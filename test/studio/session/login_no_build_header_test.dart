import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/core/network/dio_provider.dart';
import 'package:jarz_pos/src/core/offline/offline_queue.dart';
import 'package:jarz_pos/src/core/session/session_manager.dart';
import 'package:jarz_pos/src/features/auth/data/auth_repository.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_locale.dart';
import 'package:jarz_pos/src/studio/core/config/studio_config.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/core/offline/kv_store.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/features/session/presentation/login_screen.dart';
import 'package:jarz_pos/src/studio/studio_app.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../helpers/mock_services.dart';
import '../helpers.dart';

/// Answers every request with 200 and keeps the headers it was sent.
class _RecordingAdapter implements HttpClientAdapter {
  final seen = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen.add(options);
    return ResponseBody.fromString(
      '{"message":"Logged In"}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() {
    dotenv.loadFromString(
      envString: 'ERP_BASE_URL=http://localhost\nFRAPPE_SITE=',
    );
    PackageInfo.setMockInitialValues(
      appName: 'Jarz',
      packageName: 'com.jarz',
      version: '1.0.0',
      buildNumber: '1234',
      buildSignature: '',
    );
  });

  ProviderContainer container({required bool studio}) {
    final c = ProviderContainer(
      overrides: [
        sessionManagerProvider.overrideWithValue(MockSessionManager()),
        offlineQueueProvider.overrideWithValue(MockOfflineQueue()),
        if (studio) ...studioRootOverrides(),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('Studio login and logout carry no build or platform header', () async {
    final c = container(studio: true);
    final adapter = _RecordingAdapter();
    c.read(dioProvider).httpClientAdapter = adapter;

    final repo = c.read(authRepositoryProvider);
    await repo.login('ali', 'x');
    await repo.logout();

    expect(adapter.seen, isNotEmpty);
    for (final o in adapter.seen) {
      expect(o.headers.containsKey(kBuildHeader), isFalse, reason: o.path);
      expect(o.headers.containsKey(kPlatformHeader), isFalse, reason: o.path);
    }
  });

  test('the POS dio still stamps the build header', () async {
    final c = container(studio: false);
    final adapter = _RecordingAdapter();
    c.read(dioProvider).httpClientAdapter = adapter;

    await c.read(authRepositoryProvider).login('ali', 'x');

    expect(adapter.seen, isNotEmpty);
    expect(adapter.seen.first.headers[kBuildHeader], '1234');
    expect(adapter.seen.first.headers[kPlatformHeader], 'android');
  });

  group('show password', () {
    Future<void> pump(WidgetTester tester, {String locale = 'en'}) async {
      usePhone(tester);
      final api = FakeStudioApi(delay: Duration.zero)
        ..failNext('session.me', 'UNAUTHENTICATED');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studioFakeProvider.overrideWithValue(true),
            studioApiProvider.overrideWithValue(api),
            studioKvStoreProvider.overrideWithValue(MemoryKvStore()),
            studioFakeRoleProvider.overrideWithValue('founder'),
            studioLocaleProvider.overrideWith((ref) => Locale(locale)),
          ],
          child: const StudioApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    bool obscured(WidgetTester tester) => tester
        .widget<EditableText>(
          find.descendant(
            of: find.byKey(const ValueKey('login-password')),
            matching: find.byType(EditableText),
          ),
        )
        .obscureText;

    testWidgets('hidden by default, the eye toggles it (English)', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byType(StudioLoginScreen), findsOneWidget);
      expect(obscured(tester), isTrue);
      expect(find.byTooltip('Show password'), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('login-password-toggle')));
      await tester.pump();
      expect(obscured(tester), isFalse);
      expect(find.byTooltip('Hide password'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('login-password-toggle')));
      await tester.pump();
      expect(obscured(tester), isTrue);
    });

    testWidgets('Arabic label', (tester) async {
      await pump(tester, locale: 'ar');
      expect(find.byTooltip('إظهار كلمة السر'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('login-password-toggle')));
      await tester.pump();
      expect(find.byTooltip('إخفاء كلمة السر'), findsOneWidget);
    });
  });
}
