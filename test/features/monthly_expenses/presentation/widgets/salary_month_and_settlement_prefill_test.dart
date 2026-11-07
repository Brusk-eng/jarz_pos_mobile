import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/monthly_expenses/models/monthly_expense_models.dart';
import 'package:jarz_pos/src/features/monthly_expenses/presentation/monthly_expenses_screen.dart';
import 'package:jarz_pos/src/features/monthly_expenses/presentation/widgets/left_staff_section.dart';
import 'package:jarz_pos/src/features/monthly_expenses/presentation/widgets/monthly_expense_pay_sheet.dart';
import 'package:jarz_pos/src/features/monthly_expenses/presentation/widgets/salary_row_card.dart';
import 'package:jarz_pos/src/features/monthly_expenses/state/monthly_expenses_notifier.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

const _sources = [
  MonthlyExpensePaymentSource(
    id: 'cash-main',
    account: 'Cash - J',
    label: 'Main cash drawer',
  ),
];

typedef _Sent = ({
  double amount,
  List<AdvanceSettlement> advances,
  List<OrderSettlement> orders,
});

MonthlyExpensePaySheet _sheet({
  required double remaining,
  double? suggestedAmount,
  List<AdvanceEntry> advances = const [],
  List<EmployeeOrderEntry> orders = const [],
  void Function(_Sent sent)? onSent,
}) {
  return MonthlyExpensePaySheet(
    title: 'Pay Belal Hassan',
    periodLabel: 'Salary for October 2026',
    remaining: remaining,
    suggestedAmount: suggestedAmount,
    currency: 'EGP',
    paymentSources: _sources,
    advances: advances,
    orders: orders,
    onSubmit: ({
      required double amount,
      required String payingAccount,
      required String paymentDate,
      String? remarks,
      bool allowOverpay = false,
      List<AdvanceSettlement> settleAdvances = const [],
      List<OrderSettlement> settleOrders = const [],
    }) async {
      onSent?.call(
          (amount: amount, advances: settleAdvances, orders: settleOrders));
      return const MonthlyExpenseActionResult.ok();
    },
  );
}

String _amountText(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText).first).controller.text;

List<bool?> _ticks(WidgetTester tester) => tester
    .widgetList<Checkbox>(find.byType(Checkbox))
    .map((box) => box.value)
    .toList();

SalaryRow _row({
  required String employee,
  required String name,
  bool left = false,
  DateTime? relievingDate,
  List<AdvanceEntry> advances = const [],
}) {
  return SalaryRow(
    employee: employee,
    employeeName: name,
    base: left ? 0 : 9000,
    variable: 0,
    dueAmount: left ? 0 : 9000,
    paidAmount: 0,
    remaining: left ? 0 : 9000,
    paymentStatus: 'Unpaid',
    hasSalarySlip: false,
    canPay: !left,
    payments: const [],
    advances: advances,
    advanceTotal:
        advances.fold<double>(0, (sum, advance) => sum + advance.outstanding),
    offPayroll: left,
    left: left,
    relievingDate: relievingDate,
  );
}

void main() {
  group('MonthlyExpensePaySheet pre-ticks what the net deducted', () {
    testWidgets('ticks advances then orders, never past remaining',
        (tester) async {
      await _pump(
        tester,
        _sheet(
          remaining: 1000,
          suggestedAmount: 0,
          advances: const [
            AdvanceEntry(name: 'ADV-A', amount: 600, outstanding: 600),
            // 600 + 600 > 1000: ticking this would trip the overpay guard.
            AdvanceEntry(name: 'ADV-B', amount: 600, outstanding: 600),
          ],
          orders: const [
            EmployeeOrderEntry(invoice: 'SINV-1', outstanding: 300),
          ],
        ),
      );

      expect(_ticks(tester), [true, false, true]);
      // remaining 1000 − settled (600 + 300) = 100 in cash.
      expect(_amountText(tester), '100.00');
    });

    testWidgets('ticks everything when it all fits and matches the net',
        (tester) async {
      await _pump(
        tester,
        _sheet(
          remaining: 9000,
          suggestedAmount: 8300,
          advances: const [
            AdvanceEntry(name: 'ADV-A', amount: 500, outstanding: 500),
          ],
          orders: const [
            EmployeeOrderEntry(invoice: 'SINV-1', outstanding: 200),
          ],
        ),
      );

      expect(_ticks(tester), [true, true]);
      expect(_amountText(tester), '8300.00');
    });

    testWidgets('a row with nothing left to pay pre-ticks nothing',
        (tester) async {
      await _pump(
        tester,
        _sheet(
          remaining: 0,
          suggestedAmount: 0,
          advances: const [
            AdvanceEntry(name: 'ADV-A', amount: 500, outstanding: 500),
          ],
        ),
      );

      expect(_ticks(tester), [false]);
      expect(_amountText(tester), '');
    });

    testWidgets('the amount follows the ticks until the operator types',
        (tester) async {
      await _pump(
        tester,
        _sheet(
          remaining: 1000,
          suggestedAmount: 100,
          advances: const [
            AdvanceEntry(name: 'ADV-A', amount: 600, outstanding: 600),
          ],
          orders: const [
            EmployeeOrderEntry(invoice: 'SINV-1', outstanding: 300),
          ],
        ),
      );
      expect(_amountText(tester), '100.00');

      // Untick the order: its 300 goes back into cash.
      await tester.tap(find.byType(Checkbox).last);
      await tester.pumpAndSettle();
      expect(_amountText(tester), '400.00');

      // Untick the advance too: the whole remaining is cash.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(_amountText(tester), '1000.00');

      // Once the operator types, a tick no longer overwrites their figure.
      await tester.enterText(find.byType(TextFormField).first, '50');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(_amountText(tester), '50');
    });

    testWidgets('submits the derived cash with the pre-ticked settlements',
        (tester) async {
      _Sent? sent;
      await _pump(
        tester,
        _sheet(
          remaining: 1000,
          suggestedAmount: 0,
          advances: const [
            AdvanceEntry(name: 'ADV-A', amount: 600, outstanding: 600),
            AdvanceEntry(name: 'ADV-B', amount: 600, outstanding: 600),
          ],
          orders: const [
            EmployeeOrderEntry(invoice: 'SINV-1', outstanding: 300),
          ],
          onSent: (value) => sent = value,
        ),
      );

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Pay'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Pay'));
      await tester.pumpAndSettle();

      expect(sent, isNotNull);
      expect(sent!.amount, 100);
      expect(sent!.advances.map((a) => a.name), ['ADV-A']);
      expect(sent!.orders.map((o) => o.invoice), ['SINV-1']);
      // Cash + settled never exceeds what is left of the month.
      final settled = sent!.advances.fold<double>(0, (s, a) => s + a.amount) +
          sent!.orders.fold<double>(0, (s, o) => s + o.amount);
      expect(sent!.amount + settled, lessThanOrEqualTo(1000.01));
    });

    testWidgets('a registry bill keeps its suggested amount', (tester) async {
      await _pump(tester, _sheet(remaining: 3000, suggestedAmount: 2500));
      expect(find.byType(Checkbox), findsNothing);
      expect(_amountText(tester), '2500.00');
    });

    testWidgets('a registry bill with no suggestion prefills remaining',
        (tester) async {
      await _pump(tester, _sheet(remaining: 3000));
      expect(_amountText(tester), '3000.00');
    });
  });

  group('salary month heading', () {
    Future<String> heading(WidgetTester tester, String month,
        {Locale locale = const Locale('en')}) async {
      late String out;
      await _pump(
        tester,
        Builder(builder: (context) {
          out = monthlyExpenseSalariesHeading(context, month);
          return Text(out);
        }),
        locale: locale,
      );
      return out;
    }

    testWidgets('names the salary month and the month it is paid in',
        (tester) async {
      expect(await heading(tester, '2026-10'),
          'Salaries for October 2026 · paid in November');
    });

    testWidgets('carries the year when payment crosses into a new one',
        (tester) async {
      expect(await heading(tester, '2026-12'),
          'Salaries for December 2026 · paid in January 2027');
    });

    testWidgets('renders in Arabic', (tester) async {
      final text = await heading(tester, '2026-10', locale: const Locale('ar'));
      expect(text, startsWith('مرتبات '));
      expect(text, contains('تُصرف في'));
      expect(text, contains('أكتوبر'));
      expect(text, contains('نوفمبر'));
    });

    testWidgets('falls back to the plain title for an unknown month',
        (tester) async {
      expect(await heading(tester, ''), 'Salaries');
    });
  });

  group('left staff section', () {
    final leftRow = _row(
      employee: 'HR-EMP-00009',
      name: 'Omar Left',
      left: true,
      relievingDate: DateTime(2026, 10, 25),
      advances: const [
        AdvanceEntry(name: 'ADV-L', amount: 500, outstanding: 500),
      ],
    );

    testWidgets('is collapsed by default and opens on tap', (tester) async {
      await _pump(
        tester,
        LeftStaffSection(
          rows: [leftRow],
          cardBuilder: (row) => SalaryRowCard(row: row, currency: 'EGP'),
        ),
      );

      expect(find.text('Left staff – still owe money (1)'), findsOneWidget);
      expect(find.text('Omar Left'), findsNothing);

      await tester.tap(find.text('Left staff – still owe money (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Omar Left'), findsOneWidget);
      expect(find.text('Left on 25 Oct 2026'), findsOneWidget);
    });

    testWidgets('renders nothing when nobody has left', (tester) async {
      await _pump(
        tester,
        LeftStaffSection(
          rows: const [],
          cardBuilder: (row) => SalaryRowCard(row: row, currency: 'EGP'),
        ),
      );
      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.textContaining('Left staff'), findsNothing);
    });

    testWidgets('titles itself in Arabic', (tester) async {
      await _pump(
        tester,
        LeftStaffSection(
          rows: [leftRow],
          cardBuilder: (row) => SalaryRowCard(row: row, currency: 'EGP'),
        ),
        locale: const Locale('ar'),
      );
      expect(find.text('موظفون تركوا العمل – عليهم مبالغ (1)'), findsOneWidget);
    });

    test('the payroll block splits left rows out of the salaries list', () {
      final block = PayrollBlock(rows: [
        _row(employee: 'E1', name: 'Active One'),
        leftRow,
        _row(employee: 'E2', name: 'Active Two'),
      ]);
      expect(block.activeRows.map((r) => r.employee), ['E1', 'E2']);
      expect(block.leftRows.map((r) => r.employee), ['HR-EMP-00009']);
    });

    testWidgets('an active row shows no left-on line', (tester) async {
      await _pump(
        tester,
        SalaryRowCard(
          row: _row(employee: 'E1', name: 'Active One'),
          currency: 'EGP',
        ),
      );
      expect(find.textContaining('Left on'), findsNothing);
    });
  });
}
