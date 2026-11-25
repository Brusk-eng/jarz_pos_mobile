import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jarz_pos/src/studio/core/config/studio_config.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_strings.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/core/theme/studio_theme.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';
import 'package:jarz_pos/src/studio/features/calendar/calendar_routes.dart';
import 'package:jarz_pos/src/studio/features/calendar/state/calendar_state.dart';
import 'package:jarz_pos/src/studio/features/pieces/pieces_routes.dart';
import 'package:jarz_pos/src/studio/features/session/state/studio_session_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jarz_pos/src/studio/shared/studio_toast.dart';

/// The day the fixtures were made for: the calendar fixture covers the week
/// that starts on Saturday 21 Nov 2026.
final fixtureToday = DateTime(2026, 11, 25);

/// The contract fixtures with some entries changed. [patches] maps a fixture
/// key (`pieces.get`) to a function that edits its decoded JSON.
Map<String, String> patchedFixtures([
  Map<String, void Function(dynamic json)> patches = const {},
]) {
  final out = Map<String, String>.from(studioFixtures);
  patches.forEach((key, edit) {
    final json = jsonDecode(out[key]!);
    edit(json);
    out[key] = jsonEncode(json);
  });
  return out;
}

class StudioTestHarness {
  StudioTestHarness({
    required this.container,
    required this.api,
    required this.router,
  });

  final ProviderContainer container;
  final FakeStudioApi api;
  final GoRouter router;
}

Widget _stub(String text) => Scaffold(body: Center(child: Text(text)));

/// Mounts the Pieces and Calendar routes on their own, with stubs for the
/// screens other workers build (`/versions/:id`, `/shoots/...`).
Future<StudioTestHarness> pumpFeature(
  WidgetTester tester, {
  String location = '/pieces',
  String role = 'founder',
  String locale = 'en',
  Map<String, String>? fixtures,
  DateTime? today,
  double width = 360,
  double height = 780,
  FakeStudioApi? api,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final fake =
      api ??
      FakeStudioApi(role: role, delay: Duration.zero, fixtures: fixtures);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      ...piecesRoutes(),
      ...calendarRoutes(),
      GoRoute(
        path: '/versions/:id',
        builder: (_, s) => _stub('VERSION ${s.pathParameters['id']}'),
      ),
      GoRoute(path: '/shoots', builder: (_, _) => _stub('SHOOTS')),
      GoRoute(
        path: '/shoots/:id',
        builder: (_, s) => _stub('SHOOT ${s.pathParameters['id']}'),
      ),
    ],
  );
  final container = ProviderContainer(
    overrides: [
      studioFakeProvider.overrideWithValue(true),
      studioApiProvider.overrideWithValue(fake),
      studioFakeRoleProvider.overrideWithValue(role),
      calendarTodayProvider.overrideWithValue(today ?? fixtureToday),
    ],
  );
  addTearDown(container.dispose);
  // The fake answers on the real clock, so load the session before the first
  // frame outside the test's fake async zone.
  await tester.runAsync(() => container.read(studioSessionProvider.future));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        scaffoldMessengerKey: studioMessengerKey,
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
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return StudioTestHarness(container: container, api: fake, router: router);
}

/// The router location, for assertions.
String locationOf(StudioTestHarness h) {
  final conf = h.router.routerDelegate.currentConfiguration;
  final last = conf.last;
  // A screen opened with push sits on top as an imperative match.
  if (last is ImperativeRouteMatch) return last.matches.uri.toString();
  return conf.uri.toString();
}

/// Scrolls a keyed widget into view, then taps it.
Future<void> tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Loads the brand fonts and the Material icon font so goldens show real
/// glyphs (same approach as the shell goldens).
Future<void> loadGoldenFonts() async {
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
  }

  await load('Inter', [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
  await load('DMSerifDisplay', ['assets/fonts/DMSerifDisplay-Regular.ttf']);
  await load('Tajawal', [
    'assets/fonts/Tajawal-Regular.ttf',
    'assets/fonts/Tajawal-Bold.ttf',
  ]);
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final f = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (f.existsSync()) {
      final bytes = f.readAsBytesSync();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  }
}
