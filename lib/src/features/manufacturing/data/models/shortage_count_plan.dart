/// Payload of `preview_shortage_count_fix` / `fix_shortage_by_count`.
///
/// Hand-written rather than freezed: it is read once, into one dialog.
class ShortageCountPlan {
  const ShortageCountPlan({
    this.productionAt = '',
    this.countAt = '',
    this.latestCountAt = '',
    this.items = const [],
    this.laterCounts = const [],
    this.skippedCount = 0,
    this.stockReconciliations = const [],
  });

  factory ShortageCountPlan.fromJson(Map<String, dynamic> json) {
    final items = <ShortageCountItem>[];
    for (final row in (json['items'] as List?) ?? const []) {
      if (row is Map) {
        items.add(ShortageCountItem.fromJson(Map<String, dynamic>.from(row)));
      }
    }
    final countAt = (json['count_at'] ?? '').toString();
    return ShortageCountPlan(
      productionAt: (json['production_at'] ?? '').toString(),
      countAt: countAt,
      // Older servers do not send it: the count moment was the only one.
      latestCountAt: (json['latest_count_at'] ?? countAt).toString(),
      items: items,
      laterCounts: [
        for (final row in (json['later_counts'] as List?) ?? const [])
          if (row is Map)
            LaterStockCount.fromJson(Map<String, dynamic>.from(row)),
      ],
      skippedCount: ((json['skipped'] as List?) ?? const []).length,
      stockReconciliations: [
        for (final name in (json['stock_reconciliations'] as List?) ?? const [])
          name.toString(),
      ],
    );
  }

  /// "YYYY-MM-DD HH:MM:SS", server clock.
  final String productionAt;

  /// When the reconciliation posts: a few minutes before [productionAt]
  /// unless the user chose an earlier moment.
  final String countAt;

  /// The latest moment the count may be dated (the default [countAt]).
  final String latestCountAt;
  final List<ShortageCountItem> items;

  /// Stock counts of these items between [countAt] and production. Each
  /// would erase the addition, so the server refuses to post while any exist.
  final List<LaterStockCount> laterCounts;

  /// Short rows that cannot be fixed by a count (no source warehouse).
  final int skippedCount;
  final List<String> stockReconciliations;
}

class LaterStockCount {
  const LaterStockCount({
    required this.itemCode,
    required this.warehouse,
    required this.stockReconciliation,
    required this.postedAt,
  });

  factory LaterStockCount.fromJson(Map<String, dynamic> json) =>
      LaterStockCount(
        itemCode: (json['item_code'] ?? '').toString(),
        warehouse: (json['warehouse'] ?? '').toString(),
        stockReconciliation: (json['stock_reconciliation'] ?? '').toString(),
        postedAt: (json['posted_at'] ?? '').toString(),
      );

  final String itemCode;
  final String warehouse;
  final String stockReconciliation;
  final String postedAt;
}

class ShortageCountItem {
  const ShortageCountItem({
    required this.itemCode,
    required this.itemName,
    required this.uom,
    required this.warehouse,
    required this.missingQty,
    required this.currentQty,
    required this.countedQty,
  });

  factory ShortageCountItem.fromJson(Map<String, dynamic> json) {
    double num0(Object? v) => (v is num) ? v.toDouble() : 0.0;
    final code = (json['item_code'] ?? '').toString();
    return ShortageCountItem(
      itemCode: code,
      itemName: (json['item_name'] ?? code).toString(),
      uom: (json['uom'] ?? '').toString(),
      warehouse: (json['warehouse'] ?? '').toString(),
      missingQty: num0(json['missing_qty']),
      currentQty: num0(json['current_qty']),
      countedQty: num0(json['counted_qty']),
    );
  }

  final String itemCode;
  final String itemName;
  final String uom;
  final String warehouse;
  final double missingQty;
  final double currentQty;
  final double countedQty;
}
