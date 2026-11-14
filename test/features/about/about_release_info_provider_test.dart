import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:jarz_pos/src/core/monitoring/sentry_service.dart';
import 'package:jarz_pos/src/features/about/data/about_release_info_repository.dart';
import 'package:jarz_pos/src/features/about/presentation/providers/about_release_info_provider.dart';
import 'package:jarz_pos/src/features/update_channel/data/update_channel.dart';
import 'package:jarz_pos/src/features/update_channel/data/update_channel_store.dart';
import 'package:jarz_pos/src/features/update_channel/state/update_channel_provider.dart';

void main() {
  group('aboutReleaseInfoProvider', () {
    test('should resolve release info from the repository override', () async {
      // Arrange
      final reader = _FakeShorebirdStatusReader(
        const ShorebirdDiagnostics(
          status: ShorebirdPatchStatus.restartRequired,
        ),
      );
      final repository = AboutReleaseInfoRepository(
        loadPackageInfo: () async => PackageInfo(
          appName: 'Jarz POS',
          packageName: 'com.orderjarz.pos',
          version: '1.2.3',
          buildNumber: '42',
        ),
        shorebirdStatusReader: reader,
        platformLabelReader: () => 'Android',
        sentryConfigLoader: (appEnvironment) =>
            const SentryRuntimeConfig.disabled(environment: 'staging'),
      );
      final container = ProviderContainer(
        overrides: [
          aboutReleaseInfoRepositoryProvider.overrideWithValue(repository),
          // This device was last resolved to the fast channel.
          updateChannelStoreProvider.overrideWithValue(
            _MemoryStore(PatchTrack.beta),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(aboutReleaseInfoProvider.future);

      // Assert
      expect(result.buildNumber, '42');
      expect(result.environment, 'staging');
      expect(result.shorebird.status, ShorebirdPatchStatus.restartRequired);
      // The About screen checks the device's own track, never the default.
      expect(reader.tracks, [PatchTrack.beta]);
    });
  });
}

class _FakeShorebirdStatusReader implements ShorebirdStatusReader {
  _FakeShorebirdStatusReader(this.result);

  final ShorebirdDiagnostics result;
  final List<PatchTrack> tracks = [];

  @override
  Future<ShorebirdDiagnostics> readStatus({required PatchTrack track}) async {
    tracks.add(track);
    return result;
  }
}

class _MemoryStore implements UpdateChannelStore {
  _MemoryStore(this.track);

  PatchTrack? track;

  @override
  Future<PatchTrack?> readTrack() async => track;

  @override
  Future<void> writeTrack(PatchTrack value) async => track = value;

  @override
  Future<int?> readForcedRestartPatch() async => null;

  @override
  Future<void> writeForcedRestartPatch(int patchNumber) async {}
}
