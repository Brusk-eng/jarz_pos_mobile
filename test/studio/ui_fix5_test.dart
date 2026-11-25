import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/l10n/plural.dart';

import 'helpers.dart';

/// Round 5: what the fourth day-one walk found.
void main() {
  group('12. Arabic counts follow the Arabic number rules (one helper)', () {
    test('1, 2, 3 to 10 and 11 and over', () {
      expect(arPiece.of(1), 'قطعة');
      expect(arPiece.of(2), 'قطعتين');
      expect(arPiece.of(9), '9 قطع');
      expect(arPiece.of(11), '11 قطعة');
      expect(arRating.of(3), '3 تقييمات');
      expect(arRating.of(71), '71 تقييم');
      expect(arOpenPiece.of(9), '9 قطع مفتوحة');
      expect(arComment.of(18), '18 تعليق');
      expect(arDay.of(7), '7 أيام');
      expect(arDay.of(30), '30 يوم');
    });

    testWidgets('Team ratings in Arabic: «9 قطع مفتوحة», «3 تقييمات»', (
      tester,
    ) async {
      usePhone(tester, height: 2400);
      final c = await pumpStudio(tester, locale: 'ar');
      await goTo(tester, c, '/more/results/ratings');
      // The sample holds 9 open pieces and 71 ratings: 3 to 10 take the plural
      // noun, 11 and over the singular.
      expect(find.text('9 قطع مفتوحة'), findsOneWidget);
      expect(find.text('71 تقييم'), findsOneWidget);
      expect(find.textContaining('9 قطعة'), findsNothing);
    });
  });

  group('10. A typed address a role must not open goes to Today', () {
    for (final (role, path) in const [
      ('story', '/more/results'),
      ('story', '/more/references'),
      ('story', '/more/references/competitors'),
      ('story', '/more/settings/moments'),
      ('creator', '/more/settings/moments'),
      ('creator', '/more/paid'),
    ]) {
      testWidgets('$role cannot open $path', (tester) async {
        usePhone(tester, height: 1600);
        final c = await pumpStudio(tester, role: role);
        await goTo(tester, c, path);
        expect(currentLocation(c), '/today');
        expect(find.text('That page is not part of your role.'), findsOneWidget);
      });
    }

    testWidgets('the lead opens Moments, the founder opens Settings', (
      tester,
    ) async {
      usePhone(tester, height: 1600);
      final lead = await pumpStudio(tester, role: 'lead');
      await goTo(tester, lead, '/more/settings/moments');
      expect(currentLocation(lead), '/more/settings/moments');
    });
  });

  group('1. The lead reaches Moments through Settings, as the founder does', () {
    testWidgets("Settings is in the lead's More; no app-only Moments entry", (
      tester,
    ) async {
      usePhone(tester, height: 1600);
      final c = await pumpStudio(tester, role: 'lead');
      await goTo(tester, c, '/more');
      expect(find.byKey(const ValueKey('more-settings')), findsOneWidget);
      expect(find.byKey(const ValueKey('more-moments')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('more-settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-moments')));
      await tester.pumpAndSettle();
      expect(currentLocation(c), '/more/settings/moments');
      expect(find.text('You and the founder can change them.'), findsOneWidget);
      expect(find.byKey(const ValueKey('moment-add')), findsOneWidget);
    });

    testWidgets('the creator has no Settings entry', (tester) async {
      usePhone(tester, height: 1600);
      final c = await pumpStudio(tester, role: 'creator');
      await goTo(tester, c, '/more');
      expect(find.byKey(const ValueKey('more-settings')), findsNothing);
    });

    testWidgets('Moments in Arabic is المواعيد; Edit names the moment', (
      tester,
    ) async {
      usePhone(tester, height: 2000);
      final c = await pumpStudio(tester, locale: 'ar');
      await goTo(tester, c, '/more/settings/moments');
      expect(find.text('المواعيد'), findsWidgets);
      expect(find.text('اللحظات'), findsNothing);
    });
  });

  group('2. After Approve the page follows the result', () {
    testWidgets('no "In review", no Approve; Undo is offered', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/inbox/approve/PC-00188-v1');
      expect(find.text('In review'), findsWidgets);
      expect(find.byKey(const ValueKey('action-approve')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('action-approve')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('approve-confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('action-approve')), findsNothing);
      expect(find.byKey(const ValueKey('action-fix')), findsNothing);
      expect(find.byKey(const ValueKey('action-clear')), findsOneWidget);
      expect(find.text('Scheduled'), findsWidgets);
      expect(find.text('In review'), findsNothing);
      // Undo puts it back to waiting.
      await tester.tap(find.byKey(const ValueKey('action-clear')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('action-approve')), findsOneWidget);
      expect(find.text('In review'), findsWidgets);
    });
  });

  group('3. Won\'t post reads the same truth as What changed', () {
    testWidgets('the list holds the post, Put back is reachable', (
      tester,
    ) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/calendar');
      await tester.tap(find.byKey(const ValueKey('calendar-skipped')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('skipped-empty')), findsNothing);
      expect(
        find.byKey(const ValueKey('skipped-SP-2026-00230')),
        findsOneWidget,
      );
      // The window is written as dates in words, not 2026-11-21.
      expect(find.textContaining('Sat 21 Nov'), findsWidgets);
      expect(find.textContaining('2026-11-21'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('put-back-SP-2026-00230')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('skipped-empty')), findsOneWidget);
    });

    testWidgets('a post marked won\'t post lands in the list', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/calendar/post/SP-2026-00221');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('wont-post')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('wont-post')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('ask-text')),
        'Not this week',
      );
      await tester.tap(find.byKey(const ValueKey('ask-confirm')));
      await tester.pumpAndSettle();
      await goTo(tester, c, '/calendar');
      await tester.tap(find.byKey(const ValueKey('calendar-skipped')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('skipped-SP-2026-00221')),
        findsOneWidget,
      );
    });
  });

  group('4. A removed competitor shows Removed and can be restored', () {
    testWidgets('remove, then Restore on the page and in the Removed list', (
      tester,
    ) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/more/references/competitors/1980-coffee');
      await tester.tap(find.byKey(const ValueKey('competitor-remove')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('form-reason')), 'Closed');
      await tester.tap(find.byKey(const ValueKey('form-save')));
      await tester.pumpAndSettle();
      expect(find.text('Removed'), findsWidgets);
      expect(find.byKey(const ValueKey('competitor-restore')), findsOneWidget);
      expect(find.byKey(const ValueKey('competitor-remove')), findsNothing);
      // The Active list no longer holds it; the Removed list does.
      await goTo(tester, c, '/more/references/competitors');
      expect(find.byKey(const ValueKey('competitor-1980-coffee')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('competitor-status-Removed')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('competitor-restore-1980-coffee')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('competitor-restore-1980-coffee')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('competitor-status-Active')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('competitor-1980-coffee')), findsOneWidget);
    });
  });

  group('5. Moments show on the calendar', () {
    testWidgets('the week shows the moment chip on its day', (tester) async {
      usePhone(tester, height: 2400);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/calendar');
      await tester.tap(find.byKey(const ValueKey('calendar-next')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('moment-chip-MOM-00031')), findsOneWidget);
    });

    testWidgets('the month marks the day with a star', (tester) async {
      usePhone(tester, height: 2400);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/calendar');
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('month-moment-2026-11-28')),
        findsOneWidget,
      );
    });
  });

  group('6. Dates go through the one formatter', () {
    testWidgets('the day banner on Today reads Tue 24 Nov', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/today');
      await tester.tap(find.byKey(const ValueKey('day-prev')));
      await tester.pumpAndSettle();
      expect(find.textContaining('2026-11-'), findsNothing);
    });
  });

  group('7. Make an idea from a reference', () {
    testWidgets('the sheet names the reference and the founder reads Idea added', (
      tester,
    ) async {
      usePhone(tester, height: 2000);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/more/references/ad-1114412864248331');
      await tester.tap(find.byKey(const ValueKey('ref-make-idea')));
      await tester.pumpAndSettle();
      expect(find.text('From: Crumbl'), findsOneWidget);
      final title = tester.widget<TextField>(find.byKey(const ValueKey('idea-title')));
      expect(title.controller!.text, 'Crumbl: new menu every week');
      await tester.tap(find.byKey(const ValueKey('idea-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Idea added. It waits in your Ideas.'), findsOneWidget);
      expect(find.textContaining('The founder will see'), findsNothing);
    });

    testWidgets('the lead is told the founder will see it', (tester) async {
      usePhone(tester, height: 2000);
      final c = await pumpStudio(tester, role: 'lead');
      await goTo(tester, c, '/more/references/ad-1114412864248331');
      await tester.tap(find.byKey(const ValueKey('ref-make-idea')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('idea-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Idea sent. The founder will see it.'), findsOneWidget);
    });
  });

  group('10b. A creator sees only the actions the server lists', () {
    testWidgets('no Drop for a creator; the founder has it', (tester) async {
      usePhone(tester, height: 2000);
      final cr = await pumpStudio(tester, role: 'creator');
      await goTo(tester, cr, '/more/references/ad-1114412864248331');
      expect(find.byKey(const ValueKey('ref-drop')), findsNothing);
      expect(find.byKey(const ValueKey('ref-shortlist')), findsOneWidget);
    });
  });

  group('13. One name for the same action', () {
    testWidgets('the static post says Mark posted', (tester) async {
      usePhone(tester, height: 2000);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/calendar/post/SP-2026-00221');
      expect(find.text('Mark posted'), findsWidgets);
      expect(find.text('I posted it'), findsNothing);
    });
  });

  group('14. Skipped in round 4', () {
    testWidgets('tapping the active tab goes back to its root', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/calendar/post/SP-2026-00221');
      expect(currentLocation(c), '/calendar/post/SP-2026-00221');
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Calendar'),
        ),
      );
      await tester.pumpAndSettle();
      expect(currentLocation(c), '/calendar');
    });

    testWidgets('a "Results to add" line opens the read form', (tester) async {
      usePhone(tester, height: 1600);
      final c = await pumpStudio(tester);
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
      expect(find.textContaining('72-hour read'), findsWidgets);
      expect(currentLocation(c), '/today');
    });
  });
}
