import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_display_mappers.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/utils/order_display_id.dart';
import '../../data/models/report_json.dart';
import '../../state/reports_providers.dart';

// The Final Products report's jars held by open orders.
//
// POS orders take their jars off the shelf only when the Delivery Note is
// made ("Out for Delivery"), so until then the jars are on hand but already
// sold. The server reports them under `data['reserved']` (a newer key).

// ── Shared helpers ─────────────────────────────────────────────────────

/// "Nasr city - J" → "Nasr city".
String shortWarehouseName(String warehouse) {
  final dashIdx = warehouse.lastIndexOf(' - ');
  return dashIdx > 0 ? warehouse.substring(0, dashIdx) : warehouse;
}

/// Quantities with up to two decimals, grouped, in the app's locale.
String formatStockQty(BuildContext context, double qty) =>
    NumberFormat('#,##0.##', context.l10n.localeName).format(qty);

/// "12 jars" / "12 برطمان".
String reservedJarsLabel(BuildContext context, double qty) =>
    context.l10n.rptReservedJars(qty.round(), formatStockQty(context, qty));

/// "113 jars held for 20 open orders".
String reservedSummaryText(BuildContext context, ReservedJars reserved) {
  final l10n = context.l10n;
  return l10n.rptReservedHeldFor(
    reservedJarsLabel(context, reserved.qty),
    l10n.rptReservedOpenOrders(
      reserved.orderCount,
      formatCount(context, reserved.orderCount),
    ),
  );
}

// ── Model ──────────────────────────────────────────────────────────────

class ReservedOrderItem {
  final String itemName;
  final double qty;
  const ReservedOrderItem({required this.itemName, required this.qty});

  factory ReservedOrderItem.fromJson(JsonMap j) => ReservedOrderItem(
    itemName: ReportJson.str(j['item_name'], ReportJson.str(j['item_code'])),
    qty: ReportJson.dbl(j['qty']),
  );
}

/// One open order's held jars in one warehouse.
class ReservedOrder {
  final String invoice;
  final Object? wooOrderId;
  final String customerName;
  final String state;
  final String? postingDate;
  final String? deliveryDate;
  final String? deliverySlotLabel;
  final String warehouse;
  final double qty;
  final bool overdue;
  final List<ReservedOrderItem> items;

  const ReservedOrder({
    required this.invoice,
    this.wooOrderId,
    this.customerName = '',
    this.state = '',
    this.postingDate,
    this.deliveryDate,
    this.deliverySlotLabel,
    this.warehouse = '',
    this.qty = 0,
    this.overdue = false,
    this.items = const [],
  });

  factory ReservedOrder.fromJson(JsonMap j) => ReservedOrder(
    invoice: ReportJson.str(j['invoice']),
    wooOrderId: j['woo_order_id'],
    customerName: ReportJson.str(j['customer_name'], ReportJson.str(j['customer'])),
    state: ReportJson.str(j['state']),
    postingDate: ReportJson.strOrNull(j['posting_date']),
    deliveryDate: ReportJson.strOrNull(j['delivery_date']),
    deliverySlotLabel: ReportJson.strOrNull(j['delivery_slot_label']),
    warehouse: ReportJson.str(j['warehouse']),
    qty: ReportJson.dbl(j['qty']),
    overdue: ReportJson.boolean(j['overdue']),
    items: ReportJson.listOf(j['items'], ReservedOrderItem.fromJson),
  );
}

class ReservedJars {
  final double qty;
  final int orderCount;
  final int overdueCount;

  /// Server order: oldest / most urgent first.
  final List<ReservedOrder> orders;

  const ReservedJars({
    required this.qty,
    required this.orderCount,
    required this.overdueCount,
    this.orders = const [],
  });

  /// The report's `reserved` block, or null when there is nothing to show:
  /// an older server (no key), a failed read (`failed`), or no held jars.
  static ReservedJars? fromReport(Object? v) {
    if (v is! Map) return null;
    final m = ReportJson.map(v);
    if (ReportJson.boolean(m['failed'])) return null;
    final qty = ReportJson.dbl(m['qty']);
    if (qty <= 0) return null;
    final orders = ReportJson.listOf(m['orders'], ReservedOrder.fromJson);
    return ReservedJars(
      qty: qty,
      orderCount:
          ReportJson.intOrNull(m['order_count']) ??
          orders.map((o) => o.invoice).toSet().length,
      overdueCount:
          ReportJson.intOrNull(m['overdue_count']) ??
          orders.where((o) => o.overdue).length,
      orders: orders,
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────

/// The small dot in a quantity cell whose number is reduced by open orders.
class ReservedMarkerDot extends StatelessWidget {
  final double size;
  const ReservedMarkerDot({super.key, this.size = 5});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// The legend entry for [ReservedMarkerDot]: "• Held for open orders".
class ReservedLegendEntry extends StatelessWidget {
  const ReservedLegendEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ReservedMarkerDot(size: 7),
          const SizedBox(width: 4),
          Text(
            context.l10n.rptReservedLegendHeld,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// "In stock | After orders".
class FinalProductsViewToggle extends ConsumerWidget {
  const FinalProductsViewToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(finalProductsStockViewProvider);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SegmentedButton<FinalProductsStockView>(
        key: const ValueKey('final-products-view-toggle'),
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        segments: [
          ButtonSegment(
            value: FinalProductsStockView.inStock,
            label: Text(l10n.rptReservedViewInStock),
          ),
          ButtonSegment(
            value: FinalProductsStockView.afterOrders,
            label: Text(l10n.rptReservedViewAfterOrders),
          ),
        ],
        selected: {view},
        onSelectionChanged: (selection) => ref
            .read(finalProductsStockViewProvider.notifier)
            .state = selection.first,
      ),
    );
  }
}

/// A small error-coloured tag: "6 overdue", "Overdue".
class _ErrorPill extends StatelessWidget {
  final String text;
  const _ErrorPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// "113 jars held for 20 open orders  [6 overdue]  >" under the grand total.
/// Tap for the orders.
class ReservedSummaryTile extends StatelessWidget {
  final ReservedJars reserved;
  const ReservedSummaryTile({super.key, required this.reserved});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: const ValueKey('final-products-held-summary'),
        dense: true,
        leading: Icon(
          Icons.pending_actions_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          reservedSummaryText(context, reserved),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reserved.overdueCount > 0)
              _ErrorPill(
                text: context.l10n.rptReservedOverdueCount(
                  formatCount(context, reserved.overdueCount),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => ReservedOrdersSheet.show(context, reserved),
      ),
    );
  }
}

/// The open orders holding jars, most urgent first.
class ReservedOrdersSheet extends StatelessWidget {
  final ReservedJars reserved;
  const ReservedOrdersSheet({super.key, required this.reserved});

  static Future<void> show(BuildContext context, ReservedJars reserved) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ReservedOrdersSheet(reserved: reserved),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    // Android draws edge to edge: keep the last order above the navigation
    // bar (useSafeArea only covers the top).
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.rptReservedSheetTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          reservedSummaryText(context, reserved),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      if (reserved.overdueCount > 0) ...[
                        const SizedBox(width: 8),
                        _ErrorPill(
                          text: l10n.rptReservedOverdueCount(
                            formatCount(context, reserved.overdueCount),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(l10n.rptReservedSheetHint, style: muted),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                key: const ValueKey('reserved-orders-list'),
                shrinkWrap: true,
                padding: const EdgeInsetsDirectional.only(bottom: 8),
                itemCount: reserved.orders.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) =>
                    _ReservedOrderRow(order: reserved.orders[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservedOrderRow extends StatelessWidget {
  final ReservedOrder order;
  const _ReservedOrderRow({required this.order});

  /// "Delivery Thu 19 Nov · 2–4 PM", or "Ordered 3 Jul · no delivery date".
  String? _dateText(BuildContext context) {
    final l10n = context.l10n;
    final delivery = order.deliveryDate;
    if (delivery != null) {
      final date = formatDateString(context, delivery, pattern: 'EEE d MMM');
      final slot = order.deliverySlotLabel;
      return l10n.rptReservedDeliveryOn(slot == null ? date : '$date · $slot');
    }
    final posted = order.postingDate;
    if (posted != null) {
      return l10n.rptReservedOrderedNoDate(
        formatDateString(context, posted, pattern: 'd MMM'),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final error = theme.colorScheme.error;
    final id = orderDisplayId(order.invoice, wooOrderId: order.wooOrderId);
    final dateText = _dateText(context);
    final meta = [
      if (order.warehouse.isNotEmpty) shortWarehouseName(order.warehouse),
      if (dateText != null) dateText,
      if (order.state.isNotEmpty) localizedKanbanState(context, order.state),
    ].join(' · ');
    // Arabic lists use the Arabic comma.
    final separator = l10n.localeName.startsWith('ar') ? '، ' : ', ';
    final items = order.items
        .map((i) => '${i.itemName} ×${formatStockQty(context, i.qty)}')
        .join(separator);

    return Padding(
      key: ValueKey('reserved-order-${order.invoice}-${order.warehouse}'),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                id,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: order.overdue ? error : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.customerName,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (order.overdue) ...[
                const SizedBox(width: 6),
                _ErrorPill(text: l10n.rptReservedOverdue),
              ],
              const SizedBox(width: 8),
              Text(
                reservedJarsLabel(context, order.qty),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              meta,
              style: theme.textTheme.bodySmall?.copyWith(
                color: order.overdue ? error : muted,
              ),
            ),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              items,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
