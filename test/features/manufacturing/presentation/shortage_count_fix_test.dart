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
      ShortageCountChoice? result;
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
      expect(result, isNotNull);
      // Untouched date: the server keeps its default moment.
      expect(result!.countAt, isNull);
      // No recount handler: no date control.
      expect(find.text('Change date'), findsNothing);
    });

    testWidgets('a later stock count blocks confirming and is named', (
      tester,
    ) async {
      final blocked = ShortageCountPlan.fromJson({
        'production_at': '2026-11-20 18:00:00',
        'count_at': '2026-11-18 09:30:00',
        'latest_count_at': '2026-11-20 17:55:00',
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
        'later_counts': [
          {
            'item_code': 'RM-LABEL',
            'warehouse': 'Raw Material - J',
            'stock_reconciliation': 'MAT-RECO-9',
            'posted_at': '2026-11-19 10:00:00',
          },
        ],
      });
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => confirmShortageCountFix(
                context,
                blocked,
                recount: (_) async => blocked,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Change date'), findsOneWidget);
      expect(find.textContaining('MAT-RECO-9'), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      final submit = find.widgetWithText(FilledButton, 'Add to stock');
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    });

    test('moment helpers round-trip the server format', () {
      final d = parseShortageMoment('2026-11-18 09:30:00');
      expect(d, DateTime(2026, 11, 18, 9, 30));
      expect(formatShortageMoment(d!), '2026-11-18 09:30:00');
    });
  });
}
