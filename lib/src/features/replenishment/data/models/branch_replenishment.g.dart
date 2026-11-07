// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_replenishment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReplenishmentItemImpl _$$ReplenishmentItemImplFromJson(
  Map<String, dynamic> json,
) => _$ReplenishmentItemImpl(
  itemCode: json['item_code'] as String? ?? '',
  itemName: json['item_name'] as String? ?? '',
  stockUom: json['stock_uom'] as String? ?? '',
  onHand: (json['on_hand'] as num?)?.toDouble() ?? 0.0,
  stockIsNegative: json['stock_is_negative'] == null
      ? false
      : _flag(json['stock_is_negative']),
  sellsPerDay: (json['sells_per_day'] as num?)?.toDouble() ?? 0.0,
  daysOfCover: (json['days_of_cover'] as num?)?.toDouble(),
  targetDays: (json['target_days'] as num?)?.toDouble() ?? 0.0,
  suggestedQty: (json['suggested_qty'] as num?)?.toDouble() ?? 0.0,
  availableAtSource: (json['available_at_source'] as num?)?.toDouble() ?? 0.0,
  sendNow: (json['send_now'] as num?)?.toDouble() ?? 0.0,
  shortBy: (json['short_by'] as num?)?.toDouble() ?? 0.0,
  itemGroup: json['item_group'] as String? ?? '',
  jarSize: json['jar_size'] as String? ?? '',
  spareQty: json['spare_qty'] == null ? 0 : _toInt(json['spare_qty']),
  moveIn:
      (json['move_in'] as List<dynamic>?)
          ?.map((e) => ReplenishmentMoveIn.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ReplenishmentMoveIn>[],
);

Map<String, dynamic> _$$ReplenishmentItemImplToJson(
  _$ReplenishmentItemImpl instance,
) => <String, dynamic>{
  'item_code': instance.itemCode,
  'item_name': instance.itemName,
  'stock_uom': instance.stockUom,
  'on_hand': instance.onHand,
  'stock_is_negative': instance.stockIsNegative,
  'sells_per_day': instance.sellsPerDay,
  'days_of_cover': instance.daysOfCover,
  'target_days': instance.targetDays,
  'suggested_qty': instance.suggestedQty,
  'available_at_source': instance.availableAtSource,
  'send_now': instance.sendNow,
  'short_by': instance.shortBy,
  'item_group': instance.itemGroup,
  'jar_size': instance.jarSize,
  'spare_qty': instance.spareQty,
  'move_in': instance.moveIn,
};

_$ReplenishmentMoveInImpl _$$ReplenishmentMoveInImplFromJson(
  Map<String, dynamic> json,
) => _$ReplenishmentMoveInImpl(
  fromWarehouse: json['from_warehouse'] as String? ?? '',
  fromBranch: json['from_branch'] as String? ?? '',
  qty: json['qty'] == null ? 0 : _toInt(json['qty']),
);

Map<String, dynamic> _$$ReplenishmentMoveInImplToJson(
  _$ReplenishmentMoveInImpl instance,
) => <String, dynamic>{
  'from_warehouse': instance.fromWarehouse,
  'from_branch': instance.fromBranch,
  'qty': instance.qty,
};

_$ReplenishmentBranchMoveImpl _$$ReplenishmentBranchMoveImplFromJson(
  Map<String, dynamic> json,
) => _$ReplenishmentBranchMoveImpl(
  itemCode: json['item_code'] as String? ?? '',
  itemName: json['item_name'] as String? ?? '',
  jarSize: json['jar_size'] as String? ?? '',
  fromWarehouse: json['from_warehouse'] as String? ?? '',
  fromBranch: json['from_branch'] as String? ?? '',
  toWarehouse: json['to_warehouse'] as String? ?? '',
  toBranch: json['to_branch'] as String? ?? '',
  qty: json['qty'] == null ? 0 : _toInt(json['qty']),
);

Map<String, dynamic> _$$ReplenishmentBranchMoveImplToJson(
  _$ReplenishmentBranchMoveImpl instance,
) => <String, dynamic>{
  'item_code': instance.itemCode,
  'item_name': instance.itemName,
  'jar_size': instance.jarSize,
  'from_warehouse': instance.fromWarehouse,
  'from_branch': instance.fromBranch,
  'to_warehouse': instance.toWarehouse,
  'to_branch': instance.toBranch,
  'qty': instance.qty,
};

_$ReplenishmentSummaryImpl _$$ReplenishmentSummaryImplFromJson(
  Map<String, dynamic> json,
) => _$ReplenishmentSummaryImpl(
  itemsBelowCover: (json['items_below_cover'] as num?)?.toInt() ?? 0,
  totalSuggested: (json['total_suggested'] as num?)?.toDouble() ?? 0.0,
  totalSendNow: (json['total_send_now'] as num?)?.toDouble() ?? 0.0,
  negativeBins: (json['negative_bins'] as num?)?.toInt() ?? 0,
  branches: (json['branches'] as num?)?.toInt() ?? 0,
  totalShortBy: (json['total_short_by'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$ReplenishmentSummaryImplToJson(
  _$ReplenishmentSummaryImpl instance,
) => <String, dynamic>{
  'items_below_cover': instance.itemsBelowCover,
  'total_suggested': instance.totalSuggested,
  'total_send_now': instance.totalSendNow,
  'negative_bins': instance.negativeBins,
  'branches': instance.branches,
  'total_short_by': instance.totalShortBy,
};

_$ReplenishmentSourceImpl _$$ReplenishmentSourceImplFromJson(
  Map<String, dynamic> json,
) => _$ReplenishmentSourceImpl(
  warehouse: json['warehouse'] as String? ?? '',
  available:
      (json['available'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ) ??
      const <String, double>{},
);

Map<String, dynamic> _$$ReplenishmentSourceImplToJson(
  _$ReplenishmentSourceImpl instance,
) => <String, dynamic>{
  'warehouse': instance.warehouse,
  'available': instance.available,
};

_$ReplenishmentBranchImpl _$$ReplenishmentBranchImplFromJson(
  Map<String, dynamic> json,
) => _$ReplenishmentBranchImpl(
  warehouse: json['warehouse'] as String? ?? '',
  branch: json['branch'] as String? ?? '',
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => ReplenishmentItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ReplenishmentItem>[],
  summary: json['summary'] == null
      ? const ReplenishmentSummary()
      : ReplenishmentSummary.fromJson(json['summary'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$ReplenishmentBranchImplToJson(
  _$ReplenishmentBranchImpl instance,
) => <String, dynamic>{
  'warehouse': instance.warehouse,
  'branch': instance.branch,
  'items': instance.items,
  'summary': instance.summary,
};

_$ReplenishmentPlanImpl _$$ReplenishmentPlanImplFromJson(
  Map<String, dynamic> json,
) => _$ReplenishmentPlanImpl(
  generatedOn: json['generated_on'] as String? ?? '',
  company: json['company'] as String? ?? '',
  coverDays: (json['cover_days'] as num?)?.toInt() ?? 0,
  salesDays: (json['sales_days'] as num?)?.toInt() ?? 0,
  notice: json['notice'] as String?,
  source: json['source'] == null
      ? const ReplenishmentSource()
      : ReplenishmentSource.fromJson(json['source'] as Map<String, dynamic>),
  branches:
      (json['branches'] as List<dynamic>?)
          ?.map((e) => ReplenishmentBranch.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ReplenishmentBranch>[],
  summary: json['summary'] == null
      ? const ReplenishmentSummary()
      : ReplenishmentSummary.fromJson(json['summary'] as Map<String, dynamic>),
  branchMoves:
      (json['branch_moves'] as List<dynamic>?)
          ?.map(
            (e) => ReplenishmentBranchMove.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ReplenishmentBranchMove>[],
);

Map<String, dynamic> _$$ReplenishmentPlanImplToJson(
  _$ReplenishmentPlanImpl instance,
) => <String, dynamic>{
  'generated_on': instance.generatedOn,
  'company': instance.company,
  'cover_days': instance.coverDays,
  'sales_days': instance.salesDays,
  'notice': instance.notice,
  'source': instance.source,
  'branches': instance.branches,
  'summary': instance.summary,
  'branch_moves': instance.branchMoves,
};
