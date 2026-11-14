import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import '../../../core/env/env.dart';
import '../../../core/monitoring/sentry_service.dart';
import '../../update_channel/data/update_channel.dart';

typedef PackageInfoLoader = Future<PackageInfo> Function();
typedef CurrentHostReader = String Function();
typedef NowProvider = DateTime Function();
typedef PlatformLabelReader = String Function();
typedef SentryConfigLoader =
    SentryRuntimeConfig Function(String appEnvironment);

class AboutReleaseInfoRepository {
  AboutReleaseInfoRepository({
    PackageInfoLoader? loadPackageInfo,
    ShorebirdStatusReader? shorebirdStatusReader,
    CurrentHostReader? currentHostReader,
    NowProvider? now,
    PlatformLabelReader? platformLabelReader,
    SentryConfigLoader? sentryConfigLoader,
  }) : _loadPackageInfo = loadPackageInfo ?? (() => PackageInfo.fromPlatform()),
       _shorebirdStatusReader =
           shorebirdStatusReader ?? DefaultShorebirdStatusReader(),
       _currentHostReader = currentHostReader ?? _defaultCurrentHostReader,
       _now = now ?? DateTime.now,
       _platformLabelReader = platformLabelReader ?? readAboutPlatformLabel,
       _sentryConfigLoader =
           sentryConfigLoader ??
           ((appEnvironment) => SentryRuntimeConfig.fromEnvironment(
             appEnvironment: appEnvironment,
           ));

  final PackageInfoLoader _loadPackageInfo;
  final ShorebirdStatusReader _shorebirdStatusReader;
  final CurrentHostReader _currentHostReader;
  final NowProvider _now;
  final PlatformLabelReader _platformLabelReader;
  final SentryConfigLoader _sentryConfigLoader;

  /// [track] is the device's resolved Shorebird track. It is required so the
  /// About screen can never check a different track than the auto-updater.
  Future<AboutReleaseInfo> fetchReleaseInfo({required PatchTrack track}) async {
    final packageInfo = await _loadPackageInfo();
    final appEnvironment = resolveEnvName(currentHost: _currentHostReader());
    final sentryConfig = _sentryConfigLoader(appEnvironment);
    final shorebirdDiagnostics = await _shorebirdStatusReader.readStatus(
      track: track,
    );

    return AboutReleaseInfo(
      appName: packageInfo.appName,
      packageName: packageInfo.packageName,
      buildName: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      platformLabel: _platformLabelReader(),
      environment: sentryConfig.environment,
      releaseId: sentryConfig.release,
      releaseDist: sentryConfig.dist,
      shorebird: shorebirdDiagnostics,
      lastCheckedAt: _now(),
    );
  }

  static String _defaultCurrentHostReader() => Uri.base.host;
}

class AboutReleaseInfo {
  const AboutReleaseInfo({
    required this.appName,
    required this.packageName,
    required this.buildName,
    required this.buildNumber,
    required this.platformLabel,
    required this.environment,
    required this.releaseId,
    required this.releaseDist,
    required this.shorebird,
    required this.lastCheckedAt,
  });

  final String appName;
  final String packageName;
  final String buildName;
  final String buildNumber;
  final String platformLabel;
  final String environment;
  final String releaseId;
  final String releaseDist;
  final ShorebirdDiagnostics shorebird;
  final DateTime lastCheckedAt;
}

enum ShorebirdPatchStatus {
  upToDate,
  updateAvailable,
  restartRequired,
  unavailable,
  unknown,
}

class ShorebirdDiagnostics {
  const ShorebirdDiagnostics({
    required this.status,
    this.currentPatchNumber,
    this.nextPatchNumber,
    this.errorMessage,
  });

  final ShorebirdPatchStatus status;
  final int? currentPatchNumber;
  final int? nextPatchNumber;
  final String? errorMessage;
}

abstract class ShorebirdStatusReader {
  /// [track] is required on purpose: with `auto_update: false` the app is the
  /// only thing that talks to Shorebird, and a call without a track would
  /// silently check (and on a fast device, pull) the "stable" patch.
  Future<ShorebirdDiagnostics> readStatus({required PatchTrack track});
}

/// Maps the app's track to Shorebird's. Only "stable" and "beta" exist.
UpdateTrack shorebirdTrackFor(PatchTrack track) => switch (track) {
  PatchTrack.beta => UpdateTrack.beta,
  PatchTrack.stable => UpdateTrack.stable,
};

class DefaultShorebirdStatusReader implements ShorebirdStatusReader {
  const DefaultShorebirdStatusReader();

  @override
  Future<ShorebirdDiagnostics> readStatus({required PatchTrack track}) async {
    if (!_supportsShorebird()) {
      return const ShorebirdDiagnostics(
        status: ShorebirdPatchStatus.unavailable,
      );
    }

    final updater = ShorebirdUpdater();
    if (!updater.isAvailable) {
      // The app was not built with `shorebird release` (no Shorebird engine is
      // embedded), so there is no updater to query. Report unavailable instead
      // of letting the queries below throw and surface as "unknown".
      return const ShorebirdDiagnostics(
        status: ShorebirdPatchStatus.unavailable,
      );
    }

    try {
      final updateStatus = await updater.checkForUpdate(
        track: shorebirdTrackFor(track),
      );
      final currentPatch = await updater.readCurrentPatch();
      final nextPatch = await updater.readNextPatch();

      return ShorebirdDiagnostics(
        status: switch (updateStatus) {
          UpdateStatus.upToDate => ShorebirdPatchStatus.upToDate,
          UpdateStatus.outdated => ShorebirdPatchStatus.updateAvailable,
          UpdateStatus.restartRequired => ShorebirdPatchStatus.restartRequired,
          UpdateStatus.unavailable => ShorebirdPatchStatus.unavailable,
        },
        currentPatchNumber: currentPatch?.number,
        nextPatchNumber: nextPatch?.number,
      );
    } catch (error) {
      return ShorebirdDiagnostics(
        status: ShorebirdPatchStatus.unknown,
        errorMessage: error.toString(),
      );
    }
  }

  bool _supportsShorebird() {
    if (kIsWeb) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }
}

/// Read + download surface used by the in-app auto-updater.
///
/// Kept separate from [ShorebirdStatusReader] (read-only, used by the About
/// screen) so that adding a download capability here never forces the
/// read-only fakes to implement it.
abstract class ShorebirdUpdateGateway {
  Future<ShorebirdDiagnostics> readStatus({required PatchTrack track});

  /// Downloads the newest available patch immediately (instead of waiting for
  /// the next app launch). Returns `true` when a patch was downloaded, so the
  /// caller can re-read status — which will then report
  /// [ShorebirdPatchStatus.restartRequired]. Never throws.
  ///
  /// [track] must be the same track [readStatus] was asked about.
  Future<bool> downloadUpdate({required PatchTrack track});
}

class DefaultShorebirdUpdateGateway implements ShorebirdUpdateGateway {
  const DefaultShorebirdUpdateGateway();

  @override
  Future<ShorebirdDiagnostics> readStatus({required PatchTrack track}) =>
      const DefaultShorebirdStatusReader().readStatus(track: track);

  @override
  Future<bool> downloadUpdate({required PatchTrack track}) async {
    if (kIsWeb) {
      return false;
    }
    final supported = switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
    if (!supported) {
      return false;
    }

    final updater = ShorebirdUpdater();
    if (!updater.isAvailable) {
      return false;
    }

    try {
      await updater.update(track: shorebirdTrackFor(track));
      return true;
    } catch (_) {
      // Network hiccup, no-longer-available race, or engine error: stay on the
      // current patch and let the next check retry. Never surface to the UI.
      return false;
    }
  }
}

String readAboutPlatformLabel() {
  if (kIsWeb) {
    return 'Web';
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'Android',
    TargetPlatform.iOS => 'iOS',
    TargetPlatform.macOS => 'macOS',
    TargetPlatform.linux => 'Linux',
    TargetPlatform.windows => 'Windows',
    TargetPlatform.fuchsia => 'Fuchsia',
  };
}
