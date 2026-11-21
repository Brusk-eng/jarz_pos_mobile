// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_sheet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PriceSheetPageImpl _$$PriceSheetPageImplFromJson(Map<String, dynamic> json) =>
    _$PriceSheetPageImpl(
      thumb: json['thumb'] as String? ?? '',
      screen: json['screen'] as String? ?? '',
      full: json['full'] as String? ?? '',
      w: json['w'] == null ? 0 : const _IntConverter().fromJson(json['w']),
      h: json['h'] == null ? 0 : const _IntConverter().fromJson(json['h']),
    );

Map<String, dynamic> _$$PriceSheetPageImplToJson(
  _$PriceSheetPageImpl instance,
) => <String, dynamic>{
  'thumb': instance.thumb,
  'screen': instance.screen,
  'full': instance.full,
  'w': const _IntConverter().toJson(instance.w),
  'h': const _IntConverter().toJson(instance.h),
};

_$PriceSheetCellImpl _$$PriceSheetCellImplFromJson(Map<String, dynamic> json) =>
    _$PriceSheetCellImpl(
      size: json['size'] as String? ?? '',
      rate: const _NullableDoubleConverter().fromJson(json['rate']),
      normalRate: const _NullableDoubleConverter().fromJson(
        json['normal_rate'],
      ),
      isDeal: json['is_deal'] == null
          ? false
          : const _BoolConverter().fromJson(json['is_deal']),
    );

Map<String, dynamic> _$$PriceSheetCellImplToJson(
  _$PriceSheetCellImpl instance,
) => <String, dynamic>{
  'size': instance.size,
  'rate': const _NullableDoubleConverter().toJson(instance.rate),
  'normal_rate': const _NullableDoubleConverter().toJson(instance.normalRate),
  'is_deal': const _BoolConverter().toJson(instance.isDeal),
};

_$PriceSheetRowImpl _$$PriceSheetRowImplFromJson(Map<String, dynamic> json) =>
    _$PriceSheetRowImpl(
      flavour: json['flavour'] as String? ?? '',
      label: json['label'] as String? ?? '',
      cells:
          (json['cells'] as List<dynamic>?)
              ?.map((e) => PriceSheetCell.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PriceSheetCell>[],
    );

Map<String, dynamic> _$$PriceSheetRowImplToJson(_$PriceSheetRowImpl instance) =>
    <String, dynamic>{
      'flavour': instance.flavour,
      'label': instance.label,
      'cells': instance.cells,
    };

_$PriceSheetTermImpl _$$PriceSheetTermImplFromJson(Map<String, dynamic> json) =>
    _$PriceSheetTermImpl(
      label: const _NullableStringConverter().fromJson(json['label']),
      text: json['text'] as String? ?? '',
    );

Map<String, dynamic> _$$PriceSheetTermImplToJson(
  _$PriceSheetTermImpl instance,
) => <String, dynamic>{
  'label': const _NullableStringConverter().toJson(instance.label),
  'text': instance.text,
};

_$PriceSheetDataImpl _$$PriceSheetDataImplFromJson(Map<String, dynamic> json) =>
    _$PriceSheetDataImpl(
      heading: json['heading'] as String? ?? '',
      customerName: const _NullableStringConverter().fromJson(
        json['customer_name'],
      ),
      priceList: json['price_list'] as String? ?? '',
      currency: json['currency'] as String? ?? '',
      asOf: json['as_of'] as String? ?? '',
      sizes: json['sizes'] == null
          ? const <String>[]
          : const _StringListConverter().fromJson(json['sizes']),
      rows:
          (json['rows'] as List<dynamic>?)
              ?.map((e) => PriceSheetRow.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PriceSheetRow>[],
      dealUntil: const _NullableStringConverter().fromJson(json['deal_until']),
      terms:
          (json['terms'] as List<dynamic>?)
              ?.map((e) => PriceSheetTerm.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PriceSheetTerm>[],
      footer: json['footer'] as String? ?? '',
    );

Map<String, dynamic> _$$PriceSheetDataImplToJson(
  _$PriceSheetDataImpl instance,
) => <String, dynamic>{
  'heading': instance.heading,
  'customer_name': const _NullableStringConverter().toJson(
    instance.customerName,
  ),
  'price_list': instance.priceList,
  'currency': instance.currency,
  'as_of': instance.asOf,
  'sizes': const _StringListConverter().toJson(instance.sizes),
  'rows': instance.rows,
  'deal_until': const _NullableStringConverter().toJson(instance.dealUntil),
  'terms': instance.terms,
  'footer': instance.footer,
};

_$PriceSheetPreviewImpl _$$PriceSheetPreviewImplFromJson(
  Map<String, dynamic> json,
) => _$PriceSheetPreviewImpl(
  pdfUrl: json['pdf_url'] as String? ?? '',
  pages:
      (json['pages'] as List<dynamic>?)
          ?.map((e) => PriceSheetPage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PriceSheetPage>[],
  sheet: json['sheet'] == null
      ? const PriceSheetData()
      : PriceSheetData.fromJson(json['sheet'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$PriceSheetPreviewImplToJson(
  _$PriceSheetPreviewImpl instance,
) => <String, dynamic>{
  'pdf_url': instance.pdfUrl,
  'pages': instance.pages,
  'sheet': instance.sheet,
};

_$PriceSheetTemplateRowImpl _$$PriceSheetTemplateRowImplFromJson(
  Map<String, dynamic> json,
) => _$PriceSheetTemplateRowImpl(
  flavour: json['flavour'] as String? ?? '',
  label: json['label'] as String? ?? '',
  enabled: json['enabled'] == null
      ? true
      : const _BoolConverter().fromJson(json['enabled']),
);

Map<String, dynamic> _$$PriceSheetTemplateRowImplToJson(
  _$PriceSheetTemplateRowImpl instance,
) => <String, dynamic>{
  'flavour': instance.flavour,
  'label': instance.label,
  'enabled': const _BoolConverter().toJson(instance.enabled),
};

_$PriceSheetTemplateImpl _$$PriceSheetTemplateImplFromJson(
  Map<String, dynamic> json,
) => _$PriceSheetTemplateImpl(
  name: json['name'] as String? ?? '',
  title: json['title'] as String? ?? '',
  titleAr: json['title_ar'] as String? ?? '',
  enabled: json['enabled'] == null
      ? true
      : const _BoolConverter().fromJson(json['enabled']),
  isDefault: json['is_default'] == null
      ? false
      : const _BoolConverter().fromJson(json['is_default']),
  sheetHeading: json['sheet_heading'] as String? ?? '',
  sheetPriceList: const _NullableStringConverter().fromJson(
    json['sheet_price_list'],
  ),
  sheetSizes: json['sheet_sizes'] == null
      ? const <String>[]
      : const _StringListConverter().fromJson(json['sheet_sizes']),
  sheetShowDeals: json['sheet_show_deals'] == null
      ? true
      : const _BoolConverter().fromJson(json['sheet_show_deals']),
  sheetTerms: json['sheet_terms'] == null
      ? const <String>[]
      : const _LinesConverter().fromJson(json['sheet_terms']),
  sheetFooter: json['sheet_footer'] as String? ?? '',
  rows:
      (json['rows'] as List<dynamic>?)
          ?.map(
            (e) => PriceSheetTemplateRow.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <PriceSheetTemplateRow>[],
  availableFlavours: json['available_flavours'] == null
      ? const <String>[]
      : const _StringListConverter().fromJson(json['available_flavours']),
  availableSizes: json['available_sizes'] == null
      ? const <String>[]
      : const _StringListConverter().fromJson(json['available_sizes']),
  priceLists: json['price_lists'] == null
      ? const <String>[]
      : const _StringListConverter().fromJson(json['price_lists']),
  canEdit: json['can_edit'] == null
      ? false
      : const _BoolConverter().fromJson(json['can_edit']),
);

Map<String, dynamic> _$$PriceSheetTemplateImplToJson(
  _$PriceSheetTemplateImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'title': instance.title,
  'title_ar': instance.titleAr,
  'enabled': const _BoolConverter().toJson(instance.enabled),
  'is_default': const _BoolConverter().toJson(instance.isDefault),
  'sheet_heading': instance.sheetHeading,
  'sheet_price_list': const _NullableStringConverter().toJson(
    instance.sheetPriceList,
  ),
  'sheet_sizes': const _StringListConverter().toJson(instance.sheetSizes),
  'sheet_show_deals': const _BoolConverter().toJson(instance.sheetShowDeals),
  'sheet_terms': const _LinesConverter().toJson(instance.sheetTerms),
  'sheet_footer': instance.sheetFooter,
  'rows': instance.rows,
  'available_flavours': const _StringListConverter().toJson(
    instance.availableFlavours,
  ),
  'available_sizes': const _StringListConverter().toJson(
    instance.availableSizes,
  ),
  'price_lists': const _StringListConverter().toJson(instance.priceLists),
  'can_edit': const _BoolConverter().toJson(instance.canEdit),
};
