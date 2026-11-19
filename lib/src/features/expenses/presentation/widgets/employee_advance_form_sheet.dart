import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/widgets/posting_date_confirmation_dialog.dart';
import '../../models/employee_advance_models.dart';
import '../../models/expense_models.dart';
import '../../state/employee_advances_notifier.dart';

/// Sibling of `ExpenseFormSheet`: same `GlobalKey<FormState>` + controllers +
/// `_handleSubmit` → notifier → `Navigator.pop(record)` shape, so both sheets
/// behave identically from the screen's point of view.
///
/// The one deliberate difference is the employee field. A branch can carry
/// dozens of employees, and a bare `DropdownButtonFormField` of that length is
/// unusable on a phone — so the employee is a `FormField` that opens a
/// searchable sheet instead.
class EmployeeAdvanceFormSheet extends ConsumerStatefulWidget {
  final List<AdvanceEmployeeOption> employees;
  final List<ExpensePaymentSource> paymentSources;
  final String? currency;

  /// Salary months the advance may be drawn against, newest first. Empty from
  /// a backend that predates the field, in which case the picker is hidden and
  /// the server applies its pay-day default.
  final List<ExpenseMonthOption> salaryMonths;
  final String? suggestedSalaryMonth;

  const EmployeeAdvanceFormSheet({
    super.key,
    required this.employees,
    required this.paymentSources,
    this.currency,
    this.salaryMonths = const [],
    this.suggestedSalaryMonth,
  });

  @override
  ConsumerState<EmployeeAdvanceFormSheet> createState() =>
      _EmployeeAdvanceFormSheetState();
}

class _EmployeeAdvanceFormSheetState
    extends ConsumerState<EmployeeAdvanceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();

  AdvanceEmployeeOption? _selectedEmployee;
  ExpensePaymentSource? _selectedSource;

  /// Null means "let the backend use today" — `posting_date` is optional in the
  /// contract, so an untouched picker must not force a date onto the request.
  ///
  /// Non-null always carries the clock time the operator picked: the picker
  /// asks for a day and a time, and returns nothing if either is cancelled.
  DateTime? _selectedDate;

  /// Which salary the advance comes off. Deliberately starts EMPTY and is
  /// required: the cash always leaves today's drawer, but before pay day it is
  /// usually LAST month's salary paid early, and a silent default is exactly
  /// how an advance ends up deducted from the wrong payslip.
  String? _selectedSalaryMonth;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.employees.length == 1) {
      _selectedEmployee = widget.employees.first;
    }
    if (widget.paymentSources.isNotEmpty) {
      _selectedSource = widget.paymentSources.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final hasOptions =
        widget.employees.isNotEmpty && widget.paymentSources.isNotEmpty;
    final dateLabel = _selectedDate == null
        ? l10n.expensesAdvanceDateNotSet
        : formatDateTime(context, _selectedDate!,
            pattern: 'MMMM d, yyyy • h:mm a');

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.expensesAdvanceFormTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FormField<AdvanceEmployeeOption>(
                initialValue: _selectedEmployee,
                validator: (value) =>
                    value == null ? l10n.expensesAdvanceEmployeeRequired : null,
                builder: (field) {
                  final selected = _selectedEmployee;
                  return InkWell(
                    onTap: widget.employees.isEmpty
                        ? null
                        : () async {
                            final picked =
                                await _pickEmployee(context, widget.employees);
                            if (picked == null) return;
                            setState(() => _selectedEmployee = picked);
                            field.didChange(picked);
                          },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.expensesAdvanceEmployeeLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.badge_outlined),
                        suffixIcon: const Icon(Icons.search),
                        errorText: field.errorText,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selected?.employeeName ??
                                l10n.expensesAdvanceEmployeeHint,
                            style: selected == null
                                ? Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey.shade600)
                                : Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (selected != null && selected.subtitle.isNotEmpty)
                            Text(
                              selected.subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.expensesAdvanceAmountLabel,
                  border: const OutlineInputBorder(),
                  prefixText:
                      '${currencySymbol(context, currencyCode: widget.currency)} ',
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return l10n.expensesAdvanceAmountInvalid;
                  }
                  return null;
                },
              ),
              if (widget.salaryMonths.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSalaryMonthField(context),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _purposeController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.expensesAdvancePurposeLabel,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return l10n.expensesAdvancePurposeRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ExpensePaymentSource>(
                key: ValueKey<String?>(
                    _selectedSource?.account ?? _selectedSource?.label),
                initialValue: _selectedSource,
                isExpanded: true,
                items: widget.paymentSources
                    .map((source) => DropdownMenuItem(
                          value: source,
                          child: Text(
                            '${source.localizedLabel(languageCode)}${_extraLabel(source)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedSource = value),
                decoration: InputDecoration(
                  labelText: l10n.expensesAdvancePayFromLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null
                    ? l10n.expensesAdvancePaymentSourceRequired
                    : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await pickPostingDateTime(
                    context,
                    initial: _selectedDate ?? now,
                    firstDate: now.subtract(const Duration(days: 365)),
                    // Today is the ceiling, where the other expense pickers
                    // still allow +30 days. An advance is not a plan: approving
                    // one posts a Payment Entry dated from this value, moving
                    // real cash on a cash account, and the backend now refuses
                    // a future advance outright. Offering a day it will reject
                    // would just be an error message with extra steps.
                    lastDate: now,
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.expensesAdvanceDateLabel,
                    border: const OutlineInputBorder(),
                    suffixIcon: _selectedDate == null
                        ? const Icon(Icons.calendar_today)
                        : IconButton(
                            tooltip: l10n.expensesAdvanceDateClear,
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _selectedDate = null),
                          ),
                  ),
                  child: Text(dateLabel),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: !_submitting && hasOptions ? _handleSubmit : null,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.expensesAdvanceSubmit),
                ),
              ),
              if (!hasOptions)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.expensesAdvanceNoOptions,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final employee = _selectedEmployee;
    final source = _selectedSource;
    if (employee == null || source == null) return;

    final notifier = ref.read(employeeAdvancesNotifierProvider.notifier);
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final postingDate = _selectedDate == null
        ? null
        : formatPostingDateTimeForApi(_selectedDate!);

    setState(() => _submitting = true);
    final advance = await notifier.createRequest(
      employee: employee.employee,
      amount: amount,
      purpose: _purposeController.text.trim(),
      payingAccount: source.account,
      posProfile: source.posProfile,
      postingDate: postingDate,
      salaryMonth: _selectedSalaryMonth,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (advance != null) {
      Navigator.of(context).pop(advance);
    }
  }

  Widget _buildSalaryMonthField(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return FormField<String>(
      initialValue: _selectedSalaryMonth,
      validator: (value) => (value == null || value.isEmpty)
          ? l10n.expensesAdvanceSalaryMonthRequired
          : null,
      builder: (field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.expensesAdvanceSalaryMonthLabel,
            helperText: l10n.expensesAdvanceSalaryMonthHelp,
            helperMaxLines: 3,
            errorText: field.errorText,
            errorMaxLines: 2,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.event_note_outlined),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.salaryMonths.map((option) {
              final date = salaryMonthDate(option.id);
              final label = date == null
                  ? option.label
                  : formatDate(context, date, pattern: 'MMMM yyyy');
              final suggested = option.id == widget.suggestedSalaryMonth;
              return ChoiceChip(
                label: Text(
                  suggested
                      ? '$label • ${l10n.expensesAdvanceSalaryMonthSuggested}'
                      : label,
                ),
                selected: _selectedSalaryMonth == option.id,
                labelStyle: suggested && _selectedSalaryMonth != option.id
                    ? TextStyle(color: theme.colorScheme.primary)
                    : null,
                onSelected: (_) {
                  setState(() => _selectedSalaryMonth = option.id);
                  field.didChange(option.id);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _extraLabel(ExpensePaymentSource source) {
    final profile = source.posProfile;
    if (profile != null && profile.isNotEmpty && profile != source.label) {
      return ' • $profile';
    }
    return '';
  }

  Future<AdvanceEmployeeOption?> _pickEmployee(
    BuildContext context,
    List<AdvanceEmployeeOption> employees,
  ) {
    return showModalBottomSheet<AdvanceEmployeeOption>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _EmployeePickerSheet(employees: employees),
    );
  }
}

/// Searchable employee list. Filtering is done on
/// [AdvanceEmployeeOption.matches] so the picker cannot narrow the fields the
/// model says are searchable.
class _EmployeePickerSheet extends StatefulWidget {
  final List<AdvanceEmployeeOption> employees;

  const _EmployeePickerSheet({required this.employees});

  @override
  State<_EmployeePickerSheet> createState() => _EmployeePickerSheetState();
}

class _EmployeePickerSheetState extends State<_EmployeePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final matches =
        widget.employees.where((e) => e.matches(_query)).toList(growable: false);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (ctx, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.expensesAdvanceEmployeePickerTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.expensesAdvanceEmployeeSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: matches.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.expensesAdvanceEmployeeNoMatches,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.paddingOf(ctx).bottom,
                        ),
                        itemCount: matches.length,
                        itemBuilder: (listContext, index) {
                          final option = matches[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(_initials(option.employeeName)),
                            ),
                            title: Text(option.employeeName),
                            subtitle: option.subtitle.isEmpty
                                ? null
                                : Text(option.subtitle),
                            onTap: () => Navigator.of(ctx).pop(option),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }
}
