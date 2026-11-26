import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
  show debugPrint, kDebugMode, kIsWeb, visibleForTesting;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/timing_config.dart';
import '../env/app_build_identity.dart';
import '../monitoring/sentry_service.dart';
import '../session/session_manager.dart';
import 'app_upgrade_signal.dart';
import 'cookie_manager.dart';
import 'session_expired_signal.dart';
import '../offline/offline_queue.dart';

/// Headers the server's release gate reads. Every request carries them so a
/// build below the floor is refused even if it never ran the version check.
const kBuildHeader = 'X-Jarz-Build';
const kPlatformHeader = 'X-Jarz-Platform';

/// HTTP 426. Distinct from 401 (which would log the user out) and 403 (which
/// reads as a permission bug).
const kUpgradeRequiredStatus = 426;

/// Method-path prefixes that must NEVER be queued for offline replay.
///
/// The replay rule below is a blunt "POST whose path contains `create`". A
/// Task Board mutation (`create_task`, and every other `jarz_pos.api.tasks.*`
/// call) is one the user sees fail and simply retries; a queued copy replayed
/// later would then create a second task (or re-apply a status move, entry or
/// upload the user already redid). These calls must fail visibly, never
/// replay. Keep this list narrow and explicit.
const kOfflineReplayExcludedPrefixes = <String>[
  '/api/method/jarz_pos.api.tasks.',
  // A replayed chat send would message the customer twice.
  '/api/method/jarz_pos.api.chat.',
];

/// Whether a failed request may be parked in the offline queue for replay.
@visibleForTesting
bool shouldQueueForOfflineReplay(RequestOptions options) {
  if (options.method.toUpperCase() != 'POST') return false;
  final path = options.path;
  for (final prefix in kOfflineReplayExcludedPrefixes) {
    if (path.contains(prefix)) return false;
  }
  return path.contains('create');
}

class SessionInterceptor extends Interceptor {
  SessionInterceptor(
    this._sessionManager,
    this._offlineQueue,
    this._frappeSite, {
    bool? isWebOverride,
    this.sendBuildIdentity = true,
  }) : _isWeb = isWebOverride ?? kIsWeb;

  final SessionManager _sessionManager;
  final OfflineQueue _offlineQueue;
  final String _frappeSite;
  final bool _isWeb;

  /// Whether requests carry the build number and platform the server's release
  /// gate reads. The POS leaves this on. Jarz Studio turns it off: it is a
  /// different app whose build number comes from its own CI run count, and the
  /// gate floor belongs to the POS build line, so a Studio build would be
  /// refused with 426 on every call.
  final bool sendBuildIdentity;

  /// Resolved once and reused. PackageInfo hits a platform channel, and this
  /// runs on every single request.
  Future<AppBuildIdentity>? _buildIdentity;

  Future<AppBuildIdentity> _resolveBuildIdentity() {
    return _buildIdentity ??= loadAppBuildIdentity();
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // On web, browsers manage cookies automatically for same-origin requests.
    // Manually setting Cookie headers is blocked by browsers and causes issues.
    if (!_isWeb) {
      // Add session cookies
      await CookieManager.attachCookiesToRequest(options);
      
      // Also use session manager for backward compatibility
      final sessionId = await _sessionManager.getSessionId();
      if (sessionId != null) {
        options.headers['Cookie'] = 'sid=$sessionId';
      }
    }
    
    // Ensure Frappe site routing for multi-tenant backend
    if (_frappeSite.isNotEmpty) {
      options.headers['X-Frappe-Site-Name'] = _frappeSite;
      // Note: Don't set Host header - let it be the actual domain name
      // Setting Host to site name breaks HTTPS/domain-based routing
    }
    
    // Identify the build to the server's release gate. Wrapped because a
    // platform-channel failure must cost us the header, not the request.
    try {
      final identity = sendBuildIdentity ? await _resolveBuildIdentity() : null;
      if (identity != null && identity.buildNumber != null) {
        options.headers[kBuildHeader] = '${identity.buildNumber}';
        options.headers[kPlatformHeader] = identity.platform;
      }
    } catch (_) {
      // No header: the server treats an unidentified client as ungated.
    }

    if (kDebugMode) {
      print('📤 API Request: ${options.method} ${options.path}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // On web, browsers manage cookies automatically. The set-cookie header
    // is hidden from JavaScript by the browser for security.
    if (!_isWeb) {
      // Save cookies using new cookie manager
      await CookieManager.saveCookies(response);
      
      // Also extract session cookie for session manager (backward compatibility)
      final setCookieHeader = response.headers['set-cookie'];
      if (setCookieHeader != null) {
        for (final cookie in setCookieHeader) {
          if (cookie.startsWith('sid=')) {
            final sessionId = cookie.split(';')[0].split('=')[1];
            await _sessionManager.saveSessionId(sessionId);
            break;
          }
        }
      }
    }
    
    if (kDebugMode) {
      print('📥 API Response: ${response.statusCode} ${response.requestOptions.path}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (kDebugMode) {
      print('❌ API Error: ${err.response?.statusCode} ${err.requestOptions.path} - ${err.message}');
    }
    
    // 426 Upgrade Required: the server refuses this build outright. Raise the
    // gate rather than letting the call sites surface it as a random failure.
    if (err.response?.statusCode == kUpgradeRequiredStatus) {
      AppUpgradeSignal.instance.report(
        readUpgradeRefusal(err.response?.data),
      );
    }

    // Clear session on 401 Unauthorized
    if (err.response?.statusCode == 401) {
      await clearStoredSessionAfterUnauthorized(
        isWeb: _isWeb,
        sessionManager: _sessionManager,
        clearCookies: CookieManager.clearCookies,
      );
    }

    // The server has stopped recognising this session. Frappe answers that
    // with 403 (not 401), so without this the app stays "logged in" against a
    // dead session and every poller retries forever.
    if (looksLikeDeadSession(err.response?.statusCode, err.response?.data)) {
      SessionExpiredSignal.instance.report();
    }
    
    // Add to offline queue if network error and it's a modifying request
    if (err.type == DioExceptionType.connectionError || 
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      
      if (shouldQueueForOfflineReplay(err.requestOptions)) {
        
        await _offlineQueue.addTransaction({
          'endpoint': err.requestOptions.path,
          'method': err.requestOptions.method,
          'data': err.requestOptions.data,
          'headers': err.requestOptions.headers,
        });
        
        if (kDebugMode) {
          print('🔄 OFFLINE: Added failed request to queue');
        }
      }
    }
    
    handler.next(err);
  }
}

/// Pulls the refusal details out of a 426 body.
///
/// Frappe puts the fields at the top level of the error response, but an
/// upstream proxy can replace the body with HTML, so every field falls back to
/// a harmless default rather than assuming the shape.
@visibleForTesting
AppUpgradeRefusal readUpgradeRefusal(Object? body) {
  final map = body is Map ? body : const <String, dynamic>{};
  final minimum = map['minimum_build'];
  return AppUpgradeRefusal(
    minimumBuild: minimum is int
        ? minimum
        : int.tryParse('${minimum ?? ''}'.trim()) ?? 0,
    downloadUrl: '${map['download_url'] ?? ''}'.trim(),
    message: '${map['message'] ?? ''}'.trim(),
  );
}

/// Frappe's wording when the request ran as Guest because the session is
/// gone. `_server_messages` carries both of these together.
const _guestLoginMarker = 'login to access';
const _guestNotWhitelistedMarker = 'not whitelisted';
const _guestNotPermittedMarker = 'not permitted to access this resource';

/// True when this response means "your session is gone", as opposed to "you
/// are signed in but this is not yours".
///
/// The distinction is the whole point of this function and it is load-bearing:
/// 403 is ALSO the legitimate role-denial answer for the fleet map
/// (`FleetPermissionDeniedException`) and the manager menu probe. Keying off
/// the status code alone would log a supervisor-less user out of a live till
/// mid-shift, losing an open cart - a far worse bug than the one being fixed.
/// So a 403 only counts when the body carries Frappe's Guest signature.
///
/// Deliberately narrower than "any PermissionError": a role denial raised with
/// `frappe.PermissionError` carries the same `exc_type`, so that field alone
/// cannot separate the two cases. "not whitelisted" alone is also not enough -
/// an authenticated call to a genuinely un-whitelisted method would then log
/// the user out on every retry, i.e. a login loop. It is accepted only paired
/// with the "not permitted to access this resource" sentence, which is how
/// Frappe phrases it for Guest, and which is what production actually sends.
///
/// 401 needs no body check: Frappe only returns it for authentication, and the
/// interceptor already clears the stored session on it for the same reason.
@visibleForTesting
bool looksLikeDeadSession(int? status, Object? body) {
  if (status == 401) {
    return true;
  }
  if (status != 403) {
    return false;
  }

  // toString() rather than a structured parse: `_server_messages` is a JSON
  // string holding JSON strings, and an upstream proxy can replace the body
  // with HTML entirely. A substring scan survives both shapes.
  final text = body == null ? '' : body.toString().toLowerCase();
  if (text.isEmpty) {
    return false;
  }
  if (text.contains(_guestLoginMarker)) {
    return true;
  }
  if (text.contains(_guestNotWhitelistedMarker) &&
      text.contains(_guestNotPermittedMarker)) {
    return true;
  }

  final excType = body is Map
      ? '${body['exc_type'] ?? ''}'.trim().toLowerCase()
      : '';
  return excType == 'sessionexpired' ||
      excType == 'sessionstopped' ||
      excType == 'authenticationerror';
}

@visibleForTesting
Future<void> clearStoredSessionAfterUnauthorized({
  required bool isWeb,
  required SessionManager sessionManager,
  required Future<void> Function() clearCookies,
}) async {
  if (isWeb) {
    return;
  }

  await sessionManager.clearSession();
  await clearCookies();
}

final dioProvider = Provider<Dio>(
  (ref) => buildSessionDio(ref, sendBuildIdentity: true),
);

/// Builds the session Dio behind [dioProvider]. [sendBuildIdentity] is false
/// only for Jarz Studio (see [SessionInterceptor.sendBuildIdentity]), which
/// overrides [dioProvider] with this so login, biometric sign-in, logout and
/// every other request of that app go without the POS build headers.
Dio buildSessionDio(Ref ref, {required bool sendBuildIdentity}) {
  final sessionManager = ref.watch(sessionManagerProvider);
  final offlineQueue = ref.watch(offlineQueueProvider);
  final baseUrl = dotenv.get('ERP_BASE_URL');
  final frappeSite = dotenv.get('FRAPPE_SITE', fallback: '');

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: NetworkTimeouts.httpConnect,
      receiveTimeout: NetworkTimeouts.httpReceive,
      sendTimeout: NetworkTimeouts.httpSend,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Record every request/response/error as a Sentry breadcrumb. Without this,
  // events raised from this Dio instance (which serves most of the app) arrive
  // with no trace of which endpoint failed or what it returned.
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        SentryService.instance.addHttpBreadcrumb(
          method: options.method,
          path: options.path,
          category: 'http.request',
        );
        handler.next(options);
      },
      onResponse: (response, handler) {
        SentryService.instance.addHttpBreadcrumb(
          method: response.requestOptions.method,
          path: response.requestOptions.path,
          statusCode: response.statusCode,
          category: 'http.response',
        );
        handler.next(response);
      },
      onError: (error, handler) {
        SentryService.instance.addHttpBreadcrumb(
          method: error.requestOptions.method,
          path: error.requestOptions.path,
          statusCode: error.response?.statusCode,
          category: 'http.error',
          failed: true,
        );
        handler.next(error);
      },
    ),
  );

  // Add enhanced session interceptor with offline support
  dio.interceptors.add(SessionInterceptor(
    sessionManager,
    offlineQueue,
    frappeSite,
    sendBuildIdentity: sendBuildIdentity,
  ));

  // Add logging interceptor for debugging
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
  logPrint: (object) => debugPrint('🌐 HTTP: $object'),
    ));
  }

  return dio;
}
