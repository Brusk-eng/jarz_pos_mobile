import 'customer_analytics.dart';
import 'customer_segments.dart';
import 'inventory_intelligence.dart';
import 'product_analytics.dart';
import 'profit_and_loss.dart';
import 'report_json.dart';
import 'shipping_analytics.dart';

// Envelopes for the existing analytics endpoints that gained keys in the
// reports overhaul (spec C4–C10).
//
// The original models ([InventoryIntelligence], [CustomerAnalytics], ...) are
// Freezed and drop unknown keys; regenerating them needs build_runner, which
// this feature avoids. Each envelope keeps the original model untouched as
// [data] and parses the new keys alongside it from the same payload, so one
// network call feeds both. [raw] is the full payload for anything else.

// ── Inventory (+ velocity restock list, C6) ───────────────────────────────

enum RestockStatus {
  critical,
  watch,
  slow,
  overstock,
  unknown;

  static RestockStatus parse(Object? v) =>
      switch (ReportJson.str(v).toLowerCase()) {
        'critical' => RestockStatus.critical,
        'watch' || 'watch_list' => RestockStatus.watch,
        'slow' || 'slow_mover' || 'slow_movers' => RestockStatus.slow,
        'overstock' || 'overstocked' => RestockStatus.overstock,
        _ => RestockStatus.unknown,
      };
}

/// One row of `get_inventory_analytics().restock`: the velocity-based
/// restock view, per branch warehouse when a branch is selected.
class RestockRow {
  final String itemCode;
  final String itemName;
  final String itemGroup;
  final double stock;
  final String uom;

  /// Average units sold per day over the last 30 days.
  final double velocity30d;

  /// Days of stock left at [velocity30d]; null when nothing sells.
  final double? daysCover;
  final RestockStatus status;
  final double suggestedQty;

  /// Stock value at the warehouse's Bin valuation (reports overhaul C6).
  final double stockValue;
  final double velocity60d;

  /// Raw trend label ("Accelerating", "Stable", ...); localise on display.
  final String trend;

  /// Last sale date (ISO), null when the item never sold.
  final String? lastSale;

  const RestockRow({
    required this.itemCode,
    this.itemName = '',
    this.itemGroup = '',
    this.stock = 0,
    this.uom = '',
    this.velocity30d = 0,
    this.daysCover,
    this.status = RestockStatus.unknown,
    this.suggestedQty = 0,
    this.stockValue = 0,
    this.velocity60d = 0,
    this.trend = '',
    this.lastSale,
  });

  String get displayName => itemName.isNotEmpty ? itemName : itemCode;

  factory RestockRow.fromJson(JsonMap j) => RestockRow(
    itemCode: ReportJson.str(j['item_code']),
    itemName: ReportJson.str(j['item_name']),
    itemGroup: ReportJson.str(j['item_group']),
    stock: ReportJson.dbl(j['stock']),
    uom: ReportJson.str(j['uom']),
    velocity30d: ReportJson.dbl(j['velocity_30d']),
    daysCover: ReportJson.dblOrNull(j['days_cover']),
    status: RestockStatus.parse(j['status']),
    suggestedQty: ReportJson.dbl(j['suggested_qty']),
    stockValue: ReportJson.dbl(j['stock_value']),
    velocity60d: ReportJson.dbl(j['velocity_60d']),
    trend: ReportJson.str(j['trend']),
    lastSale: ReportJson.strOrNull(j['last_sale']),
  );
}

class InventoryReport {
  final InventoryIntelligence data;
  final List<RestockRow> restock;
  final JsonMap raw;

  const InventoryReport({
    required this.data,
    this.restock = const [],
    this.raw = const {},
  });

  factory InventoryReport.fromJson(JsonMap j) => InventoryReport(
    data: InventoryIntelligence.fromJson(j),
    restock: ReportJson.listOf(j['restock'], RestockRow.fromJson),
    raw: j,
  );

  List<RestockRow> restockWith(RestockStatus status) =>
      restock.where((r) => r.status == status).toList(growable: false);
}

// ── Customers (+ segment summary, C7) ─────────────────────────────────────

class CustomerReport {
  final CustomerAnalytics data;

  /// What `segmentation.get_segment_summary` returns, inlined. Rows with
  /// `pseudo` set (e.g. "Regular") overlap real segments: never sum them and
  /// never send them as a manual segment.
  final List<SegmentSummaryRow> segmentsSummary;
  final JsonMap raw;

  const CustomerReport({
    required this.data,
    this.segmentsSummary = const [],
    this.raw = const {},
  });

  factory CustomerReport.fromJson(JsonMap j) => CustomerReport(
    data: CustomerAnalytics.fromJson(j),
    segmentsSummary: ReportJson.listOf(
      j['segments_summary'],
      SegmentSummaryRow.fromJson,
    ),
    raw: j,
  );

  /// Real (non-pseudo) segments only.
  List<SegmentSummaryRow> get realSegments =>
      segmentsSummary.where((s) => !s.pseudo).toList(growable: false);
}

// ── Products (+ actual-cost coverage, C4) ─────────────────────────────────

/// Where a product row's cost came from (`cost_source`).
enum ProductCostSource {
  actual,
  bom,
  none,
  unknown;

  static ProductCostSource parse(Object? v) =>
      switch (ReportJson.str(v).trim().toLowerCase()) {
        'actual' => ProductCostSource.actual,
        'bom' => ProductCostSource.bom,
        'none' => ProductCostSource.none,
        _ => ProductCostSource.unknown,
      };
}

/// Revenue split by cost source (`cost_sources {actual, bom, none}`).
class ProductCostSources {
  final double actual;
  final double bom;
  final double none;

  const ProductCostSources({this.actual = 0, this.bom = 0, this.none = 0});

  double get total => actual + bom + none;

  static ProductCostSources? fromJson(Object? v) {
    if (v is! Map) return null;
    final j = ReportJson.map(v);
    return ProductCostSources(
      actual: ReportJson.dbl(j['actual']),
      bom: ReportJson.dbl(j['bom']),
      none: ReportJson.dbl(j['none']),
    );
  }
}

class ProductReport {
  final ProductAnalytics data;

  /// Share of revenue (0–100) whose cost came from real cost of goods; null
  /// on a backend that predates the field. Row-level `cost_source`
  /// (`actual` | `bom` | `none`), `actual_cost_per_unit` and
  /// `cost_coverage_pct` stay in the [JsonMap] rows of [data]; read them
  /// with [costSourceOf].
  final double? costCoveragePct;

  /// Revenue per cost source; null on an older backend.
  final ProductCostSources? costSources;
  final JsonMap raw;

  const ProductReport({
    required this.data,
    this.costCoveragePct,
    this.costSources,
    this.raw = const {},
  });

  factory ProductReport.fromJson(JsonMap j) => ProductReport(
    data: ProductAnalytics.fromJson(j),
    costCoveragePct: ReportJson.dblOrNull(
      j['cost_coverage_pct'] ?? ReportJson.map(j['summary'])['cost_coverage_pct'],
    ),
    costSources: ProductCostSources.fromJson(j['cost_sources']),
    raw: j,
  );

  /// The `cost_source` of one row of [ProductAnalytics.topProducts].
  static ProductCostSource costSourceOf(JsonMap row) =>
      ProductCostSource.parse(row['cost_source']);
}

// ── Shipping (+ unsettled balance date, C10) ──────────────────────────────

class ShippingReport {
  final ShippingAnalytics data;

  /// `YYYY-MM-DD` the unsettled courier balances are computed as of (the
  /// range end); null on an older backend.
  final String? unsettledAsOf;
  final JsonMap raw;

  const ShippingReport({
    required this.data,
    this.unsettledAsOf,
    this.raw = const {},
  });

  factory ShippingReport.fromJson(JsonMap j) => ShippingReport(
    data: ShippingAnalytics.fromJson(j),
    unsettledAsOf: ReportJson.strOrNull(j['unsettled_as_of']),
    raw: j,
  );
}

// ── Profit & loss (+ branch split, C9) ────────────────────────────────────

class PnlBranchRow {
  final String branch;
  final int orders;
  final double revenue;
  final double cogs;
  final double grossProfit;
  final double shippingIncome;

  /// Backend-computed margin (0–100); null on an older backend, where
  /// [grossMarginPct] derives it from [grossProfit] / [revenue].
  final double? marginPct;

  /// Share (0–100) of this branch's lines with a real cost of goods; null
  /// when the backend does not send it.
  final double? cogsCoveragePct;

  const PnlBranchRow({
    required this.branch,
    this.orders = 0,
    this.revenue = 0,
    this.cogs = 0,
    this.grossProfit = 0,
    this.shippingIncome = 0,
    this.marginPct,
    this.cogsCoveragePct,
  });

  /// Gross margin 0–100; 0 when there was no revenue.
  double get grossMarginPct =>
      marginPct ?? (revenue == 0 ? 0 : grossProfit * 100 / revenue);

  factory PnlBranchRow.fromJson(JsonMap j) => PnlBranchRow(
    branch: ReportJson.str(j['branch']),
    orders: ReportJson.integer(j['orders']),
    revenue: ReportJson.dbl(j['revenue']),
    cogs: ReportJson.dbl(j['cogs']),
    grossProfit: ReportJson.dbl(j['gross_profit']),
    shippingIncome: ReportJson.dbl(j['shipping_income']),
    marginPct: ReportJson.dblOrNull(j['gross_margin_pct']),
    cogsCoveragePct: ReportJson.dblOrNull(j['cogs_coverage_pct']),
  );
}

class ProfitAndLossReport {
  final ProfitAndLoss data;

  /// Invoice-based split per branch (COGS from `incoming_rate`).
  final List<PnlBranchRow> branches;
  final JsonMap raw;

  const ProfitAndLossReport({
    required this.data,
    this.branches = const [],
    this.raw = const {},
  });

  factory ProfitAndLossReport.fromJson(JsonMap j) => ProfitAndLossReport(
    data: ProfitAndLoss.fromJson(j),
    branches: ReportJson.listOf(j['branches'], PnlBranchRow.fromJson),
    raw: j,
  );
}

// ── Stock reports (+ stock value totals, C8) ──────────────────────────────

/// `totals: {qty, stock_value}` at group or report level of
/// `get_final_products_report` / `get_materials_report`. The reports
/// themselves stay raw maps (their shape is table-like).
class StockReportTotals {
  final double qty;
  final double stockValue;

  /// Jars held by open (undispatched) orders. Final Products only, and a
  /// newer key: 0 when the server does not send it.
  final double reservedQty;

  const StockReportTotals({
    this.qty = 0,
    this.stockValue = 0,
    this.reservedQty = 0,
  });

  /// What is left once the open orders are dispatched.
  double get availableQty => qty - reservedQty;

  factory StockReportTotals.fromJson(Object? v) {
    final j = ReportJson.map(v);
    return StockReportTotals(
      qty: ReportJson.dbl(j['qty']),
      stockValue: ReportJson.dbl(j['stock_value']),
      reservedQty: ReportJson.dbl(j['reserved_qty']),
    );
  }
}
