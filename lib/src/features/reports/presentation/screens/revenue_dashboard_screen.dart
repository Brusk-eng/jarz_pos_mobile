import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_display_mappers.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/network/user_service.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../manager/state/manager_providers.dart';
import '../../data/models/report_json.dart';
import '../../data/models/revenue_dashboard.dart';
import '../../state/reports_providers.dart';
import '../widgets/report_branch_selector.dart';
import '../widgets/report_chart_card.dart';
import '../widgets/report_export_button.dart';
import '../widgets/report_states.dart';

/// The owner's daily revenue dashboard
/// (`revenue_dashboard.get_revenue_dashboard`, contract v2), daily-first.
///
/// Top to bottom: the period buttons (Today, Yesterday, Last 7 days, Month to
/// date, each with its net sales and change, plus Custom) and the branch
/// filter; the "at a glance" hero for the selected range against its
/// like-for-like comparison; what needs attention; where the sales came from
/// (source, payment, branch); sales by hour; links to the product and B2B
/// reports; and when the figures were built. Every figure is the backend's;
/// the screen only lays it out.
///
/// Reached from the side menu with `context.go`, so it carries the drawer.
class RevenueDashboardScreen extends ConsumerStatefulWidget {
  const RevenueDashboardScreen({super.key});

  @override
  ConsumerState<RevenueDashboardScreen> createState() =>
      _RevenueDashboardScreenState();
}

class _RevenueDashboardScreenState
    extends ConsumerState<RevenueDashboardScreen> {
  // The snapshot does not depend on the dates, so while a new range loads the
  // period buttons keep their amounts (for the same branch) instead of
  // flashing back to bare labels.
  RevenueSnapshot? _lastSnapshot;
  String? _lastSnapshotBranch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = ref.watch(revenueQueryProvider);
    final async = ref.watch(revenueDashboardProvider(q));
    final showBranchCash = ref.watch(managerHomeProvider);
    final loaded = async.valueOrNull;
    if (loaded != null && !loaded.isEmpty) {
      _lastSnapshot = loaded.snapshot;
      _lastSnapshotBranch = q.branchOrNull;
    }
    final cachedSnapshot = _lastSnapshotBranch == q.branchOrNull
        ? _lastSnapshot
        : null;

    Future<void> refresh() async {
      ref.invalidate(revenueDashboardProvider(q));
      if (showBranchCash) ref.invalidate(dashboardSummaryProvider);
      try {
        await ref.read(revenueDashboardProvider(q).future);
      } catch (_) {
        // The error state renders it; the spinner only has to stop.
      }
    }

    // The period buttons and the branch filter stay on screen in every state,
    // so an empty or failed range can be changed without leaving the page.
    Widget filters() => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 0),
      child: _Filters(snapshot: cachedSnapshot),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rptRevenueDashboardTitle),
        actions: [
          ReportExportButton(
            title: l10n.rptRevenueDashboardTitle,
            rows: () => _exportRows(context, async.valueOrNull),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: async.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            filters(),
            const Padding(
              padding: EdgeInsetsDirectional.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (e, _) => Column(
          children: [
            filters(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: refresh,
                child: ReportErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(revenueDashboardProvider(q)),
                ),
              ),
            ),
          ],
        ),
        data: (data) => data.isEmpty
            ? Column(
                children: [
                  filters(),
                  // Drawer cash is "now", so it shows before the day's first
                  // sale too.
                  if (showBranchCash)
                    const Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(12, 12, 12, 0),
                      child: BranchCashCard(),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: refresh,
                      child: const ReportEmptyView(),
                    ),
                  ),
                ],
              )
            : RefreshIndicator(
                onRefresh: refresh,
                child: RevenueDashboardContent(
                  data: data,
                  query: q,
                  showBranchCash: showBranchCash,
                  selectedBranch: q.branchOrNull,
                  onBranchTap: (branch) {
                    // The server's bucket for invoices with no POS Profile is
                    // a label, not a branch: filtering by it matches nothing.
                    if (branch == _noProfile) return;
                    final notifier = ref.read(reportBranchProvider.notifier);
                    notifier.state = notifier.state == branch ? null : branch;
                  },
                ),
              ),
      ),
    );
  }
}

/// The scrollable body, split out so tests can render it from a fixture.
class RevenueDashboardContent extends StatelessWidget {
  final RevenueDashboard data;

  /// The query the data was loaded for; the hero falls back to it when the
  /// payload carries no `filters`.
  final ReportQuery? query;
  final String? selectedBranch;
  final ValueChanged<String>? onBranchTap;

  /// Adds [BranchCashCard] under the hero (the manager home only).
  final bool showBranchCash;

  const RevenueDashboardContent({
    super.key,
    required this.data,
    this.query,
    this.showBranchCash = false,
    this.selectedBranch,
    this.onBranchTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final updated = ReportJson.dateTimeOrNull(data.generatedAt);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.all(12),
      children: [
        _Filters(snapshot: data.snapshot),
        const SizedBox(height: 12),
        _HeroCard(data: data, query: query),
        if (showBranchCash) ...[
          const SizedBox(height: 12),
          const BranchCashCard(),
        ],
        if (data.hasAttention) ...[
          const SizedBox(height: 12),
          _AttentionSection(items: data.attention),
        ],
        const SizedBox(height: 12),
        _WhereFromCard(
          data: data,
          selectedBranch: selectedBranch,
          onBranchTap: onBranchTap,
        ),
        const SizedBox(height: 12),
        _ByHourCard(rows: data.hourly),
        const SizedBox(height: 12),
        const _FooterLinks(),
        if (updated != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.rptRevUpdatedAt(
              DateFormat.Hm(l10n.localeName).format(updated),
            ),
            key: const ValueKey('revenue-updated-at'),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 1. Period buttons + branch filter
// ─────────────────────────────────────────────────────────────────────────

class _Filters extends StatelessWidget {
  /// Null before the first load: the buttons then show bare labels.
  final RevenueSnapshot? snapshot;
  const _Filters({this.snapshot});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      _PeriodBar(snapshot: snapshot),
      const SizedBox(height: 10),
      const ReportBranchSelector(),
    ],
  );
}

class _Preset {
  final Key key;
  final String title;
  final RevenueSnapshotPeriod? period;
  final ReportRange range;
  const _Preset(this.key, this.title, this.period, this.range);
}

/// The snapshot cards as selectable buttons. Selecting one sets the range to
/// that card's `label_from`/`label_to` (the server's days), falling back to
/// the device's calendar before the first load. A range matching no preset
/// highlights Custom, which opens the date-range picker.
class _PeriodBar extends ConsumerWidget {
  final RevenueSnapshot? snapshot;
  const _PeriodBar({this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final range = ref.watch(revenueRangeProvider);
    final s = snapshot;
    final presets = <_Preset>[
      _Preset(
        const ValueKey('revenue-period-today'),
        l10n.rptRevToday,
        s?.today,
        _periodRange(s?.today) ?? ReportRange.today(),
      ),
      _Preset(
        const ValueKey('revenue-period-yesterday'),
        l10n.rptRevYesterday,
        s?.yesterday,
        _periodRange(s?.yesterday) ?? ReportRange.yesterday(),
      ),
      _Preset(
        const ValueKey('revenue-period-last-7-days'),
        l10n.rptRevLast7Days,
        s?.last7Days,
        _periodRange(s?.last7Days) ?? ReportRange.lastDays(7),
      ),
      _Preset(
        const ValueKey('revenue-period-month-to-date'),
        l10n.rptRevMonthToDate,
        s?.monthToDate,
        _periodRange(s?.monthToDate) ?? ReportRange.thisMonth(),
      ),
    ];
    final selected = presets.indexWhere((p) => p.range == range);

    void select(ReportRange r) =>
        ref.read(revenueRangeProvider.notifier).state = r;

    Future<void> pickCustom() async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final first = DateTime(2018);
      DateTime clamp(DateTime d) =>
          d.isBefore(first) ? first : (d.isAfter(today) ? today : d);
      final start = clamp(range.from);
      final end = clamp(range.to);
      final picked = await showDateRangePicker(
        context: context,
        firstDate: first,
        lastDate: today,
        initialDateRange: DateTimeRange(
          start: start,
          end: end.isBefore(start) ? start : end,
        ),
      );
      if (picked == null || !context.mounted) return;
      select(ReportRange(from: picked.start, to: picked.end));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < presets.length; i++)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: _PeriodButton(
                  key: presets[i].key,
                  title: presets[i].title,
                  amount: presets[i].period == null
                      ? null
                      : formatCompactCurrency(
                          context,
                          presets[i].period!.netSales,
                        ),
                  showChange: presets[i].period != null,
                  changePct: presets[i].period?.changePct,
                  selected: i == selected,
                  onTap: () => select(presets[i].range),
                ),
              ),
            _PeriodButton(
              key: const ValueKey('revenue-period-custom'),
              title: l10n.rptRevCustom,
              icon: Icons.date_range_outlined,
              amount: selected < 0
                  ? _rangeLabel(context, range.fromIso, range.toIso)
                  : null,
              selected: selected < 0,
              onTap: pickCustom,
            ),
          ],
        ),
      ),
    );
  }
}

/// A snapshot period's own dates, or null when the payload had none.
ReportRange? _periodRange(RevenueSnapshotPeriod? p) {
  if (p == null) return null;
  final from = DateTime.tryParse(p.labelFrom);
  final to = DateTime.tryParse(p.labelTo);
  if (from == null || to == null) return null;
  return ReportRange(from: from, to: to);
}

class _PeriodButton extends StatelessWidget {
  final String title;
  final String? amount;
  final bool showChange;
  final double? changePct;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodButton({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.amount,
    this.showChange = false,
    this.changePct,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    final amountText = amount;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 92, maxWidth: 136),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 14, color: fg),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: fg,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (amountText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      amountText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: fg,
                      ),
                    ),
                  ],
                  if (showChange) _ChangeText(pct: changePct, small: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 2. Hero: the selected range at a glance
// ─────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final RevenueDashboard data;
  final ReportQuery? query;
  const _HeroCard({required this.data, this.query});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final s = data.summary;
    final p = s.previous;
    final f = data.fulfilment;
    String money(double v) => formatCompactCurrency(context, v);
    String count(int v) => formatCount(context, v);

    final from = data.filters.dateFrom.isNotEmpty
        ? data.filters.dateFrom
        : (query?.fromIso ?? '');
    final to = data.filters.dateTo.isNotEmpty
        ? data.filters.dateTo
        : (query?.toIso ?? '');
    final compare = _comparisonLabel(context, p);

    // B2C / B2B are drawn as the channel split above this line; discounts
    // stay in the attention list and the CSV export, not in the hero.
    final caption = [
      l10n.rptRevNewCustomersCount(s.newCustomers),
      l10n.rptRevDeliveryPickup(
        count(f.deliveryOrders),
        count(f.pickupOrders),
      ),
    ].join(' · ');
    final leakage = [
      l10n.rptRevReturnsAmount(money(s.returnsValue)),
      l10n.rptRevCancelledShort(count(s.cancelled)),
    ].join(' · ');
    final best = s.bestDay;
    final worst = s.worstDay;
    final days = s.days > 1
        ? [
            l10n.rptRevDailyAverageAmount(money(s.dailyAverage)),
            if (best != null)
              l10n.rptRevBestDayOn(
                _dayLabel(context, best.date),
                money(best.netSales),
              ),
            if (worst != null)
              l10n.rptRevWorstDayOn(
                _dayLabel(context, worst.date),
                money(worst.netSales),
              ),
          ].join(' · ')
        : null;

    return Card(
      key: const ValueKey('revenue-hero'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _CardTitle(l10n.rptRevAtAGlance)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    from.isEmpty ? '' : _rangeLabel(context, from, to),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelMedium?.copyWith(color: muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.rptRevNetSales,
              style: theme.textTheme.labelMedium?.copyWith(color: muted),
            ),
            Row(
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      formatCurrency(context, s.netSales),
                      key: const ValueKey('revenue-hero-net-sales'),
                      maxLines: 1,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ChangePill(pct: p.changePct),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _HeroStat(
                    label: l10n.reportKpiOrders,
                    value: count(s.orders),
                    pct: p.ordersChangePct,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HeroStat(
                    label: l10n.rptRevAverageOrder,
                    value: s.aov == null ? _dash : formatCurrency(context, s.aov!),
                    pct: p.aovChangePct,
                  ),
                ),
              ],
            ),
            if (compare != null) ...[
              const SizedBox(height: 8),
              Text(
                compare,
                key: const ValueKey('revenue-hero-compare'),
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
            ],
            const Divider(height: 20),
            if (_pos(s.b2c) + _pos(s.b2b) > 0) ...[
              _ChannelSplit(
                b2c: s.b2c,
                b2b: s.b2b,
                b2cInclShipping: s.b2cInclShipping,
              ),
              const SizedBox(height: 10),
            ],
            Text(caption, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              leakage,
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            ),
            if (days != null) ...[
              const SizedBox(height: 4),
              Text(
                days,
                key: const ValueKey('revenue-hero-days'),
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final double? pct;
  const _HeroStat({required this.label, required this.value, this.pct});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            maxLines: 1,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _ChangeText(pct: pct, small: true),
      ],
    );
  }
}

/// B2C against B2B for the selected range: two tiles (label, amount, share)
/// over one bar split by share. The hero hides it when both are zero.
class _ChannelSplit extends StatelessWidget {
  final double b2c;
  final double b2b;
  final double? b2cInclShipping;
  const _ChannelSplit({
    required this.b2c,
    required this.b2b,
    this.b2cInclShipping,
  }) : super(key: const ValueKey('revenue-hero-channel-split'));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // A net-negative channel (returns above sales) counts as no share.
    final c = _pos(b2c);
    final b = _pos(b2b);
    final sum = c + b;
    final b2cShare = sum > 0 ? c / sum : 0.0;
    final b2bShare = sum > 0 ? b / sum : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ChannelTile(
                label: l10n.rptRevB2c,
                amount: b2c,
                share: b2cShare,
                color: _b2cColor,
                note: b2cInclShipping == null
                    ? null
                    : l10n.rptRevB2cInclShipping(
                        formatCompactCurrency(context, b2cInclShipping!),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ChannelTile(
                label: l10n.rptRevB2b,
                amount: b2b,
                share: b2bShare,
                color: _b2bColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                // Row follows the text direction, so B2C sits at the start
                // in both LTR and RTL, matching the tiles above.
                return Row(
                  children: [
                    SizedBox(
                      width: w * b2cShare,
                      child: const ColoredBox(color: _b2cColor),
                    ),
                    SizedBox(
                      width: w * b2bShare,
                      child: const ColoredBox(color: _b2bColor),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final String label;
  final double amount;
  final double share;
  final Color color;
  final String? note;
  const _ChannelTile({
    required this.label,
    required this.amount,
    required this.share,
    required this.color,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              formatCompactCurrency(context, amount),
              maxLines: 1,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (note != null)
            Text(
              note!,
              key: const ValueKey('revenue-hero-b2c-incl-shipping'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          Text(
            '${_pct(share * 100)}%',
            maxLines: 1,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// "vs Sun 11 Oct up to 14:05" when the comparison's last day was cut at the
/// request time, "vs Sun 11 Oct" / "vs 5–11 Oct" otherwise; null when the
/// payload names no comparison window.
String? _comparisonLabel(BuildContext context, RevenuePrevious p) {
  if (p.dateFrom.isEmpty) return null;
  final l10n = context.l10n;
  final period = _rangeLabel(context, p.dateFrom, p.dateTo);
  final cut = p.cutAt?.trim() ?? '';
  return cut.isEmpty
      ? l10n.rptRevVsPeriod(period)
      : l10n.rptRevVsPeriodUpTo(period, cut);
}

// ─────────────────────────────────────────────────────────────────────────
// 3. Needs attention
// ─────────────────────────────────────────────────────────────────────────

class _AttentionSection extends StatelessWidget {
  final List<RevenueAttentionItem> items;
  const _AttentionSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Padding(
        key: const ValueKey('revenue-attention-empty'),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, size: 16, color: _positive),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.rptRevNothingNeedsAttention,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Card(
      key: const ValueKey('revenue-attention'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(l10n.rptRevNeedsAttention),
            const SizedBox(height: 4),
            for (var i = 0; i < items.length; i++)
              Padding(
                key: ValueKey('revenue-attention-$i'),
                padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 5),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: items[i].isHigh ? _negative : _amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _attentionText(context, items[i]),
                        style: theme.textTheme.bodyMedium,
                      ),
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

String _attentionText(BuildContext context, RevenueAttentionItem a) {
  final l10n = context.l10n;
  String money(double? v) => formatCompactCurrency(context, v ?? 0);
  String drop(double? v) => _pct((v ?? 0).abs());
  return switch (a.kind) {
    RevenueAttentionItem.kindCancelled => l10n.rptRevAttnCancelled(
      a.count ?? 0,
      money(a.value),
    ),
    RevenueAttentionItem.kindReturns => l10n.rptRevAttnReturns(
      a.count ?? 0,
      money(a.value),
    ),
    RevenueAttentionItem.kindBranchDrop => l10n.rptRevAttnBranchDrop(
      _branchLabel(context, a.name ?? ''),
      drop(a.changePct),
      money(a.netSales),
      money(a.compareNetSales),
    ),
    RevenueAttentionItem.kindSourceDrop => l10n.rptRevAttnSourceDrop(
      _sourceLabel(context, a.name ?? ''),
      drop(a.changePct),
      money(a.netSales),
      money(a.compareNetSales),
    ),
    _ => l10n.rptRevAttnDiscountHigh(
      money(a.value),
      _pct(a.discountPct ?? 0),
      _pct(a.compareDiscountPct ?? 0),
    ),
  };
}

// ─────────────────────────────────────────────────────────────────────────
// 4. Where it came from: source, payment, branch
// ─────────────────────────────────────────────────────────────────────────

class _MixRowData {
  final String label;
  final double amount;
  final int orders;
  final double? sharePct;
  final bool showChange;
  final double? changePct;

  /// Extra text for the second line (a branch's B2C change).
  final String? extra;
  final bool selected;
  final VoidCallback? onTap;

  const _MixRowData({
    required this.label,
    required this.amount,
    required this.orders,
    required this.sharePct,
    this.showChange = false,
    this.changePct,
    this.extra,
    this.selected = false,
    this.onTap,
  });
}

class _WhereFromCard extends StatelessWidget {
  final RevenueDashboard data;
  final String? selectedBranch;
  final ValueChanged<String>? onBranchTap;
  const _WhereFromCard({
    required this.data,
    this.selectedBranch,
    this.onBranchTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tap = onBranchTap;
    return Card(
      key: const ValueKey('revenue-where-from'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CardTitle(l10n.rptRevWhereFrom),
            const SizedBox(height: 6),
            _MixGroup(
              title: l10n.rptRevBySourceTitle,
              rows: [
                for (final r in data.bySource)
                  _MixRowData(
                    label: _sourceLabel(context, r.source),
                    amount: r.netSales,
                    orders: r.orders,
                    sharePct: r.sharePct,
                    showChange: true,
                    changePct: r.changePct,
                  ),
              ],
            ),
            const Divider(height: 16),
            _MixGroup(
              title: l10n.rptRevByPaymentTitle,
              rows: [
                for (final r in data.byPayment)
                  _MixRowData(
                    label: _paymentLabel(context, r.method),
                    amount: r.netSales,
                    orders: r.orders,
                    sharePct: r.sharePct,
                  ),
              ],
            ),
            const Divider(height: 16),
            _MixGroup(
              title: l10n.rptRevByBranchTitle,
              rows: [
                for (final r in data.byBranch)
                  _MixRowData(
                    label: _branchLabel(context, r.branch),
                    amount: r.netSales,
                    orders: r.orders,
                    sharePct: r.sharePct,
                    showChange: true,
                    changePct: r.changePct,
                    // Only worth a mention when B2C moved differently from
                    // the branch total (i.e. the branch also sold B2B).
                    extra:
                        r.b2cChangePct != null &&
                            r.b2cChangePct != r.changePct
                        ? l10n.rptRevCaptionB2c(_changeLabel(r.b2cChangePct))
                        : null,
                    selected: r.branch == selectedBranch,
                    onTap: tap == null ? null : () => tap(r.branch),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MixGroup extends StatelessWidget {
  final String title;
  final List<_MixRowData> rows;
  const _MixGroup({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: muted,
          ),
        ),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
            child: Text(l10n.reportNoData, style: theme.textTheme.bodySmall),
          ),
        for (final r in rows) _MixRow(row: r),
      ],
    );
  }
}

class _MixRow extends StatelessWidget {
  final _MixRowData row;
  const _MixRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final r = row;
    final sub = [
      l10n.pnlOrdersCount(r.orders),
      '${_pctOrDash(r.sharePct)}%',
      ?r.extra,
    ].join(' · ');
    return InkWell(
      onTap: r.onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: r.selected ? FontWeight.bold : null,
                      color: r.selected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCompactCurrency(context, r.amount),
                  maxLines: 1,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (r.showChange) _ChangeText(pct: r.changePct, small: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 5. By hour
// ─────────────────────────────────────────────────────────────────────────

class _ByHourCard extends StatelessWidget {
  /// Always 24 rows (see [RevenueDashboard.hourly]).
  final List<RevenueHourRow> rows;
  const _ByHourCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Quiet hours at either edge are trimmed; gaps inside the day stay.
    bool active(RevenueHourRow r) => r.orders > 0 || r.netSales != 0;
    final first = rows.indexWhere(active);
    final last = rows.lastIndexWhere(active);
    final shown = first < 0 ? const <RevenueHourRow>[] : rows.sublist(first, last + 1);
    final maxY = shown.fold<double>(
      0,
      (m, r) => r.netSales > m ? r.netSales : m,
    );
    final step = shown.length <= 8 ? 1 : (shown.length <= 16 ? 2 : 3);
    final color = theme.colorScheme.primary;
    final firstHour = shown.isEmpty ? 0 : shown.first.hour;

    return ReportChartCard(
      key: const ValueKey('revenue-by-hour'),
      title: l10n.rptRevByHour,
      subtitle: l10n.rptRevByHourSubtitle,
      height: 150,
      isEmpty: shown.isEmpty || maxY <= 0,
      emptyText: l10n.reportNoData,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 1 : maxY * 1.15,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (final r in shown)
              BarChartGroupData(
                x: r.hour,
                barRods: [
                  BarChartRodData(
                    toY: _pos(r.netSales),
                    color: color,
                    width: shown.length > 16 ? 6 : 10,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
          ],
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, _) {
                final r = shown.firstWhere(
                  (e) => e.hour == group.x,
                  orElse: () => RevenueHourRow(hour: group.x),
                );
                return BarTooltipItem(
                  l10n.rptRevHourTooltip(
                    '${r.hour}',
                    formatCount(context, r.orders),
                    formatCompactCurrency(context, r.netSales),
                  ),
                  theme.textTheme.labelSmall!.copyWith(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    _compact(context, value),
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final h = value.round();
                  if (value != h.toDouble() || (h - firstHour) % step != 0) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text('$h', style: theme.textTheme.labelSmall),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 6. Footer links
// ─────────────────────────────────────────────────────────────────────────

class _FooterLinks extends ConsumerWidget {
  const _FooterLinks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    void open(String route) {
      // The linked reports read the shared range: carry this period over so
      // "Products" shows the products behind the figures above.
      ref.read(reportRangeProvider.notifier).state = ref.read(
        revenueRangeProvider,
      );
      context.push(route);
    }

    return Row(
      children: [
        Expanded(
          child: _LinkButton(
            key: const ValueKey('revenue-link-products'),
            label: l10n.rptRevLinkProducts,
            onPressed: () => open(AppRoutes.reportsProduct),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _LinkButton(
            key: const ValueKey('revenue-link-b2b'),
            label: l10n.rptRevLinkB2b,
            onPressed: () => open(AppRoutes.reportsB2b),
          ),
        ),
      ],
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _LinkButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 4),
        // arrow_forward mirrors itself in RTL.
        const Icon(Icons.arrow_forward, size: 16),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Shared small pieces
// ─────────────────────────────────────────────────────────────────────────

/// The cash sitting in each branch's drawer account right now, under the
/// hero, for a user with the manager home switched on. Read from the
/// Manager Dashboard summary (`get_manager_dashboard_summary`), so it is the
/// same figure that screen shows; it ignores the date range and the branch
/// filter, because a drawer balance is "now", not a period. A failure stays
/// inside the card and never takes the revenue figures down with it.
class BranchCashCard extends ConsumerWidget {
  const BranchCashCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final async = ref.watch(dashboardSummaryProvider);
    String money(double v) => formatCurrency(context, v);

    Widget body;
    final summary = async.valueOrNull;
    if (summary != null) {
      final branches = [...summary.branches]
        ..sort((a, b) => b.combinedBalance.compareTo(a.combinedBalance));
      const figures = [FontFeature.tabularFigures()];
      Color? tint(double v) => v < 0 ? theme.colorScheme.error : null;
      final smallMuted = theme.textTheme.bodySmall?.copyWith(color: muted);
      // One labelled amount on a line: label on the start side, figure on
      // the end side. Stacked rather than three columns so a full
      // "EGP 12,345.00" never has to squeeze into a third of a phone.
      Widget line(
        String label,
        double v, {
        Key? key,
        bool bold = false,
        TextStyle? labelStyle,
      }) =>
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle ??
                      (bold
                          ? const TextStyle(fontWeight: FontWeight.bold)
                          : null),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                money(v),
                key: key,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : null,
                  fontFeatures: figures,
                  color: tint(v),
                ),
              ),
            ],
          );
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final b in branches)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  line(b.title, b.combinedBalance),
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.rptRevBranchCashDrawer} ${money(b.balance)}'
                    '  ·  '
                    '${l10n.rptRevBranchCashCouriers} ${money(b.courierBalance)}',
                    maxLines: 2,
                    style: smallMuted?.copyWith(fontFeatures: figures),
                  ),
                ],
              ),
            ),
          const Divider(height: 18),
          line(
            l10n.rptRevBranchCashDrawer,
            summary.totalBalance,
            key: const ValueKey('branch-cash-total'),
            labelStyle: smallMuted,
          ),
          const SizedBox(height: 4),
          line(
            l10n.rptRevBranchCashCouriers,
            summary.totalCourierBalance,
            key: const ValueKey('branch-cash-courier-total'),
            labelStyle: smallMuted,
          ),
          const SizedBox(height: 6),
          line(
            l10n.managerTotalCash,
            summary.totalCombinedBalance,
            key: const ValueKey('branch-cash-combined-total'),
            bold: true,
          ),
        ],
      );
    } else if (async.hasError) {
      body = Padding(
        padding: const EdgeInsetsDirectional.only(top: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.rptRevBranchCashError,
                style: TextStyle(color: muted),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(dashboardSummaryProvider),
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    } else {
      body = const Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: 12),
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Card(
      key: const ValueKey('branch-cash-card'),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.go(AppRoutes.manager),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _CardTitle(l10n.rptRevBranchCashTitle)),
                  Icon(Icons.chevron_right, size: 18, color: muted),
                ],
              ),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String text;
  const _CardTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
  );
}

/// "▲ 12.5%" in green, "▼ 3.0%" in red, "—" when there is nothing to compare.
class _ChangeText extends StatelessWidget {
  final double? pct;
  final bool small;
  const _ChangeText({required this.pct, this.small = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = small ? theme.textTheme.labelSmall : theme.textTheme.labelMedium;
    return Text(
      _changeLabel(pct),
      maxLines: 1,
      style: base?.copyWith(
        fontWeight: FontWeight.bold,
        color: _changeColor(context, pct),
      ),
    );
  }
}

/// The hero's net-sales change, on a tinted pill.
class _ChangePill extends StatelessWidget {
  final double? pct;
  const _ChangePill({required this.pct});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _changeColor(context, pct);
    return Container(
      key: const ValueKey('revenue-hero-change'),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _changeLabel(pct),
        maxLines: 1,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ── colours ───────────────────────────────────────────────────────────────

final _positive = Colors.green.shade700;
const _negative = Color(0xFFD32F2F);
const _amber = Color(0xFFF9A825);

/// The hero's channel split: B2C blue, B2B teal.
const _b2cColor = Color(0xFF1E88E5);
const _b2bColor = Color(0xFF00897B);

/// The backend's label for invoices with no POS Profile.
const _noProfile = '(No Profile)';

/// Shown where the backend sends null (nothing to compare, no orders).
const _dash = '—';

String _sourceLabel(BuildContext context, String source) {
  final l10n = context.l10n;
  return switch (source) {
    'pos' => l10n.rptRevSourcePos,
    'woo' => l10n.rptRevSourceWoo,
    'talabat' => l10n.rptRevSourceTalabat,
    'partner' => l10n.rptRevSourcePartner,
    'b2b' => l10n.rptRevB2b,
    'staff' => l10n.rptRevSourceStaff,
    'samples' => l10n.rptRevSourceSamples,
    _ => source.isEmpty ? l10n.commonNotSpecified : source,
  };
}

String _branchLabel(BuildContext context, String branch) =>
    branch == _noProfile ? context.l10n.rptRevNoProfile : branch;

String _paymentLabel(BuildContext context, String method) =>
    method.trim().toLowerCase() == 'unspecified'
    ? context.l10n.commonNotSpecified
    : localizedPaymentMethodLabel(context, method);

// ── pure helpers ──────────────────────────────────────────────────────────

double _pos(double v) => v > 0 ? v : 0;

/// One decimal, as the backend rounds percentages.
String _pct(double v) => v.toStringAsFixed(1);

String _pctOrDash(double? v) => v == null ? _dash : _pct(v);

String _changeLabel(double? pct) {
  if (pct == null) return _dash;
  if (pct > 0) return '▲ ${_pct(pct)}%';
  if (pct < 0) return '▼ ${_pct(pct.abs())}%';
  return '${_pct(0)}%';
}

Color _changeColor(BuildContext context, double? pct) {
  if (pct == null || pct == 0) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
  return pct > 0 ? _positive : _negative;
}

String _compact(BuildContext context, num value) =>
    NumberFormat.compact(locale: context.l10n.localeName).format(value);

/// A single ISO day as "Sun 11 Oct"; the raw text when it does not parse.
String _dayLabel(BuildContext context, String raw) {
  final d = DateTime.tryParse(raw);
  if (d == null) return raw.isEmpty ? _dash : raw;
  return DateFormat('EEE d MMM', context.l10n.localeName).format(d);
}

/// An ISO range as "Sun 11 Oct" (one day), "5–11 Oct" (one month),
/// "28 Sep – 4 Oct" (one year) or with years otherwise.
String _rangeLabel(BuildContext context, String from, String to) {
  final f = DateTime.tryParse(from);
  final t = DateTime.tryParse(to);
  if (f == null) return from.isEmpty ? _dash : from;
  if (t == null || DateUtils.isSameDay(f, t)) return _dayLabel(context, from);
  final locale = context.l10n.localeName;
  String fmt(String pattern, DateTime d) =>
      DateFormat(pattern, locale).format(d);
  if (f.year == t.year && f.month == t.month) {
    return '${fmt('d', f)}–${fmt('d MMM', t)}';
  }
  if (f.year == t.year) return '${fmt('d MMM', f)} – ${fmt('d MMM', t)}';
  return '${fmt('d MMM yyyy', f)} – ${fmt('d MMM yyyy', t)}';
}

// ── CSV export ────────────────────────────────────────────────────────────

List<List<String>> _exportRows(BuildContext context, RevenueDashboard? data) {
  if (data == null || data.isEmpty) return const [];
  final l10n = context.l10n;
  final s = data.summary;
  final snap = data.snapshot;
  String n(num v) => v.toStringAsFixed(2);
  String o(double? v) => v == null ? '' : n(v);
  return [
    [l10n.rptG1ColMetric, l10n.rptG1ColAmount],
    [l10n.rptRevToday, n(snap.today.netSales)],
    [l10n.rptRevYesterday, n(snap.yesterday.netSales)],
    [l10n.rptRevLast7Days, n(snap.last7Days.netSales)],
    [l10n.rptRevMonthToDate, n(snap.monthToDate.netSales)],
    const <String>[],
    [l10n.rptRevNetSales, n(s.netSales)],
    [l10n.rptRevB2c, n(s.b2c)],
    [l10n.rptRevB2b, n(s.b2b)],
    [l10n.rptRevOther, n(s.other)],
    [l10n.rptRevDeliveryFees, n(s.shippingIncome)],
    [l10n.pnlTotalRevenue, n(s.totalRevenue)],
    [l10n.reportKpiOrders, '${s.orders}'],
    [l10n.reportKpiAov, o(s.aov)],
    [l10n.rptRevDailyAverage, n(s.dailyAverage)],
    [l10n.reportKpiCustomers, '${s.customers}'],
    [l10n.rptRevReturns, n(s.returnsValue)],
    [l10n.rptRevCancelled, n(s.cancelledValue)],
    [l10n.rptRevDiscounts, n(s.discountTotal)],
    if (data.byBranch.isNotEmpty) ...[
      const <String>[],
      [
        l10n.rptBranchLabel,
        l10n.rptRevColNet,
        l10n.rptRevColB2c,
        l10n.rptRevColB2b,
        l10n.reportKpiOrders,
      ],
      for (final b in data.byBranch)
        [b.branch, n(b.netSales), n(b.b2c), n(b.b2b), '${b.orders}'],
    ],
  ];
}
