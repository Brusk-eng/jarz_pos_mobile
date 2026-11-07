import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../data/models/meta_ads_report.dart';
import '../../data/models/report_json.dart';
import '../../state/meta_ads_providers.dart';
import '../widgets/kpi_card.dart';
import '../widgets/report_date_range_bar.dart';
import '../widgets/report_states.dart';

/// Meta Ads dashboard: spend, purchases, CTR and ROAS per campaign, ad set or
/// ad, with the ERP's own order count from each ad next to Meta's.
///
/// The date range is the shared reports range. Level, campaign / ad set
/// filters and the sort live in [metaAdsFiltersProvider]; tapping a campaign
/// opens its ad sets and tapping an ad set opens its ads. Pull-to-refresh asks
/// the server to skip its 15-minute cache (`refresh=1`).
class MetaAdsScreen extends ConsumerStatefulWidget {
  const MetaAdsScreen({super.key});

  @override
  ConsumerState<MetaAdsScreen> createState() => _MetaAdsScreenState();
}

class _MetaAdsScreenState extends ConsumerState<MetaAdsScreen> {
  /// The last report that loaded, so the campaign / ad set dropdowns keep
  /// their options while a new level or filter is loading.
  MetaAdsReport? _last;

  Future<void> _refresh(MetaAdsQuery q) async {
    ref.read(metaAdsRefreshRequestsProvider).mark(q);
    final reload = ref.refresh(metaAdsReportProvider(q).future);
    try {
      await reload;
    } catch (_) {
      // The error is rendered by the body; the indicator just stops.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = ref.watch(metaAdsQueryProvider);
    final filters = ref.watch(metaAdsFiltersProvider);
    final async = ref.watch(metaAdsReportProvider(q));
    final report = async.valueOrNull;
    if (report != null) _last = report;

    final Widget body;
    if (report != null && !report.configured) {
      body = ReportEmptyView(
        message: l10n.metaAdsNotConfigured,
        icon: Icons.campaign_outlined,
      );
    } else {
      final notifier = ref.read(metaAdsFiltersProvider.notifier);
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.only(bottom: 24),
        children: [
          const ReportDateRangeBar(),
          _ControlsCard(
            filters: filters,
            options: _last,
            onLevel: notifier.setLevel,
            onCampaign: notifier.setCampaign,
            onAdset: (id) => notifier.setAdset(
              id,
              campaignId: _last?.adsets
                  .where((a) => a.id == id)
                  .map((a) => a.campaignId)
                  .firstOrNull,
            ),
            onSort: notifier.setSort,
          ),
          ...async.when<List<Widget>>(
            loading: () => const [
              Padding(
                padding: EdgeInsetsDirectional.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              _InlineError(
                error: e,
                onRetry: () => ref.invalidate(metaAdsReportProvider(q)),
              ),
            ],
            data: (r) => [
              MetaAdsResults(
                report: r,
                level: q.level,
                sort: filters.sort,
                onRowTap: q.level.child == null ? null : notifier.drillInto,
              ),
            ],
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.metaAdsTitle)),
      body: RefreshIndicator(onRefresh: () => _refresh(q), child: body),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Controls: level, campaign, ad set, sort
// ─────────────────────────────────────────────────────────────────────────

class _ControlsCard extends StatelessWidget {
  final MetaAdsFilters filters;
  final MetaAdsReport? options;
  final ValueChanged<MetaAdsLevel> onLevel;
  final ValueChanged<String?> onCampaign;
  final ValueChanged<String?> onAdset;
  final ValueChanged<MetaAdsSort> onSort;

  const _ControlsCard({
    required this.filters,
    required this.options,
    required this.onLevel,
    required this.onCampaign,
    required this.onAdset,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final level = filters.level;
    final campaigns = _dedupe(options?.campaigns ?? const []);
    final campaignId = filters.campaignId;
    final adsets = _dedupe(
      (options?.adsets ?? const <MetaAdsFilterOption>[]).where(
        (a) =>
            campaignId == null ||
            a.campaignId == null ||
            a.campaignId == campaignId,
      ),
    );
    final rows = options?.rows ?? const <MetaAdsRow>[];

    return Card(
      margin: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 8),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<MetaAdsLevel>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: MetaAdsLevel.campaign,
                  label: Text(l10n.metaAdsLevelCampaigns),
                ),
                ButtonSegment(
                  value: MetaAdsLevel.adset,
                  label: Text(l10n.metaAdsLevelAdsets),
                ),
                ButtonSegment(
                  value: MetaAdsLevel.ad,
                  label: Text(l10n.metaAdsLevelAds),
                ),
              ],
              selected: {level},
              onSelectionChanged: (s) => onLevel(s.first),
            ),
            if (level != MetaAdsLevel.campaign) ...[
              const SizedBox(height: 10),
              _IdDropdown(
                key: const ValueKey('meta-ads-campaign'),
                label: l10n.metaAdsCampaign,
                allLabel: l10n.metaAdsAllCampaigns,
                value: campaignId,
                options: campaigns,
                fallbackName: rows
                    .where((r) => r.campaignId == campaignId)
                    .map((r) => r.campaignName)
                    .firstOrNull,
                onChanged: onCampaign,
              ),
            ],
            if (level == MetaAdsLevel.ad) ...[
              const SizedBox(height: 10),
              _IdDropdown(
                key: const ValueKey('meta-ads-adset'),
                label: l10n.metaAdsAdset,
                allLabel: l10n.metaAdsAllAdsets,
                value: filters.adsetId,
                options: adsets,
                fallbackName: rows
                    .where((r) => r.adsetId == filters.adsetId)
                    .map((r) => r.adsetName)
                    .firstOrNull,
                onChanged: onAdset,
              ),
            ],
            const SizedBox(height: 10),
            _Decorated(
              label: l10n.metaAdsSortBy,
              child: DropdownButton<MetaAdsSort>(
                key: const ValueKey('meta-ads-sort'),
                value: filters.sort,
                isExpanded: true,
                isDense: true,
                items: [
                  for (final s in MetaAdsSort.values)
                    DropdownMenuItem(
                      value: s,
                      child: Text(metaAdsSortLabel(context, s)),
                    ),
                ],
                onChanged: (s) {
                  if (s != null) onSort(s);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<MetaAdsFilterOption> _dedupe(
    Iterable<MetaAdsFilterOption> options,
  ) {
    final seen = <String>{};
    return [
      for (final o in options)
        if (o.id.isNotEmpty && seen.add(o.id)) o,
    ];
  }
}

/// A labelled outline around a bare dropdown. `DropdownButton.value` (unlike
/// the form field's `initialValue`) follows the provider state.
class _Decorated extends StatelessWidget {
  final String label;
  final Widget child;

  const _Decorated({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
    ),
    child: DropdownButtonHideUnderline(child: child),
  );
}

/// "All" + one entry per option. A selected id the options do not list
/// (another date range, a failed load) is added under [fallbackName], so the
/// dropdown never asserts on a value it has no item for.
class _IdDropdown extends StatelessWidget {
  final String label;
  final String allLabel;
  final String? value;
  final List<MetaAdsFilterOption> options;
  final String? fallbackName;
  final ValueChanged<String?> onChanged;

  const _IdDropdown({
    super.key,
    required this.label,
    required this.allLabel,
    required this.value,
    required this.options,
    required this.onChanged,
    this.fallbackName,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value;
    final listed = selected == null || options.any((o) => o.id == selected);
    Text item(String text) =>
        Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
    return _Decorated(
      label: label,
      child: DropdownButton<String?>(
        value: selected,
        isExpanded: true,
        isDense: true,
        items: [
          DropdownMenuItem<String?>(value: null, child: item(allLabel)),
          for (final o in options)
            DropdownMenuItem<String?>(value: o.id, child: item(o.name)),
          if (!listed)
            DropdownMenuItem<String?>(
              value: selected,
              child: item(
                (fallbackName?.trim().isNotEmpty ?? false)
                    ? fallbackName!
                    : selected,
              ),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// Localised label of a sort option.
String metaAdsSortLabel(BuildContext context, MetaAdsSort s) {
  final l10n = context.l10n;
  return switch (s) {
    MetaAdsSort.spend => l10n.metaAdsSpend,
    MetaAdsSort.purchases => l10n.metaAdsPurchases,
    MetaAdsSort.roas => l10n.metaAdsRoas,
    MetaAdsSort.ctr => l10n.metaAdsCtr,
    MetaAdsSort.costPerPurchase => l10n.metaAdsCostPerPurchase,
    MetaAdsSort.erpOrders => l10n.metaAdsErpOrders,
  };
}

// ─────────────────────────────────────────────────────────────────────────
// Results: KPIs, notes, rows
// ─────────────────────────────────────────────────────────────────────────

/// The loaded part of the screen: totals, caveats and the sorted rows.
class MetaAdsResults extends StatelessWidget {
  final MetaAdsReport report;
  final MetaAdsLevel level;
  final MetaAdsSort sort;

  /// Drill-down; null at ad level (no level below it).
  final ValueChanged<MetaAdsRow>? onRowTap;

  const MetaAdsResults({
    super.key,
    required this.report,
    required this.level,
    required this.sort,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final rows = sortMetaAdsRows(report.rows, sort);
    final fetched = _fetchedAtLabel(context, report.fetchedAt);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KpiGrid(totals: report.totals, currency: report.currency),
          if (fetched != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 0),
              child: Text(
                l10n.metaAdsFetchedAt(fetched),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (report.notes.isNotEmpty) _NotesCard(notes: report.notes),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.all(32),
              child: Text(
                l10n.metaAdsNoRows,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final r in rows)
              _RowCard(
                row: r,
                level: level,
                sort: sort,
                currency: report.currency,
                onTap: onRowTap == null ? null : () => onRowTap!(r),
              ),
        ],
      ),
    );
  }

  static String? _fetchedAtLabel(BuildContext context, String raw) {
    if (raw.trim().isEmpty) return null;
    final dt = ReportJson.dateTimeOrNull(raw);
    if (dt == null) return raw;
    return formatDateTime(context, dt, pattern: 'MMM d, h:mm a');
  }
}

class _KpiGrid extends StatelessWidget {
  final MetaAdsMetrics totals;
  final String currency;

  const _KpiGrid({required this.totals, required this.currency});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = totals;
    final good = Colors.green.shade700;
    final bad = Colors.red.shade700;
    Color? roasColor(double roas) =>
        t.spend <= 0 ? null : (roas >= 1 ? good : bad);

    final cards = <Widget Function(double)>[
      (w) => KpiCard(
        width: w,
        label: l10n.metaAdsSpend,
        value: formatCompactCurrency(context, t.spend, currencyCode: currency),
        icon: Icons.payments_outlined,
      ),
      (w) => KpiCard(
        width: w,
        label: l10n.metaAdsPurchases,
        value: metaAdsCount(context, t.purchases),
        icon: Icons.shopping_bag_outlined,
        caption: l10n.metaAdsPurchaseValueOf(
          formatCompactCurrency(context, t.purchaseValue, currencyCode: currency),
        ),
      ),
      (w) => KpiCard(
        width: w,
        label: l10n.metaAdsRoas,
        value: metaAdsRoas(context, t.roas),
        icon: Icons.trending_up,
        color: roasColor(t.roas),
      ),
      (w) => KpiCard(
        width: w,
        label: l10n.metaAdsCtr,
        value: metaAdsPercent(context, t.ctr),
        icon: Icons.ads_click,
        caption: l10n.metaAdsLinkClicksCount(formatCount(context, t.linkClicks)),
      ),
      (w) => KpiCard(
        width: w,
        label: l10n.metaAdsCostPerPurchase,
        value: t.purchases > 0
            ? formatCurrency(context, t.costPerPurchase, currencyCode: currency)
            : '—',
        icon: Icons.sell_outlined,
      ),
      (w) => KpiCard(
        width: w,
        label: l10n.metaAdsErpOrders,
        value: formatCount(context, t.erpOrders),
        icon: Icons.receipt_long_outlined,
        delta: l10n.metaAdsErpRoasOf(metaAdsRoas(context, t.erpRoas)),
        deltaColor: roasColor(t.erpRoas),
        caption: l10n.metaAdsErpRevenueOf(
          formatCompactCurrency(context, t.erpRevenue, currencyCode: currency),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 900
            ? 6
            : constraints.maxWidth >= 600
            ? 3
            : 2;
        const spacing = 8.0;
        final cardWidth = (constraints.maxWidth - (cols - 1) * spacing) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final b in cards) b(cardWidth)],
        );
      },
    );
  }
}

class _NotesCard extends StatelessWidget {
  final List<String> notes;

  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Card(
      margin: const EdgeInsetsDirectional.only(top: 8),
      color: color.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.metaAdsNotes,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  for (final n in notes)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 4),
                      child: Text(n, style: theme.textTheme.bodySmall),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowCard extends StatelessWidget {
  final MetaAdsRow row;
  final MetaAdsLevel level;
  final MetaAdsSort sort;
  final String currency;
  final VoidCallback? onTap;

  const _RowCard({
    required this.row,
    required this.level,
    required this.sort,
    required this.currency,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final m = row.metrics;
    final parents = [
      if (level != MetaAdsLevel.campaign && row.campaignName.isNotEmpty)
        row.campaignName,
      if (level == MetaAdsLevel.ad && (row.adsetName?.isNotEmpty ?? false))
        row.adsetName!,
    ].join(' › ');

    final metrics = <(MetaAdsSort?, String, String)>[
      (
        MetaAdsSort.spend,
        l10n.metaAdsSpend,
        formatCurrency(context, m.spend, currencyCode: currency),
      ),
      (
        MetaAdsSort.purchases,
        l10n.metaAdsPurchases,
        metaAdsCount(context, m.purchases),
      ),
      (MetaAdsSort.roas, l10n.metaAdsRoas, metaAdsRoas(context, m.roas)),
      (MetaAdsSort.ctr, l10n.metaAdsCtr, metaAdsPercent(context, m.ctr)),
      (
        MetaAdsSort.costPerPurchase,
        l10n.metaAdsCostPerPurchase,
        m.purchases > 0
            ? formatCurrency(context, m.costPerPurchase, currencyCode: currency)
            : '—',
      ),
      (
        MetaAdsSort.erpOrders,
        l10n.metaAdsErpOrders,
        formatCount(context, m.erpOrders),
      ),
      (null, l10n.metaAdsErpRoas, metaAdsRoas(context, m.erpRoas)),
    ];

    return Card(
      margin: const EdgeInsetsDirectional.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (level == MetaAdsLevel.ad) ...[
                _Thumbnail(url: row.thumbnailUrl),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            row.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (row.status.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _StatusChip(status: row.status),
                        ],
                      ],
                    ),
                    if (parents.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        parents,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        for (final (key, label, value) in metrics)
                          _Metric(
                            label: label,
                            value: value,
                            highlighted: key == sort,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4),
                  child: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _Metric({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: highlighted ? FontWeight.bold : FontWeight.w500,
            color: highlighted ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final (label, color) = switch (status) {
      'ACTIVE' => (l10n.metaAdsStatusActive, Colors.green.shade700),
      'PAUSED' ||
      'CAMPAIGN_PAUSED' ||
      'ADSET_PAUSED' => (l10n.metaAdsStatusPaused, Colors.orange.shade800),
      'ARCHIVED' => (l10n.metaAdsStatusArchived, theme.colorScheme.outline),
      'DELETED' => (l10n.metaAdsStatusDeleted, theme.colorScheme.outline),
      _ => (
        status.replaceAll('_', ' ').toLowerCase(),
        theme.colorScheme.outline,
      ),
    };
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? url;

  const _Thumbnail({required this.url});

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = Container(
      width: _size,
      height: _size,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final u = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: u == null
          ? placeholder
          : Image.network(
              u,
              width: _size,
              height: _size,
              fit: BoxFit.cover,
              cacheWidth: (_size * 3).round(),
              errorBuilder: (context, _, _) => placeholder,
            ),
    );
  }
}

/// Error inside the scrolling list (the date bar and controls stay usable).
class _InlineError extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _InlineError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            l10n.reportError,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            context.userErrorMessage(error),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.reportsRetry),
          ),
        ],
      ),
    );
  }
}

// ── number formatting ─────────────────────────────────────────────────────

String _twoDecimals(BuildContext context, double v) =>
    NumberFormat.decimalPatternDigits(
      locale: context.l10n.localeName,
      decimalDigits: 2,
    ).format(v);

/// `1.23%`.
String metaAdsPercent(BuildContext context, double v) =>
    '${_twoDecimals(context, v)}%';

/// `2.35x`.
String metaAdsRoas(BuildContext context, double v) =>
    '${_twoDecimals(context, v)}x';

/// A purchase count: whole numbers plain, fractional ones (Meta can report
/// them) with up to two decimals.
String metaAdsCount(BuildContext context, double v) =>
    v == v.roundToDouble()
        ? formatCount(context, v.round())
        : _twoDecimals(context, v);
