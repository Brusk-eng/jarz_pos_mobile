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
  String get parkedShelf => tr('Parked', 'مركونة');
  String get newPiece => tr('New piece', 'قطعة جديدة');
  String get emptyColumn =>
      tr('Nothing in this stage.', 'مفيش حاجة في المرحلة دي.');
  String get showMore => tr('Show more', 'اعرض أكتر');
  String get nobodyYet => tr('Nobody yet', 'لسه مفيش حد');
  String dueOn(String d) => tr('Due $d', 'الموعد $d');
  String waitingOn(String r) => tr('Waiting: $r', 'مستني: $r');
  String parkedWhy(String r) => tr('Parked: $r', 'مركونة: $r');
  String nextPostAt(String c, String when) =>
      tr('Next post: $c, $when', 'البوست الجاي: $c، $when');

  // Search and filters.
  String get searchHint =>
      tr('Search by title or old number', 'دوّر بالعنوان أو الرقم القديم');
  String get filterStage => tr('Stage', 'المرحلة');
  String get filterOwner => tr('Owner', 'المسؤول');
  String get filterFlavour => tr('Flavor', 'الـ flavor');
  String get filterFormat => tr('Format', 'النوع');
  String get filterPersona => tr('Who it is for', 'لمين');
  String get anyStage => tr('Any stage', 'أي مرحلة');
  String get anyOwner => tr('Anyone', 'أي حد');
  String get anyFlavour => tr('Any flavor', 'أي flavor');
  String get anyFormat => tr('Any format', 'أي نوع');
  String get anyPersona => tr('Anyone', 'أي حد');
  String get clearFilters => tr('Clear filters', 'امسح الفلاتر');
  String get noMatches => tr(
    'No piece matches. Clear a filter or search for something else.',
    'مفيش قطعة مطابقة. امسح فلتر أو دوّر على حاجة تانية.',
  );
  String get ownerClaude => 'Claude';
  String get ownerCreators => tr('The creators', 'فريق الكرييتورز');

  // Piece screen.
  String get pieceNext => tr('What happens next', 'الخطوة الجاية');
  String withPerson(String n) => tr('With $n', 'عند $n');
  String get withNobody => tr('Nobody has it yet', 'لسه مفيش حد ماسكها');
  String get nextNothing =>
      tr('No move is open right now.', 'مفيش خطوة مفتوحة دلوقتي.');
  String get whyNotYet => tr('Not yet, because', 'لسه، عشان');
  String get sectionMoves => tr('Move this piece', 'حرّك القطعة');
  String get sectionLabels => tr('Labels', 'العلامات');
  String get sectionScript => tr('Script', 'السكريبت');
  String get sectionVersions => tr('Versions', 'النسخ');
  String get sectionShots => tr('Shots', 'اللقطات');
  String get sectionPosts => tr('Posts', 'البوستات');
  String get sectionResults => tr('Results', 'النتايج');
  String get sectionHistory => tr('History', 'التاريخ');
  String get showFullHistory => tr('Show the full history', 'اعرض التاريخ كله');
  String get noScript => tr('No script yet.', 'مفيش سكريبت لسه.');
  String get noVersions => tr('No version yet.', 'مفيش نسخة لسه.');
  String get noShots => tr('No shots planned.', 'مفيش لقطات متخططة.');
  String get noPosts => tr('Not on the calendar yet.', 'لسه مش في الكالندر.');
  String get noResults => tr(
    'Results show here after the post has been read.',
    'النتايج بتظهر هنا بعد ما البوست يتقرا.',
  );
  String get noHistory => tr('No changes yet.', 'مفيش تغييرات لسه.');
  String versionNo(int n) => tr('Version $n', 'نسخة $n');
  String get currentVersion => tr('Current', 'الحالية');
  String get openShoot => tr('Open the shoot', 'افتح الشوت');
  String get arabicLine => tr('Arabic', 'عربي');
  String get englishLine => tr('English', 'إنجليزي');
  String get onScreenAr =>
      tr('On-screen text, Arabic', 'الكلام على الشاشة، عربي');
  String get onScreenEn =>
      tr('On-screen text, English', 'الكلام على الشاشة، إنجليزي');
  String get opening => tr('Opening', 'الافتتاحية');
  String get length => tr('Length', 'المدة');
  String get notes => tr('Notes', 'ملاحظات');
  String get ownText => tr('Own text', 'النص الخاص');
  String get adCopy => tr('Ad copy', 'كلام الإعلان');
  String get holds => tr('On hold', 'معلّق');
  String get lineTime => tr('Time', 'الوقت');
  String get lineLang => tr('Language', 'اللغة');
  String scriptLang(ScriptLang l) => switch (l) {
    ScriptLang.ar => tr('Arabic', 'عربي'),
    ScriptLang.en => tr('English', 'إنجليزي'),
    ScriptLang.broll => tr('B-roll', 'لقطات تغطية'),
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
    ReadBucket.manual => tr('Added by hand', 'اتضافت يدوي'),
    ReadBucket.unknown => tr('Reading', 'قراءة'),
  };

  // Moves, parking.
  String get reasonLabel => tr('Reason', 'السبب');
  String get reasonNeeded => tr('Write the reason first.', 'اكتب السبب الأول.');
  String get skipShootReasonLabel =>
      tr('Why does it not need a shoot?', 'ليه مش محتاجة تصوير؟');
  String get confirm => tr('Confirm', 'تمام');
  String get cancel => tr('Cancel', 'إلغاء');
  String get park => tr('Park', 'اركنها');
  String get unpark => tr('Bring back', 'رجّعها');
  String get parkTitle => tr('Park this piece', 'اركن القطعة دي');
  String get parkExplain => tr(
    'It leaves the path but nothing is deleted. Say why.',
    'هتخرج من المسار ومفيش حاجة بتتمسح. قول ليه.',
  );
  String get gateTitle =>
      tr('This move is not allowed yet', 'الخطوة دي لسه مينفعش');
  String get gateIntro => tr(
    'Fix these first, then try again:',
    'صلّح الحاجات دي الأول وبعدين جرّب تاني:',
  );
  String get gateFix => tr('Go fix it', 'روح صلّحها');
  String get close => tr('Close', 'اقفل');
  String movedTo(String stage) => tr('Moved to $stage.', 'اتحركت لـ $stage.');
  String get parkedDone => tr('Parked.', 'اتركنت.');
  String get unparkedDone => tr('Back on the path.', 'رجعت للمسار.');
  String get savedDone => tr('Saved.', 'اتحفظ.');
  String get staleReapplied => tr(
    'Someone changed this piece while you edited. Your changes were put on top of the latest version.',
    'حد غيّر القطعة وانت بتعدّل. غيّراتك اتحطت فوق آخر نسخة.',
  );
  String get gone =>
      tr('This piece is no longer there.', 'القطعة دي مبقتش موجودة.');

  // Edit and create.
  String get editTitle => tr('Edit piece', 'تعديل القطعة');
  String get createTitle => tr('New piece', 'قطعة جديدة');
  String get fieldTitle => tr('Title', 'العنوان');
  String get fieldTitleAr => tr('Title in Arabic', 'العنوان بالعربي');
  String get fieldFormat => tr('Format', 'النوع');
  String get fieldUse => tr('Where it is used', 'بتتستخدم فين');
  String get fieldPersona => tr('Who it is for', 'لمين');
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
  String get create => tr('Create', 'اعمل');
  String get titleNeeded => tr('Give it a title.', 'اكتب عنوان.');
  String get formatNeeded => tr('Pick a format.', 'اختار النوع.');
  String get noChanges => tr('Nothing changed.', 'مفيش حاجة اتغيّرت.');
  String get createdDone =>
      tr('Piece created at Idea.', 'القطعة اتعملت في مرحلة Idea.');

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
    'This week shows who has what, by person.',
    'الأسبوع ده بيوريك مين ماسك إيه، لكل شخص.',
  );
  String get emptyWeekFirst => tr(
    'Give pieces an owner and a date and they show up here.',
    'اديّ القطع مسؤول وموعد وهتظهر هنا.',
  );
  String get weekPieces => tr('Pieces', 'القطع');
  String get weekPosts => tr('Posts', 'البوستات');
  String get weekShots => tr('Shots', 'اللقطات');
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
    Situation.officeLunch => tr('Office lunch', 'غدا المكتب'),
    Situation.other => tr('Other', 'تاني'),
    Situation.unknown => '',
  };
  String layer(ContentLayer l) => switch (l) {
    ContentLayer.hero => 'Hero',
    ContentLayer.hub => 'Hub',
    ContentLayer.hygiene => 'Hygiene',
    ContentLayer.unknown => '',
  };
  String format(PieceFormat f) => switch (f) {
    PieceFormat.reel => tr('Reel', 'ريل'),
    PieceFormat.trial => tr('Trial reel', 'ريل تجريبي'),
    PieceFormat.staticValue => tr('Static', 'صورة ثابتة'),
    PieceFormat.carousel => tr('Carousel', 'كاروسيل'),
    PieceFormat.story => tr('Story', 'ستوري'),
    PieceFormat.unknown => '',
  };
  String use(PieceUse u) => switch (u) {
    PieceUse.feedOnly => tr('Feed only', 'الفيد بس'),
    PieceUse.feedPaid => tr('Feed and ads', 'الفيد والإعلانات'),
    PieceUse.trialOnly => tr('Trial only', 'تجريبي بس'),
    PieceUse.trialPaid => tr('Trial and ads', 'تجريبي وإعلانات'),
    PieceUse.paidOnly => tr('Ads only', 'إعلانات بس'),
    PieceUse.storiesOnly => tr('Stories only', 'ستوريز بس'),
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
    PostChannel.feedReel => tr('Feed reel', 'ريل على الفيد'),
    PostChannel.trialReel => tr('Trial reel', 'ريل تجريبي'),
    PostChannel.trialReelFeed => tr('Trial reel to feed', 'ريل تجريبي للفيد'),
    PostChannel.feedStatic => tr('Feed static', 'صورة على الفيد'),
    PostChannel.feedCarousel => tr('Feed carousel', 'كاروسيل على الفيد'),
    PostChannel.tikTok => 'TikTok',
    PostChannel.story => tr('Story', 'ستوري'),
    PostChannel.unknown => '',
  };
  String postStatus(PostStatus s) => switch (s) {
    PostStatus.draft => tr('Draft', 'مسودة'),
    PostStatus.checked => tr('Checked', 'متراجع'),
    PostStatus.scheduled => tr('Scheduled', 'متجدول'),
    PostStatus.publishing => tr('Going out now', 'بينزل دلوقتي'),
    PostStatus.published => tr('Posted', 'اتنشر'),
    PostStatus.failed => tr('Did not go out', 'مانزلش'),
    PostStatus.cancelled => tr('Cancelled', 'اتلغى'),
    PostStatus.unknown => '',
  };
  String postingMode(PostingMode m) => switch (m) {
    PostingMode.bySystem => tr('The system posts it', 'السيستم بينزّله'),
    PostingMode.byHand => tr('Posted by hand', 'بيتنزّل يدوي'),
    PostingMode.unknown => '',
  };
  String reviewOutcome(ReviewOutcome? o) => switch (o) {
    ReviewOutcome.approved => tr('Approved', 'اتوافق عليها'),
    ReviewOutcome.fix => tr('Needs a fix', 'محتاجة تصليح'),
    _ => tr('Waiting for review', 'مستنية مراجعة'),
  };

  /// An error in plain words for a snackbar or a form: the one app-wide
  /// mapping (`shared/studio_error_text.dart`).
  String error(Object e) => studioErrorMessage(e, ar: ar);
}
