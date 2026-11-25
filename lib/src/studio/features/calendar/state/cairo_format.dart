import 'cairo_time.dart';

/// Short dates in words, English or Arabic, without needing locale data.
class CairoFormat {
  CairoFormat._();

  static const _monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _monthsAr = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', //
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
  static const _daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _daysAr = [
    'الاتنين', 'التلات', 'الأربع', 'الخميس', 'الجمعة', 'السبت', 'الأحد', //
  ];

  static String month(DateTime d, bool ar) =>
      (ar ? _monthsAr : _monthsEn)[d.month - 1];

  static String weekday(DateTime d, bool ar) =>
      (ar ? _daysAr : _daysEn)[d.weekday - 1];

  /// `25 Nov` / `25 نوفمبر`.
  static String dayMonth(DateTime d, bool ar) => '${d.day} ${month(d, ar)}';

  /// `Wed 25 Nov`.
  static String full(DateTime d, bool ar) =>
      '${weekday(d, ar)} ${dayMonth(d, ar)}';

  /// `Wed 25 Nov` from a `yyyy-mm-dd` (or full wire) string: the one way the
  /// app writes a date that came as text. Anything unreadable comes back as it
  /// was, so nothing is lost.
  static String isoDay(String? iso, bool ar) {
    final d = CairoTime.parse(iso);
    return d == null ? (iso ?? '') : full(d, ar);
  }

  /// `Nov 2026`.
  static String monthYear(DateTime d, bool ar) => '${month(d, ar)} ${d.year}';

  /// `25 Nov, 13:00` from a wire string, or the empty string.
  static String stamp(String? iso, bool ar) {
    final d = CairoTime.parse(iso);
    if (d == null) return '';
    final hasTime = iso!.length >= 16 && iso[10] == 'T';
    return hasTime
        ? '${dayMonth(d, ar)}, ${CairoTime.time(d)}'
        : dayMonth(d, ar);
  }
}
