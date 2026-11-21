import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/stock_transfer/data/stock_handover_models.dart';
import 'package:jarz_pos/src/features/stock_transfer/presentation/widgets/stock_handover_card.dart';

const _plan = {
  'version': 1,
  'total_cartons': 3,
  'total_jars': 30,
  'large': 1,
  'b2b': 2,
  'cartons': [
    {
      'number': 1,
      'type': 'large',
      'jars': 20,
      'lines': [
        {'item_code': 'LM', 'item_name': 'Lotus Medium', 'qty': 20},
      ],
    },
    {
      'number': 2,
      'type': 'b2b',
      'jars': 6,
      'lines': [
        {'item_code': 'LM', 'item_name': 'Lotus Medium', 'qty': 6},
      ],
    },
    {
      'number': 3,
      'type': 'b2b',
      'jars': 4,
      'lines': [
        {'item_code': 'LM', 'item_name': 'Lotus Medium', 'qty': 4},
      ],
    },
  ],
  'unpacked': [
    {'item_code': 'X', 'item_name': 'Mystery', 'qty': 2},
  ],
};

Map<String, dynamic> _handover(Object? plan) => {
  'name': 'JSH-1',
  'status': 'Pending',
  'from_warehouse': 'F',
  'to_warehouse': 'B',
  'carton_plan': plan,
};

void main() {
  group('carton_plan parsing', () {
    test('present map', () {
      final h = StockHandover.fromJson(_handover(_plan));
      expect(h.cartonPlan, isNotNull);
      expect(h.cartonPlan!.cartons.length, 3);
      expect(h.cartonPlan!.large, 1);
      expect(h.cartonPlan!.b2b, 2);
      expect(h.cartonPlan!.totalJars, 30);
      expect(h.cartonPlan!.unpacked.single.itemName, 'Mystery');
    });

    test('present as JSON string', () {
      final h = StockHandover.fromJson(
        _handover(
          '{"cartons":[{"number":1,"type":"large","jars":5,"lines":[]}]}',
        ),
      );
      expect(h.cartonPlan!.cartons.single.isLarge, isTrue);
    });

    test('absent, malformed or empty gives null', () {
      expect(StockHandover.fromJson(_handover(null)).cartonPlan, isNull);
      expect(StockHandover.fromJson(_handover('{not json')).cartonPlan, isNull);
      expect(StockHandover.fromJson(_handover(42)).cartonPlan, isNull);
      expect(StockHandover.fromJson(_handover({'cartons': 'x'})).cartonPlan,
          isNull);
      expect(StockHandover.fromJson(_handover({'cartons': []})).cartonPlan,
          isNull);
    });
  });

  testWidgets('ticking cartons counts them received', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: StockHandoverCard(
                handover: StockHandover.fromJson(_handover(_plan)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Cartons to receive: 3 (1 large carton + 2 B2B cartons)'),
      findsOneWidget,
    );
    expect(find.text('Carton 1 · Large · 20 jars'), findsOneWidget);
    expect(find.text('Packed by hand'), findsOneWidget);
    expect(find.text('0 of 3 cartons received'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carton 2 · B2B · 6 jars'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 3 cartons received'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pumpAndSettle();
    expect(find.text('All cartons received'), findsOneWidget);

    await tester.tap(find.text('Clear ticks'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 3 cartons received'), findsOneWidget);
  });
}
