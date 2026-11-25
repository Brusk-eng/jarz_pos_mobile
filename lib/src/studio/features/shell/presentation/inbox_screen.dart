import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/router/studio_screen.dart';
import '../../../shared/placeholder_screen.dart';
import '../../../shared/view_edit_scaffold.dart';

/// Inbox with its three tabs. Each tab is its own route so it can be linked
/// to (`/inbox/decisions`); the tab bar just navigates between them.
class StudioInboxScreen extends StatefulWidget {
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

  @override
  State<StudioInboxScreen> createState() => _StudioInboxScreenState();
}

class _StudioInboxScreenState extends State<StudioInboxScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
    length: 3,
    vsync: this,
    initialIndex: widget.initialIndex,
  );

  @override
  void didUpdateWidget(StudioInboxScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialIndex != _controller.index) {
      _controller.index = widget.initialIndex;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = StudioStrings.of(context);
    final screen = StudioInboxScreen.screens[widget.initialIndex];
    return ViewEditScaffold(
      title: t.tabInbox,
      screen: screen,
      showLanguageSwitch: true,
      bottom: TabBar(
        controller: _controller,
        onTap: (i) => context.go(StudioInboxScreen.paths[i]),
        tabs: [
          Tab(key: const ValueKey('inbox-tab-approve'), text: t.inboxApprove),
          Tab(
            key: const ValueKey('inbox-tab-decisions'),
            text: t.inboxDecisions,
          ),
          Tab(key: const ValueKey('inbox-tab-ideas'), text: t.inboxIdeas),
        ],
      ),
      body: PlaceholderBody(screen: screen),
    );
  }
}
