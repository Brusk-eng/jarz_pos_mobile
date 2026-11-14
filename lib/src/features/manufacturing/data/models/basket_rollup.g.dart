// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'basket_rollup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BasketRollupImpl _$$BasketRollupImplFromJson(Map<String, dynamic> json) =>
    _$BasketRollupImpl(
      ok: json['ok'] as bool? ?? true,
      company: json['company'] as String? ?? '',
      lineCount: (json['line_count'] as num?)?.toInt() ?? 0,
      components:
          (json['components'] as List<dynamic>?)
              ?.map((e) => RollupComponent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <RollupComponent>[],
      shortages:
          (json['shortages'] as List<dynamic>?)
              ?.map((e) => RollupComponent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <RollupComponent>[],
      maxFeasibleScale: (json['max_feasible_scale'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$BasketRollupImplToJson(_$BasketRollupImpl instance) =>
    <String, dynamic>{
      'ok': instance.ok,
      'company': instance.company,
      'line_count': instance.lineCount,
      'components': instance.components,
      'shortages': instance.shortages,
      'max_feasible_scale': instance.maxFeasibleScale,
    };

_$RollupComponentImpl _$$RollupComponentImplFromJson(
  Map<String, dynamic> json,
) => _$RollupComponentImpl(
  itemCode: json['item_code'] as String? ?? '',
  itemName: json['item_name'] as String? ?? '',
  uom: json['uom'] as String? ?? '',
  sourceWarehouse: json['source_warehouse'] as String?,
  requiredQty: (json['required_qty'] as num?)?.toDouble() ?? 0.0,
  availableQty: (json['available_qty'] as num?)?.toDouble() ?? 0.0,
  missingQty: (json['missing_qty'] as num?)?.toDouble() ?? 0.0,
  reason: json['reason'] as String?,
  contributingLines:
      (json['contributing_lines'] as List<dynamic>?)
          ?.map((e) => ContributingLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ContributingLine>[],
  availableElsewhere: (json['available_elsewhere'] as num?)?.toDouble(),
  alternatives: (json['alternatives'] as List<dynamic>?)
      ?.map((e) => StockAlternative.fromJson(e as Map<String, dynamic>))
      .toList(),
  madeFrom:
      (json['made_from'] as List<dynamic>?)
          ?.map((e) => MadeFromLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MadeFromLine>[],
);

Map<String, dynamic> _$$RollupComponentImplToJson(
  _$RollupComponentImpl instance,
) => <String, dynamic>{
  'item_code': instance.itemCode,
  'item_name': instance.itemName,
  'uom': instance.uom,
  'source_warehouse': instance.sourceWarehouse,
  'required_qty': instance.requiredQty,
  'available_qty': instance.availableQty,
  'missing_qty': instance.missingQty,
  'reason': instance.reason,
  'contributing_lines': instance.contributingLines,
  'available_elsewhere': instance.availableElsewhere,
  'alternatives': instance.alternatives,
  'made_from': instance.madeFrom,
};

_$ContributingLineImpl _$$ContributingLineImplFromJson(
  Map<String, dynamic> json,
) => _$ContributingLineImpl(
  lineIndex: (json['line_index'] as num?)?.toInt() ?? 0,
  itemCode: json['item_code'] as String? ?? '',
  requiredQty: (json['required_qty'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$ContributingLineImplToJson(
  _$ContributingLineImpl instance,
) => <String, dynamic>{
  'line_index': instance.lineIndex,
  'item_code': instance.itemCode,
  'required_qty': instance.requiredQty,
};

_$MadeFromLineImpl _$$MadeFromLineImplFromJson(Map<String, dynamic> json) =>
    _$MadeFromLineImpl(
      itemCode: json['item_code'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      uom: json['uom'] as String? ?? '',
      requiredQty: (json['required_qty'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$MadeFromLineImplToJson(_$MadeFromLineImpl instance) =>
    <String, dynamic>{
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'uom': instance.uom,
      'required_qty': instance.requiredQty,
    };
