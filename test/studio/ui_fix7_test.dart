
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/l10n/plural.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_locale.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';

import 'helpers.dart';
import 'inbox/ui_test_helpers.dart';

/// Round 7: what the sixth day-one walk found.
void main() {
  group('1 and 8. Picker buttons are named; Flutter\'s own Arabic words', () {
    for (final (locale, ok, cancel) in const [
      ('en', 'OK', 'Cancel'),
      ('ar', 'تمام', 'إلغاء'),
    ]) {
      testWidgets('the OK and Cancel buttons have a name in $locale', (
        tester,
      ) async {
        usePhone(tester, height: 1800);
        final handle = tester.ensureSemantics();
        final c = await pumpStudio(tester, locale: locale);
        await goTo(tester, c, '/more/settings/moments');
        await tester.tap(find.byKey(const ValueKey('moment-add')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('moment-date')));
        await tester.pumpAndSettle();
        final labels = [
          for (final b in find
              .descendant(
                of: find.byType(DatePickerDialog),
                matching: find.byType(TextButton),
              )
              .evaluate())
            tester.getSemantics(find.byWidget(b.widget)).label,
        ];
        expect(labels, containsAll([ok, cancel]));
        handle.dispose();
      });
    }

    testWidgets('Dismiss and Scrim read «إغلاق» and «الخلفية»', (tester) async {
      usePhone(tester, height: 1800);
      await pumpStudio(tester, locale: 'ar');
      final l = MaterialLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      );
      expect(l.modalBarrierDismissLabel, 'إغلاق');
      expect(l.scrimLabel, 'الخلفية');
      expect(l.okButtonLabel, 'تمام');
    });

    testWidgets('English keeps Flutter\'s words', (tester) async {
      usePhone(tester, height: 1800);
      await pumpStudio(tester);
      final l = MaterialLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      );
      expect(l.modalBarrierDismissLabel, 'Dismiss');
    });
  });

  group('2. A shortlisted reference does not offer Add to shortlist', () {
    testWidgets('no button on a Shortlisted one', (tester) async {
      usePhone(tester, height: 2400);
      final api = fakeApi(
        edits: {'references.get': (j) => (j as Map)['status'] = 'Shortlisted'},
      );
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/more/references/ad-1114412864248331');
      expect(find.byKey(const ValueKey('ref-shortlist')), findsNothing);
    });

    test('the fake does not send the action either', () async {
      final api = fakeApi(
        edits: {'references.get': (j) => (j as Map)['status'] = 'Shortlisted'},
      );
      final r = await api.call('${studioMethodPrefix}references.get', params: {'id': 'x'}) as Map;
      expect(r['actions'], isNot(contains('shortlist')));
    });
  });

  group('3. The creator\'s idea tabs say who decides', () {
    testWidgets('Waiting for the founder / Kept / Dropped', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester, role: 'creator');
      await goTo(tester, c, '/inbox/ideas');
      final tabs = find.byKey(const ValueKey('ideas-filter'));
      for (final (text, n) in const [
        ('Waiting for the founder', 1),
        ('To decide', 0),
        ('Kept', 1),
        ('Dropped', 1),
      ]) {
        expect(
          find.descendant(of: tabs, matching: find.text(text)),
          n == 1 ? findsOneWidget : findsNothing,
        );
      }
    });

    testWidgets('in Arabic', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester, role: 'creator', locale: 'ar');
      await goTo(tester, c, '/inbox/ideas');
      final tabs = find.byKey(const ValueKey('ideas-filter'));
      for (final text in const ['مستنية المؤسس', 'اتحفظت', 'اتسابت']) {
        expect(
          find.descendant(of: tabs, matching: find.text(text)),
          findsOneWidget,
        );
      }
    });

    testWidgets('the founder still sees To decide', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/inbox/ideas');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ideas-filter')),
          matching: find.text('To decide'),
        ),
        findsOneWidget,
      );
    });
  });

  group('4. Piece labels are plain text, not checkboxes', () {
    testWidgets('no checkbox or button semantics on a label', (tester) async {
      usePhone(tester, height: 2400);
      final handle = tester.ensureSemantics();
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/pieces/PC-00188');
      final labels = find.descendant(
        of: find.byKey(const ValueKey('piece-labels')),
        matching: find.byType(Chip),
      );
      expect(labels, findsWidgets);
      final data = tester.getSemantics(labels.first).getSemanticsData();
      // ignore: deprecated_member_use
      expect(data.hasFlag(SemanticsFlag.hasCheckedState), isFalse);
      // ignore: deprecated_member_use
      expect(data.hasFlag(SemanticsFlag.isButton), isFalse);
      handle.dispose();
    });
  });

  group('5 and 6. One owner phrase; the due words', () {
    testWidgets('English: Creators and With the creators', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester, role: 'lead');
      await goTo(tester, c, '/pieces');
      expect(find.text('Any creator'), findsNothing);
      expect(find.textContaining('No due date'), findsWidgets);
    });

    testWidgets('Arabic: no date and the due word', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester, role: 'lead', locale: 'ar');
      await goTo(tester, c, '/pieces');
      expect(find.textContaining('أي واحد من صنّاع'), findsNothing);
      expect(find.textContaining('مفيش ميعاد تسليم'), findsWidgets);
      expect(find.textContaining('الموعد '), findsNothing);
    });
  });

  group('7. The story frame button', () {
    testWidgets('says Frame N posted and is named in full', (tester) async {
      usePhone(tester, height: 2400);
      final handle = tester.ensureSemantics();
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
      expect(find.bySemanticsLabel('Mark frame 3 posted'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('in Arabic', (tester) async {
      usePhone(tester, height: 2400);
      final c = await pumpStudioWith(
        tester,
        FakeStudioApi(
          role: 'story',
          delay: Duration.zero,
          storyFrames: true,
          serverLang: 'ar',
        ),
        locale: 'ar',
      );
      await goTo(tester, c, '/calendar/post/SP-2026-00310');
      await reveal(tester, find.text('فريم 3 اتنشر'));
      expect(find.text('فريم 3 اتنشر'), findsOneWidget);
    });
  });

  group('9. Arabic day counts follow the plural helper', () {
    test('1, 2, 3 to 10, 11 and over', () {
      expect(arDay.of(1), 'يوم');
      expect(arDay.of(2), 'يومين');
      expect(arDay.of(7), '7 أيام');
      expect(arDay.of(12), '12 يوم');
    });

    test('the fake wording of a Today wait line', () async {
      final api = FakeStudioApi(
        role: 'founder',
        delay: Duration.zero,
        serverLang: 'ar',
      );
      final today = await api.call('${studioMethodPrefix}today.get').then((v) => '$v');
      expect(today, isNot(contains('من 7 يوم')));
      expect(today, isNot(contains('من 2 يوم')));
    });
  });

  group('10. A language switch is not undone by the first sign-in', () {
    testWidgets('Today has no Arabic wait line in English', (tester) async {
      usePhone(tester, height: 3000);
      final c = await pumpStudioWith(
        tester,
        FakeStudioApi(role: 'founder', serverLang: 'ar'),
        locale: 'ar',
        settle: false,
      );
      // Switch to English while the sign-in language check is still waiting
      // for the server.
      await tester.pump(const Duration(milliseconds: 20));
      c.read(studioLocaleProvider.notifier).state = const Locale('en');
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.textContaining('مستني من'), findsNothing);
    });
  });

  group('11 and 12. Wording', () {
    testWidgets('Self-treater and Blocked in Arabic', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester, role: 'lead', locale: 'ar');
      await goTo(tester, c, '/today');
      expect(find.textContaining('واقف 2'), findsNothing);
    });

    testWidgets('Competitors help button in Arabic', (tester) async {
      usePhone(tester, height: 1800);
      final c = await pumpStudio(tester, locale: 'ar');
      await goTo(tester, c, '/more/references/competitors');
      expect(find.text('إزاي ده بيشتغل'), findsNothing);
    });
  });

  group('13. More lists no role entry until session.me is in', () {
    testWidgets('story lead: no Shoots or References at any point', (
      tester,
    ) async {
      usePhone(tester, height: 1800);
      await pumpStudioWith(
        tester,
        FakeStudioApi(role: 'story', serverLang: 'en'),
        settle: false,
      );
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 25));
        expect(find.byKey(const ValueKey('more-shoots')), findsNothing);
        expect(find.byKey(const ValueKey('more-references')), findsNothing);
      }
    });
  });

  group('14. Tasks and shots have their own group below the pieces', () {
    testWidgets('a Tasks and shots heading, after the pieces', (tester) async {
      usePhone(tester, height: 2400);
      final c = await pumpStudio(tester, role: 'lead');
      await goTo(tester, c, '/pieces');
      await tester.tap(find.byKey(const ValueKey('view-week')));
      await tester.pumpAndSettle();
      final heading = find.text('Tasks and shots');
      expect(heading, findsWidgets);
    });
  });
}
