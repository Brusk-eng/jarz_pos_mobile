import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations_ar.dart';
import 'package:jarz_pos/l10n/app_localizations_en.dart';
import 'package:jarz_pos/src/features/promo_lookup/data/models/promo_lookup_models.dart';
import 'package:jarz_pos/src/features/promo_lookup/presentation/widgets/promo_lookup_result_view.dart';

Map<String, dynamic> _found({Object? orderCheck}) => {
  'found': true,
  'code': 'SUMMER10',
  'title': 'Summer',
  'description': null,
  'status': 'active',
  'discount_type': 'Percentage',
  'discount_value': 10, // int on purpose
  'max_discount_amount': 150.0,
  'min_order_amount': '300',
  'min_on_whole_order': 1,
  'applies_to': 'Item Groups',
  'scope': [
    {'type': 'Item Group', 'name': 'Jars', 'label': 'Jars'},
    {'type': 'Item', 'name': 'ITM-1'},
    'junk',
  ],
  'channels': ['POS', 'Website'],
  'allow_pickup': false,
  'stackable': 0,
  'usage_limit': 100.0,
  'times_used': 7,
  'remaining_uses': 93,
  'per_customer_limit': 1,
  'active_from': '2026-11-01',
  'active_to': null,
  'customer': null,
  'woo_coupon_code': 'summer10',
  'on_website': true,
  'recent_uses': [
    {
      'invoice': 'ACC-SINV-2026-00001',
      'woo_order_id': 21471,
      'customer_name': 'Mona',
      'date': '2026-11-05',
      'status': 'Active',
    },
    {
      'invoice': 'ACC-SINV-2026-00002',
      'woo_order_id': 0,
      'date': '2026-11-04',
      'status': 'Reversed',
    },
  ],
  'order_check': orderCheck,
  'some_future_key': {'x': 1},
};

void main() {
  group('PromoLookupResult.fromJson', () {
    test('found code with int/double mix and no order check', () {
      final r = PromoLookupResult.fromJson(_found());

      expect(r.found, isTrue);
      expect(r.code, 'SUMMER10');
      expect(r.title, 'Summer');
      expect(r.description, isNull);
      expect(r.status, PromoStatus.active);
      expect(r.discountType, PromoDiscountType.percentage);
      expect(r.discountValue, 10.0);
      expect(r.maxDiscountAmount, 150.0);
      expect(r.hasCap, isTrue);
      expect(r.minOrderAmount, 300.0);
      expect(r.minOnWholeOrder, isTrue);
      expect(r.appliesTo, PromoAppliesTo.itemGroups);
      expect(r.scope, hasLength(2));
      expect(r.scope.first.isItemGroup, isTrue);
      expect(r.scope.last.label, 'ITM-1', reason: 'label falls back to name');
      expect(r.channels, ['POS', 'Website']);
      expect(r.allowPickup, isFalse);
      expect(r.stackable, isFalse);
      expect(r.usageLimit, 100);
      expect(r.timesUsed, 7);
      expect(r.remainingUses, 93);
      expect(r.perCustomerLimit, 1);
      expect(r.activeFrom, '2026-11-01');
      expect(r.activeTo, isNull);
      expect(r.isLockedToCustomer, isFalse);
      expect(r.wooCouponCode, 'summer10');
      expect(r.onWebsite, isTrue);
      expect(r.recentUses, hasLength(2));
      expect(r.recentUses.first.wooOrderId, 21471);
      expect(r.recentUses.last.isReversed, isTrue);
      expect(r.orderCheck, isNull);
    });

    test('not found carries only the code', () {
      final r = PromoLookupResult.fromJson({'found': false, 'code': 'NOPE'});

      expect(r.found, isFalse);
      expect(r.code, 'NOPE');
      expect(r.scope, isEmpty);
      expect(r.recentUses, isEmpty);
      expect(r.orderCheck, isNull);
      expect(r.remainingUses, isNull);
    });

    test('unknown enums and missing keys do not throw', () {
      final r = PromoLookupResult.fromJson({
        'found': 1,
        'code': 'X',
        'status': 'paused',
        'discount_type': 'Buy One Get One',
        'applies_to': 'Brands',
        'usage_limit': 0,
        'remaining_uses': null,
      });
      expect(r.status, PromoStatus.unknown);
      expect(r.rawStatus, 'paused');
      expect(r.discountType, PromoDiscountType.unknown);
      expect(r.appliesTo, PromoAppliesTo.unknown);
      expect(r.isUnlimited, isTrue);
      expect(r.remainingUses, isNull);
    });

    test('order_check: order_not_found', () {
      final r = PromoLookupResult.fromJson(
        _found(orderCheck: {'error': 'order_not_found', 'order': '99999'}),
      );
      final c = r.orderCheck!;
      expect(c.hasError, isTrue);
      expect(c.orderNotFound, isTrue);
      expect(c.order, '99999');
      expect(c.notPermitted, isFalse);
    });

    test('order_check: not_permitted and waived delivery', () {
      final denied = PromoLookupResult.fromJson(
        _found(orderCheck: {'error': 'not_permitted', 'order': '21471'}),
      ).orderCheck!;
      expect(denied.hasError, isTrue);
      expect(denied.notPermitted, isTrue);
      expect(denied.orderNotFound, isFalse);

      final waived = PromoLookupResult.fromJson(
        _found(
          orderCheck: {
            'invoice': 'SI-1',
            'current_total': 450,
            'waived_delivery': 50,
            'accepted': true,
            'new_total': 455,
          },
        ),
      ).orderCheck!;
      expect(waived.waivedDelivery, 50.0);
      expect(waived.notPermitted, isFalse);
    });

    test('order_check: accepted, numbers as int and double', () {
      final r = PromoLookupResult.fromJson(
        _found(
          orderCheck: {
            'invoice': 'ACC-SINV-2026-00042',
            'woo_order_id': 21500.0,
            'customer_name': 'Omar',
            'docstatus': 1,
            'invoice_status': 'Unpaid',
            'current_total': 1000,
            'current_codes': ['WELCOME'],
            'current_promo_discount': 0,
            'delivery_amount': 50.5,
            'accepted': true,
            'reason': null,
            'discount_amount': 100,
            'free_delivery': 0,
            'new_total': 900.0,
          },
        ),
      );
      final c = r.orderCheck!;
      expect(c.hasError, isFalse);
      expect(c.orderNotFound, isFalse);
      expect(c.invoice, 'ACC-SINV-2026-00042');
      expect(c.wooOrderId, 21500);
      expect(c.customerName, 'Omar');
      expect(c.docstatus, 1);
      expect(c.invoiceStatus, 'Unpaid');
      expect(c.currentTotal, 1000.0);
      expect(c.currentCodes, ['WELCOME']);
      expect(c.deliveryAmount, 50.5);
      expect(c.accepted, isTrue);
      expect(c.reason, isNull);
      expect(c.discountAmount, 100.0);
      expect(c.freeDelivery, isFalse);
      expect(c.newTotal, 900.0);
    });

    test('order_check: refused with an engine reason', () {
      final r = PromoLookupResult.fromJson(
        _found(
          orderCheck: {
            'invoice': 'ACC-SINV-2026-00043',
            'woo_order_id': null,
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
      final c = r.orderCheck!;
      expect(c.accepted, isFalse);
      expect(c.reason, 'Order total is below the minimum of 300');
      expect(c.wooOrderId, isNull);
      expect(c.newTotal, 200.0);
    });
  });

  group('CustomerPromoLookup.fromJson', () {
    // The example from CONTRACT.md (promo-customer-lookup), with the
    // CodeSummary and UseRow examples placed in the customer.
    final contractCode = {
      'code': 'BACK96R8TB',
      'title': 'Win-back one - Amal Bedross',
      'description': '...',
      'status': 'expired',
      'personal': true,
      'discount_type': 'Percentage',
      'discount_value': 15.0,
      'max_discount_amount': 100.0,
      'min_order_amount': 400.0,
      'min_on_whole_order': false,
      'applies_to': 'Whole Order',
      'scope': [
        {'type': 'Item', 'name': '...', 'label': '...'},
      ],
      'channels': ['woo', 'flutter'],
      'allow_pickup': true,
      'stackable': false,
      'usage_limit': 1,
      'times_used': 1,
      'remaining_uses': 0,
      'per_customer_limit': 1,
      'customer_times_used': 1,
      'customer_remaining_uses': 0,
      'active_from': '2026-10-31 00:03:04',
      'active_to': '2026-11-07 00:03:04',
      'on_website': false,
      'woo_coupon_code': null,
    };
    final contractUse = {
      'code': 'BACK96R8TB',
      'invoice': 'ACC-SINV-2026-19228-1',
      'woo_order_id': 20240,
      'date': '2026-10-31',
      'status': 'Active',
      'discount': 90.0,
      'order_total': 510.0,
    };
    final contractExample = {
      'query': '0122 549',
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
          'active_codes': [],
          'public_codes': [],
          'inactive_codes': [contractCode],
          'used_codes': [contractUse],
        },
      ],
    };

    test('contract example', () {
      final r = CustomerPromoLookup.fromJson(contractExample);

      expect(r.query, '0122 549');
      expect(r.matchType, CustomerPromoMatchType.phone);
      expect(r.truncated, isFalse);
      expect(r.customers, hasLength(1));

      final c = r.customers.single;
      expect(c.customer, 'Amal Bedross');
      expect(c.customerName, 'Amal Bedross');
      expect(c.displayName, 'Amal Bedross');
      expect(c.isPhoneOnly, isFalse);
      expect(c.phone, '01225495533');
      expect(c.orderCount, 2);
      expect(c.lastOrderDate, '2026-11-10');
      expect(c.lastWooOrderId, 21658);
      expect(c.activeCodes, isEmpty);
      expect(c.publicCodes, isEmpty);

      final code = c.inactiveCodes.single;
      expect(code.found, isTrue, reason: 'a summary is always a real code');
      expect(code.code, 'BACK96R8TB');
      expect(code.status, PromoStatus.expired);
      expect(code.personal, isTrue);
      expect(code.discountType, PromoDiscountType.percentage);
      expect(code.discountValue, 15.0);
      expect(code.maxDiscountAmount, 100.0);
      expect(code.minOrderAmount, 400.0);
      expect(code.minOnWholeOrder, isFalse);
      expect(code.appliesTo, PromoAppliesTo.wholeOrder);
      expect(code.scope.single.label, '...');
      expect(code.channels, ['woo', 'flutter']);
      expect(code.allowPickup, isTrue);
      expect(code.usageLimit, 1);
      expect(code.timesUsed, 1);
      expect(code.remainingUses, 0);
      expect(code.perCustomerLimit, 1);
      expect(code.customerTimesUsed, 1);
      expect(code.customerRemainingUses, 0);
      expect(code.usesLeftForCustomer, 0);
      expect(code.activeTo, '2026-11-07 00:03:04');
      expect(code.onWebsite, isFalse);
      expect(code.wooCouponCode, isNull);

      final use = c.usedCodes.single;
      expect(use.code, 'BACK96R8TB');
      expect(use.invoice, 'ACC-SINV-2026-19228-1');
      expect(use.wooOrderId, 20240);
      expect(use.date, '2026-10-31');
      expect(use.isReversed, isFalse);
      expect(use.discount, 90.0);
      expect(use.orderTotal, 510.0);
    });

    test('phone-only entry, ints as doubles, missing lists, nulls', () {
      final r = CustomerPromoLookup.fromJson({
        'query': 'mon',
        'match_type': 'something-new',
        'truncated': 1,
        'customers': [
          {
            'customer': null,
            'customer_name': null,
            'phone': '01000000001',
            'order_count': 3.0,
            'last_order_date': null,
            'last_woo_order_id': 0,
            'active_codes': [
              {
                'code': 'X1',
                'status': 'not_started',
                'discount_type': 'Fixed Amount',
                'discount_value': '50',
                'usage_limit': 0,
                'remaining_uses': null,
                'customer_remaining_uses': 2.0,
              },
              'junk',
            ],
            'used_codes': [
              {
                'code': 'X0',
                'invoice': 'ACC-SINV-2026-1',
                'woo_order_id': '',
                'status': 'Reversed',
                'discount': 25,
                'order_total': null,
              },
            ],
          },
          'junk',
        ],
      });

      expect(r.matchType, CustomerPromoMatchType.unknown);
      expect(r.truncated, isTrue);
      expect(r.customers, hasLength(1));
      final c = r.customers.single;
      expect(c.isPhoneOnly, isTrue);
      expect(c.displayName, '01000000001');
      expect(c.orderCount, 3);
      expect(c.lastWooOrderId, 0);
      expect(c.publicCodes, isEmpty);
      expect(c.inactiveCodes, isEmpty);
      final code = c.activeCodes.single;
      expect(code.status, PromoStatus.notStarted);
      expect(code.discountType, PromoDiscountType.fixedAmount);
      expect(code.discountValue, 50.0);
      expect(code.personal, isFalse);
      expect(code.customerRemainingUses, 2);
      expect(code.usesLeftForCustomer, 2);
      final use = c.usedCodes.single;
      expect(use.wooOrderId, isNull);
      expect(use.isReversed, isTrue);
      expect(use.discount, 25.0);
      expect(use.orderTotal, isNull);
      expect(use.date, isNull);
    });

    test('empty or odd payloads do not throw', () {
      final empty = CustomerPromoLookup.fromJson(null);
      expect(empty.customers, isEmpty);
      expect(empty.query, '');
      final noList = CustomerPromoLookup.fromJson({'customers': 'x'});
      expect(noList.customers, isEmpty);
    });

    test('uses left takes the smaller of own and overall', () {
      final code = PromoLookupResult.fromCodeSummary({
        'code': 'Y',
        'remaining_uses': 1,
        'customer_remaining_uses': 3,
      });
      expect(code.usesLeftForCustomer, 1);
      final unlimited = PromoLookupResult.fromCodeSummary({'code': 'Z'});
      expect(unlimited.usesLeftForCustomer, isNull);
    });
  });

  group('promoOfferText', () {
    String money(num v) => '${v.toStringAsFixed(0)} EGP';
    String number(num v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

    test('percentage with a cap on item groups', () {
      final r = PromoLookupResult.fromJson(_found());
      expect(
        promoOfferText(AppLocalizationsEn(), r, money: money, number: number),
        '10% off selected categories, up to 150 EGP',
      );
    });

    test('percentage without a cap on the whole order', () {
      final r = PromoLookupResult.fromJson({
        'found': true,
        'code': 'A',
        'discount_type': 'Percentage',
        'discount_value': 12.5,
        'max_discount_amount': 0,
        'applies_to': 'Whole Order',
      });
      expect(
        promoOfferText(AppLocalizationsEn(), r, money: money, number: number),
        '12.5% off the whole order',
      );
    });

    test('fixed amount and free delivery', () {
      final fixed = PromoLookupResult.fromJson({
        'found': true,
        'code': 'B',
        'discount_type': 'Fixed Amount',
        'discount_value': 50,
      });
      expect(
        promoOfferText(
          AppLocalizationsEn(),
          fixed,
          money: money,
          number: number,
        ),
        '50 EGP off the whole order',
      );
      final free = PromoLookupResult.fromJson({
        'found': true,
        'code': 'C',
        'discount_type': 'Free Delivery',
        'discount_value': 0,
      });
      expect(
        promoOfferText(
          AppLocalizationsAr(),
          free,
          money: money,
          number: number,
        ),
        'توصيل مجاني',
      );
    });
  });
}
