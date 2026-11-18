import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/pos/data/models/draft_cart.dart';
import 'package:jarz_pos/src/features/pos/data/repositories/draft_cart_repository.dart';
import 'package:jarz_pos/src/features/pos/data/repositories/pos_repository.dart';
import 'package:jarz_pos/src/features/pos/presentation/widgets/item_grid_widget.dart';
import 'package:jarz_pos/src/features/pos/state/pos_notifier.dart';

/// A retail cart can be filled before the customer is chosen (the operator is
/// on a call and the caller has not given a name yet). The customer is
/// enforced at the cart's checkout button instead (see cart_widget_test). B2B orders stay gated: their catalogue and
/// prices belong to the customer's branch.

class _RecordingPosRepository extends PosRepository {
  _RecordingPosRepository() : super(Dio());

  @override
  Future<List<Map<String, dynamic>>> getPosProfiles() async => const [];

  @override
  Future<List<Map<String, dynamic>>> getItems(
    String posProfile, {
    String? priceList,
    String? customer,
    String? orderPurpose,
  }) async => const [];

  @override
  Future<List<Map<String, dynamic>>> getBundles(
    String posProfile, {
    String? priceList,
    String? customer,
    String? orderPurpose,
  }) async => const [];

  @override
  Future<List<Map<String, dynamic>>> getPosPriceLists(String posProfile) async =>
      const [];
}

class _DummyDraftCartRepository extends DraftCartRepository {
  @override
  Future<List<DraftCart>> loadAll() async => const [];

  @override
  Future<void> upsert(draft) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> clearAll() async {}
}

class _PosNotifierStub extends PosNotifier {
  _PosNotifierStub(PosState initialState)
    : super(_RecordingPosRepository(), _DummyDraftCartRepository()) {
    state = initialState;
  }
}

final _items = <Map<String, dynamic>>[
  {
    'name': 'ITEM-A',
    'item_name': 'Item A',
    'item_group': 'Drinks',
    'rate': 25.0,
    'actual_qty': 91,
  },
];

late _PosNotifierStub _notifier;

Future<void> _pumpGrid(WidgetTester tester, PosState state) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  _notifier = _PosNotifierStub(state);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [posNotifierProvider.overrideWith((ref) => _notifier)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ItemGridWidget()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Lets the cart's debounced auto-save and any snackbar run out so no timer is
/// left pending when the test ends.
Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('retail order: an item can be added before a customer is chosen', (
    tester,
  ) async {
    await _pumpGrid(tester, PosState(items: _items));

    // A reminder, not a blocking warning.
    expect(find.text('Please select a customer first'), findsOneWidget);
    expect(find.byIcon(Icons.person_search), findsOneWidget);
    expect(find.byIcon(Icons.warning), findsNothing);

    await tester.tap(find.text('Item A'));
    await tester.pump();

    expect(_notifier.state.cartItems, hasLength(1));
    expect(_notifier.state.cartItems.single['item_code'], 'ITEM-A');
    expect(find.text('Select customer first'), findsNothing);
    await _drain(tester);
  });

  testWidgets('retail order: choosing the customer afterwards keeps the cart', (
    tester,
  ) async {
    await _pumpGrid(tester, PosState(items: _items));
    await tester.tap(find.text('Item A'));
    await tester.pump();

    _notifier.selectCustomer(const {
      'name': 'CUST-0001',
      'customer_name': 'Caller',
    });
    await tester.pump();

    expect(_notifier.state.selectedCustomer?['name'], 'CUST-0001');
    expect(_notifier.state.cartItems, hasLength(1));
    expect(find.text('Please select a customer first'), findsNothing);
    await _drain(tester);
  });

  testWidgets('B2B order: still needs the customer before adding', (
    tester,
  ) async {
    await _pumpGrid(tester, PosState(items: _items, isB2bOrder: true));

    expect(find.byIcon(Icons.warning), findsOneWidget);

    await tester.tap(find.text('Item A'));
    await tester.pump();

    expect(_notifier.state.cartItems, isEmpty);
    expect(find.text('Select customer first'), findsOneWidget);
    await _drain(tester);
  });
}
