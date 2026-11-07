import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/widgets/posting_date_confirmation_dialog.dart';
import '../../models/monthly_expense_models.dart';
import '../../state/monthly_expenses_notifier.dart';

/// The call the sheet makes. Kept as a callback rather than a notifier method
/// picked by an enum, because a recurring item and a salary are paid through
/// two different endpoints and the sheet has no business knowing which is
/// which — it collects an amount, an account, a date and a remark.
typedef MonthlyExpensePaySubmit = Future<MonthlyExpenseActionResult> Function({
  required double amount,
  required String payingAccount,
  required String paymentDate,
  String? remarks,
  bool allowOverpay,
  // Only a salary payment can carry these; a recurring item ignores them. They
  // live on the shared typedef rather than in a second sheet because the cash
  // half of the two payments is identical, and forking the sheet would fork the
  // overpay handling, the account picker and the posting-date rules with it.
  List<AdvanceSettlement> settleAdvances,
  List<OrderSettlement> settleOrders,
});

/// Collects a payment for one item or one employee for the selected month.
///
/// The amount is prefilled with `remaining` and stays editable: paying a
/// landlord half now and half at the end of the month is the normal case, and a
/// locked amount would send the manager to Desk to do it.
///
/// With open balances (a salary), the sheet opens with those balances ticked
/// and the amount set to `remaining − ticked`; the amount keeps following the
/// ticks until the operator types in it.
class MonthlyExpensePaySheet extends StatefulWidget {
  final String title;

  /// The period being paid FOR, shown so it is never confused with the date the
  /// money moved — those are different fields on the server and are routinely
  /// different months (August rent paid on 3 September).
  final String periodLabel;

  final double remaining;
  final String currency;
  final List<MonthlyExpensePaymentSource> paymentSources;

  /// The registry item's `default_paying_account`, when it has one. Preselects
  /// the picker; the manager can still choose another account.
  final String? defaultPayingAccount;

  /// What to prefill the amount with when it differs from [remaining] — for a
  /// salary, the NET payable, because the advance the employee is holding is
  /// not cash we hand over again. [remaining] still drives the hint, so the
  /// month's obligation and today's cash stay two visibly different numbers.
  final double? suggestedAmount;

  /// Open balances this payment may discharge at the same time. Empty for a
  /// recurring expense, which owes nobody anything.
  final List<AdvanceEntry> advances;
  final List<EmployeeOrderEntry> orders;

  final MonthlyExpensePaySubmit onSubmit;

  const MonthlyExpensePaySheet({
    super.key,
    required this.title,
    required this.periodLabel,
    required this.remaining,
    required this.currency,
    required this.paymentSources,
    required this.onSubmit,
    this.defaultPayingAccount,
    this.suggestedAmount,
    this.advances = const [],
    this.orders = const [],
  });

  @override
  State<MonthlyExpensePaySheet> createState() => _MonthlyExpensePaySheetState();
}

class _MonthlyExpensePaySheetState extends State<MonthlyExpensePaySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _remarksController = TextEditingController();

  DateTime _paymentDate = DateTime.now();

  /// Whether the operator picked a clock time. Until they do the request stays
  /// date-only and the server stamps the time itself.
  bool _timeExplicit = false;
  MonthlyExpensePaymentSource? _source;
  bool _submitting = false;

  /// Which open balances this payment clears, by document name. A Set rather
  /// than a flag per entry so the two figures below can be recomputed from one
  /// source on every tick.
  final _selectedAdvances = <String>{};
  final _selectedOrders = <String>{};

  /// Whether the operator has typed in the amount field. Until they do, the
  /// amount FOLLOWS the ticks (remaining − settled); after that it is theirs and
  /// a tick no longer overwrites it.
  bool _amountEdited = false;

  @override
  void initState() {
    super.initState();
    _source = _resolveInitialSource();

    if (_hasSettlements) {
      // The suggested (net) amount already took these balances off. Leaving
      // them unticked is how an advance got deducted from cash AND stayed open
      // in HRMS, to be deducted again the next month (production, Nov 2026).
      // So the sheet starts with them ticked and the cash derived from the
      // ticks — the two can never disagree.
      _preselectSettlements();
      _amountController = TextEditingController(
        text: _formatAmount(_followAmount),
      );
    } else {
      final prefill = widget.suggestedAmount ?? widget.remaining;
      _amountController = TextEditingController(text: _formatAmount(prefill));
    }
  }

  /// Ticks advances first, then staff orders, in list order, for as long as
  /// the running settled total stays within [MonthlyExpensePaySheet.remaining].
  /// A balance that would overshoot is skipped (a smaller later one may still
  /// fit): settling past `remaining` is refused by the server's overpay guard,
  /// so pre-ticking it would only make the default submission fail.
  void _preselectSettlements() {
    final cap = widget.remaining + 0.01;
    var running = 0.0;
    for (final advance in widget.advances) {
      if (advance.outstanding <= 0) continue;
      if (running + advance.outstanding <= cap) {
        _selectedAdvances.add(advance.name);
        running += advance.outstanding;
      }
    }
    for (final order in widget.orders) {
      if (order.outstanding <= 0) continue;
      if (running + order.outstanding <= cap) {
        _selectedOrders.add(order.invoice);
        running += order.outstanding;
      }
    }
  }

  /// The cash that, with the ticked settlements, discharges exactly what is
  /// left of the month — never negative.
  double get _followAmount {
    final value = widget.remaining - _settleTotal;
    return value > 0 ? value : 0;
  }

  /// Two decimals, no grouping separator: this string is parsed back with
  /// `double.tryParse`, so a localised "47,000.00" would parse as 47.
  static String _formatAmount(double value) =>
      value > 0 ? value.toStringAsFixed(2) : '';

  /// Called after every tick change. Re-derives the amount unless the
  /// operator has taken it over by typing.
  void _onSettlementsChanged() {
    if (_amountEdited) return;
    _amountController.text = _formatAmount(_followAmount);
  }

  bool get _hasSettlements =>
      widget.advances.isNotEmpty || widget.orders.isNotEmpty;

  double get _typedAmount => double.tryParse(_amountController.text.trim()) ?? 0;

  /// Money discharged without cash moving: the advance already left the till
  /// when it was paid out, and the staff order was already invoiced.
  double get _settleTotal {
    var total = 0.0;
    for (final advance in widget.advances) {
      if (_selectedAdvances.contains(advance.name)) {
        total += advance.outstanding;
      }
    }
    for (final order in widget.orders) {
      if (_selectedOrders.contains(order.invoice)) {
        total += order.outstanding;
      }
    }
    return total;
  }

  List<AdvanceSettlement> get _advanceSettlements => [
        for (final advance in widget.advances)
          if (_selectedAdvances.contains(advance.name))
            AdvanceSettlement(name: advance.name, amount: advance.outstanding),
      ];

  List<OrderSettlement> get _orderSettlements => [
        for (final order in widget.orders)
          if (_selectedOrders.contains(order.invoice))
            OrderSettlement(invoice: order.invoice, amount: order.outstanding),
      ];

  MonthlyExpensePaymentSource? _resolveInitialSource() {
    if (widget.paymentSources.isEmpty) return null;
    final preferred = widget.defaultPayingAccount?.trim() ?? '';
    if (preferred.isNotEmpty) {
      for (final source in widget.paymentSources) {
        if (source.account == preferred || source.id == preferred) return source;
      }
    }
    return widget.paymentSources.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasSources = widget.paymentSources.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                widget.periodLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.monthlyExpensesPayRemainingHint(
                  formatCurrency(context, widget.remaining,
                      currencyCode: widget.currency),
                ),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.monthlyExpensesPayAmountLabel,
                  border: const OutlineInputBorder(),
                  prefixText:
                      '${currencySymbol(context, currencyCode: widget.currency)} ',
                ),
                // Keeps the two figures in the settlement block honest while the
                // amount is being typed — they are the point of that block.
                onChanged: (_) => setState(() => _amountEdited = true),
                validator: (value) {
                  final text = (value ?? '').trim();
                  final amount = text.isEmpty ? 0.0 : double.tryParse(text) ?? -1;
                  if (amount < 0) {
                    return l10n.monthlyExpensesPayAmountInvalid;
                  }
                  // Zero cash is legitimate when the whole payment is a
                  // settlement: an employee whose salary goes entirely against an
                  // advance receives nothing in hand, and refusing that would
                  // leave the advance open forever.
                  if (amount == 0 && _settleTotal <= 0) {
                    return _hasSettlements
                        ? l10n.monthlyExpensesPayAmountOrSettlement
                        : l10n.monthlyExpensesPayAmountInvalid;
                  }
                  return null;
                },
              ),
              if (_hasSettlements) ...[
                const SizedBox(height: 16),
                _settlementBlock(context),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<MonthlyExpensePaymentSource>(
                key: ValueKey<String?>(_source?.id),
                initialValue: _source,
                isExpanded: true,
                items: widget.paymentSources
                    .map(
                      (source) => DropdownMenuItem(
                        value: source,
                        child: Text(
                          l10n.monthlyExpensesPaySourceOption(
                            source.localizedLabel(languageCode),
                            formatCurrency(context, source.balance,
                                currencyCode: widget.currency),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _source = value),
                decoration: InputDecoration(
                  labelText: l10n.monthlyExpensesPayFromLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? l10n.monthlyExpensesPayFromRequired : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await pickPostingDateTime(
                    context,
                    initial: _paymentDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 400)),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() {
                      _paymentDate = picked;
                      _timeExplicit = true;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.monthlyExpensesPayDateLabel,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _timeExplicit
                        ? formatDateTime(context, _paymentDate)
                        : formatDate(context, _paymentDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarksController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.monthlyExpensesPayRemarksLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      (!_submitting && hasSources) ? () => _submit() : null,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.monthlyExpensesPaySubmit),
                ),
              ),
              if (!hasSources)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.monthlyExpensesPayNoSources,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The advances and staff orders this payment may clear, and the two figures
  /// that answer the only question the manager has at the till: how much cash
  /// leaves my hand, and how much of what they owe is gone afterwards.
  ///
  /// Those are deliberately two numbers, not one. They differ by exactly the
  /// money the employee already has, and a single "total" would let a manager
  /// hand over the settled amount in cash as well.
  Widget _settlementBlock(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    String money(double value) =>
        formatCurrency(context, value, currencyCode: widget.currency);

    // A Material rather than a decorated Container: the checkboxes below are
    // ListTiles, and a coloured DecoratedBox between a ListTile and its nearest
    // Material asserts at runtime (it would hide the ink splash). Painting the
    // background with the Material itself is the fix, not a workaround.
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.advances.isNotEmpty) ...[
              Text(
                l10n.monthlyExpensesSettleAdvancesTitle,
                style: theme.textTheme.titleSmall,
              ),
              for (final advance in widget.advances)
                CheckboxListTile(
                  value: _selectedAdvances.contains(advance.name),
                  onChanged: (checked) => setState(() {
                    if (checked == true) {
                      _selectedAdvances.add(advance.name);
                    } else {
                      _selectedAdvances.remove(advance.name);
                    }
                    _onSettlementsChanged();
                  }),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(money(advance.outstanding)),
                  subtitle: Text(
                    [
                      if (advance.postingDate != null)
                        formatDate(context, advance.postingDate!),
                      if (advance.purpose.isNotEmpty) advance.purpose,
                      advance.name,
                    ].join(' • '),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
            if (widget.orders.isNotEmpty) ...[
              Text(
                l10n.monthlyExpensesSettleOrdersTitle,
                style: theme.textTheme.titleSmall,
              ),
              for (final order in widget.orders)
                CheckboxListTile(
                  value: _selectedOrders.contains(order.invoice),
                  onChanged: (checked) => setState(() {
                    if (checked == true) {
                      _selectedOrders.add(order.invoice);
                    } else {
                      _selectedOrders.remove(order.invoice);
                    }
                    _onSettlementsChanged();
                  }),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(money(order.outstanding)),
                  subtitle: Text(
                    [
                      if (order.postingDate != null)
                        formatDate(context, order.postingDate!),
                      order.invoice,
                    ].join(' • '),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
            Text(
              l10n.monthlyExpensesSettleHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 20),
            _totalLine(
              context,
              l10n.monthlyExpensesCashToHandOver,
              money(_typedAmount),
            ),
            _totalLine(
              context,
              l10n.monthlyExpensesTotalDischarged,
              money(_typedAmount + _settleTotal),
              emphasise: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalLine(
    BuildContext context,
    String label,
    String value, {
    bool emphasise = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: emphasise ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit({bool allowOverpay = false}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final source = _source;
    if (source == null) return;

    final amount = _typedAmount;
    final remarks = _remarksController.text.trim();

    setState(() => _submitting = true);
    final result = await widget.onSubmit(
      amount: amount,
      payingAccount: source.account.isNotEmpty ? source.account : source.id,
      paymentDate: _timeExplicit
          ? formatPostingDateTimeForApi(_paymentDate)
          : formatPostingDateForApi(_paymentDate),
      remarks: remarks.isEmpty ? null : remarks,
      allowOverpay: allowOverpay,
      settleAdvances: _advanceSettlements,
      settleOrders: _orderSettlements,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      Navigator.of(context).pop(true);
      return;
    }

    // The server refused the AMOUNT, not the payment: it says by how much this
    // overshoots and the same call goes through with allow_overpay. Asking is
    // the whole point — an Auto Repeat JE submitted in Desk is exactly how an
    // item ends up looking already-paid, and the manager is the one who knows
    // whether paying again is right.
    if (result.needsOverpayConfirmation) {
      final confirmed = await _confirmOverpay(result.overpayMessage!);
      if (!mounted || confirmed != true) return;
      await _submit(allowOverpay: true);
      return;
    }

    // Anything else is a real failure; the screen's error listener has already
    // shown it, so the sheet stays open with the values intact.
  }

  Future<bool?> _confirmOverpay(String serverMessage) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = ctx.l10n;
        return AlertDialog(
          title: Text(l10n.monthlyExpensesOverpayTitle),
          // The server's own sentence, verbatim.
          //
          // Deliberately NOT through `userErrorMessage`: that presenter drops a
          // bare String it does not recognise and substitutes a generic
          // "something went wrong", which would throw away the one thing this
          // dialog exists to show — by how much the payment overshoots.
          content: Text(serverMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.monthlyExpensesOverpayConfirm),
            ),
          ],
        );
      },
    );
  }
}
