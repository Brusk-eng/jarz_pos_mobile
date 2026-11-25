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
import 'package:jarz_pos/src/studio/core/upload/file_source.dart';
import 'package:jarz_pos/src/studio/core/upload/picked_file.dart';
import 'package:jarz_pos/src/studio/core/upload/s3_client.dart';
import 'package:jarz_pos/src/studio/core/upload/upload_engine.dart';
import 'package:jarz_pos/src/studio/core/upload/upload_job.dart';
import 'package:jarz_pos/src/studio/data/models/studio_enums.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';
import 'package:jarz_pos/src/studio/features/pieces/pieces_routes.dart';

import '../assets/assets_test_utils.dart';
import '../upload/upload_test_utils.dart';
import 'harness.dart' as piece_harness;

/// Pieces API for the add-version screen: the piece is the contract's example
/// with the format and actions set by the test; `versions.add` is recorded.
class AddVersionApi extends AssetsTestApi {
  AddVersionApi({this.format = PieceFormat.reel, this.canAdd = true});

  PieceFormat format;
  bool canAdd;
  final addCalls = <Map<String, dynamic>>[];

  @override
  Future<StudioPiece> piecesGet({required String pieceId}) async {
    final p = await super.piecesGet(pieceId: pieceId);
    return p.copyWith(
      format: format,
      actions: [
        for (final a in p.actions)
          if (a != 'add_version') a,
        if (canAdd) 'add_version',
      ],
    );
  }

  @override
  Future<PieceVersion> versionsAdd({
    required String pieceId,
    required String kind,
    Object? mediaIds,
    Object? langs,
    Object? frames,
    String? title,
    String? ratePrompt,
    Object? tags,
    String? requestId,
  }) {
    addCalls.add({
      'piece_id': pieceId,
      'kind': kind,
      'media_ids': mediaIds,
      'frames': frames,
      'title': title,
      'request_id': requestId,
    });
    return super.versionsAdd(
      pieceId: pieceId,
      kind: kind,
      mediaIds: mediaIds,
      frames: frames,
      title: title,
      requestId: requestId,
    );
  }
}

Future<ProviderContainer> pumpAddVersion(
  WidgetTester tester,
  AssetsHarness h, {
  String pieceId = 'PC-00188',
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 1600);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studioApiProvider.overrideWithValue(h.api),
        studioS3ClientProvider.overrideWithValue(h.s3),
        studioKvStoreProvider.overrideWithValue(h.kv),
        studioFileSourceProvider.overrideWithValue(h.files),
        uploadRetryDelayProvider.overrideWithValue((_) => Duration.zero),
        reachabilityIntervalProvider.overrideWithValue(null),
        reachabilityProbeProvider.overrideWithValue(() async => true),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: buildStudioTheme(),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          StudioStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: GoRouter(
          initialLocation: '/pieces/$pieceId/add-version',
          routes: [
            ...piecesRoutes(),
            GoRoute(
              path: '/versions/:id',
              builder: (_, _) => const Text('VERSION'),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

Finder key(String k) => find.byKey(ValueKey(k));

MemoryPickedFile jpg(String name, int n) => MemoryPickedFile(
  name: name,
  bytes: bytesOf(400),
  modifiedMs: n,
  path: '/p/$name',
);

void main() {
  tearDown(disposeContainers);

  testWidgets(
    'a creator adds a cut: upload, then versions.add with the media id',
    (tester) async {
      final h = AssetsHarness(api: AddVersionApi());
      final api = h.api as AddVersionApi;
      h.files.next = [jpg('cut.jpg', 1)];
      final c = await pumpAddVersion(tester, h);
      expect(key('add-version-empty'), findsOneWidget);
      await tester.tap(key('add-version-gallery'));
      await tester.pumpAndSettle();
      expect(find.text('cut.jpg'), findsOneWidget);
      await tester.tap(key('add-version-save'));
      await tester.pumpAndSettle();
      expect(
        c.read(studioUploadEngineProvider).jobs.single.status,
        UploadStatus.done,
      );
      expect(api.addCalls, hasLength(1));
      expect(api.addCalls.single['piece_id'], 'PC-00188');
      expect(api.addCalls.single['kind'], 'video');
      expect(
        (api.addCalls.single['media_ids'] as List).single,
        startsWith('MED-'),
      );
      expect(api.addCalls.single['request_id'], isNotEmpty);
      // The screen says what happens next.
      expect(key('add-version-next'), findsOneWidget);
      expect(find.textContaining('founder approves'), findsOneWidget);
    },
  );

  testWidgets('a carousel keeps the order the person dragged', (tester) async {
    final h = AssetsHarness(api: AddVersionApi(format: PieceFormat.carousel));
    final api = h.api as AddVersionApi;
    h.files.next = [jpg('a.jpg', 1), jpg('b.jpg', 2), jpg('c.jpg', 3)];
    await pumpAddVersion(tester, h);
    await tester.tap(key('add-version-gallery'));
    await tester.pumpAndSettle();
    // Drag the first slide below the last one: b, c, a.
    final first = tester.getCenter(find.text('a.jpg'));
    final gesture = await tester.startGesture(first);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    final order = [
      for (final n in ['a.jpg', 'b.jpg', 'c.jpg'])
        (n, tester.getTopLeft(find.text(n)).dy),
    ]..sort((x, y) => x.$2.compareTo(y.$2));
    final names = [for (final o in order) o.$1];
    expect(names, isNot(['a.jpg', 'b.jpg', 'c.jpg']), reason: 'it moved');
    await tester.tap(key('add-version-save'));
    await tester.pumpAndSettle();
    expect(api.addCalls.single['kind'], 'carousel');
    final ids = api.addCalls.single['media_ids'] as List;
    expect(ids, hasLength(3));
    // Media ids are made from the upload order; the version has one per slide.
    expect(ids.toSet(), hasLength(3));
  });

  testWidgets('a story lead adds frames: assets are made, then the version', (
    tester,
  ) async {
    final h = AssetsHarness(api: AddVersionApi(format: PieceFormat.story));
    final api = h.api as AddVersionApi;
    h.files.next = [jpg('f1.jpg', 1), jpg('f2.jpg', 2)];
    await pumpAddVersion(tester, h);
    await tester.tap(key('add-version-gallery'));
    await tester.pumpAndSettle();
    await tester.tap(key('add-version-save'));
    await tester.pumpAndSettle();
    expect(api.createCalls, hasLength(2));
    expect(api.createCalls.every((c) => c['kind'] == 'Story frame'), isTrue);
    expect(api.addCalls, hasLength(1));
    expect(api.addCalls.single['kind'], 'story');
    expect(api.addCalls.single['media_ids'], isNull);
    expect(api.addCalls.single['frames'], hasLength(2));
  });

  testWidgets('not allowed without the add_version action', (tester) async {
    final h = AssetsHarness(api: AddVersionApi(canAdd: false));
    await pumpAddVersion(tester, h);
    expect(key('add-version-not-allowed'), findsOneWidget);
    expect(key('add-version-save'), findsNothing);
  });

  testWidgets('a file that cannot go up is refused in plain words', (
    tester,
  ) async {
    final h = AssetsHarness(api: AddVersionApi());
    h.files.next = [
      MemoryPickedFile(
        name: 'notes.txt',
        bytes: bytesOf(50),
        mime: 'text/plain',
        modifiedMs: 1,
        path: '/p/notes.txt',
      ),
    ];
    await pumpAddVersion(tester, h);
    await tester.tap(key('add-version-gallery'));
    await tester.pumpAndSettle();
    await tester.tap(key('add-version-save'));
    await tester.pumpAndSettle();
    expect(key('add-version-problem'), findsOneWidget);
    expect((h.api as AddVersionApi).addCalls, isEmpty);
  });

  testWidgets('the piece screen offers it only when the actions allow', (
    tester,
  ) async {
    final h = await piece_harness.pumpFeature(
      tester,
      location: '/pieces/PC-00163',
      height: 3500,
    );
    await piece_harness.tapKey(tester, 'add-version');
    expect(piece_harness.locationOf(h), '/pieces/PC-00163/add-version');
  });

  testWidgets('a creator without the action sees no button', (tester) async {
    await piece_harness.pumpFeature(
      tester,
      location: '/pieces/PC-00163',
      height: 3500,
      fixtures: piece_harness.patchedFixtures({
        'pieces.get': (j) => (j as Map)['actions'] = ['edit'],
      }),
    );
    expect(find.byKey(const ValueKey('add-version')), findsNothing);
  });
}
