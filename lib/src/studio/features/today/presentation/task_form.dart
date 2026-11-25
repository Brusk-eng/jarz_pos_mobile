import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/studio_error.dart';
import '../../inbox/presentation/inbox_strings.dart';
import '../../inbox/presentation/ui_helpers.dart';
import '../../settings/data/settings_repository.dart';
import '../state/today_state.dart';
import 'today_strings.dart';
import '../../../shared/studio_error_text.dart';

/// Opens the add / edit form. [task] null adds a new one. Returns true when
/// saved. Only opened from a button the server allows (add for people who may
/// create tasks, edit when the task lists `edit` in `actions`).
Future<bool> showTaskForm(
  BuildContext context, {
  StudioTask? task,
  bool canAssign = true,
}) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => _TaskFormSheet(task: task, canAssign: canAssign),
  );
  return done ?? false;
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class _TaskFormSheet extends ConsumerStatefulWidget {
  const _TaskFormSheet({required this.task, required this.canAssign});
  final StudioTask? task;
  final bool canAssign;

  @override
  ConsumerState<_TaskFormSheet> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<_TaskFormSheet> {
  late final _text = TextEditingController(text: widget.task?.text ?? '');
  late String? _who = widget.task == null
      ? null
      : widget.task!.assignee != null
      ? widget.task!.assignee!.key
      : widget.task!.assigneeTeam != null
      ? 'team:${widget.task!.assigneeTeam!.name}'
      : null;
  late String? _due = widget.task?.due;
  final String _requestId = const Uuid().v4();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _due != null ? DateTime.tryParse(_due!) ?? now : now;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (d != null) setState(() => _due = _ymd(d));
  }

  Future<void> _submit() async {
    final t = TodayStrings.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _error = t.taskTextRequired);
      return;
    }
    setState(() => _busy = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final notifier = ref.read(todayTasksProvider.notifier);
    final team = _who != null && _who!.startsWith('team:')
        ? _who!.substring(5)
        : null;
    final person = _who != null && team == null ? _who : null;
    try {
      final task = widget.task;
      if (task == null) {
        await notifier.create(
          text: text,
          assignee: person,
          assigneeTeam: team,
          due: _due,
          requestId: _requestId,
        );
      } else {
        await notifier.edit(task, {
          'text': text,
          if (widget.canAssign && person != null) 'assignee': person,
          if (widget.canAssign && team != null) 'assignee_team': team,
          'due': _due,
        });
      }
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(task == null ? t.taskAdded : t.taskSaved)),
        );
      nav.pop(true);
    } catch (e) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(studioErrorMessage(e, ar: isAr)),
            duration: const Duration(seconds: 6),
          ),
        );
      if (e is StudioStale || e is StudioAlreadyDone) {
        nav.pop(false);
      } else if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = TodayStrings.of(context);
    final s = InboxStrings.of(context);
    final people = ref.watch(peopleProvider).valueOrNull ?? const [];
    final theme = Theme.of(context);
    final items = <DropdownMenuItem<String?>>[
      DropdownMenuItem(value: null, child: Text(t.me)),
      for (final p in people.where((p) => p.enabled))
        DropdownMenuItem(value: p.key, child: Text(p.fullName)),
      DropdownMenuItem(value: 'team:creators', child: Text(t.creatorsTeam)),
      DropdownMenuItem(value: 'team:claude', child: Text(t.claudeTeam)),
    ];
    final values = items.map((e) => e.value).toSet();
    final current = values.contains(_who) ? _who : null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            StudioSpacing.gutter,
            0,
            StudioSpacing.gutter,
            StudioSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.task == null ? t.addTask : t.editTask,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: StudioSpacing.md),
              TextField(
                key: const ValueKey('task-text'),
                controller: _text,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: t.taskText,
                  errorText: _error,
                ),
              ),
              if (widget.canAssign) ...[
                const SizedBox(height: StudioSpacing.md),
                DropdownButtonFormField<String?>(
                  key: const ValueKey('task-assignee'),
                  initialValue: current,
                  items: items,
                  decoration: InputDecoration(labelText: t.assignTo),
                  onChanged: (v) => setState(() => _who = v),
                ),
              ],
              const SizedBox(height: StudioSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('task-due'),
                      onPressed: _pickDate,
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(
                        _due == null
                            ? t.pickDate
                            : '${t.due}: ${slotText(s, _due)}',
                      ),
                    ),
                  ),
                  if (_due != null)
                    IconButton(
                      key: const ValueKey('task-due-clear'),
                      tooltip: t.clearDate,
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _due = null),
                    ),
                ],
              ),
              const SizedBox(height: StudioSpacing.lg),
              Row(
                children: [
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.pop(context, false),
                    child: Text(s.cancel),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const ValueKey('task-submit'),
                    onPressed: _busy ? null : _submit,
                    child: Text(widget.task == null ? s.add : s.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
