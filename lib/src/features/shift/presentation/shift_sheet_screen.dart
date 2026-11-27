import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/localized_display_mappers.dart';
import '../../../core/localization/localized_formatters.dart';
import '../../../core/localization/user_error_message.dart';
import '../data/shift_repository.dart';
import '../models/shift_sheet_models.dart';

/// The sheet for one opening entry. Auto-disposed so re-opening the screen
/// always reads the server again instead of showing a stale sheet.
final shiftSheetProvider = FutureProvider.autoDispose
    .family<ShiftSheet, String>((ref, openingEntry) {
      return ref.watch(shiftRepositoryProvider).getShiftSheet(openingEntry);
    });

/// The digital replacement for the paper sales sheet.
///
/// Staff get rows only; the server withholds `totals` and `cash_flow` from
/// them, so the money cards are simply absent (no hint that they exist) and
/// the blind count stays blind. Managers get, money first: the cash drawer
/// waterfall, sales, and delivery result, then the order rows.
class ShiftSheetScreen extends ConsumerWidget {
  const ShiftSheetScreen({super.key, required this.openingEntry});

  final String openingEntry;

  static Future<void> open(BuildContext context, String openingEntry) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ShiftSheetScreen(openingEntry: openingEntry),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(shiftSheetProvider(openingEntry));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shiftSheetTitle),
        actions: [
          IconButton(
            tooltip: l10n.shiftRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(shiftSheetProvider(openingEntry)),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.userErrorMessage(
                    e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
                    fallback: l10n.shiftSheetLoadFailed,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.invalidate(shiftSheetProvider(openingEntry)),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (sheet) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(shiftSheetProvider(openingEntry));
            await ref.read(shiftSheetProvider(openingEntry).future);
          },
          child: _SheetBody(sheet: sheet),
        ),
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.sheet});

  final ShiftSheet sheet;

  @override
  Widget build(BuildContext context) {
    final totals = sheet.totals;
    final cashFlow = sheet.cashFlow;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _Header(sheet: sheet),
        const SizedBox(height: 16),
        if (cashFlow != null) ...[
          _CashDrawerCard(flow: cashFlow),
          const SizedBox(height: 16),
        ],
        if (totals != null) ...[
          _SalesCard(totals: totals),
          const SizedBox(height: 16),
          if (totals.deliveryOrders > 0) ...[
            _DeliveryCard(totals: totals),
            const SizedBox(height: 16),
          ],
        ],
        _OrdersSection(
          orders: sheet.orders,
          amountsHidden: sheet.amountsHidden,
        ),
        const SizedBox(height: 16),
        _OverdueSection(orders: sheet.overdue),
        const SizedBox(height: 16),
        _ReturnsSection(
          returns: sheet.returns,
          amountsHidden: sheet.amountsHidden,
        ),
        const SizedBox(height: 16),
        _PayoutsSection(payouts: sheet.payouts),
        const SizedBox(height: 16),
        _FlavourSection(rows: sheet.jarsByFlavour),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.sheet});

  final ShiftSheet sheet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final opened = sheet.openedAt;
    final closed = sheet.closedAt;
    final statusColor = sheet.isOpen ? Colors.green : Colors.grey;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sheet.branchDisplay.isEmpty
                        ? sheet.openingEntry
                        : sheet.branchDisplay,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    sheet.isOpen
                        ? l10n.shiftHistoryStatusOpen
                        : l10n.shiftHistoryStatusClosed,
                  ),
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  side: BorderSide(color: statusColor.withValues(alpha: 0.24)),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ],
            ),
            if (sheet.staffLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(sheet.staffLabel, style: theme.textTheme.bodyMedium),
            ],
            if (opened != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.shiftSheetOpenedAt(formatDateTime(context, opened)),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (closed != null) ...[
              const SizedBox(height: 2),
              Text(
                l10n.shiftSheetClosedAt(formatDateTime(context, closed)),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _OrderFilter { all, outForDelivery, settled, paid }

class _OrdersSection extends StatefulWidget {
  const _OrdersSection({required this.orders, required this.amountsHidden});

  final List<ShiftSheetOrder> orders;
  final bool amountsHidden;

  @override
  State<_OrdersSection> createState() => _OrdersSectionState();
}

class _OrdersSectionState extends State<_OrdersSection> {
  _OrderFilter _filter = _OrderFilter.all;

  static bool _matchesFilter(ShiftSheetOrder o, _OrderFilter f) => switch (f) {
    _OrderFilter.all => true,
    _OrderFilter.outForDelivery => o.isOutForDelivery,
    _OrderFilter.settled => o.isSettled,
    _OrderFilter.paid => o.isPaidInDrawer,
  };

  bool _matches(ShiftSheetOrder o) => _matchesFilter(o, _filter);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final visible = widget.orders.where(_matches).toList();
    final labels = <_OrderFilter, String>{
      _OrderFilter.all: l10n.shiftSheetFilterAll,
      _OrderFilter.outForDelivery: l10n.shiftSheetReasonOutForDelivery,
      _OrderFilter.settled: l10n.shiftSheetReasonSettled,
      _OrderFilter.paid: l10n.shiftSheetReasonPaid,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.shiftSheetOrdersTitle),
        if (widget.orders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final f in _OrderFilter.values)
                  ChoiceChip(
                    key: ValueKey('shiftSheetFilter_${f.name}'),
                    label: Text(
                      '${labels[f]!} (${widget.orders.where((o) => _matchesFilter(o, f)).length})',
                    ),
                    selected: _filter == f,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
              ],
            ),
          ),
        if (visible.isEmpty)
          Text(
            // Only orders that touched the drawer are listed now.
            l10n.shiftSheetNoDrawerOrders,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          for (final order in visible)
            _OrderRow(order: order, amountsHidden: widget.amountsHidden),
      ],
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: muted?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ReturnsSection extends StatelessWidget {
  const _ReturnsSection({required this.returns, required this.amountsHidden});

  final List<ShiftSheetReturn> returns;
  final bool amountsHidden;

  String _kindLabel(BuildContext context, ShiftSheetReturn r) {
    final l10n = context.l10n;
    final base = switch (r.refundKind) {
      'cash' => l10n.shiftSheetRefundKindCash,
      'bank' => l10n.shiftSheetRefundKindBank,
      _ => l10n.shiftSheetRefundKindCredit,
    };
    final account = r.refundAccount;
    return r.refundKind == 'bank' && account != null && account.isNotEmpty
        ? '$base · $account'
        : base;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.shiftSheetReturnsTitle),
        if (returns.isEmpty)
          Text(l10n.shiftSheetNoReturns, style: theme.textTheme.bodyMedium)
        else
          for (final r in returns)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.at == null
                          ? '#${r.orderNumber}'
                          : '#${r.orderNumber} · ${formatDateTime(context, r.at!, pattern: 'h:mm a')}',
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      children: [
                        if (!amountsHidden)
                          Text(
                            '${l10n.shiftSheetReturnedAmount}: ${formatCurrency(context, r.amount)}',
                            style: muted,
                          ),
                        if (!amountsHidden)
                          Text(
                            '${l10n.shiftSheetRefundAmount}: ${formatCurrency(context, r.refundAmount)}',
                            style: muted,
                          ),
                        Text(_kindLabel(context, r), style: muted),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.amountsHidden});

  final ShiftSheetOrder order;
  final bool amountsHidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall;
    final created = order.createdAt;
    final method = order.paymentMethod;

    final ofd = order.outForDeliveryAt;
    final settled = order.settledAt;
    final paid = order.paidAt;
    String hm(DateTime d) => formatDateTime(context, d, pattern: 'h:mm a');
    final reasonChips = <Widget>[
      if (order.isNew)
        _ReasonChip(
          label: l10n.shiftSheetReasonNew,
          color: Colors.blue.shade700,
        ),
      if (order.isOutForDelivery)
        _ReasonChip(
          label: l10n.shiftSheetReasonOutForDelivery,
          color: Colors.orange.shade800,
        ),
      if (order.isSettled)
        _ReasonChip(
          label: l10n.shiftSheetReasonSettled,
          color: Colors.green.shade700,
        ),
      if (order.isPaidInDrawer)
        _ReasonChip(
          label: l10n.shiftSheetReasonPaid,
          color: Colors.teal.shade700,
        ),
      if (ofd != null)
        Text(l10n.shiftSheetOutForDeliveryAt(hm(ofd)), style: muted),
      if (settled != null)
        Text(l10n.shiftSheetSettledAt(hm(settled)), style: muted),
      if (paid != null)
        Text(
          // The amount is drawer cash, so it follows the blind-count rule.
          amountsHidden || _isZero(order.paidAmount)
              ? l10n.shiftSheetPaidInDrawerAt(hm(paid))
              : '${l10n.shiftSheetPaidInDrawerAt(hm(paid))} · ${formatCurrency(context, order.paidAmount)}',
          style: muted,
        ),
    ];

    final shipping = order.shippingExpense;
    final cashIn = order.courierCashIn;

    final details = <Widget>[
      Text(l10n.shiftSheetJarsCount(order.jars), style: muted),
      Text(
        order.isPickup
            ? l10n.shiftSheetPickup
            : l10n.shiftSheetDeliveryFee(
                formatCurrency(context, order.deliveryFee),
              ),
        style: muted,
      ),
      if (!amountsHidden && shipping != null && !order.isPickup)
        Text(
          l10n.shiftSheetRowCourierCost(formatCurrency(context, shipping)),
          style: muted,
        ),
      if (!amountsHidden && cashIn.abs() >= 0.005)
        Text(
          cashIn > 0
              ? l10n.shiftSheetRowCourierHandedIn(
                  formatCurrency(context, cashIn),
                )
              : l10n.shiftSheetRowBranchPaidCourier(
                  formatCurrency(context, -cashIn),
                ),
          style: muted?.copyWith(
            color: cashIn > 0 ? Colors.green.shade700 : Colors.orange.shade800,
          ),
        ),
      if ((order.courier ?? '').isNotEmpty)
        Text(l10n.shiftSheetCourier(order.courier!), style: muted),
      if ((order.area ?? '').isNotEmpty) Text(order.area!, style: muted),
      if ((method ?? '').isNotEmpty)
        Text(localizedPaymentMethodLabel(context, method), style: muted),
      if (order.isUnpaid)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${l10n.shiftSheetUnpaid} · ${formatCurrency(context, order.outstandingAmount)}',
            style: muted?.copyWith(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    created == null
                        ? '#${order.orderNumber}'
                        : '#${order.orderNumber} · ${formatDateTime(context, created, pattern: 'h:mm a')}',
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatCurrency(context, order.grandTotal),
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: reasonChips,
            ),
            const SizedBox(height: 4),
            Wrap(spacing: 10, runSpacing: 2, children: details),
          ],
        ),
      ),
    );
  }
}

/// "2h 5m" style duration; days once it reaches a full day.
String _lateDuration(BuildContext context, int minutes) {
  final l10n = context.l10n;
  final m = minutes < 0 ? 0 : minutes;
  if (m < 60) return l10n.shiftSheetDurationMinutes(m);
  if (m < 24 * 60) {
    return l10n.shiftSheetDurationHoursMinutes(m ~/ 60, m % 60);
  }
  return l10n.shiftSheetDurationDaysHours(
    m ~/ (24 * 60),
    (m % (24 * 60)) ~/ 60,
  );
}

/// Orders whose delivery slot ended without them going out. Shown to staff
/// and managers alike: it is the "what did we miss" list for the shift.
class _OverdueSection extends StatelessWidget {
  const _OverdueSection({required this.orders});

  final List<ShiftSheetOverdueOrder> orders;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      key: const ValueKey('shiftSheetOverdue'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.shiftSheetOverdueTitle),
        if (orders.isEmpty)
          Text(
            l10n.shiftSheetNoOverdue,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          for (final o in orders) _OverdueRow(order: o),
      ],
    );
  }
}

class _OverdueRow extends StatelessWidget {
  const _OverdueRow({required this.order});

  final ShiftSheetOverdueOrder order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall;
    final wentOut = order.wentOutAt;
    // Red while it is still sitting in the branch; amber once it left late.
    final accent = wentOut == null
        ? Colors.red.shade700
        : Colors.orange.shade800;

    final customer = order.customerName;
    final title = (customer ?? '').isEmpty
        ? '#${order.orderNumber}'
        : '#${order.orderNumber} · $customer';

    final slotStart = order.slotStart;
    final deadline = order.deadline;
    final slot = (order.slotLabel ?? '').isNotEmpty
        ? order.slotLabel!
        : slotStart != null
        ? formatDateTime(context, slotStart)
        : deadline != null
        ? formatDateTime(context, deadline)
        : null;

    final tags = <Widget>[
      _ReasonChip(
        label: l10n.shiftSheetLateBy(_lateDuration(context, order.minutesLate)),
        color: accent,
      ),
      _ReasonChip(
        label: order.dueInThisShift
            ? l10n.shiftSheetDueThisShift
            : l10n.shiftSheetFromEarlierShift,
        color: order.dueInThisShift
            ? Colors.orange.shade800
            : Colors.red.shade700,
      ),
      if (order.isPickup)
        _ReasonChip(label: l10n.shiftSheetPickup, color: Colors.blue.shade700),
    ];

    final details = <Widget>[
      if (slot != null) Text(slot, style: muted),
      if ((order.state ?? '').isNotEmpty)
        Text(localizedKanbanState(context, order.state), style: muted),
      if ((order.area ?? '').isNotEmpty) Text(order.area!, style: muted),
      Text(
        wentOut != null
            ? l10n.shiftSheetWentOutLaterAt(formatDateTime(context, wentOut))
            : l10n.shiftSheetNotSentOutYet,
        style: muted?.copyWith(
          color: wentOut != null ? Colors.orange.shade800 : Colors.red.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    ];

    return Card(
      key: ValueKey('shiftSheetOverdue_${order.name}'),
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.04),
          border: BorderDirectional(start: BorderSide(color: accent, width: 3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: tags,
            ),
            const SizedBox(height: 4),
            Wrap(spacing: 10, runSpacing: 2, children: details),
          ],
        ),
      ),
    );
  }
}

class _FlavourSection extends StatelessWidget {
  const _FlavourSection({required this.rows});

  final List<ShiftSheetFlavour> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final showSmall = rows.any((r) => r.small != 0);
    final showMedium = rows.any((r) => r.medium != 0);
    final showLarge = rows.any((r) => r.large != 0);

    Widget cell(String text, {bool header = false, bool end = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(
          text,
          textAlign: end ? TextAlign.end : TextAlign.start,
          style: header
              ? theme.textTheme.labelMedium
              : theme.textTheme.bodyMedium,
        ),
      );
    }

    final visible = rows
        .where((r) => r.small != 0 || r.medium != 0 || r.large != 0)
        .toList();

    // Collapsed by default so the money comes first; the jar counts are a
    // reference the manager opens on demand.
    return ExpansionTile(
      key: const ValueKey('shiftSheetFlavours'),
      tilePadding: EdgeInsetsDirectional.zero,
      childrenPadding: const EdgeInsetsDirectional.only(bottom: 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        l10n.shiftSheetJarsByFlavour,
        style: theme.textTheme.titleMedium,
      ),
      children: [
        if (visible.isEmpty)
          Text(l10n.shiftSheetNoJars, style: theme.textTheme.bodyMedium)
        else
          Table(
            columnWidths: {
              0: const FlexColumnWidth(3),
              if (showSmall) 1: const FlexColumnWidth(1.2),
              if (showMedium) 2: const FlexColumnWidth(1.2),
              if (showLarge) 3: const FlexColumnWidth(1.2),
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: theme.dividerColor),
              bottom: BorderSide(color: theme.dividerColor),
            ),
            children: [
              TableRow(
                children: [
                  cell(l10n.shiftSheetFlavour, header: true),
                  if (showSmall)
                    cell(l10n.shiftSheetSmall, header: true, end: true),
                  if (showMedium)
                    cell(l10n.shiftSheetMedium, header: true, end: true),
                  if (showLarge)
                    cell(l10n.shiftSheetLarge, header: true, end: true),
                ],
              ),
              for (final r in visible)
                TableRow(
                  children: [
                    cell(r.flavour),
                    if (showSmall) cell('${r.small}', end: true),
                    if (showMedium) cell('${r.medium}', end: true),
                    if (showLarge) cell('${r.large}', end: true),
                  ],
                ),
            ],
          ),
      ],
    );
  }
}

class _PayoutsSection extends StatelessWidget {
  const _PayoutsSection({required this.payouts});

  final List<ShiftSheetPayout> payouts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.shiftSheetPayoutsTitle),
        if (payouts.isEmpty)
          Text(l10n.shiftSheetNoPayouts, style: theme.textTheme.bodyMedium)
        else
          for (final p in payouts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.label, style: theme.textTheme.bodyMedium),
                        Text(
                          [
                            p.kind == 'advance'
                                ? l10n.shiftSheetPayoutAdvance
                                : l10n.shiftSheetPayoutExpense,
                            if ((p.status ?? '').isNotEmpty) p.status!,
                          ].join(' · '),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatCurrency(context, p.amount),
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// One label/value line used by the manager cards.
class _KvRow extends StatelessWidget {
  const _KvRow({
    required this.label,
    this.value = '',
    this.valueColor,
    this.bold = false,
    this.valueWidget,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  /// Replaces the [value] text (e.g. the difference pill).
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = bold
        ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyMedium;
    final valueStyle = bold
        ? theme.textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          )
        : theme.textTheme.titleSmall?.copyWith(color: valueColor);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          const SizedBox(width: 8),
          valueWidget ?? Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

String _signedMoney(BuildContext context, double v) {
  final abs = formatCurrency(context, v.abs());
  if (v.abs() < 0.005) return abs;
  return v > 0 ? '+$abs' : '−$abs';
}

bool _isZero(double v) => v.abs() < 0.005;

/// The drawer waterfall: opening cash, each movement, then expected vs
/// counted. Manager-only (the server sends `cash_flow` to managers only).
class _CashDrawerCard extends StatelessWidget {
  const _CashDrawerCard({required this.flow});

  final ShiftSheetCashFlow flow;

  String _kindLabel(BuildContext context, String kind) {
    final l10n = context.l10n;
    return switch (kind) {
      'sales_cash' => l10n.shiftSheetCashSales,
      'courier_orders' => l10n.shiftSheetCashCourierOrders,
      'courier_fees' => l10n.shiftSheetCashCourierFees,
      'expenses' => l10n.shiftSheetCashExpenses,
      'refunds' => l10n.shiftSheetCashRefunds,
      'handovers' => l10n.shiftSheetCashHandovers,
      _ => l10n.shiftSheetCashOther,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final counted = flow.counted;
    final diff =
        flow.difference ?? (counted == null ? null : counted - flow.expected);

    return Card(
      key: const ValueKey('shiftSheetCashDrawer'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(l10n.shiftSheetCashTitle),
            _KvRow(
              label: l10n.shiftSheetOpeningCash,
              value: formatCurrency(context, flow.opening),
            ),
            for (final kind in ShiftSheetCashFlow.kinds)
              if (!_isZero(flow.amountOf(kind)))
                _CashMovementRow(
                  key: ValueKey('shiftSheetCash_$kind'),
                  label: _kindLabel(context, kind),
                  amount: flow.amountOf(kind),
                  lines: flow.linesOf(kind),
                ),
            const Divider(height: 20),
            _KvRow(
              label: flow.isOpen
                  ? l10n.shiftSheetCashExpectedSoFar
                  : l10n.shiftSheetCashExpected,
              value: formatCurrency(context, flow.expected),
              bold: true,
            ),
            if (!flow.isOpen) ...[
              _KvRow(
                label: l10n.shiftSheetCashCounted,
                value: counted == null
                    ? l10n.commonNotSpecified
                    : formatCurrency(context, counted),
              ),
              if (diff != null)
                _KvRow(
                  label: l10n.shiftSheetDifference,
                  valueWidget: _DiffPill(diff: diff),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Green "Matches", red "Short X" or orange "Over X".
class _DiffPill extends StatelessWidget {
  const _DiffPill({required this.diff});

  final double diff;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (String text, Color color) = _isZero(diff)
        ? (l10n.shiftSheetCashMatches, Colors.green.shade700)
        : diff < 0
        ? (
            l10n.shiftSheetCashShort(formatCurrency(context, -diff)),
            Colors.red.shade700,
          )
        : (
            l10n.shiftSheetCashOver(formatCurrency(context, diff)),
            Colors.orange.shade800,
          );
    return Container(
      key: const ValueKey('shiftSheetDiffPill'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A waterfall row; when the server sent the vouchers behind it, tapping it
/// lists them inline.
class _CashMovementRow extends StatefulWidget {
  const _CashMovementRow({
    super.key,
    required this.label,
    required this.amount,
    required this.lines,
  });

  final String label;
  final double amount;
  final List<ShiftSheetCashLine> lines;

  @override
  State<_CashMovementRow> createState() => _CashMovementRowState();
}

class _CashMovementRowState extends State<_CashMovementRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = _signedMoney(context, widget.amount);
    if (widget.lines.isEmpty) {
      return _KvRow(label: widget.label, value: value);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Flexible(
                  child: Text(widget.label, style: theme.textTheme.bodyMedium),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const Spacer(),
                const SizedBox(width: 8),
                Text(value, style: theme.textTheme.titleSmall),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            margin: const EdgeInsetsDirectional.only(start: 8, bottom: 4),
            decoration: BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(color: theme.dividerColor, width: 2),
              ),
            ),
            child: Column(
              children: [
                for (final line in widget.lines)
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsetsDirectional.only(start: 8),
                    title: Text(
                      line.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: line.at == null
                        ? null
                        : Text(
                            formatDateTime(
                              context,
                              line.at!,
                              pattern: 'h:mm a',
                            ),
                          ),
                    trailing: Text(
                      _signedMoney(context, line.amount),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Sales of the orders created in this shift (manager only).
class _SalesCard extends StatelessWidget {
  const _SalesCard({required this.totals});

  final ShiftSheetTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('shiftSheetSales'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(l10n.shiftSheetSalesTitle),
            _KvRow(
              label: l10n.shiftSheetSalesOrdersCreated,
              value: '${totals.orders}',
            ),
            _KvRow(label: l10n.shiftSheetTotalJars, value: '${totals.jars}'),
            _KvRow(
              label: l10n.shiftSheetTotalSales,
              value: formatCurrency(context, totals.grandTotal),
            ),
            _KvRow(
              label: l10n.shiftSheetSalesDeliveryCharged,
              value: formatCurrency(context, totals.deliveryFees),
            ),
            const SizedBox(height: 4),
            Text(l10n.shiftSheetSalesNote, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// What delivery earned versus what the couriers cost (manager only).
class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.totals});

  final ShiftSheetTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final net = totals.deliveryNet;
    final loss = net < 0 && !_isZero(net);
    return Card(
      key: const ValueKey('shiftSheetDelivery'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(l10n.shiftSheetDeliveryTitle),
            _KvRow(
              label: l10n.shiftSheetDeliveryOrdersOut,
              value: '${totals.deliveryOrders}',
            ),
            _KvRow(
              label: l10n.shiftSheetDeliveryIncome,
              value: formatCurrency(context, totals.deliveryIncome),
            ),
            _KvRow(
              label: l10n.shiftSheetDeliveryCost,
              value: formatCurrency(context, totals.deliveryCost),
            ),
            const Divider(height: 16),
            _KvRow(
              label: loss
                  ? l10n.shiftSheetDeliveryLoss
                  : l10n.shiftSheetDeliveryProfit,
              value: formatCurrency(context, net.abs()),
              valueColor: loss ? Colors.red.shade700 : Colors.green.shade700,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}
