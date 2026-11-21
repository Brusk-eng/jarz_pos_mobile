/// Payload of `preview_shortage_count_fix` / `fix_shortage_by_count`.
///
/// Hand-written rather than freezed: it is read once, into one dialog.
class ShortageCountPlan {
  const ShortageCountPlan({
    this.productionAt = '',
    this.countAt = '',
    this.items = const [],
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
    return ShortageCountPlan(
      productionAt: (json['production_at'] ?? '').toString(),
      countAt: (json['count_at'] ?? '').toString(),
      items: items,
      skippedCount: ((json['skipped'] as List?) ?? const []).length,
      stockReconciliations: [
        for (final name in (json['stock_reconciliations'] as List?) ?? const [])
          name.toString(),
      ],
    );
  }

  /// "YYYY-MM-DD HH:MM:SS", server clock.
  final String productionAt;

  /// When the reconciliation posts: a few minutes before [productionAt].
  final String countAt;
  final List<ShortageCountItem> items;

  /// Short rows that cannot be fixed by a count (no source warehouse).
  final int skippedCount;
  final List<String> stockReconciliations;
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
