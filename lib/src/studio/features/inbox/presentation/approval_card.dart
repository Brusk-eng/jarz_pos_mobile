import '../../../shared/layout/studio_layout.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/studio_status_colors.dart' show Verdict;
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/media/studio_media_viewer.dart';
import '../../../shared/media/studio_thumb.dart';
import '../../../shared/person_text.dart';
import '../../../shared/verdict_badge.dart';
import '../../../shared/post_platforms.dart';
import '../state/approvals_logic.dart';
import 'approvals_strings.dart';

/// Which of the card's actions are offered.
enum ApprovalCardMode {
  /// Waiting for the yes: Approve, Send back, Change time.
  waiting,

  /// Approved: the sentence of what happens next, Change time, Undo approval.
  approved,
}

/// One piece for the founder to decide on: everything he needs to say yes,
/// without opening anything.
class ApprovalCard extends StatefulWidget {
  const ApprovalCard({
    super.key,
    required this.card,
    required this.now,
    required this.mode,
    this.busy = false,
    this.onApprove,
    this.onSendBack,
    this.onChangeTime,
    this.onUndo,
    this.onOpenDetails,
  });

  final ApproveCard card;
  final DateTime now;
  final ApprovalCardMode mode;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onSendBack;
  final VoidCallback? onChangeTime;
  final VoidCallback? onUndo;
  final VoidCallback? onOpenDetails;

  @override
  State<ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<ApprovalCard> {
  bool _captionOpen = false;

  @override
  Widget build(BuildContext context) {
    final s = ApprovalsStrings.of(context);
    final theme = Theme.of(context);
    final c = widget.card;
    final piece = c.piece;
    final post = primaryPost(c);
    final slot = approvalSlot(c);
    final who = whoPosts(post);
    final overdue = slot != null && slot.isBefore(widget.now);
    final medias = [for (final f in c.version.files) f.media];
    final media = medias.isNotEmpty ? medias.first : piece.picture;
    final title = (s.ar && (piece.titleAr ?? '').trim().isNotEmpty)
        ? piece.titleAr!
        : piece.title;
    final reason = verdictReason(c);
    final failed = failedGateLines(c);
    final approved = widget.mode == ApprovalCardMode.approved;

    return Card(
      key: ValueKey('approve-${c.version.id}'),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(StudioSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bigThumb(context, s, media, medias),
                const SizedBox(width: StudioSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (c.needsHardYes == true || c.ranAsTrial == true) ...[
                        Wrap(
                          spacing: StudioSpacing.xs,
                          runSpacing: StudioSpacing.xs,
                          children: [
                            if (c.needsHardYes == true)
                              _Badge(
                                key: const ValueKey('badge-hard-yes'),
                                text: c.hardYesReason == 'launch'
                                    ? s.badgeHardYesLaunch
                                    : s.badgeHardYesPrice,
                                color: StudioColors.berryPink,
                              ),
                            if (c.ranAsTrial == true)
                              _Badge(
                                key: const ValueKey('badge-trial'),
                                text: s.badgeTrial,
                                color: StudioColors.jarzGold,
                              ),
                          ],
                        ),
                        const SizedBox(height: StudioSpacing.xs),
                      ],
                      PersonText(
                        title,
                        key: const ValueKey('card-title'),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        piece.id,
                        key: const ValueKey('card-id'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: StudioColors.plumMuted,
                        ),
                      ),
                      const SizedBox(height: StudioSpacing.xs),
                      Text(
                        channelWords(
                          post?.channel,
                          piece.format,
                          ar: s.ar,
                          platforms: post?.platforms,
                        ),
                        key: const ValueKey('card-channel'),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: StudioSpacing.xs),
                      Text(
                        slot == null ? s.noSlot : s.when(slot),
                        key: const ValueKey('card-when'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: overdue ? StudioColors.danger : null,
                        ),
                      ),
                      if (slot != null)
                        Text(
                          s.countdown(spanTo(slot, widget.now)),
                          key: const ValueKey('card-countdown'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: overdue
                                ? StudioColors.danger
                                : StudioColors.plumMuted,
                          ),
                        ),
                      const SizedBox(height: StudioSpacing.xs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            who.byHand
                                ? Icons.front_hand_outlined
                                : Icons.schedule_send_outlined,
                            size: 16,
                            color: StudioColors.plumMuted,
                          ),
                          const SizedBox(width: StudioSpacing.xs),
                          Expanded(
                            child: PersonText(
                              who.byHand
                                  ? s.postsByHand(who.name)
                                  : s.postsByItself,
                              key: const ValueKey('card-who'),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: StudioSpacing.md),
            _caption(context, s, c.caption),
            const SizedBox(height: StudioSpacing.md),
            _verdict(context, s, c, reason),
            if (failed.isNotEmpty) ...[
              const SizedBox(height: StudioSpacing.sm),
              _failedChecks(context, s, failed),
            ],
            if (approved) ...[
              const SizedBox(height: StudioSpacing.md),
              _approvedNote(context, s, post, slot, who),
            ],
            const SizedBox(height: StudioSpacing.md),
            _actions(context, s, approved, slot),
          ],
        ),
      ),
    );
  }

  Widget _bigThumb(
    BuildContext context,
    ApprovalsStrings s,
    StudioMedia? media,
    List<StudioMedia> all,
  ) {
    final canOpen = all.isNotEmpty;
    return Semantics(
      button: canOpen,
      label: s.openMedia,
      child: InkWell(
        key: const ValueKey('card-thumb'),
        borderRadius: BorderRadius.circular(StudioRadii.md),
        onTap: canOpen
            ? () => openStudioMediaViewer(context, items: all)
            : null,
        child: Stack(
          children: [
            StudioThumb(
              media: media,
              width: context.isWideScreen ? 160 : 128,
              height: context.isWideScreen ? 220 : 176,
              radius: BorderRadius.circular(StudioRadii.md),
            ),
            if (all.length > 1)
              PositionedDirectional(
                top: StudioSpacing.xs,
                end: StudioSpacing.xs,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xB3000000),
                    borderRadius: BorderRadius.circular(StudioRadii.pill),
                  ),
                  child: Text(
                    s.filesCount(all.length),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _caption(BuildContext context, ApprovalsStrings s, String? caption) {
    final theme = Theme.of(context);
    final text = (caption ?? '').trim();
    final long = text.length > 140 || '\n'.allMatches(text).length >= 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.captionTitle,
          style: theme.textTheme.labelMedium?.copyWith(
            color: StudioColors.plumMuted,
          ),
        ),
        const SizedBox(height: StudioSpacing.xs),
        if (text.isEmpty)
          Text(
            s.noCaption,
            key: const ValueKey('card-caption'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: StudioColors.plumMuted,
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(StudioSpacing.sm),
            decoration: BoxDecoration(
              color: StudioColors.blushPale,
              borderRadius: BorderRadius.circular(StudioRadii.sm),
              border: Border.all(color: StudioColors.border),
            ),
            child: PersonText(
              text,
              key: const ValueKey('card-caption'),
              maxLines: (_captionOpen || !long) ? null : 4,
              overflow: (_captionOpen || !long)
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        if (long)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const ValueKey('card-caption-toggle'),
              onPressed: () => setState(() => _captionOpen = !_captionOpen),
              child: Text(_captionOpen ? s.showLess : s.showAll),
            ),
          ),
      ],
    );
  }

  Widget _verdict(
    BuildContext context,
    ApprovalsStrings s,
    ApproveCard c,
    String? reason,
  ) {
    final theme = Theme.of(context);
    final v = c.version.verdict;
    final brief = c.piece.verdict;
    final label = v?.verdict ?? brief?.label;
    final mapped = switch (label) {
      VerdictLabel.rUN => Verdict.run,
      VerdictLabel.fIX => Verdict.fix,
      VerdictLabel.dROP => Verdict.drop,
      _ => null,
    };
    final stale = v?.stale ?? brief?.stale ?? false;
    final sell = v?.sell ?? brief?.sell;
    return Column(
      key: const ValueKey('card-verdict'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.sellJudge,
          style: theme.textTheme.labelMedium?.copyWith(
            color: StudioColors.plumMuted,
          ),
        ),
        const SizedBox(height: StudioSpacing.xs),
        if (label == null)
          Text(s.notJudged, style: theme.textTheme.bodyMedium)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mapped != null)
                VerdictBadge(verdict: mapped)
              else
                Text(
                  label == VerdictLabel.bLOCKED ? 'BLOCKED' : '-',
                  style: theme.textTheme.labelMedium,
                ),
              if (sell != null) ...[
                const SizedBox(width: StudioSpacing.sm),
                Text(
                  sell.toStringAsFixed(1),
                  style: theme.textTheme.labelMedium,
                ),
              ],
              const SizedBox(width: StudioSpacing.sm),
              Expanded(
                child: PersonText(
                  reason ?? '',
                  key: const ValueKey('card-verdict-reason'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        if (stale)
          Text(
            s.judgeStale,
            style: theme.textTheme.bodySmall?.copyWith(
              color: StudioColors.warning,
            ),
          ),
      ],
    );
  }

  Widget _failedChecks(
    BuildContext context,
    ApprovalsStrings s,
    List<String> lines,
  ) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('card-failed-checks'),
      width: double.infinity,
      padding: const EdgeInsets.all(StudioSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0x14C0392B),
        borderRadius: BorderRadius.circular(StudioRadii.sm),
        border: Border.all(color: StudioColors.danger),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.failedChecks,
            style: theme.textTheme.labelMedium?.copyWith(
              color: StudioColors.danger,
            ),
          ),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.close, size: 14, color: StudioColors.danger),
                  const SizedBox(width: StudioSpacing.xs),
                  Expanded(
                    child: PersonText(l, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _approvedNote(
    BuildContext context,
    ApprovalsStrings s,
    PostSummary? post,
    DateTime? slot,
    ({bool byHand, String? name}) who,
  ) {
    final platform = platformsWords(post?.channel, post?.platforms, ar: s.ar);
    final tikTokByHand =
        !who.byHand &&
        hasTikTokPart(post?.platforms) &&
        platformState(post?.platformStatus, platformTikTok) == 'by hand';
    final text = slot == null
        ? s.approvedNoSlot
        : tikTokByHand
        ? s.approvedTikTokByHand(post?.assignee?.fullName, s.when(slot))
        : who.byHand
        ? s.approvedByHand(who.name, s.when(slot), platform)
        : s.approvedByItself(s.when(slot), platform);
    return Container(
      key: const ValueKey('card-approved-note'),
      width: double.infinity,
      padding: const EdgeInsets.all(StudioSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0x143F8F6B),
        borderRadius: BorderRadius.circular(StudioRadii.sm),
        border: Border.all(color: StudioColors.success),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 18, color: StudioColors.success),
          const SizedBox(width: StudioSpacing.sm),
          Expanded(
            child: PersonText(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(
    BuildContext context,
    ApprovalsStrings s,
    bool approved,
    DateTime? slot,
  ) {
    final busy = widget.busy;
    final changeTime = OutlinedButton.icon(
      key: const ValueKey('card-change-time'),
      onPressed: busy ? null : widget.onChangeTime,
      icon: const Icon(Icons.schedule, size: 18),
      label: Text(s.changeTime),
    );
    final details = TextButton(
      key: ValueKey('approve-details-${widget.card.version.id}'),
      onPressed: widget.onOpenDetails,
      child: Text(s.openDetails),
    );
    if (approved) {
      final canUndo = canUndoApproval(widget.card, widget.now);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: StudioSpacing.sm,
            runSpacing: StudioSpacing.sm,
            children: [
              FilledButton.icon(
                key: const ValueKey('card-undo'),
                onPressed: (busy || !canUndo) ? null : widget.onUndo,
                icon: const Icon(Icons.undo, size: 18),
                label: Text(s.undoApproval),
              ),
              changeTime,
            ],
          ),
          if (!canUndo)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.xs),
              child: Text(
                s.undoTooLate,
                key: const ValueKey('undo-too-late'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: StudioColors.warning),
              ),
            ),
          Align(alignment: AlignmentDirectional.centerStart, child: details),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton(
                key: const ValueKey('card-approve'),
                onPressed: busy ? null : widget.onApprove,
                child: Text(s.approve),
              ),
            ),
            const SizedBox(width: StudioSpacing.sm),
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('card-send-back'),
                onPressed: busy ? null : widget.onSendBack,
                child: Text(s.sendBack),
              ),
            ),
          ],
        ),
        const SizedBox(height: StudioSpacing.sm),
        Wrap(
          spacing: StudioSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [changeTime, details],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(StudioRadii.pill),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: StudioColors.deepPlum,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
