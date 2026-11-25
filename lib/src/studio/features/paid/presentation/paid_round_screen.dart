import '../../../shared/studio_pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../shell/more_common.dart';
import '../../shell/more_strings.dart';
import '../../settings/data/settings_repository.dart';
import '../paid_rule_check.dart';
import '../paid_strings.dart';
import '../state/paid_state.dart';
import 'paid_common.dart';

/// One test round: its dates, and each ad with its numbers, what the rules say
/// about it, and the buttons the server allows.
class PaidRoundScreen extends ConsumerWidget {
  const PaidRoundScreen({super.key, required this.roundCode});

  final String roundCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = PaidStrings.of(context);
    final value = ref.watch(paidRoundStateProvider(roundCode));
    final round = value.valueOrNull;
    return ViewEditScaffold(
      title: round?.title ?? roundCode,
      parentRoute: '/more/paid',
      onEdit: round != null && round.actions.contains('edit')
          ? () => _editRound(context, ref, round)
          : null,
      actions: [
        moreHelpAction(context, title: t.roundHelpTitle, lines: t.roundHelp),
      ],
      body: MoreBody(
        child: StudioAsyncView<PaidRound>(
          value: value,
          onRetry: () => ref.invalidate(paidRoundStateProvider(roundCode)),
          empty: StudioEmptyConfig(
            purpose: t.roundEmptyPurpose,
            firstStep: t.roundEmptyFirstStep,
          ),
          builder: (context, r) => _RoundBody(round: r),
        ),
      ),
    );
  }

  Future<void> _editRound(
    BuildContext context,
    WidgetRef ref,
    PaidRound round,
  ) async {
    final result = await showDialog<_RoundEdit>(
      context: context,
      builder: (_) => _EditRoundDialog(round: round),
    );
    if (result == null || !context.mounted) return;
    final t = PaidStrings.of(context);
    await runMoreWrite(
      context,
      () => ref
          .read(paidRoundStateProvider(roundCode).notifier)
          .edit(result.launchDate, title: result.title, note: result.note),
      okText: t.roundSaved,
    );
  }
}

class _RoundBody extends StatelessWidget {
  const _RoundBody({required this.round});

  final PaidRound round;

  @override
  Widget build(BuildContext context) {
    final t = PaidStrings.of(context);
    final m = MoreStrings.of(context);
    final theme = Theme.of(context);

    return ListView(
      key: const ValueKey('round-body'),
      padding: const EdgeInsets.only(bottom: StudioSpacing.xxl),
      children: [
        MoreCard(
          child: Column(
            children: [
              LabeledValue(t.launchDate, m.date(round.launchDate)),
              LabeledValue(t.dayFourRead, m.date(round.d4Date)),
              LabeledValue(t.daySevenRead, m.date(round.d7Date)),
              if (round.assignee != null)
                LabeledValue(t.assignedTo, round.assignee!.fullName),
              if (round.note != null && round.note!.isNotEmpty)
                LabeledValue(t.roundNoteField, round.note!),
            ],
          ),
        ),
        if (round.stateCounts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.gutter,
              vertical: StudioSpacing.sm,
            ),
            child: Wrap(
              spacing: StudioSpacing.sm,
              runSpacing: StudioSpacing.xs,
              children: [
                for (final e in round.stateCounts.entries)
                  if (e.value > 0)
                    MorePill(
                      '${t.stateLabel(AdState.parse(e.key))} ${e.value}',
                    ),
              ],
            ),
          ),
        if (round.ads.isEmpty)
          Padding(
            padding: const EdgeInsets.all(StudioSpacing.gutter),
            child: Text(t.noAds, style: theme.textTheme.bodySmall),
          )
        else
          for (final ad in round.ads)
            _AdCard(
              key: ValueKey('ad-${ad.id}'),
              ad: ad,
              roundCode: round.code,
            ),
      ],
    );
  }
}

class _AdCard extends ConsumerWidget {
  const _AdCard({super.key, required this.ad, required this.roundCode});

  final PaidAd ad;
  final String roundCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = PaidStrings.of(context);
    final m = MoreStrings.of(context);
    final theme = Theme.of(context);
    final colors = adStateColors(ad.state);
    final n = ad.numbers;

    return MoreCard(
      padding: const EdgeInsets.all(StudioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: StudioThumb(media: ad.thumb),
              ),
              const SizedBox(width: StudioSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ad.name, style: theme.textTheme.titleSmall),
                    if (ad.adset != null)
                      Text(ad.adset!, style: theme.textTheme.bodySmall),
                    const SizedBox(height: StudioSpacing.xs),
                    MorePill(
                      key: ValueKey('state-${ad.id}'),
                      ad.state == null || ad.state == AdState.unknown
                          ? (ad.state == null
                                ? t.stateLabel(null)
                                : ad.stateLabel)
                          : t.stateLabel(ad.state),
                      foreground: colors.fg,
                      background: colors.bg,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: StudioSpacing.md),
          if (n == null)
            Text(t.noNumbersYet, style: theme.textTheme.bodySmall)
          else ...[
            Row(
              children: [
                _Stat(label: t.spend, value: m.egp(n.spend)),
                _Stat(label: t.purchases, value: '${n.purchases}'),
                _Stat(
                  label: t.costPerPurchase,
                  value: n.cpa == null ? t.noPurchasesYet : m.egp(n.cpa!),
                  keyName: 'cpa-${ad.id}',
                ),
              ],
            ),
            if (n.purchases > 0)
              Padding(
                padding: const EdgeInsets.only(top: StudioSpacing.xs),
                child: Text(
                  '${t.purchaseValue}: ${m.egp(n.purchaseValue)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: StudioSpacing.md),
            Container(
              key: ValueKey('diagnostics-${ad.id}'),
              padding: const EdgeInsets.all(StudioSpacing.md),
              decoration: BoxDecoration(
                color: StudioColors.blushPale,
                borderRadius: BorderRadius.circular(StudioRadii.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${t.diagnosticsTitle} · ${t.diagnosticsNote}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: StudioSpacing.xs),
                  Wrap(
                    spacing: StudioSpacing.lg,
                    children: [
                      if (n.ctr != null)
                        Text('${t.ctr} ${m.percent(n.ctr!, digits: 2)}'),
                      if (n.frequency != null)
                        Text(
                          '${t.frequency} ${n.frequency!.toStringAsFixed(1)}',
                        ),
                      if (n.hold3 != null)
                        Text('${t.hold3} ${m.percent(n.hold3!)}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (ad.hint != null) ...[
            const SizedBox(height: StudioSpacing.md),
            _Hint(hint: ad.hint!, adId: ad.id),
          ],
          if (ad.readDue != null && ad.readDue != ReadWindow.unknown)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.sm),
              child: Text(
                t.readDueLabel(
                  ad.readDue == ReadWindow.d4 ? t.dayFourRead : t.daySevenRead,
                ),
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (ad.note != null && ad.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.sm),
              child: Text('${t.adNoteLabel}: ${ad.note}'),
            ),
          if (ad.actions.contains('set_state'))
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.md),
              child: FilledButton.tonal(
                key: ValueKey('set-state-${ad.id}'),
                onPressed: () => _setState(context, ref),
                child: Text(t.setState),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _setState(BuildContext context, WidgetRef ref) async {
    final t = PaidStrings.of(context);
    double? maxCpp;
    try {
      final rules = await ref.read(rulesProvider.future);
      maxCpp = rules
          .where((r) => r.key == 'again_max_cpp')
          .map((r) => r.value)
          .firstOrNull;
    } catch (_) {
      // The rules are a help here; the dialog works without them.
    }
    if (!context.mounted) return;
    final result = await showDialog<_StatePick>(
      context: context,
      builder: (_) => _StateDialog(ad: ad, maxCostPerPurchase: maxCpp),
    );
    if (result == null || !context.mounted) return;
    await runMoreWrite(
      context,
      () => ref
          .read(paidRoundStateProvider(roundCode).notifier)
          .setAdState(
            ad.id,
            result.state,
            note: result.note.isEmpty ? null : result.note,
          ),
      okText: t.stateSaved(t.stateLabel(result.state)),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.keyName});

  final String label;
  final String value;
  final String? keyName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: StudioSpacing.xxs),
          Text(
            value,
            key: keyName == null ? null : ValueKey(keyName),
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.hint, required this.adId});

  final AdHint hint;
  final String adId;

  @override
  Widget build(BuildContext context) {
    final t = PaidStrings.of(context);
    final style = levelStyle(hint.level);
    return Container(
      key: ValueKey('hint-$adId'),
      padding: const EdgeInsets.all(StudioSpacing.md),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(StudioRadii.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(style.icon, color: style.fg, size: 20),
          const SizedBox(width: StudioSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.rulesSay, style: Theme.of(context).textTheme.bodySmall),
                Text(hint.text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatePick {
  const _StatePick(this.state, this.note);

  /// Null clears the state.
  final AdState? state;
  final String note;
}

class _StateDialog extends StatefulWidget {
  const _StateDialog({required this.ad, this.maxCostPerPurchase});

  final PaidAd ad;
  final double? maxCostPerPurchase;
  AdState? get current => ad.state;

  @override
  State<_StateDialog> createState() => _StateDialogState();
}

class _StateDialogState extends State<_StateDialog> {
  static const _choices = [
    AdState.testing,
    AdState.winner,
    AdState.oneMoreRound,
    AdState.off,
    AdState.inScale,
  ];

  late AdState? _picked = widget.current == AdState.queued
      ? null
      : widget.current;
  bool _touched = false;
  bool _warned = false;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PaidStrings.of(context);
    final m = MoreStrings.of(context);
    final warning = adStateRuleWarning(
      widget.ad,
      _picked,
      maxCostPerPurchase: widget.maxCostPerPurchase,
    );
    final warnText = switch (warning) {
      WinnerNeedsPurchases(:final have, :final need) =>
        t.againstWinnerPurchases(t.stateLabel(_picked), have, need),
      CostAboveLine(:final cpa, :final line) =>
        t.againstCostLine(t.stateLabel(_picked), cpa, line),
      null => null,
    };
    return AlertDialog(
      key: const ValueKey('state-dialog'),
      title: Text(t.setStateTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.ad.hint != null)
              Padding(
                padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
                child: _Hint(
                  hint: widget.ad.hint!,
                  adId: '${widget.ad.id}-dialog',
                ),
              ),
            RadioGroup<AdState?>(
              groupValue: _picked,
              onChanged: (v) => setState(() {
                _picked = v;
                _touched = true;
                _warned = false;
              }),
              child: Column(
                children: [
                  for (final s in _choices)
                    RadioListTile<AdState?>(
                      key: ValueKey('state-${s.wire}'),
                      value: s,
                      title: Text(t.stateLabel(s)),
                      subtitle: Text(t.stateExplain(s)),
                      dense: true,
                    ),
                  RadioListTile<AdState?>(
                    key: const ValueKey('state-clear'),
                    value: null,
                    title: Text(t.clearState),
                    subtitle: Text(t.stateExplain(null)),
                    dense: true,
                  ),
                ],
              ),
            ),
            if (warnText != null)
              Container(
                key: const ValueKey('state-warning'),
                width: double.infinity,
                margin: const EdgeInsets.only(top: StudioSpacing.sm),
                padding: const EdgeInsets.all(StudioSpacing.md),
                decoration: BoxDecoration(
                  color: StudioColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(StudioRadii.sm),
                ),
                child: Text('$warnText ${t.tapAgainToSet}'),
              ),
            TextField(
              key: const ValueKey('state-note'),
              controller: _note,
              decoration: InputDecoration(hintText: t.setStateNoteHint),
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
          key: const ValueKey('state-save'),
          onPressed: !_touched
              ? null
              : () {
                  // A pick against the rule is allowed, but asks for a
                  // second tap so it is never done by accident.
                  if (warnText != null && !_warned) {
                    setState(() => _warned = true);
                    return;
                  }
                  Navigator.of(
                    context,
                  ).pop(_StatePick(_picked, _note.text.trim()));
                },
          child: Text(warnText != null && _warned ? t.setAnyway : m.save),
        ),
      ],
    );
  }
}

class _RoundEdit {
  const _RoundEdit(this.launchDate, this.title, this.note);

  final String launchDate;
  final String? title;
  final String? note;
}

class _EditRoundDialog extends StatefulWidget {
  const _EditRoundDialog({required this.round});

  final PaidRound round;

  @override
  State<_EditRoundDialog> createState() => _EditRoundDialogState();
}

class _EditRoundDialogState extends State<_EditRoundDialog> {
  late String _date = widget.round.launchDate;
  late final _title = TextEditingController(text: widget.round.title ?? '');
  late final _note = TextEditingController(text: widget.round.note ?? '');

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PaidStrings.of(context);
    final m = MoreStrings.of(context);
    return AlertDialog(
      key: const ValueKey('round-edit-dialog'),
      title: Text(t.editRound),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('round-title'),
              controller: _title,
              decoration: InputDecoration(labelText: t.roundTitleField),
            ),
            TextField(
              key: const ValueKey('round-note'),
              controller: _note,
              decoration: InputDecoration(labelText: t.roundNoteField),
            ),
            const SizedBox(height: StudioSpacing.md),
            OutlinedButton.icon(
              key: const ValueKey('round-date'),
              icon: const Icon(Icons.event),
              label: Text('${t.launchDate}: ${m.date(_date)}'),
              onPressed: () async {
                final parsed = DateTime.tryParse(_date) ?? DateTime.now();
                final picked = await showStudioDatePicker(
                  context: context,
                  initialDate: parsed,
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _date = isoDate(picked));
              },
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
          key: const ValueKey('round-save'),
          onPressed: () => Navigator.of(context).pop(
            _RoundEdit(
              _date,
              _title.text.trim().isEmpty ? null : _title.text.trim(),
              _note.text.trim().isEmpty ? null : _note.text.trim(),
            ),
          ),
          child: Text(m.save),
        ),
      ],
    );
  }
}
