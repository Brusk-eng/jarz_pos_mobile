import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart' show ImagePicker;
import 'package:video_player/video_player.dart';

import 'file_source.dart';
import 'picked_file.dart';

StudioFileSource createFileSource() => _IoFileSource();

/// A file on the device, read range by range.
class IoPickedFile extends PickedFile {
  IoPickedFile._(this._file, this.size, this.modifiedMs, this.name);

  static Future<IoPickedFile> open(String path, {String? name}) async {
    final f = File(path);
    final stat = await f.stat();
    final n = name ?? path.split(RegExp(r'[\\/]')).last;
    return IoPickedFile._(
      f,
      stat.size,
      stat.modified.millisecondsSinceEpoch,
      n,
    );
  }

  final File _file;
  @override
  final int size;
  @override
  final int modifiedMs;
  @override
  final String name;

  @override
  String get mime => mimeFromName(name);
  @override
  String? get path => _file.path;

  @override
  Future<Uint8List> readRange(int start, int end) async {
    final raf = await _file.open();
    try {
      await raf.setPosition(start);
      return await raf.read(end - start);
    } finally {
      await raf.close();
    }
  }

  @override
  Future<double?> durationSeconds() async {
    if (!mime.startsWith('video/')) return null;
    final c = VideoPlayerController.file(_file);
    try {
      await c.initialize();
      return c.value.duration.inMilliseconds / 1000;
    } catch (_) {
      return null;
    } finally {
      await c.dispose();
    }
  }
}

class _IoFileSource implements StudioFileSource {
  @override
  Future<PickedFile?> fromPath(String path) async {
    try {
      if (!await File(path).exists()) return null;
      return await IoPickedFile.open(path);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<PickedFile>> pickMedia({bool multiple = true}) async {
    final picker = ImagePicker();
    final shots = multiple
        ? await picker.pickMultipleMedia()
        : [?await picker.pickMedia()];
    return [
      for (final x in shots) await IoPickedFile.open(x.path, name: x.name),
    ];
  }

  @override
  Future<List<PickedFile>> pickFiles({bool multiple = true}) async {
    final r = await FilePicker.platform.pickFiles(
      allowMultiple: multiple,
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'heic',
        'mp4',
        'mov',
        'm4v',
        'pdf',
      ],
    );
    if (r == null) return [];
    return [
      for (final f in r.files)
        if (f.path != null) await IoPickedFile.open(f.path!, name: f.name),
    ];
  }
}
