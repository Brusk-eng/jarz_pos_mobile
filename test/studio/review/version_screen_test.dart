import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/data/models/studio_enums.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';
import 'package:jarz_pos/src/studio/features/review/presentation/version_screen.dart';
import 'package:jarz_pos/src/studio/features/review/review_routes.dart';
import 'package:jarz_pos/src/studio/shared/studio_async_view.dart';

import 'review_test_utils.dart';

const _id = 'PC-00163-v2';

Finder key(String k) => find.byKey(ValueKey(k));

Future<void> tapKey(WidgetTester tester, String k) async {
  await tester.ensureVisible(key(k));
  await tester.tap(key(k));
  await tester.pumpAndSettle();
}

StoryFrame frame(int position, {int comments = 0}) => StoryFrame.fromJson({
  'position': position,
  'asset': {
    'id': 'AS-$position',
    'title': 'Frame $position',
    'kind': 'Story frame',
    'media': {
      'id': 'MED-F$position',
      'kind': 'image',
      'thumb_url': 'https://cdn.example.test/f$position/thumb.jpg',
      'url': 'https://cdn.example.test/f$position/main.jpg',
      'width': 1080,
      'height': 1920,
    },
  },
  'status': 'posted',
  'comments_count': comments,
});

StudioComment frameComment() => StudioComment.fromJson({
  'id': 'CMT-F2',
  'target_type': 'version',
  'target_id': _id,
  'frame': 2,
  'body': 'Move the text up on this one.',
  'person': {'key': 'ali', 'full_name': 'Ali'},
  'at': '2026-11-24T10:20:00+02:00',
});

/// A tall window so the whole page is built (a ListView builds lazily);
/// the width stays a 360 px phone.
Future<ProviderContainer> pumpVersion(
  WidgetTester tester,
  Widget child, {
  StudioApi? api,
  VideoLog? video,
  String locale = 'en',
  Size size = const Size(360, 2800),
  bool settle = true,
}) => pumpReview(
  tester,
  child,
  api: api,
  video: video,
  locale: locale,
  size: size,
  settle: settle,
);

void main() {
  group('states', () {
    testWidgets('loading shows the skeleton', (tester) async {
      await pumpVersion(
        tester,
        const VersionScreen(versionId: _id),
        api: RoleApi(),
        settle: false,
      );
      expect(find.byType(StudioSkeleton), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(StudioSkeleton), findsNothing);
    });

    testWidgets('error shows retry and retry loads it', (tester) async {
      final api = RoleApi()..failNext('versions.get', 'SERVER_ERROR');
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      expect(key('error-text'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(key('piece-title'), findsOneWidget);
    });

    testWidgets('the how-this-works sheet opens', (tester) async {
      await pumpVersion(
        tester,
        const VersionScreen(versionId: _id),
        api: RoleApi(),
      );
      await tester.tap(key('review-help'));
      await tester.pumpAndSettle();
      expect(find.text('Reviewing a version'), findsOneWidget);
      expect(find.textContaining('sell judge'), findsOneWidget);
    });
  });

  group('content', () {
    testWidgets('shows media, title, stage, verdict, ratings, comments', (
      tester,
    ) async {
      await pumpVersion(
        tester,
        const VersionScreen(versionId: _id),
        api: RoleApi(),
      );
      expect(find.text('#3 Thank you, me'), findsOneWidget);
      expect(find.text('In review'), findsOneWidget);
      expect(find.text('Version 2 · Current version'), findsOneWidget);
      expect(find.text('RUN'), findsOneWidget);
      expect(key('verdict-score'), findsOneWidget);
      expect(find.text('Sell score: 4.2 out of 5'), findsOneWidget);
      expect(find.textContaining('Opens on the spoon'), findsOneWidget);
      expect(find.textContaining('closing line repeats'), findsOneWidget);
      expect(find.textContaining('Cut the closing line'), findsOneWidget);
      expect(find.text('4.5 out of 5 from 2 ratings'), findsOneWidget);
      expect(find.text('Still to rate: Ali, Kareem'), findsOneWidget);
      expect(key('my-rating-none'), findsOneWidget);
      expect(find.textContaining('Headline sits right above'), findsOneWidget);
      expect(key('media-pages'), findsOneWidget);
      expect(find.text("Waiting for the founder's approval"), findsOneWidget);
      expect(find.textContaining('Posts Tue 1 Dec 13:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a story shows its frames and the frame of a comment', (
      tester,
    ) async {
      final api = RoleApi()
        ..patch = ((v) => v.copyWith(
          kind: VersionKind.story,
          files: const [],
          frames: [frame(1), frame(2, comments: 1), frame(3)],
        ))
        ..comments = [frameComment()];
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      expect(key('frame-strip'), findsOneWidget);
      expect(key('frame-2'), findsOneWidget);
      expect(find.text('Story frames'), findsOneWidget);
      expect(find.text('Frame 2'), findsWidgets);
      expect(key('comment-frame-CMT-F2'), findsOneWidget);
      await tester.tap(key('frame-3'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a version with no media says so', (tester) async {
      final api = RoleApi()..patch = (v) => v.copyWith(files: const []);
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      expect(key('no-media'), findsOneWidget);
    });

    testWidgets('no verdict is worded', (tester) async {
      final api = RoleApi()..patch = (v) => v.copyWith(verdict: null);
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      expect(key('no-verdict'), findsOneWidget);
    });

    testWidgets('an outdated verdict says so', (tester) async {
      final api = RoleApi()
        ..patch = (v) => v.copyWith(verdict: v.verdict!.copyWith(stale: true));
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      expect(key('verdict-stale'), findsOneWidget);
    });

    testWidgets('a video version plays from its poster', (tester) async {
      final log = VideoLog();
      final video = StudioMedia.fromJson({
        'id': 'MED-V',
        'kind': 'video',
        'thumb_url': 'https://cdn.example.test/v/thumb.jpg',
        'poster_url': 'https://cdn.example.test/v/poster.jpg',
        'feed_url': 'https://cdn.example.test/v/feed.mp4',
        'url': 'https://cdn.example.test/v/main.mp4',
        'width': 1080,
        'height': 1920,
        'duration_s': 24.0,
      });
      final api = RoleApi()
        ..patch = (v) => v.copyWith(
          kind: VersionKind.video,
          files: [VersionFile(position: 1, media: video)],
        );
      await pumpVersion(
        tester,
        const VersionScreen(versionId: _id),
        api: api,
        video: log,
      );
      expect(log.made, isEmpty);
      await tester.tap(key('video-tap'));
      await tester.pumpAndSettle();
      expect(log.made.single.playing, isTrue);
    });
  });

  group('buttons come only from actions', () {
    for (final (role, shown, hidden) in [
      (
        'founder',
        ['action-approve', 'action-fix', 'action-rate', 'action-comment'],
        ['action-clear'],
      ),
      (
        'lead',
        ['action-rate', 'action-comment'],
        ['action-approve', 'action-fix', 'action-clear'],
      ),
      (
        'creator',
        ['action-comment'],
        ['action-approve', 'action-fix', 'action-clear', 'action-rate'],
      ),
    ]) {
      testWidgets(role, (tester) async {
        await pumpVersion(
          tester,
          const VersionScreen(versionId: _id),
          api: RoleApi(role: role),
        );
        for (final k in shown) {
          expect(key(k), findsOneWidget, reason: '$role shows $k');
        }
        for (final k in hidden) {
          expect(key(k), findsNothing, reason: '$role hides $k');
        }
      });
    }

    testWidgets('an action list with only clear_review shows only that', (
      tester,
    ) async {
      final api = RoleApi(
        actions: {
          _id: ['clear_review'],
        },
      );
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      expect(key('action-clear'), findsOneWidget);
      expect(key('action-approve'), findsNothing);
      expect(key('action-rate'), findsNothing);
      expect(key('action-comment'), findsNothing);
    });

    testWidgets('no actions: no bar at all', (tester) async {
      final api = RoleApi(actions: {_id: <String>[]});
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      expect(key('action-bar'), findsNothing);
    });
  });

  group('approve', () {
    testWidgets('one confirm tap, then says when it posts and who has it', (
      tester,
    ) async {
      final api = RoleApi();
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      await tapKey(tester, 'action-approve');
      expect(key('approve-dialog'), findsOneWidget);
      expect(find.text('It will post on Tue 1 Dec 13:00.'), findsOneWidget);
      expect(api.calls, isNot(contains('versions.approve')));
      await tester.tap(key('approve-confirm'));
      await tester.pumpAndSettle();
      expect(api.calls, contains('versions.approve'));
      expect(
        find.text('Approved. It posts on Tue 1 Dec 13:00.'),
        findsOneWidget,
      );
      expect(key('action-approve'), findsNothing);
      expect(key('action-clear'), findsOneWidget);
      expect(key('notice-back'), findsOneWidget);
    });

    testWidgets('cancel changes nothing', (tester) async {
      final api = RoleApi();
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      await tapKey(tester, 'action-approve');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(api.calls, isNot(contains('versions.approve')));
      expect(key('action-approve'), findsOneWidget);
    });

    testWidgets('approving a version with no slot says who gives one', (
      tester,
    ) async {
      final api = RoleApi()..patch = (v) => v.copyWith(post: null);
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      await tapKey(tester, 'action-approve');
      expect(find.textContaining('no posting date yet'), findsOneWidget);
      await tester.tap(key('approve-confirm'));
      await tester.pumpAndSettle();
      // The approve answer is the fixture, which still carries its post; the
      // notice follows the answer, so only assert it is the approved notice.
      expect(key('notice-ok'), findsOneWidget);
    });

    testWidgets('GATE_FAILED lists the problems in plain words', (
      tester,
    ) async {
      final api = RoleApi()
        ..failNext(
          'versions.approve',
          'GATE_FAILED',
          problems: [
            {'code': 'needs_verdict', 'message': 'It has no sell verdict yet.'},
            {
              'code': 'claim',
              'message': 'One claim is not on the approved list.',
            },
          ],
        );
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      await tapKey(tester, 'action-approve');
      await tester.tap(key('approve-confirm'));
      await tester.pumpAndSettle();
      expect(key('gate-dialog'), findsOneWidget);
      expect(find.text('It has no sell verdict yet.'), findsOneWidget);
      expect(
        find.text('One claim is not on the approved list.'),
        findsOneWidget,
      );
      expect(find.text('It is not ready to approve'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(key('action-approve'), findsOneWidget, reason: 'rolled back');
      expect(find.text("Waiting for the founder's approval"), findsOneWidget);
    });

    testWidgets('SHADOW_MODE says the Studio is not switched on', (
      tester,
    ) async {
      final api = RoleApi()..failNext('versions.approve', 'SHADOW_MODE');
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      await tapKey(tester, 'action-approve');
      await tester.tap(key('approve-confirm'));
      await tester.pumpAndSettle();
      expect(key('notice-error'), findsOneWidget);
      expect(find.textContaining('not switched on yet'), findsOneWidget);
      expect(find.text("Waiting for the founder's approval"), findsOneWidget);
    });

    testWidgets('STALE loads the fresh copy and says so', (tester) async {
      final api = RoleApi();
      final base = (await tester.runAsync(
        () => api.versionsGet(versionId: _id),
      ))!;
      final fresh = base
          .copyWith(title: 'Fresh title from the server')
          .toJson();
      api.failNext('versions.approve', 'STALE', current: fresh);
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      await tapKey(tester, 'action-approve');
      await tester.tap(key('approve-confirm'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('changed since you opened it'),
        findsOneWidget,
      );
      expect(find.text('Fresh title from the server'), findsOneWidget);
    });

    testWidgets('NOT_PERMITTED reloads the buttons', (tester) async {
      final api = RoleApi()..failNext('versions.approve', 'NOT_PERMITTED');
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      await tapKey(tester, 'action-approve');
      await tester.tap(key('approve-confirm'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Your role cannot do that'), findsOneWidget);
      expect(api.calls.where((c) => c == 'versions.get').length, 2);
    });

    testWidgets('a server failure rolls back and says so', (tester) async {
      final api = RoleApi()..failNext('versions.approve', 'SERVER_ERROR');
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      await tapKey(tester, 'action-approve');
      await tester.tap(key('approve-confirm'));
      await tester.pumpAndSettle();
      expect(find.textContaining('went wrong on our side'), findsOneWidget);
      expect(key('action-approve'), findsOneWidget);
    });

    testWidgets('ALREADY_DONE says so and shows how it stands', (tester) async {
      final api = RoleApi();
      final base = (await tester.runAsync(
        () => api.versionsGet(versionId: _id),
      ))!;
      final done = base
          .copyWith(
            reviewOutcome: ReviewOutcome.approved,
            awaitingReview: false,
            actions: ['clear_review', 'rate', 'comment'],
          )
          .toJson();
      api.failNext('versions.approve', 'ALREADY_DONE', current: done);
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      await tapKey(tester, 'action-approve');
      await tester.tap(key('approve-confirm'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Already done'), findsOneWidget);
      expect(key('action-approve'), findsNothing);
    });
  });

  group('send back', () {
    testWidgets('needs a reason, then says who has it', (tester) async {
      final api = RoleApi();
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      await tapKey(tester, 'action-fix');
      await tester.tap(key('send-back-confirm'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Write what should change'), findsOneWidget);
      expect(api.calls, isNot(contains('versions.fix')));
      await tester.enterText(key('send-back-reason'), 'Open on the spoon.');
      await tester.tap(key('send-back-confirm'));
      await tester.pumpAndSettle();
      expect(api.calls, contains('versions.fix'));
      expect(
        find.text('Sent back to Kareem, with your reason.'),
        findsOneWidget,
      );
      expect(find.text('Sent back: Open on the spoon.'), findsOneWidget);
      expect(key('action-fix'), findsNothing);
    });

    testWidgets('a server VALIDATION shows its own sentence', (tester) async {
      final api = RoleApi()
        ..failNext('versions.fix', 'VALIDATION', message: 'Say it shorter.');
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      await tapKey(tester, 'action-fix');
      await tester.enterText(key('send-back-reason'), 'x');
      await tester.tap(key('send-back-confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Say it shorter.'), findsOneWidget);
    });
  });

  group('clear the decision', () {
    testWidgets('puts it back in the waiting list', (tester) async {
      final api =
          RoleApi(
              actions: {
                _id: ['clear_review', 'rate', 'comment'],
              },
            )
            ..patch = (v) => v.copyWith(
              reviewOutcome: ReviewOutcome.approved,
              awaitingReview: false,
              reviewedBy: const PersonRef(
                key: 'abdelrahman',
                fullName: 'Abdelrahman',
              ),
            );
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      expect(find.text('Approved by Abdelrahman'), findsOneWidget);
      await tapKey(tester, 'action-clear');
      expect(api.calls, contains('versions.clear_review'));
      expect(find.textContaining('Undone'), findsOneWidget);
      expect(key('action-approve'), findsOneWidget);
    });
  });

  group('rate and comment', () {
    testWidgets('rate with a comment, then change it', (tester) async {
      final api = RoleApi(role: 'lead');
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      expect(find.text('Rate'), findsOneWidget);
      await tapKey(tester, 'action-rate');
      expect(find.text('Drop it'), findsOneWidget);
      expect(find.text('Run it'), findsOneWidget);
      await tester.tap(key('score-4'));
      await tester.enterText(key('rate-comment'), 'Strong hook');
      await tester.pump();
      await tester.tap(key('rate-save'));
      await tester.pumpAndSettle();
      expect(api.calls, contains('versions.rate'));
      expect(find.text('Saved your rating: 4, Strong.'), findsOneWidget);
      expect(find.text('Your rating: 4, Strong'), findsOneWidget);
      expect(find.text('Change rating'), findsOneWidget);
    });

    testWidgets('save is off until a score is picked', (tester) async {
      await pumpVersion(
        tester,
        const VersionScreen(versionId: _id),
        api: RoleApi(role: 'lead'),
      );
      await tapKey(tester, 'action-rate');
      final save = tester.widget<FilledButton>(key('rate-save'));
      expect(save.onPressed, isNull);
    });

    testWidgets('a failed rating says nothing was changed', (tester) async {
      final api = RoleApi(role: 'lead')
        ..failNext('versions.rate', 'SERVER_ERROR');
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      await tapKey(tester, 'action-rate');
      await tester.tap(key('score-2'));
      await tester.pump();
      await tester.tap(key('rate-save'));
      await tester.pumpAndSettle();
      expect(key('notice-error'), findsOneWidget);
      expect(find.text('Rate'), findsOneWidget);
    });

    testWidgets('a creator can comment', (tester) async {
      final api = RoleApi(role: 'creator');
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      await tapKey(tester, 'action-comment');
      await tester.enterText(key('comment-body'), 'Fixed the headline.');
      await tester.pump();
      await tester.tap(key('comment-send'));
      await tester.pumpAndSettle();
      expect(api.calls, contains('versions.comment'));
      expect(find.text('Comment added.'), findsOneWidget);
    });

    testWidgets('a comment on a story can pick its frame', (tester) async {
      final api = RoleApi(role: 'creator')
        ..patch = (v) => v.copyWith(
          kind: VersionKind.story,
          files: const [],
          frames: [frame(1), frame(2)],
        );
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      await tapKey(tester, 'action-comment');
      expect(find.text('Whole version'), findsOneWidget);
      await tester.tap(key('comment-frame-pick-2'));
      await tester.enterText(key('comment-body'), 'Too dark.');
      await tester.pump();
      await tester.tap(key('comment-send'));
      await tester.pumpAndSettle();
      expect(api.calls, contains('versions.comment'));
    });

    testWidgets('a failed comment says nothing was changed', (tester) async {
      final api = RoleApi(role: 'creator')
        ..failNext('versions.comment', 'SERVER_ERROR');
      await pumpVersion(tester, const VersionScreen(versionId: _id), api: api);
      await tapKey(tester, 'action-comment');
      await tester.enterText(key('comment-body'), 'Hello');
      await tester.pump();
      await tester.tap(key('comment-send'));
      await tester.pumpAndSettle();
      expect(key('notice-error'), findsOneWidget);
    });
  });

  group('layout and language', () {
    testWidgets('desktop width puts the media beside the details', (
      tester,
    ) async {
      await pumpVersion(
        tester,
        const VersionScreen(versionId: _id),
        api: RoleApi(),
        size: const Size(1100, 800),
      );
      expect(key('version-details'), findsOneWidget);
      expect(key('media-pages'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('360 px phone has no overflow', (tester) async {
      await pumpVersion(
        tester,
        const VersionScreen(versionId: _id),
        api: RoleApi(),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Arabic: texts, RTL and the same buttons', (tester) async {
      final api = RoleApi();
      await pumpVersion(
        tester,
        const VersionScreen(versionId: _id),
        api: api,
        locale: 'ar',
      );
      expect(find.text('مراجعة'), findsOneWidget);
      expect(find.text('وافق'), findsOneWidget);
      expect(find.text('رجّع'), findsOneWidget);
      expect(
        Directionality.of(tester.element(key('piece-title'))),
        TextDirection.rtl,
      );
      await tapKey(tester, 'action-approve');
      await tester.tap(key('approve-confirm'));
      await tester.pumpAndSettle();
      expect(find.textContaining('معتمدة. هتتنشر'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('routes', () {
    testWidgets('both version paths build the version screen', (tester) async {
      for (final path in ['/versions/$_id', '/inbox/approve/$_id']) {
        await pumpReviewRouter(tester, reviewRoutes(), path);
        expect(find.byType(VersionScreen), findsOneWidget, reason: path);
        expect(key('piece-title'), findsOneWidget);
      }
    });

    testWidgets('the feed path builds the rating feed', (tester) async {
      await pumpReviewRouter(tester, reviewRoutes(), '/inbox/rate');
      expect(key('rate-feed'), findsOneWidget);
    });
  });
}
