import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/business_constants.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../cash_custody/presentation/widgets/custody_payment_options.dart';
import '../../../pos/state/pos_notifier.dart';

/// How a label bill is settled: owed to the printer, or paid now from one
/// source. [option] uses the values the Purchase screen sends — a POS Profile
/// name, `instapay`, `cash` or `custody:<holder>` — and is null when owed.
class LabelPaymentSelection {
  final String? option;

  /// The custody choices loaded when the source was picked, kept so the sheet
  /// can re-check a custody's balance as the cost is edited.
  final CustodyPaymentChoices custody;

  const LabelPaymentSelection.owed()
      : option = null,
        custody = CustodyPaymentChoices.none;

  const LabelPaymentSelection.paid(String this.option, this.custody);

  bool get isPaid => option != null && option!.trim().isNotEmpty;

  /// A custody source that cannot cover [amount]. The server enforces it; this
  /// only keeps the save button from offering what would be refused.
  bool isShort(double amount) => isPaid && custody.isShort(option!, amount);
}

/// "Owed to supplier (pay later)" vs "Paid now", with the paid-from source
/// chosen the way the Purchase screen chooses it: every POS Profile, InstaPay,
/// Cash and the custodies the user may spend from.
///
/// Replicated from `purchase_screen.dart` `_choosePaymentOption` rather than
/// extracted, so the Purchase screen's own dialog is left exactly as it is.
class LabelPaymentChoiceField extends ConsumerStatefulWidget {
  final LabelPaymentSelection value;

  /// What the custody balance is checked against (the net cost entered).
  final double amount;
  final ValueChanged<LabelPaymentSelection> onChanged;

  const LabelPaymentChoiceField({
    super.key,
    required this.value,
    required this.amount,
    required this.onChanged,
  });

  @override
  ConsumerState<LabelPaymentChoiceField> createState() =>
      _LabelPaymentChoiceFieldState();
}

class _LabelPaymentChoiceFieldState
    extends ConsumerState<LabelPaymentChoiceField> {
  bool _loading = false;

  Future<void> _pickSource() async {
    if (_loading) return;
    setState(() => _loading = true);
    final profiles = ref.read(posNotifierProvider).profiles;
    final custody = await CustodyPaymentChoices.load(ref);
    if (!mounted) return;
    setState(() => _loading = false);

    String selected = widget.value.option ??
        (profiles.isNotEmpty ? (profiles.first['name'] as String) : 'instapay');
    final amount = widget.amount;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final l10n = ctx.l10n;
          return AlertDialog(
            title: Text(l10n.purchaseSelectPayment),
            content: SingleChildScrollView(
              child: RadioGroup<String>(
                groupValue: selected,
                onChanged: (v) =>
                    setStateDialog(() => selected = v ?? selected),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final p in profiles)
                      RadioListTile<String>(
                        value: p['name'] as String,
                        title: Text(p['name'] as String),
                        subtitle: Text(l10n.purchasePaymentProfileSubtitle),
                        dense: true,
                      ),
                    if (profiles.isNotEmpty) const Divider(),
                    RadioListTile<String>(
                      value: 'instapay',
                      title: Text(l10n.purchasePaymentInstapayTitle),
                      subtitle: Text(l10n.purchasePaymentInstapaySubtitle),
                      dense: true,
                    ),
                    RadioListTile<String>(
                      value: PaymentModes.cashLower,
                      title: Text(l10n.purchasePaymentCashTitle),
                      subtitle: Text(l10n.purchasePaymentCashSubtitle),
                      dense: true,
                    ),
                    if (!custody.isEmpty) ...[
                      const Divider(),
                      ...custody.radioTiles(ctx, amount: amount),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.commonCancel),
              ),
              ElevatedButton(
                onPressed: custody.isShort(selected, amount)
                    ? null
                    : () => Navigator.pop(ctx, selected),
                child: Text(l10n.commonContinue),
              ),
            ],
          );
        },
      ),
    );
    if (picked == null || !mounted) return;
    widget.onChanged(LabelPaymentSelection.paid(picked, custody));
  }

  String _sourceName(BuildContext context, LabelPaymentSelection value) {
    final l10n = context.l10n;
    final option = value.option!;
    if (option == 'instapay') return l10n.purchasePaymentInstapayTitle;
    if (option == PaymentModes.cashLower) return l10n.purchasePaymentCashTitle;
    final holder = value.custody.holderForOption(option);
    if (holder != null) {
      if (holder.name == value.custody.myHolderName) return l10n.custodyMine;
      final languageCode = Localizations.localeOf(context).languageCode;
      return l10n.custodyOfHolder(holder.localizedName(languageCode));
    }
    return option;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final value = widget.value;
    final short = value.isShort(widget.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.labelSheetPaymentHeading, style: theme.textTheme.labelLarge),
        // A transparent Material between the tiles and anything tinted above
        // them: Flutter 3.41+ asserts on a ListTile without one.
        Material(
          type: MaterialType.transparency,
          child: RadioGroup<bool>(
            groupValue: value.isPaid,
            onChanged: (paid) {
              if (paid == true) {
                _pickSource();
              } else {
                widget.onChanged(const LabelPaymentSelection.owed());
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<bool>(
                  key: const ValueKey('label-payment-owed'),
                  value: false,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(l10n.labelSheetPaymentOwed),
                  subtitle: Text(l10n.labelSheetPaymentOwedSubtitle),
                ),
                RadioListTile<bool>(
                  key: const ValueKey('label-payment-paid'),
                  value: true,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(l10n.labelSheetPaymentPaid),
                  subtitle: Text(
                    value.isPaid
                        ? (short
                            ? '${l10n.labelSheetPaymentPaidFrom(_sourceName(context, value))} · ${l10n.custodyInsufficientBalance}'
                            : l10n.labelSheetPaymentPaidFrom(
                                _sourceName(context, value)))
                        : l10n.labelSheetPaymentPickSource,
                    style: short
                        ? TextStyle(color: theme.colorScheme.error)
                        : null,
                  ),
                  secondary: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : value.isPaid
                          ? IconButton(
                              tooltip: l10n.labelSheetPaymentChange,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: _pickSource,
                            )
                          : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
