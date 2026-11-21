// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'price_sheet.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PriceSheetPage _$PriceSheetPageFromJson(Map<String, dynamic> json) {
  return _PriceSheetPage.fromJson(json);
}

/// @nodoc
mixin _$PriceSheetPage {
  String get thumb => throw _privateConstructorUsedError;
  String get screen => throw _privateConstructorUsedError;
  String get full => throw _privateConstructorUsedError;
  @_IntConverter()
  int get w => throw _privateConstructorUsedError;
  @_IntConverter()
  int get h => throw _privateConstructorUsedError;

  /// Serializes this PriceSheetPage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PriceSheetPage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PriceSheetPageCopyWith<PriceSheetPage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PriceSheetPageCopyWith<$Res> {
  factory $PriceSheetPageCopyWith(
    PriceSheetPage value,
    $Res Function(PriceSheetPage) then,
  ) = _$PriceSheetPageCopyWithImpl<$Res, PriceSheetPage>;
  @useResult
  $Res call({
    String thumb,
    String screen,
    String full,
    @_IntConverter() int w,
    @_IntConverter() int h,
  });
}

/// @nodoc
class _$PriceSheetPageCopyWithImpl<$Res, $Val extends PriceSheetPage>
    implements $PriceSheetPageCopyWith<$Res> {
  _$PriceSheetPageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PriceSheetPage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? thumb = null,
    Object? screen = null,
    Object? full = null,
    Object? w = null,
    Object? h = null,
  }) {
    return _then(
      _value.copyWith(
            thumb: null == thumb
                ? _value.thumb
                : thumb // ignore: cast_nullable_to_non_nullable
                      as String,
            screen: null == screen
                ? _value.screen
                : screen // ignore: cast_nullable_to_non_nullable
                      as String,
            full: null == full
                ? _value.full
                : full // ignore: cast_nullable_to_non_nullable
                      as String,
            w: null == w
                ? _value.w
                : w // ignore: cast_nullable_to_non_nullable
                      as int,
            h: null == h
                ? _value.h
                : h // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PriceSheetPageImplCopyWith<$Res>
    implements $PriceSheetPageCopyWith<$Res> {
  factory _$$PriceSheetPageImplCopyWith(
    _$PriceSheetPageImpl value,
    $Res Function(_$PriceSheetPageImpl) then,
  ) = __$$PriceSheetPageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String thumb,
    String screen,
    String full,
    @_IntConverter() int w,
    @_IntConverter() int h,
  });
}

/// @nodoc
class __$$PriceSheetPageImplCopyWithImpl<$Res>
    extends _$PriceSheetPageCopyWithImpl<$Res, _$PriceSheetPageImpl>
    implements _$$PriceSheetPageImplCopyWith<$Res> {
  __$$PriceSheetPageImplCopyWithImpl(
    _$PriceSheetPageImpl _value,
    $Res Function(_$PriceSheetPageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PriceSheetPage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? thumb = null,
    Object? screen = null,
    Object? full = null,
    Object? w = null,
    Object? h = null,
  }) {
    return _then(
      _$PriceSheetPageImpl(
        thumb: null == thumb
            ? _value.thumb
            : thumb // ignore: cast_nullable_to_non_nullable
                  as String,
        screen: null == screen
            ? _value.screen
            : screen // ignore: cast_nullable_to_non_nullable
                  as String,
        full: null == full
            ? _value.full
            : full // ignore: cast_nullable_to_non_nullable
                  as String,
        w: null == w
            ? _value.w
            : w // ignore: cast_nullable_to_non_nullable
                  as int,
        h: null == h
            ? _value.h
            : h // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PriceSheetPageImpl extends _PriceSheetPage {
  const _$PriceSheetPageImpl({
    this.thumb = '',
    this.screen = '',
    this.full = '',
    @_IntConverter() this.w = 0,
    @_IntConverter() this.h = 0,
  }) : super._();

  factory _$PriceSheetPageImpl.fromJson(Map<String, dynamic> json) =>
      _$$PriceSheetPageImplFromJson(json);

  @override
  @JsonKey()
  final String thumb;
  @override
  @JsonKey()
  final String screen;
  @override
  @JsonKey()
  final String full;
  @override
  @JsonKey()
  @_IntConverter()
  final int w;
  @override
  @JsonKey()
  @_IntConverter()
  final int h;

  @override
  String toString() {
    return 'PriceSheetPage(thumb: $thumb, screen: $screen, full: $full, w: $w, h: $h)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PriceSheetPageImpl &&
            (identical(other.thumb, thumb) || other.thumb == thumb) &&
            (identical(other.screen, screen) || other.screen == screen) &&
            (identical(other.full, full) || other.full == full) &&
            (identical(other.w, w) || other.w == w) &&
            (identical(other.h, h) || other.h == h));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, thumb, screen, full, w, h);

  /// Create a copy of PriceSheetPage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PriceSheetPageImplCopyWith<_$PriceSheetPageImpl> get copyWith =>
      __$$PriceSheetPageImplCopyWithImpl<_$PriceSheetPageImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PriceSheetPageImplToJson(this);
  }
}

abstract class _PriceSheetPage extends PriceSheetPage {
  const factory _PriceSheetPage({
    final String thumb,
    final String screen,
    final String full,
    @_IntConverter() final int w,
    @_IntConverter() final int h,
  }) = _$PriceSheetPageImpl;
  const _PriceSheetPage._() : super._();

  factory _PriceSheetPage.fromJson(Map<String, dynamic> json) =
      _$PriceSheetPageImpl.fromJson;

  @override
  String get thumb;
  @override
  String get screen;
  @override
  String get full;
  @override
  @_IntConverter()
  int get w;
  @override
  @_IntConverter()
  int get h;

  /// Create a copy of PriceSheetPage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PriceSheetPageImplCopyWith<_$PriceSheetPageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PriceSheetCell _$PriceSheetCellFromJson(Map<String, dynamic> json) {
  return _PriceSheetCell.fromJson(json);
}

/// @nodoc
mixin _$PriceSheetCell {
  String get size => throw _privateConstructorUsedError;

  /// Null when the item does not exist or has no price for this customer;
  /// the sheet prints a dash.
  @_NullableDoubleConverter()
  double? get rate => throw _privateConstructorUsedError;

  /// The undiscounted price, only meaningful beside a deal price.
  @JsonKey(name: 'normal_rate')
  @_NullableDoubleConverter()
  double? get normalRate => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_deal')
  @_BoolConverter()
  bool get isDeal => throw _privateConstructorUsedError;

  /// Serializes this PriceSheetCell to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PriceSheetCell
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PriceSheetCellCopyWith<PriceSheetCell> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PriceSheetCellCopyWith<$Res> {
  factory $PriceSheetCellCopyWith(
    PriceSheetCell value,
    $Res Function(PriceSheetCell) then,
  ) = _$PriceSheetCellCopyWithImpl<$Res, PriceSheetCell>;
  @useResult
  $Res call({
    String size,
    @_NullableDoubleConverter() double? rate,
    @JsonKey(name: 'normal_rate')
    @_NullableDoubleConverter()
    double? normalRate,
    @JsonKey(name: 'is_deal') @_BoolConverter() bool isDeal,
  });
}

/// @nodoc
class _$PriceSheetCellCopyWithImpl<$Res, $Val extends PriceSheetCell>
    implements $PriceSheetCellCopyWith<$Res> {
  _$PriceSheetCellCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PriceSheetCell
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? size = null,
    Object? rate = freezed,
    Object? normalRate = freezed,
    Object? isDeal = null,
  }) {
    return _then(
      _value.copyWith(
            size: null == size
                ? _value.size
                : size // ignore: cast_nullable_to_non_nullable
                      as String,
            rate: freezed == rate
                ? _value.rate
                : rate // ignore: cast_nullable_to_non_nullable
                      as double?,
            normalRate: freezed == normalRate
                ? _value.normalRate
                : normalRate // ignore: cast_nullable_to_non_nullable
                      as double?,
            isDeal: null == isDeal
                ? _value.isDeal
                : isDeal // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PriceSheetCellImplCopyWith<$Res>
    implements $PriceSheetCellCopyWith<$Res> {
  factory _$$PriceSheetCellImplCopyWith(
    _$PriceSheetCellImpl value,
    $Res Function(_$PriceSheetCellImpl) then,
  ) = __$$PriceSheetCellImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String size,
    @_NullableDoubleConverter() double? rate,
    @JsonKey(name: 'normal_rate')
    @_NullableDoubleConverter()
    double? normalRate,
    @JsonKey(name: 'is_deal') @_BoolConverter() bool isDeal,
  });
}

/// @nodoc
class __$$PriceSheetCellImplCopyWithImpl<$Res>
    extends _$PriceSheetCellCopyWithImpl<$Res, _$PriceSheetCellImpl>
    implements _$$PriceSheetCellImplCopyWith<$Res> {
  __$$PriceSheetCellImplCopyWithImpl(
    _$PriceSheetCellImpl _value,
    $Res Function(_$PriceSheetCellImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PriceSheetCell
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? size = null,
    Object? rate = freezed,
    Object? normalRate = freezed,
    Object? isDeal = null,
  }) {
    return _then(
      _$PriceSheetCellImpl(
        size: null == size
            ? _value.size
            : size // ignore: cast_nullable_to_non_nullable
                  as String,
        rate: freezed == rate
            ? _value.rate
            : rate // ignore: cast_nullable_to_non_nullable
                  as double?,
        normalRate: freezed == normalRate
            ? _value.normalRate
            : normalRate // ignore: cast_nullable_to_non_nullable
                  as double?,
        isDeal: null == isDeal
            ? _value.isDeal
            : isDeal // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PriceSheetCellImpl implements _PriceSheetCell {
  const _$PriceSheetCellImpl({
    this.size = '',
    @_NullableDoubleConverter() this.rate,
    @JsonKey(name: 'normal_rate') @_NullableDoubleConverter() this.normalRate,
    @JsonKey(name: 'is_deal') @_BoolConverter() this.isDeal = false,
  });

  factory _$PriceSheetCellImpl.fromJson(Map<String, dynamic> json) =>
      _$$PriceSheetCellImplFromJson(json);

  @override
  @JsonKey()
  final String size;

  /// Null when the item does not exist or has no price for this customer;
  /// the sheet prints a dash.
  @override
  @_NullableDoubleConverter()
  final double? rate;

  /// The undiscounted price, only meaningful beside a deal price.
  @override
  @JsonKey(name: 'normal_rate')
  @_NullableDoubleConverter()
  final double? normalRate;
  @override
  @JsonKey(name: 'is_deal')
  @_BoolConverter()
  final bool isDeal;

  @override
  String toString() {
    return 'PriceSheetCell(size: $size, rate: $rate, normalRate: $normalRate, isDeal: $isDeal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PriceSheetCellImpl &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.rate, rate) || other.rate == rate) &&
            (identical(other.normalRate, normalRate) ||
                other.normalRate == normalRate) &&
            (identical(other.isDeal, isDeal) || other.isDeal == isDeal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, size, rate, normalRate, isDeal);

  /// Create a copy of PriceSheetCell
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PriceSheetCellImplCopyWith<_$PriceSheetCellImpl> get copyWith =>
      __$$PriceSheetCellImplCopyWithImpl<_$PriceSheetCellImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PriceSheetCellImplToJson(this);
  }
}

abstract class _PriceSheetCell implements PriceSheetCell {
  const factory _PriceSheetCell({
    final String size,
    @_NullableDoubleConverter() final double? rate,
    @JsonKey(name: 'normal_rate')
    @_NullableDoubleConverter()
    final double? normalRate,
    @JsonKey(name: 'is_deal') @_BoolConverter() final bool isDeal,
  }) = _$PriceSheetCellImpl;

  factory _PriceSheetCell.fromJson(Map<String, dynamic> json) =
      _$PriceSheetCellImpl.fromJson;

  @override
  String get size;

  /// Null when the item does not exist or has no price for this customer;
  /// the sheet prints a dash.
  @override
  @_NullableDoubleConverter()
  double? get rate;

  /// The undiscounted price, only meaningful beside a deal price.
  @override
  @JsonKey(name: 'normal_rate')
  @_NullableDoubleConverter()
  double? get normalRate;
  @override
  @JsonKey(name: 'is_deal')
  @_BoolConverter()
  bool get isDeal;

  /// Create a copy of PriceSheetCell
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PriceSheetCellImplCopyWith<_$PriceSheetCellImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PriceSheetRow _$PriceSheetRowFromJson(Map<String, dynamic> json) {
  return _PriceSheetRow.fromJson(json);
}

/// @nodoc
mixin _$PriceSheetRow {
  String get flavour => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  List<PriceSheetCell> get cells => throw _privateConstructorUsedError;

  /// Serializes this PriceSheetRow to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PriceSheetRow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PriceSheetRowCopyWith<PriceSheetRow> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PriceSheetRowCopyWith<$Res> {
  factory $PriceSheetRowCopyWith(
    PriceSheetRow value,
    $Res Function(PriceSheetRow) then,
  ) = _$PriceSheetRowCopyWithImpl<$Res, PriceSheetRow>;
  @useResult
  $Res call({String flavour, String label, List<PriceSheetCell> cells});
}

/// @nodoc
class _$PriceSheetRowCopyWithImpl<$Res, $Val extends PriceSheetRow>
    implements $PriceSheetRowCopyWith<$Res> {
  _$PriceSheetRowCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PriceSheetRow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? flavour = null,
    Object? label = null,
    Object? cells = null,
  }) {
    return _then(
      _value.copyWith(
            flavour: null == flavour
                ? _value.flavour
                : flavour // ignore: cast_nullable_to_non_nullable
                      as String,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            cells: null == cells
                ? _value.cells
                : cells // ignore: cast_nullable_to_non_nullable
                      as List<PriceSheetCell>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PriceSheetRowImplCopyWith<$Res>
    implements $PriceSheetRowCopyWith<$Res> {
  factory _$$PriceSheetRowImplCopyWith(
    _$PriceSheetRowImpl value,
    $Res Function(_$PriceSheetRowImpl) then,
  ) = __$$PriceSheetRowImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String flavour, String label, List<PriceSheetCell> cells});
}

/// @nodoc
class __$$PriceSheetRowImplCopyWithImpl<$Res>
    extends _$PriceSheetRowCopyWithImpl<$Res, _$PriceSheetRowImpl>
    implements _$$PriceSheetRowImplCopyWith<$Res> {
  __$$PriceSheetRowImplCopyWithImpl(
    _$PriceSheetRowImpl _value,
    $Res Function(_$PriceSheetRowImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PriceSheetRow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? flavour = null,
    Object? label = null,
    Object? cells = null,
  }) {
    return _then(
      _$PriceSheetRowImpl(
        flavour: null == flavour
            ? _value.flavour
            : flavour // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        cells: null == cells
            ? _value._cells
            : cells // ignore: cast_nullable_to_non_nullable
                  as List<PriceSheetCell>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PriceSheetRowImpl implements _PriceSheetRow {
  const _$PriceSheetRowImpl({
    this.flavour = '',
    this.label = '',
    final List<PriceSheetCell> cells = const <PriceSheetCell>[],
  }) : _cells = cells;

  factory _$PriceSheetRowImpl.fromJson(Map<String, dynamic> json) =>
      _$$PriceSheetRowImplFromJson(json);

  @override
  @JsonKey()
  final String flavour;
  @override
  @JsonKey()
  final String label;
  final List<PriceSheetCell> _cells;
  @override
  @JsonKey()
  List<PriceSheetCell> get cells {
    if (_cells is EqualUnmodifiableListView) return _cells;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cells);
  }

  @override
  String toString() {
    return 'PriceSheetRow(flavour: $flavour, label: $label, cells: $cells)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PriceSheetRowImpl &&
            (identical(other.flavour, flavour) || other.flavour == flavour) &&
            (identical(other.label, label) || other.label == label) &&
            const DeepCollectionEquality().equals(other._cells, _cells));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    flavour,
    label,
    const DeepCollectionEquality().hash(_cells),
  );

  /// Create a copy of PriceSheetRow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PriceSheetRowImplCopyWith<_$PriceSheetRowImpl> get copyWith =>
      __$$PriceSheetRowImplCopyWithImpl<_$PriceSheetRowImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PriceSheetRowImplToJson(this);
  }
}

abstract class _PriceSheetRow implements PriceSheetRow {
  const factory _PriceSheetRow({
    final String flavour,
    final String label,
    final List<PriceSheetCell> cells,
  }) = _$PriceSheetRowImpl;

  factory _PriceSheetRow.fromJson(Map<String, dynamic> json) =
      _$PriceSheetRowImpl.fromJson;

  @override
  String get flavour;
  @override
  String get label;
  @override
  List<PriceSheetCell> get cells;

  /// Create a copy of PriceSheetRow
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PriceSheetRowImplCopyWith<_$PriceSheetRowImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PriceSheetTerm _$PriceSheetTermFromJson(Map<String, dynamic> json) {
  return _PriceSheetTerm.fromJson(json);
}

/// @nodoc
mixin _$PriceSheetTerm {
  @_NullableStringConverter()
  String? get label => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;

  /// Serializes this PriceSheetTerm to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PriceSheetTerm
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PriceSheetTermCopyWith<PriceSheetTerm> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PriceSheetTermCopyWith<$Res> {
  factory $PriceSheetTermCopyWith(
    PriceSheetTerm value,
    $Res Function(PriceSheetTerm) then,
  ) = _$PriceSheetTermCopyWithImpl<$Res, PriceSheetTerm>;
  @useResult
  $Res call({@_NullableStringConverter() String? label, String text});
}

/// @nodoc
class _$PriceSheetTermCopyWithImpl<$Res, $Val extends PriceSheetTerm>
    implements $PriceSheetTermCopyWith<$Res> {
  _$PriceSheetTermCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PriceSheetTerm
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? label = freezed, Object? text = null}) {
    return _then(
      _value.copyWith(
            label: freezed == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String?,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PriceSheetTermImplCopyWith<$Res>
    implements $PriceSheetTermCopyWith<$Res> {
  factory _$$PriceSheetTermImplCopyWith(
    _$PriceSheetTermImpl value,
    $Res Function(_$PriceSheetTermImpl) then,
  ) = __$$PriceSheetTermImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@_NullableStringConverter() String? label, String text});
}

/// @nodoc
class __$$PriceSheetTermImplCopyWithImpl<$Res>
    extends _$PriceSheetTermCopyWithImpl<$Res, _$PriceSheetTermImpl>
    implements _$$PriceSheetTermImplCopyWith<$Res> {
  __$$PriceSheetTermImplCopyWithImpl(
    _$PriceSheetTermImpl _value,
    $Res Function(_$PriceSheetTermImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PriceSheetTerm
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? label = freezed, Object? text = null}) {
    return _then(
      _$PriceSheetTermImpl(
        label: freezed == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PriceSheetTermImpl implements _PriceSheetTerm {
  const _$PriceSheetTermImpl({
    @_NullableStringConverter() this.label,
    this.text = '',
  });

  factory _$PriceSheetTermImpl.fromJson(Map<String, dynamic> json) =>
      _$$PriceSheetTermImplFromJson(json);

  @override
  @_NullableStringConverter()
  final String? label;
  @override
  @JsonKey()
  final String text;

  @override
  String toString() {
    return 'PriceSheetTerm(label: $label, text: $text)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PriceSheetTermImpl &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.text, text) || other.text == text));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, label, text);

  /// Create a copy of PriceSheetTerm
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PriceSheetTermImplCopyWith<_$PriceSheetTermImpl> get copyWith =>
      __$$PriceSheetTermImplCopyWithImpl<_$PriceSheetTermImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PriceSheetTermImplToJson(this);
  }
}

abstract class _PriceSheetTerm implements PriceSheetTerm {
  const factory _PriceSheetTerm({
    @_NullableStringConverter() final String? label,
    final String text,
  }) = _$PriceSheetTermImpl;

  factory _PriceSheetTerm.fromJson(Map<String, dynamic> json) =
      _$PriceSheetTermImpl.fromJson;

  @override
  @_NullableStringConverter()
  String? get label;
  @override
  String get text;

  /// Create a copy of PriceSheetTerm
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PriceSheetTermImplCopyWith<_$PriceSheetTermImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PriceSheetData _$PriceSheetDataFromJson(Map<String, dynamic> json) {
  return _PriceSheetData.fromJson(json);
}

/// @nodoc
mixin _$PriceSheetData {
  String get heading => throw _privateConstructorUsedError;
  @JsonKey(name: 'customer_name')
  @_NullableStringConverter()
  String? get customerName => throw _privateConstructorUsedError;
  @JsonKey(name: 'price_list')
  String get priceList => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  @JsonKey(name: 'as_of')
  String get asOf => throw _privateConstructorUsedError;
  @_StringListConverter()
  List<String> get sizes => throw _privateConstructorUsedError;
  List<PriceSheetRow> get rows => throw _privateConstructorUsedError;
  @JsonKey(name: 'deal_until')
  @_NullableStringConverter()
  String? get dealUntil => throw _privateConstructorUsedError;
  List<PriceSheetTerm> get terms => throw _privateConstructorUsedError;
  String get footer => throw _privateConstructorUsedError;

  /// Serializes this PriceSheetData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PriceSheetData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PriceSheetDataCopyWith<PriceSheetData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PriceSheetDataCopyWith<$Res> {
  factory $PriceSheetDataCopyWith(
    PriceSheetData value,
    $Res Function(PriceSheetData) then,
  ) = _$PriceSheetDataCopyWithImpl<$Res, PriceSheetData>;
  @useResult
  $Res call({
    String heading,
    @JsonKey(name: 'customer_name')
    @_NullableStringConverter()
    String? customerName,
    @JsonKey(name: 'price_list') String priceList,
    String currency,
    @JsonKey(name: 'as_of') String asOf,
    @_StringListConverter() List<String> sizes,
    List<PriceSheetRow> rows,
    @JsonKey(name: 'deal_until') @_NullableStringConverter() String? dealUntil,
    List<PriceSheetTerm> terms,
    String footer,
  });
}

/// @nodoc
class _$PriceSheetDataCopyWithImpl<$Res, $Val extends PriceSheetData>
    implements $PriceSheetDataCopyWith<$Res> {
  _$PriceSheetDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PriceSheetData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? heading = null,
    Object? customerName = freezed,
    Object? priceList = null,
    Object? currency = null,
    Object? asOf = null,
    Object? sizes = null,
    Object? rows = null,
    Object? dealUntil = freezed,
    Object? terms = null,
    Object? footer = null,
  }) {
    return _then(
      _value.copyWith(
            heading: null == heading
                ? _value.heading
                : heading // ignore: cast_nullable_to_non_nullable
                      as String,
            customerName: freezed == customerName
                ? _value.customerName
                : customerName // ignore: cast_nullable_to_non_nullable
                      as String?,
            priceList: null == priceList
                ? _value.priceList
                : priceList // ignore: cast_nullable_to_non_nullable
                      as String,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            asOf: null == asOf
                ? _value.asOf
                : asOf // ignore: cast_nullable_to_non_nullable
                      as String,
            sizes: null == sizes
                ? _value.sizes
                : sizes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            rows: null == rows
                ? _value.rows
                : rows // ignore: cast_nullable_to_non_nullable
                      as List<PriceSheetRow>,
            dealUntil: freezed == dealUntil
                ? _value.dealUntil
                : dealUntil // ignore: cast_nullable_to_non_nullable
                      as String?,
            terms: null == terms
                ? _value.terms
                : terms // ignore: cast_nullable_to_non_nullable
                      as List<PriceSheetTerm>,
            footer: null == footer
                ? _value.footer
                : footer // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PriceSheetDataImplCopyWith<$Res>
    implements $PriceSheetDataCopyWith<$Res> {
  factory _$$PriceSheetDataImplCopyWith(
    _$PriceSheetDataImpl value,
    $Res Function(_$PriceSheetDataImpl) then,
  ) = __$$PriceSheetDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String heading,
    @JsonKey(name: 'customer_name')
    @_NullableStringConverter()
    String? customerName,
    @JsonKey(name: 'price_list') String priceList,
    String currency,
    @JsonKey(name: 'as_of') String asOf,
    @_StringListConverter() List<String> sizes,
    List<PriceSheetRow> rows,
    @JsonKey(name: 'deal_until') @_NullableStringConverter() String? dealUntil,
    List<PriceSheetTerm> terms,
    String footer,
  });
}

/// @nodoc
class __$$PriceSheetDataImplCopyWithImpl<$Res>
    extends _$PriceSheetDataCopyWithImpl<$Res, _$PriceSheetDataImpl>
    implements _$$PriceSheetDataImplCopyWith<$Res> {
  __$$PriceSheetDataImplCopyWithImpl(
    _$PriceSheetDataImpl _value,
    $Res Function(_$PriceSheetDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PriceSheetData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? heading = null,
    Object? customerName = freezed,
    Object? priceList = null,
    Object? currency = null,
    Object? asOf = null,
    Object? sizes = null,
    Object? rows = null,
    Object? dealUntil = freezed,
    Object? terms = null,
    Object? footer = null,
  }) {
    return _then(
      _$PriceSheetDataImpl(
        heading: null == heading
            ? _value.heading
            : heading // ignore: cast_nullable_to_non_nullable
                  as String,
        customerName: freezed == customerName
            ? _value.customerName
            : customerName // ignore: cast_nullable_to_non_nullable
                  as String?,
        priceList: null == priceList
            ? _value.priceList
            : priceList // ignore: cast_nullable_to_non_nullable
                  as String,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        asOf: null == asOf
            ? _value.asOf
            : asOf // ignore: cast_nullable_to_non_nullable
                  as String,
        sizes: null == sizes
            ? _value._sizes
            : sizes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        rows: null == rows
            ? _value._rows
            : rows // ignore: cast_nullable_to_non_nullable
                  as List<PriceSheetRow>,
        dealUntil: freezed == dealUntil
            ? _value.dealUntil
            : dealUntil // ignore: cast_nullable_to_non_nullable
                  as String?,
        terms: null == terms
            ? _value._terms
            : terms // ignore: cast_nullable_to_non_nullable
                  as List<PriceSheetTerm>,
        footer: null == footer
            ? _value.footer
            : footer // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PriceSheetDataImpl extends _PriceSheetData {
  const _$PriceSheetDataImpl({
    this.heading = '',
    @JsonKey(name: 'customer_name')
    @_NullableStringConverter()
    this.customerName,
    @JsonKey(name: 'price_list') this.priceList = '',
    this.currency = '',
    @JsonKey(name: 'as_of') this.asOf = '',
    @_StringListConverter() final List<String> sizes = const <String>[],
    final List<PriceSheetRow> rows = const <PriceSheetRow>[],
    @JsonKey(name: 'deal_until') @_NullableStringConverter() this.dealUntil,
    final List<PriceSheetTerm> terms = const <PriceSheetTerm>[],
    this.footer = '',
  }) : _sizes = sizes,
       _rows = rows,
       _terms = terms,
       super._();

  factory _$PriceSheetDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$PriceSheetDataImplFromJson(json);

  @override
  @JsonKey()
  final String heading;
  @override
  @JsonKey(name: 'customer_name')
  @_NullableStringConverter()
  final String? customerName;
  @override
  @JsonKey(name: 'price_list')
  final String priceList;
  @override
  @JsonKey()
  final String currency;
  @override
  @JsonKey(name: 'as_of')
  final String asOf;
  final List<String> _sizes;
  @override
  @JsonKey()
  @_StringListConverter()
  List<String> get sizes {
    if (_sizes is EqualUnmodifiableListView) return _sizes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sizes);
  }

  final List<PriceSheetRow> _rows;
  @override
  @JsonKey()
  List<PriceSheetRow> get rows {
    if (_rows is EqualUnmodifiableListView) return _rows;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rows);
  }

  @override
  @JsonKey(name: 'deal_until')
  @_NullableStringConverter()
  final String? dealUntil;
  final List<PriceSheetTerm> _terms;
  @override
  @JsonKey()
  List<PriceSheetTerm> get terms {
    if (_terms is EqualUnmodifiableListView) return _terms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_terms);
  }

  @override
  @JsonKey()
  final String footer;

  @override
  String toString() {
    return 'PriceSheetData(heading: $heading, customerName: $customerName, priceList: $priceList, currency: $currency, asOf: $asOf, sizes: $sizes, rows: $rows, dealUntil: $dealUntil, terms: $terms, footer: $footer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PriceSheetDataImpl &&
            (identical(other.heading, heading) || other.heading == heading) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.priceList, priceList) ||
                other.priceList == priceList) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.asOf, asOf) || other.asOf == asOf) &&
            const DeepCollectionEquality().equals(other._sizes, _sizes) &&
            const DeepCollectionEquality().equals(other._rows, _rows) &&
            (identical(other.dealUntil, dealUntil) ||
                other.dealUntil == dealUntil) &&
            const DeepCollectionEquality().equals(other._terms, _terms) &&
            (identical(other.footer, footer) || other.footer == footer));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    heading,
    customerName,
    priceList,
    currency,
    asOf,
    const DeepCollectionEquality().hash(_sizes),
    const DeepCollectionEquality().hash(_rows),
    dealUntil,
    const DeepCollectionEquality().hash(_terms),
    footer,
  );

  /// Create a copy of PriceSheetData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PriceSheetDataImplCopyWith<_$PriceSheetDataImpl> get copyWith =>
      __$$PriceSheetDataImplCopyWithImpl<_$PriceSheetDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PriceSheetDataImplToJson(this);
  }
}

abstract class _PriceSheetData extends PriceSheetData {
  const factory _PriceSheetData({
    final String heading,
    @JsonKey(name: 'customer_name')
    @_NullableStringConverter()
    final String? customerName,
    @JsonKey(name: 'price_list') final String priceList,
    final String currency,
    @JsonKey(name: 'as_of') final String asOf,
    @_StringListConverter() final List<String> sizes,
    final List<PriceSheetRow> rows,
    @JsonKey(name: 'deal_until')
    @_NullableStringConverter()
    final String? dealUntil,
    final List<PriceSheetTerm> terms,
    final String footer,
  }) = _$PriceSheetDataImpl;
  const _PriceSheetData._() : super._();

  factory _PriceSheetData.fromJson(Map<String, dynamic> json) =
      _$PriceSheetDataImpl.fromJson;

  @override
  String get heading;
  @override
  @JsonKey(name: 'customer_name')
  @_NullableStringConverter()
  String? get customerName;
  @override
  @JsonKey(name: 'price_list')
  String get priceList;
  @override
  String get currency;
  @override
  @JsonKey(name: 'as_of')
  String get asOf;
  @override
  @_StringListConverter()
  List<String> get sizes;
  @override
  List<PriceSheetRow> get rows;
  @override
  @JsonKey(name: 'deal_until')
  @_NullableStringConverter()
  String? get dealUntil;
  @override
  List<PriceSheetTerm> get terms;
  @override
  String get footer;

  /// Create a copy of PriceSheetData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PriceSheetDataImplCopyWith<_$PriceSheetDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PriceSheetPreview _$PriceSheetPreviewFromJson(Map<String, dynamic> json) {
  return _PriceSheetPreview.fromJson(json);
}

/// @nodoc
mixin _$PriceSheetPreview {
  @JsonKey(name: 'pdf_url')
  String get pdfUrl => throw _privateConstructorUsedError;
  List<PriceSheetPage> get pages => throw _privateConstructorUsedError;
  PriceSheetData get sheet => throw _privateConstructorUsedError;

  /// Serializes this PriceSheetPreview to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PriceSheetPreview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PriceSheetPreviewCopyWith<PriceSheetPreview> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PriceSheetPreviewCopyWith<$Res> {
  factory $PriceSheetPreviewCopyWith(
    PriceSheetPreview value,
    $Res Function(PriceSheetPreview) then,
  ) = _$PriceSheetPreviewCopyWithImpl<$Res, PriceSheetPreview>;
  @useResult
  $Res call({
    @JsonKey(name: 'pdf_url') String pdfUrl,
    List<PriceSheetPage> pages,
    PriceSheetData sheet,
  });

  $PriceSheetDataCopyWith<$Res> get sheet;
}

/// @nodoc
class _$PriceSheetPreviewCopyWithImpl<$Res, $Val extends PriceSheetPreview>
    implements $PriceSheetPreviewCopyWith<$Res> {
  _$PriceSheetPreviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PriceSheetPreview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pdfUrl = null,
    Object? pages = null,
    Object? sheet = null,
  }) {
    return _then(
      _value.copyWith(
            pdfUrl: null == pdfUrl
                ? _value.pdfUrl
                : pdfUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            pages: null == pages
                ? _value.pages
                : pages // ignore: cast_nullable_to_non_nullable
                      as List<PriceSheetPage>,
            sheet: null == sheet
                ? _value.sheet
                : sheet // ignore: cast_nullable_to_non_nullable
                      as PriceSheetData,
          )
          as $Val,
    );
  }

  /// Create a copy of PriceSheetPreview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PriceSheetDataCopyWith<$Res> get sheet {
    return $PriceSheetDataCopyWith<$Res>(_value.sheet, (value) {
      return _then(_value.copyWith(sheet: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PriceSheetPreviewImplCopyWith<$Res>
    implements $PriceSheetPreviewCopyWith<$Res> {
  factory _$$PriceSheetPreviewImplCopyWith(
    _$PriceSheetPreviewImpl value,
    $Res Function(_$PriceSheetPreviewImpl) then,
  ) = __$$PriceSheetPreviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'pdf_url') String pdfUrl,
    List<PriceSheetPage> pages,
    PriceSheetData sheet,
  });

  @override
  $PriceSheetDataCopyWith<$Res> get sheet;
}

/// @nodoc
class __$$PriceSheetPreviewImplCopyWithImpl<$Res>
    extends _$PriceSheetPreviewCopyWithImpl<$Res, _$PriceSheetPreviewImpl>
    implements _$$PriceSheetPreviewImplCopyWith<$Res> {
  __$$PriceSheetPreviewImplCopyWithImpl(
    _$PriceSheetPreviewImpl _value,
    $Res Function(_$PriceSheetPreviewImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PriceSheetPreview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pdfUrl = null,
    Object? pages = null,
    Object? sheet = null,
  }) {
    return _then(
      _$PriceSheetPreviewImpl(
        pdfUrl: null == pdfUrl
            ? _value.pdfUrl
            : pdfUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        pages: null == pages
            ? _value._pages
            : pages // ignore: cast_nullable_to_non_nullable
                  as List<PriceSheetPage>,
        sheet: null == sheet
            ? _value.sheet
            : sheet // ignore: cast_nullable_to_non_nullable
                  as PriceSheetData,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PriceSheetPreviewImpl extends _PriceSheetPreview {
  const _$PriceSheetPreviewImpl({
    @JsonKey(name: 'pdf_url') this.pdfUrl = '',
    final List<PriceSheetPage> pages = const <PriceSheetPage>[],
    this.sheet = const PriceSheetData(),
  }) : _pages = pages,
       super._();

  factory _$PriceSheetPreviewImpl.fromJson(Map<String, dynamic> json) =>
      _$$PriceSheetPreviewImplFromJson(json);

  @override
  @JsonKey(name: 'pdf_url')
  final String pdfUrl;
  final List<PriceSheetPage> _pages;
  @override
  @JsonKey()
  List<PriceSheetPage> get pages {
    if (_pages is EqualUnmodifiableListView) return _pages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pages);
  }

  @override
  @JsonKey()
  final PriceSheetData sheet;

  @override
  String toString() {
    return 'PriceSheetPreview(pdfUrl: $pdfUrl, pages: $pages, sheet: $sheet)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PriceSheetPreviewImpl &&
            (identical(other.pdfUrl, pdfUrl) || other.pdfUrl == pdfUrl) &&
            const DeepCollectionEquality().equals(other._pages, _pages) &&
            (identical(other.sheet, sheet) || other.sheet == sheet));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    pdfUrl,
    const DeepCollectionEquality().hash(_pages),
    sheet,
  );

  /// Create a copy of PriceSheetPreview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PriceSheetPreviewImplCopyWith<_$PriceSheetPreviewImpl> get copyWith =>
      __$$PriceSheetPreviewImplCopyWithImpl<_$PriceSheetPreviewImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PriceSheetPreviewImplToJson(this);
  }
}

abstract class _PriceSheetPreview extends PriceSheetPreview {
  const factory _PriceSheetPreview({
    @JsonKey(name: 'pdf_url') final String pdfUrl,
    final List<PriceSheetPage> pages,
    final PriceSheetData sheet,
  }) = _$PriceSheetPreviewImpl;
  const _PriceSheetPreview._() : super._();

  factory _PriceSheetPreview.fromJson(Map<String, dynamic> json) =
      _$PriceSheetPreviewImpl.fromJson;

  @override
  @JsonKey(name: 'pdf_url')
  String get pdfUrl;
  @override
  List<PriceSheetPage> get pages;
  @override
  PriceSheetData get sheet;

  /// Create a copy of PriceSheetPreview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PriceSheetPreviewImplCopyWith<_$PriceSheetPreviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PriceSheetTemplateRow _$PriceSheetTemplateRowFromJson(
  Map<String, dynamic> json,
) {
  return _PriceSheetTemplateRow.fromJson(json);
}

/// @nodoc
mixin _$PriceSheetTemplateRow {
  String get flavour => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  @_BoolConverter()
  bool get enabled => throw _privateConstructorUsedError;

  /// Serializes this PriceSheetTemplateRow to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PriceSheetTemplateRow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PriceSheetTemplateRowCopyWith<PriceSheetTemplateRow> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PriceSheetTemplateRowCopyWith<$Res> {
  factory $PriceSheetTemplateRowCopyWith(
    PriceSheetTemplateRow value,
    $Res Function(PriceSheetTemplateRow) then,
  ) = _$PriceSheetTemplateRowCopyWithImpl<$Res, PriceSheetTemplateRow>;
  @useResult
  $Res call({String flavour, String label, @_BoolConverter() bool enabled});
}

/// @nodoc
class _$PriceSheetTemplateRowCopyWithImpl<
  $Res,
  $Val extends PriceSheetTemplateRow
>
    implements $PriceSheetTemplateRowCopyWith<$Res> {
  _$PriceSheetTemplateRowCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PriceSheetTemplateRow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? flavour = null,
    Object? label = null,
    Object? enabled = null,
  }) {
    return _then(
      _value.copyWith(
            flavour: null == flavour
                ? _value.flavour
                : flavour // ignore: cast_nullable_to_non_nullable
                      as String,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            enabled: null == enabled
                ? _value.enabled
                : enabled // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PriceSheetTemplateRowImplCopyWith<$Res>
    implements $PriceSheetTemplateRowCopyWith<$Res> {
  factory _$$PriceSheetTemplateRowImplCopyWith(
    _$PriceSheetTemplateRowImpl value,
    $Res Function(_$PriceSheetTemplateRowImpl) then,
  ) = __$$PriceSheetTemplateRowImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String flavour, String label, @_BoolConverter() bool enabled});
}

/// @nodoc
class __$$PriceSheetTemplateRowImplCopyWithImpl<$Res>
    extends
        _$PriceSheetTemplateRowCopyWithImpl<$Res, _$PriceSheetTemplateRowImpl>
    implements _$$PriceSheetTemplateRowImplCopyWith<$Res> {
  __$$PriceSheetTemplateRowImplCopyWithImpl(
    _$PriceSheetTemplateRowImpl _value,
    $Res Function(_$PriceSheetTemplateRowImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PriceSheetTemplateRow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? flavour = null,
    Object? label = null,
    Object? enabled = null,
  }) {
    return _then(
      _$PriceSheetTemplateRowImpl(
        flavour: null == flavour
            ? _value.flavour
            : flavour // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        enabled: null == enabled
            ? _value.enabled
            : enabled // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PriceSheetTemplateRowImpl implements _PriceSheetTemplateRow {
  const _$PriceSheetTemplateRowImpl({
    this.flavour = '',
    this.label = '',
    @_BoolConverter() this.enabled = true,
  });

  factory _$PriceSheetTemplateRowImpl.fromJson(Map<String, dynamic> json) =>
      _$$PriceSheetTemplateRowImplFromJson(json);

  @override
  @JsonKey()
  final String flavour;
  @override
  @JsonKey()
  final String label;
  @override
  @JsonKey()
  @_BoolConverter()
  final bool enabled;

  @override
  String toString() {
    return 'PriceSheetTemplateRow(flavour: $flavour, label: $label, enabled: $enabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PriceSheetTemplateRowImpl &&
            (identical(other.flavour, flavour) || other.flavour == flavour) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.enabled, enabled) || other.enabled == enabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, flavour, label, enabled);

  /// Create a copy of PriceSheetTemplateRow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PriceSheetTemplateRowImplCopyWith<_$PriceSheetTemplateRowImpl>
  get copyWith =>
      __$$PriceSheetTemplateRowImplCopyWithImpl<_$PriceSheetTemplateRowImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PriceSheetTemplateRowImplToJson(this);
  }
}

abstract class _PriceSheetTemplateRow implements PriceSheetTemplateRow {
  const factory _PriceSheetTemplateRow({
    final String flavour,
    final String label,
    @_BoolConverter() final bool enabled,
  }) = _$PriceSheetTemplateRowImpl;

  factory _PriceSheetTemplateRow.fromJson(Map<String, dynamic> json) =
      _$PriceSheetTemplateRowImpl.fromJson;

  @override
  String get flavour;
  @override
  String get label;
  @override
  @_BoolConverter()
  bool get enabled;

  /// Create a copy of PriceSheetTemplateRow
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PriceSheetTemplateRowImplCopyWith<_$PriceSheetTemplateRowImpl>
  get copyWith => throw _privateConstructorUsedError;
}

PriceSheetTemplate _$PriceSheetTemplateFromJson(Map<String, dynamic> json) {
  return _PriceSheetTemplate.fromJson(json);
}

/// @nodoc
mixin _$PriceSheetTemplate {
  String get name => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'title_ar')
  String get titleAr => throw _privateConstructorUsedError;
  @_BoolConverter()
  bool get enabled => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_default')
  @_BoolConverter()
  bool get isDefault => throw _privateConstructorUsedError;
  @JsonKey(name: 'sheet_heading')
  String get sheetHeading => throw _privateConstructorUsedError;

  /// Null = each customer's own B2B price list.
  @JsonKey(name: 'sheet_price_list')
  @_NullableStringConverter()
  String? get sheetPriceList => throw _privateConstructorUsedError;
  @JsonKey(name: 'sheet_sizes')
  @_StringListConverter()
  List<String> get sheetSizes => throw _privateConstructorUsedError;
  @JsonKey(name: 'sheet_show_deals')
  @_BoolConverter()
  bool get sheetShowDeals => throw _privateConstructorUsedError;
  @JsonKey(name: 'sheet_terms')
  @_LinesConverter()
  List<String> get sheetTerms => throw _privateConstructorUsedError;
  @JsonKey(name: 'sheet_footer')
  String get sheetFooter => throw _privateConstructorUsedError;
  List<PriceSheetTemplateRow> get rows => throw _privateConstructorUsedError;
  @JsonKey(name: 'available_flavours')
  @_StringListConverter()
  List<String> get availableFlavours => throw _privateConstructorUsedError;
  @JsonKey(name: 'available_sizes')
  @_StringListConverter()
  List<String> get availableSizes => throw _privateConstructorUsedError;
  @JsonKey(name: 'price_lists')
  @_StringListConverter()
  List<String> get priceLists => throw _privateConstructorUsedError;
  @JsonKey(name: 'can_edit')
  @_BoolConverter()
  bool get canEdit => throw _privateConstructorUsedError;

  /// Serializes this PriceSheetTemplate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PriceSheetTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PriceSheetTemplateCopyWith<PriceSheetTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PriceSheetTemplateCopyWith<$Res> {
  factory $PriceSheetTemplateCopyWith(
    PriceSheetTemplate value,
    $Res Function(PriceSheetTemplate) then,
  ) = _$PriceSheetTemplateCopyWithImpl<$Res, PriceSheetTemplate>;
  @useResult
  $Res call({
    String name,
    String title,
    @JsonKey(name: 'title_ar') String titleAr,
    @_BoolConverter() bool enabled,
    @JsonKey(name: 'is_default') @_BoolConverter() bool isDefault,
    @JsonKey(name: 'sheet_heading') String sheetHeading,
    @JsonKey(name: 'sheet_price_list')
    @_NullableStringConverter()
    String? sheetPriceList,
    @JsonKey(name: 'sheet_sizes')
    @_StringListConverter()
    List<String> sheetSizes,
    @JsonKey(name: 'sheet_show_deals') @_BoolConverter() bool sheetShowDeals,
    @JsonKey(name: 'sheet_terms') @_LinesConverter() List<String> sheetTerms,
    @JsonKey(name: 'sheet_footer') String sheetFooter,
    List<PriceSheetTemplateRow> rows,
    @JsonKey(name: 'available_flavours')
    @_StringListConverter()
    List<String> availableFlavours,
    @JsonKey(name: 'available_sizes')
    @_StringListConverter()
    List<String> availableSizes,
    @JsonKey(name: 'price_lists')
    @_StringListConverter()
    List<String> priceLists,
    @JsonKey(name: 'can_edit') @_BoolConverter() bool canEdit,
  });
}

/// @nodoc
class _$PriceSheetTemplateCopyWithImpl<$Res, $Val extends PriceSheetTemplate>
    implements $PriceSheetTemplateCopyWith<$Res> {
  _$PriceSheetTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PriceSheetTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? title = null,
    Object? titleAr = null,
    Object? enabled = null,
    Object? isDefault = null,
    Object? sheetHeading = null,
    Object? sheetPriceList = freezed,
    Object? sheetSizes = null,
    Object? sheetShowDeals = null,
    Object? sheetTerms = null,
    Object? sheetFooter = null,
    Object? rows = null,
    Object? availableFlavours = null,
    Object? availableSizes = null,
    Object? priceLists = null,
    Object? canEdit = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            titleAr: null == titleAr
                ? _value.titleAr
                : titleAr // ignore: cast_nullable_to_non_nullable
                      as String,
            enabled: null == enabled
                ? _value.enabled
                : enabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            isDefault: null == isDefault
                ? _value.isDefault
                : isDefault // ignore: cast_nullable_to_non_nullable
                      as bool,
            sheetHeading: null == sheetHeading
                ? _value.sheetHeading
                : sheetHeading // ignore: cast_nullable_to_non_nullable
                      as String,
            sheetPriceList: freezed == sheetPriceList
                ? _value.sheetPriceList
                : sheetPriceList // ignore: cast_nullable_to_non_nullable
                      as String?,
            sheetSizes: null == sheetSizes
                ? _value.sheetSizes
                : sheetSizes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            sheetShowDeals: null == sheetShowDeals
                ? _value.sheetShowDeals
                : sheetShowDeals // ignore: cast_nullable_to_non_nullable
                      as bool,
            sheetTerms: null == sheetTerms
                ? _value.sheetTerms
                : sheetTerms // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            sheetFooter: null == sheetFooter
                ? _value.sheetFooter
                : sheetFooter // ignore: cast_nullable_to_non_nullable
                      as String,
            rows: null == rows
                ? _value.rows
                : rows // ignore: cast_nullable_to_non_nullable
                      as List<PriceSheetTemplateRow>,
            availableFlavours: null == availableFlavours
                ? _value.availableFlavours
                : availableFlavours // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            availableSizes: null == availableSizes
                ? _value.availableSizes
                : availableSizes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            priceLists: null == priceLists
                ? _value.priceLists
                : priceLists // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            canEdit: null == canEdit
                ? _value.canEdit
                : canEdit // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PriceSheetTemplateImplCopyWith<$Res>
    implements $PriceSheetTemplateCopyWith<$Res> {
  factory _$$PriceSheetTemplateImplCopyWith(
    _$PriceSheetTemplateImpl value,
    $Res Function(_$PriceSheetTemplateImpl) then,
  ) = __$$PriceSheetTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String title,
    @JsonKey(name: 'title_ar') String titleAr,
    @_BoolConverter() bool enabled,
    @JsonKey(name: 'is_default') @_BoolConverter() bool isDefault,
    @JsonKey(name: 'sheet_heading') String sheetHeading,
    @JsonKey(name: 'sheet_price_list')
    @_NullableStringConverter()
    String? sheetPriceList,
    @JsonKey(name: 'sheet_sizes')
    @_StringListConverter()
    List<String> sheetSizes,
    @JsonKey(name: 'sheet_show_deals') @_BoolConverter() bool sheetShowDeals,
    @JsonKey(name: 'sheet_terms') @_LinesConverter() List<String> sheetTerms,
    @JsonKey(name: 'sheet_footer') String sheetFooter,
    List<PriceSheetTemplateRow> rows,
    @JsonKey(name: 'available_flavours')
    @_StringListConverter()
    List<String> availableFlavours,
    @JsonKey(name: 'available_sizes')
    @_StringListConverter()
    List<String> availableSizes,
    @JsonKey(name: 'price_lists')
    @_StringListConverter()
    List<String> priceLists,
    @JsonKey(name: 'can_edit') @_BoolConverter() bool canEdit,
  });
}

/// @nodoc
class __$$PriceSheetTemplateImplCopyWithImpl<$Res>
    extends _$PriceSheetTemplateCopyWithImpl<$Res, _$PriceSheetTemplateImpl>
    implements _$$PriceSheetTemplateImplCopyWith<$Res> {
  __$$PriceSheetTemplateImplCopyWithImpl(
    _$PriceSheetTemplateImpl _value,
    $Res Function(_$PriceSheetTemplateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PriceSheetTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? title = null,
    Object? titleAr = null,
    Object? enabled = null,
    Object? isDefault = null,
    Object? sheetHeading = null,
    Object? sheetPriceList = freezed,
    Object? sheetSizes = null,
    Object? sheetShowDeals = null,
    Object? sheetTerms = null,
    Object? sheetFooter = null,
    Object? rows = null,
    Object? availableFlavours = null,
    Object? availableSizes = null,
    Object? priceLists = null,
    Object? canEdit = null,
  }) {
    return _then(
      _$PriceSheetTemplateImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        titleAr: null == titleAr
            ? _value.titleAr
            : titleAr // ignore: cast_nullable_to_non_nullable
                  as String,
        enabled: null == enabled
            ? _value.enabled
            : enabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        isDefault: null == isDefault
            ? _value.isDefault
            : isDefault // ignore: cast_nullable_to_non_nullable
                  as bool,
        sheetHeading: null == sheetHeading
            ? _value.sheetHeading
            : sheetHeading // ignore: cast_nullable_to_non_nullable
                  as String,
        sheetPriceList: freezed == sheetPriceList
            ? _value.sheetPriceList
            : sheetPriceList // ignore: cast_nullable_to_non_nullable
                  as String?,
        sheetSizes: null == sheetSizes
            ? _value._sheetSizes
            : sheetSizes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        sheetShowDeals: null == sheetShowDeals
            ? _value.sheetShowDeals
            : sheetShowDeals // ignore: cast_nullable_to_non_nullable
                  as bool,
        sheetTerms: null == sheetTerms
            ? _value._sheetTerms
            : sheetTerms // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        sheetFooter: null == sheetFooter
            ? _value.sheetFooter
            : sheetFooter // ignore: cast_nullable_to_non_nullable
                  as String,
        rows: null == rows
            ? _value._rows
            : rows // ignore: cast_nullable_to_non_nullable
                  as List<PriceSheetTemplateRow>,
        availableFlavours: null == availableFlavours
            ? _value._availableFlavours
            : availableFlavours // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        availableSizes: null == availableSizes
            ? _value._availableSizes
            : availableSizes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        priceLists: null == priceLists
            ? _value._priceLists
            : priceLists // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        canEdit: null == canEdit
            ? _value.canEdit
            : canEdit // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PriceSheetTemplateImpl extends _PriceSheetTemplate {
  const _$PriceSheetTemplateImpl({
    this.name = '',
    this.title = '',
    @JsonKey(name: 'title_ar') this.titleAr = '',
    @_BoolConverter() this.enabled = true,
    @JsonKey(name: 'is_default') @_BoolConverter() this.isDefault = false,
    @JsonKey(name: 'sheet_heading') this.sheetHeading = '',
    @JsonKey(name: 'sheet_price_list')
    @_NullableStringConverter()
    this.sheetPriceList,
    @JsonKey(name: 'sheet_sizes')
    @_StringListConverter()
    final List<String> sheetSizes = const <String>[],
    @JsonKey(name: 'sheet_show_deals')
    @_BoolConverter()
    this.sheetShowDeals = true,
    @JsonKey(name: 'sheet_terms')
    @_LinesConverter()
    final List<String> sheetTerms = const <String>[],
    @JsonKey(name: 'sheet_footer') this.sheetFooter = '',
    final List<PriceSheetTemplateRow> rows = const <PriceSheetTemplateRow>[],
    @JsonKey(name: 'available_flavours')
    @_StringListConverter()
    final List<String> availableFlavours = const <String>[],
    @JsonKey(name: 'available_sizes')
    @_StringListConverter()
    final List<String> availableSizes = const <String>[],
    @JsonKey(name: 'price_lists')
    @_StringListConverter()
    final List<String> priceLists = const <String>[],
    @JsonKey(name: 'can_edit') @_BoolConverter() this.canEdit = false,
  }) : _sheetSizes = sheetSizes,
       _sheetTerms = sheetTerms,
       _rows = rows,
       _availableFlavours = availableFlavours,
       _availableSizes = availableSizes,
       _priceLists = priceLists,
       super._();

  factory _$PriceSheetTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PriceSheetTemplateImplFromJson(json);

  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String title;
  @override
  @JsonKey(name: 'title_ar')
  final String titleAr;
  @override
  @JsonKey()
  @_BoolConverter()
  final bool enabled;
  @override
  @JsonKey(name: 'is_default')
  @_BoolConverter()
  final bool isDefault;
  @override
  @JsonKey(name: 'sheet_heading')
  final String sheetHeading;

  /// Null = each customer's own B2B price list.
  @override
  @JsonKey(name: 'sheet_price_list')
  @_NullableStringConverter()
  final String? sheetPriceList;
  final List<String> _sheetSizes;
  @override
  @JsonKey(name: 'sheet_sizes')
  @_StringListConverter()
  List<String> get sheetSizes {
    if (_sheetSizes is EqualUnmodifiableListView) return _sheetSizes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sheetSizes);
  }

  @override
  @JsonKey(name: 'sheet_show_deals')
  @_BoolConverter()
  final bool sheetShowDeals;
  final List<String> _sheetTerms;
  @override
  @JsonKey(name: 'sheet_terms')
  @_LinesConverter()
  List<String> get sheetTerms {
    if (_sheetTerms is EqualUnmodifiableListView) return _sheetTerms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sheetTerms);
  }

  @override
  @JsonKey(name: 'sheet_footer')
  final String sheetFooter;
  final List<PriceSheetTemplateRow> _rows;
  @override
  @JsonKey()
  List<PriceSheetTemplateRow> get rows {
    if (_rows is EqualUnmodifiableListView) return _rows;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rows);
  }

  final List<String> _availableFlavours;
  @override
  @JsonKey(name: 'available_flavours')
  @_StringListConverter()
  List<String> get availableFlavours {
    if (_availableFlavours is EqualUnmodifiableListView)
      return _availableFlavours;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableFlavours);
  }

  final List<String> _availableSizes;
  @override
  @JsonKey(name: 'available_sizes')
  @_StringListConverter()
  List<String> get availableSizes {
    if (_availableSizes is EqualUnmodifiableListView) return _availableSizes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableSizes);
  }

  final List<String> _priceLists;
  @override
  @JsonKey(name: 'price_lists')
  @_StringListConverter()
  List<String> get priceLists {
    if (_priceLists is EqualUnmodifiableListView) return _priceLists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_priceLists);
  }

  @override
  @JsonKey(name: 'can_edit')
  @_BoolConverter()
  final bool canEdit;

  @override
  String toString() {
    return 'PriceSheetTemplate(name: $name, title: $title, titleAr: $titleAr, enabled: $enabled, isDefault: $isDefault, sheetHeading: $sheetHeading, sheetPriceList: $sheetPriceList, sheetSizes: $sheetSizes, sheetShowDeals: $sheetShowDeals, sheetTerms: $sheetTerms, sheetFooter: $sheetFooter, rows: $rows, availableFlavours: $availableFlavours, availableSizes: $availableSizes, priceLists: $priceLists, canEdit: $canEdit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PriceSheetTemplateImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.titleAr, titleAr) || other.titleAr == titleAr) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault) &&
            (identical(other.sheetHeading, sheetHeading) ||
                other.sheetHeading == sheetHeading) &&
            (identical(other.sheetPriceList, sheetPriceList) ||
                other.sheetPriceList == sheetPriceList) &&
            const DeepCollectionEquality().equals(
              other._sheetSizes,
              _sheetSizes,
            ) &&
            (identical(other.sheetShowDeals, sheetShowDeals) ||
                other.sheetShowDeals == sheetShowDeals) &&
            const DeepCollectionEquality().equals(
              other._sheetTerms,
              _sheetTerms,
            ) &&
            (identical(other.sheetFooter, sheetFooter) ||
                other.sheetFooter == sheetFooter) &&
            const DeepCollectionEquality().equals(other._rows, _rows) &&
            const DeepCollectionEquality().equals(
              other._availableFlavours,
              _availableFlavours,
            ) &&
            const DeepCollectionEquality().equals(
              other._availableSizes,
              _availableSizes,
            ) &&
            const DeepCollectionEquality().equals(
              other._priceLists,
              _priceLists,
            ) &&
            (identical(other.canEdit, canEdit) || other.canEdit == canEdit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    title,
    titleAr,
    enabled,
    isDefault,
    sheetHeading,
    sheetPriceList,
    const DeepCollectionEquality().hash(_sheetSizes),
    sheetShowDeals,
    const DeepCollectionEquality().hash(_sheetTerms),
    sheetFooter,
    const DeepCollectionEquality().hash(_rows),
    const DeepCollectionEquality().hash(_availableFlavours),
    const DeepCollectionEquality().hash(_availableSizes),
    const DeepCollectionEquality().hash(_priceLists),
    canEdit,
  );

  /// Create a copy of PriceSheetTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PriceSheetTemplateImplCopyWith<_$PriceSheetTemplateImpl> get copyWith =>
      __$$PriceSheetTemplateImplCopyWithImpl<_$PriceSheetTemplateImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PriceSheetTemplateImplToJson(this);
  }
}

abstract class _PriceSheetTemplate extends PriceSheetTemplate {
  const factory _PriceSheetTemplate({
    final String name,
    final String title,
    @JsonKey(name: 'title_ar') final String titleAr,
    @_BoolConverter() final bool enabled,
    @JsonKey(name: 'is_default') @_BoolConverter() final bool isDefault,
    @JsonKey(name: 'sheet_heading') final String sheetHeading,
    @JsonKey(name: 'sheet_price_list')
    @_NullableStringConverter()
    final String? sheetPriceList,
    @JsonKey(name: 'sheet_sizes')
    @_StringListConverter()
    final List<String> sheetSizes,
    @JsonKey(name: 'sheet_show_deals')
    @_BoolConverter()
    final bool sheetShowDeals,
    @JsonKey(name: 'sheet_terms')
    @_LinesConverter()
    final List<String> sheetTerms,
    @JsonKey(name: 'sheet_footer') final String sheetFooter,
    final List<PriceSheetTemplateRow> rows,
    @JsonKey(name: 'available_flavours')
    @_StringListConverter()
    final List<String> availableFlavours,
    @JsonKey(name: 'available_sizes')
    @_StringListConverter()
    final List<String> availableSizes,
    @JsonKey(name: 'price_lists')
    @_StringListConverter()
    final List<String> priceLists,
    @JsonKey(name: 'can_edit') @_BoolConverter() final bool canEdit,
  }) = _$PriceSheetTemplateImpl;
  const _PriceSheetTemplate._() : super._();

  factory _PriceSheetTemplate.fromJson(Map<String, dynamic> json) =
      _$PriceSheetTemplateImpl.fromJson;

  @override
  String get name;
  @override
  String get title;
  @override
  @JsonKey(name: 'title_ar')
  String get titleAr;
  @override
  @_BoolConverter()
  bool get enabled;
  @override
  @JsonKey(name: 'is_default')
  @_BoolConverter()
  bool get isDefault;
  @override
  @JsonKey(name: 'sheet_heading')
  String get sheetHeading;

  /// Null = each customer's own B2B price list.
  @override
  @JsonKey(name: 'sheet_price_list')
  @_NullableStringConverter()
  String? get sheetPriceList;
  @override
  @JsonKey(name: 'sheet_sizes')
  @_StringListConverter()
  List<String> get sheetSizes;
  @override
  @JsonKey(name: 'sheet_show_deals')
  @_BoolConverter()
  bool get sheetShowDeals;
  @override
  @JsonKey(name: 'sheet_terms')
  @_LinesConverter()
  List<String> get sheetTerms;
  @override
  @JsonKey(name: 'sheet_footer')
  String get sheetFooter;
  @override
  List<PriceSheetTemplateRow> get rows;
  @override
  @JsonKey(name: 'available_flavours')
  @_StringListConverter()
  List<String> get availableFlavours;
  @override
  @JsonKey(name: 'available_sizes')
  @_StringListConverter()
  List<String> get availableSizes;
  @override
  @JsonKey(name: 'price_lists')
  @_StringListConverter()
  List<String> get priceLists;
  @override
  @JsonKey(name: 'can_edit')
  @_BoolConverter()
  bool get canEdit;

  /// Create a copy of PriceSheetTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PriceSheetTemplateImplCopyWith<_$PriceSheetTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
