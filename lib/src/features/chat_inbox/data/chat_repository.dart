import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import 'models/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ChatRepository(dio);
});

/// Talks to `jarz_pos.api.chat.*` (contract §3). Reads are GETs with query
/// parameters; every write is a POST. All of them are excluded from offline
/// replay, so a failure surfaces instead of re-sending a customer message.
class ChatRepository {
  final Dio _dio;
  ChatRepository(this._dio);

  /// `regenerate_draft` calls the model synchronously (up to ~20s server
  /// side), longer than the app's default receive timeout.
  static const regenerateTimeout = Duration(seconds: 40);

  /// `get_order_prefill(with_order=1)` reads the chat with a model call.
  static const orderPrefillTimeout = Duration(seconds: 45);

  /// `get_new_customer_prefill` is one model call capped at 20 s server side.
  static const newCustomerPrefillTimeout = Duration(seconds: 30);

  /// `send_media` uploads up to 25 MB, then Meta takes its turn.
  static const mediaSendTimeout = Duration(minutes: 3);

  String get baseUrl => _dio.options.baseUrl;

  /// The `message` payload, or the bare body when it is not enveloped.
  dynamic _payload(Response response) {
    final data = response.data;
    if (data is Map && data.containsKey('message')) return data['message'];
    return data;
  }

  Map<String, dynamic> _map(Response response) {
    final payload = _payload(response);
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return const <String, dynamic>{};
  }

  /// `get_conversations`. [status] is `Open` / `Answered` / `Closed` / `all`;
  /// [before] is the `last_message_at` of the last row already shown.
  /// [excludeClosed] sends `exclude_closed=1` (with `status=all`: every chat
  /// that is not Closed). An older backend ignores it, so a caller that needs
  /// it must still drop Closed rows itself.
  Future<ChatConversationPage> fetchConversations({
    String status = ChatStatuses.open,
    String? channel,
    String? search,
    bool mine = false,
    int limit = 30,
    String? before,
    bool excludeClosed = false,
    String? category,
  }) async {
    final trimmedSearch = search?.trim() ?? '';
    final response = await _dio.get(
      ApiEndpoints.chatGetConversations,
      queryParameters: {
        'status': status,
        if (channel != null && channel.isNotEmpty) 'channel': channel,
        if (trimmedSearch.isNotEmpty) 'search': trimmedSearch,
        if (mine) 'mine': 1,
        if (excludeClosed) 'exclude_closed': 1,
        if (category != null && category.isNotEmpty) 'category': category,
        'limit': limit,
        if (before != null && before.isNotEmpty) 'before': before,
      },
    );
    return ChatConversationPage.fromJson(_payload(response));
  }

  /// `get_conversation` — header, messages (oldest → newest), the Pending
  /// draft and the customer card. Opening a thread resets its unread count,
  /// which is a write, so this is a POST (a forged GET must not mark it read).
  Future<ChatThread> fetchConversation(
    String name, {
    int limit = 50,
    String? before,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.chatGetConversation,
      data: {
        'name': name,
        'limit': limit,
        if (before != null && before.isNotEmpty) 'before': before,
      },
    );
    return ChatThread.fromJson(_payload(response));
  }

  /// `send_message` — a reply typed from scratch.
  Future<ChatMessage> sendMessage({
    required String conversation,
    required String text,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.chatSendMessage,
      data: {'conversation': conversation, 'text': text},
    );
    return ChatMessage.fromJson(_map(response)['message']);
  }

  /// `send_media` — one file as a reply (multipart: `conversation`,
  /// `caption`, `file`). Give [bytes] (web, or a file already in memory) or
  /// [path] (mobile; streamed from disk). [onProgress] reports bytes sent.
  Future<ChatMessage> sendMedia({
    required String conversation,
    required String filename,
    required String mime,
    Uint8List? bytes,
    String? path,
    String caption = '',
    void Function(int sent, int total)? onProgress,
  }) async {
    if (bytes == null && (path == null || path.isEmpty)) {
      throw ArgumentError('sendMedia needs bytes or a path');
    }
    final type = DioMediaType.parse(mime.isEmpty ? 'application/octet-stream' : mime);
    final file = bytes != null
        ? MultipartFile.fromBytes(bytes, filename: filename, contentType: type)
        : await MultipartFile.fromFile(
            path!,
            filename: filename,
            contentType: type,
          );
    final trimmed = caption.trim();
    final response = await _dio.post(
      ApiEndpoints.chatSendMedia,
      data: FormData.fromMap({
        'conversation': conversation,
        if (trimmed.isNotEmpty) 'caption': trimmed,
        'file': file,
      }),
      onSendProgress: onProgress,
      options: Options(
        sendTimeout: mediaSendTimeout,
        receiveTimeout: mediaSendTimeout,
      ),
    );
    final payload = _payload(response);
    final json = payload is Map && payload['message'] is Map
        ? payload['message']
        : payload;
    return ChatMessage.fromJson(json);
  }

  /// `react_to_message`; an empty [emoji] removes our reaction. Returns the
  /// updated message when the server sent one.
  Future<ChatMessage?> reactToMessage({
    required String message,
    required String emoji,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.chatReactToMessage,
      data: {'message': message, 'emoji': emoji},
    );
    final payload = _map(response)['message'];
    return payload is Map ? ChatMessage.fromJson(payload) : null;
  }

  /// Feature-local paths (kept out of `ApiEndpoints`, so a Dart-only patch).
  static const deleteMessagePath =
      '/api/method/jarz_pos.api.chat.delete_message';
  static const editMessagePath = '/api/method/jarz_pos.api.chat.edit_message';

  /// `delete_message`: deletes our comment reply for everyone.
  Future<ChatMessage?> deleteMessage({required String message}) async {
    final response = await _dio.post(
      deleteMessagePath,
      data: {'message': message},
    );
    final payload = _map(response)['message'];
    return payload is Map ? ChatMessage.fromJson(payload) : null;
  }

  /// `edit_message`: replaces the text of our comment reply.
  Future<ChatMessage?> editMessage({
    required String message,
    required String text,
  }) async {
    final response = await _dio.post(
      editMessagePath,
      data: {'message': message, 'text': text},
    );
    final payload = _map(response)['message'];
    return payload is Map ? ChatMessage.fromJson(payload) : null;
  }

  /// `send_draft` — the draft as-is or edited ([finalText] decides which).
  Future<ChatSendDraftResult> sendDraft({
    required String draft,
    required String finalText,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.chatSendDraft,
      data: {'draft': draft, 'final_text': finalText},
    );
    return ChatSendDraftResult.fromJson(_payload(response));
  }

  /// `reject_draft` with the moderator's [reason].
  Future<ChatRejectResult> rejectDraft({
    required String draft,
    required String reason,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.chatRejectDraft,
      data: {'draft': draft, 'reason': reason},
    );
    return ChatRejectResult.fromJson(_payload(response));
  }

  /// `regenerate_draft`, optionally steered by [hint].
  Future<ChatDraft?> regenerateDraft({
    required String conversation,
    String? hint,
  }) async {
    final trimmedHint = hint?.trim() ?? '';
    final response = await _dio.post(
      ApiEndpoints.chatRegenerateDraft,
      data: {
        'conversation': conversation,
        if (trimmedHint.isNotEmpty) 'hint': trimmedHint,
      },
      options: Options(receiveTimeout: regenerateTimeout),
    );
    return ChatDraft.maybeFromJson(_map(response)['draft']);
  }

  /// `assign_conversation`; an empty [user] assigns it to the caller.
  Future<ChatConversationSummary> assignConversation({
    required String conversation,
    String user = '',
  }) async {
    final response = await _dio.post(
      ApiEndpoints.chatAssignConversation,
      data: {'conversation': conversation, 'user': user},
    );
    return ChatConversationSummary.fromJson(_map(response)['conversation']);
  }

  /// `set_conversation_status` — `Open` or `Closed`.
  Future<ChatConversationSummary> setConversationStatus({
    required String conversation,
    required String status,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.chatSetConversationStatus,
      data: {'conversation': conversation, 'status': status},
    );
    return ChatConversationSummary.fromJson(_map(response)['conversation']);
  }

  /// `link_customer`.
  Future<ChatLinkResult> linkCustomer({
    required String conversation,
    required String customer,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.chatLinkCustomer,
      data: {'conversation': conversation, 'customer': customer},
    );
    return ChatLinkResult.fromJson(_payload(response));
  }

  /// `unlink_customer` — clears the customer (and last order) from the chat.
  Future<ChatConversationSummary> unlinkCustomer(String conversation) async {
    final response = await _dio.post(
      ApiEndpoints.chatUnlinkCustomer,
      data: {'conversation': conversation},
    );
    return ChatConversationSummary.fromJson(_map(response)['conversation']);
  }

  /// `suggest_customers` — ranked candidates plus the non-AI new-customer
  /// prefill. Cheap (no model call).
  Future<ChatSuggestCustomersResult> suggestCustomers(
    String conversation,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.chatSuggestCustomers,
      data: {'conversation': conversation},
    );
    return ChatSuggestCustomersResult.fromJson(_payload(response));
  }

  /// `get_new_customer_prefill` — one model call (20 s cap server side).
  Future<ChatNewCustomerPrefill> fetchNewCustomerPrefill(
    String conversation,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.chatGetNewCustomerPrefill,
      data: {'conversation': conversation},
      options: Options(receiveTimeout: newCustomerPrefillTimeout),
    );
    return ChatNewCustomerPrefill.fromJson(_payload(response));
  }

  /// `create_customer_from_chat` — creates and links, or answers `existing`
  /// when the mobile already belongs to a customer.
  Future<ChatCreateCustomerResult> createCustomerFromChat({
    required String conversation,
    required String customerName,
    required String mobileNo,
    required String address,
    required String territory,
    String? locationLink,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.chatCreateCustomerFromChat,
      data: {
        'conversation': conversation,
        'customer_name': customerName,
        'mobile_no': mobileNo,
        'address': address,
        'territory': territory,
        if (locationLink != null && locationLink.isNotEmpty)
          'location_link': locationLink,
        if (latitude != null && longitude != null) ...{
          'latitude': latitude,
          'longitude': longitude,
        },
      },
    );
    return ChatCreateCustomerResult.fromJson(_payload(response));
  }

  /// `set_contact_category`; an empty [category] returns the chat to the AI.
  Future<ChatConversationSummary> setContactCategory({
    required String conversation,
    required String category,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.chatSetContactCategory,
      data: {'conversation': conversation, 'category': category},
    );
    return ChatConversationSummary.fromJson(_map(response)['conversation']);
  }

  /// `get_fact_overrides` for `from_date`..`to_date` (`YYYY-MM-DD`),
  /// newest first, [start] rows skipped.
  Future<ChatFactOverridesPage> fetchFactOverrides({
    String? fromDate,
    String? toDate,
    int limit = 50,
    int start = 0,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.chatGetFactOverrides,
      queryParameters: {
        if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
        'limit': limit,
        'start': start,
      },
    );
    return ChatFactOverridesPage.fromJson(_payload(response));
  }

  /// Feature-local path (kept out of `ApiEndpoints`, so a Dart-only patch).
  static const approveFactConflictPath =
      '/api/method/jarz_pos.api.chat.approve_fact_conflict';

  /// `approve_fact_conflict` (managers): adds the moderator's statement on
  /// line [index] of [draft]'s fact conflicts to the approved facts. Calling
  /// it again for the same line returns the same fact.
  Future<ChatFactApprovalResult> approveFactConflict({
    required String draft,
    required int index,
    required String topic,
    String factEn = '',
    String factAr = '',
    String category = ChatFactCategories.other,
  }) async {
    final response = await _dio.post(
      approveFactConflictPath,
      data: {
        'draft': draft,
        'index': index,
        'topic': topic.trim(),
        'fact_en': factEn.trim(),
        'fact_ar': factAr.trim(),
        'category': category,
      },
    );
    return ChatFactApprovalResult.fromJson(_payload(response));
  }

  /// `get_order_prefill` — what "Start order" hands to the POS. With
  /// [withOrder] the server also reads the order out of the chat with a model
  /// call (~5-15 s), so the receive timeout is raised for that request only.
  Future<ChatOrderPrefill> fetchOrderPrefill(
    String conversation, {
    bool withOrder = false,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.chatGetOrderPrefill,
      queryParameters: {
        'conversation': conversation,
        if (withOrder) 'with_order': 1,
      },
      options:
          withOrder ? Options(receiveTimeout: orderPrefillTimeout) : null,
    );
    return ChatOrderPrefill.fromJson(_payload(response));
  }

  /// `get_chat_metrics` for `from_date`..`to_date` (`YYYY-MM-DD`, inclusive).
  Future<ChatMetrics> fetchMetrics({
    required String fromDate,
    required String toDate,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.chatGetMetrics,
      queryParameters: {'from_date': fromDate, 'to_date': toDate},
    );
    return ChatMetrics.fromJson(_payload(response));
  }

  /// `get_unread_total` — the drawer badge.
  Future<ChatUnreadTotal> fetchUnreadTotal() async {
    final response = await _dio.get(ApiEndpoints.chatGetUnreadTotal);
    return ChatUnreadTotal.fromJson(_payload(response));
  }

  /// The POS customer search (name or phone), reused by "Link customer".
  Future<List<ChatCustomerOption>> searchCustomers(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const <ChatCustomerOption>[];
    final isPhone = RegExp(r'^[0-9+\-\s()]+$').hasMatch(trimmed);
    final response = await _dio.post(
      ApiEndpoints.searchCustomers,
      data: isPhone ? {'phone': trimmed} : {'name': trimmed},
    );
    final payload = _payload(response);
    if (payload is! List) return const <ChatCustomerOption>[];
    return payload
        .whereType<Map>()
        .map(ChatCustomerOption.fromJson)
        .where((c) => c.name.isNotEmpty)
        .toList(growable: false);
  }

  /// Whether [url] is a same-site file path this client may fetch with the
  /// session cookie. Absolute URLs are refused: the session interceptor would
  /// attach the cookie to whatever host they name.
  static bool isSessionMediaUrl(String? url) {
    final value = url?.trim() ?? '';
    return value.startsWith('/private/files/') || value.startsWith('/files/');
  }

  /// Bytes of a message attachment (`/private/files/...`), fetched with the
  /// session so private files work.
  Future<Uint8List> fetchMediaBytes(String mediaUrl) async {
    if (!isSessionMediaUrl(mediaUrl)) {
      throw ArgumentError.value(mediaUrl, 'mediaUrl', 'not a site file path');
    }
    final response = await _dio.get<List<int>>(
      mediaUrl,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': '*/*'},
      ),
    );
    final data = response.data;
    if (data == null) throw Exception('Empty media response');
    return data is Uint8List ? data : Uint8List.fromList(data);
  }

  /// Absolute URL of a site file, for the browser (web) to open with its own
  /// cookie.
  String absoluteMediaUrl(String mediaUrl) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return '$base$mediaUrl';
  }
}
