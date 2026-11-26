import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/l10n/studio_locale.dart';
import '../../../core/config/studio_config.dart';
import '../biometric_strings.dart';

/// A saved login. Never printed: [toString] hides both parts.
@immutable
class BiometricCredentials {
  const BiometricCredentials(this.username, this.password);
  final String username;
  final String password;

  @override
  String toString() => 'BiometricCredentials(redacted)';
}

/// Fingerprint / face sign-in for the Studio app on Android.
///
/// Method: the username and password are kept only in `flutter_secure_storage`
/// (Android Keystore-backed encrypted preferences) and are handed back only
/// after a `local_auth` check that accepts a strong biometric (no PIN or
/// pattern fallback). A Keystore key that is invalidated when a new fingerprint
/// or face is enrolled guards the stored login: when the key is gone the login
/// is wiped. Nothing here is logged, sent to Sentry or kept in shared prefs.
abstract class StudioBiometricService {
  /// False on web and on platforms without the Android implementation: the
  /// option is then hidden everywhere.
  bool get supported;

  /// Supported, the phone has a strong biometric enrolled.
  Future<bool> canUse();

  /// A login is stored and may be released.
  Future<bool> isEnabled();

  /// The "use fingerprint next time?" question was already asked once.
  Future<bool> wasOffered();
  Future<void> markOffered();

  /// Asks for the biometric once (proof it works), then stores the login.
  /// False when the check failed or was cancelled; nothing is stored then.
  Future<bool> enable(String username, String password);

  /// Asks for the biometric and returns the stored login, or null on cancel,
  /// failure, or when the stored login was wiped because the fingerprints on
  /// the phone changed.
  Future<BiometricCredentials?> unlock();

  /// After a normal password login: when fingerprint sign-in is on, keeps the
  /// stored login in step with what the person just typed (a changed password,
  /// another account). Does nothing when it is off. No biometric prompt.
  Future<void> refresh(String username, String password);

  /// Deletes the stored login and the guard key. Safe to call at any time.
  Future<void> wipe();
}

String _defaultReason() => 'Sign in to Jarz Studio';

const _kUser = 'jarz_studio_bio_user';
const _kPass = 'jarz_studio_bio_pass';
const _kEnabled = 'jarz_studio_bio_enabled';
const _kOffered = 'jarz_studio_bio_offered';

/// Native guard key (StudioMainActivity): `arm`, `isValid`, `disarm`.
const biometricGuardChannel = MethodChannel('jarz_studio/biometric_guard');

class DeviceBiometricService implements StudioBiometricService {
  DeviceBiometricService({
    LocalAuthentication? auth,
    FlutterSecureStorage? storage,
    MethodChannel? guard,
    bool? platformSupported,
    this.reason = _defaultReason,
  }) : _auth = auth ?? LocalAuthentication(),
       _storage =
           storage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
           ),
       _guard = guard ?? biometricGuardChannel,
       supported =
           platformSupported ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;
  final MethodChannel _guard;

  /// Text of the system prompt.
  final String Function() reason;

  @override
  final bool supported;

  @override
  Future<bool> canUse() async {
    if (!supported) return false;
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.contains(BiometricType.strong);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isEnabled() async {
    if (!supported) return false;
    try {
      return await _storage.read(key: _kEnabled) == '1';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> wasOffered() async {
    try {
      return await _storage.read(key: _kOffered) == '1';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> markOffered() async {
    try {
      await _storage.write(key: _kOffered, value: '1');
    } catch (_) {}
  }

  Future<bool> _prompt() async {
    try {
      return await _auth.authenticate(
        localizedReason: reason(),
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: false,
        ),
      );
    } catch (_) {
      // Cancelled, locked out, hardware error: the caller falls back to the password.
      return false;
    }
  }

  /// True when the guard key is still valid. A phone build without the native
  /// guard, or any error, counts as valid: the biometric check still stands.
  Future<bool> _guardValid() async {
    try {
      return await _guard.invokeMethod<bool>('isValid') ?? true;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _guardCall(String method) async {
    try {
      await _guard.invokeMethod<void>(method);
    } catch (_) {}
  }

  /// Creates the guard key. A build without the native guard (tests, other
  /// activities) is fine; a guard that exists but cannot be armed is not.
  Future<bool> _guardArm() async {
    try {
      return await _guard.invokeMethod<bool>('arm') ?? false;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> enable(String username, String password) async {
    if (!await canUse()) return false;
    if (!await _prompt()) return false;
    try {
      if (!await _guardArm()) {
        await wipe();
        return false;
      }
      await _storage.write(key: _kUser, value: username);
      await _storage.write(key: _kPass, value: password);
      await _storage.write(key: _kEnabled, value: '1');
      return true;
    } catch (_) {
      await wipe();
      return false;
    }
  }

  @override
  Future<BiometricCredentials?> unlock() async {
    if (!await isEnabled()) return null;
    if (!await _guardValid()) {
      // New fingerprints or a new face were enrolled: the stored login dies.
      await wipe();
      return null;
    }
    if (!await _prompt()) return null;
    try {
      final user = await _storage.read(key: _kUser);
      final pass = await _storage.read(key: _kPass);
      if (user == null || pass == null || user.isEmpty || pass.isEmpty) {
        await wipe();
        return null;
      }
      return BiometricCredentials(user, pass);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> refresh(String username, String password) async {
    if (!await isEnabled()) return;
    try {
      await _storage.write(key: _kUser, value: username);
      await _storage.write(key: _kPass, value: password);
    } catch (_) {
      await wipe();
    }
  }

  @override
  Future<void> wipe() async {
    for (final k in [_kUser, _kPass, _kEnabled]) {
      try {
        await _storage.delete(key: k);
      } catch (_) {}
    }
    await _guardCall('disarm');
  }
}

/// The one service the Studio uses. Tests override it.
final studioBiometricProvider = Provider<StudioBiometricService>((ref) {
  return DeviceBiometricService(
    // The fake build has no server and no stored login: the option is off.
    platformSupported: ref.watch(studioFakeProvider) ? false : null,
    reason: () => ref.read(studioLocaleProvider).languageCode == 'ar'
        ? const BiometricStringsAr().promptReason
        : const BiometricStringsEn().promptReason,
  );
});
