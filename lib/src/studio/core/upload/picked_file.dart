import 'dart:typed_data';

/// A file the person chose. The engine reads it in ranges, so a big video is
/// never held in memory whole (on Android; the browser reads a slice too).
abstract class PickedFile {
  String get name;
  int get size;

  /// Last-modified time, milliseconds since the epoch.
  int get modifiedMs;
  String get mime;

  /// Where the file lives on the device (Android); null on the web, where the
  /// browser gives no path.
  String? get path;

  /// Bytes `[start, end)`.
  Future<Uint8List> readRange(int start, int end);

  /// Length of a video in seconds when the platform can read it, else null.
  Future<double?> durationSeconds() async => null;

  /// What makes two picks "the same file" (path or name, size, modified time).
  String get signature => '${path ?? name}|$size|$modifiedMs';
}

/// A file held in memory (tests, and small generated files).
class MemoryPickedFile extends PickedFile {
  MemoryPickedFile({
    required this.name,
    required this.bytes,
    this.mime = 'image/jpeg',
    this.modifiedMs = 0,
    this.path,
    this.duration,
  });

  @override
  final String name;
  final Uint8List bytes;
  @override
  final String mime;
  @override
  final int modifiedMs;
  @override
  final String? path;
  final double? duration;

  @override
  int get size => bytes.length;

  @override
  Future<Uint8List> readRange(int start, int end) async =>
      Uint8List.sublistView(bytes, start, end.clamp(start, bytes.length));

  @override
  Future<double?> durationSeconds() async => duration;
}

const _mimes = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
  'heic': 'image/heic',
  'gif': 'image/gif',
  'mp4': 'video/mp4',
  'mov': 'video/quicktime',
  'm4v': 'video/x-m4v',
  'webm': 'video/webm',
  'pdf': 'application/pdf',
};

/// The content type for a file name, or `application/octet-stream`.
String mimeFromName(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0) return 'application/octet-stream';
  return _mimes[name.substring(dot + 1).toLowerCase()] ??
      'application/octet-stream';
}
