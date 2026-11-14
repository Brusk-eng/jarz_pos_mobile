import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:jarz_pos/src/core/monitoring/sentry_service.dart';
import 'package:jarz_pos/src/features/update_channel/data/update_channel.dart';
import 'package:jarz_pos/src/features/about/data/about_release_info_repository.dart';

void main() {
  group('AboutReleaseInfoRepository', () {
    test(
      'should map package and release diagnostics when shorebird data is available',
      () async {
        // Arrange
        final repository = AboutReleaseInfoRepository(
          loadPackageInfo: () async => PackageInfo(
            appName: 'Jarz POS',
            packageName: 'com.orderjarz.pos',
            version: '1.2.3',
            buildNumber: '42',
          ),
          shorebirdStatusReader: const _FakeShorebirdStatusReader(
            ShorebirdDiagnostics(
              status: ShorebirdPatchStatus.updateAvailable,
              currentPatchNumber: 7,
              nextPatchNumber: 8,
            ),
          ),
          currentHostReader: () => 'erpstg.orderjarz.com',
          now: () => DateTime.utc(2026, 5, 30, 10),
          platformLabelReader: () => 'Android',
          sentryConfigLoader: (appEnvironment) => const SentryRuntimeConfig(
            dsn: '',
            environment: 'staging',
            release: 'staging-v1.2.3+42-abc1234',
            dist: '42',
            tracesSampleRate: 0,
            profilesSampleRate: 0,
          ),
        );

        // Act
        final result = await repository.fetchReleaseInfo(track: PatchTrack.stable);

        // Assert
        expect(result.appName, 'Jarz POS');
        expect(result.packageName, 'com.orderjarz.pos');
        expect(result.buildName, '1.2.3');
        expect(result.buildNumber, '42');
        expect(result.platformLabel, 'Android');
        expect(result.environment, 'staging');
        expect(result.releaseId, 'staging-v1.2.3+42-abc1234');
        expect(result.releaseDist, '42');
        expect(result.shorebird.status, ShorebirdPatchStatus.updateAvailable);
        expect(result.shorebird.currentPatchNumber, 7);
        expect(result.shorebird.nextPatchNumber, 8);
        expect(result.lastCheckedAt, DateTime.utc(2026, 5, 30, 10));
      },
    );

    test(
      'should preserve unavailable shorebird status for unsupported surfaces',
      () async {
        // Arrange
        final repository = AboutReleaseInfoRepository(
          loadPackageInfo: () async => PackageInfo(
            appName: 'Jarz POS',
            packageName: 'com.orderjarz.pos.web',
            version: '1.2.3',
            buildNumber: '42',
          ),
          shorebirdStatusReader: const _FakeShorebirdStatusReader(
            ShorebirdDiagnostics(status: ShorebirdPatchStatus.unavailable),
          ),
          currentHostReader: () => 'erp.orderjarz.com',
          platformLabelReader: () => 'Web',
          sentryConfigLoader: (appEnvironment) =>
              const SentryRuntimeConfig.disabled(environment: 'production'),
        );

        // Act
        final result = await repository.fetchReleaseInfo(track: PatchTrack.stable);

        // Assert
        expect(result.platformLabel, 'Web');
        expect(result.environment, 'production');
        expect(result.shorebird.status, ShorebirdPatchStatus.unavailable);
        expect(result.shorebird.currentPatchNumber, isNull);
      },
    );

    test(
      'should report a healthy base release (no patch) as up to date',
      () async {
        // Arrange
        final repository = AboutReleaseInfoRepository(
          loadPackageInfo: () async => PackageInfo(
            appName: 'Jarz POS',
            packageName: 'com.orderjarz.pos',
            version: '1.2.3',
            buildNumber: '42',
          ),
          shorebirdStatusReader: const _FakeShorebirdStatusReader(
            ShorebirdDiagnostics(status: ShorebirdPatchStatus.upToDate),
          ),
          currentHostReader: () => 'erp.orderjarz.com',
          platformLabelReader: () => 'Android',
          sentryConfigLoader: (appEnvironment) =>
              const SentryRuntimeConfig.disabled(environment: 'production'),
        );

        // Act
        final result = await repository.fetchReleaseInfo(track: PatchTrack.stable);

        // Assert
        expect(result.shorebird.status, ShorebirdPatchStatus.upToDate);
        expect(result.shorebird.currentPatchNumber, isNull);
      },
    );

    test(
      'should preserve the error message when patch status is unknown',
      () async {
        // Arrange
        final repository = AboutReleaseInfoRepository(
          loadPackageInfo: () async => PackageInfo(
            appName: 'Jarz POS',
            packageName: 'com.orderjarz.pos',
            version: '1.2.3',
            buildNumber: '42',
          ),
          shorebirdStatusReader: const _FakeShorebirdStatusReader(
            ShorebirdDiagnostics(
              status: ShorebirdPatchStatus.unknown,
              errorMessage: 'boom',
            ),
          ),
          currentHostReader: () => 'erp.orderjarz.com',
          platformLabelReader: () => 'Android',
          sentryConfigLoader: (appEnvironment) =>
              const SentryRuntimeConfig.disabled(environment: 'production'),
        );

        // Act
        final result = await repository.fetchReleaseInfo(track: PatchTrack.stable);

        // Assert
        expect(result.shorebird.status, ShorebirdPatchStatus.unknown);
        expect(result.shorebird.errorMessage, 'boom');
      },
    );
  });
}

class _FakeShorebirdStatusReader implements ShorebirdStatusReader {
  const _FakeShorebirdStatusReader(this.result);

  final ShorebirdDiagnostics result;

  @override
  Future<ShorebirdDiagnostics> readStatus({required PatchTrack track}) async =>
      result;
}
