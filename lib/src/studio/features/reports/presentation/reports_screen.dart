import '../../../shared/layout/studio_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/person_text.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../shell/more_common.dart';
import '../../shell/more_strings.dart';
import '../data/reports_repository.dart';
import '../reports_strings.dart';
import '../state/reports_state.dart';

/// The index of pages Claude produced: newest first, filtered by kind,
/// searched by title and topic, each opening in the browser.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ReportsStrings.of(context);
    final value = ref.watch(reportsProvider);
    final kind = ref.watch(reportsKindFilterProvider);
    final query = ref.watch(reportsSearchProvider);

    return ViewEditScaffold(
      contentWidth: StudioContentWidth.form,
      title: t.title,
      parentRoute: '/more',
      actions: [moreHelpAction(context, title: t.helpTitle, lines: t.help)],
      body: MoreBody(
        child: Column(
          children: [
            MoreSearchField(
              hint: t.searchHint,
              initial: query,
              liveChange: true,
              onChanged: (q) =>
                  ref.read(reportsSearchProvider.notifier).state = q,
            ),
            ChoiceChipRow<ReportKind>(
              options: const [
                ReportKind.adsRead,
                ReportKind.plan,
                ReportKind.study,
                ReportKind.retro,
                ReportKind.competitorDaily,
                ReportKind.referenceIntake,
                ReportKind.weeklyWorkingNow,
                ReportKind.sundayReview,
                ReportKind.other,
              ],
              value: kind == null ? null : ReportKind.parse(kind),
              labelOf: t.kindLabel,
              onChanged: (k) =>
                  ref.read(reportsKindFilterProvider.notifier).state = k?.wire,
            ),
            Expanded(
              child: StudioAsyncView<PagedState<StudioReport>>(
                value: value,
                onRetry: () => ref.invalidate(reportsProvider),
                empty: StudioEmptyConfig(
                  purpose: t.emptyPurpose,
                  firstStep: t.emptyFirstStep,
                  icon: Icons.description_outlined,
                ),
                isEmpty: (s) => s.items.isEmpty,
                builder: (context, state) {
                  final shown = filterReports(state.items, query);
                  return ListView(
                    key: const ValueKey('reports-list'),
                    children: [
                      if (shown.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(StudioSpacing.xl),
                          child: Text(
                            t.emptyFiltered,
                            key: const ValueKey('reports-no-match'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      for (final r in shown) _ReportRow(r: r),
                      ShowMoreFooter(
                        state: state,
                        onMore: () =>
                            ref.read(reportsProvider.notifier).loadMore(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends ConsumerWidget {
  const _ReportRow({required this.r});

  final StudioReport r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ReportsStrings.of(context);
    final m = MoreStrings.of(context);
    final theme = Theme.of(context);
    return MoreCard(
      key: ValueKey('report-${r.id}'),
      onTap: () => openMoreLink(context, ref, r.url),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: StudioSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MorePill(t.kindLabel(r.kind)),
                    Text(
                      m.date(r.reportDate),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: StudioSpacing.sm),
                PersonText(r.title, style: theme.textTheme.titleSmall),
                if (r.summary != null && r.summary!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: StudioSpacing.xs),
                    child: Text(
                      r.summary!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                if (r.decisionsOpen > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: StudioSpacing.sm),
                    child: MorePill(
                      t.openQuestions(r.decisionsOpen),
                      foreground: StudioColors.warning,
                      background: const Color(0xFFF5E8CC),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: StudioSpacing.sm),
          const Icon(Icons.open_in_new, size: 20),
        ],
      ),
    );
  }
}
