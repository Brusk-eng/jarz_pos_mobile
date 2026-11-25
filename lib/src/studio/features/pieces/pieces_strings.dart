import 'package:flutter/widgets.dart';

import '../../data/models/studio_enums.dart';
import '../../shared/studio_error_text.dart';

/// Texts of the Pieces screens and the plain-word names of the contract's
/// enums (also used by Calendar). English and Arabic sit side by side in every
/// entry, so one cannot be forgotten. Arabic is simple Egyptian wording and
/// gets a language review later. Product words people say in English (flavor,
/// size, dessert, order) stay in English.
class PiecesStrings {
  const PiecesStrings._(this.ar);

  final bool ar;

  static const en = PiecesStrings._(false);
  static const arabic = PiecesStrings._(true);

  static PiecesStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar' ? arabic : en;

  String tr(String en, String ar) => this.ar ? ar : en;

  // Views.
  String get viewBoard => tr('Board', 'اللوحة');
  String get viewWeek => tr('This week', 'الأسبوع ده');
  String get viewList => tr('List', 'القايمة');
  String get parkedShelf => tr('Parked', 'مؤجّلة');
  String get newPiece => tr('New piece', 'قطعة جديدة');
  String get emptyColumn =>
      tr('No piece in this stage yet.', 'مفيش قطعة في المرحلة دي لسه.');
  String get showMore => tr('Show more', 'اعرض أكتر');
  String get nobodyYet => tr('Nobody yet', 'لسه مفيش حد');
  String dueOn(String d) => tr('Due $d', 'الموعد $d');
  String waitingOn(String r) => tr('Waiting: $r', 'مستني: $r');
  String parkedWhy(String r) => tr('Parked: $r', 'مؤجّلة: $r');
  String nextPostAt(String c, String when) =>
      tr('Next post: $c, $when', 'البوست الجاي: $c، $when');

  // Search and filters.
  String get searchHint =>
      tr('Search by title or old number', 'دوّر بالعنوان أو الرقم القديم');
  String get filterStage => tr('Stage', 'المرحلة');
  String get filterOwner => tr('Owner', 'المسؤول');
  String get filterFlavour => tr('Flavor', 'الـ flavor');
  String get filterFormat => tr('Format', 'النوع');
  String get filterPersona => tr('Audience', 'الجمهور');
  String get anyStage => tr('Any stage', 'أي مرحلة');
  String get anyOwner => tr('Anyone', 'أي حد');
  String get anyFlavour => tr('Any flavor', 'أي flavor');
  String get anyFormat => tr('Any format', 'أي نوع');
  String get anyPersona => tr('Any audience', 'أي جمهور');
  String get clearFilters => tr('Clear filters', 'امسح الفلاتر');
  String get noMatches => tr(
    'No piece matches. Clear a filter or search for something else.',
    'مفيش قطعة مطابقة. امسح فلتر أو دوّر على حاجة تانية.',
  );
  String get ownerClaude => 'Claude';
  String get ownerCreators => tr('The creators', 'صنّاع المحتوى');

  // Piece screen.
  String get pieceNext => tr('What happens next', 'الخطوة الجاية');
  String withPerson(String n) => tr('With $n', 'عند $n');
  String get withNobody => tr('Nobody has it yet', 'لسه مفيش حد ماسكها');

  /// What happens next, stage by stage (SYSTEM_DESIGN section 3): who has the
  /// piece and what they must do. [who] is the owner's name or team (null when
  /// nobody owns it), [reason] the founder's reason when the current version was
  /// sent back, [slot] the next post's day and time, [byHand] whether that post
  /// is put out by hand.
  String stageNext(
    PieceStage stage, {
    String? who,
    String? parkedReason,
    bool sentBack = false,
    String? reason,
    String? slot,
    bool byHand = false,
  }) {
    final owner = who ?? tr('The owner', 'صاحب القطعة');
    if (parkedReason != null) {
      return tr(
        'Parked: $parkedReason. Nobody works on it until it is unparked.',
        'مؤجّلة: $parkedReason. محدش بيشتغل عليها لحد ما تتفعّل تاني.',
      );
    }
    return switch (stage) {
      PieceStage.idea => tr(
        '$owner writes the script. It moves on when the script passes the checks.',
        'عند $owner كتابة السكريبت. بتتحرّك لما السكريبت يعدّي الفحوصات.',
      ),
      PieceStage.script => tr(
        'The script is written. The marketing lead or the founder puts it on a shoot, or sends it straight to edit if it needs no shoot.',
        'السكريبت اتكتب. مسؤول التسويق أو المؤسس بيحطها على تصوير، أو على المونتاج على طول لو مش محتاجة تصوير.',
      ),
      PieceStage.toShoot => tr(
        '$owner films the shots. Ticking the last shot moves it on by itself.',
        'عند $owner تصوير الشوتس. أول ما آخر شوت يتعلّم، بتتحرّك لوحدها.',
      ),
      PieceStage.toEdit =>
        sentBack
            ? tr(
                'The founder sent it back${reason == null ? '' : ': $reason'}. $owner fixes it and uploads a new version.',
                'المؤسس رجّعها${reason == null ? '' : ': $reason'}. عند $owner التصليح ورفع نسخة جديدة.',
              )
            : tr(
                'Filmed. $owner cuts it and uploads a version; it moves on by itself.',
                'اتصوّرت. عند $owner المونتاج ورفع نسخة، وبعدها بتتحرّك لوحدها.',
              ),
      PieceStage.inReview => tr(
        'Waiting for the founder to approve or send back.',
        'مستنية المؤسس يوافق أو يرجّعها.',
      ),
      PieceStage.approved => tr(
        'Approved, no date yet. The marketing lead gives it a slot; it moves on by itself.',
        'معتمدة ومالهاش ميعاد لسه. مسؤول التسويق بيدّيها ميعاد، وبعدها بتتحرّك لوحدها.',
      ),
      PieceStage.scheduled =>
        byHand
            ? tr(
                'Has a post${slot == null ? '' : ' on $slot'}. Whoever posts by hand puts it out and taps "Mark posted".',
                'ليها بوست${slot == null ? '' : ' يوم $slot'}. اللي بينشر بإيده بينشره ويدوس «علّم إنه اتنشر».',
              )
            : tr(
                'Has a post${slot == null ? '' : ' on $slot'}. The system puts it out.',
                'ليها بوست${slot == null ? '' : ' يوم $slot'}. السيستم بينشره.',
              ),
      PieceStage.posted => tr(
        'Live. The 72-hour read is filed by the system, or by the founder or the marketing lead if a number is missing; then it moves on by itself.',
        'نازلة. نتيجة الـ 72 ساعة بيسجّلها السيستم، أو المؤسس أو مسؤول التسويق لو رقم ناقص، وبعدها بتتحرّك لوحدها.',
      ),
      PieceStage.read => tr(
        'Results are in. The founder decides whether it goes to paid.',
        'النتايج جاهزة. المؤسس بيقرّر لو هتروح للإعلانات.',
      ),
      PieceStage.unknown => '',
    };
  }

  String get nextNothing =>
      tr('No move is open right now.', 'مفيش خطوة مفتوحة دلوقتي.');
  String get whyNotYet => tr('Not yet, because:', 'لسه، لأن:');
  String get sectionMoves => tr('Move this piece', 'انقل القطعة');
  String get sectionLabels => tr('Labels', 'العلامات');
  String get sectionScript => tr('Script', 'السكريبت');
  String get sectionVersions => tr('Versions', 'النسخ');
  String get sectionShots => tr('Shots', 'الشوتس');
  String get sectionPosts => tr('Posts', 'البوستات');
  String get sectionResults => tr('Results', 'النتايج');
  String get sectionHistory => tr('History', 'السجل');
  String get showFullHistory => tr('Show the full history', 'اعرض السجل كله');
  String get noScript => tr(
    'No script yet. Add a line to start.',
    'مفيش سكريبت لسه. ضيف جملة تبدأ بيها.',
  );
  String get noVersions => tr('No version yet.', 'مفيش نسخة لسه.');
  String get noShots => tr('No shots planned yet.', 'مفيش شوتس متخططة لسه.');
  String get noPosts => tr('Not on the calendar yet.', 'لسه مش في الكالندر.');
  String get noResults => tr(
    'Results show here after the post has been read.',
    'النتايج بتظهر هنا بعد ما نتايج البوست تتقرا.',
  );
  String get noHistory => tr('No changes yet.', 'مفيش تغييرات لسه.');
  String versionNo(int n) => tr('Version $n', 'نسخة $n');
  String get currentVersion => tr('Current', 'الحالية');
  String get openShoot => tr('Open the shoot', 'افتح التصوير');
  String get arabicLine => tr('Arabic', 'عربي');
  String get englishLine => tr('English', 'إنجليزي');
  String get onScreenAr =>
      tr('On-screen text, Arabic', 'الكلام على الشاشة، عربي');
  String get onScreenEn =>
      tr('On-screen text, English', 'الكلام على الشاشة، إنجليزي');
  String get opening => tr('Opening', 'الافتتاحية');
  String get length => tr('Length', 'المدة');
  String get notes => tr('Notes', 'ملاحظات');
  String get ownText => tr('Own text', 'نص خاص');
  String get adCopy => tr('Ad copy', 'كلام الإعلان');
  String get holds => tr('On hold', 'واقف');
  String get lineTime => tr('Time', 'الوقت');
  String get lineLang => tr('Language', 'اللغة');
  String scriptLang(ScriptLang l) => switch (l) {
    ScriptLang.ar => tr('Arabic', 'عربي'),
    ScriptLang.en => tr('English', 'إنجليزي'),
    ScriptLang.broll => tr('B-roll', 'B-roll'),
    ScriptLang.unknown => '',
  };
  String get lineText => tr('Line', 'الجملة');
  String get addLine => tr('Add a line', 'ضيف جملة');
  String get removeLine => tr('Remove the line', 'شيل الجملة');
  String get readReach => tr('Reach', 'الوصول');
  String get readViews => tr('Views', 'المشاهدات');
  String get readShares => tr('Shares', 'المشاركات');
  String get readSaves => tr('Saves', 'الحفظ');
  String get readLikes => tr('Likes', 'اللايكات');
  String get readComments => tr('Comments', 'التعليقات');
  String readBucket(ReadBucket b) => switch (b) {
    ReadBucket.v24h => tr('After 24 hours', 'بعد 24 ساعة'),
    ReadBucket.v72h => tr('After 72 hours', 'بعد 72 ساعة'),
    ReadBucket.v3d => tr('After 3 days', 'بعد 3 أيام'),
    ReadBucket.v7d => tr('After 7 days', 'بعد 7 أيام'),
    ReadBucket.manual => tr('Added by hand', 'اتضافت بإيد'),
    ReadBucket.unknown => tr('Other reading', 'قراءة تانية'),
  };

  // Moves, parking.
  String get reasonLabel => tr('Reason', 'السبب');
  String get reasonNeeded => tr('Write the reason first.', 'اكتب السبب الأول.');
  String get skipShootReasonLabel =>
      tr('Why does it not need a shoot?', 'ليه مش محتاجة تصوير؟');
  String get confirm => tr('Confirm', 'أكّد');
  String get cancel => tr('Cancel', 'إلغاء');
  String get park => tr('Park', 'أجّلها');
  String get unpark => tr('Bring back', 'رجّعها');
  String get parkTitle => tr('Park this piece', 'أجّل القطعة دي');
  String get parkExplain => tr(
    'It leaves the path but nothing is deleted. Say why.',
    'هتخرج من المسار ومفيش حاجة بتتمسح. اكتب السبب.',
  );
  String get gateTitle =>
      tr('This move is not possible yet', 'الخطوة دي لسه مش متاحة');
  String get gateIntro => tr(
    'The check failed. Fix these and try again:',
    'الفحص مانجحش. صلّح اللي تحت وجرّب تاني:',
  );
  String get gateFix => tr('Go fix it', 'صلّحها');
  String get close => tr('Close', 'اقفل');
  String movedTo(String stage) => tr('Moved to $stage.', 'اتنقلت لـ $stage.');
  String get parkedDone => tr('Parked.', 'اتأجّلت.');
  String get unparkedDone => tr('Back on the path.', 'رجعت للمسار.');
  String get savedDone => tr('Saved.', 'اتحفظ.');
  String get staleReapplied => tr(
    'Someone changed this piece while you were editing. Your changes were put on top of the latest version.',
    'حد غيّر القطعة وهي بتتعدّل. تعديلاتك اتحطت فوق آخر نسخة.',
  );
  String get gone => tr(
    'This piece is gone. Go back to the list.',
    'القطعة دي اتشالت. ارجع للقايمة.',
  );

  // Edit and create.
  String get editTitle => tr('Edit piece', 'تعديل القطعة');
  String get createTitle => tr('New piece', 'قطعة جديدة');
  String get fieldTitle => tr('Title', 'العنوان');
  String get fieldTitleAr => tr('Title in Arabic', 'العنوان بالعربي');
  String get fieldFormat => tr('Format', 'النوع');
  String get fieldUse => tr('Where it is used', 'هتتستخدم فين');
  String get fieldPersona => tr('Audience', 'الجمهور');
  String get fieldSituation => tr('Situation', 'الموقف');
  String get fieldLayer =>
      tr('Hero, Hub or Hygiene', 'Hero ولا Hub ولا Hygiene');
  String get fieldLevel => tr('Awareness level', 'مستوى الوعي');
  String get fieldSeries => tr('Series', 'السلسلة');
  String get fieldFlavours => tr('Flavors', 'الـ flavors');
  String get fieldOwner => tr('Owner', 'المسؤول');
  String get fieldTeam => tr('Team', 'الفريق');
  String get fieldDue => tr('Due date', 'الموعد');
  String get fieldNote => tr('Note', 'ملاحظة');
  String get fieldWhy => tr('Why this piece', 'ليه القطعة دي');
  String get none => tr('None', 'مفيش');
  String get pickDate => tr('Pick a date', 'اختار تاريخ');
  String get clearDate => tr('Clear the date', 'امسح التاريخ');
  String get save => tr('Save', 'احفظ');
  String get create => tr('Create', 'اعمل القطعة');
  String get titleNeeded => tr('Give it a title.', 'اكتب العنوان.');
  String get formatNeeded => tr('Pick a format.', 'اختار النوع.');
  String get noChanges => tr('Nothing changed.', 'مفيش حاجة اتغيّرت.');
  String get createdDone =>
      tr('Piece created in the Idea stage.', 'القطعة اتعملت في مرحلة الفكرة.');

  // Empty states of the three views.
  String get emptyListPurpose => tr(
    'Every piece of content lives here, from idea to results.',
    'كل قطعة محتوى هنا، من الفكرة لحد النتايج.',
  );
  String get emptyListFirst => tr(
    'Make the first piece with "New piece".',
    'اعمل أول قطعة بزرار «قطعة جديدة».',
  );
  String get emptyWeekPurpose => tr(
    'This week shows who has what, person by person.',
    'الأسبوع ده بيوريك مين ماسك إيه، واحد واحد.',
  );
  String get emptyWeekFirst => tr(
    'Give a piece an owner and a date and it shows up here.',
    'حدد لكل قطعة مسؤول وموعد وهتظهر هنا.',
  );
  String get weekPieces => tr('Pieces', 'القطع');
  String get weekPosts => tr('Posts', 'البوستات');
  String get weekShots => tr('Shots', 'الشوتس');
  String get weekTasks => tr('Tasks', 'المهام');

  // Plain names of the contract's enums.
  String persona(Persona p) => switch (p) {
    Persona.household => tr('Household', 'البيت'),
    Persona.selfTreater => tr('Self-treater', 'نفسها'),
    Persona.unknown => '',
  };
  String situation(Situation s) => switch (s) {
    Situation.jarsForTheHouse => tr('Jars for the house', 'برطمانات للبيت'),
    Situation.oneJarForMe => tr('One jar for me', 'برطمان ليا'),
    Situation.guestsAreComing => tr('Guests are coming', 'ضيوف جايين'),
    Situation.aGiftToSend => tr('A gift to send', 'هدية تتبعت'),
    Situation.officeLunch => tr('Office lunch', 'غدا في المكتب'),
    Situation.other => tr('Other', 'حاجة تانية'),
    Situation.unknown => '',
  };
  String layer(ContentLayer l) => switch (l) {
    ContentLayer.hero => 'Hero',
    ContentLayer.hub => 'Hub',
    ContentLayer.hygiene => 'Hygiene',
    ContentLayer.unknown => '',
  };
  String format(PieceFormat f) => switch (f) {
    PieceFormat.reel => tr('Reel', 'Reel'),
    PieceFormat.trial => tr('Trial reel', 'Reel تجريبي'),
    PieceFormat.staticValue => tr('Static', 'صورة ثابتة'),
    PieceFormat.carousel => tr('Carousel', 'Carousel'),
    PieceFormat.story => tr('Story', 'Story'),
    PieceFormat.unknown => '',
  };
  String use(PieceUse u) => switch (u) {
    PieceUse.feedOnly => tr('Feed only', 'Feed بس'),
    PieceUse.feedPaid => tr('Feed and ads', 'Feed وإعلانات'),
    PieceUse.trialOnly => tr('Trial only', 'تجريبي بس'),
    PieceUse.trialPaid => tr('Trial and ads', 'تجريبي وإعلانات'),
    PieceUse.paidOnly => tr('Ads only', 'إعلانات بس'),
    PieceUse.storiesOnly => tr('Stories only', 'Stories بس'),
    PieceUse.unknown => '',
  };
  String route(ProdRoute r) => switch (r) {
    ProdRoute.realShoot => tr('Real shoot', 'تصوير حقيقي'),
    ProdRoute.flow3DStatic => tr('Flow 3D static', 'صورة 3D من Flow'),
    ProdRoute.aIVideo => tr('AI video', 'فيديو AI'),
    ProdRoute.unknown => '',
  };
  String team(OwnerTeam t) => switch (t) {
    OwnerTeam.creators => ownerCreators,
    OwnerTeam.claude => ownerClaude,
    OwnerTeam.unknown => '',
  };
  String channel(PostChannel c) => switch (c) {
    PostChannel.feedReel => tr('Feed reel', 'Reel على الـ Feed'),
    PostChannel.trialReel => tr('Trial reel', 'Reel تجريبي'),
    PostChannel.trialReelFeed => tr(
      'Trial reel to feed',
      'Reel تجريبي للـ Feed',
    ),
    PostChannel.feedStatic => tr('Feed static', 'صورة على الـ Feed'),
    PostChannel.feedCarousel => tr('Feed carousel', 'Carousel على الـ Feed'),
    PostChannel.tikTok => 'TikTok',
    PostChannel.story => tr('Story', 'Story'),
    PostChannel.unknown => '',
  };
  String postStatus(PostStatus s) => switch (s) {
    PostStatus.draft => tr('Draft', 'مسودة'),
    PostStatus.checked => tr('Checked', 'اتراجع'),
    PostStatus.scheduled => tr('Scheduled', 'مجدول'),
    PostStatus.publishing => tr('Going out now', 'بينزل دلوقتي'),
    PostStatus.published => tr('Posted', 'اتنشر'),
    PostStatus.failed => tr('Did not go out', 'ما نزلش'),
    PostStatus.cancelled => tr("Won't post", 'مش هيتنشر'),
    PostStatus.unknown => '',
  };
  String postingMode(PostingMode m) => switch (m) {
    PostingMode.bySystem => tr('The system posts it', 'بينزل أوتوماتيك'),
    PostingMode.byHand => tr('Posted by hand', 'بيتنشر يدوي'),
    PostingMode.unknown => '',
  };
  String reviewOutcome(ReviewOutcome? o) => switch (o) {
    ReviewOutcome.approved => tr('Approved', 'معتمدة'),
    ReviewOutcome.fix => tr('Needs a fix', 'محتاجة تعديل'),
    _ => tr('Waiting for review', 'مستنية الريفيو'),
  };

  /// An error in plain words for a snackbar or a form: the one app-wide
  /// mapping (`shared/studio_error_text.dart`).
  String error(Object e) => studioErrorMessage(e, ar: ar);
}
