import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/reason_prompt_dialog.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/user_error_message.dart';
import '../../../core/localization/localized_formatters.dart';
import '../../../core/network/user_service.dart';
import '../models/employee_advance_models.dart';
import '../models/expense_models.dart';
import '../state/employee_advances_notifier.dart';
import '../state/expenses_notifier.dart';
import 'widgets/advance_salary_payment_card.dart';
import 'widgets/employee_advance_card.dart';
import 'widgets/employee_advance_form_sheet.dart';
import 'widgets/expense_card.dart';
import 'widgets/expense_filters_bar.dart';
import 'widgets/expense_form_sheet.dart';
import 'widgets/expenses_summary_header.dart';

/// Two tabs over one screen:
///   * **Expenses** — the original screen body, moved verbatim into
///     [_ExpensesTab]; nothing about it changed.
///   * **Employee Advances** — cash advances a line manager requests for an
///     employee and a JARZ Manager approves.
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key, this.initialTab, this.initialMonth});

  /// `advances` opens on the Advances tab; anything else on Expenses.
  final String? initialTab;

  /// `YYYY-MM` to open that tab on instead of the current month. The side
  /// menu's approvals entry passes the oldest pending month, because a request
  /// filed last month is otherwise counted in the menu and absent here.
  final String? initialMonth;

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  static const _expensesTab = 0;
  static const _advancesTab = 1;

  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final TabController _tabController;
  late final ProviderSubscription<ExpensesState> _errorListener;
  late final ProviderSubscription<EmployeeAdvancesState> _advanceErrorListener;

  int _activeTab = _expensesTab;
  bool _advancesRequested = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _requestedTab(widget.initialTab),
    );
    _activeTab = _tabController.index;
    _tabController.addListener(_handleTabChange);

    _errorListener = ref.listenManual<ExpensesState>(
      expensesNotifierProvider,
      (previous, next) {
        final error = next.error;
        if (error != null && error.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final messenger = _messengerKey.currentState;
            if (messenger == null) return;
            messenger.showSnackBar(
              SnackBar(content: Text(context.userErrorMessage(error))),
            );
            ref.read(expensesNotifierProvider.notifier).clearError();
          });
        }
      },
    );

    // Held for the life of the screen, which also keeps the autoDispose
    // advances notifier alive while the user hops between tabs.
    _advanceErrorListener = ref.listenManual<EmployeeAdvancesState>(
      employeeAdvancesNotifierProvider,
      (previous, next) {
        final error = next.error;
        if (error != null && error.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final messenger = _messengerKey.currentState;
            if (messenger == null) return;
            messenger.showSnackBar(
              SnackBar(content: Text(context.userErrorMessage(error))),
            );
            ref.read(employeeAdvancesNotifierProvider.notifier).clearError();
          });
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_activeTab == _advancesTab) {
        // Opened straight on Advances: the tab listener never fires for the
        // initial index, so the first-visit load has to happen here.
        ref.read(expensesNotifierProvider.notifier).load();
        _loadAdvances(month: _requestedMonth(widget.initialMonth));
      } else {
        ref
            .read(expensesNotifierProvider.notifier)
            .load(month: _requestedMonth(widget.initialMonth));
      }
    });
  }

  static int _requestedTab(String? tab) =>
      tab == 'advances' ? _advancesTab : _expensesTab;

  static String? _requestedMonth(String? month) {
    final value = month?.trim() ?? '';
    return RegExp(r'^\d{4}-\d{2}$').hasMatch(value) ? value : null;
  }

  void _loadAdvances({String? month}) {
    _advancesRequested = true;
    ref.read(employeeAdvancesNotifierProvider.notifier).load(month: month);
  }

  /// The same screen re-targeted by a new link (the side menu while already on
  /// Expenses): GoRouter keeps this State, so initState does not run again.
  @override
  void didUpdateWidget(covariant ExpensesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab == widget.initialTab &&
        oldWidget.initialMonth == widget.initialMonth) {
      return;
    }
    final tab = _requestedTab(widget.initialTab);
    final month = _requestedMonth(widget.initialMonth);
    // Set before animateTo so the tab listener does not fire a second load.
    if (tab == _advancesTab) _advancesRequested = true;
    if (_tabController.index != tab) _tabController.animateTo(tab);
    // didUpdateWidget runs during build, and both loads set provider state
    // synchronously — so they wait for the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (tab == _advancesTab) {
        _loadAdvances(month: month);
      } else if (month != null) {
        ref.read(expensesNotifierProvider.notifier).load(month: month);
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _errorListener.close();
    _advanceErrorListener.close();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index != _activeTab) {
      setState(() => _activeTab = _tabController.index);
    }
    // Advances are fetched on first visit rather than on screen open: a user
    // who never opens the tab never pays for the extra bootstrap call.
    if (_tabController.index == _advancesTab && !_advancesRequested) {
      _advancesRequested = true;
      ref.read(employeeAdvancesNotifierProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expensesNotifierProvider);
    final advanceState = ref.watch(employeeAdvancesNotifierProvider);
    final canRequestAdvanceRole =
        ref.watch(canRequestEmployeeAdvanceProvider);
    final canApproveAdvanceRole =
        ref.watch(canApproveEmployeeAdvanceProvider);
    final l10n = context.l10n;

    final onAdvancesTab = _activeTab == _advancesTab;
    final isBusy = state.isLoading && !state.initialized;
    final advancesBusy = advanceState.isLoading && !advanceState.initialized;

    // Client gate hides the control; the bootstrap flag is the truth. Both must
    // agree before the request FAB appears.
    final mayRequestAdvance = canRequestAdvanceRole &&
        advanceState.canRequest &&
        advanceState.hrmsAvailable;
    final mayApproveAdvance =
        canApproveAdvanceRole && advanceState.canApprove;

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Text(l10n.expensesTitle),
          actions: [
            IconButton(
              tooltip: l10n.expensesRefreshTooltip,
              onPressed: onAdvancesTab
                  ? (advanceState.isLoading
                      ? null
                      : () => ref
                          .read(employeeAdvancesNotifierProvider.notifier)
                          .refresh())
                  : (state.isLoading
                      ? null
                      : () =>
                          ref.read(expensesNotifierProvider.notifier).refresh()),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.expensesAdvanceTabExpenses),
              Tab(text: l10n.expensesAdvanceTabAdvances),
            ],
          ),
        ),
        floatingActionButton: _buildFab(
          context: context,
          state: state,
          advanceState: advanceState,
          onAdvancesTab: onAdvancesTab,
          mayRequestAdvance: mayRequestAdvance,
        ),
        body: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              isBusy
                  ? const Center(child: CircularProgressIndicator())
                  : _ExpensesTab(state: state),
              advancesBusy
                  ? const Center(child: CircularProgressIndicator())
                  : _EmployeeAdvancesTab(
                      state: advanceState,
                      canApprove: mayApproveAdvance,
                      canRequest: mayRequestAdvance,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFab({
    required BuildContext context,
    required ExpensesState state,
    required EmployeeAdvancesState advanceState,
    required bool onAdvancesTab,
    required bool mayRequestAdvance,
  }) {
    final l10n = context.l10n;

    if (!onAdvancesTab) {
      return FloatingActionButton.extended(
        onPressed: state.isSubmitting
            ? null
            : () async {
                final record = await showModalBottomSheet<ExpenseRecord?>(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => ExpenseFormSheet(
                    isManager: state.isManager,
                    reasons: state.reasons,
                    paymentSources: state.paymentSources,
                    custodyAccount: state.custodyAccount,
                  ),
                );
                if (record != null && mounted) {
                  final label = record.isApproved
                      ? l10n.expensesRecorded
                      : l10n.expensesSubmitted;
                  _messengerKey.currentState
                      ?.showSnackBar(SnackBar(content: Text(label)));
                }
              },
        icon: const Icon(Icons.add),
        label: Text(l10n.expensesNewExpense),
      );
    }

    if (!mayRequestAdvance) return null;

    return FloatingActionButton.extended(
      onPressed: advanceState.isSubmitting
          ? null
          : () async {
              final advance = await showModalBottomSheet<EmployeeAdvance?>(
                context: context,
                isScrollControlled: true,
                builder: (ctx) => EmployeeAdvanceFormSheet(
                  employees: advanceState.employees,
                  paymentSources: advanceState.paymentSources,
                  currency: advanceState.currency,
                  salaryMonths: advanceState.salaryMonths,
                  suggestedSalaryMonth: advanceState.suggestedSalaryMonth,
                ),
              );
              if (advance != null && mounted) {
                _messengerKey.currentState?.showSnackBar(
                  SnackBar(content: Text(l10n.expensesAdvanceSubmitted)),
                );
              }
            },
      icon: const Icon(Icons.request_quote_outlined),
      label: Text(l10n.expensesAdvanceNewRequest),
    );
  }
}

/// The original Expenses body, unchanged — only lifted out of `build`.
class _ExpensesTab extends ConsumerWidget {
  final ExpensesState state;

  const _ExpensesTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(expensesNotifierProvider.notifier);
    final l10n = context.l10n;

    return RefreshIndicator(
      // allow pull-to-refresh
      onRefresh: notifier.refresh,
      child: ListView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 120,
        ),
        children: [
          _MonthSelector(
            months: state.months,
            selectedMonth: state.selectedMonth,
            onChanged: (value) => notifier.setMonth(value),
            label: l10n.expensesMonthLabel,
          ),
          const SizedBox(height: 12),
          ExpenseFiltersBar(
            paymentSources: state.paymentSources,
            activeFilters: state.paymentFilters,
            onToggle: notifier.togglePaymentFilter,
            onClear:
                state.paymentFilters.isEmpty ? null : notifier.clearFilters,
            clearLabel: l10n.expensesFiltersClear,
          ),
          const SizedBox(height: 12),
          ExpensesSummaryHeader(
              summary: state.summary, isManager: state.isManager),
          const SizedBox(height: 16),
          if (state.expenses.isEmpty)
            _EmptyState(isManager: state.isManager)
          else
            // `canApprove` gates the pending row; the cancel affordance on an
            // approved row needs the same manager check without the pending
            // one, so the flag is widened here and the card decides which of
            // the two action groups its own status calls for.
            ...state.expenses.map((expense) => ExpenseCard(
                  expense: expense,
                  canApprove: state.isManager && !state.isSubmitting,
                  onApprove: () => notifier.approveExpense(expense.name),
                  onReject: () => _rejectExpense(context, ref, expense),
                  onCancel: () => _cancelExpense(context, ref, expense),
                )),
        ],
      ),
    );
  }

  /// Refuse a pending request.
  ///
  /// The reason is mandatory server-side, so it is collected before the call
  /// rather than after a failure: the point of a rejection is that the person
  /// who filed the request finds out why.
  Future<void> _rejectExpense(
    BuildContext context,
    WidgetRef ref,
    ExpenseRecord expense,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final reason = await promptForReason(
      context,
      title: l10n.expensesRejectTitle,
      hint: l10n.expensesRejectHint,
      confirmLabel: l10n.expensesReject,
    );
    if (reason == null) return;

    final updated = await ref
        .read(expensesNotifierProvider.notifier)
        .rejectExpense(expense.name, reason);
    if (!context.mounted || updated == null) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.expensesRejected)));
  }

  /// Reverse one that was already approved.
  ///
  /// Spelled out in the dialog because this is not a refusal: the approval
  /// posted a journal entry, and cancelling reverses it. The amount and the
  /// account it goes back to are named so the manager is deciding with the
  /// numbers in front of them.
  Future<void> _cancelExpense(
    BuildContext context,
    WidgetRef ref,
    ExpenseRecord expense,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;

    final reason = await promptForReason(
      context,
      title: l10n.expensesCancelTitle,
      message: l10n.expensesCancelBody(
        formatCurrency(context, expense.amount, currencyCode: expense.currency),
        expense.localizedPaymentLabel(languageCode),
      ),
      hint: l10n.expensesCancelHint,
      confirmLabel: l10n.expensesCancelConfirm,
    );
    if (reason == null) return;

    final updated = await ref
        .read(expensesNotifierProvider.notifier)
        .cancelExpense(expense.name, reason);
    if (!context.mounted || updated == null) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.expensesCancelled)));
  }
}

class _EmployeeAdvancesTab extends ConsumerWidget {
  final EmployeeAdvancesState state;
  final bool canApprove;
  final bool canRequest;

  const _EmployeeAdvancesTab({
    required this.state,
    required this.canApprove,
    required this.canRequest,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(employeeAdvancesNotifierProvider.notifier);
    final l10n = context.l10n;

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 120,
        ),
        children: [
          // `hrms_available: false` is a normal answer, not a failure — the
          // server's own notice explains it and no error tile is shown.
          if (!state.hrmsAvailable)
            _AdvanceNoticeState(notice: state.notice)
          else ...[
            _MonthSelector(
              months: state.months,
              selectedMonth: state.selectedMonth,
              onChanged: (value) => notifier.setMonth(value),
              label: l10n.expensesAdvanceMonthLabel,
            ),
            const SizedBox(height: 12),
            _AdvanceStatusFilter(
              selected: state.statusFilter,
              onChanged: notifier.setStatusFilter,
            ),
            const SizedBox(height: 12),
            _AdvancesSummaryHeader(
              summary: state.summary,
              currency: state.currency,
              showSalaryPaid: state.salaryPaymentsVisible,
            ),
            if (state.notice != null && state.notice!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _AdvanceNoticeBanner(notice: state.notice!),
            ],
            const SizedBox(height: 16),
            if (state.advances.isEmpty &&
                !(state.salaryPaymentsVisible &&
                    state.salaryPayments.isNotEmpty))
              _AdvanceEmptyState(
                canApprove: canApprove,
                canRequest: canRequest,
              )
            else
              ...state.advances.map(
                (advance) => EmployeeAdvanceCard(
                  advance: advance,
                  canApprove: canApprove,
                  isBusy: state.isSubmitting,
                  onApprove: () => _confirmApprove(context, ref, advance),
                  onReject: () => _confirmReject(context, ref, advance),
                ),
              ),
            if (state.salaryPaymentsVisible &&
                state.salaryPayments.isNotEmpty) ...[
              const SizedBox(height: 8),
              _SalaryPaymentsHeader(
                total: formatCurrency(
                  context,
                  state.summary.salaryPaidAmount,
                  currencyCode: state.currency,
                ),
              ),
              const SizedBox(height: 8),
              ...state.salaryPayments.map(
                (payment) => AdvanceSalaryPaymentCard(payment: payment),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _confirmApprove(
    BuildContext context,
    WidgetRef ref,
    EmployeeAdvance advance,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final amount = formatCurrency(context, advance.amount,
        currencyCode: advance.currency);
    final source = advance.localizedPaymentLabel(languageCode).isNotEmpty
        ? advance.localizedPaymentLabel(languageCode)
        : (advance.payingAccount ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dialogL10n = ctx.l10n;
        return AlertDialog(
          title: Text(dialogL10n.expensesAdvanceApproveTitle),
          content: Text(
            dialogL10n.expensesAdvanceApproveBody(
              amount,
              advance.employeeName,
              source,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(dialogL10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(dialogL10n.expensesAdvanceApproveConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final paymentEntry = await ref
        .read(employeeAdvancesNotifierProvider.notifier)
        .approve(advance.name);
    if (!context.mounted) return;
    // `null` means the call failed; the screen's error listener already
    // surfaced the reason, so do not claim success on top of it.
    if (paymentEntry == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          paymentEntry.isEmpty
              ? l10n.expensesAdvanceApproved
              : l10n.expensesAdvanceApprovedWithEntry(paymentEntry),
        ),
      ),
    );
  }

  Future<void> _confirmReject(
    BuildContext context,
    WidgetRef ref,
    EmployeeAdvance advance,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final dialogL10n = ctx.l10n;
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          title: Text(dialogL10n.expensesAdvanceRejectTitle),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: reasonController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                labelText: dialogL10n.commonReasonLabel,
                hintText: dialogL10n.expensesAdvanceRejectHint,
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? dialogL10n.expensesAdvanceRejectReasonRequired
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(dialogL10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(ctx).pop(reasonController.text.trim());
              },
              child: Text(dialogL10n.expensesAdvanceReject),
            ),
          ],
        );
      },
    );
    reasonController.dispose();
    if (reason == null || reason.isEmpty) return;

    final ok = await ref
        .read(employeeAdvancesNotifierProvider.notifier)
        .reject(advance.name, reason);
    if (!context.mounted) return;
    if (!ok) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.expensesAdvanceRejected)),
    );
  }
}

class _AdvanceStatusFilter extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _AdvanceStatusFilter({required this.selected, required this.onChanged});

  static const _statuses = <String>[
    EmployeeAdvanceStatus.draft,
    EmployeeAdvanceStatus.paid,
    EmployeeAdvanceStatus.partiallyPaid,
    EmployeeAdvanceStatus.unpaid,
    EmployeeAdvanceStatus.claimed,
    EmployeeAdvanceStatus.returned,
    EmployeeAdvanceStatus.partlyClaimedAndReturned,
    EmployeeAdvanceStatus.cancelled,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // A status the server echoed back that is not in the known list still has
    // to be selectable, or the dropdown would assert on an unknown value.
    final values = <String?>[
      null,
      ..._statuses,
      if (selected != null && !_statuses.contains(selected)) selected,
    ];

    return Row(
      children: [
        Text(
          l10n.expensesAdvanceStatusFilterLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String?>(
            key: ValueKey<String?>(selected),
            initialValue: selected,
            isExpanded: true,
            items: values
                .map((value) => DropdownMenuItem<String?>(
                      value: value,
                      child: Text(
                        value == null
                            ? l10n.expensesAdvanceStatusFilterAll
                            : _statusLabel(context, value),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  String _statusLabel(BuildContext context, String status) =>
      localizedAdvanceStatus(context, status);
}

class _AdvancesSummaryHeader extends StatelessWidget {
  final EmployeeAdvanceSummary summary;
  final String? currency;

  final bool showSalaryPaid;

  const _AdvancesSummaryHeader({
    required this.summary,
    this.currency,
    this.showSalaryPaid = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String money(double value) =>
        formatCurrency(context, value, currencyCode: currency);

    final cards = <_AdvanceSummaryInfo>[
      _AdvanceSummaryInfo(
        title: l10n.expensesAdvanceSummaryTotal,
        value: money(summary.totalAmount),
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.blue.shade50,
        accent: Colors.blue,
      ),
      _AdvanceSummaryInfo(
        title: l10n.expensesAdvanceSummaryPending,
        value: l10n.expensesAdvanceSummaryPendingValue(
          summary.pendingCount,
          money(summary.pendingAmount),
        ),
        icon: Icons.hourglass_bottom,
        color: Colors.orange.shade50,
        accent: Colors.orange,
      ),
      _AdvanceSummaryInfo(
        title: l10n.expensesAdvanceSummaryApproved,
        value: l10n.expensesAdvanceSummaryCount(summary.approvedCount),
        icon: Icons.verified_outlined,
        color: Colors.green.shade50,
        accent: Colors.green,
      ),
      _AdvanceSummaryInfo(
        title: l10n.expensesAdvanceSummaryOutstanding,
        value: money(summary.outstandingAmount),
        icon: Icons.savings_outlined,
        color: Colors.purple.shade50,
        accent: Colors.purple,
      ),
      if (showSalaryPaid) ...[
        _AdvanceSummaryInfo(
          title: l10n.expensesAdvanceSummarySalaryPaid,
          value: l10n.expensesAdvanceSummaryPendingValue(
            summary.salaryPaidCount,
            money(summary.salaryPaidAmount),
          ),
          icon: Icons.payments_outlined,
          color: Colors.teal.shade50,
          accent: Colors.teal,
        ),
        _AdvanceSummaryInfo(
          title: l10n.expensesAdvanceSummaryHandedOut,
          value: money(summary.handedOutAmount),
          icon: Icons.volunteer_activism_outlined,
          color: Colors.indigo.shade50,
          accent: Colors.indigo,
        ),
      ],
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 82, // fixed height so the avatar + text never clip
      ),
      itemBuilder: (context, index) {
        final card = cards[index];
        return Card(
          elevation: 1,
          color: card.color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: card.accent.withValues(alpha: 0.15),
                  child: Icon(card.icon, color: card.accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        card.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: card.accent,
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.value,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Heading above the read-only salary payments from the Monthly Expenses
/// board, with their total and a one-line explanation of where they come from.
class _SalaryPaymentsHeader extends StatelessWidget {
  final String total;

  const _SalaryPaymentsHeader({required this.total});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.expensesAdvanceSalarySectionTitle,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              total,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.expensesAdvanceSalarySectionHelp,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _AdvanceSummaryInfo {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color accent;

  const _AdvanceSummaryInfo({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.accent,
  });
}

/// Rendered when `hrms_available` is false. Explanatory, never an error tile:
/// the site simply does not have the HR module installed.
class _AdvanceNoticeState extends StatelessWidget {
  final String? notice;

  const _AdvanceNoticeState({this.notice});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final body = (notice != null && notice!.trim().isNotEmpty)
        ? notice!.trim()
        : l10n.expensesAdvanceUnavailableBody;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 8),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            l10n.expensesAdvanceUnavailableTitle,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A notice that arrived alongside usable data (HRMS present, but the server
/// still had something to say). Informational, not an error.
class _AdvanceNoticeBanner extends StatelessWidget {
  final String notice;

  const _AdvanceNoticeBanner({required this.notice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(notice, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _AdvanceEmptyState extends StatelessWidget {
  final bool canApprove;
  final bool canRequest;

  const _AdvanceEmptyState({required this.canApprove, required this.canRequest});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final body = canRequest
        ? l10n.expensesAdvanceEmptyRequesterBody
        : canApprove
            ? l10n.expensesAdvanceEmptyApproverBody
            : l10n.expensesAdvanceEmptyReadOnlyBody;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.payments_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            l10n.expensesAdvanceEmptyTitle,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final List<ExpenseMonthOption> months;
  final String selectedMonth;
  final ValueChanged<String> onChanged;
  final String label;

  const _MonthSelector({
    required this.months,
    required this.selectedMonth,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final localeName = context.l10n.localeName;
    final effectiveMonths = months.isEmpty
        ? [
            ExpenseMonthOption(
              id: selectedMonth,
              label: selectedMonth.isEmpty
                  ? context.l10n.expensesMonthCurrent
                  : DateFormat.yMMMM(localeName).format(DateTime.tryParse('$selectedMonth-01') ?? DateTime.now()),
            )
          ]
        : months;

    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey<String>(selectedMonth),
            initialValue: effectiveMonths.any((m) => m.id == selectedMonth) ? selectedMonth : effectiveMonths.first.id,
            items: effectiveMonths
                .map((m) => DropdownMenuItem<String>(
                      value: m.id,
                      child: Text(m.label),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isManager;
  const _EmptyState({required this.isManager});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            l10n.expensesEmptyTitle,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            isManager ? l10n.expensesEmptyManagerBody : l10n.expensesEmptyStaffBody,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          Text(
            isManager
                ? l10n.expensesEmptyManagerHint
                : l10n.expensesEmptyStaffHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
