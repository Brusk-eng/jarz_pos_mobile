import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/replenishment/data/models/branch_replenishment.dart';
import 'package:jarz_pos/src/features/replenishment/presentation/widgets/packing_guide_sheet.dart';

/// 24 medium Lotus = two full B2B cartons.
ReplenishmentBranch _branch() => ReplenishmentBranch.fromJson({
  'warehouse': 'Dokki - J',
  'branch': 'Dokki',
  'items': [
    {
      'item_code': 'LOTUS-M',
      'item_name': 'Lotus Medium',
      'stock_uom': 'Nos',
      'on_hand': 2,
      'reserved_qty': 3,
      'sells_per_day': 2.0,
      'target_days': 21,
      'suggested_qty': 24,
      'available_at_source': 100,
      'send_now': 24,
      'short_by': 0,
      'item_group': 'Medium',
      'jar_size': 'medium',
    },
  ],
});

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PackingGuideSheet(branch: _branch())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ticking cartons counts them off until all are packed', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('0 of 2 cartons packed'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(2));
    expect(find.text('Clear ticks'), findsNothing);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('1 of 2 cartons packed'), findsOneWidget);
    expect(find.text('Clear ticks'), findsOneWidget);

    // Tapping the carton body ticks it too.
    await tester.tap(find.textContaining('Carton 2'));
    await tester.pumpAndSettle();
    expect(find.text('All cartons packed'), findsOneWidget);

    await tester.tap(find.text('Clear ticks'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 2 cartons packed'), findsOneWidget);
  });
}
