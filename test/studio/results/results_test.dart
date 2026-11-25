import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/features/results/presentation/piece_results_screen.dart';
import 'package:jarz_pos/src/studio/features/results/presentation/scorecard_screen.dart';
import 'package:jarz_pos/src/studio/features/results/presentation/summary_screen.dart';

import '../more/more_test_utils.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

Map<String, String> _scorecard(
  List<String> actions, {
  String? status,
  Map<String, dynamic>? extra,
}) => patchFixtures({
  'results.scorecard': (j) => {
    ...(j as Map),
    'actions': actions,
    if (status != null) 'status': status,
    ...?extra,
  },
});

const _tall = Size(360, 2600);

void main() {
  group('scorecard', () {
    testWidgets('numbers filled by the system are read only and sourced', (
      tester,
    ) async {
      await pumpMore(tester, const ScorecardScreen(), size: _tall);
      expect(_key('scorecard-body'), findsOneWidget);
      expect(find.text('Orders tagged by source'), findsOneWidget);
      // EGP with no decimals, percent with one.
      expect(find.text('EGP 28,350'), findsOneWidget);
      expect(_key('number-value-tagged_order_share'), findsOneWidget);
      expect(find.textContaining('Filled by the system'), findsWidgets);
      // The person-added line is listed as it was written.
      expect(find.text('Google Trends: Jarz'), findsOneWidget);
      expect(find.text('62'), findsOneWidget);
      // No field of a system number can be edited.
      expect(find.byType(TextField), findsNothing);
      expect(_key('gate-gate_pixel'), findsOneWidget);
    });

    testWidgets('the pencil shows for the founder with the note action', (
      tester,
    ) async {
      await pumpMore(tester, const ScorecardScreen(), size: _tall);
      expect(_key('edit'), findsOneWidget);
      expect(_key('add-line'), findsOneWidget);
      expect(_key('go-by-piece'), findsOneWidget);
    });

    testWidgets('no pencil without the note action', (tester) async {
      final api = RecordingApi(fixtures: _scorecard(['add_line']));
      await pumpMore(tester, const ScorecardScreen(), api: api, size: _tall);
      expect(_key('edit'), findsNothing);
      expect(_key('add-line'), findsOneWidget);
      expect(_key('mark-reviewed'), findsNothing);
    });

    testWidgets('a creator can add a line but not write the review', (
      tester,
    ) async {
      final api = RecordingApi(
        role: 'creator',
        fixtures: _scorecard(['note', 'add_line']),
      );
      await pumpMore(tester, const ScorecardScreen(), api: api, size: _tall);
      expect(_key('edit'), findsNothing);
      expect(_key('add-line'), findsOneWidget);
      expect(_key('go-by-piece'), findsNothing);
      expect(_key('go-summary'), findsNothing);
    });

    testWidgets('no actions, nothing to press', (tester) async {
      final api = RecordingApi(fixtures: _scorecard([]));
      await pumpMore(tester, const ScorecardScreen(), api: api, size: _tall);
      expect(_key('edit'), findsNothing);
      expect(_key('add-line'), findsNothing);
      expect(_key('mark-reviewed'), findsNothing);
    });

    testWidgets('writing the review sends both notes with base_modified', (
      tester,
    ) async {
      final api = RecordingApi();
      await pumpMore(tester, const ScorecardScreen(), api: api, size: _tall);
      await tapKey(tester, 'edit');
      await typeKey(tester, 'notes-field', 'Tagging is the gap.');
      await typeKey(tester, 'actions-field', 'Fix the pixel by Thursday.');
      await tapKey(tester, 'notes-save');
      final p = api.last('results.scorecard_note')!;
      expect(p['review_notes'], 'Tagging is the gap.');
      expect(p['actions_agreed'], 'Fix the pixel by Thursday.');
      expect(p['base_modified'], isNotNull);
      expect(p['week_start'], '2026-11-22');
      expect(snackText(tester), 'Review saved');
    });

    testWidgets('adding a line needs a name and a value', (tester) async {
      final api = RecordingApi();
      await pumpMore(tester, const ScorecardScreen(), api: api, size: _tall);
      await tapKey(tester, 'add-line');
      expect(tester.widget<FilledButton>(_key('line-save')).onPressed, isNull);
      await typeKey(tester, 'line-label', 'Walk-in orders');
      await typeKey(tester, 'line-value', '14');
      await tapKey(tester, 'line-save');
      final p = api.last('results.scorecard_note')!;
      expect(p['line'], {'label': 'Walk-in orders', 'value': '14'});
      expect(snackText(tester), 'Line added');
    });

    testWidgets('mark as reviewed only with the action', (tester) async {
      final api = RecordingApi(fixtures: _scorecard(['mark_reviewed']));
      await pumpMore(tester, const ScorecardScreen(), api: api, size: _tall);
      await tapKey(tester, 'mark-reviewed');
      expect(api.last('results.scorecard_note')!['mark_reviewed'], true);
      expect(snackText(tester), 'Marked as reviewed');
    });

    testWidgets('a reviewed week hides the button and shows who', (
      tester,
    ) async {
      final api = RecordingApi(
        fixtures: _scorecard(
          ['mark_reviewed'],
          status: 'Reviewed',
          extra: {
            'reviewed_by': {'key': 'ali', 'full_name': 'Ali'},
            'reviewed_at': '2026-11-22T21:00:00+02:00',
          },
        ),
      );
      await pumpMore(tester, const ScorecardScreen(), api: api, size: _tall);
      expect(_key('mark-reviewed'), findsNothing);
      expect(_key('reviewed-by'), findsOneWidget);
    });

    testWidgets('errors: shadow mode, not permitted, validation', (
      tester,
    ) async {
      final api = RecordingApi();
      await pumpMore(tester, const ScorecardScreen(), api: api, size: _tall);
      api.failNext('results.scorecard_note', 'SHADOW_MODE');
      await tapKey(tester, 'edit');
      await tapKey(tester, 'notes-save');
      expect(snackText(tester), contains('not switched on yet'));
      ScaffoldMessenger.of(
        tester.element(find.byType(Scaffold).first),
      ).clearSnackBars();
      await tester.pumpAndSettle();

      api.failNext('results.scorecard_note', 'NOT_PERMITTED');
      await tapKey(tester, 'edit');
      await tapKey(tester, 'notes-save');
      expect(snackText(tester), 'You cannot do that.');
      ScaffoldMessenger.of(
        tester.element(find.byType(Scaffold).first),
      ).clearSnackBars();
      await tester.pumpAndSettle();

      api.failNext(
        'results.scorecard_note',
        'VALIDATION',
        message: 'Write a note first.',
      );
      await tapKey(tester, 'edit');
      await tapKey(tester, 'notes-save');
      expect(snackText(tester), 'Write a note first.');
    });

    testWidgets('STALE shows the newer review', (tester) async {
      final api = RecordingApi();
      api.failNext(
        'results.scorecard_note',
        'STALE',
        current: {
          ...(fixtureJson('results.scorecard') as Map),
          'review_notes': 'Written by Ali a minute ago.',
        },
      );
      await pumpMore(tester, const ScorecardScreen(), api: api, size: _tall);
      await tapKey(tester, 'edit');
      await tapKey(tester, 'notes-save');
      expect(snackText(tester), contains('Someone changed this'));
      expect(find.text('Written by Ali a minute ago.'), findsOneWidget);
    });

    testWidgets('week buttons ask the server for the week before', (
      tester,
    ) async {
      final api = RecordingApi();
      await pumpMore(tester, const ScorecardScreen(), api: api, size: _tall);
      await tapKey(tester, 'week-prev');
      expect(api.last('results.scorecard')!['week_start'], '2026-11-15');
    });

    testWidgets('error state and retry', (tester) async {
      final api = RecordingApi()..failNext('results.scorecard', 'SERVER_ERROR');
      await pumpMore(tester, const ScorecardScreen(), api: api);
      expect(_key('error-text'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(_key('scorecard-body'), findsOneWidget);
    });

    testWidgets('links to by piece and summary', (tester) async {
      final h = await pumpMoreRouter(
        tester,
        location: '/more/results',
        size: _tall,
      );
      await tapKey(tester, 'go-by-piece');
      expect(where(h.router), '/more/results/pieces');
      h.router.go('/more/results');
      await tester.pumpAndSettle();
      await tapKey(tester, 'go-summary');
      expect(where(h.router), '/more/results/summary');
    });

    testWidgets('Arabic scorecard at 360 px has no overflow', (tester) async {
      await pumpMore(
        tester,
        const ScorecardScreen(),
        locale: 'ar',
        size: _tall,
      );
      expect(find.text('الأرقام'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('results by piece', () {
    testWidgets('lists pieces with best views and hold', (tester) async {
      await pumpMore(tester, const PieceResultsScreen(), size: _tall);
      expect(_key('result-PC-00237'), findsOneWidget);
      expect(_key('result-PC-00078'), findsOneWidget);
    });

    testWidgets('sort goes to the server', (tester) async {
      final api = RecordingApi();
      await pumpMore(tester, const PieceResultsScreen(), api: api);
      await tapKey(tester, 'chip-Most views');
      expect(api.last('results.by_piece')!['sort'], 'views');
    });

    testWidgets('empty says what to do first', (tester) async {
      final api = RecordingApi(
        fixtures: patchFixtures({
          'results.by_piece': (j) => {'items': [], 'next': null},
        }),
      );
      await pumpMore(tester, const PieceResultsScreen(), api: api);
      expect(find.textContaining('No results yet'), findsOneWidget);
    });

    testWidgets('only an open, unfiled read has a file button', (tester) async {
      await pumpMore(tester, const PieceResultsScreen(), size: _tall);
      expect(_key('file-read-SP-2026-00190'), findsOneWidget);
    });

    testWidgets('a filed read has none', (tester) async {
      final api = RecordingApi(
        fixtures: patchFixtures({
          'results.by_piece': (j) {
            final r = Map<String, dynamic>.from(j as Map);
            final items = [...(r['items'] as List)];
            final first = Map<String, dynamic>.from(items.first as Map);
            first['reads'] = [
              for (final x in first['reads'] as List)
                {...(x as Map), 'filed': true, 'due': false, 'missing': []},
            ];
            items[0] = first;
            return {...r, 'items': items};
          },
        }),
      );
      await pumpMore(tester, const PieceResultsScreen(), api: api, size: _tall);
      expect(_key('file-read-SP-2026-00190'), findsNothing);
      expect(find.text('Filed'), findsWidgets);
    });

    testWidgets('filing asks only for what is missing and files the 72h read', (
      tester,
    ) async {
      final api = RecordingApi();
      await pumpMore(tester, const PieceResultsScreen(), api: api, size: _tall);
      await tapKey(tester, 'file-read-SP-2026-00190');
      expect(_key('read-field-hold3_pct'), findsOneWidget);
      expect(_key('read-field-views'), findsNothing);
      await typeKey(tester, 'read-field-hold3_pct', '21.5');
      await tapKey(tester, 'read-send');
      final p = api.last('results.read_set')!;
      expect(p['post_id'], 'SP-2026-00190');
      expect(p['bucket'], '72h');
      expect(p['hold3_pct'], 21.5);
      expect(snackText(tester), 'Read filed');
    });

    testWidgets('a read refused before its window shows the reason', (
      tester,
    ) async {
      final api = RecordingApi()
        ..failNext(
          'results.read_set',
          'VALIDATION',
          message: 'The 72-hour window opens on Saturday.',
          field: 'bucket',
        );
      await pumpMore(tester, const PieceResultsScreen(), api: api, size: _tall);
      await tapKey(tester, 'file-read-SP-2026-00190');
      await tapKey(tester, 'read-send');
      expect(snackText(tester), 'The 72-hour window opens on Saturday.');
      expect(_key('file-read-SP-2026-00190'), findsOneWidget);
    });

    testWidgets('already filed: shows it as filed', (tester) async {
      final api = RecordingApi()..failNext('results.read_set', 'ALREADY_DONE');
      await pumpMore(tester, const PieceResultsScreen(), api: api, size: _tall);
      await tapKey(tester, 'file-read-SP-2026-00190');
      await tapKey(tester, 'read-send');
      expect(snackText(tester), contains('Already filed'));
      expect(_key('file-read-SP-2026-00190'), findsNothing);
    });

    testWidgets('shadow mode is said in plain words', (tester) async {
      final api = RecordingApi()..failNext('results.read_set', 'SHADOW_MODE');
      await pumpMore(tester, const PieceResultsScreen(), api: api, size: _tall);
      await tapKey(tester, 'file-read-SP-2026-00190');
      await tapKey(tester, 'read-send');
      expect(snackText(tester), contains('not switched on yet'));
    });
  });

  group('summary', () {
    testWidgets('groups are drawn as bars against the best one', (
      tester,
    ) async {
      await pumpMore(tester, const SummaryScreen(), size: _tall);
      expect(_key('group-reel'), findsOneWidget);
      final best = tester.widget<FractionallySizedBox>(_key('bar-reel'));
      final other = tester.widget<FractionallySizedBox>(_key('bar-trial'));
      expect(best.widthFactor, 1.0);
      expect(other.widthFactor, closeTo(3010 / 6120, 0.001));
    });

    testWidgets('group by and period go to the server', (tester) async {
      final api = RecordingApi();
      await pumpMore(
        tester,
        const SummaryScreen(),
        api: api,
        size: const Size(700, 1000),
      );
      await tapKey(tester, 'chip-Persona');
      expect(api.last('results.summary')!['group_by'], 'persona');
      await tapKey(tester, 'chip-Last 90 days');
      final p = api.last('results.summary')!;
      expect(
        DateTime.parse(p['to']).difference(DateTime.parse(p['from'])).inDays,
        90,
      );
    });

    testWidgets('empty period says what to do', (tester) async {
      final api = RecordingApi(
        fixtures: patchFixtures({
          'results.summary': (j) => {...(j as Map), 'groups': []},
        }),
      );
      await pumpMore(tester, const SummaryScreen(), api: api);
      expect(find.textContaining('Nothing in this period'), findsOneWidget);
    });
  });
}
