import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/roles/studio_role.dart';
import '../../../core/router/studio_screen.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../session/state/studio_session_notifier.dart';

/// Today: what waits on this person, in the order their role works in.
/// The blocks are placeholders until the Today endpoint exists.
class StudioTodayScreen extends ConsumerWidget {
  const StudioTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = StudioStrings.of(context);
    final theme = Theme.of(context);
    final me = ref.watch(studioSessionProvider).valueOrNull;
    final role = me?.primaryRole;
    final blocks = role == null ? const <TodayBlock>[] : todayOrder[role]!;
    final copy = t.screen(StudioScreen.today);

    return ViewEditScaffold(
      title: t.tabToday,
      screen: StudioScreen.today,
      showLanguageSwitch: true,
      body: StudioAsyncView<List<TodayBlock>>(
        value: AsyncData(blocks),
        empty: StudioEmptyConfig(
          purpose: copy.purpose,
          firstStep: copy.firstStep,
        ),
        builder: (context, blocks) => ListView(
          key: const ValueKey('today-list'),
          padding: const EdgeInsets.all(StudioSpacing.gutter),
          children: [
            if (me != null && role != null) ...[
              Text(
                t.helloUser(me.fullName),
                key: const ValueKey('today-hello'),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: StudioSpacing.xs),
              Text(t.role(role), style: theme.textTheme.bodySmall),
              const SizedBox(height: StudioSpacing.lg),
            ],
            for (final block in blocks)
              Padding(
                padding: const EdgeInsets.only(bottom: StudioSpacing.md),
                child: Card(
                  key: ValueKey('today-block-${block.name}'),
                  child: Padding(
                    padding: const EdgeInsets.all(StudioSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.todayBlock(block),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: StudioSpacing.xs),
                        Text(t.nothingHere, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
