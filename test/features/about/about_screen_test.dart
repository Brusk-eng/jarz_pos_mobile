import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/core/monitoring/sentry_service.dart';
import 'package:jarz_pos/src/features/update_channel/data/update_channel.dart';
import 'package:jarz_pos/src/features/about/data/about_release_info_repository.dart';
import 'package:jarz_pos/src/features/about/presentation/providers/about_release_info_provider.dart';
import 'package:jarz_pos/src/features/about/presentation/screens/about_screen.dart';
import 'package:jarz_pos/src/features/update_channel/state/update_channel_provider.dart';

import '../update_channel/update_channel_fakes.dart';

void main() {
  group('AboutScreen', () {
    testWidgets(
      'should render version, build, release, and patch diagnostics',
      (tester) async {
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
            ),
          ),
          platformLabelReader: () => 'Android',
          now: () => DateTime.utc(2026, 5, 30, 10, 30),
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
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              aboutReleaseInfoRepositoryProvider.overrideWithValue(repository),
              updateChannelStoreProvider.overrideWithValue(
                MemoryUpdateChannelStore(),
              ),
            ],
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: const AboutScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Jarz POS'), findsOneWidget);
        expect(find.text('1.2.3'), findsOneWidget);
        expect(find.text('42'), findsWidgets);
        expect(find.text('staging-v1.2.3+42-abc1234'), findsOneWidget);
        expect(find.text('Update available'), findsOneWidget);
        expect(find.text('7'), findsOneWidget);
      },
    );

    testWidgets(
      'should render a healthy base release as up to date with no patch number',
      (tester) async {
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
          platformLabelReader: () => 'Android',
          now: () => DateTime.utc(2026, 5, 30, 10, 30),
          sentryConfigLoader: (appEnvironment) =>
              const SentryRuntimeConfig.disabled(environment: 'production'),
        );

        // Act
        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Up to date'), findsOneWidget);
        expect(find.text('Base release only'), findsOneWidget);
      },
    );

    testWidgets(
      'should surface the error detail when patch status is unknown',
      (tester) async {
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
              errorMessage: 'updater offline',
            ),
          ),
          platformLabelReader: () => 'Android',
          now: () => DateTime.utc(2026, 5, 30, 10, 30),
          sentryConfigLoader: (appEnvironment) =>
              const SentryRuntimeConfig.disabled(environment: 'production'),
        );

        // Act
        await tester.pumpWidget(_wrap(repository));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Unknown'), findsOneWidget);
        expect(find.text('Patch check error'), findsOneWidget);
        expect(find.text('updater offline'), findsOneWidget);
      },
    );
  });
}

Widget _wrap(AboutReleaseInfoRepository repository) {
  return ProviderScope(
    overrides: [
      aboutReleaseInfoRepositoryProvider.overrideWithValue(repository),
      updateChannelStoreProvider.overrideWithValue(MemoryUpdateChannelStore()),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AboutScreen(),
    ),
  );
}

class _FakeShorebirdStatusReader implements ShorebirdStatusReader {
  const _FakeShorebirdStatusReader(this.result);

  final ShorebirdDiagnostics result;

  @override
  Future<ShorebirdDiagnostics> readStatus({required PatchTrack track}) async =>
      result;
}
