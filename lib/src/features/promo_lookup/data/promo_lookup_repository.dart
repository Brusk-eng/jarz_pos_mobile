import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import 'models/promo_lookup_models.dart';

final promoLookupRepositoryProvider = Provider<PromoLookupRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return PromoLookupRepository(dio);
});

/// Talks to `jarz_pos.api.promo.lookup_promo_code` and
/// `lookup_customer_promos`. Read-only; both only need a login.
class PromoLookupRepository {
  final Dio _dio;
  PromoLookupRepository(this._dio);

  /// The `message` payload, or the bare body when it is not enveloped.
  dynamic _payload(Response response) {
    final data = response.data;
    if (data is Map && data.containsKey('message')) return data['message'];
    return data;
  }

  /// What [code] is, and when [order] (a Woo order number or an invoice name)
  /// is given, what it would do to that order.
  Future<PromoLookupResult> lookup({
    required String code,
    String? order,
  }) async {
    final trimmedOrder = order?.trim() ?? '';
    final response = await _dio.get(
      ApiEndpoints.lookupPromoCode,
      queryParameters: {
        'code': code.trim(),
        if (trimmedOrder.isNotEmpty) 'order': trimmedOrder,
      },
    );
    return PromoLookupResult.fromJson(_payload(response));
  }

  /// A customer's promo codes, found by [query] (a name, or a phone number
  /// or its tail). The server refuses fewer than 3 characters.
  Future<CustomerPromoLookup> lookupCustomerPromos(String query) async {
    final response = await _dio.get(
      ApiEndpoints.lookupCustomerPromos,
      queryParameters: {'query': query.trim()},
    );
    return CustomerPromoLookup.fromJson(_payload(response));
  }
}
