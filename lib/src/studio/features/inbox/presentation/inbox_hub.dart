import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/studio_screen.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../review/data/review_repository.dart';
import '../state/inbox_state.dart';
import 'inbox_strings.dart';

/// Where the Notifications and Rate sections live (see `inboxRoutes()`).
class InboxPaths {
  InboxPaths._();
  static const rate = '/inbox/rate';
  static const notifications = '/inbox/notifications';
  static const notificationSettings = '/inbox/notifications/settings';
  static String decision(String id) => '/inbox/decisions/$id';
  static String approve(String versionId) => '/inbox/approve/$versionId';
}

/// The Inbox hub: one tile per kind of work the person has, with its count.
class InboxHub extends ConsumerWidget {
  const InboxHub({super.key, required this.current});

  /// The section whose list is open below (highlighted), if any.
  final InboxSection? current;

  static String pathOf(InboxSection s) => switch (s) {
    InboxSection.approve => StudioRoutes.inboxApprove,
    InboxSection.rate => InboxPaths.rate,
    InboxSection.decisions => StudioRoutes.inboxDecisions,
    InboxSection.ideas => StudioRoutes.inboxIdeas,
    InboxSection.notifications => InboxPaths.notifications,
  };

  /// Sections that open as a list under the hub; the rest push a screen.
  static bool isTab(InboxSection s) =>
      s == InboxSection.approve ||
      s == InboxSection.decisions ||
      s == InboxSection.ideas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = InboxStrings.of(context);
    final sections = ref.watch(inboxSectionsProvider);
    final counts = ref.watch(inboxCountsProvider).valueOrNull;
    final shown = [
      ...sections,
      if (current != null && !sections.contains(current)) current!,
    ];
    if (shown.isEmpty) return const SizedBox.shrink();

    String label(InboxSection x) => switch (x) {
      InboxSection.approve => s.hubToApprove,
      InboxSection.rate => s.hubToRate,
      InboxSection.decisions => s.hubDecisions,
      InboxSection.ideas => s.hubIdeas,
      InboxSection.notifications => s.hubNotifications,
    };
    IconData icon(InboxSection x) => switch (x) {
      InboxSection.approve => Icons.verified_outlined,
      InboxSection.rate => Icons.star_outline,
      InboxSection.decisions => Icons.help_outline,
      InboxSection.ideas => Icons.lightbulb_outline,
      InboxSection.notifications => Icons.notifications_none,
    };
    int? count(InboxSection x, InboxCounts? c) => c == null
        ? null
        : switch (x) {
            InboxSection.approve => c.toApprove,
            InboxSection.rate => c.toRate,
            InboxSection.decisions => c.decisions,
            InboxSection.ideas => c.ideas,
            InboxSection.notifications => c.unreadNotifications,
          };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StudioSpacing.gutter,
        StudioSpacing.md,
        StudioSpacing.gutter,
        StudioSpacing.sm,
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final perRow = box.maxWidth >= 560 ? shown.length : 3;
          const gap = StudioSpacing.sm;
          final w = ((box.maxWidth - gap * (perRow - 1)) / perRow)
              .floorToDouble();
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final x in shown)
                SizedBox(
                  width: w,
                  child: _Tile(
                    key: ValueKey('inbox-tab-${x.name}'),
                    label: label(x),
                    icon: icon(x),
                    count: count(x, counts),
                    selected: x == current,
                    onTap: () {
                      if (isTab(x)) {
                        context.go(pathOf(x));
                      } else {
                        context.push(pathOf(x));
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasWork = (count ?? 0) > 0;
    return Material(
      color: selected ? StudioColors.blushPale : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudioRadii.md),
        side: BorderSide(
          color: selected ? StudioColors.berryPink : StudioColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(StudioRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(StudioSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: StudioColors.deepPlum),
                  const Spacer(),
                  if (count != null)
                    Text(
                      '$count',
                      key: const ValueKey('tile-count'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: hasWork
                            ? StudioColors.berryPink
                            : StudioColors.plumMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: StudioSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
