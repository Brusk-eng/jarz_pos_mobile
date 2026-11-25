import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/person_text.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/studio_labels.dart';
import '../../../core/l10n/studio_strings.dart';
import '../../../core/router/studio_screen.dart';
import '../../../core/roles/studio_role.dart' show StudioRole;
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../../shared/studio_async_view.dart';
import '../../inbox/presentation/inbox_strings.dart';
import '../../inbox/presentation/ui_helpers.dart';
import '../../review/data/review_repository.dart';
import '../../session/state/studio_session_notifier.dart';
import '../../calendar/calendar_strings.dart';
import '../../calendar/data/calendar_repository.dart';
import '../../ideas/presentation/ideas_strings.dart';
import '../../ideas/presentation/my_ideas_screen.dart' show myIdeasPath;
import '../../pieces/presentation/piece_widgets.dart' show askText;
import '../../results/presentation/piece_results_screen.dart' show fileReadFlow;
import '../data/today_repository.dart';
import '../../../shared/studio_tr.dart';
import 'day_bar.dart';
import '../state/today_state.dart';
import 'task_form.dart';
import 'today_strings.dart';
import '../../../shared/studio_error_text.dart';

/// Whether the person may add tasks. The contract has no flag for it (only
/// the founder and the marketing lead may call `today.task_create`), so this
/// is the one place Today reads the role.
bool canAddTasks(StudioRole? role) =>
    role == StudioRole.founder || role == StudioRole.lead;

/// The body of Today: what waits on the person (blocks in the server's
/// order), then the one-off tasks. Pull to refresh.
class TodayBody extends ConsumerWidget {
  const TodayBody({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(todayProvider);
    ref.invalidate(inboxCountsProvider);
    ref.read(todayHiddenLinesProvider.notifier).state = const {};
    ref.read(todayDoneNotesProvider.notifier).state = const {};
    ref.read(todayDoneLinesProvider.notifier).state = const {};
    await ref.read(todayTasksProvider.notifier).refresh();
    try {
      await ref.read(todayProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = TodayStrings.of(context);
    final me = ref.watch(studioSessionProvider).valueOrNull;
    final role = me?.primaryRole;
    final value = ref
        .watch(todayProvider)
        .whenData((v) => withDoneLines(v, ref.watch(todayDoneLinesProvider)));
    final tasks = ref.watch(todayTasksProvider);
    final hidden = ref.watch(todayHiddenLinesProvider);
    final otherDate = ref.watch(todayDateProvider);
    final otherPerson = ref.watch(todayAsProvider);
    final other = otherDate != null || otherPerson != null;
    ref.listen<AsyncValue<TodayView>>(todayProvider, (_, next) {
      final v = next.valueOrNull;
      if (v != null && ref.read(todayDateProvider) == null) {
        ref.read(todayAnchorProvider.notifier).state = v.date;
      }
    });
    final labels = StudioLabels.of(context);
    final screenCopy = StudioStrings.of(context).screen(StudioScreen.today);

    bool nothing(TodayView v) =>
        v.blocks.every((b) => b.lines.every((l) => hidden.contains(l.id))) &&
        (other || (tasks.valueOrNull?.items.isEmpty ?? false));

    return StudioAsyncView<TodayView>(
      value: value,
      onRetry: () => ref.invalidate(todayProvider),
      isEmpty: nothing,
      empty: StudioEmptyConfig(
        purpose: role == null ? screenCopy.purpose : t.firstPurpose(role),
        firstStep: role == null ? screenCopy.firstStep : t.firstStep(role),
        actionLabel: canAddTasks(role) ? t.addTask : null,
        onAction: canAddTasks(role) ? () => showTaskForm(context) : null,
      ),
      builder: (context, view) => RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          key: const ValueKey('today-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(StudioSpacing.gutter),
          children: [
            DayBar(view: view, role: role),
            if (me != null && role != null && !other) ...[
              Text(
                StudioStrings.of(context).helloUser(me.fullName),
                key: const ValueKey('today-hello'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: StudioSpacing.xs),
              Text(
                StudioStrings.of(context).role(role),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: StudioSpacing.md),
              NextStepLine(t.nextBlocks),
              const SizedBox(height: StudioSpacing.lg),
            ],
            for (final block in view.blocks)
              if (block.lines.any((l) => !hidden.contains(l.id)))
                Padding(
                  padding: const EdgeInsets.only(bottom: StudioSpacing.md),
                  child: _BlockCard(block: block, hidden: hidden),
                ),
            for (final key in _emptyBlocks(view, other ? null : role))
              Padding(
                padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
                child: Text(
                  labels.blockEmpty(key)!,
                  key: ValueKey('today-empty-${key.name}'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (!other &&
                (role == StudioRole.creator || role == StudioRole.story))
              const _MyIdeasLink(),
            if (!other) _TasksSection(role: role),
          ],
        ),
      ),
    );
  }
}

/// The blocks this role watches that came back empty (the server leaves empty
/// blocks out), so a new person can tell "nothing" from "no such block".
List<BlockKey> _emptyBlocks(TodayView view, StudioRole? role) {
  if (role == null) return const [];
  const watched = {
    StudioRole.lead: [
      BlockKey.blocked,
      BlockKey.dueToday,
      BlockKey.sentBack,
      BlockKey.didntGoOut,
    ],
    StudioRole.creator: [BlockKey.sentBack, BlockKey.dueToday],
    StudioRole.story: [BlockKey.sentBack, BlockKey.dueToday],
    StudioRole.founder: [BlockKey.didntGoOut],
  };
  final present = {for (final b in view.blocks) b.key};
  return [
    for (final k in watched[role] ?? const <BlockKey>[])
      if (!present.contains(k)) k,
  ];
}

class _BlockCard extends ConsumerWidget {
  const _BlockCard({required this.block, required this.hidden});

  final TodayBlock block;
  final Set<String> hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = TodayStrings.of(context);
    final theme = Theme.of(context);
    final lines = [
      for (final l in block.lines)
        if (!hidden.contains(l.id)) l,
    ];
    return Card(
      key: ValueKey('today-block-${block.key.name}'),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StudioSpacing.lg,
              StudioSpacing.md,
              StudioSpacing.lg,
              StudioSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    StudioLabels.of(
                      context,
                    ).block(block.key, fallback: block.title),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                CountPill(
                  block.count,
                  color: block.level == NoteLevel.stop
                      ? StudioColors.danger
                      : block.level == NoteLevel.warn
                      ? StudioColors.warning
                      : StudioColors.deepPlum,
                ),
              ],
            ),
          ),
          for (final line in lines) TodayLineTile(line: line),
          if (const {
            BlockKey.didntGoOut,
            BlockKey.unplanned,
            BlockKey.unconfirmed,
          }.contains(block.key))
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: ValueKey('today-drift-${block.key.name}'),
                onPressed: () => context.push('/calendar/drift'),
                child: Text(t.clearDrift),
              ),
            ),
          if (block.moreRoute != null && block.count > lines.length)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: ValueKey('today-more-${block.key.name}'),
                onPressed: () => context.push(block.moreRoute!),
                child: Text(t.seeAll(block.count)),
              ),
            ),
        ],
      ),
    );
  }
}

/// The actions a Today line may show as a button (the contract's inline ones).
const _lineActions = {
  'tick',
  'approve',
  'fix',
  'posted',
  'mark_posted',
  'wont_post',
  'frame_set',
  'match',
  'ignore',
  'resolve',
};

/// One line of a block. Tapping it opens `line.route`; inline buttons come
/// only from `line.actions`.
/// Creator and story lead: a way back to the ideas they brought.
class _MyIdeasLink extends StatelessWidget {
  const _MyIdeasLink();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.md),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: const ValueKey('today-my-ideas'),
          onPressed: () => context.push(myIdeasPath),
          icon: const Icon(Icons.lightbulb_outline, size: 18),
          label: Text(IdeasStrings.of(context).myIdeas),
        ),
      ),
    );
  }
}

class TodayLineTile extends ConsumerStatefulWidget {
  const TodayLineTile({super.key, required this.line});
  final TodayLine line;

  @override
  ConsumerState<TodayLineTile> createState() => _TodayLineTileState();
}

class _TodayLineTileState extends ConsumerState<TodayLineTile> {
  bool _busy = false;

  Future<void> _run(String action) async {
    final line = widget.line;
    final t = TodayStrings.of(context);
    final inboxStrings = InboxStrings.of(context);
    final router = GoRouter.maybeOf(context);
    // Actions the line can do in place; the rest open the exact screen.
    final inline =
        action == 'tick' || action == 'approve' || action == 'wont_post';
    // A "result to add" line opens the read form, by its button too.
    if (action == 'open' && line.kind == LineKind.read) {
      await _openRead();
      return;
    }
    if (!inline) {
      router?.push(line.route);
      return;
    }
    final id = line.ref?.name ?? line.id;
    // Won't post asks for the reason first (the same sheet as the post screen).
    String? reason;
    final c = CalendarStrings.of(context);
    final wontDone = c.markedWont;
    if (action == 'wont_post') {
      reason = await askText(
        context,
        title: c.wontPostTitle,
        label: c.reasonLabel,
        requiredMessage: c.reasonNeeded,
      );
      if (reason == null || !mounted) return;
    }
    final notes = ref.read(todayDoneNotesProvider.notifier);
    // Taken before the write: the write refreshes Today at once.
    final block = ref
        .read(todayProvider)
        .valueOrNull
        ?.blocks
        .where((b) => b.lines.any((l) => l.id == line.id))
        .firstOrNull;
    setState(() => _busy = true);
    try {
      String next;
      if (action == 'tick') {
        await ref.read(todayRepositoryProvider).tick(id);
        next = t.tickedNext;
      } else if (action == 'wont_post') {
        await ref
            .read(calendarRepositoryProvider)
            .wontPost(id, reason!, requestId: const Uuid().v4());
        next = wontDone;
      } else {
        final v = await ref.read(reviewRepositoryProvider).approve(id);
        final post = v.post;
        final slot = post?.slotTime;
        next = t.approvedNext(
          slot == null ? null : slotText(inboxStrings, slot),
          post?.postingMode == PostingMode.byHand,
        );
      }
      // The line stays with what happens next and who has it; the next
      // refresh drops it (the server no longer lists it).
      notes.state = {...notes.state, line.id: next};
      if (block != null) {
        final kept = ref.read(todayDoneLinesProvider.notifier);
        kept.state = {...kept.state, line.id: (block: block.key, line: line)};
      }
    } catch (e) {
      if (mounted) {
        // ALREADY_DONE is a quiet success: refresh and move on.
        showStudioError(context, e);
      }
      ref.invalidate(todayProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open() => context.push(widget.line.route);

  /// A "result to add" line (`SP-2026-00190:72h`): opens the form that files
  /// that read, not the post. The line says which post and which read; the
  /// post says what is still missing. When the read is not due (or the post
  /// cannot be read) the line's own route opens instead.
  Future<void> _openRead() async {
    final line = widget.line;
    final bucket = line.id.contains(':') ? line.id.split(':').last : '72h';
    final postId = line.ref?.name ?? line.id.split(':').first;
    final router = GoRouter.maybeOf(context);
    setState(() => _busy = true);
    PostRead? read;
    try {
      final post = await ref.read(calendarRepositoryProvider).post(postId);
      read = post.reads
          .where((r) => r.bucket.wire == bucket && r.due && !r.filed)
          .firstOrNull;
    } catch (_) {
      read = null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (read == null) {
      router?.push(line.route);
      return;
    }
    await fileReadFlow(context, ref, read);
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final t = TodayStrings.of(context);
    final s = InboxStrings.of(context);
    final theme = Theme.of(context);
    final doneNote = ref.watch(todayDoneNotesProvider)[line.id];
    // Only the actions a line can run in place or open its screen for, with a
    // label; a code this app does not know is left out, never shown raw.
    final buttons = [
      for (final a in line.actions)
        if (a != 'open' && _lineActions.contains(a) && t.actionLabel(a) != null)
          a,
    ];
    final bar = levelColor(line.level);
    return InkWell(
      key: ValueKey('today-line-${line.id}'),
      onTap: line.kind == LineKind.read ? _openRead : _open,
      child: Container(
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(
              color: bar,
              width: line.level == NoteLevel.info ? 0 : 4,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: StudioSpacing.lg,
          vertical: StudioSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (line.thumb != null) ...[
                  StudioThumb(
                    media: line.thumb,
                    width: 44,
                    height: 56,
                    radius: BorderRadius.circular(StudioRadii.sm),
                  ),
                  const SizedBox(width: StudioSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PersonText(
                        line.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      if (line.subtitle != null)
                        Text(line.subtitle!, style: theme.textTheme.bodySmall),
                      if (line.due != null)
                        Text(
                          t.taskDue(slotText(s, line.due)),
                          style: theme.textTheme.labelSmall,
                        ),
                      if (line.badge != null)
                        Text(line.badge!, style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: StudioColors.plumMuted),
              ],
            ),
            if (doneNote != null)
              Padding(
                padding: const EdgeInsets.only(top: StudioSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: StudioColors.success,
                    ),
                    const SizedBox(width: StudioSpacing.sm),
                    Expanded(
                      child: Text(
                        doneNote,
                        key: ValueKey('line-${line.id}-done'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )
            else if (buttons.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: StudioSpacing.sm),
                child: Wrap(
                  spacing: StudioSpacing.sm,
                  runSpacing: StudioSpacing.xs,
                  children: [
                    for (final a in buttons)
                      OutlinedButton(
                        key: ValueKey('line-${line.id}-$a'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _busy ? null : () => _run(a),
                        child: Text(t.actionLabel(a)!),
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

class _TasksSection extends ConsumerWidget {
  const _TasksSection({required this.role});
  final StudioRole? role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = TodayStrings.of(context);
    final theme = Theme.of(context);
    final tasks = ref.watch(todayTasksProvider);
    final status = ref.watch(tasksStatusFilterProvider);
    final assignee = ref.watch(todayTasksAssigneeProvider);
    final showDone = status == 'done';
    final canAdd = canAddTasks(role);

    return Card(
      key: const ValueKey('today-tasks'),
      child: Padding(
        padding: const EdgeInsets.all(StudioSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(t.tasks, style: theme.textTheme.titleMedium),
                ),
                if (canAdd)
                  FilledButton.tonalIcon(
                    key: const ValueKey('task-add'),
                    onPressed: () => showTaskForm(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(t.addTask),
                  ),
              ],
            ),
            const SizedBox(height: StudioSpacing.sm),
            Wrap(
              spacing: StudioSpacing.sm,
              runSpacing: StudioSpacing.xs,
              children: [
                ChoiceChip(
                  key: const ValueKey('tasks-open'),
                  label: Text(t.showOpen),
                  selected: !showDone,
                  onSelected: (_) =>
                      ref.read(tasksStatusFilterProvider.notifier).state =
                          'open',
                ),
                ChoiceChip(
                  key: const ValueKey('tasks-done'),
                  label: Text(t.showDone),
                  selected: showDone,
                  onSelected: (_) =>
                      ref.read(tasksStatusFilterProvider.notifier).state =
                          'done',
                ),
                if (canAdd) ...[
                  ChoiceChip(
                    key: const ValueKey('tasks-mine'),
                    label: Text(t.myTasks),
                    selected: assignee == null,
                    onSelected: (_) =>
                        ref.read(todayTasksAssigneeProvider.notifier).state =
                            null,
                  ),
                  ChoiceChip(
                    key: const ValueKey('tasks-all'),
                    label: Text(t.everyonesTasks),
                    selected: assignee == 'all',
                    onSelected: (_) =>
                        ref.read(todayTasksAssigneeProvider.notifier).state =
                            'all',
                  ),
                ],
              ],
            ),
            const SizedBox(height: StudioSpacing.sm),
            tasks.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(StudioSpacing.md),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Row(
                children: [
                  Expanded(
                    child: Text(
                      InboxStrings.of(context).errGeneric,
                      key: const ValueKey('tasks-error'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(todayTasksProvider),
                    child: Text(StudioStrings.of(context).retry),
                  ),
                ],
              ),
              data: (d) => d.items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: StudioSpacing.sm,
                      ),
                      child: Text(
                        showDone ? t.noTasksDone : t.noTasksOpen,
                        key: const ValueKey('tasks-empty'),
                        style: theme.textTheme.bodySmall,
                      ),
                    )
                  : Column(
                      children: [
                        for (final task in d.items) TaskTile(task: task),
                        if (d.hasMore)
                          TextButton(
                            onPressed: () => ref
                                .read(todayTasksProvider.notifier)
                                .loadMore(),
                            child: Text(InboxStrings.of(context).loadMore),
                          ),
                        const SizedBox(height: StudioSpacing.xs),
                        NextStepLine(t.nextTask),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One task row: a tick box, the text, who and when, a menu for skip / edit.
class TaskTile extends ConsumerWidget {
  const TaskTile({super.key, required this.task});
  final StudioTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = TodayStrings.of(context);
    final s = InboxStrings.of(context);
    final theme = Theme.of(context);
    final canTick = task.actions.contains('tick');
    final canSkip = task.actions.contains('skip');
    final canEdit = task.actions.contains('edit');
    final who =
        task.assignee?.fullName ??
        (task.assigneeTeam == OwnerTeam.claude
            ? t.claudeTeam
            : task.assigneeTeam == OwnerTeam.creators
            ? t.creatorsTeam
            : null);
    final details = [
      if (who != null) t.assignedTo(who),
      if (task.due != null) t.taskDue(slotText(s, task.due)),
      if (task.dueTime != null) task.dueTime!,
      if (task.skipped) t.skipped,
    ].join(' · ');

    Future<void> act(Future<void> Function() f) async {
      try {
        await f();
        ref.invalidate(todayProvider);
      } catch (e) {
        if (context.mounted) showStudioError(context, e);
      }
    }

    return Row(
      key: ValueKey('task-${task.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canTick)
          Semantics(
            label: context.tr('Done: ${task.text}', 'تم: ${task.text}'),
            child: Checkbox(
              key: ValueKey('task-tick-${task.id}'),
              value: task.done,
              onChanged: (v) => act(
                () => ref
                    .read(todayTasksProvider.notifier)
                    .tick(task.id, done: v ?? true),
              ),
            ),
          )
        else
          const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: canEdit
                ? () => showTaskForm(
                    context,
                    task: task,
                    canAssign: canAddTasks(
                      ref.read(studioSessionProvider).valueOrNull?.primaryRole,
                    ),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: StudioSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PersonText(
                    task.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      decoration: task.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (details.isNotEmpty)
                    Text(details, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
        if (canSkip && !task.done && !task.skipped)
          IconButton(
            key: ValueKey('task-skip-${task.id}'),
            tooltip: t.skip,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.skip_next_outlined, size: 20),
            onPressed: () => act(
              () => ref
                  .read(todayTasksProvider.notifier)
                  .tick(task.id, skipped: true),
            ),
          ),
        if (canEdit)
          IconButton(
            key: ValueKey('task-edit-${task.id}'),
            tooltip: t.edit,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => showTaskForm(
              context,
              task: task,
              canAssign: canAddTasks(
                ref.read(studioSessionProvider).valueOrNull?.primaryRole,
              ),
            ),
          ),
      ],
    );
  }
}
