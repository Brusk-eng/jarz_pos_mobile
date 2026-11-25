import 'package:flutter/material.dart';

abstract class IdeasStrings {
  const IdeasStrings();

  static IdeasStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const IdeasStringsAr()
      : const IdeasStringsEn();

  String get tabOpen;
  String get tabOpenWaiting;
  String get tabKept;
  String get tabDropped;
  String get emptyPurpose;
  String get emptyFirstStep;
  String get emptyKeptFirstStep;
  String get emptyDroppedFirstStep;
  String get newIdea;
  String get newIdeaTitle;
  String get titleLabel;
  String get titleArLabel;
  String get hookLabel;
  String get formatLabel;
  String get titleRequired;
  String get send;
  String get keep;
  String get drop;
  String get edit;
  String get keepTitle;
  String get keepBody;
  String get dropTitle;
  String get dropReasonLabel;
  String get dropReasonRequired;
  String get editTitle;
  String get openPiece;
  String get ideaKept;
  String get ideaDropped;
  String get ideaSent;
  String get ideaAddedFounder;
  String fromReference(String name);
  String get ideaSaved;
  String get nextOpenCanDecide;
  String get nextOpenWaiting;
  String get nextKept;
  String get nextDropped;
  String get forWho;
  String get myIdeas;
  String get myIdeasEmptyPurpose;
  String get myIdeasEmptyFirstStep;
  String from(String who);
  String reasonOf(String r);
  String format(String code);
  String source(String code);
}

class IdeasStringsEn extends IdeasStrings {
  const IdeasStringsEn();
  @override
  String get tabOpen => 'To decide';
  @override
  String get tabOpenWaiting => 'Waiting for the founder';
  @override
  String get tabKept => 'Kept';
  @override
  String get tabDropped => 'Dropped';
  @override
  String get emptyPurpose =>
      'Idea cards to keep or drop. A kept idea becomes a piece.';
  @override
  String get emptyFirstStep =>
      'No ideas waiting. Tap New idea to bring one: a title and the hook is enough.';
  @override
  String get emptyKeptFirstStep =>
      'No kept ideas yet. Keep an idea and it becomes a piece here.';
  @override
  String get emptyDroppedFirstStep => 'Nothing dropped yet.';
  @override
  String get newIdea => 'New idea';
  @override
  String get newIdeaTitle => 'Bring an idea';
  @override
  String get titleLabel => 'Title';
  @override
  String get titleArLabel => 'Title in Arabic (optional)';
  @override
  String get hookLabel => 'The hook: what we see or say first';
  @override
  String get formatLabel => 'Format';
  @override
  String get titleRequired => 'Add a title first.';
  @override
  String get send => 'Send the idea';
  @override
  String get keep => 'Keep';
  @override
  String get drop => 'Drop';
  @override
  String get edit => 'Edit';
  @override
  String get keepTitle => 'Keep this idea?';
  @override
  String get keepBody =>
      'It becomes a piece at the Idea stage, ready to be planned.';
  @override
  String get dropTitle => 'Drop this idea';
  @override
  String get dropReasonLabel => 'Why? (the team sees this)';
  @override
  String get dropReasonRequired => 'Write a short reason.';
  @override
  String get editTitle => 'Edit idea';
  @override
  String get openPiece => 'Open the piece';
  @override
  String get ideaKept => 'Kept. It is a piece now.';
  @override
  String get ideaDropped => 'Dropped.';
  @override
  String get ideaSent => 'Idea sent. The founder will see it.';
  @override
  String get ideaAddedFounder => 'Idea added. It waits in your Ideas.';
  @override
  String fromReference(String name) => 'From: $name';
  @override
  String get ideaSaved => 'Idea saved.';
  @override
  String get nextOpenCanDecide =>
      'Next: keep it (it becomes a piece) or drop it with a reason.';
  @override
  String get nextOpenWaiting => 'Waiting for the founder to keep or drop it.';
  @override
  String get nextKept => 'Kept. It is now a piece.';
  @override
  String get nextDropped => 'Dropped and archived with the reason.';
  @override
  String get forWho => 'For';
  @override
  String get myIdeas => 'My ideas';
  @override
  String get myIdeasEmptyPurpose =>
      'The ideas you brought, and what became of each.';
  @override
  String get myIdeasEmptyFirstStep =>
      'You have not brought an idea yet. Tap New idea: a title and the hook is enough.';
  @override
  String from(String w) => 'from $w';
  @override
  String reasonOf(String r) => 'Reason: $r';
  @override
  String format(String c) => switch (c) {
    'reel' => 'Reel',
    'trial' => 'Trial reel',
    'static' => 'Static',
    'carousel' => 'Carousel',
    'story' => 'Story',
    _ => 'Idea',
  };
  @override
  String source(String c) => switch (c) {
    'claude' => 'Claude',
    'creator' => 'The team',
    'founder' => 'The founder',
    'reference' => 'A reference',
    'customer' => 'A customer',
    _ => 'Other',
  };
}

class IdeasStringsAr extends IdeasStrings {
  const IdeasStringsAr();
  @override
  String get tabOpen => 'للقرار';
  @override
  String get tabOpenWaiting => 'مستنية المؤسس';
  @override
  String get tabKept => 'اتحفظت';
  @override
  String get tabDropped => 'اتسابت';
  @override
  String get emptyPurpose =>
      'كروت أفكار للقرار: احتفظ أو سيب. الفكرة اللي بيتحتفظ بيها بتبقى قطعة.';
  @override
  String get emptyFirstStep =>
      'مفيش أفكار مستنية. دوس «فكرة جديدة» وهات واحدة: عنوان وهوك كفاية.';
  @override
  String get emptyKeptFirstStep =>
      'لسه مفيش أفكار محتفظ بيها. أي فكرة بتتحفظ بتبقى قطعة هنا.';
  @override
  String get emptyDroppedFirstStep => 'لسه مفيش حاجة اتسابت.';
  @override
  String get newIdea => 'فكرة جديدة';
  @override
  String get newIdeaTitle => 'هات فكرة';
  @override
  String get titleLabel => 'العنوان';
  @override
  String get titleArLabel => 'العنوان بالعربي (اختياري)';
  @override
  String get hookLabel => 'الهوك: أول حاجة نشوفها أو نقولها';
  @override
  String get formatLabel => 'النوع';
  @override
  String get titleRequired => 'اكتب عنوان الأول.';
  @override
  String get send => 'ابعت الفكرة';
  @override
  String get keep => 'احتفظ';
  @override
  String get drop => 'سيب';
  @override
  String get edit => 'تعديل';
  @override
  String get keepTitle => 'نحتفظ بالفكرة دي؟';
  @override
  String get keepBody => 'هتبقى قطعة في مرحلة الفكرة وجاهزة للتخطيط.';
  @override
  String get dropTitle => 'نسيب الفكرة دي؟';
  @override
  String get dropReasonLabel => 'السبب؟ (الفريق بيشوفه)';
  @override
  String get dropReasonRequired => 'اكتب سبب قصير.';
  @override
  String get editTitle => 'تعديل الفكرة';
  @override
  String get openPiece => 'افتح القطعة';
  @override
  String get ideaKept => 'اتحفظت. بقت قطعة دلوقتي.';
  @override
  String get ideaDropped => 'اتسابت.';
  @override
  String get ideaSent => 'الفكرة اتبعتت. المؤسس هيشوفها.';
  @override
  String get ideaAddedFounder => 'الفكرة اتضافت. مستنياك في الأفكار.';
  @override
  String fromReference(String name) => 'من: $name';
  @override
  String get ideaSaved => 'الفكرة اتحفظت.';
  @override
  String get nextOpenCanDecide =>
      'الخطوة الجاية: احتفظ بيها (هتبقى قطعة) أو سيبها وقول السبب.';
  @override
  String get nextOpenWaiting => 'مستنيين المؤسس يقرر: يحتفظ بيها أو يسيبها.';
  @override
  String get nextKept => 'اتحفظت. بقت قطعة دلوقتي.';
  @override
  String get nextDropped => 'اتسابت واتأرشفت مع السبب.';
  @override
  String get forWho => 'لـ';
  @override
  String get myIdeas => 'أفكاري';
  @override
  String get myIdeasEmptyPurpose =>
      'الأفكار اللي جبتها، وإيه اللي حصل لكل واحدة.';
  @override
  String get myIdeasEmptyFirstStep =>
      'لسه ما جبتش فكرة. دوس «فكرة جديدة»: عنوان وهوك كفاية.';
  @override
  String from(String w) => 'من $w';
  @override
  String reasonOf(String r) => 'السبب: $r';
  @override
  String format(String c) => switch (c) {
    'reel' => 'Reel',
    'trial' => 'Trial reel',
    'static' => 'Static',
    'carousel' => 'Carousel',
    'story' => 'Story',
    _ => 'فكرة',
  };
  @override
  String source(String c) => switch (c) {
    'claude' => 'Claude',
    'creator' => 'الفريق',
    'founder' => 'المؤسس',
    'reference' => 'مرجع',
    'customer' => 'عميل',
    _ => 'غير ذلك',
  };
}
