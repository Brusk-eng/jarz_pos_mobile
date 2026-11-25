import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../../data/studio_error.dart';
import '../data/settings_repository.dart';

/// The dated rules. A change adds a new dated value; history is never edited.
final rulesListProvider =
    AutoDisposeAsyncNotifierProvider<RulesNotifier, List<StudioRule>>(
      RulesNotifier.new,
    );

class RulesNotifier extends AutoDisposeAsyncNotifier<List<StudioRule>> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  Future<List<StudioRule>> build() => _repo.rules();

  /// Adds a dated value to [key]: [value] from [validFrom] on. The server's
  /// rule (with the new row in its history) replaces the one on screen.
  Future<void> change(
    String key,
    double value,
    String validFrom, {
    String? note,
  }) async {
    final fresh = await _repo.ruleSet(key, value, validFrom, note: note);
    _replace(fresh);
  }

  void _replace(StudioRule fresh) {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncData([
      for (final r in cur)
        if (r.key == fresh.key) fresh else r,
    ]);
  }
}

/// The flavours with their marketing status, dates and (read live) prices.
final flavoursListProvider =
    AutoDisposeAsyncNotifierProvider<FlavoursNotifier, List<StudioFlavour>>(
      FlavoursNotifier.new,
    );

class FlavoursNotifier extends AutoDisposeAsyncNotifier<List<StudioFlavour>> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  Future<List<StudioFlavour>> build() => _repo.flavours();

  /// Saves a flavour. The warnings the change causes come back to the
  /// caller; they never block the save. `STALE` takes the fresh copy and
  /// rethrows.
  Future<List<CheckRow>> change(
    StudioFlavour current, {
    FlavourStatus? status,
    String? availableFrom,
    String? availableTo,
    String? note,
  }) async {
    try {
      final result = await _repo.flavourSet(
        current.id,
        status: status?.wire,
        availableFrom: availableFrom,
        availableTo: availableTo,
        note: note,
        baseModified: current.modified,
      );
      _replace(result.flavour);
      return result.warnings;
    } on StudioStale catch (e) {
      if (e.current is Map) {
        _replace(
          StudioFlavour.fromJson(Map<String, dynamic>.from(e.current as Map)),
        );
      }
      rethrow;
    }
  }

  void _replace(StudioFlavour fresh) {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncData([
      for (final f in cur)
        if (f.id == fresh.id) fresh else f,
    ]);
  }
}

/// The people of the team with their role and linked login.
final peopleListProvider =
    AutoDisposeAsyncNotifierProvider<PeopleNotifier, List<StudioPerson>>(
      PeopleNotifier.new,
    );

class PeopleNotifier extends AutoDisposeAsyncNotifier<List<StudioPerson>> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  Future<List<StudioPerson>> build() => _repo.people();

  Future<void> change(String key, Map<String, dynamic> fields) async {
    final fresh = await _repo.personSet(key, fields);
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncData([
      for (final p in cur)
        if (p.key == fresh.key) fresh else p,
    ]);
  }
}

/// The claim status filter (wire value), null = all.
final claimStatusFilterProvider = StateProvider<String?>((ref) => null);

/// The read-only copy of the approved-claims registry, cursor-paged.
final claimListProvider =
    AutoDisposeAsyncNotifierProvider<
      ClaimListNotifier,
      PagedState<StudioClaim>
    >(ClaimListNotifier.new);

class ClaimListNotifier
    extends AutoDisposeAsyncNotifier<PagedState<StudioClaim>> {
  Future<StudioClaimPage> _fetch(String? after) => ref
      .read(settingsRepositoryProvider)
      .claims(status: ref.read(claimStatusFilterProvider), after: after);

  @override
  Future<PagedState<StudioClaim>> build() async {
    ref.watch(claimStatusFilterProvider);
    final page = await _fetch(null);
    return PagedState(items: page.items, next: page.next);
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || !cur.hasMore || cur.loadingMore) return;
    state = AsyncData(cur.copyWith(loadingMore: true));
    try {
      final page = await _fetch(cur.next);
      state = AsyncData(
        PagedState(items: [...cur.items, ...page.items], next: page.next),
      );
    } catch (e, st) {
      state = AsyncData(cur.copyWith(loadingMore: false));
      Error.throwWithStackTrace(e, st);
    }
  }
}
