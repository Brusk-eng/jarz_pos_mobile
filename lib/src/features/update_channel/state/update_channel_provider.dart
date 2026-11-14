import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/update_channel.dart';
import '../data/update_channel_service.dart';
import '../data/update_channel_store.dart';

typedef FcmTokenReader = Future<String?> Function();

/// Injectable so tests never touch Firebase.
final updateChannelStoreProvider = Provider<UpdateChannelStore>(
  (ref) => const SharedPrefsUpdateChannelStore(),
);

/// Reads this device's FCM token so the server can match a per-device
/// override. Returns `null` when unavailable; the server then decides by role.
final updateChannelFcmTokenReaderProvider = Provider<FcmTokenReader>(
  (ref) => readFcmTokenForUpdateChannel,
);

Future<String?> readFcmTokenForUpdateChannel() async {
  if (kIsWeb) return null;
  try {
    if (Firebase.apps.isEmpty) return null;
    return await FirebaseMessaging.instance.getToken().timeout(
      const Duration(seconds: 5),
    );
  } catch (_) {
    return null;
  }
}

/// The Shorebird patch track this device follows.
///
/// * `build` loads the track last resolved on this device (default "stable"),
///   so a cold start before login checks the right track. It never forces a
///   restart.
/// * [refresh] asks the server (signed-in only) and caches the answer.
///
/// Every state this notifier can reach is a valid [UpdateChannel]; it never
/// holds an error.
class UpdateChannelNotifier extends AsyncNotifier<UpdateChannel> {
  Future<void>? _refreshing;

  UpdateChannelStore get _store => ref.read(updateChannelStoreProvider);

  @override
  Future<UpdateChannel> build() async {
    try {
      // Bounded: a stuck preferences read must not stall the patch check.
      final cached = await _store.readTrack().timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
      return UpdateChannel.cached(cached ?? PatchTrack.stable);
    } catch (_) {
      return UpdateChannel.fallback;
    }
  }

  /// The track every Shorebird call must use. Never throws; "stable" on any
  /// failure.
  Future<PatchTrack> currentTrack() async {
    // The live state first: `future` can still hold the previous value
    // while listeners of a just-set state run.
    UpdateChannel? current;
    try {
      current = state.valueOrNull;
    } catch (_) {
      current = null;
    }
    if (current != null) return current.track;
    try {
      return (await future).track;
    } catch (_) {
      return PatchTrack.stable;
    }
  }

  /// Re-asks the server. Call after login and on resume. Concurrent calls
  /// share one request. Never throws.
  ///
  /// A transport failure (no answer) keeps the current track; any answer from
  /// the server - including an error status from a server that does not have
  /// the endpoint yet - is applied and cached, which for errors means
  /// "stable".
  Future<void> refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<void> _doRefresh() async {
    try {
      // Make sure the cached value is loaded first, so a slow cache read
      // cannot land after (and overwrite) the server's answer.
      await currentTrack();

      String? token;
      try {
        token = await ref.read(updateChannelFcmTokenReaderProvider)();
      } catch (_) {
        token = null;
      }

      final answer = await ref
          .read(updateChannelServiceProvider)
          .fetchChannel(fcmToken: token);
      if (answer == null) {
        return;
      }
      state = AsyncData(answer);
      await _store.writeTrack(answer.track);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Update channel refresh failed (ignored): $error');
      }
    }
  }
}

final updateChannelProvider =
    AsyncNotifierProvider<UpdateChannelNotifier, UpdateChannel>(
      UpdateChannelNotifier.new,
    );
