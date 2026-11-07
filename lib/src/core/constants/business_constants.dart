/// Business-domain constants shared between the mobile app and backend.
///
/// Status strings, payment modes, role names, and voucher types that **must**
/// match their ERPNext / backend equivalents exactly.
library;

// ── Payment modes ───────────────────────────────────────────────────────
abstract final class PaymentModes {
  static const cash = 'Cash';
  static const cashLower = 'cash';
  static const online = 'Online';
  static const onlineLower = 'online';

  /// Goods delivered, nothing paid at the door — the invoice stays an open
  /// receivable on the shop until a later payment clears it.
  ///
  /// Sent as `custom_payment_method` exactly like Cash / Instapay / Mobile
  /// Wallet, so the spelling must match the backend's select option. Credit is
  /// a PER-ORDER choice: a customer approved for credit still pays cash on
  /// most orders, so this never becomes anyone's default.
  static const credit = 'Credit';
  static const creditLower = 'credit';
}

// ── Courier settlement modes ───────────────────────────────────────────
abstract final class SettlementModes {
  static const payNow = 'pay_now';
  static const later = 'later';
}

abstract final class OutForDeliverySettlement {
  static const defaultMode = SettlementModes.later;
  static const showModePicker = false;
}

// ── Invoice / document statuses ─────────────────────────────────────────
abstract final class InvoiceStatus {
  static const draft = 'Draft';
  static const draftLower = 'draft';
  static const paid = 'Paid';
  static const paidLower = 'paid';
  static const paidUpper = 'PAID';
  static const unpaid = 'Unpaid';
  static const unpaidUpper = 'UNPAID';
  static const cancelled = 'Cancelled';
  static const cancelledLower = 'cancelled';
  static const submitted = 'Submitted';
  static const submittedLower = 'submitted';
  static const returnStatus = 'Return';
  static const open = 'Open';
}

// ── Delivery / acceptance statuses ──────────────────────────────────────
abstract final class DeliveryStatus {
  static const outForDelivery = 'out for delivery';
  static const outForDeliverySnake = 'out_for_delivery';
  static const delivered = 'delivered';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
  /// Terminal kanban state a fully-returned order lands in. Set by the backend
  /// post-dispatch return workflow — never by a drag.
  static const returned = 'returned';
  static const pending = 'pending';
  static const accepted = 'accepted';
}

// ── Post-dispatch return statuses ───────────────────────────────────────
/// Values of the Sales Invoice `return_status` field. Must match the backend
/// return workflow exactly; an empty/absent value means "nothing returned".
abstract final class ReturnStatus {
  static const partiallyReturned = 'Partially Returned';
  static const fullyReturned = 'Fully Returned';
}

// ── Voucher types ───────────────────────────────────────────────────────
abstract final class VoucherTypes {
  static const salesInvoice = 'Sales Invoice';
  static const journalEntry = 'Journal Entry';
  static const paymentEntry = 'Payment Entry';
}

// ── Role names ──────────────────────────────────────────────────────────
abstract final class RoleNames {
  static const jarzManager = 'JARZ Manager';
  static const jarzLineManager = 'JARZ line manager';

  /// The lower-case spelling of the line-manager role. Both exist as real Role
  /// records on staging and production, and the backend's
  /// `ROLES.LINE_MANAGER_TIER` carries both — so anywhere this client names the
  /// line manager it must name both too, or it silently treats half the people
  /// holding the role as plain POS users.
  static const jarzLineManagerAlt = 'jarz line manager';
  static const posManager = 'POS Manager';
  static const posUser = 'POS User';
  static const systemManager = 'System Manager';
  static const administrator = 'Administrator';
  static const moderator = 'Moderator';
  static const jarzPosStaff = 'Jarz POS Staff';
  static const b2bSalesRep = 'B2B Sales Rep';

  /// The operator who reconciles WooCommerce against ERPNext: retries failed
  /// sync events, sets review states, clears the outbound circuit breaker.
  ///
  /// This role belongs to the SEPARATE `jarz_woocommerce_integration` app,
  /// which creates the Role record on install but grants it to nobody — so a
  /// user holding only this string sees the console and everyone else does
  /// not. Mirrors that app's `ROLES.OPERATOR`, which also admits System
  /// Manager; Administrator short-circuits it server-side.
  static const wooSyncOperator = 'WooCommerce Sync Operator';

  // Stock/manufacturing roles. Mirror the backend `ROLES.MANUFACTURING` set so
  // the Production Board's client-side gate matches its server-side one — the
  // Manufacturing screen used to gate on a role the API did not accept, so a
  // JARZ-Manager-only user could open it and then fail every call.
  static const manufacturingManager = 'Manufacturing Manager';
  static const stockManager = 'Stock Manager';
  static const purchaseManager = 'Purchase Manager';

  /// Also a member of the backend's `MANAGER`, `STOCK` and `PURCHASE` sets,
  /// which gate Cash Transfer, Stock Transfer, Inventory Count and the Purchase
  /// Invoice screens.
  static const accountsManager = 'Accounts Manager';

  /// Floor role: may run batches but not back-date a posting, edit an SOP, or
  /// start a batch above the configured value limit.
  static const productionOperator = 'Production Operator';

  /// The media buyer's role: manages the Meta Conversions API settings and
  /// reads the Meta Ads report (`meta_ads.get_ads_report`), nothing else in
  /// the Reports hub.
  static const metaCapiManager = 'Meta CAPI Manager';
}

// ── Cancel reasons (defaults — will later be fetched from backend) ─────
abstract final class CancelReasons {
  static const defaults = [
    'Customer requested cancellation',
    'Order created in error / duplicate',
    'Inventory unavailable',
    'Payment issue',
    'Other',
  ];
}
