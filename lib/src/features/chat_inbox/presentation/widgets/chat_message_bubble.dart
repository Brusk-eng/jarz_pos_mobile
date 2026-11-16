import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_models.dart';
import '../../state/chat_providers.dart';
import '../../state/chat_voice_note_playback.dart';
import '../chat_labels.dart';
import '../chat_bidi.dart';
import 'chat_image_gallery.dart';
import 'chat_media_open.dart';
import 'chat_message_actions.dart';
import 'chat_video_player.dart';
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

/// WhatsApp-style delivery tick for one of OUR messages, or null when there
/// is nothing to show (failed has its own UI; unknown / empty status).
Widget? chatReceiptTick(
  BuildContext context,
  ChatMessage message,
  Color foreground,
) {
  if (!message.isOutbound) return null;
  final IconData icon;
  final String label;
  Color color = foreground.withValues(alpha: 0.7);
  switch (message.status) {
    case 'queued':
      icon = Icons.schedule;
      label = chatBi(context, 'Sending', 'بتتبعت');
    case 'sent':
      icon = Icons.done;
      label = chatBi(context, 'Sent', 'اتبعتت');
    case 'delivered':
      icon = Icons.done_all;
      label = chatBi(context, 'Delivered', 'وصلت');
    case 'read':
      icon = Icons.done_all;
      label = chatBi(context, 'Read', 'اتقرت');
      color = Theme.of(context).brightness == Brightness.dark
          ? Colors.lightBlueAccent
          : const Color(0xFF1976D2);
    default:
      return null;
  }
  return Tooltip(
    message: label,
    child: Semantics(
      label: label,
      child: Icon(
        icon,
        key: ValueKey('chat-receipt-${message.status}'),
        size: 15,
        color: color,
      ),
    ),
  );
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
    this.reactionChoices = const <String>[],
    this.onReact,
    this.galleryMessages = const <ChatMessage>[],
    this.showReceipts = true,
    this.onEditMessage,
    this.onDeleteMessage,
    this.onCorrection,
  });

  final ChatMessage message;

  /// Our message edited / deleted for everyone (shown when the server's
  /// `can_edit` / `can_delete` allow it).
  final ValueChanged<String>? onEditMessage;
  final VoidCallback? onDeleteMessage;

  /// "Send correction": gets the prefixed old text for the composer. Only
  /// given on WhatsApp / Messenger / Instagram DMs.
  final ValueChanged<String>? onCorrection;

  /// Delivery ticks on our messages. Off for comment channels (no receipts).
  final bool showReceipts;
  final ValueChanged<String>? onUseInReply;

  /// The emojis staff may react with (empty = none) and the callback with the
  /// chosen emoji (empty string = remove). Only inbound messages offer them.
  final List<String> reactionChoices;
  final ValueChanged<String>? onReact;

  /// Every photo of the thread, oldest first, for the full-screen viewer.
  final List<ChatMessage> galleryMessages;

  Future<void> _edit(BuildContext context) async {
    final text = await showChatEditDialog(context, message.body);
    if (text != null) onEditMessage?.call(text);
  }

  Future<void> _delete(BuildContext context) async {
    if (await showChatDeleteConfirm(context)) onDeleteMessage?.call();
  }

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
    final canReact = onReact != null && chatCanReact(message, reactionChoices);
    final deleted = message.isDeleted;
    final canEdit =
        outbound && !deleted && message.canEdit && onEditMessage != null;
    final canDelete =
        outbound && !deleted && message.canDelete && onDeleteMessage != null;
    final canCorrect = outbound &&
        !deleted &&
        !canEdit &&
        !canDelete &&
        onCorrection != null &&
        copyText != null;
    // Staff reactions sit on inbound bubbles, the customer's on outbound ones.
    final reaction = outbound ? message.customerReaction : message.staffReaction;
    final hasReaction = reaction != null && reaction.isNotEmpty;

    final footer = <String>[
      if (time != null) formatDateTime(context, time, pattern: 'h:mm a'),
      if (outbound && message.sentVia == 'Phone') l10n.chatSentFromPhone,
      if (outbound && message.sentVia == 'System') l10n.chatSentBySystem,
      if (outbound &&
          message.sentVia != 'Phone' &&
          (message.sentByName ?? message.sentBy) != null)
        l10n.chatSentBy((message.sentByName ?? message.sentBy)!),
    ];

    final tick = outbound && showReceipts
        ? chatReceiptTick(context, message, foreground)
        : null;

    return Align(
      alignment:
          outbound ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onLongPress: deleted ||
                  (copyText == null && !canReact && !canEdit && !canDelete)
              ? null
              : () => showChatMessageActionsSheet(
                  context,
                  text: copyText,
                  onUseInReply: onUseInReply,
                  reactionChoices: canReact ? reactionChoices : const <String>[],
                  currentReaction: message.staffReaction,
                  onReact: canReact ? onReact : null,
                  canEdit: canEdit,
                  canDelete: canDelete,
                  onEdit: canEdit ? () => _edit(context) : null,
                  onDelete: canDelete ? () => _delete(context) : null,
                  onCorrection: canCorrect ? onCorrection : null,
                ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
          Container(
            key: ValueKey('chat-message-${message.name}'),
            margin: EdgeInsets.fromLTRB(12, 3, 12, hasReaction ? 15 : 3),
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
                  if (deleted)
                    ChatDeletedBody(message: message)
                  else
                    ChatMessageContent(
                      message: message,
                      galleryMessages: galleryMessages,
                    ),
                  if (footer.isNotEmpty ||
                      tick != null ||
                      (message.isEdited && !deleted)) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (footer.isNotEmpty)
                          Flexible(
                            child: Text(
                              footer.join(' · '),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: foreground.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        if (message.isEdited && !deleted) ...[
                          if (footer.isNotEmpty) const SizedBox(width: 6),
                          ChatEditedLabel(
                            message: message,
                            color: foreground.withValues(alpha: 0.7),
                          ),
                        ],
                        if (tick != null) ...[
                          if (footer.isNotEmpty || message.isEdited)
                            const SizedBox(width: 4),
                          tick,
                        ],
                      ],
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
          if (hasReaction)
            PositionedDirectional(
              bottom: 0,
              end: outbound ? null : 20,
              start: outbound ? 20 : null,
              child: Container(
                key: const ValueKey('chat-reaction-badge'),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Text(reaction, style: const TextStyle(fontSize: 15)),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

/// edited label: tap shows the text before the edit.
class ChatEditedLabel extends StatelessWidget {
  const ChatEditedLabel({super.key, required this.message, required this.color});

  final ChatMessage message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final original = message.originalBody;
    return InkWell(
      key: const ValueKey('chat-edited-label'),
      onTap: original == null || original.trim().isEmpty
          ? null
          : () => showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(chatBi(
                    dialogContext,
                    'Original text',
                    'النص الأصلي',
                  )),
                  content: SelectableText(original),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(chatBi(dialogContext, 'Close', 'إغلاق')),
                    ),
                  ],
                ),
              ),
      child: Text(
        chatBi(context, 'edited', 'اتعدلت'),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }
}

/// A deleted message: greyed italic notice; tap toggles the original text
/// (staff only) dimmed underneath.
class ChatDeletedBody extends StatefulWidget {
  const ChatDeletedBody({super.key, required this.message});

  final ChatMessage message;

  @override
  State<ChatDeletedBody> createState() => _ChatDeletedBodyState();
}

class _ChatDeletedBodyState extends State<ChatDeletedBody> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final original = (message.originalBody ?? message.body).trim();
    final notice = message.isInbound
        ? chatBi(
            context,
            '🚫 Customer deleted this message',
            '🚫 العميل مسح الرسالة',
          )
        : chatBi(context, '🚫 Message deleted', '🚫 الرسالة اتمسحت');
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color:
              DefaultTextStyle.of(context).style.color?.withValues(alpha: 0.55),
        );
    return InkWell(
      key: const ValueKey('chat-deleted-body'),
      onTap: original.isEmpty ? null : () => setState(() => _show = !_show),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(notice, style: style),
          if (_show && original.isNotEmpty) ...[
            const SizedBox(height: 4),
            Opacity(
              opacity: 0.55,
              child: ChatBidiText(
                original,
                key: const ValueKey('chat-deleted-original'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The body of a message by type: text, image, location link, an inline
/// player for voice notes, or an "open" tile for video / documents.
class ChatMessageContent extends StatelessWidget {
  const ChatMessageContent({
    super.key,
    required this.message,
    this.galleryMessages = const <ChatMessage>[],
  });

  final ChatMessage message;

  /// The thread's photos for the viewer; empty opens just this one.
  final List<ChatMessage> galleryMessages;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = message.messageType;
    final body = message.body.trim();
    final linkColor = message.isOutbound
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : null;
    final isDocument = type == 'document';
    final docParts = isDocument ? chatSplitDocumentBody(body) : null;
    final captionText = isDocument ? docParts!.caption : body;

    Widget? caption() => captionText.isEmpty
        ? null
        : ChatBidiText(captionText, linkColor: linkColor);

    switch (type) {
      case 'image':
      case 'sticker':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ChatMessageImage(message: message, gallery: galleryMessages),
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
            else if (type == 'video' &&
                ChatRepository.isSessionMediaUrl(message.mediaUrl))
              ChatVideoTile(message: message)
            else
              ChatMediaOpenTile(
                message: message,
                fileName: docParts?.fileName,
              ),
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
        if (body.isNotEmpty) return ChatBidiText(body, linkColor: linkColor);
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
  const ChatMessageImage({
    super.key,
    required this.message,
    this.gallery = const <ChatMessage>[],
  });

  final ChatMessage message;

  /// Every photo of the thread; the viewer swipes across them.
  final List<ChatMessage> gallery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final url = message.mediaUrl;
    if (!ChatRepository.isSessionMediaUrl(url)) {
      return _MediaPlaceholder(
        icon: Icons.image_outlined,
        label: l10n.chatMediaUnavailable,
        detail: message.error,
      );
    }
    final sticker = message.messageType == 'sticker';
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
        detail: message.error,
      ),
      data: (data) => GestureDetector(
        onTap: () => showChatImageGallery(
          context,
          images: gallery,
          initial: message,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: sticker
                ? const BoxConstraints(maxHeight: 140, maxWidth: 140)
                : const BoxConstraints(maxHeight: 260, maxWidth: 260),
            child: Image.memory(
              data,
              // A sticker is shown whole; a photo fills its frame.
              fit: sticker ? BoxFit.contain : BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _MediaPlaceholder(
                icon: Icons.broken_image_outlined,
                label: l10n.chatMediaLoadFailed,
                detail: message.error,
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
  const ChatMediaOpenTile({super.key, required this.message, this.fileName});

  final ChatMessage message;

  /// The document's file name (first line of its body); null shows the type.
  final String? fileName;

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
    if (!available) {
      return _MediaPlaceholder(
        icon: chatMessageTypeIcon(type),
        label: l10n.chatMediaUnavailable,
        detail: widget.message.error,
      );
    }
    final isDocument = type == 'document';
    final name = widget.fileName ??
        (isDocument ? chatMediaFileName(widget.message.mediaUrl!) : null);
    final icon = isDocument
        ? chatDocumentIcon(widget.message.mediaMime, name)
        : chatMessageTypeIcon(type);
    return OutlinedButton.icon(
      onPressed: !_busy ? _open : null,
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: isDocument && name != null
          ? Directionality(
              textDirection: TextDirection.ltr,
              child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            )
          : Text(
              '${chatMessageTypeLabel(l10n, type)} · ${l10n.chatOpenMedia}',
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
  const _MediaPlaceholder({
    required this.icon,
    required this.label,
    this.detail,
  });

  final IconData icon;
  final String label;

  /// The message's `error` text, shown small under the label.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final error = detail?.trim();
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              if (error != null && error.isNotEmpty)
                Text(
                  error,
                  key: const ValueKey('chat-media-error-detail'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A document body is `filename\ncaption`. Older messages hold only a caption:
/// a single line counts as the file name only when it looks like one
/// (`report.pdf`), otherwise it is the caption.
({String? fileName, String caption}) chatSplitDocumentBody(String body) {
  final text = body.trim();
  if (text.isEmpty) return (fileName: null, caption: '');
  final newline = text.indexOf('\n');
  if (newline < 0) {
    final looksLikeFile = RegExp(
      r'^[^\s/\\][^/\\]*\.[A-Za-z0-9]{1,5}$',
    ).hasMatch(text);
    return looksLikeFile
        ? (fileName: text, caption: '')
        : (fileName: null, caption: text);
  }
  final first = text.substring(0, newline).trim();
  return (
    fileName: first.isEmpty ? null : first,
    caption: text.substring(newline + 1).trim(),
  );
}

/// A file-type icon from the mime type, falling back to the file extension.
IconData chatDocumentIcon(String? mime, String? fileName) {
  final m = (mime ?? '').split(';').first.trim().toLowerCase();
  final dot = (fileName ?? '').lastIndexOf('.');
  final ext = dot < 0 ? '' : fileName!.substring(dot + 1).toLowerCase();
  if (m == 'application/pdf' || ext == 'pdf') {
    return Icons.picture_as_pdf_outlined;
  }
  if (m.startsWith('image/') ||
      const {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'}.contains(ext)) {
    return Icons.image_outlined;
  }
  if (m.startsWith('audio/') ||
      const {'mp3', 'ogg', 'opus', 'wav', 'm4a', 'aac'}.contains(ext)) {
    return Icons.audiotrack_outlined;
  }
  if (m.startsWith('video/') ||
      const {'mp4', 'mov', 'avi', 'mkv', '3gp'}.contains(ext)) {
    return Icons.videocam_outlined;
  }
  if (m.contains('spreadsheet') ||
      m.contains('excel') ||
      m == 'text/csv' ||
      const {'xls', 'xlsx', 'csv', 'ods'}.contains(ext)) {
    return Icons.table_chart_outlined;
  }
  if (m.contains('word') ||
      m.contains('opendocument.text') ||
      const {'doc', 'docx', 'odt', 'rtf', 'txt'}.contains(ext)) {
    return Icons.article_outlined;
  }
  if (m.contains('zip') ||
      m.contains('compressed') ||
      m.contains('rar') ||
      const {'zip', 'rar', '7z', 'tar', 'gz'}.contains(ext)) {
    return Icons.folder_zip_outlined;
  }
  return Icons.insert_drive_file_outlined;
}
