import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/user_service.dart';
import '../../../core/websocket/websocket_service.dart';
import '../data/chat_repository.dart';
import '../data/models/chat_models.dart';

/// The clock the inbox's "waiting N min" labels read. Overridden in tests.
final chatClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Subscribes [onEvent] to `jarz_chat_update`. Returns null when the socket
/// service cannot be built (no env in a test), so a screen still loads over
/// plain HTTP.
StreamSubscription<Map<String, dynamic>>? listenChatUpdates(
  Ref ref,
  void Function(ChatUpdateEvent event) onEvent,
) {
  try {
    final ws = ref.read(webSocketServiceProvider);
    return ws.chatUpdates.listen((raw) {
      final ChatUpdateEvent event;
      try {
        event = ChatUpdateEvent.fromJson(raw);
      } catch (_) {
        return;
      }
      if (event.conversation.isEmpty) return;
      onEvent(event);
    });
  } catch (_) {
    return null;
  }
}

String? _currentUser(Ref ref) =>
    ref.read(userRolesFutureProvider).valueOrNull?.user;

// ─────────────────────────────────────────────────────────────────────────
// Inbox
// ─────────────────────────────────────────────────────────────────────────

/// The inbox's segmented control.
enum ChatInboxSegment { open, mine, all, closed }

/// What the inbox is showing: segment, optional channel, search text.
class ChatInboxFilter {
  final ChatInboxSegment segment;
  final String? channel;
  final String search;

  /// A [ChatContactCategories] value (`Customer` also matches unclassified
  /// chats), or null for every category.
  final String? category;

  const ChatInboxFilter({
    this.segment = ChatInboxSegment.open,
    this.channel,
    this.search = '',
    this.category,
  });

  /// `status` for `get_conversations`. "Open" means "not Closed" (Open and
  /// Answered), so a chat does not vanish the moment a moderator replies: it
  /// is sent as `all` plus `exclude_closed=1` (see [excludeClosed]). "Mine"
  /// spans every status: a moderator's own answered chats are still theirs.
  String get wireStatus => switch (segment) {
        ChatInboxSegment.closed => ChatStatuses.closed,
        ChatInboxSegment.open ||
        ChatInboxSegment.mine ||
        ChatInboxSegment.all =>
          'all',
      };

  /// Whether Closed chats are left out: sent as `exclude_closed=1`, and also
  /// filtered on the client because an older backend ignores the parameter.
  bool get excludeClosed => segment == ChatInboxSegment.open;

  bool get mine => segment == ChatInboxSegment.mine;
  bool get hasSearch => search.trim().isNotEmpty;

  ChatInboxFilter copyWith({
    ChatInboxSegment? segment,
    String? channel,
    bool clearChannel = false,
    String? search,
    String? category,
    bool clearCategory = false,
  }) {
    return ChatInboxFilter(
      segment: segment ?? this.segment,
      channel: clearChannel ? null : (channel ?? this.channel),
      search: search ?? this.search,
      category: clearCategory ? null : (category ?? this.category),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChatInboxFilter &&
      other.segment == segment &&
      other.channel == channel &&
      other.search == search &&
      other.category == category;

  @override
  int get hashCode => Object.hash(segment, channel, search, category);
}

/// Whether [summary] belongs in a list loaded with [filter], judged locally
/// so a socket update can add, move or drop a row without a refetch. Search
/// is not re-implemented here: with a search active only rows already shown
/// are updated (see [ChatInboxNotifier.applySummary]).
bool chatSummaryMatchesFilter(
  ChatConversationSummary summary,
  ChatInboxFilter filter,
  String? currentUser,
) {
  if (filter.channel != null && summary.channel != filter.channel) {
    return false;
  }
  final category = filter.category;
  if (category != null) {
    final own = summary.contactCategory;
    final matchesCategory = category == ChatContactCategories.customer
        ? (own == null || own.isEmpty || own == category)
        : own == category;
    if (!matchesCategory) return false;
  }
  return switch (filter.segment) {
    ChatInboxSegment.open => summary.status != ChatStatuses.closed,
    ChatInboxSegment.closed => summary.status == ChatStatuses.closed,
    ChatInboxSegment.mine =>
      currentUser != null && summary.assignedTo == currentUser,
    ChatInboxSegment.all => true,
  };
}

/// Newest activity first; rows with no timestamp sink to the bottom.
int compareChatSummaries(ChatConversationSummary a, ChatConversationSummary b) {
  final at = a.lastMessageAt ?? '';
  final bt = b.lastMessageAt ?? '';
  return bt.compareTo(at);
}

class ChatInboxState {
  final ChatInboxFilter filter;
  final List<ChatConversationSummary> conversations;
  final bool hasMore;
  final int openCount;
  final bool loadingMore;

  /// Server counts for the Supplier / Content Creator filter chips.
  final Map<String, int> categoryCounts;

  /// The `before` cursor for the next page: the `last_message_at` of the last
  /// row the SERVER returned, before any client-side filtering. Keyed on the
  /// raw page so dropping Closed rows locally never skips or repeats a page.
  final String? nextBefore;

  const ChatInboxState({
    this.filter = const ChatInboxFilter(),
    this.conversations = const <ChatConversationSummary>[],
    this.hasMore = false,
    this.openCount = 0,
    this.loadingMore = false,
    this.nextBefore,
    this.categoryCounts = const <String, int>{},
  });

  ChatInboxState copyWith({
    ChatInboxFilter? filter,
    List<ChatConversationSummary>? conversations,
    bool? hasMore,
    int? openCount,
    bool? loadingMore,
    String? nextBefore,
    Map<String, int>? categoryCounts,
  }) {
    return ChatInboxState(
      filter: filter ?? this.filter,
      conversations: conversations ?? this.conversations,
      hasMore: hasMore ?? this.hasMore,
      openCount: openCount ?? this.openCount,
      loadingMore: loadingMore ?? this.loadingMore,
      nextBefore: nextBefore ?? this.nextBefore,
      categoryCounts: categoryCounts ?? this.categoryCounts,
    );
  }
}

/// One fetched slice of the inbox: the rows that passed the client-side
/// filter, and pagination judged on the raw server pages.
class ChatInboxFetch {
  final List<ChatConversationSummary> rows;

  /// `last_message_at` of the last raw row fetched (the next `before`).
  final String? cursor;
  final bool hasMore;
  final int openCount;
  final Map<String, int> categoryCounts;

  const ChatInboxFetch({
    required this.rows,
    required this.cursor,
    required this.hasMore,
    required this.openCount,
    this.categoryCounts = const <String, int>{},
  });
}

/// Whether the app is in the foreground, for the polling timers. `inactive`
/// still counts (a desktop/web window that lost focus is still on screen);
/// an unknown state (no binding, as in a plain unit test) counts too.
bool chatAppInForeground() {
  try {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null ||
        lifecycle == AppLifecycleState.resumed ||
        lifecycle == AppLifecycleState.inactive;
  } catch (_) {
    return true;
  }
}

/// Merge a freshly fetched first page into [latest] without resetting what
/// the moderator scrolled to. Rows inside the fresh page's time window are
/// replaced by the page (so a row that left the filter drops out); rows older
/// than the window (later pages already loaded) are kept as they are.
ChatInboxState mergeChatInboxFirstPage(
  ChatInboxState latest,
  ChatInboxFetch fresh,
) {
  final freshRows = [...fresh.rows]..sort(compareChatSummaries);
  if (!fresh.hasMore) {
    // The fresh page is the whole list.
    return latest
        .copyWith(
          conversations: freshRows,
          hasMore: false,
          openCount: fresh.openCount,
          categoryCounts: fresh.categoryCounts.isEmpty
              ? null
              : fresh.categoryCounts,
        )
        .withCursor(fresh.cursor);
  }
  final windowEnd = fresh.cursor!;
  final freshNames = {for (final c in freshRows) c.name};
  final older = latest.conversations.where((c) {
    if (freshNames.contains(c.name)) return false;
    final at = c.lastMessageAt;
    return at == null || at.isEmpty || at.compareTo(windowEnd) < 0;
  });
  final merged = [...freshRows, ...older]..sort(compareChatSummaries);
  final loadedCursor = latest.nextBefore;
  final keepLoaded = loadedCursor != null &&
      loadedCursor.isNotEmpty &&
      loadedCursor.compareTo(windowEnd) < 0;
  return ChatInboxState(
    filter: latest.filter,
    conversations: merged,
    hasMore: keepLoaded ? latest.hasMore : true,
    openCount: fresh.openCount,
    loadingMore: latest.loadingMore,
    nextBefore: keepLoaded ? loadedCursor : windowEnd,
    categoryCounts: fresh.categoryCounts.isEmpty
        ? latest.categoryCounts
        : fresh.categoryCounts,
  );
}

extension on ChatInboxState {
  /// [copyWith] cannot clear [nextBefore]; this sets it, null included.
  ChatInboxState withCursor(String? cursor) => ChatInboxState(
    filter: filter,
    conversations: conversations,
    hasMore: hasMore,
    openCount: openCount,
    loadingMore: loadingMore,
    nextBefore: cursor,
    categoryCounts: categoryCounts,
  );
}

class ChatInboxNotifier extends AutoDisposeAsyncNotifier<ChatInboxState> {
  static const pageSize = 30;

  /// How often the open inbox re-reads its first page (realtime events do
  /// not always arrive), and the wait after a failed poll.
  static const pollInterval = Duration(seconds: 15);
  static const pollErrorBackoff = Duration(seconds: 30);

  /// With Closed rows dropped on the client (an older backend), a raw page
  /// can filter down to nothing; read on up to this many pages for a row.
  static const maxPagesPerFetch = 4;

  ChatInboxFilter _filter = const ChatInboxFilter();
  int _requestSeq = 0;

  Timer? _poll;
  int _pollGeneration = 0;
  bool _silentInFlight = false;

  ChatInboxFilter get filter => _filter;

  @override
  Future<ChatInboxState> build() async {
    final sub = listenChatUpdates(ref, _onChatUpdate);
    _poll?.cancel();
    final generation = ++_pollGeneration;
    ref.onDispose(() {
      sub?.cancel();
      _poll?.cancel();
      _poll = null;
      _pollGeneration++;
    });
    _schedulePoll(generation, pollInterval);
    return _load(_filter);
  }

  /// Fetch from [before] (null: the first page), dropping rows the filter
  /// excludes on the client. The cursor and "has more" come from the raw
  /// server page, never from the filtered rows.
  Future<ChatInboxFetch> _fetch(ChatInboxFilter filter, {String? before}) async {
    final repo = ref.read(chatRepositoryProvider);
    final rows = <ChatConversationSummary>[];
    final seen = <String>{};
    var cursor = before;
    var hasMore = false;
    var openCount = 0;
    var categoryCounts = const <String, int>{};
    for (var i = 0; i < maxPagesPerFetch; i++) {
      final page = await repo.fetchConversations(
        status: filter.wireStatus,
        channel: filter.channel,
        search: filter.search,
        mine: filter.mine,
        limit: pageSize,
        before: cursor,
        excludeClosed: filter.excludeClosed,
        category: filter.category,
      );
      if (i == 0) {
        openCount = page.openCount;
        categoryCounts = page.categoryCounts;
      }
      final raw = page.conversations;
      final rawLast = raw.isEmpty ? null : raw.last.lastMessageAt;
      final advanced =
          rawLast != null && rawLast.isNotEmpty && rawLast != cursor;
      if (advanced) cursor = rawLast;
      hasMore = advanced && (page.hasMore || raw.length >= pageSize);
      for (final row in raw) {
        if (filter.excludeClosed && row.status == ChatStatuses.closed) {
          continue;
        }
        if (seen.add(row.name)) rows.add(row);
      }
      if (rows.isNotEmpty || !hasMore) break;
    }
    return ChatInboxFetch(
      rows: rows,
      cursor: cursor,
      hasMore: hasMore,
      openCount: openCount,
      categoryCounts: categoryCounts,
    );
  }

  Future<ChatInboxState> _load(ChatInboxFilter filter) async {
    final fetched = await _fetch(filter);
    return ChatInboxState(
      filter: filter,
      conversations: fetched.rows,
      hasMore: fetched.hasMore,
      openCount: fetched.openCount,
      nextBefore: fetched.cursor,
      categoryCounts: fetched.categoryCounts,
    );
  }

  /// Reload with the current filter. The old rows stay on screen meanwhile;
  /// a slower, older request never overwrites a newer one.
  Future<void> refresh() => _reload(_filter);

  Future<void> setFilter(ChatInboxFilter filter) async {
    if (filter == _filter && state.hasValue) return;
    _filter = filter;
    await _reload(filter);
  }

  Future<void> _reload(ChatInboxFilter filter) async {
    final seq = ++_requestSeq;
    state = const AsyncLoading<ChatInboxState>().copyWithPrevious(state);
    final next = await AsyncValue.guard(() => _load(filter));
    if (seq != _requestSeq) return;
    state = next;
  }

  /// Re-read the first page and merge it in place: no spinner, no reset of
  /// the loaded pages or the scroll position. Skipped while a load, a reload
  /// or another silent refresh is running. Returns false when the fetch
  /// failed; errors never reach the screen.
  Future<bool> silentRefresh() async {
    final current = state.valueOrNull;
    if (current == null ||
        state.isLoading ||
        current.loadingMore ||
        _silentInFlight) {
      return true;
    }
    final seq = _requestSeq;
    final filter = current.filter;
    _silentInFlight = true;
    try {
      final fresh = await _fetch(filter);
      if (seq != _requestSeq) return true;
      final latest = state.valueOrNull;
      if (latest == null ||
          state.isLoading ||
          latest.loadingMore ||
          latest.filter != filter) {
        return true;
      }
      final merged = mergeChatInboxFirstPage(latest, fresh);
      state = AsyncData(merged);
      _syncBadge(latest, merged);
      return true;
    } catch (_) {
      return false;
    } finally {
      _silentInFlight = false;
    }
  }

  /// The drawer badge and the Open segment count read `get_unread_total`;
  /// re-read it when the poll saw the counts move.
  void _syncBadge(ChatInboxState before, ChatInboxState after) {
    if (!ref.exists(chatUnreadTotalProvider)) return;
    int unread(ChatInboxState s) =>
        s.conversations.fold(0, (sum, c) => sum + c.unreadCount);
    final badge = ref.read(chatUnreadTotalProvider).valueOrNull;
    final moved = badge == null ||
        badge.openCount != after.openCount ||
        before.openCount != after.openCount ||
        unread(before) != unread(after);
    if (moved) ref.invalidate(chatUnreadTotalProvider);
  }

  void _schedulePoll(int generation, Duration delay) {
    if (generation != _pollGeneration) return;
    _poll?.cancel();
    _poll = Timer(delay, () => unawaited(_pollTick(generation)));
  }

  Future<void> _pollTick(int generation) async {
    if (generation != _pollGeneration) return;
    var ok = true;
    if (chatAppInForeground()) ok = await silentRefresh();
    _schedulePoll(generation, ok ? pollInterval : pollErrorBackoff);
  }

  /// Next page, keyed on the raw cursor of the last server page.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;
    final before = current.nextBefore ??
        (current.conversations.isEmpty
            ? null
            : current.conversations.last.lastMessageAt);
    if (before == null || before.isEmpty) return;
    final seq = _requestSeq;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final fetched = await _fetch(current.filter, before: before);
      if (seq != _requestSeq) return;
      final latest = state.valueOrNull ?? current;
      final seen = latest.conversations.map((c) => c.name).toSet();
      state = AsyncData(latest.copyWith(
        conversations: [
          ...latest.conversations,
          ...fetched.rows.where((c) => !seen.contains(c.name)),
        ],
        hasMore: fetched.hasMore,
        loadingMore: false,
      ).withCursor(fetched.cursor));
    } catch (_) {
      if (seq != _requestSeq) return;
      final latest = state.valueOrNull ?? current;
      state = AsyncData(latest.copyWith(loadingMore: false));
      rethrow;
    }
  }

  /// Merge a fresh summary (socket event or the thread's own mutation):
  /// update, insert, or drop the row depending on whether it still matches.
  void applySummary(ChatConversationSummary summary) {
    final current = state.valueOrNull;
    if (current == null || summary.name.isEmpty) return;
    final rows = [...current.conversations];
    final index = rows.indexWhere((c) => c.name == summary.name);
    final matches =
        chatSummaryMatchesFilter(summary, current.filter, _currentUser(ref));
    if (matches) {
      if (index >= 0) {
        rows[index] = summary;
      } else if (current.filter.hasSearch) {
        // Cannot tell locally whether it matches the search text.
        return;
      } else {
        rows.add(summary);
      }
      rows.sort(compareChatSummaries);
    } else if (index >= 0) {
      rows.removeAt(index);
    } else {
      return;
    }
    state = AsyncData(current.copyWith(conversations: rows));
  }

  /// Zero a row's unread count when its thread is opened.
  void markRead(String name) {
    final current = state.valueOrNull;
    if (current == null) return;
    final index = current.conversations.indexWhere((c) => c.name == name);
    if (index < 0 || current.conversations[index].unreadCount == 0) return;
    final rows = [...current.conversations];
    rows[index] = rows[index].copyWith(unreadCount: 0);
    state = AsyncData(current.copyWith(conversations: rows));
  }

  void _onChatUpdate(ChatUpdateEvent event) {
    final summary = event.summary;
    if (summary != null) applySummary(summary);
  }
}

final chatInboxProvider =
    AsyncNotifierProvider.autoDispose<ChatInboxNotifier, ChatInboxState>(
  ChatInboxNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────
// Thread
// ─────────────────────────────────────────────────────────────────────────

class ChatThreadState {
  final ChatConversationSummary conversation;

  /// Oldest → newest.
  final List<ChatMessage> messages;

  /// The draft in the panel: Pending, or Failed ("draft unavailable").
  final ChatDraft? draft;
  final ChatCustomerCard? customer;

  /// The server's strong "looks like customer X" hint for an unlinked chat.
  final ChatCustomerCandidate? customerSuggestion;
  final bool hasMoreOlder;
  final bool loadingOlder;

  const ChatThreadState({
    required this.conversation,
    this.messages = const <ChatMessage>[],
    this.draft,
    this.customer,
    this.customerSuggestion,
    this.hasMoreOlder = false,
    this.loadingOlder = false,
  });

  ChatThreadState copyWith({
    ChatConversationSummary? conversation,
    List<ChatMessage>? messages,
    ChatDraft? draft,
    bool clearDraft = false,
    ChatCustomerCard? customer,
    bool clearCustomer = false,
    ChatCustomerCandidate? customerSuggestion,
    bool clearSuggestion = false,
    bool? hasMoreOlder,
    bool? loadingOlder,
  }) {
    return ChatThreadState(
      // A summary without the media / reaction info (a socket event) keeps
      // what the thread already knew.
      conversation:
          conversation?.inheritMediaInfo(this.conversation) ?? this.conversation,
      messages: messages ?? this.messages,
      draft: clearDraft ? null : (draft ?? this.draft),
      customer: clearCustomer ? null : (customer ?? this.customer),
      customerSuggestion: clearSuggestion
          ? null
          : (customerSuggestion ?? this.customerSuggestion),
      hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
      loadingOlder: loadingOlder ?? this.loadingOlder,
    );
  }
}

/// Union of two message lists by `name` ([incoming] wins), oldest → newest.
/// Timestamps are `YYYY-MM-DD HH:MM:SS`, so string order is time order; the
/// sort is stable, so equal timestamps keep their arrival order.
///
/// A voice-note transcript only ever goes from null to text, so an incoming
/// copy without one (a page read that left before the transcript landed and
/// arrived after the socket update) keeps the transcript already held.
List<ChatMessage> mergeChatMessages(
  List<ChatMessage> existing,
  List<ChatMessage> incoming,
) {
  final byName = <String, ChatMessage>{};
  final order = <String>[];
  for (final message in [...existing, ...incoming]) {
    final key = message.name.isEmpty
        ? 'anon-${order.length}'
        : message.name;
    final previous = byName[key];
    if (previous == null) order.add(key);
    byName[key] = message.transcript == null && previous?.transcript != null
        ? message.withTranscript(previous!.transcript)
        : message;
  }
  final merged = [for (final key in order) byName[key]!];
  final indexed = merged.asMap().entries.toList()
    ..sort((a, b) {
      final at = a.value.timestamp ?? '￿';
      final bt = b.value.timestamp ?? '￿';
      final byTime = at.compareTo(bt);
      return byTime != 0 ? byTime : a.key.compareTo(b.key);
    });
  return [for (final entry in indexed) entry.value];
}

/// Whether [draft] belongs in the draft panel.
bool chatDraftIsShowable(ChatDraft? draft) =>
    draft != null && (draft.isPending || draft.isFailed);

/// Whether the newest message in the thread is ours (outbound: sent from the
/// app or echoed from the phone). Falls back to the summary's
/// `last_direction` when no message is loaded.
bool chatNewestIsOurs(ChatThreadState state) {
  if (state.messages.isNotEmpty) return state.messages.last.isOutbound;
  return state.conversation.lastDirection == 'Outbound';
}

/// What sits between the message list and the composer.
enum ChatAiSlot {
  /// Nothing: the customer spoke last and no draft is showable (the server
  /// drafts on its own; unchanged behaviour).
  none,

  /// The draft panel for [ChatThreadState.draft] (Pending or Failed).
  draft,

  /// We spoke last: offer "Ask AI for a message" (an instruction is required).
  askForMessage,

  /// We spoke last and the 24-hour reply window is closed: a short note
  /// instead of the ask action, since a free-form message cannot be sent.
  windowClosed,
}

/// Which AI affordance the thread shows. A showable draft always wins, so the
/// customer-spoke-last flow is untouched.
ChatAiSlot chatAiSlot(ChatThreadState state) {
  if (chatDraftIsShowable(state.draft)) return ChatAiSlot.draft;
  if (!chatNewestIsOurs(state)) return ChatAiSlot.none;
  return state.conversation.windowOpen
      ? ChatAiSlot.askForMessage
      : ChatAiSlot.windowClosed;
}

class ChatThreadNotifier
    extends AutoDisposeFamilyAsyncNotifier<ChatThreadState, String> {
  static const pageSize = 50;

  /// How often an open thread re-reads its newest page (realtime events do
  /// not always arrive), and the wait after a failed refresh.
  static const pollInterval = Duration(seconds: 5);
  static const pollErrorBackoff = Duration(seconds: 15);

  /// The debounced re-read after an inbound socket message. The poll skips a
  /// tick while it is pending, so the two never fire back to back.
  Timer? _silentRefresh;

  Timer? _poll;
  int _pollGeneration = 0;
  int _refreshesInFlight = 0;
  bool _lastRefreshFailed = false;

  /// Writes in flight (send, reject, regenerate, assign, status, link) and a
  /// counter bumped at the start and end of each. A refresh that overlapped a
  /// write may carry the draft and header from before it, so it only merges
  /// its messages.
  int _mutationsInFlight = 0;
  int _mutationSeq = 0;

  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  @override
  Future<ChatThreadState> build(String arg) async {
    final sub = listenChatUpdates(ref, _onChatUpdate);
    _poll?.cancel();
    final generation = ++_pollGeneration;
    ref.onDispose(() {
      sub?.cancel();
      _silentRefresh?.cancel();
      _poll?.cancel();
      _poll = null;
      _pollGeneration++;
    });
    final thread = await _repo.fetchConversation(arg, limit: pageSize);
    _afterServerRead(thread.conversation);
    _schedulePoll(generation, pollInterval);
    return ChatThreadState(
      conversation: thread.conversation,
      messages: thread.messages,
      draft: thread.draft,
      customer: thread.customer,
      customerSuggestion: thread.customerSuggestion,
      hasMoreOlder: thread.messages.length >= pageSize,
    );
  }

  void _schedulePoll(int generation, Duration delay) {
    if (generation != _pollGeneration) return;
    _poll?.cancel();
    _poll = Timer(delay, () => unawaited(_pollTick(generation)));
  }

  /// Whether a poll tick should stand aside: a refresh or a write is already
  /// running, the socket debounce is about to refresh, older messages are
  /// loading, or there is no thread on screen yet.
  bool get _pollBusy =>
      _refreshesInFlight > 0 ||
      _mutationsInFlight > 0 ||
      (_silentRefresh?.isActive ?? false) ||
      !state.hasValue ||
      (state.valueOrNull?.loadingOlder ?? false);

  Future<void> _pollTick(int generation) async {
    if (generation != _pollGeneration) return;
    if (!_pollBusy && chatAppInForeground()) {
      await _refresh(silent: true);
    }
    _schedulePoll(
      generation,
      _lastRefreshFailed ? pollErrorBackoff : pollInterval,
    );
  }

  Future<T> _mutate<T>(Future<T> Function() body) async {
    _mutationsInFlight++;
    _mutationSeq++;
    try {
      return await body();
    } finally {
      _mutationsInFlight--;
      _mutationSeq++;
    }
  }

  /// `get_conversation` reset the unread count; reflect that in the inbox
  /// row and, when [badge] is set, the drawer badge.
  void _afterServerRead(
    ChatConversationSummary conversation, {
    bool badge = true,
  }) {
    if (ref.exists(chatInboxProvider)) {
      final inbox = ref.read(chatInboxProvider.notifier);
      inbox.applySummary(conversation.copyWith(unreadCount: 0));
      inbox.markRead(conversation.name);
    }
    if (badge && ref.exists(chatUnreadTotalProvider)) {
      ref.invalidate(chatUnreadTotalProvider);
    }
  }

  void _publishSummary(ChatConversationSummary summary) {
    if (summary.name.isEmpty) return;
    if (ref.exists(chatInboxProvider)) {
      ref.read(chatInboxProvider.notifier).applySummary(summary);
    }
  }

  /// Re-read the newest page and merge it, keeping older pages already
  /// loaded. Errors are swallowed unless [silent] is false.
  Future<void> refresh({bool silent = true}) => _refresh(silent: silent);

  Future<void> _refresh({required bool silent}) async {
    final mutationSeq = _mutationSeq;
    _refreshesInFlight++;
    try {
      final thread = await _repo.fetchConversation(arg, limit: pageSize);
      final current = state.valueOrNull;
      if (current == null) {
        state = AsyncData(
          ChatThreadState(
            conversation: thread.conversation,
            messages: thread.messages,
            draft: thread.draft,
            customer: thread.customer,
            customerSuggestion: thread.customerSuggestion,
            hasMoreOlder: thread.messages.length >= pageSize,
          ),
        );
        _afterServerRead(thread.conversation);
      } else {
        final messages = mergeChatMessages(current.messages, thread.messages);
        final grew = messages.length != current.messages.length;
        if (mutationSeq != _mutationSeq || _mutationsInFlight > 0) {
          // A write overlapped this read: its draft and header may predate
          // the write, so keep what the write set and take only messages.
          state = AsyncData(current.copyWith(messages: messages));
          _afterServerRead(current.conversation, badge: grew);
        } else {
          // `get_conversation` only returns a Pending draft; keep a Failed
          // one the socket delivered, so "draft unavailable" does not vanish.
          final keepFailed =
              thread.draft == null && (current.draft?.isFailed ?? false);
          state = AsyncData(
            current.copyWith(
              conversation: thread.conversation,
              messages: messages,
              draft: thread.draft,
              clearDraft: thread.draft == null && !keepFailed,
              customer: thread.customer,
              clearCustomer: thread.customer == null,
              customerSuggestion: thread.customerSuggestion,
              clearSuggestion: thread.customerSuggestion == null,
            ),
          );
          _afterServerRead(
            thread.conversation,
            badge: grew ||
                current.conversation.unreadCount > 0 ||
                thread.conversation.unreadCount > 0,
          );
        }
      }
      _lastRefreshFailed = false;
    } catch (e, st) {
      _lastRefreshFailed = true;
      if (!silent) {
        state = AsyncError<ChatThreadState>(e, st).copyWithPrevious(state);
      }
    } finally {
      _refreshesInFlight--;
    }
  }

  Future<void> loadOlder() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMoreOlder || current.loadingOlder) {
      return;
    }
    if (current.messages.isEmpty) return;
    state = AsyncData(current.copyWith(loadingOlder: true));
    try {
      final page = await _repo.fetchConversation(
        arg,
        limit: pageSize,
        before: current.messages.first.timestamp,
      );
      final latest = state.valueOrNull ?? current;
      state = AsyncData(latest.copyWith(
        messages: mergeChatMessages(page.messages, latest.messages),
        hasMoreOlder: page.messages.length >= pageSize,
        loadingOlder: false,
      ));
    } catch (_) {
      final latest = state.valueOrNull ?? current;
      state = AsyncData(latest.copyWith(loadingOlder: false));
      rethrow;
    }
  }

  void _update(ChatThreadState Function(ChatThreadState s) change) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(change(current));
  }

  void _appendMessage(ChatMessage? message) {
    if (message == null || message.name.isEmpty) return;
    _update((s) => s.copyWith(messages: mergeChatMessages(s.messages, [message])));
  }

  /// `send_media`: uploads one file as a reply and adds the returned message
  /// to the thread like a typed reply.
  Future<ChatMessage> sendMedia({
    required String filename,
    required String mime,
    Uint8List? bytes,
    String? path,
    String caption = '',
    void Function(int sent, int total)? onProgress,
  }) async {
    final message = await _mutate(() async {
      final message = await _repo.sendMedia(
        conversation: arg,
        filename: filename,
        mime: mime,
        bytes: bytes,
        path: path,
        caption: caption,
        onProgress: onProgress,
      );
      _appendMessage(message);
      return message;
    });
    unawaited(refresh());
    return message;
  }

  /// `react_to_message`: shows [emoji] on the message at once (empty removes
  /// it) and puts the old value back when the server refuses.
  Future<void> reactToMessage(ChatMessage message, String emoji) async {
    final previous = message.staffReaction;
    void apply(String? value) => _update((s) => s.copyWith(
          messages: [
            for (final m in s.messages)
              m.name == message.name ? m.withStaffReaction(value) : m,
          ],
        ));
    apply(emoji);
    try {
      final updated = await _mutate(
        () => _repo.reactToMessage(message: message.name, emoji: emoji),
      );
      if (updated != null) _appendMessage(updated);
    } catch (_) {
      apply(previous);
      rethrow;
    }
  }

  /// `delete_message`: the server's copy (deleted_at set) replaces the
  /// message. A refusal rethrows with nothing changed.
  Future<void> deleteMessage(ChatMessage message) async {
    final updated = await _mutate(
      () => _repo.deleteMessage(message: message.name),
    );
    _appendMessage(updated);
  }

  /// `edit_message`: the server's copy (edited_at set) replaces the message.
  Future<void> editMessage(ChatMessage message, String text) async {
    final updated = await _mutate(
      () => _repo.editMessage(message: message.name, text: text),
    );
    _appendMessage(updated);
  }

  /// `send_draft`. Returns the full result so the screen can show the
  /// planted-draft dialog.
  Future<ChatSendDraftResult> sendDraft({
    required String draft,
    required String finalText,
  }) async {
    final result = await _mutate(() async {
      final result =
          await _repo.sendDraft(draft: draft, finalText: finalText);
      _appendMessage(result.message);
      final next = result.nextDraft;
      _update((s) => chatDraftIsShowable(next)
          ? s.copyWith(draft: next)
          : s.copyWith(clearDraft: true));
      return result;
    });
    unawaited(refresh());
    return result;
  }

  Future<ChatRejectResult> rejectDraft({
    required String draft,
    required String reason,
  }) {
    return _mutate(() async {
      final result = await _repo.rejectDraft(draft: draft, reason: reason);
      final next = result.nextDraft;
      _update((s) => chatDraftIsShowable(next)
          ? s.copyWith(draft: next)
          : s.copyWith(clearDraft: true));
      return result;
    });
  }

  Future<ChatDraft?> regenerateDraft({String? hint}) {
    return _mutate(() async {
      final draft = await _repo.regenerateDraft(conversation: arg, hint: hint);
      _update((s) => draft != null
          ? s.copyWith(draft: draft)
          : s.copyWith(clearDraft: true));
      return draft;
    });
  }

  /// A reply typed from scratch; it supersedes any Pending draft.
  Future<ChatMessage> sendMessage(String text) async {
    final message = await _mutate(() async {
      final message = await _repo.sendMessage(conversation: arg, text: text);
      _appendMessage(message);
      _update((s) => s.copyWith(clearDraft: true));
      return message;
    });
    unawaited(refresh());
    return message;
  }

  Future<void> assignToMe() {
    return _mutate(() async {
      final summary = await _repo.assignConversation(conversation: arg);
      _update((s) => s.copyWith(conversation: summary));
      _publishSummary(summary);
    });
  }

  Future<void> setStatus(String status) async {
    await _mutate(() async {
      final summary =
          await _repo.setConversationStatus(conversation: arg, status: status);
      _update((s) => s.copyWith(conversation: summary));
      _publishSummary(summary);
    });
    if (ref.exists(chatUnreadTotalProvider)) {
      ref.invalidate(chatUnreadTotalProvider);
    }
  }

  Future<ChatLinkResult> linkCustomer(String customer) {
    return _mutate(() async {
      final result = await _repo.linkCustomer(
        conversation: arg,
        customer: customer,
      );
      _update(
        (s) => s.copyWith(
          conversation: result.conversation,
          customer: result.customer,
          clearSuggestion: true,
        ),
      );
      _publishSummary(result.conversation);
      return result;
    });
  }

  /// `unlink_customer`: the chat goes back to "not linked".
  Future<void> unlinkCustomer() {
    return _mutate(() async {
      final summary = await _repo.unlinkCustomer(arg);
      _update(
        (s) => s.copyWith(
          conversation: summary,
          clearCustomer: true,
          clearSuggestion: true,
        ),
      );
      _publishSummary(summary);
    });
  }

  /// `create_customer_from_chat`. A created customer is linked here; an
  /// `existing` answer changes nothing (the form offers "Link to them").
  Future<ChatCreateCustomerResult> createCustomerFromChat({
    required String customerName,
    required String mobileNo,
    required String address,
    required String territory,
    String? locationLink,
    double? latitude,
    double? longitude,
  }) {
    return _mutate(() async {
      final result = await _repo.createCustomerFromChat(
        conversation: arg,
        customerName: customerName,
        mobileNo: mobileNo,
        address: address,
        territory: territory,
        locationLink: locationLink,
        latitude: latitude,
        longitude: longitude,
      );
      final summary = result.conversation;
      if (result.existing == null && summary != null) {
        _update(
          (s) => s.copyWith(
            conversation: summary,
            customer: result.customer,
            clearSuggestion: true,
          ),
        );
        _publishSummary(summary);
      }
      return result;
    });
  }

  /// `set_contact_category`; an empty [category] hands the chat back to the AI.
  Future<void> setContactCategory(String category) {
    return _mutate(() async {
      final summary = await _repo.setContactCategory(
        conversation: arg,
        category: category,
      );
      _update((s) => s.copyWith(conversation: summary));
      _publishSummary(summary);
    });
  }

  /// `approve_fact_conflict` for line [index] of the draft [draft]: marks the
  /// line approved on the draft held here, patches the overrides list when it
  /// is open, then re-reads the thread.
  Future<ChatFactApprovalResult> approveFactConflict({
    required String draft,
    required int index,
    required String topic,
    String factEn = '',
    String factAr = '',
    String category = ChatFactCategories.other,
  }) async {
    final result = await _mutate(() async {
      final result = await _repo.approveFactConflict(
        draft: draft,
        index: index,
        topic: topic,
        factEn: factEn,
        factAr: factAr,
        category: category,
      );
      _update((s) {
        final held = s.draft;
        if (held == null || held.name != draft) return s;
        return s.copyWith(
          draft: held.withApprovedConflicts(
            chatApprovedAfter(held.approvedConflicts, result, index),
          ),
        );
      });
      if (ref.exists(chatFactOverridesProvider)) {
        ref
            .read(chatFactOverridesProvider.notifier)
            .markApproved(draft, index, result);
      }
      return result;
    });
    unawaited(refresh());
    return result;
  }

  /// What "Start order" hands to the POS; [withOrder] also has the server
  /// read the order out of the chat (slow: a model call).
  Future<ChatOrderPrefill> orderPrefill({bool withOrder = false}) =>
      _repo.fetchOrderPrefill(arg, withOrder: withOrder);

  void _onChatUpdate(ChatUpdateEvent event) {
    if (event.conversation != arg) return;
    final current = state.valueOrNull;
    if (current == null) return;
    var next = current;
    final summary = event.summary;
    if (summary != null) next = next.copyWith(conversation: summary);
    final message = event.message;
    // An update of a message we already show (delivery tick, reaction) is
    // not a new arrival: no unread re-read.
    final alreadyHeld =
        message != null && current.messages.any((m) => m.name == message.name);
    if (message != null && message.name.isNotEmpty) {
      // Upsert by name: a status / reaction update of a message already in
      // the thread replaces it in place (no duplicate row).
      next = next.copyWith(
        messages: mergeChatMessages(next.messages, [message]),
      );
    }
    final draft = event.draft;
    if (draft != null) {
      if (chatDraftIsShowable(draft)) {
        next = next.copyWith(draft: draft);
      } else if (next.draft?.name == draft.name) {
        next = next.copyWith(clearDraft: true);
      }
    } else if (summary != null &&
        !summary.hasPendingDraft &&
        (next.draft?.isPending ?? false) &&
        message != null &&
        message.isOutbound) {
      // An outbound (app or phone echo) superseded the Pending draft.
      next = next.copyWith(clearDraft: true);
    }
    state = AsyncData(next);

    if (message != null && message.isInbound && !alreadyHeld) {
      // The server counts this as unread until the thread is read again;
      // re-read it shortly (debounced across a burst) while it is on screen.
      _silentRefresh?.cancel();
      _silentRefresh = Timer(const Duration(seconds: 2), () {
        unawaited(refresh());
      });
    }
  }
}

final chatThreadProvider = AsyncNotifierProvider.autoDispose
    .family<ChatThreadNotifier, ChatThreadState, String>(
  ChatThreadNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────
// Badge, media, metrics
// ─────────────────────────────────────────────────────────────────────────

/// `get_unread_total` for the drawer badge. Zero for users without a chat
/// role (no call is made) and on any error: a badge must never break the
/// drawer. Re-reads itself, debounced, on every `jarz_chat_update`.
final chatUnreadTotalProvider =
    FutureProvider.autoDispose<ChatUnreadTotal>((ref) async {
  if (!ref.watch(canAccessChatsProvider)) return ChatUnreadTotal.zero;
  Timer? debounce;
  final sub = listenChatUpdates(ref, (_) {
    debounce?.cancel();
    debounce = Timer(const Duration(seconds: 2), ref.invalidateSelf);
  });
  ref.onDispose(() {
    debounce?.cancel();
    sub?.cancel();
  });
  try {
    return await ref.read(chatRepositoryProvider).fetchUnreadTotal();
  } catch (_) {
    return ChatUnreadTotal.zero;
  }
});

/// Bytes of a message image, fetched with the session. Kept five minutes
/// after the last viewer scrolls away, like task attachment thumbnails.
final chatMediaBytesProvider =
    FutureProvider.autoDispose.family<Uint8List, String>((ref, url) async {
  final bytes = await ref.watch(chatRepositoryProvider).fetchMediaBytes(url);
  final link = ref.keepAlive();
  Timer? release;
  ref.onCancel(() => release = Timer(const Duration(minutes: 5), link.close));
  ref.onResume(() => release?.cancel());
  ref.onDispose(() => release?.cancel());
  return bytes;
});

/// `get_chat_metrics` for an inclusive `YYYY-MM-DD` range.
final chatMetricsProvider = FutureProvider.autoDispose
    .family<ChatMetrics, ({String from, String to})>((ref, range) {
  return ref
      .read(chatRepositoryProvider)
      .fetchMetrics(fromDate: range.from, toDate: range.to);
});

/// Called by the push bridge on a `chat_waiting` push: refresh whatever chat
/// state is already alive, and nothing that is not.
void refreshChatsAfterPush(Ref ref, {String? conversation}) {
  ref.invalidate(chatUnreadTotalProvider);
  if (ref.exists(chatInboxProvider)) {
    final inbox = ref.read(chatInboxProvider.notifier);
    // Merge in place when a list is showing; reload an errored one.
    unawaited(ref.read(chatInboxProvider).hasValue
        ? inbox.silentRefresh()
        : inbox.refresh());
  }
  final name = conversation?.trim() ?? '';
  if (name.isNotEmpty && ref.exists(chatThreadProvider(name))) {
    unawaited(ref.read(chatThreadProvider(name).notifier).refresh());
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Customer link banner, moderator overrides
// ─────────────────────────────────────────────────────────────────────────

/// Conversations whose "Looks like X" suggestion the moderator dismissed with
/// "Not them". Lives for the app session (not persisted).
final chatDismissedSuggestionsProvider = StateProvider<Set<String>>(
  (ref) => const <String>{},
);

/// The moderator-overrides screen: a date range, newest-first rows, and
/// pagination by `start` / `limit`.
class ChatFactOverridesState {
  final DateTime from;
  final DateTime to;
  final List<ChatFactOverrideRow> rows;
  final bool hasMore;
  final int total;
  final bool loadingMore;

  /// Whether the caller may add a conflict line to the approved facts.
  final bool canApproveFacts;

  const ChatFactOverridesState({
    required this.from,
    required this.to,
    this.rows = const <ChatFactOverrideRow>[],
    this.hasMore = false,
    this.total = 0,
    this.loadingMore = false,
    this.canApproveFacts = false,
  });

  ChatFactOverridesState copyWith({
    DateTime? from,
    DateTime? to,
    List<ChatFactOverrideRow>? rows,
    bool? hasMore,
    int? total,
    bool? loadingMore,
    bool? canApproveFacts,
  }) {
    return ChatFactOverridesState(
      from: from ?? this.from,
      to: to ?? this.to,
      rows: rows ?? this.rows,
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
      loadingMore: loadingMore ?? this.loadingMore,
      canApproveFacts: canApproveFacts ?? this.canApproveFacts,
    );
  }
}

/// The approved conflict indexes after an `approve_fact_conflict` call for
/// line [index]: the server's list, or, should it leave the line out (an
/// older answer), what was held plus [index].
List<int> chatApprovedAfter(
  List<int> before,
  ChatFactApprovalResult result,
  int index,
) {
  if (result.approvedConflicts.contains(index)) return result.approvedConflicts;
  return ({...before, ...result.approvedConflicts, index}.toList()..sort());
}

String chatIsoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class ChatFactOverridesNotifier
    extends AutoDisposeAsyncNotifier<ChatFactOverridesState> {
  static const pageSize = 50;
  static const defaultDays = 30;

  late DateTime _from;
  late DateTime _to;
  int _seq = 0;

  @override
  Future<ChatFactOverridesState> build() async {
    final now = ref.read(chatClockProvider)();
    _to = DateTime(now.year, now.month, now.day);
    _from = _to.subtract(const Duration(days: defaultDays));
    return _load();
  }

  Future<ChatFactOverridesState> _load() async {
    final page = await ref
        .read(chatRepositoryProvider)
        .fetchFactOverrides(
          fromDate: chatIsoDate(_from),
          toDate: chatIsoDate(_to),
          limit: pageSize,
        );
    return ChatFactOverridesState(
      from: _from,
      to: _to,
      rows: page.rows,
      hasMore: page.hasMore,
      total: page.total,
      canApproveFacts: page.canApproveFacts,
    );
  }

  Future<void> refresh() async {
    final seq = ++_seq;
    state = const AsyncLoading<ChatFactOverridesState>().copyWithPrevious(
      state,
    );
    final next = await AsyncValue.guard(_load);
    if (seq != _seq) return;
    state = next;
  }

  Future<void> setRange(DateTime from, DateTime to) {
    _from = DateTime(from.year, from.month, from.day);
    _to = DateTime(to.year, to.month, to.day);
    return refresh();
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;
    final seq = _seq;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await ref
          .read(chatRepositoryProvider)
          .fetchFactOverrides(
            fromDate: chatIsoDate(current.from),
            toDate: chatIsoDate(current.to),
            limit: pageSize,
            start: current.rows.length,
          );
      if (seq != _seq) return;
      final latest = state.valueOrNull ?? current;
      state = AsyncData(
        latest.copyWith(
          rows: [...latest.rows, ...page.rows],
          hasMore: page.hasMore,
          total: page.total,
          loadingMore: false,
          canApproveFacts: page.canApproveFacts || latest.canApproveFacts,
        ),
      );
    } catch (_) {
      if (seq != _seq) return;
      final latest = state.valueOrNull ?? current;
      state = AsyncData(latest.copyWith(loadingMore: false));
      rethrow;
    }
  }

  /// `approve_fact_conflict` for line [index] of the row for [draft]; the row
  /// shows the line as approved at once. Errors rethrow with nothing changed.
  Future<ChatFactApprovalResult> approveConflict({
    required String draft,
    required int index,
    required String topic,
    String factEn = '',
    String factAr = '',
    String category = ChatFactCategories.other,
  }) async {
    final result = await ref.read(chatRepositoryProvider).approveFactConflict(
      draft: draft,
      index: index,
      topic: topic,
      factEn: factEn,
      factAr: factAr,
      category: category,
    );
    markApproved(draft, index, result);
    // An open thread on the same draft re-reads, so its alert shows the tick.
    for (final row in state.valueOrNull?.rows ?? const <ChatFactOverrideRow>[]) {
      if (row.draft != draft || row.conversation.isEmpty) continue;
      if (ref.exists(chatThreadProvider(row.conversation))) {
        unawaited(
          ref.read(chatThreadProvider(row.conversation).notifier).refresh(),
        );
      }
      break;
    }
    return result;
  }

  /// Marks line [index] of the row for [draft] as approved (also used by the
  /// thread after an approval made there).
  void markApproved(String draft, int index, ChatFactApprovalResult result) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.rows.any((row) => row.draft == draft)) return;
    final rows = [
      for (final row in current.rows)
        row.draft == draft
            ? row.withApprovedConflicts(
                chatApprovedAfter(row.approvedConflicts, result, index),
              )
            : row,
    ];
    state = AsyncData(current.copyWith(rows: rows));
  }
}

final chatFactOverridesProvider =
    AsyncNotifierProvider.autoDispose<
      ChatFactOverridesNotifier,
      ChatFactOverridesState
    >(ChatFactOverridesNotifier.new);
