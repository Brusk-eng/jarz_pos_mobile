// "Repeat every {weekday}" (Feature: roster-repeat-weekly): the
// `apply_weekly_change` wire shapes, the repository call, and the day sheet's
// switch -> preview -> replace -> apply flow against a fake repository.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/roster/data/roster_repository.dart';
import 'package:jarz_pos/src/features/roster/models/roster_models.dart';
import 'package:jarz_pos/src/features/roster/models/roster_weekly_models.dart';
import 'package:jarz_pos/src/features/roster/presentation/widgets/roster_day_off_form.dart'
    show rosterDayOffSaveKey;
import 'package:jarz_pos/src/features/roster/presentation/widgets/roster_day_sheet.dart';
import 'package:jarz_pos/src/features/roster/presentation/widgets/roster_weekly_review.dart';
import 'package:jarz_pos/src/features/roster/state/roster_providers.dart';

import '../../helpers/mock_services.dart';

const _ali = 'HR-EMP-00001';

/// A Sunday far enough ahead that "today or later" always holds.
const _sunday = '2030-01-06';

Map<String, dynamic> _contract({bool dryRun = true, bool replace = false}) => {
  'success': true,
  'dry_run': dryRun,
  'applied': !dryRun,
  'employee': _ali,
  'employee_name': 'Ali',
  'action': 'assign',
  'weekday': 'Sunday',
  'start': _sunday,
  'through': '2030-03-10',
  'rota_from': '2030-03-12',
  'change_count': 10,
  'dates': ['2030-01-06', '2030-01-13'],
  'replace_manual': replace,
  'kept': replace
      ? []
      : [
          {
            'date': '2030-01-20',
            'employee': _ali,
            'employee_name': 'Ali',
            'kind': 'day_off',
            'current': 'Off',
          },
          {
            'date': '2030-01-13',
            'employee': _ali,
            'employee_name': 'Ali',
            'kind': 'shift',
            'current': 'Branch Opening',
          },
          {
            'date': '2030-01-27',
            'employee': 'HR-EMP-00002',
            'employee_name': 'Omar',
            'kind': 'cover',
            'current': 'Covering Hassan',
          },
        ],
  'kept_count': replace ? 0 : 3,
  'warnings': [
    {
      'code': 'branch_short',
      'employee': _ali,
      'dates': ['2030-01-06'],
      'message': 'Nasr City has nobody on the evening shift',
    },
  ],
  'standing': [
    {
      'employee': _ali,
      'employee_name': 'Ali',
      'weekday': 'Sunday',
      'before': 'Branch Opening @ Nasr City',
      'after': 'Branch Closing @ Dokki',
    },
  ],
  'touched_outside': [],
};

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({'message': _contract()}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeRosterRepository extends RosterRepository {
  _FakeRosterRepository() : super(MockDio());

  final List<({Map<String, dynamic> payload, bool dryRun})> calls = [];

  /// When set, the next call fails with this Frappe error body.
  Map<String, dynamic>? failWith;

  @override
  Future<RosterWeeklyResult> applyWeeklyChange(
    RosterWeeklyChange change, {
    required bool dryRun,
  }) async {
    calls.add((payload: change.toPayload(), dryRun: dryRun));
    final body = failWith;
    if (body != null) {
      final options = RequestOptions(path: '/api/method/x');
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 417,
          data: body,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return RosterWeeklyResult.fromJson(
      _contract(dryRun: dryRun, replace: change.replaceManual),
    );
  }
}

RosterShift _shift(String name) => RosterShift.fromJson({
  'shift_type': name,
  'start_time': '09:00:00',
  'end_time': '18:00:00',
  'hours': 9,
});

RosterBootstrap _bootstrap() => RosterBootstrap.fromJson({
  'hrms_available': true,
  'shift_catalog': [
    {
      'shift_type': 'Branch Opening',
      'start_time': '09:00:00',
      'end_time': '18:00:00',
      'hours': 9,
    },
  ],
  'shift_locations': [
    {
      'shift_location': 'Nasr City',
      'pos_profile': 'Nasr City',
      'pos_manageable': true,
    },
    {'shift_location': 'Dokki'},
  ],
  'scope': {'configured': true, 'unrestricted': true},
});

Widget _app({
  required _FakeRosterRepository repo,
  Locale locale = const Locale('en'),
}) {
  final employee = RosterEmployee.fromJson({
    'employee': _ali,
    'employee_name': 'Ali',
    'shift_locations': ['Nasr City'],
    'days': {
      _sunday: {
        'date': _sunday,
        'shift_type': 'Branch Opening',
        'shift_location': 'Nasr City',
        'hours': 9,
      },
    },
  });
  return ProviderScope(
    overrides: [
      rosterRepositoryProvider.overrideWithValue(repo),
      rosterBootstrapProvider.overrideWith((ref) async => _bootstrap()),
      rosterMonthDataProvider.overrideWith(
        (ref) async => RosterMonth.fromJson({'employees': []}),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showRosterDaySheet(
                context,
                employee: employee,
                date: _sunday,
                cell: employee.cellFor(_sunday),
                catalog: [_shift('Branch Opening'), _shift('Branch Closing')],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('rosterWeekdayOf', () {
    test('maps ISO dates to the English names the backend speaks', () {
      expect(rosterWeekdayOf('2030-01-05'), 'Saturday');
      expect(rosterWeekdayOf('2030-01-06'), 'Sunday');
      expect(rosterWeekdayOf('2030-01-07'), 'Monday');
      expect(rosterWeekdayOf('2030-01-11'), 'Friday');
      expect(rosterWeekdayOf('not a date'), isNull);
    });

    test('only today or later may start a repeat', () {
      final now = DateTime(2026, 11, 3, 18, 30);
      expect(rosterCanRepeatFrom('2026-11-03', now: now), isTrue);
      expect(rosterCanRepeatFrom('2026-11-08', now: now), isTrue);
      expect(rosterCanRepeatFrom('2026-11-02', now: now), isFalse);
      expect(rosterCanRepeatFrom('', now: now), isFalse);
    });
  });

  group('RosterWeeklyChange.toPayload', () {
    test('assign carries shift and branch, never a POS grant', () {
      const change = RosterWeeklyChange.assign(
        employee: _ali,
        date: _sunday,
        shiftType: 'Branch Closing',
        shiftLocation: 'Dokki',
      );
      expect(change.toPayload(), {
        'employee': _ali,
        'date': _sunday,
        'action': 'assign',
        'shift_type': 'Branch Closing',
        'shift_location': 'Dokki',
        'replace_manual': false,
      });
      expect(change.weekday, 'Sunday');
      expect(
        change.copyWith(replaceManual: true).toPayload()['replace_manual'],
        isTrue,
      );
    });

    test('a blank branch is sent as null: the usual branch', () {
      const change = RosterWeeklyChange.assign(
        employee: _ali,
        date: _sunday,
        shiftType: 'Branch Closing',
        shiftLocation: ' ',
      );
      final payload = change.toPayload();
      expect(payload.containsKey('shift_location'), isTrue);
      expect(payload['shift_location'], isNull);
    });

    test('day off carries the cover; a cover shift needs a coverer', () {
      const withCover = RosterWeeklyChange.dayOff(
        employee: _ali,
        date: _sunday,
        offType: 'Weekly Off',
        coveredBy: 'HR-EMP-00002',
        coverShiftType: 'Branch Cover Full Day',
        notes: 'standing',
      );
      expect(withCover.toPayload(), {
        'employee': _ali,
        'date': _sunday,
        'action': 'day_off',
        'off_type': 'Weekly Off',
        'covered_by': 'HR-EMP-00002',
        'cover_shift_type': 'Branch Cover Full Day',
        'notes': 'standing',
        'replace_manual': false,
      });
      expect(withCover.copyWith(replaceManual: true).isDayOff, isTrue);

      const noCover = RosterWeeklyChange.dayOff(
        employee: _ali,
        date: _sunday,
        offType: 'Weekly Off',
        coverShiftType: 'Branch Cover Full Day',
      );
      final payload = noCover.toPayload();
      expect(payload['covered_by'], isNull);
      expect(payload['cover_shift_type'], isNull);
      expect(payload.containsKey('grant_pos_access'), isFalse);
    });
  });

  group('RosterWeeklyResult.fromJson', () {
    test('parses the contract shape', () {
      final result = RosterWeeklyResult.fromJson(_contract());
      expect(result.success, isTrue);
      expect(result.dryRun, isTrue);
      expect(result.applied, isFalse);
      expect(result.weekday, 'Sunday');
      expect(result.start, _sunday);
      expect(result.through, '2030-03-10');
      expect(result.rotaFrom, '2030-03-12');
      expect(result.changeCount, 10);
      expect(result.keptCount, 3);
      expect(result.warnings.single.message, contains('Nasr City'));
      expect(result.warnings.single.dates, ['2030-01-06']);
      final standing = result.standing.single;
      expect(standing.displayName, 'Ali');
      expect(standing.before, 'Branch Opening @ Nasr City');
      expect(standing.after, 'Branch Closing @ Dokki');

      // Grouped by person, first seen first, each list by date.
      final groups = result.keptByPerson;
      expect(groups.map((g) => g.key), ['Ali', 'Omar']);
      expect(groups.first.value.map((d) => d.date), [
        '2030-01-13',
        '2030-01-20',
      ]);
    });

    test('a partial body degrades instead of throwing', () {
      final result = RosterWeeklyResult.fromJson({
        'dates': ['2030-01-06', '2030-01-13'],
        'kept': [
          {'date': '2030-01-20', 'employee': _ali},
          'junk',
        ],
        'warnings': null,
      });
      expect(result.dryRun, isTrue);
      expect(result.applied, isFalse);
      expect(result.through, isNull);
      expect(result.changeCount, 2);
      expect(result.keptCount, 1);
      expect(result.kept.single.displayName, _ali);
      expect(result.warnings, isEmpty);
      expect(result.standing, isEmpty);
    });
  });

  test('repository sends the payload as JSON and dry_run both ways', () async {
    final adapter = _Adapter();
    final repository = RosterRepository(Dio()..httpClientAdapter = adapter);
    const change = RosterWeeklyChange.assign(
      employee: _ali,
      date: _sunday,
      shiftType: 'Branch Closing',
    );

    await repository.applyWeeklyChange(change, dryRun: true);
    await repository.applyWeeklyChange(change, dryRun: false);

    expect(adapter.requests, hasLength(2));
    for (final request in adapter.requests) {
      expect(request.path, contains('jarz_pos.api.roster.apply_weekly_change'));
      final data = request.data as Map;
      expect(jsonDecode(data['payload'] as String), change.toPayload());
    }
    expect((adapter.requests[0].data as Map)['dry_run'], 1);
    expect((adapter.requests[1].data as Map)['dry_run'], 0);
  });

  group('day sheet', () {
    void bigScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2700);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    testWidgets('switch off: a pick is a one-day write as before', (
      tester,
    ) async {
      bigScreen(tester);
      final repo = _FakeRosterRepository();
      await tester.pumpWidget(_app(repo: repo));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byKey(rosterRepeatWeeklyKey), findsOneWidget);
      expect(find.text('Repeat every Sunday'), findsOneWidget);
      // POS tick box is offered for the one-day edit (when within window);
      // the branch picker is not.
      expect(find.byKey(rosterRepeatBranchKey), findsNothing);
      expect(repo.calls, isEmpty);
    });

    testWidgets('switch on: preview, replace, apply', (tester) async {
      bigScreen(tester);
      final repo = _FakeRosterRepository();
      await tester.pumpWidget(_app(repo: repo));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(rosterRepeatWeeklyKey));
      await tester.pumpAndSettle();
      expect(find.byKey(rosterRepeatBranchKey), findsOneWidget);

      // The day's own shift stays tappable: repeating it is a real change.
      await tester.tap(find.text('Branch Opening'));
      await tester.pumpAndSettle();

      expect(repo.calls, hasLength(1));
      expect(repo.calls.single.dryRun, isTrue);
      expect(repo.calls.single.payload, {
        'employee': _ali,
        'date': _sunday,
        'action': 'assign',
        'shift_type': 'Branch Opening',
        'shift_location': null,
        'replace_manual': false,
      });

      expect(find.text('Check the weekly change'), findsOneWidget);
      expect(
        find.text(
          'Ali · Sunday: Branch Opening @ Nasr City → Branch Closing @ Dokki',
        ),
        findsOneWidget,
      );
      expect(
        find.text('10 Sundays from 6 Jan 2030 to 10 Mar 2030 will change.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'After 10 Mar 2030, the weekly rota carries it on (from 12 Mar 2030).',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Nasr City has nobody on the evening shift'),
        findsOneWidget,
      );
      final reviewList = find
          .descendant(
            of: find.byType(RosterWeeklyReviewSheet),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.textContaining('Covering Hassan'),
        100,
        scrollable: reviewList,
      );
      expect(find.text('Omar'), findsOneWidget);
      expect(find.textContaining('Covering Hassan'), findsOneWidget);

      await tester.ensureVisible(find.byKey(rosterWeeklyReplaceManualKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(rosterWeeklyReplaceManualKey));
      await tester.pumpAndSettle();
      expect(repo.calls, hasLength(2));
      expect(repo.calls.last.dryRun, isTrue);
      expect(repo.calls.last.payload['replace_manual'], isTrue);
      expect(find.text('Omar'), findsNothing);
      expect(find.text('These days will be changed too.'), findsOneWidget);

      await tester.tap(find.byKey(rosterWeeklyApplyKey));
      await tester.pumpAndSettle();
      expect(repo.calls, hasLength(3));
      expect(repo.calls.last.dryRun, isFalse);
      expect(repo.calls.last.payload, repo.calls[1].payload);

      // Both sheets closed; the confirmation shows.
      expect(find.text('Check the weekly change'), findsNothing);
      expect(find.byKey(rosterRepeatWeeklyKey), findsNothing);
      expect(find.textContaining('Saved: every Sunday from'), findsOneWidget);
    });

    testWidgets('switch on: a day off repeats without a POS grant', (
      tester,
    ) async {
      bigScreen(tester);
      final repo = _FakeRosterRepository();
      await tester.pumpWidget(_app(repo: repo));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(rosterRepeatWeeklyKey));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Mark day off'));
      await tester.tap(find.text('Mark day off'));
      await tester.pumpAndSettle();

      // The form's POS-access tick box is never offered for a repeat.
      expect(find.byType(PosAccessCheckbox), findsNothing);
      await tester.tap(find.byKey(rosterDayOffSaveKey));
      await tester.pumpAndSettle();

      expect(repo.calls, hasLength(1));
      expect(repo.calls.single.dryRun, isTrue);
      final payload = repo.calls.single.payload;
      expect(payload['action'], 'day_off');
      expect(payload['off_type'], 'Weekly Off');
      expect(payload['covered_by'], isNull);
      expect(payload.containsKey('grant_pos_access'), isFalse);
      expect(find.text('Check the weekly change'), findsOneWidget);
    });

    testWidgets('an English server refusal is shown on the Arabic screen', (
      tester,
    ) async {
      bigScreen(tester);
      final repo = _FakeRosterRepository()
        ..failWith = {
          'exc_type': 'ValidationError',
          '_server_messages': jsonEncode([
            jsonEncode({'message': 'Ali is not rostered at Dokki'}),
          ]),
        };
      await tester.pumpWidget(_app(repo: repo, locale: const Locale('ar')));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(rosterRepeatWeeklyKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Branch Closing'));
      await tester.pumpAndSettle();

      expect(find.text('مقدرناش نراجع التغيير.'), findsOneWidget);
      expect(find.text('Ali is not rostered at Dokki'), findsOneWidget);
      expect(find.byKey(rosterWeeklyRetryKey), findsOneWidget);
    });
  });
}
