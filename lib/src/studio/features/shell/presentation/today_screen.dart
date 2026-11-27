import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/router/studio_screen.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../inbox/presentation/inbox_strings.dart';
import '../../review/data/review_repository.dart';
import '../../today/data/today_repository.dart';
import '../../today/presentation/day_bar.dart';
import '../../today/presentation/task_form.dart';
import '../../today/presentation/today_strings.dart';
import '../../session/state/studio_session_notifier.dart';
import '../../../shared/layout/studio_layout.dart';
import '../../today/presentation/today_view.dart';
import '../../today/state/today_state.dart';

/// Today: what waits on this person, in the order their role works in, then
/// the one-off tasks. The body lives in `features/today`.
class StudioTodayScreen extends ConsumerWidget {
  const StudioTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = StudioStrings.of(context);
    final wide = context.isWideScreen;
    final role = ref.watch(studioSessionProvider).valueOrNull?.primaryRole;
    final view = ref.watch(todayProvider).valueOrNull;
    final other =
        ref.watch(todayDateProvider) != null ||
        ref.watch(todayAsProvider) != null;
    return ViewEditScaffold(
      title: t.tabToday,
      contentWidth: StudioContentWidth.full,
      // Wide: the day switcher shares the title's line.
      titleExtra: wide && view != null
          ? DayBar(view: view, role: role, part: DayBarPart.controls)
          : null,
      rootTab: true,
      screen: StudioScreen.today,
      showLanguageSwitch: true,
      actions: [
        if (wide && !other && canAddTasks(role))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilledButton.tonalIcon(
              key: const ValueKey('task-add-top'),
              onPressed: () => showTaskForm(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(TodayStrings.of(context).addTask),
            ),
          ),
        IconButton(
          key: const ValueKey('today-refresh'),
          tooltip: InboxStrings.of(context).refresh,
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.invalidate(todayProvider);
            ref.invalidate(inboxCountsProvider);
            ref.read(todayHiddenLinesProvider.notifier).state = const {};
            ref.read(todayDoneNotesProvider.notifier).state = const {};
            ref.read(todayDoneLinesProvider.notifier).state = const {};
            ref.invalidate(todayTasksProvider);
          },
        ),
      ],
      body: const TodayBody(),
    );
  }
}
