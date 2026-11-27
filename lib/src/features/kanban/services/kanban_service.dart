import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import "../models/kanban_models.dart";
import "../models/kanban_filter_options.dart";
import "../../../core/utils/logger.dart";
import '../../../core/network/frappe_error_message.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/business_constants.dart';
import '../../../core/repositories/customer_address_repository.dart';

/// Service for interacting with Kanban-related API endpoints
class KanbanService {
  // Replaced ApiClient with shared Dio (has SessionInterceptor -> cookies)
  final Dio _dio;
  final Logger _logger = Logger("KanbanService");
  late final CustomerAddressRepository _addressRepo;

  KanbanService(this._dio) {
    _addressRepo = CustomerAddressRepository(_dio);
  }

  String _friendlyMessage(dynamic payload, {required String fallback}) {
    return extractFrappeErrorMessage(payload, fallback: fallback);
  }

  Exception _friendlyException(Object error, {required String fallback}) {
    return mapFrappeError(error, fallback: fallback);
  }

  Future<dynamic> rawPost(String path, Map<String, dynamic> data) async {
    final resp = await _dio.post(path, data: data);
    return resp.data['message'] ?? resp.data;
  }

  /// Settlement preview for an invoice to reconcile paid/unpaid and amounts
  Future<Map<String, dynamic>> getInvoiceSettlementPreview({
    required String invoiceName,
    String? partyType,
    String? party,
  }) async {
    try {
      _logger.info('Fetching settlement preview for $invoiceName');
      final resp = await _dio.get(
        ApiEndpoints.getInvoiceSettlementPreview,
        queryParameters: {
          'invoice_name': invoiceName,
          if (partyType != null) 'party_type': partyType,
          if (party != null) 'party': party,
        },
      );
      final msg = resp.data['message'];
      if (msg is Map) {
        return Map<String, dynamic>.from(msg);
      }
      throw Exception('Failed to fetch settlement preview');
    } catch (e) {
      _logger.error('Failed to get settlement preview', e);
      rethrow;
    }
  }

  Future<Map<String, List<InvoiceCard>>> fetchInvoices() async {
    return await getKanbanInvoices();
  }

  /// Fetch kanban columns from the API
  Future<List<KanbanColumn>> getKanbanColumns() async {
    try {
      _logger.info("Fetching kanban columns");
      final response = await _dio.get(
        ApiEndpoints.getKanbanColumns,
      );

      if (response.data["message"]["success"] == true) {
        final List<dynamic> columnsData = response.data["message"]["columns"];
        // Sort by the backend's declared `order` so the board's index-based
        // drag guard can never be thrown off by response ordering. Stable, and
        // a no-op when the server already sends them in order.
        final columns = KanbanColumn.sorted(
          columnsData.map((column) => KanbanColumn.fromJson(column)).toList(),
        );
        _logger.debug("Retrieved ${columns.length} columns");
        return columns;
      } else {
        final error =
            response.data["message"]["error"] ??
            "Failed to load kanban columns";
        _logger.error("API error: $error");
        throw Exception(error);
      }
    } catch (e) {
      _logger.error("Failed to get kanban columns", e);
      throw Exception("Failed to get kanban columns: $e");
    }
  }

  /// Fetch kanban invoices from the API with optional filters
  Future<Map<String, List<InvoiceCard>>> getKanbanInvoices({
    Map<String, dynamic>? filters,
  }) async {
    try {
      _logger.info("Fetching kanban invoices with filters: $filters");
      final response = await _dio.post(
        ApiEndpoints.getKanbanInvoices,
        data: filters != null ? {"filters": jsonEncode(filters)} : {},
      );

      if (response.data["message"]["success"] == true) {
        final Map<String, dynamic> kanbanData =
            response.data["message"]["data"];
        final Map<String, List<InvoiceCard>> result = {};

        kanbanData.forEach((columnId, cardList) {
          if (cardList is List) {
            result[columnId] = cardList
                .map((card) => InvoiceCard.fromJson(card))
                .toList();
          }
        });

        int total = 0;
        result.forEach((key, cards) => total += cards.length);
        _logger.debug(
          "Retrieved $total cards across ${result.keys.length} columns",
        );

        return result;
      } else {
        final error =
            response.data["message"]["error"] ??
            "Failed to load kanban invoices";
        _logger.error("API error: $error");
        throw Exception(error);
      }
    } catch (e) {
      _logger.error("Failed to get kanban invoices", e);
      throw Exception("Failed to get kanban invoices: $e");
    }
  }

  /// Update the state of an invoice
  Future<Map<String, dynamic>> previewOutForDelivery(String invoiceId) async {
    final response = await _dio.get(
      ApiEndpoints.previewInvoiceOutForDelivery,
      queryParameters: {'invoice_id': invoiceId},
    );

    final message = response.data['message'];
    if (message is Map && message['success'] == true) {
      return Map<String, dynamic>.from(message);
    }
    throw Exception(
      message is Map
          ? message['error'] ?? 'Failed to preview Out For Delivery'
          : 'Failed to preview Out For Delivery',
    );
  }

  Future<bool> updateInvoiceState(
    String invoiceId,
    String newState, {
    bool shortageApproved = false,
    String? shortageReason,
    String? expectedState,
  }) async {
    final payload = <String, dynamic>{
      'invoice_id': invoiceId,
      'new_state': newState,
    };
    // Tell the server which column we dragged the card out of. If somebody else
    // already moved it, the move is rejected instead of silently overwriting
    // their change.
    if (expectedState != null && expectedState.isNotEmpty) {
      payload['expected_state'] = expectedState;
    }
    if (shortageApproved) {
      payload['shortage_approved'] = 1;
    }
    if (shortageReason != null && shortageReason.trim().isNotEmpty) {
      payload['shortage_reason'] = shortageReason.trim();
    }

    final response = await _dio.post(
      ApiEndpoints.updateInvoiceState,
      data: payload,
    );

    if (response.data["message"]["success"] == true) {
      _logger.debug("Invoice state updated successfully");
      return true;
    } else {
      final error =
          response.data["message"]["error"] ?? "Failed to update invoice state";
      _logger.error("API error: $error");
      throw Exception(error);
    }
  }

  /// Cancel an invoice before dispatch
  Future<Map<String, dynamic>> cancelInvoice({
    required String invoiceName,
    required String reason,
    String? notes,
  }) async {
    try {
      _logger.info("Cancelling invoice $invoiceName");
      final payload = {
        "invoice_id": invoiceName,
        "reason": reason,
      };
      if (notes != null && notes.trim().isNotEmpty) {
        payload["notes"] = notes.trim();
      }

      final response = await _dio.post(
        ApiEndpoints.cancelInvoice,
        data: payload,
      );

      final message = response.data["message"];
      if (message is Map && message["success"] == true) {
        return Map<String, dynamic>.from(message);
      }
      if (message is Map && message["error"] != null) {
        throw Exception(message["error"]);
      }
      throw Exception("Failed to cancel invoice");
    } catch (e) {
      _logger.error("Failed to cancel invoice", e);
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          final msg = data['message'] ?? data['exception'] ?? data['error'];
          if (msg is String && msg.trim().isNotEmpty) {
            throw Exception(msg);
          }
          if (msg is Map && msg['error'] != null) {
            throw Exception(msg['error']);
          }
        }
        if (data is String && data.trim().isNotEmpty) {
          throw Exception(data);
        }
        final status = e.response?.statusCode;
        final statusText = e.response?.statusMessage;
        throw Exception(
          status != null ? "Cancellation failed ($status ${statusText ?? ''}).".trim() : "Cancellation failed",
        );
      }
      throw Exception(e.toString());
    }
  }

  /// Load the return preview for a dispatched invoice. Read-only server side.
  Future<Map<String, dynamic>> getReturnPreview(String invoiceName) async {
    try {
      _logger.info("Loading return preview for $invoiceName");
      final response = await _dio.post(
        ApiEndpoints.getReturnPreview,
        data: {"invoice_id": invoiceName},
      );
      return _unwrapMethodResponse(response.data, "Failed to load return preview");
    } catch (e) {
      _logger.error("Failed to load return preview", e);
      throw _friendlyException(e, fallback: "Failed to load return preview");
    }
  }

  /// Post a return: credit note + return delivery note + money reversal.
  ///
  /// [lines] is a list of `{si_detail, qty}` maps — the operator's per-line
  /// selection, which is what makes partial (B2B) returns possible.
  Future<Map<String, dynamic>> submitInvoiceReturn({
    required String invoiceName,
    required List<Map<String, dynamic>> lines,
    required String reason,
    required String returnType,
    required String refundMode,
    required bool payCourierForTrip,
    String? goodsCondition,
    String? notes,
    String? requestId,
  }) async {
    try {
      _logger.info("Submitting return for $invoiceName");
      final payload = <String, dynamic>{
        "invoice_id": invoiceName,
        "lines": jsonEncode(lines),
        "reason": reason,
        "return_type": returnType,
        "refund_mode": refundMode,
        "pay_courier_for_trip": payCourierForTrip ? 1 : 0,
      };
      if (requestId != null && requestId.isNotEmpty) {
        payload["request_id"] = requestId;
      }
      if (notes != null && notes.trim().isNotEmpty) {
        payload["notes"] = notes.trim();
      }
      // `waste` or `restock`. Left out when the dialog did not ask, so the
      // server applies its own rule (a "Damaged" return is written off).
      if (goodsCondition != null && goodsCondition.isNotEmpty) {
        payload["goods_condition"] = goodsCondition;
      }

      final response = await _dio.post(
        ApiEndpoints.submitInvoiceReturn,
        data: payload,
      );
      return _unwrapMethodResponse(response.data, "Failed to submit return");
    } catch (e) {
      _logger.error("Failed to submit return", e);
      throw _friendlyException(e, fallback: "Failed to submit return");
    }
  }

  /// Unwrap a Frappe `{"message": {...}}` envelope, surfacing server errors.
  Map<String, dynamic> _unwrapMethodResponse(dynamic data, String fallback) {
    final message = data is Map ? data["message"] : null;
    if (message is Map) {
      if (message["success"] == true) {
        return Map<String, dynamic>.from(message);
      }
      final error = message["error"] ?? message["return_block_reason"];
      if (error != null) {
        throw Exception(error.toString());
      }
    }
    throw Exception(fallback);
  }

  /// Get detailed information about a specific invoice
  Future<InvoiceCard> getInvoiceDetails(String invoiceId) async {
    try {
      _logger.info("Fetching details for invoice: $invoiceId");
      final response = await _dio.get(
        ApiEndpoints.getInvoiceDetails,
        queryParameters: {"invoice_id": invoiceId},
      );

      if (response.data["message"]["success"] == true) {
        final cardData = response.data["message"]["data"];
        _logger.debug("Retrieved invoice details successfully");
        return InvoiceCard.fromJson(cardData);
      } else {
        final error =
            response.data["message"]["error"] ??
            "Failed to get invoice details";
        _logger.error("API error: $error");
        throw Exception(error);
      }
    } catch (e) {
      _logger.error("Failed to get invoice details", e);
      throw Exception("Failed to get invoice details: $e");
    }
  }

  Future<List<InvoiceNote>> getInvoiceNotes(String invoiceId) async {
    try {
      _logger.info("Fetching notes for invoice: $invoiceId");
      final response = await _dio.get(
        ApiEndpoints.getInvoiceNotes,
        queryParameters: {"invoice_id": invoiceId},
      );

      final message = response.data["message"];
      if (message is Map && message["success"] == true) {
        return (message["data"] as List? ?? const [])
            .whereType<Map>()
            .map((note) => InvoiceNote.fromJson(Map<String, dynamic>.from(note)))
            .toList();
      }

      throw Exception(
        message is Map
            ? message["error"] ?? "Failed to load invoice notes"
            : "Failed to load invoice notes",
      );
    } catch (e) {
      _logger.error("Failed to get invoice notes", e);
      throw _friendlyException(e, fallback: 'Failed to load invoice notes');
    }
  }

  Future<InvoiceNoteSaveResult> addInvoiceNote({
    required String invoiceId,
    required String note,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.addInvoiceNote,
        data: {
          'invoice_id': invoiceId,
          'note': note.trim(),
        },
      );

      final message = response.data["message"];
      if (message is Map && message["success"] == true) {
        final noteCount = message["note_count"] is int
            ? message["note_count"] as int
            : int.tryParse((message["note_count"] ?? '').toString()) ?? 0;
        return InvoiceNoteSaveResult(
          note: InvoiceNote.fromJson(
            Map<String, dynamic>.from((message["data"] as Map?) ?? const {}),
          ),
          noteCount: noteCount,
        );
      }

      throw Exception(
        message is Map
            ? message["error"] ?? "Failed to add invoice note"
            : "Failed to add invoice note",
      );
    } catch (e) {
      _logger.error("Failed to add invoice note", e);
      throw _friendlyException(e, fallback: 'Failed to add invoice note');
    }
  }

  /// Get filter options for the kanban board
  Future<KanbanFilterOptions> getKanbanFilters() async {
    try {
      _logger.info("Fetching kanban filter options");
      final response = await _dio.get(
        ApiEndpoints.getKanbanFilters,
      );

      if (response.data["message"]["success"] == true) {
        final data = response.data["message"];
        final customers =
            (data["customers"] as List?)
                ?.map((c) => FilterOption(value: c["value"], label: c["label"]))
                .toList() ??
            [];

        final states =
            (data["states"] as List?)
                ?.map((s) => FilterOption(value: s["value"], label: s["label"]))
                .toList() ??
            [];

        _logger.debug(
          "Retrieved ${customers.length} customers and ${states.length} states for filtering",
        );

        return KanbanFilterOptions(customers: customers, states: states);
      } else {
        final error =
            response.data["message"]["error"] ?? "Failed to get filter options";
        _logger.error("API error: $error");
        throw Exception(error);
      }
    } catch (e) {
      _logger.error("Failed to get kanban filters", e);
      throw Exception("Failed to get kanban filters: $e");
    }
  }

  /// Pay an invoice (creates Payment Entry) given payment mode and optional POS profile for Cash
  Future<Map<String, dynamic>> payInvoice({
    required String invoiceName,
    required String paymentMode,
    String? posProfile,
  }) async {
    try {
      _logger.info("Paying invoice $invoiceName via $paymentMode");
      final data = {
        "invoice_name": invoiceName,
        "payment_mode": paymentMode,
      };
      if (posProfile != null) data["pos_profile"] = posProfile;

      final response = await _dio.post(
        ApiEndpoints.payInvoice,
        data: data,
      );
      final msg = response.data["message"];
      if (msg is Map && msg["success"] == true) {
        _logger.debug("Payment entry ${msg["payment_entry"]} created");
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(
        _friendlyMessage(msg ?? "Payment failed", fallback: "Payment failed"),
      );
    } catch (e) {
      _logger.error("Failed to pay invoice", e);
      // The server's own refusal must reach the card. The previous handler
      // threw `Exception(m)` inside a `try` whose `catch (_)` swallowed it, so
      // every Frappe refusal (e.g. "InstaPay payments need a confirmed transfer
      // receipt") collapsed into "Payment failed (417 ...)". The shared mapper
      // reads `message` / `_server_messages` / `exception` from the body.
      throw _friendlyException(e, fallback: "Payment failed");
    }
  }

  /// Unified Out For Delivery transition (handles paid and unpaid per backend new rules)
  Future<Map<String, dynamic>> handleOutForDeliveryTransition({
    required String invoiceName,
    required String courier,
    required String mode, // pay_now only
    required String posProfile,
    required String idempotencyToken,
    String? partyType,
    String? party,
  }) async {
    try {
      _logger.info("OFD transition $invoiceName mode=$mode courier=$courier token=$idempotencyToken");
      final response = await _dio.post(
        ApiEndpoints.handleOutForDeliveryTransition,
        data: {
          "invoice_name": invoiceName,
          "courier": courier,
          "mode": mode,
            "pos_profile": posProfile,
            "idempotency_token": idempotencyToken,
          if (partyType != null) "party_type": partyType,
          if (party != null) "party": party,
        },
      );
      final msg = response.data["message"];
      if (msg is Map && msg['success'] == true) {
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(msg is Map ? msg['error'] ?? 'OFD transition failed' : 'OFD transition failed');
    } catch (e) {
      _logger.error('Failed unified OFD transition', e);
      rethrow;
    }
  }

  /// Helper to generate an idempotency token (not cryptographically secure)
  String generateIdempotencyToken() {
    final r = Random();
    return 'ofd-${DateTime.now().millisecondsSinceEpoch}-${r.nextInt(1<<32).toRadixString(16)}';
  }

  /// Fetch list of active couriers (name & courier_name)
  Future<List<Map<String, String>>> fetchCouriers({String? posProfile}) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.getActiveCouriers,
        queryParameters: {
          if (posProfile != null && posProfile.trim().isNotEmpty)
            'pos_profile': posProfile.trim(),
        },
      );
      final msg = resp.data['message'];
      if (msg is List) {
        // Unified shape from backend: { party_type, party, display_name }
        return msg.map<Map<String, String>>((e) {
          final display = (e['display_name'] ?? e['name'] ?? '').toString();
          final party = (e['party'] ?? '').toString();
          final partyType = (e['party_type'] ?? '').toString();
          return {
            'party_type': partyType,
            'party': party,
            'display_name': display,
            // legacy keys consumed by existing UI dropdown
            'courier_name': display,
            'name': party,
            if (e['branch'] != null) 'branch': (e['branch'] ?? '').toString(),
            // Set when the rider works for a Delivery Partner (e.g. Deliverk);
            // dispatch flows must then collect the partner's delivery cost.
            if ((e['delivery_partner'] ?? '').toString().isNotEmpty)
              'delivery_partner': e['delivery_partner'].toString(),
          };
        }).toList();
      }
      if (msg is Map && msg['error'] != null) {
        throw Exception(msg['error']);
      }
      return [];
    } catch (e) {
      _logger.error('Failed to fetch couriers', e);
      rethrow;
    }
  }

  /// Mark courier outstanding for UNPAID invoice: creates Payment Entry moving receivable to Courier Outstanding,
  /// creates Courier Transaction with amount = invoice outstanding and shipping_amount from city, and may create a
  /// shipping expense Journal Entry. Also sets state to Out for Delivery idempotently via backend and emits realtime.
  Future<Map<String, dynamic>> markCourierOutstanding({
    required String invoiceName,
    required String courier,
    String? partyType,
    String? party,
  }) async {
    try {
      _logger.info("Mark courier outstanding $invoiceName courier=$courier");
      final response = await _dio.post(
        ApiEndpoints.markCourierOutstanding,
        data: {
          "invoice_name": invoiceName,
          "courier": courier,
          if (partyType != null) "party_type": partyType,
          if (party != null) "party": party,
        },
      );
      final msg = response.data["message"];
      if (msg is Map) {
        // Normalize: ensure a success flag so callers can treat as successful
        final map = Map<String, dynamic>.from(msg);
        map.putIfAbsent('success', () => true);
        map.putIfAbsent('invoice', () => invoiceName);
        return map;
      }
      // Some backends may return a bare string like "OK"; treat as success
      if (msg is String) {
        return {
          'success': true,
          'invoice': invoiceName,
          'message': msg,
        };
      }
      throw Exception("mark_courier_outstanding failed");
    } catch (e) {
      _logger.error('Failed to mark courier outstanding', e);
      rethrow;
    }
  }

  /// Create a new delivery party (Employee or Supplier) with phone & branch (pos profile name)
  Future<Map<String, String>> createDeliveryParty({
    required String partyType, // 'Employee' | 'Supplier'
    String? name, // optional if first/last provided
    String? firstName,
    String? lastName,
    required String phone,
    String? posProfile, // used as branch on backend
    String? deliveryPartner, // Delivery Partner to link
    // Opt out of the branch's default delivery partner (server links a new
    // Supplier to the branch default unless this is sent).
    bool noDeliveryPartner = false,
  }) async {
    try {
      _logger.info('Creating delivery party type=$partyType name=$name branch=$posProfile deliveryPartner=$deliveryPartner noDeliveryPartner=$noDeliveryPartner');
      final resp = await _dio.post(
        ApiEndpoints.createDeliveryParty,
        data: {
          'party_type': partyType,
          if (name != null) 'name': name,
          'phone': phone,
          if (posProfile != null) 'pos_profile': posProfile,
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (deliveryPartner != null && deliveryPartner.isNotEmpty) 'delivery_partner': deliveryPartner,
          if (noDeliveryPartner) 'no_delivery_partner': 1,
        },
      );
      final msg = resp.data['message'];
      if (msg is Map) {
        // Normalize output with legacy keys for UI reuse
        final map = {
          'party_type': (msg['party_type'] ?? '').toString(),
          'party': (msg['party'] ?? '').toString(),
          'display_name': (msg['display_name'] ?? name).toString(),
          'courier_name': (msg['display_name'] ?? name).toString(),
          'name': (msg['party'] ?? '').toString(),
          if (msg['branch'] != null) 'branch': (msg['branch'] ?? '').toString(),
          if (msg['phone'] != null) 'phone': (msg['phone'] ?? '').toString(),
          if (msg['delivery_partner'] != null) 'delivery_partner': (msg['delivery_partner'] ?? '').toString(),
        };
        return map;
      }
      throw Exception('Unexpected response creating delivery party');
    } catch (e) {
      _logger.error('Failed to create delivery party', e);
      rethrow;
    }
  }

  /// Get list of active Delivery Partners for dropdown
  Future<List<Map<String, String>>> getDeliveryPartnersList() async {
    try {
      final resp = await _dio.post(ApiEndpoints.getDeliveryPartnersList, data: {});
      final msg = resp.data['message'];
      if (msg is List) {
        return msg.map<Map<String, String>>((e) => {
          'name': (e['name'] ?? '').toString(),
          'partner_name': (e['partner_name'] ?? '').toString(),
        }).toList();
      }
      return [];
    } catch (e) {
      _logger.error('Failed to fetch delivery partners list', e);
      return [];
    }
  }

  /// Settle a single already-paid invoice's courier shipping expense (one-by-one settlement)
  Future<Map<String, dynamic>> settleSingleInvoicePaid({
    required String invoiceName,
    required String posProfile,
    required String partyType,
    required String party,
  }) async {
    try {
      _logger.info('Single courier settlement invoice=$invoiceName party=$partyType/$party');
      final resp = await _dio.post(
        ApiEndpoints.settleSingleInvoicePaid,
        data: {
          'invoice_name': invoiceName,
          'pos_profile': posProfile,
          'party_type': partyType,
          'party': party,
        },
      );
      final msg = resp.data['message'];
      if (msg is Map && (msg['success'] == true || msg['journal_entry'] != null)) {
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(msg is Map ? msg['error'] ?? 'Settlement failed' : 'Settlement failed');
    } catch (e) {
      _logger.error('Failed single invoice settlement', e);
      rethrow;
    }
  }

  /// Settle scenario where courier collected the full order amount from customer.
  /// Backend performs two-case JE logic netting order vs shipping expense.
  Future<Map<String, dynamic>> settleCourierCollectedPayment({
    required String invoiceName,
    required String posProfile,
    required String partyType,
    required String party,
  }) async {
    try {
      _logger.info('Courier collected settlement invoice=$invoiceName party=$partyType/$party');
      final resp = await _dio.post(
        ApiEndpoints.settleCourierCollectedPayment,
        data: {
          'invoice_name': invoiceName,
          'pos_profile': posProfile,
          'party_type': partyType,
          'party': party,
        },
      );
      final msg = resp.data['message'];
      if (msg is Map && (msg['success'] == true || msg['journal_entry'] != null)) {
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(msg is Map ? msg['error'] ?? 'Courier collected settlement failed' : 'Courier collected settlement failed');
    } catch (e) {
      _logger.error('Failed courier collected settlement', e);
      rethrow;
    }
  }

  /// Sales Partner UNPAID -> Out For Delivery fast-path (auto cash payment + DN + state change)
  Future<Map<String, dynamic>> salesPartnerUnpaidOutForDelivery({
    required String invoiceName,
    required String posProfile,
    String modeOfPayment = PaymentModes.cash,
  }) async {
    try {
      _logger.info('SalesPartner unpaid OFD invoice=$invoiceName pos_profile=$posProfile');
      final resp = await _dio.post(
        ApiEndpoints.salesPartnerUnpaidOutForDelivery,
        data: {
          'invoice_name': invoiceName,
          'pos_profile': posProfile,
          'mode_of_payment': modeOfPayment,
        },
      );
      final msg = resp.data['message'];
      if (msg is Map && (msg['success'] == true)) {
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(msg is Map ? (msg['error'] ?? 'Sales partner unpaid OFD failed') : 'Sales partner unpaid OFD failed');
    } catch (e) {
      _logger.error('Failed sales partner unpaid OFD', e);
      rethrow;
    }
  }

  /// Sales Partner PAID -> Out For Delivery fast-path (ensure DN + state change)
  Future<Map<String, dynamic>> salesPartnerPaidOutForDelivery({
    required String invoiceId,
  }) async {
    try {
      _logger.info('SalesPartner paid OFD invoice=$invoiceId');
      final resp = await _dio.post(
        ApiEndpoints.salesPartnerPaidOutForDelivery,
        data: {
          'invoice_name': invoiceId,
        },
      );
      final msg = resp.data['message'];
      if (msg is Map && (msg['success'] == true)) {
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(msg is Map ? (msg['error'] ?? 'Sales partner paid OFD failed') : 'Sales partner paid OFD failed');
    } catch (e) {
      _logger.error('Failed sales partner paid OFD', e);
      rethrow;
    }
  }

  /// Update customer's default address and phone number
  Future<Map<String, dynamic>> updateCustomerAddress({
    required String customer,
    required String address,
    required String phone,
    String? invoice,
  }) async {
    try {
      _logger.info('Updating customer address for $customer (invoice: $invoice)');
      final resp = await _dio.post(
        ApiEndpoints.updateDefaultAddress,
        data: {
          'customer': customer,
          'address': address,
          'phone': phone,
          if (invoice != null) 'invoice': invoice,
        },
      );
      final msg = resp.data['message'];
      if (msg is Map && (msg['success'] == true)) {
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(_friendlyMessage(msg, fallback: 'Failed to update customer address'));
    } catch (e) {
      _logger.error('Failed to update customer address', e);
      throw _friendlyException(e, fallback: 'Failed to update customer address');
    }
  }

  Future<Map<String, dynamic>> getCustomerShippingAddresses({
    required String customer,
    String? invoice,
  }) async {
    try {
      _logger.info('Fetching shipping addresses for $customer (invoice: $invoice)');
      final resp = await _dio.post(
        ApiEndpoints.getCustomerShippingAddresses,
        data: {
          'customer': customer,
          if (invoice != null && invoice.isNotEmpty) 'invoice': invoice,
        },
      );
      final msg = resp.data['message'];
      if (msg is Map) {
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(_friendlyMessage(msg, fallback: 'Failed to load shipping addresses'));
    } catch (e) {
      _logger.error('Failed to load shipping addresses', e);
      throw _friendlyException(e, fallback: 'Failed to load shipping addresses');
    }
  }

  Future<Map<String, dynamic>> saveCustomerShippingAddress({
    required String customer,
    required String phone,
    String? invoice,
    String? addressName,
    String? address,
    String? territory,
    String? locationLink,
    double? latitude,
    double? longitude,
    String? geoSource,
  }) async {
    try {
      _logger.info('Saving shipping address for $customer (invoice: $invoice)');
      final resp = await _dio.post(
        ApiEndpoints.saveCustomerShippingAddress,
        data: {
          'customer': customer,
          'phone': phone,
          if (invoice != null && invoice.isNotEmpty) 'invoice': invoice,
          if (addressName != null && addressName.isNotEmpty)
            'address_name': addressName,
          if (address != null && address.isNotEmpty) 'address': address,
          if (territory != null && territory.isNotEmpty) 'territory': territory,
          // Geo payload from the location-link field. Frappe drops form keys a
          // whitelisted method does not declare, so a backend that predates the
          // geo lane ignores these rather than failing the save.
          if (locationLink != null && locationLink.isNotEmpty)
            'location_link': locationLink,
          if (latitude != null && longitude != null) ...{
            'latitude': latitude,
            'longitude': longitude,
            if (geoSource != null && geoSource.isNotEmpty)
              'geo_source': geoSource,
          },
          'set_as_primary': 1,
        },
      );
      final msg = resp.data['message'];
      if (msg is Map && (msg['success'] == true)) {
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(_friendlyMessage(msg, fallback: 'Failed to save shipping address'));
    } catch (e) {
      _logger.error('Failed to save shipping address', e);
      throw _friendlyException(e, fallback: 'Failed to save shipping address');
    }
  }

  Future<Map<String, dynamic>> updateCustomerShippingAddress({
    required String customer,
    required String addressName,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? phone,
    String? pincode,
  }) =>
      _addressRepo.updateAddress(
        customer: customer,
        addressName: addressName,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        phone: phone,
        pincode: pincode,
      );

  Future<Map<String, dynamic>> deleteCustomerShippingAddress({
    required String customer,
    required String addressName,
  }) =>
      _addressRepo.deleteAddress(customer: customer, addressName: addressName);

  Future<Map<String, dynamic>> changeInvoiceShippingAddress({
    required String invoiceName,
    required String addressName,
  }) =>
      _addressRepo.changeInvoiceShippingAddress(
        invoiceName: invoiceName,
        addressName: addressName,
      );

  /// Transfer invoice to a different POS profile
  Future<void> transferInvoice({
    required String invoiceId,
    required String newBranch,
  }) async {
    try {
      _logger.info('Transferring invoice $invoiceId to $newBranch');
      final resp = await _dio.post(
        ApiEndpoints.updateInvoiceBranch,
        data: {
          'invoice_id': invoiceId,
          'new_branch': newBranch,
        },
        options: Options(
          validateStatus: (status) => status! < 500, // Accept all status codes < 500
        ),
      );
      
      _logger.info('Transfer response status: ${resp.statusCode}');
      _logger.info('Transfer response data: ${resp.data}');
      
      // Handle non-200 status codes
      if (resp.statusCode != 200) {
        final errorMsg = resp.data.toString();
        _logger.error('Transfer failed with status ${resp.statusCode}: $errorMsg');
        throw Exception('Transfer failed: $errorMsg');
      }
      
      // Frappe wraps the response in a 'message' key
      final msg = resp.data['message'];
      _logger.info('Transfer response message: $msg');
      
      if (msg is Map) {
        final success = msg['success'] == true;
        if (!success) {
          final error = _friendlyMessage(msg, fallback: 'Transfer failed');
          _logger.error('Transfer failed: $error');
          throw Exception(error);
        }
        _logger.info('Invoice $invoiceId transferred successfully to $newBranch');
      } else {
        _logger.error('Unexpected response format: $msg');
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      _logger.error('Failed to transfer invoice', e);
      throw _friendlyException(e, fallback: 'Transfer failed');
    }
  }

  /// Update delivery slot for an invoice
  Future<void> updateDeliverySlot({
    required String invoiceId,
    required String deliveryDate,
    required String deliveryTimeFrom,
    required int deliveryDuration,
    String deliverySlotLabel = '',
  }) async {
    try {
      _logger.info('Updating delivery slot for invoice $invoiceId');
      _logger.info('New slot: $deliveryDate $deliveryTimeFrom, duration: ${deliveryDuration}s');
      
      final resp = await _dio.post(
        ApiEndpoints.updateInvoiceDeliverySlot,
        data: {
          'invoice_id': invoiceId,
          'delivery_date': deliveryDate,
          'delivery_time_from': deliveryTimeFrom,
          'delivery_duration': deliveryDuration,
          if (deliverySlotLabel.isNotEmpty) 'delivery_slot_label': deliverySlotLabel,
        },
      );
      
      _logger.info('Update delivery slot response: ${resp.data}');
      
      final msg = resp.data['message'];
      if (msg is Map) {
        final success = msg['success'] == true;
        if (!success) {
          final error = _friendlyMessage(msg, fallback: 'Failed to update delivery slot');
          _logger.error('Update delivery slot failed: $error');
          throw Exception(error);
        }
        _logger.info('Delivery slot updated successfully for $invoiceId');
      } else {
        _logger.error('Unexpected response format: $msg');
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      _logger.error('Failed to update delivery slot', e);
      throw _friendlyException(e, fallback: 'Failed to update delivery slot');
    }
  }

  /// List payment receipts with optional filters
  Future<List<Map<String, dynamic>>> listPaymentReceipts({
    String? posProfile,
    String? status,
  }) async {
    try {
      _logger.info('Fetching payment receipts (profile: $posProfile, status: $status)');
      final resp = await _dio.get(
        ApiEndpoints.listPaymentReceipts,
        queryParameters: {
          if (posProfile != null) 'pos_profile': posProfile,
          if (status != null) 'status': status,
        },
      );
      final msg = resp.data['message'];
      if (msg is List) {
        return List<Map<String, dynamic>>.from(msg.map((e) => Map<String, dynamic>.from(e)));
      }
      throw Exception('Failed to fetch payment receipts');
    } catch (e) {
      _logger.error('Failed to list payment receipts', e);
      throw _friendlyException(e, fallback: 'Failed to fetch payment receipts');
    }
  }

  /// One receipt by name (POST `receipt_name`). Newer than the list endpoint:
  /// callers fall back to `listPaymentReceipts` on a server without it.
  ///
  /// Kept here rather than in `ApiEndpoints` on purpose: anything under
  /// `lib/src/core/` classifies a release as a full APK (a forced reinstall for
  /// every operator), while this feature-only change ships as a Shorebird patch.
  static const _getPaymentReceiptEndpoint =
      '/api/method/jarz_pos.api.payment_receipts.get_payment_receipt';

  /// One payment receipt by name, or null when the server answered without a
  /// receipt row.
  ///
  /// Errors are rethrown UNWRAPPED, unlike the other receipt calls: the caller
  /// has to tell "this server has no `get_payment_receipt` yet" (fall back to
  /// [listPaymentReceipts]) from "the receipt is gone / not your branch" (no
  /// current receipt), and that needs the HTTP status and the raw Frappe body
  /// that `_friendlyException` flattens away. See
  /// `classifyReceiptLookupError` in `widgets/transfer_proof_logic.dart`.
  Future<Map<String, dynamic>?> getPaymentReceipt({
    required String receiptName,
  }) async {
    try {
      _logger.info('Fetching payment receipt $receiptName');
      final resp = await _dio.post(
        _getPaymentReceiptEndpoint,
        data: {'receipt_name': receiptName},
      );
      final data = resp.data;
      final msg = data is Map ? data['message'] : null;
      if (msg is Map) {
        if (msg['success'] == true) {
          final receipt = msg['receipt'];
          return receipt is Map ? Map<String, dynamic>.from(receipt) : null;
        }
        throw Exception(
          _friendlyMessage(msg, fallback: 'Failed to fetch payment receipt'),
        );
      }
      throw Exception('Failed to fetch payment receipt');
    } catch (e) {
      _logger.error('Failed to get payment receipt $receiptName', e);
      rethrow;
    }
  }

  /// Create a payment receipt record
  Future<Map<String, dynamic>> createPaymentReceipt({
    required String salesInvoice,
    required String paymentMethod,
    required double amount,
    required String posProfile,
  }) async {
    try {
      _logger.info('Creating payment receipt for $salesInvoice ($paymentMethod)');
      final resp = await _dio.post(
        ApiEndpoints.createPaymentReceipt,
        data: {
          'sales_invoice': salesInvoice,
          'payment_method': paymentMethod,
          'amount': amount,
          'pos_profile': posProfile,
        },
      );
      final msg = resp.data['message'];
      if (msg is Map && msg['success'] == true) {
        _logger.info('Payment receipt created: ${msg['receipt_name']}');
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(_friendlyMessage(msg, fallback: 'Failed to create receipt'));
    } catch (e) {
      _logger.error('Failed to create payment receipt', e);
      throw _friendlyException(e, fallback: 'Failed to create receipt');
    }
  }

  /// Upload receipt image (base64 encoded)
  Future<Map<String, dynamic>> uploadReceiptImage({
    required String receiptName,
    required String imageData,
    required String filename,
  }) async {
    // Chokepoint guard, deliberately outside the try/catch below so it can
    // never be reshaped into a server error.
    //
    // A picker that hands back a zero-byte file (permission revoked mid-pick,
    // an unreadable cloud/HEIC asset, a cancelled camera write) base64-encodes
    // to the empty string. The backend answered "File does not exist" and the
    // sheet still reported success, so an InstaPay payment was confirmed with
    // no proof attached. Refuse here rather than at any one call site: this is
    // the single point every present and future caller passes through.
    if (imageData.isEmpty) {
      _logger.error('Refusing to upload an empty receipt image for $receiptName');
      throw Exception('Receipt image is empty');
    }
    try {
      _logger.info('Uploading receipt image for $receiptName');
      final resp = await _dio.post(
        ApiEndpoints.uploadReceiptImage,
        data: {
          'receipt_name': receiptName,
          'image_data': imageData,
          'filename': filename,
        },
      );
      final msg = resp.data['message'];
      if (msg is Map && msg['success'] == true) {
        _logger.info('Receipt image uploaded successfully');
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(_friendlyMessage(msg, fallback: 'Failed to upload image'));
    } catch (e) {
      _logger.error('Failed to upload receipt image', e);
      throw _friendlyException(e, fallback: 'Failed to upload image');
    }
  }

  /// Remove the uploaded image from an unconfirmed payment receipt
  Future<Map<String, dynamic>> removeReceiptImage({
    required String receiptName,
  }) async {
    try {
      _logger.info('Removing receipt image for $receiptName');
      final resp = await _dio.post(
        ApiEndpoints.removeReceiptImage,
        data: {
          'receipt_name': receiptName,
        },
      );
      final msg = resp.data['message'];
      if (msg is Map && msg['success'] == true) {
        _logger.info('Receipt image removed successfully');
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(_friendlyMessage(msg, fallback: 'Failed to remove image'));
    } catch (e) {
      _logger.error('Failed to remove receipt image', e);
      throw _friendlyException(e, fallback: 'Failed to remove image');
    }
  }

  /// Confirm a payment receipt
  Future<Map<String, dynamic>> confirmReceipt({
    required String receiptName,
  }) async {
    try {
      _logger.info('Confirming receipt $receiptName');
      final resp = await _dio.post(
        ApiEndpoints.confirmReceipt,
        data: {
          'receipt_name': receiptName,
        },
      );
      final msg = resp.data['message'];
      if (msg is Map && msg['success'] == true) {
        _logger.info('Receipt confirmed successfully');
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(_friendlyMessage(msg, fallback: 'Failed to confirm receipt'));
    } catch (e) {
      _logger.error('Failed to confirm receipt', e);
      throw _friendlyException(e, fallback: 'Failed to confirm receipt');
    }
  }

  /// Turn down a payment receipt, recording why.
  ///
  /// The counterpart Confirm never had. Without it the only way to register
  /// "this screenshot is not proof of payment" was to leave the receipt alone,
  /// which reads exactly like nobody having looked at it yet -- and the branch
  /// keeps chasing a customer who already paid, or stops chasing one who did
  /// not.
  Future<Map<String, dynamic>> rejectReceipt({
    required String receiptName,
    required String reason,
  }) async {
    try {
      _logger.info('Rejecting receipt $receiptName');
      final resp = await _dio.post(
        ApiEndpoints.rejectReceipt,
        data: {
          'receipt_name': receiptName,
          'reason': reason,
        },
      );
      final msg = resp.data['message'];
      if (msg is Map && msg['success'] == true) {
        _logger.info('Receipt rejected');
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(_friendlyMessage(msg, fallback: 'Failed to reject receipt'));
    } catch (e) {
      _logger.error('Failed to reject receipt', e);
      throw _friendlyException(e, fallback: 'Failed to reject receipt');
    }
  }

  /// Get user's accessible POS profiles
  Future<List<String>> getAccessiblePOSProfiles() async {
    try {
      _logger.info('Fetching accessible POS profiles');
      final resp = await _dio.get(
        ApiEndpoints.getAccessiblePosProfiles,
      );
      final msg = resp.data['message'];
      if (msg is List) {
        return List<String>.from(msg);
      }
      throw Exception('Failed to fetch accessible POS profiles');
    } catch (e) {
      _logger.error('Failed to get accessible POS profiles', e);
      rethrow;
    }
  }

  // ── Sub-territory methods ─────────────────────────────────────────────

  /// Fetch child territories for a given parent territory
  Future<List<Map<String, dynamic>>> getSubTerritories(String territory) async {
    try {
      _logger.info('Fetching sub-territories for $territory');
      final resp = await _dio.get(
        ApiEndpoints.getSubTerritories,
        queryParameters: {'territory_name': territory},
      );
      final msg = resp.data['message'];
      if (msg is Map && msg['success'] == true) {
        return List<Map<String, dynamic>>.from(msg['data'] ?? []);
      }
      throw Exception(_friendlyMessage(msg, fallback: 'Failed to fetch sub-territories'));
    } catch (e) {
      _logger.error('Failed to get sub-territories', e);
      throw _friendlyException(e, fallback: 'Failed to fetch sub-territories');
    }
  }

  /// Assign a sub-territory to an invoice
  Future<Map<String, dynamic>> setInvoiceSubTerritory(String invoiceName, String subTerritory) async {
    try {
      _logger.info('Setting sub-territory $subTerritory on $invoiceName');
      final resp = await _dio.post(
        ApiEndpoints.setInvoiceSubTerritory,
        data: {'invoice_name': invoiceName, 'sub_territory': subTerritory},
      );
      final msg = resp.data['message'];
      if (msg is Map && msg['success'] == true) {
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(_friendlyMessage(msg, fallback: 'Failed to set sub-territory'));
    } catch (e) {
      _logger.error('Failed to set sub-territory', e);
      throw _friendlyException(e, fallback: 'Failed to set sub-territory');
    }
  }

  // ── Delivery Trip methods ─────────────────────────────────────────────

  /// Create a delivery trip grouping the given invoices
  Future<Map<String, dynamic>> createDeliveryTrip({
    required List<String> invoiceNames,
    required String partyType,
    required String party,
  }) async {
    try {
      _logger.info('Creating delivery trip with ${invoiceNames.length} invoices');
      final resp = await _dio.post(
        ApiEndpoints.createDeliveryTrip,
        data: {
          'invoice_names': json.encode(invoiceNames),
          'party_type': partyType,
          'party': party,
        },
      );
      final msg = resp.data['message'];
      if (msg is Map && msg['success'] == true) {
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(msg is Map ? msg['message'] ?? 'Failed' : 'Failed to create trip');
    } catch (e) {
      _logger.error('Failed to create delivery trip', e);
      rethrow;
    }
  }

  /// List delivery trips with optional filters
  Future<List<Map<String, dynamic>>> getDeliveryTrips({
    String? status,
    String? courierParty,
    String? dateFrom,
    String? dateTo,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      _logger.info('Fetching delivery trips');
      final resp = await _dio.get(
        ApiEndpoints.getDeliveryTrips,
        queryParameters: {
          if (status != null) 'status': status,
          if (courierParty != null) 'courier_party': courierParty,
          if (dateFrom != null) 'date_from': dateFrom,
          if (dateTo != null) 'date_to': dateTo,
          'limit': limit,
          'offset': offset,
        },
      );
      final msg = resp.data['message'];
      if (msg is Map && msg['success'] == true) {
        return List<Map<String, dynamic>>.from(msg['data'] ?? []);
      }
      throw Exception('Failed to fetch delivery trips');
    } catch (e) {
      _logger.error('Failed to get delivery trips', e);
      rethrow;
    }
  }

  /// Get full details of a delivery trip
  Future<Map<String, dynamic>> getTripDetails(String tripName) async {
    try {
      _logger.info('Fetching trip details for $tripName');
      final resp = await _dio.get(
        ApiEndpoints.getTripDetails,
        queryParameters: {'trip_name': tripName},
      );
      final msg = resp.data['message'];
      if (msg is Map && msg['success'] == true) {
        return Map<String, dynamic>.from(msg['trip'] ?? msg);
      }
      throw Exception('Failed to fetch trip details');
    } catch (e) {
      _logger.error('Failed to get trip details', e);
      rethrow;
    }
  }

  /// Send a delivery trip for delivery (bulk OFD)
  Future<Map<String, dynamic>> sendTripForDelivery(String tripName) async {
    try {
      _logger.info('Sending trip $tripName for delivery');
      final resp = await _dio.post(
        ApiEndpoints.sendTripForDelivery,
        data: {'trip_name': tripName},
      );
      final msg = resp.data['message'];
      if (msg is Map && msg['success'] == true) {
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(msg is Map ? msg['message'] ?? 'Failed' : 'Failed to send trip for delivery');
    } catch (e) {
      _logger.error('Failed to send trip for delivery', e);
      rethrow;
    }
  }

  // ── Custom Shipping methods ───────────────────────────────────────────

  /// Request custom shipping for an invoice
  Future<Map<String, dynamic>> requestCustomShipping({
    required String invoiceName,
    required double amount,
    required String reason,
  }) async {
    try {
      _logger.info('Requesting custom shipping for $invoiceName');
      final resp = await _dio.post(
        ApiEndpoints.requestCustomShipping,
        data: {
          'invoice_name': invoiceName,
          'amount': amount,
          'reason': reason,
        },
      );
      final msg = resp.data['message'];
      if (msg is Map && msg['success'] == true) {
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(msg is Map ? msg['message'] ?? 'Failed' : 'Failed to request custom shipping');
    } catch (e) {
      _logger.error('Failed to request custom shipping', e);
      rethrow;
    }
  }

  /// Approve a custom shipping request (manager only)
  Future<Map<String, dynamic>> approveCustomShipping(String requestName) async {
    try {
      _logger.info('Approving custom shipping request $requestName');
      final resp = await _dio.post(
        ApiEndpoints.approveCustomShipping,
        data: {'request_name': requestName},
      );
      final msg = resp.data['message'];
      if (msg is Map && msg['success'] == true) {
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(msg is Map ? msg['message'] ?? 'Failed' : 'Failed to approve');
    } catch (e) {
      _logger.error('Failed to approve custom shipping', e);
      rethrow;
    }
  }

  /// Reject a custom shipping request (manager only)
  Future<Map<String, dynamic>> rejectCustomShipping(String requestName, {String reason = ''}) async {
    try {
      _logger.info('Rejecting custom shipping request $requestName');
      final resp = await _dio.post(
        ApiEndpoints.rejectCustomShipping,
        data: {'request_name': requestName, 'rejection_reason': reason},
      );
      final msg = resp.data['message'];
      if (msg is Map && msg['success'] == true) {
        return Map<String, dynamic>.from(msg);
      }
      throw Exception(msg is Map ? msg['message'] ?? 'Failed' : 'Failed to reject');
    } catch (e) {
      _logger.error('Failed to reject custom shipping', e);
      rethrow;
    }
  }

  /// Set a custom delivery income on an existing invoice via amendment.
  ///
  /// The cart is NOT reconstructed here: `reuse_source_cart` tells the backend to
  /// rebuild it from the invoice's own rows. Only the invoice-level delivery
  /// income changes, and the server has the persisted bundle group keys that a
  /// client-side reconstruction cannot recover — a bundle listing the same item
  /// group twice used to fail validation on the way back in.
  /// [customDeliveryIncome] null = revert to territory default; 0 = free; >0 = custom.
  Future<Map<String, dynamic>> setDeliveryIncomeAmendment({
    required InvoiceCard invoice,
    required double? customDeliveryIncome,
  }) async {
    _logger.info(
      'setDeliveryIncomeAmendment invoice=${invoice.id} override=$customDeliveryIncome',
    );

    final data = <String, dynamic>{
      'invoice_id': invoice.id,
      'reuse_source_cart': 1,
      // Always send the key: '' = clear override (revert to territory default); number = custom.
      'custom_delivery_income': customDeliveryIncome ?? '',
      'suppress_legacy_delivery_charges': 1,
    };

    final resp = await _dio.post(
      ApiEndpoints.submitInvoiceAmendment,
      data: data,
    );
    final msg = resp.data['message'];
    if (msg is Map) return Map<String, dynamic>.from(msg);
    throw Exception('Unexpected response from amendment');
  }

  /// Get pending custom shipping requests (manager dashboard)
  Future<List<Map<String, dynamic>>> getPendingCustomShippingRequests() async {
    try {
      _logger.info('Fetching pending custom shipping requests');
      final resp = await _dio.get(ApiEndpoints.getPendingCustomShippingRequests);
      final msg = resp.data['message'];
      if (msg is Map && msg['success'] == true) {
        return List<Map<String, dynamic>>.from(msg['data'] ?? []);
      }
      throw Exception('Failed to fetch pending requests');
    } catch (e) {
      _logger.error('Failed to get pending custom shipping requests', e);
      rethrow;
    }
  }
}
