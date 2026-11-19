import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../models/task_models.dart';
import '../../state/tasks_providers.dart';
import '../task_labels.dart';
import 'task_common_widgets.dart';

/// Add a subtask (when [existing] is null) or edit one.
///
/// Who may be picked follows `can_assign_subtask_to_others`: a manager (or the
/// card's creator) picks any board user; the card's assignee may only give a
/// subtask to themselves or leave it unassigned.
Future<void> showTaskSubtaskSheet(
  BuildContext context, {
  required String taskName,
  required List<TaskUserRef> users,
  required bool canAssignToOthers,
  TaskUserRef? me,
  TaskSubtask? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SubtaskSheet(
      taskName: taskName,
      users: users,
      canAssignToOthers: canAssignToOthers,
      me: me,
      existing: existing,
    ),
  );
}

/// The people a subtask may be given to, per the permission.
@visibleForTesting
List<TaskUserRef> subtaskAssigneeOptions({
  required List<TaskUserRef> users,
  required bool canAssignToOthers,
  TaskUserRef? me,
  String? currentAssignee,
}) {
  if (canAssignToOthers) return users;
  final options = <TaskUserRef>[?me];
  // Keep a subtask's existing assignee selectable so editing its title does
  // not silently reassign it.
  if (currentAssignee != null && currentAssignee != me?.user) {
    for (final u in users) {
      if (u.user == currentAssignee) options.add(u);
    }
  }
  return options;
}

class _SubtaskSheet extends ConsumerStatefulWidget {
  final String taskName;
  final List<TaskUserRef> users;
  final bool canAssignToOthers;
  final TaskUserRef? me;
  final TaskSubtask? existing;

  const _SubtaskSheet({
    required this.taskName,
    required this.users,
    required this.canAssignToOthers,
    this.me,
    this.existing,
  });

  @override
  ConsumerState<_SubtaskSheet> createState() => _SubtaskSheetState();
}

class _SubtaskSheetState extends ConsumerState<_SubtaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late String? _assignee = widget.existing?.assignedTo;
  late DateTime? _dueDate = widget.existing?.dueDate;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(taskDetailProvider(widget.taskName).notifier);
    setState(() => _submitting = true);
    try {
      final existing = widget.existing;
      if (existing == null) {
        await notifier.addSubtask(
          title: _title.text,
          assignedTo: _assignee,
          dueDate: _dueDate,
        );
      } else {
        final title = _title.text.trim();
        final assigneeChanged = _assignee != existing.assignedTo;
        final dueChanged = _dueDate != existing.dueDate;
        await notifier.updateSubtask(
          existing.id,
          title: title != existing.title ? title : null,
          assignedTo: assigneeChanged ? _assignee : null,
          clearAssignee: assigneeChanged && _assignee == null,
          dueDate: dueChanged ? _dueDate : null,
          clearDueDate: dueChanged && _dueDate == null,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(content: Text(taskErrorMessage(context, e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = subtaskAssigneeOptions(
      users: widget.users,
      canAssignToOthers: widget.canAssignToOthers,
      me: widget.me,
      currentAssignee: widget.existing?.assignedTo,
    );
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            20 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null
                    ? l10n.tasksAddSubtask
                    : l10n.tasksEditSubtask,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                autofocus: widget.existing == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.tasksSubtaskTitle,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? l10n.tasksFieldTitleRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TaskUserDropdown(
                users: options,
                value: _assignee,
                label: l10n.tasksSubtaskAssignee,
                allowNone: true,
                noneLabel: l10n.tasksUnassigned,
                onChanged: (v) => setState(() => _assignee = v),
              ),
              const SizedBox(height: 12),
              TaskDateField(
                value: _dueDate,
                label: l10n.tasksFieldDueDate,
                onChanged: (d) => setState(() => _dueDate = d),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.commonSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
