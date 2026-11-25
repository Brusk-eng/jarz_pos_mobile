import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/config/studio_config.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_locale.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/core/offline/kv_store.dart';
import 'package:jarz_pos/src/studio/core/offline/reachability.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/features/shoots/state/on_set_state.dart';
import 'package:jarz_pos/src/studio/studio_app.dart';

import 'helpers.dart';

Future<ProviderContainer> _app(
  WidgetTester tester,
  FakeStudioApi api, {
  String locale = 'en',
}) async {
  usePhone(tester, height: 1800);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studioFakeProvider.overrideWithValue(true),
        studioApiProvider.overrideWithValue(api),
        studioFakeRoleProvider.overrideWithValue(api.role),
        studioLocaleProvider.overrideWith((ref) => Locale(locale)),
        // On set keeps its copy on the phone: memory here, no probe timers.
        studioKvStoreProvider.overrideWithValue(MemoryKvStore()),
        reachabilityIntervalProvider.overrideWithValue(null),
        reachabilityProbeProvider.overrideWithValue(() async => true),
        onSetClockProvider.overrideWithValue(
          () => DateTime.parse('2026-11-25T10:00:00+02:00'),
        ),
      ],
      child: const StudioApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(StudioApp)));
}

FakeStudioApi _api(String role) =>
    FakeStudioApi(role: role, delay: Duration.zero, textDecisions: true, storyFrames: true);

Future<void> _tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  group('9. Story lead: post the frames', () {
    testWidgets('open from Today, see the frames in order, post, skip, finish', (
      tester,
    ) async {
      final api = _api('story');
      final c = await _app(tester, api);
      // Today: the Stories line, with its button.
      expect(find.byKey(const ValueKey('today-block-stories')), findsOne);
      await _tapKey(tester, 'today-line-SP-2026-00310');
      expect(find.byKey(const ValueKey('frames-progress')), findsOneWidget);

      // Four frames, in order, photos and a clip.
      for (var i = 1; i <= 4; i++) {
        expect(find.byKey(ValueKey('frame-$i')), findsOneWidget);
      }
      final ys = [
        for (var i = 1; i <= 4; i++)
          tester.getTopLeft(find.byKey(ValueKey('frame-$i'))).dy,
      ];
      expect([...ys]..sort(), ys);
      expect(find.byKey(const ValueKey('frames-progress')), findsOneWidget);

      // Mark frame 1 posted.
      await _tapKey(tester, 'frame-posted-1');
      expect(
        api.callLog.lastWhere((x) => x.key == 'calendar.frame_set').params,
        containsPair('status', 'posted'),
      );
      expect(find.text('Posted'), findsWidgets);

      // Skip frame 2: a reason is needed.
      await _tapKey(tester, 'frame-skip-2');
      await tester.tap(find.byKey(const ValueKey('ask-confirm')));
      await tester.pumpAndSettle();
      expect(
        api.callLog.where((x) => x.key == 'calendar.frame_set').length,
        1,
        reason: 'no reason, no write',
      );
      await tester.enterText(
        find.byKey(const ValueKey('ask-text')),
        'Same picture as yesterday',
      );
      await tester.tap(find.byKey(const ValueKey('ask-confirm')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Same picture as yesterday'), findsOneWidget);

      // The story is not posted until every frame is decided.
      expect(find.byKey(const ValueKey('frames-all-decided')), findsNothing);
      await _tapKey(tester, 'frame-posted-3');
      await _tapKey(tester, 'frame-posted-4');

      // Every frame decided and one posted: the story is posted, by itself.
      expect(find.byKey(const ValueKey('frames-all-decided')), findsOneWidget);
      expect(find.byKey(const ValueKey('frame-posted-4')), findsNothing);
      await goTo(tester, c, '/today');
      expect(find.byKey(const ValueKey('today-block-stories')), findsNothing);
    });
  });

  group('6. On set: a note and a true heading', () {
    testWidgets('a note can be left on a shot and reaches the server', (
      tester,
    ) async {
      final api = _api('creator');
      final c = await _app(tester, api);
      await goTo(tester, c, '/shoots/SHOOT-0006/on-set');
      expect(find.byKey(const ValueKey('shot-note')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('shot-note')),
        'Take 3 has the door sound',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onset-close')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('shoots.shot_note'));
      expect(
        api.callLog.lastWhere((x) => x.key == 'shoots.shot_note').params['note'],
        'Take 3 has the door sound',
      );
    });

    testWidgets('ticking shots updates the count in the heading', (
      tester,
    ) async {
      final api = _api('founder');
      final c = await _app(tester, api);
      await goTo(tester, c, '/shoots/SHOOT-0006/on-set');
      expect(find.text('1 of 3 shots filmed'), findsOneWidget);
      // The page opens on the first shot still to film: tick it, then the next.
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const ValueKey('onset-filmed')));
        await tester.pumpAndSettle();
        if (i == 0) {
          expect(find.text('2 of 3 shots filmed'), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('onset-next')));
          await tester.pumpAndSettle();
        }
      }
      expect(find.text('Every shot is filmed.'), findsWidgets);
      expect(find.text('2 of 3 shots filmed'), findsNothing);
    });
  });

  group('7. The "didn\'t go out" screen', () {
    testWidgets('promises no retry the post cannot do and names people', (
      tester,
    ) async {
      final api = _api('founder');
      final c = await _app(tester, api);
      await goTo(tester, c, '/calendar/drift');
      expect(find.textContaining('try it again'), findsNothing);
      expect(find.textContaining('Waiting: claude'), findsNothing);
      expect(find.textContaining('claude'), findsNothing);
      expect(find.textContaining('Claude'), findsWidgets);
    });

    testWidgets('a post that cannot be retried has no Try again button', (
      tester,
    ) async {
      final api = _api('founder');
      final c = await _app(tester, api);
      await goTo(tester, c, '/calendar/drift');
      expect(
        find.byKey(const ValueKey('drift-retry-SP-2026-00175')),
        findsNothing,
      );
    });
  });

  group('10. Creator: Results', () {
    testWidgets('the creator sees the scorecard and may only add a line', (
      tester,
    ) async {
      final api = _api('creator');
      final c = await _app(tester, api);
      await goTo(tester, c, '/more');
      expect(find.byKey(const ValueKey('more-results')), findsOneWidget);
      await _tapKey(tester, 'more-results');
      expect(currentLocation(c), '/more/results');
      expect(find.byKey(const ValueKey('add-line')), findsOneWidget);
      expect(find.byKey(const ValueKey('mark-reviewed')), findsNothing);
      expect(find.byKey(const ValueKey('go-by-piece')), findsNothing);
      expect(find.byKey(const ValueKey('go-summary')), findsNothing);
    });

    testWidgets('the story lead has no Results', (tester) async {
      final c = await _app(tester, _api('story'));
      await goTo(tester, c, '/more');
      expect(find.byKey(const ValueKey('more-results')), findsNothing);
    });
  });

  group('11. Arabic role label', () {
    testWidgets('the creator is «صانع محتوى»', (tester) async {
      await _app(tester, _api('creator'), locale: 'ar');
      expect(find.textContaining('صانع محتوى'), findsWidgets);
      expect(find.textContaining('كرييتور'), findsNothing);
    });
  });
}
