import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'helpers.dart';

/// Goldens are rendered with the bundled brand fonts on the machine that ran
/// `flutter test --update-goldens`; regenerate on the CI platform if pixels
/// differ there.
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

  // Icons: the SDK's Material Icons font, so the golden shows real glyphs.
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
    testWidgets('shell golden: Today, founder, $locale', (tester) async {
      usePhone(tester);
      await pumpStudio(tester, role: 'founder', locale: locale);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/shell_today_$locale.png'),
      );
    });

    testWidgets('shell golden: Inbox decisions, $locale', (tester) async {
      usePhone(tester);
      final c = await pumpStudio(tester, role: 'founder', locale: locale);
      await goTo(tester, c, '/inbox/decisions');
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/shell_inbox_decisions_$locale.png'),
      );
    });
  }
}
