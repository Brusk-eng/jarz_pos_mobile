import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/router/studio_screen.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../inbox/presentation/inbox_strings.dart';
import '../../review/data/review_repository.dart';
import '../../today/data/today_repository.dart';
import '../../today/presentation/today_view.dart';
import '../../today/state/today_state.dart';

/// Today: what waits on this person, in the order their role works in, then
/// the one-off tasks. The body lives in `features/today`.
class StudioTodayScreen extends ConsumerWidget {
  const StudioTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = StudioStrings.of(context);
    return ViewEditScaffold(
      title: t.tabToday,
      screen: StudioScreen.today,
      showLanguageSwitch: true,
      actions: [
        IconButton(
          key: const ValueKey('today-refresh'),
          tooltip: InboxStrings.of(context).refresh,
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.invalidate(todayProvider);
            ref.invalidate(inboxCountsProvider);
            ref.read(todayHiddenLinesProvider.notifier).state = const {};
            ref.invalidate(todayTasksProvider);
          },
        ),
      ],
      body: const TodayBody(),
    );
  }
}
