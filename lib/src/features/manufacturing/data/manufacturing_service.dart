import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/frappe_error_message.dart';
import '../../../core/constants/api_endpoints.dart';
import 'models/base_batch_preview.dart';
import 'models/base_item.dart';
import 'models/basket_rollup.dart';
import 'models/bom_details.dart';
import 'models/material_move_result.dart';
import 'models/material_options.dart';
import 'models/production_policy.dart';
import 'models/production_suggestion.dart';
import 'models/recipe_sheet.dart';
import 'models/running_batch.dart';
import 'models/shortage_count_plan.dart';
import 'models/sop.dart';

final manufacturingServiceProvider = Provider<ManufacturingService>((ref) {
  final dio = ref.watch(dioProvider);
  return ManufacturingService(dio);
});

class ManufacturingService {
  static const _getMaterialOptionsEndpoint =
      '/api/method/jarz_pos.api.manufacturing.get_material_options';

  /// Kept here rather than in `ApiEndpoints` so this feature ships as an OTA
  /// patch: `core/**` changes force a full APK.
  static const _getRecipeSheetEndpoint =
      '/api/method/jarz_pos.api.sop.get_recipe_sheet';

  /// The "counted wrong" fix for a basket shortage. Kept here for the same
  /// reason as the recipe sheet endpoint.
  static const _previewShortageCountFixEndpoint =
      '/api/method/jarz_pos.api.production.preview_shortage_count_fix';
  static const _fixShortageByCountEndpoint =
      '/api/method/jarz_pos.api.production.fix_shortage_by_count';
  final Dio _dio;
  ManufacturingService(this._dio);

  /// What the shortage correction would post: items, counts, and the count
  /// moment a few minutes before production. Posts nothing.
  ///
  /// [countAt] ("YYYY-MM-DD HH:MM:SS") dates the count earlier than that
  /// default; the server refuses a later one.
  Future<ShortageCountPlan> previewShortageCountFix(
    List<Map<String, dynamic>> lines, {
    String? scheduledAt,
    String? countAt,
  }) async {
    try {
      final resp = await _dio.post(
        _previewShortageCountFixEndpoint,
        data: {
          'lines': lines,
          if (scheduledAt != null) 'scheduled_at': scheduledAt,
          if (countAt != null) 'count_at': countAt,
        },
      );
      return ShortageCountPlan.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to check missing stock');
    }
  }

  /// Posts the correction as a Stock Reconciliation. [lines] and
  /// [scheduledAt] must be what the preview was asked about: the server
  /// recomputes the counts from them rather than trusting the client.
  Future<ShortageCountPlan> fixShortageByCount(
    List<Map<String, dynamic>> lines, {
    String? scheduledAt,
    String? countAt,
  }) async {
    try {
      final resp = await _dio.post(
        _fixShortageByCountEndpoint,
        data: {
          'lines': lines,
          if (scheduledAt != null) 'scheduled_at': scheduledAt,
          if (countAt != null) 'count_at': countAt,
          'confirm_miscount': 1,
        },
      );
      return ShortageCountPlan.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to add missing stock');
    }
  }

  Exception _friendlyError(Object error, {required String fallback}) {
    return mapFrappeError(error, fallback: fallback);
  }

  Future<List<Map<String, dynamic>>> listDefaultBomItems(String search) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.listDefaultBomItems,
        data: {'search': search},
      );
      final payload = resp.data;
      if (payload is Map && payload['message'] is List) {
        return (payload['message'] as List).cast<Map<String, dynamic>>();
      }
      if (payload is List) return payload.cast<Map<String, dynamic>>();
      return [];
    } catch (error) {
      throw _friendlyError(
        error,
        fallback: 'Failed to load manufacturing items',
      );
    }
  }

  Future<Map<String, dynamic>> getBomDetails(String itemCode) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.getBomDetails,
        data: {'item_code': itemCode},
      );
      final payload = resp.data;
      if (payload is Map && payload['message'] is Map) {
        return Map<String, dynamic>.from(payload['message'] as Map);
      }
      if (payload is Map) return Map<String, dynamic>.from(payload);
      throw Exception('Unexpected BOM details response');
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to load BOM details');
    }
  }

  Future<Map<String, dynamic>> submitWorkOrders(
    List<Map<String, dynamic>> lines,
  ) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.submitWorkOrders,
        data: {'lines': lines},
      );
      final payload = resp.data;
      if (payload is Map && payload['message'] is Map) {
        return Map<String, dynamic>.from(payload['message'] as Map);
      }
      if (payload is Map) return Map<String, dynamic>.from(payload);
      throw Exception('Unexpected submit response');
    } catch (error) {
      throw _friendlyError(
        error,
        fallback: 'Failed to submit manufacturing work orders',
      );
    }
  }

  /// Books what ACTUALLY came out of the kitchen, line by line.
  ///
  /// Same line objects and same response shape as [submitWorkOrders]
  /// (`{"results": [...], "basket_shortages": [...]}`), so both share the one
  /// result parser. The difference is intent, not payload: this is the Today
  /// screen recording a finished run, not the Batch tab queueing one.
  ///
  /// [strictBasket] asks the server to refuse the whole call when the
  /// consolidated material check comes up short, instead of posting the lines
  /// it can and leaving the day half-recorded. It is why bases and jars must
  /// go as two calls — jars eat the mix the bases have just made, and a single
  /// basket would be refused for material that is about to exist.
  Future<Map<String, dynamic>> produceNow(
    List<Map<String, dynamic>> lines, {
    bool strictBasket = true,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.produceNow,
        data: {'lines': lines, 'strict_basket': strictBasket ? 1 : 0},
      );
      final payload = resp.data;
      if (payload is Map && payload['message'] is Map) {
        return Map<String, dynamic>.from(payload['message'] as Map);
      }
      if (payload is Map) return Map<String, dynamic>.from(payload);
      throw Exception('Unexpected produce response');
    } catch (error) {
      throw _friendlyError(
        error,
        fallback: 'Failed to record what was produced',
      );
    }
  }

  Future<MaterialOptions> getMaterialOptions({
    required String bomName,
    required double qty,
  }) async {
    try {
      final resp = await _dio.post(
        _getMaterialOptionsEndpoint,
        data: {'bom_name': bomName, 'qty': qty},
      );
      return MaterialOptions.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw _friendlyError(
        error,
        fallback: 'Failed to load ingredient choices',
      );
    }
  }

  Future<Map<String, dynamic>> submitSingleWorkOrder({
    required String itemCode,
    required String bomName,
    required double itemQty,
    String? scheduledAt,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.submitSingleWorkOrder,
        data: {
          'item_code': itemCode,
          'bom_name': bomName,
          'item_qty': itemQty,
          if (scheduledAt != null) 'scheduled_at': scheduledAt,
        },
      );
      final payload = resp.data;
      if (payload is Map && payload['message'] is Map) {
        return Map<String, dynamic>.from(payload['message'] as Map);
      }
      if (payload is Map) return Map<String, dynamic>.from(payload);
      throw Exception('Unexpected single submit response');
    } catch (error) {
      throw _friendlyError(
        error,
        fallback: 'Failed to submit manufacturing work order',
      );
    }
  }

  /// Ranked production suggestions with quantities already computed.
  ///
  /// [includeCapacity] false skips the per-BOM explosion server-side and
  /// returns null capacities — the escape hatch if the board gets slow.
  Future<ProductionSuggestionsPage> getProductionSuggestions({
    String? company,
    String? search,
    String? status,
    bool includeCapacity = true,
    bool forceRefresh = false,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.getProductionSuggestions,
        data: {
          if (company != null) 'company': company,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          'include_capacity': includeCapacity ? 1 : 0,
          'force_refresh': forceRefresh ? 1 : 0,
        },
      );
      return ProductionSuggestionsPage.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw _friendlyError(
        error,
        fallback: 'Failed to load production suggestions',
      );
    }
  }

  /// Consolidated material demand across every line in the basket.
  ///
  /// The per-line check cannot see two lines drawing on the same pile.
  Future<BasketRollup> getBasketMaterialRollup(
    List<Map<String, dynamic>> lines, {
    String? company,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.getBasketMaterialRollup,
        data: {'lines': lines, if (company != null) 'company': company},
      );
      return BasketRollup.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to check batch materials');
    }
  }

  /// Overrides the cover target for one item. Null or 0 restores the default.
  Future<Map<String, dynamic>> setItemTargetDays({
    required String itemCode,
    int? targetDays,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.setItemTargetDays,
        data: {'item_code': itemCode, 'target_days': targetDays ?? 0},
      );
      return _unwrapMap(resp.data);
    } catch (error) {
      throw _friendlyError(
        error,
        fallback: 'Failed to update target days of cover',
      );
    }
  }

  /// Typed wrapper over [listDefaultBomItems] for the manual search path.
  Future<List<BomItemSummary>> searchBomItems(String search) async {
    final rows = await listDefaultBomItems(search);
    return rows.map(BomItemSummary.fromJson).toList(growable: false);
  }

  /// Typed wrapper over [getBomDetails].
  Future<BomDetails> fetchBomDetails(String itemCode) async {
    return BomDetails.fromJson(await getBomDetails(itemCode));
  }

  // ── Sub-assemblies / bases ──────────────────────────

  /// The bases the floor can make a run of, with freezer stock already read
  /// back as batches.
  ///
  /// Bases are never sold, so `get_production_suggestions` computes zero for
  /// every one of them and the Plan tab hides its action panel. This endpoint
  /// answers the batch question instead.
  ///
  /// [includeDemand] false skips the plan / suggestion roll-up server-side and
  /// returns rows with no `demand` block — the escape hatch if the list gets
  /// slow, matching `includeCapacity` on the sales board.
  Future<BaseItemsPage> getBaseItems({
    String? company,
    String? search,
    bool includeDemand = true,
    String? planDate,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.getBaseItems,
        data: {
          if (company != null) 'company': company,
          if (search != null && search.isNotEmpty) 'search': search,
          'include_demand': includeDemand ? 1 : 0,
          if (planDate != null && planDate.isNotEmpty) 'plan_date': planDate,
        },
      );
      return BaseItemsPage.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to load base items');
    }
  }

  /// What a run would consume, before anybody commits to it.
  ///
  /// Deliberately a separate call from [startProductionBatch]: the preview is
  /// re-taken every time the operator changes the number, and a start is a
  /// stock movement that must happen exactly once.
  ///
  /// Send [qty] for anything weighed and [batches] for anything counted — never
  /// both. A mix has no batch to speak of, so routing it through a batch count
  /// would invent one and then divide by it; the server treats [qty] as
  /// authoritative when it is present and reports the batch count it implies.
  Future<BaseBatchPreview> previewBaseBatch({
    required String itemCode,
    double? batches,
    double? qty,
    String? bomName,
    String? company,
    Map<String, String> materialSelections = const {},
  }) async {
    assert(
      batches != null || qty != null,
      'previewBaseBatch needs a quantity or a batch count',
    );
    try {
      final resp = await _dio.post(
        ApiEndpoints.previewBaseBatch,
        data: {
          'item_code': itemCode,
          // Only one goes on the wire. Sending both would leave which of them
          // wins to the server's precedence rule rather than to the caller's
          // intent, and the two disagree the moment a yield changes.
          if (qty != null) 'qty': qty else 'batches': batches,
          if (bomName != null && bomName.isNotEmpty) 'bom_name': bomName,
          if (company != null) 'company': company,
          if (materialSelections.isNotEmpty)
            'material_selections': materialSelections,
        },
      );
      return BaseBatchPreview.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to check batch materials');
    }
  }

  /// The posting window and permissions the server will actually enforce.
  ///
  /// Read rather than assumed: the app's own constant and the server's setting
  /// disagreed silently, which showed up on the floor as a date picker that
  /// offered yesterday and a submit that refused it.
  Future<ProductionPolicy> getProductionPolicy() async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.getProductionPolicy,
        data: const <String, dynamic>{},
      );
      return ProductionPolicy.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw _friendlyError(
        error,
        fallback: 'Failed to load production settings',
      );
    }
  }

  /// Moves [qty] of [itemCode] out of [fromWarehouse] and into the warehouse
  /// its recipe draws from.
  ///
  /// [toWarehouse] is only needed when the component is drawn from more than
  /// one warehouse; the server picks the single one otherwise, and refuses any
  /// destination the component is not actually demanded from.
  Future<MaterialMoveResult> transferMaterialForProduction({
    required String itemCode,
    required String fromWarehouse,
    required double qty,
    String? toWarehouse,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.transferMaterialForProduction,
        data: {
          'item_code': itemCode,
          'from_warehouse': fromWarehouse,
          'qty': qty,
          if (toWarehouse != null && toWarehouse.isNotEmpty)
            'to_warehouse': toWarehouse,
        },
      );
      return MaterialMoveResult.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to move the stock');
    }
  }

  // ── Start / finish (stage 2) ────────────────────────────────────────

  /// Starts a batch: creates the Work Order and files the material transfer
  /// ONLY. No Manufacture entry until [finishProductionBatch].
  Future<StartBatchResult> startProductionBatch({
    required String itemCode,
    required String bomName,
    required double itemQty,
    String? scheduledAt,
    Map<String, String> materialSelections = const {},
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.startProductionBatch,
        data: {
          'item_code': itemCode,
          'bom_name': bomName,
          'item_qty': itemQty,
          if (scheduledAt != null) 'scheduled_at': scheduledAt,
          if (materialSelections.isNotEmpty)
            'material_selections': materialSelections,
        },
      );
      return StartBatchResult.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to start the batch');
    }
  }

  /// Starts several batches under ONE basket-wide material check.
  ///
  /// Same `{"results": [...], "basket_shortages": [...]}` envelope as
  /// [produceNow], so [parseProduceResults] reads both — but only the material
  /// transfer is posted per line. What each batch actually yielded is recorded
  /// later on the Running tab.
  ///
  /// Not a loop over [startProductionBatch]: that would run one check per line,
  /// and a basket can clear every line on its own while collectively emptying a
  /// store. Because each line commits as it succeeds, discovering that on the
  /// last line leaves the earlier ones' material already in WIP.
  Future<Map<String, dynamic>> startProductionBatches(
    List<Map<String, dynamic>> lines, {
    bool strictBasket = true,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.startProductionBatches,
        data: {'lines': lines, 'strict_basket': strictBasket ? 1 : 0},
      );
      final payload = resp.data;
      if (payload is Map && payload['message'] is Map) {
        return Map<String, dynamic>.from(payload['message'] as Map);
      }
      if (payload is Map) return Map<String, dynamic>.from(payload);
      throw Exception('Unexpected start response');
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to start the batches');
    }
  }

  /// Finishes a batch with the quantity that actually came out.
  ///
  /// [actualQty] drives the Manufacture entry; [scrapQty] is recorded on the
  /// Work Order as a reported figure and does not post stock.
  Future<FinishBatchResult> finishProductionBatch({
    required String workOrder,
    required double actualQty,
    double scrapQty = 0,
    String? scheduledAt,
    String? notes,
    bool returnLeftover = false,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.finishProductionBatch,
        data: {
          'work_order': workOrder,
          'actual_qty': actualQty,
          'scrap_qty': scrapQty,
          if (scheduledAt != null) 'scheduled_at': scheduledAt,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          // Off unless the operator said the batch is done. The server cannot
          // tell a short yield from a batch still in the mixer -- both are a
          // finish for less than the planned quantity -- so returning by
          // default would empty WIP under work that is still running.
          'return_leftover': returnLeftover ? 1 : 0,
        },
      );
      return FinishBatchResult.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to finish the batch');
    }
  }

  Future<List<RunningBatch>> listRunningWorkOrders({int limit = 50}) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.listRunningWorkOrders,
        data: {'limit': limit},
      );
      return _unwrapList(resp.data).map(RunningBatch.fromJson).toList();
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to load running batches');
    }
  }

  Future<BatchCost> getBatchCost(String workOrder) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.getBatchCost,
        data: {'work_order': workOrder},
      );
      return BatchCost.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to load batch cost');
    }
  }

  /// Manager-only: returns un-consumed WIP material to its source warehouse.
  Future<Map<String, dynamic>> returnWipToStore(String workOrder) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.returnWipToStore,
        data: {'work_order': workOrder},
      );
      return _unwrapMap(resp.data);
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to return WIP material');
    }
  }

  /// Aborts a started batch: returns whatever is still in WIP and stops the
  /// Work Order.
  ///
  /// The server refuses once anything has been produced, and the message it
  /// returns names the alternative (finish the batch for what was actually
  /// made). That message is surfaced verbatim rather than replaced by the
  /// fallback, which is the whole point of `_friendlyError`.
  Future<Map<String, dynamic>> cancelProductionBatch({
    required String workOrder,
    required String reason,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.cancelProductionBatch,
        data: {'work_order': workOrder, 'reason': reason},
      );
      return _unwrapMap(resp.data);
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to cancel the batch');
    }
  }

  // ── SOPs (stage 3) ──────────────────────────────────────────────────

  /// Returns `hasSop: false` rather than throwing when an item has no SOP —
  /// most do not, and the board asks for every item.
  Future<SopDocument> getSopForItem({
    required String itemCode,
    String? bom,
    double batches = 1,
    double? units,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.getSopForItem,
        data: {
          'item_code': itemCode,
          if (bom != null) 'bom': bom,
          'batches': batches,
          if (units != null) 'units': units,
        },
      );
      return SopDocument.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to load the SOP');
    }
  }

  /// Item codes with an active SOP, so a row can offer its recipe without
  /// fetching every item's document. `{"message": {"item_codes": [...]}}`.
  Future<Set<String>> listItemsWithSop() async {
    try {
      final resp = await _dio.get(ApiEndpoints.listItemsWithSop);
      final payload = resp.data;
      final message = payload is Map ? payload['message'] : null;
      final codes = message is Map ? message['item_codes'] : null;
      if (codes is! List) return const <String>{};
      return {
        for (final code in codes)
          if (code != null && code.toString().trim().isNotEmpty)
            code.toString().trim(),
      };
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to load the SOP list');
    }
  }

  /// One combined recipe sheet per recipe family for every jar typed, e.g. all
  /// Tiramisu sizes made together. [quantities] maps item code to an amount:
  /// a whole jar count for a jar, or a fractional amount in the item's stock
  /// UOM for a base (12.5 Kg of Fudge Cake). Ints go out as ints, so a jar
  /// request is byte-for-byte what it always was. Zero or negative amounts are
  /// dropped, and an empty request answers itself without a call. Items
  /// without a recipe are simply absent from the answer.
  Future<RecipeSheetResponse> getRecipeSheet(
    Map<String, num> quantities,
  ) async {
    final lines = [
      for (final entry in quantities.entries)
        if (entry.value > 0) {'item_code': entry.key, 'qty': entry.value},
    ];
    if (lines.isEmpty) return RecipeSheetResponse.empty;
    try {
      final resp = await _dio.post(
        _getRecipeSheetEndpoint,
        // A JSON string, which `frappe.parse_json` reads whether the body
        // arrives as form fields or as JSON.
        data: {'lines': jsonEncode(lines)},
      );
      return RecipeSheetResponse.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to load the recipe');
    }
  }

  /// Returns the SOP version stamped on the Work Order when it started, not
  /// whatever is active now — otherwise editing an SOP silently rewrites the
  /// method every past batch was made by.
  Future<SopDocument> getSopForWorkOrder(String workOrder) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.getSopForWorkOrder,
        data: {'work_order': workOrder},
      );
      return SopDocument.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to load the SOP');
    }
  }

  Future<Map<String, dynamic>> recordSopStepCapture({
    required String workOrder,
    required int stepNo,
    double? value,
    String? fileUrl,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.recordSopStepCapture,
        data: {
          'work_order': workOrder,
          'step_no': stepNo,
          if (value != null) 'value': value,
          if (fileUrl != null) 'file_url': fileUrl,
        },
      );
      return _unwrapMap(resp.data);
    } catch (error) {
      throw _friendlyError(error, fallback: 'Failed to record the reading');
    }
  }

  /// Unwraps Frappe's `{"message": [...]}` envelope down to a List of Maps.
  List<Map<String, dynamic>> _unwrapList(dynamic payload) {
    if (payload is Map && payload['message'] is List) {
      return (payload['message'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (payload is List) {
      return payload.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const [];
  }

  /// Unwraps Frappe's `{"message": ...}` envelope down to a Map.
  Map<String, dynamic> _unwrapMap(dynamic payload) {
    if (payload is Map && payload['message'] is Map) {
      return Map<String, dynamic>.from(payload['message'] as Map);
    }
    if (payload is Map) return Map<String, dynamic>.from(payload);
    throw Exception('Unexpected response shape');
  }

  /// Work Orders newest first. Each row carries `creation` (when the order was
  /// entered) and `posted_at` (when its Manufacture entry hit stock, or null).
  /// [dateBasis] is `posting` or `creation`: which of the two [fromDate] and
  /// [toDate] filter on and the list sorts by.
  Future<List<Map<String, dynamic>>> listRecentWorkOrders({
    int limit = 50,
    String? search,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    String dateBasis = 'creation',
  }) async {
    String day(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    try {
      final resp = await _dio.post(
        ApiEndpoints.listRecentWorkOrders,
        data: {
          "limit": limit,
          "date_basis": dateBasis,
          if (search != null && search.trim().isNotEmpty)
            "search": search.trim(),
          if (status != null && status.isNotEmpty) "status": status,
          if (fromDate != null) "from_date": day(fromDate),
          if (toDate != null) "to_date": day(toDate),
        },
      );
      final payload = resp.data;
      if (payload is Map && payload['message'] is List) {
        return (payload['message'] as List).cast<Map<String, dynamic>>();
      }
      if (payload is List) return payload.cast<Map<String, dynamic>>();
      return [];
    } catch (error) {
      throw _friendlyError(
        error,
        fallback: 'Failed to load recent work orders',
      );
    }
  }
}
