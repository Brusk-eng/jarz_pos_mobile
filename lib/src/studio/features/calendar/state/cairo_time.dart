/// Dates and times as the Studio data layer gives them: ISO strings that carry
/// the Africa/Cairo offset. They are read as written (no conversion to the
/// device's zone), so a slot at 13:00 Cairo shows 13:00 everywhere.
class CairoTime {
  CairoTime._();

  /// Reads `2026-12-01T13:00:00+02:00` (or a plain date) as a wall-clock
  /// DateTime with no zone. Null for null or unreadable input.
  static DateTime? parse(String? iso) {
    if (iso == null || iso.length < 10) return null;
    final y = int.tryParse(iso.substring(0, 4));
    final m = int.tryParse(iso.substring(5, 7));
    final d = int.tryParse(iso.substring(8, 10));
    if (y == null || m == null || d == null) return null;
    var hh = 0, mm = 0;
    if (iso.length >= 16 && (iso[10] == 'T' || iso[10] == ' ')) {
      hh = int.tryParse(iso.substring(11, 13)) ?? 0;
      mm = int.tryParse(iso.substring(14, 16)) ?? 0;
    }
    return DateTime(y, m, d, hh, mm);
  }

  static String _p(int v, [int w = 2]) => v.toString().padLeft(w, '0');

  /// `2026-11-23`.
  static String date(DateTime d) => '${_p(d.year, 4)}-${_p(d.month)}-${_p(d.day)}';

  /// `13:00`.
  static String time(DateTime d) => '${_p(d.hour)}:${_p(d.minute)}';

  /// Egypt's summer time runs from the last Friday of April to the last
  /// Thursday of October (UTC+3); the rest of the year is UTC+2.
  static String offsetFor(DateTime d) {
    DateTime lastWeekday(int year, int month, int weekday) {
      var x = DateTime(year, month + 1, 0);
      while (x.weekday != weekday) {
        x = x.subtract(const Duration(days: 1));
      }
      return x;
    }

    final start = lastWeekday(d.year, 4, DateTime.friday);
    final end = lastWeekday(d.year, 10, DateTime.thursday);
    final day = DateTime(d.year, d.month, d.day);
    final summer = !day.isBefore(start) && !day.isAfter(end);
    return summer ? '+03:00' : '+02:00';
  }

  /// A wall-clock time as the wire string `2026-12-01T13:00:00+02:00`.
  static String wire(DateTime d) =>
      '${date(d)}T${time(d)}:00${offsetFor(d)}';

  /// The Saturday that starts the Studio week containing [d].
  static DateTime weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final back = (day.weekday - DateTime.saturday) % 7;
    return day.subtract(Duration(days: back));
  }

  static DateTime addDays(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day + n);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
