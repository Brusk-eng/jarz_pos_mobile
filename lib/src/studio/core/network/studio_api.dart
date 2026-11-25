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
import '../../data/studio_error.dart';
import '../config/studio_config.dart';

export '../../data/api/studio_api_base.dart' show newRequestId;
export '../../data/studio_error.dart';

/// Frappe method prefix for every Studio endpoint.
const studioMethodPrefix = 'jarz_social.api.studio.';

/// The one door every Studio repository calls through: one typed method per
/// endpoint (generated, see `data/api/`), all built on [call]. Implemented by
/// [DioStudioApi] and the fake.
abstract class StudioApi extends StudioApiEndpoints {}

/// Real client: whitelisted Frappe methods go to `/api/method/<method>`
/// (POST, or GET for pure reads), the `message` envelope is unwrapped and every
/// failure becomes a [StudioError].
class DioStudioApi extends StudioApi {
  DioStudioApi(this._dio);

  final Dio _dio;

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
      final response = get
          ? await _dio.get('/api/method/$method', queryParameters: wire)
          : await _dio.post('/api/method/$method', data: wire);
      final data = response.data;
      if (data is Map && data.containsKey('message')) return data['message'];
      return data;
    } on DioException catch (e) {
      throw _toStudioError(e);
    }
  }
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

/// The API the whole Studio uses. The choice between real and fake is a
/// compile-time constant (`--dart-define=STUDIO_FAKE=1`), so a normal build
/// drops [FakeStudioApi] and the bundled fixtures entirely. Tests override
/// this provider with a [FakeStudioApi].
final studioApiProvider = Provider<StudioApi>((ref) {
  if (StudioConfig.fake) {
    return FakeStudioApi(role: StudioConfig.fakeRole);
  }
  return DioStudioApi(ref.watch(studioDioProvider));
});
