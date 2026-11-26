import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart'
    show SessionInterceptor, dioProvider;
import '../../../core/offline/offline_queue.dart';
import '../../../core/session/session_manager.dart';
import '../../data/api/studio_api_endpoints.dart';
import '../../data/fake/fake_studio_api.dart';
import '../../data/models/studio_models.dart' show MeProfile;
import '../../data/studio_error.dart';
import '../config/studio_config.dart';

export '../../data/api/studio_api_base.dart' show newRequestId;
export '../../data/studio_error.dart';

/// Frappe method prefix for every Studio endpoint.
const studioMethodPrefix = 'jarz_social.api.studio.';

/// The one door every Studio repository calls through: one typed method per
/// endpoint (generated, see `data/api/`), all built on [call]. Implemented by
/// [DioStudioApi] and the fake.
abstract class StudioApi extends StudioApiEndpoints {
  final _writes = StreamController<String>.broadcast();

  /// `group.fn` of every call that went through without an error, in order.
  /// The app listens in one place (`studioWriteRefreshProvider`) and refreshes
  /// what that write changes; no screen does it itself.
  Stream<String> get writes => _writes.stream;

  /// Called by an implementation after a call succeeded.
  void announceCall(String method) {
    final key = method.startsWith(studioMethodPrefix)
        ? method.substring(studioMethodPrefix.length)
        : method;
    if (!_writes.isClosed) _writes.add(key);
  }
}

/// Real client: whitelisted Frappe methods go to `/api/method/<method>`
/// (POST, or GET for pure reads), the `message` envelope is unwrapped and every
/// failure becomes a [StudioError].
class DioStudioApi extends StudioApi {
  DioStudioApi(
    this._dio, {
    this.retryDelay = const Duration(milliseconds: 1500),
  });

  final Dio _dio;

  /// Wait before the one automatic retry of a read that got a 502, 503 or 504.
  final Duration retryDelay;

  /// Frappe CSRF token from `session.me` (contract 1.5). Sent as
  /// `X-Frappe-CSRF-Token` on every POST while it is non-null.
  String? _csrfToken;

  /// Test hook: the token currently held.
  String? get csrfToken => _csrfToken;

  @override
  Future<MeProfile> sessionMe() async {
    final me = await super.sessionMe();
    _csrfToken = me.csrfToken;
    return me;
  }

  @override
  Future<dynamic> call(
    String method, {
    Map<String, dynamic>? params,
    bool get = false,
  }) async {
    final wire = <String, dynamic>{
      // Lists and objects travel as JSON strings, like materials_repository.
      for (final e in (params ?? const <String, dynamic>{}).entries)
        e.key: (e.value is Map || e.value is List)
            ? jsonEncode(e.value)
            : e.value,
    };
    try {
      Response<dynamic> response;
      try {
        response = await _send(method, wire, get);
      } on DioException catch (e) {
        if (get && _isGatewayError(e)) {
          // A read behind a restarting or overloaded server: one quiet retry.
          await Future<void>.delayed(retryDelay);
          response = await _send(method, wire, get);
        } else if (!get && _isCsrfError(e)) {
          // A stale CSRF token: fetch a fresh one and send the request once more.
          await sessionMe();
          response = await _send(method, wire, get);
        } else {
          rethrow;
        }
      }
      final data = response.data;
      if (!get) announceCall(method);
      if (data is Map && data.containsKey('message')) return data['message'];
      return data;
    } on DioException catch (e) {
      throw _toStudioError(e);
    }
  }

  Future<Response<dynamic>> _send(
    String method,
    Map<String, dynamic> wire,
    bool get,
  ) {
    if (get) return _dio.get('/api/method/$method', queryParameters: wire);
    final token = _csrfToken;
    return _dio.post(
      '/api/method/$method',
      data: wire,
      options: token == null
          ? null
          : Options(headers: {'X-Frappe-CSRF-Token': token}),
    );
  }
}

bool _isGatewayError(DioException e) {
  final code = e.response?.statusCode;
  return code == 502 || code == 503 || code == 504;
}

/// Frappe answers a POST with a missing or stale CSRF token with HTTP 400 and
/// `exc_type: CSRFTokenError`.
bool _isCsrfError(DioException e) {
  final response = e.response;
  if (response == null || response.statusCode != 400) return false;
  var body = response.data;
  if (body is String && body.trim().startsWith('{')) {
    try {
      body = jsonDecode(body);
    } catch (_) {}
  }
  return body is Map && '${body['exc_type']}' == 'CSRFTokenError';
}

StudioError _toStudioError(DioException e) {
  final response = e.response;
  if (response == null) {
    return StudioNetworkError(e.message ?? 'No connection.');
  }
  var body = response.data;
  if (body is String && body.trim().startsWith('{')) {
    try {
      body = jsonDecode(body);
    } catch (_) {}
  }
  return StudioError.fromResponse(response.statusCode, body);
}

/// Queue stand-in for the Studio's Dio: swallows what the POS interceptor
/// would park for offline replay. See README "Offline replay opt-out".
class NoReplayOfflineQueue extends OfflineQueue {
  NoReplayOfflineQueue() : super();

  @override
  Future<void> addTransaction(Map<String, dynamic> transaction) async {}
}

/// A Dio with the POS options and session handling (cookies, site header,
/// 401 and dead-session signals) but that never queues a failed
/// POST for replay: the POS rule replays any POST whose path contains
/// "create", and a replayed Studio write would double-create. It sends no
/// build headers: the POS release floor on the server must not gate Studio.
final studioDioProvider = Provider<Dio>((ref) {
  final posDio = ref.watch(dioProvider);
  final dio = Dio(posDio.options.copyWith());
  dio.interceptors.add(
    SessionInterceptor(
      ref.watch(sessionManagerProvider),
      NoReplayOfflineQueue(),
      dotenv.get('FRAPPE_SITE', fallback: ''),
      sendBuildIdentity: false,
    ),
  );
  return dio;
});

/// The API the whole Studio uses. The choice between real and fake is a
/// compile-time constant (`--dart-define=STUDIO_FAKE=1`), so a normal build
/// drops [FakeStudioApi] and the bundled fixtures entirely. Tests override
/// this provider with a [FakeStudioApi].
final studioApiProvider = Provider<StudioApi>((ref) {
  if (StudioConfig.fake) {
    return FakeStudioApi(
      role: StudioConfig.fakeRole,
      textDecisions: true,
      firstLogin: true,
      storyFrames: true,
    );
  }
  return DioStudioApi(ref.watch(studioDioProvider));
});
