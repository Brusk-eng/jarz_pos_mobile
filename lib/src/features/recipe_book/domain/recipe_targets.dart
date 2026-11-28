/// What the one detail route (`/recipes/:sop`) opens, encoded in its single
/// path parameter so the router needs no new entry: a plain SOP name, an
/// `item:<item_code>` for a BOM-only recipe, or `jar:<family>` for a jar
/// family.
library;

import '../data/recipe_book_models.dart';

const String _itemPrefix = 'item:';
const String _jarPrefix = 'jar:';

/// The route parameter for a written SOP.
String recipeTargetSop(String sop) => sop;

/// The route parameter for a recipe known only by its item (BOM-only).
String recipeTargetItem(String itemCode) => '$_itemPrefix$itemCode';

/// The route parameter for a jar family screen.
String recipeTargetJar(String family) => '$_jarPrefix$family';

/// Where a list row for [recipe] leads; null when it has nothing to open.
String? recipeTargetFor(RecipeSummary recipe) {
  final sop = recipe.openSop;
  if (sop.isNotEmpty) return recipeTargetSop(sop);
  final item = recipe.itemCode ?? (recipe.isBomOnly ? recipe.key : null);
  return item == null || item.isEmpty ? null : recipeTargetItem(item);
}

/// Where a jar size's header and method row lead: its SOP, else its item.
String? recipeTargetForSize(JarSize size) {
  final sop = size.sop;
  if (sop != null && sop.isNotEmpty) return recipeTargetSop(sop);
  final item = size.itemCode;
  return item == null || item.isEmpty ? null : recipeTargetItem(item);
}

/// A route parameter, read back. A stray `%XX` (a double-encoded link) is
/// decoded; a name that is not valid percent-encoding is kept as it came.
String normalizeRecipeTarget(String raw) {
  if (!raw.contains('%')) return raw;
  try {
    return Uri.decodeComponent(raw);
  } catch (_) {
    return raw;
  }
}

/// The family named by a `jar:` target, or null when [target] is not one.
String? jarFamilyOfTarget(String target) =>
    target.startsWith(_jarPrefix) ? target.substring(_jarPrefix.length) : null;

/// The item code named by an `item:` target, or null when it is not one.
String? itemOfTarget(String target) => target.startsWith(_itemPrefix)
    ? target.substring(_itemPrefix.length)
    : null;
