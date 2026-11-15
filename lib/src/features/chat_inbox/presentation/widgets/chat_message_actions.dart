import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../chat_bidi.dart';
import '../chat_labels.dart';

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

/// The long-press sheet of a bubble: Copy, Select text, Use in reply.
Future<void> showChatMessageActionsSheet(
  BuildContext context, {
  required String text,
  ValueChanged<String>? onUseInReply,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        key: const ValueKey('chat-message-actions'),
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const ValueKey('chat-action-copy'),
            leading: const Icon(Icons.copy_outlined),
            title: Text(chatBi(sheetContext, 'Copy', 'نسخ')),
            onTap: () {
              Navigator.of(sheetContext).pop();
              copyChatText(context, text, messenger: messenger);
            },
          ),
          ListTile(
            key: const ValueKey('chat-action-select'),
            leading: const Icon(Icons.select_all),
            title: Text(chatBi(sheetContext, 'Select text', 'تحديد النص')),
            onTap: () {
              Navigator.of(sheetContext).pop();
              showChatSelectTextSheet(context, text);
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
                onUseInReply(text);
              },
            ),
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
