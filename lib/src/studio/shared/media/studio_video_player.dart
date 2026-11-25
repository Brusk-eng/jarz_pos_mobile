import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/studio_tokens.dart';
import '../../data/models/studio_models.dart';
import 'media_strings.dart';
import 'studio_network_image.dart';
import 'studio_thumb.dart';
import 'studio_video_pool.dart';

/// A video with its poster first.
///
/// - The poster shows at once; the controller is only made when the video is
///   [active] (on screen), [prefetch]ed (next to the active one) or the person
///   tapped play.
/// - Controllers come from a [StudioVideoPool] (at most 3 live): the nearest
///   [StudioVideoPoolScope], or a private one.
/// - It pauses when [active] turns false, when scrolled mostly out of view,
///   when another screen covers it and when the app goes to the background.
/// - A video that fails shows a plain message with "Try again".
class StudioVideoPlayer extends ConsumerStatefulWidget {
  const StudioVideoPlayer({
    super.key,
    required this.media,
    this.active = true,
    this.prefetch = false,
    this.autoplay = false,
    this.muted = true,
    this.showControls = true,
    this.fit = BoxFit.contain,
    this.onTap,
  });

  final StudioMedia media;

  /// This is the video on screen. Only an active video plays.
  final bool active;

  /// Get the controller ready without playing (the neighbour in a feed).
  final bool prefetch;
  final bool autoplay;
  final bool muted;

  /// Scrub bar, time and sound button along the bottom.
  final bool showControls;
  final BoxFit fit;

  /// Extra tap handler; the tap still toggles play and pause.
  final VoidCallback? onTap;

  @override
  ConsumerState<StudioVideoPlayer> createState() => _StudioVideoPlayerState();
}

class _StudioVideoPlayerState extends ConsumerState<StudioVideoPlayer>
    with WidgetsBindingObserver {
  StudioVideoPool? _ownPool;
  StudioVideoPool? _pool;
  VideoSlot? _slot;
  bool? _userPlay;
  bool _started = false;
  late bool _muted = widget.muted;
  bool _visible = true;
  bool _tickerOn = true;
  bool _foreground = true;
  final List<ScrollPosition> _positions = [];

  String get _key => widget.media.id;
  Uri get _url => Uri.parse(widget.media.feedUrl ?? widget.media.url);
  bool get _wants =>
      (widget.active && widget.autoplay) || widget.prefetch || _started;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerOn = TickerMode.valuesOf(context).enabled;
    final scoped = StudioVideoPoolScope.maybeOf(context);
    if (scoped != null) {
      _ownPool?.dispose();
      _ownPool = null;
      _pool = scoped;
    } else {
      _ownPool ??= StudioVideoPool(
        factory: ref.read(studioVideoControllerFactoryProvider),
      );
      _pool = _ownPool;
    }
    _watchScrolling();
    _sync();
  }

  @override
  void didUpdateWidget(StudioVideoPlayer old) {
    super.didUpdateWidget(old);
    if (old.media.id != widget.media.id) {
      _detach(release: true, key: old.media.id);
      _userPlay = null;
      _started = false;
    }
    if (old.muted != widget.muted) _muted = widget.muted;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _applyPlayback();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final p in _positions) {
      p.removeListener(_checkVisible);
    }
    _slot?.removeListener(_onSlot);
    _pool?.deactivate(_key);
    if (_ownPool != null) {
      _ownPool!.dispose();
    } else if (_slot != null) {
      _pool?.release(_key);
    }
    super.dispose();
  }

  // -------------------------------------------------------------- scrolling

  void _watchScrolling() {
    for (final p in _positions) {
      p.removeListener(_checkVisible);
    }
    _positions.clear();
    context.visitAncestorElements((e) {
      if (e is StatefulElement && e.state is ScrollableState) {
        final pos = (e.state as ScrollableState).position;
        pos.addListener(_checkVisible);
        _positions.add(pos);
      }
      return true;
    });
  }

  void _checkVisible() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    var visible = true;
    final mine = box.localToGlobal(Offset.zero) & box.size;
    context.visitAncestorElements((e) {
      if (e is StatefulElement && e.state is ScrollableState) {
        final r = e.renderObject;
        if (r is RenderBox && r.attached && r.hasSize) {
          final view = r.localToGlobal(Offset.zero) & r.size;
          final hit = mine.intersect(view);
          final seen = hit.width <= 0 || hit.height <= 0
              ? 0.0
              : (hit.width * hit.height) / (mine.width * mine.height);
          if (seen < 0.4) visible = false;
        }
      }
      return true;
    });
    if (visible != _visible) {
      _visible = visible;
      _applyPlayback();
    }
  }

  // ------------------------------------------------------------ the slot

  void _sync() {
    final pool = _pool;
    if (pool == null) return;
    if (_wants) {
      final slot = pool.acquire(_key, _url, active: widget.active);
      if (!identical(slot, _slot)) {
        _slot?.removeListener(_onSlot);
        _slot = slot;
        slot.addListener(_onSlot);
      }
      _applyPlayback();
    } else if (_slot != null) {
      _detach(release: true, key: _key);
    }
  }

  void _detach({required bool release, required String key}) {
    final c = _slot?.controller;
    if (c != null && c.value.isPlaying) c.pause();
    _slot?.removeListener(_onSlot);
    _slot = null;
    if (release) _pool?.release(key);
  }

  void _onSlot() {
    if (!mounted) return;
    // A video the pool dropped to make room stays on its poster; it asks
    // for a controller again the next time its widget changes.
    _applyPlayback();
    _refresh();
  }

  /// setState that is safe when the pool pokes us in the middle of a build.
  void _refresh() {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  bool get _shouldPlay =>
      widget.active &&
      _visible &&
      _tickerOn &&
      _foreground &&
      (_userPlay ?? widget.autoplay);

  void _applyPlayback() {
    final c = _slot?.controller;
    if (c == null || !(_slot?.isReady ?? false)) return;
    c.setVolume(_muted ? 0 : 1);
    if (_shouldPlay) {
      if (!c.value.isPlaying) c.play();
    } else {
      if (c.value.isPlaying) c.pause();
    }
  }

  void _toggle() {
    widget.onTap?.call();
    final playing = _slot?.controller?.value.isPlaying ?? false;
    setState(() {
      _userPlay = !(playing && _shouldPlay);
      if (_userPlay!) _started = true;
    });
    _sync();
    _applyPlayback();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _applyPlayback();
  }

  void _retry() {
    _pool?.retry(_key);
    setState(() {});
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final t = MediaStrings.of(context);
    final slot = _slot;
    final m = widget.media;
    final ratio = (m.width != null && m.height != null && m.height! > 0)
        ? m.width! / m.height!
        : 9 / 16;
    final failed = slot?.status == VideoSlotStatus.failed;
    final c = slot?.isReady ?? false ? slot!.controller : null;

    final poster = StudioNetworkImage(
      url: studioStillUrl(m),
      fit: widget.fit,
      errorIcon: Icons.movie_outlined,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: poster),
        if (c != null)
          Positioned.fill(
            child: FittedBox(
              fit: widget.fit == BoxFit.cover ? BoxFit.cover : BoxFit.contain,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: c.value.size.width > 0 ? c.value.size.width : 1080,
                height: c.value.size.height > 0
                    ? c.value.size.height
                    : 1080 / ratio,
                child: VideoPlayer(c),
              ),
            ),
          ),
        Positioned.fill(
          child: GestureDetector(
            key: const ValueKey('video-tap'),
            behavior: HitTestBehavior.opaque,
            onTap: failed ? null : _toggle,
          ),
        ),
        if (failed)
          _ErrorLayer(
            message: t.couldNotPlay,
            retry: t.tryAgain,
            onRetry: _retry,
          )
        else if (c == null && slot != null && widget.active)
          const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
                key: ValueKey('video-loading'),
              ),
            ),
          ),
        if (!failed)
          Center(
            child: IgnorePointer(
              child: c == null
                  ? (slot == null || !widget.active
                        ? const _BigPlay()
                        : const SizedBox.shrink())
                  : ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: c,
                      builder: (_, v, _) => v.isPlaying
                          ? const SizedBox.shrink()
                          : const _BigPlay(),
                    ),
            ),
          ),
        if (widget.showControls && c != null && !failed)
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: _Controls(
              controller: c,
              muted: _muted,
              onMute: _toggleMute,
              onToggle: _toggle,
            ),
          ),
      ],
    );
  }
}

class _BigPlay extends StatelessWidget {
  const _BigPlay();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('video-play-badge'),
    width: 56,
    height: 56,
    decoration: const BoxDecoration(
      color: Color(0x99000000),
      shape: BoxShape.circle,
    ),
    child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
  );
}

class _ErrorLayer extends StatelessWidget {
  const _ErrorLayer({
    required this.message,
    required this.retry,
    required this.onRetry,
  });

  final String message;
  final String retry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xCC000000),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(StudioSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(height: StudioSpacing.sm),
            Text(
              message,
              key: const ValueKey('video-error'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: StudioSpacing.md),
            FilledButton(
              key: const ValueKey('video-retry'),
              onPressed: onRetry,
              child: Text(retry),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.controller,
    required this.muted,
    required this.onMute,
    required this.onToggle,
  });

  final VideoPlayerController controller;
  final bool muted;
  final VoidCallback onMute;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = MediaStrings.of(context);
    return Container(
      color: const Color(0x66000000),
      padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (_, v, _) {
          final total = v.duration.inMilliseconds;
          final pos = v.position.inMilliseconds.clamp(0, total > 0 ? total : 1);
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('video-toggle'),
                  tooltip: v.isPlaying ? t.pause : t.play,
                  color: Colors.white,
                  onPressed: onToggle,
                  icon: Icon(v.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                Expanded(
                  child: Slider(
                    key: const ValueKey('video-scrub'),
                    value: pos.toDouble(),
                    max: total > 0 ? total.toDouble() : 1,
                    activeColor: StudioColors.berryPink,
                    inactiveColor: Colors.white38,
                    onChanged: total > 0
                        ? (x) => controller.seekTo(
                            Duration(milliseconds: x.round()),
                          )
                        : null,
                  ),
                ),
                Text(
                  '${formatDuration(pos / 1000)} / ${formatDuration(total / 1000)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                IconButton(
                  key: const ValueKey('video-mute'),
                  tooltip: muted ? t.unmute : t.mute,
                  color: Colors.white,
                  onPressed: onMute,
                  icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
