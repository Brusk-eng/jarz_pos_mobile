import 'package:video_player/video_player.dart';

import 'chat_video_controller_io.dart'
    if (dart.library.js_interop) 'chat_video_controller_web.dart' as impl;

/// A controller playing the local file at [uri] (a temp file on Android/iOS).
VideoPlayerController chatFileVideoController(Uri uri) =>
    impl.fileVideoController(uri);
