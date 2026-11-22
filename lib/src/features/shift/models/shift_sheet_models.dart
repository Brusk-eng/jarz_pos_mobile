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

  bool get isUnpaid => outstandingAmount > 0;
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
    this.totals,
  });

  factory ShiftSheet.fromJson(Map<String, dynamic> json) {
    final totalsRaw = json['totals'];
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
      amountsHidden:
          json.containsKey('amounts_hidden') ? _flag(json['amounts_hidden']) : true,
      orders: _rows(json['orders']).map(ShiftSheetOrder.fromJson).toList(),
      jarsByFlavour:
          _rows(json['jars_by_flavour']).map(ShiftSheetFlavour.fromJson).toList(),
      payouts: _rows(json['payouts']).map(ShiftSheetPayout.fromJson).toList(),
      totals: totalsRaw is Map
          ? ShiftSheetTotals.fromJson(Map<String, dynamic>.from(totalsRaw))
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
  final ShiftSheetTotals? totals;

  String get staffLabel => userFullName.isNotEmpty ? userFullName : user;
  String get branchDisplay => branchLabel.isNotEmpty ? branchLabel : posProfile;
}
