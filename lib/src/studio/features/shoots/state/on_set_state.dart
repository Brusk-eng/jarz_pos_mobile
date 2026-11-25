import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../core/offline/kv_store.dart';
import '../../../core/offline/reachability.dart';
import '../../../data/models/studio_models.dart';
import '../data/shoots_repository.dart';

/// "Now" with the time zone offset kept (`2026-11-25T14:05:00+02:00`), the
/// way the contract writes times. Tests replace it.
final onSetClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

String isoWithOffset(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  final off = t.timeZoneOffset;
  final sign = off.isNegative ? '-' : '+';
  final h = off.inHours.abs();
  final m = off.inMinutes.abs() % 60;
  return '${t.year.toString().padLeft(4, '0')}-${two(t.month)}-${two(t.day)}'
      'T${two(t.hour)}:${two(t.minute)}:${two(t.second)}$sign${two(h)}:${two(m)}';
}

/// One change made on set, waiting to reach the server. Ticks and notes are
/// kept with the time they were made (`at`) and a `request_id`, so sending
/// them twice is harmless.
class OutboxItem {
  const OutboxItem({
    required this.kind,
    required this.shotId,
    required this.at,
    required this.requestId,
    this.done,
    this.note,
  });

  /// `tick` or `note`.
  final String kind;
  final String shotId;
  final String at;
  final String requestId;
  final bool? done;
  final String? note;

  bool get isTick => kind == 'tick';

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'shot_id': shotId,
    'at': at,
    'request_id': requestId,
    'done': done,
    'note': note,
  };

  factory OutboxItem.fromJson(Map<String, dynamic> j) => OutboxItem(
    kind: j['kind'] as String,
    shotId: j['shot_id'] as String,
    at: j['at'] as String,
    requestId: j['request_id'] as String,
    done: j['done'] as bool?,
    note: j['note'] as String?,
  );
}

class OnSetState {
  const OnSetState({
    this.loaded = false,
    this.shoots = const {},
    this.outbox = const [],
    this.sending = false,
    this.serverTime,
    this.everSent = false,
    this.moved = const [],
    this.blockedMessage,
    this.refused = const [],
  });

  /// The stored data has been read.
  final bool loaded;

  /// The last copy of each shoot from the server (without waiting changes).
  final Map<String, StudioShoot> shoots;
  final List<OutboxItem> outbox;
  final bool sending;

  /// `server_time` of the last full sync, sent back as `modified_since`.
  final String? serverTime;

  /// Something reached the server since the app opened (for "all sent").
  final bool everSent;

  /// Pieces that moved on because of ticks, as the server reported them.
  final List<PieceRef> moved;

  /// Why sending is stuck (the Studio is not switched on, not allowed).
  final String? blockedMessage;

  /// Changes the server refused, in its words.
  final List<String> refused;

  int get pending => outbox.length;

  /// A shoot as the person sees it: the server copy with the waiting changes
  /// on top.
  StudioShoot? shoot(String id) {
    final s = shoots[id];
    return s == null ? null : applyOutbox(s, outbox);
  }

  OnSetState copyWith({
    bool? loaded,
    Map<String, StudioShoot>? shoots,
    List<OutboxItem>? outbox,
    bool? sending,
    String? serverTime,
    bool? everSent,
    List<PieceRef>? moved,
    String? blockedMessage,
    bool clearBlocked = false,
    List<String>? refused,
  }) => OnSetState(
    loaded: loaded ?? this.loaded,
    shoots: shoots ?? this.shoots,
    outbox: outbox ?? this.outbox,
    sending: sending ?? this.sending,
    serverTime: serverTime ?? this.serverTime,
    everSent: everSent ?? this.everSent,
    moved: moved ?? this.moved,
    blockedMessage: clearBlocked
        ? null
        : (blockedMessage ?? this.blockedMessage),
    refused: refused ?? this.refused,
  );
}

DateTime? _t(String? s) => s == null ? null : DateTime.tryParse(s);

/// Puts waiting ticks and notes on top of a server copy. Last write wins: a
/// waiting tick counts only when it is newer than what the server already
/// holds for that shot (`done_at`); an older one loses.
StudioShoot applyOutbox(StudioShoot s, List<OutboxItem> outbox) {
  if (outbox.isEmpty) return s;
  final shots = <ShootShot>[];
  for (final shot in s.shots) {
    var out = shot;
    OutboxItem? tick;
    OutboxItem? note;
    for (final o in outbox) {
      if (o.shotId != shot.id) continue;
      if (o.isTick) {
        if (tick == null || !_t(o.at)!.isBefore(_t(tick.at)!)) tick = o;
      } else {
        if (note == null || !_t(o.at)!.isBefore(_t(note.at)!)) note = o;
      }
    }
    if (tick != null) {
      final serverAt = _t(shot.doneAt);
      final mine = _t(tick.at);
      if (serverAt == null || mine == null || mine.isAfter(serverAt)) {
        out = out.copyWith(
          done: tick.done ?? out.done,
          doneAt: tick.at,
          doneBy: tick.done == true ? out.doneBy : null,
        );
      }
    }
    if (note != null) out = out.copyWith(note: note.note);
    shots.add(out);
  }
  return s.copyWith(shots: shots, nDone: shots.where((x) => x.done).length);
}

/// What On set needs, kept on the device: the shoots, and every tick and note
/// that has not reached the server yet. Opening a shoot (or the shoot list)
/// stores it; ticking and noting works with no connection; the changes go out
/// in order of their time when the connection returns.
class OnSetController extends Notifier<OnSetState> {
  static const _metaKey = 'onset:meta';
  static const _outboxKey = 'onset:outbox';
  static const _shootPrefix = 'onset:shoot:';

  Future<void>? _loading;
  Future<void>? _flush;

  KvStore get _kv => ref.read(studioKvStoreProvider);
  ShootsRepository get _repo => ref.read(shootsRepositoryProvider);
  void _report(bool online) =>
      ref.read(studioReachabilityProvider.notifier).report(online);

  @override
  OnSetState build() {
    ref.listen<bool>(studioReachabilityProvider, (prev, online) {
      if (online && state.outbox.isNotEmpty) unawaited(flush());
    });
    _loading = _load();
    return const OnSetState();
  }

  /// The stored data is in [state].
  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    final shoots = <String, StudioShoot>{};
    for (final k in await _kv.keys(_shootPrefix)) {
      final raw = await _kv.get(k);
      if (raw == null) continue;
      try {
        final s = StudioShoot.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
        shoots[s.id] = s;
      } catch (_) {
        await _kv.delete(k);
      }
    }
    var outbox = <OutboxItem>[];
    final rawBox = await _kv.get(_outboxKey);
    if (rawBox != null) {
      try {
        outbox = [
          for (final j in jsonDecode(rawBox) as List)
            OutboxItem.fromJson(Map<String, dynamic>.from(j as Map)),
        ];
      } catch (_) {}
    }
    String? serverTime;
    final rawMeta = await _kv.get(_metaKey);
    if (rawMeta != null) {
      try {
        serverTime = (jsonDecode(rawMeta) as Map)['server_time'] as String?;
      } catch (_) {}
    }
    state = state.copyWith(
      loaded: true,
      shoots: {...shoots, ...state.shoots},
      outbox: [...outbox, ...state.outbox],
      serverTime: serverTime,
    );
  }

  Future<void> _persistOutbox() => _kv.put(
    _outboxKey,
    jsonEncode([for (final o in state.outbox) o.toJson()]),
  );

  Future<void> _persistShoot(StudioShoot s) =>
      _kv.put('$_shootPrefix${s.id}', jsonEncode(s.toJson()));

  Future<void> _persistMeta() =>
      _kv.put(_metaKey, jsonEncode({'server_time': state.serverTime}));

  Future<void> _setServer(StudioShoot s) async {
    state = state.copyWith(shoots: {...state.shoots, s.id: s});
    await _persistShoot(s);
  }

  // ------------------------------------------------------------------ loading

  /// Reads one shoot from the server and stores it. With no connection the
  /// stored copy is returned; null when there is none and no connection (the
  /// error is thrown instead).
  Future<StudioShoot> openShoot(String id) async {
    await ensureLoaded();
    try {
      final s = await trackReachability(_report, () => _repo.get(id));
      await _setServer(s);
      if (state.outbox.isNotEmpty) unawaited(flush());
      return state.shoot(id)!;
    } on StudioNetworkError {
      final cached = state.shoot(id);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Downloads every shoot that changed since the last time (all of them the
  /// first time) so On set works with no connection. Quiet when offline.
  Future<void> syncAll() async {
    await ensureLoaded();
    try {
      String? after;
      String? first;
      final changed = <StudioShoot>[];
      final gone = <String>[];
      do {
        final page = await trackReachability(
          _report,
          () => _repo.sync(modifiedSince: state.serverTime, after: after),
        );
        first ??= page.serverTime;
        changed.addAll(page.items);
        gone.addAll(page.deleted);
        after = page.next;
      } while (after != null);
      final map = {...state.shoots};
      for (final id in gone) {
        map.remove(id);
        await _kv.delete('$_shootPrefix$id');
      }
      for (final s in changed) {
        map[s.id] = s;
        await _persistShoot(s);
      }
      state = state.copyWith(shoots: map, serverTime: first);
      await _persistMeta();
      if (state.outbox.isNotEmpty) unawaited(flush());
    } on StudioNetworkError {
      // Offline: what is stored stays.
    }
  }

  // ----------------------------------------------------------------- changes

  /// Ticks (or unticks) a shot. Always queued first, so closing the app can
  /// not lose it; then sent when there is a connection.
  Future<void> tick(String shotId, bool done) async {
    await ensureLoaded();
    final clock = ref.read(onSetClockProvider)();
    final item = OutboxItem(
      kind: 'tick',
      shotId: shotId,
      done: done,
      at: isoWithOffset(clock),
      requestId: newRequestId(),
    );
    state = state.copyWith(outbox: [...state.outbox, item]);
    await _persistOutbox();
    unawaited(flush());
  }

  /// Saves the whole note of a shot (it replaces the old one).
  /// With [send] false the note is only kept on the phone (while typing).
  Future<void> saveNote(String shotId, String note, {bool send = true}) async {
    await ensureLoaded();
    final clock = ref.read(onSetClockProvider)();
    final item = OutboxItem(
      kind: 'note',
      shotId: shotId,
      note: note,
      at: isoWithOffset(clock),
      requestId: newRequestId(),
    );
    state = state.copyWith(
      outbox: [
        for (final o in state.outbox)
          if (!(o.kind == 'note' && o.shotId == shotId)) o,
        item,
      ],
    );
    await _persistOutbox();
    if (send) unawaited(flush());
  }

  /// A prep list tick (needs the connection, like everything but On set).
  Future<void> tickPrep(String shootId, StudioTask task, bool done) async {
    await ensureLoaded();
    final before = state.shoots[shootId];
    if (before == null) return;
    StudioShoot with_(bool d) {
      final prep = [
        for (final p in before.prep)
          if (p.id == task.id) p.copyWith(done: d) else p,
      ];
      return before.copyWith(
        prep: prep,
        prepDone: prep.where((p) => p.done).length,
      );
    }

    state = state.copyWith(shoots: {...state.shoots, shootId: with_(done)});
    try {
      final r = await trackReachability(
        _report,
        () => _repo.prepTick(task.id, done: done, requestId: newRequestId()),
      );
      final cur = state.shoots[shootId] ?? before;
      final prep = [
        for (final p in cur.prep)
          if (p.id == r.id) r else p,
      ];
      await _setServer(
        cur.copyWith(prep: prep, prepDone: prep.where((p) => p.done).length),
      );
    } catch (_) {
      state = state.copyWith(shoots: {...state.shoots, shootId: before});
      rethrow;
    }
  }

  /// Saves an edit of the plan (lead, founder).
  Future<StudioShoot> update(String id, Map<String, dynamic> fields) async {
    final base = state.shoots[id]?.modified;
    final s = await trackReachability(
      _report,
      () => _repo.update(id, fields, baseModified: base),
    );
    await _setServer(s);
    return state.shoot(id)!;
  }

  /// Adds or edits a shot card; returns the fresh shoot.
  Future<StudioShoot> setShot(
    String shootId, {
    String? shotId,
    required String what,
    String? setup,
    String? ar,
    String? en,
  }) async {
    final api = ref.read(studioApiProvider);
    await trackReachability(
      _report,
      () => api.shootsShotSet(
        shootId: shootId,
        shotId: shotId,
        what: what,
        setup: setup,
        ar: ar,
        en: en,
        requestId: shotId == null ? newRequestId() : null,
      ),
    );
    return openShoot(shootId);
  }

  /// Puts a shoot the screen just created into the stored set.
  Future<void> remember(StudioShoot s) => _setServer(s);

  void clearNotices() =>
      state = state.copyWith(moved: const [], refused: const []);

  // ----------------------------------------------------------------- sending

  /// Sends every waiting change. Safe to call at any time and from anywhere;
  /// one send runs at a time, and what was added meanwhile follows.
  Future<void> flush() {
    return _flush ??= () async {
      try {
        await ensureLoaded();
        while (state.outbox.isNotEmpty &&
            ref.read(studioReachabilityProvider)) {
          state = state.copyWith(sending: true);
          final progressed = await _flushOnce();
          if (!progressed) break;
        }
      } finally {
        state = state.copyWith(sending: false);
        _flush = null;
      }
    }();
  }

  /// Returns true when something was sent and more may follow.
  Future<bool> _flushOnce() async {
    final snapshot = [...state.outbox];
    var progressed = false;

    // Ticks: the latest per shot, in the order they were made.
    final latest = <String, OutboxItem>{};
    for (final o in snapshot.where((o) => o.isTick)) {
      final cur = latest[o.shotId];
      if (cur == null || !_t(o.at)!.isBefore(_t(cur.at)!)) latest[o.shotId] = o;
    }
    if (latest.isNotEmpty) {
      final sorted = latest.values.toList()
        ..sort((a, b) => _t(a.at)!.compareTo(_t(b.at)!));
      try {
        final reply = await trackReachability(
          _report,
          () => _repo.shotTick([
            for (final o in sorted)
              {
                'shot_id': o.shotId,
                'done': o.done,
                'at': o.at,
                'request_id': o.requestId,
              },
          ]),
        );
        progressed = true;
        final sentIds = {
          for (final o in snapshot)
            if (o.isTick && latest.containsKey(o.shotId)) o.requestId,
        };
        final refused = <String>[];
        for (final r in reply.results) {
          if (!r.ok) refused.add(r.error?.message ?? r.shotId);
        }
        await _mergeShots(reply.shots);
        state = state.copyWith(
          outbox: [
            for (final o in state.outbox)
              if (!sentIds.contains(o.requestId)) o,
          ],
          everSent: true,
          clearBlocked: true,
          moved: [...state.moved, ...reply.piecesMoved],
          refused: [...state.refused, ...refused],
        );
        await _persistOutbox();
      } on StudioNetworkError {
        return false;
      } on StudioError catch (e) {
        state = state.copyWith(blockedMessage: e.message);
        return false;
      }
    }

    // Notes, oldest first.
    final notes = [
      for (final o in state.outbox)
        if (!o.isTick && snapshot.any((s) => s.requestId == o.requestId)) o,
    ]..sort((a, b) => _t(a.at)!.compareTo(_t(b.at)!));
    for (final n in notes) {
      try {
        final shot = _serverShot(n.shotId);
        ShootShot saved;
        var requestId = n.requestId;
        try {
          saved = await trackReachability(
            _report,
            () => _repo.shotNote(
              n.shotId,
              n.note ?? '',
              baseModified: shot?.modified,
              requestId: requestId,
            ),
          );
        } on StudioStale catch (e) {
          final cur = ShootShot.fromJson(
            Map<String, dynamic>.from(e.current as Map),
          );
          final merged = _mergeNote(cur.note, n.note ?? '');
          requestId = newRequestId();
          saved = await trackReachability(
            _report,
            () => _repo.shotNote(
              n.shotId,
              merged,
              baseModified: cur.modified,
              requestId: requestId,
            ),
          );
        }
        progressed = true;
        await _mergeShots([saved]);
        state = state.copyWith(
          outbox: [
            for (final o in state.outbox)
              if (o.requestId != n.requestId) o,
          ],
          everSent: true,
          clearBlocked: true,
        );
        await _persistOutbox();
      } on StudioNetworkError {
        return false;
      } on StudioError catch (e) {
        state = state.copyWith(blockedMessage: e.message);
        return false;
      }
    }
    return progressed;
  }

  ShootShot? _serverShot(String shotId) {
    for (final s in state.shoots.values) {
      for (final x in s.shots) {
        if (x.id == shotId) return x;
      }
    }
    return null;
  }

  String _mergeNote(String? current, String mine) {
    final c = (current ?? '').trim();
    if (c.isEmpty) return mine;
    if (c.contains(mine.trim())) return c;
    return '$c\n$mine';
  }

  Future<void> _mergeShots(List<ShootShot> fresh) async {
    final map = {...state.shoots};
    for (final shot in fresh) {
      final s = map[shot.shootId];
      if (s == null) continue;
      final shots = [
        for (final x in s.shots)
          if (x.id == shot.id) shot else x,
      ];
      map[s.id] = s.copyWith(
        shots: shots,
        nDone: shots.where((x) => x.done).length,
      );
    }
    state = state.copyWith(shoots: map);
    for (final shot in fresh) {
      final s = map[shot.shootId];
      if (s != null) await _persistShoot(s);
    }
  }
}

final onSetProvider = NotifierProvider<OnSetController, OnSetState>(
  OnSetController.new,
);

/// One shoot, fetched now (stored copy when offline). The screens also watch
/// [onSetProvider] to see waiting changes on top.
final shootDetailProvider = FutureProvider.autoDispose
    .family<StudioShoot, String>((ref, id) {
      return ref.read(onSetProvider.notifier).openShoot(id);
    });
