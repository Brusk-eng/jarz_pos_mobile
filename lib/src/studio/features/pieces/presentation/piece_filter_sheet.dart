import '../../../shared/studio_chips.dart';
import '../../../shared/studio_pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../shared/studio_tr.dart';
import '../../calendar/state/cairo_format.dart';
import '../../calendar/state/cairo_time.dart';
import '../../settings/data/settings_repository.dart';
import '../state/piece_filters.dart';

String _verdictLabel(BuildContext c, String v) =>
    v == 'none' ? c.tr('No verdict', 'من غير حكم') : v;

String _sortLabel(BuildContext c, String v) => v == 'rating'
    ? c.tr('Best rated first', 'الأعلى تقييم الأول')
    : c.tr('Newest first', 'الأحدث الأول');

/// The Saturday that starts the week of [date] (`YYYY-MM-DD`).
String _weekLabel(BuildContext c, String date) {
  final d = CairoTime.parse(date);
  if (d == null) return date;
  final thisWeek = CairoTime.weekStart(DateTime.now());
  final start = CairoTime.weekStart(d);
  if (CairoTime.sameDay(start, thisWeek)) {
    return c.tr('This week', 'الأسبوع ده');
  }
  if (CairoTime.sameDay(start, CairoTime.addDays(thisWeek, -7))) {
    return c.tr('Last week', 'الأسبوع اللي فات');
  }
  if (CairoTime.sameDay(start, CairoTime.addDays(thisWeek, 7))) {
    return c.tr('Next week', 'الأسبوع الجاي');
  }
  return c.tr(
    'Week of ${CairoFormat.full(start, false)}',
    'أسبوع ${CairoFormat.full(start, true)}',
  );
}

/// The "Filters" button of the Pieces tab and the chips of what is on, each
/// one removable. The board and the list both read the same filters.
class PieceFilterBar extends ConsumerWidget {
  const PieceFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(pieceFiltersProvider);
    void set(PieceFilters next) =>
        ref.read(pieceFiltersProvider.notifier).state = next;

    Widget chip(String key, String label, PieceFilters Function() cleared) =>
        Padding(
          padding: const EdgeInsetsDirectional.only(end: StudioSpacing.sm),
          child: InputChip(
            key: ValueKey('piece-chip-$key'),
            label: Text(label),
            deleteButtonTooltipMessage: context.tr('Remove', 'شيل'),
            onDeleted: () => set(cleared()),
            backgroundColor: StudioColors.softBlush,
          ),
        );

    return SingleChildScrollView(
      key: const ValueKey('piece-filter-bar'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: StudioSpacing.gutter,
        vertical: StudioSpacing.xs,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: StudioSpacing.sm),
            child: StudioActionChip(
              key: const ValueKey('piece-filters-open'),
              avatar: const Icon(Icons.tune, size: 18),
              label: Text(
                f.sheetCount == 0
                    ? context.tr('More filters', 'فلاتر أكتر')
                    : context.tr(
                        'More filters (${f.sheetCount})',
                        'فلاتر أكتر (${f.sheetCount})',
                      ),
              ),
              onPressed: () => PieceFilterSheet.show(context),
            ),
          ),
          if (f.batch != null)
            chip(
              'batch',
              context.tr('Batch: ${f.batch}', 'الدفعة: ${f.batch}'),
              () => f.copyWith(batch: null),
            ),
          if (f.situation != null)
            chip(
              'situation',
              context.tr('Situation: ${f.situation}', 'الموقف: ${f.situation}'),
              () => f.copyWith(situation: null),
            ),
          if (f.week != null)
            chip(
              'week',
              _weekLabel(context, f.week!),
              () => f.copyWith(week: null),
            ),
          if (f.verdict != null)
            chip(
              'verdict',
              context.tr(
                'Verdict: ${_verdictLabel(context, f.verdict!)}',
                'الحكم: ${_verdictLabel(context, f.verdict!)}',
              ),
              () => f.copyWith(verdict: null),
            ),
          if (f.route != null)
            chip(
              'route',
              context.tr('Route: ${f.route}', 'الطريقة: ${f.route}'),
              () => f.copyWith(route: null),
            ),
          if (f.readyForAds == true)
            chip(
              'ready',
              context.tr('Ready for ads', 'جاهز للإعلانات'),
              () => f.copyWith(readyForAds: null),
            ),
          if (f.needsVerdict == true)
            chip(
              'needs',
              context.tr('Needs a verdict', 'محتاج حكم'),
              () => f.copyWith(needsVerdict: null),
            ),
          if (f.sort != null && f.sort != 'recent')
            chip(
              'sort',
              _sortLabel(context, f.sort!),
              () => f.copyWith(sort: null),
            ),
        ],
      ),
    );
  }
}

/// The sheet of the piece filters the server takes: batch, situation, week,
/// verdict, route, ready for ads, needs a verdict, and the sort.
class PieceFilterSheet extends ConsumerWidget {
  const PieceFilterSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => const PieceFilterSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(pieceFiltersProvider);
    final options = ref.watch(studioOptionsProvider).valueOrNull;
    List<String> list(String key) => options?.lists[key] ?? const <String>[];
    void set(PieceFilters next) =>
        ref.read(pieceFiltersProvider.notifier).state = next;
    final theme = Theme.of(context);

    Widget group(String title, List<Widget> chips) => Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelLarge),
          const SizedBox(height: StudioSpacing.xs),
          Wrap(
            spacing: StudioSpacing.sm,
            runSpacing: StudioSpacing.xs,
            children: chips,
          ),
        ],
      ),
    );

    Widget choice(
      String key,
      String label,
      bool selected,
      VoidCallback onTap,
    ) => StudioChoiceChip(
      key: ValueKey(key),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );

    final thisWeek = CairoTime.weekStart(DateTime.now());
    String weekStart(int n) =>
        CairoTime.date(CairoTime.addDays(thisWeek, n * 7));
    bool onWeek(int n) =>
        f.week != null &&
        CairoTime.weekStart(CairoTime.parse(f.week!) ?? thisWeek) ==
            CairoTime.addDays(thisWeek, n * 7);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          StudioSpacing.gutter,
          0,
          StudioSpacing.gutter,
          StudioSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Filter the pieces', 'فلتر القطع'),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: StudioSpacing.md),
            if (list('batches').isNotEmpty)
              group(context.tr('Batch', 'الدفعة'), [
                for (final b in list('batches'))
                  choice(
                    'pf-batch-$b',
                    b,
                    f.batch == b,
                    () => set(f.copyWith(batch: f.batch == b ? null : b)),
                  ),
              ]),
            if (list('situations').isNotEmpty)
              group(context.tr('Situation', 'الموقف'), [
                for (final s in list('situations'))
                  choice(
                    'pf-situation-$s',
                    s,
                    f.situation == s,
                    () =>
                        set(f.copyWith(situation: f.situation == s ? null : s)),
                  ),
              ]),
            group(
              context.tr(
                'Week (Saturday to Friday)',
                'الأسبوع (من السبت للجمعة)',
              ),
              [
                choice(
                  'pf-week-this',
                  context.tr('This week', 'الأسبوع ده'),
                  onWeek(0),
                  () => set(f.copyWith(week: onWeek(0) ? null : weekStart(0))),
                ),
                choice(
                  'pf-week-last',
                  context.tr('Last week', 'الأسبوع اللي فات'),
                  onWeek(-1),
                  () =>
                      set(f.copyWith(week: onWeek(-1) ? null : weekStart(-1))),
                ),
                choice(
                  'pf-week-next',
                  context.tr('Next week', 'الأسبوع الجاي'),
                  onWeek(1),
                  () => set(f.copyWith(week: onWeek(1) ? null : weekStart(1))),
                ),
                StudioActionChip(
                  key: const ValueKey('pf-week-pick'),
                  avatar: const Icon(Icons.calendar_month, size: 18),
                  label: Text(context.tr('Pick a date', 'اختار تاريخ')),
                  onPressed: () async {
                    final picked = await showStudioDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2028),
                    );
                    if (picked != null) {
                      set(
                        f.copyWith(
                          week: CairoTime.date(CairoTime.weekStart(picked)),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            group(context.tr('Claude\'s verdict', 'حكم Claude'), [
              for (final v in list('verdicts'))
                choice(
                  'pf-verdict-$v',
                  _verdictLabel(context, v),
                  f.verdict == v,
                  () => set(f.copyWith(verdict: f.verdict == v ? null : v)),
                ),
            ]),
            if (list('routes').isNotEmpty)
              group(context.tr('Route', 'الطريقة'), [
                for (final r in list('routes'))
                  choice(
                    'pf-route-$r',
                    r,
                    f.route == r,
                    () => set(f.copyWith(route: f.route == r ? null : r)),
                  ),
              ]),
            group(context.tr('Checks', 'فحوصات'), [
              FilterChip(
                key: const ValueKey('pf-ready'),
                label: Text(context.tr('Ready for ads', 'جاهز للإعلانات')),
                selected: f.readyForAds == true,
                onSelected: (v) =>
                    set(f.copyWith(readyForAds: v ? true : null)),
              ),
              FilterChip(
                key: const ValueKey('pf-needs'),
                label: Text(context.tr('Needs a verdict', 'محتاج حكم')),
                selected: f.needsVerdict == true,
                onSelected: (v) =>
                    set(f.copyWith(needsVerdict: v ? true : null)),
              ),
            ]),
            group(context.tr('Sort', 'الترتيب'), [
              for (final s in list('piece_sorts'))
                choice(
                  'pf-sort-$s',
                  _sortLabel(context, s),
                  (f.sort ?? 'recent') == s,
                  () => set(f.copyWith(sort: s == 'recent' ? null : s)),
                ),
            ]),
            Row(
              children: [
                TextButton(
                  key: const ValueKey('pf-clear'),
                  onPressed: f.sheetCount == 0
                      ? null
                      : () => set(
                          f.copyWith(
                            situation: null,
                            batch: null,
                            week: null,
                            verdict: null,
                            route: null,
                            readyForAds: null,
                            needsVerdict: null,
                            sort: null,
                          ),
                        ),
                  child: Text(context.tr('Clear these', 'امسح دول')),
                ),
                const Spacer(),
                FilledButton(
                  key: const ValueKey('pf-done'),
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr('Done', 'تمام')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Used by the list view's own empty state to know the new filters are on.
bool pieceSheetFiltersOn(PieceFilters f) => f.sheetCount > 0;
