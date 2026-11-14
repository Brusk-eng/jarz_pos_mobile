import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import 'update_channel.dart';

final updateChannelServiceProvider = Provider<UpdateChannelService>((ref) {
  return UpdateChannelService(ref.watch(dioProvider));
});

/// Asks the server which Shorebird track this signed-in device follows.
class UpdateChannelService {
  UpdateChannelService(this._dio, {Duration? timeout})
    : _timeout = timeout ?? const Duration(seconds: 15);

  final Dio _dio;
  final Duration _timeout;

  /// Never throws.
  ///
  /// * The server gave a real answer: returns its parsed answer, or
  ///   [UpdateChannel.fallback] ("stable") when it says the endpoint is not
  ///   there (404 on a server without it, 417) or the body is unreadable.
  /// * No usable answer: returns `null`, meaning "unknown - keep whatever
  ///   track you already had". That covers offline, DNS, timeout, and the
  ///   transient statuses: 5xx (the 502/503/504 burst while a deploy restarts
  ///   the backend), 401/403 (an expired session), 408 and 429. Treating those
  ///   as "stable" would drop a manager off the fast channel for a whole
  ///   session just because the app opened during a restart.
  Future<UpdateChannel?> fetchChannel({String? fcmToken}) async {
    try {
      final token = fcmToken?.trim() ?? '';
      final response = await _dio
          .post<dynamic>(
            ApiEndpoints.getUpdateChannel,
            data: <String, dynamic>{if (token.isNotEmpty) 'token': token},
          )
          .timeout(_timeout);

      final body = response.data;
      if (body is! Map) {
        return UpdateChannel.fallback;
      }
      // Frappe wraps whitelisted return values in `message`.
      return UpdateChannel.fromJson(body['message']);
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint('Update channel check failed (ignored): $error');
      }
      final response = error.response;
      if (response == null) return null;
      return isTransientStatus(response.statusCode)
          ? null
          : UpdateChannel.fallback;
    } on TimeoutException {
      return null;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Update channel check failed (ignored): $error');
      }
      return UpdateChannel.fallback;
    }
  }

  /// Statuses that say nothing about this device's channel, only that the
  /// server could not answer right now.
  @visibleForTesting
  static bool isTransientStatus(int? status) {
    if (status == null) return true;
    if (status >= 500) return true;
    return status == 401 || status == 403 || status == 408 || status == 429;
  }
}
