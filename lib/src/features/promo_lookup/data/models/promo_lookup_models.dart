// Promo code lookup: the payload of `jarz_pos.api.promo.lookup_promo_code`.
//
// Plain classes with hand-written, defensive `fromJson` (the same loose
// parsing the follow-ups and reports features use): Frappe sends numbers as
// int or double, flags as bool or 0/1, and leaves keys out when they are
// empty. Unknown keys are ignored and unknown enum values fall back to
// `unknown` rather than throwing.

int _int(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is bool) return value ? 1 : 0;
  if (value is num) return value.toInt();
  final text = value.toString().trim();
  if (text.isEmpty) return fallback;
  final lower = text.toLowerCase();
  if (lower == 'true') return 1;
  if (lower == 'false') return 0;
  return int.tryParse(text) ?? double.tryParse(text)?.toInt() ?? fallback;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is String && value.trim().isEmpty) return null;
  return _int(value);
}

double _double(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is bool) return value ? 1 : 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim()) ?? fallback;
}

bool _bool(dynamic value) => _int(value) != 0;

String _string(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return {for (final e in value.entries) e.key.toString(): e.value};
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map) _map(item),
  ];
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item != null && item.toString().trim().isNotEmpty)
        item.toString().trim(),
  ];
}

/// Where the code stands today, as the server judges it.
enum PromoStatus {
  active('active'),
  disabled('disabled'),
  notStarted('not_started'),
  expired('expired'),
  usedUp('used_up'),
  unknown('');

  const PromoStatus(this.wire);
  final String wire;

  static PromoStatus fromWire(dynamic value) {
    final text = _string(value).trim().toLowerCase();
    for (final status in values) {
      if (status != unknown && status.wire == text) return status;
    }
    return unknown;
  }
}

enum PromoDiscountType {
  percentage('Percentage'),
  fixedAmount('Fixed Amount'),
  freeDelivery('Free Delivery'),
  unknown('');

  const PromoDiscountType(this.wire);
  final String wire;

  static PromoDiscountType fromWire(dynamic value) {
    final text = _string(value).trim().toLowerCase();
    for (final type in values) {
      if (type != unknown && type.wire.toLowerCase() == text) return type;
    }
    return unknown;
  }
}

enum PromoAppliesTo {
  wholeOrder('Whole Order'),
  specificItems('Specific Items'),
  itemGroups('Item Groups'),
  unknown('');

  const PromoAppliesTo(this.wire);
  final String wire;

  static PromoAppliesTo fromWire(dynamic value) {
    final text = _string(value).trim().toLowerCase();
    if (text.isEmpty) return wholeOrder;
    for (final target in values) {
      if (target != unknown && target.wire.toLowerCase() == text) {
        return target;
      }
    }
    return unknown;
  }
}

/// One item or item group the code is limited to.
class PromoScopeEntry {
  const PromoScopeEntry({
    required this.type,
    required this.name,
    required this.label,
  });

  factory PromoScopeEntry.fromJson(Map<String, dynamic> json) {
    final name = _string(json['name']);
    return PromoScopeEntry(
      type: _string(json['type']),
      name: name,
      label: _nullableString(json['label']) ?? name,
    );
  }

  /// `Item` or `Item Group`.
  final String type;
  final String name;

  /// What to show; falls back to [name].
  final String label;

  bool get isItemGroup => type.trim().toLowerCase() == 'item group';
}

/// One invoice the code was used on.
class PromoRecentUse {
  const PromoRecentUse({
    required this.invoice,
    this.wooOrderId,
    this.customerName,
    this.date,
    this.status = '',
  });

  factory PromoRecentUse.fromJson(Map<String, dynamic> json) => PromoRecentUse(
    invoice: _string(json['invoice']),
    wooOrderId: _nullableInt(json['woo_order_id']),
    customerName: _nullableString(json['customer_name']),
    date: _nullableString(json['date']),
    status: _string(json['status']),
  );

  final String invoice;
  final int? wooOrderId;
  final String? customerName;
  final String? date;

  /// `Active` or `Reversed`.
  final String status;

  bool get isReversed => status.trim().toLowerCase() == 'reversed';
}

/// The code tried against one order. Either [orderNotFound] (with the
/// [order] the user typed) or the full evaluation.
class PromoOrderCheck {
  const PromoOrderCheck({
    this.orderNotFound = false,
    this.error,
    this.order,
    this.invoice = '',
    this.wooOrderId,
    this.customerName,
    this.docstatus = 0,
    this.invoiceStatus = '',
    this.currentTotal = 0,
    this.currentCodes = const [],
    this.currentPromoDiscount = 0,
    this.deliveryAmount = 0,
    this.accepted = false,
    this.reason,
    this.discountAmount = 0,
    this.freeDelivery = false,
    this.newTotal = 0,
  });

  factory PromoOrderCheck.fromJson(Map<String, dynamic> json) {
    final error = _nullableString(json['error']);
    return PromoOrderCheck(
      orderNotFound: error == 'order_not_found',
      error: error,
      order: _nullableString(json['order']),
      invoice: _string(json['invoice']),
      wooOrderId: _nullableInt(json['woo_order_id']),
      customerName: _nullableString(json['customer_name']),
      docstatus: _int(json['docstatus']),
      invoiceStatus: _string(json['invoice_status']),
      currentTotal: _double(json['current_total']),
      currentCodes: _stringList(json['current_codes']),
      currentPromoDiscount: _double(json['current_promo_discount']),
      deliveryAmount: _double(json['delivery_amount']),
      accepted: _bool(json['accepted']),
      reason: _nullableString(json['reason']),
      discountAmount: _double(json['discount_amount']),
      freeDelivery: _bool(json['free_delivery']),
      newTotal: _double(json['new_total']),
    );
  }

  final bool orderNotFound;

  /// Any `error` the server sent; [orderNotFound] is the one it documents.
  final String? error;

  /// The order reference the user typed (only sent with an error).
  final String? order;

  final String invoice;
  final int? wooOrderId;
  final String? customerName;
  final int docstatus;
  final String invoiceStatus;
  final double currentTotal;
  final List<String> currentCodes;
  final double currentPromoDiscount;
  final double deliveryAmount;
  final bool accepted;

  /// English engine text explaining a refusal; shown as-is.
  final String? reason;
  final double discountAmount;
  final bool freeDelivery;
  final double newTotal;

  bool get hasError => error != null;
}

/// The whole lookup answer.
class PromoLookupResult {
  const PromoLookupResult({
    required this.found,
    required this.code,
    this.title,
    this.description,
    this.status = PromoStatus.unknown,
    this.rawStatus = '',
    this.discountType = PromoDiscountType.unknown,
    this.discountValue = 0,
    this.maxDiscountAmount = 0,
    this.minOrderAmount = 0,
    this.minOnWholeOrder = false,
    this.appliesTo = PromoAppliesTo.wholeOrder,
    this.scope = const [],
    this.channels = const [],
    this.allowPickup = false,
    this.stackable = false,
    this.usageLimit = 0,
    this.timesUsed = 0,
    this.remainingUses,
    this.perCustomerLimit = 0,
    this.activeFrom,
    this.activeTo,
    this.customer,
    this.customerName,
    this.customerPhone,
    this.wooCouponCode,
    this.onWebsite = false,
    this.recentUses = const [],
    this.orderCheck,
  });

  factory PromoLookupResult.fromJson(dynamic raw) {
    final json = _map(raw);
    final orderCheckRaw = json['order_check'];
    return PromoLookupResult(
      found: _bool(json['found']),
      code: _string(json['code']),
      title: _nullableString(json['title']),
      description: _nullableString(json['description']),
      status: PromoStatus.fromWire(json['status']),
      rawStatus: _string(json['status']),
      discountType: PromoDiscountType.fromWire(json['discount_type']),
      discountValue: _double(json['discount_value']),
      maxDiscountAmount: _double(json['max_discount_amount']),
      minOrderAmount: _double(json['min_order_amount']),
      minOnWholeOrder: _bool(json['min_on_whole_order']),
      appliesTo: PromoAppliesTo.fromWire(json['applies_to']),
      scope: [
        for (final entry in _mapList(json['scope']))
          PromoScopeEntry.fromJson(entry),
      ],
      channels: _stringList(json['channels']),
      allowPickup: _bool(json['allow_pickup']),
      stackable: _bool(json['stackable']),
      usageLimit: _int(json['usage_limit']),
      timesUsed: _int(json['times_used']),
      remainingUses: _nullableInt(json['remaining_uses']),
      perCustomerLimit: _int(json['per_customer_limit']),
      activeFrom: _nullableString(json['active_from']),
      activeTo: _nullableString(json['active_to']),
      customer: _nullableString(json['customer']),
      customerName: _nullableString(json['customer_name']),
      customerPhone: _nullableString(json['customer_phone']),
      wooCouponCode: _nullableString(json['woo_coupon_code']),
      onWebsite: _bool(json['on_website']),
      recentUses: [
        for (final use in _mapList(json['recent_uses']))
          PromoRecentUse.fromJson(use),
      ],
      orderCheck: orderCheckRaw is Map
          ? PromoOrderCheck.fromJson(_map(orderCheckRaw))
          : null,
    );
  }

  final bool found;
  final String code;
  final String? title;
  final String? description;
  final PromoStatus status;

  /// The status string as sent, for an unknown [status].
  final String rawStatus;
  final PromoDiscountType discountType;
  final double discountValue;

  /// 0 means no cap.
  final double maxDiscountAmount;
  final double minOrderAmount;

  /// True: the minimum counts the whole order; false: only eligible items.
  final bool minOnWholeOrder;
  final PromoAppliesTo appliesTo;
  final List<PromoScopeEntry> scope;

  /// Empty means every channel.
  final List<String> channels;
  final bool allowPickup;
  final bool stackable;

  /// 0 means unlimited.
  final int usageLimit;
  final int timesUsed;

  /// Null when [usageLimit] is unlimited.
  final int? remainingUses;

  /// 0 means unlimited.
  final int perCustomerLimit;
  final String? activeFrom;
  final String? activeTo;
  final String? customer;
  final String? customerName;
  final String? customerPhone;
  final String? wooCouponCode;
  final bool onWebsite;
  final List<PromoRecentUse> recentUses;
  final PromoOrderCheck? orderCheck;

  bool get isActive => status == PromoStatus.active;
  bool get isUnlimited => usageLimit <= 0;
  bool get hasCap => maxDiscountAmount > 0;
  bool get isLockedToCustomer =>
      customer != null || customerName != null || customerPhone != null;
}
