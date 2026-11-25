import 'package:flutter/widgets.dart';

/// Texts of the media widgets (viewer, player, thumbnails). English and
/// Arabic; the language is read from the surrounding [Localizations].
abstract class MediaStrings {
  const MediaStrings();

  static MediaStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const MediaStringsAr()
      : const MediaStringsEn();

  String get close;
  String get download;
  String get downloadFailed;
  String get mute;
  String get unmute;
  String get play;
  String get pause;
  String get couldNotPlay;
  String get couldNotShow;
  String get tryAgain;
  String get video;
  String get image;
  String itemOf(int index, int total);
  String get zoomHint;
}

class MediaStringsEn extends MediaStrings {
  const MediaStringsEn();
  @override
  String get close => 'Close';
  @override
  String get download => 'Download';
  @override
  String get downloadFailed => 'Could not get the download link. Try again.';
  @override
  String get mute => 'Turn sound off';
  @override
  String get unmute => 'Turn sound on';
  @override
  String get play => 'Play';
  @override
  String get pause => 'Pause';
  @override
  String get couldNotPlay => 'This video will not play. Try again.';
  @override
  String get couldNotShow => 'This picture will not load. Try again.';
  @override
  String get tryAgain => 'Try again';
  @override
  String get video => 'Video';
  @override
  String get image => 'Picture';
  @override
  String itemOf(int index, int total) => '$index of $total';
  @override
  String get zoomHint => 'Pinch to zoom';
}

class MediaStringsAr extends MediaStrings {
  const MediaStringsAr();
  @override
  String get close => 'اقفل';
  @override
  String get download => 'نزّل';
  @override
  String get downloadFailed => 'مقدرناش نجيب لينك التنزيل. جرّب تاني.';
  @override
  String get mute => 'اقفل الصوت';
  @override
  String get unmute => 'افتح الصوت';
  @override
  String get play => 'شغّل';
  @override
  String get pause => 'وقّف';
  @override
  String get couldNotPlay => 'الفيديو مش بيشتغل. جرّب تاني.';
  @override
  String get couldNotShow => 'الصورة مش بتفتح. جرّب تاني.';
  @override
  String get tryAgain => 'جرّب تاني';
  @override
  String get video => 'فيديو';
  @override
  String get image => 'صورة';
  @override
  String itemOf(int index, int total) => '$index من $total';
  @override
  String get zoomHint => 'قرّب بصابعين';
}
