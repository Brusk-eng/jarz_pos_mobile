/// The per-shift "sheet" that replaces the paper sales sheet.
///
/// Parsing is deliberately tolerant: every field may be missing or typed
/// loosely (numbers as strings, `1`/`true` flags), because the sheet is a
/// read-only view and one odd row must not blank the whole screen.
double _num(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim()) ?? 0;
  return 0;
}

int _int(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? 0;
  return 0;
}

bool _flag(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.trim().toLowerCase();
    return s == '1' || s == 'true';
  }
  return false;
}

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

List<Map<String, dynamic>> _rows(dynamic v) {
  if (v is! List) return const [];
  return v
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
}

List<String> _reasons(dynamic v) {
  if (v is! List) return const ['created'];
  final out = v.map(_str).whereType<String>().toList(growable: false);
  return out.isEmpty ? const ['created'] : out;
}

double? _optNum(dynamic v) {
  if (v == null) return null;
  if (v is String && v.trim().isEmpty) return null;
  if (v is num || v is String) return _num(v);
  return null;
}

DateTime? _date(dynamic v) {
  final s = _str(v);
  if (s == null) return null;
  return DateTime.tryParse(s);
}

class ShiftSheetOrder {
  const ShiftSheetOrder({
    required this.name,
    required this.orderNumber,
    this.createdAt,
    this.jars = 0,
    this.grandTotal = 0,
    this.outstandingAmount = 0,
    this.deliveryFee = 0,
    this.courier,
    this.isPickup = false,
    this.area,
    this.paymentMethod,
    this.state,
    this.channel,
    this.reasons = const ['created'],
    this.outForDeliveryAt,
    this.settledAt,
    this.settledAmount = 0,
    this.shippingExpense,
    this.courierCashIn = 0,
    this.courierFeePaid = 0,
    this.paidAt,
    this.paidAmount = 0,
  });

  factory ShiftSheetOrder.fromJson(Map<String, dynamic> json) {
    final name = _str(json['name']) ?? '';
    return ShiftSheetOrder(
      name: name,
      orderNumber: _str(json['order_number']) ?? name,
      createdAt: _date(json['created_at']),
      jars: _int(json['jars']),
      grandTotal: _num(json['grand_total']),
      outstandingAmount: _num(json['outstanding_amount']),
      deliveryFee: _num(json['delivery_fee']),
      courier: _str(json['courier']),
      isPickup: _flag(json['is_pickup']),
      area: _str(json['area']),
      paymentMethod: _str(json['payment_method']),
      state: _str(json['state']),
      channel: _str(json['channel']),
      reasons: _reasons(json['reasons']),
      outForDeliveryAt: _date(json['out_for_delivery_at']),
      settledAt: _date(json['settled_at']),
      settledAmount: _num(json['settled_amount']),
      shippingExpense: _optNum(json['shipping_expense']),
      courierCashIn: _num(json['courier_cash_in']),
      courierFeePaid: _num(json['courier_fee_paid']),
      paidAt: _date(json['paid_at']),
      paidAmount: _num(json['paid_amount']),
    );
  }

  final String name;
  final String orderNumber;
  final DateTime? createdAt;
  final int jars;
  final double grandTotal;
  final double outstandingAmount;
  final double deliveryFee;
  final String? courier;
  final bool isPickup;
  final String? area;
  final String? paymentMethod;
  final String? state;
  final String? channel;

  /// Why the order is on this sheet: subset of `created`,
  /// `out_for_delivery`, `settled`, `paid`. Current servers list only orders
  /// that touched the drawer, so `created` is an extra tag and never alone.
  /// Old servers omit it, so it defaults to `created`.
  final List<String> reasons;
  final DateTime? outForDeliveryAt;
  final DateTime? settledAt;

  /// Gross order money settled in this shift. Parsed for compatibility but
  /// no longer shown: [courierCashIn] is what actually reached the drawer.
  final double settledAmount;

  /// Courier cost of the order. 0 for pickup and for partner deliveries we
  /// don't pay; null while the order has not gone out yet (or old server).
  final double? shippingExpense;

  /// Cash the courier handed the branch for this order in this shift (order
  /// money minus the courier's fee). Negative when the branch paid the
  /// courier (prepaid order). 0 when not settled in this shift.
  final double courierCashIn;

  /// Courier fee deducted at that settlement.
  final double courierFeePaid;

  /// First time cash for this order reached the branch drawer (till) in this
  /// shift; null when none did (or old server).
  final DateTime? paidAt;

  /// Cash into the drawer for this order in this shift; 0 when none.
  final double paidAmount;

  bool get isNew => reasons.contains('created');
  bool get isOutForDelivery => reasons.contains('out_for_delivery');
  bool get isSettled => reasons.contains('settled');
  bool get isPaidInDrawer => reasons.contains('paid');

  bool get isUnpaid => outstandingAmount > 0;
}

/// An order of the branch whose delivery slot ended before the shift's end
/// (or before now on an open shift) without it going out by then.
class ShiftSheetOverdueOrder {
  const ShiftSheetOverdueOrder({
    required this.name,
    required this.orderNumber,
    this.customerName,
    this.createdAt,
    this.slotStart,
    this.slotEnd,
    this.slotLabel,
    this.deadline,
    this.minutesLate = 0,
    this.state,
    this.isPickup = false,
    this.area,
    this.paymentMethod,
    this.grandTotal = 0,
    this.outstandingAmount = 0,
    this.dueInThisShift = false,
    this.wentOutAt,
  });

  factory ShiftSheetOverdueOrder.fromJson(Map<String, dynamic> json) {
    final name = _str(json['name']) ?? '';
    return ShiftSheetOverdueOrder(
      name: name,
      orderNumber: _str(json['order_number']) ?? name,
      customerName: _str(json['customer_name']),
      createdAt: _date(json['created_at']),
      slotStart: _date(json['slot_start']),
      slotEnd: _date(json['slot_end']),
      slotLabel: _str(json['slot_label']),
      deadline: _date(json['deadline']),
      minutesLate: _int(json['minutes_late']),
      state: _str(json['state']),
      isPickup: _flag(json['is_pickup']),
      area: _str(json['area']),
      paymentMethod: _str(json['payment_method']),
      grandTotal: _num(json['grand_total']),
      outstandingAmount: _num(json['outstanding_amount']),
      dueInThisShift: _flag(json['due_in_this_shift']),
      wentOutAt: _date(json['went_out_at']),
    );
  }

  final String name;
  final String orderNumber;
  final String? customerName;
  final DateTime? createdAt;
  final DateTime? slotStart;
  final DateTime? slotEnd;
  final String? slotLabel;

  /// When the order should have gone out (end of its slot).
  final DateTime? deadline;

  /// How far past [deadline] at the shift end (or now, on an open shift).
  final int minutesLate;
  final String? state;
  final bool isPickup;
  final String? area;
  final String? paymentMethod;
  final double grandTotal;
  final double outstandingAmount;

  /// True when [deadline] fell inside this shift; false when it was due in an
  /// earlier shift and is still carried.
  final bool dueInThisShift;

  /// Set only on a closed shift's sheet, when the order went out after the
  /// shift ended.
  final DateTime? wentOutAt;
}

class ShiftSheetFlavour {
  const ShiftSheetFlavour({
    required this.flavour,
    this.small = 0,
    this.medium = 0,
    this.large = 0,
  });

  factory ShiftSheetFlavour.fromJson(Map<String, dynamic> json) {
    return ShiftSheetFlavour(
      flavour: _str(json['flavour']) ?? '',
      small: _int(json['small']),
      medium: _int(json['medium']),
      large: _int(json['large']),
    );
  }

  final String flavour;
  final int small;
  final int medium;
  final int large;
}

class ShiftSheetPayout {
  const ShiftSheetPayout({
    required this.kind,
    required this.name,
    required this.label,
    this.amount = 0,
    this.status,
    this.at,
  });

  factory ShiftSheetPayout.fromJson(Map<String, dynamic> json) {
    final name = _str(json['name']) ?? '';
    return ShiftSheetPayout(
      kind: _str(json['kind']) ?? 'expense',
      name: name,
      label: _str(json['label']) ?? name,
      amount: _num(json['amount']),
      status: _str(json['status']),
      at: _date(json['at']),
    );
  }

  final String kind;
  final String name;
  final String label;
  final double amount;
  final String? status;
  final DateTime? at;
}

/// A return (credit note) booked in the shift, with where the refund came from.
class ShiftSheetReturn {
  const ShiftSheetReturn({
    required this.creditNote,
    required this.order,
    required this.orderNumber,
    this.amount = 0,
    this.refundAmount = 0,
    this.refundAccount,
    this.refundKind = 'credit',
    this.at,
  });

  factory ShiftSheetReturn.fromJson(Map<String, dynamic> json) {
    final order = _str(json['order']) ?? '';
    return ShiftSheetReturn(
      creditNote: _str(json['credit_note']) ?? '',
      order: order,
      orderNumber: _str(json['order_number']) ?? order,
      amount: _num(json['amount']),
      refundAmount: _num(json['refund_amount']),
      refundAccount: _str(json['refund_account']),
      refundKind: _str(json['refund_kind']) ?? 'credit',
      at: _date(json['at']),
    );
  }

  final String creditNote;
  final String order;
  final String orderNumber;
  final double amount;
  final double refundAmount;
  final String? refundAccount;

  /// `cash`, `bank` or `credit`.
  final String refundKind;
  final DateTime? at;
}

class ShiftSheetTotals {
  const ShiftSheetTotals({
    this.orders = 0,
    this.jars = 0,
    this.grandTotal = 0,
    this.deliveryFees = 0,
    this.payouts = 0,
    this.openingAmount = 0,
    this.expectedClosing,
    this.actualClosing,
    this.difference,
    this.newOrders = 0,
    this.outForDeliveryOrders = 0,
    this.settledOrders = 0,
    this.settledAmount = 0,
    this.returns = 0,
    this.returnsAmount = 0,
    this.cashRefunds = 0,
    this.bankRefunds = 0,
    this.deliveryOrders = 0,
    this.deliveryIncome = 0,
    this.deliveryCost = 0,
    this.deliveryNet = 0,
    this.courierCashIn = 0,
    this.courierFeesPaid = 0,
    this.paidOrders = 0,
    this.paidAmount = 0,
    this.overdueOrders = 0,
  });

  factory ShiftSheetTotals.fromJson(Map<String, dynamic> json) {
    double? opt(dynamic v) => v == null ? null : _num(v);
    return ShiftSheetTotals(
      orders: _int(json['orders']),
      jars: _int(json['jars']),
      grandTotal: _num(json['grand_total']),
      deliveryFees: _num(json['delivery_fees']),
      payouts: _num(json['payouts']),
      openingAmount: _num(json['opening_amount']),
      expectedClosing: opt(json['expected_closing']),
      actualClosing: opt(json['actual_closing']),
      difference: opt(json['difference']),
      newOrders: _int(json['new_orders']),
      outForDeliveryOrders: _int(json['out_for_delivery_orders']),
      settledOrders: _int(json['settled_orders']),
      settledAmount: _num(json['settled_amount']),
      returns: _int(json['returns']),
      returnsAmount: _num(json['returns_amount']),
      cashRefunds: _num(json['cash_refunds']),
      bankRefunds: _num(json['bank_refunds']),
      deliveryOrders: _int(json['delivery_orders']),
      deliveryIncome: _num(json['delivery_income']),
      deliveryCost: _num(json['delivery_cost']),
      deliveryNet: _num(json['delivery_net']),
      courierCashIn: _num(json['courier_cash_in']),
      courierFeesPaid: _num(json['courier_fees_paid']),
      paidOrders: _int(json['paid_orders']),
      paidAmount: _num(json['paid_amount']),
      overdueOrders: _int(json['overdue_orders']),
    );
  }

  final int orders;
  final int jars;
  final double grandTotal;
  final double deliveryFees;
  final double payouts;
  final double openingAmount;
  final double? expectedClosing;
  final double? actualClosing;
  final double? difference;
  final int newOrders;
  final int outForDeliveryOrders;
  final int settledOrders;
  final double settledAmount;
  final int returns;
  final double returnsAmount;
  final double cashRefunds;
  final double bankRefunds;

  /// Orders sent out for delivery in this shift (not pickup).
  final int deliveryOrders;

  /// Delivery charged to customers on [deliveryOrders].
  final double deliveryIncome;

  /// Courier cost of [deliveryOrders].
  final double deliveryCost;

  /// [deliveryIncome] minus [deliveryCost]; negative = delivery ran at a loss.
  final double deliveryNet;
  final double courierCashIn;
  final double courierFeesPaid;

  /// Orders whose cash reached the branch drawer in this shift.
  final int paidOrders;

  /// Cash those [paidOrders] put into the drawer.
  final double paidAmount;

  /// Late orders not sent out (see [ShiftSheet.overdue]).
  final int overdueOrders;
}

/// One voucher behind a cash-drawer movement.
class ShiftSheetCashLine {
  const ShiftSheetCashLine({
    required this.kind,
    this.voucherType,
    this.voucherNo,
    this.label = '',
    this.amount = 0,
    this.at,
  });

  factory ShiftSheetCashLine.fromJson(Map<String, dynamic> json) {
    final voucherNo = _str(json['voucher_no']);
    return ShiftSheetCashLine(
      kind: _str(json['kind']) ?? 'other',
      voucherType: _str(json['voucher_type']),
      voucherNo: voucherNo,
      label: _str(json['label']) ?? voucherNo ?? '',
      amount: _num(json['amount']),
      at: _date(json['at']),
    );
  }

  /// One of [ShiftSheetCashFlow.kinds].
  final String kind;
  final String? voucherType;
  final String? voucherNo;
  final String label;

  /// Signed: money out of the drawer is negative.
  final double amount;
  final DateTime? at;
}

/// How the drawer got from the opening cash to the expected closing cash.
///
/// Manager-only; null for staff and on servers that predate it. Signs are
/// applied by the server and `opening + every kind == expected`.
class ShiftSheetCashFlow {
  const ShiftSheetCashFlow({
    this.opening = 0,
    this.salesCash = 0,
    this.courierOrders = 0,
    this.courierFees = 0,
    this.expenses = 0,
    this.refunds = 0,
    this.handovers = 0,
    this.other = 0,
    this.expected = 0,
    this.counted,
    this.difference,
    this.isOpen = false,
    this.lines = const [],
  });

  factory ShiftSheetCashFlow.fromJson(Map<String, dynamic> json) {
    return ShiftSheetCashFlow(
      opening: _num(json['opening']),
      salesCash: _num(json['sales_cash']),
      courierOrders: _num(json['courier_orders']),
      courierFees: _num(json['courier_fees']),
      expenses: _num(json['expenses']),
      refunds: _num(json['refunds']),
      handovers: _num(json['handovers']),
      other: _num(json['other']),
      expected: _num(json['expected']),
      counted: _optNum(json['counted']),
      difference: _optNum(json['difference']),
      isOpen: _flag(json['is_open']),
      lines: _rows(json['lines']).map(ShiftSheetCashLine.fromJson).toList(),
    );
  }

  /// Movement kinds in display order.
  static const kinds = <String>[
    'sales_cash',
    'courier_orders',
    'courier_fees',
    'expenses',
    'refunds',
    'handovers',
    'other',
  ];

  final double opening;
  final double salesCash;
  final double courierOrders;
  final double courierFees;
  final double expenses;
  final double refunds;
  final double handovers;
  final double other;
  final double expected;
  final double? counted;
  final double? difference;
  final bool isOpen;
  final List<ShiftSheetCashLine> lines;

  double amountOf(String kind) => switch (kind) {
    'sales_cash' => salesCash,
    'courier_orders' => courierOrders,
    'courier_fees' => courierFees,
    'expenses' => expenses,
    'refunds' => refunds,
    'handovers' => handovers,
    _ => other,
  };

  List<ShiftSheetCashLine> linesOf(String kind) =>
      lines.where((l) => l.kind == kind).toList(growable: false);
}

class ShiftSheet {
  const ShiftSheet({
    required this.openingEntry,
    this.closingEntry,
    this.posProfile = '',
    this.branchLabel = '',
    this.user = '',
    this.userFullName = '',
    this.openedAt,
    this.closedAt,
    this.isOpen = false,
    this.isManagerView = false,
    this.amountsHidden = true,
    this.orders = const [],
    this.jarsByFlavour = const [],
    this.payouts = const [],
    this.returns = const [],
    this.overdue = const [],
    this.totals,
    this.cashFlow,
  });

  factory ShiftSheet.fromJson(Map<String, dynamic> json) {
    final totalsRaw = json['totals'];
    final cashFlowRaw = json['cash_flow'];
    return ShiftSheet(
      openingEntry: _str(json['opening_entry']) ?? '',
      closingEntry: _str(json['closing_entry']),
      posProfile: _str(json['pos_profile']) ?? '',
      branchLabel: _str(json['branch_label']) ?? '',
      user: _str(json['user']) ?? '',
      userFullName: _str(json['user_full_name']) ?? '',
      openedAt: _date(json['opened_at']),
      closedAt: _date(json['closed_at']),
      isOpen: _flag(json['is_open']),
      isManagerView: _flag(json['is_manager_view']),
      // Hidden unless the server says otherwise: failing closed keeps the
      // blind count blind if the field ever goes missing.
      amountsHidden: json.containsKey('amounts_hidden')
          ? _flag(json['amounts_hidden'])
          : true,
      orders: _rows(json['orders']).map(ShiftSheetOrder.fromJson).toList(),
      jarsByFlavour: _rows(
        json['jars_by_flavour'],
      ).map(ShiftSheetFlavour.fromJson).toList(),
      payouts: _rows(json['payouts']).map(ShiftSheetPayout.fromJson).toList(),
      returns: _rows(json['returns']).map(ShiftSheetReturn.fromJson).toList(),
      overdue: _rows(
        json['overdue'],
      ).map(ShiftSheetOverdueOrder.fromJson).toList(),
      totals: totalsRaw is Map
          ? ShiftSheetTotals.fromJson(Map<String, dynamic>.from(totalsRaw))
          : null,
      cashFlow: cashFlowRaw is Map
          ? ShiftSheetCashFlow.fromJson(Map<String, dynamic>.from(cashFlowRaw))
          : null,
    );
  }

  final String openingEntry;
  final String? closingEntry;
  final String posProfile;
  final String branchLabel;
  final String user;
  final String userFullName;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final bool isOpen;
  final bool isManagerView;
  final bool amountsHidden;
  final List<ShiftSheetOrder> orders;
  final List<ShiftSheetFlavour> jarsByFlavour;
  final List<ShiftSheetPayout> payouts;
  final List<ShiftSheetReturn> returns;

  /// Late orders not sent out, deadline ascending; empty on old servers.
  final List<ShiftSheetOverdueOrder> overdue;
  final ShiftSheetTotals? totals;

  /// Manager-only drawer waterfall; null for staff and older servers.
  final ShiftSheetCashFlow? cashFlow;

  String get staffLabel => userFullName.isNotEmpty ? userFullName : user;
  String get branchDisplay => branchLabel.isNotEmpty ? branchLabel : posProfile;
}
