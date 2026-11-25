import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/config/studio_config.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_locale.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
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
        studioApiProvider.overrideWithValue(
          FakeStudioApi(role: role, delay: Duration.zero),
        ),
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
