import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../models/task_models.dart';
import '../task_labels.dart';
import 'task_common_widgets.dart';

/// The board's filter sheet. Returns the new filter, or null when dismissed.
Future<TaskBoardFilter?> showTaskFilterSheet(
  BuildContext context, {
  required TaskBoardFilter filter,
  required TaskBoardContext boardContext,
}) {
  return showModalBottomSheet<TaskBoardFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        _TaskFilterSheet(initial: filter, boardContext: boardContext),
  );
}

class _TaskFilterSheet extends StatefulWidget {
  final TaskBoardFilter initial;
  final TaskBoardContext boardContext;

  const _TaskFilterSheet({required this.initial, required this.boardContext});

  @override
  State<_TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<_TaskFilterSheet> {
  late TaskBoardFilter _filter = widget.initial;

  // Remounting the dropdowns after "clear" is what resets their shown value:
  // DropdownButtonFormField only reads `initialValue` once.
  int _resetKey = 0;

  static const _doneWindows = [7, 30, 90, 0];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ctx = widget.boardContext;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          key: ValueKey(_resetKey),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.tasksFilters, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TaskUserDropdown(
              users: ctx.users,
              value: _filter.assignedTo,
              label: l10n.tasksFilterAssignee,
              allowNone: true,
              noneLabel: l10n.tasksFilterAny,
              onChanged: (v) => setState(
                () => _filter = v == null
                    ? _filter.copyWith(clearAssignedTo: true)
                    : _filter.copyWith(assignedTo: v),
              ),
            ),
            const SizedBox(height: 12),
            TaskUserDropdown(
              users: ctx.users,
              value: _filter.createdBy,
              label: l10n.tasksFilterCreator,
              allowNone: true,
              noneLabel: l10n.tasksFilterAny,
              onChanged: (v) => setState(
                () => _filter = v == null
                    ? _filter.copyWith(clearCreatedBy: true)
                    : _filter.copyWith(createdBy: v),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: ctx.branches.contains(_filter.branch)
                  ? _filter.branch
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.tasksFilterBranch,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.tasksFilterAny),
                ),
                for (final b in ctx.branches)
                  DropdownMenuItem<String?>(value: b, child: Text(b)),
              ],
              onChanged: (v) => setState(
                () => _filter = v == null
                    ? _filter.copyWith(clearBranch: true)
                    : _filter.copyWith(branch: v),
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.tasksFilterPriority),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                ChoiceChip(
                  label: Text(l10n.tasksFilterAny),
                  selected: _filter.priority == null,
                  onSelected: (_) => setState(
                    () => _filter = _filter.copyWith(clearPriority: true),
                  ),
                ),
                for (final p in ctx.priorities)
                  ChoiceChip(
                    label: Text(taskPriorityLabel(l10n, p)),
                    selected: _filter.priority == p,
                    onSelected: (_) =>
                        setState(() => _filter = _filter.copyWith(priority: p)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.tasksFilterOverdueOnly),
              value: _filter.overdueOnly,
              onChanged: (v) =>
                  setState(() => _filter = _filter.copyWith(overdueOnly: v)),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.tasksFilterShowArchived),
              value: _filter.includeArchived,
              onChanged: (v) => setState(
                () => _filter = _filter.copyWith(includeArchived: v),
              ),
            ),
            const SizedBox(height: 4),
            Text(l10n.tasksFilterDoneWindow),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                for (final days in _doneWindows)
                  ChoiceChip(
                    label: Text(
                      days == 0
                          ? l10n.tasksDoneWindowAll
                          : l10n.tasksDoneWindowDays(days),
                    ),
                    selected: _filter.doneDays == days,
                    onSelected: (_) => setState(
                      () => _filter = _filter.copyWith(doneDays: days),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _filter = _filter.cleared();
                    _resetKey++;
                  }),
                  child: Text(l10n.tasksFilterClear),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_filter),
                  child: Text(l10n.tasksFilterApply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
