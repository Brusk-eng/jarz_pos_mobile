import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/offline/kv_store.dart';
import 'package:jarz_pos/src/studio/core/offline/reachability.dart';
import 'package:jarz_pos/src/studio/core/upload/picked_file.dart';
import 'package:jarz_pos/src/studio/core/upload/s3_client.dart';
import 'package:jarz_pos/src/studio/core/upload/upload_engine.dart';
import 'package:jarz_pos/src/studio/core/upload/upload_job.dart';
import 'package:jarz_pos/src/studio/data/studio_error.dart';

import 'upload_test_utils.dart';

void main() {
  tearDown(disposeContainers);

  late UploadTestApi api;
  late FakeS3 s3;
  late MemoryKvStore kv;
  late FakeFileSource files;

  setUp(() {
    api = UploadTestApi();
    s3 = FakeS3();
    kv = MemoryKvStore();
    files = FakeFileSource();
  });

  UploadEngine engineOf(ProviderContainer container) =>
      container.read(studioUploadEngineProvider.notifier);

  test(
    'a small file goes up in one PUT with exactly the given headers',
    () async {
      final c = uploadContainer(api: api, s3: s3, kv: kv);
      final e = engineOf(c);
      final r = await e.enqueue(
        MemoryPickedFile(name: 'a.jpg', bytes: bytesOf(1000)),
        purpose: 'asset',
      );
      expect(r.ok, isTrue);
      final job = await e.whenSettled(r.job!.id);
      expect(job.status, UploadStatus.done);
      expect(job.media!.id, 'MED-UPL-1');
      expect(s3.puts, ['https://s3.test/UPL-1/file']);
      expect(s3.headersSeen.values.single, {
        'Content-Type': 'image/jpeg',
        'x-amz-x': '1',
      });
      expect(s3.bodies.values.single.length, 1000);
      expect(api.completedParts.single, isNull);
    },
  );

  test(
    'a big file goes in parts, 3 at a time, etags collected in order',
    () async {
      api.partSize = 400;
      final c = uploadContainer(api: api, s3: s3, kv: kv);
      final e = engineOf(c);
      final r = await e.enqueue(
        MemoryPickedFile(
          name: 'v.mp4',
          mime: 'video/mp4',
          bytes: bytesOf(2000),
        ),
        purpose: 'version_file',
      );
      final job = await e.whenSettled(r.job!.id);
      expect(job.status, UploadStatus.done);
      expect(s3.puts.length, 5);
      expect(s3.maxInFlight, lessThanOrEqualTo(3));
      final parts = api.completedParts.single as List;
      expect([for (final p in parts) (p as Map)['part_no']], [1, 2, 3, 4, 5]);
      expect(parts.first['etag'], '"etag-part1"');
      // Each part carries its own slice of the file.
      expect(s3.bodies['https://s3.test/UPL-1/part2']![0], 400 % 251);
    },
  );

  test(
    'a failed part is retried alone and the upload still completes',
    () async {
      api.partSize = 400;
      s3.failures['part2'] = [
        const S3HttpException(500),
        const S3HttpException(503),
      ];
      final c = uploadContainer(api: api, s3: s3, kv: kv);
      final e = engineOf(c);
      final r = await e.enqueue(
        MemoryPickedFile(
          name: 'v.mp4',
          mime: 'video/mp4',
          bytes: bytesOf(1200),
        ),
        purpose: 'version_file',
      );
      final job = await e.whenSettled(r.job!.id);
      expect(job.status, UploadStatus.done);
      expect(s3.puts.where((u) => u.endsWith('part2')).length, 3);
      expect(s3.puts.where((u) => u.endsWith('part1')).length, 1);
    },
  );

  test('a part that keeps failing fails the file with a plain code', () async {
    s3.failAll = const S3HttpException(500);
    final c = uploadContainer(api: api, s3: s3, kv: kv);
    final e = engineOf(c);
    final r = await e.enqueue(
      MemoryPickedFile(name: 'a.jpg', bytes: bytesOf(100)),
      purpose: 'asset',
    );
    final job = await e.whenSettled(r.job!.id);
    expect(job.status, UploadStatus.failed);
    expect(job.errorCode, 'server');
    expect(s3.puts.length, 4);
    // "Try again" starts it over.
    s3.failAll = null;
    e.retry(job.id);
    final again = await e.whenSettled(job.id);
    expect(again.status, UploadStatus.done);
  });

  test(
    'cancel aborts the upload and clears it from the queue and storage',
    () async {
      api.partSize = 400;
      s3.gate = Completer<void>();
      final c = uploadContainer(api: api, s3: s3, kv: kv);
      final e = engineOf(c);
      final r = await e.enqueue(
        MemoryPickedFile(
          name: 'v.mp4',
          mime: 'video/mp4',
          bytes: bytesOf(1200),
        ),
        purpose: 'version_file',
      );
      await pumpEventQueue();
      expect(
        c.read(studioUploadEngineProvider).byId(r.job!.id)!.status,
        UploadStatus.uploading,
      );
      await e.cancel(r.job!.id);
      s3.gate!.complete();
      await pumpEventQueue();
      expect(api.aborted, ['UPL-1']);
      expect(c.read(studioUploadEngineProvider).jobs, isEmpty);
      expect(await kv.keys('upload:'), isEmpty);
      expect(api.completedParts, isEmpty);
    },
  );

  test(
    'after a restart the queue is rebuilt and only missing parts are sent',
    () async {
      api.partSize = 400;
      final file = MemoryPickedFile(
        name: 'v.mp4',
        mime: 'video/mp4',
        bytes: bytesOf(1200),
        path: '/phone/v.mp4',
        modifiedMs: 5,
      );
      files.byPath['/phone/v.mp4'] = file;
      // First run: part 1 goes, then the connection drops.
      s3.failures['part2'] = List<Object>.filled(
        10,
        const S3NetworkException(),
        growable: true,
      );
      s3.failures['part3'] = List<Object>.filled(
        10,
        const S3NetworkException(),
        growable: true,
      );
      final c1 = uploadContainer(api: api, s3: s3, kv: kv, files: files);
      final e1 = engineOf(c1);
      final r = await e1.enqueue(file, purpose: 'version_file');
      await pumpEventQueue(times: 200);
      final paused = c1.read(studioUploadEngineProvider).byId(r.job!.id)!;
      expect(paused.errorCode, isNull);
      expect(paused.status, UploadStatus.paused);
      expect(paused.parts.where((p) => p.etag != null).length, 1);
      expect(c1.read(studioReachabilityProvider), isFalse);

      // "Restart": new container, same storage.
      final s3b = FakeS3();
      final c2 = uploadContainer(api: api, s3: s3b, kv: kv, files: files);
      final e2 = engineOf(c2);
      await e2.restore();
      final job = await e2.whenSettled(r.job!.id);
      expect(job.status, UploadStatus.done);
      expect(api.beginCount, 1, reason: 'the stored upload is continued');
      expect(s3b.puts.where((u) => u.endsWith('part1')), isEmpty);
      expect(s3b.puts.length, 2);
      final parts = api.completedParts.single as List;
      expect(parts.length, 3);
      expect(parts.every((p) => (p as Map)['etag'] != null), isTrue);
    },
  );

  test(
    'lost connection pauses; the connection coming back continues',
    () async {
      s3.failAll = const S3NetworkException();
      final c = uploadContainer(api: api, s3: s3, kv: kv);
      final e = engineOf(c);
      final r = await e.enqueue(
        MemoryPickedFile(name: 'a.jpg', bytes: bytesOf(300)),
        purpose: 'asset',
      );
      await pumpEventQueue(times: 100);
      expect(
        c.read(studioUploadEngineProvider).byId(r.job!.id)!.status,
        UploadStatus.paused,
      );
      // Nothing starts while offline.
      final r2 = await e.enqueue(
        MemoryPickedFile(name: 'b.jpg', bytes: bytesOf(300)),
        purpose: 'asset',
      );
      await pumpEventQueue(times: 50);
      expect(
        c.read(studioUploadEngineProvider).byId(r2.job!.id)!.status,
        UploadStatus.queued,
      );
      s3.failAll = null;
      c.read(studioReachabilityProvider.notifier).report(true);
      final a = await e.whenSettled(r.job!.id);
      final b = await e.whenSettled(r2.job!.id);
      expect(a.status, UploadStatus.done);
      expect(b.status, UploadStatus.done);
    },
  );

  test('the same file is never queued twice', () async {
    s3.gate = Completer<void>();
    final c = uploadContainer(api: api, s3: s3, kv: kv);
    final e = engineOf(c);
    MemoryPickedFile mk() => MemoryPickedFile(
      name: 'a.jpg',
      bytes: bytesOf(300),
      path: '/p/a.jpg',
      modifiedMs: 9,
    );
    expect((await e.enqueue(mk(), purpose: 'asset')).ok, isTrue);
    final dup = await e.enqueue(mk(), purpose: 'asset');
    expect(dup.rejection, UploadRejection.duplicate);
    s3.gate!.complete();
    await pumpEventQueue();
    // Even after it finished.
    final dup2 = await e.enqueue(mk(), purpose: 'asset');
    expect(dup2.rejection, UploadRejection.duplicate);
    expect(c.read(studioUploadEngineProvider).jobs.length, 1);
  });

  test(
    'client checks: empty, wrong type, too big, story clip too long',
    () async {
      final c = uploadContainer(
        api: api,
        s3: s3,
        kv: kv,
        extra: [
          uploadLimitsProvider.overrideWithValue(
            const UploadLimits(maxBytes: 5000, storyClipMaxSeconds: 60),
          ),
        ],
      );
      final e = engineOf(c);
      Future<UploadRejection?> why(PickedFile f, [String p = 'asset']) async =>
          (await e.enqueue(f, purpose: p)).rejection;
      expect(
        await why(MemoryPickedFile(name: 'e.jpg', bytes: bytesOf(0))),
        UploadRejection.empty,
      );
      expect(
        await why(
          MemoryPickedFile(
            name: 'x.zip',
            mime: 'application/zip',
            bytes: bytesOf(10),
          ),
        ),
        UploadRejection.wrongType,
      );
      expect(
        await why(MemoryPickedFile(name: 'big.jpg', bytes: bytesOf(6000))),
        UploadRejection.tooBig,
      );
      expect(
        await why(
          MemoryPickedFile(
            name: 's.mp4',
            mime: 'video/mp4',
            bytes: bytesOf(10),
            duration: 75,
          ),
          'story_frame',
        ),
        UploadRejection.tooLong,
      );
      // The same clip is fine as a plain asset, and a 20 s story clip too.
      final ok = await e.enqueue(
        MemoryPickedFile(
          name: 's2.mp4',
          mime: 'video/mp4',
          bytes: bytesOf(10),
          duration: 20,
        ),
        purpose: 'story_frame',
      );
      expect(ok.ok, isTrue);
      await e.whenSettled(ok.job!.id);
    },
  );

  test(
    'on the web a restart needs the file again; picking it resumes the upload',
    () async {
      s3.failAll = const S3NetworkException();
      final c1 = uploadContainer(api: api, s3: s3, kv: kv);
      final e1 = engineOf(c1);
      MemoryPickedFile mk() => MemoryPickedFile(
        name: 'clip.mp4',
        mime: 'video/mp4',
        bytes: bytesOf(500),
        modifiedMs: 77,
      );
      final r = await e1.enqueue(mk(), purpose: 'asset');
      await pumpEventQueue(times: 100);

      final s3b = FakeS3();
      final c2 = uploadContainer(api: api, s3: s3b, kv: kv);
      final e2 = engineOf(c2);
      await e2.restore();
      var j = c2.read(studioUploadEngineProvider).byId(r.job!.id)!;
      expect(j.needsFile, isTrue);
      expect(j.status, UploadStatus.paused);
      final again = await e2.enqueue(mk(), purpose: 'asset');
      expect(again.reattached, isTrue);
      j = await e2.whenSettled(r.job!.id);
      expect(j.status, UploadStatus.done);
      expect(api.beginCount, 1);
    },
  );

  test('retrying the finish call reuses the stored request ids', () async {
    api.completeError = const StudioServerError('boom');
    final c = uploadContainer(api: api, s3: s3, kv: kv);
    final e = engineOf(c);
    final r = await e.enqueue(
      MemoryPickedFile(name: 'a.jpg', bytes: bytesOf(100)),
      purpose: 'asset',
    );
    var j = await e.whenSettled(r.job!.id);
    expect(j.status, UploadStatus.failed);
    api.completeError = null;
    e.retry(j.id);
    j = await e.whenSettled(j.id);
    expect(j.status, UploadStatus.done);
    expect(api.completeIds.single, j.completeRequestId);
    expect(api.beginIds.every((i) => i == j.beginRequestId), isTrue);
  });

  test(
    'a follow-up runs once the file is stored, and again after a restart if it was missed',
    () async {
      final c1 = uploadContainer(api: api, s3: s3, kv: kv);
      final e1 = engineOf(c1);
      final r = await e1.enqueue(
        MemoryPickedFile(name: 'a.jpg', bytes: bytesOf(100)),
        purpose: 'asset',
        meta: {'followUp': 'test', 'title': 'T'},
      );
      await e1.whenSettled(r.job!.id);
      await pumpEventQueue();
      expect(
        c1.read(studioUploadEngineProvider).byId(r.job!.id)!.followedUp,
        isFalse,
      );

      final c2 = uploadContainer(api: api, s3: s3, kv: kv);
      final e2 = engineOf(c2);
      await e2.restore();
      final seen = <String>[];
      e2.registerFollowUp(
        'test',
        (job, media) async => seen.add('${job.meta['title']}:${media.id}'),
      );
      await pumpEventQueue();
      expect(seen, ['T:MED-UPL-1']);
      expect(
        c2.read(studioUploadEngineProvider).byId(r.job!.id)!.followedUp,
        isTrue,
      );
    },
  );
}
