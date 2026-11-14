import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/about/data/about_release_info_repository.dart';
import 'package:jarz_pos/src/features/about/state/shorebird_update_provider.dart';
import 'package:jarz_pos/src/features/update_channel/data/update_channel.dart';
import 'package:jarz_pos/src/features/update_channel/data/update_channel_service.dart';
import 'package:jarz_pos/src/features/update_channel/presentation/shorebird_restart_gate.dart';
import 'package:jarz_pos/src/features/update_channel/state/update_channel_provider.dart';

import 'update_channel_fakes.dart';

const _forcing = UpdateChannel(
  track: PatchTrack.beta,
  forceRestart: true,
  channel: 'fast',
  source: 'role',
);

void main() {
  late int exits;

  Future<MemoryUpdateChannelStore> pump(
    WidgetTester tester, {
    required ShorebirdPatchStatus status,
    required UpdateChannel? serverAnswer,
    bool supported = true,
    bool isAuthenticated = true,
    int? nextPatch = 7,
    int? alreadyForcedPatch,
  }) async {
    exits = 0;
    final store = MemoryUpdateChannelStore(
      track: PatchTrack.beta,
      forcedPatch: alreadyForcedPatch,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shorebirdUpdateGatewayProvider.overrideWithValue(
            FakeShorebirdUpdateGateway(
              statuses: [status],
              downloadResult: false,
              nextPatchNumber: nextPatch,
            ),
          ),
          updateChannelStoreProvider.overrideWithValue(store),
          updateChannelServiceProvider.overrideWithValue(
            ScriptedUpdateChannelService([serverAnswer]),
          ),
          updateChannelFcmTokenReaderProvider.overrideWithValue(
            () async => null,
          ),
          forcedRestartSupportedProvider.overrideWithValue(supported),
          appProcessExitProvider.overrideWithValue(() => exits++),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShorebirdRestartGate(
            isAuthenticated: isAuthenticated,
            child: const Scaffold(body: Text('app-content')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  final closeButton = find.byKey(const Key('shorebird-forced-restart-close'));

  testWidgets('blocks with a close button when the server forces a restart', (
    tester,
  ) async {
    final store = await pump(
      tester,
      status: ShorebirdPatchStatus.restartRequired,
      serverAnswer: _forcing,
    );

    expect(find.text('app-content'), findsNothing);
    expect(closeButton, findsOneWidget);

    await tester.tap(closeButton);
    await tester.pumpAndSettle();

    expect(exits, 1);
    // Remembered, so the same patch can never trap the device in a loop.
    expect(store.forcedPatch, 7);
  });

  testWidgets('does not block a second time for the same patch', (
    tester,
  ) async {
    await pump(
      tester,
      status: ShorebirdPatchStatus.restartRequired,
      serverAnswer: _forcing,
      alreadyForcedPatch: 7,
    );
    expect(closeButton, findsNothing);
    expect(find.text('app-content'), findsOneWidget);
  });

  testWidgets('does not block without force_restart', (tester) async {
    await pump(
      tester,
      status: ShorebirdPatchStatus.restartRequired,
      serverAnswer: const UpdateChannel(
        track: PatchTrack.beta,
        forceRestart: false,
        channel: 'fast',
        source: 'role',
      ),
    );
    expect(closeButton, findsNothing);
    expect(find.text('app-content'), findsOneWidget);
  });

  testWidgets('does not block when the server could not be reached', (
    tester,
  ) async {
    await pump(
      tester,
      status: ShorebirdPatchStatus.restartRequired,
      serverAnswer: null,
    );
    expect(closeButton, findsNothing);
  });

  testWidgets('does not block signed out (cached channel never forces)', (
    tester,
  ) async {
    await pump(
      tester,
      status: ShorebirdPatchStatus.restartRequired,
      serverAnswer: _forcing,
      isAuthenticated: false,
    );
    expect(closeButton, findsNothing);
  });

  testWidgets('does not block when no patch is waiting', (tester) async {
    await pump(
      tester,
      status: ShorebirdPatchStatus.upToDate,
      serverAnswer: _forcing,
    );
    expect(closeButton, findsNothing);
  });

  testWidgets('does not block when the pending patch number is unknown', (
    tester,
  ) async {
    await pump(
      tester,
      status: ShorebirdPatchStatus.restartRequired,
      serverAnswer: _forcing,
      nextPatch: null,
    );
    expect(closeButton, findsNothing);
  });

  testWidgets('does not block on platforms that cannot exit (iOS/web)', (
    tester,
  ) async {
    await pump(
      tester,
      status: ShorebirdPatchStatus.restartRequired,
      serverAnswer: _forcing,
      supported: false,
    );
    expect(closeButton, findsNothing);
  });
}
