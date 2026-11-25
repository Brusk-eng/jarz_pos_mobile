import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/config/studio_config.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_locale.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/core/router/studio_router.dart';
import 'package:jarz_pos/src/studio/studio_app.dart';
import 'package:go_router/go_router.dart';

/// Phone-sized view (logical pixels).
void usePhone(WidgetTester tester, {double width = 390, double height = 844}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Pumps the whole Studio in fake mode as [role] (founder, lead, creator,
/// story or none), in [locale].
Future<ProviderContainer> pumpStudio(
  WidgetTester tester, {
  String role = 'founder',
  String locale = 'en',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studioFakeProvider.overrideWithValue(true),
        studioFixtureBundleProvider.overrideWithValue(fixtureBundle()),
        studioFakeRoleProvider.overrideWithValue(role),
        studioLocaleProvider.overrideWith((ref) => Locale(locale)),
      ],
      child: const StudioApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(StudioApp)));
}

/// Navigates the running app, like a deep link.
Future<void> goTo(
  WidgetTester tester,
  ProviderContainer container,
  String location,
) async {
  container.read(studioRouterProvider).go(location);
  await tester.pumpAndSettle();
}

/// The router location, for assertions.
String currentLocation(ProviderContainer container) {
  final router = container.read(studioRouterProvider);
  return router.routerDelegate.currentConfiguration.uri.toString();
}

// Re-exported so tests need only this file.
typedef Router = GoRouter;

/// The real fixture files, read synchronously into memory.
AssetBundle fixtureBundle() {
  final files = <String, String>{};
  for (final f in Directory(FakeStudioApi.fixtureDir).listSync()) {
    if (f is File && f.path.endsWith('.json')) {
      final name = f.uri.pathSegments.last;
      files['${FakeStudioApi.fixtureDir}/$name'] = f.readAsStringSync();
    }
  }
  return MemoryAssetBundle(files);
}

class MemoryAssetBundle extends CachingAssetBundle {
  MemoryAssetBundle(this.files);
  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) {
    final text = files[key];
    if (text == null) return Future.error(StateError('missing $key'));
    return SynchronousFuture(
      ByteData.sublistView(Uint8List.fromList(utf8.encode(text))),
    );
  }
}
