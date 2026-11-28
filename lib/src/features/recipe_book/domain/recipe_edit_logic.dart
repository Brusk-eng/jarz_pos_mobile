/// Pure logic for editing recipes and jar layers: placeholder insertion,
/// validation, layer-grid totals and the payloads sent to the server. No
/// Flutter widgets, so it is unit-tested on its own.
library;

import 'package:flutter/services.dart' show TextSelection, TextEditingValue;

import '../data/recipe_book_models.dart';
import 'recipe_scaling.dart';

/// How a save lands on the server.
abstract final class SaveMode {
  static const inPlace = 'in_place';
  static const newVersion = 'new_version';
}

/// Stage values the server accepts.
abstract final class RecipeStage {
  static const trial = 'Trial';
  static const approved = 'Approved';
  static const retired = 'Retired';
}

/// Units offered in the ingredient unit menu (free text is also allowed).
const List<String> kEditUnits = <String>['g', 'kg', 'ml', 'piece'];

// ── placeholders ──────────────────────────────────────────────────────────

/// "[Name]", "[Name each]", "[Name ×2]" or "[Name ×2 each]": the readable
/// placeholder the server turns into a scaling amount. [times] of 1 (or less)
/// adds no multiplier.
String placeholderFor(String name, {bool each = false, double? times}) {
  final label = name.trim();
  final buffer = StringBuffer('[$label');
  if (times != null && times > 0 && (times - 1).abs() > 1e-9) {
    buffer.write(' ×${formatDecimal(times, maxDecimals: 3)}');
  }
  if (each) buffer.write(' each');
  buffer.write(']');
  return buffer.toString();
}

/// [value] with [insert] put at the cursor (replacing a selection). With no
/// valid cursor it goes at the end. The cursor lands after the insert.
TextEditingValue insertAtCursor(TextEditingValue value, String insert) {
  final text = value.text;
  final sel = value.selection;
  final start = sel.isValid ? sel.start.clamp(0, text.length) : text.length;
  final end = sel.isValid ? sel.end.clamp(0, text.length) : text.length;
  final next = text.replaceRange(start, end, insert);
  return TextEditingValue(
    text: next,
    selection: TextSelection.collapsed(offset: start + insert.length),
  );
}

/// "Tiramisu jar (Small)": the title of a new jar recipe.
String composeJarTitle(String flavour, String size) =>
    '${flavour.trim()} jar (${size.trim()})';

// ── drafts ────────────────────────────────────────────────────────────────

/// An ingredient row as typed.
class IngredientDraft {
  IngredientDraft({
    this.name = '',
    this.amount = '',
    this.unit = 'g',
    this.section = '',
    this.note,
    this.itemCode,
  });

  String name;
  String amount;
  String unit;
  String section;
  String? note;
  String? itemCode;

  bool get isBlank => name.trim().isEmpty && amount.trim().isEmpty;
}

/// A method step as typed.
class StepDraft {
  StepDraft({
    this.title = '',
    this.text = '',
    this.minutes = '',
    this.extra = const <String, dynamic>{},
  });

  String title;
  String text;
  String minutes;

  /// Server fields the editor does not show, passed back unchanged.
  Map<String, dynamic> extra;

  bool get isBlank => title.trim().isEmpty && text.trim().isEmpty;
}

/// A jar layer of one jar as typed.
class LayerDraft {
  LayerDraft({this.layer = '', this.grams = '', this.note});

  String layer;
  String grams;
  String? note;

  bool get isBlank => layer.trim().isEmpty && grams.trim().isEmpty;
}

/// Everything the editor form holds, as plain text.
class RecipeDraft {
  RecipeDraft({
    this.title = '',
    this.track,
    this.category = '',
    this.flavour = '',
    this.size = '',
    this.yieldQty = '',
    this.yieldUom = '',
    this.prepMins = '',
    this.equipment = '',
    this.notes = '',
    this.fromBom = false,
    this.composeJar = false,
    List<IngredientDraft>? ingredients,
    List<LayerDraft>? layers,
    List<StepDraft>? steps,
  }) : ingredients = ingredients ?? <IngredientDraft>[],
       layers = layers ?? <LayerDraft>[],
       steps = steps ?? <StepDraft>[];

  String title;
  String? track;

  /// bases | fillings | jars | empty.
  String category;

  /// New jar only: the title is composed from these.
  String flavour;
  String size;
  String yieldQty;
  String yieldUom;
  String prepMins;
  String equipment;
  String notes;

  /// Amounts come from the BOM: the ingredient table is not sent.
  bool fromBom;

  /// The title is `<flavour> jar (<size>)` (a new recipe in Jars).
  bool composeJar;
  final List<IngredientDraft> ingredients;
  final List<LayerDraft> layers;
  final List<StepDraft> steps;

  /// The title the recipe will be saved with.
  String get effectiveTitle =>
      composeJar ? composeJarTitle(flavour, size) : title.trim();
}

/// What is wrong with a draft; the screen turns each into a sentence.
enum DraftIssue {
  titleMissing,
  flavourMissing,
  sizeMissing,
  ingredientNameMissing,
  amountInvalid,
  noIngredients,
  yieldInvalid,
  layerNameMissing,
  layerGramsInvalid,
}

/// The first problem in [draft], or null when it can be saved.
///
/// [requireIngredients]: a NEW table recipe needs at least one ingredient.
DraftIssue? validateDraft(
  RecipeDraft draft, {
  bool requireIngredients = false,
}) {
  if (draft.composeJar) {
    if (draft.flavour.trim().isEmpty) return DraftIssue.flavourMissing;
    if (draft.size.trim().isEmpty) return DraftIssue.sizeMissing;
  } else if (draft.title.trim().isEmpty) {
    return DraftIssue.titleMissing;
  }
  if (!draft.fromBom) {
    final rows = [
      for (final i in draft.ingredients)
        if (!i.isBlank) i,
    ];
    if (requireIngredients && rows.isEmpty) return DraftIssue.noIngredients;
    for (final row in rows) {
      if (row.name.trim().isEmpty) return DraftIssue.ingredientNameMissing;
      final amount = parseAmount(row.amount);
      if (amount == null || amount <= 0) return DraftIssue.amountInvalid;
    }
    if (draft.yieldQty.trim().isNotEmpty) {
      final y = parseAmount(draft.yieldQty);
      if (y == null || y <= 0) return DraftIssue.yieldInvalid;
    }
  }
  if (draft.category == RecipeCategory.jars) {
    for (final row in draft.layers) {
      if (row.isBlank) continue;
      if (row.layer.trim().isEmpty) return DraftIssue.layerNameMissing;
      final grams = parseAmount(row.grams);
      if (grams == null || grams <= 0) return DraftIssue.layerGramsInvalid;
    }
  }
  return null;
}

String? _blankToNull(String? v) =>
    v == null || v.trim().isEmpty ? null : v.trim();

/// The `payload` of `save_recipe`.
///
/// [mode] is [SaveMode]; [stage] is [RecipeStage] (Trial / Approved).
/// [base] is the SOP the draft started from (null for a new recipe);
/// [changeSummary] only matters for a new version.
Map<String, dynamic> buildSaveRecipePayload(
  RecipeDraft draft, {
  required String mode,
  required String stage,
  String? base,
  String? itemCode,
  String? changeSummary,
  Map<String, String> tokenMap = const {},
}) {
  final yieldQty = parseAmount(draft.yieldQty);
  return {
    'base': base,
    'item_code': itemCode,
    'mode': mode,
    'stage': stage,
    'title': draft.effectiveTitle,
    'track': _blankToNull(draft.track),
    'category': draft.category.isEmpty ? null : draft.category,
    'yield_qty': draft.fromBom ? null : yieldQty,
    'yield_uom': draft.fromBom ? null : _blankToNull(draft.yieldUom),
    'prep_time_mins': parseAmount(draft.prepMins)?.round(),
    'equipment': draft.equipment.trim(),
    'notes': draft.notes.trim(),
    'change_summary': (changeSummary ?? '').trim(),
    'ingredients': draft.fromBom
        ? const <Map<String, dynamic>>[]
        : [
            for (final i in draft.ingredients)
              if (!i.isBlank)
                {
                  'name': i.name.trim(),
                  'amount': parseAmount(i.amount),
                  'unit': i.unit.trim().isEmpty ? 'g' : i.unit.trim(),
                  'section': _blankToNull(i.section),
                  'note': _blankToNull(i.note),
                  'item_code': _blankToNull(i.itemCode),
                },
          ],
    'layers': draft.category == RecipeCategory.jars
        ? [
            for (final l in draft.layers)
              if (!l.isBlank)
                {
                  'layer': l.layer.trim(),
                  'grams': parseAmount(l.grams),
                  'note': _blankToNull(l.note),
                },
          ]
        : const <Map<String, dynamic>>[],
    'steps': [
      for (final st in draft.steps)
        if (!st.isBlank)
          {
            'title': st.title.trim(),
            'text': st.text.trimRight(),
            'duration_mins': parseAmount(st.minutes),
            ...st.extra,
          },
    ],
    'token_map': tokenMap,
  };
}

// ── jar layer grid ────────────────────────────────────────────────────────

/// One row of the layer grid editor: a layer name and grams per size, as typed.
class LayerGridRow {
  LayerGridRow({this.name = '', this.note, Map<String, String>? grams})
    : grams = grams ?? <String, String>{};

  String name;
  String? note;

  /// Size → grams as typed ("" when that size has none).
  final Map<String, String> grams;

  bool get isBlank =>
      name.trim().isEmpty && grams.values.every((g) => g.trim().isEmpty);
}

/// The grid to start editing from. An aligned assembly is its rows; otherwise
/// the sizes' layers are merged by name in first-seen order.
List<LayerGridRow> initialLayerGrid(JarAssembly assembly) {
  String fmt(double g) => formatDecimal(g, maxDecimals: 3);
  if (assembly.aligned && assembly.rows.isNotEmpty) {
    final notes = <String, String?>{};
    for (final list in assembly.bySize.values) {
      for (final l in list) {
        notes.putIfAbsent(l.layer.toLowerCase(), () => l.note);
      }
    }
    return [
      for (final r in assembly.rows)
        LayerGridRow(
          name: r.layer,
          note: notes[r.layer.toLowerCase()],
          grams: {for (final e in r.grams.entries) e.key: fmt(e.value)},
        ),
    ];
  }
  final rows = <String, LayerGridRow>{};
  for (final size in assembly.sizes) {
    for (final l in assembly.bySize[size] ?? const <RecipeLayer>[]) {
      final row = rows.putIfAbsent(
        l.layer.toLowerCase(),
        () => LayerGridRow(name: l.layer, note: l.note),
      );
      row.grams[size] = fmt(l.grams);
    }
  }
  return rows.values.toList();
}

/// Σ of each size's column; a size with no number in any row is absent.
Map<String, double> layerGridTotals(
  List<LayerGridRow> rows,
  List<String> sizes,
) {
  final totals = <String, double>{};
  for (final size in sizes) {
    var any = false;
    var sum = 0.0;
    for (final row in rows) {
      final v = parseAmount(row.grams[size] ?? '');
      if (v != null && v > 0) {
        sum += v;
        any = true;
      }
    }
    if (any) totals[size] = sum;
  }
  return totals;
}

/// What is wrong with a layer grid, or null.
DraftIssue? validateLayerGrid(List<LayerGridRow> rows, List<String> sizes) {
  for (final row in rows) {
    if (row.isBlank) continue;
    final hasGrams = row.grams.values.any((g) => g.trim().isNotEmpty);
    if (row.name.trim().isEmpty) return DraftIssue.layerNameMissing;
    if (!hasGrams) return DraftIssue.layerGramsInvalid;
    for (final size in sizes) {
      final raw = (row.grams[size] ?? '').trim();
      if (raw.isEmpty) continue;
      final v = parseAmount(raw);
      if (v == null || v <= 0) return DraftIssue.layerGramsInvalid;
    }
  }
  return null;
}

/// The `layers` argument of `save_jar_layers`: a size a row leaves empty is
/// left out of its `grams`, and a blank row is dropped.
List<Map<String, dynamic>> buildLayersPayload(
  List<LayerGridRow> rows,
  List<String> sizes,
) => [
  for (final row in rows)
    if (!row.isBlank)
      {
        'layer': row.name.trim(),
        'note': _blankToNull(row.note),
        'grams': {
          for (final size in sizes)
            if (parseAmount(row.grams[size] ?? '') case final v?)
              if (v > 0) size: v,
        },
      },
];

/// The sizes that carry at least one gram value in [rows].
List<String> layerGridTouchedSizes(
  List<LayerGridRow> rows,
  List<String> sizes,
) => [
  for (final size in sizes)
    if (layerGridTotals(rows, [size]).isNotEmpty) size,
];
