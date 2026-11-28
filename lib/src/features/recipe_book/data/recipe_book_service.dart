import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/network/frappe_error_message.dart';
import 'recipe_book_models.dart';

final recipeBookServiceProvider = Provider<RecipeBookService>((ref) {
  return RecipeBookService(ref.watch(dioProvider));
});

/// Reads the Recipe Book. Every call are read-only and gated server-side on
/// the production view role set.
class RecipeBookService {
  RecipeBookService(this._dio);

  /// Kept here rather than in `ApiEndpoints` so this feature ships as an OTA
  /// patch: `core/**` changes force a full APK.
  static const listRecipesEndpoint =
      '/api/method/jarz_pos.api.recipe_book.list_recipes';
  static const getRecipeEndpoint =
      '/api/method/jarz_pos.api.recipe_book.get_recipe';
  static const getJarFamilyEndpoint =
      '/api/method/jarz_pos.api.recipe_book.get_jar_family';

  final Dio _dio;

  Future<RecipeBookIndex> listRecipes() async {
    try {
      // `catalog=1` asks for every recipe (BOM-only ones too) with its
      // category, family and size; an older server ignores it.
      final resp = await _dio.get(
        listRecipesEndpoint,
        queryParameters: {'catalog': 1},
      );
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

  /// A recipe that has no SOP, read from its default BOM (or its current SOP
  /// when one exists), at one batch.
  Future<RecipeDetail> getRecipeByItem(String itemCode) async {
    try {
      final resp = await _dio.get(
        getRecipeEndpoint,
        queryParameters: {'item_code': itemCode},
      );
      return RecipeDetail.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw mapFrappeError(error, fallback: 'Failed to load the recipe');
    }
  }

  /// Every size of one jar flavour with its per-jar layer weights.
  Future<JarFamily> getJarFamily(String family) async {
    try {
      final resp = await _dio.get(
        getJarFamilyEndpoint,
        queryParameters: {'family': family},
      );
      return JarFamily.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw mapFrappeError(error, fallback: 'Failed to load the jar recipes');
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
