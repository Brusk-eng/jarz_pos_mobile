import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/promo_lookup/data/models/promo_lookup_models.dart';
import 'package:jarz_pos/src/features/promo_lookup/data/promo_lookup_repository.dart';
import 'package:jarz_pos/src/features/promo_lookup/presentation/screens/promo_lookup_screen.dart';

class _FakeRepo implements PromoLookupRepository {
  _FakeRepo(this.answer, {this.customerAnswer});

  final Map<String, dynamic> Function(String code, String? order) answer;
  final Map<String, dynamic> Function(String query)? customerAnswer;
  final List<Map<String, String?>> calls = [];
  final List<String> customerCalls = [];

  @override
  Future<CustomerPromoLookup> lookupCustomerPromos(String query) async {
    customerCalls.add(query);
    final answer = customerAnswer;
    return CustomerPromoLookup.fromJson(
      answer == null ? {'query': query, 'customers': []} : answer(query),
    );
  }

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

/// Pumps the screen. It opens on the Customer tab; [codeTab] switches to the
/// Code tab first, which is where the original code-lookup tests live.
Future<void> _pump(
  WidgetTester tester,
  _FakeRepo repo, {
  Locale locale = const Locale('en'),
  bool codeTab = true,
  Size size = const Size(800, 2400),
}) async {
  await tester.binding.setSurfaceSize(size);
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
  if (codeTab) {
    await tester.tap(find.byKey(const ValueKey('promoLookupCodeTab')));
    await tester.pumpAndSettle();
  }
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
          'waived_delivery': 30,
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
    // The order already carries WELCOME, so the total is labelled as a swap.
    expect(
      find.text('New total (this code instead of the current ones)'),
      findsOneWidget,
    );
    expect(find.text('Delivery waived by the current code'), findsOneWidget);
    expect(find.text('EGP30.00'), findsOneWidget);
  });

  testWidgets('order the user may not see', (tester) async {
    final repo = _FakeRepo(
      (code, order) =>
          _summer(orderCheck: {'error': 'not_permitted', 'order': '21471'}),
    );
    await _pump(tester, repo);

    await tester.enterText(_codeField(), 'SUMMER10');
    await tester.enterText(_orderField(), '21471');
    await tester.tap(find.byKey(const ValueKey('promoLookupCheckButton')));
    await tester.pumpAndSettle();

    expect(find.text('No access to order 21471'), findsOneWidget);
    expect(find.byKey(const ValueKey('promoLookupNewTotal')), findsNothing);
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

  group('Customer tab', () {
    testWidgets('opens on the Customer tab', (tester) async {
      final repo = _FakeRepo((code, order) => {'found': false, 'code': code});
      await _pump(tester, repo, codeTab: false);

      expect(find.text('Check promo code'), findsOneWidget);
      expect(_customerField(), findsOneWidget);
      expect(find.text('Name or phone number'), findsOneWidget);
      // The Code tab is not built until it is opened.
      expect(_codeField(), findsNothing);
      final controller = DefaultTabController.of(
        tester.element(_customerField()),
      );
      expect(controller.index, 0);
    });

    testWidgets('fewer than 3 characters asks for more, no server call', (
      tester,
    ) async {
      final repo = _FakeRepo(
        (code, order) => {'found': false, 'code': code},
        customerAnswer: (q) => _amalAnswer(q),
      );
      await _pump(tester, repo, codeTab: false);

      await tester.enterText(_customerField(), ' am ');
      await tester.tap(find.byKey(const ValueKey('promoCustomerSearchButton')));
      await tester.pumpAndSettle();

      expect(
        find.text('Type at least 3 characters of a name or phone number'),
        findsOneWidget,
      );
      expect(repo.customerCalls, isEmpty);
    });

    testWidgets('search shows the active code and copy puts it on the '
        'clipboard', (tester) async {
      final clipboard = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      final repo = _FakeRepo(
        (code, order) => {'found': false, 'code': code},
        customerAnswer: (q) => _amalAnswer(q),
      );
      await _pump(tester, repo, codeTab: false);

      await tester.enterText(_customerField(), '  0122 549 ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(repo.customerCalls.single, '0122 549');
      expect(find.text('Amal Bedross'), findsOneWidget);
      expect(find.text('01225495533'), findsOneWidget);
      expect(find.textContaining('Orders: 2'), findsOneWidget);
      expect(find.textContaining('#21658'), findsOneWidget);

      // Active personal code, with its conditions.
      expect(find.text('Active personal codes'), findsOneWidget);
      expect(find.text('WELCOME15'), findsOneWidget);
      expect(
        find.text('15% off the whole order, up to EGP100.00'),
        findsOneWidget,
      );
      expect(
        find.textContaining('EGP400.00 on the whole order'),
        findsOneWidget,
      );
      expect(find.textContaining('Valid until Dec 31, 2026'), findsOneWidget);
      expect(find.text('Uses left for this customer: 1'), findsOneWidget);
      expect(find.text('No active personal code'), findsNothing);

      // Open code, past uses, expired code (collapsed).
      expect(find.text('FREESHIP'), findsOneWidget);
      expect(find.text('Free delivery'), findsOneWidget);
      expect(find.textContaining('#20240'), findsOneWidget);
      expect(find.textContaining('2026-00007'), findsOneWidget);
      expect(find.text('Cancelled / reversed'), findsOneWidget);
      expect(find.text('EGP90.00 off a EGP510.00 order'), findsOneWidget);
      expect(find.text('Expired / used-up codes (1)'), findsOneWidget);
      expect(find.byKey(const ValueKey('promoCopy-BACK96R8TB')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('promoCopy-WELCOME15')));
      await tester.pumpAndSettle();
      expect(clipboard, ['WELCOME15']);
      expect(find.text('Code copied'), findsOneWidget);

      await tester.tap(find.text('Expired / used-up codes (1)'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('promoCopy-BACK96R8TB')),
        findsOneWidget,
      );
      expect(find.text('Expired'), findsOneWidget);
    });

    testWidgets('no customer found', (tester) async {
      final repo = _FakeRepo(
        (code, order) => {'found': false, 'code': code},
        customerAnswer: (q) => {
          'query': q,
          'match_type': 'name',
          'truncated': false,
          'customers': [],
        },
      );
      await _pump(tester, repo, codeTab: false);

      await tester.enterText(_customerField(), 'Zzyzx');
      await tester.tap(find.byKey(const ValueKey('promoCustomerSearchButton')));
      await tester.pumpAndSettle();

      expect(find.textContaining('No customer found for'), findsOneWidget);
      expect(find.textContaining('Zzyzx'), findsWidgets);
    });

    testWidgets('no active code, phone-only entry and truncated note', (
      tester,
    ) async {
      final repo = _FakeRepo(
        (code, order) => {'found': false, 'code': code},
        customerAnswer: (q) => {
          'query': q,
          'match_type': 'name',
          'truncated': true,
          'customers': [
            {
              'customer': 'Mona',
              'customer_name': 'Mona Adel',
              'phone': null,
              'order_count': 0,
            },
            {
              'customer': null,
              'customer_name': null,
              'phone': '01000000001',
              'order_count': 0,
              'active_codes': [_welcome15()],
            },
          ],
        },
      );
      await _pump(tester, repo, codeTab: false);

      await tester.enterText(_customerField(), 'mon');
      await tester.tap(find.byKey(const ValueKey('promoCustomerSearchButton')));
      await tester.pumpAndSettle();

      expect(
        find.text('Showing first 10 matches — type more of the name'),
        findsOneWidget,
      );
      expect(find.text('Mona Adel'), findsOneWidget);
      expect(find.text('No active personal code'), findsOneWidget);
      expect(find.text('Never used a promo code'), findsNWidgets(2));
      expect(find.text('01000000001'), findsOneWidget);
      expect(
        find.text('Phone number only, no customer record'),
        findsOneWidget,
      );
    });

    testWidgets('Arabic on a phone-width screen does not overflow', (
      tester,
    ) async {
      final repo = _FakeRepo(
        (code, order) => {'found': false, 'code': code},
        customerAnswer: (q) => _amalAnswer(q),
      );
      await _pump(
        tester,
        repo,
        locale: const Locale('ar'),
        codeTab: false,
        size: const Size(360, 3000),
      );

      expect(find.text('العميل'), findsOneWidget);
      expect(find.text('الكود'), findsOneWidget);
      expect(find.text('الاسم أو رقم الموبايل'), findsOneWidget);

      await tester.enterText(_customerField(), 'أمال');
      await tester.tap(find.byKey(const ValueKey('promoCustomerSearchButton')));
      await tester.pumpAndSettle();

      expect(find.text('أكواد الخصم الشخصية الفعالة'), findsOneWidget);
      expect(find.text('WELCOME15'), findsOneWidget);
      expect(find.text('اتلغى / اترجع'), findsOneWidget);
      await tester.tap(find.text('أكواد منتهية أو مستخدمة (1)'));
      await tester.pumpAndSettle();
      expect(find.text('BACK96R8TB'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switching tabs keeps the customer answer', (tester) async {
      final repo = _FakeRepo(
        (code, order) => {'found': false, 'code': code},
        customerAnswer: (q) => _amalAnswer(q),
      );
      await _pump(tester, repo, codeTab: false);

      await tester.enterText(_customerField(), 'amal');
      await tester.tap(find.byKey(const ValueKey('promoCustomerSearchButton')));
      await tester.pumpAndSettle();
      expect(find.text('WELCOME15'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('promoLookupCodeTab')));
      await tester.pumpAndSettle();
      expect(_codeField(), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('promoLookupCustomerTab')));
      await tester.pumpAndSettle();
      expect(find.text('WELCOME15'), findsOneWidget);
      expect(repo.customerCalls, ['amal']);
    });
  });
}

Finder _customerField() =>
    find.byKey(const ValueKey('promoCustomerSearchField'));

Map<String, dynamic> _welcome15() => {
  'code': 'WELCOME15',
  'title': 'Welcome back - Amal',
  'status': 'active',
  'personal': true,
  'discount_type': 'Percentage',
  'discount_value': 15,
  'max_discount_amount': 100.0,
  'min_order_amount': 400,
  'min_on_whole_order': true,
  'applies_to': 'Whole Order',
  'scope': [],
  'channels': [],
  'allow_pickup': true,
  'stackable': false,
  'usage_limit': 1,
  'times_used': 0,
  'remaining_uses': 1,
  'per_customer_limit': 1,
  'customer_times_used': 0,
  'customer_remaining_uses': 1,
  'active_from': '2026-11-01 00:00:00',
  'active_to': '2026-12-31 23:59:59',
  'on_website': false,
  'woo_coupon_code': null,
};

Map<String, dynamic> _amalAnswer(String query) => {
  'query': query,
  'match_type': 'phone',
  'truncated': false,
  'customers': [
    {
      'customer': 'Amal Bedross',
      'customer_name': 'Amal Bedross',
      'phone': '01225495533',
      'order_count': 2,
      'last_order_date': '2026-11-10',
      'last_woo_order_id': 21658,
      'active_codes': [_welcome15()],
      'public_codes': [
        {
          'code': 'FREESHIP',
          'status': 'active',
          'personal': false,
          'discount_type': 'Free Delivery',
          'discount_value': 0,
          'channels': ['woo'],
          'allow_pickup': false,
          'usage_limit': 0,
          'remaining_uses': null,
          'per_customer_limit': 0,
          'customer_remaining_uses': null,
          'active_to': null,
        },
      ],
      'inactive_codes': [
        {
          'code': 'BACK96R8TB',
          'title': 'Win-back one - Amal Bedross',
          'status': 'expired',
          'personal': true,
          'discount_type': 'Percentage',
          'discount_value': 15.0,
          'max_discount_amount': 100.0,
          'min_order_amount': 400.0,
          'usage_limit': 1,
          'times_used': 1,
          'remaining_uses': 0,
          'per_customer_limit': 1,
          'customer_times_used': 1,
          'customer_remaining_uses': 0,
          'active_from': '2026-10-31 00:03:04',
          'active_to': '2026-11-07 00:03:04',
        },
      ],
      'used_codes': [
        {
          'code': 'BACK96R8TB',
          'invoice': 'ACC-SINV-2026-19228-1',
          'woo_order_id': 20240,
          'date': '2026-10-31',
          'status': 'Active',
          'discount': 90.0,
          'order_total': 510.0,
        },
        {
          'code': 'OLDCODE',
          'invoice': 'ACC-SINV-2026-00007',
          'woo_order_id': null,
          'date': '2026-09-01',
          'status': 'Reversed',
          'discount': 50,
          'order_total': null,
        },
      ],
    },
  ],
};
