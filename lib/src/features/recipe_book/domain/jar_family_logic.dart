/// Pure maths for the jar family screen: what a planned run needs in total.
/// No Flutter imports, so it is unit-tested on its own.
library;

import '../data/recipe_book_models.dart';
import 'recipe_scaling.dart';

/// What a run of [counts] jars needs.
class JarRunTotals {
  const JarRunTotals({
    this.layers = const <String, double>{},
    this.packaging = const <String, double>{},
    this.totalGrams = 0,
    this.jars = 0,
  });

  /// Layer key → total in the layer's own unit.
  final Map<String, double> layers;

  /// Packaging key → total pieces.
  final Map<String, double> packaging;

  /// Σ count × grams per jar.
  final double totalGrams;

  /// Σ counts.
  final double jars;

  /// True when at least one size has a count above zero.
  bool get hasRun => jars > 0;
}

/// Grams in one jar of [size]: the server's `jar_grams`, else the sum of the
/// gram layers that size carries; null when it carries none.
double? jarGramsFor(JarFamily family, JarSize size) {
  if (size.jarGrams != null) return size.jarGrams;
  var sum = 0.0;
  var any = false;
  for (final layer in family.layers) {
    final v = layer.perJar[size.size];
    if (v != null && layer.unit.trim().toLowerCase() == 'g') {
      sum += v;
      any = true;
    }
  }
  return any ? sum : null;
}

/// Σ count × per-jar for every layer and packaging row. A size without a
/// layer contributes nothing to it; a count of zero (or less) is ignored.
JarRunTotals computeJarRun(JarFamily family, Map<String, double> counts) {
  double countOf(String size) {
    final c = counts[size] ?? 0;
    return c.isNaN || c.isInfinite || c < 0 ? 0 : c;
  }

  Map<String, double> sum(List<JarLayer> rows) => {
    for (final row in rows)
      row.key: [
        for (final e in row.perJar.entries) countOf(e.key) * e.value,
      ].fold(0.0, (a, b) => a + b),
  };

  var grams = 0.0;
  var jars = 0.0;
  for (final size in family.sizes) {
    final c = countOf(size.size);
    jars += c;
    grams += c * (jarGramsFor(family, size) ?? 0);
  }
  return JarRunTotals(
    layers: sum(family.layers),
    packaging: sum(family.packaging),
    totalGrams: grams,
    jars: jars,
  );
}

/// A weight total: "430 g" below a kilo, "1.25 kg" from 1,000 g up.
String formatWeight(double grams) {
  if (grams.abs() >= 1000) {
    return '${formatDecimal(grams / 1000, maxDecimals: 2, grouping: true)} kg';
  }
  return formatGrams(grams);
}

/// A run total for [unit]: grams switch to kg from 1,000 g, anything else
/// shows as a plain count or quantity.
String formatRunAmount(double value, String unit) =>
    unit.trim().toLowerCase() == 'g'
    ? formatWeight(value)
    : formatIngredientAmount(value, unit);

/// What a planned run needs of one assembly layer: Σ count × grams per jar.
double assemblyRowRunTotal(JarAssemblyRow row, Map<String, double> counts) {
  var sum = 0.0;
  for (final e in row.grams.entries) {
    final c = counts[e.key] ?? 0;
    if (c > 0 && !c.isNaN && !c.isInfinite) sum += c * e.value;
  }
  return sum;
}

/// Grams of filled jars in a planned run: Σ count × the size's layer total.
double assemblyRunTotal(JarAssembly assembly, Map<String, double> counts) {
  var sum = 0.0;
  for (final e in assembly.totals.entries) {
    final c = counts[e.key] ?? 0;
    if (c > 0 && !c.isNaN && !c.isInfinite) sum += c * e.value;
  }
  return sum;
}
