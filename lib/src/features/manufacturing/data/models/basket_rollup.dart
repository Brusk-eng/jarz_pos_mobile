// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import 'stock_alternative.dart';

part 'basket_rollup.freezed.dart';
part 'basket_rollup.g.dart';

/// Payload of `get_basket_material_rollup`.
///
/// The consolidated pick list for a whole batch. This is what the old per-line
/// check could never answer: two lines drawing on the same pile of flour each
/// passed on their own while the pair busted the warehouse.
@freezed
class BasketRollup with _$BasketRollup {
  const factory BasketRollup({
    @Default(true) bool ok,
    @Default('') String company,
    @JsonKey(name: 'line_count') @Default(0) int lineCount,
    @Default(<RollupComponent>[]) List<RollupComponent> components,
    @Default(<RollupComponent>[]) List<RollupComponent> shortages,

    /// Largest uniform fraction of the basket the warehouse can cover.
    /// 1.0 means it fits as-is; 0.6 means every line must shrink to 60%.
    /// Null when nothing constrains it.
    @JsonKey(name: 'max_feasible_scale') double? maxFeasibleScale,
  }) = _BasketRollup;

  factory BasketRollup.fromJson(Map<String, dynamic> json) =>
      _$BasketRollupFromJson(json);

  const BasketRollup._();

  bool get hasShortages => shortages.isNotEmpty;
}

@freezed
class RollupComponent with _$RollupComponent {
  const factory RollupComponent({
    @JsonKey(name: 'item_code') @Default('') String itemCode,
    @JsonKey(name: 'item_name') @Default('') String itemName,
    @Default('') String uom,
    @JsonKey(name: 'source_warehouse') String? sourceWarehouse,
    @JsonKey(name: 'required_qty') @Default(0.0) double requiredQty,
    @JsonKey(name: 'available_qty') @Default(0.0) double availableQty,
    @JsonKey(name: 'missing_qty') @Default(0.0) double missingQty,
    String? reason,
    @JsonKey(name: 'contributing_lines')
    @Default(<ContributingLine>[])
    List<ContributingLine> contributingLines,

    /// Where else this material is sitting, when the backend looked.
    ///
    /// Null means nobody looked — deliberately distinct from `0.0` with an
    /// empty [alternatives] list, which means the lookup ran and there is none
    /// of it anywhere in the company.
    @JsonKey(name: 'available_elsewhere') double? availableElsewhere,
    List<StockAlternative>? alternatives,

    /// What goes into a sub-assembly made fresh for this run (Cheesecake Mix),
    /// for the whole basket. Kept under it, never merged with the same
    /// material a jar takes directly. Empty for a raw material or a stored
    /// sub-assembly.
    @JsonKey(name: 'made_from')
    @Default(<MadeFromLine>[])
    List<MadeFromLine> madeFrom,
  }) = _RollupComponent;

  factory RollupComponent.fromJson(Map<String, dynamic> json) =>
      _$RollupComponentFromJson(json);

  const RollupComponent._();

  bool get isShort => missingQty > 0 || reason == 'missing_source_warehouse';
  bool get isMissingWarehouse => reason == 'missing_source_warehouse';

  /// True when no single line is short on its own — the shortage only exists
  /// because several lines share this material.
  bool get isSharedAcrossLines => contributingLines.length > 1;
}

/// Which basket line asked for how much of a shared material.
@freezed
class ContributingLine with _$ContributingLine {
  const factory ContributingLine({
    @JsonKey(name: 'line_index') @Default(0) int lineIndex,
    @JsonKey(name: 'item_code') @Default('') String itemCode,
    @JsonKey(name: 'required_qty') @Default(0.0) double requiredQty,
  }) = _ContributingLine;

  factory ContributingLine.fromJson(Map<String, dynamic> json) =>
      _$ContributingLineFromJson(json);
}

/// One ingredient of a fresh sub-assembly, for the basket's whole need of it.
@freezed
class MadeFromLine with _$MadeFromLine {
  const factory MadeFromLine({
    @JsonKey(name: 'item_code') @Default('') String itemCode,
    @JsonKey(name: 'item_name') @Default('') String itemName,
    @Default('') String uom,
    @JsonKey(name: 'required_qty') @Default(0.0) double requiredQty,
  }) = _MadeFromLine;

  factory MadeFromLine.fromJson(Map<String, dynamic> json) =>
      _$MadeFromLineFromJson(json);
}
