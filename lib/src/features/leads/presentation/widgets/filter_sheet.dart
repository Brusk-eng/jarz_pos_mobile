import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../b2b/presentation/widgets/b2b_stage_chip.dart'
    show B2bStageChip, kB2bStages;
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_display_mappers.dart';
import '../../state/lead_filter.dart';
import '../../state/leads_notifier.dart';
import '../leads_theme.dart';
import 'area_picker_sheet.dart';

/// Bottom sheet with the advanced filters: pipeline stage, rating range, min
/// reviews, min branch count, has-Sahel, specialty-only, presence toggles,
/// price band, and whether not-suitable prospects are shown.
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LeadsTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const FilterSheet(),
    );
  }

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  /// Zero means "any"; its chip takes the localized wording at build time.
  static const _branchOptions = <int, String>{
    0: '',
    2: '2+',
    3: '3+',
    6: '6+',
    10: '10+',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filter = ref.watch(leadFilterProvider);
    final notifier = ref.read(leadFilterProvider.notifier);

    final catalog = ref.watch(leadsProvider).valueOrNull ?? const [];

    // Distinct areas present in the catalog — same source as the list bar's
    // picker, so both surfaces offer exactly the options that can match.
    final areas = <String>{
      for (final l in catalog)
        if (l.primaryArea.trim().isNotEmpty) l.primaryArea.trim(),
    }.toList()
      ..sort();

    // Distinct price bands present in the catalog.
    final priceBands = <String>{
      for (final l in catalog)
        if (l.priceBand.trim().isNotEmpty) l.priceBand.trim(),
    }.toList()
      ..sort();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: LeadsTheme.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(l10n.leadsFilterTitle, style: LeadsTheme.heading),
                  const Spacer(),
                  if (filter.activeAdvancedCount > 0)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: LeadsTheme.berryPink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l10n.leadsFilterActiveCount(filter.activeAdvancedCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: LeadsTheme.bodyFont,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Areas. Reachable from here because the map has no filter bar of
              // its own, and area is one of the two narrowings a rep changes
              // while planning a route.
              _label(l10n.leadsFilterAreas),
              Align(
                alignment: Alignment.centerLeft,
                child: AreaFilterButton(areas: areas),
              ),

              const SizedBox(height: 12),
              // Pipeline stage. "All" is a real chip rather than an implicit
              // empty state, so clearing the narrowing is one tap and the sheet
              // never looks like it has no stage selected by accident.
              _label(l10n.leadsFilterPipelineStage),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: Text(l10n.leadsFilterAll),
                    selected: filter.selectedStages.isEmpty,
                    selectedColor: LeadsTheme.blush,
                    showCheckmark: false,
                    onSelected: (_) => notifier.clearStages(),
                  ),
                  for (final stage in kB2bStages)
                    FilterChip(
                      label: Text(localizedLeadStage(context, stage)),
                      selected: filter.selectedStages.contains(stage),
                      selectedColor:
                          B2bStageChip.colorFor(stage).withValues(alpha: 0.2),
                      checkmarkColor: B2bStageChip.colorFor(stage),
                      onSelected: (_) => notifier.toggleStage(stage),
                    ),
                ],
              ),

              const SizedBox(height: 12),
              _label(l10n.leadsFilterRatingRange),
              RangeSlider(
                values: RangeValues(filter.ratingMin, filter.ratingMax),
                min: 0,
                max: 5,
                divisions: 10,
                activeColor: LeadsTheme.berryPink,
                inactiveColor: LeadsTheme.line,
                labels: RangeLabels(
                  filter.ratingMin.toStringAsFixed(1),
                  filter.ratingMax.toStringAsFixed(1),
                ),
                onChanged: (v) => notifier.update(
                  (f) => f.copyWith(ratingMin: v.start, ratingMax: v.end),
                ),
              ),

              const SizedBox(height: 8),
              _label(l10n.leadsFilterMinReviews(filter.minReviews)),
              Slider(
                value: filter.minReviews.toDouble().clamp(0, 1000),
                min: 0,
                max: 1000,
                divisions: 20,
                activeColor: LeadsTheme.berryPink,
                inactiveColor: LeadsTheme.line,
                label: '${filter.minReviews}',
                onChanged: (v) =>
                    notifier.update((f) => f.copyWith(minReviews: v.round())),
              ),

              const SizedBox(height: 8),
              _label(l10n.leadsFilterMinBranches),
              Wrap(
                spacing: 6,
                children: [
                  for (final entry in _branchOptions.entries)
                    ChoiceChip(
                      label: Text(entry.value.isEmpty
                          ? l10n.leadsFilterAny
                          : entry.value),
                      selected: filter.minBranches == entry.key,
                      selectedColor: LeadsTheme.blush,
                      showCheckmark: false,
                      onSelected: (_) => notifier
                          .update((f) => f.copyWith(minBranches: entry.key)),
                    ),
                ],
              ),

              const SizedBox(height: 12),
              _toggle(l10n.leadsFilterHasSahel, filter.hasSahel,
                  (v) => notifier.update((f) => f.copyWith(hasSahel: v))),
              _toggle(l10n.leadsFilterSpecialtyOnly, filter.specialtyOnly,
                  (v) => notifier.update((f) => f.copyWith(specialtyOnly: v))),
              // Narrows to venues Google confirms do takeaway. Labelled
              // "confirmed" on purpose: leads without the flag are unknown, not
              // dine-in-only, so this can only ever narrow the list.
              _toggle(l10n.leadsFilterTakeawayOnly, filter.takeawayOnly,
                  (v) => notifier.update((f) => f.copyWith(takeawayOnly: v))),
              _toggle(l10n.leadsFilterHasPhone, filter.hasPhone,
                  (v) => notifier.update((f) => f.copyWith(hasPhone: v))),
              _toggle(l10n.leadsFilterHasInstagram, filter.hasInstagram,
                  (v) => notifier.update((f) => f.copyWith(hasInstagram: v))),
              _toggle(l10n.leadsFilterHasWebsite, filter.hasWebsite,
                  (v) => notifier.update((f) => f.copyWith(hasWebsite: v))),
              _toggle(l10n.leadsFilterShowNotSuitable, filter.showNotSuitable,
                  (v) => notifier.setShowNotSuitable(v)),

              // Three chips, not a switch: unlike the Google signals above, the
              // Talabat flag is genuinely two-state, so "not on Talabat" is a
              // real segment a rep may want (nobody is delivering for them yet).
              const SizedBox(height: 12),
              _label(l10n.leadsFilterTalabat),
              Wrap(
                spacing: 6,
                children: [
                  for (final option in <(TalabatFilter, String)>[
                    (TalabatFilter.any, l10n.leadsFilterAny),
                    (TalabatFilter.on, l10n.leadsFilterTalabatOn),
                    (TalabatFilter.off, l10n.leadsFilterTalabatOff),
                  ])
                    ChoiceChip(
                      label: Text(option.$2),
                      selected: filter.talabatFilter == option.$1,
                      selectedColor: LeadsTheme.blush,
                      showCheckmark: false,
                      onSelected: (_) => notifier
                          .update((f) => f.copyWith(talabatFilter: option.$1)),
                    ),
                ],
              ),

              if (priceBands.isNotEmpty) ...[
                const SizedBox(height: 12),
                _label(l10n.leadsFilterPriceBand),
                Wrap(
                  spacing: 6,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.leadsFilterAny),
                      selected: filter.priceBand == null,
                      selectedColor: LeadsTheme.blush,
                      showCheckmark: false,
                      onSelected: (_) =>
                          notifier.update((f) => f.copyWith(priceBand: null)),
                    ),
                    for (final band in priceBands)
                      ChoiceChip(
                        label: Text(band),
                        selected: filter.priceBand == band,
                        selectedColor: LeadsTheme.blush,
                        showCheckmark: false,
                        onSelected: (_) =>
                            notifier.update((f) => f.copyWith(priceBand: band)),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => notifier.clearAdvanced(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LeadsTheme.deepPlum,
                        side: const BorderSide(color: LeadsTheme.line),
                      ),
                      child: Text(l10n.leadsFilterClearAll),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: LeadsTheme.berryPink,
                      ),
                      child: Text(l10n.leadsFilterDone),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: LeadsTheme.bodyMuted),
      );

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeThumbColor: LeadsTheme.berryPink,
      title: Text(label, style: LeadsTheme.body),
      value: value,
      onChanged: onChanged,
    );
  }
}
