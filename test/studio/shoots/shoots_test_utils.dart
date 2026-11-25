import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_strings.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/core/offline/kv_store.dart';
import 'package:jarz_pos/src/studio/core/offline/reachability.dart';
import 'package:jarz_pos/src/studio/core/theme/studio_theme.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';
import 'package:jarz_pos/src/studio/features/shoots/shoots_routes.dart';
import 'package:jarz_pos/src/studio/features/shoots/state/on_set_state.dart';
import 'package:jarz_pos/src/studio/features/shoots/state/shoot_list_state.dart';
import 'package:jarz_pos/src/studio/shared/media/studio_media_widgets.dart';

/// The contract's example shoot SHOOT-0006 (3 shots: 107 filmed, 108 and 109
/// not) behind a Studio API that can lose its connection and keeps its own
/// record of who ticked what and when, like the server does.
class ShootTestApi extends FakeStudioApi {
  ShootTestApi({super.role = 'founder'}) : super(delay: Duration.zero);

  bool offline = false;

  /// Hide every action (a person who may only look).
  bool noActions = false;

  /// What `shoots.shot_tick` was asked, call by call.
  final tickCalls = <List<Map<String, dynamic>>>[];
  final noteCalls = <({String shot, String note, String? base})>[];
  final prepCalls = <String>[];
  final shotSets = <Map<String, dynamic>>[];

  /// The server's own record: shot id -> (done, at). Seeded from the example.
  final serverDone = <String, ({bool done, String at})>{};

  /// Pieces reported as moved by the next tick call.
  List<PieceRef> movedNext = const [];

  /// Make the next `shot_note` answer STALE with this note on the server.
  String? staleNote;

  /// Replace the list the server answers `shoots.list` with.
  List<ShootSummary>? listItems;

  @override
  Future<dynamic> call(
    String method, {
    Map<String, dynamic>? params,
    bool get = false,
  }) async {
    if (offline) throw const StudioNetworkError('No connection.');
    return super.call(method, params: params, get: get);
  }

  Future<StudioShoot> _base() async {
    final s = await super.shootsGet(shootId: 'SHOOT-0006');
    final shots = [
      for (final shot in s.shots)
        shot.copyWith(
          done: serverDone[shot.id]?.done ?? shot.done,
          doneAt: serverDone[shot.id]?.at ?? shot.doneAt,
          actions: noActions ? const [] : shot.actions,
        ),
    ];
    return s.copyWith(
      shots: shots,
      nDone: shots.where((x) => x.done).length,
      actions: noActions ? const [] : s.actions,
      prep: [
        for (final p in s.prep) noActions ? p.copyWith(actions: const []) : p,
      ],
    );
  }

  @override
  Future<StudioShoot> shootsGet({required String shootId}) async {
    if (offline) throw const StudioNetworkError('No connection.');
    final s = await _base();
    return s.copyWith(id: shootId);
  }

  @override
  Future<StudioShootSync> shootsSync({
    String? modifiedSince,
    String? from,
    int? limit,
    String? after,
  }) async {
    if (offline) throw const StudioNetworkError('No connection.');
    return StudioShootSync(
      items: [await _base()],
      deleted: const [],
      serverTime: '2026-11-25T14:05:00+02:00',
    );
  }

  @override
  Future<ShootSummarySync> shootsList({
    String? status,
    String? from,
    String? to,
    bool? includeDone,
    int? limit,
    String? after,
    String? modifiedSince,
  }) async {
    if (offline) throw const StudioNetworkError('No connection.');
    if (listItems == null) {
      return super.shootsList(includeDone: includeDone, after: after);
    }
    return ShootSummarySync(
      items: listItems!,
      deleted: const [],
      serverTime: '2026-11-25T14:05:00+02:00',
    );
  }

  @override
  Future<ShotTickResult> shootsShotTick({required Object ticks}) async {
    if (offline) throw const StudioNetworkError('No connection.');
    final list = [
      for (final t in (ticks is String ? jsonDecode(ticks) : ticks) as List)
        Map<String, dynamic>.from(t as Map),
    ];
    tickCalls.add(list);
    final results = <TickItem>[];
    for (final t in list) {
      final id = t['shot_id'] as String;
      final at = t['at'] as String;
      final cur = serverDone[id];
      final newer =
          cur == null || DateTime.parse(at).isAfter(DateTime.parse(cur.at));
      if (newer) serverDone[id] = (done: t['done'] as bool, at: at);
      results.add(TickItem(shotId: id, ok: true));
    }
    final s = await _base();
    final moved = movedNext;
    movedNext = const [];
    return ShotTickResult(results: results, shots: s.shots, piecesMoved: moved);
  }

  @override
  Future<ShootShot> shootsShotNote({
    required String shotId,
    required String note,
    String? baseModified,
    String? requestId,
  }) async {
    if (offline) throw const StudioNetworkError('No connection.');
    noteCalls.add((shot: shotId, note: note, base: baseModified));
    final s = await _base();
    final shot = s.shots.firstWhere((x) => x.id == shotId);
    if (staleNote != null) {
      final server = shot.copyWith(
        note: staleNote,
        modified: '2026-11-25T15:00:00+02:00',
      );
      staleNote = null;
      throw StudioStale('changed', server.toJson());
    }
    return shot.copyWith(note: note, modified: '2026-11-25T15:30:00+02:00');
  }

  @override
  Future<StudioTask> shootsPrepTick({
    required String taskId,
    bool? done,
    String? requestId,
  }) async {
    if (offline) throw const StudioNetworkError('No connection.');
    prepCalls.add('$taskId:$done');
    final s = await _base();
    return s.prep
        .firstWhere((p) => p.id == taskId)
        .copyWith(done: done ?? true);
  }

  @override
  Future<ShootShot> shootsShotSet({
    required String shootId,
    String? shotId,
    String? what,
    String? setup,
    double? lenS,
    String? ar,
    String? en,
    Object? brief,
    Object? pieceIds,
    double? sortOrder,
    bool? archived,
    String? baseModified,
    String? requestId,
  }) async {
    if (offline) throw const StudioNetworkError('No connection.');
    shotSets.add({'shoot': shootId, 'shot': shotId, 'what': what, 'ar': ar});
    final s = await _base();
    return s.shots.first.copyWith(what: what ?? '');
  }
}

/// Everything outside the screens replaced: API, storage, probe, clock.
List<Override> shootOverrides({
  required ShootTestApi api,
  required KvStore kv,
  DateTime? now,
  bool canPlan = true,
  bool founder = true,
  List<Uri>? opened,
}) => [
  studioApiProvider.overrideWithValue(api),
  studioKvStoreProvider.overrideWithValue(kv),
  reachabilityIntervalProvider.overrideWithValue(null),
  reachabilityProbeProvider.overrideWithValue(() async => !api.offline),
  onSetClockProvider.overrideWithValue(
    () => now ?? DateTime.parse('2026-11-25T10:00:00+02:00'),
  ),
  canPlanShootsProvider.overrideWithValue(canPlan),
  isFounderProvider.overrideWithValue(founder),
  studioLinkOpenerProvider.overrideWithValue((u) async {
    opened?.add(u);
    return true;
  }),
];

/// A controllable clock for the outbox: each call is one second later.
DateTime Function() ticker(String start) {
  var t = DateTime.parse(start);
  return () {
    final cur = t;
    t = t.add(const Duration(seconds: 1));
    return cur;
  };
}

/// Pumps [child] in a Material app with the Studio theme and both Studio
/// localisations at [locale], on a 360 px phone by default.
Future<ProviderContainer> pumpShoot(
  WidgetTester tester,
  Widget child, {
  required ShootTestApi api,
  MemoryKvStore? kv,
  String locale = 'en',
  Size size = const Size(360, 1800),
  bool settle = true,
  bool canPlan = true,
  bool founder = true,
  List<Uri>? opened,
  List<Override> extra = const [],
  String? location,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scope = ProviderScope(
    overrides: [
      ...shootOverrides(
        api: api,
        kv: kv ?? MemoryKvStore(),
        canPlan: canPlan,
        founder: founder,
        opened: opened,
      ),
      ...extra,
    ],
    child: location != null
        ? MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: buildStudioTheme(locale: Locale(locale)),
            locale: Locale(locale),
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: _delegates,
            routerConfig: GoRouter(
              initialLocation: location,
              routes: [
                ...shootsRoutes(),
                GoRoute(path: '/more', builder: (_, _) => const Text('MORE')),
              ],
            ),
          )
        : MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildStudioTheme(locale: Locale(locale)),
            locale: Locale(locale),
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: _delegates,
            home: child,
          ),
  );
  await tester.pumpWidget(scope);
  if (settle) await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

const _delegates = <LocalizationsDelegate<dynamic>>[
  StudioStrings.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
