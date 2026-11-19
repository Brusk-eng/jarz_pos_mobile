import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/widgets/posting_date_confirmation_dialog.dart';
import '../../../cash_custody/models/cash_custody_models.dart'
    show custodyBalanceEpsilon;
import '../../../cash_custody/presentation/custody_labels.dart';
import '../../models/expense_models.dart';
import '../../state/expenses_notifier.dart';

class ExpenseFormSheet extends ConsumerStatefulWidget {
  final bool isManager;
  final List<ExpenseReason> reasons;
  final List<ExpensePaymentSource> paymentSources;

  /// The caller's own custody account, so it reads "My custody" rather than
  /// the holder's name.
  final String? custodyAccount;

  const ExpenseFormSheet({
    super.key,
    required this.isManager,
    required this.reasons,
    required this.paymentSources,
    this.custodyAccount,
  });

  @override
  ConsumerState<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  /// Whether the operator picked a clock time.
  ///
  /// False keeps the legacy date-only request, so an untouched picker still
  /// lets the server stamp the time from its own clock rather than from a
  /// tablet's.
  bool _timeExplicit = false;
  ExpenseReason? _selectedReason;
  ExpensePaymentSource? _selectedSource;
  bool _submitting = false;

  /// Service period the bill covers. Only collected (and only sent) when the
  /// chosen reason has `requiresPeriod`.
  DateTime? _periodFrom;
  DateTime? _periodTo;

  bool get _requiresPeriod => _selectedReason?.requiresPeriod ?? false;

  @override
  void initState() {
    super.initState();
    if (widget.reasons.isNotEmpty) {
      _selectedReason = widget.reasons.first;
    }
    if (widget.paymentSources.isNotEmpty) {
      _selectedSource = widget.paymentSources.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final dateLabel = _timeExplicit
        ? formatDateTime(context, _selectedDate,
            pattern: 'MMMM d, yyyy • h:mm a')
        : formatDate(context, _selectedDate, pattern: 'MMMM d, yyyy');
    final submitLabel = widget.isManager ? l10n.expensesSubmitManager : l10n.expensesSubmitStaff;
    final hasOptions = widget.reasons.isNotEmpty && widget.paymentSources.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.expensesNewExpense,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.expensesAmountLabel,
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  final amount = double.tryParse(trimmed);
                  if (amount == null || amount <= 0) {
                    return l10n.expensesAmountInvalid;
                  }
                  // A custody can never go negative. The server enforces it;
                  // this only saves the round trip and says why.
                  final source = _selectedSource;
                  if (source != null &&
                      source.isCustody &&
                      amount > source.balance + custodyBalanceEpsilon) {
                    return l10n.custodyAmountExceedsBalance(
                      formatCurrency(context, source.balance),
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await pickPostingDateTime(
                    context,
                    initial: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                      _timeExplicit = true;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.expensesDateLabel,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(dateLabel),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ExpenseReason>(
                key: ValueKey<String?>(_selectedReason?.account),
                initialValue: _selectedReason,
                items: widget.reasons
                    .map((reason) => DropdownMenuItem(
                          value: reason,
                      child: Text(reason.localizedLabel(languageCode)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() {
                  _selectedReason = value;
                  // A reason without a period must not carry a stale one.
                  if (!(value?.requiresPeriod ?? false)) {
                    _periodFrom = null;
                    _periodTo = null;
                  }
                }),
                decoration: InputDecoration(
                  labelText: l10n.expensesReasonLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null ? l10n.expensesReasonRequired : null,
              ),
              if (_requiresPeriod) ...[
                const SizedBox(height: 16),
                _buildPeriodField(context),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<ExpensePaymentSource>(
                key: ValueKey<String?>(_selectedSource?.account ?? _selectedSource?.label),
                initialValue: _selectedSource,
                isExpanded: true,
                items: widget.paymentSources
                    .map((source) {
                      if (source.isCustody) {
                        return DropdownMenuItem(
                          value: source,
                          child: _custodyItem(context, source, languageCode),
                        );
                      }
                      final sourceLabel = source.localizedLabel(languageCode);
                      return DropdownMenuItem(
                        value: source,
                        child: Text(
                          '$sourceLabel${_extraLabel(source)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    })
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedSource = value);
                  // Re-check the amount against the newly chosen balance.
                  if (_amountController.text.trim().isNotEmpty) {
                    _formKey.currentState?.validate();
                  }
                },
                decoration: InputDecoration(
                  labelText: l10n.expensesPayFromLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null ? l10n.expensesPaymentSourceRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.expensesRemarksLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: !_submitting && hasOptions ? _handleSubmit : null,
                  child: _submitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(submitLabel),
                ),
              ),
              if (!hasOptions)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.expensesNoOptions,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(expensesNotifierProvider.notifier);
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final reason = _selectedReason!;
    final source = _selectedSource!;
    final isoDate = _timeExplicit
        ? formatPostingDateTimeForApi(_selectedDate)
        : formatPostingDateForApi(_selectedDate);

    final sendPeriod = reason.requiresPeriod && _periodFrom != null && _periodTo != null;

    setState(() => _submitting = true);
    // A custody is paid by account, never through a POS profile: both a
    // holder and a manager send its account with source type "custody".
    // Every other source keeps its original request shape.
    final isCustody = source.isCustody;
    final record = await notifier.createExpense(
      amount: amount,
      reasonAccount: reason.account,
      expenseDate: isoDate,
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      posProfile: isCustody
          ? null
          : (widget.isManager ? source.posProfile : source.posProfile ?? source.label),
      payingAccount: isCustody || widget.isManager ? source.account : null,
      paymentSourceType: isCustody
          ? 'custody'
          : (widget.isManager ? _typeLabel(context, source) : null),
      paymentLabel: source.label,
      periodFrom: sendPeriod ? formatPostingDateForApi(_periodFrom!) : null,
      periodTo: sendPeriod ? formatPostingDateForApi(_periodTo!) : null,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (record != null) {
      Navigator.of(context).pop(record);
    }
  }

  String? _periodErrorText(BuildContext context) {
    final error = validateExpensePeriod(
      requiresPeriod: _requiresPeriod,
      periodFrom: _periodFrom,
      periodTo: _periodTo,
      expenseDate: _selectedDate,
    );
    final l10n = context.l10n;
    switch (error) {
      case null:
        return null;
      case ExpensePeriodError.missing:
        return l10n.expensesPeriodRequired;
      case ExpensePeriodError.fromAfterTo:
        return l10n.expensesPeriodFromAfterTo;
      case ExpensePeriodError.toAfterExpenseDate:
        return l10n.expensesPeriodAfterExpenseDate;
      case ExpensePeriodError.tooLong:
        return l10n.expensesPeriodTooLong;
    }
  }

  Future<void> _pickPeriod(FormFieldState<void> field) async {
    final expenseDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    // A bill is paid after the service, so the period cannot end after the
    // expense date; it may start in an earlier month (the server splits
    // months) but spans at most 366 days inclusive, so the earliest start
    // is 365 days before the expense date.
    final firstDate = DateTime(
      expenseDay.year,
      expenseDay.month,
      expenseDay.day - (maxExpensePeriodDays - 1),
    );
    final current = (_periodFrom != null &&
            _periodTo != null &&
            !_periodFrom!.isBefore(firstDate) &&
            !_periodTo!.isAfter(expenseDay) &&
            !_periodFrom!.isAfter(_periodTo!))
        ? DateTimeRange(start: _periodFrom!, end: _periodTo!)
        : null;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: expenseDay,
      initialDateRange: current,
      currentDate: expenseDay,
      helpText: context.l10n.expensesPeriodLabel,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _periodFrom = DateTime(picked.start.year, picked.start.month, picked.start.day);
      _periodTo = DateTime(picked.end.year, picked.end.month, picked.end.day);
    });
    field.validate();
  }

  Widget _buildPeriodField(BuildContext context) {
    final l10n = context.l10n;
    String show(DateTime? d) =>
        d == null ? '—' : formatDate(context, d, pattern: 'd MMM yyyy');
    return FormField<void>(
      // Keyed on the reason so switching reasons resets the error state.
      key: ValueKey<String?>('period-${_selectedReason?.account}'),
      validator: (_) => _periodErrorText(context),
      builder: (field) => InkWell(
        onTap: () => _pickPeriod(field),
        child: InputDecorator(
          isEmpty: _periodFrom == null && _periodTo == null,
          decoration: InputDecoration(
            labelText: l10n.expensesPeriodLabel,
            hintText: l10n.expensesPeriodSelect,
            helperText: l10n.expensesPeriodHelper,
            helperMaxLines: 2,
            errorText: field.errorText,
            errorMaxLines: 2,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.date_range),
          ),
          child: (_periodFrom == null && _periodTo == null)
              ? null
              : Row(
                  children: [
                    Expanded(
                      child: Text('${l10n.expensesPeriodFrom}: ${show(_periodFrom)}'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${l10n.expensesPeriodTo}: ${show(_periodTo)}'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _custodyItem(
    BuildContext context,
    ExpensePaymentSource source,
    String languageCode,
  ) {
    final l10n = context.l10n;
    final isMine = widget.custodyAccount != null &&
        source.account == widget.custodyAccount;
    final label = isMine
        ? l10n.custodyMine
        : custodyDisplayLabel(l10n, source.localizedLabel(languageCode));
    return Row(
      children: [
        Icon(custodyIcon, size: 18, color: custodyColor(context)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Text(formatCurrency(context, source.balance)),
      ],
    );
  }

  String _extraLabel(ExpensePaymentSource source) {
    if (source.posProfile != null && source.posProfile!.isNotEmpty && source.posProfile != source.label) {
      return ' • ${source.posProfile}';
    }
    return '';
  }

  String _typeLabel(BuildContext context, ExpensePaymentSource source) {
    final l10n = context.l10n;
    switch (source.category) {
      case 'cash':
        return l10n.expenseSourceCash;
      case 'bank':
        return l10n.expenseSourceBank;
      case 'mobile':
        return l10n.expenseSourceMobileWallet;
      case 'pos_profile':
        return l10n.expenseSourcePosProfile;
      default:
        return l10n.expenseSourceAccount;
    }
  }
}
