import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../../../core/widgets/posting_date_confirmation_dialog.dart';
import '../../models/cash_custody_models.dart';
import '../../state/cash_custody_notifier.dart';
import '../custody_labels.dart';

enum CustodyMovementMode { issue, returnCash }

/// Bottom sheet for moving cash into (issue) or out of (return) a custody.
///
/// Pops with the [CustodyMovementResult] on success. A server refusal stays
/// on the sheet, shown through the shared error presenter, so the operator
/// can correct the amount without re-entering everything.
class CustodyMovementSheet extends ConsumerStatefulWidget {
  final CustodyMovementMode mode;
  final CustodyHolder holder;
  final List<CustodyAccountOption> accounts;

  /// Only managers may date a custody movement (the server refuses a date
  /// from anyone else); for a holder the movement is stamped with "now".
  final bool allowDate;

  const CustodyMovementSheet({
    super.key,
    required this.mode,
    required this.holder,
    required this.accounts,
    this.allowDate = false,
  });

  static Future<CustodyMovementResult?> show(
    BuildContext context, {
    required CustodyMovementMode mode,
    required CustodyHolder holder,
    required List<CustodyAccountOption> accounts,
    bool allowDate = false,
  }) {
    return showModalBottomSheet<CustodyMovementResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CustodyMovementSheet(
        mode: mode,
        holder: holder,
        accounts: accounts,
        allowDate: allowDate,
      ),
    );
  }

  @override
  ConsumerState<CustodyMovementSheet> createState() =>
      _CustodyMovementSheetState();
}

class _CustodyMovementSheetState extends ConsumerState<CustodyMovementSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _remarkController = TextEditingController();
  String? _account;
  DateTime _date = DateTime.now();

  /// False keeps the request date-less, so the server stamps its own clock.
  bool _timeExplicit = false;
  bool _submitting = false;
  String? _error;

  bool get _isReturn => widget.mode == CustodyMovementMode.returnCash;

  @override
  void initState() {
    super.initState();
    // A return usually empties the custody, so start from the whole balance.
    final prefill = _isReturn && widget.holder.balance > 0
        ? widget.holder.balance.toStringAsFixed(2)
        : '';
    _amountController = TextEditingController(text: prefill);
    if (widget.accounts.length == 1) {
      _account = widget.accounts.single.account;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final l10n = context.l10n;
    final amount = double.tryParse((value ?? '').trim());
    if (amount == null || amount <= 0) return l10n.custodyAmountInvalid;
    if (_isReturn && amount > widget.holder.balance + custodyBalanceEpsilon) {
      return l10n.custodyAmountExceedsBalance(
        formatCurrency(context, widget.holder.balance),
      );
    }
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await pickPostingDateTime(
      context,
      initial: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null && mounted) {
      setState(() {
        _date = picked;
        _timeExplicit = true;
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_timeExplicit) {
      final confirmed = await confirmPostingDatesBeforeSubmit(
        context,
        dates: [_date],
        includeTime: true,
      );
      if (!confirmed || !mounted) return;
    }

    final amount = double.parse(_amountController.text.trim());
    final remark = _remarkController.text.trim();
    final postingDate = widget.allowDate && _timeExplicit
        ? formatPostingDateTimeForApi(_date)
        : null;
    final notifier = ref.read(custodyActionsProvider.notifier);

    setState(() => _submitting = true);
    try {
      final result = _isReturn
          ? await notifier.returnCash(
              holder: widget.holder.name,
              toAccount: _account!,
              amount: amount,
              postingDate: postingDate,
              remark: remark.isEmpty ? null : remark,
            )
          : await notifier.issue(
              holder: widget.holder.name,
              fromAccount: _account!,
              amount: amount,
              postingDate: postingDate,
              remark: remark.isEmpty ? null : remark,
            );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = context.userErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final title = _isReturn ? l10n.custodyReturnTitle : l10n.custodyIssueTitle;
    final accountLabel = _isReturn
        ? l10n.custodyReturnAccount
        : l10n.custodySourceAccount;
    final submitLabel = _isReturn
        ? l10n.custodySubmitReturn
        : l10n.custodySubmitIssue;
    final dateLabel = _timeExplicit
        ? formatPostingDateTimeForDisplay(context, _date)
        : l10n.custodyDateNow;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleLarge),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                '${widget.holder.localizedName(languageCode)} • '
                '${l10n.custodyAvailable(formatCurrency(context, widget.holder.balance))}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (widget.accounts.isEmpty)
                Text(
                  l10n.custodyNoAccounts,
                  style: TextStyle(color: theme.colorScheme.error),
                )
              else
                DropdownButtonFormField<String>(
                  key: const Key('custody-account-field'),
                  initialValue: _account,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: accountLabel,
                    border: const OutlineInputBorder(),
                  ),
                  hint: Text(l10n.custodySelectAccount),
                  items: [
                    for (final option in widget.accounts)
                      DropdownMenuItem<String>(
                        value: option.account,
                        child: Row(
                          children: [
                            Icon(
                              custodyAccountCategoryIcon(option.category),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option.localizedLabel(languageCode),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(formatCurrency(context, option.balance)),
                          ],
                        ),
                      ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _account = value),
                  validator: (value) =>
                      value == null ? l10n.custodyAccountRequired : null,
                ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('custody-amount-field'),
                controller: _amountController,
                enabled: !_submitting,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.custodyAmountLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: _validateAmount,
              ),
              if (widget.allowDate) const SizedBox(height: 16),
              if (widget.allowDate)
                InkWell(
                  onTap: _submitting ? null : _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.custodyDateLabel,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(dateLabel),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarkController,
                enabled: !_submitting,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.custodyRemarkLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  key: const Key('custody-sheet-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('custody-submit'),
                onPressed: _submitting || widget.accounts.isEmpty
                    ? null
                    : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isReturn ? Icons.north_east : Icons.south_west),
                label: Text(submitLabel),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
