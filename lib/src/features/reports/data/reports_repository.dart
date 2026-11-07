import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../state/meta_ads_providers.dart' show MetaAdsQuery;
import '../state/reports_providers.dart' show ReportQuery, ReportRange;
import 'models/meta_ads_report.dart';
import 'models/shipping_analytics.dart';
import 'models/inventory_intelligence.dart';
import 'models/product_analytics.dart';
import 'models/customer_analytics.dart';
import 'models/executive_overview.dart';
import 'models/b2b_sales_clients.dart';
import 'models/profit_and_loss.dart';
import 'models/ops_reports.dart';
import 'models/business_reports.dart';
import 'models/report_envelopes.dart';
import 'models/revenue_dashboard.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ReportsRepository(dio);
});

class ReportsRepository {
  final Dio _dio;
  ReportsRepository(this._dio);

  /// Unwraps Frappe's `{ "message": ... }` envelope down to a Map.
  Map<String, dynamic> _asMap(Response response) {
    final data = response.data;
    if (data is Map && data['message'] is Map) {
      return Map<String, dynamic>.from(data['message'] as Map);
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return const <String, dynamic>{};
  }

  /// Like [_asMap] but throws on anything that is not a map, for the stock
  /// reports whose screens render the raw payload.
  Map<String, dynamic> _asMapStrict(Response response) {
    final data = response.data;
    if (data is Map && data['message'] is Map) {
      return Map<String, dynamic>.from(data['message'] as Map);
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception('Unexpected response format');
  }

  /// `{date_from, date_to}` plus `branch` only when one is selected.
  static Map<String, dynamic> _params(ReportQuery q) => {
        'date_from': q.fromIso,
        'date_to': q.toIso,
        if (q.branchOrNull != null) 'branch': q.branchOrNull,
      };

  static Map<String, dynamic> _branchOnly(String? branch) {
    final b = branch?.trim();
    return {if (b != null && b.isNotEmpty) 'branch': b};
  }

  // ── Stock reports ───────────────────────────────────────────────────────

  /// `get_final_products_report(branch=None)`; null branch = every warehouse.
  Future<Map<String, dynamic>> fetchFinalProductsReport({String? branch}) async {
    final response = await _dio.post(
      ApiEndpoints.getFinalProductsReport,
      data: _branchOnly(branch),
    );
    return _asMapStrict(response);
  }

  /// `get_materials_report(branch=None)`; null branch = every warehouse.
  Future<Map<String, dynamic>> fetchMaterialsReport({String? branch}) async {
    final response = await _dio.post(
      ApiEndpoints.getMaterialsReport,
      data: _branchOnly(branch),
    );
    return _asMapStrict(response);
  }

  // ── Branch list (ops_reports.get_report_branches) ──────────────────────

  Future<List<ReportBranch>> fetchReportBranches() async {
    final response = await _dio.post(ApiEndpoints.getReportBranches, data: {});
    final data = response.data;
    final payload = (data is Map && data.containsKey('message')) ? data['message'] : data;
    return ReportBranch.listFromPayload(payload);
  }

  // ── Analytics dashboards ────────────────────────────────────────────────

  /// Shipping Analytics. NOTE: this endpoint uses `from_date` / `to_date`
  /// (all other analytics endpoints use `date_from` / `date_to`).
  Future<ShippingReport> fetchShippingReport(ReportQuery q) async {
    final response = await _dio.post(
      ApiEndpoints.getShippingAnalytics,
      data: {
        'from_date': q.fromIso,
        'to_date': q.toIso,
        if (q.branchOrNull != null) 'branch': q.branchOrNull,
      },
    );
    return ShippingReport.fromJson(_asMap(response));
  }

  Future<ShippingAnalytics> fetchShippingAnalytics({
    required String fromDate,
    required String toDate,
    String? branch,
  }) async =>
      (await fetchShippingReport(ReportQuery(
        range: ReportRange(from: DateTime.parse(fromDate), to: DateTime.parse(toDate)),
        branch: branch,
      )))
          .data;

  Future<InventoryReport> fetchInventoryReport(ReportQuery q) async {
    final response = await _dio.post(
      ApiEndpoints.getInventoryAnalytics,
      data: _params(q),
    );
    return InventoryReport.fromJson(_asMap(response));
  }

  Future<InventoryIntelligence> fetchInventoryIntelligence({
    required String dateFrom,
    required String dateTo,
    String? branch,
  }) async =>
      (await fetchInventoryReport(_query(dateFrom, dateTo, branch))).data;

  Future<ProductReport> fetchProductReport(ReportQuery q) async {
    final response = await _dio.post(
      ApiEndpoints.getProductAnalytics,
      data: _params(q),
    );
    return ProductReport.fromJson(_asMap(response));
  }

  Future<ProductAnalytics> fetchProductAnalytics({
    required String dateFrom,
    required String dateTo,
    String? branch,
  }) async =>
      (await fetchProductReport(_query(dateFrom, dateTo, branch))).data;

  Future<CustomerReport> fetchCustomerReport(ReportQuery q) async {
    final response = await _dio.post(
      ApiEndpoints.getCustomerAnalytics,
      data: _params(q),
    );
    return CustomerReport.fromJson(_asMap(response));
  }

  Future<CustomerAnalytics> fetchCustomerAnalytics({
    required String dateFrom,
    required String dateTo,
    String? branch,
  }) async =>
      (await fetchCustomerReport(_query(dateFrom, dateTo, branch))).data;

  Future<ExecutiveOverview> fetchExecutiveOverview({
    required String dateFrom,
    required String dateTo,
    String? branch,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.getExecutiveOverview,
      data: _params(_query(dateFrom, dateTo, branch)),
    );
    return ExecutiveOverview.fromJson(_asMap(response));
  }

  /// B2B has no branch dimension.
  Future<B2bSalesAnalytics> fetchB2bSalesClients({
    required String dateFrom,
    required String dateTo,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.getB2bAnalytics,
      data: {'date_from': dateFrom, 'date_to': dateTo},
    );
    return B2bSalesAnalytics.fromJson(_asMap(response));
  }

  Future<ProfitAndLossReport> fetchProfitAndLossReport(ReportQuery q) async {
    final response = await _dio.post(
      ApiEndpoints.getProfitAndLoss,
      data: _params(q),
    );
    return ProfitAndLossReport.fromJson(_asMap(response));
  }

  /// `revenue_dashboard.get_revenue_dashboard`. The snapshot in the payload
  /// ignores the dates (it is always today-relative) but follows the branch.
  Future<RevenueDashboard> fetchRevenueDashboard(ReportQuery q) async {
    final response = await _dio.post(
      ApiEndpoints.getRevenueDashboard,
      data: _params(q),
    );
    return RevenueDashboard.fromJson(_asMap(response));
  }

  Future<ProfitAndLoss> fetchProfitAndLoss({
    required String dateFrom,
    required String dateTo,
    String? branch,
  }) async =>
      (await fetchProfitAndLossReport(_query(dateFrom, dateTo, branch))).data;

  // ── Operations reports (ops_reports.py) ─────────────────────────────────

  Future<DailyClose> fetchDailyClose(ReportQuery q) async {
    final response = await _dio.post(ApiEndpoints.getDailyClose, data: _params(q));
    return DailyClose.fromJson(_asMap(response));
  }

  Future<CashOverShort> fetchCashOverShort(ReportQuery q) async {
    final response = await _dio.post(ApiEndpoints.getCashOverShort, data: _params(q));
    return CashOverShort.fromJson(_asMap(response));
  }

  Future<FulfilmentSla> fetchFulfilmentSla(ReportQuery q) async {
    final response = await _dio.post(ApiEndpoints.getFulfilmentSla, data: _params(q));
    return FulfilmentSla.fromJson(_asMap(response));
  }

  // ── Business reports (business_reports.py) ──────────────────────────────

  /// Company-wide: no branch. [inputs] are the owner's assumptions.
  Future<UnitEconomics> fetchUnitEconomics({
    required ReportRange range,
    UnitEconomicsInputs inputs = const UnitEconomicsInputs(),
  }) async {
    final response = await _dio.post(
      ApiEndpoints.getUnitEconomics,
      data: {
        'date_from': range.fromIso,
        'date_to': range.toIso,
        ...inputs.toParams(),
      },
    );
    return UnitEconomics.fromJson(_asMap(response));
  }

  Future<PromoPerformance> fetchPromoPerformance(ReportQuery q) async {
    final response = await _dio.post(ApiEndpoints.getPromoPerformance, data: _params(q));
    return PromoPerformance.fromJson(_asMap(response));
  }

  Future<StockAdjustments> fetchStockAdjustments(ReportQuery q) async {
    final response = await _dio.post(ApiEndpoints.getStockAdjustments, data: _params(q));
    return StockAdjustments.fromJson(_asMap(response));
  }

  Future<LabourCost> fetchLabourCost(ReportQuery q) async {
    final response = await _dio.post(ApiEndpoints.getLabourCost, data: _params(q));
    return LabourCost.fromJson(_asMap(response));
  }

  // ── Marketing (meta_ads.py) ─────────────────────────────────────────────

  /// `meta_ads.get_ads_report`. No branch dimension. [refresh] sends
  /// `refresh=1`, which makes the server skip its 15-minute cache and ask
  /// Meta again (pull-to-refresh only — normal loads use the cache).
  Future<MetaAdsReport> fetchMetaAdsReport(
    MetaAdsQuery q, {
    bool refresh = false,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.getAdsReport,
      data: {
        'level': q.level.apiValue,
        'date_from': q.range.fromIso,
        'date_to': q.range.toIso,
        if (q.campaignId != null) 'campaign_id': q.campaignId,
        if (q.adsetId != null) 'adset_id': q.adsetId,
        if (refresh) 'refresh': 1,
      },
    );
    return MetaAdsReport.fromJson(_asMap(response));
  }

  static ReportQuery _query(String dateFrom, String dateTo, String? branch) => ReportQuery(
        range: ReportRange(from: DateTime.parse(dateFrom), to: DateTime.parse(dateTo)),
        branch: branch,
      );
}
