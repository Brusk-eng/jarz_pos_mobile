import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';
import 'package:jarz_pos/src/studio/data/models/studio_enums.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';

import '../helpers.dart';
import '../inbox/ui_test_helpers.dart';

const _open = '/inbox/decisions/DEC-00012';
const _answered = '/inbox/decisions/DEC-00011';
const _question =
    'Which month do we film the founder series: December or January?';

Finder box() => find.byKey(const ValueKey('decision-text'));
Finder send() => find.byKey(const ValueKey('decision-send'));
bool sendEnabled(WidgetTester t) =>
    t.widget<FilledButton>(send()).onPressed != null;

void main() {
  group('A decision answered in words', () {
    testWidgets('the founder writes the answer and sends it', (tester) async {
      usePhone(tester, height: 1400);
      final api = fakeApi(textDecisions: true);
      await pumpMini(tester, api, location: _open);
      expect(find.text(_question), findsOneWidget);
      expect(find.byKey(const ValueKey('option-1')), findsNothing);
      expect(find.byKey(const ValueKey('decision-confirm')), findsNothing);
      await tester.enterText(box(), '  December, from the 6th.  ');
      await tester.pump();
      expect(sendEnabled(tester), isTrue);
      await tester.tap(send());
      await tester.pumpAndSettle();
      final call = api.callLog.lastWhere((c) => c.key == 'decisions.answer');
      expect(call.params['text'], 'December, from the 6th.');
      expect(call.params.containsKey('option_index'), isFalse);
      expect(call.params.containsKey('note'), isFalse);
      expect(find.byKey(const ValueKey('decision-answered')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('decision-answered')),
          matching: find.text('December, from the 6th.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('an empty or blank answer cannot be sent', (tester) async {
      usePhone(tester, height: 1400);
      final api = fakeApi(textDecisions: true);
      await pumpMini(tester, api, location: _open);
      expect(sendEnabled(tester), isFalse);
      expect(find.text('Write the answer first'), findsOneWidget);
      await tester.enterText(box(), '   \n  ');
      await tester.pump();
      expect(sendEnabled(tester), isFalse);
      expect(api.calls, isNot(contains('decisions.answer')));
    });

    testWidgets('the counter runs to 2000 and the box stops there', (
      tester,
    ) async {
      usePhone(tester, height: 1400);
      await pumpMini(tester, fakeApi(textDecisions: true), location: _open);
      expect(find.textContaining('0 / 2000'), findsOneWidget);
      await tester.enterText(box(), 'x' * 2100);
      await tester.pump();
      expect(find.textContaining('2000 / 2000'), findsOneWidget);
    });

    testWidgets('someone who is not the founder only reads it', (tester) async {
      usePhone(tester, height: 1400);
      final api = fakeApi(role: 'lead', textDecisions: true);
      await pumpMini(tester, api, location: _open);
      expect(find.text(_question), findsOneWidget);
      expect(box(), findsNothing);
      expect(send(), findsNothing);
      expect(find.textContaining('Only the founder answers'), findsOneWidget);
    });

    testWidgets('an answered one shows the words, who and when, read-only', (
      tester,
    ) async {
      usePhone(tester, height: 1400);
      await pumpMini(tester, fakeApi(textDecisions: true), location: _answered);
      expect(box(), findsNothing);
      expect(send(), findsNothing);
      expect(
        find.text(
          'How We Got Here. Keep the English name on the Arabic posts too.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Abdelrahman'), findsWidgets);
    });

    testWidgets('a server error on the text shows under the box', (
      tester,
    ) async {
      usePhone(tester, height: 1400);
      final api = fakeApi(textDecisions: true)
        ..failNext(
          'decisions.answer',
          'VALIDATION',
          field: 'text',
          message: 'The answer can be 2000 characters at most.',
        );
      await pumpMini(tester, api, location: _open);
      await tester.enterText(box(), 'January');
      await tester.pump();
      await tester.tap(send());
      await tester.pumpAndSettle();
      expect(
        find.text('The answer can be 2000 characters at most.'),
        findsOneWidget,
      );
      // Typing again clears it.
      await tester.enterText(box(), 'January 2027');
      await tester.pump();
      expect(
        find.text('The answer can be 2000 characters at most.'),
        findsNothing,
      );
    });

    testWidgets('ALREADY_DONE says so and shows the stored answer', (
      tester,
    ) async {
      usePhone(tester, height: 1400);
      final api = fakeApi(textDecisions: true)
        ..failNext('decisions.answer', 'ALREADY_DONE');
      await pumpMini(tester, api, location: _open);
      await tester.enterText(box(), 'January');
      await tester.pump();
      await tester.tap(send());
      await tester.pumpAndSettle();
      expect(find.textContaining('Already done'), findsOneWidget);
      expect(find.textContaining('went wrong'), findsNothing);
    });

    testWidgets('it sits in the same Inbox list and counts in the badge', (
      tester,
    ) async {
      usePhone(tester, height: 3000);
      final api = fakeApi(textDecisions: true);
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/inbox/decisions');
      expect(find.byKey(const ValueKey('decision-DEC-00007')), findsOneWidget);
      expect(find.byKey(const ValueKey('decision-DEC-00012')), findsOneWidget);
      expect(find.byKey(const ValueKey('decision-DEC-00011')), findsNothing);
      expect((await tester.runAsync(api.inboxCounts))!.decisions, 2);
      await tester.enterText(box(), 'January');
      await tester.pump();
      await tester.tap(send());
      await tester.pumpAndSettle();
      expect((await tester.runAsync(api.inboxCounts))!.decisions, 1);
    });

    test('the fake refuses a wrong combination like the server', () async {
      final api = fakeApi(textDecisions: true);
      Future<String?> field(Future<Object?> call) async {
        try {
          await call;
        } catch (e) {
          return (e as dynamic).field as String?;
        }
        return 'accepted';
      }

      expect(
        await field(api.decisionsAnswer(decisionId: 'DEC-00012', text: '')),
        'text',
      );
      expect(
        await field(
          api.decisionsAnswer(decisionId: 'DEC-00012', optionIndex: 1),
        ),
        'option_index',
      );
      expect(
        await field(
          api.decisionsAnswer(decisionId: 'DEC-00012', text: 'a', note: 'n'),
        ),
        'note',
      );
      expect(
        await field(
          api.decisionsAnswer(decisionId: 'DEC-00012', text: 'x' * 2001),
        ),
        'text',
      );
      expect(
        await field(api.decisionsAnswer(decisionId: 'DEC-00007', text: 'a')),
        'text',
      );
      expect(
        await field(api.decisionsAnswer(decisionId: 'DEC-00007')),
        'option_index',
      );
    });
  });

  group('Decisions from a server before v1.2', () {
    test('a row without answer_kind reads as an option decision', () {
      final json = jsonDecode(studioFixtures['decisions.get']!) as Map;
      json.remove('answer_kind');
      json.remove('answer_text');
      final d = StudioDecision.fromJson(Map<String, dynamic>.from(json));
      expect(d.answerKind, DecisionKind.option);
      expect(d.answerText, isNull);
      expect(d.options, isNotEmpty);
    });

    test('a text decision reads as text', () {
      final d = StudioDecision.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(studioFixtures['decisions.get.text_answered']!) as Map,
        ),
      );
      expect(d.answerKind, DecisionKind.text);
      expect(d.options, isEmpty);
      expect(d.answerText, startsWith('How We Got Here'));
    });
  });
}
