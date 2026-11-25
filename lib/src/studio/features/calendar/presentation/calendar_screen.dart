import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/roles/studio_role.dart';
import '../../../core/router/studio_screen.dart';
import '../../../core/theme/studio_status_colors.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../pieces/pieces_strings.dart';
import '../../pieces/presentation/piece_widgets.dart';
import '../../session/state/studio_session_notifier.dart';
import '../calendar_strings.dart';
import '../data/calendar_repository.dart';
import '../state/cairo_format.dart';
import '../state/cairo_time.dart';
import '../state/calendar_state.dart';
import 'calendar_banner.dart';
import 'calendar_extras.dart';
import '../../../shared/studio_tr.dart';
import 'calendar_widgets.dart';
import 'post_slot_form.dart';

/// The Calendar tab: week by default, a month overview, a jump to today and a
/// channel filter. Lead, founder and story lead can add a post to a slot.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = StudioStrings.of(context);
    final c = CalendarStrings.of(context);
    final today = ref.watch(calendarTodayProvider);
    final anchor = ref.watch(calendarAnchorProvider) ?? today;
    final mode = ref.watch(calendarModeProvider);
    final channel = ref.watch(calendarChannelFilterProvider);
    final status = ref.watch(calendarStatusFilterProvider);
    final role = ref.watch(studioSessionProvider).valueOrNull?.primaryRole;
    final canSet =
        role == StudioRole.founder ||
        role == StudioRole.lead ||
        role == StudioRole.story;
    final window = calendarWindowFor(mode, anchor);
    final range = ref.watch(calendarRangeProvider(window));
    final copy = t.screen(StudioScreen.calendar);

    Future<void> addPost(DateTime? day) async {
      final saved = await showPostSlotForm(context, initialDate: day);
      if (saved == true) ref.invalidate(calendarRangeProvider);
    }

    return ViewEditScaffold(
      title: t.tabCalendar,
      rootTab: true,
      screen: StudioScreen.calendar,
      showLanguageSwitch: true,
      actions: [
        IconButton(
          key: const ValueKey('calendar-changes'),
          tooltip: context.tr('What changed', 'إيه اللي اتغيّر'),
          icon: const Icon(Icons.history),
          onPressed: () => CalendarChangesSheet.show(context),
        ),
        IconButton(
          key: const ValueKey('calendar-skipped'),
          tooltip: context.tr('Won\'t post', 'مش هيتنشر'),
          icon: const Icon(Icons.event_busy_outlined),
          onPressed: () => SkippedPostsSheet.show(context, window),
        ),
        if (canSet)
          IconButton(
            key: const ValueKey('add-post'),
            tooltip: c.addPost,
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => addPost(null),
          ),
      ],
      body: Column(
        children: [
          _Toolbar(mode: mode, anchor: anchor, today: today),
          _ChannelFilter(selected: channel),
          StatusFilter(selected: status),
          const CalendarBanner(),
          Expanded(
            child: StudioAsyncView<CalendarRange>(
              value: range,
              onRetry: () => ref.invalidate(calendarRangeProvider),
              isEmpty: (r) =>
                  r.posts.isEmpty && r.moments.isEmpty && r.shoots.isEmpty,
              empty: StudioEmptyConfig(
                purpose: copy.purpose,
                firstStep: copy.firstStep,
                icon: Icons.event_outlined,
                actionLabel: canSet ? c.addPost : null,
                onAction: canSet ? () => addPost(anchor) : null,
              ),
              builder: (context, r) {
                final posts = [
                  for (final p in r.posts)
                    if ((channel == null || p.channel == channel) &&
                        (status == null || p.status == status))
                      p,
                ];
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.refresh(calendarRangeProvider(window).future),
                  child: mode == CalendarMode.week
                      ? _WeekView(
                          start: CairoTime.weekStart(anchor),
                          today: today,
                          range: r,
                          posts: posts,
                          canAdd: canSet,
                          onAdd: addPost,
                        )
                      : _MonthView(anchor: anchor, today: today, posts: posts),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- toolbar

class _Toolbar extends ConsumerWidget {
  const _Toolbar({
    required this.mode,
    required this.anchor,
    required this.today,
  });

  final CalendarMode mode;
  final DateTime anchor;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = CalendarStrings.of(context);
    final ar = isArabic(context);
    void go(DateTime d) => ref.read(calendarAnchorProvider.notifier).state = d;

    final String label;
    if (mode == CalendarMode.week) {
      final start = CairoTime.weekStart(anchor);
      label =
          '${CairoFormat.dayMonth(start, ar)} – ${CairoFormat.dayMonth(CairoTime.addDays(start, 6), ar)}';
    } else {
      label = CairoFormat.monthYear(anchor, ar);
    }

    DateTime step(int n) => mode == CalendarMode.week
        ? CairoTime.addDays(anchor, 7 * n)
        : DateTime(anchor.year, anchor.month + n, 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StudioSpacing.gutter,
        StudioSpacing.sm,
        StudioSpacing.sm,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<CalendarMode>(
                  key: const ValueKey('calendar-mode'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: CalendarMode.week,
                      label: Text(c.viewWeek),
                    ),
                    ButtonSegment(
                      value: CalendarMode.month,
                      label: Text(c.viewMonth),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (v) =>
                      ref.read(calendarModeProvider.notifier).state = v.first,
                ),
              ),
              const SizedBox(width: StudioSpacing.sm),
              TextButton(
                key: const ValueKey('calendar-today'),
                onPressed: () =>
                    ref.read(calendarAnchorProvider.notifier).state = null,
                child: Text(c.today),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                key: const ValueKey('calendar-prev'),
                tooltip: c.previous,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => go(step(-1)),
              ),
              Expanded(
                child: Text(
                  label,
                  key: const ValueKey('calendar-label'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                key: const ValueKey('calendar-next'),
                tooltip: c.next,
                icon: const Icon(Icons.chevron_right),
                onPressed: () => go(step(1)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChannelFilter extends ConsumerWidget {
  const _ChannelFilter({required this.selected});

  final PostChannel? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = CalendarStrings.of(context);
    final names = PiecesStrings.of(context);
    void set(PostChannel? v) =>
        ref.read(calendarChannelFilterProvider.notifier).state = v;
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        key: const ValueKey('channel-filter'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.gutter),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: StudioSpacing.sm),
              child: ChoiceChip(
                key: const ValueKey('channel-all'),
                label: Text(c.allChannels),
                selected: selected == null,
                onSelected: (_) => set(null),
              ),
            ),
            for (final ch in PostChannel.values)
              if (ch != PostChannel.unknown)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: StudioSpacing.sm,
                  ),
                  child: ChoiceChip(
                    key: ValueKey('channel-${ch.wire}'),
                    avatar: Icon(channelIcon(ch), size: 16),
                    label: Text(names.channel(ch)),
                    selected: selected == ch,
                    onSelected: (_) => set(selected == ch ? null : ch),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------- week

DateTime? _slotDay(PostSummary p) {
  final d = CairoTime.parse(p.slotTime);
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

class _WeekView extends StatefulWidget {
  const _WeekView({
    required this.start,
    required this.today,
    required this.range,
    required this.posts,
    required this.canAdd,
    required this.onAdd,
  });

  final DateTime start;
  final DateTime today;
  final CalendarRange range;
  final List<PostSummary> posts;
  final bool canAdd;
  final Future<void> Function(DateTime day) onAdd;

  @override
  State<_WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<_WeekView> {
  final _todayKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _showToday();
  }

  @override
  void didUpdateWidget(_WeekView old) {
    super.didUpdateWidget(old);
    if (old.start != widget.start) _showToday();
  }

  /// Opens the week with today in view, not at the top of Saturday.
  void _showToday() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _todayKey.currentContext;
      if (!mounted || ctx == null) return;
      Scrollable.ensureVisible(ctx, duration: Duration.zero);
    });
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.start;
    final today = widget.today;
    final range = widget.range;
    final posts = widget.posts;
    final canAdd = widget.canAdd;
    final onAdd = widget.onAdd;
    final days = [for (var i = 0; i < 7; i++) CairoTime.addDays(start, i)];
    Widget block(DateTime day) {
      final dayPosts = [
        for (final p in posts)
          if (_slotDay(p) case final d? when CairoTime.sameDay(d, day)) p,
      ]..sort((a, b) => (a.slotTime ?? '').compareTo(b.slotTime ?? ''));
      final moments = [
        for (final m in range.moments)
          if (CairoTime.parse(m.effectiveDate ?? m.date) case final d?
              when CairoTime.sameDay(d, day))
            m,
      ];
      final shoots = [
        for (final s in range.shoots)
          if (CairoTime.parse(s.shootDate) case final d?
              when CairoTime.sameDay(d, day))
            s,
      ];
      return _DayBlock(
        day: day,
        isToday: CairoTime.sameDay(day, today),
        posts: dayPosts,
        moments: moments,
        shoots: shoots,
        canAdd: canAdd,
        onAdd: () => onAdd(day),
      );
    }

    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth >= 900) {
          return Row(
            key: const ValueKey('week-wide'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final d in days)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(StudioSpacing.sm),
                    child: block(d),
                  ),
                ),
            ],
          );
        }
        // Seven blocks, all built at once, so today's block always exists to
        // be scrolled into view.
        return SingleChildScrollView(
          key: const ValueKey('week-days'),
          padding: const EdgeInsets.all(StudioSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final d in days)
                CairoTime.sameDay(d, today)
                    ? KeyedSubtree(key: _todayKey, child: block(d))
                    : block(d),
            ],
          ),
        );
      },
    );
  }
}

class _DayBlock extends StatelessWidget {
  const _DayBlock({
    required this.day,
    required this.isToday,
    required this.posts,
    required this.moments,
    required this.shoots,
    required this.canAdd,
    required this.onAdd,
  });

  final DateTime day;
  final bool isToday;
  final List<PostSummary> posts;
  final List<StudioMoment> moments;
  final List<ShootBrief> shoots;
  final bool canAdd;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = CalendarStrings.of(context);
    final ar = isArabic(context);
    final textTheme = Theme.of(context).textTheme;
    final dateKey = CairoTime.date(day);
    return Container(
      key: ValueKey('day-$dateKey'),
      margin: const EdgeInsets.only(bottom: StudioSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Semantics(
                  label: isToday
                      ? '${c.today}, ${CairoFormat.full(day, ar)}'
                      : CairoFormat.full(day, ar),
                  excludeSemantics: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: StudioSpacing.sm,
                      vertical: StudioSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: isToday ? StudioColors.berryPink : null,
                      borderRadius: BorderRadius.circular(StudioRadii.sm),
                    ),
                    child: Text(
                      CairoFormat.full(day, ar),
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: isToday ? Colors.white : null,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (canAdd)
                IconButton(
                  key: ValueKey('day-add-$dateKey'),
                  tooltip: c.addPost,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: onAdd,
                ),
            ],
          ),
          if (moments.isNotEmpty || shoots.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
              child: Wrap(
                spacing: StudioSpacing.sm,
                runSpacing: StudioSpacing.xs,
                children: [
                  for (final m in moments)
                    ActionChip(
                      key: ValueKey('moment-chip-${m.id}'),
                      avatar: const Icon(Icons.star_outline, size: 16),
                      label: Text(m.title),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => MomentSheet.show(context, m),
                    ),
                  for (final s in shoots)
                    ActionChip(
                      avatar: const Icon(Icons.videocam_outlined, size: 16),
                      label: Text(s.title),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => context.push('/shoots/${s.id}'),
                    ),
                ],
              ),
            ),
          if (posts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: StudioSpacing.xs),
              child: Text(c.nothingPlanned, style: textTheme.bodySmall),
            ),
          for (final p in posts) PostTile(post: p),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- month

class _MonthView extends ConsumerWidget {
  const _MonthView({
    required this.anchor,
    required this.today,
    required this.posts,
  });

  final DateTime anchor;
  final DateTime today;
  final List<PostSummary> posts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = CalendarStrings.of(context);
    final ar = isArabic(context);
    final first = DateTime(anchor.year, anchor.month, 1);
    final last = DateTime(anchor.year, anchor.month + 1, 0);
    var cursor = CairoTime.weekStart(first);
    final weeks = <List<DateTime>>[];
    while (!cursor.isAfter(last)) {
      weeks.add([for (var i = 0; i < 7; i++) CairoTime.addDays(cursor, i)]);
      cursor = CairoTime.addDays(cursor, 7);
    }
    final byDay = <String, List<PostSummary>>{};
    for (final p in posts) {
      final d = _slotDay(p);
      if (d != null) byDay.putIfAbsent(CairoTime.date(d), () => []).add(p);
    }
    return ListView(
      key: const ValueKey('month-grid'),
      padding: const EdgeInsets.all(StudioSpacing.gutter),
      children: [
        Row(
          children: [
            for (final d in weeks.first)
              Expanded(
                child: Center(
                  child: Text(
                    CairoFormat.weekday(d, ar),
                    style: StudioTextStyles.caption,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: StudioSpacing.xs),
        for (final w in weeks)
          Row(
            children: [
              for (final d in w)
                Expanded(
                  child: _MonthCell(
                    day: d,
                    inMonth: d.month == anchor.month,
                    isToday: CairoTime.sameDay(d, today),
                    posts: byDay[CairoTime.date(d)] ?? const [],
                    onTap: () {
                      ref.read(calendarAnchorProvider.notifier).state = d;
                      ref.read(calendarModeProvider.notifier).state =
                          CalendarMode.week;
                    },
                    label: c.postsCount(
                      (byDay[CairoTime.date(d)] ?? const []).length,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.posts,
    required this.onTap,
    required this.label,
  });

  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final List<PostSummary> posts;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: posts.isEmpty ? '${day.day}' : '${day.day}, $label',
      button: true,
      child: InkWell(
        key: ValueKey('month-cell-${CairoTime.date(day)}'),
        onTap: onTap,
        child: Container(
          height: 64,
          margin: const EdgeInsets.all(1),
          padding: const EdgeInsets.all(StudioSpacing.xs),
          decoration: BoxDecoration(
            color: isToday ? StudioColors.blushPale : Colors.white,
            border: Border.all(
              color: isToday ? StudioColors.berryPink : StudioColors.border,
            ),
            borderRadius: BorderRadius.circular(StudioRadii.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${day.day}',
                style: textTheme.labelMedium?.copyWith(
                  color: inMonth ? null : StudioColors.plumMuted,
                ),
              ),
              const Spacer(),
              if (posts.isNotEmpty)
                Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: [
                    for (final p in posts.take(4))
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: postStatusColors[p.status]!.background,
                          shape: BoxShape.circle,
                          border: Border.all(color: StudioColors.border),
                        ),
                      ),
                    if (posts.length > 4)
                      Text('+${posts.length - 4}', style: textTheme.labelSmall),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
