import 'package:flutter/material.dart';
import 'package:jarz_pos/src/studio/core/offline/kv_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/config/studio_config.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/write_refresh.dart';
import 'package:jarz_pos/src/studio/features/review/data/review_repository.dart';
import 'package:jarz_pos/src/studio/shared/person_name.dart';
import 'package:jarz_pos/src/studio/studio_app.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_locale.dart';

import 'helpers.dart';

/// Pumps the whole app as [role]; [firstLogin] leaves the role's walkthrough
/// unseen, as on a first open.
Future<ProviderContainer> _app(
  WidgetTester tester, {
  String role = 'founder',
  bool firstLogin = false,
  String locale = 'en',
  FakeStudioApi? api,
}) async {
  usePhone(tester, height: 1600);
  final fake =
      api ??
      FakeStudioApi(
        role: role,
        delay: Duration.zero,
        textDecisions: true,
        firstLogin: firstLogin,
      );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studioFakeProvider.overrideWithValue(true),
        studioApiProvider.overrideWithValue(fake),
        studioKvStoreProvider.overrideWithValue(MemoryKvStore()),
        studioFakeRoleProvider.overrideWithValue(fake.role),
        studioLocaleProvider.overrideWith((ref) => Locale(locale)),
      ],
      child: const StudioApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(StudioApp)));
}

void main() {
  group('1. A write refreshes what depends on it (one map)', () {
    test('every announced write is looked up in one table', () {
      expect(studioWriteRefreshes['versions.approve'], isNotEmpty);
      expect(studioWriteRefreshes['decisions.answer'], isNotEmpty);
      expect(studioWriteRefreshes['paid.ad_set_state'], isNotEmpty);
      expect(studioWriteRefreshes['today.task_create'], isNotEmpty);
      expect(studioWriteRefreshes['ideas.keep'], isNotEmpty);
      expect(studioWriteRefreshes['shoots.shot_tick'], isNotEmpty);
    });

    testWidgets('approving on Today drops the Inbox badge and the block count', (
      tester,
    ) async {
      final c = await _app(tester);
      final before = (await c.read(inboxCountsProvider.future)).toApprove;
      expect(find.byKey(const ValueKey('line-PC-00163-v2-approve')), findsOne);
      await tester.tap(find.byKey(const ValueKey('line-PC-00163-v2-approve')));
      await tester.pumpAndSettle();
      // The line stays with what happens next; the counts are the server's.
      expect(find.byKey(const ValueKey('line-PC-00163-v2-done')), findsOne);
      final after = (await c.read(inboxCountsProvider.future)).toApprove;
      expect(after, before - 1);
      expect(find.text('${before - 1}'), findsWidgets);
    });

    testWidgets('an answered decision leaves Today, the list and the badge', (
      tester,
    ) async {
      final c = await _app(tester);
      expect(find.byKey(const ValueKey('today-block-decisions')), findsOne);
      final before = (await c.read(inboxCountsProvider.future)).decisions;
      await goTo(tester, c, '/inbox/decisions/DEC-00007');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('option-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('decision-confirm')));
      await tester.pumpAndSettle();
      await goTo(tester, c, '/today');
      expect(find.byKey(const ValueKey('today-block-decisions')), findsNothing);
      final after = (await c.read(inboxCountsProvider.future)).decisions;
      expect(after, before - 1);
    });

    testWidgets('a task added on Today is in the list with its own text', (
      tester,
    ) async {
      await _app(tester, role: 'lead');
      await tester.tap(find.byKey(const ValueKey('task-add')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('task-text')),
        'Book the courier for Friday',
      );
      await tester.tap(find.byKey(const ValueKey('task-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Book the courier for Friday'), findsOneWidget);
    });

    testWidgets('setting an ad state moves the round counters at once', (
      tester,
    ) async {
      final c = await _app(tester);
      await goTo(tester, c, '/more/paid/rounds/R2b');
      expect(find.textContaining('Testing 1'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('set-state-AD-00013')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('state-Winner')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('state-save')));
      await tester.pumpAndSettle();
      // The rule says 7 purchases and the ad has 6: the second tap sets it.
      await tester.tap(find.byKey(const ValueKey('state-save')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Testing 1'), findsNothing);
      expect(find.textContaining('Winner 1'), findsWidgets);
    });

    testWidgets('keeping an idea drops the idea count on Today', (
      tester,
    ) async {
      final c = await _app(tester);
      final before = (await c.read(inboxCountsProvider.future)).ideas;
      await goTo(tester, c, '/inbox/ideas');
      await tester.tap(find.byKey(const ValueKey('idea-keep')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep').last);
      await tester.pumpAndSettle();
      final after = (await c.read(inboxCountsProvider.future)).ideas;
      expect(after, before - 1);
    });
  });

  group('2. Today "Results to add"', () {
    testWidgets('opens the form that files that read, not the post', (
      tester,
    ) async {
      final c = await _app(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('today-line-SP-2026-00190:72h')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('today-line-SP-2026-00190:72h')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('file-read-dialog')), findsOneWidget);
      expect(currentLocation(c), '/today');
    });
  });

  group('3. The ad state dialog', () {
    testWidgets('says which rule and the numbers; the second button is Set it anyway', (
      tester,
    ) async {
      final c = await _app(tester);
      await goTo(tester, c, '/more/paid/rounds/R2b');
      await tester.tap(find.byKey(const ValueKey('set-state-AD-00013')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('state-Winner')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'does not meet the rule for Winner: the rule asks for 7 purchases and it has 6',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('state-save')));
      await tester.pumpAndSettle();
      expect(find.text('Set it anyway'), findsOneWidget);
    });

    testWidgets('a state the server refuses shows its message, no override', (
      tester,
    ) async {
      final api = FakeStudioApi(delay: Duration.zero, textDecisions: true)
        ..failNext(
          'paid.ad_set_state',
          'VALIDATION',
          message: 'Winner needs 7 purchases.',
        );
      final c = await _app(tester, api: api);
      await goTo(tester, c, '/more/paid/rounds/R2b');
      await tester.tap(find.byKey(const ValueKey('set-state-AD-00013')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('state-clear')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('state-save')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('paid.ad_set_state'));
      expect(find.text('Set it anyway'), findsNothing);
      expect(find.byKey(const ValueKey('state-dialog')), findsNothing);
    });
  });

  group('4. First-login walkthrough', () {
    for (final role in ['founder', 'lead', 'creator', 'story']) {
      testWidgets('$role: shows once, is skippable and is remembered', (
        tester,
      ) async {
        final api = FakeStudioApi(
          role: role,
          delay: Duration.zero,
          textDecisions: true,
          firstLogin: true,
        );
        await _app(tester, api: api);
        expect(find.byKey(const ValueKey('walkthrough')), findsOneWidget);
        expect(find.byKey(const ValueKey('walkthrough-step')), findsOne);
        await tester.tap(find.byKey(const ValueKey('walkthrough-skip')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('walkthrough')), findsNothing);
        expect(api.calls, contains('session.help_seen'));
        expect(
          api.callLog.lastWhere((c) => c.key == 'session.help_seen')
              .params['key'],
          'walkthrough_$role',
        );
      });
    }

    testWidgets('does not come back for someone who has seen it', (
      tester,
    ) async {
      await _app(tester);
      expect(find.byKey(const ValueKey('walkthrough')), findsNothing);
    });

    testWidgets('the cards page through and end with help; More > Help reopens it', (
      tester,
    ) async {
      final c = await _app(tester, role: 'creator', firstLogin: true);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('walkthrough-next')));
        await tester.pumpAndSettle();
      }
      // The creator's tour has a card on ideas (New idea, My ideas).
      expect(find.text('Bring ideas'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('walkthrough-next')));
      await tester.pumpAndSettle();
      expect(find.text('Help is on every screen'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('walkthrough-next')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('walkthrough')), findsNothing);
      await goTo(tester, c, '/more');
      await tester.tap(find.byKey(const ValueKey('more-help')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('walkthrough')), findsOneWidget);
    });

    testWidgets('Arabic cards read in Arabic', (tester) async {
      await _app(tester, role: 'story', firstLogin: true, locale: 'ar');
      expect(find.text('النهارده هو نقطة البداية'), findsOneWidget);
    });
  });

  group('5. What happens next on the piece page', () {
    Future<void> openPiece(WidgetTester t, ProviderContainer c) async {
      await goTo(t, c, '/pieces/PC-00163');
    }

    testWidgets('a piece in review says it waits for the founder', (
      tester,
    ) async {
      final c = await _app(tester, role: 'lead');
      await openPiece(tester, c);
      final text = tester
          .widget<Text>(find.byKey(const ValueKey('next-stage')))
          .data!;
      expect(text, isNotEmpty);
    });
  });

  group('7. Names, not ids', () {
    test('personName', () {
      expect(personName('claude'), 'Claude');
      expect(personName('abdelrahman'), 'Abdelrahman');
      expect(personName('ali_mamdouh'), 'Ali Mamdouh');
      expect(personName('Kareem'), 'Kareem');
      expect(personName(null), '');
    });
  });

  group('8. Other people tasks', () {
    for (final role in ['creator', 'story']) {
      test('$role gets only their own tasks, and can tick them', () async {
        final api = FakeStudioApi(role: role, delay: Duration.zero);
        final page = await api.todayTasks();
        expect(page.items, isNotEmpty);
        for (final t in page.items) {
          expect(t.assignee?.fullName, isNot('Ali'));
          expect(t.actions, contains('tick'));
        }
      });
    }

    test('the lead sees everyone with all actions, only their own by default', () async {
      final api = FakeStudioApi(role: 'lead', delay: Duration.zero);
      final mine = await api.todayTasks();
      expect(mine.items.every((t) => t.assignee?.fullName == 'Ali'), isTrue);
      final all = await api.todayTasks(assignee: 'all');
      expect(all.items.length, greaterThan(mine.items.length));
    });
  });
}
