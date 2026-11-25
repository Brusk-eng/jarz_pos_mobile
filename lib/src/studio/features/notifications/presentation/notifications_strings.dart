import 'package:flutter/material.dart';

import '../../../core/l10n/studio_strings.dart' show ScreenCopy;

abstract class NotificationsStrings {
  const NotificationsStrings();

  static NotificationsStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const NotificationsStringsAr()
      : const NotificationsStringsEn();

  ScreenCopy get listCopy;
  ScreenCopy get prefsCopy;
  String get markAllRead;
  String get settings;
  String get unread;
  String get allRead;
  String get nextList;
  String get quietHours;
  String get quietFrom;
  String get quietTo;
  String get notSet;
  String get clearQuiet;
  String get digest;
  String get digestOn;
  String get digestTime;
  String get eventsTitle;
  String get eventsNote;
  String get quietNote;
  String get saved;
  String audience(String raw);
}

class NotificationsStringsEn extends NotificationsStrings {
  const NotificationsStringsEn();
  @override
  ScreenCopy get listCopy => const ScreenCopy(
    title: 'Notifications',
    purpose: 'Everything the Studio told you, newest first.',
    firstStep:
        'Nothing yet. When something needs you (a version to approve, a piece '
        'sent back, a shoot tomorrow) it shows here and arrives on your phone.',
    help: [
      'Each row opens the exact thing it is about.',
      'Opening a row marks it read.',
      'Mark all read clears the badge.',
      'Quiet hours hold notifications; they still wait here.',
    ],
  );
  @override
  ScreenCopy get prefsCopy => const ScreenCopy(
    title: 'My notifications',
    purpose: 'When the Studio may notify you, and the daily digest.',
    firstStep: 'Set quiet hours and choose if you want a daily digest.',
    help: [
      'Quiet hours hold notifications until they end.',
      'Held notifications still wait in the list.',
      'The digest is one notification a day with what waits on you.',
      'What you are told about depends on your role.',
    ],
  );
  @override
  String get markAllRead => 'Mark all read';
  @override
  String get settings => 'Notification settings';
  @override
  String get unread => 'Unread';
  @override
  String get allRead => 'All caught up.';
  @override
  String get nextList => 'Tap a row to open what it is about.';
  @override
  String get quietHours => 'Quiet hours';
  @override
  String get quietFrom => 'From';
  @override
  String get quietTo => 'Until';
  @override
  String get notSet => 'Not set';
  @override
  String get clearQuiet => 'Clear quiet hours';
  @override
  String get digest => 'Daily digest';
  @override
  String get digestOn => 'Send me a daily digest';
  @override
  String get digestTime => 'Digest time';
  @override
  String get eventsTitle => 'What you are told about';
  @override
  String get eventsNote =>
      'Set by your role. You cannot switch these off one by one yet.';
  @override
  String get quietNote =>
      'Notifications held in quiet hours arrive when they end.';
  @override
  String get saved => 'Saved';
  @override
  String audience(String raw) => raw;
}

class NotificationsStringsAr extends NotificationsStrings {
  const NotificationsStringsAr();
  @override
  ScreenCopy get listCopy => const ScreenCopy(
    title: 'الإشعارات',
    purpose: 'كل اللي الـ Studio قالهولك، الأحدث الأول.',
    firstStep:
        'لسه مفيش حاجة. لما حاجة تحتاجك (نسخة للموافقة، قطعة اترجعت، '
        'تصوير بكرة) هتظهر هنا وهتوصلك إشعار على موبايلك.',
    help: [
      'كل سطر بيفتح الحاجة اللي بيتكلم عنها.',
      'لما تفتح سطر بيتعلّم إنه اتقرا.',
      'علّم الكل اتقرا بيشيل العدّاد.',
      'ساعات الهدوء بتأجّل الإشعارات، وبتفضل مستنية هنا.',
    ],
  );
  @override
  ScreenCopy get prefsCopy => const ScreenCopy(
    title: 'إشعاراتي',
    purpose: 'امتى الـ Studio يبعت لك إشعارات، والملخص اليومي.',
    firstStep: 'حدّد ساعات الهدوء واختار تاخد ملخص يومي ولا لأ.',
    help: [
      'ساعات الهدوء بتأجّل الإشعارات لحد ما تخلص.',
      'الإشعارات المتأجلة بتفضل مستنية في القايمة.',
      'الملخص إشعار واحد في اليوم فيه اللي مستني منك.',
      'اللي بيوصلك بيتحدد حسب دورك.',
    ],
  );
  @override
  String get markAllRead => 'علّم الكل اتقرا';
  @override
  String get settings => 'إعدادات الإشعارات';
  @override
  String get unread => 'جديد';
  @override
  String get allRead => 'مفيش جديد.';
  @override
  String get nextList => 'اضغط على أي سطر يفتح الحاجة نفسها.';
  @override
  String get quietHours => 'ساعات الهدوء';
  @override
  String get quietFrom => 'من';
  @override
  String get quietTo => 'لحد';
  @override
  String get notSet => 'مش متحدد';
  @override
  String get clearQuiet => 'امسح ساعات الهدوء';
  @override
  String get digest => 'الملخص اليومي';
  @override
  String get digestOn => 'ابعتلي ملخص يومي';
  @override
  String get digestTime => 'ميعاد الملخص';
  @override
  String get eventsTitle => 'اللي بيوصلك';
  @override
  String get eventsNote => 'بيتحدد حسب دورك. لسه مينفعش تقفل كل إشعار لوحده.';
  @override
  String get quietNote => 'الإشعارات المتأجلة بتوصل لما ساعات الهدوء تخلص.';
  @override
  String get saved => 'اتحفظ';
  @override
  String audience(String raw) => switch (raw) {
    'Founder' => 'المؤسس',
    'Crew' => 'فريق التصوير',
    _ => raw,
  };
}
