import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'file_source_stub.dart'
    if (dart.library.io) 'file_source_io.dart'
    if (dart.library.js_interop) 'file_source_web.dart'
    as impl;
import 'picked_file.dart';

/// Where picked files come from. The real one is the browser's file dialog on
/// web and the camera roll / files on Android; tests hand files in directly.
abstract class StudioFileSource {
  /// The camera roll (photos and videos). On the web this is the file dialog.
  Future<List<PickedFile>> pickMedia({bool multiple = true});

  /// Any file the Studio accepts (pictures, videos, PDF).
  Future<List<PickedFile>> pickFiles({bool multiple = true});

  /// Rebuilds a file from the path stored in the queue, or null when the
  /// platform cannot (web) or the file is gone.
  Future<PickedFile?> fromPath(String path);
}

final studioFileSourceProvider = Provider<StudioFileSource>(
  (ref) => impl.createFileSource(),
);
