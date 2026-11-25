import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';

import '../pieces/harness.dart';

const _path = '/calendar/post/SP-2026-00221';

Map<String, dynamic> _postJson() =>
    jsonDecode(studioFixtures['calendar.post_get']!) as Map<String, dynamic>;

Map<String, void Function(dynamic)> _post(void Function(Map j) edit) => {
  'calendar.post_get': (j) => edit(j as Map),
};

Future<void> _scrollTo(WidgetTester tester, Finder f) => tester
    .scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);

void main() {
  group('Post screen: reading', () {
    testWidgets('shows creative, caption, channel, slot, who, approval', (
      tester,
    ) async {
      await pumpFeature(tester, location: _path, height: 3000);
      expect(find.text('Gathering Box, opened'), findsWidgets);
      expect(find.byKey(const ValueKey('post-creative')), findsOneWidget);
      expect(find.byKey(const ValueKey('post-channel')), findsOneWidget);
      expect(find.text('Feed carousel'), findsOneWidget);
      // Slot in Cairo time exactly as the data says: 25 Nov, 16:00.
      expect(find.textContaining('Wed 25 Nov, 16:00'), findsOneWidget);
      expect(find.textContaining('Posted by hand'), findsOneWidget);
      expect(find.byKey(const ValueKey('post-approval')), findsOneWidget);
    });

    testWidgets('caption in Arabic reads right to left', (tester) async {
      await pumpFeature(
        tester,
        location: _path,
        height: 3000,
        fixtures: patchedFixtures(
          _post((j) => j['caption'] = 'عزومة تليق بيك'),
        ),
      );
      final text = tester.widget<Text>(
        find.byKey(const ValueKey('post-caption')),
      );
      expect(text.textDirection, TextDirection.rtl);
    });

    testWidgets('a hashtag line under Arabic text reads left to right', (
      tester,
    ) async {
      await pumpFeature(
        tester,
        location: _path,
        height: 3000,
        fixtures: patchedFixtures(
          _post((j) => j['caption'] = 'عزومة تليق بيك\n#Jarz #JarzEgypt'),
        ),
      );
      final ar = tester.widget<Text>(
        find.byKey(const ValueKey('post-caption-line-0')),
      );
      final tags = tester.widget<Text>(
        find.byKey(const ValueKey('post-caption-line-1')),
      );
      expect(ar.textDirection, TextDirection.rtl);
      expect(tags.textDirection, TextDirection.ltr);
    });

    testWidgets('the publish log lists what happened', (tester) async {
      await pumpFeature(
        tester,
        location: _path,
        height: 3000,
        fixtures: patchedFixtures(
          _post((j) {
            j['posted_at'] = '2026-11-25T16:02:00+02:00';
            j['posted_how'] = 'system';
            j['posted_by'] = 'The system';
            j['last_error'] = 'The token ran out';
            j['permalink'] = 'https://instagram.example/p/abc';
          }),
        ),
      );
      await _scrollTo(tester, find.text('WHAT HAPPENED'));
      expect(find.textContaining('Went out at 25 Nov, 16:02'), findsOneWidget);
      expect(
        find.textContaining('Posted by the system by The system'),
        findsOneWidget,
      );
      expect(find.text('It failed: The token ran out'), findsOneWidget);
      expect(find.byKey(const ValueKey('post-permalink')), findsOneWidget);
    });

    testWidgets('results show once read', (tester) async {
      await pumpFeature(
        tester,
        location: _path,
        height: 3000,
        fixtures: patchedFixtures(
          _post(
            (j) => j['reads'] = [
              {
                'post_id': 'SP-2026-00221',
                'piece_id': 'PC-00112',
                'bucket': '72h',
                'opens_on': '2026-11-28',
                'due': true,
                'filed': true,
                'reach': 900,
                'views': 2000,
                'shares': 5,
                'saves': 9,
                'missing': [],
              },
            ],
          ),
        ),
      );
      await _scrollTo(tester, find.text('After 72 hours'));
      expect(find.text('Reach: 900'), findsOneWidget);
    });

    testWidgets('links to the piece and the version', (tester) async {
      final h = await pumpFeature(tester, location: _path, height: 3000);
      await tester.tap(find.byKey(const ValueKey('open-piece')));
      await tester.pumpAndSettle();
      expect(locationOf(h), startsWith('/pieces/PC-'));
    });

    testWidgets('error state with retry', (tester) async {
      final api = FakeStudioApi(role: 'founder', delay: Duration.zero)
        ..failNext('calendar.post_get', 'SERVER_ERROR');
      await pumpFeature(tester, location: _path, height: 3000, api: api);
      expect(find.byKey(const ValueKey('error-text')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('post-body')), findsOneWidget);
    });

    testWidgets('the help sheet opens', (tester) async {
      await pumpFeature(tester, location: _path, height: 3000);
      await tester.tap(find.byKey(const ValueKey('help')));
      await tester.pumpAndSettle();
      expect(find.text('The post screen'), findsOneWidget);
    });

    testWidgets('Arabic', (tester) async {
      await pumpFeature(tester, location: _path, height: 3000, locale: 'ar');
      expect(find.text('الكابشن'), findsWidgets);
      expect(find.text('الميعاد'), findsWidgets);
    });
  });

  group('Post screen: buttons come only from actions', () {
    testWidgets('the fixture offers edit, move, wont_post, mark_posted', (
      tester,
    ) async {
      await pumpFeature(tester, location: _path, height: 3000);
      expect(find.byKey(const ValueKey('edit')), findsOneWidget);
      expect(find.byKey(const ValueKey('post-move')), findsOneWidget);
      await _scrollTo(tester, find.byKey(const ValueKey('mark-posted')));
      expect(find.byKey(const ValueKey('wont-post')), findsOneWidget);
      // Not listed, so not drawn.
      expect(find.byKey(const ValueKey('retry')), findsNothing);
      expect(find.byKey(const ValueKey('set-caption')), findsNothing);
    });

    testWidgets('no actions: read only', (tester) async {
      await pumpFeature(
        tester,
        location: _path,
        height: 3000,
        role: 'creator',
        fixtures: patchedFixtures(_post((j) => j['actions'] = [])),
      );
      expect(find.byKey(const ValueKey('edit')), findsNothing);
      expect(find.byKey(const ValueKey('post-move')), findsNothing);
      expect(find.byKey(const ValueKey('post-actions')), findsNothing);
    });

    testWidgets('retry and set_caption show when listed', (tester) async {
      await pumpFeature(
        tester,
        location: _path,
        height: 3000,
        fixtures: patchedFixtures(
          _post((j) => j['actions'] = ['retry', 'set_caption']),
        ),
      );
      expect(find.byKey(const ValueKey('set-caption')), findsOneWidget);
      await _scrollTo(tester, find.byKey(const ValueKey('retry')));
      expect(find.byKey(const ValueKey('mark-posted')), findsNothing);
    });
  });

  group('Post screen: acting', () {
    testWidgets('I posted it, with a link', (tester) async {
      final h = await pumpFeature(tester, location: _path, height: 3000);
      await _scrollTo(tester, find.byKey(const ValueKey('mark-posted')));
      await tester.tap(find.byKey(const ValueKey('mark-posted')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('ask-text')),
        'https://instagram.example/p/xyz',
      );
      await tester.tap(find.byKey(const ValueKey('ask-confirm')));
      await tester.pumpAndSettle();
      expect(h.api.calls, contains('calendar.post_mark_posted'));
      expect(find.textContaining('Marked as posted'), findsOneWidget);
    });

    testWidgets('I posted it works without a link', (tester) async {
      final h = await pumpFeature(tester, location: _path, height: 3000);
      await _scrollTo(tester, find.byKey(const ValueKey('mark-posted')));
      await tester.tap(find.byKey(const ValueKey('mark-posted')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ask-confirm')));
      await tester.pumpAndSettle();
      expect(h.api.calls, contains('calendar.post_mark_posted'));
    });

    testWidgets(
      'mark posted refused (version not approved) lists the problems',
      (tester) async {
        final api = FakeStudioApi(role: 'founder', delay: Duration.zero)
          ..failNext(
            'calendar.post_mark_posted',
            'GATE_FAILED',
            problems: [
              {
                'code': 'not_approved',
                'message': 'The version is not approved yet',
              },
            ],
          );
        await pumpFeature(tester, location: _path, height: 3000, api: api);
        await _scrollTo(tester, find.byKey(const ValueKey('mark-posted')));
        await tester.tap(find.byKey(const ValueKey('mark-posted')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('ask-confirm')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('gate-sheet')), findsOneWidget);
        expect(find.text('The version is not approved yet'), findsOneWidget);
      },
    );

    testWidgets("Won't post needs a reason", (tester) async {
      final h = await pumpFeature(tester, location: _path, height: 3000);
      await _scrollTo(tester, find.byKey(const ValueKey('wont-post')));
      await tester.tap(find.byKey(const ValueKey('wont-post')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ask-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Write the reason first.'), findsOneWidget);
      expect(h.api.calls, isNot(contains('calendar.post_wont_post')));
      await tester.enterText(
        find.byKey(const ValueKey('ask-text')),
        'Held for next week',
      );
      await tester.tap(find.byKey(const ValueKey('ask-confirm')));
      await tester.pumpAndSettle();
      expect(h.api.calls, contains('calendar.post_wont_post'));
      expect(find.text('Marked as will not post.'), findsOneWidget);
    });

    testWidgets('try again sends the post out again', (tester) async {
      final h = await pumpFeature(
        tester,
        location: _path,
        height: 3000,
        fixtures: patchedFixtures(_post((j) => j['actions'] = ['retry'])),
      );
      await _scrollTo(tester, find.byKey(const ValueKey('retry')));
      await tester.tap(find.byKey(const ValueKey('retry')));
      await tester.pumpAndSettle();
      expect(h.api.calls, contains('calendar.post_retry'));
      expect(find.text('Sent again.'), findsOneWidget);
    });

    testWidgets('edit the caption', (tester) async {
      final h = await pumpFeature(
        tester,
        location: _path,
        height: 3000,
        fixtures: patchedFixtures(_post((j) => j['actions'] = ['set_caption'])),
      );
      await tester.tap(find.byKey(const ValueKey('set-caption')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('ask-text')),
        'عزومة تليق بيك',
      );
      await tester.tap(find.byKey(const ValueKey('ask-confirm')));
      await tester.pumpAndSettle();
      expect(h.api.calls, contains('calendar.post_set'));
      expect(find.text('Caption saved.'), findsOneWidget);
    });

    for (final c in [
      ('ALREADY_DONE', 'Already done'),
      ('SHADOW_MODE', 'The Studio is not switched on yet'),
      ('NOT_PERMITTED', 'Your role cannot do that.'),
    ]) {
      testWidgets('${c.$1} on mark posted', (tester) async {
        final api = FakeStudioApi(role: 'founder', delay: Duration.zero)
          ..failNext(
            'calendar.post_mark_posted',
            c.$1,
            current: c.$1 == 'ALREADY_DONE' ? _postJson() : null,
          );
        await pumpFeature(tester, location: _path, height: 3000, api: api);
        await _scrollTo(tester, find.byKey(const ValueKey('mark-posted')));
        await tester.tap(find.byKey(const ValueKey('mark-posted')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('ask-confirm')));
        await tester.pumpAndSettle();
        expect(find.textContaining(c.$2), findsOneWidget);
      });
    }

    testWidgets('STALE on mark posted shows the latest', (tester) async {
      final api = FakeStudioApi(role: 'founder', delay: Duration.zero)
        ..failNext('calendar.post_mark_posted', 'STALE', current: _postJson());
      await pumpFeature(tester, location: _path, height: 3000, api: api);
      await _scrollTo(tester, find.byKey(const ValueKey('mark-posted')));
      await tester.tap(find.byKey(const ValueKey('mark-posted')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ask-confirm')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This changed since you opened it. Refresh the page and try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('move opens the slot form with only day and time', (
      tester,
    ) async {
      final h = await pumpFeature(tester, location: _path, height: 3000);
      await tester.tap(find.byKey(const ValueKey('post-move')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('slot-form')), findsOneWidget);
      expect(find.byKey(const ValueKey('slot-caption')), findsNothing);
      expect(find.byKey(const ValueKey('slot-channel')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('slot-save')));
      await tester.pumpAndSettle();
      expect(h.api.calls, contains('calendar.post_move'));
    });
  });

  group('Post screen: story frames', () {
    testWidgets('frames show; Posted and Skip only with frame_set', (
      tester,
    ) async {
      final frames =
          (jsonDecode(studioFixtures['calendar.frame_set']!) as Map)['frames']
              as List;
      expect(frames, isNotEmpty);
      final pos = (frames.first as Map)['position'];
      final h = await pumpFeature(
        tester,
        location: _path,
        height: 3000,
        fixtures: patchedFixtures({
          'calendar.post_get': (j) {
            (j as Map)['frames'] = frames;
            j['actions'] = ['frame_set'];
          },
        }),
      );
      await _scrollTo(tester, find.byKey(ValueKey('frame-$pos')));
      expect(find.byKey(ValueKey('frame-posted-$pos')), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('frame-posted-$pos')));
      await tester.pumpAndSettle();
      expect(h.api.calls, contains('calendar.frame_set'));
      expect(find.text('Frame saved.'), findsOneWidget);
    });

    testWidgets('frames without frame_set have no buttons', (tester) async {
      final frames =
          (jsonDecode(studioFixtures['calendar.frame_set']!) as Map)['frames']
              as List;
      final pos = (frames.first as Map)['position'];
      await pumpFeature(
        tester,
        location: _path,
        height: 3000,
        fixtures: patchedFixtures({
          'calendar.post_get': (j) {
            (j as Map)['frames'] = frames;
            j['actions'] = [];
          },
        }),
      );
      await _scrollTo(tester, find.byKey(ValueKey('frame-$pos')));
      expect(find.byKey(ValueKey('frame-posted-$pos')), findsNothing);
    });
  });
}
