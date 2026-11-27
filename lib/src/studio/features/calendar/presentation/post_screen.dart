import '../../../core/l10n/studio_labels.dart';
import '../../../shared/bidi_text.dart';
import '../../../shared/person_name.dart';
import '../../../shared/post_platforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../core/network/studio_api.dart';
import '../../../shared/how_this_works_sheet.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../pieces/pieces_strings.dart';
import '../../pieces/presentation/piece_widgets.dart';
import '../../results/presentation/piece_results_screen.dart' show ReadRow;
import '../../../shared/studio_tr.dart';
import '../calendar_strings.dart';
import '../data/calendar_repository.dart';
import '../state/cairo_format.dart';
import '../state/cairo_time.dart';
import 'calendar_widgets.dart';
import 'post_slot_form.dart';

/// One post (`/calendar/post/:id`): the creative, the caption, the channel and
/// slot, who posts it, its state, what happened, and the actions the server
/// lists for this person.
class PostScreen extends ConsumerStatefulWidget {
  const PostScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends ConsumerState<PostScreen> {
  bool _busy = false;

  PostNotifier get _notifier => ref.read(postProvider(widget.postId).notifier);

  Future<void> _run(Future<void> Function() op, {required String done}) async {
    final c = CalendarStrings.of(context);
    setState(() => _busy = true);
    try {
      await op();
      if (mounted) showSnack(context, done);
    } on StudioGateFailed catch (e) {
      if (!mounted) return;
      await showGateProblemsSheet(
        context,
        problems: e.problems,
        message: e.message,
      );
    } on StudioNotFound {
      if (mounted) {
        showSnack(context, c.gone);
        context.go('/calendar');
      }
    } on StudioNotPermitted catch (e) {
      // The actions were stale: say so and reload.
      if (mounted) showSnack(context, c.error(e));
      await _notifier.refresh();
    } catch (e) {
      if (mounted) showSnack(context, c.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markPosted() async {
    final c = CalendarStrings.of(context);
    final link = await askText(
      context,
      title: c.markPostedTitle,
      label: c.linkLabel,
      required: false,
    );
    if (link == null) return;
    await _run(
      () => _notifier.markPosted(
        link: link.isEmpty ? null : link,
        requestId: const Uuid().v4(),
      ),
      done: c.markedPosted,
    );
  }

  Future<void> _wontPost() async {
    final c = CalendarStrings.of(context);
    final reason = await askText(
      context,
      title: c.wontPostTitle,
      label: c.reasonLabel,
      requiredMessage: c.reasonNeeded,
    );
    if (reason == null) return;
    await _run(
      () => _notifier.wontPost(reason, requestId: const Uuid().v4()),
      done: c.markedWont,
    );
  }

  Future<void> _retry() async {
    final c = CalendarStrings.of(context);
    await _run(
      () => _notifier.retry(requestId: const Uuid().v4()),
      done: c.retrying,
    );
  }

  Future<void> _editCaption(SocialPost post) async {
    final c = CalendarStrings.of(context);
    final text = await askText(
      context,
      title: c.actionSetCaption,
      label: c.fieldCaption,
      initial: post.caption ?? '',
      maxLines: 10,
      required: false,
    );
    if (text == null) return;
    await _run(() async {
      await ref
          .read(calendarRepositoryProvider)
          .postSet(
            postId: post.id,
            caption: text,
            baseModified: post.modified,
            requestId: const Uuid().v4(),
          );
      await _notifier.refresh();
    }, done: c.savedCaption);
  }

  Future<void> _openSlot(SocialPost post, SlotFormMode mode) async {
    final saved = await showPostSlotForm(context, post: post, mode: mode);
    if (saved == true) await _notifier.refresh();
  }

  Future<void> _frame(SocialPost post, StoryFrame f, FrameStatus status) async {
    final c = CalendarStrings.of(context);
    String? reason;
    if (status == FrameStatus.skipped) {
      reason = await askText(
        context,
        title: c.actionFrameSkipped(f.position),
        label: c.reasonLabel,
        requiredMessage: c.reasonNeeded,
      );
      if (reason == null) return;
    }
    await _run(
      () => _notifier.frameSet(
        f.position,
        status.wire,
        reason: reason,
        requestId: const Uuid().v4(),
      ),
      done: c.frameSaved,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = CalendarStrings.of(context);
    final value = ref.watch(postProvider(widget.postId));
    final post = value.valueOrNull;

    return ViewEditScaffold(
      title: post?.title ?? c.postHelpTitle,
      parentRoute: '/calendar',
      onEdit: post != null && post.actions.contains('edit')
          ? () => _openSlot(post, SlotFormMode.edit)
          : null,
      actions: [
        IconButton(
          key: const ValueKey('help'),
          tooltip: PiecesStrings.of(
            context,
          ).tr('How this works', 'الشاشة دي بتشتغل إزاي'),
          icon: const Icon(Icons.help_outline),
          onPressed: () => HowThisWorksSheet.show(
            context,
            title: c.postHelpTitle,
            lines: c.postHelp,
          ),
        ),
      ],
      body: StudioAsyncView<SocialPost>(
        value: value,
        onRetry: () => _notifier.refresh(),
        isEmpty: (_) => false,
        empty: StudioEmptyConfig(
          purpose: c.emptyPostPurpose,
          firstStep: c.emptyPostFirst,
        ),
        builder: (context, p) => RefreshIndicator(
          onRefresh: _notifier.refresh,
          child: ListView(
            key: const ValueKey('post-body'),
            padding: const EdgeInsets.all(StudioSpacing.gutter),
            children: [
              _Creative(post: p),
              if (p.frames.isNotEmpty)
                _Frames(
                  post: p,
                  busy: _busy,
                  onFrame: (f, s) => _frame(p, f, s),
                ),
              _Links(post: p),
              _CaptionBlock(
                post: p,
                busy: _busy,
                onEdit: () => _editCaption(p),
              ),
              _SlotBlock(
                post: p,
                busy: _busy,
                onMove: () => _openSlot(p, SlotFormMode.move),
              ),
              _Approval(post: p),
              _Checks(post: p),
              _Log(post: p),
              _PostResults(post: p),
              if (p.actions.contains('mark_posted')) _HandPost(post: p),
              _Actions(
                post: p,
                busy: _busy,
                onMarkPosted: _markPosted,
                onWontPost: _wontPost,
                onRetry: _retry,
              ),
              const SizedBox(height: StudioSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- sections

class _Creative extends StatelessWidget {
  const _Creative({required this.post});
  final SocialPost post;

  @override
  Widget build(BuildContext context) {
    final c = CalendarStrings.of(context);
    final media = post.files.isNotEmpty ? post.files : [?post.thumb];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(c.sectionCreative),
        SizedBox(
          height: 220,
          child: media.isEmpty
              ? const StudioThumb(media: null, width: 160, height: 220)
              : ListView(
                  key: const ValueKey('post-creative'),
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final (i, m) in media.indexed)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: StudioSpacing.sm,
                        ),
                        child: Semantics(
                          button: true,
                          label: media.length == 1
                              ? context.tr(
                                  'Preview the creative',
                                  'شوف الصورة أو الفيديو',
                                )
                              : context.tr(
                                  'Preview creative ${i + 1} of ${media.length}',
                                  'شوف ${i + 1} من ${media.length}',
                                ),
                          child: InkWell(
                            key: ValueKey('creative-$i'),
                            onTap: () => openStudioMediaViewer(
                              context,
                              items: media,
                              initialIndex: i,
                            ),
                            child: StudioThumb(
                              media: m,
                              width: 165,
                              height: 220,
                              radius: BorderRadius.circular(StudioRadii.md),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Frames extends StatelessWidget {
  const _Frames({
    required this.post,
    required this.busy,
    required this.onFrame,
  });

  final SocialPost post;
  final bool busy;
  final void Function(StoryFrame frame, FrameStatus status) onFrame;

  @override
  Widget build(BuildContext context) {
    final c = CalendarStrings.of(context);
    final canSet = post.actions.contains('frame_set');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(c.sectionFrames),
        Padding(
          padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
          child: Text(
            key: const ValueKey('frames-progress'),
            c.framesDecided(
              post.frames
                  .where(
                    (f) =>
                        f.status == FrameStatus.posted ||
                        f.status == FrameStatus.skipped,
                  )
                  .length,
              post.frames.length,
            ),
            style: StudioTextStyles.caption,
          ),
        ),
        if (post.frames.every(
          (f) =>
              f.status == FrameStatus.posted || f.status == FrameStatus.skipped,
        ))
          Padding(
            padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
            child: Text(
              c.framesAllDecided,
              key: const ValueKey('frames-all-decided'),
              style: StudioTextStyles.caption,
            ),
          ),
        if (canSet)
          Padding(
            padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
            child: Text(
              c.framesAutoPosted,
              key: const ValueKey('frames-auto-posted'),
              style: StudioTextStyles.caption,
            ),
          ),
        for (final f in post.frames)
          Card(
            margin: const EdgeInsets.only(bottom: StudioSpacing.sm),
            child: Padding(
              padding: const EdgeInsets.all(StudioSpacing.md),
              child: Row(
                key: ValueKey('frame-${f.position}'),
                children: [
                  StudioThumb(
                    media: f.asset.media,
                    width: 44,
                    height: 70,
                    radius: BorderRadius.circular(StudioRadii.sm),
                  ),
                  const SizedBox(width: StudioSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${f.position}. ${f.asset.title}'),
                        if (f.status == FrameStatus.posted)
                          Text(c.frameDone, style: StudioTextStyles.caption),
                        if (f.status == FrameStatus.skipped)
                          Text(
                            [
                              c.frameSkipped,
                              if (f.reason != null) f.reason!,
                            ].join(': '),
                            style: StudioTextStyles.caption,
                          ),
                        if (canSet)
                          Wrap(
                            spacing: StudioSpacing.sm,
                            children: [
                              Semantics(
                                container: true,
                                button: true,
                                label: c.actionFramePosted(f.position),
                                excludeSemantics: true,
                                onTap: busy
                                    ? null
                                    : () => onFrame(f, FrameStatus.posted),
                                child: TextButton(
                                  key: ValueKey('frame-posted-${f.position}'),
                                  onPressed: busy
                                      ? null
                                      : () => onFrame(f, FrameStatus.posted),
                                  child: Text(c.frameShortPosted(f.position)),
                                ),
                              ),
                              TextButton(
                                key: ValueKey('frame-skip-${f.position}'),
                                onPressed: busy
                                    ? null
                                    : () => onFrame(f, FrameStatus.skipped),
                                child: Text(c.actionFrameSkipped(f.position)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Links extends StatelessWidget {
  const _Links({required this.post});
  final SocialPost post;

  @override
  Widget build(BuildContext context) {
    final c = CalendarStrings.of(context);
    if (post.piece == null && post.versionId == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: StudioSpacing.sm),
      child: Wrap(
        spacing: StudioSpacing.sm,
        children: [
          if (post.piece != null)
            TextButton.icon(
              key: const ValueKey('open-piece'),
              icon: const Icon(Icons.article_outlined),
              onPressed: () => context.push('/pieces/${post.piece!.id}'),
              label: Text(c.openPiece),
            ),
          if (post.versionId != null)
            TextButton.icon(
              key: const ValueKey('open-version'),
              icon: const Icon(Icons.layers_outlined),
              onPressed: () => context.push('/versions/${post.versionId}'),
              label: Text(c.openVersion),
            ),
        ],
      ),
    );
  }
}

bool _hasArabic(String s) => RegExp(r'[؀-ۿ]').hasMatch(s);

/// The caption, each line in its own direction: an Arabic line reads right to
/// left, the hashtag line under it left to right, so `#Jarz #JarzEgypt` does
/// not come out reversed.
class _CaptionText extends StatelessWidget {
  const _CaptionText(this.caption);
  final String caption;

  TextDirection _dir(String line) =>
      _hasArabic(line) ? TextDirection.rtl : TextDirection.ltr;

  @override
  Widget build(BuildContext context) {
    final lines = caption.split('\n');
    if (lines.length == 1) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          caption,
          key: const ValueKey('post-caption'),
          textDirection: _dir(caption),
        ),
      );
    }
    return Column(
      key: const ValueKey('post-caption'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, line) in lines.indexed)
          Text(
            line.isEmpty ? ' ' : line,
            key: ValueKey('post-caption-line-$i'),
            textDirection: _dir(line),
          ),
      ],
    );
  }
}

class _CaptionBlock extends StatelessWidget {
  const _CaptionBlock({
    required this.post,
    required this.busy,
    required this.onEdit,
  });

  final SocialPost post;
  final bool busy;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = CalendarStrings.of(context);
    final caption = post.caption ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(c.sectionCaption),
        if (caption.isEmpty)
          Text(c.noCaption, style: Theme.of(context).textTheme.bodySmall)
        else
          // Arabic first: the caption is shown in its own direction.
          _CaptionText(caption),
        if (post.captionProblems.isNotEmpty) ...[
          const SizedBox(height: StudioSpacing.sm),
          ProblemChecklist(problems: post.captionProblems),
        ],
        if (post.actions.contains('set_caption'))
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('set-caption'),
              icon: const Icon(Icons.edit_outlined),
              onPressed: busy ? null : onEdit,
              label: Text(c.actionSetCaption),
            ),
          ),
      ],
    );
  }
}

class _SlotBlock extends StatelessWidget {
  const _SlotBlock({
    required this.post,
    required this.busy,
    required this.onMove,
  });

  final SocialPost post;
  final bool busy;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    final c = CalendarStrings.of(context);
    final names = c.names;
    final ar = isArabic(context);
    final who = post.assignee != null
        ? post.assignee!.fullName
        : (post.postingMode == PostingMode.bySystem
              ? c.whoSystem
              : (post.assigneeTeam != null &&
                    post.assigneeTeam != OwnerTeam.unknown)
              ? names.team(post.assigneeTeam!)
              : names.nobodyYet);

    Widget row(IconData icon, String text, {Key? key}) => Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: StudioColors.plumMuted),
          const SizedBox(width: StudioSpacing.sm),
          Expanded(child: Text(text, key: key)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(c.sectionSlot),
        Row(
          children: [
            PostStatusChip(status: post.status),
            if (platformsOf(post.platforms).isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: StudioSpacing.sm,
                ),
                child: PlatformMarks(
                  platforms: post.platforms,
                  status: post.platformStatus,
                  ar: ar,
                ),
              ),
            if (post.waitsOn != null && post.waitsOn!.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: StudioSpacing.sm,
                  ),
                  child: Text(
                    names.waitingOn(personName(post.waitsOn)),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: StudioColors.warning,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: StudioSpacing.md),
        row(
          channelIcon(post.channel),
          post.channel == null
              ? ''
              : names.channel(post.channel!) +
                    (hasTikTokPart(post.platforms) &&
                            post.channel != PostChannel.tikTok
                        ? ' + TikTok'
                        : ''),
          key: const ValueKey('post-channel'),
        ),
        row(
          Icons.schedule,
          post.slotTime == null
              ? c.noTime
              : '${CairoFormat.full(CairoTime.parse(post.slotTime)!, ar)}, ${CairoTime.time(CairoTime.parse(post.slotTime)!)}',
          key: const ValueKey('post-slot'),
        ),
        row(
          Icons.person_outline,
          c.whoPostsLine(post.postingMode == PostingMode.byHand, who),
          key: const ValueKey('post-who'),
        ),
        if (post.actions.contains('move'))
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              key: const ValueKey('post-move'),
              icon: const Icon(Icons.open_with),
              onPressed: busy ? null : onMove,
              label: Text(c.actionMove),
            ),
          ),
      ],
    );
  }
}

class _Approval extends StatelessWidget {
  const _Approval({required this.post});
  final SocialPost post;

  @override
  Widget build(BuildContext context) {
    final c = CalendarStrings.of(context);
    final outcome = post.version?.reviewOutcome;
    final (icon, text, color) = post.versionId == null
        ? (Icons.help_outline, c.approvalNone, StudioColors.plumMuted)
        : outcome == ReviewOutcome.approved
        ? (Icons.check_circle_outline, c.approvalOk, StudioColors.success)
        : outcome == ReviewOutcome.fix
        ? (Icons.error_outline, c.approvalFix, StudioColors.danger)
        : (Icons.hourglass_empty, c.approvalWaiting, StudioColors.warning);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(c.sectionApproval),
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: StudioSpacing.sm),
            Text(text, key: const ValueKey('post-approval')),
          ],
        ),
      ],
    );
  }
}

class _Checks extends StatelessWidget {
  const _Checks({required this.post});
  final SocialPost post;

  @override
  Widget build(BuildContext context) {
    final c = CalendarStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(c.sectionChecks),
        if (post.checks.isEmpty)
          Text(c.noChecks, style: Theme.of(context).textTheme.bodySmall),
        for (final k in post.checks)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              k.severity == CheckSeverity.block
                  ? Icons.error_outline
                  : Icons.warning_amber_outlined,
              color: k.severity == CheckSeverity.block
                  ? StudioColors.danger
                  : StudioColors.warning,
            ),
            title: Text(
              StudioLabels.of(context).problem(k.code, message: k.message),
            ),
            subtitle: Text(
              k.severity == CheckSeverity.block ? c.blockLevel : c.warnLevel,
            ),
          ),
      ],
    );
  }
}

/// "What happened": the publish log, in order, as plain lines.
class _Log extends StatelessWidget {
  const _Log({required this.post});
  final SocialPost post;

  @override
  Widget build(BuildContext context) {
    final c = CalendarStrings.of(context);
    final ar = isArabic(context);
    final lines = <String>[
      if (post.postedAt != null)
        c.postedAt(CairoFormat.stamp(post.postedAt, ar)),
      if (post.postedHow != null)
        c.postedHow(switch (post.postedHow!) {
          PostedHow.system => c.postedBySystem,
          PostedHow.hand => c.postedByHand,
          PostedHow.matched => c.postedMatched,
          PostedHow.unknown => '',
        }, post.postedBy == null ? c.whoSystem : personName(post.postedBy)),
      if (post.lastError != null && post.lastError!.isNotEmpty)
        c.lastError(post.lastError!),
      if (post.skipReason != null && post.skipReason!.isNotEmpty)
        c.skipReason(post.skipReason!),
      if (post.note != null && post.note!.isNotEmpty) post.note!,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(c.sectionLog),
        if (lines.isEmpty)
          Text(c.noLog, style: Theme.of(context).textTheme.bodySmall),
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6, right: 8, left: 8),
                  child: Icon(Icons.circle, size: 6),
                ),
                Expanded(child: Text(l)),
              ],
            ),
          ),
        if (post.permalink != null && post.permalink!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: StudioSpacing.xs),
            child: SelectableText(
              '${c.permalink}: ${post.permalink}',
              key: const ValueKey('post-permalink'),
            ),
          ),
      ],
    );
  }
}

class _PostResults extends StatelessWidget {
  const _PostResults({required this.post});
  final SocialPost post;

  @override
  Widget build(BuildContext context) {
    final c = CalendarStrings.of(context);
    final s = c.names;
    final filed = post.reads.where((r) => r.filed).toList();
    // The reads still to file (the 72-hour one above all): due ones get the
    // button, the others say when they open.
    final open = post.reads.where((r) => !r.filed).toList();
    if (filed.isEmpty && open.isEmpty) return const SizedBox.shrink();
    String n(int? v) => v == null ? '–' : '$v';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(c.sectionResults),
        for (final r in open)
          Card(
            key: ValueKey('post-read-open-${r.bucket.wire}'),
            margin: const EdgeInsets.only(bottom: StudioSpacing.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: StudioSpacing.md,
                vertical: StudioSpacing.xs,
              ),
              child: ReadRow(read: r),
            ),
          ),
        for (final r in filed)
          Card(
            margin: const EdgeInsets.only(bottom: StudioSpacing.sm),
            child: Padding(
              padding: const EdgeInsets.all(StudioSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.readBucket(r.bucket),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: StudioSpacing.xs),
                  Wrap(
                    spacing: StudioSpacing.lg,
                    children: [
                      Text('${s.readReach}: ${n(r.reach)}'),
                      Text('${s.readViews}: ${n(r.views)}'),
                      Text('${s.readShares}: ${n(r.shares)}'),
                      Text('${s.readSaves}: ${n(r.saves)}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.post,
    required this.busy,
    required this.onMarkPosted,
    required this.onWontPost,
    required this.onRetry,
  });

  final SocialPost post;
  final bool busy;
  final VoidCallback onMarkPosted;
  final VoidCallback onWontPost;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = CalendarStrings.of(context);
    final a = post.actions;
    final buttons = <Widget>[
      if (a.contains('mark_posted'))
        FilledButton.icon(
          key: const ValueKey('mark-posted'),
          icon: const Icon(Icons.check),
          onPressed: busy ? null : onMarkPosted,
          label: Text(c.actionMarkPosted),
        ),
      if (a.contains('retry'))
        FilledButton.icon(
          key: const ValueKey('retry'),
          icon: const Icon(Icons.refresh),
          onPressed: busy ? null : onRetry,
          label: Text(c.actionRetry),
        ),
      if (a.contains('wont_post'))
        OutlinedButton.icon(
          key: const ValueKey('wont-post'),
          icon: const Icon(Icons.block),
          onPressed: busy ? null : onWontPost,
          label: Text(c.actionWontPost),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: StudioSpacing.xl),
      child: Wrap(
        key: const ValueKey('post-actions'),
        spacing: StudioSpacing.sm,
        runSpacing: StudioSpacing.sm,
        children: buttons,
      ),
    );
  }
}

/// What the hand-poster needs before "Mark posted": the files to save (one tap
/// each, or all at once) and the caption to copy. Works on web (the signed link
/// opens in a new tab) and on Android (the browser downloads it).
class _HandPost extends ConsumerStatefulWidget {
  const _HandPost({required this.post});
  final SocialPost post;

  @override
  ConsumerState<_HandPost> createState() => _HandPostState();
}

class _HandPostState extends ConsumerState<_HandPost> {
  bool _busy = false;

  List<StudioMedia> get _files => widget.post.files.isNotEmpty
      ? widget.post.files
      : [for (final f in widget.post.frames) ?f.asset.media];

  Future<bool> _save(StudioMedia m) async {
    try {
      final link = await ref
          .read(studioApiProvider)
          .mediaDownloadLink(mediaId: m.id);
      return await ref.read(studioLinkOpenerProvider)(Uri.parse(link.url));
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveOne(StudioMedia m) async {
    final c = CalendarStrings.of(context);
    setState(() => _busy = true);
    final ok = await _save(m);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) showSnack(context, c.saveFailed);
  }

  Future<void> _saveAll() async {
    final c = CalendarStrings.of(context);
    setState(() => _busy = true);
    var allOk = true;
    for (final m in _files) {
      allOk = await _save(m) && allOk;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (!allOk) showSnack(context, c.saveFailed);
  }

  Future<void> _copy() async {
    final c = CalendarStrings.of(context);
    final text = widget.post.caption ?? '';
    if (text.trim().isEmpty) {
      showSnack(context, c.nothingToCopy);
      return;
    }
    await Clipboard.setData(ClipboardData(text: withoutBidiIsolates(text)));
    if (mounted) showSnack(context, c.captionCopied);
  }

  @override
  Widget build(BuildContext context) {
    final c = CalendarStrings.of(context);
    final files = _files;
    return Column(
      key: const ValueKey('hand-post'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(c.handPostTitle),
        Text(c.handPostSteps, style: StudioTextStyles.caption),
        const SizedBox(height: StudioSpacing.sm),
        if (files.isEmpty)
          Text(c.noFilesYet, style: Theme.of(context).textTheme.bodySmall),
        Wrap(
          spacing: StudioSpacing.sm,
          runSpacing: StudioSpacing.sm,
          children: [
            for (final (i, m) in files.indexed)
              OutlinedButton.icon(
                key: ValueKey('save-file-$i'),
                icon: const Icon(Icons.download),
                onPressed: _busy ? null : () => _saveOne(m),
                label: Text(c.saveFile(i + 1, m.kind == MediaKind.video)),
              ),
            if (files.length > 1)
              FilledButton.tonalIcon(
                key: const ValueKey('save-all'),
                icon: const Icon(Icons.download_for_offline_outlined),
                onPressed: _busy ? null : _saveAll,
                label: Text(c.saveAll),
              ),
            OutlinedButton.icon(
              key: const ValueKey('copy-caption'),
              icon: const Icon(Icons.copy),
              onPressed: _copy,
              label: Text(c.copyCaption),
            ),
          ],
        ),
      ],
    );
  }
}
