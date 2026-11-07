import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/features/monthly_expenses/models/monthly_expense_models.dart';

/// The full `get_monthly_expenses` envelope, shaped exactly as the frozen
/// contract describes it, with the staging ground truth in it: four Rent items,
/// three of them sharing one account so the attribution rules have something to
/// bite on.
Map<String, dynamic> _payload() => {
      'month': '2026-09',
      'month_label': 'September 2026',
      'month_start': '2026-09-01',
      'month_end': '2026-09-30',
      'company': 'JARZ',
      'currency': 'EGP',
      'available_months': ['2026-07', '2026-08', '2026-09'],
      'summary': {
        'run_rate': 155000,
        'due': 155000,
        'paid': 47000,
        'remaining': 108000,
        'overpaid': 0,
        'items_total': 4,
        'items_paid': 1,
        'items_partial': 0,
        'items_unpaid': 3,
      },
      'by_category': [
        {
          'category': 'Rent',
          'due': 47000,
          'paid': 47000,
          'remaining': 0,
          'count': 4,
          'source': 'registry',
        },
        {
          'category': 'Salaries',
          'due': 108000,
          'paid': 0,
          'remaining': 108000,
          'count': 16,
          'source': 'payroll',
        },
      ],
      'recurring': [
        {
          'name': 'JRE-0001',
          'expense_name': 'Factory rent',
          'category': 'Rent',
          'status': 'Active',
          'amount': 20000,
          'frequency': 'Monthly',
          'monthly_equivalent': 20000,
          'day_of_month': 5,
          'due_date': '2026-09-05',
          'expense_account': 'Rent - Factory - J',
          'expense_account_label': 'Rent - Factory',
          'cost_center': 'Main - J',
          'supplier': null,
          'default_paying_account': 'Cash - J',
          'start_date': '2025-01-01',
          'end_date': null,
          'notes': 'Paid to the landlord in cash',
          'due_this_month': 1,
          'due_amount': 20000,
          'paid_amount': 20000,
          'paid_linked': 15000,
          'paid_unlinked': 5000,
          'remaining': 0,
          'payment_status': 'Paid',
          'shared_account': false,
          'inferred': true,
          'can_pay': false,
          'payments': [
            {
              'name': 'JER-0009',
              'amount': 15000,
              'date': '2026-09-03',
              'paying_account': 'Cash - J',
              'paying_label': 'Main cash drawer',
              'journal_entry': 'ACC-JV-2026-00042',
              'remarks': 'First half',
              'by': 'manager@jarz.com',
            }
          ],
        },
        {
          'name': 'JRE-0002',
          'expense_name': 'Dokki rent',
          'category': 'Rent',
          'status': 'Paused',
          'amount': 9000,
          'frequency': 'Monthly',
          'monthly_equivalent': 9000,
          'expense_account': 'Rent - Shared - J',
          'expense_account_label': 'Rent - Shared',
          'due_this_month': 0,
          'due_amount': 0,
          'paid_amount': 0,
          'paid_linked': 0,
          'paid_unlinked': 0,
          'remaining': 0,
          'payment_status': 'Not Due',
          'shared_account': true,
          'inferred': false,
          'can_pay': false,
          'payments': [],
        },
      ],
      'payroll': {
        'configured': 1,
        'employees_total': 16,
        'employees_with_structure': 15,
        'employees_without_structure': 1,
        'salary_account': 'Salary - J',
        'due': 108000,
        'paid': 0,
        'remaining': 108000,
        'unattributed_gl': 2500,
        'rows': [
          {
            'employee': 'HR-EMP-00001',
            'employee_name': 'Sara Ali',
            'designation': 'Barista',
            'department': 'Operations',
            'base': 6500,
            'variable': 500,
            'gross_due': 7300,
            'day_rate': 243.33,
            'due_amount': 7000,
            'paid_amount': 0,
            'remaining': 7000,
            'payment_status': 'Unpaid',
            'penalty_total': 300,
            'penalty_days': 1.233,
            'penalties': [
              {
                'name': 'JPEN-00001',
                'penalty_date': '2026-09-03',
                'period_month': '2026-09',
                'unit': 'Money',
                'quantity': 0,
                'amount': 300,
                'equivalent_days': 1.233,
                'day_rate': 243.33,
                'reason': 'Broke two jars',
                'settled': false,
              }
            ],
            'advance_total': 500,
            'advances': [
              {
                'name': 'HR-EAD-2026-00004',
                'posting_date': '2026-09-04',
                'amount': 500,
                'outstanding': 500,
                'purpose': 'Family emergency',
                'status': 'Paid',
                'advance_account': 'Debtors - J',
              }
            ],
            'order_total': 184,
            'orders': [
              {
                'invoice': 'ACC-SINV-2026-18146',
                'posting_date': '2026-09-02',
                'customer': 'CUST-0042',
                'customer_name': 'Sara Ali (staff)',
                'grand_total': 184,
                'outstanding': 184,
                'status': 'Unpaid',
              }
            ],
            'deductions_total': 984,
            'settled_amount': 0,
            'net_payable': 6316,
            'off_payroll': false,
            'has_salary_slip': false,
            'can_pay': true,
            'payments': [],
          },
          // Nobody's payroll, but the company's money all the same: no salary
          // structure, an open advance, and therefore a row.
          {
            'employee': 'HR-EMP-00021',
            'employee_name': 'Kareem Mamdouh',
            'base': 0,
            'variable': 0,
            'gross_due': 0,
            'day_rate': 0,
            'due_amount': 0,
            'paid_amount': 0,
            'remaining': 0,
            'payment_status': 'Not Due',
            'advance_total': 5000,
            'advances': [
              {
                'name': 'HR-EAD-2026-00002',
                'posting_date': '2026-08-14',
                'amount': 5000,
                'outstanding': 5000,
                'status': 'Paid',
                'advance_account': 'Debtors - J',
              }
            ],
            'deductions_total': 5000,
            'net_payable': 0,
            'off_payroll': true,
            'has_salary_slip': false,
            'can_pay': false,
            'payments': [],
          },
        ],
        'missing': [
          {
            'employee': 'HR-EMP-00016',
            'employee_name': 'Omar Nabil',
            'designation': 'Driver',
            'department': 'Delivery',
          }
        ],
      },
      'payment_sources': [
        {
          'id': 'cash-main',
          'label': 'Main cash drawer',
          'label_ar': 'درج النقدية',
          'type': 'cash',
          'account': 'Cash - J',
          'balance': 32000,
        }
      ],
      'expense_accounts': [
        {'account': 'Rent - Factory - J', 'label': 'Rent - Factory'}
      ],
      'cost_centers': [
        {'name': 'Main - J', 'label': 'Main'}
      ],
      'categories': ['Rent', 'Utilities'],
      'frequencies': ['Monthly', 'Quarterly'],
      'gaps': [
        {'severity': 'warning', 'message': '1 employee has no salary structure'}
      ],
      'deductions': {
        'penalty_total': 300,
        'penalty_days': 1.233,
        'advance_total': 5500,
        'order_total': 184,
        'total': 5984,
        'net_payable': 102016,
        'advances_readable': true,
        'employee_orders_present': true,
        'penalty_units': ['Days', 'Half Days', 'Money'],
        'days_per_month': 30,
      },
      'can_manage': true,
    };

void main() {
  group('MonthlyExpensesPayload.fromJson', () {
    test('parses the whole envelope', () {
      final payload = MonthlyExpensesPayload.fromJson(_payload());

      expect(payload.month, '2026-09');
      expect(payload.monthLabel, 'September 2026');
      expect(payload.company, 'JARZ');
      expect(payload.currency, 'EGP');
      expect(payload.canManage, isTrue);
      expect(payload.monthStart, DateTime(2026, 9, 1));
      expect(payload.categories, ['Rent', 'Utilities']);
      expect(payload.frequencies, ['Monthly', 'Quarterly']);
      expect(payload.gaps.single.message, contains('salary structure'));
    });

    test('summary carries every figure the header shows', () {
      final summary = MonthlyExpensesPayload.fromJson(_payload()).summary;
      expect(summary.due, 155000);
      expect(summary.paid, 47000);
      expect(summary.remaining, 108000);
      expect(summary.runRate, 155000);
      expect(summary.itemsTotal, 4);
      expect(summary.itemsUnpaid, 3);
    });

    test('an empty response degrades to zeros rather than throwing', () {
      final payload = MonthlyExpensesPayload.fromJson({});
      expect(payload.summary.remaining, 0);
      expect(payload.recurring, isEmpty);
      expect(payload.payroll.rows, isEmpty);
      expect(payload.canManage, isFalse);
    });
  });

  group('available_months', () {
    test('accepts bare month strings', () {
      final payload = MonthlyExpensesPayload.fromJson(_payload());
      expect(payload.availableMonths.map((m) => m.id).toList(),
          ['2026-07', '2026-08', '2026-09']);
      expect(payload.availableMonths.first.label, isNull);
    });

    test('accepts objects carrying their own label', () {
      final json = _payload()
        ..['available_months'] = [
          {'month': '2026-08', 'month_label': 'August 2026'},
          {'id': '2026-09', 'label': 'September 2026'},
        ];
      final payload = MonthlyExpensesPayload.fromJson(json);
      expect(payload.availableMonths.first.id, '2026-08');
      expect(payload.availableMonths.first.label, 'August 2026');
      expect(payload.availableMonths.last.label, 'September 2026');
    });
  });

  group('RecurringExpenseItem', () {
    test('parses the attribution flags honestly', () {
      final payload = MonthlyExpensesPayload.fromJson(_payload());
      final factory = payload.recurring.first;

      expect(factory.displayName, 'Factory rent');
      expect(factory.paymentStatus, 'Paid');
      // `inferred` says the paid figure leans on the ledger, and the unlinked
      // portion is what the card discloses.
      expect(factory.inferred, isTrue);
      expect(factory.paidLinked, 15000);
      expect(factory.paidUnlinked, 5000);
      expect(factory.sharedAccount, isFalse);
      expect(factory.canPay, isFalse);
      expect(factory.payments.single.journalEntry, 'ACC-JV-2026-00042');
    });

    test('reads shared_account and the lifecycle status', () {
      final dokki = MonthlyExpensesPayload.fromJson(_payload()).recurring[1];
      expect(dokki.sharedAccount, isTrue);
      expect(dokki.isPaused, isTrue);
      expect(dokki.isActive, isFalse);
      expect(dokki.paymentStatus, 'Not Due');
    });

    test('due_this_month accepts 1/0 as well as true/false', () {
      final payload = MonthlyExpensesPayload.fromJson(_payload());
      expect(payload.recurring.first.dueThisMonth, isTrue);
      expect(payload.recurring[1].dueThisMonth, isFalse);
    });

    test('falls back to the doc name when expense_name is blank', () {
      final item = RecurringExpenseItem.fromJson({'name': 'JRE-0007'});
      expect(item.displayName, 'JRE-0007');
      expect(item.accountDisplayLabel, '');
    });
  });

  group('recurringByCategory', () {
    test('groups items and orders the groups like by_category', () {
      final json = _payload();
      (json['recurring'] as List).add({
        'name': 'JRE-0003',
        'expense_name': 'Electricity',
        'category': 'Utilities',
        'status': 'Active',
        'amount': 3000,
        'due_amount': 3000,
        'remaining': 3000,
        'payment_status': 'Unpaid',
      });
      final payload = MonthlyExpensesPayload.fromJson(json);
      final grouped = payload.recurringByCategory;

      // Rent is ranked by `by_category`; Utilities is not, so it is appended
      // rather than dropped.
      expect(grouped.keys.toList(), ['Rent', 'Utilities']);
      expect(grouped['Rent']!.length, 2);
      expect(grouped['Utilities']!.single.displayName, 'Electricity');
    });

    test('categoryTotal finds the matching total', () {
      final payload = MonthlyExpensesPayload.fromJson(_payload());
      expect(payload.categoryTotal('Rent')?.due, 47000);
      expect(payload.categoryTotal('Nope'), isNull);
    });
  });

  group('PayrollBlock', () {
    test('keeps the gaps out of the rows', () {
      final payroll = MonthlyExpensesPayload.fromJson(_payload()).payroll;
      expect(payroll.configured, isTrue);
      expect(payroll.rows.length, 2);
      expect(payroll.rows.first.dueAmount, 7000);
      expect(payroll.rows.first.canPay, isTrue);
      // The employee without a structure is NOT a row — a zero row would read
      // as "nothing owed" when the truth is "we do not know".
      expect(payroll.missing.single.displayName, 'Omar Nabil');
      expect(payroll.employeesWithoutStructure, 1);
      expect(payroll.unattributedGl, 2500);
    });
  });

  group('MonthlyExpensePaymentSource', () {
    test('reads the contract field `type`', () {
      final source =
          MonthlyExpensesPayload.fromJson(_payload()).paymentSources.single;
      expect(source.type, 'cash');
      expect(source.account, 'Cash - J');
      expect(source.balance, 32000);
      expect(source.localizedLabel('en'), 'Main cash drawer');
      expect(source.localizedLabel('ar'), 'درج النقدية');
    });

    test('falls back to `category`, which is what the shared serializer emits',
        () {
      final source = MonthlyExpensePaymentSource.fromJson({
        'account': 'Bank - J',
        'label': 'Bank',
        'category': 'bank',
      });
      expect(source.type, 'bank');
      expect(source.id, 'Bank - J');
    });

    test('defaults to `account` when neither is sent', () {
      expect(MonthlyExpensePaymentSource.fromJson({}).type, 'account');
    });
  });

  group('RecurringExpenseDraft.toJson', () {
    test('omits name on a create and empty optionals throughout', () {
      final json = const RecurringExpenseDraft(
        expenseName: 'Nasr City rent',
        category: 'Rent',
        amount: 12000,
        frequency: 'Monthly',
        expenseAccount: 'Rent - Nasr City - J',
      ).toJson();

      expect(json.containsKey('name'), isFalse);
      expect(json['expense_name'], 'Nasr City rent');
      expect(json['amount'], 12000);
      expect(json.containsKey('cost_center'), isFalse);
      expect(json.containsKey('day_of_month'), isFalse);
    });

    test('carries name on an update', () {
      final json = const RecurringExpenseDraft(
        name: 'JRE-0001',
        expenseName: 'Factory rent',
        category: 'Rent',
        amount: 20000,
        frequency: 'Monthly',
        expenseAccount: 'Rent - Factory - J',
        dayOfMonth: 5,
        costCenter: 'Main - J',
        startDate: '2025-01-01',
      ).toJson();

      expect(json['name'], 'JRE-0001');
      expect(json['day_of_month'], 5);
      expect(json['cost_center'], 'Main - J');
      expect(json['start_date'], '2025-01-01');
    });
  });

  group('MonthlyExpenseGap', () {
    test('critical severities are recognised, messages without text dropped',
        () {
      final gaps = MonthlyExpenseGap.listFrom([
        {'severity': 'critical', 'message': 'Overpaid'},
        {'severity': 'info', 'message': 'Registry is empty'},
        {'severity': 'info', 'message': ''},
      ]);
      expect(gaps.length, 2);
      expect(gaps.first.isCritical, isTrue);
      expect(gaps.last.isCritical, isFalse);
    });

    test('INFO is told apart from a warning so the banner can stop being red',
        () {
      final gaps = MonthlyExpenseGap.listFrom([
        {
          'severity': 'INFO',
          'message': 'No order has ever been rung up as a staff order'
        },
        {'severity': 'warning', 'message': 'Advances could not be read'},
      ]);
      expect(gaps.first.isInfo, isTrue);
      expect(gaps.first.isCritical, isFalse);
      expect(gaps.last.isInfo, isFalse);
    });
  });

  group('deductions', () {
    test('the top-level block carries every figure and its vocabulary', () {
      final deductions = MonthlyExpensesPayload.fromJson(_payload()).deductions;
      expect(deductions.penaltyTotal, 300);
      expect(deductions.advanceTotal, 5500);
      expect(deductions.orderTotal, 184);
      expect(deductions.total, 5984);
      expect(deductions.netPayable, 102016);
      expect(deductions.advancesReadable, isTrue);
      expect(deductions.employeeOrdersPresent, isTrue);
      expect(deductions.penaltyUnits,
          [PenaltyUnit.days, PenaltyUnit.halfDays, PenaltyUnit.money]);
      expect(deductions.daysPerMonth, 30);
      expect(deductions.hasAny, isTrue);
    });

    test('an absent block is zeros, and advances are assumed readable', () {
      // A server build without the block was reading HRMS fine; defaulting to
      // "unreadable" would warn about a problem that does not exist.
      const empty = DeductionsSummary();
      expect(empty.advancesReadable, isTrue);
      expect(empty.hasAny, isFalse);
      expect(empty.penaltyUnits, PenaltyUnit.all);
      expect(empty.daysPerMonth, 30);
      expect(MonthlyExpensesPayload.fromJson({}).deductions.total, 0);
    });
  });

  group('SalaryRow deductions', () {
    test('reads the penalties, advances and orders on a row', () {
      final row = MonthlyExpensesPayload.fromJson(_payload()).payroll.rows.first;

      expect(row.grossDue, 7300);
      expect(row.dayRate, 243.33);
      // due = gross − penalty; the two are only equal when nothing was deducted.
      expect(row.dueAmount, 7000);
      expect(row.penaltyTotal, 300);
      expect(row.penalties.single.reason, 'Broke two jars');
      expect(row.penalties.single.settled, isFalse);
      expect(row.advances.single.name, 'HR-EAD-2026-00004');
      expect(row.advances.single.advanceAccount, 'Debtors - J');
      expect(row.orders.single.invoice, 'ACC-SINV-2026-18146');
      expect(row.orders.single.displayCustomer, 'Sara Ali (staff)');
      expect(row.deductionsTotal, 984);
      expect(row.netPayable, 6316);
      expect(row.hasDeductions, isTrue);
      expect(row.hasOpenBalances, isTrue);
      expect(row.offPayroll, isFalse);
    });

    test('an off-payroll row exists because of what is owed, not what is due',
        () {
      final row = MonthlyExpensesPayload.fromJson(_payload()).payroll.rows.last;

      expect(row.offPayroll, isTrue);
      expect(row.grossDue, 0);
      expect(row.dayRate, 0);
      expect(row.advanceTotal, 5000);
      expect(row.canPay, isFalse);
      // The whole point of the row: the advance is visible even though this
      // person has no salary structure at all.
      expect(row.hasDeductions, isTrue);
    });

    test('a row with nothing deducted stays the clean single line it was', () {
      final row = SalaryRow.fromJson({
        'employee': 'HR-EMP-00002',
        'employee_name': 'Mona',
        'base': 5000,
        'gross_due': 5000,
        'due_amount': 5000,
        'remaining': 5000,
        'payment_status': 'Unpaid',
        'can_pay': true,
      });
      expect(row.hasDeductions, isFalse);
      expect(row.hasOpenBalances, isFalse);
      expect(row.netPayable, 5000);
    });

    test('the derived figures fall back to their own definition, not to zero',
        () {
      // A server that has not shipped these fields yet must still render a
      // correct card: a zero `gross_due` would read as "earns nothing".
      final row = SalaryRow.fromJson({
        'employee': 'HR-EMP-00003',
        'due_amount': 9000,
        'paid_amount': 0,
        'remaining': 9000,
        'payment_status': 'Unpaid',
      });
      expect(row.grossDue, 9000);
      expect(row.deductionsTotal, 0);
      expect(row.netPayable, 9000);
    });

    test('net_payable never goes negative when it has to be derived', () {
      final row = SalaryRow.fromJson({
        'employee': 'HR-EMP-00004',
        'due_amount': 1000,
        'remaining': 1000,
        'advance_total': 4000,
        'payment_status': 'Unpaid',
      });
      // The employee owes more than the month pays; today's cash is zero, and
      // the rest stays open rather than turning into a negative payment.
      expect(row.netPayable, 0);
    });
  });

  group('penalty conversion', () {
    // The same two rules the DocType's `validate` applies, mirrored locally so
    // the sheet can show the equivalence before anything is sent.
    test('days and half-days price themselves off the day rate', () {
      expect(
        penaltyAmountFor(
            unit: PenaltyUnit.days, quantity: 2, amount: 0, dayRate: 300),
        600,
      );
      expect(
        penaltyAmountFor(
            unit: PenaltyUnit.halfDays, quantity: 3, amount: 0, dayRate: 300),
        450,
      );
      expect(
        penaltyDaysFor(
            unit: PenaltyUnit.halfDays, quantity: 3, amount: 0, dayRate: 300),
        1.5,
      );
    });

    test('money converts back to days, unrounded', () {
      expect(
        penaltyDaysFor(
            unit: PenaltyUnit.money, quantity: 0, amount: 600, dayRate: 400),
        1.5,
      );
      expect(
        penaltyAmountFor(
            unit: PenaltyUnit.money, quantity: 0, amount: 600, dayRate: 400),
        600,
      );
    });

    test('a day rate of 0 yields 0 days rather than infinity', () {
      // No salary structure: a day genuinely has no value for this employee,
      // which is why the sheet refuses Days for them.
      expect(
        penaltyDaysFor(
            unit: PenaltyUnit.money, quantity: 0, amount: 600, dayRate: 0),
        0,
      );
      expect(
        penaltyAmountFor(
            unit: PenaltyUnit.days, quantity: 2, amount: 0, dayRate: 0),
        0,
      );
    });
  });

  group('settlement payloads', () {
    test('use the field names the endpoint declares', () {
      expect(const AdvanceSettlement(name: 'HR-EAD-2026-00004', amount: 500)
          .toJson(), {'name': 'HR-EAD-2026-00004', 'amount': 500.0});
      expect(
          const OrderSettlement(invoice: 'ACC-SINV-2026-18146', amount: 184)
              .toJson(),
          {'invoice': 'ACC-SINV-2026-18146', 'amount': 184.0});
    });
  });

  group('left staff and salary month', () {
    test('parses left, relieving_date and current_month', () {
      final payload = MonthlyExpensesPayload.fromJson({
        ..._payload(),
        'month': '2026-10',
        'current_month': '2026-11',
        'payroll': {
          'configured': 1,
          'rows': [
            {
              'employee': 'HR-EMP-00001',
              'employee_name': 'Active',
              'remaining': 9000,
              'left': false,
              'relieving_date': null,
            },
            {
              'employee': 'HR-EMP-00009',
              'employee_name': 'Gone',
              'off_payroll': 1,
              'left': 1,
              'relieving_date': '2026-10-25',
              'advance_total': 500,
            },
          ],
        },
      });

      expect(payload.month, '2026-10');
      expect(payload.currentMonth, '2026-11');
      final rows = payload.payroll.rows;
      expect(rows.first.left, isFalse);
      expect(rows.first.relievingDate, isNull);
      expect(rows.last.left, isTrue);
      expect(rows.last.relievingDate, DateTime(2026, 10, 25));
      expect(payload.payroll.activeRows.map((r) => r.employee),
          ['HR-EMP-00001']);
      expect(payload.payroll.leftRows.map((r) => r.employee),
          ['HR-EMP-00009']);
    });

    test('an older server without the new keys still parses', () {
      final payload = MonthlyExpensesPayload.fromJson(_payload());
      expect(payload.currentMonth, '');
      for (final row in payload.payroll.rows) {
        expect(row.left, isFalse);
        expect(row.relievingDate, isNull);
      }
      expect(payload.payroll.leftRows, isEmpty);
      expect(payload.payroll.activeRows.length, payload.payroll.rows.length);
    });

    test('an empty or junk relieving_date reads as null', () {
      for (final value in ['', '   ', 'not-a-date']) {
        final row = SalaryRow.fromJson({
          'employee': 'HR-EMP-00009',
          'left': true,
          'relieving_date': value,
        });
        expect(row.relievingDate, isNull, reason: 'value "$value"');
        expect(row.left, isTrue);
      }
    });
  });
}
