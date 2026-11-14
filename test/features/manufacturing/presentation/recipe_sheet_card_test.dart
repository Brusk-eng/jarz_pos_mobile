import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/core/constants/api_endpoints.dart';
import 'package:jarz_pos/src/core/network/user_service.dart';
import 'package:jarz_pos/src/features/manufacturing/data/daily_plan_service.dart';
import 'package:jarz_pos/src/features/manufacturing/data/manufacturing_service.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/base_item.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/batch_line.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/daily_plan.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/production_policy.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/recipe_sheet.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/running_batch.dart';
import 'package:jarz_pos/src/features/manufacturing/data/repositories/production_basket_repository.dart';
import 'package:jarz_pos/src/features/manufacturing/presentation/screens/base_production_tab.dart';
import 'package:jarz_pos/src/features/manufacturing/presentation/screens/production_today_screen.dart';
import 'package:jarz_pos/src/features/manufacturing/presentation/widgets/plan_jar_row.dart';
import 'package:jarz_pos/src/features/manufacturing/presentation/widgets/recipe_sheet_card.dart';
import 'package:jarz_pos/src/features/manufacturing/presentation/widgets/view_sop_button.dart';
import 'package:jarz_pos/src/features/manufacturing/state/base_production_providers.dart';
import 'package:jarz_pos/src/features/manufacturing/state/daily_plan_providers.dart';
import 'package:jarz_pos/src/features/manufacturing/state/plan_board_providers.dart';
import 'package:jarz_pos/src/features/manufacturing/state/production_providers.dart';
import 'package:jarz_pos/src/features/manufacturing/state/running_batches_notifier.dart';

import '../../../helpers/mock_services.dart';

/// The jar recipe is one inline sheet for every size typed, not a book icon
/// per row opening a separate SOP screen.

const _recipeSheetPath = '/api/method/jarz_pos.api.sop.get_recipe_sheet';

Map<String, dynamic> _sheetJson() => {
  'title': 'Tiramisu',
  'items': [
    {'item_code': 'Tiramisu Large', 'item_name': 'Tiramisu Large', 'qty': 10},
    {'item_code': 'Tiramisu Medium', 'item_name': 'Tiramisu Medium', 'qty': 12},
  ],
  'total_qty': 22,
  'ingredients': [
    {
      'item_code': 'Coffee beans',
      'item_name': 'Coffee beans',
      'qty': 0.1653,
      'uom': 'Kg',
      'display': '165.3 g',
    },
    {
      'item_code': 'Mascarpone cream with a very long ingredient name',
      'item_name': 'Mascarpone cream with a very long ingredient name',
      'qty': 2.3,
      'uom': 'Kg',
      'display': '2.3 kg',
    },
  ],
  'steps': [
    {
      'step_no': 1,
      'title': 'Brew the coffee',
      'text':
          'Brew 165.3 g of coffee grinds into 496 g of hot water\n'
          'اعمل 496 جرام قهوة من 165.3 جرام بن',
      'per_item': null,
    },
    {
      'step_no': 4,
      'title': 'Fill each jar',
      'text': null,
      'per_item': [
        {
          'item_code': 'Tiramisu Large',
          'item_name': 'Tiramisu Large',
          'qty': 10,
          'text': '40 g savoiardi + 24 g coffee\n40 جرام سافوياردي',
        },
        {
          'item_code': 'Tiramisu Medium',
          'item_name': 'Tiramisu Medium',
          'qty': 12,
          'text': '30 g savoiardi + 18 g coffee\n30 جرام سافوياردي',
        },
      ],
    },
  ],
  'unresolved_tokens': ['{{missing}}'],
};

const _localizations = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Every piece of visible text, flattened — rich text included.
String _allText(WidgetTester tester) => tester
    .widgetList<RichText>(find.byType(RichText))
    .map((r) => r.text.toPlainText())
    .join('\n');

void _useSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _pumpCard(WidgetTester tester, {Locale? locale}) async {
  _useSize(tester, const Size(360, 1800));
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: _localizations,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: SingleChildScrollView(
          child: RecipeSheetCard(
            sheet: RecipeSheet.fromJson(_sheetJson()),
            initiallyExpanded: true,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ── Today screen harness ────────────────────────────────────────────────────

const _large = DailyPlanItem(
  itemCode: 'Tiramisu Large',
  itemName: 'Tiramisu Large',
  itemGroup: 'Jars',
  defaultBom: 'BOM-Tiramisu Large-001',
);

const _lotus = DailyPlanItem(
  itemCode: 'JAR-LOTUS',
  itemName: 'Lotus Jar',
  itemGroup: 'Jars',
  defaultBom: 'BOM-JAR-LOTUS-001',
);

const _template = DailyPlanTemplate(
  planDate: '2026-10-08',
  mix: DailyPlanMix(itemCode: 'MIX-CHEESECAKE', batchQty: 30, uom: 'Kg'),
  items: [_large, _lotus],
);

class _StubBaseItems extends BaseItemsNotifier {
  @override
  Future<BaseItemsPage> build() async => const BaseItemsPage();
}

class _StubRunningBatches extends RunningBatchesNotifier {
  @override
  Future<List<RunningBatch>> build() async => const <RunningBatch>[];
}

class _FakeBasketRepository implements ProductionBasketRepository {
  ProductionBasket? stored;

  @override
  Future<ProductionBasket?> load() async => stored;
  @override
  Future<void> save(ProductionBasket basket) async => stored = basket;
  @override
  Future<void> clear() async => stored = null;
}

Future<MockDio> _pumpToday(
  WidgetTester tester, {
  bool sheetFails = false,
}) async {
  _useSize(tester, const Size(1000, 2000));
  final dio = MockDio()
    ..setResponse(ApiEndpoints.listItemsWithSop, {
      'message': {
        'item_codes': ['Tiramisu Large', 'Tiramisu Medium'],
      },
    })
    ..setResponse(ApiEndpoints.dailyPlanPreview, {
      'message': {
        'mix': {'item_code': 'MIX-CHEESECAKE', 'batch_qty': 30.0, 'uom': 'Kg'},
        'total_mix_qty': 0.0,
        'required_batches': 0.0,
        'planned_batches': 0.0,
        'run_detail': const <Map<String, dynamic>>[],
        'run_count': 0,
      },
    });
  if (sheetFails) {
    dio.setError(
      _recipeSheetPath,
      createMockDioException(statusCode: 500, path: _recipeSheetPath),
    );
  } else {
    dio.setResponse(_recipeSheetPath, {
      'message': {
        'sheets': [_sheetJson()],
      },
    });
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        canAccessProductionBoardProvider.overrideWithValue(true),
        canExecuteProductionProvider.overrideWithValue(true),
        productionPolicyProvider.overrideWith(
          (ref) async => const ProductionPolicy(canExecute: true),
        ),
        baseItemsProvider.overrideWith(_StubBaseItems.new),
        dailyPlanTemplateProvider.overrideWith((ref) async => _template),
        runningBatchesProvider.overrideWith(_StubRunningBatches.new),
        manufacturingServiceProvider.overrideWithValue(
          ManufacturingService(dio),
        ),
        dailyPlanServiceProvider.overrideWithValue(DailyPlanService(dio)),
        productionBasketRepositoryProvider.overrideWithValue(
          _FakeBasketRepository(),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: _localizations,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProductionTodayScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return dio;
}

/// Rows are in template order and the bases section is empty, so the fields
/// are the jars in order.
Finder _jarField(int index) => find.byType(TextField).at(index);

Future<void> _typeJars(WidgetTester tester, int index, String value) async {
  await tester.enterText(_jarField(index), value);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

int _sheetCalls(MockDio dio) =>
    dio.requestLog.where((r) => r['path'] == _recipeSheetPath).length;

// ── Bases tab harness ───────────────────────────────────────────────────────

/// What the server answers for one base: its own sheet, measured in Kg.
Map<String, dynamic> _baseSheetJson({double qty = 9.258}) => {
  'title': 'Fudge Cake',
  'items': [
    {'item_code': 'Fudge Cake', 'item_name': 'Fudge Cake', 'qty': qty},
  ],
  'total_qty': qty,
  'ingredients': [
    {
      'item_code': 'Eggs',
      'item_name': 'Eggs',
      'qty': 30,
      'uom': 'Nos',
      'display': '30 pcs',
    },
  ],
  'steps': [
    {
      'step_no': 1,
      'title': 'Whisk the eggs',
      'text': 'Whisk 30 eggs with 450 g sugar\nاخفق 30 بيضة مع 450 جرام سكر',
      'per_item': null,
    },
  ],
  'unresolved_tokens': const [],
};

/// A cake with a recipe, entered in eggs, and a mix without one.
const _fudgeCake = BaseItem(
  itemCode: 'Fudge Cake',
  itemName: 'Fudge Cake',
  stockUom: 'Kg',
  defaultBom: 'BOM-Fudge Cake-004',
  batchYield: 9.258,
  onHand: 18.5,
  entryMode: kBaseEntryBatch,
  batchUnit: BaseBatchUnit(
    itemCode: 'eggs',
    itemName: 'eggs',
    uom: 'piece',
    qtyPerBatch: 30,
  ),
);

const _blueberryMix = BaseItem(
  itemCode: 'Blueberry mix',
  itemName: 'Blueberry mix',
  stockUom: 'Kg',
  defaultBom: 'BOM-Blueberry mix-003',
  batchYield: 2,
  onHand: 0.58,
  entryMode: kBaseEntryQuantity,
);

class _StubBasesPage extends BaseItemsNotifier {
  @override
  Future<BaseItemsPage> build() async =>
      const BaseItemsPage(items: [_fudgeCake, _blueberryMix]);
}

Future<MockDio> _pumpBases(WidgetTester tester) async {
  _useSize(tester, const Size(1200, 3000));
  final dio = MockDio()
    ..setResponse(ApiEndpoints.listItemsWithSop, {
      'message': {
        'item_codes': ['Fudge Cake'],
      },
    })
    ..setResponse(
      '/api/method/jarz_pos.api.manufacturing.get_material_options',
      {
        'message': {
          'bom_name': 'BOM-x',
          'qty': 1.0,
          'components': <Map<String, dynamic>>[],
        },
      },
    )
    ..setResponse(ApiEndpoints.previewBaseBatch, {
      'message': {
        'item_code': 'Fudge Cake',
        'bom_name': 'BOM-Fudge Cake-004',
        'batches': 1.0,
        'batch_yield': 9.258,
        'item_qty': 9.258,
        'stock_uom': 'Kg',
        'components': const <Map<String, dynamic>>[],
        'has_shortage': false,
        'run_size_ok': true,
        'has_sop': true,
      },
    })
    ..setResponse(_recipeSheetPath, {
      'message': {
        'sheets': [_baseSheetJson()],
      },
    });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        manufacturingServiceProvider.overrideWithValue(
          ManufacturingService(dio),
        ),
        baseItemsProvider.overrideWith(_StubBasesPage.new),
      ],
      child: const MaterialApp(
        localizationsDelegates: _localizations,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: BaseProductionTab()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return dio;
}

/// Ticks a base by tapping its name, then lets the debounced calls land.
Future<void> _tickBase(WidgetTester tester, String itemCode) async {
  await tester.tap(find.text(itemCode).first);
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

void main() {
  group('RecipeSheetCard', () {
    testWidgets('shows the run, the totals and every size', (tester) async {
      await _pumpCard(tester);

      final text = _allText(tester);
      expect(text, contains('Tiramisu · Work instructions'));
      expect(text, contains('For 22 jars'));
      expect(text, contains('10 × Large'));
      expect(text, contains('12 × Medium'));
      expect(text, contains('165.3 g'));
      expect(text, contains('2.3 kg'));
      expect(text, contains('Brew the coffee'));
      expect(text, contains('Brew 165.3 g of coffee grinds'));
      expect(text, contains('Large: 40 g savoiardi + 24 g coffee'));
      expect(text, contains('Medium: 30 g savoiardi + 18 g coffee'));
      expect(
        text,
        contains('1 instruction reference(s) could not be resolved'),
      );
      // English tablet: the Arabic lines are not shown.
      expect(text, isNot(contains('سافوياردي')));
      expect(text, isNot(contains('اعمل')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('an Arabic tablet shows the Arabic lines only', (tester) async {
      await _pumpCard(tester, locale: const Locale('ar'));

      final text = _allText(tester);
      expect(text, contains('اعمل 496 جرام قهوة'));
      expect(text, contains('40 جرام سافوياردي'));
      expect(text, contains('30 جرام سافوياردي'));
      expect(text, isNot(contains('savoiardi')));
      expect(text, isNot(contains('Brew 165.3 g')));
      // An English-only title still shows rather than an empty heading.
      expect(text, contains('Brew the coffee'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('weights are set in bold', (tester) async {
      await _pumpCard(tester);

      final spans = <TextSpan>[];
      for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
        rich.text.visitChildren((span) {
          if (span is TextSpan) spans.add(span);
          return true;
        });
      }
      final grams = spans.firstWhere((s) => s.text == '40 g');
      expect(grams.style?.fontWeight, FontWeight.w800);
    });
  });

  group('Today screen', () {
    testWidgets('no book icon on the jar rows any more', (tester) async {
      await _pumpToday(tester);

      expect(find.byType(ViewSopButton), findsNothing);
      expect(find.byIcon(Icons.menu_book_outlined), findsNothing);
      // Nothing typed: no sheet and no request.
      expect(find.byType(RecipeSheetCard), findsNothing);
    });

    testWidgets('typing a recipe jar shows one sheet under the jars', (
      tester,
    ) async {
      final dio = await _pumpToday(tester);

      await _typeJars(tester, 0, '10');

      expect(find.byType(RecipeSheetCard), findsOneWidget);
      expect(_allText(tester), contains('For 22 jars'));
      expect(_sheetCalls(dio), 1);
      expect(tester.takeException(), isNull);

      // A jar without a recipe does not refetch the sheet.
      await _typeJars(tester, 1, '7');
      expect(_sheetCalls(dio), 1);
      expect(find.byType(RecipeSheetCard), findsOneWidget);
    });

    testWidgets('a jar without a recipe shows no sheet', (tester) async {
      final dio = await _pumpToday(tester);

      await _typeJars(tester, 1, '7');

      expect(find.byType(RecipeSheetCard), findsNothing);
      expect(_sheetCalls(dio), 0);
    });

    testWidgets('a failed sheet is one line with Retry', (tester) async {
      final dio = await _pumpToday(tester, sheetFails: true);

      await _typeJars(tester, 0, '10');

      expect(find.byType(RecipeSheetCard), findsNothing);
      expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
      // The rest of the screen is untouched.
      expect(find.text('Lotus Jar'), findsOneWidget);

      dio.setResponse(_recipeSheetPath, {
        'message': {
          'sheets': [_sheetJson()],
        },
      });
      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(RecipeSheetCard), findsOneWidget);
    });
  });

  group('Bases tab', () {
    testWidgets('a base sheet reads its amount in Kg, not in jars', (
      tester,
    ) async {
      _useSize(tester, const Size(360, 1200));
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: _localizations,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RecipeSheetCard(
                sheet: RecipeSheet.fromJson(_baseSheetJson(qty: 12.5)),
                uomByItem: const {'Fudge Cake': 'Kg'},
                initiallyExpanded: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = _allText(tester);
      expect(text, contains('Fudge Cake · Work instructions'));
      expect(text, contains('12.5 Kg'));
      expect(text, isNot(contains('jars')));
      expect(text, isNot(contains('×')));
      expect(text, contains('30 pcs'));
      expect(text, contains('Whisk 30 eggs with 450 g sugar'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('nothing ticked: no sheet and no request', (tester) async {
      final dio = await _pumpBases(tester);

      expect(find.byType(RecipeSheetSection), findsOneWidget);
      expect(find.byType(RecipeSheetCard), findsNothing);
      expect(_sheetCalls(dio), 0);
    });

    testWidgets('ticking a base with a recipe shows its sheet below the rows', (
      tester,
    ) async {
      final dio = await _pumpBases(tester);

      await _tickBase(tester, 'Fudge Cake');

      expect(find.byType(RecipeSheetCard), findsOneWidget);
      // Folded by default: the heading and the amount, not the method.
      expect(_allText(tester), contains('Fudge Cake · Work instructions'));
      expect(_allText(tester), isNot(contains('Whisk 30 eggs')));
      await tester.tap(find.text('Fudge Cake · Work instructions'));
      await tester.pumpAndSettle();

      final text = _allText(tester);
      expect(text, contains('Fudge Cake · Work instructions'));
      expect(text, contains('9.258 Kg'));
      expect(text, isNot(contains('For 9')));
      expect(text, contains('Whisk 30 eggs'));
      // English tablet: the Arabic line is not shown.
      expect(text, isNot(contains('اخفق')));

      // Asked for the amount on the row, fraction and all, once.
      expect(_sheetCalls(dio), 1);
      final call = dio.requestLog.lastWhere(
        (r) => r['path'] == _recipeSheetPath,
      );
      final lines =
          jsonDecode((call['data'] as Map)['lines'] as String) as List;
      expect(lines.single['item_code'], 'Fudge Cake');
      expect((lines.single['qty'] as num).toDouble(), closeTo(9.258, 1e-9));

      // Below the last row.
      expect(
        tester.getTopLeft(find.byType(RecipeSheetCard)).dy,
        greaterThan(tester.getTopLeft(find.text('Blueberry mix')).dy),
      );
      expect(tester.takeException(), isNull);

      // Unticking it takes the sheet away without another call.
      await tester.tap(find.text('Fudge Cake').first);
      await tester.pumpAndSettle();
      expect(find.byType(RecipeSheetCard), findsNothing);
      expect(_sheetCalls(dio), 1);
    });

    testWidgets('a ticked base without a recipe shows nothing', (tester) async {
      final dio = await _pumpBases(tester);

      await _tickBase(tester, 'Blueberry mix');

      expect(find.byType(RecipeSheetCard), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(_sheetCalls(dio), 0);
    });
  });

  testWidgets('a Plan row no longer offers a recipe behind the caret', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: _localizations,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PlanJarRow(
            row: const PlanRow(
              itemCode: 'Tiramisu Large',
              itemName: 'Tiramisu Large',
              itemGroup: 'Jars',
              bomName: 'BOM-Tiramisu Large-001',
            ),
            quantity: 8,
            onQuantityChanged: (_) {},
            onUseSuggestion: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    expect(find.byType(ViewSopButton), findsNothing);
  });
}
