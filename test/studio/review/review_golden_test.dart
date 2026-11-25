import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/features/review/presentation/rate_feed_screen.dart';
import 'package:jarz_pos/src/studio/features/review/presentation/version_screen.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';

import 'review_test_utils.dart';

/// Goldens are rendered with the bundled brand fonts on the machine that ran
/// `flutter test --update-goldens`; regenerate if pixels differ elsewhere.
Future<void> _loadFonts() async {
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

void main() {
  setUpAll(_loadFonts);

  for (final locale in ['en', 'ar']) {
    testWidgets('golden: version screen, founder, $locale, 360 px', (
      tester,
    ) async {
      final api = RoleApi();
      await pumpReview(
        tester,
        const VersionScreen(versionId: 'PC-00163-v2'),
        api: api,
        locale: locale,
        size: const Size(360, 1700),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/version_$locale.png'),
      );
    });

    testWidgets('golden: rating feed, $locale, 360 px', (tester) async {
      final api = FeedApi({
        null: RateCardPage(items: await videoCards(tester, 3)),
      });
      await pumpReview(
        tester,
        const RateFeedScreen(),
        api: api,
        locale: locale,
        size: const Size(360, 740),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/feed_$locale.png'),
      );
    });
  }
}
