import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/l10n/studio_locale.dart';
import '../../../core/network/studio_api.dart';
import '../../../core/roles/studio_role.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../session/state/studio_session_notifier.dart';
import '../../walkthrough/walkthrough_sheet.dart';
import '../../walkthrough/walkthrough_strings.dart';
import '../more_common.dart';
import '../more_strings.dart';

/// Where each More entry goes. Shoots and Library sit at the contract's
/// paths (`/shoots`, `/assets`), above the shell.
const _moreRoutes = {
  MoreItem.shoots: '/shoots',
  MoreItem.assets: '/assets',
  MoreItem.references: '/more/references',
  MoreItem.paid: '/more/paid',
  MoreItem.results: '/more/results',
  MoreItem.reports: '/more/reports',
  MoreItem.settings: '/more/settings',
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

/// The route of the notification settings screen (built elsewhere).
const notificationSettingsRoute = '/inbox/notifications/settings';

/// The entries `session.me` says this person may open, in the server's order.
/// Null while loading or when the call failed (the role list is used then).
final moreNavKeysProvider = FutureProvider.autoDispose<List<String>?>((
  ref,
) async {
  try {
    final me = await ref.watch(studioApiProvider).sessionMe();
    return [for (final n in me.nav) n.key];
  } catch (_) {
    return null;
  }
});

/// The app version, or empty when the platform cannot say (tests).
final moreAppVersionProvider = FutureProvider.autoDispose<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return info.buildNumber.isEmpty
        ? info.version
        : '${info.version}+${info.buildNumber}';
  } catch (_) {
    return '';
  }
});

MoreItem? _itemOfNavKey(String key) => switch (key) {
  'shoots' => MoreItem.shoots,
  'assets' => MoreItem.assets,
  'references' => MoreItem.references,
  'paid' => MoreItem.paid,
  'results' => MoreItem.results,
  'reports' => MoreItem.reports,
  'settings' => MoreItem.settings,
  _ => null,
};

String _labelOf(MoreStrings t, MoreItem i) => switch (i) {
  MoreItem.shoots => t.entryShoots,
  MoreItem.assets => t.entryLibrary,
  MoreItem.references => t.entryReferences,
  MoreItem.paid => t.entryPaid,
  MoreItem.results => t.entryResults,
  MoreItem.reports => t.entryReports,
  MoreItem.settings => t.entrySettings,
};

/// The More list: Library, Shoots, References, Paid, Results, Reports,
/// Settings, notification settings, language, sign out and the version.
/// Each entry shows only when `session.me` lists it for this person.
class StudioMoreScreen extends ConsumerWidget {
  const StudioMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = MoreStrings.of(context);
    final role = ref.watch(studioSessionProvider).valueOrNull?.primaryRole;
    final nav = ref.watch(moreNavKeysProvider).valueOrNull;
    final version = ref.watch(moreAppVersionProvider).valueOrNull ?? '';

    final List<MoreItem> items;
    if (nav != null) {
      items = [for (final k in nav) ?_itemOfNavKey(k)];
    } else {
      items = role == null ? const <MoreItem>[] : moreOrder[role]!;
    }

    return ViewEditScaffold(
      title: t.moreTitle,
      rootTab: true,
      showLanguageSwitch: true,
      actions: [
        moreHelpAction(context, title: t.moreHelpTitle, lines: t.moreHelp),
      ],
      body: MoreBody(
        child: items.isEmpty
            ? StudioEmptyState(
                config: StudioEmptyConfig(
                  purpose: t.moreEmpty,
                  firstStep: t.moreEmptyFirstStep,
                ),
              )
            : ListView(
                key: const ValueKey('more-list'),
                padding: const EdgeInsets.symmetric(vertical: StudioSpacing.sm),
                children: [
                  for (final item in items)
                    ListTile(
                      key: ValueKey('more-${item.name}'),
                      leading: Icon(
                        _moreIcons[item],
                        color: StudioColors.deepPlum,
                      ),
                      title: Text(_labelOf(t, item)),
                      trailing: const _Chevron(),
                      onTap: () => context.go(_moreRoutes[item]!),
                    ),
                  ListTile(
                    key: const ValueKey('more-notifications'),
                    leading: const Icon(
                      Icons.notifications_outlined,
                      color: StudioColors.deepPlum,
                    ),
                    title: Text(t.entryNotifications),
                    trailing: const _Chevron(),
                    onTap: () => context.go(notificationSettingsRoute),
                  ),
                  if (role != null)
                    ListTile(
                      key: const ValueKey('more-help'),
                      leading: const Icon(
                        Icons.help_outline,
                        color: StudioColors.deepPlum,
                      ),
                      title: Text(WalkthroughStrings.of(context).helpEntry),
                      subtitle: Text(
                        WalkthroughStrings.of(context).helpEntryHint,
                      ),
                      trailing: const _Chevron(),
                      onTap: () => showWalkthrough(context, role),
                    ),
                  const Divider(),
                  ListTile(
                    key: const ValueKey('more-language'),
                    leading: const Icon(
                      Icons.translate,
                      color: StudioColors.deepPlum,
                    ),
                    title: Text(t.languageRow),
                    trailing: Text(
                      t.isArabic ? 'English' : 'العربية',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onTap: () {
                      final cur = ref.read(studioLocaleProvider);
                      ref
                          .read(studioLocaleProvider.notifier)
                          .state = cur.languageCode == 'ar'
                          ? const Locale('en')
                          : const Locale('ar');
                    },
                  ),
                  ListTile(
                    key: const ValueKey('more-sign-out'),
                    leading: const Icon(Icons.logout),
                    title: Text(t.signOutRow),
                    onTap: () =>
                        ref.read(studioSessionProvider.notifier).signOut(),
                  ),
                  if (version.isNotEmpty)
                    Padding(
                      key: const ValueKey('more-version'),
                      padding: const EdgeInsets.all(StudioSpacing.gutter),
                      child: Text(
                        t.appVersion(version),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) => Icon(
    Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left
        : Icons.chevron_right,
  );
}
