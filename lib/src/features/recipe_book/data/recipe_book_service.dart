import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/network/frappe_error_message.dart';
import 'recipe_book_models.dart';

final recipeBookServiceProvider = Provider<RecipeBookService>((ref) {
  return RecipeBookService(ref.watch(dioProvider));
});

/// Reads the Recipe Book (gated server-side on the production view role set)
/// and, for the manufacturing roles, writes it: recipes, stages and jar layers.
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

  // v3 (edit): the write side lives in its own backend module.
  static const getRecipeForEditEndpoint =
      '/api/method/jarz_pos.api.recipe_book_edit.get_recipe_for_edit';
  static const saveRecipeEndpoint =
      '/api/method/jarz_pos.api.recipe_book_edit.save_recipe';
  static const setRecipeStageEndpoint =
      '/api/method/jarz_pos.api.recipe_book_edit.set_recipe_stage';
  static const saveJarLayersEndpoint =
      '/api/method/jarz_pos.api.recipe_book_edit.save_jar_layers';

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

  /// The editable form of a version (`sop`), or a blank one pre-filled from a
  /// BOM-only item (`itemCode`).
  Future<RecipeEditForm> getRecipeForEdit({
    String? sop,
    String? itemCode,
  }) async {
    try {
      final resp = await _dio.get(
        getRecipeForEditEndpoint,
        queryParameters: {
          if (sop != null && sop.isNotEmpty) 'sop': sop,
          if (itemCode != null && itemCode.isNotEmpty) 'item_code': itemCode,
        },
      );
      return RecipeEditForm.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw mapFrappeError(error, fallback: 'Failed to load the recipe');
    }
  }

  /// Saves a recipe; [payload] goes up as a JSON string.
  Future<SaveRecipeResult> saveRecipe(Map<String, dynamic> payload) async {
    try {
      final resp = await _dio.post(
        saveRecipeEndpoint,
        data: {'payload': jsonEncode(payload)},
      );
      return SaveRecipeResult.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw mapFrappeError(error, fallback: 'Failed to save the recipe');
    }
  }

  /// Approve / retire / back to trial. [useBom] answers the server's refusal
  /// when a trial has its own amounts but the item has a BOM.
  Future<SetStageResult> setRecipeStage(
    String sop,
    String stage, {
    bool useBom = false,
  }) async {
    try {
      final resp = await _dio.post(
        setRecipeStageEndpoint,
        data: {'sop': sop, 'stage': stage, 'use_bom': useBom ? 1 : 0},
      );
      return SetStageResult.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw mapFrappeError(error, fallback: 'Failed to change the recipe');
    }
  }

  /// Writes a jar flavour's layers for every size; [layers] goes up as a JSON
  /// string.
  Future<SaveLayersResult> saveJarLayers(
    String family,
    List<Map<String, dynamic>> layers, {
    String? changeSummary,
  }) async {
    try {
      final resp = await _dio.post(
        saveJarLayersEndpoint,
        data: {
          'family': family,
          'layers': jsonEncode(layers),
          if (changeSummary != null && changeSummary.trim().isNotEmpty)
            'change_summary': changeSummary.trim(),
        },
      );
      return SaveLayersResult.fromJson(_unwrapMap(resp.data));
    } catch (error) {
      throw mapFrappeError(error, fallback: 'Failed to save the layers');
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
