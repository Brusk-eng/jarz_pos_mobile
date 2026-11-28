import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/features/recipe_book/data/recipe_book_models.dart';
import 'package:jarz_pos/src/features/recipe_book/domain/jar_family_logic.dart';
import 'package:jarz_pos/src/features/recipe_book/domain/recipe_edit_logic.dart';

import 'recipe_book_fixtures.dart';
import 'recipe_book_fixtures_v2.dart';
import 'recipe_book_fixtures_v3.dart';

void main() {
  group('v3 model parsing', () {
    test('a v2 payload still parses: nothing editable, no layers', () {
      final detail = RecipeDetail.fromJson(kFudgeCakeJson);
      expect(detail.canEdit, isFalse);
      expect(detail.editableInPlace, isFalse);
      expect(detail.usedInProduction, isFalse);
      expect(detail.layers, isEmpty);

      final family = JarFamily.fromJson(kTiramisuFamilyJson);
      expect(family.canEdit, isFalse);
      expect(family.assembly.isEmpty, isTrue);
      expect(family.sizes.every((s) => !s.editableInPlace), isTrue);

      expect(RecipeBookIndex.fromJson(kRecipeIndexV2Json).canEdit, isFalse);
    });

    test('a v3 jar family carries the aligned assembly', () {
      final family = JarFamily.fromJson(
        kTiramisuFamilyV3Json(kTiramisuFamilyJson),
      );
      expect(family.canEdit, isTrue);
      expect(family.assembly.aligned, isTrue);
      expect(family.assembly.rows.map((r) => r.layer), [
        'Savoiardi',
        'Coffee soak',
        'Cream',
        'Cocoa',
      ]);
      expect(family.assembly.rows[1].grams['Large'], 23.5);
      expect(family.assembly.totals['Medium'], 116.2);
      expect(family.assembly.sizes, ['Small', 'Medium', 'Large']);
      final medium = family.sizes.firstWhere((s) => s.size == 'Medium');
      expect(medium.editableInPlace, isFalse);
    });

    test('a v3 recipe carries layers and the in-place flags', () {
      final detail = RecipeDetail.fromJson(
        kFudgeV3Json(
          kFudgeCakeJson,
          layers: [
            {'layer': 'Savoiardi', 'grams': 18.7, 'note': null},
            {'layer': 'Cocoa', 'grams': 1.3},
          ],
        ),
      );
      expect(detail.canEdit, isTrue);
      expect(detail.usedInProduction, isTrue);
      expect(detail.layers.map((l) => l.layer), ['Savoiardi', 'Cocoa']);
      expect(detail.layers.first.grams, 18.7);
    });

    test('the edit form parses with steps, token map and next version', () {
      final form = RecipeEditForm.fromJson(kFudgeEditFormJson);
      expect(form.base, 'SOP-0042');
      expect(form.nextVersion, 5);
      expect(form.fromBom, isFalse);
      expect(form.ingredients, hasLength(2));
      expect(form.steps.single.extra['scaling_mode'], 'Per Batch');
      expect(form.tokenMap['[Flour]'], '{{item:flour|grams}}');
    });

    test('save results parse the saved recipe, warnings and created', () {
      final saved = SaveRecipeResult.fromJson({
        'recipe': kFudgeCakeJson,
        'warnings': ['[Sugar]'],
      });
      expect(saved.recipe.name, 'SOP-0042');
      expect(saved.warnings, ['[Sugar]']);

      final layers = SaveLayersResult.fromJson({
        ...kTiramisuFamilyV3Json(kTiramisuFamilyJson),
        'created': ['Small', 'Medium'],
        'updated': ['Large'],
      });
      expect(layers.created, ['Small', 'Medium']);
      expect(layers.updated, ['Large']);
      expect(layers.family.assembly.aligned, isTrue);
    });
  });

  group('placeholders', () {
    test('placeholderFor builds the readable forms', () {
      expect(placeholderFor('Flour'), '[Flour]');
      expect(placeholderFor('Flour', each: true), '[Flour each]');
      expect(placeholderFor('Flour', times: 2), '[Flour ×2]');
      expect(
        placeholderFor('Flour', times: 2.5, each: true),
        '[Flour ×2.5 each]',
      );
      expect(placeholderFor('Flour', times: 1), '[Flour]');
    });

    test('insertAtCursor inserts at the cursor and moves it past the text', () {
      const value = TextEditingValue(
        text: 'Sift  and mix',
        selection: TextSelection.collapsed(offset: 5),
      );
      final next = insertAtCursor(value, '[Flour]');
      expect(next.text, 'Sift [Flour] and mix');
      expect(next.selection.baseOffset, 12);
    });

    test('insertAtCursor replaces a selection and falls back to the end', () {
      const selected = TextEditingValue(
        text: 'Add XX now',
        selection: TextSelection(baseOffset: 4, extentOffset: 6),
      );
      expect(insertAtCursor(selected, '[Egg]').text, 'Add [Egg] now');
      const none = TextEditingValue(text: 'Add ');
      expect(insertAtCursor(none, '[Egg]').text, 'Add [Egg]');
    });
  });

  group('layer grid', () {
    final family = JarFamily.fromJson(
      kTiramisuFamilyV3Json(kTiramisuFamilyJson),
    );
    const sizes = ['Small', 'Medium', 'Large'];

    test('starts from the aligned rows', () {
      final grid = initialLayerGrid(family.assembly);
      expect(grid.map((r) => r.name), [
        'Savoiardi',
        'Coffee soak',
        'Cream',
        'Cocoa',
      ]);
      expect(grid[0].grams['Small'], '18.7');
    });

    test('totals match the fixture per size', () {
      final grid = initialLayerGrid(family.assembly);
      final totals = layerGridTotals(grid, sizes);
      expect(totals['Small'], closeTo(77.5, 1e-9));
      expect(totals['Medium'], closeTo(116.2, 1e-9));
      expect(totals['Large'], closeTo(163.5, 1e-9));
    });

    test('differing sizes merge by layer name', () {
      final grid = initialLayerGrid(
        JarAssembly.fromJson(kAssemblyDifferingJson()),
      );
      expect(grid.map((r) => r.name), ['Savoiardi', 'Sprinkles', 'Cream']);
      expect(grid[1].grams.containsKey('Medium'), isFalse);
    });

    test('payload leaves out empty sizes and blank rows', () {
      final rows = [
        LayerGridRow(
          name: ' Savoiardi ',
          grams: {'Small': '18.7', 'Medium': '', 'Large': '40'},
        ),
        LayerGridRow(),
      ];
      final payload = buildLayersPayload(rows, sizes);
      expect(payload, hasLength(1));
      expect(payload.single['layer'], 'Savoiardi');
      expect(payload.single['grams'], {'Small': 18.7, 'Large': 40.0});
      expect(layerGridTouchedSizes(rows, sizes), ['Small', 'Large']);
    });

    test('validation: name needed, grams positive', () {
      expect(
        validateLayerGrid([
          LayerGridRow(grams: {'Small': '5'}),
        ], sizes),
        DraftIssue.layerNameMissing,
      );
      expect(
        validateLayerGrid([
          LayerGridRow(name: 'Cream', grams: {'Small': '0'}),
        ], sizes),
        DraftIssue.layerGramsInvalid,
      );
      expect(
        validateLayerGrid([
          LayerGridRow(name: 'Cream', grams: {'Small': '5'}),
        ], sizes),
        isNull,
      );
    });

    test('a planned run totals each layer and the filled jar', () {
      final counts = {'Small': 10.0, 'Large': 2.0};
      final savoiardi = family.assembly.rows.first;
      expect(assemblyRowRunTotal(savoiardi, counts), closeTo(267, 1e-9));
      expect(assemblyRunTotal(family.assembly, counts), closeTo(1102, 1e-9));
      expect(assemblyRunTotal(family.assembly, const {}), 0);
    });
  });

  group('recipe payload', () {
    RecipeDraft table() => RecipeDraft(
      title: ' Fudge Cake ',
      category: 'bases',
      yieldQty: '14.29',
      yieldUom: 'Kg',
      prepMins: '85',
      ingredients: [
        IngredientDraft(name: 'Flour', amount: '1,500', unit: 'g'),
        IngredientDraft(),
      ],
      steps: [
        StepDraft(
          title: 'Mix',
          text: 'Sift [Flour].',
          minutes: '10',
          extra: const {'scaling_mode': 'Per Batch'},
        ),
        StepDraft(),
      ],
    );

    test('in place keeps the base and drops blank rows', () {
      final p = buildSaveRecipePayload(
        table(),
        mode: SaveMode.inPlace,
        stage: RecipeStage.approved,
        base: 'SOP-0042',
        itemCode: 'Fudge Cake',
        tokenMap: const {'[Flour]': '{{item:flour|grams}}'},
      );
      expect(p['mode'], 'in_place');
      expect(p['base'], 'SOP-0042');
      expect(p['stage'], 'Approved');
      expect(p['title'], 'Fudge Cake');
      expect(p['yield_qty'], 14.29);
      expect(p['prep_time_mins'], 85);
      final ingredients = p['ingredients'] as List;
      expect(ingredients, hasLength(1));
      expect((ingredients.first as Map)['amount'], 1500.0);
      final steps = p['steps'] as List;
      expect(steps, hasLength(1));
      expect((steps.first as Map)['scaling_mode'], 'Per Batch');
      expect((steps.first as Map)['duration_mins'], 10.0);
      expect(p['layers'], isEmpty);
      expect(p['token_map'], {'[Flour]': '{{item:flour|grams}}'});
    });

    test('a new version carries the change summary', () {
      final p = buildSaveRecipePayload(
        table(),
        mode: SaveMode.newVersion,
        stage: RecipeStage.trial,
        base: 'SOP-0042',
        changeSummary: '  less sugar ',
      );
      expect(p['mode'], 'new_version');
      expect(p['stage'], 'Trial');
      expect(p['change_summary'], 'less sugar');
    });

    test('a new recipe has no base and no item', () {
      final p = buildSaveRecipePayload(
        table(),
        mode: SaveMode.newVersion,
        stage: RecipeStage.trial,
      );
      expect(p['base'], isNull);
      expect(p['item_code'], isNull);
    });

    test('a BOM recipe sends no ingredient table or yield', () {
      final draft = table()..fromBom = true;
      final p = buildSaveRecipePayload(
        draft,
        mode: SaveMode.newVersion,
        stage: RecipeStage.trial,
        base: 'SOP-1',
      );
      expect(p['ingredients'], isEmpty);
      expect(p['yield_qty'], isNull);
    });

    test('jar layers are sent only for the Jars category', () {
      final draft = table()
        ..layers.add(LayerDraft(layer: 'Cream', grams: '46.7'));
      expect(
        buildSaveRecipePayload(
          draft,
          mode: SaveMode.inPlace,
          stage: 'Trial',
        )['layers'],
        isEmpty,
      );
      draft.category = 'jars';
      final layers =
          buildSaveRecipePayload(
                draft,
                mode: SaveMode.inPlace,
                stage: 'Trial',
              )['layers']
              as List;
      expect(layers.single, {'layer': 'Cream', 'grams': 46.7, 'note': null});
    });

    test('a new jar composes its title from flavour and size', () {
      expect(composeJarTitle(' Tiramisu ', 'Small'), 'Tiramisu jar (Small)');
      final draft = RecipeDraft(
        category: 'jars',
        flavour: 'Lotus',
        size: 'Large',
        composeJar: true,
        ingredients: [IngredientDraft(name: 'Lotus', amount: '5')],
      );
      final p = buildSaveRecipePayload(
        draft,
        mode: SaveMode.newVersion,
        stage: 'Trial',
      );
      expect(p['title'], 'Lotus jar (Large)');
      expect(p['category'], 'jars');
    });
  });

  group('draft validation', () {
    test('title is required', () {
      expect(validateDraft(RecipeDraft()), DraftIssue.titleMissing);
    });

    test('a new jar needs flavour and size instead of a title', () {
      final draft = RecipeDraft(composeJar: true, category: 'jars');
      expect(validateDraft(draft), DraftIssue.flavourMissing);
      draft.flavour = 'Lotus';
      expect(validateDraft(draft), DraftIssue.sizeMissing);
      draft.size = 'Small';
      expect(validateDraft(draft), isNull);
    });

    test('amounts must be numbers above zero', () {
      final draft = RecipeDraft(
        title: 'X',
        ingredients: [IngredientDraft(name: 'Flour', amount: '0')],
      );
      expect(validateDraft(draft), DraftIssue.amountInvalid);
      draft.ingredients.first.amount = 'abc';
      expect(validateDraft(draft), DraftIssue.amountInvalid);
      draft.ingredients.first.amount = '12';
      expect(validateDraft(draft), isNull);
    });

    test('a new table recipe needs an ingredient; a BOM one does not', () {
      final draft = RecipeDraft(title: 'X');
      expect(
        validateDraft(draft, requireIngredients: true),
        DraftIssue.noIngredients,
      );
      draft.fromBom = true;
      expect(validateDraft(draft, requireIngredients: true), isNull);
    });

    test('a jar layer needs a name and grams above zero', () {
      final draft = RecipeDraft(title: 'X', category: 'jars')
        ..ingredients.add(IngredientDraft(name: 'a', amount: '1'))
        ..layers.add(LayerDraft(layer: '', grams: '5'));
      expect(validateDraft(draft), DraftIssue.layerNameMissing);
      draft.layers.first
        ..layer = 'Cream'
        ..grams = '-1';
      expect(validateDraft(draft), DraftIssue.layerGramsInvalid);
    });
  });
}
