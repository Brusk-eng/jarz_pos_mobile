import 'package:flutter/material.dart';

abstract class DecisionsStrings {
  const DecisionsStrings();

  static DecisionsStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const DecisionsStringsAr()
      : const DecisionsStringsEn();

  String get tabOpen;
  String get pickToOpen;
  String get tabAnswered;
  String get emptyOpenPurpose;
  String get emptyOpenFirstStep;
  String get emptyAnsweredPurpose;
  String get emptyAnsweredFirstStep;
  String get title;
  String get recommended;
  String get pros;
  String get cons;
  String get mainRisk;
  String get whenRight;
  String get raisedByClaude;
  String get raisedByNeon;
  String get raisedByBoth;
  String get noteLabel;
  String get noteHint;
  String get confirmPick;
  String get pickFirst;
  String get openReport;
  String get nextOpenFounder;
  String get nextOpenOthers;
  String get nextAnswered;
  String get superseded;
  String get withdrawn;
  String youPicked(String label);
  String picked(String label);
  String pickedBy(String name, String when);
  String get yourNote;
  String raisedBy(String who);
  String waiting(String d);
  String get saved;
  String get answerSaved;
  String get answerLabel;
  String get answerHint;
  String get sendAnswer;
  String get writeFirst;
  String get nextOpenFounderText;
  String get nextAnsweredText;
  String get yourAnswer;
  String answerCount(int n, int max);
  String get decisionGone;
}

class DecisionsStringsEn extends DecisionsStrings {
  const DecisionsStringsEn();
  @override
  String get pickToOpen => 'Pick a decision to open it here.';
  @override
  String get tabOpen => 'Open';
  @override
  String get tabAnswered => 'Answered';
  @override
  String get emptyOpenPurpose =>
      'Questions that need the founder, each with options, pros and cons.';
  @override
  String get emptyOpenFirstStep =>
      'No open decisions. When a report raises a question it shows up here.';
  @override
  String get emptyAnsweredPurpose => 'Every answered decision stays here.';
  @override
  String get emptyAnsweredFirstStep =>
      'Nothing answered yet. Answer an open decision and it moves here.';
  @override
  String get title => 'Decision';
  @override
  String get recommended => 'Recommended';
  @override
  String get pros => 'Pros';
  @override
  String get cons => 'Cons';
  @override
  String get mainRisk => 'Main risk';
  @override
  String get whenRight => 'Right when';
  @override
  String get raisedByClaude => 'Claude\'s view';
  @override
  String get raisedByNeon => 'Second opinion';
  @override
  String get raisedByBoth => 'Both agree';
  @override
  String get noteLabel => 'Note (optional)';
  @override
  String get noteHint => 'Why this one, if it matters later';
  @override
  String get confirmPick => 'Confirm this pick';
  @override
  String get pickFirst => 'Pick an option';
  @override
  String get openReport => 'Open the report';
  @override
  String get nextOpenFounder =>
      'Pick one option and confirm. Any option is fine, not only the recommended one.';
  @override
  String get nextOpenOthers =>
      'Only the founder answers this. You will see the pick here once it is made.';
  @override
  String get nextAnswered =>
      'Done. The pick is kept and the work that waited on it can go ahead.';
  @override
  String get superseded => 'Replaced by a newer decision';
  @override
  String get withdrawn => 'Withdrawn. No answer needed any more.';
  @override
  String youPicked(String l) => 'You picked: $l';
  @override
  String picked(String l) => 'Picked: $l';
  @override
  String pickedBy(String n, String w) => w.isEmpty ? 'by $n' : 'by $n, $w';
  @override
  String get yourNote => 'Note';
  @override
  String raisedBy(String w) => 'raised by $w';
  @override
  String waiting(String d) => 'waiting $d';
  @override
  String get saved => 'Pick saved';
  @override
  String get answerSaved => 'Answer saved';
  @override
  String get answerLabel => 'Your answer';
  @override
  String get answerHint => 'Write the answer in your own words';
  @override
  String get sendAnswer => 'Send the answer';
  @override
  String get writeFirst => 'Write the answer first';
  @override
  String get nextOpenFounderText =>
      'Write your answer and send it. It is kept as you wrote it and the work that waited on it can go ahead.';
  @override
  String get nextAnsweredText =>
      'Done. The answer is kept and the work that waited on it can go ahead.';
  @override
  String get yourAnswer => 'Answer';
  @override
  String answerCount(int n, int max) => '\u202A$n / $max\u202C';
  @override
  String get decisionGone =>
      'This decision is no longer there. Go back to the list.';
}

class DecisionsStringsAr extends DecisionsStrings {
  const DecisionsStringsAr();
  @override
  String get pickToOpen => 'اختار قرار عشان تفتحه هنا.';
  @override
  String get tabOpen => 'مفتوحة';
  @override
  String get tabAnswered => 'اتحسمت';
  @override
  String get emptyOpenPurpose =>
      'أسئلة محتاجة قرار المؤسس، وكل سؤال بخياراته ومميزاته وعيوبه.';
  @override
  String get emptyOpenFirstStep =>
      'مفيش قرارات مفتوحة. أي تقرير بيطلع بسؤال هيظهر هنا.';
  @override
  String get emptyAnsweredPurpose => 'كل قرار اتحسم بيفضل هنا.';
  @override
  String get emptyAnsweredFirstStep =>
      'لسه مفيش قرار اتحسم. احسم قرار مفتوح وهينتقل هنا.';
  @override
  String get title => 'قرار';
  @override
  String get recommended => 'المرشّح';
  @override
  String get pros => 'المميزات';
  @override
  String get cons => 'العيوب';
  @override
  String get mainRisk => 'أكبر خطر';
  @override
  String get whenRight => 'مناسب لما';
  @override
  String get raisedByClaude => 'رأي Claude';
  @override
  String get raisedByNeon => 'رأي تاني';
  @override
  String get raisedByBoth => 'الاتنين متفقين';
  @override
  String get noteLabel => 'ملاحظة (اختياري)';
  @override
  String get noteHint => 'ليه الاختيار ده، لو هتفرق بعدين';
  @override
  String get confirmPick => 'أكّد الاختيار';
  @override
  String get pickFirst => 'اختار خيار';
  @override
  String get openReport => 'افتح التقرير';
  @override
  String get nextOpenFounder =>
      'اختار خيار واحد وأكّده. تقدر تختار أي خيار، مش المرشّح بس.';
  @override
  String get nextOpenOthers =>
      'المؤسس بس هو اللي بيجاوب على ده. هتشوف اختياره هنا أول ما يختار.';
  @override
  String get nextAnswered =>
      'تمام. الاختيار اتسجّل والشغل اللي كان مستنيه يقدر يكمّل.';
  @override
  String get superseded => 'اتغيّر بقرار أحدث';
  @override
  String get withdrawn => 'اتسحب. مش محتاج إجابة تاني.';
  @override
  String youPicked(String l) => 'اخترت: $l';
  @override
  String picked(String l) => 'الاختيار: $l';
  @override
  String pickedBy(String n, String w) => w.isEmpty ? 'من $n' : 'من $n، $w';
  @override
  String get yourNote => 'ملاحظة';
  @override
  String raisedBy(String w) => 'من $w';
  @override
  String waiting(String d) => 'مستني من $d';
  @override
  String get saved => 'الاختيار اتحفظ';
  @override
  String get answerSaved => 'الإجابة اتحفظت';
  @override
  String get answerLabel => 'إجابتك';
  @override
  String get answerHint => 'اكتب الإجابة بكلامك';
  @override
  String get sendAnswer => 'ابعت الإجابة';
  @override
  String get writeFirst => 'اكتب الإجابة الأول';
  @override
  String get nextOpenFounderText =>
      'اكتب إجابتك وابعتها. بتتسجّل زي ما كتبتها، والشغل اللي كان مستنيها يقدر يكمّل.';
  @override
  String get nextAnsweredText =>
      'تمام. الإجابة اتسجّلت والشغل اللي كان مستنيها يقدر يكمّل.';
  @override
  String get yourAnswer => 'الإجابة';
  @override
  String answerCount(int n, int max) => '\u202A$n / $max\u202C';
  @override
  String get decisionGone => 'القرار ده مبقاش موجود. ارجع للقايمة.';
}
