import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/core/theme/studio_theme.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';
import 'package:jarz_pos/src/studio/shared/media/studio_media_widgets.dart';
import 'package:video_player/video_player.dart';

/// A video controller that never touches a platform: it "loads" at once.
class FakeVideoController extends VideoPlayerController {
  // ignore: use_super_parameters
  FakeVideoController(Uri url, {this.failInit = false}) : super.networkUrl(url);

  final bool failInit;
  bool disposed = false;
  bool playing = false;
  double volume = 1;
  Duration? lastSeek;

  @override
  Future<void> initialize() async {
    if (failInit) throw Exception('cannot load');
    value = value.copyWith(
      isInitialized: true,
      duration: const Duration(seconds: 24),
      size: const Size(1080, 1920),
    );
  }

  @override
  Future<void> play() async {
    playing = true;
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    playing = false;
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> setVolume(double v) async {
    volume = v;
    value = value.copyWith(volume: v);
  }

  @override
  Future<void> setLooping(bool looping) async {}

  @override
  Future<void> seekTo(Duration position) async {
    lastSeek = position;
    value = value.copyWith(position: position);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    super.dispose();
  }
}

/// Every controller a test's factory made, in order.
class VideoLog {
  final List<FakeVideoController> made = [];
  bool failAll = false;

  List<FakeVideoController> get live => [
    for (final c in made)
      if (!c.disposed) c,
  ];

  VideoControllerFactory get factory => (url) {
    final c = FakeVideoController(url, failInit: failAll);
    made.add(c);
    return c;
  };
}

/// The fake API, with `versions.get` answering the `actions` of [role] the
/// way the real server would (the shipped fixture is the founder's).
class RoleApi extends FakeStudioApi {
  // ignore: use_super_parameters
  RoleApi({String role = 'founder', Map<String, List<String>>? actions})
    : _actions = actions ?? _byRole[role]!,
      super(role: role, delay: Duration.zero);

  static const _byRole = {
    'founder': ['approve', 'fix', 'rate', 'comment', 'edit_meta'],
    'lead': ['rate', 'comment', 'edit_meta'],
    'creator': ['comment'],
  };

  final Object _actions;

  /// Patch the version the next `versions.get` returns.
  PieceVersion Function(PieceVersion)? patch;

  /// What `versions.rate` was asked: version id, score, comment.
  final List<({String id, int score, String? comment})> rates = [];

  @override
  Future<PieceVersion> versionsRate({
    required String versionId,
    required int score,
    String? comment,
    String? requestId,
  }) {
    rates.add((id: versionId, score: score, comment: comment));
    return super.versionsRate(
      versionId: versionId,
      score: score,
      comment: comment,
      requestId: requestId,
    );
  }

  /// What `assets.rate` was asked: asset id, score, comment.
  final List<({String id, int score, String? comment})> assetRates = [];

  @override
  Future<StudioAsset> assetsRate({
    required String assetId,
    required int score,
    String? comment,
    String? requestId,
  }) {
    assetRates.add((id: assetId, score: score, comment: comment));
    return super.assetsRate(
      assetId: assetId,
      score: score,
      comment: comment,
      requestId: requestId,
    );
  }

  /// Replace the comments the server answers with.
  List<StudioComment>? comments;

  @override
  Future<StudioCommentPage> versionsComments({
    required String versionId,
    int? frame,
    int? limit,
    String? after,
  }) async {
    final page = await super.versionsComments(
      versionId: versionId,
      frame: frame,
      limit: limit,
      after: after,
    );
    return comments == null
        ? page
        : StudioCommentPage(items: comments!, next: null);
  }

  @override
  Future<PieceVersion> versionsGet({required String versionId}) async {
    final v = await super.versionsGet(versionId: versionId);
    final acts = _actions is Map
        ? (_actions as Map<String, List<String>>)[versionId]
        : _actions as List<String>;
    final withActions = v.copyWith(actions: acts ?? v.actions);
    return patch == null ? withActions : patch!(withActions);
  }
}

/// Pumps [child] in a plain Material app with the Studio theme, the Material
/// localisations and a fake API, at [locale].
Future<ProviderContainer> pumpReview(
  WidgetTester tester,
  Widget child, {
  StudioApi? api,
  VideoLog? video,
  List<Uri>? opened,
  bool openResult = true,
  String locale = 'en',
  Size size = const Size(360, 740),
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final log = video ?? VideoLog();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studioApiProvider.overrideWithValue(
          api ?? FakeStudioApi(delay: Duration.zero),
        ),
        studioVideoControllerFactoryProvider.overrideWithValue(log.factory),
        studioLinkOpenerProvider.overrideWithValue((u) async {
          opened?.add(u);
          return openResult;
        }),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildStudioTheme(locale: Locale(locale)),
        locale: Locale(locale),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

/// Like [pumpReview] but through a real router, to check the route table.
Future<void> pumpReviewRouter(
  WidgetTester tester,
  List<RouteBase> routes,
  String location, {
  StudioApi? api,
  VideoLog? video,
  Size size = const Size(360, 740),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final log = video ?? VideoLog();
  final router = GoRouter(routes: routes, initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studioApiProvider.overrideWithValue(api ?? RoleApi()),
        studioVideoControllerFactoryProvider.overrideWithValue(log.factory),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: buildStudioTheme(),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The to-rate feed served from [pages] (cursor to page), whatever the role.
class FeedApi extends RoleApi {
  FeedApi(this.pages, {super.role});

  final Map<String?, RateCardPage> pages;
  final List<String?> asked = [];

  @override
  Future<RateCardPage> inboxToRate({
    int? limit,
    String? after,
    String? kind,
  }) async {
    asked.add(after);
    return pages[after] ?? const RateCardPage(items: [], next: null);
  }
}

/// [n] video cards for the feed, with ids `V1`..`Vn`, made from the fixture.
Future<List<RateCard>> videoCards(
  WidgetTester tester,
  int n, {
  int from = 1,
}) async {
  final base = (await tester.runAsync(
    () => FakeStudioApi(delay: Duration.zero).inboxToRate(),
  ))!.items.first;
  return [
    for (var i = from; i < from + n; i++)
      base.copyWith(
        version: base.version!.copyWith(
          id: 'V$i',
          piece: base.version!.piece.copyWith(id: 'P$i', title: 'Reel $i'),
          files: [
            for (final f in base.version!.files)
              f.copyWith(media: f.media.copyWith(id: 'MED-V$i')),
          ],
        ),
      ),
  ];
}
