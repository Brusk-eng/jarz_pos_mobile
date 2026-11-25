import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/person_text.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/push/studio_push_router.dart';
import '../../../core/router/studio_screen.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../../shared/how_this_works_sheet.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../inbox/presentation/inbox_hub.dart';
import '../../inbox/presentation/inbox_strings.dart';
import '../../inbox/presentation/ui_helpers.dart';
import '../data/notifications_repository.dart';
import 'notifications_strings.dart';
import '../../../shared/studio_error_text.dart';

IconData _iconFor(String event) {
  if (event.contains('version') || event.contains('sent_back')) {
    return Icons.verified_outlined;
  }
  if (event.contains('decision')) return Icons.help_outline;
  if (event.contains('post') || event.contains('read')) {
    return Icons.event_available_outlined;
  }
  if (event.contains('shoot')) return Icons.videocam_outlined;
  if (event.contains('paid')) return Icons.payments_outlined;
  if (event.contains('failed')) return Icons.error_outline;
  return Icons.notifications_none;
}

/// The in-app list. Each row opens its `route` and marks itself read.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = NotificationsStrings.of(context);
    final s = InboxStrings.of(context);
    final copy = t.listCopy;
    final value = ref.watch(notificationsProvider);
    final unread = value.valueOrNull?.items.where((n) => !n.read).length ?? 0;

    Future<void> markAll() async {
      try {
        await ref.read(notificationsProvider.notifier).markAllRead();
      } catch (e) {
        if (context.mounted) showStudioError(context, e);
      }
    }

    return ViewEditScaffold(
      title: copy.title,
      parentRoute: StudioRoutes.inboxApprove,
      showLanguageSwitch: true,
      actions: [
        if (unread > 0)
          IconButton(
            key: const ValueKey('mark-all-read'),
            tooltip: t.markAllRead,
            icon: const Icon(Icons.done_all),
            onPressed: markAll,
          ),
        IconButton(
          key: const ValueKey('notification-settings'),
          tooltip: t.settings,
          icon: const Icon(Icons.tune),
          onPressed: () => context.push(InboxPaths.notificationSettings),
        ),
        IconButton(
          key: const ValueKey('help'),
          tooltip: StudioStrings.of(context).howThisWorks,
          icon: const Icon(Icons.help_outline),
          onPressed: () => HowThisWorksSheet.show(
            context,
            title: copy.title,
            lines: copy.help,
          ),
        ),
      ],
      body: StudioAsyncView<PagedState<NotificationItem>>(
        value: value,
        onRetry: () => ref.invalidate(notificationsProvider),
        isEmpty: (d) => d.items.isEmpty,
        empty: StudioEmptyConfig(
          purpose: copy.purpose,
          firstStep: copy.firstStep,
          icon: Icons.notifications_none,
        ),
        builder: (context, d) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(notificationsProvider.notifier).refresh();
          },
          child: ListView(
            key: const ValueKey('notifications-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(StudioSpacing.gutter),
            children: [
              NextStepLine(unread == 0 ? t.allRead : t.nextList),
              const SizedBox(height: StudioSpacing.md),
              for (final n in d.items) _NotificationRow(item: n),
              if (d.hasMore)
                Center(
                  child: TextButton(
                    onPressed: () =>
                        ref.read(notificationsProvider.notifier).loadMore(),
                    child: Text(s.loadMore),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.item});
  final NotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = InboxStrings.of(context);
    final theme = Theme.of(context);
    final unread = !item.read;
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
      child: Card(
        key: ValueKey('notification-${item.id}'),
        color: unread ? StudioColors.blushPale : Colors.white,
        child: InkWell(
          onTap: () {
            final router = GoRouter.maybeOf(context);
            final location = studioPushLocation({
              'type': item.event,
              'route': item.route,
              'doctype': item.doctype ?? '',
              'docname': item.docname ?? '',
            });
            if (unread) {
              ref
                  .read(notificationsProvider.notifier)
                  .markRead(item.id)
                  .catchError((_) {});
            }
            router?.push(location);
          },
          child: Padding(
            padding: const EdgeInsets.all(StudioSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconFor(item.event), color: StudioColors.deepPlum),
                const SizedBox(width: StudioSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PersonText(
                        item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (item.body != null && item.body!.isNotEmpty)
                        Text(item.body!, style: theme.textTheme.bodySmall),
                      const SizedBox(height: StudioSpacing.xs),
                      Text(
                        slotText(s, item.created),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    key: const ValueKey('unread-dot'),
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                      color: StudioColors.berryPink,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
