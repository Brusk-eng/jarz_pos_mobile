import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/user_error_message.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/posting_date_confirmation_dialog.dart';
import '../../../core/network/user_service.dart';
import '../data/stock_handover_models.dart';
import '../data/stock_transfer_service.dart';
import '../state/handover_badge.dart';
import '../state/stock_handover_providers.dart';
import 'widgets/stock_handover_view.dart';
import 'widgets/stock_transfer_history.dart';

/// Stock Transfer: the manager's full transfer UI plus stock handovers.
///
/// Who sees what is decided by `get_context` (the role gate stands in until it
/// answers): a transfer manager gets two tabs — the full transfer and the
/// handovers — and everyone else (the branch on shift, the production team)
/// gets the handover view alone. Every endpoint re-checks on the server.
class StockTransferScreen extends ConsumerStatefulWidget {
  const StockTransferScreen({super.key, this.initialTab});

  /// `handovers` opens a manager on the Handovers tab (where a
  /// `stock_handover` push lands). Ignored for everyone else.
  final String? initialTab;

  @override
  ConsumerState<StockTransferScreen> createState() =>
      _StockTransferScreenState();
}

class _StockTransferScreenState extends ConsumerState<StockTransferScreen>
    with SingleTickerProviderStateMixin {
  // Owned here (not a DefaultTabController) so a push tap that re-opens this
  // already-mounted screen with `?tab=handovers` can still move the tab:
  // the route's widget is updated, not rebuilt from scratch.
  //
  // Created in initState, not lazily: a non-manager never reads it, and a
  // lazy `late final` would first run inside dispose() and create a ticker
  // while the state is being torn down.
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'handovers' ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant StockTransferScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab == 'handovers' &&
        oldWidget.initialTab != 'handovers') {
      _tabs.animateTo(1);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ctxAsync = ref.watch(stockHandoverContextProvider);
    final roleManager = ref.watch(canAccessStockTransferProvider);
    final handoverCtx = ctxAsync.valueOrNull;
    final canManage = handoverCtx?.canManage ?? roleManager;

    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.stockTransferTitle)),
        drawer: const AppDrawer(),
        body: const StockHandoverView(),
      );
    }

    final profile = ref.watch(handoverSelectedProfileProvider);
    // Only what a manager is actually awaited on: rows they can answer, plus
    // the receipts waiting on the Transit board.
    final waiting = handoverCtx == null
        ? 0
        : handoverBadgeCount(
            ref
                .watch(stockHandoverListsProvider(
                    handoverListQueryFor(handoverCtx, profile)))
                .valueOrNull,
            myWarehouses: [for (final s in handoverCtx.mySides) s.warehouse],
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.stockTransferTitle),
        actions: [
          IconButton(
            tooltip: l10n.stockTransferHistoryTitle,
            icon: const Icon(Icons.history),
            onPressed: () => StockTransferHistory.show(context, ref),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.stockHandoverTabTransfer),
            Tab(
              child: Badge(
                isLabelVisible: waiting > 0,
                label: Text('$waiting'),
                offset: const Offset(14, -6),
                child: Text(l10n.stockHandoverTabHandovers),
              ),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabs,
        // The full transfer lists scroll vertically only, but a stray
        // horizontal swipe must not throw away a half-built transfer view.
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          _FullTransferPanel(),
          StockHandoverView(),
        ],
      ),
    );
  }
}

/// The manager's full transfer: source/target, search, bulk add, posting date.
/// For a pair that touches a branch, `submit_transfer` now creates a pending
/// handover instead of posting.
class _FullTransferPanel extends ConsumerStatefulWidget {
  const _FullTransferPanel();

  @override
  ConsumerState<_FullTransferPanel> createState() => _FullTransferPanelState();
}

class _FullTransferPanelState extends ConsumerState<_FullTransferPanel>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? sourceProfile;
  String? targetProfile;
  String? sourceWarehouse;
  String? targetWarehouse;
  String? itemGroup;
  String search = '';
  // null => today, and no explicit clock time: the server stamps its own.
  // Non-null always carries a time the operator picked, because the picker
  // asks for both halves or returns nothing.
  DateTime? postingDate;

  /// A submit is in flight: blocks a second tap from creating a second
  /// handover while the first reply is still on its way.
  bool _submitting = false;

  /// A JARZ Manager's "Post now (no confirmation)" switch for a branch pair:
  /// on by default, only shown when `get_context` says `can_post_direct`.
  bool _postDirect = true;

  // Keep the latest search results to enable bulk-add/select-all actions
  List<Map<String, dynamic>> currentItems = [];

  final List<Map<String, dynamic>> lines = [];
  StateSetter? _sheetSetState;

  @override
  void dispose() {
    for (final l in lines) {
      try {
        (l['qtyCtrl'] as TextEditingController?)?.dispose();
      } catch (e, stack) {
        debugPrint('StockTransferScreen dispose error: $e');
        debugPrintStack(stackTrace: stack);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final isPhone = ResponsiveUtils.isPhone(context);
    final padding = ResponsiveUtils.getResponsivePadding(context, small: 10, medium: 12, large: 12);
    // Rebuild once get_context arrives: it decides whether the pair is a
    // branch handover (F8).
    ref.watch(stockHandoverContextProvider);
    final pending = _isPendingFlow;
    final showDirectSwitch = _touchesBranch() && _canPostDirect;

    final leftPanel = Padding(
      padding: padding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildBranchSelectors(),
        const SizedBox(height: 8),
        if (showDirectSwitch) _buildPostDirectSwitch(),
        if (pending) _buildPendingNote() else _buildDatePickerRow(),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l10n.commonSearchItems),
              onChanged: (v) => setState(() => search = v),
            ),
          ),
          const SizedBox(width: 8),
          _GroupPicker(
            onPicked: (g) => setState(() => itemGroup = g),
            initial: itemGroup,
          ),
          const SizedBox(width: 8),
          _BulkActionsButton(
            onAddAll: _onAddAllResults,
            onAddGroup: itemGroup == null ? null : _onAddGroup,
          ),
        ]),
        const SizedBox(height: 8),
        Expanded(child: _buildItemResults()),
      ]),
    );

    if (isPhone) {
      // A nested Scaffold only to host the lines FAB inside this tab; the app
      // bar and drawer belong to the screen around it.
      return Scaffold(
        body: leftPanel,
        floatingActionButton: Badge(
          isLabelVisible: lines.isNotEmpty,
          label: Text('${lines.length}'),
          child: FloatingActionButton(
            onPressed: _openTransferLinesSheet,
            tooltip: l10n.stockTransferLinesTitle(lines.length),
            child: const Icon(Icons.inventory_2),
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: leftPanel,
          ),
          Container(width: 1, color: Colors.grey.shade300),
          Expanded(
            flex: 2,
            child: Padding(
              padding: padding,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.inventory_2),
                  const SizedBox(width: 8),
                  Text(l10n.stockTransferLinesTitle(lines.length), style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  if (postingDate != null && !pending)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8.0),
                      child: Chip(label: Text(l10n.stockTransferPostingChip(formatPostingDateTimeForDisplay(context, postingDate!)))),
                    ),
                  ElevatedButton.icon(
                    onPressed: _canSubmit() ? _submit : null,
                    icon: const Icon(Icons.send),
                    label: Text(l10n.stockTransferSubmit),
                  )
                ]),
                const SizedBox(height: 8),
                Expanded(child: _buildLinesList()),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openTransferLinesSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: ResponsiveUtils.getCartBottomSheetInitialSize(context),
          minChildSize: ResponsiveUtils.getCartBottomSheetMinSize(context),
          maxChildSize: ResponsiveUtils.getCartBottomSheetMaxSize(context),
          expand: false,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (_, setSheetState) {
                _sheetSetState = setSheetState;
                final l10n = context.l10n;
                final colorScheme = Theme.of(context).colorScheme;
                return Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.stockTransferLinesTitle(lines.length),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (postingDate != null && !_isPendingFlow)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(end: 8.0),
                                child: Chip(label: Text(l10n.stockTransferPostingChip(formatPostingDateTimeForDisplay(context, postingDate!)))),
                              ),
                            ElevatedButton.icon(
                              onPressed: _canSubmit()
                                  ? () async {
                                      await _submit();
                                      setSheetState(() {});
                                    }
                                  : null,
                              icon: const Icon(Icons.send),
                              label: Text(l10n.stockTransferSubmit),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: lines.isEmpty
                            ? Center(child: Text(l10n.stockTransferNoLines))
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                itemCount: lines.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  if (i >= lines.length) return const SizedBox.shrink();
                                  return _buildTransferLineItem(lines[i], i, onChanged: () => setSheetState(() {}));
                                },
                              ),
                      ),
                      SizedBox(height: 16 + MediaQuery.paddingOf(sheetCtx).bottom),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() => _sheetSetState = null);
  }

  Widget _buildTransferLineItem(Map<String, dynamic> l, int i, {required VoidCallback onChanged}) {
    final l10n = context.l10n;
    final qty = (l['qty'] as num?)?.toDouble() ?? 0;
    final srcB = (l['src_before'] as num?)?.toDouble() ?? 0;
    final dstB = (l['dst_before'] as num?)?.toDouble() ?? 0;
    final reservedSrc = (l['reserved_src'] as num?)?.toDouble() ?? 0;
    final reservedDst = (l['reserved_dst'] as num?)?.toDouble() ?? 0;
    l['qtyCtrl'] ??= TextEditingController(text: qty.toStringAsFixed(2));
    final TextEditingController qtyCtrl = l['qtyCtrl'] as TextEditingController;
    final srcAfter = srcB - qty;
    final dstAfter = dstB + qty;
    final beforeBuffer = StringBuffer(l10n.stockTransferBeforeBase(srcB.toStringAsFixed(2), dstB.toStringAsFixed(2)));
    if (reservedSrc > 0) beforeBuffer.write(l10n.stockTransferReservedSource(reservedSrc.toStringAsFixed(2)));
    if (reservedDst > 0) beforeBuffer.write(l10n.stockTransferReservedTarget(reservedDst.toStringAsFixed(2)));
    return ListTile(
      title: Text(l10n.commonNameWithCode(l['item_name'] as String, l['item_code'] as String)),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(beforeBuffer.toString()),
        Text(l10n.stockTransferAfterBase(srcAfter.toStringAsFixed(2), dstAfter.toStringAsFixed(2))),
        const SizedBox(height: 6),
        Row(children: [
          Text(l10n.commonQtyLabel),
          const SizedBox(width: 6),
          SizedBox(
            width: 28, height: 28,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove),
              onPressed: () {
                double newQty = qty - 1;
                if (newQty < 0) newQty = 0;
                setState(() { l['qty'] = newQty; qtyCtrl.text = newQty.toStringAsFixed(2); });
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 90,
            child: TextFormField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) {
                final q = double.tryParse(v) ?? qty; setState(() => l['qty'] = q); onChanged();
              },
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 28, height: 28,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add),
              onPressed: () {
                final newQty = qty + 1;
                setState(() { l['qty'] = newQty; qtyCtrl.text = newQty.toStringAsFixed(2); });
                onChanged();
              },
            ),
          ),
        ]),
      ]),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () {
          setState(() {
            try { (l['qtyCtrl'] as TextEditingController?)?.dispose(); } catch (_) {}
            lines.removeAt(i);
          });
          onChanged();
          _sheetSetState?.call(() {});
        },
      ),
    );
  }

  /// True when either side of the chosen pair is a branch: the transfer then
  /// becomes a handover the other side confirms, and is posted at that moment,
  /// so there is no posting date to pick or confirm. Mirrors the server's
  /// `touches_branch`: both sides must be known sides.
  bool _touchesBranch() {
    final source = sourceWarehouse;
    final target = targetWarehouse;
    if (source == null || target == null) return false;
    final ctx = ref.read(stockHandoverContextProvider).valueOrNull;
    // Before get_context answers: this form only offers POS Profile
    // warehouses, which are branches.
    if (ctx == null) return true;
    final known = {
      for (final side in [...ctx.mySides, ...ctx.counterparts])
        side.warehouse: side,
    };
    final a = known[source];
    final b = known[target];
    if (a == null || b == null) return false;
    return a.isBranch || b.isBranch;
  }

  /// `get_context` granted the one-step post (JARZ Manager).
  bool get _canPostDirect =>
      ref.read(stockHandoverContextProvider).valueOrNull?.canPostDirect ??
      false;

  /// The transfer becomes a pending handover: a branch pair, unless a manager
  /// who may post direct left "Post now" on. Decides the pending note vs the
  /// posting date, and what [_submit] sends.
  bool get _isPendingFlow =>
      _touchesBranch() && !(_canPostDirect && _postDirect);

  Widget _buildPostDirectSwitch() {
    final l10n = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(l10n.stockTransferPostDirectTitle),
      subtitle: Text(l10n.stockTransferPostDirectSubtitle),
      value: _postDirect,
      onChanged: (v) {
        setState(() => _postDirect = v);
        _sheetSetState?.call(() {});
      },
    );
  }

  Widget _buildPendingNote() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.info_outline, size: 18, color: theme.colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.stockTransferBecomesOfficialNote,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
      ],
    );
  }

  bool _canSubmit() {
    if (_submitting) return false;
    if (sourceWarehouse == null || targetWarehouse == null) return false;
    if (sourceWarehouse == targetWarehouse) return false;
    return lines.any((l) => ((l['qty'] as num?)?.toDouble() ?? 0) > 0);
  }

  Widget _buildBranchSelectors() {
    final l10n = context.l10n;
    final service = ref.read(stockTransferServiceProvider);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: service.listPosProfiles(),
      builder: (context, snap) {
        final profiles = snap.data ?? [];
        // compute invalid pair warning
        final sameProfile = sourceProfile != null && targetProfile != null && sourceProfile == targetProfile;
        return Row(children: [
          Expanded(child: _profileDropdown(l10n.stockTransferProfileLabelSource, profiles, sourceProfile, (v) {
            setState(() {
              sourceProfile = v;
              sourceWarehouse = profiles.firstWhere((p) => p['name'] == v, orElse: () => const {})['warehouse'] as String?;
              // If same selection occurs, clear target to force reselect
              if (targetProfile == sourceProfile) {
                targetProfile = null;
                targetWarehouse = null;
              }
            });
          })),
          const SizedBox(width: 8),
          Expanded(child: _profileDropdown(l10n.stockTransferProfileLabelTarget, profiles, targetProfile, (v) {
            setState(() {
              targetProfile = v;
              targetWarehouse = profiles.firstWhere((p) => p['name'] == v, orElse: () => const {})['warehouse'] as String?;
              if (targetProfile == sourceProfile) {
                // prevent same profile; revert selection
                targetProfile = null;
                targetWarehouse = null;
              }
            });
          })),
          if (sameProfile) ...[
            const SizedBox(width: 8),
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 4),
            Text(l10n.stockTransferProfilesMustDiffer, style: const TextStyle(color: Colors.red)),
          ]
        ]);
      },
    );
  }

  Widget _profileDropdown(String label, List<Map<String, dynamic>> profiles, String? value, ValueChanged<String?> onChanged) {
    final l10n = context.l10n;
    return InputDecorator(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(l10n.stockTransferProfilePlaceholder),
          items: [
            for (final p in profiles)
              DropdownMenuItem<String>(
                value: p['name'] as String,
                child: Text(
                  l10n.stockTransferProfileOption(
                    p['name'] as String,
                    (p['warehouse'] as String?) ?? l10n.stockTransferProfileWarehouseFallback,
                  ),
                ),
              )
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildItemResults() {
    final l10n = context.l10n;
    if (sourceWarehouse == null || targetWarehouse == null) {
      return Center(child: Text(l10n.stockTransferSelectBranches));
    }
    if (sourceProfile != null && targetProfile != null && sourceProfile == targetProfile) {
      return Center(child: Text(l10n.stockTransferSameProfile)); 
    }
    final service = ref.read(stockTransferServiceProvider);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: service.searchItemsWithStock(
        sourceWarehouse: sourceWarehouse!,
        targetWarehouse: targetWarehouse!,
        search: search.isEmpty ? null : search,
        itemGroup: itemGroup,
      ),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        final items = snap.data ?? [];
        // Save for bulk actions
        currentItems = items;
  if (items.isEmpty) return Center(child: Text(l10n.commonNoItems));
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final it = items[i];
            final code = it['item_code'];
            final name = it['item_name'] ?? code;
            final src = (it['qty_source'] as num?)?.toDouble() ?? 0;
            final dst = (it['qty_target'] as num?)?.toDouble() ?? 0;
            final reservedSrc = (it['reserved_source'] as num?)?.toDouble() ?? 0;
            final reservedDst = (it['reserved_target'] as num?)?.toDouble() ?? 0;
            final isPos = (it['pos_item'] == 1);
            final availability = StringBuffer(
              l10n.stockTransferAvailability(src.toString(), dst.toString()),
            );
            if (reservedSrc > 0) {
              availability.write(l10n.stockTransferReservedSource(reservedSrc.toString()));
            }
            if (reservedDst > 0) {
              availability.write(l10n.stockTransferReservedTarget(reservedDst.toString()));
            }
            if (isPos) {
              availability.write(l10n.stockTransferPosTag);
            }
            return ListTile(
              title: Text(l10n.commonNameWithCode(name, code)),
              subtitle: Text(availability.toString()),
              trailing: ElevatedButton(
                onPressed: () {
                  setState(() {
                    lines.add({
                      'item_code': code,
                      'item_name': name,
                      'uom': it['stock_uom'] ?? 'Nos',
                      'src_before': src,
                      'dst_before': dst,
                      'reserved_src': reservedSrc,
                      'reserved_dst': reservedDst,
                      'qty': 1.0,
                      'qtyCtrl': TextEditingController(text: '1.00'),
                    });
                  });
                },
                child: Text(l10n.commonAdd),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDatePickerRow() {
    final l10n = context.l10n;
    final label = postingDate == null
        ? l10n.stockTransferPostingToday
        : l10n.stockTransferPostingDate(
            formatPostingDateTimeForDisplay(context, postingDate!));
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final initial = postingDate ?? now;
            final picked = await pickPostingDateTime(
              context,
              initial: initial,
              firstDate: DateTime(now.year - 5),
              lastDate: DateTime(now.year + 5),
            );
            // Kept whole: truncating to the day here is what put a backdated
            // transfer at midnight regardless of the time just chosen.
            if (picked != null) {
              setState(() => postingDate = picked);
            }
          },
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(label),
        ),
        if (postingDate != null) ...[
          const SizedBox(width: 8),
          IconButton(
            tooltip: l10n.stockTransferUseToday,
            onPressed: () => setState(() => postingDate = null),
            icon: const Icon(Icons.close),
          ),
        ]
      ],
    );
  }

  Widget _buildLinesList() {
    final l10n = context.l10n;
    if (lines.isEmpty) return Center(child: Text(l10n.stockTransferNoLines));
    return ListView.separated(
      itemCount: lines.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final l = lines[i];
        final qty = (l['qty'] as num?)?.toDouble() ?? 0;
        final srcB = (l['src_before'] as num?)?.toDouble() ?? 0;
        final dstB = (l['dst_before'] as num?)?.toDouble() ?? 0;
        final reservedSrc = (l['reserved_src'] as num?)?.toDouble() ?? 0;
        final reservedDst = (l['reserved_dst'] as num?)?.toDouble() ?? 0;
        l['qtyCtrl'] ??= TextEditingController(text: qty.toStringAsFixed(2));
        final TextEditingController qtyCtrl = l['qtyCtrl'] as TextEditingController;
        final srcAfter = srcB - qty;
        final dstAfter = dstB + qty;
        final beforeBuffer = StringBuffer(
          l10n.stockTransferBeforeBase(srcB.toStringAsFixed(2), dstB.toStringAsFixed(2)),
        );
        if (reservedSrc > 0) {
          beforeBuffer.write(l10n.stockTransferReservedSource(reservedSrc.toStringAsFixed(2)));
        }
        if (reservedDst > 0) {
          beforeBuffer.write(l10n.stockTransferReservedTarget(reservedDst.toStringAsFixed(2)));
        }
        return ListTile(
          title: Text(l10n.commonNameWithCode(l['item_name'] as String, l['item_code'] as String)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(beforeBuffer.toString()),
            Text(l10n.stockTransferAfterBase(srcAfter.toStringAsFixed(2), dstAfter.toStringAsFixed(2))),
            const SizedBox(height: 6),
            Row(children: [
              Text(l10n.commonQtyLabel),
              const SizedBox(width: 6),
              SizedBox(
                width: 28, height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    double newQty = qty - 1;
                    if (newQty < 0) newQty = 0;
                    setState(() {
                      l['qty'] = newQty;
                      qtyCtrl.text = newQty.toStringAsFixed(2);
                    });
                  },
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 90,
                child: TextFormField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    final q = double.tryParse(v) ?? qty; setState(() => l['qty'] = q);
                  },
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 28, height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final newQty = qty + 1;
                    setState(() {
                      l['qty'] = newQty;
                      qtyCtrl.text = newQty.toStringAsFixed(2);
                    });
                  },
                ),
              ),
            ]),
          ]),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                try {
                  (l['qtyCtrl'] as TextEditingController?)?.dispose();
                } catch (e, stack) {
                  debugPrint('StockTransferScreen remove line dispose error: $e');
                  debugPrintStack(stackTrace: stack);
                }
                lines.removeAt(i);
              });
              _sheetSetState?.call(() {});
            },
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit()) return;
    final service = ref.read(stockTransferServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    // A branch handover is posted when the other side confirms, so it has no
    // posting date and nothing to confirm here (F8). A manager's one-step
    // post of a branch pair is posted now, so it keeps the posting date.
    final pending = _isPendingFlow;
    final direct = !pending && _touchesBranch();
    setState(() => _submitting = true);
    _sheetSetState?.call(() {});
    try {
      final payload = [for (final l in lines) if (((l['qty'] as num?)?.toDouble() ?? 0) > 0) {'item_code': l['item_code'], 'qty': (l['qty'] as num).toDouble()}];
      String? postingDateStr;
      if (!pending) {
        final chosen = postingDate;
        final resolvedPostingDate = resolvePostingDateOrToday(chosen);
        final confirmedPostingDate = await confirmPostingDatesBeforeSubmit(
          context,
          dates: [chosen ?? resolvedPostingDate],
          includeTime: chosen != null,
        );
        if (!confirmedPostingDate || !mounted) {
          return;
        }
        postingDateStr = chosen == null
            ? formatPostingDateForApi(resolvedPostingDate)
            : formatPostingDateTimeForApi(chosen);
      }
      final res = await service.submitTransfer(
        sourceWarehouse: sourceWarehouse!,
        targetWarehouse: targetWarehouse!,
        lines: payload,
        postingDate: postingDateStr,
        direct: direct,
      );
      final outcome = TransferSubmitOutcome.fromJson(res);
      // A pair touching a branch is a pending handover now: nothing has moved
      // until the other side confirms, so there is no entry to name.
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            outcome.pending
                ? l10n.stockTransferSentPending(outcome.handover ?? '-')
                : l10n.stockTransferTransferCreated(outcome.stockEntry ?? '-'),
          ),
        ),
      );
      if (outcome.pending) ref.invalidate(stockHandoverListsProvider);
      if (!mounted) return;
      setState(() {
        for (final l in lines) {
          try {
            (l['qtyCtrl'] as TextEditingController?)?.dispose();
          } catch (e, stack) {
            debugPrint('StockTransferScreen submit dispose error: $e');
            debugPrintStack(stackTrace: stack);
          }
        }
        lines.clear();
      });
      _sheetSetState?.call(() {});
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(context.userErrorMessage(e))));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
        _sheetSetState?.call(() {});
      }
    }
  }

  Future<void> _onAddAllResults() async {
    if (currentItems.isEmpty) return;
    final qty = await _promptBulkQty(context);
    if (qty == null || qty <= 0) return;
    setState(() {
      for (final it in currentItems) {
        _addOrIncrementLineFromItem(it, qty);
      }
    });
  }

  Future<void> _onAddGroup() async {
    if (itemGroup == null || sourceWarehouse == null || targetWarehouse == null) return;
    final qty = await _promptBulkQty(context);
    if (qty == null || qty <= 0) return;
    final service = ref.read(stockTransferServiceProvider);
    try {
      final items = await service.searchItemsWithStock(
        sourceWarehouse: sourceWarehouse!,
        targetWarehouse: targetWarehouse!,
        itemGroup: itemGroup,
      );
      if (!mounted) return;
      setState(() {
        for (final it in items) {
          _addOrIncrementLineFromItem(it, qty);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.userErrorMessage(e))));
    }
  }

  void _addOrIncrementLineFromItem(Map<String, dynamic> it, double addQty) {
    final code = it['item_code'];
    final idx = lines.indexWhere((l) => l['item_code'] == code);
    final name = it['item_name'] ?? code;
    final src = (it['qty_source'] as num?)?.toDouble() ?? 0;
    final dst = (it['qty_target'] as num?)?.toDouble() ?? 0;
    final reservedSrc = (it['reserved_source'] as num?)?.toDouble() ?? 0;
    final reservedDst = (it['reserved_target'] as num?)?.toDouble() ?? 0;
    if (idx >= 0) {
      final l = lines[idx];
      final newQty = ((l['qty'] as num?)?.toDouble() ?? 0) + addQty;
      l['qty'] = newQty;
      (l['qtyCtrl'] as TextEditingController?)?.text = newQty.toStringAsFixed(2);
    } else {
      lines.add({
        'item_code': code,
        'item_name': name,
        'uom': it['stock_uom'] ?? 'Nos',
        'src_before': src,
        'dst_before': dst,
        'reserved_src': reservedSrc,
        'reserved_dst': reservedDst,
        'qty': addQty,
        'qtyCtrl': TextEditingController(text: addQty.toStringAsFixed(2)),
      });
    }
  }

  Future<double?> _promptBulkQty(BuildContext context) async {
    final ctrl = TextEditingController(text: '1.00');
    final res = await showDialog<double>(
      context: context,
      builder: (ctx) {
        final dialogL10n = ctx.l10n;
        return AlertDialog(
          title: Text(dialogL10n.stockTransferQuickQuantity),
          content: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: dialogL10n.stockTransferQuantityPerItem),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: Text(dialogL10n.commonCancel)),
            ElevatedButton(onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              Navigator.of(ctx).pop(v);
            }, child: Text(dialogL10n.commonAdd)),
          ],
        );
      },
    );
    return res;
  }
}

class _GroupPicker extends ConsumerStatefulWidget {
  const _GroupPicker({required this.onPicked, this.initial});
  final ValueChanged<String?> onPicked;
  final String? initial;
  @override
  ConsumerState<_GroupPicker> createState() => _GroupPickerState();
}

class _GroupPickerState extends ConsumerState<_GroupPicker> {
  String? selected;
  List<Map<String, dynamic>> groups = const [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    selected = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final service = ref.read(stockTransferServiceProvider);
      groups = await service.listItemGroups();
    } catch (e, stack) {
      debugPrint('StockTransferScreen group load error: $e');
      debugPrintStack(stackTrace: stack);
    }
    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DropdownButton<String?>(
      hint: Text(l10n.stockTransferItemGroup),
      value: selected,
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(l10n.stockTransferAllGroups)),
        for (final g in groups)
          DropdownMenuItem<String?>(value: g['name'] as String, child: Text(g['name'] as String)),
      ],
      onChanged: (v) {
        setState(() => selected = v);
        widget.onPicked(v);
      },
    );
  }
}

class _BulkActionsButton extends StatelessWidget {
  const _BulkActionsButton({required this.onAddAll, this.onAddGroup});
  final VoidCallback onAddAll;
  final VoidCallback? onAddGroup;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: onAddAll,
          icon: const Icon(Icons.select_all),
          label: Text(l10n.stockTransferAddAll),
        ),
        const SizedBox(width: 6),
        OutlinedButton.icon(
          onPressed: onAddGroup,
          icon: const Icon(Icons.playlist_add),
          label: Text(l10n.stockTransferAddGroup),
        ),
      ],
    );
  }
}
