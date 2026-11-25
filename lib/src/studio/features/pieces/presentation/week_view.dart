import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/person_text.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/studio_async_view.dart';
import '../../calendar/presentation/calendar_widgets.dart';
import '../../calendar/state/cairo_format.dart';
import '../../calendar/state/cairo_time.dart';
import '../data/pieces_repository.dart';
import '../pieces_strings.dart';
import 'piece_widgets.dart';

/// The This week view: who has what, by person.
class PiecesWeekView extends ConsumerWidget {
  const PiecesWeekView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = PiecesStrings.of(context);
    final week = ref.watch(thisWeekProvider);
    return StudioAsyncView<ThisWeek>(
      value: week,
      onRetry: () => ref.invalidate(thisWeekProvider),
      isEmpty: (w) => w.groups.every(
        (g) =>
            g.pieces.isEmpty &&
            g.posts.isEmpty &&
            g.shots.isEmpty &&
            g.tasks.isEmpty,
      ),
      empty: StudioEmptyConfig(
        purpose: s.emptyWeekPurpose,
        firstStep: s.emptyWeekFirst,
        icon: Icons.event_note_outlined,
      ),
      builder: (context, w) => RefreshIndicator(
        onRefresh: () async => ref.refresh(thisWeekProvider.future),
        child: ListView(
          key: const ValueKey('week-list'),
          padding: const EdgeInsets.all(StudioSpacing.gutter),
          children: [
            for (final (i, g) in w.groups.indexed)
              _WeekGroupBlock(group: g, index: i),
          ],
        ),
      ),
    );
  }
}

class _WeekGroupBlock extends StatelessWidget {
  const _WeekGroupBlock({required this.group, required this.index});

  final WeekGroup group;
  final int index;

  @override
  Widget build(BuildContext context) {
    final s = PiecesStrings.of(context);
    final ar = isArabic(context);
    final name =
        group.person?.fullName ??
        (group.team != null && group.team != OwnerTeam.unknown
            ? s.team(group.team!)
            : s.nobodyYet);
    final nothing =
        group.pieces.isEmpty &&
        group.posts.isEmpty &&
        group.shots.isEmpty &&
        group.tasks.isEmpty;
    if (nothing) return const SizedBox.shrink();
    return Column(
      key: ValueKey('week-group-$index'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: StudioSpacing.md,
            bottom: StudioSpacing.sm,
          ),
          child: Text(name, style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final p in group.pieces)
          PieceCard(piece: p, onTap: () => context.push('/pieces/${p.id}')),
        for (final p in group.posts) PostTile(post: p, showDate: true),
        for (final shot in group.shots)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              shot.done ? Icons.check_circle_outline : Icons.circle_outlined,
              size: 20,
            ),
            title: Text(shot.what),
            subtitle: Text(
              [
                shot.shootTitle,
                if (CairoTime.parse(shot.shootDate) case final d?)
                  CairoFormat.dayMonth(d, ar),
              ].join(' · '),
            ),
            onTap: () => context.push('/shoots/${shot.shootId}'),
          ),
        for (final task in group.tasks)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              task.done ? Icons.check_circle_outline : Icons.task_alt_outlined,
              size: 20,
            ),
            title: PersonText(task.text),
            subtitle: task.due == null
                ? null
                : Text(s.dueOn(CairoFormat.stamp(task.due, ar))),
          ),
      ],
    );
  }
}
