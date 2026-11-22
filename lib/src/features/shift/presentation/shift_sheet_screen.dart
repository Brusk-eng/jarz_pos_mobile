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
/// Staff get rows only; the server withholds `totals` from them, so the totals
/// card is simply absent (no hint that it exists) and the blind count stays
/// blind. Managers get the totals card as well.
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _Header(sheet: sheet),
        const SizedBox(height: 16),
        if (totals != null) ...[
          _TotalsCard(totals: totals),
          const SizedBox(height: 16),
        ],
        _OrdersSection(orders: sheet.orders),
        const SizedBox(height: 16),
        _FlavourSection(rows: sheet.jarsByFlavour),
        const SizedBox(height: 16),
        _PayoutsSection(payouts: sheet.payouts),
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

class _OrdersSection extends StatelessWidget {
  const _OrdersSection({required this.orders});

  final List<ShiftSheetOrder> orders;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.shiftSheetOrdersTitle),
        if (orders.isEmpty)
          Text(
            l10n.shiftSheetNoOrders,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          for (final order in orders) _OrderRow(order: order),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final ShiftSheetOrder order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall;
    final created = order.createdAt;
    final method = order.paymentMethod;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.shiftSheetJarsByFlavour),
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

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals});

  final ShiftSheetTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final diff = totals.difference;
    final diffColor = diff == null || diff == 0
        ? null
        : (diff > 0 ? Colors.green.shade700 : Colors.red.shade700);

    Widget row(String label, String value, {Color? color}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            const SizedBox(width: 8),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(color: color),
            ),
          ],
        ),
      );
    }

    String optMoney(double? v) =>
        v == null ? l10n.commonNotSpecified : formatCurrency(context, v);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(l10n.shiftSheetTotalsTitle),
            row(l10n.shiftSheetTotalOrders, '${totals.orders}'),
            row(l10n.shiftSheetTotalJars, '${totals.jars}'),
            row(
              l10n.shiftSheetTotalSales,
              formatCurrency(context, totals.grandTotal),
            ),
            row(
              l10n.shiftSheetTotalDeliveryFees,
              formatCurrency(context, totals.deliveryFees),
            ),
            row(
              l10n.shiftSheetTotalPayouts,
              formatCurrency(context, totals.payouts),
            ),
            const Divider(height: 20),
            row(
              l10n.shiftSheetOpeningCash,
              formatCurrency(context, totals.openingAmount),
            ),
            row(l10n.shiftSheetExpectedClosing, optMoney(totals.expectedClosing)),
            row(l10n.shiftSheetCountedClosing, optMoney(totals.actualClosing)),
            row(
              l10n.shiftSheetDifference,
              optMoney(totals.difference),
              color: diffColor,
            ),
          ],
        ),
      ),
    );
  }
}
