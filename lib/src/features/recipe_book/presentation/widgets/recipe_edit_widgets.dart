import 'package:flutter/material.dart';

import '../../../../core/localization/user_error_message.dart';
import '../../domain/recipe_edit_logic.dart';
import '../../domain/recipe_scaling.dart';
import '../recipe_book_strings.dart';

/// The server's own sentence for [error] (they are written to be read), else
/// the app's generic wording.
String recipeErrorText(BuildContext context, Object? error) {
  final raw = error?.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  final text = raw?.trim() ?? '';
  final unsafe =
      text.isEmpty ||
      text.length > 400 ||
      text.contains('<') ||
      text.contains('Traceback');
  return unsafe ? context.userErrorMessage(error) : text;
}

/// "Discard your changes?"; true when the user chooses to leave.
Future<bool> confirmDiscardChanges(BuildContext context) async {
  final s = RecipeBookStrings.of(context);
  final leave = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.discardTitle),
      content: Text(s.discardBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(s.keepEditing),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(s.discard),
        ),
      ],
    ),
  );
  return leave ?? false;
}

/// What the save sheet answers.
class SaveSheetResult {
  const SaveSheetResult({this.summary = '', this.stage = RecipeStage.trial});

  final String summary;
  final String stage;
}

/// The sheet shown before a save that creates a version: "What changed?"
/// (when [askSummary]) and a Trial / Approved choice (when [askStage]).
Future<SaveSheetResult?> showSaveSheet(
  BuildContext context, {
  required String confirmLabel,
  bool askSummary = true,
  bool askStage = true,
  String initialStage = RecipeStage.trial,
  String? approvedHint,
  String? note,
}) {
  return showModalBottomSheet<SaveSheetResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SaveSheet(
      confirmLabel: confirmLabel,
      askSummary: askSummary,
      askStage: askStage,
      initialStage: initialStage,
      approvedHint: approvedHint,
      note: note,
    ),
  );
}

class _SaveSheet extends StatefulWidget {
  const _SaveSheet({
    required this.confirmLabel,
    required this.askSummary,
    required this.askStage,
    required this.initialStage,
    this.approvedHint,
    this.note,
  });

  final String confirmLabel;
  final bool askSummary;
  final bool askStage;
  final String initialStage;
  final String? approvedHint;
  final String? note;

  @override
  State<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<_SaveSheet> {
  final _summary = TextEditingController();
  late String _stage = widget.initialStage;
  bool _missing = false;

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _summary.text.trim();
    if (widget.askSummary && text.isEmpty) {
      setState(() => _missing = true);
      return;
    }
    Navigator.of(context).pop(SaveSheetResult(summary: text, stage: _stage));
  }

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final theme = Theme.of(context);
    final quiet = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.askSummary) ...[
              Text(s.whatChangedQ, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('save-summary'),
                controller: _summary,
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: s.whatChangedHint,
                  errorText: _missing ? s.whatChangedRequired : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_missing) setState(() => _missing = false);
                },
              ),
              const SizedBox(height: 16),
            ],
            if (widget.askStage) ...[
              Text(s.saveStageTitle, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                key: const ValueKey('save-stage'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: RecipeStage.trial,
                    label: Text(s.stageTrial),
                  ),
                  ButtonSegment(
                    value: RecipeStage.approved,
                    label: Text(s.stageApproved),
                  ),
                ],
                selected: {_stage},
                onSelectionChanged: (v) => setState(() => _stage = v.first),
              ),
              const SizedBox(height: 6),
              Text(
                _stage == RecipeStage.approved
                    ? (widget.approvedHint ?? '')
                    : s.stageTrialHint,
                style: quiet,
              ),
              const SizedBox(height: 16),
            ],
            if (widget.note != null) ...[
              Text(widget.note!, style: quiet),
              const SizedBox(height: 12),
            ],
            FilledButton(
              key: const ValueKey('save-sheet-confirm'),
              onPressed: _submit,
              child: Text(widget.confirmLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Picks an ingredient (with "per jar" and "×n" options) and answers the
/// placeholder text to insert, e.g. `[Flour ×2]`; null when dismissed.
Future<String?> showInsertAmountSheet(
  BuildContext context, {
  required List<String> names,
  bool offerPerJar = true,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _InsertAmountSheet(names: names, offerPerJar: offerPerJar),
  );
}

class _InsertAmountSheet extends StatefulWidget {
  const _InsertAmountSheet({required this.names, required this.offerPerJar});

  final List<String> names;
  final bool offerPerJar;

  @override
  State<_InsertAmountSheet> createState() => _InsertAmountSheetState();
}

class _InsertAmountSheetState extends State<_InsertAmountSheet> {
  final _times = TextEditingController();
  bool _each = false;

  @override
  void dispose() {
    _times.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height * 0.75),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(s.pickIngredient, style: theme.textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (widget.offerPerJar) ...[
                    FilterChip(
                      key: const ValueKey('insert-each'),
                      label: Text(s.perJarOption),
                      selected: _each,
                      onSelected: (v) => setState(() => _each = v),
                    ),
                    const SizedBox(width: 12),
                  ],
                  SizedBox(
                    width: 110,
                    child: TextField(
                      key: const ValueKey('insert-times'),
                      controller: _times,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: '× ${s.timesOption}',
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: widget.names.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(s.noIngredientsToInsert),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final name in widget.names)
                          ListTile(
                            title: Text(name),
                            onTap: () => Navigator.of(context).pop(
                              placeholderFor(
                                name,
                                each: _each,
                                times: parseAmount(_times.text),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A section title in the editors, with an optional trailing widget.
class EditorSectionTitle extends StatelessWidget {
  const EditorSectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
