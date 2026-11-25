import 'package:flutter/material.dart';

import '../../core/theme/studio_tokens.dart';
import 'media_strings.dart';

/// A network picture that never throws: a soft placeholder while it loads and
/// a grey box with an icon when it cannot load (no network, bad link, tests).
///
/// On the web the picture may come from another domain without CORS headers,
/// so it falls back to a plain `<img>` element when the canvas fetch fails.
class StudioNetworkImage extends StatelessWidget {
  const StudioNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.showErrorLabel = false,
    this.errorIcon = Icons.image_outlined,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Say "this picture will not load" under the icon (large views only).
  final bool showErrorLabel;
  final IconData errorIcon;

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return _placeholder(context);
    return Image.network(
      u,
      fit: fit,
      width: width,
      height: height,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      gaplessPlayback: true,
      errorBuilder: (context, _, _) => _placeholder(context),
      frameBuilder: (context, child, frame, sync) {
        if (sync || frame != null) return child;
        return _box(const SizedBox.shrink());
      },
    );
  }

  Widget _box(Widget child) => SizedBox(
    width: width,
    height: height,
    child: ColoredBox(
      color: const Color(0xFFEDE8EC),
      child: Center(child: child),
    ),
  );

  Widget _placeholder(BuildContext context) {
    final label = showErrorLabel ? MediaStrings.of(context).couldNotShow : null;
    return _box(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(errorIcon, color: StudioColors.plumMuted),
          if (label != null) ...[
            const SizedBox(height: StudioSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: StudioColors.plumMuted),
            ),
          ],
        ],
      ),
    );
  }
}
