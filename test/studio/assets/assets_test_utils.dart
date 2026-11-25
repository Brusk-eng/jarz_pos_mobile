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
import 'package:jarz_pos/src/studio/data/models/studio_enums.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';
import 'package:jarz_pos/src/studio/features/assets/assets_routes.dart';
import 'package:jarz_pos/src/studio/shared/media/studio_media_widgets.dart';

import '../upload/upload_test_utils.dart';

/// Library API: the contract's three example assets, with filters recorded
/// and consent validated like the server does. Media calls come from
/// [UploadTestApi] so a consent screenshot or a new file can really upload.
class AssetsTestApi extends UploadTestApi {
  AssetsTestApi() : super();

  /// Every `assets.list` call's filters.
  final listCalls = <Map<String, String?>>[];
  final createCalls = <Map<String, dynamic>>[];
  final consentCalls = <Map<String, dynamic>>[];
  final usedCalls = <Map<String, dynamic>>[];
  final updateCalls = <Map<String, dynamic>>[];
  final rateCalls = <int>[];
  final commentCalls = <String>[];

  /// Answer `assets.list` with this instead of the example (null = example).
  List<StudioAsset>? items;

  /// Rows per page; the rest follows behind a cursor.
  int? pageSize;

  /// No buttons on any asset.
  bool noActions = false;

  /// Thrown by the next `assets.set_consent`.
  Object? consentError;

  /// Error to throw from the next `assets.get`.
  Object? getError;

  @override
  Future<StudioAssetPage> assetsList({
    String? kind,
    String? category,
    String? flavourId,
    String? status,
    String? uploadedBy,
    String? consent,
    String? q,
    bool? includeHidden,
    int? limit,
    String? after,
  }) async {
    if (offline) throw const StudioNetworkError('No connection.');
    listCalls.add({
      'kind': kind,
      'flavour_id': flavourId,
      'status': status,
      'consent': consent,
      'q': q,
      'after': after,
    });
    final base = items ?? (await super.assetsList()).items;
    var rows = [
      for (final a in base)
        if ((kind == null || a.kind.wire == kind) &&
            (consent == null || a.consent?.status.wire == consent) &&
            (status == null || a.status.wire == status) &&
            (flavourId == null || a.flavour?.id == flavourId) &&
            (q == null || a.title.toLowerCase().contains(q.toLowerCase())))
          noActions ? a.copyWith(actions: const []) : a,
    ];
    String? next;
    if (pageSize != null) {
      final start = after == null ? 0 : int.parse(after);
      final end = (start + pageSize!).clamp(0, rows.length);
      next = end < rows.length ? '$end' : null;
      rows = rows.sublist(start, end);
    }
    return StudioAssetPage(items: rows, next: next);
  }

  @override
  Future<StudioAsset> assetsGet({required String assetId}) async {
    if (offline) throw const StudioNetworkError('No connection.');
    if (getError != null) throw getError!;
    final a = await super.assetsGet(assetId: assetId);
    return noActions ? a.copyWith(actions: const []) : a.copyWith(id: assetId);
  }

  @override
  Future<StudioAsset> assetsCreate({
    required String mediaId,
    required String kind,
    String? title,
    String? flavourId,
    String? category,
    Object? tags,
    String? theme,
    String? note,
    String? sourceRef,
    String? requestId,
  }) async {
    createCalls.add({
      'media_id': mediaId,
      'kind': kind,
      'title': title,
      'flavour_id': flavourId,
      'category': category,
      'note': note,
      'request_id': requestId,
    });
    return super.assetsGet(assetId: 'AST-0000316');
  }

  @override
  Future<StudioAsset> assetsSetConsent({
    required String assetId,
    required String status,
    String? who,
    String? date,
    String? scope,
    String? proofMediaId,
    String? requestId,
  }) async {
    if (offline) throw const StudioNetworkError('No connection.');
    consentCalls.add({
      'status': status,
      'who': who,
      'date': date,
      'scope': scope,
      'proof_media_id': proofMediaId,
      'request_id': requestId,
    });
    if (consentError != null) {
      final e = consentError!;
      consentError = null;
      throw e;
    }
    if (status == 'Given') {
      for (final e in {
        'who': who,
        'date': date,
        'scope': scope,
        'proof_media_id': proofMediaId,
      }.entries) {
        if (e.value == null) {
          throw StudioValidation('Given needs ${e.key}.', field: e.key);
        }
      }
    }
    final a = await super.assetsGet(assetId: assetId);
    return a.copyWith(
      consent: Consent(
        status: ConsentStatus.parse(status),
        who: who,
        date: date,
        scope: ConsentScope.values.firstWhere(
          (s) => s.wire == scope,
          orElse: () => ConsentScope.organicOnly,
        ),
        paidOk: scope == 'Organic and paid' && status == 'Given',
      ),
    );
  }

  @override
  Future<StudioAsset> assetsMarkUsed({
    required String assetId,
    String? status,
    String? note,
    String? requestId,
  }) async {
    usedCalls.add({'status': status, 'note': note});
    final a = await super.assetsGet(assetId: assetId);
    return a.copyWith(status: AssetStatus.parse(status), usedCount: 1);
  }

  @override
  Future<StudioAsset> assetsRate({
    required String assetId,
    required int score,
    String? comment,
    String? requestId,
  }) async {
    rateCalls.add(score);
    return super.assetsRate(
      assetId: assetId,
      score: score,
      comment: comment,
      requestId: requestId,
    );
  }

  @override
  Future<CommentResult> assetsComment({
    required String assetId,
    required String body,
    String? requestId,
  }) async {
    commentCalls.add(body);
    return super.assetsComment(
      assetId: assetId,
      body: body,
      requestId: requestId,
    );
  }

  @override
  Future<StudioAsset> assetsUpdate({
    required String assetId,
    required Object fields,
    String? baseModified,
  }) async {
    updateCalls.add(Map<String, dynamic>.from(fields as Map));
    return super.assetsGet(assetId: assetId);
  }
}

/// A file source whose pick answers are set by the test.
class PickFileSource extends FakeFileSource {
  List<PickedFile> next = [];

  @override
  Future<List<PickedFile>> pickMedia({bool multiple = true}) async => next;
  @override
  Future<List<PickedFile>> pickFiles({bool multiple = true}) async => next;
}

class AssetsHarness {
  AssetsHarness({AssetsTestApi? api})
    : api = api ?? AssetsTestApi(),
      s3 = FakeS3(),
      kv = MemoryKvStore(),
      files = PickFileSource();

  final AssetsTestApi api;
  final FakeS3 s3;
  final MemoryKvStore kv;
  final PickFileSource files;
  List<Uri> opened = [];
}

/// Pumps the Library routes (or one screen) with every outside door replaced.
Future<ProviderContainer> pumpAssets(
  WidgetTester tester,
  AssetsHarness h, {
  String location = '/assets',
  String locale = 'en',
  Size size = const Size(360, 1800),
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
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
        studioLinkOpenerProvider.overrideWithValue((u) async {
          h.opened.add(u);
          return true;
        }),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: buildStudioTheme(locale: Locale(locale)),
        locale: Locale(locale),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          StudioStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: GoRouter(
          initialLocation: location,
          routes: [
            ...assetsRoutes(),
            GoRoute(path: '/more', builder: (_, _) => const Text('MORE')),
          ],
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}
