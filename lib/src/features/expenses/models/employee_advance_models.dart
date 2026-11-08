import 'expense_models.dart';

/// Employee Advance models for the `jarz_pos.api.employee_advances.*` contract.
///
/// Deliberately hand-written immutable classes with manual `fromJson`, matching
/// the neighbouring `expense_models.dart` — this slice does not use Freezed, so
/// nothing here needs `build_runner`.
///
/// `ExpensePaymentSource` is reused verbatim for `payment_sources`: the
/// bootstrap returns the exact same shape the expense bootstrap does, and a
/// second identical class would only be one more thing to keep in sync.

/// The HRMS-derived status string an advance carries.
///
/// `Draft` is the one that matters operationally: an advance sits at `Draft`
/// until a JARZ Manager approves it. Approval submits the HRMS document AND
/// posts the Payment Entry, so the status jumps straight past submitted-unpaid
/// to `Paid` in the same call.
class EmployeeAdvanceStatus {
  static const draft = 'Draft';
  static const paid = 'Paid';
  static const partiallyPaid = 'Partially Paid';
  static const unpaid = 'Unpaid';
  static const claimed = 'Claimed';
  static const returned = 'Returned';
  static const partlyClaimedAndReturned = 'Partly Claimed and Returned';
  static const cancelled = 'Cancelled';

  const EmployeeAdvanceStatus._();
}

double _parseAmount(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

String? _optionalString(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  return raw.isEmpty ? null : raw;
}

/// First day of a `YYYY-MM` salary-month key, for locale-aware formatting
/// (`formatDate(..., pattern: 'MMMM yyyy')`). Null for anything malformed.
DateTime? salaryMonthDate(String? monthKey) {
  final key = monthKey?.trim() ?? '';
  if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(key)) return null;
  return DateTime.tryParse('$key-01');
}

/// One selectable employee in the request sheet.
class AdvanceEmployeeOption {
  final String employee;
  final String employeeName;
  final String? branch;
  final String? department;
  final String? designation;
  final String? user;

  const AdvanceEmployeeOption({
    required this.employee,
    required this.employeeName,
    this.branch,
    this.department,
    this.designation,
    this.user,
  });

  /// Everything the searchable picker matches a query against. Kept on the
  /// model so the widget cannot quietly narrow it.
  String get searchHaystack => [
        employee,
        employeeName,
        branch ?? '',
        department ?? '',
        designation ?? '',
        user ?? '',
      ].join(' ').toLowerCase();

  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return searchHaystack.contains(needle);
  }

  /// Secondary line under the employee name in the picker.
  String get subtitle => [
        if (branch != null && branch!.isNotEmpty) branch!,
        if (designation != null && designation!.isNotEmpty) designation!,
        if (department != null && department!.isNotEmpty) department!,
      ].join(' • ');

  factory AdvanceEmployeeOption.fromJson(Map<String, dynamic> json) {
    final id = (json['employee'] ?? '').toString();
    final name = (json['employee_name'] ?? '').toString();
    return AdvanceEmployeeOption(
      employee: id,
      employeeName: name.isNotEmpty ? name : id,
      branch: _optionalString(json['branch']),
      department: _optionalString(json['department']),
      designation: _optionalString(json['designation']),
      user: _optionalString(json['user']),
    );
  }

  Map<String, dynamic> toJson() => {
        'employee': employee,
        'employee_name': employeeName,
        'branch': branch,
        'department': department,
        'designation': designation,
        'user': user,
      };
}

class EmployeeAdvance {
  final String name;
  final String employee;
  final String employeeName;
  final String? branch;
  final String? posProfile;
  final DateTime? postingDate;

  /// `YYYY-MM` of the SALARY this advance is deducted from — not the day the
  /// cash left the drawer ([postingDate]). Before pay day an advance is usually
  /// last month's salary paid early. Legacy rows carry their posting month and
  /// [salaryMonthExplicit] is false.
  final String? salaryMonth;
  final bool salaryMonthExplicit;
  final String? currency;
  final double amount;
  final double paidAmount;
  final double claimedAmount;
  final double returnAmount;
  final double balance;
  final String? purpose;
  final String status;
  final int docstatus;
  final String? payingAccount;
  final String paymentLabel;
  final String? paymentLabelEn;
  final String? paymentLabelAr;
  final String? requestedBy;
  final String? requestedByName;
  final String? approvedBy;
  final DateTime? approvedOn;
  final String? paymentEntry;
  final String? company;
  final DateTime? createdOn;
  final DateTime? modifiedOn;

  const EmployeeAdvance({
    required this.name,
    required this.employee,
    required this.employeeName,
    this.branch,
    this.posProfile,
    this.postingDate,
    this.salaryMonth,
    this.salaryMonthExplicit = false,
    this.currency,
    required this.amount,
    required this.paidAmount,
    required this.claimedAmount,
    required this.returnAmount,
    required this.balance,
    this.purpose,
    required this.status,
    required this.docstatus,
    this.payingAccount,
    required this.paymentLabel,
    this.paymentLabelEn,
    this.paymentLabelAr,
    this.requestedBy,
    this.requestedByName,
    this.approvedBy,
    this.approvedOn,
    this.paymentEntry,
    this.company,
    this.createdOn,
    this.modifiedOn,
  });

  /// Awaiting a JARZ Manager. The backend keeps an unapproved request at
  /// docstatus 0 / status `Draft`; approving it submits and pays in one step.
  bool get isPendingApproval =>
      docstatus == 0 && status == EmployeeAdvanceStatus.draft;

  bool get isCancelled =>
      docstatus == 2 || status == EmployeeAdvanceStatus.cancelled;

  bool get isSubmitted => docstatus == 1;

  bool get isPaid =>
      status == EmployeeAdvanceStatus.paid ||
      status == EmployeeAdvanceStatus.claimed ||
      status == EmployeeAdvanceStatus.returned ||
      status == EmployeeAdvanceStatus.partlyClaimedAndReturned;

  String localizedPaymentLabel(String languageCode) {
    return localizedExpenseLabel(
      languageCode: languageCode,
      fallbackLabel: paymentLabel,
      englishLabel: paymentLabelEn,
      arabicLabel: paymentLabelAr,
    );
  }

  factory EmployeeAdvance.fromJson(Map<String, dynamic> json) {
    final employeeId = (json['employee'] ?? '').toString();
    final employeeName = (json['employee_name'] ?? '').toString();
    return EmployeeAdvance(
      name: (json['name'] ?? '').toString(),
      employee: employeeId,
      employeeName: employeeName.isNotEmpty ? employeeName : employeeId,
      branch: _optionalString(json['branch']),
      posProfile: _optionalString(json['pos_profile']),
      postingDate: _parseDate(json['posting_date']),
      salaryMonth: _optionalString(json['salary_month']),
      salaryMonthExplicit: json['salary_month_explicit'] == true ||
          json['salary_month_explicit'] == 1,
      currency: _optionalString(json['currency']),
      amount: _parseAmount(json['amount']),
      paidAmount: _parseAmount(json['paid_amount']),
      claimedAmount: _parseAmount(json['claimed_amount']),
      returnAmount: _parseAmount(json['return_amount']),
      balance: _parseAmount(json['balance']),
      purpose: _optionalString(json['purpose']),
      status: (json['status'] ?? '').toString(),
      docstatus: int.tryParse(json['docstatus']?.toString() ?? '') ?? 0,
      payingAccount: _optionalString(json['paying_account']),
      paymentLabel: (json['payment_label'] ?? '').toString(),
      paymentLabelEn: _optionalString(json['payment_label_en']),
      paymentLabelAr: _optionalString(json['payment_label_ar']),
      requestedBy: _optionalString(json['requested_by']),
      requestedByName: _optionalString(json['requested_by_name']),
      approvedBy: _optionalString(json['approved_by']),
      approvedOn: _parseDate(json['approved_on']),
      paymentEntry: _optionalString(json['payment_entry']),
      company: _optionalString(json['company']),
      createdOn: _parseDate(json['creation']),
      modifiedOn: _parseDate(json['modified']),
    );
  }
}

/// Cash a manager handed over as salary from the Monthly Expenses board
/// (Jarz Expense Request, kind Salary). Read-only: nothing to approve here.
class AdvanceSalaryPayment {
  final String name;
  final String employee;
  final String employeeName;
  final String? branch;
  final DateTime? postingDate;

  /// `YYYY-MM` of the salary this payment counts against.
  final String? salaryMonth;
  final String? salaryMonthLabel;
  final String? currency;
  final double amount;
  final String paymentLabel;
  final String? paymentLabelEn;
  final String? paymentLabelAr;
  final String? paidBy;
  final String? paidByName;
  final String? remarks;

  const AdvanceSalaryPayment({
    required this.name,
    required this.employee,
    required this.employeeName,
    this.branch,
    this.postingDate,
    this.salaryMonth,
    this.salaryMonthLabel,
    this.currency,
    required this.amount,
    this.paymentLabel = '',
    this.paymentLabelEn,
    this.paymentLabelAr,
    this.paidBy,
    this.paidByName,
    this.remarks,
  });

  String localizedPaymentLabel(String languageCode) {
    return localizedExpenseLabel(
      languageCode: languageCode,
      fallbackLabel: paymentLabel,
      englishLabel: paymentLabelEn,
      arabicLabel: paymentLabelAr,
    );
  }

  factory AdvanceSalaryPayment.fromJson(Map<String, dynamic> json) {
    final employeeId = (json['employee'] ?? '').toString();
    final employeeName = (json['employee_name'] ?? '').toString();
    return AdvanceSalaryPayment(
      name: (json['name'] ?? '').toString(),
      employee: employeeId,
      employeeName: employeeName.isNotEmpty ? employeeName : employeeId,
      branch: _optionalString(json['branch']),
      postingDate: _parseDate(json['posting_date']),
      salaryMonth: _optionalString(json['salary_month']),
      salaryMonthLabel: _optionalString(json['salary_month_label']),
      currency: _optionalString(json['currency']),
      amount: _parseAmount(json['amount']),
      paymentLabel: (json['payment_label'] ?? '').toString(),
      paymentLabelEn: _optionalString(json['payment_label_en']),
      paymentLabelAr: _optionalString(json['payment_label_ar']),
      paidBy: _optionalString(json['paid_by']),
      paidByName: _optionalString(json['paid_by_name']),
      remarks: _optionalString(json['remarks']),
    );
  }
}

class EmployeeAdvanceSummary {
  final double totalAmount;
  final int pendingCount;
  final double pendingAmount;
  final int approvedCount;
  final double outstandingAmount;

  /// Salary paid from the Monthly Expenses board (managers only; 0 otherwise).
  final int salaryPaidCount;
  final double salaryPaidAmount;

  /// Advances total plus salary paid.
  final double handedOutAmount;

  const EmployeeAdvanceSummary({
    required this.totalAmount,
    required this.pendingCount,
    required this.pendingAmount,
    required this.approvedCount,
    required this.outstandingAmount,
    this.salaryPaidCount = 0,
    this.salaryPaidAmount = 0,
    this.handedOutAmount = 0,
  });

  static const empty = EmployeeAdvanceSummary(
    totalAmount: 0,
    pendingCount: 0,
    pendingAmount: 0,
    approvedCount: 0,
    outstandingAmount: 0,
  );

  factory EmployeeAdvanceSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;
    return EmployeeAdvanceSummary(
      totalAmount: _parseAmount(json['total_amount']),
      pendingCount: int.tryParse(json['pending_count']?.toString() ?? '') ?? 0,
      pendingAmount: _parseAmount(json['pending_amount']),
      approvedCount: int.tryParse(json['approved_count']?.toString() ?? '') ?? 0,
      outstandingAmount: _parseAmount(json['outstanding_amount']),
      salaryPaidCount:
          int.tryParse(json['salary_paid_count']?.toString() ?? '') ?? 0,
      salaryPaidAmount: _parseAmount(json['salary_paid_amount']),
      handedOutAmount: _parseAmount(json['handed_out_amount']),
    );
  }
}

class EmployeeAdvanceBootstrap {
  /// `false` is a NORMAL answer, not an error: it means the HRMS app is not
  /// installed on the site. The screen renders [notice] as an explanatory empty
  /// state in that case, never an error tile.
  final bool hrmsAvailable;
  final bool canRequest;
  final bool canApprove;
  final String? company;
  final String? currency;
  final String currentMonth;
  final String requestedMonth;
  final String? statusFilter;
  final String? employeeFilter;
  final String? branchFilter;
  final List<ExpenseMonthOption> months;

  /// Salary months a new advance may be drawn against (newest first). Empty
  /// from a backend that predates the field — the form then hides the picker.
  final List<ExpenseMonthOption> salaryMonths;

  /// The likely answer (last month's salary until pay day). Only marked in the
  /// form, never pre-selected: the requester has to choose.
  final String? suggestedSalaryMonth;
  final List<AdvanceEmployeeOption> employees;
  final List<ExpensePaymentSource> paymentSources;
  final List<EmployeeAdvance> advances;
  final EmployeeAdvanceSummary summary;
  final String? notice;

  /// True only for managers on a backend that sends salary payments. Anything
  /// but an explicit true/1 hides the section.
  final bool salaryPaymentsVisible;
  final List<AdvanceSalaryPayment> salaryPayments;

  const EmployeeAdvanceBootstrap({
    required this.hrmsAvailable,
    required this.canRequest,
    required this.canApprove,
    this.company,
    this.currency,
    required this.currentMonth,
    required this.requestedMonth,
    this.statusFilter,
    this.employeeFilter,
    this.branchFilter,
    required this.months,
    this.salaryMonths = const [],
    this.suggestedSalaryMonth,
    required this.employees,
    required this.paymentSources,
    required this.advances,
    required this.summary,
    this.notice,
    this.salaryPaymentsVisible = false,
    this.salaryPayments = const [],
  });

  factory EmployeeAdvanceBootstrap.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> rows(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    final applied = json['applied_filters'];
    final appliedMap =
        applied is Map ? Map<String, dynamic>.from(applied) : const {};

    return EmployeeAdvanceBootstrap(
      // Absent means available: only an explicit `false` disables the tab, so a
      // backend that stops sending the flag does not black out the feature.
      hrmsAvailable: json['hrms_available'] != false &&
          json['hrms_available'] != 0 &&
          json['hrms_available'] != '0',
      canRequest: json['can_request'] == true || json['can_request'] == 1,
      canApprove: json['can_approve'] == true || json['can_approve'] == 1,
      company: _optionalString(json['company']),
      currency: _optionalString(json['currency']),
      currentMonth: (json['current_month'] ?? '').toString(),
      requestedMonth: (json['requested_month'] ?? '').toString(),
      statusFilter: _optionalString(appliedMap['status']),
      employeeFilter: _optionalString(appliedMap['employee']),
      branchFilter: _optionalString(appliedMap['branch']),
      months: rows('months').map(ExpenseMonthOption.fromJson).toList(),
      salaryMonths:
          rows('salary_months').map(ExpenseMonthOption.fromJson).toList(),
      suggestedSalaryMonth: _optionalString(json['suggested_salary_month']),
      employees: rows('employees').map(AdvanceEmployeeOption.fromJson).toList(),
      paymentSources:
          rows('payment_sources').map(ExpensePaymentSource.fromJson).toList(),
      advances: rows('advances').map(EmployeeAdvance.fromJson).toList(),
      summary: EmployeeAdvanceSummary.fromJson(
        json['summary'] is Map
            ? Map<String, dynamic>.from(json['summary'] as Map)
            : null,
      ),
      notice: _optionalString(json['notice']),
      salaryPaymentsVisible: json['salary_payments_visible'] == true ||
          json['salary_payments_visible'] == 1,
      salaryPayments:
          rows('salary_payments').map(AdvanceSalaryPayment.fromJson).toList(),
    );
  }
}
