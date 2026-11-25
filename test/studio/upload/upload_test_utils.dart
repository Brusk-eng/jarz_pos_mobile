import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/core/offline/kv_store.dart';
import 'package:jarz_pos/src/studio/core/offline/reachability.dart';
import 'package:jarz_pos/src/studio/core/upload/file_source.dart';
import 'package:jarz_pos/src/studio/core/upload/picked_file.dart';
import 'package:jarz_pos/src/studio/core/upload/s3_client.dart';
import 'package:jarz_pos/src/studio/core/upload/upload_engine.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/models/studio_enums.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';

/// Studio API whose media calls are scripted by the test.
class UploadTestApi extends FakeStudioApi {
  UploadTestApi({this.partSize = 0}) : super(delay: Duration.zero);

  /// 0: single PUT; otherwise multipart with parts of this many bytes.
  int partSize;
  bool offline = false;
  Object? completeError;
  int beginCount = 0;
  final aborted = <String>[];
  final beginIds = <String?>[];
  final completeIds = <String?>[];
  final completedParts = <Object?>[];

  @override
  Future<UploadBegin> mediaBeginUpload({
    required String filename,
    required String contentType,
    required int bytes,
    required String purpose,
    String? sha256,
    String? requestId,
  }) async {
    if (offline) throw const StudioNetworkError('No connection.');
    beginCount++;
    beginIds.add(requestId);
    final id = 'UPL-$beginCount';
    if (partSize == 0) {
      return UploadBegin(
        uploadId: id,
        mode: UploadMode.single,
        mediaKind: contentType.startsWith('video')
            ? MediaKind.video
            : MediaKind.image,
        expiresAt: '2999-01-01T00:00:00+02:00',
        put: UploadPut(
          method: 'PUT',
          url: 'https://s3.test/$id/file',
          headers: const {'Content-Type': 'image/jpeg', 'x-amz-x': '1'},
        ),
        parts: const [],
      );
    }
    final n = (bytes / partSize).ceil();
    return UploadBegin(
      uploadId: id,
      mode: UploadMode.multipart,
      mediaKind: MediaKind.video,
      expiresAt: '2999-01-01T00:00:00+02:00',
      partSize: partSize,
      parts: [
        for (var i = 1; i <= n; i++)
          UploadPart(
            partNo: i,
            url: 'https://s3.test/$id/part$i',
            size: i < n ? partSize : bytes - partSize * (n - 1),
          ),
      ],
    );
  }

  @override
  Future<StudioMedia> mediaCompleteUpload({
    required String uploadId,
    Object? parts,
    String? sha256,
    String? requestId,
  }) async {
    if (offline) throw const StudioNetworkError('No connection.');
    if (completeError != null) throw completeError!;
    completeIds.add(requestId);
    completedParts.add(parts);
    return StudioMedia(
      id: 'MED-$uploadId',
      kind: MediaKind.image,
      url: 'https://cdn.test/$uploadId.jpg',
    );
  }

  @override
  Future<OkResult> mediaAbortUpload({required String uploadId}) async {
    aborted.add(uploadId);
    return const OkResult(ok: true);
  }
}

/// S3 stand-in: records every PUT, can fail on demand, can hold PUTs.
class FakeS3 implements S3Client {
  final puts = <String>[];
  final headersSeen = <String, Map<String, String>>{};
  final bodies = <String, Uint8List>{};

  /// url suffix -> failures still to throw.
  final failures = <String, List<Object>>{};

  /// Every PUT throws this while set.
  Object? failAll;
  int inFlight = 0;
  int maxInFlight = 0;

  /// When set, a PUT waits for it.
  Completer<void>? gate;

  @override
  Future<String?> put(
    String url,
    Map<String, String> headers,
    Uint8List bytes, {
    void Function(int sent)? onProgress,
    UploadCancel? cancel,
  }) async {
    puts.add(url);
    headersSeen[url] = headers;
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    try {
      if (gate != null) await gate!.future;
      if (failAll != null) throw failAll!;
      for (final e in failures.entries) {
        if (url.endsWith(e.key) && e.value.isNotEmpty) {
          throw e.value.removeAt(0);
        }
      }
      onProgress?.call(bytes.length);
      bodies[url] = bytes;
      return '"etag-${url.split('/').last}"';
    } finally {
      inFlight--;
    }
  }
}

/// Hands back files by path, like the phone's storage does.
class FakeFileSource implements StudioFileSource {
  final byPath = <String, PickedFile>{};
  @override
  Future<PickedFile?> fromPath(String path) async => byPath[path];
  @override
  Future<List<PickedFile>> pickFiles({bool multiple = true}) async => [];
  @override
  Future<List<PickedFile>> pickMedia({bool multiple = true}) async => [];
}

Uint8List bytesOf(int n) =>
    Uint8List.fromList(List.generate(n, (i) => i % 251));

/// A container the way the app is wired, with every outside door replaced.
ProviderContainer uploadContainer({
  required UploadTestApi api,
  required FakeS3 s3,
  required KvStore kv,
  FakeFileSource? files,
  List<Override> extra = const [],
}) {
  final c = ProviderContainer(
    overrides: [
      studioApiProvider.overrideWithValue(api),
      studioS3ClientProvider.overrideWithValue(s3),
      studioKvStoreProvider.overrideWithValue(kv),
      studioFileSourceProvider.overrideWithValue(files ?? FakeFileSource()),
      uploadRetryDelayProvider.overrideWithValue((_) => Duration.zero),
      reachabilityIntervalProvider.overrideWithValue(null),
      reachabilityProbeProvider.overrideWithValue(() async => true),
      ...extra,
    ],
  );
  addTearDownContainer(c);
  return c;
}

final _toDispose = <ProviderContainer>[];
void addTearDownContainer(ProviderContainer c) => _toDispose.add(c);
void disposeContainers() {
  for (final c in _toDispose) {
    c.dispose();
  }
  _toDispose.clear();
}
