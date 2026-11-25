// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'studio_me.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

StudioMe _$StudioMeFromJson(Map<String, dynamic> json) {
  return _StudioMe.fromJson(json);
}

/// @nodoc
mixin _$StudioMe {
  String get user => throw _privateConstructorUsedError;
  String get fullName => throw _privateConstructorUsedError;
  List<String> get roles => throw _privateConstructorUsedError;
  bool get isFounder => throw _privateConstructorUsedError;
  String get mode => throw _privateConstructorUsedError;
  String get serverTime => throw _privateConstructorUsedError;

  /// Serializes this StudioMe to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StudioMe
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StudioMeCopyWith<StudioMe> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudioMeCopyWith<$Res> {
  factory $StudioMeCopyWith(StudioMe value, $Res Function(StudioMe) then) =
      _$StudioMeCopyWithImpl<$Res, StudioMe>;
  @useResult
  $Res call({
    String user,
    String fullName,
    List<String> roles,
    bool isFounder,
    String mode,
    String serverTime,
  });
}

/// @nodoc
class _$StudioMeCopyWithImpl<$Res, $Val extends StudioMe>
    implements $StudioMeCopyWith<$Res> {
  _$StudioMeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StudioMe
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = null,
    Object? fullName = null,
    Object? roles = null,
    Object? isFounder = null,
    Object? mode = null,
    Object? serverTime = null,
  }) {
    return _then(
      _value.copyWith(
            user: null == user
                ? _value.user
                : user // ignore: cast_nullable_to_non_nullable
                      as String,
            fullName: null == fullName
                ? _value.fullName
                : fullName // ignore: cast_nullable_to_non_nullable
                      as String,
            roles: null == roles
                ? _value.roles
                : roles // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            isFounder: null == isFounder
                ? _value.isFounder
                : isFounder // ignore: cast_nullable_to_non_nullable
                      as bool,
            mode: null == mode
                ? _value.mode
                : mode // ignore: cast_nullable_to_non_nullable
                      as String,
            serverTime: null == serverTime
                ? _value.serverTime
                : serverTime // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StudioMeImplCopyWith<$Res>
    implements $StudioMeCopyWith<$Res> {
  factory _$$StudioMeImplCopyWith(
    _$StudioMeImpl value,
    $Res Function(_$StudioMeImpl) then,
  ) = __$$StudioMeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String user,
    String fullName,
    List<String> roles,
    bool isFounder,
    String mode,
    String serverTime,
  });
}

/// @nodoc
class __$$StudioMeImplCopyWithImpl<$Res>
    extends _$StudioMeCopyWithImpl<$Res, _$StudioMeImpl>
    implements _$$StudioMeImplCopyWith<$Res> {
  __$$StudioMeImplCopyWithImpl(
    _$StudioMeImpl _value,
    $Res Function(_$StudioMeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StudioMe
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = null,
    Object? fullName = null,
    Object? roles = null,
    Object? isFounder = null,
    Object? mode = null,
    Object? serverTime = null,
  }) {
    return _then(
      _$StudioMeImpl(
        user: null == user
            ? _value.user
            : user // ignore: cast_nullable_to_non_nullable
                  as String,
        fullName: null == fullName
            ? _value.fullName
            : fullName // ignore: cast_nullable_to_non_nullable
                  as String,
        roles: null == roles
            ? _value._roles
            : roles // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isFounder: null == isFounder
            ? _value.isFounder
            : isFounder // ignore: cast_nullable_to_non_nullable
                  as bool,
        mode: null == mode
            ? _value.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as String,
        serverTime: null == serverTime
            ? _value.serverTime
            : serverTime // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$StudioMeImpl extends _StudioMe {
  const _$StudioMeImpl({
    required this.user,
    this.fullName = '',
    final List<String> roles = const <String>[],
    this.isFounder = false,
    this.mode = 'live',
    this.serverTime = '',
  }) : _roles = roles,
       super._();

  factory _$StudioMeImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudioMeImplFromJson(json);

  @override
  final String user;
  @override
  @JsonKey()
  final String fullName;
  final List<String> _roles;
  @override
  @JsonKey()
  List<String> get roles {
    if (_roles is EqualUnmodifiableListView) return _roles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_roles);
  }

  @override
  @JsonKey()
  final bool isFounder;
  @override
  @JsonKey()
  final String mode;
  @override
  @JsonKey()
  final String serverTime;

  @override
  String toString() {
    return 'StudioMe(user: $user, fullName: $fullName, roles: $roles, isFounder: $isFounder, mode: $mode, serverTime: $serverTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudioMeImpl &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            const DeepCollectionEquality().equals(other._roles, _roles) &&
            (identical(other.isFounder, isFounder) ||
                other.isFounder == isFounder) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.serverTime, serverTime) ||
                other.serverTime == serverTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    user,
    fullName,
    const DeepCollectionEquality().hash(_roles),
    isFounder,
    mode,
    serverTime,
  );

  /// Create a copy of StudioMe
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StudioMeImplCopyWith<_$StudioMeImpl> get copyWith =>
      __$$StudioMeImplCopyWithImpl<_$StudioMeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StudioMeImplToJson(this);
  }
}

abstract class _StudioMe extends StudioMe {
  const factory _StudioMe({
    required final String user,
    final String fullName,
    final List<String> roles,
    final bool isFounder,
    final String mode,
    final String serverTime,
  }) = _$StudioMeImpl;
  const _StudioMe._() : super._();

  factory _StudioMe.fromJson(Map<String, dynamic> json) =
      _$StudioMeImpl.fromJson;

  @override
  String get user;
  @override
  String get fullName;
  @override
  List<String> get roles;
  @override
  bool get isFounder;
  @override
  String get mode;
  @override
  String get serverTime;

  /// Create a copy of StudioMe
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StudioMeImplCopyWith<_$StudioMeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
