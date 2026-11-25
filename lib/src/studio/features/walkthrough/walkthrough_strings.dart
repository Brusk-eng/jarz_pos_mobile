import 'package:flutter/material.dart';

import '../../core/roles/studio_role.dart';

/// One card of the first-login walkthrough.
class WalkthroughCard {
  const WalkthroughCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

/// Words of the first-login walkthrough: three or four short cards per role
/// (what Today is, what waits on you, where your main job screen is, how to get
/// help). English and Arabic sit side by side; tab names are the app's own
/// (Today / النهارده, Inbox / الوارد, Calendar / التقويم, Pieces / المحتوى,
/// More / المزيد).
class WalkthroughStrings {
  const WalkthroughStrings._(this.ar);

  final bool ar;

  static const en = WalkthroughStrings._(false);
  static const arabic = WalkthroughStrings._(true);

  static WalkthroughStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar' ? arabic : en;

  String tr(String en, String ar) => this.ar ? ar : en;

  /// The key `session.help_seen` stores for this role's walkthrough.
  static String keyFor(StudioRole role) => 'walkthrough_${role.name}';

  String get skip => tr('Skip', 'تخطّى');
  String get next => tr('Next', 'التالي');
  String get done => tr('Got it', 'تمام');
  String get helpEntry => tr('Help', 'مساعدة');
  String get helpEntryHint =>
      tr('A short tour of your screens', 'جولة قصيرة في شاشاتك');
  String step(int i, int n) => tr('$i of $n', '$i من $n');

  // The same last card for every role: where to get help.
  WalkthroughCard get _help => WalkthroughCard(
    icon: Icons.help_outline,
    title: tr('Help is on every screen', 'المساعدة في كل شاشة'),
    body: tr(
      'Tap the ? at the top of any screen: "How this works" says what the screen is for and what to do first. This tour is always in More > Help.',
      'دوس على ؟ فوق في أي شاشة: «الشاشة دي بتشتغل إزاي» بتقولك الشاشة لإيه وتبدأ بإيه. الجولة دي دايمًا في المزيد > مساعدة.',
    ),
  );

  WalkthroughCard get _today => WalkthroughCard(
    icon: Icons.today_outlined,
    title: tr('Today is where you start', 'النهارده هو نقطة البداية'),
    body: tr(
      'Today lists what waits on you, nothing else. Each line opens the exact screen, and a line you finish says what happens next.',
      'النهارده فيها اللي مستنيك بس. كل سطر بيفتح الشاشة بالظبط، والسطر اللي تخلّصه بيقولك إيه اللي هيحصل بعده.',
    ),
  );

  List<WalkthroughCard> cards(StudioRole role) => switch (role) {
    StudioRole.founder => [
      _today,
      WalkthroughCard(
        icon: Icons.inbox_outlined,
        title: tr('What waits on you', 'اللي مستنيك'),
        body: tr(
          'Versions to approve or send back, decisions to answer, ideas to keep or drop, and posts to put out by hand. They are all in Inbox and on Today.',
          'نسخ للموافقة أو الرجوع، وقرارات تحسمها، وأفكار تحتفظ بيها أو تسيبها، وبوستات تنشرها بإيدك. كلها في الوارد وفي النهارده.',
        ),
      ),
      WalkthroughCard(
        icon: Icons.campaign_outlined,
        title: tr('Your main job screens', 'شاشات شغلك الأساسية'),
        body: tr(
          'Inbox is where you approve. For paid, open More > Paid: rounds, the queue and the state of each ad. Results are in More > Results.',
          'الوارد هو مكان الموافقة. للإعلانات افتح المزيد > الإعلانات: الجولات والطابور وحالة كل إعلان. النتايج في المزيد > النتائج.',
        ),
      ),
      _help,
    ],
    StudioRole.lead => [
      _today,
      WalkthroughCard(
        icon: Icons.view_kanban_outlined,
        title: tr('What waits on you', 'اللي مستنيك'),
        body: tr(
          'Pieces that are blocked and who they wait on, what is due today, posts that did not go out and results still to add.',
          'قطع واقفة وبتستنى مين، واللي ميعاده النهارده، وبوستات ما نزلتش، ونتايج لسه ناقصة.',
        ),
      ),
      WalkthroughCard(
        icon: Icons.calendar_month_outlined,
        title: tr('Your main job screens', 'شاشات شغلك الأساسية'),
        body: tr(
          'Pieces > This week: give every piece an owner and a date. Calendar: fill the slots and fix what did not go out.',
          'المحتوى > الأسبوع ده: اديّ كل قطعة صاحب وميعاد. التقويم: املا المواعيد وصلّح اللي ما نزلش.',
        ),
      ),
      _help,
    ],
    StudioRole.creator => [
      _today,
      WalkthroughCard(
        icon: Icons.videocam_outlined,
        title: tr('What waits on you', 'اللي مستنيك'),
        body: tr(
          'Pieces sent back to you with the reason, what is due today and the shoot tomorrow.',
          'قطع اترجعتلك مع السبب، واللي ميعاده النهارده، والتصوير بكرة.',
        ),
      ),
      WalkthroughCard(
        icon: Icons.photo_library_outlined,
        title: tr('Your main job screens', 'شاشات شغلك الأساسية'),
        body: tr(
          'More > Shoots: open the shoot, tap On set and tick each shot as you film it (it works without a connection). More > Library: upload clips and cuts.',
          'المزيد > التصوير: افتح التصوير ودوس على On set وعلّم كل شوت وإنت بتصوّره (بيشتغل من غير نت). المزيد > المكتبة: ارفع الكليبات والنسخ.',
        ),
      ),
      WalkthroughCard(
        icon: Icons.lightbulb_outline,
        title: tr('Bring ideas', 'هات أفكار'),
        body: tr(
          'Inbox > Ideas: tap New idea to send one to the founder, and My ideas to see what happened to each.',
          'الوارد > الأفكار: دوس على «فكرة جديدة» وابعتها للمؤسس، وفي «أفكاري» تشوف حصل إيه في كل واحدة.',
        ),
      ),
      _help,
    ],
    StudioRole.story => [
      _today,
      WalkthroughCard(
        icon: Icons.auto_stories_outlined,
        title: tr('What waits on you', 'اللي مستنيك'),
        body: tr(
          'The Stories to put out today, frame by frame, and the tasks due today.',
          'الـ Stories اللي تتنشر النهارده، فريم فريم، والمهام اللي ميعادها النهارده.',
        ),
      ),
      WalkthroughCard(
        icon: Icons.photo_library_outlined,
        title: tr('Your main job screens', 'شاشات شغلك الأساسية'),
        body: tr(
          'On Today, open the Stories line and tap "Post the frames": mark each frame posted, or skip it with a reason. More > Library: upload and tag photos and clips.',
          'في النهارده افتح سطر الـ Stories ودوس «انشر الفريمات»: علّم كل فريم إنه اتنشر، أو تخطّاه مع السبب. المزيد > المكتبة: ارفع الصور والكليبات وحط لها تاج.',
        ),
      ),
      _help,
    ],
  };
}
