import 'package:flutter/widgets.dart';

import '../../core/l10n/plural.dart';
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
  String get previous => tr('Previous', 'السابق');
  String get next => tr('Next', 'التالي');
  String get allChannels => tr('All channels', 'كل القنوات');
  String get nothingPlanned => tr('Nothing planned', 'مفيش حاجة متخططة');
  String get addPost => tr('Add a post', 'ضيف بوست');
  String get emptyPurpose => tr(
    'The calendar shows every post and the day it goes out.',
    'الكالندر بيوريك كل بوست واليوم اللي هينزل فيه.',
  );
  String get emptyFirst => tr(
    'Give an approved piece a slot with "Add a post".',
    'اختار قطعة معتمدة وحدّد ميعادها من «ضيف بوست».',
  );
  String postsCount(int n) => tr(
    n == 1 ? '1 post' : '$n posts',
    arCount(n, one: 'بوست', two: 'بوستين', few: 'بوستات', many: 'بوست'),
  );
  String get noTime => tr('No time', 'من غير ميعاد');

  // Banner.
  String get bannerTitle => tr('Needs a look', 'محتاج نظرة');
  String missingPosts(int n) => tr(
    n == 1 ? '1 post did not go out' : '$n posts did not go out',
    '${arCount(n, one: 'بوست واحد', two: 'بوستين', few: 'بوستات', many: 'بوست')} ${n == 1 ? 'مانزلش' : 'مانزلوش'}',
  );
  String unplannedPosts(int n) => tr(
    n == 1
        ? '1 post went out that is not in the calendar'
        : '$n posts went out that are not in the calendar',
    '${arCount(n, one: 'بوست واحد', two: 'بوستين', few: 'بوستات', many: 'بوست')} ${n == 1 ? 'نزل' : 'نزلوا'} ومش في الكالندر',
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

  // Posts that did not go out and posts nobody planned.
  String get driftTitle => tr('Didn\'t go out', 'اللي ما نزلش');
  String get driftIntro => tr(
    'Clear each one: move it, mark it Won\'t post, or match a live post to its slot. A post the system can send again shows a Try again button.',
    'نضّف كل واحد: انقله، أو علّمه «مش هيتنشر»، أو اربط بوست نازل بميعاده. البوست اللي السيستم يقدر يبعته تاني بيظهر عليه زرار «جرّب تاني».',
  );
  String get driftEmptyPurpose => tr(
    'Posts that did not go out, and posts that went out without a plan, show here.',
    'البوستات اللي ما نزلتش، واللي نزلت من غير خطة، بتظهر هنا.',
  );
  String get driftEmptyFirst => tr(
    'Nothing to clear. The calendar matches what is live.',
    'مفيش حاجة تتنضّف. الكالندر زي اللي نازل بالظبط.',
  );
  String get driftLateHeading => tr('Went out late', 'نزل متأخر');
  String get driftLoadingActions =>
      tr('Checking what you can do...', 'بنشوف تقدر تعمل إيه...');
  String get driftWontDone =>
      tr('Marked Won\'t post.', 'اتعلّم إنه مش هيتنشر.');
  String get driftIgnored =>
      tr('Ignored. It leaves this list.', 'اتجاهل. هيختفي من القايمة دي.');
  String get driftMatched => tr(
    'Matched. The post is marked as posted.',
    'اتربط. البوست اتعلّم إنه اتنشر.',
  );
  String get driftNothingToMatch => tr(
    'No post is waiting for a match. Ignore it instead.',
    'مفيش بوست مستني ربط. تجاهله بدل كده.',
  );
  String get driftMatchPick =>
      tr('Which planned post is this?', 'ده أنهي بوست من المخطط؟');
  String get driftOnlyLead => tr(
    'The founder or the marketing lead clears this one.',
    'المؤسس أو مسؤول التسويق هو اللي بينضّف ده.',
  );
  String get driftSeeAll => tr('Clear these one by one', 'نضّفهم واحد واحد');

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
  String get fieldMode => tr('Who posts it', 'مين هينزّله');
  String get pickPiece => tr('Pick a piece', 'اختار قطعة');
  String get searchPieces => tr('Search the pieces', 'دوّر في القطع');
  String get approvedPieces =>
      tr('Approved pieces first', 'القطع المعتمدة الأول');
  String get pieceNeeded => tr('Pick a piece.', 'اختار قطعة.');
  String get channelNeeded => tr('Pick a channel.', 'اختار القناة.');
  String get dateNeeded => tr('Pick a day and a time.', 'اختار اليوم والساعة.');
  String get saveSlot => tr('Save the slot', 'احفظ الميعاد');
  String get slotSaved => tr('Slot saved.', 'الميعاد اتحفظ.');
  String get problemsHeading => tr(
    'The check failed. Fix these and try again:',
    'الفحص مانجحش. صلّح اللي تحت وجرّب تاني:',
  );
  String get warningsHeading => tr('To check:', 'للمراجعة:');
  String get closeLabel => tr('Close', 'اقفل');
  String get cancel => tr('Cancel', 'إلغاء');

  // Post screen.
  String get postHelpTitle => tr('The post screen', 'شاشة البوست');
  List<String> get postHelp => ar
      ? const [
          'هنا بتشوف البوست كله: الصورة أو الفيديو، الكابشن، القناة والميعاد.',
          'الأزرار اللي بتظهر هي اللي تقدر تعملها دلوقتي بس.',
          'لو البوست بيتنزّل يدوي، انزّله وبعدين دوس «علّم إنه اتنشر».',
          'لو مش هيتنشر، دوس «مش هيتنشر» واكتب السبب.',
        ]
      : const [
          'Here you see the whole post: the creative, the caption, the channel and the slot.',
          'Only the buttons you can use right now are shown.',
          'If the post goes out by hand, post it and then tap "Mark posted".',
          'If it will not go out, tap "Won\'t post" and write why.',
        ];
  String get emptyPostPurpose =>
      tr('This post is not there any more.', 'البوست ده مبقاش موجود.');
  String get emptyPostFirst => tr('Go back to the calendar.', 'ارجع للكالندر.');
  String get sectionCreative => tr('Creative', 'الصورة أو الفيديو');
  String get sectionCaption => tr('Caption', 'الكابشن');
  String get sectionSlot => tr('Slot', 'الميعاد');
  String get sectionApproval => tr('Approval', 'الموافقة');
  String get sectionChecks => tr('Checks', 'الفحص');
  String get sectionLog => tr('What happened', 'اللي حصل');
  String get sectionResults => tr('Results', 'النتايج');
  String get sectionFrames => tr('Story frames', 'فريمات الـ Story');
  String get noCaption => tr('No caption yet.', 'لسه مفيش.');
  String whoPostsLine(bool byHand, String who) => byHand
      ? tr('Who posts it: By hand ($who)', 'هتنزلها: يدوي ($who)')
      : tr('Who posts it: The system', 'هتنزل: بالسيستم');
  String get noChecks => tr('No problems found.', 'مفيش مشاكل.');
  String get noLog => tr('Nothing has happened yet.', 'لسه مفيش حاجة حصلت.');
  String get openPiece => tr('Open the piece', 'افتح القطعة');
  String get openVersion => tr('Open the version', 'افتح النسخة');
  String get whoSystem => tr('The system', 'السيستم');
  String get permalink => tr('Link', 'اللينك');
  String get blockLevel => tr('Must fix', 'لازم يتصلّح');
  String get warnLevel => tr('To check', 'للمراجعة');
  String postedHow(String how, String by) =>
      tr('Posted $how by $by', 'اتنشر $how من $by');
  String get postedBySystem => tr('by the system', 'بالسيستم');
  String get postedByHand => tr('by hand', 'يدوي');
  String get postedMatched =>
      tr('matched from Instagram', 'اتعرف عليه من Instagram');
  String postedAt(String when) => tr('Went out at $when', 'نزل الساعة $when');
  String lastError(String e) => tr('It failed: $e', 'حصلت مشكلة: $e');
  String skipReason(String r) => tr('Won\'t post: $r', 'مش هيتنشر: $r');
  String get approvalOk => tr('Approved', 'معتمد');
  String get approvalFix => tr('Needs a fix first', 'محتاج تعديل الأول');
  String get approvalWaiting => tr('Waiting for approval', 'مستني موافقة');
  String get approvalNone => tr('No version chosen', 'لسه مفيش نسخة');

  // Actions.
  String get actionMarkPosted => tr('Mark posted', 'علّم إنه اتنشر');
  String get actionWontPost => tr('Won\'t post', 'مش هيتنشر');
  String get actionRetry => tr('Try again', 'جرّب تاني');
  String get actionMove => tr('Move', 'انقل');
  String get actionSetCaption => tr('Edit the caption', 'تعديل الكابشن');
  String get actionEditSlot => tr('Edit the slot', 'تعديل الميعاد');
  String actionFramePosted(int n) =>
      tr('Mark frame $n posted', 'علّم فريم $n إنه اتنشر');
  String actionFrameSkipped(int n) => tr('Skip frame $n', 'تخطّى فريم $n');
  String get frameDone => tr('Posted', 'اتنشر');
  String get frameSkipped => tr('Skipped', 'اتخطّى');
  String get linkLabel =>
      tr('Link to the post (optional)', 'لينك البوست (اختياري)');
  String get markPostedTitle => tr(
    'Did you post it? Paste the link if you have it.',
    'نشرته فعلاً؟ الصق اللينك لو معاك.',
  );
  String get handPostTitle => tr('Post it by hand', 'انشره يدوي');
  String get handPostSteps => tr(
    '1. Save the files. 2. Copy the caption. 3. Post it in the app. 4. Come back and tap "Mark posted".',
    '1. احفظ الملفات. 2. انسخ الكابشن. 3. انشره من التطبيق. 4. ارجع واضغط «علّم إنه اتنشر».',
  );
  String saveFile(int n, bool video) => tr(
    video ? 'Save video $n' : 'Save picture $n',
    video ? 'احفظ الفيديو $n' : 'احفظ الصورة $n',
  );
  String get saveAll => tr('Save all the files', 'احفظ كل الملفات');
  String get copyCaption => tr('Copy the caption', 'انسخ الكابشن');
  String get captionCopied => tr('Caption copied.', 'الكابشن اتنسخ.');
  String get saveFailed => tr(
    'Could not open the file. Try again in a moment.',
    'مقدرناش نفتح الملف. جرّب كمان شوية.',
  );
  String get nothingToCopy =>
      tr('This post has no caption yet.', 'البوست ده لسه معندوش كابشن.');
  String get noFilesYet =>
      tr('No files on this post yet.', 'مفيش ملفات على البوست ده لسه.');
  String framesDecided(int done, int total) =>
      tr(
        '$done of $total frames decided',
        '$done من ${arFrame.of(total)} اتحددت',
      );
  String get framesAllDecided => tr(
    'Every frame is decided. The story now counts as done.',
    'كل الفريمات اتحددت. الـ Story اتحسبت خلصت.',
  );
  String get wontPostTitle =>
      tr('Won\'t post', 'مش هيتنشر');
  String get reasonLabel => tr('Reason', 'السبب');
  String get reasonNeeded => tr('Write the reason first.', 'اكتب السبب الأول.');
  String get confirm => tr('Confirm', 'تأكيد');
  String get framesAutoPosted => tr(
    'Mark each frame posted or skipped. The story counts as posted as soon as every frame is decided and at least one went out.',
    'علّم كل فريم إنه اتنشر أو اتخطّى. الـ Story بتتعلّم إنها اتنشرت أول ما كل الفريمات تتحدد وواحد على الأقل نزل.',
  );
  String get savedCaption => tr('Caption saved.', 'الكابشن اتحفظ.');
  String get markedPosted => tr(
    'Marked as posted. The 72-hour read comes due in 3 days: file it from this post.',
    'اتعلّم إنه اتنشر. قراءة الـ 72 ساعة ميعادها بعد 3 أيام: سجّلها من البوست ده.',
  );
  String get markedWont =>
      tr('Marked Won\'t post.', 'اتعلّم إنه مش هيتنشر.');
  String get retrying => tr('Sent again.', 'اتبعت تاني.');
  String get moved => tr('Moved.', 'اتنقل.');
  String get frameSaved => tr('Frame saved.', 'الفريم اتحفظ.');
  String get gone =>
      tr('This post is no longer there.', 'البوست ده مبقاش موجود.');

  /// An error in plain words: the one app-wide mapping.
  String error(Object e) => names.error(e);
}
