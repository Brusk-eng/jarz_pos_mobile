// Wide-layout pass 2: References, Paid, Results and Scorecard, Decisions,
// Ideas, the Pieces board. Each screen at 390 (a phone: one column, nothing
// new) and 1440 (a desktop: the space used).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jarz_pos/src/studio/features/ideas/presentation/my_ideas_screen.dart';

import '../helpers.dart';
import 'shot_harness.dart' show useSize;

Finder _key(String k) => find.byKey(ValueKey(k));

/// The keys that start with [prefix].
Finder _keys(String prefix) => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith(prefix),
);

/// Two finders sit side by side (same row, different column) or stacked.
bool _sideBySide(WidgetTester t, Finder a, Finder b) {
  final pa = t.getTopLeft(a.first);
  final pb = t.getTopLeft(b.first);
  return (pa.dy - pb.dy).abs() < 40 && (pa.dx - pb.dx).abs() > 100;
}

bool _stacked(WidgetTester t, Finder a, Finder b) {
  final pa = t.getTopLeft(a.first);
  final pb = t.getTopLeft(b.first);
  return (pa.dx - pb.dx).abs() < 40 && pb.dy > pa.dy;
}

Future<ProviderContainerLike> _open(
  WidgetTester tester,
  double w,
  double h,
  String route, {
  String locale = 'en',
}) async {
  useSize(tester, w, h);
  final c = await pumpStudio(
    tester,
    locale: locale,
    now: DateTime.parse('2026-11-25T14:05:00+02:00'),
  );
  await goTo(tester, c, route);
  return c;
}

typedef ProviderContainerLike = dynamic;

void main() {
  group('References', () {
    testWidgets('1440: thumbnails up to the wide cell, no width cap', (
      tester,
    ) async {
      await _open(tester, 1440, 900, '/more/references');
      final cards = _keys('ref-');
      expect(cards, findsAtLeastNWidgets(2));
      final r = tester.getRect(cards.first);
      expect(r.width, inInclusiveRange(200, 240));
      // The search field is not capped at the old 1100.
      final search = tester.getRect(find.byType(TextField).first);
      expect(search.width, greaterThan(1000));
      expect(tester.takeException(), isNull);
    });

    testWidgets('390: two across, unchanged', (tester) async {
      await _open(tester, 390, 844, '/more/references');
      final cards = _keys('ref-');
      expect(cards, findsAtLeastNWidgets(2));
      expect(_sideBySide(tester, cards.at(0), cards.at(1)), isTrue);
      expect(tester.getRect(cards.first).width, lessThan(200));
      expect(tester.takeException(), isNull);
    });
  });

  group('Paid overview', () {
    testWidgets('1440: sections side by side', (tester) async {
      await _open(tester, 1440, 900, '/more/paid');
      expect(_keys('due-'), findsWidgets);
      expect(_keys('round-'), findsWidgets);
      expect(_sideBySide(tester, _keys('due-'), _keys('round-')), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('390: one column, no overflow', (tester) async {
      await _open(tester, 390, 844, '/more/paid');
      expect(_stacked(tester, _keys('due-'), _keys('round-')), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440 Arabic: no overflow', (tester) async {
      await _open(tester, 1440, 900, '/more/paid', locale: 'ar');
      expect(_keys('due-'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Results and Scorecard', () {
    testWidgets('1440: the scorecard cards sit in columns', (tester) async {
      await _open(tester, 1440, 900, '/more/results');
      expect(_keys('number-'), findsWidgets);
      expect(_keys('gate-'), findsWidgets);
      expect(_sideBySide(tester, _keys('number-'), _keys('gate-')), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('390: the scorecard is one column', (tester) async {
      await _open(tester, 390, 844, '/more/results');
      expect(_keys('number-'), findsWidgets);
      expect(
        tester.getRect(_keys('number-').first).width,
        390,
        reason: 'one column: a card (with its side margins) fills the width',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440: ratings lists side by side', (tester) async {
      await _open(tester, 1440, 900, '/more/results/ratings');
      expect(
        _sideBySide(tester, _key('ratings-ready'), _key('ratings-drop')),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('390: ratings lists stacked', (tester) async {
      await _open(tester, 390, 844, '/more/results/ratings');
      expect(
        _stacked(tester, _key('ratings-ready'), _key('ratings-drop')),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440: summary groups and results by piece in columns', (
      tester,
    ) async {
      await _open(tester, 1440, 900, '/more/results/summary');
      expect(_keys('group-').evaluate().length, greaterThan(1));
      expect(
        _sideBySide(tester, _keys('group-').at(0), _keys('group-').at(1)),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('390: summary groups stacked', (tester) async {
      await _open(tester, 390, 844, '/more/results/summary');
      expect(
        _stacked(tester, _keys('group-').at(0), _keys('group-').at(1)),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440 and 390: results by piece', (tester) async {
      await _open(tester, 1440, 900, '/more/results/pieces');
      expect(_keys('result-').evaluate().length, greaterThan(1));
      expect(
        _sideBySide(tester, _keys('result-').at(0), _keys('result-').at(1)),
        isTrue,
      );
      await _open(tester, 390, 844, '/more/results/pieces');
      expect(
        _stacked(tester, _keys('result-').at(0), _keys('result-').at(1)),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Decisions', () {
    testWidgets('1440: list left, the decision with its options right', (
      tester,
    ) async {
      await _open(tester, 1440, 900, '/inbox/decisions');
      expect(_keys('dr-'), findsWidgets);
      expect(_keys('dc-'), findsNothing, reason: 'nothing open yet');
      await tester.tap(_keys('dr-').first);
      await tester.pumpAndSettle();
      expect(_keys('dc-'), findsOneWidget);
      expect(_key('decision-question'), findsOneWidget);
      final row = tester.getRect(_keys('dr-').first);
      final card = tester.getRect(_keys('dc-').first);
      expect(
        card.left,
        greaterThan(row.right),
        reason: 'detail is on the right',
      );
      expect(
        tester.getRect(_keys('dr-').first).height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440 Arabic: opens and has no overflow', (tester) async {
      await _open(tester, 1440, 900, '/inbox/decisions', locale: 'ar');
      await tester.tap(_keys('dr-').first);
      await tester.pumpAndSettle();
      expect(_keys('dc-'), findsOneWidget);
      // RTL: the list is on the right, the detail on its left.
      final row = tester.getRect(_keys('dr-').first);
      final card = tester.getRect(_keys('dc-').first);
      expect(card.right, lessThan(row.left));
      expect(tester.takeException(), isNull);
    });

    testWidgets('390: the cards stay in one list', (tester) async {
      await _open(tester, 390, 844, '/inbox/decisions');
      expect(_keys('dc-'), findsWidgets);
      expect(_keys('dr-'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Ideas', () {
    testWidgets('1440: cards in a grid', (tester) async {
      await _open(tester, 1440, 900, '/inbox/ideas');
      expect(_keys('ic-').evaluate().length, greaterThan(1));
      expect(
        _sideBySide(tester, _keys('ic-').at(0), _keys('ic-').at(1)),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('390: one column', (tester) async {
      await _open(tester, 390, 844, '/inbox/ideas');
      expect(_stacked(tester, _keys('ic-').at(0), _keys('ic-').at(1)), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440 and 390: my ideas', (tester) async {
      await _open(tester, 1440, 900, '/inbox/my-ideas');
      expect(find.byType(MyIdeaRow).evaluate().length, greaterThan(1));
      expect(
        _sideBySide(
          tester,
          find.byType(MyIdeaRow).at(0),
          find.byType(MyIdeaRow).at(1),
        ),
        isTrue,
      );
      await _open(tester, 390, 844, '/inbox/my-ideas');
      expect(
        _stacked(
          tester,
          find.byType(MyIdeaRow).at(0),
          find.byType(MyIdeaRow).at(1),
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Pieces board', () {
    testWidgets('1440: columns keep their minimum and scroll sideways', (
      tester,
    ) async {
      await _open(tester, 1440, 900, '/pieces');
      final board = find.byKey(const ValueKey('board-wide'));
      expect(board, findsOneWidget);
      expect(
        find.descendant(of: board, matching: find.byType(ListView)),
        findsWidgets,
      );
      final w = tester.getRect(_key('board-column-Idea')).width;
      expect(w, greaterThanOrEqualTo(200));
      expect(tester.takeException(), isNull);
    });

    testWidgets('2560: the columns share the width, no scrolling', (
      tester,
    ) async {
      await _open(tester, 2560, 1200, '/pieces');
      final first = tester.getRect(_key('board-column-Idea'));
      final second = tester.getRect(_key('board-column-Script'));
      expect((first.width - second.width).abs(), lessThan(1));
      expect(first.width, greaterThan(220));
      expect(
        tester.getRect(_key('board-column-parked')).right,
        lessThanOrEqualTo(2560),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('390: swipe pages and tabs, unchanged', (tester) async {
      await _open(tester, 390, 844, '/pieces');
      expect(_key('board-tabs'), findsOneWidget);
      expect(_key('board-pages'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Phone 360 and 390 screens: no overflow', () {
    for (final size in const [Size(360, 800), Size(390, 844)]) {
      for (final route in const [
        '/more/references',
        '/more/paid',
        '/more/results',
        '/more/results/ratings',
        '/inbox/decisions',
        '/inbox/ideas',
        '/inbox/my-ideas',
        '/pieces',
      ]) {
        testWidgets('${size.width.round()} $route', (tester) async {
          await _open(tester, size.width, size.height, route);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('Phone tap targets', () {
    for (final route in const ['/inbox/decisions', '/inbox/ideas']) {
      testWidgets('390 $route', (tester) async {
        useSize(tester, 390, 844);
        final handle = tester.ensureSemantics();
        final c = await pumpStudio(tester);
        await goTo(tester, c, route);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      });
    }
  });
}
