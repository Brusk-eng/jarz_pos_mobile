import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/config/studio_config.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/core/push/studio_push_router.dart';
import 'package:jarz_pos/src/studio/core/router/studio_router.dart';
import 'package:jarz_pos/src/studio/core/theme/studio_status_colors.dart';
import 'package:jarz_pos/src/studio/data/api/studio_api_base.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/models/studio_enums.dart';
import 'package:jarz_pos/src/studio/features/pieces/data/pieces_repository.dart';
import 'package:jarz_pos/src/studio/features/references/data/references_repository.dart';
import 'package:jarz_pos/src/studio/features/review/data/review_repository.dart';
import 'package:jarz_pos/src/studio/features/session/state/studio_session_notifier.dart';
import 'package:jarz_pos/src/studio/shared/placeholder_screen.dart';
import 'package:jarz_pos/src/studio/studio_app.dart';

import 'helpers.dart';

ProviderContainer containerWith(FakeStudioApi api) {
  final c = ProviderContainer(
    overrides: [studioApiProvider.overrideWithValue(api)],
  );
  addTearDown(c.dispose);
  return c;
}

Map<String, dynamic> lastParams(FakeStudioApi api, String key) =>
    api.callLog.lastWhere((c) => c.key == key).params;

Future<void> pumpFor(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('base_modified goes out with every write that may answer STALE', () {
    test(
      'version approve, fix and clear review send the version modified',
      () async {
        final api = FakeStudioApi(delay: Duration.zero);
        final c = containerWith(api);
        final v = await c.read(versionProvider('PC-00188-v1').future);
        final n = c.read(versionProvider('PC-00188-v1').notifier);

        await n.approve();
        expect(
          lastParams(api, 'versions.approve')['base_modified'],
          v.modified,
        );

        final afterApprove = c.read(versionProvider('PC-00188-v1')).value!;
        await n.clearReview();
        expect(
          lastParams(api, 'versions.clear_review')['base_modified'],
          afterApprove.modified,
        );

        final afterClear = c.read(versionProvider('PC-00188-v1')).value!;
        await n.fix('Cut the first two seconds');
        expect(
          lastParams(api, 'versions.fix')['base_modified'],
          afterClear.modified,
        );
      },
    );

    test('piece move and reference status send the object modified', () async {
      final api = FakeStudioApi(delay: Duration.zero);
      final c = containerWith(api);
      final p = await c.read(pieceProvider('PC-00188').future);
      await c.read(pieceProvider('PC-00188').notifier).move('Script');
      expect(lastParams(api, 'pieces.move')['base_modified'], p.modified);

      final r = await c.read(referenceProvider('ad-1114412864248331').future);
      await c
          .read(referenceProvider('ad-1114412864248331').notifier)
          .setStatus('Queued');
      expect(
        lastParams(api, 'references.update_status')['base_modified'],
        r.modified,
      );
    });

    test('the to-approve feed sends the card version modified', () async {
      final api = FakeStudioApi(delay: Duration.zero);
      final c = containerWith(api);
      final feed = await c.read(toApproveProvider.future);
      final first = feed.items.first.version;
      await c.read(toApproveProvider.notifier).approve(first.id);
      expect(
        lastParams(api, 'versions.approve')['base_modified'],
        first.modified,
      );
    });
  });

  group('explicit null', () {
    test('studioClear sends null, leaving it out sends nothing', () async {
      final api = FakeStudioApi(delay: Duration.zero);
      await api.settingsSetMyNotifications(
        quietFrom: studioClear,
        quietTo: studioClear,
      );
      var p = lastParams(api, 'settings.set_my_notifications');
      expect(p.containsKey('quiet_from'), isTrue);
      expect(p['quiet_from'], isNull);
      expect(p.containsKey('quiet_to'), isTrue);
      expect(p['quiet_to'], isNull);

      await api.settingsSetMyNotifications(digestEnabled: true);
      p = lastParams(api, 'settings.set_my_notifications');
      expect(p.containsKey('quiet_from'), isFalse);
      expect(p.containsKey('quiet_to'), isFalse);

      await api.settingsSetMyNotifications(
        quietFrom: '22:00',
        quietTo: '08:00',
      );
      p = lastParams(api, 'settings.set_my_notifications');
      expect(p['quiet_from'], '22:00');
      expect(p['quiet_to'], '08:00');
    });
  });

  group('ALREADY_DONE is shown, not swallowed', () {
    test('an entity write rethrows it and keeps the current state', () async {
      final api = FakeStudioApi(delay: Duration.zero);
      final c = containerWith(api);
      final v = await c.read(versionProvider('PC-00188-v1').future);
      final current = v.copyWith(
        reviewOutcome: ReviewOutcome.approved,
        awaitingReview: false,
      );
      api.failNext(
        'versions.approve',
        'ALREADY_DONE',
        current: current.toJson(),
      );
      await expectLater(
        c.read(versionProvider('PC-00188-v1').notifier).approve(),
        throwsA(isA<StudioAlreadyDone>()),
      );
      final now = c.read(versionProvider('PC-00188-v1')).value!;
      expect(now.reviewOutcome, ReviewOutcome.approved);
    });
  });

  group('post status colours', () {
    test('one per status, none of them a stage colour', () {
      for (final s in PostStatus.values) {
        expect(postStatusColors.containsKey(s), isTrue, reason: '$s');
      }
      final stageBackgrounds = {
        for (final c in stageColors.values) c.background.toARGB32(),
      };
      for (final e in postStatusColors.entries) {
        expect(
          stageBackgrounds.contains(e.value.background.toARGB32()),
          isFalse,
          reason: '${e.key} must not reuse a stage colour',
        );
      }
    });
  });

  group('router', () {
    // Every route shape of the push table (contract 1.9).
    const real = [
      '/today',
      '/inbox/approve',
      '/inbox/ideas',
      '/inbox/approve/PC-00188-v1',
      '/inbox/decisions/DEC-00007',
      '/calendar',
      '/calendar/post/SP-2026-00224',
      '/pieces',
      '/pieces/PC-00188',
      '/more',
      '/references',
      '/paid',
      '/results',
      '/reports',
      '/settings',
      '/shoots',
      '/shoots/SHOOT-0006',
      '/assets',
      '/prep/abc123',
    ];
    testWidgets('every route of the push table opens a real screen', (
      tester,
    ) async {
      usePhone(tester);
      final c = await pumpStudio(tester);
      for (final path in real) {
        await goTo(tester, c, path);
        expect(currentLocation(c), studioAppRoute(path));
        expect(
          find.byType(StudioPlaceholderScreen),
          findsNothing,
          reason: path,
        );
        expect(tester.takeException(), isNull, reason: path);
      }
    });

    testWidgets('/inbox/rate is the rating feed, above the shell', (
      tester,
    ) async {
      usePhone(tester);
      final c = await pumpStudio(tester);
      await goTo(tester, c, '/inbox/rate');
      expect(currentLocation(c), '/inbox/rate');
      expect(find.byKey(const ValueKey('shell-bar')), findsNothing);
    });

    testWidgets('a deep link signed out goes to login and comes back', (
      tester,
    ) async {
      usePhone(tester);
      final api = FakeStudioApi(delay: Duration.zero)
        ..failAlways('session.me', 'UNAUTHENTICATED');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studioFakeProvider.overrideWithValue(true),
            studioApiProvider.overrideWithValue(api),
            studioFakeRoleProvider.overrideWithValue('founder'),
          ],
          child: const StudioApp(),
        ),
      );
      await pumpFor(tester);
      final c = ProviderScope.containerOf(
        tester.element(find.byType(StudioApp)),
      );
      c.read(studioRouterProvider).go('/pieces/PC-00188');
      await pumpFor(tester);
      final loc = currentLocation(c);
      expect(loc, startsWith('/login'));
      expect(Uri.parse(loc).queryParameters['from'], '/pieces/PC-00188');

      api.clearFailures();
      final reloaded = c.read(studioSessionProvider.notifier).reload();
      await pumpFor(tester);
      await reloaded;

      expect(currentLocation(c), '/pieces/PC-00188');
    });
  });

  testWidgets('the Inbox tab carries the badge', (tester) async {
    usePhone(tester);
    await pumpStudio(tester);
    // inbox.counts fixture: total 11 plus 4 unread notifications.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('inbox-badge')),
        matching: find.text('15'),
      ),
      findsOneWidget,
    );
  });
}
