import '../../../core/l10n/studio_labels.dart';
import 'package:flutter/material.dart';
import '../../../shared/person_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../pieces/presentation/piece_widgets.dart';
import '../calendar_strings.dart';
import '../data/calendar_repository.dart';
import '../state/cairo_format.dart';
import 'calendar_widgets.dart';

/// The banner above the calendar: posts that did not go out, posts that went
/// out without being in the calendar, and consistency problems. Hidden when
/// there is nothing to say, or while the data has not arrived. With a
/// [window] it speaks only for the days on screen: a week with nothing wrong
/// shows nothing, whatever is wrong in another week.
class CalendarBanner extends ConsumerWidget {
  const CalendarBanner({super.key, this.window});

  /// The days on screen as `yyyy-mm-dd`; null counts everything.
  final ({String from, String to})? window;

  bool _in(String? iso) {
    final w = window;
    if (w == null || iso == null || iso.length < 10) return true;
    final day = iso.substring(0, 10);
    return day.compareTo(w.from) >= 0 && day.compareTo(w.to) <= 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = CalendarStrings.of(context);
    final fullDrift = ref.watch(postDriftProvider).valueOrNull;
    final fullChecks = ref.watch(postChecksProvider).valueOrNull;
    final drift = fullDrift == null || window == null
        ? fullDrift
        : fullDrift.copyWith(
            missing: [
              for (final m in fullDrift.missing)
                if (_in(m.post.slotTime)) m,
            ],
            unplanned: [
              for (final a in fullDrift.unplanned)
                if (_in(a.postedAt)) a,
            ],
          );
    final checkRows = [
      for (final r in fullChecks?.items ?? const <CheckRow>[])
        if (_in(r.date)) r,
    ];
    final checks = fullChecks == null || window == null
        ? fullChecks
        : fullChecks.copyWith(
            items: checkRows,
            block: checkRows
                .where((r) => r.severity == CheckSeverity.block)
                .length,
            warn: checkRows
                .where((r) => r.severity != CheckSeverity.block)
                .length,
          );
    final missing = window == null
        ? drift?.counts.missing ?? 0
        : drift?.missing.length ?? 0;
    final unplanned = window == null
        ? drift?.counts.unplanned ?? 0
        : drift?.unplanned.length ?? 0;
    final block = checks?.block ?? 0;
    final warn = checks?.warn ?? 0;
    if (missing + unplanned + block + warn == 0) return const SizedBox.shrink();

    final lines = [
      if (missing > 0) c.missingPosts(missing),
      if (unplanned > 0) c.unplannedPosts(unplanned),
      if (block + warn > 0) c.checkProblems(block, warn),
    ];
    final stop = block > 0 || missing > 0;
    final color = stop ? StudioColors.danger : StudioColors.warning;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StudioSpacing.gutter,
        StudioSpacing.xs,
        StudioSpacing.gutter,
        StudioSpacing.xs,
      ),
      child: Material(
        color: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudioRadii.md),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
        ),
        child: InkWell(
          key: const ValueKey('calendar-banner'),
          borderRadius: BorderRadius.circular(StudioRadii.md),
          onTap: () => missing + unplanned > 0
              ? context.push('/calendar/drift')
              : _showDetails(context, drift, checks),
          child: Padding(
            padding: const EdgeInsets.all(StudioSpacing.md),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: color),
                const SizedBox(width: StudioSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.bannerTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      for (final l in lines) Text(l),
                    ],
                  ),
                ),
                Text(
                  c.bannerOpen,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: StudioColors.berryPink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(
    BuildContext context,
    PostDrift? drift,
    PostChecks? checks,
  ) {
    final c = CalendarStrings.of(context);
    final ar = isArabic(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheet).size.height * 0.8,
          ),
          child: ListView(
            key: const ValueKey('banner-sheet'),
            padding: const EdgeInsets.fromLTRB(
              StudioSpacing.gutter,
              0,
              StudioSpacing.gutter,
              StudioSpacing.xl,
            ),
            children: [
              if (drift != null && drift.missing.isNotEmpty) ...[
                Text(
                  c.bannerMissingHeading,
                  style: Theme.of(sheet).textTheme.titleSmall,
                ),
                const SizedBox(height: StudioSpacing.sm),
                for (final m in drift.missing) PostTile(post: m.post),
              ],
              if (drift != null && drift.unplanned.isNotEmpty) ...[
                Text(
                  c.bannerUnplannedHeading,
                  style: Theme.of(sheet).textTheme.titleSmall,
                ),
                const SizedBox(height: StudioSpacing.sm),
                for (final a in drift.unplanned)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.link_off),
                    title: Text(
                      (a.caption?.isNotEmpty ?? false)
                          ? a.caption!
                          : a.permalink ?? a.id,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(CairoFormat.stamp(a.postedAt, ar)),
                  ),
              ],
              if (checks != null && checks.items.isNotEmpty) ...[
                const SizedBox(height: StudioSpacing.md),
                Text(
                  c.sectionChecks,
                  style: Theme.of(sheet).textTheme.titleSmall,
                ),
                const SizedBox(height: StudioSpacing.sm),
                for (final row in checks.items)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      row.severity == CheckSeverity.block
                          ? Icons.error_outline
                          : Icons.warning_amber_outlined,
                      color: row.severity == CheckSeverity.block
                          ? StudioColors.danger
                          : StudioColors.warning,
                    ),
                    title: Text(
                      StudioLabels.of(
                        context,
                      ).problem(row.code, message: row.message),
                    ),
                    subtitle: row.title == null ? null : PersonText(row.title!),
                    onTap: row.postId == null
                        ? null
                        : () {
                            Navigator.of(sheet).pop();
                            context.push('/calendar/post/${row.postId}');
                          },
                  ),
              ],
              if (drift == null && checks == null) Text(c.bannerNothing),
            ],
          ),
        ),
      ),
    );
  }
}
