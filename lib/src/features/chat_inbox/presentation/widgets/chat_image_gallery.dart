import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/user_error_message.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_models.dart';
import '../../state/chat_providers.dart';
import '../chat_labels.dart';
import 'chat_media_open.dart';

/// Whether [message] is a photo / sticker the gallery can show.
bool chatIsGalleryImage(ChatMessage message) =>
    (message.messageType == 'image' || message.messageType == 'sticker') &&
    ChatRepository.isSessionMediaUrl(message.mediaUrl);

/// Opens the full-screen viewer over [images] (oldest first), starting at
/// [initial] (matched by message name; the first image when not found).
Future<void> showChatImageGallery(
  BuildContext context, {
  required List<ChatMessage> images,
  required ChatMessage initial,
}) {
  final list = images.isEmpty ? [initial] : images;
  var start = list.indexWhere((m) => m.name == initial.name);
  if (start < 0) start = 0;
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ChatImageGallery(images: list, initialIndex: start),
    ),
  );
}

/// Swipe across every photo of the thread, pinch to zoom, Close and Share.
/// Each page loads its bytes lazily through [chatMediaBytesProvider].
class ChatImageGallery extends ConsumerStatefulWidget {
  const ChatImageGallery({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  final List<ChatMessage> images;
  final int initialIndex;

  @override
  ConsumerState<ChatImageGallery> createState() => _ChatImageGalleryState();
}

class _ChatImageGalleryState extends ConsumerState<ChatImageGallery> {
  late final PageController _pages;
  late int _index;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pages = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _share() {
    final message = widget.images[_index];
    final url = message.mediaUrl;
    final bytes =
        url == null ? null : ref.read(chatMediaBytesProvider(url)).valueOrNull;
    openChatMediaAttachment(
      context,
      ref.read(chatRepositoryProvider),
      message,
      bytes: bytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.images.length;
    return Scaffold(
      key: const ValueKey('chat-image-viewer'),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                key: const ValueKey('chat-image-pages'),
                controller: _pages,
                itemCount: count,
                // A zoomed page pans instead of swiping to the next photo.
                physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
                onPageChanged: (i) => setState(() {
                  _index = i;
                  _zoomed = false;
                }),
                itemBuilder: (context, i) => _GalleryPage(
                  key: ValueKey('chat-image-page-$i'),
                  message: widget.images[i],
                  onZoomChanged: (zoomed) {
                    if (i == _index && zoomed != _zoomed) {
                      setState(() => _zoomed = zoomed);
                    }
                  },
                ),
              ),
            ),
            PositionedDirectional(
              top: 4,
              start: 4,
              end: 4,
              child: Row(
                children: [
                  IconButton.filledTonal(
                    key: const ValueKey('chat-image-close'),
                    tooltip: chatBi(context, 'Close', 'إغلاق'),
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  if (count > 1)
                    Container(
                      key: const ValueKey('chat-image-indicator'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_index + 1} / $count',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  const Spacer(),
                  IconButton.filledTonal(
                    key: const ValueKey('chat-image-share'),
                    tooltip: kIsWeb
                        ? chatBi(context, 'Open in new tab', 'فتح في تبويب جديد')
                        : chatBi(context, 'Share', 'مشاركة'),
                    icon: Icon(
                      kIsWeb ? Icons.open_in_new : Icons.share_outlined,
                    ),
                    onPressed: _share,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryPage extends ConsumerStatefulWidget {
  const _GalleryPage({
    super.key,
    required this.message,
    required this.onZoomChanged,
  });

  final ChatMessage message;
  final ValueChanged<bool> onZoomChanged;

  @override
  ConsumerState<_GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<_GalleryPage> {
  final _transform = TransformationController();

  @override
  void initState() {
    super.initState();
    _transform.addListener(
      () => widget.onZoomChanged(_transform.value.getMaxScaleOnAxis() > 1.02),
    );
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.message.mediaUrl!;
    final bytes = ref.watch(chatMediaBytesProvider(url));
    return bytes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_outlined,
                  color: Colors.white70, size: 40),
              const SizedBox(height: 8),
              Text(
                context.userErrorMessage(
                  e,
                  fallback: chatBi(
                    context,
                    'Could not load the photo.',
                    'مقدرتش أحمّل الصورة.',
                  ),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              TextButton(
                onPressed: () => ref.invalidate(chatMediaBytesProvider(url)),
                child: Text(chatBi(context, 'Retry', 'حاول تاني')),
              ),
            ],
          ),
        ),
      ),
      data: (data) => InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: Image.memory(
            data,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white70,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}
