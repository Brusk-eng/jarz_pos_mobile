import 'package:flutter/widgets.dart';

import '../../data/models/studio_enums.dart';

/// Words for the codes the server sends (action codes, Today block keys,
/// scorecard metric keys, statuses, stages), in English and Arabic, from the
/// glossary (`GLOSSARY.md`).
///
/// A code this app does not know gets `null` (actions, metrics) or the
/// server's own title (blocks): it is never shown as a raw code. The test
/// `test/studio/labels_test.dart` walks every enum of the generated models and
/// every action code and fails when a label is missing in either language.
class StudioLabels {
  const StudioLabels._(this.ar);

  static const en = StudioLabels._(false);
  static const arabic = StudioLabels._(true);

  static StudioLabels of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar' ? arabic : en;

  static StudioLabels forLanguage(String code) => code == 'ar' ? arabic : en;

  final bool ar;

  String tr(String en, String ar) => this.ar ? ar : en;

  // ---------------------------------------------------- problem and check lines

  /// The line for a problem or a calendar check. The server words it in the
  /// reader's language (contract v1.3), so it is shown as it came; only an
  /// empty line falls back to the [code].
  String problem(String code, {required String message}) {
    final line = message.trim();
    return line.isEmpty ? code : message;
  }

  // ------------------------------------------------------------ action codes

  /// Every action code the contract can put in an `actions` list (and the
  /// calendar drift actions), with its button label.
  static const _actions = <String, (String, String)>{
    'approve': ('Approve', 'وافق'),
    'fix': ('Send back', 'رجّع'),
    'clear_review': ('Undo my approval', 'ارجع في موافقتي'),
    'rate': ('Rate', 'قيّم'),
    'comment': ('Comment', 'علّق'),
    'edit_meta': ('Edit details', 'عدّل التفاصيل'),
    'edit': ('Edit', 'تعديل'),
    'assign': ('Assign', 'حدّد المسؤول'),
    'move': ('Move', 'انقل'),
    'park': ('Park', 'أجّل'),
    'unpark': ('Bring back', 'رجّعه للشغل'),
    'add_version': ('Add a version', 'ضيف نسخة'),
    'keep': ('Keep', 'احتفظ'),
    'drop': ('Drop', 'سيب'),
    'wont_post': ('Will not post', 'مش هيتنشر'),
    'mark_posted': ('Mark posted', 'علّم إنه اتنشر'),
    'posted': ('Mark posted', 'علّم إنه اتنشر'),
    'retry': ('Try again', 'جرّب تاني'),
    'reopen': ('Reopen', 'افتحه تاني'),
    'set_caption': ('Edit the caption', 'عدّل الكابشن'),
    'frame_set': ('Post the frames', 'انشر الفريمات'),
    'tick': ('Done', 'خلصت'),
    'skip': ('Skip', 'تخطّى'),
    'note': ('Add a note', 'ضيف ملاحظة'),
    'share': ('Share', 'شارك'),
    'tick_shot': ('Mark filmed', 'اتصوّر'),
    'add_shot': ('Add a shot', 'ضيف شوت'),
    'set_consent': ('Record consent', 'سجّل الإذن'),
    'mark_used': ('Mark used', 'علّم إنه اتستخدم'),
    'shortlist': ('Shortlist', 'حطّه في القايمة القصيرة'),
    'send_to_shoot': ('Send to a shoot', 'ابعته لتصوير'),
    'link': ('Link', 'اربط'),
    'set_state': ('Set the state', 'حدّد الحالة'),
    'queue_remove': ('Take out of the queue', 'شيله من الطابور'),
    'remove': ('Remove', 'شيل'),
    'restore': ('Restore', 'رجّعه'),
    'set_feasibility': ('Change the verdict', 'غيّر الرأي'),
    'add_line': ('Add a number', 'ضيف رقم'),
    'mark_reviewed': ('Mark reviewed', 'علّم إنه اتراجع'),
    'answer': ('Answer', 'جاوب'),
    'resolve': ('Resolve', 'اتحلت'),
    'set': ('Change', 'غيّر'),
    'open': ('Open', 'افتح'),
    'match': ('Match', 'اربط'),
    'ignore': ('Ignore', 'تجاهل'),
    'actual_match': ('Match to a post', 'اربطه ببوست'),
    'actual_ignore': ('Ignore', 'تجاهل'),
    'post_wont_post': ('Will not post', 'مش هيتنشر'),
    'post_retry': ('Try again', 'جرّب تاني'),
    'post_move': ('Move the post', 'انقل البوست'),
  };

  static List<String> get actionCodes => _actions.keys.toList();

  /// The button label of an action code, or null for a code this app does not
  /// know (the caller then hides the button).
  String? action(String code) {
    final p = _actions[code];
    return p == null ? null : (ar ? p.$2 : p.$1);
  }

  /// The last line of a detail screen's "How this works": where the tabs went.
  String get backBarNote => tr(
    'This screen opened from a list, so it has a Back arrow instead of the tabs. Back returns you to the list.',
    'الشاشة دي اتفتحت من قايمة، فعليها سهم رجوع بدل التابات. الرجوع بيرجّعك للقايمة.',
  );

  // ------------------------------------------------------------ Today blocks

  /// The title of a Today block; [fallback] (the server's own title) for a key
  /// this app does not know.
  String block(BlockKey key, {String fallback = ''}) => switch (key) {
    BlockKey.sentBack => tr('Sent back to you', 'اللي اترجعلك'),
    BlockKey.toApprove => tr('To approve', 'للموافقة'),
    BlockKey.decisions => tr('Decisions', 'القرارات'),
    BlockKey.ideas => tr('Ideas', 'الأفكار'),
    BlockKey.dueToday => tr('Due today', 'ميعاده النهارده'),
    BlockKey.readyToPost => tr('Ready to post', 'جاهز للنشر'),
    BlockKey.stories => tr('Stories today', 'Stories النهارده'),
    BlockKey.readsMissing => tr('Results to add', 'نتايج ناقصة'),
    BlockKey.adsDue => tr('Paid reads due', 'قراءات الإعلانات المطلوبة'),
    BlockKey.didntGoOut => tr('Didn\'t go out', 'ما نزلش'),
    BlockKey.unplanned => tr('Posted without a plan', 'اتنشر من غير خطة'),
    BlockKey.unconfirmed => tr('Waiting to be confirmed', 'مستني التأكيد'),
    BlockKey.blocked => tr('Blocked', 'واقف'),
    BlockKey.shootTomorrow => tr('Shoot tomorrow', 'تصوير بكرة'),
    BlockKey.advice => tr('Advice from Claude', 'نصيحة من Claude'),
    BlockKey.warnings => tr('System warnings', 'تحذيرات السيستم'),
    BlockKey.rulesChanged => tr(
      'Rules changed this week',
      'قواعد اتغيّرت الأسبوع ده',
    ),
    BlockKey.dayPosts => tr('Posts of the day', 'بوستات اليوم'),
    BlockKey.dayTasks => tr('Tasks due that day', 'مهام اليوم'),
    BlockKey.dayShoots => tr('Shoot of the day', 'تصوير اليوم'),
    BlockKey.unknown => fallback,
  };

  /// What the block says when it is empty, so a new person can tell "nothing"
  /// from "this block does not exist". Null where the server never lists it.
  String? blockEmpty(BlockKey key) => switch (key) {
    BlockKey.sentBack => tr(
      'Sent back to you: nothing.',
      'اللي اترجعلك: مفيش.',
    ),
    BlockKey.dueToday => tr('Due today: nothing.', 'ميعاده النهارده: مفيش.'),
    BlockKey.blocked => tr('Blocked: nothing.', 'واقف: مفيش.'),
    BlockKey.didntGoOut => tr('Didn\'t go out: nothing.', 'ما نزلش: مفيش.'),
    _ => null,
  };

  // ---------------------------------------------------------- scorecard keys

  static const _metrics = <String, (String, String)>{
    'orders': ('Orders', 'الأوردرات'),
    'tagged_order_share': (
      'Orders tagged by source',
      'الأوردرات اللي معروف مصدرها',
    ),
    'cost_per_tagged_order': (
      'Cost per tagged order',
      'تكلفة الأوردر المعروف مصدره',
    ),
    'cost_per_new_customer': ('Cost per new customer', 'تكلفة العميل الجديد'),
    'whatsapp_first_reply_min': (
      'WhatsApp median first reply',
      'متوسط أول رد على واتساب',
    ),
    'ad_spend': ('Ad spend', 'الإنفاق على الإعلانات'),
    'cost_per_purchase': ('Cost per purchase', 'تكلفة الشراء'),
    'frequency_max': ('Highest frequency (7 days)', 'أعلى تكرار (7 أيام)'),
    'new_creatives': ('New creatives live', 'إعلانات جديدة شغالة'),
    'hold3_avg': (
      '3-second hold (average, diagnostic)',
      'الـ hold في 3 ثواني (متوسط، للتشخيص)',
    ),
    'gate_pixel': (
      'Gate 1: pixel fixed, orders tagged',
      'بوابة 1: البكسل اتصلّح والأوردرات متعلّمة',
    ),
    'gate_holdout': ('Gate 2: holdout read', 'بوابة 2: قراءة مجموعة المقارنة'),
    'gate_new_customer_cost': (
      'Gate 3: cost within the line',
      'بوابة 3: التكلفة جوه الخط',
    ),
    'gate_frequency': ('Gate 4: replacements live', 'بوابة 4: البدائل شغالة'),
    'gate_whatsapp': (
      'Gate 5: first reply on time',
      'بوابة 5: أول رد في الميعاد',
    ),
  };

  static List<String> get metricKeys => _metrics.keys.toList();

  /// The name of a scorecard number or gate; null for a key this app does not
  /// know (the server's own label is then used).
  String? metric(String key) {
    final p = _metrics[key];
    return p == null ? null : (ar ? p.$2 : p.$1);
  }

  /// A unit the scorecard sends (`orders`, `%`, `EGP`, `x`, `ads`, `min`).
  String unit(String unit) => switch (unit) {
    'orders' => tr('orders', 'أوردر'),
    'EGP' => tr('EGP', 'جنيه'),
    'ads' => tr('ads', 'إعلان'),
    'min' => tr('min', 'دقيقة'),
    _ => unit,
  };

  // ------------------------------------------------- statuses, stages, kinds

  String pieceStage(PieceStage s) => switch (s) {
    PieceStage.idea => tr('Idea', 'فكرة'),
    PieceStage.script => tr('Script', 'سكريبت'),
    PieceStage.toShoot => tr('To shoot', 'للتصوير'),
    PieceStage.toEdit => tr('To edit', 'للمونتاج'),
    PieceStage.inReview => tr('In review', 'في الريفيو'),
    PieceStage.approved => tr('Approved', 'معتمدة'),
    PieceStage.scheduled => tr('Scheduled', 'مجدولة'),
    PieceStage.posted => tr('Posted', 'اتنشرت'),
    PieceStage.read => tr('Read', 'اتقرت نتايجها'),
    PieceStage.unknown => '',
  };

  String postStatus(PostStatus s) => switch (s) {
    PostStatus.draft => tr('Planned', 'متخطط'),
    PostStatus.checked => tr('Checked', 'اتفحص'),
    PostStatus.scheduled => tr('Scheduled', 'مجدول'),
    PostStatus.publishing => tr('Going out now', 'بينزل دلوقتي'),
    PostStatus.published => tr('Posted', 'اتنشر'),
    PostStatus.failed => tr('Didn\'t go out', 'ما نزلش'),
    PostStatus.cancelled => tr('Skipped', 'اتخطّى'),
    PostStatus.unknown => '',
  };

  String decisionStatus(DecisionStatus s) => switch (s) {
    DecisionStatus.open => tr('Waiting for the founder', 'مستني المؤسس'),
    DecisionStatus.answered => tr('Decided', 'اتحسمت'),
    DecisionStatus.superseded => tr(
      'Replaced by a newer one',
      'اتبدلت بقرار أحدث',
    ),
    DecisionStatus.withdrawn => tr('Withdrawn', 'اتسحبت'),
    DecisionStatus.unknown => '',
  };

  String ideaStatus(IdeaStatus s) => switch (s) {
    IdeaStatus.open => tr('To decide', 'لسه متقررش'),
    IdeaStatus.kept => tr('Kept', 'اتحفظت'),
    IdeaStatus.dropped => tr('Dropped', 'اتسابت'),
    IdeaStatus.unknown => '',
  };

  String frameStatus(FrameStatus s) => switch (s) {
    FrameStatus.posted => tr('Posted', 'اتنشر'),
    FrameStatus.skipped => tr('Skipped', 'اتخطّى'),
    FrameStatus.unknown => '',
  };

  String postedHow(PostedHow h) => switch (h) {
    PostedHow.system => tr('Posted by the system', 'نزل أوتوماتيك'),
    PostedHow.hand => tr('Posted by hand', 'اتنشر يدوي'),
    PostedHow.matched => tr('Matched to a live post', 'اتربط ببوست منشور'),
    PostedHow.unknown => '',
  };

  String taskKind(TaskKind k) => switch (k) {
    TaskKind.todo => tr('Task', 'مهمة'),
    TaskKind.prep => tr('Prep', 'تحضير'),
    TaskKind.unknown => '',
  };

  String versionKind(VersionKind k) => switch (k) {
    VersionKind.video => tr('Video', 'فيديو'),
    VersionKind.staticValue => tr('Static', 'ستاتيك'),
    VersionKind.carousel => tr('Carousel', 'كاروسيل'),
    VersionKind.story => tr('Story', 'Story'),
    VersionKind.unknown => '',
  };

  String mediaKind(MediaKind k) => switch (k) {
    MediaKind.image => tr('Image', 'صورة'),
    MediaKind.video => tr('Video', 'فيديو'),
    MediaKind.audio => tr('Sound', 'صوت'),
    MediaKind.unknown => '',
  };

  String actualKind(ActualKind k) => switch (k) {
    ActualKind.feed => tr('Feed post', 'بوست فيد'),
    ActualKind.reel => tr('Reel', 'Reel'),
    ActualKind.carousel => tr('Carousel', 'كاروسيل'),
    ActualKind.story => tr('Story', 'Story'),
    ActualKind.unknown => '',
  };

  String actualMatch(ActualMatch m) => switch (m) {
    ActualMatch.none => tr('Not matched', 'مش مربوط'),
    ActualMatch.auto => tr('Matched by the system', 'اتربط أوتوماتيك'),
    ActualMatch.hand => tr('Matched by hand', 'اتربط يدوي'),
    ActualMatch.ignored => tr('Ignored', 'اتجاهل'),
    ActualMatch.unknown => '',
  };

  String signalLevel(SignalLevel l) => switch (l) {
    SignalLevel.action => tr('Needs action', 'محتاج حركة'),
    SignalLevel.warn => tr('Warning', 'تحذير'),
    SignalLevel.stop => tr('Stop', 'وقّف'),
    SignalLevel.red => tr('Red', 'أحمر'),
    SignalLevel.bad => tr('Bad', 'وحش'),
    SignalLevel.info => tr('For your information', 'للعلم'),
    SignalLevel.ok => tr('All good', 'تمام'),
    SignalLevel.unknown => '',
  };

  String noteLevel(NoteLevel l) => switch (l) {
    NoteLevel.info => tr('For your information', 'للعلم'),
    NoteLevel.warn => tr('Warning', 'تحذير'),
    NoteLevel.stop => tr('Stop', 'وقّف'),
    NoteLevel.unknown => '',
  };

  String checkSeverity(CheckSeverity s) => switch (s) {
    CheckSeverity.block => tr('Blocks posting', 'بيمنع النشر'),
    CheckSeverity.warn => tr('Warning', 'تحذير'),
    CheckSeverity.unknown => '',
  };

  String moveKind(MoveKind k) => switch (k) {
    MoveKind.forward => tr('Move forward', 'قدّمه'),
    MoveKind.back => tr('Move back', 'رجّعه'),
    MoveKind.unknown => '',
  };

  /// What happened to a post, for the "What changed" sheet.
  String changeKind(ChangeKind k) => switch (k) {
    ChangeKind.moved => tr('Moved', 'اتنقل'),
    ChangeKind.wontPost => tr('Will not post', 'مش هيتنشر'),
    ChangeKind.putBack => tr('Put back', 'اتحط تاني'),
    ChangeKind.added => tr('Added', 'اتضاف'),
    ChangeKind.unknown => '',
  };

  String readWindow(ReadWindow w) => switch (w) {
    ReadWindow.d4 => tr('Day 4 read', 'قراءة اليوم 4'),
    ReadWindow.d7 => tr('Day 7 read', 'قراءة اليوم 7'),
    ReadWindow.unknown => '',
  };

  String lineKind(LineKind k) => switch (k) {
    LineKind.piece => tr('Piece', 'قطعة'),
    LineKind.version => tr('Version', 'نسخة'),
    LineKind.post => tr('Post', 'بوست'),
    LineKind.task => tr('Task', 'مهمة'),
    LineKind.shoot => tr('Shoot', 'تصوير'),
    LineKind.decision => tr('Decision', 'قرار'),
    LineKind.idea => tr('Idea', 'فكرة'),
    LineKind.read => tr('Results', 'نتايج'),
    LineKind.ad => tr('Ad', 'إعلان'),
    LineKind.signal => tr('Signal', 'إشارة'),
    LineKind.actual => tr('Live post', 'بوست نازل'),
    LineKind.summary => tr('Summary', 'ملخص'),
    LineKind.unknown => '',
  };

  String ideaSource(IdeaSource s) => switch (s) {
    IdeaSource.claude => tr('Claude', 'Claude'),
    IdeaSource.creator => tr('A creator', 'صانع محتوى'),
    IdeaSource.founder => tr('The founder', 'المؤسس'),
    IdeaSource.reference => tr('A reference', 'مرجع'),
    IdeaSource.customer => tr('A customer', 'عميل'),
    IdeaSource.other => tr('Other', 'غير ذلك'),
    IdeaSource.unknown => '',
  };
}
