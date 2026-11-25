import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/studio_enums.dart';
import '../data/calendar_repository.dart';
import 'cairo_time.dart';

enum CalendarMode { week, month }

/// Today's date in Cairo. Tests override it.
final calendarTodayProvider = Provider<DateTime>((ref) {
  final cairo = DateTime.now().toUtc().add(const Duration(hours: 2));
  return DateTime(cairo.year, cairo.month, cairo.day);
});

final calendarModeProvider = StateProvider<CalendarMode>(
  (ref) => CalendarMode.week,
);

/// Any day inside the week or month on screen. Null means today.
final calendarAnchorProvider = StateProvider<DateTime?>((ref) => null);

final calendarChannelFilterProvider = StateProvider<PostChannel?>(
  (ref) => null,
);

/// The window to fetch for [mode] around [anchor], as dates.
CalendarWindow calendarWindowFor(CalendarMode mode, DateTime anchor) {
  if (mode == CalendarMode.week) {
    final start = CairoTime.weekStart(anchor);
    return (
      from: CairoTime.date(start),
      to: CairoTime.date(CairoTime.addDays(start, 6)),
    );
  }
  final first = DateTime(anchor.year, anchor.month, 1);
  final last = DateTime(anchor.year, anchor.month + 1, 0);
  final start = CairoTime.weekStart(first);
  final end = CairoTime.addDays(CairoTime.weekStart(last), 6);
  return (from: CairoTime.date(start), to: CairoTime.date(end));
}
