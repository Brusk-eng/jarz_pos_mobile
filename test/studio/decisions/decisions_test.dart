import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';

import '../helpers.dart';
import '../inbox/ui_test_helpers.dart';

Finder confirmButton() => find.byKey(const ValueKey('decision-confirm'));

bool confirmEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(confirmButton()).onPressed != null;

Future<void> openDecisions(WidgetTester tester, dynamic container) async {
  await goTo(tester, container, '/inbox/decisions');
}

void main() {
  group('Decision card', () {
    testWidgets(
      'shows the question, every option with its parts and the report link',
      (tester) async {
        usePhone(tester, height: 2600);
        final c = await pumpStudioWith(tester, fakeApi());
        await openDecisions(tester, c);
        expect(
          find.text('Raise the WIN budget step from 3,000 to 3,750 a day?'),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('option-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('option-2')), findsOneWidget);
        expect(find.byKey(const ValueKey('option-3')), findsOneWidget);
        // Recommended is marked on exactly one option.
        expect(find.byKey(const ValueKey('recommended')), findsOneWidget);
        expect(
          find.textContaining('Gates 1 and 5 do not hold yet'),
          findsOneWidget,
        );
        expect(
          find.textContaining('We miss the December push window.'),
          findsOneWidget,
        );
        expect(
          find.textContaining('When tagged orders are under 90%.'),
          findsOneWidget,
        );
        expect(find.textContaining('Ads read, Wed 25 Nov'), findsOneWidget);
      },
    );

    testWidgets('founder picks any option with a note and confirms once', (
      tester,
    ) async {
      usePhone(tester, height: 2600);
      final api = fakeApi();
      final c = await pumpStudioWith(tester, api);
      await openDecisions(tester, c);
      expect(confirmEnabled(tester), isFalse);
      await tester.tap(find.byKey(const ValueKey('option-2')));
      await tester.pump();
      expect(confirmEnabled(tester), isTrue);
      await tester.enterText(
        find.byKey(const ValueKey('decision-note')),
        'After two clean weeks',
      );
      await tester.tap(confirmButton());
      await tester.pumpAndSettle();
      expect(api.calls.where((x) => x == 'decisions.answer').length, 1);
      expect(find.byKey(const ValueKey('decision-answered')), findsOneWidget);
      expect(confirmButton(), findsNothing);
      expect(find.text('Pick saved'), findsOneWidget);
    });

    testWidgets(
      'SHADOW_MODE says the Studio is not switched on; the pick can be retried',
      (tester) async {
        usePhone(tester, height: 2600);
        final api = fakeApi()..failNext('decisions.answer', 'SHADOW_MODE');
        final c = await pumpStudioWith(tester, api);
        await openDecisions(tester, c);
        await tester.tap(find.byKey(const ValueKey('option-1')));
        await tester.pump();
        await tester.tap(confirmButton());
        await tester.pumpAndSettle();
        expect(find.textContaining('not switched on yet'), findsOneWidget);
        expect(confirmButton(), findsOneWidget);
        // Retry works.
        await tester.tap(confirmButton());
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('decision-answered')), findsOneWidget);
      },
    );

    testWidgets('NOT_PERMITTED is shown in plain words and nothing is picked', (
      tester,
    ) async {
      usePhone(tester, height: 2600);
      final api = fakeApi()..failNext('decisions.answer', 'NOT_PERMITTED');
      final c = await pumpStudioWith(tester, api);
      await openDecisions(tester, c);
      await tester.tap(find.byKey(const ValueKey('option-3')));
      await tester.pump();
      await tester.tap(confirmButton());
      await tester.pumpAndSettle();
      expect(find.textContaining('not allowed'), findsOneWidget);
      expect(find.byKey(const ValueKey('decision-answered')), findsNothing);
    });

    testWidgets('a rate limit is shown in plain words', (tester) async {
      usePhone(tester, height: 2600);
      final api = fakeApi()..failNext('decisions.answer', 'RATE_LIMITED');
      final c = await pumpStudioWith(tester, api);
      await openDecisions(tester, c);
      await tester.tap(find.byKey(const ValueKey('option-1')));
      await tester.pump();
      await tester.tap(confirmButton());
      await tester.pumpAndSettle();
      expect(find.textContaining('Too many tries'), findsOneWidget);
    });

    testWidgets(
      'ALREADY_DONE says it was already done and the first answer stands',
      (tester) async {
        usePhone(tester, height: 2600);
        final api = fakeApi()
          ..failNext(
            'decisions.answer',
            'ALREADY_DONE',
            current: jsonDecode(studioFixtures['decisions.answer']!),
          );
        final c = await pumpStudioWith(tester, api);
        await openDecisions(tester, c);
        await tester.tap(find.byKey(const ValueKey('option-1')));
        await tester.pump();
        await tester.tap(confirmButton());
        await tester.pumpAndSettle();
        expect(find.textContaining('already done'), findsOneWidget);
        expect(find.textContaining('went wrong'), findsNothing);
        expect(find.textContaining('not allowed'), findsNothing);
      },
    );

    testWidgets('no confirm button without the answer action (lead)', (
      tester,
    ) async {
      usePhone(tester, height: 2600);
      final api = fakeApi(
        role: 'lead',
        edits: {
          'decisions.list': (j) {
            for (final d in j['items']) {
              d['actions'] = [];
            }
          },
        },
      );
      final c = await pumpStudioWith(tester, api);
      await openDecisions(tester, c);
      expect(find.byKey(const ValueKey('option-1')), findsOneWidget);
      expect(confirmButton(), findsNothing);
      expect(find.byKey(const ValueKey('decision-note')), findsNothing);
      expect(find.textContaining('Waiting for the founder'), findsOneWidget);
    });

    testWidgets('an answered decision is read-only and shows the pick', (
      tester,
    ) async {
      usePhone(tester, height: 2600);
      final api = fakeApi(
        edits: {
          'decisions.list': (j) {
            for (final d in j['items']) {
              d['status'] = 'Answered';
              d['picked_index'] = 1;
              d['pick_note'] = 'Gates first';
              d['answered_by'] = {
                'key': 'abdelrahman',
                'full_name': 'Abdelrahman',
              };
              d['answered_at'] = '2026-11-25T10:00:00+02:00';
              d['actions'] = [];
            }
          },
        },
      );
      final c = await pumpStudioWith(tester, api);
      await openDecisions(tester, c);
      await tester.tap(find.text('Answered'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('decision-answered')), findsOneWidget);
      expect(
        find.textContaining('Picked: Hold WIN at 3,000 a day'),
        findsOneWidget,
      );
      expect(find.textContaining('Gates first'), findsOneWidget);
      expect(confirmButton(), findsNothing);
    });

    testWidgets('empty Open tab says what to do; error offers retry', (
      tester,
    ) async {
      usePhone(tester, height: 900);
      final api = fakeApi(edits: {'decisions.list': (j) => j['items'] = []})
        ..failNext('decisions.list', 'SERVER_ERROR');
      final c = await pumpStudioWith(tester, api);
      await openDecisions(tester, c);
      expect(find.byKey(const ValueKey('error-text')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('empty-purpose')), findsOneWidget);
      expect(find.textContaining('No open decisions'), findsOneWidget);
    });

    testWidgets('Arabic card runs right to left', (tester) async {
      usePhone(tester, height: 2600);
      final c = await pumpStudioWith(tester, fakeApi(), locale: 'ar');
      await openDecisions(tester, c);
      expect(find.text('أكّد الاختيار'), findsNothing); // disabled label first
      expect(find.text('اختار خيار'), findsOneWidget);
      expect(
        Directionality.of(
          tester.element(find.byKey(const ValueKey('decision-question'))),
        ),
        TextDirection.rtl,
      );
    });
  });

  group('Decision detail route', () {
    testWidgets('opens one decision by id and answers it', (tester) async {
      usePhone(tester, height: 2600);
      final api = fakeApi();
      await pumpMini(tester, api, location: '/inbox/decisions/DEC-00007');
      expect(find.byKey(const ValueKey('decision-DEC-00007')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('option-1')));
      await tester.pump();
      await tester.tap(confirmButton());
      await tester.pumpAndSettle();
      expect(api.calls, contains('decisions.answer'));
      expect(find.byKey(const ValueKey('decision-answered')), findsOneWidget);
    });

    testWidgets('NOT_FOUND shows the error state with retry', (tester) async {
      usePhone(tester, height: 900);
      final api = fakeApi()..failNext('decisions.get', 'NOT_FOUND');
      await pumpMini(tester, api, location: '/inbox/decisions/DEC-00099');
      expect(find.byKey(const ValueKey('error-text')), findsOneWidget);
    });
  });
}
