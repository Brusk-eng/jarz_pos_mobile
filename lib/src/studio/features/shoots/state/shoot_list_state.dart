import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../session/state/studio_session_notifier.dart';
import '../data/shoots_repository.dart';
import 'on_set_state.dart';

/// Every shoot, done ones included (the screen splits them into Upcoming and
/// Past).
final shootListProvider =
    AsyncNotifierProvider<ShootListNotifier, PagedState<ShootSummary>>(
      ShootListNotifier.new,
    );

class ShootListNotifier extends PagedNotifier<ShootSummary> {
  @override
  Future<ShootSummarySync> fetchPage(String? after) =>
      ref.read(shootsRepositoryProvider).list(includeDone: true, after: after);
}

/// Planning a shoot is for the founder and the marketing lead. (The contract
/// has no list-level action, so the role decides this one button.)
final canPlanShootsProvider = Provider<bool>(
  (ref) => ref.watch(studioSessionProvider).valueOrNull?.canPlanShoots ?? false,
);

/// A new link for the prep page is the founder's (contract: `regenerate`).
final isFounderProvider = Provider<bool>(
  (ref) =>
      ref.watch(studioSessionProvider).valueOrNull?.canRegeneratePrep ?? false,
);

/// A shoot is past when it is done or skipped, or filmed and its day is over.
bool isPastShoot(ShootSummary s, DateTime now) {
  if (s.status == ShootStatus.done || s.status == ShootStatus.skipped) {
    return true;
  }
  final d = s.shootDate == null ? null : DateTime.tryParse(s.shootDate!);
  if (s.status == ShootStatus.shot && d != null) {
    return d.isBefore(DateTime(now.year, now.month, now.day));
  }
  return false;
}

/// Upcoming first by date (undated last); past newest first.
({List<ShootSummary> upcoming, List<ShootSummary> past}) splitShoots(
  List<ShootSummary> all,
  DateTime now,
) {
  final up = <ShootSummary>[];
  final past = <ShootSummary>[];
  for (final s in all) {
    (isPastShoot(s, now) ? past : up).add(s);
  }
  int cmp(ShootSummary a, ShootSummary b, {required bool desc}) {
    final ad = a.shootDate, bd = b.shootDate;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    final c = ad.compareTo(bd);
    return desc ? -c : c;
  }

  up.sort((a, b) => cmp(a, b, desc: false));
  past.sort((a, b) => cmp(a, b, desc: true));
  return (upcoming: up, past: past);
}

final shootNowProvider = Provider<DateTime>(
  (ref) => ref.watch(onSetClockProvider)(),
);
