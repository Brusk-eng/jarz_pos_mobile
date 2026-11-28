import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/core/network/user_service.dart';
import 'package:jarz_pos/src/features/recipe_book/data/recipe_book_models.dart';
import 'package:jarz_pos/src/features/recipe_book/data/recipe_book_service.dart';
import 'package:jarz_pos/src/features/recipe_book/presentation/recipe_book_list_screen.dart';
import 'package:jarz_pos/src/features/recipe_book/presentation/recipe_detail_screen.dart';
import 'package:jarz_pos/src/features/recipe_book/presentation/recipe_jar_family_screen.dart';

import 'recipe_book_fixtures.dart';
import 'recipe_book_fixtures_v2.dart';
import 'recipe_book_fixtures_v3.dart';

class _Fake extends RecipeBookService {
  _Fake({
    this.canEdit = true,
    this.stage = 'Approved',
    this.assembly,
    this.editForm,
    this.layerLines = const [],
    this.refuseApproveWithoutBom = false,
  }) : super(Dio());

  final bool canEdit;
  final String stage;
  final Map<String, dynamic>? assembly;
  final Map<String, dynamic>? editForm;
  final List<Map<String, dynamic>> layerLines;
  final bool refuseApproveWithoutBom;

  final requested = <String>[];
  final editRequests = <({String? sop, String? item})>[];
  final saved = <Map<String, dynamic>>[];
  final layerSaves = <({String family, List layers, String? summary})>[];
  final stageCalls = <({String sop, String stage, bool useBom})>[];

  @override
  Future<RecipeBookIndex> listRecipes() async =>
      RecipeBookIndex.fromJson({...kRecipeIndexV2Json, 'can_edit': canEdit});

  @override
  Future<RecipeDetail> getRecipe(String sop) async {
    requested.add(sop);
    return RecipeDetail.fromJson({
      ...kFudgeV3Json(
        kFudgeCakeJson,
        canEdit: canEdit,
        stage: stage,
        layers: layerLines,
      ),
      'name': sop,
    });
  }

  @override
  Future<RecipeDetail> getRecipeByItem(String itemCode) async =>
      RecipeDetail.fromJson({...kSpongeCakeBomJson, 'can_edit': canEdit});

  @override
  Future<JarFamily> getJarFamily(String family) async => JarFamily.fromJson(
    kTiramisuFamilyV3Json(
      kTiramisuFamilyJson,
      canEdit: canEdit,
      assembly: assembly,
    ),
  );

  @override
  Future<RecipeEditForm> getRecipeForEdit({
    String? sop,
    String? itemCode,
  }) async {
    editRequests.add((sop: sop, item: itemCode));
    return RecipeEditForm.fromJson(editForm ?? kFudgeEditFormJson);
  }

  @override
  Future<SaveRecipeResult> saveRecipe(Map<String, dynamic> payload) async {
    saved.add(payload);
    return SaveRecipeResult.fromJson({
      'recipe': {...kFudgeCakeJson, 'name': 'SOP-0043', 'version': 5},
      'warnings': const <String>[],
    });
  }

  @override
  Future<SetStageResult> setRecipeStage(
    String sop,
    String stage, {
    bool useBom = false,
  }) async {
    stageCalls.add((sop: sop, stage: stage, useBom: useBom));
    if (refuseApproveWithoutBom && !useBom) {
      throw Exception(
        'This trial has its own amounts; production uses the BOM. '
        'Update the BOM in Desk, then approve with the BOM amounts.',
      );
    }
    return SetStageResult.fromJson({...kFudgeCakeJson, 'replaced': null});
  }

  @override
  Future<SaveLayersResult> saveJarLayers(
    String family,
    List<Map<String, dynamic>> layers, {
    String? changeSummary,
  }) async {
    layerSaves.add((family: family, layers: layers, summary: changeSummary));
    return SaveLayersResult.fromJson({
      ...kTiramisuFamilyV3Json(kTiramisuFamilyJson),
      'created': ['Medium'],
      'updated': ['Small', 'Large'],
    });
  }
}

Future<_Fake> _pump(
  WidgetTester tester,
  Widget home, {
  _Fake? fake,
  double width = 420,
}) async {
  final service = fake ?? _Fake();
  tester.view.physicalSize = Size(width, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        canAccessProductionBoardProvider.overrideWithValue(true),
        recipeBookServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  group('jar family layers', () {
    const family = RecipeJarFamilyScreen(family: 'Tiramisu');

    testWidgets('an aligned family shows the layers table with a total', (
      tester,
    ) async {
      await _pump(tester, family);
      expect(find.text('Layers per jar'), findsOneWidget);
      expect(find.text('Ingredients per jar'), findsOneWidget);
      expect(find.text('Coffee soak'), findsOneWidget);
      expect(find.text('Filled jar'), findsOneWidget);
      expect(find.text('77.5'), findsOneWidget);
      expect(find.text('163.5'), findsOneWidget);
      expect(find.text('1 = bottom of the jar'), findsOneWidget);
      expect(_key('jar-layers-size'), findsNothing);
    });

    testWidgets('planning a run adds a Total column to the layers', (
      tester,
    ) async {
      await _pump(tester, family);
      await tester.enterText(_key('jar-count-Small'), '10');
      await tester.pumpAndSettle();
      // 10 x 18.7 g of Savoiardi, and 10 x 77.5 g of filled jars.
      expect(find.text('187 g'), findsWidgets);
      expect(find.text('775 g'), findsOneWidget);
    });

    testWidgets('sizes with different layers get a size switch', (
      tester,
    ) async {
      await _pump(
        tester,
        family,
        fake: _Fake(assembly: kAssemblyDifferingJson()),
      );
      expect(_key('jar-layers-size'), findsOneWidget);
      expect(find.text('Sprinkles'), findsOneWidget);
      expect(find.text('Cream'), findsNothing);
      await tester.tap(
        find.descendant(
          of: _key('jar-layers-size'),
          matching: find.text('Medium'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sprinkles'), findsNothing);
      expect(find.text('Cream'), findsOneWidget);
    });

    testWidgets('no layers: a quiet line and, when editable, Add layers', (
      tester,
    ) async {
      await _pump(tester, family, fake: _Fake(assembly: kAssemblyEmptyJson()));
      expect(find.text('No layers yet'), findsOneWidget);
      expect(_key('jar-layers-add'), findsOneWidget);
      expect(_key('jar-layers-edit'), findsNothing);
    });

    testWidgets('the pencil is hidden when the user cannot edit', (
      tester,
    ) async {
      await _pump(tester, family, fake: _Fake(canEdit: false));
      expect(find.text('Filled jar'), findsOneWidget);
      expect(_key('jar-layers-edit'), findsNothing);
      await _pump(
        tester,
        family,
        fake: _Fake(canEdit: false, assembly: kAssemblyEmptyJson()),
      );
      expect(_key('jar-layers-add'), findsNothing);
    });

    testWidgets('the grid editor saves through the service', (tester) async {
      final fake = await _pump(tester, family);
      await tester.tap(_key('jar-layers-edit'));
      await tester.pumpAndSettle();
      expect(_key('layer-name-3'), findsOneWidget);

      await tester.enterText(_key('layer-grams-0-Small'), '20');
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(_key('layers-total-Small')).data, '78.8');

      await tester.tap(_key('layers-save'));
      await tester.pumpAndSettle();
      // Medium is on the Production Board, so a new version needs a reason.
      expect(find.text('What changed?'), findsOneWidget);
      await tester.tap(_key('save-sheet-confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Say what changed, so the team knows why'), findsOne);
      expect(fake.layerSaves, isEmpty);

      await tester.enterText(_key('save-summary'), 'More savoiardi');
      await tester.tap(_key('save-sheet-confirm'));
      await tester.pumpAndSettle();

      expect(fake.layerSaves, hasLength(1));
      final call = fake.layerSaves.single;
      expect(call.family, 'Tiramisu');
      expect(call.summary, 'More savoiardi');
      final first = call.layers.first as Map;
      expect(first['layer'], 'Savoiardi');
      expect((first['grams'] as Map)['Small'], 20.0);
      expect((first['grams'] as Map)['Medium'], 28.0);
      expect(call.layers, hasLength(4));
      // Back on the family page, with the confirmation.
      expect(find.text('Saved — new version for Medium'), findsOneWidget);
    });

    testWidgets('leaving the grid with edits asks first', (tester) async {
      final fake = await _pump(tester, family);
      await tester.tap(_key('jar-layers-edit'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      // Nothing changed: it just closes.
      expect(_key('layers-save'), findsNothing);

      await tester.tap(_key('jar-layers-edit'));
      await tester.pumpAndSettle();
      await tester.enterText(_key('layer-grams-0-Small'), '21');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(_key('layers-save'), findsOneWidget);
      expect(fake.layerSaves, isEmpty);
    });
  });

  group('recipe detail', () {
    const detail = RecipeDetailScreen(sop: 'SOP-0042');

    testWidgets('the pencil and menu are hidden without can_edit', (
      tester,
    ) async {
      await _pump(tester, detail, fake: _Fake(canEdit: false));
      expect(_key('recipe-edit'), findsNothing);
      expect(_key('recipe-menu'), findsNothing);
    });

    testWidgets('a jar recipe lists its layers above the method', (
      tester,
    ) async {
      await _pump(
        tester,
        detail,
        fake: _Fake(
          layerLines: [
            {'layer': 'Savoiardi', 'grams': 18.7, 'note': null},
            {'layer': 'Cream', 'grams': 46.7, 'note': null},
          ],
        ),
      );
      await tester.tap(find.text('Method'));
      await tester.pumpAndSettle();
      expect(_key('recipe-layers'), findsOneWidget);
      expect(find.text('65.4 g'), findsOneWidget);
    });

    testWidgets('a used version saves as the next version after asking', (
      tester,
    ) async {
      final fake = await _pump(tester, detail);
      await tester.tap(_key('recipe-edit'));
      await tester.pumpAndSettle();
      expect(fake.editRequests.single.sop, 'SOP-0042');
      expect(find.text('Save as v5'), findsOneWidget);

      await tester.tap(_key('recipe-save'));
      await tester.pumpAndSettle();
      expect(find.text('What changed?'), findsOneWidget);
      await tester.enterText(_key('save-summary'), 'Less sugar');
      await tester.tap(_key('save-sheet-confirm'));
      await tester.pumpAndSettle();

      expect(fake.saved, hasLength(1));
      final payload = fake.saved.single;
      expect(payload['mode'], 'new_version');
      expect(payload['base'], 'SOP-0042');
      expect(payload['stage'], 'Trial');
      expect(payload['change_summary'], 'Less sugar');
      expect(payload['title'], 'Fudge Cake');
      expect((payload['steps'] as List).single['scaling_mode'], 'Per Batch');
      // The saved version is now the one on screen.
      expect(fake.requested, contains('SOP-0043'));
    });

    testWidgets('an editable version saves in place without asking', (
      tester,
    ) async {
      final fake = await _pump(
        tester,
        detail,
        fake: _Fake(editForm: kFudgeEditInPlaceJson()),
      );
      await tester.tap(_key('recipe-edit'));
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
      await tester.tap(_key('recipe-save'));
      await tester.pumpAndSettle();
      expect(find.text('What changed?'), findsNothing);
      expect(fake.saved.single['mode'], 'in_place');
      expect(fake.saved.single['stage'], 'Approved');
    });

    testWidgets('the overflow offers Save as new version when in place', (
      tester,
    ) async {
      final fake = await _pump(
        tester,
        detail,
        fake: _Fake(editForm: kFudgeEditInPlaceJson()),
      );
      await tester.tap(_key('recipe-edit'));
      await tester.pumpAndSettle();
      await tester.tap(_key('recipe-save-menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save as new version'));
      await tester.pumpAndSettle();
      expect(find.text('What changed?'), findsOneWidget);
      await tester.enterText(_key('save-summary'), 'Try butter');
      await tester.tap(_key('save-sheet-confirm'));
      await tester.pumpAndSettle();
      expect(fake.saved.single['mode'], 'new_version');
    });

    testWidgets('Insert amount puts a placeholder at the end of the text', (
      tester,
    ) async {
      await _pump(tester, detail);
      await tester.tap(_key('recipe-edit'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(_key('step-insert-0'));
      await tester.tap(_key('step-insert-0'));
      await tester.pumpAndSettle();
      await tester.tap(_key('insert-times'));
      await tester.enterText(_key('insert-times'), '2');
      await tester.tap(find.text('Cocoa').last);
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(_key('step-text-0'));
      expect(field.controller!.text, 'Sift [Flour] and [Cocoa].[Cocoa ×2]');
    });

    testWidgets('leaving the editor with edits asks to discard', (
      tester,
    ) async {
      await _pump(tester, detail);
      await tester.tap(_key('recipe-edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      // Untouched: closes straight away.
      expect(_key('recipe-save'), findsNothing);

      await tester.tap(_key('recipe-edit'));
      await tester.pumpAndSettle();
      await tester.enterText(_key('recipe-title'), 'Fudge Cake 2');
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(_key('recipe-save'), findsNothing);
    });

    testWidgets('Approve confirms, names the version it replaces', (
      tester,
    ) async {
      final fake = await _pump(tester, detail, fake: _Fake(stage: 'Trial'));
      await tester.tap(_key('recipe-menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'v4 becomes the method on the Production Board, replacing v3.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
      await tester.pumpAndSettle();
      expect(fake.stageCalls.single.stage, 'Approved');
      expect(fake.stageCalls.single.useBom, isFalse);
    });

    testWidgets('a BOM refusal offers Approve with BOM amounts', (
      tester,
    ) async {
      final fake = await _pump(
        tester,
        detail,
        fake: _Fake(stage: 'Trial', refuseApproveWithoutBom: true),
      );
      await tester.tap(_key('recipe-menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
      await tester.pumpAndSettle();
      expect(find.textContaining('production uses the BOM'), findsOneWidget);
      await tester.tap(find.text('Approve with BOM amounts'));
      await tester.pumpAndSettle();
      expect(fake.stageCalls.map((c) => c.useBom), [false, true]);
    });

    testWidgets('a BOM-only recipe offers Write the method', (tester) async {
      final fake = await _pump(
        tester,
        const RecipeDetailScreen(sop: 'item:Sponge Cake'),
        fake: _Fake(
          editForm: {
            'base': null,
            'item_code': 'Sponge Cake',
            'title': 'Sponge Cake',
            'stage': '',
            'version': 0,
            'next_version': 1,
            'ingredients_source': 'bom',
            'ingredients': [
              {'name': 'Flour', 'amount': 500, 'unit': 'g'},
            ],
          },
        ),
      );
      expect(_key('recipe-menu'), findsNothing);
      await tester.tap(_key('recipe-write-method'));
      await tester.pumpAndSettle();
      expect(fake.editRequests.single.item, 'Sponge Cake');
      expect(find.text('Save'), findsOneWidget);
      expect(
        find.text('Amounts come from the BOM (change them in Desk)'),
        findsOneWidget,
      );
      await tester.tap(_key('recipe-save'));
      await tester.pumpAndSettle();
      // First version of an item: Approved is the default, no summary asked.
      expect(find.text('What changed?'), findsNothing);
      await tester.tap(_key('save-sheet-confirm'));
      await tester.pumpAndSettle();
      expect(fake.saved.single['item_code'], 'Sponge Cake');
      expect(fake.saved.single['stage'], 'Approved');
      expect(fake.saved.single['ingredients'], isEmpty);
    });
  });

  group('new recipe', () {
    testWidgets('the button shows only with can_edit', (tester) async {
      await _pump(tester, const RecipeBookListScreen());
      expect(_key('recipe-new'), findsOneWidget);
      await _pump(
        tester,
        const RecipeBookListScreen(),
        fake: _Fake(canEdit: false),
      );
      expect(_key('recipe-new'), findsNothing);
    });

    testWidgets('validates, then saves a trial with no change summary', (
      tester,
    ) async {
      final fake = await _pump(tester, const RecipeBookListScreen());
      await tester.tap(_key('recipe-new'));
      await tester.pumpAndSettle();
      expect(find.text('New recipe'), findsWidgets);

      await tester.tap(_key('recipe-save'));
      await tester.pump();
      expect(find.text('Give the recipe a name'), findsOneWidget);

      await tester.enterText(_key('recipe-title'), 'Brownie');
      await tester.tap(_key('recipe-save'));
      await tester.pump();
      expect(find.text('Add at least one ingredient'), findsOneWidget);

      await tester.enterText(_key('ing-name-0'), 'Cocoa');
      await tester.enterText(_key('ing-amount-0'), '0');
      await tester.tap(_key('recipe-save'));
      await tester.pump();
      expect(
        find.text('Every ingredient needs an amount above zero'),
        findsOneWidget,
      );

      await tester.enterText(_key('ing-amount-0'), '100');
      await tester.tap(_key('recipe-save'));
      await tester.pumpAndSettle();
      expect(find.text('What changed?'), findsNothing);
      await tester.tap(_key('save-sheet-confirm'));
      await tester.pumpAndSettle();

      final payload = fake.saved.single;
      expect(payload['base'], isNull);
      expect(payload['item_code'], isNull);
      expect(payload['title'], 'Brownie');
      expect(payload['stage'], 'Trial');
      expect((payload['ingredients'] as List).single['amount'], 100.0);
    });

    testWidgets('a new jar composes its title from flavour and size', (
      tester,
    ) async {
      final fake = await _pump(tester, const RecipeBookListScreen());
      await tester.tap(_key('recipe-new'));
      await tester.pumpAndSettle();
      await tester.tap(_key('recipe-category-jars'));
      await tester.pumpAndSettle();
      expect(_key('recipe-title'), findsNothing);
      await tester.enterText(_key('recipe-flavour'), 'Lotus');
      await tester.tap(
        find.descendant(of: _key('recipe-size'), matching: find.text('Large')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(_key('ing-name-0'), 'Lotus spread');
      await tester.enterText(_key('ing-amount-0'), '30');
      await tester.tap(_key('recipe-add-layer'));
      await tester.pumpAndSettle();
      await tester.enterText(_key('recipe-layer-name-0'), 'Lotus cream');
      await tester.enterText(_key('recipe-layer-grams-0'), '30');
      await tester.tap(_key('recipe-save'));
      await tester.pumpAndSettle();
      await tester.tap(_key('save-sheet-confirm'));
      await tester.pumpAndSettle();
      final payload = fake.saved.single;
      expect(payload['title'], 'Lotus jar (Large)');
      expect(payload['category'], 'jars');
      expect((payload['layers'] as List).single['layer'], 'Lotus cream');
    });

    testWidgets('the Jars chip preselects the Jars kind', (tester) async {
      await _pump(tester, const RecipeBookListScreen());
      await tester.drag(
        find.byKey(const ValueKey('recipe-filter-chips')),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Jars'));
      await tester.pumpAndSettle();
      await tester.tap(_key('recipe-new'));
      await tester.pumpAndSettle();
      expect(_key('recipe-flavour'), findsOneWidget);
    });
  });
}
