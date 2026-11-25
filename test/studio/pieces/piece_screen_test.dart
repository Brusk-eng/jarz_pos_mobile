import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';

import 'harness.dart';

const _id = '/pieces/PC-00163';

Map<String, dynamic> _pieceJson() =>
    jsonDecode(studioFixtures['pieces.get']!) as Map<String, dynamic>;

Map<String, void Function(dynamic)> _piece(void Function(Map j) edit) => {
  'pieces.get': (j) => edit(j as Map),
};

Map<String, dynamic> _move(
  String to,
  String label, {
  String kind = 'forward',
  bool enabled = true,
  String needs = '',
  List<Map<String, String>> problems = const [],
}) => {
  'to': to,
  'kind': kind,
  'label': label,
  'enabled': enabled,
  'problems': problems,
  'needs': needs,
};

Future<void> _askAndConfirm(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const ValueKey('ask-text')), text);
  await tester.tap(find.byKey(const ValueKey('ask-confirm')));
  await tester.pumpAndSettle();
}

void main() {
  group('Piece screen: reading', () {
    testWidgets('shows stage, who has it, labels, versions, posts, history', (
      tester,
    ) async {
      await pumpFeature(tester, location: _id, height: 3500);
      expect(find.byKey(const ValueKey('piece-title')), findsOneWidget);
      expect(find.text('#3 Thank you, me'), findsWidgets);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('piece-stage')),
          matching: find.text('In review'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('next-card')), findsOneWidget);
      expect(find.textContaining('With the creators'), findsOneWidget);
      // Plain words, not enum names.
      expect(find.text('Self-treater'), findsWidgets);
      expect(find.text('One jar for me'), findsWidgets);
      expect(find.text('Static'), findsWidgets);
      expect(find.textContaining('Version 2'), findsOneWidget);
      expect(find.text('Version 1'), findsOneWidget);
      // Newest first.
      final v2 = tester.getTopLeft(find.textContaining('Version 2')).dy;
      final v1 = tester.getTopLeft(find.text('Version 1')).dy;
      expect(v2, lessThan(v1));
    });

    testWidgets('sections further down: posts, results, history', (
      tester,
    ) async {
      await pumpFeature(tester, location: _id, height: 3500);
      await tester.scrollUntilVisible(
        find.text('RESULTS'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey('results-empty')), findsOneWidget);
      expect(find.text('HISTORY'), findsOneWidget);
      expect(find.byKey(const ValueKey('history-full')), findsOneWidget);
    });

    testWidgets('results appear once read', (tester) async {
      await pumpFeature(
        tester,
        location: _id,
        height: 3500,
        fixtures: patchedFixtures(
          _piece(
            (j) => j['reads'] = [
              {
                'post_id': 'SP-2026-00218',
                'piece_id': 'PC-00163',
                'bucket': '24h',
                'opens_on': '2026-11-24',
                'due': true,
                'filed': true,
                'reach': 1200,
                'views': 3400,
                'shares': 12,
                'saves': 30,
                'likes': 100,
                'comments_count': 4,
                'missing': [],
              },
            ],
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('After 24 hours'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Reach: 1200'), findsOneWidget);
      expect(find.byKey(const ValueKey('results-empty')), findsNothing);
    });

    testWidgets('script lines and on-screen text show in both languages', (
      tester,
    ) async {
      await pumpFeature(
        tester,
        location: _id,
        height: 3500,
        fixtures: patchedFixtures(
          _piece((j) {
            j['script'] = {
              'length': '20 s',
              'opening': 'Open on the lid',
              'screen_ar': 'برطمان واحد',
              'screen_en': 'One jar',
              'block': null,
              'holds': [],
              'notes': null,
              'lines': [
                {'lang': 'en', 't': '0:00', 'line': 'Spoon in'},
              ],
            };
          }),
        ),
      );
      expect(find.byKey(const ValueKey('script-block')), findsOneWidget);
      expect(find.text('Spoon in'), findsOneWidget);
      expect(find.text('برطمان واحد'), findsOneWidget);
      expect(find.text('One jar'), findsOneWidget);
    });

    testWidgets('versions and posts open their screens', (tester) async {
      final h = await pumpFeature(tester, location: _id, height: 3500);
      await tester.tap(find.byKey(const ValueKey('version-PC-00163-v2')));
      await tester.pumpAndSettle();
      expect(locationOf(h), '/versions/PC-00163-v2');
      h.router.pop();
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('post-tile-SP-2026-00218')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('post-tile-SP-2026-00218')));
      await tester.pumpAndSettle();
      expect(locationOf(h), '/calendar/post/SP-2026-00218');
    });

    testWidgets('full history loads on tap', (tester) async {
      final h = await pumpFeature(tester, location: _id, height: 3500);
      await tapKey(tester, 'history-full');
      expect(h.api.calls, contains('pieces.history'));
    });

    testWidgets('error state offers a retry', (tester) async {
      final api = FakeStudioApi(role: 'founder', delay: Duration.zero)
        ..failNext('pieces.get', 'SERVER_ERROR');
      await pumpFeature(tester, location: _id, height: 3500, api: api);
      expect(find.byKey(const ValueKey('error-text')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('piece-title')), findsOneWidget);
    });

    testWidgets('Arabic', (tester) async {
      await pumpFeature(tester, location: _id, height: 3500, locale: 'ar');
      expect(find.text('الخطوة الجاية'), findsOneWidget);
      expect(find.text('النسخ'), findsOneWidget);
    });
  });

  group('Piece screen: buttons come only from actions', () {
    testWidgets('no actions: no pencil, no moves, no park', (tester) async {
      await pumpFeature(
        tester,
        location: _id,
        height: 3500,
        role: 'creator',
        fixtures: patchedFixtures(_piece((j) => j['actions'] = [])),
      );
      expect(find.byKey(const ValueKey('edit')), findsNothing);
      expect(find.byKey(const ValueKey('park')), findsNothing);
      expect(find.byKey(const ValueKey('unpark')), findsNothing);
      expect(find.byKey(const ValueKey('move-To shoot')), findsNothing);
      expect(find.byKey(const ValueKey('move-Script')), findsNothing);
    });

    testWidgets('only the listed actions show', (tester) async {
      await pumpFeature(
        tester,
        location: _id,
        height: 3500,
        fixtures: patchedFixtures(_piece((j) => j['actions'] = ['edit'])),
      );
      expect(find.byKey(const ValueKey('edit')), findsOneWidget);
      expect(find.byKey(const ValueKey('park')), findsNothing);
      expect(find.byKey(const ValueKey('move-To shoot')), findsNothing);
    });

    testWidgets('a move the server did not list is never offered', (
      tester,
    ) async {
      await pumpFeature(tester, location: _id, height: 3500);
      // The fixture lists exactly two back moves; nothing else is a button.
      expect(find.byKey(const ValueKey('move-To shoot')), findsOneWidget);
      expect(find.byKey(const ValueKey('move-Script')), findsOneWidget);
      expect(find.byKey(const ValueKey('move-Approved')), findsNothing);
    });

    testWidgets(
      'a move that is listed but not enabled shows why, as no button',
      (tester) async {
        await pumpFeature(
          tester,
          location: _id,
          height: 3500,
          fixtures: patchedFixtures(
            _piece(
              (j) => j['next_moves'] = [
                _move(
                  'Approved',
                  'Send to approval',
                  enabled: false,
                  problems: [
                    {'code': 'x', 'message': 'The file is not ready'},
                  ],
                ),
              ],
            ),
          ),
        );
        expect(find.byKey(const ValueKey('move-Approved')), findsNothing);
        expect(
          find.byKey(const ValueKey('move-blocked-Approved')),
          findsOneWidget,
        );
        expect(find.text('The file is not ready'), findsOneWidget);
      },
    );

    testWidgets('parked piece: banner and Bring back, only from actions', (
      tester,
    ) async {
      await pumpFeature(
        tester,
        location: _id,
        height: 3500,
        fixtures: patchedFixtures(
          _piece((j) {
            j['parked'] = 'Waiting for the new jars';
            j['actions'] = ['unpark'];
          }),
        ),
      );
      expect(find.byKey(const ValueKey('parked-banner')), findsOneWidget);
      expect(find.byKey(const ValueKey('unpark')), findsOneWidget);
      expect(find.byKey(const ValueKey('park')), findsNothing);
    });
  });

  group('Piece screen: moving', () {
    testWidgets('a move that needs a reason asks for it, then moves', (
      tester,
    ) async {
      final h = await pumpFeature(tester, location: _id, height: 3500);
      await tester.tap(find.byKey(const ValueKey('move-To shoot')));
      await tester.pumpAndSettle();
      // Empty reason: told to write it, nothing sent.
      await tester.tap(find.byKey(const ValueKey('ask-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Write the reason first.'), findsOneWidget);
      expect(h.api.calls, isNot(contains('pieces.move')));
      await _askAndConfirm(tester, 'Needs a re-shoot');
      expect(h.api.calls, contains('pieces.move'));
      expect(find.text('Moved to To shoot.'), findsOneWidget);
    });

    testWidgets('a move with no extra input goes straight through', (
      tester,
    ) async {
      final h = await pumpFeature(
        tester,
        location: _id,
        height: 3500,
        fixtures: patchedFixtures(
          _piece(
            (j) => j['next_moves'] = [_move('Approved', 'Send to approval')],
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('move-Approved')));
      await tester.pumpAndSettle();
      expect(h.api.calls, contains('pieces.move'));
      expect(find.byKey(const ValueKey('ask-text')), findsNothing);
    });

    testWidgets(
      'GATE_FAILED shows the problems as a checklist with fix links',
      (tester) async {
        final api = FakeStudioApi(role: 'founder', delay: Duration.zero)
          ..failNext(
            'pieces.move',
            'GATE_FAILED',
            problems: [
              {
                'code': 'labels_missing',
                'message': 'Pick a persona and a situation first',
              },
              {
                'code': 'file_missing',
                'message': 'The finished file is missing',
              },
              {'code': 'other', 'message': 'Something with no fix link'},
            ],
          );
        final h = await pumpFeature(
          tester,
          location: _id,
          height: 3500,
          api: api,
          fixtures: null,
        );
        await tester.tap(find.byKey(const ValueKey('move-Script')));
        await tester.pumpAndSettle();
        await _askAndConfirm(tester, 'x');
        expect(find.byKey(const ValueKey('gate-sheet')), findsOneWidget);
        expect(find.text('This move is not possible yet'), findsOneWidget);
        expect(
          find.text('Pick a persona and a situation first'),
          findsOneWidget,
        );
        expect(find.text('The finished file is missing'), findsOneWidget);
        expect(find.text('Something with no fix link'), findsOneWidget);
        // A link only where we can tell where it is fixed.
        expect(
          find.byKey(const ValueKey('problem-fix-labels_missing')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('problem-fix-file_missing')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('problem-fix-other')), findsNothing);
        await tester.tap(
          find.byKey(const ValueKey('problem-fix-file_missing')),
        );
        await tester.pumpAndSettle();
        expect(locationOf(h), '/versions/PC-00163-v2');
      },
    );

    for (final c in [
      ('SHADOW_MODE', 'The Studio is not switched on yet'),
      ('NOT_PERMITTED', 'Your role cannot do that.'),
      ('SERVER_ERROR', 'Something went wrong on our side'),
      ('VALIDATION', 'Say what changed'),
    ]) {
      testWidgets('${c.$1} is shown in plain words', (tester) async {
        final api = FakeStudioApi(role: 'founder', delay: Duration.zero)
          ..failNext('pieces.move', c.$1, message: 'Say what changed');
        await pumpFeature(tester, location: _id, height: 3500, api: api);
        await tester.tap(find.byKey(const ValueKey('move-Script')));
        await tester.pumpAndSettle();
        await _askAndConfirm(tester, 'x');
        expect(find.textContaining(c.$2), findsOneWidget);
        // Rolled back: still a piece in review, the button is still there.
        expect(find.byKey(const ValueKey('move-Script')), findsOneWidget);
      });
    }

    testWidgets('STALE swaps in the latest copy and says so', (tester) async {
      final fresh = _pieceJson()..['title'] = 'Changed by Ali';
      final api = FakeStudioApi(role: 'founder', delay: Duration.zero)
        ..failNext('pieces.move', 'STALE', current: fresh);
      await pumpFeature(tester, location: _id, height: 3500, api: api);
      await tester.tap(find.byKey(const ValueKey('move-Script')));
      await tester.pumpAndSettle();
      await _askAndConfirm(tester, 'x');
      expect(
        find.text(
          'This changed since you opened it. Refresh the page and try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Changed by Ali'), findsWidgets);
    });

    testWidgets('ALREADY_DONE says so and shows the latest', (tester) async {
      final api = FakeStudioApi(role: 'founder', delay: Duration.zero)
        ..failNext('pieces.move', 'ALREADY_DONE', current: _pieceJson());
      await pumpFeature(tester, location: _id, height: 3500, api: api);
      await tester.tap(find.byKey(const ValueKey('move-Script')));
      await tester.pumpAndSettle();
      await _askAndConfirm(tester, 'x');
      expect(
        find.text('Already done. This is how it stands now.'),
        findsOneWidget,
      );
    });

    testWidgets('NOT_FOUND sends you back to the pieces', (tester) async {
      final api = FakeStudioApi(role: 'founder', delay: Duration.zero)
        ..failNext('pieces.move', 'NOT_FOUND');
      final h = await pumpFeature(
        tester,
        location: _id,
        height: 3500,
        api: api,
      );
      await tester.tap(find.byKey(const ValueKey('move-Script')));
      await tester.pumpAndSettle();
      await _askAndConfirm(tester, 'x');
      expect(locationOf(h), '/pieces');
      expect(
        find.text('This piece is gone. Go back to the list.'),
        findsOneWidget,
      );
    });
  });

  group('Piece screen: parking', () {
    testWidgets('parks with a reason', (tester) async {
      final h = await pumpFeature(tester, location: _id, height: 3500);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('park')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('park')));
      await tester.pumpAndSettle();
      await _askAndConfirm(tester, 'Waiting for new jars');
      expect(h.api.calls, contains('pieces.park'));
      expect(find.text('Parked.'), findsOneWidget);
    });

    testWidgets('brings a parked piece back', (tester) async {
      final h = await pumpFeature(
        tester,
        location: _id,
        height: 3500,
        fixtures: patchedFixtures(
          _piece((j) {
            j['parked'] = 'Waiting';
            j['actions'] = ['unpark'];
          }),
        ),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('unpark')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('unpark')));
      await tester.pumpAndSettle();
      expect(h.api.calls, contains('pieces.unpark'));
      expect(find.text('Back on the path.'), findsOneWidget);
    });
  });

  group('Piece screen: editing', () {
    Future<void> openEdit(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('edit')));
      await tester.pumpAndSettle();
    }

    testWidgets('edit the title and save', (tester) async {
      final h = await pumpFeature(tester, location: _id, height: 3500);
      await openEdit(tester);
      expect(find.byKey(const ValueKey('edit-form')), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('edit-title')),
          matching: find.byType(TextField),
        ),
        'A better title',
      );
      await tester.tap(find.byKey(const ValueKey('edit-save')));
      await tester.pumpAndSettle();
      expect(h.api.calls, contains('pieces.update'));
      expect(find.text('Saved.'), findsOneWidget);
      expect(find.byKey(const ValueKey('edit-form')), findsNothing);
    });

    testWidgets('saving without a change says so and sends nothing', (
      tester,
    ) async {
      final h = await pumpFeature(tester, location: _id, height: 3500);
      await openEdit(tester);
      await tester.tap(find.byKey(const ValueKey('edit-save')));
      await tester.pumpAndSettle();
      expect(find.text('Nothing changed.'), findsOneWidget);
      expect(h.api.calls, isNot(contains('pieces.update')));
    });

    testWidgets('an empty title is refused in the form', (tester) async {
      await pumpFeature(tester, location: _id, height: 3500);
      await openEdit(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('edit-title')),
          matching: find.byType(TextField),
        ),
        '',
      );
      await tester.tap(find.byKey(const ValueKey('edit-save')));
      await tester.pumpAndSettle();
      expect(find.text('Give it a title.'), findsOneWidget);
    });

    testWidgets('STALE: reloads and applies the change on top, once', (
      tester,
    ) async {
      final fresh = _pieceJson()
        ..['modified'] = '2026-11-25T10:00:00+02:00'
        ..['series'] = 'Pick one';
      final api = FakeStudioApi(role: 'founder', delay: Duration.zero)
        ..failNext('pieces.update', 'STALE', current: fresh);
      await pumpFeature(tester, location: _id, height: 3500, api: api);
      await openEdit(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('edit-title')),
          matching: find.byType(TextField),
        ),
        'Mine',
      );
      await tester.tap(find.byKey(const ValueKey('edit-save')));
      await tester.pumpAndSettle();
      expect(api.calls.where((c) => c == 'pieces.update').length, 2);
      expect(
        find.textContaining('Your changes were put on top'),
        findsOneWidget,
      );
    });

    testWidgets('STALE twice gives up in plain words', (tester) async {
      final fresh = _pieceJson();
      final api = FakeStudioApi(role: 'founder', delay: Duration.zero)
        ..failNext('pieces.update', 'STALE', times: 2, current: fresh);
      await pumpFeature(tester, location: _id, height: 3500, api: api);
      await openEdit(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('edit-title')),
          matching: find.byType(TextField),
        ),
        'Mine',
      );
      await tester.tap(find.byKey(const ValueKey('edit-save')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('This changed since you opened it'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('edit-form')), findsOneWidget);
    });

    testWidgets('a lead with only assign sees owner and date, not the title', (
      tester,
    ) async {
      final h = await pumpFeature(
        tester,
        location: _id,
        height: 3500,
        role: 'lead',
        fixtures: patchedFixtures(_piece((j) => j['actions'] = ['assign'])),
      );
      await openEdit(tester);
      expect(find.byKey(const ValueKey('edit-title')), findsNothing);
      expect(find.text('Due date: Pick a date'), findsOneWidget);
      expect(h.api.calls, isNot(contains('pieces.update')));
    });

    testWidgets('editing script lines adds and removes rows', (tester) async {
      await pumpFeature(tester, location: _id, height: 3500);
      await openEdit(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('script-line-add')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('script-line-add')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('script-line-0')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('script-line-remove-0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('script-line-0')), findsNothing);
    });
  });
}
