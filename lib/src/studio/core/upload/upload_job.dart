import '../../data/models/studio_models.dart';

enum UploadStatus {
  /// Waiting for its turn (or for the connection).
  queued,
  uploading,

  /// The connection was lost, or on the web the file must be picked again.
  paused,
  failed,
  done,
}

/// One part of a multipart upload.
class UploadPartState {
  const UploadPartState({
    required this.no,
    required this.url,
    required this.size,
    this.etag,
  });

  final int no;
  final String url;
  final int size;

  /// The `ETag` S3 answered with; null until the part is stored.
  final String? etag;

  UploadPartState withEtag(String? e) =>
      UploadPartState(no: no, url: url, size: size, etag: e);

  Map<String, dynamic> toJson() => {
    'no': no,
    'url': url,
    'size': size,
    'etag': etag,
  };

  factory UploadPartState.fromJson(Map<String, dynamic> j) => UploadPartState(
    no: j['no'] as int,
    url: j['url'] as String,
    size: j['size'] as int,
    etag: j['etag'] as String?,
  );
}

/// One file in the upload queue. Immutable; the engine replaces it on change.
/// Everything here survives an app restart (see `UploadEngine.restore`).
class UploadJob {
  const UploadJob({
    required this.id,
    required this.signature,
    required this.name,
    required this.size,
    required this.modifiedMs,
    required this.mime,
    required this.purpose,
    required this.beginRequestId,
    required this.completeRequestId,
    required this.createdMs,
    this.path,
    this.status = UploadStatus.queued,
    this.bytesSent = 0,
    this.uploadId,
    this.multipart = false,
    this.partSize,
    this.expiresAt,
    this.putUrl,
    this.putHeaders = const {},
    this.parts = const [],
    this.media,
    this.errorCode,
    this.errorMessage,
    this.needsFile = false,
    this.meta = const {},
    this.followedUp = false,
    this.followUpError,
    this.restarts = 0,
  });

  final String id;
  final String signature;
  final String name;
  final int size;
  final int modifiedMs;
  final String mime;

  /// version_file, story_frame, asset, consent_proof or reference_image.
  final String purpose;
  final String beginRequestId;
  final String completeRequestId;
  final int createdMs;
  final String? path;
  final UploadStatus status;
  final int bytesSent;
  final String? uploadId;
  final bool multipart;
  final int? partSize;
  final String? expiresAt;
  final String? putUrl;
  final Map<String, String> putHeaders;
  final List<UploadPartState> parts;

  /// The finished media (once done).
  final StudioMedia? media;

  /// `shadow`, `validation`, `permission`, `server`, `expired`,
  /// `file_missing`, `unknown`; null while all is well.
  final String? errorCode;
  final String? errorMessage;

  /// The file must be picked again (the web cannot keep a file across a
  /// reload).
  final bool needsFile;

  /// What the screen that started the upload wants done afterwards (stored so
  /// it survives a restart). Key `followUp` names the handler.
  final Map<String, dynamic> meta;
  final bool followedUp;
  final String? followUpError;

  /// How many times the server forgot the upload and it was started over.
  final int restarts;

  bool get isActive =>
      status == UploadStatus.queued ||
      status == UploadStatus.uploading ||
      status == UploadStatus.paused;

  double get progress => status == UploadStatus.done
      ? 1
      : size == 0
      ? 0
      : (bytesSent / size).clamp(0, 1).toDouble();

  UploadJob copyWith({
    UploadStatus? status,
    int? bytesSent,
    String? uploadId,
    bool clearUpload = false,
    bool? multipart,
    int? partSize,
    String? expiresAt,
    String? putUrl,
    Map<String, String>? putHeaders,
    List<UploadPartState>? parts,
    StudioMedia? media,
    String? errorCode,
    String? errorMessage,
    bool clearError = false,
    bool? needsFile,
    bool? followedUp,
    String? followUpError,
    bool clearFollowUpError = false,
    int? restarts,
    String? path,
  }) => UploadJob(
    id: id,
    signature: signature,
    name: name,
    size: size,
    modifiedMs: modifiedMs,
    mime: mime,
    purpose: purpose,
    beginRequestId: beginRequestId,
    completeRequestId: completeRequestId,
    createdMs: createdMs,
    path: path ?? this.path,
    status: status ?? this.status,
    bytesSent: bytesSent ?? this.bytesSent,
    uploadId: clearUpload ? null : (uploadId ?? this.uploadId),
    multipart: multipart ?? this.multipart,
    partSize: clearUpload ? null : (partSize ?? this.partSize),
    expiresAt: clearUpload ? null : (expiresAt ?? this.expiresAt),
    putUrl: clearUpload ? null : (putUrl ?? this.putUrl),
    putHeaders: clearUpload ? const {} : (putHeaders ?? this.putHeaders),
    parts: clearUpload ? const [] : (parts ?? this.parts),
    media: media ?? this.media,
    errorCode: clearError ? null : (errorCode ?? this.errorCode),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    needsFile: needsFile ?? this.needsFile,
    meta: meta,
    followedUp: followedUp ?? this.followedUp,
    followUpError: clearFollowUpError
        ? null
        : (followUpError ?? this.followUpError),
    restarts: restarts ?? this.restarts,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'signature': signature,
    'name': name,
    'size': size,
    'modified_ms': modifiedMs,
    'mime': mime,
    'purpose': purpose,
    'begin_request_id': beginRequestId,
    'complete_request_id': completeRequestId,
    'created_ms': createdMs,
    'path': path,
    'status': status.name,
    'bytes_sent': bytesSent,
    'upload_id': uploadId,
    'multipart': multipart,
    'part_size': partSize,
    'expires_at': expiresAt,
    'put_url': putUrl,
    'put_headers': putHeaders,
    'parts': [for (final p in parts) p.toJson()],
    'media': media?.toJson(),
    'error_code': errorCode,
    'error_message': errorMessage,
    'needs_file': needsFile,
    'meta': meta,
    'followed_up': followedUp,
    'follow_up_error': followUpError,
    'restarts': restarts,
  };

  factory UploadJob.fromJson(Map<String, dynamic> j) => UploadJob(
    id: j['id'] as String,
    signature: j['signature'] as String,
    name: j['name'] as String,
    size: j['size'] as int,
    modifiedMs: j['modified_ms'] as int,
    mime: j['mime'] as String,
    purpose: j['purpose'] as String,
    beginRequestId: j['begin_request_id'] as String,
    completeRequestId: j['complete_request_id'] as String,
    createdMs: j['created_ms'] as int,
    path: j['path'] as String?,
    status: UploadStatus.values.firstWhere(
      (s) => s.name == j['status'],
      orElse: () => UploadStatus.queued,
    ),
    bytesSent: j['bytes_sent'] as int? ?? 0,
    uploadId: j['upload_id'] as String?,
    multipart: j['multipart'] as bool? ?? false,
    partSize: j['part_size'] as int?,
    expiresAt: j['expires_at'] as String?,
    putUrl: j['put_url'] as String?,
    putHeaders: {
      for (final e in (j['put_headers'] as Map? ?? const {}).entries)
        '${e.key}': '${e.value}',
    },
    parts: [
      for (final p in (j['parts'] as List? ?? const []))
        UploadPartState.fromJson(Map<String, dynamic>.from(p as Map)),
    ],
    media: j['media'] == null
        ? null
        : StudioMedia.fromJson(Map<String, dynamic>.from(j['media'] as Map)),
    errorCode: j['error_code'] as String?,
    errorMessage: j['error_message'] as String?,
    needsFile: j['needs_file'] as bool? ?? false,
    meta: Map<String, dynamic>.from(j['meta'] as Map? ?? const {}),
    followedUp: j['followed_up'] as bool? ?? false,
    followUpError: j['follow_up_error'] as String?,
    restarts: j['restarts'] as int? ?? 0,
  );
}

/// Why the engine refused a file before queueing it.
enum UploadRejection { empty, wrongType, tooBig, tooLong, duplicate }

class EnqueueResult {
  const EnqueueResult.accepted(this.job, {this.reattached = false})
    : rejection = null;
  const EnqueueResult.rejected(this.rejection) : job = null, reattached = false;

  final UploadJob? job;
  final UploadRejection? rejection;

  /// The web picked the same file again and the paused upload took it up.
  final bool reattached;
  bool get ok => job != null;
}
