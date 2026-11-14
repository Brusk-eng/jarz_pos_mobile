import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/core/constants/api_endpoints.dart';
import 'package:jarz_pos/src/features/manufacturing/data/daily_plan_service.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/basket_rollup.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/batch_line.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/daily_plan.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/material_options.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/production_policy.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/production_suggestion.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/stock_alternative.dart';
import 'package:jarz_pos/src/features/manufacturing/data/repositories/production_basket_repository.dart';
import 'package:jarz_pos/src/features/manufacturing/presentation/screens/production_plan_tab.dart';
import 'package:jarz_pos/src/features/manufacturing/presentation/widgets/plan_jar_row.dart';
import 'package:jarz_pos/src/features/manufacturing/state/daily_plan_providers.dart';
import 'package:jarz_pos/src/features/manufacturing/state/plan_board_providers.dart';
import 'package:jarz_pos/src/features/manufacturing/state/production_basket_notifier.dart';
import 'package:jarz_pos/src/features/manufacturing/state/production_providers.dart';

import '../../../helpers/mock_services.dart';

class _FakeBasketRepository implements ProductionBasketRepository {
  _FakeBasketRepository([this._saved]);

  final ProductionBasket? _saved;

  @override
  Future<ProductionBasket?> load() async => _saved;
  @override
  Future<void> save(ProductionBasket basket) async {}
  @override
  Future<void> clear() async {}
}

class _StubSuggestionsNotifier extends ProductionSuggestionsNotifier {
  _StubSuggestionsNotifier(this._page);
  final ProductionSuggestionsPage _page;

  @override
  Future<ProductionSuggestionsPage> build() async => _page;
}

/// Stands in for quantities typed on the Today screen, which writes the draft
/// and nothing else, before the full board is opened.
class _SeededDraft extends DailyPlanDraftNotifier {
  _SeededDraft(this._quantities);
  final Map<String, int> _quantities;
  @override
  DailyPlanDraft build() {
    super.build();
    return DailyPlanDraft(quantities: _quantities);
  }
}

class _SeededBasket extends ProductionBasketNotifier {
  _SeededBasket(this._seed);
  final ProductionBasket _seed;
  @override
  ProductionBasket build() => _seed;
}

ProductionSuggestion _item({
  required String itemCode,
  String status = ProductionStatus.critical,
  double onHand = 20,
  double? daysOfCover = 2.2,
  int suggestedBatches = 5,
  double bomQty = 10,
  int? canMakeNowBatches,
  bool stockIsNegative = false,
  LimitingComponent? limiting,
}) {
  return ProductionSuggestion(
    itemCode: itemCode,
    itemName: '$itemCode name',
    itemGroup: 'Jars',
    stockUom: 'Nos',
    defaultBom: 'BOM-$itemCode',
    bomQty: bomQty,
    onHand: onHand,
    velocity60d: 5,
    effectiveVelocity: 9,
    targetDays: 10,
    daysOfCover: daysOfCover,
    status: status,
    stockIsNegative: stockIsNegative,
    suggestedBatches: suggestedBatches,
    suggestedUnits: suggestedBatches * bomQty,
    canMakeNowBatches: canMakeNowBatches,
    limitingComponent: limiting,
  );
}

DailyPlanTemplate _template(List<String> itemCodes, {String? existingPlan}) {
  return DailyPlanTemplate(
    planDate: '2026-08-02',
    mix: const DailyPlanMix(itemCode: 'BASE-MIX', batchQty: 12, uom: 'Kg'),
    existingPlan: existingPlan,
    items: [
      for (final code in itemCodes)
        DailyPlanItem(
          itemCode: code,
          itemName: '$code name',
          itemGroup: 'Jars',
          defaultBom: 'BOM-$code',
          mixQtyPerUnit: 0.1,
          jarsPerBatch: 120,
          usesMix: true,
        ),
    ],
  );
}

/// A plan service that answers without a network, so the mixer preview the
/// draft fires on every edit cannot reach Dio.
DailyPlanService _planService([Map<String, dynamic>? savedPlan]) {
  final dio = MockDio();
  if (savedPlan != null) {
    // Spelled as wire JSON rather than `plan.toJson()`: the generated map
    // holds real `DailyPlanLine` objects, which a real response never does, and
    // reading it back blows up in the cast.
    dio.setResponse(ApiEndpoints.dailyPlanGet, {'message': savedPlan});
  }
  dio.setResponse(ApiEndpoints.dailyPlanPreview, {
    'message': {
      'mix': {'item_code': 'BASE-MIX', 'batch_qty': 12, 'uom': 'Kg'},
      'total_mix_qty': 6.0,
      'required_batches': 0.5,
      'run_detail': [
        {'size': 1.0, 'quality': 'acceptable'},
      ],
      'run_count': 1,
    },
  });
  dio.setResponse(ApiEndpoints.dailyPlanSave, {
    'message': {'name': 'DPP-0001', 'plan_date': '2026-08-02'},
  });
  return DailyPlanService(dio);
}

Future<void> _pump(
  WidgetTester tester, {
  required ProductionSuggestionsPage page,
  DailyPlanTemplate? template,
  Map<String, dynamic>? savedPlan,
  BasketRollup? rollup,
  ProductionBasket? basket,
  ProductionBasket? restored,
  Map<String, int>? draft,
  Size size = const Size(430, 1200),
  Locale? locale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productionBasketRepositoryProvider.overrideWithValue(
          _FakeBasketRepository(restored),
        ),
        if (basket != null)
          productionBasketProvider.overrideWith(() => _SeededBasket(basket)),
        if (draft != null)
          dailyPlanDraftProvider.overrideWith(() => _SeededDraft(draft)),
        productionSuggestionsProvider.overrideWith(
          () => _StubSuggestionsNotifier(page),
        ),
        dailyPlanTemplateProvider.overrideWith(
          (ref) async =>
              template ?? _template(page.items.map((i) => i.itemCode).toList()),
        ),
        bomReadinessProvider.overrideWith(
          (ref) async => const BomReadiness(ok: true),
        ),
        dailyPlanServiceProvider.overrideWithValue(_planService(savedPlan)),
        basketRollupProvider.overrideWith((ref) async => rollup),
        materialOptionsProvider.overrideWith(
          (ref, request) async => MaterialOptions(
            bomName: request.bomName,
            qty: request.qty,
            components: const [],
          ),
        ),
        productionPolicyProvider.overrideWith(
          (ref) async => ProductionPolicy(serverDate: DateTime(2026, 8, 2)),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const Scaffold(body: ProductionPlanTab()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(ProductionPlanTab)));

/// Closes a confirmation SnackBar without moving the clock.
///
/// Its auto-dismiss is a `Timer` rather than a frame, so `pumpAndSettle()`
/// returns with the timer still pending and the binding fails the test on
/// teardown. Clearing the messenger cancels the timer and settles the exit in
/// the same frame.
Future<void> _drainSnackBar(WidgetTester tester) async {
  await tester.pumpAndSettle();
  ScaffoldMessenger.of(
    tester.element(find.byType(ProductionPlanTab)),
  ).clearSnackBars();
  await tester.pumpAndSettle();
}

/// One flavour's row, by item code rather than by anything on screen.
Finder _row(String itemCode) => find.byWidgetPredicate(
  (w) => w is PlanJarRow && w.row.itemCode == itemCode,
);

/// The jar field on that row.
Finder _quantityField(String itemCode) =>
    find.descendant(of: _row(itemCode), matching: find.byType(TextField));

/// What the operator can actually SEE in that field.
String _shown(WidgetTester tester, String itemCode) =>
    tester.widget<TextField>(_quantityField(itemCode)).controller!.text;

void main() {
  testWidgets('a row carries the figures AND the field', (tester) async {
    // The merge, in one assertion: the numbers used to be on the Plan tab and
    // the field on Daily, so deciding a quantity meant remembering a cover
    // figure printed on a screen you had to leave.
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [_item(itemCode: 'CAKE-A', suggestedBatches: 5)],
        summary: const ProductionSummary(critical: 1),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
    );

    expect(find.text('CAKE-A name'), findsOneWidget);
    // Closed, the row carries the two figures a quantity is decided from, the
    // one-tap offer and the field. The status chip is the only "Critical" on
    // screen now that the filter chip counts instead.
    expect(find.text('2.2 d · 20 on hand'), findsOneWidget);
    expect(find.text('Use 50'), findsOneWidget);
    expect(find.text('Critical'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Critical 1'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Open, the rest of what the board knows.
    await _expandRow(tester);
    expect(find.text('On hand'), findsOneWidget);
    expect(find.text('Sells / day'), findsOneWidget);
    expect(find.text('Cover'), findsOneWidget);
    // "Make 5 batches · 50 Nos" — the arithmetic is already done.
    expect(find.textContaining('Make 5 batches'), findsOneWidget);
    expect(find.textContaining('to reach 10 days cover'), findsOneWidget);
  });

  testWidgets('the suggestion is offered, never pre-typed', (tester) async {
    // The rule this feature has already paid for: 50 planned, 42 made, one
    // un-edited tap booking 50. Nothing may reach the field without a tap.
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [_item(itemCode: 'CAKE-A', suggestedBatches: 5)],
        summary: const ProductionSummary(critical: 1),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
    );

    expect(_shown(tester, 'CAKE-A'), isEmpty);
    final container = _container(tester);
    expect(container.read(productionBasketProvider).isEmpty, isTrue);
    expect(container.read(dailyPlanDraftProvider).quantities, isEmpty);

    // One tap, and the number lands where it can be seen and corrected.
    await tester.tap(find.text('Use 50'));
    await tester.pumpAndSettle();

    expect(_shown(tester, 'CAKE-A'), '50');
    expect(container.read(dailyPlanDraftProvider).quantities['CAKE-A'], 50);
    expect(container.read(productionBasketProvider).lines.single.units, 50);
  });

  testWidgets('one typed quantity drives the plan and the queue', (
    tester,
  ) async {
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [_item(itemCode: 'CAKE-A', suggestedBatches: 5)],
        summary: const ProductionSummary(critical: 1),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
    );

    await tester.enterText(find.byType(TextField), '24');
    await tester.pumpAndSettle();

    final container = _container(tester);
    expect(container.read(dailyPlanDraftProvider).quantities['CAKE-A'], 24);
    final line = container.read(productionBasketProvider).lines.single;
    expect(line.itemCode, 'CAKE-A');
    expect(line.bomName, 'BOM-CAKE-A');
    // 24 jars off a BOM yielding 10 is 2.4 runs — the conversion the operator
    // no longer does on paper.
    expect(line.units, 24);
    expect(line.batches, closeTo(2.4, 0.0001));

    // Emptied means gone, not a zeroed line left in the queue.
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(container.read(productionBasketProvider).lines, isEmpty);
    expect(container.read(dailyPlanDraftProvider).quantities, isEmpty);
  });

  testWidgets('a decimal in the jar field is shown as wrong, never swallowed', (
    tester,
  ) async {
    // The old digits-only filter dropped the point: "1.360" (the kilos a
    // strawberry mix needed) arrived as 1360 jars and was queued.
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [_item(itemCode: 'CAKE-A', suggestedBatches: 5)],
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
    );

    await tester.enterText(_quantityField('CAKE-A'), '1.360');
    await tester.pumpAndSettle();

    final container = _container(tester);
    expect(_shown(tester, 'CAKE-A'), '1.360');
    // On the row, and on the action bar in case the row is scrolled away.
    expect(
      find.text('Whole jars only. Mixes and cakes go on the Bases tab.'),
      findsNWidgets(2),
    );
    // A red field queues nothing.
    expect(container.read(dailyPlanDraftProvider).quantities, isEmpty);
    expect(container.read(productionBasketProvider).lines, isEmpty);

    await tester.enterText(_quantityField('CAKE-A'), '34');
    await tester.pumpAndSettle();
    expect(
      find.text('Whole jars only. Mixes and cakes go on the Bases tab.'),
      findsNothing,
    );
    expect(container.read(dailyPlanDraftProvider).quantities, {'CAKE-A': 34});
  });

  testWidgets('a stray point queues nothing and holds both actions', (
    tester,
  ) async {
    // Nothing behind a red field: a kept last-valid number was posted by
    // every reader of the queue that could not see the field.
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [_item(itemCode: 'CAKE-A', suggestedBatches: 5)],
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
    );

    await tester.enterText(_quantityField('CAKE-A'), '12');
    await tester.pumpAndSettle();
    await tester.enterText(_quantityField('CAKE-A'), '12.');
    await tester.pumpAndSettle();

    final container = _container(tester);
    // Not snapped back to "12", nor wiped by the 0 it reported.
    expect(_shown(tester, 'CAKE-A'), '12.');
    expect(container.read(productionBasketProvider).lines, isEmpty);
    expect(container.read(dailyPlanDraftProvider).quantities, isEmpty);
    expect(_button(tester, 'Start batches').onPressed, isNull);
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Save plan'),
              matching: find.byWidgetPredicate((w) => w is FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(_quantityField('CAKE-A'), '12');
    await tester.pumpAndSettle();
    expect(container.read(productionBasketProvider).lines.single.units, 12);
    expect(
      find.text('Whole jars only. Mixes and cakes go on the Bases tab.'),
      findsNothing,
    );
  });

  testWidgets('a red entry survives its row leaving the screen', (
    tester,
  ) async {
    // Rows are disposed when they scroll away or a filter hides them. Held
    // only by the row, "1.360" came back as a plain "1" with Start enabled.
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [_item(itemCode: 'CAKE-A', suggestedBatches: 5)],
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
    );

    await tester.enterText(_quantityField('CAKE-A'), '1');
    await tester.pumpAndSettle();
    await tester.enterText(_quantityField('CAKE-A'), '1.360');
    await tester.pumpAndSettle();

    final container = _container(tester);
    expect(container.read(productionBasketProvider).lines, isEmpty);
    container.read(productionFilterProvider.notifier).state =
        const ProductionFilter().toggle(ProductionStatus.ok);
    await tester.pumpAndSettle();
    expect(_row('CAKE-A'), findsNothing);
    expect(_button(tester, 'Start batches').onPressed, isNull);

    container.read(productionFilterProvider.notifier).state =
        const ProductionFilter();
    await tester.pumpAndSettle();
    expect(_shown(tester, 'CAKE-A'), '1.360');
    expect(_button(tester, 'Start batches').onPressed, isNull);
  });

  testWidgets('Clear empties a red field and lets the day start again', (
    tester,
  ) async {
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [_item(itemCode: 'CAKE-A', suggestedBatches: 5)],
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
    );

    await tester.enterText(_quantityField('CAKE-A'), '12');
    await tester.pumpAndSettle();
    await tester.enterText(_quantityField('CAKE-A'), '12.');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pumpAndSettle();

    final container = _container(tester);
    expect(_shown(tester, 'CAKE-A'), '');
    expect(container.read(productionBasketProvider).lines, isEmpty);
    expect(
      find.text('Whole jars only. Mixes and cakes go on the Bases tab.'),
      findsNothing,
    );

    expect(_button(tester, 'Start batches').onPressed, isNull);
    expect(container.read(planInvalidEntriesProvider), isEmpty);
  });

  testWidgets('flags negative stock so somebody counts the item', (
    tester,
  ) async {
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [
          _item(
            itemCode: 'CAKE-NEG',
            onHand: -36,
            daysOfCover: 0,
            stockIsNegative: true,
            suggestedBatches: 15,
          ),
        ],
        summary: const ProductionSummary(critical: 1),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
    );

    // The mark is on the closed row, because a figure computed as though the
    // hole were zero must not read as an ordinary small number.
    expect(find.byIcon(Icons.error_outline), findsWidgets);
    // cover clamps at zero rather than rendering a negative day count
    expect(find.textContaining('0 d ·'), findsOneWidget);

    await _expandRow(tester);
    expect(find.text('Stock is negative — count this item'), findsOneWidget);
  });

  testWidgets(
    'a materials-capped row offers the achievable number and names the '
    'component',
    (tester) async {
      await _pump(
        tester,
        page: ProductionSuggestionsPage(
          items: [
            _item(
              itemCode: 'CAKE-CAP',
              suggestedBatches: 12,
              canMakeNowBatches: 3,
              limiting: const LimitingComponent(
                itemCode: 'RM-LABEL',
                itemName: 'Molten Jar Label',
                reason: 'insufficient_stock',
              ),
            ),
          ],
          summary: const ProductionSummary(critical: 1),
          velocityUpdatedOn: '2026-08-01 00:00:00',
        ),
      );

      // The capped offer is on the closed row, in its own colour.
      expect(find.text('Use 30'), findsOneWidget);

      // What capped it, and which component, behind the caret.
      await _expandRow(tester);
      expect(find.textContaining('Molten Jar Label'), findsOneWidget);
      expect(find.textContaining('capped at 3'), findsOneWidget);
    },
  );

  testWidgets('a row with no material left can still be planned', (
    tester,
  ) async {
    // Planning it is not authorizing it: Start batches still checks the
    // consolidated stock, and the operator can move stock in first.
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [
          _item(
            itemCode: 'CAKE-BLOCKED',
            suggestedBatches: 12,
            canMakeNowBatches: 0,
            limiting: const LimitingComponent(
              itemCode: 'RM-GONE',
              itemName: 'Missing material',
              reason: 'insufficient_stock',
            ),
          ),
        ],
        summary: const ProductionSummary(critical: 1),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
    );

    await _expandRow(tester);
    expect(
      find.text('Cannot start — Missing material is short'),
      findsOneWidget,
    );

    await tester.tap(find.text('Use 120'));
    await tester.pumpAndSettle();

    final line = _container(tester).read(productionBasketProvider).lines.single;
    expect(line.itemCode, 'CAKE-BLOCKED');
    expect(line.units, 120);
  });

  testWidgets('a blocked row whose material is in another store says so', (
    tester,
  ) async {
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [
          _item(
            itemCode: 'CAKE-BLOCKED',
            suggestedBatches: 12,
            canMakeNowBatches: 0,
            limiting: const LimitingComponent(
              itemCode: 'RM-LABEL',
              itemName: 'Jar label',
              uom: 'Nos',
              sourceWarehouse: 'Raw Material - J',
              requiredQty: 8,
              reason: 'insufficient_stock',
              availableElsewhere: 40.5,
              alternatives: [
                StockAlternative(warehouse: 'Stores - J', availableQty: 40.5),
              ],
            ),
          ),
        ],
        summary: const ProductionSummary(critical: 1),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
    );

    await _expandRow(tester);
    expect(
      find.text(
        '40.5 Nos is in Stores - J — needs a stock transfer, not a purchase',
      ),
      findsOneWidget,
    );
  });

  testWidgets('warns when velocity has never been calculated', (tester) async {
    // A board full of zeroes almost always means the weekly job never ran, not
    // that nothing sells.
    await _pump(
      tester,
      page: const ProductionSuggestionsPage(
        items: [],
        summary: ProductionSummary(),
      ),
      template: const DailyPlanTemplate(),
    );

    expect(
      find.textContaining('Sales velocity has never been calculated'),
      findsOneWidget,
    );
    expect(find.text('Nothing needs producing'), findsOneWidget);
  });

  testWidgets('Fill the day is hidden when nothing needs producing', (
    tester,
  ) async {
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [
          _item(
            itemCode: 'CAKE-OK',
            status: ProductionStatus.ok,
            daysOfCover: 30,
            suggestedBatches: 0,
          ),
        ],
        summary: const ProductionSummary(ok: 1),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
    );

    // Offered only when there is something to fill: the menu opens, and the
    // entry is simply not in it.
    await _openActions(tester);
    expect(find.text('Fill the day'), findsNothing);
  });

  testWidgets('Fill the day fills the fields, and says what it skipped', (
    tester,
  ) async {
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [
          _item(itemCode: 'CAKE-A', suggestedBatches: 4),
          _item(
            itemCode: 'CAKE-B',
            status: ProductionStatus.low,
            suggestedBatches: 6,
            canMakeNowBatches: 2,
          ),
          _item(
            itemCode: 'CAKE-BLOCKED',
            suggestedBatches: 6,
            canMakeNowBatches: 0,
          ),
          _item(
            itemCode: 'CAKE-OK',
            status: ProductionStatus.ok,
            suggestedBatches: 0,
          ),
        ],
        summary: const ProductionSummary(critical: 1, low: 1),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
    );

    await _openActions(tester);
    await tester.tap(find.text('Fill the day'));
    await tester.pumpAndSettle();

    final container = _container(tester);
    final quantities = container.read(dailyPlanDraftProvider).quantities;
    // Capped at what materials allow, and the untouched row stays untouched.
    expect(quantities, {'CAKE-A': 40, 'CAKE-B': 20});
    expect(
      container.read(productionBasketProvider).lines.map((l) => l.itemCode),
      ['CAKE-A', 'CAKE-B'],
    );
    // Every one of those numbers is now on screen, where it can be corrected.
    expect(_shown(tester, 'CAKE-A'), '40');
    expect(_shown(tester, 'CAKE-B'), '20');
    // A silent cap would read as "covered everything" when it was not.
    expect(find.textContaining('1 skipped'), findsOneWidget);

    await _drainSnackBar(tester);
  });

  testWidgets('Save plan and Start batches are two different actions', (
    tester,
  ) async {
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [_item(itemCode: 'CAKE-A', suggestedBatches: 5)],
        summary: const ProductionSummary(critical: 1),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
    );

    expect(find.text('Save plan'), findsOneWidget);
    expect(find.text('Start batches'), findsOneWidget);

    // Nothing planned yet: neither action has anything to act on.
    expect(_button(tester, 'Save plan').onPressed, isNull);
    expect(_button(tester, 'Start batches').onPressed, isNull);

    await tester.tap(find.text('Use 50'));
    await tester.pumpAndSettle();

    expect(_button(tester, 'Save plan').onPressed, isNotNull);
    expect(_button(tester, 'Start batches').onPressed, isNotNull);
  });

  testWidgets('Start batches refuses a day the roll-up says is short', (
    tester,
  ) async {
    // The check only the consolidated roll-up can make: a material shared by
    // two rows passes each row on its own and still leaves the day short.
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [_item(itemCode: 'CAKE-A', suggestedBatches: 5)],
        summary: const ProductionSummary(critical: 1),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
      basket: const ProductionBasket(
        lines: [
          BatchLine(
            itemCode: 'CAKE-A',
            itemName: 'CAKE-A name',
            bomName: 'BOM-CAKE-A',
            stockUom: 'Nos',
            bomQtyYield: 10,
            batches: 5,
          ),
        ],
      ),
      rollup: const BasketRollup(
        ok: false,
        lineCount: 1,
        components: [
          RollupComponent(
            itemCode: 'RM-FLOUR',
            itemName: 'Flour',
            uom: 'Kg',
            requiredQty: 10,
            availableQty: 4,
            missingQty: 6,
            reason: 'insufficient_stock',
            contributingLines: [
              ContributingLine(
                lineIndex: 0,
                itemCode: 'CAKE-A',
                requiredQty: 10,
              ),
            ],
          ),
        ],
        shortages: [
          RollupComponent(
            itemCode: 'RM-FLOUR',
            itemName: 'Flour',
            uom: 'Kg',
            requiredQty: 10,
            availableQty: 4,
            missingQty: 6,
            reason: 'insufficient_stock',
            contributingLines: [
              ContributingLine(
                lineIndex: 0,
                itemCode: 'CAKE-A',
                requiredQty: 10,
              ),
            ],
          ),
        ],
      ),
    );

    expect(_button(tester, 'Start batches').onPressed, isNull);
    // Quick produce posts the same stock, so it is gated with it — it was the
    // one path with no gate at all. It lives in the overflow now; the gate
    // moved with it.
    await _openActions(tester);
    expect(
      tester
          .widget<PopupMenuItem<int>>(
            find.widgetWithText(PopupMenuItem<int>, 'Quick produce'),
          )
          .enabled,
      isFalse,
    );
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    // Saving the target is still allowed: a plan is a statement of intent, not
    // a stock movement.
    expect(find.text('Consolidated pick list'), findsNothing);
    expect(find.textContaining('Short by 6 Kg'), findsOneWidget);
  });

  testWidgets('the posting date defaults to the server day, not the device', (
    tester,
  ) async {
    // It used to come from `DateTime.now()` while every verdict about it — the
    // caption, `isBackDated`, the refusal that gates Start and Quick produce —
    // came from the SERVER's day. Two clocks, one date, and the disagreement
    // only appears on a tablet whose clock is off: exactly the device nobody
    // is looking at.
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [_item(itemCode: 'CAKE-A')],
        summary: const ProductionSummary(critical: 1),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
    );

    expect(find.text('Production date'), findsOneWidget);
    expect(find.text('2026-08-02'), findsOneWidget);
    final now = DateTime.now();
    final deviceDay =
        '${now.year}-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';
    if (deviceDay != '2026-08-02') {
      expect(find.text(deviceDay), findsNothing);
    }
  });

  testWidgets('a queue restored from Hive comes back in the fields', (
    tester,
  ) async {
    // The basket survives the app being killed. If the numbers did not come
    // back onto the rows with it, the operator would be looking at empty
    // fields over a queue that Start batches would still post.
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [_item(itemCode: 'CAKE-A', suggestedBatches: 5)],
        summary: const ProductionSummary(critical: 1),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
      restored: const ProductionBasket(
        lines: [
          BatchLine(
            itemCode: 'CAKE-A',
            itemName: 'CAKE-A name',
            bomName: 'BOM-CAKE-A',
            stockUom: 'Nos',
            bomQtyYield: 10,
            batches: 3,
          ),
        ],
      ),
    );

    // The host restores the queue; this stands in for that call.
    final container = _container(tester);
    await container.read(productionBasketProvider.notifier).restore();
    await tester.pumpAndSettle();

    expect(container.read(dailyPlanDraftProvider).quantities['CAKE-A'], 30);
    expect(_shown(tester, 'CAKE-A'), '30');
  });

  testWidgets(
    'jars typed on Today and a restored queue both land in fields AND queue',
    (tester) async {
      // The draft is shared with the Today screen. Opening the full board with
      // jars already typed there used to skip filling the fields from the
      // restored queue: yesterday's CAKE-B was posted by Start batches with no
      // field showing it, and Today's CAKE-A showed in its field with nothing
      // queued behind it.
      final cakeB = _item(itemCode: 'CAKE-B', suggestedBatches: 5);
      await _pump(
        tester,
        page: ProductionSuggestionsPage(
          items: [
            _item(itemCode: 'CAKE-A'),
            cakeB,
          ],
          summary: const ProductionSummary(critical: 2),
          velocityUpdatedOn: '2026-08-01 00:00:00',
        ),
        draft: const {'CAKE-A': 10},
        restored: const ProductionBasket(
          lines: [
            BatchLine(
              itemCode: 'CAKE-B',
              itemName: 'CAKE-B name',
              bomName: 'BOM-CAKE-B',
              stockUom: 'Nos',
              bomQtyYield: 10,
              batches: 0.5,
            ),
          ],
        ),
      );

      // The host's restore lands after the tab has already queued Today's
      // jar: coming from Today the jar list is cached, so the tab reconciles on
      // its first frame while Hive is still opening.
      final container = _container(tester);
      expect(
        container.read(productionBasketProvider).lines.map((l) => l.itemCode),
        ['CAKE-A'],
      );
      await container.read(productionBasketProvider.notifier).restore();
      await tester.pumpAndSettle();

      expect(_shown(tester, 'CAKE-A'), '10');
      expect(_shown(tester, 'CAKE-B'), '5');
      final queued = {
        for (final l in container.read(productionBasketProvider).positiveLines)
          l.itemCode: l.units,
      };
      expect(queued, {'CAKE-A': 10.0, 'CAKE-B': 5.0});
      expect(container.read(dailyPlanDraftProvider).quantities, {
        'CAKE-A': 10,
        'CAKE-B': 5,
      });
    },
  );

  testWidgets('a jar Today has already made leaves the queue with its field', (
    tester,
  ) async {
    // Today's Make empties the draft and nothing else. A queue line left
    // behind would come back into the field on the next open and be started a
    // second time.
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [_item(itemCode: 'CAKE-A')],
        summary: const ProductionSummary(critical: 1),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
    );

    await tester.enterText(_quantityField('CAKE-A'), '12');
    await tester.pumpAndSettle();
    final container = _container(tester);
    expect(
      container.read(productionBasketProvider).positiveLines,
      hasLength(1),
    );

    // What `ProductionTodayNotifier._clearSucceeded` does after a Make.
    container.read(dailyPlanDraftProvider.notifier).setQuantity('CAKE-A', 0);
    await tester.pumpAndSettle();

    expect(_shown(tester, 'CAKE-A'), '');
    expect(container.read(productionBasketProvider).positiveLines, isEmpty);
    expect(container.read(dailyPlanDraftProvider).quantities, isEmpty);
    expect(_button(tester, 'Start batches').onPressed, isNull);
  });

  testWidgets('an empty jar list keeps the queue but starts none of it', (
    tester,
  ) async {
    // Restored X=60 over a template that answered with no items: nothing is
    // pruned, so no field shows X — and Start batches posted it anyway.
    await _pump(
      tester,
      page: const ProductionSuggestionsPage(
        items: [],
        summary: ProductionSummary(),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
      template: const DailyPlanTemplate(
        planDate: '2026-08-02',
        mix: DailyPlanMix(itemCode: 'BASE-MIX', batchQty: 12, uom: 'Kg'),
        items: [],
      ),
      restored: const ProductionBasket(
        lines: [
          BatchLine(
            itemCode: 'CAKE-X',
            itemName: 'CAKE-X name',
            bomName: 'BOM-CAKE-X',
            stockUom: 'Nos',
            bomQtyYield: 10,
            batches: 6,
          ),
        ],
      ),
    );

    final container = _container(tester);
    await container.read(productionBasketProvider.notifier).restore();
    await tester.pumpAndSettle();

    expect(
      container.read(productionBasketProvider).positiveLines,
      hasLength(1),
    );
    expect(_button(tester, 'Start batches').onPressed, isNull);
    expect(_button(tester, 'Save plan').onPressed, isNull);
    // The roll-up settles the queue on a timer that no frame advances.
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('an unqueueable row still takes a plan quantity', (tester) async {
    // A flavour with no BOM is still part of the day's target. It just has
    // nothing for Start batches to submit.
    await _pump(
      tester,
      page: const ProductionSuggestionsPage(
        items: [],
        summary: ProductionSummary(),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
      template: const DailyPlanTemplate(
        planDate: '2026-08-02',
        mix: DailyPlanMix(itemCode: 'BASE-MIX', batchQty: 12, uom: 'Kg'),
        items: [
          DailyPlanItem(
            itemCode: 'CAKE-NOBOM',
            itemName: 'CAKE-NOBOM name',
            itemGroup: 'Jars',
            usesMix: false,
          ),
        ],
      ),
    );

    expect(find.text('CAKE-NOBOM name'), findsOneWidget);
    await _expandRow(tester);
    expect(find.text('No cheesecake mix'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '12');
    await tester.pumpAndSettle();

    final container = _container(tester);
    expect(container.read(dailyPlanDraftProvider).quantities['CAKE-NOBOM'], 12);
    expect(container.read(productionBasketProvider).lines, isEmpty);
    expect(_button(tester, 'Save plan').onPressed, isNotNull);
    expect(_button(tester, 'Start batches').onPressed, isNull);
  });

  testWidgets('a saved plan is a target on the row, never a number in the '
      'field', (tester) async {
    // The rule the Today screen already keeps. Poured into the field the plan
    // would also be queued, so re-opening the tab after this morning's run and
    // tapping Start would make the same jars twice.
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [_item(itemCode: 'CAKE-A', suggestedBatches: 5)],
        summary: const ProductionSummary(critical: 1),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
      template: _template(['CAKE-A'], existingPlan: 'DPP-0001'),
      savedPlan: const {
        'name': 'DPP-0001',
        'plan_date': '2026-08-02',
        'lines': [
          {'item_code': 'CAKE-A', 'planned_qty': 60},
        ],
      },
    );

    final container = _container(tester);
    expect(container.read(dailyPlanDraftProvider).savedPlanName, 'DPP-0001');
    expect(find.text('Planned 60'), findsOneWidget);
    expect(_shown(tester, 'CAKE-A'), isEmpty);
    expect(container.read(productionBasketProvider).lines, isEmpty);
    // …but attached, so Save updates that document rather than filing a second
    // plan for the same day.
    expect(container.read(dailyPlanDraftProvider).savedPlanName, 'DPP-0001');

    // One tap adopts it — the point at which a target becomes an instruction.
    await tester.tap(find.text('Planned 60'));
    await tester.pumpAndSettle();

    expect(_shown(tester, 'CAKE-A'), '60');
    expect(container.read(productionBasketProvider).lines.single.units, 60);
    expect(find.text('Planned 60'), findsNothing);
  });

  testWidgets('the busiest row lays out on an Arabic 360 dp phone', (
    tester,
  ) async {
    // The narrowest screen the floor actually holds, in the longer of the two
    // languages, with everything a row can carry showing at once: the chip,
    // the field, four figures, the negative-stock warning, a capped headline
    // and the note about where the missing material is.
    await _pump(
      tester,
      size: const Size(360, 740),
      locale: const Locale('ar'),
      page: ProductionSuggestionsPage(
        items: [
          _item(
            itemCode: 'CAKE-BUSY',
            onHand: -36,
            stockIsNegative: true,
            suggestedBatches: 12,
            canMakeNowBatches: 3,
            limiting: const LimitingComponent(
              itemCode: 'RM-LABEL',
              itemName: 'Molten Jar Label',
              uom: 'Nos',
              sourceWarehouse: 'Raw Material - J',
              requiredQty: 8,
              reason: 'insufficient_stock',
              availableElsewhere: 40.5,
              alternatives: [
                StockAlternative(warehouse: 'Stores - J', availableQty: 40.5),
              ],
            ),
          ),
        ],
        summary: const ProductionSummary(critical: 1),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
    );

    expect(tester.takeException(), isNull);
    // Both actions still reachable rather than pushed off the bottom.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is ButtonStyleButton), findsWidgets);
  });

  testWidgets('the status filter hides rows without hiding their quantity', (
    tester,
  ) async {
    await _pump(
      tester,
      page: ProductionSuggestionsPage(
        items: [
          _item(itemCode: 'CAKE-A', suggestedBatches: 4),
          _item(
            itemCode: 'CAKE-OK',
            status: ProductionStatus.ok,
            suggestedBatches: 0,
          ),
        ],
        summary: const ProductionSummary(critical: 1, ok: 1),
        velocityUpdatedOn: '2026-08-01 00:00:00',
      ),
    );

    await tester.enterText(_quantityField('CAKE-OK'), '15');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Critical 1'));
    await tester.pumpAndSettle();

    expect(find.text('CAKE-OK name'), findsNothing);
    expect(find.text('CAKE-A name'), findsOneWidget);
    // Filtered off the screen, still in the day.
    final container = _container(tester);
    expect(container.read(dailyPlanDraftProvider).quantities['CAKE-OK'], 15);
    expect(container.read(productionBasketProvider).lines, hasLength(1));
  });

  group('groups', () {
    DailyPlanItem planItem(String code, String group) => DailyPlanItem(
      itemCode: code,
      itemName: '$code name',
      itemGroup: group,
      defaultBom: 'BOM-$code',
      mixQtyPerUnit: 0.1,
      jarsPerBatch: 120,
      usesMix: true,
    );

    const emptyPage = ProductionSuggestionsPage(
      items: [],
      summary: ProductionSummary(),
      velocityUpdatedOn: '2026-08-01 00:00:00',
    );

    DailyPlanTemplate template(List<DailyPlanItem> items) => DailyPlanTemplate(
      planDate: '2026-08-02',
      mix: const DailyPlanMix(itemCode: 'BASE-MIX', batchQty: 12, uom: 'Kg'),
      items: items,
    );

    testWidgets('Small starts closed; a typed Small row stays in sight', (
      tester,
    ) async {
      await _pump(
        tester,
        page: emptyPage,
        template: template([
          planItem('MANGO-M', 'Medium'),
          planItem('MANGO-S', 'Small'),
          planItem('TIRA-S', 'Small'),
        ]),
        draft: const {'TIRA-S': 6},
      );

      expect(find.text('MANGO-M name'), findsOneWidget);
      // Closed: the untyped Small row is hidden, the typed one is not.
      expect(find.text('MANGO-S name'), findsNothing);
      expect(find.text('TIRA-S name'), findsOneWidget);

      await tester.tap(find.textContaining('Small'));
      await tester.pumpAndSettle();
      expect(find.text('MANGO-S name'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a typed row moves to the top of its group, keyboard kept', (
      tester,
    ) async {
      await _pump(
        tester,
        page: emptyPage,
        template: template([
          planItem('A-JAR', 'Medium'),
          planItem('B-JAR', 'Medium'),
          planItem('C-JAR', 'Medium'),
        ]),
      );

      double top(String code) => tester.getTopLeft(find.text('$code name')).dy;
      expect(top('A-JAR'), lessThan(top('C-JAR')));

      final cField = find.descendant(
        of: find.ancestor(
          of: find.text('C-JAR name'),
          matching: find.byType(PlanJarRow),
        ),
        matching: find.byType(TextField),
      );
      await tester.enterText(cField, '4');
      await tester.pumpAndSettle();

      expect(top('C-JAR'), lessThan(top('A-JAR')));
      // Same field, still focused: the row moved, not rebuilt.
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.ancestor(
            of: find.text('C-JAR name'),
            matching: find.byType(PlanJarRow),
          ),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller!.text, '4');
      expect(tester.testTextInput.isVisible, isTrue);
    });
  });
}

/// Opens a row's detail panel.
///
/// The figures, the item code and the full offer moved behind a caret so a
/// phone shows five products instead of two. Everything they assert is still
/// there; it is one tap away.
Future<void> _expandRow(WidgetTester tester, {int index = 0}) async {
  await tester.tap(find.byIcon(Icons.expand_more).at(index));
  await tester.pumpAndSettle();
}

/// Opens the action bar's overflow, where everything that is neither the
/// target nor the run now lives.
Future<void> _openActions(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
}

/// A button by its label, whatever flavour of button it is.
///
/// `find.byType` matches the exact runtime type, so it cannot ask for
/// "any ButtonStyleButton" — and these two deliberately differ in weight.
ButtonStyleButton _button(WidgetTester tester, String label) {
  return tester.widget<ButtonStyleButton>(
    find
        .ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        )
        .first,
  );
}
