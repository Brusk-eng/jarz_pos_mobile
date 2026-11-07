/// Centralised GoRouter path constants.
///
/// Use these instead of raw route strings in `context.go()` / `context.push()`
/// and in the GoRouter definition so every reference points to the same source.
abstract final class AppRoutes {
  static const login = '/login';
  static const about = '/about';
  static const pos = '/pos';
  static const selectProfile = '/pos/select-profile';
  static const kanban = '/kanban';
  static const printers = '/printers';
  static const manager = '/manager';
  static const shiftMonitor = '/shift-monitor';

  /// Monthly shift distribution — who works which shift, and who is off.
  /// Distinct from [shiftMonitor], which watches POS cash drawers: the two
  /// senses of "shift" in this app are unrelated.
  static const roster = '/roster';

  /// Attendance — who actually turned up against [roster]'s plan. Read-only,
  /// and deliberately a separate screen: the rota is edited in [roster], and a
  /// screen that both plans and judges the same day invites editing the plan
  /// to match what happened.
  static const attendance = '/attendance';

  /// Branch access — who may open which branch's POS, plus one-day access.
  /// Same line-manager gate as [roster], which can also grant a day's access.
  static const branchAccess = '/branch-access';
  static const purchase = '/purchase';

  /// Team item requests. Open to all floor staff, unlike [purchase] which is
  /// manager-gated — noticing a shortage is not a manager's job.
  static const itemRequests = '/item-requests';
  static const manufacturing = '/manufacturing';

  /// The collapsed front screen of the Production Board: one list of what is
  /// coming out of the kitchen today, one Make button. [manufacturing] stays
  /// registered behind it as the advanced board, so every `?tab=N` deep link
  /// and the SOP screen's own navigation keep working.
  static const productionToday = '/manufacturing/today';

  /// Full-screen SOP execution. A real destination rather than a sheet: the
  /// operator stays in it for the length of a batch.
  static const productionSop = '/manufacturing/sop';
  static const stockTransfer = '/stock-transfer';

  /// Stock Transfer opened on its Handovers tab (where a `stock_handover`
  /// push lands). Non-managers only have that view, so the query is ignored.
  static const stockTransferHandovers = '/stock-transfer?tab=handovers';

  /// What the factory should send each branch today. Separate from
  /// [stockTransfer], which is the manual "move these items from A to B" form:
  /// this one answers WHAT to move, and only then moves it.
  static const replenishment = '/replenishment';

  /// What the factory should MAKE this round so every branch holds a full
  /// cycle plus backup. The sibling of [replenishment], which says what to
  /// SEND out of what already exists.
  static const productionRound = '/production-round';
  static const cashTransfer = '/cash-transfer';

  /// Company cash held by named employees (العُهد).
  static const cashCustody = '/cash-custody';
  static const inventoryCount = '/inventory-count';

  /// Branch weekly stock count (Saturday to Friday): the count flow, the
  /// approver list, and one count's review. `approvals` is a static segment
  /// and must be registered before `:name`.
  static const weeklyCount = '/weekly-count';
  static const weeklyCountApprovals = '/weekly-count/approvals';
  static const weeklyCountDetail = '/weekly-count/:name';
  static String weeklyCountDetailFor(String name) =>
      '$weeklyCount/${Uri.encodeComponent(name)}';
  static const expenses = '/expenses';

  /// The company's monthly bill — the recurring-expense registry plus payroll
  /// for one month, with Pay actions. Distinct from [expenses], which records
  /// one-off spending; this pays a *period* of a standing commitment.
  static const monthlyExpenses = '/monthly-expenses';
  static const trips = '/trips';

  /// Live courier map. Supervisor-only: the tracking API deliberately refuses
  /// couriers, who may see their own run but never a colleague's position.
  static const fleetMap = '/fleet';

  /// Courier anomaly alerts (Detour, Speeding, Mock GPS ...). Same audience as
  /// [fleetMap]: the line-manager tier.
  static const courierAlerts = '/courier-alerts';
  static const reports = '/reports';
  static const reportsShipping = '/reports/shipping';
  static const reportsInventory = '/reports/inventory';
  static const reportsProduct = '/reports/product';
  static const reportsCustomer = '/reports/customer';
  static const reportsExecutive = '/reports/executive';
  static const reportsB2b = '/reports/b2b';
  static const reportsProfitLoss = '/reports/profit-loss';

  /// Daily revenue dashboard. Manager-only: not listed in
  /// `canOpenReportsLocation`, so it falls through to `canViewAllReports`.
  static const reportsRevenueDashboard = '/reports/revenue';

  // ── Reports overhaul: new reports + single-report stock routes ────────
  static const reportsUnitEconomics = '/reports/unit-economics';
  static const reportsDailyClose = '/reports/daily-close';
  static const reportsCashOverShort = '/reports/cash-over-short';
  static const reportsFulfilmentSla = '/reports/fulfilment-sla';
  static const reportsPromo = '/reports/promo-codes';
  static const reportsStockAdjustments = '/reports/stock-adjustments';
  static const reportsLabourCost = '/reports/labour-cost';

  /// Meta Ads dashboard. Gated on `UserRoles.canViewMetaAds` (adds System
  /// Manager and Meta CAPI Manager to the analytics set).
  static const reportsMetaAds = '/reports/meta-ads';
  static const reportsFinalProducts = '/reports/final-products';
  static const reportsMaterials = '/reports/materials';
  static const masterOrders = '/master-orders';
  static const instapayReconciliation = '/instapay-reconciliation';
  static const profile = '/profile';
  static const shiftStart = '/shift/start';
  static const shiftEnd = '/shift/end';
  static const root = '/';

  // ── B2B Mode ──────────────────────────────────────────────────────────
  // B2B mode's landing: the Active-stage customer list ("Active customers").
  static const b2b = '/b2b';
  // The sales pipeline Kanban board, one tap from the landing list.
  static const b2bPipeline = '/b2b/pipeline';
  static const b2bToday = '/b2b/today';
  static const b2bAccount = '/b2b/account';
  // Everything due, on a month grid — the cross-account view of the same next
  // actions the per-account journey timeline writes.
  static const b2bCalendar = '/b2b/calendar';

  // ── Visit planner ─────────────────────────────────────────────────────
  // The rep's field days: a month of routes, one route, and the builder that
  // turns a filtered slice of the catalog into a driveable day.
  static const b2bVisits = '/b2b/visits';
  static const b2bVisitPlan = '/b2b/visits/plan';
  static const b2bVisitBuilder = '/b2b/visits/build';

  // ── Pricing (Price Lists) ─────────────────────────────────────────────
  static const pricing = '/pricing';

  // ── B2B customer labels (printed-label stock + reorder alerts) ────────
  static const labels = '/labels';
  static const labelDetail = '/labels/detail';
  static const labelSetup = '/labels/setup';

  // ── Leads (B2B prospect research) ─────────────────────────────────────
  static const leads = '/leads';
  static const leadsMap = '/leads/map';
  static const leadForm = '/leads/new';
  static const leadDetail = '/leads/:id';

  // ── Partner settlements ───────────────────────────────────────────────
  // Two payables that were only ever cleared outside the app: the delivery
  // partner's weekly bank transfer, and sales partner commission.
  static const partnerSettlements = '/partner-settlements';

  // ── Address pin correction ────────────────────────────────────────────
  // Pushed from an address or an order, never a drawer entry.
  static const addressPin = '/address-pin';

  // ── Reports added to the existing hub ─────────────────────────────────
  // Velocity and Segments were merged into Inventory and Customers, and the
  // Executive overview into the P&L "Business overview"; the old paths (and
  // [reportsExecutive]) stay as redirects so saved links still land.
  static const reportsVelocity = '/reports/velocity';
  static const reportsSegments = '/reports/segments';
  static const reportsWarehouseAlignment = '/reports/warehouse-alignment';

  // ── Customer follow-ups (reorder plan) ────────────────────────────────
  // The sender's daily due list of WhatsApp / call touches after delivery.
  static const followups = '/followups';
  static const followupResults = '/followups/results';

  // ── Promo code lookup ─────────────────────────────────────────────────
  // Any logged-in staff member types a code and sees what the offer is,
  // optionally checked against one order.
  static const promoLookup = '/promo-lookup';

  // ── Chat inbox (moderator reply copilot) ──────────────────────────────
  // WhatsApp / Instagram / Messenger conversations with an AI-drafted reply.
  // `/chats/metrics` is matched before `/chats/:name` (it is declared first).
  static const chats = '/chats';
  static const chatsMetrics = '/chats/metrics';

  /// One conversation thread (`CHAT-00001`).
  static String chatThreadFor(String name) =>
      '$chats/${Uri.encodeComponent(name)}';

  // ── Credit accounts (B2B shops buying on account) ─────────────────────
  // The rolling-balance view: which shops owe money, their open invoices
  // oldest-first, and the payment that clears them FIFO. Manager-gated, like
  // the employee ledger it mirrors.
  static const creditAccounts = '/credit-accounts';
  static const creditAccountDetail = '/credit-accounts/detail';

  /// The accounts screen opened on its Collections view (side-menu
  /// "Collections due", settlement reminder without a customer).
  static const creditCollections = '/credit-accounts?view=collections';

  /// One shop's account by id alone — for push taps and deep links, which
  /// cannot carry `extra`. `/credit-accounts/<id>` (the settlement reminder's
  /// `route`) resolves to the same screen.
  static String creditAccountDetailFor(String customer) => Uri(
        path: creditAccountDetail,
        queryParameters: {'customer': customer},
      ).toString();

  // ── WooCommerce sync operations ───────────────────────────────────────
  // The retry / review / breaker workflow that lived only in Desk.
  static const wooSync = '/woo-sync';
  static const wooDuplicates = '/woo-sync/duplicates';

  // ── Task Board (line-manager tier) ────────────────────────────────────
  // `/tasks?view=all|mine|created|review`. The literal `/tasks/overview`
  // route is declared before `/tasks/:id` so the static segment wins.
  static const tasks = '/tasks';
  static const tasksOverview = '/tasks/overview';
  static const taskDetail = '/tasks/:id';

  /// The board opened on one view (`mine`, `review`, ...).
  static String tasksView(String view) =>
      Uri(path: tasks, queryParameters: {'view': view}).toString();

  /// One task's detail screen.
  static String taskDetailFor(String name) =>
      '$tasks/${Uri.encodeComponent(name)}';

  // ── User management (JARZ Manager / System Manager) ───────────────────
  // `/users/new` and `/users/couriers` are declared before `/users/:id` so the static segment wins.
  static const users = '/users';
  static const userNew = '/users/new';
  static const userCouriers = '/users/couriers';
  static const userDetail = '/users/:id';

  /// One account's detail/edit screen. The id is the login email.
  static String userDetailFor(String user) =>
      '$users/${Uri.encodeComponent(user)}';
}
