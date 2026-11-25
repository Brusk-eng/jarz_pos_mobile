import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../shell/more_common.dart';
import '../../shell/more_strings.dart';
import '../settings_strings.dart';
import '../state/settings_state.dart';

/// A rule value with its unit: EGP as money, % as a percent, the rest as the
/// number and the unit.
String formatRuleValue(MoreStrings m, double v, String? unit) {
  if (unit == 'EGP') return m.egp(v);
  final s = v == v.roundToDouble()
      ? '${v.round()}'
      : v.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  if (unit == '%') return '$s%';
  return (unit == null || unit.isEmpty) ? s : '$s $unit';
}

String _ruleName(StudioRule r) =>
    r.meaning.isEmpty ? humanizeKey(r.key) : r.meaning;

/// The rules, each with its current value and the date it applies from.
class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final t = SettingsStrings.of(context);
    final m = MoreStrings.of(context);
    final value = ref.watch(rulesListProvider);

    return ViewEditScaffold(
      title: t.rulesTitle,
      parentRoute: '/more/settings',
      actions: [
        moreHelpAction(context, title: t.rulesHelpTitle, lines: t.rulesHelp),
      ],
      body: MoreBody(
        child: Column(
          children: [
            MoreSearchField(
              hint: t.rulesSearchHint,
              liveChange: true,
              onChanged: (q) => setState(() => _q = q.trim().toLowerCase()),
            ),
            Expanded(
              child: StudioAsyncView<List<StudioRule>>(
                value: value,
                onRetry: () => ref.invalidate(rulesListProvider),
                empty: StudioEmptyConfig(
                  purpose: t.rulesEmptyPurpose,
                  firstStep: t.rulesEmptyFirstStep,
                  icon: Icons.rule,
                ),
                builder: (context, rules) {
                  final shown = [
                    for (final r in rules)
                      if (_q.isEmpty ||
                          r.meaning.toLowerCase().contains(_q) ||
                          r.key.toLowerCase().contains(_q))
                        r,
                  ];
                  return ListView(
                    key: const ValueKey('rules-list'),
                    children: [
                      for (final r in shown)
                        MoreCard(
                          key: ValueKey('rule-${r.key}'),
                          onTap: () => context.go(
                            '/more/settings/rules/${Uri.encodeComponent(r.key)}',
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _ruleName(r),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    Text(
                                      r.valueSince == null
                                          ? t.startingValue
                                          : t.fromDate(m.date(r.valueSince)),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatRuleValue(m, r.value, r.unit),
                                key: ValueKey('rule-value-${r.key}'),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: StudioSpacing.xxl),
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

/// One rule: its value now, its starting value, the dated history, and (for
/// the founder) the "change from a date" form. History is never edited.
class RuleScreen extends ConsumerWidget {
  const RuleScreen({super.key, required this.ruleKey});

  final String ruleKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = SettingsStrings.of(context);
    final value = ref.watch(rulesListProvider);
    final rule = value.valueOrNull?.where((r) => r.key == ruleKey).firstOrNull;

    return ViewEditScaffold(
      title: rule == null ? t.ruleTitle : _ruleName(rule),
      parentRoute: '/more/settings/rules',
      onEdit: rule != null && rule.actions.contains('set')
          ? () => _change(context, ref, rule)
          : null,
      actions: [
        moreHelpAction(context, title: t.rulesHelpTitle, lines: t.rulesHelp),
      ],
      body: MoreBody(
        child: StudioAsyncView<List<StudioRule>>(
          value: value,
          onRetry: () => ref.invalidate(rulesListProvider),
          empty: StudioEmptyConfig(
            purpose: t.rulesEmptyPurpose,
            firstStep: t.rulesEmptyFirstStep,
          ),
          isEmpty: (rules) => !rules.any((r) => r.key == ruleKey),
          builder: (context, rules) {
            final r = rules.firstWhere((x) => x.key == ruleKey);
            return _RuleBody(
              rule: r,
              onChange: r.actions.contains('set')
                  ? () => _change(context, ref, r)
                  : null,
            );
          },
        ),
      ),
    );
  }

  Future<void> _change(
    BuildContext context,
    WidgetRef ref,
    StudioRule rule,
  ) async {
    final result =
        await showDialog<({double value, String from, String? note})>(
          context: context,
          builder: (_) => _ChangeDialog(rule: rule),
        );
    if (result == null || !context.mounted) return;
    final t = SettingsStrings.of(context);
    await runMoreWrite(
      context,
      () => ref
          .read(rulesListProvider.notifier)
          .change(rule.key, result.value, result.from, note: result.note),
      okText: t.ruleChanged,
    );
  }
}

class _RuleBody extends StatelessWidget {
  const _RuleBody({required this.rule, required this.onChange});

  final StudioRule rule;

  /// Opens the "change from a date" form; null when the person may not.
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final t = SettingsStrings.of(context);
    final m = MoreStrings.of(context);
    final theme = Theme.of(context);
    final history = [...rule.values]
      ..sort((a, b) => b.validFrom.compareTo(a.validFrom));

    return ListView(
      key: const ValueKey('rule-body'),
      padding: const EdgeInsets.only(bottom: StudioSpacing.xxl),
      children: [
        MoreCard(
          padding: const EdgeInsets.all(StudioSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.inForce, style: theme.textTheme.bodySmall),
              Text(
                formatRuleValue(m, rule.value, rule.unit),
                key: const ValueKey('rule-now'),
                style: theme.textTheme.headlineMedium,
              ),
              Text(
                rule.valueSince == null
                    ? t.startingValue
                    : t.fromDate(m.date(rule.valueSince)),
                style: theme.textTheme.bodySmall,
              ),
              if (rule.meaning.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: StudioSpacing.md),
                  child: Text(rule.meaning, style: theme.textTheme.bodyMedium),
                ),
              const Divider(),
              LabeledValue(
                t.startingValue,
                formatRuleValue(m, rule.defaultValue, rule.unit),
              ),
              if (rule.source != null && rule.source!.isNotEmpty)
                LabeledValue(t.sourceLabel, rule.source!),
            ],
          ),
        ),
        SectionLabel(t.history),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.gutter,
            ),
            child: Text(t.noHistory, style: theme.textTheme.bodySmall),
          )
        else
          for (final v in history)
            MoreCard(
              key: ValueKey('history-${v.validFrom}'),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.fromDate(m.date(v.validFrom)),
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (v.note != null && v.note!.isNotEmpty)
                          Text(v.note!, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (v.archived)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: StudioSpacing.sm,
                      ),
                      child: MorePill(t.replaced),
                    ),
                  Text(
                    formatRuleValue(m, v.value, rule.unit),
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ),
        Padding(
          padding: const EdgeInsets.all(StudioSpacing.gutter),
          child: Text(t.historyNeverEdited, style: theme.textTheme.bodySmall),
        ),
        if (onChange != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.gutter,
            ),
            child: FilledButton.tonal(
              key: const ValueKey('rule-change'),
              onPressed: onChange,
              child: Text(t.changeFromDate),
            ),
          ),
      ],
    );
  }
}

class _ChangeDialog extends StatefulWidget {
  const _ChangeDialog({required this.rule});

  final StudioRule rule;

  @override
  State<_ChangeDialog> createState() => _ChangeDialogState();
}

class _ChangeDialogState extends State<_ChangeDialog> {
  late final _value = TextEditingController();
  final _note = TextEditingController();
  String _from = todayIso();
  bool _bad = false;

  @override
  void dispose() {
    _value.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = SettingsStrings.of(context);
    final m = MoreStrings.of(context);
    return AlertDialog(
      key: const ValueKey('rule-dialog'),
      title: Text(t.changeTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${t.inForce}: ${formatRuleValue(m, widget.rule.value, widget.rule.unit)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextField(
              key: const ValueKey('rule-new-value'),
              controller: _value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
              ],
              decoration: InputDecoration(
                labelText: t.newValue,
                errorText: _bad ? t.valueNotANumber : null,
                suffixText: widget.rule.unit,
              ),
            ),
            const SizedBox(height: StudioSpacing.md),
            OutlinedButton.icon(
              key: const ValueKey('rule-from'),
              icon: const Icon(Icons.event),
              label: Text('${t.validFrom}: ${m.date(_from)}'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(_from) ?? DateTime.now(),
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2031),
                );
                if (picked != null) setState(() => _from = isoDate(picked));
              },
            ),
            TextField(
              key: const ValueKey('rule-note'),
              controller: _note,
              decoration: InputDecoration(labelText: t.noteOptional),
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
          key: const ValueKey('rule-save'),
          onPressed: () {
            final v = double.tryParse(_value.text.trim());
            if (v == null) {
              setState(() => _bad = true);
              return;
            }
            final note = _note.text.trim();
            Navigator.of(
              context,
            ).pop((value: v, from: _from, note: note.isEmpty ? null : note));
          },
          child: Text(m.save),
        ),
      ],
    );
  }
}
