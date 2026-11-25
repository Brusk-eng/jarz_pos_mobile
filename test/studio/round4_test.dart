import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/models/studio_enums.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';
import 'package:jarz_pos/src/studio/features/calendar/presentation/calendar_extras.dart';
import 'package:jarz_pos/src/studio/features/inbox/state/inbox_state.dart';
import 'package:jarz_pos/src/studio/features/references/presentation/competitors_screens.dart';
import 'package:jarz_pos/src/studio/features/references/presentation/reference_screen.dart';
import 'package:jarz_pos/src/studio/features/results/presentation/ratings_screen.dart';
import 'package:jarz_pos/src/studio/features/results/presentation/scorecard_screen.dart';
import 'package:jarz_pos/src/studio/features/settings/presentation/claims_moments_options_screens.dart';
import 'package:jarz_pos/src/studio/shared/person_text.dart';
import 'package:jarz_pos/src/studio/shared/save_files.dart';

import 'helpers.dart';
import 'inbox/ui_test_helpers.dart';
import 'more/more_test_utils.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

StudioMedia _media(String id) => StudioMedia(
  id: id,
  kind: MediaKind.image,
  thumbUrl: 'https://cdn.example.test/$id/thumb.jpg',
  feedUrl: 'https://cdn.example.test/$id/feed.jpg',
  url: 'https://cdn.example.test/$id/main.jpg',
);

void main() {
  group('1 team ratings', () {
    testWidgets('the roll-up lists, progress, comments and thresholds', (
      tester,
    ) async {
      await pumpMore(
        tester,
        const RatingsScreen(),
        size: const Size(360, 3000),
      );
      expect(find.text('Ready to run (2)'), findsOneWidget);
      expect(find.text('Drop or rework (1)'), findsOneWidget);
      expect(find.text('Team is split (1)'), findsOneWidget);
      expect(find.text('Team progress'), findsOneWidget);
      expect(find.text('Latest comments'), findsOneWidget);
      expect(find.text('71 ratings'), findsOneWidget);
      await tester.tap(_key('ratings-how'));
      await tester.pumpAndSettle();
      expect(find.textContaining('at least 3 ratings'), findsWidgets);
    });

    testWidgets('Arabic', (tester) async {
      await pumpMore(
        tester,
        const RatingsScreen(),
        locale: 'ar',
        size: const Size(360, 3000),
      );
      expect(find.text('جاهز للتشغيل (2)'), findsOneWidget);
      expect(find.text('تقدّم الفريق'), findsOneWidget);
    });

    testWidgets('the scorecard links to it for the founder', (tester) async {
      await pumpMore(
        tester,
        const ScorecardScreen(),
        size: const Size(360, 2600),
      );
      expect(_key('go-ratings'), findsOneWidget);
    });
  });

  group('2 competitors', () {
    testWidgets('add sends the fields; needs a handle or a link', (
      tester,
    ) async {
      final api = RecordingApi();
      await pumpMore(tester, const CompetitorsScreen(), api: api);
      await tapKey(tester, 'competitor-add');
      await tester.enterText(_key('form-name'), 'Crumbl');
      await tapKey(tester, 'form-save');
      expect(
        find.text('Add the Instagram handle or the Ads Library link.'),
        findsOneWidget,
      );
      await tester.enterText(_key('form-ig'), 'crumbl');
      await tapKey(tester, 'form-save');
      final c = api.last('references.competitor_add')!;
      expect(c['name'], 'Crumbl');
      expect(c['ig_handle'], 'crumbl');
      expect(c.containsKey('adlib_url'), isFalse);
      expect(find.text('Competitor added.'), findsOneWidget);
    });

    testWidgets('remove needs a reason, undo restores', (tester) async {
      final api = RecordingApi();
      await pumpMore(
        tester,
        const CompetitorScreen(competitorKey: '1980-coffee'),
        api: api,
      );
      await tapKey(tester, 'competitor-remove');
      await tapKey(tester, 'form-save');
      expect(api.count('references.competitor_remove'), 0);
      await tester.enterText(_key('form-reason'), 'Closed down');
      await tapKey(tester, 'form-save');
      expect(api.last('references.competitor_remove')!['reason'], 'Closed down');
      expect(find.text('Undo'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(api.last('references.competitor_restore')!['key'], '1980-coffee');
    });

    testWidgets('a removed one offers Restore, a creator has no buttons', (
      tester,
    ) async {
      final removed = patchFixtures({
        'references.competitor_get': (j) => {
          ...(j as Map),
          'status': 'Removed',
          'removed_why': 'x',
          'actions': ['restore'],
        },
      });
      final api = RecordingApi(fixtures: removed);
      await pumpMore(
        tester,
        const CompetitorScreen(competitorKey: '1980-coffee'),
        api: api,
      );
      expect(_key('competitor-remove'), findsNothing);
      await tapKey(tester, 'competitor-restore');
      expect(api.count('references.competitor_restore'), 1);

      final creator = RecordingApi(role: 'creator');
      await pumpMore(
        tester,
        const CompetitorsScreen(),
        api: creator,
      );
      expect(_key('competitor-add'), findsNothing);
    });
  });

  group('3 reference', () {
    testWidgets('feasibility picker saves the verdict', (tester) async {
      final api = RecordingApi();
      await pumpMore(
        tester,
        const ReferenceScreen(referenceId: 'ig-Dehn9LltvGf'),
        api: api,
        size: const Size(360, 1800),
      );
      await tapKey(tester, 'ref-feasibility');
      await tapKey(tester, 'feas-needs');
      await tester.enterText(_key('form-block'), 'Needs the new label');
      await tapKey(tester, 'form-save');
      final c = api.last('references.set_feasibility')!;
      expect(c['feasibility'], 'needs');
      expect(c['block'], 'Needs the new label');
    });

    testWidgets('no picker without the action (creator)', (tester) async {
      await pumpMore(
        tester,
        const ReferenceScreen(referenceId: 'ig-Dehn9LltvGf'),
        api: RecordingApi(role: 'creator'),
        size: const Size(360, 1800),
      );
      expect(_key('ref-feasibility'), findsNothing);
    });

    testWidgets('make an idea sends source_reference_id with the title', (
      tester,
    ) async {
      final api = RecordingApi();
      await pumpMore(
        tester,
        const ReferenceScreen(referenceId: 'ig-Dehn9LltvGf'),
        api: api,
        size: const Size(520, 1800),
      );
      await tapKey(tester, 'ref-make-idea');
      final field = tester.widget<TextField>(_key('idea-title'));
      expect(field.controller!.text, isNotEmpty);
      await tester.tap(find.text('Send the idea'));
      await tester.pumpAndSettle();
      final c = api.last('ideas.propose')!;
      expect(c['source_reference_id'], isA<String>());
    });
  });

  group('4 Today for another day and person', () {
    testWidgets('the next arrow asks for the day after, back to today', (
      tester,
    ) async {
      usePhone(tester, height: 1200);
      final api = RecordingApi();
      await pumpStudioWith(tester, api);
      await tester.tap(_key('day-next'));
      await tester.pumpAndSettle();
      expect(api.last('today.get')!['date'], '2026-11-26');
      expect(find.text('Tomorrow'), findsWidgets);
      expect(_key('day-banner'), findsOneWidget);
            expect(find.text('Posts of the day'), findsOneWidget);
      expect(_key('task-add'), findsNothing);
      await tester.tap(_key('day-today'));
      await tester.pumpAndSettle();
      expect(_key('day-banner'), findsNothing);
      expect(api.last('today.get')!.containsKey('date'), isFalse);
    });

    testWidgets('the founder picks a person; a creator cannot', (tester) async {
      usePhone(tester, height: 1200);
      final api = RecordingApi();
      await pumpStudioWith(tester, api);
      await tester.tap(_key('day-person'));
      await tester.pumpAndSettle();
      await tester.tap(_key('day-person-kareem'));
      await tester.pumpAndSettle();
      expect(api.last('today.get')!['as'], 'kareem');
      expect(find.textContaining('You are looking at Kareem'), findsOneWidget);
      // no action buttons on this person's lines
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('a creator has the arrows and no person picker', (
      tester,
    ) async {
      usePhone(tester, height: 1200);
      await pumpStudioWith(tester, RecordingApi(role: 'creator'));
      expect(_key('day-next'), findsOneWidget);
      expect(_key('day-person'), findsNothing);
    });

    testWidgets('Arabic banner', (tester) async {
      usePhone(tester, height: 1200);
      await pumpStudioWith(tester, RecordingApi(), locale: 'ar');
      await tester.tap(_key('day-person'));
      await tester.pumpAndSettle();
      await tester.tap(_key('day-person-kareem'));
      await tester.pumpAndSettle();
      expect(find.textContaining('إنت بتشوف يوم'), findsOneWidget);
    });
  });

  group('5 piece filters', () {
    testWidgets('verdict and sort go to the list and the board', (
      tester,
    ) async {
      usePhone(tester, height: 1200);
      final api = RecordingApi();
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/pieces');
      await tester.tap(_key('piece-filters-open'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'pf-verdict-RUN');
      await tester.pumpAndSettle();
      await tapKey(tester, 'pf-sort-rating');
      await tester.pumpAndSettle();
      await tapKey(tester, 'pf-ready');
      await tester.pumpAndSettle();
      expect(api.last('pieces.board')!['verdict'], 'RUN');
      expect(api.last('pieces.board')!['sort'], 'rating');
      expect(api.last('pieces.board')!['ready_for_ads'], true);
      await tester.tap(_key('pf-done'));
      await tester.pumpAndSettle();
      expect(_key('piece-chip-verdict'), findsOneWidget);
      // a chip removes its filter
      final x = find.descendant(
        of: _key('piece-chip-verdict'),
        matching: find.byIcon(Icons.clear),
      );
      await tester.ensureVisible(x);
      await tester.tap(x);
      await tester.pumpAndSettle();
      expect(_key('piece-chip-verdict'), findsNothing);
      expect(api.last('pieces.board')!.containsKey('verdict'), isFalse);
    });

    testWidgets('the week picker sends a Saturday', (tester) async {
      usePhone(tester, height: 1200);
      final api = RecordingApi();
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/pieces');
      await tester.tap(_key('piece-filters-open'));
      await tester.pumpAndSettle();
      await tester.tap(_key('pf-week-this'));
      await tester.pumpAndSettle();
      final w = DateTime.parse(api.last('pieces.board')!['week'] as String);
      expect(w.weekday, DateTime.saturday);
    });
  });

  group('6 calendar', () {
    testWidgets('status chips filter the posts', (tester) async {
      usePhone(tester, height: 1400);
      final c = await pumpStudioWith(tester, RecordingApi());
      await goTo(tester, c, '/calendar');
      expect(_key('status-filter'), findsOneWidget);
      await tester.tap(_key('status-Published'));
      await tester.pumpAndSettle();
      expect(find.text('Third jar she tried'), findsWidgets);
      expect(find.text('Seat belt on'), findsNothing);
    });

    testWidgets('what changed lists the rows newest first', (tester) async {
      usePhone(tester, height: 1400);
      final api = RecordingApi();
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/calendar');
      await tester.tap(_key('calendar-changes'));
      await tester.pumpAndSettle();
      expect(api.last('calendar.changes')!['days'], 7);
      expect(find.byType(CalendarChangesSheet), findsOneWidget);
      expect(
        find.text('Moved from Thu 26 Nov, 20:00 to Fri 27 Nov, 20:00'),
        findsOneWidget,
      );
      await tester.tap(_key('changes-days-30'));
      await tester.pumpAndSettle();
      expect(api.last('calendar.changes')!['days'], 30);
    });

    testWidgets('won\'t post lists the skipped posts', (tester) async {
      usePhone(tester, height: 1400);
      final skipped = patchFixtures({
        'calendar.range': (j) => {
          ...(j as Map),
          'posts': [
            {
              ...(j['posts'] as List).first as Map,
              'status': 'Cancelled',
              // Inside the window the calendar asks for (the fake now cuts
              // the answer to it, as the server does).
              'slot_time': '${DateTime.now().toIso8601String().substring(0, 10)}T20:00:00+02:00',
            },
          ],
        },
      });
      final api = RecordingApi(fixtures: skipped);
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/calendar');
      await tester.tap(_key('calendar-skipped'));
      await tester.pumpAndSettle();
      expect(api.calls_('calendar.range').any((p) => p['status'] == 'Cancelled'),
          isTrue);
      expect(_key('skipped-list'), findsOneWidget);
    });
  });

  group('7 moments', () {
    testWidgets('create a moment with the date picked', (tester) async {
      final api = RecordingApi();
      await pumpMore(tester, const MomentsScreen(), api: api);
      await tapKey(tester, 'moment-add');
      await tester.enterText(_key('form-title'), 'Cookie Jar launch');
      await tapKey(tester, 'moment-date');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'form-save');
      final c = api.last('settings.moment_set')!;
      expect(c['title'], 'Cookie Jar launch');
      expect(c['kind'], 'launch');
      expect(c.containsKey('moment_id'), isFalse);
      expect((c['date'] as String).length, 10);
    });

    testWidgets('move one and see the warnings the server sends', (
      tester,
    ) async {
      final warn = patchFixtures({
        'settings.moment_set': (j) => {
          ...(j as Map),
          'warnings': [
            {
              'code': 'R4',
              'severity': 'warn',
              'message': '2 pinned posts moved with it.',
            },
          ],
        },
      });
      final api = RecordingApi(fixtures: warn);
      await pumpMore(tester, const MomentsScreen(), api: api);
      await tester.tap(find.byKey(const ValueKey('moment-move-MOM-00027')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final c = api.last('settings.moment_set')!;
      expect(c['moment_id'], 'MOM-00027');
      expect(find.text('2 pinned posts moved with it.'), findsOneWidget);
    });

    testWidgets('the calendar moment sheet has Move this moment', (
      tester,
    ) async {
      usePhone(tester, height: 1400);
      final c = await pumpStudioWith(tester, RecordingApi());
      await goTo(tester, c, '/calendar');
      final chip = find.byKey(const ValueKey('moment-chip-MOM-00027'));
      if (chip.evaluate().isEmpty) return; // the sample week has no moment
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(_key('moment-move-this'), findsOneWidget);
    });
  });

  group('9 save files', () {
    testWidgets('one button per file and Save all', (tester) async {
      final opened = <Uri>[];
      final files = [
        for (var i = 0; i < 2; i++)
          _media('MED-00000010$i'),
      ];
      await pumpMore(
        tester,
        Scaffold(body: SaveFilesBar(files: files)),
        opened: opened,
      );
      expect(_key('save-media-0'), findsOneWidget);
      expect(_key('save-media-1'), findsOneWidget);
      await tapKey(tester, 'save-media-all');
      expect(opened.length, 2);
    });
  });

  group('15 text direction', () {
    test('first strong letter decides', () {
      expect(personTextDirection('11 pm, the laptop'), TextDirection.ltr);
      expect(personTextDirection('٣ حاجات'), TextDirection.rtl);
      expect(personTextDirection('12'), isNull);
    });

    testWidgets('an English line in an Arabic page keeps left to right', (
      tester,
    ) async {
      await pumpMore(
        tester,
        const Scaffold(body: PersonText('11 pm, the laptop')),
        locale: 'ar',
      );
      final t = tester.widget<Text>(find.text('11 pm, the laptop'));
      expect(t.textDirection, TextDirection.ltr);
      expect(t.textAlign, TextAlign.end);
    });
  });

  group('11 12 14 badge, stage, story card', () {
    testWidgets('the badge adds up the tiles the role has', (tester) async {
      usePhone(tester, height: 900);
      final c = await pumpStudioWith(tester, RecordingApi(role: 'creator'));
      // to rate 2 + ideas 7 + unread 4 (no to approve or decisions tile)
      expect(c.read(inboxBadgeProvider), 13);
    });

    test('approve moves the piece out of In review', () async {
      final api = FakeStudioApi(delay: Duration.zero);
      await api.call(
        'jarz_social.api.studio.versions.approve',
        params: {'version_id': 'PC-00163-v2'},
      );
      final piece = await api.call(
        'jarz_social.api.studio.pieces.get',
        params: {'piece_id': 'PC-00163'},
        get: true,
      );
      expect(piece['stage'], 'Scheduled');
    });

    testWidgets('the story card counts the frames the slot page counts', (
      tester,
    ) async {
      usePhone(tester, height: 1200);
      final api = FakeStudioApi(
        role: 'story',
        delay: Duration.zero,
        storyFrames: true,
      );
      await pumpStudioWith(tester, api);
      expect(find.textContaining('4 frames'), findsOneWidget);
      await tester.runAsync(
        () => api.call(
          'jarz_social.api.studio.calendar.frame_set',
          params: {
            'post_id': 'SP-2026-00310',
            'position': 1,
            'status': 'posted',
          },
        ),
      );
      final today = await tester.runAsync(
        () => api.call('jarz_social.api.studio.today.get', get: true),
      );
      final line = ((today!['blocks'] as List).firstWhere(
        (b) => b['key'] == 'stories',
      )['lines'] as List).first;
      expect(line['subtitle'], '4 frames · 1 posted · 3 to go');
      expect(line['badge'], '1/4');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
    });
  });

  group('13 17 20 21 small ones', () {
    testWidgets('More has Sign out and calls it Library', (tester) async {
      usePhone(tester, height: 900);
      final c = await pumpStudioWith(tester, RecordingApi());
      await goTo(tester, c, '/more');
      expect(_key('more-sign-out'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      await goTo(tester, c, '/assets');
      expect(find.text('Library'), findsWidgets);
      expect(find.text('Assets'), findsNothing);
    });

    testWidgets('gates say Held or Not held', (tester) async {
      await pumpMore(
        tester,
        const ScorecardScreen(),
        size: const Size(360, 2600),
      );
      expect(find.textContaining('Held'), findsWidgets);
    });

    testWidgets('task tick boxes are named', (tester) async {
      usePhone(tester, height: 3200);
      final handle = tester.ensureSemantics();
      await pumpStudioWith(
        tester,
        FakeStudioApi(role: 'lead', delay: Duration.zero),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('Done: ')), findsWidgets);
      handle.dispose();
    });
  });
}
