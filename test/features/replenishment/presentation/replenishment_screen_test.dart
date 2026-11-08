import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/core/constants/api_endpoints.dart';
import 'package:jarz_pos/src/core/constants/business_constants.dart';
import 'package:jarz_pos/src/core/network/dio_provider.dart';
import 'package:jarz_pos/src/core/network/user_service.dart';
import 'package:jarz_pos/src/features/replenishment/presentation/replenishment_screen.dart';

import '../../../helpers/mock_services.dart';

/// The factory holds 30 Lotus jars and the two branches want 105 between them,
/// so the server split what exists 18/12 and reported the rest as `short_by`.
/// Every assertion about the shortfall below leans on those exact figures.
Map<String, dynamic> _plan() => {
  'generated_on': '2026-09-11 08:00:00',
  'company': 'Jarz',
  'cover_days': 14,
  'sales_days': 30,
  'notice': null,
  'source': {
    'warehouse': 'Finished Goods - J',
    'available': {'JAR-LOTUS': 30},
  },
  'branches': [
    {
      'warehouse': 'Dokki - J',
      'branch': 'Dokki',
      'items': [
        {
          'item_code': 'JAR-LOTUS',
          'item_name': 'Lotus Jar',
          'stock_uom': 'Nos',
          'on_hand': 5,
          'stock_is_negative': false,
          'sells_per_day': 3.0,
          'days_of_cover': 1.7,
          'target_days': 14,
          'suggested_qty': 42,
          'available_at_source': 30,
          'send_now': 12,
          'short_by': 30,
        },
      ],
      'summary': {
        'items_below_cover': 1,
        'total_suggested': 42,
        'total_send_now': 12,
        'negative_bins': 0,
      },
    },
    {
      'warehouse': 'Nasr - J',
      'branch': 'Nasr City',
      'items': [
        {
          'item_code': 'JAR-LOTUS',
          'item_name': 'Lotus Jar',
          'stock_uom': 'Nos',
          'on_hand': -3,
          'stock_is_negative': true,
          'sells_per_day': 4.5,
          'days_of_cover': null,
          'target_days': 14,
          'suggested_qty': 63,
          'available_at_source': 30,
          'send_now': 18,
          'short_by': 45,
        },
        {
          'item_code': 'JAR-MANGO',
          'item_name': 'Mango Jar',
          'stock_uom': 'Nos',
          'on_hand': 6,
          'stock_is_negative': false,
          'sells_per_day': 3.0,
          'days_of_cover': 2.0,
          'target_days': 14,
          'suggested_qty': 36,
          'available_at_source': 12,
          'send_now': 12,
          'short_by': 24,
        },
        {
          'item_code': 'JAR-DATE',
          'item_name': 'Date Jar',
          'stock_uom': 'Nos',
          'on_hand': 40,
          'stock_is_negative': false,
          'sells_per_day': 1.0,
          'days_of_cover': 40.0,
          'target_days': 14,
          'suggested_qty': 0,
          'available_at_source': 50,
          'send_now': 0,
          'short_by': 0,
        },
      ],
      'summary': {
        'items_below_cover': 2,
        'total_suggested': 99,
        'total_send_now': 30,
        'negative_bins': 1,
      },
    },
  ],
  'summary': {
    'items_below_cover': 3,
    'total_suggested': 141,
    'total_send_now': 42,
    'negative_bins': 1,
    'branches': 2,
    'total_short_by': 99,
  },
};

const _roles = UserRoles(user: 'manager@jarz', roles: [RoleNames.jarzManager]);

Future<void> _pump(
  WidgetTester tester,
  MockDio dio, {
  Locale locale = const Locale('en'),
  // A 360 dp phone by default: the narrowest device in the field, and the one
  // the rows have to survive without an overflow.
  Size size = const Size(360, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dioProvider.overrideWithValue(dio),
        userRolesFutureProvider.overrideWith((ref) async => _roles),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ReplenishmentScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Finds the quantity box that belongs to a named row.
///
/// By row identity rather than by index: the list is lazy, so a result banner
/// or a taller warning above can change how many rows exist without changing
/// which row the assertion is about.
Finder get _sendBarButton =>
    find.byWidgetPredicate((w) => w is FilledButton).last;

Finder _qtyFieldFor(String itemName) {
  return find.descendant(
    of: find
        .ancestor(of: find.text(itemName), matching: find.byType(Card))
        .first,
    matching: find.byType(TextField),
  );
}

String _qtyTextFor(WidgetTester tester, String itemName) =>
    tester.widget<TextField>(_qtyFieldFor(itemName)).controller?.text ?? '';

void main() {
  late MockDio dio;

  setUp(() {
    dio = MockDio();
    dio.setResponse(
      ApiEndpoints.getBranchReplenishment,
      createSuccessResponse(data: _plan()),
    );
    dio.setResponse(
      ApiEndpoints.submitTransfer,
      createSuccessResponse(data: {'stock_entry': 'MAT-STE-0007'}),
    );
  });

  testWidgets('opens on the branch with the most items below cover', (
    tester,
  ) async {
    await _pump(tester, dio);

    // Dokki is first in the payload; Nasr City is the one somebody opened this
    // screen for, so it is the one that must be showing.
    expect(find.textContaining('Nasr City'), findsWidgets);
    expect(find.text('Mango Jar'), findsOneWidget);
  });

  testWidgets('surfaces the proportional shortfall instead of hiding it', (
    tester,
  ) async {
    await _pump(tester, dio);

    // The row pre-fills with the 18 the factory can actually spare, not the 63
    // the branch wants.
    expect(_qtyTextFor(tester, 'Lotus Jar'), '18');

    // The per-row reason is one tap away, with the number that means
    // "produce more".
    await tester.tap(find.text('Lotus Jar'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining("Factory can't cover this — short by 45 Nos"),
      findsOneWidget,
    );
    expect(
      find.textContaining('The factory is short 99 across all branches'),
      findsOneWidget,
    );
  });

  testWidgets('a negative bin asks for a count instead of a bigger load', (
    tester,
  ) async {
    await _pump(tester, dio);

    await tester.tap(find.text('Lotus Jar'));
    await tester.pumpAndSettle();
    expect(find.text('Stock is negative, count this item'), findsOneWidget);
    expect(find.text('1 item has negative stock'), findsOneWidget);
    // The minus is wrapped in a bidi isolate, so match on the digits.
    expect(find.textContaining('-3'), findsOneWidget);
  });

  testWidgets('an item with no sales history never reads as zero days', (
    tester,
  ) async {
    await _pump(tester, dio);

    expect(find.textContaining('No sales yet'), findsOneWidget);
    expect(find.textContaining('· 0 days cover'), findsNothing);
    // The item that DOES sell still reports its own cover.
    expect(find.textContaining('2 days cover'), findsOneWidget);
  });

  testWidgets('sends exactly the typed quantities to the chosen branch', (
    tester,
  ) async {
    await _pump(tester, dio, size: const Size(420, 1600));

    // The van is smaller than the plan: 5 Lotus, the suggested 12 Mango, and
    // 3 Date off a row the server suggested nothing for.
    await tester.enterText(_qtyFieldFor('Lotus Jar'), '5');
    // Date Jar sits below the fold on an 800x600 test window, and a
    // ListView.builder does not build what it has not scrolled to, so the
    // finder has nothing to find until we go there.

    await tester.enterText(_qtyFieldFor('Date Jar'), '3');
    await tester.pumpAndSettle();

    expect(find.text('3 lines · 20 units'), findsOneWidget);

    await tester.tap(_sendBarButton);
    await tester.pumpAndSettle();
    expect(find.textContaining('3 lines · 20 units, out of'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Send'),
      ),
    );
    await tester.pumpAndSettle();

    final submit = dio.requestLog
        .where((call) => call['path'] == ApiEndpoints.submitTransfer)
        .single;
    final body = submit['data'] as Map<String, dynamic>;
    expect(body['source_warehouse'], 'Finished Goods - J');
    expect(body['target_warehouse'], 'Nasr - J');
    expect(body['lines'], [
      {'item_code': 'JAR-LOTUS', 'qty': 5.0},
      {'item_code': 'JAR-MANGO', 'qty': 12.0},
      {'item_code': 'JAR-DATE', 'qty': 3.0},
    ]);

    expect(find.text('Sent to Nasr City'), findsWidgets);
    expect(find.textContaining('3 lines · 20 units · entry'), findsOneWidget);
  });

  testWidgets('a failed send keeps the numbers and names the line', (
    tester,
  ) async {
    dio.setError(
      ApiEndpoints.submitTransfer,
      createMockDioException(
        statusCode: 417,
        data: {
          'exception':
              'ValidationError: Negative stock for item JAR-MANGO in Finished Goods - J',
        },
        type: DioExceptionType.badResponse,
      ),
    );
    await _pump(tester, dio);

    await tester.enterText(_qtyFieldFor('Lotus Jar'), '5');
    await tester.pumpAndSettle();

    await tester.tap(_sendBarButton);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Send'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't send to Nasr City"), findsOneWidget);
    expect(find.text('The line the server refused: Mango Jar'), findsOneWidget);
    expect(
      find.text('Your quantities are still on screen — fix it and send again.'),
      findsOneWidget,
    );

    // Nothing has to be retyped: the edited row and the untouched rows are
    // both still carrying what they were going to send.
    expect(_qtyTextFor(tester, 'Lotus Jar'), '5');
    expect(find.text('2 lines · 17 units'), findsOneWidget);

    // The row the banner pushed down kept its number too.
    expect(_qtyTextFor(tester, 'Mango Jar'), '12');
  });

  testWidgets('an empty run says why rather than showing a blank list', (
    tester,
  ) async {
    dio.setResponse(
      ApiEndpoints.getBranchReplenishment,
      createSuccessResponse(
        data: {
          'notice': 'No POS profile has a branch warehouse set.',
          'branches': <dynamic>[],
        },
      ),
    );
    await _pump(tester, dio);

    expect(find.text('Nothing to send'), findsOneWidget);
    expect(
      find.text('No POS profile has a branch warehouse set.'),
      findsOneWidget,
    );
  });

  testWidgets('a load failure says why and offers a retry', (tester) async {
    dio.setError(
      ApiEndpoints.getBranchReplenishment,
      createMockDioException(
        statusCode: 403,
        data: {'exception': 'PermissionError: Not permitted'},
        type: DioExceptionType.badResponse,
      ),
    );
    await _pump(tester, dio);

    expect(find.text("Couldn't load what to send"), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
  });

  testWidgets('fits a short tablet landscape window too', (tester) async {
    await _pump(tester, dio, size: const Size(1024, 600));

    expect(find.text('Mango Jar'), findsOneWidget);
    expect(_sendBarButton, findsOneWidget);
  });

  testWidgets('branches are tabs and swiping the body changes the branch', (
    tester,
  ) async {
    await _pump(tester, dio);

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Nasr City · 2'), findsOneWidget);
    expect(find.text('Dokki · 1'), findsOneWidget);
    expect(find.text('Mango Jar'), findsOneWidget);

    // Nasr City is the 2nd tab, so the next page to the left is nothing; swipe
    // right (toward the start) to reach Dokki.
    await tester.drag(find.byType(TabBarView), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Mango Jar'), findsNothing);
    expect(find.text('Lotus Jar'), findsOneWidget);
    expect(_qtyTextFor(tester, 'Lotus Jar'), '12');

    // Tapping the tab goes back, and the typed draft per branch survives.
    await tester.tap(find.text('Nasr City · 2'));
    await tester.pumpAndSettle();
    expect(find.text('Mango Jar'), findsOneWidget);
  });

  testWidgets('shows at least five item rows on a 390x844 phone', (
    tester,
  ) async {
    final plan = _plan();
    final nasr = (plan['branches'] as List)[1] as Map<String, dynamic>;
    nasr['items'] = [
      for (var i = 0; i < 12; i++)
        {
          'item_code': 'JAR-$i',
          'item_name': 'Jar number $i',
          'stock_uom': 'Nos',
          'on_hand': 8,
          'stock_is_negative': false,
          'sells_per_day': 5.1,
          'days_of_cover': 1.6,
          'target_days': 14,
          'suggested_qty': 20,
          'available_at_source': 100,
          'send_now': 20,
          'short_by': 0,
        },
    ];
    dio.setResponse(
      ApiEndpoints.getBranchReplenishment,
      createSuccessResponse(data: plan),
    );
    await _pump(tester, dio, size: const Size(390, 844));

    var visible = 0;
    for (var i = 0; i < 12; i++) {
      final finder = find.text('Jar number $i');
      if (finder.evaluate().isEmpty) continue;
      final rect = tester.getRect(finder);
      if (rect.top >= 0 && rect.bottom <= 844) visible++;
    }
    expect(visible, greaterThanOrEqualTo(5));
  });

  testWidgets('renders right-to-left on a 360 dp phone', (tester) async {
    await _pump(tester, dio, locale: const Locale('ar'));

    expect(find.byType(Directionality), findsWidgets);
    await tester.tap(find.text('Lotus Jar'));
    await tester.pumpAndSettle();
    expect(find.text('الرصيد بالسالب، اعمل جرد للصنف ده'), findsOneWidget);
    expect(find.textContaining('لسه مفيش مبيعات'), findsOneWidget);
  });
}
