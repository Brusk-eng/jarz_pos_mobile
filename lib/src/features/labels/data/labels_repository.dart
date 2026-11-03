import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../models/label_models.dart';

final labelsRepositoryProvider = Provider<LabelsRepository>((ref) {
  return LabelsRepository(ref.watch(dioProvider));
});

/// Warehouses a label can live in. Small and stable, so it is fetched once and
/// cached for the life of the provider rather than on every sheet open.
final labelStorageLocationsProvider =
    FutureProvider<List<LabelStorageLocation>>((ref) async {
  return ref.watch(labelsRepositoryProvider).getStorageLocations();
});

/// HTTP repository for `jarz_pos.api.labels.*`. Every call is gated server-side
/// on B2B or manager access and throws otherwise; billing a batch additionally
/// requires the manager tier.
class LabelsRepository {
  final Dio _dio;
  LabelsRepository(this._dio);

  /// Unwraps Frappe's `{ "message": ... }` envelope.
  dynamic _unwrap(Response response) {
    final data = response.data;
    if (data is Map && data.containsKey('message')) return data['message'];
    return data;
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      Map<String, dynamic>.from(value as Map);

  Future<LabelDashboard> getDashboard({
    String? customer,
    bool onlyAttention = false,
    bool includeUntracked = true,
  }) async {
    final response = await _dio.post(ApiEndpoints.getLabelDashboard, data: {
      if (customer != null && customer.trim().isNotEmpty) 'customer': customer.trim(),
      'only_attention': onlyAttention ? 1 : 0,
      'include_untracked': includeUntracked ? 1 : 0,
    });
    return LabelDashboard.fromJson(_asMap(_unwrap(response)));
  }

  /// Badge count only — deliberately a separate, cheaper call than the board so
  /// the drawer can ask for it without pulling every label's ledger.
  Future<LabelSummary> getAlertCount() async {
    final response =
        await _dio.post(ApiEndpoints.getLabelAlertCount, data: const {});
    final payload = _asMap(_unwrap(response));
    return LabelSummary.fromJson({
      'needs_attention': payload['needs_attention'],
      'out_of_stock': payload['out_of_stock'],
      'reorder_now': payload['reorder_now'],
      'reorder_soon': payload['reorder_soon'],
    });
  }

  Future<CustomerLabel> getDetail(String label) async {
    final response = await _dio
        .post(ApiEndpoints.getLabelDetail, data: {'label': label});
    return CustomerLabel.fromJson(_asMap(_unwrap(response)));
  }

  Future<List<LabelCustomerOption>> searchCustomers(String query) async {
    final response = await _dio
        .post(ApiEndpoints.searchLabelCustomers, data: {'query': query});
    final payload = _asMap(_unwrap(response));
    return (payload['customers'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => LabelCustomerOption.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// The flavours a customer deals in (price list + order history), flagged
  /// with whether a label already tracks them — the setup wizard's checklist.
  Future<LabelFlavourOptions> getFlavourOptions(String customer) async {
    final response = await _dio
        .post(ApiEndpoints.getLabelFlavourOptions, data: {'customer': customer});
    return LabelFlavourOptions.fromJson(_asMap(_unwrap(response)));
  }

  Future<List<LabelStorageLocation>> getStorageLocations() async {
    final response =
        await _dio.post(ApiEndpoints.getLabelStorageLocations, data: const {});
    final payload = _asMap(_unwrap(response));
    return (payload['locations'] as List? ?? const [])
        .whereType<Map>()
        .map((e) =>
            LabelStorageLocation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<LabelSupplierOption>> searchPrintSuppliers(String query) async {
    final response = await _dio
        .post(ApiEndpoints.getLabelPrintSuppliers, data: {'query': query});
    final payload = _asMap(_unwrap(response));
    return (payload['suppliers'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => LabelSupplierOption.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// One-shot account setup: creates a label per picked flavour at the given
  /// storage location. A flavour already tracked at THAT location is skipped
  /// server-side; the same flavour at another branch gets its own label, so
  /// re-running for a second branch is additive.
  ///
  /// `we_print` is always 1: JARZ prints every customer label (the server
  /// forces it regardless).
  Future<LabelSetupResult> setupCustomerLabels({
    required String customer,
    required List<LabelSetupFlavour> flavours,
    String? storageLocation,
    String? priceList,
    int defaultPrintSheets = 0,
  }) async {
    final response = await _dio.post(ApiEndpoints.setupCustomerLabels, data: {
      'customer': customer,
      'flavours': flavours.map((f) => f.toJson()).toList(),
      if (storageLocation != null && storageLocation.trim().isNotEmpty)
        'storage_location': storageLocation.trim(),
      if (priceList != null && priceList.trim().isNotEmpty)
        'price_list': priceList.trim(),
      if (defaultPrintSheets > 0) 'default_print_sheets': defaultPrintSheets,
      'we_print': 1,
    });
    return LabelSetupResult.fromJson(_asMap(_unwrap(response)));
  }

  Future<CustomerLabel> createLabel({
    required String customer,
    required String item,
    String? labelTitle,
    String? storageLocation,
    double labelsPerUnit = 1,
    int labelsPerSheet = 0,
    int defaultPrintSheets = 0,
    int minStockQty = 0,
    int openingQty = 0,
    String? notes,
  }) async {
    final response = await _dio.post(ApiEndpoints.createLabel, data: {
      'customer': customer,
      'item': item,
      if (labelTitle != null && labelTitle.trim().isNotEmpty)
        'label_title': labelTitle.trim(),
      'we_print': 1,
      if (storageLocation != null && storageLocation.trim().isNotEmpty)
        'storage_location': storageLocation.trim(),
      'labels_per_unit': labelsPerUnit,
      'labels_per_sheet': labelsPerSheet,
      'default_print_sheets': defaultPrintSheets,
      'min_stock_qty': minStockQty,
      'opening_qty': openingQty,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
    return CustomerLabel.fromJson(_asMap(_unwrap(response)));
  }

  /// Only the fields actually passed are written, so a caller can flip one
  /// switch without having to resend the whole policy.
  Future<CustomerLabel> updateLabel({
    required String label,
    String? labelTitle,
    String? item,
    bool? enabled,
    String? storageLocation,
    double? labelsPerUnit,
    int? labelsPerSheet,
    int? defaultPrintSheets,
    int? minStockQty,
    String? notes,
  }) async {
    final response = await _dio.post(ApiEndpoints.updateLabel, data: {
      'label': label,
      if (labelTitle != null) 'label_title': labelTitle,
      if (item != null) 'item': item,
      if (enabled != null) 'enabled': enabled ? 1 : 0,
      // An empty string is meaningful: it clears the home location.
      if (storageLocation != null) 'storage_location': storageLocation,
      if (labelsPerUnit != null) 'labels_per_unit': labelsPerUnit,
      if (labelsPerSheet != null) 'labels_per_sheet': labelsPerSheet,
      if (defaultPrintSheets != null)
        'default_print_sheets': defaultPrintSheets,
      if (minStockQty != null) 'min_stock_qty': minStockQty,
      if (notes != null) 'notes': notes,
    });
    return CustomerLabel.fromJson(_asMap(_unwrap(response)));
  }

  Future<CustomerLabel> recordMovement({
    required String label,
    required String movementType,
    required int qty,
    String? postingDate,
    String? remarks,
  }) async {
    final response = await _dio.post(ApiEndpoints.recordLabelMovement, data: {
      'label': label,
      'movement_type': movementType,
      'qty': qty,
      if (postingDate != null) 'posting_date': postingDate,
      if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
    });
    final payload = _asMap(_unwrap(response));
    return CustomerLabel.fromJson(_asMap(payload['label']));
  }

  /// Reconciles the ledger to a physical count; the server posts the difference.
  Future<CustomerLabel> recordCount({
    required String label,
    required int countedQty,
    String? remarks,
  }) async {
    final response = await _dio.post(ApiEndpoints.recordLabelCount, data: {
      'label': label,
      'counted_qty': countedQty,
      if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
    });
    final payload = _asMap(_unwrap(response));
    return CustomerLabel.fromJson(_asMap(payload['label']));
  }

  /// Sends a batch to the print house, in SHEETS — the label quantity and the
  /// expected-ready date are computed server-side.
  Future<CustomerLabel> createPrintOrder({
    required String label,
    required int qtySheets,
    String? supplier,
    String? printerName,
    double? totalCost,
    String? requestedOn,
    String? notes,
  }) async {
    final response = await _dio.post(ApiEndpoints.createLabelPrintOrder, data: {
      'label': label,
      'qty_sheets': qtySheets,
      if (supplier != null && supplier.trim().isNotEmpty)
        'supplier': supplier.trim(),
      if (printerName != null && printerName.trim().isNotEmpty)
        'printer_name': printerName.trim(),
      if (totalCost != null && totalCost > 0) 'total_cost': totalCost,
      if (requestedOn != null) 'requested_on': requestedOn,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
    final payload = _asMap(_unwrap(response));
    return CustomerLabel.fromJson(_asMap(payload['label']));
  }

  Future<CustomerLabel> updatePrintOrder({
    required String printOrder,
    String? status,
    int? receivedQty,
    String? receivedOn,
    double? totalCost,
    String? supplier,
    String? printerName,
    String? notes,
  }) async {
    final response = await _dio.post(ApiEndpoints.updateLabelPrintOrder, data: {
      'print_order': printOrder,
      if (status != null) 'status': status,
      if (receivedQty != null) 'received_qty': receivedQty,
      if (receivedOn != null) 'received_on': receivedOn,
      if (totalCost != null) 'total_cost': totalCost,
      if (supplier != null) 'supplier': supplier,
      if (printerName != null) 'printer_name': printerName,
      if (notes != null) 'notes': notes,
    });
    final payload = _asMap(_unwrap(response));
    return CustomerLabel.fromJson(_asMap(payload['label']));
  }

  /// Books the printer's bill as a supplier Purchase Invoice. Manager-gated
  /// server-side — reps receive boxes; managers commit money.
  Future<CustomerLabel> billPrintOrder({
    required String printOrder,
    String? supplier,
    double? totalCost,
    String? billNo,
    String? billDate,
    bool? isPaid,
    String? paymentOption,
  }) async {
    final paid = _paidOption(isPaid ?? false, paymentOption);
    final response = await _dio.post(ApiEndpoints.billLabelPrintOrder, data: {
      'print_order': printOrder,
      if (supplier != null && supplier.trim().isNotEmpty)
        'supplier': supplier.trim(),
      if (totalCost != null && totalCost > 0) 'total_cost': totalCost,
      if (billNo != null && billNo.trim().isNotEmpty) 'bill_no': billNo.trim(),
      if (billDate != null && billDate.trim().isNotEmpty)
        'bill_date': billDate.trim(),
      // Omitted entirely when the caller does not say, so an older caller
      // keeps the old wire format (owed to the printer).
      if (isPaid != null) 'is_paid': paid == null ? 0 : 1,
      if (paid != null) 'payment_option': paid,
    });
    final payload = _asMap(_unwrap(response));
    return CustomerLabel.fromJson(_asMap(payload['label']));
  }

  /// A batch already bought AND delivered, in one call: the server creates the
  /// print order, receives it into stock and books the supplier bill.
  /// Manager-only server-side; a refusal surfaces as the server's sentence.
  ///
  /// [clientRequestId] must be the same on a retry of the same purchase, so a
  /// replay after a timeout is deduplicated instead of buying twice.
  Future<BoughtBatchResult> recordBoughtBatch({
    required String label,
    required int qtySheets,
    int? receivedQty,
    required String supplier,
    required double totalCost,
    String? billNo,
    String? billDate,
    String? receivedOn,
    bool isPaid = false,
    String? paymentOption,
    String? notes,
    required String clientRequestId,
  }) async {
    final paid = _paidOption(isPaid, paymentOption);
    final response =
        await _dio.post(ApiEndpoints.recordLabelBoughtBatch, data: {
      'label': label,
      'qty_sheets': qtySheets,
      if (receivedQty != null && receivedQty > 0) 'received_qty': receivedQty,
      'supplier': supplier.trim(),
      'total_cost': totalCost,
      if (billNo != null && billNo.trim().isNotEmpty) 'bill_no': billNo.trim(),
      if (billDate != null && billDate.trim().isNotEmpty)
        'bill_date': billDate.trim(),
      if (receivedOn != null && receivedOn.trim().isNotEmpty)
        'received_on': receivedOn.trim(),
      'is_paid': paid == null ? 0 : 1,
      if (paid != null) 'payment_option': paid,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      'client_request_id': clientRequestId,
    });
    final payload = _asMap(_unwrap(response));
    final dedup = payload['deduplicated'];
    return BoughtBatchResult(
      printOrder: payload['print_order']?.toString(),
      purchaseInvoice: payload['purchase_invoice']?.toString(),
      deduplicated: dedup == true || dedup == 1 || dedup == '1',
      label: CustomerLabel.fromJson(_asMap(payload['label'])),
    );
  }

  /// The payment source to send, or null for "owed to the supplier". Paid with
  /// no source is a caller bug: silently booking it as owed would leave the
  /// money out of the drawer it actually left, so it throws instead.
  String? _paidOption(bool isPaid, String? paymentOption) {
    if (!isPaid) return null;
    final option = paymentOption?.trim() ?? '';
    if (option.isEmpty) {
      throw ArgumentError.value(
          paymentOption, 'paymentOption', 'required when isPaid is true');
    }
    return option;
  }
}

/// What `record_bought_batch` returns: the records it created and the label's
/// refreshed detail (the same map `bill_print_order` returns).
class BoughtBatchResult {
  final String? printOrder;
  final String? purchaseInvoice;

  /// True when the `client_request_id` matched a batch already recorded: the
  /// server replayed that one and booked nothing new. False when missing.
  final bool deduplicated;
  final CustomerLabel label;

  const BoughtBatchResult({
    required this.printOrder,
    required this.purchaseInvoice,
    this.deduplicated = false,
    required this.label,
  });
}
