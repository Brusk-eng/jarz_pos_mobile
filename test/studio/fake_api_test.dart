import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/features/session/data/studio_me.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FakeStudioApi (bundled fixtures)', () {
    test('serves session.me for each role variant', () async {
      for (final role in ['founder', 'lead', 'creator', 'story', 'none']) {
        final api = FakeStudioApi(bundle: fixtureBundle(), role: role);
        final me = StudioMe.fromJson(
          Map<String, dynamic>.from(
            await api.call('${studioMethodPrefix}session.me') as Map,
          ),
        );
        expect(me.user, isNotEmpty, reason: role);
        expect(me.hasStudioAccess, role != 'none', reason: role);
      }
    });

    test('founder fixture is the founder', () async {
      final me = StudioMe.fromJson(
        Map<String, dynamic>.from(
          await FakeStudioApi(
                bundle: fixtureBundle(),
              ).call('${studioMethodPrefix}session.me')
              as Map,
        ),
      );
      expect(me.isFounder, isTrue);
      expect(me.roles, contains('Studio Founder'));
    });

    test('an unknown method fails with a clear error', () {
      expect(
        FakeStudioApi(
          bundle: fixtureBundle(),
        ).call('${studioMethodPrefix}nothing.here'),
        throwsA(isA<StudioApiException>()),
      );
    });
  });

  group('FakeStudioApi (loader rules)', () {
    final bundle = MemoryAssetBundle({
      'assets/studio/fixtures/a.b.json': '{"message": {"v": "plain"}}',
      'assets/studio/fixtures/a.b__lead.json': '{"message": {"v": "lead"}}',
      'assets/studio/fixtures/c.d.json': '[1, 2, 3]',
    });

    test('role variant wins, plain file is the fallback', () async {
      expect(
        await FakeStudioApi(
          bundle: bundle,
          role: 'lead',
        ).call('jarz_social.api.studio.a.b'),
        {'v': 'lead'},
      );
      expect(
        await FakeStudioApi(
          bundle: bundle,
          role: 'creator',
        ).call('jarz_social.api.studio.a.b'),
        {'v': 'plain'},
      );
    });

    test(
      'unwraps the Frappe message envelope, passes bare JSON through',
      () async {
        final api = FakeStudioApi(bundle: bundle);
        expect(await api.call('jarz_social.api.studio.c.d'), [1, 2, 3]);
      },
    );
  });

  test('the fixtures are declared as assets (real rootBundle)', () async {
    final text = await rootBundle.loadString(
      'assets/studio/fixtures/session.me__founder.json',
    );
    expect(text, contains('Studio Founder'));
  });

  group('dead session detection', () {
    test('401 is dead; plain 403 is not; guest 403 is', () {
      expect(isDeadSessionResponse(401, null), isTrue);
      expect(isDeadSessionResponse(403, {'exc': 'PermissionError'}), isFalse);
      expect(
        isDeadSessionResponse(403, 'Please login to access this page'),
        isTrue,
      );
      expect(isDeadSessionResponse(500, 'login to access'), isFalse);
    });
  });
}
