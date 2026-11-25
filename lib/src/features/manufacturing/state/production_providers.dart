import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/manufacturing_service.dart';
import '../data/models/basket_rollup.dart';
import '../data/models/bom_details.dart';
import '../data/models/production_policy.dart';
import '../data/models/production_suggestion.dart';
import '../data/models/material_options.dart';
import '../data/models/batch_line.dart';
import '../../../core/widgets/posting_date_confirmation_dialog.dart';
import '../presentation/production_timestamp.dart';
import 'production_basket_notifier.dart';

/// Which status buckets the Plan tab is showing.
class ProductionFilter {
  const ProductionFilter({this.statuses = const <String>{}});

  /// Empty means "everything".
  final Set<String> statuses;

  bool get isAll => statuses.isEmpty;

  bool matches(ProductionSuggestion item) =>
      isAll || statuses.contains(item.status);

  ProductionFilter toggle(String status) {
    final next = Set<String>.from(statuses);
    if (!next.remove(status)) next.add(status);
    return ProductionFilter(statuses: next);
  }

  @override
  bool operator ==(Object other) =>
      other is ProductionFilter &&
      other.statuses.length == statuses.length &&
      other.statuses.containsAll(statuses);

  @override
  int get hashCode => Object.hashAllUnordered(statuses);
}

final productionFilterProvider = StateProvider<ProductionFilter>(
  (ref) => const ProductionFilter(),
);

/// Whether to ask the backend for per-item capacity.
///
/// Capacity costs one BOM explosion per item server-side. Kept switchable so a
/// slow board can be made fast without a deploy.
final includeCapacityProvider = StateProvider<bool>((ref) => true);

/// The ranked board. Loads once and is refreshed explicitly.
final productionSuggestionsProvider =
    AsyncNotifierProvider<
      ProductionSuggestionsNotifier,
      ProductionSuggestionsPage
    >(ProductionSuggestionsNotifier.new);

class ProductionSuggestionsNotifier
    extends AsyncNotifier<ProductionSuggestionsPage> {
  ManufacturingService get _service => ref.read(manufacturingServiceProvider);

  @override
  Future<ProductionSuggestionsPage> build() {
    final includeCapacity = ref.watch(includeCapacityProvider);
    return _service.getProductionSuggestions(includeCapacity: includeCapacity);
  }

  /// Pull-to-refresh. Bypasses the server-side cache so the number on screen
  /// reflects stock as of now, not up to two minutes ago.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.getProductionSuggestions(
        includeCapacity: ref.read(includeCapacityProvider),
        forceRefresh: true,
      ),
    );
  }

  /// Sets an item's cover-target override, then refreshes so its suggestion
  /// reflects the new target immediately.
  Future<void> setTargetDays(String itemCode, int? targetDays) async {
    await _service.setItemTargetDays(
      itemCode: itemCode,
      targetDays: targetDays,
    );
    await refresh();
  }
}

/// The board after the status filter — derived, so filtering never refetches.
final visibleSuggestionsProvider = Provider<List<ProductionSuggestion>>((ref) {
  final page = ref.watch(productionSuggestionsProvider).valueOrNull;
  if (page == null) return const <ProductionSuggestion>[];

  final filter = ref.watch(productionFilterProvider);
  if (filter.isAll) return page.items;
  return page.items.where(filter.matches).toList(growable: false);
});

/// Search text for the manual BOM lookup, written debounced by the widget.
final bomSearchQueryProvider = StateProvider<String>((ref) => '');

/// Manual BOM search, cached per query for a minute.
///
/// Replaces the old `FutureBuilder(future: service.listDefaultBomItems(search))`
/// sitting inside `build()`, which re-issued the request on every keystroke and
/// on every unrelated `setState` — including each tap of a quantity stepper.
final bomSearchProvider = FutureProvider.autoDispose
    .family<List<BomItemSummary>, String>((ref, query) async {
      final link = ref.keepAlive();
      final timer = Timer(const Duration(seconds: 60), link.close);
      ref.onDispose(timer.cancel);

      return ref.read(manufacturingServiceProvider).searchBomItems(query);
    });

/// One BOM's components, cached while the user is working with it.
final bomDetailsProvider = FutureProvider.autoDispose
    .family<BomDetails, String>((ref, itemCode) async {
      final link = ref.keepAlive();
      final timer = Timer(const Duration(minutes: 5), link.close);
      ref.onDispose(timer.cancel);

      return ref.read(manufacturingServiceProvider).fetchBomDetails(itemCode);
    });

class MaterialOptionsRequest {
  const MaterialOptionsRequest({required this.bomName, required this.qty});

  final String bomName;
  final double qty;

  @override
  bool operator ==(Object other) =>
      other is MaterialOptionsRequest &&
      other.bomName == bomName &&
      other.qty == qty;

  @override
  int get hashCode => Object.hash(bomName, qty);
}

final materialOptionsProvider = FutureProvider.autoDispose
    .family<MaterialOptions, MaterialOptionsRequest>((ref, request) {
      return ref
          .read(manufacturingServiceProvider)
          .getMaterialOptions(bomName: request.bomName, qty: request.qty);
    });

/// The posting window and permissions the server enforces, for this user.
///
/// Loaded once per board session and kept: it changes only when somebody edits
/// Jarz POS Settings or this user's roles, neither of which happens while a
/// batch is being queued.
///
/// **Invalidated on a user switch** by `login_notifier._resetUserScopedState`.
/// It holds per-user permissions and lives for the app process, so on a shared
/// floor tablet a manager's window would otherwise survive into the operator's
/// session.
///
/// Every consumer must degrade gracefully while this is loading or failed —
/// see [productionPolicyOrFallbackProvider]. A date picker that refuses to
/// render because a permissions probe is in flight is worse than one built
/// from a conservative guess.
final productionPolicyProvider = FutureProvider<ProductionPolicy>((ref) {
  return ref.read(manufacturingServiceProvider).getProductionPolicy();
});

/// The policy, refetched if the last attempt failed.
///
/// A plain `FutureProvider` that has errored stays errored for the life of the
/// app process, so one dropped connection at board open would pin every user on
/// that tablet to today-only — silently, because
/// [productionPolicyOrFallbackProvider] swallows the error by design. Screens
/// that open the board call this so a failure costs one retry rather than a
/// restart.
Future<void> refreshProductionPolicy(WidgetRef ref) async {
  if (ref.read(productionPolicyProvider).hasError) {
    ref.invalidate(productionPolicyProvider);
  }
}

/// The policy, or the safest assumption while it is unknown.
///
/// "Safest" is today-only: a picker that offers a date the server will refuse
/// teaches the floor that the screen lies, while one that offers too few dates
/// is merely inconvenient for the few seconds the probe takes.
final productionPolicyOrFallbackProvider = Provider<ProductionPolicy>((ref) {
  return ref.watch(productionPolicyProvider).valueOrNull ??
      const ProductionPolicy();
});

/// The queue, once it has stopped changing.
///
/// Every heavy question about the queue — the consolidated roll-up, a line's
/// material options — costs a BOM explosion per line server-side. That was
/// affordable while the quantity moved in stepper taps; on the merged Plan tab
/// it is TYPED, so "50" is three states and would be three roll-ups, two of
/// them describing a basket that existed for eighty milliseconds.
///
/// Deliberately only the heavy consumers read this. The buttons and the totals
/// read the live basket, so what the operator sees and what Start batches
/// submits is never a stale copy — a settled basket is a cheaper QUESTION, not
/// a second source of truth.
final settledBasketProvider = FutureProvider.autoDispose<ProductionBasket>((
  ref,
) async {
  final basket = ref.watch(productionBasketProvider);
  // Nothing to wait for: an emptied basket should clear the pick list at once
  // rather than leave yesterday's shortage on screen for another half second.
  if (basket.isEmpty) return basket;

  var cancelled = false;
  ref.onDispose(() => cancelled = true);
  await Future<void>.delayed(const Duration(milliseconds: 400));
  // A newer keystroke has already replaced this provider. Never completing
  // leaves the disposed instance's consumers untouched instead of firing a
  // request for a basket that no longer exists.
  if (cancelled) return Completer<ProductionBasket>().future;
  return basket;
});

/// Consolidated material check for the current basket.
///
/// Recomputed whenever the basket settles, so the pick list and the shortage
/// banner always describe what is actually queued. Returns null for an empty
/// basket rather than calling the API with nothing.
final basketRollupProvider = FutureProvider.autoDispose<BasketRollup?>((
  ref,
) async {
  final basket = await ref.watch(settledBasketProvider.future);
  final policy = ref.read(productionPolicyOrFallbackProvider);
  // Check stock as of the date the batch will be posted, the same moment
  // Start batches sends. Without it a backdated plan was checked against
  // today's stock, showed no shortage, and was refused only on Start
  // (2026-11-26, Remas cheese: 45 kg today, 3.067 kg on 11-23 16:00).
  final posting = basket.postingDate;
  final explicitTime = hasExplicitPostingTime(posting);
  final today = policy.today();
  final isPastDay =
      posting != null &&
      DateTime(
        posting.year,
        posting.month,
        posting.day,
      ).isBefore(DateTime(today.year, today.month, today.day));
  // Today with no chosen time: today's stock is the right snapshot.
  final scheduledAt = (posting != null && (explicitTime || isPastDay))
      ? startScheduledAt(posting, explicitTime: explicitTime)
      : null;
  final lines = basket.toApiLines(scheduledAt: scheduledAt);
  if (lines.isEmpty) return null;

  return ref.read(manufacturingServiceProvider).getBasketMaterialRollup(lines);
});
