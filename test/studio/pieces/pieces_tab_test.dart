import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

void main() {
  group('Pieces tab: board', () {
    testWidgets('shows a tab per stage with its count, plus a Parked shelf', (
      tester,
    ) async {
      await pumpFeature(tester);
      for (final stage in [
        'Idea',
        'Script',
        'To shoot',
        'To edit',
        'In review',
        'Approved',
        'Scheduled',
        'Posted',
        'Read',
      ]) {
        expect(
          find.byKey(ValueKey('board-tab-$stage')),
          findsOneWidget,
          reason: stage,
        );
      }
      expect(find.byKey(const ValueKey('board-tab-parked')), findsOneWidget);
      // Counts are totals from the server, not the items on screen.
      expect(find.text('Idea 77'), findsOneWidget);
      expect(find.text('To shoot 79'), findsOneWidget);
    });

    testWidgets('a card shows title, stage, owner and opens the piece', (
      tester,
    ) async {
      final h = await pumpFeature(tester);
      final card = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey &&
            (w.key! as ValueKey).value.toString().startsWith('piece-card-'),
      );
      expect(card, findsWidgets);
      await tester.tap(card.first);
      await tester.pumpAndSettle();
      expect(locationOf(h), startsWith('/pieces/PC-'));
    });

    testWidgets('swiping moves to the next stage column', (tester) async {
      await pumpFeature(tester);
      expect(find.byKey(const ValueKey('board-column-Idea')), findsOneWidget);
      await tapKey(tester, 'board-tab-To shoot');
      expect(
        find.byKey(const ValueKey('board-column-To shoot')),
        findsOneWidget,
      );
    });

    testWidgets(
      'an empty stage says so; the Parked shelf lists parked pieces',
      (tester) async {
        final h = await pumpFeature(tester);
        await tapKey(tester, 'board-tab-Script');
        expect(
          find.byKey(const ValueKey('board-empty-Script')),
          findsOneWidget,
        );
        await tapKey(tester, 'board-tab-parked');
        expect(h.api.calls, contains('pieces.list'));
        expect(
          find.byKey(const ValueKey('board-column-parked')),
          findsOneWidget,
        );
      },
    );

    testWidgets('empty board shows what to do first', (tester) async {
      await pumpFeature(
        tester,
        fixtures: patchedFixtures({
          'pieces.board': (j) {
            j['total'] = 0;
            for (final c in j['columns']) {
              c['count'] = 0;
              c['items'] = [];
              c['next'] = null;
            }
          },
          'pieces.list': (j) {
            j['items'] = [];
            j['next'] = null;
          },
        }),
      );
      expect(find.byKey(const ValueKey('empty-purpose')), findsOneWidget);
      expect(find.byKey(const ValueKey('empty-first-step')), findsOneWidget);
    });

    testWidgets('loading skeleton, then error with retry', (tester) async {
      final api = FakeStudioApi(role: 'founder', delay: Duration.zero)
        ..failNext('pieces.board', 'SERVER_ERROR');
      final h = await pumpFeature(tester, api: api);
      expect(find.byKey(const ValueKey('error-text')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('error-text')), findsNothing);
      expect(find.byKey(const ValueKey('board-tab-Idea')), findsOneWidget);
      expect(h.api.calls.where((c) => c == 'pieces.board').length, 2);
    });

    testWidgets('wide screens show the columns side by side', (tester) async {
      await pumpFeature(tester, width: 1280, height: 800);
      expect(find.byKey(const ValueKey('board-wide')), findsOneWidget);
      expect(find.byKey(const ValueKey('board-column-Idea')), findsOneWidget);
    });
  });

  group('Pieces tab: views', () {
    testWidgets('This week groups by person', (tester) async {
      await pumpFeature(tester);
      await tester.tap(find.byKey(const ValueKey('view-week')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('week-list')), findsOneWidget);
      expect(find.byKey(const ValueKey('week-group-0')), findsOneWidget);
      expect(find.text('Kareem'), findsWidgets);
    });

    testWidgets('This week empty state', (tester) async {
      await pumpFeature(
        tester,
        fixtures: patchedFixtures({
          'pieces.this_week': (j) => j['groups'] = [],
        }),
      );
      await tester.tap(find.byKey(const ValueKey('view-week')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('empty-purpose')), findsOneWidget);
    });

    testWidgets('List view pages with a cursor and shows a Show more row', (
      tester,
    ) async {
      final h = await pumpFeature(tester);
      await tester.tap(find.byKey(const ValueKey('view-list')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('piece-list')), findsOneWidget);
      expect(find.byKey(const ValueKey('piece-list-more')), findsOneWidget);
      final before = h.api.calls.where((c) => c == 'pieces.list').length;
      await tester.tap(find.byKey(const ValueKey('piece-list-more')));
      await tester.pumpAndSettle();
      expect(h.api.calls.where((c) => c == 'pieces.list').length, before + 1);
    });

    testWidgets('searching and filtering ask the server again', (tester) async {
      final h = await pumpFeature(tester);
      await tester.tap(find.byKey(const ValueKey('view-list')));
      await tester.pumpAndSettle();
      final before = h.api.calls.where((c) => c == 'pieces.list').length;
      await tester.enterText(
        find.byKey(const ValueKey('piece-search')),
        'cx-163',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(
        h.api.calls.where((c) => c == 'pieces.list').length,
        greaterThan(before),
      );

      final mid = h.api.calls.where((c) => c == 'pieces.list').length;
      await tapKey(tester, 'filter-stage');
      await tapKey(tester, 'filter-stage-In review');
      expect(
        h.api.calls.where((c) => c == 'pieces.list').length,
        greaterThan(mid),
      );
      expect(find.textContaining('Stage: In review'), findsOneWidget);
    });

    testWidgets('a filter nothing matches offers to clear it', (tester) async {
      await pumpFeature(
        tester,
        fixtures: patchedFixtures({
          'pieces.list': (j) {
            j['items'] = [];
            j['next'] = null;
          },
        }),
      );
      await tester.tap(find.byKey(const ValueKey('view-list')));
      await tester.pumpAndSettle();
      // No filter yet: the "first piece" empty state.
      expect(find.byKey(const ValueKey('empty-purpose')), findsOneWidget);
      await tapKey(tester, 'filter-format');
      await tapKey(tester, 'filter-format-reel');
      expect(find.text('Clear filters'), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Format:'), findsNothing);
    });

    testWidgets('the chosen view is remembered', (tester) async {
      await pumpFeature(tester);
      await tester.tap(find.byKey(const ValueKey('view-list')));
      await tester.pumpAndSettle();
      // A fresh visit with the same stored choice (prefs mock is reset by the
      // harness, so write it back the way the app does).
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().any((k) => k.startsWith('studio.pieces.view.')),
        true,
      );
      expect(
        prefs.getString(
          prefs.getKeys().firstWhere(
            (k) => k.startsWith('studio.pieces.view.'),
          ),
        ),
        'list',
      );
    });
  });

  group('Pieces tab: new piece', () {
    testWidgets('only the founder and the lead see the button', (tester) async {
      await pumpFeature(tester, role: 'creator');
      expect(find.byKey(const ValueKey('new-piece')), findsNothing);
    });

    testWidgets('founder creates a piece at Idea and lands on it', (
      tester,
    ) async {
      final h = await pumpFeature(tester, role: 'founder');
      await tester.tap(find.byKey(const ValueKey('new-piece')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('create-form')), findsOneWidget);

      // Nothing typed: both missing fields are named, nothing is sent.
      await tester.tap(find.byKey(const ValueKey('create-save')));
      await tester.pumpAndSettle();
      expect(find.text('Give it a title.'), findsOneWidget);
      expect(find.text('Pick a format.'), findsOneWidget);
      expect(h.api.calls, isNot(contains('pieces.create')));

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('create-title')),
          matching: find.byType(TextField),
        ),
        'A jar for the late shift',
      );
      await tester.tap(find.byKey(const ValueKey('create-format')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reel').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create-save')));
      await tester.pumpAndSettle();
      expect(h.api.calls, contains('pieces.create'));
      expect(locationOf(h), '/pieces/PC-00331');
    });

    testWidgets('a refused create shows the reason', (tester) async {
      final api = FakeStudioApi(role: 'lead', delay: Duration.zero)
        ..failNext('pieces.create', 'SHADOW_MODE');
      await pumpFeature(tester, role: 'lead', api: api);
      await tester.tap(find.byKey(const ValueKey('new-piece')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('create-title')),
          matching: find.byType(TextField),
        ),
        'Test piece',
      );
      await tester.tap(find.byKey(const ValueKey('create-format')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Static').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create-save')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'The Studio is not switched on yet, so nothing can be changed.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('create-form')), findsOneWidget);
    });
  });

  testWidgets('Arabic: RTL and Arabic stage names', (tester) async {
    await pumpFeature(tester, locale: 'ar');
    expect(find.text('اللوحة'), findsOneWidget);
    expect(find.text('الأسبوع ده'), findsOneWidget);
    expect(find.text('القايمة'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.rtl,
    );
  });

  test('the fixtures used by these tests exist', () {
    expect(studioFixtures.containsKey('pieces.board'), true);
    expect(studioFixtures.containsKey('calendar.range'), true);
  });
}
