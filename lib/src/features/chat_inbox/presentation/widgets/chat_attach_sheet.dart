import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/user_error_message.dart';
import '../../data/chat_media_limits.dart';
import '../chat_labels.dart';
import 'chat_message_bubble.dart' show chatDocumentIcon;

/// A file the moderator chose to send: bytes (web, small photos) or a path
/// (mobile, streamed from disk when uploaded).
class ChatPickedMedia {
  const ChatPickedMedia({
    required this.filename,
    required this.mime,
    required this.size,
    this.bytes,
    this.path,
  });

  final String filename;
  final String mime;
  final int size;
  final Uint8List? bytes;
  final String? path;

  ChatMediaKind get kind => chatMediaKindOf(mime, filename);
}

enum ChatAttachSource { photo, camera, video, file }

/// Opens the attach sheet (Photo / Camera / Video / File), picks the file and
/// returns it, or null when cancelled. A file over its size cap is refused
/// with a snackbar and null. Camera is not offered on web.
Future<ChatPickedMedia?> showChatAttachSheet(BuildContext context) async {
  final source = await showModalBottomSheet<ChatAttachSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      Widget option(ChatAttachSource value, IconData icon, String label) =>
          ListTile(
            key: ValueKey('chat-attach-${value.name}'),
            leading: Icon(icon),
            title: Text(label),
            onTap: () => Navigator.of(sheetContext).pop(value),
          );
      return SafeArea(
        child: Column(
          key: const ValueKey('chat-attach-sheet'),
          mainAxisSize: MainAxisSize.min,
          children: [
            option(
              ChatAttachSource.photo,
              Icons.photo_outlined,
              chatBi(sheetContext, 'Photo', 'صورة'),
            ),
            if (!kIsWeb)
              option(
                ChatAttachSource.camera,
                Icons.photo_camera_outlined,
                chatBi(sheetContext, 'Camera', 'كاميرا'),
              ),
            option(
              ChatAttachSource.video,
              Icons.videocam_outlined,
              chatBi(sheetContext, 'Video', 'فيديو'),
            ),
            option(
              ChatAttachSource.file,
              Icons.attach_file,
              chatBi(sheetContext, 'File', 'ملف'),
            ),
          ],
        ),
      );
    },
  );
  if (source == null || !context.mounted) return null;
  final messenger = ScaffoldMessenger.of(context);
  final arabic = Localizations.localeOf(context).languageCode == 'ar';
  final failed = chatBi(
    context,
    'Could not open that file.',
    'مقدرتش أفتح الملف ده.',
  );
  try {
    final picked = await _pick(source);
    if (picked == null) return null;
    final error = chatMediaSizeError(
      kind: picked.kind,
      bytes: picked.size,
      arabic: arabic,
    );
    if (error != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return null;
    }
    return picked;
  } catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failed)));
    return null;
  }
}

Future<ChatPickedMedia?> _pick(ChatAttachSource source) async {
  switch (source) {
    case ChatAttachSource.photo:
    case ChatAttachSource.camera:
      final file = await ImagePicker().pickImage(
        source: source == ChatAttachSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        // Phone photos are often over the 5 MB cap; this keeps them sharp
        // enough for a chat and well under it.
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (file == null) return null;
      return _fromXFile(file, fallbackMime: 'image/jpeg', readBytes: true);
    case ChatAttachSource.video:
      final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (file == null) return null;
      return _fromXFile(file, fallbackMime: 'video/mp4', readBytes: false);
    case ChatAttachSource.file:
      final result = await FilePicker.platform.pickFiles(
        withData: kIsWeb,
        allowMultiple: false,
      );
      final file = result?.files.single;
      if (file == null) return null;
      final name = file.name;
      return ChatPickedMedia(
        filename: name,
        mime: chatGuessMime(name),
        size: file.size,
        bytes: kIsWeb ? file.bytes : null,
        path: kIsWeb ? null : file.path,
      );
  }
}

Future<ChatPickedMedia> _fromXFile(
  XFile file, {
  required String fallbackMime,
  required bool readBytes,
}) async {
  final name = file.name.isEmpty ? 'file' : file.name;
  var mime = file.mimeType ?? chatGuessMime(name);
  if (mime == 'application/octet-stream') mime = fallbackMime;
  final size = await file.length();
  final useBytes = kIsWeb || readBytes;
  final tooBig = size > chatMediaMaxBytes(chatMediaKindOf(mime, name));
  return ChatPickedMedia(
    filename: name,
    mime: mime,
    size: size,
    // Never load an oversized file into memory just to refuse it.
    bytes: useBytes && !tooBig ? await file.readAsBytes() : null,
    path: useBytes ? null : file.path,
  );
}

/// The preview before sending: thumbnail / icon, name and size, an optional
/// caption (not for audio) and Send with upload progress. [onSend] runs the
/// upload; the sheet closes on success and shows the error on failure so the
/// moderator can retry. Returns true when it was sent.
Future<bool> showChatMediaPreviewSheet(
  BuildContext context, {
  required ChatPickedMedia media,
  required Future<void> Function(
    ChatPickedMedia media,
    String caption,
    void Function(int sent, int total) onProgress,
  ) onSend,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _MediaPreviewSheet(media: media, onSend: onSend),
  );
  return sent ?? false;
}

class _MediaPreviewSheet extends StatefulWidget {
  const _MediaPreviewSheet({required this.media, required this.onSend});

  final ChatPickedMedia media;
  final Future<void> Function(
    ChatPickedMedia media,
    String caption,
    void Function(int sent, int total) onProgress,
  ) onSend;

  @override
  State<_MediaPreviewSheet> createState() => _MediaPreviewSheetState();
}

class _MediaPreviewSheetState extends State<_MediaPreviewSheet> {
  final _caption = TextEditingController();
  bool _busy = false;
  double? _progress;
  String? _error;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _progress = 0;
    });
    try {
      await widget.onSend(widget.media, _caption.text.trim(), (sent, total) {
        if (!mounted || total <= 0) return;
        setState(() => _progress = (sent / total).clamp(0.0, 1.0));
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _progress = null;
        _error = context.userErrorMessage(
          e,
          fallback: chatBi(
            context,
            'Could not send the file.',
            'مقدرتش أبعت الملف.',
          ),
        );
      });
    }
  }

  Widget _preview(ThemeData theme) {
    final media = widget.media;
    final kind = media.kind;
    if (kind == ChatMediaKind.image && media.bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          media.bytes!,
          key: const ValueKey('chat-media-preview-image'),
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
        ),
      );
    }
    final icon = switch (kind) {
      ChatMediaKind.video => Icons.videocam_outlined,
      ChatMediaKind.audio => Icons.audiotrack_outlined,
      ChatMediaKind.image => Icons.image_outlined,
      ChatMediaKind.document => chatDocumentIcon(media.mime, media.filename),
    };
    return Icon(
      icon,
      key: const ValueKey('chat-media-preview-icon'),
      size: 72,
      color: theme.colorScheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = widget.media;
    final canCaption = media.kind != ChatMediaKind.audio;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            key: const ValueKey('chat-media-preview'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _preview(theme)),
              const SizedBox(height: 8),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  media.filename,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                formatChatFileSize(media.size),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              if (canCaption) ...[
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('chat-media-caption'),
                  controller: _caption,
                  enabled: !_busy,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: chatBi(
                      context,
                      'Caption (optional)',
                      'تعليق (اختياري)',
                    ),
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
              ],
              if (_busy) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  key: const ValueKey('chat-media-progress'),
                  value: (_progress == null || _progress! >= 1)
                      ? null
                      : _progress,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  key: const ValueKey('chat-media-send-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(false),
                      child: Text(chatBi(context, 'Cancel', 'إلغاء')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('chat-media-send'),
                      onPressed: _busy ? null : _send,
                      icon: const Icon(Icons.send),
                      label: Text(chatBi(context, 'Send', 'إرسال')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
