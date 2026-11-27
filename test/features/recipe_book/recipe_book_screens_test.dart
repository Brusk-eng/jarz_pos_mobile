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

import 'recipe_book_fixtures.dart';

class _FakeRecipeBookService extends RecipeBookService {
  _FakeRecipeBookService() : super(Dio());

  final requested = <String>[];

  @override
  Future<RecipeBookIndex> listRecipes() async =>
      RecipeBookIndex.fromJson(kRecipeIndexJson);

  @override
  Future<RecipeDetail> getRecipe(String sop) async {
    requested.add(sop);
    return RecipeDetail.fromJson({...kFudgeCakeJson, 'name': sop});
  }
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(420, 1600);
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

void main() {
  group('Recipe list', () {
    testWidgets('groups by track and filters by chip and search', (
      tester,
    ) async {
      await _pump(tester, const RecipeBookListScreen());

      for (final title in [
        'Fudge Cake',
        'Tiramisu',
        'Carrot Cookie',
        'Old Brownie',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('STANDARD LINE'), findsOneWidget);
      expect(find.text('COOKIE JAR LINE'), findsOneWidget);
      expect(find.text('OTHER'), findsOneWidget);
      expect(
        find.textContaining('Trial in progress', findRichText: true),
        findsOneWidget,
      );

      // Trials: a trial recipe, and an approved one with a trial alongside.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Trials'));
      await tester.pumpAndSettle();
      expect(find.text('Fudge Cake'), findsOneWidget);
      expect(find.text('Carrot Cookie'), findsOneWidget);
      expect(find.text('Tiramisu'), findsNothing);
      expect(find.text('Old Brownie'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Approved'));
      await tester.pumpAndSettle();
      expect(find.text('Tiramisu'), findsOneWidget);
      expect(find.text('Carrot Cookie'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.enterText(find.byType(TextField), 'carrot');
      await tester.pumpAndSettle();
      expect(find.text('Carrot Cookie'), findsOneWidget);
      expect(find.text('Fudge Cake'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No recipe matches'), findsOneWidget);
      await tester.tap(find.text('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Old Brownie'), findsOneWidget);
    });
  });

  group('Recipe detail', () {
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

      final container = ProviderScope.containerOf(
        tester.element(find.byType(RecipeDetailScreen)),
      );
      final service =
          container.read(recipeBookServiceProvider) as _FakeRecipeBookService;
      expect(service.requested, ['SOP-0042', 'SOP-0050']);
    });
  });
}
