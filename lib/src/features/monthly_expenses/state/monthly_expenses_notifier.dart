import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/monthly_expenses_repository.dart';
import '../models/monthly_expense_models.dart';

/// What a mutation did.
///
/// `overpayMessage` is deliberately NOT an error: the server refused the amount
/// as an overpayment and told us by how much, and the very same call succeeds
/// with `allowOverpay: true`. It travels back to the caller as a question so
/// the pay sheet can ask, instead of landing in `state.error` and being
/// snackbarred as a failure.
class MonthlyExpenseActionResult {
  final bool success;
  final String? error;
  final String? overpayMessage;

  const MonthlyExpenseActionResult.ok()
      : success = true,
        error = null,
        overpayMessage = null;

  const MonthlyExpenseActionResult.failed(String message)
      : success = false,
        error = message,
        overpayMessage = null;

  const MonthlyExpenseActionResult.overpay(String message)
      : success = false,
        error = null,
        overpayMessage = message;

  bool get needsOverpayConfirmation => overpayMessage != null;
}

class MonthlyExpensesState {
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final bool initialized;

  /// `YYYY-MM`. Empty until the first load answers with the server's month.
  final String selectedMonth;

  final MonthlyExpensesPayload payload;

  const MonthlyExpensesState({
    required this.isLoading,
    required this.isSubmitting,
    required this.error,
    required this.initialized,
    required this.selectedMonth,
    required this.payload,
  });

  factory MonthlyExpensesState.initial() => const MonthlyExpensesState(
        isLoading: false,
        isSubmitting: false,
        error: null,
        initialized: false,
        selectedMonth: '',
        payload: MonthlyExpensesPayload(),
      );

  /// Where the selected month sits in `available_months`, or -1 when the list
  /// has not arrived yet. The prev/next arrows walk this list rather than doing
  /// date arithmetic: the server decides which months exist, and stepping off
  /// the end of its window would fetch a month it will not answer for.
  int get monthIndex {
    final months = payload.availableMonths;
    for (var i = 0; i < months.length; i++) {
      if (months[i].id == selectedMonth) return i;
    }
    return -1;
  }

  /// `available_months` is ordered newest LAST, so the previous month is the
  /// entry before the current one.
  bool get hasPreviousMonth => monthIndex > 0;

  bool get hasNextMonth {
    final index = monthIndex;
    return index >= 0 && index < payload.availableMonths.length - 1;
  }

  String? get previousMonth =>
      hasPreviousMonth ? payload.availableMonths[monthIndex - 1].id : null;

  String? get nextMonth =>
      hasNextMonth ? payload.availableMonths[monthIndex + 1].id : null;

  MonthlyExpensesState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool? clearError,
    bool? initialized,
    String? selectedMonth,
    MonthlyExpensesPayload? payload,
  }) {
    return MonthlyExpensesState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError == true ? null : error ?? this.error,
      initialized: initialized ?? this.initialized,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      payload: payload ?? this.payload,
    );
  }
}

final monthlyExpensesNotifierProvider =
    StateNotifierProvider<MonthlyExpensesNotifier, MonthlyExpensesState>((ref) {
  final repository = ref.watch(monthlyExpensesRepositoryProvider);
  return MonthlyExpensesNotifier(repository);
});

class MonthlyExpensesNotifier extends StateNotifier<MonthlyExpensesState> {
  final MonthlyExpensesRepository _repository;

  MonthlyExpensesNotifier(this._repository)
      : super(MonthlyExpensesState.initial());

  Future<void> load({String? month}) async {
    final candidate = month ?? state.selectedMonth;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final payload = await _repository.fetchMonth(
        month: candidate.isNotEmpty ? candidate : null,
      );
      // The server's echoed month wins over the requested one: it is the month
      // the numbers below actually describe, and a header disagreeing with its
      // own figures is how a manager pays the wrong period.
      final resolved = payload.month.isNotEmpty ? payload.month : candidate;
      state = state.copyWith(
        isLoading: false,
        initialized: true,
        selectedMonth: resolved,
        payload: payload,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => load(month: state.selectedMonth);

  Future<void> setMonth(String month) => load(month: month);

  Future<void> goToPreviousMonth() async {
    final target = state.previousMonth;
    if (target == null) return;
    await load(month: target);
  }

  Future<void> goToNextMonth() async {
    final target = state.nextMonth;
    if (target == null) return;
    await load(month: target);
  }

  Future<MonthlyExpenseActionResult> payRecurringExpense({
    required String recurringExpense,
    required double amount,
    required String payingAccount,
    String? paymentDate,
    String? remarks,
    bool allowOverpay = false,
  }) {
    return _mutate(() => _repository.payRecurringExpense(
          recurringExpense: recurringExpense,
          month: state.selectedMonth,
          amount: amount,
          payingAccount: payingAccount,
          paymentDate: paymentDate,
          remarks: remarks,
          allowOverpay: allowOverpay,
        ));
  }

  Future<MonthlyExpenseActionResult> paySalary({
    required String employee,
    required double amount,
    required String payingAccount,
    String? paymentDate,
    String? remarks,
    bool allowOverpay = false,
    List<AdvanceSettlement> settleAdvances = const [],
    List<OrderSettlement> settleOrders = const [],
  }) {
    return _mutate(() => _repository.paySalary(
          employee: employee,
          month: state.selectedMonth,
          amount: amount,
          payingAccount: payingAccount,
          paymentDate: paymentDate,
          remarks: remarks,
          allowOverpay: allowOverpay,
          settleAdvances: settleAdvances,
          settleOrders: settleOrders,
        ));
  }

  /// Record a penalty for the selected month.
  ///
  /// Goes through [_mutate] like every other write, so the month is refetched
  /// before success is reported: a penalty moves `due_amount`, the payroll
  /// total, the Salaries category subtotal and the row's net payable all at
  /// once, and only the server can recompute that set.
  Future<MonthlyExpenseActionResult> addPenalty({
    required PenaltyDraft draft,
    bool allowOverpay = false,
  }) {
    return _mutate(() => _repository.addEmployeePenalty(
          draft: draft,
          month: state.selectedMonth,
          allowOverpay: allowOverpay,
        ));
  }

  Future<MonthlyExpenseActionResult> cancelPenalty({
    required String name,
    required String reason,
  }) {
    return _mutate(
      () => _repository.cancelEmployeePenalty(name: name, reason: reason),
    );
  }

  Future<MonthlyExpenseActionResult> saveRecurringExpense(
    RecurringExpenseDraft draft,
  ) {
    return _mutate(() => _repository.saveRecurringExpense(draft));
  }

  Future<MonthlyExpenseActionResult> removeAmountChange({
    required String name,
    required String effectiveFrom,
  }) {
    return _mutate(
      () => _repository.removeRecurringAmountChange(
        name: name,
        effectiveFrom: effectiveFrom,
      ),
    );
  }

  Future<MonthlyExpenseActionResult> setStatus({
    required String name,
    required String status,
  }) {
    return _mutate(
      () => _repository.setRecurringExpenseStatus(name: name, status: status),
    );
  }

  Future<MonthlyExpenseActionResult> cancelPayment({
    required String name,
    required String reason,
  }) {
    return _mutate(
      () => _repository.cancelExpensePayment(name: name, reason: reason),
    );
  }

  /// Every mutation refetches the month before reporting success.
  ///
  /// Not an optimisation target: `remaining`, the category totals, the status
  /// chips and — for items sharing an expense account — the `inferred` and
  /// `shared_account` flags on OTHER rows all move when one payment posts. Only
  /// the server can recompute that attribution, so the screen asks it rather
  /// than patching a row and leaving the rest of the page stale.
  Future<MonthlyExpenseActionResult> _mutate(
    Future<void> Function() call,
  ) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await call();
      await load(month: state.selectedMonth);
      state = state.copyWith(isSubmitting: false);
      return const MonthlyExpenseActionResult.ok();
    } on MonthlyExpenseOverpayException catch (e) {
      // Deliberately not written into `state.error`: this is a question the pay
      // sheet is about to ask, not a failure to announce.
      state = state.copyWith(isSubmitting: false);
      return MonthlyExpenseActionResult.overpay(e.message);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return MonthlyExpenseActionResult.failed(e.toString());
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}
