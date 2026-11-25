import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';

import '../pieces/harness.dart';

Map<String, dynamic> _fx(String key) =>
    jsonDecode(studioFixtures[key]!) as Map<String, dynamic>;

int _tiles() => find
    .byWidgetPredicate(
      (w) =>
          w.key is ValueKey &&
          (w.key! as ValueKey).value.toString().startsWith('post-tile-'),
    )
    .evaluate()
    .length;

void main() {
  final range = _fx('calendar.range');
  final posts = (range['posts'] as List).cast<Map<String, dynamic>>();
  // The window is Saturday 21 to Friday 27 Nov.
  final inWeek = posts
      .where((p) => (p['slot_time'] as String).compareTo('2026-11-28') < 0)
      .toList();

  group('Calendar: week', () {
    testWidgets('opens on the week that holds today, Saturday to Friday', (
      tester,
    ) async {
      await pumpFeature(tester, location: '/calendar', height: 3000);
      expect(find.text('21 Nov – 27 Nov'), findsOneWidget);
      for (var d = 21; d <= 27; d++) {
        expect(find.byKey(ValueKey('day-2026-11-$d')), findsOneWidget);
      }
    });

    testWidgets('shows every post of the week with channel, time and status', (
      tester,
    ) async {
      await pumpFeature(tester, location: '/calendar', height: 4000);
      expect(_tiles(), inWeek.length);
      final first = inWeek.first;
      expect(find.byKey(ValueKey('post-tile-${first['id']}')), findsOneWidget);
      // Plain words for status, never the enum name.
      expect(find.text('Scheduled'), findsWidgets);
    });

    testWidgets('next and previous week, then back to today', (tester) async {
      final h = await pumpFeature(tester, location: '/calendar', height: 3000);
      await tester.tap(find.byKey(const ValueKey('calendar-next')));
      await tester.pumpAndSettle();
      expect(find.text('28 Nov – 4 Dec'), findsOneWidget);
      expect(find.byKey(const ValueKey('day-2026-11-28')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('calendar-prev')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-prev')));
      await tester.pumpAndSettle();
      expect(find.text('14 Nov – 20 Nov'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('calendar-today')));
      await tester.pumpAndSettle();
      expect(find.text('21 Nov – 27 Nov'), findsOneWidget);
      expect(
        h.api.calls.where((c) => c == 'calendar.range').length,
        greaterThanOrEqualTo(3),
      );
    });

    testWidgets('filter by channel keeps only that channel', (tester) async {
      await pumpFeature(tester, location: '/calendar', height: 4000);
      final channel = inWeek.first['channel'] as String;
      final expected = inWeek.where((p) => p['channel'] == channel).length;
      await tester.tap(find.byKey(ValueKey('channel-$channel')));
      await tester.pumpAndSettle();
      expect(_tiles(), expected);
      await tester.tap(find.byKey(const ValueKey('channel-all')));
      await tester.pumpAndSettle();
      expect(_tiles(), inWeek.length);
    });

    testWidgets('a quiet day says nothing is planned', (tester) async {
      await pumpFeature(tester, location: '/calendar', height: 4000);
      expect(find.text('Nothing planned'), findsWidgets);
    });

    testWidgets('tapping a post opens it', (tester) async {
      final h = await pumpFeature(tester, location: '/calendar', height: 4000);
      final id = inWeek.first['id'];
      await tester.tap(find.byKey(ValueKey('post-tile-$id')));
      await tester.pumpAndSettle();
      expect(locationOf(h), '/calendar/post/$id');
    });

    testWidgets('empty window says what to do first, and the toolbar stays', (
      tester,
    ) async {
      await pumpFeature(
        tester,
        location: '/calendar',
        height: 3000,
        fixtures: patchedFixtures({
          'calendar.range': (j) {
            j['posts'] = [];
            j['moments'] = [];
            j['shoots'] = [];
          },
        }),
      );
      expect(find.byKey(const ValueKey('empty-purpose')), findsOneWidget);
      expect(find.byKey(const ValueKey('empty-first-step')), findsOneWidget);
      expect(find.byKey(const ValueKey('calendar-next')), findsOneWidget);
      // The founder can act on it.
      expect(find.text('Add a post'), findsOneWidget);
    });

    testWidgets('error state with retry', (tester) async {
      final api = FakeStudioApi(role: 'founder', delay: Duration.zero)
        ..failNext('calendar.range', 'SERVER_ERROR');
      await pumpFeature(tester, location: '/calendar', height: 3000, api: api);
      expect(find.byKey(const ValueKey('error-text')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('error-text')), findsNothing);
    });

    testWidgets('wide screens lay the week out in seven columns', (
      tester,
    ) async {
      await pumpFeature(
        tester,
        location: '/calendar',
        width: 1280,
        height: 800,
      );
      expect(find.byKey(const ValueKey('week-wide')), findsOneWidget);
    });

    testWidgets('Arabic week', (tester) async {
      await pumpFeature(
        tester,
        location: '/calendar',
        height: 3000,
        locale: 'ar',
      );
      expect(find.text('أسبوع'), findsOneWidget);
      expect(find.text('النهارده'), findsWidgets);
      expect(find.text('21 نوفمبر – 27 نوفمبر'), findsOneWidget);
    });
  });

  group('Calendar: month', () {
    testWidgets('month overview, and a day opens its week', (tester) async {
      await pumpFeature(tester, location: '/calendar', height: 3000);
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('month-grid')), findsOneWidget);
      expect(find.text('Nov 2026'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('month-cell-2026-11-10')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('week-days')), findsOneWidget);
      expect(find.text('7 Nov – 13 Nov'), findsOneWidget);
    });

    testWidgets('next month moves by a month', (tester) async {
      await pumpFeature(tester, location: '/calendar', height: 3000);
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-next')));
      await tester.pumpAndSettle();
      expect(find.text('Dec 2026'), findsOneWidget);
    });
  });

  group('Calendar: banner', () {
    testWidgets('drift and check problems show in plain words', (tester) async {
      await pumpFeature(
        tester,
        location: '/calendar',
        height: 3000,
        fixtures: patchedFixtures({
          // The banner speaks for the days on screen (21 to 27 Nov), so the
          // lists carry what it counts.
          'calendar.drift': (j) {
            j['counts']['missing'] = 2;
            j['counts']['unplanned'] = 1;
            j['missing'] = [j['missing'][0], j['missing'][0]];
            j['unplanned'] = [j['unplanned'][0]];
          },
          'calendar.checks': (j) {
            final row = Map<String, dynamic>.from(j['items'][0] as Map);
            j['block'] = 1;
            j['warn'] = 3;
            j['items'] = [
              {...row, 'severity': 'block'},
              {...row, 'severity': 'warn'},
              {...row, 'severity': 'warn'},
              {...row, 'severity': 'warn'},
            ];
          },
        }),
      );
      expect(find.byKey(const ValueKey('calendar-banner')), findsOneWidget);
      expect(find.text('2 posts did not go out'), findsOneWidget);
      expect(
        find.text('1 post went out that is not in the calendar'),
        findsOneWidget,
      );
      expect(find.text('1 must fix, 3 to check'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('calendar-banner')));
      await tester.pumpAndSettle();
      // Posts to clear open the clearing screen, not a read-only sheet.
      expect(find.byKey(const ValueKey('drift-body')), findsOneWidget);
    });

    testWidgets('no banner when all is clear', (tester) async {
      await pumpFeature(
        tester,
        location: '/calendar',
        height: 3000,
        fixtures: patchedFixtures({
          'calendar.drift': (j) {
            j['counts']['missing'] = 0;
            j['counts']['unplanned'] = 0;
            j['missing'] = [];
            j['unplanned'] = [];
          },
          'calendar.checks': (j) {
            j['block'] = 0;
            j['warn'] = 0;
            j['items'] = [];
          },
        }),
      );
      expect(find.byKey(const ValueKey('calendar-banner')), findsNothing);
    });

    testWidgets('a week with nothing wrong shows no banner', (tester) async {
      // The same problems sit in the week of 21 to 27 Nov; the next week is
      // clear, so the banner is not repeated there.
      await pumpFeature(tester, location: '/calendar', height: 3000);
      expect(find.byKey(const ValueKey('calendar-banner')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('calendar-next')));
      await tester.pumpAndSettle();
      expect(find.text('28 Nov – 4 Dec'), findsOneWidget);
      expect(find.byKey(const ValueKey('calendar-banner')), findsNothing);
    });
  });

  group('Calendar: add a post', () {
    testWidgets('a creator cannot add posts', (tester) async {
      await pumpFeature(
        tester,
        location: '/calendar',
        height: 3000,
        role: 'creator',
      );
      expect(find.byKey(const ValueKey('add-post')), findsNothing);
      expect(find.byKey(const ValueKey('day-add-2026-11-21')), findsNothing);
    });

    testWidgets('founder fills the slot form and saves', (tester) async {
      final h = await pumpFeature(tester, location: '/calendar', height: 3000);
      await tester.tap(find.byKey(const ValueKey('day-add-2026-11-27')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('slot-form')), findsOneWidget);

      // Nothing chosen: every missing part is named, nothing is sent.
      await tester.tap(find.byKey(const ValueKey('slot-save')));
      await tester.pumpAndSettle();
      expect(find.text('Pick a piece.'), findsOneWidget);
      expect(find.text('Pick a channel.'), findsOneWidget);
      expect(find.text('Pick a day and a time.'), findsOneWidget);
      expect(h.api.calls, isNot(contains('calendar.post_set')));

      await tester.tap(find.byKey(const ValueKey('slot-piece')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('picker-PC-00163')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('slot-time')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('slot-save')));
      await tester.pumpAndSettle();
      expect(h.api.calls, contains('calendar.post_set'));
      expect(find.byKey(const ValueKey('slot-form')), findsNothing);
    });

    testWidgets('a refusal shows in plain words and keeps the form', (
      tester,
    ) async {
      final api = FakeStudioApi(role: 'founder', delay: Duration.zero)
        ..failNext(
          'calendar.post_set',
          'GATE_FAILED',
          problems: [
            {
              'code': 'R4',
              'message':
                  'Mango is not live on 27 Nov, so it cannot go out then',
            },
          ],
        );
      await pumpFeature(tester, location: '/calendar', height: 3000, api: api);
      await tester.tap(find.byKey(const ValueKey('day-add-2026-11-27')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('slot-piece')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('picker-PC-00163')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('slot-time')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('slot-save')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('slot-problems')), findsOneWidget);
      expect(
        find.text('The check failed. Fix these and try again:'),
        findsOneWidget,
      );
      expect(
        find.text('Mango is not live on 27 Nov, so it cannot go out then'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('slot-form')), findsOneWidget);
    });

    testWidgets('SHADOW_MODE is explained', (tester) async {
      final api = FakeStudioApi(role: 'lead', delay: Duration.zero)
        ..failNext('calendar.post_set', 'SHADOW_MODE');
      await pumpFeature(
        tester,
        location: '/calendar',
        height: 3000,
        role: 'lead',
        api: api,
      );
      await tester.tap(find.byKey(const ValueKey('day-add-2026-11-27')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('slot-piece')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('picker-PC-00163')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('slot-time')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('slot-save')));
      await tester.pumpAndSettle();
      expect(
        find.text('The Studio is not switched on yet, so nothing was changed.'),
        findsOneWidget,
      );
    });
  });
}
