import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/localization/user_error_message.dart';
import '../../data/chat_repository.dart';
import '../../data/chat_video_controller.dart';
import '../../data/chat_voice_note_source.dart';
import '../../data/models/chat_models.dart';
import '../../state/chat_voice_note_playback.dart';
import '../chat_labels.dart';
import 'chat_media_open.dart';

/// A video message in the thread: a dark tile with a play button. Tapping it
/// opens the in-app player ([ChatVideoPlayerPage]).
class ChatVideoTile extends StatelessWidget {
  const ChatVideoTile({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: const ValueKey('chat-video-tile'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => ChatVideoPlayerPage(message: message),
        ),
      ),
      child: Container(
        width: 220,
        height: 124,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            PositionedDirectional(
              start: 8,
              bottom: 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    chatBi(context, 'Video', 'فيديو'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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

/// Full-screen player. Mobile: the bytes are fetched with the session into a
/// temp file (so the private file works) and played from it; web: the browser
/// streams the same-origin URL with its own cookie.
class ChatVideoPlayerPage extends ConsumerStatefulWidget {
  const ChatVideoPlayerPage({super.key, required this.message});

  final ChatMessage message;

  @override
  ConsumerState<ChatVideoPlayerPage> createState() =>
      _ChatVideoPlayerPageState();
}

class _ChatVideoPlayerPageState extends ConsumerState<ChatVideoPlayerPage> {
  VideoPlayerController? _controller;
  ChatVoiceNoteSource? _source;
  Uint8List? _bytes;
  String? _error;
  bool _loading = true;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposed = true;
    _controller?.dispose();
    _source?.release();
    super.dispose();
  }

  String _fileName(String url, String? mime) {
    final name = chatMediaFileName(url);
    if (name.contains('.')) return name;
    return switch (chatBareMime(mime)) {
      'video/quicktime' => '$name.mov',
      'video/3gpp' => '$name.3gp',
      'video/webm' => '$name.webm',
      _ => '$name.mp4',
    };
  }

  Future<void> _load() async {
    final message = widget.message;
    final url = message.mediaUrl;
    if (!ChatRepository.isSessionMediaUrl(url)) {
      setState(() {
        _loading = false;
        _error = chatBi(
          context,
          'This video is not available.',
          'الفيديو ده مش متاح.',
        );
      });
      return;
    }
    final repo = ref.read(chatRepositoryProvider);
    final fallback = chatBi(
      context,
      'Could not load the video.',
      'مقدرتش أحمّل الفيديو.',
    );
    try {
      VideoPlayerController controller;
      if (kIsWeb) {
        controller = VideoPlayerController.networkUrl(
          Uri.parse(repo.absoluteMediaUrl(url!)),
        );
      } else {
        final bytes = await repo.fetchMediaBytes(url!);
        if (_disposed) return;
        _bytes = bytes;
        final source = await createChatVoiceNoteSource(
          bytes,
          mime: chatBareMime(message.mediaMime),
          fileName: _fileName(url, message.mediaMime),
        );
        if (_disposed) {
          await source.release();
          return;
        }
        _source = source;
        controller = chatFileVideoController(source.uri);
      }
      _controller = controller;
      await controller.initialize();
      if (_disposed) return;
      await controller.setLooping(false);
      await controller.play();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.userErrorMessage(e, fallback: fallback);
      });
    }
  }

  void _retry() {
    _controller?.dispose();
    _controller = null;
    _source?.release();
    _source = null;
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      key: const ValueKey('chat-video-player'),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _body(controller)),
            PositionedDirectional(
              top: 4,
              start: 4,
              end: 4,
              child: Row(
                children: [
                  IconButton.filledTonal(
                    key: const ValueKey('chat-video-close'),
                    tooltip: chatBi(context, 'Close', 'إغلاق'),
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    key: const ValueKey('chat-video-share'),
                    tooltip: kIsWeb
                        ? chatBi(context, 'Open in new tab', 'فتح في تبويب جديد')
                        : chatBi(context, 'Share', 'مشاركة'),
                    icon: Icon(
                      kIsWeb ? Icons.open_in_new : Icons.share_outlined,
                    ),
                    onPressed: () => openChatMediaAttachment(
                      context,
                      ref.read(chatRepositoryProvider),
                      widget.message,
                      bytes: _bytes,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(VideoPlayerController? controller) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 40),
              const SizedBox(height: 12),
              Text(
                _error!,
                key: const ValueKey('chat-video-error'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _retry,
                child: Text(chatBi(context, 'Retry', 'حاول تاني')),
              ),
            ],
          ),
        ),
      );
    }
    if (_loading || controller == null || !controller.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(key: ValueKey('chat-video-loading')),
            const SizedBox(height: 12),
            Text(
              chatBi(context, 'Loading video…', 'بحمّل الفيديو…'),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => controller.value.isPlaying
                ? controller.pause()
                : controller.play(),
            child: Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0
                    ? 16 / 9
                    : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
        _ControlBar(controller: controller),
      ],
    );
  }
}

/// Play / pause, position, seek bar and duration.
class _ControlBar extends StatelessWidget {
  const _ControlBar({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final total = value.duration.inMilliseconds;
        final position = value.position.inMilliseconds.clamp(0, total);
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 12, 8),
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('chat-video-play-pause'),
                  color: Colors.white,
                  icon: Icon(
                    value.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  onPressed: () =>
                      value.isPlaying ? controller.pause() : controller.play(),
                ),
                Text(
                  formatChatVoiceDuration(value.position),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Expanded(
                  child: Slider(
                    key: const ValueKey('chat-video-seek'),
                    value: total == 0 ? 0 : position.toDouble(),
                    max: total == 0 ? 1 : total.toDouble(),
                    onChanged: total == 0
                        ? null
                        : (v) => controller.seekTo(
                              Duration(milliseconds: v.round()),
                            ),
                  ),
                ),
                Text(
                  formatChatVoiceDuration(value.duration),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
