import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_strings.dart';

/// The five-tab frame: a bottom bar on a phone, a rail from tablet width up.
class StudioShellScaffold extends StatelessWidget {
  const StudioShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _icons = [
    (Icons.today_outlined, Icons.today),
    (Icons.inbox_outlined, Icons.inbox),
    (Icons.calendar_month_outlined, Icons.calendar_month),
    (Icons.view_kanban_outlined, Icons.view_kanban),
    (Icons.more_horiz, Icons.more_horiz),
  ];

  void _select(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = StudioStrings.of(context);
    final labels = [
      t.tabToday,
      t.tabInbox,
      t.tabCalendar,
      t.tabPieces,
      t.tabMore,
    ];
    final wide = MediaQuery.sizeOf(context).width >= 840;

    if (wide) {
      return Scaffold(
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
                    icon: Icon(_icons[i].$1),
                    selectedIcon: Icon(_icons[i].$2),
                    label: Text(labels[i]),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        key: const ValueKey('shell-bar'),
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _select,
        destinations: [
          for (var i = 0; i < 5; i++)
            NavigationDestination(
              icon: Icon(_icons[i].$1),
              selectedIcon: Icon(_icons[i].$2),
              label: labels[i],
            ),
        ],
      ),
    );
  }
}
