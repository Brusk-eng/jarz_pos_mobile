import 'package:flutter/widgets.dart';

/// Texts of the More menu and the words every More screen shares (errors,
/// buttons, dates, money), English and Arabic, in the same pattern as
/// `StudioStrings`: an abstract class with one implementation per language, so
/// a text missing in Arabic fails the build.
///
/// Brand and product words people say in English (Jarz, Studio, flavor, size,
/// dessert, order, costly) stay in English inside Arabic. The Arabic gets a
/// language review later.
abstract class MoreStrings {
  const MoreStrings();

  static MoreStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const MoreStringsAr()
      : const MoreStringsEn();

  bool get isArabic;

  // ---- The More menu ----------------------------------------------------
  String get moreTitle;
  String get moreHelpTitle;
  List<String> get moreHelp;
  String get moreEmpty;
  String get moreEmptyFirstStep;
  String get entryLibrary;
  String get entryShoots;
  String get entryReferences;
  String get entryPaid;
  String get entryResults;
  String get entryReports;
  String get entrySettings;
  String get entryNotifications;
  String get languageRow;
  String get languageName;
  String get signOutRow;
  String appVersion(String v);

  // ---- Shared words -----------------------------------------------------
  String get cancel;
  String get save;
  String get saved;
  String get add;
  String get remove;
  String get close;
  String get retry;
  String get search;
  String get clear;
  String get all;
  String get showMore;
  String get showMoreFailed;
  String get optional;
  String get none;
  String get yes;
  String get no;
  String get openInBrowser;
  String get couldNotOpen;
  String get pickDate;
  String get diagnosticsOnly;
  String get howThisWorks;

  // ---- Errors, in plain words ------------------------------------------
  String get errShadow;
  String get errStale;
  String get errNotPermitted;
  String get errAlreadyDone;
  String get errNetwork;
  String get errNotFound;
  String get errGeneric;

  // ---- Numbers and dates ------------------------------------------------
  String egp(num amount);
  String date(String? iso);
  String dateTime(String? iso);
  String percent(double v, {int digits = 1});
}

const _daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthsEn = [
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
const _daysAr = [
  'الاتنين',
  'التلات',
  'الأربع',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];
const _monthsAr = [
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

/// 1234567 -> "1,234,567".
String groupDigits(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return v < 0 ? '-$b' : '$b';
}

final _isoRe = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2}))?');

String _fmtDate(
  String? iso,
  List<String> days,
  List<String> months, {
  bool time = false,
}) {
  if (iso == null || iso.isEmpty) return '';
  final m = _isoRe.firstMatch(iso);
  if (m == null) return iso;
  final d = DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  final base = '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  return time && m[4] != null ? '$base ${m[4]}:${m[5]}' : base;
}

class MoreStringsEn extends MoreStrings {
  const MoreStringsEn();

  @override
  bool get isArabic => false;

  @override
  String get moreTitle => 'More';
  @override
  String get moreHelpTitle => 'More';
  @override
  List<String> get moreHelp => const [
    'Everything outside the five main tabs lives here.',
    'You only see what your role can use.',
    'Switch the language or sign out at the bottom.',
  ];
  @override
  String get moreEmpty => 'Nothing here for your role yet.';
  @override
  String get moreEmptyFirstStep =>
      'Ask the founder to give you a Studio role, then sign in again.';
  @override
  String get entryLibrary => 'Library';
  @override
  String get entryShoots => 'Shoots';
  @override
  String get entryReferences => 'References';
  @override
  String get entryPaid => 'Paid';
  @override
  String get entryResults => 'Results';
  @override
  String get entryReports => 'Reports';
  @override
  String get entrySettings => 'Settings';
  @override
  String get entryNotifications => 'Notification settings';
  @override
  String get languageRow => 'Language';
  @override
  String get languageName => 'English';
  @override
  String get signOutRow => 'Sign out';
  @override
  String appVersion(String v) => 'Version $v';

  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get saved => 'Saved';
  @override
  String get add => 'Add';
  @override
  String get remove => 'Remove';
  @override
  String get close => 'Close';
  @override
  String get retry => 'Try again';
  @override
  String get search => 'Search';
  @override
  String get clear => 'Clear';
  @override
  String get all => 'All';
  @override
  String get showMore => 'Show more';
  @override
  String get showMoreFailed => 'Could not load more. Try again.';
  @override
  String get optional => 'Optional';
  @override
  String get none => 'None';
  @override
  String get yes => 'Yes';
  @override
  String get no => 'No';
  @override
  String get openInBrowser => 'Open in the browser';
  @override
  String get couldNotOpen => 'Could not open the link.';
  @override
  String get pickDate => 'Pick a date';
  @override
  String get diagnosticsOnly => 'Diagnostics only. They do not decide.';
  @override
  String get howThisWorks => 'How this works';

  @override
  String get errShadow =>
      'The Studio is not switched on yet. You can look, but not change '
      'anything.';
  @override
  String get errStale =>
      'Someone changed this a moment ago. We loaded the latest, check it and '
      'try again.';
  @override
  String get errNotPermitted => 'You cannot do that.';
  @override
  String get errAlreadyDone => 'Already done. Showing how it stands now.';
  @override
  String get errNetwork => 'No connection. Check the internet and try again.';
  @override
  String get errNotFound => 'That is no longer there.';
  @override
  String get errGeneric => 'Something went wrong. Try again.';

  @override
  String egp(num amount) => 'EGP ${groupDigits(amount.round())}';
  @override
  String date(String? iso) => _fmtDate(iso, _daysEn, _monthsEn);
  @override
  String dateTime(String? iso) => _fmtDate(iso, _daysEn, _monthsEn, time: true);
  @override
  String percent(double v, {int digits = 1}) => '${v.toStringAsFixed(digits)}%';
}

class MoreStringsAr extends MoreStrings {
  const MoreStringsAr();

  @override
  bool get isArabic => true;

  @override
  String get moreTitle => 'المزيد';
  @override
  String get moreHelpTitle => 'المزيد';
  @override
  List<String> get moreHelp => const [
    'هنا كل اللي برّه التابات الخمسة.',
    'بتشوف بس اللي دورك محتاجه.',
    'تغيّر اللغة أو تسجّل خروج من تحت.',
  ];
  @override
  String get moreEmpty => 'مفيش حاجة هنا لدورك لسه.';
  @override
  String get moreEmptyFirstStep =>
      'اطلب من المؤسس يديك دور في الـ Studio وبعدين ادخل تاني.';
  @override
  String get entryLibrary => 'المكتبة';
  @override
  String get entryShoots => 'التصوير';
  @override
  String get entryReferences => 'المراجع';
  @override
  String get entryPaid => 'الإعلانات';
  @override
  String get entryResults => 'النتائج';
  @override
  String get entryReports => 'التقارير';
  @override
  String get entrySettings => 'الإعدادات';
  @override
  String get entryNotifications => 'إعدادات الإشعارات';
  @override
  String get languageRow => 'اللغة';
  @override
  String get languageName => 'العربية';
  @override
  String get signOutRow => 'تسجيل خروج';
  @override
  String appVersion(String v) => 'الإصدار $v';

  @override
  String get cancel => 'إلغاء';
  @override
  String get save => 'حفظ';
  @override
  String get saved => 'اتحفظ';
  @override
  String get add => 'إضافة';
  @override
  String get remove => 'شيل';
  @override
  String get close => 'قفل';
  @override
  String get retry => 'جرّب تاني';
  @override
  String get search => 'بحث';
  @override
  String get clear => 'مسح';
  @override
  String get all => 'الكل';
  @override
  String get showMore => 'اعرض أكتر';
  @override
  String get showMoreFailed => 'مقدرناش نحمّل أكتر. جرّب تاني.';
  @override
  String get optional => 'اختياري';
  @override
  String get none => 'مفيش';
  @override
  String get yes => 'أيوه';
  @override
  String get no => 'لأ';
  @override
  String get openInBrowser => 'افتح في المتصفح';
  @override
  String get couldNotOpen => 'مقدرناش نفتح اللينك.';
  @override
  String get pickDate => 'اختار تاريخ';
  @override
  String get diagnosticsOnly => 'للمتابعة بس. مش هي اللي بتحسم.';
  @override
  String get howThisWorks => 'إزاي ده بيشتغل';

  @override
  String get errShadow => 'الـ Studio لسه مش شغّال. تقدر تشوف بس، مش تغيّر.';
  @override
  String get errStale =>
      'حد غيّر ده من لحظة. حمّلنا آخر نسخة، راجعها وجرّب تاني.';
  @override
  String get errNotPermitted => 'مش مسموح لك بده.';
  @override
  String get errAlreadyDone => 'اتعمل قبل كده. بنعرض الحالة دلوقتي.';
  @override
  String get errNetwork => 'مفيش اتصال. اتأكد من النت وجرّب تاني.';
  @override
  String get errNotFound => 'ده مبقاش موجود.';
  @override
  String get errGeneric => 'حصلت مشكلة. جرّب تاني.';

  @override
  String egp(num amount) => '${groupDigits(amount.round())} EGP';
  @override
  String date(String? iso) => _fmtDate(iso, _daysAr, _monthsAr);
  @override
  String dateTime(String? iso) => _fmtDate(iso, _daysAr, _monthsAr, time: true);
  @override
  String percent(double v, {int digits = 1}) => '${v.toStringAsFixed(digits)}%';
}
