import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/employee_advances_repository.dart';
import '../models/employee_advance_models.dart';
import '../models/expense_models.dart';

class EmployeeAdvancesState {
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final bool initialized;

  /// `false` means the HRMS app is not installed on the site. That is a normal
  /// answer, NOT an error — the screen renders [notice] as an empty state.
  final bool hrmsAvailable;

  /// Server truth for "may this user request / approve". The client role gate
  /// hides the control early; these decide it.
  final bool canRequest;
  final bool canApprove;

  final String? currency;
  final String selectedMonth;
  final String? statusFilter;
  final List<ExpenseMonthOption> months;
  final List<ExpenseMonthOption> salaryMonths;
  final String? suggestedSalaryMonth;
  final List<AdvanceEmployeeOption> employees;
  final List<ExpensePaymentSource> paymentSources;
  final List<EmployeeAdvance> advances;
  final EmployeeAdvanceSummary summary;
  final String? notice;
  final bool salaryPaymentsVisible;
  final List<AdvanceSalaryPayment> salaryPayments;

  const EmployeeAdvancesState({
    required this.isLoading,
    required this.isSubmitting,
    required this.error,
    required this.initialized,
    required this.hrmsAvailable,
    required this.canRequest,
    required this.canApprove,
    required this.currency,
    required this.selectedMonth,
    required this.statusFilter,
    required this.months,
    this.salaryMonths = const [],
    this.suggestedSalaryMonth,
    required this.employees,
    required this.paymentSources,
    required this.advances,
    required this.summary,
    required this.notice,
    this.salaryPaymentsVisible = false,
    this.salaryPayments = const [],
  });

  factory EmployeeAdvancesState.initial() => const EmployeeAdvancesState(
        isLoading: false,
        isSubmitting: false,
        error: null,
        initialized: false,
        hrmsAvailable: true,
        canRequest: false,
        canApprove: false,
        currency: null,
        selectedMonth: '',
        statusFilter: null,
        months: [],
        employees: [],
        paymentSources: [],
        advances: [],
        summary: EmployeeAdvanceSummary.empty,
        notice: null,
      );

  bool get canSubmitRequest =>
      hrmsAvailable && canRequest && paymentSources.isNotEmpty && employees.isNotEmpty;

  EmployeeAdvancesState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool? clearError,
    bool? initialized,
    bool? hrmsAvailable,
    bool? canRequest,
    bool? canApprove,
    String? currency,
    String? selectedMonth,
    String? statusFilter,
    bool? clearStatusFilter,
    List<ExpenseMonthOption>? months,
    List<ExpenseMonthOption>? salaryMonths,
    String? suggestedSalaryMonth,
    List<AdvanceEmployeeOption>? employees,
    List<ExpensePaymentSource>? paymentSources,
    List<EmployeeAdvance>? advances,
    EmployeeAdvanceSummary? summary,
    String? notice,
    bool? clearNotice,
    bool? salaryPaymentsVisible,
    List<AdvanceSalaryPayment>? salaryPayments,
  }) {
    return EmployeeAdvancesState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError == true ? null : error ?? this.error,
      initialized: initialized ?? this.initialized,
      hrmsAvailable: hrmsAvailable ?? this.hrmsAvailable,
      canRequest: canRequest ?? this.canRequest,
      canApprove: canApprove ?? this.canApprove,
      currency: currency ?? this.currency,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      statusFilter:
          clearStatusFilter == true ? null : statusFilter ?? this.statusFilter,
      months: months ?? this.months,
      salaryMonths: salaryMonths ?? this.salaryMonths,
      suggestedSalaryMonth: suggestedSalaryMonth ?? this.suggestedSalaryMonth,
      employees: employees ?? this.employees,
      paymentSources: paymentSources ?? this.paymentSources,
      advances: advances ?? this.advances,
      summary: summary ?? this.summary,
      notice: clearNotice == true ? null : notice ?? this.notice,
      salaryPaymentsVisible:
          salaryPaymentsVisible ?? this.salaryPaymentsVisible,
      salaryPayments: salaryPayments ?? this.salaryPayments,
    );
  }
}

final employeeAdvancesNotifierProvider = StateNotifierProvider.autoDispose<
    EmployeeAdvancesNotifier, EmployeeAdvancesState>((ref) {
  final repo = ref.watch(employeeAdvancesRepositoryProvider);
  return EmployeeAdvancesNotifier(repo);
});

class EmployeeAdvancesNotifier extends StateNotifier<EmployeeAdvancesState> {
  final EmployeeAdvancesRepository _repository;

  EmployeeAdvancesNotifier(this._repository)
      : super(EmployeeAdvancesState.initial());

  Future<void> load({String? month, String? status, bool clearStatus = false}) async {
    final monthCandidate = month ?? state.selectedMonth;
    final statusCandidate = clearStatus ? null : (status ?? state.statusFilter);

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final bootstrap = await _repository.fetchAdvances(
        month: monthCandidate.isNotEmpty ? monthCandidate : null,
        status: statusCandidate,
      );
      final requested = bootstrap.requestedMonth.isNotEmpty
          ? bootstrap.requestedMonth
          : (monthCandidate.isNotEmpty
              ? monthCandidate
              : bootstrap.currentMonth);
      // A short/empty months list on a later call must not wipe the selector.
      final months =
          bootstrap.months.isNotEmpty ? bootstrap.months : state.months;

      state = state.copyWith(
        isLoading: false,
        initialized: true,
        hrmsAvailable: bootstrap.hrmsAvailable,
        canRequest: bootstrap.canRequest,
        canApprove: bootstrap.canApprove,
        currency: bootstrap.currency,
        selectedMonth: requested,
        statusFilter: bootstrap.statusFilter,
        clearStatusFilter: bootstrap.statusFilter == null,
        months: months,
        salaryMonths: bootstrap.salaryMonths,
        suggestedSalaryMonth: bootstrap.suggestedSalaryMonth,
        employees: bootstrap.employees,
        paymentSources: bootstrap.paymentSources,
        advances: bootstrap.advances,
        summary: bootstrap.summary,
        notice: bootstrap.notice,
        clearNotice: bootstrap.notice == null,
        salaryPaymentsVisible: bootstrap.salaryPaymentsVisible,
        salaryPayments: bootstrap.salaryPayments,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await load(month: state.selectedMonth, status: state.statusFilter);
  }

  Future<void> setMonth(String month) async {
    await load(month: month, status: state.statusFilter);
  }

  Future<void> setStatusFilter(String? status) async {
    await load(
      month: state.selectedMonth,
      status: status,
      clearStatus: status == null,
    );
  }

  Future<EmployeeAdvance?> createRequest({
    required String employee,
    required double amount,
    required String purpose,
    required String payingAccount,
    String? posProfile,
    String? postingDate,
    String? salaryMonth,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final advance = await _repository.createRequest(
        employee: employee,
        amount: amount,
        purpose: purpose,
        payingAccount: payingAccount,
        posProfile: posProfile,
        postingDate: postingDate,
        salaryMonth: salaryMonth,
      );
      // Re-read from the server rather than splicing the row in: the summary
      // and the HRMS-derived status are both computed server-side.
      await load(month: state.selectedMonth, status: state.statusFilter);
      state = state.copyWith(isSubmitting: false);
      return advance;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return null;
    }
  }

  /// Approving submits the advance AND posts the Payment Entry — cash leaves
  /// the branch account on this call. Returns the Payment Entry name (or an
  /// empty string when the backend omitted it) so the UI can confirm the move;
  /// `null` means the call failed and [EmployeeAdvancesState.error] is set.
  Future<String?> approve(String name) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await _repository.approve(name);
      await load(month: state.selectedMonth, status: state.statusFilter);
      state = state.copyWith(isSubmitting: false);
      return result.paymentEntry ?? result.advance.paymentEntry ?? '';
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return null;
    }
  }

  Future<bool> reject(String name, String reason) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repository.reject(name, reason);
      await load(month: state.selectedMonth, status: state.statusFilter);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
