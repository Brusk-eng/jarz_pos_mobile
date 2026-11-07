// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'branch_replenishment.freezed.dart';
part 'branch_replenishment.g.dart';

/// One item the factory may owe a branch.
///
/// Every figure here is the branch's OWN: the same jar sells four times faster
/// in Nasr City than in Dokki, so a single company-wide rate would send the
/// wrong van load to both. [sendNow] is already capped by what the factory
/// holds and split proportionally when it cannot cover everyone, which is why
/// the screen pre-fills that and not [suggestedQty].
@freezed
class ReplenishmentItem with _$ReplenishmentItem {
  const factory ReplenishmentItem({
    @JsonKey(name: 'item_code') @Default('') String itemCode,
    @JsonKey(name: 'item_name') @Default('') String itemName,
    @JsonKey(name: 'stock_uom') @Default('') String stockUom,
    @JsonKey(name: 'on_hand') @Default(0.0) double onHand,

    /// A negative bin is a counting error, not demand — the branch sold jars
    /// that were never booked in. Surfaced so the row asks for a count instead
    /// of quietly inflating the suggestion; the server has already floored the
    /// suggestion to zero for it.
    @JsonKey(name: 'stock_is_negative', fromJson: _flag)
    @Default(false)
    bool stockIsNegative,
    @JsonKey(name: 'sells_per_day') @Default(0.0) double sellsPerDay,

    /// Null when this branch has never sold the item. Distinct from zero,
    /// which means "sells, and has run out" — the row must never round the
    /// two together.
    @JsonKey(name: 'days_of_cover') double? daysOfCover,
    @JsonKey(name: 'target_days') @Default(0.0) double targetDays,
    @JsonKey(name: 'suggested_qty') @Default(0.0) double suggestedQty,
    @JsonKey(name: 'available_at_source') @Default(0.0) double availableAtSource,
    @JsonKey(name: 'send_now') @Default(0.0) double sendNow,

    /// How much of [suggestedQty] the factory simply does not have. This is
    /// the number that tells the owner to produce more, so it is shown rather
    /// than folded silently into the capped [sendNow].
    @JsonKey(name: 'short_by') @Default(0.0) double shortBy,

    /// Older servers omit everything below; the defaults keep them working.
    @JsonKey(name: 'item_group') @Default('') String itemGroup,

    /// "small" | "medium" | "large", or empty when the server cannot tell.
    @JsonKey(name: 'jar_size') @Default('') String jarSize,

    /// Jars this branch can give away and still keep its own cover.
    @JsonKey(name: 'spare_qty', fromJson: _toInt) @Default(0) int spareQty,

    /// Where the factory cannot cover [shortBy], which other branch can.
    @JsonKey(name: 'move_in')
    @Default(<ReplenishmentMoveIn>[])
    List<ReplenishmentMoveIn> moveIn,
  }) = _ReplenishmentItem;

  factory ReplenishmentItem.fromJson(Map<String, dynamic> json) =>
      _$ReplenishmentItemFromJson(json);

  const ReplenishmentItem._();

  /// Whether the branch has any sales history for this item at all.
  bool get hasSalesHistory => daysOfCover != null;

  /// Whether the factory cannot fully cover this line.
  bool get isShort => shortBy > 0;

  /// What the row should be titled. Item codes are the fallback because a
  /// missing `item_name` must not render an anonymous row.
  String get displayName => itemName.trim().isEmpty ? itemCode : itemName;
}

/// A branch that could hand [qty] of one row to the branch being viewed.
@freezed
class ReplenishmentMoveIn with _$ReplenishmentMoveIn {
  const factory ReplenishmentMoveIn({
    @JsonKey(name: 'from_warehouse') @Default('') String fromWarehouse,
    @JsonKey(name: 'from_branch') @Default('') String fromBranch,
    @JsonKey(fromJson: _toInt) @Default(0) int qty,
  }) = _ReplenishmentMoveIn;

  factory ReplenishmentMoveIn.fromJson(Map<String, dynamic> json) =>
      _$ReplenishmentMoveInFromJson(json);

  const ReplenishmentMoveIn._();

  String get displayFrom => fromBranch.trim().isEmpty ? fromWarehouse : fromBranch;
}

/// One suggested branch-to-branch move for a whole plan.
@freezed
class ReplenishmentBranchMove with _$ReplenishmentBranchMove {
  const factory ReplenishmentBranchMove({
    @JsonKey(name: 'item_code') @Default('') String itemCode,
    @JsonKey(name: 'item_name') @Default('') String itemName,
    @JsonKey(name: 'jar_size') @Default('') String jarSize,
    @JsonKey(name: 'from_warehouse') @Default('') String fromWarehouse,
    @JsonKey(name: 'from_branch') @Default('') String fromBranch,
    @JsonKey(name: 'to_warehouse') @Default('') String toWarehouse,
    @JsonKey(name: 'to_branch') @Default('') String toBranch,
    @JsonKey(fromJson: _toInt) @Default(0) int qty,
  }) = _ReplenishmentBranchMove;

  factory ReplenishmentBranchMove.fromJson(Map<String, dynamic> json) =>
      _$ReplenishmentBranchMoveFromJson(json);

  const ReplenishmentBranchMove._();

  String get displayName => itemName.trim().isEmpty ? itemCode : itemName;
  String get displayFrom => fromBranch.trim().isEmpty ? fromWarehouse : fromBranch;
}

/// Counts for one branch, or for the whole run.
///
/// `branches` and `totalShortBy` are only populated on the top-level summary;
/// a branch's own block leaves them at zero.
@freezed
class ReplenishmentSummary with _$ReplenishmentSummary {
  const factory ReplenishmentSummary({
    @JsonKey(name: 'items_below_cover') @Default(0) int itemsBelowCover,
    @JsonKey(name: 'total_suggested') @Default(0.0) double totalSuggested,
    @JsonKey(name: 'total_send_now') @Default(0.0) double totalSendNow,
    @JsonKey(name: 'negative_bins') @Default(0) int negativeBins,
    @Default(0) int branches,
    @JsonKey(name: 'total_short_by') @Default(0.0) double totalShortBy,
  }) = _ReplenishmentSummary;

  factory ReplenishmentSummary.fromJson(Map<String, dynamic> json) =>
      _$ReplenishmentSummaryFromJson(json);
}

/// The factory store the van loads from, and what it currently holds.
@freezed
class ReplenishmentSource with _$ReplenishmentSource {
  const factory ReplenishmentSource({
    @Default('') String warehouse,
    @Default(<String, double>{}) Map<String, double> available,
  }) = _ReplenishmentSource;

  factory ReplenishmentSource.fromJson(Map<String, dynamic> json) =>
      _$ReplenishmentSourceFromJson(json);
}

/// One selling branch and everything it is short of.
@freezed
class ReplenishmentBranch with _$ReplenishmentBranch {
  const factory ReplenishmentBranch({
    @Default('') String warehouse,
    @Default('') String branch,
    @Default(<ReplenishmentItem>[]) List<ReplenishmentItem> items,
    @Default(ReplenishmentSummary()) ReplenishmentSummary summary,
  }) = _ReplenishmentBranch;

  factory ReplenishmentBranch.fromJson(Map<String, dynamic> json) =>
      _$ReplenishmentBranchFromJson(json);

  const ReplenishmentBranch._();

  /// The branch label, falling back to the warehouse so the selector can never
  /// show a blank entry.
  String get displayName => branch.trim().isEmpty ? warehouse : branch;
}

/// The whole answer to "what should the factory send today".
@freezed
class ReplenishmentPlan with _$ReplenishmentPlan {
  const factory ReplenishmentPlan({
    @JsonKey(name: 'generated_on') @Default('') String generatedOn,
    @Default('') String company,
    @JsonKey(name: 'cover_days') @Default(0) int coverDays,
    @JsonKey(name: 'sales_days') @Default(0) int salesDays,

    /// Non-null with a reason whenever the payload is empty. The screen shows
    /// it verbatim, because "no rows" without a why is the state that made
    /// people stop trusting this kind of screen.
    String? notice,
    @Default(ReplenishmentSource()) ReplenishmentSource source,
    @Default(<ReplenishmentBranch>[]) List<ReplenishmentBranch> branches,
    @Default(ReplenishmentSummary()) ReplenishmentSummary summary,

    /// Suggested moves between branches; empty on older servers.
    @JsonKey(name: 'branch_moves')
    @Default(<ReplenishmentBranchMove>[])
    List<ReplenishmentBranchMove> branchMoves,
  }) = _ReplenishmentPlan;

  factory ReplenishmentPlan.fromJson(Map<String, dynamic> json) =>
      _$ReplenishmentPlanFromJson(json);

  const ReplenishmentPlan._();

  /// Nothing to render is not the same as nothing to send: a run with branches
  /// but zero suggestions still has rows worth reading.
  bool get hasBranches => branches.isNotEmpty;

  /// Moves other branches could make INTO [warehouse].
  List<ReplenishmentBranchMove> movesInto(String warehouse) => [
    for (final move in branchMoves)
      if (move.toWarehouse == warehouse && move.qty > 0) move,
  ];

  ReplenishmentBranch? branchFor(String? warehouse) {
    if (warehouse == null) return null;
    for (final branch in branches) {
      if (branch.warehouse == warehouse) return branch;
    }
    return null;
  }
}

int _toInt(dynamic value) {
  if (value is num) return value.round();
  if (value is String) return double.tryParse(value.trim())?.round() ?? 0;
  return 0;
}

/// Frappe hands booleans back as `true`, but a checkbox read straight off a
/// DocType arrives as 0/1 — accept both rather than crash the whole payload on
/// one field.
bool _flag(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final text = value.trim().toLowerCase();
    return text == '1' || text == 'true' || text == 'yes';
  }
  return false;
}
