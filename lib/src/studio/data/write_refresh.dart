import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/studio_api.dart';
import '../features/calendar/data/calendar_repository.dart';
import '../features/decisions/data/decisions_repository.dart';
import '../features/ideas/data/ideas_repository.dart';
import '../features/notifications/data/notifications_repository.dart';
import '../features/paid/data/paid_repository.dart';
import '../features/paid/state/paid_state.dart';
import '../features/pieces/data/pieces_repository.dart';
import '../features/pieces/state/piece_filters.dart';
import '../features/references/data/references_repository.dart';
import '../features/references/state/references_state.dart';
import '../features/results/data/results_repository.dart';
import '../features/results/state/results_state.dart';
import '../features/review/data/review_repository.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/shoots/data/shoots_repository.dart';
import '../features/shoots/state/on_set_state.dart';
import '../features/today/data/today_repository.dart';
import '../features/today/state/today_state.dart';

/// THE one place that says which reads a successful write makes stale.
///
/// Every call that reaches the server and succeeds is announced by the API
/// (`StudioApi.writes`); [studioWriteRefreshProvider] (watched once by
/// `StudioApp`) looks the call up here and invalidates these providers. A
/// screen or notifier never invalidates another feature's provider after a
/// write: add the write to this map instead.
final Map<String, List<ProviderOrFamily>> studioWriteRefreshes = () {
  // What Today and the Inbox badges show.
  final badges = <ProviderOrFamily>[todayProvider, inboxCountsProvider];
  // Everywhere a piece appears.
  final pieces = <ProviderOrFamily>[
    pieceProvider,
    pieceBoardProvider,
    pieceListProvider,
    parkedPiecesProvider,
    thisWeekProvider,
  ];
  // Everywhere a post appears.
  final posts = <ProviderOrFamily>[
    postProvider,
    calendarRangeProvider,
    readyToPostProvider,
    postDriftProvider,
    postChecksProvider,
  ];
  final reviewed = <ProviderOrFamily>[
    ...badges,
    toApproveProvider,
    approvedSoonProvider,
    versionProvider,
    ...pieces,
    readyToPostProvider,
    calendarRangeProvider,
  ];
  final paid = <ProviderOrFamily>[
    ...badges,
    paidOverviewProvider,
    paidRoundStateProvider,
    paidRoundProvider,
    queueCandidatesProvider,
  ];
  final idea = <ProviderOrFamily>[
    ...badges,
    ideaProvider,
    myIdeasProvider,
    ...pieces,
  ];
  final shot = <ProviderOrFamily>[
    ...badges,
    shootsProvider,
    shootProvider,
    shootDetailProvider,
    ...pieces,
  ];
  final task = <ProviderOrFamily>[...badges, tasksProvider, todayTasksProvider];
  final post = <ProviderOrFamily>[
    ...badges,
    ...posts,
    ...pieces,
    toApproveProvider,
    approvedSoonProvider,
  ];
  final read = <ProviderOrFamily>[
    ...badges,
    postProvider,
    pieceResultsProvider,
    resultsByPieceProvider,
    scorecardProvider,
  ];
  final piece = <ProviderOrFamily>[...badges, ...pieces];
  // The reads that carry lines the server words in the person's language.
  final worded = <ProviderOrFamily>[
    ...badges,
    toApproveProvider,
    paidOverviewProvider,
    paidRoundStateProvider,
    paidRoundProvider,
    notificationsProvider,
    ...pieces,
    pieceHistoryProvider,
    scorecardProvider,
  ];
  final competitors = <ProviderOrFamily>[
    competitorListProvider,
    competitorsProvider,
    competitorProvider,
  ];
  final reference = <ProviderOrFamily>[
    referenceProvider,
    referenceGridProvider,
    referencesProvider,
  ];
  return {
    // A moved moment moves the posts pinned to it.
    'settings.moment_set': [
      momentsProvider,
      ...posts,
      ...pieces,
      todayProvider,
    ],
    'references.competitor_add': competitors,
    'references.competitor_remove': competitors,
    'references.competitor_restore': competitors,
    'references.set_feasibility': reference,
    'versions.approve': reviewed,
    'versions.fix': reviewed,
    'versions.clear_review': reviewed,
    'versions.add': reviewed,
    'decisions.answer': [...badges, decisionProvider],
    'ideas.keep': idea,
    'ideas.drop': idea,
    'ideas.propose': idea,
    'ideas.update': idea,
    'paid.ad_set_state': paid,
    'paid.round_set': paid,
    // The overview notifier shows its own queue edit.
    'paid.queue_add': [...badges, queueCandidatesProvider],
    'paid.queue_remove': [...badges, queueCandidatesProvider],
    'paid.queue_reorder': badges,
    'today.task_create': task,
    'today.task_update': task,
    'today.task_tick': task,
    'shoots.shot_tick': shot,
    'shoots.shot_set': shot,
    'shoots.shot_note': shot,
    'shoots.sync': shot,
    'shoots.prep_tick': shot,
    'calendar.post_mark_posted': post,
    'calendar.post_move': post,
    'calendar.post_wont_post': post,
    'calendar.post_set': post,
    'calendar.post_retry': post,
    'calendar.frame_set': post,
    'calendar.actual_match': post,
    'calendar.actual_ignore': post,
    'results.read_set': read,
    'results.scorecard_note': read,
    'notifications.mark_read': [unreadCountProvider, inboxCountsProvider],
    'settings.set_my_notifications': worded,
    'pieces.move': piece,
    'pieces.assign': piece,
    'pieces.park': piece,
    'pieces.unpark': piece,
    'pieces.update': piece,
    'pieces.create': piece,
  };
}();

/// Invalidates what [writeKey] (`group.fn`) changed. Public for tests.
void refreshAfterWrite(Ref ref, String writeKey) {
  for (final p in studioWriteRefreshes[writeKey] ?? const []) {
    ref.invalidate(p);
  }
}

/// Watched once by `StudioApp`: turns every announced write into the
/// refreshes listed in [studioWriteRefreshes].
final studioWriteRefreshProvider = Provider<void>((ref) {
  final sub = ref
      .watch(studioApiProvider)
      .writes
      .listen((key) => refreshAfterWrite(ref, key));
  ref.onDispose(sub.cancel);
});
