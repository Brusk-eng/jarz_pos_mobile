import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart'
    show SessionInterceptor, dioProvider;
import '../../../core/offline/offline_queue.dart';
import '../../../core/session/session_manager.dart';
import '../config/studio_config.dart';

/// Frappe method prefix for every Studio endpoint.
const studioMethodPrefix = 'jarz_social.api.studio.';

/// A failed Studio call. [deadSession] is true when the server no longer
/// recognises the session (the caller should send the user to login).
class StudioApiException implements Exception {
  StudioApiException(this.message, {this.statusCode, this.deadSession = false});

  final String message;
  final int? statusCode;
  final bool deadSession;

  @override
  String toString() => 'StudioApiException($statusCode): $message';
}

/// True when the response means "your session is gone". The POS app has the
/// same check but marks it test-only, so this is a narrow Studio copy: 401, or
/// a 403 carrying Frappe's Guest wording or an auth exc_type. A plain 403
/// (signed in, not allowed) is NOT a dead session.
bool isDeadSessionResponse(int? status, Object? body) {
  if (status == 401) return true;
  if (status != 403) return false;
  final text = (body ?? '').toString().toLowerCase();
  if (text.contains('login to access')) return true;
  if (text.contains('not whitelisted') &&
      text.contains('not permitted to access this resource')) {
    return true;
  }
  final excType = body is Map ? '${body['exc_type'] ?? ''}'.toLowerCase() : '';
  return excType == 'sessionexpired' ||
      excType == 'sessionstopped' ||
      excType == 'authenticationerror';
}

/// The one door every Studio repository calls through. Whitelisted Frappe
/// methods are POSTed to `/api/method/<method>` and the `message` envelope is
/// unwrapped, exactly as the POS repositories do.
abstract class StudioApi {
  Future<dynamic> call(String method, {Map<String, dynamic>? params});
}

class DioStudioApi implements StudioApi {
  DioStudioApi(this._dio);

  final Dio _dio;

  @override
  Future<dynamic> call(String method, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.post(
        '/api/method/$method',
        data: params ?? const <String, dynamic>{},
      );
      final data = response.data;
      if (data is Map && data.containsKey('message')) return data['message'];
      return data;
    } on DioException catch (e) {
      throw StudioApiException(
        e.message ?? 'Request failed',
        statusCode: e.response?.statusCode,
        deadSession: isDeadSessionResponse(
          e.response?.statusCode,
          e.response?.data,
        ),
      );
    }
  }
}

/// Queue stand-in for the Studio's Dio: swallows what the POS interceptor
/// would park for offline replay. See README "Offline replay opt-out".
class NoReplayOfflineQueue extends OfflineQueue {
  NoReplayOfflineQueue() : super();

  @override
  Future<void> addTransaction(Map<String, dynamic> transaction) async {}
}

/// A Dio with the POS options and session handling (cookies, site header,
/// build headers, 401 and dead-session signals) but that never queues a failed
/// POST for replay: the POS rule replays any POST whose path contains
/// "create", and a replayed Studio write would double-create.
final studioDioProvider = Provider<Dio>((ref) {
  final posDio = ref.watch(dioProvider);
  final dio = Dio(posDio.options.copyWith());
  dio.interceptors.add(
    SessionInterceptor(
      ref.watch(sessionManagerProvider),
      NoReplayOfflineQueue(),
      dotenv.get('FRAPPE_SITE', fallback: ''),
    ),
  );
  return dio;
});

/// Serves `session.me` and any other call from JSON files in the bundle.
///
/// A call to `jarz_social.api.studio.<key>` reads
/// `assets/studio/fixtures/<key>__<role>.json` when a role variant exists
/// (role = STUDIO_FAKE_ROLE), else `<key>.json`.
class FakeStudioApi implements StudioApi {
  FakeStudioApi({AssetBundle? bundle, this.role = 'founder'})
    : _bundle = bundle ?? rootBundle;

  static const fixtureDir = 'assets/studio/fixtures';

  final AssetBundle _bundle;
  final String role;

  @override
  Future<dynamic> call(String method, {Map<String, dynamic>? params}) async {
    final key = method.startsWith(studioMethodPrefix)
        ? method.substring(studioMethodPrefix.length)
        : method;
    for (final file in ['${key}__$role', key]) {
      final path = '$fixtureDir/$file.json';
      try {
        final text = await _bundle.loadString(path);
        return _decode(text);
      } catch (_) {
        continue;
      }
    }
    throw StudioApiException('No fake fixture for $method', statusCode: 404);
  }

  dynamic _decode(String text) {
    final decoded = jsonDecode(text);
    if (decoded is Map && decoded.containsKey('message')) {
      return decoded['message'];
    }
    return decoded;
  }
}

/// Where fake fixtures are read from. Tests override it with an in-memory
/// bundle so no real asset IO runs under fake time.
final studioFixtureBundleProvider = Provider<AssetBundle>((ref) => rootBundle);

final studioApiProvider = Provider<StudioApi>((ref) {
  if (ref.watch(studioFakeProvider)) {
    return FakeStudioApi(
      bundle: ref.watch(studioFixtureBundleProvider),
      role: ref.watch(studioFakeRoleProvider),
    );
  }
  return DioStudioApi(ref.watch(studioDioProvider));
});
