import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_models.dart';
import '../chat_bidi.dart';
import '../chat_labels.dart';

/// The amber accent of a chat with open staff notes (strip and inbox badge).
const Color kChatNoteAccent = Color(0xFFE65100);

/// Open notes in [next] that [previous] did not hold, written by someone
/// other than [currentUser]: what a moderator should be told about when it
/// arrives while the thread is open. Empty on the first load ([previous]
/// null), so opening a chat never "announces" its old notes.
List<ChatNote> chatNewOpenNotes(
  List<ChatNote>? previous,
  List<ChatNote> next, {
  String? currentUser,
}) {
  if (previous == null) return const <ChatNote>[];
  final known = {for (final n in previous) n.name};
  return [
    for (final n in next)
      if (n.isOpen &&
          !known.contains(n.name) &&
          (currentUser == null || n.author != currentUser))
        n,
  ];
}

/// The staff-notes strip pinned above the messages. Hidden when there are no
/// notes; collapsed it is one slim row ("Notes (N)", amber while any is open,
/// with the newest open note's first line); tapped it shows the list with a
/// "Handled" toggle per note, delete when allowed, and "Add note".
class ChatNotesStrip extends StatelessWidget {
  const ChatNotesStrip({
    super.key,
    required this.notes,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onAdd,
    required this.onSetHandled,
    required this.onDelete,
    required this.now,
    this.busy = false,
    this.maxListHeight = 240,
  });

  /// Newest first.
  final List<ChatNote> notes;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onAdd;
  final void Function(ChatNote note, bool handled) onSetHandled;
  final void Function(ChatNote note) onDelete;

  /// For the short time labels (time today, date otherwise).
  final DateTime now;

  /// A note write is in flight: the toggles and delete are disabled.
  final bool busy;
  final double maxListHeight;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final open = notes.where((n) => n.isOpen).toList(growable: false);
    final hasOpen = open.isNotEmpty;
    final accent = hasOpen ? kChatNoteAccent : theme.colorScheme.onSurfaceVariant;
    final background = hasOpen
        ? Colors.amber.withValues(alpha: 0.16)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final count = hasOpen ? open.length : notes.length;
    final label = hasOpen
        ? chatBi(
            context,
            'Notes (${formatCount(context, count)})',
            'ملاحظات (${formatCount(context, count)})',
          )
        : chatBi(
            context,
            'Notes (${formatCount(context, count)}) · all handled',
            'ملاحظات (${formatCount(context, count)}) · كلها اتنفذت',
          );
    final preview = hasOpen ? open.first.firstLine : '';

    return Material(
      key: const ValueKey('chat-notes-strip'),
      color: background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const ValueKey('chat-notes-toggle'),
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    hasOpen ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined,
                    size: 18,
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    key: const ValueKey('chat-notes-label'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: accent,
                      fontWeight: hasOpen ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  if (preview.isNotEmpty && !expanded) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        preview,
                        key: const ValueKey('chat-notes-preview'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: chatTextDirection(
                          preview,
                          Directionality.of(context),
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: accent,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxListHeight),
              child: ListView.separated(
                key: const ValueKey('chat-notes-list'),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: notes.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => _NoteRow(
                  note: notes[index],
                  now: now,
                  busy: busy,
                  onSetHandled: onSetHandled,
                  onDelete: onDelete,
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const ValueKey('chat-notes-add'),
                onPressed: busy ? null : onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: Text(chatBi(context, 'Add note', 'إضافة ملاحظة')),
              ),
            ),
          ],
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({
    required this.note,
    required this.now,
    required this.busy,
    required this.onSetHandled,
    required this.onDelete,
  });

  final ChatNote note;
  final DateTime now;
  final bool busy;
  final void Function(ChatNote note, bool handled) onSetHandled;
  final void Function(ChatNote note) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      if (note.authorLabel.isNotEmpty) note.authorLabel,
      chatNoteTimeLabel(context, note.createdTime, now),
    ].where((s) => s.isNotEmpty).join(' · ');
    final handledBy = note.resolvedByLabel;

    return Opacity(
      opacity: note.resolved ? 0.55 : 1,
      child: Padding(
        key: ValueKey('chat-note-${note.name}'),
        padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 4, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tooltip(
              message: chatBi(context, 'Handled', 'اتنفذت'),
              child: Checkbox(
                key: ValueKey('chat-note-handled-${note.name}'),
                value: note.resolved,
                onChanged: busy
                    ? null
                    : (value) => onSetHandled(note, value ?? false),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      note.note,
                      textAlign: TextAlign.start,
                      textDirection: chatTextDirection(
                        note.note,
                        Directionality.of(context),
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        decoration:
                            note.resolved ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (note.resolved)
                      Text(
                        handledBy == null
                            ? chatBi(context, 'Handled', 'اتنفذت')
                            : chatBi(
                                context,
                                'Handled by $handledBy',
                                'نفّذها $handledBy',
                              ),
                        key: ValueKey('chat-note-handled-by-${note.name}'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (note.canDelete)
              IconButton(
                key: ValueKey('chat-note-delete-${note.name}'),
                tooltip: chatBi(context, 'Delete note', 'مسح الملاحظة'),
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: busy ? null : () => onDelete(note),
              ),
          ],
        ),
      ),
    );
  }
}

/// "h:mm a" for today, "MMM d, h:mm a" otherwise; empty when unknown.
String chatNoteTimeLabel(BuildContext context, DateTime? time, DateTime now) {
  if (time == null) return '';
  final sameDay =
      time.year == now.year && time.month == now.month && time.day == now.day;
  return formatDateTime(
    context,
    time,
    pattern: sameDay ? 'h:mm a' : 'MMM d, h:mm a',
  );
}

/// Asks before deleting a note; true when confirmed.
Future<bool> showChatDeleteNoteDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('chat-delete-note-dialog'),
      title: Text(chatBi(dialogContext, 'Delete this note?', 'تمسح الملاحظة دي؟')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(chatBi(dialogContext, 'Cancel', 'إلغاء')),
        ),
        FilledButton(
          key: const ValueKey('chat-delete-note-confirm'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(chatBi(dialogContext, 'Delete', 'مسح')),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// "Add staff note": a multi-line field (max
/// [ChatRepository.chatNoteMaxLength]) and Save. [onSubmit] runs the write;
/// the dialog stays open with the server's reason when it fails, so the text
/// is not lost. True when a note was saved.
Future<bool> showChatAddNoteDialog(
  BuildContext context, {
  required Future<void> Function(String note) onSubmit,
}) async {
  final added = await showDialog<bool>(
    context: context,
    builder: (_) => ChatAddNoteDialog(onSubmit: onSubmit),
  );
  return added ?? false;
}

class ChatAddNoteDialog extends StatefulWidget {
  const ChatAddNoteDialog({super.key, required this.onSubmit});

  final Future<void> Function(String note) onSubmit;

  @override
  State<ChatAddNoteDialog> createState() => _ChatAddNoteDialogState();
}

class _ChatAddNoteDialogState extends State<ChatAddNoteDialog> {
  final _text = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onChanged);
  }

  @override
  void dispose() {
    _text.removeListener(_onChanged);
    _text.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    final note = _text.text.trim();
    if (_busy || note.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(note);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = context.userErrorMessage(
          e,
          fallback: context.l10n.chatActionFailed,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String bi(String en, String ar) => chatBi(context, en, ar);
    return AlertDialog(
      key: const ValueKey('chat-add-note-dialog'),
      title: Text(bi('Add staff note', 'إضافة ملاحظة للفريق')),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              bi(
                'Every moderator on this chat sees it live.',
                'كل اللي شغالين على المحادثة دي هيشوفوها على طول.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('chat-add-note-field'),
              controller: _text,
              autofocus: true,
              enabled: !_busy,
              minLines: 3,
              maxLines: 6,
              maxLength: ChatRepository.chatNoteMaxLength,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              textDirection: chatTextDirection(
                _text.text,
                Directionality.of(context),
              ),
              decoration: InputDecoration(
                hintText: bi(
                  'e.g. Apologise to her, give her free delivery',
                  'مثلاً: اعتذر لها واديها توصيل مجاني',
                ),
                border: const OutlineInputBorder(),
                errorText: _error,
                errorMaxLines: 3,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(bi('Cancel', 'إلغاء')),
        ),
        FilledButton(
          key: const ValueKey('chat-add-note-save'),
          onPressed: _busy || _text.text.trim().isEmpty ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(bi('Save', 'حفظ')),
        ),
      ],
    );
  }
}
