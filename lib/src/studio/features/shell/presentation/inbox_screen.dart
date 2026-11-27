import '../../../shared/layout/studio_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/router/studio_screen.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../decisions/presentation/decisions_list.dart';
import '../../ideas/presentation/ideas_list.dart';
import '../../inbox/presentation/inbox_hub.dart';
import '../../inbox/presentation/inbox_strings.dart';
import '../../inbox/presentation/to_approve_list.dart';
import '../../inbox/state/inbox_state.dart';
import '../../session/state/studio_session_notifier.dart';

/// Inbox: the hub of tiles (with counts) over the list of the open section.
/// Each section is its own route so it can be linked to
/// (`/inbox/decisions`); the tiles navigate between them.
class StudioInboxScreen extends ConsumerWidget {
  const StudioInboxScreen({super.key, required this.initialIndex});

  final int initialIndex;

  static const paths = [
    StudioRoutes.inboxApprove,
    StudioRoutes.inboxDecisions,
    StudioRoutes.inboxIdeas,
  ];
  static const screens = [
    StudioScreen.approve,
    StudioScreen.decisions,
    StudioScreen.ideas,
  ];
  static const _sections = [
    InboxSection.approve,
    InboxSection.decisions,
    InboxSection.ideas,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = StudioStrings.of(context);
    final s = InboxStrings.of(context);
    final current = _sections[initialIndex];
    final mine = ref.watch(inboxSectionsProvider);
    final role = ref.watch(studioSessionProvider).valueOrNull?.primaryRole;

    // A list that is not part of this person's work: land on their first one.
    if (role != null && !mine.contains(current)) {
      final first = mine.where(InboxHub.isTab).firstOrNull;
      if (first != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go(InboxHub.pathOf(first));
        });
      }
    }

    final body = switch (current) {
      InboxSection.approve => const ToApproveList(),
      InboxSection.decisions => const DecisionsList(),
      InboxSection.ideas => const IdeasList(),
      _ => Center(child: Text(s.notYourList)),
    };

    return ViewEditScaffold(
      title: t.tabInbox,
      rootTab: true,
      contentWidth: StudioContentWidth.full,
      screen: screens[initialIndex],
      showLanguageSwitch: true,
      body: Column(
        children: [
          InboxHub(current: current),
          Expanded(child: body),
        ],
      ),
    );
  }
}
