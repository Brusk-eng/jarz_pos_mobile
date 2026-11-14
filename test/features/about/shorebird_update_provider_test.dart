import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/features/about/data/about_release_info_repository.dart';
import 'package:jarz_pos/src/features/about/state/shorebird_update_provider.dart';
import 'package:jarz_pos/src/features/update_channel/data/update_channel.dart';
import 'package:jarz_pos/src/features/update_channel/data/update_channel_service.dart';
import 'package:jarz_pos/src/features/update_channel/state/update_channel_provider.dart';

import '../update_channel/update_channel_fakes.dart';

ProviderContainer _container(
  FakeShorebirdUpdateGateway gateway, {
  MemoryUpdateChannelStore? store,
  ScriptedUpdateChannelService? service,
}) {
  final container = ProviderContainer(
    overrides: [
      shorebirdUpdateGatewayProvider.overrideWithValue(gateway),
      updateChannelStoreProvider.overrideWithValue(
        store ?? MemoryUpdateChannelStore(),
      ),
      updateChannelServiceProvider.overrideWithValue(
        service ?? ScriptedUpdateChannelService([]),
      ),
      updateChannelFcmTokenReaderProvider.overrideWithValue(
        () async => 'fcm-token',
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('shorebirdUpdateProvider', () {
    test(
      'proactively downloads a ready patch and reports restartRequired',
      () async {
        final gateway = FakeShorebirdUpdateGateway(
          statuses: [
            ShorebirdPatchStatus.updateAvailable,
            ShorebirdPatchStatus.restartRequired,
          ],
          downloadResult: true,
        );
        final container = _container(gateway);

        final result = await container.read(shorebirdUpdateProvider.future);

        expect(result, ShorebirdPatchStatus.restartRequired);
        expect(gateway.downloadCalls, 1);
        expect(gateway.readCalls, 2);
      },
    );

    test('stays updateAvailable when the download fails', () async {
      final gateway = FakeShorebirdUpdateGateway(
        statuses: [ShorebirdPatchStatus.updateAvailable],
        downloadResult: false,
      );
      final container = _container(gateway);

      final result = await container.read(shorebirdUpdateProvider.future);

      expect(result, ShorebirdPatchStatus.updateAvailable);
      expect(gateway.downloadCalls, 1);
    });

    test('does not download when already up to date', () async {
      final gateway = FakeShorebirdUpdateGateway(
        statuses: [ShorebirdPatchStatus.upToDate],
        downloadResult: true,
      );
      final container = _container(gateway);

      final result = await container.read(shorebirdUpdateProvider.future);

      expect(result, ShorebirdPatchStatus.upToDate);
      expect(gateway.downloadCalls, 0);
    });

    test(
      'recheckStatus re-resolves and downloads a newly available patch',
      () async {
        final gateway = FakeShorebirdUpdateGateway(
          statuses: [
            // Initial build: nothing to do.
            ShorebirdPatchStatus.upToDate,
            // After resume: a patch appears, gets downloaded, then restartRequired.
            ShorebirdPatchStatus.updateAvailable,
            ShorebirdPatchStatus.restartRequired,
          ],
          downloadResult: true,
        );
        final container = _container(gateway);

        final initial = await container.read(shorebirdUpdateProvider.future);
        expect(initial, ShorebirdPatchStatus.upToDate);

        await container.read(shorebirdUpdateProvider.notifier).recheckStatus();
        final after = container.read(shorebirdUpdateProvider).valueOrNull;

        expect(after, ShorebirdPatchStatus.restartRequired);
        expect(gateway.downloadCalls, 1);
      },
    );
  });

  group('shorebirdUpdateProvider track', () {
    test('uses "stable" when nothing is cached (today\'s behaviour)', () async {
      final gateway = FakeShorebirdUpdateGateway(
        statuses: [
          ShorebirdPatchStatus.updateAvailable,
          ShorebirdPatchStatus.restartRequired,
        ],
        downloadResult: true,
      );
      final container = _container(gateway);

      await container.read(shorebirdUpdateProvider.future);

      expect(gateway.readTracks, everyElement(PatchTrack.stable));
      expect(gateway.downloadTracks, [PatchTrack.stable]);
    });

    test('uses "stable" when the cache cannot be read', () async {
      final gateway = FakeShorebirdUpdateGateway(
        statuses: [
          ShorebirdPatchStatus.updateAvailable,
          ShorebirdPatchStatus.restartRequired,
        ],
        downloadResult: true,
      );
      final container = _container(
        gateway,
        store: MemoryUpdateChannelStore(throwOnRead: true),
      );

      await container.read(shorebirdUpdateProvider.future);

      expect(gateway.readTracks, everyElement(PatchTrack.stable));
      expect(gateway.downloadTracks, [PatchTrack.stable]);
    });

    test(
      'cold start (before login) checks and downloads on the cached track',
      () async {
        final gateway = FakeShorebirdUpdateGateway(
          statuses: [
            ShorebirdPatchStatus.updateAvailable,
            ShorebirdPatchStatus.restartRequired,
          ],
          downloadResult: true,
        );
        final service = ScriptedUpdateChannelService([]);
        final container = _container(
          gateway,
          store: MemoryUpdateChannelStore(track: PatchTrack.beta),
          service: service,
        );

        await container.read(shorebirdUpdateProvider.future);

        expect(gateway.readTracks, [PatchTrack.beta, PatchTrack.beta]);
        expect(gateway.downloadTracks, [PatchTrack.beta]);
        // No server call is needed for the cold-start check.
        expect(service.calls, 0);
      },
    );

    test('a track change from the server re-checks on the new track', () async {
      final gateway = FakeShorebirdUpdateGateway(
        statuses: [
          ShorebirdPatchStatus.upToDate,
          ShorebirdPatchStatus.updateAvailable,
          ShorebirdPatchStatus.restartRequired,
        ],
        downloadResult: true,
      );
      final container = _container(
        gateway,
        service: ScriptedUpdateChannelService([
          const UpdateChannel(
            track: PatchTrack.beta,
            forceRestart: false,
            channel: 'fast',
            source: 'role',
          ),
        ]),
      );
      await container.read(shorebirdUpdateProvider.future);
      expect(gateway.readTracks, [PatchTrack.stable]);

      await container.read(updateChannelProvider.notifier).refresh();
      // Let the listener-triggered recheck run to completion.
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(gateway.readTracks.skip(1), everyElement(PatchTrack.beta));
      expect(gateway.downloadTracks, [PatchTrack.beta]);
      expect(
        container.read(shorebirdUpdateProvider).valueOrNull,
        ShorebirdPatchStatus.restartRequired,
      );
    });

    test('overlapping rechecks never run two downloads at once', () async {
      final gateway = FakeShorebirdUpdateGateway(
        statuses: [
          ShorebirdPatchStatus.upToDate,
          ShorebirdPatchStatus.updateAvailable,
          ShorebirdPatchStatus.restartRequired,
        ],
        downloadResult: true,
      );
      final container = _container(gateway);
      await container.read(shorebirdUpdateProvider.future);

      final notifier = container.read(shorebirdUpdateProvider.notifier);
      await Future.wait([
        notifier.recheckStatus(),
        notifier.recheckStatus(),
        notifier.recheckStatus(),
      ]);

      expect(gateway.downloadCalls, 1);
      expect(
        container.read(shorebirdUpdateProvider).valueOrNull,
        ShorebirdPatchStatus.restartRequired,
      );
    });

    test('keeps the previous value while a recheck is loading', () async {
      final gateway = FakeShorebirdUpdateGateway(
        statuses: [ShorebirdPatchStatus.restartRequired],
        downloadResult: true,
      );
      final container = _container(gateway);
      await container.read(shorebirdUpdateProvider.future);

      final pending = container
          .read(shorebirdUpdateProvider.notifier)
          .recheckStatus();
      final during = container.read(shorebirdUpdateProvider);
      expect(during.isLoading, isTrue);
      expect(during.valueOrNull, ShorebirdPatchStatus.restartRequired);
      await pending;
    });
  });
}
