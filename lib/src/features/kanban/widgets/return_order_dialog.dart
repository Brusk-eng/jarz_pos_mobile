import 'package:flutter/material.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/utils/order_display_id.dart';
import '../../../core/utils/responsive_utils.dart';

/// What the operator chose in the return dialog.
class OrderReturnRequest {
  const OrderReturnRequest({
    required this.lines,
    required this.reason,
    required this.returnType,
    required this.refundMode,
    required this.payCourierForTrip,
    this.goodsCondition,
    this.notes,
  });

  /// `{si_detail, qty}` rows — only the lines actually coming back.
  final List<Map<String, dynamic>> lines;
  final String reason;
  final String returnType;
  final String refundMode;
  final bool payCourierForTrip;

  /// `waste` (written off) or `restock` (back on the shelf). Null when the
  /// server did not offer the question — an older build — so nothing is sent
  /// and the server keeps its own rule.
  final String? goodsCondition;
  final String? notes;
}

/// Confirmation dialog for a post-dispatch return.
///
/// Shows exactly what will be posted before anything is written: which lines
/// come back, what the customer is credited, and the two decisions the server
/// cannot make on its own — whether the courier is paid for the trip, and
/// whether money already collected is refunded now or left as customer credit.
class ReturnOrderDialog extends StatefulWidget {
  const ReturnOrderDialog({super.key, required this.preview});

  final Map<String, dynamic> preview;

  static Future<OrderReturnRequest?> show(
    BuildContext context, {
    required Map<String, dynamic> preview,
  }) {
    return showDialog<OrderReturnRequest>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReturnOrderDialog(preview: preview),
    );
  }

  @override
  State<ReturnOrderDialog> createState() => _ReturnOrderDialogState();
}

class _ReturnOrderDialogState extends State<ReturnOrderDialog> {
  static const _returnTypes = <String>[
    'Customer Return',
    'Failed Delivery',
    'Damaged',
    'Wrong Item',
  ];

  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _reasonController = TextEditingController();

  /// si_detail -> quantity selected for return.
  final Map<String, double> _selected = {};

  String _returnType = 'Customer Return';
  String _refundMode = 'customer_credit';
  bool _payCourierForTrip = true;

  /// Whether the goods came back unsellable. Follows the return type until the
  /// operator touches the switch: a "Damaged" return starts as damaged, but a
  /// failed delivery that melted on the way back is damaged too, and a dented
  /// box with good jars is not.
  bool _goodsDamaged = false;

  @override
  void initState() {
    super.initState();
    // Default to a full return: it is by far the common case, and a partial is
    // a deliberate edit away.
    for (final line in _lines) {
      final returnable = _asDouble(line['qty_returnable']);
      if (returnable > 0) {
        _selected[line['si_detail'].toString()] = returnable;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _lines =>
      (widget.preview['lines'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

  Map<String, dynamic> get _toggles =>
      (widget.preview['toggles'] as Map?)?.cast<String, dynamic>() ?? const {};

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  /// What the credit note will actually come to for the current selection.
  ///
  /// Goods alone are not the whole story. The delivery charge is a fixed amount
  /// that rides on the return which closes the order out — a partial return
  /// leaves it with the customer, because the delivery did happen and they still
  /// have some of the goods. Summing `qty * rate` on its own therefore understated
  /// a completing return, so the operator confirmed one number and the ledger
  /// took another. This mirrors the server rule in
  /// `invoice_return._apply_fixed_charge_rule`; the two must stay in step.
  double get _creditTotal {
    var total = 0.0;
    for (final line in _lines) {
      final qty = _selected[line['si_detail'].toString()] ?? 0;
      total += qty * _asDouble(line['rate']);
    }
    if (!_isPartial) {
      total += _asDouble(widget.preview['fixed_charges_remaining']);
    }
    return total;
  }

  bool get _isPartial {
    for (final line in _lines) {
      final selected = _selected[line['si_detail'].toString()] ?? 0;
      if (selected < _asDouble(line['qty_returnable'])) return true;
    }
    return false;
  }

  bool get _hasSelection => _selected.values.any((qty) => qty > 0);

  bool get _canRefundNow => _toggles['can_refund_now'] == true;

  /// Where a "refund now" will be paid from. Null when the server (older
  /// build) did not send the fields, so nothing new is shown.
  String? _refundSourceLabel() {
    final l10n = context.l10n;
    final p = widget.preview;
    if (p['refund_from_branch_cash'] == true) {
      return l10n.returnRefundFromBranchCash;
    }
    final account = p['refund_account']?.toString().trim() ?? '';
    return account.isEmpty ? null : l10n.returnRefundFromAccount(account);
  }

  bool get _canChooseCourierFee => _toggles['can_choose_courier_fee'] == true;

  /// The goods question is asked only when the server can act on the answer:
  /// it sends `goods.can_write_off` once it knows how to book the loss. An
  /// older server sends no `goods` block at all, and the switch stays hidden.
  bool get _canWriteOffGoods {
    final goods = widget.preview['goods'];
    return goods is Map && goods['can_write_off'] == true;
  }

  void _setQty(String siDetail, double max, double value) {
    setState(() {
      final clamped = value.clamp(0.0, max).toDouble();
      if (clamped <= 0) {
        _selected.remove(siDetail);
      } else {
        _selected[siDetail] = clamped;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = widget.preview['currency']?.toString() ?? '';

    return AlertDialog(
      title: Text(l10n.returnOrderTitle),
      content: SizedBox(
        width: ResponsiveUtils.getDialogWidth(context),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderDisplayId(
                    widget.preview['invoice_id']?.toString(),
                    wooOrderId: widget.preview['woo_order_id'],
                  ),
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  widget.preview['customer_name']?.toString() ?? '',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),

                Text(l10n.returnOrderLinesLabel,
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                ..._lines.map(_buildLineRow),
                const Divider(height: 24),

                _buildImpactTile(currency),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _returnType,
                  decoration: InputDecoration(labelText: l10n.returnOrderTypeLabel),
                  items: _returnTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(_localizedType(type)),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _returnType = value ?? _returnType;
                    // The type is the first hint about the goods; the switch
                    // below stays free to say otherwise.
                    _goodsDamaged = _returnType == 'Damaged';
                  }),
                ),
                const SizedBox(height: 12),

                if (_canWriteOffGoods) ...[
                  SwitchListTile(
                    key: const Key('return-goods-damaged-switch'),
                    contentPadding: EdgeInsets.zero,
                    value: _goodsDamaged,
                    onChanged: (value) => setState(() => _goodsDamaged = value),
                    title: Text(l10n.returnOrderGoodsDamagedTitle),
                    subtitle: Text(
                      _goodsDamaged
                          ? l10n.returnOrderGoodsDamagedYes
                          : l10n.returnOrderGoodsDamagedNo,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                TextFormField(
                  controller: _reasonController,
                  decoration:
                      InputDecoration(labelText: l10n.returnOrderReasonLabel),
                  maxLines: 2,
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? l10n.returnOrderReasonRequired
                      : null,
                ),
                const SizedBox(height: 12),

                if (_canChooseCourierFee) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _payCourierForTrip,
                    onChanged: (value) =>
                        setState(() => _payCourierForTrip = value),
                    title: Text(l10n.returnOrderPayCourierTitle),
                    subtitle: Text(
                      _payCourierForTrip
                          ? l10n.returnOrderPayCourierYes
                          : l10n.returnOrderPayCourierNo,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                Text(l10n.returnOrderRefundLabel,
                    style: theme.textTheme.titleSmall),
                RadioGroup<String>(
                  groupValue: _refundMode,
                  onChanged: (value) =>
                      setState(() => _refundMode = value ?? _refundMode),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: 'customer_credit',
                        title: Text(l10n.returnOrderRefundCredit),
                        dense: true,
                      ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: 'refund_now',
                        enabled: _canRefundNow,
                        title: Text(l10n.returnOrderRefundNow),
                        subtitle: _canRefundNow
                            ? (_refundSourceLabel() == null
                                ? null
                                : Text(_refundSourceLabel()!))
                            : Text(
                                _toggles['refund_blocked_reason']?.toString() ??
                                    l10n.returnOrderRefundUnavailable,
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
                        dense: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                      labelText: l10n.returnOrderNotesOptional),
                  minLines: 2,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _hasSelection ? _submit : null,
          child: Text(l10n.returnOrderConfirmButton),
        ),
      ],
    );
  }

  Widget _buildLineRow(Map<String, dynamic> line) {
    final siDetail = line['si_detail'].toString();
    final returnable = _asDouble(line['qty_returnable']);
    final alreadyReturned = _asDouble(line['qty_already_returned']);
    final selected = _selected[siDetail] ?? 0;
    final theme = Theme.of(context);

    if (returnable <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                line['item_name']?.toString() ?? line['item_code'].toString(),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.disabledColor),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.returnOrderLineFullyReturned,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.disabledColor),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line['item_name']?.toString() ?? line['item_code'].toString(),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  alreadyReturned > 0
                      ? context.l10n.returnOrderLineAvailableAfterPrior(
                          _fmt(returnable), _fmt(alreadyReturned))
                      : context.l10n
                          .returnOrderLineAvailable(_fmt(returnable)),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed:
                selected > 0 ? () => _setQty(siDetail, returnable, selected - 1) : null,
          ),
          SizedBox(
            width: 44,
            child: Text(
              _fmt(selected),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: selected < returnable
                ? () => _setQty(siDetail, returnable, selected + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildImpactTile(String currency) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Both sides must be able to give way — the label is translated
              // and the amount grows with the order value, so neither has a
              // width we can assume.
              Expanded(
                child: Text(l10n.returnOrderCreditAmountLabel,
                    style: theme.textTheme.bodyMedium),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    '${_fmt(_creditTotal)} $currency',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isPartial
                ? l10n.returnOrderPartialNotice
                : l10n.returnOrderFullNotice,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _localizedType(String type) {
    final l10n = context.l10n;
    switch (type) {
      case 'Failed Delivery':
        return l10n.returnTypeFailedDelivery;
      case 'Damaged':
        return l10n.returnTypeDamaged;
      case 'Wrong Item':
        return l10n.returnTypeWrongItem;
      default:
        return l10n.returnTypeCustomerReturn;
    }
  }

  static String _fmt(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    final lines = _selected.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {'si_detail': entry.key, 'qty': entry.value})
        .toList();
    if (lines.isEmpty) return;

    final notes = _notesController.text.trim();
    Navigator.of(context).pop(
      OrderReturnRequest(
        lines: lines,
        reason: _reasonController.text.trim(),
        returnType: _returnType,
        // A refund can only be offered when the server said it is possible;
        // fall back to credit rather than sending an option it would reject.
        refundMode: _canRefundNow ? _refundMode : 'customer_credit',
        payCourierForTrip: _canChooseCourierFee ? _payCourierForTrip : true,
        // Sent only when the question was actually asked.
        goodsCondition: _canWriteOffGoods
            ? (_goodsDamaged ? 'waste' : 'restock')
            : null,
        notes: notes.isEmpty ? null : notes,
      ),
    );
  }
}
