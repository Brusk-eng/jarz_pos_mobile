import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/studio_api.dart';

/// Can the app reach the Studio server right now? No connectivity plugin: the
/// answer comes from what the app's own calls report ([report]) and, while
/// offline, from a probe every [reachabilityIntervalProvider] seconds.
///
/// Starts as online; the first failed call flips it.
class Reachability extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    ref.onDispose(() => _timer?.cancel());
    return true;
  }

  /// A call finished: [online] false when it failed for lack of a network.
  void report(bool online) {
    if (state == online) return;
    state = online;
    _timer?.cancel();
    _timer = null;
    final every = ref.read(reachabilityIntervalProvider);
    if (!online && every != null) {
      _timer = Timer.periodic(every, (_) => probe());
    }
  }

  /// Asks the server whether it answers (any answer, even "not signed in",
  /// means the network works).
  Future<bool> probe() async {
    final ok = await ref.read(reachabilityProbeProvider)();
    report(ok);
    return ok;
  }
}

final studioReachabilityProvider = NotifierProvider<Reachability, bool>(
  Reachability.new,
);

/// How often to probe while offline. Null switches the timer off (tests).
final reachabilityIntervalProvider = Provider<Duration?>(
  (ref) => const Duration(seconds: 8),
);

final reachabilityProbeProvider = Provider<Future<bool> Function()>((ref) {
  final api = ref.watch(studioApiProvider);
  return () async {
    try {
      await api.call('${studioMethodPrefix}session.me', get: true);
      return true;
    } on StudioNetworkError {
      return false;
    } catch (_) {
      return true;
    }
  };
});

/// Runs [body]; a network failure reports offline and a success online, then
/// the result or error goes on.
Future<T> trackReachability<T>(
  void Function(bool online) report,
  Future<T> Function() body,
) async {
  try {
    final r = await body();
    report(true);
    return r;
  } on StudioNetworkError {
    report(false);
    rethrow;
  }
}
