import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/config/studio_config.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_labels.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_locale.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_strings.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/core/offline/kv_store.dart';
import 'package:jarz_pos/src/studio/core/offline/reachability.dart';
import 'package:jarz_pos/src/studio/core/theme/studio_theme.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/models/studio_enums.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';
import 'package:jarz_pos/src/studio/shared/bidi_text.dart';
import 'package:jarz_pos/src/studio/studio_app.dart';

import 'helpers.dart';
import 'more/more_test_utils.dart' show loadStudioFonts;

const _a = '\u2068';
const _b = '\u2069';

Future<ProviderContainer> _app(
  WidgetTester tester,
  FakeStudioApi api, {
  MemoryKvStore? kv,
  String locale = 'en',
}) async {
  usePhone(tester, height: 1600);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studioFakeProvider.overrideWithValue(true),
        studioApiProvider.overrideWithValue(api),
        studioFakeRoleProvider.overrideWithValue(api.role),
        studioLocaleProvider.overrideWith((ref) => Locale(locale)),
        studioKvStoreProvider.overrideWithValue(kv ?? MemoryKvStore()),
        reachabilityIntervalProvider.overrideWithValue(null),
        reachabilityProbeProvider.overrideWithValue(() async => true),
      ],
      child: const StudioApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(StudioApp)));
}

FakeStudioApi _api({String? serverLang}) => FakeStudioApi(
  delay: Duration.zero,
  textDecisions: true,
  serverLang: serverLang,
);

void main() {
  group('13. The language and the lines the server words', () {
    test('NotificationPrefs reads with and without lang', () {
      final base = {
        'quiet_from': null,
        'quiet_to': null,
        'digest_enabled': true,
        'digest_time': '08:00',
        'events': <dynamic>[],
      };
      expect(NotificationPrefs.fromJson(base).lang, isNull);
      expect(
        NotificationPrefs.fromJson({...base, 'lang': 'ar'}).lang,
        StudioLang.ar,
      );
      expect(
        NotificationPrefs.fromJson({...base, 'lang': null}).lang,
        isNull,
      );
    });

    testWidgets('switching to Arabic is saved and changes a server-worded Today line', (
      tester,
    ) async {
      final api = _api(serverLang: 'en');
      final c = await _app(tester, api, kv: MemoryKvStore({'studio.lang.device': 'en'}));
      expect(find.textContaining('waiting 2 days'), findsWidgets);
      c.read(studioLocaleProvider.notifier).state = const Locale('ar');
      await tester.pumpAndSettle();
      final sent = api.callLog.lastWhere(
        (x) => x.key == 'settings.set_my_notifications',
      );
      expect(sent.params['lang'], 'ar');
      expect(api.serverLang, 'ar');
      expect(find.textContaining('waiting 2 days'), findsNothing);
      expect(find.textContaining('مستني من 2 يوم'), findsWidgets);
    });

    testWidgets('nothing stored anywhere: the app language is sent once', (
      tester,
    ) async {
      final api = _api();
      await _app(tester, api);
      expect(api.serverLang, 'en');
      expect(
        api.calls.where((k) => k == 'settings.set_my_notifications').length,
        1,
      );
    });

    testWidgets('the server has a language and the device none: adopt it', (
      tester,
    ) async {
      final api = _api(serverLang: 'ar');
      final kv = MemoryKvStore();
      final c = await _app(tester, api, kv: kv);
      expect(c.read(studioLocaleProvider).languageCode, 'ar');
      expect(kv.data['studio.lang.device'], 'ar');
      expect(api.calls, isNot(contains('settings.set_my_notifications')));
    });

    testWidgets('both exist and differ: the device wins and is sent', (
      tester,
    ) async {
      final api = _api(serverLang: 'ar');
      final c = await _app(
        tester,
        api,
        kv: MemoryKvStore({'studio.lang.device': 'en'}),
      );
      expect(c.read(studioLocaleProvider).languageCode, 'en');
      expect(api.serverLang, 'en');
    });

    testWidgets('offline: the switch does not wait, the send is kept pending', (
      tester,
    ) async {
      final api = _api(serverLang: 'en')
        ..failAlways('settings.set_my_notifications', 'SERVER_ERROR');
      final kv = MemoryKvStore({'studio.lang.device': 'en'});
      final c = await _app(tester, api, kv: kv);
      c.read(studioLocaleProvider.notifier).state = const Locale('ar');
      await tester.pumpAndSettle();
      expect(c.read(studioLocaleProvider).languageCode, 'ar');
      expect(kv.data['studio.lang.pending'], 'ar');
    });

    test('a bad language is refused by the server', () async {
      final api = _api();
      expect(
        () => api.settingsSetMyNotifications(lang: 'fr'),
        throwsA(isA<StudioValidation>()),
      );
    });

    test('isolate marks never reach the clipboard', () {
      expect(withoutBidiIsolates('${_a}Mango$_b caption'), 'Mango caption');
      expect(
        withoutBidiIsolates('\u2066x\u2067y\u2068z\u2069'),
        'xyz',
      );
    });
  });

  group('14. Problem and check lines by code', () {
    test('known codes are worded in both languages', () {
      final en = StudioLabels.forLanguage('en');
      final ar = StudioLabels.forLanguage('ar');
      expect(
        en.problem('no_script', message: 'server'),
        'Write the script first.',
      );
      expect(ar.problem('no_script', message: 'server'), isNot('server'));
      // A code with names in its message keeps the server's English line.
      expect(en.problem('R2', message: 'Carrot Cake is paused'), 'Carrot Cake is paused');
      expect(ar.problem('R2', message: 'Carrot Cake is paused'), contains('flavor'));
    });

    test('an unknown code falls back to the server message', () {
      expect(
        StudioLabels.forLanguage('ar').problem('brand_new', message: 'As sent'),
        'As sent',
      );
    });
  });

  group('Isolate marks render as nothing', () {
    setUpAll(loadStudioFonts);

    for (final locale in ['en', 'ar']) {
      testWidgets('golden: a line with isolates, $locale', (tester) async {
        usePhone(tester, width: 360, height: 200);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildStudioTheme(locale: Locale(locale)),
            locale: Locale(locale),
            supportedLocales: StudioStrings.supportedLocales,
            localizationsDelegates: const [
              StudioStrings.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale == 'ar'
                          ? 'قطعة $_a#3 Thank you, me$_b مستنية منذ يومين'
                          : 'Piece $_a#3 Thank you, me$_b waiting 2 days',
                    ),
                    Text(
                      locale == 'ar'
                          ? 'ملف ${_a}Mango and Pistachio$_b جاهز'
                          : 'File ${_a}Mango and Pistachio$_b is ready',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/isolate_marks_$locale.png'),
        );
      });
    }
  });
}
