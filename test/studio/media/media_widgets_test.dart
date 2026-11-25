import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';
import 'package:jarz_pos/src/studio/shared/media/studio_media_widgets.dart';

import '../review/review_test_utils.dart';

StudioMedia image(String id) => StudioMedia.fromJson({
  'id': id,
  'kind': 'image',
  'thumb_url': 'https://cdn.example.test/$id/thumb.jpg',
  'poster_url': null,
  'feed_url': 'https://cdn.example.test/$id/feed.jpg',
  'url': 'https://cdn.example.test/$id/main.jpg',
  'width': 1080,
  'height': 1350,
  'duration_s': null,
});

StudioMedia video(String id) => StudioMedia.fromJson({
  'id': id,
  'kind': 'video',
  'thumb_url': 'https://cdn.example.test/$id/thumb.jpg',
  'poster_url': 'https://cdn.example.test/$id/poster.jpg',
  'feed_url': 'https://cdn.example.test/$id/feed.mp4',
  'url': 'https://cdn.example.test/$id/main.mp4',
  'width': 1080,
  'height': 1920,
  'duration_s': 24.0,
});

void main() {
  group('StudioThumb', () {
    testWidgets('null media shows a grey placeholder and does not throw', (
      tester,
    ) async {
      await pumpReview(
        tester,
        const Scaffold(body: StudioThumb(media: null, width: 80, height: 80)),
      );
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an image that cannot load falls back to the placeholder', (
      tester,
    ) async {
      await pumpReview(
        tester,
        Scaffold(body: StudioThumb(media: image('m1'), width: 80, height: 80)),
      );
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a video shows the play badge and its length', (tester) async {
      await pumpReview(
        tester,
        Scaffold(body: StudioThumb(media: video('v1'), width: 80, height: 120)),
      );
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('0:24'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('formatDuration', () {
      expect(formatDuration(null), '');
      expect(formatDuration(75), '1:15');
      expect(formatDuration(5.4), '0:05');
    });
  });

  group('StudioVideoPool', () {
    test(
      'keeps at most 3 controllers and never drops the active one',
      () async {
        final log = VideoLog();
        final pool = StudioVideoPool(factory: log.factory);
        addTearDown(pool.dispose);
        pool.acquire('a', Uri.parse('https://x.test/a.mp4'));
        pool.acquire('b', Uri.parse('https://x.test/b.mp4'));
        pool.acquire('c', Uri.parse('https://x.test/c.mp4'), active: true);
        expect(pool.liveCount, 3);
        pool.acquire('d', Uri.parse('https://x.test/d.mp4'));
        expect(pool.liveCount, 3, reason: 'one was dropped to make room');
        await Future<void>.delayed(Duration.zero);
        expect(log.made.length, 4);
        expect(log.made[0].disposed, isTrue, reason: 'oldest, not active');
        expect(log.made[2].disposed, isFalse, reason: 'the active one stays');
      },
    );

    test('a dropped video comes back with a fresh controller', () async {
      final log = VideoLog();
      final pool = StudioVideoPool(factory: log.factory);
      addTearDown(pool.dispose);
      for (final k in ['a', 'b', 'c', 'd']) {
        pool.acquire(k, Uri.parse('https://x.test/$k.mp4'));
      }
      final again = pool.acquire('a', Uri.parse('https://x.test/a.mp4'));
      expect(again.controller, isNotNull);
      expect(pool.liveCount, 3);
    });

    test('a failed video is marked failed and retry makes a new one', () async {
      final log = VideoLog()..failAll = true;
      final pool = StudioVideoPool(factory: log.factory);
      addTearDown(pool.dispose);
      final slot = pool.acquire('a', Uri.parse('https://x.test/a.mp4'));
      await Future<void>.delayed(Duration.zero);
      expect(slot.status, VideoSlotStatus.failed);
      log.failAll = false;
      pool.retry('a');
      await Future<void>.delayed(Duration.zero);
      expect(slot.status, VideoSlotStatus.ready);
    });

    test('release disposes the controller', () async {
      final log = VideoLog();
      final pool = StudioVideoPool(factory: log.factory);
      addTearDown(pool.dispose);
      pool.acquire('a', Uri.parse('https://x.test/a.mp4'));
      pool.release('a');
      await Future<void>.delayed(Duration.zero);
      expect(log.made.single.disposed, isTrue);
      expect(pool.liveCount, 0);
    });
  });

  group('StudioVideoPlayer', () {
    Widget player(StudioMedia m, {bool active = true, bool autoplay = false}) =>
        Scaffold(
          body: SizedBox(
            width: 300,
            height: 500,
            child: StudioVideoPlayer(
              media: m,
              active: active,
              autoplay: autoplay,
            ),
          ),
        );

    testWidgets('shows the poster and makes no controller until play', (
      tester,
    ) async {
      final log = VideoLog();
      await pumpReview(tester, player(video('v1')), video: log);
      expect(log.made, isEmpty);
      expect(find.byKey(const ValueKey('video-play-badge')), findsOneWidget);
    });

    testWidgets('tap plays, tap again pauses', (tester) async {
      final log = VideoLog();
      await pumpReview(tester, player(video('v1')), video: log);
      await tester.tap(find.byKey(const ValueKey('video-tap')));
      await tester.pumpAndSettle();
      expect(log.made.single.playing, isTrue);
      await tester.tap(find.byKey(const ValueKey('video-tap')));
      await tester.pumpAndSettle();
      expect(log.made.single.playing, isFalse);
    });

    testWidgets('autoplay starts muted and pauses when no longer active', (
      tester,
    ) async {
      final log = VideoLog();
      await pumpReview(tester, player(video('v1'), autoplay: true), video: log);
      expect(log.made.single.playing, isTrue);
      expect(log.made.single.volume, 0);
    });

    testWidgets('pauses when active turns false', (tester) async {
      final log = VideoLog();
      final active = ValueNotifier(true);
      await pumpReview(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: active,
          builder: (_, a, _) => player(video('v1'), active: a, autoplay: true),
        ),
        video: log,
      );
      expect(log.made.single.playing, isTrue);
      active.value = false;
      await tester.pumpAndSettle();
      expect(log.made.single.playing, isFalse);
    });

    testWidgets('a video that fails says so and retry works', (tester) async {
      final log = VideoLog()..failAll = true;
      await pumpReview(tester, player(video('v1'), autoplay: true), video: log);
      expect(find.byKey(const ValueKey('video-error')), findsOneWidget);
      log.failAll = false;
      await tester.tap(find.byKey(const ValueKey('video-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('video-error')), findsNothing);
      expect(log.made.last.playing, isTrue);
    });

    testWidgets('controls: scrub and sound', (tester) async {
      final log = VideoLog();
      await pumpReview(tester, player(video('v1'), autoplay: true), video: log);
      expect(find.byKey(const ValueKey('video-scrub')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('video-mute')));
      await tester.pumpAndSettle();
      expect(log.made.single.volume, 1);
      await tester.drag(
        find.byKey(const ValueKey('video-scrub')),
        const Offset(60, 0),
      );
      await tester.pumpAndSettle();
      expect(log.made.single.lastSeek, isNotNull);
    });

    testWidgets('three players in one pool keep 3 live controllers', (
      tester,
    ) async {
      final log = VideoLog();
      final pool = StudioVideoPool(factory: log.factory);
      addTearDown(pool.dispose);
      await pumpReview(
        tester,
        Scaffold(
          body: StudioVideoPoolScope(
            pool: pool,
            child: Column(
              children: [
                for (var i = 0; i < 4; i++)
                  SizedBox(
                    height: 100,
                    child: StudioVideoPlayer(
                      media: video('v$i'),
                      active: i == 1,
                      prefetch: true,
                      showControls: false,
                    ),
                  ),
              ],
            ),
          ),
        ),
        video: log,
      );
      expect(pool.liveCount, lessThanOrEqualTo(3));
      expect(log.live.length, lessThanOrEqualTo(3));
    });
  });

  group('openStudioMediaViewer', () {
    Widget opener(List<StudioMedia> items) => Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          key: const ValueKey('open'),
          onPressed: () => openStudioMediaViewer(context, items: items),
          child: const Text('open'),
        ),
      ),
    );

    testWidgets('swipes between items and counts them', (tester) async {
      final log = VideoLog();
      await pumpReview(
        tester,
        opener([image('m1'), video('v1'), image('m2')]),
        video: log,
      );
      await tester.tap(find.byKey(const ValueKey('open')));
      await tester.pumpAndSettle();
      expect(find.text('1 of 3'), findsOneWidget);
      await tester.timedDrag(
        find.byKey(const ValueKey('viewer-pages')),
        const Offset(-300, 0),
        const Duration(milliseconds: 400),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 of 3'), findsOneWidget);
      expect(log.made, isNotEmpty, reason: 'the video page autoplays');
      await tester.tap(find.byKey(const ValueKey('viewer-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('viewer-pages')), findsNothing);
    });

    testWidgets('download asks the server for a link and opens it', (
      tester,
    ) async {
      final opened = <Uri>[];
      await pumpReview(
        tester,
        opener([image('MED-000000107')]),
        opened: opened,
      );
      await tester.tap(find.byKey(const ValueKey('open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('viewer-download')));
      await tester.pumpAndSettle();
      expect(opened, hasLength(1));
      expect(opened.single.host, 'cdn.example.test');
    });

    testWidgets('a download that cannot open says so', (tester) async {
      await pumpReview(
        tester,
        opener([image('m1')]),
        opened: [],
        openResult: false,
      );
      await tester.tap(find.byKey(const ValueKey('open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('viewer-download')));
      await tester.pumpAndSettle();
      expect(find.textContaining('download link'), findsOneWidget);
    });

    testWidgets('a server error on the link says so', (tester) async {
      final api = RoleApi()..failNext('media.download_link', 'SERVER_ERROR');
      await pumpReview(tester, opener([image('m1')]), api: api);
      await tester.tap(find.byKey(const ValueKey('open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('viewer-download')));
      await tester.pumpAndSettle();
      expect(find.textContaining('download link'), findsOneWidget);
    });

    testWidgets('Arabic labels and RTL swipe', (tester) async {
      await pumpReview(
        tester,
        opener([image('m1'), image('m2')]),
        locale: 'ar',
      );
      await tester.tap(find.byKey(const ValueKey('open')));
      await tester.pumpAndSettle();
      expect(find.text('1 من 2'), findsOneWidget);
    });
  });
}
