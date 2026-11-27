import '../../../shared/layout/studio_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/how_this_works_sheet.dart';
import '../../../shared/media_row.dart';
import '../../../shared/person_text.dart';
import '../../../shared/studio_async_view.dart';
import '../../../core/l10n/plural.dart';
import '../../../shared/studio_tr.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../shell/more_common.dart';
import '../data/results_repository.dart';

/// The team's ratings across the open pieces: Ready to run, Drop or rework,
/// Team is split, Team progress and the latest comments. Founder and Lead.
class RatingsScreen extends ConsumerWidget {
  const RatingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(ratingsRollupProvider);
    return ViewEditScaffold(
      contentWidth: StudioContentWidth.full,
      title: context.tr('Team ratings', 'تقييمات الفريق'),
      parentRoute: '/more/results',
      actions: [
        IconButton(
          key: const ValueKey('ratings-how'),
          tooltip: context.tr('How this works', 'الموضوع ده بيشتغل إزاي'),
          icon: const Icon(Icons.help_outline),
          onPressed: () {
            final r = value.valueOrNull;
            HowThisWorksSheet.show(
              context,
              title: context.tr(
                'How the ratings are read',
                'إزاي بنقرا التقييمات',
              ),
              lines: _howLines(context, r?.thresholds),
            );
          },
        ),
      ],
      body: MoreBody(
        maxWidth: StudioContentWidth.full,
        child: StudioAsyncView<RatingsRollup>(
          emptyOnNotFound: true,
          value: value,
          onRetry: () => ref.invalidate(ratingsRollupProvider),
          empty: StudioEmptyConfig(
            purpose: context.tr(
              'Nothing to roll up yet.',
              'لسه مفيش تقييمات تتجمّع.',
            ),
            firstStep: context.tr(
              'Ratings appear when the team rates pieces.',
              'التقييمات بتظهر لما الفريق يقيّم القطع.',
            ),
            icon: Icons.star_outline,
          ),
          isEmpty: (_) => false,
          builder: (context, r) => _Body(r: r),
        ),
      ),
    );
  }

  static List<String> _howLines(BuildContext context, RatingsThresholds? t) {
    final min = t?.minRatings ?? 3;
    final ready = t?.readyAvg ?? 4;
    final drop = t?.dropAvg ?? 3;
    final sd = t?.splitSd ?? 1.2;
    final n = t?.splitMinN ?? 2;
    return [
      context.tr(
        'Only open pieces count: the current version, open to rate, past Script.',
        'القطع المفتوحة بس هي اللي بتتحسب: النسخة الحالية، مفتوحة للتقييم، وعدّت مرحلة السكريبت.',
      ),
      context.tr(
        'Ready to run: at least $min ratings and an average of $ready or more.',
        'جاهز للتشغيل: على الأقل ${arRating.of(min)} ومتوسط $ready أو أكتر.',
      ),
      context.tr(
        'Drop or rework: at least $min ratings and an average under $drop.',
        'نشيلها أو نعيد شغلها: على الأقل ${arRating.of(min)} ومتوسط أقل من $drop.',
      ),
      context.tr(
        'Team is split: at least $n ratings and the scores spread by $sd or more.',
        'الفريق مش متفق: على الأقل ${arRating.of(n)} والدرجات متباعدة $sd أو أكتر.',
      ),
      context.tr(
        'Each list shows 25 pieces at most; the number beside the title is the full count.',
        'كل قايمة بتعرض 25 قطعة على الأكتر؛ الرقم جنب العنوان هو العدد الكامل.',
      ),
    ];
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.r});
  final RatingsRollup r;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('ratings-body'),
      padding: const EdgeInsets.only(bottom: StudioSpacing.xl),
      children: [
        Padding(
          padding: const EdgeInsets.all(StudioSpacing.gutter),
          child: Wrap(
            spacing: StudioSpacing.sm,
            runSpacing: StudioSpacing.sm,
            children: [
              MorePill(
                context.count(
                  r.openCount,
                  one: 'open piece',
                  many: 'open pieces',
                  ar: arOpenPiece,
                ),
              ),
              MorePill(
                context.tr(
                  '${r.fullyRated} rated by everyone',
                  '${r.fullyRated} الكل قيّمها',
                ),
              ),
              MorePill(
                context.count(
                  r.ratingsCount,
                  one: 'rating',
                  many: 'ratings',
                  ar: arRating,
                ),
              ),
              MorePill(
                context.count(
                  r.commentsCount,
                  one: 'comment',
                  many: 'comments',
                  ar: arComment,
                ),
              ),
            ],
          ),
        ),
        // The lists side by side on a wide window, one column on a phone.
        // Rows carry their own side padding, so the grid adds no gap.
        ResponsiveSectionGrid(
          gap: 0,
          sections: [
            GridSection(
              weight: 1.0 + r.readyToRun.length,
              child: _Group(
                keyName: 'ready',
                title: context.tr('Ready to run', 'جاهز للتشغيل'),
                count: r.counts.readyToRun,
                rows: r.readyToRun,
                empty: context.tr('Nothing yet.', 'مفيش لسه.'),
              ),
            ),
            GridSection(
              weight: 1.0 + r.dropOrRework.length,
              child: _Group(
                keyName: 'drop',
                title: context.tr('Drop or rework', 'نشيلها أو نعيد شغلها'),
                count: r.counts.dropOrRework,
                rows: r.dropOrRework,
                empty: context.tr('Nothing yet.', 'مفيش لسه.'),
              ),
            ),
            GridSection(
              weight: 1.0 + r.teamSplit.length,
              child: _Group(
                keyName: 'split',
                title: context.tr('Team is split', 'الفريق مش متفق'),
                count: r.counts.teamSplit,
                rows: r.teamSplit,
                empty: context.tr('Nothing yet.', 'مفيش لسه.'),
              ),
            ),
            GridSection(
              weight: 1.0 + r.progress.length,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionLabel(context.tr('Team progress', 'تقدّم الفريق')),
                  for (final p in r.progress)
                    MoreCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: PersonText(p.person.fullName, maxLines: 2),
                          ),
                          Flexible(
                            child: Text(
                              context.tr(
                                '${p.rated} rated · ${p.left} left · ${p.total} total',
                                '${p.rated} قيّم · ${p.left} فاضل · ${p.total} الإجمالي',
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            GridSection(
              weight: 1.0 + 2.0 * r.latestComments.length,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionLabel(context.tr('Latest comments', 'آخر التعليقات')),
                  if (r.latestComments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(StudioSpacing.gutter),
                      child: Text(
                        context.tr('No comments yet.', 'مفيش تعليقات لسه.'),
                      ),
                    ),
                  for (final c in r.latestComments)
                    MoreCard(
                      onTap: () => context.push('/pieces/${c.piece.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PersonText(
                            '${c.person.fullName} · ${c.score}/5 · ${c.piece.title}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: StudioSpacing.xs),
                          PersonText(c.comment),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.keyName,
    required this.title,
    required this.count,
    required this.rows,
    required this.empty,
  });

  final String keyName;
  final String title;
  final int count;
  final List<RatedPiece> rows;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey('ratings-$keyName'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('$title ($count)'),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.gutter,
            ),
            child: Text(empty),
          ),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.gutter,
            ),
            child: StudioMediaRow(
              media: row.piece.picture,
              title: row.piece.title,
              subtitle: _sub(context, row),
              onTap: () => context.push('/pieces/${row.piece.id}'),
            ),
          ),
      ],
    );
  }

  static String _sub(BuildContext context, RatedPiece row) {
    final avg = row.avg.toStringAsFixed(1);
    final waiting = row.waiting.map((p) => p.fullName);
    return context.tr(
      'avg $avg · ${row.n} ratings'
          '${waiting.isEmpty ? '' : ' · waiting: ${waiting.join(', ')}'}',
      'متوسط $avg · ${arRating.of(row.n)}'
          '${waiting.isEmpty ? '' : ' · مستنيين: ${waiting.join('، ')}'}',
    );
  }
}
