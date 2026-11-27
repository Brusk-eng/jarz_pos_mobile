import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/recipe_book_models.dart';
import '../data/recipe_book_service.dart';
import '../domain/recipe_scaling.dart';

/// Every recipe with its versions. Kept (not auto-disposed) so going back to
/// the list from a recipe does not refetch; pull to refresh does.
final recipeBookIndexProvider = FutureProvider<RecipeBookIndex>((ref) {
  return ref.watch(recipeBookServiceProvider).listRecipes();
});

/// One version of a recipe at one batch, by SOP name. Kept, so switching back
/// to a version seen a moment ago does not blink; pull to refresh refetches.
final recipeDetailProvider = FutureProvider.family<RecipeDetail, String>((
  ref,
  sop,
) {
  return ref.watch(recipeBookServiceProvider).getRecipe(sop);
});

/// The list screen's search text.
final recipeBookQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// The list screen's filter chip.
final recipeBookFilterProvider = StateProvider.autoDispose<RecipeFilter>(
  (ref) => RecipeFilter.all,
);

/// The chosen scale factor per recipe key, kept while the app is open (not
/// persisted). Keyed by recipe, not by version, so switching versions keeps
/// the batch the user asked for.
final recipeScaleProvider = StateProvider.family<double, String>(
  (ref, key) => 1.0,
);

/// Whether the user has scaled any recipe yet this session. The "tap any
/// ingredient" hint is shown until they have.
final recipeScaleHintDoneProvider = StateProvider<bool>((ref) => false);

/// SOP versions whose "What changed" card was dismissed this session, so it
/// is shown once rather than on every open.
final recipeChangeNoteDismissedProvider = StateProvider<Set<String>>(
  (ref) => const <String>{},
);

/// Sets [key]'s factor and retires the scaling hint.
void setRecipeScale(WidgetRef ref, String key, double factor) {
  if (factor.isNaN || factor.isInfinite || factor <= 0) return;
  ref.read(recipeScaleProvider(key).notifier).state = factor;
  ref.read(recipeScaleHintDoneProvider.notifier).state = true;
}
