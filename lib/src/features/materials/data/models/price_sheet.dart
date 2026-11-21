// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'price_sheet.freezed.dart';
part 'price_sheet.g.dart';

// -- Lenient scalar converters ----------------------------------------------
// Frappe hands Check fields back as 0/1 and numbers as strings on some query
// paths, so every flag and rate here is read through these rather than a
// strict `as bool` cast that would throw on a perfectly good payload.

bool _looseBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final text = value.trim().toLowerCase();
    return text == '1' || text == 'true' || text == 'yes';
  }
  return false;
}

double? _looseDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

int _looseInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final text = value.trim();
    return int.tryParse(text) ?? double.tryParse(text)?.toInt() ?? 0;
  }
  return 0;
}

String? _blankToNull(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

class _BoolConverter implements JsonConverter<bool, Object?> {
  const _BoolConverter();
  @override
  bool fromJson(Object? json) => _looseBool(json);
  @override
  Object? toJson(bool object) => object;
}

class _NullableDoubleConverter implements JsonConverter<double?, Object?> {
  const _NullableDoubleConverter();
  @override
  double? fromJson(Object? json) => _looseDouble(json);
  @override
  Object? toJson(double? object) => object;
}

class _IntConverter implements JsonConverter<int, Object?> {
  const _IntConverter();
  @override
  int fromJson(Object? json) => _looseInt(json);
  @override
  Object? toJson(int object) => object;
}

class _NullableStringConverter implements JsonConverter<String?, Object?> {
  const _NullableStringConverter();
  @override
  String? fromJson(Object? json) => _blankToNull(json);
  @override
  Object? toJson(String? object) => object;
}

/// A list of strings that tolerates `null`, a single comma string (how the
/// DocType stores `sheet_sizes`) and stray blanks.
class _StringListConverter implements JsonConverter<List<String>, Object?> {
  const _StringListConverter();
  @override
  List<String> fromJson(Object? json) {
    if (json is List) {
      return json
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (json is String) {
      return json
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  @override
  Object? toJson(List<String> object) => object;
}

/// Terms keep blank lines out but keep each line whole — a term may itself
/// contain commas, so the comma split above would be wrong here.
class _LinesConverter implements JsonConverter<List<String>, Object?> {
  const _LinesConverter();
  @override
  List<String> fromJson(Object? json) {
    final Iterable<Object?> raw = json is List
        ? json
        : json is String
        ? json.split('\n')
        : const <Object?>[];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Object? toJson(List<String> object) => object;
}

// -- Preview (`jarz_pos.api.price_sheet.preview_price_sheet`) ----------------

/// One rasterised page of a rendered sheet, in the same three tiers as an
/// uploaded material: a thumbnail, a phone-screen image and a full-resolution
/// one for zooming into.
@freezed
class PriceSheetPage with _$PriceSheetPage {
  const PriceSheetPage._();

  const factory PriceSheetPage({
    @Default('') String thumb,
    @Default('') String screen,
    @Default('') String full,
    @_IntConverter() @Default(0) int w,
    @_IntConverter() @Default(0) int h,
  }) = _PriceSheetPage;

  factory PriceSheetPage.fromJson(Map<String, dynamic> json) =>
      _$PriceSheetPageFromJson(json);

  /// Width / height, or A4 portrait when the server did not say.
  double get aspectRatio => (w > 0 && h > 0) ? w / h : 1 / 1.4142;

  /// The best image for a fitted page, falling back down the ladder.
  String get screenUrl => screen.isNotEmpty
      ? screen
      : full.isNotEmpty
      ? full
      : thumb;

  /// The sharpest image, for a zoomed-in page.
  String get fullUrl => full.isNotEmpty ? full : screenUrl;

  /// Every tier resolved against [base] (the ERP origin) when relative.
  PriceSheetPage resolvedAgainst(String base) => copyWith(
    thumb: absoluteFileUrl(base, thumb),
    screen: absoluteFileUrl(base, screen),
    full: absoluteFileUrl(base, full),
  );
}

/// One price in the table: a flavour at a size.
@freezed
class PriceSheetCell with _$PriceSheetCell {
  const factory PriceSheetCell({
    @Default('') String size,

    /// Null when the item does not exist or has no price for this customer;
    /// the sheet prints a dash.
    @_NullableDoubleConverter() double? rate,

    /// The undiscounted price, only meaningful beside a deal price.
    @JsonKey(name: 'normal_rate')
    @_NullableDoubleConverter()
    double? normalRate,
    @JsonKey(name: 'is_deal') @_BoolConverter() @Default(false) bool isDeal,
  }) = _PriceSheetCell;

  factory PriceSheetCell.fromJson(Map<String, dynamic> json) =>
      _$PriceSheetCellFromJson(json);
}

/// One flavour row of the table.
@freezed
class PriceSheetRow with _$PriceSheetRow {
  const factory PriceSheetRow({
    @Default('') String flavour,
    @Default('') String label,
    @Default(<PriceSheetCell>[]) List<PriceSheetCell> cells,
  }) = _PriceSheetRow;

  factory PriceSheetRow.fromJson(Map<String, dynamic> json) =>
      _$PriceSheetRowFromJson(json);
}

/// One line of the terms. `label` is the highlighted part before the first
/// colon, null when the line has none.
@freezed
class PriceSheetTerm with _$PriceSheetTerm {
  const factory PriceSheetTerm({
    @_NullableStringConverter() String? label,
    @Default('') String text,
  }) = _PriceSheetTerm;

  factory PriceSheetTerm.fromJson(Map<String, dynamic> json) =>
      _$PriceSheetTermFromJson(json);
}

/// The data the server rendered the sheet from — what the app shows around
/// the page images (who it is for, until when the deal prices hold).
@freezed
class PriceSheetData with _$PriceSheetData {
  const PriceSheetData._();

  const factory PriceSheetData({
    @Default('') String heading,
    @JsonKey(name: 'customer_name')
    @_NullableStringConverter()
    String? customerName,
    @JsonKey(name: 'price_list') @Default('') String priceList,
    @Default('') String currency,
    @JsonKey(name: 'as_of') @Default('') String asOf,
    @_StringListConverter() @Default(<String>[]) List<String> sizes,
    @Default(<PriceSheetRow>[]) List<PriceSheetRow> rows,
    @JsonKey(name: 'deal_until') @_NullableStringConverter() String? dealUntil,
    @Default(<PriceSheetTerm>[]) List<PriceSheetTerm> terms,
    @Default('') String footer,
  }) = _PriceSheetData;

  factory PriceSheetData.fromJson(Map<String, dynamic> json) =>
      _$PriceSheetDataFromJson(json);

  DateTime? get asOfDate => _parseDate(asOf);
  DateTime? get dealUntilDate => _parseDate(dealUntil);

  /// True when at least one cell is a deal price.
  bool get hasDeals => rows.any((r) => r.cells.any((c) => c.isDeal));
}

/// The full preview payload.
@freezed
class PriceSheetPreview with _$PriceSheetPreview {
  const PriceSheetPreview._();

  const factory PriceSheetPreview({
    @JsonKey(name: 'pdf_url') @Default('') String pdfUrl,
    @Default(<PriceSheetPage>[]) List<PriceSheetPage> pages,
    @Default(PriceSheetData()) PriceSheetData sheet,
  }) = _PriceSheetPreview;

  factory PriceSheetPreview.fromJson(Map<String, dynamic> json) =>
      _$PriceSheetPreviewFromJson(json);

  /// Every URL resolved against [base] so `Image.network` can load it.
  PriceSheetPreview resolvedAgainst(String base) => copyWith(
    pdfUrl: absoluteFileUrl(base, pdfUrl),
    pages: [for (final page in pages) page.resolvedAgainst(base)],
  );
}

// -- Template (`get_price_sheet_template` / `save_price_sheet_template`) -----

/// One flavour row of the template. `label` blank = the flavour itself.
@freezed
class PriceSheetTemplateRow with _$PriceSheetTemplateRow {
  const factory PriceSheetTemplateRow({
    @Default('') String flavour,
    @Default('') String label,
    @_BoolConverter() @Default(true) bool enabled,
  }) = _PriceSheetTemplateRow;

  factory PriceSheetTemplateRow.fromJson(Map<String, dynamic> json) =>
      _$PriceSheetTemplateRowFromJson(json);
}

/// The editable template behind a generated price sheet, plus the choices
/// the editor offers (flavours, sizes, price lists) and whether this user may
/// save it.
@freezed
class PriceSheetTemplate with _$PriceSheetTemplate {
  const PriceSheetTemplate._();

  const factory PriceSheetTemplate({
    @Default('') String name,
    @Default('') String title,
    @JsonKey(name: 'title_ar') @Default('') String titleAr,
    @_BoolConverter() @Default(true) bool enabled,
    @JsonKey(name: 'is_default')
    @_BoolConverter()
    @Default(false)
    bool isDefault,
    @JsonKey(name: 'sheet_heading') @Default('') String sheetHeading,

    /// Null = each customer's own B2B price list.
    @JsonKey(name: 'sheet_price_list')
    @_NullableStringConverter()
    String? sheetPriceList,
    @JsonKey(name: 'sheet_sizes')
    @_StringListConverter()
    @Default(<String>[])
    List<String> sheetSizes,
    @JsonKey(name: 'sheet_show_deals')
    @_BoolConverter()
    @Default(true)
    bool sheetShowDeals,
    @JsonKey(name: 'sheet_terms')
    @_LinesConverter()
    @Default(<String>[])
    List<String> sheetTerms,
    @JsonKey(name: 'sheet_footer') @Default('') String sheetFooter,
    @Default(<PriceSheetTemplateRow>[]) List<PriceSheetTemplateRow> rows,
    @JsonKey(name: 'available_flavours')
    @_StringListConverter()
    @Default(<String>[])
    List<String> availableFlavours,
    @JsonKey(name: 'available_sizes')
    @_StringListConverter()
    @Default(<String>[])
    List<String> availableSizes,
    @JsonKey(name: 'price_lists')
    @_StringListConverter()
    @Default(<String>[])
    List<String> priceLists,
    @JsonKey(name: 'can_edit') @_BoolConverter() @Default(false) bool canEdit,
  }) = _PriceSheetTemplate;

  factory PriceSheetTemplate.fromJson(Map<String, dynamic> json) =>
      _$PriceSheetTemplateFromJson(json);

  /// The `data` object `save_price_sheet_template` takes: the template's own
  /// fields, without the read-only choices (`available_*`, `price_lists`),
  /// `can_edit` or `name`. Blank strings are trimmed; a blank price list is
  /// sent as null ("each customer's own list"); blank term lines are dropped.
  Map<String, dynamic> toSavePayload() {
    final priceList = sheetPriceList?.trim() ?? '';
    return <String, dynamic>{
      'title': title.trim(),
      'title_ar': titleAr.trim(),
      'enabled': enabled,
      'is_default': isDefault,
      'sheet_heading': sheetHeading.trim(),
      'sheet_price_list': priceList.isEmpty ? null : priceList,
      'sheet_sizes': [
        for (final size in sheetSizes)
          if (size.trim().isNotEmpty) size.trim(),
      ],
      'sheet_show_deals': sheetShowDeals,
      'sheet_terms': [
        for (final line in sheetTerms)
          if (line.trim().isNotEmpty) line.trim(),
      ],
      'sheet_footer': sheetFooter.trim(),
      'rows': [
        for (final row in rows)
          if (row.flavour.trim().isNotEmpty)
            {
              'flavour': row.flavour.trim(),
              'label': row.label.trim(),
              'enabled': row.enabled,
            },
      ],
    };
  }

  /// Flavours offered by "Add flavour": available ones not already a row.
  List<String> get addableFlavours {
    final taken = rows.map((r) => r.flavour.trim().toLowerCase()).toSet();
    return [
      for (final flavour in availableFlavours)
        if (!taken.contains(flavour.trim().toLowerCase())) flavour,
    ];
  }
}

/// Resolves a server path such as `/files/...` against the ERP [base] URL.
/// Absolute URLs and blanks are returned unchanged.
String absoluteFileUrl(String base, String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final origin = base.trim();
  if (origin.isEmpty) return trimmed;
  final normalisedBase = origin.endsWith('/')
      ? origin.substring(0, origin.length - 1)
      : origin;
  final normalisedPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return '$normalisedBase$normalisedPath';
}

DateTime? _parseDate(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return DateTime.tryParse(value.trim());
}
