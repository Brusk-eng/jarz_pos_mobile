import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';
import 'package:jarz_pos/src/studio/data/models/studio_enums.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';
import 'package:jarz_pos/src/studio/features/inbox/presentation/approvals_strings.dart';
import 'package:jarz_pos/src/studio/shared/person_text.dart';
import 'package:jarz_pos/src/studio/features/inbox/state/approvals_logic.dart';
import 'dart:convert';

import '../helpers.dart';
import 'ui_test_helpers.dart';

/// The fixture cards: PC-00163 static (Tue 1 Dec 13:00, by hand, ran as a
/// trial), PC-00188 reel (Fri 27 Nov 20:00, by itself, needs the hard yes),
/// PC-00147 carousel (Sat 28 Nov 13:00, by hand, failed gate checks).
final _fri9 = DateTime(2026, 11, 27, 9);

ApproveCard _card(String versionId) {
  final page = ApproveCardPage.fromJson(
    jsonDecode(studioFixtures['inbox.to_approve']!) as Map<String, dynamic>,
  );
  return page.items.firstWhere((c) => c.version.id == versionId);
}

ApproveCard _at(ApproveCard c, String? slot) =>
    c.copyWith(posts: [for (final p in c.posts) p.copyWith(slotTime: slot)]);

Finder _card_(String id) => find.byKey(ValueKey('approve-$id'));
Finder _in(String id, String key) =>
    find.descendant(of: _card_(id), matching: find.byKey(ValueKey(key)));
String _text(WidgetTester t, Finder f) {
  final w = t.widget(f);
  return w is PersonText ? w.text : (w as Text).data!;
}

void main() {
  group('grouping and time words', () {
    final all = [
      _card('PC-00163-v2'),
      _card('PC-00188-v1'),
      _card('PC-00147-v1'),
    ];

    test('ordered by the time they go out, grouped by day', () {
      final groups = groupApprovals(all, _fri9);
      expect(groups.map((g) => g.kind), [
        ApprovalDay.today,
        ApprovalDay.tomorrow,
        ApprovalDay.later,
      ]);
      expect(groups.map((g) => g.cards.single.version.id), [
        'PC-00188-v1',
        'PC-00147-v1',
        'PC-00163-v2',
      ]);
      expect(groups.last.date, DateTime(2026, 12, 1));
    });

    test('a slot that has passed is overdue and sorts first', () {
      final groups = groupApprovals(all, DateTime(2026, 11, 27, 21));
      expect(groups.first.kind, ApprovalDay.overdue);
      expect(groups.first.cards.single.version.id, 'PC-00188-v1');
      expect(groups.map((g) => g.kind), [
        ApprovalDay.overdue,
        ApprovalDay.tomorrow,
        ApprovalDay.later,
      ]);
    });

    test('a card with no time comes last; same day shares a group', () {
      final noTime = _at(_card('PC-00147-v1'), null);
      final sameDay = _at(_card('PC-00163-v2'), '2026-11-27T22:30:00+02:00');
      final groups = groupApprovals([noTime, sameDay, all[1]], _fri9);
      expect(groups.map((g) => g.kind), [
        ApprovalDay.today,
        ApprovalDay.noTime,
      ]);
      expect(groups.first.cards.map((c) => c.version.id), [
        'PC-00188-v1',
        'PC-00163-v2',
      ]);
    });

    test('12-hour time with the day, English and Arabic', () {
      const en = ApprovalsStrings(false), ar = ApprovalsStrings(true);
      expect(en.when(DateTime(2026, 12, 1, 20)), 'Tue 1 Dec · 8:00 pm');
      expect(en.when(DateTime(2026, 12, 1, 0, 5)), 'Tue 1 Dec · 12:05 am');
      expect(en.when(DateTime(2026, 12, 1, 12, 30)), 'Tue 1 Dec · 12:30 pm');
      expect(ar.when(DateTime(2026, 12, 1, 20)), 'التلات 1 ديسمبر · 8:00 م');
    });

    test('countdown in days and hours, hours and minutes, minutes', () {
      const en = ApprovalsStrings(false), ar = ApprovalsStrings(true);
      final now = DateTime(2026, 11, 29, 9);
      String c(DateTime slot, [ApprovalsStrings s = en]) =>
          s.countdown(spanTo(slot, now));
      expect(c(DateTime(2026, 12, 1, 13)), 'in 2 days 4 h');
      expect(c(DateTime(2026, 11, 29, 12, 20)), 'in 3 h 20 min');
      expect(c(DateTime(2026, 11, 29, 9, 12)), 'in 12 min');
      expect(c(DateTime(2026, 11, 29, 6)), '3 h ago');
      expect(c(DateTime(2026, 12, 1, 13), ar), 'بعد يومين و4 ساعات');
      expect(c(DateTime(2026, 11, 29, 6), ar), 'من 3 ساعات');
    });

    test(
      'undo is possible only while the slot is more than 15 minutes away',
      () {
        final c = _card('PC-00188-v1'); // Fri 27 Nov 20:00
        expect(canUndoApproval(c, DateTime(2026, 11, 27, 19, 30)), isTrue);
        expect(canUndoApproval(c, DateTime(2026, 11, 27, 19, 45)), isFalse);
        expect(canUndoApproval(c, DateTime(2026, 11, 27, 19, 50)), isFalse);
        expect(canUndoApproval(c, DateTime(2026, 11, 27, 20, 10)), isFalse);
      },
    );

    test('channel words and who posts', () {
      expect(
        channelWords(PostChannel.feedReel, PieceFormat.reel, ar: false),
        'Instagram feed reel',
      );
      expect(
        channelWords(PostChannel.story, PieceFormat.story, ar: false),
        'Instagram story',
      );
      expect(
        channelWords(PostChannel.tikTok, PieceFormat.reel, ar: false),
        'TikTok',
      );
      expect(
        channelWords(
          PostChannel.feedStatic,
          PieceFormat.staticValue,
          ar: false,
        ),
        'Instagram static',
      );
      expect(
        channelWords(null, PieceFormat.carousel, ar: false),
        'Instagram carousel',
      );
      expect(whoPosts(primaryPost(_card('PC-00188-v1'))).byHand, isFalse);
      final hand = whoPosts(primaryPost(_card('PC-00163-v2')));
      expect((hand.byHand, hand.name), (true, 'Abdelrahman'));
    });
  });

  group('the approvals screen', () {
    testWidgets('groups by day with the day words and one card each', (
      tester,
    ) async {
      usePhone(tester, height: 3000);
      final c = await pumpStudioWith(tester, fakeApi(), now: _fri9);
      await goTo(tester, c, '/inbox/approve');
      expect(find.byKey(const ValueKey('group-today')), findsOneWidget);
      expect(find.byKey(const ValueKey('group-tomorrow')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('group-later-2026-12-01')),
        findsOneWidget,
      );
      expect(_text(tester, find.byKey(const ValueKey('group-today'))), 'Today');
      expect(
        _text(tester, find.byKey(const ValueKey('group-tomorrow'))),
        'Tomorrow',
      );
      expect(
        _text(tester, find.byKey(const ValueKey('group-later-2026-12-01'))),
        'Tue 1 Dec',
      );
      expect(find.byKey(const ValueKey('group-overdue')), findsNothing);
      // The time order is the order on the page.
      final y = {
        for (final id in ['PC-00188-v1', 'PC-00147-v1', 'PC-00163-v2'])
          id: tester.getTopLeft(_card_(id)).dy,
      };
      expect(y['PC-00188-v1']!, lessThan(y['PC-00147-v1']!));
      expect(y['PC-00147-v1']!, lessThan(y['PC-00163-v2']!));
    });

    testWidgets('a slot that has passed lands in a red Overdue group on top', (
      tester,
    ) async {
      usePhone(tester, height: 3000);
      final c = await pumpStudioWith(
        tester,
        fakeApi(),
        now: DateTime(2026, 11, 27, 21),
      );
      await goTo(tester, c, '/inbox/approve');
      final head = find.byKey(const ValueKey('group-overdue'));
      expect(head, findsOneWidget);
      expect(_text(tester, head), 'Overdue — slot passed');
      expect(tester.widget<Text>(head).style?.color, const Color(0xFFC0392B));
      expect(
        tester.getTopLeft(head).dy,
        lessThan(tester.getTopLeft(_card_('PC-00188-v1')).dy),
      );
      expect(_text(tester, _in('PC-00188-v1', 'card-countdown')), '1 h ago');
    });

    testWidgets('a card shows everything without opening anything', (
      tester,
    ) async {
      usePhone(tester, height: 3000);
      final c = await pumpStudioWith(tester, fakeApi(), now: _fri9);
      await goTo(tester, c, '/inbox/approve');
      const id = 'PC-00188-v1';
      expect(_in(id, 'card-thumb'), findsOneWidget);
      expect(
        _text(tester, _in(id, 'card-title')),
        'Pick one: Mango or Pistachio',
      );
      expect(_text(tester, _in(id, 'card-id')), 'PC-00188');
      expect(_text(tester, _in(id, 'card-channel')), 'Instagram feed reel');
      expect(_text(tester, _in(id, 'card-when')), 'Fri 27 Nov · 8:00 pm');
      expect(_text(tester, _in(id, 'card-countdown')), 'in 11 h');
      expect(
        _text(tester, _in(id, 'card-who')),
        'Posts by itself at that time',
      );
      expect(_text(tester, _in(id, 'card-caption')), contains('#JarzEgypt'));
      expect(_in(id, 'card-verdict'), findsOneWidget);
      expect(
        _text(tester, _in(id, 'card-verdict-reason')),
        'Opens on the spoon and says the flavour once; the order is easy to picture.',
      );
      expect(
        find.descendant(of: _card_(id), matching: find.text('RUN')),
        findsOneWidget,
      );
      expect(_in(id, 'card-approve'), findsOneWidget);
      expect(_in(id, 'card-send-back'), findsOneWidget);
      expect(_in(id, 'card-change-time'), findsOneWidget);
    });

    testWidgets(
      'by-hand posts name the person; badges show on the right cards',
      (tester) async {
        usePhone(tester, height: 3000);
        final c = await pumpStudioWith(tester, fakeApi(), now: _fri9);
        await goTo(tester, c, '/inbox/approve');
        expect(
          _text(tester, _in('PC-00163-v2', 'card-who')),
          'Posted by hand by Abdelrahman',
        );
        expect(
          _text(tester, _in('PC-00163-v2', 'card-channel')),
          'Instagram static',
        );
        expect(
          _text(tester, _in('PC-00147-v1', 'card-channel')),
          'Instagram carousel',
        );
        expect(_in('PC-00188-v1', 'badge-hard-yes'), findsOneWidget);
        expect(
          find.descendant(
            of: _in('PC-00188-v1', 'badge-hard-yes'),
            matching: find.text('Needs your hard yes (price/box post)'),
          ),
          findsOneWidget,
        );
        expect(_in('PC-00188-v1', 'badge-trial'), findsNothing);
        expect(_in('PC-00163-v2', 'badge-trial'), findsOneWidget);
        expect(
          find.descendant(
            of: _card_('PC-00163-v2'),
            matching: find.text('Already ran as a trial reel'),
          ),
          findsOneWidget,
        );
        expect(_in('PC-00163-v2', 'badge-hard-yes'), findsNothing);
        expect(_in('PC-00147-v1', 'badge-hard-yes'), findsNothing);
      },
    );

    testWidgets('failed gate checks are listed on the card', (tester) async {
      usePhone(tester, height: 3000);
      final c = await pumpStudioWith(tester, fakeApi(), now: _fri9);
      await goTo(tester, c, '/inbox/approve');
      final box = _in('PC-00147-v1', 'card-failed-checks');
      expect(box, findsOneWidget);
      expect(
        find.descendant(
          of: box,
          matching: find.textContaining('The creative reader read the file'),
        ),
        findsOneWidget,
      );
      expect(_in('PC-00188-v1', 'card-failed-checks'), findsNothing);
    });

    testWidgets('a long caption folds and opens in full', (tester) async {
      usePhone(tester, height: 3000);
      final long =
          '${List.filled(30, 'Spoon after spoon.').join(' ')}\n#JarzEgypt';
      final c = await pumpStudioWith(
        tester,
        fakeApi(
          edits: {
            'inbox.to_approve': (j) {
              for (final it in j['items'] as List) {
                if (it['version']['id'] == 'PC-00188-v1') it['caption'] = long;
              }
            },
          },
        ),
        now: _fri9,
      );
      await goTo(tester, c, '/inbox/approve');
      final cap = _in('PC-00188-v1', 'card-caption');
      expect(tester.widget<PersonText>(cap).maxLines, 4);
      await tester.ensureVisible(_in('PC-00188-v1', 'card-caption-toggle'));
      await tester.tap(_in('PC-00188-v1', 'card-caption-toggle'));
      await tester.pumpAndSettle();
      expect(tester.widget<PersonText>(cap).maxLines, isNull);
      expect(_text(tester, cap), long);
    });

    testWidgets('approve: the card says in words what will happen', (
      tester,
    ) async {
      usePhone(tester, height: 3000);
      final api = fakeApi();
      final c = await pumpStudioWith(tester, api, now: _fri9);
      await goTo(tester, c, '/inbox/approve');
      await tester.ensureVisible(_in('PC-00188-v1', 'card-approve'));
      await tester.tap(_in('PC-00188-v1', 'card-approve'));
      await tester.pumpAndSettle();
      expect(api.calls, contains('versions.approve'));
      final note = _in('PC-00188-v1', 'card-approved-note');
      expect(
        find.descendant(
          of: note,
          matching: find.text(
            'Approved. Posts by itself Fri 27 Nov · 8:00 pm on Instagram',
          ),
        ),
        findsOneWidget,
      );
      // It stays on the page, now with Undo instead of Approve.
      expect(_in('PC-00188-v1', 'card-approve'), findsNothing);
      expect(_in('PC-00188-v1', 'card-undo'), findsOneWidget);

      // A by-hand post names who posts it.
      await tester.ensureVisible(_in('PC-00147-v1', 'card-approve'));
      await tester.tap(_in('PC-00147-v1', 'card-approve'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: _in('PC-00147-v1', 'card-approved-note'),
          matching: find.text(
            'Approved. Abdelrahman posts it by hand Sat 28 Nov · 1:00 pm on Instagram',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('send back asks for a note, then the card leaves', (
      tester,
    ) async {
      usePhone(tester, height: 3000);
      final api = fakeApi();
      final c = await pumpStudioWith(tester, api, now: _fri9);
      await goTo(tester, c, '/inbox/approve');
      await tester.ensureVisible(_in('PC-00147-v1', 'card-send-back'));
      await tester.tap(_in('PC-00147-v1', 'card-send-back'));
      await tester.pumpAndSettle();
      // No note, no send.
      await tester.tap(find.byKey(const ValueKey('send-back-confirm')));
      await tester.pumpAndSettle();
      expect(api.calls, isNot(contains('versions.fix')));
      await tester.enterText(
        find.byKey(const ValueKey('send-back-reason')),
        'Fix the closing line.',
      );
      await tester.tap(find.byKey(const ValueKey('send-back-confirm')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('versions.fix'));
      expect(
        api.callLog.lastWhere((e) => e.key == 'versions.fix').params['reason'],
        'Fix the closing line.',
      );
      expect(_card_('PC-00147-v1'), findsNothing);
    });

    testWidgets('change time picks a date and a time and saves the slot', (
      tester,
    ) async {
      usePhone(tester, height: 3000);
      final api = fakeApi();
      final c = await pumpStudioWith(tester, api, now: _fri9);
      await goTo(tester, c, '/inbox/approve');
      await tester.ensureVisible(_in('PC-00188-v1', 'card-change-time'));
      await tester.tap(_in('PC-00188-v1', 'card-change-time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK')); // the day, kept
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK')); // the time, kept
      await tester.pumpAndSettle();
      final call = api.callLog.lastWhere((e) => e.key == 'calendar.post_move');
      expect(call.params['post_id'], 'SP-2026-00224');
      expect(call.params['slot_time'], '2026-11-27T20:00:00+02:00');
    });

    testWidgets('empty: Nothing waiting for you.', (tester) async {
      usePhone(tester, height: 900);
      final c = await pumpStudioWith(
        tester,
        fakeApi(edits: {'inbox.to_approve': (j) => j['items'] = []}),
      );
      await goTo(tester, c, '/inbox/approve');
      expect(find.text('Nothing waiting for you.'), findsOneWidget);
    });

    testWidgets('the details link opens the version screen', (tester) async {
      usePhone(tester, height: 3000);
      final c = await pumpStudioWith(tester, fakeApi(), now: _fri9);
      await goTo(tester, c, '/inbox/approve');
      final link = find.byKey(const ValueKey('approve-details-PC-00188-v1'));
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(topLocation(c), '/inbox/approve/PC-00188-v1');
    });
  });

  group('the approved tab', () {
    Future<ProviderContainer> open(
      WidgetTester tester,
      FakeStudioApi api, {
      DateTime? now,
      String locale = 'en',
    }) async {
      usePhone(tester, height: 3000);
      final c = await pumpStudioWith(
        tester,
        api,
        now: now ?? _fri9,
        locale: locale,
      );
      await goTo(tester, c, '/inbox/approve');
      await tester.tap(find.byKey(const ValueKey('approvals-tab-approved')));
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('lists what is approved with the same card and Undo', (
      tester,
    ) async {
      final api = fakeApi();
      await open(tester, api);
      expect(api.callLog.last.params['scope'], 'approved');
      expect(find.byKey(const ValueKey('approved-list')), findsOneWidget);
      const id = 'PC-00170-v1';
      expect(_text(tester, _in(id, 'card-title')), 'Strawberry spoon, slow');
      expect(_text(tester, _in(id, 'card-when')), 'Sun 29 Nov · 8:00 pm');
      expect(_in(id, 'card-undo'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(_in(id, 'card-undo')).onPressed,
        isNotNull,
      );
      expect(_in(id, 'card-approved-note'), findsOneWidget);
      expect(_in(id, 'card-approve'), findsNothing);
    });

    testWidgets('undo is off within 15 minutes of the slot', (tester) async {
      final api = fakeApi();
      await open(tester, api, now: DateTime(2026, 11, 29, 19, 50));
      const id = 'PC-00170-v1';
      expect(
        tester.widget<FilledButton>(_in(id, 'card-undo')).onPressed,
        isNull,
      );
      expect(_in(id, 'undo-too-late'), findsOneWidget);
    });

    testWidgets('undo clears the approval and the card goes back to waiting', (
      tester,
    ) async {
      final api = fakeApi();
      final c = await pumpStudioWith(tester, api, now: _fri9);
      usePhone(tester, height: 3000);
      await goTo(tester, c, '/inbox/approve');
      await tester.ensureVisible(_in('PC-00188-v1', 'card-approve'));
      await tester.tap(_in('PC-00188-v1', 'card-approve'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('approvals-tab-approved')));
      await tester.pumpAndSettle();
      expect(_card_('PC-00188-v1'), findsOneWidget);
      await tester.ensureVisible(_in('PC-00188-v1', 'card-undo'));
      await tester.tap(_in('PC-00188-v1', 'card-undo'));
      await tester.pumpAndSettle();
      expect(api.calls, contains('versions.clear_review'));
      expect(_card_('PC-00188-v1'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('approvals-tab-waiting')));
      await tester.pumpAndSettle();
      expect(_in('PC-00188-v1', 'card-approve'), findsOneWidget);
    });

    testWidgets('empty: nothing approved is going out', (tester) async {
      final api = fakeApi(edits: {'inbox.to_approve': (j) => j['items'] = []});
      usePhone(tester, height: 900);
      final c = await pumpStudioWith(tester, api, now: _fri9);
      await goTo(tester, c, '/inbox/approve');
      await tester.tap(find.byKey(const ValueKey('approvals-tab-approved')));
      await tester.pumpAndSettle();
      // The sample approved cards come from the fake; an empty fixture still
      // shows the two seeded ones only when the waiting sample exists.
      expect(find.byKey(const ValueKey('approved-list')), findsNothing);
      expect(
        find.text('Nothing approved is going out in the next 7 days.'),
        findsOneWidget,
      );
    });
  });

  group('Arabic', () {
    testWidgets('day groups, card words and the approved sentence', (
      tester,
    ) async {
      usePhone(tester, height: 3000);
      final c = await pumpStudioWith(
        tester,
        fakeApi(),
        now: _fri9,
        locale: 'ar',
      );
      await goTo(tester, c, '/inbox/approve');
      expect(
        _text(tester, find.byKey(const ValueKey('group-today'))),
        'النهارده',
      );
      expect(
        _text(tester, find.byKey(const ValueKey('group-tomorrow'))),
        'بكرة',
      );
      expect(
        _text(tester, find.byKey(const ValueKey('group-later-2026-12-01'))),
        'التلات 1 ديسمبر',
      );
      expect(
        _text(tester, _in('PC-00188-v1', 'card-who')),
        'هتتنشر لوحدها في المعاد ده',
      );
      expect(
        _text(tester, _in('PC-00163-v2', 'card-who')),
        'هتتنشر بإيد Abdelrahman',
      );
      expect(
        _text(tester, _in('PC-00188-v1', 'card-channel')),
        'Instagram ريل على الفيد',
      );
      expect(
        _text(tester, _in('PC-00188-v1', 'card-when')),
        'الجمعة 27 نوفمبر · 8:00 م',
      );
      expect(
        _text(tester, _in('PC-00188-v1', 'card-countdown')),
        'بعد 11 ساعة',
      );
      expect(
        find.descendant(
          of: _in('PC-00188-v1', 'badge-hard-yes'),
          matching: find.text('محتاجة موافقتك الصريحة (بوست سعر/بوكس)'),
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(_in('PC-00188-v1', 'card-approve'));
      await tester.tap(_in('PC-00188-v1', 'card-approve'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: _in('PC-00188-v1', 'card-approved-note'),
          matching: find.text(
            'اتوافق عليها. هتتنشر لوحدها الجمعة 27 نوفمبر · 8:00 م على Instagram',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('empty state in Arabic', (tester) async {
      usePhone(tester, height: 900);
      final c = await pumpStudioWith(
        tester,
        fakeApi(edits: {'inbox.to_approve': (j) => j['items'] = []}),
        locale: 'ar',
      );
      await goTo(tester, c, '/inbox/approve');
      expect(find.text('مفيش حاجة مستنياك.'), findsOneWidget);
    });
  });
}
