/// Result of `jarz_pos.api.customer.check_customer_duplicates`: existing
/// customers that look like the one about to be created.
///
/// Plain Dart (no Freezed) on purpose: the shape is tiny and read-only, and
/// keeping it out of code generation keeps this change a Dart-only patch.
class CustomerDuplicateCheck {
  const CustomerDuplicateCheck({
    this.matches = const <CustomerDuplicateMatch>[],
    this.nameInvalid = false,
  });

  /// "No matches": what every failure of the check falls back to, so a
  /// missing endpoint, an error or no network never blocks a create.
  static const none = CustomerDuplicateCheck();

  final List<CustomerDuplicateMatch> matches;

  /// The server judged the name not to be a real name (symbols, digits only).
  final bool nameInvalid;

  bool get hasMatches => matches.isNotEmpty;

  factory CustomerDuplicateCheck.fromJson(dynamic raw) {
    if (raw is! Map) return none;
    final list = raw['matches'];
    final matches = list is List
        ? list
              .whereType<Map>()
              .map(
                (m) => CustomerDuplicateMatch.fromJson(
                  Map<String, dynamic>.from(m),
                ),
              )
              .where((m) => m.name.isNotEmpty)
              .toList(growable: false)
        : const <CustomerDuplicateMatch>[];
    final invalid = raw['name_invalid'];
    return CustomerDuplicateCheck(
      matches: matches,
      nameInvalid: invalid == true || invalid == 1 || invalid == '1',
    );
  }
}

/// Why a customer was offered as a possible duplicate (`match_reasons`).
abstract final class CustomerDuplicateReason {
  static const phone = 'phone';
  static const secondaryPhone = 'secondary_phone';
  static const address = 'address';
  static const name = 'name';
}

/// One possible duplicate. [raw] keeps the full row: it carries the same keys
/// as a `search_customers` result, so it can be selected exactly like one.
class CustomerDuplicateMatch {
  const CustomerDuplicateMatch({
    required this.name,
    this.customerName = '',
    this.mobileNo,
    this.primaryAddress,
    this.matchedAddress,
    this.orderCount = 0,
    this.lastOrderDate,
    this.reasons = const <String>[],
    this.raw = const <String, dynamic>{},
  });

  final String name;
  final String customerName;
  final String? mobileNo;
  final String? primaryAddress;
  final String? matchedAddress;
  final int orderCount;
  final String? lastOrderDate;
  final List<String> reasons;
  final Map<String, dynamic> raw;

  /// The address worth showing: the one that matched, else the primary one.
  String? get displayAddress => (matchedAddress?.isNotEmpty ?? false)
      ? matchedAddress
      : ((primaryAddress?.isNotEmpty ?? false) ? primaryAddress : null);

  factory CustomerDuplicateMatch.fromJson(Map<String, dynamic> json) {
    String? str(Object? v) {
      final s = v?.toString().trim() ?? '';
      return s.isEmpty || s == 'null' ? null : s;
    }

    final name = str(json['name']) ?? '';
    final reasons = json['match_reasons'];
    final count = json['order_count'];
    return CustomerDuplicateMatch(
      name: name,
      customerName: str(json['customer_name']) ?? name,
      mobileNo: str(json['mobile_no']) ?? str(json['phone']),
      primaryAddress: str(json['customer_primary_address']),
      matchedAddress: str(json['matched_address']),
      orderCount: count is num
          ? count.toInt()
          : int.tryParse(count?.toString() ?? '') ?? 0,
      lastOrderDate: str(json['last_order_date']),
      reasons: reasons is List
          ? reasons.map((r) => r.toString()).toList(growable: false)
          : const <String>[],
      raw: json,
    );
  }
}
