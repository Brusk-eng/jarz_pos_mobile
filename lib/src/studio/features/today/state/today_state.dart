import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../data/today_repository.dart';

/// What each acted-on Today line says now (line id to the sentence: what
/// happens next and who has it). The line stays, with that sentence in place of
/// its buttons, until the next refresh drops it.
final todayDoneNotesProvider = StateProvider<Map<String, String>>(
  (ref) => const {},
);

/// Today lines the person has just acted on (ticked, approved). They vanish at
/// once; if the call fails the id is removed again and the line comes back.
final todayHiddenLinesProvider = StateProvider<Set<String>>((ref) => const {});

/// Whose tasks the list shows: null = mine, 'all' = everyone's (founder and
/// lead only; the server decides what comes back).
final todayTasksAssigneeProvider = StateProvider<String?>((ref) => null);

/// The task list under the blocks. Same as the data layer's `tasksProvider`
/// plus the assignee filter and edit.
final todayTasksProvider =
    AsyncNotifierProvider<TodayTasksNotifier, PagedState<StudioTask>>(
      TodayTasksNotifier.new,
    );

class TodayTasksNotifier extends PagedNotifier<StudioTask> {
  TodayRepository get _repo => ref.read(todayRepositoryProvider);

  @override
  Future<StudioTaskPage> fetchPage(String? after) => _repo.tasks(
    assignee: ref.watch(todayTasksAssigneeProvider),
    status: ref.watch(tasksStatusFilterProvider),
    after: after,
  );

  StudioTask? _parse(Object? j) => j == null
      ? null
      : StudioTask.fromJson(Map<String, dynamic>.from(j as Map));

  /// Tick, untick or skip. The row leaves (or changes) at once; a failure
  /// puts it back and rethrows.
  Future<void> tick(
    String id, {
    bool done = true,
    bool skipped = false,
    String? requestId,
  }) async {
    final showingOpen = ref.read(tasksStatusFilterProvider) == 'open';
    await mutate<StudioTask>(
      match: (t) => t.id == id,
      optimistic: (t) => showingOpen && (done || skipped)
          ? null
          : t.copyWith(done: done && !skipped, skipped: skipped),
      call: () =>
          _repo.tick(id, done: done, skipped: skipped, requestId: requestId),
      fromCurrent: _parse,
    );
  }

  Future<StudioTask> create({
    required String text,
    String? assignee,
    String? assigneeTeam,
    String? due,
    String? requestId,
  }) async {
    final t = await _repo.create(
      text: text,
      assignee: assignee,
      assigneeTeam: assigneeTeam,
      due: due,
      requestId: requestId,
    );
    final cur = state.valueOrNull;
    if (cur != null) {
      state = AsyncData(PagedState(items: [t, ...cur.items], next: cur.next));
    }
    return t;
  }

  Future<StudioTask> edit(StudioTask task, Map<String, dynamic> fields) async {
    try {
      final t = await _repo.update(
        task.id,
        fields,
        baseModified: task.modified,
      );
      swap((x) => x.id == task.id, t);
      return t;
    } on Object {
      await refresh();
      rethrow;
    }
  }
}
