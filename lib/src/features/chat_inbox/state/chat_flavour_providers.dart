import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_flavour_repository.dart';
import '../data/models/chat_flavour_models.dart';

/// The flavour availability list. A tap updates its row at once, then the
/// row the server returns replaces it; on error the row goes back to what it
/// was and the error is rethrown for the screen to show.
class ChatFlavourAvailabilityNotifier
    extends AutoDisposeAsyncNotifier<ChatFlavourAvailabilityPage> {
  int _seq = 0;

  /// Latest request per item, so an older answer never overwrites a newer tap.
  final Map<String, int> _itemSeq = {};

  @override
  Future<ChatFlavourAvailabilityPage> build() =>
      ref.read(chatFlavourRepositoryProvider).fetch();

  Future<void> refresh() async {
    final seq = ++_seq;
    state = const AsyncLoading<ChatFlavourAvailabilityPage>().copyWithPrevious(
      state,
    );
    final next = await AsyncValue.guard(
      () => ref.read(chatFlavourRepositoryProvider).fetch(),
    );
    if (seq != _seq) return;
    state = next;
  }

  void _replace(ChatFlavourAvailability row) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        items: [
          for (final item in current.items)
            item.itemCode == row.itemCode ? row : item,
        ],
      ),
    );
  }

  Future<void> setAvailability(String itemCode, String availability) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final before = current.items
        .where((row) => row.itemCode == itemCode)
        .firstOrNull;
    if (before == null || before.override == availability) return;
    final seq = (_itemSeq[itemCode] ?? 0) + 1;
    _itemSeq[itemCode] = seq;
    _replace(before.withOverride(availability));
    try {
      final saved = await ref
          .read(chatFlavourRepositoryProvider)
          .setAvailability(itemCode: itemCode, availability: availability);
      if (_itemSeq[itemCode] != seq) return;
      _replace(saved);
    } catch (_) {
      if (_itemSeq[itemCode] == seq) _replace(before);
      rethrow;
    }
  }
}

final chatFlavourAvailabilityProvider =
    AsyncNotifierProvider.autoDispose<
      ChatFlavourAvailabilityNotifier,
      ChatFlavourAvailabilityPage
    >(ChatFlavourAvailabilityNotifier.new);
