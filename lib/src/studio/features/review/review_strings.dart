import 'package:flutter/widgets.dart';

/// Texts of the review screens (version page and rating feed), English and
/// Arabic, in the same pattern as `StudioStrings`: an abstract class with one
/// implementation per language, so a text missing in Arabic fails the build.
///
/// Brand and product words people say in English (Jarz, Studio, flavor, size,
/// dessert, order) stay in English inside Arabic. The Arabic gets a language
/// review later.
abstract class ReviewStrings {
  const ReviewStrings();

  static ReviewStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const ReviewStringsAr()
      : const ReviewStringsEn();

  bool get isArabic;

  // ---- Screen titles and help ------------------------------------------
  String get versionTitle;
  String get versionHelpTitle;
  List<String> get versionHelp;
  String get feedTitle;
  String get feedHelpTitle;
  List<String> get feedHelp;

  // ---- The version -----------------------------------------------------
  String versionNo(int n);
  String get currentVersion;
  String get olderVersion;
  String postsOn(String when, String? channel);
  String get noSlotYet;
  String get noMedia;
  String get storyFrames;
  String frameLabel(int n);
  String get framePosted;
  String get frameSkipped;
  String get langAr;
  String get langEn;
  String get openFullScreen;

  // ---- Review state ----------------------------------------------------
  String get waitingForApproval;
  String approvedBy(String name);
  String sentBackWith(String reason);
  String get approvedPlain;
  String get sentBackPlain;

  // ---- Sell judge ------------------------------------------------------
  String get verdictTitle;
  String get noVerdict;
  String sellScore(String score);
  String get whySells;
  String get whatStops;
  String get fixesTitle;
  String get verdictOutdated;
  String get verdictBlocked;

  // ---- Ratings ---------------------------------------------------------
  String get ratingsTitle;
  String get noRatingsYet;
  String ratingSummary(String avg, int n);
  String stillToRate(String names);
  String get notRatedByMe;
  String yourRating(int score, String label);
  String get yourComment;
  String scoreLabel(int score);

  // ---- Comments --------------------------------------------------------
  String get commentsTitle;
  String get noComments;
  String get wholeVersion;
  String get commentsLoadFailed;

  // ---- Actions ---------------------------------------------------------
  String get approve;
  String get sendBack;
  String get clearDecision;
  String get rate;
  String get changeRating;
  String get comment;
  String get cancel;
  String get save;
  String get send;
  String get confirmApproveTitle;
  String confirmApproveBody(String? when);
  String get confirmApprove;
  String get sendBackTitle;
  String get sendBackHint;
  String get sendBackReasonRequired;
  String get sendBackConfirm;
  String get rateSheetTitle;
  String get rateCommentHint;
  String get commentSheetTitle;
  String get commentHint;
  String get commentForFrame;

  // ---- What happens next ----------------------------------------------
  String approvedPosts(String when);
  String get approvedNoSlot;
  String sentBackTo(String name);
  String get sentBackToCreator;
  String get decisionCleared;
  String ratedSaved(int score, String label);
  String get commentAdded;
  String get backToList;

  // ---- Errors ----------------------------------------------------------
  String get gateFailedTitle;
  String get gateFailedIntro;
  String get gotIt;
  String get tryAgain;

  // ---- Rating feed -----------------------------------------------------
  String get feedEmptyPurpose;
  String get feedEmptyFirstStep;
  String get feedEndTitle;
  String get feedEndBody;
  String get feedBack;
  String get feedSkip;
  String get feedDetails;
  String get feedAddComment;
  String get feedCommentAdded;
  String feedPosition(int i, int? total);
  String feedRollback(String title);
  String get feedSoundOn;
  String get feedSoundOff;
  String get feedLoadMoreFailed;

  /// "Tue 1 Dec 19:00" for an ISO time with an offset: the wall clock as
  /// written (Cairo time), not converted to this device's zone.
  String when(String iso);
}

const _weekdaysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthsEn = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _weekdaysAr = [
  'الاتنين',
  'التلات',
  'الأربع',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];
const _monthsAr = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String _when(String iso, List<String> days, List<String> months) {
  final m = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})',
  ).firstMatch(iso);
  if (m == null) return iso;
  final d = DateTime(
    int.parse(m[1]!),
    int.parse(m[2]!),
    int.parse(m[3]!),
    int.parse(m[4]!),
    int.parse(m[5]!),
  );
  return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]} '
      '${m[4]}:${m[5]}';
}

class ReviewStringsEn extends ReviewStrings {
  const ReviewStringsEn();

  @override
  bool get isArabic => false;
  @override
  String when(String iso) => _when(iso, _weekdaysEn, _monthsEn);

  @override
  String get versionTitle => 'Review';
  @override
  String get versionHelpTitle => 'Reviewing a version';
  @override
  List<String> get versionHelp => const [
    'Watch or look at the version first. Tap the picture to open it full screen.',
    'The sell judge says whether it should sell, why, and what to fix.',
    'Rate it from 1 to 5 and say why. You can change your rating later.',
    'The founder approves a version or sends it back with a reason. Only the buttons you can use are shown.',
    'After every action this page says what happens next and who has it.',
  ];
  @override
  String get feedTitle => 'Rate';
  @override
  String get feedHelpTitle => 'Rating feed';
  @override
  List<String> get feedHelp => const [
    'One version at a time. Swipe up for the next one.',
    'Tap a number to rate it. It saves and moves on.',
    'Want to say why? Tap "Add a comment" before you tap the number.',
    'Tap the picture to pause. Tap the speaker to hear it.',
    'Not sure? Tap Skip. It stays in your list.',
  ];

  @override
  String versionNo(int n) => 'Version $n';
  @override
  String get currentVersion => 'Current version';
  @override
  String get olderVersion => 'An older version';
  @override
  String postsOn(String when, String? channel) =>
      channel == null ? 'Posts $when' : 'Posts $when · $channel';
  @override
  String get noSlotYet => 'No posting date yet';
  @override
  String get noMedia => 'There is no picture or video on this version yet.';
  @override
  String get storyFrames => 'Story frames';
  @override
  String frameLabel(int n) => 'Frame $n';
  @override
  String get framePosted => 'Posted';
  @override
  String get frameSkipped => 'Skipped';
  @override
  String get langAr => 'Arabic';
  @override
  String get langEn => 'English';
  @override
  String get openFullScreen => 'Open full screen';

  @override
  String get waitingForApproval => 'Waiting for approval';
  @override
  String approvedBy(String name) => 'Approved by $name';
  @override
  String sentBackWith(String reason) => 'Sent back: $reason';
  @override
  String get approvedPlain => 'Approved';
  @override
  String get sentBackPlain => 'Sent back';

  @override
  String get verdictTitle => 'Sell judge';
  @override
  String get noVerdict => 'Not judged yet.';
  @override
  String sellScore(String score) => 'Sells $score out of 5';
  @override
  String get whySells => 'Why it sells';
  @override
  String get whatStops => 'What stops it';
  @override
  String get fixesTitle => 'Fix these';
  @override
  String get verdictOutdated =>
      'This verdict was for an older cut. It will be judged again.';
  @override
  String get verdictBlocked => 'Blocked';

  @override
  String get ratingsTitle => 'Ratings';
  @override
  String get noRatingsYet => 'No ratings yet.';
  @override
  String ratingSummary(String avg, int n) =>
      '$avg out of 5 from $n ${n == 1 ? 'rating' : 'ratings'}';
  @override
  String stillToRate(String names) => 'Still to rate: $names';
  @override
  String get notRatedByMe => 'You have not rated this yet.';
  @override
  String yourRating(int score, String label) => 'Your rating: $score, $label';
  @override
  String get yourComment => 'Your comment';
  @override
  String scoreLabel(int score) => switch (score) {
    1 => 'Drop it',
    2 => 'Weak',
    3 => 'Okay',
    4 => 'Strong',
    _ => 'Run it',
  };

  @override
  String get commentsTitle => 'Comments';
  @override
  String get noComments => 'No comments yet.';
  @override
  String get wholeVersion => 'Whole version';
  @override
  String get commentsLoadFailed => 'Could not load the comments.';

  @override
  String get approve => 'Approve';
  @override
  String get sendBack => 'Send back';
  @override
  String get clearDecision => 'Clear the decision';
  @override
  String get rate => 'Rate';
  @override
  String get changeRating => 'Change rating';
  @override
  String get comment => 'Comment';
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get send => 'Send';
  @override
  String get confirmApproveTitle => 'Approve this version?';
  @override
  String confirmApproveBody(String? when) => when == null
      ? 'It has no posting date yet. The marketing lead gives it a slot next.'
      : 'It will post on $when.';
  @override
  String get confirmApprove => 'Yes, approve';
  @override
  String get sendBackTitle => 'Send this version back';
  @override
  String get sendBackHint => 'What should change?';
  @override
  String get sendBackReasonRequired =>
      'Write what should change, so the creator knows what to fix.';
  @override
  String get sendBackConfirm => 'Send back';
  @override
  String get rateSheetTitle => 'How does it look?';
  @override
  String get rateCommentHint => 'Say why (optional)';
  @override
  String get commentSheetTitle => 'Add a comment';
  @override
  String get commentHint => 'Write your comment';
  @override
  String get commentForFrame => 'About which frame?';

  @override
  String approvedPosts(String when) => 'Approved. It posts on $when.';
  @override
  String get approvedNoSlot =>
      'Approved. It has no posting date yet. The marketing lead gives it a slot next.';
  @override
  String sentBackTo(String name) => 'Sent back to $name, with your reason.';
  @override
  String get sentBackToCreator => 'Sent back to the creator, with your reason.';
  @override
  String get decisionCleared =>
      'Decision cleared. It is waiting for your approval again.';
  @override
  String ratedSaved(int score, String label) =>
      'Saved your rating: $score, $label.';
  @override
  String get commentAdded => 'Comment added.';
  @override
  String get backToList => 'Back to the list';

  @override
  String get gateFailedTitle => 'It is not ready to approve';
  @override
  String get gateFailedIntro => 'Fix these first. Nothing was changed.';
  @override
  String get gotIt => 'Got it';
  @override
  String get tryAgain => 'Try again';

  @override
  String get feedEmptyPurpose => 'You rated everything';
  @override
  String get feedEmptyFirstStep =>
      'Nothing is waiting for your rating. New cuts show up here when they are ready.';
  @override
  String get feedEndTitle => 'You rated everything';
  @override
  String get feedEndBody =>
      'Thank you. New cuts show up here when they are ready.';
  @override
  String get feedBack => 'Back';
  @override
  String get feedSkip => 'Skip';
  @override
  String get feedDetails => 'Details';
  @override
  String get feedAddComment => 'Add a comment';
  @override
  String get feedCommentAdded => 'Comment ready. Tap a number to send it.';
  @override
  String feedPosition(int i, int? total) =>
      total == null ? '$i' : '$i of $total';
  @override
  String feedRollback(String title) =>
      'Your rating for "$title" was not saved.';
  @override
  String get feedSoundOn => 'Sound on';
  @override
  String get feedSoundOff => 'Sound off';
  @override
  String get feedLoadMoreFailed => 'Could not load more. Tap to try again.';
}

class ReviewStringsAr extends ReviewStrings {
  const ReviewStringsAr();

  @override
  bool get isArabic => true;
  @override
  String when(String iso) => _when(iso, _weekdaysAr, _monthsAr);

  @override
  String get versionTitle => 'مراجعة';
  @override
  String get versionHelpTitle => 'إزاي تراجع نسخة';
  @override
  List<String> get versionHelp => const [
    'اتفرّج على النسخة الأول. دوس على الصورة تفتحها على الشاشة كلها.',
    'الـ sell judge بيقول هتبيع ولا لأ، وليه، وإيه اللي محتاج يتصلّح.',
    'قيّمها من 1 لـ 5 وقول السبب. تقدر تغيّر تقييمك بعدين.',
    'المؤسس بيوافق على النسخة أو بيرجّعها بسبب. بتشوف بس الأزرار اللي تقدر تستخدمها.',
    'بعد كل خطوة الصفحة بتقولك إيه اللي هيحصل بعد كده ومين ماسكها.',
  ];
  @override
  String get feedTitle => 'قيّم';
  @override
  String get feedHelpTitle => 'صفحة التقييم';
  @override
  List<String> get feedHelp => const [
    'نسخة واحدة في المرة. اسحب لفوق للي بعدها.',
    'دوس على رقم تقيّم. التقييم بيتسجّل وتروح للي بعده.',
    'عايز تقول السبب؟ دوس "أضف تعليق" قبل ما تدوس على الرقم.',
    'دوس على الصورة توقّف الفيديو. دوس على السماعة تسمعه.',
    'مش متأكد؟ دوس "عدّي". هتفضل في قايمتك.',
  ];

  @override
  String versionNo(int n) => 'نسخة $n';
  @override
  String get currentVersion => 'النسخة الحالية';
  @override
  String get olderVersion => 'نسخة أقدم';
  @override
  String postsOn(String when, String? channel) =>
      channel == null ? 'هتتنشر $when' : 'هتتنشر $when · $channel';
  @override
  String get noSlotYet => 'لسه مفيش ميعاد نشر';
  @override
  String get noMedia => 'مفيش صورة ولا فيديو على النسخة دي لسه.';
  @override
  String get storyFrames => 'فريمات الستوري';
  @override
  String frameLabel(int n) => 'فريم $n';
  @override
  String get framePosted => 'اتنشر';
  @override
  String get frameSkipped => 'اتعدّى';
  @override
  String get langAr => 'عربي';
  @override
  String get langEn => 'إنجليزي';
  @override
  String get openFullScreen => 'افتح على الشاشة كلها';

  @override
  String get waitingForApproval => 'مستنية الموافقة';
  @override
  String approvedBy(String name) => 'وافق عليها $name';
  @override
  String sentBackWith(String reason) => 'اترجّعت: $reason';
  @override
  String get approvedPlain => 'اتوافق عليها';
  @override
  String get sentBackPlain => 'اترجّعت';

  @override
  String get verdictTitle => 'Sell judge';
  @override
  String get noVerdict => 'لسه ما اتحكمش عليها.';
  @override
  String sellScore(String score) => 'هتبيع $score من 5';
  @override
  String get whySells => 'ليه هتبيع';
  @override
  String get whatStops => 'إيه اللي بيمنعها';
  @override
  String get fixesTitle => 'اتصلّح الحاجات دي';
  @override
  String get verdictOutdated =>
      'الحكم ده كان على نسخة أقدم. هيتحكم عليها تاني.';
  @override
  String get verdictBlocked => 'موقوفة';

  @override
  String get ratingsTitle => 'التقييمات';
  @override
  String get noRatingsYet => 'مفيش تقييمات لسه.';
  @override
  String ratingSummary(String avg, int n) =>
      '$avg من 5 من $n ${n == 1 ? 'تقييم' : 'تقييمات'}';
  @override
  String stillToRate(String names) => 'لسه هيقيّموا: $names';
  @override
  String get notRatedByMe => 'إنت لسه ما قيّمتش النسخة دي.';
  @override
  String yourRating(int score, String label) => 'تقييمك: $score، $label';
  @override
  String get yourComment => 'تعليقك';
  @override
  String scoreLabel(int score) => switch (score) {
    1 => 'سيبها',
    2 => 'ضعيفة',
    3 => 'كويسة',
    4 => 'قوية',
    _ => 'شغّلها',
  };

  @override
  String get commentsTitle => 'التعليقات';
  @override
  String get noComments => 'مفيش تعليقات لسه.';
  @override
  String get wholeVersion => 'النسخة كلها';
  @override
  String get commentsLoadFailed => 'مقدرناش نحمّل التعليقات.';

  @override
  String get approve => 'وافق';
  @override
  String get sendBack => 'رجّعها';
  @override
  String get clearDecision => 'امسح القرار';
  @override
  String get rate => 'قيّم';
  @override
  String get changeRating => 'غيّر التقييم';
  @override
  String get comment => 'تعليق';
  @override
  String get cancel => 'إلغاء';
  @override
  String get save => 'احفظ';
  @override
  String get send => 'ابعت';
  @override
  String get confirmApproveTitle => 'توافق على النسخة دي؟';
  @override
  String confirmApproveBody(String? when) => when == null
      ? 'لسه ليها ميعاد نشر. مسؤول التسويق هيديها ميعاد بعد كده.'
      : 'هتتنشر $when.';
  @override
  String get confirmApprove => 'أيوه، وافق';
  @override
  String get sendBackTitle => 'رجّع النسخة دي';
  @override
  String get sendBackHint => 'إيه اللي لازم يتغيّر؟';
  @override
  String get sendBackReasonRequired =>
      'اكتب إيه اللي لازم يتغيّر عشان صاحب الشغل يعرف يصلّحه.';
  @override
  String get sendBackConfirm => 'رجّعها';
  @override
  String get rateSheetTitle => 'شايفها إزاي؟';
  @override
  String get rateCommentHint => 'قول السبب (اختياري)';
  @override
  String get commentSheetTitle => 'أضف تعليق';
  @override
  String get commentHint => 'اكتب تعليقك';
  @override
  String get commentForFrame => 'على أنهي فريم؟';

  @override
  String approvedPosts(String when) => 'اتوافق عليها. هتتنشر $when.';
  @override
  String get approvedNoSlot =>
      'اتوافق عليها. لسه ماليهاش ميعاد نشر. مسؤول التسويق هيديها ميعاد بعد كده.';
  @override
  String sentBackTo(String name) => 'اترجّعت لـ $name، ومعاها السبب بتاعك.';
  @override
  String get sentBackToCreator => 'اترجّعت لصاحب الشغل، ومعاها السبب بتاعك.';
  @override
  String get decisionCleared => 'القرار اتمسح. النسخة مستنية موافقتك تاني.';
  @override
  String ratedSaved(int score, String label) =>
      'تقييمك اتسجّل: $score، $label.';
  @override
  String get commentAdded => 'التعليق اتضاف.';
  @override
  String get backToList => 'ارجع للقايمة';

  @override
  String get gateFailedTitle => 'لسه مش جاهزة للموافقة';
  @override
  String get gateFailedIntro => 'صلّح الحاجات دي الأول. مفيش حاجة اتغيّرت.';
  @override
  String get gotIt => 'تمام';
  @override
  String get tryAgain => 'جرّب تاني';

  @override
  String get feedEmptyPurpose => 'قيّمت كل حاجة';
  @override
  String get feedEmptyFirstStep =>
      'مفيش حاجة مستنية تقييمك. النسخ الجديدة هتظهر هنا أول ما تجهز.';
  @override
  String get feedEndTitle => 'قيّمت كل حاجة';
  @override
  String get feedEndBody => 'شكراً. النسخ الجديدة هتظهر هنا أول ما تجهز.';
  @override
  String get feedBack => 'رجوع';
  @override
  String get feedSkip => 'عدّي';
  @override
  String get feedDetails => 'التفاصيل';
  @override
  String get feedAddComment => 'أضف تعليق';
  @override
  String get feedCommentAdded => 'التعليق جاهز. دوس على رقم يتبعت.';
  @override
  String feedPosition(int i, int? total) =>
      total == null ? '$i' : '$i من $total';
  @override
  String feedRollback(String title) => 'تقييمك لـ "$title" ما اتسجّلش.';
  @override
  String get feedSoundOn => 'الصوت شغّال';
  @override
  String get feedSoundOff => 'الصوت مقفول';
  @override
  String get feedLoadMoreFailed => 'مقدرناش نحمّل أكتر. دوس تجرّب تاني.';
}
