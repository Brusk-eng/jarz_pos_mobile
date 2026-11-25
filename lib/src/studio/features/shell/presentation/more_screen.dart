import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/studio_config.dart';
import '../../../core/l10n/studio_strings.dart';
import '../../../core/roles/studio_role.dart';
import '../../../core/router/studio_screen.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../session/state/studio_session_notifier.dart';

const _moreRoutes = {
  MoreItem.shoots: StudioRoutes.shoots,
  MoreItem.assets: StudioRoutes.assets,
  MoreItem.references: StudioRoutes.references,
  MoreItem.paid: StudioRoutes.paid,
  MoreItem.results: StudioRoutes.results,
  MoreItem.reports: StudioRoutes.reports,
  MoreItem.settings: StudioRoutes.settings,
};

const _moreIcons = {
  MoreItem.shoots: Icons.videocam_outlined,
  MoreItem.assets: Icons.photo_library_outlined,
  MoreItem.references: Icons.bookmarks_outlined,
  MoreItem.paid: Icons.campaign_outlined,
  MoreItem.results: Icons.insights_outlined,
  MoreItem.reports: Icons.description_outlined,
  MoreItem.settings: Icons.settings_outlined,
};

/// The More list. Its order and contents follow the role.
class StudioMoreScreen extends ConsumerWidget {
  const StudioMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = StudioStrings.of(context);
    final role = ref.watch(studioSessionProvider).valueOrNull?.primaryRole;
    final items = role == null ? const <MoreItem>[] : moreOrder[role]!;
    final fake = ref.watch(studioFakeProvider);

    return ViewEditScaffold(
      title: t.tabMore,
      showLanguageSwitch: true,
      body: ListView(
        key: const ValueKey('more-list'),
        padding: const EdgeInsets.symmetric(vertical: StudioSpacing.sm),
        children: [
          for (final item in items)
            ListTile(
              key: ValueKey('more-${item.name}'),
              leading: Icon(_moreIcons[item], color: StudioColors.deepPlum),
              title: Text(t.moreItem(item)),
              trailing: Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
              ),
              onTap: () => context.go(_moreRoutes[item]!),
            ),
          if (!fake) ...[
            const Divider(),
            ListTile(
              key: const ValueKey('more-sign-out'),
              leading: const Icon(Icons.logout),
              title: Text(t.signOut),
              onTap: () => ref.read(studioSessionProvider.notifier).signOut(),
            ),
          ],
        ],
      ),
    );
  }
}
