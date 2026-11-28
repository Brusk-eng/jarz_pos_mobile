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

class _FakeRecipeBookService extends RecipeBookService {
  _FakeRecipeBookService() : super(Dio());

  final requested = <String>[];
  final requestedItems = <String>[];
  final requestedFamilies = <String>[];

  @override
  Future<RecipeBookIndex> listRecipes() async =>
      RecipeBookIndex.fromJson(kRecipeIndexV2Json);

  @override
  Future<RecipeDetail> getRecipe(String sop) async {
    requested.add(sop);
    return RecipeDetail.fromJson({...kFudgeCakeJson, 'name': sop});
  }

  @override
  Future<RecipeDetail> getRecipeByItem(String itemCode) async {
    requestedItems.add(itemCode);
    return RecipeDetail.fromJson(kSpongeCakeBomJson);
  }

  @override
  Future<JarFamily> getJarFamily(String family) async {
    requestedFamilies.add(family);
    return JarFamily.fromJson(
      family == 'Carrot cake' ? kCarrotFamilyJson : kTiramisuFamilyJson,
    );
  }
}

_FakeRecipeBookService _service(WidgetTester tester, Type screen) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(screen)),
  );
  return container.read(recipeBookServiceProvider) as _FakeRecipeBookService;
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  double width = 420,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        canAccessProductionBoardProvider.overrideWithValue(true),
        recipeBookServiceProvider.overrideWithValue(_FakeRecipeBookService()),
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
}

/// Taps a filter chip, scrolling the chip row to it first (from the start).
Future<void> _tapChip(WidgetTester tester, String label) async {
  final row = find.byKey(const ValueKey('recipe-filter-chips'));
  await tester.drag(row, const Offset(600, 0));
  await tester.pumpAndSettle();
  final chip = find.widgetWithText(ChoiceChip, label);
  for (var i = 0; i < 8 && chip.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(row, const Offset(-120, 0));
    await tester.pumpAndSettle();
  }
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

void main() {
  group('Recipe list', () {
    testWidgets(
      'sections by category, one row per jar family, no approved pill',
      (tester) async {
        await _pump(tester, const RecipeBookListScreen());

        // Category headers, in order.
        expect(find.text('CAKES & BISCUITS'), findsOneWidget);
        expect(find.text('MIXES & FILLINGS'), findsOneWidget);
        expect(find.text('JARS'), findsOneWidget);
        expect(find.text('STANDARD LINE'), findsNothing);

        // Jars collapse: one Tiramisu row listing its sizes, no per-size rows.
        expect(find.text('Tiramisu'), findsOneWidget);
        expect(find.text('Small · Medium · Large'), findsOneWidget);
        expect(find.text('Tiramisu Small'), findsNothing);
        expect(find.text('Lotus'), findsOneWidget);
        expect(find.text('Small · Large'), findsOneWidget);
        // A sizeless jar is a normal row inside Jars.
        expect(find.text('Cookie jar second bake'), findsOneWidget);

        // BOM-only recipes say so; SOP recipes keep their version line.
        expect(find.text('Sponge Cake'), findsOneWidget);
        expect(
          find.text('Ingredients · no written method yet'),
          findsNWidgets(2),
        );
        expect(find.textContaining('v4 ·'), findsOneWidget);

        // No Approved pill anywhere; only Trial / Trial running.
        expect(find.text('Approved'), findsNothing);
        expect(find.text('Trial running'), findsNWidgets(2)); // Fudge, Lotus
        expect(find.text('Trial'), findsOneWidget); // Cookie jar second bake
      },
    );

    testWidgets('chips filter by category and trials; search covers families', (
      tester,
    ) async {
      await _pump(tester, const RecipeBookListScreen());

      await _tapChip(tester, 'Jars');
      expect(find.text('Tiramisu'), findsOneWidget);
      expect(find.text('Fudge Cake'), findsNothing);
      // One chip names the section: no header repeats it.
      expect(find.text('JARS'), findsNothing);

      await _tapChip(tester, 'Fillings');
      expect(find.text('Cheesecake Mix'), findsOneWidget);
      expect(find.text('Chocolate ganache'), findsOneWidget);
      expect(find.text('Tiramisu'), findsNothing);

      await _tapChip(tester, 'Cakes');
      expect(find.text('Fudge Cake'), findsOneWidget);
      expect(find.text('Sponge Cake'), findsOneWidget);

      await _tapChip(tester, 'Trials');
      expect(find.text('Fudge Cake'), findsOneWidget);
      expect(find.text('Lotus'), findsOneWidget);
      expect(find.text('Cookie jar second bake'), findsOneWidget);
      expect(find.text('Tiramisu'), findsNothing);

      await _tapChip(tester, 'All');
      await tester.enterText(find.byType(TextField), 'medium');
      await tester.pumpAndSettle();
      expect(find.text('Tiramisu'), findsOneWidget);
      expect(find.text('Lotus'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No recipe matches'), findsOneWidget);
      await tester.tap(find.text('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Sponge Cake'), findsOneWidget);
    });

    testWidgets('a row opens its recipe; a family opens the family screen', (
      tester,
    ) async {
      await _pump(tester, const RecipeBookListScreen());

      await tester.tap(find.text('Sponge Cake'));
      await tester.pumpAndSettle();
      expect(_service(tester, RecipeDetailScreen).requestedItems, [
        'Sponge Cake',
      ]);
      expect(find.text('No written method yet'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fudge Cake'));
      await tester.pumpAndSettle();
      expect(_service(tester, RecipeDetailScreen).requested, ['SOP-0042']);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tiramisu'));
      await tester.pumpAndSettle();
      expect(find.byType(RecipeJarFamilyScreen), findsOneWidget);
      expect(_service(tester, RecipeJarFamilyScreen).requestedFamilies, [
        'Tiramisu',
      ]);
    });
  });

  group('Recipe detail', () {
    testWidgets('a BOM-only recipe scales by ingredient with no method', (
      tester,
    ) async {
      await _pump(tester, const RecipeDetailScreen(sop: 'item:Sponge Cake'));

      expect(_service(tester, RecipeDetailScreen).requestedItems, [
        'Sponge Cake',
      ]);
      expect(find.text('Sponge Cake'), findsOneWidget);
      expect(find.text('No written method yet'), findsOneWidget);
      expect(find.byKey(const ValueKey('recipe-version-button')), findsNothing);
      expect(find.text('Method'), findsNothing);
      expect(find.text('1,500'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('recipe-ingredient-flour')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('recipe-scale-input')),
        '3,000',
      );
      await tester.tap(find.byKey(const ValueKey('recipe-scale-apply')));
      await tester.pumpAndSettle();
      expect(find.text('×2 · 12 kg batch'), findsOneWidget);
      expect(find.text('3,000'), findsOneWidget);
      expect(find.text('60'), findsOneWidget); // 30 eggs × 2
    });

    testWidgets('tapping an ingredient rescales the method', (tester) async {
      await _pump(tester, const RecipeDetailScreen(sop: 'SOP-0042'));

      expect(find.text('Fudge Cake'), findsOneWidget);
      expect(find.text('v4 · Current'), findsOneWidget);
      expect(find.text('×1 · 14.29 kg batch'), findsOneWidget);
      expect(
        find.text('Tap any ingredient to scale the recipe to it'),
        findsOneWidget,
      );
      expect(
        find.textContaining('More cocoa, shorter bake.', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('1,500'), findsOneWidget);

      // ×1 method.
      await tester.tap(find.text('Method'));
      await tester.pumpAndSettle();
      expect(
        find.text('Sift 900 g cocoa.', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('40 min'), findsOneWidget);
      expect(find.text('Target 92–98 °C'), findsOneWidget);

      // "I have 3,000 g flour" → ×2.
      await tester.tap(find.text('Ingredients'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recipe-ingredient-flour')));
      await tester.pumpAndSettle();
      expect(find.text('How much Flour do you have?'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('recipe-scale-input')),
        '3,000',
      );
      await tester.pump();
      expect(find.text('Recipe ×2 · batch 28.58 kg'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('recipe-scale-apply')));
      await tester.pumpAndSettle();

      expect(find.text('×2 · 28.58 kg batch'), findsOneWidget);
      expect(find.text('3,000'), findsOneWidget);
      expect(find.text('1,800'), findsOneWidget);
      expect(find.text('90'), findsOneWidget); // 45 eggs × 2
      expect(find.text('Reset'), findsOneWidget);
      expect(
        find.text('Tap any ingredient to scale the recipe to it'),
        findsNothing,
      );

      await tester.tap(find.text('Method'));
      await tester.pumpAndSettle();
      expect(
        find.text('Sift 1,800 g cocoa.', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text('انخل 1,800 g كاكاو.', findRichText: true),
        findsOneWidget,
      );
      // `each` portion: unchanged. Per Batch duration: doubled.
      expect(
        find.text('Fill each jar with 120 g of batter.', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('1 h 20 min'), findsOneWidget);
      // Fixed duration: unchanged.
      expect(find.text('20 min'), findsOneWidget);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(
        find.text('Sift 900 g cocoa.', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a target batch size sets the factor', (tester) async {
      await _pump(tester, const RecipeDetailScreen(sop: 'SOP-0042'));

      await tester.tap(find.byKey(const ValueKey('recipe-scale-batch')));
      await tester.pumpAndSettle();
      expect(find.text('What batch size do you want?'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('recipe-scale-input')),
        '42.87',
      );
      await tester.tap(find.byKey(const ValueKey('recipe-scale-apply')));
      await tester.pumpAndSettle();
      expect(find.text('×3 · 42.87 kg batch'), findsOneWidget);
      expect(find.text('4,500'), findsOneWidget);
    });

    testWidgets('the version sheet switches version in place', (tester) async {
      await _pump(tester, const RecipeDetailScreen(sop: 'SOP-0042'));

      await tester.tap(find.byKey(const ValueKey('recipe-version-button')));
      await tester.pumpAndSettle();
      expect(find.text('Versions'), findsOneWidget);
      expect(find.text('Less sugar.'), findsOneWidget);
      await tester.tap(find.textContaining('Trial v5'));
      await tester.pumpAndSettle();

      expect(_service(tester, RecipeDetailScreen).requested, [
        'SOP-0042',
        'SOP-0050',
      ]);
    });
  });

  group('Jar family', () {
    testWidgets('the route parameter jar:<family> opens the family screen', (
      tester,
    ) async {
      await _pump(tester, const RecipeDetailScreen(sop: 'jar:Tiramisu'));
      expect(find.byType(RecipeJarFamilyScreen), findsOneWidget);
      expect(find.text('Tiramisu'), findsOneWidget); // app bar
      expect(find.text('Standard line'), findsOneWidget);
    });

    testWidgets('renders every size side by side on a phone', (tester) async {
      await _pump(
        tester,
        const RecipeJarFamilyScreen(family: 'Tiramisu'),
        width: 390,
      );

      for (final size in ['Small', 'Medium', 'Large']) {
        expect(find.byKey(ValueKey('jar-size-$size')), findsOneWidget);
      }
      for (final layer in [
        'Savoiardi',
        'Cheesecake mix',
        'Coffee beans',
        'Powder sugar',
        'Coco powder',
      ]) {
        expect(find.text(layer), findsOneWidget);
      }
      expect(find.text('18.7'), findsOneWidget);
      expect(find.text('43.1'), findsOneWidget);
      expect(find.text('142.2'), findsOneWidget);
      // Large has no powder sugar.
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Per jar'), findsOneWidget);
      expect(find.text('69.5'), findsOneWidget);
      expect(find.text('139'), findsOneWidget);
      expect(find.text('221.4'), findsOneWidget);
      // Calm by default: no Total column, packaging collapsed.
      expect(find.text('Total'), findsNothing);
      expect(find.text('Packaging'), findsOneWidget);
      expect(find.text('Glass jar'), findsNothing);

      await tester.tap(find.text('Packaging'));
      await tester.pumpAndSettle();
      expect(find.text('Glass jar'), findsOneWidget);
      // The real item each size uses, as a quiet caption.
      expect(
        find.text(
          'Small glass jar 147 · Medium glass jar · Large glass jar 330',
        ),
        findsOneWidget,
      );
    });

    testWidgets('planning a run adds the Total column', (tester) async {
      await _pump(
        tester,
        const RecipeJarFamilyScreen(family: 'Tiramisu'),
        width: 390,
      );

      await tester.enterText(
        find.byKey(const ValueKey('jar-count-Small')),
        '10',
      );
      await tester.enterText(
        find.byKey(const ValueKey('jar-count-Medium')),
        '5',
      );
      await tester.pumpAndSettle();

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('374 g'), findsOneWidget); // 10 × 18.7 + 5 × 37.4
      expect(find.text('862 g'), findsOneWidget); // Mix 10 × 43.1 + 5 × 86.2
      expect(find.text('1.39 kg'), findsOneWidget); // 10 × 69.5 + 5 × 139

      // Clearing the counts brings the calm table back.
      await tester.enterText(find.byKey(const ValueKey('jar-count-Small')), '');
      await tester.enterText(
        find.byKey(const ValueKey('jar-count-Medium')),
        '',
      );
      await tester.pumpAndSettle();
      expect(find.text('Total'), findsNothing);
    });

    testWidgets('a single-size family shows one numeric column', (
      tester,
    ) async {
      await _pump(
        tester,
        const RecipeJarFamilyScreen(family: 'Carrot cake'),
        width: 390,
      );
      expect(find.byKey(const ValueKey('jar-size-Medium')), findsOneWidget);
      expect(find.byKey(const ValueKey('jar-size-Small')), findsNothing);
      expect(find.text('Carrot sponge'), findsOneWidget);
      expect(find.text('Packaging'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('jar-count-Medium')),
        '10',
      );
      await tester.pumpAndSettle();
      expect(find.text('1.2 kg'), findsNWidgets(2)); // layer and Per jar total
      expect(find.text('No written method yet'), findsOneWidget);
    });

    testWidgets('size headers and method rows open the right recipe', (
      tester,
    ) async {
      await _pump(
        tester,
        const RecipeJarFamilyScreen(family: 'Tiramisu'),
        width: 390,
      );

      // Method: only the sizes with a SOP, the trial one marked.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('jar-method-Large')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Small · v1'), findsOneWidget);
      expect(find.text('Large · v1'), findsOneWidget);
      expect(find.text('Medium · v1'), findsNothing);
      expect(find.text('Trial'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('jar-size-Small')),
        -200,
        scrollable: find.byType(Scrollable).first,
      );

      // Small has a SOP: its header opens it.
      await tester.tap(find.byKey(const ValueKey('jar-size-Small')));
      await tester.pumpAndSettle();
      expect(_service(tester, RecipeDetailScreen).requested, ['SOP-0030']);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Medium has none: it opens by item.
      await tester.tap(find.byKey(const ValueKey('jar-size-Medium')));
      await tester.pumpAndSettle();
      expect(_service(tester, RecipeDetailScreen).requestedItems, [
        'Tiramisu Medium',
      ]);
    });
  });
}
