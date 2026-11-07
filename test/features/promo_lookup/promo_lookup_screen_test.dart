import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/promo_lookup/data/models/promo_lookup_models.dart';
import 'package:jarz_pos/src/features/promo_lookup/data/promo_lookup_repository.dart';
import 'package:jarz_pos/src/features/promo_lookup/presentation/screens/promo_lookup_screen.dart';

class _FakeRepo implements PromoLookupRepository {
  _FakeRepo(this.answer);

  final Map<String, dynamic> Function(String code, String? order) answer;
  final List<Map<String, String?>> calls = [];

  @override
  Future<PromoLookupResult> lookup({
    required String code,
    String? order,
  }) async {
    calls.add({'code': code, 'order': order});
    return PromoLookupResult.fromJson(answer(code, order));
  }
}

Map<String, dynamic> _summer({Map<String, dynamic>? orderCheck}) => {
  'found': true,
  'code': 'SUMMER10',
  'title': 'Summer sale',
  'status': 'active',
  'discount_type': 'Percentage',
  'discount_value': 10,
  'max_discount_amount': 150,
  'min_order_amount': 300,
  'min_on_whole_order': true,
  'applies_to': 'Whole Order',
  'scope': [],
  'channels': [],
  'allow_pickup': true,
  'stackable': false,
  'usage_limit': 0,
  'times_used': 3,
  'remaining_uses': null,
  'per_customer_limit': 0,
  'active_from': null,
  'active_to': '2026-12-31',
  'woo_coupon_code': 'SUMMER10',
  'on_website': true,
  'recent_uses': [
    {
      'invoice': 'ACC-SINV-2026-00001',
      'woo_order_id': 21471,
      'customer_name': 'Mona',
      'date': '2026-11-05',
      'status': 'Active',
    },
  ],
  'order_check': orderCheck,
};

Future<void> _pump(
  WidgetTester tester,
  _FakeRepo repo, {
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [promoLookupRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PromoLookupScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _codeField() => find.byKey(const ValueKey('promoLookupCodeField'));
Finder _orderField() => find.byKey(const ValueKey('promoLookupOrderField'));

void main() {
  testWidgets('found code with an accepted order check', (tester) async {
    final repo = _FakeRepo(
      (code, order) => _summer(
        orderCheck: {
          'invoice': 'ACC-SINV-2026-00042',
          'woo_order_id': 21500,
          'customer_name': 'Omar',
          'docstatus': 0,
          'invoice_status': 'Draft',
          'current_total': 1000.0,
          'current_codes': ['WELCOME'],
          'current_promo_discount': 0,
          'delivery_amount': 50,
          'accepted': true,
          'reason': null,
          'discount_amount': 100,
          'free_delivery': false,
          'new_total': 900,
        },
      ),
    );
    await _pump(tester, repo);

    expect(find.text('Check promo code'), findsOneWidget);

    await tester.enterText(_codeField(), 'summer10');
    await tester.enterText(_orderField(), '21500');
    await tester.tap(find.byKey(const ValueKey('promoLookupCheckButton')));
    await tester.pumpAndSettle();

    expect(repo.calls.single, {'code': 'SUMMER10', 'order': '21500'});
    expect(find.text('SUMMER10'), findsWidgets);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Summer sale'), findsOneWidget);
    expect(
      find.text('10% off the whole order, up to EGP150.00'),
      findsOneWidget,
    );
    expect(find.text('EGP300.00 on the whole order'), findsOneWidget);
    expect(find.text('3 used, no limit'), findsOneWidget);
    expect(find.text('Yes, code SUMMER10'), findsOneWidget);
    expect(find.text('#21471'), findsOneWidget);

    expect(find.text('On this order'), findsOneWidget);
    expect(find.text('#21500'), findsOneWidget);
    expect(find.text('Omar'), findsOneWidget);
    expect(find.text('WELCOME'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('EGP1,000.00'), findsOneWidget);
    final newTotal = tester.widget<Text>(
      find.byKey(const ValueKey('promoLookupNewTotal')),
    );
    expect(newTotal.data, 'EGP900.00');
  });

  testWidgets('refused order shows the engine reason', (tester) async {
    final repo = _FakeRepo(
      (code, order) => _summer(
        orderCheck: {
          'invoice': 'ACC-SINV-2026-00043',
          'current_total': 200,
          'current_codes': [],
          'accepted': false,
          'reason': 'Order total is below the minimum of 300',
          'discount_amount': 0,
          'free_delivery': false,
          'new_total': 200,
        },
      ),
    );
    await _pump(tester, repo);

    await tester.enterText(_codeField(), 'SUMMER10');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Not accepted'), findsOneWidget);
    expect(
      find.text('Order total is below the minimum of 300'),
      findsOneWidget,
    );
    expect(find.text('2026-00043'), findsOneWidget);
  });

  testWidgets('order not found', (tester) async {
    final repo = _FakeRepo(
      (code, order) =>
          _summer(orderCheck: {'error': 'order_not_found', 'order': '424242'}),
    );
    await _pump(tester, repo);

    await tester.enterText(_codeField(), 'SUMMER10');
    await tester.enterText(_orderField(), '424242');
    await tester.tap(find.byKey(const ValueKey('promoLookupCheckButton')));
    await tester.pumpAndSettle();

    expect(find.text('No order 424242 found'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('unknown code', (tester) async {
    final repo = _FakeRepo((code, order) => {'found': false, 'code': code});
    await _pump(tester, repo);

    await tester.enterText(_codeField(), 'nope');
    await tester.tap(find.byKey(const ValueKey('promoLookupCheckButton')));
    await tester.pumpAndSettle();

    expect(repo.calls.single, {'code': 'NOPE', 'order': ''});
    expect(find.text('No promo code NOPE in the system'), findsOneWidget);
  });

  testWidgets('empty code asks for one and does not call the server', (
    tester,
  ) async {
    final repo = _FakeRepo((code, order) => {'found': false, 'code': code});
    await _pump(tester, repo);

    await tester.tap(find.byKey(const ValueKey('promoLookupCheckButton')));
    await tester.pumpAndSettle();

    expect(find.text('Type a promo code first'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('Arabic not-found and status labels', (tester) async {
    final repo = _FakeRepo(
      (code, order) => code == 'NOPE'
          ? {'found': false, 'code': code}
          : {..._summer(), 'status': 'expired'},
    );
    await _pump(tester, repo, locale: const Locale('ar'));

    expect(find.text('فحص كود الخصم'), findsOneWidget);

    await tester.enterText(_codeField(), 'nope');
    await tester.tap(find.byKey(const ValueKey('promoLookupCheckButton')));
    await tester.pumpAndSettle();
    expect(find.text('مفيش كود خصم NOPE على السيستم'), findsOneWidget);

    await tester.enterText(_codeField(), 'summer10');
    await tester.tap(find.byKey(const ValueKey('promoLookupCheckButton')));
    await tester.pumpAndSettle();
    expect(find.text('انتهى'), findsOneWidget);
    expect(find.text('توصيل مجاني'), findsNothing);
  });
}
