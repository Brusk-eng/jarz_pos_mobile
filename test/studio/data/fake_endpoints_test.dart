import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/models/studio_enums.dart';
import 'package:jarz_pos/src/studio/data/studio_error.dart';

import 'generated/endpoint_calls.g.dart';

void main() {
  FakeStudioApi fake({String role = 'founder'}) =>
      FakeStudioApi(role: role, delay: Duration.zero);

  test('113 app endpoints are wired (the service group is not)', () {
    expect(endpointCalls, hasLength(113));
    expect(endpointCalls.keys.where((k) => k.startsWith('service.')), isEmpty);
  });

  group('the fake returns each endpoint as its model', () {
    for (final e in endpointCalls.entries) {
      test(e.key, () async {
        final r = await e.value(fake());
        expect(r, isNotNull);
        expect(r.runtimeType.toString(), isNot('_Map<String, dynamic>'));
      });
    }
  });

  group('role variants', () {
    test('me and today follow the role', () async {
      for (final role in ['founder', 'lead', 'creator', 'story']) {
        final me = await fake(role: role).sessionMe();
        expect(me.roles, isNotEmpty, reason: role);
        final today = await fake(role: role).todayGet();
        expect(today.role, isNotNull, reason: role);
      }
      final none = await fake(role: 'none').sessionMe();
      expect(none.roles, isEmpty);
      expect(none.nav, isEmpty);
      expect(none.studioRole, isNull);
    });
  });

  group('simulated writes', () {
    test(
      'approve returns the updated version and empties the feed slot',
      () async {
        final api = fake();
        final before = await api.inboxToApprove();
        final id = before.items.first.version.id;
        final counts0 = await api.inboxCounts();

        final v = await api.versionsApprove(versionId: id);
        expect(v.id, id);
        expect(v.reviewOutcome, ReviewOutcome.approved);
        expect(v.awaitingReview, isFalse);

        final after = await api.inboxToApprove();
        expect(after.items.map((c) => c.version.id), isNot(contains(id)));
        expect(after.items.length, before.items.length - 1);
        final counts1 = await api.inboxCounts();
        expect(counts1.toApprove, counts0.toApprove - 1);
        expect(counts1.total, counts0.total - 1);

        // Clearing the review puts it back.
        final cleared = await api.versionsClearReview(versionId: id);
        expect(cleared.reviewOutcome, isNull);
        expect(cleared.awaitingReview, isTrue);
        final back = await api.inboxToApprove();
        expect(back.items.length, before.items.length);
      },
    );

    test('fix needs a reason', () async {
      final api = fake();
      await expectLater(
        api.versionsFix(versionId: 'PC-00188-v1', reason: ''),
        throwsA(isA<StudioValidation>()),
      );
      final v = await api.versionsFix(
        versionId: 'PC-00188-v1',
        reason: 'Too dark',
      );
      expect(v.reviewOutcome, ReviewOutcome.fix);
      expect(v.reviewReason, 'Too dark');
    });

    test('rate stores my rating', () async {
      final v = await fake().versionsRate(
        versionId: 'PC-00188-v1',
        score: 4,
        comment: 'nice',
      );
      expect(v.myRating?.score, 4);
      expect(v.myRating?.comment, 'nice');
    });

    test('tick, answer a decision, keep and drop an idea', () async {
      final api = fake();
      final t = await api.todayTaskTick(taskId: 'TASK-000191');
      expect(t.done, isTrue);
      expect(t.id, 'TASK-000191');

      final d = await api.decisionsAnswer(
        decisionId: 'DEC-00007',
        optionIndex: 1,
        note: 'go',
      );
      expect(d.status, DecisionStatus.answered);
      expect(d.pickedIndex, 1);
      // A later read of the same decision shows it.
      final again = await api.decisionsGet(decisionId: 'DEC-00007');
      expect(again.status, DecisionStatus.answered);

      final k = await api.ideasKeep(ideaId: 'IDEA-00012');
      expect(k.idea.status, IdeaStatus.kept);
      final dr = await api.ideasDrop(ideaId: 'IDEA-00013', reason: 'no');
      expect(dr.status, IdeaStatus.dropped);
      final list = await api.ideasList();
      final kept = list.items.where((i) => i.id == 'IDEA-00012');
      expect(kept.every((i) => i.status == IdeaStatus.kept), isTrue);
    });
  });

  group('forced failures', () {
    test('failNext fails one call with the chosen contract code', () async {
      final api = fake()..failNext('versions.approve', 'SHADOW_MODE');
      await expectLater(
        api.versionsApprove(versionId: 'PC-1-v1'),
        throwsA(isA<StudioShadowMode>()),
      );
      // Only once.
      expect((await api.versionsApprove(versionId: 'PC-1-v1')).id, 'PC-1-v1');
    });

    test('every code can be forced, with overrides', () async {
      for (final code in [
        'UNAUTHENTICATED',
        'NOT_PERMITTED',
        'NOT_FOUND',
        'VALIDATION',
        'GATE_FAILED',
        'STALE',
        'ALREADY_DONE',
        'SHADOW_MODE',
        'RATE_LIMITED',
        'SERVER_ERROR',
      ]) {
        final api = fake()..failNext('*', code);
        try {
          await api.inboxCounts();
          fail('should have failed with $code');
        } on StudioError catch (e) {
          expect(e.code, code);
        }
      }
      final api = fake()
        ..failNext('pieces', 'VALIDATION', message: 'custom', field: 'to');
      try {
        await api.piecesMove(pieceId: 'PC-1', to: 'Script');
        fail('no failure');
      } on StudioValidation catch (e) {
        expect(e.message, 'custom');
        expect(e.field, 'to');
      }
    });

    test('failAlways lasts until cleared', () async {
      final api = fake()..failAlways('inbox.counts', 'SERVER_ERROR');
      for (var i = 0; i < 3; i++) {
        await expectLater(api.inboxCounts(), throwsA(isA<StudioServerError>()));
      }
      api.clearFailures();
      expect((await api.inboxCounts()).total, isNonNegative);
      expect(api.calls.where((c) => c == 'inbox.counts'), hasLength(4));
    });
  });
}
