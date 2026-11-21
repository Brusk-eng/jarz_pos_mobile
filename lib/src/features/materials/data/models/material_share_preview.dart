// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import 'price_sheet.dart';

part 'material_share_preview.freezed.dart';
part 'material_share_preview.g.dart';

String? _blankToNull(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

class _NullableStringConverter implements JsonConverter<String?, Object?> {
  const _NullableStringConverter();
  @override
  String? fromJson(Object? json) => _blankToNull(json);
  @override
  Object? toJson(String? object) => object;
}

/// A string Frappe may hand back as `null`: read as empty, never a crash.
class _StringConverter implements JsonConverter<String, Object?> {
  const _StringConverter();
  @override
  String fromJson(Object? json) => json?.toString() ?? '';
  @override
  Object? toJson(String object) => object;
}

/// One item of the client's `/m/<token>` page, exactly as
/// `get_public_share` returns it: a title, its rasterised pages (the same
/// thumb/screen/full ladder as a price-sheet page) and, for a file with no
/// pages, the download link the page offers instead.
@freezed
class PublicShareItem with _$PublicShareItem {
  const PublicShareItem._();

  const factory PublicShareItem({
    @_StringConverter() @Default('') String title,
    @_StringConverter() @Default('') String type,
    @JsonKey(name: 'download_url') @_StringConverter() @Default('')
    String downloadUrl,
    @Default(<PriceSheetPage>[]) List<PriceSheetPage> pages,
  }) = _PublicShareItem;

  factory PublicShareItem.fromJson(Map<String, dynamic> json) =>
      _$PublicShareItemFromJson(json);

  /// Nothing to look at, only something to download.
  bool get isDownloadOnly => pages.isEmpty;

  PublicShareItem resolvedAgainst(String base) => copyWith(
    downloadUrl: absoluteFileUrl(base, downloadUrl),
    pages: [for (final page in pages) page.resolvedAgainst(base)],
  );
}

/// `jarz_pos.api.materials.preview_material_share`: what the client would get
/// for a pack, rendered without minting a link or counting a view.
@freezed
class MaterialSharePreview with _$MaterialSharePreview {
  const MaterialSharePreview._();

  const factory MaterialSharePreview({
    /// The final WhatsApp text, `{name}` filled and the link replaced by
    /// [linkPlaceholderUrl].
    @_StringConverter() @Default('') String message,

    /// The fake-token URL standing where the real link will go.
    @JsonKey(name: 'link_placeholder_url') @_StringConverter() @Default('')
    String linkPlaceholderUrl,

    /// Exactly what the page would greet with; null = no greeting.
    @JsonKey(name: 'greeting_name') @_NullableStringConverter()
    String? greetingName,
    @Default(<PublicShareItem>[]) List<PublicShareItem> items,
    @JsonKey(name: 'material_names') @Default(<String>[])
    List<String> materialNames,
  }) = _MaterialSharePreview;

  factory MaterialSharePreview.fromJson(Map<String, dynamic> json) =>
      _$MaterialSharePreviewFromJson(json);

  /// Every file URL resolved against [base] so `Image.network` can load it.
  /// The placeholder URL is left as the server wrote it: it is text, not a
  /// file.
  MaterialSharePreview resolvedAgainst(String base) => copyWith(
    items: [for (final item in items) item.resolvedAgainst(base)],
  );
}
