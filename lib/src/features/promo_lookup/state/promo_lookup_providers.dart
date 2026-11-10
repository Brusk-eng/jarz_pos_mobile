import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/promo_lookup_models.dart';
import '../data/promo_lookup_repository.dart';

/// The last lookup on the promo code screen: `AsyncData(null)` before the
/// first Check, then loading / the result / the error. Hand-written notifier
/// (no codegen), like the follow-ups feature.
class PromoLookupNotifier extends AutoDisposeAsyncNotifier<PromoLookupResult?> {
  int _generation = 0;

  @override
  Future<PromoLookupResult?> build() async => null;

  /// Looks [code] up, optionally against [order]. A slower earlier answer
  /// never overwrites a newer one.
  Future<void> lookup({required String code, String? order}) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    final generation = ++_generation;
    state = const AsyncLoading<PromoLookupResult?>();
    final next = await AsyncValue.guard<PromoLookupResult?>(
      () => ref
          .read(promoLookupRepositoryProvider)
          .lookup(code: trimmed, order: order),
    );
    if (generation == _generation) state = next;
  }

  void clear() {
    _generation++;
    state = const AsyncData<PromoLookupResult?>(null);
  }
}

final promoLookupProvider =
    AsyncNotifierProvider.autoDispose<PromoLookupNotifier, PromoLookupResult?>(
      PromoLookupNotifier.new,
    );

/// The last search on the Customer tab: `AsyncData(null)` before the first
/// search, then loading / the answer / the error.
class CustomerPromoLookupNotifier
    extends AutoDisposeAsyncNotifier<CustomerPromoLookup?> {
  int _generation = 0;

  /// The server refuses shorter queries; the screen checks first.
  static const minQueryLength = 3;

  @override
  Future<CustomerPromoLookup?> build() async => null;

  /// Searches [query] (name or phone). A slower earlier answer never
  /// overwrites a newer one.
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < minQueryLength) return;
    final generation = ++_generation;
    state = const AsyncLoading<CustomerPromoLookup?>();
    final next = await AsyncValue.guard<CustomerPromoLookup?>(
      () =>
          ref.read(promoLookupRepositoryProvider).lookupCustomerPromos(trimmed),
    );
    if (generation == _generation) state = next;
  }

  void clear() {
    _generation++;
    state = const AsyncData<CustomerPromoLookup?>(null);
  }
}

final customerPromoLookupProvider =
    AsyncNotifierProvider.autoDispose<
      CustomerPromoLookupNotifier,
      CustomerPromoLookup?
    >(CustomerPromoLookupNotifier.new);
