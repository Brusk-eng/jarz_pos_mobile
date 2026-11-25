import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/offline/kv_store.dart';
import 'package:jarz_pos/src/studio/core/offline/reachability.dart';
import 'package:jarz_pos/src/studio/data/models/studio_enums.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';
import 'package:jarz_pos/src/studio/features/shoots/presentation/on_set_screen.dart';
import 'package:jarz_pos/src/studio/features/shoots/presentation/public_prep_screen.dart';
import 'package:jarz_pos/src/studio/features/shoots/presentation/shoot_edit_screen.dart';
import 'package:jarz_pos/src/studio/features/shoots/presentation/shoot_screen.dart';
import 'package:jarz_pos/src/studio/features/shoots/presentation/shoots_list_screen.dart';
import 'package:jarz_pos/src/studio/features/shoots/state/on_set_state.dart';

import 'shoots_test_utils.dart';

void main() {
  late ShootTestApi api;

  setUp(() => api = ShootTestApi());

  group('shoot list', () {
    testWidgets('upcoming and past tabs; opening it downloads the shoots', (
      tester,
    ) async {
      final c = await pumpShoot(tester, const ShootsListScreen(), api: api);
      expect(find.byKey(const ValueKey('shoot-SHOOT-0006')), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Plan a shoot'), findsOneWidget);
      expect(find.textContaining('shots filmed'), findsWidgets);
      expect(c.read(onSetProvider).shoots.keys, contains('SHOOT-0006'));
      await tester.tap(find.byKey(const ValueKey('tab-past')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('empty-purpose')), findsOneWidget);
    });

    testWidgets(
      'empty: says what to do first, with the plan button for a lead',
      (tester) async {
        api.listItems = const [];
        await pumpShoot(tester, const ShootsListScreen(), api: api);
        expect(find.byKey(const ValueKey('empty-purpose')), findsOneWidget);
        expect(find.byKey(const ValueKey('empty-first-step')), findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, 'Plan a shoot'),
          findsOneWidget,
        );
      },
    );

    testWidgets('a creator sees no plan button', (tester) async {
      api.listItems = const [];
      await pumpShoot(
        tester,
        const ShootsListScreen(),
        api: api,
        canPlan: false,
      );
      expect(find.byKey(const ValueKey('plan-shoot')), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Plan a shoot'), findsNothing);
    });

    testWidgets('error: plain words and a try again button', (tester) async {
      api.failNext('shoots.list', 'SERVER_ERROR');
      await pumpShoot(tester, const ShootsListScreen(), api: api);
      expect(find.byKey(const ValueKey('error-text')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('shoot-SHOOT-0006')), findsOneWidget);
    });

    testWidgets('loading shows the skeleton first', (tester) async {
      await pumpShoot(
        tester,
        const ShootsListScreen(),
        api: api,
        settle: false,
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('skeleton')), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('Arabic: RTL and Arabic words', (tester) async {
      await pumpShoot(tester, const ShootsListScreen(), api: api, locale: 'ar');
      expect(find.text('الجاية'), findsOneWidget);
      expect(find.text('خطّط لتصوير'), findsOneWidget);
    });
  });

  group('shoot page', () {
    testWidgets(
      'plan, prep checklist, shots grouped by piece, buttons from actions',
      (tester) async {
        await pumpShoot(
          tester,
          const ShootScreen(shootId: 'SHOOT-0006'),
          api: api,
        );
        expect(find.byKey(const ValueKey('plan-when')), findsOneWidget);
        expect(find.byKey(const ValueKey('start-on-set')), findsOneWidget);
        expect(find.byKey(const ValueKey('share-prep')), findsOneWidget);
        expect(find.byKey(const ValueKey('add-shot')), findsOneWidget);
        expect(find.byKey(const ValueKey('edit')), findsOneWidget);
        expect(find.byKey(const ValueKey('shot-SHOT-00108')), findsOneWidget);
        // Grouped by the first piece a shot serves.
        expect(find.byKey(const ValueKey('group-PC-00101')), findsOneWidget);
        expect(find.byKey(const ValueKey('group-PC-00188')), findsOneWidget);
        expect(find.byKey(const ValueKey('prep-TASK-000191')), findsWidgets);
      },
    );

    testWidgets('with no actions there are no buttons', (tester) async {
      api.noActions = true;
      await pumpShoot(
        tester,
        const ShootScreen(shootId: 'SHOOT-0006'),
        api: api,
      );
      expect(find.byKey(const ValueKey('start-on-set')), findsNothing);
      expect(find.byKey(const ValueKey('share-prep')), findsNothing);
      expect(find.byKey(const ValueKey('add-shot')), findsNothing);
      expect(find.byKey(const ValueKey('edit')), findsNothing);
    });

    testWidgets('opening a shoot stores it; offline later it still shows', (
      tester,
    ) async {
      final kv = MemoryKvStore();
      await pumpShoot(
        tester,
        const ShootScreen(shootId: 'SHOOT-0006'),
        api: api,
        kv: kv,
      );
      expect(await kv.get('onset:shoot:SHOOT-0006'), isNotNull);

      // A new run of the app, no connection.
      api.offline = true;
      await tester.pumpWidget(const SizedBox());
      final c = await pumpShoot(
        tester,
        const ShootScreen(shootId: 'SHOOT-0006'),
        api: api,
        kv: kv,
      );
      expect(find.byKey(const ValueKey('shot-SHOT-00108')), findsOneWidget);
      expect(find.byKey(const ValueKey('stored-copy')), findsOneWidget);
      expect(c.read(studioReachabilityProvider), isFalse);
    });

    testWidgets('not stored and no connection: an error with try again', (
      tester,
    ) async {
      api.offline = true;
      await pumpShoot(
        tester,
        const ShootScreen(shootId: 'SHOOT-0006'),
        api: api,
      );
      expect(find.byKey(const ValueKey('error-text')), findsOneWidget);
    });

    testWidgets('a shoot that is gone says so', (tester) async {
      api.failNext('shoots.get', 'NOT_FOUND');
      await pumpShoot(
        tester,
        const ShootScreen(shootId: 'SHOOT-0006'),
        api: api,
      );
      expect(
        find.text('This shoot is not there. Go back to the shoot list.'),
        findsOneWidget,
      );
    });

    testWidgets('prep tick is saved; offline it says it needs a connection', (
      tester,
    ) async {
      final c = await pumpShoot(
        tester,
        const ShootScreen(shootId: 'SHOOT-0006'),
        api: api,
      );
      final tile = find.byType(CheckboxListTile).first;
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(api.prepCalls.length, 1);

      api.offline = true;
      await tester.tap(find.byType(CheckboxListTile).at(1));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'The prep list needs a connection. Try again when you are online.',
        ),
        findsOneWidget,
      );
      expect(c.read(studioReachabilityProvider), isFalse);
    });

    testWidgets(
      'share sheet: link, copy, WhatsApp; new link for the founder only',
      (tester) async {
        final opened = <Uri>[];
        await pumpShoot(
          tester,
          const ShootScreen(shootId: 'SHOOT-0006'),
          api: api,
          opened: opened,
        );
        await tester.ensureVisible(find.byKey(const ValueKey('share-prep')));
        await tester.tap(find.byKey(const ValueKey('share-prep')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('share-url')), findsOneWidget);
        expect(find.byKey(const ValueKey('share-regenerate')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('share-whatsapp')));
        await tester.pumpAndSettle();
        expect(opened.single.host, 'wa.me');
      },
    );

    testWidgets('share sheet: a lead has no new-link button', (tester) async {
      await pumpShoot(
        tester,
        const ShootScreen(shootId: 'SHOOT-0006'),
        api: api,
        founder: false,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('share-prep')));
      await tester.tap(find.byKey(const ValueKey('share-prep')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('share-url')), findsOneWidget);
      expect(find.byKey(const ValueKey('share-regenerate')), findsNothing);
    });

    testWidgets('add a shot', (tester) async {
      await pumpShoot(
        tester,
        const ShootScreen(shootId: 'SHOOT-0006'),
        api: api,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('add-shot')));
      await tester.tap(find.byKey(const ValueKey('add-shot')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('shot-save')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('shot-error')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('shot-what')),
        'Spoon lifts a layer',
      );
      await tester.tap(find.byKey(const ValueKey('shot-save')));
      await tester.pumpAndSettle();
      expect(api.shotSets.single['what'], 'Spoon lifts a layer');
    });
  });

  group('edit', () {
    testWidgets('a shoot that cannot load shows an error with a retry', (
      tester,
    ) async {
      api.offline = true;
      await pumpShoot(
        tester,
        const ShootEditScreen(shootId: 'SHOOT-9999'),
        api: api,
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('error-text')), findsOneWidget);
      api.offline = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('f-title')), findsOneWidget);
    });

    testWidgets('plan a new shoot needs a name, then creates it', (
      tester,
    ) async {
      await pumpShoot(tester, const ShootEditScreen(), api: api);
      await tester.tap(find.byKey(const ValueKey('f-save')));
      await tester.pumpAndSettle();
      expect(find.text('Give the shoot a name.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('f-title')),
        'Mango set',
      );
      await tester.tap(find.byKey(const ValueKey('f-save')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('shoots.create'));
    });

    testWidgets('a server validation message shows at its field', (
      tester,
    ) async {
      await pumpShoot(
        tester,
        const ShootEditScreen(shootId: 'SHOOT-0006'),
        api: api,
      );
      await tester.enterText(find.byKey(const ValueKey('f-place')), 'Studio B');
      api.failNext(
        'shoots.update',
        'VALIDATION',
        message: 'Ready needs a date.',
        field: 'place',
      );
      await tester.tap(find.byKey(const ValueKey('f-save')));
      await tester.pumpAndSettle();
      expect(find.text('Ready needs a date.'), findsOneWidget);
    });

    testWidgets('STALE shows their version and a plain notice', (tester) async {
      final base = (await tester.runAsync(
        () => ShootTestApi().shootsGet(shootId: 'SHOOT-0006'),
      ))!;
      api.failNext(
        'shoots.update',
        'STALE',
        current: base.copyWith(title: 'Changed by Ali').toJson(),
      );
      await pumpShoot(
        tester,
        const ShootEditScreen(shootId: 'SHOOT-0006'),
        api: api,
      );
      await tester.enterText(find.byKey(const ValueKey('f-place')), 'Studio B');
      await tester.tap(find.byKey(const ValueKey('f-save')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('edit-banner')), findsOneWidget);
      expect(find.text('Changed by Ali'), findsOneWidget);
    });

    testWidgets('SHADOW_MODE: the Studio is not switched on yet', (
      tester,
    ) async {
      await pumpShoot(
        tester,
        const ShootEditScreen(shootId: 'SHOOT-0006'),
        api: api,
      );
      await tester.enterText(find.byKey(const ValueKey('f-place')), 'Studio B');
      api.failNext('shoots.update', 'SHADOW_MODE');
      await tester.tap(find.byKey(const ValueKey('f-save')));
      await tester.pumpAndSettle();
      expect(
        find.text('The Studio is not switched on yet, so nothing was changed.'),
        findsOneWidget,
      );
    });
  });

  group('On set', () {
    testWidgets('opens at the first shot still to film, with the brief', (
      tester,
    ) async {
      await pumpShoot(
        tester,
        const OnSetScreen(shootId: 'SHOOT-0006'),
        api: api,
      );
      expect(find.text('Shot 2 of 3'), findsOneWidget);
      expect(find.byKey(const ValueKey('onset-filmed')), findsOneWidget);
      expect(find.textContaining('Four jars land'), findsOneWidget);
      expect(find.byKey(const ValueKey('shot-note')), findsOneWidget);
      // The note sits under the shot's title, in view without scrolling.
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('shot-note'))).dy,
        lessThan(300),
      );
      expect(find.byKey(const ValueKey('onset-prev')), findsOneWidget);
      expect(find.byKey(const ValueKey('onset-next')), findsOneWidget);
    });

    testWidgets(
      'no connection: tick is kept and the banner says so; back online it is sent',
      (tester) async {
        final c = await pumpShoot(
          tester,
          const OnSetScreen(shootId: 'SHOOT-0006'),
          api: api,
        );
        api.offline = true;
        c.read(studioReachabilityProvider.notifier).report(false);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('sync-banner')), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('onset-filmed')));
        await tester.pumpAndSettle();
        expect(find.textContaining('1 change waiting to send'), findsOneWidget);
        expect(find.text('Filmed. Tap to undo'), findsOneWidget);
        expect(api.tickCalls, isEmpty);

        api.offline = false;
        c.read(studioReachabilityProvider.notifier).report(true);
        await tester.pumpAndSettle();
        expect(api.tickCalls.length, 1);
        expect(find.text('All sent'), findsOneWidget);
      },
    );

    testWidgets('moved pieces are announced', (tester) async {
      api.movedNext = const [
        PieceRef(
          id: 'PC-00101',
          title: 'Ten minutes',
          format: PieceFormat.trial,
          stage: PieceStage.toEdit,
        ),
        PieceRef(
          id: 'PC-00188',
          title: 'Pick one',
          format: PieceFormat.reel,
          stage: PieceStage.toEdit,
        ),
      ];
      await pumpShoot(
        tester,
        const OnSetScreen(shootId: 'SHOOT-0006'),
        api: api,
      );
      await tester.tap(find.byKey(const ValueKey('onset-filmed')));
      await tester.pumpAndSettle();
      expect(find.text('2 pieces moved to To edit'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('notices-dismiss')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pieces-moved')), findsNothing);
    });

    testWidgets('next, previous, and a note typed on a shot is queued', (
      tester,
    ) async {
      final c = await pumpShoot(
        tester,
        const OnSetScreen(shootId: 'SHOOT-0006'),
        api: api,
      );
      await tester.tap(find.byKey(const ValueKey('onset-next')));
      await tester.pumpAndSettle();
      expect(find.text('Shot 3 of 3'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('shot-note')),
        'Second take was better',
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('onset-prev')));
      await tester.pumpAndSettle();
      expect(find.text('Shot 2 of 3'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(api.noteCalls.single.note, 'Second take was better');
      expect(c.read(onSetProvider).pending, 0);
    });

    testWidgets('a person who may only look gets no Filmed button', (
      tester,
    ) async {
      api.noActions = true;
      await pumpShoot(
        tester,
        const OnSetScreen(shootId: 'SHOOT-0006'),
        api: api,
      );
      expect(find.byKey(const ValueKey('onset-filmed')), findsNothing);
      expect(find.byKey(const ValueKey('shot-note')), findsNothing);
    });

    testWidgets('not stored and no connection: a plain error with try again', (
      tester,
    ) async {
      api.offline = true;
      await pumpShoot(
        tester,
        const OnSetScreen(shootId: 'SHOOT-0006'),
        api: api,
      );
      expect(find.byKey(const ValueKey('onset-error')), findsOneWidget);
    });

    testWidgets('routes: shoot page opens On set at the shot', (tester) async {
      await pumpShoot(
        tester,
        const SizedBox(),
        api: api,
        location: '/shoots/SHOOT-0006',
      );
      await tester.tap(find.byKey(const ValueKey('start-on-set')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('on-set')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('onset-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('start-on-set')), findsOneWidget);
    });
  });

  group('public prep page', () {
    testWidgets('a good token shows the checklist, Arabic first, read only', (
      tester,
    ) async {
      await pumpShoot(
        tester,
        const SizedBox(),
        api: api,
        location: '/prep/EXAMPLETOKEN0000000000000000000A',
      );
      expect(find.byKey(const ValueKey('public-prep')), findsOneWidget);
      expect(find.text('تجهيز التصوير'), findsOneWidget);
      expect(find.byKey(const ValueKey('prep-item-0')), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      await tester.tap(find.byKey(const ValueKey('prep-lang')));
      await tester.pumpAndSettle();
      expect(find.text('Shoot prep'), findsOneWidget);
    });

    testWidgets('a wrong or old link shows a plain message', (tester) async {
      api.failNext('shoots.public_prep', 'NOT_FOUND');
      await pumpShoot(tester, const PublicPrepScreen(token: 'nope'), api: api);
      expect(find.text('اللينك ده مش شغّال'), findsOneWidget);
    });

    testWidgets('too many tries says to wait', (tester) async {
      api.failNext('shoots.public_prep', 'RATE_LIMITED');
      await pumpShoot(tester, const PublicPrepScreen(token: 'x'), api: api);
      expect(find.byKey(const ValueKey('prep-message')), findsOneWidget);
    });
  });
}
