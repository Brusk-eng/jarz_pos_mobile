import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../../../core/network/frappe_error_message.dart';
import '../../../approvals/state/pending_approvals_provider.dart';
import '../../../tasks/models/task_models.dart';
import '../../../tasks/state/tasks_providers.dart';
import '../../data/credit_repository.dart';
import '../../data/models/settlement_models.dart';
import '../../state/credit_providers.dart';
import '../settlement_labels.dart';

/// Edits one party's settlement schedule — a Customer, or a Lead whose terms
/// carry over to its Customer on conversion.
///
/// Only the inputs of the chosen cycle are shown, and only those travel: see
/// [SettlementTermsDraft.toPayload]. Everything here feeds REMINDERS; none of
/// it can stop an order being placed.
class SettlementTermsSheet extends ConsumerStatefulWidget {
  final SettlementParty party;

  /// Display name for the header; falls back to the party's id.
  final String customerName;

  /// The saved record, or null for a shop with none yet.
  final SettlementTerms? initial;

  const SettlementTermsSheet({
    super.key,
    required this.party,
    this.customerName = '',
    this.initial,
  });

  /// Shows the sheet; returns the server's recomputed terms + status on
  /// save, or null when the user backed out.
  ///
  /// Pass [party], or [customer] as a shorthand for a Customer party.
  static Future<SettlementTermsResponse?> show(
    BuildContext context, {
    SettlementParty? party,
    String? customer,
    String customerName = '',
    SettlementTerms? initial,
  }) {
    assert(
      (party == null) != (customer == null),
      'Pass exactly one of party or customer',
    );
    final target = party ?? SettlementParty.customer(customer ?? '');
    return showModalBottomSheet<SettlementTermsResponse>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SettlementTermsSheet(
          party: target,
          customerName: customerName,
          initial: initial,
        ),
      ),
    );
  }

  @override
  ConsumerState<SettlementTermsSheet> createState() =>
      _SettlementTermsSheetState();
}

class _SettlementTermsSheetState extends ConsumerState<SettlementTermsSheet> {
  late String _cycle;
  late bool _enabled;
  late Set<String> _weekdays;
  late Set<String> _monthDays;
  String? _anchorDate;
  late String _responsibleUser;

  late final TextEditingController _weekIntervalController;
  late final TextEditingController _intervalDaysController;
  late final TextEditingController _remindController;
  late final TextEditingController _overdueRepeatController;
  late final TextEditingController _responsibleController;
  late final TextEditingController _notesController;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final exists = initial != null && initial.exists;
    final cycle = exists ? initial.cycle : '';
    _cycle = SettlementCycle.all.contains(cycle)
        ? cycle
        : SettlementCycle.invoiceAfterInvoice;
    _enabled = exists ? initial.enabled : true;
    _weekdays = exists ? initial.weekdayList.toSet() : <String>{};
    _monthDays = exists ? initial.monthDayList.toSet() : <String>{};
    _anchorDate = exists && initial.anchorDate.isNotEmpty
        ? initial.anchorDate
        : null;
    _responsibleUser = exists ? initial.responsibleUser : '';
    _weekIntervalController = TextEditingController(
      text: '${exists ? initial.weekInterval : 1}',
    );
    _intervalDaysController = TextEditingController(
      text: exists && initial.intervalDays != null
          ? '${initial.intervalDays}'
          : '',
    );
    _remindController = TextEditingController(
      text: '${exists ? initial.effectiveRemindDaysBefore : 1}',
    );
    _overdueRepeatController = TextEditingController(
      text: '${exists ? initial.effectiveOverdueRepeatDays : 2}',
    );
    _responsibleController = TextEditingController(text: _responsibleUser);
    _notesController = TextEditingController(
      text: exists ? initial.notes : '',
    );
  }

  @override
  void dispose() {
    _weekIntervalController.dispose();
    _intervalDaysController.dispose();
    _remindController.dispose();
    _overdueRepeatController.dispose();
    _responsibleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int? _int(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  /// The first problem, as a sentence, or null when the draft can be sent.
  String? _validate() {
    final l10n = context.l10n;
    switch (_cycle) {
      case SettlementCycle.weekly:
        if (_weekdays.isEmpty) return l10n.settlementValidationPickDay;
        final weeks = _int(_weekIntervalController);
        if (weeks == null || weeks < 1) {
          return l10n.settlementValidationWholeNumber;
        }
      case SettlementCycle.daysOfMonth:
        if (_monthDays.isEmpty) return l10n.settlementValidationPickDay;
      case SettlementCycle.everyNDays:
        final days = _int(_intervalDaysController);
        if (days == null || days < 1) {
          return l10n.settlementValidationWholeNumber;
        }
    }
    final remind = _int(_remindController);
    if (remind == null || remind < 0) return l10n.settlementValidationZeroOrMore;
    final repeat = _int(_overdueRepeatController);
    if (repeat == null || repeat < 1) {
      return l10n.settlementValidationWholeNumber;
    }
    return null;
  }

  SettlementTermsDraft _draft() => SettlementTermsDraft(
        customer: widget.party.isLead ? '' : widget.party.name,
        lead: widget.party.isLead ? widget.party.name : '',
        cycle: _cycle,
        enabled: _enabled,
        weekdays: _weekdays.toList(),
        weekInterval: _int(_weekIntervalController) ?? 1,
        monthDays: _monthDays.toList(),
        intervalDays: _int(_intervalDaysController),
        anchorDate: _anchorDate,
        remindDaysBefore: _int(_remindController) ?? 1,
        overdueRepeatDays: _int(_overdueRepeatController) ?? 2,
        responsibleUser: _responsibleUser,
        notes: _notesController.text,
      );

  Future<void> _submit() async {
    final l10n = context.l10n;
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(creditRepositoryProvider)
          .saveSettlementTerms(_draft());
      // The status moved with the schedule, and so may the Collections list
      // and the side-menu "Collections due" count. Both the B2B and the
      // credit account screens read the same party-keyed provider.
      invalidateSettlementTerms(ref, widget.party, saved: result);
      ref.invalidate(pendingApprovalsProvider);
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = context.userErrorMessage(
          extractFrappeErrorMessage(error, fallback: l10n.settlementSaveFailed),
          fallback: l10n.settlementSaveFailed,
        );
      });
    }
  }

  Future<void> _pickAnchorDate() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(_anchorDate ?? '') ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null || !mounted) return;
    setState(() => _anchorDate = isoDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

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
            Text(l10n.settlementSheetTitle, style: theme.textTheme.titleLarge),
            Text(
              widget.customerName.isNotEmpty
                  ? widget.customerName
                  : widget.party.name,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.settlementSheetHint,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            if (widget.party.isLead)
              Text(
                l10n.settlementLeadHint,
                key: const ValueKey('settlement-lead-hint'),
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            const SizedBox(height: 14),
            Text(l10n.settlementCycleLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final cycle in SettlementCycle.all)
                  ChoiceChip(
                    key: ValueKey('settlement-cycle-$cycle'),
                    label: Text(settlementCycleLabel(l10n, cycle)),
                    selected: _cycle == cycle,
                    onSelected: _submitting
                        ? null
                        : (_) => setState(() {
                              _cycle = cycle;
                              _error = null;
                            }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ..._cycleInputs(context),
            const SizedBox(height: 14),
            _numberField(
              controller: _remindController,
              label: l10n.settlementRemindDaysBeforeLabel,
              helper: l10n.settlementRemindDaysBeforeHint,
              fieldKey: const ValueKey('settlement-remind-days'),
            ),
            const SizedBox(height: 12),
            _numberField(
              controller: _overdueRepeatController,
              label: l10n.settlementOverdueRepeatLabel,
              fieldKey: const ValueKey('settlement-overdue-repeat'),
            ),
            const SizedBox(height: 12),
            _ResponsibleUserField(
              value: _responsibleUser,
              controller: _responsibleController,
              enabled: !_submitting,
              onChanged: (value) => setState(() => _responsibleUser = value),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('settlement-notes'),
              controller: _notesController,
              enabled: !_submitting,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.settlementNotesFieldLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              key: const ValueKey('settlement-enabled'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settlementEnabledLabel),
              value: _enabled,
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _enabled = value),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            FilledButton.icon(
              key: const ValueKey('settlement-save'),
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(l10n.settlementSaveAction),
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
      ),
    );
  }

  List<Widget> _cycleInputs(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    Widget hint(String text) => Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        );

    switch (_cycle) {
      case SettlementCycle.weekly:
        final weeks = _int(_weekIntervalController) ?? 1;
        return [
          Text(l10n.settlementWeekdaysLabel, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final day in weekdayTokens)
                FilterChip(
                  key: ValueKey('settlement-weekday-$day'),
                  label: Text(settlementWeekdayName(l10n, day, short: true)),
                  selected: _weekdays.contains(day),
                  onSelected: _submitting
                      ? null
                      : (on) => setState(() {
                            on ? _weekdays.add(day) : _weekdays.remove(day);
                          }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _numberField(
            controller: _weekIntervalController,
            label: l10n.settlementWeekIntervalLabel,
            helper: l10n.settlementWeekIntervalHint,
            fieldKey: const ValueKey('settlement-week-interval'),
            onChanged: (_) => setState(() {}),
          ),
          // A single week needs no starting point; every-other-week does.
          if (weeks > 1) ...[
            const SizedBox(height: 8),
            _anchorRow(context),
          ],
        ];
      case SettlementCycle.daysOfMonth:
        return [
          Text(l10n.settlementMonthDaysLabel, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (var day = 1; day <= 31; day++)
                _monthDayChip('$day', '$day'),
              _monthDayChip(monthDayLast, l10n.settlementMonthDayLastChip),
            ],
          ),
          const SizedBox(height: 4),
          hint(l10n.settlementMonthDaysClampHint),
        ];
      case SettlementCycle.everyNDays:
        return [
          _numberField(
            controller: _intervalDaysController,
            label: l10n.settlementIntervalDaysLabel,
            fieldKey: const ValueKey('settlement-interval-days'),
          ),
          const SizedBox(height: 8),
          _anchorRow(context),
        ];
      case SettlementCycle.invoiceAfterInvoice:
        return [hint(l10n.settlementCycleInvoiceAfterInvoiceHint)];
      case SettlementCycle.onDelivery:
        return [hint(l10n.settlementCycleOnDeliveryHint)];
      default:
        return const [];
    }
  }

  Widget _monthDayChip(String token, String label) {
    return FilterChip(
      key: ValueKey('settlement-monthday-$token'),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      showCheckmark: false,
      selected: _monthDays.contains(token),
      onSelected: _submitting
          ? null
          : (on) => setState(() {
                on ? _monthDays.add(token) : _monthDays.remove(token);
              }),
    );
  }

  Widget _anchorRow(BuildContext context) {
    final l10n = context.l10n;
    final anchor = _anchorDate;
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.settlementAnchorDateLabel,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        OutlinedButton.icon(
          key: const ValueKey('settlement-anchor-date'),
          icon: const Icon(Icons.event, size: 18),
          label: Text(
            anchor == null
                ? l10n.settlementAnchorDateDefault
                : formatDateString(context, anchor),
          ),
          onPressed: _submitting ? null : _pickAnchorDate,
        ),
      ],
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    String? helper,
    Key? fieldKey,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      key: fieldKey,
      controller: controller,
      enabled: !_submitting,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}

/// Who gets the reminder. A dropdown of the task board's users when this
/// user can see them (the same managers and line managers who collect), a
/// plain email field otherwise. Empty means every JARZ Manager.
class _ResponsibleUserField extends ConsumerWidget {
  final String value;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _ResponsibleUserField({
    required this.value,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final users = ref.watch(taskBoardContextProvider).maybeWhen(
          data: (ctx) => ctx.canAccess ? ctx.users : const <TaskUserRef>[],
          orElse: () => const <TaskUserRef>[],
        );

    if (users.isEmpty) {
      return TextField(
        key: const ValueKey('settlement-responsible-user'),
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: l10n.settlementResponsibleUserLabel,
          helperText: l10n.settlementResponsibleUserHint,
          border: const OutlineInputBorder(),
        ),
        onChanged: (text) => onChanged(text.trim()),
      );
    }

    // A saved user who is no longer on the board stays selectable, so
    // opening the sheet never silently changes who is reminded.
    final known = users.any((u) => u.user == value);
    return DropdownButtonFormField<String>(
      key: const ValueKey('settlement-responsible-user'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.settlementResponsibleUserLabel,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(value: '', child: Text(l10n.settlementRemindsAllManagers)),
        if (value.isNotEmpty && !known)
          DropdownMenuItem(value: value, child: Text(value)),
        for (final user in users)
          DropdownMenuItem(
            value: user.user,
            child: Text(user.displayName, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: enabled ? (v) => onChanged(v ?? '') : null,
    );
  }
}
