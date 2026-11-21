import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../../../core/network/user_service.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/chat_models.dart';
import '../../state/chat_providers.dart';
import '../chat_labels.dart';
import '../widgets/chat_conversation_tile.dart';
import 'chat_flavour_availability_screen.dart';

/// `/chats` — the moderator's inbox: Open / Mine / All / Closed, channel
/// chips, search, and rows that update live from `jarz_chat_update`.
/// Gated by `UserRoles.canAccessChats`; the server enforces the same roles.
class ChatInboxScreen extends ConsumerStatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  ConsumerState<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends ConsumerState<ChatInboxScreen> {
  final _search = TextEditingController();
  Timer? _searchDebounce;

  /// Moves every row's "waiting N min" label forward.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  ChatInboxNotifier get _notifier => ref.read(chatInboxProvider.notifier);

  void _setFilter(ChatInboxFilter filter) {
    unawaited(_notifier.setFilter(filter));
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _setFilter(_notifier.filter.copyWith(search: value.trim()));
    });
  }

  Future<void> _loadMore() async {
    try {
      await _notifier.loadMore();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.userErrorMessage(e, fallback: context.l10n.chatInboxLoadError),
          ),
        ),
      );
    }
  }

  void _open(ChatConversationSummary summary) {
    _notifier.markRead(summary.name);
    context.push(AppRoutes.chatThreadFor(summary.name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final roles = ref.watch(userRolesFutureProvider);
    final canAccess = ref.watch(canAccessChatsProvider);
    final canViewMetrics = ref.watch(canViewChatMetricsProvider);

    // Roles still loading: wait. Loaded and not a chat role: say so without
    // calling the API. A roles error falls through (the server decides).
    final Widget body;
    if (roles.isLoading && !roles.hasValue) {
      body = const Center(child: CircularProgressIndicator());
    } else if (roles.hasValue && !canAccess) {
      body = _Message(icon: Icons.lock_outline, text: l10n.chatNotAllowed);
    } else {
      body = _InboxBody(
        search: _search,
        onSearchChanged: _onSearchChanged,
        onFilter: _setFilter,
        onLoadMore: _loadMore,
        onOpen: _open,
        now: ref.read(chatClockProvider)(),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(l10n.chatInboxTitle),
        actions: [
          if (canViewMetrics)
            IconButton(
              key: const ValueKey('chat-metrics-action'),
              tooltip: l10n.chatMetricsTitle,
              icon: const Icon(Icons.insights_outlined),
              onPressed: () => context.push(AppRoutes.chatsMetrics),
            ),
          if (canAccess)
            IconButton(
              key: const ValueKey('chat-fact-overrides-action'),
              tooltip: chatBi(
                context,
                'Moderator overrides',
                'تعديلات المشرف على المعلومات',
              ),
              icon: const Icon(Icons.fact_check_outlined),
              onPressed: () => context.push(AppRoutes.chatsFactOverrides),
            ),
          // A plain Navigator route (no GoRouter entry in core/), so this
          // ships as a Dart-only Shorebird patch.
          if (canAccess)
            IconButton(
              key: const ValueKey('chat-flavours-action'),
              tooltip: chatBi(
                context,
                'Flavour availability',
                'النكهات المتاحة',
              ),
              icon: const Icon(Icons.inventory_2_outlined),
              onPressed: () => Navigator.of(
                context,
              ).push(ChatFlavourAvailabilityScreen.route()),
            ),
          if (canAccess)
            IconButton(
              tooltip: l10n.commonRetry,
              icon: const Icon(Icons.refresh),
              onPressed: () => unawaited(_notifier.refresh()),
            ),
        ],
      ),
      body: body,
    );
  }
}

class _InboxBody extends ConsumerWidget {
  const _InboxBody({
    required this.search,
    required this.onSearchChanged,
    required this.onFilter,
    required this.onLoadMore,
    required this.onOpen,
    required this.now,
  });

  final TextEditingController search;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ChatInboxFilter> onFilter;
  final Future<void> Function() onLoadMore;
  final ValueChanged<ChatConversationSummary> onOpen;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final inbox = ref.watch(chatInboxProvider);
    final filter = ref.watch(chatInboxProvider.notifier).filter;
    final unread = ref.watch(chatUnreadTotalProvider).valueOrNull;
    final openCount = unread?.openCount ?? inbox.valueOrNull?.openCount ?? 0;

    String segmentLabel(ChatInboxSegment segment) {
      final label = chatSegmentLabel(l10n, segment);
      if (segment == ChatInboxSegment.open && openCount > 0) {
        return '$label (${formatCount(context, openCount)})';
      }
      return label;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<ChatInboxSegment>(
              key: const ValueKey('chat-segments'),
              showSelectedIcon: false,
              segments: [
                for (final segment in ChatInboxSegment.values)
                  ButtonSegment(
                    value: segment,
                    label: Text(
                      segmentLabel(segment),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              selected: {filter.segment},
              onSelectionChanged: (selected) =>
                  onFilter(filter.copyWith(segment: selected.first)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            key: const ValueKey('chat-search'),
            controller: search,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.chatSearchHint,
              border: const OutlineInputBorder(),
              suffixIcon: search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.commonClear,
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        search.clear();
                        onFilter(filter.copyWith(search: ''));
                      },
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: ChoiceChip(
                  label: Text(l10n.chatChannelAll),
                  selected: filter.channel == null,
                  onSelected: (_) =>
                      onFilter(filter.copyWith(clearChannel: true)),
                ),
              ),
              for (final channel in ChatChannels.all)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: ChoiceChip(
                    key: ValueKey('chat-channel-$channel'),
                    avatar: Icon(chatChannelIcon(channel), size: 16),
                    label: Text(chatChannelLabel(l10n, channel)),
                    selected: filter.channel == channel,
                    onSelected: (selected) => onFilter(
                      selected
                          ? filter.copyWith(channel: channel)
                          : filter.copyWith(clearChannel: true),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            key: const ValueKey('chat-category-filters'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final category in <String?>[
                null,
                ChatContactCategories.customer,
                ChatContactCategories.supplier,
                ChatContactCategories.contentCreator,
                ChatContactCategories.other,
              ])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: ChoiceChip(
                    key: ValueKey('chat-filter-category-${category ?? 'all'}'),
                    label: Text(
                      _categoryChipLabel(
                        context,
                        category,
                        inbox.valueOrNull?.categoryCounts ??
                            const <String, int>{},
                      ),
                    ),
                    selected: filter.category == category,
                    onSelected: (_) => onFilter(
                      category == null
                          ? filter.copyWith(clearCategory: true)
                          : filter.copyWith(category: category),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (inbox.isLoading && inbox.hasValue)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: inbox.when(
            skipLoadingOnReload: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _Message(
              icon: Icons.cloud_off,
              text: context.userErrorMessage(e, fallback: l10n.chatInboxLoadError),
              onRetry: () => ref.read(chatInboxProvider.notifier).refresh(),
            ),
            data: (data) {
              final rows = data.conversations;
              return RefreshIndicator(
                onRefresh: () => ref.read(chatInboxProvider.notifier).refresh(),
                child: rows.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          _Message(
                            icon: Icons.forum_outlined,
                            text: data.filter.hasSearch
                                ? l10n.chatInboxEmptySearch
                                : l10n.chatInboxEmpty,
                          ),
                        ],
                      )
                    : ListView.separated(
                        key: const ValueKey('chat-inbox-list'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: rows.length + (data.hasMore ? 1 : 0),
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index >= rows.length) {
                            return Padding(
                              padding: const EdgeInsets.all(12),
                              child: Center(
                                child: data.loadingMore
                                    ? const CircularProgressIndicator()
                                    : OutlinedButton(
                                        key: const ValueKey('chat-load-more'),
                                        onPressed: onLoadMore,
                                        child: Text(l10n.chatLoadMore),
                                      ),
                              ),
                            );
                          }
                          final summary = rows[index];
                          return ChatConversationTile(
                            summary: summary,
                            now: now,
                            onTap: () => onOpen(summary),
                          );
                        },
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// "Suppliers (3)": the count comes from `category_counts` and is shown for
/// Supplier and Content Creator only.
String _categoryChipLabel(
  BuildContext context,
  String? category,
  Map<String, int> counts,
) {
  final label = chatCategoryFilterLabel(context, category);
  final count = category == null ? null : counts[category];
  final counted =
      category == ChatContactCategories.supplier ||
      category == ChatContactCategories.contentCreator;
  if (!counted || count == null || count <= 0) return label;
  return '$label (${formatCount(context, count)})';
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).disabledColor),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(context.l10n.commonRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
