import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import 'models/chat_flavour_models.dart';

final chatFlavourRepositoryProvider = Provider<ChatFlavourRepository>((ref) {
  return ChatFlavourRepository(ref.watch(dioProvider));
});

/// `get_flavour_availability` / `set_flavour_availability`. Same auth and
/// chat-role gate as the rest of `jarz_pos.api.chat`. The paths are kept
/// feature-local (not in `ApiEndpoints`) so the change ships as a
/// Dart-only Shorebird patch.
class ChatFlavourRepository {
  final Dio _dio;
  ChatFlavourRepository(this._dio);

  static const getPath =
      '/api/method/jarz_pos.api.chat.get_flavour_availability';
  static const setPath =
      '/api/method/jarz_pos.api.chat.set_flavour_availability';

  dynamic _payload(Response response) {
    final data = response.data;
    if (data is Map && data.containsKey('message')) return data['message'];
    return data;
  }

  Future<ChatFlavourAvailabilityPage> fetch() async {
    final response = await _dio.get(getPath);
    return ChatFlavourAvailabilityPage.fromJson(_payload(response));
  }

  /// Saves [availability] (`auto` / `available` / `paused`) for [itemCode]
  /// and returns the row as the server now reads it.
  Future<ChatFlavourAvailability> setAvailability({
    required String itemCode,
    required String availability,
  }) async {
    final response = await _dio.post(
      setPath,
      data: {'item_code': itemCode, 'availability': availability},
    );
    final payload = _payload(response);
    final item = payload is Map ? payload['item'] : null;
    final row = ChatFlavourAvailability.fromJson(item);
    if (row.itemCode.isEmpty) {
      throw StateError('set_flavour_availability returned no item');
    }
    return row;
  }
}
