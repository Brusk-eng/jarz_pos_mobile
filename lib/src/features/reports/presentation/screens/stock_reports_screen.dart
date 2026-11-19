import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/network/user_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../data/models/report_envelopes.dart';
import '../../data/models/report_json.dart';
import '../../state/reports_providers.dart';
import '../widgets/final_products_reserved.dart';
import '../widgets/report_branch_selector.dart';
import '../widgets/report_states.dart';

/// The stock-count reports (Final Products + Materials & Consumables), per
/// branch, with stock values and group / grand totals. [initialTab] is 0 for
/// Final Products, 1 for Materials.
///
/// [singleReport] shows only the [initialTab] report, with no tab bar and no
/// swiping, for the role-gated `/reports/final-products` and
/// `/reports/materials` routes (a materials-only user must not reach the
/// Final Products tab). The two-tab mode is offered only to users who may see
/// both reports; anyone else gets the single Materials report.
class StockReportsScreen extends ConsumerStatefulWidget {
  final int initialTab;
  final bool singleReport;
  const StockReportsScreen({
    super.key,
    this.initialTab = 0,
    this.singleReport = false,
  });

  @override
  ConsumerState<StockReportsScreen> createState() => _StockReportsScreenState();
}

class _StockReportsScreenState extends ConsumerState<StockReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh(int tab, String? branch) {
    if (tab == 0) {
      ref.invalidate(finalProductsReportProvider(branch));
    } else {
      ref.invalidate(materialsReportProvider(branch));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final branch = ref.watch(reportBranchProvider);
    final roles = ref.watch(userRolesFutureProvider).valueOrNull;
    final canSeeBoth = roles?.canViewAllReports ?? false;

    final single = widget.singleReport || !canSeeBoth;
    if (single) {
      // Outside the explicit single-report routes, a user who cannot see
      // Final Products only ever gets Materials.
      final tab = widget.singleReport || canSeeBoth
          ? widget.initialTab.clamp(0, 1)
          : 1;
      final finalProducts = tab == 0;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            finalProducts ? l10n.reportsFinalProducts : l10n.reportsMaterials,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.rptG2Refresh,
              onPressed: () => _refresh(tab, branch),
            ),
          ],
        ),
        body: _WithBranch(
          child: finalProducts
              ? _FinalProductsTab(branch: branch)
              : _MaterialsTab(branch: branch),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.rptG2Refresh,
            onPressed: () => _refresh(_tabController.index, branch),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.reportsFinalProducts),
            Tab(text: l10n.reportsMaterials),
          ],
        ),
      ),
      body: _WithBranch(
        child: TabBarView(
          controller: _tabController,
          children: [
            _FinalProductsTab(branch: branch),
            _MaterialsTab(branch: branch),
          ],
        ),
      ),
    );
  }
}

/// The branch selector above a report body.
class _WithBranch extends StatelessWidget {
  final Widget child;
  const _WithBranch({required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsetsDirectional.fromSTEB(12, 8, 12, 4),
          child: ReportBranchSelector(),
        ),
        Expanded(child: child),
      ],
    );
  }
}

// ── Totals strip ───────────────────────────────────────────────────────

/// "Total qty: N  •  Stock value: X" for a group or the whole report.
class _TotalsLine extends StatelessWidget {
  final StockReportTotals totals;

  /// After-orders view: add "Held: N" when open orders hold jars here.
  final bool showHeld;

  const _TotalsLine({required this.totals, this.showHeld = false});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurfaceVariant,
    );
    // After orders, lead with what is left so the line agrees with the
    // table's Total column and the grand total card above it.
    final held = showHeld && totals.reservedQty > 0;
    final parts = [
      held
          ? '${l10n.rptReservedViewAfterOrders}: ${_formatQty(context, totals.availableQty)}'
          : '${l10n.rptG2TotalQty}: ${_formatQty(context, totals.qty)}',
      if (held)
        l10n.rptReservedHeldTotal(_formatQty(context, totals.reservedQty)),
      '${l10n.rptG2StockValue}: ${formatCurrency(context, totals.stockValue)}',
    ];
    return Text(parts.join('  •  '), style: style);
  }
}

class _GrandTotalCard extends StatelessWidget {
  final StockReportTotals totals;

  /// After-orders view: the quantity is what is left once the open orders
  /// go out, with "of N in stock" under it.
  final bool afterOrders;
  const _GrandTotalCard({required this.totals, this.afterOrders = false});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final held = afterOrders && totals.reservedQty > 0;
    final qty = held ? totals.availableQty : totals.qty;
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.rptG2GrandTotal,
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatCurrency(context, totals.stockValue),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  held ? l10n.rptReservedViewAfterOrders : l10n.rptG2TotalQty,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatQty(context, qty),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: held && qty < 0 ? theme.colorScheme.error : null,
                  ),
                ),
                if (held)
                  Text(
                    l10n.rptReservedOfInStock(_formatQty(context, totals.qty)),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Totals are only shown when the server sent them (older servers did not).
StockReportTotals? _totalsOrNull(Object? v) =>
    v is Map ? StockReportTotals.fromJson(v) : null;

// ── Tab 1: Final Products ──────────────────────────────────────────────

class _FinalProductsTab extends ConsumerWidget {
  final String? branch;
  const _FinalProductsTab({required this.branch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reportAsync = ref.watch(finalProductsReportProvider(branch));
    final view = ref.watch(finalProductsStockViewProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(finalProductsReportProvider(branch).future),
      child: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ReportErrorView(
          error: error,
          onRetry: () => ref.invalidate(finalProductsReportProvider(branch)),
        ),
        data: (data) {
          final groups = ReportJson.list(data['groups']);
          if (groups.isEmpty) {
            return ReportEmptyView(message: l10n.reportsNoData);
          }
          final grand = _totalsOrNull(data['totals']);
          // Days-of-cover thresholds are a newer key; the legend only shows
          // when the server sends them.
          final hasCover = data['cover'] is Map;
          final cover = CoverThresholds.fromJson(data['cover']);
          // Jars held by open orders are a newer key too: no toggle, no
          // summary and today's numbers when the server does not send them
          // (or its read failed, or nothing is held).
          final reserved = ReservedJars.fromReport(data['reserved']);
          final afterOrders =
              reserved != null && view == FinalProductsStockView.afterOrders;
          final header = <Widget>[
            if (reserved != null) const FinalProductsViewToggle(),
            if (grand != null)
              _GrandTotalCard(totals: grand, afterOrders: afterOrders),
            if (reserved != null) ReservedSummaryTile(reserved: reserved),
            if (hasCover || afterOrders)
              _CoverLegend(
                cover: cover,
                showDaysCover: hasCover,
                showHeld: afterOrders,
              ),
          ];
          final hasHeader = header.isNotEmpty;
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsetsDirectional.all(8),
            itemCount: groups.length + (hasHeader ? 1 : 0),
            itemBuilder: (context, index) {
              if (hasHeader && index == 0) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < header.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        header[i],
                      ],
                    ],
                  ),
                );
              }
              final group = groups[index - (hasHeader ? 1 : 0)];
              final groupName = ReportJson.str(group['group_name']);
              final warehouses = ReportJson.strings(group['warehouses']);
              final items = ReportJson.list(group['items']);
              final totals = _totalsOrNull(group['totals']);
              final table = _FinalProductsTable(
                warehouses: warehouses,
                items: items,
                cover: cover,
                afterOrders: afterOrders,
              );
              // The Small jar group is rarely looked at: start it collapsed
              // (tap the header to open; the item count stays in the header).
              if (groupName.trim().toLowerCase() == 'small') {
                return Padding(
                  padding: EdgeInsetsDirectional.only(top: index > 0 ? 16 : 0),
                  child: _CollapsibleSection(
                    title: groupName,
                    itemCount: items.length,
                    initiallyExpanded: false,
                    totals: totals,
                    showHeld: afterOrders,
                    child: table,
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index > 0) const SizedBox(height: 16),
                  _SectionHeader(title: groupName, count: items.length),
                  if (totals != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 2),
                      child: _TotalsLine(
                        totals: totals,
                        showHeld: afterOrders,
                      ),
                    ),
                  const SizedBox(height: 6),
                  table,
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ── Days of cover: cell colours ────────────────────────────────────────

/// The Final Products report's days-of-cover thresholds
/// (`data['cover']`): under [redBelow] days is red, over [greenAbove] is
/// green, in between is amber. Defaults match the backend's.
class CoverThresholds {
  final double redBelow;
  final double greenAbove;
  const CoverThresholds({this.redBelow = 3, this.greenAbove = 7});

  factory CoverThresholds.fromJson(Object? v) {
    final m = ReportJson.map(v);
    return CoverThresholds(
      redBelow: ReportJson.dbl(m['red_below'], 3),
      greenAbove: ReportJson.dbl(m['green_above'], 7),
    );
  }
}

/// How a stock quantity cell is tinted.
enum CoverTone { none, red, amber, green }

/// The tint for a quantity with [cover] days of stock at the recent sales
/// rate. No recent sales (null cover) is left untinted even at zero — a
/// branch that never sells an item would otherwise read as a wall of red
/// (an oversold bin still shows its red text). With sales, nothing on hand
/// is red.
CoverTone coverTone(
  double qty,
  double? cover,
  double redBelow,
  double greenAbove,
) {
  if (cover == null) return CoverTone.none;
  if (qty <= 0) return CoverTone.red;
  if (cover < redBelow) return CoverTone.red;
  if (cover <= greenAbove) return CoverTone.amber;
  return CoverTone.green;
}

const _coverGreen = Color(0xFF43A047); // green 600
const _coverAmber = Color(0xFFFFA000); // amber 700
const _coverRed = Color(0xFFE53935); // red 600

Color? _coverColor(CoverTone tone) => switch (tone) {
  CoverTone.none => null,
  CoverTone.red => _coverRed,
  CoverTone.amber => _coverAmber,
  CoverTone.green => _coverGreen,
};

/// Cell background for a tone; reads on light and dark surfaces.
Color? _coverTint(CoverTone tone) => _coverColor(tone)?.withValues(alpha: 0.18);

/// Days of cover with at most one decimal, in the app's locale.
String _formatDays(BuildContext context, double days) =>
    NumberFormat('#,##0.#', context.l10n.localeName).format(days);

/// "Days cover: [< 3] [3–7] [> 7] [No sales]" under the grand total, and
/// in the After-orders view "• Held for open orders" for the cell marker.
class _CoverLegend extends StatelessWidget {
  final CoverThresholds cover;
  final bool showDaysCover;
  final bool showHeld;
  const _CoverLegend({
    required this.cover,
    this.showDaysCover = true,
    this.showHeld = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final red = _formatDays(context, cover.redBelow);
    final green = _formatDays(context, cover.greenAbove);
    return Wrap(
      key: const ValueKey('final-products-cover-legend'),
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showDaysCover) ...[
          Text(
            l10n.rptG2ColumnDaysCover,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          _LegendChip(label: '< $red', color: _coverRed),
          _LegendChip(label: '$red–$green', color: _coverAmber),
          _LegendChip(label: '> $green', color: _coverGreen),
          _LegendChip(
            label: l10n.productionRoundStatusNoSales,
            color: theme.colorScheme.outline,
            neutral: true,
          ),
        ],
        if (showHeld) const ReservedLegendEntry(),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;

  /// A localized word rather than a number range: follow the text direction.
  final bool neutral;
  const _LegendChip({
    required this.label,
    required this.color,
    this.neutral = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: neutral ? 0.12 : 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        // "< 3" must not be mirrored to "3 >" in Arabic.
        textDirection: neutral ? null : TextDirection.ltr,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FinalProductsTable extends StatelessWidget {
  final List<String> warehouses;
  final List<JsonMap> items;
  final CoverThresholds cover;

  /// Show what is left once the open orders go out (`available_qty`, tinted
  /// by `available_days_cover`) instead of what is on the shelf. A cell that
  /// open orders reduce carries a [ReservedMarkerDot].
  final bool afterOrders;

  const _FinalProductsTable({
    required this.warehouses,
    required this.items,
    this.cover = const CoverThresholds(),
    this.afterOrders = false,
  });

  double _resolveItemColumnWidth({
    required double tableWidth,
    required int metricColumnCount,
  }) {
    if (metricColumnCount == 0) return tableWidth;

    final preferredWidth = tableWidth * 0.34;
    final compactWidth = tableWidth * 0.24;
    final maxWidthWhileKeepingMetricsReadable =
        tableWidth - (metricColumnCount * 44.0);

    if (maxWidthWhileKeepingMetricsReadable >= preferredWidth) {
      return preferredWidth;
    }

    return maxWidthWhileKeepingMetricsReadable > compactWidth
        ? maxWidthWhileKeepingMetricsReadable
        : compactWidth;
  }

  Widget _buildHeaderCell({
    required String text,
    required double width,
    required TextStyle? style,
    TextAlign textAlign = TextAlign.start,
  }) {
    return SizedBox(
      width: width,
      child: Tooltip(
        message: text,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 6,
            vertical: 8,
          ),
          child: Text(
            text,
            style: style,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
          ),
        ),
      ),
    );
  }

  Widget _buildTextCell({
    required String text,
    required double width,
    required TextStyle? style,
  }) {
    return SizedBox(
      width: width,
      child: Tooltip(
        message: text,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 6,
            vertical: 8,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              text,
              style: style,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumericCell({
    required String text,
    required double width,
    required TextStyle? style,
    String? tooltip,
    Color? tint,
    bool held = false,
  }) {
    Widget content = Align(
      alignment: AlignmentDirectional.centerEnd,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerEnd,
        child: Text(text, style: style, maxLines: 1, textAlign: TextAlign.end),
      ),
    );
    // Same 6/8 inset as an untinted cell, split around the tinted box.
    content = tint == null
        ? Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 6,
              vertical: 8,
            ),
            child: content,
          )
        : Padding(
            padding: const EdgeInsetsDirectional.all(3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 3,
                  vertical: 5,
                ),
                child: content,
              ),
            ),
          );
    // Open orders hold some of this stock: a dot in the top-end corner,
    // inside the cell's inset so the row height does not change.
    if (held) {
      content = Stack(
        fit: StackFit.passthrough,
        children: [
          content,
          const PositionedDirectional(
            top: 4,
            end: 4,
            child: ReservedMarkerDot(),
          ),
        ],
      );
    }
    return SizedBox(
      width: width,
      child: Tooltip(message: tooltip ?? text, child: content),
    );
  }

  /// The tint and tooltip suffix for one quantity cell, or (null, null) when
  /// the server sent no days-of-cover for this item (older servers).
  ({Color? tint, String? note}) _coverFor(
    BuildContext context, {
    required bool hasCover,
    required double qty,
    required double? days,
  }) {
    if (!hasCover) return (tint: null, note: null);
    final l10n = context.l10n;
    final tone = coverTone(qty, days, cover.redBelow, cover.greenAbove);
    final note = days == null
        ? l10n.replenishmentNoSalesYet
        : l10n.replenishmentDaysOfCover(_formatDays(context, days));
    return (tint: _coverTint(tone), note: note);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final headerStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final cellStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w500,
    );
    final totalStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final negativeStyle = cellStyle?.copyWith(color: theme.colorScheme.error);
    final negativeTotalStyle = totalStyle?.copyWith(
      color: theme.colorScheme.error,
    );
    // Stock value is a newer key; only add the column when the server sends it.
    final hasValue = items.any((i) => i.containsKey('stock_value'));

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final rawTableWidth = viewportWidth - 16;
        final tableWidth = rawTableWidth > 240 ? rawTableWidth : 240.0;
        final metricColumnCount = warehouses.length + 1 + (hasValue ? 1 : 0);
        final itemColWidth = _resolveItemColumnWidth(
          tableWidth: tableWidth,
          metricColumnCount: metricColumnCount,
        );
        final dataColWidth = metricColumnCount == 0
            ? 0.0
            : (tableWidth - itemColWidth) / metricColumnCount;

        return Padding(
          padding: const EdgeInsetsDirectional.all(8),
          child: SizedBox(
            width: tableWidth,
            child: DataTable(
              columnSpacing: 0,
              horizontalMargin: 0,
              headingRowHeight: 48,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 48,
              border: TableBorder.all(color: theme.dividerColor, width: 0.5),
              columns: [
                DataColumn(
                  label: _buildHeaderCell(
                    text: l10n.reportsItemName,
                    width: itemColWidth,
                    style: headerStyle,
                  ),
                ),
                ...warehouses.map(
                  (wh) => DataColumn(
                    label: _buildHeaderCell(
                      text: _shortWarehouse(wh),
                      width: dataColWidth,
                      style: headerStyle,
                      textAlign: TextAlign.end,
                    ),
                    numeric: true,
                  ),
                ),
                DataColumn(
                  label: _buildHeaderCell(
                    text: l10n.reportsTotal,
                    width: dataColWidth,
                    style: headerStyle,
                    textAlign: TextAlign.end,
                  ),
                  numeric: true,
                ),
                if (hasValue)
                  DataColumn(
                    label: _buildHeaderCell(
                      text: l10n.rptG2StockValue,
                      width: dataColWidth,
                      style: headerStyle,
                      textAlign: TextAlign.end,
                    ),
                    numeric: true,
                  ),
              ],
              rows: items.map((item) {
                final whQty = ReportJson.map(item['warehouse_qty']);
                final total = ReportJson.dbl(item['total_qty']);
                final itemName = ReportJson.str(item['item_name']);
                final value = ReportJson.dbl(item['stock_value']);
                final hasCover = item.containsKey('days_cover');
                final whCover = ReportJson.map(item['days_cover']);
                // After orders: what is left once the open orders go out.
                // Every key may be missing on an item (older server), so it
                // falls back to on-hand minus held, and to the on-hand cover.
                final whReserved = ReportJson.map(item['reserved_qty']);
                final whAvailable = ReportJson.map(item['available_qty']);
                final whAvailableCover =
                    item.containsKey('available_days_cover')
                    ? ReportJson.map(item['available_days_cover'])
                    : whCover;
                final totalHeld = afterOrders
                    ? ReportJson.dbl(item['total_reserved_qty'])
                    : 0.0;
                final totalShown = afterOrders
                    ? ReportJson.dblOrNull(item['total_available_qty']) ??
                          total - totalHeld
                    : total;
                final totalDays =
                    afterOrders &&
                        item.containsKey('total_available_days_cover')
                    ? ReportJson.dblOrNull(item['total_available_days_cover'])
                    : ReportJson.dblOrNull(item['total_days_cover']);
                final totalCover = _coverFor(
                  context,
                  hasCover: hasCover,
                  qty: totalShown,
                  days: totalDays,
                );
                final totalTip = totalHeld > 0
                    ? l10n.rptReservedCellTooltip(
                        l10n.reportsTotal,
                        _formatQty(context, totalShown),
                        _formatQty(context, total),
                        _formatQty(context, totalHeld),
                      )
                    : '${l10n.reportsTotal}: ${_formatQty(context, total)}';
                // Held tooltips read as one line; the on-hand ones keep the
                // days cover on a line of its own.
                final totalSep = totalHeld > 0 ? ' · ' : '\n';

                return DataRow(
                  cells: [
                    DataCell(
                      _buildTextCell(
                        text: itemName,
                        width: itemColWidth,
                        style: cellStyle,
                      ),
                    ),
                    ...warehouses.map((wh) {
                      final onHand = ReportJson.dbl(whQty[wh]);
                      final held = afterOrders
                          ? ReportJson.dbl(whReserved[wh])
                          : 0.0;
                      final qty = afterOrders
                          ? ReportJson.dblOrNull(whAvailable[wh]) ??
                                onHand - held
                          : onHand;
                      // A negative bin is stock the branch has oversold. It used to
                      // collapse to the same '-' as an empty cell, which is the one
                      // reading that hides it.
                      final formattedQty = qty != 0
                          ? _formatQty(context, qty)
                          : '-';
                      final c = _coverFor(
                        context,
                        hasCover: hasCover,
                        qty: qty,
                        days: ReportJson.dblOrNull(
                          (afterOrders ? whAvailableCover : whCover)[wh],
                        ),
                      );
                      final tip = held > 0
                          ? l10n.rptReservedCellTooltip(
                              _shortWarehouse(wh),
                              _formatQty(context, qty),
                              _formatQty(context, onHand),
                              _formatQty(context, held),
                            )
                          : '${_shortWarehouse(wh)}: $formattedQty';
                      final sep = held > 0 ? ' · ' : '\n';
                      return DataCell(
                        _buildNumericCell(
                          text: formattedQty,
                          width: dataColWidth,
                          style: qty < 0 ? negativeStyle : cellStyle,
                          tooltip: c.note == null ? tip : '$tip$sep${c.note}',
                          tint: c.tint,
                          held: held > 0,
                        ),
                      );
                    }),
                    DataCell(
                      _buildNumericCell(
                        text: _formatQty(context, totalShown),
                        width: dataColWidth,
                        style: totalShown < 0 ? negativeTotalStyle : totalStyle,
                        tooltip: totalCover.note == null
                            ? totalTip
                            : '$totalTip$totalSep${totalCover.note}',
                        tint: totalCover.tint,
                        held: totalHeld > 0,
                      ),
                    ),
                    if (hasValue)
                      DataCell(
                        _buildNumericCell(
                          text: formatCompactCurrency(context, value),
                          width: dataColWidth,
                          style: value < 0 ? negativeStyle : cellStyle,
                          tooltip:
                              '${l10n.rptG2StockValue}: ${formatCurrency(context, value)}',
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

// ── Tab 2: Materials & Consumables ─────────────────────────────────────

class _MaterialsTab extends ConsumerWidget {
  final String? branch;
  const _MaterialsTab({required this.branch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reportAsync = ref.watch(materialsReportProvider(branch));

    return RefreshIndicator(
      onRefresh: () => ref.refresh(materialsReportProvider(branch).future),
      child: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ReportErrorView(
          error: error,
          onRetry: () => ref.invalidate(materialsReportProvider(branch)),
        ),
        data: (data) {
          final rawMaterials = ReportJson.list(data['raw_materials']);
          final subAssemblies = ReportJson.list(data['sub_assemblies']);
          final consumables = ReportJson.list(data['consumables']);

          if (rawMaterials.isEmpty &&
              subAssemblies.isEmpty &&
              consumables.isEmpty) {
            return ReportEmptyView(message: l10n.reportsNoData);
          }

          final buckets = ReportJson.map(data['bucket_totals']);
          return _MaterialsBody(
            rawMaterials: rawMaterials,
            subAssemblies: subAssemblies,
            consumables: consumables,
            grandTotals: _totalsOrNull(data['totals']),
            rawTotals: _totalsOrNull(buckets['raw_materials']),
            subTotals: _totalsOrNull(buckets['sub_assemblies']),
            consumableTotals: _totalsOrNull(buckets['consumables']),
          );
        },
      ),
    );
  }
}

class _MaterialsBody extends StatelessWidget {
  final List<JsonMap> rawMaterials;
  final List<JsonMap> subAssemblies;
  final List<JsonMap> consumables;
  final StockReportTotals? grandTotals;
  final StockReportTotals? rawTotals;
  final StockReportTotals? subTotals;
  final StockReportTotals? consumableTotals;

  const _MaterialsBody({
    required this.rawMaterials,
    required this.subAssemblies,
    required this.consumables,
    this.grandTotals,
    this.rawTotals,
    this.subTotals,
    this.consumableTotals,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      children: [
        if (grandTotals != null) ...[
          _GrandTotalCard(totals: grandTotals!),
          const SizedBox(height: 12),
        ],
        if (rawMaterials.isNotEmpty) ...[
          _SectionHeader(
            title: l10n.reportsRawMaterials,
            count: rawMaterials.length,
          ),
          if (rawTotals != null) _TotalsLine(totals: rawTotals!),
          const SizedBox(height: 6),
          _CompactItemGrid(items: rawMaterials),
          const SizedBox(height: 16),
        ],
        if (subAssemblies.isNotEmpty) ...[
          _SectionHeader(
            title: l10n.reportsSubAssemblies,
            count: subAssemblies.length,
          ),
          if (subTotals != null) _TotalsLine(totals: subTotals!),
          const SizedBox(height: 6),
          _CompactItemGrid(items: subAssemblies),
          const SizedBox(height: 16),
        ],
        if (consumables.isNotEmpty)
          _CollapsibleSection(
            title: l10n.reportsConsumables,
            itemCount: consumables.length,
            initiallyExpanded: false,
            totals: consumableTotals,
            child: _CompactItemGrid(items: consumables),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _CountBadge(count: count),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 7,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        formatCount(context, count),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _CollapsibleSection extends StatelessWidget {
  final String title;
  final int itemCount;
  final bool initiallyExpanded;
  final StockReportTotals? totals;
  final bool showHeld;
  final Widget child;

  const _CollapsibleSection({
    required this.title,
    required this.itemCount,
    required this.initiallyExpanded,
    required this.child,
    this.totals,
    this.showHeld = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _CountBadge(count: itemCount),
        ],
      ),
      subtitle: totals == null
          ? null
          : _TotalsLine(totals: totals!, showHeld: showHeld),
      children: [child],
    );
  }
}

/// Compact grid: 2 items per row showing name, qty badge, value and
/// warehouse lines.
class _CompactItemGrid extends StatelessWidget {
  final List<JsonMap> items;
  const _CompactItemGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = ResponsiveUtils.getGridColumns(
          context,
          min: 2,
          max: 4,
        );
        final cardWidth =
            (constraints.maxWidth - 8 * (crossCount - 1)) / crossCount;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final itemName = ReportJson.str(item['item_name']);
            final stockUom = ReportJson.str(item['stock_uom']);
            final totalQty = ReportJson.dbl(item['total_qty']);
            final value = ReportJson.dblOrNull(item['stock_value']);
            final whQty = ReportJson.map(item['warehouse_qty']);

            return SizedBox(
              width: cardWidth,
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        itemName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_formatQty(context, totalQty)} $stockUom',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            // An oversold material reaches this card, so it has
                            // to read as a problem rather than as a small number.
                            color: totalQty < 0
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      if (value != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.rptG2StockValue}: '
                          '${formatCurrency(context, value)}',
                          style: theme.textTheme.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (whQty.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...whQty.entries.map((e) {
                          final qty = ReportJson.dbl(e.value);
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(top: 1),
                            child: Text(
                              '${_shortWarehouse(e.key)}: '
                              '${_formatQty(context, qty)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: qty < 0
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────

String _shortWarehouse(String warehouse) => shortWarehouseName(warehouse);

/// Quantities with up to two decimals, grouped, in the app's locale.
String _formatQty(BuildContext context, double qty) =>
    formatStockQty(context, qty);
