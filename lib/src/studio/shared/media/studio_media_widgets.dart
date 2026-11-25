/// The one public entry of the Studio media widgets. Other features import
/// this file only.
///
/// - [StudioThumb]: thumbnail or poster of an image or video.
/// - [openStudioMediaViewer]: full-screen viewer with swipe, zoom, video and
///   download.
/// - [StudioVideoPlayer]: a video with a poster first and a small pool of
///   controllers (at most 3 live).
library;

export 'studio_media_viewer.dart'
    show openStudioMediaViewer, studioLinkOpenerProvider, StudioLinkOpener;
export 'studio_thumb.dart' show StudioThumb, formatDuration;
export 'studio_video_player.dart' show StudioVideoPlayer;
export 'studio_video_pool.dart'
    show
        StudioVideoPool,
        StudioVideoPoolScope,
        VideoSlot,
        VideoSlotStatus,
        studioVideoControllerFactoryProvider,
        VideoControllerFactory;
