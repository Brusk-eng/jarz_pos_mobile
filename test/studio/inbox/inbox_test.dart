import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/router/studio_router.dart';
import 'package:jarz_pos/src/studio/features/inbox/state/inbox_state.dart';
import 'package:jarz_pos/src/studio/features/review/data/review_repository.dart';

import '../helpers.dart';
import 'ui_test_helpers.dart';

Finder tile(String name) => find.byKey(ValueKey('inbox-tab-$name'));

void main() {
  group('Inbox hub shows only the tiles a role works in', () {
    testWidgets('founder: five tiles with their counts', (tester) async {
      usePhone(tester, height: 900);
      final c = await pumpStudioWith(tester, fakeApi());
      await goTo(tester, c, '/inbox/approve');
      for (final n in [
        'approve',
        'rate',
        'decisions',
        'ideas',
        'notifications',
      ]) {
        expect(tile(n), findsOneWidget, reason: n);
      }
      String count(String n) => (tester.widget<Text>(
        find.descendant(
          of: tile(n),
          matching: find.byKey(const ValueKey('tile-count')),
        ),
      )).data!;
      expect(count('approve'), '3');
      expect(count('rate'), '2');
      expect(count('decisions'), '1');
      expect(count('ideas'), '7');
      expect(count('notifications'), '4');
    });

    testWidgets('lead: no To approve tile, lands on Decisions', (tester) async {
      usePhone(tester, height: 900);
      final c = await pumpStudioWith(tester, fakeApi(role: 'lead'));
      await goTo(tester, c, '/inbox/approve');
      expect(tile('approve'), findsNothing);
      expect(tile('decisions'), findsOneWidget);
      expect(currentLocation(c), '/inbox/decisions');
    });

    for (final role in ['creator', 'story']) {
      testWidgets('$role: rate, ideas, notifications only', (tester) async {
        usePhone(tester, height: 900);
        final c = await pumpStudioWith(tester, fakeApi(role: role));
        await goTo(tester, c, '/inbox/approve');
        expect(tile('approve'), findsNothing);
        expect(tile('decisions'), findsNothing);
        expect(tile('rate'), findsOneWidget);
        expect(tile('ideas'), findsOneWidget);
        expect(tile('notifications'), findsOneWidget);
        expect(currentLocation(c), '/inbox/ideas');
      });
    }

    testWidgets('tiles navigate: tab tiles go, the others push', (
      tester,
    ) async {
      usePhone(tester, height: 900);
      final c = await pumpStudioWith(tester, fakeApi());
      await goTo(tester, c, '/inbox/approve');
      await tester.tap(tile('ideas'));
      await tester.pumpAndSettle();
      expect(currentLocation(c), '/inbox/ideas');
      await tester.tap(tile('rate'));
      await tester.pumpAndSettle();
      expect(topLocation(c), '/inbox/rate');
    });

    testWidgets('the notifications tile opens the notifications route', (
      tester,
    ) async {
      usePhone(tester, height: 900);
      final c = await pumpStudioWith(tester, fakeApi());
      await goTo(tester, c, '/inbox/approve');
      await tester.tap(tile('notifications'));
      await tester.pumpAndSettle();
      expect(topLocation(c), '/inbox/notifications');
    });

    testWidgets('the badge provider follows the counts', (tester) async {
      usePhone(tester, height: 900);
      final c = await pumpStudioWith(tester, fakeApi());
      final sub = c.listen(inboxCountsProvider, (_, _) {});
      addTearDown(sub.close);
      await tester.pumpAndSettle();
      expect(c.read(inboxBadgeProvider), 11);
    });

    testWidgets('Arabic hub uses Arabic words and runs RTL', (tester) async {
      usePhone(tester, height: 900);
      final c = await pumpStudioWith(tester, fakeApi(), locale: 'ar');
      await goTo(tester, c, '/inbox/approve');
      expect(find.text('للموافقة'), findsWidgets);
      expect(find.text('الإشعارات'), findsWidgets);
      expect(
        Directionality.of(tester.element(tile('approve'))),
        TextDirection.rtl,
      );
    });
  });

  group('To approve list', () {
    testWidgets('rows show title, flavour, slot, verdict, score, wait', (
      tester,
    ) async {
      usePhone(tester, height: 1200);
      final c = await pumpStudioWith(
        tester,
        fakeApi(),
        now: DateTime(2026, 11, 25, 12),
      );
      await goTo(tester, c, '/inbox/approve');
      final row = find.byKey(const ValueKey('approve-PC-00163-v2'));
      expect(row, findsOneWidget);
      expect(
        find.descendant(of: row, matching: find.text('#3 Thank you, me')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('RUN')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('sell 4.2')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: row,
          matching: find.textContaining('waiting 1 day'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.textContaining('Red Velvet')),
        findsOneWidget,
      );
    });

    testWidgets('a row opens the version screen route', (tester) async {
      usePhone(tester, height: 1200);
      final c = await pumpStudioWith(tester, fakeApi());
      await goTo(tester, c, '/inbox/approve');
      await tester.tap(find.byKey(const ValueKey('approve-PC-00188-v1')));
      await tester.pumpAndSettle();
      expect(topLocation(c), '/inbox/approve/PC-00188-v1');
    });

    testWidgets('empty state says what happens next', (tester) async {
      usePhone(tester, height: 900);
      final c = await pumpStudioWith(
        tester,
        fakeApi(edits: {'inbox.to_approve': (j) => j['items'] = []}),
      );
      await goTo(tester, c, '/inbox/approve');
      expect(find.byKey(const ValueKey('empty-purpose')), findsOneWidget);
      expect(find.textContaining('lands here'), findsOneWidget);
    });

    testWidgets('error state offers retry and recovers', (tester) async {
      usePhone(tester, height: 900);
      final api = fakeApi()..failNext('inbox.to_approve', 'SERVER_ERROR');
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/inbox/approve');
      expect(find.byKey(const ValueKey('error-text')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('approve-list')), findsOneWidget);
    });

    testWidgets('loading skeleton shows while the list loads', (tester) async {
      usePhone(tester, height: 900);
      final api = fakeApi(delay: const Duration(milliseconds: 200));
      final c = await pumpStudioWith(tester, api, settle: false);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      c.read(studioRouterProvider).go('/inbox/approve');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const ValueKey('skeleton')), findsWidgets);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const ValueKey('approve-list')), findsOneWidget);
    });
  });
}
