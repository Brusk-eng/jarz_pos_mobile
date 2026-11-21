// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_material.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SalesMaterialImpl _$$SalesMaterialImplFromJson(Map<String, dynamic> json) =>
    _$SalesMaterialImpl(
      name: json['name'] as String,
      title: json['title'] as String? ?? '',
      titleAr: json['title_ar'] as String? ?? '',
      displayTitle: json['display_title'] as String? ?? '',
      materialType: json['material_type'] as String? ?? '',
      downloadUrl: json['download_url'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      pageCount: (json['page_count'] as num?)?.toInt() ?? 0,
      ready: json['ready'] as bool? ?? false,
      sourceType: json['source_type'] as String? ?? 'Uploaded File',
      generated: json['generated'] as bool? ?? false,
    );

Map<String, dynamic> _$$SalesMaterialImplToJson(_$SalesMaterialImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'title': instance.title,
      'title_ar': instance.titleAr,
      'display_title': instance.displayTitle,
      'material_type': instance.materialType,
      'download_url': instance.downloadUrl,
      'is_default': instance.isDefault,
      'page_count': instance.pageCount,
      'ready': instance.ready,
      'source_type': instance.sourceType,
      'generated': instance.generated,
    };

_$MaterialLibraryImpl _$$MaterialLibraryImplFromJson(
  Map<String, dynamic> json,
) => _$MaterialLibraryImpl(
  materials:
      (json['materials'] as List<dynamic>?)
          ?.map((e) => SalesMaterial.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SalesMaterial>[],
  messageTemplate: json['message_template'] as String? ?? '',
  namePlaceholder: json['name_placeholder'] as String? ?? '{name}',
  linkPlaceholder: json['link_placeholder'] as String? ?? '{link}',
  nameFallback: json['name_fallback'] as String? ?? '',
  canEditSheets: json['can_edit_sheets'] as bool? ?? false,
);

Map<String, dynamic> _$$MaterialLibraryImplToJson(
  _$MaterialLibraryImpl instance,
) => <String, dynamic>{
  'materials': instance.materials,
  'message_template': instance.messageTemplate,
  'name_placeholder': instance.namePlaceholder,
  'link_placeholder': instance.linkPlaceholder,
  'name_fallback': instance.nameFallback,
  'can_edit_sheets': instance.canEditSheets,
};

_$MaterialShareImpl _$$MaterialShareImplFromJson(Map<String, dynamic> json) =>
    _$MaterialShareImpl(
      name: json['name'] as String? ?? '',
      token: json['token'] as String? ?? '',
      url: json['url'] as String? ?? '',
      whatsappUrl: json['whatsapp_url'] as String? ?? '',
      message: json['message'] as String? ?? '',
      msisdn: json['msisdn'] as String? ?? '',
      pendingRender:
          (json['pending_render'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$$MaterialShareImplToJson(_$MaterialShareImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'token': instance.token,
      'url': instance.url,
      'whatsapp_url': instance.whatsappUrl,
      'message': instance.message,
      'msisdn': instance.msisdn,
      'pending_render': instance.pendingRender,
    };

_$MaterialShareSummaryImpl _$$MaterialShareSummaryImplFromJson(
  Map<String, dynamic> json,
) => _$MaterialShareSummaryImpl(
  name: json['name'] as String? ?? '',
  url: json['url'] as String? ?? '',
  contactName: json['contact_name'] as String? ?? '',
  contactPhone: json['contact_phone'] as String? ?? '',
  channel: json['channel'] as String? ?? '',
  sentBy: json['sent_by'] as String? ?? '',
  sentOn: json['sent_on'] as String?,
  viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
  firstViewedOn: json['first_viewed_on'] as String?,
  lastViewedOn: json['last_viewed_on'] as String?,
  message: json['message'] as String? ?? '',
  titles:
      (json['titles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  deviceType: json['device_type'] as String? ?? '',
  os: json['os'] as String? ?? '',
  browser: json['browser'] as String? ?? '',
  seconds: (json['seconds'] as num?)?.toInt() ?? 0,
  pagesViewed: (json['pages_viewed'] as num?)?.toInt() ?? 0,
  maxZoom: (json['max_zoom'] as num?)?.toDouble() ?? 0.0,
  downloaded: json['downloaded'] as bool? ?? false,
);

Map<String, dynamic> _$$MaterialShareSummaryImplToJson(
  _$MaterialShareSummaryImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'url': instance.url,
  'contact_name': instance.contactName,
  'contact_phone': instance.contactPhone,
  'channel': instance.channel,
  'sent_by': instance.sentBy,
  'sent_on': instance.sentOn,
  'view_count': instance.viewCount,
  'first_viewed_on': instance.firstViewedOn,
  'last_viewed_on': instance.lastViewedOn,
  'message': instance.message,
  'titles': instance.titles,
  'device_type': instance.deviceType,
  'os': instance.os,
  'browser': instance.browser,
  'seconds': instance.seconds,
  'pages_viewed': instance.pagesViewed,
  'max_zoom': instance.maxZoom,
  'downloaded': instance.downloaded,
};
