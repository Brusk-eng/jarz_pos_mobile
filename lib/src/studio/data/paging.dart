import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/page_like.dart';
import 'optimistic_write.dart';
import 'studio_error.dart';

/// The loaded part of a cursor-paged list (`{items, next}`, contract 1.3).
class PagedState<T> {
  const PagedState({
    this.items = const [],
    this.next,
    this.loadingMore = false,
  });

  final List<T> items;

  /// Cursor for the next page, null at the end.
  final String? next;
  final bool loadingMore;

  bool get hasMore => next != null;

  PagedState<T> copyWith({List<T>? items, bool? loadingMore}) => PagedState(
    items: items ?? this.items,
    next: next,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// A cursor-paged list as a Riverpod notifier. A subclass supplies
/// [fetchPage]; filters live in other providers it `ref.watch`es, so a
/// filter change reloads from the first page.
abstract class PagedNotifier<T> extends AsyncNotifier<PagedState<T>> {
  /// One page of the endpoint: pass the previous page's `next` as [after].
  Future<PageLike<T>> fetchPage(String? after);

  @override
  Future<PagedState<T>> build() async {
    final page = await fetchPage(null);
    return PagedState(items: page.items, next: page.next);
  }

  /// Appends the next page. Does nothing at the end or while already loading.
  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || !cur.hasMore || cur.loadingMore) return;
    state = AsyncData(cur.copyWith(loadingMore: true));
    try {
      final page = await fetchPage(cur.next);
      state = AsyncData(
        PagedState(items: [...cur.items, ...page.items], next: page.next),
      );
    } catch (e, st) {
      // Keep what is on screen; the screen shows a "try again" row.
      state = AsyncData(cur.copyWith(loadingMore: false));
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Reloads from the first page.
  Future<void> refresh() async {
    state = await AsyncValue.guard(build);
  }

  /// Replaces (or, with null, removes) every item matching [match].
  void swap(bool Function(T) match, T? replacement) {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncData(
      cur.copyWith(
        items: [
          for (final it in cur.items)
            if (!match(it)) it else ...[?replacement],
        ],
      ),
    );
  }

  /// An optimistic write on the matching item.
  ///
  /// [optimistic] gives the item as it will look (null removes it) and is
  /// applied at once; [call] is the server write; [toItem] turns its result
  /// into the item to keep (default: leave the optimistic one). On failure the
  /// list rolls back and the error is rethrown. `ALREADY_DONE` counts as
  /// success and takes the server's copy through [fromCurrent]; `STALE` swaps
  /// in the fresh copy the same way and rethrows so the screen can say so.
  Future<R?> mutate<R>({
    required bool Function(T) match,
    required T? Function(T) optimistic,
    required Future<R> Function() call,
    T? Function(R result)? toItem,
    T? Function(Object? current)? fromCurrent,
  }) async {
    try {
      return await runOptimistic<PagedState<T>?, R?>(
        snapshot: () => state.valueOrNull,
        apply: () {
          final cur = state.valueOrNull;
          if (cur == null) return;
          state = AsyncData(
            cur.copyWith(
              items: [
                for (final it in cur.items)
                  if (!match(it)) it else ...[?optimistic(it)],
              ],
            ),
          );
        },
        rollback: (prev) {
          if (prev != null) state = AsyncData(prev);
        },
        call: () async {
          final r = await call();
          if (toItem != null) swap(match, toItem(r));
          return r;
        },
      );
    } on StudioAlreadyDone catch (e) {
      if (fromCurrent != null) swap(match, fromCurrent(e.current));
      return null;
    } on StudioStale catch (e) {
      if (fromCurrent != null) swap(match, fromCurrent(e.current));
      rethrow;
    }
  }
}

/// One object by id (a version, a piece, a post...) with optimistic writes.
/// Use with `AsyncNotifierProvider.family`.
abstract class EntityNotifier<T> extends FamilyAsyncNotifier<T, String> {
  Future<T> fetch(String id);

  /// Parses the `current` object of a `STALE` or `ALREADY_DONE` error.
  T parse(Object? json);

  /// The `modified` of [value]: what every write that may answer `STALE`
  /// sends back as `base_modified` (contract 1.4).
  String? modifiedOf(T value);

  /// The `modified` of the copy on screen, for `base_modified`. Pass it to
  /// every write the contract lets answer `STALE`.
  String? get baseModified {
    final cur = state.valueOrNull;
    return cur == null ? null : modifiedOf(cur);
  }

  @override
  Future<T> build(String arg) => fetch(arg);

  /// Reloads the object.
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => fetch(arg));
  }

  /// An optimistic write. [optimistic] (optional) shows the expected object at
  /// once; the server's answer replaces it. Failure rolls back and rethrows.
  /// `ALREADY_DONE` and `STALE` take the server's copy and rethrow, so the
  /// screen can say "This was already done" or "Someone changed this" (see
  /// `studioErrorText`) while already showing the current state.
  Future<void> mutate({
    T Function(T current)? optimistic,
    required Future<T> Function() call,
  }) async {
    try {
      final fresh = await runOptimistic<AsyncValue<T>, T>(
        snapshot: () => state,
        apply: () {
          final cur = state.valueOrNull;
          if (cur != null && optimistic != null) {
            state = AsyncData(optimistic(cur));
          }
        },
        rollback: (prev) => state = prev,
        call: call,
      );
      state = AsyncData(fresh);
    } on StudioAlreadyDone catch (e) {
      if (e.current != null) state = AsyncData(parse(e.current));
      rethrow;
    } on StudioStale catch (e) {
      if (e.current != null) state = AsyncData(parse(e.current));
      rethrow;
    }
  }
}
