import 'package:flutter/foundation.dart';

/// Wire models for the Recipe Book (`jarz_pos.api.recipe_book`).
///
/// Hand-written rather than freezed: the shapes are read-only and tolerant
/// parsing is the whole job. A missing or odd key becomes a default, never a
/// crash, so a backend that adds a field (or has not shipped one yet) still
/// renders.

/// `list_recipes()` → `{"tracks": [...], "recipes": [...]}`.
@immutable
class RecipeBookIndex {
  const RecipeBookIndex({
    this.tracks = const <String>[],
    this.recipes = const <RecipeSummary>[],
  });

  factory RecipeBookIndex.fromJson(Map<String, dynamic> json) =>
      RecipeBookIndex(
        tracks: _strList(json['tracks']),
        recipes: _mapList(json['recipes'], RecipeSummary.fromJson),
      );

  /// Track order as the server sorts them.
  final List<String> tracks;
  final List<RecipeSummary> recipes;
}

/// The recipe as a whole: every version of one key.
@immutable
class RecipeSummary {
  const RecipeSummary({
    required this.key,
    required this.title,
    this.itemCode,
    this.track,
    this.status = RecipeStatus.approved,
    this.headline = '',
    this.hasTrial = false,
    this.updated,
    this.versions = const <RecipeVersion>[],
  });

  factory RecipeSummary.fromJson(Map<String, dynamic> json) {
    final key = _str(json['key']);
    final title = _str(json['title']);
    return RecipeSummary(
      key: key.isNotEmpty ? key : title,
      title: title.isNotEmpty ? title : key,
      itemCode: _optStr(json['item_code']),
      track: _optStr(json['track']),
      status: _str(json['status']).toLowerCase().isEmpty
          ? RecipeStatus.approved
          : _str(json['status']).toLowerCase(),
      headline: _str(json['headline']),
      hasTrial: json['has_trial'] == true || json['has_trial'] == 1,
      updated: _optStr(json['updated']),
      versions: _mapList(json['versions'], RecipeVersion.fromJson),
    );
  }

  /// item_code, else recipe_title. Scale factors are kept per key.
  final String key;
  final String title;
  final String? itemCode;
  final String? track;

  /// [RecipeStatus] value: approved | trial | retired.
  final String status;

  /// The SOP name opened by default: the current version, else newest trial.
  final String headline;

  /// A Trial version exists alongside a current one.
  final bool hasTrial;
  final String? updated;

  /// Newest first.
  final List<RecipeVersion> versions;

  /// The version named by [headline], else the newest one.
  RecipeVersion? get headlineVersion {
    for (final v in versions) {
      if (v.name == headline) return v;
    }
    return versions.isEmpty ? null : versions.first;
  }

  /// The SOP to open: [headline], else the newest version's name.
  String get openSop =>
      headline.isNotEmpty ? headline : (headlineVersion?.name ?? '');
}

/// Recipe-level status values.
abstract final class RecipeStatus {
  static const approved = 'approved';
  static const trial = 'trial';
  static const retired = 'retired';
}

/// Version-level status values.
abstract final class VersionStatus {
  static const current = 'current';
  static const previous = 'previous';
  static const trial = 'trial';
  static const retired = 'retired';
}

@immutable
class RecipeVersion {
  const RecipeVersion({
    required this.name,
    this.version = 0,
    this.stage = '',
    this.status = VersionStatus.current,
    this.approvedOn,
    this.modified,
    this.changeSummary,
    this.inProduction = false,
  });

  factory RecipeVersion.fromJson(Map<String, dynamic> json) => RecipeVersion(
    name: _str(json['name']),
    version: _num(json['version']).round(),
    stage: _str(json['stage']),
    status: _str(json['status']).toLowerCase(),
    approvedOn: _optStr(json['approved_on']),
    modified: _optStr(json['modified']),
    changeSummary: _optStr(json['change_summary']),
    inProduction: json['in_production'] == true || json['in_production'] == 1,
  );

  /// The SOP document name, e.g. "SOP-0042".
  final String name;
  final int version;

  /// Approved | Trial | Retired.
  final String stage;

  /// [VersionStatus] value: current | previous | trial | retired.
  final String status;
  final String? approvedOn;
  final String? modified;
  final String? changeSummary;
  final bool inProduction;
}

/// `get_recipe(sop)`: one version at one batch (factor 1).
@immutable
class RecipeDetail {
  const RecipeDetail({
    required this.name,
    required this.key,
    required this.title,
    this.itemCode,
    this.track,
    this.version = 0,
    this.stage = '',
    this.status = VersionStatus.current,
    this.approvedOn,
    this.changeSummary,
    this.inProduction = false,
    this.equipment,
    this.prepTimeMins,
    this.notes,
    this.batchYield = const RecipeYield(),
    this.ingredients = const <RecipeIngredient>[],
    this.steps = const <RecipeStep>[],
    this.versions = const <RecipeVersion>[],
    this.unresolvedTokens = const <String>[],
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    final name = _str(json['name']);
    final key = _str(json['key']);
    final title = _str(json['title']);
    final rawYield = json['yield'];
    return RecipeDetail(
      name: name,
      key: key.isNotEmpty ? key : (title.isNotEmpty ? title : name),
      title: title.isNotEmpty ? title : (key.isNotEmpty ? key : name),
      itemCode: _optStr(json['item_code']),
      track: _optStr(json['track']),
      version: _num(json['version']).round(),
      stage: _str(json['stage']),
      status: _str(json['status']).toLowerCase(),
      approvedOn: _optStr(json['approved_on']),
      changeSummary: _optStr(json['change_summary']),
      inProduction: json['in_production'] == true || json['in_production'] == 1,
      equipment: _optStr(json['equipment']),
      prepTimeMins: _optNum(json['prep_time_mins'])?.round(),
      notes: _optStr(json['notes']),
      batchYield: rawYield is Map
          ? RecipeYield.fromJson(Map<String, dynamic>.from(rawYield))
          : const RecipeYield(),
      ingredients: _mapList(json['ingredients'], RecipeIngredient.fromJson),
      steps: _mapList(json['steps'], RecipeStep.fromJson),
      versions: _mapList(json['versions'], RecipeVersion.fromJson),
      unresolvedTokens: _strList(json['unresolved_tokens']),
    );
  }

  final String name;
  final String key;
  final String title;
  final String? itemCode;
  final String? track;
  final int version;
  final String stage;
  final String status;
  final String? approvedOn;
  final String? changeSummary;
  final bool inProduction;
  final String? equipment;
  final int? prepTimeMins;
  final String? notes;
  final RecipeYield batchYield;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final List<RecipeVersion> versions;
  final List<String> unresolvedTokens;

  bool get hasNotes =>
      (notes?.trim().isNotEmpty ?? false) ||
      (equipment?.trim().isNotEmpty ?? false);
}

@immutable
class RecipeYield {
  const RecipeYield({this.label = '', this.amount, this.unit = ''});

  factory RecipeYield.fromJson(Map<String, dynamic> json) => RecipeYield(
    label: _str(json['label']),
    amount: _optNum(json['amount']),
    unit: _str(json['unit']),
  );

  final String label;

  /// Null when the server does not know what one batch makes.
  final double? amount;
  final String unit;

  bool get isKnown => amount != null && amount! > 0;
}

@immutable
class RecipeIngredient {
  const RecipeIngredient({
    required this.key,
    required this.name,
    this.amount = 0,
    this.unit = '',
    this.section,
    this.note,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    final name = _str(json['name']);
    final key = _str(json['key']);
    return RecipeIngredient(
      key: key.isNotEmpty ? key : name,
      name: name.isNotEmpty ? name : key,
      amount: _num(json['amount']),
      unit: _str(json['unit']),
      section: _optStr(json['section']),
      note: _optStr(json['note']),
    );
  }

  final String key;
  final String name;

  /// At one batch, in [unit] ("g" whenever it converts to grams).
  final double amount;
  final String unit;
  final String? section;
  final String? note;
}

@immutable
class RecipeStep {
  const RecipeStep({
    this.stepNo = 0,
    this.title = '',
    this.durationMins,
    this.scalingMode = 'Fixed',
    this.captureLabel,
    this.captureMin,
    this.captureMax,
    this.segments = const <RecipeSegment>[],
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
    stepNo: _num(json['step_no']).round(),
    title: _str(json['title']),
    durationMins: _optNum(json['duration_mins']),
    scalingMode: _str(json['scaling_mode']).isEmpty
        ? 'Fixed'
        : _str(json['scaling_mode']),
    captureLabel: _optStr(json['capture_label']),
    captureMin: _optNum(json['capture_min']),
    captureMax: _optNum(json['capture_max']),
    segments: _mapList(json['segments'], RecipeSegment.fromJson),
  );

  final int stepNo;
  final String title;
  final double? durationMins;

  /// Fixed | Per Batch | Per Unit.
  final String scalingMode;
  final String? captureLabel;
  final double? captureMin;
  final double? captureMax;
  final List<RecipeSegment> segments;
}

/// One piece of a step's text: plain [text], or a token with an amount.
@immutable
class RecipeSegment {
  const RecipeSegment.text(String this.text)
    : key = null,
      amount = null,
      unit = '',
      format = '',
      scales = false,
      name = '';

  const RecipeSegment.token({
    this.key,
    this.amount,
    this.unit = '',
    required this.format,
    this.scales = true,
    this.name = '',
  }) : text = null;

  factory RecipeSegment.fromJson(Map<String, dynamic> json) {
    final format = _str(json['format']).toLowerCase();
    if (format.isEmpty) {
      // Not trimmed: "Sift " and " cocoa" carry the spaces between tokens.
      final text = json['text'];
      return RecipeSegment.text(text == null ? '' : text.toString());
    }
    return RecipeSegment.token(
      key: _optStr(json['key']),
      amount: _optNum(json['amount']),
      unit: _str(json['unit']),
      format: format,
      scales: json['scales'] == true || json['scales'] == 1,
      name: _str(json['name']),
    );
  }

  /// Non-null for a plain text segment.
  final String? text;
  final String? key;
  final double? amount;
  final String unit;

  /// grams | qty | count | full | name | uom. Empty for text.
  final String format;
  final bool scales;
  final String name;

  bool get isText => text != null;
}

// ── tolerant parsing ──────────────────────────────────────────────────────

String _str(Object? value) => value == null ? '' : value.toString().trim();

String? _optStr(Object? value) {
  final s = _str(value);
  return s.isEmpty ? null : s;
}

double _num(Object? value) => _optNum(value) ?? 0;

double? _optNum(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

List<String> _strList(Object? value) => [
  if (value is List)
    for (final v in value)
      if (v != null && v.toString().trim().isNotEmpty) v.toString().trim(),
];

List<T> _mapList<T>(Object? value, T Function(Map<String, dynamic>) parse) => [
  if (value is List)
    for (final v in value)
      if (v is Map) parse(Map<String, dynamic>.from(v)),
];
