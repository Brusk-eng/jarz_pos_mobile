import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../models/task_models.dart';
import '../../state/tasks_providers.dart';
import '../task_labels.dart';
import 'task_attachments.dart';
import 'task_common_widgets.dart';

/// Opens the composer for a Log ("What I did") or a Comment.
Future<void> showTaskEntryComposer(
  BuildContext context, {
  required String taskName,
  required String kind,
  required List<TaskUserRef> mentionable,
  required bool canUpload,
  String? me,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TaskEntryComposer(
      taskName: taskName,
      kind: kind,
      mentionable: mentionable,
      canUpload: canUpload,
      me: me,
    ),
  );
}

class _TaskEntryComposer extends ConsumerStatefulWidget {
  final String taskName;
  final String kind;
  final List<TaskUserRef> mentionable;
  final bool canUpload;
  final String? me;

  const _TaskEntryComposer({
    required this.taskName,
    required this.kind,
    required this.mentionable,
    required this.canUpload,
    this.me,
  });

  @override
  ConsumerState<_TaskEntryComposer> createState() => _TaskEntryComposerState();
}

class _TaskEntryComposerState extends ConsumerState<_TaskEntryComposer> {
  final _controller = TextEditingController();
  final List<TaskUserRef> _mentions = [];
  final List<TaskPickedFile> _files = [];
  bool _submitting = false;
  bool _showEmptyError = false;

  bool get _isComment => widget.kind == TaskEntryKind.comment;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickMention() async {
    final l10n = context.l10n;
    final available = widget.mentionable
        .where((u) => !_mentions.any((m) => m.user == u.user))
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.tasksNoMentionable)));
      return;
    }
    final picked = await showDialog<TaskUserRef>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.tasksMentionPick),
        children: [
          for (final u in available)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(u),
              child: Row(
                children: [
                  TaskAvatar(name: u.displayName),
                  const SizedBox(width: 10),
                  Expanded(child: Text(u.displayName)),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _mentions.add(picked);
      final text = _controller.text;
      final spacer = text.isEmpty || text.endsWith(' ') ? '' : ' ';
      _controller.text = '$text$spacer@${picked.displayName} ';
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
  }

  Future<void> _attach() async {
    final files = await pickTaskFiles(context);
    if (files.isEmpty || !mounted) return;
    setState(() => _files.addAll(files));
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      setState(() => _showEmptyError = true);
      return;
    }
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(taskDetailProvider(widget.taskName).notifier);
    final entriesBefore =
        ref.read(taskDetailProvider(widget.taskName)).bundle?.entries.length ??
        0;
    setState(() => _submitting = true);
    // A mention whose name was deleted from the text is not sent.
    final mentions = _mentions
        .where((m) => content.contains('@${m.displayName}'))
        .map((m) => m.user)
        .toList();
    try {
      await notifier.addEntry(
        kind: widget.kind,
        content: content,
        mentions: mentions,
        files: List.of(_files),
        me: widget.me,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final entriesAfter =
          ref.read(taskDetailProvider(widget.taskName)).bundle?.entries.length ??
          0;
      if (entriesAfter > entriesBefore) {
        // The entry was saved and only a file failed: closing is right, and
        // re-posting would duplicate the text.
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.tasksAttachmentsPartial)),
        );
        Navigator.of(context).pop();
        return;
      }
      setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(content: Text(taskErrorMessage(context, e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
              _isComment ? l10n.tasksAddComment : l10n.tasksAddLog,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 3,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_showEmptyError) setState(() => _showEmptyError = false);
              },
              decoration: InputDecoration(
                hintText: _isComment ? l10n.tasksCommentHint : l10n.tasksLogHint,
                border: const OutlineInputBorder(),
                errorText: _showEmptyError ? l10n.tasksContentRequired : null,
              ),
            ),
            if (_mentions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final m in _mentions)
                    InputChip(
                      avatar: const Icon(Icons.alternate_email, size: 16),
                      label: Text(m.displayName),
                      onDeleted: () => setState(() => _mentions.remove(m)),
                    ),
                ],
              ),
            ],
            if (_files.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final f in _files)
                    InputChip(
                      avatar: const Icon(Icons.attach_file, size: 16),
                      label: Text(f.filename, overflow: TextOverflow.ellipsis),
                      onDeleted: () => setState(() => _files.remove(f)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (_isComment)
                  TextButton.icon(
                    onPressed: _submitting ? null : _pickMention,
                    icon: const Icon(Icons.alternate_email),
                    label: Text(l10n.tasksMention),
                  ),
                if (widget.canUpload)
                  TextButton.icon(
                    onPressed: _submitting ? null : _attach,
                    icon: const Icon(Icons.attach_file),
                    label: Text(l10n.tasksAddAttachment),
                  ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(l10n.tasksSend),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
