import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/network/frappe_error_message.dart';
import 'recipe_book_models.dart';

final recipeBookServiceProvider = Provider<RecipeBookService>((ref) {
  return RecipeBookService(ref.watch(dioProvider));
});

/// Reads the Recipe Book. Both calls are read-only and gated server-side on
/// the production view role set.
class RecipeBookService {
  RecipeBookService(this._dio);

  /// Kept here rather than in `ApiEndpoints` so this feature ships as an OTA
  /// patch: `core/**` changes force a full APK.
  static const listRecipesEndpoint =
      '/api/method/jarz_pos.api.recipe_book.list_recipes';
  static const getRecipeEndpoint =
      '/api/method/jarz_pos.api.recipe_book.get_recipe';

  final Dio _dio;

  Future<RecipeBookIndex> listRecipes() async {
    try {
      final resp = await _dio.get(listRecipesEndpoint);
      return RecipeBookIndex.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw mapFrappeError(error, fallback: 'Failed to load the recipes');
    }
  }

  /// One version of a recipe, at one batch.
  Future<RecipeDetail> getRecipe(String sop) async {
    try {
      final resp = await _dio.get(
        getRecipeEndpoint,
        queryParameters: {'sop': sop},
      );
      return RecipeDetail.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw mapFrappeError(error, fallback: 'Failed to load the recipe');
    }
  }

  Map<String, dynamic> _unwrapMap(dynamic payload) {
    if (payload is Map && payload['message'] is Map) {
      return Map<String, dynamic>.from(payload['message'] as Map);
    }
    if (payload is Map) return Map<String, dynamic>.from(payload);
    throw Exception('Unexpected response shape');
  }
}
