import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'constants/app_routes.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/pos/presentation/screens/pos_screen.dart';
import '../features/pos/presentation/screens/pos_profile_selection_screen.dart';
import '../features/kanban/screens/kanban_board_screen.dart';
import 'session/session_manager.dart';
import '../features/printing/printer_selection_screen.dart'
    if (dart.library.html) '../features/printing/printer_selection_screen_web.dart';
import '../features/manager/presentation/manager_dashboard_screen.dart';
import '../features/roster/presentation/roster_screen.dart';
import '../features/attendance/presentation/attendance_screen.dart';
import '../features/branch_access/presentation/branch_access_screen.dart';
import '../features/shift_monitor/presentation/shift_monitor_screen.dart';
import '../features/purchase/presentation/purchase_screen.dart';
import '../features/purchase_request/presentation/purchase_requests_screen.dart';
import '../features/manufacturing/presentation/manufacturing_screen.dart';
import '../features/manufacturing/presentation/screens/sop_execute_screen.dart';
import '../features/stock_transfer/presentation/stock_transfer_screen.dart';
import '../features/production_round/presentation/production_round_screen.dart';
import '../features/replenishment/presentation/replenishment_screen.dart';
import '../features/cash_transfer/presentation/cash_transfer_screen.dart';
import '../features/cash_custody/presentation/cash_custody_screen.dart';
import '../features/tasks/presentation/task_detail_screen.dart';
import '../features/tasks/presentation/task_overview_screen.dart';
import '../features/tasks/presentation/tasks_board_screen.dart';
import '../features/user_admin/presentation/courier_setup_screen.dart';
import '../features/user_admin/presentation/user_admin_form_screen.dart';
import '../features/user_admin/presentation/user_admin_list_screen.dart';
import '../features/geo/presentation/screens/address_pin_screen.dart';
import '../features/inventory_count/presentation/inventory_count_screen.dart';
import '../features/partner_settlements/presentation/partner_settlements_screen.dart';
import '../features/followups/presentation/screens/followup_results_screen.dart';
import '../features/followups/presentation/screens/followups_screen.dart';
import '../features/promo_lookup/presentation/screens/promo_lookup_screen.dart';
import '../features/chat_inbox/presentation/screens/chat_inbox_screen.dart';
import '../features/chat_inbox/presentation/screens/chat_metrics_screen.dart';
import '../features/chat_inbox/presentation/screens/chat_thread_screen.dart';
import '../features/reports/presentation/screens/warehouse_alignment_screen.dart';
import '../features/reports/presentation/screens/profit_and_loss_screen.dart';
import '../features/reports/presentation/screens/revenue_dashboard_screen.dart';
import '../features/woo_sync/presentation/screens/woo_duplicates_screen.dart';
import '../features/woo_sync/presentation/screens/woo_sync_screen.dart';
import '../features/expenses/presentation/expenses_screen.dart';
import '../features/monthly_expenses/presentation/monthly_expenses_screen.dart';
import '../features/settings/presentation/user_profile_screen.dart';
import '../features/shift/presentation/shift_start_screen.dart';
import '../features/shift/presentation/shift_end_screen.dart';
import '../features/trips/screens/trips_screen.dart';
import '../features/fleet/presentation/screens/fleet_map_screen.dart';
import '../features/courier_alerts/presentation/courier_alerts_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/reports/presentation/screens/shipping_analytics_screen.dart';
import '../features/reports/presentation/screens/inventory_intelligence_screen.dart';
import '../features/reports/presentation/screens/product_analytics_screen.dart';
import '../features/reports/presentation/screens/customer_analytics_screen.dart';
import '../features/reports/presentation/screens/b2b_sales_clients_screen.dart';
import '../features/reports/presentation/screens/stock_reports_screen.dart';
import '../features/reports/presentation/screens/daily_close_screen.dart';
import '../features/reports/presentation/screens/cash_over_short_screen.dart';
import '../features/reports/presentation/screens/fulfilment_sla_screen.dart';
import '../features/reports/presentation/screens/unit_economics_screen.dart';
import '../features/reports/presentation/screens/promo_performance_screen.dart';
import '../features/reports/presentation/screens/stock_adjustments_screen.dart';
import '../features/reports/presentation/screens/labour_cost_screen.dart';
import '../features/reports/presentation/screens/meta_ads_screen.dart';
import '../features/master_orders/presentation/master_orders_screen.dart';
import '../features/instapay_reconciliation/presentation/instapay_reconciliation_screen.dart';
import 'network/user_service.dart';
import '../features/about/presentation/screens/about_screen.dart';
import '../features/b2b/presentation/screens/b2b_active_accounts_screen.dart';
import '../features/b2b/presentation/screens/b2b_pipeline_screen.dart';
import '../features/labels/presentation/screens/labels_screen.dart';
import '../features/labels/presentation/screens/label_detail_screen.dart';
import '../features/labels/presentation/screens/label_setup_wizard.dart';
import '../features/b2b/presentation/screens/b2b_account_screen.dart';
import '../features/b2b/presentation/screens/b2b_today_screen.dart';
import '../features/journey/presentation/screens/action_calendar_screen.dart';
import '../features/visits/presentation/screens/visit_builder_screen.dart';
import '../features/visits/presentation/screens/visit_plan_screen.dart';
import '../features/visits/presentation/screens/visit_plans_screen.dart';
import '../features/pricing/presentation/screens/pricing_screen.dart';
import '../features/credit/presentation/screens/credit_accounts_screen.dart';
import '../features/credit/presentation/screens/credit_account_detail_screen.dart';
import '../features/leads/presentation/screens/leads_list_screen.dart';
import '../features/leads/presentation/screens/leads_map_screen.dart';
import '../features/leads/presentation/screens/lead_detail_screen.dart';
import '../features/leads/presentation/screens/lead_form_screen.dart';
import '../features/leads/data/models/lead.dart';

import '../features/shift/state/shift_notifier.dart';
import '../features/shift/models/shift_models.dart';
import '../features/pos/state/pos_notifier.dart';
import '../features/weekly_count/presentation/weekly_count_approvals_screen.dart';
import '../features/weekly_count/presentation/weekly_count_detail_screen.dart';
import '../features/weekly_count/presentation/weekly_count_screen.dart';
import 'widgets/global_orientation_enforcer.dart';
import 'widgets/manager_bottom_bar.dart';

// Global RouteObserver for navigation lifecycle (used by Kanban to refresh on return)
final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();

// Auth state provider that checks stored session on startup
final authStateProvider = FutureProvider<bool>((ref) async {
  final sessionManager = ref.watch(sessionManagerProvider);
  final authRepo = ref.watch(authRepositoryProvider);

  return resolveInitialAuthState(
    isWeb: kIsWeb,
    hasStoredSession: sessionManager.hasValidSession,
    validateSession: authRepo.validateSession,
  );
});

@visibleForTesting
Future<bool> resolveInitialAuthState({
  required bool isWeb,
  required Future<bool> Function() hasStoredSession,
  required Future<bool> Function() validateSession,
}) async {
  try {
    if (!isWeb) {
      final hasSession = await hasStoredSession();
      if (!hasSession) return false;
    }

    return await validateSession();
  } catch (_) {
    return false;
  }
}

// Current auth state for UI
final currentAuthStateProvider = StateProvider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (isAuthenticated) => isAuthenticated,
    orElse: () => false,
  );
});

// Global navigator key so logic outside widgets (e.g., websocket handlers) can show dialogs
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

// Expose as provider for consumers needing context
final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => rootNavigatorKey,
);

@visibleForTesting
String? resolveRouterRedirect({
  required bool isAuthenticated,
  required String location,
  required bool Function() readRequirePosShift,
  required AsyncValue<ShiftEntry?> Function() readActiveShift,
  required Map<String, dynamic>? Function() readSelectedProfile,
}) {
  final isOnLogin = location == AppRoutes.login;
  final isOnShiftStart = location == AppRoutes.shiftStart;
  final isOnShiftEnd = location == AppRoutes.shiftEnd;
  final isOnProfileSelection = location == AppRoutes.selectProfile;

  if (!isAuthenticated && !isOnLogin) return AppRoutes.login;
  // Send freshly-authenticated users to the root landing gate, which resolves
  // the correct home (Kanban for Jarz POS Staff, POS otherwise) once roles load.
  if (isAuthenticated && isOnLogin) return AppRoutes.root;

  if (!isAuthenticated) return null;

  // End Shift is the one screen where "no open shift" is the expected state.
  // The moment the close succeeds the active shift disappears, and the gate
  // below would bounce the user to Start Shift — off the closing summary and
  // the Logout button it carries — leaving them signed in on the till they
  // just closed. The screen cannot take money, so nothing is gated by letting
  // it stand.
  if (isOnShiftEnd) return null;

  final requirePosShift = readRequirePosShift();
  final activeShiftAsync = readActiveShift();
  final selectedProfile = readSelectedProfile();

  // Track whether a profile has been selected (used for subsequent checks).
  final hasSelectedProfile = selectedProfile != null;

  // If profile is selected, no need to keep user on profile selection screen.
  if (hasSelectedProfile && isOnProfileSelection) {
    return AppRoutes.pos;
  }

  // A shift belongs to one branch, so it cannot be verified until we know which
  // branch the user is on. Staff who land straight on the Kanban board never
  // pass through profile selection, which used to skip the shift gate entirely
  // while still letting them collect cash and dispatch orders.
  if (requirePosShift && !hasSelectedProfile) {
    if (!isOnProfileSelection && !isOnShiftStart) {
      return AppRoutes.selectProfile;
    }
    return null;
  }

  // Global shift gating: only after POS profile is selected.
  // Each POS profile is independent – shifts on other profiles are irrelevant.
  if (hasSelectedProfile && requirePosShift) {
    final activeShift = activeShiftAsync.valueOrNull;
    final selectedProfileName = (selectedProfile['name'] ?? '').toString();

    // The gate is keyed on a *known-good* shift rather than on "is the request
    // finished". The old code bailed out (`return null`) whenever the async
    // value was loading, which let a user straight onto POS while the
    // get_active_shift call was still in flight — and because nothing re-ran
    // the redirect once it landed, they stayed there with no shift open until
    // the next navigation happened to re-trigger the gate.
    //
    // `valueOrNull` deliberately survives a refresh: a user who already has a
    // matching open shift keeps working while the value is revalidated, so a
    // background refresh never yanks them off the screen they are on.
    final hasShiftForProfile =
        activeShift != null &&
        activeShift.posProfile == selectedProfileName &&
        activeShift.isCurrentUser;

    if (hasShiftForProfile) {
      // Same user + same profile → nothing to gate; leave Start Shift.
      if (isOnShiftStart) return AppRoutes.pos;
    } else {
      // No shift, a shift on another profile, a shift owned by someone else,
      // or a shift we do not know about yet → block on Start Shift, which
      // renders a spinner while the lookup is still in flight and then either
      // shows the opening form or the "already open by <user>" message.
      if (!isOnShiftStart) return AppRoutes.shiftStart;
    }
  }

  return null;
}

/// The home route for a user based on their roles:
///  - a user with the manager home switched on (and the reports it needs)
///    lands on the revenue dashboard,
///  - dedicated B2B sales reps (non-managers) land in B2B mode,
///  - Jarz POS Staff (non-managers) land on the dispatch Kanban,
///  - everyone else (incl. managers) lands on POS.
String homeRouteFor(UserRoles roles) {
  if (roles.usesManagerHome) return AppRoutes.reportsRevenueDashboard;
  if (roles.landsOnB2b) return AppRoutes.b2b;
  if (roles.landsOnKanban) return AppRoutes.kanban;
  return AppRoutes.pos;
}

/// Enforces B2B/B2C separation by role once roles are known:
///  - A dedicated B2B rep (non-manager) cannot reach the B2C POS/Kanban flows
///    and is redirected to B2B mode.
///  - A non-B2B user (e.g. a cashier) cannot reach `/b2b` and is sent home.
/// Managers can reach both (they own the mode switch), so no redirect applies.
/// Returns null when no redirect is needed.
@visibleForTesting
String? resolveB2bRedirect({
  required UserRoles roles,
  required String location,
  bool isB2bOrderMode = false,
}) {
  final isOnB2b = location.startsWith(AppRoutes.b2b);
  final isOnB2c =
      (location == AppRoutes.pos && !isB2bOrderMode) ||
      location == AppRoutes.kanban ||
      location == AppRoutes.selectProfile;

  // Dedicated B2B rep: locked out of the B2C flows.
  if (roles.landsOnB2b && isOnB2c) {
    return AppRoutes.b2b;
  }

  // Non-B2B user trying to open B2B mode → send to their home.
  if (isOnB2b && !roles.canUseB2b) {
    return homeRouteFor(roles);
  }

  return null;
}

/// Whether [roles] may open the `/reports...` [location], mirroring each
/// report's backend gate (and the hub's tile gates):
///  - the hub: [UserRoles.canAccessReportsHub];
///  - Materials and the daily-operations reports (daily close, cash
///    over/short, fulfilment SLA): the line-manager tier,
///    [UserRoles.canViewMaterialsReport];
///  - Warehouse alignment: [UserRoles.canAccessManagerDashboard];
///  - Meta Ads: [UserRoles.canViewMetaAds];
///  - every other report: [UserRoles.canViewAllReports].
///
/// Returns null when [location] is not a reports path.
@visibleForTesting
bool? canOpenReportsLocation({
  required UserRoles roles,
  required String location,
}) {
  final path = location.split('?').first;
  if (path == AppRoutes.reports || path == '${AppRoutes.reports}/') {
    return roles.canAccessReportsHub;
  }
  if (!path.startsWith('${AppRoutes.reports}/')) return null;
  bool under(String route) => path == route || path.startsWith('$route/');
  if (under(AppRoutes.reportsMaterials) ||
      under(AppRoutes.reportsDailyClose) ||
      under(AppRoutes.reportsCashOverShort) ||
      under(AppRoutes.reportsFulfilmentSla)) {
    return roles.canViewMaterialsReport;
  }
  if (under(AppRoutes.reportsWarehouseAlignment)) {
    return roles.canAccessManagerDashboard;
  }
  if (under(AppRoutes.reportsMetaAds)) {
    return roles.canViewMetaAds;
  }
  return roles.canViewAllReports;
}

/// Redirect for a reports location the user's roles do not allow: back to
/// the hub when they can open it (and are not already on it), otherwise to
/// their home. Null when allowed or not a reports path.
@visibleForTesting
String? resolveReportsRedirect({
  required UserRoles roles,
  required String location,
}) {
  final allowed = canOpenReportsLocation(roles: roles, location: location);
  if (allowed == null || allowed) return null;
  final path = location.split('?').first;
  final onHub = path == AppRoutes.reports || path == '${AppRoutes.reports}/';
  if (!onHub && roles.canAccessReportsHub) return AppRoutes.reports;
  return homeRouteFor(roles);
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(currentAuthStateProvider);
  final isAuthenticated = authState;

  // GoRouter only evaluates `redirect` on navigation and whenever this
  // listenable fires. Every provider the gate reads must therefore be wired to
  // it, otherwise the gate silently runs on stale data.
  final gateRefresh = ValueNotifier<int>(0);
  if (isAuthenticated) {
    // Re-run redirects when the user's roles finish loading (e.g. on cold start
    // with a saved session) so the landing gate can resolve the correct home.
    //
    // Gated on auth for the same reason as the shift lookup below: `ref.listen`
    // *initialises* the provider, and `routerProvider` is watched
    // unconditionally by `JarzPosApp.build`, so leaving this ungated fired
    // `get_current_user_roles` with no session while the user sat on /login →
    // 403. It also fired again straight after `LoginNotifier.logout()`
    // invalidates the provider, i.e. against a session that had just been
    // destroyed.
    ref.listen(userRolesFutureProvider, (_, _) => gateRefresh.value++);
    // The shift gate resolves asynchronously, and selecting a POS profile
    // invalidates it (a shift belongs to one profile). Without this the gate
    // never re-ran after the lookup landed, so the user sat on POS with no
    // shift open until an unrelated navigation re-triggered the redirect.
    // Gated on auth so an anonymous login screen never calls get_active_shift.
    ref.listen(activeShiftProvider, (_, _) => gateRefresh.value++);
  }
  ref.onDispose(gateRefresh.dispose);

  // Expose a RouteObserver so screens can respond to navigation lifecycle (e.g., refresh on return)
  // Keep a single observer instance; safe to reuse across router rebuilds
  // Note: exported below for screen imports
  // (Declared outside function in actual file scope)

  return GoRouter(
    // On startup: if authenticated, land on the root gate which resolves the
    // correct home (Kanban for Jarz POS Staff, POS otherwise) once roles load.
    initialLocation: isAuthenticated ? AppRoutes.root : AppRoutes.login,
    refreshListenable: gateRefresh,
    redirect: (context, state) {
      // NOTE: We do NOT redirect non-POS/shift screens when no profile is selected.
      // Kanban, Trips, Expenses, and Courier screens can operate across all accessible
      // profiles without requiring a single selection. Profile selection is only mandatory
      // for POS order creation and authenticated shift management.
      final baseRedirect = resolveRouterRedirect(
        isAuthenticated: isAuthenticated,
        location: state.matchedLocation,
        readRequirePosShift: () => ref.read(requirePosShiftProvider),
        readActiveShift: () => ref.read(activeShiftProvider),
        readSelectedProfile: () =>
            ref.read(posNotifierProvider.select((s) => s.selectedProfile)),
      );
      if (baseRedirect != null) return baseRedirect;

      // Enforce B2B/B2C separation once roles are known.
      if (isAuthenticated) {
        final rolesAsync = ref.read(userRolesFutureProvider);
        final roles = rolesAsync.valueOrNull;
        if (roles != null) {
          return resolveB2bRedirect(
                roles: roles,
                location: state.matchedLocation,
                isB2bOrderMode:
                    state.uri.queryParameters['mode'] == 'b2b_order',
              ) ??
              resolveReportsRedirect(
                roles: roles,
                location: state.matchedLocation,
              );
        }
      }
      return null;
    },
    // SentryNavigatorObserver records a breadcrumb per navigation, so events
    // show the screen the user was on when they crashed.
    observers: [
      routeObserver,
      SentryNavigatorObserver(),
      managerBarRouteObserver,
    ],
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.pos,
        name: 'pos',
        builder: (context, state) {
          final extra = state.extra;
          final launchData = extra is Map
              ? Map<String, dynamic>.from(extra)
              : <String, dynamic>{};
          if (state.uri.queryParameters['mode'] == 'b2b_order') {
            launchData['mode'] = 'b2b_order';
          }
          return PosScreen(launchData: launchData.isEmpty ? null : launchData);
        },
      ),
      GoRoute(
        path: AppRoutes.selectProfile,
        name: 'pos-select-profile',
        builder: (context, state) => const PosProfileSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.kanban,
        name: 'kanban',
        builder: (context, state) => KanbanBoardScreen(
          openReceipts: state.uri.queryParameters['receipts'] == '1',
        ),
      ),
      GoRoute(
        path: AppRoutes.printers,
        name: 'printers',
        builder: (context, state) => const PrinterSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.manager,
        name: 'manager',
        builder: (context, state) => const ManagerDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.shiftMonitor,
        name: 'shift-monitor',
        builder: (context, state) => const ShiftMonitorScreen(),
      ),
      GoRoute(
        path: AppRoutes.roster,
        name: 'roster',
        builder: (context, state) => const RosterScreen(),
      ),
      GoRoute(
        path: AppRoutes.attendance,
        name: 'attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.branchAccess,
        name: 'branch-access',
        builder: (context, state) => const BranchAccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.users,
        name: 'users',
        builder: (context, state) => const UserAdminListScreen(),
      ),
      // Declared before `/users/:id` so the static segment wins.
      GoRoute(
        path: AppRoutes.userNew,
        name: 'user-new',
        builder: (context, state) => const UserAdminFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.userCouriers,
        name: 'user-couriers',
        builder: (context, state) => const CourierSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.userDetail,
        name: 'user-detail',
        builder: (context, state) => UserAdminFormScreen(
          userName: Uri.decodeComponent(state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.purchase,
        name: 'purchase',
        builder: (context, state) => const PurchaseScreen(),
      ),
      GoRoute(
        path: AppRoutes.itemRequests,
        name: 'item-requests',
        builder: (context, state) => const PurchaseRequestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.manufacturing,
        name: 'manufacturing',
        // Landscape opt-in: the Plan tab is a wide table of figures, and the
        // app is portrait-locked on phones by default.
        builder: (context, state) => PhoneLandscapeScope(
          child: ManufacturingScreen(
            initialTab:
                int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.productionToday,
        name: 'production-today',
        // Today was retired on 2026-11-08 (owner: "we don't use it"). Kept as
        // a redirect so an old link or a cached drawer lands on the board.
        redirect: (context, state) => AppRoutes.manufacturing,
      ),
      GoRoute(
        path: AppRoutes.productionSop,
        name: 'production-sop',
        // Deliberately NOT wrapped in PhoneLandscapeScope: an SOP step is long
        // instruction prose, and portrait fits more of it on screen.
        builder: (context, state) =>
            SopExecuteScreen(args: SopLaunchArgs.fromExtra(state.extra)),
      ),
      GoRoute(
        path: AppRoutes.stockTransfer,
        name: 'stock-transfer',
        builder: (context, state) => StockTransferScreen(
          initialTab: state.uri.queryParameters['tab'],
        ),
      ),
      // Ungated here like every other manager screen: the drawer decides who
      // is offered the entry (`canAccessStockTransferProvider`, the same gate
      // Stock Transfer uses), the screen re-checks it, and `submit_transfer`
      // refuses anyone who arrives by URL anyway.
      GoRoute(
        path: AppRoutes.replenishment,
        name: 'replenishment',
        builder: (context, state) => const ReplenishmentScreen(),
      ),
      // Ungated here for the same reason: the drawer offers it on the
      // production view gate, the screen re-checks it, and the read endpoint
      // refuses anyone else.
      GoRoute(
        path: AppRoutes.productionRound,
        name: 'production-round',
        builder: (context, state) => const ProductionRoundScreen(),
      ),
      GoRoute(
        path: AppRoutes.cashTransfer,
        name: 'cash-transfer',
        builder: (context, state) => const CashTransferScreen(),
      ),
      // Open to anyone signed in: the screen itself asks the server whether
      // the caller manages custodies or holds one, and says so if neither.
      GoRoute(
        path: AppRoutes.cashCustody,
        name: 'cash-custody',
        builder: (context, state) => const CashCustodyScreen(),
      ),
      // ── Task Board ────────────────────────────────────────────────────
      // Open to anyone signed in: the board asks `get_board_context` and
      // renders a refusal for a non-board user. `/tasks/overview` is declared
      // before `/tasks/:id` so the static segment wins the match.
      GoRoute(
        path: AppRoutes.tasks,
        name: 'tasks',
        builder: (context, state) =>
            TasksBoardScreen(initialView: state.uri.queryParameters['view']),
      ),
      GoRoute(
        path: AppRoutes.tasksOverview,
        name: 'tasks-overview',
        builder: (context, state) => const TaskOverviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.taskDetail,
        name: 'task-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return TaskDetailScreen(taskName: Uri.decodeComponent(id));
        },
      ),
      GoRoute(
        path: AppRoutes.partnerSettlements,
        name: 'partner-settlements',
        builder: (context, state) => const PartnerSettlementsScreen(),
      ),
      // The duplicates screen is a drill-down from the console's app bar, but
      // it keeps its own route so a deep link can reach it directly.
      GoRoute(
        path: AppRoutes.wooSync,
        name: 'woo-sync',
        builder: (context, state) => const WooSyncScreen(),
      ),
      GoRoute(
        path: AppRoutes.wooDuplicates,
        name: 'woo-duplicates',
        builder: (context, state) => const WooDuplicatesScreen(),
      ),
      // Pushed from the shipping-address dialog with the Address name as
      // `extra`, never navigated to cold — there is nothing to show without
      // an address to correct.
      GoRoute(
        path: AppRoutes.addressPin,
        name: 'address-pin',
        builder: (context, state) =>
            AddressPinScreen(address: (state.extra ?? '').toString()),
      ),
      GoRoute(
        path: AppRoutes.inventoryCount,
        name: 'inventory-count',
        builder: (context, state) => const InventoryCountScreen(),
      ),
      GoRoute(
        path: AppRoutes.weeklyCount,
        name: 'weekly-count',
        builder: (context, state) => const WeeklyCountScreen(),
      ),
      // Static segment before `:name`, or "approvals" would open as a count.
      GoRoute(
        path: AppRoutes.weeklyCountApprovals,
        name: 'weekly-count-approvals',
        builder: (context, state) => const WeeklyCountApprovalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.weeklyCountDetail,
        name: 'weekly-count-detail',
        builder: (context, state) {
          final name = state.pathParameters['name'] ?? '';
          return WeeklyCountDetailScreen(countName: Uri.decodeComponent(name));
        },
      ),
      GoRoute(
        path: AppRoutes.expenses,
        name: 'expenses',
        builder: (context, state) => ExpensesScreen(
          initialTab: state.uri.queryParameters['tab'],
          initialMonth: state.uri.queryParameters['month'],
        ),
      ),
      // Ungated in the router, like every other manager screen here: the
      // drawer decides who is offered the entry (see
      // `canAccessMonthlyExpensesProvider`, which mirrors the backend gate),
      // and the API refuses anyone who arrives by URL anyway.
      GoRoute(
        path: AppRoutes.monthlyExpenses,
        name: 'monthly-expenses',
        builder: (context, state) => const MonthlyExpensesScreen(),
      ),
      GoRoute(
        path: AppRoutes.trips,
        name: 'trips',
        builder: (context, state) => const TripsScreen(),
      ),
      GoRoute(
        path: AppRoutes.courierAlerts,
        name: 'courier-alerts',
        builder: (context, state) => const CourierAlertsScreen(),
      ),
      GoRoute(
        path: AppRoutes.fleetMap,
        name: 'fleet-map',
        builder: (context, state) => const FleetMapScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        name: 'reports',
        builder: (context, state) =>
            const PhoneLandscapeScope(child: ReportsScreen()),
      ),
      GoRoute(
        path: AppRoutes.reportsShipping,
        name: 'reports-shipping',
        builder: (context, state) =>
            const PhoneLandscapeScope(child: ShippingAnalyticsScreen()),
      ),
      GoRoute(
        path: AppRoutes.reportsInventory,
        name: 'reports-inventory',
        builder: (context, state) =>
            const PhoneLandscapeScope(child: InventoryIntelligenceScreen()),
      ),
      // Merged reports: Velocity lives in Inventory & restock, Segments in
      // Customers & segments, and the Executive overview in the P&L
      // "Business overview". The old paths stay so saved links still land.
      GoRoute(
        path: AppRoutes.reportsVelocity,
        name: 'reports-velocity',
        redirect: (context, state) => AppRoutes.reportsInventory,
      ),
      GoRoute(
        path: AppRoutes.reportsSegments,
        name: 'reports-segments',
        redirect: (context, state) => AppRoutes.reportsCustomer,
      ),
      GoRoute(
        path: AppRoutes.followups,
        name: 'followups',
        builder: (context, state) => const FollowupsScreen(),
        // Nested so Back from the results lands on the worklist, also when the
        // drawer `go`es straight to it.
        routes: [
          GoRoute(
            path: 'results',
            name: 'followup-results',
            builder: (context, state) => const FollowupResultsScreen(),
          ),
        ],
      ),
      // Promo code lookup: every logged-in user, no role gate.
      GoRoute(
        path: AppRoutes.promoLookup,
        name: 'promo-lookup',
        builder: (context, state) => const PromoLookupScreen(),
      ),
      // Chat inbox. The thread and metrics are nested so a push that opens a
      // thread directly (`go('/chats/CHAT-00001')`) still has the inbox under
      // it for Back. `metrics` is declared before `:name` so it wins.
      GoRoute(
        path: AppRoutes.chats,
        name: 'chats',
        builder: (context, state) => const ChatInboxScreen(),
        routes: [
          GoRoute(
            path: 'metrics',
            name: 'chats-metrics',
            builder: (context, state) => const ChatMetricsScreen(),
          ),
          GoRoute(
            path: ':name',
            name: 'chat-thread',
            builder: (context, state) => ChatThreadScreen(
              conversation: state.pathParameters['name'] ?? '',
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.reportsWarehouseAlignment,
        name: 'reports-warehouse-alignment',
        builder: (context, state) =>
            const PhoneLandscapeScope(child: WarehouseAlignmentScreen()),
      ),
      GoRoute(
        path: AppRoutes.reportsProduct,
        name: 'reports-product',
        builder: (context, state) =>
            const PhoneLandscapeScope(child: ProductAnalyticsScreen()),
      ),
      GoRoute(
        path: AppRoutes.reportsCustomer,
        name: 'reports-customer',
        builder: (context, state) =>
            const PhoneLandscapeScope(child: CustomerAnalyticsScreen()),
      ),
      GoRoute(
        path: AppRoutes.reportsExecutive,
        name: 'reports-executive',
        redirect: (context, state) => AppRoutes.reportsProfitLoss,
      ),
      GoRoute(
        path: AppRoutes.reportsB2b,
        name: 'reports-b2b',
        builder: (context, state) =>
            const PhoneLandscapeScope(child: B2bSalesClientsScreen()),
      ),
      GoRoute(
        path: AppRoutes.reportsProfitLoss,
        name: 'reports-profit-loss',
        builder: (context, state) =>
            const PhoneLandscapeScope(child: ProfitAndLossScreen()),
      ),
      // Manager-only through the report gate's `canViewAllReports` fallback.
      GoRoute(
        path: AppRoutes.reportsRevenueDashboard,
        name: 'reports-revenue',
        builder: (context, state) =>
            const PhoneLandscapeScope(child: RevenueDashboardScreen()),
      ),
      GoRoute(
        path: AppRoutes.reportsUnitEconomics,
        name: 'reports-unit-economics',
        builder: (context, state) =>
            const PhoneLandscapeScope(child: UnitEconomicsScreen()),
      ),
      GoRoute(
        path: AppRoutes.reportsDailyClose,
        name: 'reports-daily-close',
        builder: (context, state) =>
            const PhoneLandscapeScope(child: DailyCloseScreen()),
      ),
      GoRoute(
        path: AppRoutes.reportsCashOverShort,
        name: 'reports-cash-over-short',
        builder: (context, state) =>
            const PhoneLandscapeScope(child: CashOverShortScreen()),
      ),
      GoRoute(
        path: AppRoutes.reportsFulfilmentSla,
        name: 'reports-fulfilment-sla',
        builder: (context, state) =>
            const PhoneLandscapeScope(child: FulfilmentSlaScreen()),
      ),
      GoRoute(
        path: AppRoutes.reportsPromo,
        name: 'reports-promo-codes',
        builder: (context, state) =>
            const PhoneLandscapeScope(child: PromoPerformanceScreen()),
      ),
      GoRoute(
        path: AppRoutes.reportsStockAdjustments,
        name: 'reports-stock-adjustments',
        builder: (context, state) =>
            const PhoneLandscapeScope(child: StockAdjustmentsScreen()),
      ),
      GoRoute(
        path: AppRoutes.reportsLabourCost,
        name: 'reports-labour-cost',
        builder: (context, state) =>
            const PhoneLandscapeScope(child: LabourCostScreen()),
      ),
      // Gated on `canViewMetaAds` in `canOpenReportsLocation`.
      GoRoute(
        path: AppRoutes.reportsMetaAds,
        name: 'reports-meta-ads',
        builder: (context, state) =>
            const PhoneLandscapeScope(child: MetaAdsScreen()),
      ),
      // The two stock reports as single-report routes: no tab bar, so a
      // materials-only user cannot swipe into Final Products.
      GoRoute(
        path: AppRoutes.reportsFinalProducts,
        name: 'reports-final-products',
        builder: (context, state) => const PhoneLandscapeScope(
          child: StockReportsScreen(initialTab: 0, singleReport: true),
        ),
      ),
      GoRoute(
        path: AppRoutes.reportsMaterials,
        name: 'reports-materials',
        builder: (context, state) => const PhoneLandscapeScope(
          child: StockReportsScreen(initialTab: 1, singleReport: true),
        ),
      ),
      GoRoute(
        path: AppRoutes.masterOrders,
        name: 'master-orders',
        builder: (context, state) => const MasterOrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.instapayReconciliation,
        name: 'instapay-reconciliation',
        builder: (context, state) => const InstapayReconciliationScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const UserProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.b2b,
        name: 'b2b',
        builder: (context, state) => const B2bActiveAccountsScreen(),
      ),
      GoRoute(
        path: AppRoutes.b2bPipeline,
        name: 'b2b-pipeline',
        builder: (context, state) => const B2bPipelineScreen(),
      ),
      GoRoute(
        path: AppRoutes.b2bToday,
        name: 'b2b-today',
        builder: (context, state) => const B2bTodayScreen(),
      ),
      // Every `/b2b/*` path here is a static segment, so declaration order
      // does not decide the match the way it does in the leads block below —
      // keep it that way if a `/b2b/:id` ever lands.
      GoRoute(
        path: AppRoutes.b2bCalendar,
        name: 'b2b-calendar',
        builder: (context, state) => const ActionCalendarScreen(),
      ),
      // Visit planner. `/b2b/visits/build` is declared BEFORE
      // `/b2b/visits/:name` so the literal segment wins the match — a route
      // named "build" would otherwise open a plan that does not exist.
      GoRoute(
        path: AppRoutes.b2bVisits,
        name: 'b2b-visits',
        builder: (context, state) => const VisitPlansScreen(),
      ),
      GoRoute(
        path: AppRoutes.b2bVisitBuilder,
        name: 'b2b-visit-builder',
        builder: (context, state) => const VisitBuilderScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.b2bVisitPlan}/:name',
        name: 'b2b-visit-plan',
        builder: (context, state) => VisitPlanScreen(
          planName: Uri.decodeComponent(state.pathParameters['name'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.b2bAccount,
        name: 'b2b-account',
        builder: (context, state) {
          final extra = state.extra;
          final data = extra is Map
              ? Map<String, dynamic>.from(extra)
              : const <String, dynamic>{};
          return B2bAccountScreen(
            doctype: (data['doctype'] ?? 'Lead').toString(),
            name: (data['name'] ?? '').toString(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.pricing,
        name: 'pricing',
        builder: (context, state) => const PricingScreen(),
      ),
      // ── Credit accounts ───────────────────────────────────────────────
      // `/credit-accounts/detail` is a static segment and must stay declared
      // beside the list route for the same reason the leads block documents:
      // a future `/credit-accounts/:id` would otherwise swallow it.
      //
      // Ungated in the router, like every other manager screen here: the
      // drawer entry carries the role gate and the API refuses anyone else.
      GoRoute(
        path: AppRoutes.creditAccounts,
        name: 'credit-accounts',
        builder: (context, state) => CreditAccountsScreen(
          initialView: CreditAccountsScreen.viewFromQuery(
            state.uri.queryParameters['view'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.creditAccountDetail,
        name: 'credit-account-detail',
        builder: (context, state) {
          final extra = state.extra;
          final data = extra is Map
              ? Map<String, dynamic>.from(extra)
              : const <String, dynamic>{};
          // `extra` from an in-app tap; `?customer=` from a push tap or a
          // deep link, which cannot carry an object.
          final customer = (data['customer'] ??
                  state.uri.queryParameters['customer'] ??
                  '')
              .toString();
          return CreditAccountDetailScreen(
            customer: customer,
            customerName: (data['customer_name'] ?? '').toString(),
          );
        },
      ),
      // The settlement reminder's `route`: `/credit-accounts/<customer>`.
      // Declared AFTER `/credit-accounts/detail` so the static segment wins.
      GoRoute(
        path: '${AppRoutes.creditAccounts}/:customer',
        name: 'credit-account-by-id',
        builder: (context, state) => CreditAccountDetailScreen(
          customer: state.pathParameters['customer'] ?? '',
        ),
      ),
      // ── B2B customer labels ───────────────────────────────────────────
      // `/labels/detail` is declared before nothing else, but it must stay
      // ahead of any future `/labels/:id` for the same reason the leads block
      // documents: static segments have to win the match.
      GoRoute(
        path: AppRoutes.labels,
        name: 'labels',
        builder: (context, state) => const LabelsScreen(),
      ),
      GoRoute(
        path: AppRoutes.labelDetail,
        name: 'label-detail',
        builder: (context, state) =>
            LabelDetailScreen(labelName: (state.extra ?? '').toString()),
      ),
      GoRoute(
        path: AppRoutes.labelSetup,
        name: 'label-setup',
        builder: (context, state) {
          // Extra is either a bare customer id (String) or a map carrying the
          // display name too; both preselect the customer in the wizard.
          final extra = state.extra;
          String? customer;
          String? customerName;
          if (extra is String && extra.trim().isNotEmpty) {
            customer = extra.trim();
          } else if (extra is Map) {
            customer = extra['customer']?.toString();
            customerName = extra['customer_name']?.toString();
          }
          return LabelSetupWizardScreen(
            initialCustomer: customer,
            initialCustomerName: customerName,
          );
        },
      ),
      // ── Leads (B2B prospect research) ─────────────────────────────────
      // Note: the literal `/leads/map` and `/leads/new` routes must be
      // declared before `/leads/:id` so the static segments win the match.
      GoRoute(
        path: AppRoutes.leads,
        name: 'leads',
        builder: (context, state) => const LeadsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.leadsMap,
        name: 'leads-map',
        builder: (context, state) => const LeadsMapScreen(),
      ),
      GoRoute(
        path: AppRoutes.leadForm,
        name: 'lead-form',
        builder: (context, state) => LeadFormScreen(
          existing: state.extra is Lead ? state.extra! as Lead : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.leadDetail,
        name: 'lead-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return LeadDetailScreen(leadName: Uri.decodeComponent(id));
        },
      ),
      GoRoute(
        path: AppRoutes.shiftStart,
        name: 'shift-start',
        builder: (context, state) => const ShiftStartScreen(),
      ),
      GoRoute(
        path: AppRoutes.shiftEnd,
        name: 'shift-end',
        builder: (context, state) => const ShiftEndScreen(),
      ),
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const _LandingGateScreen(),
        redirect: (context, state) {
          if (!ref.read(currentAuthStateProvider)) return AppRoutes.login;
          final rolesAsync = ref.read(userRolesFutureProvider);
          // Stay on the gate (spinner) until roles are known.
          if (!rolesAsync.hasValue) return null;
          return homeRouteFor(rolesAsync.requireValue);
        },
      ),
    ],
    navigatorKey: rootNavigatorKey,
  );
});

/// Minimal splash shown while the landing gate resolves the user's home route.
class _LandingGateScreen extends StatelessWidget {
  const _LandingGateScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
