// Screenshot run for the wide-layout work. Skipped unless WIDE_SHOTS_DIR is
// set; run with `--update-goldens` so each PNG is written to that folder:
//
//   WIDE_SHOTS_DIR=C:/x/shots WIDE_SHOTS_TAG=after \
//     flutter test test/studio/wide_layout/shots_test.dart --update-goldens
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jarz_pos/src/studio/features/pieces/state/pieces_view_state.dart';

import '../helpers.dart';
import 'shot_harness.dart';

const _sizes = {
  'm360': (360.0, 800.0),
  'm390': (390.0, 844.0),
  'd1024': (1024.0, 768.0),
  'd1440': (1440.0, 900.0),
  'd1920': (1920.0, 1080.0),
};

/// (name, route, sizes, locales)
final _shots = <(String, String, List<String>, List<String>)>[
  ('today', '/today', ['m390', 'd1024', 'd1440', 'd1920'], ['en', 'ar']),
  (
    'inbox',
    '/inbox/approve',
    ['m390', 'd1024', 'd1440', 'd1920'],
    ['en', 'ar'],
  ),
  ('calendar', '/calendar', ['m390', 'd1024', 'd1440', 'd1920'], ['en']),
  ('pieces', '/pieces', ['m390', 'd1024', 'd1440', 'd1920'], ['en']),
  ('more', '/more', ['m390', 'd1024', 'd1440', 'd1920'], ['en']),
  ('settings', '/more/settings', ['m390', 'd1440'], ['en']),
  ('pieces_list', '/pieces', ['m390', 'd1024', 'd1440', 'd1920'], ['en']),
  ('library', '/assets', ['m390', 'd1440', 'd1920'], ['en']),
  ('shoots', '/shoots', ['m390', 'd1440', 'd1920'], ['en']),
  ('phone360', '/today', ['m360'], ['en', 'ar']),
  ('phone360_inbox', '/inbox/approve', ['m360'], ['en', 'ar']),
  ('phone360_calendar', '/calendar', ['m360'], ['en']),
  ('phone360_pieces', '/pieces', ['m360'], ['en']),
  ('phone360_more', '/more', ['m360'], ['en']),
];

void main() {
  final dir = Platform.environment['WIDE_SHOTS_DIR'];
  final tag = Platform.environment['WIDE_SHOTS_TAG'] ?? 'after';
  final only = Platform.environment['WIDE_SHOTS_ONLY']?.split(',');
  if (dir == null) return;
  setUpAll(loadShotFonts);

  for (final (name, route, sizes, locales) in _shots) {
    if (only != null && !only.contains(name)) continue;
    for (final locale in locales) {
      for (final s in sizes) {
        final (w, h) = _sizes[s]!;
        testWidgets('$tag $name $locale $s', (tester) async {
          useSize(tester, w, h);
          final overrides = await fakePictureOverrides(tester);
          await HttpOverrides.runZoned(() async {
            final c = await pumpStudio(
              tester,
              locale: locale,
              now: DateTime.parse('2026-11-25T14:05:00+02:00'),
            );
            if (route != '/today') await goTo(tester, c, route);
            if (name == 'pieces_list') {
              c.read(piecesViewProvider.notifier).choose(PiecesView.list);
              await tester.pumpAndSettle();
            }
            await tester.pump(const Duration(milliseconds: 300));
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 200)),
            );
            await tester.pump();
            await expectLater(
              find.byType(WidgetsApp),
              matchesGoldenFile(
                Uri.file('$dir/${tag}_${name}_${locale}_$s.png'),
              ),
            );
          }, createHttpClient: (ctx) => overrides.createHttpClient(ctx));
        });
      }
    }
  }
}
