import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/features/paid/presentation/paid_overview_screen.dart';
import 'package:jarz_pos/src/studio/features/results/presentation/scorecard_screen.dart';
import 'package:jarz_pos/src/studio/features/settings/presentation/rules_screens.dart';
import 'package:jarz_pos/src/studio/features/shell/presentation/more_screen.dart';

import 'more_test_utils.dart';

/// Goldens are rendered with the bundled brand fonts on the machine that ran
/// `flutter test --update-goldens`; regenerate if pixels differ elsewhere.
void main() {
  setUpAll(loadStudioFonts);

  for (final locale in ['en', 'ar']) {
    testWidgets('golden: More, founder, $locale, 360 px', (tester) async {
      await pumpMore(
        tester,
        const StudioMoreScreen(),
        api: FakeStudioApi(delay: Duration.zero),
        locale: locale,
        size: const Size(360, 800),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/more_$locale.png'),
      );
    });

    testWidgets('golden: paid overview, $locale, 360 px', (tester) async {
      await pumpMore(
        tester,
        const PaidOverviewScreen(),
        locale: locale,
        size: const Size(360, 1500),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/paid_overview_$locale.png'),
      );
    });

    testWidgets('golden: scorecard, $locale, 360 px', (tester) async {
      await pumpMore(
        tester,
        const ScorecardScreen(),
        locale: locale,
        size: const Size(360, 2000),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/scorecard_$locale.png'),
      );
    });

    testWidgets('golden: rules list, $locale, 360 px', (tester) async {
      await pumpMore(
        tester,
        const RulesScreen(),
        locale: locale,
        size: const Size(360, 700),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/rules_$locale.png'),
      );
    });
  }
}
