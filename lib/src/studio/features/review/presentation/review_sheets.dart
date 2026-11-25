import 'package:flutter/material.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../review_strings.dart';

/// The 1 to 5 choice: five big buttons with their plain labels.
class ScorePicker extends StatelessWidget {
  const ScorePicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.compact = false,
    this.dark = false,
    this.enabled = true,
  });

  final int? selected;
  final ValueChanged<int> onSelected;
  final bool compact;

  /// White text for use on top of a video.
  final bool dark;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = ReviewStrings.of(context);
    return Row(
      children: [
        for (var s = 1; s <= 5; s++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Semantics(
                button: true,
                selected: selected == s,
                label: '$s, ${t.scoreLabel(s)}',
                child: InkWell(
                  key: ValueKey('score-$s'),
                  borderRadius: BorderRadius.circular(StudioRadii.sm),
                  onTap: enabled ? () => onSelected(s) : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: compact ? 8 : 10,
                      horizontal: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected == s
                          ? StudioColors.berryPink
                          : (dark ? const Color(0x33FFFFFF) : Colors.white),
                      border: Border.all(
                        color: selected == s
                            ? StudioColors.berryPink
                            : (dark ? Colors.white54 : StudioColors.border),
                      ),
                      borderRadius: BorderRadius.circular(StudioRadii.sm),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$s',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: selected == s || dark
                                ? Colors.white
                                : StudioColors.deepPlum,
                          ),
                        ),
                        Text(
                          t.scoreLabel(s),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: selected == s || dark
                                ? Colors.white
                                : StudioColors.plumMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A sheet that grows with the keyboard.
Future<T?> _sheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            StudioSpacing.gutter,
            0,
            StudioSpacing.gutter,
            StudioSpacing.lg,
          ),
          child: builder(ctx),
        ),
      ),
    ),
  );
}

class RateResult {
  const RateResult(this.score, this.comment);
  final int score;
  final String? comment;
}

/// Rate a version: pick 1 to 5, say why if you want, save. Starts from my
/// current rating so it can be changed.
Future<RateResult?> showRateSheet(BuildContext context, PieceVersion v) {
  return _sheet<RateResult>(context, (ctx) => _RateSheet(version: v));
}

class _RateSheet extends StatefulWidget {
  const _RateSheet({required this.version});
  final PieceVersion version;

  @override
  State<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<_RateSheet> {
  late int? _score = widget.version.myRating?.score;
  late final TextEditingController _comment = TextEditingController(
    text: widget.version.myRating?.comment ?? '',
  );

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ReviewStrings.of(context);
    final prompt = widget.version.ratePrompt;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.rateSheetTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (prompt != null && prompt.isNotEmpty) ...[
          const SizedBox(height: StudioSpacing.xs),
          Text(prompt, key: const ValueKey('rate-prompt')),
        ],
        const SizedBox(height: StudioSpacing.lg),
        ScorePicker(
          selected: _score,
          onSelected: (s) => setState(() => _score = s),
        ),
        const SizedBox(height: StudioSpacing.lg),
        TextField(
          key: const ValueKey('rate-comment'),
          controller: _comment,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(hintText: t.rateCommentHint),
        ),
        const SizedBox(height: StudioSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.cancel),
              ),
            ),
            const SizedBox(width: StudioSpacing.md),
            Expanded(
              child: FilledButton(
                key: const ValueKey('rate-save'),
                onPressed: _score == null
                    ? null
                    : () {
                        final c = _comment.text.trim();
                        Navigator.of(
                          context,
                        ).pop(RateResult(_score!, c.isEmpty ? null : c));
                      },
                child: Text(t.save),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CommentResultInput {
  const CommentResultInput(this.body, this.frame);
  final String body;
  final int? frame;
}

/// Write a comment. A story offers "whole version" or one of its frames.
Future<CommentResultInput?> showCommentSheet(
  BuildContext context,
  PieceVersion v, {
  int? initialFrame,
}) {
  return _sheet<CommentResultInput>(
    context,
    (ctx) => _CommentSheet(version: v, initialFrame: initialFrame),
  );
}

class _CommentSheet extends StatefulWidget {
  const _CommentSheet({required this.version, this.initialFrame});
  final PieceVersion version;
  final int? initialFrame;

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final TextEditingController _body = TextEditingController();
  late int? _frame = widget.initialFrame;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ReviewStrings.of(context);
    final frames = [...widget.version.frames]
      ..sort((a, b) => a.position - b.position);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.commentSheetTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (frames.isNotEmpty) ...[
          const SizedBox(height: StudioSpacing.md),
          Text(
            t.commentForFrame,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: StudioSpacing.sm),
          Wrap(
            spacing: StudioSpacing.sm,
            runSpacing: StudioSpacing.sm,
            children: [
              ChoiceChip(
                key: const ValueKey('comment-frame-none'),
                label: Text(t.wholeVersion),
                selected: _frame == null,
                onSelected: (_) => setState(() => _frame = null),
              ),
              for (final f in frames)
                ChoiceChip(
                  key: ValueKey('comment-frame-pick-${f.position}'),
                  label: Text(t.frameLabel(f.position)),
                  selected: _frame == f.position,
                  onSelected: (_) => setState(() => _frame = f.position),
                ),
            ],
          ),
        ],
        const SizedBox(height: StudioSpacing.md),
        TextField(
          key: const ValueKey('comment-body'),
          controller: _body,
          minLines: 3,
          maxLines: 6,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: t.commentHint),
        ),
        const SizedBox(height: StudioSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.cancel),
              ),
            ),
            const SizedBox(width: StudioSpacing.md),
            Expanded(
              child: FilledButton(
                key: const ValueKey('comment-send'),
                onPressed: _body.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(
                        context,
                      ).pop(CommentResultInput(_body.text.trim(), _frame)),
                child: Text(t.send),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Ask why a version goes back. The reason is required.
Future<String?> showSendBackSheet(BuildContext context) {
  return _sheet<String>(context, (ctx) => const _SendBackSheet());
}

class _SendBackSheet extends StatefulWidget {
  const _SendBackSheet();

  @override
  State<_SendBackSheet> createState() => _SendBackSheetState();
}

class _SendBackSheetState extends State<_SendBackSheet> {
  final TextEditingController _reason = TextEditingController();
  bool _tried = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ReviewStrings.of(context);
    final missing = _tried && _reason.text.trim().isEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.sendBackTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: StudioSpacing.md),
        TextField(
          key: const ValueKey('send-back-reason'),
          controller: _reason,
          minLines: 3,
          maxLines: 6,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: t.sendBackHint,
            errorText: missing ? t.sendBackReasonRequired : null,
          ),
        ),
        const SizedBox(height: StudioSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.cancel),
              ),
            ),
            const SizedBox(width: StudioSpacing.md),
            Expanded(
              child: FilledButton(
                key: const ValueKey('send-back-confirm'),
                onPressed: () {
                  final r = _reason.text.trim();
                  if (r.isEmpty) {
                    setState(() => _tried = true);
                    return;
                  }
                  Navigator.of(context).pop(r);
                },
                child: Text(t.sendBackConfirm),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One confirm tap before approving.
Future<bool> confirmApprove(BuildContext context, PieceVersion v) async {
  final t = ReviewStrings.of(context);
  final slot = v.post?.slotTime;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const ValueKey('approve-dialog'),
      title: Text(t.confirmApproveTitle),
      content: Text(t.confirmApproveBody(slot == null ? null : t.when(slot))),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(t.cancel),
        ),
        FilledButton(
          key: const ValueKey('approve-confirm'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(t.confirmApprove),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Plain helper: the piece title for messages.
String versionLabel(PieceVersion v) => v.title ?? v.piece.title;
