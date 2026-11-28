import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/features/recipe_book/data/recipe_book_models.dart';
import 'package:jarz_pos/src/features/recipe_book/domain/jar_family_logic.dart';
import 'package:jarz_pos/src/features/recipe_book/domain/recipe_list_logic.dart';
import 'package:jarz_pos/src/features/recipe_book/domain/recipe_targets.dart';

import 'recipe_book_fixtures.dart';
import 'recipe_book_fixtures_v2.dart';

List<String> _titles(List<RecipeSection> sections) => [
  for (final s in sections)
    for (final e in s.entries) e.title,
];

void main() {
  group('model parsing', () {
    test('a v1 payload still parses: no category, family or families', () {
      final index = RecipeBookIndex.fromJson(kRecipeIndexJson);
      expect(index.families, isEmpty);
      final fudge = index.recipes.first;
      expect(fudge.category, '');
      expect(fudge.effectiveCategory, RecipeCategory.fillings);
      expect(fudge.family, isNull);
      expect(fudge.size, isNull);
      expect(fudge.source, RecipeSource.sop);
      expect(fudge.hasMethod, isTrue); // has versions
      expect(fudge.isBomOnly, isFalse);
    });

    test('a v2 payload carries category, family, size, source', () {
      final index = RecipeBookIndex.fromJson(kRecipeIndexV2Json);
      expect(index.families.map((f) => f.family), ['Lotus', 'Tiramisu']);
      expect(index.families.last.sizes, ['Small', 'Medium', 'Large']);
      final sponge = index.recipes.firstWhere((r) => r.title == 'Sponge Cake');
      expect(sponge.isBomOnly, isTrue);
      expect(sponge.headline, '');
      expect(sponge.versions, isEmpty);
      expect(sponge.hasMethod, isFalse);
      expect(sponge.category, 'bases');
      final small = index.recipes.firstWhere(
        (r) => r.title == 'Tiramisu Small',
      );
      expect(small.family, 'Tiramisu');
      expect(small.size, 'Small');
      expect(small.hasMethod, isTrue);
    });

    test('a BOM-only detail has no version and a null name', () {
      final detail = RecipeDetail.fromJson(kSpongeCakeBomJson);
      expect(detail.isBomOnly, isTrue);
      expect(detail.version, 0);
      expect(detail.versions, isEmpty);
      expect(detail.steps, isEmpty);
      expect(detail.category, 'bases');
      expect(detail.ingredients, hasLength(2));
    });

    test('a jar family parses, sizes sorted, missing layers left out', () {
      final family = JarFamily.fromJson(kTiramisuFamilyJson);
      expect(family.sizes.map((s) => s.size), ['Small', 'Medium', 'Large']);
      expect(family.sizes.first.sop, 'SOP-0030');
      expect(family.sizes[1].sop, isNull);
      expect(family.sizes.last.isTrial, isTrue);
      final sugar = family.layers.firstWhere((l) => l.name == 'powder sugar');
      expect(sugar.perJar.containsKey('Large'), isFalse);
      expect(family.packaging.first.unit, 'Nos');
      expect(family.packaging.last.items['Large'], 'glass jar 330');
    });
  });

  group('list sections', () {
    final recipes = RecipeBookIndex.fromJson(kRecipeIndexV2Json).recipes;

    test('All: categories in order, jars collapsed to one row per family', () {
      final sections = buildRecipeSections(recipes);
      expect(sections.map((s) => s.category), ['bases', 'fillings', 'jars']);
      expect(_titles(sections), [
        'Fudge Cake',
        'Sponge Cake',
        'Cheesecake Mix',
        'Chocolate ganache',
        // Jars sort by name; the sizeless jar is a normal row among them.
        'Cookie jar second bake',
        'Lotus',
        'Tiramisu',
      ]);
      final tiramisu = sections.last.entries.last as RecipeFamilyEntry;
      expect(tiramisu.sizes, ['Small', 'Medium', 'Large']);
      expect(tiramisu.members, hasLength(3));
      expect(tiramisu.track, 'Standard line');
    });

    test('category chips keep only that category', () {
      expect(
        _titles(buildRecipeSections(recipes, filter: RecipeFilter.fillings)),
        ['Cheesecake Mix', 'Chocolate ganache'],
      );
      expect(_titles(buildRecipeSections(recipes, filter: RecipeFilter.jars)), [
        'Cookie jar second bake',
        'Lotus',
        'Tiramisu',
      ]);
      expect(
        _titles(buildRecipeSections(recipes, filter: RecipeFilter.bases)),
        ['Fudge Cake', 'Sponge Cake'],
      );
    });

    test(
      'Trials: a trial recipe, a recipe with a trial, a family with one',
      () {
        expect(
          _titles(buildRecipeSections(recipes, filter: RecipeFilter.trials)),
          ['Fudge Cake', 'Cookie jar second bake', 'Lotus'],
        );
      },
    );

    test('search matches title, family name and size; every word', () {
      expect(_titles(buildRecipeSections(recipes, query: 'tira')), [
        'Tiramisu',
      ]);
      // Size words find the families that have that size.
      expect(_titles(buildRecipeSections(recipes, query: 'medium')), [
        'Tiramisu',
      ]);
      expect(_titles(buildRecipeSections(recipes, query: 'LOTUS large')), [
        'Lotus',
      ]);
      expect(_titles(buildRecipeSections(recipes, query: 'tiramisu zzz')), []);
      expect(
        _titles(
          buildRecipeSections(
            recipes,
            query: 'cake',
            filter: RecipeFilter.bases,
          ),
        ),
        ['Fudge Cake', 'Sponge Cake'],
      );
    });

    test('a v1 payload (no categories) lists everything under fillings', () {
      final v1 = RecipeBookIndex.fromJson(kRecipeIndexJson).recipes;
      final sections = buildRecipeSections(v1);
      expect(sections.map((s) => s.category), ['fillings']);
      expect(sectionEntryCount(sections), 4);
    });

    test('family name matching is case-insensitive across members', () {
      final mixed = [
        const RecipeSummary(
          key: 'a',
          title: 'Mango Small',
          category: 'jars',
          family: 'Mango',
          size: 'Small',
        ),
        const RecipeSummary(
          key: 'b',
          title: 'mango Large',
          category: 'jars',
          family: 'mango',
          size: 'Large',
        ),
      ];
      final entries = collapseJarFamilies(mixed);
      expect(entries, hasLength(1));
      expect((entries.single as RecipeFamilyEntry).sizes, ['Small', 'Large']);
    });
  });

  group('targets', () {
    test('encode and decode the route parameter', () {
      expect(recipeTargetSop('SOP-1'), 'SOP-1');
      expect(itemOfTarget(recipeTargetItem('Sponge Cake')), 'Sponge Cake');
      expect(jarFamilyOfTarget(recipeTargetJar('Tiramisu')), 'Tiramisu');
      expect(jarFamilyOfTarget('SOP-1'), isNull);
      expect(itemOfTarget('SOP-1'), isNull);
      // A link that was encoded twice still reads.
      expect(
        normalizeRecipeTarget(Uri.encodeComponent('jar:Carrot cake')),
        'jar:Carrot cake',
      );
      expect(normalizeRecipeTarget('SOP-0042'), 'SOP-0042');
    });

    test('a list row opens its SOP, else its item', () {
      final recipes = RecipeBookIndex.fromJson(kRecipeIndexV2Json).recipes;
      final fudge = recipes.firstWhere((r) => r.title == 'Fudge Cake');
      final sponge = recipes.firstWhere((r) => r.title == 'Sponge Cake');
      expect(recipeTargetFor(fudge), 'SOP-0042');
      expect(recipeTargetFor(sponge), 'item:Sponge Cake');
      final family = JarFamily.fromJson(kTiramisuFamilyJson);
      expect(recipeTargetForSize(family.sizes[0]), 'SOP-0030');
      expect(recipeTargetForSize(family.sizes[1]), 'item:Tiramisu Medium');
    });
  });

  group('jar run totals', () {
    final family = JarFamily.fromJson(kTiramisuFamilyJson);

    test('Σ count × per jar, per layer, with the jar total', () {
      final run = computeJarRun(family, {'Small': 10, 'Medium': 5});
      expect(run.hasRun, isTrue);
      expect(run.jars, 15);
      expect(run.layers['savoiardi'], closeTo(10 * 18.7 + 5 * 37.4, 1e-9));
      expect(run.layers['cheesecake mix'], closeTo(862, 1e-9));
      expect(run.totalGrams, closeTo(10 * 69.5 + 5 * 139.0, 1e-9));
      expect(run.packaging['glass jar'], 15);
    });

    test('a size missing a layer contributes nothing to it', () {
      final run = computeJarRun(family, {'Large': 2});
      // Large has no powder sugar.
      expect(run.layers['powder sugar'], 0);
      expect(run.layers['coco powder'], closeTo(8.6, 1e-9));
      expect(run.totalGrams, closeTo(442.8, 1e-9));
    });

    test('no counts, zero, negatives and NaN mean no run', () {
      expect(computeJarRun(family, const {}).hasRun, isFalse);
      expect(
        computeJarRun(family, {
          'Small': 0,
          'Medium': -3,
          'Large': double.nan,
        }).hasRun,
        isFalse,
      );
    });

    test('jar grams fall back to the sum of the gram layers', () {
      const size = JarSize(size: 'Small');
      const fam = JarFamily(
        family: 'X',
        sizes: [size],
        layers: [
          JarLayer(key: 'a', name: 'a', perJar: {'Small': 10.5}),
          JarLayer(key: 'b', name: 'b', perJar: {'Small': 4.5}),
          JarLayer(key: 'c', name: 'c', unit: 'Nos', perJar: {'Small': 1}),
        ],
      );
      expect(jarGramsFor(fam, size), 15);
      expect(jarGramsFor(const JarFamily(family: 'Y'), size), isNull);
    });

    test('weights switch to kg from 1,000 g', () {
      expect(formatWeight(430), '430 g');
      expect(formatWeight(999.9), '999.9 g');
      expect(formatWeight(1250), '1.25 kg');
      expect(formatWeight(12500), '12.5 kg');
      expect(formatRunAmount(1390, 'g'), '1.39 kg');
      expect(formatRunAmount(15, 'Nos'), '15');
    });
  });
}
