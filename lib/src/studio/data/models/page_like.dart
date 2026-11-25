/// What every generated `<Item>Page` and `<Item>Sync` class offers, so paging
/// helpers need not know the item type.
abstract interface class PageLike<T> {
  List<T> get items;

  /// Opaque cursor for the next page, null at the end.
  String? get next;
}
