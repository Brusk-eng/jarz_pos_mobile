import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/roles/studio_role.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../review/data/review_repository.dart';
import '../../session/state/studio_session_notifier.dart';

/// "Now" for waiting times. A provider so tests can pin it.
final studioNowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The five sections of the Inbox hub.
enum InboxSection { approve, rate, decisions, ideas, notifications }

/// Which hub tiles a role has work in. Navigation only: every button inside a
/// screen still comes from the server's `actions`.
const Map<StudioRole, List<InboxSection>> inboxSectionsByRole = {
  StudioRole.founder: [
    InboxSection.approve,
    InboxSection.rate,
    InboxSection.decisions,
    InboxSection.ideas,
    InboxSection.notifications,
  ],
  StudioRole.lead: [
    InboxSection.rate,
    InboxSection.decisions,
    InboxSection.ideas,
    InboxSection.notifications,
  ],
  StudioRole.creator: [
    InboxSection.rate,
    InboxSection.ideas,
    InboxSection.notifications,
  ],
  StudioRole.story: [
    InboxSection.rate,
    InboxSection.ideas,
    InboxSection.notifications,
  ],
};

/// The sections shown to the signed-in person.
final inboxSectionsProvider = Provider<List<InboxSection>>((ref) {
  final role = ref.watch(studioSessionProvider).valueOrNull?.primaryRole;
  return role == null ? const [] : inboxSectionsByRole[role]!;
});

/// Number for the badge on the bottom bar's Inbox tab: what waits on the
/// person (to approve + decisions + ideas, as the server sums it). The shell
/// scaffold does not read it yet; wire `ref.watch(inboxBadgeProvider)` there.
final inboxBadgeProvider = Provider<int>((ref) {
  return ref.watch(inboxCountsProvider).valueOrNull?.total ?? 0;
});

/// Number for a bell badge: unread notifications.
final unreadBadgeProvider = Provider<int>((ref) {
  return ref.watch(unreadCountProvider).valueOrNull?.unread ?? 0;
});
