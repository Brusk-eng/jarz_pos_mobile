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

/// Number for the badge on the bottom bar's Inbox tab: exactly the sum of the
/// tiles this person's Inbox shows (to approve, to rate, decisions, ideas and
/// unread notifications, each only if their role has that tile). The server's
/// `total` is not used: it leaves out to rate and unread, and a role without a
/// tile would still be counted for it.
final inboxBadgeProvider = Provider<int>((ref) {
  final c = ref.watch(inboxCountsProvider).valueOrNull;
  if (c == null) return 0;
  var sum = 0;
  for (final s in ref.watch(inboxSectionsProvider)) {
    sum += switch (s) {
      InboxSection.approve => c.toApprove,
      InboxSection.rate => c.toRate,
      InboxSection.decisions => c.decisions,
      InboxSection.ideas => c.ideas,
      InboxSection.notifications => c.unreadNotifications,
    };
  }
  return sum;
});

/// Number for a bell badge: unread notifications.
final unreadBadgeProvider = Provider<int>((ref) {
  return ref.watch(unreadCountProvider).valueOrNull?.unread ?? 0;
});
