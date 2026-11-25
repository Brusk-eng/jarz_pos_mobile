import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compile-time switches for the Studio build.
///
/// `--dart-define=STUDIO_FAKE=1` serves every API call from bundled JSON
/// fixtures and skips login. `STUDIO_FAKE_ROLE=founder|lead|creator|story|none`
/// picks which `session.me` fixture is served.
class StudioConfig {
  StudioConfig._();

  // bool.fromEnvironment only accepts "true"; the documented flag is =1.
  static const _fakeFlag = String.fromEnvironment('STUDIO_FAKE');
  static const fake = _fakeFlag == '1' || _fakeFlag == 'true';
  static const fakeRole = String.fromEnvironment(
    'STUDIO_FAKE_ROLE',
    defaultValue: 'founder',
  );
}

/// Overridable in tests.
final studioFakeProvider = Provider<bool>((ref) => StudioConfig.fake);
final studioFakeRoleProvider = Provider<String>((ref) => StudioConfig.fakeRole);
