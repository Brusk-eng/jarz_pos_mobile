// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sales_material.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SalesMaterial _$SalesMaterialFromJson(Map<String, dynamic> json) {
  return _SalesMaterial.fromJson(json);
}

/// @nodoc
mixin _$SalesMaterial {
  String get name => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'title_ar')
  String get titleAr => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_title')
  String get displayTitle => throw _privateConstructorUsedError;
  @JsonKey(name: 'material_type')
  String get materialType => throw _privateConstructorUsedError;
  @JsonKey(name: 'download_url')
  String get downloadUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_default')
  bool get isDefault => throw _privateConstructorUsedError;
  @JsonKey(name: 'page_count')
  int get pageCount => throw _privateConstructorUsedError;

  /// False while the backend is still rasterising this file. The rep can
  /// still send it — the customer's page self-heals — but the sheet says so,
  /// because a link opened ten seconds after a 40MB upload is the one case
  /// where the reader waits.
  bool get ready => throw _privateConstructorUsedError;

  /// `Uploaded File` (a PDF/image a manager uploaded) or `Generated Price
  /// List` (a sheet the server renders from live prices per recipient).
  @JsonKey(name: 'source_type')
  String get sourceType => throw _privateConstructorUsedError;

  /// True for a generated price sheet: its prices are filled in at send time
  /// for the customer it goes to, so the sheet offers a preview instead of a
  /// file. Absent on an older server, hence the default.
  bool get generated => throw _privateConstructorUsedError;

  /// Serializes this SalesMaterial to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SalesMaterial
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SalesMaterialCopyWith<SalesMaterial> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SalesMaterialCopyWith<$Res> {
  factory $SalesMaterialCopyWith(
    SalesMaterial value,
    $Res Function(SalesMaterial) then,
  ) = _$SalesMaterialCopyWithImpl<$Res, SalesMaterial>;
  @useResult
  $Res call({
    String name,
    String title,
    @JsonKey(name: 'title_ar') String titleAr,
    @JsonKey(name: 'display_title') String displayTitle,
    @JsonKey(name: 'material_type') String materialType,
    @JsonKey(name: 'download_url') String downloadUrl,
    @JsonKey(name: 'is_default') bool isDefault,
    @JsonKey(name: 'page_count') int pageCount,
    bool ready,
    @JsonKey(name: 'source_type') String sourceType,
    bool generated,
  });
}

/// @nodoc
class _$SalesMaterialCopyWithImpl<$Res, $Val extends SalesMaterial>
    implements $SalesMaterialCopyWith<$Res> {
  _$SalesMaterialCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SalesMaterial
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? title = null,
    Object? titleAr = null,
    Object? displayTitle = null,
    Object? materialType = null,
    Object? downloadUrl = null,
    Object? isDefault = null,
    Object? pageCount = null,
    Object? ready = null,
    Object? sourceType = null,
    Object? generated = null,
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
            displayTitle: null == displayTitle
                ? _value.displayTitle
                : displayTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            materialType: null == materialType
                ? _value.materialType
                : materialType // ignore: cast_nullable_to_non_nullable
                      as String,
            downloadUrl: null == downloadUrl
                ? _value.downloadUrl
                : downloadUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            isDefault: null == isDefault
                ? _value.isDefault
                : isDefault // ignore: cast_nullable_to_non_nullable
                      as bool,
            pageCount: null == pageCount
                ? _value.pageCount
                : pageCount // ignore: cast_nullable_to_non_nullable
                      as int,
            ready: null == ready
                ? _value.ready
                : ready // ignore: cast_nullable_to_non_nullable
                      as bool,
            sourceType: null == sourceType
                ? _value.sourceType
                : sourceType // ignore: cast_nullable_to_non_nullable
                      as String,
            generated: null == generated
                ? _value.generated
                : generated // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SalesMaterialImplCopyWith<$Res>
    implements $SalesMaterialCopyWith<$Res> {
  factory _$$SalesMaterialImplCopyWith(
    _$SalesMaterialImpl value,
    $Res Function(_$SalesMaterialImpl) then,
  ) = __$$SalesMaterialImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String title,
    @JsonKey(name: 'title_ar') String titleAr,
    @JsonKey(name: 'display_title') String displayTitle,
    @JsonKey(name: 'material_type') String materialType,
    @JsonKey(name: 'download_url') String downloadUrl,
    @JsonKey(name: 'is_default') bool isDefault,
    @JsonKey(name: 'page_count') int pageCount,
    bool ready,
    @JsonKey(name: 'source_type') String sourceType,
    bool generated,
  });
}

/// @nodoc
class __$$SalesMaterialImplCopyWithImpl<$Res>
    extends _$SalesMaterialCopyWithImpl<$Res, _$SalesMaterialImpl>
    implements _$$SalesMaterialImplCopyWith<$Res> {
  __$$SalesMaterialImplCopyWithImpl(
    _$SalesMaterialImpl _value,
    $Res Function(_$SalesMaterialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SalesMaterial
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? title = null,
    Object? titleAr = null,
    Object? displayTitle = null,
    Object? materialType = null,
    Object? downloadUrl = null,
    Object? isDefault = null,
    Object? pageCount = null,
    Object? ready = null,
    Object? sourceType = null,
    Object? generated = null,
  }) {
    return _then(
      _$SalesMaterialImpl(
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
        displayTitle: null == displayTitle
            ? _value.displayTitle
            : displayTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        materialType: null == materialType
            ? _value.materialType
            : materialType // ignore: cast_nullable_to_non_nullable
                  as String,
        downloadUrl: null == downloadUrl
            ? _value.downloadUrl
            : downloadUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        isDefault: null == isDefault
            ? _value.isDefault
            : isDefault // ignore: cast_nullable_to_non_nullable
                  as bool,
        pageCount: null == pageCount
            ? _value.pageCount
            : pageCount // ignore: cast_nullable_to_non_nullable
                  as int,
        ready: null == ready
            ? _value.ready
            : ready // ignore: cast_nullable_to_non_nullable
                  as bool,
        sourceType: null == sourceType
            ? _value.sourceType
            : sourceType // ignore: cast_nullable_to_non_nullable
                  as String,
        generated: null == generated
            ? _value.generated
            : generated // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SalesMaterialImpl extends _SalesMaterial {
  const _$SalesMaterialImpl({
    required this.name,
    this.title = '',
    @JsonKey(name: 'title_ar') this.titleAr = '',
    @JsonKey(name: 'display_title') this.displayTitle = '',
    @JsonKey(name: 'material_type') this.materialType = '',
    @JsonKey(name: 'download_url') this.downloadUrl = '',
    @JsonKey(name: 'is_default') this.isDefault = false,
    @JsonKey(name: 'page_count') this.pageCount = 0,
    this.ready = false,
    @JsonKey(name: 'source_type') this.sourceType = 'Uploaded File',
    this.generated = false,
  }) : super._();

  factory _$SalesMaterialImpl.fromJson(Map<String, dynamic> json) =>
      _$$SalesMaterialImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey()
  final String title;
  @override
  @JsonKey(name: 'title_ar')
  final String titleAr;
  @override
  @JsonKey(name: 'display_title')
  final String displayTitle;
  @override
  @JsonKey(name: 'material_type')
  final String materialType;
  @override
  @JsonKey(name: 'download_url')
  final String downloadUrl;
  @override
  @JsonKey(name: 'is_default')
  final bool isDefault;
  @override
  @JsonKey(name: 'page_count')
  final int pageCount;

  /// False while the backend is still rasterising this file. The rep can
  /// still send it — the customer's page self-heals — but the sheet says so,
  /// because a link opened ten seconds after a 40MB upload is the one case
  /// where the reader waits.
  @override
  @JsonKey()
  final bool ready;

  /// `Uploaded File` (a PDF/image a manager uploaded) or `Generated Price
  /// List` (a sheet the server renders from live prices per recipient).
  @override
  @JsonKey(name: 'source_type')
  final String sourceType;

  /// True for a generated price sheet: its prices are filled in at send time
  /// for the customer it goes to, so the sheet offers a preview instead of a
  /// file. Absent on an older server, hence the default.
  @override
  @JsonKey()
  final bool generated;

  @override
  String toString() {
    return 'SalesMaterial(name: $name, title: $title, titleAr: $titleAr, displayTitle: $displayTitle, materialType: $materialType, downloadUrl: $downloadUrl, isDefault: $isDefault, pageCount: $pageCount, ready: $ready, sourceType: $sourceType, generated: $generated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SalesMaterialImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.titleAr, titleAr) || other.titleAr == titleAr) &&
            (identical(other.displayTitle, displayTitle) ||
                other.displayTitle == displayTitle) &&
            (identical(other.materialType, materialType) ||
                other.materialType == materialType) &&
            (identical(other.downloadUrl, downloadUrl) ||
                other.downloadUrl == downloadUrl) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault) &&
            (identical(other.pageCount, pageCount) ||
                other.pageCount == pageCount) &&
            (identical(other.ready, ready) || other.ready == ready) &&
            (identical(other.sourceType, sourceType) ||
                other.sourceType == sourceType) &&
            (identical(other.generated, generated) ||
                other.generated == generated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    title,
    titleAr,
    displayTitle,
    materialType,
    downloadUrl,
    isDefault,
    pageCount,
    ready,
    sourceType,
    generated,
  );

  /// Create a copy of SalesMaterial
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SalesMaterialImplCopyWith<_$SalesMaterialImpl> get copyWith =>
      __$$SalesMaterialImplCopyWithImpl<_$SalesMaterialImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SalesMaterialImplToJson(this);
  }
}

abstract class _SalesMaterial extends SalesMaterial {
  const factory _SalesMaterial({
    required final String name,
    final String title,
    @JsonKey(name: 'title_ar') final String titleAr,
    @JsonKey(name: 'display_title') final String displayTitle,
    @JsonKey(name: 'material_type') final String materialType,
    @JsonKey(name: 'download_url') final String downloadUrl,
    @JsonKey(name: 'is_default') final bool isDefault,
    @JsonKey(name: 'page_count') final int pageCount,
    final bool ready,
    @JsonKey(name: 'source_type') final String sourceType,
    final bool generated,
  }) = _$SalesMaterialImpl;
  const _SalesMaterial._() : super._();

  factory _SalesMaterial.fromJson(Map<String, dynamic> json) =
      _$SalesMaterialImpl.fromJson;

  @override
  String get name;
  @override
  String get title;
  @override
  @JsonKey(name: 'title_ar')
  String get titleAr;
  @override
  @JsonKey(name: 'display_title')
  String get displayTitle;
  @override
  @JsonKey(name: 'material_type')
  String get materialType;
  @override
  @JsonKey(name: 'download_url')
  String get downloadUrl;
  @override
  @JsonKey(name: 'is_default')
  bool get isDefault;
  @override
  @JsonKey(name: 'page_count')
  int get pageCount;

  /// False while the backend is still rasterising this file. The rep can
  /// still send it — the customer's page self-heals — but the sheet says so,
  /// because a link opened ten seconds after a 40MB upload is the one case
  /// where the reader waits.
  @override
  bool get ready;

  /// `Uploaded File` (a PDF/image a manager uploaded) or `Generated Price
  /// List` (a sheet the server renders from live prices per recipient).
  @override
  @JsonKey(name: 'source_type')
  String get sourceType;

  /// True for a generated price sheet: its prices are filled in at send time
  /// for the customer it goes to, so the sheet offers a preview instead of a
  /// file. Absent on an older server, hence the default.
  @override
  bool get generated;

  /// Create a copy of SalesMaterial
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SalesMaterialImplCopyWith<_$SalesMaterialImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MaterialLibrary _$MaterialLibraryFromJson(Map<String, dynamic> json) {
  return _MaterialLibrary.fromJson(json);
}

/// @nodoc
mixin _$MaterialLibrary {
  List<SalesMaterial> get materials => throw _privateConstructorUsedError;
  @JsonKey(name: 'message_template')
  String get messageTemplate => throw _privateConstructorUsedError;
  @JsonKey(name: 'name_placeholder')
  String get namePlaceholder => throw _privateConstructorUsedError;
  @JsonKey(name: 'link_placeholder')
  String get linkPlaceholder => throw _privateConstructorUsedError;
  @JsonKey(name: 'name_fallback')
  String get nameFallback => throw _privateConstructorUsedError;

  /// Whether this user may edit a generated price sheet's template (full
  /// manager pricing access). The server enforces it again on save.
  @JsonKey(name: 'can_edit_sheets')
  bool get canEditSheets => throw _privateConstructorUsedError;

  /// Serializes this MaterialLibrary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MaterialLibrary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MaterialLibraryCopyWith<MaterialLibrary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaterialLibraryCopyWith<$Res> {
  factory $MaterialLibraryCopyWith(
    MaterialLibrary value,
    $Res Function(MaterialLibrary) then,
  ) = _$MaterialLibraryCopyWithImpl<$Res, MaterialLibrary>;
  @useResult
  $Res call({
    List<SalesMaterial> materials,
    @JsonKey(name: 'message_template') String messageTemplate,
    @JsonKey(name: 'name_placeholder') String namePlaceholder,
    @JsonKey(name: 'link_placeholder') String linkPlaceholder,
    @JsonKey(name: 'name_fallback') String nameFallback,
    @JsonKey(name: 'can_edit_sheets') bool canEditSheets,
  });
}

/// @nodoc
class _$MaterialLibraryCopyWithImpl<$Res, $Val extends MaterialLibrary>
    implements $MaterialLibraryCopyWith<$Res> {
  _$MaterialLibraryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MaterialLibrary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? materials = null,
    Object? messageTemplate = null,
    Object? namePlaceholder = null,
    Object? linkPlaceholder = null,
    Object? nameFallback = null,
    Object? canEditSheets = null,
  }) {
    return _then(
      _value.copyWith(
            materials: null == materials
                ? _value.materials
                : materials // ignore: cast_nullable_to_non_nullable
                      as List<SalesMaterial>,
            messageTemplate: null == messageTemplate
                ? _value.messageTemplate
                : messageTemplate // ignore: cast_nullable_to_non_nullable
                      as String,
            namePlaceholder: null == namePlaceholder
                ? _value.namePlaceholder
                : namePlaceholder // ignore: cast_nullable_to_non_nullable
                      as String,
            linkPlaceholder: null == linkPlaceholder
                ? _value.linkPlaceholder
                : linkPlaceholder // ignore: cast_nullable_to_non_nullable
                      as String,
            nameFallback: null == nameFallback
                ? _value.nameFallback
                : nameFallback // ignore: cast_nullable_to_non_nullable
                      as String,
            canEditSheets: null == canEditSheets
                ? _value.canEditSheets
                : canEditSheets // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MaterialLibraryImplCopyWith<$Res>
    implements $MaterialLibraryCopyWith<$Res> {
  factory _$$MaterialLibraryImplCopyWith(
    _$MaterialLibraryImpl value,
    $Res Function(_$MaterialLibraryImpl) then,
  ) = __$$MaterialLibraryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<SalesMaterial> materials,
    @JsonKey(name: 'message_template') String messageTemplate,
    @JsonKey(name: 'name_placeholder') String namePlaceholder,
    @JsonKey(name: 'link_placeholder') String linkPlaceholder,
    @JsonKey(name: 'name_fallback') String nameFallback,
    @JsonKey(name: 'can_edit_sheets') bool canEditSheets,
  });
}

/// @nodoc
class __$$MaterialLibraryImplCopyWithImpl<$Res>
    extends _$MaterialLibraryCopyWithImpl<$Res, _$MaterialLibraryImpl>
    implements _$$MaterialLibraryImplCopyWith<$Res> {
  __$$MaterialLibraryImplCopyWithImpl(
    _$MaterialLibraryImpl _value,
    $Res Function(_$MaterialLibraryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MaterialLibrary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? materials = null,
    Object? messageTemplate = null,
    Object? namePlaceholder = null,
    Object? linkPlaceholder = null,
    Object? nameFallback = null,
    Object? canEditSheets = null,
  }) {
    return _then(
      _$MaterialLibraryImpl(
        materials: null == materials
            ? _value._materials
            : materials // ignore: cast_nullable_to_non_nullable
                  as List<SalesMaterial>,
        messageTemplate: null == messageTemplate
            ? _value.messageTemplate
            : messageTemplate // ignore: cast_nullable_to_non_nullable
                  as String,
        namePlaceholder: null == namePlaceholder
            ? _value.namePlaceholder
            : namePlaceholder // ignore: cast_nullable_to_non_nullable
                  as String,
        linkPlaceholder: null == linkPlaceholder
            ? _value.linkPlaceholder
            : linkPlaceholder // ignore: cast_nullable_to_non_nullable
                  as String,
        nameFallback: null == nameFallback
            ? _value.nameFallback
            : nameFallback // ignore: cast_nullable_to_non_nullable
                  as String,
        canEditSheets: null == canEditSheets
            ? _value.canEditSheets
            : canEditSheets // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MaterialLibraryImpl extends _MaterialLibrary {
  const _$MaterialLibraryImpl({
    final List<SalesMaterial> materials = const <SalesMaterial>[],
    @JsonKey(name: 'message_template') this.messageTemplate = '',
    @JsonKey(name: 'name_placeholder') this.namePlaceholder = '{name}',
    @JsonKey(name: 'link_placeholder') this.linkPlaceholder = '{link}',
    @JsonKey(name: 'name_fallback') this.nameFallback = '',
    @JsonKey(name: 'can_edit_sheets') this.canEditSheets = false,
  }) : _materials = materials,
       super._();

  factory _$MaterialLibraryImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaterialLibraryImplFromJson(json);

  final List<SalesMaterial> _materials;
  @override
  @JsonKey()
  List<SalesMaterial> get materials {
    if (_materials is EqualUnmodifiableListView) return _materials;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_materials);
  }

  @override
  @JsonKey(name: 'message_template')
  final String messageTemplate;
  @override
  @JsonKey(name: 'name_placeholder')
  final String namePlaceholder;
  @override
  @JsonKey(name: 'link_placeholder')
  final String linkPlaceholder;
  @override
  @JsonKey(name: 'name_fallback')
  final String nameFallback;

  /// Whether this user may edit a generated price sheet's template (full
  /// manager pricing access). The server enforces it again on save.
  @override
  @JsonKey(name: 'can_edit_sheets')
  final bool canEditSheets;

  @override
  String toString() {
    return 'MaterialLibrary(materials: $materials, messageTemplate: $messageTemplate, namePlaceholder: $namePlaceholder, linkPlaceholder: $linkPlaceholder, nameFallback: $nameFallback, canEditSheets: $canEditSheets)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaterialLibraryImpl &&
            const DeepCollectionEquality().equals(
              other._materials,
              _materials,
            ) &&
            (identical(other.messageTemplate, messageTemplate) ||
                other.messageTemplate == messageTemplate) &&
            (identical(other.namePlaceholder, namePlaceholder) ||
                other.namePlaceholder == namePlaceholder) &&
            (identical(other.linkPlaceholder, linkPlaceholder) ||
                other.linkPlaceholder == linkPlaceholder) &&
            (identical(other.nameFallback, nameFallback) ||
                other.nameFallback == nameFallback) &&
            (identical(other.canEditSheets, canEditSheets) ||
                other.canEditSheets == canEditSheets));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_materials),
    messageTemplate,
    namePlaceholder,
    linkPlaceholder,
    nameFallback,
    canEditSheets,
  );

  /// Create a copy of MaterialLibrary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MaterialLibraryImplCopyWith<_$MaterialLibraryImpl> get copyWith =>
      __$$MaterialLibraryImplCopyWithImpl<_$MaterialLibraryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MaterialLibraryImplToJson(this);
  }
}

abstract class _MaterialLibrary extends MaterialLibrary {
  const factory _MaterialLibrary({
    final List<SalesMaterial> materials,
    @JsonKey(name: 'message_template') final String messageTemplate,
    @JsonKey(name: 'name_placeholder') final String namePlaceholder,
    @JsonKey(name: 'link_placeholder') final String linkPlaceholder,
    @JsonKey(name: 'name_fallback') final String nameFallback,
    @JsonKey(name: 'can_edit_sheets') final bool canEditSheets,
  }) = _$MaterialLibraryImpl;
  const _MaterialLibrary._() : super._();

  factory _MaterialLibrary.fromJson(Map<String, dynamic> json) =
      _$MaterialLibraryImpl.fromJson;

  @override
  List<SalesMaterial> get materials;
  @override
  @JsonKey(name: 'message_template')
  String get messageTemplate;
  @override
  @JsonKey(name: 'name_placeholder')
  String get namePlaceholder;
  @override
  @JsonKey(name: 'link_placeholder')
  String get linkPlaceholder;
  @override
  @JsonKey(name: 'name_fallback')
  String get nameFallback;

  /// Whether this user may edit a generated price sheet's template (full
  /// manager pricing access). The server enforces it again on save.
  @override
  @JsonKey(name: 'can_edit_sheets')
  bool get canEditSheets;

  /// Create a copy of MaterialLibrary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MaterialLibraryImplCopyWith<_$MaterialLibraryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MaterialShare _$MaterialShareFromJson(Map<String, dynamic> json) {
  return _MaterialShare.fromJson(json);
}

/// @nodoc
mixin _$MaterialShare {
  String get name => throw _privateConstructorUsedError;
  String get token => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  @JsonKey(name: 'whatsapp_url')
  String get whatsappUrl => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  String get msisdn => throw _privateConstructorUsedError;

  /// Materials still being rasterised when the link was minted.
  @JsonKey(name: 'pending_render')
  List<String> get pendingRender => throw _privateConstructorUsedError;

  /// Serializes this MaterialShare to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MaterialShare
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MaterialShareCopyWith<MaterialShare> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaterialShareCopyWith<$Res> {
  factory $MaterialShareCopyWith(
    MaterialShare value,
    $Res Function(MaterialShare) then,
  ) = _$MaterialShareCopyWithImpl<$Res, MaterialShare>;
  @useResult
  $Res call({
    String name,
    String token,
    String url,
    @JsonKey(name: 'whatsapp_url') String whatsappUrl,
    String message,
    String msisdn,
    @JsonKey(name: 'pending_render') List<String> pendingRender,
  });
}

/// @nodoc
class _$MaterialShareCopyWithImpl<$Res, $Val extends MaterialShare>
    implements $MaterialShareCopyWith<$Res> {
  _$MaterialShareCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MaterialShare
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? token = null,
    Object? url = null,
    Object? whatsappUrl = null,
    Object? message = null,
    Object? msisdn = null,
    Object? pendingRender = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            token: null == token
                ? _value.token
                : token // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            whatsappUrl: null == whatsappUrl
                ? _value.whatsappUrl
                : whatsappUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            msisdn: null == msisdn
                ? _value.msisdn
                : msisdn // ignore: cast_nullable_to_non_nullable
                      as String,
            pendingRender: null == pendingRender
                ? _value.pendingRender
                : pendingRender // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MaterialShareImplCopyWith<$Res>
    implements $MaterialShareCopyWith<$Res> {
  factory _$$MaterialShareImplCopyWith(
    _$MaterialShareImpl value,
    $Res Function(_$MaterialShareImpl) then,
  ) = __$$MaterialShareImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String token,
    String url,
    @JsonKey(name: 'whatsapp_url') String whatsappUrl,
    String message,
    String msisdn,
    @JsonKey(name: 'pending_render') List<String> pendingRender,
  });
}

/// @nodoc
class __$$MaterialShareImplCopyWithImpl<$Res>
    extends _$MaterialShareCopyWithImpl<$Res, _$MaterialShareImpl>
    implements _$$MaterialShareImplCopyWith<$Res> {
  __$$MaterialShareImplCopyWithImpl(
    _$MaterialShareImpl _value,
    $Res Function(_$MaterialShareImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MaterialShare
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? token = null,
    Object? url = null,
    Object? whatsappUrl = null,
    Object? message = null,
    Object? msisdn = null,
    Object? pendingRender = null,
  }) {
    return _then(
      _$MaterialShareImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        token: null == token
            ? _value.token
            : token // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        whatsappUrl: null == whatsappUrl
            ? _value.whatsappUrl
            : whatsappUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        msisdn: null == msisdn
            ? _value.msisdn
            : msisdn // ignore: cast_nullable_to_non_nullable
                  as String,
        pendingRender: null == pendingRender
            ? _value._pendingRender
            : pendingRender // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MaterialShareImpl implements _MaterialShare {
  const _$MaterialShareImpl({
    this.name = '',
    this.token = '',
    this.url = '',
    @JsonKey(name: 'whatsapp_url') this.whatsappUrl = '',
    this.message = '',
    this.msisdn = '',
    @JsonKey(name: 'pending_render')
    final List<String> pendingRender = const <String>[],
  }) : _pendingRender = pendingRender;

  factory _$MaterialShareImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaterialShareImplFromJson(json);

  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String token;
  @override
  @JsonKey()
  final String url;
  @override
  @JsonKey(name: 'whatsapp_url')
  final String whatsappUrl;
  @override
  @JsonKey()
  final String message;
  @override
  @JsonKey()
  final String msisdn;

  /// Materials still being rasterised when the link was minted.
  final List<String> _pendingRender;

  /// Materials still being rasterised when the link was minted.
  @override
  @JsonKey(name: 'pending_render')
  List<String> get pendingRender {
    if (_pendingRender is EqualUnmodifiableListView) return _pendingRender;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pendingRender);
  }

  @override
  String toString() {
    return 'MaterialShare(name: $name, token: $token, url: $url, whatsappUrl: $whatsappUrl, message: $message, msisdn: $msisdn, pendingRender: $pendingRender)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaterialShareImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.whatsappUrl, whatsappUrl) ||
                other.whatsappUrl == whatsappUrl) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.msisdn, msisdn) || other.msisdn == msisdn) &&
            const DeepCollectionEquality().equals(
              other._pendingRender,
              _pendingRender,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    token,
    url,
    whatsappUrl,
    message,
    msisdn,
    const DeepCollectionEquality().hash(_pendingRender),
  );

  /// Create a copy of MaterialShare
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MaterialShareImplCopyWith<_$MaterialShareImpl> get copyWith =>
      __$$MaterialShareImplCopyWithImpl<_$MaterialShareImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MaterialShareImplToJson(this);
  }
}

abstract class _MaterialShare implements MaterialShare {
  const factory _MaterialShare({
    final String name,
    final String token,
    final String url,
    @JsonKey(name: 'whatsapp_url') final String whatsappUrl,
    final String message,
    final String msisdn,
    @JsonKey(name: 'pending_render') final List<String> pendingRender,
  }) = _$MaterialShareImpl;

  factory _MaterialShare.fromJson(Map<String, dynamic> json) =
      _$MaterialShareImpl.fromJson;

  @override
  String get name;
  @override
  String get token;
  @override
  String get url;
  @override
  @JsonKey(name: 'whatsapp_url')
  String get whatsappUrl;
  @override
  String get message;
  @override
  String get msisdn;

  /// Materials still being rasterised when the link was minted.
  @override
  @JsonKey(name: 'pending_render')
  List<String> get pendingRender;

  /// Create a copy of MaterialShare
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MaterialShareImplCopyWith<_$MaterialShareImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MaterialShareSummary _$MaterialShareSummaryFromJson(Map<String, dynamic> json) {
  return _MaterialShareSummary.fromJson(json);
}

/// @nodoc
mixin _$MaterialShareSummary {
  String get name => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  @JsonKey(name: 'contact_name')
  String get contactName => throw _privateConstructorUsedError;
  @JsonKey(name: 'contact_phone')
  String get contactPhone => throw _privateConstructorUsedError;
  String get channel => throw _privateConstructorUsedError;
  @JsonKey(name: 'sent_by')
  String get sentBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'sent_on')
  String? get sentOn => throw _privateConstructorUsedError;
  @JsonKey(name: 'view_count')
  int get viewCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'first_viewed_on')
  String? get firstViewedOn => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_viewed_on')
  String? get lastViewedOn => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  List<String> get titles =>
      throw _privateConstructorUsedError; // What the reader's latest visit looked like. All of it is observable
  // without asking them for a permission: device/OS/browser come from the
  // User-Agent server-side, the rest from the page's own end-of-session
  // beacon. Absent on shares sent before this shipped, hence the defaults.
  @JsonKey(name: 'device_type')
  String get deviceType => throw _privateConstructorUsedError;
  String get os => throw _privateConstructorUsedError;
  String get browser => throw _privateConstructorUsedError;
  int get seconds => throw _privateConstructorUsedError;
  @JsonKey(name: 'pages_viewed')
  int get pagesViewed => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_zoom')
  double get maxZoom => throw _privateConstructorUsedError;
  bool get downloaded => throw _privateConstructorUsedError;

  /// Serializes this MaterialShareSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MaterialShareSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MaterialShareSummaryCopyWith<MaterialShareSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaterialShareSummaryCopyWith<$Res> {
  factory $MaterialShareSummaryCopyWith(
    MaterialShareSummary value,
    $Res Function(MaterialShareSummary) then,
  ) = _$MaterialShareSummaryCopyWithImpl<$Res, MaterialShareSummary>;
  @useResult
  $Res call({
    String name,
    String url,
    @JsonKey(name: 'contact_name') String contactName,
    @JsonKey(name: 'contact_phone') String contactPhone,
    String channel,
    @JsonKey(name: 'sent_by') String sentBy,
    @JsonKey(name: 'sent_on') String? sentOn,
    @JsonKey(name: 'view_count') int viewCount,
    @JsonKey(name: 'first_viewed_on') String? firstViewedOn,
    @JsonKey(name: 'last_viewed_on') String? lastViewedOn,
    String message,
    List<String> titles,
    @JsonKey(name: 'device_type') String deviceType,
    String os,
    String browser,
    int seconds,
    @JsonKey(name: 'pages_viewed') int pagesViewed,
    @JsonKey(name: 'max_zoom') double maxZoom,
    bool downloaded,
  });
}

/// @nodoc
class _$MaterialShareSummaryCopyWithImpl<
  $Res,
  $Val extends MaterialShareSummary
>
    implements $MaterialShareSummaryCopyWith<$Res> {
  _$MaterialShareSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MaterialShareSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? url = null,
    Object? contactName = null,
    Object? contactPhone = null,
    Object? channel = null,
    Object? sentBy = null,
    Object? sentOn = freezed,
    Object? viewCount = null,
    Object? firstViewedOn = freezed,
    Object? lastViewedOn = freezed,
    Object? message = null,
    Object? titles = null,
    Object? deviceType = null,
    Object? os = null,
    Object? browser = null,
    Object? seconds = null,
    Object? pagesViewed = null,
    Object? maxZoom = null,
    Object? downloaded = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            contactName: null == contactName
                ? _value.contactName
                : contactName // ignore: cast_nullable_to_non_nullable
                      as String,
            contactPhone: null == contactPhone
                ? _value.contactPhone
                : contactPhone // ignore: cast_nullable_to_non_nullable
                      as String,
            channel: null == channel
                ? _value.channel
                : channel // ignore: cast_nullable_to_non_nullable
                      as String,
            sentBy: null == sentBy
                ? _value.sentBy
                : sentBy // ignore: cast_nullable_to_non_nullable
                      as String,
            sentOn: freezed == sentOn
                ? _value.sentOn
                : sentOn // ignore: cast_nullable_to_non_nullable
                      as String?,
            viewCount: null == viewCount
                ? _value.viewCount
                : viewCount // ignore: cast_nullable_to_non_nullable
                      as int,
            firstViewedOn: freezed == firstViewedOn
                ? _value.firstViewedOn
                : firstViewedOn // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastViewedOn: freezed == lastViewedOn
                ? _value.lastViewedOn
                : lastViewedOn // ignore: cast_nullable_to_non_nullable
                      as String?,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            titles: null == titles
                ? _value.titles
                : titles // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            deviceType: null == deviceType
                ? _value.deviceType
                : deviceType // ignore: cast_nullable_to_non_nullable
                      as String,
            os: null == os
                ? _value.os
                : os // ignore: cast_nullable_to_non_nullable
                      as String,
            browser: null == browser
                ? _value.browser
                : browser // ignore: cast_nullable_to_non_nullable
                      as String,
            seconds: null == seconds
                ? _value.seconds
                : seconds // ignore: cast_nullable_to_non_nullable
                      as int,
            pagesViewed: null == pagesViewed
                ? _value.pagesViewed
                : pagesViewed // ignore: cast_nullable_to_non_nullable
                      as int,
            maxZoom: null == maxZoom
                ? _value.maxZoom
                : maxZoom // ignore: cast_nullable_to_non_nullable
                      as double,
            downloaded: null == downloaded
                ? _value.downloaded
                : downloaded // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MaterialShareSummaryImplCopyWith<$Res>
    implements $MaterialShareSummaryCopyWith<$Res> {
  factory _$$MaterialShareSummaryImplCopyWith(
    _$MaterialShareSummaryImpl value,
    $Res Function(_$MaterialShareSummaryImpl) then,
  ) = __$$MaterialShareSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String url,
    @JsonKey(name: 'contact_name') String contactName,
    @JsonKey(name: 'contact_phone') String contactPhone,
    String channel,
    @JsonKey(name: 'sent_by') String sentBy,
    @JsonKey(name: 'sent_on') String? sentOn,
    @JsonKey(name: 'view_count') int viewCount,
    @JsonKey(name: 'first_viewed_on') String? firstViewedOn,
    @JsonKey(name: 'last_viewed_on') String? lastViewedOn,
    String message,
    List<String> titles,
    @JsonKey(name: 'device_type') String deviceType,
    String os,
    String browser,
    int seconds,
    @JsonKey(name: 'pages_viewed') int pagesViewed,
    @JsonKey(name: 'max_zoom') double maxZoom,
    bool downloaded,
  });
}

/// @nodoc
class __$$MaterialShareSummaryImplCopyWithImpl<$Res>
    extends _$MaterialShareSummaryCopyWithImpl<$Res, _$MaterialShareSummaryImpl>
    implements _$$MaterialShareSummaryImplCopyWith<$Res> {
  __$$MaterialShareSummaryImplCopyWithImpl(
    _$MaterialShareSummaryImpl _value,
    $Res Function(_$MaterialShareSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MaterialShareSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? url = null,
    Object? contactName = null,
    Object? contactPhone = null,
    Object? channel = null,
    Object? sentBy = null,
    Object? sentOn = freezed,
    Object? viewCount = null,
    Object? firstViewedOn = freezed,
    Object? lastViewedOn = freezed,
    Object? message = null,
    Object? titles = null,
    Object? deviceType = null,
    Object? os = null,
    Object? browser = null,
    Object? seconds = null,
    Object? pagesViewed = null,
    Object? maxZoom = null,
    Object? downloaded = null,
  }) {
    return _then(
      _$MaterialShareSummaryImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        contactName: null == contactName
            ? _value.contactName
            : contactName // ignore: cast_nullable_to_non_nullable
                  as String,
        contactPhone: null == contactPhone
            ? _value.contactPhone
            : contactPhone // ignore: cast_nullable_to_non_nullable
                  as String,
        channel: null == channel
            ? _value.channel
            : channel // ignore: cast_nullable_to_non_nullable
                  as String,
        sentBy: null == sentBy
            ? _value.sentBy
            : sentBy // ignore: cast_nullable_to_non_nullable
                  as String,
        sentOn: freezed == sentOn
            ? _value.sentOn
            : sentOn // ignore: cast_nullable_to_non_nullable
                  as String?,
        viewCount: null == viewCount
            ? _value.viewCount
            : viewCount // ignore: cast_nullable_to_non_nullable
                  as int,
        firstViewedOn: freezed == firstViewedOn
            ? _value.firstViewedOn
            : firstViewedOn // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastViewedOn: freezed == lastViewedOn
            ? _value.lastViewedOn
            : lastViewedOn // ignore: cast_nullable_to_non_nullable
                  as String?,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        titles: null == titles
            ? _value._titles
            : titles // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        deviceType: null == deviceType
            ? _value.deviceType
            : deviceType // ignore: cast_nullable_to_non_nullable
                  as String,
        os: null == os
            ? _value.os
            : os // ignore: cast_nullable_to_non_nullable
                  as String,
        browser: null == browser
            ? _value.browser
            : browser // ignore: cast_nullable_to_non_nullable
                  as String,
        seconds: null == seconds
            ? _value.seconds
            : seconds // ignore: cast_nullable_to_non_nullable
                  as int,
        pagesViewed: null == pagesViewed
            ? _value.pagesViewed
            : pagesViewed // ignore: cast_nullable_to_non_nullable
                  as int,
        maxZoom: null == maxZoom
            ? _value.maxZoom
            : maxZoom // ignore: cast_nullable_to_non_nullable
                  as double,
        downloaded: null == downloaded
            ? _value.downloaded
            : downloaded // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MaterialShareSummaryImpl extends _MaterialShareSummary {
  const _$MaterialShareSummaryImpl({
    this.name = '',
    this.url = '',
    @JsonKey(name: 'contact_name') this.contactName = '',
    @JsonKey(name: 'contact_phone') this.contactPhone = '',
    this.channel = '',
    @JsonKey(name: 'sent_by') this.sentBy = '',
    @JsonKey(name: 'sent_on') this.sentOn,
    @JsonKey(name: 'view_count') this.viewCount = 0,
    @JsonKey(name: 'first_viewed_on') this.firstViewedOn,
    @JsonKey(name: 'last_viewed_on') this.lastViewedOn,
    this.message = '',
    final List<String> titles = const <String>[],
    @JsonKey(name: 'device_type') this.deviceType = '',
    this.os = '',
    this.browser = '',
    this.seconds = 0,
    @JsonKey(name: 'pages_viewed') this.pagesViewed = 0,
    @JsonKey(name: 'max_zoom') this.maxZoom = 0.0,
    this.downloaded = false,
  }) : _titles = titles,
       super._();

  factory _$MaterialShareSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaterialShareSummaryImplFromJson(json);

  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String url;
  @override
  @JsonKey(name: 'contact_name')
  final String contactName;
  @override
  @JsonKey(name: 'contact_phone')
  final String contactPhone;
  @override
  @JsonKey()
  final String channel;
  @override
  @JsonKey(name: 'sent_by')
  final String sentBy;
  @override
  @JsonKey(name: 'sent_on')
  final String? sentOn;
  @override
  @JsonKey(name: 'view_count')
  final int viewCount;
  @override
  @JsonKey(name: 'first_viewed_on')
  final String? firstViewedOn;
  @override
  @JsonKey(name: 'last_viewed_on')
  final String? lastViewedOn;
  @override
  @JsonKey()
  final String message;
  final List<String> _titles;
  @override
  @JsonKey()
  List<String> get titles {
    if (_titles is EqualUnmodifiableListView) return _titles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_titles);
  }

  // What the reader's latest visit looked like. All of it is observable
  // without asking them for a permission: device/OS/browser come from the
  // User-Agent server-side, the rest from the page's own end-of-session
  // beacon. Absent on shares sent before this shipped, hence the defaults.
  @override
  @JsonKey(name: 'device_type')
  final String deviceType;
  @override
  @JsonKey()
  final String os;
  @override
  @JsonKey()
  final String browser;
  @override
  @JsonKey()
  final int seconds;
  @override
  @JsonKey(name: 'pages_viewed')
  final int pagesViewed;
  @override
  @JsonKey(name: 'max_zoom')
  final double maxZoom;
  @override
  @JsonKey()
  final bool downloaded;

  @override
  String toString() {
    return 'MaterialShareSummary(name: $name, url: $url, contactName: $contactName, contactPhone: $contactPhone, channel: $channel, sentBy: $sentBy, sentOn: $sentOn, viewCount: $viewCount, firstViewedOn: $firstViewedOn, lastViewedOn: $lastViewedOn, message: $message, titles: $titles, deviceType: $deviceType, os: $os, browser: $browser, seconds: $seconds, pagesViewed: $pagesViewed, maxZoom: $maxZoom, downloaded: $downloaded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaterialShareSummaryImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.contactName, contactName) ||
                other.contactName == contactName) &&
            (identical(other.contactPhone, contactPhone) ||
                other.contactPhone == contactPhone) &&
            (identical(other.channel, channel) || other.channel == channel) &&
            (identical(other.sentBy, sentBy) || other.sentBy == sentBy) &&
            (identical(other.sentOn, sentOn) || other.sentOn == sentOn) &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.firstViewedOn, firstViewedOn) ||
                other.firstViewedOn == firstViewedOn) &&
            (identical(other.lastViewedOn, lastViewedOn) ||
                other.lastViewedOn == lastViewedOn) &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other._titles, _titles) &&
            (identical(other.deviceType, deviceType) ||
                other.deviceType == deviceType) &&
            (identical(other.os, os) || other.os == os) &&
            (identical(other.browser, browser) || other.browser == browser) &&
            (identical(other.seconds, seconds) || other.seconds == seconds) &&
            (identical(other.pagesViewed, pagesViewed) ||
                other.pagesViewed == pagesViewed) &&
            (identical(other.maxZoom, maxZoom) || other.maxZoom == maxZoom) &&
            (identical(other.downloaded, downloaded) ||
                other.downloaded == downloaded));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    name,
    url,
    contactName,
    contactPhone,
    channel,
    sentBy,
    sentOn,
    viewCount,
    firstViewedOn,
    lastViewedOn,
    message,
    const DeepCollectionEquality().hash(_titles),
    deviceType,
    os,
    browser,
    seconds,
    pagesViewed,
    maxZoom,
    downloaded,
  ]);

  /// Create a copy of MaterialShareSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MaterialShareSummaryImplCopyWith<_$MaterialShareSummaryImpl>
  get copyWith =>
      __$$MaterialShareSummaryImplCopyWithImpl<_$MaterialShareSummaryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MaterialShareSummaryImplToJson(this);
  }
}

abstract class _MaterialShareSummary extends MaterialShareSummary {
  const factory _MaterialShareSummary({
    final String name,
    final String url,
    @JsonKey(name: 'contact_name') final String contactName,
    @JsonKey(name: 'contact_phone') final String contactPhone,
    final String channel,
    @JsonKey(name: 'sent_by') final String sentBy,
    @JsonKey(name: 'sent_on') final String? sentOn,
    @JsonKey(name: 'view_count') final int viewCount,
    @JsonKey(name: 'first_viewed_on') final String? firstViewedOn,
    @JsonKey(name: 'last_viewed_on') final String? lastViewedOn,
    final String message,
    final List<String> titles,
    @JsonKey(name: 'device_type') final String deviceType,
    final String os,
    final String browser,
    final int seconds,
    @JsonKey(name: 'pages_viewed') final int pagesViewed,
    @JsonKey(name: 'max_zoom') final double maxZoom,
    final bool downloaded,
  }) = _$MaterialShareSummaryImpl;
  const _MaterialShareSummary._() : super._();

  factory _MaterialShareSummary.fromJson(Map<String, dynamic> json) =
      _$MaterialShareSummaryImpl.fromJson;

  @override
  String get name;
  @override
  String get url;
  @override
  @JsonKey(name: 'contact_name')
  String get contactName;
  @override
  @JsonKey(name: 'contact_phone')
  String get contactPhone;
  @override
  String get channel;
  @override
  @JsonKey(name: 'sent_by')
  String get sentBy;
  @override
  @JsonKey(name: 'sent_on')
  String? get sentOn;
  @override
  @JsonKey(name: 'view_count')
  int get viewCount;
  @override
  @JsonKey(name: 'first_viewed_on')
  String? get firstViewedOn;
  @override
  @JsonKey(name: 'last_viewed_on')
  String? get lastViewedOn;
  @override
  String get message;
  @override
  List<String> get titles; // What the reader's latest visit looked like. All of it is observable
  // without asking them for a permission: device/OS/browser come from the
  // User-Agent server-side, the rest from the page's own end-of-session
  // beacon. Absent on shares sent before this shipped, hence the defaults.
  @override
  @JsonKey(name: 'device_type')
  String get deviceType;
  @override
  String get os;
  @override
  String get browser;
  @override
  int get seconds;
  @override
  @JsonKey(name: 'pages_viewed')
  int get pagesViewed;
  @override
  @JsonKey(name: 'max_zoom')
  double get maxZoom;
  @override
  bool get downloaded;

  /// Create a copy of MaterialShareSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MaterialShareSummaryImplCopyWith<_$MaterialShareSummaryImpl>
  get copyWith => throw _privateConstructorUsedError;
}
