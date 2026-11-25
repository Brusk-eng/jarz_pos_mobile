import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/how_this_works_sheet.dart';
import '../../../shared/stage_chip.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../data/review_repository.dart';
import '../review_strings.dart';
import '../state/action_outcome.dart';
import '../state/version_review_state.dart';
import 'review_helpers.dart';
import 'review_sheets.dart';
import 'version_media_view.dart';
import 'version_sections.dart';
import '../../../core/l10n/studio_strings.dart';

/// One version of a piece: its media, the sell judge's verdict, ratings,
/// comments and the buttons the server allows (`actions`). Used for
/// `/versions/:id` and `/inbox/approve/:id`.
class VersionScreen extends ConsumerStatefulWidget {
  const VersionScreen({
    super.key,
    required this.versionId,
    this.parentRoute = '/inbox/approve',
  });

  final String versionId;

  /// Where the back arrow goes when the page was opened by a link.
  final String parentRoute;

  @override
  ConsumerState<VersionScreen> createState() => _VersionScreenState();
}

class _Notice {
  const _Notice(this.text, {required this.ok, this.showBack = false});
  final String text;
  final bool ok;
  final bool showBack;
}

class _VersionScreenState extends ConsumerState<VersionScreen> {
  _Notice? _notice;
  bool _busy = false;
  int? _frame;

  VersionActions get _actions =>
      ref.read(versionActionsProvider(widget.versionId));

  PieceVersion? get _current =>
      ref.read(versionProvider(widget.versionId)).valueOrNull;

  Future<void> _run(
    Future<ActionOutcome> Function() call,
    String Function(ReviewStrings t, PieceVersion fresh) okText, {
    bool showBack = false,
  }) async {
    setState(() {
      _busy = true;
      _notice = null;
    });
    final outcome = await call();
    if (!mounted) return;
    final t = ReviewStrings.of(context);
    setState(() => _busy = false);
    if (outcome.ok) {
      final fresh = _current;
      setState(
        () => _notice = _Notice(
          fresh == null ? t.commentAdded : okText(t, fresh),
          ok: true,
          showBack: showBack,
        ),
      );
      return;
    }
    if (outcome.failure == ActionFailure.gateFailed) {
      setState(() => _notice = null);
      await showGateProblems(context, t, outcome.problems);
      return;
    }
    setState(() => _notice = _Notice(failureText(context, outcome), ok: false));
  }

  Future<void> _approve(PieceVersion v) async {
    if (!await confirmApprove(context, v)) return;
    await _run(_actions.approve, (t, fresh) {
      final slot = fresh.post?.slotTime;
      return slot == null ? t.approvedNoSlot : t.approvedPosts(t.when(slot));
    }, showBack: true);
  }

  Future<void> _sendBack() async {
    final reason = await showSendBackSheet(context);
    if (reason == null) return;
    await _run(() => _actions.sendBack(reason), (t, fresh) {
      final name = fresh.createdBy?.fullName;
      return name == null ? t.sentBackToCreator : t.sentBackTo(name);
    }, showBack: true);
  }

  Future<void> _clear() =>
      _run(_actions.clearDecision, (t, _) => t.decisionCleared);

  Future<void> _rate(PieceVersion v) async {
    final r = await showRateSheet(context, v);
    if (r == null) return;
    await _run(
      () => _actions.rate(r.score, comment: r.comment),
      (t, _) => t.ratedSaved(r.score, scoreText(t, r.score)),
    );
  }

  Future<void> _comment(PieceVersion v) async {
    final c = await showCommentSheet(context, v, initialFrame: _frame);
    if (c == null) return;
    await _run(
      () => _actions.comment(c.body, frame: c.frame),
      (t, _) => t.commentAdded,
    );
  }

  void _help(ReviewStrings t) => HowThisWorksSheet.show(
    context,
    title: t.versionHelpTitle,
    lines: t.versionHelp,
  );

  void _back() {
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      Navigator.of(context).maybePop();
    } else if (router.canPop()) {
      router.pop();
    } else {
      router.go(widget.parentRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ReviewStrings.of(context);
    final value = ref.watch(versionProvider(widget.versionId));
    return ViewEditScaffold(
      title: t.versionTitle,
      parentRoute: widget.parentRoute,
      actions: [
        IconButton(
          key: const ValueKey('review-help'),
          tooltip: t.versionHelpTitle,
          icon: const Icon(Icons.help_outline),
          onPressed: () => _help(t),
        ),
      ],
      body: StudioAsyncView<PieceVersion>(
        value: value,
        isEmpty: (_) => false,
        empty: StudioEmptyConfig(purpose: t.noMedia, firstStep: t.noMedia),
        onRetry: () => ref.invalidate(versionProvider(widget.versionId)),
        builder: (context, v) => Column(
          children: [
            if (_notice != null)
              _NoticeBar(
                notice: _notice!,
                backLabel: t.backToList,
                onBack: _back,
                onClose: () => setState(() => _notice = null),
              ),
            Expanded(child: _content(context, t, v)),
            _ActionBar(
              version: v,
              busy: _busy,
              onApprove: () => _approve(v),
              onSendBack: _sendBack,
              onClear: _clear,
              onRate: () => _rate(v),
              onComment: () => _comment(v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ReviewStrings t, PieceVersion v) {
    final media = VersionMediaView(
      version: v,
      selectedFrame: _frame,
      onFrameSelected: (p) => setState(() => _frame = p),
    );
    final details = <Widget>[
      _Header(version: v),
      const SizedBox(height: StudioSpacing.lg),
      VerdictSection(version: v),
      const SizedBox(height: StudioSpacing.lg),
      RatingsSection(version: v),
      const SizedBox(height: StudioSpacing.lg),
      CommentsSection(version: v),
      const SizedBox(height: StudioSpacing.xl),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(StudioSpacing.lg),
                  child: media,
                ),
              ),
              Expanded(
                child: ListView(
                  key: const ValueKey('version-details'),
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    StudioSpacing.lg,
                    StudioSpacing.lg,
                    0,
                  ),
                  children: details,
                ),
              ),
            ],
          );
        }
        return ListView(
          key: const ValueKey('version-details'),
          padding: const EdgeInsets.all(StudioSpacing.gutter),
          children: [
            media,
            const SizedBox(height: StudioSpacing.lg),
            ...details,
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.version});
  final PieceVersion version;

  @override
  Widget build(BuildContext context) {
    final t = ReviewStrings.of(context);
    final theme = Theme.of(context);
    final v = version;
    final stage = uiStage(v.piece.stage);
    final slot = v.post?.slotTime;
    final status = switch (v.reviewOutcome) {
      ReviewOutcome.approved =>
        v.reviewedBy == null
            ? t.approvedPlain
            : t.approvedBy(v.reviewedBy!.fullName),
      ReviewOutcome.fix =>
        (v.reviewReason ?? '').isEmpty
            ? t.sentBackPlain
            : t.sentBackWith(v.reviewReason!),
      _ => v.awaitingReview ? t.waitingForApproval : null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          v.piece.title,
          key: const ValueKey('piece-title'),
          style: theme.textTheme.headlineSmall,
        ),
        if (v.title != null && v.title != v.piece.title)
          Padding(
            padding: const EdgeInsets.only(top: StudioSpacing.xs),
            child: Text(v.title!, style: theme.textTheme.bodyMedium),
          ),
        const SizedBox(height: StudioSpacing.md),
        Wrap(
          spacing: StudioSpacing.sm,
          runSpacing: StudioSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (stage != null) StageChip(stage: stage),
            Text(
              '${t.versionNo(v.versionNo)} · ${v.isCurrent ? t.currentVersion : t.olderVersion}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        if (status != null) ...[
          const SizedBox(height: StudioSpacing.sm),
          Text(
            status,
            key: const ValueKey('review-status'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: StudioSpacing.xs),
        Text(
          slot == null
              ? t.noSlotYet
              : t.postsOn(t.when(slot), channelLabel(v.post?.channel)),
          key: const ValueKey('post-slot'),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _NoticeBar extends StatelessWidget {
  const _NoticeBar({
    required this.notice,
    required this.backLabel,
    required this.onBack,
    required this.onClose,
  });

  final _Notice notice;
  final String backLabel;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ok = notice.ok;
    return Container(
      key: ValueKey(ok ? 'notice-ok' : 'notice-error'),
      width: double.infinity,
      color: ok ? const Color(0xFFD7EFE2) : const Color(0xFFFBE3E0),
      padding: const EdgeInsets.symmetric(
        horizontal: StudioSpacing.gutter,
        vertical: StudioSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.error_outline,
            color: ok ? StudioColors.success : StudioColors.danger,
          ),
          const SizedBox(width: StudioSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.text,
                  key: const ValueKey('notice-text'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (notice.showBack)
                  TextButton(
                    key: const ValueKey('notice-back'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                    ),
                    onPressed: onBack,
                    child: Text(backLabel),
                  ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('notice-close'),
            tooltip: StudioStrings.of(context).dismiss,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// The buttons. Each one shows only when the server listed its action on the
/// version; the client holds no role logic.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.version,
    required this.busy,
    required this.onApprove,
    required this.onSendBack,
    required this.onClear,
    required this.onRate,
    required this.onComment,
  });

  final PieceVersion version;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onSendBack;
  final VoidCallback onClear;
  final VoidCallback onRate;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final t = ReviewStrings.of(context);
    final v = version;
    final buttons = <Widget>[
      if (can(v, 'approve'))
        FilledButton.icon(
          key: const ValueKey('action-approve'),
          onPressed: busy ? null : onApprove,
          icon: const Icon(Icons.check),
          label: Text(t.approve),
        ),
      if (can(v, 'fix'))
        OutlinedButton.icon(
          key: const ValueKey('action-fix'),
          onPressed: busy ? null : onSendBack,
          icon: const Icon(Icons.undo),
          label: Text(t.sendBack),
        ),
      if (can(v, 'clear_review'))
        OutlinedButton.icon(
          key: const ValueKey('action-clear'),
          onPressed: busy ? null : onClear,
          icon: const Icon(Icons.restart_alt),
          label: Text(t.clearDecision),
        ),
      if (can(v, 'rate'))
        OutlinedButton.icon(
          key: const ValueKey('action-rate'),
          onPressed: busy ? null : onRate,
          icon: const Icon(Icons.star_outline),
          label: Text(v.myRating == null ? t.rate : t.changeRating),
        ),
      if (can(v, 'comment'))
        OutlinedButton.icon(
          key: const ValueKey('action-comment'),
          onPressed: busy ? null : onComment,
          icon: const Icon(Icons.chat_bubble_outline),
          label: Text(t.comment),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: StudioColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: StudioSpacing.gutter,
            vertical: StudioSpacing.md,
          ),
          child: Wrap(
            key: const ValueKey('action-bar'),
            spacing: StudioSpacing.sm,
            runSpacing: StudioSpacing.sm,
            children: buttons,
          ),
        ),
      ),
    );
  }
}
