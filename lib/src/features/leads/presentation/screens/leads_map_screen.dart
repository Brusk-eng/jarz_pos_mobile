import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/lead.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_display_mappers.dart';
import '../../domain/lead_clustering.dart';
import '../../state/lead_categories_notifier.dart';
import '../../state/lead_filter.dart';
import '../../state/leads_notifier.dart';
import '../../state/my_location_notifier.dart';
import '../leads_theme.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/lead_map.dart';
import '../../../visits/presentation/widgets/add_to_visit_sheet.dart';
import '../widgets/sahel_badge.dart';
import '../widgets/stacked_leads_sheet.dart';
import '../widgets/stage_filter_bar.dart';
import '../widgets/tier_pill.dart';

/// A filterable map of the leads (same filters as the list). Tapping a marker
/// shows a small card that navigates to the lead detail; tapping a group that
/// zooming cannot split lists its leads to pick from.
///
/// The map reads the SHARED [filteredLeadsProvider], but until it carried its
/// own controls a rep had to go back to the list to change anything — so the
/// filters were effectively unreachable here. The stage strip is inline
/// because stage is what changes while planning a route; everything else is
/// one tap away behind the same sheet the list uses.
class LeadsMapScreen extends ConsumerStatefulWidget {
  const LeadsMapScreen({super.key});

  @override
  ConsumerState<LeadsMapScreen> createState() => _LeadsMapScreenState();
}

class _LeadsMapScreenState extends ConsumerState<LeadsMapScreen> {
  Lead? _selected;
  final _mapController = MapController();
  bool _showLegend = false;

  @override
  void initState() {
    super.initState();
    // Same reason as the list: every filter here runs against the cached
    // catalog, so a stage changed on the server has to be pulled in or the
    // stage strip filters against stale pins. The refresh keeps the current
    // markers up while it runs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(leadsProvider.notifier).refresh();
    });
  }

  /// Ask for a fix, then centre on it. Every refusal gets an explanation and,
  /// where one exists, a way out — a map that just fails to grow a blue dot is
  /// indistinguishable from a broken map.
  Future<void> _locate(MyLocationState current) async {
    final notifier = ref.read(myLocationProvider.notifier);
    await notifier.locate();
    if (!mounted) return;

    final state = ref.read(myLocationProvider);
    if (state.hasPosition) {
      _mapController.move(state.position!, 14);
      return;
    }

    final l10n = context.l10n;
    final message = switch (state.status) {
      MyLocationStatus.serviceDisabled => l10n.leadsLocationServicesOff,
      MyLocationStatus.deniedForever => l10n.leadsLocationBlocked,
      MyLocationStatus.denied => l10n.leadsLocationDenied,
      _ => l10n.leadsLocationNoFix,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: state.status == MyLocationStatus.deniedForever
            ? SnackBarAction(
                label: l10n.leadsLocationSettings,
                onPressed: () => notifier.openSettings(),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredLeadsProvider);
    final filter = ref.watch(leadFilterProvider);
    final location = ref.watch(myLocationProvider);
    final located = locatableLeads(filtered);

    // Colour source for the pins: the colour configured on each category
    // master, so the map, the filter chips and Desk all agree.
    final categoryColors = <String, String?>{
      for (final c in ref.watch(leadCategoriesProvider).valueOrNull ??
          const <LeadCategory>[])
        c.name: c.color,
    };

    return Scaffold(
      backgroundColor: LeadsTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: LeadsTheme.deepPlum,
        elevation: 0,
        title: Text(
          context.l10n.leadsMapTitle,
          style: LeadsTheme.heading.copyWith(fontSize: 22),
        ),
        actions: [
          _MapFilterButton(count: filter.activeAdvancedCount),
          IconButton(
            tooltip: context.l10n.leadsListViewTooltip,
            icon: const Icon(Icons.list_alt),
            onPressed: () => context.pop(),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(44),
          child: StageFilterBar(backgroundColor: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          LeadMap(
            leads: filtered,
            mapController: _mapController,
            categoryColors: categoryColors,
            myLocation: location.position,
            myLocationAccuracy: location.accuracyMetres,
            selected: _selected,
            onMarkerTap: (lead) => setState(() => _selected = lead),
            onStackTap: (cluster) async {
              final picked = await StackedLeadsSheet.show(
                context,
                leads: cluster.leads,
                categoryColors: categoryColors,
                myLocation: location.position,
              );
              if (picked != null && mounted) {
                setState(() => _selected = picked);
              }
            },
          ),
          // Count pill.
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Text(
                // Name the active stage narrowing right on the map: a rep who
                // filtered and then panned away needs to know why the map
                // looks empty here.
                filter.selectedStages.isEmpty
                    ? context.l10n.leadsOnMapCount(located.length)
                    : context.l10n.leadsOnMapWithStages(
                        located.length,
                        _stageSummary(context, filter.selectedStages),
                      ),
                style: LeadsTheme.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // Locate-me + legend, stacked bottom-right clear of the marker card.
          Positioned(
            right: 12,
            bottom: _selected == null ? 20 : 150,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (categoryColors.isNotEmpty)
                  _RoundMapButton(
                    icon: _showLegend ? Icons.close : Icons.palette_outlined,
                    tooltip: _showLegend
                        ? context.l10n.leadsHideLegend
                        : context.l10n.leadsCategoryLegend,
                    onTap: () => setState(() => _showLegend = !_showLegend),
                  ),
                const SizedBox(height: 10),
                _RoundMapButton(
                  icon: location.hasPosition
                      ? Icons.my_location
                      : Icons.location_searching,
                  tooltip: context.l10n.leadsShowMyLocation,
                  busy: location.isBusy,
                  active: location.hasPosition,
                  onTap: () => _locate(location),
                ),
              ],
            ),
          ),

          if (_showLegend && categoryColors.isNotEmpty)
            Positioned(
              right: 12,
              bottom: _selected == null ? 90 : 220,
              child: _CategoryLegend(
                // Only categories actually on screen: a legend listing
                // categories the filters have excluded is noise.
                categories: {
                  for (final lead in located)
                    if ((lead.category ?? '').isNotEmpty)
                      lead.category!: categoryColors[lead.category],
                },
              ),
            ),

          if (_selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 20,
              child: _MarkerCard(
                lead: _selected!,
                distanceMetres: location.position == null
                    ? null
                    : metresToLead(location.position!, _selected!),
                onClose: () => setState(() => _selected = null),
                onOpen: () => context.push(
                  '/leads/${Uri.encodeComponent(_selected!.name)}',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Qualify" for one stage, "3 stages" beyond that — the full list would not
/// fit the pill and truncating it mid-name reads worse than a count.
String _stageSummary(BuildContext context, Set<String> stages) {
  if (stages.length == 1) {
    return localizedLeadStage(context, stages.first);
  }
  return context.l10n.leadsStageSummaryCount(stages.length);
}

/// The map's route into the shared advanced-filter sheet, badged with the
/// active count so a narrowed map is never mistaken for an empty catalog.
class _MapFilterButton extends StatelessWidget {
  const _MapFilterButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: context.l10n.leadsAdvancedFilters,
          icon: const Icon(Icons.tune),
          color: LeadsTheme.deepPlum,
          onPressed: () => FilterSheet.show(context),
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: LeadsTheme.berryPink,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: LeadsTheme.bodyFont,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MarkerCard extends StatelessWidget {
  const _MarkerCard({
    required this.lead,
    required this.onClose,
    required this.onOpen,
    this.distanceMetres,
  });

  final Lead lead;

  /// Straight-line metres from the rep. Null when no position is known.
  final double? distanceMetres;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final nameRtl = LeadsTheme.isArabic(lead.leadName);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TierPill(lead.tier, dense: true),
                        const SizedBox(width: 6),
                        if (lead.sahelBranches > 0)
                          SahelBadge(lead.sahelBranches),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection:
                          nameRtl ? TextDirection.rtl : TextDirection.ltr,
                      child: Text(
                        lead.leadName.isEmpty ? lead.name : lead.leadName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LeadsTheme.nameStyle(lead.leadName),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (lead.primaryArea.isNotEmpty) lead.primaryArea,
                        if (lead.avgRating != null)
                          '★ ${lead.avgRating!.toStringAsFixed(1)}',
                        context.l10n.leadsBranchesCount(lead.branchCount),
                      ].join('  ·  '),
                      style: LeadsTheme.bodyMuted,
                    ),
                    if (distanceMetres != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.straighten,
                              size: 13, color: Color(0xFF1B6CA8)),
                          const SizedBox(width: 4),
                          Text(
                            // "straight line" is stated, not implied: this is
                            // not a driving distance and a rep planning a
                            // route must not read it as one.
                            context.l10n.leadsDistanceAway(
                                formatDistance(context, distanceMetres!)),
                            style: LeadsTheme.bodyMuted.copyWith(
                              color: const Color(0xFF1B6CA8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.visitAddToRoute,
                icon: const Icon(Icons.route, size: 20),
                onPressed: () => addToVisitAndConfirm(
                  context,
                  referenceDoctype: 'Lead',
                  referenceName: lead.name,
                  title: lead.leadName,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: LeadsTheme.muted,
                onPressed: onClose,
              ),
              const Icon(Icons.chevron_right, color: LeadsTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// A circular white map control. Sized for a thumb on a phone held one-handed.
class _RoundMapButton extends StatelessWidget {
  const _RoundMapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.busy = false,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool busy;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: busy ? null : onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Icon(
                    icon,
                    color: active
                        ? const Color(0xFF1B6CA8)
                        : LeadsTheme.deepPlum,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Which colour means which category. Without it the pins are decorative.
class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({required this.categories});

  /// Category name -> configured colour (null falls back to the palette).
  final Map<String, String?> categories;

  @override
  Widget build(BuildContext context) {
    final names = categories.keys.toList()..sort();
    return Container(
      constraints: const BoxConstraints(maxWidth: 210, maxHeight: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.leadsMapCategories,
              style: LeadsTheme.body.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final name in names)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: LeadsTheme.categoryColor(
                                name,
                                configuredColor: categories[name],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LeadsTheme.bodyMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
