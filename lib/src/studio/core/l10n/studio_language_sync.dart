import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/studio_enums.dart';
import '../../features/session/state/studio_session_notifier.dart';
import '../../features/settings/data/settings_repository.dart';
import '../offline/kv_store.dart';
import 'studio_locale.dart';

const _deviceKey = 'studio.lang.device';
const _pendingKey = 'studio.lang.pending';

/// Keeps the language the person picked in step with the server (contract
/// v1.3: the server words its own lines in `NotificationPrefs.lang`).
///
/// One home for it, watched once by `StudioApp`:
/// * a switch in the app is stored on the device and sent with
///   `settings.set_my_notifications(lang)`; if the send fails (offline) it is
///   kept as pending and sent on the next switch or the next sign-in. The switch
///   itself never waits for the network;
/// * on the first sign-in of a run: no choice on the device and none on the
///   server, the app's language is sent; none on the device but one on the
///   server, the server's is adopted; both and different, the device wins and
///   is sent.
final studioLanguageSyncProvider = Provider<void>((ref) {
  final sync = _LanguageSync(ref);
  ref.listen<Locale>(studioLocaleProvider, (_, next) => sync.switched(next));
  ref.listen(studioSessionProvider, (_, next) {
    if (next.valueOrNull != null) sync.signedIn();
  }, fireImmediately: true);
});

class _LanguageSync {
  _LanguageSync(this._ref);
  final Ref _ref;
  var _adopting = false;
  var _signedInDone = false;

  KvStore get _kv => _ref.read(studioKvStoreProvider);

  Future<String?> _read(String key) async {
    try {
      return await _kv.get(key);
    } catch (_) {
      return null; // no storage here (tests, a blocked browser): no choice kept
    }
  }

  Future<void> _write(String key, String? value) async {
    try {
      value == null ? await _kv.delete(key) : await _kv.put(key, value);
    } catch (_) {}
  }

  void _set(String code) {
    _adopting = true;
    _ref.read(studioLocaleProvider.notifier).state = Locale(code);
    _adopting = false;
  }

  Future<void> switched(Locale next) async {
    if (_adopting) return;
    await _write(_deviceKey, next.languageCode);
    await _send(next.languageCode);
  }

  Future<void> _send(String code) async {
    try {
      await _ref.read(settingsRepositoryProvider).setMyNotifications(lang: code);
      await _write(_pendingKey, null);
    } catch (_) {
      await _write(_pendingKey, code);
    }
  }

  Future<void> signedIn() async {
    if (_signedInDone) return;
    _signedInDone = true;
    final device = await _read(_deviceKey);
    final current = _ref.read(studioLocaleProvider).languageCode;
    if (device != null && device != current) _set(device);
    final mine = device ?? current;
    StudioLang? server;
    try {
      server = (await _ref.read(settingsRepositoryProvider).myNotifications())
          .lang;
    } catch (_) {
      // Offline: the device choice stays; this is tried again next run.
      _signedInDone = false;
      return;
    }
    final serverCode = server == null || server == StudioLang.unknown
        ? null
        : server.wire;
    if (device == null && serverCode != null) {
      _set(serverCode);
      await _write(_deviceKey, serverCode);
    } else if (serverCode != mine || await _read(_pendingKey) != null) {
      await _write(_deviceKey, mine);
      await _send(mine);
    }
  }
}
