import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../inbox/state/inbox_state.dart';
import '../../walkthrough/walkthrough_sheet.dart';

/// The five-tab frame: a bottom bar on a phone, a rail from tablet width up.
class StudioShellScaffold extends ConsumerWidget {
  const StudioShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _icons = [
    (Icons.today_outlined, Icons.today),
    (Icons.inbox_outlined, Icons.inbox),
    (Icons.calendar_month_outlined, Icons.calendar_month),
    (Icons.view_kanban_outlined, Icons.view_kanban),
    (Icons.more_horiz, Icons.more_horiz),
  ];

  static const _inboxIndex = 1;

  void _select(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = StudioStrings.of(context);
    final labels = [
      t.tabToday,
      t.tabInbox,
      t.tabCalendar,
      t.tabPieces,
      t.tabMore,
    ];
    // What waits on this person plus unread notifications, on the Inbox tab.
    final inboxBadge =
        ref.watch(inboxBadgeProvider) + ref.watch(unreadBadgeProvider);
    Widget icon(int i, {required bool selected}) {
      final data = selected ? _icons[i].$2 : _icons[i].$1;
      final child = Icon(data);
      if (i != _inboxIndex || inboxBadge <= 0) return child;
      return Badge(
        key: const ValueKey('inbox-badge'),
        label: Text(inboxBadge > 99 ? '99+' : '$inboxBadge'),
        child: child,
      );
    }

    final wide = MediaQuery.sizeOf(context).width >= 840;

    if (wide) {
      return FirstLoginWalkthrough(
        child: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              key: const ValueKey('shell-rail'),
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (var i = 0; i < 5; i++)
                  NavigationRailDestination(
                    icon: icon(i, selected: false),
                    selectedIcon: icon(i, selected: true),
                    label: Text(labels[i]),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
        ),
      );
    }

    return FirstLoginWalkthrough(
      child: Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        key: const ValueKey('shell-bar'),
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _select,
        destinations: [
          for (var i = 0; i < 5; i++)
            NavigationDestination(
              icon: icon(i, selected: false),
              selectedIcon: icon(i, selected: true),
              label: labels[i],
            ),
        ],
      ),
      ),
    );
  }
}
