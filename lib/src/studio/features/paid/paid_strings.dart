import 'package:flutter/widgets.dart';

import '../../data/models/studio_enums.dart';

/// Texts of the Paid screens (overview, queue, round), English and Arabic,
/// same pattern as `StudioStrings`. Ad words people say in English (ad set,
/// CTR, reach) stay in English inside Arabic.
abstract class PaidStrings {
  const PaidStrings();

  static PaidStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const PaidStringsAr()
      : const PaidStringsEn();

  // ---- Overview ----------------------------------------------------------
  String get title;
  String get helpTitle;
  List<String> get help;
  String get emptyPurpose;
  String get emptyFirstStep;
  String asOf(String when);
  String get dueNow;
  String get nothingDue;
  String get liveRounds;
  String get noRounds;
  String get stopSigns;
  String get noStopSigns;
  String get queueSection;
  String get queueEmptyShort;
  String get seeQueue;
  String get readOnlyNote;
  String launches(String date);
  String adsCount(int n);
  String dueKindLabel(PaidDueKind k);
  String dueOn(String date);

  // ---- Queue -------------------------------------------------------------
  String get queueTitle;
  String get queueHelpTitle;
  List<String> get queueHelp;
  String get queueEmptyPurpose;
  String get queueEmptyFirstStep;
  String get addVersion;
  String rankLabel(int n);
  String get readyForAds;
  String get notReadyForAds;
  String get dragToReorder;
  String get removeTitle;
  String removeBody(String name);
  String get removeConfirm;
  String get noteLabel;
  String get addSheetTitle;
  String get addSheetHelp;
  String get noCandidates;
  String get addNoteHint;
  String get addConfirm;
  String get added;
  String get removedOk;
  String get reorderedOk;
  String versionNo(int n);

  // ---- Round -------------------------------------------------------------
  String get roundTitle;
  String get roundHelpTitle;
  List<String> get roundHelp;
  String get roundEmptyPurpose;
  String get roundEmptyFirstStep;
  String get launchDate;
  String get dayFourRead;
  String get daySevenRead;
  String get assignedTo;
  String get spend;
  String get purchases;
  String get costPerPurchase;
  String get noPurchasesYet;
  String get purchaseValue;
  String get diagnosticsTitle;
  String get diagnosticsNote;
  String get ctr;
  String get frequency;
  String get hold3;
  String get rulesSay;
  String get noNumbersYet;
  String get setState;
  String get setStateTitle;
  String get setStateNoteHint;
  String get clearState;
  String stateLabel(AdState? s);
  String stateSaved(String label);
  String get editRound;
  String get roundTitleField;
  String get roundNoteField;
  String get roundSaved;
  String get noAds;
  String readDueLabel(String window);
  String get adNoteLabel;
}

class PaidStringsEn extends PaidStrings {
  const PaidStringsEn();

  @override
  String get title => 'Paid';
  @override
  String get helpTitle => 'Paid';
  @override
  List<String> get help => const [
    'Shows what is due now and why, the live rounds and the stop signs.',
    'The numbers come from Meta by themselves. Nobody types them.',
    'The rules say what each ad should do; you set its state.',
    'The queue holds what goes into the next round.',
    'The action itself (budget, launch) still happens in Ads Manager.',
  ];
  @override
  String get emptyPurpose =>
      'Rounds, each ad with its numbers, and what is due today.';
  @override
  String get emptyFirstStep =>
      'No round is running. Add a version to the queue to start the next one.';
  @override
  String asOf(String when) => 'Numbers as of $when';
  @override
  String get dueNow => 'Due now';
  @override
  String get nothingDue => 'Nothing is due today.';
  @override
  String get liveRounds => 'Rounds';
  @override
  String get noRounds => 'No round yet.';
  @override
  String get stopSigns => 'Stop signs';
  @override
  String get noStopSigns => 'No stop signs. Nothing needs stopping.';
  @override
  String get queueSection => 'Next in the queue';
  @override
  String get queueEmptyShort => 'The queue is empty.';
  @override
  String get seeQueue => 'Open the queue';
  @override
  String get readOnlyNote => 'You can read this page. The founder changes it.';
  @override
  String launches(String date) => 'Launches $date';
  @override
  String adsCount(int n) => n == 1 ? '1 ad' : '$n ads';
  @override
  String dueKindLabel(PaidDueKind k) => switch (k) {
    PaidDueKind.readD4 => 'Day 4 read',
    PaidDueKind.readD7 => 'Day 7 read',
    PaidDueKind.roundLaunch => 'Round launch',
    PaidDueKind.budgetStep => 'Budget step',
    PaidDueKind.retire => 'Retire check',
    PaidDueKind.stepGate => 'Spend gate check',
    PaidDueKind.unknown => 'To do',
  };
  @override
  String dueOn(String date) => 'Due $date';

  @override
  String get queueTitle => 'Ad queue';
  @override
  String get queueHelpTitle => 'The ad queue';
  @override
  List<String> get queueHelp => const [
    'These versions are lined up for the next round, first in line on top.',
    'Hold the handle and drag to change the order.',
    'Add a version once it is ready for ads. If one is refused, the reason shows.',
    'Remove a version only while it is still waiting here.',
  ];
  @override
  String get queueEmptyPurpose => 'What goes into the next round, in order.';
  @override
  String get queueEmptyFirstStep =>
      'The queue is empty. Add a version that is ready for ads.';
  @override
  String get addVersion => 'Add a version';
  @override
  String rankLabel(int n) => '#$n';
  @override
  String get readyForAds => 'Ready for ads';
  @override
  String get notReadyForAds => 'Not ready for ads';
  @override
  String get dragToReorder => 'Hold and drag to change the order';
  @override
  String get removeTitle => 'Take it out of the queue?';
  @override
  String removeBody(String name) => '$name will leave the queue.';
  @override
  String get removeConfirm => 'Take it out';
  @override
  String get noteLabel => 'Note';
  @override
  String get addSheetTitle => 'Add to the queue';
  @override
  String get addSheetHelp => 'Only versions that are ready for ads are listed.';
  @override
  String get noCandidates =>
      'No version is ready for ads right now. A version is ready once it is '
      'approved and has an ad route.';
  @override
  String get addNoteHint => 'A note for the round (optional)';
  @override
  String get addConfirm => 'Add to queue';
  @override
  String get added => 'Added to the queue';
  @override
  String get removedOk => 'Taken out of the queue';
  @override
  String get reorderedOk => 'New order saved';
  @override
  String versionNo(int n) => 'Version $n';

  @override
  String get roundTitle => 'Round';
  @override
  String get roundHelpTitle => 'A round';
  @override
  List<String> get roundHelp => const [
    'Each ad shows spend, purchases and cost per purchase. Purchases decide.',
    'Hold and CTR are shown as diagnostics only.',
    'The line from the rules says what the ad should do and why.',
    'You set the ad state yourself. The app never sets it for you.',
  ];
  @override
  String get roundEmptyPurpose => 'A test round and the ads in it.';
  @override
  String get roundEmptyFirstStep =>
      'This round has no ads yet. Give a queued ad to this round to start.';
  @override
  String get launchDate => 'Launch date';
  @override
  String get dayFourRead => 'Day 4 read';
  @override
  String get daySevenRead => 'Day 7 read';
  @override
  String get assignedTo => 'Owner';
  @override
  String get spend => 'Spend';
  @override
  String get purchases => 'Purchases';
  @override
  String get costPerPurchase => 'Cost per purchase';
  @override
  String get noPurchasesYet => 'No purchases yet';
  @override
  String get purchaseValue => 'Sales';
  @override
  String get diagnosticsTitle => 'Diagnostics';
  @override
  String get diagnosticsNote => 'For understanding only. They do not decide.';
  @override
  String get ctr => 'CTR';
  @override
  String get frequency => 'Frequency';
  @override
  String get hold3 => 'Held past 3 seconds';
  @override
  String get rulesSay => 'What the rules say';
  @override
  String get noNumbersYet => 'No numbers yet. They arrive with the next sync.';
  @override
  String get setState => 'Set state';
  @override
  String get setStateTitle => 'What happens to this ad?';
  @override
  String get setStateNoteHint => 'A note (optional)';
  @override
  String get clearState => 'Clear the state';
  @override
  String stateLabel(AdState? s) => switch (s) {
    null => 'Not set',
    AdState.queued => 'In the queue',
    AdState.testing => 'Testing',
    AdState.winner => 'Winner',
    AdState.oneMoreRound => 'One more round',
    AdState.off => 'Off',
    AdState.inScale => 'Scaling',
    AdState.unknown => 'Other',
  };
  @override
  String stateSaved(String label) => 'Now: $label';
  @override
  String get editRound => 'Edit the round';
  @override
  String get roundTitleField => 'Name';
  @override
  String get roundNoteField => 'Note';
  @override
  String get roundSaved => 'Round saved';
  @override
  String get noAds => 'No ads in this round yet.';
  @override
  String readDueLabel(String window) => 'Read due: $window';
  @override
  String get adNoteLabel => 'Note';
}

class PaidStringsAr extends PaidStrings {
  const PaidStringsAr();

  @override
  String get title => 'الإعلانات';
  @override
  String get helpTitle => 'الإعلانات';
  @override
  List<String> get help => const [
    'بيعرض إيه المطلوب دلوقتي وليه، والجولات الشغّالة وعلامات الوقف.',
    'الأرقام بتيجي من Meta لوحدها. محدش بيكتبها.',
    'القواعد بتقول كل إعلان المفروض يعمل إيه؛ وانت اللي بتحدد حالته.',
    'الطابور فيه اللي داخل الجولة الجاية.',
    'التنفيذ نفسه (الميزانية، الإطلاق) لسه في Ads Manager.',
  ];
  @override
  String get emptyPurpose =>
      'الجولات، وكل إعلان بأرقامه، وإيه المطلوب النهارده.';
  @override
  String get emptyFirstStep =>
      'مفيش جولة شغّالة. ضيف نسخة للطابور تبدأ الجولة الجاية.';
  @override
  String asOf(String when) => 'الأرقام لحد $when';
  @override
  String get dueNow => 'مطلوب دلوقتي';
  @override
  String get nothingDue => 'مفيش حاجة مطلوبة النهارده.';
  @override
  String get liveRounds => 'الجولات';
  @override
  String get noRounds => 'مفيش جولة لسه.';
  @override
  String get stopSigns => 'علامات الوقف';
  @override
  String get noStopSigns => 'مفيش علامات وقف. مفيش حاجة تتوقف.';
  @override
  String get queueSection => 'الجاي في الطابور';
  @override
  String get queueEmptyShort => 'الطابور فاضي.';
  @override
  String get seeQueue => 'افتح الطابور';
  @override
  String get readOnlyNote => 'تقدر تقرا الصفحة دي. المؤسس هو اللي بيغيّر.';
  @override
  String launches(String date) => 'بتبدأ $date';
  @override
  String adsCount(int n) => n == 1 ? 'إعلان واحد' : '$n إعلانات';
  @override
  String dueKindLabel(PaidDueKind k) => switch (k) {
    PaidDueKind.readD4 => 'قراءة اليوم 4',
    PaidDueKind.readD7 => 'قراءة اليوم 7',
    PaidDueKind.roundLaunch => 'إطلاق جولة',
    PaidDueKind.budgetStep => 'خطوة ميزانية',
    PaidDueKind.retire => 'مراجعة إيقاف',
    PaidDueKind.stepGate => 'مراجعة شروط زيادة الصرف',
    PaidDueKind.unknown => 'مطلوب',
  };
  @override
  String dueOn(String date) => 'ميعاده $date';

  @override
  String get queueTitle => 'طابور الإعلانات';
  @override
  String get queueHelpTitle => 'طابور الإعلانات';
  @override
  List<String> get queueHelp => const [
    'النسخ دي مستنية الجولة الجاية، الأول في الطابور فوق.',
    'اضغط على المقبض واسحب تغيّر الترتيب.',
    'ضيف نسخة لما تبقى جاهزة للإعلانات. لو اترفضت هيظهر السبب.',
    'شيل النسخة وهي لسه مستنية هنا بس.',
  ];
  @override
  String get queueEmptyPurpose => 'اللي داخل الجولة الجاية، بالترتيب.';
  @override
  String get queueEmptyFirstStep => 'الطابور فاضي. ضيف نسخة جاهزة للإعلانات.';
  @override
  String get addVersion => 'ضيف نسخة';
  @override
  String rankLabel(int n) => '#$n';
  @override
  String get readyForAds => 'جاهزة للإعلانات';
  @override
  String get notReadyForAds => 'مش جاهزة للإعلانات';
  @override
  String get dragToReorder => 'اضغط واسحب تغيّر الترتيب';
  @override
  String get removeTitle => 'تشيلها من الطابور؟';
  @override
  String removeBody(String name) => '$name هتخرج من الطابور.';
  @override
  String get removeConfirm => 'شيلها';
  @override
  String get noteLabel => 'ملاحظة';
  @override
  String get addSheetTitle => 'ضيف للطابور';
  @override
  String get addSheetHelp => 'بنعرض بس النسخ الجاهزة للإعلانات.';
  @override
  String get noCandidates =>
      'مفيش نسخة جاهزة للإعلانات دلوقتي. النسخة بتبقى جاهزة لما تتوافق '
      'ويبقى لها مسار إعلان.';
  @override
  String get addNoteHint => 'ملاحظة للجولة (اختياري)';
  @override
  String get addConfirm => 'ضيف للطابور';
  @override
  String get added => 'اتضافت للطابور';
  @override
  String get removedOk => 'اتشالت من الطابور';
  @override
  String get reorderedOk => 'الترتيب الجديد اتحفظ';
  @override
  String versionNo(int n) => 'نسخة $n';

  @override
  String get roundTitle => 'جولة';
  @override
  String get roundHelpTitle => 'الجولة';
  @override
  List<String> get roundHelp => const [
    'كل إعلان بيعرض الصرف والمشتريات وتكلفة المشتريات. المشتريات هي اللي بتحسم.',
    'الـ hold والـ CTR للمتابعة بس.',
    'سطر القواعد بيقول الإعلان المفروض يعمل إيه وليه.',
    'انت اللي بتحدد حالة الإعلان. التطبيق مبيحددهاش لوحده.',
  ];
  @override
  String get roundEmptyPurpose => 'جولة اختبار والإعلانات اللي فيها.';
  @override
  String get roundEmptyFirstStep =>
      'الجولة دي مفيهاش إعلانات لسه. ادّي إعلان من الطابور للجولة دي.';
  @override
  String get launchDate => 'تاريخ الإطلاق';
  @override
  String get dayFourRead => 'قراءة اليوم 4';
  @override
  String get daySevenRead => 'قراءة اليوم 7';
  @override
  String get assignedTo => 'المسؤول';
  @override
  String get spend => 'الصرف';
  @override
  String get purchases => 'المشتريات';
  @override
  String get costPerPurchase => 'تكلفة المشترى';
  @override
  String get noPurchasesYet => 'مفيش مشتريات لسه';
  @override
  String get purchaseValue => 'المبيعات';
  @override
  String get diagnosticsTitle => 'للمتابعة';
  @override
  String get diagnosticsNote => 'للفهم بس. مش هي اللي بتحسم.';
  @override
  String get ctr => 'CTR';
  @override
  String get frequency => 'التكرار';
  @override
  String get hold3 => 'كمّلوا بعد 3 ثواني';
  @override
  String get rulesSay => 'القواعد بتقول إيه';
  @override
  String get noNumbersYet => 'مفيش أرقام لسه. هتيجي مع المزامنة الجاية.';
  @override
  String get setState => 'حدد الحالة';
  @override
  String get setStateTitle => 'هيحصل إيه للإعلان ده؟';
  @override
  String get setStateNoteHint => 'ملاحظة (اختياري)';
  @override
  String get clearState => 'امسح الحالة';
  @override
  String stateLabel(AdState? s) => switch (s) {
    null => 'مش محددة',
    AdState.queued => 'في الطابور',
    AdState.testing => 'بيتجرّب',
    AdState.winner => 'كسبان',
    AdState.oneMoreRound => 'جولة كمان',
    AdState.off => 'واقف',
    AdState.inScale => 'بيكبر',
    AdState.unknown => 'تاني',
  };
  @override
  String stateSaved(String label) => 'دلوقتي: $label';
  @override
  String get editRound => 'عدّل الجولة';
  @override
  String get roundTitleField => 'الاسم';
  @override
  String get roundNoteField => 'ملاحظة';
  @override
  String get roundSaved => 'الجولة اتحفظت';
  @override
  String get noAds => 'مفيش إعلانات في الجولة دي لسه.';
  @override
  String readDueLabel(String window) => 'قراءة مطلوبة: $window';
  @override
  String get adNoteLabel => 'ملاحظة';
}
