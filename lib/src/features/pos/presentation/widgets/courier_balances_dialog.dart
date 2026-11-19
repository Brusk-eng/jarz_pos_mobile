// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/courier_balances_provider.dart';
import '../../state/courier_ws_bridge.dart';
import '../../data/models/courier_balance.dart';
import '../../../pos/state/pos_notifier.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../../../core/network/courier_service.dart';
import '../../../kanban/providers/kanban_provider.dart';
import '../../data/repositories/courier_repository.dart';
import '../../../kanban/widgets/settlement_preview_dialog.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/network/user_service.dart';
import '../../../settlement_reversal/presentation/widgets/reverse_settlement_sheet.dart';

/// Whether settlement reversal is released to users.
///
/// Released on 2026-09-07, together with `UNSETTLE_RELEASED` in
/// `jarz_pos/api/couriers.py`. The server-side flag is the real control: these
/// endpoints take an arbitrary Journal Entry name, so hiding this button was
/// never more than a convenience.
///
/// Held back since 944bf02 while three money-affecting defects were fixed — a
/// settlement-discovery query that returned nothing on any real database, a
/// deny-list that let a collection-change entry be reversed (erasing the record
/// of a customer's online payment; 14 such entries existed in production), and
/// a double-reversal guard that a row lock did not actually isolate. All three
/// were invisible to the mocked suites on both sides, which is how they
/// survived a green run, so all three were verified against a real database,
/// real Redis and real concurrency before this was flipped.
///
/// Deliberately not `const` — a `const` bool folds at compile time and the
/// analyzer then reports the other branch as dead code.
final bool _settlementReversalReleased = true;

String _courierPartyKey(String partyType, String party) => '$partyType::$party';

Future<void> showCourierBalancesDialog(
  BuildContext context, {
  Set<String>? allowedPartyKeys,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => CourierBalancesDialog(allowedPartyKeys: allowedPartyKeys),
  );
}

class CourierBalancesDialog extends ConsumerStatefulWidget {
  const CourierBalancesDialog({
    super.key,
    this.allowedPartyKeys,
  });

  final Set<String>? allowedPartyKeys;

  @override
  ConsumerState<CourierBalancesDialog> createState() =>
      _CourierBalancesDialogState();
}

class _CourierBalancesDialogState extends ConsumerState<CourierBalancesDialog> {
  @override
  void initState() {
    super.initState();
    // Always fetch fresh balances whenever the popup opens. The provider is a
    // session-scoped singleton, so relying on its cached `hasLoaded` flag (as the
    // old build-time microtask did) meant every reopen showed stale figures until
    // the user manually hit refresh. load() has its own concurrency guard, so a
    // redundant call while a fetch is already in flight is a safe no-op.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(courierBalancesProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courierBalancesProvider);
    // Activate websocket bridge for auto-refresh while dialog is open
    ref.watch(courierWsBridgeProvider);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: FractionallySizedBox(
        widthFactor: 0.95,
        heightFactor: 0.85,
        child: Column(
          children: [
            _DialogHeader(
              onClose: () => Navigator.of(context).pop(),
              onRefresh: () async {
                final notifier = ref.read(courierBalancesProvider.notifier);
                await notifier.load();
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: _DialogBody(
                state: state,
                allowedPartyKeys: widget.allowedPartyKeys,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends ConsumerWidget {
  final VoidCallback onClose;
  final VoidCallback onRefresh;
  const _DialogHeader({required this.onClose, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Released 2026-09-07 (see `_settlementReversalReleased` above). The role
    // check mirrors the server's: Admin | Line Manager tier, the same tier
    // `_ensure_unsettle_access` enforces in jarz_pos/api/couriers.py. This gate
    // decides what is SHOWN; the server decides what is allowed, and it is
    // gated independently because these endpoints take an arbitrary Journal
    // Entry name.
    final canReverse =
        _settlementReversalReleased && ref.watch(canActAsLineManagerProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.primary,
      child: Row(
        children: [
          Icon(Icons.local_shipping, color: Theme.of(context).colorScheme.onPrimary),
          const SizedBox(width: 8),
          Text(
            l10n.courierBalancesTitle,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
          ),
          const Spacer(),
          if (canReverse)
            IconButton(
              tooltip: l10n.unsettleEntryPointTooltip,
              icon: Icon(Icons.undo, color: Theme.of(context).colorScheme.onPrimary),
              onPressed: () {
                final posProfile = ref.read(posNotifierProvider).selectedProfile?['name'] as String?;
                ReverseSettlementSheet.show(context, posProfile: posProfile);
              },
            ),
          IconButton(
            tooltip: l10n.expensesRefreshTooltip,
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onPrimary),
            onPressed: onRefresh,
          ),
          IconButton(
            tooltip: l10n.commonClose,
            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onPrimary),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _DialogBody extends StatelessWidget {
  final CourierBalancesState state;
  final Set<String>? allowedPartyKeys;

  const _DialogBody({
    required this.state,
    this.allowedPartyKeys,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(child: Text(context.userErrorMessage(state.error)));
    }
    final balances = allowedPartyKeys == null || allowedPartyKeys!.isEmpty
        ? state.balances
        : state.balances.where((balance) {
            return allowedPartyKeys!.contains(
              _courierPartyKey(balance.partyType, balance.party),
            );
          }).toList(growable: false);
    if (balances.isEmpty) {
      return Center(child: Text(l10n.courierBalancesEmpty));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: balances.length,
  separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => _CourierTile(balances[index]),
    );
  }
}

class _CourierTile extends StatelessWidget {
  final CourierBalance b;
  const _CourierTile(this.b);

  @override
  Widget build(BuildContext context) {
  final l10n = context.l10n;
  final amount = b.balance;
  // Domain correction: positive balance -> collect from courier (they owe us); negative -> pay courier
  final collectFromCourier = amount > 0;
  final color = amount == 0
    ? Colors.grey
    : (collectFromCourier ? Colors.green : Colors.red);
  final label = amount == 0
    ? l10n.courierBalancesSettledLabel
    : (collectFromCourier ? l10n.settlementTitleCollectFromCourier : l10n.settlementTitlePayCourier);
    return ListTile(
      title: Row(
        children: [
          Flexible(child: Text(b.courierName.isNotEmpty ? b.courierName : b.courier)),
          if (b.isPartnerCourier) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.handshake, size: 12, color: Colors.deepPurple.shade400),
                  const SizedBox(width: 3),
                  Text(b.deliveryPartner ?? l10n.rptCourierBalancesPartnerFallback,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.deepPurple.shade700)),
                ],
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(label),
      trailing: SizedBox(
        width: 170,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // The formatted amount carries the currency symbol, so it may
            // shrink rather than overflow the fixed-width trailing slot.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  formatCurrency(context, amount),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 30,
              child: _InlineSettleAllButton(balance: b),
            ),
          ],
        ),
      ),
      onTap: () => _showDetails(context),
    );
  }

  // Everything inside the sheet must use the SHEET's own contexts, never this
  // tile's `context`. The sheet is a separate route that outlives the tile: the
  // dialog body swaps its whole list for a spinner on every balances reload
  // (after a settlement, or a websocket-driven refresh), which disposes this
  // tile while the sheet stays open. Its context is then defunct, and the next
  // tap on a per-invoice Settle hit `ScaffoldMessenger.of(<dead context>)` ->
  // "Null check operator used on a null value" (Sentry JARZ-FLUTTER-CLIENT-J).
  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (routeCtx) {
        return DraggableScrollableSheet(
          initialChildSize: ResponsiveUtils.getCartBottomSheetInitialSize(routeCtx),
          minChildSize: ResponsiveUtils.getCartBottomSheetMinSize(routeCtx),
          maxChildSize: ResponsiveUtils.getCartBottomSheetMaxSize(routeCtx),
          expand: false,
          builder: (sheetCtx, scrollController) {
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(sheetCtx).colorScheme.primary,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sheetCtx.l10n.courierBalancesDetailsTitle(b.courierName.isNotEmpty ? b.courierName : b.courier),
                          style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                            color: Theme.of(sheetCtx).colorScheme.onPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SettleAllButton(balance: b),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      12,
                      12,
                      12,
                      12 + MediaQuery.paddingOf(sheetCtx).bottom,
                    ),
                    itemCount: b.details.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final d = b.details[index];
                      final net = d.amount - d.shipping;
                      return ListTile(
                        dense: true,
                        title: Text(d.displayId),
                        subtitle: Text(
                          context.l10n.courierBalancesCityOrderLine(
                            d.city,
                            formatCurrency(context, d.amount),
                            formatCurrency(context, d.shipping),
                          ),
                        ),
                        trailing: SizedBox(
                          width: 150,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(context.l10n.courierBalancesNetLabel, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(formatCurrency(context, net), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 60,
                                height: 28,
                                child: Consumer(
                                  builder: (buttonCtx, ref, _) {
                                    return ElevatedButton(
                                      onPressed: () async {
                                        if (!buttonCtx.mounted) return;
                                        final messenger = ScaffoldMessenger.of(buttonCtx);
                                        try {
                                          final posProfile = ref.read(posNotifierProvider).selectedProfile?['name'];
                                          if (posProfile == null || posProfile.isEmpty) {
                                            messenger.showSnackBar(SnackBar(content: Text(buttonCtx.l10n.posProfileSelectionPrompt)));
                                            return;
                                          }
                                          String partyType = b.partyType.isNotEmpty ? b.partyType : 'Supplier';
                                          String party = b.party.isNotEmpty ? b.party : b.courier;

                                          final preview = await ref.read(courierServiceProvider).getSettlementPreview(
                                            invoice: d.invoice,
                                            partyType: partyType,
                                            party: party,
                                          );
                                          if (partyType.isEmpty && (preview['party_type'] ?? '') != '') partyType = preview['party_type'];
                                          if (party.isEmpty && (preview['party'] ?? '') != '') party = preview['party'];
                                          if (!buttonCtx.mounted) return;

                                          final confirmation = await showSettlementConfirmDialog(
                                            buttonCtx,
                                            preview,
                                            invoice: d.invoice,
                                            orderFallback: d.amount,
                                            shippingFallback: d.shipping,
                                          );
                                          if (confirmation?.confirmed != true) return;

                                          final netRaw = preview['net_amount'];
                                          final net = (netRaw is num) ? netRaw.toDouble() : double.tryParse(netRaw?.toString() ?? '0') ?? 0.0;

                                          Map<String, dynamic>? res;
                                          if (net > 0) {
                                            // Courier collected customer money; we record that collection.
                                            res = await ref.read(kanbanProvider.notifier).settleCourierCollectedPayment(
                                              invoiceId: d.invoice,
                                              posProfile: posProfile,
                                              partyType: partyType,
                                              party: party,
                                            );
                                          } else if (net < 0) {
                                            // Store owes courier (shipping higher or order already paid) → pay courier.
                                            res = await ref.read(kanbanProvider.notifier).settleSingleInvoicePaid(
                                              invoiceId: d.invoice,
                                              posProfile: posProfile,
                                              partyType: partyType,
                                              party: party,
                                            );
                                          } else {
                                            messenger.showSnackBar(SnackBar(content: Text(buttonCtx.l10n.settlementNothingToSettle)));
                                            return;
                                          }

                                          if (!buttonCtx.mounted) return;
                                          if (res != null && (res['success'] == true || res['journal_entry'] != null)) {
                                            messenger.showSnackBar(SnackBar(content: Text(buttonCtx.l10n.courierSettlementComplete)));
                                            try { await ref.read(courierBalancesProvider.notifier).load(); } catch (_) {}
                                          } else {
                                            messenger.showSnackBar(SnackBar(content: Text(buttonCtx.l10n.courierSettlementFailed)));
                                          }
                                        } catch (e) {
                                          if (buttonCtx.mounted) {
                                            messenger.showSnackBar(SnackBar(content: Text(buttonCtx.userErrorMessage(e))));
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        minimumSize: const Size(0, 28),
                                        textStyle: const TextStyle(fontSize: 10),
                                      ),
                                      child: Text(context.l10n.courierSettleButton),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SettleAllButton extends ConsumerStatefulWidget {
  final CourierBalance balance;
  const _SettleAllButton({required this.balance});

  @override
  ConsumerState<_SettleAllButton> createState() => _SettleAllButtonState();
}

// Inline variant for list row reuse underlying logic
class _InlineSettleAllButton extends ConsumerStatefulWidget {
  final CourierBalance balance;
  const _InlineSettleAllButton({required this.balance});
  @override
  ConsumerState<_InlineSettleAllButton> createState() => _InlineSettleAllButtonState();
}

class _InlineSettleAllButtonState extends ConsumerState<_InlineSettleAllButton> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    final b = widget.balance;
    final disabled = (b.balance).abs() < 0.0001 || _loading;
    return ElevatedButton(
      onPressed: disabled ? null : () => _run(context),
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: const Size(0,30)),
      child: _loading ? const SizedBox(width:14,height:14,child:CircularProgressIndicator(strokeWidth:2,color: Colors.white)) : Text(context.l10n.courierSettleButton, style: const TextStyle(fontSize: 11)),
    );
  }

  Future<void> _run(BuildContext context) async {
  final b = widget.balance;
  final posProfile = ref.read(posNotifierProvider).selectedProfile?['name'];
    if (posProfile == null || posProfile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.posProfileSelectionPrompt)));
      return;
    }
    final amount = formatCurrency(context, b.balance.abs());
    // Mirror _CourierTile / _SettleAllButtonState: a POSITIVE balance means the
    // courier owes the store, so we COLLECT from them; negative means we pay them.
    // The label was previously inverted here, which is why inline "Settle All"
    // disagreed with the single-settle wording.
    final collectFromCourier = b.balance > 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(collectFromCourier
            ? context.l10n.courierCollectAmount(amount)
            : context.l10n.courierPayCourierAmount(amount)),
        content: Text(context.l10n.courierSettleAllInvoicesQuestion(b.details.length)),
        actions: [
          TextButton(onPressed: ()=>Navigator.of(ctx).pop(false), child: Text(context.l10n.commonCancel)),
          ElevatedButton(onPressed: ()=>Navigator.of(ctx).pop(true), child: Text(context.l10n.commonConfirm)),
        ],
      ),
    );
    // This button lives in the courier row, and the row is disposed whenever the
    // balances reload (a websocket refresh can land while the confirm dialog is
    // open). setState on a disposed State is the same release-mode null-check
    // crash as JARZ-FLUTTER-CLIENT-J, and it dropped the settlement unsent.
    if (confirmed != true || !mounted) return;
    setState(()=>_loading=true);
    try {
      final res = await ref.read(courierRepositoryProvider).settleAllForParty(
        posProfile: posProfile,
        partyType: b.partyType.isNotEmpty ? b.partyType : null,
        party: b.party.isNotEmpty ? b.party : null,
        legacyCourier: b.courier.isNotEmpty ? b.courier : null,
      );
      if (!mounted) return;
      if (res['journal_entry']!=null || res['net_balance']!=null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.courierSettled)));
        try {
          await ref.read(courierBalancesProvider.notifier).load();
        } catch (e) {
          debugPrint('Failed to refresh courier balances after settle-all inline: $e');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.courierSettlementFailed)));
      }
    } catch(e){
      if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.userErrorMessage(e))));}
    } finally { if(mounted) setState(()=>_loading=false); }
  }
}

class _SettleAllButtonState extends ConsumerState<_SettleAllButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
  final b = widget.balance;
    final disabled = (b.balance).abs() < 0.0001 || _loading;
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: disabled ? null : () => _confirmAndSettleAll(context),
        icon: _loading ? const SizedBox(width:16,height:16,child: CircularProgressIndicator(strokeWidth:2,color: Colors.white)) : const Icon(Icons.done_all,size:16),
        label: Text(context.l10n.courierSettleAllButton, style: const TextStyle(fontSize: 11)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          disabledBackgroundColor: Colors.grey.shade500,
        ),
      ),
    );
  }

  Future<void> _confirmAndSettleAll(BuildContext context) async {
    final b = widget.balance;
  final posProfile = ref.read(posNotifierProvider).selectedProfile?['name'];
    if (posProfile == null || posProfile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.posProfileSelectionPrompt)));
      return;
    }
  final collectFromCourier = b.balance > 0; // positive -> collect (courier owes store)
  final actionLabel = collectFromCourier ? context.l10n.settlementTitleCollectFromCourier : context.l10n.settlementTitlePayCourier;
    final netLabel = formatCurrency(context, b.balance.abs());
    final invoices = b.details.map((d) => d.displayId).toList();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.courierSettleAllDialogTitle(actionLabel, netLabel)),
        content: SizedBox(
          width: ResponsiveUtils.getDialogWidth(
            ctx,
            small: 400,
            medium: 460,
            large: 520,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.courierSettleAllWillSettle(invoices.length)),
              const SizedBox(height: 8),
              Text(context.l10n.courierInvoicesLabel),
              const SizedBox(height: 6),
              SizedBox(
                height: 150,
                width: double.infinity,
                child: Scrollbar(
                  child: ListView.builder(
                    itemCount: invoices.length,
                    itemBuilder: (context, i) => Text(invoices[i], style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
        Text(collectFromCourier
          ? context.l10n.courierSettleAllCollectInfo
          : context.l10n.courierSettleAllPayInfo),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(context.l10n.commonCancel)),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(context.l10n.commonConfirm)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    // Read once, before any await: if the sheet is closed mid-loop, `ref` is
    // disposed and every later ref.read throws, which the per-invoice catch
    // counted as a failure - leaving the rest of the invoices silently unsettled.
    final courierService = ref.read(courierServiceProvider);
    final kanbanNotifier = ref.read(kanbanProvider.notifier);
    final balancesNotifier = ref.read(courierBalancesProvider.notifier);
    try {
      final messenger = ScaffoldMessenger.of(context);
      int success = 0;
      int failed = 0;
      for (final d in b.details) {
        try {
          // Per-invoice preview & settlement (kanban aligned)
          String partyType = b.partyType.isNotEmpty ? b.partyType : 'Supplier';
          String party = b.party.isNotEmpty ? b.party : b.courier;
          final preview = await courierService.getSettlementPreview(
            invoice: d.invoice,
            partyType: partyType,
            party: party,
          );
          final netRaw = preview['net_amount'];
          final net = (netRaw is num) ? netRaw.toDouble() : double.tryParse(netRaw?.toString() ?? '0') ?? 0.0;
          Map<String, dynamic>? res;
          if (net > 0) {
            // store collects from courier (courier had customer cash)
            res = await kanbanNotifier.settleCourierCollectedPayment(
              invoiceId: d.invoice,
              posProfile: posProfile,
              partyType: partyType,
              party: party,
            );
          } else if (net < 0) {
            // store pays courier (shipping greater or order prepaid)
            res = await kanbanNotifier.settleSingleInvoicePaid(
              invoiceId: d.invoice,
              posProfile: posProfile,
              partyType: partyType,
              party: party,
            );
          } else {
            // nothing to do for zero net
            continue;
          }
          if (res != null && (res['success'] == true || res['journal_entry'] != null)) {
            success++;
          } else {
            failed++;
          }
        } catch (_) {
          failed++;
        }
      }
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(context.l10n.courierSettleAllComplete(success, failed))));
      }
      try { await balancesNotifier.load(); } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.userErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
