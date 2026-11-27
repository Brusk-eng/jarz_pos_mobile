import '../../../shared/layout/studio_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/person_text.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../shell/more_common.dart';
import '../../shell/more_strings.dart';
import '../data/paid_repository.dart';
import '../paid_strings.dart';
import 'paid_common.dart';

/// Paid at a glance: what is due now and why, the rounds, the stop signs and
/// the head of the queue.
class PaidOverviewScreen extends ConsumerWidget {
  const PaidOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = PaidStrings.of(context);
    final value = ref.watch(paidOverviewProvider);
    return ViewEditScaffold(
      contentWidth: StudioContentWidth.full,
      title: t.title,
      parentRoute: '/more',
      actions: [moreHelpAction(context, title: t.helpTitle, lines: t.help)],
      body: MoreBody(
        maxWidth: StudioContentWidth.full,
        child: StudioAsyncView<PaidOverview>(
          emptyOnNotFound: true,
          value: value,
          onRetry: () => ref.invalidate(paidOverviewProvider),
          empty: StudioEmptyConfig(
            purpose: t.emptyPurpose,
            firstStep: t.emptyFirstStep,
            icon: Icons.campaign_outlined,
            actionLabel: t.seeQueue,
            onAction: () => context.go('/more/paid/queue'),
          ),
          isEmpty: (o) =>
              o.rounds.isEmpty &&
              o.due.isEmpty &&
              o.queue.isEmpty &&
              o.stopSigns.isEmpty,
          builder: (context, o) => RefreshIndicator(
            onRefresh: () => ref.read(paidOverviewProvider.notifier).refresh(),
            child: _OverviewBody(o: o),
          ),
        ),
      ),
    );
  }
}

class _OverviewBody extends StatelessWidget {
  const _OverviewBody({required this.o});

  final PaidOverview o;

  @override
  Widget build(BuildContext context) {
    final t = PaidStrings.of(context);
    final m = MoreStrings.of(context);
    final theme = Theme.of(context);

    Widget section(List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );

    return ListView(
      key: const ValueKey('paid-overview'),
      padding: const EdgeInsets.only(bottom: StudioSpacing.xxl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StudioSpacing.gutter,
            StudioSpacing.sm,
            StudioSpacing.gutter,
            0,
          ),
          child: Text(
            t.asOf(m.dateTime(o.asOf)),
            key: const ValueKey('paid-as-of'),
            style: theme.textTheme.bodySmall,
          ),
        ),
        // Four sections: one column on a phone, 2 to 3 on a wide window.
        // The cards carry their own side margins, so the grid adds none.
        ResponsiveSectionGrid(
          gap: 0,
          sections: [
            GridSection(
              weight: 1 + 2.0 * o.due.length,
              child: section([
                SectionLabel(t.dueNow),
                if (o.due.isEmpty)
                  _Quiet(t.nothingDue)
                else
                  for (final d in o.due) _DueRow(d: d),
              ]),
            ),
            GridSection(
              weight: 1 + 1.0 * o.rounds.length,
              child: section([
                SectionLabel(t.liveRounds),
                if (o.rounds.isEmpty)
                  _Quiet(t.noRounds)
                else
                  for (final r in o.rounds) _RoundRow(r: r),
              ]),
            ),
            GridSection(
              weight: 1 + 1.0 * o.stopSigns.length,
              child: section([
                SectionLabel(t.stopSigns),
                if (o.stopSigns.isEmpty)
                  _Quiet(t.noStopSigns)
                else
                  for (final s in o.stopSigns) _StopSign(s: s),
              ]),
            ),
            GridSection(
              weight: 1 + 1.0 * (o.queue.length > 3 ? 3 : o.queue.length),
              child: section([
                SectionLabel(
                  t.queueSection,
                  trailing: TextButton(
                    key: const ValueKey('paid-open-queue'),
                    onPressed: () => context.go('/more/paid/queue'),
                    child: Text(t.seeQueue),
                  ),
                ),
                if (o.queue.isEmpty)
                  _Quiet(t.queueEmptyShort)
                else
                  for (final q in o.queue.take(3)) _QueueGlance(q: q),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}

class _Quiet extends StatelessWidget {
  const _Quiet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.gutter),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}

class _DueRow extends StatelessWidget {
  const _DueRow({required this.d});

  final PaidDue d;

  @override
  Widget build(BuildContext context) {
    final t = PaidStrings.of(context);
    final m = MoreStrings.of(context);
    final style = levelStyle(d.level);
    final theme = Theme.of(context);
    return MoreCard(
      key: ValueKey('due-${d.kind.wire}-${d.adId ?? d.roundCode ?? ''}'),
      onTap: () => context.go(
        d.roundCode != null
            ? '/more/paid/rounds/${d.roundCode}'
            : '/more/paid/queue',
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: style.bg, shape: BoxShape.circle),
            child: Icon(style.icon, size: 20, color: style.fg),
          ),
          const SizedBox(width: StudioSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PersonText(d.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: StudioSpacing.xxs),
                PersonText(d.why, style: theme.textTheme.bodyMedium),
                const SizedBox(height: StudioSpacing.xs),
                Text(
                  '${t.dueKindLabel(d.kind)} · ${t.dueOn(m.date(d.dueDate))}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundRow extends StatelessWidget {
  const _RoundRow({required this.r});

  final RoundBrief r;

  @override
  Widget build(BuildContext context) {
    final t = PaidStrings.of(context);
    final m = MoreStrings.of(context);
    final theme = Theme.of(context);
    return MoreCard(
      key: ValueKey('round-${r.code}'),
      onTap: () => context.go('/more/paid/rounds/${r.code}'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title ?? r.code, style: theme.textTheme.titleSmall),
                Text(
                  '${t.launches(m.date(r.launchDate))} · ${t.adsCount(r.nAds)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _StopSign extends StatelessWidget {
  const _StopSign({required this.s});

  final Signal s;

  @override
  Widget build(BuildContext context) {
    final style = levelStyle(noteLevelOfSignal(s.level));
    return MoreCard(
      key: ValueKey('stop-${s.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(style.icon, color: style.fg),
          const SizedBox(width: StudioSpacing.md),
          Expanded(child: Text(s.text)),
        ],
      ),
    );
  }
}

class _QueueGlance extends StatelessWidget {
  const _QueueGlance({required this.q});

  final QueueItem q;

  @override
  Widget build(BuildContext context) {
    final t = PaidStrings.of(context);
    return MoreCard(
      key: ValueKey('glance-${q.adId}'),
      onTap: () => context.go('/more/paid/queue'),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: StudioThumb(media: q.version.thumb ?? q.piece.picture),
          ),
          const SizedBox(width: StudioSpacing.md),
          Expanded(
            child: PersonText(
              q.piece.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(t.rankLabel(q.queueRank)),
        ],
      ),
    );
  }
}
