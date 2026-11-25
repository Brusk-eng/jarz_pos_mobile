import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/offline/reachability.dart';
import 'package:jarz_pos/src/studio/features/shoots/presentation/on_set_screen.dart';
import 'package:jarz_pos/src/studio/features/shoots/presentation/shoot_screen.dart';

import 'shoots_test_utils.dart';

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
    testWidgets('golden: shoot page, $locale, 360 px', (tester) async {
      await pumpShoot(
        tester,
        const ShootScreen(shootId: 'SHOOT-0006'),
        api: ShootTestApi(),
        locale: locale,
        size: const Size(360, 1500),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/shoot_$locale.png'),
      );
    });

    testWidgets(
      'golden: On set, offline with waiting changes, $locale, 360 px',
      (tester) async {
        final api = ShootTestApi();
        final c = await pumpShoot(
          tester,
          const OnSetScreen(shootId: 'SHOOT-0006'),
          api: api,
          locale: locale,
          size: const Size(360, 780),
        );
        api.offline = true;
        c.read(studioReachabilityProvider.notifier).report(false);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('onset-filmed')));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/onset_$locale.png'),
        );
      },
    );
  }
}
