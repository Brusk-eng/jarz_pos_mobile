import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_locale.dart';
import 'package:jarz_pos/src/studio/core/roles/studio_role.dart';
import 'package:jarz_pos/src/studio/data/models/studio_enums.dart';

import 'package:jarz_pos/src/studio/features/pieces/presentation/piece_screen.dart';

import 'package:jarz_pos/src/studio/core/push/studio_push_router.dart';

import 'package:jarz_pos/src/studio/features/shoots/presentation/shoots_list_screen.dart';

import 'helpers.dart';

/// Vertical order of widgets with the given keys.
List<String> orderOf(WidgetTester tester, Iterable<String> keys) {
  final found = <(String, double)>[];
  for (final k in keys) {
    final f = find.byKey(ValueKey(k));
    if (f.evaluate().isNotEmpty) {
      found.add((k, tester.getTopLeft(f).dy));
    }
  }
  found.sort((a, b) => a.$2.compareTo(b.$2));
  return found.map((e) => e.$1).toList();
}

void main() {
  testWidgets('five tabs render and switch', (tester) async {
    usePhone(tester);
    final c = await pumpStudio(tester);

    for (final label in ['Today', 'Inbox', 'Calendar', 'Pieces', 'More']) {
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('shell-bar')),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: label,
      );
    }
    expect(currentLocation(c), '/today');

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    expect(currentLocation(c), '/calendar');

    await tester.tap(find.text('Pieces'));
    await tester.pumpAndSettle();
    expect(currentLocation(c), '/pieces');

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(currentLocation(c), '/more');
  });

  testWidgets('Inbox has three tabs that route', (tester) async {
    usePhone(tester);
    final c = await pumpStudio(tester);
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();
    expect(currentLocation(c), '/inbox/approve');

    await tester.tap(find.byKey(const ValueKey('inbox-tab-decisions')));
    await tester.pumpAndSettle();
    expect(currentLocation(c), '/inbox/decisions');

    await tester.tap(find.byKey(const ValueKey('inbox-tab-ideas')));
    await tester.pumpAndSettle();
    expect(currentLocation(c), '/inbox/ideas');
    expect(find.byKey(const ValueKey('ideas-list')), findsOneWidget);
  });

  testWidgets('every route is deep-linkable', (tester) async {
    usePhone(tester);
    final c = await pumpStudio(tester);
    for (final path in [
      '/today',
      '/inbox/approve',
      '/inbox/decisions',
      '/inbox/ideas',
      '/calendar',
      '/pieces',
      '/pieces/abc-1',
      '/shoots',
      '/shoots/s-9',
      '/assets',
      '/references',
      '/paid',
      '/results',
      '/reports',
      '/settings',
    ]) {
      await goTo(tester, c, path);
      expect(currentLocation(c), studioAppRoute(path));
      expect(tester.takeException(), isNull, reason: path);
    }
    await goTo(tester, c, '/pieces/abc-1');
    expect(find.byType(PieceScreen), findsOneWidget);
  });

  testWidgets('screens open at their own URLs', (tester) async {
    usePhone(tester);
    final c = await pumpStudio(tester);
    await goTo(tester, c, '/inbox/decisions');
    expect(find.byKey(const ValueKey('decisions-list')), findsOneWidget);
    await goTo(tester, c, '/shoots');
    expect(find.byType(ShootsListScreen), findsOneWidget);
  });

  group('role changes Today and More', () {
    // Today's blocks and their order come from the server (today.get); the
    // client keeps the server's order. First block per role, from the fixtures.
    final todayKeys = [
      for (final b in BlockKey.values) 'today-block-${b.name}',
    ];

    testWidgets('founder Today starts with what waits for his yes', (
      tester,
    ) async {
      usePhone(tester, height: 1400);
      await pumpStudio(tester, role: 'founder');
      expect(orderOf(tester, todayKeys).take(2).toList(), [
        'today-block-toApprove',
        'today-block-decisions',
      ]);
    });

    testWidgets('creator Today order differs', (tester) async {
      usePhone(tester, height: 1400);
      await pumpStudio(tester, role: 'creator');
      expect(orderOf(tester, todayKeys), [
        'today-block-sentBack',
        'today-block-dueToday',
        'today-block-shootTomorrow',
      ]);
    });

    testWidgets('story lead sees stories first', (tester) async {
      usePhone(tester, height: 1400);
      await pumpStudio(tester, role: 'story');
      expect(orderOf(tester, todayKeys).first, 'today-block-stories');
    });

    testWidgets('lead sees Blocked first', (tester) async {
      usePhone(tester, height: 1400);
      await pumpStudio(tester, role: 'lead');
      expect(orderOf(tester, todayKeys).first, 'today-block-blocked');
    });

    List<String> moreKeys() => [
      for (final m in MoreItem.values) 'more-${m.name}',
    ];

    testWidgets('founder More has all seven in design order', (tester) async {
      usePhone(tester, height: 1000);
      final c = await pumpStudio(tester, role: 'founder');
      await goTo(tester, c, '/more');
      expect(orderOf(tester, moreKeys()), [
        'more-shoots',
        'more-assets',
        'more-references',
        'more-paid',
        'more-results',
        'more-reports',
        'more-settings',
      ]);
    });

    testWidgets('creator More is short; no Paid or Settings', (tester) async {
      usePhone(tester, height: 1000);
      final c = await pumpStudio(tester, role: 'creator');
      await goTo(tester, c, '/more');
      expect(orderOf(tester, moreKeys()), [
        'more-shoots',
        'more-assets',
        'more-references',
        'more-results',
      ]);
    });

    testWidgets('lead reads Paid and has Settings', (tester) async {
      usePhone(tester, height: 1000);
      final c = await pumpStudio(tester, role: 'lead');
      await goTo(tester, c, '/more');
      final order = orderOf(tester, moreKeys());
      expect(order, contains('more-paid'));
      expect(order, contains('more-settings'));
      expect(order.first, 'more-shoots');
    });
  });

  testWidgets('a More item links to its own URL under /more', (tester) async {
    usePhone(tester);
    final c = await pumpStudio(tester);
    await goTo(tester, c, '/more');
    await tester.tap(find.byKey(const ValueKey('more-shoots')));
    await tester.pumpAndSettle();
    // Library and Shoots are other screens' routes: the list only links to
    // them. Back from a More screen is tested in test/studio/more.
    expect(currentLocation(c), '/shoots');
  });

  testWidgets('a user with no Studio role sees the no-access screen', (
    tester,
  ) async {
    usePhone(tester);
    final c = await pumpStudio(tester, role: 'none');
    expect(find.byKey(const ValueKey('no-access-title')), findsOneWidget);
    expect(find.text("You don't have Studio access"), findsOneWidget);
    expect(currentLocation(c), '/no-access');
    expect(find.byKey(const ValueKey('shell-bar')), findsNothing);

    // Deep links do not get past it.
    await goTo(tester, c, '/inbox/decisions');
    expect(currentLocation(c), '/no-access');
  });

  testWidgets('Arabic switches text and direction (RTL)', (tester) async {
    usePhone(tester);
    final c = await pumpStudio(tester);
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.ltr,
    );

    await tester.tap(find.byKey(const ValueKey('lang-switch')));
    await tester.pumpAndSettle();

    expect(c.read(studioLocaleProvider).languageCode, 'ar');
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.rtl,
    );
    final bar = find.byKey(const ValueKey('shell-bar'));
    expect(
      find.descendant(of: bar, matching: find.text('النهارده')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bar, matching: find.text('المزيد')),
      findsOneWidget,
    );

    // RTL mirrors the bar: Today is on the right, More on the left.
    final today = tester.getCenter(
      find.descendant(of: bar, matching: find.text('النهارده')),
    );
    final more = tester.getCenter(
      find.descendant(of: bar, matching: find.text('المزيد')),
    );
    expect(today.dx, greaterThan(more.dx));

    await goTo(tester, c, '/inbox/decisions');
    expect(find.text('القرارات'), findsWidgets);
  });

  testWidgets('wide screens use a rail instead of the bottom bar', (
    tester,
  ) async {
    usePhone(tester, width: 1200, height: 800);
    await pumpStudio(tester);
    expect(find.byKey(const ValueKey('shell-rail')), findsOneWidget);
    expect(find.byKey(const ValueKey('shell-bar')), findsNothing);
  });
}
