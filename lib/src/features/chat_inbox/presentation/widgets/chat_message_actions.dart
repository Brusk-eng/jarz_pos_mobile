import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/chat_models.dart';
import '../chat_bidi.dart';
import '../chat_labels.dart';
import '../chat_linkify.dart';

/// Copies [text] and says so. The snackbar is raised on [messenger] so it
/// survives the sheet that triggered it closing.
Future<void> copyChatText(
  BuildContext context,
  String text, {
  ScaffoldMessengerState? messenger,
}) async {
  final target = messenger ?? ScaffoldMessenger.maybeOf(context);
  final label = chatBi(context, 'Copied', 'اتنسخ');
  await Clipboard.setData(ClipboardData(text: text));
  target
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: const ValueKey('chat-copied-snack'),
        content: Text(label),
        duration: const Duration(seconds: 2),
      ),
    );
}

/// Whether staff can react to [message]: it is an inbound message the server
/// knows (has a name) and the channel offers reaction emojis.
bool chatCanReact(ChatMessage message, List<String> reactionChoices) =>
    message.isInbound && message.name.isNotEmpty && reactionChoices.isNotEmpty;

/// «تصحيح: » / "Correction: " (by the script of [oldText]) followed by the
/// old text: what "Send correction" puts in the composer.
String chatCorrectionText(String oldText) {
  final rtl = chatTextDirection(oldText, TextDirection.ltr) == TextDirection.rtl;
  return '${rtl ? 'تصحيح: ' : 'Correction: '}${oldText.trim()}';
}

/// The one-line hint shown with "Send correction".
String chatCorrectionHint(BuildContext context) => chatBi(
      context,
      "Meta doesn't allow deleting or editing a sent private message "
          '— send a correction',
      'ميتا مش بتسمح بمسح أو تعديل رسالة اتبعتت في الخاص — ابعت تصحيح',
    );

/// Edit dialog: returns the new text, or null when cancelled / unchanged.
Future<String?> showChatEditDialog(BuildContext context, String current) {
  final controller = TextEditingController(text: current);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(chatBi(dialogContext, 'Edit message', 'تعديل الرسالة')),
      content: TextField(
        key: const ValueKey('chat-edit-field'),
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 8,
        keyboardType: TextInputType.multiline,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(chatBi(dialogContext, 'Cancel', 'إلغاء')),
        ),
        FilledButton(
          key: const ValueKey('chat-edit-save'),
          onPressed: () {
            final text = controller.text.trim();
            Navigator.of(dialogContext)
                .pop(text.isEmpty || text == current.trim() ? null : text);
          },
          child: Text(chatBi(dialogContext, 'Save', 'حفظ')),
        ),
      ],
    ),
  );
}

/// Destructive confirm for "Delete for everyone".
Future<bool> showChatDeleteConfirm(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(
          chatBi(dialogContext, 'Delete for everyone?', 'مسح عند الكل؟'),
        ),
        content: Text(chatBi(
          dialogContext,
          'The customer will no longer see this message.',
          'العميل مش هيشوف الرسالة دي تاني.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(chatBi(dialogContext, 'Cancel', 'إلغاء')),
          ),
          FilledButton(
            key: const ValueKey('chat-delete-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(chatBi(dialogContext, 'Delete', 'مسح')),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}

/// The long-press sheet of a bubble: the reaction row (inbound messages, when
/// the channel has [reactionChoices]), Copy, Select text, Use in reply, and
/// Open link when the message contains a URL (one row per link, max 5).
/// [text] is null for a message with nothing to copy (a photo alone); the
/// text rows are then left out. [onReact] gets the chosen emoji, or an empty
/// string when the current [currentReaction] was tapped again.
Future<void> showChatMessageActionsSheet(
  BuildContext context, {
  required String? text,
  ValueChanged<String>? onUseInReply,
  List<String> reactionChoices = const <String>[],
  String? currentReaction,
  ValueChanged<String>? onReact,
  bool canEdit = false,
  bool canDelete = false,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
  ValueChanged<String>? onCorrection,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final copyText = text;
  final urls = copyText == null
      ? const <ChatLinkMatch>[]
      : findChatLinks(copyText)
          .where((l) => l.kind == ChatLinkKind.url)
          .take(5)
          .toList();
  final showReactions = onReact != null && reactionChoices.isNotEmpty;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        key: const ValueKey('chat-message-actions'),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showReactions)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  key: const ValueKey('chat-reaction-row'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final emoji in reactionChoices)
                      _ReactionChip(
                        emoji: emoji,
                        selected: emoji == currentReaction,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          onReact(emoji == currentReaction ? '' : emoji);
                        },
                      ),
                  ],
                ),
              ),
            ),
          if (canEdit && onEdit != null)
            ListTile(
              key: const ValueKey('chat-action-edit'),
              leading: const Icon(Icons.edit_outlined),
              title: Text(chatBi(sheetContext, 'Edit', 'تعديل')),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onEdit();
              },
            ),
          if (canDelete && onDelete != null)
            ListTile(
              key: const ValueKey('chat-action-delete'),
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(sheetContext).colorScheme.error,
              ),
              title: Text(
                chatBi(sheetContext, 'Delete for everyone', 'امسح عند الكل'),
                style: TextStyle(
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onDelete();
              },
            ),
          if (!canEdit &&
              !canDelete &&
              onCorrection != null &&
              copyText != null)
            ListTile(
              key: const ValueKey('chat-action-correction'),
              leading: const Icon(Icons.edit_note),
              title: Text(chatBi(sheetContext, 'Send correction', 'ابعت تصحيح')),
              subtitle: Text(chatCorrectionHint(sheetContext)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onCorrection(chatCorrectionText(copyText));
                messenger
                  ?..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    key: const ValueKey('chat-correction-snack'),
                    content: Text(chatCorrectionHint(context)),
                  ));
              },
            ),
          for (var i = 0; i < urls.length; i++)
            ListTile(
              key: ValueKey('chat-action-open-link-$i'),
              leading: const Icon(Icons.open_in_new),
              title: Text(
                chatBi(sheetContext, 'Open link', 'فتح اللينك'),
              ),
              subtitle: urls.length == 1
                  ? null
                  : Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        urls[i].text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                openChatLink(context, urls[i]);
              },
            ),
          if (copyText != null) ...[
          ListTile(
            key: const ValueKey('chat-action-copy'),
            leading: const Icon(Icons.copy_outlined),
            title: Text(chatBi(sheetContext, 'Copy', 'نسخ')),
            onTap: () {
              Navigator.of(sheetContext).pop();
              copyChatText(context, copyText, messenger: messenger);
            },
          ),
          ListTile(
            key: const ValueKey('chat-action-select'),
            leading: const Icon(Icons.select_all),
            title: Text(chatBi(sheetContext, 'Select text', 'تحديد النص')),
            onTap: () {
              Navigator.of(sheetContext).pop();
              showChatSelectTextSheet(context, copyText);
            },
          ),
          if (onUseInReply != null)
            ListTile(
              key: const ValueKey('chat-action-reply'),
              leading: const Icon(Icons.reply_outlined),
              title: Text(
                chatBi(sheetContext, 'Use in reply', 'استخدمه في الرد'),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onUseInReply(copyText);
              },
            ),
          ],
        ],
      ),
    ),
  );
}

/// The whole message in a large sheet where part of it is easy to select
/// (long-press a word, drag the handles), with a Copy-all button.
Future<void> showChatSelectTextSheet(BuildContext context, String text) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.85,
        child: Column(
          key: const ValueKey('chat-select-text'),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      chatBi(sheetContext, 'Select text', 'تحديد النص'),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    key: const ValueKey('chat-select-copy-all'),
                    onPressed: () =>
                        copyChatText(context, text, messenger: messenger),
                    icon: const Icon(Icons.copy_outlined),
                    label: Text(chatBi(sheetContext, 'Copy all', 'نسخ الكل')),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SelectionArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ChatBidiText(
                      text,
                      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          key: ValueKey('chat-reaction-$emoji'),
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: selected
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.primary, width: 2),
                  )
                : null,
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
        ),
      ),
    );
  }
}
