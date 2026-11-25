import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'file_source.dart';
import 'picked_file.dart';

StudioFileSource createFileSource() => _WebFileSource();

/// A browser `File`, read slice by slice so a big video is not loaded whole.
class WebPickedFile extends PickedFile {
  WebPickedFile(this._file);
  final web.File _file;

  @override
  String get name => _file.name;
  @override
  int get size => _file.size;
  @override
  int get modifiedMs => _file.lastModified;
  @override
  String get mime => _file.type.isEmpty ? mimeFromName(_file.name) : _file.type;
  @override
  String? get path => null;

  @override
  Future<Uint8List> readRange(int start, int end) async {
    final buf = await _file.slice(start, end).arrayBuffer().toDart;
    return buf.toDart.asUint8List();
  }
}

class _WebFileSource implements StudioFileSource {
  @override
  Future<PickedFile?> fromPath(String path) async => null;

  @override
  Future<List<PickedFile>> pickMedia({bool multiple = true}) =>
      _pick('image/*,video/*', multiple);

  @override
  Future<List<PickedFile>> pickFiles({bool multiple = true}) =>
      _pick('image/*,video/*,application/pdf', multiple);

  Future<List<PickedFile>> _pick(String accept, bool multiple) {
    final done = Completer<List<PickedFile>>();
    final input = web.document.createElement('input') as web.HTMLInputElement
      ..type = 'file'
      ..accept = accept
      ..multiple = multiple;
    input.addEventListener(
      'change',
      ((web.Event _) {
        final files = input.files;
        final out = <PickedFile>[];
        if (files != null) {
          for (var i = 0; i < files.length; i++) {
            final f = files.item(i);
            if (f != null) out.add(WebPickedFile(f));
          }
        }
        if (!done.isCompleted) done.complete(out);
      }).toJS,
    );
    input.addEventListener(
      'cancel',
      ((web.Event _) {
        if (!done.isCompleted) done.complete(const []);
      }).toJS,
    );
    input.click();
    return done.future;
  }
}
