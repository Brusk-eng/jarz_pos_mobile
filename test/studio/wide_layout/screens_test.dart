import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/data/models/studio_enums.dart';
import 'package:jarz_pos/src/studio/features/today/presentation/today_view.dart';

import 'package:jarz_pos/src/studio/features/pieces/presentation/piece_screen.dart';
import 'package:jarz_pos/src/studio/features/pieces/presentation/piece_widgets.dart';

import '../helpers.dart';
import 'shot_harness.dart' show useSize;

Finder _keyEnding(String suffix) => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('line-') &&
      (w.key! as ValueKey<String>).value.endsWith(suffix),
);

void main() {
  test('Today blocks: what waits on the person first, housekeeping last', () {
    expect(todayBlockTier(BlockKey.toApprove), 0);
    expect(todayBlockTier(BlockKey.decisions), 0);
    expect(todayBlockTier(BlockKey.didntGoOut), 0);
    expect(todayBlockTier(BlockKey.readyToPost), 1);
    expect(todayBlockTier(BlockKey.shootTomorrow), 1);
    expect(todayBlockTier(BlockKey.unplanned), 2);
    expect(todayBlockTier(BlockKey.advice), 2);
  });

  group('Today on a wide window', () {
    testWidgets('1920: sections in 3 columns, actions on the row', (
      tester,
    ) async {
      useSize(tester, 1920, 1080);
      await pumpStudio(tester);
      final approve = tester.getTopLeft(
        find.byKey(const ValueKey('today-block-toApprove')),
      );
      final decisions = tester.getTopLeft(
        find.byKey(const ValueKey('today-block-decisions')),
      );
      expect(approve.dy, decisions.dy, reason: 'first two share the top row');
      expect(approve.dx, lessThan(decisions.dx));
      // The first approve button sits on the same row as its line.
      final btn = tester.getRect(_keyEnding('-approve').first);
      final row = tester.getRect(
        find
            .ancestor(
              of: _keyEnding('-approve').first,
              matching: find.byWidgetPredicate(
                (w) =>
                    w.key is ValueKey<String> &&
                    (w.key! as ValueKey<String>).value.startsWith(
                      'today-line-',
                    ),
              ),
            )
            .first,
      );
      expect(btn.center.dy, lessThan(row.top + row.height * 0.7));
      // The add-task button and the day switcher share the app bar.
      expect(find.byKey(const ValueKey('task-add-top')), findsOneWidget);
      final bar = tester.getRect(find.byType(AppBar));
      expect(
        bar.contains(tester.getCenter(find.byKey(const ValueKey('day-next')))),
        isTrue,
      );
    });

    testWidgets('1024: two columns', (tester) async {
      useSize(tester, 1024, 768);
      await pumpStudio(tester);
      final a = tester.getTopLeft(
        find.byKey(const ValueKey('today-block-toApprove')),
      );
      final b = tester.getTopLeft(
        find.byKey(const ValueKey('today-block-decisions')),
      );
      expect(a.dy, b.dy);
      expect(b.dx, greaterThan(a.dx + 300));
    });

    testWidgets('phone: one column, buttons under the line, no overflow', (
      tester,
    ) async {
      for (final size in const [Size(360, 800), Size(390, 844)]) {
        useSize(tester, size.width, size.height);
        await pumpStudio(tester);
        final block = tester.getRect(
          find.byKey(const ValueKey('today-block-toApprove')),
        );
        // One column: the block fills the width less the two gutters.
        expect(block.width, size.width - 32);
        // The buttons wrap under their line, inside the block.
        final btn = tester.getRect(_keyEnding('-approve').first);
        expect(block.contains(btn.center), isTrue);
        expect(btn.height, greaterThanOrEqualTo(44));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('phone: Today and Inbox meet the tap-target guideline', (
      tester,
    ) async {
      useSize(tester, 390, 844);
      final handle = tester.ensureSemantics();
      final c = await pumpStudio(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await goTo(tester, c, '/inbox/approve');
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });

  group('Inbox on a wide window', () {
    testWidgets('the approval days flow into columns', (tester) async {
      useSize(tester, 1920, 1080);
      final c = await pumpStudio(
        tester,
        now: DateTime.parse('2026-11-25T14:05:00+02:00'),
      );
      await goTo(tester, c, '/inbox/approve');
      final cards = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('approve-') &&
            w is Card,
      );
      expect(cards, findsAtLeastNWidgets(2));
      final xs = {
        for (final e in cards.evaluate())
          tester.getTopLeft(find.byWidget(e.widget)).dx.round(),
      };
      expect(xs.length, greaterThan(1), reason: 'more than one column');
    });
  });

  group('Calendar and More on a wide window', () {
    testWidgets('the week is seven columns with stacked tiles', (tester) async {
      useSize(tester, 1440, 900);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/calendar');
      expect(find.byKey(const ValueKey('week-wide')), findsOneWidget);
    });

    testWidgets('More is a grid of cards', (tester) async {
      useSize(tester, 1440, 900);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/more');
      final a = tester.getTopLeft(find.byKey(const ValueKey('more-shoots')));
      final b = tester.getTopLeft(find.byKey(const ValueKey('more-assets')));
      expect(a.dy, b.dy);
      expect(b.dx, greaterThan(a.dx));
    });

    testWidgets('Pieces list opens the piece in the right pane', (
      tester,
    ) async {
      useSize(tester, 1440, 900);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/pieces');
      await tester.tap(find.byKey(const ValueKey('view-list')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PieceCard).first);
      await tester.pumpAndSettle();
      expect(currentLocation(c), '/pieces', reason: 'no screen was pushed');
      expect(find.byType(PieceScreen), findsOneWidget);
    });
  });
}
