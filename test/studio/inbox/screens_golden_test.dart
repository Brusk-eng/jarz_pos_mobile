import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';
import 'ui_test_helpers.dart';

/// Goldens at 360 px: Today, the Inbox hub (with its To approve list) and a
/// decision card, in English and Arabic. Made on Windows with the bundled
/// fonts; regenerate with `--update-goldens` on another platform.
void main() {
  setUpAll(loadGoldenFonts);

  final now = DateTime(2026, 11, 25, 12);

  for (final locale in ['en', 'ar']) {
    testWidgets('golden: Today, founder, 360 px, $locale', (tester) async {
      usePhone(tester, width: 360, height: 780);
      await pumpStudioWith(tester, fakeApi(), locale: locale, now: now);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../goldens/today_founder_360_$locale.png'),
      );
    });

    testWidgets('golden: Today, creator, 360 px, $locale', (tester) async {
      usePhone(tester, width: 360, height: 780);
      await pumpStudioWith(
        tester,
        fakeApi(role: 'creator'),
        locale: locale,
        now: now,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../goldens/today_creator_360_$locale.png'),
      );
    });

    testWidgets('golden: Inbox hub, 360 px, $locale', (tester) async {
      usePhone(tester, width: 360, height: 780);
      final c = await pumpStudioWith(
        tester,
        fakeApi(),
        locale: locale,
        now: now,
      );
      await goTo(tester, c, '/inbox/approve');
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../goldens/inbox_hub_360_$locale.png'),
      );
    });

    testWidgets('golden: decision card, 360 px, $locale', (tester) async {
      usePhone(tester, width: 360, height: 1500);
      final c = await pumpStudioWith(
        tester,
        fakeApi(),
        locale: locale,
        now: now,
      );
      await goTo(tester, c, '/inbox/decisions');
      await tester.tap(find.byKey(const ValueKey('option-1')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../goldens/decision_card_360_$locale.png'),
      );
    });
  }
}
