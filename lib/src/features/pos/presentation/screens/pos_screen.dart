import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../../../core/utils/order_display_id.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/websocket/websocket_service.dart';
import '../../../../core/sync/offline_sync_service.dart';
import '../../../../core/router.dart';
import '../../state/courier_balances_provider.dart';
import '../../../credit/data/models/credit_models.dart';
import '../../../credit/state/credit_providers.dart';

// Merged system status: connectivity, realtime, sync, couriers, partner chip
// Removed unused system status imports (connectivity, sync, websocket) to satisfy analyzer.
import '../../state/pos_notifier.dart';
import '../../state/chat_order_apply.dart';
import '../../../chat_inbox/data/models/chat_models.dart';
import '../../../../core/repositories/customer_address_repository.dart';
import '../../../../core/widgets/customer_shipping_address_flow.dart';
import '../widgets/chat_order_panel.dart';
import '../widgets/customer_search_widget.dart';
import '../widgets/draft_tabs_bar.dart';
import '../widgets/sales_partner_selector.dart';
import '../widgets/item_grid_widget.dart';
import '../widgets/cart_widget.dart';
import '../widgets/courier_balances_dialog.dart';
import '../utils/amendment_refusal_message.dart';
// Kanban is navigated as a separate route to keep headers consistent
// Printing
import '../../../printing/pos_printer_provider.dart';
import '../../../printing/printer_status.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/network/user_service.dart';
import '../../../shift/state/shift_notifier.dart';
import '../../../shift/presentation/widgets/shift_status_banner.dart';
import '../../../weekly_count/presentation/widgets/weekly_count_banner.dart';
// Removed branch filter from POS; filter lives in Kanban header
// Removed unused direct service import (service accessed through provider)

class PosScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? launchData;

  const PosScreen({super.key, this.launchData});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen>
    with SingleTickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isProfileDialogOpen = false;
  bool _amendmentCleanupScheduled = false;
  bool _b2bBindingApplied = false;
  bool _b2bBindingInProgress = false;
  String? _b2bBindingError;
  bool _chatOrderApplied = false;
  // Chat order ("Start order" from the inbox): lines still to be put in the
  // cart, what applying them did, and whether staff closed the panel.
  bool _chatCartPending = false;
  bool _chatPanelDismissed = false;
  ChatOrderApplyResult? _chatApplyResult;
  List<ChatPromoOutcome>? _chatPromoOutcomes;
  late final ChatPrefillOrder? _chatOrder = _readChatOrder();

  bool get _isB2bOrderRoute =>
      widget.launchData?['mode']?.toString() == 'b2b_order';

  // ── Scroll-to-hide state (phones only) ──────────────────────────
  late final AnimationController _hideController;

  /// 1.0 → visible, 0.0 → hidden.  Used for SizeTransition + FAB.
  late final Animation<double> _hideAnim;
  bool _headerVisible = true;
  double _lastScrollOffset = 0;

  /// Accumulated scroll delta – works on 120 Hz+ displays where per-frame
  /// delta can be tiny.  Resets when scroll direction reverses.
  double _accumulatedDelta = 0;
  // Accumulated px in one direction before triggering hide/show
  static const _scrollThreshold = 30.0;

  Map<String, dynamic>? _amendmentInvoiceData() {
    final launchData = widget.launchData;
    final invoiceData = launchData?['invoice'];
    if (launchData?['mode']?.toString() != 'amendment_draft' ||
        invoiceData is! Map) {
      return null;
    }
    return Map<String, dynamic>.from(invoiceData);
  }

  String? _amendmentInvoiceId() {
    final invoiceId = _amendmentInvoiceData()?['name']?.toString().trim() ?? '';
    return invoiceId.isEmpty ? null : invoiceId;
  }

  void _scheduleAmendmentDraftCleanup() {
    if (_amendmentCleanupScheduled) {
      return;
    }
    final invoiceId = _amendmentInvoiceId();
    if (invoiceId == null) {
      return;
    }
    _amendmentCleanupScheduled = true;
    unawaited(
      ref
          .read(posNotifierProvider.notifier)
          .abandonAmendmentDraft(expectedInvoiceId: invoiceId),
    );
  }

  /// Applies a B2B binding passed via [PosScreen.launchData]:
  /// `{mode: 'b2b_order', customer, order_purpose}`.
  /// Preselects the customer and selects the
  /// commercial policy whose order purpose matches the binding, so the order is
  /// placed through the normal invoice-creation path (and lands on the dispatch
  /// Kanban automatically).
  Future<bool> _applyB2bBinding() async {
    final launchData = widget.launchData;
    if (launchData?['mode']?.toString() != 'b2b_order') return false;

    final customer = launchData?['customer']?.toString().trim() ?? '';
    final orderPurpose = launchData?['order_purpose']?.toString().trim() ?? '';
    if (customer.isEmpty) return false;

    final notifier = ref.read(posNotifierProvider.notifier);
    final selectedCustomer = launchData?['selected_customer'] is Map
        ? Map<String, dynamic>.from(launchData!['selected_customer'] as Map)
        : <String, dynamic>{
            'name': customer,
            'customer_name':
                launchData?['customer_name']?.toString() ?? customer,
            if (launchData?['mobile_no'] != null)
              'mobile_no': launchData!['mobile_no'].toString(),
          };
    final current = ref.read(posNotifierProvider);
    String normalizedCustomerField(Map<String, dynamic>? value, String key) =>
        value?[key]?.toString().trim() ?? '';
    final currentCustomer = current.selectedCustomer;
    final samePendingContext =
        current.isB2bOrder &&
        !current.b2bSetupComplete &&
        normalizedCustomerField(currentCustomer, 'name') == customer &&
        normalizedCustomerField(
              currentCustomer,
              'selected_shipping_address_name',
            ) ==
            normalizedCustomerField(
              selectedCustomer,
              'selected_shipping_address_name',
            ) &&
        normalizedCustomerField(
              currentCustomer,
              'selected_shipping_address_territory_pos_profile',
            ) ==
            normalizedCustomerField(
              selectedCustomer,
              'selected_shipping_address_territory_pos_profile',
            ) &&
        ((current.boundB2bOrderPurpose?.trim().isEmpty ?? true) ||
            current.boundB2bOrderPurpose?.trim() == orderPurpose);
    if (!samePendingContext &&
        !await notifier.startB2bOrder(selectedCustomer)) {
      return false;
    }

    final policyApplied =
        orderPurpose.isNotEmpty &&
        await notifier.setCommercialPolicyByOrderPurpose(orderPurpose);
    if (!policyApplied) return false;

    notifier.markB2bSetupComplete();
    return ref.read(posNotifierProvider).b2bSetupComplete;
  }

  bool _hasLaunchBranchProfile() {
    final selectedCustomer = widget.launchData?['selected_customer'];
    if (selectedCustomer is! Map) return false;
    final requiredProfile =
        selectedCustomer['selected_shipping_address_territory_pos_profile']
            ?.toString()
            .trim() ??
        '';
    return requiredProfile.isNotEmpty;
  }

  /// The order the chat reader found (`launchData['chat_order']`), or null.
  ChatPrefillOrder? _readChatOrder() {
    final launchData = widget.launchData;
    if (launchData?['mode']?.toString() != 'chat_order') return null;
    final raw = launchData?['chat_order'];
    final order = raw is ChatPrefillOrder
        ? raw
        : ChatPrefillOrder.maybeFromJson(raw);
    return (order == null || order.isEmpty) ? null : order;
  }

  String get _chatCustomerName {
    final customer = widget.launchData?['customer'];
    return customer is Map ? customer['name']?.toString().trim() ?? '' : '';
  }

  /// Applies a chat binding passed via [PosScreen.launchData]:
  /// `{mode: 'chat_order', conversation, customer, chat_order?}` (from the
  /// chat inbox's "Start order"). Once a POS profile is chosen it preselects
  /// the linked customer; when the chat's order changes the cart and a cart
  /// is already in progress, that cart is saved as a draft first so the two
  /// orders never mix. The order's lines are applied later, once, by
  /// [_scheduleChatCartApply].
  void _scheduleChatOrderBinding(PosState state) {
    final launchData = widget.launchData;
    if (launchData?['mode']?.toString() != 'chat_order') return;
    if (_chatOrderApplied) {
      _scheduleChatCartApply(state);
      return;
    }
    if (state.selectedProfile == null) return;
    final customer = launchData?['customer'];
    if (customer is! Map ||
        (customer['name']?.toString().trim().isEmpty ?? true)) {
      return;
    }
    _chatOrderApplied = true;
    _chatCartPending = _chatOrder?.changesCart ?? false;
    final selected = Map<String, dynamic>.from(customer);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(posNotifierProvider.notifier);
      final current = ref.read(posNotifierProvider);
      if (_chatCartPending &&
          (current.cartItems.isNotEmpty ||
              current.isB2bOrder ||
              current.isAmendmentDraft)) {
        notifier.newDraft();
      }
      notifier.selectCustomer(selected);
    });
  }

  /// Puts the chat's order in the cart exactly once, after the chat customer
  /// is selected AND the catalog (items + bundles) is loaded.
  void _scheduleChatCartApply(PosState state) {
    final order = _chatOrder;
    if (!_chatCartPending || order == null) return;
    final customerName = _chatCustomerName;
    if (state.isLoading ||
        state.error != null ||
        (state.items.isEmpty && state.bundles.isEmpty) ||
        customerName.isEmpty ||
        state.selectedCustomer?['name']?.toString().trim() != customerName) {
      return;
    }
    _chatCartPending = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(posNotifierProvider.notifier);
      final result = notifier.applyChatOrder(order);
      // Pickup before the codes: free-delivery promos depend on it.
      if (order.pickup) notifier.setPickup(true);
      setState(() => _chatApplyResult = result);
      if (order.promoCodes.isNotEmpty) {
        unawaited(_applyChatPromos(order.promoCodes));
      }
    });
  }

  /// The chat's promo codes, through the cart's own promo path, once the
  /// cart is filled (an empty cart leaves them "not applied").
  Future<void> _applyChatPromos(List<String> codes) async {
    final outcomes = await ref
        .read(posNotifierProvider.notifier)
        .applyChatPromoCodes(codes);
    if (!mounted) return;
    setState(() {
      final merged = [...?_chatPromoOutcomes];
      for (final outcome in outcomes) {
        merged.removeWhere((o) => o.code == outcome.code);
        merged.add(outcome);
      }
      _chatPromoOutcomes = merged;
    });
  }

  /// "Add as new address" on the chat panel: the POS address dialog opened
  /// on its new-address tab with the customer's text and map pin. Staff edit
  /// and confirm; only then is the address saved (with its pin) and selected
  /// for this order.
  Future<void> _addChatAddress() async {
    final order = _chatOrder;
    if (order == null) return;
    final customer = ref.read(posNotifierProvider).selectedCustomer;
    final customerName = customer?['name']?.toString().trim() ?? '';
    if (customer == null || customerName.isEmpty) return;
    final merged = await chooseCustomerShippingAddress(
      context,
      customer: customer,
      repository: ref.read(customerAddressRepositoryProvider),
      // Empty text with a pin still opens the new-address tab.
      initialNewAddress: order.addressText ?? '',
      initialNewLocation: chatLocationLinkValue(order.location),
    );
    if (merged == null || !mounted) return;
    final active = ref
        .read(posNotifierProvider)
        .selectedCustomer?['name']
        ?.toString()
        .trim();
    if (active != customerName) return;
    ref.read(posNotifierProvider.notifier).selectCustomer(merged);
  }

  Widget? _buildChatOrderPanel(PosState state) {
    final order = _chatOrder;
    if (order == null || _chatPanelDismissed) return null;
    final hasCustomer =
        state.selectedCustomer?['name']?.toString().trim().isNotEmpty ?? false;
    return ChatOrderPanel(
      order: order,
      result: _chatApplyResult,
      promoOutcomes: _chatPromoOutcomes,
      onApplyPromo: (code) => unawaited(_applyChatPromos([code])),
      onDismiss: () => setState(() => _chatPanelDismissed = true),
      onAddAddress: hasCustomer && !state.isB2bOrder ? _addChatAddress : null,
    );
  }

  void _scheduleB2bBinding(PosState state) {
    if (!_isB2bOrderRoute ||
        _b2bBindingApplied ||
        _b2bBindingInProgress ||
        _b2bBindingError != null ||
        (state.selectedProfile == null &&
            (!_hasLaunchBranchProfile() || state.profiles.isEmpty))) {
      return;
    }
    final hasBinding =
        widget.launchData?['customer']?.toString().trim().isNotEmpty == true;
    if (!hasBinding) return;
    _b2bBindingInProgress = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(() async {
        try {
          final applied = await _applyB2bBinding();
          if (!mounted) return;
          setState(() {
            _b2bBindingApplied = applied;
            _b2bBindingError = applied
                ? null
                : context.l10n.b2bOrderPolicyUnavailable;
          });
        } catch (error) {
          if (!mounted) return;
          setState(() {
            _b2bBindingApplied = false;
            _b2bBindingError = context.userErrorMessage(error);
          });
        } finally {
          if (mounted) setState(() => _b2bBindingInProgress = false);
        }
      }());
    });
  }

  Future<void> _retryB2bSetup() async {
    if (_b2bBindingInProgress) return;
    setState(() {
      _b2bBindingInProgress = true;
      _b2bBindingError = null;
    });
    try {
      final notifier = ref.read(posNotifierProvider.notifier);
      final current = ref.read(posNotifierProvider);
      final hasSavedContext =
          current.isB2bOrder &&
          current.selectedCustomer != null &&
          (current.boundB2bOrderPurpose?.trim().isNotEmpty ?? false);
      final applied = hasSavedContext
          ? await notifier.retryB2bPricingContext()
          : await _applyB2bBinding();
      if (!mounted) return;
      setState(() {
        _b2bBindingApplied = applied;
        _b2bBindingError = applied
            ? null
            : context.l10n.b2bOrderPolicyUnavailable;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _b2bBindingApplied = false;
        _b2bBindingError = context.userErrorMessage(error);
      });
    } finally {
      if (mounted) setState(() => _b2bBindingInProgress = false);
    }
  }

  Widget _wrapWithAmendmentCleanupGuard(Widget child) {
    if (_amendmentInvoiceId() == null) {
      return child;
    }
    return PopScope<Object?>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _scheduleAmendmentDraftCleanup();
        }
      },
      child: child,
    );
  }

  void _openKanban() {
    if (_amendmentInvoiceId() != null) {
      _scheduleAmendmentDraftCleanup();
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
        return;
      }
      context.go(AppRoutes.kanban);
      return;
    }

    context.push(AppRoutes.kanban);
  }

  Widget _buildB2bSetupRecovery(BuildContext context, PosState state) {
    final policyPending = state.isB2bOrder && !state.b2bSetupComplete;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.business_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              policyPending
                  ? context.l10n.b2bOrderSetupFailedTitle
                  : context.l10n.b2bOrderResumeTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              policyPending
                  ? (_b2bBindingError ?? context.l10n.b2bOrderPolicyUnavailable)
                  : context.l10n.b2bOrderResumeMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (policyPending) ...[
              FilledButton.icon(
                onPressed: _b2bBindingInProgress ? null : _retryB2bSetup,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.commonRetry),
              ),
              const SizedBox(height: 8),
            ],
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.b2b),
              icon: const Icon(Icons.arrow_back),
              label: Text(context.l10n.b2bOrderChooseAccount),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _hideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    // When controller goes 0→1 (forward), this animation goes 1→0 (hide)
    _hideAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _hideController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Authentication assumed handled by route guard; proceed to load profiles.

      final amendmentInvoiceData = _amendmentInvoiceData();
      if (amendmentInvoiceData != null) {
        ref
            .read(posNotifierProvider.notifier)
            .startAmendmentDraft(amendmentInvoiceData);
        // The edit's payment dialog always asks the live credit profile (the
        // invoice carries no `credit_allowed` hint), so warm it now, as the
        // customer search does when a shop is picked. A failure is the
        // dialog's to render.
        final amendmentCustomer =
            amendmentInvoiceData['customer']?.toString().trim() ?? '';
        if (amendmentCustomer.isNotEmpty) {
          unawaited(
            ref
                .read(customerCreditProfileProvider(amendmentCustomer).future)
                .catchError((Object _) => const CustomerCreditProfile()),
          );
        }
        return;
      }

      final state = ref.read(posNotifierProvider);
      if (state.isAmendmentDraft) {
        ref.read(posNotifierProvider.notifier).startNewInvoice();
      }
      if (state.selectedProfile == null) {
        ref
            .read(posNotifierProvider.notifier)
            .loadProfiles(deferSingleProfileCatalog: _isB2bOrderRoute);
      } else if (!_isB2bOrderRoute) {
        ref.read(posNotifierProvider.notifier).refreshCatalog();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute<dynamic>) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    final route = ModalRoute.of(context);
    if (route?.isCurrent ?? false) {
      final state = ref.read(posNotifierProvider);
      if (!_isB2bOrderRoute || state.b2bSetupComplete) {
        ref.read(posNotifierProvider.notifier).refreshCatalog();
      }
    }
  }

  @override
  void didPopNext() {
    final state = ref.read(posNotifierProvider);
    if (!_isB2bOrderRoute || state.b2bSetupComplete) {
      ref.read(posNotifierProvider.notifier).refreshCatalog();
    }
  }

  @override
  void dispose() {
    _scheduleAmendmentDraftCleanup();
    WidgetsBinding.instance.removeObserver(this);
    try {
      routeObserver.unsubscribe(this);
    } catch (_) {}
    _hideController.dispose();
    super.dispose();
  }

  /// Handle scroll notifications from nested scrollables (phones only).
  /// Uses accumulated delta so small per-frame deltas on 120 Hz+ screens
  /// still trigger hide/show after the user has scrolled enough.
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.axis == Axis.vertical) {
      final offset = notification.metrics.pixels;
      final delta = offset - _lastScrollOffset;
      _lastScrollOffset = offset;

      // At the very top – always show header
      if (offset <= 0) {
        _accumulatedDelta = 0;
        _showHeader();
        return false;
      }

      // Accumulate; reset when direction reverses
      if (delta > 0) {
        _accumulatedDelta = _accumulatedDelta > 0
            ? _accumulatedDelta + delta
            : delta;
      } else if (delta < 0) {
        _accumulatedDelta = _accumulatedDelta < 0
            ? _accumulatedDelta + delta
            : delta;
      }

      if (_accumulatedDelta > _scrollThreshold && _headerVisible) {
        _hideHeader();
        _accumulatedDelta = 0;
      }

      // Only auto-show when the user returns to the very top; avoid
      // popping the header back on small upward scrolls mid-list.
      if (!_headerVisible && offset < 12) {
        _showHeader();
        _accumulatedDelta = 0;
      }
    }
    return false;
  }

  void _hideHeader() {
    if (!_headerVisible) return;
    setState(() {
      _headerVisible = false;
    });
    _hideController.forward();
  }

  void _showHeader() {
    if (_headerVisible) return;
    setState(() {
      _headerVisible = true;
    });
    _hideController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posNotifierProvider);
    _scheduleB2bBinding(state);
    _scheduleChatOrderBinding(state);
    final requirePosShift = ref.watch(requirePosShiftProvider);
    final activeShiftAsync = ref.watch(activeShiftProvider);
    // Enforce POS profile selection: show startup popup chooser on entry
    if (state.selectedProfile == null) {
      if (state.isLoading) {
        return _wrapWithAmendmentCleanupGuard(
          const Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      }
      if (state.error != null && state.profiles.isEmpty) {
        return _wrapWithAmendmentCleanupGuard(
          Scaffold(body: _buildError(context, state.error!)),
        );
      }
      if (state.profiles.isEmpty) {
        return _wrapWithAmendmentCleanupGuard(
          Scaffold(body: _buildEmptyProfiles(context)),
        );
      }
      if (_isB2bOrderRoute && _b2bBindingError != null) {
        return _wrapWithAmendmentCleanupGuard(
          Scaffold(body: _buildB2bSetupRecovery(context, state)),
        );
      }
      if (_isB2bOrderRoute &&
          (_b2bBindingInProgress || _hasLaunchBranchProfile())) {
        return _wrapWithAmendmentCleanupGuard(
          const Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      }
      // Auto-select if only one profile available
      if (state.profiles.length == 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref
              .read(posNotifierProvider.notifier)
              .selectProfile(state.profiles.first);
        });
        return _wrapWithAmendmentCleanupGuard(
          const Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      }

      // Show popup chooser for multiple profiles
      if (state.profiles.isNotEmpty) {
        if (!_isProfileDialogOpen) {
          _isProfileDialogOpen = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            final selected = await showDialog<Map<String, dynamic>>(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) {
                return AlertDialog(
                  title: Text(context.l10n.posProfileSelectionTitle),
                  content: SizedBox(
                    width: ResponsiveUtils.getDialogWidth(
                      dialogContext,
                      small: 380,
                      medium: 420,
                      large: 480,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: state.profiles.length,
                      separatorBuilder: (_, x) => const Divider(height: 1),
                      itemBuilder: (ctx, index) {
                        final profile = state.profiles[index];
                        final name = (profile['name'] ?? '').toString();
                        final title =
                            (profile['title'] ?? profile['name'] ?? '')
                                .toString();
                        return ListTile(
                          leading: const Icon(Icons.store),
                          title: Text(title.isNotEmpty ? title : name),
                          subtitle: name.isNotEmpty ? Text(name) : null,
                          onTap: () => Navigator.of(dialogContext).pop(profile),
                        );
                      },
                    ),
                  ),
                );
              },
            );

            _isProfileDialogOpen = false;
            if (!mounted) return;
            if (selected != null) {
              await ref
                  .read(posNotifierProvider.notifier)
                  .selectProfile(selected);
            }
          });
        }

        return _wrapWithAmendmentCleanupGuard(
          const Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      }
      return _wrapWithAmendmentCleanupGuard(
        const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // Defence in depth behind the router's shift gate: never paint the POS UI
    // unless we hold a shift that matches THIS profile and THIS user. Checking
    // `isLoading && !hasValue` was not enough — a refresh carries the previous
    // profile's value forward, so `hasValue` stayed true across a profile
    // switch and the POS UI rendered for a profile with no shift open.
    final selectedProfileName = (state.selectedProfile?['name'] ?? '')
        .toString();
    final shiftForThisProfile = activeShiftAsync.valueOrNull;
    final hasShiftForProfile =
        shiftForThisProfile != null &&
        shiftForThisProfile.posProfile == selectedProfileName &&
        shiftForThisProfile.isCurrentUser;
    if (requirePosShift && !hasShiftForProfile) {
      return _wrapWithAmendmentCleanupGuard(
        const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final isPhone = ResponsiveUtils.isPhone(context);
    final headerHeight = ResponsiveUtils.getHeaderHeight(context);

    final header = _MergedHeader(
      state: state,
      onShowCart: () => _showCartBottomSheet(context),
      onOpenKanban: _openKanban,
      onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ref: ref,
      context: context,
    );
    // Only show the shift banner for the shift that actually gated this screen.
    // Keeping the stale value across a refresh stops the banner flickering out.
    final matchedActiveShift = hasShiftForProfile ? shiftForThisProfile : null;
    final chatOrderPanel = _buildChatOrderPanel(state);

    // ── Phone: scroll-to-hide header + FAB ──────────────────────────
    if (isPhone) {
      final primary = Theme.of(context).colorScheme.primary;
      final onPrimary = Theme.of(context).colorScheme.onPrimary;
      final statusBarHeight = MediaQuery.of(context).viewPadding.top;
      return _wrapWithAmendmentCleanupGuard(
        AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            key: _scaffoldKey,
            drawer: const AppDrawer(),
            // FAB slides out when header hides
            floatingActionButton: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: Offset.zero,
                    end: const Offset(0, 2), // slide down off screen
                  ).animate(
                    CurvedAnimation(
                      parent: _hideController,
                      curve: Curves.easeInOut,
                    ),
                  ),
              child: Consumer(
                builder: (c, ref2, _) {
                  final cartCount = ref2.watch(
                    posNotifierProvider.select((s) => s.cartItemCount),
                  );
                  return FloatingActionButton(
                    heroTag: 'pos_cart_fab',
                    onPressed: () => _showCartBottomSheet(context),
                    child: Badge(
                      isLabelVisible: cartCount > 0,
                      label: Text('$cartCount'),
                      child: const Icon(Icons.shopping_cart),
                    ),
                  );
                },
              ),
            ),
            body: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _onScrollNotification,
                      child: Column(
                        children: [
                          // Persistent primary-coloured status bar area
                          Container(
                            width: double.infinity,
                            height: statusBarHeight,
                            color: primary,
                          ),
                          // Header collapses smoothly when scrolling down
                          ClipRect(
                            child: SizeTransition(
                              sizeFactor: _hideAnim,
                              axisAlignment: -1.0, // collapse from top edge
                              child: header,
                            ),
                          ),
                          // Main content
                          // Weekly count reminder: nothing unless owed.
                          const WeeklyCountBanner(),
                          if (matchedActiveShift != null)
                            ShiftStatusBanner(shift: matchedActiveShift),
                          if (state.isAmendmentDraft)
                            _buildAmendmentDraftBanner(context, state),
                          if (chatOrderPanel != null) chatOrderPanel,
                          Expanded(
                            child: state.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : state.error != null
                                ? _buildError(context, state.error!)
                                : _buildResponsiveLayout(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Quick reveal button when header is hidden (phones only)
                  SafeArea(
                    child: Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          top: 6,
                          end: 8,
                        ),
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 200),
                          offset: _headerVisible
                              ? const Offset(0, -0.4)
                              : Offset.zero,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _headerVisible ? 0.0 : 0.9,
                            child: IgnorePointer(
                              ignoring: _headerVisible,
                              child: FloatingActionButton.small(
                                heroTag: 'pos_header_reveal',
                                tooltip: context.l10n.posShowHeaderTooltip,
                                onPressed: () {
                                  _accumulatedDelta = 0;
                                  _showHeader();
                                },
                                backgroundColor: primary,
                                foregroundColor: onPrimary,
                                child: const Icon(Icons.keyboard_arrow_down),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── Tablet: standard layout ─────────────────────────────────────
    return _wrapWithAmendmentCleanupGuard(
      Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(headerHeight),
          child: header,
        ),
        body: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Column(
            children: [
              // Weekly count reminder: nothing unless owed.
              const WeeklyCountBanner(),
              if (matchedActiveShift != null)
                ShiftStatusBanner(shift: matchedActiveShift),
              if (state.isAmendmentDraft)
                _buildAmendmentDraftBanner(context, state),
              if (chatOrderPanel != null) chatOrderPanel,
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.error != null
                    ? _buildError(context, state.error!)
                    : _buildResponsiveLayout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmendmentDraftBanner(BuildContext context, PosState state) {
    final theme = Theme.of(context);
    // Already carries its own '#' when the order came from WooCommerce.
    final invoiceId = orderDisplayId(
      state.amendmentSourceInvoiceId,
      wooOrderId: state.amendmentSourceWooOrderId,
    );
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.edit_note, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.posAmendmentDraftTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (invoiceId.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    invoiceId,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer.withValues(
                        alpha: 0.8,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  context.l10n.posAmendmentDraftMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build responsive layout that adapts to screen size.
  /// On phones (< 600px) show items full-width; cart accessible via FAB / bottom sheet.
  /// The customer search bar is animated on phones (collapses with the header).
  /// On tablets keep the side-by-side Row layout.
  Widget _buildResponsiveLayout(BuildContext context) {
    final padding = ResponsiveUtils.getResponsivePadding(
      context,
      small: 12,
      medium: 14,
      large: 16,
    );
    final isPhone = ResponsiveUtils.isPhone(context);
    final state = ref.watch(posNotifierProvider);

    if (_isB2bOrderRoute && (!state.isB2bOrder || !state.b2bSetupComplete)) {
      final policyPending = state.isB2bOrder && !state.b2bSetupComplete;
      return Column(
        children: [
          const DraftTabsBar(b2bOnly: true),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.business_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      policyPending
                          ? context.l10n.b2bOrderSetupFailedTitle
                          : context.l10n.b2bOrderResumeTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      policyPending
                          ? (_b2bBindingError ??
                                context.l10n.b2bOrderPolicyUnavailable)
                          : context.l10n.b2bOrderResumeMessage,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (policyPending) ...[
                      FilledButton.icon(
                        onPressed: _b2bBindingInProgress
                            ? null
                            : _retryB2bSetup,
                        icon: const Icon(Icons.refresh),
                        label: Text(context.l10n.commonRetry),
                      ),
                      const SizedBox(height: 8),
                    ],
                    FilledButton.icon(
                      onPressed: () => context.go(AppRoutes.b2b),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(context.l10n.b2bOrderChooseAccount),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final customerSearch = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomerSearchWidget(lockCustomer: _isB2bOrderRoute),
    );

    // Phone: customer search collapses with header
    if (isPhone) {
      return Column(
        children: [
          // Customer search slides away with the header
          ClipRect(
            child: SizeTransition(
              sizeFactor: _hideAnim, // 1→0 collapses customer search
              axisAlignment: -1.0, // collapse from top
              child: customerSearch,
            ),
          ),
          DraftTabsBar(b2bOnly: _isB2bOrderRoute),
          Expanded(child: ItemGridWidget(hideAnimation: _hideAnim)),
        ],
      );
    }

    // Tablet: side-by-side
    final itemsPanel = Column(
      children: [
        customerSearch,
        DraftTabsBar(b2bOnly: _isB2bOrderRoute),
        const Expanded(child: ItemGridWidget()),
      ],
    );
    final flexRatio = ResponsiveUtils.getCartFlexRatio(context);
    return Row(
      children: [
        Expanded(flex: flexRatio[0], child: itemsPanel),
        Expanded(flex: flexRatio[1], child: const CartWidget()),
      ],
    );
  }

  Widget _buildError(BuildContext context, String error) {
    final l10n = context.l10n;
    // A refused order edit carries the server's own reason; the generic
    // presenter would reduce most of those sentences to "something went wrong".
    final rejection = ref.read(posNotifierProvider.notifier).amendmentRejection;
    final message = rejection != null
        ? amendmentRefusalMessageFor(l10n, rejection.message)
        : context.userErrorMessage(error);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.commonError,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref
                .read(posNotifierProvider.notifier)
                .loadProfiles(deferSingleProfileCatalog: _isB2bOrderRoute),
            child: Text(l10n.commonRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProfiles(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.store_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.posProfileSelectionNoProfilesTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.posProfileSelectionNoProfilesBody,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref
                  .read(posNotifierProvider.notifier)
                  .loadProfiles(deferSingleProfileCatalog: _isB2bOrderRoute),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
            if (_isB2bOrderRoute) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.b2b),
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.b2bOrderChooseAccount),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCartBottomSheet(BuildContext context) {
    final l10n = context.l10n;
    final isPhone = ResponsiveUtils.isPhone(context);
    final initialChildSize = ResponsiveUtils.getCartBottomSheetInitialSize(
      context,
    );
    final minChildSize = ResponsiveUtils.getCartBottomSheetMinSize(context);
    final maxChildSize = ResponsiveUtils.getCartBottomSheetMaxSize(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        // Size the modal sheet to the cart itself; with the default
        // expand: true the sheet fills the screen and its empty top
        // shows as a blank box above the cart on phones.
        expand: false,
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: EdgeInsets.all(isPhone ? 12 : 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    l10n.posCartTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: isPhone ? 18 : null,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: isPhone ? 22 : null,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: SafeArea(
                  top: false,
                  child: CartWidget(scrollController: scrollController),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MergedHeader extends ConsumerWidget implements PreferredSizeWidget {
  final PosState state;
  final VoidCallback onShowCart;
  final VoidCallback onOpenKanban;
  final VoidCallback onOpenDrawer;
  final WidgetRef ref;
  final BuildContext context;
  const _MergedHeader({
    required this.state,
    required this.onShowCart,
    required this.onOpenKanban,
    required this.onOpenDrawer,
    required this.ref,
    required this.context,
    double? headerHeight,
  }) : _headerHeight = headerHeight;

  @override
  Size get preferredSize => Size.fromHeight(_headerHeight ?? 88);
  final double? _headerHeight;

  @override
  Widget build(BuildContext ctx, WidgetRef r) {
    final theme = Theme.of(ctx);
    final l10n = ctx.l10n;
    final connectivityAsync = r.watch(connectivityStatusProvider);
    final webSocketService = r.watch(webSocketServiceProvider);
    final offlineSyncService = r.watch(offlineSyncServiceProvider);
    final courierState = r.watch(courierBalancesProvider);
    final partner = r.watch(
      posNotifierProvider.select((s) => s.selectedSalesPartner),
    );
    final printer = r.watch(posPrinterServiceProvider);
    final isPhone = ResponsiveUtils.isPhone(ctx);

    // On phones condense to essential controls; move status to overflow menu
    final essentialChildren = <Widget>[
      // Hamburger menu
      IconButton(
        icon: Icon(
          Icons.menu,
          color: theme.colorScheme.onPrimary,
          size: isPhone ? 20 : 24,
        ),
        onPressed: onOpenDrawer,
        tooltip: MaterialLocalizations.of(ctx).openAppDrawerTooltip,
        visualDensity: isPhone ? VisualDensity.compact : VisualDensity.standard,
      ),
      if (!isPhone) ...[
        const SizedBox(width: 4),
        const SizedBox(width: 12),
        _vDivider(theme),
        const SizedBox(width: 12),
      ],
      // Section: Partner
      if (partner != null)
        InputChip(
          backgroundColor: theme.colorScheme.secondaryContainer,
          avatar: const Icon(Icons.handshake, size: 16),
          label: Text(
            partner['title'] ??
                partner['partner_name'] ??
                partner['name'] ??
                l10n.systemStatusPartnerChip,
            overflow: TextOverflow.ellipsis,
          ),
          onDeleted: () =>
              r.read(posNotifierProvider.notifier).setSalesPartner(null),
          deleteIcon: const Icon(Icons.close, size: 16),
        )
      else
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          onPressed: () async {
            final sel = await showDialog<Map<String, dynamic>?>(
              context: ctx,
              builder: (_) => const SalesPartnerSelectorDialog(),
            );
            if (sel != null) {
              r.read(posNotifierProvider.notifier).setSalesPartner(sel);
            }
          },
          icon: const Icon(Icons.handshake),
          label: isPhone
              ? const SizedBox.shrink()
              : Text(l10n.systemStatusPartnerChip),
        ),
      if (!isPhone) ...[
        const SizedBox(width: 12),
        _vDivider(theme),
        const SizedBox(width: 12),
      ] else
        const SizedBox(width: 4),
      // Section: POS Profile quick selector (dialog-based)
      Builder(
        builder: (bCtx) {
          final profiles = r.watch(posNotifierProvider).profiles;
          final selected = r.watch(posNotifierProvider).selectedProfile;
          final onPrimary = theme.colorScheme.onPrimary;

          if (profiles.isEmpty) {
            return Text(
              selected?['title'] ??
                  selected?['name'] ??
                  l10n.posProfileSelectionShortFallback,
              style: theme.textTheme.titleMedium?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: isPhone ? 11 : null,
              ),
            );
          }

          final label = selected != null
              ? (selected['title'] ??
                        selected['name'] ??
                        l10n.posProfileSelectionShortFallback)
                    .toString()
              : (profiles.length == 1
                    ? (profiles.first['title'] ??
                              profiles.first['name'] ??
                              l10n.posProfileSelectionShortFallback)
                          .toString()
                    : l10n.posProfileSelectionCycleHint);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: InkWell(
              onTap: () async {
                if (profiles.length == 1) {
                  r
                      .read(posNotifierProvider.notifier)
                      .selectProfile(profiles.first);
                  return;
                }
                // Cycle through profiles without modal dialog
                final currentIndex = selected != null
                    ? profiles.indexWhere((p) => p['name'] == selected['name'])
                    : -1;
                final nextIndex = (currentIndex + 1) % profiles.length;
                final nextProfile = profiles[nextIndex];
                r.read(posNotifierProvider.notifier).selectProfile(nextProfile);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isPhone ? 6 : 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: onPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: onPrimary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.store,
                      size: isPhone ? 14 : 16,
                      color: onPrimary,
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isPhone ? 80 : 200),
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onPrimary,
                          fontSize: isPhone ? 10 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_drop_down, size: 18, color: onPrimary),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ];

    // Status chips – shown inline on tablets, in trailing overflow on phones
    final statusChips = <Widget>[
      connectivityAsync.when(
        data: (isOnline) => _statusChip(
          ctx,
          icon: isOnline ? Icons.wifi : Icons.wifi_off,
          label: isOnline ? l10n.commonOnline : l10n.commonOffline,
          color: isOnline ? Colors.green : Colors.red,
        ),
        loading: () => _statusChip(
          ctx,
          icon: Icons.wifi,
          label: l10n.systemStatusChecking,
          color: Colors.orange,
        ),
        error: (e, st) => _statusChip(
          ctx,
          icon: Icons.wifi_off,
          label: l10n.commonError,
          color: Colors.red,
        ),
      ),
      const SizedBox(width: 8),
      StreamBuilder<bool>(
        stream: webSocketService.connectionStatus,
        initialData: false,
        builder: (c, snap) {
          final connected = snap.data ?? false;
          return _statusChip(
            ctx,
            icon: connected ? Icons.sync : Icons.sync_disabled,
            label: connected
                ? l10n.systemStatusRealtime
                : l10n.systemStatusNoRealtime,
            color: connected ? Colors.blue : Colors.grey,
          );
        },
      ),
      const SizedBox(width: 8),
      FutureBuilder<int>(
        future: offlineSyncService.getPendingCount(),
        builder: (c, snap) {
          final pending = snap.data ?? 0;
          return _statusChip(
            ctx,
            icon: pending == 0 ? Icons.check_circle : Icons.sync_problem,
            label: pending == 0
                ? l10n.systemStatusSynced
                : l10n.systemStatusPendingCount(pending),
            color: pending == 0 ? Colors.green : Colors.orange,
          );
        },
      ),
      const SizedBox(width: 8),
      InkWell(
        onTap: () => showCourierBalancesDialog(ctx),
        child: _statusChip(
          ctx,
          icon: courierState.hasUnsettled
              ? Icons.delivery_dining
              : Icons.local_shipping,
          label: courierState.hasUnsettled
              ? l10n.systemStatusCourierCount(courierState.unsettledCount)
              : l10n.systemStatusCouriers,
          color: courierState.hasUnsettled ? Colors.orange : Colors.grey,
        ),
      ),
      const SizedBox(width: 8),
      StreamBuilder(
        stream: Stream.periodic(const Duration(seconds: 1)),
        builder: (c, snap) {
          final now = DateTime.now();
          final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
          final minute = now.minute.toString().padLeft(2, '0');
          final period = now.hour < 12 ? 'AM' : 'PM';
          return _statusChip(
            ctx,
            icon: Icons.schedule,
            label: '$hour:$minute $period',
            color: Colors.teal,
          );
        },
      ),
    ];

    // Printer chip
    final printerChip = InkWell(
      onTap: () => context.push(AppRoutes.printers),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isPhone ? 6 : 10,
          vertical: 6,
        ),
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
            Icon(
              Icons.print,
              size: isPhone ? 14 : 16,
              color: () {
                switch (printer.unifiedStatus) {
                  case PrinterUnifiedStatus.connectedBle:
                  case PrinterUnifiedStatus.connectedClassic:
                    return Colors.greenAccent;
                  case PrinterUnifiedStatus.connecting:
                    return Colors.orangeAccent;
                  case PrinterUnifiedStatus.error:
                    return Colors.redAccent;
                  case PrinterUnifiedStatus.disconnected:
                    return Colors.redAccent;
                }
              }(),
            ),
            if (!isPhone) ...[
              const SizedBox(width: 6),
              Text(
                () {
                  switch (printer.unifiedStatus) {
                    case PrinterUnifiedStatus.connectedBle:
                      return l10n.printerStatusBle;
                    case PrinterUnifiedStatus.connectedClassic:
                      return l10n.printerStatusClassic;
                    case PrinterUnifiedStatus.connecting:
                      return l10n.printerStatusConnecting;
                    case PrinterUnifiedStatus.error:
                      return ctx.userErrorMessage(
                        printer.lastErrorMessage,
                        fallback: l10n.printerStatusError,
                      );
                    case PrinterUnifiedStatus.disconnected:
                      return l10n.printerStatusDisconnected;
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
                        return Colors.red;
                      case PrinterUnifiedStatus.disconnected:
                        return Colors.red;
                    }
                  }(),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // Action buttons
    final actionButtons = <Widget>[
      printerChip,
      SizedBox(width: isPhone ? 4 : 12),
      // Draft count badge
      Consumer(
        builder: (c, ref2, _) {
          final draftCount = ref2.watch(
            posNotifierProvider.select((s) => s.drafts.length),
          );
          if (draftCount == 0) return const SizedBox.shrink();
          return Padding(
            padding: EdgeInsetsDirectional.only(end: isPhone ? 4 : 8),
            child: Badge(
              label: Text('$draftCount'),
              child: Icon(
                Icons.layers,
                size: isPhone ? 20 : 24,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          );
        },
      ),
      IconButton(
        icon: Icon(
          Icons.view_kanban,
          color: theme.colorScheme.onPrimary,
          size: isPhone ? 20 : 24,
        ),
        tooltip: l10n.menuSalesKanban,
        onPressed: onOpenKanban,
        visualDensity: isPhone ? VisualDensity.compact : VisualDensity.standard,
      ),
      // Cart icon only shown on tablets (phones use FAB)
      if (!isPhone)
        Consumer(
          builder: (c, ref2, _) {
            final cartCount = ref2.watch(
              posNotifierProvider.select((s) => s.cartItemCount),
            );
            return Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shopping_cart,
                    color: theme.colorScheme.onPrimary,
                  ),
                  onPressed: onShowCart,
                  tooltip: l10n.posCartTitle,
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$cartCount',
                        style: TextStyle(
                          color: theme.colorScheme.onError,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      SizedBox(width: isPhone ? 2 : 12),
      // Force sync
      IconButton(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: l10n.systemStatusForceSyncTooltip,
        icon: Icon(
          Icons.refresh,
          size: isPhone ? 18 : 20,
          color: theme.colorScheme.onPrimary,
        ),
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(ctx);
          await offlineSyncService.forceSyncNow();
          await r.read(posNotifierProvider.notifier).refreshCatalog();
          await r.read(courierBalancesProvider.notifier).load();
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.systemStatusSyncComplete),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    ];

    return Material(
      elevation: 4,
      color: theme.colorScheme.primary,
      child: SafeArea(
        top: !isPhone, // phones handle status bar padding externally
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isPhone ? 4 : 12,
            vertical: isPhone ? 2 : 6,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...essentialChildren,
                if (!isPhone) ...[
                  const SizedBox(width: 12),
                  _vDivider(theme),
                  const SizedBox(width: 12),
                  ...statusChips,
                  const SizedBox(width: 12),
                  _vDivider(theme),
                  const SizedBox(width: 12),
                ],
                ...actionButtons,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider(ThemeData theme) => Container(
    width: 1,
    height: 24,
    color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
  );
}

// Footer removed: printer status now lives in header
