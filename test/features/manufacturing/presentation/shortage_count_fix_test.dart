import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/basket_rollup.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/shortage_count_plan.dart';
import 'package:jarz_pos/src/features/manufacturing/presentation/widgets/basket_shortage_banner.dart';
import 'package:jarz_pos/src/features/manufacturing/presentation/widgets/shortage_count_fix_dialog.dart';

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

const _short = RollupComponent(
  itemCode: 'RM-LABEL',
  itemName: 'Jar label',
  uom: 'Nos',
  sourceWarehouse: 'Raw Material - J',
  requiredQty: 34,
  availableQty: 11,
  missingQty: 23,
  reason: 'insufficient_stock',
);

void main() {
  group('Add missing stock button', () {
    testWidgets('shows on a shortage when a handler is given', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _app(
          BasketPickList(
            rollup: const BasketRollup(
              components: [_short],
              shortages: [_short],
            ),
            onAddMissingStock: () => tapped++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-missing-stock')));
      expect(tapped, 1);
    });

    testWidgets('is hidden without a handler', (tester) async {
      await tester.pumpWidget(
        _app(
          const BasketPickList(
            rollup: BasketRollup(components: [_short], shortages: [_short]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('add-missing-stock')), findsNothing);
    });
  });

  group('confirmShortageCountFix', () {
    final plan = ShortageCountPlan.fromJson({
      'production_at': '2026-11-20 18:00:00',
      'count_at': '2026-11-20 17:55:00',
      'items': [
        {
          'item_code': 'RM-LABEL',
          'item_name': 'Jar label',
          'uom': 'Nos',
          'warehouse': 'Raw Material - J',
          'missing_qty': 23,
          'current_qty': 11,
          'counted_qty': 34,
        },
      ],
      'skipped': [],
    });

    testWidgets('lists items and the count moment; confirm needs the tick', (
      tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await confirmShortageCountFix(context, plan),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Jar label'), findsOneWidget);
      expect(find.text('+23 Nos'), findsOneWidget);
      expect(find.textContaining('17:55 · 2026-11-20'), findsOneWidget);

      final submit = find.widgetWithText(FilledButton, 'Add to stock');
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });
  });
}
