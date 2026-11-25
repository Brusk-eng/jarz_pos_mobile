import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/media_row.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../session/state/studio_session_notifier.dart';
import '../../shell/more_common.dart';
import '../../shell/more_strings.dart';
import '../data/paid_repository.dart';
import '../paid_strings.dart';
import '../state/paid_state.dart';

/// The ad queue: what goes into the next round, in order. The founder drags
/// to reorder, adds a version the server lists as ready for ads, removes one
/// that is still waiting, and leaves a note.
class PaidQueueScreen extends ConsumerWidget {
  const PaidQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = PaidStrings.of(context);
    final value = ref.watch(paidOverviewProvider);
    // Adding a version is the founder's write; the server holds it too.
    final isFounder =
        ref.watch(studioSessionProvider).valueOrNull?.canAddToPaidQueue ??
        false;

    return ViewEditScaffold(
      title: t.queueTitle,
      parentRoute: '/more/paid',
      actions: [
        moreHelpAction(context, title: t.queueHelpTitle, lines: t.queueHelp),
      ],
      body: MoreBody(
        child: Column(
          children: [
            if (isFounder)
              Padding(
                padding: const EdgeInsets.all(StudioSpacing.gutter),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.icon(
                    key: const ValueKey('queue-add'),
                    onPressed: () => _openAdd(context),
                    icon: const Icon(Icons.add),
                    label: Text(t.addVersion),
                  ),
                ),
              ),
            Expanded(
              child: StudioAsyncView<PaidOverview>(
                emptyOnNotFound: true,
                value: value,
                onRetry: () => ref.invalidate(paidOverviewProvider),
                empty: StudioEmptyConfig(
                  purpose: t.queueEmptyPurpose,
                  firstStep: t.queueEmptyFirstStep,
                  icon: Icons.format_list_numbered,
                ),
                isEmpty: (o) => o.queue.isEmpty,
                builder: (context, o) => _QueueList(items: o.queue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAdd(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => const _AddSheet(),
    );
  }
}

class _QueueList extends ConsumerWidget {
  const _QueueList({required this.items});

  final List<QueueItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = PaidStrings.of(context);
    final m = MoreStrings.of(context);
    final canMove = items.any((q) => q.actions.contains('move'));

    return Column(
      children: [
        if (canMove)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.gutter,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                t.dragToReorder,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        Expanded(
          child: ReorderableListView.builder(
            key: const ValueKey('queue-list'),
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.only(bottom: StudioSpacing.xxl),
            itemCount: items.length,
            onReorderItem: (from, to) async {
              if (from == to) return;
              final ids = [for (final q in items) q.adId];
              ids.insert(to, ids.removeAt(from));
              await runMoreWrite(
                context,
                () => ref.read(paidOverviewProvider.notifier).reorderQueue(ids),
                okText: t.reorderedOk,
              );
            },
            itemBuilder: (context, i) {
              final q = items[i];
              return _QueueRow(
                key: ValueKey('queue-${q.adId}'),
                q: q,
                index: i,
                m: m,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QueueRow extends ConsumerWidget {
  const _QueueRow({
    super.key,
    required this.q,
    required this.index,
    required this.m,
  });

  final QueueItem q;
  final int index;
  final MoreStrings m;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = PaidStrings.of(context);
    final theme = Theme.of(context);
    final canMove = q.actions.contains('move');
    final canRemove = q.actions.contains('remove');

    return MoreCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canMove)
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: StudioSpacing.sm,
                  top: StudioSpacing.sm,
                ),
                child: Icon(
                  Icons.drag_handle,
                  key: ValueKey('drag-${q.adId}'),
                  color: StudioColors.plumMuted,
                ),
              ),
            ),
          SizedBox(
            width: 56,
            height: 56,
            child: StudioThumb(media: q.version.thumb ?? q.piece.picture),
          ),
          const SizedBox(width: StudioSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t.rankLabel(index + 1)}  ${q.piece.title}',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  t.versionNo(q.version.versionNo),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: StudioSpacing.xs),
                MorePill(
                  q.readyForAds ? t.readyForAds : t.notReadyForAds,
                  foreground: q.readyForAds
                      ? const Color(0xFF1F6B4A)
                      : StudioColors.warning,
                  background: q.readyForAds
                      ? const Color(0xFFD7EFE2)
                      : const Color(0xFFF5E8CC),
                ),
                if (q.queueNote != null && q.queueNote!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: StudioSpacing.xs),
                    child: Text(
                      q.queueNote!,
                      key: ValueKey('queue-note-${q.adId}'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
          if (canRemove)
            IconButton(
              key: ValueKey('queue-remove-${q.adId}'),
              tooltip: m.remove,
              icon: const Icon(Icons.close),
              onPressed: () => _remove(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final t = PaidStrings.of(context);
    final m = MoreStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('remove-dialog'),
        title: Text(t.removeTitle),
        content: Text(t.removeBody(q.piece.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(m.cancel),
          ),
          FilledButton(
            key: const ValueKey('remove-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.removeConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await runMoreWrite(
      context,
      () => ref.read(paidOverviewProvider.notifier).removeFromQueue(q.adId),
      okText: t.removedOk,
    );
  }
}

class _AddSheet extends ConsumerWidget {
  const _AddSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = PaidStrings.of(context);
    final m = MoreStrings.of(context);
    final candidates = ref.watch(queueCandidatesProvider);
    final height = MediaQuery.sizeOf(context).height * 0.7;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: StudioSpacing.gutter,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.addSheetTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    t.addSheetHelp,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: candidates.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(queueCandidatesProvider),
                    child: Text(m.retry),
                  ),
                ),
                data: (items) => items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(StudioSpacing.xl),
                          child: Text(
                            t.noCandidates,
                            key: const ValueKey('no-candidates'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView(
                        children: [
                          for (final c in items)
                            StudioMediaRow(
                              key: ValueKey('candidate-${c.piece.id}'),
                              media:
                                  c.piece.currentVersion?.thumb ??
                                  c.piece.picture,
                              title: c.piece.title,
                              subtitle: t.versionNo(c.version.versionNo),
                              onTap: () => _add(context, ref, c),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    QueueCandidate c,
  ) async {
    final t = PaidStrings.of(context);
    final navigator = Navigator.of(context);
    final note = await askForText(
      context,
      title: c.piece.title,
      hint: t.addNoteHint,
      confirm: t.addConfirm,
    );
    if (note == null || !context.mounted) return;
    final ok = await runMoreWrite(
      context,
      () => ref
          .read(paidOverviewProvider.notifier)
          .addToQueue(c.version.id, note: note.isEmpty ? null : note),
      okText: t.added,
    );
    if (ok) navigator.pop();
  }
}
