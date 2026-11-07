// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'branch_replenishment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ReplenishmentItem _$ReplenishmentItemFromJson(Map<String, dynamic> json) {
  return _ReplenishmentItem.fromJson(json);
}

/// @nodoc
mixin _$ReplenishmentItem {
  @JsonKey(name: 'item_code')
  String get itemCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String get itemName => throw _privateConstructorUsedError;
  @JsonKey(name: 'stock_uom')
  String get stockUom => throw _privateConstructorUsedError;
  @JsonKey(name: 'on_hand')
  double get onHand => throw _privateConstructorUsedError;

  /// A negative bin is a counting error, not demand — the branch sold jars
  /// that were never booked in. Surfaced so the row asks for a count instead
  /// of quietly inflating the suggestion; the server has already floored the
  /// suggestion to zero for it.
  @JsonKey(name: 'stock_is_negative', fromJson: _flag)
  bool get stockIsNegative => throw _privateConstructorUsedError;
  @JsonKey(name: 'sells_per_day')
  double get sellsPerDay => throw _privateConstructorUsedError;

  /// Null when this branch has never sold the item. Distinct from zero,
  /// which means "sells, and has run out" — the row must never round the
  /// two together.
  @JsonKey(name: 'days_of_cover')
  double? get daysOfCover => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_days')
  double get targetDays => throw _privateConstructorUsedError;
  @JsonKey(name: 'suggested_qty')
  double get suggestedQty => throw _privateConstructorUsedError;
  @JsonKey(name: 'available_at_source')
  double get availableAtSource => throw _privateConstructorUsedError;
  @JsonKey(name: 'send_now')
  double get sendNow => throw _privateConstructorUsedError;

  /// How much of [suggestedQty] the factory simply does not have. This is
  /// the number that tells the owner to produce more, so it is shown rather
  /// than folded silently into the capped [sendNow].
  @JsonKey(name: 'short_by')
  double get shortBy => throw _privateConstructorUsedError;

  /// Older servers omit everything below; the defaults keep them working.
  @JsonKey(name: 'item_group')
  String get itemGroup => throw _privateConstructorUsedError;

  /// "small" | "medium" | "large", or empty when the server cannot tell.
  @JsonKey(name: 'jar_size')
  String get jarSize => throw _privateConstructorUsedError;

  /// Jars this branch can give away and still keep its own cover.
  @JsonKey(name: 'spare_qty', fromJson: _toInt)
  int get spareQty => throw _privateConstructorUsedError;

  /// Where the factory cannot cover [shortBy], which other branch can.
  @JsonKey(name: 'move_in')
  List<ReplenishmentMoveIn> get moveIn => throw _privateConstructorUsedError;

  /// Serializes this ReplenishmentItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReplenishmentItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReplenishmentItemCopyWith<ReplenishmentItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReplenishmentItemCopyWith<$Res> {
  factory $ReplenishmentItemCopyWith(
    ReplenishmentItem value,
    $Res Function(ReplenishmentItem) then,
  ) = _$ReplenishmentItemCopyWithImpl<$Res, ReplenishmentItem>;
  @useResult
  $Res call({
    @JsonKey(name: 'item_code') String itemCode,
    @JsonKey(name: 'item_name') String itemName,
    @JsonKey(name: 'stock_uom') String stockUom,
    @JsonKey(name: 'on_hand') double onHand,
    @JsonKey(name: 'stock_is_negative', fromJson: _flag) bool stockIsNegative,
    @JsonKey(name: 'sells_per_day') double sellsPerDay,
    @JsonKey(name: 'days_of_cover') double? daysOfCover,
    @JsonKey(name: 'target_days') double targetDays,
    @JsonKey(name: 'suggested_qty') double suggestedQty,
    @JsonKey(name: 'available_at_source') double availableAtSource,
    @JsonKey(name: 'send_now') double sendNow,
    @JsonKey(name: 'short_by') double shortBy,
    @JsonKey(name: 'item_group') String itemGroup,
    @JsonKey(name: 'jar_size') String jarSize,
    @JsonKey(name: 'spare_qty', fromJson: _toInt) int spareQty,
    @JsonKey(name: 'move_in') List<ReplenishmentMoveIn> moveIn,
  });
}

/// @nodoc
class _$ReplenishmentItemCopyWithImpl<$Res, $Val extends ReplenishmentItem>
    implements $ReplenishmentItemCopyWith<$Res> {
  _$ReplenishmentItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReplenishmentItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemCode = null,
    Object? itemName = null,
    Object? stockUom = null,
    Object? onHand = null,
    Object? stockIsNegative = null,
    Object? sellsPerDay = null,
    Object? daysOfCover = freezed,
    Object? targetDays = null,
    Object? suggestedQty = null,
    Object? availableAtSource = null,
    Object? sendNow = null,
    Object? shortBy = null,
    Object? itemGroup = null,
    Object? jarSize = null,
    Object? spareQty = null,
    Object? moveIn = null,
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
            stockUom: null == stockUom
                ? _value.stockUom
                : stockUom // ignore: cast_nullable_to_non_nullable
                      as String,
            onHand: null == onHand
                ? _value.onHand
                : onHand // ignore: cast_nullable_to_non_nullable
                      as double,
            stockIsNegative: null == stockIsNegative
                ? _value.stockIsNegative
                : stockIsNegative // ignore: cast_nullable_to_non_nullable
                      as bool,
            sellsPerDay: null == sellsPerDay
                ? _value.sellsPerDay
                : sellsPerDay // ignore: cast_nullable_to_non_nullable
                      as double,
            daysOfCover: freezed == daysOfCover
                ? _value.daysOfCover
                : daysOfCover // ignore: cast_nullable_to_non_nullable
                      as double?,
            targetDays: null == targetDays
                ? _value.targetDays
                : targetDays // ignore: cast_nullable_to_non_nullable
                      as double,
            suggestedQty: null == suggestedQty
                ? _value.suggestedQty
                : suggestedQty // ignore: cast_nullable_to_non_nullable
                      as double,
            availableAtSource: null == availableAtSource
                ? _value.availableAtSource
                : availableAtSource // ignore: cast_nullable_to_non_nullable
                      as double,
            sendNow: null == sendNow
                ? _value.sendNow
                : sendNow // ignore: cast_nullable_to_non_nullable
                      as double,
            shortBy: null == shortBy
                ? _value.shortBy
                : shortBy // ignore: cast_nullable_to_non_nullable
                      as double,
            itemGroup: null == itemGroup
                ? _value.itemGroup
                : itemGroup // ignore: cast_nullable_to_non_nullable
                      as String,
            jarSize: null == jarSize
                ? _value.jarSize
                : jarSize // ignore: cast_nullable_to_non_nullable
                      as String,
            spareQty: null == spareQty
                ? _value.spareQty
                : spareQty // ignore: cast_nullable_to_non_nullable
                      as int,
            moveIn: null == moveIn
                ? _value.moveIn
                : moveIn // ignore: cast_nullable_to_non_nullable
                      as List<ReplenishmentMoveIn>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReplenishmentItemImplCopyWith<$Res>
    implements $ReplenishmentItemCopyWith<$Res> {
  factory _$$ReplenishmentItemImplCopyWith(
    _$ReplenishmentItemImpl value,
    $Res Function(_$ReplenishmentItemImpl) then,
  ) = __$$ReplenishmentItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'item_code') String itemCode,
    @JsonKey(name: 'item_name') String itemName,
    @JsonKey(name: 'stock_uom') String stockUom,
    @JsonKey(name: 'on_hand') double onHand,
    @JsonKey(name: 'stock_is_negative', fromJson: _flag) bool stockIsNegative,
    @JsonKey(name: 'sells_per_day') double sellsPerDay,
    @JsonKey(name: 'days_of_cover') double? daysOfCover,
    @JsonKey(name: 'target_days') double targetDays,
    @JsonKey(name: 'suggested_qty') double suggestedQty,
    @JsonKey(name: 'available_at_source') double availableAtSource,
    @JsonKey(name: 'send_now') double sendNow,
    @JsonKey(name: 'short_by') double shortBy,
    @JsonKey(name: 'item_group') String itemGroup,
    @JsonKey(name: 'jar_size') String jarSize,
    @JsonKey(name: 'spare_qty', fromJson: _toInt) int spareQty,
    @JsonKey(name: 'move_in') List<ReplenishmentMoveIn> moveIn,
  });
}

/// @nodoc
class __$$ReplenishmentItemImplCopyWithImpl<$Res>
    extends _$ReplenishmentItemCopyWithImpl<$Res, _$ReplenishmentItemImpl>
    implements _$$ReplenishmentItemImplCopyWith<$Res> {
  __$$ReplenishmentItemImplCopyWithImpl(
    _$ReplenishmentItemImpl _value,
    $Res Function(_$ReplenishmentItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReplenishmentItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemCode = null,
    Object? itemName = null,
    Object? stockUom = null,
    Object? onHand = null,
    Object? stockIsNegative = null,
    Object? sellsPerDay = null,
    Object? daysOfCover = freezed,
    Object? targetDays = null,
    Object? suggestedQty = null,
    Object? availableAtSource = null,
    Object? sendNow = null,
    Object? shortBy = null,
    Object? itemGroup = null,
    Object? jarSize = null,
    Object? spareQty = null,
    Object? moveIn = null,
  }) {
    return _then(
      _$ReplenishmentItemImpl(
        itemCode: null == itemCode
            ? _value.itemCode
            : itemCode // ignore: cast_nullable_to_non_nullable
                  as String,
        itemName: null == itemName
            ? _value.itemName
            : itemName // ignore: cast_nullable_to_non_nullable
                  as String,
        stockUom: null == stockUom
            ? _value.stockUom
            : stockUom // ignore: cast_nullable_to_non_nullable
                  as String,
        onHand: null == onHand
            ? _value.onHand
            : onHand // ignore: cast_nullable_to_non_nullable
                  as double,
        stockIsNegative: null == stockIsNegative
            ? _value.stockIsNegative
            : stockIsNegative // ignore: cast_nullable_to_non_nullable
                  as bool,
        sellsPerDay: null == sellsPerDay
            ? _value.sellsPerDay
            : sellsPerDay // ignore: cast_nullable_to_non_nullable
                  as double,
        daysOfCover: freezed == daysOfCover
            ? _value.daysOfCover
            : daysOfCover // ignore: cast_nullable_to_non_nullable
                  as double?,
        targetDays: null == targetDays
            ? _value.targetDays
            : targetDays // ignore: cast_nullable_to_non_nullable
                  as double,
        suggestedQty: null == suggestedQty
            ? _value.suggestedQty
            : suggestedQty // ignore: cast_nullable_to_non_nullable
                  as double,
        availableAtSource: null == availableAtSource
            ? _value.availableAtSource
            : availableAtSource // ignore: cast_nullable_to_non_nullable
                  as double,
        sendNow: null == sendNow
            ? _value.sendNow
            : sendNow // ignore: cast_nullable_to_non_nullable
                  as double,
        shortBy: null == shortBy
            ? _value.shortBy
            : shortBy // ignore: cast_nullable_to_non_nullable
                  as double,
        itemGroup: null == itemGroup
            ? _value.itemGroup
            : itemGroup // ignore: cast_nullable_to_non_nullable
                  as String,
        jarSize: null == jarSize
            ? _value.jarSize
            : jarSize // ignore: cast_nullable_to_non_nullable
                  as String,
        spareQty: null == spareQty
            ? _value.spareQty
            : spareQty // ignore: cast_nullable_to_non_nullable
                  as int,
        moveIn: null == moveIn
            ? _value._moveIn
            : moveIn // ignore: cast_nullable_to_non_nullable
                  as List<ReplenishmentMoveIn>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReplenishmentItemImpl extends _ReplenishmentItem {
  const _$ReplenishmentItemImpl({
    @JsonKey(name: 'item_code') this.itemCode = '',
    @JsonKey(name: 'item_name') this.itemName = '',
    @JsonKey(name: 'stock_uom') this.stockUom = '',
    @JsonKey(name: 'on_hand') this.onHand = 0.0,
    @JsonKey(name: 'stock_is_negative', fromJson: _flag)
    this.stockIsNegative = false,
    @JsonKey(name: 'sells_per_day') this.sellsPerDay = 0.0,
    @JsonKey(name: 'days_of_cover') this.daysOfCover,
    @JsonKey(name: 'target_days') this.targetDays = 0.0,
    @JsonKey(name: 'suggested_qty') this.suggestedQty = 0.0,
    @JsonKey(name: 'available_at_source') this.availableAtSource = 0.0,
    @JsonKey(name: 'send_now') this.sendNow = 0.0,
    @JsonKey(name: 'short_by') this.shortBy = 0.0,
    @JsonKey(name: 'item_group') this.itemGroup = '',
    @JsonKey(name: 'jar_size') this.jarSize = '',
    @JsonKey(name: 'spare_qty', fromJson: _toInt) this.spareQty = 0,
    @JsonKey(name: 'move_in')
    final List<ReplenishmentMoveIn> moveIn = const <ReplenishmentMoveIn>[],
  }) : _moveIn = moveIn,
       super._();

  factory _$ReplenishmentItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReplenishmentItemImplFromJson(json);

  @override
  @JsonKey(name: 'item_code')
  final String itemCode;
  @override
  @JsonKey(name: 'item_name')
  final String itemName;
  @override
  @JsonKey(name: 'stock_uom')
  final String stockUom;
  @override
  @JsonKey(name: 'on_hand')
  final double onHand;

  /// A negative bin is a counting error, not demand — the branch sold jars
  /// that were never booked in. Surfaced so the row asks for a count instead
  /// of quietly inflating the suggestion; the server has already floored the
  /// suggestion to zero for it.
  @override
  @JsonKey(name: 'stock_is_negative', fromJson: _flag)
  final bool stockIsNegative;
  @override
  @JsonKey(name: 'sells_per_day')
  final double sellsPerDay;

  /// Null when this branch has never sold the item. Distinct from zero,
  /// which means "sells, and has run out" — the row must never round the
  /// two together.
  @override
  @JsonKey(name: 'days_of_cover')
  final double? daysOfCover;
  @override
  @JsonKey(name: 'target_days')
  final double targetDays;
  @override
  @JsonKey(name: 'suggested_qty')
  final double suggestedQty;
  @override
  @JsonKey(name: 'available_at_source')
  final double availableAtSource;
  @override
  @JsonKey(name: 'send_now')
  final double sendNow;

  /// How much of [suggestedQty] the factory simply does not have. This is
  /// the number that tells the owner to produce more, so it is shown rather
  /// than folded silently into the capped [sendNow].
  @override
  @JsonKey(name: 'short_by')
  final double shortBy;

  /// Older servers omit everything below; the defaults keep them working.
  @override
  @JsonKey(name: 'item_group')
  final String itemGroup;

  /// "small" | "medium" | "large", or empty when the server cannot tell.
  @override
  @JsonKey(name: 'jar_size')
  final String jarSize;

  /// Jars this branch can give away and still keep its own cover.
  @override
  @JsonKey(name: 'spare_qty', fromJson: _toInt)
  final int spareQty;

  /// Where the factory cannot cover [shortBy], which other branch can.
  final List<ReplenishmentMoveIn> _moveIn;

  /// Where the factory cannot cover [shortBy], which other branch can.
  @override
  @JsonKey(name: 'move_in')
  List<ReplenishmentMoveIn> get moveIn {
    if (_moveIn is EqualUnmodifiableListView) return _moveIn;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_moveIn);
  }

  @override
  String toString() {
    return 'ReplenishmentItem(itemCode: $itemCode, itemName: $itemName, stockUom: $stockUom, onHand: $onHand, stockIsNegative: $stockIsNegative, sellsPerDay: $sellsPerDay, daysOfCover: $daysOfCover, targetDays: $targetDays, suggestedQty: $suggestedQty, availableAtSource: $availableAtSource, sendNow: $sendNow, shortBy: $shortBy, itemGroup: $itemGroup, jarSize: $jarSize, spareQty: $spareQty, moveIn: $moveIn)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReplenishmentItemImpl &&
            (identical(other.itemCode, itemCode) ||
                other.itemCode == itemCode) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.stockUom, stockUom) ||
                other.stockUom == stockUom) &&
            (identical(other.onHand, onHand) || other.onHand == onHand) &&
            (identical(other.stockIsNegative, stockIsNegative) ||
                other.stockIsNegative == stockIsNegative) &&
            (identical(other.sellsPerDay, sellsPerDay) ||
                other.sellsPerDay == sellsPerDay) &&
            (identical(other.daysOfCover, daysOfCover) ||
                other.daysOfCover == daysOfCover) &&
            (identical(other.targetDays, targetDays) ||
                other.targetDays == targetDays) &&
            (identical(other.suggestedQty, suggestedQty) ||
                other.suggestedQty == suggestedQty) &&
            (identical(other.availableAtSource, availableAtSource) ||
                other.availableAtSource == availableAtSource) &&
            (identical(other.sendNow, sendNow) || other.sendNow == sendNow) &&
            (identical(other.shortBy, shortBy) || other.shortBy == shortBy) &&
            (identical(other.itemGroup, itemGroup) ||
                other.itemGroup == itemGroup) &&
            (identical(other.jarSize, jarSize) || other.jarSize == jarSize) &&
            (identical(other.spareQty, spareQty) ||
                other.spareQty == spareQty) &&
            const DeepCollectionEquality().equals(other._moveIn, _moveIn));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    itemCode,
    itemName,
    stockUom,
    onHand,
    stockIsNegative,
    sellsPerDay,
    daysOfCover,
    targetDays,
    suggestedQty,
    availableAtSource,
    sendNow,
    shortBy,
    itemGroup,
    jarSize,
    spareQty,
    const DeepCollectionEquality().hash(_moveIn),
  );

  /// Create a copy of ReplenishmentItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReplenishmentItemImplCopyWith<_$ReplenishmentItemImpl> get copyWith =>
      __$$ReplenishmentItemImplCopyWithImpl<_$ReplenishmentItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ReplenishmentItemImplToJson(this);
  }
}

abstract class _ReplenishmentItem extends ReplenishmentItem {
  const factory _ReplenishmentItem({
    @JsonKey(name: 'item_code') final String itemCode,
    @JsonKey(name: 'item_name') final String itemName,
    @JsonKey(name: 'stock_uom') final String stockUom,
    @JsonKey(name: 'on_hand') final double onHand,
    @JsonKey(name: 'stock_is_negative', fromJson: _flag)
    final bool stockIsNegative,
    @JsonKey(name: 'sells_per_day') final double sellsPerDay,
    @JsonKey(name: 'days_of_cover') final double? daysOfCover,
    @JsonKey(name: 'target_days') final double targetDays,
    @JsonKey(name: 'suggested_qty') final double suggestedQty,
    @JsonKey(name: 'available_at_source') final double availableAtSource,
    @JsonKey(name: 'send_now') final double sendNow,
    @JsonKey(name: 'short_by') final double shortBy,
    @JsonKey(name: 'item_group') final String itemGroup,
    @JsonKey(name: 'jar_size') final String jarSize,
    @JsonKey(name: 'spare_qty', fromJson: _toInt) final int spareQty,
    @JsonKey(name: 'move_in') final List<ReplenishmentMoveIn> moveIn,
  }) = _$ReplenishmentItemImpl;
  const _ReplenishmentItem._() : super._();

  factory _ReplenishmentItem.fromJson(Map<String, dynamic> json) =
      _$ReplenishmentItemImpl.fromJson;

  @override
  @JsonKey(name: 'item_code')
  String get itemCode;
  @override
  @JsonKey(name: 'item_name')
  String get itemName;
  @override
  @JsonKey(name: 'stock_uom')
  String get stockUom;
  @override
  @JsonKey(name: 'on_hand')
  double get onHand;

  /// A negative bin is a counting error, not demand — the branch sold jars
  /// that were never booked in. Surfaced so the row asks for a count instead
  /// of quietly inflating the suggestion; the server has already floored the
  /// suggestion to zero for it.
  @override
  @JsonKey(name: 'stock_is_negative', fromJson: _flag)
  bool get stockIsNegative;
  @override
  @JsonKey(name: 'sells_per_day')
  double get sellsPerDay;

  /// Null when this branch has never sold the item. Distinct from zero,
  /// which means "sells, and has run out" — the row must never round the
  /// two together.
  @override
  @JsonKey(name: 'days_of_cover')
  double? get daysOfCover;
  @override
  @JsonKey(name: 'target_days')
  double get targetDays;
  @override
  @JsonKey(name: 'suggested_qty')
  double get suggestedQty;
  @override
  @JsonKey(name: 'available_at_source')
  double get availableAtSource;
  @override
  @JsonKey(name: 'send_now')
  double get sendNow;

  /// How much of [suggestedQty] the factory simply does not have. This is
  /// the number that tells the owner to produce more, so it is shown rather
  /// than folded silently into the capped [sendNow].
  @override
  @JsonKey(name: 'short_by')
  double get shortBy;

  /// Older servers omit everything below; the defaults keep them working.
  @override
  @JsonKey(name: 'item_group')
  String get itemGroup;

  /// "small" | "medium" | "large", or empty when the server cannot tell.
  @override
  @JsonKey(name: 'jar_size')
  String get jarSize;

  /// Jars this branch can give away and still keep its own cover.
  @override
  @JsonKey(name: 'spare_qty', fromJson: _toInt)
  int get spareQty;

  /// Where the factory cannot cover [shortBy], which other branch can.
  @override
  @JsonKey(name: 'move_in')
  List<ReplenishmentMoveIn> get moveIn;

  /// Create a copy of ReplenishmentItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReplenishmentItemImplCopyWith<_$ReplenishmentItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReplenishmentMoveIn _$ReplenishmentMoveInFromJson(Map<String, dynamic> json) {
  return _ReplenishmentMoveIn.fromJson(json);
}

/// @nodoc
mixin _$ReplenishmentMoveIn {
  @JsonKey(name: 'from_warehouse')
  String get fromWarehouse => throw _privateConstructorUsedError;
  @JsonKey(name: 'from_branch')
  String get fromBranch => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get qty => throw _privateConstructorUsedError;

  /// Serializes this ReplenishmentMoveIn to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReplenishmentMoveIn
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReplenishmentMoveInCopyWith<ReplenishmentMoveIn> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReplenishmentMoveInCopyWith<$Res> {
  factory $ReplenishmentMoveInCopyWith(
    ReplenishmentMoveIn value,
    $Res Function(ReplenishmentMoveIn) then,
  ) = _$ReplenishmentMoveInCopyWithImpl<$Res, ReplenishmentMoveIn>;
  @useResult
  $Res call({
    @JsonKey(name: 'from_warehouse') String fromWarehouse,
    @JsonKey(name: 'from_branch') String fromBranch,
    @JsonKey(fromJson: _toInt) int qty,
  });
}

/// @nodoc
class _$ReplenishmentMoveInCopyWithImpl<$Res, $Val extends ReplenishmentMoveIn>
    implements $ReplenishmentMoveInCopyWith<$Res> {
  _$ReplenishmentMoveInCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReplenishmentMoveIn
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromWarehouse = null,
    Object? fromBranch = null,
    Object? qty = null,
  }) {
    return _then(
      _value.copyWith(
            fromWarehouse: null == fromWarehouse
                ? _value.fromWarehouse
                : fromWarehouse // ignore: cast_nullable_to_non_nullable
                      as String,
            fromBranch: null == fromBranch
                ? _value.fromBranch
                : fromBranch // ignore: cast_nullable_to_non_nullable
                      as String,
            qty: null == qty
                ? _value.qty
                : qty // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReplenishmentMoveInImplCopyWith<$Res>
    implements $ReplenishmentMoveInCopyWith<$Res> {
  factory _$$ReplenishmentMoveInImplCopyWith(
    _$ReplenishmentMoveInImpl value,
    $Res Function(_$ReplenishmentMoveInImpl) then,
  ) = __$$ReplenishmentMoveInImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'from_warehouse') String fromWarehouse,
    @JsonKey(name: 'from_branch') String fromBranch,
    @JsonKey(fromJson: _toInt) int qty,
  });
}

/// @nodoc
class __$$ReplenishmentMoveInImplCopyWithImpl<$Res>
    extends _$ReplenishmentMoveInCopyWithImpl<$Res, _$ReplenishmentMoveInImpl>
    implements _$$ReplenishmentMoveInImplCopyWith<$Res> {
  __$$ReplenishmentMoveInImplCopyWithImpl(
    _$ReplenishmentMoveInImpl _value,
    $Res Function(_$ReplenishmentMoveInImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReplenishmentMoveIn
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromWarehouse = null,
    Object? fromBranch = null,
    Object? qty = null,
  }) {
    return _then(
      _$ReplenishmentMoveInImpl(
        fromWarehouse: null == fromWarehouse
            ? _value.fromWarehouse
            : fromWarehouse // ignore: cast_nullable_to_non_nullable
                  as String,
        fromBranch: null == fromBranch
            ? _value.fromBranch
            : fromBranch // ignore: cast_nullable_to_non_nullable
                  as String,
        qty: null == qty
            ? _value.qty
            : qty // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReplenishmentMoveInImpl extends _ReplenishmentMoveIn {
  const _$ReplenishmentMoveInImpl({
    @JsonKey(name: 'from_warehouse') this.fromWarehouse = '',
    @JsonKey(name: 'from_branch') this.fromBranch = '',
    @JsonKey(fromJson: _toInt) this.qty = 0,
  }) : super._();

  factory _$ReplenishmentMoveInImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReplenishmentMoveInImplFromJson(json);

  @override
  @JsonKey(name: 'from_warehouse')
  final String fromWarehouse;
  @override
  @JsonKey(name: 'from_branch')
  final String fromBranch;
  @override
  @JsonKey(fromJson: _toInt)
  final int qty;

  @override
  String toString() {
    return 'ReplenishmentMoveIn(fromWarehouse: $fromWarehouse, fromBranch: $fromBranch, qty: $qty)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReplenishmentMoveInImpl &&
            (identical(other.fromWarehouse, fromWarehouse) ||
                other.fromWarehouse == fromWarehouse) &&
            (identical(other.fromBranch, fromBranch) ||
                other.fromBranch == fromBranch) &&
            (identical(other.qty, qty) || other.qty == qty));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, fromWarehouse, fromBranch, qty);

  /// Create a copy of ReplenishmentMoveIn
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReplenishmentMoveInImplCopyWith<_$ReplenishmentMoveInImpl> get copyWith =>
      __$$ReplenishmentMoveInImplCopyWithImpl<_$ReplenishmentMoveInImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ReplenishmentMoveInImplToJson(this);
  }
}

abstract class _ReplenishmentMoveIn extends ReplenishmentMoveIn {
  const factory _ReplenishmentMoveIn({
    @JsonKey(name: 'from_warehouse') final String fromWarehouse,
    @JsonKey(name: 'from_branch') final String fromBranch,
    @JsonKey(fromJson: _toInt) final int qty,
  }) = _$ReplenishmentMoveInImpl;
  const _ReplenishmentMoveIn._() : super._();

  factory _ReplenishmentMoveIn.fromJson(Map<String, dynamic> json) =
      _$ReplenishmentMoveInImpl.fromJson;

  @override
  @JsonKey(name: 'from_warehouse')
  String get fromWarehouse;
  @override
  @JsonKey(name: 'from_branch')
  String get fromBranch;
  @override
  @JsonKey(fromJson: _toInt)
  int get qty;

  /// Create a copy of ReplenishmentMoveIn
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReplenishmentMoveInImplCopyWith<_$ReplenishmentMoveInImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReplenishmentBranchMove _$ReplenishmentBranchMoveFromJson(
  Map<String, dynamic> json,
) {
  return _ReplenishmentBranchMove.fromJson(json);
}

/// @nodoc
mixin _$ReplenishmentBranchMove {
  @JsonKey(name: 'item_code')
  String get itemCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String get itemName => throw _privateConstructorUsedError;
  @JsonKey(name: 'jar_size')
  String get jarSize => throw _privateConstructorUsedError;
  @JsonKey(name: 'from_warehouse')
  String get fromWarehouse => throw _privateConstructorUsedError;
  @JsonKey(name: 'from_branch')
  String get fromBranch => throw _privateConstructorUsedError;
  @JsonKey(name: 'to_warehouse')
  String get toWarehouse => throw _privateConstructorUsedError;
  @JsonKey(name: 'to_branch')
  String get toBranch => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get qty => throw _privateConstructorUsedError;

  /// Serializes this ReplenishmentBranchMove to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReplenishmentBranchMove
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReplenishmentBranchMoveCopyWith<ReplenishmentBranchMove> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReplenishmentBranchMoveCopyWith<$Res> {
  factory $ReplenishmentBranchMoveCopyWith(
    ReplenishmentBranchMove value,
    $Res Function(ReplenishmentBranchMove) then,
  ) = _$ReplenishmentBranchMoveCopyWithImpl<$Res, ReplenishmentBranchMove>;
  @useResult
  $Res call({
    @JsonKey(name: 'item_code') String itemCode,
    @JsonKey(name: 'item_name') String itemName,
    @JsonKey(name: 'jar_size') String jarSize,
    @JsonKey(name: 'from_warehouse') String fromWarehouse,
    @JsonKey(name: 'from_branch') String fromBranch,
    @JsonKey(name: 'to_warehouse') String toWarehouse,
    @JsonKey(name: 'to_branch') String toBranch,
    @JsonKey(fromJson: _toInt) int qty,
  });
}

/// @nodoc
class _$ReplenishmentBranchMoveCopyWithImpl<
  $Res,
  $Val extends ReplenishmentBranchMove
>
    implements $ReplenishmentBranchMoveCopyWith<$Res> {
  _$ReplenishmentBranchMoveCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReplenishmentBranchMove
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemCode = null,
    Object? itemName = null,
    Object? jarSize = null,
    Object? fromWarehouse = null,
    Object? fromBranch = null,
    Object? toWarehouse = null,
    Object? toBranch = null,
    Object? qty = null,
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
            jarSize: null == jarSize
                ? _value.jarSize
                : jarSize // ignore: cast_nullable_to_non_nullable
                      as String,
            fromWarehouse: null == fromWarehouse
                ? _value.fromWarehouse
                : fromWarehouse // ignore: cast_nullable_to_non_nullable
                      as String,
            fromBranch: null == fromBranch
                ? _value.fromBranch
                : fromBranch // ignore: cast_nullable_to_non_nullable
                      as String,
            toWarehouse: null == toWarehouse
                ? _value.toWarehouse
                : toWarehouse // ignore: cast_nullable_to_non_nullable
                      as String,
            toBranch: null == toBranch
                ? _value.toBranch
                : toBranch // ignore: cast_nullable_to_non_nullable
                      as String,
            qty: null == qty
                ? _value.qty
                : qty // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReplenishmentBranchMoveImplCopyWith<$Res>
    implements $ReplenishmentBranchMoveCopyWith<$Res> {
  factory _$$ReplenishmentBranchMoveImplCopyWith(
    _$ReplenishmentBranchMoveImpl value,
    $Res Function(_$ReplenishmentBranchMoveImpl) then,
  ) = __$$ReplenishmentBranchMoveImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'item_code') String itemCode,
    @JsonKey(name: 'item_name') String itemName,
    @JsonKey(name: 'jar_size') String jarSize,
    @JsonKey(name: 'from_warehouse') String fromWarehouse,
    @JsonKey(name: 'from_branch') String fromBranch,
    @JsonKey(name: 'to_warehouse') String toWarehouse,
    @JsonKey(name: 'to_branch') String toBranch,
    @JsonKey(fromJson: _toInt) int qty,
  });
}

/// @nodoc
class __$$ReplenishmentBranchMoveImplCopyWithImpl<$Res>
    extends
        _$ReplenishmentBranchMoveCopyWithImpl<
          $Res,
          _$ReplenishmentBranchMoveImpl
        >
    implements _$$ReplenishmentBranchMoveImplCopyWith<$Res> {
  __$$ReplenishmentBranchMoveImplCopyWithImpl(
    _$ReplenishmentBranchMoveImpl _value,
    $Res Function(_$ReplenishmentBranchMoveImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReplenishmentBranchMove
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemCode = null,
    Object? itemName = null,
    Object? jarSize = null,
    Object? fromWarehouse = null,
    Object? fromBranch = null,
    Object? toWarehouse = null,
    Object? toBranch = null,
    Object? qty = null,
  }) {
    return _then(
      _$ReplenishmentBranchMoveImpl(
        itemCode: null == itemCode
            ? _value.itemCode
            : itemCode // ignore: cast_nullable_to_non_nullable
                  as String,
        itemName: null == itemName
            ? _value.itemName
            : itemName // ignore: cast_nullable_to_non_nullable
                  as String,
        jarSize: null == jarSize
            ? _value.jarSize
            : jarSize // ignore: cast_nullable_to_non_nullable
                  as String,
        fromWarehouse: null == fromWarehouse
            ? _value.fromWarehouse
            : fromWarehouse // ignore: cast_nullable_to_non_nullable
                  as String,
        fromBranch: null == fromBranch
            ? _value.fromBranch
            : fromBranch // ignore: cast_nullable_to_non_nullable
                  as String,
        toWarehouse: null == toWarehouse
            ? _value.toWarehouse
            : toWarehouse // ignore: cast_nullable_to_non_nullable
                  as String,
        toBranch: null == toBranch
            ? _value.toBranch
            : toBranch // ignore: cast_nullable_to_non_nullable
                  as String,
        qty: null == qty
            ? _value.qty
            : qty // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReplenishmentBranchMoveImpl extends _ReplenishmentBranchMove {
  const _$ReplenishmentBranchMoveImpl({
    @JsonKey(name: 'item_code') this.itemCode = '',
    @JsonKey(name: 'item_name') this.itemName = '',
    @JsonKey(name: 'jar_size') this.jarSize = '',
    @JsonKey(name: 'from_warehouse') this.fromWarehouse = '',
    @JsonKey(name: 'from_branch') this.fromBranch = '',
    @JsonKey(name: 'to_warehouse') this.toWarehouse = '',
    @JsonKey(name: 'to_branch') this.toBranch = '',
    @JsonKey(fromJson: _toInt) this.qty = 0,
  }) : super._();

  factory _$ReplenishmentBranchMoveImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReplenishmentBranchMoveImplFromJson(json);

  @override
  @JsonKey(name: 'item_code')
  final String itemCode;
  @override
  @JsonKey(name: 'item_name')
  final String itemName;
  @override
  @JsonKey(name: 'jar_size')
  final String jarSize;
  @override
  @JsonKey(name: 'from_warehouse')
  final String fromWarehouse;
  @override
  @JsonKey(name: 'from_branch')
  final String fromBranch;
  @override
  @JsonKey(name: 'to_warehouse')
  final String toWarehouse;
  @override
  @JsonKey(name: 'to_branch')
  final String toBranch;
  @override
  @JsonKey(fromJson: _toInt)
  final int qty;

  @override
  String toString() {
    return 'ReplenishmentBranchMove(itemCode: $itemCode, itemName: $itemName, jarSize: $jarSize, fromWarehouse: $fromWarehouse, fromBranch: $fromBranch, toWarehouse: $toWarehouse, toBranch: $toBranch, qty: $qty)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReplenishmentBranchMoveImpl &&
            (identical(other.itemCode, itemCode) ||
                other.itemCode == itemCode) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.jarSize, jarSize) || other.jarSize == jarSize) &&
            (identical(other.fromWarehouse, fromWarehouse) ||
                other.fromWarehouse == fromWarehouse) &&
            (identical(other.fromBranch, fromBranch) ||
                other.fromBranch == fromBranch) &&
            (identical(other.toWarehouse, toWarehouse) ||
                other.toWarehouse == toWarehouse) &&
            (identical(other.toBranch, toBranch) ||
                other.toBranch == toBranch) &&
            (identical(other.qty, qty) || other.qty == qty));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    itemCode,
    itemName,
    jarSize,
    fromWarehouse,
    fromBranch,
    toWarehouse,
    toBranch,
    qty,
  );

  /// Create a copy of ReplenishmentBranchMove
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReplenishmentBranchMoveImplCopyWith<_$ReplenishmentBranchMoveImpl>
  get copyWith =>
      __$$ReplenishmentBranchMoveImplCopyWithImpl<
        _$ReplenishmentBranchMoveImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReplenishmentBranchMoveImplToJson(this);
  }
}

abstract class _ReplenishmentBranchMove extends ReplenishmentBranchMove {
  const factory _ReplenishmentBranchMove({
    @JsonKey(name: 'item_code') final String itemCode,
    @JsonKey(name: 'item_name') final String itemName,
    @JsonKey(name: 'jar_size') final String jarSize,
    @JsonKey(name: 'from_warehouse') final String fromWarehouse,
    @JsonKey(name: 'from_branch') final String fromBranch,
    @JsonKey(name: 'to_warehouse') final String toWarehouse,
    @JsonKey(name: 'to_branch') final String toBranch,
    @JsonKey(fromJson: _toInt) final int qty,
  }) = _$ReplenishmentBranchMoveImpl;
  const _ReplenishmentBranchMove._() : super._();

  factory _ReplenishmentBranchMove.fromJson(Map<String, dynamic> json) =
      _$ReplenishmentBranchMoveImpl.fromJson;

  @override
  @JsonKey(name: 'item_code')
  String get itemCode;
  @override
  @JsonKey(name: 'item_name')
  String get itemName;
  @override
  @JsonKey(name: 'jar_size')
  String get jarSize;
  @override
  @JsonKey(name: 'from_warehouse')
  String get fromWarehouse;
  @override
  @JsonKey(name: 'from_branch')
  String get fromBranch;
  @override
  @JsonKey(name: 'to_warehouse')
  String get toWarehouse;
  @override
  @JsonKey(name: 'to_branch')
  String get toBranch;
  @override
  @JsonKey(fromJson: _toInt)
  int get qty;

  /// Create a copy of ReplenishmentBranchMove
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReplenishmentBranchMoveImplCopyWith<_$ReplenishmentBranchMoveImpl>
  get copyWith => throw _privateConstructorUsedError;
}

ReplenishmentSummary _$ReplenishmentSummaryFromJson(Map<String, dynamic> json) {
  return _ReplenishmentSummary.fromJson(json);
}

/// @nodoc
mixin _$ReplenishmentSummary {
  @JsonKey(name: 'items_below_cover')
  int get itemsBelowCover => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_suggested')
  double get totalSuggested => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_send_now')
  double get totalSendNow => throw _privateConstructorUsedError;
  @JsonKey(name: 'negative_bins')
  int get negativeBins => throw _privateConstructorUsedError;
  int get branches => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_short_by')
  double get totalShortBy => throw _privateConstructorUsedError;

  /// Serializes this ReplenishmentSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReplenishmentSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReplenishmentSummaryCopyWith<ReplenishmentSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReplenishmentSummaryCopyWith<$Res> {
  factory $ReplenishmentSummaryCopyWith(
    ReplenishmentSummary value,
    $Res Function(ReplenishmentSummary) then,
  ) = _$ReplenishmentSummaryCopyWithImpl<$Res, ReplenishmentSummary>;
  @useResult
  $Res call({
    @JsonKey(name: 'items_below_cover') int itemsBelowCover,
    @JsonKey(name: 'total_suggested') double totalSuggested,
    @JsonKey(name: 'total_send_now') double totalSendNow,
    @JsonKey(name: 'negative_bins') int negativeBins,
    int branches,
    @JsonKey(name: 'total_short_by') double totalShortBy,
  });
}

/// @nodoc
class _$ReplenishmentSummaryCopyWithImpl<
  $Res,
  $Val extends ReplenishmentSummary
>
    implements $ReplenishmentSummaryCopyWith<$Res> {
  _$ReplenishmentSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReplenishmentSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemsBelowCover = null,
    Object? totalSuggested = null,
    Object? totalSendNow = null,
    Object? negativeBins = null,
    Object? branches = null,
    Object? totalShortBy = null,
  }) {
    return _then(
      _value.copyWith(
            itemsBelowCover: null == itemsBelowCover
                ? _value.itemsBelowCover
                : itemsBelowCover // ignore: cast_nullable_to_non_nullable
                      as int,
            totalSuggested: null == totalSuggested
                ? _value.totalSuggested
                : totalSuggested // ignore: cast_nullable_to_non_nullable
                      as double,
            totalSendNow: null == totalSendNow
                ? _value.totalSendNow
                : totalSendNow // ignore: cast_nullable_to_non_nullable
                      as double,
            negativeBins: null == negativeBins
                ? _value.negativeBins
                : negativeBins // ignore: cast_nullable_to_non_nullable
                      as int,
            branches: null == branches
                ? _value.branches
                : branches // ignore: cast_nullable_to_non_nullable
                      as int,
            totalShortBy: null == totalShortBy
                ? _value.totalShortBy
                : totalShortBy // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReplenishmentSummaryImplCopyWith<$Res>
    implements $ReplenishmentSummaryCopyWith<$Res> {
  factory _$$ReplenishmentSummaryImplCopyWith(
    _$ReplenishmentSummaryImpl value,
    $Res Function(_$ReplenishmentSummaryImpl) then,
  ) = __$$ReplenishmentSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'items_below_cover') int itemsBelowCover,
    @JsonKey(name: 'total_suggested') double totalSuggested,
    @JsonKey(name: 'total_send_now') double totalSendNow,
    @JsonKey(name: 'negative_bins') int negativeBins,
    int branches,
    @JsonKey(name: 'total_short_by') double totalShortBy,
  });
}

/// @nodoc
class __$$ReplenishmentSummaryImplCopyWithImpl<$Res>
    extends _$ReplenishmentSummaryCopyWithImpl<$Res, _$ReplenishmentSummaryImpl>
    implements _$$ReplenishmentSummaryImplCopyWith<$Res> {
  __$$ReplenishmentSummaryImplCopyWithImpl(
    _$ReplenishmentSummaryImpl _value,
    $Res Function(_$ReplenishmentSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReplenishmentSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemsBelowCover = null,
    Object? totalSuggested = null,
    Object? totalSendNow = null,
    Object? negativeBins = null,
    Object? branches = null,
    Object? totalShortBy = null,
  }) {
    return _then(
      _$ReplenishmentSummaryImpl(
        itemsBelowCover: null == itemsBelowCover
            ? _value.itemsBelowCover
            : itemsBelowCover // ignore: cast_nullable_to_non_nullable
                  as int,
        totalSuggested: null == totalSuggested
            ? _value.totalSuggested
            : totalSuggested // ignore: cast_nullable_to_non_nullable
                  as double,
        totalSendNow: null == totalSendNow
            ? _value.totalSendNow
            : totalSendNow // ignore: cast_nullable_to_non_nullable
                  as double,
        negativeBins: null == negativeBins
            ? _value.negativeBins
            : negativeBins // ignore: cast_nullable_to_non_nullable
                  as int,
        branches: null == branches
            ? _value.branches
            : branches // ignore: cast_nullable_to_non_nullable
                  as int,
        totalShortBy: null == totalShortBy
            ? _value.totalShortBy
            : totalShortBy // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReplenishmentSummaryImpl implements _ReplenishmentSummary {
  const _$ReplenishmentSummaryImpl({
    @JsonKey(name: 'items_below_cover') this.itemsBelowCover = 0,
    @JsonKey(name: 'total_suggested') this.totalSuggested = 0.0,
    @JsonKey(name: 'total_send_now') this.totalSendNow = 0.0,
    @JsonKey(name: 'negative_bins') this.negativeBins = 0,
    this.branches = 0,
    @JsonKey(name: 'total_short_by') this.totalShortBy = 0.0,
  });

  factory _$ReplenishmentSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReplenishmentSummaryImplFromJson(json);

  @override
  @JsonKey(name: 'items_below_cover')
  final int itemsBelowCover;
  @override
  @JsonKey(name: 'total_suggested')
  final double totalSuggested;
  @override
  @JsonKey(name: 'total_send_now')
  final double totalSendNow;
  @override
  @JsonKey(name: 'negative_bins')
  final int negativeBins;
  @override
  @JsonKey()
  final int branches;
  @override
  @JsonKey(name: 'total_short_by')
  final double totalShortBy;

  @override
  String toString() {
    return 'ReplenishmentSummary(itemsBelowCover: $itemsBelowCover, totalSuggested: $totalSuggested, totalSendNow: $totalSendNow, negativeBins: $negativeBins, branches: $branches, totalShortBy: $totalShortBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReplenishmentSummaryImpl &&
            (identical(other.itemsBelowCover, itemsBelowCover) ||
                other.itemsBelowCover == itemsBelowCover) &&
            (identical(other.totalSuggested, totalSuggested) ||
                other.totalSuggested == totalSuggested) &&
            (identical(other.totalSendNow, totalSendNow) ||
                other.totalSendNow == totalSendNow) &&
            (identical(other.negativeBins, negativeBins) ||
                other.negativeBins == negativeBins) &&
            (identical(other.branches, branches) ||
                other.branches == branches) &&
            (identical(other.totalShortBy, totalShortBy) ||
                other.totalShortBy == totalShortBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    itemsBelowCover,
    totalSuggested,
    totalSendNow,
    negativeBins,
    branches,
    totalShortBy,
  );

  /// Create a copy of ReplenishmentSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReplenishmentSummaryImplCopyWith<_$ReplenishmentSummaryImpl>
  get copyWith =>
      __$$ReplenishmentSummaryImplCopyWithImpl<_$ReplenishmentSummaryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ReplenishmentSummaryImplToJson(this);
  }
}

abstract class _ReplenishmentSummary implements ReplenishmentSummary {
  const factory _ReplenishmentSummary({
    @JsonKey(name: 'items_below_cover') final int itemsBelowCover,
    @JsonKey(name: 'total_suggested') final double totalSuggested,
    @JsonKey(name: 'total_send_now') final double totalSendNow,
    @JsonKey(name: 'negative_bins') final int negativeBins,
    final int branches,
    @JsonKey(name: 'total_short_by') final double totalShortBy,
  }) = _$ReplenishmentSummaryImpl;

  factory _ReplenishmentSummary.fromJson(Map<String, dynamic> json) =
      _$ReplenishmentSummaryImpl.fromJson;

  @override
  @JsonKey(name: 'items_below_cover')
  int get itemsBelowCover;
  @override
  @JsonKey(name: 'total_suggested')
  double get totalSuggested;
  @override
  @JsonKey(name: 'total_send_now')
  double get totalSendNow;
  @override
  @JsonKey(name: 'negative_bins')
  int get negativeBins;
  @override
  int get branches;
  @override
  @JsonKey(name: 'total_short_by')
  double get totalShortBy;

  /// Create a copy of ReplenishmentSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReplenishmentSummaryImplCopyWith<_$ReplenishmentSummaryImpl>
  get copyWith => throw _privateConstructorUsedError;
}

ReplenishmentSource _$ReplenishmentSourceFromJson(Map<String, dynamic> json) {
  return _ReplenishmentSource.fromJson(json);
}

/// @nodoc
mixin _$ReplenishmentSource {
  String get warehouse => throw _privateConstructorUsedError;
  Map<String, double> get available => throw _privateConstructorUsedError;

  /// Serializes this ReplenishmentSource to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReplenishmentSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReplenishmentSourceCopyWith<ReplenishmentSource> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReplenishmentSourceCopyWith<$Res> {
  factory $ReplenishmentSourceCopyWith(
    ReplenishmentSource value,
    $Res Function(ReplenishmentSource) then,
  ) = _$ReplenishmentSourceCopyWithImpl<$Res, ReplenishmentSource>;
  @useResult
  $Res call({String warehouse, Map<String, double> available});
}

/// @nodoc
class _$ReplenishmentSourceCopyWithImpl<$Res, $Val extends ReplenishmentSource>
    implements $ReplenishmentSourceCopyWith<$Res> {
  _$ReplenishmentSourceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReplenishmentSource
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? warehouse = null, Object? available = null}) {
    return _then(
      _value.copyWith(
            warehouse: null == warehouse
                ? _value.warehouse
                : warehouse // ignore: cast_nullable_to_non_nullable
                      as String,
            available: null == available
                ? _value.available
                : available // ignore: cast_nullable_to_non_nullable
                      as Map<String, double>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReplenishmentSourceImplCopyWith<$Res>
    implements $ReplenishmentSourceCopyWith<$Res> {
  factory _$$ReplenishmentSourceImplCopyWith(
    _$ReplenishmentSourceImpl value,
    $Res Function(_$ReplenishmentSourceImpl) then,
  ) = __$$ReplenishmentSourceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String warehouse, Map<String, double> available});
}

/// @nodoc
class __$$ReplenishmentSourceImplCopyWithImpl<$Res>
    extends _$ReplenishmentSourceCopyWithImpl<$Res, _$ReplenishmentSourceImpl>
    implements _$$ReplenishmentSourceImplCopyWith<$Res> {
  __$$ReplenishmentSourceImplCopyWithImpl(
    _$ReplenishmentSourceImpl _value,
    $Res Function(_$ReplenishmentSourceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReplenishmentSource
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? warehouse = null, Object? available = null}) {
    return _then(
      _$ReplenishmentSourceImpl(
        warehouse: null == warehouse
            ? _value.warehouse
            : warehouse // ignore: cast_nullable_to_non_nullable
                  as String,
        available: null == available
            ? _value._available
            : available // ignore: cast_nullable_to_non_nullable
                  as Map<String, double>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReplenishmentSourceImpl implements _ReplenishmentSource {
  const _$ReplenishmentSourceImpl({
    this.warehouse = '',
    final Map<String, double> available = const <String, double>{},
  }) : _available = available;

  factory _$ReplenishmentSourceImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReplenishmentSourceImplFromJson(json);

  @override
  @JsonKey()
  final String warehouse;
  final Map<String, double> _available;
  @override
  @JsonKey()
  Map<String, double> get available {
    if (_available is EqualUnmodifiableMapView) return _available;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_available);
  }

  @override
  String toString() {
    return 'ReplenishmentSource(warehouse: $warehouse, available: $available)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReplenishmentSourceImpl &&
            (identical(other.warehouse, warehouse) ||
                other.warehouse == warehouse) &&
            const DeepCollectionEquality().equals(
              other._available,
              _available,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    warehouse,
    const DeepCollectionEquality().hash(_available),
  );

  /// Create a copy of ReplenishmentSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReplenishmentSourceImplCopyWith<_$ReplenishmentSourceImpl> get copyWith =>
      __$$ReplenishmentSourceImplCopyWithImpl<_$ReplenishmentSourceImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ReplenishmentSourceImplToJson(this);
  }
}

abstract class _ReplenishmentSource implements ReplenishmentSource {
  const factory _ReplenishmentSource({
    final String warehouse,
    final Map<String, double> available,
  }) = _$ReplenishmentSourceImpl;

  factory _ReplenishmentSource.fromJson(Map<String, dynamic> json) =
      _$ReplenishmentSourceImpl.fromJson;

  @override
  String get warehouse;
  @override
  Map<String, double> get available;

  /// Create a copy of ReplenishmentSource
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReplenishmentSourceImplCopyWith<_$ReplenishmentSourceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReplenishmentBranch _$ReplenishmentBranchFromJson(Map<String, dynamic> json) {
  return _ReplenishmentBranch.fromJson(json);
}

/// @nodoc
mixin _$ReplenishmentBranch {
  String get warehouse => throw _privateConstructorUsedError;
  String get branch => throw _privateConstructorUsedError;
  List<ReplenishmentItem> get items => throw _privateConstructorUsedError;
  ReplenishmentSummary get summary => throw _privateConstructorUsedError;

  /// Serializes this ReplenishmentBranch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReplenishmentBranch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReplenishmentBranchCopyWith<ReplenishmentBranch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReplenishmentBranchCopyWith<$Res> {
  factory $ReplenishmentBranchCopyWith(
    ReplenishmentBranch value,
    $Res Function(ReplenishmentBranch) then,
  ) = _$ReplenishmentBranchCopyWithImpl<$Res, ReplenishmentBranch>;
  @useResult
  $Res call({
    String warehouse,
    String branch,
    List<ReplenishmentItem> items,
    ReplenishmentSummary summary,
  });

  $ReplenishmentSummaryCopyWith<$Res> get summary;
}

/// @nodoc
class _$ReplenishmentBranchCopyWithImpl<$Res, $Val extends ReplenishmentBranch>
    implements $ReplenishmentBranchCopyWith<$Res> {
  _$ReplenishmentBranchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReplenishmentBranch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? warehouse = null,
    Object? branch = null,
    Object? items = null,
    Object? summary = null,
  }) {
    return _then(
      _value.copyWith(
            warehouse: null == warehouse
                ? _value.warehouse
                : warehouse // ignore: cast_nullable_to_non_nullable
                      as String,
            branch: null == branch
                ? _value.branch
                : branch // ignore: cast_nullable_to_non_nullable
                      as String,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<ReplenishmentItem>,
            summary: null == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                      as ReplenishmentSummary,
          )
          as $Val,
    );
  }

  /// Create a copy of ReplenishmentBranch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReplenishmentSummaryCopyWith<$Res> get summary {
    return $ReplenishmentSummaryCopyWith<$Res>(_value.summary, (value) {
      return _then(_value.copyWith(summary: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ReplenishmentBranchImplCopyWith<$Res>
    implements $ReplenishmentBranchCopyWith<$Res> {
  factory _$$ReplenishmentBranchImplCopyWith(
    _$ReplenishmentBranchImpl value,
    $Res Function(_$ReplenishmentBranchImpl) then,
  ) = __$$ReplenishmentBranchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String warehouse,
    String branch,
    List<ReplenishmentItem> items,
    ReplenishmentSummary summary,
  });

  @override
  $ReplenishmentSummaryCopyWith<$Res> get summary;
}

/// @nodoc
class __$$ReplenishmentBranchImplCopyWithImpl<$Res>
    extends _$ReplenishmentBranchCopyWithImpl<$Res, _$ReplenishmentBranchImpl>
    implements _$$ReplenishmentBranchImplCopyWith<$Res> {
  __$$ReplenishmentBranchImplCopyWithImpl(
    _$ReplenishmentBranchImpl _value,
    $Res Function(_$ReplenishmentBranchImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReplenishmentBranch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? warehouse = null,
    Object? branch = null,
    Object? items = null,
    Object? summary = null,
  }) {
    return _then(
      _$ReplenishmentBranchImpl(
        warehouse: null == warehouse
            ? _value.warehouse
            : warehouse // ignore: cast_nullable_to_non_nullable
                  as String,
        branch: null == branch
            ? _value.branch
            : branch // ignore: cast_nullable_to_non_nullable
                  as String,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<ReplenishmentItem>,
        summary: null == summary
            ? _value.summary
            : summary // ignore: cast_nullable_to_non_nullable
                  as ReplenishmentSummary,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReplenishmentBranchImpl extends _ReplenishmentBranch {
  const _$ReplenishmentBranchImpl({
    this.warehouse = '',
    this.branch = '',
    final List<ReplenishmentItem> items = const <ReplenishmentItem>[],
    this.summary = const ReplenishmentSummary(),
  }) : _items = items,
       super._();

  factory _$ReplenishmentBranchImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReplenishmentBranchImplFromJson(json);

  @override
  @JsonKey()
  final String warehouse;
  @override
  @JsonKey()
  final String branch;
  final List<ReplenishmentItem> _items;
  @override
  @JsonKey()
  List<ReplenishmentItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey()
  final ReplenishmentSummary summary;

  @override
  String toString() {
    return 'ReplenishmentBranch(warehouse: $warehouse, branch: $branch, items: $items, summary: $summary)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReplenishmentBranchImpl &&
            (identical(other.warehouse, warehouse) ||
                other.warehouse == warehouse) &&
            (identical(other.branch, branch) || other.branch == branch) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.summary, summary) || other.summary == summary));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    warehouse,
    branch,
    const DeepCollectionEquality().hash(_items),
    summary,
  );

  /// Create a copy of ReplenishmentBranch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReplenishmentBranchImplCopyWith<_$ReplenishmentBranchImpl> get copyWith =>
      __$$ReplenishmentBranchImplCopyWithImpl<_$ReplenishmentBranchImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ReplenishmentBranchImplToJson(this);
  }
}

abstract class _ReplenishmentBranch extends ReplenishmentBranch {
  const factory _ReplenishmentBranch({
    final String warehouse,
    final String branch,
    final List<ReplenishmentItem> items,
    final ReplenishmentSummary summary,
  }) = _$ReplenishmentBranchImpl;
  const _ReplenishmentBranch._() : super._();

  factory _ReplenishmentBranch.fromJson(Map<String, dynamic> json) =
      _$ReplenishmentBranchImpl.fromJson;

  @override
  String get warehouse;
  @override
  String get branch;
  @override
  List<ReplenishmentItem> get items;
  @override
  ReplenishmentSummary get summary;

  /// Create a copy of ReplenishmentBranch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReplenishmentBranchImplCopyWith<_$ReplenishmentBranchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReplenishmentPlan _$ReplenishmentPlanFromJson(Map<String, dynamic> json) {
  return _ReplenishmentPlan.fromJson(json);
}

/// @nodoc
mixin _$ReplenishmentPlan {
  @JsonKey(name: 'generated_on')
  String get generatedOn => throw _privateConstructorUsedError;
  String get company => throw _privateConstructorUsedError;
  @JsonKey(name: 'cover_days')
  int get coverDays => throw _privateConstructorUsedError;
  @JsonKey(name: 'sales_days')
  int get salesDays => throw _privateConstructorUsedError;

  /// Non-null with a reason whenever the payload is empty. The screen shows
  /// it verbatim, because "no rows" without a why is the state that made
  /// people stop trusting this kind of screen.
  String? get notice => throw _privateConstructorUsedError;
  ReplenishmentSource get source => throw _privateConstructorUsedError;
  List<ReplenishmentBranch> get branches => throw _privateConstructorUsedError;
  ReplenishmentSummary get summary => throw _privateConstructorUsedError;

  /// Suggested moves between branches; empty on older servers.
  @JsonKey(name: 'branch_moves')
  List<ReplenishmentBranchMove> get branchMoves =>
      throw _privateConstructorUsedError;

  /// Serializes this ReplenishmentPlan to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReplenishmentPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReplenishmentPlanCopyWith<ReplenishmentPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReplenishmentPlanCopyWith<$Res> {
  factory $ReplenishmentPlanCopyWith(
    ReplenishmentPlan value,
    $Res Function(ReplenishmentPlan) then,
  ) = _$ReplenishmentPlanCopyWithImpl<$Res, ReplenishmentPlan>;
  @useResult
  $Res call({
    @JsonKey(name: 'generated_on') String generatedOn,
    String company,
    @JsonKey(name: 'cover_days') int coverDays,
    @JsonKey(name: 'sales_days') int salesDays,
    String? notice,
    ReplenishmentSource source,
    List<ReplenishmentBranch> branches,
    ReplenishmentSummary summary,
    @JsonKey(name: 'branch_moves') List<ReplenishmentBranchMove> branchMoves,
  });

  $ReplenishmentSourceCopyWith<$Res> get source;
  $ReplenishmentSummaryCopyWith<$Res> get summary;
}

/// @nodoc
class _$ReplenishmentPlanCopyWithImpl<$Res, $Val extends ReplenishmentPlan>
    implements $ReplenishmentPlanCopyWith<$Res> {
  _$ReplenishmentPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReplenishmentPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? generatedOn = null,
    Object? company = null,
    Object? coverDays = null,
    Object? salesDays = null,
    Object? notice = freezed,
    Object? source = null,
    Object? branches = null,
    Object? summary = null,
    Object? branchMoves = null,
  }) {
    return _then(
      _value.copyWith(
            generatedOn: null == generatedOn
                ? _value.generatedOn
                : generatedOn // ignore: cast_nullable_to_non_nullable
                      as String,
            company: null == company
                ? _value.company
                : company // ignore: cast_nullable_to_non_nullable
                      as String,
            coverDays: null == coverDays
                ? _value.coverDays
                : coverDays // ignore: cast_nullable_to_non_nullable
                      as int,
            salesDays: null == salesDays
                ? _value.salesDays
                : salesDays // ignore: cast_nullable_to_non_nullable
                      as int,
            notice: freezed == notice
                ? _value.notice
                : notice // ignore: cast_nullable_to_non_nullable
                      as String?,
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as ReplenishmentSource,
            branches: null == branches
                ? _value.branches
                : branches // ignore: cast_nullable_to_non_nullable
                      as List<ReplenishmentBranch>,
            summary: null == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                      as ReplenishmentSummary,
            branchMoves: null == branchMoves
                ? _value.branchMoves
                : branchMoves // ignore: cast_nullable_to_non_nullable
                      as List<ReplenishmentBranchMove>,
          )
          as $Val,
    );
  }

  /// Create a copy of ReplenishmentPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReplenishmentSourceCopyWith<$Res> get source {
    return $ReplenishmentSourceCopyWith<$Res>(_value.source, (value) {
      return _then(_value.copyWith(source: value) as $Val);
    });
  }

  /// Create a copy of ReplenishmentPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReplenishmentSummaryCopyWith<$Res> get summary {
    return $ReplenishmentSummaryCopyWith<$Res>(_value.summary, (value) {
      return _then(_value.copyWith(summary: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ReplenishmentPlanImplCopyWith<$Res>
    implements $ReplenishmentPlanCopyWith<$Res> {
  factory _$$ReplenishmentPlanImplCopyWith(
    _$ReplenishmentPlanImpl value,
    $Res Function(_$ReplenishmentPlanImpl) then,
  ) = __$$ReplenishmentPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'generated_on') String generatedOn,
    String company,
    @JsonKey(name: 'cover_days') int coverDays,
    @JsonKey(name: 'sales_days') int salesDays,
    String? notice,
    ReplenishmentSource source,
    List<ReplenishmentBranch> branches,
    ReplenishmentSummary summary,
    @JsonKey(name: 'branch_moves') List<ReplenishmentBranchMove> branchMoves,
  });

  @override
  $ReplenishmentSourceCopyWith<$Res> get source;
  @override
  $ReplenishmentSummaryCopyWith<$Res> get summary;
}

/// @nodoc
class __$$ReplenishmentPlanImplCopyWithImpl<$Res>
    extends _$ReplenishmentPlanCopyWithImpl<$Res, _$ReplenishmentPlanImpl>
    implements _$$ReplenishmentPlanImplCopyWith<$Res> {
  __$$ReplenishmentPlanImplCopyWithImpl(
    _$ReplenishmentPlanImpl _value,
    $Res Function(_$ReplenishmentPlanImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReplenishmentPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? generatedOn = null,
    Object? company = null,
    Object? coverDays = null,
    Object? salesDays = null,
    Object? notice = freezed,
    Object? source = null,
    Object? branches = null,
    Object? summary = null,
    Object? branchMoves = null,
  }) {
    return _then(
      _$ReplenishmentPlanImpl(
        generatedOn: null == generatedOn
            ? _value.generatedOn
            : generatedOn // ignore: cast_nullable_to_non_nullable
                  as String,
        company: null == company
            ? _value.company
            : company // ignore: cast_nullable_to_non_nullable
                  as String,
        coverDays: null == coverDays
            ? _value.coverDays
            : coverDays // ignore: cast_nullable_to_non_nullable
                  as int,
        salesDays: null == salesDays
            ? _value.salesDays
            : salesDays // ignore: cast_nullable_to_non_nullable
                  as int,
        notice: freezed == notice
            ? _value.notice
            : notice // ignore: cast_nullable_to_non_nullable
                  as String?,
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as ReplenishmentSource,
        branches: null == branches
            ? _value._branches
            : branches // ignore: cast_nullable_to_non_nullable
                  as List<ReplenishmentBranch>,
        summary: null == summary
            ? _value.summary
            : summary // ignore: cast_nullable_to_non_nullable
                  as ReplenishmentSummary,
        branchMoves: null == branchMoves
            ? _value._branchMoves
            : branchMoves // ignore: cast_nullable_to_non_nullable
                  as List<ReplenishmentBranchMove>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReplenishmentPlanImpl extends _ReplenishmentPlan {
  const _$ReplenishmentPlanImpl({
    @JsonKey(name: 'generated_on') this.generatedOn = '',
    this.company = '',
    @JsonKey(name: 'cover_days') this.coverDays = 0,
    @JsonKey(name: 'sales_days') this.salesDays = 0,
    this.notice,
    this.source = const ReplenishmentSource(),
    final List<ReplenishmentBranch> branches = const <ReplenishmentBranch>[],
    this.summary = const ReplenishmentSummary(),
    @JsonKey(name: 'branch_moves')
    final List<ReplenishmentBranchMove> branchMoves =
        const <ReplenishmentBranchMove>[],
  }) : _branches = branches,
       _branchMoves = branchMoves,
       super._();

  factory _$ReplenishmentPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReplenishmentPlanImplFromJson(json);

  @override
  @JsonKey(name: 'generated_on')
  final String generatedOn;
  @override
  @JsonKey()
  final String company;
  @override
  @JsonKey(name: 'cover_days')
  final int coverDays;
  @override
  @JsonKey(name: 'sales_days')
  final int salesDays;

  /// Non-null with a reason whenever the payload is empty. The screen shows
  /// it verbatim, because "no rows" without a why is the state that made
  /// people stop trusting this kind of screen.
  @override
  final String? notice;
  @override
  @JsonKey()
  final ReplenishmentSource source;
  final List<ReplenishmentBranch> _branches;
  @override
  @JsonKey()
  List<ReplenishmentBranch> get branches {
    if (_branches is EqualUnmodifiableListView) return _branches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_branches);
  }

  @override
  @JsonKey()
  final ReplenishmentSummary summary;

  /// Suggested moves between branches; empty on older servers.
  final List<ReplenishmentBranchMove> _branchMoves;

  /// Suggested moves between branches; empty on older servers.
  @override
  @JsonKey(name: 'branch_moves')
  List<ReplenishmentBranchMove> get branchMoves {
    if (_branchMoves is EqualUnmodifiableListView) return _branchMoves;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_branchMoves);
  }

  @override
  String toString() {
    return 'ReplenishmentPlan(generatedOn: $generatedOn, company: $company, coverDays: $coverDays, salesDays: $salesDays, notice: $notice, source: $source, branches: $branches, summary: $summary, branchMoves: $branchMoves)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReplenishmentPlanImpl &&
            (identical(other.generatedOn, generatedOn) ||
                other.generatedOn == generatedOn) &&
            (identical(other.company, company) || other.company == company) &&
            (identical(other.coverDays, coverDays) ||
                other.coverDays == coverDays) &&
            (identical(other.salesDays, salesDays) ||
                other.salesDays == salesDays) &&
            (identical(other.notice, notice) || other.notice == notice) &&
            (identical(other.source, source) || other.source == source) &&
            const DeepCollectionEquality().equals(other._branches, _branches) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            const DeepCollectionEquality().equals(
              other._branchMoves,
              _branchMoves,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    generatedOn,
    company,
    coverDays,
    salesDays,
    notice,
    source,
    const DeepCollectionEquality().hash(_branches),
    summary,
    const DeepCollectionEquality().hash(_branchMoves),
  );

  /// Create a copy of ReplenishmentPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReplenishmentPlanImplCopyWith<_$ReplenishmentPlanImpl> get copyWith =>
      __$$ReplenishmentPlanImplCopyWithImpl<_$ReplenishmentPlanImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ReplenishmentPlanImplToJson(this);
  }
}

abstract class _ReplenishmentPlan extends ReplenishmentPlan {
  const factory _ReplenishmentPlan({
    @JsonKey(name: 'generated_on') final String generatedOn,
    final String company,
    @JsonKey(name: 'cover_days') final int coverDays,
    @JsonKey(name: 'sales_days') final int salesDays,
    final String? notice,
    final ReplenishmentSource source,
    final List<ReplenishmentBranch> branches,
    final ReplenishmentSummary summary,
    @JsonKey(name: 'branch_moves')
    final List<ReplenishmentBranchMove> branchMoves,
  }) = _$ReplenishmentPlanImpl;
  const _ReplenishmentPlan._() : super._();

  factory _ReplenishmentPlan.fromJson(Map<String, dynamic> json) =
      _$ReplenishmentPlanImpl.fromJson;

  @override
  @JsonKey(name: 'generated_on')
  String get generatedOn;
  @override
  String get company;
  @override
  @JsonKey(name: 'cover_days')
  int get coverDays;
  @override
  @JsonKey(name: 'sales_days')
  int get salesDays;

  /// Non-null with a reason whenever the payload is empty. The screen shows
  /// it verbatim, because "no rows" without a why is the state that made
  /// people stop trusting this kind of screen.
  @override
  String? get notice;
  @override
  ReplenishmentSource get source;
  @override
  List<ReplenishmentBranch> get branches;
  @override
  ReplenishmentSummary get summary;

  /// Suggested moves between branches; empty on older servers.
  @override
  @JsonKey(name: 'branch_moves')
  List<ReplenishmentBranchMove> get branchMoves;

  /// Create a copy of ReplenishmentPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReplenishmentPlanImplCopyWith<_$ReplenishmentPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
