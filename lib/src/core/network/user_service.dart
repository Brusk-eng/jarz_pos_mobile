import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_provider.dart';
import '../constants/api_endpoints.dart';
import '../constants/business_constants.dart';

class UserRoles {
  final String user;
  final String? fullName;
  final List<String> roles;
  final String? employee;
  final String? employeeName;
  final String? branch;
  final bool requirePosShift;
  final bool isB2bSalesRep;
  final bool canAccessB2b;

  /// `User.custom_manager_home`: open on the revenue dashboard and show the
  /// manager bottom bar. A per-user switch, off for everyone by default.
  final bool managerHome;

  const UserRoles({
    required this.user,
    this.fullName,
    required this.roles,
    this.employee,
    this.employeeName,
    this.branch,
    this.requirePosShift = false,
    this.isB2bSalesRep = false,
    this.canAccessB2b = false,
    this.managerHome = false,
  });

  bool get isJarzManager => roles.contains(RoleNames.jarzManager);
  bool get isManager => isJarzManager;

  /// Both spellings of the line-manager Role exist as real records on staging
  /// and production, and the backend's `ROLES.LINE_MANAGER_TIER` carries both.
  /// Matching only the capitalised one left a line manager holding the other
  /// spelling looking like a plain POS user to every gate below.
  bool get isLineManager =>
      roles.contains(RoleNames.jarzLineManager) ||
      roles.contains(RoleNames.jarzLineManagerAlt);
  bool get isAdminManager =>
      roles.contains(RoleNames.posManager) ||
      roles.contains(RoleNames.systemManager) ||
      roles.contains(RoleNames.administrator);

  /// Everything a JARZ line manager may do, the manager tier and the
  /// Administrator may do too — the line manager is a *narrower* manager, never
  /// the holder of an authority its own manager lacks. Mirrors the backend
  /// `ROLES.LINE_MANAGER_TIER`.
  ///
  /// Gate line-manager actions on this, NOT on [isLineManager]: cancel and
  /// return were gated on the bare role for months, so a JARZ Manager could not
  /// cancel or return an order on their own branch.
  bool get canActAsLineManager =>
      isLineManager || isJarzManager || isAdminManager;
  bool get canAccessManagerDashboard =>
      isJarzManager || isLineManager || isAdminManager;
  bool get isJarzPosStaff => roles.contains(RoleNames.jarzPosStaff);

  /// Lands on the Kanban board (instead of POS) only when the user is
  /// Jarz POS Staff AND not a manager — managers keep the POS home.
  bool get landsOnKanban => isJarzPosStaff && !canAccessManagerDashboard;
  bool get canAccessShiftMonitor =>
      isJarzManager || isAdminManager || isLineManager;
  bool get isModerator => roles.contains(RoleNames.moderator);
  /// The admin tier is included deliberately: ACCESS_MATRIX has always listed
  /// mute as a High Management capability, but the check omitted it, so a
  /// System-Manager-only account could not mute while a Moderator could.
  bool get canMuteNotifications =>
      isJarzManager || isLineManager || isModerator || isAdminManager;

  /// Whether this user is a dedicated B2B sales rep (lands in B2B mode and is
  /// blocked from the B2C POS/Kanban flows). Falls back to the role name when
  /// the backend flag is absent.
  bool get isB2bRep =>
      isB2bSalesRep || roles.contains(RoleNames.b2bSalesRep);

  /// Whether this user can use B2B mode at all (sales reps + managers).
  bool get canUseB2b => canAccessB2b || isB2bRep;

  /// Whether this user may EDIT prices (create lists, set category/flavor
  /// prices, assign customers to lists). The backend
  /// `_ensure_full_manager_pricing_access` requires manager-pricing access AND
  /// B2B access, which nets out to the JARZ Manager (Administrator holds that
  /// role implicitly). Line managers lack B2B and B2B reps lack pricing, so both
  /// get the read-only pricing view.
  bool get canEditPricing => isJarzManager;

  /// A B2B rep who is NOT a manager lands in B2B mode and cannot reach the
  /// B2C POS/Kanban flows. Managers keep their normal landing but get a switch.
  bool get landsOnB2b => isB2bRep && !canAccessManagerDashboard;

  // ── Gates that mirror one backend role set each ──────────────────────
  //
  // Each of these mirrors the set its OWN API accepts, never the general
  // manager-dashboard gate. `canAccessManagerDashboard` is satisfied by any
  // line manager (the dashboard's own backend check accepts the line-manager
  // tier), but the APIs behind Cash Transfer, Stock Transfer, Inventory Count,
  // the Purchase Invoice and the analytics reports do not — so gating a drawer
  // entry on it shows a line manager a tile that answers "Not permitted" on
  // every call. Same class of bug as the old Manufacturing screen; see
  // [canAccessProductionBoard].
  //
  // `Administrator` is carried in every set because `frappe.get_roles` hands
  // that user every role, so the server always lets it through.

  /// Mirrors backend `ROLES.MANAGER` — Cash Transfer (`api/cash_transfer.py`)
  /// and Stock Transfer (`api/transfer.py`).
  bool get _isBackendManagerSet =>
      isJarzManager ||
      roles.contains(RoleNames.systemManager) ||
      roles.contains(RoleNames.administrator) ||
      roles.contains(RoleNames.accountsManager) ||
      roles.contains(RoleNames.stockManager) ||
      roles.contains(RoleNames.manufacturingManager) ||
      roles.contains(RoleNames.purchaseManager);

  /// Whether this user may move cash between accounts.
  /// Mirrors `ROLES.MANAGER`, enforced by `cash_transfer._ensure_manager_access`.
  bool get canAccessCashTransfer => _isBackendManagerSet;

  /// Whether this user may settle a delivery partner or a sales partner.
  ///
  /// Mirrors `ROLES.MANAGER`, enforced by
  /// `delivery_partners._ensure_delivery_partner_access` and
  /// `sales_partners._ensure_sales_partner_settlement_access`. Deliberately
  /// the same tier as [canAccessCashTransfer] and NOT the manager-dashboard
  /// gate: both of these post money out of the company, and neither a
  /// delivery partner nor a sales partner has a branch dimension to devolve
  /// to a floor supervisor. Gating this on the dashboard tier would show a
  /// line manager a tile that 403s on every call.
  bool get canAccessPartnerSettlements => _isBackendManagerSet;

  /// Whether this user may open the WooCommerce sync console.
  ///
  /// Mirrors the OTHER app's `ROLES.OPERATOR`
  /// (`jarz_woocommerce_integration/services/access.ensure_operator_access`),
  /// which is `{System Manager, WooCommerce Sync Operator, JARZ Manager}` with
  /// Administrator short-circuited server-side. JARZ Manager is in that set by
  /// the owner's decision — Frappe roles do not inherit, so naming it there is
  /// the only durable way to say "managers operate Woo sync".
  ///
  /// Keep these two lists identical. Widening either side alone is how a tile
  /// appears in the drawer and then 403s on every call behind it.
  bool get canAccessWooSync =>
      roles.contains(RoleNames.wooSyncOperator) ||
      roles.contains(RoleNames.jarzManager) ||
      roles.contains(RoleNames.systemManager) ||
      roles.contains(RoleNames.administrator);

  /// Whether this user may move stock between warehouses.
  /// Mirrors `ROLES.STOCK_TRANSFER` (= `ROLES.MANAGER` | `LINE_MANAGER_TIER`),
  /// enforced by `transfer._ensure_transfer_access`.
  ///
  /// Deliberately WIDER than [canAccessCashTransfer]: moving jars between a
  /// branch and Finished Goods is floor-supervisor work, so the line-manager
  /// tier is in. Cash Transfer and the Purchase Invoice commit money and stay
  /// on the narrower manager set — do not collapse the three back into one gate.
  ///
  /// NOT gated on [canActAsLineManager]: that helper folds in the POS Manager
  /// (via [isAdminManager]), which `ROLES.STOCK_TRANSFER` does not contain — so
  /// it would put the tile back in front of the one role the server refuses.
  /// The two line-manager spellings are the only additions to the manager set.
  bool get canAccessStockTransfer => _isBackendManagerSet || isLineManager;

  /// Whether this user may take part in a stock handover by ROLE alone: the
  /// transfer managers above, or the production team acting for the factory
  /// (`ROLES.PRODUCTION_EXECUTE`). A branch cashier qualifies too, but only
  /// through an open shift, which is not a role — the Stock Transfer tile adds
  /// that half itself (`canOpenStockTransferProvider`).
  bool get canAccessStockHandover =>
      canAccessStockTransfer || canExecuteProduction;

  /// Whether this user may run an inventory count.
  /// Mirrors `ROLES.STOCK`, enforced by
  /// `inventory_count._ensure_manager_access` — the same set as
  /// [canAccessCashTransfer] minus Purchase Manager.
  bool get canAccessInventoryCount =>
      isJarzManager ||
      roles.contains(RoleNames.systemManager) ||
      roles.contains(RoleNames.administrator) ||
      roles.contains(RoleNames.accountsManager) ||
      roles.contains(RoleNames.stockManager) ||
      roles.contains(RoleNames.manufacturingManager);

  /// Whether this user may raise a Purchase Invoice (buying against a request,
  /// which commits money — distinct from *asking* for stock, which
  /// `ROLES.PURCHASE_REQUEST` opens to everyone).
  /// Mirrors `ROLES.PURCHASE`, enforced by `purchase._ensure_manager_access`.
  bool get canAccessPurchaseInvoice => _isBackendManagerSet;

  /// Whether this user may open the analytics dashboards behind the Reports hub
  /// (shipping, inventory, product, customer, executive, B2B) and the Final
  /// Products stock report. Mirrors `_ensure_jarz_manager`, which every one of
  /// those endpoints calls: the JARZ Manager and the Administrator, nobody
  /// else. Note that System Manager and POS Manager are NOT in it.
  bool get canViewAllReports =>
      isJarzManager || roles.contains(RoleNames.administrator);

  /// Whether the manager home applies: the per-user switch AND the reports it
  /// lands on. The switch alone must never route a user to a screen whose
  /// guard would bounce them back home, which would loop.
  bool get usesManagerHome => managerHome && canViewAllReports;

  /// Whether this user may open the Materials & Consumables report — the one
  /// report a line manager can actually read. Mirrors
  /// `reports._ensure_materials_report_access`, i.e. `ROLES.LINE_MANAGER_TIER`.
  bool get canViewMaterialsReport =>
      isLineManager ||
      isJarzManager ||
      roles.contains(RoleNames.administrator) ||
      roles.contains(RoleNames.systemManager);

  /// Whether the side menu offers the Task Board. Mirrors the backend's
  /// board-user gate, `ROLES.LINE_MANAGER_TIER`: both line-manager spellings,
  /// JARZ Manager, System Manager and Administrator — and deliberately NOT the
  /// POS Manager that [canActAsLineManager] folds in. (A user granted access
  /// only through Jarz Task Settings can still open `/tasks` by link; the
  /// screen trusts `get_board_context.can_access`, not this getter.)
  bool get canAccessTaskBoard =>
      isLineManager ||
      isJarzManager ||
      roles.contains(RoleNames.systemManager) ||
      roles.contains(RoleNames.administrator);

  /// Whether the Reports hub has anything at all to show this user.
  ///
  /// The hub is kept rather than hidden for the line-manager tier because it
  /// still holds one readable report for them; the screen itself drops every
  /// tile whose API would refuse them, so the hub is never an empty page and
  /// never a dead link. A POS Manager, who is in neither set, loses the entry
  /// entirely — every tile on it would have 403'd.
  bool get canAccessReportsHub =>
      canViewAllReports || canViewMaterialsReport || canViewMetaAds;

  /// Whether this user may open the Meta Ads report. Mirrors the role set of
  /// `meta_ads.get_ads_report`: JARZ Manager, Administrator, System Manager
  /// and the media buyer's Meta CAPI Manager. Wider than [canViewAllReports]
  /// on purpose — the media buyer holds only the last role, so for them the
  /// hub shows this one tile.
  bool get canViewMetaAds =>
      isJarzManager ||
      roles.contains(RoleNames.administrator) ||
      roles.contains(RoleNames.systemManager) ||
      roles.contains(RoleNames.metaCapiManager);

  /// Holds one of the stock/manufacturing roles the backend accepts.
  bool get isProductionRole =>
      roles.contains(RoleNames.manufacturingManager) ||
      roles.contains(RoleNames.stockManager) ||
      roles.contains(RoleNames.purchaseManager);

  bool get isProductionOperator =>
      roles.contains(RoleNames.productionOperator);

  /// May start and finish batches. Mirrors backend `ROLES.PRODUCTION_EXECUTE`.
  bool get canExecuteProduction =>
      isProductionOperator || canAccessProductionBoard;

  /// May post production on a past date. Mirrors `ROLES.PRODUCTION_BACKDATE` —
  /// deliberately EXCLUDES the operator role. The server enforces this against
  /// its own clock; this only decides whether the date picker is tappable, so a
  /// client that got it wrong would still be refused.
  bool get canBackDateProduction =>
      isJarzManager ||
      roles.contains(RoleNames.systemManager) ||
      roles.contains(RoleNames.administrator) ||
      isProductionRole;

  /// May return stranded WIP material to its source warehouse.
  ///
  /// Deliberately NOT [canAccessProductionBoard]: that mirrors the backend's
  /// PRODUCTION_VIEW set, which *includes* Production Operator — gating on it
  /// would show the action to exactly the role it must be hidden from. Manager
  /// tier only, matching what the backend requires for `return_wip_to_store`.
  bool get canManageProductionWip => canBackDateProduction;

  /// Whether this user may open the Production Board.
  ///
  /// Mirrors the backend `ROLES.PRODUCTION_VIEW` set exactly — deliberately
  /// NOT `canAccessManagerDashboard`, which admits POS Manager and line
  /// managers that the production API rejects. Gating on a wider set than the
  /// server accepts is how the old Manufacturing screen ended up showing a
  /// tile that failed on every call.
  bool get canAccessProductionBoard =>
      isJarzManager ||
      roles.contains(RoleNames.systemManager) ||
      roles.contains(RoleNames.administrator) ||
      isProductionRole ||
      roles.contains(RoleNames.productionOperator);

  /// Whether this user may REQUEST a cash advance for an employee.
  ///
  /// Mirrors the backend LINE_MANAGER_TIER that
  /// `employee_advances.create_employee_advance_request` accepts, which is
  /// exactly what [canActAsLineManager] already encodes — including BOTH
  /// spellings of the line-manager Role record, so a line manager holding the
  /// lowercase one is not silently dropped.
  ///
  /// Deliberately its own getter rather than call sites reusing
  /// [canActAsLineManager]: if the backend ever narrows or widens this one
  /// endpoint, this is the single line that moves.
  bool get canRequestEmployeeAdvance => canActAsLineManager;

  /// Whether this user may APPROVE or REJECT a cash advance.
  ///
  /// Narrower than [canRequestEmployeeAdvance] on purpose — approval submits
  /// the HRMS Employee Advance AND posts the Payment Entry, so cash actually
  /// leaves the branch account. Mirrors the JARZ Manager + admin tier that
  /// `approve_employee_advance` / `reject_employee_advance` accept: a line
  /// manager asks, it does not sign off on its own request.
  bool get canApproveEmployeeAdvance => isJarzManager || isAdminManager;

  /// Whether this user may open Monthly Expenses — the recurring-expense
  /// registry and payroll for one month, with the Pay actions on it.
  ///
  /// Mirrors `monthly_expenses._ensure_manager` EXACTLY, which is itself a
  /// mirror of `recurring_expenses._ensure_manager`: JARZ Manager,
  /// Administrator, System Manager, Accounts Manager — and nobody else.
  ///
  /// Written out here rather than reusing [_isBackendManagerSet] or
  /// [canAccessManagerDashboard], both of which are WIDER: the former adds
  /// Stock / Manufacturing / Purchase Manager, the latter adds the line-manager
  /// tier and POS Manager. Every one of those would see the drawer tile and get
  /// "Not permitted" from the first call — the recurring bug this app keeps
  /// hitting (Manufacturing, Cash Transfer, the Reports hub). If the backend
  /// gate ever moves, this getter is the single line that moves with it.
  bool get canAccessMonthlyExpenses =>
      isJarzManager ||
      roles.contains(RoleNames.administrator) ||
      roles.contains(RoleNames.systemManager) ||
      roles.contains(RoleNames.accountsManager);

  /// Backend `ROLES.LINE_MANAGER_TIER` exactly: both line-manager spellings,
  /// JARZ Manager, System Manager, Administrator. Unlike
  /// [canActAsLineManager] it does NOT fold in the POS Manager, which the
  /// tier's own endpoints refuse.
  bool get _isLineManagerTier =>
      isLineManager ||
      isJarzManager ||
      roles.contains(RoleNames.systemManager) ||
      roles.contains(RoleNames.administrator);

  /// Whether this user may open Master Orders. Mirrors
  /// `orders._ensure_elevated_access` = `LINE_MANAGER_TIER | {Moderator}`.
  bool get canAccessMasterOrders => _isLineManagerTier || isModerator;

  /// Whether this user may watch the Live Courier Map. Mirrors the courier
  /// app's `ROLES.COURIER_MAP_VIEWER`: the line-manager tier, both spellings.
  /// Opened to line managers by the owner on 2026-09-26; the server scopes
  /// them to their own branches.
  bool get canViewLiveCourierMap => _isLineManagerTier;

  /// Whether this user may open Price Lists (read). Mirrors
  /// `price_lists._ensure_pricing_read_access`: the line-manager tier, or B2B.
  bool get canViewPriceLists => _isLineManagerTier || canUseB2b;

  /// Whether this user may open Branch Access. Mirrors
  /// `branch_access.has_access` = `LINE_MANAGER_TIER` (no POS Manager).
  bool get canAccessBranchAccess => _isLineManagerTier;

  /// Whether this user may work the customer follow-ups list (المتابعات).
  /// Mirrors `api/customer_followups.py`'s gate, `ROLES.LINE_MANAGER_TIER`:
  /// the senders are the managers and line managers.
  bool get canAccessFollowups => _isLineManagerTier;

  /// Whether this user may work the chat inbox (WhatsApp / Instagram /
  /// Messenger / ad comments). Mirrors `api/chat.py`'s `CHAT_ROLES` =
  /// `{Moderator, Jarz Manager, System Manager} | LINE_MANAGER_TIER`.
  bool get canAccessChats => _isLineManagerTier || isModerator;

  /// Whether this user sees the chat metrics screen: the manager tier only.
  /// The endpoint itself admits every chat role; the screen is a manager view.
  bool get canViewChatMetrics => _isLineManagerTier;

  /// Whether this user may read follow-up stats. Narrower than the list:
  /// `get_followup_stats` admits JARZ Manager and System Manager only.
  bool get canViewFollowupStats =>
      isJarzManager ||
      roles.contains(RoleNames.systemManager) ||
      roles.contains(RoleNames.administrator);

  /// Whether this user may raise an item request. Mirrors
  /// `ROLES.PURCHASE_REQUEST`, the widest gate in the app: every POS user is in
  /// it. A B2B-only rep is not, so the tile is hidden from them.
  bool get canRaiseItemRequest =>
      canAccessPurchaseInvoice ||
      canAccessProductionBoard ||
      _isLineManagerTier ||
      roles.contains(RoleNames.posUser) ||
      roles.contains(RoleNames.posManager);

  /// Whether this user may manage the site's users (create, edit, disable,
  /// delete, set a password). Mirrors `services/user_admin.ACCESS_ROLES`.
  bool get canManageUsers =>
      isJarzManager ||
      roles.contains(RoleNames.systemManager) ||
      roles.contains(RoleNames.administrator);

  /// Whether this user may book money on a customer label batch (record the
  /// printer's bill, or a bought-and-received batch). Mirrors
  /// `api/labels._MANAGER_ROLES` exactly: JARZ Manager, System Manager,
  /// Administrator. Narrower than [canAccessPurchaseInvoice], which also
  /// admits the Accounts/Stock/Manufacturing/Purchase managers the labels API
  /// refuses.
  bool get canBillLabels =>
      isJarzManager ||
      roles.contains(RoleNames.systemManager) ||
      roles.contains(RoleNames.administrator);

  factory UserRoles.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    final rolesList = rolesRaw is List
        ? rolesRaw.map((e) => e.toString()).toList()
        : <String>[];
    return UserRoles(
      user: (json['user'] ?? '').toString(),
      fullName: json['full_name']?.toString(),
      roles: rolesList,
      employee: json['employee']?.toString(),
      employeeName: json['employee_name']?.toString(),
      branch: json['branch']?.toString(),
      requirePosShift:
          json['require_pos_shift'] == true || json['require_pos_shift'] == 1,
      isB2bSalesRep:
          json['is_b2b_sales_rep'] == true || json['is_b2b_sales_rep'] == 1,
      canAccessB2b:
          json['can_access_b2b'] == true || json['can_access_b2b'] == 1,
      managerHome: json['manager_home'] == true || json['manager_home'] == 1,
    );
  }
}

final userServiceProvider = Provider<UserService>((ref) {
  final dio = ref.watch(dioProvider);
  return UserService(dio);
});

class UserService {
  final Dio _dio;
  UserService(this._dio);

  Future<UserRoles> getCurrentUserRoles() async {
    final resp = await _dio.post(ApiEndpoints.getCurrentUserRoles, data: {});
    final data = resp.data;
    if (data is Map && data['message'] is Map) {
      return UserRoles.fromJson(
        Map<String, dynamic>.from(data['message'] as Map),
      );
    }
    if (data is Map) {
      return UserRoles.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Unexpected roles response');
  }
}

// Riverpod providers for roles state
final userRolesFutureProvider = FutureProvider<UserRoles>((ref) async {
  final service = ref.watch(userServiceProvider);
  return service.getCurrentUserRoles();
});

final isJarzManagerProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.isManager,
    orElse: () => false,
  );
});

final isLineManagerProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.isLineManager,
    orElse: () => false,
  );
});

/// Whether the user may take any line-manager action (cancel order, return
/// order, …). True for the line manager, the JARZ Manager and the admin tier.
final canActAsLineManagerProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canActAsLineManager,
    orElse: () => false,
  );
});

final canAccessManagerDashboardRoleProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canAccessManagerDashboard,
    orElse: () => false,
  );
});

final isModeratorProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.isModerator,
    orElse: () => false,
  );
});

/// Remembers the last answer [userRolesFutureProvider] gave for
/// [UserRoles.canMuteNotifications], for the duration of the session.
///
/// `maybeWhen(orElse: false)` answers "no" on every *reload* of the roles
/// future and on any transient failure. That is the wrong default here: it made
/// the mute button vanish from a ringing alarm — mid-alarm, with the volume keys
/// locked — every time roles were refetched or the network hiccuped, leaving a
/// manager with no way to silence the device. Cleared on logout by
/// [OrderAlertBridge] so it can never leak across users.
class CanMuteNotificationsCache extends StateNotifier<bool> {
  CanMuteNotificationsCache(this._ref) : super(false) {
    _ref.listen<AsyncValue<UserRoles>>(
      userRolesFutureProvider,
      (_, next) {
        final roles = next.valueOrNull;
        if (roles != null) {
          state = roles.canMuteNotifications;
        }
      },
      fireImmediately: true,
    );
  }

  final Ref _ref;

  void clear() => state = false;
}

final canMuteNotificationsCacheProvider =
    StateNotifierProvider<CanMuteNotificationsCache, bool>(
  CanMuteNotificationsCache.new,
);

final canMuteNotificationsProvider = Provider<bool>((ref) {
  // Watched unconditionally: the cache only records while something keeps it
  // alive, and it has to be recording *before* the roles future starts
  // reloading, not after.
  final cached = ref.watch(canMuteNotificationsCacheProvider);
  final roles = ref.watch(userRolesFutureProvider).valueOrNull;
  return roles?.canMuteNotifications ?? cached;
});

final canAccessShiftMonitorProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canAccessShiftMonitor,
    orElse: () => false,
  );
});

/// Whether the current user can open the Production Board.
///
/// Role-derived and synchronous — no server probe. The Manufacturing screen
/// used to gate on `managerAccessProvider`, which fires a manager-dashboard
/// request on every open and admits roles the production API rejects.
final canAccessProductionBoardProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canAccessProductionBoard,
    orElse: () => false,
  );
});

/// Whether the side menu offers the Task Board. See
/// [UserRoles.canAccessTaskBoard].
final canAccessTaskBoardProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canAccessTaskBoard,
    orElse: () => false,
  );
});

/// Whether the current user may open Cash Transfer.
///
/// Mirrors backend `ROLES.MANAGER`, not the manager-dashboard gate: a line
/// manager passes the latter and is refused by `api/cash_transfer.py`.
final canAccessCashTransferProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canAccessCashTransfer,
    orElse: () => false,
  );
});

/// Whether the current user may open Partner Settlements.
///
/// Mirrors backend `ROLES.MANAGER` — the same tier as Cash Transfer, and
/// deliberately NOT the manager-dashboard tier. Settling a delivery partner
/// posts the weekly bank transfer and settling a sales partner posts a
/// commission journal entry; a line manager passes the dashboard gate and
/// would be refused by both endpoints.
final canAccessPartnerSettlementsProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canAccessPartnerSettlements,
    orElse: () => false,
  );
});

/// Whether the current user may open the WooCommerce sync console.
///
/// Mirrors `ROLES.OPERATOR` in the separate `jarz_woocommerce_integration`
/// app, as enforced by its `services/access.ensure_operator_access` — which
/// includes JARZ Manager, so the console is visible to managers without anyone
/// having to hand-assign the dedicated operator role. That role still exists
/// for anyone who should run Woo sync WITHOUT being a manager.
final canAccessWooSyncProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canAccessWooSync,
    orElse: () => false,
  );
});

/// Whether the current user may open Stock Transfer. Mirrors
/// `ROLES.STOCK_TRANSFER` — the manager set plus the line-manager tier — as
/// enforced by `api/transfer.py`.
final canAccessStockTransferProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canAccessStockTransfer,
    orElse: () => false,
  );
});

/// Role half of the Stock Transfer gate for handovers. See
/// [UserRoles.canAccessStockHandover].
final canAccessStockHandoverProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canAccessStockHandover,
    orElse: () => false,
  );
});

/// Whether the current user may open Inventory Count. Mirrors `ROLES.STOCK`
/// as enforced by `api/inventory_count.py`.
final canAccessInventoryCountProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canAccessInventoryCount,
    orElse: () => false,
  );
});

/// Whether the current user may open the Purchase Invoice screen. Mirrors
/// `ROLES.PURCHASE` as enforced by `api/purchase.py`. Note this is NOT the gate
/// for raising an item request — `ROLES.PURCHASE_REQUEST` is deliberately open
/// to everyone, so that drawer entry stays ungated.
final canAccessPurchaseInvoiceProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canAccessPurchaseInvoice,
    orElse: () => false,
  );
});

/// See [UserRoles.canBillLabels].
final canBillLabelsProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canBillLabels,
    orElse: () => false,
  );
});

/// Whether the Reports hub has at least one report this user may read.
///
/// True for the line-manager tier because the hub still shows them Materials &
/// Consumables; the hub itself hides the dashboards their role would be refused
/// on. See [UserRoles.canAccessReportsHub].
final canAccessReportsHubProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canAccessReportsHub,
    orElse: () => false,
  );
});

/// Whether the current user may open the manager-only analytics dashboards
/// (P&L, revenue dashboard, ...). See [UserRoles.canViewAllReports]; false
/// while the roles are loading or failed.
final canViewAllReportsProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canViewAllReports,
    orElse: () => false,
  );
});

/// Whether the current user may start and finish production batches.
final canExecuteProductionProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canExecuteProduction,
    orElse: () => false,
  );
});

/// Whether the current user may post production on a past date.
final canBackDateProductionProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canBackDateProduction,
    orElse: () => false,
  );
});

/// Whether the current user may request a cash advance for an employee.
/// Mirrors LINE_MANAGER_TIER as enforced by
/// `api/employee_advances.create_employee_advance_request`.
///
/// This only hides the control. The bootstrap's `can_request` flag is the
/// truth, and the Employee Advances tab respects that as well.
final canRequestEmployeeAdvanceProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canRequestEmployeeAdvance,
    orElse: () => false,
  );
});

/// Whether the current user may approve or reject a cash advance. Deliberately
/// narrower than [canRequestEmployeeAdvanceProvider]: approving posts the
/// Payment Entry, so cash leaves the branch account immediately. Mirrors
/// `api/employee_advances.approve_employee_advance`.
final canApproveEmployeeAdvanceProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canApproveEmployeeAdvance,
    orElse: () => false,
  );
});

/// Whether the current user may open Monthly Expenses.
///
/// Mirrors `api/monthly_expenses.py`'s own gate (JARZ Manager, Administrator,
/// System Manager, Accounts Manager) rather than any of the broader manager
/// providers above. Client gate and server gate agree by construction; see
/// [UserRoles.canAccessMonthlyExpenses].
final canAccessMonthlyExpensesProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canAccessMonthlyExpenses,
    orElse: () => false,
  );
});

/// Whether the current user may return stranded WIP material to store.
final canManageProductionWipProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canManageProductionWip,
    orElse: () => false,
  );
});

/// Whether the current user can access B2B mode (sales reps + managers).
final canAccessB2bProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canUseB2b,
    orElse: () => false,
  );
});

/// Whether the current user can VIEW the Pricing (Price Lists) page.
/// Managers get full edit access; B2B sales reps get a read-only view.
final canViewPricingProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canViewPriceLists,
    orElse: () => false,
  );
});

bool _roleGate(Ref ref, bool Function(UserRoles roles) gate) =>
    ref.watch(userRolesFutureProvider).maybeWhen(
          data: gate,
          orElse: () => false,
        );

final canAccessMasterOrdersProvider =
    Provider<bool>((ref) => _roleGate(ref, (r) => r.canAccessMasterOrders));

final canViewLiveCourierMapProvider =
    Provider<bool>((ref) => _roleGate(ref, (r) => r.canViewLiveCourierMap));

final canAccessBranchAccessProvider =
    Provider<bool>((ref) => _roleGate(ref, (r) => r.canAccessBranchAccess));

/// Customer follow-ups (المتابعات). See [UserRoles.canAccessFollowups].
final canAccessFollowupsProvider =
    Provider<bool>((ref) => _roleGate(ref, (r) => r.canAccessFollowups));

/// Follow-up stats link. See [UserRoles.canViewFollowupStats].
final canViewFollowupStatsProvider =
    Provider<bool>((ref) => _roleGate(ref, (r) => r.canViewFollowupStats));

/// Chat inbox. See [UserRoles.canAccessChats].
final canAccessChatsProvider =
    Provider<bool>((ref) => _roleGate(ref, (r) => r.canAccessChats));

/// Chat metrics link. See [UserRoles.canViewChatMetrics].
final canViewChatMetricsProvider =
    Provider<bool>((ref) => _roleGate(ref, (r) => r.canViewChatMetrics));

final canRaiseItemRequestProvider =
    Provider<bool>((ref) => _roleGate(ref, (r) => r.canRaiseItemRequest));

/// User management (create / edit / disable / delete / password). JARZ Manager
/// and the admin tier only; the server enforces the same set.
final canManageUsersProvider =
    Provider<bool>((ref) => _roleGate(ref, (r) => r.canManageUsers));

/// Whether the current user can EDIT pricing (create lists, set category prices,
/// set/remove overrides, assign customers). Managers only; B2B reps are
/// read-only.
final canEditPricingProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  return rolesAsync.maybeWhen(
    data: (roles) => roles.canEditPricing,
    orElse: () => false,
  );
});

/// Whether the user needs to open a POS shift.
///
/// Driven solely by `User.custom_require_pos_shift`, which is the same flag the
/// backend enforces. The old line-manager "manager mode" escape hatch is gone:
/// it lived only on the client, so a line manager could take cash with no shift
/// open and leave the money unattributed at close. A line manager who genuinely
/// should not need a shift is configured by clearing the flag on their User.
final requirePosShiftProvider = Provider<bool>((ref) {
  final rolesAsync = ref.watch(userRolesFutureProvider);
  // `valueOrNull` keeps the last successful roles across a refresh failure.
  // `maybeWhen(orElse: false)` used to report "no shift needed" whenever the
  // roles call errored, silently switching the gate off on a network blip.
  final roles = rolesAsync.valueOrNull;
  if (roles == null) return false;
  return roles.requirePosShift;
});

/// Whether the current user gets the manager home (revenue dashboard landing
/// and the bottom bar). False until the roles load and on any roles error, so
/// nobody sees the bar by accident.
final managerHomeProvider = Provider<bool>((ref) {
  final roles = ref.watch(userRolesFutureProvider).valueOrNull;
  return roles?.usesManagerHome ?? false;
});
