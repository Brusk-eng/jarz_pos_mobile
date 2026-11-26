import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/studio_config.dart';
import '../../../core/network/studio_api.dart';
import '../data/biometric_service.dart';
import '../data/session_repository.dart';

export '../data/me_profile_x.dart';
import '../../../data/models/studio_models.dart';

/// The signed-in Studio user, or null when signed out.
///
/// `AsyncData(null)` means "no session" (send to login); `AsyncError` means
/// the server could not be reached (show retry, do not log the user out).
class StudioSessionNotifier extends AsyncNotifier<MeProfile?> {
  bool _expiring = false;

  @override
  Future<MeProfile?> build() => _load();

  StudioBiometricService get _bio => ref.read(studioBiometricProvider);

  Future<MeProfile?> _load({bool allowBiometric = true}) async {
    try {
      return await ref.read(studioSessionRepositoryProvider).me();
    } on StudioError catch (e) {
      if (!e.deadSession) rethrow;
      return allowBiometric ? _silentSignIn() : null;
    }
  }

  /// The session is gone: when fingerprint sign-in is on, ask for it and sign
  /// in with the stored login. Null (login screen) on cancel, failure, or when
  /// the server refuses the stored password (it is wiped then).
  Future<MeProfile?> _silentSignIn() async {
    final bio = _bio;
    if (!bio.supported || !await bio.isEnabled()) return null;
    final creds = await bio.unlock();
    if (creds == null) return null;
    final repo = ref.read(studioSessionRepositoryProvider);
    final ok = ref.read(studioFakeProvider)
        ? true
        : await repo.login(creds.username, creds.password);
    if (!ok) {
      await bio.wipe();
      return null;
    }
    try {
      return await repo.me();
    } on StudioError catch (e) {
      if (e.deadSession) return null;
      rethrow;
    }
  }

  /// The "Sign in with fingerprint" button on the login screen. False when the
  /// check was cancelled or failed; the password form stays.
  Future<bool> biometricSignIn() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_silentSignIn);
    return state.valueOrNull != null;
  }

  /// Called by the API client when a call found the session dead. Does
  /// nothing unless fingerprint sign-in is on, so the app behaves as before.
  Future<void> onSessionExpired() async {
    if (_expiring || state.isLoading) return;
    _expiring = true;
    try {
      final bio = _bio;
      if (!bio.supported || !await bio.isEnabled()) return;
      await reload();
    } finally {
      _expiring = false;
    }
  }

  /// Returns false when the server rejects the credentials.
  Future<bool> login(String username, String password) async {
    final repo = ref.read(studioSessionRepositoryProvider);
    // The fake build has no Frappe site to sign in to: any login is accepted.
    final ok = ref.read(studioFakeProvider)
        ? true
        : await repo.login(username, password);
    if (!ok) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(allowBiometric: false));
    if (state.valueOrNull != null) {
      await _afterPasswordLogin(username, password);
    }
    return true;
  }

  Future<void> _afterPasswordLogin(String username, String password) async {
    final bio = _bio;
    if (!bio.supported) return;
    if (await bio.isEnabled()) {
      await bio.refresh(username, password);
    } else if (!await bio.wasOffered() && await bio.canUse()) {
      ref.read(studioBiometricOfferProvider.notifier).state =
          BiometricCredentials(username, password);
    }
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
    if (!ref.read(studioFakeProvider)) {
      await ref.read(studioSessionRepositoryProvider).logout();
    }
    await _bio.wipe();
    ref.read(studioBiometricOfferProvider.notifier).state = null;
    state = const AsyncData(null);
  }
}

/// A login waiting for the answer to "use fingerprint next time?". Held in
/// memory only, until the person answers; null otherwise.
final studioBiometricOfferProvider = StateProvider<BiometricCredentials?>(
  (ref) => null,
);

final studioSessionProvider =
    AsyncNotifierProvider<StudioSessionNotifier, MeProfile?>(
      StudioSessionNotifier.new,
    );
