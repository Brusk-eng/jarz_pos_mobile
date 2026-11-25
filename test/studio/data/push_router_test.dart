import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/push/studio_push_router.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';

void main() {
  final examples = (jsonDecode(studioFixtures['push.payloads']!) as List)
      .cast<Map<String, dynamic>>();

  Map<String, String> payload(Map<String, dynamic> e) =>
      (e['payload'] as Map).map((k, v) => MapEntry('$k', '$v'));

  test('the fixture lists every contract event (15)', () {
    expect(examples, hasLength(15));
  });

  for (final e in examples) {
    final event = e['event'] as String;
    test('$event: opens the route in the payload', () {
      final p = payload(e);
      expect(p['type'], 'studio_$event');
      expect(studioPushLocation(p), studioAppRoute(p['route']!));
      expect(studioPushNotificationId(p), p['notification_id']);
    });

    test('$event: with no route the event code decides', () {
      final p = payload(e)..['route'] = '';
      final want = (e['payload'] as Map)['route'] as String;
      // Only the paid push loses its round query; every other event rebuilds
      // exactly the route the contract sends.
      expect(
        studioPushLocation(p),
        studioAppRoute(event == 'paid_due' ? '/paid' : want),
      );
    });
  }

  test('an unknown route or event opens Today', () {
    expect(
      studioPushLocation({'type': 'studio_new', 'route': '/somewhere/else'}),
      '/today',
    );
    expect(studioPushLocation({}), '/today');
    expect(studioPushNotificationId({'notification_id': ''}), isNull);
  });

  test('assigned: the record type picks the screen', () {
    String go(String doctype, String name) => studioPushLocation({
      'type': 'studio_assigned',
      'route': '',
      'doctype': doctype,
      'docname': name,
    });
    expect(go('Studio Piece', 'PC-1'), '/pieces/PC-1');
    expect(go('Studio Shoot', 'SHOOT-1'), '/shoots/SHOOT-1');
    expect(go('Social Post', 'SP-1'), '/calendar/post/SP-1');
    expect(go('Studio Task', 'TASK-1'), '/today?task=TASK-1');
  });

  test('contract routes open the screens under /more', () {
    expect(studioAppRoute('/paid?round=R2b'), '/more/paid?round=R2b');
    expect(studioAppRoute('/assets'), '/assets');
    expect(studioAppRoute('/shoots/SHOOT-1'), '/shoots/SHOOT-1');
    expect(
      studioAppRoute('/results?week=2026-11-22'),
      '/more/results?week=2026-11-22',
    );
    expect(studioAppRoute('/pieces/PC-1'), '/pieces/PC-1');
    expect(studioAppRoute('/prep/abc'), '/prep/abc');
    expect(studioAppRoute('/more/paid'), '/more/paid');
  });

  test('route shapes of contract 1.9', () {
    for (final r in [
      '/today',
      '/inbox',
      '/inbox/approve',
      '/inbox/approve/PC-1-v1',
      '/inbox/decisions/DEC-1',
      '/inbox/ideas',
      '/calendar/post/SP-1',
      '/pieces/PC-1',
      '/shoots/SHOOT-1',
      '/prep/abc',
      '/paid?round=R2b',
      '/results?week=2026-11-22',
      '/calendar?actual=AC-1',
    ]) {
      expect(isKnownStudioRoute(r), isTrue, reason: r);
    }
    expect(isKnownStudioRoute('/nope'), isFalse);
    expect(isKnownStudioRoute('https://x.test/today'), isFalse);
  });
}
