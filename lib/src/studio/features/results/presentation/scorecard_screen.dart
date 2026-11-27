import '../../../shared/layout/studio_layout.dart';
import 'package:flutter/material.dart';
import '../../../shared/studio_tr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_labels.dart';
import '../../../core/roles/studio_role.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../session/state/studio_session_notifier.dart';
import '../../shell/more_common.dart';
import '../../shell/more_strings.dart';
import '../data/results_repository.dart';
import '../results_strings.dart';
import '../state/results_state.dart';

/// The Sunday scorecard. The system fills the numbers (read only); a person
/// adds only what the system cannot read, writes the review and marks it done,
/// where the server's `actions` allow.
class ScorecardScreen extends ConsumerWidget {
  const ScorecardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ResultsStrings.of(context);
    final week = ref.watch(scorecardWeekProvider);
    final value = ref.watch(scorecardProvider(week));
    final role = ref.watch(studioSessionProvider).valueOrNull?.primaryRole;
    final canReview = role == StudioRole.founder || role == StudioRole.lead;
    final card = value.valueOrNull;

    return ViewEditScaffold(
      contentWidth: StudioContentWidth.full,
      title: t.title,
      parentRoute: '/more',
      onEdit: card != null && canReview && card.actions.contains('note')
          ? () => _editNotes(context, ref, week, card)
          : null,
      actions: [moreHelpAction(context, title: t.helpTitle, lines: t.help)],
      body: MoreBody(
        child: StudioAsyncView<WeekScorecard>(
          emptyOnNotFound: true,
          value: value,
          onRetry: () => ref.invalidate(scorecardProvider(week)),
          empty: StudioEmptyConfig(
            purpose: t.emptyPurpose,
            firstStep: t.emptyFirstStep,
            icon: Icons.insights_outlined,
            actionLabel: t.previousWeek,
            onAction: () => _previousWeek(ref, week),
          ),
          builder: (context, c) =>
              _ScorecardBody(card: c, week: week, canSeeMore: canReview),
        ),
      ),
    );
  }

  /// From the empty state: step back so the person is never stuck on a week
  /// with no card. An empty [week] means "this week" (the Sunday before today).
  void _previousWeek(WidgetRef ref, String week) {
    final now = DateTime.now();
    final base =
        DateTime.tryParse(week) ??
        DateTime(now.year, now.month, now.day - (now.weekday % 7));
    ref.read(scorecardWeekProvider.notifier).state = isoDate(
      base.subtract(const Duration(days: 7)),
    );
  }

  Future<void> _editNotes(
    BuildContext context,
    WidgetRef ref,
    String week,
    WeekScorecard card,
  ) async {
    final result = await showDialog<({String notes, String actions})>(
      context: context,
      builder: (_) => _NotesDialog(card: card),
    );
    if (result == null || !context.mounted) return;
    final t = ResultsStrings.of(context);
    await runMoreWrite(
      context,
      () => ref
          .read(scorecardActionsProvider(week))
          .saveNotes(reviewNotes: result.notes, actionsAgreed: result.actions),
      okText: t.notesSaved,
    );
  }
}

class _ScorecardBody extends ConsumerWidget {
  const _ScorecardBody({
    required this.card,
    required this.week,
    required this.canSeeMore,
  });

  final WeekScorecard card;
  final String week;
  final bool canSeeMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ResultsStrings.of(context);
    final m = MoreStrings.of(context);
    final theme = Theme.of(context);

    void shift(int days) {
      final d = DateTime.tryParse(card.weekStart);
      if (d == null) return;
      ref.read(scorecardWeekProvider.notifier).state = isoDate(
        d.add(Duration(days: days)),
      );
    }

    return ListView(
      key: const ValueKey('scorecard-body'),
      padding: const EdgeInsets.only(bottom: StudioSpacing.xxl),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: StudioSpacing.sm,
            vertical: StudioSpacing.sm,
          ),
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('week-prev'),
                tooltip: t.previousWeek,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => shift(-7),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      t.weekLabel(m.date(card.weekStart), m.date(card.weekEnd)),
                      key: const ValueKey('week-label'),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: StudioSpacing.xs),
                    MorePill(
                      t.statusLabel(card.status),
                      key: const ValueKey('scorecard-status'),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('week-next'),
                tooltip: t.nextWeek,
                icon: const Icon(Icons.chevron_right),
                onPressed: () => shift(7),
              ),
            ],
          ),
        ),
        if (canSeeMore)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.gutter,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                key: const ValueKey('top-ratings'),
                icon: const Icon(Icons.star_outline),
                label: Text(context.tr('Team ratings', 'تقييمات الفريق')),
                onPressed: () => context.go('/more/results/ratings'),
              ),
            ),
          ),
        SectionLabel(t.numbersTitle),
        for (final n in card.numbers) _NumberRow(n: n),
        if (card.gates.isNotEmpty) ...[
          SectionLabel(t.gatesTitle),
          MoreCard(
            child: Column(
              children: [
                for (final g in card.gates)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: StudioSpacing.xs,
                    ),
                    child: Row(
                      key: ValueKey('gate-${g.key}'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          g.ok ? Icons.check_circle : Icons.cancel,
                          size: 20,
                          color: g.ok
                              ? StudioColors.success
                              : StudioColors.danger,
                        ),
                        const SizedBox(width: StudioSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                StudioLabels.of(context).metric(g.key) ??
                                    g.label,
                              ),
                              if (g.detail != null)
                                Text(
                                  g.detail!,
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: StudioSpacing.sm),
                        Text(
                          g.ok
                              ? context.tr('Held', 'متحقق')
                              : context.tr('Not held', 'مش متحقق'),
                          key: ValueKey('gate-state-${g.key}'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: g.ok
                                ? StudioColors.success
                                : StudioColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                Text(
                  t.gatesHeld(card.gatesHeldWeeks),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
        SectionLabel(
          t.linesTitle,
          trailing: card.actions.contains('add_line')
              ? TextButton.icon(
                  key: const ValueKey('add-line'),
                  onPressed: () => _addLine(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(t.addLine),
                )
              : null,
        ),
        if (card.lines.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.gutter,
            ),
            child: Text(t.noLines, style: theme.textTheme.bodySmall),
          )
        else
          MoreCard(
            child: Column(
              children: [
                for (final l in card.lines)
                  LabeledValue(l.label, l.value ?? t.sourceLabel(l.source)),
              ],
            ),
          ),
        SectionLabel(t.reviewNotes),
        _TextBlock(text: card.reviewNotes, empty: t.nothingWritten),
        SectionLabel(t.actionsAgreed),
        _TextBlock(text: card.actionsAgreed, empty: t.nothingWritten),
        if (card.reviewedBy != null && card.reviewedAt != null)
          Padding(
            padding: const EdgeInsets.all(StudioSpacing.gutter),
            child: Text(
              t.reviewedBy(
                card.reviewedBy!.fullName,
                m.dateTime(card.reviewedAt),
              ),
              key: const ValueKey('reviewed-by'),
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (card.actions.contains('mark_reviewed') &&
            card.status != ScorecardStatus.reviewed)
          Padding(
            padding: const EdgeInsets.all(StudioSpacing.gutter),
            child: FilledButton(
              key: const ValueKey('mark-reviewed'),
              onPressed: () => runMoreWrite(
                context,
                () => ref.read(scorecardActionsProvider(week)).markReviewed(),
                okText: t.reviewedOk,
              ),
              child: Text(t.markReviewed),
            ),
          ),
        if (canSeeMore) ...[
          const Divider(),
          ListTile(
            key: const ValueKey('go-by-piece'),
            leading: const Icon(Icons.view_list_outlined),
            title: Text(t.seeByPiece),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/more/results/pieces'),
          ),
          ListTile(
            key: const ValueKey('go-summary'),
            leading: const Icon(Icons.bar_chart),
            title: Text(t.seeSummary),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/more/results/summary'),
          ),
          ListTile(
            key: const ValueKey('go-ratings'),
            leading: const Icon(Icons.star_outline),
            title: Text(context.tr('Team ratings', 'تقييمات الفريق')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/more/results/ratings'),
          ),
        ],
      ],
    );
  }

  Future<void> _addLine(BuildContext context, WidgetRef ref) async {
    final t = ResultsStrings.of(context);
    final result = await showDialog<({String label, String value})>(
      context: context,
      builder: (_) => const _LineDialog(),
    );
    if (result == null || !context.mounted) return;
    await runMoreWrite(
      context,
      () => ref
          .read(scorecardActionsProvider(week))
          .addLine(result.label, result.value),
      okText: t.lineAdded,
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.text, required this.empty});

  final String? text;
  final String empty;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.gutter),
    child: Text(
      (text == null || text!.isEmpty) ? empty : text!,
      style: (text == null || text!.isEmpty)
          ? Theme.of(context).textTheme.bodySmall
          : Theme.of(context).textTheme.bodyMedium,
    ),
  );
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({required this.n});

  final ScorecardNumber n;

  String _fmt(MoreStrings m, double v, StudioLabels labels) {
    if (n.unit == 'EGP') return m.egp(v);
    if (n.unit == '%') return m.percent(v);
    final s = v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
    return n.unit.isEmpty ? s : '$s ${labels.unit(n.unit)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = ResultsStrings.of(context);
    final m = MoreStrings.of(context);
    final theme = Theme.of(context);
    final ok = n.ok;
    return MoreCard(
      key: ValueKey('number-${n.key}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  StudioLabels.of(context).metric(n.key) ?? n.label,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: StudioSpacing.xxs),
                Text(
                  [
                    t.sourceLabel(n.source),
                    if (n.line != null)
                      '${t.againstLine}: ${_fmt(m, n.line!, StudioLabels.of(context))}',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: StudioSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                n.value == null
                    ? '-'
                    : _fmt(m, n.value!, StudioLabels.of(context)),
                key: ValueKey('number-value-${n.key}'),
                style: theme.textTheme.titleMedium,
              ),
              if (ok != null)
                Icon(
                  ok ? Icons.check_circle : Icons.cancel,
                  size: 18,
                  semanticLabel: ok ? t.aboveLine : t.belowLine,
                  color: ok ? StudioColors.success : StudioColors.danger,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotesDialog extends StatefulWidget {
  const _NotesDialog({required this.card});

  final WeekScorecard card;

  @override
  State<_NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<_NotesDialog> {
  late final _notes = TextEditingController(
    text: widget.card.reviewNotes ?? '',
  );
  late final _actions = TextEditingController(
    text: widget.card.actionsAgreed ?? '',
  );

  @override
  void dispose() {
    _notes.dispose();
    _actions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ResultsStrings.of(context);
    final m = MoreStrings.of(context);
    return AlertDialog(
      key: const ValueKey('notes-dialog'),
      title: Text(t.editNotesTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('notes-field'),
              controller: _notes,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(labelText: t.reviewNotes),
            ),
            const SizedBox(height: StudioSpacing.md),
            TextField(
              key: const ValueKey('actions-field'),
              controller: _actions,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(labelText: t.actionsAgreed),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(m.cancel),
        ),
        FilledButton(
          key: const ValueKey('notes-save'),
          onPressed: () => Navigator.of(
            context,
          ).pop((notes: _notes.text.trim(), actions: _actions.text.trim())),
          child: Text(m.save),
        ),
      ],
    );
  }
}

class _LineDialog extends StatefulWidget {
  const _LineDialog();

  @override
  State<_LineDialog> createState() => _LineDialogState();
}

class _LineDialogState extends State<_LineDialog> {
  final _label = TextEditingController();
  final _value = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ResultsStrings.of(context);
    final m = MoreStrings.of(context);
    final ready =
        _label.text.trim().isNotEmpty && _value.text.trim().isNotEmpty;
    return AlertDialog(
      key: const ValueKey('line-dialog'),
      title: Text(t.addLineTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('line-label'),
            controller: _label,
            decoration: InputDecoration(hintText: t.lineLabelHint),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            key: const ValueKey('line-value'),
            controller: _value,
            decoration: InputDecoration(hintText: t.lineValueHint),
            onChanged: (_) => setState(() {}),
          ),
          if (!ready)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.sm),
              child: Text(
                t.lineNeedsBoth,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(m.cancel),
        ),
        FilledButton(
          key: const ValueKey('line-save'),
          onPressed: ready
              ? () => Navigator.of(
                  context,
                ).pop((label: _label.text.trim(), value: _value.text.trim()))
              : null,
          child: Text(m.add),
        ),
      ],
    );
  }
}
