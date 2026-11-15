import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../data/models/chat_models.dart';
import '../../state/chat_providers.dart';
import '../chat_bidi.dart';
import '../chat_labels.dart';

/// `/chats/fact-overrides` — the moments a moderator told the AI something
/// that is not in our approved facts: who asked, when, in which chat, what
/// they said, which facts it contradicted, and whether the reply went out.
/// Newest first; last 30 days by default; tap a row to open the chat.
class ChatFactOverridesScreen extends ConsumerWidget {
  const ChatFactOverridesScreen({super.key});

  Future<void> _pickRange(
    BuildContext context,
    WidgetRef ref,
    ChatFactOverridesState current,
  ) async {
    final now = ref.read(chatClockProvider)();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: DateTimeRange(start: current.from, end: current.to),
    );
    if (picked == null) return;
    unawaited(
      ref
          .read(chatFactOverridesProvider.notifier)
          .setRange(picked.start, picked.end),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(chatFactOverridesProvider);
    final data = async.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          chatBi(
            context,
            'Moderator overrides',
            'تعديلات المشرف على المعلومات',
          ),
        ),
        actions: [
          IconButton(
            key: const ValueKey('chat-overrides-range'),
            tooltip: chatBi(context, 'Date range', 'الفترة'),
            icon: const Icon(Icons.date_range_outlined),
            onPressed: data == null
                ? null
                : () => _pickRange(context, ref, data),
          ),
        ],
      ),
      body: Column(
        children: [
          if (data != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  '${chatIsoDate(data.from)} → ${chatIsoDate(data.to)}'
                  ' · ${formatCount(context, data.total)}',
                  key: const ValueKey('chat-overrides-range-label'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          if (async.isLoading && data != null)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: async.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        context.userErrorMessage(
                          e,
                          fallback: l10n.chatInboxLoadError,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref
                            .read(chatFactOverridesProvider.notifier)
                            .refresh(),
                        child: Text(l10n.commonRetry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (state) => RefreshIndicator(
                onRefresh: () =>
                    ref.read(chatFactOverridesProvider.notifier).refresh(),
                child: state.rows.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Text(
                              chatBi(
                                context,
                                'No overrides in this period.',
                                'مفيش تعديلات في الفترة دي.',
                              ),
                              key: const ValueKey('chat-overrides-empty'),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        key: const ValueKey('chat-overrides-list'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        itemCount: state.rows.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.rows.length) {
                            return Padding(
                              padding: const EdgeInsets.all(12),
                              child: Center(
                                child: state.loadingMore
                                    ? const CircularProgressIndicator()
                                    : OutlinedButton(
                                        key: const ValueKey(
                                          'chat-overrides-load-more',
                                        ),
                                        onPressed: () => ref
                                            .read(
                                              chatFactOverridesProvider
                                                  .notifier,
                                            )
                                            .loadMore(),
                                        child: Text(l10n.chatLoadMore),
                                      ),
                              ),
                            );
                          }
                          final row = state.rows[index];
                          return ChatFactOverrideCard(
                            row: row,
                            onOpen: row.conversation.isEmpty
                                ? null
                                : () => context.push(
                                    AppRoutes.chatThreadFor(row.conversation),
                                  ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One override: requester and time, the chat, the moderator's instruction,
/// each fact it contradicted, the draft's fate, and the text (collapsed).
class ChatFactOverrideCard extends StatelessWidget {
  const ChatFactOverrideCard({super.key, required this.row, this.onOpen});

  final ChatFactOverrideRow row;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = row.time;
    final when = time == null
        ? ''
        : formatDateTime(context, time, pattern: 'MMM d · h:mm a');
    final who = [
      if (row.requester.isNotEmpty) row.requester,
      if (when.isNotEmpty) when,
    ].join(' · ');
    final contact = [
      row.contactName ?? row.conversation,
      if (row.channel.isNotEmpty) row.channel,
    ].join(' · ');
    final statusColor = row.wasSent
        ? Colors.green.shade700
        : row.status == ChatDraftStatuses.rejected
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    final shown = row.shownText;

    return Card(
      key: ValueKey('chat-override-${row.draft}'),
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: ValueKey('chat-override-open-${row.draft}'),
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(who, style: theme.textTheme.labelLarge),
                      ),
                      Container(
                        key: ValueKey('chat-override-status-${row.draft}'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          chatDraftStatusLabel(context, row.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: double.infinity,
                    child: ChatBidiText(
                      contact,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  if (row.moderatorHint != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      chatBi(context, 'Instruction', 'التعليمات'),
                      style: theme.textTheme.labelSmall,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ChatBidiText(
                        row.moderatorHint!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (row.conflicts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      chatBi(
                        context,
                        'Differs from our facts',
                        'مختلف عن معلوماتنا',
                      ),
                      style: theme.textTheme.labelSmall,
                    ),
                    for (final conflict in row.conflicts)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '•  ',
                              style: TextStyle(
                                color: Colors.deepOrange.shade800,
                              ),
                            ),
                            Expanded(
                              child: SizedBox(
                                width: double.infinity,
                                child: ChatBidiText(
                                  conflict,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.deepOrange.shade800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (shown != null && shown.isNotEmpty)
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: ValueKey('chat-override-text-${row.draft}'),
                dense: true,
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                title: Text(
                  row.wasSent
                      ? chatBi(context, 'Sent text', 'النص المبعوت')
                      : chatBi(context, 'Draft text', 'نص المسودة'),
                  style: theme.textTheme.labelMedium,
                ),
                children: [
                  SizedBox(width: double.infinity, child: ChatBidiText(shown)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
