import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/studio_enums.dart';
import '../../data/models/studio_models.dart';
import '../network/studio_api.dart';
import '../offline/kv_store.dart';
import '../offline/reachability.dart';
import 'file_source.dart';
import 'picked_file.dart';
import 's3_client.dart';
import 'upload_job.dart';

/// Client-side limits. The contract fixes only the 16 MB single-PUT line and
/// the 8 MiB part size; the rest are the app's own guard rails.
class UploadLimits {
  const UploadLimits({
    this.maxBytes = 4 * 1024 * 1024 * 1024,
    this.storyClipMaxSeconds = 60,
    this.singleMaxBytes = 16 * 1024 * 1024,
  });
  final int maxBytes;
  final double storyClipMaxSeconds;
  final int singleMaxBytes;
}

/// Pause before attempt number [attempt] (1-based) of a part. Tests make it
/// zero.
final uploadRetryDelayProvider = Provider<Duration Function(int attempt)>(
  (ref) =>
      (attempt) => Duration(seconds: 1 << (attempt - 1)),
);

final uploadLimitsProvider = Provider<UploadLimits>(
  (ref) => const UploadLimits(),
);

/// What a screen wants done once its file is stored (for example create the
/// asset). Called with the finished media; may be called again after a
/// failure, so it must use a stable `request_id`.
typedef UploadFollowUp =
    Future<void> Function(UploadJob job, StudioMedia media);

class UploadQueueState {
  const UploadQueueState({this.jobs = const [], this.restored = false});
  final List<UploadJob> jobs;

  /// The stored queue has been read.
  final bool restored;

  List<UploadJob> get active => [
    for (final j in jobs)
      if (j.isActive) j,
  ];
  List<UploadJob> get failed => [
    for (final j in jobs)
      if (j.status == UploadStatus.failed) j,
  ];
  List<UploadJob> get done => [
    for (final j in jobs)
      if (j.status == UploadStatus.done) j,
  ];

  /// 0 to 1 across every file that is not finished plus the finished ones of
  /// the same batch (all jobs held).
  double get overall {
    final total = jobs.fold<int>(0, (a, j) => a + j.size);
    if (total == 0) return 0;
    final sent = jobs.fold<int>(
      0,
      (a, j) => a + (j.status == UploadStatus.done ? j.size : j.bytesSent),
    );
    return (sent / total).clamp(0, 1).toDouble();
  }

  UploadJob? byId(String id) {
    for (final j in jobs) {
      if (j.id == id) return j;
    }
    return null;
  }
}

class _Cancelled implements Exception {}

/// The one upload service every Studio screen uses.
///
/// Pick, check, `media.begin_upload`, PUT straight to S3 (one PUT up to 16 MB,
/// 8 MiB parts above with 3 in parallel and each part retried with backoff),
/// `media.complete_upload`. The queue is stored (see [KvStore]) and rebuilt
/// by [restore]; unfinished multipart uploads continue with the parts still
/// missing while their presigned links are valid.
class UploadEngine extends Notifier<UploadQueueState> {
  static const _prefix = 'upload:';
  static const _maxFilesAtOnce = 2;
  static const _partsAtOnce = 3;
  static const _attempts = 4;

  final _files = <String, PickedFile>{};
  final _cancels = <String, UploadCancel>{};
  final _running = <String>{};
  final _waiters = <String, List<Completer<UploadJob>>>{};
  final _followUps = <String, UploadFollowUp>{};
  final _followRunning = <String>{};
  Future<void>? _restoring;

  KvStore get _kv => ref.read(studioKvStoreProvider);
  StudioApi get _api => ref.read(studioApiProvider);
  S3Client get _s3 => ref.read(studioS3ClientProvider);
  Reachability get _reach => ref.read(studioReachabilityProvider.notifier);

  @override
  UploadQueueState build() {
    ref.listen<bool>(studioReachabilityProvider, (prev, online) {
      if (online) resumePaused();
    });
    return const UploadQueueState();
  }

  // ------------------------------------------------------------------ restore

  /// Reads the stored queue. Safe to call many times; screens call it when
  /// they open.
  Future<void> restore() => _restoring ??= _restore();

  Future<void> _restore() async {
    final jobs = <UploadJob>[];
    for (final k in await _kv.keys(_prefix)) {
      final raw = await _kv.get(k);
      if (raw == null) continue;
      try {
        var j = UploadJob.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
        if (j.status == UploadStatus.uploading) {
          j = j.copyWith(status: UploadStatus.queued);
        }
        jobs.add(j);
      } catch (_) {
        await _kv.delete(k);
      }
    }
    jobs.sort((a, b) => a.createdMs.compareTo(b.createdMs));
    state = UploadQueueState(jobs: jobs, restored: true);
    for (final j in jobs) {
      if (!j.isActive || _files.containsKey(j.id)) continue;
      PickedFile? f;
      if (j.path != null) {
        f = await ref.read(studioFileSourceProvider).fromPath(j.path!);
      }
      if (f != null) {
        _files[j.id] = f;
      } else {
        _put(
          j.copyWith(
            status: j.path == null ? UploadStatus.paused : UploadStatus.failed,
            needsFile: j.path == null,
            errorCode: j.path == null ? null : 'file_missing',
          ),
        );
      }
    }
    _runFollowUps();
    resumePaused();
  }

  // ------------------------------------------------------------------ enqueue

  /// Checks [file] and adds it to the queue.
  Future<EnqueueResult> enqueue(
    PickedFile file, {
    required String purpose,
    Map<String, dynamic> meta = const {},
  }) async {
    await restore();
    final limits = ref.read(uploadLimitsProvider);
    for (final j in state.jobs) {
      if (j.signature != file.signature) continue;
      if (j.needsFile) {
        _files[j.id] = file;
        _put(j.copyWith(needsFile: false, status: UploadStatus.queued));
        _pump();
        return EnqueueResult.accepted(state.byId(j.id)!, reattached: true);
      }
      if (j.status != UploadStatus.failed) {
        return const EnqueueResult.rejected(UploadRejection.duplicate);
      }
    }
    if (file.size <= 0) {
      return const EnqueueResult.rejected(UploadRejection.empty);
    }
    final isImage = file.mime.startsWith('image/');
    final isVideo = file.mime.startsWith('video/');
    final isPdf = file.mime == 'application/pdf';
    if (!(isImage || isVideo || isPdf)) {
      return const EnqueueResult.rejected(UploadRejection.wrongType);
    }
    if (file.size > limits.maxBytes) {
      return const EnqueueResult.rejected(UploadRejection.tooBig);
    }
    if (purpose == 'story_frame' && isVideo) {
      final d = await file.durationSeconds();
      if (d != null && d > limits.storyClipMaxSeconds) {
        return const EnqueueResult.rejected(UploadRejection.tooLong);
      }
    }
    // A failed twin is replaced by the new try.
    for (final j in [...state.jobs]) {
      if (j.signature == file.signature && j.status == UploadStatus.failed) {
        await _remove(j.id);
      }
    }
    final job = UploadJob(
      id: newRequestId(),
      signature: file.signature,
      name: file.name,
      size: file.size,
      modifiedMs: file.modifiedMs,
      mime: file.mime,
      purpose: purpose,
      path: file.path,
      beginRequestId: newRequestId(),
      completeRequestId: newRequestId(),
      createdMs: DateTime.now().microsecondsSinceEpoch,
      meta: meta,
    );
    _files[job.id] = file;
    _put(job, add: true);
    _pump();
    return EnqueueResult.accepted(job);
  }

  /// Completes when the job is done (or failed for good, or cancelled).
  Future<UploadJob> whenSettled(String id) {
    final j = state.byId(id);
    if (j != null &&
        (j.status == UploadStatus.done || j.status == UploadStatus.failed)) {
      return Future.value(j);
    }
    final c = Completer<UploadJob>();
    (_waiters[id] ??= []).add(c);
    return c.future;
  }

  // ------------------------------------------------------------ user controls

  /// Stops a file for good; frees its S3 parts.
  Future<void> cancel(String id) async {
    final j = state.byId(id);
    if (j == null) return;
    _cancels[id]?.cancel();
    await _remove(id);
    final uploadId = j.uploadId;
    if (uploadId != null && j.status != UploadStatus.done) {
      await _abortQuiet(uploadId);
    }
    _settle(j.copyWith(status: UploadStatus.failed));
    _pump();
  }

  Future<void> _abortQuiet(String uploadId) async {
    try {
      await _api.mediaAbortUpload(uploadId: uploadId);
    } catch (_) {
      // The links die on their own; nothing to show.
    }
  }

  /// Tries a failed file again.
  void retry(String id) {
    final j = state.byId(id);
    if (j == null || j.status != UploadStatus.failed) return;
    _put(j.copyWith(status: UploadStatus.queued, clearError: true));
    _pump();
  }

  /// Takes finished files off the tray.
  Future<void> clearFinished() async {
    for (final j in [...state.jobs]) {
      if (j.status == UploadStatus.done && (j.followedUp || !_hasFollowUp(j))) {
        await _remove(j.id);
      }
    }
  }

  /// A file the web asked to pick again (same name, size and date).
  void resumePaused() {
    for (final j in state.jobs) {
      if (j.status == UploadStatus.paused && !j.needsFile) {
        _put(j.copyWith(status: UploadStatus.queued));
      }
    }
    _pump();
  }

  // ---------------------------------------------------------------- follow-up

  /// A screen says what to do with finished files of kind [key]. Anything
  /// finished earlier but not yet followed up runs now.
  void registerFollowUp(String key, UploadFollowUp handler) {
    _followUps[key] = handler;
    _runFollowUps();
  }

  bool _hasFollowUp(UploadJob j) => j.meta['followUp'] != null;

  void _runFollowUps() {
    for (final j in state.jobs) {
      final key = j.meta['followUp'] as String?;
      if (key == null ||
          j.status != UploadStatus.done ||
          j.followedUp ||
          j.media == null ||
          !_followUps.containsKey(key) ||
          _followRunning.contains(j.id)) {
        continue;
      }
      _followRunning.add(j.id);
      () async {
        try {
          await _followUps[key]!(j, j.media!);
          final cur = state.byId(j.id);
          if (cur != null) {
            _put(cur.copyWith(followedUp: true, clearFollowUpError: true));
          }
        } on StudioError catch (e) {
          final cur = state.byId(j.id);
          if (cur != null) {
            _put(cur.copyWith(followUpError: e.message));
          }
        } catch (e) {
          final cur = state.byId(j.id);
          if (cur != null) _put(cur.copyWith(followUpError: '$e'));
        } finally {
          _followRunning.remove(j.id);
        }
      }();
    }
  }

  /// Runs the follow-up of a file again after it failed.
  void retryFollowUp(String id) {
    final j = state.byId(id);
    if (j == null) return;
    _put(j.copyWith(clearFollowUpError: true));
    _runFollowUps();
  }

  // -------------------------------------------------------------------- state

  void _put(UploadJob job, {bool add = false}) {
    final jobs = [...state.jobs];
    final i = jobs.indexWhere((j) => j.id == job.id);
    if (i >= 0) {
      jobs[i] = job;
    } else if (add) {
      jobs.add(job);
    } else {
      return; // removed meanwhile
    }
    state = UploadQueueState(jobs: jobs, restored: state.restored);
    // Persist (progress ticks are cheap; parts and statuses matter).
    _kv.put('$_prefix${job.id}', jsonEncode(job.toJson()));
  }

  Future<void> _remove(String id) async {
    state = UploadQueueState(
      jobs: [
        for (final j in state.jobs)
          if (j.id != id) j,
      ],
      restored: state.restored,
    );
    _files.remove(id);
    _cancels.remove(id);
    await _kv.delete('$_prefix$id');
  }

  void _settle(UploadJob j) {
    final ws = _waiters.remove(j.id);
    if (ws == null) return;
    for (final c in ws) {
      if (!c.isCompleted) c.complete(j);
    }
  }

  // --------------------------------------------------------------------- pump

  void _pump() {
    if (!ref.read(studioReachabilityProvider)) return;
    for (final j in state.jobs) {
      if (_running.length >= _maxFilesAtOnce) break;
      if (j.status == UploadStatus.queued &&
          !j.needsFile &&
          !_running.contains(j.id)) {
        _running.add(j.id);
        _run(j.id).whenComplete(() {
          _running.remove(j.id);
          _pump();
        });
      }
    }
  }

  Future<void> _run(String id) async {
    final cancel = _cancels[id] = UploadCancel();
    void check() {
      if (cancel.isCancelled || state.byId(id) == null) throw _Cancelled();
    }

    try {
      var job = state.byId(id)!;
      var file = _files[id];
      if (file == null) {
        _put(job.copyWith(status: UploadStatus.paused, needsFile: true));
        return;
      }
      _put(job.copyWith(status: UploadStatus.uploading, clearError: true));
      job = state.byId(id)!;

      // 1. Begin (or keep the stored upload while its links are valid).
      if (job.uploadId != null && _expired(job)) {
        final old = job.uploadId!;
        job = job.copyWith(clearUpload: true, bytesSent: 0);
        _put(job);
        unawaited(_abortQuiet(old));
      }
      if (job.uploadId == null) {
        final b = await _apiCall(
          () => _api.mediaBeginUpload(
            filename: job.name,
            contentType: job.mime,
            bytes: job.size,
            purpose: job.purpose,
            requestId: job.beginRequestId,
          ),
        );
        check();
        final multi = b.mode == UploadMode.multipart;
        job = job.copyWith(
          uploadId: b.uploadId,
          multipart: multi,
          partSize: b.partSize,
          expiresAt: b.expiresAt,
          putUrl: b.put?.url,
          putHeaders: b.put?.headers,
          parts: [
            for (final p in b.parts)
              UploadPartState(no: p.partNo, url: p.url, size: p.size),
          ],
          bytesSent: 0,
        );
        _put(job);
      }

      // 2. Send the bytes.
      List<Map<String, dynamic>>? partsForComplete;
      if (!job.multipart) {
        final bytes = await file.readRange(0, job.size);
        check();
        await _putRetry(
          id,
          job.putUrl!,
          job.putHeaders,
          () async => bytes,
          cancel,
          onSent: (s) => _progress(id, {1: s}),
        );
        _put(state.byId(id)!.copyWith(bytesSent: job.size));
      } else {
        await _sendParts(id, file, cancel);
        final done = state.byId(id)!;
        partsForComplete = [
          for (final p in done.parts) {'part_no': p.no, 'etag': p.etag},
        ];
      }
      check();

      // 3. Complete.
      job = state.byId(id)!;
      StudioMedia media;
      try {
        media = await _apiCall(
          () => _api.mediaCompleteUpload(
            uploadId: job.uploadId!,
            parts: partsForComplete,
            requestId: job.completeRequestId,
          ),
        );
      } on StudioAlreadyDone catch (e) {
        media = StudioMedia.fromJson(
          Map<String, dynamic>.from(e.current as Map),
        );
      }
      final fin = state
          .byId(id)!
          .copyWith(
            status: UploadStatus.done,
            media: media,
            bytesSent: job.size,
            clearError: true,
          );
      _put(fin);
      _settle(fin);
      _runFollowUps();
    } on _Cancelled {
      // Gone from the queue already.
    } on S3NetworkException {
      _reach.report(false);
      _pauseOnNetwork(id);
    } on StudioNetworkError {
      _reach.report(false);
      _pauseOnNetwork(id);
    } on S3HttpException catch (e) {
      _fail(id, e.expired ? 'expired' : 'server');
    } on StudioNotFound {
      // The server forgot the upload: start it over, a few times at most.
      final j = state.byId(id);
      if (j != null && j.restarts < 2) {
        _put(
          j.copyWith(
            clearUpload: true,
            bytesSent: 0,
            restarts: j.restarts + 1,
            status: UploadStatus.queued,
          ),
        );
      } else {
        _fail(id, 'server');
      }
    } on StudioShadowMode catch (e) {
      _fail(id, 'shadow', e.message);
    } on StudioValidation catch (e) {
      _fail(id, 'validation', e.message);
    } on StudioNotPermitted catch (e) {
      _fail(id, 'permission', e.message);
    } on StudioError catch (e) {
      _fail(id, 'server', e.message);
    } catch (e) {
      _fail(id, 'unknown', '$e');
    } finally {
      _cancels.remove(id);
    }
  }

  void _pauseOnNetwork(String id) {
    final j = state.byId(id);
    if (j != null && j.status != UploadStatus.done) {
      _put(j.copyWith(status: UploadStatus.paused));
    }
  }

  void _fail(String id, String code, [String? message]) {
    final j = state.byId(id);
    if (j == null) return;
    final f = j.copyWith(
      status: UploadStatus.failed,
      errorCode: code,
      errorMessage: message,
    );
    _put(f);
    _settle(f);
  }

  bool _expired(UploadJob j) {
    final e = j.expiresAt == null ? null : DateTime.tryParse(j.expiresAt!);
    return e != null &&
        DateTime.now().isAfter(e.subtract(const Duration(minutes: 1)));
  }

  /// A Studio call with one retry after `RATE_LIMITED` (same `request_id`).
  Future<T> _apiCall<T>(Future<T> Function() body) async {
    try {
      return await trackReachability(_reach.report, body);
    } on StudioRateLimited {
      await Future<void>.delayed(ref.read(uploadRetryDelayProvider)(2));
      return trackReachability(_reach.report, body);
    }
  }

  // -------------------------------------------------------------------- parts

  final _inflight = <String, Map<int, int>>{};

  void _progress(String id, Map<int, int> partial) {
    final j = state.byId(id);
    if (j == null) return;
    final m = _inflight[id] ??= {};
    m.addAll(partial);
    final base = j.multipart
        ? j.parts
              .where((p) => p.etag != null)
              .fold<int>(0, (a, p) => a + p.size)
        : 0;
    final inflight = j.multipart
        ? m.entries
              .where((e) => j.parts.any((p) => p.no == e.key && p.etag == null))
              .fold<int>(0, (a, e) => a + e.value)
        : (m[1] ?? 0);
    final sent = (base + inflight).clamp(0, j.size);
    if (sent != j.bytesSent) _put(j.copyWith(bytesSent: sent));
  }

  Future<void> _sendParts(
    String id,
    PickedFile file,
    UploadCancel cancel,
  ) async {
    final job = state.byId(id)!;
    final size = job.partSize ?? 8 * 1024 * 1024;
    final todo = [
      for (final p in job.parts)
        if (p.etag == null) p,
    ];
    _inflight[id] = {};
    var next = 0;
    Object? failure;

    Future<void> worker() async {
      while (failure == null) {
        if (cancel.isCancelled) return;
        if (next >= todo.length) return;
        final p = todo[next++];
        try {
          final start = (p.no - 1) * size;
          final end = (start + p.size).clamp(0, file.size);
          final etag = await _putRetry(
            id,
            p.url,
            const {},
            () => file.readRange(start, end),
            cancel,
            onSent: (s) => _progress(id, {p.no: s}),
          );
          final cur = state.byId(id);
          if (cur == null) return;
          _inflight[id]?.remove(p.no);
          _put(
            cur.copyWith(
              parts: [
                for (final q in cur.parts)
                  if (q.no == p.no) q.withEtag(etag ?? '') else q,
              ],
            ),
          );
          _progress(id, const {});
        } catch (e) {
          failure ??= e;
          return;
        }
      }
    }

    await Future.wait([for (var i = 0; i < _partsAtOnce; i++) worker()]);
    if (cancel.isCancelled || state.byId(id) == null) throw _Cancelled();
    if (failure != null) throw failure!;
  }

  /// One PUT with up to [_attempts] tries and backoff. A 403 (expired link)
  /// is not retried.
  Future<String?> _putRetry(
    String id,
    String url,
    Map<String, String> headers,
    Future<Uint8List> Function() bytes,
    UploadCancel cancel, {
    required void Function(int sent) onSent,
  }) async {
    for (var attempt = 1; ; attempt++) {
      if (cancel.isCancelled) throw _Cancelled();
      try {
        final data = await bytes();
        return await _s3.put(
          url,
          headers,
          data,
          onProgress: onSent,
          cancel: cancel,
        );
      } on S3HttpException catch (e) {
        if (e.expired || attempt >= _attempts) rethrow;
      } on S3NetworkException {
        if (cancel.isCancelled) throw _Cancelled();
        if (attempt >= _attempts) rethrow;
      }
      await Future<void>.delayed(ref.read(uploadRetryDelayProvider)(attempt));
    }
  }
}

final studioUploadEngineProvider =
    NotifierProvider<UploadEngine, UploadQueueState>(UploadEngine.new);
