import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../roles/studio_role.dart';
import '../router/studio_screen.dart';

/// Copy for one screen: its name, what it is for (shown as the empty state),
/// what to do first, and the lines of its "how this works" sheet (3 to 5).
class ScreenCopy {
  const ScreenCopy({
    required this.title,
    required this.purpose,
    required this.firstStep,
    required this.help,
  });

  final String title;
  final String purpose;
  final String firstStep;
  final List<String> help;
}

/// Studio strings, hand-written and separate from the POS ARB files.
///
/// An abstract class with one implementation per language, so a string added
/// here cannot be forgotten in Arabic: the build fails instead. Brand and
/// product words (Jarz, Studio) stay in English inside Arabic copy.
abstract class StudioStrings {
  const StudioStrings();

  static const supportedLocales = [Locale('en'), Locale('ar')];
  static const LocalizationsDelegate<StudioStrings> delegate =
      _StudioStringsDelegate();

  static StudioStrings of(BuildContext context) =>
      Localizations.of<StudioStrings>(context, StudioStrings) ??
      const StudioStringsEn();

  static StudioStrings forLocale(Locale locale) => locale.languageCode == 'ar'
      ? const StudioStringsAr()
      : const StudioStringsEn();

  // App chrome.
  String get appName;
  String get tabToday;
  String get tabInbox;
  String get tabCalendar;
  String get tabPieces;
  String get tabMore;
  String get inboxApprove;
  String get inboxDecisions;
  String get inboxIdeas;

  // Common.
  String get howThisWorks;
  String get gotIt;
  String get edit;
  String get back;
  String get retry;
  String get dismiss;
  String get clear;
  String get showMore;
  String get loading;
  String get errorGeneric;
  String get changeFailed;
  String get languageSwitchLabel;
  String get languageSwitchTarget;
  String get signOut;
  String get more;
  String get nothingHere;

  // Login and access.
  String get loginTitle;
  String get loginSubtitle;
  String get username;
  String get password;
  String get showPassword;
  String get hidePassword;
  String get signIn;
  String get signInFailed;
  String get noAccessTitle;
  String get noAccessBody;
  String get checkingAccess;
  String helloUser(String name);

  String role(StudioRole role);
  String todayBlock(TodayBlock block);
  String moreItem(MoreItem item);
  ScreenCopy screen(StudioScreen screen);

  // Piece stages and verdicts.
  String stage(String apiName);
  String verdict(String code);
}

class _StudioStringsDelegate extends LocalizationsDelegate<StudioStrings> {
  const _StudioStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'ar';

  @override
  Future<StudioStrings> load(Locale locale) =>
      SynchronousFuture(StudioStrings.forLocale(locale));

  @override
  bool shouldReload(_StudioStringsDelegate old) => false;
}

class StudioStringsEn extends StudioStrings {
  const StudioStringsEn();

  @override
  String get appName => 'Jarz Studio';
  @override
  String get tabToday => 'Today';
  @override
  String get tabInbox => 'Inbox';
  @override
  String get tabCalendar => 'Calendar';
  @override
  String get tabPieces => 'Pieces';
  @override
  String get tabMore => 'More';
  @override
  String get inboxApprove => 'To approve';
  @override
  String get inboxDecisions => 'Decisions';
  @override
  String get inboxIdeas => 'Ideas';

  @override
  String get howThisWorks => 'How this works';
  @override
  String get gotIt => 'Got it';
  @override
  String get edit => 'Edit';
  @override
  String get back => 'Back';
  @override
  String get retry => 'Try again';
  @override
  String get dismiss => 'Dismiss';
  @override
  String get clear => 'Clear';
  @override
  String get showMore => 'Show more';
  @override
  String get loading => 'Loading';
  @override
  String get errorGeneric => 'Something went wrong. Try again.';
  @override
  String get changeFailed => 'That change was not saved. Try again.';
  @override
  String get languageSwitchLabel => 'Language';
  @override
  String get languageSwitchTarget => 'عربي';
  @override
  String get signOut => 'Sign out';
  @override
  String get more => 'More';
  @override
  String get nothingHere => 'Nothing here';

  @override
  String get loginTitle => 'Jarz Studio';
  @override
  String get loginSubtitle => 'Sign in with your Jarz account.';
  @override
  String get username => 'Username';
  @override
  String get password => 'Password';
  @override
  String get showPassword => 'Show password';
  @override
  String get hidePassword => 'Hide password';
  @override
  String get signIn => 'Sign in';
  @override
  String get signInFailed => 'The username or password is not right.';
  @override
  String get noAccessTitle => "You don't have Studio access";
  @override
  String get noAccessBody =>
      'You are signed in, but your account has no Studio role yet. '
      'Ask the founder or the marketing lead to add you.';
  @override
  String get checkingAccess => 'Checking your access';
  @override
  String helloUser(String name) => 'Hello, $name';

  @override
  String role(StudioRole role) => switch (role) {
    StudioRole.founder => 'Founder',
    StudioRole.lead => 'Marketing lead',
    StudioRole.creator => 'Creator',
    StudioRole.story => 'Story lead',
  };

  @override
  String todayBlock(TodayBlock block) => switch (block) {
    TodayBlock.sentBack => 'Sent back',
    TodayBlock.dueToday => 'Due today',
    TodayBlock.blocked => 'Blocked',
    TodayBlock.readyToPost => 'Ready to post',
    TodayBlock.stories => 'Stories',
    TodayBlock.readsMissing => 'Results missing',
    TodayBlock.didntGoOut => "Didn't go out",
    TodayBlock.warnings => 'System warnings',
  };

  @override
  String moreItem(MoreItem item) => switch (item) {
    MoreItem.shoots => screen(StudioScreen.shoots).title,
    MoreItem.assets => screen(StudioScreen.assets).title,
    MoreItem.references => screen(StudioScreen.references).title,
    MoreItem.paid => screen(StudioScreen.paid).title,
    MoreItem.results => screen(StudioScreen.results).title,
    MoreItem.reports => screen(StudioScreen.reports).title,
    MoreItem.settings => screen(StudioScreen.settings).title,
  };

  @override
  String stage(String apiName) => apiName;

  @override
  String verdict(String code) => code.toUpperCase();

  @override
  ScreenCopy screen(StudioScreen screen) => switch (screen) {
    StudioScreen.today => const ScreenCopy(
      title: 'Today',
      purpose:
          'What waits on you, in order: sent back, due today, '
          'ready to post, stories, results missing, what did not go out, '
          'system warnings.',
      firstStep:
          'Nothing waits on you yet. When a piece is sent back '
          'or comes due, it shows here.',
      help: [
        'Today lists what waits on you, most urgent first.',
        'The order follows your role.',
        'Tap an item to open the exact piece, shoot or post.',
        'Ticks and "Mark posted" happen here, not in a chat.',
      ],
    ),
    StudioScreen.approve => const ScreenCopy(
      title: 'To approve',
      purpose:
          'One version per page: the video, its verdict badge, '
          'the caption and where it will post.',
      firstStep:
          'Nothing is waiting. New versions land here as soon '
          'as they are ready.',
      help: [
        'Swipe through the versions waiting for your yes.',
        'Approve it, or send it back with a reason.',
        'Rate and comment on the version itself.',
        'Nothing posts until you approve it.',
      ],
    ),
    StudioScreen.decisions => const ScreenCopy(
      title: 'Decisions',
      purpose:
          'Open questions with options, pros and cons, and the '
          'recommended one.',
      firstStep:
          'No open decisions. A report that raises a question '
          'sends it here.',
      help: [
        'Each card is one question with 2 to 4 options.',
        'The recommended option is marked, but you can pick any.',
        'Add a note if the reason matters later.',
        'Reports send their open questions here.',
      ],
    ),
    StudioScreen.ideas => const ScreenCopy(
      title: 'Ideas',
      purpose:
          'Idea cards to keep or drop. A kept idea becomes a '
          'piece.',
      firstStep:
          'No ideas to review. Ideas from the team and Claude '
          'arrive here.',
      help: [
        'Keep an idea and it becomes a piece.',
        'Drop it and it leaves the list.',
        'Anyone can bring an idea; only the founder keeps or drops.',
      ],
    ),
    StudioScreen.calendar => const ScreenCopy(
      title: 'Calendar',
      purpose:
          'Agenda, week and month, by channel and status, with '
          'what moved.',
      firstStep:
          'No posts are scheduled. Give a piece a slot from '
          'Pieces to see it here.',
      help: [
        'Switch between agenda, week and month.',
        'Filter by channel and status.',
        "Give a piece a slot, move it, or mark it Won't post.",
        'Tap a post to view it; the pencil edits its caption.',
      ],
    ),
    StudioScreen.pieces => const ScreenCopy(
      title: 'Pieces',
      purpose: 'The board by stage, and "This week" by person.',
      firstStep:
          'No pieces yet. Start with a new piece, or keep an '
          'idea from the Inbox.',
      help: [
        'Every piece sits in one of nine stages, left to right.',
        '"This week" shows who owns what.',
        'Open a piece for its script, versions, ratings and results.',
        'Add a version from the piece page.',
      ],
    ),
    StudioScreen.piece => const ScreenCopy(
      title: 'Piece',
      purpose:
          'Script, versions, ratings, posts and results for one '
          'piece.',
      firstStep:
          'This piece has nothing on it yet. Add a version to '
          'begin.',
      help: [
        'Everything about one piece is on this page.',
        'Tap to read; the pencil opens the edit form.',
        'Add a version here; it goes to the founder to approve.',
      ],
    ),
    StudioScreen.shoots => const ScreenCopy(
      title: 'Shoots',
      purpose:
          'The plan, the prep list, and On set with a card for '
          'every shot.',
      firstStep:
          'No shoots planned. Plan one and its prep list is '
          'built from the pieces.',
      help: [
        'Plan a shoot, then share the prep list with operations.',
        'On set works offline: tick each shot, leave a note.',
        'Each shot card carries its references.',
      ],
    ),
    StudioScreen.shoot => const ScreenCopy(
      title: 'Shoot',
      purpose: 'Plan, prep list and shot cards for one shoot.',
      firstStep:
          'This shoot has no shots yet. Add the pieces it '
          'should cover.',
      help: [
        'Tap a shot to read its brief.',
        'On set: tick the shot and leave a note on it.',
        'The prep list is shared by link, no login needed.',
      ],
    ),
    StudioScreen.assets => const ScreenCopy(
      title: 'Library',
      purpose: 'Raw clips, photos, templates and customer content.',
      firstStep:
          'No files yet. Upload a clip or a photo and tag it '
          'with a category and flavor.',
      help: [
        'Upload from the phone, straight to storage.',
        'Tag each file with its category and flavor.',
        'Customer content needs its consent logged before you use it.',
        'Mark a file as used once it goes into a piece.',
      ],
    ),
    StudioScreen.references => const ScreenCopy(
      title: 'References',
      purpose: 'Ads and posts to learn from, and competitors.',
      firstStep:
          'No references yet. Add an ad or post worth learning '
          'from.',
      help: [
        'Add an ad or post with a link.',
        'Shortlist the ones worth acting on.',
        'Send a reference to a shoot or queue a remake.',
      ],
    ),
    StudioScreen.paid => const ScreenCopy(
      title: 'Paid',
      purpose:
          'Rounds, each ad with its numbers, and what is due '
          'today.',
      firstStep:
          'No round is running. When one starts, its ads and '
          'numbers appear here.',
      help: [
        'The numbers are filled in for you.',
        'Set each ad\'s state on day 4 and day 7.',
        'The queue holds what goes into the next round.',
        'The action itself happens in Ads Manager.',
      ],
    ),
    StudioScreen.results => const ScreenCopy(
      title: 'Results',
      purpose:
          'The scorecard, and results by piece, format and '
          'persona.',
      firstStep:
          'No results yet. The scorecard fills in as pieces '
          'are read.',
      help: [
        'The system fills the scorecard; you add what it cannot read.',
        'Review it together on Sunday.',
        'Add review notes on any result.',
      ],
    ),
    StudioScreen.reports => const ScreenCopy(
      title: 'Reports',
      purpose: 'Every page Claude produced, newest first.',
      firstStep:
          'No reports yet. The first one Claude writes shows '
          'here.',
      help: [
        'Newest report first.',
        'Open one to read it.',
        'Questions a report raises go to Decisions.',
      ],
    ),
    StudioScreen.settings => const ScreenCopy(
      title: 'Settings',
      purpose:
          'Rules, flavors, claims, moments, people and my '
          'notifications.',
      firstStep:
          'Nothing to change yet. Settings fill in when the '
          'rules are synced.',
      help: [
        'Rules, flavors, claims and moments live here.',
        'The approved-claims list is a read-only copy of the registry.',
        'Tap to view; the pencil edits.',
        'Choose which notifications reach you.',
      ],
    ),
  };
}

class StudioStringsAr extends StudioStrings {
  const StudioStringsAr();

  @override
  String get appName => 'Jarz Studio';
  @override
  String get tabToday => 'النهارده';
  @override
  String get tabInbox => 'الوارد';
  @override
  String get tabCalendar => 'التقويم';
  @override
  String get tabPieces => 'المحتوى';
  @override
  String get tabMore => 'المزيد';
  @override
  String get inboxApprove => 'للموافقة';
  @override
  String get inboxDecisions => 'القرارات';
  @override
  String get inboxIdeas => 'الأفكار';

  @override
  String get howThisWorks => 'الشاشة دي بتشتغل إزاي';
  @override
  String get gotIt => 'تمام';
  @override
  String get edit => 'تعديل';
  @override
  String get back => 'رجوع';
  @override
  String get retry => 'جرّب تاني';
  @override
  String get dismiss => 'اقفل';
  @override
  String get clear => 'امسح';
  @override
  String get showMore => 'اعرض أكتر';
  @override
  String get loading => 'بنحمّل';
  @override
  String get errorGeneric => 'حصلت مشكلة. جرّب تاني.';
  @override
  String get changeFailed => 'التغيير ما اتحفظش. جرّب تاني.';
  @override
  String get languageSwitchLabel => 'اللغة';
  @override
  String get languageSwitchTarget => 'EN';
  @override
  String get signOut => 'خروج';
  @override
  String get more => 'المزيد';
  @override
  String get nothingHere => 'مفيش حاجة هنا';

  @override
  String get loginTitle => 'Jarz Studio';
  @override
  String get loginSubtitle => 'ادخل بحساب Jarz بتاعك.';
  @override
  String get username => 'اسم المستخدم';
  @override
  String get password => 'كلمة السر';
  @override
  String get showPassword => 'إظهار كلمة السر';
  @override
  String get hidePassword => 'إخفاء كلمة السر';
  @override
  String get signIn => 'دخول';
  @override
  String get signInFailed => 'اسم المستخدم أو كلمة السر مش مظبوطين.';
  @override
  String get noAccessTitle => 'مفيش عندك صلاحية للـ Studio';
  @override
  String get noAccessBody =>
      'دخلت بحسابك، بس لسه ملكش دور في الـ Studio. '
      'اطلب من المؤسس أو مسؤول التسويق يضيفوك.';
  @override
  String get checkingAccess => 'بنراجع صلاحياتك';
  @override
  String helloUser(String name) => 'أهلاً يا $name';

  @override
  String role(StudioRole role) => switch (role) {
    StudioRole.founder => 'المؤسس',
    StudioRole.lead => 'مسؤول التسويق',
    StudioRole.creator => 'صانع محتوى',
    StudioRole.story => 'مسؤول الـ Stories',
  };

  @override
  String todayBlock(TodayBlock block) => switch (block) {
    TodayBlock.sentBack => 'اترجعت',
    TodayBlock.dueToday => 'ميعادها النهارده',
    TodayBlock.blocked => 'متعطّلة',
    TodayBlock.readyToPost => 'جاهزة للنشر',
    TodayBlock.stories => 'الـ Stories',
    TodayBlock.readsMissing => 'نتايج ناقصة',
    TodayBlock.didntGoOut => 'ما نزلش',
    TodayBlock.warnings => 'تحذيرات السيستم',
  };

  @override
  String moreItem(MoreItem item) => switch (item) {
    MoreItem.shoots => screen(StudioScreen.shoots).title,
    MoreItem.assets => screen(StudioScreen.assets).title,
    MoreItem.references => screen(StudioScreen.references).title,
    MoreItem.paid => screen(StudioScreen.paid).title,
    MoreItem.results => screen(StudioScreen.results).title,
    MoreItem.reports => screen(StudioScreen.reports).title,
    MoreItem.settings => screen(StudioScreen.settings).title,
  };

  @override
  String stage(String apiName) => switch (apiName) {
    'Idea' => 'فكرة',
    'Script' => 'سكريبت',
    'To shoot' => 'للتصوير',
    'To edit' => 'للمونتاج',
    'In review' => 'في الريفيو',
    'Approved' => 'معتمدة',
    'Scheduled' => 'مجدولة',
    'Posted' => 'اتنشرت',
    'Read' => 'اتقرت نتايجها',
    _ => apiName,
  };

  @override
  String verdict(String code) => code.toUpperCase();

  @override
  ScreenCopy screen(StudioScreen screen) => switch (screen) {
    StudioScreen.today => const ScreenCopy(
      title: 'النهارده',
      purpose:
          'اللي مستنيك بالترتيب: اللي اترجع، واللي ميعاده '
          'النهارده، والجاهز للنشر، والـ Stories، والنتايج الناقصة، '
          'واللي ما نزلش، وتحذيرات السيستم.',
      firstStep:
          'مفيش حاجة مستنية منك دلوقتي. أول ما حاجة ترجعلك أو '
          'ميعادها يجي، هتلاقيها هنا.',
      help: [
        'النهارده بيعرض اللي مستنيك، الأهم الأول.',
        'الترتيب بيتغير حسب دورك.',
        'اضغط على أي سطر يفتح القطعة أو التصوير أو البوست بالظبط.',
        'علامة اتصوّر وزرار "علّم إنه اتنشر" بيتعملوا هنا، مش في شات.',
      ],
    ),
    StudioScreen.approve => const ScreenCopy(
      title: 'للموافقة',
      purpose:
          'نسخة واحدة في كل صفحة: الفيديو، وعلامة الـ verdict، '
          'والكابشن، وهتتنشر فين.',
      firstStep: 'مفيش حاجة مستنية. أول ما نسخة تجهز هتظهر هنا.',
      help: [
        'اسحب بين النسخ المستنية موافقتك.',
        'وافق عليها، أو رجّعها بسبب.',
        'قيّم وعلّق على النسخة نفسها.',
        'مفيش حاجة بتتنشر قبل ما توافق.',
      ],
    ),
    StudioScreen.decisions => const ScreenCopy(
      title: 'القرارات',
      purpose:
          'أسئلة مفتوحة بخياراتها ومميزاتها وعيوبها، والخيار '
          'المرشّح.',
      firstStep: 'مفيش قرارات مفتوحة. أي تقرير فيه سؤال بيبعته هنا.',
      help: [
        'كل كارت سؤال واحد بـ 2 لـ 4 خيارات.',
        'الخيار المرشّح متعلّم، بس تقدر تختار أي خيار.',
        'اكتب ملاحظة لو السبب هيفرق بعدين.',
        'التقارير بتبعت أسئلتها المفتوحة هنا.',
      ],
    ),
    StudioScreen.ideas => const ScreenCopy(
      title: 'الأفكار',
      purpose:
          'كروت أفكار تحتفظ بيها أو تسيبها. الفكرة اللي '
          'بتحتفظ بيها بتبقى قطعة محتوى.',
      firstStep: 'مفيش أفكار للمراجعة. أفكار الفريق وClaude بتوصل هنا.',
      help: [
        'احتفظ بفكرة وهتبقى قطعة محتوى.',
        'سيبها وهتختفي من القايمة.',
        'أي حد يقدر يجيب فكرة، بس المؤسس هو اللي بيحتفظ أو بيسيب.',
      ],
    ),
    StudioScreen.calendar => const ScreenCopy(
      title: 'التقويم',
      purpose:
          'اليوم والأسبوع والشهر، حسب القناة والحالة، '
          'وإيه اللي اتحرك.',
      firstStep:
          'مفيش بوستات مجدولة. حدّد ميعاد لقطعة من المحتوى '
          'وهتظهر هنا.',
      help: [
        'بدّل بين اليوم والأسبوع والشهر.',
        'فلتر حسب القناة والحالة.',
        'حدّد ميعاد لقطعة، أو انقله، أو علّم إنها مش هتنزل.',
        'اضغط على بوست تشوفه، والقلم يعدّل الكابشن.',
      ],
    ),
    StudioScreen.pieces => const ScreenCopy(
      title: 'المحتوى',
      purpose: 'اللوحة حسب المرحلة، و"الأسبوع ده" حسب الشخص.',
      firstStep:
          'لسه مفيش محتوى. ابدأ بقطعة جديدة، أو احتفظ بفكرة '
          'من الوارد.',
      help: [
        'كل قطعة في مرحلة من 9 مراحل، بالترتيب.',
        '"الأسبوع ده" بيوضّح مين مسؤول عن إيه.',
        'افتح القطعة تشوف السكريبت والنسخ والتقييمات والنتايج.',
        'ضيف نسخة من صفحة القطعة.',
      ],
    ),
    StudioScreen.piece => const ScreenCopy(
      title: 'قطعة',
      purpose:
          'السكريبت والنسخ والتقييمات والبوستات والنتايج لقطعة '
          'واحدة.',
      firstStep: 'القطعة دي لسه فاضية. ضيف نسخة عشان تبدأ.',
      help: [
        'كل حاجة عن القطعة في الصفحة دي.',
        'اضغط تقرا، والقلم يفتح التعديل.',
        'ضيف نسخة هنا وهتروح للمؤسس يوافق عليها.',
      ],
    ),
    StudioScreen.shoots => const ScreenCopy(
      title: 'التصوير',
      purpose: 'الخطة، وقايمة التجهيز، ووضع On set بكارت لكل شوت.',
      firstStep:
          'مفيش تصوير مخطط. خطّط لواحد وقايمة التجهيز هتتبني '
          'من القطع.',
      help: [
        'خطّط للتصوير وابعت قايمة التجهيز للتشغيل.',
        'في On set بتشتغل من غير نت: علّم كل شوت واكتب ملاحظة.',
        'كل كارت شوت معاه المراجع بتاعته.',
      ],
    ),
    StudioScreen.shoot => const ScreenCopy(
      title: 'تصوير',
      purpose: 'الخطة وقايمة التجهيز وكروت الشوتس لتصوير واحد.',
      firstStep:
          'التصوير ده لسه مفيهوش شوتس. ضيف القطع اللي '
          'هيغطيها.',
      help: [
        'اضغط على شوت تقرا البريف بتاعه.',
        'في On set: علّم الشوت واكتب عليه ملاحظة.',
        'قايمة التجهيز بتتبعت بلينك من غير تسجيل دخول.',
      ],
    ),
    StudioScreen.assets => const ScreenCopy(
      title: 'المكتبة',
      purpose: 'الكليبات الخام والصور والتمبلتس ومحتوى العملاء.',
      firstStep:
          'لسه مفيش ملفات. ارفع كليب أو صورة وحدّد التصنيف '
          'والـ flavor.',
      help: [
        'ارفع من الموبايل على طول.',
        'حدّد لكل ملف التصنيف والـ flavor بتاعه.',
        'محتوى العملاء لازم يتسجّل إذنهم قبل ما يتستخدم.',
        'علّم الملف إنه اتستخدم لما يدخل في قطعة.',
      ],
    ),
    StudioScreen.references => const ScreenCopy(
      title: 'المراجع',
      purpose: 'إعلانات وبوستات نتعلم منها، والمنافسين.',
      firstStep: 'لسه مفيش مراجع. ضيف إعلان أو بوست يستاهل نتعلم منه.',
      help: [
        'ضيف إعلان أو بوست بلينك.',
        'اختار اللي يستاهل نشتغل عليه.',
        'ابعت المرجع لتصوير، أو اطلب نعمل منه نسخة بتاعتنا.',
      ],
    ),
    StudioScreen.paid => const ScreenCopy(
      title: 'الإعلانات',
      purpose: 'الجولات، وكل إعلان بأرقامه، وإيه المطلوب النهارده.',
      firstStep:
          'مفيش جولة شغالة. أول ما واحدة تبدأ، إعلاناتها '
          'وأرقامها هتظهر هنا.',
      help: [
        'الأرقام بتتملى لوحدها.',
        'حدّد حالة كل إعلان يوم 4 ويوم 7.',
        'الطابور فيه اللي هيدخل الجولة الجاية.',
        'التنفيذ نفسه بيتعمل في Ads Manager.',
      ],
    ),
    StudioScreen.results => const ScreenCopy(
      title: 'النتايج',
      purpose:
          'الـ scorecard، والنتايج حسب القطعة والفورمات والـ '
          'persona.',
      firstStep:
          'لسه مفيش نتايج. الـ scorecard بيتملى كل ما قطعة '
          'تتقري.',
      help: [
        'السيستم بيملا الـ scorecard، وإنت بتضيف اللي مايقدرش يقراه.',
        'بتراجعوه سوا يوم الأحد.',
        'ضيف ملاحظات المراجعة على أي نتيجة.',
      ],
    ),
    StudioScreen.reports => const ScreenCopy(
      title: 'التقارير',
      purpose: 'كل صفحة Claude عملها، الأحدث الأول.',
      firstStep: 'لسه مفيش تقارير. أول تقرير Claude يكتبه هيظهر هنا.',
      help: [
        'الأحدث الأول.',
        'افتح أي تقرير تقراه.',
        'الأسئلة اللي التقرير بيطلع بيها بتروح للقرارات.',
      ],
    ),
    StudioScreen.settings => const ScreenCopy(
      title: 'الإعدادات',
      purpose:
          'القواعد والـ flavors والـ claims والمواعيد والناس '
          'وإشعاراتي.',
      firstStep:
          'مفيش حاجة تتغيّر دلوقتي. الإعدادات بتتملى لما '
          'القواعد تتزامن.',
      help: [
        'القواعد والـ flavors والـ claims والمواعيد هنا.',
        'قايمة الـ claims المعتمدة نسخة للقراءة بس من الـ registry.',
        'اضغط تشوف، والقلم يعدّل.',
        'اختار الإشعارات اللي توصلك.',
      ],
    ),
  };
}
