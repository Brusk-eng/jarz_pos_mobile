// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_share_preview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PublicShareItemImpl _$$PublicShareItemImplFromJson(
  Map<String, dynamic> json,
) => _$PublicShareItemImpl(
  title: json['title'] == null
      ? ''
      : const _StringConverter().fromJson(json['title']),
  type: json['type'] == null
      ? ''
      : const _StringConverter().fromJson(json['type']),
  downloadUrl: json['download_url'] == null
      ? ''
      : const _StringConverter().fromJson(json['download_url']),
  pages:
      (json['pages'] as List<dynamic>?)
          ?.map((e) => PriceSheetPage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PriceSheetPage>[],
);

Map<String, dynamic> _$$PublicShareItemImplToJson(
  _$PublicShareItemImpl instance,
) => <String, dynamic>{
  'title': const _StringConverter().toJson(instance.title),
  'type': const _StringConverter().toJson(instance.type),
  'download_url': const _StringConverter().toJson(instance.downloadUrl),
  'pages': instance.pages,
};

_$MaterialSharePreviewImpl _$$MaterialSharePreviewImplFromJson(
  Map<String, dynamic> json,
) => _$MaterialSharePreviewImpl(
  message: json['message'] == null
      ? ''
      : const _StringConverter().fromJson(json['message']),
  linkPlaceholderUrl: json['link_placeholder_url'] == null
      ? ''
      : const _StringConverter().fromJson(json['link_placeholder_url']),
  greetingName: const _NullableStringConverter().fromJson(
    json['greeting_name'],
  ),
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => PublicShareItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PublicShareItem>[],
  materialNames:
      (json['material_names'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$$MaterialSharePreviewImplToJson(
  _$MaterialSharePreviewImpl instance,
) => <String, dynamic>{
  'message': const _StringConverter().toJson(instance.message),
  'link_placeholder_url': const _StringConverter().toJson(
    instance.linkPlaceholderUrl,
  ),
  'greeting_name': const _NullableStringConverter().toJson(
    instance.greetingName,
  ),
  'items': instance.items,
  'material_names': instance.materialNames,
};
