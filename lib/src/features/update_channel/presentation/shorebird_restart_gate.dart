import 'dart:async';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../about/data/about_release_info_repository.dart';
import '../../about/state/shorebird_update_provider.dart';
import '../state/update_channel_provider.dart';

/// Ends the process so the next launch boots the downloaded patch.
typedef AppProcessExit = void Function();

final appProcessExitProvider = Provider<AppProcessExit>(
  (ref) =>
      () => io.exit(0),
);

/// Whether this platform can close itself to apply a patch. Android only:
/// iOS forbids programmatic exit and web has no Shorebird; both keep the
/// banner.
final forcedRestartSupportedProvider = Provider<bool>((ref) {
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
});

/// Owns the Shorebird update lifecycle for the whole app, signed in or not.
///
/// * Mounting it starts the first patch check (cold start, before login),
///   because `auto_update` is off in `shorebird.yaml`.
/// * On login, and on every resume while signed in, re-resolves the device's
///   update channel and then re-checks Shorebird on that track. Signed out, a
///   resume re-checks on the cached track.
/// * Replaces the app with a blocking "close and reopen" screen only when
///   all of these hold: the server's live answer says `force_restart`, a
///   patch is downloaded and waiting (restartRequired with a known patch
///   number), the platform is Android, and this device has not already been
///   forced to restart for that same patch (so a patch that does not apply
///   cannot trap the device in a loop). Anything else renders [child]; the
///   regular amber banner covers the "restart to apply" case.
class ShorebirdRestartGate extends ConsumerStatefulWidget {
  const ShorebirdRestartGate({
    super.key,
    required this.isAuthenticated,
    required this.child,
  });

  final bool isAuthenticated;
  final Widget child;

  @override
  ConsumerState<ShorebirdRestartGate> createState() =>
      _ShorebirdRestartGateState();
}

class _ShorebirdRestartGateState extends ConsumerState<ShorebirdRestartGate>
    with WidgetsBindingObserver {
  bool _guardLoaded = false;
  int? _alreadyForcedPatch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadGuard());
    if (widget.isAuthenticated) {
      // Already signed in at launch (restored session): learn the channel.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_refreshChannelThenRecheck());
      });
    }
  }

  @override
  void didUpdateWidget(covariant ShorebirdRestartGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isAuthenticated && widget.isAuthenticated) {
      // Just signed in: this is the moment a manager's device learns "beta".
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_refreshChannelThenRecheck());
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (widget.isAuthenticated) {
      unawaited(_refreshChannelThenRecheck());
    } else {
      unawaited(_recheck());
    }
  }

  Future<void> _loadGuard() async {
    int? patch;
    try {
      patch = await ref
          .read(updateChannelStoreProvider)
          .readForcedRestartPatch()
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
    } catch (_) {
      patch = null;
    }
    if (!mounted) return;
    setState(() {
      _alreadyForcedPatch = patch;
      _guardLoaded = true;
    });
  }

  Future<void> _refreshChannelThenRecheck() async {
    try {
      await ref.read(updateChannelProvider.notifier).refresh();
    } catch (_) {
      // refresh never throws; belt and braces.
    }
    if (!mounted) return;
    // Coalesced with the recheck the channel listener fires on a track change.
    await _recheck();
  }

  Future<void> _recheck() async {
    try {
      await ref.read(shorebirdUpdateProvider.notifier).recheckStatus();
    } catch (_) {}
  }

  Future<void> _closeApp(int patchNumber) async {
    try {
      await ref
          .read(updateChannelStoreProvider)
          .writeForcedRestartPatch(patchNumber);
    } catch (_) {}
    ref.read(appProcessExitProvider)();
  }

  @override
  Widget build(BuildContext context) {
    // Watching is what starts the cold-start check, signed in or not.
    final status = ref.watch(shorebirdUpdateProvider).valueOrNull;
    final channel = ref.watch(updateChannelProvider).valueOrNull;
    final supported = ref.watch(forcedRestartSupportedProvider);

    if (!supported ||
        !_guardLoaded ||
        channel == null ||
        !channel.forceRestart ||
        status != ShorebirdPatchStatus.restartRequired) {
      return widget.child;
    }

    final ShorebirdDiagnostics? diagnostics = ref
        .read(shorebirdUpdateProvider.notifier)
        .lastDiagnostics;
    final pendingPatch = diagnostics?.nextPatchNumber;
    if (pendingPatch == null || pendingPatch == _alreadyForcedPatch) {
      return widget.child;
    }

    return ShorebirdForcedRestartScreen(onClose: () => _closeApp(pendingPatch));
  }
}

/// Full-screen, non-dismissible "close and reopen" prompt.
class ShorebirdForcedRestartScreen extends StatelessWidget {
  const ShorebirdForcedRestartScreen({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.restart_alt,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.shorebirdForcedRestartTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.shorebirdForcedRestartBody,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      key: const Key('shorebird-forced-restart-close'),
                      onPressed: onClose,
                      icon: const Icon(Icons.power_settings_new),
                      label: Text(l10n.shorebirdForcedRestartButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
