// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'material_share_preview.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PublicShareItem _$PublicShareItemFromJson(Map<String, dynamic> json) {
  return _PublicShareItem.fromJson(json);
}

/// @nodoc
mixin _$PublicShareItem {
  @_StringConverter()
  String get title => throw _privateConstructorUsedError;
  @_StringConverter()
  String get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'download_url')
  @_StringConverter()
  String get downloadUrl => throw _privateConstructorUsedError;
  List<PriceSheetPage> get pages => throw _privateConstructorUsedError;

  /// Serializes this PublicShareItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PublicShareItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PublicShareItemCopyWith<PublicShareItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PublicShareItemCopyWith<$Res> {
  factory $PublicShareItemCopyWith(
    PublicShareItem value,
    $Res Function(PublicShareItem) then,
  ) = _$PublicShareItemCopyWithImpl<$Res, PublicShareItem>;
  @useResult
  $Res call({
    @_StringConverter() String title,
    @_StringConverter() String type,
    @JsonKey(name: 'download_url') @_StringConverter() String downloadUrl,
    List<PriceSheetPage> pages,
  });
}

/// @nodoc
class _$PublicShareItemCopyWithImpl<$Res, $Val extends PublicShareItem>
    implements $PublicShareItemCopyWith<$Res> {
  _$PublicShareItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PublicShareItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? type = null,
    Object? downloadUrl = null,
    Object? pages = null,
  }) {
    return _then(
      _value.copyWith(
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            downloadUrl: null == downloadUrl
                ? _value.downloadUrl
                : downloadUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            pages: null == pages
                ? _value.pages
                : pages // ignore: cast_nullable_to_non_nullable
                      as List<PriceSheetPage>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PublicShareItemImplCopyWith<$Res>
    implements $PublicShareItemCopyWith<$Res> {
  factory _$$PublicShareItemImplCopyWith(
    _$PublicShareItemImpl value,
    $Res Function(_$PublicShareItemImpl) then,
  ) = __$$PublicShareItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @_StringConverter() String title,
    @_StringConverter() String type,
    @JsonKey(name: 'download_url') @_StringConverter() String downloadUrl,
    List<PriceSheetPage> pages,
  });
}

/// @nodoc
class __$$PublicShareItemImplCopyWithImpl<$Res>
    extends _$PublicShareItemCopyWithImpl<$Res, _$PublicShareItemImpl>
    implements _$$PublicShareItemImplCopyWith<$Res> {
  __$$PublicShareItemImplCopyWithImpl(
    _$PublicShareItemImpl _value,
    $Res Function(_$PublicShareItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PublicShareItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? type = null,
    Object? downloadUrl = null,
    Object? pages = null,
  }) {
    return _then(
      _$PublicShareItemImpl(
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        downloadUrl: null == downloadUrl
            ? _value.downloadUrl
            : downloadUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        pages: null == pages
            ? _value._pages
            : pages // ignore: cast_nullable_to_non_nullable
                  as List<PriceSheetPage>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PublicShareItemImpl extends _PublicShareItem {
  const _$PublicShareItemImpl({
    @_StringConverter() this.title = '',
    @_StringConverter() this.type = '',
    @JsonKey(name: 'download_url') @_StringConverter() this.downloadUrl = '',
    final List<PriceSheetPage> pages = const <PriceSheetPage>[],
  }) : _pages = pages,
       super._();

  factory _$PublicShareItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PublicShareItemImplFromJson(json);

  @override
  @JsonKey()
  @_StringConverter()
  final String title;
  @override
  @JsonKey()
  @_StringConverter()
  final String type;
  @override
  @JsonKey(name: 'download_url')
  @_StringConverter()
  final String downloadUrl;
  final List<PriceSheetPage> _pages;
  @override
  @JsonKey()
  List<PriceSheetPage> get pages {
    if (_pages is EqualUnmodifiableListView) return _pages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pages);
  }

  @override
  String toString() {
    return 'PublicShareItem(title: $title, type: $type, downloadUrl: $downloadUrl, pages: $pages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PublicShareItemImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.downloadUrl, downloadUrl) ||
                other.downloadUrl == downloadUrl) &&
            const DeepCollectionEquality().equals(other._pages, _pages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    title,
    type,
    downloadUrl,
    const DeepCollectionEquality().hash(_pages),
  );

  /// Create a copy of PublicShareItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PublicShareItemImplCopyWith<_$PublicShareItemImpl> get copyWith =>
      __$$PublicShareItemImplCopyWithImpl<_$PublicShareItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PublicShareItemImplToJson(this);
  }
}

abstract class _PublicShareItem extends PublicShareItem {
  const factory _PublicShareItem({
    @_StringConverter() final String title,
    @_StringConverter() final String type,
    @JsonKey(name: 'download_url') @_StringConverter() final String downloadUrl,
    final List<PriceSheetPage> pages,
  }) = _$PublicShareItemImpl;
  const _PublicShareItem._() : super._();

  factory _PublicShareItem.fromJson(Map<String, dynamic> json) =
      _$PublicShareItemImpl.fromJson;

  @override
  @_StringConverter()
  String get title;
  @override
  @_StringConverter()
  String get type;
  @override
  @JsonKey(name: 'download_url')
  @_StringConverter()
  String get downloadUrl;
  @override
  List<PriceSheetPage> get pages;

  /// Create a copy of PublicShareItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PublicShareItemImplCopyWith<_$PublicShareItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MaterialSharePreview _$MaterialSharePreviewFromJson(Map<String, dynamic> json) {
  return _MaterialSharePreview.fromJson(json);
}

/// @nodoc
mixin _$MaterialSharePreview {
  /// The final WhatsApp text, `{name}` filled and the link replaced by
  /// [linkPlaceholderUrl].
  @_StringConverter()
  String get message => throw _privateConstructorUsedError;

  /// The fake-token URL standing where the real link will go.
  @JsonKey(name: 'link_placeholder_url')
  @_StringConverter()
  String get linkPlaceholderUrl => throw _privateConstructorUsedError;

  /// Exactly what the page would greet with; null = no greeting.
  @JsonKey(name: 'greeting_name')
  @_NullableStringConverter()
  String? get greetingName => throw _privateConstructorUsedError;
  List<PublicShareItem> get items => throw _privateConstructorUsedError;
  @JsonKey(name: 'material_names')
  List<String> get materialNames => throw _privateConstructorUsedError;

  /// Serializes this MaterialSharePreview to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MaterialSharePreview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MaterialSharePreviewCopyWith<MaterialSharePreview> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaterialSharePreviewCopyWith<$Res> {
  factory $MaterialSharePreviewCopyWith(
    MaterialSharePreview value,
    $Res Function(MaterialSharePreview) then,
  ) = _$MaterialSharePreviewCopyWithImpl<$Res, MaterialSharePreview>;
  @useResult
  $Res call({
    @_StringConverter() String message,
    @JsonKey(name: 'link_placeholder_url')
    @_StringConverter()
    String linkPlaceholderUrl,
    @JsonKey(name: 'greeting_name')
    @_NullableStringConverter()
    String? greetingName,
    List<PublicShareItem> items,
    @JsonKey(name: 'material_names') List<String> materialNames,
  });
}

/// @nodoc
class _$MaterialSharePreviewCopyWithImpl<
  $Res,
  $Val extends MaterialSharePreview
>
    implements $MaterialSharePreviewCopyWith<$Res> {
  _$MaterialSharePreviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MaterialSharePreview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? linkPlaceholderUrl = null,
    Object? greetingName = freezed,
    Object? items = null,
    Object? materialNames = null,
  }) {
    return _then(
      _value.copyWith(
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            linkPlaceholderUrl: null == linkPlaceholderUrl
                ? _value.linkPlaceholderUrl
                : linkPlaceholderUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            greetingName: freezed == greetingName
                ? _value.greetingName
                : greetingName // ignore: cast_nullable_to_non_nullable
                      as String?,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<PublicShareItem>,
            materialNames: null == materialNames
                ? _value.materialNames
                : materialNames // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MaterialSharePreviewImplCopyWith<$Res>
    implements $MaterialSharePreviewCopyWith<$Res> {
  factory _$$MaterialSharePreviewImplCopyWith(
    _$MaterialSharePreviewImpl value,
    $Res Function(_$MaterialSharePreviewImpl) then,
  ) = __$$MaterialSharePreviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @_StringConverter() String message,
    @JsonKey(name: 'link_placeholder_url')
    @_StringConverter()
    String linkPlaceholderUrl,
    @JsonKey(name: 'greeting_name')
    @_NullableStringConverter()
    String? greetingName,
    List<PublicShareItem> items,
    @JsonKey(name: 'material_names') List<String> materialNames,
  });
}

/// @nodoc
class __$$MaterialSharePreviewImplCopyWithImpl<$Res>
    extends _$MaterialSharePreviewCopyWithImpl<$Res, _$MaterialSharePreviewImpl>
    implements _$$MaterialSharePreviewImplCopyWith<$Res> {
  __$$MaterialSharePreviewImplCopyWithImpl(
    _$MaterialSharePreviewImpl _value,
    $Res Function(_$MaterialSharePreviewImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MaterialSharePreview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? linkPlaceholderUrl = null,
    Object? greetingName = freezed,
    Object? items = null,
    Object? materialNames = null,
  }) {
    return _then(
      _$MaterialSharePreviewImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        linkPlaceholderUrl: null == linkPlaceholderUrl
            ? _value.linkPlaceholderUrl
            : linkPlaceholderUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        greetingName: freezed == greetingName
            ? _value.greetingName
            : greetingName // ignore: cast_nullable_to_non_nullable
                  as String?,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<PublicShareItem>,
        materialNames: null == materialNames
            ? _value._materialNames
            : materialNames // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MaterialSharePreviewImpl extends _MaterialSharePreview {
  const _$MaterialSharePreviewImpl({
    @_StringConverter() this.message = '',
    @JsonKey(name: 'link_placeholder_url')
    @_StringConverter()
    this.linkPlaceholderUrl = '',
    @JsonKey(name: 'greeting_name')
    @_NullableStringConverter()
    this.greetingName,
    final List<PublicShareItem> items = const <PublicShareItem>[],
    @JsonKey(name: 'material_names')
    final List<String> materialNames = const <String>[],
  }) : _items = items,
       _materialNames = materialNames,
       super._();

  factory _$MaterialSharePreviewImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaterialSharePreviewImplFromJson(json);

  /// The final WhatsApp text, `{name}` filled and the link replaced by
  /// [linkPlaceholderUrl].
  @override
  @JsonKey()
  @_StringConverter()
  final String message;

  /// The fake-token URL standing where the real link will go.
  @override
  @JsonKey(name: 'link_placeholder_url')
  @_StringConverter()
  final String linkPlaceholderUrl;

  /// Exactly what the page would greet with; null = no greeting.
  @override
  @JsonKey(name: 'greeting_name')
  @_NullableStringConverter()
  final String? greetingName;
  final List<PublicShareItem> _items;
  @override
  @JsonKey()
  List<PublicShareItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  final List<String> _materialNames;
  @override
  @JsonKey(name: 'material_names')
  List<String> get materialNames {
    if (_materialNames is EqualUnmodifiableListView) return _materialNames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_materialNames);
  }

  @override
  String toString() {
    return 'MaterialSharePreview(message: $message, linkPlaceholderUrl: $linkPlaceholderUrl, greetingName: $greetingName, items: $items, materialNames: $materialNames)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaterialSharePreviewImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.linkPlaceholderUrl, linkPlaceholderUrl) ||
                other.linkPlaceholderUrl == linkPlaceholderUrl) &&
            (identical(other.greetingName, greetingName) ||
                other.greetingName == greetingName) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            const DeepCollectionEquality().equals(
              other._materialNames,
              _materialNames,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    message,
    linkPlaceholderUrl,
    greetingName,
    const DeepCollectionEquality().hash(_items),
    const DeepCollectionEquality().hash(_materialNames),
  );

  /// Create a copy of MaterialSharePreview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MaterialSharePreviewImplCopyWith<_$MaterialSharePreviewImpl>
  get copyWith =>
      __$$MaterialSharePreviewImplCopyWithImpl<_$MaterialSharePreviewImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MaterialSharePreviewImplToJson(this);
  }
}

abstract class _MaterialSharePreview extends MaterialSharePreview {
  const factory _MaterialSharePreview({
    @_StringConverter() final String message,
    @JsonKey(name: 'link_placeholder_url')
    @_StringConverter()
    final String linkPlaceholderUrl,
    @JsonKey(name: 'greeting_name')
    @_NullableStringConverter()
    final String? greetingName,
    final List<PublicShareItem> items,
    @JsonKey(name: 'material_names') final List<String> materialNames,
  }) = _$MaterialSharePreviewImpl;
  const _MaterialSharePreview._() : super._();

  factory _MaterialSharePreview.fromJson(Map<String, dynamic> json) =
      _$MaterialSharePreviewImpl.fromJson;

  /// The final WhatsApp text, `{name}` filled and the link replaced by
  /// [linkPlaceholderUrl].
  @override
  @_StringConverter()
  String get message;

  /// The fake-token URL standing where the real link will go.
  @override
  @JsonKey(name: 'link_placeholder_url')
  @_StringConverter()
  String get linkPlaceholderUrl;

  /// Exactly what the page would greet with; null = no greeting.
  @override
  @JsonKey(name: 'greeting_name')
  @_NullableStringConverter()
  String? get greetingName;
  @override
  List<PublicShareItem> get items;
  @override
  @JsonKey(name: 'material_names')
  List<String> get materialNames;

  /// Create a copy of MaterialSharePreview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MaterialSharePreviewImplCopyWith<_$MaterialSharePreviewImpl>
  get copyWith => throw _privateConstructorUsedError;
}
