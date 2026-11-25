import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/push/studio_push_router.dart';

void main() {
  test('short and prefixed hash routes land on the one stable address', () {
    const cases = {
      '/library': '/assets',
      '/more/library': '/assets',
      '/more/shoots': '/shoots',
      '/more/calendar?actual=x': '/calendar?actual=x',
      '/ideas': '/inbox/ideas',
      '/decisions': '/inbox/decisions',
      '/decisions/DEC-1': '/inbox/decisions/DEC-1',
      '/rate': '/inbox/rate',
      '/notifications': '/inbox/notifications',
      '/paid?round=R3': '/more/paid?round=R3',
      '/assets/new': '/assets/new',
      '/inbox/rate': '/inbox/rate',
      '/today': '/today',
    };
    cases.forEach((from, to) => expect(studioAppRoute(from), to, reason: from));
  });

  test('a push with route /library opens the library', () {
    expect(studioPushLocation({'route': '/library'}), '/assets');
  });
}
