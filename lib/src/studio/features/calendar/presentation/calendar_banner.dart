import 'package:flutter/material.dart';
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
/// there is nothing to say, or while the data has not arrived.
class CalendarBanner extends ConsumerWidget {
  const CalendarBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = CalendarStrings.of(context);
    final drift = ref.watch(postDriftProvider).valueOrNull;
    final checks = ref.watch(postChecksProvider).valueOrNull;
    final missing = drift?.counts.missing ?? 0;
    final unplanned = drift?.counts.unplanned ?? 0;
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
          onTap: () => _showDetails(context, drift, checks),
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
                Text(c.bannerOpen, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: StudioColors.berryPink)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, PostDrift? drift, PostChecks? checks) {
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
                    title: Text(row.message),
                    subtitle: row.title == null ? null : Text(row.title!),
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
