import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';
import 'package:jarz_pos/src/studio/features/session/data/me_profile_x.dart';

void main() {
  FakeStudioApi fake({String role = 'founder'}) =>
      FakeStudioApi(role: role, delay: Duration.zero);

  group('FakeStudioApi (fixtures)', () {
    test('serves session.me for each role variant', () async {
      for (final role in ['founder', 'lead', 'creator', 'story', 'none']) {
        final me = MeProfile.fromJson(
          Map<String, dynamic>.from(
            await fake(role: role).call('${studioMethodPrefix}session.me')
                as Map,
          ),
        );
        expect(me.user, isNotEmpty, reason: role);
        expect(me.hasStudioAccess, role != 'none', reason: role);
      }
    });

    test('founder fixture is the founder', () async {
      final me = MeProfile.fromJson(
        Map<String, dynamic>.from(
          await fake().call('${studioMethodPrefix}session.me') as Map,
        ),
      );
      expect(me.isFounder, isTrue);
      expect(me.roles, contains('Studio Founder'));
    });

    test('an unknown method fails with NOT_FOUND', () {
      expect(
        fake().call('${studioMethodPrefix}nothing.here'),
        throwsA(isA<StudioNotFound>()),
      );
    });

    test('a role variant wins over the plain fixture', () async {
      final founder =
          await fake().call('${studioMethodPrefix}today.get') as Map;
      final creator =
          await fake(role: 'creator').call('${studioMethodPrefix}today.get')
              as Map;
      expect(creator, isNot(founder));
    });
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
