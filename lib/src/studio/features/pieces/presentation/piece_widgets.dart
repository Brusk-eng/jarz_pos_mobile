import '../../../core/l10n/studio_labels.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/theme/studio_status_colors.dart' as theme;
import '../../../core/theme/studio_theme.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../../shared/stage_chip.dart';
import '../../calendar/state/cairo_format.dart';
import '../../calendar/state/cairo_time.dart';
import '../pieces_strings.dart';
import '../../../shared/studio_toast.dart';

bool isArabic(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar';

/// The stage chip of the shared kit takes the theme's own stage enum.
theme.PieceStage themeStage(PieceStage s) => switch (s) {
  PieceStage.idea => theme.PieceStage.idea,
  PieceStage.script => theme.PieceStage.script,
  PieceStage.toShoot => theme.PieceStage.toShoot,
  PieceStage.toEdit => theme.PieceStage.toEdit,
  PieceStage.inReview => theme.PieceStage.inReview,
  PieceStage.approved => theme.PieceStage.approved,
  PieceStage.scheduled => theme.PieceStage.scheduled,
  PieceStage.posted => theme.PieceStage.posted,
  PieceStage.read => theme.PieceStage.read,
  PieceStage.unknown => theme.PieceStage.idea,
};

Widget stageChipFor(PieceStage s) => StageChip(stage: themeStage(s));

/// The stage's name in the person's language.
String stageName(BuildContext context, PieceStage s) =>
    StudioStrings.of(context).stage(themeStage(s).apiName);

/// Title in the person's language when there is one.
String pieceTitle(BuildContext context, PieceSummary p) =>
    pieceTitleText(context, p.title, p.titleAr);

String pieceTitleText(BuildContext context, String title, String? titleAr) =>
    isArabic(context) && (titleAr?.isNotEmpty ?? false) ? titleAr! : title;

String ownerText(BuildContext context, PieceSummary p) {
  final s = PiecesStrings.of(context);
  if (p.assignee != null) return p.assignee!.fullName;
  if (p.assigneeTeam != null && p.assigneeTeam != OwnerTeam.unknown) {
    return s.team(p.assigneeTeam!);
  }
  return s.nobodyYet;
}

/// What a piece is waiting on, in a few words, or null.
String? waitingText(BuildContext context, PieceSummary p) {
  final s = PiecesStrings.of(context);
  if (p.parked != null) return s.parkedWhy(p.parked!);
  if (p.blocked != null) return s.waitingOn(p.blocked!.reason);
  return null;
}

/// One piece as a card: picture, title, stage, owner, due date and what it
/// waits on. Tapping opens the piece.
class PieceCard extends StatelessWidget {
  const PieceCard({super.key, required this.piece, this.onTap});

  final PieceSummary piece;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final s = PiecesStrings.of(context);
    final ar = isArabic(context);
    final waiting = waitingText(context, piece);
    final due = CairoTime.parse(piece.dueDate);
    return Card(
      margin: const EdgeInsets.only(bottom: StudioSpacing.sm),
      child: InkWell(
        key: ValueKey('piece-card-${piece.id}'),
        borderRadius: BorderRadius.circular(StudioRadii.md),
        onTap: onTap ?? () => context.push('/pieces/${piece.id}'),
        child: Padding(
          padding: const EdgeInsets.all(StudioSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudioThumb(
                media: piece.picture ?? piece.currentVersion?.thumb,
                width: 56,
                height: 70,
                radius: BorderRadius.circular(StudioRadii.sm),
              ),
              const SizedBox(width: StudioSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pieceTitle(context, piece),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: StudioSpacing.xs),
                    Wrap(
                      spacing: StudioSpacing.sm,
                      runSpacing: StudioSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        stageChipFor(piece.stage),
                        Text(
                          piece.legacyId ?? piece.id,
                          style: StudioTextStyles.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: StudioSpacing.xs),
                    Text(
                      [
                        ownerText(context, piece),
                        if (due != null) s.dueOn(CairoFormat.dayMonth(due, ar)),
                      ].join(' · '),
                      style: textTheme.bodySmall,
                    ),
                    if (waiting != null)
                      Padding(
                        padding: const EdgeInsets.only(top: StudioSpacing.xs),
                        child: Text(
                          waiting,
                          key: ValueKey('piece-waiting-${piece.id}'),
                          style: textTheme.bodySmall?.copyWith(
                            color: StudioColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A short title above a block.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: StudioSpacing.lg,
      bottom: StudioSpacing.sm,
    ),
    child: Text(text.toUpperCase(), style: StudioTextStyles.sectionLabel),
  );
}

/// A checklist of problems from a refused move or write, in plain words.
/// [fixFor] may give a way to the place that fixes one problem.
class ProblemChecklist extends StatelessWidget {
  const ProblemChecklist({
    super.key,
    required this.problems,
    this.fixFor,
    this.fixLabel,
  });

  final List<StudioProblem> problems;
  final VoidCallback? Function(StudioProblem problem)? fixFor;
  final String? fixLabel;

  @override
  Widget build(BuildContext context) {
    final label = fixLabel ?? PiecesStrings.of(context).gateFix;
    return Column(
      key: const ValueKey('problem-checklist'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in problems)
          Padding(
            padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_box_outline_blank,
                    size: 18,
                    color: StudioColors.warning,
                  ),
                ),
                const SizedBox(width: StudioSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        StudioLabels.of(
                          context,
                        ).problem(p.code, message: p.message),
                      ),
                      if (fixFor?.call(p) case final VoidCallback go)
                        TextButton(
                          key: ValueKey('problem-fix-${p.code}'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            alignment: AlignmentDirectional.centerStart,
                          ),
                          onPressed: go,
                          child: Text(label),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The sheet that explains a refused move: what to fix first.
Future<void> showGateProblemsSheet(
  BuildContext context, {
  required List<StudioProblem> problems,
  String? message,
  VoidCallback? Function(StudioProblem problem)? fixFor,
}) {
  final s = PiecesStrings.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        key: const ValueKey('gate-sheet'),
        padding: const EdgeInsets.fromLTRB(
          StudioSpacing.gutter,
          0,
          StudioSpacing.gutter,
          StudioSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.gateTitle, style: Theme.of(sheet).textTheme.titleMedium),
            const SizedBox(height: StudioSpacing.sm),
            if (problems.isEmpty && message != null)
              Text(message)
            else ...[
              Text(s.gateIntro),
              const SizedBox(height: StudioSpacing.md),
              ProblemChecklist(
                problems: problems,
                fixFor: fixFor == null
                    ? null
                    : (p) {
                        final go = fixFor(p);
                        if (go == null) return null;
                        return () {
                          Navigator.of(sheet).pop();
                          go();
                        };
                      },
              ),
            ],
            const SizedBox(height: StudioSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => Navigator.of(sheet).pop(),
                child: Text(s.close),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Asks for a line of text (a reason, a link). Null when cancelled.
Future<String?> askText(
  BuildContext context, {
  required String title,
  required String label,
  String? explain,
  bool required = true,
  String? requiredMessage,
  String confirmLabel = '',
  String cancelLabel = '',
  String initial = '',
  int maxLines = 4,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _AskTextDialog(
      title: title,
      label: label,
      explain: explain,
      required: required,
      requiredMessage: requiredMessage,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      initial: initial,
      maxLines: maxLines,
    ),
  );
}

class _AskTextDialog extends StatefulWidget {
  const _AskTextDialog({
    required this.title,
    required this.label,
    required this.explain,
    required this.required,
    required this.requiredMessage,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.initial,
    required this.maxLines,
  });

  final String title;
  final String label;
  final String? explain;
  final bool required;
  final String? requiredMessage;
  final String confirmLabel;
  final String cancelLabel;
  final String initial;
  final int maxLines;

  @override
  State<_AskTextDialog> createState() => _AskTextDialogState();
}

class _AskTextDialogState extends State<_AskTextDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = PiecesStrings.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.explain != null) ...[
            Text(widget.explain!),
            const SizedBox(height: StudioSpacing.md),
          ],
          TextField(
            key: const ValueKey('ask-text'),
            controller: _controller,
            autofocus: true,
            minLines: 1,
            maxLines: widget.maxLines,
            decoration: InputDecoration(
              labelText: widget.label,
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('ask-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            widget.cancelLabel.isEmpty ? s.cancel : widget.cancelLabel,
          ),
        ),
        FilledButton(
          key: const ValueKey('ask-confirm'),
          onPressed: () {
            final v = _controller.text.trim();
            if (widget.required && v.isEmpty) {
              setState(() => _error = widget.requiredMessage ?? s.reasonNeeded);
              return;
            }
            Navigator.of(context).pop(v);
          },
          child: Text(
            widget.confirmLabel.isEmpty ? s.confirm : widget.confirmLabel,
          ),
        ),
      ],
    );
  }
}

void showSnack(BuildContext context, String text) => showStudioToast(text);
