import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pieces/harness.dart';

/// Goldens at phone width (360 px) in English and Arabic.
void main() {
  setUpAll(loadGoldenFonts);

  for (final locale in ['en', 'ar']) {
    testWidgets('golden: calendar week, $locale', (tester) async {
      await pumpFeature(
        tester,
        location: '/calendar',
        locale: locale,
        height: 2400,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/calendar_week_$locale.png'),
      );
    });

    testWidgets('golden: post screen, $locale', (tester) async {
      await pumpFeature(
        tester,
        location: '/calendar/post/SP-2026-00221',
        locale: locale,
        height: 1500,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/post_screen_$locale.png'),
      );
    });
  }
}
