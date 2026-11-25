import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'assets_test_utils.dart';

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
    testWidgets('golden: library grid, $locale, 360 px', (tester) async {
      await pumpAssets(
        tester,
        AssetsHarness(),
        locale: locale,
        size: const Size(360, 740), // phone
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/library_$locale.png'),
      );
    });
  }
}
