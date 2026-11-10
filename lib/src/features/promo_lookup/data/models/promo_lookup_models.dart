// Promo code lookup: the payloads of `jarz_pos.api.promo.lookup_promo_code`
// (one code) and `jarz_pos.api.promo.lookup_customer_promos` (one customer's
// codes; each `CodeSummary` parses into the same [PromoLookupResult]).
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

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is String && value.trim().isEmpty) return null;
  return _double(value);
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
    this.notPermitted = false,
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
    this.waivedDelivery = 0,
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
      notPermitted: error == 'not_permitted',
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
      waivedDelivery: _double(json['waived_delivery']),
      accepted: _bool(json['accepted']),
      reason: _nullableString(json['reason']),
      discountAmount: _double(json['discount_amount']),
      freeDelivery: _bool(json['free_delivery']),
      newTotal: _double(json['new_total']),
    );
  }

  final bool orderNotFound;

  /// The order exists but the user may not read it (no Sales Invoice read
  /// permission, or another branch's order).
  final bool notPermitted;

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

  /// Delivery fee a current Free Delivery code already took off the order;
  /// the new total puts it back when this code replaces the current ones.
  final double waivedDelivery;
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
    this.personal = false,
    this.customerTimesUsed = 0,
    this.customerRemainingUses,
  });

  /// One `CodeSummary` from `lookup_customer_promos`: the same code shape
  /// without `found` (a summary is always a real code) and with the
  /// per-customer counters.
  factory PromoLookupResult.fromCodeSummary(dynamic raw) =>
      PromoLookupResult.fromJson({..._map(raw), 'found': true});

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
      personal: _bool(json['personal']),
      customerTimesUsed: _int(json['customer_times_used']),
      customerRemainingUses: _nullableInt(json['customer_remaining_uses']),
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

  /// Customer lookup only: the code is locked to a customer or phone.
  final bool personal;

  /// Customer lookup only: Active redemptions by the customer looked up.
  final int customerTimesUsed;

  /// Customer lookup only: uses this customer has left; null = unlimited
  /// (or not sent).
  final int? customerRemainingUses;

  bool get isActive => status == PromoStatus.active;
  bool get isUnlimited => usageLimit <= 0;
  bool get hasCap => maxDiscountAmount > 0;
  bool get isLockedToCustomer =>
      customer != null || customerName != null || customerPhone != null;

  /// How many more times the looked-up customer can use the code: the
  /// smaller of their own allowance and what is left overall. Null when
  /// neither is limited.
  int? get usesLeftForCustomer {
    final own = customerRemainingUses;
    final overall = remainingUses;
    if (own == null) return overall;
    if (overall == null) return own;
    return own < overall ? own : overall;
  }
}

/// `lookup_customer_promos` match mode.
enum CustomerPromoMatchType {
  phone('phone'),
  name('name'),
  unknown('');

  const CustomerPromoMatchType(this.wire);
  final String wire;

  static CustomerPromoMatchType fromWire(dynamic value) {
    final text = _string(value).trim().toLowerCase();
    for (final type in values) {
      if (type != unknown && type.wire == text) return type;
    }
    return unknown;
  }
}

/// One redemption of a promo code by the customer looked up (`UseRow`).
class PromoUse {
  const PromoUse({
    required this.code,
    required this.invoice,
    this.wooOrderId,
    this.date,
    this.status = '',
    this.discount = 0,
    this.orderTotal,
  });

  factory PromoUse.fromJson(Map<String, dynamic> json) => PromoUse(
    code: _string(json['code']),
    invoice: _string(json['invoice']),
    wooOrderId: _nullableInt(json['woo_order_id']),
    date: _nullableString(json['date']),
    status: _string(json['status']),
    discount: _double(json['discount']),
    orderTotal: _nullableDouble(json['order_total']),
  );

  final String code;
  final String invoice;
  final int? wooOrderId;
  final String? date;

  /// `Active` or `Reversed`.
  final String status;

  /// What the code took off that order.
  final double discount;

  /// The invoice grand total, when the invoice was found.
  final double? orderTotal;

  bool get isReversed => status.trim().toLowerCase() == 'reversed';
}

/// One customer matched by the lookup, with their codes and past uses.
/// [customer] is null for a phone-only entry (a personal code locked to a
/// phone that no Customer owns).
class CustomerPromoEntry {
  const CustomerPromoEntry({
    this.customer,
    this.customerName,
    this.phone,
    this.orderCount = 0,
    this.lastOrderDate,
    this.lastWooOrderId,
    this.activeCodes = const [],
    this.publicCodes = const [],
    this.inactiveCodes = const [],
    this.usedCodes = const [],
  });

  factory CustomerPromoEntry.fromJson(Map<String, dynamic> json) =>
      CustomerPromoEntry(
        customer: _nullableString(json['customer']),
        customerName: _nullableString(json['customer_name']),
        phone: _nullableString(json['phone']),
        orderCount: _int(json['order_count']),
        lastOrderDate: _nullableString(json['last_order_date']),
        lastWooOrderId: _nullableInt(json['last_woo_order_id']),
        activeCodes: _codeList(json['active_codes']),
        publicCodes: _codeList(json['public_codes']),
        inactiveCodes: _codeList(json['inactive_codes']),
        usedCodes: [
          for (final use in _mapList(json['used_codes']))
            PromoUse.fromJson(use),
        ],
      );

  static List<PromoLookupResult> _codeList(dynamic value) => [
    for (final code in _mapList(value)) PromoLookupResult.fromCodeSummary(code),
  ];

  /// Customer docname; null for a phone-only entry.
  final String? customer;
  final String? customerName;
  final String? phone;
  final int orderCount;
  final String? lastOrderDate;
  final int? lastWooOrderId;

  /// Personal codes that are active or not started yet.
  final List<PromoLookupResult> activeCodes;

  /// Codes open to everyone that this customer can still use.
  final List<PromoLookupResult> publicCodes;

  /// Personal codes that expired, were used up or were disabled.
  final List<PromoLookupResult> inactiveCodes;
  final List<PromoUse> usedCodes;

  bool get isPhoneOnly => customer == null;

  /// What to call the entry: name, else docname, else the phone.
  String get displayName => customerName ?? customer ?? phone ?? '';
}

/// The whole `lookup_customer_promos` answer.
class CustomerPromoLookup {
  const CustomerPromoLookup({
    required this.query,
    this.matchType = CustomerPromoMatchType.unknown,
    this.truncated = false,
    this.customers = const [],
  });

  factory CustomerPromoLookup.fromJson(dynamic raw) {
    final json = _map(raw);
    return CustomerPromoLookup(
      query: _string(json['query']),
      matchType: CustomerPromoMatchType.fromWire(json['match_type']),
      truncated: _bool(json['truncated']),
      customers: [
        for (final entry in _mapList(json['customers']))
          CustomerPromoEntry.fromJson(entry),
      ],
    );
  }

  final String query;
  final CustomerPromoMatchType matchType;

  /// More customers matched than were sent (the server caps at 10).
  final bool truncated;
  final List<CustomerPromoEntry> customers;
}
