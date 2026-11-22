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
}
