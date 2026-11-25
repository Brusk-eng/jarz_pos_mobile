import 'package:flutter/widgets.dart';

import '../../core/l10n/plural.dart';
import '../../data/models/studio_enums.dart';

/// Texts of the shoot screens (list, shoot page, edit, On set and the public
/// prep page), English and Arabic, in the same pattern as `StudioStrings`: a
/// text missing in Arabic fails the build. The Arabic gets a language review
/// later; flavor, size, dessert and order stay English inside it.
abstract class ShootStrings {
  const ShootStrings();

  static ShootStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const ShootStringsAr()
      : const ShootStringsEn();

  bool get isArabic;

  /// "Wed 26 Nov, 11:00".
  String dateLabel(String? date, String? time);

  // ---- List ------------------------------------------------------------
  String get tabUpcoming;
  String get tabPast;
  String get emptyUpcomingPurpose;
  String get emptyUpcomingFirst;
  String get emptyPastPurpose;
  String get emptyPastFirst;
  String get planShoot;
  String get noDateYet;
  String shotsOf(int done, int total);
  String prepOf(int done, int total);
  String status(ShootStatus s);
  String get loadMore;
  String get showingStoredCopy;
  String get listHelpTitle;
  List<String> get listHelp;

  // ---- Shoot page ------------------------------------------------------
  String get sectionPlan;
  String get sectionPrep;
  String get sectionShots;
  String get noPrep;
  String get noShots;
  String get notForPieceYet;
  String get fieldPlace;
  String get fieldPeople;
  String get fieldKit;
  String get fieldNotes;
  String assignedTo(String name);
  String get startOnSet;
  String get sharePrep;
  String get shareTitle;
  String get shareHelp;
  String get copyLink;
  String get linkCopied;
  String get sendWhatsApp;
  String get newLink;
  String get newLinkWarning;
  String get shareFailed;
  String get addShot;
  String get editShot;
  String get shotWhat;
  String get shotSetup;
  String get shotLineAr;
  String get shotLineEn;
  String get save;
  String get cancel;
  String get prepNeedsConnection;
  String get filmedMark;
  String get notFilmedMark;
  String get shootNotFound;
  String piecesCount(int n);

  // ---- Edit ------------------------------------------------------------
  String get editTitle;
  String get newTitle;
  String get fieldTitle;
  String get fieldDate;
  String get fieldTime;
  String get fieldStatus;
  String get pickDate;
  String get pickTime;
  String get clear;
  String get titleRequired;
  String get saved;
  String get changedMeanwhile;
  String get editHelpTitle;
  List<String> get editHelp;

  // ---- On set ----------------------------------------------------------
  String get onSetTitle;
  String shotOf(int i, int n);
  String get filmedButton;
  String get filmedDone;
  String get noteLabel;
  String get noteHint;
  String get noteSaved;
  String get next;
  String get previous;
  String get scriptLine;
  String get onScreenText;
  String get setupLabel;
  String lengthSeconds(String s);
  String get referencesTitle;
  String get noReferences;
  String get realReference;
  String get madeReference;
  String get briefWhy;
  String get briefFrame;
  String get briefLight;
  String get briefAction;
  String get briefSound;
  String get briefAvoid;
  String get briefCheck;
  String get briefTakes;
  String get servesPieces;
  String get allFilmed;
  String get exitOnSet;
  String get offlineBanner;
  String waitingToSend(int n);
  String get sendingNow;
  String get allSent;
  String get sendNow;
  String piecesMoved(int n, String stage);
  String refusedChange(String what);
  String get onSetHelpTitle;
  List<String> get onSetHelp;

  // ---- Errors ----------------------------------------------------------
  String get errShadow;
  String get errStale;
  String get errNotPermitted;
  String get errNetwork;
  String get errGeneric;
  String get errNotFound;

  // ---- Public prep page ------------------------------------------------
  String get prepPageTitle;
  String get prepKit;
  String get prepItems;
  String get prepNoItems;
  String get prepBadLinkTitle;
  String get prepBadLinkBody;
  String get prepTryAgainLater;
  String get prepRead;
}

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
const _daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
const _daysAr = [
  'الاتنين',
  'التلات',
  'الأربع',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

String _date(
  String? date,
  String? time,
  List<String> days,
  List<String> months,
) {
  final d = date == null ? null : DateTime.tryParse(date);
  if (d == null) return time ?? '';
  final s = '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  return time == null || time.isEmpty ? s : '$s، $time';
}

class ShootStringsEn extends ShootStrings {
  const ShootStringsEn();

  @override
  bool get isArabic => false;
  @override
  String dateLabel(String? date, String? time) =>
      _date(date, time, _daysEn, _monthsEn).replaceFirst('،', ',');

  @override
  String get tabUpcoming => 'Upcoming';
  @override
  String get tabPast => 'Past';
  @override
  String get emptyUpcomingPurpose =>
      'Shoots you have planned show here, with their prep list and shots.';
  @override
  String get emptyUpcomingFirst =>
      'Plan a shoot, then share its prep list with operations.';
  @override
  String get emptyPastPurpose => 'Shoots that are done show here.';
  @override
  String get emptyPastFirst =>
      'Nothing finished yet. Set a shoot to Done when it is over.';
  @override
  String get planShoot => 'Plan a shoot';
  @override
  String get noDateYet => 'No date yet';
  @override
  String shotsOf(int d, int t) => '$d of $t shots filmed';
  @override
  String prepOf(int d, int t) => 'Prep $d of $t';
  @override
  String status(ShootStatus s) => switch (s) {
    ShootStatus.idea => 'Idea',
    ShootStatus.prep => 'Preparing',
    ShootStatus.ready => 'Ready',
    ShootStatus.shot => 'Filmed',
    ShootStatus.done => 'Done',
    ShootStatus.skipped => 'Skipped',
    ShootStatus.unknown => 'Other',
  };
  @override
  String get loadMore => 'Show more';
  @override
  String get showingStoredCopy =>
      'No connection. Showing the copy stored on this phone.';
  @override
  String get listHelpTitle => 'How shoots work';
  @override
  List<String> get listHelp => const [
    'Each card is one shoot day: when, where, and how much is ready.',
    'Open a shoot to see the prep list and a card for every shot.',
    'On set works with no connection: tick each shot, leave a note.',
    'Share the prep page with the kitchen. They need no account.',
  ];

  @override
  String get sectionPlan => 'The plan';
  @override
  String get sectionPrep => 'Prep list';
  @override
  String get sectionShots => 'Shots';
  @override
  String get noPrep => 'No prep tasks yet.';
  @override
  String get noShots => 'No shots yet. Add the first one.';
  @override
  String get notForPieceYet => 'Not for a piece yet';
  @override
  String get fieldPlace => 'Place';
  @override
  String get fieldPeople => 'Who is there';
  @override
  String get fieldKit => 'What to bring';
  @override
  String get fieldNotes => 'Notes';
  @override
  String assignedTo(String name) => 'Lead: $name';
  @override
  String get startOnSet => 'Start On set';
  @override
  String get sharePrep => 'Share the prep page';
  @override
  String get shareTitle => 'Prep page link';
  @override
  String get shareHelp =>
      'Anyone with this link can read the prep list. They cannot change it.';
  @override
  String get copyLink => 'Copy link';
  @override
  String get linkCopied => 'Link copied';
  @override
  String get sendWhatsApp => 'Send on WhatsApp';
  @override
  String get newLink => 'Make a new link';
  @override
  String get newLinkWarning => 'The old link stops working.';
  @override
  String get shareFailed => 'Could not get the link. Try again.';
  @override
  String get addShot => 'Add a shot';
  @override
  String get editShot => 'Edit the shot';
  @override
  String get shotWhat => 'What we film';
  @override
  String get shotSetup => 'Set-up (where, props)';
  @override
  String get shotLineAr => 'Line in Arabic';
  @override
  String get shotLineEn => 'Line in English';
  @override
  String get save => 'Save';
  @override
  String get cancel => 'Cancel';
  @override
  String get prepNeedsConnection =>
      'The prep list needs a connection. Try again when you are online.';
  @override
  String get filmedMark => 'Filmed';
  @override
  String get notFilmedMark => 'Not filmed';
  @override
  String get shootNotFound =>
      'This shoot is not there. Go back to the shoot list.';
  @override
  String piecesCount(int n) => n == 1 ? '1 piece' : '$n pieces';

  @override
  String get editTitle => 'Edit the shoot';
  @override
  String get newTitle => 'Plan a shoot';
  @override
  String get fieldTitle => 'Name of the shoot';
  @override
  String get fieldDate => 'Date';
  @override
  String get fieldTime => 'Time';
  @override
  String get fieldStatus => 'Where it stands';
  @override
  String get pickDate => 'Pick a date';
  @override
  String get pickTime => 'Pick a time';
  @override
  String get clear => 'Clear';
  @override
  String get titleRequired => 'Give the shoot a name.';
  @override
  String get saved => 'Saved';
  @override
  String get changedMeanwhile =>
      'Someone changed this shoot since you opened it. The new version is on screen. Check it and save again.';
  @override
  String get editHelpTitle => 'Planning a shoot';
  @override
  List<String> get editHelp => const [
    'Give it a name, a date and a place.',
    'To mark it Ready, it needs a date and a brief on every shot.',
    'Saving shows the changes to everyone at once.',
  ];

  @override
  String get onSetTitle => 'On set';
  @override
  String shotOf(int i, int n) => '$i of $n';
  @override
  String get filmedButton => 'Filmed';
  @override
  String get filmedDone => 'Filmed. Tap to undo';
  @override
  String get noteLabel => 'Note on this shot';
  @override
  String get noteHint => 'What went well, what to redo';
  @override
  String get noteSaved => 'Note saved';
  @override
  String get next => 'Next';
  @override
  String get previous => 'Back';
  @override
  String get scriptLine => 'Script line';
  @override
  String get onScreenText => 'On-screen text';
  @override
  String get setupLabel => 'Set-up';
  @override
  String lengthSeconds(String s) => 'About $s seconds';
  @override
  String get referencesTitle => 'References';
  @override
  String get noReferences => 'No reference on this shot yet.';
  @override
  String get realReference => 'Real reference';
  @override
  String get madeReference => 'Made with AI';
  @override
  String get briefWhy => 'Why this shot';
  @override
  String get briefFrame => 'Frame';
  @override
  String get briefLight => 'Light';
  @override
  String get briefAction => 'Action';
  @override
  String get briefSound => 'Sound';
  @override
  String get briefAvoid => 'Avoid';
  @override
  String get briefCheck => 'Check before you move on';
  @override
  String get briefTakes => 'Takes';
  @override
  String get servesPieces => 'For these pieces';
  @override
  String get allFilmed => 'Every shot is filmed.';
  @override
  String get exitOnSet => 'Close On set';
  @override
  String get offlineBanner => 'No connection. Your ticks and notes are kept.';
  @override
  String waitingToSend(int n) =>
      n == 1 ? '1 change waiting to send' : '$n changes waiting to send';
  @override
  String get sendingNow => 'Sending your changes';
  @override
  String get allSent => 'All sent';
  @override
  String get sendNow => 'Send now';
  @override
  String piecesMoved(int n, String stage) =>
      n == 1 ? '1 piece moved to $stage' : '$n pieces moved to $stage';
  @override
  String refusedChange(String what) => 'Not accepted: $what';
  @override
  String get onSetHelpTitle => 'How On set works';
  @override
  List<String> get onSetHelp => const [
    'One shot at a time. Read the brief, film it, tap Filmed.',
    'No connection is fine. Ticks and notes wait on this phone.',
    'They go out by themselves, in order, when the connection is back.',
    'When a piece has all its shots, it moves on to editing.',
  ];

  @override
  String get errShadow =>
      'The Studio is not switched on yet, so nothing was changed.';
  @override
  String get errStale =>
      'This changed since you opened it. Refresh the page and try again.';
  @override
  String get errNotPermitted => 'Your role cannot do that.';
  @override
  String get errNetwork => 'No connection. Check the internet and try again.';
  @override
  String get errGeneric => 'Something went wrong. Try again.';
  @override
  String get errNotFound => 'This is no longer there. Go back and refresh.';

  @override
  String get prepPageTitle => 'Shoot prep';
  @override
  String get prepKit => 'What to bring';
  @override
  String get prepItems => 'Prep list';
  @override
  String get prepNoItems => 'Nothing on the prep list yet.';
  @override
  String get prepBadLinkTitle => 'This link does not work';
  @override
  String get prepBadLinkBody =>
      'It may be wrong or out of date. Ask for a new link.';
  @override
  String get prepTryAgainLater =>
      'Too many tries. Wait a minute and try again.';
  @override
  String get prepRead => 'Read only. Ticks are made by the Jarz team.';
}

class ShootStringsAr extends ShootStrings {
  const ShootStringsAr();

  @override
  bool get isArabic => true;
  @override
  String dateLabel(String? date, String? time) =>
      _date(date, time, _daysAr, _monthsAr);

  @override
  String get tabUpcoming => 'الجاية';
  @override
  String get tabPast => 'اللي فاتت';
  @override
  String get emptyUpcomingPurpose =>
      'التصويرات المخطط لها هتظهر هنا، مع قايمة التجهيز والشوتس.';
  @override
  String get emptyUpcomingFirst => 'خطّط لتصوير وابعت قايمة التجهيز للمطبخ.';
  @override
  String get emptyPastPurpose => 'التصويرات اللي خلصت هتظهر هنا.';
  @override
  String get emptyPastFirst =>
      'لسه مفيش تصوير خلص. غيّر حالة التصوير لـ «خلص» لما يخلص.';
  @override
  String get planShoot => 'خطّط لتصوير';
  @override
  String get noDateYet => 'مفيش ميعاد لسه';
  @override
  String shotsOf(int d, int t) => 'اتصوّر $d من $t شوت';
  @override
  String prepOf(int d, int t) => 'التجهيز $d من $t';
  @override
  String status(ShootStatus s) => switch (s) {
    ShootStatus.idea => 'فكرة',
    ShootStatus.prep => 'بيتجهّز',
    ShootStatus.ready => 'جاهز',
    ShootStatus.shot => 'اتصوّر',
    ShootStatus.done => 'خلص',
    ShootStatus.skipped => 'اتخطّى',
    ShootStatus.unknown => 'حاجة تانية',
  };
  @override
  String get loadMore => 'وريني أكتر';
  @override
  String get showingStoredCopy =>
      'مفيش نت. بنعرض النسخة المحفوظة على التليفون.';
  @override
  String get listHelpTitle => 'التصوير بيشتغل إزاي';
  @override
  List<String> get listHelp => const [
    'كل كارت هو يوم تصوير: إمتى وفين وجاهز قد إيه.',
    'افتح التصوير تشوف قايمة التجهيز وكارت لكل شوت.',
    'On set بيشتغل من غير نت: علّم كل شوت اتصوّر واكتب ملاحظة.',
    'ابعت صفحة التجهيز للمطبخ. مش محتاجين حساب.',
  ];

  @override
  String get sectionPlan => 'الخطة';
  @override
  String get sectionPrep => 'قايمة التجهيز';
  @override
  String get sectionShots => 'الشوتس';
  @override
  String get noPrep => 'مفيش مهام تجهيز لسه.';
  @override
  String get noShots => 'مفيش شوتس لسه. ضيف أول شوت.';
  @override
  String get notForPieceYet => 'لسه مش مربوط بقطعة';
  @override
  String get fieldPlace => 'المكان';
  @override
  String get fieldPeople => 'مين هيحضر';
  @override
  String get fieldKit => 'اللي هنجيبه';
  @override
  String get fieldNotes => 'ملاحظات';
  @override
  String assignedTo(String name) => 'المسؤول: $name';
  @override
  String get startOnSet => 'ابدأ On set';
  @override
  String get sharePrep => 'ابعت صفحة التجهيز';
  @override
  String get shareTitle => 'لينك صفحة التجهيز';
  @override
  String get shareHelp =>
      'أي حد معاه اللينك يقدر يقرا قايمة التجهيز، بس مش هيقدر يغيّر فيها.';
  @override
  String get copyLink => 'انسخ اللينك';
  @override
  String get linkCopied => 'اللينك اتنسخ';
  @override
  String get sendWhatsApp => 'ابعت على واتساب';
  @override
  String get newLink => 'اعمل لينك جديد';
  @override
  String get newLinkWarning => 'اللينك القديم مش هيشتغل تاني.';
  @override
  String get shareFailed => 'مقدرناش نجيب اللينك. جرّب تاني.';
  @override
  String get addShot => 'ضيف شوت';
  @override
  String get editShot => 'عدّل الشوت';
  @override
  String get shotWhat => 'هنصوّر إيه';
  @override
  String get shotSetup => 'الـ setup (المكان، الـ props)';
  @override
  String get shotLineAr => 'الجملة بالعربي';
  @override
  String get shotLineEn => 'الجملة بالإنجليزي';
  @override
  String get save => 'احفظ';
  @override
  String get cancel => 'إلغاء';
  @override
  String get prepNeedsConnection =>
      'قايمة التجهيز محتاجة نت. جرّب تاني لما النت يرجع.';
  @override
  String get filmedMark => 'اتصوّر';
  @override
  String get notFilmedMark => 'لسه ما اتصوّرش';
  @override
  String get shootNotFound => 'التصوير ده مش موجود. ارجع لقايمة التصويرات.';
  @override
  String piecesCount(int n) =>
      arCount(n, one: 'قطعة', two: 'قطعتين', few: 'قطع', many: 'قطعة');

  @override
  String get editTitle => 'عدّل التصوير';
  @override
  String get newTitle => 'خطّط لتصوير';
  @override
  String get fieldTitle => 'اسم التصوير';
  @override
  String get fieldDate => 'التاريخ';
  @override
  String get fieldTime => 'الساعة';
  @override
  String get fieldStatus => 'الحالة';
  @override
  String get pickDate => 'اختار تاريخ';
  @override
  String get pickTime => 'اختار ساعة';
  @override
  String get clear => 'امسح';
  @override
  String get titleRequired => 'اكتب اسم للتصوير.';
  @override
  String get saved => 'اتحفظ';
  @override
  String get changedMeanwhile =>
      'حد غيّر التصوير ده من ساعة ما فتحته. النسخة الجديدة قدامك. راجعها واحفظ تاني.';
  @override
  String get editHelpTitle => 'تخطيط تصوير';
  @override
  List<String> get editHelp => const [
    'اكتب اسم وتاريخ ومكان للتصوير.',
    'عشان تخلّيه «جاهز» لازم تاريخ وبريف على كل شوت.',
    'أول ما تحفظ، التغيير بيظهر للكل.',
  ];

  @override
  String get onSetTitle => 'On set';
  @override
  String shotOf(int i, int n) => '$i من $n';
  @override
  String get filmedButton => 'اتصوّر';
  @override
  String get filmedDone => 'اتصوّر. دوس للتراجع';
  @override
  String get noteLabel => 'ملاحظة على الشوت';
  @override
  String get noteHint => 'إيه اللي حلو وإيه اللي نعيده';
  @override
  String get noteSaved => 'الملاحظة اتحفظت';
  @override
  String get next => 'التالي';
  @override
  String get previous => 'رجوع';
  @override
  String get scriptLine => 'جملة السكريبت';
  @override
  String get onScreenText => 'الكلام على الشاشة';
  @override
  String get setupLabel => 'الـ setup';
  @override
  String lengthSeconds(String s) => 'حوالي $s ثانية';
  @override
  String get referencesTitle => 'المراجع';
  @override
  String get noReferences => 'مفيش مرجع على الشوت ده لسه.';
  @override
  String get realReference => 'مرجع حقيقي';
  @override
  String get madeReference => 'معمول بالـ AI';
  @override
  String get briefWhy => 'ليه الشوت ده';
  @override
  String get briefFrame => 'الكادر';
  @override
  String get briefLight => 'الإضاءة';
  @override
  String get briefAction => 'الحركة';
  @override
  String get briefSound => 'الصوت';
  @override
  String get briefAvoid => 'تجنّب';
  @override
  String get briefCheck => 'اتأكد قبل ما تكمّل';
  @override
  String get briefTakes => 'التيكات';
  @override
  String get servesPieces => 'للقطع دي';
  @override
  String get allFilmed => 'كل الشوتس اتصوّرت.';
  @override
  String get exitOnSet => 'اقفل On set';
  @override
  String get offlineBanner => 'مفيش نت. اللي علّمته والملاحظات محفوظين.';
  @override
  String waitingToSend(int n) => arCount(
    n,
    one: 'تغيير واحد مستني يتبعت',
    two: 'تغييرين مستنيين يتبعتوا',
    few: 'تغييرات مستنية تتبعت',
    many: 'تغيير مستني يتبعت',
  );
  @override
  String get sendingNow => 'بنبعت التغييرات';
  @override
  String get allSent => 'كله اتبعت';
  @override
  String get sendNow => 'ابعت دلوقتي';
  @override
  String piecesMoved(int n, String stage) =>
      '${arCount(n, one: 'قطعة واحدة اتنقلت', two: 'قطعتين اتنقلوا', few: 'قطع اتنقلت', many: 'قطعة اتنقلت')}. المرحلة الجديدة: $stage';
  @override
  String refusedChange(String what) => 'اترفض: $what';
  @override
  String get onSetHelpTitle => 'On set بيشتغل إزاي';
  @override
  List<String> get onSetHelp => const [
    'شوت شوت. اقرا البريف، صوّر، ودوس «اتصوّر».',
    'مفيش نت مش مشكلة. اللي علّمته والملاحظات بيستنوا على التليفون.',
    'بيتبعتوا لوحدهم بالترتيب لما النت يرجع.',
    'لما كل شوتس القطعة تتصوّر، بتروح للمونتاج.',
  ];

  @override
  String get errShadow => 'الـ Studio لسه مش شغّال، فمفيش حاجة اتغيّرت.';
  @override
  String get errStale => 'اتغيّر من ساعة ما فتحته. حدّث الصفحة وجرّب تاني.';
  @override
  String get errNotPermitted => 'مش مسموح لدورك.';
  @override
  String get errNetwork => 'مفيش نت. اتأكد من الاتصال وجرّب تاني.';
  @override
  String get errGeneric => 'حصلت مشكلة. جرّب تاني.';
  @override
  String get errNotFound => 'ده مبقاش موجود. ارجع وحدّث الصفحة.';

  @override
  String get prepPageTitle => 'تجهيز التصوير';
  @override
  String get prepKit => 'اللي هنجيبه';
  @override
  String get prepItems => 'قايمة التجهيز';
  @override
  String get prepNoItems => 'قايمة التجهيز فاضية لسه.';
  @override
  String get prepBadLinkTitle => 'اللينك ده مش شغّال';
  @override
  String get prepBadLinkBody => 'ممكن يكون غلط أو قديم. اطلب لينك جديد.';
  @override
  String get prepTryAgainLater => 'محاولات كتير. استنى دقيقة وجرّب تاني.';
  @override
  String get prepRead => 'للقراءة بس. العلامات بيعملها فريق Jarz.';
}
