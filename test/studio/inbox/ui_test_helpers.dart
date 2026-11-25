import 'package:jarz_pos/src/studio/core/offline/kv_store.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jarz_pos/src/studio/core/config/studio_config.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_locale.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_strings.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/core/router/studio_router.dart';
import 'package:jarz_pos/src/studio/core/theme/studio_theme.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';
import 'package:jarz_pos/src/studio/features/inbox/inbox_routes.dart';
import 'package:jarz_pos/src/studio/features/inbox/state/inbox_state.dart';
import 'package:jarz_pos/src/studio/studio_app.dart';

/// A fake API whose fixtures can be edited per key. [edits] maps a fixture key
/// (`today.get`, `decisions.list`...) to a function that changes its decoded
/// JSON. A role variant of a key is edited too.
FakeStudioApi fakeApi({
  String role = 'founder',
  Duration delay = Duration.zero,
  Map<String, void Function(dynamic json)> edits = const {},
  bool textDecisions = false,
}) {
  final fx = Map<String, String>.from(studioFixtures);
  edits.forEach((key, edit) {
    for (final k in [key, '$key.$role']) {
      final raw = fx[k];
      if (raw == null) continue;
      final json = jsonDecode(raw);
      edit(json);
      fx[k] = jsonEncode(json);
    }
  });
  return FakeStudioApi(
    role: role,
    delay: delay,
    fixtures: fx,
    textDecisions: textDecisions,
    serverLang: 'en', // the person's language is already saved: no first-open send
  );
}

/// The whole Studio with [api] as [role] in [locale]. Returns the container.
Future<ProviderContainer> pumpStudioWith(
  WidgetTester tester,
  FakeStudioApi api, {
  String locale = 'en',
  bool settle = true,
  DateTime? now,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studioFakeProvider.overrideWithValue(true),
        studioApiProvider.overrideWithValue(api),
        studioKvStoreProvider.overrideWithValue(
          MemoryKvStore({'studio.lang.device': locale}),
        ),
        studioFakeRoleProvider.overrideWithValue(api.role),
        studioLocaleProvider.overrideWith((ref) => Locale(locale)),
        if (now != null) studioNowProvider.overrideWithValue(() => now),
      ],
      child: const StudioApp(),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(StudioApp)));
}

/// A small app with only the extra Inbox routes (`inboxRoutes()`), for the
/// screens the integration step has not wired into the real router yet.
/// Pushed locations are recorded in [visited].
Future<void> pumpMini(
  WidgetTester tester,
  FakeStudioApi api, {
  required String location,
  String locale = 'en',
  List<String>? visited,
}) async {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/inbox',
        builder: (_, _) => const Scaffold(body: Text('inbox root')),
        routes: inboxRoutes(),
      ),
      GoRoute(
        path: '/:rest(.*)',
        builder: (_, state) {
          visited?.add(state.uri.toString());
          return Scaffold(body: Text('opened ${state.uri}'));
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studioFakeProvider.overrideWithValue(true),
        studioApiProvider.overrideWithValue(api),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: Locale(locale),
        theme: buildStudioTheme(locale: Locale(locale)),
        supportedLocales: StudioStrings.supportedLocales,
        localizationsDelegates: const [
          StudioStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Brand fonts and icons for goldens.
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

/// The location of the page on top, including pages opened with `push`
/// (`currentLocation` in helpers.dart only follows `go`).
String topLocation(ProviderContainer container) {
  final cfg = container
      .read(studioRouterProvider)
      .routerDelegate
      .currentConfiguration;
  final last = cfg.last.matchedLocation;
  return last;
}

/// Scrolls the first scrollable until [finder] is built and visible.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}
