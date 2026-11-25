import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/offline/kv_store.dart';
import 'package:jarz_pos/src/studio/core/offline/reachability.dart';
import 'package:jarz_pos/src/studio/data/models/studio_enums.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';
import 'package:jarz_pos/src/studio/features/shoots/state/on_set_state.dart';

import 'shoots_test_utils.dart';

void main() {
  late ShootTestApi api;
  late MemoryKvStore kv;
  final containers = <ProviderContainer>[];

  ProviderContainer app({DateTime Function()? clock}) {
    final c = ProviderContainer(
      overrides: [
        ...shootOverrides(api: api, kv: kv),
        if (clock != null) onSetClockProvider.overrideWithValue(clock),
      ],
    );
    containers.add(c);
    return c;
  }

  setUp(() {
    api = ShootTestApi();
    kv = MemoryKvStore();
  });
  tearDown(() {
    for (final c in containers) {
      c.dispose();
    }
    containers.clear();
  });

  void goOffline(ProviderContainer c) {
    api.offline = true;
    c.read(studioReachabilityProvider.notifier).report(false);
  }

  Future<void> goOnline(ProviderContainer c) async {
    api.offline = false;
    c.read(studioReachabilityProvider.notifier).report(true);
    await c.read(onSetProvider.notifier).flush();
  }

  test(
    'opening a shoot stores it; with no connection the stored copy opens',
    () async {
      final c1 = app();
      final shoot = await c1
          .read(onSetProvider.notifier)
          .openShoot('SHOOT-0006');
      expect(shoot.shots.length, 3);

      final c2 = app();
      goOffline(c2);
      final again = await c2
          .read(onSetProvider.notifier)
          .openShoot('SHOOT-0006');
      expect(again.title, shoot.title);
      expect(again.shots.length, 3);
    },
  );

  test(
    'a shoot never opened and no connection is an error, not an empty page',
    () async {
      final c = app();
      goOffline(c);
      expect(
        c.read(onSetProvider.notifier).openShoot('SHOOT-0006'),
        throwsA(isA<Object>()),
      );
    },
  );

  test(
    'ticks made offline are kept, survive a restart, and go out in order when online',
    () async {
      final c1 = app(clock: ticker('2026-11-25T10:00:00+02:00'));
      final n1 = c1.read(onSetProvider.notifier);
      await n1.openShoot('SHOOT-0006');
      goOffline(c1);
      await n1.tick('SHOT-00109', true);
      await n1.tick('SHOT-00108', true);
      expect(c1.read(onSetProvider).pending, 2);
      final seen = c1.read(onSetProvider).shoot('SHOOT-0006')!;
      expect(seen.shots.where((s) => s.done).length, 3);
      expect(api.tickCalls, isEmpty);

      // The app is closed and opened again, still offline.
      final c2 = app();
      goOffline(c2);
      final n2 = c2.read(onSetProvider.notifier);
      await n2.ensureLoaded();
      expect(c2.read(onSetProvider).pending, 2);
      expect(
        c2
            .read(onSetProvider)
            .shoot('SHOOT-0006')!
            .shots
            .where((s) => s.done)
            .length,
        3,
        reason: 'ticks still show after a restart',
      );

      await goOnline(c2);
      expect(api.tickCalls.length, 1);
      expect(
        [for (final t in api.tickCalls.single) t['shot_id']],
        ['SHOT-00109', 'SHOT-00108'],
        reason: 'sent in the order they were ticked',
      );
      expect(
        api.tickCalls.single.every((t) => t['request_id'] != null),
        isTrue,
      );
      expect(c2.read(onSetProvider).pending, 0);
      expect(c2.read(onSetProvider).everSent, isTrue);
      expect(await kv.get('onset:outbox'), '[]');
    },
  );

  test('ticking and unticking one shot sends only the last state', () async {
    final c = app(clock: ticker('2026-11-25T10:00:00+02:00'));
    final n = c.read(onSetProvider.notifier);
    await n.openShoot('SHOOT-0006');
    goOffline(c);
    await n.tick('SHOT-00108', true);
    await n.tick('SHOT-00108', false);
    await goOnline(c);
    expect(api.tickCalls.single.length, 1);
    expect(api.tickCalls.single.single['done'], false);
    expect(c.read(onSetProvider).pending, 0);
  });

  test('conflict: the newer write wins, by the time it was made', () async {
    // Someone else ticked 108 at 11:00. A tick made offline at 10:00 loses.
    api.serverDone['SHOT-00108'] = (
      done: true,
      at: '2026-11-25T11:00:00+02:00',
    );
    final c = app(clock: ticker('2026-11-25T10:00:00+02:00'));
    final n = c.read(onSetProvider.notifier);
    await n.openShoot('SHOOT-0006');
    goOffline(c);
    await n.tick('SHOT-00108', false);
    final seen = c.read(onSetProvider).shoot('SHOOT-0006')!;
    expect(
      seen.shots.firstWhere((s) => s.id == 'SHOT-00108').done,
      isTrue,
      reason: 'the server holds a newer tick, so the old one does not show',
    );
    await goOnline(c);
    expect(
      c
          .read(onSetProvider)
          .shoot('SHOOT-0006')!
          .shots
          .firstWhere((s) => s.id == 'SHOT-00108')
          .done,
      isTrue,
    );

    // A tick made after theirs wins.
    final c2 = app(clock: ticker('2026-11-25T12:00:00+02:00'));
    final n2 = c2.read(onSetProvider.notifier);
    await n2.openShoot('SHOOT-0006');
    goOffline(c2);
    await n2.tick('SHOT-00108', false);
    expect(
      c2
          .read(onSetProvider)
          .shoot('SHOOT-0006')!
          .shots
          .firstWhere((s) => s.id == 'SHOT-00108')
          .done,
      isFalse,
    );
    await goOnline(c2);
    expect(api.serverDone['SHOT-00108']!.done, isFalse);
  });

  test('pieces that moved on are reported after the send', () async {
    api.movedNext = [
      const PieceRef(
        id: 'PC-00101',
        title: 'Ten minutes before the doorbell',
        format: PieceFormat.trial,
        stage: PieceStage.toEdit,
      ),
      const PieceRef(
        id: 'PC-00188',
        title: 'Pick one',
        format: PieceFormat.reel,
        stage: PieceStage.toEdit,
      ),
    ];
    final c = app();
    final n = c.read(onSetProvider.notifier);
    await n.openShoot('SHOOT-0006');
    await n.tick('SHOT-00108', true);
    await n.flush();
    expect(c.read(onSetProvider).moved.length, 2);
    n.clearNotices();
    expect(c.read(onSetProvider).moved, isEmpty);
  });

  test(
    'a note changed on the server meanwhile is merged, not overwritten',
    () async {
      final c = app();
      final n = c.read(onSetProvider.notifier);
      await n.openShoot('SHOOT-0006');
      goOffline(c);
      await n.saveNote('SHOT-00108', 'redo the door');
      await n.saveNote('SHOT-00108', 'redo the door, 2 takes');
      expect(c.read(onSetProvider).pending, 1, reason: 'one note per shot');
      api.staleNote = 'light was too warm';
      await goOnline(c);
      expect(api.noteCalls.length, 2);
      expect(
        api.noteCalls.last.note,
        'light was too warm\nredo the door, 2 takes',
      );
      expect(c.read(onSetProvider).pending, 0);
    },
  );

  test('syncAll downloads every shoot for offline use', () async {
    final c1 = app();
    await c1.read(onSetProvider.notifier).syncAll();
    expect(c1.read(onSetProvider).shoots.keys, ['SHOOT-0006']);
    expect(c1.read(onSetProvider).serverTime, '2026-11-25T14:05:00+02:00');

    final c2 = app();
    await c2.read(onSetProvider.notifier).ensureLoaded();
    expect(c2.read(onSetProvider).shoot('SHOOT-0006'), isNotNull);
    expect(c2.read(onSetProvider).serverTime, '2026-11-25T14:05:00+02:00');
  });

  test('isoWithOffset keeps the time zone offset', () {
    expect(
      isoWithOffset(DateTime.parse('2026-11-25T14:05:09+02:00')),
      matches(RegExp(r'^2026-11-25T\d\d:05:09[+-]\d\d:\d\d$')),
    );
  });
}
