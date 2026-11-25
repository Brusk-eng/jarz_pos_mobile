import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';

import 'helpers.dart';
import 'inbox/ui_test_helpers.dart';

/// Round 6: what the fifth day-one walk found.
void main() {
  group('1. Approve follows the versions.approve result on every screen', () {
    for (final path in const [
      '/inbox/approve/PC-00188-v1',
      '/versions/PC-00188-v1',
    ]) {
      testWidgets('the version page at $path', (tester) async {
        usePhone(tester, height: 1800);
        final c = await pumpStudio(tester);
        await goTo(tester, c, path);
        expect(find.byKey(const ValueKey('action-approve')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('action-approve')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('approve-confirm')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('action-approve')), findsNothing);
        expect(find.byKey(const ValueKey('action-fix')), findsNothing);
        expect(find.byKey(const ValueKey('action-clear')), findsOneWidget);
        expect(find.text('In review'), findsNothing);
      });
    }

    testWidgets('the same with the real 150 ms server delay', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudioWith(
        tester,
        fakeApi(delay: const Duration(milliseconds: 150)),
      );
      await goTo(tester, c, '/inbox/approve/PC-00188-v1');
      await tester.tap(find.byKey(const ValueKey('action-approve')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('approve-confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('action-approve')), findsNothing);
      expect(find.text('In review'), findsNothing);
    });

    testWidgets('the card in the Inbox opens the version, then Approve works', (
      tester,
    ) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/inbox');
      final card = find.byKey(const ValueKey('approve-PC-00188-v1'));
      await reveal(tester, card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('action-approve')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('approve-confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('action-approve')), findsNothing);
      expect(find.byKey(const ValueKey('action-clear')), findsOneWidget);
    });

    testWidgets('Today approves in place, then the version page agrees', (
      tester,
    ) async {
      usePhone(tester, height: 3000);
      final c = await pumpStudioWith(tester, fakeApi());
      final line = find.byKey(const ValueKey('line-PC-00163-v2-approve'));
      expect(line, findsOneWidget);
      await tester.tap(line);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('line-PC-00163-v2-approve')),
          findsNothing);
      await goTo(tester, c, '/versions/PC-00163-v2');
      expect(find.byKey(const ValueKey('action-approve')), findsNothing);
    });
  });

  group('2. Team ratings has an entry at the top of Results', () {
    testWidgets('the button opens the ratings', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/more/results');
      expect(find.byKey(const ValueKey('top-ratings')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('top-ratings')));
      await tester.pumpAndSettle();
      expect(currentLocation(c), '/more/results/ratings');
    });
  });

  group('3. Owner and due on the piece card', () {
    testWidgets('a piece with no date says so', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester, role: 'lead');
      await goTo(tester, c, '/pieces');
      expect(find.textContaining('No due date'), findsWidgets);
    });
  });

  group('4. The lead and the founder can add a task from Today', () {
    for (final role in const ['founder', 'lead']) {
      testWidgets('$role sees Add a task', (tester) async {
        usePhone(tester, height: 1800);
        await pumpStudio(tester, role: role);
        expect(find.byKey(const ValueKey('task-add-top')), findsOneWidget);
        expect(find.text('Add a task'), findsWidgets);
      });
    }
  });

  group('5. The Removed tab has its own empty text', () {
    testWidgets('No removed competitors.', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/more/references/competitors');
      await tester.tap(find.byKey(const ValueKey('competitor-status-Removed')));
      await tester.pumpAndSettle();
      expect(find.text('No removed competitors.'), findsOneWidget);
    });

    testWidgets('in Arabic', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester, locale: 'ar');
      await goTo(tester, c, '/more/references/competitors');
      await tester.tap(find.byKey(const ValueKey('competitor-status-Removed')));
      await tester.pumpAndSettle();
      expect(find.text('مفيش منافسين اتشالوا.'), findsOneWidget);
    });
  });

  group('6. Won\'t post draws its list from the window it names', () {
    testWidgets('a post outside the window is not in the list', (tester) async {
      usePhone(tester, height: 1400);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final api = fakeApi(
        edits: {
          'calendar.range': (j) {
            final first = (j['posts'] as List).first as Map;
            j['posts'] = [
              {
                ...first,
                'id': 'SP-IN',
                'title': 'Inside the window',
                'status': 'Cancelled',
                'slot_time': '${today}T20:00:00+02:00',
              },
              {
                ...first,
                'id': 'SP-OUT',
                'title': 'Far outside the window',
                'status': 'Cancelled',
                'slot_time': '2026-01-05T20:00:00+02:00',
              },
            ];
          },
        },
      );
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/calendar');
      await tester.tap(find.byKey(const ValueKey('calendar-skipped')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('skipped-SP-IN')), findsOneWidget);
      expect(find.byKey(const ValueKey('skipped-SP-OUT')), findsNothing);
    });
  });

  group('7. Date pickers say OK and Cancel in both languages', () {
    for (final (locale, ok, cancel) in const [
      ('en', 'OK', 'Cancel'),
      ('ar', 'تمام', 'إلغاء'),
    ]) {
      testWidgets('the moment date picker in $locale', (tester) async {
        usePhone(tester, height: 1800);
        final c = await pumpStudio(tester, locale: locale);
        await goTo(tester, c, '/more/settings/moments');
        await tester.tap(find.byKey(const ValueKey('moment-add')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('moment-date')));
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(DatePickerDialog),
            matching: find.text(ok),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(DatePickerDialog),
            matching: find.text(cancel),
          ),
          findsOneWidget,
        );
      });
    }
  });

  group('8. A chip that acts is a button, a real toggle stays a toggle', () {
    testWidgets('the status chip on the calendar', (tester) async {
      usePhone(tester, height: 1400);
      final handle = tester.ensureSemantics();
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/calendar');
      final node = tester.getSemantics(
        find.byKey(const ValueKey('status-all')),
      );
      expect(
        // ignore: deprecated_member_use
        node.getSemanticsData().hasFlag(SemanticsFlag.isButton),
        isTrue,
      );
      handle.dispose();
    });
  });

  group('9. An unknown address', () {
    testWidgets('shows Page not found and a way back', (tester) async {
      usePhone(tester, height: 1400);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/no/such/page');
      expect(find.text('Page not found'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('not-found-today')));
      await tester.pumpAndSettle();
      expect(currentLocation(c), '/today');
    });

    testWidgets('in Arabic', (tester) async {
      usePhone(tester, height: 1400);
      final c = await pumpStudio(tester, locale: 'ar');
      await goTo(tester, c, '/no/such/page');
      expect(find.text('الصفحة مش موجودة'), findsOneWidget);
      expect(find.text('ارجع للنهارده'), findsOneWidget);
    });
  });

  group('10. The Story Lead cannot open a shoot by address', () {
    for (final path in const [
      '/shoots',
      '/shoots/SHOOT-1',
      '/shoots/SHOOT-1/on-set',
    ]) {
      testWidgets('story cannot open $path', (tester) async {
        usePhone(tester, height: 1600);
        final c = await pumpStudio(tester, role: 'story');
        await goTo(tester, c, path);
        expect(currentLocation(c), '/today');
      });
    }

    testWidgets('the creator still opens the shoots list', (tester) async {
      usePhone(tester, height: 1600);
      final c = await pumpStudio(tester, role: 'creator');
      await goTo(tester, c, '/shoots');
      expect(currentLocation(c), '/shoots');
    });
  });

  group('11. Required inputs are marked before submit', () {
    testWidgets('the moment date says required', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/more/settings/moments');
      await tester.tap(find.byKey(const ValueKey('moment-add')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Date * (required)'), findsOneWidget);
    });

    testWidgets('in Arabic', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester, locale: 'ar');
      await goTo(tester, c, '/more/settings/moments');
      await tester.tap(find.byKey(const ValueKey('moment-add')));
      await tester.pumpAndSettle();
      expect(find.textContaining('(مطلوب)'), findsWidgets);
    });
  });

  group('12. The creator tour names Ideas and Results', () {
    testWidgets('step 3 in English', (tester) async {
      usePhone(tester, height: 1800);
      await pumpStudioWith(
        tester,
        FakeStudioApi(
          role: 'creator',
          delay: Duration.zero,
          firstLogin: true,
          serverLang: 'en',
        ),
      );
      final text = find.textContaining('Results: More > Results');
      for (var i = 0; i < 4 && text.evaluate().isEmpty; i++) {
        await tester.tap(find.byKey(const ValueKey('walkthrough-next')));
        await tester.pumpAndSettle();
      }
      expect(text, findsOneWidget);
    });
  });

  group('13. A story frame button carries the frame number', () {
    testWidgets('Mark frame 3 posted, Skip frame 3', (tester) async {
      usePhone(tester, height: 2400);
      final c = await pumpStudioWith(
        tester,
        FakeStudioApi(
          role: 'story',
          delay: Duration.zero,
          storyFrames: true,
          serverLang: 'en',
        ),
      );
      await goTo(tester, c, '/calendar/post/SP-2026-00310');
      await reveal(tester, find.text('Frame 3 posted'));
      expect(find.text('Frame 3 posted'), findsOneWidget);
      expect(find.text('Skip frame 3'), findsOneWidget);
    });
  });
}
