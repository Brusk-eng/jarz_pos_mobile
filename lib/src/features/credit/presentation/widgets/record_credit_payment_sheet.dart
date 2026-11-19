import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/business_constants.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../../../core/network/frappe_error_message.dart';
import '../../data/credit_payment_token.dart';
import '../../data/credit_repository.dart';
import '../../data/models/credit_models.dart';
import '../../state/credit_providers.dart';
import '../credit_payment_summary.dart';

/// The payment methods a shop can settle its account with.
///
/// Deliberately excludes [PaymentModes.credit]: paying a credit balance with
/// credit is not a thing, and offering it would be an invitation to create a
/// self-referential Payment Entry.
const creditSettlementMethods = <String>[
  PaymentModes.cash,
  'Instapay',
  'Mobile Wallet',
];

/// Records a rolling settlement against one shop's credit account.
///
/// The amount defaults to the whole balance because that is the common case,
/// but partial and over-payments are both normal here: shops pay invoice N
/// when invoice N+1 arrives, and round their payments. The backend allocates
/// FIFO, so the sheet's job after submitting is to report what the money
/// ACTUALLY cleared rather than to confirm what was typed.
class RecordCreditPaymentSheet extends ConsumerStatefulWidget {
  final String customer;
  final String customerName;
  final double balance;
  final String currency;

  /// Pre-selected branch, when the caller already knows one (the ledger's
  /// branch filter, or the single profile this user has).
  final String? initialPosProfile;

  /// The order the shop says it is paying for, when it names one — often the
  /// NEWEST, with the older one left open. Paid first; any extra still goes
  /// oldest-first. Null means plain rolling settlement.
  final CreditInvoice? targetInvoice;

  const RecordCreditPaymentSheet({
    super.key,
    required this.customer,
    required this.customerName,
    required this.balance,
    this.currency = '',
    this.initialPosProfile,
    this.targetInvoice,
  });

  /// Shows the sheet and returns the server's allocation result, or null when
  /// the user backed out.
  static Future<CreditPaymentResult?> show(
    BuildContext context, {
    required String customer,
    required String customerName,
    required double balance,
    String currency = '',
    String? initialPosProfile,
    CreditInvoice? targetInvoice,
  }) {
    return showModalBottomSheet<CreditPaymentResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: RecordCreditPaymentSheet(
          customer: customer,
          customerName: customerName,
          balance: balance,
          currency: currency,
          initialPosProfile: initialPosProfile,
          targetInvoice: targetInvoice,
        ),
      ),
    );
  }

  @override
  ConsumerState<RecordCreditPaymentSheet> createState() =>
      _RecordCreditPaymentSheetState();
}

class _RecordCreditPaymentSheetState
    extends ConsumerState<RecordCreditPaymentSheet> {
  late final TextEditingController _amountController;
  final TextEditingController _remarksController = TextEditingController();
  String _paymentMethod = PaymentModes.cash;
  String? _posProfile;
  bool _submitting = false;
  String? _error;

  /// One token per ATTEMPT, held per customer OUTSIDE this widget: a failed
  /// submit keeps its token — even across closing and reopening the sheet — so
  /// tapping again on the same figures is a retry the server can recognise
  /// rather than a second payment. Changing any figure mints a new one.
  CreditPaymentIdempotency get _idempotency =>
      ref.read(creditPaymentIdempotencyProvider(widget.customer));

  @override
  void initState() {
    super.initState();
    // Defaults to the full balance: settling the whole account is what the
    // shop usually hands over, and it saves the common case a keystroke. A
    // named order defaults to what is left on THAT order instead.
    final initial = _targetOutstanding ?? widget.balance;
    _amountController = TextEditingController(
      text: initial > 0 ? initial.toStringAsFixed(2) : '',
    );
    _posProfile = widget.initialPosProfile;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  String? get _targetName {
    final name = widget.targetInvoice?.invoice.trim() ?? '';
    return name.isEmpty ? null : name;
  }

  double? get _targetOutstanding =>
      _targetName == null ? null : widget.targetInvoice!.outstandingAmount;

  double? get _amount {
    final raw = _amountController.text.trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw.replaceAll(',', ''));
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final amount = _amount;
    if (amount == null || amount <= 0) {
      setState(() => _error = l10n.creditPaymentAmountInvalid);
      return;
    }
    // A user with exactly one POS profile is never asked to pick it, so the
    // implicit choice is resolved here rather than by mutating state during
    // build.
    var profile = (_posProfile ?? '').trim();
    if (profile.isEmpty) {
      final profiles =
          ref.read(creditPaymentPosProfilesProvider).valueOrNull ??
              const <String>[];
      if (profiles.length == 1) profile = profiles.first;
    }
    if (profile.isEmpty) {
      setState(() => _error = l10n.creditPaymentBranchMissing);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final remarks = _remarksController.text;
    final token = _idempotency.tokenFor(
      customer: widget.customer,
      amount: amount,
      posProfile: profile,
      paymentMethod: _paymentMethod,
      remarks: remarks,
      invoice: _targetName ?? '',
    );

    try {
      final result = await ref.read(creditRepositoryProvider).recordCreditPayment(
            customer: widget.customer,
            amount: amount,
            posProfile: profile,
            paymentMethod: _paymentMethod,
            remarks: remarks,
            idempotencyToken: token,
            invoice: _targetName,
          );
      // Accepted — including the replay branch, which means the money is in.
      // Holding on to the token would make the next real settlement look like
      // a repeat of this one and post nothing.
      _idempotency.reset();
      // The balance and the headroom both moved; anything still holding the
      // old profile would offer credit the shop no longer has.
      ref.invalidate(customerCreditProfileProvider(widget.customer));
      ref.invalidate(creditLedgerProvider);
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        // The server's own sentence — "amount exceeds the outstanding
        // balance", "no open invoices" — is more useful than a generic
        // failure, so it is unwrapped before the presenter sees it.
        _error = context.userErrorMessage(
          extractFrappeErrorMessage(error, fallback: l10n.creditPaymentFailed),
          fallback: l10n.creditPaymentFailed,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final profilesAsync = ref.watch(creditPaymentPosProfilesProvider);
    final amount = _amount;
    final overpaying = amount != null && amount > widget.balance + 0.005;

    return SafeArea(
      top: false,
      child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(l10n.creditPaymentTitle, style: theme.textTheme.titleLarge),
            Text(
              widget.customerName.isNotEmpty
                  ? widget.customerName
                  : widget.customer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_targetName != null)
              Text(
                l10n.creditPaymentTargetInvoice(
                  widget.targetInvoice!.displayId,
                ),
                style: theme.textTheme.titleSmall,
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              enabled: !_submitting,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.creditPaymentAmountLabel,
                prefixText: '${currencySymbol(context, currencyCode: widget.currency)} ',
                helperText: _targetOutstanding != null
                    ? l10n.creditPaymentTargetOutstandingHint(
                        formatCurrency(
                          context,
                          _targetOutstanding!,
                          currencyCode: widget.currency,
                        ),
                      )
                    : l10n.creditPaymentFullBalanceHint(
                        formatCurrency(
                          context,
                          widget.balance,
                          currencyCode: widget.currency,
                        ),
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            // Over-payment is allowed, not blocked: the excess becomes an
            // advance the shop's next invoice draws on, which is exactly how
            // rolling settlement works here.
            if (overpaying)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.creditPaymentAmountExceedsBalance,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: InputDecoration(
                labelText: l10n.creditPaymentMethodLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final method in creditSettlementMethods)
                  DropdownMenuItem<String>(
                    value: method,
                    child: Text(_methodLabel(context, method)),
                  ),
              ],
              onChanged: _submitting
                  ? null
                  : (value) => setState(
                      () => _paymentMethod = value ?? PaymentModes.cash,
                    ),
            ),
            const SizedBox(height: 14),
            profilesAsync.when(
              data: (profiles) {
                // A single branch is not a choice; show it selected so the
                // operator is not asked a question with one answer. Computed,
                // never assigned to state during build.
                final value = profiles.contains(_posProfile)
                    ? _posProfile
                    : (profiles.length == 1 ? profiles.first : null);
                return DropdownButtonFormField<String>(
                  initialValue: value,
                  decoration: InputDecoration(
                    labelText: l10n.creditPaymentBranchLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final profile in profiles)
                      DropdownMenuItem<String>(
                        value: profile,
                        child: Text(profile),
                      ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (selected) => setState(() => _posProfile = selected),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text(
                l10n.creditPaymentBranchLoadFailed,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _remarksController,
              enabled: !_submitting,
              decoration: InputDecoration(
                labelText: l10n.creditPaymentRemarksLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _targetName != null
                  ? l10n.creditPaymentTargetNotice
                  : l10n.creditPaymentFifoNotice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            // The balance above was read from a BRANCH-SCOPED ledger, while
            // allocation is FIFO across the whole company: one debt, one
            // customer. So the result can name invoices this branch cannot
            // list. Said here rather than papered over — the backend's scoping
            // is deliberate, the surprise is not.
            Text(
              l10n.creditAccountBranchScopeNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.creditPaymentSubmit),
            ),
            TextButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.commonCancel),
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _methodLabel(BuildContext context, String method) {
    final l10n = context.l10n;
    return switch (method) {
      PaymentModes.cash => l10n.paymentMethodCash,
      'Instapay' => l10n.paymentMethodInstapay,
      'Mobile Wallet' => l10n.paymentMethodMobileWallet,
      _ => method,
    };
  }
}

/// Reads a FIFO allocation back to the user.
///
/// Shown after the sheet closes, never merged into a one-line snackbar: with
/// two invoices cleared, one part-paid and an advance left over there are up
/// to four facts, and truncating them is how a manager comes to believe an
/// invoice was settled that was not.
class CreditPaymentResultDialog extends StatelessWidget {
  final CreditPaymentResult result;
  final String currency;

  const CreditPaymentResultDialog({
    super.key,
    required this.result,
    this.currency = '',
  });

  static Future<void> show(
    BuildContext context, {
    required CreditPaymentResult result,
    String currency = '',
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => CreditPaymentResultDialog(
        result: result,
        currency: currency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final effectiveCurrency =
        result.currency.isNotEmpty ? result.currency : currency;
    final lines = creditPaymentSummaryLines(
      l10n: l10n,
      result: result,
      money: (amount) =>
          formatCurrency(context, amount, currencyCode: effectiveCurrency),
    );

    return AlertDialog(
      // A replay is not a new payment, and titling it "Payment recorded" reads
      // as a confirmation that the SECOND tap went in.
      title: Text(
        result.isReplay
            ? l10n.creditPaymentResultAlreadyRecordedTitle
            : l10n.creditPaymentResultTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line),
            ),
          if (result.paymentEntry.isNotEmpty)
            Text(
              l10n.creditPaymentResultEntry(result.paymentEntry),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonDone),
        ),
      ],
    );
  }
}
