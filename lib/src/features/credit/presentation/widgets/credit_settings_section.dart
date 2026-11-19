import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../../../core/network/frappe_error_message.dart';
import '../../data/credit_repository.dart';
import '../../data/models/credit_models.dart';
import '../../state/credit_providers.dart';

/// Whether a shop may order on credit, its days and its limit — the three
/// Customer fields Desk edits, now settable from the B2B account screen.
///
/// Hidden when the profile cannot be read (a rep or cashier the credit read
/// gate refuses, or an older server): the account screen carries on without
/// it. The edit button appears only when the server says
/// [CustomerCreditProfile.canEditSettings].
class CreditSettingsSection extends ConsumerWidget {
  final String customer;
  final String customerName;

  const CreditSettingsSection({
    super.key,
    required this.customer,
    this.customerName = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(customerCreditProfileProvider(customer));
    return async.maybeWhen(
      data: (profile) => _CreditSettingsCard(
        profile: profile,
        onEdit: profile.canEditSettings
            ? () async {
                final saved = await CreditSettingsSheet.show(
                  context,
                  customer: customer,
                  customerName: customerName,
                  initial: profile,
                );
                if (saved == null || !context.mounted) return;
                final l10n = context.l10n;
                // Switching credit off does not clear what the shop owes;
                // said out loud so nobody reads "off" as "settled".
                final message =
                    !saved.creditAllowed && saved.currentBalance > 0.005
                        ? l10n.creditSettingsOffWithBalance(
                            formatCurrency(
                              context,
                              saved.currentBalance,
                              currencyCode: saved.currency,
                            ),
                          )
                        : l10n.creditSettingsSaved;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(message)));
              }
            : null,
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _CreditSettingsCard extends StatelessWidget {
  final CustomerCreditProfile profile;
  final VoidCallback? onEdit;

  const _CreditSettingsCard({required this.profile, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final allowed = profile.creditAllowed;

    final details = <String>[
      if (allowed && profile.hasTerms) l10n.creditAccountTerms(profile.creditDays),
      if (allowed)
        profile.hasLimit
            ? l10n.creditAccountLimit(
                formatCurrency(
                  context,
                  profile.creditLimit,
                  currencyCode: profile.currency,
                ),
              )
            : l10n.creditSettingsNoLimit,
      if (profile.currentBalance > 0.005)
        '${l10n.creditAccountBalanceLabel}: '
            '${formatCurrency(context, profile.currentBalance, currencyCode: profile.currency)}',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            Icon(
              allowed ? Icons.credit_score_outlined : Icons.credit_card_off_outlined,
              color: allowed ? theme.colorScheme.primary : muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.creditSettingsTitle,
                    style: theme.textTheme.labelLarge?.copyWith(color: muted),
                  ),
                  Text(
                    allowed
                        ? l10n.creditSettingsAllowed
                        : l10n.creditSettingsNotAllowed,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (details.isNotEmpty)
                    Text(
                      details.join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                ],
              ),
            ),
            if (onEdit != null)
              TextButton(
                onPressed: onEdit,
                child: Text(l10n.creditSettingsEdit),
              ),
          ],
        ),
      ),
    );
  }
}

/// The editor: one switch and two numbers. Returns the saved profile, or null
/// when the user backed out.
class CreditSettingsSheet extends ConsumerStatefulWidget {
  final String customer;
  final String customerName;
  final CustomerCreditProfile initial;

  const CreditSettingsSheet({
    super.key,
    required this.customer,
    required this.customerName,
    required this.initial,
  });

  static Future<CustomerCreditProfile?> show(
    BuildContext context, {
    required String customer,
    required String customerName,
    required CustomerCreditProfile initial,
  }) {
    return showModalBottomSheet<CustomerCreditProfile>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: CreditSettingsSheet(
          customer: customer,
          customerName: customerName,
          initial: initial,
        ),
      ),
    );
  }

  @override
  ConsumerState<CreditSettingsSheet> createState() =>
      _CreditSettingsSheetState();
}

class _CreditSettingsSheetState extends ConsumerState<CreditSettingsSheet> {
  late bool _allowed;
  late final TextEditingController _daysController;
  late final TextEditingController _limitController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _allowed = initial.creditAllowed;
    final storedDays = initial.creditDaysSetting ?? initial.creditDays;
    _daysController = TextEditingController(
      text: storedDays > 0 ? '$storedDays' : '',
    );
    // Empty means "no limit"; showing 0.00 would read as "no credit at all".
    _limitController = TextEditingController(
      text: initial.hasLimit ? initial.creditLimit.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _daysController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final daysText = _daysController.text.trim();
    final limitText = _limitController.text.trim().replaceAll(',', '');

    final days = daysText.isEmpty ? 0 : int.tryParse(daysText);
    if (days == null || days < 0 || days > 365) {
      setState(() => _error = l10n.creditSettingsDaysInvalid);
      return;
    }
    final limit = limitText.isEmpty ? 0.0 : double.tryParse(limitText);
    if (limit == null || limit < 0) {
      setState(() => _error = l10n.creditSettingsLimitInvalid);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved =
          await ref.read(creditRepositoryProvider).updateCustomerCreditSettings(
                customer: widget.customer,
                creditAllowed: _allowed,
                days: days,
                limit: limit,
              );
      // The checkout's Credit button and the ledger both read this profile.
      ref.invalidate(customerCreditProfileProvider(widget.customer));
      ref.invalidate(creditLedgerProvider);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = context.userErrorMessage(
          extractFrappeErrorMessage(
            error,
            fallback: l10n.creditSettingsSaveFailed,
          ),
          fallback: l10n.creditSettingsSaveFailed,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(l10n.creditSettingsTitle, style: theme.textTheme.titleLarge),
            if (widget.customerName.isNotEmpty)
              Text(
                widget.customerName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.creditSettingsAllowSwitch),
              value: _allowed,
              onChanged: _saving ? null : (v) => setState(() => _allowed = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _daysController,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.creditSettingsDaysLabel,
                helperText: l10n.creditSettingsDaysHelper,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _limitController,
              enabled: !_saving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.creditSettingsLimitLabel,
                helperText: l10n.creditSettingsLimitHelper,
                prefixText:
                    '${currencySymbol(context, currencyCode: widget.initial.currency)} ',
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.commonSave),
            ),
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.commonCancel),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
