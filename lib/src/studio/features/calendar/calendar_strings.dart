import 'package:flutter/widgets.dart';

import '../pieces/pieces_strings.dart';

/// Texts of the Calendar and Post screens. Same pattern as [PiecesStrings]:
/// English and Arabic side by side in every entry. Names of channels, statuses
/// and the like come from [PiecesStrings].
class CalendarStrings {
  const CalendarStrings._(this.ar);

  final bool ar;

  static const en = CalendarStrings._(false);
  static const arabic = CalendarStrings._(true);

  static CalendarStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar' ? arabic : en;

  PiecesStrings get names => ar ? PiecesStrings.arabic : PiecesStrings.en;

  String tr(String en, String ar) => this.ar ? ar : en;

  // Calendar screen.
  String get viewWeek => tr('Week', 'أسبوع');
  String get viewMonth => tr('Month', 'شهر');
  String get today => tr('Today', 'النهارده');
  String get previous => tr('Previous', 'اللي قبل');
  String get next => tr('Next', 'اللي بعد');
  String get allChannels => tr('All channels', 'كل القنوات');
  String get nothingPlanned => tr('Nothing planned', 'مفيش حاجة متخططة');
  String get addPost => tr('Add a post', 'ضيف بوست');
  String get emptyPurpose => tr(
    'The calendar shows every post and the day it goes out.',
    'الكالندر بيوريك كل بوست واليوم اللي هينزل فيه.',
  );
  String get emptyFirst => tr(
    'Give an approved piece a slot with "Add a post".',
    'اديّ قطعة متوافق عليها ميعاد بزرار «ضيف بوست».',
  );
  String postsCount(int n) => tr(n == 1 ? '1 post' : '$n posts', '$n بوست');
  String get noTime => tr('No time', 'من غير ميعاد');

  // Banner.
  String get bannerTitle => tr('Needs a look', 'محتاج نظرة');
  String missingPosts(int n) => tr(
    n == 1 ? '1 post did not go out' : '$n posts did not go out',
    n == 1 ? 'بوست واحد مانزلش' : '$n بوستات مانزلوش',
  );
  String unplannedPosts(int n) => tr(
    n == 1
        ? '1 post went out that is not in the calendar'
        : '$n posts went out that are not in the calendar',
    n == 1
        ? 'بوست واحد نزل ومش في الكالندر'
        : '$n بوستات نزلوا ومش في الكالندر',
  );
  String checkProblems(int block, int warn) => tr(
    '$block must fix, $warn to check',
    '$block لازم يتصلّح، $warn محتاج مراجعة',
  );
  String get bannerOpen => tr('See details', 'شوف التفاصيل');
  String get bannerMissingHeading => tr('Did not go out', 'اللي مانزلش');
  String get bannerUnplannedHeading =>
      tr('Went out, not in the calendar', 'نزل ومش في الكالندر');
  String get bannerNothing => tr('All clear.', 'كله تمام.');

  // Slot form.
  String get formCreateTitle => tr('Add a post', 'ضيف بوست');
  String get formEditTitle => tr('Change the slot', 'غيّر الميعاد');
  String get formMoveTitle => tr('Move the post', 'انقل البوست');
  String get fieldPiece => tr('Piece', 'القطعة');
  String get fieldVersion => tr('Version', 'النسخة');
  String get fieldChannel => tr('Channel', 'القناة');
  String get fieldDate => tr('Date', 'اليوم');
  String get fieldTime => tr('Time', 'الساعة');
  String get fieldCaption => tr('Caption', 'الكابشن');
  String get fieldMode => tr('Who posts it', 'مين بينزّله');
  String get pickPiece => tr('Pick a piece', 'اختار قطعة');
  String get searchPieces => tr('Search the pieces', 'دوّر في القطع');
  String get approvedPieces =>
      tr('Approved pieces first', 'القطع المتوافق عليها الأول');
  String get pieceNeeded => tr('Pick a piece.', 'اختار قطعة.');
  String get channelNeeded => tr('Pick a channel.', 'اختار القناة.');
  String get dateNeeded => tr('Pick a day and a time.', 'اختار اليوم والساعة.');
  String get saveSlot => tr('Save the slot', 'احفظ الميعاد');
  String get slotSaved => tr('Slot saved.', 'الميعاد اتحفظ.');
  String get problemsHeading => tr('Fix these first:', 'صلّح دول الأول:');
  String get warningsHeading => tr('To check:', 'للمراجعة:');
  String get closeLabel => tr('Close', 'اقفل');
  String get cancel => tr('Cancel', 'إلغاء');

  // Post screen.
  String get postHelpTitle => tr('The post screen', 'شاشة البوست');
  List<String> get postHelp => ar
      ? const [
          'هنا بتشوف البوست كله: الصورة أو الفيديو، الكابشن، القناة والميعاد.',
          'الأزرار اللي بتظهر هي اللي تقدر تعملها دلوقتي بس.',
          'لو البوست بيتنزّل يدوي، انزّله وبعدين دوس «نزّلته».',
          'لو مش هينزل، دوس «مش هينزل» واكتب السبب.',
        ]
      : const [
          'Here you see the whole post: the creative, the caption, the channel and the slot.',
          'Only the buttons you can use right now are shown.',
          'If the post goes out by hand, post it and then tap "I posted it".',
          'If it will not go out, tap "Won\'t post" and write why.',
        ];
  String get emptyPostPurpose =>
      tr('This post is not there any more.', 'البوست ده مبقاش موجود.');
  String get emptyPostFirst => tr('Go back to the calendar.', 'ارجع للكالندر.');
  String get sectionCreative => tr('Creative', 'الشغل');
  String get sectionCaption => tr('Caption', 'الكابشن');
  String get sectionSlot => tr('Slot', 'الميعاد');
  String get sectionApproval => tr('Approval', 'الموافقة');
  String get sectionChecks => tr('Checks', 'المراجعات');
  String get sectionLog => tr('What happened', 'اللي حصل');
  String get sectionResults => tr('Results', 'النتايج');
  String get sectionFrames => tr('Story frames', 'فريمات الستوري');
  String get noCaption => tr('No caption yet.', 'مفيش كابشن لسه.');
  String get noChecks => tr('No problems found.', 'مفيش مشاكل.');
  String get noLog => tr('Nothing has happened yet.', 'لسه مفيش حاجة حصلت.');
  String get openPiece => tr('Open the piece', 'افتح القطعة');
  String get openVersion => tr('Open the version', 'افتح النسخة');
  String get whoSystem => tr('The system', 'السيستم');
  String get permalink => tr('Link', 'اللينك');
  String get blockLevel => tr('Must fix', 'لازم يتصلّح');
  String get warnLevel => tr('To check', 'للمراجعة');
  String postedHow(String how, String by) =>
      tr('Posted $how by $by', 'اتنشر $how بواسطة $by');
  String get postedBySystem => tr('by the system', 'بالسيستم');
  String get postedByHand => tr('by hand', 'يدوي');
  String get postedMatched =>
      tr('matched from Instagram', 'اتطابق من Instagram');
  String postedAt(String when) => tr('Went out at $when', 'نزل الساعة $when');
  String lastError(String e) => tr('It failed: $e', 'فشل: $e');
  String skipReason(String r) => tr('Will not post: $r', 'مش هينزل: $r');
  String get approvalOk => tr('Approved', 'متوافق عليه');
  String get approvalFix => tr('Needs a fix first', 'محتاج تصليح الأول');
  String get approvalWaiting => tr('Waiting for approval', 'مستني موافقة');
  String get approvalNone => tr('No version chosen', 'لسه مفيش نسخة');

  // Actions.
  String get actionMarkPosted => tr('I posted it', 'نزّلته');
  String get actionWontPost => tr('Won\'t post', 'مش هينزل');
  String get actionRetry => tr('Try again', 'جرّب تاني');
  String get actionMove => tr('Move', 'انقل');
  String get actionSetCaption => tr('Edit the caption', 'عدّل الكابشن');
  String get actionEditSlot => tr('Edit the slot', 'عدّل الميعاد');
  String get actionFramePosted => tr('Posted', 'اتنشر');
  String get actionFrameSkipped => tr('Skip', 'اتخطى');
  String get frameDone => tr('Posted', 'اتنشر');
  String get frameSkipped => tr('Skipped', 'اتخطى');
  String get linkLabel =>
      tr('Link to the post (optional)', 'لينك البوست (اختياري)');
  String get markPostedTitle => tr('You posted it', 'انت نزّلته');
  String get wontPostTitle =>
      tr('This post will not go out', 'البوست ده مش هينزل');
  String get reasonLabel => tr('Reason', 'السبب');
  String get reasonNeeded => tr('Write the reason first.', 'اكتب السبب الأول.');
  String get confirm => tr('Confirm', 'تمام');
  String get framesAutoPosted => tr(
    'Mark each frame posted or skipped. The story counts as posted as soon as every frame is decided and at least one went out.',
    'علّم كل فريم إنه نزل أو اتخطّى. الستوري بتتعلّم إنها نزلت أول ما كل الفريمات تتحدد وواحد على الأقل نزل.',
  );
  String get savedCaption => tr('Caption saved.', 'الكابشن اتحفظ.');
  String get markedPosted => tr('Marked as posted.', 'اتعلّم إنه نزل.');
  String get markedWont =>
      tr('Marked as will not post.', 'اتعلّم إنه مش هينزل.');
  String get retrying => tr('Sent again.', 'اتبعت تاني.');
  String get moved => tr('Moved.', 'اتنقل.');
  String get frameSaved => tr('Frame saved.', 'الفريم اتحفظ.');
  String get gone =>
      tr('This post is no longer there.', 'البوست ده مبقاش موجود.');

  /// An error in plain words: the one app-wide mapping.
  String error(Object e) => names.error(e);
}
