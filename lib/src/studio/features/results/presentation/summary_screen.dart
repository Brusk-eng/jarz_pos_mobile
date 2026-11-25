import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../shell/more_common.dart';
import '../../shell/more_strings.dart';
import '../data/results_repository.dart';
import '../results_strings.dart';
import '../state/results_state.dart';

const _groupBys = [
  'format',
  'persona',
  'situation',
  'layer',
  'flavour',
  'series',
];

/// The summary: pieces grouped by format, persona, situation, layer, flavor
/// or series, as simple bars drawn against the best group.
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ResultsStrings.of(context);
    final query = ref.watch(summaryQueryProvider);
    final value = ref.watch(resultsSummaryProvider(query));
    final days = ref.watch(summaryDaysProvider);

    return ViewEditScaffold(
      title: t.summaryTitle,
      parentRoute: '/more/results',
      actions: [
        moreHelpAction(
          context,
          title: t.summaryHelpTitle,
          lines: t.summaryHelp,
        ),
      ],
      body: MoreBody(
        child: Column(
          children: [
            ChoiceChipRow<String>(
              options: _groupBys.skip(1).toList(),
              value: query.groupBy == 'format' ? null : query.groupBy,
              allLabel: t.groupByLabel('format'),
              labelOf: t.groupByLabel,
              onChanged: (v) =>
                  ref.read(summaryGroupByProvider.notifier).state =
                      v ?? 'format',
            ),
            ChoiceChipRow<int>(
              options: const [28, 90],
              value: days == 7 ? null : days,
              allLabel: t.lastDays(7),
              labelOf: t.lastDays,
              onChanged: (v) =>
                  ref.read(summaryDaysProvider.notifier).state = v ?? 7,
            ),
            Expanded(
              child: StudioAsyncView<ResultSummary>(
                value: value,
                onRetry: () => ref.invalidate(resultsSummaryProvider(query)),
                empty: StudioEmptyConfig(
                  purpose: t.summaryEmptyPurpose,
                  firstStep: t.summaryEmptyFirstStep,
                  icon: Icons.bar_chart,
                ),
                isEmpty: (s) => s.groups.isEmpty,
                builder: (context, s) => _Groups(summary: s),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Groups extends StatelessWidget {
  const _Groups({required this.summary});

  final ResultSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = ResultsStrings.of(context);
    final m = MoreStrings.of(context);
    final theme = Theme.of(context);
    final best = summary.groups.fold<double>(
      0,
      (a, g) => (g.avgViews ?? 0) > a ? g.avgViews! : a,
    );
    return ListView(
      key: const ValueKey('summary-groups'),
      padding: const EdgeInsets.only(bottom: StudioSpacing.xxl),
      children: [
        for (final g in summary.groups)
          MoreCard(
            key: ValueKey('group-${g.key}'),
            padding: const EdgeInsets.all(StudioSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.label, style: theme.textTheme.titleSmall),
                Text(
                  t.piecesLine(g.pieces, g.posts, g.reads),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: StudioSpacing.sm),
                _Bar(
                  keyName: 'bar-${g.key}',
                  label: t.avgViews,
                  value: g.avgViews == null
                      ? '-'
                      : groupDigits(g.avgViews!.round()),
                  fraction: best == 0 || g.avgViews == null
                      ? 0
                      : g.avgViews! / best,
                ),
                if (g.avgHold3 != null)
                  LabeledValue(t.avgHold, m.percent(g.avgHold3!)),
                if (g.ads > 0) ...[
                  LabeledValue(t.spendLabel, m.egp(g.spend)),
                  LabeledValue(t.purchasesLabel, '${g.purchases}'),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.keyName,
    required this.label,
    required this.value,
    required this.fraction,
  });

  final String keyName;
  final String label;
  final String value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
            Text(value, style: theme.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: StudioSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(StudioRadii.pill),
          child: Container(
            height: 10,
            width: double.infinity,
            color: StudioColors.blushPale,
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              key: ValueKey(keyName),
              widthFactor: fraction.clamp(0.0, 1.0),
              child: Container(color: StudioColors.berryPink),
            ),
          ),
        ),
      ],
    );
  }
}
