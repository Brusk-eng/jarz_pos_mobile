import 'package:video_player/video_player.dart';

/// Web plays the same-origin URL directly; a local file is never created.
VideoPlayerController fileVideoController(Uri uri) =>
    VideoPlayerController.networkUrl(uri);
