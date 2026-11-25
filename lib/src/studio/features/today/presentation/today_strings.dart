import 'package:flutter/material.dart';

import '../../../core/l10n/studio_labels.dart';
import '../../../core/roles/studio_role.dart';

abstract class TodayStrings {
  const TodayStrings();

  static TodayStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const TodayStringsAr()
      : const TodayStringsEn();

  String firstPurpose(StudioRole role);
  String firstStep(StudioRole role);
  String get refresh;
  String seeAll(int count);
  String get tasks;
  String get myTasks;
  String get everyonesTasks;
  String get showOpen;
  String get showDone;
  String get noTasksOpen;
  String get noTasksDone;
  String get addTask;
  String get editTask;
  String get taskText;
  String get taskTextRequired;
  String get assignTo;
  String get me;
  String get creatorsTeam;
  String get claudeTeam;
  String get due;
  String get noDue;
  String get pickDate;
  String get clearDate;
  String get tick;
  String get skip;
  String get edit;
  String get taskSaved;
  String get taskAdded;
  String taskDue(String when);
  String assignedTo(String who);
  String get skipped;
  String get nextTask;
  String get nextBlocks;
  String? actionLabel(String action);
  String get done;

  /// What a row says after its action worked: what happens next, and who has it.
  String approvedNext(String? slot, bool byHand);
  String get tickedNext;
  String get postedNext;
  String get emptyBlockHint;
  String get clearDrift;
}

class TodayStringsEn extends TodayStrings {
  const TodayStringsEn();
  @override
  String firstPurpose(StudioRole r) => switch (r) {
    StudioRole.founder =>
      'Today shows what waits on you: versions to approve, decisions, '
          'ideas, what did not go out.',
    StudioRole.lead =>
      'Today shows what is blocked, what is due and what did not go out, '
          'so you can assign the week.',
    StudioRole.creator =>
      'Today shows what was sent back to you, what is due and what to '
          'film or post.',
    StudioRole.story =>
      'Today shows the story frames to shoot and post, and what was sent back.',
  };
  @override
  String firstStep(StudioRole r) => switch (r) {
    StudioRole.founder =>
      'Nothing waits on you yet. Open Ideas to keep or drop what came in, '
          'or the Calendar to see what posts next.',
    StudioRole.lead =>
      'Start the week: add a task for someone, then open the Calendar to '
          'see what posts in the next 48 hours.',
    StudioRole.creator =>
      'Nothing waits on you yet. Open Ideas and bring one idea, or open '
          'Pieces to see what is assigned to you.',
    StudioRole.story =>
      'Nothing waits on you yet. Open Assets and upload today\'s photos '
          'and clips.',
  };
  @override
  String get refresh => 'Refresh';
  @override
  String seeAll(int c) => 'See all $c';
  @override
  String get tasks => 'Tasks';
  @override
  String get myTasks => 'Mine';
  @override
  String get everyonesTasks => 'Everyone';
  @override
  String get showOpen => 'To do';
  @override
  String get showDone => 'Done';
  @override
  String get noTasksOpen =>
      'No open tasks. Add a task for a one-off ask with a due date.';
  @override
  String get noTasksDone => 'Nothing ticked yet. Tick a task when it is done.';
  @override
  String get addTask => 'Add a task';
  @override
  String get editTask => 'Edit task';
  @override
  String get taskText => 'What needs doing';
  @override
  String get taskTextRequired => 'Write what needs doing.';
  @override
  String get assignTo => 'Who';
  @override
  String get me => 'Me';
  @override
  String get creatorsTeam => 'The creators';
  @override
  String get claudeTeam => 'Claude';
  @override
  String get due => 'Due';
  @override
  String get noDue => 'No date';
  @override
  String get pickDate => 'Pick a date';
  @override
  String get clearDate => 'Clear the date';
  @override
  String get tick => 'Tick as done';
  @override
  String get skip => 'Skip';
  @override
  String get edit => 'Edit';
  @override
  String get taskSaved => 'Task saved.';
  @override
  String get taskAdded => 'Task added.';
  @override
  String taskDue(String w) => 'due $w';
  @override
  String assignedTo(String w) => 'for $w';
  @override
  String get skipped => 'skipped';
  @override
  String get nextTask => 'Tick a task when it is done. It leaves your list.';
  @override
  String get nextBlocks => 'Tap a line to open the exact item.';
  @override
  String? actionLabel(String a) => StudioLabels.en.action(a);
  @override
  String approvedNext(String? slot, bool byHand) => slot == null
      ? 'Approved. The marketing lead picks its slot.'
      : byHand
      ? 'Approved. It goes to Ready to post for whoever posts by hand, on $slot.'
      : 'Approved. It posts by itself on $slot.';
  @override
  String get tickedNext =>
      'Done. It is off your list; whoever set it sees it ticked.';
  @override
  String get postedNext =>
      'Marked posted. The 72-hour read comes due in 3 days: the founder or the '
      'marketing lead files it.';
  @override
  String get emptyBlockHint => 'Nothing here right now.';
  @override
  String get clearDrift => 'Clear these one by one';
  @override
  String get done => 'Done.';
}

class TodayStringsAr extends TodayStrings {
  const TodayStringsAr();
  @override
  String firstPurpose(StudioRole r) => switch (r) {
    StudioRole.founder =>
      'النهارده بيعرض اللي مستنيك: نسخ للموافقة، وقرارات، وأفكار، '
          'واللي ما نزلش.',
    StudioRole.lead =>
      'النهارده بيعرض اللي واقف واللي ميعاده جه واللي ما نزلش، '
          'عشان توزّع الأسبوع.',
    StudioRole.creator =>
      'النهارده بيعرض اللي اترجعلك واللي ميعاده جه واللي تصوّره أو تنشره.',
    StudioRole.story =>
      'النهارده بيعرض فريمات الـ Story اللي تصوّرها وتنشرها واللي اترجع.',
  };
  @override
  String firstStep(StudioRole r) => switch (r) {
    StudioRole.founder =>
      'مفيش حاجة مستنية منك لسه. افتح الأفكار تحتفظ باللي جه أو تسيبه، '
          'أو التقويم تشوف إيه اللي هيتنشر.',
    StudioRole.lead =>
      'ابدأ الأسبوع: ضيف مهمة لحد في الفريق، وبعدين افتح التقويم '
          'تشوف اللي هيتنشر في الـ 48 ساعة الجاية.',
    StudioRole.creator =>
      'مفيش حاجة مستنية منك لسه. افتح الأفكار وهات فكرة، '
          'أو افتح المحتوى تشوف اللي اتسندلك.',
    StudioRole.story =>
      'مفيش حاجة مستنية منك لسه. افتح الملفات وارفع صور وفيديوهات النهارده.',
  };
  @override
  String get refresh => 'تحديث';
  @override
  String seeAll(int c) => 'شوف الكل ($c)';
  @override
  String get tasks => 'المهام';
  @override
  String get myTasks => 'بتاعتي';
  @override
  String get everyonesTasks => 'الكل';
  @override
  String get showOpen => 'لسه';
  @override
  String get showDone => 'خلصت';
  @override
  String get noTasksOpen =>
      'مفيش مهام مفتوحة. ضيف مهمة لأي طلب لمرة واحدة وليه ميعاد.';
  @override
  String get noTasksDone => 'لسه مفيش مهمة اتعلّمت إنها خلصت.';
  @override
  String get addTask => 'ضيف مهمة';
  @override
  String get editTask => 'تعديل المهمة';
  @override
  String get taskText => 'المطلوب إيه';
  @override
  String get taskTextRequired => 'اكتب المطلوب.';
  @override
  String get assignTo => 'لمين';
  @override
  String get me => 'أنا';
  @override
  String get creatorsTeam => 'الكرييتورز';
  @override
  String get claudeTeam => 'Claude';
  @override
  String get due => 'الميعاد';
  @override
  String get noDue => 'من غير ميعاد';
  @override
  String get pickDate => 'اختار تاريخ';
  @override
  String get clearDate => 'امسح التاريخ';
  @override
  String get tick => 'علّم إنها خلصت';
  @override
  String get skip => 'تخطّى';
  @override
  String get edit => 'تعديل';
  @override
  String get taskSaved => 'المهمة اتحفظت.';
  @override
  String get taskAdded => 'المهمة اتضافت.';
  @override
  String taskDue(String w) => 'الميعاد $w';
  @override
  String assignedTo(String w) => 'لـ $w';
  @override
  String get skipped => 'اتخطّت';
  @override
  String get nextTask => 'علّم المهمة لما تخلص وهتختفي من قايمتك.';
  @override
  String get nextBlocks => 'اضغط على سطر يفتح الحاجة نفسها.';
  @override
  String? actionLabel(String a) => StudioLabels.arabic.action(a);
  @override
  String approvedNext(String? slot, bool byHand) => slot == null
      ? 'اتوافق عليه. مسؤول التسويق هيحدد ميعاده.'
      : byHand
      ? 'اتوافق عليه. هيروح لـ «جاهز للنشر» لمين هينشره يدوي، يوم $slot.'
      : 'اتوافق عليه. هينزل لوحده يوم $slot.';
  @override
  String get tickedNext =>
      'تمام. اختفت من قايمتك، واللي كلّفك بيها هيشوفها اتعلّمت.';
  @override
  String get postedNext =>
      'اتعلّم إنه اتنشر. قراءة الـ 72 ساعة ميعادها بعد 3 أيام، والمؤسس أو '
      'مسؤول التسويق بيسجّلها.';
  @override
  String get emptyBlockHint => 'مفيش حاجة دلوقتي.';
  @override
  String get clearDrift => 'نضّفهم واحد واحد';
  @override
  String get done => 'تمام.';
}
