import 'package:flutter/widgets.dart';

import '../../data/models/studio_enums.dart';

/// Texts of the Settings screens (rules, flavours, claims, moments, people,
/// options), English and Arabic, same pattern as `StudioStrings`. Product
/// words people say in English (flavor, size) stay in English inside Arabic.
abstract class SettingsStrings {
  const SettingsStrings();

  static SettingsStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const SettingsStringsAr()
      : const SettingsStringsEn();

  // ---- Hub ---------------------------------------------------------------
  String get title;
  String get helpTitle;
  List<String> get help;
  String get readOnlyNote;
  String get rules;
  String get rulesBlurb;
  String get flavours;
  String get flavoursBlurb;
  String get claims;
  String get claimsBlurb;
  String get moments;
  String get momentsBlurb;
  String get people;
  String get peopleBlurb;
  String get options;
  String get optionsBlurb;

  // ---- Rules -------------------------------------------------------------
  String get rulesTitle;
  String get rulesHelpTitle;
  List<String> get rulesHelp;
  String get rulesEmptyPurpose;
  String get rulesEmptyFirstStep;
  String get rulesSearchHint;
  String get ruleTitle;
  String get inForce;
  String fromDate(String date);
  String get startingValue;
  String get history;
  String get noHistory;
  String get replaced;
  String get changeFromDate;
  String get changeTitle;
  String get newValue;
  String get validFrom;
  String get noteOptional;
  String get valueNotANumber;
  String get ruleChanged;
  String get historyNeverEdited;
  String get sourceLabel;

  // ---- Flavours ----------------------------------------------------------
  String get flavoursTitle;
  String get flavoursHelpTitle;
  List<String> get flavoursHelp;
  String get flavoursEmptyPurpose;
  String get flavoursEmptyFirstStep;
  String get flavourTitle;
  String statusLabel(FlavourStatus s);
  String get availableFrom;
  String get availableTo;
  String get notSet;
  String get prices;
  String get priceMedium;
  String get priceLarge;
  String get priceUnknown;
  String get flavourNote;
  String get nameBlocked;
  String get editFlavour;
  String get statusField;
  String get flavourSaved;
  String get flavourWarningsTitle;
  String get flavourWarningsIntro;
  String get clearDate;

  // ---- Claims ------------------------------------------------------------
  String get claimsTitle;
  String get claimsHelpTitle;
  List<String> get claimsHelp;
  String get claimsEmptyPurpose;
  String get claimsEmptyFirstStep;
  String claimStatusLabel(ClaimStatus s);
  String get englishWording;
  String get arabicWording;
  String get registrySource;
  String syncedOn(String when);

  // ---- Moments -----------------------------------------------------------
  String get momentsTitle;
  String get momentsHelpTitle;
  List<String> get momentsHelp;
  String get momentsEmptyPurpose;
  String get momentsEmptyFirstStep;
  String kindLabel(MomentKind k);
  String kindPlural(MomentKind k);
  String get until;
  String stageLabel(LaunchStage s);
  String get jarLabel;
  String labelName(JarLabel l);
  String get owner;
  String get startsFrom;

  // ---- People ------------------------------------------------------------
  String get peopleTitle;
  String get peopleHelpTitle;
  List<String> get peopleHelp;
  String get peopleEmptyPurpose;
  String get peopleEmptyFirstStep;
  String get personTitle;
  String roleLabel(PersonRole r);
  String get linkedLogin;
  String get noLogin;
  String get active;
  String get inactive;
  String get mustRate;
  String get fullName;
  String get roleField;
  String get loginField;
  String get loginHint;
  String get activeField;
  String get mustRateField;
  String get editPerson;
  String get personSaved;

  // ---- Options -----------------------------------------------------------
  String get optionsTitle;
  String get optionsHelpTitle;
  List<String> get optionsHelp;
  String get optionsEmptyPurpose;
  String get optionsEmptyFirstStep;
  String optionListLabel(String key);
}

String _humanize(String key) {
  final s = key.replaceAll('_', ' ').trim();
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class SettingsStringsEn extends SettingsStrings {
  const SettingsStringsEn();

  @override
  String get title => 'Settings';
  @override
  String get helpTitle => 'Settings';
  @override
  List<String> get help => const [
    'Rules, flavors, approved claims, moments and people live here.',
    'Everyone can read. Only the founder changes them.',
    'A rule change adds a new dated value. Old values are never edited.',
    'Tap an item to read it. The pencil edits it.',
  ];
  @override
  String get readOnlyNote => 'You can read these. The founder changes them.';
  @override
  String get rules => 'Rules';
  @override
  String get rulesBlurb => 'The numbers the paid rules run on, with dates';
  @override
  String get flavours => 'Flavors';
  @override
  String get flavoursBlurb => 'Status, dates and prices of each flavor';
  @override
  String get claims => 'Approved claims';
  @override
  String get claimsBlurb => 'What we may say, as the registry holds it';
  @override
  String get moments => 'Moments';
  @override
  String get momentsBlurb => 'Launches, Occasion windows and budget steps';
  @override
  String get people => 'People';
  @override
  String get peopleBlurb => 'Who is on the team and what they can do';
  @override
  String get options => 'Option lists';
  @override
  String get optionsBlurb => 'The choices every form offers';

  @override
  String get rulesTitle => 'Rules';
  @override
  String get rulesHelpTitle => 'Rules';
  @override
  List<String> get rulesHelp => const [
    'Each rule is a number with the date it applies from.',
    'To change one, add a new value from a date. Old values stay as history.',
    'The paid screens and the judges read these numbers.',
  ];
  @override
  String get rulesEmptyPurpose => 'The numbers the rules run on, with dates.';
  @override
  String get rulesEmptyFirstStep =>
      'No rules yet. They arrive when the rule table is synced.';
  @override
  String get rulesSearchHint => 'Search rules';
  @override
  String get ruleTitle => 'Rule';
  @override
  String get inForce => 'In force now';
  @override
  String fromDate(String date) => 'since $date';
  @override
  String get startingValue => 'Starting value';
  @override
  String get history => 'History';
  @override
  String get noHistory => 'No dated values yet. The starting value applies.';
  @override
  String get replaced => 'Replaced';
  @override
  String get changeFromDate => 'Change from a date';
  @override
  String get changeTitle => 'Change this rule';
  @override
  String get newValue => 'New value';
  @override
  String get validFrom => 'Applies from';
  @override
  String get noteOptional => 'Why (optional)';
  @override
  String get valueNotANumber => 'Write the value as a number.';
  @override
  String get ruleChanged => 'New value saved';
  @override
  String get historyNeverEdited => 'Old values are kept as they were.';
  @override
  String get sourceLabel => 'Where it comes from';

  @override
  String get flavoursTitle => 'Flavors';
  @override
  String get flavoursHelpTitle => 'Flavors';
  @override
  List<String> get flavoursHelp => const [
    'Each flavor has a marketing status and dates it is available.',
    'Prices are read live from ERPNext. They cannot be typed here.',
    'Saving never blocks. If a change causes a problem, a warning says so.',
  ];
  @override
  String get flavoursEmptyPurpose => 'Every flavor with its status and dates.';
  @override
  String get flavoursEmptyFirstStep =>
      'No flavors yet. They arrive when the catalog is synced.';
  @override
  String get flavourTitle => 'Flavor';
  @override
  String statusLabel(FlavourStatus s) => switch (s) {
    FlavourStatus.live => 'On sale',
    FlavourStatus.paused => 'Paused',
    FlavourStatus.seasonal => 'Seasonal',
    FlavourStatus.coming => 'Coming',
    FlavourStatus.unknown => 'Unknown',
  };
  @override
  String get availableFrom => 'Available from';
  @override
  String get availableTo => 'Available until';
  @override
  String get notSet => 'Not set';
  @override
  String get prices => 'Prices';
  @override
  String get priceMedium => 'Medium';
  @override
  String get priceLarge => 'Large';
  @override
  String get priceUnknown => 'ERPNext did not answer';
  @override
  String get flavourNote => 'Note';
  @override
  String get nameBlocked => 'The name is blocked. Do not use it in copy.';
  @override
  String get editFlavour => 'Change this flavor';
  @override
  String get statusField => 'Status';
  @override
  String get flavourSaved => 'Flavor saved';
  @override
  String get flavourWarningsTitle => 'Saved, with a warning';
  @override
  String get flavourWarningsIntro =>
      'The change is saved. These now need a look:';
  @override
  String get clearDate => 'Clear';

  @override
  String get claimsTitle => 'Approved claims';
  @override
  String get claimsHelpTitle => 'Approved claims';
  @override
  List<String> get claimsHelp => const [
    'A read-only copy of the approved-claims registry.',
    'Only the wording shown as approved may be used in copy.',
    'Hold means not yet cleared. Retired means never use it again.',
  ];
  @override
  String get claimsEmptyPurpose => 'What we may say, word for word.';
  @override
  String get claimsEmptyFirstStep =>
      'No claims yet. They are copied from the registry by a script.';
  @override
  String claimStatusLabel(ClaimStatus s) => switch (s) {
    ClaimStatus.aPPROVED => 'Approved',
    ClaimStatus.hOLD => 'On hold',
    ClaimStatus.rETIRED => 'Retired',
    ClaimStatus.unknown => 'Unknown',
  };
  @override
  String get englishWording => 'English wording';
  @override
  String get arabicWording => 'Arabic wording';
  @override
  String get registrySource => 'Registry line';
  @override
  String syncedOn(String when) => 'Copied $when';

  @override
  String get momentsTitle => 'Moments';
  @override
  String get momentsHelpTitle => 'Moments';
  @override
  List<String> get momentsHelp => const [
    'Launches, Occasion windows and budget steps, by date.',
    'An occasion window opens the push for one occasion; none runs outside it.',
    'This list is for reading. Dates move from the calendar.',
  ];
  @override
  String get momentsEmptyPurpose =>
      'Launches, Occasion windows and budget steps.';
  @override
  String get momentsEmptyFirstStep => 'No moments yet. None are planned.';
  @override
  String kindLabel(MomentKind k) => switch (k) {
    MomentKind.launch => 'Launch',
    MomentKind.heroWindow => 'Occasion window',
    MomentKind.budgetStep => 'Budget step',
    MomentKind.unknown => 'Unknown',
  };
  @override
  String kindPlural(MomentKind k) => switch (k) {
    MomentKind.launch => 'Launches',
    MomentKind.heroWindow => 'Occasion windows',
    MomentKind.budgetStep => 'Budget steps',
    MomentKind.unknown => 'Unknown',
  };
  @override
  String get until => 'until';
  @override
  String stageLabel(LaunchStage s) => switch (s) {
    LaunchStage.teasing => 'Teasing',
    LaunchStage.live => 'Live',
    LaunchStage.paused => 'Paused',
    LaunchStage.done => 'Done',
    LaunchStage.unknown => 'Unknown',
  };
  @override
  String get jarLabel => 'Jar label';
  @override
  String labelName(JarLabel l) => switch (l) {
    JarLabel.old => 'Old label',
    JarLabel.newValue => 'New label',
    JarLabel.unknown => 'Unknown',
  };
  @override
  String get owner => 'Owner';
  @override
  String get startsFrom => 'Starts';

  @override
  String get peopleTitle => 'People';
  @override
  String get peopleHelpTitle => 'People';
  @override
  List<String> get peopleHelp => const [
    'Everyone on the team, with their role.',
    'Linking a login gives that person the matching Studio access.',
    'Turn a person off instead of deleting them.',
  ];
  @override
  String get peopleEmptyPurpose => 'Who is on the team and what they can do.';
  @override
  String get peopleEmptyFirstStep =>
      'No people yet. They arrive when the team list is synced.';
  @override
  String get personTitle => 'Person';
  @override
  String roleLabel(PersonRole r) => switch (r) {
    PersonRole.founder => 'Founder',
    PersonRole.marketingLead => 'Marketing lead',
    PersonRole.creator => 'Creator',
    PersonRole.storyLead => 'Story lead',
    PersonRole.moderator => 'Moderator (no access yet)',
    PersonRole.unknown => 'Unknown',
  };
  @override
  String get linkedLogin => 'Linked login';
  @override
  String get noLogin => 'No login linked';
  @override
  String get active => 'Active';
  @override
  String get inactive => 'Switched off';
  @override
  String get mustRate => 'Rates every version';
  @override
  String get fullName => 'Name';
  @override
  String get roleField => 'Role';
  @override
  String get loginField => 'Login';
  @override
  String get loginHint => 'The email or username they sign in with';
  @override
  String get activeField => 'Active';
  @override
  String get mustRateField => 'Rates every version';
  @override
  String get editPerson => 'Change this person';
  @override
  String get personSaved => 'Person saved';

  @override
  String get optionsTitle => 'Option lists';
  @override
  String get optionsHelpTitle => 'Option lists';
  @override
  List<String> get optionsHelp => const [
    'These are the choices every form in the Studio offers.',
    'They are read only here. The server owns them.',
  ];
  @override
  String get optionsEmptyPurpose => 'The choices every form offers.';
  @override
  String get optionsEmptyFirstStep => 'No option lists came back. Try again.';
  @override
  String optionListLabel(String key) => _humanize(key);
}

class SettingsStringsAr extends SettingsStrings {
  const SettingsStringsAr();

  @override
  String get title => 'الإعدادات';
  @override
  String get helpTitle => 'الإعدادات';
  @override
  List<String> get help => const [
    'القواعد والـ flavors والـ claims المعتمدة واللحظات والناس هنا.',
    'الكل يقدر يقرا. المؤسس بس اللي بيغيّر.',
    'تغيير القاعدة بيضيف قيمة جديدة بتاريخ. القيم القديمة مبتتعدلش.',
    'اضغط على أي عنصر عشان تقراه. القلم للتعديل.',
  ];
  @override
  String get readOnlyNote => 'تقدر تقرا دول بس. المؤسس هو اللي بيغيّرهم.';
  @override
  String get rules => 'القواعد';
  @override
  String get rulesBlurb =>
      'الأرقام اللي قواعد الإعلانات بتشتغل بيها، بالتواريخ';
  @override
  String get flavours => 'الـ flavors';
  @override
  String get flavoursBlurb => 'حالة وتواريخ وأسعار كل flavor';
  @override
  String get claims => 'الـ claims المعتمدة';
  @override
  String get claimsBlurb => 'اللي مسموح نقوله، زي ما الـ registry ماسكه';
  @override
  String get moments => 'اللحظات';
  @override
  String get momentsBlurb => 'الإطلاقات ونوافذ المناسبات وخطوات الميزانية';
  @override
  String get people => 'الناس';
  @override
  String get peopleBlurb => 'مين في الفريق وبيعمل إيه';
  @override
  String get options => 'قوائم الاختيارات';
  @override
  String get optionsBlurb => 'الاختيارات اللي كل فورم بيعرضها';

  @override
  String get rulesTitle => 'القواعد';
  @override
  String get rulesHelpTitle => 'القواعد';
  @override
  List<String> get rulesHelp => const [
    'كل قاعدة رقم معاه التاريخ اللي بيسري منه.',
    'عشان تغيّر قاعدة، ضيف قيمة جديدة من تاريخ معيّن. القيم القديمة بتفضل في السجل.',
    'شاشات الإعلانات والـ judges بيقروا الأرقام دي.',
  ];
  @override
  String get rulesEmptyPurpose =>
      'الأرقام اللي القواعد بتشتغل بيها، بالتواريخ.';
  @override
  String get rulesEmptyFirstStep =>
      'مفيش قواعد لسه. هتظهر لما جدول القواعد يتزامن.';
  @override
  String get rulesSearchHint => 'دوّر في القواعد';
  @override
  String get ruleTitle => 'قاعدة';
  @override
  String get inForce => 'ساري دلوقتي';
  @override
  String fromDate(String date) => 'من $date';
  @override
  String get startingValue => 'القيمة الأصلية';
  @override
  String get history => 'السجل';
  @override
  String get noHistory => 'مفيش قيم بتواريخ لسه. القيمة الأصلية هي السارية.';
  @override
  String get replaced => 'اتغيّرت';
  @override
  String get changeFromDate => 'غيّر من تاريخ';
  @override
  String get changeTitle => 'غيّر القاعدة دي';
  @override
  String get newValue => 'القيمة الجديدة';
  @override
  String get validFrom => 'بتسري من';
  @override
  String get noteOptional => 'ليه (اختياري)';
  @override
  String get valueNotANumber => 'اكتب القيمة كرقم.';
  @override
  String get ruleChanged => 'القيمة الجديدة اتحفظت';
  @override
  String get historyNeverEdited => 'القيم القديمة بتفضل زي ما كانت.';
  @override
  String get sourceLabel => 'مصدرها';

  @override
  String get flavoursTitle => 'الـ flavors';
  @override
  String get flavoursHelpTitle => 'الـ flavors';
  @override
  List<String> get flavoursHelp => const [
    'كل flavor له حالة وتواريخ بيكون متاح فيها.',
    'الأسعار بتتقرا لايف من ERPNext. مش بتتكتب هنا.',
    'الحفظ مش بيتمنع. لو التغيير هيعمل مشكلة، بيظهر تنبيه.',
  ];
  @override
  String get flavoursEmptyPurpose => 'كل flavor بحالته وتواريخه.';
  @override
  String get flavoursEmptyFirstStep =>
      'مفيش flavors لسه. هتظهر لما الكتالوج يتزامن.';
  @override
  String get flavourTitle => 'Flavor';
  @override
  String statusLabel(FlavourStatus s) => switch (s) {
    FlavourStatus.live => 'متاح للبيع',
    FlavourStatus.paused => 'واقف مؤقتًا',
    FlavourStatus.seasonal => 'موسمي',
    FlavourStatus.coming => 'جاي قريب',
    FlavourStatus.unknown => 'غير معروف',
  };
  @override
  String get availableFrom => 'متاح من';
  @override
  String get availableTo => 'متاح لحد';
  @override
  String get notSet => 'مش محدد';
  @override
  String get prices => 'الأسعار';
  @override
  String get priceMedium => 'Medium';
  @override
  String get priceLarge => 'Large';
  @override
  String get priceUnknown => 'ERPNext مردّش';
  @override
  String get flavourNote => 'ملاحظة';
  @override
  String get nameBlocked => 'الاسم ده ممنوع. متستخدمهوش في أي كلام.';
  @override
  String get editFlavour => 'عدّل الـ flavor ده';
  @override
  String get statusField => 'الحالة';
  @override
  String get flavourSaved => 'الـ flavor اتحفظ';
  @override
  String get flavourWarningsTitle => 'اتحفظ، مع تنبيه';
  @override
  String get flavourWarningsIntro =>
      'التغيير اتحفظ. الحاجات دي محتاجة مراجعة دلوقتي:';
  @override
  String get clearDate => 'امسح';

  @override
  String get claimsTitle => 'الـ claims المعتمدة';
  @override
  String get claimsHelpTitle => 'الـ claims المعتمدة';
  @override
  List<String> get claimsHelp => const [
    'نسخة للقراءة بس من الـ registry بتاع الـ claims المعتمدة.',
    'الصياغة المعتمدة بس هي اللي تتستخدم في الكلام.',
    'متوقف يعني لسه ما اتوافقش عليه. اتسحب يعني متستخدمهوش تاني.',
  ];
  @override
  String get claimsEmptyPurpose => 'اللي مسموح نقوله، كلمة بكلمة.';
  @override
  String get claimsEmptyFirstStep =>
      'مفيش claims لسه. بتتنسخ من الـ registry بسكربت.';
  @override
  String claimStatusLabel(ClaimStatus s) => switch (s) {
    ClaimStatus.aPPROVED => 'معتمد',
    ClaimStatus.hOLD => 'متوقف',
    ClaimStatus.rETIRED => 'اتسحب',
    ClaimStatus.unknown => 'غير معروف',
  };
  @override
  String get englishWording => 'الصياغة بالإنجليزي';
  @override
  String get arabicWording => 'الصياغة بالعربي';
  @override
  String get registrySource => 'سطر الـ registry';
  @override
  String syncedOn(String when) => 'اتنسخ $when';

  @override
  String get momentsTitle => 'اللحظات';
  @override
  String get momentsHelpTitle => 'اللحظات';
  @override
  List<String> get momentsHelp => const [
    'الإطلاقات ونوافذ المناسبات وخطوات الميزانية، بالتاريخ.',
    'نافذة المناسبة بتفتح الدفعة لمناسبة واحدة، ومفيش دفعة بره النافذة.',
    'القائمة دي للقراءة بس. التواريخ بتتغيّر من التقويم.',
  ];
  @override
  String get momentsEmptyPurpose =>
      'الإطلاقات ونوافذ المناسبات وخطوات الميزانية.';
  @override
  String get momentsEmptyFirstStep => 'مفيش لحظات لسه. لسه مفيش حاجة متخططة.';
  @override
  String kindLabel(MomentKind k) => switch (k) {
    MomentKind.launch => 'إطلاق',
    MomentKind.heroWindow => 'نافذة المناسبة',
    MomentKind.budgetStep => 'خطوة ميزانية',
    MomentKind.unknown => 'غير معروف',
  };
  @override
  String kindPlural(MomentKind k) => switch (k) {
    MomentKind.launch => 'الإطلاقات',
    MomentKind.heroWindow => 'نوافذ المناسبات',
    MomentKind.budgetStep => 'خطوات الميزانية',
    MomentKind.unknown => 'غير معروف',
  };
  @override
  String get until => 'لحد';
  @override
  String stageLabel(LaunchStage s) => switch (s) {
    LaunchStage.teasing => 'تشويق',
    LaunchStage.live => 'شغّال',
    LaunchStage.paused => 'واقف',
    LaunchStage.done => 'خلص',
    LaunchStage.unknown => 'غير معروف',
  };
  @override
  String get jarLabel => 'ليبل البرطمان';
  @override
  String labelName(JarLabel l) => switch (l) {
    JarLabel.old => 'الليبل القديم',
    JarLabel.newValue => 'الليبل الجديد',
    JarLabel.unknown => 'غير معروف',
  };
  @override
  String get owner => 'المسؤول';
  @override
  String get startsFrom => 'بيبدأ من';

  @override
  String get peopleTitle => 'الناس';
  @override
  String get peopleHelpTitle => 'الناس';
  @override
  List<String> get peopleHelp => const [
    'كل اللي في الفريق، ودور كل واحد.',
    'ربط اللوجين بيدّي الشخص صلاحيات الـ Studio المناسبة.',
    'وقّف الشخص بدل ما تمسحه.',
  ];
  @override
  String get peopleEmptyPurpose => 'مين في الفريق وبيعمل إيه.';
  @override
  String get peopleEmptyFirstStep =>
      'مفيش ناس لسه. هيظهروا لما قائمة الفريق تتزامن.';
  @override
  String get personTitle => 'شخص';
  @override
  String roleLabel(PersonRole r) => switch (r) {
    PersonRole.founder => 'المؤسس',
    PersonRole.marketingLead => 'مسؤول التسويق',
    PersonRole.creator => 'صانع محتوى',
    PersonRole.storyLead => 'مسؤول الـ Stories',
    PersonRole.moderator => 'مودريتور (لسه من غير صلاحية)',
    PersonRole.unknown => 'غير معروف',
  };
  @override
  String get linkedLogin => 'اللوجين المربوط';
  @override
  String get noLogin => 'مفيش لوجين مربوط';
  @override
  String get active => 'شغّال';
  @override
  String get inactive => 'واقف';
  @override
  String get mustRate => 'بيقيّم كل نسخة';
  @override
  String get fullName => 'الاسم';
  @override
  String get roleField => 'الدور';
  @override
  String get loginField => 'اللوجين';
  @override
  String get loginHint => 'الإيميل أو اسم المستخدم اللي بيدخل بيه';
  @override
  String get activeField => 'شغّال';
  @override
  String get mustRateField => 'بيقيّم كل نسخة';
  @override
  String get editPerson => 'عدّل بيانات الشخص ده';
  @override
  String get personSaved => 'الشخص اتحفظ';

  @override
  String get optionsTitle => 'قوائم الاختيارات';
  @override
  String get optionsHelpTitle => 'قوائم الاختيارات';
  @override
  List<String> get optionsHelp => const [
    'دي الاختيارات اللي كل فورم في الـ Studio بيعرضها.',
    'للقراءة بس هنا. السيرفر هو اللي ماسكها.',
  ];
  @override
  String get optionsEmptyPurpose => 'الاختيارات اللي كل فورم بيعرضها.';
  @override
  String get optionsEmptyFirstStep => 'القوائم ما وصلتش. جرّب تاني.';
  @override
  String optionListLabel(String key) => _humanize(key);
}
