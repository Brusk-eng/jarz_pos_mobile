import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_endpoint_roles.g.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';

import 'helpers.dart';
import 'inbox/ui_test_helpers.dart';

/// The fixtures show the founder's buttons. The fake API cuts every `actions`
/// list down to what the role may call (the contract's "Who may call" table,
/// generated), so a screen shows each role only what that role can do.
Future<dynamic> _call(FakeStudioApi api, String key) =>
    api.call('jarz_social.api.studio.$key');

Iterable<Map> _withActions(dynamic v) sync* {
  if (v is Map) {
    if (v['actions'] is List) yield v;
    for (final c in v.values) {
      yield* _withActions(c);
    }
  } else if (v is List) {
    for (final c in v) {
      yield* _withActions(c);
    }
  }
}

void main() {
  group('the fake API cuts actions by role', () {
    test('the generated table says who may call what', () {
      expect(studioEndpointRoles['versions.approve'], 'F');
      expect(studioEndpointRoles['ideas.keep'], 'F');
      expect(studioEndpointRoles['paid.ad_set_state'], 'F');
      expect(studioEndpointRoles['decisions.answer'], 'F');
      expect(studioEndpointRoles['pieces.assign'], 'FL');
    });

    test('every endpoint the action map points to exists in the table', () {
      for (final kind in fakeActionEndpoints.entries) {
        for (final e in kind.value.entries) {
          expect(
            studioEndpointRoles.containsKey(e.value),
            isTrue,
            reason: '${kind.key}.${e.key} -> ${e.value}',
          );
        }
      }
    });

    test('versions: only the founder gets approve and send back', () async {
      for (final role in ['founder', 'lead', 'creator', 'story']) {
        final api = FakeStudioApi(role: role, delay: Duration.zero);
        final feed = await _call(api, 'inbox.to_approve');
        final actions = [
          for (final m in _withActions(feed)) ...(m['actions'] as List),
        ];
        final isFounder = role == 'founder';
        expect(actions.contains('approve'), isFounder, reason: role);
        expect(actions.contains('fix'), isFounder, reason: role);
        if (!isFounder) {
          expect(actions.contains('clear_review'), isFalse, reason: role);
        }
      }
    });

    test('ideas: keep and drop are the founder\'s', () async {
      for (final role in ['founder', 'lead', 'creator', 'story']) {
        final api = FakeStudioApi(role: role, delay: Duration.zero);
        final list = await _call(api, 'ideas.list');
        final actions = [
          for (final m in _withActions(list)) ...(m['actions'] as List),
        ];
        expect(actions.contains('keep'), role == 'founder', reason: role);
        expect(actions.contains('drop'), role == 'founder', reason: role);
      }
    });

    test('paid: set state and edit are the founder\'s', () async {
      for (final role in ['founder', 'lead']) {
        final api = FakeStudioApi(role: role, delay: Duration.zero);
        final round = await _call(api, 'paid.round_get');
        final actions = [
          for (final m in _withActions(round)) ...(m['actions'] as List),
        ];
        expect(actions.contains('set_state'), role == 'founder', reason: role);
        expect(actions.contains('edit'), role == 'founder', reason: role);
      }
    });

    test('decisions: only the founder may answer', () async {
      for (final role in ['founder', 'lead', 'creator']) {
        final api = FakeStudioApi(role: role, delay: Duration.zero);
        final list = await _call(api, 'decisions.list');
        final actions = [
          for (final m in _withActions(list)) ...(m['actions'] as List),
        ];
        expect(actions.contains('answer'), role == 'founder', reason: role);
      }
    });

    test('pieces: assign is the founder\'s and the lead\'s', () async {
      for (final role in ['founder', 'lead', 'creator', 'story']) {
        final api = FakeStudioApi(role: role, delay: Duration.zero);
        final piece = await _call(api, 'pieces.get');
        final actions = [
          for (final m in _withActions(piece)) ...(m['actions'] as List),
        ];
        expect(
          actions.contains('assign'),
          role == 'founder' || role == 'lead',
          reason: role,
        );
      }
    });

    test('the founder keeps every fixture action (nothing is cut)', () async {
      final api = FakeStudioApi(role: 'founder', delay: Duration.zero);
      final raw = jsonDecode(studioFixtures['ideas.list']!);
      final list = await _call(api, 'ideas.list');
      expect(
        [for (final m in _withActions(list)) m['actions']],
        [for (final m in _withActions(raw)) m['actions']],
      );
    });
  });

  group('screens show each role its own buttons', () {
    for (final role in ['lead', 'creator', 'story']) {
      testWidgets('$role: a version page has no Approve or Send back', (
        tester,
      ) async {
        usePhone(tester, height: 2000);
        final api = fakeApi(role: role);
        final c = await pumpStudioWith(tester, api);
        await goTo(tester, c, '/versions/PC-00163-v2');
        expect(find.byKey(const ValueKey('action-approve')), findsNothing);
        expect(find.byKey(const ValueKey('action-fix')), findsNothing);
        expect(find.byKey(const ValueKey('action-clear')), findsNothing);
      });

      testWidgets('$role: Ideas have no Keep, Drop or Edit for others\'', (
        tester,
      ) async {
        usePhone(tester, height: 2000);
        final api = fakeApi(role: role);
        final c = await pumpStudioWith(tester, api);
        await goTo(tester, c, '/inbox/ideas');
        expect(find.byKey(const ValueKey('idea-keep')), findsNothing);
        expect(find.byKey(const ValueKey('idea-drop')), findsNothing);
      });
    }

    testWidgets('founder: a version page offers Approve and Send back', (
      tester,
    ) async {
      usePhone(tester, height: 2000);
      final api = fakeApi();
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/versions/PC-00163-v2');
      expect(find.byKey(const ValueKey('action-approve')), findsOneWidget);
      expect(find.byKey(const ValueKey('action-fix')), findsOneWidget);
    });

    testWidgets('founder: Ideas offer Keep and Drop', (tester) async {
      usePhone(tester, height: 2000);
      final api = fakeApi();
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/inbox/ideas');
      expect(find.byKey(const ValueKey('idea-keep')), findsWidgets);
      expect(find.byKey(const ValueKey('idea-drop')), findsWidgets);
    });

    testWidgets('lead: a paid round has no Set state and no pencil', (
      tester,
    ) async {
      usePhone(tester, height: 2400);
      final api = fakeApi(role: 'lead');
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/more/paid/rounds/R2b');
      expect(find.byKey(const ValueKey('set-state-AD-00013')), findsNothing);
      expect(find.byTooltip('Edit'), findsNothing);
    });

    testWidgets('founder: a paid round offers Set state', (tester) async {
      usePhone(tester, height: 2400);
      final api = fakeApi();
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/more/paid/rounds/R2b');
      expect(find.byKey(const ValueKey('set-state-AD-00013')), findsOneWidget);
    });

    testWidgets('lead: a decision is read-only with one line', (tester) async {
      usePhone(tester, height: 2600);
      final api = fakeApi(role: 'lead');
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/inbox/decisions');
      expect(find.byKey(const ValueKey('decision-confirm')), findsNothing);
      expect(find.byKey(const ValueKey('decision-note')), findsNothing);
      expect(
        find.textContaining('Only the founder answers this'),
        findsWidgets,
      );
      // Tapping an option does nothing: no pick, no confirm bar.
      await tester.tap(find.byKey(const ValueKey('option-1')).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('decision-confirm')), findsNothing);
      expect(api.calls, isNot(contains('decisions.answer')));
    });

    testWidgets('founder: a decision has the confirm bar', (tester) async {
      usePhone(tester, height: 2600);
      final api = fakeApi();
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/inbox/decisions');
      expect(find.byKey(const ValueKey('decision-confirm')), findsWidgets);
    });
  });
}
