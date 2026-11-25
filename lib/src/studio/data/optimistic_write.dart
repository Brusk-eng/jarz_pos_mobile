import 'studio_error.dart';

/// The context-free core of an optimistic write: take a snapshot, apply the
/// change at once, run the server call, and on failure roll back and rethrow
/// so the caller can tell the person.
///
/// A [StudioStale] or [StudioAlreadyDone] failure is not rolled back: the
/// server's fresh object is the truth, and the caller (see `PagedNotifier.mutate`
/// and `EntityNotifier.mutate`) swaps it in instead.
///
/// The widget-level `optimistic()` in `shared/optimistic.dart` is a thin
/// wrapper over this.
Future<R> runOptimistic<S, R>({
  required S Function() snapshot,
  required void Function() apply,
  required void Function(S previous) rollback,
  required Future<R> Function() call,
}) async {
  final previous = snapshot();
  apply();
  try {
    return await call();
  } on StudioStale {
    rethrow;
  } on StudioAlreadyDone {
    rethrow;
  } catch (_) {
    rollback(previous);
    rethrow;
  }
}
