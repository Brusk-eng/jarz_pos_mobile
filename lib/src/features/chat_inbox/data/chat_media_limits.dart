// Size caps and kinds for staff-sent media (`send_media`, contract §1).
// The server enforces the same numbers (and may lower them per channel); the
// app checks first so a too-big file fails before it is uploaded.

enum ChatMediaKind { image, video, audio, document }

const int chatImageMaxBytes = 5 * 1024 * 1024;
const int chatVideoMaxBytes = 16 * 1024 * 1024;
const int chatAudioMaxBytes = 16 * 1024 * 1024;
const int chatDocumentMaxBytes = 25 * 1024 * 1024;

/// The kind the server will treat a file of [mime] / [fileName] as.
ChatMediaKind chatMediaKindOf(String? mime, String? fileName) {
  final m = (mime ?? '').split(';').first.trim().toLowerCase();
  if (m.startsWith('image/')) return ChatMediaKind.image;
  if (m.startsWith('video/')) return ChatMediaKind.video;
  if (m.startsWith('audio/')) return ChatMediaKind.audio;
  if (m.isEmpty || m == 'application/octet-stream') {
    final dot = (fileName ?? '').lastIndexOf('.');
    final ext = dot < 0 ? '' : fileName!.substring(dot + 1).toLowerCase();
    if (const {'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'}.contains(ext)) {
      return ChatMediaKind.image;
    }
    if (const {'mp4', 'mov', '3gp', 'm4v'}.contains(ext)) {
      return ChatMediaKind.video;
    }
    if (const {'mp3', 'ogg', 'opus', 'm4a', 'aac', 'amr', 'wav'}
        .contains(ext)) {
      return ChatMediaKind.audio;
    }
  }
  return ChatMediaKind.document;
}

int chatMediaMaxBytes(ChatMediaKind kind) => switch (kind) {
      ChatMediaKind.image => chatImageMaxBytes,
      ChatMediaKind.video => chatVideoMaxBytes,
      ChatMediaKind.audio => chatAudioMaxBytes,
      ChatMediaKind.document => chatDocumentMaxBytes,
    };

/// A bilingual error when a file of [bytes] is over the cap of its kind, or
/// null when it fits. [arabic] picks the language.
String? chatMediaSizeError({
  required ChatMediaKind kind,
  required int bytes,
  required bool arabic,
}) {
  final max = chatMediaMaxBytes(kind);
  if (bytes <= max) return null;
  final limit = '${max ~/ (1024 * 1024)} MB';
  final size = formatChatFileSize(bytes);
  final en = switch (kind) {
    ChatMediaKind.image => 'The photo',
    ChatMediaKind.video => 'The video',
    ChatMediaKind.audio => 'The audio file',
    ChatMediaKind.document => 'The file',
  };
  final ar = switch (kind) {
    ChatMediaKind.image => 'الصورة',
    ChatMediaKind.video => 'الفيديو',
    ChatMediaKind.audio => 'الملف الصوتي',
    ChatMediaKind.document => 'الملف',
  };
  return arabic
      ? '$ar حجمه $size، وأقصى حجم مسموح $limit.'
      : '$en is $size; the limit is $limit.';
}

/// `842 KB` / `3.4 MB`.
String formatChatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// A best-guess mime type from a file name, for pickers that give none.
String chatGuessMime(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final ext = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
  const map = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'heic': 'image/heic',
    'mp4': 'video/mp4',
    'm4v': 'video/mp4',
    'mov': 'video/quicktime',
    '3gp': 'video/3gpp',
    'mp3': 'audio/mpeg',
    'ogg': 'audio/ogg',
    'opus': 'audio/ogg',
    'm4a': 'audio/mp4',
    'aac': 'audio/aac',
    'amr': 'audio/amr',
    'wav': 'audio/wav',
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx':
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'txt': 'text/plain',
    'csv': 'text/csv',
    'zip': 'application/zip',
  };
  return map[ext] ?? 'application/octet-stream';
}
