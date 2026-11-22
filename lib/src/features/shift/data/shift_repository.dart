import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/frappe_error_message.dart';
import '../models/shift_models.dart';
import '../models/shift_sheet_models.dart';

class ShiftRepository {
  ShiftRepository(this._dio);

  final Dio _dio;

  Exception _mapApiException(
    Object error, {
    String fallback = 'Request failed',
  }) {
    return mapFrappeError(error, fallback: fallback);
  }

  Future<ShiftEntry?> getActiveShift({String? posProfile}) async {
    final response = await _dio.post(
      ApiEndpoints.getActiveShift,
      data: {
        if (posProfile != null && posProfile.isNotEmpty) 'pos_profile': posProfile,
      },
    );
    final message = response.data is Map ? response.data['message'] : null;
    if (message is Map) {
      return ShiftEntry.fromJson(Map<String, dynamic>.from(message));
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getShiftPaymentMethods(String posProfile) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.getShiftPaymentMethods,
        data: {'pos_profile': posProfile},
      );

      final message = response.data is Map ? response.data['message'] : null;
      if (message is List) {
        return message.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      throw _mapApiException(e);
    }
  }

  Future<String> startShift({
    required String posProfile,
    required List<Map<String, dynamic>> openingBalances,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.startShift,
        data: {
          'pos_profile': posProfile,
          'opening_balances': openingBalances,
        },
      );

      final message = response.data is Map ? response.data['message'] : null;
      if (message is Map && message['opening_entry'] != null) {
        return message['opening_entry'].toString();
      }
      throw Exception('Unexpected start shift response');
    } catch (e) {
      throw _mapApiException(e);
    }
  }

  Future<ShiftSummary> getShiftSummary(String openingEntry) async {
    final response = await _dio.post(
      ApiEndpoints.getShiftSummary,
      data: {'pos_opening_entry': openingEntry},
    );

    final message = response.data is Map ? response.data['message'] : null;
    if (message is Map) {
      return ShiftSummary.fromJson(Map<String, dynamic>.from(message));
    }
    throw Exception('Unexpected shift summary response');
  }

  /// Past shifts, newest first.
  ///
  /// `amountsHidden` mirrors the server's decision: a non-manager gets their
  /// own shifts with dates, profile and status but no money, because
  /// [getShiftSummary] withholds those figures from the closing cashier on
  /// purpose and a history that handed them back would undo that.
  Future<({List<Map<String, dynamic>> shifts, int total, bool amountsHidden})>
      listShifts({
    int limit = 30,
    int page = 0,
    String? posProfile,
    String? status,
    String? fromDate,
    String? toDate,
    bool mineOnly = false,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.listShifts,
        data: {
          'limit': limit,
          'page': page,
          if (posProfile != null && posProfile.isNotEmpty)
            'pos_profile': posProfile,
          if (status != null && status.isNotEmpty) 'status': status,
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
          'mine_only': mineOnly ? 1 : 0,
        },
      );
      final message = response.data is Map ? response.data['message'] : null;
      final map = message is Map
          ? Map<String, dynamic>.from(message)
          : <String, dynamic>{};
      final rows = (map['shifts'] as List?) ?? const [];
      return (
        shifts: rows
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        total: (map['total'] as num?)?.toInt() ?? rows.length,
        amountsHidden: ((map['amounts_hidden'] as num?)?.toInt() ?? 1) == 1,
      );
    } catch (e) {
      throw _mapApiException(e, fallback: 'Failed to load shift history');
    }
  }

  /// The sales sheet for one shift. Staff get per-order rows with
  /// `totals: null`; managers get the totals too.
  Future<ShiftSheet> getShiftSheet(String openingEntry) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.getShiftSheet,
        data: {'opening_entry': openingEntry},
      );
      final message = response.data is Map ? response.data['message'] : null;
      if (message is Map) {
        return ShiftSheet.fromJson(Map<String, dynamic>.from(message));
      }
      throw Exception('Unexpected shift sheet response');
    } catch (e) {
      throw _mapApiException(e, fallback: 'Failed to load shift sheet');
    }
  }

  /// Close the shift.
  ///
  /// [acknowledgedCourierTransactions] is the set of Courier Transaction names
  /// the closer confirmed are still out with a courier. It is always sent, even
  /// when empty — an empty list is the positive statement "nothing is out",
  /// while omitting the field asks the server for the old hard refusal.
  Future<ShiftSummary> endShift({
    required String openingEntry,
    required List<Map<String, dynamic>> closingBalances,
    List<String> acknowledgedCourierTransactions = const [],
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.endShift,
        data: {
          'pos_opening_entry': openingEntry,
          'closing_balances': closingBalances,
          'acknowledged_courier_transactions': acknowledgedCourierTransactions,
        },
      );

      final message = response.data is Map ? response.data['message'] : null;
      if (message is Map) {
        return ShiftSummary.fromJson(Map<String, dynamic>.from(message));
      }
      throw Exception('Unexpected end shift response');
    } catch (e) {
      throw _mapApiException(e, fallback: 'Failed to close shift');
    }
  }
}

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ShiftRepository(dio);
});
