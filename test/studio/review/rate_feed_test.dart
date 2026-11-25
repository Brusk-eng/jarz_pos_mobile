import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/models/studio_enums.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';
import 'package:jarz_pos/src/studio/features/review/presentation/rate_feed_screen.dart';
import 'package:jarz_pos/src/studio/features/review/state/rate_feed_state.dart';
import 'package:jarz_pos/src/studio/shared/studio_async_view.dart';

import 'review_test_utils.dart';

Finder key(String k) => find.byKey(ValueKey(k));

Future<void> swipeUp(WidgetTester tester) async {
  await tester.timedDrag(
    key('rate-feed'),
    const Offset(0, -400),
    const Duration(milliseconds: 400),
  );
  await tester.pumpAndSettle();
}

Future<ProviderContainer> pumpFeed(
  WidgetTester tester, {
  StudioApi? api,
  VideoLog? video,
  String locale = 'en',
  Size size = const Size(360, 740),
  bool settle = true,
}) => pumpReview(
  tester,
  const RateFeedScreen(),
  api: api,
  video: video,
  locale: locale,
  size: size,
  settle: settle,
);

void main() {
  group('states', () {
    testWidgets('loading shows the skeleton', (tester) async {
      await pumpFeed(tester, api: RoleApi(), settle: false);
      expect(find.byType(StudioSkeleton), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('error shows retry', (tester) async {
      final api = RoleApi()..failNext('inbox.to_rate', 'SERVER_ERROR');
      await pumpFeed(tester, api: api);
      expect(key('error-text'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(key('rate-feed'), findsOneWidget);
    });

    testWidgets('empty says you rated everything and what happens next', (
      tester,
    ) async {
      await pumpFeed(tester, api: FeedApi({}));
      expect(key('empty-purpose'), findsOneWidget);
      expect(find.text('You rated everything'), findsOneWidget);
      expect(find.textContaining('New cuts show up here'), findsOneWidget);
    });

    testWidgets('how this works opens', (tester) async {
      await pumpFeed(tester, api: RoleApi());
      await tester.tap(key('review-help'));
      await tester.pumpAndSettle();
      expect(find.text('Rating feed'), findsOneWidget);
      expect(find.textContaining('Swipe up'), findsOneWidget);
    });
  });

  group('the feed', () {
    testWidgets('shows the first version, plays it muted, offers 1 to 5', (
      tester,
    ) async {
      final log = VideoLog();
      final cards = await videoCards(tester, 3);
      await pumpFeed(
        tester,
        api: FeedApi({null: RateCardPage(items: cards)}),
        video: log,
      );
      expect(find.text('Reel 1'), findsOneWidget);
      expect(key('feed-position'), findsOneWidget);
      expect(find.text('1 of 3'), findsOneWidget);
      for (var s = 1; s <= 5; s++) {
        expect(key('score-$s'), findsOneWidget);
      }
      expect(log.made.first.playing, isTrue);
      expect(log.made.first.volume, 0, reason: 'muted');
      expect(find.text('RUN'), findsOneWidget);
    });

    testWidgets('one tap rates and moves on to the next', (tester) async {
      final api = FeedApi({
        null: RateCardPage(items: await videoCards(tester, 3)),
      });
      await pumpFeed(tester, api: api);
      await tester.tap(key('score-4'));
      await tester.pumpAndSettle();
      expect(api.rates.single.id, 'V1');
      expect(api.rates.single.score, 4);
      expect(api.rates.single.comment, isNull);
      expect(find.text('Reel 2'), findsOneWidget);
      expect(find.text('2 of 3'), findsOneWidget);
    });

    testWidgets('rating everything ends on "You rated everything"', (
      tester,
    ) async {
      final api = FeedApi({
        null: RateCardPage(items: await videoCards(tester, 2)),
      });
      final container = await pumpFeed(tester, api: api);
      await tester.tap(key('score-5'));
      await tester.pumpAndSettle();
      await tester.tap(key('score-3'));
      await tester.pumpAndSettle();
      expect(api.rates.map((r) => r.score), [5, 3]);
      expect(key('feed-end'), findsOneWidget);
      expect(find.text('You rated everything'), findsOneWidget);
      expect(key('feed-end-back'), findsOneWidget);
      expect(
        container.read(rateFeedControllerProvider).saved,
        containsAll(['V1', 'V2']),
      );
    });

    testWidgets(
      'a library item is shown as a card and rated with assets.rate',
      (tester) async {
        final cards = await videoCards(tester, 1);
        final fixture = (await tester.runAsync(
          () => FakeStudioApi(delay: Duration.zero).inboxToRate(),
        ))!.items;
        final assetCard = fixture.firstWhere(
          (c) => c.targetType == TargetType.asset,
        );
        final api = FeedApi({
          null: RateCardPage(items: [assetCard, ...cards]),
        });
        final container = await pumpFeed(tester, api: api);
        expect(find.text(assetCard.asset!.title), findsOneWidget);
        expect(find.text('1 of 2'), findsOneWidget);
        expect(key('feed-details'), findsNothing, reason: 'no version page');
        await tester.tap(key('score-5'));
        await tester.pumpAndSettle();
        expect(api.assetRates.single.id, assetCard.asset!.id);
        expect(api.assetRates.single.score, 5);
        expect(api.rates, isEmpty, reason: 'not versions.rate');
        expect(
          container.read(rateFeedControllerProvider).saved,
          contains(assetCard.asset!.id),
        );
        expect(find.text('Reel 1'), findsOneWidget);
      },
    );

    testWidgets('skip moves on without rating', (tester) async {
      final api = FeedApi({
        null: RateCardPage(items: await videoCards(tester, 2)),
      });
      await pumpFeed(tester, api: api);
      await tester.tap(key('feed-skip'));
      await tester.pumpAndSettle();
      expect(api.rates, isEmpty);
      expect(find.text('Reel 2'), findsOneWidget);
    });

    testWidgets('swiping up also moves on', (tester) async {
      final api = FeedApi({
        null: RateCardPage(items: await videoCards(tester, 3)),
      });
      await pumpFeed(tester, api: api);
      await swipeUp(tester);
      expect(find.text('Reel 2'), findsOneWidget);
    });

    testWidgets('a comment typed first is sent with the rating', (
      tester,
    ) async {
      final api = FeedApi({
        null: RateCardPage(items: await videoCards(tester, 2)),
      });
      await pumpFeed(tester, api: api);
      await tester.tap(key('feed-comment'));
      await tester.pumpAndSettle();
      await tester.enterText(key('feed-comment-field'), 'Hook is slow');
      await tester.tap(key('feed-comment-save'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Comment ready'), findsOneWidget);
      await tester.tap(key('score-2'));
      await tester.pumpAndSettle();
      expect(api.rates.single.comment, 'Hook is slow');
      expect(api.rates.single.score, 2);
    });

    testWidgets('a rating the server refuses is taken back', (tester) async {
      final api = FeedApi({
        null: RateCardPage(items: await videoCards(tester, 3)),
      })..failNext('versions.rate', 'SERVER_ERROR');
      final container = await pumpFeed(tester, api: api);
      await tester.tap(key('score-4'));
      await tester.pumpAndSettle();
      expect(find.textContaining('was not saved'), findsOneWidget);
      expect(
        container.read(rateFeedControllerProvider).rated,
        isEmpty,
        reason: 'rolled back',
      );
      // Back on the first card with its buttons.
      expect(find.text('Reel 1'), findsOneWidget);
      expect(key('score-4'), findsOneWidget);
      expect(key('feed-rated'), findsNothing);
      // And it can be rated again.
      await tester.tap(key('score-4'));
      await tester.pumpAndSettle();
      expect(api.rates, hasLength(2));
      expect(find.text('Reel 2'), findsOneWidget);
    });

    testWidgets('SHADOW_MODE is explained when a rating is refused', (
      tester,
    ) async {
      final api = FeedApi({
        null: RateCardPage(items: await videoCards(tester, 2)),
      })..failNext('versions.rate', 'SHADOW_MODE');
      await pumpFeed(tester, api: api);
      await tester.tap(key('score-3'));
      await tester.pumpAndSettle();
      expect(find.textContaining('not switched on yet'), findsOneWidget);
    });

    testWidgets('ALREADY_DONE counts as rated', (tester) async {
      final api = FeedApi({
        null: RateCardPage(items: await videoCards(tester, 2)),
      });
      final fresh = (await tester.runAsync(
        () => api.versionsGet(versionId: 'PC-00163-v2'),
      ))!.toJson();
      api.failNext('versions.rate', 'ALREADY_DONE', current: fresh);
      final container = await pumpFeed(tester, api: api);
      await tester.tap(key('score-5'));
      await tester.pumpAndSettle();
      expect(find.textContaining('was not saved'), findsNothing);
      expect(container.read(rateFeedControllerProvider).saved, contains('V1'));
    });

    testWidgets('cards that are not versions are left out', (tester) async {
      final cards = await videoCards(tester, 1);
      final asset = RateCard(
        targetType: TargetType.asset,
        version: null,
        asset: null,
      );
      final api = FeedApi({
        null: RateCardPage(items: [asset, ...cards]),
      });
      await pumpFeed(tester, api: api);
      expect(find.text('1 of 1'), findsOneWidget);
    });

    testWidgets('a picture version opens the viewer on tap', (tester) async {
      final api = FeedApi({
        null: RateCardPage(
          items: [
            RateCard(
              targetType: TargetType.version,
              version: (await tester.runAsync(
                () => RoleApi().versionsGet(versionId: 'PC-00163-v2'),
              ))!,
            ),
          ],
        ),
      });
      await pumpFeed(tester, api: api);
      expect(find.text('#3 Thank you, me'), findsOneWidget);
      await tester.tapAt(const Offset(180, 200));
      await tester.pumpAndSettle();
      expect(key('viewer-pages'), findsOneWidget);
    });
  });

  group('paging and video pool', () {
    testWidgets('loads the next page by cursor and then ends', (tester) async {
      final api = FeedApi({
        null: RateCardPage(items: await videoCards(tester, 2), next: 'p2'),
        'p2': RateCardPage(items: await videoCards(tester, 2, from: 3)),
      });
      await pumpFeed(tester, api: api);
      expect(api.asked, [null]);
      await tester.tap(key('score-3'));
      await tester.pumpAndSettle();
      expect(api.asked, [null, 'p2'], reason: 'asked when 2 from the end');
      await tester.tap(key('score-3'));
      await tester.pumpAndSettle();
      expect(find.text('Reel 3'), findsOneWidget);
      await tester.tap(key('score-3'));
      await tester.pumpAndSettle();
      await tester.tap(key('score-3'));
      await tester.pumpAndSettle();
      expect(key('feed-end'), findsOneWidget);
      expect(api.rates, hasLength(4));
    });

    testWidgets('at most 3 video controllers live while swiping through 6', (
      tester,
    ) async {
      final log = VideoLog();
      final api = FeedApi({
        null: RateCardPage(items: await videoCards(tester, 6)),
      });
      await pumpFeed(tester, api: api, video: log);
      for (var i = 0; i < 5; i++) {
        expect(log.live.length, lessThanOrEqualTo(3), reason: 'card ${i + 1}');
        await swipeUp(tester);
      }
      expect(log.live.length, lessThanOrEqualTo(3));
      expect(find.text('Reel 6'), findsOneWidget);
      expect(
        log.made.where((c) => c.playing).length,
        lessThanOrEqualTo(1),
        reason: 'only the visible one plays',
      );
    });

    testWidgets('sound button turns the sound on for the playing video', (
      tester,
    ) async {
      final log = VideoLog();
      final api = FeedApi({
        null: RateCardPage(items: await videoCards(tester, 2)),
      });
      await pumpFeed(tester, api: api, video: log);
      await tester.tap(key('feed-mute'));
      await tester.pumpAndSettle();
      expect(log.made.first.volume, 1);
    });
  });

  group('language and size', () {
    testWidgets('Arabic', (tester) async {
      final api = FeedApi({
        null: RateCardPage(items: await videoCards(tester, 1)),
      });
      await pumpFeed(tester, api: api, locale: 'ar');
      expect(find.text('قيّم'), findsOneWidget);
      expect(find.text('شغّلها'), findsOneWidget);
      expect(find.text('عدّي'), findsOneWidget);
      await tester.tap(key('score-5'));
      await tester.pumpAndSettle();
      expect(find.text('قيّمت كل حاجة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop width keeps the feed in a centred column', (
      tester,
    ) async {
      final api = FeedApi({
        null: RateCardPage(items: await videoCards(tester, 2)),
      });
      await pumpFeed(tester, api: api, size: const Size(1200, 800));
      expect(tester.getSize(key('rate-feed')).width, lessThanOrEqualTo(520));
      expect(tester.takeException(), isNull);
    });

    testWidgets('360 px phone: nothing overflows', (tester) async {
      final api = FeedApi({
        null: RateCardPage(items: await videoCards(tester, 2)),
      });
      await pumpFeed(tester, api: api, size: const Size(360, 600));
      expect(tester.takeException(), isNull);
    });
  });
}
