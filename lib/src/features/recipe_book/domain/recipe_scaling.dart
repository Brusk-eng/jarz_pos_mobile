/// Pure scaling and formatting for the Recipe Book. No Flutter imports, so
/// every rule here is unit-tested on its own.
///
/// The server answers every recipe at ONE batch (factor 1). The client owns
/// the factor and applies the rendering rules of the API contract:
/// `displayed = amount × (scales ? factor : 1)`.
library;

import '../data/recipe_book_models.dart';

/// Anything closer to 1 than this is "not scaled" (×1).
const double _unitEpsilon = 1e-9;

bool isScaled(double factor) => (factor - 1).abs() > _unitEpsilon;

/// [value] with at most [maxDecimals] decimals, trailing zeros (and a bare
/// ".") dropped, optionally grouped in thousands with commas.
String formatDecimal(
  double value, {
  required int maxDecimals,
  bool grouping = false,
}) {
  if (value.isNaN || value.isInfinite) return '0';
  var text = value.toStringAsFixed(maxDecimals);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'0+$'), '');
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
  }
  if (text == '-0') text = '0';
  if (!grouping) return text;

  final negative = text.startsWith('-');
  if (negative) text = text.substring(1);
  final dot = text.indexOf('.');
  final whole = dot < 0 ? text : text.substring(0, dot);
  final fraction = dot < 0 ? '' : text.substring(dot);
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
    buffer.write(whole[i]);
  }
  return '${negative ? '-' : ''}$buffer$fraction';
}

/// Grams: one decimal max, trailing .0 dropped, thousands separator ("1,500").
String formatGramsNumber(double grams) =>
    formatDecimal(grams, maxDecimals: 1, grouping: true);

/// "1,500 g".
String formatGrams(double grams) => '${formatGramsNumber(grams)} g';

/// `qty`: up to 3 decimals, trailing zeros dropped.
String formatQty(double qty) => formatDecimal(qty, maxDecimals: 3);

/// `count`: things the bench counts (eggs). Nobody cracks 57.15 eggs, so a
/// scaled count is rounded to what can be counted out: whole from 10 up,
/// the nearest half below that (1½ eggs is a real instruction: beat two,
/// weigh half). Trailing .0 dropped.
String formatCount(double count) {
  final rounded = count.abs() >= 10
      ? count.roundToDouble()
      : (count * 2).roundToDouble() / 2;
  return formatDecimal(rounded, maxDecimals: 1);
}

bool _isGramUnit(String unit) => unit.trim().toLowerCase() == 'g';

const _pieceUnits = {
  'piece',
  'pieces',
  'pcs',
  'pc',
  'nos',
  'no',
  'unit',
  'units',
  'each',
};

bool _isPieceUnit(String unit) =>
    _pieceUnits.contains(unit.trim().toLowerCase());

/// Pieces, counted rather than weighed ("piece", "Nos").
bool isPieceUnit(String unit) => _isPieceUnit(unit);

/// First letter upper-cased, the rest as stored ("cheesecake mix" shows as
/// "Cheesecake mix").
String sentenceCase(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// A unit as it reads on screen: "Kg" and "KG" become "kg"; anything else is
/// shown as the server sent it.
String displayUnit(String unit) {
  final trimmed = unit.trim();
  return trimmed.toLowerCase() == 'kg' ? 'kg' : trimmed;
}

/// An ingredient amount without its unit: grams by the grams rule, anything
/// else by the qty rule.
String formatIngredientAmount(double amount, String unit) => _isGramUnit(unit)
    ? formatGramsNumber(amount)
    : _isPieceUnit(unit)
    ? formatCount(amount)
    : formatQty(amount);

/// An ingredient's amount at [factor]. Ingredients always scale.
double scaledIngredientAmount(RecipeIngredient ingredient, double factor) =>
    ingredient.amount * factor;

/// What a token's figure is at [factor]; null when the token has no amount.
double? scaledTokenAmount(RecipeSegment segment, double factor) {
  final amount = segment.amount;
  if (amount == null) return null;
  return segment.scales ? amount * factor : amount;
}

const _numericFormats = {'grams', 'qty', 'count', 'full'};

/// True when the token's figure on screen differs from its ×1 figure, so it
/// is tinted as scaled.
bool tokenLooksScaled(RecipeSegment segment, double factor) =>
    !segment.isText &&
    segment.scales &&
    segment.amount != null &&
    _numericFormats.contains(segment.format) &&
    isScaled(factor);

/// A segment as text at [factor], following the contract's rendering rules.
String renderSegment(RecipeSegment segment, double factor) {
  if (segment.isText) return segment.text!;
  final value = scaledTokenAmount(segment, factor);
  switch (segment.format) {
    case 'grams':
      return value == null ? segment.name : formatGrams(value);
    case 'qty':
      return value == null ? segment.name : formatQty(value);
    case 'count':
      return value == null ? segment.name : formatCount(value);
    case 'full':
      return [
        if (value != null) formatQty(value),
        if (segment.unit.trim().isNotEmpty) segment.unit.trim(),
        if (segment.name.trim().isNotEmpty) segment.name.trim(),
      ].join(' ');
    case 'name':
      return segment.name;
    case 'uom':
      return segment.unit;
    default:
      return value == null ? segment.name : formatQty(value);
  }
}

/// A step's segments cut into lines at every `\n` inside a text segment, so
/// each line (English, then Arabic) can take its own text direction. Blank
/// lines are dropped.
List<List<RecipeSegment>> splitSegmentsIntoLines(List<RecipeSegment> segments) {
  final lines = <List<RecipeSegment>>[];
  var current = <RecipeSegment>[];
  for (final segment in segments) {
    if (!segment.isText || !segment.text!.contains('\n')) {
      current.add(segment);
      continue;
    }
    final parts = segment.text!.split('\n');
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) {
        lines.add(current);
        current = <RecipeSegment>[];
      }
      if (parts[i].isNotEmpty) current.add(RecipeSegment.text(parts[i]));
    }
  }
  lines.add(current);
  return [
    for (final line in lines)
      if (line.any((s) => !s.isText || s.text!.trim().isNotEmpty)) line,
  ];
}

final RegExp _arabicChar = RegExp(r'[؀-ۿݐ-ݿ]');

bool containsArabic(String text) => _arabicChar.hasMatch(text);

/// Whether a line reads right to left: its plain text carries Arabic. Token
/// names are mostly English item names, so they do not decide it.
bool lineIsRtl(List<RecipeSegment> line) {
  final plain = line.where((s) => s.isText).map((s) => s.text!).join();
  if (plain.trim().isNotEmpty) return containsArabic(plain);
  return containsArabic(line.map((s) => renderSegment(s, 1)).join());
}

/// A step's duration at [factor]: `Fixed` unchanged, `Per Batch` / `Per Unit`
/// multiplied and rounded to whole minutes. Null stays null.
int? scaleDuration(double? minutes, String scalingMode, double factor) {
  if (minutes == null) return null;
  final mode = scalingMode.trim().toLowerCase();
  if (mode == 'per batch' || mode == 'per unit') {
    return (minutes * factor).round();
  }
  return minutes.round();
}

/// Whether the step's duration changes with the factor at all.
bool durationScales(String scalingMode) {
  final mode = scalingMode.trim().toLowerCase();
  return mode == 'per batch' || mode == 'per unit';
}

/// "45 min", "1 h", "1 h 25 min", with the unit words supplied so Arabic can
/// pass its own.
String formatMinutes(int minutes, {String hour = 'h', String minute = 'min'}) {
  if (minutes < 60) return '$minutes $minute';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h $hour' : '$h $hour $m $minute';
}

/// "92–98 °C", "≥ 40", "≤ 55 °C"; null when neither bound exists. "°C" is
/// appended only when the capture label mentions it.
String? formatTargetRange(double? min, double? max, String? label) {
  if (min == null && max == null) return null;
  final unit = (label ?? '').toLowerCase().contains('°c') ? ' °C' : '';
  String n(double v) => formatDecimal(v, maxDecimals: 2);
  if (min != null && max != null) {
    return min == max ? '${n(min)}$unit' : '${n(min)}–${n(max)}$unit';
  }
  if (min != null) return '≥ ${n(min)}$unit';
  return '≤ ${n(max!)}$unit';
}

/// The factor that makes [ingredient] come out at [entered] (in its unit).
/// Null when either side is not a positive number.
double? factorFromIngredient(double? entered, double ingredientAmount) {
  if (entered == null || entered <= 0 || ingredientAmount <= 0) return null;
  if (entered.isNaN || entered.isInfinite) return null;
  return entered / ingredientAmount;
}

/// The factor that makes one batch come out at [target] (in the yield unit).
double? factorFromTargetYield(double? target, double? yieldAmount) {
  if (target == null ||
      target <= 0 ||
      yieldAmount == null ||
      yieldAmount <= 0) {
    return null;
  }
  if (target.isNaN || target.isInfinite) return null;
  return target / yieldAmount;
}

/// "×1", "×½", "×2", "×1.27".
String formatFactor(double factor) {
  if ((factor - 0.5).abs() < _unitEpsilon) return '×½';
  return '×${formatDecimal(factor, maxDecimals: 2)}';
}

/// What a batch at [factor] makes, e.g. "14.29 kg" or "6 jars"; null when the
/// yield is unknown.
String? formatYieldAt(RecipeYield batchYield, double factor) {
  if (!batchYield.isKnown) return null;
  final value = batchYield.amount! * factor;
  final number = _isGramUnit(batchYield.unit)
      ? formatGramsNumber(value)
      : formatDecimal(value, maxDecimals: 2, grouping: true);
  final unit = displayUnit(batchYield.unit);
  return unit.isEmpty ? number : '$number $unit';
}

/// Parses a typed amount, accepting "1,800" / "1800" / "1.5" / "1٫5" and
/// Arabic-Indic digits. Null for anything that is not a number.
double? parseAmount(String raw) {
  const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
  const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
  final buffer = StringBuffer();
  for (final rune in raw.trim().runes) {
    final ch = String.fromCharCode(rune);
    final a = arabicDigits.indexOf(ch);
    final p = persianDigits.indexOf(ch);
    if (a >= 0) {
      buffer.write(a);
    } else if (p >= 0) {
      buffer.write(p);
    } else if (ch == '٫') {
      buffer.write('.');
    } else if (ch == ',' || ch == '٬' || ch == ' ') {
      // Thousands separators.
    } else {
      buffer.write(ch);
    }
  }
  final text = buffer.toString();
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

/// One ingredient section. [section] is null for ingredients without one.
typedef IngredientSection = ({String? section, List<RecipeIngredient> items});

/// Ingredients grouped by section in first-appearance order; the unsectioned
/// ones lead. A recipe without sections answers one group with a null name.
List<IngredientSection> groupIngredientsBySection(
  List<RecipeIngredient> ingredients,
) {
  final bySection = <String?, List<RecipeIngredient>>{};
  for (final i in ingredients) {
    bySection.putIfAbsent(i.section, () => <RecipeIngredient>[]).add(i);
  }
  final order = <String?>[
    if (bySection.containsKey(null)) null,
    for (final s in bySection.keys)
      if (s != null) s,
  ];
  return [for (final s in order) (section: s, items: bySection[s]!)];
}
