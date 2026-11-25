import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/person_text.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../../shared/studio_tr.dart';
import '../../session/state/studio_session_notifier.dart';
import '../../shell/more_common.dart';
import '../../shell/more_strings.dart';
import '../data/settings_repository.dart';
import '../settings_strings.dart';
import '../state/settings_state.dart';
import 'moment_forms.dart';

/// The approved claims: a read-only mirror of the registry.
class ClaimsScreen extends ConsumerWidget {
  const ClaimsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = SettingsStrings.of(context);
    final value = ref.watch(claimListProvider);
    final status = ref.watch(claimStatusFilterProvider);

    return ViewEditScaffold(
      title: t.claimsTitle,
      parentRoute: '/more/settings',
      actions: [
        moreHelpAction(context, title: t.claimsHelpTitle, lines: t.claimsHelp),
      ],
      body: MoreBody(
        child: Column(
          children: [
            ChoiceChipRow<ClaimStatus>(
              options: const [
                ClaimStatus.aPPROVED,
                ClaimStatus.hOLD,
                ClaimStatus.rETIRED,
              ],
              value: status == null ? null : ClaimStatus.parse(status),
              labelOf: t.claimStatusLabel,
              onChanged: (s) =>
                  ref.read(claimStatusFilterProvider.notifier).state = s?.wire,
            ),
            Expanded(
              child: StudioAsyncView<PagedState<StudioClaim>>(
                value: value,
                onRetry: () => ref.invalidate(claimListProvider),
                empty: StudioEmptyConfig(
                  purpose: t.claimsEmptyPurpose,
                  firstStep: t.claimsEmptyFirstStep,
                  icon: Icons.verified_outlined,
                ),
                isEmpty: (s) => s.items.isEmpty,
                builder: (context, state) => ListView(
                  key: const ValueKey('claims-list'),
                  children: [
                    for (final c in state.items) _ClaimCard(c: c),
                    ShowMoreFooter(
                      state: state,
                      onMore: () =>
                          ref.read(claimListProvider.notifier).loadMore(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.c});

  final StudioClaim c;

  @override
  Widget build(BuildContext context) {
    final t = SettingsStrings.of(context);
    final m = MoreStrings.of(context);
    final theme = Theme.of(context);
    final (fg, bg) = switch (c.status) {
      ClaimStatus.aPPROVED => (
        const Color(0xFF1F6B4A),
        const Color(0xFFD7EFE2),
      ),
      ClaimStatus.hOLD => (const Color(0xFF7A5A12), const Color(0xFFF5E8CC)),
      ClaimStatus.rETIRED => (StudioColors.plumMuted, const Color(0xFFF2EFF3)),
      _ => (StudioColors.deepPlum, StudioColors.softBlush),
    };
    return MoreCard(
      key: ValueKey('claim-${c.id}'),
      padding: const EdgeInsets.all(StudioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MorePill(
            t.claimStatusLabel(c.status),
            foreground: fg,
            background: bg,
          ),
          const SizedBox(height: StudioSpacing.sm),
          Text(t.englishWording, style: theme.textTheme.bodySmall),
          Text(c.textEn, style: theme.textTheme.bodyMedium),
          if (c.textAr != null) ...[
            const SizedBox(height: StudioSpacing.sm),
            Text(t.arabicWording, style: theme.textTheme.bodySmall),
            Text(
              c.textAr!,
              textDirection: TextDirection.rtl,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: StudioSpacing.sm),
          Text(
            [
              if (c.registryRef != null)
                '${t.registrySource}: ${c.registryRef}',
              if (c.syncedAt != null) t.syncedOn(m.date(c.syncedAt)),
            ].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Launches, Hero windows and budget steps, grouped by kind.
class MomentsScreen extends ConsumerWidget {
  const MomentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = SettingsStrings.of(context);
    final value = ref.watch(momentsProvider);
    final me = ref.watch(studioSessionProvider).valueOrNull;
    return ViewEditScaffold(
      title: t.momentsTitle,
      parentRoute: '/more/settings',
      actions: [
        if (me != null && me.canManageMoments)
          IconButton(
            key: const ValueKey('moment-add'),
            tooltip: context.tr('New moment', 'موعد جديد'),
            icon: const Icon(Icons.add),
            onPressed: () => MomentForms.edit(context, ref),
          ),
        moreHelpAction(
          context,
          title: t.momentsHelpTitle,
          lines: t.momentsHelp,
        ),
      ],
      body: MoreBody(
        child: StudioAsyncView<List<StudioMoment>>(
          value: value,
          onRetry: () => ref.invalidate(momentsProvider),
          empty: StudioEmptyConfig(
            purpose: t.momentsEmptyPurpose,
            firstStep: t.momentsEmptyFirstStep,
            icon: Icons.event_outlined,
          ),
          builder: (context, items) {
            final kinds = [
              MomentKind.launch,
              MomentKind.heroWindow,
              MomentKind.budgetStep,
              MomentKind.unknown,
            ];
            return ListView(
              key: const ValueKey('moments-list'),
              padding: const EdgeInsets.only(bottom: StudioSpacing.xxl),
              children: [
                if (me != null && me.canManageMoments && !me.canEditSettings)
                  Padding(
                    padding: const EdgeInsets.all(StudioSpacing.gutter),
                    child: Text(
                      t.momentsLeadNote,
                      key: const ValueKey('moments-lead-note'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                for (final k in kinds)
                  if (items.any((x) => x.kind == k)) ...[
                    SectionLabel(t.kindPlural(k)),
                    for (final mo in items.where((x) => x.kind == k))
                      _MomentCard(mo: mo),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MomentCard extends ConsumerWidget {
  const _MomentCard({required this.mo});

  final StudioMoment mo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = SettingsStrings.of(context);
    final m = MoreStrings.of(context);
    final theme = Theme.of(context);
    final when = mo.effectiveDate ?? mo.date;
    return MoreCard(
      key: ValueKey('moment-${mo.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PersonText(mo.title, style: theme.textTheme.titleSmall),
          Text(
            [
              if (when != null) m.date(when),
              if (mo.endDate != null) '${t.until} ${m.date(mo.endDate)}',
            ].join(' '),
            style: theme.textTheme.bodySmall,
          ),
          Wrap(
            spacing: StudioSpacing.sm,
            children: [
              if (mo.flavour != null) MorePill(mo.flavour!.name),
              if (mo.launchStage != null &&
                  mo.launchStage != LaunchStage.unknown)
                MorePill(t.stageLabel(mo.launchStage!)),
              if (mo.label != null && mo.label != JarLabel.unknown)
                MorePill(t.labelName(mo.label!)),
            ],
          ),
          if (mo.assignee != null)
            Text(
              '${t.owner}: ${mo.assignee!.fullName}',
              style: theme.textTheme.bodySmall,
            ),
          if (mo.note != null && mo.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.xs),
              child: PersonText(mo.note!, style: theme.textTheme.bodyMedium),
            ),
          if (mo.actions.contains('edit') || mo.actions.contains('move'))
            Wrap(
              spacing: StudioSpacing.sm,
              children: [
                if (mo.actions.contains('edit'))
                  TextButton(
                    key: ValueKey('moment-edit-${mo.id}'),
                    onPressed: () => MomentForms.edit(context, ref, mo: mo),
                    child: Semantics(
                      label: context.tr('Edit ${mo.title}', 'عدّل ${mo.title}'),
                      excludeSemantics: true,
                      child: Text(context.tr('Edit', 'تعديل')),
                    ),
                  ),
                if (mo.actions.contains('move'))
                  TextButton(
                    key: ValueKey('moment-move-${mo.id}'),
                    onPressed: () => MomentForms.move(context, ref, mo),
                    child: Semantics(
                      label: context.tr('Move ${mo.title}', 'انقل ${mo.title}'),
                      excludeSemantics: true,
                      child: Text(context.tr('Move', 'انقل')),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The option lists every form offers, read only.
class OptionsScreen extends ConsumerWidget {
  const OptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = SettingsStrings.of(context);
    final value = ref.watch(studioOptionsProvider);
    return ViewEditScaffold(
      title: t.optionsTitle,
      parentRoute: '/more/settings',
      actions: [
        moreHelpAction(
          context,
          title: t.optionsHelpTitle,
          lines: t.optionsHelp,
        ),
      ],
      body: MoreBody(
        child: StudioAsyncView<StudioOptions>(
          value: value,
          onRetry: () => ref.invalidate(studioOptionsProvider),
          empty: StudioEmptyConfig(
            purpose: t.optionsEmptyPurpose,
            firstStep: t.optionsEmptyFirstStep,
            icon: Icons.list_alt,
          ),
          isEmpty: (o) => o.lists.isEmpty,
          builder: (context, o) => ListView(
            key: const ValueKey('options-list'),
            padding: const EdgeInsets.only(bottom: StudioSpacing.xxl),
            children: [
              for (final e in o.lists.entries) ...[
                SectionLabel(t.optionListLabel(e.key)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StudioSpacing.gutter,
                  ),
                  child: Wrap(
                    spacing: StudioSpacing.sm,
                    runSpacing: StudioSpacing.xs,
                    children: [for (final v in e.value) MorePill(v)],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
