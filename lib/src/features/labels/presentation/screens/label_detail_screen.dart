import 'package:jarz_pos/src/core/localization/user_error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_display_mappers.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/network/user_service.dart'
    show canAccessPurchaseInvoiceProvider;
import '../../data/labels_repository.dart';
import '../../models/label_models.dart';
import '../../state/labels_notifier.dart' show labelErrorMessage;
import '../widgets/label_card.dart' show LabelSizeChip;
import '../widgets/label_sheets.dart';
import '../widgets/label_status_chip.dart';

/// One flavour's label: where it stands, what is at the printer, what it is
/// worth, and the full ledger of how it got there.
class LabelDetailScreen extends ConsumerStatefulWidget {
  final String labelName;

  const LabelDetailScreen({super.key, required this.labelName});

  @override
  ConsumerState<LabelDetailScreen> createState() => _LabelDetailScreenState();
}

class _LabelDetailScreenState extends ConsumerState<LabelDetailScreen> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final DateFormat _dateFormat =
      DateFormat('d MMM yyyy', context.l10n.localeName);
  late final DateFormat _shortDate =
      DateFormat('d MMM', context.l10n.localeName);

  CustomerLabel? _label;
  String? _error;
  bool _loading = true;
  bool _busy = false;

  /// The idempotency key of a bought-batch save that did not come back (a
  /// timeout, a dropped connection). The next sheet reuses it, so if the first
  /// attempt did land server-side the retry replays it instead of buying the
  /// batch twice. Cleared on success.
  String? _pendingBoughtRequestId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final label =
          await ref.read(labelsRepositoryProvider).getDetail(widget.labelName);
      if (mounted) setState(() => _label = label);
    } catch (error) {
      if (mounted) setState(() => _error = labelErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Runs a write, swaps in the label the server returns, and reports failure
  /// once — so no action handler has to repeat this. Returns the fresh label
  /// so a caller can chain a follow-up (the receive-then-bill flow).
  Future<CustomerLabel?> _act(
    Future<CustomerLabel> Function() action, {
    String? success,
  }) async {
    if (_busy) return null;
    setState(() => _busy = true);
    try {
      final label = await action();
      if (!mounted) return null;
      setState(() => _label = label);
      if (success != null) {
        _messengerKey.currentState
            ?.showSnackBar(SnackBar(content: Text(success)));
      }
      return label;
    } catch (error) {
      if (!mounted) return null;
      _messengerKey.currentState
          ?.showSnackBar(SnackBar(content: Text(labelErrorMessage(error))));
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _label;

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(label?.customerName ?? context.l10n.labelDetailFallbackTitle),
          actions: [
            if (label != null)
              IconButton(
                tooltip: context.l10n.labelDetailSettingsTooltip,
                icon: const Icon(Icons.tune),
                onPressed: _busy ? null : () => _editPolicy(label),
              ),
            IconButton(
              tooltip: context.l10n.labelsRefreshTooltip,
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _load,
            ),
          ],
        ),
        body: _buildBody(label),
      ),
    );
  }

  Widget _buildBody(CustomerLabel? label) {
    if (_loading && label == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (label == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.userErrorMessage(_error ?? ''),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: _load, child: Text(context.l10n.commonRetry)),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _Header(label: label, shortDate: _shortDate),
          if (_busy) const LinearProgressIndicator(),
          _Actions(
            label: label,
            busy: _busy,
            // Booking a bill is a supplier Purchase Invoice: the same manager
            // set the Purchase screen is gated on. The server enforces it.
            canRecordBought: ref.watch(canAccessPurchaseInvoiceProvider),
            onOrder: () => _orderBatch(label),
            onBought: () => _recordBought(label),
            onCount: () => _count(label),
            onMovement: () => _recordMovement(label),
          ),
          if (label.printOrders.isNotEmpty)
            _PrintOrders(
              orders: label.printOrders,
              dateFormat: _shortDate,
              busy: _busy,
              onReceive: (order) => _receive(label, order),
              onAdvance: (order, status) => _advance(label, order, status),
              onBill: (order) => _bill(order),
            ),
          _Policy(label: label, dateFormat: _dateFormat),
          _Ledger(movements: label.movements, dateFormat: _shortDate),
        ],
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────
  Future<void> _orderBatch(CustomerLabel label) async {
    final request = await showModalBottomSheet<PrintOrderRequest>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PrintOrderSheet(label: label),
    );
    if (request == null || !mounted) return;
    final l10n = context.l10n;
    final labels = label.labelsForSheets(request.qtySheets);
    final what = l10n.labelCardSheetsCount(request.qtySheets) +
        (labels > 0 ? ' (${l10n.labelCardLabelsCount(labels)})' : '');
    await _act(
      () => ref.read(labelsRepositoryProvider).createPrintOrder(
            label: label.name,
            qtySheets: request.qtySheets,
            supplier: request.supplier,
            totalCost: request.totalCost,
            notes: request.notes,
          ),
      success: l10n.labelDetailSentToPrinter(what),
    );
  }

  /// A batch already bought and delivered: order + receipt + bill in one
  /// form and one call.
  Future<void> _recordBought(CustomerLabel label) async {
    String? lastSupplier;
    for (final order in label.printOrders) {
      if (order.supplier != null && order.supplier!.isNotEmpty) {
        lastSupplier = order.supplier;
        break;
      }
    }
    final request = await showModalBottomSheet<BoughtBatchRequest>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BoughtBatchSheet(
        label: label,
        initialSupplier: lastSupplier,
        clientRequestId: _pendingBoughtRequestId,
      ),
    );
    if (request == null || !mounted) return;
    final l10n = context.l10n;
    final date = DateFormat('yyyy-MM-dd').format(request.boughtOn);
    _pendingBoughtRequestId = request.clientRequestId;
    String? invoice;
    final updated = await _act(() async {
      final result = await ref.read(labelsRepositoryProvider).recordBoughtBatch(
            label: label.name,
            qtySheets: request.qtySheets,
            receivedQty: request.receivedQty,
            supplier: request.supplier,
            totalCost: request.totalCost,
            billNo: request.billNo,
            billDate: date,
            receivedOn: date,
            isPaid: request.isPaid,
            paymentOption: request.paymentOption,
            notes: request.notes,
            clientRequestId: request.clientRequestId,
          );
      invoice = result.purchaseInvoice;
      return result.label;
    });
    if (updated == null || !mounted) return;
    _pendingBoughtRequestId = null;
    final received =
        request.receivedQty ?? label.labelsForSheets(request.qtySheets);
    final pi = invoice;
    _messengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(
        pi == null || pi.isEmpty
            ? l10n.labelDetailReceivedAdded(received)
            : l10n.labelDetailBoughtRecorded(received, pi),
      ),
    ));
  }

  Future<void> _count(CustomerLabel label) async {
    final l10n = context.l10n;
    final request = await showModalBottomSheet<CountRequest>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CountSheet(label: label),
    );
    if (request == null || !mounted) return;
    await _act(
      () => ref.read(labelsRepositoryProvider).recordCount(
            label: label.name,
            countedQty: request.countedQty,
            remarks: request.remarks,
          ),
      success: l10n.labelDetailCountSaved,
    );
  }

  Future<void> _recordMovement(CustomerLabel label) async {
    final l10n = context.l10n;
    final request = await showModalBottomSheet<MovementRequest>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MovementSheet(label: label),
    );
    if (request == null || !mounted) return;
    await _act(
      () => ref.read(labelsRepositoryProvider).recordMovement(
            label: label.name,
            movementType: request.movementType,
            qty: request.qty,
            remarks: request.remarks,
          ),
      success: l10n.labelDetailMovementRecorded,
    );
  }

  Future<void> _receive(CustomerLabel label, LabelPrintOrder order) async {
    final l10n = context.l10n;
    final received = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReceiveBatchSheet(order: order),
    );
    if (received == null || !mounted) return;
    final updated = await _act(
      () => ref.read(labelsRepositoryProvider).updatePrintOrder(
            printOrder: order.name,
            status: 'Received',
            receivedQty: received,
          ),
      success: l10n.labelDetailReceivedAdded(received),
    );
    if (updated == null || !mounted) return;

    // The batch is on the shelf; if the printer's bill was never booked, offer
    // to record it now — otherwise the stock sits on the books at zero cost.
    LabelPrintOrder? fresh;
    for (final o in updated.printOrders) {
      if (o.name == order.name) {
        fresh = o;
        break;
      }
    }
    if (fresh != null && fresh.awaitsBill) {
      await _bill(fresh);
    }
  }

  Future<void> _advance(
    CustomerLabel label,
    LabelPrintOrder order,
    String status,
  ) async {
    final statusText = localizedLabelPrintStatus(context, status);
    await _act(
      () => ref.read(labelsRepositoryProvider).updatePrintOrder(
            printOrder: order.name,
            status: status,
          ),
      success: context.l10n.labelDetailBatchMarked(statusText),
    );
  }

  /// Books the printer's bill for [order]. Manager-gated server-side; a
  /// rejection surfaces as the server's own sentence in the snackbar.
  Future<void> _bill(LabelPrintOrder order) async {
    final l10n = context.l10n;
    final request = await showModalBottomSheet<BillRequest>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RecordBillSheet(order: order),
    );
    if (request == null || !mounted) return;
    await _act(
      () => ref.read(labelsRepositoryProvider).billPrintOrder(
            printOrder: order.name,
            supplier: request.supplier,
            totalCost: request.totalCost,
            billNo: request.billNo,
            isPaid: request.isPaid,
            paymentOption: request.paymentOption,
          ),
      success: l10n.labelDetailBillRecorded,
    );
  }

  Future<void> _editPolicy(CustomerLabel label) async {
    final l10n = context.l10n;
    final request = await showModalBottomSheet<LabelPolicyRequest>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LabelPolicySheet(label: label),
    );
    if (request == null || !mounted) return;
    await _act(
      () => ref.read(labelsRepositoryProvider).updateLabel(
            label: label.name,
            labelTitle: request.labelTitle,
            enabled: request.enabled,
            storageLocation: request.storageLocation,
            labelsPerUnit: request.labelsPerUnit,
            labelsPerSheet: request.labelsPerSheet,
            defaultPrintSheets: request.defaultPrintSheets,
            minStockQty: request.minStockQty,
            notes: request.notes,
          ),
      success: l10n.labelDetailSettingsSaved,
    );
  }
}

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final CustomerLabel label;
  final DateFormat shortDate;

  const _Header({required this.label, required this.shortDate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final style =
        LabelStatusStyle.of(context, label.status,
            leadDaysMax: label.leadDaysMax);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      color: style.color.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        label.labelTitle,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (label.size != null) ...[
                      const SizedBox(width: 8),
                      LabelSizeChip(size: label.size!),
                    ],
                  ],
                ),
              ),
              LabelStatusChip(
                status: label.status,
                leadDaysMax: label.leadDaysMax,
              ),
            ],
          ),
          if (label.storageLocation != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.place_outlined,
                    size: 15, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    l10n.labelDetailStoredAt(label.locationName!),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label.tracked
                    ? '${label.onHandQty}'
                    : l10n.labelCardCoverNone,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: style.color,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(l10n.labelDetailLabelsOnHand,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(style.explanation, style: theme.textTheme.bodySmall),
          if (label.tracked) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 22,
              runSpacing: 10,
              children: [
                _Stat(
                  label: l10n.labelDetailDaysOfCover,
                  value: label.daysOfCover == null
                      ? l10n.labelDetailUnknownValue
                      : label.daysOfCover!.toStringAsFixed(1),
                ),
                _Stat(
                  label: l10n.labelDetailUsedPerDay,
                  value: label.avgDailyUsage > 0
                      ? label.avgDailyUsage.toStringAsFixed(2)
                      : l10n.labelCardCoverNone,
                ),
                _Stat(
                  label: l10n.labelDetailRunsOut,
                  value: label.runsOutOn == null
                      ? l10n.labelCardCoverNone
                      : shortDate.format(label.runsOutOn!),
                ),
                _Stat(
                  label: l10n.labelDetailUsedInDays(label.usageWindowDays),
                  value: '${label.consumedInWindow}',
                ),
                // Money stats only once a batch has been billed — a column of
                // zeroes would just say "accounting not set up" in a loud way.
                if (label.stockValue > 0)
                  _Stat(
                    label: l10n.labelDetailStockValue,
                    value: formatCurrency(context, label.stockValue),
                  ),
                if (label.avgCostPerLabel > 0)
                  _Stat(
                    label: l10n.labelDetailAvgCost,
                    value: formatCurrency(context, label.avgCostPerLabel),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  final CustomerLabel label;
  final bool busy;
  final bool canRecordBought;
  final VoidCallback onOrder;
  final VoidCallback onBought;
  final VoidCallback onCount;
  final VoidCallback onMovement;

  const _Actions({
    required this.label,
    required this.busy,
    required this.canRecordBought,
    required this.onOrder,
    required this.onBought,
    required this.onCount,
    required this.onMovement,
  });

  @override
  Widget build(BuildContext context) {
    if (!label.tracked) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          context.l10n.labelDetailRetired,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final order = Expanded(
      child: FilledButton.icon(
        onPressed: busy ? null : onOrder,
        icon: const Icon(Icons.local_printshop, size: 18),
        label: Text(context.l10n.labelDetailActionOrder),
      ),
    );
    final count = Expanded(
      child: OutlinedButton.icon(
        onPressed: busy ? null : onCount,
        icon: const Icon(Icons.checklist, size: 18),
        label: Text(context.l10n.labelDetailActionCount),
      ),
    );
    final record = Expanded(
      child: OutlinedButton.icon(
        onPressed: busy ? null : onMovement,
        icon: const Icon(Icons.edit_note, size: 18),
        label: Text(context.l10n.labelDetailActionRecord),
      ),
    );

    if (!canRecordBought) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
        child: Row(
          children: [
            order,
            const SizedBox(width: 8),
            count,
            const SizedBox(width: 8),
            record,
          ],
        ),
      );
    }

    // Four actions do not fit one row on a phone: the two ways a batch
    // arrives sit together on top, the stock corrections below.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: Column(
        children: [
          Row(
            children: [
              order,
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const ValueKey('label-action-bought'),
                  onPressed: busy ? null : onBought,
                  icon: const Icon(Icons.inventory_2, size: 18),
                  label: Text(context.l10n.labelDetailActionBought),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              count,
              const SizedBox(width: 8),
              record,
            ],
          ),
        ],
      ),
    );
  }
}

class _PrintOrders extends StatelessWidget {
  final List<LabelPrintOrder> orders;
  final DateFormat dateFormat;
  final bool busy;
  final void Function(LabelPrintOrder) onReceive;
  final void Function(LabelPrintOrder, String) onAdvance;
  final void Function(LabelPrintOrder) onBill;

  const _PrintOrders({
    required this.orders,
    required this.dateFormat,
    required this.busy,
    required this.onReceive,
    required this.onAdvance,
    required this.onBill,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.labelDetailSectionBatches),
        ...orders.map((order) {
          final due = order.expectedReadyDate;
          final subtitleBits = <String>[
            if (order.requestedOn != null)
              l10n.labelDetailOrderedOn(dateFormat.format(order.requestedOn!)),
            if (order.isOpen && due != null)
              order.isOverdue
                  ? l10n.labelDetailOverdueSince(dateFormat.format(due))
                  : l10n.labelDetailDueOn(dateFormat.format(due)),
            if (order.isReceived && order.receivedOn != null)
              order.receivedQty != order.qty
                  ? l10n.labelDetailReceivedOnQty(
                      dateFormat.format(order.receivedOn!), order.receivedQty)
                  : l10n.labelDetailReceivedOn(
                      dateFormat.format(order.receivedOn!)),
            if (order.supplier != null)
              order.supplier!
            else if (order.printerName != null)
              order.printerName!,
          ];

          final statusText = localizedLabelPrintStatus(context, order.status);
          final title = order.qtySheets > 0
              ? '${l10n.labelCardSheetsCount(order.qtySheets)} · ${l10n.labelCardLabelsCount(order.qty)} · $statusText'
              : '${l10n.labelCardLabelsCount(order.qty)} · $statusText';

          final cancelled = order.status == 'Cancelled';
          final canBill = !cancelled && !order.isBilled;

          return ListTile(
            leading: Icon(
              order.isReceived
                  ? Icons.inventory_2
                  : cancelled
                      ? Icons.cancel
                      : Icons.local_shipping,
              color: order.isOverdue ? const Color(0xFFE65100) : null,
            ),
            title: Text(title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitleBits.join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: order.isOverdue ? const Color(0xFFE65100) : null,
                  ),
                ),
                if (!cancelled) ...[
                  const SizedBox(height: 4),
                  _BillingChip(order: order),
                ],
              ],
            ),
            isThreeLine: !cancelled,
            trailing: !order.isOpen && !(order.isReceived && canBill)
                ? null
                : PopupMenuButton<String>(
                    enabled: !busy,
                    onSelected: (value) {
                      if (value == 'receive') {
                        onReceive(order);
                      } else if (value == 'bill') {
                        onBill(order);
                      } else {
                        onAdvance(order, value);
                      }
                    },
                    itemBuilder: (_) => [
                      if (order.isOpen)
                        PopupMenuItem(
                          value: 'receive',
                          child: Text(l10n.labelDetailReceiveIntoStock),
                        ),
                      if (order.isOpen && order.status == 'Requested')
                        PopupMenuItem(
                            value: 'Printing',
                            child: Text(l10n.labelDetailMarkPrinting)),
                      if (order.isOpen && order.status != 'Ready')
                        PopupMenuItem(
                            value: 'Ready',
                            child: Text(l10n.labelDetailMarkReady)),
                      if (canBill)
                        PopupMenuItem(
                          value: 'bill',
                          child: Text(l10n.labelDetailRecordBill),
                        ),
                      // A billed batch is on the books: the server refuses to
                      // cancel it until its Purchase Invoice is cancelled, so
                      // the menu does not offer what would only fail.
                      if (order.isOpen && !order.isBilled)
                        PopupMenuItem(
                            value: 'Cancelled',
                            child: Text(l10n.labelDetailCancelBatch)),
                    ],
                  ),
          );
        }),
      ],
    );
  }
}

/// Amber until the printer's bill is booked; green with the purchase invoice
/// once it is. Money that never arrived on the books stays visibly amber.
class _BillingChip extends StatelessWidget {
  final LabelPrintOrder order;

  const _BillingChip({required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final billed = order.isBilled;
    final color = billed ? const Color(0xFF2E7D32) : const Color(0xFFF9A825);
    final text = billed
        ? (order.purchaseInvoice == null
            ? l10n.labelDetailBilled
            : l10n.labelDetailBilledWithInvoice(order.purchaseInvoice!))
        : (order.totalCost > 0
            ? l10n.labelDetailUnbilledQuoted(
                formatCurrency(context, order.totalCost))
            : l10n.labelDetailUnbilled);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            billed ? Icons.receipt_long : Icons.pending_actions,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Policy extends StatelessWidget {
  final CustomerLabel label;
  final DateFormat dateFormat;

  const _Policy({required this.label, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final rows = <(String, String)>[
      if (label.item != null) (l10n.labelDetailPolicyFlavour, label.item!),
      if (label.size != null) (l10n.labelDetailPolicySize, label.size!),
      (
        l10n.labelDetailPolicyStoredAt,
        label.locationName ?? l10n.labelDetailPolicyNotSet
      ),
      (l10n.labelDetailPolicyMinStock, '${label.minStockQty}'),
      (
        l10n.labelDetailPolicyUsualBatch,
        l10n.labelCardSheetsCount(label.defaultPrintSheets)
      ),
      (l10n.labelDetailPolicyLabelsPerSheet, '${label.labelsPerSheet}'),
      (
        l10n.labelDetailPolicyLabelsPerJar,
        label.labelsPerUnit.toStringAsFixed(
            label.labelsPerUnit == label.labelsPerUnit.roundToDouble() ? 0 : 2)
      ),
      (
        l10n.labelDetailPolicyLeadTime,
        l10n.labelDetailPolicyLeadTimeValue(
            label.leadDaysMin, label.leadDaysMax, label.restDay)
      ),
      if (label.lastCountedOn != null)
        (
          l10n.labelDetailPolicyLastCounted,
          dateFormat.format(label.lastCountedOn!)
        ),
      if (label.lastMovementOn != null)
        (
          l10n.labelDetailPolicyLastMovement,
          dateFormat.format(label.lastMovementOn!)
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.labelDetailSectionSetup),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: rows
                .map(
                  (row) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            row.$1,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(row.$2,
                              style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        if (label.notes != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(label.notes!, style: theme.textTheme.bodySmall),
          ),
      ],
    );
  }
}

class _Ledger extends StatelessWidget {
  final List<LabelMovement> movements;
  final DateFormat dateFormat;

  const _Ledger({required this.movements, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    if (movements.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(l10n.labelDetailSectionHistory),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.labelDetailHistoryEmpty,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.labelDetailSectionHistory),
        ...movements.map((movement) {
          final positive = movement.isIncoming;
          final hasValue = movement.value != 0;
          return ListTile(
            dense: true,
            leading: Icon(
              positive ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: positive
                  ? const Color(0xFF2E7D32)
                  : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            title: Text(
              '${positive ? '+' : ''}${movement.qty}   ${localizedLabelMovementType(context, movement.movementType)}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                if (movement.postingDate != null)
                  dateFormat.format(movement.postingDate!),
                if (movement.referenceName != null) movement.referenceName!,
                if (movement.remarks != null) movement.remarks!,
              ].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            trailing: (!hasValue && !movement.isAutomatic)
                ? null
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasValue)
                  Text(
                    '${movement.value > 0 ? '+' : '−'}${formatCurrency(context, movement.value.abs())}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: movement.value > 0
                          ? const Color(0xFF2E7D32)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (movement.isAutomatic) ...[
                  if (hasValue) const SizedBox(width: 6),
                  Tooltip(
                    message: l10n.labelDetailAutoPosted,
                    child: Icon(Icons.bolt,
                        size: 16, color: theme.colorScheme.outline),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
