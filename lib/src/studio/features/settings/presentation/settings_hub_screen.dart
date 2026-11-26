import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../shell/more_common.dart';
import '../../session/state/studio_session_notifier.dart';
import '../../session/presentation/biometric_widgets.dart';
import '../settings_strings.dart';
import 'tiktok_card.dart';

/// Settings: rules, flavors, approved claims, moments, people and the option
/// lists. Everyone may read; the founder edits through the pencil on each
/// page.
class SettingsHubScreen extends ConsumerWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = SettingsStrings.of(context);
    final me = ref.watch(studioSessionProvider).valueOrNull;
    final isFounder = me?.canEditSettings ?? false;
    final canMoments = me?.canManageMoments ?? false;

    Widget tile(String key, IconData icon, String title, String blurb) =>
        ListTile(
          key: ValueKey('settings-$key'),
          leading: Icon(icon, color: StudioColors.deepPlum),
          title: Text(title),
          subtitle: Text(blurb),
          trailing: Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_left
                : Icons.chevron_right,
          ),
          onTap: () => context.go('/more/settings/$key'),
        );

    return ViewEditScaffold(
      title: t.title,
      parentRoute: '/more',
      actions: [moreHelpAction(context, title: t.helpTitle, lines: t.help)],
      body: MoreBody(
        child: ListView(
          key: const ValueKey('settings-hub'),
          padding: const EdgeInsets.symmetric(vertical: StudioSpacing.sm),
          children: [
            if (!isFounder)
              Padding(
                padding: const EdgeInsets.all(StudioSpacing.gutter),
                child: Text(
                  canMoments ? t.readOnlyNoteLead : t.readOnlyNote,
                  key: const ValueKey('settings-read-only'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            tile('rules', Icons.rule, t.rules, t.rulesBlurb),
            tile(
              'flavours',
              Icons.icecream_outlined,
              t.flavours,
              t.flavoursBlurb,
            ),
            tile('claims', Icons.verified_outlined, t.claims, t.claimsBlurb),
            tile('moments', Icons.event_outlined, t.moments, t.momentsBlurb),
            tile('people', Icons.people_outline, t.people, t.peopleBlurb),
            tile('options', Icons.list_alt, t.options, t.optionsBlurb),
            if (isFounder) const TikTokCard(),
            const BiometricSettingsTile(),
          ],
        ),
      ),
    );
  }
}
