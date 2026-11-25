import '../../../shared/studio_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_labels.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../../shared/person_text.dart';
import '../../../shared/studio_error_text.dart';
import '../../../shared/studio_toast.dart';
import '../../../core/l10n/plural.dart';
import '../../../shared/studio_tr.dart';
import '../../session/state/studio_session_notifier.dart';
import '../../settings/presentation/moment_forms.dart';
import '../data/calendar_repository.dart';
import '../state/cairo_format.dart';
import '../state/cairo_time.dart';
import '../state/calendar_state.dart';

/// The status chips beside the channel chips. Posts are filtered by their
/// status (the wire names, worded by [StudioLabels.postStatus]).
class StatusFilter extends ConsumerWidget {
  const StatusFilter({super.key, required this.selected});

  final PostStatus? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = StudioLabels.of(context);
    void set(PostStatus? v) =>
        ref.read(calendarStatusFilterProvider.notifier).state = v;
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        key: const ValueKey('status-filter'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.gutter),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: StudioSpacing.sm),
              child: StudioChoiceChip(
                key: const ValueKey('status-all'),
                label: Text(context.tr('Any status', 'أي حالة')),
                selected: selected == null,
                onSelected: (_) => set(null),
              ),
            ),
            for (final s in PostStatus.values)
              if (s != PostStatus.unknown)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: StudioSpacing.sm,
                  ),
                  child: StudioChoiceChip(
                    key: ValueKey('status-${s.wire}'),
                    label: Text(labels.postStatus(s)),
                    selected: selected == s,
                    onSelected: (_) => set(selected == s ? null : s),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// "What changed": moved, skipped, put back and added posts of the last days,
/// newest first. A row opens the post. The line is the server's own words.
class CalendarChangesSheet extends ConsumerStatefulWidget {
  const CalendarChangesSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => const CalendarChangesSheet(),
  );

  @override
  ConsumerState<CalendarChangesSheet> createState() => _ChangesState();
}

class _ChangesState extends ConsumerState<CalendarChangesSheet> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(calendarChangesProvider(_days));
    final labels = StudioLabels.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: StudioSpacing.gutter,
              ),
              child: Text(
                context.tr('What changed', 'إيه اللي اتغيّر'),
                style: theme.textTheme.headlineSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(StudioSpacing.gutter),
              child: Wrap(
                spacing: StudioSpacing.sm,
                children: [
                  for (final d in const [1, 7, 30])
                    StudioChoiceChip(
                      key: ValueKey('changes-days-$d'),
                      label: Text(
                        d == 1
                            ? context.tr('Last day', 'آخر يوم')
                            : context.tr('Last $d days', 'آخر ${arDay.of(d)}'),
                      ),
                      selected: _days == d,
                      onSelected: (_) => setState(() => _days = d),
                    ),
                ],
              ),
            ),
            Flexible(
              child: value.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(StudioSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(StudioSpacing.gutter),
                  child: Text(
                    studioErrorMessage(
                      e,
                      ar: Localizations.localeOf(context).languageCode == 'ar',
                    ),
                  ),
                ),
                data: (r) => r.items.isEmpty
                    ? Padding(
                        key: const ValueKey('changes-empty'),
                        padding: const EdgeInsets.all(StudioSpacing.gutter),
                        child: Text(
                          context.tr(
                            'Nothing changed in this time.',
                            'مفيش حاجة اتغيّرت في المدة دي.',
                          ),
                        ),
                      )
                    : ListView(
                        key: const ValueKey('changes-list'),
                        shrinkWrap: true,
                        children: [
                          for (final c in r.items)
                            ListTile(
                              key: ValueKey('change-${c.id}'),
                              leading: SizedBox(
                                width: 40,
                                height: 50,
                                child: StudioThumb(media: c.post.thumb),
                              ),
                              title: PersonText(c.text),
                              subtitle: Text(
                                [
                                  labels.changeKind(c.kind),
                                  if (c.by != null) c.by!.fullName,
                                  CairoFormat.stamp(
                                    c.at,
                                    Localizations.localeOf(
                                          context,
                                        ).languageCode ==
                                        'ar',
                                  ),
                                ].join(' · '),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/calendar/post/${c.post.id}');
                              },
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
}

/// "Won't post": the skipped posts of the window on screen, with "Put back"
/// where the post's own `actions` allow it.
class SkippedPostsSheet extends ConsumerWidget {
  const SkippedPostsSheet({super.key, required this.window});

  final CalendarWindow window;

  static Future<void> show(BuildContext context, CalendarWindow window) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (_) => SkippedPostsSheet(window: window),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(skippedPostsProvider(window));
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: StudioSpacing.gutter,
              ),
              child: Text(
                context.tr('Won\'t post', 'مش هيتنشر'),
                style: theme.textTheme.headlineSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(StudioSpacing.gutter),
              child: Text(
                '${CairoFormat.isoDay(window.from, context.isAr)} - ${CairoFormat.isoDay(window.to, context.isAr)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
            Flexible(
              child: value.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(StudioSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(StudioSpacing.gutter),
                  child: Text(
                    studioErrorMessage(
                      e,
                      ar: Localizations.localeOf(context).languageCode == 'ar',
                    ),
                  ),
                ),
                data: (r) {
                  final posts = [
                    for (final p in r.posts)
                      if (p.status == PostStatus.cancelled) p,
                  ];
                  if (posts.isEmpty) {
                    return Padding(
                      key: const ValueKey('skipped-empty'),
                      padding: const EdgeInsets.all(StudioSpacing.gutter),
                      child: Text(
                        context.tr(
                          'Nothing is marked Won\'t post in this window.',
                          'مفيش بوست متعلّم «مش هيتنشر» في الفترة دي.',
                        ),
                      ),
                    );
                  }
                  return ListView(
                    key: const ValueKey('skipped-list'),
                    shrinkWrap: true,
                    children: [
                      for (final p in posts)
                        ListTile(
                          key: ValueKey('skipped-${p.id}'),
                          leading: SizedBox(
                            width: 40,
                            height: 50,
                            child: StudioThumb(media: p.thumb),
                          ),
                          title: PersonText(p.title),
                          subtitle: Text(
                            CairoFormat.stamp(
                              p.slotTime,
                              Localizations.localeOf(context).languageCode ==
                                  'ar',
                            ),
                          ),
                          trailing: _PutBack(postId: p.id),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/calendar/post/${p.id}');
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "Put back" button of a skipped post: shown only when the post's own
/// `actions` list has `reopen` (the range rows carry no actions, so the post
/// is read first). It sets the post's slot again, which reopens it.
class _PutBack extends ConsumerStatefulWidget {
  const _PutBack({required this.postId});
  final String postId;

  @override
  ConsumerState<_PutBack> createState() => _PutBackState();
}

class _PutBackState extends ConsumerState<_PutBack> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final post = ref.watch(postProvider(widget.postId)).valueOrNull;
    if (post == null || !post.actions.contains('reopen')) {
      return const SizedBox.shrink();
    }
    return TextButton(
      key: ValueKey('put-back-${widget.postId}'),
      onPressed: _busy
          ? null
          : () async {
              final done = context.tr(
                'Put back on the calendar.',
                'اترجع على الكاليندر.',
              );
              final ar = Localizations.localeOf(context).languageCode == 'ar';
              setState(() => _busy = true);
              try {
                await ref
                    .read(calendarRepositoryProvider)
                    .postSet(
                      postId: post.id,
                      slotTime: post.slotTime,
                      baseModified: post.modified,
                    );
                showStudioToast(done);
                ref.invalidate(skippedPostsProvider);
              } catch (e) {
                showStudioToast(
                  studioErrorMessage(e, ar: ar),
                  duration: studioErrorToastDuration,
                );
                if (mounted) setState(() => _busy = false);
              }
            },
      child: Text(context.tr('Put back', 'رجّعه')),
    );
  }
}

/// A moment on the calendar: what it is, when, and "Move this moment" where
/// its `actions` allow it.
class MomentSheet extends ConsumerWidget {
  const MomentSheet({super.key, required this.moment});

  final StudioMoment moment;

  static Future<void> show(BuildContext context, StudioMoment moment) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (_) => MomentSheet(moment: moment),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(studioSessionProvider).valueOrNull;
    final theme = Theme.of(context);
    final when = moment.effectiveDate ?? moment.date;
    final canMove = moment.actions.contains('move') && me != null;
    final d = CairoTime.parse(when);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          StudioSpacing.gutter,
          0,
          StudioSpacing.gutter,
          StudioSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PersonText(moment.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: StudioSpacing.xs),
            Text(
              [
                MomentForms.kindName(context, moment.kind),
                if (d != null) CairoFormat.full(d, context.isAr),
                if (moment.endDate != null)
                  context.tr(
                    'until ${CairoFormat.isoDay(moment.endDate, false)}',
                    'لحد ${CairoFormat.isoDay(moment.endDate, true)}',
                  ),
              ].where((e) => e.isNotEmpty).join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            if (moment.note != null && moment.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: StudioSpacing.sm),
                child: PersonText(moment.note!),
              ),
            if (canMove)
              Padding(
                padding: const EdgeInsets.only(top: StudioSpacing.lg),
                child: FilledButton(
                  key: const ValueKey('moment-move-this'),
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    nav.pop();
                    await MomentForms.move(nav.context, ref, moment);
                  },
                  child: Text(context.tr('Move this moment', 'انقل الموعد ده')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
