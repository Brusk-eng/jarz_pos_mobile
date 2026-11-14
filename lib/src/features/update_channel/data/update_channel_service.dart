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
  /// * The server answered (any status, any body): returns its parsed answer,
  ///   or [UpdateChannel.fallback] ("stable") when it is an error (404 on a
  ///   server without the endpoint, 403, 417, 500) or unreadable.
  /// * No answer at all (offline, DNS, timeout): returns `null`, meaning
  ///   "unknown - keep whatever track you already had". This is what stops a
  ///   flaky connection from bouncing a manager's device between tracks.
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
      return error.response == null ? null : UpdateChannel.fallback;
    } on TimeoutException {
      return null;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Update channel check failed (ignored): $error');
      }
      return UpdateChannel.fallback;
    }
  }
}
