// Flavour availability for the AI chat drafts: `get_flavour_availability`
// and `set_flavour_availability`.
//
// The drafts hide a flavour when the branches' stock is under `min_stock`
// jars. Stock lags reality (jars on the route, or in a branch but not moved
// in the system), so a moderator can force a flavour Available or Paused, or
// put it back on Auto (follow stock).
//
// Plain classes with lenient `fromJson`, like the rest of `chat_models.dart`.

import 'chat_models.dart';

/// Wire values of `override` / `availability` / `auto` / `effective`.
abstract final class ChatFlavourAvailabilityValues {
  static const auto = 'auto';
  static const available = 'available';
  static const paused = 'paused';

  /// The three choices of the segmented control, in display order.
  static const choices = [auto, available, paused];

  /// [raw] as one of the three values; anything else reads as [fallback].
  static String normalize(dynamic raw, {String fallback = auto}) {
    final text = chatString(raw).trim().toLowerCase();
    return choices.contains(text) ? text : fallback;
  }
}

/// One flavour + size row.
class ChatFlavourAvailability {
  final String itemCode;
  final String name;
  final String nameAr;
  final String size;
  final String sizeAr;

  /// Jars across the branches; null for a non-stock item.
  final double? stock;

  /// What stock alone says: `available` / `paused`.
  final String auto;

  /// The moderator's choice: `auto` / `available` / `paused`.
  final String override;

  /// What the AI uses: `available` / `paused`.
  final String effective;

  const ChatFlavourAvailability({
    required this.itemCode,
    this.name = '',
    this.nameAr = '',
    this.size = '',
    this.sizeAr = '',
    this.stock,
    this.auto = ChatFlavourAvailabilityValues.available,
    this.override = ChatFlavourAvailabilityValues.auto,
    this.effective = ChatFlavourAvailabilityValues.available,
  });

  factory ChatFlavourAvailability.fromJson(dynamic raw) {
    final json = raw is Map ? raw : const {};
    final auto = ChatFlavourAvailabilityValues.normalize(
      json['auto'],
      fallback: ChatFlavourAvailabilityValues.available,
    );
    final override = ChatFlavourAvailabilityValues.normalize(json['override']);
    final effectiveRaw = ChatFlavourAvailabilityValues.normalize(
      json['effective'],
      fallback: '',
    );
    return ChatFlavourAvailability(
      itemCode: chatString(json['item_code']),
      name: chatString(json['name']),
      nameAr: chatString(json['name_ar']),
      size: chatString(json['size']),
      sizeAr: chatString(json['size_ar']),
      stock: chatNullableDouble(json['stock']),
      auto: auto,
      override: override,
      effective:
          effectiveRaw == ChatFlavourAvailabilityValues.available ||
              effectiveRaw == ChatFlavourAvailabilityValues.paused
          ? effectiveRaw
          : effectiveFor(override, auto),
    );
  }

  /// What the AI uses for [override] when stock says [auto].
  static String effectiveFor(String override, String auto) =>
      override == ChatFlavourAvailabilityValues.auto ? auto : override;

  bool get isAvailable => effective == ChatFlavourAvailabilityValues.available;

  /// Whether a moderator set this row by hand.
  bool get isManual => override != ChatFlavourAvailabilityValues.auto;

  /// The row as it will read once [availability] is saved (optimistic).
  ChatFlavourAvailability withOverride(String availability) =>
      ChatFlavourAvailability(
        itemCode: itemCode,
        name: name,
        nameAr: nameAr,
        size: size,
        sizeAr: sizeAr,
        stock: stock,
        auto: auto,
        override: availability,
        effective: effectiveFor(availability, auto),
      );
}

/// `get_flavour_availability` answer.
class ChatFlavourAvailabilityPage {
  final List<ChatFlavourAvailability> items;

  /// Jars under which stock pauses a flavour.
  final int minStock;

  const ChatFlavourAvailabilityPage({
    this.items = const <ChatFlavourAvailability>[],
    this.minStock = 3,
  });

  factory ChatFlavourAvailabilityPage.fromJson(dynamic raw) {
    final json = raw is Map ? raw : const {};
    final items = json['items'];
    return ChatFlavourAvailabilityPage(
      items: items is List
          ? items
                .whereType<Map>()
                .map(ChatFlavourAvailability.fromJson)
                .where((row) => row.itemCode.isNotEmpty)
                .toList(growable: false)
          : const <ChatFlavourAvailability>[],
      minStock: chatInt(json['min_stock'], fallback: 3),
    );
  }

  ChatFlavourAvailabilityPage copyWith({
    List<ChatFlavourAvailability>? items,
  }) => ChatFlavourAvailabilityPage(
    items: items ?? this.items,
    minStock: minStock,
  );

  /// [items] by size: Medium first, then Large, then any other size in the
  /// order it first appears. Rows keep the server's order inside a size.
  List<MapEntry<String, List<ChatFlavourAvailability>>> get bySize {
    final groups = <String, List<ChatFlavourAvailability>>{};
    for (final row in items) {
      groups.putIfAbsent(row.size, () => []).add(row);
    }
    int rank(String size) => switch (size.trim().toLowerCase()) {
      'medium' => 0,
      'large' => 1,
      _ => 2,
    };
    final keys = groups.keys.toList();
    final order = {for (var i = 0; i < keys.length; i++) keys[i]: i};
    keys.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : order[a]!.compareTo(order[b]!);
    });
    return [for (final key in keys) MapEntry(key, groups[key]!)];
  }
}
