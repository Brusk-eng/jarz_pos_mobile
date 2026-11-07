import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';
import '../../features/auth/state/login_notifier.dart';
import '../../features/manager/state/manager_providers.dart';
import '../../features/pos/presentation/widgets/courier_balances_dialog.dart';
import '../localization/locale_notifier.dart';
import '../localization/localization_extensions.dart';
import '../network/user_service.dart';
import '../../features/pos/state/pos_notifier.dart';
import '../../features/shift/state/shift_notifier.dart';
import '../../features/labels/state/labels_notifier.dart';
import '../../features/courier_alerts/state/courier_alerts_providers.dart';
import '../../features/purchase_request/state/purchase_request_notifier.dart';
import '../../features/approvals/presentation/pending_approvals_widgets.dart';
import '../../features/cash_custody/state/cash_custody_notifier.dart';
import '../../features/chat_inbox/state/chat_providers.dart';
import '../../features/weekly_count/presentation/widgets/weekly_count_drawer_tiles.dart';
import '../../features/stock_transfer/state/stock_handover_providers.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canAccessB2b = ref.watch(canAccessB2bProvider);
    final canAccessManagerDashboardRole = ref.watch(
      canAccessManagerDashboardRoleProvider,
    );
    final canAccessShiftMonitor = ref.watch(canAccessShiftMonitorProvider);
    final canActAsLineManager = ref.watch(canActAsLineManagerProvider);
    final managerAccess = canAccessManagerDashboardRole
        ? ref.watch(managerAccessProvider)
        : const AsyncValue<bool>.data(false);
    final requirePosShift = ref.watch(requirePosShiftProvider);
    final activeShiftAsync = ref.watch(activeShiftProvider);
    // "End Shift" must only appear for a shift this user opened on the profile
    // they are currently on — any other open shift is not theirs to close.
    final selectedProfileName = ref.watch(
      posNotifierProvider.select(
        (s) => (s.selectedProfile?['name'] ?? '').toString(),
      ),
    );
    final activeShift = activeShiftAsync.valueOrNull;
    final hasActiveShift =
        activeShift != null &&
        activeShift.posProfile == selectedProfileName &&
        activeShift.isCurrentUser;
    final hasManagerAccess = managerAccess.maybeWhen(
      data: (v) => v,
      orElse: () => false,
    );
    // Each gate below mirrors the role set its own endpoint accepts. Verified
    // against production 2026-09-26 by evaluating every screen's server gate
    // as a real member of each Jarz role profile.
    final canAccessMasterOrders = ref.watch(canAccessMasterOrdersProvider);
    final canViewLiveCourierMap = ref.watch(canViewLiveCourierMapProvider);
    final canViewPricing = ref.watch(canViewPricingProvider);
    final canAccessBranchAccess = ref.watch(canAccessBranchAccessProvider);
    final canAccessFollowups = ref.watch(canAccessFollowupsProvider);
    final canViewFollowupStats = ref.watch(canViewFollowupStatsProvider);
    final canAccessChats = ref.watch(canAccessChatsProvider);
    final canRaiseItemRequest = ref.watch(canRaiseItemRequestProvider);
    final canManageUsers = ref.watch(canManageUsersProvider);
    final canAccessProductionBoard =
        ref.watch(canAccessProductionBoardProvider);
    // Each of these mirrors the role set its OWN API accepts. `hasManagerAccess`
    // is the manager-*dashboard* gate, and the dashboard deliberately admits the
    // line-manager tier — so gating these five on it showed a line manager tiles
    // that answered "Not permitted" on every call.
    final canAccessCashTransfer = ref.watch(canAccessCashTransferProvider);
    // A manager or a custody holder, as the server says; the Cash Transfer
    // tier stands in until that answer arrives (see the provider).
    final canAccessCashCustody = ref.watch(custodyMenuVisibleProvider);
    final canAccessPartnerSettlements =
        ref.watch(canAccessPartnerSettlementsProvider);
    final canAccessWooSync = ref.watch(canAccessWooSyncProvider);
    final canAccessTaskBoard = ref.watch(canAccessTaskBoardProvider);
    final canAccessStockTransfer = ref.watch(canAccessStockTransferProvider);
    // Wider than [canAccessStockTransfer] on purpose: the screen now also holds
    // stock handovers, which the production team and the cashier holding a
    // branch's open shift take part in. Replenishment keeps the narrow gate.
    final canOpenStockTransfer = ref.watch(canOpenStockTransferProvider);
    final canAccessInventoryCount = ref.watch(canAccessInventoryCountProvider);
    // Branch weekly count: gated on the server's own answer (the branches the
    // user may count, and `is_approver`), not on a role, because who counts
    // is decided by POS Profile membership.
    final weeklyCount = ref.watch(weeklyCountDrawerStateProvider);
    final canAccessPurchaseInvoice =
        ref.watch(canAccessPurchaseInvoiceProvider);
    final canAccessReportsHub = ref.watch(canAccessReportsHubProvider);
    // The revenue dashboard's endpoint takes JARZ Manager / Administrator
    // only, the same set as every analytics report on the hub.
    final canViewAllReports = ref.watch(canViewAllReportsProvider);
    // Mirrors `api/monthly_expenses.py`'s own gate (JARZ Manager,
    // Administrator, System Manager, Accounts Manager) — NOT the wider
    // manager-dashboard gate, and not the `ROLES.MANAGER` set behind Cash
    // Transfer either, which also admits Stock / Manufacturing / Purchase
    // Manager. A drawer gate wider than the server gate is the recurring bug in
    // this app: the tile appears and every call on the screen answers "Not
    // permitted".
    final canAccessMonthlyExpenses =
        ref.watch(canAccessMonthlyExpensesProvider);
    final locale = ref.watch(localeNotifierProvider);
    final openItemRequests = ref.watch(itemRequestCountsProvider).maybeWhen(
          data: (c) => c.open,
          orElse: () => 0,
        );
    // Only the courier-map tier is asked (the provider itself refuses to call
    // the server for anyone else), so this never costs another role a request.
    final openCourierAlerts = canViewLiveCourierMap
        ? ref.watch(courierAlertCountsProvider).maybeWhen(
              data: (c) => c.openCount,
              orElse: () => 0,
            )
        : 0;
    final englishLocale = const Locale('en');
    final arabicLocale = const Locale('ar');
    final currentLocale = locale?.languageCode ?? englishLocale.languageCode;
    final isArabic = currentLocale == arabicLocale.languageCode;
    final selectedLanguageLabel = l10n.menuSelectedLanguage(
      describeLocale(context, isArabic ? arabicLocale : englishLocale),
    );

    Future<void> changeLanguage(Locale targetLocale) async {
      final notifier = ref.read(localeNotifierProvider.notifier);
      final languageName = describeLocale(context, targetLocale);
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (dialogCtx) => AlertDialog(
              title: Text(l10n.menuLanguage),
              content: Text(l10n.menuConfirmLanguage(languageName)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(true),
                  child: Text(l10n.commonConfirm),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;

      await notifier.setLocale(targetLocale);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.languageChanged(languageName))),
      );
    }

    // Navigate helper: preserve the existing behavior (close drawer, then go).
    void navigate(String route) {
      Navigator.pop(context);
      context.go(route);
    }

    ListTile navTile({
      required IconData icon,
      required String title,
      required VoidCallback onTap,
    }) {
      return ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(icon),
        title: Text(title),
        onTap: onTap,
      );
    }

    // Current location, used to auto-expand the group holding the active route.
    String currentLocation;
    try {
      // The path only: a query string (`/manufacturing?tab=…`) would defeat
      // both the exact and the prefix match below.
      currentLocation = GoRouterState.of(context).uri.path;
    } catch (_) {
      currentLocation = '';
    }
    bool matchesRoute(List<String> routes) => routes.any(
      (r) => currentLocation == r || currentLocation.startsWith('$r/'),
    );

    // ── Group child lists (each item keeps its original route/gate/icon) ──
    //
    // Eight short groups rather than seven long ones: the old "Purchasing" and
    // "Management" groups had grown to six and eleven entries of unrelated
    // work (stock next to production, rota next to InstaPay). Every entry keeps
    // the gate it had; only the group it sits in moved.

    // Sales: taking and following orders.
    final salesChildren = <Widget>[
      navTile(
        icon: Icons.point_of_sale,
        title: l10n.menuPointOfSale,
        onTap: () => navigate(AppRoutes.pos),
      ),
      if (requirePosShift && hasActiveShift)
        navTile(
          icon: Icons.timer_off,
          title: l10n.menuEndShift,
          onTap: () => navigate(AppRoutes.shiftEnd),
        ),
      navTile(
        icon: Icons.view_kanban,
        title: l10n.menuSalesKanban,
        onTap: () => navigate(AppRoutes.kanban),
      ),
      if (canAccessMasterOrders)
        navTile(
          icon: Icons.list_alt,
          title: l10n.menuMasterOrders,
          onTap: () => navigate(AppRoutes.masterOrders),
        ),
      // Customer chats (WhatsApp / Instagram / Messenger) with the AI reply
      // copilot: moderators and the manager tier, as `api/chat.py` enforces.
      if (canAccessChats) _ChatsNavTile(onTap: () => navigate(AppRoutes.chats)),
      // Ungated on purpose: `api/promo.lookup_promo_code` only needs a login,
      // and anyone at the counter or on the phone may be asked what a code is.
      navTile(
        icon: Icons.local_offer_outlined,
        title: l10n.promoLookupMenuTitle,
        onTap: () => navigate(AppRoutes.promoLookup),
      ),
    ];

    final deliveryChildren = <Widget>[
      // Supervisor-only, mirroring the tracking API's `_ensure_ops_permission`,
      // which deliberately excludes couriers: a courier may see their own run,
      // never a colleague's live position. Line managers see their own
      // branches (`ROLES.COURIER_MAP_VIEWER`).
      if (canViewLiveCourierMap)
        navTile(
          icon: Icons.map_outlined,
          title: l10n.menuLiveCourierMap,
          onTap: () => navigate(AppRoutes.fleetMap),
        ),
      // Same audience as the map: `jarz_courier.api.alerts` is gated on
      // `ROLES.COURIER_MAP_VIEWER`.
      if (canViewLiveCourierMap)
        _CourierAlertsNavTile(onTap: () => navigate(AppRoutes.courierAlerts)),
      navTile(
        icon: Icons.local_shipping_outlined,
        title: l10n.menuDeliveryTrips,
        onTap: () => navigate(AppRoutes.trips),
      ),
      navTile(
        icon: Icons.local_shipping,
        title: l10n.menuCourierBalances,
        onTap: () {
          Navigator.pop(context);
          showCourierBalancesDialog(context);
        },
      ),
    ];

    // B2B customers and what they pay. Price Lists used to be a one-entry
    // group of its own.
    final b2bChildren = <Widget>[
      if (canAccessB2b)
        navTile(
          icon: Icons.handshake_outlined,
          title: l10n.menuB2bMode,
          onTap: () => navigate(AppRoutes.b2b),
        ),
      if (canAccessB2b)
        navTile(
          icon: Icons.view_kanban_outlined,
          title: l10n.b2bActivePipelineBoard,
          onTap: () => navigate(AppRoutes.b2bPipeline),
        ),
      if (canAccessB2b)
        navTile(
          icon: Icons.travel_explore,
          title: l10n.menuLeads,
          onTap: () => navigate(AppRoutes.leads),
        ),
      // Printed-label stock per B2B customer. The badge carries the count that
      // has to go to the print house, so the shortage is visible from the drawer
      // without opening the board — printing takes days, so noticing late is the
      // whole failure mode.
      if (canAccessB2b)
        _LabelsNavTile(onTap: () => navigate(AppRoutes.labels)),
      if (canViewPricing)
        navTile(
          icon: Icons.sell_outlined,
          title: l10n.menuPriceLists,
          onTap: () => navigate(AppRoutes.pricing),
        ),
    ];

    final financeChildren = <Widget>[
      navTile(
        icon: Icons.receipt_long,
        title: l10n.menuExpenses,
        onTap: () => navigate(AppRoutes.expenses),
      ),
      if (canAccessMonthlyExpenses)
        navTile(
          icon: Icons.calendar_month_outlined,
          title: l10n.menuMonthlyExpenses,
          onTap: () => navigate(AppRoutes.monthlyExpenses),
        ),
      if (canAccessCashTransfer)
        navTile(
          icon: Icons.account_balance_wallet,
          title: l10n.menuCashTransfer,
          onTap: () => navigate(AppRoutes.cashTransfer),
        ),
      if (canAccessCashCustody)
        navTile(
          icon: Icons.wallet,
          title: l10n.menuCashCustody,
          onTap: () => navigate(AppRoutes.cashCustody),
        ),
      // Same tier as Cash Transfer, and for the same reason: settling a
      // delivery partner posts the weekly bank transfer and settling a sales
      // partner posts a commission entry. Gating this on manager-dashboard
      // access instead would offer a line manager a tile that 403s.
      if (canAccessPartnerSettlements)
        navTile(
          icon: Icons.request_quote_outlined,
          title: l10n.partnerSettlementMenuTitle,
          onTap: () => navigate(AppRoutes.partnerSettlements),
        ),
      if (hasManagerAccess)
        navTile(
          icon: Icons.account_balance_outlined,
          title: l10n.menuInstapayReconciliation,
          onTap: () => navigate(AppRoutes.instapayReconciliation),
        ),
      // Gated on the same manager-dashboard access as the Employee Ledger it
      // mirrors: `get_credit_ledger` is the customer analogue of
      // `get_employee_ledger` and accepts the same role set, so a wider gate
      // here would be a tile that 403s on tap.
      if (hasManagerAccess)
        navTile(
          icon: Icons.credit_score_outlined,
          title: l10n.menuCreditAccounts,
          onTap: () => navigate(AppRoutes.creditAccounts),
        ),
    ];

    final inventoryChildren = <Widget>[
      // Ungated on purpose: anyone who notices a shortage can raise a request,
      // and the server gate (ROLES.PURCHASE_REQUEST) is deliberately the widest
      // in the app. Hiding this behind manager access would defeat the feature.
      if (canRaiseItemRequest)
        _ItemRequestsNavTile(onTap: () => navigate(AppRoutes.itemRequests)),
      if (canAccessPurchaseInvoice)
        navTile(
          icon: Icons.receipt_long,
          title: l10n.menuPurchaseInvoice,
          onTap: () => navigate(AppRoutes.purchase),
        ),
      // Split rather than sharing one gate: Stock Transfer answers to
      // `ROLES.STOCK_TRANSFER` (the manager set PLUS the line-manager tier —
      // moving stock between a branch and Finished Goods is floor work) and
      // Inventory Count to `ROLES.STOCK`, which excludes the Purchase Manager
      // and the line manager both.
      if (canAccessStockTransfer)
        navTile(
          icon: Icons.local_shipping,
          title: l10n.menuReplenishment,
          // Same gate as Stock Transfer, and it has to be: the screen sends
          // through `submit_transfer`, so a wider gate here would put a tile in
          // front of somebody every call on it answers "Not permitted" to.
          onTap: () => navigate(AppRoutes.replenishment),
        ),
      if (canOpenStockTransfer)
        navTile(
          icon: Icons.swap_horiz,
          title: l10n.menuStockTransfer,
          onTap: () => navigate(AppRoutes.stockTransfer),
        ),
      if (canAccessInventoryCount)
        navTile(
          icon: Icons.inventory,
          title: l10n.menuInventoryCount,
          onTap: () => navigate(AppRoutes.inventoryCount),
        ),
      if (weeklyCount.canCount)
        WeeklyCountNavTile(onTap: () => navigate(AppRoutes.weeklyCount)),
      if (weeklyCount.isApprover)
        WeeklyCountApprovalsNavTile(
          onTap: () => navigate(AppRoutes.weeklyCountApprovals),
        ),
    ];

    // Gated on its own role set rather than the general manager one: the
    // production API accepts stock/manufacturing managers that
    // `hasManagerAccess` misses, and rejects line/POS managers that it
    // includes. Showing a tile that 403s on every call is the bug this avoids.
    final productionChildren = <Widget>[
      if (canAccessProductionBoard)
        navTile(
          icon: Icons.factory,
          title: l10n.menuProductionBoard,
          // The collapsed Today screen, not the five-tab board: the board is
          // complete and correct and went unused for three months because it
          // asks the person holding the tablet to hold the whole document
          // lifecycle in their head. The full board is still one tap away,
          // from Today's own app bar.
          onTap: () => navigate(AppRoutes.productionToday),
        ),
      // The other half of Send to Branches: what to MAKE so there is enough
      // to send. Read only, and gated on the production view set because
      // that is what its endpoint accepts.
      if (canAccessProductionBoard)
        navTile(
          icon: Icons.event_repeat,
          title: l10n.menuProductionRound,
          onTap: () => navigate(AppRoutes.productionRound),
        ),
    ];

    // People and shifts: who works where and when, and what they are doing.
    final teamChildren = <Widget>[
      // Mirrors `ROLES.LINE_MANAGER_TIER`, the board-user gate of
      // `api/tasks.py`; the board itself trusts `get_board_context`.
      if (canAccessTaskBoard)
        navTile(
          icon: Icons.task_alt,
          title: l10n.tasksMenuTitle,
          onTap: () => navigate(AppRoutes.tasks),
        ),
      // Gated on the line-manager tier, which is exactly the set
      // `api/roster.py` accepts — a narrower gate here would be a dead tile,
      // a wider one a tile that 403s on tap.
      if (canActAsLineManager)
        navTile(
          icon: Icons.calendar_month,
          title: l10n.menuShiftDistribution,
          onTap: () => navigate(AppRoutes.roster),
        ),
      // Sits immediately after the rota it is read against, on the same gate:
      // `api/attendance.py` accepts exactly the line-manager tier.
      if (canActAsLineManager)
        navTile(
          icon: Icons.how_to_reg_outlined,
          title: l10n.menuAttendance,
          onTap: () => navigate(AppRoutes.attendance),
        ),
      if (hasManagerAccess && canAccessShiftMonitor)
        navTile(
          icon: Icons.timeline,
          title: l10n.menuShiftMonitor,
          onTap: () => navigate(AppRoutes.shiftMonitor),
        ),
      // `api/branch_access.py` accepts exactly the line-manager tier (a line
      // manager sees only their own branches) -- not the POS Manager that
      // `canActAsLineManager` folds in.
      if (canAccessBranchAccess)
        navTile(
          icon: Icons.key_outlined,
          title: l10n.menuBranchAccess,
          onTap: () => navigate(AppRoutes.branchAccess),
        ),
    ];

    final managementChildren = <Widget>[
      if (hasManagerAccess)
        navTile(
          icon: Icons.dashboard,
          title: l10n.menuManagerDashboard,
          onTap: () => navigate(AppRoutes.manager),
        ),
      // Kept for the line-manager tier: the hub still holds one report they may
      // read (Materials & Consumables), and the hub itself drops every tile
      // their role would be refused on, so the entry is never a dead end.
      if (canAccessReportsHub)
        navTile(
          icon: Icons.bar_chart,
          title: l10n.menuReports,
          onTap: () => navigate(AppRoutes.reports),
        ),
      // The sender's daily follow-up list. `api/customer_followups.py`
      // accepts the line-manager tier (managers and line managers).
      if (canAccessFollowups)
        navTile(
          icon: Icons.support_agent_outlined,
          title: l10n.followupsMenuTitle,
          onTap: () => navigate(AppRoutes.followups),
        ),
      // What the follow-ups sent and brought in. Same gate as the old stats
      // links: managers only.
      if (canViewFollowupStats)
        navTile(
          icon: Icons.insights_outlined,
          title: l10n.followupResultsTitle,
          onTap: () => navigate(AppRoutes.followupResults),
        ),
      // Gated on the OTHER app's `ROLES.OPERATOR`, which includes JARZ Manager
      // by the owner's decision, plus the dedicated `WooCommerce Sync Operator`
      // role for anyone who runs the sync without being a manager. The
      // destructive operations behind that app stay System-Manager-only and are
      // not reachable from here at all.
      if (canAccessWooSync)
        navTile(
          icon: Icons.sync_outlined,
          title: l10n.wooSyncMenuTitle,
          onTap: () => navigate(AppRoutes.wooSync),
        ),
      // Create, edit, disable, delete users and set passwords. Mirrors
      // `services/user_admin.ACCESS_ROLES`: JARZ Manager and the admin tier.
      if (canManageUsers)
        navTile(
          icon: Icons.manage_accounts_outlined,
          title: l10n.menuUsers,
          onTap: () => navigate(AppRoutes.users),
        ),
    ];

    final groups = <_DrawerGroupSpec>[
      _DrawerGroupSpec(
        id: 'sales',
        icon: Icons.point_of_sale,
        label: l10n.drawerGroupPosSales,
        children: salesChildren,
        routes: const [
          AppRoutes.pos,
          AppRoutes.shiftEnd,
          AppRoutes.kanban,
          AppRoutes.masterOrders,
          AppRoutes.chats,
          AppRoutes.promoLookup,
        ],
      ),
      _DrawerGroupSpec(
        id: 'delivery',
        icon: Icons.local_shipping_outlined,
        label: l10n.drawerGroupDelivery,
        children: deliveryChildren,
        routes: const [
          AppRoutes.trips,
          AppRoutes.fleetMap,
          AppRoutes.courierAlerts,
        ],
        // The group starts collapsed, so a dot on the header is the only sign
        // that an alert is waiting inside it.
        badge: openCourierAlerts > 0
            ? const _CourierAlertsBadge(dotOnly: true)
            : null,
      ),
      _DrawerGroupSpec(
        id: 'b2b',
        icon: Icons.handshake_outlined,
        label: l10n.drawerGroupCrm,
        children: b2bChildren,
        routes: const [
          AppRoutes.b2b,
          AppRoutes.b2bPipeline,
          AppRoutes.leads,
          AppRoutes.labels,
          AppRoutes.pricing,
        ],
      ),
      _DrawerGroupSpec(
        id: 'finance',
        icon: Icons.account_balance_wallet,
        label: l10n.drawerGroupFinance,
        children: financeChildren,
        routes: const [
          AppRoutes.expenses,
          AppRoutes.monthlyExpenses,
          AppRoutes.cashTransfer,
          AppRoutes.cashCustody,
          AppRoutes.partnerSettlements,
          AppRoutes.instapayReconciliation,
          AppRoutes.creditAccounts,
          AppRoutes.creditAccountDetail,
        ],
      ),
      _DrawerGroupSpec(
        id: 'inventory',
        icon: Icons.inventory_2_outlined,
        label: l10n.drawerGroupPurchasing,
        children: inventoryChildren,
        routes: const [
          AppRoutes.purchase,
          AppRoutes.itemRequests,
          AppRoutes.replenishment,
          AppRoutes.stockTransfer,
          AppRoutes.inventoryCount,
          AppRoutes.weeklyCount,
        ],
        // The group starts collapsed, so without this the open-request count
        // on its child tile is invisible until someone thinks to expand it.
        // Null when there is nothing open, so the header is the plain one.
        // A weekly count still owed gets the same dot when no request does.
        badge: openItemRequests > 0
            ? const _ItemRequestsBadge(dotOnly: true)
            : weeklyCount.due
            ? WeeklyCountDueDot(urgent: weeklyCount.urgent)
            : null,
      ),
      _DrawerGroupSpec(
        id: 'production',
        icon: Icons.factory_outlined,
        label: l10n.drawerGroupProduction,
        children: productionChildren,
        routes: const [
          // `/manufacturing/today` is caught by the prefix rule on
          // `/manufacturing`, but the tile points at it, so it is named too:
          // a list that only names the route nobody navigates to is one rename
          // away from silently losing the highlight.
          AppRoutes.manufacturing,
          AppRoutes.productionToday,
          AppRoutes.productionRound,
        ],
      ),
      _DrawerGroupSpec(
        id: 'team',
        icon: Icons.groups_outlined,
        label: l10n.drawerGroupTeam,
        children: teamChildren,
        routes: const [
          AppRoutes.tasks,
          AppRoutes.roster,
          AppRoutes.attendance,
          AppRoutes.shiftMonitor,
          AppRoutes.branchAccess,
        ],
      ),
      _DrawerGroupSpec(
        id: 'management',
        icon: Icons.insights,
        label: l10n.drawerGroupManagement,
        children: managementChildren,
        routes: const [
          AppRoutes.manager,
          // `matchesRoute` also matches `$route/...`, so this one entry
          // highlights the group on every report (`/reports/...`), including
          // reports added later.
          AppRoutes.reports,
          AppRoutes.followups,
          AppRoutes.followupResults,
          AppRoutes.wooSync,
          AppRoutes.users,
        ],
      ),
    ].where((g) => g.children.isNotEmpty).toList();

    // Open the group holding the active route; fall back to the first group
    // (Sales) so the drawer never opens as a wall of collapsed headers.
    final activeGroup = groups
        .where((g) => matchesRoute(g.routes))
        .map((g) => g.id)
        .firstOrNull;
    final initiallyOpen =
        activeGroup ?? (groups.isEmpty ? null : groups.first.id);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_DrawerHeaderTitle()],
            ),
          ),
          // One tap from the menu to the day's revenue: top level, above every
          // collapsible group, so it is never hidden inside a closed one.
          if (canViewAllReports)
            ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: const Icon(Icons.insights),
              title: Text(l10n.rptRevenueDashboardTitle),
              selected: currentLocation == AppRoutes.reportsRevenueDashboard,
              onTap: () => navigate(AppRoutes.reportsRevenueDashboard),
            ),
          // Everything awaiting this user's approval, above the groups so it
          // is never hidden inside a collapsed one. Renders nothing when there
          // is nothing to do or the user approves nothing.
          const PendingApprovalsDrawerSection(),
          _DrawerGroups(groups: groups, initiallyOpen: initiallyOpen),
          const Divider(),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.menuAbout),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRoutes.about);
            },
          ),
          SwitchListTile.adaptive(
            dense: true,
            visualDensity: VisualDensity.compact,
            secondary: const Icon(Icons.language),
            title: Text(l10n.menuLanguage),
            subtitle: Text(selectedLanguageLabel),
            value: isArabic,
            onChanged: (value) {
              final targetLocale = value ? arabicLocale : englishLocale;
              if (targetLocale.languageCode != currentLocale) {
                changeLanguage(targetLocale);
              }
            },
          ),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.logout),
            title: Text(l10n.menuLogout),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(loginNotifierProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerHeaderTitle extends StatelessWidget {
  const _DrawerHeaderTitle();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          l10n.drawerHeaderTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.drawerHeaderSubtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}

/// One collapsible section of the drawer.
class _DrawerGroupSpec {
  final String id;
  final IconData icon;
  final String label;
  final List<Widget> children;

  /// Routes whose screens live in this group; the group holding the current
  /// route opens when the drawer does.
  final List<String> routes;
  final Widget? badge;

  const _DrawerGroupSpec({
    required this.id,
    required this.icon,
    required this.label,
    required this.children,
    required this.routes,
    this.badge,
  });
}

/// The drawer's groups as an accordion: opening one closes whichever was open,
/// so the drawer stays one group deep instead of growing into a long scroll.
class _DrawerGroups extends StatefulWidget {
  final List<_DrawerGroupSpec> groups;
  final String? initiallyOpen;

  const _DrawerGroups({required this.groups, required this.initiallyOpen});

  @override
  State<_DrawerGroups> createState() => _DrawerGroupsState();
}

class _DrawerGroupsState extends State<_DrawerGroups> {
  // Keyed by group id, not position: gates resolve asynchronously, so a group
  // can appear after the first build and shift the ones below it.
  final Map<String, ExpansibleController> _controllers = {};

  ExpansibleController _controllerFor(String id) =>
      _controllers.putIfAbsent(id, ExpansibleController.new);

  void _onExpansionChanged(String id, bool expanded) {
    if (!expanded) return;
    for (final entry in _controllers.entries) {
      if (entry.key != id && entry.value.isExpanded) entry.value.collapse();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final g in widget.groups)
          ExpansionTile(
            // A ValueKey, not a PageStorageKey: page storage outlives the
            // drawer and would reopen a stale group alongside the one holding
            // the current route. The controller is the only source of state.
            key: ValueKey<String>('drawer-group-${g.id}'),
            controller: _controllerFor(g.id),
            leading: Icon(g.icon),
            title: g.badge == null
                ? Text(g.label, style: theme.textTheme.titleSmall)
                : Row(
                    children: [
                      Flexible(
                        child: Text(
                          g.label,
                          style: theme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      g.badge!,
                    ],
                  ),
            initiallyExpanded: g.id == widget.initiallyOpen,
            onExpansionChanged: (expanded) =>
                _onExpansionChanged(g.id, expanded),
            visualDensity: VisualDensity.compact,
            shape: const Border(),
            collapsedShape: const Border(),
            childrenPadding: const EdgeInsetsDirectional.only(start: 16),
            children: g.children,
          ),
      ],
    );
  }
}

/// Drawer entry for team item requests, badged with how many are still open.
///
/// Red while any open request has not been accepted by a buyer — that is the
/// part that needs someone to act — and neutral once every open one has been.
class _ItemRequestsNavTile extends ConsumerWidget {
  final VoidCallback onTap;

  const _ItemRequestsNavTile({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(itemRequestCountsProvider).maybeWhen(
          data: (c) => c.open,
          orElse: () => 0,
        );
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: const Icon(Icons.playlist_add),
      title: Text(context.l10n.menuItemRequests),
      // Null rather than an empty widget: any trailing slot, even an empty
      // one, reserves space and shifts the title.
      trailing: open > 0 ? const _ItemRequestsBadge() : null,
      onTap: onTap,
    );
  }
}

class _ItemRequestsBadge extends ConsumerWidget {
  /// A plain dot for the collapsed group header, the number on the tile.
  final bool dotOnly;

  const _ItemRequestsBadge({this.dotOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(itemRequestCountsProvider).maybeWhen(
          data: (c) => c,
          orElse: () => null,
        );
    if (counts == null || counts.open == 0) return const SizedBox.shrink();

    final color = counts.unacknowledged > 0
        ? const Color(0xFFB3261E)
        : Colors.blueGrey.shade600;
    if (dotOnly) {
      return Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${counts.open}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Drawer entry for courier alerts, badged with how many are still open and
/// red while any of them is High severity.
class _CourierAlertsNavTile extends ConsumerWidget {
  final VoidCallback onTap;

  const _CourierAlertsNavTile({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(courierAlertCountsProvider).maybeWhen(
          data: (c) => c.openCount,
          orElse: () => 0,
        );
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: const Icon(Icons.notification_important_outlined),
      title: Text(context.l10n.courierAlertsTitle),
      trailing: open > 0 ? const _CourierAlertsBadge() : null,
      onTap: onTap,
    );
  }
}

class _CourierAlertsBadge extends ConsumerWidget {
  /// A plain dot for the collapsed group header, the number on the tile.
  final bool dotOnly;

  const _CourierAlertsBadge({this.dotOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(courierAlertCountsProvider).maybeWhen(
          data: (c) => c,
          orElse: () => null,
        );
    if (counts == null || counts.openCount == 0) {
      return const SizedBox.shrink();
    }
    final color = counts.highCount > 0
        ? const Color(0xFFB3261E)
        : Colors.blueGrey.shade600;
    if (dotOnly) {
      return Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${counts.openCount}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Drawer entry for the chat inbox, badged with the unread inbound messages
/// across every conversation (`get_unread_total`). The provider is
/// `autoDispose` and re-reads on each `jarz_chat_update`, and renders no
/// badge while pending or on error.
class _ChatsNavTile extends ConsumerWidget {
  final VoidCallback onTap;

  const _ChatsNavTile({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(chatUnreadTotalProvider).maybeWhen(
          data: (total) => total.unreadTotal,
          orElse: () => 0,
        );

    return ListTile(
      key: const ValueKey('drawer-chats'),
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: const Icon(Icons.forum_outlined),
      title: Text(context.l10n.chatNavLabel),
      trailing: count <= 0
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFB3261E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      onTap: onTap,
    );
  }
}

/// Drawer entry for the B2B customer-label board, badged with how many labels
/// currently need printing.
///
/// The count is its own cheap endpoint rather than the full board payload, and
/// the provider is `autoDispose`, so opening the drawer re-asks instead of
/// showing whatever the first read of the session returned. A failed or pending
/// read simply renders no badge — a stale or wrong number here would be worse
/// than none.
class _LabelsNavTile extends ConsumerWidget {
  final VoidCallback onTap;

  const _LabelsNavTile({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(labelAlertCountProvider).maybeWhen(
          data: (summary) => summary.needsAttention,
          orElse: () => 0,
        );

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: const Icon(Icons.label_important_outline),
      title: Text(context.l10n.labelsTitle),
      trailing: count == 0
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFB3261E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      onTap: onTap,
    );
  }
}
