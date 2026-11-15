import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_models.dart';
import '../../state/chat_providers.dart';
import '../chat_labels.dart';
import '../chat_bidi.dart';
import 'chat_media_open.dart';
import 'chat_message_actions.dart';
import 'chat_voice_note_player.dart';

/// The text a long press can copy / select: the caption or body, plus a voice
/// note's transcript. Null for a message with no text (an image alone, a
/// location pin).
String? chatMessageCopyText(ChatMessage message) {
  if (message.messageType == 'location') return null;
  final parts = <String>[
    if (message.body.trim().isNotEmpty) message.body.trim(),
    if (message.messageType == 'audio' && message.transcript != null)
      message.transcript!.trim(),
  ];
  return parts.isEmpty ? null : parts.join('\n\n');
}

/// One message: inbound on the start side, outbound on the end side.
///
/// A long press opens Copy / Select text / Use in reply ([onUseInReply] is
/// the composer hook; without it that action is left out). The text itself is
/// plain, not selectable, so the long press is not taken by a text selection.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onUseInReply,
  });

  final ChatMessage message;
  final ValueChanged<String>? onUseInReply;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final outbound = message.isOutbound;
    final background = outbound
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = outbound
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    final time = message.time;
    final copyText = chatMessageCopyText(message);

    final footer = <String>[
      if (time != null) formatDateTime(context, time, pattern: 'h:mm a'),
      if (outbound && message.sentVia == 'Phone') l10n.chatSentFromPhone,
      if (outbound && message.sentVia == 'System') l10n.chatSentBySystem,
      if (outbound &&
          message.sentVia != 'Phone' &&
          (message.sentByName ?? message.sentBy) != null)
        l10n.chatSentBy((message.sentByName ?? message.sentBy)!),
    ];

    return Align(
      alignment:
          outbound ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onLongPress: copyText == null
              ? null
              : () => showChatMessageActionsSheet(
                  context,
                  text: copyText,
                  onUseInReply: onUseInReply,
                ),
          child: Container(
            key: ValueKey('chat-message-${message.name}'),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadiusDirectional.only(
                topStart: const Radius.circular(14),
                topEnd: const Radius.circular(14),
                bottomStart: Radius.circular(outbound ? 14 : 4),
                bottomEnd: Radius.circular(outbound ? 4 : 14),
              ),
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: foreground),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChatMessageContent(message: message),
                  if (footer.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      footer.join(' · '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: foreground.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  if (message.isFailed)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 14,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              message.error == null
                                  ? l10n.chatMessageFailed
                                  : '${l10n.chatMessageFailed}: ${message.error}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The body of a message by type: text, image, location link, an inline
/// player for voice notes, or an "open" tile for video / documents.
class ChatMessageContent extends StatelessWidget {
  const ChatMessageContent({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = message.messageType;
    final body = message.body.trim();

    Widget? caption() => body.isEmpty ? null : ChatBidiText(body);

    switch (type) {
      case 'image':
      case 'sticker':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ChatMessageImage(message: message),
            if (caption() != null) ...[
              const SizedBox(height: 6),
              caption()!,
            ],
          ],
        );
      case 'audio':
      case 'video':
      case 'document':
        final transcript = type == 'audio' ? message.transcript : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type == 'audio')
              ChatVoiceNotePlayer(message: message)
            else
              ChatMediaOpenTile(message: message),
            if (transcript != null) ...[
              const SizedBox(height: 6),
              ChatVoiceTranscript(text: transcript),
            ],
            if (caption() != null) ...[
              const SizedBox(height: 6),
              caption()!,
            ],
          ],
        );
      case 'location':
        final location = message.location;
        return InkWell(
          onTap: location == null
              ? null
              : () => launchUrl(
                    Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query='
                      '${location.lat},${location.lng}',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.place_outlined, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  location == null ? l10n.chatMessageLocation : l10n.chatOpenInMaps,
                  style: const TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        );
      case 'reaction':
        return Text(body.isEmpty ? l10n.chatMessageReaction : body);
      default:
        if (body.isNotEmpty) return ChatBidiText(body);
        final label = chatMessageTypeLabel(l10n, type);
        return Text(
          label.isEmpty ? l10n.chatMessageUnsupported : label,
          style: const TextStyle(fontStyle: FontStyle.italic),
        );
    }
  }
}

/// A message image, fetched with the session (private files) and shown with
/// `Image.memory`. Only same-site `/files` paths are fetched.
class ChatMessageImage extends ConsumerWidget {
  const ChatMessageImage({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final url = message.mediaUrl;
    if (!ChatRepository.isSessionMediaUrl(url)) {
      return _MediaPlaceholder(
        icon: Icons.image_outlined,
        label: l10n.chatMediaUnavailable,
      );
    }
    final bytes = ref.watch(chatMediaBytesProvider(url!));
    return bytes.when(
      loading: () => const SizedBox(
        width: 180,
        height: 140,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => _MediaPlaceholder(
        icon: Icons.broken_image_outlined,
        label: l10n.chatMediaLoadFailed,
      ),
      data: (data) => GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            insetPadding: const EdgeInsets.all(12),
            child: InteractiveViewer(child: Image.memory(data)),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260, maxWidth: 260),
            child: Image.memory(
              data,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _MediaPlaceholder(
                icon: Icons.broken_image_outlined,
                label: l10n.chatMediaLoadFailed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Video / document as a tile that opens the file (see
/// [openChatMediaAttachment]: the browser on web, the share sheet elsewhere).
class ChatMediaOpenTile extends ConsumerStatefulWidget {
  const ChatMediaOpenTile({super.key, required this.message});

  final ChatMessage message;

  @override
  ConsumerState<ChatMediaOpenTile> createState() => _ChatMediaOpenTileState();
}

class _ChatMediaOpenTileState extends ConsumerState<ChatMediaOpenTile> {
  bool _busy = false;

  Future<void> _open() async {
    if (!ChatRepository.isSessionMediaUrl(widget.message.mediaUrl) || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await openChatMediaAttachment(
        context,
        ref.read(chatRepositoryProvider),
        widget.message,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = widget.message.messageType;
    final available = ChatRepository.isSessionMediaUrl(widget.message.mediaUrl);
    return OutlinedButton.icon(
      onPressed: available && !_busy ? _open : null,
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(chatMessageTypeIcon(type)),
      label: Text(
        available
            ? '${chatMessageTypeLabel(l10n, type)} · ${l10n.chatOpenMedia}'
            : l10n.chatMediaUnavailable,
      ),
    );
  }
}

/// The server's transcript of a voice note, under the player: a small muted
/// label, then the text (selectable), capped at [collapsedLines] lines with
/// tap-to-expand when longer. The text runs in its own direction (an Arabic
/// note reads right-to-left even in the English UI).
class ChatVoiceTranscript extends StatefulWidget {
  const ChatVoiceTranscript({
    super.key,
    required this.text,
    this.collapsedLines = 6,
  });

  final String text;
  final int collapsedLines;

  @override
  State<ChatVoiceTranscript> createState() => _ChatVoiceTranscriptState();
}

class _ChatVoiceTranscriptState extends State<ChatVoiceTranscript> {
  bool _expanded = false;

  String _bi(String en, String ar) =>
      Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = DefaultTextStyle.of(context).style;
    final muted = (base.color ?? theme.colorScheme.onSurface)
        .withValues(alpha: 0.72);
    final textStyle = base.merge(theme.textTheme.bodySmall).copyWith(
          color: muted,
        );
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: muted,
      fontWeight: FontWeight.w600,
    );
    final direction = chatTextDirection(
      widget.text,
      Directionality.of(context),
    );

    return Column(
      key: const ValueKey('chat-voice-transcript'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.subtitles_outlined, size: 14, color: muted),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _bi('Transcript', 'نص الرسالة الصوتية'),
                style: labelStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        LayoutBuilder(
          builder: (context, constraints) {
            final painter = TextPainter(
              text: TextSpan(text: widget.text, style: textStyle),
              textDirection: direction,
              textScaler: MediaQuery.textScalerOf(context),
              maxLines: widget.collapsedLines,
            )..layout(maxWidth: constraints.maxWidth);
            final long = painter.didExceedMaxLines;
            painter.dispose();
            final collapsed = long && !_expanded;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: long ? _toggle : null,
                  child: ChatBidiText(
                    widget.text,
                    style: textStyle,
                    maxLines: collapsed ? widget.collapsedLines : null,
                    overflow: collapsed ? TextOverflow.ellipsis : null,
                  ),
                ),
                if (long)
                  InkWell(
                    key: const ValueKey('chat-voice-transcript-toggle'),
                    onTap: _toggle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _expanded
                            ? _bi('Show less', 'عرض أقل')
                            : _bi('Show more', 'عرض المزيد'),
                        style: labelStyle?.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// The direction of [text] from its first strong character: right-to-left
/// for Arabic / Hebrew script, left-to-right for a Latin-style letter, null
/// when there is none (digits, punctuation, emoji only).
TextDirection? chatTextDirectionOf(String text) {
  for (final rune in text.runes) {
    if ((rune >= 0x0590 && rune <= 0x08FF) ||
        (rune >= 0xFB1D && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF)) {
      return TextDirection.rtl;
    }
    if ((rune >= 0x41 && rune <= 0x5A) ||
        (rune >= 0x61 && rune <= 0x7A) ||
        (rune >= 0x00C0 && rune <= 0x024F)) {
      return TextDirection.ltr;
    }
  }
  return null;
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}
