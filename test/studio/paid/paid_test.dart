import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/features/paid/presentation/paid_overview_screen.dart';
import 'package:jarz_pos/src/studio/features/paid/presentation/paid_queue_screen.dart';
import 'package:jarz_pos/src/studio/features/paid/presentation/paid_round_screen.dart';

import '../more/more_test_utils.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

/// The overview with a second queued ad, so there is something to reorder.
Map<String, String> _twoInQueue({List<String>? actions}) => patchFixtures({
  'paid.overview': (j) {
    final o = Map<String, dynamic>.from(j as Map);
    final first = Map<String, dynamic>.from((o['queue'] as List).first as Map);
    final second = {
      ...first,
      'ad_id': 'AD-00032',
      'queue_rank': 2,
      'queue_note': 'Second in line',
      'piece': {...(first['piece'] as Map), 'title': 'Second piece'},
    };
    if (actions != null) {
      first['actions'] = actions;
      second['actions'] = actions;
    }
    o['queue'] = [first, second];
    return o;
  },
});

void main() {
  group('overview', () {
    testWidgets('shows what is due and why, rounds, stop signs, queue', (
      tester,
    ) async {
      await pumpMore(
        tester,
        const PaidOverviewScreen(),
        size: const Size(360, 1800),
      );
      expect(_key('paid-as-of'), findsOneWidget);
      expect(find.text('reel-p18-v7: day 7 read'), findsOneWidget);
      expect(
        find.text('Round R2b launched Wed 18 Nov; day 7 is today'),
        findsOneWidget,
      );
      expect(_key('round-R2b'), findsOneWidget);
      expect(_key('round-R3'), findsOneWidget);
      expect(_key('stop-2026-11-25:paid:jobs-checks:gate1'), findsOneWidget);
      expect(_key('glance-AD-00031'), findsOneWidget);
      // Money is whole EGP, never decimals.
      expect(find.textContaining('.00'), findsNothing);
    });

    testWidgets('empty overview says what to do first', (tester) async {
      final api = RecordingApi(
        fixtures: patchFixtures({
          'paid.overview': (j) => {
            ...(j as Map),
            'rounds': [],
            'due': [],
            'queue': [],
            'stop_signs': [],
          },
        }),
      );
      await pumpMore(tester, const PaidOverviewScreen(), api: api);
      expect(_key('empty-purpose'), findsOneWidget);
      expect(find.textContaining('No round is running'), findsOneWidget);
    });

    testWidgets('error offers a retry', (tester) async {
      final api = RecordingApi()..failNext('paid.overview', 'SERVER_ERROR');
      await pumpMore(tester, const PaidOverviewScreen(), api: api);
      expect(_key('error-text'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(_key('paid-overview'), findsOneWidget);
    });

    testWidgets('a due line opens its round; the queue link opens the queue', (
      tester,
    ) async {
      final h = await pumpMoreRouter(
        tester,
        location: '/more/paid',
        size: const Size(360, 1800),
      );
      await tapKey(tester, 'due-read_d7-AD-00013');
      expect(where(h.router), '/more/paid/rounds/R2b');
      h.router.go('/more/paid');
      await tester.pumpAndSettle();
      await tapKey(tester, 'paid-open-queue');
      expect(where(h.router), '/more/paid/queue');
    });

    testWidgets('Arabic overview at 360 px has no overflow', (tester) async {
      await pumpMore(
        tester,
        const PaidOverviewScreen(),
        locale: 'ar',
        size: const Size(360, 1800),
      );
      expect(find.text('مطلوب دلوقتي'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('queue', () {
    testWidgets('founder sees the add button, handles and remove buttons', (
      tester,
    ) async {
      final api = RecordingApi(fixtures: _twoInQueue());
      await pumpMore(tester, const PaidQueueScreen(), api: api);
      expect(_key('queue-add'), findsOneWidget);
      expect(_key('drag-AD-00031'), findsOneWidget);
      expect(_key('queue-remove-AD-00032'), findsOneWidget);
      expect(find.text('Second in line'), findsOneWidget);
      expect(find.text('Ready for ads'), findsWidgets);
    });

    testWidgets('lead reads it: no add, no handles, no remove', (tester) async {
      final api = RecordingApi(
        role: 'lead',
        fixtures: _twoInQueue(actions: []),
      );
      await pumpMore(tester, const PaidQueueScreen(), api: api);
      expect(_key('queue-add'), findsNothing);
      expect(find.byIcon(Icons.drag_handle), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.text('Second in line'), findsOneWidget);
    });

    testWidgets('only the actions the server gives show', (tester) async {
      final api = RecordingApi(fixtures: _twoInQueue(actions: ['remove']));
      await pumpMore(tester, const PaidQueueScreen(), api: api);
      expect(find.byIcon(Icons.drag_handle), findsNothing);
      expect(_key('queue-remove-AD-00031'), findsOneWidget);
    });

    testWidgets('empty queue says what to do first', (tester) async {
      final api = RecordingApi(
        fixtures: patchFixtures({
          'paid.overview': (j) => {...(j as Map), 'queue': []},
        }),
      );
      await pumpMore(tester, const PaidQueueScreen(), api: api);
      expect(find.textContaining('The queue is empty'), findsOneWidget);
    });

    testWidgets('dragging reorders and sends the full list', (tester) async {
      final api = RecordingApi(fixtures: _twoInQueue());
      await pumpMore(tester, const PaidQueueScreen(), api: api);
      final before = tester.getTopLeft(_key('queue-AD-00032')).dy;
      await tester.drag(_key('drag-AD-00032'), const Offset(0, -140));
      await tester.pumpAndSettle();
      final p = api.last('paid.queue_reorder')!;
      expect(p['ad_ids'], ['AD-00032', 'AD-00031']);
      expect(tester.getTopLeft(_key('queue-AD-00032')).dy, lessThan(before));
      expect(snackText(tester), 'New order saved');
    });

    testWidgets('a refused reorder puts the order back and says why', (
      tester,
    ) async {
      final api = RecordingApi(fixtures: _twoInQueue())
        ..failNext(
          'paid.queue_reorder',
          'VALIDATION',
          message: 'The list must hold exactly the queued ads.',
        );
      await pumpMore(tester, const PaidQueueScreen(), api: api);
      final before = tester.getTopLeft(_key('queue-AD-00032')).dy;
      await tester.drag(_key('drag-AD-00032'), const Offset(0, -140));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(_key('queue-AD-00032')).dy, before);
      expect(snackText(tester), 'The list must hold exactly the queued ads.');
    });

    testWidgets('remove asks first, then removes', (tester) async {
      final api = RecordingApi(fixtures: _twoInQueue());
      await pumpMore(tester, const PaidQueueScreen(), api: api);
      await tapKey(tester, 'queue-remove-AD-00032');
      expect(_key('remove-dialog'), findsOneWidget);
      await tapKey(tester, 'remove-confirm');
      expect(api.last('paid.queue_remove')!['ad_id'], 'AD-00032');
      expect(snackText(tester), 'Taken out of the queue');
    });

    testWidgets('remove refused: ALREADY_DONE says so, queue is kept', (
      tester,
    ) async {
      final api = RecordingApi(fixtures: _twoInQueue())
        ..failNext('paid.queue_remove', 'ALREADY_DONE');
      await pumpMore(tester, const PaidQueueScreen(), api: api);
      await tapKey(tester, 'queue-remove-AD-00032');
      await tapKey(tester, 'remove-confirm');
      expect(snackText(tester), contains('Already done'));
      expect(_key('queue-AD-00032'), findsOneWidget);
    });

    Future<RecordingApi> openAdd(WidgetTester tester) async {
      final api = RecordingApi();
      api.respond['versions.get'] = (p) => {
        ...(fixtureJson('versions.get') as Map),
        'id': p['version_id'],
        'ready_for_ads': p['version_id'] == 'PC-00188-v1',
      };
      await pumpMore(tester, const PaidQueueScreen(), api: api);
      await tapKey(tester, 'queue-add');
      return api;
    }

    testWidgets('add lists only versions ready for ads', (tester) async {
      await openAdd(tester);
      expect(_key('candidate-PC-00188'), findsOneWidget);
      expect(_key('candidate-PC-00163'), findsNothing);
      expect(_key('candidate-PC-00147'), findsNothing);
    });

    testWidgets('adding a version sends it with a note', (tester) async {
      final api = await openAdd(tester);
      await tapKey(tester, 'candidate-PC-00188');
      await typeKey(tester, 'text-dialog-field', 'For Saturday');
      await tapKey(tester, 'text-dialog-confirm');
      final p = api.last('paid.queue_add')!;
      expect(p['version_id'], 'PC-00188-v1');
      expect(p['note'], 'For Saturday');
      expect(_key('candidate-PC-00188'), findsNothing);
      expect(snackText(tester), 'Added to the queue');
    });

    testWidgets('a refusal shows the server reason and keeps the sheet', (
      tester,
    ) async {
      final api = await openAdd(tester);
      api.failNext(
        'paid.queue_add',
        'VALIDATION',
        message: 'This version has no ad route yet.',
      );
      await tapKey(tester, 'candidate-PC-00188');
      await tapKey(tester, 'text-dialog-confirm');
      expect(snackText(tester), 'This version has no ad route yet.');
      expect(_key('candidate-PC-00188'), findsOneWidget);
    });

    testWidgets('already queued: ALREADY_DONE', (tester) async {
      final api = await openAdd(tester);
      api.failNext('paid.queue_add', 'ALREADY_DONE');
      await tapKey(tester, 'candidate-PC-00188');
      await tapKey(tester, 'text-dialog-confirm');
      expect(snackText(tester), contains('Already done'));
    });

    testWidgets('shadow mode is said in plain words', (tester) async {
      final api = await openAdd(tester);
      api.failNext('paid.queue_add', 'SHADOW_MODE');
      await tapKey(tester, 'candidate-PC-00188');
      await tapKey(tester, 'text-dialog-confirm');
      expect(snackText(tester), contains('not switched on yet'));
    });

    testWidgets('nothing ready: the sheet says why', (tester) async {
      final api = RecordingApi();
      api.respond['versions.get'] = (p) => {
        ...(fixtureJson('versions.get') as Map),
        'id': p['version_id'],
        'ready_for_ads': false,
      };
      await pumpMore(tester, const PaidQueueScreen(), api: api);
      await tapKey(tester, 'queue-add');
      expect(_key('no-candidates'), findsOneWidget);
    });
  });

  group('round', () {
    testWidgets('ads show their numbers, the rules line and diagnostics', (
      tester,
    ) async {
      await pumpMore(
        tester,
        const PaidRoundScreen(roundCode: 'R2b'),
        size: const Size(360, 2000),
      );
      expect(find.text('reel-p18-v7'), findsOneWidget);
      expect(find.text('EGP 1,010'), findsOneWidget);
      expect(find.text('EGP 168'), findsOneWidget);
      expect(
        find.textContaining('under the 185 line', findRichText: true),
        findsOneWidget,
      );
      // Hold and CTR are marked as diagnostics only.
      expect(_key('diagnostics-AD-00013'), findsOneWidget);
      expect(
        find.descendant(
          of: _key('diagnostics-AD-00013'),
          matching: find.textContaining('do not decide'),
        ),
        findsOneWidget,
      );
      expect(find.text('Testing'), findsWidgets);
    });

    testWidgets('no purchases shows words, not a number', (tester) async {
      final api = RecordingApi(
        fixtures: patchFixtures({
          'paid.round_get': (j) {
            final r = Map<String, dynamic>.from(j as Map);
            final ads = [...(r['ads'] as List)];
            final a = Map<String, dynamic>.from(ads.first as Map);
            a['numbers'] = {
              ...(a['numbers'] as Map),
              'purchases': 0,
              'cpa': null,
            };
            ads[0] = a;
            return {...r, 'ads': ads};
          },
        }),
      );
      await pumpMore(
        tester,
        const PaidRoundScreen(roundCode: 'R2b'),
        api: api,
        size: const Size(360, 2000),
      );
      expect(find.text('No purchases yet'), findsOneWidget);
    });

    testWidgets('state buttons show when the ad allows set_state', (
      tester,
    ) async {
      await pumpMore(
        tester,
        const PaidRoundScreen(roundCode: 'R2b'),
        size: const Size(360, 2000),
      );
      expect(_key('set-state-AD-00013'), findsOneWidget);
      expect(_key('edit'), findsOneWidget);
    });

    testWidgets('no actions, no state buttons and no pencil', (tester) async {
      final none = RecordingApi(
        fixtures: patchFixtures({
          'paid.round_get': (j) {
            final r = Map<String, dynamic>.from(j as Map);
            return {
              ...r,
              'actions': [],
              'ads': [
                for (final a in r['ads'] as List)
                  {...(a as Map), 'actions': []},
              ],
            };
          },
        }),
      );
      await pumpMore(
        tester,
        const PaidRoundScreen(roundCode: 'R2b'),
        api: none,
        size: const Size(360, 2000),
      );
      expect(_key('set-state-AD-00013'), findsNothing);
      expect(_key('edit'), findsNothing);
    });

    testWidgets('setting a state is optimistic and sent with the round', (
      tester,
    ) async {
      final api = RecordingApi();
      await pumpMore(
        tester,
        const PaidRoundScreen(roundCode: 'R2b'),
        api: api,
        size: const Size(360, 2000),
      );
      await tapKey(tester, 'set-state-AD-00013');
      await tester.tap(find.byKey(const ValueKey('state-Winner')));
      await tester.pump();
      await typeKey(tester, 'state-note', 'Seven purchases');
      await tapKey(tester, 'state-save');
      final p = api.last('paid.ad_set_state')!;
      expect(p['ad_id'], 'AD-00013');
      expect(p['state'], 'Winner');
      expect(p['note'], 'Seven purchases');
      expect(p['base_modified'], isNotNull);
      expect(snackText(tester), 'Now: Winner');
    });

    testWidgets('clearing sends an empty state', (tester) async {
      final api = RecordingApi();
      await pumpMore(
        tester,
        const PaidRoundScreen(roundCode: 'R2b'),
        api: api,
        size: const Size(360, 2000),
      );
      await tapKey(tester, 'set-state-AD-00013');
      await tester.tap(find.byKey(const ValueKey('state-clear')));
      await tester.pump();
      await tapKey(tester, 'state-save');
      expect(api.last('paid.ad_set_state')!['state'], '');
    });

    testWidgets('a failed state change rolls back', (tester) async {
      final api = RecordingApi()..failNext('paid.ad_set_state', 'SERVER_ERROR');
      await pumpMore(
        tester,
        const PaidRoundScreen(roundCode: 'R2b'),
        api: api,
        size: const Size(360, 2000),
      );
      await tapKey(tester, 'set-state-AD-00013');
      await tester.tap(find.byKey(const ValueKey('state-Off')));
      await tester.pump();
      await tapKey(tester, 'state-save');
      expect(snackText(tester), 'Something went wrong. Try again.');
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: _key('state-AD-00013'),
                matching: find.byType(Text),
              ),
            )
            .data,
        'Testing',
      );
    });

    testWidgets('STALE takes the fresh ad and says so', (tester) async {
      final api = RecordingApi();
      final round = fixtureJson('paid.round_get') as Map;
      final fresh = {
        ...((round['ads'] as List).first as Map),
        'state': 'Winner',
        'state_label': 'Winner',
        'actions': ['set_state'],
      };
      api.failNext('paid.ad_set_state', 'STALE', current: fresh);
      await pumpMore(
        tester,
        const PaidRoundScreen(roundCode: 'R2b'),
        api: api,
        size: const Size(360, 2000),
      );
      await tapKey(tester, 'set-state-AD-00013');
      await tester.tap(find.byKey(const ValueKey('state-Off')));
      await tester.pump();
      await tapKey(tester, 'state-save');
      expect(snackText(tester), contains('Someone changed this'));
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: _key('state-AD-00013'),
                matching: find.byType(Text),
              ),
            )
            .data,
        'Winner',
      );
    });

    testWidgets('NOT_PERMITTED is said plainly', (tester) async {
      final api = RecordingApi()
        ..failNext('paid.ad_set_state', 'NOT_PERMITTED');
      await pumpMore(
        tester,
        const PaidRoundScreen(roundCode: 'R2b'),
        api: api,
        size: const Size(360, 2000),
      );
      await tapKey(tester, 'set-state-AD-00013');
      await tester.tap(find.byKey(const ValueKey('state-Off')));
      await tester.pump();
      await tapKey(tester, 'state-save');
      expect(snackText(tester), 'You cannot do that.');
    });

    testWidgets('the pencil edits the round date', (tester) async {
      final api = RecordingApi();
      await pumpMore(
        tester,
        const PaidRoundScreen(roundCode: 'R2b'),
        api: api,
        size: const Size(360, 2000),
      );
      await tapKey(tester, 'edit');
      await typeKey(tester, 'round-title', 'Round two b');
      await tapKey(tester, 'round-save');
      final p = api.last('paid.round_set')!;
      expect(p['round_code'], 'R2b');
      expect(p['launch_date'], '2026-11-18');
      expect(p['title'], 'Round two b');
    });

    testWidgets('a round that is not there shows the error state', (
      tester,
    ) async {
      final api = RecordingApi()..failNext('paid.round_get', 'NOT_FOUND');
      await pumpMore(tester, const PaidRoundScreen(roundCode: 'R9'), api: api);
      expect(_key('error-text'), findsOneWidget);
    });

    testWidgets('Arabic round page at 360 px has no overflow', (tester) async {
      await pumpMore(
        tester,
        const PaidRoundScreen(roundCode: 'R2b'),
        locale: 'ar',
        size: const Size(360, 2000),
      );
      expect(find.text('القواعد بتقول إيه'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
