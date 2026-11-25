import 'package:flutter/widgets.dart';

import '../../data/models/studio_enums.dart';

/// Texts of the Results screens (scorecard, results by piece, summary),
/// English and Arabic, same pattern as `StudioStrings`.
abstract class ResultsStrings {
  const ResultsStrings();

  static ResultsStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const ResultsStringsAr()
      : const ResultsStringsEn();

  // ---- Scorecard ---------------------------------------------------------
  String get title;
  String get helpTitle;
  List<String> get help;
  String get emptyPurpose;
  String get emptyFirstStep;
  String weekLabel(String from, String to);
  String get previousWeek;
  String get nextWeek;
  String statusLabel(ScorecardStatus s);
  String get numbersTitle;
  String get gatesTitle;
  String gatesHeld(int weeks);
  String get linesTitle;
  String get noLines;
  String get reviewNotes;
  String get actionsAgreed;
  String get nothingWritten;
  String reviewedBy(String name, String when);
  String get againstLine;
  String get aboveLine;
  String get belowLine;
  String get noLineToJudge;
  String sourceLabel(ScoreSource s);
  String get seeByPiece;
  String get seeSummary;

  // ---- Scorecard actions -------------------------------------------------
  String get editNotes;
  String get editNotesTitle;
  String get addLine;
  String get addLineTitle;
  String get lineLabelHint;
  String get lineValueHint;
  String get markReviewed;
  String get notesSaved;
  String get lineAdded;
  String get reviewedOk;
  String get lineNeedsBoth;

  // ---- By piece ----------------------------------------------------------
  String get piecesTitle;
  String get piecesHelpTitle;
  List<String> get piecesHelp;
  String get piecesEmptyPurpose;
  String get piecesEmptyFirstStep;
  String get sortBy;
  String sortLabel(String wire);
  String get bestViews;
  String get bestHold;
  String postsCount(int n);
  String adsCount(int n);
  String get readsTitle;
  String get readDueNow;
  String get readFiled;
  String get readNotOpen;
  String get fileRead;

  // ---- Filing the 72-hour read ------------------------------------------
  String get fileReadTitle;
  String get fileReadHelp;
  String get fileReadSend;
  String get fileReadNothingMissing;
  String get readFiledOk;
  String get readAlreadyFiled;
  String fieldLabel(String key);

  // ---- Summary -----------------------------------------------------------
  String get summaryTitle;
  String get summaryHelpTitle;
  List<String> get summaryHelp;
  String get summaryEmptyPurpose;
  String get summaryEmptyFirstStep;
  String get groupBy;
  String groupByLabel(String wire);
  String lastDays(int n);
  String get avgViews;
  String get avgHold;
  String get spendLabel;
  String get purchasesLabel;
  String piecesLine(int pieces, int posts, int reads);
}

class ResultsStringsEn extends ResultsStrings {
  const ResultsStringsEn();

  @override
  String get title => 'Results';
  @override
  String get helpTitle => 'Results';
  @override
  List<String> get help => const [
    'The Sunday scorecard fills itself in. Lines marked by the system are read only.',
    'Add only what the system cannot read, as a line with a name and a value.',
    'Review it together on Sunday, then mark it reviewed.',
    'Results by piece and the summary sit one tap away.',
  ];
  @override
  String get emptyPurpose =>
      'The scorecard, and results by piece, format and persona.';
  @override
  String get emptyFirstStep =>
      'No scorecard yet. It fills in as pieces are read and ads report.';
  @override
  String weekLabel(String from, String to) => '$from to $to';
  @override
  String get previousWeek => 'Week before';
  @override
  String get nextWeek => 'Week after';
  @override
  String statusLabel(ScorecardStatus s) => switch (s) {
    ScorecardStatus.filling => 'Still filling in',
    ScorecardStatus.ready => 'Ready to review',
    ScorecardStatus.reviewed => 'Reviewed',
    ScorecardStatus.unknown => 'Other',
  };
  @override
  String get numbersTitle => 'Numbers';
  @override
  String get gatesTitle => 'Spend gates';
  @override
  String gatesHeld(int weeks) => weeks == 1
      ? 'All gates held for 1 week in a row'
      : 'All gates held for $weeks weeks in a row';
  @override
  String get linesTitle => 'Added by people';
  @override
  String get noLines => 'Nobody has added a line this week.';
  @override
  String get reviewNotes => 'Review notes';
  @override
  String get actionsAgreed => 'What we agreed to do';
  @override
  String get nothingWritten => 'Nothing written yet.';
  @override
  String reviewedBy(String name, String when) => 'Reviewed by $name, $when';
  @override
  String get againstLine => 'Line';
  @override
  String get aboveLine => 'Meets the line';
  @override
  String get belowLine => 'Misses the line';
  @override
  String get noLineToJudge => 'No line to judge by';
  @override
  String sourceLabel(ScoreSource s) => switch (s) {
    ScoreSource.system => 'Filled by the system',
    ScoreSource.person => 'Added by hand',
    ScoreSource.missing => 'Missing, nobody has added it',
    ScoreSource.unknown => 'Other',
  };
  @override
  String get seeByPiece => 'Results by piece';
  @override
  String get seeSummary => 'Summary by format and persona';

  @override
  String get editNotes => 'Write the review';
  @override
  String get editNotesTitle => 'The Sunday review';
  @override
  String get addLine => 'Add a line';
  @override
  String get addLineTitle => 'A number the system cannot read';
  @override
  String get lineLabelHint => 'What is it? (for example Walk-in orders)';
  @override
  String get lineValueHint => 'The value';
  @override
  String get markReviewed => 'Mark as reviewed';
  @override
  String get notesSaved => 'Review saved';
  @override
  String get lineAdded => 'Line added';
  @override
  String get reviewedOk => 'Marked as reviewed';
  @override
  String get lineNeedsBoth => 'Write what it is and its value.';

  @override
  String get piecesTitle => 'Results by piece';
  @override
  String get piecesHelpTitle => 'Results by piece';
  @override
  List<String> get piecesHelp => const [
    'Each piece with its posts, reads and ads.',
    'Views and hold are shown as read from the platforms.',
    'When a 72-hour read is open and the API missed numbers, add them here.',
  ];
  @override
  String get piecesEmptyPurpose => 'How each piece did once it went out.';
  @override
  String get piecesEmptyFirstStep =>
      'No results yet. They appear a few days after a piece is posted.';
  @override
  String get sortBy => 'Sort by';
  @override
  String sortLabel(String wire) => switch (wire) {
    'views' => 'Most views',
    'hold3' => 'Best hold',
    _ => 'Newest',
  };
  @override
  String get bestViews => 'Best views';
  @override
  String get bestHold => 'Best hold past 3 seconds';
  @override
  String postsCount(int n) => n == 1 ? '1 post' : '$n posts';
  @override
  String adsCount(int n) => n == 1 ? '1 ad' : '$n ads';
  @override
  String get readsTitle => 'Reads';
  @override
  String get readDueNow => '72-hour read is open';
  @override
  String get readFiled => 'Filed';
  @override
  String get readNotOpen => 'Opens later';
  @override
  String get fileRead => 'File the read';

  @override
  String get fileReadTitle => 'File the 72-hour read';
  @override
  String get fileReadHelp =>
      'Fill only what is missing. The rest came from the platform.';
  @override
  String get fileReadSend => 'File it';
  @override
  String get fileReadNothingMissing => 'Nothing is missing. File it as it is.';
  @override
  String get readFiledOk => 'Read filed';
  @override
  String get readAlreadyFiled => 'Already filed. Showing it as filed.';
  @override
  String fieldLabel(String key) => switch (key) {
    'views' => 'Views',
    'reach' => 'Reach',
    'sends' => 'Sends',
    'shares' => 'Shares',
    'likes' => 'Likes',
    'saves' => 'Saves',
    'comments_count' => 'Comments',
    'hold3_pct' => 'Held past 3 seconds (%)',
    'avg_watch_s' => 'Average watch time (seconds)',
    'reel_len_s' => 'Reel length (seconds)',
    _ => key.replaceAll('_', ' '),
  };

  @override
  String get summaryTitle => 'Summary';
  @override
  String get summaryHelpTitle => 'The summary';
  @override
  List<String> get summaryHelp => const [
    'Groups pieces by format, persona, situation, layer, flavor or series.',
    'Bars are drawn against the best group, so you can compare at a glance.',
    'Choose how far back to look.',
  ];
  @override
  String get summaryEmptyPurpose => 'Which kind of piece does best.';
  @override
  String get summaryEmptyFirstStep =>
      'Nothing in this period. Try a longer period.';
  @override
  String get groupBy => 'Group by';
  @override
  String groupByLabel(String wire) => switch (wire) {
    'format' => 'Format',
    'persona' => 'Persona',
    'situation' => 'Situation',
    'layer' => 'Layer',
    'flavour' => 'Flavor',
    'series' => 'Series',
    _ => wire,
  };
  @override
  String lastDays(int n) => 'Last $n days';
  @override
  String get avgViews => 'Average views';
  @override
  String get avgHold => 'Average hold';
  @override
  String get spendLabel => 'Spend';
  @override
  String get purchasesLabel => 'Purchases';
  @override
  String piecesLine(int pieces, int posts, int reads) =>
      '$pieces pieces, $posts posts, $reads reads';
}

class ResultsStringsAr extends ResultsStrings {
  const ResultsStringsAr();

  @override
  String get title => 'النتائج';
  @override
  String get helpTitle => 'النتائج';
  @override
  List<String> get help => const [
    'لوحة الأحد بتتملي لوحدها. السطور اللي عليها علامة النظام للقراءة بس.',
    'ضيف بس اللي النظام مش قادر يقراه، كسطر باسم وقيمة.',
    'راجعوها مع بعض يوم الأحد، وبعدين علّمها إنها اتراجعت.',
    'نتايج كل قطعة والملخص على بعد ضغطة.',
  ];
  @override
  String get emptyPurpose => 'لوحة الأحد، ونتايج القطع بالنوع والـ persona.';
  @override
  String get emptyFirstStep =>
      'مفيش لوحة لسه. بتتملي مع قراءة القطع وتقارير الإعلانات.';
  @override
  String weekLabel(String from, String to) => 'من $from إلى $to';
  @override
  String get previousWeek => 'الأسبوع اللي فات';
  @override
  String get nextWeek => 'الأسبوع الجاي';
  @override
  String statusLabel(ScorecardStatus s) => switch (s) {
    ScorecardStatus.filling => 'لسه بتتملي',
    ScorecardStatus.ready => 'جاهزة للمراجعة',
    ScorecardStatus.reviewed => 'اتراجعت',
    ScorecardStatus.unknown => 'تاني',
  };
  @override
  String get numbersTitle => 'الأرقام';
  @override
  String get gatesTitle => 'شروط زيادة الصرف';
  @override
  String gatesHeld(int weeks) => weeks == 1
      ? 'كل الشروط متحققة من أسبوع'
      : 'كل الشروط متحققة من $weeks أسابيع ورا بعض';
  @override
  String get linesTitle => 'اللي اتضاف بإيد حد';
  @override
  String get noLines => 'محدش ضاف سطر الأسبوع ده.';
  @override
  String get reviewNotes => 'ملاحظات المراجعة';
  @override
  String get actionsAgreed => 'اللي اتفقنا نعمله';
  @override
  String get nothingWritten => 'مفيش حاجة مكتوبة لسه.';
  @override
  String reviewedBy(String name, String when) => 'راجعها $name، $when';
  @override
  String get againstLine => 'الخط';
  @override
  String get aboveLine => 'عدّى الخط';
  @override
  String get belowLine => 'ماوصلش للخط';
  @override
  String get noLineToJudge => 'مفيش خط نقيس عليه';
  @override
  String sourceLabel(ScoreSource s) => switch (s) {
    ScoreSource.system => 'النظام ملاه',
    ScoreSource.person => 'اتضاف بإيد',
    ScoreSource.missing => 'ناقص، محدش ضافه',
    ScoreSource.unknown => 'تاني',
  };
  @override
  String get seeByPiece => 'نتايج كل قطعة';
  @override
  String get seeSummary => 'ملخص بالنوع والـ persona';

  @override
  String get editNotes => 'اكتب المراجعة';
  @override
  String get editNotesTitle => 'مراجعة الأحد';
  @override
  String get addLine => 'ضيف سطر';
  @override
  String get addLineTitle => 'رقم النظام مش قادر يقراه';
  @override
  String get lineLabelHint => 'إيه هو؟ (مثلا أوردرات الفرع)';
  @override
  String get lineValueHint => 'القيمة';
  @override
  String get markReviewed => 'علّمها إنها اتراجعت';
  @override
  String get notesSaved => 'المراجعة اتحفظت';
  @override
  String get lineAdded => 'السطر اتضاف';
  @override
  String get reviewedOk => 'اتعلّمت إنها اتراجعت';
  @override
  String get lineNeedsBoth => 'اكتب إيه هو وقيمته.';

  @override
  String get piecesTitle => 'نتايج كل قطعة';
  @override
  String get piecesHelpTitle => 'نتايج كل قطعة';
  @override
  List<String> get piecesHelp => const [
    'كل قطعة بالبوستات والقراءات والإعلانات بتاعتها.',
    'المشاهدات والـ hold زي ما اتقرت من المنصات.',
    'لما قراءة الـ 72 ساعة تبقى مفتوحة والـ API فاته أرقام، ضيفها هنا.',
  ];
  @override
  String get piecesEmptyPurpose => 'كل قطعة عملت إيه بعد ما نزلت.';
  @override
  String get piecesEmptyFirstStep =>
      'مفيش نتايج لسه. بتظهر بعد البوست بكام يوم.';
  @override
  String get sortBy => 'رتّب حسب';
  @override
  String sortLabel(String wire) => switch (wire) {
    'views' => 'الأكتر مشاهدة',
    'hold3' => 'أحسن hold',
    _ => 'الأحدث',
  };
  @override
  String get bestViews => 'أعلى مشاهدات';
  @override
  String get bestHold => 'أعلى كمّلوا بعد 3 ثواني';
  @override
  String postsCount(int n) => n == 1 ? 'بوست واحد' : '$n بوستات';
  @override
  String adsCount(int n) => n == 1 ? 'إعلان واحد' : '$n إعلانات';
  @override
  String get readsTitle => 'القراءات';
  @override
  String get readDueNow => 'قراءة الـ 72 ساعة مفتوحة';
  @override
  String get readFiled => 'اتسجلت';
  @override
  String get readNotOpen => 'بتفتح بعدين';
  @override
  String get fileRead => 'سجّل القراءة';

  @override
  String get fileReadTitle => 'سجّل قراءة الـ 72 ساعة';
  @override
  String get fileReadHelp => 'املا الناقص بس. الباقي جه من المنصة.';
  @override
  String get fileReadSend => 'سجّلها';
  @override
  String get fileReadNothingMissing => 'مفيش حاجة ناقصة. سجّلها زي ما هي.';
  @override
  String get readFiledOk => 'القراءة اتسجلت';
  @override
  String get readAlreadyFiled => 'اتسجلت قبل كده. بنعرضها كمسجّلة.';
  @override
  String fieldLabel(String key) => switch (key) {
    'views' => 'المشاهدات',
    'reach' => 'الوصول',
    'sends' => 'الإرسال',
    'shares' => 'المشاركات',
    'likes' => 'الإعجابات',
    'saves' => 'الحفظ',
    'comments_count' => 'التعليقات',
    'hold3_pct' => 'كمّلوا بعد 3 ثواني (%)',
    'avg_watch_s' => 'متوسط وقت المشاهدة (ثواني)',
    'reel_len_s' => 'طول الـ reel (ثواني)',
    _ => key.replaceAll('_', ' '),
  };

  @override
  String get summaryTitle => 'الملخص';
  @override
  String get summaryHelpTitle => 'الملخص';
  @override
  List<String> get summaryHelp => const [
    'بيجمّع القطع بالنوع أو الـ persona أو الموقف أو الطبقة أو الـ flavor أو السلسلة.',
    'الأعمدة بتتقاس على أحسن مجموعة، فتقارن بنظرة.',
    'اختار تبص لورا قد إيه.',
  ];
  @override
  String get summaryEmptyPurpose => 'أنهي نوع قطع بيعمل أحسن.';
  @override
  String get summaryEmptyFirstStep => 'مفيش حاجة في الفترة دي. جرّب فترة أطول.';
  @override
  String get groupBy => 'جمّع حسب';
  @override
  String groupByLabel(String wire) => switch (wire) {
    'format' => 'النوع',
    'persona' => 'Persona',
    'situation' => 'الموقف',
    'layer' => 'الطبقة',
    'flavour' => 'Flavor',
    'series' => 'السلسلة',
    _ => wire,
  };
  @override
  String lastDays(int n) => 'آخر $n يوم';
  @override
  String get avgViews => 'متوسط المشاهدات';
  @override
  String get avgHold => 'متوسط الـ hold';
  @override
  String get spendLabel => 'الصرف';
  @override
  String get purchasesLabel => 'المشتريات';
  @override
  String piecesLine(int pieces, int posts, int reads) =>
      '$pieces قطع، $posts بوستات، $reads قراءات';
}
