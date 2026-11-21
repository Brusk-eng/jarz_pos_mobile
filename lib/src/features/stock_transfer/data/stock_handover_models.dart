/// Plain models for the Stock Handover API (`jarz_pos.api.stock_handover`).
///
/// A handover is one side saying "this stock moved" and the OTHER side
/// confirming it; only the confirmation posts a Stock Entry. Every parser here
/// is lenient on purpose: a missing field reads as empty rather than throwing,
/// so one odd row can never blank the whole screen.
library;

import 'dart:convert';

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

String _toStr(Object? value) => value == null ? '' : value.toString();

String? _toOptStr(Object? value) {
  if (value == null) return null;
  final s = value.toString();
  return s.isEmpty ? null : s;
}

bool _toBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return false;
}

List<Map<String, dynamic>> _maps(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
}

/// Unwraps Frappe's `{"message": ...}` envelope when present.
Object? unwrapFrappeMessage(Object? payload) {
  if (payload is Map && payload.containsKey('message')) {
    return payload['message'];
  }
  return payload;
}

Map<String, dynamic> unwrapFrappeMap(Object? payload) {
  final inner = unwrapFrappeMessage(payload);
  if (inner is Map) return Map<String, dynamic>.from(inner);
  return <String, dynamic>{};
}

/// A warehouse the user can act for, or a warehouse they hand stock to/from.
class HandoverSide {
  const HandoverSide({
    required this.warehouse,
    required this.label,
    required this.kind,
    this.posProfile,
  });

  final String warehouse;
  final String label;

  /// `branch` or `factory`.
  final String kind;

  /// Set for a branch side the user acts for through an open shift.
  final String? posProfile;

  bool get isFactory => kind == 'factory';
  bool get isBranch => kind == 'branch';

  factory HandoverSide.fromJson(Map<String, dynamic> json) {
    final warehouse = _toStr(json['warehouse']);
    final label = _toStr(json['label']);
    return HandoverSide(
      warehouse: warehouse,
      label: label.isEmpty ? warehouse : label,
      kind: _toStr(json['kind']),
      posProfile: _toOptStr(json['pos_profile']),
    );
  }
}

/// Who the user is for handovers (`get_context`).
class HandoverContext {
  const HandoverContext({
    this.mySides = const [],
    this.counterparts = const [],
    this.canManage = false,
    this.canPostDirect = false,
    this.canMatchTransit = false,
  });

  final List<HandoverSide> mySides;
  final List<HandoverSide> counterparts;

  /// `ROLES.STOCK_TRANSFER`: the full manager transfer screen applies too.
  final bool canManage;

  /// `can_post_direct`: a JARZ Manager may post a branch-touching transfer in
  /// one step (`submit_transfer(direct=1)`) instead of opening a handover.
  final bool canPostDirect;

  /// `can_match_transit`: a manager, who gets the Transit board.
  final bool canMatchTransit;

  bool get canDeclare => mySides.isNotEmpty;

  /// Everyone this [side] can hand stock to/from: never itself, factory first,
  /// then the branches in the server's order.
  List<HandoverSide> counterpartsFor(HandoverSide side) {
    final others = counterparts
        .where((c) => c.warehouse != side.warehouse)
        .toList();
    final factory = others.where((c) => c.isFactory);
    final rest = others.where((c) => !c.isFactory);
    return [...factory, ...rest];
  }

  factory HandoverContext.fromJson(Map<String, dynamic> json) {
    return HandoverContext(
      mySides: _maps(json['my_sides']).map(HandoverSide.fromJson).toList(),
      counterparts:
          _maps(json['counterparts']).map(HandoverSide.fromJson).toList(),
      canManage: _toBool(json['can_manage']),
      canPostDirect: _toBool(json['can_post_direct']),
      canMatchTransit: _toBool(json['can_match_transit']),
    );
  }
}

/// One item that may be declared (`list_items`). Deliberately no stock
/// figures: the declaration is blind.
class HandoverItemOption {
  const HandoverItemOption({
    required this.itemCode,
    required this.itemName,
    this.itemGroup = '',
    this.stockUom = '',
  });

  final String itemCode;
  final String itemName;
  final String itemGroup;
  final String stockUom;

  factory HandoverItemOption.fromJson(Map<String, dynamic> json) {
    final code = _toStr(json['item_code']);
    final name = _toStr(json['item_name']);
    return HandoverItemOption(
      itemCode: code,
      itemName: name.isEmpty ? code : name,
      itemGroup: _toStr(json['item_group']),
      stockUom: _toStr(json['stock_uom']),
    );
  }
}

class StockHandoverLine {
  const StockHandoverLine({
    required this.itemCode,
    required this.itemName,
    this.stockUom = '',
    this.qty = 0,
    this.declaredQty = 0,
  });

  final String itemCode;
  final String itemName;
  final String stockUom;

  /// The quantity currently proposed.
  final double qty;

  /// What the first declaration said; differs from [qty] after a change.
  final double declaredQty;

  bool get isChanged => (qty - declaredQty).abs() > 1e-9;

  factory StockHandoverLine.fromJson(Map<String, dynamic> json) {
    final code = _toStr(json['item_code']);
    final name = _toStr(json['item_name']);
    final qty = _toDouble(json['qty']);
    return StockHandoverLine(
      itemCode: code,
      itemName: name.isEmpty ? code : name,
      stockUom: _toStr(json['stock_uom']),
      qty: qty,
      declaredQty:
          json.containsKey('declared_qty') ? _toDouble(json['declared_qty']) : qty,
    );
  }
}

/// One line inside a carton (or a hand-packed line).
class CartonPlanLine {
  const CartonPlanLine({
    required this.itemCode,
    required this.itemName,
    required this.qty,
  });

  final String itemCode;
  final String itemName;
  final int qty;

  factory CartonPlanLine.fromJson(Map<String, dynamic> json) {
    final code = _toStr(json['item_code']);
    final name = _toStr(json['item_name']);
    return CartonPlanLine(
      itemCode: code,
      itemName: name.isEmpty ? code : name,
      qty: _toDouble(json['qty']).round(),
    );
  }
}

/// One carton of the sender's packing plan.
class CartonPlanCarton {
  const CartonPlanCarton({
    required this.number,
    required this.type,
    required this.jars,
    this.lines = const [],
  });

  final int number;

  /// `large` or `b2b`.
  final String type;
  final int jars;
  final List<CartonPlanLine> lines;

  bool get isLarge => type == 'large';

  factory CartonPlanCarton.fromJson(Map<String, dynamic> json) {
    final lines = _maps(json['lines']).map(CartonPlanLine.fromJson).toList();
    final jars = _toDouble(json['jars']).round();
    return CartonPlanCarton(
      number: _toDouble(json['number']).round(),
      type: _toStr(json['type']) == 'large' ? 'large' : 'b2b',
      jars: jars > 0 ? jars : lines.fold(0, (sum, l) => sum + l.qty),
      lines: lines,
    );
  }
}

/// The cartons the sender packed for a transfer (`carton_plan`): how many to
/// expect and what is in each. Count only, never stock-moved.
class HandoverCartonPlan {
  const HandoverCartonPlan({
    required this.cartons,
    this.unpacked = const [],
    this.totalJars = 0,
  });

  final List<CartonPlanCarton> cartons;

  /// Lines packed by hand (jar size unknown to the packer).
  final List<CartonPlanLine> unpacked;
  final int totalJars;

  int get large => cartons.where((c) => c.isLarge).length;
  int get b2b => cartons.length - large;

  /// Reads the `carton_plan` value of a handover: a map, or a JSON string of
  /// one. Null for absent, malformed or empty plans so the UI simply hides it.
  static HandoverCartonPlan? tryParse(Object? raw) {
    try {
      var value = raw;
      if (value is String) {
        if (value.trim().isEmpty) return null;
        value = jsonDecode(value);
      }
      if (value is! Map) return null;
      final json = Map<String, dynamic>.from(value);
      final cartons =
          _maps(json['cartons']).map(CartonPlanCarton.fromJson).toList();
      final unpacked =
          _maps(json['unpacked']).map(CartonPlanLine.fromJson).toList();
      if (cartons.isEmpty) return null;
      final total = _toDouble(json['total_jars']).round();
      return HandoverCartonPlan(
        cartons: cartons,
        unpacked: unpacked,
        totalJars: total > 0 ? total : cartons.fold(0, (s, c) => s + c.jars),
      );
    } catch (_) {
      return null;
    }
  }
}

class StockHandover {
  const StockHandover({
    required this.name,
    required this.status,
    required this.fromWarehouse,
    required this.fromLabel,
    required this.toWarehouse,
    required this.toLabel,
    this.kind = 'Handover',
    this.groupSource,
    this.awaitingSide = '',
    this.awaitingLabel = '',
    this.declaredByName = '',
    this.declaredAt,
    this.lastProposedByName = '',
    this.lastProposedAt,
    this.changed = false,
    this.canRespond = false,
    this.canCancel = false,
    this.stockEntry,
    this.rejectReason,
    this.items = const [],
    this.cartonPlan,
  });

  final String name;

  /// Pending | Confirmed | Rejected | Cancelled
  final String status;
  final String fromWarehouse;
  final String fromLabel;

  /// Empty for a Dispatch ("sent out"): it has no destination until a manager
  /// matches it. [fromWarehouse] is empty for an unsourced receipt.
  final String toWarehouse;
  final String toLabel;

  /// `Handover` (one side to the other) | `Dispatch` ("I sent out").
  final String kind;

  /// The sender warehouse when this row sits in a manager match group.
  final String? groupSource;

  /// `From`, `To` or `Manager`.
  final String awaitingSide;
  final String awaitingLabel;
  final String declaredByName;
  final DateTime? declaredAt;
  final String lastProposedByName;
  final DateTime? lastProposedAt;
  final bool changed;
  final bool canRespond;
  final bool canCancel;
  final String? stockEntry;
  final String? rejectReason;
  final List<StockHandoverLine> items;

  /// The sender's carton packing plan, when the server sent one.
  final HandoverCartonPlan? cartonPlan;

  bool get isPending => status == 'Pending';
  bool get isConfirmed => status == 'Confirmed';
  bool get isRejected => status == 'Rejected';
  bool get isCancelled => status == 'Cancelled';

  /// A "sent out" declaration with no destination yet.
  bool get isDispatch => kind == 'Dispatch';

  /// A receipt held in a manager match group (waits for the manager, not the
  /// sender).
  bool get inGroup => !isDispatch && groupSource != null;

  /// An "I received" whose sender the receiver did not know: a manager
  /// matches it on the Transit board.
  bool get isUnsourced => !isDispatch && fromWarehouse.isEmpty;

  /// True when nobody on the branch side can act: the manager matches it.
  bool get awaitsManager => awaitingSide == 'Manager';

  /// The warehouse whose turn it is (the one that would confirm / change).
  /// Empty when a manager is awaited.
  String get awaitingWarehouse => switch (awaitingSide) {
        'From' => fromWarehouse,
        'To' => toWarehouse,
        _ => '',
      };

  /// The other side of [awaitingWarehouse].
  String get proposingWarehouse =>
      awaitingSide == 'From' ? toWarehouse : fromWarehouse;

  double get totalQty => items.fold(0, (sum, l) => sum + l.qty);

  factory StockHandover.fromJson(Map<String, dynamic> json) {
    final fromWh = _toStr(json['from_warehouse']);
    final toWh = _toStr(json['to_warehouse']);
    final fromLabel = _toStr(json['from_label']);
    final toLabel = _toStr(json['to_label']);
    return StockHandover(
      name: _toStr(json['name']),
      status: _toStr(json['status']),
      fromWarehouse: fromWh,
      fromLabel: fromLabel.isEmpty ? fromWh : fromLabel,
      toWarehouse: toWh,
      toLabel: toLabel.isEmpty ? toWh : toLabel,
      kind: _toStr(json['kind']).isEmpty ? 'Handover' : _toStr(json['kind']),
      groupSource: _toOptStr(json['group_source']),
      awaitingSide: _toStr(json['awaiting_side']),
      awaitingLabel: _toStr(json['awaiting_label']),
      declaredByName: _toStr(json['declared_by_name']),
      declaredAt: DateTime.tryParse(_toStr(json['declared_at'])),
      lastProposedByName: _toStr(json['last_proposed_by_name']),
      lastProposedAt: DateTime.tryParse(_toStr(json['last_proposed_at'])),
      changed: _toBool(json['changed']),
      canRespond: _toBool(json['can_respond']),
      canCancel: _toBool(json['can_cancel']),
      stockEntry: _toOptStr(json['stock_entry']),
      rejectReason: _toOptStr(json['reject_reason']),
      items: _maps(json['items']).map(StockHandoverLine.fromJson).toList(),
      cartonPlan: HandoverCartonPlan.tryParse(json['carton_plan']),
    );
  }
}

class StockHandoverLists {
  const StockHandoverLists({
    this.waitingForMe = const [],
    this.waitingForThem = const [],
    this.recent = const [],
    this.transitToMatch = 0,
  });

  final List<StockHandover> waitingForMe;
  final List<StockHandover> waitingForThem;
  final List<StockHandover> recent;

  /// Managers only (0 for everyone else): receipts waiting on the Transit
  /// board for a manager to approve. Drives the "Transit — N to approve"
  /// entry and the tab badge.
  final int transitToMatch;

  bool get isEmpty =>
      waitingForMe.isEmpty && waitingForThem.isEmpty && recent.isEmpty;

  factory StockHandoverLists.fromJson(Map<String, dynamic> json) {
    List<StockHandover> parse(Object? v) =>
        _maps(v).map(StockHandover.fromJson).toList();
    final count = _toDouble(json['transit_to_match']).round();
    return StockHandoverLists(
      waitingForMe: parse(json['waiting_for_me']),
      waitingForThem: parse(json['waiting_for_them']),
      recent: parse(json['recent']),
      transitToMatch: count < 0 ? 0 : count,
    );
  }
}

// ── Transit board (`get_transit_board`) ───────────────────────────────────

/// How sure the recommendation engine is about one suggestion.
enum TransitConfidence {
  high,
  medium,
  low,
  none;

  static TransitConfidence parse(Object? value) =>
      switch (_toStr(value).toLowerCase()) {
        'high' => TransitConfidence.high,
        'medium' => TransitConfidence.medium,
        'low' => TransitConfidence.low,
        _ => TransitConfidence.none,
      };

  /// The wire value `approve_receipt` stores (`""` for none).
  String get wire => this == TransitConfidence.none ? '' : name;
}

/// Why the engine suggested a source: `{"code": ..., ...params}`. The app
/// turns the code into a sentence; unknown codes are kept and shown as
/// nothing rather than breaking the card.
class TransitReason {
  const TransitReason({required this.code, this.params = const {}});

  final String code;
  final Map<String, dynamic> params;

  /// `usual_supplier` share, 0..1.
  double get share => _toDouble(params['share']);

  factory TransitReason.fromJson(Map<String, dynamic> json) {
    final params = Map<String, dynamic>.from(json)..remove('code');
    return TransitReason(code: _toStr(json['code']), params: params);
  }
}

/// One suggested source for one receipt line. [dispatch] null = a direct
/// allocation: nobody declared sending it, the stock comes straight from
/// [sourceWarehouse].
class TransitSuggestion {
  const TransitSuggestion({
    this.dispatch,
    required this.sourceWarehouse,
    required this.sourceLabel,
    this.qty = 0,
    this.confidence = TransitConfidence.none,
    this.reasons = const [],
  });

  final String? dispatch;
  final String sourceWarehouse;
  final String sourceLabel;
  final double qty;
  final TransitConfidence confidence;
  final List<TransitReason> reasons;

  bool get isDirect => dispatch == null;

  factory TransitSuggestion.fromJson(Map<String, dynamic> json) {
    final wh = _toStr(json['source_warehouse']);
    final label = _toStr(json['source_label']);
    return TransitSuggestion(
      dispatch: _toOptStr(json['dispatch']),
      sourceWarehouse: wh,
      sourceLabel: label.isEmpty ? wh : label,
      qty: _toDouble(json['qty']),
      confidence: TransitConfidence.parse(json['confidence']),
      reasons: _maps(json['reasons']).map(TransitReason.fromJson).toList(),
    );
  }
}

class TransitReceiptLine {
  const TransitReceiptLine({
    required this.itemCode,
    required this.itemName,
    this.stockUom = '',
    this.qty = 0,
    this.suggestions = const [],
    this.unresolvedQty = 0,
  });

  final String itemCode;
  final String itemName;
  final String stockUom;

  /// What the receiver declared.
  final double qty;
  final List<TransitSuggestion> suggestions;

  /// What the engine could not place (every send of the item is exhausted).
  final double unresolvedQty;

  factory TransitReceiptLine.fromJson(Map<String, dynamic> json) {
    final code = _toStr(json['item_code']);
    final name = _toStr(json['item_name']);
    return TransitReceiptLine(
      itemCode: code,
      itemName: name.isEmpty ? code : name,
      stockUom: _toStr(json['stock_uom']),
      qty: _toDouble(json['qty']),
      suggestions:
          _maps(json['suggestions']).map(TransitSuggestion.fromJson).toList(),
      unresolvedQty: _toDouble(json['unresolved_qty']),
    );
  }
}

/// A pending "I received" waiting for a manager.
class TransitReceipt {
  const TransitReceipt({
    required this.name,
    required this.targetWarehouse,
    required this.targetLabel,
    this.namedSource,
    this.namedSourceLabel,
    this.declaredBy = '',
    this.declaredByName = '',
    this.declaredAt,
    this.canApprove = false,
    this.lines = const [],
  });

  final String name;
  final String targetWarehouse;
  final String targetLabel;

  /// The sender the receiver named, or null ("don't know who sent it").
  final String? namedSource;
  final String? namedSourceLabel;
  final String declaredBy;
  final String declaredByName;
  final DateTime? declaredAt;

  /// False for the manager who declared it: another manager must approve.
  final bool canApprove;
  final List<TransitReceiptLine> lines;

  double get totalQty => lines.fold(0.0, (s, l) => s + l.qty);

  factory TransitReceipt.fromJson(Map<String, dynamic> json) {
    final wh = _toStr(json['target_warehouse']);
    final label = _toStr(json['target_label']);
    final named = _toOptStr(json['named_source']);
    final namedLabel = _toOptStr(json['named_source_label']);
    return TransitReceipt(
      name: _toStr(json['name']),
      targetWarehouse: wh,
      targetLabel: label.isEmpty ? wh : label,
      namedSource: named,
      namedSourceLabel: named == null ? null : (namedLabel ?? named),
      declaredBy: _toStr(json['declared_by']),
      declaredByName: _toStr(json['declared_by_name']),
      declaredAt: DateTime.tryParse(_toStr(json['declared_at'])),
      canApprove: _toBool(json['can_approve']),
      lines: _maps(json['lines']).map(TransitReceiptLine.fromJson).toList(),
    );
  }
}

class TransitSendLine {
  const TransitSendLine({
    required this.itemCode,
    required this.itemName,
    this.stockUom = '',
    this.qty = 0,
    this.matchedQty = 0,
    this.writtenOffQty = 0,
    this.returnedQty = 0,
    this.remaining = 0,
  });

  final String itemCode;
  final String itemName;
  final String stockUom;
  final double qty;
  final double matchedQty;
  final double writtenOffQty;
  final double returnedQty;

  /// Still in transit: `qty - matched - written off - returned`.
  final double remaining;

  factory TransitSendLine.fromJson(Map<String, dynamic> json) {
    final code = _toStr(json['item_code']);
    final name = _toStr(json['item_name']);
    return TransitSendLine(
      itemCode: code,
      itemName: name.isEmpty ? code : name,
      stockUom: _toStr(json['stock_uom']),
      qty: _toDouble(json['qty']),
      matchedQty: _toDouble(json['matched_qty']),
      writtenOffQty: _toDouble(json['written_off_qty']),
      returnedQty: _toDouble(json['returned_qty']),
      remaining: _toDouble(json['remaining']),
    );
  }
}

/// An open "I sent out": stock sitting in the transit warehouse.
class TransitSend {
  const TransitSend({
    required this.name,
    required this.sourceWarehouse,
    required this.sourceLabel,
    this.declaredBy = '',
    this.declaredByName = '',
    this.declaredAt,
    this.ageHours = 0,
    this.transitEntry,
    this.overdue = false,
    this.canAct = false,
    this.lines = const [],
  });

  final String name;
  final String sourceWarehouse;
  final String sourceLabel;
  final String declaredBy;
  final String declaredByName;
  final DateTime? declaredAt;
  final double ageHours;
  final String? transitEntry;

  /// Open for more than 24 hours.
  final bool overdue;

  /// Manager and not its declarer: may return / write off.
  final bool canAct;
  final List<TransitSendLine> lines;

  /// Lines with something still in transit.
  List<TransitSendLine> get openLines =>
      lines.where((l) => l.remaining > 1e-9).toList();

  double get remainingUnits => lines.fold(0.0, (s, l) => s + l.remaining);

  /// What is left of [itemCode] on this send (0 when it never had it).
  double remainingFor(String itemCode) => lines
      .where((l) => l.itemCode == itemCode)
      .fold(0.0, (s, l) => s + l.remaining);

  factory TransitSend.fromJson(Map<String, dynamic> json) {
    final wh = _toStr(json['source_warehouse']);
    final label = _toStr(json['source_label']);
    return TransitSend(
      name: _toStr(json['name']),
      sourceWarehouse: wh,
      sourceLabel: label.isEmpty ? wh : label,
      declaredBy: _toStr(json['declared_by']),
      declaredByName: _toStr(json['declared_by_name']),
      declaredAt: DateTime.tryParse(_toStr(json['declared_at'])),
      ageHours: _toDouble(json['age_hours']),
      transitEntry: _toOptStr(json['transit_entry']),
      overdue: _toBool(json['overdue']),
      canAct: _toBool(json['can_act']),
      lines: _maps(json['lines']).map(TransitSendLine.fromJson).toList(),
    );
  }
}

class TransitSummary {
  const TransitSummary({
    this.toApprove = 0,
    this.unitsInTransit = 0,
    this.overdueSends = 0,
  });

  final int toApprove;
  final double unitsInTransit;
  final int overdueSends;

  factory TransitSummary.fromJson(Map<String, dynamic> json) => TransitSummary(
        toApprove: _toDouble(json['to_approve']).round(),
        unitsInTransit: _toDouble(json['units_in_transit']),
        overdueSends: _toDouble(json['overdue_sends']).round(),
      );
}

/// The manager's Transit board: open sends, receipts to approve with the
/// engine's suggestions, and every known side for the "pick the sender"
/// picker. [version] goes back to `approve_receipt` as its drift token.
class TransitBoard {
  const TransitBoard({
    this.version = '',
    this.summary = const TransitSummary(),
    this.sends = const [],
    this.receipts = const [],
    this.senders = const [],
    this.canDirect = false,
  });

  final String version;
  final TransitSummary summary;
  final List<TransitSend> sends;
  final List<TransitReceipt> receipts;
  final List<HandoverSide> senders;

  /// `can_direct`: the server lets this user allocate a receipt line with no
  /// dispatch ("sender didn't declare") and correct `received` ABOVE the
  /// declared qty. Without it both are refused; corrections down still work.
  final bool canDirect;

  bool get isEmpty => sends.isEmpty && receipts.isEmpty;

  TransitSend? sendNamed(String name) {
    for (final s in sends) {
      if (s.name == name) return s;
    }
    return null;
  }

  String senderLabel(String warehouse) {
    for (final s in senders) {
      if (s.warehouse == warehouse) return s.label;
    }
    for (final s in sends) {
      if (s.sourceWarehouse == warehouse) return s.sourceLabel;
    }
    return warehouse;
  }

  factory TransitBoard.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'];
    return TransitBoard(
      version: _toStr(json['version']),
      summary: summary is Map
          ? TransitSummary.fromJson(Map<String, dynamic>.from(summary))
          : const TransitSummary(),
      sends: _maps(json['sends'])
          .map(TransitSend.fromJson)
          .where((s) => s.name.isNotEmpty)
          .toList(),
      receipts: _maps(json['receipts'])
          .map(TransitReceipt.fromJson)
          .where((r) => r.name.isNotEmpty)
          .toList(),
      senders: _maps(json['senders'])
          .map(HandoverSide.fromJson)
          .where((s) => s.warehouse.isNotEmpty)
          .toList(),
      canDirect: _toBool(json['can_direct']),
    );
  }
}

/// What `approve_receipt` answered: `{ok, stock_entry, receipt, closed_sends}`.
class TransitApproveOutcome {
  const TransitApproveOutcome({
    this.stockEntry,
    this.receipt,
    this.closedSends = const [],
  });

  final String? stockEntry;
  final String? receipt;
  final List<String> closedSends;

  factory TransitApproveOutcome.fromJson(Map<String, dynamic> json) {
    final receipt = json['receipt'];
    return TransitApproveOutcome(
      stockEntry: _toOptStr(json['stock_entry']),
      // Lenient: a name, or the receipt row itself.
      receipt: receipt is Map ? _toOptStr(receipt['name']) : _toOptStr(receipt),
      closedSends: _strings(json['closed_sends']),
    );
  }
}

/// What `write_off_transit` / `return_to_sender` / `reject_receipt`
/// answered. Only the entry is read; anything else is ignored.
class TransitActionOutcome {
  const TransitActionOutcome({this.stockEntry});

  final String? stockEntry;

  factory TransitActionOutcome.fromJson(Map<String, dynamic> json) =>
      TransitActionOutcome(stockEntry: _toOptStr(json['stock_entry']));
}

/// What `transfer.submit_transfer` answered.
///
/// Two shapes are valid: the old `{"ok": true, "stock_entry": "MAT-STE-…"}`
/// (posted now), and, for a transfer touching a branch,
/// `{"ok": true, "stock_entry": null, "handover": "HND-…", "pending": true}`
/// — nothing has moved yet; the other side must confirm. A manager's
/// one-step post of a branch pair answers
/// `{"ok": true, "stock_entry": "MAT-STE-…", "direct": true}` (posted now).
class TransferSubmitOutcome {
  const TransferSubmitOutcome({
    this.stockEntry,
    this.handover,
    this.pending = false,
    this.direct = false,
  });

  final String? stockEntry;
  final String? handover;
  final bool pending;

  /// A branch pair posted in one step, with no handover.
  final bool direct;

  factory TransferSubmitOutcome.fromJson(Map<String, dynamic> json) {
    final handover = _toOptStr(json['handover']);
    return TransferSubmitOutcome(
      stockEntry: _toOptStr(json['stock_entry']),
      handover: handover,
      // A handover name alone also means "not posted yet", whatever the flag.
      pending: _toBool(json['pending']) || handover != null,
      direct: _toBool(json['direct']),
    );
  }
}
