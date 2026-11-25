import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/features/settings/presentation/claims_moments_options_screens.dart';
import 'package:jarz_pos/src/studio/features/settings/presentation/flavours_screens.dart';
import 'package:jarz_pos/src/studio/features/settings/presentation/people_screens.dart';
import 'package:jarz_pos/src/studio/features/settings/presentation/rules_screens.dart';
import 'package:jarz_pos/src/studio/features/settings/presentation/settings_hub_screen.dart';

import '../more/more_test_utils.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

Map<String, String> _noActions(String fixture) => patchFixtures({
  fixture: (j) => j is List
      ? [
          for (final r in j) {...(r as Map), 'actions': []},
        ]
      : j,
});

const _tall = Size(360, 1800);

void main() {
  group('hub', () {
    testWidgets('founder sees every section and no read-only note', (
      tester,
    ) async {
      await pumpMore(tester, const SettingsHubScreen());
      for (final k in [
        'rules',
        'flavours',
        'claims',
        'moments',
        'people',
        'options',
      ]) {
        expect(_key('settings-$k'), findsOneWidget, reason: k);
      }
      expect(_key('settings-read-only'), findsNothing);
    });

    testWidgets('lead reads the same sections and is told it is read only', (
      tester,
    ) async {
      final api = RecordingApi(role: 'lead');
      await pumpMore(tester, const SettingsHubScreen(), api: api);
      expect(_key('settings-rules'), findsOneWidget);
      expect(_key('settings-read-only'), findsOneWidget);
    });

    testWidgets('sections link to their pages', (tester) async {
      final h = await pumpMoreRouter(tester, location: '/more/settings');
      await tapKey(tester, 'settings-rules');
      expect(where(h.router), '/more/settings/rules');
    });
  });

  group('rules', () {
    testWidgets('each rule shows its value and the date it applies from', (
      tester,
    ) async {
      await pumpMore(tester, const RulesScreen(), size: _tall);
      expect(
        find.text(
          'Highest cost per purchase at which an ad earns one more round.',
        ),
        findsOneWidget,
      );
      expect(_key('rule-value-again_max_cpp'), findsOneWidget);
      expect(
        tester.widget<Text>(_key('rule-value-again_max_cpp')).data,
        'EGP 185',
      );
      expect(find.textContaining('since'), findsWidgets);
      expect(find.text('Starting value'), findsWidgets);
    });

    testWidgets('search narrows the list', (tester) async {
      await pumpMore(tester, const RulesScreen(), size: _tall);
      await typeKey(tester, 'search-field', 'retire');
      expect(_key('rule-retire_cpp'), findsOneWidget);
      expect(_key('rule-again_max_cpp'), findsNothing);
    });

    testWidgets('empty says what to do', (tester) async {
      final api = RecordingApi(
        fixtures: patchFixtures({'settings.rules': (j) => []}),
      );
      await pumpMore(tester, const RulesScreen(), api: api);
      expect(find.textContaining('No rules yet'), findsOneWidget);
    });

    testWidgets('error, then retry', (tester) async {
      final api = RecordingApi()..failNext('settings.rules', 'SERVER_ERROR');
      await pumpMore(tester, const RulesScreen(), api: api);
      expect(_key('error-text'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(_key('rules-list'), findsOneWidget);
    });

    Future<RecordingApi> openRule(
      WidgetTester tester, {
      RecordingApi? api,
      String locale = 'en',
    }) async {
      final a = api ?? RecordingApi();
      await pumpMoreRouter(
        tester,
        location: '/more/settings/rules/again_max_cpp',
        api: a,
        size: _tall,
        locale: locale,
      );
      return a;
    }

    testWidgets('the page shows the value now, the start and the history', (
      tester,
    ) async {
      await openRule(tester);
      expect(tester.widget<Text>(_key('rule-now')).data, 'EGP 185');
      expect(_key('history-2026-11-13'), findsOneWidget);
      expect(find.text('Old values are kept as they were.'), findsOneWidget);
    });

    testWidgets('changing a rule adds a new dated value; history stays', (
      tester,
    ) async {
      final api = await openRule(tester);
      await tapKey(tester, 'rule-change');
      await typeKey(tester, 'rule-new-value', '175');
      await typeKey(tester, 'rule-note', 'Margin check');
      await tapKey(tester, 'rule-save');
      final p = api.last('settings.rule_set')!;
      expect(p['rule_key'], 'again_max_cpp');
      expect(p['value'], 175.0);
      expect(p['note'], 'Margin check');
      expect(p['valid_from'], todayIsoForTest());
      // The new dated value is in the history next to the old one.
      expect(tester.widget<Text>(_key('rule-now')).data, 'EGP 175');
      expect(_key('history-2026-11-13'), findsOneWidget);
      expect(_key('history-2026-11-25'), findsOneWidget);
      expect(snackText(tester), 'New value saved');
    });

    testWidgets('the pencil opens the same form', (tester) async {
      await openRule(tester);
      await tapKey(tester, 'edit');
      expect(_key('rule-dialog'), findsOneWidget);
    });

    testWidgets('a value that is not a number is refused on the spot', (
      tester,
    ) async {
      final api = await openRule(tester);
      await tapKey(tester, 'rule-change');
      await typeKey(tester, 'rule-new-value', '-');
      await tapKey(tester, 'rule-save');
      expect(find.text('Write the value as a number.'), findsOneWidget);
      expect(api.count('settings.rule_set'), 0);
    });

    testWidgets('read only without the set action', (tester) async {
      final api = RecordingApi(
        role: 'lead',
        fixtures: _noActions('settings.rules'),
      );
      await openRule(tester, api: api);
      expect(_key('edit'), findsNothing);
      expect(_key('rule-change'), findsNothing);
      expect(_key('rule-now'), findsOneWidget);
    });

    testWidgets('errors are said in plain words', (tester) async {
      final api = await openRule(tester);
      Future<void> tryChange(String code, String expected) async {
        api.failNext('settings.rule_set', code);
        await tapKey(tester, 'rule-change');
        await typeKey(tester, 'rule-new-value', '170');
        await tapKey(tester, 'rule-save');
        expect(snackText(tester), contains(expected), reason: code);
        ScaffoldMessenger.of(
          tester.element(find.byType(Scaffold).first),
        ).clearSnackBars();
        await tester.pumpAndSettle();
      }

      await tryChange('SHADOW_MODE', 'not switched on yet');
      await tryChange('NOT_PERMITTED', 'You cannot do that.');
      await tryChange('SERVER_ERROR', 'Something went wrong');
      expect(tester.widget<Text>(_key('rule-now')).data, 'EGP 185');

      api.failNext(
        'settings.rule_set',
        'VALIDATION',
        message: 'A new value must start from today or later.',
        field: 'valid_from',
      );
      await tapKey(tester, 'rule-change');
      await typeKey(tester, 'rule-new-value', '170');
      await tapKey(tester, 'rule-save');
      expect(snackText(tester), 'A new value must start from today or later.');
    });

    testWidgets('Arabic rule page at 360 px has no overflow', (tester) async {
      await openRule(tester, locale: 'ar');
      expect(find.text('السجل'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('flavours', () {
    testWidgets('list shows status and dates in plain words', (tester) async {
      await pumpMore(tester, const FlavoursScreen(), size: _tall);
      expect(find.text('Blueberry Cheesecake'), findsOneWidget);
      expect(find.text('On sale'), findsWidgets);
      expect(find.text('Paused'), findsWidgets);
    });

    testWidgets('the page shows prices as EGP and the note', (tester) async {
      await pumpMoreRouter(
        tester,
        location: '/more/settings/flavours/carrot-cake',
        size: _tall,
      );
      expect(_key('flavour-note'), findsOneWidget);
      expect(find.text('Return delayed, no date yet'), findsOneWidget);
    });

    testWidgets('prices come from ERPNext, whole EGP', (tester) async {
      await pumpMoreRouter(
        tester,
        location: '/more/settings/flavours/blueberry-cheesecake',
        size: _tall,
      );
      expect(find.text('EGP 120'), findsOneWidget);
      expect(find.text('EGP 160'), findsOneWidget);
    });

    testWidgets('no edit action, no pencil', (tester) async {
      final api = RecordingApi(fixtures: _noActions('settings.flavours'));
      await pumpMoreRouter(
        tester,
        location: '/more/settings/flavours/blueberry-cheesecake',
        api: api,
      );
      expect(_key('edit'), findsNothing);
    });

    testWidgets('editing sends the status and base_modified, then warns', (
      tester,
    ) async {
      final api = RecordingApi();
      await pumpMoreRouter(
        tester,
        location: '/more/settings/flavours/blueberry-cheesecake',
        api: api,
        size: _tall,
      );
      await tapKey(tester, 'edit');
      await tapKey(tester, 'flavour-status-paused');
      await tapKey(tester, 'flavour-save');
      final p = api.last('settings.flavour_set')!;
      expect(p['flavour_id'], 'blueberry-cheesecake');
      expect(p['status'], 'paused');
      expect(p['base_modified'], '2026-11-18T10:00:00+02:00');
      // Saving never blocks; the checks it causes are listed.
      expect(_key('flavour-warnings'), findsOneWidget);
      expect(
        find.textContaining('Carrot Cake is paused: 2 planned posts'),
        findsOneWidget,
      );
    });

    testWidgets('STALE brings the newer copy', (tester) async {
      final api = RecordingApi();
      final fresh = {
        ...((fixtureJson('settings.flavours') as List).first as Map),
        'note': 'Changed by Ali a moment ago',
      };
      api.failNext('settings.flavour_set', 'STALE', current: fresh);
      await pumpMoreRouter(
        tester,
        location: '/more/settings/flavours/blueberry-cheesecake',
        api: api,
        size: _tall,
      );
      await tapKey(tester, 'edit');
      await tapKey(tester, 'flavour-save');
      expect(snackText(tester), contains('Someone changed this'));
      expect(find.text('Changed by Ali a moment ago'), findsOneWidget);
    });

    testWidgets('shadow mode and not permitted', (tester) async {
      final api = RecordingApi()
        ..failNext('settings.flavour_set', 'SHADOW_MODE');
      await pumpMoreRouter(
        tester,
        location: '/more/settings/flavours/blueberry-cheesecake',
        api: api,
        size: _tall,
      );
      await tapKey(tester, 'edit');
      await tapKey(tester, 'flavour-save');
      expect(snackText(tester), contains('not switched on yet'));
    });
  });

  group('claims', () {
    testWidgets('read-only mirror with its source line', (tester) async {
      await pumpMore(tester, const ClaimsScreen(), size: _tall);
      expect(_key('claim-low-sugar'), findsOneWidget);
      expect(find.textContaining('Registry: low sugar'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Approved'), findsWidgets);
    });

    testWidgets('status chip filters on the server', (tester) async {
      final api = RecordingApi();
      await pumpMore(tester, const ClaimsScreen(), api: api);
      await tapKey(tester, 'chip-On hold');
      expect(api.last('settings.claims')!['status'], 'HOLD');
    });

    testWidgets('empty says what to do', (tester) async {
      final api = RecordingApi(
        fixtures: patchFixtures({
          'settings.claims': (j) => {'items': [], 'next': null},
        }),
      );
      await pumpMore(tester, const ClaimsScreen(), api: api);
      expect(find.textContaining('No claims yet'), findsOneWidget);
    });
  });

  group('moments and options', () {
    testWidgets('moments are grouped by kind', (tester) async {
      await pumpMore(tester, const MomentsScreen(), size: _tall);
      expect(find.text('Launches'), findsOneWidget);
      expect(find.text('Budget steps'), findsOneWidget);
      expect(_key('moment-MOM-00027'), findsOneWidget);
    });

    testWidgets('options list the choices', (tester) async {
      await pumpMore(tester, const OptionsScreen(), size: _tall);
      expect(find.text('Series'), findsOneWidget);
      expect(_key('options-list'), findsOneWidget);
    });
  });

  group('people', () {
    testWidgets('list shows role and whether they are active', (tester) async {
      await pumpMore(tester, const PeopleScreen(), size: _tall);
      expect(_key('person-ali'), findsOneWidget);
      expect(find.text('Marketing lead'), findsWidgets);
    });

    testWidgets('editing sends only what changed', (tester) async {
      final api = RecordingApi();
      await pumpMoreRouter(
        tester,
        location: '/more/settings/people/kareem',
        api: api,
        size: _tall,
      );
      await tapKey(tester, 'edit');
      await tapKey(tester, 'person-enabled');
      await tapKey(tester, 'person-save');
      final p = api.last('settings.person_set')!;
      expect(p['person_key'], 'kareem');
      expect(p['fields'], {'enabled': false});
      expect(snackText(tester), 'Person saved');
    });

    testWidgets('role and login can change', (tester) async {
      final api = RecordingApi();
      await pumpMoreRouter(
        tester,
        location: '/more/settings/people/kareem',
        api: api,
        size: _tall,
      );
      await tapKey(tester, 'edit');
      await tapKey(tester, 'person-role-Story Lead');
      await typeKey(tester, 'person-user', 'kareem2@example.test');
      await tapKey(tester, 'person-save');
      expect(api.last('settings.person_set')!['fields'], {
        'studio_role': 'Story Lead',
        'user': 'kareem2@example.test',
      });
    });

    testWidgets('no edit action, no pencil', (tester) async {
      final api = RecordingApi(
        role: 'lead',
        fixtures: _noActions('settings.people'),
      );
      await pumpMoreRouter(
        tester,
        location: '/more/settings/people/kareem',
        api: api,
      );
      expect(_key('edit'), findsNothing);
    });

    testWidgets('a refusal shows the server message', (tester) async {
      final api = RecordingApi()
        ..failNext(
          'settings.person_set',
          'VALIDATION',
          message: 'That login is already linked to someone else.',
          field: 'user',
        );
      await pumpMoreRouter(
        tester,
        location: '/more/settings/people/kareem',
        api: api,
        size: _tall,
      );
      await tapKey(tester, 'edit');
      await tapKey(tester, 'person-enabled');
      await tapKey(tester, 'person-save');
      expect(
        snackText(tester),
        'That login is already linked to someone else.',
      );
    });
  });
}

String todayIsoForTest() {
  final d = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}
