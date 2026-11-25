import '../../../shared/studio_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/roles/studio_role.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/person_text.dart';
import '../../../shared/studio_tr.dart';
import '../../calendar/state/cairo_format.dart';
import '../../calendar/state/cairo_time.dart';
import '../../settings/data/settings_repository.dart';
import '../data/today_repository.dart';

/// The day arrows (every role), the "See the day of..." person picker
/// (Founder and Lead), and the banner that says whose day and which day is on
/// screen. Another day or another person has no action buttons: the server
/// sends none.
class DayBar extends ConsumerWidget {
  const DayBar({super.key, required this.view, required this.role});

  final TodayView view;
  final StudioRole? role;

  static String _shift(String date, int days) {
    final d = CairoTime.parse(date) ?? DateTime.now();
    return CairoTime.date(DateTime(d.year, d.month, d.day + days));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(todayDateProvider);
    final asKey = ref.watch(todayAsProvider);
    final anchor = ref.watch(todayAnchorProvider) ?? view.date;
    final theme = Theme.of(context);
    final canPickPerson = role == StudioRole.founder || role == StudioRole.lead;
    final shown = view.date;
    final viewing = view.viewingAs;

    String dayWord() {
      if (shown == anchor) return context.tr('Today', 'النهارده');
      if (shown == _shift(anchor, 1)) return context.tr('Tomorrow', 'بكرة');
      if (shown == _shift(anchor, -1)) return context.tr('Yesterday', 'امبارح');
      return CairoFormat.isoDay(shown, context.isAr);
    }

    void goTo(int days) {
      final next = _shift(shown, days);
      ref.read(todayDateProvider.notifier).state = next == anchor ? null : next;
    }

    final banner = <String>[
      if (viewing != null)
        context.tr(
          'You are looking at ${viewing.fullName}\'s day',
          'إنت بتشوف يوم ${viewing.fullName}',
        ),
      if (date != null && shown != anchor)
        context.tr(
          'Day shown: ${dayWord()} (${CairoFormat.isoDay(view.date, false)})',
          'اليوم المعروض: ${dayWord()} (${CairoFormat.isoDay(view.date, true)})',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          key: const ValueKey('day-bar'),
          children: [
            IconButton(
              key: const ValueKey('day-prev'),
              tooltip: context.tr('Previous day', 'اليوم اللي قبله'),
              icon: const Icon(Icons.chevron_left),
              onPressed: () => goTo(-1),
            ),
            Expanded(
              child: Text(
                dayWord(),
                key: const ValueKey('day-label'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall,
              ),
            ),
            IconButton(
              key: const ValueKey('day-next'),
              tooltip: context.tr('Next day', 'اليوم اللي بعده'),
              icon: const Icon(Icons.chevron_right),
              onPressed: () => goTo(1),
            ),
          ],
        ),
        Wrap(
          spacing: StudioSpacing.sm,
          children: [
            if (date != null)
              StudioActionChip(
                key: const ValueKey('day-today'),
                avatar: const Icon(Icons.today, size: 18),
                label: Text(context.tr('Back to today', 'ارجع للنهارده')),
                onPressed: () =>
                    ref.read(todayDateProvider.notifier).state = null,
              ),
            if (canPickPerson)
              StudioActionChip(
                key: const ValueKey('day-person'),
                avatar: const Icon(Icons.person_outline, size: 18),
                label: Text(
                  asKey == null
                      ? context.tr('See the day of...', 'شوف يوم...')
                      : context.tr('Someone else', 'حد تاني'),
                ),
                onPressed: () => _pickPerson(context, ref),
              ),
            if (asKey != null)
              StudioActionChip(
                key: const ValueKey('day-mine'),
                label: Text(context.tr('Back to my day', 'ارجع ليومي')),
                onPressed: () =>
                    ref.read(todayAsProvider.notifier).state = null,
              ),
          ],
        ),
        if (banner.isNotEmpty)
          Container(
            key: const ValueKey('day-banner'),
            margin: const EdgeInsets.symmetric(vertical: StudioSpacing.sm),
            padding: const EdgeInsets.all(StudioSpacing.md),
            decoration: BoxDecoration(
              color: StudioColors.softBlush,
              borderRadius: BorderRadius.circular(StudioRadii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in banner)
                  PersonText(
                    line,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  context.tr(
                    'Look only: there are no buttons here.',
                    'للمشاهدة بس: مفيش أزرار هنا.',
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _pickPerson(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => const _PeopleSheet(),
    );
    if (picked == null) return;
    ref.read(todayAsProvider.notifier).state = picked.isEmpty ? null : picked;
  }
}

class _PeopleSheet extends ConsumerWidget {
  const _PeopleSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider);
    return SafeArea(
      child: people.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(StudioSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(StudioSpacing.xl),
          child: Text(
            context.tr('Could not load people.', 'مقدرتش أحمّل الناس.'),
          ),
        ),
        data: (all) {
          const roles = {
            PersonRole.founder,
            PersonRole.marketingLead,
            PersonRole.creator,
            PersonRole.storyLead,
          };
          final list = [
            for (final p in all)
              if (p.enabled && roles.contains(p.studioRole)) p,
          ];
          return ListView(
            key: const ValueKey('day-people'),
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(context.tr('See the day of...', 'شوف يوم...')),
                dense: true,
              ),
              for (final p in list)
                ListTile(
                  key: ValueKey('day-person-${p.key}'),
                  title: PersonText(p.fullName),
                  onTap: () => Navigator.pop(context, p.key),
                ),
            ],
          );
        },
      ),
    );
  }
}
