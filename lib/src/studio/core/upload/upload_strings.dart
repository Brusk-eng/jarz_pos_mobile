import 'package:flutter/widgets.dart';

import 'upload_job.dart';

/// Texts of the upload tray and the upload checks, English and Arabic.
abstract class UploadStrings {
  const UploadStrings();

  static UploadStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const UploadStringsAr()
      : const UploadStringsEn();

  String get trayTitle;
  String trayCounts(int uploading, int failed, int done);
  String get waitingForConnection;
  String get waitingForTurn;
  String uploadingPercent(int pct);
  String get uploaded;
  String get retry;
  String get cancel;
  String get pickAgain;
  String get pickAgainWhy;
  String get dismissDone;
  String get followUpFailed;
  String get tryAgain;

  String rejection(UploadRejection r, String name);
  String errorText(String? code, String? message);
}

class UploadStringsEn extends UploadStrings {
  const UploadStringsEn();
  @override
  String get trayTitle => 'Uploads';
  @override
  String trayCounts(int u, int f, int d) => [
    if (u > 0) '$u uploading',
    if (f > 0) '$f failed',
    if (d > 0) '$d done',
  ].join(' · ');
  @override
  String get waitingForConnection => 'Waiting for the connection';
  @override
  String get waitingForTurn => 'Waiting for its turn';
  @override
  String uploadingPercent(int pct) => 'Uploading $pct%';
  @override
  String get uploaded => 'Uploaded';
  @override
  String get retry => 'Try again';
  @override
  String get cancel => 'Cancel';
  @override
  String get pickAgain => 'Pick the file again';
  @override
  String get pickAgainWhy =>
      'The browser forgot this file. Pick the same one and it carries on.';
  @override
  String get dismissDone => 'Clear finished';
  @override
  String get followUpFailed => 'Uploaded, but the next step did not save.';
  @override
  String get tryAgain => 'Try again';

  @override
  String rejection(UploadRejection r, String name) => switch (r) {
    UploadRejection.empty => '$name is empty.',
    UploadRejection.wrongType =>
      '$name is not a picture, a video or a PDF, so it cannot go up.',
    UploadRejection.tooBig => '$name is too big to upload.',
    UploadRejection.tooLong => '$name is longer than a story clip can be.',
    UploadRejection.duplicate => '$name is already uploading or uploaded.',
  };

  @override
  String errorText(String? code, String? message) => switch (code) {
    'shadow' => 'The Studio is not switched on yet, so nothing can go up.',
    'permission' => message ?? 'You are not allowed to upload this.',
    'validation' => message ?? 'The server did not accept this file.',
    'expired' => 'The upload link ran out. Try again.',
    'file_missing' => 'The file is no longer on this phone.',
    _ => message ?? 'The upload failed. Try again.',
  };
}

class UploadStringsAr extends UploadStrings {
  const UploadStringsAr();
  @override
  String get trayTitle => 'الرفع';
  @override
  String trayCounts(int u, int f, int d) => [
    if (u > 0) '$u بيترفع',
    if (f > 0) '$f فشل',
    if (d > 0) '$d خلص',
  ].join(' · ');
  @override
  String get waitingForConnection => 'مستني النت';
  @override
  String get waitingForTurn => 'مستني دوره';
  @override
  String uploadingPercent(int pct) => 'بيترفع $pct%';
  @override
  String get uploaded => 'اترفع';
  @override
  String get retry => 'جرّب تاني';
  @override
  String get cancel => 'إلغاء';
  @override
  String get pickAgain => 'اختار الملف تاني';
  @override
  String get pickAgainWhy => 'المتصفح نسي الملف ده. اختار نفس الملف وهيكمّل.';
  @override
  String get dismissDone => 'امسح اللي خلص';
  @override
  String get followUpFailed => 'اترفع، بس الخطوة اللي بعده ما اتحفظتش.';
  @override
  String get tryAgain => 'جرّب تاني';

  @override
  String rejection(UploadRejection r, String name) => switch (r) {
    UploadRejection.empty => '$name فاضي.',
    UploadRejection.wrongType =>
      '$name مش صورة ولا فيديو ولا PDF، فمينفعش يترفع.',
    UploadRejection.tooBig => '$name كبير أوي على الرفع.',
    UploadRejection.tooLong => '$name أطول من اللي الستوري تقبله.',
    UploadRejection.duplicate => '$name بيترفع أو اترفع قبل كده.',
  };

  @override
  String errorText(String? code, String? message) => switch (code) {
    'shadow' => 'الـ Studio لسه مش شغّال، فمفيش حاجة تترفع.',
    'permission' => message ?? 'مش مسموح لك ترفع ده.',
    'validation' => message ?? 'السيرفر ما قبلش الملف ده.',
    'expired' => 'لينك الرفع خلص. جرّب تاني.',
    'file_missing' => 'الملف ما بقاش على التليفون.',
    _ => message ?? 'الرفع فشل. جرّب تاني.',
  };
}
