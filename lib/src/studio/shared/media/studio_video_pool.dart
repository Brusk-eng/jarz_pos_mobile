import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

/// Makes the controller for one video URL. Tests replace it with a fake.
typedef VideoControllerFactory = VideoPlayerController Function(Uri url);

VideoPlayerController _defaultFactory(Uri url) =>
    VideoPlayerController.networkUrl(url);

/// The factory the pools use. Override it in tests.
final studioVideoControllerFactoryProvider = Provider<VideoControllerFactory>(
  (ref) => _defaultFactory,
);

enum VideoSlotStatus { idle, loading, ready, failed }

/// One video held by a [StudioVideoPool]. Listen to it to follow the
/// controller from "loading" to "ready" (or "failed").
class VideoSlot extends ChangeNotifier {
  VideoSlot._(this.key, this.url);

  final String key;
  final Uri url;
  VideoPlayerController? _controller;
  VideoSlotStatus _status = VideoSlotStatus.idle;
  bool _active = false;
  int _lastUsed = 0;
  bool _disposed = false;

  VideoSlotStatus get status => _status;
  VideoPlayerController? get controller => _controller;
  bool get isReady => _status == VideoSlotStatus.ready;

  void _set(VideoSlotStatus s) {
    _status = s;
    if (!_disposed) notifyListeners();
  }

  void _poke() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// A small pool of video controllers: at most [maxLive] exist at the same
/// time (the previous, the current and the next video of a feed). Asking for
/// one more drops the least recently used one that is not the active video.
///
/// A dropped slot goes back to `idle`; the player that still wants it asks
/// again and gets a fresh controller.
class StudioVideoPool {
  StudioVideoPool({VideoControllerFactory? factory, this.maxLive = 3})
    : _factory = factory ?? _defaultFactory;

  final VideoControllerFactory _factory;
  final int maxLive;
  final Map<String, VideoSlot> _slots = {};
  int _tick = 0;
  bool _disposed = false;

  /// Controllers that exist right now.
  int get liveCount => _slots.values.where((s) => s._controller != null).length;

  /// The slot for [key], making and starting its controller when needed.
  /// [active] marks the video on screen: it is never the one dropped.
  VideoSlot acquire(String key, Uri url, {bool active = false}) {
    final slot = _slots.putIfAbsent(key, () => VideoSlot._(key, url));
    slot._active = active;
    slot._lastUsed = ++_tick;
    if (slot._controller == null && slot._status != VideoSlotStatus.failed) {
      _start(slot);
    }
    _trim(keep: slot);
    return slot;
  }

  /// Marks [key] as no longer on screen (it can be dropped, or kept as the
  /// previous or next video until the pool needs the room).
  void deactivate(String key) => _slots[key]?._active = false;

  /// Drops the controller of [key] and forgets it.
  void release(String key) {
    final slot = _slots.remove(key);
    if (slot == null) return;
    _drop(slot);
    slot.dispose();
  }

  /// Tries a failed (or dropped) video again.
  void retry(String key) {
    final slot = _slots[key];
    if (slot == null) return;
    _drop(slot);
    slot._status = VideoSlotStatus.idle;
    slot._lastUsed = ++_tick;
    _start(slot);
    _trim(keep: slot);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final s in _slots.values) {
      _drop(s);
      s.dispose();
    }
    _slots.clear();
  }

  void _start(VideoSlot slot) {
    final VideoPlayerController c;
    try {
      c = _factory(slot.url);
    } catch (_) {
      slot._set(VideoSlotStatus.failed);
      return;
    }
    slot._controller = c;
    slot._status = VideoSlotStatus.loading;
    c.setLooping(true).catchError((Object _) {});
    c
        .initialize()
        .then((_) {
          if (slot._controller != c || slot._disposed) return;
          slot._set(VideoSlotStatus.ready);
        })
        .catchError((Object _) {
          if (slot._controller != c || slot._disposed) return;
          slot._set(VideoSlotStatus.failed);
        });
  }

  void _drop(VideoSlot slot) {
    final c = slot._controller;
    slot._controller = null;
    if (c != null) {
      // Dispose after the frame: a widget may still be painting it.
      scheduleMicrotask(() {
        try {
          c.dispose();
        } catch (_) {}
      });
    }
    if (slot._status != VideoSlotStatus.failed) {
      slot._status = VideoSlotStatus.idle;
    }
  }

  void _trim({required VideoSlot keep}) {
    while (liveCount > maxLive) {
      VideoSlot? victim;
      for (final s in _slots.values) {
        if (s._controller == null || s == keep || s._active) continue;
        if (victim == null || s._lastUsed < victim._lastUsed) victim = s;
      }
      if (victim == null) return;
      _drop(victim);
      victim._poke();
    }
  }
}

/// Gives the players below it one shared pool (a feed or the viewer makes
/// one). Without it a player makes its own.
class StudioVideoPoolScope extends InheritedWidget {
  const StudioVideoPoolScope({
    super.key,
    required this.pool,
    required super.child,
  });

  final StudioVideoPool pool;

  static StudioVideoPool? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StudioVideoPoolScope>()?.pool;

  @override
  bool updateShouldNotify(StudioVideoPoolScope old) => pool != old.pool;
}
