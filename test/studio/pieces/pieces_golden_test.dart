import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Goldens at phone width (360 px) in English and Arabic, made with the
/// bundled brand fonts. Regenerate with `--update-goldens` on another platform.
void main() {
  setUpAll(loadGoldenFonts);

  for (final locale in ['en', 'ar']) {
    testWidgets('golden: board, $locale', (tester) async {
      await pumpFeature(tester, location: '/pieces', locale: locale);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/pieces_board_$locale.png'),
      );
    });

    testWidgets('golden: piece screen, $locale', (tester) async {
      await pumpFeature(
        tester,
        location: '/pieces/PC-00163',
        locale: locale,
        height: 1400,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/piece_screen_$locale.png'),
      );
    });
  }
}
