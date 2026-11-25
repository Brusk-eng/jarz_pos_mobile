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
import 'package:jarz_pos/src/studio/core/theme/studio_theme.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';
import 'package:jarz_pos/src/studio/features/shell/more_routes.dart';
import 'package:jarz_pos/src/studio/features/shell/presentation/more_screen.dart';
import 'package:jarz_pos/src/studio/shared/media/studio_media_widgets.dart';
import 'package:jarz_pos/src/studio/shared/studio_toast.dart';

/// Loads the brand fonts so goldens look like the app. Call from `setUpAll`.
Future<void> loadStudioFonts() async {
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

/// The shipped fixtures with some of them changed: each entry maps a fixture
/// key to a function that gets the decoded JSON and returns the new JSON.
Map<String, String> patchFixtures(
  Map<String, dynamic Function(dynamic json)> patches,
) {
  final out = {...studioFixtures};
  patches.forEach((key, fn) {
    out[key] = jsonEncode(fn(jsonDecode(out[key]!)));
  });
  return out;
}

/// The fixture [key] decoded (to build a `current` object or a variant).
dynamic fixtureJson(String key) => jsonDecode(studioFixtures[key]!);

/// A fake API that remembers every call with its parameters, and can answer
/// some calls itself (for paging).
class RecordingApi extends FakeStudioApi {
  RecordingApi({super.role, super.fixtures}) : super(delay: Duration.zero);

  final List<({String fn, Map<String, dynamic> params})> log = [];

  /// `group.fn` to a function that answers instead of the fixture.
  final Map<String, dynamic Function(Map<String, dynamic> params)> respond = {};

  List<Map<String, dynamic>> calls_(String fn) => [
    for (final c in log)
      if (c.fn == fn) c.params,
  ];

  Map<String, dynamic>? last(String fn) {
    final all = calls_(fn);
    return all.isEmpty ? null : all.last;
  }

  int count(String fn) => calls_(fn).length;

  @override
  Future<dynamic> call(
    String method, {
    Map<String, dynamic>? params,
    bool get = false,
  }) {
    final fn = method.replaceFirst(studioMethodPrefix, '');
    log.add((fn: fn, params: params ?? const {}));
    final answer = respond[fn];
    if (answer != null) {
      return Future.value(
        jsonDecode(jsonEncode(answer(params ?? const <String, dynamic>{}))),
      );
    }
    return super.call(method, params: params, get: get);
  }
}

ThemeData _theme(String locale) => buildStudioTheme(locale: Locale(locale));

const _delegates = <LocalizationsDelegate<dynamic>>[
  StudioStrings.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Pumps [child] alone, in the Studio theme, with [api] (default: the founder
/// fake) at [locale] and phone [size].
Future<ProviderContainer> pumpMore(
  WidgetTester tester,
  Widget child, {
  StudioApi? api,
  String locale = 'en',
  Size size = const Size(360, 740),
  List<Uri>? opened,
  bool openResult = true,
  bool fake = true,
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studioApiProvider.overrideWithValue(
          api ?? FakeStudioApi(delay: Duration.zero),
        ),
        studioFakeProvider.overrideWithValue(fake),
        studioLocaleProvider.overrideWith((ref) => Locale(locale)),
        studioLinkOpenerProvider.overrideWithValue((u) async {
          opened?.add(u);
          return openResult;
        }),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final l = ref.watch(studioLocaleProvider);
          return MaterialApp(
        scaffoldMessengerKey: studioMessengerKey,
            debugShowCheckedModeBanner: false,
            theme: _theme(l.languageCode),
            locale: l,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: _delegates,
            home: child,
          );
        },
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

/// Pumps a router with `/more` (the real More screen) and [moreRoutes] as its
/// children, plus stubs for the screens other workers build.
Future<({ProviderContainer container, GoRouter router})> pumpMoreRouter(
  WidgetTester tester, {
  String location = '/more',
  StudioApi? api,
  String locale = 'en',
  Size size = const Size(360, 740),
  List<Uri>? opened,
  bool fake = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  Widget stub(String name) => Scaffold(
    appBar: AppBar(title: Text(name)),
    body: Center(child: Text(name, key: ValueKey('stub-$name'))),
  );

  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/more',
        builder: (_, _) => const StudioMoreScreen(),
        routes: [...moreRoutes()],
      ),
      GoRoute(path: '/shoots', builder: (_, _) => stub('shoots')),
      GoRoute(path: '/assets', builder: (_, _) => stub('library')),
      GoRoute(
        path: '/inbox/notifications/settings',
        builder: (_, _) => stub('notification-settings'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studioApiProvider.overrideWithValue(
          api ?? FakeStudioApi(delay: Duration.zero),
        ),
        studioFakeProvider.overrideWithValue(fake),
        studioLocaleProvider.overrideWith((ref) => Locale(locale)),
        studioLinkOpenerProvider.overrideWithValue((u) async {
          opened?.add(u);
          return true;
        }),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final l = ref.watch(studioLocaleProvider);
          return MaterialApp.router(
        scaffoldMessengerKey: studioMessengerKey,
            debugShowCheckedModeBanner: false,
            theme: _theme(l.languageCode),
            locale: l,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: _delegates,
            routerConfig: router,
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  return (container: container, router: router);
}

/// The router location, for assertions.
String where(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();

/// Taps by key and settles.
Future<void> tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Types into the text field with [key].
Future<void> typeKey(WidgetTester tester, String key, String text) async {
  await tester.enterText(find.byKey(ValueKey(key)), text);
  await tester.pump();
}

/// Text of the snack bar on screen, or null.
String? snackText(WidgetTester tester) {
  final f = find.descendant(
    of: find.byType(SnackBar),
    matching: find.byType(Text),
  );
  if (f.evaluate().isEmpty) return null;
  return tester.widget<Text>(f.first).data;
}
