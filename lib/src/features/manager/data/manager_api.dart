import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/frappe_error_message.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/order_display_id.dart';

final managerApiProvider = Provider<ManagerApi>((ref) {
  final dio = ref.read(dioProvider);
  return ManagerApi(dio);
});

class ManagerApi {
  final Dio _dio;
  ManagerApi(this._dio);

  Future<DashboardSummary> getSummary({String? company}) async {
    final resp = await _dio.get(
      ApiEndpoints.getManagerDashboardSummary,
      queryParameters: {if (company != null) 'company': company},
    );
    final data = resp.data is String ? json.decode(resp.data) : resp.data;
    return DashboardSummary.fromJson(data['message'] ?? data);
  }

  Future<List<TransferTargetBranch>> getTransferTargetBranches() async {
    try {
      final resp = await _dio.get(ApiEndpoints.getManagerTransferTargetBranches);
      final data = resp.data is String ? json.decode(resp.data) : resp.data;
      final payload = data is Map<String, dynamic> ? (data['message'] ?? data) : data;

      if (payload is Map<String, dynamic> && payload['success'] == false) {
        throw Exception(
          extractFrappeErrorMessage(
            payload,
            fallback: 'Failed to load transfer branches',
          ),
        );
      }

      final rawBranches = payload is List<dynamic>
          ? payload
          : payload is Map<String, dynamic>
              ? ((payload['branches'] ?? payload['data']) as List<dynamic>? ??
                  const <dynamic>[])
              : const <dynamic>[];

      return rawBranches
          .whereType<Map>()
          .map(
            (entry) => TransferTargetBranch.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .where((branch) => branch.name.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw mapFrappeError(
        error,
        fallback: 'Failed to load transfer branches',
      );
    }
  }

  Future<ManagerOrdersPage> getOrders({
    String? branch,
    String? state,
    String? channel,
    int start = 0,
    int limit = 20,
  }) async {
    final resp = await _dio.get(
      ApiEndpoints.getManagerOrders,
      queryParameters: {
        if (branch != null) 'branch': branch,
        if (state != null) 'state': state,
        if (channel != null) 'channel': channel,
        'start': start,
        'limit': limit,
      },
    );
    final data = resp.data is String ? json.decode(resp.data) : resp.data;
    final payload = data['message'] ?? data;
    final list = payload['invoices'] as List<dynamic>? ?? const [];
    final invoices =
        list.map((j) => ManagerInvoice.fromJson(j as Map<String, dynamic>)).toList();
    return ManagerOrdersPage(
      invoices: invoices,
      hasMore: payload['has_more'] == true,
    );
  }

  Future<List<String>> getStates() async {
    final resp = await _dio.get(
      ApiEndpoints.getManagerStates,
    );
    final data = resp.data is String ? json.decode(resp.data) : resp.data;
    final list = (data['message'] ?? data)['states'] as List<dynamic>? ?? const [];
    return list.map((e) => e.toString()).toList();
  }

  Future<void> updateInvoiceBranch({required String invoiceId, required String newBranch}) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.updateInvoiceBranch,
        data: {'invoice_id': invoiceId, 'new_branch': newBranch},
      );
      final data = resp.data is String ? json.decode(resp.data) : resp.data;
      final message = data is Map<String, dynamic> ? (data['message'] ?? data) : data;
      if (!((message is Map<String, dynamic>) && message['success'] == true)) {
        throw Exception(
          extractFrappeErrorMessage(
            message,
            fallback: 'Failed to transfer branch',
          ),
        );
      }
    } on DioException catch (error) {
      throw mapFrappeError(error, fallback: 'Failed to transfer branch');
    }
  }

  Future<List<CustomShippingRequest>> getPendingCustomShippingRequests() async {
    final resp = await _dio.get(ApiEndpoints.getPendingCustomShippingRequests);
    final data = resp.data is String ? json.decode(resp.data) : resp.data;
    final msg = data['message'] ?? data;
    final ok = (msg is Map<String, dynamic>) ? (msg['success'] == true) : false;
    if (!ok) {
      throw Exception('Failed to fetch pending custom shipping requests');
    }
    final list = (msg['data'] as List<dynamic>? ?? const []);
    return list
        .map((j) => CustomShippingRequest.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveCustomShipping(String requestName) async {
    final resp = await _dio.post(
      ApiEndpoints.approveCustomShipping,
      data: {'request_name': requestName},
    );
    final data = resp.data is String ? json.decode(resp.data) : resp.data;
    final msg = data['message'] ?? data;
    if (!((msg is Map<String, dynamic>) && msg['success'] == true)) {
      throw Exception((msg is Map<String, dynamic>) ? (msg['message'] ?? 'Failed to approve') : 'Failed to approve');
    }
  }

  Future<void> rejectCustomShipping(String requestName, {String reason = ''}) async {
    final resp = await _dio.post(
      ApiEndpoints.rejectCustomShipping,
      data: {'request_name': requestName, 'rejection_reason': reason},
    );
    final data = resp.data is String ? json.decode(resp.data) : resp.data;
    final msg = data['message'] ?? data;
    if (!((msg is Map<String, dynamic>) && msg['success'] == true)) {
      throw Exception((msg is Map<String, dynamic>) ? (msg['message'] ?? 'Failed to reject') : 'Failed to reject');
    }
  }
}

class DashboardSummary {
  final List<BranchBalance> branches;
  final double totalBalance;
  DashboardSummary({required this.branches, required this.totalBalance});
  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
        branches: (json['branches'] as List<dynamic>? ?? const [])
            .map((e) => BranchBalance.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0.0,
      );
}

class TransferTargetBranch {
  final String name;
  final String title;

  const TransferTargetBranch({required this.name, required this.title});

  factory TransferTargetBranch.fromJson(Map<String, dynamic> json) =>
      TransferTargetBranch(
        name: (json['name'] ?? '').toString(),
        title: (json['title'] ?? json['name'] ?? '').toString(),
      );
}

class BranchBalance {
  final String name;
  final String title;
  final String? cashAccount;
  final double balance;
  BranchBalance({required this.name, required this.title, required this.cashAccount, required this.balance});
  factory BranchBalance.fromJson(Map<String, dynamic> json) => BranchBalance(
        name: json['name'] as String,
        title: (json['title'] as String?) ?? json['name'] as String,
        cashAccount: json['cash_account'] as String?,
        balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      );
}

/// One page of the manager's recent orders plus whether more exist.
class ManagerOrdersPage {
  final List<ManagerInvoice> invoices;
  final bool hasMore;
  const ManagerOrdersPage({required this.invoices, required this.hasMore});
}

class ManagerInvoice {
  final String name;
  final int? wooOrderId;
  final String customer;
  final String customerName;
  final String postingDate;
  final String postingTime;
  final double grandTotal;
  final double netTotal;
  final String status;
  final String branch;
  /// Order Purpose, e.g. "B2B Supply", "Standard", "Employee".
  final String orderPurpose;
  /// True for wholesale (B2B Supply) orders.
  bool get isB2b => orderPurpose == 'B2B Supply';
  // convenience for UI
  String get branchName => branch;
  /// What the dashboard labels this order with.
  String get displayId => orderDisplayId(name, wooOrderId: wooOrderId);
  ManagerInvoice({
    required this.name,
    required this.customer,
    required this.customerName,
    required this.postingDate,
    required this.postingTime,
    required this.grandTotal,
    required this.netTotal,
    required this.status,
    required this.branch,
    this.orderPurpose = '',
    this.wooOrderId,
  });
  factory ManagerInvoice.fromJson(Map<String, dynamic> json) => ManagerInvoice(
        name: json['name'] as String,
        wooOrderId: normalizeWooOrderId(json['woo_order_id']),
        customer: json['customer'] as String,
        customerName: (json['customer_name'] as String?) ?? (json['customer'] as String),
        postingDate: json['posting_date'] as String,
        postingTime: json['posting_time'] as String,
        grandTotal: (json['grand_total'] as num).toDouble(),
        netTotal: (json['net_total'] as num).toDouble(),
        status: json['status'] as String,
        branch: json['branch'] as String,
        orderPurpose: (json['order_purpose'] ?? '').toString(),
      );
}

class CustomShippingRequest {
  final String name;
  final String invoice;
  final String customerName;
  final String territory;
  final String? territoryNameAr;
  final double originalAmount;
  final double requestedAmount;
  final String reason;
  final String requestedBy;
  final String requestedOn;

  CustomShippingRequest({
    required this.name,
    required this.invoice,
    required this.customerName,
    required this.territory,
    this.territoryNameAr,
    required this.originalAmount,
    required this.requestedAmount,
    required this.reason,
    required this.requestedBy,
    required this.requestedOn,
  });

  factory CustomShippingRequest.fromJson(Map<String, dynamic> json) {
    return CustomShippingRequest(
      name: (json['name'] ?? '').toString(),
      invoice: (json['invoice'] ?? '').toString(),
      customerName: (json['customer_name'] ?? '').toString(),
      territory: (json['territory'] ?? '').toString(),
      territoryNameAr: json['territory_name_ar']?.toString(),
      originalAmount: (json['original_amount'] as num?)?.toDouble() ?? 0,
      requestedAmount: (json['requested_amount'] as num?)?.toDouble() ?? 0,
      reason: (json['reason'] ?? '').toString(),
      requestedBy: (json['requested_by'] ?? '').toString(),
      requestedOn: (json['requested_on'] ?? '').toString(),
    );
  }
}
