import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/business_constants.dart';
import '../providers/kanban_provider.dart';
import '../models/kanban_models.dart';
import '../widgets/kanban_column_widget.dart';
import '../widgets/invoice_card_widget.dart';
import '../widgets/kanban_filters_widget.dart';
import '../widgets/payment_receipt_list_dialog.dart';
import '../../pos/state/pos_notifier.dart';
import '../../../core/router.dart';
import '../../pos/presentation/widgets/courier_balances_dialog.dart';
import '../../../core/network/courier_service.dart';
import '../../instapay_reconciliation/data/instapay_reconciliation_service.dart';
import '../../../core/utils/responsive_utils.dart';
import '../widgets/settlement_preview_dialog.dart';
import '../../printing/pos_printer_provider.dart';
import '../../printing/printer_status.dart';
import '../../trips/providers/trip_provider.dart';
import '../../trips/widgets/create_trip_dialog.dart';
import '../../trips/widgets/trip_group_card.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/branch_filter_dialog.dart';
import '../../../core/widgets/ofd_shortage_dialog.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/user_error_message.dart';
import '../../../core/localization/localized_display_mappers.dart';
import '../../../core/utils/territory_label.dart';
import '../../approvals/state/pending_approvals_provider.dart';
import '../../weekly_count/presentation/widgets/weekly_count_banner.dart';

class KanbanBoardScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  /// Open the payment-receipts dialog on arrival — the side menu's
  /// "receipts to confirm" row links here (`/kanban?receipts=1`) because the
  /// dialog runs on this screen's board provider.
  final bool openReceipts;

  const KanbanBoardScreen({
    super.key,
    this.showAppBar = true,
    this.openReceipts = false,
  });

  @override
  ConsumerState<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends ConsumerState<KanbanBoardScreen> with RouteAware {
  bool _showFilters = false;

  Future<bool> _sendTripForDeliveryWithPreview(String tripName) async {
    String? shortageReason;
    try {
      final preview = await ref
          .read(tripProvider.notifier)
          .previewSendForDelivery(tripName);
      final blockingMessage = buildOfdBlockingErrorMessage(preview);
      if (blockingMessage != null && blockingMessage.isNotEmpty) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.userErrorMessage(blockingMessage))),
        );
        return false;
      }
      if (preview['requires_shortage_reason'] == true) {
        if (!mounted) return false;
        shortageReason = await showOfdShortageReasonDialog(context, preview);
        if (shortageReason == null || shortageReason.trim().isEmpty) {
          return false;
        }
      }
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.userErrorMessage(e))),
      );
      return false;
    }

    await ref.read(tripProvider.notifier).sendForDeliveryWithApproval(
      tripName,
      shortageApproved: shortageReason != null,
      shortageReason: shortageReason,
    );
    return true;
  }

  Future<String?> _previewInvoiceOfdReason(String invoiceId) async {
    final preview = await ref.read(kanbanProvider.notifier).previewOutForDelivery(invoiceId);
    final blockingMessage = buildOfdBlockingErrorMessage(preview);
    if (blockingMessage != null && blockingMessage.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.userErrorMessage(blockingMessage))),
        );
      }
      return null;
    }
    if (preview['requires_shortage_reason'] == true) {
      if (!mounted) return null;
      return showOfdShortageReasonDialog(context, preview);
    }
    return '';
  }
  bool _allowHScroll = true; // new state
  bool _posProfileDialogActive = false;
  bool _profileDialogDismissed = false; // once dismissed, don't re-prompt automatically
  late final ScrollController _horizontalScrollController;
  ProviderSubscription<PosState>? _posStateSubscription;
  DateTime? _lastBackPress;

  void _setScrollActive(bool active) {
    if (_allowHScroll == active) return;
    setState(() => _allowHScroll = active);
  }

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _posStateSubscription = ref.listenManual<PosState>(
      posNotifierProvider,
      (previous, next) {
        if (mounted) {
          _handlePosStateChange(next);
        }
      },
    );
    // On entering Kanban, refresh to fetch any new invoices created from POS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(kanbanProvider.notifier);
      notifier.loadInvoices();
      ref.read(tripProvider.notifier).loadTrips();
      // Proactively load POS profiles so branch filter is available immediately
      final posState = ref.read(posNotifierProvider);
      if (!posState.isLoading && posState.profiles.isEmpty) {
        ref.read(posNotifierProvider.notifier).loadProfiles();
      }
      _handlePosStateChange(posState);
      // Auto-refresh unconfirmed receipts badge
      ref.invalidate(unconfirmedReceiptsCountProvider);
      if (widget.openReceipts) _openReceiptsFromLink();
    });
  }

  @override
  void didUpdateWidget(covariant KanbanBoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.openReceipts && !oldWidget.openReceipts) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openReceiptsFromLink();
      });
    }
  }

  /// The dialog, opened by link. On close the link is dropped from the URL so
  /// the same menu row opens it again next time, and both receipt counts
  /// (this screen's badge and the side menu's) are re-asked.
  Future<void> _openReceiptsFromLink() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const PaymentReceiptListDialog(),
    );
    if (!mounted) return;
    ref.invalidate(unconfirmedReceiptsCountProvider);
    ref.invalidate(pendingApprovalsProvider);
    context.go(AppRoutes.kanban);
  }

  @override
  Widget build(BuildContext context) {
    final kanbanState = ref.watch(kanbanProvider);
    final isPhone = ResponsiveUtils.isPhone(context);
    
    // Listen for errors and show them as SnackBars
    ref.listen<KanbanState>(kanbanProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.error!),
                backgroundColor: Colors.red[700],
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: context.l10n.commonDismiss,
                  textColor: Colors.white,
                  onPressed: () {
                    ref.read(kanbanProvider.notifier).clearError();
                  },
                ),
              ),
            );
          }
        });
      }
    });
    // No POS profile guard here; Kanban should be usable with branch filter defaults

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.maybeOf(context);
        if (await _handleBackPress() && mounted) {
          navigator?.maybePop(result);
        }
      },
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: widget.showAppBar
          ? _buildResponsiveAppBar(context)
          : null,
        body: Column(
          children: [
            // Branch staff land here, so the weekly-count reminder does too.
            // Renders nothing unless a member branch still owes the count.
            const WeeklyCountBanner(),
            // Removed full-width branch chips to maximize kanban space; filter now in header
            if (_showFilters && !isPhone)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: KanbanFiltersWidget(
                  filters: kanbanState.filters,
                  customers: kanbanState.customers,
                  resultCount: _visibleCardCount(kanbanState),
                  isLoading: kanbanState.isLoading,
                  onFiltersChanged: (newFilters) {
                    ref.read(kanbanProvider.notifier).updateFilters(newFilters);
                  },
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final notifier = ref.read(kanbanProvider.notifier);
                  await notifier.loadInvoices();
                  ref.invalidate(unconfirmedReceiptsCountProvider);
                },
                child: _buildKanbanContent(kanbanState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route lifecycle
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute<dynamic>) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    _posStateSubscription?.close();
    _horizontalScrollController.dispose();
    // Unsubscribe
    try { routeObserver.unsubscribe(this); } catch (_) {}
    super.dispose();
  }

  // Called when coming back to this screen (e.g., from POS)
  @override
  void didPopNext() {
    // Refresh invoices and columns to pick up newly created orders
    final notifier = ref.read(kanbanProvider.notifier);
    notifier.loadInvoices();
    // Optionally refresh columns if backend added new states dynamically
    notifier.loadColumns();
  }

  /// Responsive AppBar: on phones collapses secondary actions into overflow menu.
  AppBar _buildResponsiveAppBar(BuildContext context) {
    final isPhone = ResponsiveUtils.isPhone(context);
    final unconfirmedCount = ref.watch(unconfirmedReceiptsCountProvider).maybeWhen(
      data: (n) => n,
      orElse: () => 0,
    );
    final hasUnconfirmed = unconfirmedCount > 0;
    final activeFilterCount = ref.watch(
      kanbanProvider.select((s) => s.filters.activeCount),
    );

    // Primary actions always visible
    final primaryActions = <Widget>[
      IconButton(
        tooltip: context.l10n.kanbanRefreshOrders,
        icon: const Icon(Icons.refresh),
        visualDensity: isPhone ? VisualDensity.compact : VisualDensity.standard,
        onPressed: () async {
          final l10n = context.l10n;
          final notifier = ref.read(kanbanProvider.notifier);
          final messenger = ScaffoldMessenger.of(context);
          await notifier.loadInvoices();
          if (!context.mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.kanbanOrdersRefreshed),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
      const _BranchFilterButton(),
      if (!isPhone) _buildPrinterChip(context),
      // Badged so an active filter can never be the silent reason the board
      // looks empty — the commonest "the board is broken" report was a filter
      // someone else had left on.
      IconButton(
        tooltip: _showFilters ? context.l10n.kanbanHideFilters : context.l10n.kanbanShowFilters,
        icon: Badge(
          isLabelVisible: activeFilterCount > 0,
          label: Text('$activeFilterCount'),
          child: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
        ),
        visualDensity: isPhone ? VisualDensity.compact : VisualDensity.standard,
        onPressed: () {
          if (isPhone) {
            _showMobileFiltersSheet();
            return;
          }
          setState(() => _showFilters = !_showFilters);
        },
      ),
    ];

    // On phones, move secondary actions into overflow popup
    if (isPhone) {
      primaryActions.add(
        PopupMenuButton<String>(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.more_vert),
              if (hasUnconfirmed)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          tooltip: context.l10n.kanbanMoreActions,
          onSelected: (value) {
            switch (value) {
              case 'receipts':
                showDialog(context: context, builder: (_) => const PaymentReceiptListDialog())
                    .then((_) => ref.invalidate(unconfirmedReceiptsCountProvider));
                break;
              case 'printers':
                context.push(AppRoutes.printers);
                break;
              case 'couriers':
                showCourierBalancesDialog(context);
                break;
              case 'profile':
                context.push(AppRoutes.profile);
                break;
              case 'pos':
                context.push(AppRoutes.pos);
                break;
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'receipts',
              child: ListTile(
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.receipt_long),
                    if (hasUnconfirmed)
                      Positioned(
                        top: -4,
                        right: -6,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(context.l10n.kanbanMenuReceipts),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'printers',
              child: ListTile(
                leading: const Icon(Icons.print),
                title: Text(context.l10n.kanbanMenuPrinters),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'couriers',
              child: ListTile(
                leading: const Icon(Icons.local_shipping),
                title: Text(context.l10n.kanbanMenuCouriers),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'profile',
              child: ListTile(
                leading: const Icon(Icons.account_circle),
                title: Text(context.l10n.kanbanMenuProfile),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'pos',
              child: ListTile(
                leading: const Icon(Icons.point_of_sale),
                title: Text(context.l10n.kanbanMenuPos),
                dense: true,
              ),
            ),
          ],
        ),
      );
    } else {
      // Tablet: show all actions inline
      primaryActions.insertAll(0, [
        IconButton(
          tooltip: context.l10n.kanbanPaymentReceipts,
          icon: Badge(
            isLabelVisible: hasUnconfirmed,
            label: Text('$unconfirmedCount'),
            backgroundColor: Colors.orange,
            child: const Icon(Icons.receipt_long),
          ),
          onPressed: () {
            showDialog(context: context, builder: (ctx) => const PaymentReceiptListDialog())
                .then((_) => ref.invalidate(unconfirmedReceiptsCountProvider));
          },
        ),
      ]);
      primaryActions.addAll([
        IconButton(
          tooltip: context.l10n.kanbanCourierBalances,
          icon: const Icon(Icons.local_shipping),
          onPressed: () => showCourierBalancesDialog(context),
        ),
        IconButton(
          tooltip: context.l10n.kanbanUserProfile,
          icon: const Icon(Icons.account_circle),
          onPressed: () => context.push(AppRoutes.profile),
        ),
        IconButton(
          tooltip: context.l10n.kanbanOpenPos,
          icon: const Icon(Icons.point_of_sale),
          onPressed: () => context.push(AppRoutes.pos),
        ),
      ]);
    }

    return AppBar(
      automaticallyImplyLeading: false,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
          tooltip: context.l10n.kanbanMenu,
        ),
      ),
      title: Text(isPhone ? context.l10n.kanbanTitleShort : context.l10n.kanbanTitleFull),
      actions: primaryActions,
    );
  }

  void _showMobileFiltersSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.42,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, _) {
                final kanbanState = ref.watch(kanbanProvider);
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom,
                  ),
                  child: KanbanFiltersWidget(
                    filters: kanbanState.filters,
                    customers: kanbanState.customers,
                    resultCount: _visibleCardCount(kanbanState),
                    isLoading: kanbanState.isLoading,
                    onClose: () => Navigator.of(sheetContext).pop(),
                    onFiltersChanged: (newFilters) {
                      ref.read(kanbanProvider.notifier).updateFilters(newFilters);
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Reusable printer chip for AppBar
  Widget _buildPrinterChip(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final printer = ref.watch(posPrinterServiceProvider);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: InkWell(
            onTap: () => context.push(AppRoutes.printers),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: () {
                  switch (printer.unifiedStatus) {
                    case PrinterUnifiedStatus.connectedBle:
                    case PrinterUnifiedStatus.connectedClassic:
                      return Colors.green.withValues(alpha: 0.15);
                    case PrinterUnifiedStatus.connecting:
                      return Colors.orange.withValues(alpha: 0.15);
                    case PrinterUnifiedStatus.error:
                      return Colors.red.withValues(alpha: 0.18);
                    case PrinterUnifiedStatus.disconnected:
                      return Colors.red.withValues(alpha: 0.15);
                  }
                }(),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: () {
                    switch (printer.unifiedStatus) {
                      case PrinterUnifiedStatus.connectedBle:
                      case PrinterUnifiedStatus.connectedClassic:
                        return Colors.green;
                      case PrinterUnifiedStatus.connecting:
                        return Colors.orange;
                      case PrinterUnifiedStatus.error:
                        return Colors.red;
                      case PrinterUnifiedStatus.disconnected:
                        return Colors.red;
                    }
                  }().withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.print, size: 16, color: () {
                    switch (printer.unifiedStatus) {
                      case PrinterUnifiedStatus.connectedBle:
                      case PrinterUnifiedStatus.connectedClassic:
                        return Colors.greenAccent;
                      case PrinterUnifiedStatus.connecting:
                        return Colors.orangeAccent;
                      case PrinterUnifiedStatus.error:
                      case PrinterUnifiedStatus.disconnected:
                        return Colors.redAccent;
                    }
                  }()),
                  const SizedBox(width: 6),
                  Text(
                    () {
                      switch (printer.unifiedStatus) {
                        case PrinterUnifiedStatus.connectedBle:
                          return context.l10n.kanbanPrinterBle;
                        case PrinterUnifiedStatus.connectedClassic:
                          return context.l10n.kanbanPrinterClassic;
                        case PrinterUnifiedStatus.connecting:
                          return context.l10n.kanbanPrinterConnecting;
                        case PrinterUnifiedStatus.error:
                          return context.userErrorMessage(printer.lastErrorMessage);
                        case PrinterUnifiedStatus.disconnected:
                          return context.l10n.kanbanPrinterNotConnected;
                      }
                    }(),
                    style: TextStyle(
                      color: () {
                        switch (printer.unifiedStatus) {
                          case PrinterUnifiedStatus.connectedBle:
                          case PrinterUnifiedStatus.connectedClassic:
                            return Colors.green;
                          case PrinterUnifiedStatus.connecting:
                            return Colors.orange;
                          case PrinterUnifiedStatus.error:
                          case PrinterUnifiedStatus.disconnected:
                            return Colors.red;
                        }
                      }(),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKanbanContent(KanbanState kanbanState) {
    final tripState = ref.watch(tripProvider);
    final hasInvoices = kanbanState.invoices.values.any((list) => list.isNotEmpty);

    if (kanbanState.isLoading && kanbanState.columns.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

  if (kanbanState.error != null && kanbanState.columns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              context.l10n.kanbanErrorLoadingData,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              kanbanState.error!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(kanbanProvider.notifier).clearError();
                ref.read(kanbanProvider.notifier).loadInvoices();
              },
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (kanbanState.columns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              context.l10n.kanbanNoColumnsConfigured,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.kanbanEnsureStateField,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(kanbanProvider.notifier).loadKanbanData();
              },
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (!hasInvoices && kanbanState.filters.hasFilters) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.masterOrdersNoResults,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.kanbanFilterActiveCount(
                  kanbanState.filters.activeCount,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () {
                  ref.read(kanbanProvider.notifier).updateFilters(const KanbanFilters());
                  if (!_showFilters) {
                    setState(() => _showFilters = true);
                  }
                },
                child: Text(context.l10n.kanbanFilterClearAll),
              ),
            ],
          ),
        ),
      );
    }

    // In Progress (or a legacy Ready column from an older backend) is where
    // orders are multi-selected and grouped into delivery trips.
    final tripStagingColumnId = tripStagingKanbanColumn(kanbanState.columns)?.id;

    final board = Stack(
      children: [
        ScrollConfiguration(
          behavior: const _KanbanScrollBehavior(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boardPadding = ResponsiveUtils.getKanbanBoardPadding(context);
              final columnGap = ResponsiveUtils.getKanbanColumnGap(context);
              final columnWidth = ResponsiveUtils.getKanbanColumnWidth(context);
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(), // Allow pull-to-refresh
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Scrollbar(
                    controller: _horizontalScrollController,
                    thumbVisibility: true,
                    thickness: 8,
                    radius: const Radius.circular(12),
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: _allowHScroll ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                      padding: boardPadding,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final column in kanbanState.columns) ...[
                            Builder(
                              builder: (context) {
                                final invoices = kanbanState.invoices[column.id] ?? const <InvoiceCard>[];
                                final isTripStaging =
                                    tripStagingColumnId != null && column.id == tripStagingColumnId;
                                final isOFD = _isOutForDeliveryColumn(column);
                                return Container(
                                  width: columnWidth,
                                  margin: EdgeInsetsDirectional.only(end: columnGap),
                                  child: KanbanColumnWidget(
                                    column: column,
                                    invoices: invoices,
                                    canAcceptMove: _canAcceptCardMove,
                                    onCardMoved: (invoiceId, fromColumnId, newColumnId) =>
                                        _handleCardMove(invoiceId, fromColumnId, newColumnId),
                                    onCardPointerActive: (active) => _setScrollActive(!active),
                                    onMobileMoveRequested: ResponsiveUtils.isPhone(context)
                                      ? (invoice, fromColumnId) => _showMobileMoveSheet(invoice, fromColumnId)
                                      : null,
                                    headerAction: isTripStaging
                                        ? IconButton(
                                            tooltip: tripState.multiSelectActive
                                                ? context.l10n.kanbanExitSelection
                                                : context.l10n.kanbanSelectOrders,
                                            icon: Icon(
                                              tripState.multiSelectActive ? Icons.close : Icons.checklist,
                                              size: 18,
                                            ),
                                            onPressed: () {
                                              ref.read(tripProvider.notifier).toggleMultiSelect();
                                            },
                                          )
                                        : null,
                                    selectionMode: isTripStaging && tripState.multiSelectActive,
                                    selectedInvoiceIds: isTripStaging ? tripState.selectedInvoiceIds : const <String>{},
                                    onToggleInvoiceSelection: isTripStaging
                                        ? (id) => ref.read(tripProvider.notifier).toggleInvoiceSelection(id)
                                        : null,
                                    customListBuilder: isOFD
                                        ? (ctx, ofdInvoices) => _buildOFDTripGroupedList(ofdInvoices, tripState)
                                        : (isTripStaging && !tripState.multiSelectActive)
                                            ? (ctx, stagingInvoices) =>
                                                _buildTripStagingGroupedList(stagingInvoices, tripState, column.id)
                                            : null,
                                  ),
                                );
                              },
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (tripState.multiSelectActive) _buildTripSelectionBar(kanbanState, tripState),
      ],
    );

    if (!ResponsiveUtils.isPhone(context)) {
      return board;
    }

    return Column(
      children: [
        _buildMobileColumnJumpStrip(kanbanState),
        Expanded(child: board),
      ],
    );
  }

  Widget _buildMobileColumnJumpStrip(KanbanState kanbanState) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 1,
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          itemCount: kanbanState.columns.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final column = kanbanState.columns[index];
            final count = kanbanState.invoices[column.id]?.length ?? 0;
            return ActionChip(
              visualDensity: VisualDensity.compact,
              avatar: CircleAvatar(
                radius: 10,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Text(
                  '$count',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
              label: Text(
                localizedKanbanState(context, column.name),
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () => _scrollToKanbanColumn(index),
            );
          },
        ),
      ),
    );
  }

  void _scrollToKanbanColumn(int index) {
    if (!_horizontalScrollController.hasClients) return;
    final columnWidth = ResponsiveUtils.getKanbanColumnWidth(context);
    final columnGap = ResponsiveUtils.getKanbanColumnGap(context);
    final target = index * (columnWidth + columnGap);
    final maxScroll = _horizontalScrollController.position.maxScrollExtent;
    _horizontalScrollController.animateTo(
      target.clamp(0.0, maxScroll).toDouble(),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  /// Total cards on the board — what the filter bar reports as the match count.
  int _visibleCardCount(KanbanState state) =>
      state.invoices.values.fold(0, (sum, cards) => sum + cards.length);

  Widget _buildOFDTripGroupedList( List<InvoiceCard> invoices, TripState tripState) {
    if (invoices.isEmpty) {
      return Center(child: Text(context.l10n.kanbanNoInvoices));
    }

    // Find the OFD column id for drag data
    final ofdColumnId = ref.read(kanbanProvider).columns
        .where(_isOutForDeliveryColumn)
        .map((c) => c.id)
        .firstOrNull ?? 'out_for_delivery';

    final grouped = <String, List<InvoiceCard>>{};
    final nonTrip = <InvoiceCard>[];
    for (final inv in invoices) {
      final tripName = (inv.deliveryTrip ?? '').trim();
      if (tripName.isEmpty) {
        nonTrip.add(inv);
      } else {
        grouped.putIfAbsent(tripName, () => <InvoiceCard>[]).add(inv);
      }
    }

    String courierLabelFor(String tripName) {
      for (final t in tripState.trips) {
        if (t.name == tripName) {
          return t.courierDisplayName;
        }
      }
      return 'Courier';
    }

    bool isDoubleShipping(String tripName) {
      for (final t in tripState.trips) {
        if (t.name == tripName) {
          return t.isDoubleShipping;
        }
      }
      return false;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4).copyWith(bottom: 2),
      children: [
        for (final entry in grouped.entries)
          TripGroupCard(
            tripName: entry.key,
            courierDisplayName: courierLabelFor(entry.key),
            isDoubleShipping: isDoubleShipping(entry.key),
            invoices: entry.value,
            onMarkDelivered: (tripName) async {
              try {
                await ref.read(tripProvider.notifier).markAsDelivered(tripName);
              } finally {
                // Always refresh kanban — backend may have completed even if
                // the client saw an error (timeout, etc.)
                await ref.read(kanbanProvider.notifier).loadInvoices(immediate: true);
              }
            },
          ),
        for (final inv in nonTrip)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildDraggableInvoiceCard(inv, ofdColumnId),
          ),
      ],
    );
  }

  /// Trip-staging column (In Progress, or legacy Ready): orders already
  /// batched into a trip render as a [TripGroupCard] with "Send for Delivery";
  /// the rest stay ordinary draggable cards. [columnId] is the column's own id,
  /// used as the drag source.
  Widget _buildTripStagingGroupedList(
    List<InvoiceCard> invoices,
    TripState tripState,
    String columnId,
  ) {
    if (invoices.isEmpty) {
      return Center(child: Text(context.l10n.kanbanNoInvoices));
    }

    final grouped = <String, List<InvoiceCard>>{};
    final nonTrip = <InvoiceCard>[];
    for (final inv in invoices) {
      final tripName = (inv.deliveryTrip ?? '').trim();
      if (tripName.isEmpty) {
        nonTrip.add(inv);
      } else {
        grouped.putIfAbsent(tripName, () => <InvoiceCard>[]).add(inv);
      }
    }

    // If no trip groups, skip custom rendering so default drag/drop works
    if (grouped.isEmpty) return _buildDefaultDraggableList(nonTrip, columnId);

    String courierLabelFor(String tripName) {
      for (final t in tripState.trips) {
        if (t.name == tripName) return t.courierDisplayName;
      }
      return 'Courier';
    }

    bool isDoubleShipping(String tripName) {
      for (final t in tripState.trips) {
        if (t.name == tripName) return t.isDoubleShipping;
      }
      return false;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4).copyWith(bottom: 2),
      children: [
        for (final entry in grouped.entries)
          TripGroupCard(
            tripName: entry.key,
            courierDisplayName: courierLabelFor(entry.key),
            isDoubleShipping: isDoubleShipping(entry.key),
            invoices: entry.value,
            onSendForDelivery: (tripName) async {
              try {
                final sent = await _sendTripForDeliveryWithPreview(tripName);
                if (sent && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.tripsSentForDeliverySuccess)),
                  );
                }
              } finally {
                await ref.read(kanbanProvider.notifier).loadInvoices(immediate: true);
              }
            },
          ),
        for (final inv in nonTrip)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildDraggableInvoiceCard(inv, columnId),
          ),
      ],
    );
  }

  Widget _buildDefaultDraggableList(List<InvoiceCard> invoices, String columnId) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4).copyWith(bottom: 2),
      children: [
        for (final inv in invoices)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildDraggableInvoiceCard(inv, columnId),
          ),
      ],
    );
  }

  Widget _buildDraggableInvoiceCard(InvoiceCard invoice, String columnId) {
    return LongPressDraggable<Map<String, dynamic>>(
      data: {
        'invoiceId': invoice.id,
        'fromColumnId': columnId,
      },
      dragAnchorStrategy: pointerDragAnchorStrategy,
      maxSimultaneousDrags: 1,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.03,
          child: Opacity(
            opacity: 0.95,
            child: SizedBox(
              width: ResponsiveUtils.getKanbanColumnWidth(context),
              child: InvoiceCardWidget(invoice: invoice, isDragging: true, compact: true),
            ),
          ),
        ),
      ),
      childWhenDragging: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: 0.25,
        child: InvoiceCardWidget(invoice: invoice, isDragging: false, compact: false),
      ),
      child: _buildInvoiceCardWithMobileMove(invoice, columnId),
    );
  }

  Widget _buildInvoiceCardWithMobileMove(InvoiceCard invoice, String columnId) {
    final card = InvoiceCardWidget(invoice: invoice, isDragging: false, compact: false);
    if (!ResponsiveUtils.isPhone(context)) {
      return card;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 4, bottom: 8),
            child: OutlinedButton.icon(
              onPressed: () => _showMobileMoveSheet(invoice, columnId),
              icon: const Icon(Icons.drive_file_move, size: 16),
              label: Text(context.l10n.kanbanMoveAction),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTripSelectionBar(KanbanState kanbanState, TripState tripState) {
    final selectedInvoices = _selectedTripStagingInvoices(kanbanState, tripState.selectedInvoiceIds);
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.kanbanOrdersSelectedCount(selectedInvoices.length),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () => ref.read(tripProvider.notifier).clearSelection(),
                child: Text(context.l10n.commonClear),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: selectedInvoices.isEmpty ? null : () => _createTripFromSelection(selectedInvoices),
                icon: const Icon(Icons.local_shipping),
                label: Text(context.l10n.tripsCreateTripButton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<InvoiceCard> _selectedTripStagingInvoices(KanbanState kanbanState, Set<String> selectedIds) {
    final stagingColumn = tripStagingKanbanColumn(kanbanState.columns);
    if (stagingColumn == null) return const <InvoiceCard>[];
    final stagingInvoices = kanbanState.invoices[stagingColumn.id] ?? const <InvoiceCard>[];
    return stagingInvoices.where((inv) => selectedIds.contains(inv.id)).toList();
  }

  bool _isOutForDeliveryColumn(KanbanColumn column) {
    final id = column.id.trim().toLowerCase().replaceAll(' ', '_');
    final name = column.name.trim().toLowerCase().replaceAll(' ', '_');
    return id == 'out_for_delivery' || name == 'out_for_delivery';
  }

  Future<void> _createTripFromSelection(List<InvoiceCard> selectedInvoices) async {
    final created = await showDialog<dynamic>(
      context: context,
      builder: (_) => CreateTripDialog(selectedInvoices: selectedInvoices),
    );
    if (!mounted || created == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.kanbanTripCreatedSuccess)),
    );
    await ref.read(kanbanProvider.notifier).loadInvoices();
    await ref.read(tripProvider.notifier).loadTrips();
  }

  Future<void> _handleCardMove(
    String invoiceId,
    String fromColumnId,
    String toColumnId,
  ) async {
    final screenContext = context;
    final l10n = screenContext.l10n;
    // Clear any previous error so it doesn't persist on the screen
    final messenger = ScaffoldMessenger.of(screenContext);
    ref.read(kanbanProvider.notifier).clearError();

    // Last funnel before any state change: a fully returned order is terminal.
    // The DragTarget and the mobile sheet already block it, but every move ends
    // up here, so the guard lives here too rather than trusting the callers.
    if (_findInvoice(invoiceId)?.isFullyReturned ?? false) {
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.kanbanFullyReturnedLocked)),
      );
      return;
    }

    final targetColumn = ref.read(kanbanProvider).columns.firstWhere(
      (col) => col.id == toColumnId,
      orElse: () => KanbanColumn(id: toColumnId, name: toColumnId, color: '#F5F5F5'),
    );

    String normId = toColumnId.trim().toLowerCase();
    String normName = targetColumn.name.trim().toLowerCase().replaceAll('  ', ' ');
    String collapsedName = normName.replaceAll(' ', '_');
    final movingToOut = (
      normId == 'out_for_delivery' ||
      collapsedName == 'out_for_delivery' ||
      (normName.contains('out') && normName.contains('delivery'))
    );
    if (movingToOut) {
      final inv = _findInvoice(invoiceId);
      final hasPartner = ((inv?.salesPartner ?? '').isNotEmpty);
      final isPickup = (inv?.isPickup ?? false);
      final isPaid = (inv?.isFullyPaid ?? false);

      // Block individual OFD for invoices that belong to a trip — must use bulk trip send
      final tripName = inv?.deliveryTrip;
      if (tripName != null && tripName.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.kanbanPartOfTripWarning(tripName)),
            duration: const Duration(seconds: 4),
          ),
        );
        // Revert visual move
        final fromCol = ref.read(kanbanProvider).columns.firstWhere(
          (c) => c.id == fromColumnId,
          orElse: () => KanbanColumn(id: fromColumnId, name: fromColumnId.replaceAll('_', ' '), color: '#F5F5F5'),
        );
        ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, fromCol.name);
        return;
      }
      
      // Fast-path for pickup orders and already-paid Sales Partner invoices.
      if (isPickup || (hasPartner && isPaid)) {
        String? shortageReason;
        try {
          shortageReason = await _previewInvoiceOfdReason(invoiceId);
          if (shortageReason == null) {
            return;
          }
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(content: Text(context.userErrorMessage(e))),
          );
          return;
        }

        await ref.read(kanbanProvider.notifier).updateInvoiceState(
          invoiceId,
          'Out For Delivery',
          shortageApproved: shortageReason.isNotEmpty,
          shortageReason: shortageReason.isEmpty ? null : shortageReason,
        );
        return;
      }

      if (hasPartner && !isPaid) {
        await ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, 'Out For Delivery');
        return;
      }

      // Every courier dispatch runs the same pre-dispatch gates as the plain
      // state move: sub-territory, pending shipping request, and a stock
      // shortage that needs a reason. The server now enforces them on the
      // courier endpoints too, so ask here rather than fail after the courier
      // dialog. null = blocked or the operator backed out; '' = nothing needed.
      final String? courierShortageReason;
      try {
        courierShortageReason = await _previewInvoiceOfdReason(invoiceId);
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.userErrorMessage(e))),
        );
        return;
      }
      if (courierShortageReason == null) {
        return;
      }
      final courierShortageApproved = courierShortageReason.isNotEmpty;
      final String? courierShortageReasonText =
          courierShortageReason.isEmpty ? null : courierShortageReason;

      // InstaPay-on-delivery: an UNPAID online order (Instapay / Mobile Wallet),
      // non-partner and non-pickup, still needs a courier assigned but must NOT
      // go through courier settlement (which would wrongly mark it paid via the
      // outstanding path). It goes Out for Delivery as "Awaiting Payment" and is
      // reconciled later on the manager reconciliation screen.
      if (!isPaid && !hasPartner && !isPickup && _isOnlineIntent(inv)) {
        final posProfile = _getEffectiveProfileForInvoice(inv);
        if (posProfile == null) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.kanbanSelectPosProfileFirst)),
          );
          final fromCol = ref.read(kanbanProvider).columns.firstWhere(
            (c) => c.id == fromColumnId,
            orElse: () => KanbanColumn(id: fromColumnId, name: fromColumnId.replaceAll('_', ' '), color: '#F5F5F5'),
          );
          ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, fromCol.name);
          return;
        }
        final courierResult = await _showCourierSettlementDialog(
          courierOnly: true,
          invoicePosProfile: inv?.posProfile,
        );
        if (courierResult == null) {
          final fromCol = ref.read(kanbanProvider).columns.firstWhere(
            (c) => c.id == fromColumnId,
            orElse: () => KanbanColumn(id: fromColumnId, name: fromColumnId.replaceAll('_', ' '), color: '#F5F5F5'),
          );
          ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, fromCol.name);
          return;
        }
        final courierPartyType = courierResult['party_type'] as String?;
        final courierParty = courierResult['party'] as String?;
        final courierDisplay =
            (courierResult['display_name'] as String?) ?? courierParty;
        // A Delivery Partner rider (e.g. Deliverk) is accrued the partner's own
        // price for this address, which only the cashier knows; the server
        // refuses the dispatch without it.
        final deliveryPartner =
            (courierResult['delivery_partner'] as String?)?.trim() ?? '';
        double? partnerFee;
        if (deliveryPartner.isNotEmpty) {
          if (!screenContext.mounted) return;
          partnerFee = await showPartnerFeeDialog(
            screenContext,
            partnerName: deliveryPartner,
          );
          if (partnerFee == null) {
            final fromCol = ref.read(kanbanProvider).columns.firstWhere(
              (c) => c.id == fromColumnId,
              orElse: () => KanbanColumn(id: fromColumnId, name: fromColumnId.replaceAll('_', ' '), color: '#F5F5F5'),
            );
            ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, fromCol.name);
            return;
          }
        }
        try {
          await ref
              .read(instapayReconciliationServiceProvider)
              .deliverOnlineUnconfirmed(
                invoiceName: invoiceId,
                posProfile: posProfile,
                partyType: courierPartyType,
                party: courierParty,
                partnerFee: partnerFee,
                shortageApproved: courierShortageApproved,
                shortageReason: courierShortageReasonText,
              );
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                (courierDisplay != null && courierDisplay.isNotEmpty)
                    ? l10n.kanbanOfdAwaitingInstapayWithCourier(courierDisplay)
                    : l10n.kanbanOfdAwaitingInstapay,
              ),
            ),
          );
          try {
            await ref.read(kanbanProvider.notifier).refreshSingle(invoiceId);
          } catch (_) {
            try {
              await ref.read(kanbanProvider.notifier).loadInvoices();
            } catch (_) {}
          }
        } catch (e) {
          final errorMessage =
              context.userErrorMessage(e, fallback: l10n.commonError);
          messenger.showSnackBar(SnackBar(content: Text(context.userErrorMessage(errorMessage))));
          // Revert the optimistic move on failure.
          final fromCol = ref.read(kanbanProvider).columns.firstWhere(
            (c) => c.id == fromColumnId,
            orElse: () => KanbanColumn(id: fromColumnId, name: fromColumnId.replaceAll('_', ' '), color: '#F5F5F5'),
          );
          ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, fromCol.name);
        }
        return;
      }

      // Launch courier/mode dialog for regular delivery orders
      // Show "Settle Later" for non-partner, non-pickup only (per business rule)
      final showSettleLater = !hasPartner && !isPickup;
      final dialogResult = await _showCourierSettlementDialog(
        hideSettleLater: !showSettleLater,
        invoicePosProfile: inv?.posProfile,
      );
      if (dialogResult == null) {
        // Revert visual move if user cancelled (pass label)
        final fromCol = ref.read(kanbanProvider).columns.firstWhere(
          (c) => c.id == fromColumnId,
          orElse: () => KanbanColumn(id: fromColumnId, name: fromColumnId.replaceAll('_', ' '), color: '#F5F5F5'),
        );
        ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, fromCol.name);
        return;
      }
    final courier = dialogResult['courier'] as String?; // may be 'UNKNOWN'
    final mode = dialogResult['mode'] as String; // pay_now
    final partyType = dialogResult['party_type'] as String?;
    final party = dialogResult['party'] as String?;
    final courierDisplay = dialogResult['display_name'] as String? ?? courier;
      // Use the invoice's own POS profile for settlement. This ensures the correct
      // branch cash account is used regardless of which profile is globally selected.
      final posProfile = _getEffectiveProfileForInvoice(inv);
      if (posProfile == null) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.kanbanSelectPosProfileFirst)));
        // revert
        final fromCol = ref.read(kanbanProvider).columns.firstWhere(
          (c) => c.id == fromColumnId,
          orElse: () => KanbanColumn(id: fromColumnId, name: fromColumnId.replaceAll('_', ' '), color: '#F5F5F5'),
        );
        ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, fromCol.name);
        return;
      }
    // Only pay_now is supported per new business rule

      // New: Support 'later' when enabled (except Sales Partner and Pickup)
      if (mode == SettlementModes.later) {
        try {
          final courierService = ref.read(courierServiceProvider);
          // Generate preview only to obtain a token; do not show any collect/pay dialogs
          final preview = await courierService.generateSettlementPreview(
            invoice: invoiceId,
            partyType: partyType,
            party: party,
            mode: SettlementModes.later,
            recentPaymentSeconds: 30,
          );
          final previewPartyType = (preview['party_type'] ?? '').toString().trim();
          final previewParty = (preview['party'] ?? '').toString().trim();
          final resolvedPartyType = (partyType?.trim().isNotEmpty ?? false)
              ? partyType!.trim()
              : (previewPartyType.isNotEmpty ? previewPartyType : null);
          final resolvedParty = (party?.trim().isNotEmpty ?? false)
              ? party!.trim()
              : (previewParty.isNotEmpty ? previewParty : null);
          if (resolvedPartyType == null || resolvedParty == null) {
            messenger.showSnackBar(SnackBar(content: Text(l10n.kanbanSettleLaterMissingParty)));
            final fromCol = ref.read(kanbanProvider).columns.firstWhere(
              (c) => c.id == fromColumnId,
              orElse: () => KanbanColumn(id: fromColumnId, name: fromColumnId.replaceAll('_', ' '), color: '#F5F5F5'),
            );
            ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, fromCol.name);
            return;
          }
          final token = (preview['preview_token'] ?? preview['token'] ?? '').toString();
          if (token.isEmpty) {
            messenger.showSnackBar(SnackBar(content: Text(l10n.kanbanSettleLaterPreviewExpired)));
            // revert
            final fromCol = ref.read(kanbanProvider).columns.firstWhere(
              (c) => c.id == fromColumnId,
              orElse: () => KanbanColumn(id: fromColumnId, name: fromColumnId.replaceAll('_', ' '), color: '#F5F5F5'),
            );
            ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, fromCol.name);
            return;
          }

          final res = await courierService.confirmSettlement(
            invoice: invoiceId,
            previewToken: token,
            mode: SettlementModes.later,
            posProfile: posProfile,
            partyType: resolvedPartyType,
            party: resolvedParty,
            // No immediate collection; include courier label if present
            courier: courier ?? courierDisplay ?? 'UNKNOWN',
            shortageApproved: courierShortageApproved,
            shortageReason: courierShortageReasonText,
          );
          if (res['success'] != true) {
            messenger.showSnackBar(SnackBar(content: Text(l10n.kanbanSettleLaterFailed)));
            // revert
            final fromCol = ref.read(kanbanProvider).columns.firstWhere(
              (c) => c.id == fromColumnId,
              orElse: () => KanbanColumn(id: fromColumnId, name: fromColumnId.replaceAll('_', ' '), color: '#F5F5F5'),
            );
            ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, fromCol.name);
            return;
          }
          // Success: do not show collection/info popups for settle later
          messenger.showSnackBar(SnackBar(content: Text(l10n.kanbanMarkedSettleLater)));
          try {
            await ref.read(kanbanProvider.notifier).refreshSingle(invoiceId);
          } catch (_) {}
          return; // handled fully; backend already moved to OFD
        } catch (e) {
          final errorMessage = context.userErrorMessage(
            e,
            fallback: l10n.kanbanSettleLaterFailed,
          );
          messenger.showSnackBar(
            SnackBar(content: Text(context.userErrorMessage(errorMessage))),
          );
          // revert
          final fromCol = ref.read(kanbanProvider).columns.firstWhere(
            (c) => c.id == fromColumnId,
            orElse: () => KanbanColumn(id: fromColumnId, name: fromColumnId.replaceAll('_', ' '), color: '#F5F5F5'),
          );
          ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, fromCol.name);
          return;
        }
      }

  // For pay_now flow (regardless of paid/unpaid), use two-step preview -> confirm.
  if (mode == SettlementModes.payNow) {
        try {
          final courierService = ref.read(courierServiceProvider);
          final preview = await courierService.generateSettlementPreview(
            invoice: invoiceId,
            partyType: partyType,
            party: party,
            mode: mode,
            recentPaymentSeconds: 30,
          );
          final previewPartyType = (preview['party_type'] ?? '').toString().trim();
          final previewParty = (preview['party'] ?? '').toString().trim();
          final resolvedPartyType = (partyType?.trim().isNotEmpty ?? false)
              ? partyType!.trim()
              : (previewPartyType.isNotEmpty ? previewPartyType : null);
          final resolvedParty = (party?.trim().isNotEmpty ?? false)
              ? party!.trim()
              : (previewParty.isNotEmpty ? previewParty : null);
          if (resolvedPartyType == null || resolvedParty == null) {
            messenger.showSnackBar(SnackBar(content: Text(l10n.kanbanSettlementMissingParty)));
            final fromCol = ref.read(kanbanProvider).columns.firstWhere(
              (c) => c.id == fromColumnId,
              orElse: () => KanbanColumn(id: fromColumnId, name: fromColumnId.replaceAll('_', ' '), color: '#F5F5F5'),
            );
            ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, fromCol.name);
            return;
          }
          if (!screenContext.mounted) return;

          final confirmation = await showSettlementConfirmDialog(
            screenContext,
            preview,
            invoice: invoiceId,
            territory: territoryLabel(
              nameAr: inv?.territoryNameAr,
              display: inv?.territoryDisplay,
              raw: inv?.territory,
            ),
            orderFallback: inv?.grandTotal,
            shippingFallback: inv?.shippingExpenseDisplay,
          );
          if (confirmation?.confirmed != true) {
            // Revert visual move if user cancelled
            final fromCol = ref.read(kanbanProvider).columns.firstWhere(
              (c) => c.id == fromColumnId,
              orElse: () => KanbanColumn(id: fromColumnId, name: fromColumnId.replaceAll('_', ' '), color: '#F5F5F5'),
            );
            ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, fromCol.name);
            return;
          }

          final token = (preview['preview_token'] ?? preview['token'] ?? '').toString();
          if (token.isEmpty) {
            messenger.showSnackBar(SnackBar(content: Text(l10n.kanbanPreviewExpired)));
            // revert
            final fromCol = ref.read(kanbanProvider).columns.firstWhere(
              (c) => c.id == fromColumnId,
              orElse: () => KanbanColumn(id: fromColumnId, name: fromColumnId.replaceAll('_', ' '), color: '#F5F5F5'),
            );
            ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, fromCol.name);
            return;
          }

          messenger.showSnackBar(SnackBar(content: Text(l10n.kanbanConfirmingSettlement)));
          final res = await courierService.confirmSettlement(
            invoice: invoiceId,
            previewToken: token,
            mode: mode,
            posProfile: posProfile,
            partyType: resolvedPartyType,
            party: resolvedParty,
            paymentMode: PaymentModes.cash,
            courier: courier ?? courierDisplay ?? 'UNKNOWN',
            partnerFee: confirmation?.partnerFee,
            shortageApproved: courierShortageApproved,
            shortageReason: courierShortageReasonText,
          );
          if (res['success'] != true) {
            messenger.showSnackBar(SnackBar(content: Text(l10n.kanbanSettlementFailed)));
            // revert
            final fromCol = ref.read(kanbanProvider).columns.firstWhere(
              (c) => c.id == fromColumnId,
              orElse: () => KanbanColumn(id: fromColumnId, name: fromColumnId.replaceAll('_', ' '), color: '#F5F5F5'),
            );
            ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, fromCol.name);
            return;
          }
          messenger.showSnackBar(SnackBar(content: Text(l10n.kanbanSettlementConfirmed)));
          return; // handled: server already performed OFD
        } catch (e) {
          final errorMessage = context.userErrorMessage(
            e,
            fallback: l10n.kanbanSettlementFailed,
          );
          messenger.showSnackBar(
            SnackBar(content: Text(context.userErrorMessage(errorMessage))),
          );
          // revert
          final fromCol = ref.read(kanbanProvider).columns.firstWhere(
            (c) => c.id == fromColumnId,
            orElse: () => KanbanColumn(id: fromColumnId, name: fromColumnId.replaceAll('_', ' '), color: '#F5F5F5'),
          );
          ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, fromCol.name);
          return;
        }
      }

      // Perform unified OFD transition
      ref.read(kanbanProvider.notifier)
          .outForDeliveryUnified(
            invoiceId: invoiceId,
            courier: courier ?? 'UNKNOWN',
            mode: mode,
            posProfile: posProfile,
            partyType: partyType,
            party: party,
            courierDisplay: courierDisplay,
          )
          .then((res) async {
        if (mode == SettlementModes.payNow) {
          // Fetch settlement preview to drive UI (signed net logic)
          try {
            final courierService = ref.read(courierServiceProvider);
            final preview = await courierService.getSettlementPreview(
              invoice: invoiceId,
              partyType: partyType,
              party: party,
            );
            if (!mounted) return;
            await _showSettlementResultDialog(preview, inv);
          } catch (e) {
            if (!mounted) return;
            final errorMessage = context.userErrorMessage(
              e,
              fallback: l10n.kanbanSettlementFailed,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.userErrorMessage(errorMessage))),
            );
          }
        }
      });
      return; // do not fall through to normal state update
    }

    // Other states: normal state update
    ref.read(kanbanProvider.notifier).updateInvoiceState(invoiceId, targetColumn.name);
  }

  Future<void> _showMobileMoveSheet(InvoiceCard invoice, String fromColumnId) async {
    // A fully returned order is frozen, so bail out with the real reason rather
    // than the generic "one stage at a time" the empty-target branch would give.
    if (invoice.isFullyReturned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.kanbanFullyReturnedLocked)),
      );
      return;
    }

    final columns = ref.read(kanbanProvider).columns;
    final targets = columns
        .where((column) => column.id != fromColumnId)
        .where((column) => _cardMoveBlockMessage(invoice.id, fromColumnId, column.id) == null)
        .toList(growable: false);

    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.kanbanMoveOneStage)),
      );
      return;
    }

    final target = await showModalBottomSheet<KanbanColumn>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: ResponsiveUtils.getDialogHeight(sheetContext, phoneFraction: 0.65),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.kanbanMoveOrderTitle,
                          style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: targets.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final column = targets[index];
                      return ListTile(
                        leading: const Icon(Icons.arrow_forward),
                        title: Text(localizedKanbanState(context, column.name)),
                        subtitle: Text(invoice.customerName, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.of(sheetContext).pop(column),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || target == null) return;
    await _handleCardMove(invoice.id, fromColumnId, target.id);
  }

  bool _canAcceptCardMove(String invoiceId, String fromColumnId, String toColumnId) {
    final blockMessage = _cardMoveBlockMessage(invoiceId, fromColumnId, toColumnId);
    if (blockMessage == null) return true;
    if (blockMessage.isNotEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(blockMessage)));
    }
    return false;
  }

  /// Resolves the block reason for a move, then maps it to a user-facing string.
  ///
  /// Returns null when the move is allowed, `''` to block silently, and a
  /// non-empty message to block with a snackbar. The decision itself lives in
  /// [evaluateCardMoveBlock] so the guard ordering can be unit-tested.
  String? _cardMoveBlockMessage(String invoiceId, String fromColumnId, String toColumnId) {
    final columns = ref.read(kanbanProvider).columns;
    final reason = evaluateCardMoveBlock(
      columns: columns,
      fromColumnId: fromColumnId,
      toColumnId: toColumnId,
      // Lazy: only resolved when the target is the settlement column, so a plain
      // hover over other columns does not scan the whole board.
      isPickupLookup: () => _findInvoice(invoiceId)?.isPickup ?? false,
      isFullyReturnedLookup: () =>
          _findInvoice(invoiceId)?.isFullyReturned ?? false,
    );

    switch (reason) {
      case null:
        return null;
      case CardMoveBlockReason.sameColumn:
        return '';
      case CardMoveBlockReason.fullyReturnedLocked:
        return context.l10n.kanbanFullyReturnedLocked;
      case CardMoveBlockReason.pickupNoSettlement:
        return context.l10n.kanbanPickupNoSettlement;
      case CardMoveBlockReason.cancelViaMenuOnly:
        return context.l10n.kanbanCancelViaMenuOnly;
      case CardMoveBlockReason.returnViaMenuOnly:
        return context.l10n.kanbanReturnViaMenuOnly;
      case CardMoveBlockReason.cannotMoveBackward:
        return context.l10n.kanbanCannotMoveBackward;
      case CardMoveBlockReason.moveOneStage:
        return context.l10n.kanbanMoveOneStage;
    }
  }

  InvoiceCard? _findInvoice(String id) {
    final s = ref.read(kanbanProvider);
    for (final entry in s.invoices.entries) {
      for (final c in entry.value) {
        if (c.id == id) return c;
      }
    }
    return null;
  }

  String? _getPosProfile() {
    final posState = ref.read(posNotifierProvider);
    return posState.selectedProfile?['name'];
  }

  /// Returns the POS profile to use for a specific invoice's operations.
  /// Prefers the invoice's own posProfile (its branch), falling back to the
  /// globally selected profile. This allows multi-profile users to process
  /// invoices from any of their accessible branches without changing their
  /// current POS selection.
  String? _getEffectiveProfileForInvoice(InvoiceCard? inv) {
    final invProfile = (inv?.posProfile ?? '').trim();
    if (invProfile.isNotEmpty) return invProfile;
    return _getPosProfile();
  }

  /// True when the invoice's requested payment method (or its resolved
  /// collection method) is an online method — Instapay or Mobile Wallet —
  /// meaning it should follow the InstaPay-on-delivery awaiting-payment flow
  /// instead of the courier settlement dialog. Case-insensitive.
  bool _isOnlineIntent(InvoiceCard? inv) {
    if (inv == null) return false;
    bool isOnline(String? method) {
      final normalized = (method ?? '').trim().toLowerCase();
      return normalized == 'instapay' || normalized == 'mobile wallet';
    }

    return isOnline(inv.paymentMethod) ||
        isOnline(inv.effectiveCollectionMethod);
  }

  void _handlePosStateChange(PosState state) {
    if (!mounted) return;
    final hasMultipleProfiles = state.profiles.length > 1;
    final noProfileSelected = state.selectedProfile == null;
    // Show a dismissible profile-selection hint when the user has multiple profiles and
    // hasn't selected one yet. Selecting a profile enables the cash-balance chip and
    // scopes OFD couriers to the matching branch.  The dialog is NOT mandatory —
    // the user can dismiss it and all non-POS/shift operations will still work across
    // all their accessible profiles (OFD uses the invoice's own POS profile instead).
    if (!_posProfileDialogActive && !_profileDialogDismissed && hasMultipleProfiles && noProfileSelected && !state.isLoading) {
      _posProfileDialogActive = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final selected = await _showPosProfileSelectionDialog(state.profiles);
        _posProfileDialogActive = false;
        if (selected != null && mounted) {
          await ref.read(posNotifierProvider.notifier).selectProfile(selected);
        } else {
          // User dismissed — don't re-prompt automatically for this screen session.
          _profileDialogDismissed = true;
        }
      });
    }
  }

  Future<Map<String, dynamic>?> _showPosProfileSelectionDialog(List<Map<String, dynamic>> profiles) async {
    if (!mounted) return null;
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final dialogWidth = ResponsiveUtils.getDialogWidth(ctx);
        return PopScope(
          canPop: true,
          child: AlertDialog(
            title: Text(context.l10n.kanbanSelectPosProfile),
            content: SizedBox(
              width: dialogWidth,
              child: profiles.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(context.l10n.kanbanNoPosProfiles),
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: profiles.length,
                        separatorBuilder: (context, _) => const SizedBox(height: 8),
                        itemBuilder: (ctx, index) {
                          final profile = profiles[index];
                          final title = (profile['title'] ?? profile['name'] ?? '').toString();
                          final warehouse = (profile['warehouse'] ?? '').toString();
                          return Card(
                            elevation: 1,
                            child: ListTile(
                              leading: const Icon(Icons.store),
                              title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                              subtitle: warehouse.isNotEmpty ? Text(context.l10n.kanbanWarehouse(warehouse)) : null,
                              onTap: () => Navigator.of(ctx).pop(profile),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _showCourierSettlementDialog({
    bool hideSettleLater = false,
    // Courier attribution only: hides every settlement option and returns just
    // the courier selection. Used by flows that must not settle the invoice.
    bool courierOnly = false,
    String? invoicePosProfile, // The specific invoice's POS profile (branch)
  }) async {
    String? courier;
    String mode = OutForDeliverySettlement.defaultMode;
    bool loading = true;
    List<Map<String, String>> couriers = [];
    bool creating = false;
    String newPartyType = 'Supplier'; // Default to Supplier (Employee has validation issues on staging)
    bool isPartnerCourier = false;
    String? selectedDeliveryPartner;
    List<Map<String, String>> deliveryPartners = [];
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    // Resolve the POS profile for this operation: prefer the invoice's own profile
    // so multi-profile users can process invoices from any branch.
    final effectiveProfile = invoicePosProfile?.trim().isNotEmpty == true
        ? invoicePosProfile!.trim()
        : _getPosProfile();
    // Check if the effective profile allows delivery partner assignment
    final posState = ref.read(posNotifierProvider);
    final currentProfile = effectiveProfile != null
        ? posState.profiles.cast<Map<String, dynamic>?>().firstWhere(
            (p) => p?['name'] == effectiveProfile,
            orElse: () => posState.selectedProfile,
          )
        : posState.selectedProfile;
    final allowDeliveryPartner = currentProfile?['allow_delivery_partner'] == true;
    try {
      couriers = await ref.read(kanbanProvider.notifier).getCouriers(posProfile: effectiveProfile);
      // Branch filter: keep only couriers whose branch matches this invoice's POS profile.
      // Using the invoice's own profile (not the globally selected one) so that
      // multi-profile users see couriers from the correct branch.
      if (effectiveProfile != null) {
        couriers = couriers.where((c) => c['branch'] == effectiveProfile).toList();
      }
    } catch (_) {}
    loading = false;
    if (!mounted) return null;
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: Text(context.l10n.commonCourierLabel),
            content: SizedBox(
              width: ResponsiveUtils.getDialogWidth(ctx),
              child: loading
                  ? const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()))
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!creating) ...[
                            if (couriers.isEmpty) ...[
                              const Icon(Icons.local_shipping_outlined, size: 48, color: Colors.orange),
                              const SizedBox(height: 12),
                              Text(context.l10n.kanbanNoCouriersAvailable, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.kanbanCreateCourierHint,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                            ] else ...[
                              // Grid/list of courier cards for selection
                              LayoutBuilder(
                                builder: (ctx, constraints) {
                                  final isWide = constraints.maxWidth > 560;
                                  final crossAxisCount = isWide ? 3 : 2;
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: couriers.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      mainAxisExtent: 76, // fixed height: CircleAvatar(r:18)=36 + 12+12 padding + 2 text lines
                                    ),
                                    itemBuilder: (ctx, i) {
                                      final c = couriers[i];
                                      final selected = courier == c['party'];
                                      return InkWell(
                                        onTap: () => setState(() => courier = c['party']),
                                        borderRadius: BorderRadius.circular(12),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: selected ? Colors.blue : Colors.grey[300]!,
                                              width: selected ? 2 : 1,
                                            ),
                                            color: selected ? Colors.blue.withValues(alpha: 0.06) : Colors.white,
                                            boxShadow: [
                                              if (selected)
                                                BoxShadow(
                                                  color: Colors.blue.withValues(alpha: 0.15),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor: selected ? Colors.blue : Colors.grey[200],
                                                child: Icon(Icons.person, color: selected ? Colors.white : Colors.grey[600]),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      c['display_name'] ?? c['party']!,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: selected ? Colors.blue[800] : Colors.black87,
                                                      ),
                                                    ),
                                                    if (c['delivery_partner'] != null && c['delivery_partner']!.isNotEmpty)
                                                      Text(
                                                        '🤝 ${c['delivery_partner']}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(fontSize: 10, color: Colors.deepPurple[600], fontWeight: FontWeight.w500),
                                                      )
                                                    else if (c['party_type'] != null)
                                                      Text(
                                                        c['party_type']!,
                                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton.icon(
                                icon: const Icon(Icons.add),
                                label: Text(context.l10n.kanbanNewCourier),
                                onPressed: () => setState(() => creating = true),
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: firstNameController,
                                    decoration: InputDecoration(labelText: context.l10n.kanbanFirstName),
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: lastNameController,
                                    decoration: InputDecoration(labelText: context.l10n.kanbanLastName),
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: phoneController,
                              decoration: InputDecoration(labelText: context.l10n.kanbanPhone),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: newPartyType,
                              decoration: InputDecoration(labelText: context.l10n.kanbanType),
                              items: [
                                DropdownMenuItem(value: 'Employee', child: Text(context.l10n.kanbanEmployee)),
                                DropdownMenuItem(value: 'Supplier', child: Text(context.l10n.kanbanSupplier)),
                              ],
                              onChanged: (v) => setState(() => newPartyType = v ?? 'Employee'),
                            ),
                            if (allowDeliveryPartner) ...[
                              const SizedBox(height: 8),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(context.l10n.kanbanDeliveryPartnerCourier),
                                subtitle: Text(context.l10n.kanbanDeliveryPartnerCourierSubtitle, style: const TextStyle(fontSize: 12)),
                                value: isPartnerCourier,
                                onChanged: (v) async {
                                  setState(() => isPartnerCourier = v);
                                  if (v && deliveryPartners.isEmpty) {
                                    // Load delivery partners list
                                    try {
                                      deliveryPartners = await ref.read(kanbanProvider.notifier).getDeliveryPartnersList();
                                      setState(() {});
                                    } catch (_) {}
                                  }
                                  if (!v) {
                                    setState(() => selectedDeliveryPartner = null);
                                  }
                                },
                              ),
                              if (isPartnerCourier) ...[
                                if (deliveryPartners.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                                  )
                                else
                                  DropdownButtonFormField<String>(
                                    initialValue: selectedDeliveryPartner,
                                    decoration: InputDecoration(
                                        labelText: context
                                            .l10n.kanbanDeliveryPartnerField),
                                    items: deliveryPartners.map((dp) => DropdownMenuItem(
                                      value: dp['name'],
                                      child: Text(dp['partner_name'] ?? dp['name'] ?? ''),
                                    )).toList(),
                                    onChanged: (v) => setState(() => selectedDeliveryPartner = v),
                                  ),
                              ],
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: loading ? null : () => setState(() => creating = false),
                                  child: Text(context.l10n.kanbanBack),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: loading
                                      ? null
                                      : () async {
                      final firstName = firstNameController.text.trim();
                      final lastName = lastNameController.text.trim();
                                          final phone = phoneController.text.trim();
                      if (firstName.isEmpty || lastName.isEmpty) return;
                                          setState(() => loading = true);
                                          try {
                                            final created = await ref.read(kanbanProvider.notifier).createDeliveryParty(
                                              partyType: newPartyType,
                        firstName: firstName,
                        lastName: lastName,
                                              phone: phone,
                                              posProfile: effectiveProfile,
                                              deliveryPartner: isPartnerCourier ? selectedDeliveryPartner : null,
                                            );
                                            if (created != null) {
                                              couriers = [...couriers, created];
                                              courier = created['party'];
                                              creating = false;
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              final errorMessage = context.userErrorMessage(
                                                e,
                                                fallback: context.l10n.kanbanCreateFailedFallback,
                                              );
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(context.userErrorMessage(errorMessage))),
                                              );
                                            }
                                          } finally {
                                            setState(() => loading = false);
                                          }
                                        },
                                  icon: const Icon(Icons.check),
                                  label: Text(context.l10n.commonSave),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (OutForDeliverySettlement.showModePicker && !courierOnly) ...[
                            const SizedBox(height: 14),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(context.l10n.kanbanMode, style: Theme.of(context).textTheme.titleSmall),
                            ),
                            RadioGroup<String>(
                              groupValue: mode,
                              onChanged: (v) => setState(() => mode = v ?? mode),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RadioListTile<String>(
                                    title: Text(context.l10n.kanbanPayNowCash),
                                    value: SettlementModes.payNow,
                                    dense: true,
                                  ),
                                  if (!hideSettleLater)
                                    RadioListTile<String>(
                                      title: Text(context.l10n.kanbanSettleLater),
                                      subtitle: Text(context.l10n.kanbanSettleLaterSubtitle),
                                      value: SettlementModes.later,
                                      dense: true,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.commonCancel)),
              if (!creating)
                if (couriers.isEmpty)
                  ElevatedButton(
                    onPressed: loading
                        ? null
                        : () => Navigator.pop(ctx, {
                              'courier': 'UNKNOWN',
                              if (!courierOnly) 'mode': mode,
                              'no_courier': true,
                            }),
                    child: Text(context.l10n.kanbanContinue),
                  )
                else
                  ElevatedButton(
                    onPressed: courier == null || loading
                        ? null
                        : () {
                              final selected = couriers.firstWhere((c) => c['party'] == courier, orElse: () => {});
                              Navigator.pop(ctx, {
                                'courier': courier,
                                if (!courierOnly) 'mode': mode,
                                'party_type': selected['party_type'],
                                'party': selected['party'],
                                'display_name': selected['display_name'],
                                if ((selected['delivery_partner'] ?? '').isNotEmpty)
                                  'delivery_partner': selected['delivery_partner'],
                              });
                            },
                    child: Text(context.l10n.commonConfirm),
                  )
              else
                const SizedBox.shrink(),
            ],
          );
        });
      },
    );
  }

  Future<void> _showSettlementResultDialog(Map<String, dynamic> preview, InvoiceCard? inv) async {
    await showSettlementInfoDialog(
      context,
      preview,
      invoice: inv?.name,
      territory: inv?.territory,
      orderFallback: inv?.grandTotal,
      shippingFallback: inv?.shippingExpenseDisplay,
    );
  }

  Future<bool> _handleBackPress() async {
    final now = DateTime.now();
    if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      return true;
    }
    _lastBackPress = now;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.kanbanPressBackAgain)),
      );
    }
    return false;
  }
}

class _KanbanScrollBehavior extends MaterialScrollBehavior {
  const _KanbanScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.unknown,
      };
}


class _BranchFilterButton extends ConsumerWidget {
  const _BranchFilterButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final posState = ref.watch(posNotifierProvider);
    final sel = ref.watch(kanbanProvider).selectedBranches;
    final profiles = posState.profiles;
    // Always render a placeholder chip so the UI is visible immediately
    final isLoading = posState.isLoading && profiles.isEmpty;

    final selectedCount = sel.length;
    final label = selectedCount == 0
        ? context.l10n.kanbanAllBranches
        : context.l10n.kanbanBranchCount(selectedCount);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: InkWell(
        onTap: () async {
          if (profiles.isEmpty) return; // ignore taps until loaded
          final current = Set<String>.from(sel);
          final result = await showDialog<Set<String>>(
            context: context,
            useRootNavigator: true,
            builder: (ctx) => BranchFilterDialog(
              profiles: profiles,
              initiallySelected: current,
              title: context.l10n.kanbanFilterByBranches,
            ),
          );
          if (result != null) {
            ref.read(kanbanProvider.notifier).setSelectedBranches(result);
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_alt, size: 16, color: theme.colorScheme.onSurface),
              const SizedBox(width: 6),
              Text(
                isLoading ? context.l10n.kanbanLoadingBranches : label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down, size: 18, color: theme.colorScheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }
}

/// Why a kanban card move was rejected. Mapped to a localised string by
/// `_cardMoveBlockMessage`; [sameColumn] blocks silently.
enum CardMoveBlockReason {
  sameColumn,
  fullyReturnedLocked,
  pickupNoSettlement,
  cancelViaMenuOnly,
  returnViaMenuOnly,
  cannotMoveBackward,
  moveOneStage,
}

/// True when [column] is the Cancelled column.
bool isCancelledKanbanColumn(KanbanColumn column) {
  final id = column.id.toLowerCase();
  final name = column.name.toLowerCase();
  return id.contains('cancelled') || name.contains('cancelled');
}

/// True when [column] is the terminal Returned column.
///
/// Matches `returned` but deliberately NOT the older `Returned to Sender`
/// courier status, which is a different thing entirely.
bool isReturnedKanbanColumn(KanbanColumn column) {
  bool matches(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(' ', '_');
    return normalized == 'returned' || normalized == 'return';
  }

  return matches(column.id) || matches(column.name);
}

/// True when [column] is the "In Progress" preparation column.
///
/// Accepts the legacy "Processing" label too, so boards that were never
/// renamed keep resolving to the same stage.
bool isInProgressKanbanColumn(KanbanColumn column) {
  bool matches(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(' ', '_');
    return normalized == 'in_progress' || normalized == 'processing';
  }

  return matches(column.id) || matches(column.name);
}

/// True when [column] is the legacy "Ready" column.
///
/// The backend dropped the Ready stage on 2026-10-13; this only matters while
/// an older server still sends it during the rollout.
bool isReadyKanbanColumn(KanbanColumn column) {
  bool matches(String value) => value.trim().toLowerCase() == 'ready';

  return matches(column.id) || matches(column.name);
}

/// The column where staff multi-select orders and batch them into a delivery
/// trip, before the trip is sent out for delivery.
///
/// That is In Progress, the stage right before Out for Delivery. While an
/// older backend still sends a legacy Ready column, Ready keeps the role it
/// always had so the board behaves exactly as before. Returns null when the
/// board has neither column.
KanbanColumn? tripStagingKanbanColumn(List<KanbanColumn> columns) {
  for (final column in columns) {
    if (isReadyKanbanColumn(column)) return column;
  }
  for (final column in columns) {
    if (isInProgressKanbanColumn(column)) return column;
  }
  return null;
}

/// Pure move-validation for the kanban board. Returns null when the move is
/// allowed, otherwise the reason it is blocked.
///
/// Guard order matters and is asserted by tests:
///  1. same column          -> silent no-op
///  2. fully returned       -> the card itself is frozen, so this beats every
///     target-specific guard below. The server rejects the move anyway; doing
///     it here saves the round-trip and gives immediate feedback.
///  3. pickup -> settlement -> pickup orders never settle
///  4. -> Cancelled         -> ALWAYS blocked, any direction. Cancelling has to
///     capture a reason + notes and honour canCancel / hasPartialPayment, which
///     only the card's "Cancel Order" menu action does. This must stay ahead of
///     the backward guard, otherwise a backward drag into Cancelled would report
///     the unhelpful "Cannot move backward" instead.
///  5. -> Returned          -> ALWAYS blocked, any direction. Reaching Returned
///     means a credit note was posted; only the card's "Return Order" action
///     can do that. Same ordering reasoning as Cancelled.
///  6. backward             -> never allowed
///  7. forward > 1 stage    -> one stage at a time
///
/// [isPickupLookup] is called lazily, only when the target is the settlement
/// column, so hovering other columns stays cheap during a drag.
/// [isFullyReturnedLookup] is likewise lazy, and defaults to "not returned" so
/// callers that predate the return workflow keep their old behaviour.
CardMoveBlockReason? evaluateCardMoveBlock({
  required List<KanbanColumn> columns,
  required String fromColumnId,
  required String toColumnId,
  required bool Function() isPickupLookup,
  bool Function()? isFullyReturnedLookup,
}) {
  if (columns.isEmpty) return null;

  int resolveIndex(String candidate) {
    final normalized = candidate.trim().toLowerCase();
    var idx = columns.indexWhere((c) => c.id.trim().toLowerCase() == normalized);
    if (idx != -1) return idx;
    idx = columns.indexWhere((c) => c.name.trim().toLowerCase() == normalized);
    return idx;
  }

  final fromIndex = resolveIndex(fromColumnId);
  final toIndex = resolveIndex(toColumnId);
  if (fromIndex == -1 || toIndex == -1) {
    return null; // Unknown columns; do not block the move
  }

  if (fromIndex == toIndex) {
    return CardMoveBlockReason.sameColumn;
  }

  // FULLY-RETURNED GUARD: a fully returned order is terminal. It cannot leave
  // the Returned column and nothing can be dragged onto it either.
  if (isFullyReturnedLookup?.call() ?? false) {
    return CardMoveBlockReason.fullyReturnedLocked;
  }

  // PICKUP ORDER VALIDATION: Prevent pickup orders from going to Courier Settlement
  final targetColumn = columns[toIndex];
  final targetName = targetColumn.name.trim().toLowerCase();
  final targetId = targetColumn.id.trim().toLowerCase();
  final isMovingToSettlement =
      targetName.contains('courier') && targetName.contains('settlement') ||
          targetId.contains('courier') && targetId.contains('settlement');

  if (isMovingToSettlement && isPickupLookup()) {
    return CardMoveBlockReason.pickupNoSettlement;
  }

  // CANCELLATION GUARD — see doc comment above for why this precedes the
  // backward guard.
  if (isCancelledKanbanColumn(targetColumn)) {
    return CardMoveBlockReason.cancelViaMenuOnly;
  }

  // RETURN GUARD — same reasoning as the cancellation guard: the column is
  // only ever reached by the backend return workflow, never by a drag.
  if (isReturnedKanbanColumn(targetColumn)) {
    return CardMoveBlockReason.returnViaMenuOnly;
  }

  // Orders never move backward, with no exceptions (owner decision
  // 2026-10-13). The old Ready -> In Progress kitchen-correction carve-out went
  // away together with the Ready stage itself.
  if (toIndex < fromIndex) {
    return CardMoveBlockReason.cannotMoveBackward;
  }

  if (toIndex - fromIndex > 1) {
    return CardMoveBlockReason.moveOneStage;
  }

  return null;
}
