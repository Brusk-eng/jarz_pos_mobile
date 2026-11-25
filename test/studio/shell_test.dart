import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_locale.dart';
import 'package:jarz_pos/src/studio/core/roles/studio_role.dart';

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
    expect(find.byKey(const ValueKey('empty-purpose')), findsOneWidget);
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
      expect(currentLocation(c), path);
      expect(tester.takeException(), isNull, reason: path);
    }
    await goTo(tester, c, '/pieces/abc-1');
    expect(find.text('Piece abc-1'), findsOneWidget);
  });

  testWidgets('placeholder screens say what they are for', (tester) async {
    usePhone(tester);
    final c = await pumpStudio(tester);
    await goTo(tester, c, '/inbox/decisions');
    expect(find.textContaining('Open questions with options'), findsOneWidget);
    await goTo(tester, c, '/paid');
    expect(find.textContaining('each ad with its numbers'), findsOneWidget);
  });

  group('role changes Today and More', () {
    final todayKeys = [
      for (final b in TodayBlock.values) 'today-block-${b.name}',
    ];

    testWidgets('founder Today order', (tester) async {
      usePhone(tester, height: 1400);
      await pumpStudio(tester, role: 'founder');
      expect(orderOf(tester, todayKeys), [
        'today-block-readyToPost',
        'today-block-didntGoOut',
        'today-block-readsMissing',
        'today-block-warnings',
        'today-block-dueToday',
        'today-block-sentBack',
        'today-block-stories',
      ]);
    });

    testWidgets('creator Today order differs', (tester) async {
      usePhone(tester, height: 1400);
      await pumpStudio(tester, role: 'creator');
      expect(orderOf(tester, todayKeys), [
        'today-block-sentBack',
        'today-block-dueToday',
        'today-block-readyToPost',
        'today-block-readsMissing',
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
      ]);
    });

    testWidgets('lead reads Paid but has no Settings', (tester) async {
      usePhone(tester, height: 1000);
      final c = await pumpStudio(tester, role: 'lead');
      await goTo(tester, c, '/more');
      final order = orderOf(tester, moreKeys());
      expect(order, contains('more-paid'));
      expect(order, isNot(contains('more-settings')));
      expect(order.first, 'more-shoots');
    });
  });

  testWidgets('a More item opens at its own URL and back returns to More', (
    tester,
  ) async {
    usePhone(tester);
    final c = await pumpStudio(tester);
    await goTo(tester, c, '/more');
    await tester.tap(find.byKey(const ValueKey('more-shoots')));
    await tester.pumpAndSettle();
    expect(currentLocation(c), '/shoots');
    await tester.tap(find.byKey(const ValueKey('back')));
    await tester.pumpAndSettle();
    expect(currentLocation(c), '/more');
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
