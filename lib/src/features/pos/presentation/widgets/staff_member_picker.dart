import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/paste_icon_button.dart';
import '../../data/models/staff_customer_models.dart';
import '../../data/repositories/staff_customer_repository.dart';
import '../../state/pos_notifier.dart';

/// What the picker hands back: the person chosen and the Customer the backend
/// guaranteed for them.
class StaffMemberPick {
  final StaffOrderEmployee employee;
  final StaffCustomerEnsureResult result;

  const StaffMemberPick({required this.employee, required this.result});
}

/// The "Staff member" field shown under the order purpose for an Employee
/// order. The order's customer is never picked by hand here: the operator picks
/// a person and the backend returns the Customer linked to that Employee, which
/// is what lets payroll deduct the order.
class StaffMemberControl extends ConsumerWidget {
  const StaffMemberControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(posNotifierProvider);
    final hasStaff = state.hasStaffEmployee;
    final staffName = (state.selectedStaffEmployeeName ?? '').trim().isNotEmpty
        ? state.selectedStaffEmployeeName!.trim()
        : (state.selectedStaffEmployee ?? '').trim();

    return Container(
      key: const ValueKey('staff-member-control'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: hasStaff ? colorScheme.outline : colorScheme.error,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.posStaffMemberLabel,
                      style: theme.textTheme.labelMedium,
                    ),
                    if (hasStaff)
                      Text(
                        staffName,
                        key: const ValueKey('staff-member-name'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (hasStaff)
                TextButton(
                  onPressed: state.isLoading
                      ? null
                      : () => pickStaffMemberForOrder(context, ref),
                  child: Text(l10n.posStaffMemberChange),
                ),
            ],
          ),
          if (!hasStaff) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('choose-staff-member'),
                onPressed: state.isLoading
                    ? null
                    : () => pickStaffMemberForOrder(context, ref),
                icon: const Icon(Icons.person_search_outlined),
                label: Text(l10n.posStaffMemberChoose),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "On credit" / "Cash" for an Employee order, shown directly under
/// [StaffMemberControl]. Credit (the default) leaves the order unpaid on the
/// staff customer for payroll to deduct; cash settles it into the branch till
/// at checkout. The hint underneath says which of the two will happen.
class EmployeePaymentControl extends ConsumerWidget {
  const EmployeePaymentControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(posNotifierProvider);
    final paysCash = state.employeePaysCash;

    return Column(
      key: const ValueKey('employee-payment-control'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            key: const ValueKey('employee-payment-toggle'),
            segments: [
              ButtonSegment<String>(
                value: PosState.employeePaymentCredit,
                label: Text(
                  l10n.paymentMethodCredit,
                  overflow: TextOverflow.ellipsis,
                ),
                icon: const Icon(Icons.badge_outlined),
              ),
              ButtonSegment<String>(
                value: PosState.employeePaymentCash,
                label: Text(
                  l10n.paymentMethodCash,
                  overflow: TextOverflow.ellipsis,
                ),
                icon: const Icon(Icons.payments_outlined),
              ),
            ],
            selected: <String>{
              paysCash
                  ? PosState.employeePaymentCash
                  : PosState.employeePaymentCredit,
            },
            onSelectionChanged: state.isLoading
                ? null
                : (selection) {
                    if (selection.isEmpty) return;
                    ref
                        .read(posNotifierProvider.notifier)
                        .setEmployeePayment(selection.first);
                  },
            showSelectedIcon: false,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          paysCash ? l10n.posEmployeePaymentCashHint : l10n.posStaffMemberHint,
          key: ValueKey(
            paysCash
                ? 'employee-payment-cash-hint'
                : 'employee-payment-credit-hint',
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// Opens the picker and, on a choice, puts the order on that staff member.
Future<void> pickStaffMemberForOrder(
  BuildContext context,
  WidgetRef ref,
) async {
  // Resolved before the await: the cart can rebuild away while the sheet is
  // open, after which `ref` is no longer usable.
  final notifier = ref.read(posNotifierProvider.notifier);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = context.l10n;

  final pick = await showStaffMemberPicker(context);
  if (pick == null) return;

  final name = pick.employee.displayName;
  final applied = notifier.selectStaffCustomer(
    customer: pick.result.customer,
    employee: pick.employee.employee,
    employeeName: name,
  );
  if (!applied) return;
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        pick.result.created
            ? l10n.posStaffMemberCustomerCreated(name)
            : l10n.posStaffMemberAssigned(name),
      ),
    ),
  );
}

/// A bottom sheet on phones, a dialog on tablets, like the cart's other
/// pickers.
Future<StaffMemberPick?> showStaffMemberPicker(BuildContext context) {
  if (ResponsiveUtils.isPhone(context)) {
    return showModalBottomSheet<StaffMemberPick>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const StaffMemberPickerSheet(),
    );
  }
  return showDialog<StaffMemberPick>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveUtils.getDialogWidth(dialogContext, small: 520),
          maxHeight: ResponsiveUtils.getDialogHeight(dialogContext, max: 640),
        ),
        child: const StaffMemberPickerSheet(asDialog: true),
      ),
    ),
  );
}

class StaffMemberPickerSheet extends ConsumerStatefulWidget {
  const StaffMemberPickerSheet({super.key, this.asDialog = false});

  final bool asDialog;

  @override
  ConsumerState<StaffMemberPickerSheet> createState() =>
      _StaffMemberPickerSheetState();
}

class _StaffMemberPickerSheetState
    extends ConsumerState<StaffMemberPickerSheet> {
  static const _searchDebounce = Duration(milliseconds: 350);

  final _searchController = TextEditingController();
  Timer? _debounce;
  int _requestToken = 0;
  String _query = '';
  bool _loading = true;
  StaffOrderEmployeeList? _data;
  Object? _loadError;
  String? _ensuringEmployee;
  Object? _ensureError;

  @override
  void initState() {
    super.initState();
    // `_loading` already starts true; setState is not allowed in initState.
    _load(initial: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool initial = false}) async {
    final token = ++_requestToken;
    final query = _query;
    if (!initial) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final data = await ref
          .read(staffCustomerRepositoryProvider)
          .listStaffForOrders(search: query);
      if (!mounted || token != _requestToken) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || token != _requestToken) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      if (!mounted) return;
      _query = value.trim();
      _load();
    });
  }

  Future<void> _choose(StaffOrderEmployee employee) async {
    if (_ensuringEmployee != null) return;
    setState(() {
      _ensuringEmployee = employee.employee;
      _ensureError = null;
    });
    try {
      final result = await ref
          .read(staffCustomerRepositoryProvider)
          .ensureStaffCustomer(employee.employee);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(StaffMemberPick(employee: employee, result: result));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _ensuringEmployee = null;
        _ensureError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asDialog) {
      return _buildContent(context, null);
    }
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (ctx, scrollController) => SafeArea(
          top: false,
          child: _buildContent(ctx, scrollController),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ScrollController? controller) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.posStaffMemberPickerTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: l10n.commonClose,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: TextField(
            key: const ValueKey('staff-member-search'),
            controller: _searchController,
            textInputAction: TextInputAction.search,
            enabled: _ensuringEmployee == null,
            decoration: InputDecoration(
              hintText: l10n.posStaffMemberSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: PasteIconButton(
                controller: _searchController,
                enabled: _ensuringEmployee == null,
                onChanged: _onSearchChanged,
              ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        if (_ensureError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.userErrorMessage(
                      _ensureError,
                      fallback: l10n.posStaffMemberEnsureFailed,
                    ),
                    key: const ValueKey('staff-member-ensure-error'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_loading && _data != null) const LinearProgressIndicator(),
        const Divider(height: 1),
        Flexible(child: _buildBody(context, controller)),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ScrollController? controller) {
    final l10n = context.l10n;
    final data = _data;

    if (data == null) {
      if (_loading) {
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return _message(
        context,
        icon: Icons.cloud_off_outlined,
        title: context.userErrorMessage(
          _loadError,
          fallback: l10n.posStaffMemberLoadFailed,
        ),
        action: TextButton(onPressed: _load, child: Text(l10n.commonRetry)),
      );
    }

    if (!data.hrmsAvailable) {
      return _message(
        context,
        key: const ValueKey('staff-member-hrms-unavailable'),
        icon: Icons.groups_outlined,
        title: l10n.posStaffMemberHrmsUnavailableTitle,
        body: l10n.posStaffMemberHrmsUnavailableBody,
      );
    }

    if (data.employees.isEmpty) {
      return _message(
        context,
        icon: Icons.person_off_outlined,
        title: _query.isEmpty
            ? l10n.posStaffMemberEmpty
            : l10n.posStaffMemberNoMatches,
      );
    }

    return ListView.builder(
      controller: controller,
      shrinkWrap: controller == null,
      itemCount: data.employees.length,
      itemBuilder: (context, index) {
        final employee = data.employees[index];
        final details = [
          employee.branch,
          employee.designation,
        ].where((part) => part.isNotEmpty).join(' • ');
        final isEnsuring = _ensuringEmployee == employee.employee;
        return ListTile(
          key: ValueKey('staff-member-${employee.employee}'),
          enabled: _ensuringEmployee == null || isEnsuring,
          leading: CircleAvatar(child: Text(_initials(employee.displayName))),
          title: Text(employee.displayName),
          subtitle: details.isEmpty && employee.hasCustomer
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (details.isNotEmpty) Text(details),
                    if (!employee.hasCustomer)
                      Text(
                        l10n.posStaffMemberNewCustomerHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
          trailing: isEnsuring
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _ensuringEmployee == null ? () => _choose(employee) : null,
        );
      },
    );
  }

  Widget _message(
    BuildContext context, {
    Key? key,
    required IconData icon,
    required String title,
    String? body,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }
}
