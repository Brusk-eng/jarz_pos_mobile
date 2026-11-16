// Chat inbox ("moderator reply copilot"): the payloads of `jarz_pos.api.chat`.
//
// Plain classes with hand-written, defensive `fromJson`, like the follow-ups
// feature: Frappe sends ints as bool / num / str depending on the field type
// and leaves keys out when they are empty, so every reader below tolerates a
// missing or oddly-typed value instead of throwing.
//
// Wire values (channel, status, direction, message type, draft status) stay
// exactly as the server sends them. They are mapped to display labels in the
// presentation layer, never here.

import 'dart:convert';

/// Lenient int: `true`/`false`, `3`, `3.0`, `"3"`, `null`.
int chatInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is bool) return value ? 1 : 0;
  if (value is num) return value.toInt();
  final text = value.toString().trim();
  if (text.isEmpty) return fallback;
  final lower = text.toLowerCase();
  if (lower == 'true') return 1;
  if (lower == 'false') return 0;
  return int.tryParse(text) ?? double.tryParse(text)?.toInt() ?? fallback;
}

/// Lenient double, same inputs as [chatInt].
double chatDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is bool) return value ? 1 : 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim()) ?? fallback;
}

/// Lenient nullable double: null when absent or unparseable.
double? chatNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

/// Lenient flag: anything [chatInt] reads as non-zero.
bool chatBool(dynamic value) => chatInt(value) != 0;

/// Lenient string: `null` becomes [fallback], everything else `toString()`.
String chatString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

/// Trimmed string, or null when absent / blank.
String? chatNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

/// A site-tz `"YYYY-MM-DD HH:MM:SS"` read as local wall-clock time. The
/// server and the tills share one timezone (Cairo), so no offset is applied.
DateTime? chatParseDateTime(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  return DateTime.tryParse(value);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

/// `warnings` is specced as a list of strings, but the column behind it is a
/// JSON string; accept both, plus a bare string.
List<String> chatStringList(dynamic value) {
  if (value == null) return const <String>[];
  if (value is List) {
    return value
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
  final text = value.toString().trim();
  if (text.isEmpty) return const <String>[];
  if (text.startsWith('[')) {
    try {
      return chatStringList(jsonDecode(text));
    } catch (_) {
      // Fall through: show it as one warning rather than lose it.
    }
  }
  return <String>[text];
}

/// `{"key": n}` with lenient ints; empty for anything else.
Map<String, int> chatIntMap(dynamic value) {
  if (value is! Map) return const <String, int>{};
  return {
    for (final entry in value.entries)
      entry.key.toString(): chatInt(entry.value),
  };
}

/// The channels a conversation can come from (`Jarz Chat Conversation.channel`).
abstract final class ChatChannels {
  static const whatsApp = 'WhatsApp';
  static const instagram = 'Instagram';
  static const messenger = 'Messenger';
  static const facebookComment = 'Facebook Comment';
  static const instagramComment = 'Instagram Comment';

  static const all = <String>[
    whatsApp,
    instagram,
    messenger,
    facebookComment,
    instagramComment,
  ];
}

/// Conversation statuses (`Jarz Chat Conversation.status`).
abstract final class ChatStatuses {
  static const open = 'Open';
  static const answered = 'Answered';
  static const closed = 'Closed';
}

/// AI / manual contact categories (`Jarz Chat Conversation.contact_category`).
/// A blank category means "not classified yet" and reads as Customer.
abstract final class ChatContactCategories {
  static const customer = 'Customer';
  static const supplier = 'Supplier';
  static const contentCreator = 'Content Creator';
  static const other = 'Other';

  /// The values a moderator can set by hand.
  static const settable = <String>[customer, supplier, contentCreator, other];
}

/// Draft statuses (`Jarz Chat Draft.status`).
abstract final class ChatDraftStatuses {
  static const pending = 'Pending';
  static const held = 'Held';
  static const sentAsIs = 'Sent As-Is';
  static const sentEdited = 'Sent Edited';
  static const rejected = 'Rejected';
  static const superseded = 'Superseded';
  static const blocked = 'Blocked';
  static const failed = 'Failed';
}

/// `ConversationSummary` — one row of the inbox and the thread header.
class ChatConversationSummary {
  final String name;
  final String channel;
  final String? contactName;
  final String? phone;
  final String? customer;
  final String? customerName;
  final String status;
  final String? assignedTo;
  final String? assignedToName;
  final String? intent;
  final bool isComplaint;

  /// Raw site-tz datetimes, kept as sent so a round trip never reformats them.
  final String? lastMessageAt;
  final String? lastMessagePreview;
  final String? lastDirection;
  final int unreadCount;
  final String? waitingSince;
  final String? windowExpiresAt;
  final bool windowOpen;
  final bool hasPendingDraft;
  final String? lastOrder;

  /// `Customer` / `Supplier` / `Content Creator` / `Other`, or null when the
  /// chat is not classified yet (or the server predates categories).
  final String? contactCategory;

  /// `AI` or `Manual`; null when not classified.
  final String? contactCategorySource;

  /// The AI's one-line reason (English).
  final String? contactCategoryReason;

  /// Whether staff may send a photo / video / file here. The server sends
  /// `can_send_media`; when the key is missing it is true for WhatsApp,
  /// Messenger and Instagram and false for comment channels.
  final bool canSendMedia;

  /// The emojis staff may react with on this channel, in display order. Empty
  /// = reactions are not supported (or an older server).
  final List<String> reactionChoices;

  /// Whether this summary carried `can_send_media` / `reaction_choices`. A
  /// socket summary may not; the thread then keeps what it already knew.
  final bool mediaInfoKnown;

  const ChatConversationSummary({
    required this.name,
    this.channel = '',
    this.contactName,
    this.phone,
    this.customer,
    this.customerName,
    this.status = ChatStatuses.open,
    this.assignedTo,
    this.assignedToName,
    this.intent,
    this.isComplaint = false,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.lastDirection,
    this.unreadCount = 0,
    this.waitingSince,
    this.windowExpiresAt,
    this.windowOpen = true,
    this.hasPendingDraft = false,
    this.lastOrder,
    this.contactCategory,
    this.contactCategorySource,
    this.contactCategoryReason,
    this.canSendMedia = true,
    this.reactionChoices = const <String>[],
    this.mediaInfoKnown = false,
  });

  factory ChatConversationSummary.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return ChatConversationSummary(
      name: chatString(json['name']),
      channel: chatString(json['channel']),
      contactName: chatNullableString(json['contact_name']),
      phone: chatNullableString(json['phone']),
      customer: chatNullableString(json['customer']),
      customerName: chatNullableString(json['customer_name']),
      status: chatNullableString(json['status']) ?? ChatStatuses.open,
      assignedTo: chatNullableString(json['assigned_to']),
      assignedToName: chatNullableString(json['assigned_to_name']),
      intent: chatNullableString(json['intent']),
      isComplaint: chatBool(json['is_complaint']),
      lastMessageAt: chatNullableString(json['last_message_at']),
      lastMessagePreview: chatNullableString(json['last_message_preview']),
      lastDirection: chatNullableString(json['last_direction']),
      unreadCount: chatInt(json['unread_count']),
      waitingSince: chatNullableString(json['waiting_since']),
      windowExpiresAt: chatNullableString(json['window_expires_at']),
      // Absent means "unknown"; assume open so the composer is not blocked by
      // an older server that never sent the flag.
      windowOpen: json.containsKey('window_open')
          ? chatBool(json['window_open'])
          : true,
      hasPendingDraft: chatBool(json['has_pending_draft']),
      lastOrder: chatNullableString(json['last_order']),
      contactCategory: chatNullableString(json['contact_category']),
      contactCategorySource: chatNullableString(
        json['contact_category_source'],
      ),
      contactCategoryReason: chatNullableString(
        json['contact_category_reason'],
      ),
      canSendMedia: json.containsKey('can_send_media')
          ? chatBool(json['can_send_media'])
          : chatChannelCanSendMedia(chatString(json['channel'])),
      reactionChoices: chatStringList(json['reaction_choices']),
      mediaInfoKnown: json.containsKey('can_send_media') ||
          json.containsKey('reaction_choices'),
    );
  }

  /// Whether the category was set by the AI (shown with an "AI" marker).
  bool get categoryIsAi => contactCategorySource == 'AI';

  bool get isOpen => status == ChatStatuses.open;
  bool get isClosed => status == ChatStatuses.closed;

  /// The best human label: contact, then linked customer, then phone, then id.
  String get displayName =>
      contactName ?? customerName ?? phone ?? name;

  DateTime? get lastMessageTime => chatParseDateTime(lastMessageAt);
  DateTime? get waitingSinceTime => chatParseDateTime(waitingSince);
  DateTime? get windowExpiresTime => chatParseDateTime(windowExpiresAt);

  /// Whole minutes the customer has been waiting at [now], or null when
  /// nobody is waiting (answered, closed, or no `waiting_since`).
  int? waitingMinutes(DateTime now) {
    if (isClosed) return null;
    final since = waitingSinceTime;
    if (since == null) return null;
    final minutes = now.difference(since).inMinutes;
    return minutes < 0 ? 0 : minutes;
  }

  ChatConversationSummary copyWith({
    int? unreadCount,
    String? status,
    bool? hasPendingDraft,
  }) {
    return ChatConversationSummary(
      name: name,
      channel: channel,
      contactName: contactName,
      phone: phone,
      customer: customer,
      customerName: customerName,
      status: status ?? this.status,
      assignedTo: assignedTo,
      assignedToName: assignedToName,
      intent: intent,
      isComplaint: isComplaint,
      lastMessageAt: lastMessageAt,
      lastMessagePreview: lastMessagePreview,
      lastDirection: lastDirection,
      unreadCount: unreadCount ?? this.unreadCount,
      waitingSince: waitingSince,
      windowExpiresAt: windowExpiresAt,
      windowOpen: windowOpen,
      hasPendingDraft: hasPendingDraft ?? this.hasPendingDraft,
      lastOrder: lastOrder,
      contactCategory: contactCategory,
      contactCategorySource: contactCategorySource,
      contactCategoryReason: contactCategoryReason,
      canSendMedia: canSendMedia,
      reactionChoices: reactionChoices,
      mediaInfoKnown: mediaInfoKnown,
    );
  }

  /// This summary with the media / reaction info of [previous] when this one
  /// did not carry it.
  ChatConversationSummary inheritMediaInfo(ChatConversationSummary previous) {
    if (mediaInfoKnown || !previous.mediaInfoKnown) return this;
    return ChatConversationSummary(
      name: name,
      channel: channel,
      contactName: contactName,
      phone: phone,
      customer: customer,
      customerName: customerName,
      status: status,
      assignedTo: assignedTo,
      assignedToName: assignedToName,
      intent: intent,
      isComplaint: isComplaint,
      lastMessageAt: lastMessageAt,
      lastMessagePreview: lastMessagePreview,
      lastDirection: lastDirection,
      unreadCount: unreadCount,
      waitingSince: waitingSince,
      windowExpiresAt: windowExpiresAt,
      windowOpen: windowOpen,
      hasPendingDraft: hasPendingDraft,
      lastOrder: lastOrder,
      contactCategory: contactCategory,
      contactCategorySource: contactCategorySource,
      contactCategoryReason: contactCategoryReason,
      canSendMedia: previous.canSendMedia,
      reactionChoices: previous.reactionChoices,
      mediaInfoKnown: true,
    );
  }
}

/// Whether a channel can carry media when the server did not say: the direct
/// channels yes, comment channels (and unknown ones) no.
bool chatChannelCanSendMedia(String channel) {
  final c = channel.trim().toLowerCase();
  return c == 'whatsapp' || c == 'messenger' || c == 'instagram';
}

/// `Message` — one bubble in a thread.
class ChatMessage {
  final String name;
  final String direction;
  final String messageType;
  final String body;

  /// `/private/files/...` (fetched with the session) or null.
  final String? mediaUrl;
  final String? mediaMime;
  final String? status;
  final String? sentVia;
  final String? sentBy;
  final String? sentByName;
  final String? timestamp;
  final String? error;

  /// The text of a customer's voice note, filled by the server a few seconds
  /// after the note arrives (a socket update re-sends the message with it).
  /// Null when absent (older servers), not yet transcribed, or blank.
  final String? transcript;

  /// The emoji our team put on this (inbound) message, and the one the
  /// customer put on this (outbound) message. Null when none.
  final String? staffReaction;
  final String? customerReaction;

  const ChatMessage({
    required this.name,
    this.direction = 'Inbound',
    this.messageType = 'text',
    this.body = '',
    this.mediaUrl,
    this.mediaMime,
    this.status,
    this.sentVia,
    this.sentBy,
    this.sentByName,
    this.timestamp,
    this.error,
    this.transcript,
    this.staffReaction,
    this.customerReaction,
  });

  factory ChatMessage.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return ChatMessage(
      name: chatString(json['name']),
      direction: chatNullableString(json['direction']) ?? 'Inbound',
      messageType: chatNullableString(json['message_type']) ?? 'text',
      body: chatString(json['body']),
      mediaUrl: chatNullableString(json['media_url']),
      mediaMime: chatNullableString(json['media_mime']),
      status: chatNullableString(json['status']),
      sentVia: chatNullableString(json['sent_via']),
      sentBy: chatNullableString(json['sent_by']),
      sentByName: chatNullableString(json['sent_by_name']),
      timestamp: chatNullableString(json['timestamp']),
      error: chatNullableString(json['error']),
      transcript: chatNullableString(json['transcript']),
      staffReaction: chatNullableString(json['staff_reaction']),
      customerReaction: chatNullableString(json['customer_reaction']),
    );
  }

  /// A copy carrying [value] as its transcript.
  ChatMessage withTranscript(String? value) {
    if (value == transcript) return this;
    return _copy(transcript: value, setTranscript: true);
  }

  /// A copy with our reaction set to [emoji] (null or empty clears it).
  ChatMessage withStaffReaction(String? emoji) {
    final value = (emoji == null || emoji.isEmpty) ? null : emoji;
    if (value == staffReaction) return this;
    return _copy(staffReaction: value, setStaffReaction: true);
  }

  ChatMessage _copy({
    String? transcript,
    bool setTranscript = false,
    String? staffReaction,
    bool setStaffReaction = false,
  }) {
    return ChatMessage(
      name: name,
      direction: direction,
      messageType: messageType,
      body: body,
      mediaUrl: mediaUrl,
      mediaMime: mediaMime,
      status: status,
      sentVia: sentVia,
      sentBy: sentBy,
      sentByName: sentByName,
      timestamp: timestamp,
      error: error,
      transcript: setTranscript ? transcript : this.transcript,
      staffReaction: setStaffReaction ? staffReaction : this.staffReaction,
      customerReaction: customerReaction,
    );
  }

  bool get isInbound => direction == 'Inbound';
  bool get isOutbound => !isInbound;
  bool get isFailed => status == 'failed';
  DateTime? get time => chatParseDateTime(timestamp);

  /// `"lat,lng"` of a location message, or null.
  ({double lat, double lng})? get location {
    if (messageType != 'location') return null;
    final parts = body.split(',');
    if (parts.length < 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }
}

/// `Draft` — the AI reply waiting for the moderator.
class ChatDraft {
  final String name;
  final String status;
  final String draftText;
  final String? upsellItem;
  final String? upsellItemName;
  final String? upsellText;
  final String? intent;
  final bool isComplaint;
  final String? needsHumanReason;
  final List<String> warnings;

  /// Points where the moderator's instruction went against our facts. The
  /// draft follows the moderator anyway; the panel asks them to confirm these.
  final List<String> factConflicts;
  final String? createdAt;
  final String? forMessage;

  /// Not in the frozen `Draft` shape; read when the server adds it to a
  /// `send_draft` / `reject_draft` answer about a planted (training) draft.
  final String? plantedError;

  /// Also outside the frozen shape (`is_planted` / `planted_caught` columns);
  /// read when present so a rejected training draft can be acknowledged.
  final bool isPlanted;
  final bool plantedCaught;
  final String? error;

  const ChatDraft({
    required this.name,
    this.status = ChatDraftStatuses.pending,
    this.draftText = '',
    this.upsellItem,
    this.upsellItemName,
    this.upsellText,
    this.intent,
    this.isComplaint = false,
    this.needsHumanReason,
    this.warnings = const <String>[],
    this.factConflicts = const <String>[],
    this.createdAt,
    this.forMessage,
    this.plantedError,
    this.isPlanted = false,
    this.plantedCaught = false,
    this.error,
  });

  factory ChatDraft.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return ChatDraft(
      name: chatString(json['name']),
      status: chatNullableString(json['status']) ?? ChatDraftStatuses.pending,
      draftText: chatString(json['draft_text']),
      upsellItem: chatNullableString(json['upsell_item']),
      upsellItemName: chatNullableString(json['upsell_item_name']),
      upsellText: chatNullableString(json['upsell_text']),
      intent: chatNullableString(json['intent']),
      isComplaint: chatBool(json['is_complaint']),
      needsHumanReason: chatNullableString(json['needs_human_reason']),
      warnings: chatStringList(json['warnings']),
      factConflicts: chatStringList(json['fact_conflicts']),
      createdAt: chatNullableString(json['created_at'] ?? json['creation']),
      forMessage: chatNullableString(json['for_message']),
      plantedError: chatNullableString(json['planted_error']),
      isPlanted: chatBool(json['is_planted']),
      plantedCaught: chatBool(json['planted_caught']),
      error: chatNullableString(json['error']),
    );
  }

  /// A copy carrying [plantedError] (when the server sent it beside the
  /// draft rather than on it).
  ChatDraft withPlantedError(String? value) {
    if (value == null || plantedError != null) return this;
    return ChatDraft(
      name: name,
      status: status,
      draftText: draftText,
      upsellItem: upsellItem,
      upsellItemName: upsellItemName,
      upsellText: upsellText,
      intent: intent,
      isComplaint: isComplaint,
      needsHumanReason: needsHumanReason,
      warnings: warnings,
      factConflicts: factConflicts,
      createdAt: createdAt,
      forMessage: forMessage,
      plantedError: value,
      isPlanted: isPlanted,
      plantedCaught: plantedCaught,
      error: error,
    );
  }

  /// Null for a missing / empty payload (`draft: null`, `{}`).
  static ChatDraft? maybeFromJson(dynamic raw) {
    if (raw is! Map || raw.isEmpty) return null;
    final draft = ChatDraft.fromJson(raw);
    return draft.name.isEmpty ? null : draft;
  }

  bool get isPending => status == ChatDraftStatuses.pending;
  bool get isFailed => status == ChatDraftStatuses.failed;

  /// The label for the upsell chip; the item code when no name was sent.
  String? get upsellLabel => upsellItemName ?? upsellItem;

  /// Whether [text] is the draft unchanged (the server's own comparison:
  /// stripped equality).
  bool isUnchanged(String text) => text.trim() == draftText.trim();
}

/// `CustomerCard` — the linked customer at a glance.
class ChatCustomerCard {
  final String name;
  final String customerName;
  final String? mobileNo;
  final String? territory;
  final int totalOrders;
  final String? lastOrderDate;
  final double? lastOrderTotal;
  final double lifetimeValue;
  final List<String> recentItems;

  const ChatCustomerCard({
    required this.name,
    this.customerName = '',
    this.mobileNo,
    this.territory,
    this.totalOrders = 0,
    this.lastOrderDate,
    this.lastOrderTotal,
    this.lifetimeValue = 0,
    this.recentItems = const <String>[],
  });

  factory ChatCustomerCard.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final name = chatString(json['name']);
    return ChatCustomerCard(
      name: name,
      customerName: chatNullableString(json['customer_name']) ?? name,
      mobileNo: chatNullableString(json['mobile_no']),
      territory: chatNullableString(json['territory']),
      totalOrders: chatInt(json['total_orders']),
      lastOrderDate: chatNullableString(json['last_order_date']),
      lastOrderTotal: chatNullableDouble(json['last_order_total']),
      lifetimeValue: chatDouble(json['lifetime_value']),
      recentItems: chatStringList(json['recent_items']),
    );
  }

  static ChatCustomerCard? maybeFromJson(dynamic raw) {
    if (raw is! Map || raw.isEmpty) return null;
    final card = ChatCustomerCard.fromJson(raw);
    return card.name.isEmpty ? null : card;
  }
}

/// `get_conversations` answer.
class ChatConversationPage {
  final List<ChatConversationSummary> conversations;
  final bool hasMore;
  final int openCount;

  /// `{"Supplier": n, "Content Creator": n}` over non-Closed chats; empty
  /// when the server predates categories.
  final Map<String, int> categoryCounts;

  const ChatConversationPage({
    this.conversations = const <ChatConversationSummary>[],
    this.hasMore = false,
    this.openCount = 0,
    this.categoryCounts = const <String, int>{},
  });

  factory ChatConversationPage.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final rows = json['conversations'];
    return ChatConversationPage(
      conversations: rows is List
          ? rows
              .whereType<Map>()
              .map(ChatConversationSummary.fromJson)
              .where((c) => c.name.isNotEmpty)
              .toList(growable: false)
          : const <ChatConversationSummary>[],
      hasMore: chatBool(json['has_more']),
      openCount: chatInt(json['open_count']),
      categoryCounts: chatIntMap(json['category_counts']),
    );
  }
}

/// `get_conversation` answer.
class ChatThread {
  final ChatConversationSummary conversation;

  /// Oldest → newest.
  final List<ChatMessage> messages;

  /// The Pending draft, if any.
  final ChatDraft? draft;
  final ChatCustomerCard? customer;

  /// The strong "this looks like customer X" hint for an unlinked chat
  /// (phone match only); null when linked, weak, or an older server.
  final ChatCustomerCandidate? customerSuggestion;

  const ChatThread({
    required this.conversation,
    this.messages = const <ChatMessage>[],
    this.draft,
    this.customer,
    this.customerSuggestion,
  });

  factory ChatThread.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final rows = json['messages'];
    return ChatThread(
      conversation: ChatConversationSummary.fromJson(json['conversation']),
      messages: rows is List
          ? rows
              .whereType<Map>()
              .map(ChatMessage.fromJson)
              .toList(growable: false)
          : const <ChatMessage>[],
      draft: ChatDraft.maybeFromJson(json['draft']),
      customer: ChatCustomerCard.maybeFromJson(json['customer']),
      customerSuggestion: ChatCustomerCandidate.maybeFromJson(
        json['customer_suggestion'],
      ),
    );
  }
}

/// `send_draft` answer.
class ChatSendDraftResult {
  final ChatMessage? message;
  final ChatDraft draft;

  /// The draft was a deliberate-mistake training check.
  final bool planted;

  /// The moderator's edit removed the planted mistake.
  final bool caught;
  final ChatDraft? nextDraft;

  const ChatSendDraftResult({
    this.message,
    required this.draft,
    this.planted = false,
    this.caught = false,
    this.nextDraft,
  });

  factory ChatSendDraftResult.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final draft = ChatDraft.fromJson(json['draft']);
    final message = json['message'];
    // A top-level `planted_error` is accepted as well, should the server put
    // it beside the draft rather than on it.
    final topLevelError = chatNullableString(json['planted_error']);
    return ChatSendDraftResult(
      message: message is Map && message.isNotEmpty
          ? ChatMessage.fromJson(message)
          : null,
      draft: draft.withPlantedError(topLevelError),
      planted: chatBool(json['planted']),
      caught: chatBool(json['caught']),
      nextDraft: ChatDraft.maybeFromJson(json['next_draft']),
    );
  }

  /// Nothing reached the customer (a planted draft sent as-is is blocked).
  bool get wasSent => message != null;
}

/// `reject_draft` answer.
class ChatRejectResult {
  final ChatDraft draft;
  final ChatDraft? nextDraft;

  /// The rejected draft was a training check (rejecting one always counts
  /// as caught). Read from an optional top-level `planted` or the draft's
  /// `is_planted`; false when the server sends neither.
  final bool planted;

  const ChatRejectResult({
    required this.draft,
    this.nextDraft,
    this.planted = false,
  });

  factory ChatRejectResult.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final draft = ChatDraft.fromJson(json['draft'])
        .withPlantedError(chatNullableString(json['planted_error']));
    return ChatRejectResult(
      draft: draft,
      nextDraft: ChatDraft.maybeFromJson(json['next_draft']),
      planted: chatBool(json['planted']) || draft.isPlanted,
    );
  }
}

/// `link_customer` answer.
class ChatLinkResult {
  final ChatConversationSummary conversation;
  final ChatCustomerCard? customer;

  const ChatLinkResult({required this.conversation, this.customer});

  factory ChatLinkResult.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return ChatLinkResult(
      conversation: ChatConversationSummary.fromJson(json['conversation']),
      customer: ChatCustomerCard.maybeFromJson(json['customer']),
    );
  }
}

/// One flavour picked into a bundle group by the chat order reader.
class ChatPrefillSelection {
  final String itemCode;
  final int qty;

  const ChatPrefillSelection({required this.itemCode, required this.qty});

  factory ChatPrefillSelection.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return ChatPrefillSelection(
      itemCode: chatString(json['item_code']).trim(),
      qty: chatInt(json['qty'], fallback: 1),
    );
  }

  Map<String, dynamic> toJson() => {'item_code': itemCode, 'qty': qty};
}

/// One line of the order the AI read from the chat (`order.lines[]`).
///
/// An item line is `{kind: item, item_code, item_name, qty}`. A bundle line is
/// ONE bundle instance: `{kind: bundle, bundle_id, item_code, item_name, qty,
/// selections: {group_key: [{item_code, qty}]}, complete}`.
class ChatPrefillLine {
  static const kindItem = 'item';
  static const kindBundle = 'bundle';

  final String kind;
  final String itemCode;
  final String itemName;
  final double qty;

  /// `Jarz Bundle` name, which is the POS catalog bundle's `id`.
  final String? bundleId;

  /// group_key -> the flavours picked into that group.
  final Map<String, List<ChatPrefillSelection>> selections;

  /// True when every group's selections add up to the group's quantity.
  final bool complete;

  const ChatPrefillLine({
    required this.kind,
    required this.itemCode,
    required this.itemName,
    required this.qty,
    this.bundleId,
    this.selections = const {},
    this.complete = false,
  });

  bool get isBundle => kind == kindBundle;

  String get displayName => itemName.isNotEmpty ? itemName : itemCode;

  factory ChatPrefillLine.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final bundleId = chatNullableString(json['bundle_id']);
    final rawKind = chatString(json['kind']).trim().toLowerCase();
    // An unknown kind is read from the payload: a bundle id means a bundle.
    final kind = rawKind == kindBundle || (rawKind != kindItem && bundleId != null)
        ? kindBundle
        : kindItem;
    final selections = <String, List<ChatPrefillSelection>>{};
    final rawSelections = json['selections'];
    if (rawSelections is Map) {
      rawSelections.forEach((key, value) {
        final groupKey = key?.toString().trim() ?? '';
        if (groupKey.isEmpty || value is! List) return;
        selections[groupKey] = value
            .whereType<Map>()
            .map(ChatPrefillSelection.fromJson)
            .where((s) => s.itemCode.isNotEmpty)
            .toList(growable: false);
      });
    }
    final itemCode = chatString(json['item_code']).trim();
    return ChatPrefillLine(
      kind: kind,
      itemCode: itemCode,
      itemName: chatNullableString(json['item_name']) ?? itemCode,
      qty: chatDouble(json['qty'], fallback: 1),
      bundleId: bundleId,
      selections: selections,
      complete: chatBool(json['complete']),
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'item_code': itemCode,
        'item_name': itemName,
        'qty': qty,
        if (bundleId != null) 'bundle_id': bundleId,
        if (isBundle)
          'selections': selections.map(
            (key, value) =>
                MapEntry(key, value.map((s) => s.toJson()).toList()),
          ),
        if (isBundle) 'complete': complete,
      };
}

/// A delivery area the customer named that differs from the one on file.
class ChatPrefillArea {
  final String territory;
  final String label;
  final double? deliveryIncome;

  const ChatPrefillArea({
    required this.territory,
    required this.label,
    this.deliveryIncome,
  });

  static ChatPrefillArea? maybeFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final json = _asMap(raw);
    final territory = chatString(json['territory']).trim();
    final label = chatNullableString(json['label']) ?? territory;
    if (territory.isEmpty && label.isEmpty) return null;
    return ChatPrefillArea(
      territory: territory,
      label: label,
      deliveryIncome: chatNullableDouble(json['delivery_income']),
    );
  }

  Map<String, dynamic> toJson() => {
        'territory': territory,
        'label': label,
        if (deliveryIncome != null) 'delivery_income': deliveryIncome,
      };
}

/// A map pin the customer sent in the chat (`order.location`). A resolved
/// link carries coordinates; a short link (maps.app.goo.gl) may not.
class ChatPrefillLocation {
  final double? latitude;
  final double? longitude;
  final String link;

  const ChatPrefillLocation({this.latitude, this.longitude, this.link = ''});

  bool get hasCoordinates => latitude != null && longitude != null;

  /// What "Open map" opens: the link, else a search on the coordinates.
  String? get mapUrl {
    if (link.isNotEmpty) return link;
    if (!hasCoordinates) return null;
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  static ChatPrefillLocation? maybeFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final json = _asMap(raw);
    var latitude = chatNullableDouble(json['latitude']);
    var longitude = chatNullableDouble(json['longitude']);
    // Half a coordinate is no coordinate.
    if (latitude == null || longitude == null) {
      latitude = null;
      longitude = null;
    }
    final link = chatNullableString(json['link']) ?? '';
    if (link.isEmpty && latitude == null) return null;
    return ChatPrefillLocation(
      latitude: latitude,
      longitude: longitude,
      link: link,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'link': link,
      };
}

/// The payment methods the chat reader names (`order.payment_method`).
abstract final class ChatPaymentMethods {
  static const cash = 'cash';
  static const instapay = 'instapay';
  static const wallet = 'wallet';
  static const card = 'card';
}

/// `get_order_prefill(with_order=1)`'s `order`: what the customer asked for
/// in the chat, read by the AI. Nothing here is applied to the customer
/// record; the POS only fills the cart and shows the rest to staff.
class ChatPrefillOrder {
  final List<ChatPrefillLine> lines;

  /// The customer's own message carrying a NEW address, verbatim.
  final String? addressText;
  final ChatPrefillArea? area;

  /// A map pin the customer sent, for the new address.
  final ChatPrefillLocation? location;

  /// A phone / name the customer typed that differs from the one on file.
  final String? phone;
  final String? contactName;
  final bool pickup;
  final String? notes;
  final List<String> warnings;

  /// Promo codes the customer gave, already checked server-side (exist,
  /// usable now, this customer's or public). Applied through the POS's own
  /// promo path once the cart is filled.
  final List<String> promoCodes;

  /// How the customer said they will pay ([ChatPaymentMethods]), lower-case;
  /// display only.
  final String? paymentMethod;

  const ChatPrefillOrder({
    this.lines = const [],
    this.addressText,
    this.area,
    this.location,
    this.phone,
    this.contactName,
    this.pickup = false,
    this.notes,
    this.warnings = const [],
    this.promoCodes = const [],
    this.paymentMethod,
  });

  /// True when there is nothing to put in the cart or show to staff.
  bool get isEmpty =>
      lines.isEmpty &&
      addressText == null &&
      area == null &&
      location == null &&
      phone == null &&
      contactName == null &&
      !pickup &&
      notes == null &&
      warnings.isEmpty &&
      promoCodes.isEmpty &&
      paymentMethod == null;

  /// True when opening the POS changes the cart (lines, pickup or promo
  /// codes), so the chat order gets a cart of its own.
  bool get changesCart => lines.isNotEmpty || pickup || promoCodes.isNotEmpty;

  /// True when "Add as new address" has something to prefill.
  bool get hasNewAddress => addressText != null || location != null;

  static ChatPrefillOrder? maybeFromJson(dynamic raw) {
    if (raw is! Map) return null;
    return ChatPrefillOrder.fromJson(raw);
  }

  factory ChatPrefillOrder.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final rawLines = json['lines'];
    final address = json['address'];
    final addressText = address is Map
        ? chatNullableString(address['text'])
        : chatNullableString(address);
    final promoCodes = <String>[];
    for (final code in chatStringList(json['promo_codes'])) {
      final normalized = code.toUpperCase();
      if (!promoCodes.contains(normalized)) promoCodes.add(normalized);
    }
    return ChatPrefillOrder(
      lines: rawLines is List
          ? rawLines
              .whereType<Map>()
              .map(ChatPrefillLine.fromJson)
              .where((l) => l.itemCode.isNotEmpty || l.bundleId != null)
              .toList(growable: false)
          : const [],
      addressText: addressText,
      area: ChatPrefillArea.maybeFromJson(json['area']),
      location: ChatPrefillLocation.maybeFromJson(json['location']),
      phone: chatNullableString(json['phone']),
      contactName: chatNullableString(json['contact_name']),
      pickup: chatBool(json['pickup']),
      notes: chatNullableString(json['notes']),
      warnings: chatStringList(json['warnings']),
      promoCodes: List.unmodifiable(promoCodes),
      paymentMethod: chatNullableString(json['payment_method'])?.toLowerCase(),
    );
  }

  /// The wire shape again, so the order can travel in a route's `extra`.
  Map<String, dynamic> toJson() => {
        'lines': lines.map((l) => l.toJson()).toList(),
        'address': addressText == null ? null : {'text': addressText},
        'area': area?.toJson(),
        'location': location?.toJson(),
        'phone': phone,
        'contact_name': contactName,
        'pickup': pickup,
        'notes': notes,
        'warnings': warnings,
        'promo_codes': promoCodes,
        'payment_method': paymentMethod,
      };
}

/// `get_order_prefill` answer.
class ChatOrderPrefill {
  /// `{name, customer_name, mobile_no}` ready for `PosNotifier.selectCustomer`,
  /// or null when the chat has no linked customer yet.
  final Map<String, dynamic>? customer;
  final String? phone;
  final String? contactName;

  /// The order read from the chat (`with_order=1` only); null when it was not
  /// asked for or the reader is off / failed ([orderError] then says why).
  final ChatPrefillOrder? order;
  final String? orderError;

  const ChatOrderPrefill({
    this.customer,
    this.phone,
    this.contactName,
    this.order,
    this.orderError,
  });

  factory ChatOrderPrefill.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final customer = json['customer'];
    Map<String, dynamic>? customerMap;
    if (customer is Map && chatNullableString(customer['name']) != null) {
      final name = chatString(customer['name']).trim();
      customerMap = <String, dynamic>{
        'name': name,
        'customer_name': chatNullableString(customer['customer_name']) ?? name,
        'mobile_no': chatString(customer['mobile_no']),
      };
    }
    return ChatOrderPrefill(
      customer: customerMap,
      phone: chatNullableString(json['phone']),
      contactName: chatNullableString(json['contact_name']),
      order: ChatPrefillOrder.maybeFromJson(json['order']),
      orderError: chatNullableString(json['order_error']),
    );
  }
}

/// `get_unread_total` answer (drawer badge).
class ChatUnreadTotal {
  final int openCount;
  final int unreadTotal;

  const ChatUnreadTotal({this.openCount = 0, this.unreadTotal = 0});

  static const zero = ChatUnreadTotal();

  factory ChatUnreadTotal.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return ChatUnreadTotal(
      openCount: chatInt(json['open_count']),
      unreadTotal: chatInt(json['unread_total']),
    );
  }
}

/// `Metrics.drafts`.
class ChatDraftMetrics {
  final int total;
  final int sentAsIs;
  final int sentEdited;
  final int rejected;
  final int superseded;
  final int blocked;

  const ChatDraftMetrics({
    this.total = 0,
    this.sentAsIs = 0,
    this.sentEdited = 0,
    this.rejected = 0,
    this.superseded = 0,
    this.blocked = 0,
  });

  factory ChatDraftMetrics.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return ChatDraftMetrics(
      total: chatInt(json['total']),
      sentAsIs: chatInt(json['sent_as_is']),
      sentEdited: chatInt(json['sent_edited']),
      rejected: chatInt(json['rejected']),
      superseded: chatInt(json['superseded']),
      blocked: chatInt(json['blocked']),
    );
  }
}

/// One row of `Metrics.by_moderator`.
class ChatModeratorMetrics {
  final String user;
  final String fullName;
  final int sent;
  final int asIs;
  final int edited;
  final int rejected;

  const ChatModeratorMetrics({
    required this.user,
    this.fullName = '',
    this.sent = 0,
    this.asIs = 0,
    this.edited = 0,
    this.rejected = 0,
  });

  factory ChatModeratorMetrics.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final user = chatString(json['user']);
    return ChatModeratorMetrics(
      user: user,
      fullName: chatNullableString(json['full_name']) ?? user,
      sent: chatInt(json['sent']),
      asIs: chatInt(json['as_is']),
      edited: chatInt(json['edited']),
      rejected: chatInt(json['rejected']),
    );
  }
}

/// `get_chat_metrics` answer.
class ChatMetrics {
  final String fromDate;
  final String toDate;
  final int conversations;
  final int inboundMessages;
  final int outboundMessages;
  final double? medianFirstResponseMinutes;
  final int unansweredOpen;
  final int waitingOverAlert;
  final ChatDraftMetrics drafts;

  /// 0..1 as sent; older servers may send a percentage (handled at display).
  final double asIsRate;
  final int plantedTotal;
  final int plantedCaught;
  final double costUsd;
  final List<ChatModeratorMetrics> byModerator;

  const ChatMetrics({
    this.fromDate = '',
    this.toDate = '',
    this.conversations = 0,
    this.inboundMessages = 0,
    this.outboundMessages = 0,
    this.medianFirstResponseMinutes,
    this.unansweredOpen = 0,
    this.waitingOverAlert = 0,
    this.drafts = const ChatDraftMetrics(),
    this.asIsRate = 0,
    this.plantedTotal = 0,
    this.plantedCaught = 0,
    this.costUsd = 0,
    this.byModerator = const <ChatModeratorMetrics>[],
  });

  factory ChatMetrics.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final planted = _asMap(json['planted']);
    final rows = json['by_moderator'];
    return ChatMetrics(
      fromDate: chatString(json['from_date']),
      toDate: chatString(json['to_date']),
      conversations: chatInt(json['conversations']),
      inboundMessages: chatInt(json['inbound_messages']),
      outboundMessages: chatInt(json['outbound_messages']),
      medianFirstResponseMinutes:
          chatNullableDouble(json['median_first_response_minutes']),
      unansweredOpen: chatInt(json['unanswered_open']),
      waitingOverAlert: chatInt(json['waiting_over_alert']),
      drafts: ChatDraftMetrics.fromJson(json['drafts']),
      asIsRate: chatDouble(json['as_is_rate']),
      plantedTotal: chatInt(planted['total']),
      plantedCaught: chatInt(planted['caught']),
      costUsd: chatDouble(json['cost_usd']),
      byModerator: rows is List
          ? rows
              .whereType<Map>()
              .map(ChatModeratorMetrics.fromJson)
              .toList(growable: false)
          : const <ChatModeratorMetrics>[],
    );
  }

  /// [asIsRate] as a 0..100 percentage, whichever scale the server used.
  double get asIsPercent => asIsRate <= 1 ? asIsRate * 100 : asIsRate;
}

/// A `jarz_chat_update` socket payload.
class ChatUpdateEvent {
  final String conversation;

  /// `message` | `draft` | `status` | `assigned`.
  final String kind;
  final ChatConversationSummary? summary;
  final ChatMessage? message;
  final ChatDraft? draft;

  const ChatUpdateEvent({
    required this.conversation,
    this.kind = '',
    this.summary,
    this.message,
    this.draft,
  });

  factory ChatUpdateEvent.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final summaryRaw = json['summary'];
    final summary = summaryRaw is Map && summaryRaw.isNotEmpty
        ? ChatConversationSummary.fromJson(summaryRaw)
        : null;
    final messageRaw = json['message'];
    final conversation = chatNullableString(json['conversation']) ??
        summary?.name ??
        '';
    return ChatUpdateEvent(
      conversation: conversation,
      kind: chatString(json['kind']),
      summary: summary != null && summary.name.isNotEmpty ? summary : null,
      message: messageRaw is Map && messageRaw.isNotEmpty
          ? ChatMessage.fromJson(messageRaw)
          : null,
      draft: ChatDraft.maybeFromJson(json['draft']),
    );
  }
}

/// One `search_customers` hit offered by "Link customer".
class ChatCustomerOption {
  final String name;
  final String customerName;
  final String? mobileNo;

  const ChatCustomerOption({
    required this.name,
    this.customerName = '',
    this.mobileNo,
  });

  factory ChatCustomerOption.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final name = chatString(json['name']);
    return ChatCustomerOption(
      name: name,
      customerName: chatNullableString(json['customer_name']) ?? name,
      mobileNo: chatNullableString(json['mobile_no'] ?? json['phone']),
    );
  }
}

/// Why a customer was suggested for a chat (`candidates[].reasons`).
abstract final class ChatSuggestionReasons {
  static const phone = 'phone';
  static const typedPhone = 'typed_phone';
  static const name = 'name';
  static const sameContact = 'same_contact';
}

/// One `suggest_customers` candidate (also `customer_suggestion`).
class ChatCustomerCandidate {
  final String name;
  final String customerName;
  final String? mobileNo;
  final String? territory;
  final int totalOrders;
  final String? lastOrderDate;
  final List<String> reasons;
  final double score;

  const ChatCustomerCandidate({
    required this.name,
    this.customerName = '',
    this.mobileNo,
    this.territory,
    this.totalOrders = 0,
    this.lastOrderDate,
    this.reasons = const <String>[],
    this.score = 0,
  });

  factory ChatCustomerCandidate.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final name = chatString(json['name']);
    return ChatCustomerCandidate(
      name: name,
      customerName: chatNullableString(json['customer_name']) ?? name,
      mobileNo: chatNullableString(json['mobile_no']),
      territory: chatNullableString(json['territory']),
      totalOrders: chatInt(json['total_orders']),
      lastOrderDate: chatNullableString(json['last_order_date']),
      reasons: chatStringList(json['reasons']),
      score: chatDouble(json['score']),
    );
  }

  /// Null for a missing / empty payload.
  static ChatCustomerCandidate? maybeFromJson(dynamic raw) {
    if (raw is! Map || raw.isEmpty) return null;
    final candidate = ChatCustomerCandidate.fromJson(raw);
    return candidate.name.isEmpty ? null : candidate;
  }

  /// The same customer as a link-sheet option.
  ChatCustomerOption toOption() => ChatCustomerOption(
    name: name,
    customerName: customerName,
    mobileNo: mobileNo,
  );
}

/// A new-customer starting point read from the chat: `prefill` of
/// `suggest_customers` (no AI) and of `get_new_customer_prefill` (`ai`).
class ChatNewCustomerPrefill {
  final String customerName;
  final String? mobileNo;
  final List<String> phones;
  final String? address;

  /// The Territory record name (what `create_customer` takes).
  final String? territory;
  final String? territoryName;

  /// `"lat,lng"` or a Maps link.
  final String? location;
  final bool ai;
  final String? aiError;

  const ChatNewCustomerPrefill({
    this.customerName = '',
    this.mobileNo,
    this.phones = const <String>[],
    this.address,
    this.territory,
    this.territoryName,
    this.location,
    this.ai = false,
    this.aiError,
  });

  static const empty = ChatNewCustomerPrefill();

  factory ChatNewCustomerPrefill.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final mobile = chatNullableString(json['mobile_no']);
    final phones = chatStringList(json['phones']);
    return ChatNewCustomerPrefill(
      customerName: chatNullableString(json['customer_name']) ?? '',
      mobileNo: mobile,
      // The chosen mobile is always offered as a chip.
      phones: mobile != null && !phones.contains(mobile)
          ? <String>[mobile, ...phones]
          : phones,
      address: chatNullableString(json['address']),
      territory: chatNullableString(json['territory']),
      territoryName: chatNullableString(json['territory_name']),
      location: chatNullableString(json['location']),
      ai: chatBool(json['ai']),
      aiError: chatNullableString(json['ai_error']),
    );
  }

  /// `(lat, lng)` when [location] is a coordinate pair.
  ({double lat, double lng})? get coordinates {
    final value = location;
    if (value == null) return null;
    final parts = value.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }

  /// [location] when it is a link rather than coordinates.
  String? get locationLink =>
      location != null && coordinates == null ? location : null;
}

/// `suggest_customers` answer.
class ChatSuggestCustomersResult {
  final List<ChatCustomerCandidate> candidates;
  final ChatNewCustomerPrefill prefill;

  const ChatSuggestCustomersResult({
    this.candidates = const <ChatCustomerCandidate>[],
    this.prefill = ChatNewCustomerPrefill.empty,
  });

  factory ChatSuggestCustomersResult.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final rows = json['candidates'];
    return ChatSuggestCustomersResult(
      candidates: rows is List
          ? rows
                .whereType<Map>()
                .map(ChatCustomerCandidate.fromJson)
                .where((c) => c.name.isNotEmpty)
                .toList(growable: false)
          : const <ChatCustomerCandidate>[],
      prefill: ChatNewCustomerPrefill.fromJson(json['prefill']),
    );
  }

  /// The best phone to search with: the chat's own, else the first typed.
  String? get bestPhone {
    final mobile = prefill.mobileNo;
    if (mobile != null) return mobile;
    return prefill.phones.isEmpty ? null : prefill.phones.first;
  }
}

/// `create_customer_from_chat` answer: a created-and-linked customer, or the
/// customer that already owns the mobile (`existing`).
class ChatCreateCustomerResult {
  final ChatConversationSummary? conversation;
  final ChatCustomerCard? customer;
  final ChatCustomerCandidate? existing;
  final bool created;

  const ChatCreateCustomerResult({
    this.conversation,
    this.customer,
    this.existing,
    this.created = false,
  });

  factory ChatCreateCustomerResult.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final conversation = json['conversation'];
    return ChatCreateCustomerResult(
      conversation: conversation is Map && conversation.isNotEmpty
          ? ChatConversationSummary.fromJson(conversation)
          : null,
      customer: ChatCustomerCard.maybeFromJson(json['customer']),
      existing: ChatCustomerCandidate.maybeFromJson(json['existing']),
      created: chatBool(json['created']),
    );
  }
}

/// One moderator override from `get_fact_overrides`.
class ChatFactOverrideRow {
  final String draft;
  final String conversation;
  final String? contactName;
  final String channel;
  final String? createdAt;
  final String? requestedBy;
  final String? requestedByName;
  final String? moderatorHint;
  final List<String> conflicts;
  final String status;
  final String? finalText;
  final String? draftText;

  const ChatFactOverrideRow({
    required this.draft,
    this.conversation = '',
    this.contactName,
    this.channel = '',
    this.createdAt,
    this.requestedBy,
    this.requestedByName,
    this.moderatorHint,
    this.conflicts = const <String>[],
    this.status = '',
    this.finalText,
    this.draftText,
  });

  factory ChatFactOverrideRow.fromJson(dynamic raw) {
    final json = _asMap(raw);
    return ChatFactOverrideRow(
      draft: chatString(json['draft']),
      conversation: chatString(json['conversation']),
      contactName: chatNullableString(json['contact_name']),
      channel: chatString(json['channel']),
      createdAt: chatNullableString(json['created_at']),
      requestedBy: chatNullableString(json['requested_by']),
      requestedByName: chatNullableString(json['requested_by_name']),
      moderatorHint: chatNullableString(json['moderator_hint']),
      conflicts: chatStringList(json['conflicts']),
      status: chatString(json['status']),
      finalText: chatNullableString(json['final_text']),
      draftText: chatNullableString(json['draft_text']),
    );
  }

  DateTime? get time => chatParseDateTime(createdAt);
  String get requester => requestedByName ?? requestedBy ?? '';

  /// What went out when sent, else the draft text.
  String? get shownText => finalText ?? draftText;
  bool get wasSent => status.startsWith('Sent');
}

/// `get_fact_overrides` answer.
class ChatFactOverridesPage {
  final List<ChatFactOverrideRow> rows;
  final bool hasMore;
  final int total;

  const ChatFactOverridesPage({
    this.rows = const <ChatFactOverrideRow>[],
    this.hasMore = false,
    this.total = 0,
  });

  factory ChatFactOverridesPage.fromJson(dynamic raw) {
    final json = _asMap(raw);
    final rows = json['rows'];
    final parsed = rows is List
        ? rows
              .whereType<Map>()
              .map(ChatFactOverrideRow.fromJson)
              .where((r) => r.draft.isNotEmpty || r.conversation.isNotEmpty)
              .toList(growable: false)
        : const <ChatFactOverrideRow>[];
    return ChatFactOverridesPage(
      rows: parsed,
      hasMore: chatBool(json['has_more']),
      total: chatInt(json['total'], fallback: parsed.length),
    );
  }
}
