import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../models/task_models.dart';
import '../../state/tasks_providers.dart';
import '../task_labels.dart';
import 'task_common_widgets.dart';

/// Opens the "New task" form. Returns the created task, or null.
Future<TaskBundle?> showTaskCreateSheet(
  BuildContext context,
  TaskBoardContext boardContext,
) {
  return showModalBottomSheet<TaskBundle>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => TaskFormSheet(boardContext: boardContext),
  );
}

/// Opens the edit form for [bundle]. Returns the updated task, or null.
Future<TaskBundle?> showTaskEditSheet(
  BuildContext context, {
  required TaskBoardContext boardContext,
  required TaskBundle bundle,
}) {
  return showModalBottomSheet<TaskBundle>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => TaskFormSheet(boardContext: boardContext, existing: bundle),
  );
}

/// The create / edit form. Create when [existing] is null.
class TaskFormSheet extends ConsumerStatefulWidget {
  final TaskBoardContext boardContext;
  final TaskBundle? existing;

  const TaskFormSheet({super.key, required this.boardContext, this.existing});

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  final _subtaskController = TextEditingController();
  late String? _assignee;
  late String _priority;
  late DateTime? _dueDate;
  late String? _branch;
  final List<NewSubtaskDraft> _subtasks = [];
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final task = widget.existing?.task;
    _title = TextEditingController(text: task?.title ?? '');
    _description = TextEditingController(text: task?.description ?? '');
    _assignee = task?.summary.assignedTo;
    _priority = task?.summary.priority ?? TaskPriority.normal;
    _dueDate = task?.summary.dueDate;
    _branch = task?.summary.branch;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(NewSubtaskDraft(title: text));
      _subtaskController.clear();
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _submitting = true);
    try {
      final TaskBundle result;
      if (_isEdit) {
        result = await _saveEdit();
      } else {
        // A subtask typed but not yet added with the + button still counts.
        _addSubtask();
        result = await ref
            .read(taskCreateProvider.notifier)
            .create(
              title: _title.text,
              assignedTo: _assignee!,
              description: _description.text,
              priority: _priority,
              dueDate: _dueDate,
              branch: _branch,
              subtasks: List.of(_subtasks),
            );
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_isEdit ? l10n.tasksSaved : l10n.tasksCreated)),
      );
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(content: Text(taskErrorMessage(context, e))),
      );
    }
  }

  /// Sends only what changed; a removed due date or branch is a clear flag.
  Future<TaskBundle> _saveEdit() {
    final bundle = widget.existing!;
    final task = bundle.task;
    final notifier = ref.read(taskDetailProvider(task.name).notifier);
    final title = _title.text.trim();
    final description = _description.text;
    final dueChanged = !_sameDay(_dueDate, task.summary.dueDate);
    final branchChanged = _branch != task.summary.branch;
    return notifier.update(
      title: title != task.title ? title : null,
      description: description != task.description ? description : null,
      priority: _priority != task.summary.priority ? _priority : null,
      dueDate: dueChanged ? _dueDate : null,
      clearDueDate: dueChanged && _dueDate == null,
      branch: branchChanged ? _branch : null,
      clearBranch: branchChanged && _branch == null,
      assignedTo: _assignee != null && _assignee != task.summary.assignedTo
          ? _assignee
          : null,
    );
  }

  static bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ctx = widget.boardContext;
    // Watched (not only read) so the auto-disposed create notifier stays
    // alive for the whole request while this sheet is open.
    ref.watch(taskCreateProvider);
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
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEdit ? l10n.tasksEditTitle : l10n.tasksNewTask,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                autofocus: !_isEdit,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.tasksFieldTitle,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? l10n.tasksFieldTitleRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                minLines: 2,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.tasksFieldDescription,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TaskUserDropdown(
                users: ctx.users,
                value: _assignee,
                label: l10n.tasksFieldAssignee,
                onChanged: (v) => setState(() => _assignee = v),
                validator: (v) =>
                    v == null ? l10n.tasksFieldAssigneeRequired : null,
              ),
              const SizedBox(height: 12),
              Text(l10n.tasksFieldPriority),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  for (final p in ctx.priorities)
                    ChoiceChip(
                      label: Text(taskPriorityLabel(l10n, p)),
                      selected: _priority == p,
                      onSelected: (_) => setState(() => _priority = p),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TaskDateField(
                value: _dueDate,
                label: l10n.tasksFieldDueDate,
                onChanged: (d) => setState(() => _dueDate = d),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: ctx.branches.contains(_branch) ? _branch : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.tasksFieldBranch,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.tasksNoBranch),
                  ),
                  for (final b in ctx.branches)
                    DropdownMenuItem<String?>(value: b, child: Text(b)),
                ],
                onChanged: (v) => setState(() => _branch = v),
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.tasksInitialSubtasks,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (var i = 0; i < _subtasks.length; i++)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_box_outline_blank),
                    title: Text(_subtasks[i].title),
                    trailing: IconButton(
                      tooltip: l10n.tasksDeleteSubtask,
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _subtasks.removeAt(i)),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskController,
                        onSubmitted: (_) => _addSubtask(),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: l10n.tasksAddSubtaskField,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.tasksAddSubtask,
                      icon: const Icon(Icons.add),
                      onPressed: _addSubtask,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isEdit ? Icons.save : Icons.add_task),
                label: Text(_isEdit ? l10n.commonSave : l10n.tasksCreateButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
