import '../../../shared/person_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MaxLengthEnforcement;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/studio_error.dart';
import '../../inbox/presentation/inbox_strings.dart';
import '../../inbox/presentation/ui_helpers.dart';
import '../../inbox/state/inbox_state.dart';
import 'decisions_strings.dart';
import '../../../shared/studio_error_text.dart';

/// Sends the pick. [requestId] stays the same across retries of one pick.
typedef AnswerDecision =
    Future<void> Function(
      int? optionIndex,
      String? note,
      String requestId, {
      String? text,
    });

/// The longest answer in words the server keeps (contract `decisions.answer`).
const decisionTextMax = 2000;

/// One decision: the question, 2 to 4 options with pros, cons, main risk and
/// when each is right, the recommended one marked, the report link. The
/// confirm button exists only when the server lists `answer` in `actions`.
class DecisionCard extends ConsumerStatefulWidget {
  const DecisionCard({
    super.key,
    required this.decision,
    required this.onAnswer,
  });

  final StudioDecision decision;
  final AnswerDecision onAnswer;

  @override
  ConsumerState<DecisionCard> createState() => _DecisionCardState();
}

class _DecisionCardState extends ConsumerState<DecisionCard> {
  int? _selected;
  final _note = TextEditingController();
  final _text = TextEditingController();
  String? _textError;
  String _requestId = const Uuid().v4();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final pick = _selected;
    if (pick == null || _busy) return;
    final t = DecisionsStrings.of(context);
    setState(() => _busy = true);
    try {
      final note = _note.text.trim();
      await widget.onAnswer(pick, note.isEmpty ? null : note, _requestId);
      _requestId = const Uuid().v4();
      if (mounted) showStudioNote(context, t.saved);
    } catch (e) {
      if (mounted) showStudioError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _busy) return;
    final t = DecisionsStrings.of(context);
    setState(() {
      _busy = true;
      _textError = null;
    });
    try {
      await widget.onAnswer(null, null, _requestId, text: text);
      _requestId = const Uuid().v4();
      if (mounted) showStudioNote(context, t.answerSaved);
    } on StudioValidation catch (e) {
      // A server error on the answer box shows under it; any other field is
      // shown as the plain message.
      if (mounted) {
        if (e.field == 'text') {
          setState(() => _textError = e.message);
        } else {
          showStudioError(context, e);
        }
      }
    } catch (e) {
      if (mounted) showStudioError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _textBox(DecisionsStrings t) {
    final empty = _text.text.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const ValueKey('decision-text'),
          controller: _text,
          minLines: 4,
          maxLines: 8,
          maxLength: decisionTextMax,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          onChanged: (_) => setState(() => _textError = null),
          buildCounter:
              (
                context, {
                required currentLength,
                required isFocused,
                required maxLength,
              }) => Text(
                t.answerCount(currentLength, maxLength ?? decisionTextMax),
                key: const ValueKey('decision-text-count'),
              ),
          decoration: InputDecoration(
            labelText: t.answerLabel,
            hintText: t.answerHint,
            errorText: _textError,
          ),
        ),
        const SizedBox(height: StudioSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('decision-send'),
            onPressed: empty || _busy ? null : _send,
            child: Text(empty ? t.writeFirst : t.sendAnswer),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.decision;
    final inWords = d.answerKind == DecisionKind.text;
    final t = DecisionsStrings.of(context);
    final s = InboxStrings.of(context);
    final theme = Theme.of(context);
    final now = ref.watch(studioNowProvider)();
    final canAnswer =
        d.actions.contains('answer') && d.status == DecisionStatus.open;
    final answered = d.status == DecisionStatus.answered;

    return Card(
      key: ValueKey('decision-${d.id}'),
      child: Padding(
        padding: const EdgeInsets.all(StudioSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.question,
              key: const ValueKey('decision-question'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: StudioSpacing.xs),
            Text(
              [
                t.raisedBy(personName(d.raisedBy)),
                if (d.status == DecisionStatus.open)
                  t.waiting(waitedText(s, d.waitingSince, now)),
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            if (d.context != null && d.context!.isNotEmpty) ...[
              const SizedBox(height: StudioSpacing.md),
              Text(d.context!, style: theme.textTheme.bodyMedium),
            ],
            if (d.report != null) ...[
              const SizedBox(height: StudioSpacing.sm),
              TextButton.icon(
                key: const ValueKey('decision-report'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: AlignmentDirectional.centerStart,
                ),
                onPressed: () async {
                  final uri = Uri.tryParse(d.report!.url);
                  if (uri != null) {
                    try {
                      await launchUrl(uri);
                    } catch (_) {}
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text('${t.openReport}: ${d.report!.title}'),
              ),
            ],
            const SizedBox(height: StudioSpacing.md),
            for (final o in d.options)
              _OptionTile(
                option: o,
                selected: (answered ? d.pickedIndex : _selected) == o.index,
                selectable: canAnswer,
                picked: answered && d.pickedIndex == o.index,
                onTap: canAnswer
                    ? () => setState(() => _selected = o.index)
                    : null,
              ),
            const SizedBox(height: StudioSpacing.sm),
            if (canAnswer && inWords) ...[
              _textBox(t),
              const SizedBox(height: StudioSpacing.sm),
              NextStepLine(t.nextOpenFounderText),
            ] else if (canAnswer) ...[
              TextField(
                key: const ValueKey('decision-note'),
                controller: _note,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: t.noteLabel,
                  hintText: t.noteHint,
                ),
              ),
              const SizedBox(height: StudioSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('decision-confirm'),
                  onPressed: _selected == null || _busy ? null : _confirm,
                  child: Text(_selected == null ? t.pickFirst : t.confirmPick),
                ),
              ),
              const SizedBox(height: StudioSpacing.sm),
              NextStepLine(t.nextOpenFounder),
            ] else if (answered) ...[
              _answeredSummary(context, d, t),
              const SizedBox(height: StudioSpacing.sm),
              NextStepLine(inWords ? t.nextAnsweredText : t.nextAnswered),
            ] else if (d.status == DecisionStatus.open)
              NextStepLine(t.nextOpenOthers)
            else
              NextStepLine(
                d.status == DecisionStatus.superseded
                    ? t.superseded
                    : t.withdrawn,
              ),
          ],
        ),
      ),
    );
  }

  Widget _answeredSummary(
    BuildContext context,
    StudioDecision d,
    DecisionsStrings t,
  ) {
    final s = InboxStrings.of(context);
    final theme = Theme.of(context);
    final label = d.options
        .where((o) => o.index == d.pickedIndex)
        .map((o) => o.label)
        .firstOrNull;
    final who = d.answeredBy?.fullName;
    final inWords = d.answerKind == DecisionKind.text;
    return Container(
      key: const ValueKey('decision-answered'),
      width: double.infinity,
      padding: const EdgeInsets.all(StudioSpacing.md),
      decoration: BoxDecoration(
        color: StudioColors.blushPale,
        borderRadius: BorderRadius.circular(StudioRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inWords) ...[
            Text(t.yourAnswer, style: theme.textTheme.titleSmall),
            const SizedBox(height: StudioSpacing.xs),
            Text(
              d.answerText ?? '',
              key: const ValueKey('decision-answer-text'),
              style: theme.textTheme.bodyMedium,
            ),
          ] else
            Text(
              t.picked(label ?? '#${d.pickedIndex}'),
              style: theme.textTheme.titleSmall,
            ),
          if (who != null)
            Text(
              t.pickedBy(who, slotText(s, d.answeredAt)),
              style: theme.textTheme.bodySmall,
            ),
          if (d.pickNote != null && d.pickNote!.isNotEmpty) ...[
            const SizedBox(height: StudioSpacing.xs),
            Text(
              '${t.yourNote}: ${d.pickNote}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.selectable,
    required this.picked,
    required this.onTap,
  });

  final DecisionOption option;
  final bool selected;
  final bool selectable;
  final bool picked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = DecisionsStrings.of(context);
    final theme = Theme.of(context);
    final o = option;
    Widget line(String label, String? text) => text == null || text.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: StudioSpacing.xs),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: theme.textTheme.labelMedium,
                  ),
                  TextSpan(text: text, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          );
    final view = switch (o.raisedByView) {
      ViewBy.claude => t.raisedByClaude,
      ViewBy.neon => t.raisedByNeon,
      ViewBy.both => t.raisedByBoth,
      _ => null,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
      child: Material(
        color: selected ? StudioColors.blushPale : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudioRadii.md),
          side: BorderSide(
            color: selected ? StudioColors.berryPink : StudioColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          key: ValueKey('option-${o.index}'),
          borderRadius: BorderRadius.circular(StudioRadii.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(StudioSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectable || picked)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: StudioSpacing.sm,
                    ),
                    child: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: selected
                          ? StudioColors.berryPink
                          : StudioColors.plumMuted,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.label, style: theme.textTheme.titleSmall),
                      if (o.recommended || view != null)
                        Padding(
                          padding: const EdgeInsets.only(top: StudioSpacing.xs),
                          child: Wrap(
                            spacing: StudioSpacing.sm,
                            runSpacing: StudioSpacing.xs,
                            children: [
                              if (o.recommended)
                                Container(
                                  key: const ValueKey('recommended'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: StudioColors.softBlush,
                                    borderRadius: BorderRadius.circular(
                                      StudioRadii.pill,
                                    ),
                                  ),
                                  child: Text(
                                    t.recommended,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: StudioColors.deepPlum,
                                    ),
                                  ),
                                ),
                              if (view != null)
                                Text(view, style: theme.textTheme.labelSmall),
                            ],
                          ),
                        ),
                      line(t.pros, o.pros),
                      line(t.cons, o.cons),
                      line(t.mainRisk, o.mainRisk),
                      line(t.whenRight, o.whenRight),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
