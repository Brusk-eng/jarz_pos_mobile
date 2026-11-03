/// "Repeat every {weekday}" — `roster.apply_weekly_change`
/// (Feature: roster-repeat-weekly).
///
/// One person's single-day edit (a shift, a branch move, or a day off with its
/// cover) made their standing week from that day on. Plain classes with
/// hand-written `fromJson`, in the style of `roster_plan_models.dart`: every
/// field tolerates being missing or null, so a partial response degrades to
/// "nothing to list", never to a crash.
library;

import 'roster_plan_models.dart' show rosterPlanWeekdays;

/// The English weekday name of an ISO date (`2026-11-08` -> `Sunday`), the
/// value the backend speaks; null when [isoDate] is not a date.
String? rosterWeekdayOf(String isoDate) {
  // Parsed as UTC midnight: a local midnight can fall in a DST gap (Egypt
  // springs forward at 00:00) and normalise back into the previous day.
  if (isoDate.length < 10) return null;
  final parsed = DateTime.tryParse('${isoDate.substring(0, 10)}T00:00:00Z');
  if (parsed == null) return null;
  // DateTime.weekday: Monday = 1 ... Sunday = 7. rosterPlanWeekdays starts
  // on Saturday, so Saturday (6) maps to index 0.
  return rosterPlanWeekdays[(parsed.weekday + 1) % 7];
}

/// What "Repeat every {weekday}" sends. Built from the single-day sheet's
/// choice; [toPayload] is the contract's `payload` object.
class RosterWeeklyChange {
  const RosterWeeklyChange.assign({
    required this.employee,
    required this.date,
    required String this.shiftType,
    this.shiftLocation,
    this.replaceManual = false,
  }) : action = 'assign',
       offType = null,
       coveredBy = null,
       coverShiftType = null,
       notes = null;

  const RosterWeeklyChange.dayOff({
    required this.employee,
    required this.date,
    required String this.offType,
    this.coveredBy,
    this.coverShiftType,
    this.notes,
    this.replaceManual = false,
  }) : action = 'day_off',
       shiftType = null,
       shiftLocation = null;

  const RosterWeeklyChange._({
    required this.employee,
    required this.date,
    required this.action,
    this.shiftType,
    this.shiftLocation,
    this.offType,
    this.coveredBy,
    this.coverShiftType,
    this.notes,
    this.replaceManual = false,
  });

  final String employee;

  /// The first day (ISO). Its weekday is the one repeated.
  final String date;

  /// `assign` | `day_off`.
  final String action;

  final String? shiftType;

  /// Null keeps the server's own branch resolution (the person's usual one).
  final String? shiftLocation;

  final String? offType;
  final String? coveredBy;
  final String? coverShiftType;
  final String? notes;

  /// Overwrite the later one-off days too, instead of keeping them.
  final bool replaceManual;

  bool get isDayOff => action == 'day_off';

  /// English weekday of [date]; what the preview will repeat.
  String? get weekday => rosterWeekdayOf(date);

  RosterWeeklyChange copyWith({bool? replaceManual}) => RosterWeeklyChange._(
    employee: employee,
    date: date,
    action: action,
    shiftType: shiftType,
    shiftLocation: shiftLocation,
    offType: offType,
    coveredBy: coveredBy,
    coverShiftType: coverShiftType,
    notes: notes,
    replaceManual: replaceManual ?? this.replaceManual,
  );

  /// The contract's payload. Never carries a POS grant: the weekly endpoint
  /// does not give day access, so the sheet does not offer one.
  Map<String, dynamic> toPayload() => {
    'employee': employee,
    'date': date,
    'action': action,
    if (isDayOff) ...{
      'off_type': offType,
      'covered_by': _blankToNull(coveredBy),
      // A cover shift without a coverer means nothing; the server rejects it.
      'cover_shift_type': _blankToNull(coveredBy) == null
          ? null
          : _blankToNull(coverShiftType),
      'notes': _blankToNull(notes),
    } else ...{
      'shift_type': shiftType,
      'shift_location': _blankToNull(shiftLocation),
    },
    'replace_manual': replaceManual,
  };
}

/// A later day that was edited one by one and is kept (or replaced).
class RosterWeeklyKeptDay {
  const RosterWeeklyKeptDay({
    required this.date,
    required this.employee,
    this.employeeName,
    this.kind = '',
    this.current,
  });

  final String date;
  final String employee;
  final String? employeeName;

  /// `day_off` | `cover` | `shift` | `empty`.
  final String kind;

  /// Server text: "Off", "Covering Hassan", the shift, "Empty".
  final String? current;

  String get displayName {
    final name = (employeeName ?? '').trim();
    return name.isEmpty ? employee : name;
  }

  factory RosterWeeklyKeptDay.fromJson(Map<String, dynamic> json) =>
      RosterWeeklyKeptDay(
        date: (json['date'] ?? '').toString(),
        employee: (json['employee'] ?? '').toString(),
        employeeName: _nullIfBlank(json['employee_name']),
        kind: (json['kind'] ?? '').toString(),
        current: _nullIfBlank(json['current']),
      );
}

class RosterWeeklyWarning {
  const RosterWeeklyWarning({
    required this.code,
    required this.message,
    this.employee,
    this.dates = const [],
  });

  final String code;
  final String message;
  final String? employee;
  final List<String> dates;

  factory RosterWeeklyWarning.fromJson(Map<String, dynamic> json) =>
      RosterWeeklyWarning(
        code: (json['code'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
        employee: _nullIfBlank(json['employee']),
        dates: _strings(json['dates']),
      );
}

/// One line of the standing (weekly) rota that changes.
class RosterWeeklyStanding {
  const RosterWeeklyStanding({
    required this.employee,
    this.employeeName,
    this.weekday = '',
    this.before,
    this.after,
  });

  final String employee;
  final String? employeeName;
  final String weekday;

  /// e.g. "Branch Evening @ Nasr City" or "Off".
  final String? before;
  final String? after;

  String get displayName {
    final name = (employeeName ?? '').trim();
    return name.isEmpty ? employee : name;
  }

  factory RosterWeeklyStanding.fromJson(Map<String, dynamic> json) =>
      RosterWeeklyStanding(
        employee: (json['employee'] ?? '').toString(),
        employeeName: _nullIfBlank(json['employee_name']),
        weekday: (json['weekday'] ?? '').toString(),
        before: _nullIfBlank(json['before']),
        after: _nullIfBlank(json['after']),
      );
}

/// The preview (dry run) or the outcome of applying — the same shape.
class RosterWeeklyResult {
  const RosterWeeklyResult({
    this.success = false,
    this.dryRun = true,
    this.applied = false,
    this.employee,
    this.employeeName,
    this.action,
    this.weekday,
    this.start,
    this.through,
    this.rotaFrom,
    this.changeCount = 0,
    this.dates = const [],
    this.replaceManual = false,
    this.kept = const [],
    this.keptCount = 0,
    this.warnings = const [],
    this.standing = const [],
  });

  final bool success;
  final bool dryRun;
  final bool applied;
  final String? employee;
  final String? employeeName;
  final String? action;

  /// English weekday name; localise on the client.
  final String? weekday;
  final String? start;

  /// The last dated day written; null when no dated day changes.
  final String? through;

  /// From here on the weekly (standing) rota carries the change.
  final String? rotaFrom;
  final int changeCount;
  final List<String> dates;
  final bool replaceManual;
  final List<RosterWeeklyKeptDay> kept;
  final int keptCount;
  final List<RosterWeeklyWarning> warnings;
  final List<RosterWeeklyStanding> standing;

  /// [kept] grouped by person, in first-seen order, each day list by date.
  List<MapEntry<String, List<RosterWeeklyKeptDay>>> get keptByPerson {
    final groups = <String, List<RosterWeeklyKeptDay>>{};
    for (final day in kept) {
      groups.putIfAbsent(day.displayName, () => []).add(day);
    }
    for (final days in groups.values) {
      days.sort((a, b) => a.date.compareTo(b.date));
    }
    return groups.entries.toList();
  }

  factory RosterWeeklyResult.fromJson(Map<String, dynamic> json) {
    final kept = _maps(json['kept']).map(RosterWeeklyKeptDay.fromJson).toList();
    final dates = _strings(json['dates']);
    return RosterWeeklyResult(
      success: _isTrue(json['success']),
      // The endpoint previews by default, so a missing flag means a preview.
      dryRun: json['dry_run'] == null ? true : _isTrue(json['dry_run']),
      applied: _isTrue(json['applied']),
      employee: _nullIfBlank(json['employee']),
      employeeName: _nullIfBlank(json['employee_name']),
      action: _nullIfBlank(json['action']),
      weekday: _nullIfBlank(json['weekday']),
      start: _nullIfBlank(json['start']),
      through: _nullIfBlank(json['through']),
      rotaFrom: _nullIfBlank(json['rota_from']),
      changeCount: json['change_count'] == null
          ? dates.length
          : _toInt(json['change_count']),
      dates: dates,
      replaceManual: _isTrue(json['replace_manual']),
      kept: kept,
      keptCount: json['kept_count'] == null
          ? kept.length
          : _toInt(json['kept_count']),
      warnings: _maps(
        json['warnings'],
      ).map(RosterWeeklyWarning.fromJson).toList(),
      standing: _maps(
        json['standing'],
      ).map(RosterWeeklyStanding.fromJson).toList(),
    );
  }
}

Iterable<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e))
    : const <Map<String, dynamic>>[];

List<String> _strings(dynamic value) => value is List
    ? value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList()
    : const <String>[];

bool _isTrue(dynamic value) =>
    value == true || value == 1 || value == '1' || value == 'true';

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _nullIfBlank(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

String? _blankToNull(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : text;
}
