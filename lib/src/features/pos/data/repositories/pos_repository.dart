import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/frappe_error_message.dart';
import '../../../../core/network/frappe_exc_type.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/territory_label.dart';
import '../../domain/models/delivery_slot.dart';
import '../models/customer_duplicate_models.dart';
import '../models/pos_models.dart';

/// Set on an amendment cart line built from a draft whose server reply carried
/// `amendment_line_rates`: that line already holds the source's custom price, or
/// was reset to list on purpose. Never sent as an item field; it only decides
/// whether the request says `keep_source_line_pricing: 0`.
const amendmentPricingCarriedKey = 'amendment_pricing_carried';

/// The server refused an order edit.
///
/// `submit_invoice_amendment` refuses with HTTP 200 and
/// `{success: false, error, amendment_block_code}`, not with an error status.
/// The app used to read that reply as a success, so it deleted the draft,
/// cleared the cart and told staff the edit had gone through when nothing had
/// changed (Woo #17862, three times on 2026-10-06).
class AmendmentRejectedException implements Exception {
  const AmendmentRejectedException(
    this.message, {
    this.blockCode,
    this.requestId,
    this.hasServerReason = true,
  });

  /// Fallback text when the server gave no reason.
  static const defaultMessage = 'The order was not edited.';

  /// The server's own explanation, or [defaultMessage].
  final String message;

  /// `amendment_block_code` (`invoice_locked`, `stale_source`, ...), if any.
  final String? blockCode;

  /// The server's `request_id`, for matching the refusal to its server log.
  final String? requestId;

  /// False when [message] is the client-side [defaultMessage].
  final bool hasServerReason;

  @override
  String toString() => message;
}

/// The server refused to book a delivery order because its address has no map
/// pin (`exc_type: AddressPinRequired`, setting `require_address_pin_for_delivery`).
///
/// A typed error rather than a message string so the cart can send staff to the
/// pin field instead of showing a generic failure.
class AddressPinRequiredException implements Exception {
  const AddressPinRequiredException([this.message = defaultMessage]);

  /// `exc_type` the backend raises.
  static const excType = 'AddressPinRequired';

  static const defaultMessage = 'Delivery orders need a map pin on the address.';

  final String message;

  @override
  String toString() => message;
}

/// Returns [reply] (the `message` of a `submit_invoice_amendment` response) if
/// it reports a completed edit; throws [AmendmentRejectedException] otherwise.
///
/// Success means `success: true`. A reply with no `success` key at all is
/// accepted only if it names the replacement invoice. Anything else, including
/// `success: false`, is a refusal.
Map<String, dynamic> requireCompletedAmendment(Object? reply) {
  if (reply is! Map) {
    throw const AmendmentRejectedException(
      AmendmentRejectedException.defaultMessage,
      hasServerReason: false,
    );
  }
  final map = Map<String, dynamic>.from(reply);
  final success = map['success'];
  if (success == true) return map;

  String? text(Object? value) {
    final s = value?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  final hasInvoicePayload =
      map['invoice'] is Map ||
      text(map['replacement_invoice_id']) != null ||
      text(map['invoice_name']) != null ||
      text(map['name']) != null;
  if (success == null && hasInvoicePayload) return map;

  final reason = text(map['error']) ?? text(map['message']);
  throw AmendmentRejectedException(
    reason ?? AmendmentRejectedException.defaultMessage,
    blockCode: text(map['amendment_block_code']),
    requestId: text(map['request_id']),
    hasServerReason: reason != null,
  );
}

/// Price-list option key naming the order purposes a list is reserved for.
const reservedForPurposesKey = 'reserved_for_purposes';

/// Lenient parse of `reserved_for_purposes`: anything but a list (null, a
/// string, a map) means "reserved for nobody"; blank entries are dropped.
List<String> parseReservedForPurposes(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .map((entry) => entry?.toString().trim() ?? '')
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

class B2bPricingContext {
  B2bPricingContext({
    required this.profile,
    required this.customer,
    required this.orderPurpose,
    required this.commercialPolicy,
    required this.priceList,
  });

  final String profile;
  final String customer;
  final String orderPurpose;
  final CommercialPolicy commercialPolicy;
  final Map<String, dynamic> priceList;
}

class PosRepository {
  PosRepository(this._dio);

  final Dio _dio;
  static const _policyDiscountMarker = '_policy_discount_percentage';

  bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }

    final normalized = value?.toString().trim().toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'y';
  }

  bool _isExplicitlyDisabled(Map<String, dynamic> data) {
    const disabledKeys = ['disabled', 'is_disabled', 'enabled'];

    for (final key in disabledKeys) {
      if (!data.containsKey(key)) {
        continue;
      }

      final value = data[key];
      if (key == 'enabled') {
        return !_asBool(value);
      }
      return _asBool(value);
    }

    return false;
  }

  String _stringValue(Map<String, dynamic> data, String key) {
    return (data[key] ?? '').toString().trim();
  }

  String _firstNonEmptyString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = _stringValue(data, key);
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value == null) {
      return null;
    }

    return double.tryParse(value.toString().trim());
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value == null) {
      return null;
    }

    return int.tryParse(value.toString().trim()) ??
        double.tryParse(value.toString().trim())?.toInt();
  }

  String? _normalizedOptionalString(dynamic value) {
    final normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  Map<String, dynamic>? _normalizedBundleItem(Map<String, dynamic> rawItem) {
    if (_isExplicitlyDisabled(rawItem)) {
      return null;
    }

    final item = Map<String, dynamic>.from(rawItem);
    final itemId = _firstNonEmptyString(item, const ['id', 'item_code']);
    final itemName = _firstNonEmptyString(item, const [
      'name',
      'item_name',
      'title',
    ]);

    item['id'] = itemId;
    item['name'] = itemName;

    final price = _asDouble(
      item['price'] ?? item['rate'] ?? item['price_list_rate'],
    );
    if (price != null) {
      item['price'] = price;
    }

    final stockQty = _asDouble(
      item['qty'] ??
          item['actual_qty'] ??
          item['stock_qty'] ??
          item['available_qty'],
    );
    if (stockQty != null) {
      item['qty'] = stockQty;
      item['actual_qty'] = stockQty;
    }

    item['allow_negative_stock'] = _asBool(item['allow_negative_stock']);

    if (!_hasUsableItemIdentity(item)) {
      return null;
    }

    return item;
  }

  bool _hasUsableItemIdentity(Map<String, dynamic> item) {
    return _stringValue(item, 'id').isNotEmpty &&
        _stringValue(item, 'name').isNotEmpty;
  }

  bool _hasUsableBundleIdentity(Map<String, dynamic> bundle) {
    return _stringValue(bundle, 'id').isNotEmpty &&
        _stringValue(bundle, 'name').isNotEmpty;
  }

  String _normalizedBundleGroupKey(
    Map<String, dynamic> group,
    String groupName,
    int fallbackIndex,
  ) {
    final explicitKey = _firstNonEmptyString(group, const [
      'group_key',
      'group_id',
      'name',
    ]);
    if (explicitKey.isNotEmpty) {
      return explicitKey;
    }

    final rawIndex =
        _asInt(group['group_index'] ?? group['idx']) ?? fallbackIndex;
    return '$groupName::$rawIndex';
  }

  List<Map<String, dynamic>> _normalizedBundleGroups(
    Map<String, dynamic> bundle,
  ) {
    final rawGroups = bundle['item_groups'];
    if (rawGroups is! List) {
      return const [];
    }

    final normalizedGroups = <Map<String, dynamic>>[];
    var fallbackIndex = 1;
    for (final rawGroup in rawGroups) {
      if (rawGroup is! Map) {
        continue;
      }

      final group = Map<String, dynamic>.from(rawGroup);
      final groupName = _firstNonEmptyString(group, const [
        'group_name',
        'item_group',
        'title',
      ]);
      if (groupName.isEmpty) {
        continue;
      }

      final rawQuantity = _asInt(
        group['quantity'] ?? group['required_quantity'],
      );
      if (rawQuantity != null && rawQuantity <= 0) {
        continue;
      }
      final quantity = rawQuantity ?? 1;

      final rawItems = group['items'] ?? group['bundle_items'];
      if (rawItems is! List) {
        continue;
      }

      final validItems = <Map<String, dynamic>>[];
      for (final rawItem in rawItems) {
        if (rawItem is! Map) {
          continue;
        }

        final item = _normalizedBundleItem(Map<String, dynamic>.from(rawItem));
        if (item == null) {
          continue;
        }
        validItems.add(item);
      }

      if (validItems.isEmpty) {
        continue;
      }

      final groupKey = _normalizedBundleGroupKey(
        group,
        groupName,
        fallbackIndex,
      );
      final groupIndex =
          _asInt(group['group_index'] ?? group['idx']) ?? fallbackIndex;

      group['group_name'] = groupName;
      group['group_key'] = groupKey;
      group['group_index'] = groupIndex;
      group['quantity'] = quantity;
      group['items'] = validItems;
      normalizedGroups.add(group);
      fallbackIndex += 1;
    }

    return normalizedGroups;
  }

  Future<List<Map<String, dynamic>>> getPosProfiles() async {
    try {
      final response = await _dio.post(ApiEndpoints.getPosProfiles);

      if (response.statusCode == 200 && response.data['message'] != null) {
        final List<dynamic> profilesData = response.data['message'];

        // Convert profile names/objects to profile objects with basic info
        List<Map<String, dynamic>> profiles = [];
        for (final item in profilesData) {
          if (item is String) {
            // Legacy format: just a name string
            profiles.add({'name': item, 'title': item});
          } else if (item is Map) {
            // New format: {name, allow_delivery_partner, ...}
            final name = (item['name'] ?? '').toString();
            profiles.add({
              'name': name,
              'title': name,
              'allow_delivery_partner': item['allow_delivery_partner'] == true,
            });
          }
        }
        return profiles;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch POS profiles: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getBundles(
    String posProfile, {
    String? priceList,
    String? customer,
    String? orderPurpose,
  }) async {
    final hasB2bContext = customer != null || orderPurpose != null;
    final normalizedCustomer = _normalizedOptionalString(customer);
    final normalizedPurpose = _normalizedOptionalString(orderPurpose);
    if (hasB2bContext &&
        (normalizedCustomer == null || normalizedPurpose == null)) {
      throw ArgumentError(
        'Both customer and orderPurpose are required for a B2B catalog.',
      );
    }
    try {
      final response = await _dio.post(
        ApiEndpoints.getProfileBundles,
        data: {
          'profile': posProfile,
          if (_normalizedOptionalString(priceList) case final value?)
            'price_list': value,
          if (hasB2bContext) 'customer': normalizedCustomer,
          if (hasB2bContext) 'order_purpose': normalizedPurpose,
        },
      );

      if (response.statusCode == 200 && response.data['message'] != null) {
        final List<dynamic> bundlesData = response.data['message'];
        return bundlesData
            .whereType<Map>()
            .map((raw) {
              final bundle = Map<String, dynamic>.from(raw);
              if (_isExplicitlyDisabled(bundle) ||
                  !_hasUsableBundleIdentity(bundle)) {
                return null;
              }

              final itemGroups = _normalizedBundleGroups(bundle);
              if (itemGroups.isEmpty) {
                return null;
              }

              final bundleRate =
                  _asDouble(
                    bundle['price'] ??
                        bundle['price_list_rate'] ??
                        bundle['rate'],
                  ) ??
                  0.0;
              bundle['free_shipping'] = _asBool(bundle['free_shipping']);
              bundle['price'] = bundleRate;
              bundle['price_list_rate'] =
                  _asDouble(bundle['price_list_rate'] ?? bundle['price']) ??
                  bundleRate;
              bundle['price_list'] =
                  _normalizedOptionalString(bundle['price_list']) ??
                  _normalizedOptionalString(priceList);
              bundle['item_groups'] = itemGroups;
              return bundle;
            })
            .whereType<Map<String, dynamic>>()
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch bundles: $e');
    }
  }

  Future<Map<String, dynamic>> getPosProfileAccountBalance(
    String posProfile,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.getPosProfileAccountBalance,
        data: {'profile': posProfile},
      );

      if (response.statusCode == 200 && response.data['message'] != null) {
        return Map<String, dynamic>.from(response.data['message'] as Map);
      }
      throw Exception('Failed to fetch POS account balance');
    } catch (e) {
      throw Exception('Failed to fetch POS account balance: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTerritories({String? search}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.getTerritories,
        data: search != null ? {'search': search} : {},
      );

      if (response.statusCode == 200 && response.data['message'] != null) {
        final List<dynamic> territoriesData = response.data['message'];
        return selectableTerritories(
          territoriesData.cast<Map<String, dynamic>>(),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch territories: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getItems(
    String posProfile, {
    String? priceList,
    String? customer,
    String? orderPurpose,
  }) async {
    final hasB2bContext = customer != null || orderPurpose != null;
    final normalizedCustomer = _normalizedOptionalString(customer);
    final normalizedPurpose = _normalizedOptionalString(orderPurpose);
    if (hasB2bContext &&
        (normalizedCustomer == null || normalizedPurpose == null)) {
      throw ArgumentError(
        'Both customer and orderPurpose are required for a B2B catalog.',
      );
    }
    try {
      final response = await _dio.post(
        ApiEndpoints.getProfileProducts,
        data: {
          'profile': posProfile,
          if (_normalizedOptionalString(priceList) case final value?)
            'price_list': value,
          if (hasB2bContext) 'customer': normalizedCustomer,
          if (hasB2bContext) 'order_purpose': normalizedPurpose,
        },
      );

      if (response.statusCode == 200 && response.data['message'] != null) {
        final List<dynamic> itemsData = response.data['message'];

        // Transform the item data to match our expected format
        List<Map<String, dynamic>> items = [];
        for (final rawItem in itemsData.whereType<Map>()) {
          final item = Map<String, dynamic>.from(rawItem);
          if (_isExplicitlyDisabled(item) || !_hasUsableItemIdentity(item)) {
            continue;
          }

          final rate =
              _asDouble(
                item['price'] ?? item['price_list_rate'] ?? item['rate'],
              ) ??
              0.0;

          items.add({
            'name': item['id'],
            'item_name': item['name'],
            'item_group': item['item_group'],
            'rate': rate,
            'price_list_rate':
                _asDouble(item['price_list_rate'] ?? item['price']) ?? rate,
            'price_list':
                _normalizedOptionalString(item['price_list']) ??
                _normalizedOptionalString(priceList),
            'actual_qty': item['qty'] ?? 0.0,
            'allow_negative_stock': _asBool(item['allow_negative_stock']),
            'stock_uom': 'Unit', // Default UOM
          });
        }
        return items;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch items: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPosPriceLists(String posProfile) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.getPosPriceLists,
        data: {'profile': posProfile},
      );

      if (response.statusCode == 200 && response.data['message'] != null) {
        final List<dynamic> priceListsData = response.data['message'];
        return priceListsData
            .whereType<Map>()
            .map((raw) {
              final priceList = Map<String, dynamic>.from(raw);
              return {
                'name': _normalizedOptionalString(priceList['name']) ?? '',
                'display_label':
                    _normalizedOptionalString(priceList['display_label']) ??
                    _normalizedOptionalString(priceList['name']) ??
                    '',
                'currency': _normalizedOptionalString(priceList['currency']),
                'is_default': _asBool(priceList['is_default']),
                'zero_shipping_default': _asBool(
                  priceList['zero_shipping_default'],
                ),
                // Order purposes this list belongs to (`[]` = a free retail
                // list). Only carried when the backend sends the key, so the
                // client can tell an older backend (key absent) from one that
                // says "reserved for nobody" and fall back accordingly.
                if (priceList.containsKey(reservedForPurposesKey))
                  reservedForPurposesKey: parseReservedForPurposes(
                    priceList[reservedForPurposesKey],
                  ),
              };
            })
            .where((item) => (item['name'] as String).isNotEmpty)
            .toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch POS price lists: $e');
      }
      return [];
    }
  }

  /// Fetches the commercial policies (order purposes) configured for [posProfile].
  ///
  /// Manager-gated on the backend. Returns `[]` on error / for non-managers so
  /// the caller can simply treat the absence of policies as "Standard only".
  /// The "Standard" purpose is intentionally NOT returned — a null selection
  /// in the UI means Standard.
  Future<List<CommercialPolicy>> getCommercialPolicies(
    String posProfile,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.getCommercialPolicies,
        data: {'profile': posProfile},
      );

      if (response.statusCode == 200 && response.data['message'] != null) {
        final List<dynamic> policiesData = response.data['message'];
        return policiesData
            .whereType<Map>()
            .map(
              (raw) =>
                  CommercialPolicy.fromJson(Map<String, dynamic>.from(raw)),
            )
            .where((policy) => policy.name.trim().isNotEmpty)
            .toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch commercial policies: $e');
      }
      return [];
    }
  }

  /// Resolves the only commercial policy and price list a B2B order may use.
  ///
  /// Unlike the manager catalog helpers, this endpoint is available to an
  /// assigned B2B Sales Rep and validates the customer, purpose, and profile as
  /// one server-owned pricing context.
  Future<B2bPricingContext> getB2bPricingContext({
    required String profile,
    required String customer,
    required String orderPurpose,
  }) async {
    final normalizedProfile = profile.trim();
    final normalizedCustomer = customer.trim();
    final normalizedPurpose = orderPurpose.trim();
    final response = await _dio.post(
      ApiEndpoints.getB2bPricingContext,
      data: {
        'profile': normalizedProfile,
        'customer': normalizedCustomer,
        'order_purpose': normalizedPurpose,
      },
    );
    final rawMessage = response.data is Map
        ? (response.data as Map)['message']
        : null;
    if (response.statusCode != 200 || rawMessage is! Map) {
      throw Exception('The B2B pricing context could not be loaded.');
    }

    final message = Map<String, dynamic>.from(rawMessage);
    final echoedProfile = _normalizedOptionalString(message['profile']);
    final echoedCustomer = _normalizedOptionalString(message['customer']);
    final echoedPurpose = _normalizedOptionalString(message['order_purpose']);
    if (echoedProfile != normalizedProfile ||
        echoedCustomer != normalizedCustomer ||
        echoedPurpose != normalizedPurpose) {
      throw Exception('The B2B pricing context did not match this order.');
    }

    final rawPolicy = message['commercial_policy'];
    final rawPriceList = message['price_list'];
    if (rawPolicy is! Map || rawPriceList is! Map) {
      throw Exception('The B2B pricing policy is incomplete.');
    }
    final policy = CommercialPolicy.fromJson(
      Map<String, dynamic>.from(rawPolicy),
    );
    if (policy.name.trim().isEmpty ||
        policy.orderPurpose.trim() != normalizedPurpose) {
      throw Exception('The B2B pricing policy did not match this order.');
    }

    final priceList = Map<String, dynamic>.from(rawPriceList);
    final priceListName = _normalizedOptionalString(priceList['name']);
    if (priceListName == null) {
      throw Exception('The B2B price list is unavailable.');
    }
    priceList['name'] = priceListName;
    priceList['display_label'] =
        _normalizedOptionalString(priceList['display_label']) ?? priceListName;
    priceList['currency'] = _normalizedOptionalString(priceList['currency']);
    priceList['is_default'] = _asBool(priceList['is_default']);
    priceList['zero_shipping_default'] = _asBool(
      priceList['zero_shipping_default'],
    );

    return B2bPricingContext(
      profile: normalizedProfile,
      customer: normalizedCustomer,
      orderPurpose: normalizedPurpose,
      commercialPolicy: policy,
      priceList: priceList,
    );
  }

  /// Resolves the effective price list for [customer] (B2B tier).
  ///
  /// Mirrors [getCommercialPolicies]: manager-gated on the backend, best-effort
  /// on the client. The backend walks Customer.default_price_list →
  /// Customer Group.default_price_list and returns the resolved name, or null
  /// when the customer has no tier price list configured.
  ///
  /// [orderPurpose] matters: for a "B2B Supply" order the backend falls back to
  /// the B2B base list rather than letting an un-tiered B2B customer price at
  /// retail. Omitting it makes the cart show the POS default while the server
  /// still books the B2B rate, so it is always passed for a policy order.
  ///
  /// Returns the resolved price-list name, or `null` when none is configured /
  /// on any error (non-manager, network failure, etc.) so the caller can simply
  /// fall back to the POS default price list.
  Future<String?> getCustomerPriceList(
    String customer,
    String posProfile, {
    String? orderPurpose,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.resolveCustomerPriceList,
        data: {
          'customer': customer,
          if (posProfile.trim().isNotEmpty) 'pos_profile': posProfile,
          if ((orderPurpose ?? '').trim().isNotEmpty)
            'order_purpose': orderPurpose!.trim(),
        },
      );

      if (response.statusCode == 200 && response.data['message'] != null) {
        final message = Map<String, dynamic>.from(
          response.data['message'] as Map,
        );
        return _normalizedOptionalString(message['price_list']);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to resolve customer price list: $e');
      }
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getSalesPartners({
    String? search,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.getSalesPartners,
        data: {
          if (search != null && search.isNotEmpty) 'search': search,
          'limit': limit,
        },
      );
      if (response.statusCode == 200 && response.data['message'] != null) {
        final List<dynamic> data = response.data['message'];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch sales partners: $e');
    }
  }

  /// Searches customers. [customerType] (optional) constrains results to
  /// "Individual" or "Company"; pass null for all. The B2C POS customer search
  /// passes "Individual" so Company (B2B) accounts never appear in POS, while
  /// B2B mode passes "Company".
  Future<List<Map<String, dynamic>>> searchCustomers(
    String query, {
    String? customerType,
  }) async {
    try {
      // Check if query contains only digits/phone characters (phone search) or contains letters (name search)
      final isPhoneSearch = RegExp(r'^[0-9+\-\s()]+$').hasMatch(query.trim());

      final response = await _dio.post(
        ApiEndpoints.searchCustomers,
        data: {
          ...(isPhoneSearch ? {'phone': query} : {'name': query}),
          if (customerType != null && customerType.isNotEmpty)
            'customer_type': customerType,
        },
      );

      if (response.statusCode == 200 && response.data['message'] != null) {
        final List<dynamic> customersData = response.data['message'];
        return customersData.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to search customers: $e');
    }
  }

  Future<Map<String, dynamic>> getCustomerShippingAddresses({
    required String customer,
    String? invoice,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.getCustomerShippingAddresses,
        data: {
          'customer': customer,
          if (invoice != null && invoice.isNotEmpty) 'invoice': invoice,
        },
      );

      if (response.statusCode == 200 && response.data['message'] != null) {
        return Map<String, dynamic>.from(response.data['message'] as Map);
      }
      throw ApiException('Failed to fetch customer shipping addresses');
    } catch (e) {
      throw ApiException('Failed to fetch customer shipping addresses');
    }
  }

  Future<Map<String, dynamic>> saveCustomerShippingAddress({
    required String customer,
    required String phone,
    String? invoice,
    String? addressName,
    String? branchName,
    String? address,
    String? territory,
    String? locationLink,
    double? latitude,
    double? longitude,
    String? geoSource,
    bool setAsPrimary = true,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.saveCustomerShippingAddress,
        data: {
          'customer': customer,
          'phone': phone,
          if (invoice != null && invoice.isNotEmpty) 'invoice': invoice,
          if (addressName != null && addressName.isNotEmpty)
            'address_name': addressName,
          if (branchName != null && branchName.isNotEmpty)
            'branch_name': branchName,
          if (address != null && address.isNotEmpty) 'address': address,
          if (territory != null && territory.isNotEmpty) 'territory': territory,
          // Geo payload. Frappe drops form keys a whitelisted method does not
          // declare, so a backend that predates the geo lane simply ignores
          // these instead of erroring.
          if (locationLink != null && locationLink.isNotEmpty)
            'location_link': locationLink,
          if (latitude != null && longitude != null) ...{
            'latitude': latitude,
            'longitude': longitude,
            if (geoSource != null && geoSource.isNotEmpty)
              'geo_source': geoSource,
          },
          'set_as_primary': setAsPrimary ? 1 : 0,
        },
      );

      if (response.statusCode == 200 && response.data['message'] != null) {
        return Map<String, dynamic>.from(response.data['message'] as Map);
      }
      throw ApiException('Failed to save customer shipping address');
    } catch (e) {
      throw ApiException('Failed to save customer shipping address');
    }
  }

  Future<Map<String, dynamic>> createCustomer({
    required String customerName,
    required String mobileNumber,
    required String territoryId,
    required String detailedAddress,
    String? locationLink,
    double? latitude,
    double? longitude,
    String? geoSource,
    String? secondaryMobile,
    String? customerType,
    String? customerGroup,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.createCustomer,
        data: FormData.fromMap({
          'customer_name': customerName,
          'mobile_no': mobileNumber,
          'customer_primary_address': detailedAddress,
          'territory_id': territoryId,
          if (locationLink != null && locationLink.isNotEmpty)
            'location_link': locationLink,
          // Resolved pin from the location-link field. Sent only as a pair —
          // half a coordinate is worse than none.
          if (latitude != null && longitude != null) ...{
            'latitude': latitude.toString(),
            'longitude': longitude.toString(),
            if (geoSource != null && geoSource.isNotEmpty)
              'geo_source': geoSource,
          },
          if (secondaryMobile != null && secondaryMobile.isNotEmpty)
            'secondary_mobile': secondaryMobile,
          if (customerType != null && customerType.isNotEmpty)
            'customer_type': customerType,
          if (customerGroup != null && customerGroup.isNotEmpty)
            'customer_group': customerGroup,
        }),
      );

      if (response.statusCode == 200 && response.data['message'] != null) {
        return response.data['message'] as Map<String, dynamic>;
      }
      throw ApiException('Failed to create customer');
    } on DioException catch (e) {
      // Try to extract a friendly error from Frappe/ERPNext error payload
      final data = e.response?.data;
      String? exceptionType;
      String? message;
      if (data is Map) {
        exceptionType = data['exception']?.toString();
        // Frappe can return nested messages; prefer explicit message if present
        message = data['message']?.toString();
        // Sometimes error text is under _error_message or _server_messages
        message ??= data['_error_message']?.toString();
        message ??= data['_server_messages']?.toString();
      }
      // Fallback to Dio error message
      message ??= e.message;

      // Specific friendly mapping: duplicate customer/mobile
      if ((exceptionType == 'ValidationError' ||
              exceptionType == 'frappe.exceptions.ValidationError') &&
          message != null &&
          message.toLowerCase().contains('already exists')) {
        final lowerMsg = message.toLowerCase();

        // Mobile/phone uniqueness violation
        if (lowerMsg.contains('mobile') || lowerMsg.contains('phone')) {
          throw ApiException(
            'A customer with this phone number already exists. Please search and select it.',
            code: 'DUPLICATE_CUSTOMER_MOBILE',
          );
        }

        // Name-based duplication (still possible if backend changes back)
        String? conflictedName;
        try {
          final namePos = lowerMsg.indexOf('name');
          if (namePos >= 0) {
            final tail = message.substring(namePos);
            int firstQuoteIndex = -1;
            String? quoteChar;
            for (final q in ['"', "'"]) {
              final i = tail.indexOf(q);
              if (i >= 0 && (firstQuoteIndex == -1 || i < firstQuoteIndex)) {
                firstQuoteIndex = i;
                quoteChar = q;
              }
            }
            if (firstQuoteIndex >= 0 && quoteChar != null) {
              final start = firstQuoteIndex + 1;
              final end = tail.indexOf(quoteChar, start);
              if (end > start) {
                conflictedName = tail.substring(start, end);
              }
            }
          }
        } catch (_) {}
        final friendly = conflictedName != null
            ? "Customer '$conflictedName' already exists. Please search and select it, or use a different name."
            : 'Customer already exists. Please search and select it, or use a different name.';
        throw ApiException(friendly, code: 'DUPLICATE_CUSTOMER');
      }

      // Generic friendly
      throw ApiException(message ?? 'Failed to create customer');
    } catch (e) {
      throw ApiException('Failed to create customer');
    }
  }

  /// Asks the backend for existing customers that look like the one about to
  /// be created (same phone, second phone, delivery address or name).
  ///
  /// FAILS OPEN: an old backend without the endpoint (404), a server error, a
  /// timeout or no network all return [CustomerDuplicateCheck.none], so this
  /// warning can never stop a create.
  Future<CustomerDuplicateCheck> checkCustomerDuplicates({
    required String customerName,
    required String mobileNumber,
    String? secondaryMobile,
    String? address,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.checkCustomerDuplicates,
        data: FormData.fromMap({
          'customer_name': customerName,
          'mobile_no': mobileNumber,
          if (secondaryMobile != null && secondaryMobile.isNotEmpty)
            'secondary_mobile': secondaryMobile,
          if (address != null && address.isNotEmpty) 'address': address,
        }),
        // A slow check must not hold the create hostage.
        options: Options(
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      if (response.statusCode == 200 && response.data is Map) {
        return CustomerDuplicateCheck.fromJson(
          (response.data as Map)['message'],
        );
      }
      return CustomerDuplicateCheck.none;
    } catch (e) {
      debugPrint('checkCustomerDuplicates failed open: $e');
      return CustomerDuplicateCheck.none;
    }
  }

  /// Returns the POS Profile mapped to [customerName]'s territory, or null.
  ///
  /// Response fields: `customer`, `territory`, `territory_pos_profile`
  Future<String?> getTerritoryPosProfile(String customerName) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.getTerritoryPosProfile,
        data: {'customer': customerName},
      );
      if (response.statusCode == 200 && response.data['message'] != null) {
        final msg = response.data['message'] as Map<String, dynamic>;
        return msg['territory_pos_profile'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Preview promo-code discounts for the current cart.
  ///
  /// Returns the Frappe `message` envelope:
  /// `{ results: [...], total_discount, free_delivery, eligible_net_total, capped }`.
  /// The preview is DISPLAY-ONLY — the server re-computes authoritatively at
  /// invoice creation.
  Future<Map<String, dynamic>> validatePromoCodes({
    required List<String> codes,
    required List<Map<String, dynamic>> items,
    String? customer,
    required String posProfile,
    bool isPickup = false,
    // The invoice being amended: its own redemption is not counted, so a
    // single-use code the order already carries does not preview as used up.
    String? amendedFrom,
  }) async {
    try {
      final cartItems = _buildCartRequestItems(items);
      final requestData = <String, dynamic>{
        'codes': jsonEncode(codes),
        'cart_json': jsonEncode(cartItems),
        'pos_profile': posProfile,
        'channel': 'flutter',
        'pickup': isPickup,
      };
      if (customer != null && customer.trim().isNotEmpty) {
        requestData['customer'] = customer;
      }
      if (amendedFrom != null && amendedFrom.trim().isNotEmpty) {
        requestData['amended_from'] = amendedFrom;
      }

      final response = await _dio.post(
        ApiEndpoints.validatePromoCodes,
        data: requestData,
      );

      if (response.statusCode == 200) {
        final message = response.data['message'];
        if (message is Map<String, dynamic>) {
          return message;
        }
        return Map<String, dynamic>.from(message as Map);
      }
      throw Exception('Failed to validate promo codes');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PROMO VALIDATION ERROR: $e');
      }
      throw Exception(
        extractFrappeErrorMessage(
          e,
          fallback: 'Failed to validate promo codes',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> createInvoice({
    required String posProfile,
    required List<Map<String, dynamic>> items,
    Map<String, dynamic>? customer,
    String? requiredDeliveryDatetime,
    String? deliveryEndDatetime,
    bool deliverySlotExplicit = false,
    String? salesPartner,
    String? paymentType, // 'cash' | 'online' (optional, advisory)
    bool isPickup = false,
    String? paymentMethod, // 'Cash' | 'Instapay' | 'Mobile Wallet'
    String? priceList,
    bool zeroShippingOverride = false,
    bool posProfileOverride = false,
    double? customDeliveryIncome,
    String? orderPurpose,
    String? commercialPolicy,
    String? policyReason,
    String? employeePayment, // 'credit' | 'cash' — Employee orders only
    List<String> promoCodes = const [],
  }) async {
    try {
      final requestData = _buildInvoiceRequestData(
        posProfile: posProfile,
        items: items,
        customer: customer,
        requiredDeliveryDatetime: requiredDeliveryDatetime,
        deliveryEndDatetime: deliveryEndDatetime,
        deliverySlotExplicit: deliverySlotExplicit,
        salesPartner: salesPartner,
        paymentType: paymentType,
        isPickup: isPickup,
        paymentMethod: paymentMethod,
        priceList: priceList,
        zeroShippingOverride: zeroShippingOverride,
        posProfileOverride: posProfileOverride,
        customDeliveryIncome: customDeliveryIncome,
        orderPurpose: orderPurpose,
        commercialPolicy: commercialPolicy,
        policyReason: policyReason,
        employeePayment: employeePayment,
        promoCodes: promoCodes,
      );

      if (kDebugMode) {
        debugPrint('🚀 SENDING REQUEST TO BACKEND:');
        debugPrint('   Endpoint: ${ApiEndpoints.createPosInvoice}');
        debugPrint('   Cart JSON: ${requestData['cart_json']}');
        debugPrint('   Customer: ${requestData['customer_name']}');
        debugPrint('   POS Profile: ${requestData['pos_profile_name']}');
      }

      final response = await _dio.post(
        ApiEndpoints.createPosInvoice,
        data: requestData,
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ INVOICE CREATION SUCCESS:');
          debugPrint('   Response: ${response.data['message']}');
        }
        return response.data['message'];
      }
      throw Exception('Failed to create invoice');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ INVOICE CREATION ERROR: $e');
      }
      // The refusal code is only on the raw error: read it before wrapping.
      if (frappeExcType(e) == AddressPinRequiredException.excType) {
        throw AddressPinRequiredException(
          extractFrappeErrorMessage(
            e,
            fallback: AddressPinRequiredException.defaultMessage,
          ),
        );
      }
      // Surface the real Frappe server message (e.g. a missing-price-list error)
      // instead of a bare DioException / 417 status code.
      throw Exception(
        extractFrappeErrorMessage(e, fallback: 'Failed to create invoice'),
      );
    }
  }

  Future<Map<String, dynamic>> submitInvoiceAmendment({
    required String sourceInvoiceId,
    required String posProfile,
    required List<Map<String, dynamic>> items,
    Map<String, dynamic>? customer,
    String? requiredDeliveryDatetime,
    String? deliveryEndDatetime,
    bool deliverySlotExplicit = false,
    String? salesPartner,
    String? paymentType,
    bool isPickup = false,
    String? paymentMethod,
    String? priceList,
    bool zeroShippingOverride = false,
    String? idempotencyKey,
    bool posProfileOverride = false,
    double? expectedSourceGrandTotal,
    int? expectedSourceItemCount,
    double? customDeliveryIncome,
    String? orderPurpose,
    String? commercialPolicy,
    String? policyReason,
    // Only an explicit 'cash' is sent. Anything else is omitted so the server
    // derives the choice from the source invoice, which the amendment cart
    // never loaded: a default 'credit' here would un-pay an amended cash order.
    String? employeePayment,
    // Every code left applied in the edit cart. The server treats a sent list as
    // authoritative (an empty one removes the order's codes); null leaves the
    // field out, and the server keeps the order's own codes.
    List<String>? promoCodes,
    // True when the cart never held the order's own codes (a restored draft):
    // [promoCodes] then only adds to them on the server.
    bool keepSourcePromoCodes = false,
  }) async {
    try {
      final amendmentEmployeePayment =
          employeePayment?.trim().toLowerCase() == 'cash' ? 'cash' : null;
      final requestData = _buildInvoiceRequestData(
        posProfile: posProfile,
        items: items,
        customer: customer,
        requiredDeliveryDatetime: requiredDeliveryDatetime,
        deliveryEndDatetime: deliveryEndDatetime,
        deliverySlotExplicit: deliverySlotExplicit,
        salesPartner: salesPartner,
        paymentType: paymentType,
        isPickup: isPickup,
        paymentMethod: paymentMethod,
        priceList: priceList,
        zeroShippingOverride: zeroShippingOverride,
        posProfileOverride: posProfileOverride,
        customDeliveryIncome: customDeliveryIncome,
        orderPurpose: orderPurpose,
        commercialPolicy: commercialPolicy,
        policyReason: policyReason,
        employeePayment: amendmentEmployeePayment,
      );
      requestData['invoice_id'] = sourceInvoiceId;
      // Always state pickup on an edit, 0 included. The shared builder omits the
      // key when off, and the server reads a missing key as "keep the source's
      // mode", so a pickup order could never be edited back to delivery
      // (order 22088). Older servers read 0 the same as a missing key.
      requestData['pickup'] = isPickup ? 1 : 0;
      if (promoCodes != null) {
        requestData['promo_codes'] = jsonEncode(promoCodes);
        if (keepSourcePromoCodes) requestData['keep_source_promo_codes'] = 1;
      }
      // The cart carries the source's custom line prices itself, so a line with no
      // override was reset to list by the operator: the server must not put the
      // old price back. A cart with no such line (an older draft, or a reply
      // without `amendment_line_rates`) leaves the server to inject them.
      if (items.any((item) => item[amendmentPricingCarriedKey] == true)) {
        requestData['keep_source_line_pricing'] = 0;
      }
      // Propagate free-shipping suppression so the backend doesn't re-add
      // the territory shipping tax row on the replacement invoice.
      if (customer?['was_free_shipping'] == true) {
        requestData['suppress_shipping_income'] = 1;
      }
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        requestData['idempotency_key'] = idempotencyKey;
      }
      // B5: pass source invoice context for server-side parity check.
      if (expectedSourceGrandTotal != null) {
        requestData['expected_source_grand_total'] = expectedSourceGrandTotal;
      }
      if (expectedSourceItemCount != null) {
        requestData['expected_source_item_count'] = expectedSourceItemCount;
      }

      if (kDebugMode) {
        debugPrint('🔁 SENDING AMENDMENT REQUEST TO BACKEND:');
        debugPrint('   Endpoint: ${ApiEndpoints.submitInvoiceAmendment}');
        debugPrint('   Source Invoice: $sourceInvoiceId');
        debugPrint('   Cart JSON: ${requestData['cart_json']}');
      }

      final response = await _dio.post(
        ApiEndpoints.submitInvoiceAmendment,
        data: requestData,
      );

      if (response.statusCode == 200) {
        // A refusal also arrives as 200: check `success`, not the status.
        return requireCompletedAmendment(response.data['message']);
      }
      throw Exception('Failed to submit invoice amendment');
    } on AmendmentRejectedException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '❌ INVOICE AMENDMENT REFUSED (${e.blockCode ?? 'no code'}): $e',
        );
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ INVOICE AMENDMENT ERROR: $e');
      }
      if (frappeExcType(e) == AddressPinRequiredException.excType) {
        throw AddressPinRequiredException(
          extractFrappeErrorMessage(
            e,
            fallback: AddressPinRequiredException.defaultMessage,
          ),
        );
      }
      throw Exception(
        extractFrappeErrorMessage(
          e,
          fallback: 'Failed to submit invoice amendment',
        ),
      );
    }
  }

  List<Map<String, dynamic>> _buildCartRequestItems(
    List<Map<String, dynamic>> items,
  ) {
    return items.map((item) {
      final isBundle = item['type'] == 'bundle';
      final base = <String, dynamic>{
        'item_code': isBundle
            ? item['bundle_details']['bundle_id']
            : item['item_code'],
        'qty': item['quantity'],
        'rate': item['rate'],
        'is_bundle': isBundle,
      };
      if (isBundle) {
        final rawSelections =
            item['bundle_details']?['selected_items'] as Map<String, dynamic>?;
        if (rawSelections != null) {
          final normalizedSelections = <String, List<Map<String, dynamic>>>{};
          rawSelections.forEach((groupName, entries) {
            final entryList = (entries as List)
                .map<Map<String, dynamic>>(
                  (entry) => Map<String, dynamic>.from(entry as Map),
                )
                .toList();
            normalizedSelections[groupName.toString()] = entryList;
          });
          base['selected_items'] = normalizedSelections;
        }
      }
      if (item.containsKey('price_list_rate')) {
        base['price_list_rate'] = item['price_list_rate'];
      }
      if (item.containsKey('discount_amount')) {
        base['discount_amount'] = item['discount_amount'];
      }
      if (item.containsKey('discount_percentage') &&
          !item.containsKey(_policyDiscountMarker)) {
        base['discount_percentage'] = item['discount_percentage'];
      }
      if (item.containsKey('custom_rate_override')) {
        base['custom_rate_override'] = item['custom_rate_override'];
      }
      return base;
    }).toList();
  }

  Map<String, dynamic> _buildInvoiceRequestData({
    required String posProfile,
    required List<Map<String, dynamic>> items,
    Map<String, dynamic>? customer,
    String? requiredDeliveryDatetime,
    String? deliveryEndDatetime,
    bool deliverySlotExplicit = false,
    String? salesPartner,
    String? paymentType,
    bool isPickup = false,
    String? paymentMethod,
    String? priceList,
    bool zeroShippingOverride = false,
    bool posProfileOverride = false,
    double? customDeliveryIncome,
    String? orderPurpose,
    String? commercialPolicy,
    String? policyReason,
    String? employeePayment,
    List<String> promoCodes = const [],
  }) {
    final cartItems = _buildCartRequestItems(items);

    if (kDebugMode) {
      debugPrint('📦 CART ITEMS BEING SENT TO BACKEND:');
      for (int i = 0; i < cartItems.length; i++) {
        final item = cartItems[i];
        final isBundle = item['is_bundle'] == true;
        debugPrint(
          '   Item ${i + 1}: ${item['item_code']} - Qty: ${item['qty']}, Rate: ${item['rate']}, Bundle: $isBundle',
        );
      }
    }

    final requestData = <String, dynamic>{
      'cart_json': jsonEncode(cartItems),
      'customer_name': customer?['name'] ?? 'Walking Customer',
      'pos_profile_name': posProfile,
    };

    final shippingAddressName =
        customer?['selected_shipping_address_name']?.toString().trim() ?? '';
    if (shippingAddressName.isNotEmpty) {
      requestData['shipping_address_name'] = shippingAddressName;
    }

    final deliveryIncome = customer == null
        ? null
        : _asDouble(
            customer['selected_shipping_address_delivery_income'] ??
                customer['delivery_income'],
          );
    final deliveryTerritory = customer == null
        ? ''
        : _firstNonEmptyString(customer, const [
            'selected_shipping_address_territory',
            'territory',
            'territory_name',
          ]);

    final partnerActive = salesPartner != null && salesPartner.isNotEmpty;
    if (customDeliveryIncome != null) {
      // Custom override: backend handles injection in STEP 7.4; suppress legacy STEP 7.5.
      requestData['custom_delivery_income'] = customDeliveryIncome;
      requestData['suppress_legacy_delivery_charges'] = 1;
    } else if (!partnerActive &&
        !zeroShippingOverride &&
        customer != null &&
        deliveryIncome != null &&
        deliveryIncome > 0) {
      requestData['delivery_charges_json'] = jsonEncode([
        {
          'charge_type': 'Delivery',
          'amount': deliveryIncome,
          'description':
              'Delivery charge for ${deliveryTerritory.isNotEmpty ? deliveryTerritory : 'Unknown Territory'}',
        },
      ]);
    }

    if (requiredDeliveryDatetime != null &&
        requiredDeliveryDatetime.isNotEmpty) {
      requestData['required_delivery_datetime'] = requiredDeliveryDatetime;
    }
    if (deliveryEndDatetime != null && deliveryEndDatetime.isNotEmpty) {
      requestData['delivery_end_datetime'] = deliveryEndDatetime;
    }
    // Always sent with a delivery start: 1 for a slot the operator picked, 0 for
    // one the app pre-selected. On 0 the server snaps a start whose slot is
    // already running (past a short grace) to the next slot, so an aged
    // auto-default never books the window in progress. A missing key means an
    // app too old to say, and keeps the running slot. Older servers ignore it.
    if (requiredDeliveryDatetime != null &&
        requiredDeliveryDatetime.isNotEmpty) {
      requestData['delivery_slot_explicit'] = deliverySlotExplicit ? 1 : 0;
    }
    if (isPickup) {
      requestData['pickup'] = 1;
    }
    if (posProfileOverride) {
      requestData['pos_profile_override'] = 1;
    }
    if (salesPartner != null && salesPartner.isNotEmpty) {
      requestData['sales_partner'] = salesPartner;
    }
    if (paymentType != null && paymentType.isNotEmpty) {
      requestData['payment_type'] = paymentType;
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      requestData['payment_method'] = paymentMethod;
    }
    if (priceList != null && priceList.isNotEmpty) {
      requestData['price_list'] = priceList;
    }
    if (zeroShippingOverride) {
      requestData['zero_shipping_override'] = 1;
      requestData['suppress_shipping_income'] = 1;
      requestData['suppress_legacy_delivery_charges'] = 1;
    }
    // Commercial policy (Order Purpose). When no policy is selected these fields
    // are omitted entirely so the backend applies Standard (unchanged) behavior.
    final normalizedCommercialPolicy = _normalizedOptionalString(
      commercialPolicy,
    );
    if (normalizedCommercialPolicy != null) {
      requestData['commercial_policy'] = normalizedCommercialPolicy;
      final normalizedOrderPurpose = _normalizedOptionalString(orderPurpose);
      if (normalizedOrderPurpose != null) {
        requestData['order_purpose'] = normalizedOrderPurpose;
      }
      final normalizedPolicyReason = _normalizedOptionalString(policyReason);
      if (normalizedPolicyReason != null) {
        requestData['policy_reason'] = normalizedPolicyReason;
      }
      // How an Employee order is paid. Its own field, never `payment_method`:
      // the server settles `cash` into the branch till and leaves `credit`
      // unpaid on the staff customer. Meaningless without a policy, so it
      // travels only inside this block.
      final normalizedEmployeePayment = _normalizedOptionalString(
        employeePayment,
      )?.toLowerCase();
      if (normalizedEmployeePayment == 'credit' ||
          normalizedEmployeePayment == 'cash') {
        requestData['employee_payment'] = normalizedEmployeePayment;
      }
    }
    // Promo codes. The server re-computes the discount authoritatively; the
    // preview is display-only. Always tag the channel when promos are present.
    if (promoCodes.isNotEmpty) {
      requestData['promo_codes'] = jsonEncode(promoCodes);
      requestData['channel'] = 'flutter';
    }
    return requestData;
  }

  Future<List<DeliverySlot>> getDeliverySlots(String posProfile) async {
    try {
      if (kDebugMode) {
        debugPrint('📡 API Call: getDeliverySlots for profile: $posProfile');
      }
      final response = await _dio.post(
        ApiEndpoints.getAvailableDeliverySlots,
        data: {'pos_profile_name': posProfile},
      );

      if (kDebugMode) {
        debugPrint('📡 API Response Status: ${response.statusCode}');
        debugPrint('📡 API Response Data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data['message'] != null) {
        final List<dynamic> slotsData = response.data['message'];
        if (kDebugMode) {
          debugPrint(
            '🎯 Converting ${slotsData.length} slots to DeliverySlot objects',
          );
        }
        return slotsData.map((slot) => DeliverySlot.fromJson(slot)).toList();
      }
      if (kDebugMode) {
        debugPrint('⚠️ No message in response or status code not 200');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error in getDeliverySlots: $e');
      }
      throw Exception('Failed to fetch delivery slots: $e');
    }
  }

  Future<DeliverySlot?> getNextAvailableSlot(String posProfile) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.getNextAvailableSlot,
        data: {'pos_profile_name': posProfile},
      );

      if (response.statusCode == 200 && response.data['message'] != null) {
        return DeliverySlot.fromJson(response.data['message']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch next available slot: $e');
    }
  }

  // Enhanced invoice creation with receipt printing
  Future<Map<String, dynamic>> createInvoiceWithReceipt({
    required String posProfile,
    required List<Map<String, dynamic>> items,
    Map<String, dynamic>? customer,
    String? requiredDeliveryDatetime,
    bool printReceipt =
        false, // default false; printing moved outside POS submit
  }) async {
    // Deprecated inline printing; retained for future Kanban use
    return createInvoice(
      posProfile: posProfile,
      items: items,
      customer: customer,
      requiredDeliveryDatetime: requiredDeliveryDatetime,
    );
  }

  // Register payment for an invoice (Wallet / InstaPay / Cash)
  // Wallet & InstaPay: backend will AUTO-GENERATE referenceNo/referenceDate if omitted, but UI should collect real values.
  Future<Map<String, dynamic>> payInvoice({
    required String invoiceName,
    required String paymentMode, // wallet | instapay | cash
    String? posProfile, // required for cash
    String? referenceNo, // required for wallet & instapay
    String? referenceDate, // required for wallet & instapay
  }) async {
    try {
      final data = {
        'invoice_name': invoiceName,
        'payment_mode': paymentMode,
        if (posProfile != null) 'pos_profile': posProfile,
        if (referenceNo != null) 'reference_no': referenceNo,
        if (referenceDate != null) 'reference_date': referenceDate,
      };

      final response = await _dio.post(ApiEndpoints.payInvoice, data: data);

      if (response.statusCode == 200 && response.data['message'] != null) {
        return Map<String, dynamic>.from(response.data['message']);
      }
      throw Exception('Failed to register payment');
    } catch (e) {
      throw Exception('Failed to register payment: $e');
    }
  }

  // Check if printing is available
  Future<bool> canPrint() async {
    // Legacy always-false after removal of PDF receipt system.
    return false;
  }

  /// Check if a POS Profile is currently open based on its timetable
  Future<Map<String, dynamic>> isPosProfileOpen(String posProfile) async {
    try {
      // Validate input
      if (posProfile.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ isPosProfileOpen: POS profile is empty, defaulting to open',
          );
        }
        return {'is_open': true, 'message': 'No POS profile specified'};
      }

      final response = await _dio.post(
        ApiEndpoints.isPosProfileOpen,
        data: {'pos_profile': posProfile},
      );

      if (response.statusCode == 200 && response.data['message'] != null) {
        return Map<String, dynamic>.from(response.data['message']);
      }
      throw Exception('Failed to check POS profile timetable');
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ DioException in isPosProfileOpen: ${e.message}');
      }
      // If there's a server error or network issue, default to "open"
      // to avoid blocking critical operations like order transfers
      return {
        'is_open': true,
        'message':
            'Error checking timetable: ${e.message}. Defaulting to open.',
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error in isPosProfileOpen: $e');
      }
      // Default to open to avoid blocking operations
      return {
        'is_open': true,
        'message': 'Error checking timetable. Defaulting to open.',
      };
    }
  }
}

class ApiException implements Exception {
  final String message;
  final String? code;
  ApiException(this.message, {this.code});
  @override
  String toString() => message;
}

final posRepositoryProvider = Provider<PosRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return PosRepository(dio);
});
