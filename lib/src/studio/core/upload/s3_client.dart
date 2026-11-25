import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Set by the engine when the person cancels, so a running PUT stops.
class UploadCancel {
  bool _cancelled = false;
  final _listeners = <void Function()>[];
  bool get isCancelled => _cancelled;
  void onCancel(void Function() f) => _listeners.add(f);
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final l in _listeners) {
      l();
    }
  }
}

/// No answer from S3 (offline, timeout, DNS).
class S3NetworkException implements Exception {
  const S3NetworkException([this.message = 'network']);
  final String message;
  @override
  String toString() => 'S3NetworkException($message)';
}

/// S3 answered with a failure status.
class S3HttpException implements Exception {
  const S3HttpException(this.status);
  final int status;

  /// 403 on a presigned URL means it expired.
  bool get expired => status == 403;
  @override
  String toString() => 'S3HttpException($status)';
}

/// The one door to S3. The bytes never go through the Studio API.
abstract class S3Client {
  /// PUTs [bytes] to the presigned [url] with exactly [headers]; returns the
  /// `ETag` response header (null if S3 sent none). [onProgress] reports bytes
  /// of this request sent so far.
  Future<String?> put(
    String url,
    Map<String, String> headers,
    Uint8List bytes, {
    void Function(int sent)? onProgress,
    UploadCancel? cancel,
  });
}

/// Dio without the Studio's cookies or base URL: S3 must never see a session.
class DioS3Client implements S3Client {
  DioS3Client([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(minutes: 5),
              receiveTimeout: const Duration(seconds: 60),
            ),
          );
  final Dio _dio;

  @override
  Future<String?> put(
    String url,
    Map<String, String> headers,
    Uint8List bytes, {
    void Function(int sent)? onProgress,
    UploadCancel? cancel,
  }) async {
    final token = CancelToken();
    cancel?.onCancel(() => token.cancel());
    try {
      final r = await _dio.put<void>(
        url,
        data: bytes,
        cancelToken: token,
        options: Options(headers: headers, validateStatus: (_) => true),
        onSendProgress: (sent, _) => onProgress?.call(sent),
      );
      final s = r.statusCode ?? 0;
      if (s < 200 || s >= 300) throw S3HttpException(s);
      return r.headers.value('etag');
    } on DioException catch (e) {
      throw S3NetworkException('${e.type}');
    }
  }
}

final studioS3ClientProvider = Provider<S3Client>((ref) => DioS3Client());
