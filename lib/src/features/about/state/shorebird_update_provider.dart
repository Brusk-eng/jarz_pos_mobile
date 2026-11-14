import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../update_channel/data/update_channel.dart';
import '../../update_channel/state/update_channel_provider.dart';
import '../data/about_release_info_repository.dart';

/// Injectable gateway so the notifier can be driven in tests without a device.
final shorebirdUpdateGatewayProvider = Provider<ShorebirdUpdateGateway>(
  (ref) => const DefaultShorebirdUpdateGateway(),
);

/// Drives Shorebird OTA patches.
///
/// `shorebird.yaml` has `auto_update: false`, so the engine no longer fetches
/// patches on launch by itself: this notifier is the only updater. It is
/// first read at app start (by `ShorebirdRestartGate`, mounted above login),
/// so a cold start checks immediately, before sign-in, using the track cached
/// by [updateChannelProvider]. Every Shorebird call carries that track; a
/// failure to resolve it means "stable", which is what the engine did before.
class ShorebirdUpdateNotifier extends AsyncNotifier<ShorebirdPatchStatus> {
  // Guards against overlapping downloads when a resume-triggered recheck races
  // the initial build.
  bool _downloading = false;

  // Coalesces rechecks: one runs at a time, and a request that arrives while
  // one is running schedules exactly one more pass (it may carry a new track).
  Future<void>? _recheck;
  bool _recheckAgain = false;

  ShorebirdDiagnostics? _lastDiagnostics;

  /// The most recent full diagnostics behind [state] (patch numbers), or
  /// `null` before the first read.
  ShorebirdDiagnostics? get lastDiagnostics => _lastDiagnostics;

  ShorebirdUpdateGateway get _gateway =>
      ref.read(shorebirdUpdateGatewayProvider);

  @override
  Future<ShorebirdPatchStatus> build() {
    // A device moved between tracks (e.g. login resolves "beta") re-checks at
    // once on its new track instead of waiting for the next resume.
    ref.listen<PatchTrack?>(
      updateChannelProvider.select((channel) => channel.valueOrNull?.track),
      (previous, next) {
        if (previous != null && next != null && previous != next) {
          unawaited(recheckStatus());
        }
      },
    );
    return _resolveStatus();
  }

  Future<void> recheckStatus() {
    final running = _recheck;
    if (running != null) {
      _recheckAgain = true;
      return running;
    }
    final future = _runRechecks();
    _recheck = future;
    return future.whenComplete(() => _recheck = null);
  }

  Future<void> _runRechecks() async {
    do {
      _recheckAgain = false;
      // Keep the previous value while loading so the restart banner/screen
      // does not flicker away on every resume.
      state = const AsyncLoading<ShorebirdPatchStatus>().copyWithPrevious(
        state,
      );
      state = await AsyncValue.guard(_resolveStatus);
    } while (_recheckAgain);
  }

  /// Reads the current patch status and, when a patch is available but not yet
  /// downloaded ([ShorebirdPatchStatus.updateAvailable]), pulls it immediately
  /// so the app surfaces "restart to apply" without waiting for the next
  /// launch. A POS device kept open all day would otherwise never download the
  /// patch.
  Future<ShorebirdPatchStatus> _resolveStatus() async {
    final track = await _currentTrack();
    final diagnostics = await _gateway.readStatus(track: track);
    _lastDiagnostics = diagnostics;
    if (diagnostics.status != ShorebirdPatchStatus.updateAvailable ||
        _downloading) {
      return diagnostics.status;
    }

    _downloading = true;
    try {
      final downloaded = await _gateway.downloadUpdate(track: track);
      if (!downloaded) {
        return diagnostics.status;
      }
      final afterDownload = await _gateway.readStatus(track: track);
      _lastDiagnostics = afterDownload;
      return afterDownload.status;
    } finally {
      _downloading = false;
    }
  }

  Future<PatchTrack> _currentTrack() async {
    try {
      return await ref.read(updateChannelProvider.notifier).currentTrack();
    } catch (_) {
      return PatchTrack.stable;
    }
  }
}

final shorebirdUpdateProvider =
    AsyncNotifierProvider<ShorebirdUpdateNotifier, ShorebirdPatchStatus>(
      ShorebirdUpdateNotifier.new,
    );
