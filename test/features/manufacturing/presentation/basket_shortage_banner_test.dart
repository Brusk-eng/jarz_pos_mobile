import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/basket_rollup.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/stock_alternative.dart';
import 'package:jarz_pos/src/features/manufacturing/presentation/widgets/basket_shortage_banner.dart';
import 'package:jarz_pos/src/features/manufacturing/presentation/widgets/stock_elsewhere_note.dart';

/// The consolidated pick list on the Batch tab.
///
/// Nothing here changes what the list blocks — the Start button reads
/// `rollup.hasShortages`, which these rows do not touch. The only question is
/// whether the operator is told that the fix is a transfer rather than a
/// purchase.
Future<void> _pump(
  WidgetTester tester,
  BasketRollup rollup, {
  Locale? locale,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: SingleChildScrollView(child: BasketPickList(rollup: rollup)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

RollupComponent _short({
  double? availableElsewhere,
  List<StockAlternative>? alternatives,
}) {
  return RollupComponent(
    itemCode: 'RM-LABEL',
    itemName: 'Jar label',
    uom: 'Nos',
    sourceWarehouse: 'Raw Material - J',
    requiredQty: 8,
    availableQty: 0,
    missingQty: 8,
    reason: 'insufficient_stock',
    availableElsewhere: availableElsewhere,
    alternatives: alternatives,
  );
}

void main() {
  testWidgets('a shortage sitting in other stores names the fullest one', (
    tester,
  ) async {
    await _pump(
      tester,
      BasketRollup(
        ok: false,
        components: [
          _short(
            availableElsewhere: 48.5,
            alternatives: const [
              StockAlternative(warehouse: 'Stores - J', availableQty: 40.5),
              StockAlternative(warehouse: 'Nasr City - J', availableQty: 8),
            ],
          ),
        ],
        shortages: [_short()],
      ),
    );

    expect(find.text('Short by 8 Nos'), findsOneWidget);
    expect(
      find.text(
        '40.5 Nos is in Stores - J and 1 more '
        '\u2014 needs a stock transfer, not a purchase',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a lookup that found none anywhere says so', (tester) async {
    await _pump(
      tester,
      BasketRollup(
        ok: false,
        components: [
          _short(
            availableElsewhere: 0,
            alternatives: const <StockAlternative>[],
          ),
        ],
        shortages: [_short()],
      ),
    );

    expect(
      find.text(
        'None of it in any other store \u2014 this one has to be bought',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a server that never looked adds no row at all', (tester) async {
    await _pump(
      tester,
      BasketRollup(ok: false, components: [_short()], shortages: [_short()]),
    );

    expect(find.text('Short by 8 Nos'), findsOneWidget);
    expect(tester.getSize(find.byType(StockElsewhereNote)), Size.zero);
    expect(find.textContaining('stock transfer'), findsNothing);
    expect(find.textContaining('any other store'), findsNothing);
  });

  testWidgets('a covered component is never asked where else it is', (
    tester,
  ) async {
    await _pump(
      tester,
      const BasketRollup(
        components: [
          RollupComponent(
            itemCode: 'RM-FLOUR',
            itemName: 'Flour',
            uom: 'Kg',
            requiredQty: 4,
            availableQty: 100,
          ),
        ],
      ),
    );

    expect(find.text('All materials available'), findsOneWidget);
    expect(find.byType(StockElsewhereNote), findsNothing);
  });

  testWidgets('the Arabic hint lays out at 360 dp without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      BasketRollup(
        ok: false,
        components: [
          _short(
            availableElsewhere: 48.5,
            alternatives: const [
              StockAlternative(warehouse: 'Stores - J', availableQty: 40.5),
              StockAlternative(warehouse: 'Nasr City - J', availableQty: 8),
            ],
          ),
        ],
        shortages: [_short()],
      ),
      locale: const Locale('ar'),
    );

    expect(tester.takeException(), isNull);
  });

  group('folding and per flavour', () {
    RollupComponent covered(
      String code,
      String name,
      List<ContributingLine> lines,
    ) => RollupComponent(
      itemCode: code,
      itemName: name,
      uom: 'Kg',
      requiredQty: lines.fold(0.0, (sum, l) => sum + l.requiredQty),
      availableQty: 100,
      contributingLines: lines,
    );

    final rollup = BasketRollup(
      components: [
        covered('MIX', 'Cheesecake Mix', const [
          ContributingLine(itemCode: 'Tiramisu Large', requiredQty: 1),
          ContributingLine(
            lineIndex: 1,
            itemCode: 'Tiramisu Medium',
            requiredQty: 0.5,
          ),
          ContributingLine(
            lineIndex: 2,
            itemCode: 'Mango Medium',
            requiredQty: 0.25,
          ),
        ]),
        covered('MANGO', 'Mango mix', const [
          ContributingLine(
            lineIndex: 2,
            itemCode: 'Mango Medium',
            requiredQty: 0.75,
          ),
        ]),
      ],
    );

    test('each line lands under its flavour, sizes summed', () {
      final flavours = groupRollupByFlavour(rollup.components);
      expect(flavours.map((f) => f.name), ['Tiramisu', 'Mango']);
      expect(flavours[0].lines.single.qty, 1.5);
      expect(flavours[1].lines.map((l) => (l.component.itemCode, l.qty)), [
        ('MIX', 0.25),
        ('MANGO', 0.75),
      ]);
    });

    testWidgets('a covered basket starts folded, and both sections fold', (
      tester,
    ) async {
      await _pump(tester, rollup);

      expect(find.text('Ingredients'), findsOneWidget);
      expect(find.textContaining('Mango mix'), findsNothing);

      await tester.tap(find.text('Ingredients'));
      await tester.pumpAndSettle();
      expect(find.text('Consolidated pick list'), findsOneWidget);
      expect(find.text('Per flavour'), findsOneWidget);
      // The sections themselves are still closed.
      expect(find.textContaining('Mango mix'), findsNothing);

      await tester.tap(find.text('Per flavour'));
      await tester.pumpAndSettle();
      expect(find.text('Tiramisu'), findsOneWidget);
      expect(find.text('Mango'), findsOneWidget);

      await tester.tap(find.text('Mango'));
      await tester.pumpAndSettle();
      expect(find.text('Mango mix'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a shortage stays in sight while the card is folded', (
      tester,
    ) async {
      await _pump(
        tester,
        BasketRollup(ok: false, components: [_short()], shortages: [_short()]),
      );
      expect(find.text('Short by 8 Nos'), findsOneWidget);

      // Opening the card to look at the shortage must not hide it.
      await tester.tap(find.text('Insufficient inventory').first);
      await tester.pumpAndSettle();
      expect(find.text('Short by 8 Nos'), findsOneWidget);
    });
  });

  testWidgets('a fresh mix lists its own sugar apart from the jar sugar', (
    tester,
  ) async {
    await _pump(
      tester,
      const BasketRollup(
        components: [
          RollupComponent(
            itemCode: 'MIX',
            itemName: 'Cheesecake Mix',
            uom: 'Kg',
            requiredQty: 2,
            availableQty: 10,
            contributingLines: [
              ContributingLine(itemCode: 'Tiramisu Large', requiredQty: 2),
            ],
            madeFrom: [
              MadeFromLine(
                itemCode: 'SUGAR',
                itemName: 'Powder sugar',
                uom: 'Kg',
                requiredQty: 0.2,
              ),
            ],
          ),
          RollupComponent(
            itemCode: 'SUGAR',
            itemName: 'Powder sugar',
            uom: 'Kg',
            requiredQty: 0.3,
            availableQty: 10,
            contributingLines: [
              ContributingLine(itemCode: 'Tiramisu Large', requiredQty: 0.3),
            ],
          ),
        ],
      ),
    );

    await tester.tap(find.text('Ingredients'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Consolidated pick list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Made from'));
    await tester.pumpAndSettle();

    expect(find.textContaining('0.2 Kg'), findsOneWidget);
    expect(find.textContaining('0.3 Kg'), findsOneWidget);
    expect(find.textContaining('0.5 Kg'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
