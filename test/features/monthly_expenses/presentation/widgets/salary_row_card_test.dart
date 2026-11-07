import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/monthly_expenses/models/monthly_expense_models.dart';
import 'package:jarz_pos/src/features/monthly_expenses/presentation/widgets/employee_penalty_sheet.dart';
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

SalaryRow _row({
  double penaltyTotal = 0,
  double penaltyDays = 0,
  double advanceTotal = 0,
  double orderTotal = 0,
  List<PenaltyEntry> penalties = const [],
  List<AdvanceEntry> advances = const [],
  List<EmployeeOrderEntry> orders = const [],
  bool offPayroll = false,
  double dayRate = 300,
  bool canPay = true,
}) {
  final deductions = penaltyTotal + advanceTotal + orderTotal;
  const gross = 9000.0;
  final due = gross - penaltyTotal;
  final net = due - advanceTotal - orderTotal;
  return SalaryRow(
    employee: 'HR-EMP-00001',
    employeeName: 'Belal Hassan',
    designation: 'Barista',
    base: gross,
    variable: 0,
    grossDue: offPayroll ? 0 : gross,
    dayRate: dayRate,
    dueAmount: offPayroll ? 0 : due,
    paidAmount: 0,
    remaining: offPayroll ? 0 : due,
    paymentStatus: 'Unpaid',
    penaltyTotal: penaltyTotal,
    penaltyDays: penaltyDays,
    penalties: penalties,
    advanceTotal: advanceTotal,
    advances: advances,
    orderTotal: orderTotal,
    orders: orders,
    deductionsTotal: deductions,
    netPayable: net > 0 ? net : 0,
    offPayroll: offPayroll,
    hasSalarySlip: false,
    canPay: canPay,
    payments: const [],
  );
}

void main() {
  group('SalaryRowCard deductions block', () {
    testWidgets('a clean row shows no deductions block at all', (tester) async {
      await _pump(tester, SalaryRowCard(row: _row(), currency: 'EGP'));

      // Sixteen people are on this screen. A row with nothing deducted must
      // read as the single clean line it has always been.
      expect(find.text('Net to pay'), findsNothing);
      expect(find.text('Gross'), findsNothing);
      expect(find.text('Advance'), findsNothing);
    });

    testWidgets('renders only the lines that are not zero', (tester) async {
      await _pump(
        tester,
        SalaryRowCard(row: _row(advanceTotal: 500), currency: 'EGP'),
      );

      expect(find.text('Gross'), findsOneWidget);
      expect(find.text('Advance'), findsOneWidget);
      expect(find.text('Net to pay'), findsOneWidget);
      // Nothing was penalised and no jars were taken, so those two lines are
      // absent rather than zero.
      expect(find.textContaining('Penalty'), findsNothing);
      expect(find.text('Jars'), findsNothing);
      expect(find.textContaining('8,500'), findsWidgets);
    });

    testWidgets('a penalty carries its day equivalent next to the money',
        (tester) async {
      await _pump(
        tester,
        SalaryRowCard(
          row: _row(penaltyTotal: 450, penaltyDays: 1.5),
          currency: 'EGP',
        ),
      );

      // 1.5 days, not "2": rounding it would misstate the penalty in the
      // direction nobody audits.
      expect(find.textContaining('1.5 days'), findsWidgets);
      expect(find.textContaining('− '), findsWidgets);
    });

    testWidgets('an advance is visible even for an off-payroll employee',
        (tester) async {
      await _pump(
        tester,
        SalaryRowCard(
          row: _row(
            offPayroll: true,
            dayRate: 0,
            canPay: false,
            advanceTotal: 5000,
            advances: [
              AdvanceEntry(
                name: 'HR-EAD-2026-00002',
                postingDate: DateTime(2026, 8, 14),
                amount: 5000,
                outstanding: 5000,
                status: 'Paid',
              ),
            ],
          ),
          currency: 'EGP',
        ),
      );

      // The whole request: money out to someone with no salary structure still
      // has to appear on this board.
      expect(find.text('Off payroll'), findsOneWidget);
      expect(find.text('Advance'), findsOneWidget);
      expect(find.textContaining('5,000'), findsWidgets);
    });
  });

  group('SalaryRowCard expanded detail', () {
    testWidgets('lists each penalty, advance and order with its date',
        (tester) async {
      await _pump(
        tester,
        SalaryRowCard(
          row: _row(
            penaltyTotal: 300,
            penaltyDays: 1,
            advanceTotal: 500,
            orderTotal: 184,
            penalties: [
              PenaltyEntry(
                name: 'JPEN-00001',
                penaltyDate: DateTime(2026, 9, 3),
                unit: PenaltyUnit.days,
                quantity: 1,
                amount: 300,
                equivalentDays: 1,
                dayRate: 300,
                reason: 'Left the branch unattended',
              ),
            ],
            advances: [
              AdvanceEntry(
                name: 'HR-EAD-2026-00004',
                postingDate: DateTime(2026, 9, 4),
                amount: 500,
                outstanding: 500,
                purpose: 'Family emergency',
              ),
            ],
            orders: [
              EmployeeOrderEntry(
                invoice: 'ACC-SINV-2026-18146',
                postingDate: DateTime(2026, 9, 2),
                grandTotal: 184,
                outstanding: 184,
              ),
            ],
          ),
          currency: 'EGP',
          onCancelPenalty: (_) {},
        ),
      );

      await tester.tap(find.text('Belal Hassan'));
      await tester.pumpAndSettle();

      expect(find.text('Penalties'), findsOneWidget);
      expect(find.textContaining('Left the branch unattended'), findsOneWidget);
      expect(find.text('Advances'), findsOneWidget);
      expect(find.textContaining('Family emergency'), findsOneWidget);
      expect(find.text('Staff orders'), findsOneWidget);
      expect(find.text('ACC-SINV-2026-18146'), findsOneWidget);
      expect(find.byTooltip('Cancel penalty'), findsOneWidget);
    });

    testWidgets('the penalty cancel action needs the server flag',
        (tester) async {
      await _pump(
        tester,
        SalaryRowCard(
          row: _row(
            penaltyTotal: 300,
            penalties: [
              const PenaltyEntry(name: 'JPEN-00001', amount: 300, reason: 'x'),
            ],
          ),
          currency: 'EGP',
          // No `can_cancel_payments`: reversing money is a narrower role set
          // than reading this screen, so the client never guesses.
        ),
      );

      await tester.tap(find.text('Belal Hassan'));
      await tester.pumpAndSettle();

      expect(find.text('Penalties'), findsOneWidget);
      expect(find.byTooltip('Cancel penalty'), findsNothing);
    });

    testWidgets('a settled penalty cannot be cancelled', (tester) async {
      await _pump(
        tester,
        SalaryRowCard(
          row: _row(
            penaltyTotal: 300,
            penalties: [
              const PenaltyEntry(
                name: 'JPEN-00001',
                amount: 300,
                reason: 'x',
                settled: true,
              ),
            ],
          ),
          currency: 'EGP',
          onCancelPenalty: (_) {},
        ),
      );

      await tester.tap(find.text('Belal Hassan'));
      await tester.pumpAndSettle();

      expect(find.text('Settled'), findsOneWidget);
      // The server refuses it, so the affordance is not offered.
      expect(find.byTooltip('Cancel penalty'), findsNothing);
    });

    testWidgets('Add penalty is offered to a manager, hidden otherwise',
        (tester) async {
      await _pump(
        tester,
        SalaryRowCard(row: _row(), currency: 'EGP', onAddPenalty: () {}),
      );
      await tester.tap(find.text('Belal Hassan'));
      await tester.pumpAndSettle();
      expect(find.text('Add penalty'), findsOneWidget);

      await _pump(tester, SalaryRowCard(row: _row(), currency: 'EGP'));
      await tester.tap(find.text('Belal Hassan'));
      await tester.pumpAndSettle();
      expect(find.text('Add penalty'), findsNothing);
    });

    testWidgets('renders in Arabic without falling back to English',
        (tester) async {
      await _pump(
        tester,
        SalaryRowCard(row: _row(advanceTotal: 500), currency: 'EGP'),
        locale: const Locale('ar'),
      );

      expect(find.text('سلفة'), findsOneWidget);
      expect(find.text('الصافي المستحق'), findsOneWidget);
      expect(find.text('Net to pay'), findsNothing);
    });
  });

  group('EmployeePenaltySheet equivalence', () {
    Widget sheet(SalaryRow row) => EmployeePenaltySheet(
          row: row,
          currency: 'EGP',
          periodLabel: 'For September 2026',
          onSubmit: ({
            required PenaltyDraft draft,
            bool allowOverpay = false,
          }) async =>
              const MonthlyExpenseActionResult.ok(),
        );

    testWidgets('days become money on every keystroke', (tester) async {
      await _pump(tester, sheet(_row()));

      await tester.enterText(find.byType(TextFormField).first, '2');
      await tester.pump();

      // 2 days at a 300 day rate is 600, and the manager sees it before
      // agreeing to anything.
      expect(find.textContaining('600'), findsWidgets);
    });

    testWidgets('money becomes days, unrounded', (tester) async {
      await _pump(tester, sheet(_row(dayRate: 400)));

      await tester.tap(find.text('Money'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '600');
      await tester.pump();

      // 600 against a 400 day rate is a day and a half, not one day and not two.
      expect(find.textContaining('1.5 days'), findsOneWidget);
    });

    testWidgets('an employee with no day rate is told to use money',
        (tester) async {
      await _pump(tester, sheet(_row(dayRate: 0, offPayroll: true)));

      expect(
        find.textContaining('no salary structure, so a day has no value'),
        findsOneWidget,
      );
      // Money is preselected, because it is the only unit that can be priced.
      expect(find.text('Penalty amount'), findsOneWidget);
      expect(find.text('Number of days'), findsNothing);
    });

    testWidgets('submit waits for a reason', (tester) async {
      await _pump(tester, sheet(_row()));

      await tester.enterText(find.byType(TextFormField).first, '2');
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Save penalty'))
            .onPressed,
        isNull,
        reason: 'a penalty with no stated reason is not defensible',
      );

      await tester.enterText(find.byType(TextFormField).at(1), 'No-show');
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Save penalty'))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('sends only the quantity for a Days penalty', (tester) async {
      PenaltyDraft? sent;
      await _pump(
        tester,
        EmployeePenaltySheet(
          row: _row(),
          currency: 'EGP',
          periodLabel: 'For September 2026',
          onSubmit: ({
            required PenaltyDraft draft,
            bool allowOverpay = false,
          }) async {
            sent = draft;
            return const MonthlyExpenseActionResult.ok();
          },
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, '1.5');
      await tester.enterText(find.byType(TextFormField).at(1), 'Late twice');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save penalty'));
      await tester.pumpAndSettle();

      expect(sent?.unit, PenaltyUnit.days);
      expect(sent?.quantity, 1.5);
      // The server owns the conversion and snapshots the rate it used, so the
      // client never sends a money figure it computed itself.
      expect(sent?.amount, isNull);
      expect(sent?.reason, 'Late twice');
      expect(sent?.penaltyDate, isNotNull);
    });
  });

  group('MonthlyExpensePaySheet settlements', () {
    testWidgets('cash and total discharged move apart as balances are ticked',
        (tester) async {
      await _pump(
        tester,
        MonthlyExpensePaySheet(
          title: 'Pay Belal Hassan',
          periodLabel: 'For September 2026',
          remaining: 9000,
          suggestedAmount: 8500,
          currency: 'EGP',
          paymentSources: const [
            MonthlyExpensePaymentSource(
              id: 'cash-main',
              account: 'Cash - J',
              label: 'Main cash drawer',
            ),
          ],
          advances: [
            AdvanceEntry(
              name: 'HR-EAD-2026-00004',
              postingDate: DateTime(2026, 9, 4),
              amount: 500,
              outstanding: 500,
            ),
          ],
          onSubmit: ({
            required double amount,
            required String payingAccount,
            required String paymentDate,
            String? remarks,
            bool allowOverpay = false,
            List<AdvanceSettlement> settleAdvances = const [],
            List<OrderSettlement> settleOrders = const [],
          }) async =>
              const MonthlyExpenseActionResult.ok(),
        ),
      );

      expect(find.text('Cash to hand over'), findsOneWidget);
      expect(find.text('Total discharged'), findsOneWidget);

      // The advance the net already deducted opens ticked: 8,500 cash and
      // 9,000 discharged. Two numbers, because collapsing them would hand the
      // employee money they already have.
      expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);
      expect(find.textContaining('8,500'), findsWidgets);
      expect(find.textContaining('9,000'), findsWidgets);

      // Unticking it puts the advance back in cash: the amount follows.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('8,500'), findsNothing);
      expect(
        tester.widget<EditableText>(find.byType(EditableText).first)
            .controller
            .text,
        '9000.00',
      );
    });

    testWidgets('sends the pre-ticked balance as a settlement',
        (tester) async {
      List<AdvanceSettlement> sent = const [];
      await _pump(
        tester,
        MonthlyExpensePaySheet(
          title: 'Pay Belal Hassan',
          periodLabel: 'For September 2026',
          remaining: 9000,
          suggestedAmount: 8500,
          currency: 'EGP',
          paymentSources: const [
            MonthlyExpensePaymentSource(
              id: 'cash-main',
              account: 'Cash - J',
              label: 'Main cash drawer',
            ),
          ],
          advances: const [
            AdvanceEntry(
              name: 'HR-EAD-2026-00004',
              amount: 500,
              outstanding: 500,
            ),
          ],
          onSubmit: ({
            required double amount,
            required String payingAccount,
            required String paymentDate,
            String? remarks,
            bool allowOverpay = false,
            List<AdvanceSettlement> settleAdvances = const [],
            List<OrderSettlement> settleOrders = const [],
          }) async {
            sent = settleAdvances;
            return const MonthlyExpenseActionResult.ok();
          },
        ),
      );

      // No tap: the advance the suggested net deducted is already ticked.
      // The sheet is taller than the test surface once the settlement block is
      // in it, so the submit button has to be scrolled to before it can be hit.
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Pay'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Pay'));
      await tester.pumpAndSettle();

      expect(sent.single.name, 'HR-EAD-2026-00004');
      expect(sent.single.amount, 500);
    });
  });
}
