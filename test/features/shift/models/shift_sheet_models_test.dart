import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/features/shift/models/shift_sheet_models.dart';

void main() {
  test('parses a full manager payload', () {
    final sheet = ShiftSheet.fromJson({
      'opening_entry': 'POS-OPE-1',
      'closing_entry': 'POS-CLO-1',
      'pos_profile': 'Zamalek',
      'branch_label': 'Zamalek Branch',
      'user': 'a@x.com',
      'user_full_name': 'Amr Ali',
      'opened_at': '2026-11-20 09:00:00',
      'closed_at': '2026-11-20 17:00:00',
      'is_open': 0,
      'is_manager_view': true,
      'amounts_hidden': 0,
      'orders': [
        {
          'name': 'ACC-SINV-1',
          'order_number': '1001',
          'created_at': '2026-11-20 10:15:00',
          'jars': 3,
          'grand_total': '250.5',
          'outstanding_amount': 50,
          'delivery_fee': 30,
          'courier': 'Hassan',
          'is_pickup': 0,
          'area': 'Maadi',
          'payment_method': 'Cash',
        },
      ],
      'jars_by_flavour': [
        {'flavour': 'Mango', 'small': 1, 'medium': 2, 'large': 0},
      ],
      'payouts': [
        {'kind': 'advance', 'name': 'EA-1', 'label': 'Advance', 'amount': 100},
      ],
      'totals': {
        'orders': 1,
        'jars': 3,
        'grand_total': 250.5,
        'delivery_fees': 30,
        'payouts': 100,
        'opening_amount': 500,
        'expected_closing': 680.5,
        'actual_closing': 680.5,
        'difference': 0,
      },
    });
    expect(sheet.isOpen, isFalse);
    expect(sheet.isManagerView, isTrue);
    expect(sheet.amountsHidden, isFalse);
    expect(sheet.orders.single.grandTotal, 250.5);
    expect(sheet.orders.single.isUnpaid, isTrue);
    expect(sheet.orders.single.createdAt, isNotNull);
    expect(sheet.jarsByFlavour.single.medium, 2);
    expect(sheet.payouts.single.kind, 'advance');
    expect(sheet.totals!.expectedClosing, 680.5);
    expect(sheet.staffLabel, 'Amr Ali');
  });

  test('staff payload keeps totals null and amounts hidden', () {
    final sheet = ShiftSheet.fromJson({
      'opening_entry': 'POS-OPE-2',
      'is_open': 1,
      'amounts_hidden': 1,
      'totals': null,
      'orders': [
        {'name': 'S1', 'is_pickup': 1, 'jars': 2, 'grand_total': 90},
      ],
    });
    expect(sheet.totals, isNull);
    expect(sheet.amountsHidden, isTrue);
    expect(sheet.isOpen, isTrue);
    expect(sheet.orders.single.isPickup, isTrue);
    // order_number falls back to the document name
    expect(sheet.orders.single.orderNumber, 'S1');
  });

  test('missing and malformed fields do not throw', () {
    final sheet = ShiftSheet.fromJson({
      'opening_entry': 'X',
      'orders': [
        'junk',
        {'name': 'A', 'jars': 'abc', 'grand_total': null},
      ],
      'jars_by_flavour': 5,
      'payouts': null,
    });
    expect(sheet.amountsHidden, isTrue);
    expect(sheet.orders.length, 1);
    expect(sheet.orders.single.jars, 0);
    expect(sheet.jarsByFlavour, isEmpty);
    expect(sheet.payouts, isEmpty);
    expect(sheet.totals, isNull);
    expect(ShiftSheet.fromJson(const {}).openingEntry, '');
  });

  test('old server JSON defaults new fields', () {
    final sheet = ShiftSheet.fromJson({
      'opening_entry': 'O',
      'amounts_hidden': 0,
      'orders': [
        {'name': 'A'},
      ],
      'totals': {'orders': 2},
    });
    final o = sheet.orders.single;
    expect(o.reasons, ['created']);
    expect(o.isNew, isTrue);
    expect(o.isSettled, isFalse);
    expect(o.outForDeliveryAt, isNull);
    expect(o.settledAt, isNull);
    expect(o.settledAmount, 0);
    expect(sheet.returns, isEmpty);
    expect(sheet.totals!.newOrders, 0);
    expect(sheet.totals!.cashRefunds, 0);
  });

  test('parses reasons, returns and new totals', () {
    final sheet = ShiftSheet.fromJson({
      'opening_entry': 'O',
      'orders': [
        {
          'name': 'A',
          'reasons': ['out_for_delivery', 'settled'],
          'out_for_delivery_at': '2026-11-23T10:15:00',
          'settled_at': '2026-11-23T12:00:00',
          'settled_amount': '250.5',
        },
      ],
      'returns': [
        {
          'credit_note': 'CN-1',
          'order': 'SINV-1',
          'order_number': '1001',
          'amount': 100,
          'refund_amount': 80,
          'refund_account': 'Bank - J',
          'refund_kind': 'bank',
          'at': '2026-11-23T13:00:00',
        },
        'junk',
      ],
      'totals': {
        'new_orders': 3,
        'out_for_delivery_orders': 2,
        'settled_orders': 1,
        'settled_amount': 250.5,
        'returns': 1,
        'returns_amount': 100,
        'cash_refunds': 0,
        'bank_refunds': 80,
      },
    });
    final o = sheet.orders.single;
    expect(o.reasons, ['out_for_delivery', 'settled']);
    expect(o.isNew, isFalse);
    expect(o.isOutForDelivery, isTrue);
    expect(o.isSettled, isTrue);
    expect(o.outForDeliveryAt, DateTime(2026, 11, 23, 10, 15));
    expect(o.settledAmount, 250.5);
    final r = sheet.returns.single;
    expect(r.orderNumber, '1001');
    expect(r.refundKind, 'bank');
    expect(r.refundAccount, 'Bank - J');
    expect(r.refundAmount, 80);
    final t = sheet.totals!;
    expect(t.newOrders, 3);
    expect(t.outForDeliveryOrders, 2);
    expect(t.settledOrders, 1);
    expect(t.settledAmount, 250.5);
    expect(t.returns, 1);
    expect(t.returnsAmount, 100);
    expect(t.bankRefunds, 80);
  });

  test(
    'old server JSON defaults the courier, delivery and cash-flow fields',
    () {
      final sheet = ShiftSheet.fromJson({
        'opening_entry': 'O',
        'amounts_hidden': 0,
        'orders': [
          {'name': 'A', 'delivery_fee': 30},
        ],
        'totals': {'orders': 1},
      });
      final o = sheet.orders.single;
      expect(o.shippingExpense, isNull);
      expect(o.courierCashIn, 0);
      expect(o.courierFeePaid, 0);
      final t = sheet.totals!;
      expect(t.deliveryOrders, 0);
      expect(t.deliveryIncome, 0);
      expect(t.deliveryCost, 0);
      expect(t.deliveryNet, 0);
      expect(t.courierCashIn, 0);
      expect(t.courierFeesPaid, 0);
      expect(sheet.cashFlow, isNull);
    },
  );

  test('parses per-order courier money and delivery totals', () {
    final sheet = ShiftSheet.fromJson({
      'opening_entry': 'O',
      'orders': [
        {
          'name': 'A',
          'shipping_expense': '45',
          'courier_cash_in': 205,
          'courier_fee_paid': 45,
        },
        {'name': 'B', 'shipping_expense': 0, 'courier_cash_in': '-60'},
        {'name': 'C', 'shipping_expense': null},
      ],
      'totals': {
        'delivery_orders': '12',
        'delivery_income': 360,
        'delivery_cost': 540.5,
        'delivery_net': -180.5,
        'courier_cash_in': 5800,
        'courier_fees_paid': 995,
      },
      'cash_flow': null,
    });
    final a = sheet.orders[0];
    expect(a.shippingExpense, 45);
    expect(a.courierCashIn, 205);
    expect(a.courierFeePaid, 45);
    expect(sheet.orders[1].shippingExpense, 0);
    expect(sheet.orders[1].courierCashIn, -60);
    expect(sheet.orders[2].shippingExpense, isNull);
    final t = sheet.totals!;
    expect(t.deliveryOrders, 12);
    expect(t.deliveryIncome, 360);
    expect(t.deliveryCost, 540.5);
    expect(t.deliveryNet, -180.5);
    expect(t.courierCashIn, 5800);
    expect(t.courierFeesPaid, 995);
    expect(sheet.cashFlow, isNull);
  });

  test('parses the cash_flow waterfall and its lines', () {
    final sheet = ShiftSheet.fromJson({
      'opening_entry': 'O',
      'cash_flow': {
        'opening': 101,
        'sales_cash': 240,
        'courier_orders': 5800,
        'courier_fees': -995,
        'expenses': '-95',
        'refunds': 0,
        'handovers': -3000,
        'other': 0,
        'expected': 2051,
        'counted': 2051,
        'difference': 0,
        'is_open': false,
        'lines': [
          {
            'kind': 'handovers',
            'voucher_type': 'Journal Entry',
            'voucher_no': 'ACC-JV-1',
            'label': 'Cash - J',
            'amount': -3000,
            'at': '2026-11-23T22:10:00',
          },
          {'kind': 'expenses', 'voucher_no': 'EXP-1', 'amount': -95},
          'junk',
        ],
      },
    });
    final f = sheet.cashFlow!;
    expect(f.opening, 101);
    expect(f.salesCash, 240);
    expect(f.courierOrders, 5800);
    expect(f.courierFees, -995);
    expect(f.expenses, -95);
    expect(f.handovers, -3000);
    expect(f.expected, 2051);
    expect(f.counted, 2051);
    expect(f.difference, 0);
    expect(f.isOpen, isFalse);
    expect(
      f.opening +
          ShiftSheetCashFlow.kinds.map(f.amountOf).reduce((a, b) => a + b),
      f.expected,
    );
    expect(f.lines.length, 2);
    final h = f.linesOf('handovers').single;
    expect(h.voucherType, 'Journal Entry');
    expect(h.label, 'Cash - J');
    expect(h.amount, -3000);
    expect(h.at, DateTime(2026, 11, 23, 22, 10));
    // label falls back to the voucher number
    expect(f.linesOf('expenses').single.label, 'EXP-1');
    expect(f.linesOf('refunds'), isEmpty);
  });

  test('open shift cash_flow keeps counted and difference null', () {
    final f = ShiftSheet.fromJson({
      'opening_entry': 'O',
      'cash_flow': {
        'opening': 100,
        'expected': 100,
        'counted': null,
        'difference': null,
        'is_open': 1,
      },
    }).cashFlow!;
    expect(f.isOpen, isTrue);
    expect(f.counted, isNull);
    expect(f.difference, isNull);
    expect(f.lines, isEmpty);
    expect(f.salesCash, 0);
  });
}
