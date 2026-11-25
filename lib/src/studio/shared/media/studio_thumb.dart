import 'package:flutter/material.dart';

import '../../core/theme/studio_tokens.dart';
import '../../data/models/studio_enums.dart';
import '../../data/models/studio_models.dart';
import 'studio_network_image.dart';

/// "1:24" for a length in seconds.
String formatDuration(double? seconds) {
  if (seconds == null) return '';
  final s = seconds.round();
  final m = s ~/ 60;
  final r = (s % 60).toString().padLeft(2, '0');
  return '$m:$r';
}

/// The still picture to show for [m]: a video's poster, an image's thumbnail.
String? studioStillUrl(StudioMedia m) => m.kind == MediaKind.video
    ? (m.posterUrl ?? m.thumbUrl)
    : (m.thumbUrl ?? m.feedUrl ?? m.url);

/// Thumbnail or poster of an image or video. Videos get a play badge and their
/// length. A missing or broken picture shows a grey box with an icon.
class StudioThumb extends StatelessWidget {
  const StudioThumb({
    super.key,
    required this.media,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius,
  });

  final StudioMedia? media;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final m = media;
    final isVideo = m?.kind == MediaKind.video;
    Widget child = Stack(
      fit: StackFit.passthrough,
      children: [
        StudioNetworkImage(
          url: m == null ? null : studioStillUrl(m),
          fit: fit,
          width: width,
          height: height,
          errorIcon: isVideo ? Icons.movie_outlined : Icons.image_outlined,
        ),
        if (isVideo) ...[
          const Positioned.fill(child: Center(child: _PlayBadge())),
          if (m?.durationS != null)
            PositionedDirectional(
              end: StudioSpacing.xs,
              bottom: StudioSpacing.xs,
              child: _DurationTag(text: formatDuration(m!.durationS)),
            ),
        ],
      ],
    );
    if (width != null || height != null) {
      child = SizedBox(width: width, height: height, child: child);
    }
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.circular(StudioRadii.sm),
      child: child,
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    decoration: const BoxDecoration(
      color: Color(0x99000000),
      shape: BoxShape.circle,
    ),
    child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
  );
}

class _DurationTag extends StatelessWidget {
  const _DurationTag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: const Color(0xB3000000),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 11),
    ),
  );
}
