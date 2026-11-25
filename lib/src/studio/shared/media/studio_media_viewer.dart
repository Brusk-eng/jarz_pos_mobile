import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/studio_api.dart';
import '../../data/models/studio_enums.dart';
import '../../data/models/studio_models.dart';
import 'media_strings.dart';
import 'studio_network_image.dart';
import 'studio_video_player.dart';
import 'studio_video_pool.dart';
import '../studio_toast.dart';

/// Opens a link outside the app (the browser or the system downloader).
/// Returns false when it could not. Tests replace it.
typedef StudioLinkOpener = Future<bool> Function(Uri url);

final studioLinkOpenerProvider = Provider<StudioLinkOpener>(
  (ref) =>
      (url) => launchUrl(url, mode: LaunchMode.externalApplication),
);

/// Full-screen viewer: swipe between [items], pinch-zoom pictures, play videos
/// with scrub and sound, and a download button that asks the server for a
/// download link.
Future<void> openStudioMediaViewer(
  BuildContext context, {
  required List<StudioMedia> items,
  int initialIndex = 0,
}) {
  if (items.isEmpty) return Future.value();
  return Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => StudioMediaViewer(
        items: items,
        initialIndex: initialIndex.clamp(0, items.length - 1),
      ),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

class StudioMediaViewer extends ConsumerStatefulWidget {
  const StudioMediaViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  final List<StudioMedia> items;
  final int initialIndex;

  @override
  ConsumerState<StudioMediaViewer> createState() => _StudioMediaViewerState();
}

class _StudioMediaViewerState extends ConsumerState<StudioMediaViewer> {
  late final PageController _pc = PageController(
    initialPage: widget.initialIndex,
  );
  StudioVideoPool? _pool;
  late int _index = widget.initialIndex;
  bool _zoomed = false;
  bool _downloading = false;

  @override
  void dispose() {
    _pc.dispose();
    _pool?.dispose();
    super.dispose();
  }

  StudioVideoPool get pool => _pool ??= StudioVideoPool(
    factory: ref.read(studioVideoControllerFactoryProvider),
  );

  Future<void> _download() async {
    final t = MediaStrings.of(context);
    final media = widget.items[_index];
    setState(() => _downloading = true);
    try {
      final link = await ref
          .read(studioApiProvider)
          .mediaDownloadLink(mediaId: media.id);
      final ok = await ref.read(studioLinkOpenerProvider)(Uri.parse(link.url));
      if (!ok) throw StateError('could not open');
    } catch (_) {
      showStudioToast(t.downloadFailed);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = MediaStrings.of(context);
    final n = widget.items.length;
    return Scaffold(
      backgroundColor: Colors.black,
      body: StudioVideoPoolScope(
        pool: pool,
        child: Stack(
          children: [
            PageView.builder(
              key: const ValueKey('viewer-pages'),
              controller: _pc,
              itemCount: n,
              physics: _zoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              onPageChanged: (i) => setState(() {
                _index = i;
                _zoomed = false;
              }),
              itemBuilder: (_, i) {
                final m = widget.items[i];
                if (m.kind == MediaKind.video) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 56),
                    child: StudioVideoPlayer(
                      media: m,
                      active: i == _index,
                      prefetch: (i - _index).abs() == 1,
                      autoplay: true,
                      muted: false,
                    ),
                  );
                }
                return _ZoomableImage(
                  media: m,
                  onZoomChanged: (z) {
                    if (i == _index && z != _zoomed) {
                      setState(() => _zoomed = z);
                    }
                  },
                );
              },
            ),
            PositionedDirectional(
              start: 0,
              end: 0,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  color: const Color(0x80000000),
                  child: Row(
                    children: [
                      IconButton(
                        key: const ValueKey('viewer-close'),
                        tooltip: t.close,
                        color: Colors.white,
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      Expanded(
                        child: Text(
                          n > 1 ? t.itemOf(_index + 1, n) : '',
                          key: const ValueKey('viewer-counter'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      _downloading
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : IconButton(
                              key: const ValueKey('viewer-download'),
                              tooltip: t.download,
                              color: Colors.white,
                              icon: const Icon(Icons.download),
                              onPressed: _download,
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.media, required this.onZoomChanged});

  final StudioMedia media;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final TransformationController _tc = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _tc.addListener(() {
      final z = _tc.value.getMaxScaleOnAxis() > 1.02;
      if (z != _zoomed) {
        setState(() => _zoomed = z);
        widget.onZoomChanged(z);
      }
    });
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  void _doubleTap(Offset at) {
    if (_tc.value.getMaxScaleOnAxis() > 1.02) {
      _tc.value = Matrix4.identity();
    } else {
      const s = 2.5;
      _tc.value = Matrix4.identity()
        ..translateByDouble(-at.dx * (s - 1), -at.dy * (s - 1), 0, 1)
        ..scaleByDouble(s, s, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    Offset last = Offset.zero;
    final m = widget.media;
    return GestureDetector(
      onDoubleTapDown: (d) => last = d.localPosition,
      onDoubleTap: () => _doubleTap(last),
      child: InteractiveViewer(
        key: const ValueKey('viewer-zoom'),
        transformationController: _tc,
        // Panning only once zoomed in: at 1x a sideways drag belongs to the
        // page swipe.
        panEnabled: _zoomed,
        minScale: 1,
        maxScale: 5,
        child: Padding(
          padding: const EdgeInsets.only(top: 56),
          child: StudioNetworkImage(
            url: m.url,
            fit: BoxFit.contain,
            showErrorLabel: true,
            errorIcon: Icons.broken_image_outlined,
          ),
        ),
      ),
    );
  }
}
