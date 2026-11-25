import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../data/session_repository.dart';

export '../data/me_profile_x.dart';
import '../../../data/models/studio_models.dart';

/// The signed-in Studio user, or null when signed out.
///
/// `AsyncData(null)` means "no session" (send to login); `AsyncError` means
/// the server could not be reached (show retry, do not log the user out).
class StudioSessionNotifier extends AsyncNotifier<MeProfile?> {
  @override
  Future<MeProfile?> build() => _load();

  Future<MeProfile?> _load() async {
    try {
      return await ref.read(studioSessionRepositoryProvider).me();
    } on StudioError catch (e) {
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

  /// Remembers on this device that [key] was seen (the server was told by the
  /// caller), without reloading the session: the screens stay where they are.
  void markHelpSeen(String key) {
    final me = state.valueOrNull;
    if (me == null || me.seenHelp.contains(key)) return;
    state = AsyncData(me.copyWith(seenHelp: [...me.seenHelp, key]));
  }

  Future<void> signOut() async {
    await ref.read(studioSessionRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

final studioSessionProvider =
    AsyncNotifierProvider<StudioSessionNotifier, MeProfile?>(
      StudioSessionNotifier.new,
    );
