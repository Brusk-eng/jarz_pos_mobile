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
    this.families = const <RecipeFamilySummary>[],
    this.canEdit = false,
  });

  factory RecipeBookIndex.fromJson(Map<String, dynamic> json) =>
      RecipeBookIndex(
        tracks: _strList(json['tracks']),
        recipes: _mapList(json['recipes'], RecipeSummary.fromJson),
        families: _mapList(json['families'], RecipeFamilySummary.fromJson),
        canEdit: _bool(json['can_edit']),
      );

  /// Track order as the server sorts them.
  final List<String> tracks;
  final List<RecipeSummary> recipes;

  /// v2 only: one entry per jar flavour. Empty on a v1 payload.
  final List<RecipeFamilySummary> families;

  /// v3: the user may write and edit recipes. False on an older server.
  final bool canEdit;
}

/// Recipe kinds (v2 `category`). A v1 payload carries none.
abstract final class RecipeCategory {
  /// Cakes & biscuits.
  static const bases = 'bases';

  /// Mixes & fillings.
  static const fillings = 'fillings';
  static const jars = 'jars';

  /// Display order.
  static const order = <String>[bases, fillings, jars];
}

/// Jar sizes in display order.
const List<String> kJarSizes = <String>['Small', 'Medium', 'Large'];

/// `families[]` of the v2 `list_recipes(catalog=1)`.
@immutable
class RecipeFamilySummary {
  const RecipeFamilySummary({
    required this.family,
    this.track,
    this.sizes = const <String>[],
    this.hasTrial = false,
    this.status = RecipeStatus.approved,
    this.updated,
  });

  factory RecipeFamilySummary.fromJson(Map<String, dynamic> json) {
    final status = _str(json['status']).toLowerCase();
    return RecipeFamilySummary(
      family: _str(json['family']),
      track: _optStr(json['track']),
      sizes: _strList(json['sizes']),
      hasTrial: _bool(json['has_trial']),
      status: status.isEmpty ? RecipeStatus.approved : status,
      updated: _optStr(json['updated']),
    );
  }

  final String family;
  final String? track;
  final List<String> sizes;
  final bool hasTrial;
  final String status;
  final String? updated;
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
    this.category = '',
    this.family,
    this.size,
    this.hasMethod = true,
    this.source = RecipeSource.sop,
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
      hasTrial: _bool(json['has_trial']),
      updated: _optStr(json['updated']),
      versions: _mapList(json['versions'], RecipeVersion.fromJson),
      category: _str(json['category']).toLowerCase(),
      family: _optStr(json['family']),
      size: _optStr(json['size']),
      hasMethod: json.containsKey('has_method')
          ? _bool(json['has_method'])
          : _mapList(json['versions'], RecipeVersion.fromJson).isNotEmpty,
      source: _str(json['source']).toLowerCase() == RecipeSource.bom
          ? RecipeSource.bom
          : RecipeSource.sop,
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

  /// Newest first. Empty for a BOM-only recipe.
  final List<RecipeVersion> versions;

  /// [RecipeCategory] value, or empty on a v1 payload.
  final String category;

  /// Jar flavour ("Tiramisu"); null for anything but a sized jar.
  final String? family;

  /// Small | Medium | Large, or null.
  final String? size;

  /// At least one SOP version is written.
  final bool hasMethod;

  /// [RecipeSource] value.
  final String source;

  /// [category], with a missing one read as a filling: the quietest bucket for
  /// a recipe the server did not classify.
  String get effectiveCategory => RecipeCategory.order.contains(category)
      ? category
      : RecipeCategory.fillings;

  bool get isBomOnly => source == RecipeSource.bom;

  /// This recipe is a trial, or has a trial running alongside.
  bool get isTrialish => status == RecipeStatus.trial || hasTrial;

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

/// Where a recipe comes from (v2 `source`).
abstract final class RecipeSource {
  static const sop = 'sop';
  static const bom = 'bom';
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
    this.category = '',
    this.family,
    this.size,
    this.canEdit = false,
    this.editableInPlace = false,
    this.usedInProduction = false,
    this.layers = const <RecipeLayer>[],
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
      category: _str(json['category']).toLowerCase(),
      family: _optStr(json['family']),
      size: _optStr(json['size']),
      canEdit: _bool(json['can_edit']),
      editableInPlace: _bool(json['editable_in_place']),
      usedInProduction: _bool(json['used_in_production']),
      layers: _mapList(json['layers'], RecipeLayer.fromJson),
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
  final String category;
  final String? family;
  final String? size;

  /// v3: the user may edit this recipe.
  final bool canEdit;

  /// v3: this version can be changed where it stands (not used in production).
  final bool editableInPlace;
  final bool usedInProduction;

  /// v3: a jar's layers in fill order, grams per jar (never scaled).
  final List<RecipeLayer> layers;

  /// A recipe read from a BOM alone: no SOP behind it, so no version, no
  /// method.
  bool get isBomOnly => name.isEmpty;

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

/// `get_jar_family(family)`: every size of one jar flavour side by side.
@immutable
class JarFamily {
  const JarFamily({
    required this.family,
    this.track,
    this.sizes = const <JarSize>[],
    this.layers = const <JarLayer>[],
    this.packaging = const <JarLayer>[],
    this.canEdit = false,
    this.assembly = const JarAssembly(),
  });

  factory JarFamily.fromJson(Map<String, dynamic> json) => JarFamily(
    family: _str(json['family']),
    track: _optStr(json['track']),
    sizes: sortJarSizes(_mapList(json['sizes'], JarSize.fromJson)),
    layers: _mapList(json['layers'], JarLayer.fromJson),
    packaging: _mapList(json['packaging'], JarLayer.fromJson),
    canEdit: _bool(json['can_edit']),
    assembly: json['assembly'] is Map
        ? JarAssembly.fromJson(Map<String, dynamic>.from(json['assembly']))
        : const JarAssembly(),
  );

  final String family;
  final String? track;

  /// Small, Medium, Large order (the sizes that exist).
  final List<JarSize> sizes;

  /// Everything that is not packaging, in the order the server walked them.
  final List<JarLayer> layers;

  /// Jar, lid, label.
  final List<JarLayer> packaging;

  /// v3: the user may edit the layers.
  final bool canEdit;

  /// v3: the prepared layers in fill order, per size.
  final JarAssembly assembly;
}

/// [sizes] in Small, Medium, Large order; an odd size name goes last.
List<JarSize> sortJarSizes(List<JarSize> sizes) {
  int rank(String size) {
    final i = kJarSizes.indexOf(size);
    return i < 0 ? kJarSizes.length : i;
  }

  final sorted = [...sizes];
  sorted.sort((a, b) => rank(a.size).compareTo(rank(b.size)));
  return sorted;
}

@immutable
class JarSize {
  const JarSize({
    required this.size,
    this.itemCode,
    this.title = '',
    this.sop,
    this.sopVersion,
    this.status = RecipeStatus.approved,
    this.jarGrams,
    this.editableInPlace = false,
  });

  factory JarSize.fromJson(Map<String, dynamic> json) {
    final status = _str(json['status']).toLowerCase();
    return JarSize(
      size: _str(json['size']),
      itemCode: _optStr(json['item_code']),
      title: _str(json['title']),
      sop: _optStr(json['sop']),
      sopVersion: _optNum(json['sop_version'])?.round(),
      status: status.isEmpty ? RecipeStatus.approved : status,
      jarGrams: _optNum(json['jar_grams']),
      editableInPlace: _bool(json['editable_in_place']),
    );
  }

  final String size;
  final String? itemCode;
  final String title;

  /// Null when this size has no written method.
  final String? sop;
  final int? sopVersion;

  /// approved | trial.
  final String status;

  /// Sum of the gram layers in one jar; null when none.
  final double? jarGrams;

  /// v3: this size's headline version can be changed where it stands.
  final bool editableInPlace;

  bool get isTrial => status == RecipeStatus.trial;
}

/// One row of the comparison: a layer (or packaging piece) and what each size
/// carries per jar. A size missing from [perJar] does not have this layer.
@immutable
class JarLayer {
  const JarLayer({
    required this.key,
    required this.name,
    this.unit = 'g',
    this.perJar = const <String, double>{},
    this.items = const <String, String>{},
  });

  factory JarLayer.fromJson(Map<String, dynamic> json) {
    final name = _str(json['name']);
    final key = _str(json['key']);
    final raw = json['per_jar'];
    final rawItems = json['items'];
    return JarLayer(
      key: key.isNotEmpty ? key : name,
      name: name.isNotEmpty ? name : key,
      unit: _str(json['unit']).isEmpty ? 'g' : _str(json['unit']),
      perJar: {
        if (raw is Map)
          for (final e in raw.entries)
            if (_optNum(e.value) != null) e.key.toString(): _optNum(e.value)!,
      },
      items: {
        if (rawItems is Map)
          for (final e in rawItems.entries)
            if (_str(e.value).isNotEmpty) e.key.toString(): _str(e.value),
      },
    );
  }

  final String key;
  final String name;
  final String unit;
  final Map<String, double> perJar;

  /// Packaging only: the real item each size uses (size -> item name).
  final Map<String, String> items;
}

// ── tolerant parsing ──────────────────────────────────────────────────────

bool _bool(Object? value) => value == true || value == 1 || value == '1';

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

// ── v3: layers ────────────────────────────────────────────────────────────

/// One prepared layer of a jar, grams per jar. Order is fill order (the first
/// is the bottom of the jar).
@immutable
class RecipeLayer {
  const RecipeLayer({required this.layer, this.grams = 0, this.note});

  factory RecipeLayer.fromJson(Map<String, dynamic> json) => RecipeLayer(
    layer: _str(json['layer']),
    grams: _num(json['grams']),
    note: _optStr(json['note']),
  );

  final String layer;
  final double grams;
  final String? note;
}

/// One row of an aligned assembly: a layer and its grams in every size.
@immutable
class JarAssemblyRow {
  const JarAssemblyRow({required this.layer, this.grams = const {}});

  factory JarAssemblyRow.fromJson(Map<String, dynamic> json) {
    final raw = json['grams'];
    return JarAssemblyRow(
      layer: _str(json['layer']),
      grams: {
        if (raw is Map)
          for (final e in raw.entries)
            if (_optNum(e.value) != null) e.key.toString(): _optNum(e.value)!,
      },
    );
  }

  final String layer;

  /// Size → grams per jar.
  final Map<String, double> grams;
}

/// `get_jar_family().assembly`: what goes into each jar, layer by layer.
@immutable
class JarAssembly {
  const JarAssembly({
    this.aligned = false,
    this.rows = const <JarAssemblyRow>[],
    this.bySize = const <String, List<RecipeLayer>>{},
    this.totals = const <String, double>{},
  });

  factory JarAssembly.fromJson(Map<String, dynamic> json) {
    final rawBySize = json['by_size'];
    final rawTotals = json['totals'];
    return JarAssembly(
      aligned: _bool(json['aligned']),
      rows: _mapList(json['rows'], JarAssemblyRow.fromJson),
      bySize: {
        if (rawBySize is Map)
          for (final e in rawBySize.entries)
            e.key.toString(): _mapList(e.value, RecipeLayer.fromJson),
      },
      totals: {
        if (rawTotals is Map)
          for (final e in rawTotals.entries)
            if (_optNum(e.value) != null) e.key.toString(): _optNum(e.value)!,
      },
    );
  }

  /// Every size that has layers has the same layer names in the same order.
  final bool aligned;
  final List<JarAssemblyRow> rows;
  final Map<String, List<RecipeLayer>> bySize;
  final Map<String, double> totals;

  /// No size has any layer.
  bool get isEmpty => bySize.values.every((l) => l.isEmpty);

  /// The sizes that have layers, in Small, Medium, Large order.
  List<String> get sizes {
    final known = [
      for (final s in kJarSizes)
        if ((bySize[s] ?? const <RecipeLayer>[]).isNotEmpty) s,
    ];
    final other = [
      for (final e in bySize.entries)
        if (!kJarSizes.contains(e.key) && e.value.isNotEmpty) e.key,
    ];
    return [...known, ...other];
  }
}

// ── v3: editing ───────────────────────────────────────────────────────────

/// One ingredient row of the editable form.
@immutable
class EditIngredient {
  const EditIngredient({
    required this.name,
    this.amount,
    this.unit = 'g',
    this.section,
    this.note,
    this.itemCode,
  });

  factory EditIngredient.fromJson(Map<String, dynamic> json) => EditIngredient(
    name: _str(json['name']),
    amount: _optNum(json['amount']),
    unit: _str(json['unit']).isEmpty ? 'g' : _str(json['unit']),
    section: _optStr(json['section']),
    note: _optStr(json['note']),
    itemCode: _optStr(json['item_code']),
  );

  final String name;
  final double? amount;
  final String unit;
  final String? section;
  final String? note;
  final String? itemCode;
}

/// One method step of the editable form. The fields the editor does not show
/// ([extra]) are carried through untouched so a save never loses them.
@immutable
class EditStep {
  const EditStep({
    this.title = '',
    this.text = '',
    this.durationMins,
    this.extra = const <String, dynamic>{},
  });

  factory EditStep.fromJson(Map<String, dynamic> json) => EditStep(
    title: _str(json['title']),
    // Not trimmed: the text is the author's own.
    text: json['text'] == null ? '' : json['text'].toString(),
    durationMins: _optNum(json['duration_mins']),
    extra: {
      for (final key in const [
        'scaling_mode',
        'requires_confirmation',
        'capture_type',
        'capture_label',
        'capture_min',
        'capture_max',
      ])
        if (json.containsKey(key)) key: json[key],
    },
  );

  final String title;
  final String text;
  final double? durationMins;
  final Map<String, dynamic> extra;
}

/// `get_recipe_for_edit`: the editable form of one version, or a blank form
/// for a BOM-only item.
@immutable
class RecipeEditForm {
  const RecipeEditForm({
    this.base,
    this.itemCode,
    this.title = '',
    this.track,
    this.category = '',
    this.size,
    this.family,
    this.stage = '',
    this.version = 0,
    this.nextVersion = 1,
    this.editableInPlace = false,
    this.usedInProduction = false,
    this.ingredientsSource = 'table',
    this.ingredients = const <EditIngredient>[],
    this.yieldQty,
    this.yieldUom,
    this.prepTimeMins,
    this.equipment = '',
    this.notes = '',
    this.changeSummary = '',
    this.layers = const <RecipeLayer>[],
    this.steps = const <EditStep>[],
    this.tokenMap = const <String, String>{},
  });

  factory RecipeEditForm.fromJson(Map<String, dynamic> json) {
    final map = json['token_map'];
    final source = _str(json['ingredients_source']).toLowerCase();
    return RecipeEditForm(
      base: _optStr(json['base']),
      itemCode: _optStr(json['item_code']),
      title: _str(json['title']),
      track: _optStr(json['track']),
      category: _str(json['category']).toLowerCase(),
      size: _optStr(json['size']),
      family: _optStr(json['family']),
      stage: _str(json['stage']),
      version: _num(json['version']).round(),
      nextVersion: _optNum(json['next_version'])?.round() ?? 1,
      editableInPlace: _bool(json['editable_in_place']),
      usedInProduction: _bool(json['used_in_production']),
      ingredientsSource: source == 'bom' ? 'bom' : 'table',
      ingredients: _mapList(json['ingredients'], EditIngredient.fromJson),
      yieldQty: _optNum(json['yield_qty']),
      yieldUom: _optStr(json['yield_uom']),
      prepTimeMins: _optNum(json['prep_time_mins'])?.round(),
      equipment: json['equipment']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      changeSummary: json['change_summary']?.toString() ?? '',
      layers: _mapList(json['layers'], RecipeLayer.fromJson),
      steps: _mapList(json['steps'], EditStep.fromJson),
      tokenMap: {
        if (map is Map)
          for (final e in map.entries) e.key.toString(): e.value.toString(),
      },
    );
  }

  /// The SOP being edited; null for a new recipe or a BOM-only item.
  final String? base;
  final String? itemCode;
  final String title;
  final String? track;

  /// bases | fillings | jars, or empty.
  final String category;
  final String? size;
  final String? family;
  final String stage;
  final int version;
  final int nextVersion;
  final bool editableInPlace;
  final bool usedInProduction;

  /// "bom" (amounts are read-only here) or "table".
  final String ingredientsSource;
  final List<EditIngredient> ingredients;
  final double? yieldQty;
  final String? yieldUom;
  final int? prepTimeMins;
  final String equipment;
  final String notes;
  final String changeSummary;
  final List<RecipeLayer> layers;
  final List<EditStep> steps;
  final Map<String, String> tokenMap;

  bool get fromBom => ingredientsSource == 'bom';
  bool get hasItem => itemCode != null && itemCode!.isNotEmpty;
}

/// What `save_recipe` answers: the saved version and any notes about it.
@immutable
class SaveRecipeResult {
  const SaveRecipeResult({required this.recipe, this.warnings = const []});

  factory SaveRecipeResult.fromJson(Map<String, dynamic> json) {
    final raw = json['recipe'];
    return SaveRecipeResult(
      recipe: RecipeDetail.fromJson(
        raw is Map ? Map<String, dynamic>.from(raw) : json,
      ),
      warnings: _strList(json['warnings']),
    );
  }

  final RecipeDetail recipe;

  /// Placeholders the server could not match; the recipe is saved anyway.
  final List<String> warnings;
}

/// What `set_recipe_stage` answers: the version, and the one it replaced.
@immutable
class SetStageResult {
  const SetStageResult({required this.recipe, this.replaced});

  factory SetStageResult.fromJson(Map<String, dynamic> json) {
    final raw = json['recipe'];
    return SetStageResult(
      recipe: RecipeDetail.fromJson(
        raw is Map ? Map<String, dynamic>.from(raw) : json,
      ),
      replaced: _optStr(json['replaced']),
    );
  }

  final RecipeDetail recipe;
  final String? replaced;
}

/// What `save_jar_layers` answers: the family again, and what changed.
@immutable
class SaveLayersResult {
  const SaveLayersResult({
    required this.family,
    this.created = const [],
    this.updated = const [],
  });

  factory SaveLayersResult.fromJson(Map<String, dynamic> json) {
    List<String> names(Object? v) => [
      if (v is List)
        for (final e in v)
          if (e is Map)
            (_str(e['size']).isNotEmpty ? _str(e['size']) : _str(e['sop']))
          else
            _str(e),
    ].where((e) => e.isNotEmpty).toList();
    final raw = json['family'];
    return SaveLayersResult(
      // Contract: "the get_jar_family payload plus created / updated".
      family: JarFamily.fromJson(
        raw is Map ? Map<String, dynamic>.from(raw) : json,
      ),
      created: names(json['created']),
      updated: names(json['updated']),
    );
  }

  final JarFamily family;

  /// Sizes (or SOPs) that got a new version.
  final List<String> created;
  final List<String> updated;
}
