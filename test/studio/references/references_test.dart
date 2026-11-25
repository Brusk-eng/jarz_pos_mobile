import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/features/references/presentation/competitors_screens.dart';
import 'package:jarz_pos/src/studio/features/references/presentation/reference_screen.dart';
import 'package:jarz_pos/src/studio/features/references/presentation/references_screen.dart';

import '../more/more_test_utils.dart';

const _refId = 'ad-1114412864248331';

Map<String, dynamic> _ref(String id, {String status = 'New'}) {
  final base = Map<String, dynamic>.from(fixtureJson('references.get') as Map);
  return {...base, 'id': id, 'title': 'Reference $id', 'status': status};
}

Finder _key(String k) => find.byKey(ValueKey(k));

void main() {
  group('references grid', () {
    testWidgets('shows a skeleton, then the cards', (tester) async {
      await pumpMore(tester, const ReferencesScreen(), settle: false);
      await tester.pump();
      expect(_key('skeleton'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(_key('refs-grid'), findsOneWidget);
      expect(find.text('Crumbl: new menu every week'), findsOneWidget);
    });

    testWidgets('empty says what to do first', (tester) async {
      final api = RecordingApi(
        fixtures: patchFixtures({
          'references.list': (j) => {'items': [], 'next': null},
        }),
      );
      await pumpMore(tester, const ReferencesScreen(), api: api);
      expect(_key('empty-purpose'), findsOneWidget);
      expect(find.textContaining('Claude adds new ones'), findsOneWidget);
    });

    testWidgets('error shows plain words and retry reloads', (tester) async {
      final api = RecordingApi()..failNext('references.list', 'SERVER_ERROR');
      await pumpMore(tester, const ReferencesScreen(), api: api);
      expect(_key('error-text'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(_key('refs-grid'), findsOneWidget);
      expect(api.count('references.list'), 2);
    });

    testWidgets('status chip, search and filters go to the server', (
      tester,
    ) async {
      final api = RecordingApi();
      await pumpMore(tester, const ReferencesScreen(), api: api);
      await tapKey(tester, 'chip-Shortlisted');
      expect(api.last('references.list')!['status'], 'Shortlisted');

      await typeKey(tester, 'search-field', 'crumbl');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(api.last('references.list')!['q'], 'crumbl');

      await tapKey(tester, 'refs-filters');
      await tapKey(tester, 'filter-reel');
      await tapKey(tester, 'filter-ok');
      await tapKey(tester, 'filter-rank');
      await tapKey(tester, 'filters-apply');
      final p = api.last('references.list')!;
      expect(p['media_type'], 'reel');
      expect(p['remake'], 'ok');
      expect(p['sort'], 'rank');
      expect(p['status'], 'Shortlisted');
    });

    testWidgets('a second page loads on "show more"', (tester) async {
      final api = RecordingApi();
      api.respond['references.list'] = (p) => p['after'] == 'c1'
          ? {
              'items': [_ref('ref-two')],
              'next': null,
            }
          : {
              'items': [_ref('ref-one')],
              'next': 'c1',
            };
      await pumpMore(tester, const ReferencesScreen(), api: api);
      expect(find.text('Reference ref-one'), findsOneWidget);
      expect(find.text('Reference ref-two'), findsNothing);
      await tapKey(tester, 'show-more');
      expect(find.text('Reference ref-two'), findsOneWidget);
      expect(_key('show-more'), findsNothing);
    });

    testWidgets('a failed second page keeps the list and says so', (
      tester,
    ) async {
      final api = RecordingApi();
      var n = 0;
      api.respond['references.list'] = (p) {
        if (p['after'] == 'c1') throw StateError('boom');
        n++;
        return {
          'items': [_ref('ref-one')],
          'next': 'c1',
        };
      };
      await pumpMore(tester, const ReferencesScreen(), api: api);
      await tapKey(tester, 'show-more');
      expect(_key('show-more-failed'), findsOneWidget);
      expect(find.text('Reference ref-one'), findsOneWidget);
      expect(n, 1);
    });

    testWidgets('a card opens the reference page', (tester) async {
      final h = await pumpMoreRouter(tester, location: '/more/references');
      await tapKey(tester, 'ref-$_refId');
      expect(where(h.router), '/more/references/$_refId');
      expect(_key('reference-body'), findsOneWidget);
    });
  });

  group('reference page', () {
    Future<RecordingApi> open(
      WidgetTester tester, {
      List<String>? actions,
      String status = 'New',
      Map<String, dynamic Function(dynamic)> more = const {},
      Locale? ignore,
      String locale = 'en',
      List<Uri>? opened,
    }) async {
      final api = RecordingApi(
        fixtures: patchFixtures({
          'references.get': (j) => {
            ...(j as Map),
            'status': status,
            if (actions != null) 'actions': actions,
          },
          ...more,
        }),
      );
      await pumpMore(
        tester,
        const ReferenceScreen(referenceId: _refId),
        api: api,
        locale: locale,
        size: const Size(360, 3000),
        opened: opened,
      );
      return api;
    }

    testWidgets('shows the take, numbers in plain words and the links', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Crumbl: new menu every week'), findsWidgets);
      expect(find.text('Our take'), findsOneWidget);
      expect(find.text('Days running'), findsOneWidget);
      expect(find.text('Copies of the ad'), findsOneWidget);
      expect(_key('link-RL-00107'), findsOneWidget);
      expect(find.text('Strong match'), findsOneWidget);
    });

    testWidgets('the source opens in the browser', (tester) async {
      final opened = <Uri>[];
      await open(tester, opened: opened);
      await tapKey(tester, 'ref-open-source');
      expect(opened.single.toString(), contains('ads.example.test'));
    });

    testWidgets('buttons come only from actions', (tester) async {
      await open(tester, actions: ['note']);
      expect(_key('ref-note'), findsOneWidget);
      for (final k in [
        'ref-shortlist',
        'ref-send',
        'ref-used',
        'ref-link',
        'ref-drop',
      ]) {
        expect(_key(k), findsNothing, reason: k);
      }
      expect(_key('unlink-RL-00107'), findsNothing);
    });

    testWidgets('no actions, no buttons', (tester) async {
      await open(tester, actions: []);
      expect(find.byType(FilledButton), findsNothing);
      expect(_key('ref-note'), findsNothing);
    });

    testWidgets('all actions show every button', (tester) async {
      await open(tester, status: 'For a shoot');
      for (final k in [
        'ref-shortlist',
        'ref-send',
        'ref-used',
        'ref-link',
        'ref-note',
        'ref-drop',
      ]) {
        expect(_key(k), findsOneWidget, reason: k);
      }
    });

    testWidgets('shortlist moves the status, with a plain confirmation', (
      tester,
    ) async {
      final api = await open(tester);
      await tapKey(tester, 'ref-shortlist');
      final p = api.last('references.update_status')!;
      expect(p['status'], 'Shortlisted');
      expect(p['reference_id'], _refId);
      expect(snackText(tester), 'Now: Shortlisted');
    });

    testWidgets('mark as used sends Remade', (tester) async {
      final api = await open(tester, status: 'For a shoot');
      await tapKey(tester, 'ref-used');
      expect(api.last('references.update_status')!['status'], 'Remade');
    });

    testWidgets('drop needs a reason and sends it', (tester) async {
      final api = await open(tester);
      await tapKey(tester, 'ref-drop');
      final confirm = tester.widget<FilledButton>(_key('text-dialog-confirm'));
      expect(confirm.onPressed, isNull);
      await typeKey(tester, 'text-dialog-field', 'Not our look');
      await tapKey(tester, 'text-dialog-confirm');
      final p = api.last('references.update_status')!;
      expect(p['status'], 'Dropped');
      expect(p['note'], 'Not our look');
    });

    testWidgets('send to a shoot picks a shoot, then a shot', (tester) async {
      final api = await open(tester);
      await tapKey(tester, 'ref-send');
      expect(find.text('Pick a shoot'), findsOneWidget);
      await tapKey(tester, 'pick-shoot-SHOOT-0006');
      expect(find.text('Pick the shot'), findsOneWidget);
      await tapKey(tester, 'pick-shot-SHOT-00108');
      final p = api.last('references.update_status')!;
      expect(p['status'], 'For a shoot');
      expect(p['shot_id'], 'SHOT-00108');
    });

    testWidgets('link to a piece searches and links', (tester) async {
      final api = await open(tester);
      await tapKey(tester, 'ref-link');
      await tapKey(tester, 'pick-piece-PC-00188');
      final p = api.last('references.link')!;
      expect(p['piece_id'], 'PC-00188');
      expect(p['unlink'], isNull);
    });

    testWidgets('unlink removes a link', (tester) async {
      final api = await open(tester);
      await tapKey(tester, 'unlink-RL-00107');
      final p = api.last('references.link')!;
      expect(p['unlink'], true);
      expect(p['shot_id'], 'SHOT-00107');
    });

    testWidgets('add a note', (tester) async {
      final api = await open(tester);
      await tapKey(tester, 'ref-note');
      await typeKey(tester, 'text-dialog-field', 'Try with four jars');
      await tapKey(tester, 'text-dialog-confirm');
      expect(api.last('references.note')!['text'], 'Try with four jars');
      expect(snackText(tester), 'Note added');
    });

    testWidgets('errors are said in plain words', (tester) async {
      final api = await open(tester);
      final cases = {
        'SHADOW_MODE':
            'The Studio is not switched on yet. You can look, but '
            'not change anything.',
        'NOT_PERMITTED': 'You cannot do that.',
        'SERVER_ERROR': 'Something went wrong. Try again.',
      };
      for (final e in cases.entries) {
        api.failNext('references.update_status', e.key);
        await tapKey(tester, 'ref-shortlist');
        expect(snackText(tester), e.value, reason: e.key);
        // The optimistic status is rolled back.
        expect(find.text('New'), findsOneWidget);
        ScaffoldMessenger.of(
          tester.element(find.byType(Scaffold).first),
        ).clearSnackBars();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('VALIDATION shows the server message', (tester) async {
      final api = await open(tester);
      api.failNext(
        'references.update_status',
        'VALIDATION',
        message: 'Pick a shot first.',
        field: 'shot_id',
      );
      await tapKey(tester, 'ref-shortlist');
      expect(snackText(tester), 'Pick a shot first.');
    });

    testWidgets('STALE takes the fresh copy and says so', (tester) async {
      final api = await open(tester);
      api.failNext(
        'references.update_status',
        'STALE',
        current: {
          ..._ref(_refId, status: 'Dropped'),
          'actions': ['note'],
        },
      );
      await tapKey(tester, 'ref-shortlist');
      expect(snackText(tester), contains('Someone changed this'));
      expect(find.text('Dropped'), findsOneWidget);
      expect(_key('ref-shortlist'), findsNothing);
    });

    testWidgets('ALREADY_DONE shows the current state quietly', (tester) async {
      final api = await open(tester);
      api.failNext(
        'references.update_status',
        'ALREADY_DONE',
        current: {
          ..._ref(_refId, status: 'Shortlisted'),
          'actions': ['note'],
        },
      );
      await tapKey(tester, 'ref-shortlist');
      expect(find.text('Shortlisted'), findsOneWidget);
      expect(_key('ref-shortlist'), findsNothing);
    });

    testWidgets('Arabic page renders right to left at 360 px', (tester) async {
      await open(tester, locale: 'ar');
      expect(find.text('رأينا'), findsOneWidget);
      expect(find.text('أيام شغّال'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('competitors', () {
    testWidgets('list, search and open', (tester) async {
      final api = RecordingApi();
      final h = await pumpMoreRouter(
        tester,
        location: '/more/references/competitors',
        api: api,
      );
      expect(find.text('1980 Coffee'), findsOneWidget);
      await typeKey(tester, 'search-field', 'coffee');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(api.last('references.competitors')!['q'], 'coffee');
      await tapKey(tester, 'competitor-1980-coffee');
      expect(where(h.router), '/more/references/competitors/1980-coffee');
      expect(_key('competitor-body'), findsOneWidget);
      expect(find.text('Followers'), findsOneWidget);
    });

    testWidgets('empty list says what to do', (tester) async {
      final api = RecordingApi(
        fixtures: patchFixtures({
          'references.competitors': (j) => {'items': [], 'next': null},
        }),
      );
      await pumpMore(tester, const CompetitorsScreen(), api: api);
      expect(_key('empty-first-step'), findsOneWidget);
    });

    testWidgets('their references filter the grid', (tester) async {
      final api = RecordingApi();
      final h = await pumpMoreRouter(
        tester,
        location: '/more/references/competitors/1980-coffee',
        api: api,
      );
      await tapKey(tester, 'competitor-see-references');
      expect(where(h.router), '/more/references');
      expect(api.last('references.list')!['competitor_key'], '1980-coffee');
    });

    testWidgets('social links open outside the app', (tester) async {
      final opened = <Uri>[];
      await pumpMoreRouter(
        tester,
        location: '/more/references/competitors/1980-coffee',
        opened: opened,
      );
      await tapKey(tester, 'competitor-ig');
      expect(opened.single.toString(), 'https://instagram.com/1980.coffee');
    });

    testWidgets('a missing competitor shows the error state', (tester) async {
      final api = RecordingApi()
        ..failNext('references.competitor_get', 'NOT_FOUND');
      await pumpMore(
        tester,
        const CompetitorScreen(competitorKey: 'nope'),
        api: api,
      );
      expect(_key('error-text'), findsOneWidget);
    });
  });
}
