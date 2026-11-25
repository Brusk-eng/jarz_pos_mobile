import 'package:flutter/material.dart';

import '../../../core/l10n/plural.dart';

/// Inbox strings (hub, to-approve list, and the plain-word errors shared by the
/// Today, Inbox, Decisions, Ideas and Notifications screens). English and
/// Arabic; the Arabic is simple Egyptian-friendly wording and gets a language
/// review later.
abstract class InboxStrings {
  const InboxStrings();

  static InboxStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const InboxStringsAr()
      : const InboxStringsEn();

  bool get isArabic;

  // Hub tiles.
  String get hubToApprove;
  String get hubToRate;
  String get hubDecisions;
  String get hubIdeas;
  String get hubNotifications;

  // To approve list.
  String get approveEmptyPurpose;
  String get approveEmptyFirstStep;
  String waiting(String duration);
  String get noSlot;
  String get notJudged;
  String sellScore(String score);
  String get stale;
  String get loadMore;
  String get notYourList;
  String get nextStepApprove;

  // Common words.
  String get cancel;
  String get save;
  String get confirm;
  String get add;
  String get open;
  String get refresh;
  String get justNow;
  String minutes(int n);
  String hours(int n);
  String days(int n);
  List<String> get weekdays; // Monday first
  List<String> get months;

  // Plain-word errors.
  String get errShadow;
  String get errGateHeader;
  String get errStale;
  String get errNotPermitted;
  String get errNotFound;
  String get errAlreadyDone;
  String get errNetwork;
  String get errRate;
  String get errServer;
  String get errGeneric;
}

class InboxStringsEn extends InboxStrings {
  const InboxStringsEn();
  @override
  bool get isArabic => false;
  @override
  String get hubToApprove => 'To approve';
  @override
  String get hubToRate => 'To rate';
  @override
  String get hubDecisions => 'Decisions';
  @override
  String get hubIdeas => 'Ideas';
  @override
  String get hubNotifications => 'Notifications';
  @override
  String get approveEmptyPurpose =>
      'Versions waiting for your yes show up here, oldest first.';
  @override
  String get approveEmptyFirstStep =>
      'Nothing is waiting. When a version is ready it lands here and you get a push.';
  @override
  String waiting(String d) => 'waiting $d';
  @override
  String get noSlot => 'No slot yet';
  @override
  String get notJudged => 'Not judged yet';
  @override
  String sellScore(String s) => 'sell $s';
  @override
  String get stale => 'out of date';
  @override
  String get loadMore => 'Show more';
  @override
  String get notYourList =>
      'This list is not part of your work. Use the other sections above.';
  @override
  String get nextStepApprove =>
      'Next: tap a version, then approve it or send it back with a reason. '
      'Nothing posts until you approve.';
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get confirm => 'Confirm';
  @override
  String get add => 'Add';
  @override
  String get open => 'Open';
  @override
  String get refresh => 'Refresh';
  @override
  String get justNow => 'just now';
  @override
  String minutes(int n) => '$n min';
  @override
  String hours(int n) => n == 1 ? '1 hour' : '$n hours';
  @override
  String days(int n) => n == 1 ? '1 day' : '$n days';
  @override
  List<String> get weekdays => const [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  @override
  List<String> get months => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  @override
  String get errShadow =>
      'The Studio is not switched on yet, so nothing was changed.';
  @override
  String get errGateHeader => 'The check failed. Fix these and try again:';
  @override
  String get errStale =>
      'This changed since you opened it. Refresh the page and try again.';
  @override
  String get errNotPermitted => 'Your role cannot do that.';
  @override
  String get errNotFound => 'This is no longer there. Go back and refresh.';
  @override
  String get errAlreadyDone => 'Already done. This is how it stands now.';
  @override
  String get errNetwork => 'No connection. Check the internet and try again.';
  @override
  String get errRate => 'Too many tries in a row. Wait a moment and try again.';
  @override
  String get errServer => 'Something went wrong on our side. Try again soon.';
  @override
  String get errGeneric => 'Something went wrong. Try again.';
}

class InboxStringsAr extends InboxStrings {
  const InboxStringsAr();
  @override
  bool get isArabic => true;
  @override
  String get hubToApprove => 'للموافقة';
  @override
  String get hubToRate => 'للتقييم';
  @override
  String get hubDecisions => 'القرارات';
  @override
  String get hubIdeas => 'الأفكار';
  @override
  String get hubNotifications => 'الإشعارات';
  @override
  String get approveEmptyPurpose =>
      'النسخ اللي مستنية موافقتك بتظهر هنا، الأقدم الأول.';
  @override
  String get approveEmptyFirstStep =>
      'مفيش حاجة مستنية. أول ما نسخة تجهز هتظهر هنا وهييجيلك إشعار.';
  @override
  String waiting(String d) => 'مستنية بقالها $d';
  @override
  String get noSlot => 'لسه من غير ميعاد';
  @override
  String get notJudged => 'لسه ماتقيّمتش';
  @override
  String sellScore(String s) => 'درجة البيع $s';
  @override
  String get stale => 'قديمة';
  @override
  String get loadMore => 'اعرض أكتر';
  @override
  String get notYourList => 'القايمة دي مش لدورك. استخدم الأقسام التانية فوق.';
  @override
  String get nextStepApprove =>
      'الخطوة الجاية: افتح نسخة، ووافق عليها أو رجّعها بسبب. '
      'مفيش حاجة بتنزل قبل موافقتك.';
  @override
  String get cancel => 'إلغاء';
  @override
  String get save => 'احفظ';
  @override
  String get confirm => 'تمام';
  @override
  String get add => 'ضيف';
  @override
  String get open => 'افتح';
  @override
  String get refresh => 'حدّث';
  @override
  String get justNow => 'دلوقتي';
  @override
  String minutes(int n) =>
      arCount(n, one: 'دقيقة', two: 'دقيقتين', few: 'دقايق', many: 'دقيقة');
  @override
  String hours(int n) =>
      arCount(n, one: 'ساعة', two: 'ساعتين', few: 'ساعات', many: 'ساعة');
  @override
  String days(int n) => arDay.of(n);
  @override
  List<String> get weekdays => const [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  @override
  List<String> get months => const [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  @override
  String get errShadow => 'الـ Studio لسه مش شغّال، فمفيش حاجة اتغيّرت.';
  @override
  String get errGateHeader => 'الفحص مانجحش. صلّح اللي تحت وجرّب تاني:';
  @override
  String get errStale => 'اتغيّر من ساعة ما فتحته. حدّث الصفحة وجرّب تاني.';
  @override
  String get errNotPermitted => 'مش مسموح لدورك.';
  @override
  String get errNotFound => 'ده مبقاش موجود. ارجع وحدّث الصفحة.';
  @override
  String get errAlreadyDone => 'اتعمل قبل كده. دي الحالة دلوقتي.';
  @override
  String get errNetwork => 'مفيش نت. اتأكد من الاتصال وجرّب تاني.';
  @override
  String get errRate => 'محاولات كتير ورا بعض. استنى شوية وجرّب تاني.';
  @override
  String get errServer => 'حصلت مشكلة عندنا. جرّب تاني كمان شوية.';
  @override
  String get errGeneric => 'حصلت مشكلة. جرّب تاني.';
}
