import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../data/session_repository.dart';
import '../data/studio_me.dart';

/// The signed-in Studio user, or null when signed out.
///
/// `AsyncData(null)` means "no session" (send to login); `AsyncError` means
/// the server could not be reached (show retry, do not log the user out).
class StudioSessionNotifier extends AsyncNotifier<StudioMe?> {
  @override
  Future<StudioMe?> build() => _load();

  Future<StudioMe?> _load() async {
    try {
      return await ref.read(studioSessionRepositoryProvider).me();
    } on StudioApiException catch (e) {
      if (e.deadSession) return null;
      rethrow;
    }
  }

  /// Returns false when the server rejects the credentials.
  Future<bool> login(String username, String password) async {
    final repo = ref.read(studioSessionRepositoryProvider);
    final ok = await repo.login(username, password);
    if (!ok) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
    return true;
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> signOut() async {
    await ref.read(studioSessionRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

final studioSessionProvider =
    AsyncNotifierProvider<StudioSessionNotifier, StudioMe?>(
      StudioSessionNotifier.new,
    );
