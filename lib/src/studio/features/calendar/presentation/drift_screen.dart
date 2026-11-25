import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/person_text.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/studio_labels.dart';
import '../../../core/roles/studio_role.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../pieces/presentation/piece_widgets.dart';
import '../../session/state/studio_session_notifier.dart';
import '../calendar_strings.dart';
import '../data/calendar_repository.dart';
import '../state/cairo_format.dart';
import 'calendar_widgets.dart';
import 'post_slot_form.dart';

/// `/calendar/drift`: the posts that did not go out and the posts that went
/// out without a plan, each with the actions the server allows for it. The
/// buttons of a missing post come from that post's own `actions`; matching or
/// ignoring a live post is the founder's and the marketing lead's.
class DriftScreen extends ConsumerWidget {
  const DriftScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = CalendarStrings.of(context);
    final value = ref.watch(postDriftProvider);
    return ViewEditScaffold(
      title: c.driftTitle,
      parentRoute: '/calendar',
      body: StudioAsyncView<PostDrift>(
        value: value,
        onRetry: () => ref.invalidate(postDriftProvider),
        empty: StudioEmptyConfig(
          purpose: c.driftEmptyPurpose,
          firstStep: c.driftEmptyFirst,
          icon: Icons.verified_outlined,
        ),
        isEmpty: (d) =>
            d.missing.isEmpty && d.unplanned.isEmpty && d.lateValue.isEmpty,
        builder: (context, d) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(postDriftProvider);
            await ref.read(postDriftProvider.future);
          },
          child: ListView(
            key: const ValueKey('drift-body'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(StudioSpacing.gutter),
            children: [
              Text(c.driftIntro, style: Theme.of(context).textTheme.bodySmall),
              if (d.missing.isNotEmpty) ...[
                SectionTitle(c.bannerMissingHeading),
                for (final m in d.missing) _MissingRow(item: m, drift: d),
              ],
              if (d.unplanned.isNotEmpty) ...[
                SectionTitle(c.bannerUnplannedHeading),
                for (final a in d.unplanned) _UnplannedRow(actual: a, drift: d),
              ],
              if (d.lateValue.isNotEmpty) ...[
                SectionTitle(c.driftLateHeading),
                for (final m in d.lateValue)
                  Padding(
                    padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
                    child: PostTile(post: m.post),
                  ),
              ],
              const SizedBox(height: StudioSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

/// A post that did not go out, with the buttons its own `actions` allow.
class _MissingRow extends ConsumerStatefulWidget {
  const _MissingRow({required this.item, required this.drift});
  final DriftItem item;
  final PostDrift drift;

  @override
  ConsumerState<_MissingRow> createState() => _MissingRowState();
}

class _MissingRowState extends ConsumerState<_MissingRow> {
  bool _busy = false;

  PostNotifier get _notifier =>
      ref.read(postProvider(widget.item.post.id).notifier);

  Future<void> _run(Future<void> Function() op, String done) async {
    final c = CalendarStrings.of(context);
    setState(() => _busy = true);
    try {
      await op();
      ref.invalidate(postDriftProvider);
      if (mounted) showSnack(context, done);
    } catch (e) {
      if (mounted) showSnack(context, c.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
      c.driftWontDone,
    );
  }

  Future<void> _move(SocialPost p) async {
    final saved = await showPostSlotForm(
      context,
      post: p,
      mode: SlotFormMode.move,
    );
    if (saved == true) {
      ref.invalidate(postDriftProvider);
      await _notifier.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = CalendarStrings.of(context);
    final labels = StudioLabels.of(context);
    final post = widget.item.post;
    final full = ref.watch(postProvider(post.id)).valueOrNull;
    final a = full?.actions ?? const <String>[];
    return Card(
      key: ValueKey('drift-missing-${post.id}'),
      margin: const EdgeInsets.only(bottom: StudioSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(StudioSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PostTile(post: post, showDate: true),
            if (full == null)
              Padding(
                padding: const EdgeInsets.all(StudioSpacing.sm),
                child: Text(
                  c.driftLoadingActions,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              Wrap(
                spacing: StudioSpacing.sm,
                runSpacing: StudioSpacing.xs,
                children: [
                  if (a.contains('retry'))
                    FilledButton.tonal(
                      key: ValueKey('drift-retry-${post.id}'),
                      onPressed: _busy
                          ? null
                          : () => _run(
                              () =>
                                  _notifier.retry(requestId: const Uuid().v4()),
                              c.retrying,
                            ),
                      child: Text(labels.action('post_retry')!),
                    ),
                  if (a.contains('move'))
                    OutlinedButton(
                      key: ValueKey('drift-move-${post.id}'),
                      onPressed: _busy ? null : () => _move(full),
                      child: Text(labels.action('post_move')!),
                    ),
                  if (a.contains('wont_post'))
                    OutlinedButton(
                      key: ValueKey('drift-wont-${post.id}'),
                      onPressed: _busy ? null : _wontPost,
                      child: Text(labels.action('post_wont_post')!),
                    ),
                  TextButton(
                    key: ValueKey('drift-open-${post.id}'),
                    onPressed: () => context.push('/calendar/post/${post.id}'),
                    child: Text(labels.action('open')!),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// A live post nobody planned: match it to a post that did not go out, or
/// ignore it (founder and marketing lead).
class _UnplannedRow extends ConsumerStatefulWidget {
  const _UnplannedRow({required this.actual, required this.drift});
  final ActualPost actual;
  final PostDrift drift;

  @override
  ConsumerState<_UnplannedRow> createState() => _UnplannedRowState();
}

class _UnplannedRowState extends ConsumerState<_UnplannedRow> {
  bool _busy = false;

  Future<void> _ignore() async {
    final c = CalendarStrings.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(calendarRepositoryProvider).actualIgnore(widget.actual.id);
      ref.invalidate(postDriftProvider);
      if (mounted) showSnack(context, c.driftIgnored);
    } catch (e) {
      if (mounted) showSnack(context, c.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _match() async {
    final c = CalendarStrings.of(context);
    final candidates = widget.drift.missing;
    if (candidates.isEmpty) {
      showSnack(context, c.driftNothingToMatch);
      return;
    }
    final picked = await showModalBottomSheet<PostSummary>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: ListView(
          key: const ValueKey('drift-match-sheet'),
          padding: const EdgeInsets.all(StudioSpacing.gutter),
          shrinkWrap: true,
          children: [
            Text(c.driftMatchPick, style: Theme.of(sheet).textTheme.titleSmall),
            const SizedBox(height: StudioSpacing.sm),
            for (final m in candidates)
              ListTile(
                key: ValueKey('drift-match-${m.post.id}'),
                contentPadding: EdgeInsets.zero,
                title: PersonText(m.post.title),
                subtitle: Text(
                  CairoFormat.stamp(m.post.slotTime, isArabic(sheet)),
                ),
                onTap: () => Navigator.of(sheet).pop(m.post),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(calendarRepositoryProvider)
          .actualMatch(widget.actual.id, picked.id);
      ref.invalidate(postDriftProvider);
      ref.invalidate(postProvider(picked.id));
      if (mounted) showSnack(context, c.driftMatched);
    } catch (e) {
      if (mounted) showSnack(context, c.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = CalendarStrings.of(context);
    final labels = StudioLabels.of(context);
    final a = widget.actual;
    final role = ref.watch(studioSessionProvider).valueOrNull?.primaryRole;
    final canClear = role == StudioRole.founder || role == StudioRole.lead;
    final text = (a.caption?.isNotEmpty ?? false)
        ? a.caption!
        : a.permalink ?? a.id;
    return Card(
      key: ValueKey('drift-unplanned-${a.id}'),
      margin: const EdgeInsets.only(bottom: StudioSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(StudioSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              [
                labels.actualKind(a.kind),
                CairoFormat.stamp(a.postedAt, isArabic(context)),
              ].where((s) => s.isNotEmpty).join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: StudioSpacing.sm),
            if (canClear)
              Wrap(
                spacing: StudioSpacing.sm,
                children: [
                  FilledButton.tonal(
                    key: ValueKey('drift-actual-match-${a.id}'),
                    onPressed: _busy ? null : _match,
                    child: Text(labels.action('actual_match')!),
                  ),
                  OutlinedButton(
                    key: ValueKey('drift-actual-ignore-${a.id}'),
                    onPressed: _busy ? null : _ignore,
                    child: Text(labels.action('actual_ignore')!),
                  ),
                ],
              )
            else
              Text(
                c.driftOnlyLead,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
