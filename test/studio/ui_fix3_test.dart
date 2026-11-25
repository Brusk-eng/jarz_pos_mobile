import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/router/studio_router.dart';
import 'package:jarz_pos/src/studio/shared/studio_toast.dart';

import 'helpers.dart';
import 'inbox/ui_test_helpers.dart';
import 'pieces/harness.dart' as h;

/// Round 3: server wording, My ideas, Won't post from Today, polish.
int _count(List<String> calls, String key) =>
    calls.where((c) => c == key).length;

/// Every icon-only button on screen has a name a screen reader can read.
void _expectButtonsNamed(WidgetTester tester) {
  for (final w in tester.widgetList<IconButton>(find.byType(IconButton))) {
    final named =
        (w.tooltip?.isNotEmpty ?? false) ||
        (w.icon is Icon && (w.icon as Icon).semanticLabel != null);
    expect(named, isTrue, reason: 'IconButton without a name: ${w.key}');
  }
  for (final b in tester.widgetList<ButtonStyleButton>(
    find.byWidgetPredicate((w) => w is ButtonStyleButton),
  )) {
    if (b.child is Icon) {
      final el = find.byWidget(b).evaluate().first;
      var inTooltip = false;
      el.visitAncestorElements((a) {
        if (a.widget is Tooltip || a.widget is Semantics) {
          inTooltip = true;
          return false;
        }
        return true;
      });
      expect(inTooltip, isTrue, reason: 'Icon-only button without a name');
    }
  }
}

void main() {
  group('1. Server wording for checks', () {
    testWidgets('a check on the post screen shows the server line as sent', (
      tester,
    ) async {
      await h.pumpFeature(
        tester,
        location: '/calendar/post/SP-2026-00221',
        height: 3000,
        locale: 'ar',
        fixtures: h.patchedFixtures({
          'calendar.post_get': (j) => j['checks'] = [
            {
              'code': 'R6',
              'severity': 'warn',
              'message': 'سطر من السيرفر عن R6',
            },
            {'code': 'R9', 'severity': 'block', 'message': ''},
          ],
        }),
      );
      await tester.scrollUntilVisible(
        find.text('سطر من السيرفر عن R6'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('سطر من السيرفر عن R6'), findsOneWidget);
      // An empty line shows the code, never a blank row.
      expect(find.text('R9'), findsOneWidget);
    });

    testWidgets('a refused move shows the server line, not the app\'s', (
      tester,
    ) async {
      usePhone(tester, height: 3000);
      final api = fakeApi()
        ..failNext(
          'versions.approve',
          'GATE_FAILED',
          problems: [
            {'code': 'needs_verdict', 'message': 'Line from the server.'},
          ],
        );
      await pumpStudioWith(tester, api);
      await tester.tap(find.byKey(const ValueKey('line-PC-00163-v2-approve')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Line from the server.'), findsOneWidget);
    });
  });

  group('2. My ideas', () {
    Map<String, void Function(dynamic)> mine() => {
      'ideas.list': (j) {
        final base = (j['items'] as List).first as Map;
        Map<String, dynamic> idea(String id, String status) => {
          ...Map<String, dynamic>.from(base),
          'id': id,
          'title': 'Idea $id',
          'status': status,
          'actions': <String>[],
        };
        j['items'] = [
          idea('IDEA-1', 'Open'),
          {...idea('IDEA-2', 'Kept'), 'kept_piece_id': 'PC-00163'},
          {
            ...idea('IDEA-3', 'Dropped'),
            'drop_reason': 'We shot it last month',
          },
        ];
      },
    };

    testWidgets('lists title, status and what happens next', (tester) async {
      usePhone(tester, height: 1600);
      final api = fakeApi(role: 'creator', edits: mine());
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/inbox/my-ideas');
      expect(find.text('My ideas'), findsWidgets);
      expect(find.text('Idea IDEA-1'), findsOneWidget);
      expect(
        find.text('Waiting for the founder to keep or drop it.'),
        findsOneWidget,
      );
      expect(find.text('Kept. It is now a piece.'), findsOneWidget);
      expect(find.byKey(const ValueKey('my-idea-open-piece')), findsOneWidget);
      expect(
        find.text('Dropped and archived with the reason.'),
        findsOneWidget,
      );
      expect(find.text('Reason: We shot it last month'), findsOneWidget);
      // No Keep or Drop for the person who raised it.
      expect(find.byKey(const ValueKey('idea-keep')), findsNothing);
    });

    testWidgets('empty state says what to do first', (tester) async {
      usePhone(tester, height: 900);
      final api = fakeApi(
        role: 'creator',
        edits: {'ideas.list': (j) => j['items'] = []},
      );
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/inbox/my-ideas');
      expect(find.textContaining('have not brought an idea'), findsOneWidget);
    });

    testWidgets('Arabic names', (tester) async {
      usePhone(tester, height: 1600);
      final api = fakeApi(role: 'story', edits: mine());
      final c = await pumpStudioWith(tester, api, locale: 'ar');
      await goTo(tester, c, '/inbox/my-ideas');
      expect(find.text('أفكاري'), findsWidgets);
      expect(find.text('اتحفظت. بقت قطعة دلوقتي.'), findsOneWidget);
      expect(find.text('السبب: We shot it last month'), findsOneWidget);
    });

    testWidgets('reachable from Ideas and from Today; proposing refreshes it', (
      tester,
    ) async {
      usePhone(tester, height: 1600);
      final api = fakeApi(role: 'creator', edits: mine());
      final c = await pumpStudioWith(tester, api);
      expect(find.byKey(const ValueKey('today-my-ideas')), findsOneWidget);
      await goTo(tester, c, '/inbox/ideas');
      await tester.tap(find.byKey(const ValueKey('ideas-mine')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('my-ideas-list')), findsOneWidget);
      final before = _count(api.calls, 'ideas.list');
      await tester.tap(find.byKey(const ValueKey('my-ideas-new')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('idea-title')),
        'Friday jar',
      );
      await tester.tap(find.byKey(const ValueKey('idea-submit')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('ideas.propose'));
      expect(_count(api.calls, 'ideas.list'), greaterThan(before));
      // The toast outlived the sheet that asked for it.
      expect(find.text('Idea sent. The founder will see it.'), findsOneWidget);
    });

    testWidgets('the founder has no My ideas link', (tester) async {
      usePhone(tester, height: 1600);
      final c = await pumpStudioWith(tester, fakeApi());
      expect(find.byKey(const ValueKey('today-my-ideas')), findsNothing);
      await goTo(tester, c, '/inbox/ideas');
      expect(find.byKey(const ValueKey('ideas-mine')), findsNothing);
    });
  });

  group("3. Won't post from Today", () {
    Map<String, void Function(dynamic)> hand() => {
      'today.get': (j) {
        (j['blocks'] as List).add({
          'key': 'didnt_go_out',
          'title': "Didn't go out",
          'count': 1,
          'level': 'stop',
          'more_route': null,
          'lines': [
            {
              'id': 'SP-2026-00175',
              'kind': 'post',
              'title': 'Story: the late shift',
              'subtitle': 'Story · was due Tue 24 Nov, 20:00',
              'level': 'stop',
              'due': null,
              'route': '/calendar/post/SP-2026-00175',
              'thumb': null,
              'ref': {'doctype': 'Social Post', 'name': 'SP-2026-00175'},
              'badge': null,
              'actions': ['wont_post', 'open'],
            },
          ],
        });
      },
    };

    testWidgets('asks for a reason, calls the endpoint, refreshes Today', (
      tester,
    ) async {
      usePhone(tester, height: 3000);
      final api = fakeApi(role: 'story', edits: hand());
      await pumpStudioWith(tester, api);
      final btn = find.byKey(const ValueKey('line-SP-2026-00175-wont_post'));
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();
      // The reason is required, as on the post screen.
      await tester.tap(find.byKey(const ValueKey('ask-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Write the reason first.'), findsOneWidget);
      expect(api.calls, isNot(contains('calendar.post_wont_post')));
      final todayBefore = _count(api.calls, 'today.get');
      await tester.enterText(
        find.byKey(const ValueKey('ask-text')),
        'Held for next week',
      );
      await tester.tap(find.byKey(const ValueKey('ask-confirm')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('calendar.post_wont_post'));
      expect(_count(api.calls, 'today.get'), greaterThan(todayBefore));
    });

    testWidgets('cancelling the sheet changes nothing', (tester) async {
      usePhone(tester, height: 3000);
      final api = fakeApi(role: 'story', edits: hand());
      await pumpStudioWith(tester, api);
      final btn = find.byKey(const ValueKey('line-SP-2026-00175-wont_post'));
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5)); // outside the dialog
      await tester.pumpAndSettle();
      expect(api.calls, isNot(contains('calendar.post_wont_post')));
    });
  });

  group('4. Polish', () {
    testWidgets('a toast shown as a screen closes is not lost', (tester) async {
      usePhone(tester, height: 1600);
      final c = await pumpStudioWith(tester, fakeApi());
      await goTo(tester, c, '/inbox/notifications');
      showStudioToast('Saved for you');
      await tester.pump();
      await goTo(tester, c, '/today');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Saved for you'), findsOneWidget);
    });

    testWidgets('root tabs have no back arrow; pushed screens do', (
      tester,
    ) async {
      usePhone(tester, height: 900);
      final c = await pumpStudioWith(tester, fakeApi());
      for (final tab in [
        '/today',
        '/inbox/approve',
        '/inbox/ideas',
        '/calendar',
        '/pieces',
        '/more',
      ]) {
        await goTo(tester, c, tab);
        expect(find.byKey(const ValueKey('back')), findsNothing, reason: tab);
      }
      await goTo(tester, c, '/inbox/notifications');
      expect(find.byKey(const ValueKey('back')), findsOneWidget);
      // A pushed screen on top of a tab.
      await goTo(tester, c, '/pieces');
      c.read(studioRouterProvider).push('/pieces/PC-00163');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('back')), findsOneWidget);
    });

    testWidgets('a disabled Upload says why', (tester) async {
      usePhone(tester, height: 1600);
      final c = await pumpStudioWith(tester, fakeApi());
      await goTo(tester, c, '/assets/new');
      expect(find.byKey(const ValueKey('add-upload-why')), findsOneWidget);
      expect(find.textContaining('Pick at least one file'), findsOneWidget);
    });

    testWidgets('Arabic: a disabled Upload says why', (tester) async {
      usePhone(tester, height: 1600);
      final c = await pumpStudioWith(tester, fakeApi(), locale: 'ar');
      await goTo(tester, c, '/assets/new');
      expect(find.textContaining('اختار ملف واحد'), findsOneWidget);
    });

    for (final locale in ['en', 'ar']) {
      testWidgets('icon-only buttons have a name ($locale)', (tester) async {
        usePhone(tester, height: 1600);
        final api = fakeApi(role: 'creator');
        final c = await pumpStudioWith(tester, api, locale: locale);
        for (final path in [
          '/today',
          '/inbox/ideas',
          '/inbox/my-ideas',
          '/inbox/notifications',
          '/calendar',
          '/pieces',
          '/more',
          '/assets',
          '/assets/new',
        ]) {
          await goTo(tester, c, path);
          _expectButtonsNamed(tester);
        }
      });
    }
  });
}
