import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';

import 'pieces/harness.dart';

void main() {
  group('Calendar opens on today', () {
    testWidgets('the week scrolls so today is in view', (tester) async {
      await pumpFeature(tester, location: '/calendar', height: 640);
      final today = find.byKey(const ValueKey('day-2026-11-25'));
      expect(today, findsOneWidget);
      final top = tester.getTopLeft(today).dy;
      expect(top, greaterThanOrEqualTo(0));
      expect(top, lessThan(640));
    });
  });

  group('Add a version', () {
    testWidgets('with nothing picked it says why the button is off', (
      tester,
    ) async {
      await pumpFeature(
        tester,
        location: '/pieces/PC-00163/add-version',
        height: 1200,
      );
      expect(
        find.byKey(const ValueKey('add-version-pick-first')),
        findsOneWidget,
      );
      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('add-version-save')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('a story piece says "Add the frames"', (tester) async {
      await pumpFeature(
        tester,
        location: '/pieces/PC-00163',
        height: 3500,
        fixtures: patchedFixtures({
          'pieces.get': (j) {
            (j as Map)['format'] = 'story';
            j['actions'] = ['add_version', 'edit'];
          },
        }),
      );
      final b = find.byKey(const ValueKey('add-version'));
      await tester.ensureVisible(b);
      expect(
        find.descendant(of: b, matching: find.text('Add the frames')),
        findsOneWidget,
      );
    });
  });

  group('Story frames', () {
    testWidgets('the post says how many frames are decided, then done', (
      tester,
    ) async {
      final frames =
          (jsonDecode(studioFixtures['calendar.frame_set']!) as Map)['frames']
              as List;
      expect(frames.length, greaterThan(0));
      await pumpFeature(
        tester,
        location: '/calendar/post/SP-2026-00310',
        height: 3200,
        fixtures: patchedFixtures({
          'calendar.post_get': (j) {
            (j as Map)['frames'] = [
              for (final (i, f) in frames.indexed)
                {...f as Map, 'status': i == 0 ? 'posted' : '', 'reason': null},
            ];
            j['actions'] = ['frame_set'];
          },
        }),
      );
      final progress = find.byKey(const ValueKey('frames-progress'));
      await tester.ensureVisible(progress);
      expect(
        tester.widget<Text>(progress).data,
        '1 of ${frames.length} frames decided',
      );
      expect(
        find.byKey(const ValueKey('frames-all-decided')),
        frames.length == 1 ? findsOneWidget : findsNothing,
      );
    });

    testWidgets('every frame decided: the set shows done', (tester) async {
      final frames =
          (jsonDecode(studioFixtures['calendar.frame_set']!) as Map)['frames']
              as List;
      await pumpFeature(
        tester,
        location: '/calendar/post/SP-2026-00310',
        height: 3200,
        fixtures: patchedFixtures({
          'calendar.post_get': (j) {
            (j as Map)['frames'] = [
              for (final (i, f) in frames.indexed)
                {
                  ...f as Map,
                  'status': i == 0 ? 'posted' : 'skipped',
                  'reason': i == 0 ? null : 'Kitchen was closed',
                },
            ];
            j['actions'] = ['frame_set'];
          },
        }),
      );
      final done = find.byKey(const ValueKey('frames-all-decided'));
      await tester.ensureVisible(done);
      expect(done, findsOneWidget);
      expect(find.textContaining('Kitchen was closed'), findsWidgets);
    });
  });
}
