import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/data/auth_repository.dart';
import '../../../core/network/studio_api.dart';
import 'studio_me.dart';

final studioSessionRepositoryProvider = Provider<StudioSessionRepository>((
  ref,
) {
  return StudioSessionRepository(
    ref.watch(studioApiProvider),
    () => ref.read(authRepositoryProvider),
  );
});

/// Login and "who am I" for the Studio. Login reuses the POS Frappe session
/// login; `me` is the Studio's own endpoint.
class StudioSessionRepository {
  StudioSessionRepository(this._api, this._authRepo);

  final StudioApi _api;

  /// Resolved on use: building the POS auth repository needs the POS env, which
  /// the fake build never loads.
  final AuthRepository Function() _authRepo;
  AuthRepository get _auth => _authRepo();

  Future<bool> login(String username, String password) =>
      _auth.login(username, password);

  Future<void> logout() => _auth.logout();

  Future<StudioMe> me() async {
    final data = await _api.call('${studioMethodPrefix}session.me');
    return StudioMe.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
