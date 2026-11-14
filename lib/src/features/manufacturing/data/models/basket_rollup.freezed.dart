// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'basket_rollup.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BasketRollup _$BasketRollupFromJson(Map<String, dynamic> json) {
  return _BasketRollup.fromJson(json);
}

/// @nodoc
mixin _$BasketRollup {
  bool get ok => throw _privateConstructorUsedError;
  String get company => throw _privateConstructorUsedError;
  @JsonKey(name: 'line_count')
  int get lineCount => throw _privateConstructorUsedError;
  List<RollupComponent> get components => throw _privateConstructorUsedError;
  List<RollupComponent> get shortages => throw _privateConstructorUsedError;

  /// Largest uniform fraction of the basket the warehouse can cover.
  /// 1.0 means it fits as-is; 0.6 means every line must shrink to 60%.
  /// Null when nothing constrains it.
  @JsonKey(name: 'max_feasible_scale')
  double? get maxFeasibleScale => throw _privateConstructorUsedError;

  /// Phantom sub-assemblies (Cheesecake Mix) made in their own bowl, each
  /// with its own ingredients. ERPNext merges those ingredients into
  /// [components]; this keeps them apart for the kitchen.
  List<RollupSubassembly> get subassemblies =>
      throw _privateConstructorUsedError;

  /// Serializes this BasketRollup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BasketRollup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BasketRollupCopyWith<BasketRollup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BasketRollupCopyWith<$Res> {
  factory $BasketRollupCopyWith(
    BasketRollup value,
    $Res Function(BasketRollup) then,
  ) = _$BasketRollupCopyWithImpl<$Res, BasketRollup>;
  @useResult
  $Res call({
    bool ok,
    String company,
    @JsonKey(name: 'line_count') int lineCount,
    List<RollupComponent> components,
    List<RollupComponent> shortages,
    @JsonKey(name: 'max_feasible_scale') double? maxFeasibleScale,
    List<RollupSubassembly> subassemblies,
  });
}

/// @nodoc
class _$BasketRollupCopyWithImpl<$Res, $Val extends BasketRollup>
    implements $BasketRollupCopyWith<$Res> {
  _$BasketRollupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BasketRollup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ok = null,
    Object? company = null,
    Object? lineCount = null,
    Object? components = null,
    Object? shortages = null,
    Object? maxFeasibleScale = freezed,
    Object? subassemblies = null,
  }) {
    return _then(
      _value.copyWith(
            ok: null == ok
                ? _value.ok
                : ok // ignore: cast_nullable_to_non_nullable
                      as bool,
            company: null == company
                ? _value.company
                : company // ignore: cast_nullable_to_non_nullable
                      as String,
            lineCount: null == lineCount
                ? _value.lineCount
                : lineCount // ignore: cast_nullable_to_non_nullable
                      as int,
            components: null == components
                ? _value.components
                : components // ignore: cast_nullable_to_non_nullable
                      as List<RollupComponent>,
            shortages: null == shortages
                ? _value.shortages
                : shortages // ignore: cast_nullable_to_non_nullable
                      as List<RollupComponent>,
            maxFeasibleScale: freezed == maxFeasibleScale
                ? _value.maxFeasibleScale
                : maxFeasibleScale // ignore: cast_nullable_to_non_nullable
                      as double?,
            subassemblies: null == subassemblies
                ? _value.subassemblies
                : subassemblies // ignore: cast_nullable_to_non_nullable
                      as List<RollupSubassembly>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BasketRollupImplCopyWith<$Res>
    implements $BasketRollupCopyWith<$Res> {
  factory _$$BasketRollupImplCopyWith(
    _$BasketRollupImpl value,
    $Res Function(_$BasketRollupImpl) then,
  ) = __$$BasketRollupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool ok,
    String company,
    @JsonKey(name: 'line_count') int lineCount,
    List<RollupComponent> components,
    List<RollupComponent> shortages,
    @JsonKey(name: 'max_feasible_scale') double? maxFeasibleScale,
    List<RollupSubassembly> subassemblies,
  });
}

/// @nodoc
class __$$BasketRollupImplCopyWithImpl<$Res>
    extends _$BasketRollupCopyWithImpl<$Res, _$BasketRollupImpl>
    implements _$$BasketRollupImplCopyWith<$Res> {
  __$$BasketRollupImplCopyWithImpl(
    _$BasketRollupImpl _value,
    $Res Function(_$BasketRollupImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BasketRollup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ok = null,
    Object? company = null,
    Object? lineCount = null,
    Object? components = null,
    Object? shortages = null,
    Object? maxFeasibleScale = freezed,
    Object? subassemblies = null,
  }) {
    return _then(
      _$BasketRollupImpl(
        ok: null == ok
            ? _value.ok
            : ok // ignore: cast_nullable_to_non_nullable
                  as bool,
        company: null == company
            ? _value.company
            : company // ignore: cast_nullable_to_non_nullable
                  as String,
        lineCount: null == lineCount
            ? _value.lineCount
            : lineCount // ignore: cast_nullable_to_non_nullable
                  as int,
        components: null == components
            ? _value._components
            : components // ignore: cast_nullable_to_non_nullable
                  as List<RollupComponent>,
        shortages: null == shortages
            ? _value._shortages
            : shortages // ignore: cast_nullable_to_non_nullable
                  as List<RollupComponent>,
        maxFeasibleScale: freezed == maxFeasibleScale
            ? _value.maxFeasibleScale
            : maxFeasibleScale // ignore: cast_nullable_to_non_nullable
                  as double?,
        subassemblies: null == subassemblies
            ? _value._subassemblies
            : subassemblies // ignore: cast_nullable_to_non_nullable
                  as List<RollupSubassembly>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BasketRollupImpl extends _BasketRollup {
  const _$BasketRollupImpl({
    this.ok = true,
    this.company = '',
    @JsonKey(name: 'line_count') this.lineCount = 0,
    final List<RollupComponent> components = const <RollupComponent>[],
    final List<RollupComponent> shortages = const <RollupComponent>[],
    @JsonKey(name: 'max_feasible_scale') this.maxFeasibleScale,
    final List<RollupSubassembly> subassemblies = const <RollupSubassembly>[],
  }) : _components = components,
       _shortages = shortages,
       _subassemblies = subassemblies,
       super._();

  factory _$BasketRollupImpl.fromJson(Map<String, dynamic> json) =>
      _$$BasketRollupImplFromJson(json);

  @override
  @JsonKey()
  final bool ok;
  @override
  @JsonKey()
  final String company;
  @override
  @JsonKey(name: 'line_count')
  final int lineCount;
  final List<RollupComponent> _components;
  @override
  @JsonKey()
  List<RollupComponent> get components {
    if (_components is EqualUnmodifiableListView) return _components;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_components);
  }

  final List<RollupComponent> _shortages;
  @override
  @JsonKey()
  List<RollupComponent> get shortages {
    if (_shortages is EqualUnmodifiableListView) return _shortages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_shortages);
  }

  /// Largest uniform fraction of the basket the warehouse can cover.
  /// 1.0 means it fits as-is; 0.6 means every line must shrink to 60%.
  /// Null when nothing constrains it.
  @override
  @JsonKey(name: 'max_feasible_scale')
  final double? maxFeasibleScale;

  /// Phantom sub-assemblies (Cheesecake Mix) made in their own bowl, each
  /// with its own ingredients. ERPNext merges those ingredients into
  /// [components]; this keeps them apart for the kitchen.
  final List<RollupSubassembly> _subassemblies;

  /// Phantom sub-assemblies (Cheesecake Mix) made in their own bowl, each
  /// with its own ingredients. ERPNext merges those ingredients into
  /// [components]; this keeps them apart for the kitchen.
  @override
  @JsonKey()
  List<RollupSubassembly> get subassemblies {
    if (_subassemblies is EqualUnmodifiableListView) return _subassemblies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subassemblies);
  }

  @override
  String toString() {
    return 'BasketRollup(ok: $ok, company: $company, lineCount: $lineCount, components: $components, shortages: $shortages, maxFeasibleScale: $maxFeasibleScale, subassemblies: $subassemblies)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BasketRollupImpl &&
            (identical(other.ok, ok) || other.ok == ok) &&
            (identical(other.company, company) || other.company == company) &&
            (identical(other.lineCount, lineCount) ||
                other.lineCount == lineCount) &&
            const DeepCollectionEquality().equals(
              other._components,
              _components,
            ) &&
            const DeepCollectionEquality().equals(
              other._shortages,
              _shortages,
            ) &&
            (identical(other.maxFeasibleScale, maxFeasibleScale) ||
                other.maxFeasibleScale == maxFeasibleScale) &&
            const DeepCollectionEquality().equals(
              other._subassemblies,
              _subassemblies,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    ok,
    company,
    lineCount,
    const DeepCollectionEquality().hash(_components),
    const DeepCollectionEquality().hash(_shortages),
    maxFeasibleScale,
    const DeepCollectionEquality().hash(_subassemblies),
  );

  /// Create a copy of BasketRollup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BasketRollupImplCopyWith<_$BasketRollupImpl> get copyWith =>
      __$$BasketRollupImplCopyWithImpl<_$BasketRollupImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BasketRollupImplToJson(this);
  }
}

abstract class _BasketRollup extends BasketRollup {
  const factory _BasketRollup({
    final bool ok,
    final String company,
    @JsonKey(name: 'line_count') final int lineCount,
    final List<RollupComponent> components,
    final List<RollupComponent> shortages,
    @JsonKey(name: 'max_feasible_scale') final double? maxFeasibleScale,
    final List<RollupSubassembly> subassemblies,
  }) = _$BasketRollupImpl;
  const _BasketRollup._() : super._();

  factory _BasketRollup.fromJson(Map<String, dynamic> json) =
      _$BasketRollupImpl.fromJson;

  @override
  bool get ok;
  @override
  String get company;
  @override
  @JsonKey(name: 'line_count')
  int get lineCount;
  @override
  List<RollupComponent> get components;
  @override
  List<RollupComponent> get shortages;

  /// Largest uniform fraction of the basket the warehouse can cover.
  /// 1.0 means it fits as-is; 0.6 means every line must shrink to 60%.
  /// Null when nothing constrains it.
  @override
  @JsonKey(name: 'max_feasible_scale')
  double? get maxFeasibleScale;

  /// Phantom sub-assemblies (Cheesecake Mix) made in their own bowl, each
  /// with its own ingredients. ERPNext merges those ingredients into
  /// [components]; this keeps them apart for the kitchen.
  @override
  List<RollupSubassembly> get subassemblies;

  /// Create a copy of BasketRollup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BasketRollupImplCopyWith<_$BasketRollupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RollupComponent _$RollupComponentFromJson(Map<String, dynamic> json) {
  return _RollupComponent.fromJson(json);
}

/// @nodoc
mixin _$RollupComponent {
  @JsonKey(name: 'item_code')
  String get itemCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String get itemName => throw _privateConstructorUsedError;
  String get uom => throw _privateConstructorUsedError;
  @JsonKey(name: 'source_warehouse')
  String? get sourceWarehouse => throw _privateConstructorUsedError;
  @JsonKey(name: 'required_qty')
  double get requiredQty => throw _privateConstructorUsedError;
  @JsonKey(name: 'available_qty')
  double get availableQty => throw _privateConstructorUsedError;
  @JsonKey(name: 'missing_qty')
  double get missingQty => throw _privateConstructorUsedError;
  String? get reason => throw _privateConstructorUsedError;
  @JsonKey(name: 'contributing_lines')
  List<ContributingLine> get contributingLines =>
      throw _privateConstructorUsedError;

  /// Where else this material is sitting, when the backend looked.
  ///
  /// Null means nobody looked — deliberately distinct from `0.0` with an
  /// empty [alternatives] list, which means the lookup ran and there is none
  /// of it anywhere in the company.
  @JsonKey(name: 'available_elsewhere')
  double? get availableElsewhere => throw _privateConstructorUsedError;
  List<StockAlternative>? get alternatives =>
      throw _privateConstructorUsedError;

  /// The part of [requiredQty] NOT inside a sub-assembly (the powder sugar
  /// for the coffee, not the mix's). Null from a server that predates it.
  @JsonKey(name: 'direct_qty')
  double? get directQty => throw _privateConstructorUsedError;

  /// Serializes this RollupComponent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RollupComponent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RollupComponentCopyWith<RollupComponent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RollupComponentCopyWith<$Res> {
  factory $RollupComponentCopyWith(
    RollupComponent value,
    $Res Function(RollupComponent) then,
  ) = _$RollupComponentCopyWithImpl<$Res, RollupComponent>;
  @useResult
  $Res call({
    @JsonKey(name: 'item_code') String itemCode,
    @JsonKey(name: 'item_name') String itemName,
    String uom,
    @JsonKey(name: 'source_warehouse') String? sourceWarehouse,
    @JsonKey(name: 'required_qty') double requiredQty,
    @JsonKey(name: 'available_qty') double availableQty,
    @JsonKey(name: 'missing_qty') double missingQty,
    String? reason,
    @JsonKey(name: 'contributing_lines')
    List<ContributingLine> contributingLines,
    @JsonKey(name: 'available_elsewhere') double? availableElsewhere,
    List<StockAlternative>? alternatives,
    @JsonKey(name: 'direct_qty') double? directQty,
  });
}

/// @nodoc
class _$RollupComponentCopyWithImpl<$Res, $Val extends RollupComponent>
    implements $RollupComponentCopyWith<$Res> {
  _$RollupComponentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RollupComponent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemCode = null,
    Object? itemName = null,
    Object? uom = null,
    Object? sourceWarehouse = freezed,
    Object? requiredQty = null,
    Object? availableQty = null,
    Object? missingQty = null,
    Object? reason = freezed,
    Object? contributingLines = null,
    Object? availableElsewhere = freezed,
    Object? alternatives = freezed,
    Object? directQty = freezed,
  }) {
    return _then(
      _value.copyWith(
            itemCode: null == itemCode
                ? _value.itemCode
                : itemCode // ignore: cast_nullable_to_non_nullable
                      as String,
            itemName: null == itemName
                ? _value.itemName
                : itemName // ignore: cast_nullable_to_non_nullable
                      as String,
            uom: null == uom
                ? _value.uom
                : uom // ignore: cast_nullable_to_non_nullable
                      as String,
            sourceWarehouse: freezed == sourceWarehouse
                ? _value.sourceWarehouse
                : sourceWarehouse // ignore: cast_nullable_to_non_nullable
                      as String?,
            requiredQty: null == requiredQty
                ? _value.requiredQty
                : requiredQty // ignore: cast_nullable_to_non_nullable
                      as double,
            availableQty: null == availableQty
                ? _value.availableQty
                : availableQty // ignore: cast_nullable_to_non_nullable
                      as double,
            missingQty: null == missingQty
                ? _value.missingQty
                : missingQty // ignore: cast_nullable_to_non_nullable
                      as double,
            reason: freezed == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String?,
            contributingLines: null == contributingLines
                ? _value.contributingLines
                : contributingLines // ignore: cast_nullable_to_non_nullable
                      as List<ContributingLine>,
            availableElsewhere: freezed == availableElsewhere
                ? _value.availableElsewhere
                : availableElsewhere // ignore: cast_nullable_to_non_nullable
                      as double?,
            alternatives: freezed == alternatives
                ? _value.alternatives
                : alternatives // ignore: cast_nullable_to_non_nullable
                      as List<StockAlternative>?,
            directQty: freezed == directQty
                ? _value.directQty
                : directQty // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RollupComponentImplCopyWith<$Res>
    implements $RollupComponentCopyWith<$Res> {
  factory _$$RollupComponentImplCopyWith(
    _$RollupComponentImpl value,
    $Res Function(_$RollupComponentImpl) then,
  ) = __$$RollupComponentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'item_code') String itemCode,
    @JsonKey(name: 'item_name') String itemName,
    String uom,
    @JsonKey(name: 'source_warehouse') String? sourceWarehouse,
    @JsonKey(name: 'required_qty') double requiredQty,
    @JsonKey(name: 'available_qty') double availableQty,
    @JsonKey(name: 'missing_qty') double missingQty,
    String? reason,
    @JsonKey(name: 'contributing_lines')
    List<ContributingLine> contributingLines,
    @JsonKey(name: 'available_elsewhere') double? availableElsewhere,
    List<StockAlternative>? alternatives,
    @JsonKey(name: 'direct_qty') double? directQty,
  });
}

/// @nodoc
class __$$RollupComponentImplCopyWithImpl<$Res>
    extends _$RollupComponentCopyWithImpl<$Res, _$RollupComponentImpl>
    implements _$$RollupComponentImplCopyWith<$Res> {
  __$$RollupComponentImplCopyWithImpl(
    _$RollupComponentImpl _value,
    $Res Function(_$RollupComponentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RollupComponent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemCode = null,
    Object? itemName = null,
    Object? uom = null,
    Object? sourceWarehouse = freezed,
    Object? requiredQty = null,
    Object? availableQty = null,
    Object? missingQty = null,
    Object? reason = freezed,
    Object? contributingLines = null,
    Object? availableElsewhere = freezed,
    Object? alternatives = freezed,
    Object? directQty = freezed,
  }) {
    return _then(
      _$RollupComponentImpl(
        itemCode: null == itemCode
            ? _value.itemCode
            : itemCode // ignore: cast_nullable_to_non_nullable
                  as String,
        itemName: null == itemName
            ? _value.itemName
            : itemName // ignore: cast_nullable_to_non_nullable
                  as String,
        uom: null == uom
            ? _value.uom
            : uom // ignore: cast_nullable_to_non_nullable
                  as String,
        sourceWarehouse: freezed == sourceWarehouse
            ? _value.sourceWarehouse
            : sourceWarehouse // ignore: cast_nullable_to_non_nullable
                  as String?,
        requiredQty: null == requiredQty
            ? _value.requiredQty
            : requiredQty // ignore: cast_nullable_to_non_nullable
                  as double,
        availableQty: null == availableQty
            ? _value.availableQty
            : availableQty // ignore: cast_nullable_to_non_nullable
                  as double,
        missingQty: null == missingQty
            ? _value.missingQty
            : missingQty // ignore: cast_nullable_to_non_nullable
                  as double,
        reason: freezed == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String?,
        contributingLines: null == contributingLines
            ? _value._contributingLines
            : contributingLines // ignore: cast_nullable_to_non_nullable
                  as List<ContributingLine>,
        availableElsewhere: freezed == availableElsewhere
            ? _value.availableElsewhere
            : availableElsewhere // ignore: cast_nullable_to_non_nullable
                  as double?,
        alternatives: freezed == alternatives
            ? _value._alternatives
            : alternatives // ignore: cast_nullable_to_non_nullable
                  as List<StockAlternative>?,
        directQty: freezed == directQty
            ? _value.directQty
            : directQty // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RollupComponentImpl extends _RollupComponent {
  const _$RollupComponentImpl({
    @JsonKey(name: 'item_code') this.itemCode = '',
    @JsonKey(name: 'item_name') this.itemName = '',
    this.uom = '',
    @JsonKey(name: 'source_warehouse') this.sourceWarehouse,
    @JsonKey(name: 'required_qty') this.requiredQty = 0.0,
    @JsonKey(name: 'available_qty') this.availableQty = 0.0,
    @JsonKey(name: 'missing_qty') this.missingQty = 0.0,
    this.reason,
    @JsonKey(name: 'contributing_lines')
    final List<ContributingLine> contributingLines = const <ContributingLine>[],
    @JsonKey(name: 'available_elsewhere') this.availableElsewhere,
    final List<StockAlternative>? alternatives,
    @JsonKey(name: 'direct_qty') this.directQty,
  }) : _contributingLines = contributingLines,
       _alternatives = alternatives,
       super._();

  factory _$RollupComponentImpl.fromJson(Map<String, dynamic> json) =>
      _$$RollupComponentImplFromJson(json);

  @override
  @JsonKey(name: 'item_code')
  final String itemCode;
  @override
  @JsonKey(name: 'item_name')
  final String itemName;
  @override
  @JsonKey()
  final String uom;
  @override
  @JsonKey(name: 'source_warehouse')
  final String? sourceWarehouse;
  @override
  @JsonKey(name: 'required_qty')
  final double requiredQty;
  @override
  @JsonKey(name: 'available_qty')
  final double availableQty;
  @override
  @JsonKey(name: 'missing_qty')
  final double missingQty;
  @override
  final String? reason;
  final List<ContributingLine> _contributingLines;
  @override
  @JsonKey(name: 'contributing_lines')
  List<ContributingLine> get contributingLines {
    if (_contributingLines is EqualUnmodifiableListView)
      return _contributingLines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_contributingLines);
  }

  /// Where else this material is sitting, when the backend looked.
  ///
  /// Null means nobody looked — deliberately distinct from `0.0` with an
  /// empty [alternatives] list, which means the lookup ran and there is none
  /// of it anywhere in the company.
  @override
  @JsonKey(name: 'available_elsewhere')
  final double? availableElsewhere;
  final List<StockAlternative>? _alternatives;
  @override
  List<StockAlternative>? get alternatives {
    final value = _alternatives;
    if (value == null) return null;
    if (_alternatives is EqualUnmodifiableListView) return _alternatives;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// The part of [requiredQty] NOT inside a sub-assembly (the powder sugar
  /// for the coffee, not the mix's). Null from a server that predates it.
  @override
  @JsonKey(name: 'direct_qty')
  final double? directQty;

  @override
  String toString() {
    return 'RollupComponent(itemCode: $itemCode, itemName: $itemName, uom: $uom, sourceWarehouse: $sourceWarehouse, requiredQty: $requiredQty, availableQty: $availableQty, missingQty: $missingQty, reason: $reason, contributingLines: $contributingLines, availableElsewhere: $availableElsewhere, alternatives: $alternatives, directQty: $directQty)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RollupComponentImpl &&
            (identical(other.itemCode, itemCode) ||
                other.itemCode == itemCode) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.uom, uom) || other.uom == uom) &&
            (identical(other.sourceWarehouse, sourceWarehouse) ||
                other.sourceWarehouse == sourceWarehouse) &&
            (identical(other.requiredQty, requiredQty) ||
                other.requiredQty == requiredQty) &&
            (identical(other.availableQty, availableQty) ||
                other.availableQty == availableQty) &&
            (identical(other.missingQty, missingQty) ||
                other.missingQty == missingQty) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            const DeepCollectionEquality().equals(
              other._contributingLines,
              _contributingLines,
            ) &&
            (identical(other.availableElsewhere, availableElsewhere) ||
                other.availableElsewhere == availableElsewhere) &&
            const DeepCollectionEquality().equals(
              other._alternatives,
              _alternatives,
            ) &&
            (identical(other.directQty, directQty) ||
                other.directQty == directQty));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    itemCode,
    itemName,
    uom,
    sourceWarehouse,
    requiredQty,
    availableQty,
    missingQty,
    reason,
    const DeepCollectionEquality().hash(_contributingLines),
    availableElsewhere,
    const DeepCollectionEquality().hash(_alternatives),
    directQty,
  );

  /// Create a copy of RollupComponent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RollupComponentImplCopyWith<_$RollupComponentImpl> get copyWith =>
      __$$RollupComponentImplCopyWithImpl<_$RollupComponentImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RollupComponentImplToJson(this);
  }
}

abstract class _RollupComponent extends RollupComponent {
  const factory _RollupComponent({
    @JsonKey(name: 'item_code') final String itemCode,
    @JsonKey(name: 'item_name') final String itemName,
    final String uom,
    @JsonKey(name: 'source_warehouse') final String? sourceWarehouse,
    @JsonKey(name: 'required_qty') final double requiredQty,
    @JsonKey(name: 'available_qty') final double availableQty,
    @JsonKey(name: 'missing_qty') final double missingQty,
    final String? reason,
    @JsonKey(name: 'contributing_lines')
    final List<ContributingLine> contributingLines,
    @JsonKey(name: 'available_elsewhere') final double? availableElsewhere,
    final List<StockAlternative>? alternatives,
    @JsonKey(name: 'direct_qty') final double? directQty,
  }) = _$RollupComponentImpl;
  const _RollupComponent._() : super._();

  factory _RollupComponent.fromJson(Map<String, dynamic> json) =
      _$RollupComponentImpl.fromJson;

  @override
  @JsonKey(name: 'item_code')
  String get itemCode;
  @override
  @JsonKey(name: 'item_name')
  String get itemName;
  @override
  String get uom;
  @override
  @JsonKey(name: 'source_warehouse')
  String? get sourceWarehouse;
  @override
  @JsonKey(name: 'required_qty')
  double get requiredQty;
  @override
  @JsonKey(name: 'available_qty')
  double get availableQty;
  @override
  @JsonKey(name: 'missing_qty')
  double get missingQty;
  @override
  String? get reason;
  @override
  @JsonKey(name: 'contributing_lines')
  List<ContributingLine> get contributingLines;

  /// Where else this material is sitting, when the backend looked.
  ///
  /// Null means nobody looked — deliberately distinct from `0.0` with an
  /// empty [alternatives] list, which means the lookup ran and there is none
  /// of it anywhere in the company.
  @override
  @JsonKey(name: 'available_elsewhere')
  double? get availableElsewhere;
  @override
  List<StockAlternative>? get alternatives;

  /// The part of [requiredQty] NOT inside a sub-assembly (the powder sugar
  /// for the coffee, not the mix's). Null from a server that predates it.
  @override
  @JsonKey(name: 'direct_qty')
  double? get directQty;

  /// Create a copy of RollupComponent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RollupComponentImplCopyWith<_$RollupComponentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ContributingLine _$ContributingLineFromJson(Map<String, dynamic> json) {
  return _ContributingLine.fromJson(json);
}

/// @nodoc
mixin _$ContributingLine {
  @JsonKey(name: 'line_index')
  int get lineIndex => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_code')
  String get itemCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'required_qty')
  double get requiredQty => throw _privateConstructorUsedError;

  /// This line's share outside any sub-assembly; null from an older server.
  @JsonKey(name: 'direct_qty')
  double? get directQty => throw _privateConstructorUsedError;

  /// Serializes this ContributingLine to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ContributingLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContributingLineCopyWith<ContributingLine> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContributingLineCopyWith<$Res> {
  factory $ContributingLineCopyWith(
    ContributingLine value,
    $Res Function(ContributingLine) then,
  ) = _$ContributingLineCopyWithImpl<$Res, ContributingLine>;
  @useResult
  $Res call({
    @JsonKey(name: 'line_index') int lineIndex,
    @JsonKey(name: 'item_code') String itemCode,
    @JsonKey(name: 'required_qty') double requiredQty,
    @JsonKey(name: 'direct_qty') double? directQty,
  });
}

/// @nodoc
class _$ContributingLineCopyWithImpl<$Res, $Val extends ContributingLine>
    implements $ContributingLineCopyWith<$Res> {
  _$ContributingLineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContributingLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lineIndex = null,
    Object? itemCode = null,
    Object? requiredQty = null,
    Object? directQty = freezed,
  }) {
    return _then(
      _value.copyWith(
            lineIndex: null == lineIndex
                ? _value.lineIndex
                : lineIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            itemCode: null == itemCode
                ? _value.itemCode
                : itemCode // ignore: cast_nullable_to_non_nullable
                      as String,
            requiredQty: null == requiredQty
                ? _value.requiredQty
                : requiredQty // ignore: cast_nullable_to_non_nullable
                      as double,
            directQty: freezed == directQty
                ? _value.directQty
                : directQty // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ContributingLineImplCopyWith<$Res>
    implements $ContributingLineCopyWith<$Res> {
  factory _$$ContributingLineImplCopyWith(
    _$ContributingLineImpl value,
    $Res Function(_$ContributingLineImpl) then,
  ) = __$$ContributingLineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'line_index') int lineIndex,
    @JsonKey(name: 'item_code') String itemCode,
    @JsonKey(name: 'required_qty') double requiredQty,
    @JsonKey(name: 'direct_qty') double? directQty,
  });
}

/// @nodoc
class __$$ContributingLineImplCopyWithImpl<$Res>
    extends _$ContributingLineCopyWithImpl<$Res, _$ContributingLineImpl>
    implements _$$ContributingLineImplCopyWith<$Res> {
  __$$ContributingLineImplCopyWithImpl(
    _$ContributingLineImpl _value,
    $Res Function(_$ContributingLineImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContributingLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lineIndex = null,
    Object? itemCode = null,
    Object? requiredQty = null,
    Object? directQty = freezed,
  }) {
    return _then(
      _$ContributingLineImpl(
        lineIndex: null == lineIndex
            ? _value.lineIndex
            : lineIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        itemCode: null == itemCode
            ? _value.itemCode
            : itemCode // ignore: cast_nullable_to_non_nullable
                  as String,
        requiredQty: null == requiredQty
            ? _value.requiredQty
            : requiredQty // ignore: cast_nullable_to_non_nullable
                  as double,
        directQty: freezed == directQty
            ? _value.directQty
            : directQty // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ContributingLineImpl implements _ContributingLine {
  const _$ContributingLineImpl({
    @JsonKey(name: 'line_index') this.lineIndex = 0,
    @JsonKey(name: 'item_code') this.itemCode = '',
    @JsonKey(name: 'required_qty') this.requiredQty = 0.0,
    @JsonKey(name: 'direct_qty') this.directQty,
  });

  factory _$ContributingLineImpl.fromJson(Map<String, dynamic> json) =>
      _$$ContributingLineImplFromJson(json);

  @override
  @JsonKey(name: 'line_index')
  final int lineIndex;
  @override
  @JsonKey(name: 'item_code')
  final String itemCode;
  @override
  @JsonKey(name: 'required_qty')
  final double requiredQty;

  /// This line's share outside any sub-assembly; null from an older server.
  @override
  @JsonKey(name: 'direct_qty')
  final double? directQty;

  @override
  String toString() {
    return 'ContributingLine(lineIndex: $lineIndex, itemCode: $itemCode, requiredQty: $requiredQty, directQty: $directQty)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContributingLineImpl &&
            (identical(other.lineIndex, lineIndex) ||
                other.lineIndex == lineIndex) &&
            (identical(other.itemCode, itemCode) ||
                other.itemCode == itemCode) &&
            (identical(other.requiredQty, requiredQty) ||
                other.requiredQty == requiredQty) &&
            (identical(other.directQty, directQty) ||
                other.directQty == directQty));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, lineIndex, itemCode, requiredQty, directQty);

  /// Create a copy of ContributingLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContributingLineImplCopyWith<_$ContributingLineImpl> get copyWith =>
      __$$ContributingLineImplCopyWithImpl<_$ContributingLineImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ContributingLineImplToJson(this);
  }
}

abstract class _ContributingLine implements ContributingLine {
  const factory _ContributingLine({
    @JsonKey(name: 'line_index') final int lineIndex,
    @JsonKey(name: 'item_code') final String itemCode,
    @JsonKey(name: 'required_qty') final double requiredQty,
    @JsonKey(name: 'direct_qty') final double? directQty,
  }) = _$ContributingLineImpl;

  factory _ContributingLine.fromJson(Map<String, dynamic> json) =
      _$ContributingLineImpl.fromJson;

  @override
  @JsonKey(name: 'line_index')
  int get lineIndex;
  @override
  @JsonKey(name: 'item_code')
  String get itemCode;
  @override
  @JsonKey(name: 'required_qty')
  double get requiredQty;

  /// This line's share outside any sub-assembly; null from an older server.
  @override
  @JsonKey(name: 'direct_qty')
  double? get directQty;

  /// Create a copy of ContributingLine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContributingLineImplCopyWith<_$ContributingLineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RollupSubassembly _$RollupSubassemblyFromJson(Map<String, dynamic> json) {
  return _RollupSubassembly.fromJson(json);
}

/// @nodoc
mixin _$RollupSubassembly {
  @JsonKey(name: 'item_code')
  String get itemCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String get itemName => throw _privateConstructorUsedError;
  String get uom => throw _privateConstructorUsedError;
  @JsonKey(name: 'required_qty')
  double get requiredQty => throw _privateConstructorUsedError;
  @JsonKey(name: 'made_from')
  List<MadeFromLine> get madeFrom => throw _privateConstructorUsedError;
  @JsonKey(name: 'contributing_lines')
  List<ContributingLine> get contributingLines =>
      throw _privateConstructorUsedError;

  /// Serializes this RollupSubassembly to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RollupSubassembly
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RollupSubassemblyCopyWith<RollupSubassembly> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RollupSubassemblyCopyWith<$Res> {
  factory $RollupSubassemblyCopyWith(
    RollupSubassembly value,
    $Res Function(RollupSubassembly) then,
  ) = _$RollupSubassemblyCopyWithImpl<$Res, RollupSubassembly>;
  @useResult
  $Res call({
    @JsonKey(name: 'item_code') String itemCode,
    @JsonKey(name: 'item_name') String itemName,
    String uom,
    @JsonKey(name: 'required_qty') double requiredQty,
    @JsonKey(name: 'made_from') List<MadeFromLine> madeFrom,
    @JsonKey(name: 'contributing_lines')
    List<ContributingLine> contributingLines,
  });
}

/// @nodoc
class _$RollupSubassemblyCopyWithImpl<$Res, $Val extends RollupSubassembly>
    implements $RollupSubassemblyCopyWith<$Res> {
  _$RollupSubassemblyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RollupSubassembly
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemCode = null,
    Object? itemName = null,
    Object? uom = null,
    Object? requiredQty = null,
    Object? madeFrom = null,
    Object? contributingLines = null,
  }) {
    return _then(
      _value.copyWith(
            itemCode: null == itemCode
                ? _value.itemCode
                : itemCode // ignore: cast_nullable_to_non_nullable
                      as String,
            itemName: null == itemName
                ? _value.itemName
                : itemName // ignore: cast_nullable_to_non_nullable
                      as String,
            uom: null == uom
                ? _value.uom
                : uom // ignore: cast_nullable_to_non_nullable
                      as String,
            requiredQty: null == requiredQty
                ? _value.requiredQty
                : requiredQty // ignore: cast_nullable_to_non_nullable
                      as double,
            madeFrom: null == madeFrom
                ? _value.madeFrom
                : madeFrom // ignore: cast_nullable_to_non_nullable
                      as List<MadeFromLine>,
            contributingLines: null == contributingLines
                ? _value.contributingLines
                : contributingLines // ignore: cast_nullable_to_non_nullable
                      as List<ContributingLine>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RollupSubassemblyImplCopyWith<$Res>
    implements $RollupSubassemblyCopyWith<$Res> {
  factory _$$RollupSubassemblyImplCopyWith(
    _$RollupSubassemblyImpl value,
    $Res Function(_$RollupSubassemblyImpl) then,
  ) = __$$RollupSubassemblyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'item_code') String itemCode,
    @JsonKey(name: 'item_name') String itemName,
    String uom,
    @JsonKey(name: 'required_qty') double requiredQty,
    @JsonKey(name: 'made_from') List<MadeFromLine> madeFrom,
    @JsonKey(name: 'contributing_lines')
    List<ContributingLine> contributingLines,
  });
}

/// @nodoc
class __$$RollupSubassemblyImplCopyWithImpl<$Res>
    extends _$RollupSubassemblyCopyWithImpl<$Res, _$RollupSubassemblyImpl>
    implements _$$RollupSubassemblyImplCopyWith<$Res> {
  __$$RollupSubassemblyImplCopyWithImpl(
    _$RollupSubassemblyImpl _value,
    $Res Function(_$RollupSubassemblyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RollupSubassembly
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemCode = null,
    Object? itemName = null,
    Object? uom = null,
    Object? requiredQty = null,
    Object? madeFrom = null,
    Object? contributingLines = null,
  }) {
    return _then(
      _$RollupSubassemblyImpl(
        itemCode: null == itemCode
            ? _value.itemCode
            : itemCode // ignore: cast_nullable_to_non_nullable
                  as String,
        itemName: null == itemName
            ? _value.itemName
            : itemName // ignore: cast_nullable_to_non_nullable
                  as String,
        uom: null == uom
            ? _value.uom
            : uom // ignore: cast_nullable_to_non_nullable
                  as String,
        requiredQty: null == requiredQty
            ? _value.requiredQty
            : requiredQty // ignore: cast_nullable_to_non_nullable
                  as double,
        madeFrom: null == madeFrom
            ? _value._madeFrom
            : madeFrom // ignore: cast_nullable_to_non_nullable
                  as List<MadeFromLine>,
        contributingLines: null == contributingLines
            ? _value._contributingLines
            : contributingLines // ignore: cast_nullable_to_non_nullable
                  as List<ContributingLine>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RollupSubassemblyImpl implements _RollupSubassembly {
  const _$RollupSubassemblyImpl({
    @JsonKey(name: 'item_code') this.itemCode = '',
    @JsonKey(name: 'item_name') this.itemName = '',
    this.uom = '',
    @JsonKey(name: 'required_qty') this.requiredQty = 0.0,
    @JsonKey(name: 'made_from')
    final List<MadeFromLine> madeFrom = const <MadeFromLine>[],
    @JsonKey(name: 'contributing_lines')
    final List<ContributingLine> contributingLines = const <ContributingLine>[],
  }) : _madeFrom = madeFrom,
       _contributingLines = contributingLines;

  factory _$RollupSubassemblyImpl.fromJson(Map<String, dynamic> json) =>
      _$$RollupSubassemblyImplFromJson(json);

  @override
  @JsonKey(name: 'item_code')
  final String itemCode;
  @override
  @JsonKey(name: 'item_name')
  final String itemName;
  @override
  @JsonKey()
  final String uom;
  @override
  @JsonKey(name: 'required_qty')
  final double requiredQty;
  final List<MadeFromLine> _madeFrom;
  @override
  @JsonKey(name: 'made_from')
  List<MadeFromLine> get madeFrom {
    if (_madeFrom is EqualUnmodifiableListView) return _madeFrom;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_madeFrom);
  }

  final List<ContributingLine> _contributingLines;
  @override
  @JsonKey(name: 'contributing_lines')
  List<ContributingLine> get contributingLines {
    if (_contributingLines is EqualUnmodifiableListView)
      return _contributingLines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_contributingLines);
  }

  @override
  String toString() {
    return 'RollupSubassembly(itemCode: $itemCode, itemName: $itemName, uom: $uom, requiredQty: $requiredQty, madeFrom: $madeFrom, contributingLines: $contributingLines)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RollupSubassemblyImpl &&
            (identical(other.itemCode, itemCode) ||
                other.itemCode == itemCode) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.uom, uom) || other.uom == uom) &&
            (identical(other.requiredQty, requiredQty) ||
                other.requiredQty == requiredQty) &&
            const DeepCollectionEquality().equals(other._madeFrom, _madeFrom) &&
            const DeepCollectionEquality().equals(
              other._contributingLines,
              _contributingLines,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    itemCode,
    itemName,
    uom,
    requiredQty,
    const DeepCollectionEquality().hash(_madeFrom),
    const DeepCollectionEquality().hash(_contributingLines),
  );

  /// Create a copy of RollupSubassembly
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RollupSubassemblyImplCopyWith<_$RollupSubassemblyImpl> get copyWith =>
      __$$RollupSubassemblyImplCopyWithImpl<_$RollupSubassemblyImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RollupSubassemblyImplToJson(this);
  }
}

abstract class _RollupSubassembly implements RollupSubassembly {
  const factory _RollupSubassembly({
    @JsonKey(name: 'item_code') final String itemCode,
    @JsonKey(name: 'item_name') final String itemName,
    final String uom,
    @JsonKey(name: 'required_qty') final double requiredQty,
    @JsonKey(name: 'made_from') final List<MadeFromLine> madeFrom,
    @JsonKey(name: 'contributing_lines')
    final List<ContributingLine> contributingLines,
  }) = _$RollupSubassemblyImpl;

  factory _RollupSubassembly.fromJson(Map<String, dynamic> json) =
      _$RollupSubassemblyImpl.fromJson;

  @override
  @JsonKey(name: 'item_code')
  String get itemCode;
  @override
  @JsonKey(name: 'item_name')
  String get itemName;
  @override
  String get uom;
  @override
  @JsonKey(name: 'required_qty')
  double get requiredQty;
  @override
  @JsonKey(name: 'made_from')
  List<MadeFromLine> get madeFrom;
  @override
  @JsonKey(name: 'contributing_lines')
  List<ContributingLine> get contributingLines;

  /// Create a copy of RollupSubassembly
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RollupSubassemblyImplCopyWith<_$RollupSubassemblyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MadeFromLine _$MadeFromLineFromJson(Map<String, dynamic> json) {
  return _MadeFromLine.fromJson(json);
}

/// @nodoc
mixin _$MadeFromLine {
  @JsonKey(name: 'item_code')
  String get itemCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String get itemName => throw _privateConstructorUsedError;
  String get uom => throw _privateConstructorUsedError;
  @JsonKey(name: 'required_qty')
  double get requiredQty => throw _privateConstructorUsedError;

  /// Serializes this MadeFromLine to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MadeFromLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MadeFromLineCopyWith<MadeFromLine> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MadeFromLineCopyWith<$Res> {
  factory $MadeFromLineCopyWith(
    MadeFromLine value,
    $Res Function(MadeFromLine) then,
  ) = _$MadeFromLineCopyWithImpl<$Res, MadeFromLine>;
  @useResult
  $Res call({
    @JsonKey(name: 'item_code') String itemCode,
    @JsonKey(name: 'item_name') String itemName,
    String uom,
    @JsonKey(name: 'required_qty') double requiredQty,
  });
}

/// @nodoc
class _$MadeFromLineCopyWithImpl<$Res, $Val extends MadeFromLine>
    implements $MadeFromLineCopyWith<$Res> {
  _$MadeFromLineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MadeFromLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemCode = null,
    Object? itemName = null,
    Object? uom = null,
    Object? requiredQty = null,
  }) {
    return _then(
      _value.copyWith(
            itemCode: null == itemCode
                ? _value.itemCode
                : itemCode // ignore: cast_nullable_to_non_nullable
                      as String,
            itemName: null == itemName
                ? _value.itemName
                : itemName // ignore: cast_nullable_to_non_nullable
                      as String,
            uom: null == uom
                ? _value.uom
                : uom // ignore: cast_nullable_to_non_nullable
                      as String,
            requiredQty: null == requiredQty
                ? _value.requiredQty
                : requiredQty // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MadeFromLineImplCopyWith<$Res>
    implements $MadeFromLineCopyWith<$Res> {
  factory _$$MadeFromLineImplCopyWith(
    _$MadeFromLineImpl value,
    $Res Function(_$MadeFromLineImpl) then,
  ) = __$$MadeFromLineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'item_code') String itemCode,
    @JsonKey(name: 'item_name') String itemName,
    String uom,
    @JsonKey(name: 'required_qty') double requiredQty,
  });
}

/// @nodoc
class __$$MadeFromLineImplCopyWithImpl<$Res>
    extends _$MadeFromLineCopyWithImpl<$Res, _$MadeFromLineImpl>
    implements _$$MadeFromLineImplCopyWith<$Res> {
  __$$MadeFromLineImplCopyWithImpl(
    _$MadeFromLineImpl _value,
    $Res Function(_$MadeFromLineImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MadeFromLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemCode = null,
    Object? itemName = null,
    Object? uom = null,
    Object? requiredQty = null,
  }) {
    return _then(
      _$MadeFromLineImpl(
        itemCode: null == itemCode
            ? _value.itemCode
            : itemCode // ignore: cast_nullable_to_non_nullable
                  as String,
        itemName: null == itemName
            ? _value.itemName
            : itemName // ignore: cast_nullable_to_non_nullable
                  as String,
        uom: null == uom
            ? _value.uom
            : uom // ignore: cast_nullable_to_non_nullable
                  as String,
        requiredQty: null == requiredQty
            ? _value.requiredQty
            : requiredQty // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MadeFromLineImpl implements _MadeFromLine {
  const _$MadeFromLineImpl({
    @JsonKey(name: 'item_code') this.itemCode = '',
    @JsonKey(name: 'item_name') this.itemName = '',
    this.uom = '',
    @JsonKey(name: 'required_qty') this.requiredQty = 0.0,
  });

  factory _$MadeFromLineImpl.fromJson(Map<String, dynamic> json) =>
      _$$MadeFromLineImplFromJson(json);

  @override
  @JsonKey(name: 'item_code')
  final String itemCode;
  @override
  @JsonKey(name: 'item_name')
  final String itemName;
  @override
  @JsonKey()
  final String uom;
  @override
  @JsonKey(name: 'required_qty')
  final double requiredQty;

  @override
  String toString() {
    return 'MadeFromLine(itemCode: $itemCode, itemName: $itemName, uom: $uom, requiredQty: $requiredQty)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MadeFromLineImpl &&
            (identical(other.itemCode, itemCode) ||
                other.itemCode == itemCode) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.uom, uom) || other.uom == uom) &&
            (identical(other.requiredQty, requiredQty) ||
                other.requiredQty == requiredQty));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, itemCode, itemName, uom, requiredQty);

  /// Create a copy of MadeFromLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MadeFromLineImplCopyWith<_$MadeFromLineImpl> get copyWith =>
      __$$MadeFromLineImplCopyWithImpl<_$MadeFromLineImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MadeFromLineImplToJson(this);
  }
}

abstract class _MadeFromLine implements MadeFromLine {
  const factory _MadeFromLine({
    @JsonKey(name: 'item_code') final String itemCode,
    @JsonKey(name: 'item_name') final String itemName,
    final String uom,
    @JsonKey(name: 'required_qty') final double requiredQty,
  }) = _$MadeFromLineImpl;

  factory _MadeFromLine.fromJson(Map<String, dynamic> json) =
      _$MadeFromLineImpl.fromJson;

  @override
  @JsonKey(name: 'item_code')
  String get itemCode;
  @override
  @JsonKey(name: 'item_name')
  String get itemName;
  @override
  String get uom;
  @override
  @JsonKey(name: 'required_qty')
  double get requiredQty;

  /// Create a copy of MadeFromLine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MadeFromLineImplCopyWith<_$MadeFromLineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
