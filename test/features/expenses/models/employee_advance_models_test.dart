import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/features/expenses/models/employee_advance_models.dart';

void main() {
  // ── AdvanceEmployeeOption ─────────────────────────────────────────────

  group('AdvanceEmployeeOption.fromJson', () {
    test('parses all fields', () {
      final option = AdvanceEmployeeOption.fromJson({
        'employee': 'HR-EMP-0001',
        'employee_name': 'Mona Adel',
        'branch': 'Nasr City',
        'department': 'Operations',
        'designation': 'Barista',
        'user': 'mona@example.com',
      });
      expect(option.employee, 'HR-EMP-0001');
      expect(option.employeeName, 'Mona Adel');
      expect(option.branch, 'Nasr City');
      expect(option.subtitle, 'Nasr City • Barista • Operations');
    });

    test('falls back to the id when employee_name is missing', () {
      final option = AdvanceEmployeeOption.fromJson({'employee': 'HR-EMP-0002'});
      expect(option.employeeName, 'HR-EMP-0002');
      expect(option.branch, isNull);
      expect(option.subtitle, '');
    });

    test('matches on every searchable field, case-insensitively', () {
      final option = AdvanceEmployeeOption.fromJson({
        'employee': 'HR-EMP-0003',
        'employee_name': 'Mona Adel',
        'branch': 'Nasr City',
        'department': 'Operations',
      });
      expect(option.matches(''), isTrue);
      expect(option.matches('mona'), isTrue);
      expect(option.matches('NASR'), isTrue);
      expect(option.matches('operations'), isTrue);
      expect(option.matches('emp-0003'), isTrue);
      expect(option.matches('dokki'), isFalse);
    });
  });

  // ── EmployeeAdvance ───────────────────────────────────────────────────

  group('EmployeeAdvance.fromJson', () {
    Map<String, dynamic> base() => {
          'name': 'HR-EAD-2026-00001',
          'employee': 'HR-EMP-0001',
          'employee_name': 'Mona Adel',
          'branch': 'Nasr City',
          'pos_profile': 'Nasr City POS',
          'posting_date': '2026-08-28',
          'currency': 'EGP',
          'amount': 1500,
          'paid_amount': '1500',
          'claimed_amount': 0,
          'return_amount': 0,
          'balance': 1500.0,
          'purpose': 'Fuel for the delivery bike',
          'status': 'Paid',
          'docstatus': 1,
          'paying_account': 'Cash - JZ',
          'payment_label': 'Cash',
          'payment_label_en': 'Cash',
          'payment_label_ar': 'نقدي',
          'requested_by': 'lm@example.com',
          'requested_by_name': 'Line Manager',
          'approved_by': 'mgr@example.com',
          'approved_on': '2026-08-28 11:30:00',
          'payment_entry': 'ACC-PAY-2026-00042',
          'company': 'Jarz',
          'creation': '2026-08-28 10:00:00',
          'modified': '2026-08-28 11:30:00',
        };

    test('parses the full contract payload', () {
      final advance = EmployeeAdvance.fromJson(base());
      expect(advance.name, 'HR-EAD-2026-00001');
      expect(advance.employeeName, 'Mona Adel');
      expect(advance.amount, 1500);
      expect(advance.paidAmount, 1500); // numeric string
      expect(advance.balance, 1500.0);
      expect(advance.postingDate, DateTime(2026, 8, 28));
      expect(advance.paymentEntry, 'ACC-PAY-2026-00042');
      expect(advance.approvedOn, isNotNull);
    });

    test('localizes the payment label triple', () {
      final advance = EmployeeAdvance.fromJson(base());
      expect(advance.localizedPaymentLabel('en'), 'Cash');
      expect(advance.localizedPaymentLabel('ar'), 'نقدي');
    });

    test('Draft at docstatus 0 is what awaits manager approval', () {
      final advance = EmployeeAdvance.fromJson(
        base()..addAll({'status': 'Draft', 'docstatus': 0, 'paid_amount': 0}),
      );
      expect(advance.isPendingApproval, isTrue);
      expect(advance.isSubmitted, isFalse);
      expect(advance.isPaid, isFalse);
      expect(advance.isCancelled, isFalse);
    });

    test('a submitted advance is never pending approval', () {
      final advance = EmployeeAdvance.fromJson(base());
      expect(advance.isPendingApproval, isFalse);
      expect(advance.isSubmitted, isTrue);
      expect(advance.isPaid, isTrue);
    });

    test('cancelled is detected from docstatus or status', () {
      expect(
        EmployeeAdvance.fromJson(base()..['docstatus'] = 2).isCancelled,
        isTrue,
      );
      expect(
        EmployeeAdvance.fromJson(base()..['status'] = 'Cancelled').isCancelled,
        isTrue,
      );
    });

    test('every HRMS settlement status counts as paid-out', () {
      for (final status in const [
        'Paid',
        'Claimed',
        'Returned',
        'Partly Claimed and Returned',
      ]) {
        expect(
          EmployeeAdvance.fromJson(base()..['status'] = status).isPaid,
          isTrue,
          reason: status,
        );
      }
      for (final status in const ['Draft', 'Unpaid', 'Partially Paid']) {
        expect(
          EmployeeAdvance.fromJson(base()..['status'] = status).isPaid,
          isFalse,
          reason: status,
        );
      }
    });

    test('tolerates a sparse payload', () {
      final advance = EmployeeAdvance.fromJson({'name': 'HR-EAD-X'});
      expect(advance.name, 'HR-EAD-X');
      expect(advance.employeeName, '');
      expect(advance.amount, 0);
      expect(advance.postingDate, isNull);
      expect(advance.paymentEntry, isNull);
      expect(advance.docstatus, 0);
    });

    test('empty strings become null, not empty labels', () {
      final advance = EmployeeAdvance.fromJson({
        'name': 'HR-EAD-Y',
        'branch': '   ',
        'payment_entry': '',
      });
      expect(advance.branch, isNull);
      expect(advance.paymentEntry, isNull);
    });
  });

  // ── EmployeeAdvanceSummary ────────────────────────────────────────────

  group('EmployeeAdvanceSummary.fromJson', () {
    test('parses the contract summary', () {
      final summary = EmployeeAdvanceSummary.fromJson({
        'total_amount': 4500,
        'pending_count': 2,
        'pending_amount': '1500.5',
        'approved_count': 3,
        'outstanding_amount': 800,
      });
      expect(summary.totalAmount, 4500);
      expect(summary.pendingCount, 2);
      expect(summary.pendingAmount, 1500.5);
      expect(summary.approvedCount, 3);
      expect(summary.outstandingAmount, 800);
    });

    test('null summary collapses to empty', () {
      expect(EmployeeAdvanceSummary.fromJson(null).totalAmount, 0);
      expect(EmployeeAdvanceSummary.fromJson(null).outstandingAmount, 0);
    });
  });

  // ── EmployeeAdvanceBootstrap ──────────────────────────────────────────

  group('EmployeeAdvanceBootstrap.fromJson', () {
    test('parses a populated bootstrap', () {
      final bootstrap = EmployeeAdvanceBootstrap.fromJson({
        'success': true,
        'hrms_available': true,
        'can_request': true,
        'can_approve': false,
        'company': 'Jarz',
        'currency': 'EGP',
        'current_month': '2026-08',
        'requested_month': '2026-08',
        'months': [
          {'id': '2026-08', 'label': 'August 2026'},
        ],
        'employees': [
          {'employee': 'HR-EMP-0001', 'employee_name': 'Mona Adel'},
        ],
        'payment_sources': [
          {
            'id': 'src-1',
            'account': 'Cash - JZ',
            'label': 'Cash',
            'category': 'cash',
            'balance': 9000,
          },
        ],
        'advances': [
          {'name': 'HR-EAD-1', 'amount': 500, 'status': 'Draft'},
        ],
        'summary': {'total_amount': 500, 'pending_count': 1},
        'applied_filters': {'month': '2026-08', 'status': 'Draft'},
      });

      expect(bootstrap.hrmsAvailable, isTrue);
      expect(bootstrap.canRequest, isTrue);
      expect(bootstrap.canApprove, isFalse);
      expect(bootstrap.currency, 'EGP');
      expect(bootstrap.months.single.label, 'August 2026');
      expect(bootstrap.employees.single.employeeName, 'Mona Adel');
      expect(bootstrap.paymentSources.single.account, 'Cash - JZ');
      expect(bootstrap.advances.single.name, 'HR-EAD-1');
      expect(bootstrap.summary.totalAmount, 500);
      expect(bootstrap.statusFilter, 'Draft');
    });

    test('hrms_available false is a normal payload carrying a notice', () {
      final bootstrap = EmployeeAdvanceBootstrap.fromJson({
        'success': true,
        'hrms_available': false,
        'can_request': false,
        'can_approve': false,
        'advances': [],
        'notice': 'HRMS is not installed on this site.',
      });
      expect(bootstrap.hrmsAvailable, isFalse);
      expect(bootstrap.notice, 'HRMS is not installed on this site.');
      expect(bootstrap.advances, isEmpty);
    });

    test('an absent hrms_available flag does not black out the feature', () {
      final bootstrap = EmployeeAdvanceBootstrap.fromJson({'success': true});
      expect(bootstrap.hrmsAvailable, isTrue);
      expect(bootstrap.summary.totalAmount, 0);
      expect(bootstrap.months, isEmpty);
      expect(bootstrap.statusFilter, isNull);
    });
  });

  // ── Salary month ──────────────────────────────────────────────────────

  group('salary month', () {
    test('an advance carries the salary it is deducted from', () {
      final advance = EmployeeAdvance.fromJson({
        'name': 'HR-EAD-2026-00010',
        'employee': 'HR-EMP-0001',
        'posting_date': '2026-10-07',
        'salary_month': '2026-09',
        'salary_month_explicit': true,
        'status': 'Draft',
      });
      expect(advance.salaryMonth, '2026-09');
      expect(advance.salaryMonthExplicit, isTrue);
      expect(advance.postingDate, DateTime(2026, 10, 7));
    });

    test('a legacy row is not marked explicit', () {
      final advance = EmployeeAdvance.fromJson({
        'name': 'HR-EAD-2026-00001',
        'salary_month': '2026-09',
      });
      expect(advance.salaryMonthExplicit, isFalse);
    });

    test('bootstrap reads the options and the suggestion', () {
      final bootstrap = EmployeeAdvanceBootstrap.fromJson({
        'salary_months': [
          {'id': '2026-10', 'label': 'October 2026'},
          {'id': '2026-09', 'label': 'September 2026'},
        ],
        'suggested_salary_month': '2026-09',
      });
      expect(bootstrap.salaryMonths.map((m) => m.id), ['2026-10', '2026-09']);
      expect(bootstrap.suggestedSalaryMonth, '2026-09');
    });

    test('an older backend yields no options, so the picker hides', () {
      final bootstrap = EmployeeAdvanceBootstrap.fromJson({'success': true});
      expect(bootstrap.salaryMonths, isEmpty);
      expect(bootstrap.suggestedSalaryMonth, isNull);
    });

    test('salaryMonthDate', () {
      expect(salaryMonthDate('2026-09'), DateTime(2026, 9, 1));
      expect(salaryMonthDate('Sept'), isNull);
      expect(salaryMonthDate(null), isNull);
    });
  });

  group('salary payments', () {
    Map<String, dynamic> payment() => {
          'name': 'JEXP-00149',
          'employee': 'HR-EMP-0001',
          'employee_name': 'Mona Adel',
          'branch': '',
          'posting_date': '2026-11-02',
          'salary_month': '2026-10',
          'salary_month_label': 'October 2026',
          'amount': 1960,
          'currency': 'EGP',
          'payment_label': 'Cash',
          'payment_label_en': 'Cash drawer',
          'payment_label_ar': 'الدرج',
          'paid_by': 'boss@example.com',
          'paid_by_name': 'Boss',
          'remarks': 'Oct salary',
        };

    test('parses visible bootstrap with payments and summary', () {
      final bootstrap = EmployeeAdvanceBootstrap.fromJson({
        'salary_payments_visible': true,
        'salary_payments': [payment()],
        'summary': {
          'total_amount': 100,
          'salary_paid_count': 3,
          'salary_paid_amount': 5880,
          'handed_out_amount': 5980,
        },
      });
      expect(bootstrap.salaryPaymentsVisible, isTrue);
      expect(bootstrap.salaryPayments, hasLength(1));
      final row = bootstrap.salaryPayments.single;
      expect(row.name, 'JEXP-00149');
      expect(row.employeeName, 'Mona Adel');
      expect(row.branch, isNull);
      expect(row.postingDate, DateTime(2026, 11, 2));
      expect(row.salaryMonth, '2026-10');
      expect(row.salaryMonthLabel, 'October 2026');
      expect(row.amount, 1960);
      expect(row.paidByName, 'Boss');
      expect(row.remarks, 'Oct salary');
      expect(row.localizedPaymentLabel('en'), 'Cash drawer');
      expect(row.localizedPaymentLabel('ar'), 'الدرج');
      expect(bootstrap.summary.salaryPaidCount, 3);
      expect(bootstrap.summary.salaryPaidAmount, 5880);
      expect(bootstrap.summary.handedOutAmount, 5980);
    });

    test('old backend omits everything: hidden, empty, zeros', () {
      final bootstrap = EmployeeAdvanceBootstrap.fromJson({'success': true});
      expect(bootstrap.salaryPaymentsVisible, isFalse);
      expect(bootstrap.salaryPayments, isEmpty);
      expect(EmployeeAdvanceSummary.empty.salaryPaidAmount, 0);
      expect(bootstrap.summary.handedOutAmount, 0);
    });

    test('visible=false and non-explicit values stay hidden', () {
      for (final v in [false, 0, null, 'true', '1']) {
        final bootstrap = EmployeeAdvanceBootstrap.fromJson({
          'salary_payments_visible': v,
          'salary_payments': <dynamic>[],
        });
        expect(bootstrap.salaryPaymentsVisible, isFalse, reason: '$v');
      }
      expect(
        EmployeeAdvanceBootstrap.fromJson({'salary_payments_visible': 1})
            .salaryPaymentsVisible,
        isTrue,
      );
    });

    test('payment falls back to employee id and tolerates missing fields', () {
      final row = AdvanceSalaryPayment.fromJson(
          {'employee': 'HR-EMP-0002', 'amount': '250'});
      expect(row.employeeName, 'HR-EMP-0002');
      expect(row.amount, 250);
      expect(row.postingDate, isNull);
      expect(row.salaryMonthLabel, isNull);
      expect(row.localizedPaymentLabel('en'), '');
    });
  });
}
