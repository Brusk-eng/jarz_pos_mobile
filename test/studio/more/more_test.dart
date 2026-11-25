import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/features/shell/presentation/more_screen.dart';

import 'more_test_utils.dart';

List<String> entryKeys(WidgetTester tester) {
  const all = [
    'more-shoots',
    'more-assets',
    'more-references',
    'more-paid',
    'more-results',
    'more-reports',
    'more-settings',
  ];
  final found = <String, double>{};
  for (final k in all) {
    final f = find.byKey(ValueKey(k));
    if (f.evaluate().isNotEmpty) found[k] = tester.getTopLeft(f).dy;
  }
  return (found.keys.toList()..sort((a, b) => found[a]!.compareTo(found[b]!)));
}

void main() {
  group('More menu', () {
    testWidgets('founder sees every entry, from session.me, in its order', (
      tester,
    ) async {
      await pumpMoreRouter(tester, api: FakeStudioApi(delay: Duration.zero));
      expect(entryKeys(tester), [
        'more-shoots',
        'more-assets',
        'more-references',
        'more-paid',
        'more-results',
        'more-reports',
        'more-settings',
      ]);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Notification settings'), findsOneWidget);
      expect(find.byKey(const ValueKey('more-language')), findsOneWidget);
    });

    testWidgets('lead has no Settings; creator has three; story one', (
      tester,
    ) async {
      await pumpMoreRouter(
        tester,
        api: FakeStudioApi(role: 'lead', delay: Duration.zero),
      );
      final lead = entryKeys(tester);
      expect(lead, contains('more-paid'));
      expect(lead, isNot(contains('more-settings')));
      expect(lead.first, 'more-shoots');
    });

    testWidgets('creator sees shoots, library, references and results only', (
      tester,
    ) async {
      await pumpMoreRouter(
        tester,
        api: FakeStudioApi(role: 'creator', delay: Duration.zero),
      );
      expect(entryKeys(tester), [
        'more-shoots',
        'more-assets',
        'more-references',
        'more-results',
      ]);
    });

    testWidgets('story lead sees the library only', (tester) async {
      await pumpMoreRouter(
        tester,
        api: FakeStudioApi(role: 'story', delay: Duration.zero),
      );
      expect(entryKeys(tester), ['more-assets']);
    });

    testWidgets('a user with no role sees what to do first', (tester) async {
      await pumpMore(
        tester,
        const StudioMoreScreen(),
        api: FakeStudioApi(role: 'none', delay: Duration.zero),
      );
      expect(find.byKey(const ValueKey('empty-purpose')), findsOneWidget);
      expect(find.byKey(const ValueKey('empty-first-step')), findsOneWidget);
    });

    testWidgets('entries link to the More routes', (tester) async {
      final h = await pumpMoreRouter(tester);
      await tapKey(tester, 'more-references');
      expect(where(h.router), '/more/references');
      h.router.go('/more');
      await tester.pumpAndSettle();
      await tapKey(tester, 'more-shoots');
      expect(where(h.router), '/shoots');
      expect(find.byKey(const ValueKey('stub-shoots')), findsOneWidget);
      h.router.go('/more');
      await tester.pumpAndSettle();
      await tapKey(tester, 'more-assets');
      expect(where(h.router), '/assets');
      h.router.go('/more');
      await tester.pumpAndSettle();
      await tapKey(tester, 'more-notifications');
      expect(where(h.router), '/inbox/notifications/settings');
    });

    testWidgets('the language row flips to Arabic and back', (tester) async {
      await pumpMoreRouter(tester);
      expect(find.text('Library'), findsOneWidget);
      await tapKey(tester, 'more-language');
      expect(find.text('المكتبة'), findsOneWidget);
      await tapKey(tester, 'more-language');
      expect(find.text('Library'), findsOneWidget);
    });

    testWidgets('sign out shows in the fake build too', (tester) async {
      await pumpMoreRouter(tester);
      expect(find.byKey(const ValueKey('more-sign-out')), findsOneWidget);
    });

    testWidgets('sign out shows in a real build', (tester) async {
      await pumpMoreRouter(tester, fake: false);
      expect(find.byKey(const ValueKey('more-sign-out')), findsOneWidget);
    });

    testWidgets('the help sheet opens', (tester) async {
      await pumpMoreRouter(tester);
      await tapKey(tester, 'help');
      expect(find.text('Got it'), findsOneWidget);
    });
  });

  group('routes', () {
    testWidgets('every route opens by deep link and back goes to its parent', (
      tester,
    ) async {
      const pairs = {
        '/more/references': '/more',
        '/more/references/competitors': '/more/references',
        '/more/references/competitors/1980-coffee':
            '/more/references/competitors',
        '/more/references/ad-1114412864248331': '/more/references',
        '/more/paid': '/more',
        '/more/paid/queue': '/more/paid',
        '/more/paid/rounds/R2b': '/more/paid',
        '/more/results': '/more',
        '/more/results/pieces': '/more/results',
        '/more/results/summary': '/more/results',
        '/more/reports': '/more',
        '/more/settings': '/more',
        '/more/settings/rules': '/more/settings',
        '/more/settings/rules/again_max_cpp': '/more/settings/rules',
        '/more/settings/flavours': '/more/settings',
        '/more/settings/flavours/carrot-cake': '/more/settings/flavours',
        '/more/settings/claims': '/more/settings',
        '/more/settings/moments': '/more/settings',
        '/more/settings/people': '/more/settings',
        '/more/settings/people/ali': '/more/settings/people',
        '/more/settings/options': '/more/settings',
      };
      for (final e in pairs.entries) {
        final h = await pumpMoreRouter(tester, location: e.key);
        expect(where(h.router), e.key);
        expect(
          find.byKey(const ValueKey('back')),
          findsOneWidget,
          reason: e.key,
        );
        await tester.tap(find.byKey(const ValueKey('back')));
        await tester.pumpAndSettle();
        expect(where(h.router), e.value, reason: e.key);
        await tester.pumpWidget(const SizedBox());
      }
    });
  });
}
