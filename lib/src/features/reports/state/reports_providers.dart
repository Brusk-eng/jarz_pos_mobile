import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reports_repository.dart';
import '../data/models/shipping_analytics.dart';
import '../data/models/inventory_intelligence.dart';
import '../data/models/product_analytics.dart';
import '../data/models/customer_analytics.dart';
import '../data/models/executive_overview.dart';
import '../data/models/b2b_sales_clients.dart';
import '../data/models/profit_and_loss.dart';
import '../data/models/ops_reports.dart';
import '../data/models/business_reports.dart';
import '../data/models/report_envelopes.dart';
import '../data/models/report_json.dart';
import '../data/models/revenue_dashboard.dart';

// ── Shared date range for the analytics dashboards ────────────────────────

/// An immutable, value-comparable inclusive date range used as the family key
/// for every analytics dashboard provider. Dates are date-only (time ignored).
@immutable
class ReportRange {
  final DateTime from;
  final DateTime to;

  const ReportRange({required this.from, required this.to});

  static DateTime _today(DateTime? now) {
    final n = now ?? DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Today only.
  factory ReportRange.today([DateTime? now]) {
    final t = _today(now);
    return ReportRange(from: t, to: t);
  }

  /// Yesterday only.
  factory ReportRange.yesterday([DateTime? now]) {
    final t = _today(now);
    final y = DateTime(t.year, t.month, t.day - 1);
    return ReportRange(from: y, to: y);
  }

  /// The current calendar month (1st → today).
  factory ReportRange.thisMonth([DateTime? now]) {
    final n = now ?? DateTime.now();
    return ReportRange(from: DateTime(n.year, n.month, 1), to: DateTime(n.year, n.month, n.day));
  }

  /// The previous calendar month, 1st to its last day.
  factory ReportRange.lastMonth([DateTime? now]) {
    final n = now ?? DateTime.now();
    // Day 0 of this month is the last day of the previous one.
    final end = DateTime(n.year, n.month, 0);
    return ReportRange(from: DateTime(end.year, end.month, 1), to: end);
  }

  /// The trailing [days] days ending today (inclusive).
  factory ReportRange.lastDays(int days, [DateTime? now]) {
    final today = _today(now);
    // Calendar arithmetic (not Duration) so a DST change never shifts a day.
    return ReportRange(
      from: DateTime(today.year, today.month, today.day - (days - 1)),
      to: today,
    );
  }

  /// The current calendar year (1 January → today).
  factory ReportRange.thisYear([DateTime? now]) {
    final t = _today(now);
    return ReportRange(from: DateTime(t.year, 1, 1), to: t);
  }

  String get fromIso => _fmt(from);
  String get toIso => _fmt(to);

  /// Number of calendar days covered, inclusive (≥ 1).
  int get dayCount {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays + 1;
  }

  /// The quick preset this range equals today, or null for a custom range.
  ReportRangePreset? matchingPreset([DateTime? now]) {
    for (final p in ReportRangePreset.values) {
      if (p.range(now) == this) return p;
    }
    return null;
  }

  ReportRange copyWith({DateTime? from, DateTime? to}) =>
      ReportRange(from: from ?? this.from, to: to ?? this.to);

  static String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  bool operator ==(Object other) =>
      other is ReportRange &&
      other.from.year == from.year &&
      other.from.month == from.month &&
      other.from.day == from.day &&
      other.to.year == to.year &&
      other.to.month == to.month &&
      other.to.day == to.day;

  @override
  int get hashCode => Object.hash(
        from.year,
        from.month,
        from.day,
        to.year,
        to.month,
        to.day,
      );

  @override
  String toString() => 'ReportRange($fromIso..$toIso)';
}

/// The quick ranges offered as chips in the date bar, in display order.
enum ReportRangePreset {
  today,
  yesterday,
  last7Days,
  thisMonth,
  lastMonth,
  last30Days,
  last90Days,
  thisYear;

  ReportRange range([DateTime? now]) => switch (this) {
        ReportRangePreset.today => ReportRange.today(now),
        ReportRangePreset.yesterday => ReportRange.yesterday(now),
        ReportRangePreset.last7Days => ReportRange.lastDays(7, now),
        ReportRangePreset.thisMonth => ReportRange.thisMonth(now),
        ReportRangePreset.lastMonth => ReportRange.lastMonth(now),
        ReportRangePreset.last30Days => ReportRange.lastDays(30, now),
        ReportRangePreset.last90Days => ReportRange.lastDays(90, now),
        ReportRangePreset.thisYear => ReportRange.thisYear(now),
      };
}

/// The date range currently selected in the reports date-range bar. Shared
/// across all dashboards so the picker state persists while navigating.
final reportRangeProvider = StateProvider<ReportRange>(
  (ref) => ReportRange.thisMonth(),
);

// ── Shared branch filter ──────────────────────────────────────────────────

/// The branch (POS Profile name) selected in the reports branch selector, or
/// null for all branches. Shared across reports like [reportRangeProvider].
final reportBranchProvider = StateProvider<String?>((ref) => null);

/// The branches the reports can be filtered by
/// (`ops_reports.get_report_branches`). Empty on failure, so the selector
/// degrades to "All branches" instead of erroring.
final reportBranchesProvider =
    FutureProvider.autoDispose<List<ReportBranch>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  try {
    return await repo.fetchReportBranches();
  } catch (e) {
    debugPrint('[reports] get_report_branches failed: $e');
    return const <ReportBranch>[];
  }
});

/// Range + branch: the family key for every report whose endpoint accepts a
/// branch. Value-comparable. Exposes the [ReportRange] getters so screens
/// that used to key on the range keep reading `fromIso` / `toIso`.
@immutable
class ReportQuery {
  final ReportRange range;

  /// POS Profile name, or null for all branches.
  final String? branch;

  const ReportQuery({required this.range, this.branch});

  DateTime get from => range.from;
  DateTime get to => range.to;
  String get fromIso => range.fromIso;
  String get toIso => range.toIso;

  /// Normalised branch: blank → null.
  String? get branchOrNull {
    final b = branch?.trim();
    return (b == null || b.isEmpty) ? null : b;
  }

  bool get hasBranch => branchOrNull != null;

  ReportQuery copyWith({ReportRange? range, String? branch, bool clearBranch = false}) =>
      ReportQuery(
        range: range ?? this.range,
        branch: clearBranch ? null : (branch ?? this.branch),
      );

  @override
  bool operator ==(Object other) =>
      other is ReportQuery && other.range == range && other.branchOrNull == branchOrNull;

  @override
  int get hashCode => Object.hash(range, branchOrNull);

  @override
  String toString() => 'ReportQuery(${range.fromIso}..${range.toIso}, ${branchOrNull ?? '*'})';
}

/// The current [ReportQuery] built from the shared range and branch.
final reportQueryProvider = Provider<ReportQuery>((ref) {
  return ReportQuery(
    range: ref.watch(reportRangeProvider),
    branch: ref.watch(reportBranchProvider),
  );
});

// ── Stock reports (keyed by branch; null = every warehouse) ───────────────

final finalProductsReportProvider =
    FutureProvider.autoDispose.family<JsonMap, String?>((ref, branch) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchFinalProductsReport(branch: branch);
});

/// Which quantities the Final Products table shows: what is on the shelf, or
/// what is left once the open (undispatched) orders take their jars.
enum FinalProductsStockView { inStock, afterOrders }

/// The Final Products "In stock | After orders" choice, kept for the session.
/// Defaults to After orders: "how many can I still sell?" is the question the
/// report is opened for. Only used when the server reports reservations.
final finalProductsStockViewProvider = StateProvider<FinalProductsStockView>(
  (ref) => FinalProductsStockView.afterOrders,
);

final materialsReportProvider =
    FutureProvider.autoDispose.family<JsonMap, String?>((ref, branch) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchMaterialsReport(branch: branch);
});

// ── Existing dashboards ───────────────────────────────────────────────────
//
// Each endpoint that gained keys in the overhaul has two providers:
//   * `xxxProvider`       → the original model (kept so existing screens and
//                           tests compile unchanged), and
//   * `xxxReportProvider` → an envelope with the original model as `.data`
//                           plus the new keys.
// They fetch independently; a screen should watch ONE of them (prefer the
// envelope), so there is never a double request.

final shippingAnalyticsProvider = FutureProvider.autoDispose
    .family<ShippingAnalytics, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return (await repo.fetchShippingReport(q)).data;
});

final shippingReportProvider = FutureProvider.autoDispose
    .family<ShippingReport, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchShippingReport(q);
});

final inventoryIntelligenceProvider = FutureProvider.autoDispose
    .family<InventoryIntelligence, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return (await repo.fetchInventoryReport(q)).data;
});

final inventoryReportProvider = FutureProvider.autoDispose
    .family<InventoryReport, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchInventoryReport(q);
});

final productAnalyticsProvider = FutureProvider.autoDispose
    .family<ProductAnalytics, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return (await repo.fetchProductReport(q)).data;
});

final productReportProvider = FutureProvider.autoDispose
    .family<ProductReport, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchProductReport(q);
});

final customerAnalyticsProvider = FutureProvider.autoDispose
    .family<CustomerAnalytics, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return (await repo.fetchCustomerReport(q)).data;
});

final customerReportProvider = FutureProvider.autoDispose
    .family<CustomerReport, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchCustomerReport(q);
});

final executiveOverviewProvider = FutureProvider.autoDispose
    .family<ExecutiveOverview, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchExecutiveOverview(
    dateFrom: q.fromIso,
    dateTo: q.toIso,
    branch: q.branchOrNull,
  );
});

/// B2B has no branch dimension, so it stays keyed by the range alone.
final b2bSalesClientsProvider = FutureProvider.autoDispose
    .family<B2bSalesAnalytics, ReportRange>((ref, range) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchB2bSalesClients(
    dateFrom: range.fromIso,
    dateTo: range.toIso,
  );
});

final profitAndLossProvider = FutureProvider.autoDispose
    .family<ProfitAndLoss, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return (await repo.fetchProfitAndLossReport(q)).data;
});

final profitAndLossReportProvider = FutureProvider.autoDispose
    .family<ProfitAndLossReport, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchProfitAndLossReport(q);
});

/// The revenue dashboard's own date range. It is daily-first, so it opens on
/// Today rather than on the shared [reportRangeProvider] (month to date by
/// default), and picking a period there never moves the other reports'
/// dates. Auto-disposed: opening the screen the next morning starts on that
/// day, not on a stale "today".
final revenueRangeProvider = StateProvider.autoDispose<ReportRange>(
  (ref) => ReportRange.today(),
);

/// The revenue dashboard's [ReportQuery]: its own range + the shared branch.
final revenueQueryProvider = Provider.autoDispose<ReportQuery>((ref) {
  return ReportQuery(
    range: ref.watch(revenueRangeProvider),
    branch: ref.watch(reportBranchProvider),
  );
});

/// The daily revenue dashboard for a range + branch
/// (keyed by [revenueQueryProvider] on the dashboard screen).
final revenueDashboardProvider = FutureProvider.autoDispose
    .family<RevenueDashboard, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchRevenueDashboard(q);
});

// ── Operations reports (ops_reports.py) ───────────────────────────────────

final dailyCloseProvider = FutureProvider.autoDispose
    .family<DailyClose, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchDailyClose(q);
});

final cashOverShortProvider = FutureProvider.autoDispose
    .family<CashOverShort, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchCashOverShort(q);
});

final fulfilmentSlaProvider = FutureProvider.autoDispose
    .family<FulfilmentSla, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchFulfilmentSla(q);
});

// ── Business reports (business_reports.py) ────────────────────────────────

/// The owner inputs for unit economics. Defaults match the backend's; the
/// unit-economics screen loads/saves them (shared_preferences) and writes
/// them here.
final unitEconomicsInputsProvider = StateProvider<UnitEconomicsInputs>(
  (ref) => const UnitEconomicsInputs(),
);

/// Family key for [unitEconomicsProvider]: range + owner inputs (no branch;
/// unit economics is company-wide).
@immutable
class UnitEconomicsQuery {
  final ReportRange range;
  final UnitEconomicsInputs inputs;

  const UnitEconomicsQuery({required this.range, required this.inputs});

  @override
  bool operator ==(Object other) =>
      other is UnitEconomicsQuery && other.range == range && other.inputs == inputs;

  @override
  int get hashCode => Object.hash(range, inputs);
}

/// The current [UnitEconomicsQuery] from the shared range + saved inputs.
final unitEconomicsQueryProvider = Provider<UnitEconomicsQuery>((ref) {
  return UnitEconomicsQuery(
    range: ref.watch(reportRangeProvider),
    inputs: ref.watch(unitEconomicsInputsProvider),
  );
});

final unitEconomicsProvider = FutureProvider.autoDispose
    .family<UnitEconomics, UnitEconomicsQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchUnitEconomics(range: q.range, inputs: q.inputs);
});

final promoPerformanceProvider = FutureProvider.autoDispose
    .family<PromoPerformance, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchPromoPerformance(q);
});

final stockAdjustmentsProvider = FutureProvider.autoDispose
    .family<StockAdjustments, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchStockAdjustments(q);
});

final labourCostProvider = FutureProvider.autoDispose
    .family<LabourCost, ReportQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchLabourCost(q);
});
