import 'package:flutter/widgets.dart';

import '../../data/models/studio_enums.dart';

/// Texts of the Reports screen, English and Arabic, same pattern as
/// `StudioStrings`.
abstract class ReportsStrings {
  const ReportsStrings();

  static ReportsStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const ReportsStringsAr()
      : const ReportsStringsEn();

  String get title;
  String get helpTitle;
  List<String> get help;
  String get emptyPurpose;
  String get emptyFirstStep;
  String get emptyFiltered;
  String get searchHint;
  String kindLabel(ReportKind k);
  String get open;
  String openQuestions(int n);
  String get byClaude;
  String createdBy(String who);
}

class ReportsStringsEn extends ReportsStrings {
  const ReportsStringsEn();

  @override
  String get title => 'Reports';
  @override
  String get helpTitle => 'Reports';
  @override
  List<String> get help => const [
    'Every page Claude wrote, newest first.',
    'Filter by kind, or search by title and topic.',
    'Tap one to read it in the browser.',
    'Questions a report raises wait in Decisions.',
  ];
  @override
  String get emptyPurpose => 'Every page Claude produced, newest first.';
  @override
  String get emptyFirstStep =>
      'No reports yet. The first page Claude writes shows up here.';
  @override
  String get emptyFiltered =>
      'No report matches. Clear the search or the kind.';
  @override
  String get searchHint => 'Search by title or topic';
  @override
  String kindLabel(ReportKind k) => switch (k) {
    ReportKind.adsRead => 'Ads read',
    ReportKind.plan => 'Plan',
    ReportKind.study => 'Study',
    ReportKind.retro => 'Retro',
    ReportKind.competitorDaily => 'Competitor daily',
    ReportKind.referenceIntake => 'New references',
    ReportKind.weeklyWorkingNow => 'What is working now',
    ReportKind.sundayReview => 'Sunday review',
    ReportKind.other => 'Other',
    ReportKind.unknown => 'Other',
  };
  @override
  String get open => 'Open';
  @override
  String openQuestions(int n) =>
      n == 1 ? '1 question waiting' : '$n questions waiting';
  @override
  String get byClaude => 'Claude';
  @override
  String createdBy(String who) => 'By $who';
}

class ReportsStringsAr extends ReportsStrings {
  const ReportsStringsAr();

  @override
  String get title => 'التقارير';
  @override
  String get helpTitle => 'التقارير';
  @override
  List<String> get help => const [
    'كل صفحة Claude كتبها، الأحدث الأول.',
    'فلتر بالنوع، أو دوّر بالعنوان والموضوع.',
    'اضغط على أي واحد تقراه في المتصفح.',
    'الأسئلة اللي التقرير بيفتحها مستنية في القرارات.',
  ];
  @override
  String get emptyPurpose => 'كل صفحة Claude عملها، الأحدث الأول.';
  @override
  String get emptyFirstStep =>
      'مفيش تقارير لسه. أول صفحة Claude يكتبها هتظهر هنا.';
  @override
  String get emptyFiltered => 'مفيش تقرير بيطابق. امسح البحث أو النوع.';
  @override
  String get searchHint => 'دوّر بالعنوان أو الموضوع';
  @override
  String kindLabel(ReportKind k) => switch (k) {
    ReportKind.adsRead => 'قراءة الإعلانات',
    ReportKind.plan => 'خطة',
    ReportKind.study => 'دراسة',
    ReportKind.retro => 'مراجعة بعد التنفيذ',
    ReportKind.competitorDaily => 'المنافسين اليومي',
    ReportKind.referenceIntake => 'مراجع جديدة',
    ReportKind.weeklyWorkingNow => 'اللي شغّال دلوقتي',
    ReportKind.sundayReview => 'مراجعة الأحد',
    ReportKind.other => 'تاني',
    ReportKind.unknown => 'تاني',
  };
  @override
  String get open => 'افتح';
  @override
  String openQuestions(int n) => n == 1 ? 'سؤال واحد مستني' : '$n أسئلة مستنية';
  @override
  String get byClaude => 'Claude';
  @override
  String createdBy(String who) => 'بواسطة $who';
}
