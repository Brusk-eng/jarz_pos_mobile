import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../models/roster_models.dart';
import '../models/roster_plan_models.dart';
import '../models/roster_weekly_models.dart';

final rosterRepositoryProvider = Provider<RosterRepository>((ref) {
  return RosterRepository(ref.watch(dioProvider));
});

/// HTTP repository for shift distribution (`jarz_pos.api.roster.*`).
///
/// All endpoints are POST and return Frappe's `{ "message": ... }` envelope,
/// unwrapped by [_unwrap] exactly like the visits, leads and journey
/// repositories.
class RosterRepository {
  RosterRepository(this._dio);

  final Dio _dio;

  dynamic _unwrap(Response response) {
    final data = response.data;
    if (data is Map && data.containsKey('message')) return data['message'];
    return data;
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      Map<String, dynamic>.from(value as Map);

  // ── Reads ────────────────────────────────────────────────────────────

  /// Shift catalogue, branches and the caller's scope — one call so the
  /// calendar does not open on three separate spinners.
  Future<RosterBootstrap> getBootstrap() async {
    final response = await _dio.post(ApiEndpoints.rosterBootstrap, data: {});
    return RosterBootstrap.fromJson(_asMap(_unwrap(response)));
  }

  /// The month grid: one row per employee, one cell per day.
  ///
  /// [month] is `YYYY-MM`; omitting it asks the server for the current month,
  /// so the client never has to decide what "this month" means in the site's
  /// timezone.
  Future<RosterMonth> getMonth({String? month, String? shiftLocation}) async {
    final response = await _dio.post(
      ApiEndpoints.rosterMonth,
      data: {
        if (month != null) 'month': month,
        if (shiftLocation != null && shiftLocation.isNotEmpty)
          'shift_location': shiftLocation,
      },
    );
    return RosterMonth.fromJson(_asMap(_unwrap(response)));
  }

  /// Hours and overtime for the month, as payroll reads it.
  Future<RosterHours> getMonthHours({
    String? month,
    String? shiftLocation,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.rosterMonthHours,
      data: {
        if (month != null) 'month': month,
        if (shiftLocation != null && shiftLocation.isNotEmpty)
          'shift_location': shiftLocation,
      },
    );
    return RosterHours.fromJson(_asMap(_unwrap(response)));
  }

  // ── Writes ───────────────────────────────────────────────────────────

  /// Put one employee on one shift for one day.
  ///
  /// Passing [shiftLocation] moves them to another branch for the day, which
  /// also moves where their phone has to be to clock in.
  ///
  /// [grantPosAccess] also gives them that branch's POS for the day. The grant
  /// is best-effort server-side, so its outcome comes back rather than
  /// throwing; null means the server did not report one (older backend, or
  /// nothing was asked).
  Future<PosAccessOutcome?> assignShift({
    required String employee,
    required String date,
    required String shiftType,
    String? shiftLocation,
    bool grantPosAccess = false,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.rosterAssignShift,
      data: {
        'employee': employee,
        'date': date,
        'shift_type': shiftType,
        if (shiftLocation != null && shiftLocation.isNotEmpty)
          'shift_location': shiftLocation,
        // Only sent when asked, so the request is exactly what an older
        // backend already accepts.
        if (grantPosAccess) 'grant_pos_access': 1,
      },
    );
    return _posAccess(response);
  }

  PosAccessOutcome? _posAccess(Response response) {
    final body = _unwrap(response);
    if (body is! Map) return null;
    return PosAccessOutcome.tryParse(body['pos_access']);
  }

  /// Mark somebody off and, in the same request, name who covers the day.
  ///
  /// The pair is one call rather than two because a branch that loses one of
  /// its overlapping shifts is not covered by shortening the rota — sending
  /// them separately would leave a window where the branch is rostered
  /// half-open.
  ///
  /// [grantPosAccess] gives the COVERING person ([coveredBy]) POS access at the
  /// covered branch for the day; ignored without a cover.
  Future<PosAccessOutcome?> setDayOff({
    required String employee,
    required String date,
    required String offType,
    String? coveredBy,
    String? coverShiftType,
    String? notes,
    bool grantPosAccess = false,
  }) async {
    final hasCover = coveredBy != null && coveredBy.isNotEmpty;
    final response = await _dio.post(
      ApiEndpoints.rosterSetDayOff,
      data: {
        'employee': employee,
        'date': date,
        'off_type': offType,
        if (hasCover) 'covered_by': coveredBy,
        if (coverShiftType != null && coverShiftType.isNotEmpty)
          'cover_shift_type': coverShiftType,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (grantPosAccess && hasCover) 'grant_pos_access': 1,
      },
    );
    return _posAccess(response);
  }

  /// Undo a day off, restoring both the person and whoever covered them.
  Future<void> clearDayOff({
    required String employee,
    required String date,
  }) async {
    await _dio.post(
      ApiEndpoints.rosterClearDayOff,
      data: {'employee': employee, 'date': date},
    );
  }

  /// Apply many single-day changes in one request.
  ///
  /// [changes] is a list of `{employee, date, action, ...}` rows, one per
  /// existing single-cell write (`action: 'assign' | 'day_off' |
  /// 'clear_day_off'`) — see `jarz_pos.api.roster.bulk_assign`. This is the
  /// whole win of the endpoint: building or clearing a stretch of days becomes
  /// ONE round trip instead of one per day.
  ///
  /// Encoded to a JSON string rather than sent as a raw list: Frappe binds a
  /// list argument delivered as form data into a JSON string anyway, and
  /// `bulk_assign`'s own `payload` parameter explicitly `json.loads`s a string
  /// first — the same reason the visits/leads/materials repositories encode
  /// their list arguments before sending.
  Future<RosterBulkResult> bulkAssign(
    List<Map<String, dynamic>> changes,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.rosterBulkAssign,
      data: {'payload': jsonEncode(changes)},
    );
    return RosterBulkResult.fromJson(_asMap(_unwrap(response)));
  }

  // ── Rota plan wizard ─────────────────────────────────────────────────

  /// Everyone the caller can plan for, pre-filled with their current week.
  ///
  /// A GET, as the contract declares it; [shiftLocation] narrows to one branch.
  Future<RosterPlanDefaults> getPlanDefaults({String? shiftLocation}) async {
    final response = await _dio.get(
      ApiEndpoints.rosterPlanDefaults,
      queryParameters: {
        if (shiftLocation != null && shiftLocation.isNotEmpty)
          'shift_location': shiftLocation,
      },
    );
    return RosterPlanDefaults.fromJson(_asMap(_unwrap(response)));
  }

  /// Preview ([dryRun] true) or write a rota plan.
  ///
  /// [plan] is the contract's payload (`start`, `end`, `replace_manual`,
  /// `grant_pos_access`, `rows`). JSON-encoded for the same reason as
  /// [bulkAssign]: nested lists do not survive Frappe's form binding, and
  /// `apply_plan` `json.loads` a string payload.
  Future<RosterPlanResult> applyPlan(
    Map<String, dynamic> plan, {
    required bool dryRun,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.rosterApplyPlan,
      data: {'payload': jsonEncode(plan), 'dry_run': dryRun ? 1 : 0},
    );
    return RosterPlanResult.fromJson(_asMap(_unwrap(response)));
  }
  // ── Repeat every <weekday> ───────────────────────────────────────────

  /// Preview ([dryRun] true) or apply one person's weekly change: [change]'s
  /// day, and the same weekday every week after it, becomes their usual week.
  ///
  /// The same payload goes to both calls, so what is applied is exactly what
  /// was previewed. JSON-encoded like [applyPlan]; `dry_run` is sent
  /// explicitly both ways, since the endpoint previews when it is missing.
  Future<RosterWeeklyResult> applyWeeklyChange(
    RosterWeeklyChange change, {
    required bool dryRun,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.rosterApplyWeeklyChange,
      data: {
        'payload': jsonEncode(change.toPayload()),
        'dry_run': dryRun ? 1 : 0,
      },
    );
    return RosterWeeklyResult.fromJson(_asMap(_unwrap(response)));
  }
}
