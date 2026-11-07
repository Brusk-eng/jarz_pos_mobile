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
