import '../../expenses/models/expense_models.dart' show localizedExpenseLabel;

/// Models for `jarz_pos.api.monthly_expenses.get_monthly_expenses`.
///
/// Hand-written `fromJson`, exactly like `expenses/models/expense_models.dart`:
/// this module deliberately does NOT introduce freezed/json_serializable, so
/// the two finance features stay one style and one review surface.
///
/// Every parser is defensive on purpose. The payload is assembled from a
/// registry, the GL and HRMS, and a field that is absent for one row is normal
/// (a recurring expense with no supplier, an employee with no department), not
/// an error worth failing the whole screen over.

double _num(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _int(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

bool _bool(dynamic value) {
  return value == true || value == 1 || value == '1' || value == 'true';
}

String _str(dynamic value) => (value ?? '').toString();

String? _strOrNull(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

List<Map<String, dynamic>> _maps(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

/// The five states the backend reports for a recurring item or a salary row.
///
/// Kept as raw server strings rather than an enum: an unrecognised status still
/// has to render (as itself) instead of crashing the month, and the server owns
/// the vocabulary. [localizedMonthlyExpenseStatus] does the display mapping.
class MonthlyExpenseStatus {
  static const paid = 'Paid';
  static const partial = 'Partial';
  static const unpaid = 'Unpaid';
  static const notDue = 'Not Due';
  static const overpaid = 'Overpaid';

  const MonthlyExpenseStatus._();
}

/// Registry lifecycle status of a `Jarz Recurring Expense`.
class RecurringExpenseLifecycle {
  static const active = 'Active';
  static const paused = 'Paused';
  static const ended = 'Ended';

  const RecurringExpenseLifecycle._();
}

/// One entry of `available_months`.
///
/// The contract froze the *ordering* ("12 months back plus current, newest
/// last") but not the element shape, so both shapes the backend could
/// reasonably send are accepted: a bare `"2026-09"` string, or an object
/// carrying its own label. When only the id arrives the screen formats the
/// label itself from the locale.
class MonthlyExpenseMonthOption {
  final String id;
  final String? label;

  const MonthlyExpenseMonthOption({required this.id, this.label});

  factory MonthlyExpenseMonthOption.fromDynamic(dynamic value) {
    if (value is Map) {
      final json = Map<String, dynamic>.from(value);
      return MonthlyExpenseMonthOption(
        id: _str(json['month'] ?? json['id'] ?? json['value']),
        label: _strOrNull(json['month_label'] ?? json['label']),
      );
    }
    return MonthlyExpenseMonthOption(id: _str(value));
  }

  static List<MonthlyExpenseMonthOption> listFrom(dynamic value) {
    if (value is! List) return const [];
    return value
        .map(MonthlyExpenseMonthOption.fromDynamic)
        .where((m) => m.id.isNotEmpty)
        .toList();
  }
}

/// The month's headline figures. `remaining` is the number the screen leads
/// with — everything else on the header exists to explain it.
class MonthlyExpenseSummary {
  final double runRate;
  final double due;
  final double paid;
  final double remaining;
  final double overpaid;
  final int itemsTotal;
  final int itemsPaid;
  final int itemsPartial;
  final int itemsUnpaid;

  const MonthlyExpenseSummary({
    this.runRate = 0,
    this.due = 0,
    this.paid = 0,
    this.remaining = 0,
    this.overpaid = 0,
    this.itemsTotal = 0,
    this.itemsPaid = 0,
    this.itemsPartial = 0,
    this.itemsUnpaid = 0,
  });

  factory MonthlyExpenseSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MonthlyExpenseSummary();
    return MonthlyExpenseSummary(
      runRate: _num(json['run_rate']),
      due: _num(json['due']),
      paid: _num(json['paid']),
      remaining: _num(json['remaining']),
      overpaid: _num(json['overpaid']),
      itemsTotal: _int(json['items_total']),
      itemsPaid: _int(json['items_paid']),
      itemsPartial: _int(json['items_partial']),
      itemsUnpaid: _int(json['items_unpaid']),
    );
  }
}

/// A `by_category` row. `source` says where the numbers came from (the registry
/// or payroll), which is why the salaries block can appear as a category total
/// without being a registry item.
class MonthlyExpenseCategoryTotal {
  final String category;
  final double due;
  final double paid;
  final double remaining;
  final int count;
  final String source;

  const MonthlyExpenseCategoryTotal({
    required this.category,
    required this.due,
    required this.paid,
    required this.remaining,
    required this.count,
    required this.source,
  });

  factory MonthlyExpenseCategoryTotal.fromJson(Map<String, dynamic> json) {
    return MonthlyExpenseCategoryTotal(
      category: _str(json['category']),
      due: _num(json['due']),
      paid: _num(json['paid']),
      remaining: _num(json['remaining']),
      count: _int(json['count']),
      source: _str(json['source']),
    );
  }
}

/// One submitted `Jarz Expense Request` that paid part or all of a period.
class MonthlyExpensePayment {
  final String name;
  final double amount;
  final DateTime? date;
  final String payingAccount;
  final String payingLabel;
  final String? journalEntry;
  final String? remarks;
  final String? by;

  const MonthlyExpensePayment({
    required this.name,
    required this.amount,
    this.date,
    this.payingAccount = '',
    this.payingLabel = '',
    this.journalEntry,
    this.remarks,
    this.by,
  });

  /// What to show as the source of the money: the server's label when it sent
  /// one, otherwise the raw account, which is never empty for a posted payment.
  String get sourceLabel =>
      payingLabel.trim().isNotEmpty ? payingLabel.trim() : payingAccount;

  factory MonthlyExpensePayment.fromJson(Map<String, dynamic> json) {
    return MonthlyExpensePayment(
      name: _str(json['name']),
      amount: _num(json['amount']),
      date: _date(json['date']),
      payingAccount: _str(json['paying_account']),
      payingLabel: _str(json['paying_label']),
      journalEntry: _strOrNull(json['journal_entry']),
      remarks: _strOrNull(json['remarks']),
      by: _strOrNull(json['by']),
    );
  }

  static List<MonthlyExpensePayment> listFrom(dynamic value) =>
      _maps(value).map(MonthlyExpensePayment.fromJson).toList();
}

/// A single registry item resolved against the selected month.
class RecurringExpenseItem {
  final String name;
  final String expenseName;
  final String category;
  final String status;
  final double amount;
  final String frequency;
  final double monthlyEquivalent;
  final int? dayOfMonth;
  final DateTime? dueDate;
  final String expenseAccount;
  final String expenseAccountLabel;
  final String? costCenter;
  final String? supplier;
  final String? defaultPayingAccount;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;

  final bool dueThisMonth;
  final double dueAmount;
  final double paidAmount;
  final double paidLinked;
  final double paidUnlinked;
  final double remaining;
  final String paymentStatus;

  /// Several items due this month post to the SAME expense account, so ledger
  /// money that did not come through the app cannot be attributed to one of
  /// them. The card says so instead of guessing.
  final bool sharedAccount;

  /// `paid_amount` includes money read out of the GL rather than a payment made
  /// in this app. Surfaced on the card because "paid" then means "the ledger
  /// says so", which is a materially weaker claim than "we paid it here".
  final bool inferred;

  final bool canPay;
  final List<MonthlyExpensePayment> payments;

  const RecurringExpenseItem({
    required this.name,
    required this.expenseName,
    required this.category,
    required this.status,
    required this.amount,
    required this.frequency,
    required this.monthlyEquivalent,
    this.dayOfMonth,
    this.dueDate,
    required this.expenseAccount,
    required this.expenseAccountLabel,
    this.costCenter,
    this.supplier,
    this.defaultPayingAccount,
    this.startDate,
    this.endDate,
    this.notes,
    required this.dueThisMonth,
    required this.dueAmount,
    required this.paidAmount,
    required this.paidLinked,
    required this.paidUnlinked,
    required this.remaining,
    required this.paymentStatus,
    required this.sharedAccount,
    required this.inferred,
    required this.canPay,
    required this.payments,
  });

  bool get isActive => status == RecurringExpenseLifecycle.active;
  bool get isPaused => status == RecurringExpenseLifecycle.paused;
  bool get isEnded => status == RecurringExpenseLifecycle.ended;

  /// The label to put on the card. Falls back to the doc name so a row with a
  /// blank `expense_name` is still identifiable rather than a blank line.
  String get displayName =>
      expenseName.trim().isNotEmpty ? expenseName.trim() : name;

  String get accountDisplayLabel => expenseAccountLabel.trim().isNotEmpty
      ? expenseAccountLabel.trim()
      : expenseAccount;

  factory RecurringExpenseItem.fromJson(Map<String, dynamic> json) {
    return RecurringExpenseItem(
      name: _str(json['name']),
      expenseName: _str(json['expense_name']),
      category: _str(json['category']),
      status: _str(json['status']),
      amount: _num(json['amount']),
      frequency: _str(json['frequency']),
      monthlyEquivalent: _num(json['monthly_equivalent']),
      dayOfMonth: json['day_of_month'] == null
          ? null
          : _int(json['day_of_month']),
      dueDate: _date(json['due_date']),
      expenseAccount: _str(json['expense_account']),
      expenseAccountLabel: _str(json['expense_account_label']),
      costCenter: _strOrNull(json['cost_center']),
      supplier: _strOrNull(json['supplier']),
      defaultPayingAccount: _strOrNull(json['default_paying_account']),
      startDate: _date(json['start_date']),
      endDate: _date(json['end_date']),
      notes: _strOrNull(json['notes']),
      dueThisMonth: _bool(json['due_this_month']),
      dueAmount: _num(json['due_amount']),
      paidAmount: _num(json['paid_amount']),
      paidLinked: _num(json['paid_linked']),
      paidUnlinked: _num(json['paid_unlinked']),
      remaining: _num(json['remaining']),
      paymentStatus: _str(json['payment_status']),
      sharedAccount: _bool(json['shared_account']),
      inferred: _bool(json['inferred']),
      canPay: _bool(json['can_pay']),
      payments: MonthlyExpensePayment.listFrom(json['payments']),
    );
  }

  static List<RecurringExpenseItem> listFrom(dynamic value) =>
      _maps(value).map(RecurringExpenseItem.fromJson).toList();
}

/// The three ways a penalty can be expressed. Server vocabulary, verbatim:
/// `Jarz Employee Penalty.unit` is a Select with exactly these options, and the
/// conversion below is the DocType's `validate` mirrored locally so the sheet
/// can show the equivalence before anything is sent.
class PenaltyUnit {
  static const days = 'Days';
  static const halfDays = 'Half Days';
  static const money = 'Money';

  static const all = <String>[days, halfDays, money];

  const PenaltyUnit._();
}

/// The money value of a penalty, from whatever the user typed.
///
/// Mirrors `Jarz Employee Penalty.validate` exactly — Days multiply the day
/// rate, Half Days multiply half of it, Money is taken as given. Duplicated on
/// the client ON PURPOSE: the sheet has to show the equivalence on every
/// keystroke, and a round trip per keystroke is not that.
double penaltyAmountFor({
  required String unit,
  required double quantity,
  required double amount,
  required double dayRate,
}) {
  switch (unit) {
    case PenaltyUnit.days:
      return quantity * dayRate;
    case PenaltyUnit.halfDays:
      return quantity * dayRate / 2;
    case PenaltyUnit.money:
    default:
      return amount;
  }
}

/// The day value of a penalty, from whatever the user typed.
///
/// Deliberately NOT rounded to a whole day: half a day is a real answer, and
/// 600 against a 400 day rate is 1.5 days, not "1" or "2". A day rate of 0
/// yields 0 rather than infinity — that employee has no salary structure, so a
/// day genuinely has no value for them.
double penaltyDaysFor({
  required String unit,
  required double quantity,
  required double amount,
  required double dayRate,
}) {
  switch (unit) {
    case PenaltyUnit.days:
      return quantity;
    case PenaltyUnit.halfDays:
      return quantity / 2;
    case PenaltyUnit.money:
    default:
      return dayRate > 0 ? amount / dayRate : 0;
  }
}

/// One submitted `Jarz Employee Penalty` deducted from this month's salary.
///
/// [dayRate] is the rate SNAPSHOTTED when the penalty was entered, not the
/// employee's rate today: a raise afterwards must not silently re-price a
/// penalty already agreed with them.
class PenaltyEntry {
  final String name;
  final DateTime? penaltyDate;
  final String periodMonth;
  final String unit;
  final double quantity;
  final double amount;
  final double equivalentDays;
  final double dayRate;
  final String reason;

  /// Already discharged by a salary payment. A settled penalty cannot be
  /// cancelled — the server refuses it, so the card hides the action.
  final bool settled;

  const PenaltyEntry({
    required this.name,
    this.penaltyDate,
    this.periodMonth = '',
    this.unit = PenaltyUnit.money,
    this.quantity = 0,
    this.amount = 0,
    this.equivalentDays = 0,
    this.dayRate = 0,
    this.reason = '',
    this.settled = false,
  });

  factory PenaltyEntry.fromJson(Map<String, dynamic> json) {
    final unit = _str(json['unit']);
    return PenaltyEntry(
      name: _str(json['name']),
      penaltyDate: _date(json['penalty_date']),
      periodMonth: _str(json['period_month']),
      unit: unit.isEmpty ? PenaltyUnit.money : unit,
      quantity: _num(json['quantity']),
      amount: _num(json['amount']),
      equivalentDays: _num(json['equivalent_days']),
      dayRate: _num(json['day_rate']),
      reason: _str(json['reason']),
      settled: _bool(json['settled']),
    );
  }

  static List<PenaltyEntry> listFrom(dynamic value) =>
      _maps(value).map(PenaltyEntry.fromJson).toList();
}

/// One submitted `Employee Advance` with money still outstanding.
///
/// The balance is ALL-TIME, not this month's: windowing it would hide exactly
/// the stale debt worth collecting. Belal's two advances are why this class
/// exists — they were invisible on this screen while the money was out.
class AdvanceEntry {
  final String name;
  final DateTime? postingDate;

  /// What was advanced originally.
  final double amount;

  /// What is still open: paid − claimed − returned − already settled here.
  final double outstanding;

  final String purpose;
  final String status;

  /// Where the advance sits in the ledger. Reported, never repointed: on
  /// production all three open advances sit on `Debtors - J`, which is customer
  /// AR, and the server raises a gap about it rather than moving anything.
  final String advanceAccount;

  const AdvanceEntry({
    required this.name,
    this.postingDate,
    this.amount = 0,
    this.outstanding = 0,
    this.purpose = '',
    this.status = '',
    this.advanceAccount = '',
  });

  factory AdvanceEntry.fromJson(Map<String, dynamic> json) {
    return AdvanceEntry(
      name: _str(json['name']),
      postingDate: _date(json['posting_date']),
      amount: _num(json['amount']),
      outstanding: _num(json['outstanding']),
      purpose: _str(json['purpose']),
      status: _str(json['status']),
      advanceAccount: _str(json['advance_account']),
    );
  }

  static List<AdvanceEntry> listFrom(dynamic value) =>
      _maps(value).map(AdvanceEntry.fromJson).toList();
}

/// One unpaid Sales Invoice rung up with the Employee order policy — staff who
/// took jars and have not paid for them.
///
/// Only invoices carrying `custom_order_purpose = "Employee"` count. A customer
/// merely linked to an employee does NOT: production has 48 such links and they
/// are misused, so trusting them would bill people for other people's orders.
class EmployeeOrderEntry {
  final String invoice;
  final DateTime? postingDate;
  final String customer;
  final String customerName;
  final double grandTotal;
  final double outstanding;
  final String status;

  /// POS profile (branch) the order was rung up on.
  final String branch;

  /// Kanban state of the order (Delivered, Out for delivery, ...).
  final String orderState;

  const EmployeeOrderEntry({
    required this.invoice,
    this.postingDate,
    this.customer = '',
    this.customerName = '',
    this.grandTotal = 0,
    this.outstanding = 0,
    this.status = '',
    this.branch = '',
    this.orderState = '',
  });

  String get displayCustomer =>
      customerName.trim().isNotEmpty ? customerName.trim() : customer;

  factory EmployeeOrderEntry.fromJson(Map<String, dynamic> json) {
    return EmployeeOrderEntry(
      invoice: _str(json['invoice'] ?? json['name']),
      postingDate: _date(json['posting_date']),
      customer: _str(json['customer']),
      customerName: _str(json['customer_name']),
      grandTotal: _num(json['grand_total']),
      outstanding: _num(json['outstanding']),
      status: _str(json['status']),
      branch: _str(json['branch']),
      orderState: _str(json['order_state']),
    );
  }

  static List<EmployeeOrderEntry> listFrom(dynamic value) =>
      _maps(value).map(EmployeeOrderEntry.fromJson).toList();
}

/// The month's deductions across everybody — the top-level `deductions` block.
class DeductionsSummary {
  final double penaltyTotal;
  final double penaltyDays;
  final double advanceTotal;
  final double orderTotal;
  final double total;

  /// What is left to hand over in cash once the open balances come off.
  final double netPayable;

  /// HRMS answered. When false the advance figures are not zero, they are
  /// UNKNOWN, and the server raises an `advances_unreadable` gap saying so.
  final bool advancesReadable;

  /// At least one Sales Invoice has ever been rung up as an Employee order.
  /// False on production today, which is why the board legitimately shows no
  /// jar debt — the server emits an INFO gap explaining exactly that.
  final bool employeeOrdersPresent;

  /// The Select options for a new penalty, in the server's own vocabulary.
  final List<String> penaltyUnits;

  /// The fixed calendar basis behind the day rate: monthly salary / this.
  final int daysPerMonth;

  /// Unpaid Employee-purpose orders whose customer is linked to no employee:
  /// they reach no salary row, so they are listed on their own.
  final List<EmployeeOrderEntry> unattributedOrders;
  final double unattributedOrderTotal;

  const DeductionsSummary({
    this.penaltyTotal = 0,
    this.penaltyDays = 0,
    this.advanceTotal = 0,
    this.orderTotal = 0,
    this.total = 0,
    this.netPayable = 0,
    this.advancesReadable = true,
    this.employeeOrdersPresent = false,
    this.penaltyUnits = PenaltyUnit.all,
    this.daysPerMonth = 30,
    this.unattributedOrders = const [],
    this.unattributedOrderTotal = 0,
  });

  bool get hasAny =>
      penaltyTotal.abs() > 0.005 ||
      advanceTotal.abs() > 0.005 ||
      orderTotal.abs() > 0.005;

  factory DeductionsSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DeductionsSummary();
    final units = _stringList(json['penalty_units']);
    return DeductionsSummary(
      penaltyTotal: _num(json['penalty_total']),
      penaltyDays: _num(json['penalty_days']),
      advanceTotal: _num(json['advance_total']),
      orderTotal: _num(json['order_total']),
      total: _num(json['total']),
      netPayable: _num(json['net_payable']),
      // Absent means readable: a server build that never had this flag was
      // reading HRMS fine, and defaulting to "unreadable" would warn about a
      // problem that does not exist.
      advancesReadable: json.containsKey('advances_readable')
          ? _bool(json['advances_readable'])
          : true,
      employeeOrdersPresent: _bool(json['employee_orders_present']),
      penaltyUnits: units.isEmpty ? PenaltyUnit.all : units,
      daysPerMonth:
          json['days_per_month'] == null ? 30 : _int(json['days_per_month']),
      unattributedOrders:
          EmployeeOrderEntry.listFrom(json['unattributed_orders']),
      unattributedOrderTotal: _num(json['unattributed_order_total']),
    );
  }
}

/// One advance to discharge as part of a salary payment.
class AdvanceSettlement {
  final String name;
  final double amount;

  const AdvanceSettlement({required this.name, required this.amount});

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};
}

/// One staff order to discharge as part of a salary payment.
class OrderSettlement {
  final String invoice;
  final double amount;

  const OrderSettlement({required this.invoice, required this.amount});

  Map<String, dynamic> toJson() => {'invoice': invoice, 'amount': amount};
}

/// A penalty about to be created.
///
/// A class rather than a loose map so the field names are written once: the
/// sheet, the repository and the test read the same definition, and a typo is a
/// compile error instead of a field the server silently ignores.
class PenaltyDraft {
  final String employee;
  final String unit;

  /// Days or half-days. Null when [unit] is Money.
  final double? quantity;

  /// Money. Null when [unit] is Days or Half Days — the server derives it from
  /// the day rate it snapshots, so sending a client-computed amount as well
  /// would be two sources of truth for one number.
  final double? amount;

  final String reason;

  /// `YYYY-MM-DD`. Null lets the server stamp today.
  final String? penaltyDate;

  const PenaltyDraft({
    required this.employee,
    required this.unit,
    required this.reason,
    this.quantity,
    this.amount,
    this.penaltyDate,
  });
}

/// One employee's salary for the month, and everything that reduces it.
///
/// The money model has one meaning per number: [grossDue] is the structure's
/// salary, [dueAmount] is that minus this month's penalties, [remaining] is the
/// obligation still open, and [netPayable] is the cash to hand over once the
/// advance and staff-order balances come off. Four fields because they answer
/// four different questions — collapsing any two is how someone gets paid twice.
class SalaryRow {
  final String employee;
  final String employeeName;
  final String? designation;
  final String? department;
  final double base;
  final double variable;

  /// The month's salary BEFORE penalties.
  final double grossDue;

  /// `gross_due / days_per_month`, snapshotted server-side. 0 for an employee
  /// with no salary structure — which is exactly why the penalty sheet has to
  /// refuse Days for them and ask for money instead.
  final double dayRate;

  final double dueAmount;
  final double paidAmount;
  final double remaining;
  final String paymentStatus;

  final double penaltyTotal;
  final double penaltyDays;
  final List<PenaltyEntry> penalties;

  /// Open advance balance, ALL-TIME rather than month-scoped.
  final double advanceTotal;
  final List<AdvanceEntry> advances;

  /// Open balance on staff orders — jars taken and not paid for.
  final double orderTotal;
  final List<EmployeeOrderEntry> orders;

  final double deductionsTotal;

  /// How much of the deductions a payment has already discharged.
  final double settledAmount;

  /// Cash to hand over now.
  final double netPayable;

  /// No salary structure at all: the row exists only because this employee
  /// carries an advance, a staff order or a penalty. Two people are deliberately
  /// off payroll on production, and an advance to either still has to appear.
  final bool offPayroll;

  /// This person has LEFT the company (an off-payroll row whose employee is
  /// no longer active). They are listed apart from the staff on payroll, at the
  /// end of the screen, because they are not paid this month — the row only
  /// exists because they still owe an advance or a staff order. The server
  /// sorts these last; an older server never sends the key, which reads false.
  final bool left;

  /// The HR relieving date of a [left] employee, when HR recorded one.
  final DateTime? relievingDate;

  /// A submitted Salary Slip already exists for this period, so paying here
  /// would double-post. The backend refuses it; the card hides the button.
  final bool hasSalarySlip;

  final bool canPay;
  final List<MonthlyExpensePayment> payments;

  const SalaryRow({
    required this.employee,
    required this.employeeName,
    this.designation,
    this.department,
    required this.base,
    required this.variable,
    required this.dueAmount,
    required this.paidAmount,
    required this.remaining,
    required this.paymentStatus,
    required this.hasSalarySlip,
    required this.canPay,
    required this.payments,
    this.grossDue = 0,
    this.dayRate = 0,
    this.penaltyTotal = 0,
    this.penaltyDays = 0,
    this.penalties = const [],
    this.advanceTotal = 0,
    this.advances = const [],
    this.orderTotal = 0,
    this.orders = const [],
    this.deductionsTotal = 0,
    this.settledAmount = 0,
    this.netPayable = 0,
    this.offPayroll = false,
    this.left = false,
    this.relievingDate,
  });

  String get displayName =>
      employeeName.trim().isNotEmpty ? employeeName.trim() : employee;

  /// Whether anything at all reduces what the company hands over. Drives
  /// whether the card renders a deductions block: a clean row has to stay the
  /// single line it is today, because this screen lists sixteen people.
  bool get hasDeductions =>
      penaltyTotal.abs() > 0.005 ||
      advanceTotal.abs() > 0.005 ||
      orderTotal.abs() > 0.005;

  /// Balances one payment could settle in the same action.
  bool get hasOpenBalances => advances.isNotEmpty || orders.isNotEmpty;

  factory SalaryRow.fromJson(Map<String, dynamic> json) {
    final dueAmount = _num(json['due_amount']);
    final remaining = _num(json['remaining']);
    final penaltyTotal = _num(json['penalty_total']);
    final advanceTotal = _num(json['advance_total']);
    final orderTotal = _num(json['order_total']);

    // Every derived figure falls back to its own definition rather than to
    // zero: a server that has not shipped these fields yet must still render a
    // correct card, and a zero `gross_due` would read as "earns nothing".
    final grossDue = json['gross_due'] == null
        ? dueAmount + penaltyTotal
        : _num(json['gross_due']);
    final deductionsTotal = json['deductions_total'] == null
        ? penaltyTotal + advanceTotal + orderTotal
        : _num(json['deductions_total']);
    final netRaw = remaining - advanceTotal - orderTotal;
    final netPayable = json['net_payable'] == null
        ? (netRaw > 0 ? netRaw : 0.0)
        : _num(json['net_payable']);

    return SalaryRow(
      employee: _str(json['employee']),
      employeeName: _str(json['employee_name']),
      designation: _strOrNull(json['designation']),
      department: _strOrNull(json['department']),
      base: _num(json['base']),
      variable: _num(json['variable']),
      grossDue: grossDue,
      dayRate: _num(json['day_rate']),
      dueAmount: dueAmount,
      paidAmount: _num(json['paid_amount']),
      remaining: remaining,
      paymentStatus: _str(json['payment_status']),
      penaltyTotal: penaltyTotal,
      penaltyDays: _num(json['penalty_days']),
      penalties: PenaltyEntry.listFrom(json['penalties']),
      advanceTotal: advanceTotal,
      advances: AdvanceEntry.listFrom(json['advances']),
      orderTotal: orderTotal,
      orders: EmployeeOrderEntry.listFrom(json['orders']),
      deductionsTotal: deductionsTotal,
      settledAmount: _num(json['settled_amount']),
      netPayable: netPayable,
      offPayroll: _bool(json['off_payroll']),
      left: _bool(json['left']),
      relievingDate: _date(_strOrNull(json['relieving_date'])),
      hasSalarySlip: _bool(json['has_salary_slip']),
      canPay: _bool(json['can_pay']),
      payments: MonthlyExpensePayment.listFrom(json['payments']),
    );
  }
}

/// An employee with no submitted Salary Structure Assignment. Reported as a
/// caveat beside the salaries list, never as a row with a zero in it: a zero
/// would read as "nothing owed", when the truth is "we do not know".
class SalaryGapEmployee {
  final String employee;
  final String employeeName;
  final String? designation;
  final String? department;

  const SalaryGapEmployee({
    required this.employee,
    required this.employeeName,
    this.designation,
    this.department,
  });

  String get displayName =>
      employeeName.trim().isNotEmpty ? employeeName.trim() : employee;

  factory SalaryGapEmployee.fromJson(Map<String, dynamic> json) {
    return SalaryGapEmployee(
      employee: _str(json['employee']),
      employeeName: _str(json['employee_name']),
      designation: _strOrNull(json['designation']),
      department: _strOrNull(json['department']),
    );
  }
}

class PayrollBlock {
  final bool configured;
  final int employeesTotal;
  final int employeesWithStructure;
  final int employeesWithoutStructure;
  final String? salaryAccount;
  final double due;
  final double paid;
  final double remaining;

  /// Salary GL that no row can claim. Salary posts to one account for the whole
  /// company, so it cannot be split per employee — it is reported once, here,
  /// and never folded into a row.
  final double unattributedGl;

  final List<SalaryRow> rows;
  final List<SalaryGapEmployee> missing;

  const PayrollBlock({
    this.configured = false,
    this.employeesTotal = 0,
    this.employeesWithStructure = 0,
    this.employeesWithoutStructure = 0,
    this.salaryAccount,
    this.due = 0,
    this.paid = 0,
    this.remaining = 0,
    this.unattributedGl = 0,
    this.rows = const [],
    this.missing = const [],
  });

  /// Rows of people still on staff, in server order. This is the salaries list.
  List<SalaryRow> get activeRows => [
        for (final row in rows)
          if (!row.left) row,
      ];

  /// Rows of people who have left and still owe money. Rendered apart, at the
  /// end, so they stop reading as part of this month's payroll.
  List<SalaryRow> get leftRows => [
        for (final row in rows)
          if (row.left) row,
      ];

  factory PayrollBlock.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PayrollBlock();
    return PayrollBlock(
      configured: _bool(json['configured']),
      employeesTotal: _int(json['employees_total']),
      employeesWithStructure: _int(json['employees_with_structure']),
      employeesWithoutStructure: _int(json['employees_without_structure']),
      salaryAccount: _strOrNull(json['salary_account']),
      due: _num(json['due']),
      paid: _num(json['paid']),
      remaining: _num(json['remaining']),
      unattributedGl: _num(json['unattributed_gl']),
      rows: _maps(json['rows']).map(SalaryRow.fromJson).toList(),
      missing: _maps(json['missing']).map(SalaryGapEmployee.fromJson).toList(),
    );
  }
}

/// A cash-or-bank account the payment can come out of.
///
/// The contract says the backend reuses `expenses._serialize_payment_sources`
/// so the picker matches the ad-hoc expense screen, but declares the field as
/// `type` while that serializer emits `category`. Both are read, so whichever
/// the server actually sends lands in the same place — the alternative is a
/// picker whose every entry says "account".
class MonthlyExpensePaymentSource {
  final String id;
  final String account;
  final String label;
  final String? labelEn;
  final String? labelAr;
  final String type;
  final double balance;
  final String? posProfile;

  const MonthlyExpensePaymentSource({
    required this.id,
    required this.account,
    required this.label,
    this.labelEn,
    this.labelAr,
    this.type = 'account',
    this.balance = 0,
    this.posProfile,
  });

  String localizedLabel(String languageCode) => localizedExpenseLabel(
        languageCode: languageCode,
        fallbackLabel: label.isNotEmpty ? label : account,
        englishLabel: labelEn,
        arabicLabel: labelAr,
      );

  factory MonthlyExpensePaymentSource.fromJson(Map<String, dynamic> json) {
    return MonthlyExpensePaymentSource(
      id: _str(json['id'] ?? json['account']),
      account: _str(json['account']),
      label: _str(json['label']),
      labelEn: _strOrNull(json['label_en']),
      labelAr: _strOrNull(json['label_ar']),
      type: _str(json['type'] ?? json['category']).isEmpty
          ? 'account'
          : _str(json['type'] ?? json['category']),
      balance: _num(json['balance']),
      posProfile: _strOrNull(json['pos_profile']),
    );
  }

  static List<MonthlyExpensePaymentSource> listFrom(dynamic value) =>
      _maps(value).map(MonthlyExpensePaymentSource.fromJson).toList();
}

/// An `expense_accounts` option for the manage form.
class ExpenseAccountOption {
  final String account;
  final String label;

  const ExpenseAccountOption({required this.account, required this.label});

  String get displayLabel => label.trim().isNotEmpty ? label.trim() : account;

  factory ExpenseAccountOption.fromJson(Map<String, dynamic> json) {
    return ExpenseAccountOption(
      account: _str(json['account']),
      label: _str(json['label']),
    );
  }

  static List<ExpenseAccountOption> listFrom(dynamic value) => _maps(value)
      .map(ExpenseAccountOption.fromJson)
      .where((o) => o.account.isNotEmpty)
      .toList();
}

/// A `cost_centers` option for the manage form.
class CostCenterOption {
  final String name;
  final String label;

  const CostCenterOption({required this.name, required this.label});

  String get displayLabel => label.trim().isNotEmpty ? label.trim() : name;

  factory CostCenterOption.fromJson(Map<String, dynamic> json) {
    return CostCenterOption(
      name: _str(json['name']),
      label: _str(json['label']),
    );
  }

  static List<CostCenterOption> listFrom(dynamic value) => _maps(value)
      .map(CostCenterOption.fromJson)
      .where((o) => o.name.isNotEmpty)
      .toList();
}

/// Something the server wants the manager to know before trusting the numbers:
/// a missing salary structure, an overpaid item, unattributable salary GL, an
/// empty registry. Rendered at the top of the screen, above the money.
class MonthlyExpenseGap {
  final String severity;
  final String message;

  const MonthlyExpenseGap({required this.severity, required this.message});

  bool get isCritical {
    final s = severity.toLowerCase();
    return s == 'critical' || s == 'error' || s == 'danger';
  }

  /// Purely informational: nothing is wrong, there is simply something the
  /// manager should know before reading a zero as a fact — "no order has ever
  /// been rung up as a staff order" is the case this was added for.
  ///
  /// Split out from [isCritical] so a month whose only gaps are INFO stops
  /// painting itself in the error colour. A banner that is always red is a
  /// banner nobody reads by the third month.
  bool get isInfo {
    final s = severity.toLowerCase();
    return s == 'info' || s == 'information' || s == 'notice';
  }

  factory MonthlyExpenseGap.fromJson(Map<String, dynamic> json) {
    return MonthlyExpenseGap(
      severity: _str(json['severity']),
      message: _str(json['message']),
    );
  }

  static List<MonthlyExpenseGap> listFrom(dynamic value) => _maps(value)
      .map(MonthlyExpenseGap.fromJson)
      .where((g) => g.message.isNotEmpty)
      .toList();
}

/// The whole `get_monthly_expenses` response.
class MonthlyExpensesPayload {
  /// The board's month, `YYYY-MM`. During days 1-20 the server opens on the
  /// PREVIOUS month, because that is the month whose salaries are being paid.
  final String month;
  final String monthLabel;

  /// Today's month on the server, `YYYY-MM`. Empty against an older server.
  final String currentMonth;
  final DateTime? monthStart;
  final DateTime? monthEnd;
  final String company;
  final String currency;
  final List<MonthlyExpenseMonthOption> availableMonths;
  final MonthlyExpenseSummary summary;
  final List<MonthlyExpenseCategoryTotal> byCategory;
  final List<RecurringExpenseItem> recurring;
  final PayrollBlock payroll;
  final List<MonthlyExpensePaymentSource> paymentSources;
  final List<ExpenseAccountOption> expenseAccounts;
  final List<CostCenterOption> costCenters;
  final List<String> categories;
  final List<String> frequencies;
  final List<MonthlyExpenseGap> gaps;

  /// What reduces the month's payroll bill, company-wide: penalties, open
  /// advances and unpaid staff orders. Never folded into [summary] — that block
  /// answers "what does the company owe", this one answers "what do we actually
  /// hand over", and the two differ by exactly the money staff already took.
  final DeductionsSummary deductions;

  final bool canManage;

  /// Whether this user may reverse a posted payment.
  ///
  /// Deliberately separate from [canManage]: cancelling reverses a Journal
  /// Entry, and the server gates that on a NARROWER role set (JARZ Manager and
  /// the admin tier) than the one that may read this screen (which also admits
  /// Accounts Manager). Reusing [canManage] would show an Accounts Manager a
  /// Cancel button that always fails.
  final bool canCancelPayments;

  const MonthlyExpensesPayload({
    this.month = '',
    this.monthLabel = '',
    this.currentMonth = '',
    this.monthStart,
    this.monthEnd,
    this.company = '',
    this.currency = '',
    this.availableMonths = const [],
    this.summary = const MonthlyExpenseSummary(),
    this.byCategory = const [],
    this.recurring = const [],
    this.payroll = const PayrollBlock(),
    this.paymentSources = const [],
    this.expenseAccounts = const [],
    this.costCenters = const [],
    this.categories = const [],
    this.frequencies = const [],
    this.gaps = const [],
    this.deductions = const DeductionsSummary(),
    this.canManage = false,
    this.canCancelPayments = false,
  });

  /// Registry items keyed by category, categories in the order `by_category`
  /// gives them so the sections match the totals the header shows. Categories
  /// the server did not rank are appended alphabetically rather than dropped.
  Map<String, List<RecurringExpenseItem>> get recurringByCategory {
    final grouped = <String, List<RecurringExpenseItem>>{};
    for (final item in recurring) {
      final key = item.category.trim().isEmpty ? '' : item.category.trim();
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final ordered = <String, List<RecurringExpenseItem>>{};
    for (final total in byCategory) {
      final key = total.category.trim();
      final items = grouped.remove(key);
      if (items != null && items.isNotEmpty) ordered[key] = items;
    }
    final leftovers = grouped.keys.toList()..sort();
    for (final key in leftovers) {
      ordered[key] = grouped[key]!;
    }
    return ordered;
  }

  MonthlyExpenseCategoryTotal? categoryTotal(String category) {
    for (final total in byCategory) {
      if (total.category.trim() == category.trim()) return total;
    }
    return null;
  }

  factory MonthlyExpensesPayload.fromJson(Map<String, dynamic> json) {
    return MonthlyExpensesPayload(
      month: _str(json['month']),
      monthLabel: _str(json['month_label']),
      currentMonth: _str(json['current_month']),
      monthStart: _date(json['month_start']),
      monthEnd: _date(json['month_end']),
      company: _str(json['company']),
      currency: _str(json['currency']),
      availableMonths:
          MonthlyExpenseMonthOption.listFrom(json['available_months']),
      summary: MonthlyExpenseSummary.fromJson(
        json['summary'] is Map
            ? Map<String, dynamic>.from(json['summary'] as Map)
            : null,
      ),
      byCategory: _maps(json['by_category'])
          .map(MonthlyExpenseCategoryTotal.fromJson)
          .toList(),
      recurring: RecurringExpenseItem.listFrom(json['recurring']),
      payroll: PayrollBlock.fromJson(
        json['payroll'] is Map
            ? Map<String, dynamic>.from(json['payroll'] as Map)
            : null,
      ),
      paymentSources:
          MonthlyExpensePaymentSource.listFrom(json['payment_sources']),
      expenseAccounts: ExpenseAccountOption.listFrom(json['expense_accounts']),
      costCenters: CostCenterOption.listFrom(json['cost_centers']),
      categories: _stringList(json['categories']),
      frequencies: _stringList(json['frequencies']),
      gaps: MonthlyExpenseGap.listFrom(json['gaps']),
      deductions: DeductionsSummary.fromJson(
        json['deductions'] is Map
            ? Map<String, dynamic>.from(json['deductions'] as Map)
            : null,
      ),
      canManage: _bool(json['can_manage']),
      canCancelPayments: _bool(json['can_cancel_payments']),
    );
  }
}

/// `categories` / `frequencies` are declared as bare lists in the contract but
/// the Desk-side helpers they come from return `{"value","label"}` rows for
/// some Selects, so both are flattened to the value the API expects back.
List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  final out = <String>[];
  for (final item in value) {
    if (item is Map) {
      final map = Map<String, dynamic>.from(item);
      final text = _str(map['value'] ?? map['name'] ?? map['label']);
      if (text.isNotEmpty) out.add(text);
    } else {
      final text = _str(item).trim();
      if (text.isNotEmpty) out.add(text);
    }
  }
  return out;
}

/// The payload a manage save sends back to `save_recurring_expense`.
///
/// A class rather than a loose map so the field names are written once: the
/// form, the repository and the test all read the same definition, and a typo
/// in one of them is a compile error instead of a field the server silently
/// ignores.
class RecurringExpenseDraft {
  /// Absent for a create, present for an update.
  final String? name;
  final String expenseName;
  final String category;
  final double amount;
  final String frequency;
  final String expenseAccount;
  final int? dayOfMonth;
  final String? costCenter;
  final String? supplier;
  final String? defaultPayingAccount;
  final String? startDate;
  final String? endDate;
  final String? notes;

  const RecurringExpenseDraft({
    this.name,
    required this.expenseName,
    required this.category,
    required this.amount,
    required this.frequency,
    required this.expenseAccount,
    this.dayOfMonth,
    this.costCenter,
    this.supplier,
    this.defaultPayingAccount,
    this.startDate,
    this.endDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        if (name != null && name!.isNotEmpty) 'name': name,
        'expense_name': expenseName,
        'category': category,
        'amount': amount,
        'frequency': frequency,
        'expense_account': expenseAccount,
        if (dayOfMonth != null) 'day_of_month': dayOfMonth,
        if (costCenter != null && costCenter!.isNotEmpty)
          'cost_center': costCenter,
        if (supplier != null && supplier!.isNotEmpty) 'supplier': supplier,
        if (defaultPayingAccount != null && defaultPayingAccount!.isNotEmpty)
          'default_paying_account': defaultPayingAccount,
        if (startDate != null && startDate!.isNotEmpty) 'start_date': startDate,
        if (endDate != null && endDate!.isNotEmpty) 'end_date': endDate,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
