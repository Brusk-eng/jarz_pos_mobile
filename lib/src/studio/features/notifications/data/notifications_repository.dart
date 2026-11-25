import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';

class NotificationsRepository {
  NotificationsRepository(this._api);
  final StudioApi _api;

  Future<NotificationItemPage> list({bool? unreadOnly, String? after}) =>
      _api.notificationsList(unreadOnly: unreadOnly, after: after);

  Future<UnreadCount> unreadCount() => _api.notificationsUnreadCount();

  /// Marks [ids] read, or everything with [all].
  Future<UnreadCount> markRead({List<String>? ids, bool? all}) =>
      _api.notificationsMarkRead(ids: ids, all: all);
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(studioApiProvider)),
);

final unreadCountProvider = FutureProvider.autoDispose<UnreadCount>(
  (ref) => ref.watch(notificationsRepositoryProvider).unreadCount(),
);

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, PagedState<NotificationItem>>(
      NotificationsNotifier.new,
    );

class NotificationsNotifier extends PagedNotifier<NotificationItem> {
  NotificationsRepository get _repo =>
      ref.read(notificationsRepositoryProvider);

  @override
  Future<NotificationItemPage> fetchPage(String? after) =>
      _repo.list(after: after);

  /// Marks one notification read (when its push or row is opened).
  Future<void> markRead(String id) async {
    await mutate<UnreadCount>(
      match: (n) => n.id == id,
      optimistic: (n) => n.copyWith(read: true),
      call: () => _repo.markRead(ids: [id]),
    );
  }

  Future<void> markAllRead() async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    final before = state;
    state = AsyncData(
      PagedState(
        items: [for (final n in cur.items) n.copyWith(read: true)],
        next: cur.next,
      ),
    );
    try {
      await _repo.markRead(all: true);
    } catch (_) {
      state = before;
      rethrow;
    }
  }
}
