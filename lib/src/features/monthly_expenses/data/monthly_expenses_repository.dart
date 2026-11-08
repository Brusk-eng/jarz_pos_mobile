import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/frappe_error_message.dart';
import '../models/monthly_expense_models.dart';

final monthlyExpensesRepositoryProvider =
    Provider<MonthlyExpensesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MonthlyExpensesRepository(dio);
});

/// The server refused a payment because it would push the period's paid total
/// past what is due.
///
/// Modelled as its own exception rather than a plain failure because it is not
/// a failure: it is a question. The backend states by how much the payment
/// overshoots, and the same call succeeds with `allow_overpay=1`, so the UI has
/// to be able to tell this apart from "the payment did not work" and offer the
/// retry instead of a red snackbar.
class MonthlyExpenseOverpayException implements Exception {
  /// The server's own sentence, which carries the amount of the overshoot.
  final String message;

  const MonthlyExpenseOverpayException(this.message);

  @override
  String toString() => message;
}

/// Recognises the overpay refusal in whatever the server said.
///
/// The contract froze the *behaviour* ("reject ... unless `allow_overpay=1` is
/// passed, and say by how much") but not the wording, so this matches on the
/// stable parts: the flag name, which appears in the hint the backend gives,
/// and the word "overpay" in either language's stem. Anything else stays a
/// normal error — offering "pay anyway" on an unrelated failure would be worse
/// than not offering it at all.
bool looksLikeOverpayRefusal(String message) {
  final text = message.toLowerCase();
  return text.contains('allow_overpay') ||
      text.contains('overpay') ||
      text.contains('over-pay') ||
      text.contains('دفع زائد') ||
      text.contains('أكثر من المستحق');
}

class MonthlyExpensesRepository {
  final Dio _dio;
  MonthlyExpensesRepository(this._dio);

  /// The company's bill for one `YYYY-MM` period. `month` null means the
  /// server's current month.
  Future<MonthlyExpensesPayload> fetchMonth({String? month, String? company}) async {
    final response = await _dio.post(
      ApiEndpoints.getMonthlyExpenses,
      data: {
        if (month != null && month.isNotEmpty) 'month': month,
        if (company != null && company.isNotEmpty) 'company': company,
      },
    );
    return MonthlyExpensesPayload.fromJson(_unwrap(response));
  }

  /// Pay a period of a registry item. Returns the whole recomputed month rather
  /// than the single row the server echoes: paying one item moves the summary,
  /// the category total and — when the item shares an expense account — the
  /// `inferred` flag on its neighbours, so patching one row in place would leave
  /// four numbers on screen disagreeing with the fifth.
  Future<void> payRecurringExpense({
    required String recurringExpense,
    required String month,
    required double amount,
    required String payingAccount,
    String? paymentDate,
    String? remarks,
    bool allowOverpay = false,
  }) async {
    await _post(ApiEndpoints.payRecurringExpense, {
      'recurring_expense': recurringExpense,
      'month': month,
      'amount': amount,
      'paying_account': payingAccount,
      if (paymentDate != null && paymentDate.isNotEmpty)
        'payment_date': paymentDate,
      if (remarks != null && remarks.trim().isNotEmpty)
        'remarks': remarks.trim(),
      'allow_overpay': allowOverpay ? 1 : 0,
    });
  }

  /// Pay a salary, and optionally clear what the employee owes in the same
  /// action.
  ///
  /// [amount] keeps its meaning throughout: the CASH handed over. The
  /// settlements are ADDITIONAL discharge — the server posts them as a second
  /// journal entry against each advance's own account and each invoice's
  /// receivable, inside the same transaction as the cash half. That is why they
  /// travel here and not through a separate call: a cash payment that posts
  /// while the settlement fails leaves the advance open and the employee paid
  /// twice.
  ///
  /// [amount] may legitimately be 0 when only settlements are asked for — an
  /// employee whose whole salary goes against an advance receives no cash.
  Future<void> paySalary({
    required String employee,
    required String month,
    required double amount,
    required String payingAccount,
    String? paymentDate,
    String? remarks,
    bool allowOverpay = false,
    List<AdvanceSettlement> settleAdvances = const [],
    List<OrderSettlement> settleOrders = const [],
  }) async {
    await _post(ApiEndpoints.paySalary, {
      'employee': employee,
      'month': month,
      'amount': amount,
      'paying_account': payingAccount,
      if (paymentDate != null && paymentDate.isNotEmpty)
        'payment_date': paymentDate,
      if (remarks != null && remarks.trim().isNotEmpty)
        'remarks': remarks.trim(),
      'allow_overpay': allowOverpay ? 1 : 0,
      // Omitted entirely when empty rather than sent as `[]`: every existing
      // caller then produces byte-for-byte the request it produced before, so
      // an ordinary salary payment cannot regress on this change.
      if (settleAdvances.isNotEmpty)
        'settle_advances': settleAdvances.map((s) => s.toJson()).toList(),
      if (settleOrders.isNotEmpty)
        'settle_orders': settleOrders.map((s) => s.toJson()).toList(),
    });
  }

  /// Record a penalty against an employee for [month].
  ///
  /// Only ONE of `quantity` / `amount` is sent, whichever the manager actually
  /// typed. The server owns the conversion and snapshots the day rate it used,
  /// so sending both would put two sources of truth on one number and let a
  /// stale client price a penalty.
  Future<void> addEmployeePenalty({
    required PenaltyDraft draft,
    required String month,
    bool allowOverpay = false,
  }) async {
    await _post(ApiEndpoints.addEmployeePenalty, {
      'employee': draft.employee,
      'month': month,
      'unit': draft.unit,
      if (draft.quantity != null) 'quantity': draft.quantity,
      if (draft.amount != null) 'amount': draft.amount,
      'reason': draft.reason,
      if (draft.penaltyDate != null && draft.penaltyDate!.isNotEmpty)
        'penalty_date': draft.penaltyDate,
      'allow_overpay': allowOverpay ? 1 : 0,
    });
  }

  /// Cancel a penalty (docstatus 2). The reason is mandatory server-side, and a
  /// penalty already settled by a payment is refused.
  Future<void> cancelEmployeePenalty({
    required String name,
    required String reason,
  }) async {
    await _post(ApiEndpoints.cancelEmployeePenalty, {
      'name': name,
      'reason': reason,
    });
  }

  /// Create (no `name`) or update (with `name`) a registry entry.
  Future<void> saveRecurringExpense(RecurringExpenseDraft draft) async {
    await _post(ApiEndpoints.saveRecurringExpense, {'payload': draft.toJson()});
  }

  /// Drop one dated step from a recurring expense's amount history.
  /// `effectiveFrom` is `YYYY-MM-DD`. The server refuses the first row.
  Future<void> removeRecurringAmountChange({
    required String name,
    required String effectiveFrom,
  }) async {
    await _post(ApiEndpoints.removeRecurringAmountChange, {
      'name': name,
      'effective_from': effectiveFrom,
    });
  }

  /// `Active` / `Paused` / `Ended`.
  Future<void> setRecurringExpenseStatus({
    required String name,
    required String status,
  }) async {
    await _post(ApiEndpoints.setRecurringExpenseStatus, {
      'name': name,
      'status': status,
    });
  }

  /// Reverse a payment. The reason is mandatory server-side — the endpoint
  /// delegates to `expenses.cancel_expense`, which cancels the journal entry
  /// the payment posted.
  Future<void> cancelExpensePayment({
    required String name,
    required String reason,
  }) async {
    await _post(ApiEndpoints.cancelExpensePayment, {
      'name': name,
      'reason': reason,
    });
  }

  /// Every mutation goes through here so the overpay question is recognised in
  /// exactly one place, and every other failure is turned into the same
  /// readable exception the rest of the app raises.
  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post(endpoint, data: body);
      return _unwrap(response);
    } catch (error) {
      final message = extractFrappeErrorMessage(error);
      if (looksLikeOverpayRefusal(message)) {
        throw MonthlyExpenseOverpayException(message);
      }
      throw mapFrappeError(error);
    }
  }

  Map<String, dynamic> _unwrap(Response<dynamic> response) {
    final data = response.data;
    final payload = data is Map ? (data['message'] ?? data) : data;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return <String, dynamic>{};
  }
}
