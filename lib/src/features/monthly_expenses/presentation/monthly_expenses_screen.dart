import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/localized_formatters.dart';
import '../../../core/localization/user_error_message.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/reason_prompt_dialog.dart';
import '../models/monthly_expense_models.dart';
import '../state/monthly_expenses_notifier.dart';
import 'widgets/employee_penalty_sheet.dart';
import 'widgets/left_staff_section.dart';
import 'widgets/monthly_expense_gaps_banner.dart';
import 'widgets/monthly_expense_pay_sheet.dart';
import 'widgets/monthly_expenses_summary_header.dart';
import 'widgets/recurring_expense_card.dart';
import 'widgets/recurring_expense_form_sheet.dart';
import 'widgets/salary_row_card.dart';

/// The company's monthly bill: what is due, what has been paid, and what
/// REMAINS — for the recurring expense registry and for payroll, one month at a
/// time.
///
/// Route `/monthly-expenses`. The drawer entry is gated on
/// `canAccessMonthlyExpensesProvider`, which mirrors the backend gate on these
/// endpoints exactly; the route itself is reachable by URL, so the screen must
/// still survive a "Not permitted" answer, which it does by showing the error
/// and an empty month rather than crashing.
class MonthlyExpensesScreen extends ConsumerStatefulWidget {
  const MonthlyExpensesScreen({super.key});

  @override
  ConsumerState<MonthlyExpensesScreen> createState() =>
      _MonthlyExpensesScreenState();
}

class _MonthlyExpensesScreenState extends ConsumerState<MonthlyExpensesScreen> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final ProviderSubscription<MonthlyExpensesState> _errorListener;

  @override
  void initState() {
    super.initState();

    _errorListener = ref.listenManual<MonthlyExpensesState>(
      monthlyExpensesNotifierProvider,
      (previous, next) {
        final error = next.error;
        if (error == null || error.isEmpty) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final messenger = _messengerKey.currentState;
          if (messenger == null) return;
          messenger.showSnackBar(
            SnackBar(content: Text(context.userErrorMessage(error))),
          );
          ref.read(monthlyExpensesNotifierProvider.notifier).clearError();
        });
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(monthlyExpensesNotifierProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _errorListener.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(monthlyExpensesNotifierProvider);
    final notifier = ref.read(monthlyExpensesNotifierProvider.notifier);
    final payload = state.payload;
    final busy = state.isLoading && !state.initialized;

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Text(l10n.monthlyExpensesTitle),
          actions: [
            IconButton(
              tooltip: l10n.monthlyExpensesRefreshTooltip,
              onPressed: state.isLoading ? null : notifier.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: payload.canManage
            ? FloatingActionButton.extended(
                onPressed: state.isSubmitting
                    ? null
                    : () => _openForm(context, state, null),
                icon: const Icon(Icons.add),
                label: Text(l10n.monthlyExpensesAddAction),
              )
            : null,
        body: SafeArea(
          child: busy
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: notifier.refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      _MonthSelector(
                        state: state,
                        onPrevious: notifier.goToPreviousMonth,
                        onNext: notifier.goToNextMonth,
                        onChanged: notifier.setMonth,
                      ),
                      const SizedBox(height: 12),
                      if (payload.gaps.isNotEmpty) ...[
                        MonthlyExpenseGapsBanner(gaps: payload.gaps),
                        const SizedBox(height: 12),
                      ],
                      MonthlyExpensesSummaryHeader(
                        summary: payload.summary,
                        currency: payload.currency,
                      ),
                      if (!payload.canManage) ...[
                        const SizedBox(height: 12),
                        _Notice(
                          icon: Icons.lock_outline,
                          text: l10n.monthlyExpensesReadOnlyNotice,
                        ),
                      ],
                      const SizedBox(height: 20),
                      _SectionTitle(title: l10n.monthlyExpensesRecurringTitle),
                      const SizedBox(height: 8),
                      ..._buildRecurring(context, state),
                      const SizedBox(height: 20),
                      // Names the month the salaries are FOR and the month they
                      // are paid in. Salaries go out around the 10th for the
                      // previous month, and a heading that said only the board
                      // month let September be paid off the October board.
                      _SectionTitle(
                        title: monthlyExpenseSalariesHeading(
                          context,
                          _boardMonth(state),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._buildSalaries(context, state),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ── Recurring ───────────────────────────────────────────────────────

  List<Widget> _buildRecurring(
    BuildContext context,
    MonthlyExpensesState state,
  ) {
    final l10n = context.l10n;
    final payload = state.payload;
    if (payload.recurring.isEmpty) {
      return [_EmptyBlock(text: l10n.monthlyExpensesRecurringEmpty)];
    }

    final widgets = <Widget>[];
    payload.recurringByCategory.forEach((category, items) {
      final total = payload.categoryTotal(category);
      widgets.add(
        _CategoryHeader(
          category: category.isEmpty
              ? l10n.monthlyExpensesCategoryUncategorised
              : category,
          subtitle: total == null
              ? null
              : l10n.monthlyExpensesCategorySubtotal(
                  formatCurrency(context, total.remaining,
                      currencyCode: payload.currency),
                  formatCurrency(context, total.due,
                      currencyCode: payload.currency),
                ),
        ),
      );
      for (final item in items) {
        widgets.add(
          RecurringExpenseCard(
            item: item,
            currency: payload.currency,
            canManage: payload.canManage,
            isBusy: state.isSubmitting,
            onPay: () => _payRecurring(context, state, item),
            onMenuAction: (action) => _handleMenuAction(context, state, item, action),
            // Null hides the cancel affordance. Reversing a payment is gated
            // server-side on a narrower role set than reading this screen, so
            // the server tells us rather than the client guessing.
            onCancelPayment: payload.canCancelPayments
                ? (payment) => _cancelPayment(context, payment,
                    currency: payload.currency)
                : null,
          ),
        );
      }
    });
    return widgets;
  }

  Future<void> _payRecurring(
    BuildContext context,
    MonthlyExpensesState state,
    RecurringExpenseItem item,
  ) async {
    final l10n = context.l10n;
    final notifier = ref.read(monthlyExpensesNotifierProvider.notifier);
    final payload = state.payload;

    final paid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => MonthlyExpensePaySheet(
        title: ctx.l10n.monthlyExpensesPayTitle(item.displayName),
        periodLabel:
            ctx.l10n.monthlyExpensesPayPeriod(_monthLabel(ctx, state)),
        remaining: item.remaining,
        currency: payload.currency,
        paymentSources: payload.paymentSources,
        defaultPayingAccount: item.defaultPayingAccount,
        onSubmit: ({
          required double amount,
          required String payingAccount,
          required String paymentDate,
          String? remarks,
          bool allowOverpay = false,
          // A registry item owes nobody anything, so the settlement arguments
          // arrive empty and are dropped here rather than being sent as empty
          // lists the endpoint has no field for.
          List<AdvanceSettlement> settleAdvances = const [],
          List<OrderSettlement> settleOrders = const [],
        }) =>
            notifier.payRecurringExpense(
          recurringExpense: item.name,
          amount: amount,
          payingAccount: payingAccount,
          paymentDate: paymentDate,
          remarks: remarks,
          allowOverpay: allowOverpay,
        ),
      ),
    );

    if (paid == true && mounted) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(l10n.monthlyExpensesPaymentRecorded)),
      );
    }
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    MonthlyExpensesState state,
    RecurringExpenseItem item,
    RecurringExpenseMenuAction action,
  ) async {
    final statusUpdated = context.l10n.monthlyExpensesStatusUpdated;
    final notifier = ref.read(monthlyExpensesNotifierProvider.notifier);

    switch (action) {
      case RecurringExpenseMenuAction.edit:
        await _openForm(context, state, item);
        return;
      case RecurringExpenseMenuAction.pause:
        await _applyStatus(item, RecurringExpenseLifecycle.paused, notifier,
            statusUpdated);
        return;
      case RecurringExpenseMenuAction.resume:
        await _applyStatus(item, RecurringExpenseLifecycle.active, notifier,
            statusUpdated);
        return;
      case RecurringExpenseMenuAction.end:
        // Ending is the one irreversible-looking option here, so it is
        // confirmed and the dialog says plainly that past payments survive.
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(ctx.l10n.monthlyExpensesEndTitle(item.displayName)),
            content: Text(ctx.l10n.monthlyExpensesEndBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(ctx.l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(ctx.l10n.monthlyExpensesEndConfirm),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await _applyStatus(item, RecurringExpenseLifecycle.ended, notifier,
            statusUpdated);
        return;
    }
  }

  /// [successLabel] is resolved from the l10n BEFORE the await: reading it off
  /// a context after an async gap is how a screen ends up using a disposed
  /// element, and the analyzer flags exactly that.
  Future<void> _applyStatus(
    RecurringExpenseItem item,
    String status,
    MonthlyExpensesNotifier notifier,
    String successLabel,
  ) async {
    final result = await notifier.setStatus(name: item.name, status: status);
    if (!mounted || !result.success) return;
    _messengerKey.currentState
        ?.showSnackBar(SnackBar(content: Text(successLabel)));
  }

  Future<void> _openForm(
    BuildContext context,
    MonthlyExpensesState state,
    RecurringExpenseItem? item,
  ) async {
    final l10n = context.l10n;
    final notifier = ref.read(monthlyExpensesNotifierProvider.notifier);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => RecurringExpenseFormSheet(
        payload: state.payload,
        item: item,
        onSubmit: notifier.saveRecurringExpense,
      ),
    );

    if (saved == true && mounted) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(l10n.monthlyExpensesSaved)),
      );
    }
  }

  // ── Salaries ────────────────────────────────────────────────────────

  List<Widget> _buildSalaries(
    BuildContext context,
    MonthlyExpensesState state,
  ) {
    final l10n = context.l10n;
    final payload = state.payload;
    final payroll = payload.payroll;
    final widgets = <Widget>[];

    if (!payroll.configured) {
      widgets.add(
        _Notice(
          icon: Icons.info_outline,
          text: l10n.monthlyExpensesPayrollNotConfigured,
        ),
      );
    }

    // The two payroll caveats are rendered as caveats, never as rows: an
    // employee with no salary structure has an UNKNOWN salary, and salary GL
    // that matches no employee belongs to no employee. A zero row for either
    // would read as "nothing owed", which is a different claim entirely.
    if (payroll.employeesWithoutStructure > 0) {
      widgets.add(
        _Notice(
          icon: Icons.person_off_outlined,
          text: l10n.monthlyExpensesMissingStructureTitle(
            payroll.employeesWithoutStructure,
          ),
          detail: [
            l10n.monthlyExpensesMissingStructureBody,
            if (payroll.missing.isNotEmpty)
              // A neutral separator rather than a comma: the Arabic list
              // separator is a different character, and hard-coding either one
              // is wrong in the other locale.
              payroll.missing.map((e) => e.displayName).join(' • '),
          ].join('\n'),
        ),
      );
    }

    if (payroll.unattributedGl.abs() > 0.005) {
      widgets.add(
        _Notice(
          icon: Icons.help_outline,
          text: l10n.monthlyExpensesUnattributedGl(
            formatCurrency(context, payroll.unattributedGl,
                currencyCode: payload.currency),
          ),
        ),
      );
    }

    if (payroll.rows.isEmpty) {
      widgets.add(_EmptyBlock(text: l10n.monthlyExpensesSalariesEmpty));
      return widgets;
    }

    // People who have left are not part of this month's payroll; they are
    // listed only because they still owe money, so they go to a collapsed
    // section at the end instead of sitting among the salaries.
    final activeRows = payroll.activeRows;
    final leftRows = payroll.leftRows;

    Widget card(SalaryRow row) => SalaryRowCard(
          row: row,
          currency: payload.currency,
          isBusy: state.isSubmitting,
          onPay: () => _paySalary(context, state, row),
          // See the recurring card above: cancel is gated by the server.
          onCancelPayment: payload.canCancelPayments
              ? (payment) =>
                  _cancelPayment(context, payment, currency: payload.currency)
              : null,
          onAddPenalty:
              payload.canManage ? () => _addPenalty(context, state, row) : null,
          // Cancelling a penalty takes money back OUT of a deduction, so it is
          // gated on the same narrower role set as reversing a payment rather
          // than on `can_manage`.
          onCancelPenalty: payload.canCancelPayments
              ? (penalty) => _cancelPenalty(context, penalty,
                  currency: payload.currency)
              : null,
        );

    // What the company will NOT be handing over, stated once above the rows.
    // Only when there is something to state: on a month with no advances, no
    // penalties and no staff orders this line would be three zeros.
    if (payload.deductions.hasAny) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.monthlyExpensesDeductionsSummary(
              formatCurrency(context, payload.deductions.total,
                  currencyCode: payload.currency),
              formatCurrency(context, payload.deductions.netPayable,
                  currencyCode: payload.currency),
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    widgets.add(const SizedBox(height: 8));
    if (activeRows.isEmpty) {
      widgets.add(_EmptyBlock(text: l10n.monthlyExpensesSalariesEmpty));
    }
    for (final row in activeRows) {
      widgets.add(card(row));
    }
    if (leftRows.isNotEmpty) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(LeftStaffSection(rows: leftRows, cardBuilder: card));
    }
    return widgets;
  }

  // ── Penalties ───────────────────────────────────────────────────────

  Future<void> _addPenalty(
    BuildContext context,
    MonthlyExpensesState state,
    SalaryRow row,
  ) async {
    final l10n = context.l10n;
    final notifier = ref.read(monthlyExpensesNotifierProvider.notifier);
    final payload = state.payload;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => EmployeePenaltySheet(
        row: row,
        currency: payload.currency,
        periodLabel:
            ctx.l10n.monthlyExpensesPayPeriod(_monthLabel(ctx, state)),
        penaltyUnits: payload.deductions.penaltyUnits,
        daysPerMonth: payload.deductions.daysPerMonth,
        onSubmit: ({
          required PenaltyDraft draft,
          bool allowOverpay = false,
        }) =>
            notifier.addPenalty(draft: draft, allowOverpay: allowOverpay),
      ),
    );

    if (saved == true && mounted) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(l10n.monthlyExpensesPenaltyRecorded)),
      );
    }
  }

  Future<void> _cancelPenalty(
    BuildContext context,
    PenaltyEntry penalty, {
    required String currency,
  }) async {
    final l10n = context.l10n;
    final notifier = ref.read(monthlyExpensesNotifierProvider.notifier);

    final reason = await promptForReason(
      context,
      title: l10n.monthlyExpensesPenaltyCancelTitle,
      message: l10n.monthlyExpensesPenaltyCancelBody(
        formatCurrency(context, penalty.amount, currencyCode: currency),
      ),
      hint: l10n.monthlyExpensesPenaltyCancelHint,
      confirmLabel: l10n.monthlyExpensesPenaltyCancelConfirm,
    );
    if (reason == null || reason.isEmpty) return;

    final result =
        await notifier.cancelPenalty(name: penalty.name, reason: reason);
    if (!mounted || !result.success) return;
    _messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(l10n.monthlyExpensesPenaltyCancelled)),
    );
  }

  Future<void> _paySalary(
    BuildContext context,
    MonthlyExpensesState state,
    SalaryRow row,
  ) async {
    final l10n = context.l10n;
    final notifier = ref.read(monthlyExpensesNotifierProvider.notifier);
    final payload = state.payload;

    final paid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => MonthlyExpensePaySheet(
        title: ctx.l10n.monthlyExpensesPayTitle(row.displayName),
        // "Salary for October 2026": the month this money is FOR, which is
        // routinely not the month it is paid in.
        periodLabel: ctx.l10n.monthlyExpensesPaySalaryPeriod(
          monthlyExpenseMonthLabel(ctx, _boardMonth(state)),
        ),
        remaining: row.remaining,
        // The prefill is the NET: an advance the employee is already holding
        // must not be handed to them a second time in cash. With open balances
        // the sheet ticks those advances/orders itself and derives the cash
        // from the ticks, so the net and the settlements always go together.
        // The hint above it still shows `remaining`, so the month's obligation
        // and today's cash stay two visibly different numbers.
        suggestedAmount: row.netPayable,
        currency: payload.currency,
        paymentSources: payload.paymentSources,
        advances: row.advances,
        orders: row.orders,
        onSubmit: ({
          required double amount,
          required String payingAccount,
          required String paymentDate,
          String? remarks,
          bool allowOverpay = false,
          List<AdvanceSettlement> settleAdvances = const [],
          List<OrderSettlement> settleOrders = const [],
        }) =>
            notifier.paySalary(
          employee: row.employee,
          amount: amount,
          payingAccount: payingAccount,
          paymentDate: paymentDate,
          remarks: remarks,
          allowOverpay: allowOverpay,
          settleAdvances: settleAdvances,
          settleOrders: settleOrders,
        ),
      ),
    );

    if (paid == true && mounted) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(l10n.monthlyExpensesPaymentRecorded)),
      );
    }
  }

  // ── Cancel a payment ────────────────────────────────────────────────

  Future<void> _cancelPayment(
    BuildContext context,
    MonthlyExpensePayment payment, {
    required String currency,
  }) async {
    final l10n = context.l10n;
    final notifier = ref.read(monthlyExpensesNotifierProvider.notifier);

    final reason = await promptForReason(
      context,
      title: l10n.monthlyExpensesPaymentCancelTitle,
      message: l10n.monthlyExpensesPaymentCancelBody(
        formatCurrency(context, payment.amount, currencyCode: currency),
        payment.sourceLabel,
      ),
      hint: l10n.monthlyExpensesPaymentCancelHint,
      confirmLabel: l10n.monthlyExpensesPaymentCancelConfirm,
    );
    if (reason == null || reason.isEmpty) return;

    final result =
        await notifier.cancelPayment(name: payment.name, reason: reason);
    if (!mounted || !result.success) return;
    _messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(l10n.monthlyExpensesPaymentCancelled)),
    );
  }

  String _monthLabel(BuildContext context, MonthlyExpensesState state) {
    final payload = state.payload;
    if (payload.monthLabel.isNotEmpty) return payload.monthLabel;
    return monthlyExpenseMonthLabel(context, state.selectedMonth);
  }

  /// The month the board shows, `YYYY-MM`: the server's answer when there is
  /// one (it picks the month on first load), else the selection.
  String _boardMonth(MonthlyExpensesState state) {
    final month = state.payload.month.trim();
    return month.isNotEmpty ? month : state.selectedMonth;
  }
}

/// "Salaries for October 2026 · paid in November" — the salary month and the
/// month it is paid in. The pay month carries its year only when it crosses
/// into a new one ("Salaries for December 2026 · paid in January 2027").
/// Falls back to the plain section title when the month is unknown.
String monthlyExpenseSalariesHeading(BuildContext context, String month) {
  final l10n = context.l10n;
  final salaryMonth = DateTime.tryParse('${month.trim()}-01');
  if (salaryMonth == null) return l10n.monthlyExpensesSalariesTitle;
  final payMonth = DateTime(salaryMonth.year, salaryMonth.month + 1);
  final payLabel = payMonth.year == salaryMonth.year
      ? DateFormat.MMMM(l10n.localeName).format(payMonth)
      : DateFormat.yMMMM(l10n.localeName).format(payMonth);
  return l10n.monthlyExpensesSalariesForMonth(
    monthlyExpenseMonthLabel(context, month.trim()),
    payLabel,
  );
}

/// `YYYY-MM` rendered in the user's locale. Falls back to the raw id so a month
/// the parser does not understand still names itself.
String monthlyExpenseMonthLabel(BuildContext context, String month) {
  if (month.isEmpty) return '';
  final parsed = DateTime.tryParse('$month-01');
  if (parsed == null) return month;
  return DateFormat.yMMMM(context.l10n.localeName).format(parsed);
}

/// Prev / next arrows plus the full `available_months` list.
///
/// The arrows step through the server's list rather than doing date arithmetic:
/// the window is the server's to define, and walking off its end would request
/// a month it does not answer for. That is why both arrows disable at the ends.
class _MonthSelector extends StatelessWidget {
  final MonthlyExpensesState state;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<String> onChanged;

  const _MonthSelector({
    required this.state,
    required this.onPrevious,
    required this.onNext,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final months = state.payload.availableMonths.isNotEmpty
        ? state.payload.availableMonths
        : [MonthlyExpenseMonthOption(id: state.selectedMonth)];
    final selected = months.any((m) => m.id == state.selectedMonth)
        ? state.selectedMonth
        : months.last.id;
    final busy = state.isLoading;

    return Row(
      children: [
        IconButton(
          tooltip: l10n.monthlyExpensesPreviousMonthTooltip,
          onPressed:
              (busy || !state.hasPreviousMonth) ? null : onPrevious,
          // Directional so the arrow points at the past in Arabic too.
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey<String>(selected),
            initialValue: selected,
            isExpanded: true,
            items: months
                .map(
                  (month) => DropdownMenuItem<String>(
                    value: month.id,
                    child: Text(
                      month.label ??
                          monthlyExpenseMonthLabel(context, month.id),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: busy
                ? null
                : (value) {
                    if (value != null) onChanged(value);
                  },
            decoration: InputDecoration(
              labelText: l10n.monthlyExpensesMonthLabel,
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.monthlyExpensesNextMonthTooltip,
          onPressed: (busy || !state.hasNextMonth) ? null : onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String category;
  final String? subtitle;

  const _CategoryHeader({required this.category, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? detail;

  const _Notice({required this.icon, required this.text, this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (detail != null && detail!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(detail!, style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final String text;

  const _EmptyBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
