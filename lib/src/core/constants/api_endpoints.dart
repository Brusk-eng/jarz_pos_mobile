/// Centralised API endpoint paths.
///
/// Every `/api/method/…` string used by the mobile app lives here so that
/// a backend module rename only requires a single-file update.
abstract final class ApiEndpoints {
  // ── Auth ──────────────────────────────────────────────────────────────
  static const login = '/api/method/login';
  static const logout = '/api/method/logout';
  static const getLoggedUser = '/api/method/frappe.auth.get_logged_user';

  // ── User ──────────────────────────────────────────────────────────────
  static const getCurrentUserRoles =
      '/api/method/jarz_pos.api.user.get_current_user_roles';

  // ── POS ───────────────────────────────────────────────────────────────
  static const getPosProfiles = '/api/method/jarz_pos.api.pos.get_pos_profiles';
  static const getProfileBundles =
      '/api/method/jarz_pos.api.pos.get_profile_bundles';
  static const getPosProfileAccountBalance =
      '/api/method/jarz_pos.api.pos.get_pos_profile_account_balance';
  static const getProfileProducts =
      '/api/method/jarz_pos.api.pos.get_profile_products';
  static const getPosPriceLists =
      '/api/method/jarz_pos.api.pos.get_pos_price_lists';
  static const getCommercialPolicies =
      '/api/method/jarz_pos.api.pos.get_commercial_policies';
  static const getB2bPricingContext =
      '/api/method/jarz_pos.api.pos.get_b2b_pricing_context';
  static const resolveCustomerPriceList =
      '/api/method/jarz_pos.api.pos.resolve_customer_price_list';
  static const getSalesPartners =
      '/api/method/jarz_pos.api.pos.get_sales_partners';
  static const isPosProfileOpen =
      '/api/method/jarz_pos.api.pos.is_pos_profile_open';
  static const getTerritoryPosProfile =
      '/api/method/jarz_pos.api.pos.get_territory_pos_profile';

  // ── Customer ──────────────────────────────────────────────────────────
  static const getTerritories =
      '/api/method/jarz_pos.api.customer.get_territories';
  static const searchCustomers =
      '/api/method/jarz_pos.api.customer.search_customers';
  static const createCustomer =
      '/api/method/jarz_pos.api.customer.create_customer';
  static const updateDefaultAddress =
      '/api/method/jarz_pos.api.customer.update_default_address';
  static const getCustomerShippingAddresses =
      '/api/method/jarz_pos.api.customer.get_customer_shipping_addresses';
  static const saveCustomerShippingAddress =
      '/api/method/jarz_pos.api.customer.save_customer_shipping_address';
  static const updateCustomerShippingAddress =
      '/api/method/jarz_pos.api.customer.update_customer_shipping_address';
  static const deleteCustomerShippingAddress =
      '/api/method/jarz_pos.api.customer.delete_customer_shipping_address';
  static const changeInvoiceShippingAddress =
      '/api/method/jarz_pos.api.customer.change_invoice_shipping_address';

  // ── Credit / on account ───────────────────────────────────────────────
  // B2B shops that take an order on credit: goods delivered, nothing paid at
  // the door. Credit is a PER-ORDER choice, so the profile below gates the
  // checkout selector rather than the customer record gating the whole shop.
  static const getCustomerCreditProfile =
      '/api/method/jarz_pos.api.credit.get_customer_credit_profile';

  /// The customer analogue of `manager.get_employee_ledger`: per-shop
  /// all-time balances plus a window-scoped invoice feed.
  static const getCreditLedger =
      '/api/method/jarz_pos.api.credit.get_credit_ledger';

  /// Allocates a payment FIFO across the shop's open credit invoices, oldest
  /// first. Any excess is left as an unallocated advance.
  static const recordCreditPayment =
      '/api/method/jarz_pos.api.credit.record_credit_payment';

  /// Switches a shop's credit on/off and sets its days / limit (managers).
  static const updateCustomerCreditSettings =
      '/api/method/jarz_pos.api.credit.update_customer_credit_settings';

  /// The shop branch (delivery door) each chosen invoice went to, for the
  /// account statement's per-branch sections.
  static const getInvoiceShopBranches =
      '/api/method/jarz_pos.api.credit.get_invoice_shop_branches';

  // ── Settlement terms (B2B collection schedule + reminders) ─────────────
  // A schedule and reminders, never a gate: nothing here blocks an order.
  static const getSettlementTerms =
      '/api/method/jarz_pos.api.settlement_terms.get_settlement_terms';
  static const saveSettlementTerms =
      '/api/method/jarz_pos.api.settlement_terms.save_settlement_terms';
  static const deleteSettlementTerms =
      '/api/method/jarz_pos.api.settlement_terms.delete_settlement_terms';
  static const getCollectionsDue =
      '/api/method/jarz_pos.api.settlement_terms.get_collections_due';

  // ── Geo ───────────────────────────────────────────────────────────────
  /// Read-only resolve of a pasted Maps link into coordinates + the distance
  /// from the branch. Writes nothing; the address save carries the result.
  static const previewMapsLink =
      '/api/method/jarz_pos.api.geo.preview_maps_link';

  // ── Invoices ──────────────────────────────────────────────────────────
  static const createPosInvoice =
      '/api/method/jarz_pos.api.invoices.create_pos_invoice';
  static const validatePromoCodes =
      '/api/method/jarz_pos.api.promo.validate_promo_codes';

  /// Read-only: what a promo code is, and optionally what it would do to one
  /// order (`order` = Woo order number or invoice name). Login only.
  static const lookupPromoCode =
      '/api/method/jarz_pos.api.promo.lookup_promo_code';
  static const submitInvoiceAmendment =
      '/api/method/jarz_pos.api.manager.submit_invoice_amendment';
  static const payInvoice = '/api/method/jarz_pos.api.invoices.pay_invoice';
  static const getInvoiceSettlementPreview =
      '/api/method/jarz_pos.api.invoices.get_invoice_settlement_preview';
  static const updateInvoiceDeliverySlot =
      '/api/method/jarz_pos.api.invoices.update_invoice_delivery_slot';

  // ── Delivery Slots ────────────────────────────────────────────────────
  static const getAvailableDeliverySlots =
      '/api/method/jarz_pos.api.delivery_slots.get_available_delivery_slots';
  static const getNextAvailableSlot =
      '/api/method/jarz_pos.api.delivery_slots.get_next_available_slot';

  // ── Shift ─────────────────────────────────────────────────────────────
  static const getActiveShift =
      '/api/method/jarz_pos.api.shift.get_active_shift';
  static const getShiftPaymentMethods =
      '/api/method/jarz_pos.api.shift.get_shift_payment_methods';
  static const startShift = '/api/method/jarz_pos.api.shift.start_shift';
  static const getShiftSummary =
      '/api/method/jarz_pos.api.shift.get_shift_summary';
  static const endShift = '/api/method/jarz_pos.api.shift.end_shift';
  static const getForceCloseShiftPreview =
      '/api/method/jarz_pos.api.shift.get_force_close_preview';
  static const forceCloseShift =
      '/api/method/jarz_pos.api.shift.force_close_shift';

  /// Past shifts, newest first. Amounts come back only for managers.
  static const listShifts = '/api/method/jarz_pos.api.shift.list_shifts';

  // ── Kanban ────────────────────────────────────────────────────────────
  static const getKanbanColumns =
      '/api/method/jarz_pos.api.kanban.get_kanban_columns';
  static const getKanbanInvoices =
      '/api/method/jarz_pos.api.kanban.get_kanban_invoices';
  static const updateInvoiceState =
      '/api/method/jarz_pos.api.kanban.update_invoice_state';
  static const previewInvoiceOutForDelivery =
      '/api/method/jarz_pos.api.kanban.preview_invoice_out_for_delivery';
  static const cancelInvoice = '/api/method/jarz_pos.api.kanban.cancel_invoice';
  // Post-dispatch return workflow (credit note + return delivery note).
  static const getReturnPreview =
      '/api/method/jarz_pos.api.returns.get_return_preview';
  static const submitInvoiceReturn =
      '/api/method/jarz_pos.api.returns.submit_invoice_return';
  static const getInvoiceDetails =
      '/api/method/jarz_pos.api.kanban.get_invoice_details';
  static const getInvoiceNotes =
      '/api/method/jarz_pos.api.kanban.get_invoice_notes';
  static const addInvoiceNote =
      '/api/method/jarz_pos.api.kanban.add_invoice_note';
  static const getKanbanFilters =
      '/api/method/jarz_pos.api.kanban.get_kanban_filters';

  // ── Couriers / Delivery ───────────────────────────────────────────────
  static const getCourierBalances =
      '/api/method/jarz_pos.api.couriers.get_courier_balances';
  static const handleOutForDeliveryTransition =
      '/api/method/jarz_pos.api.couriers.handle_out_for_delivery_transition';
  static const getActiveCouriers =
      '/api/method/jarz_pos.api.couriers.get_active_couriers';
  static const markCourierOutstanding =
      '/api/method/jarz_pos.api.couriers.mark_courier_outstanding';
  static const createDeliveryParty =
      '/api/method/jarz_pos.api.couriers.create_delivery_party';
  static const getDeliveryPartnersList =
      '/api/method/jarz_pos.api.couriers.get_delivery_partners_list';
  static const settleSingleInvoicePaid =
      '/api/method/jarz_pos.api.couriers.settle_single_invoice_paid';
  static const settleCourierCollectedPayment =
      '/api/method/jarz_pos.api.couriers.settle_courier_collected_payment';
  static const changePaymentCollectionMethod =
      '/api/method/jarz_pos.api.couriers.change_payment_collection_method';
  static const generateSettlementPreview =
      '/api/method/jarz_pos.api.couriers.generate_settlement_preview';
  static const confirmSettlement =
      '/api/method/jarz_pos.api.couriers.confirm_settlement';

  // ── InstaPay-on-delivery reconciliation (online payment assurance) ─────
  static const deliverOnlineUnconfirmed =
      '/api/method/jarz_pos.api.couriers.deliver_online_unconfirmed';
  static const listUnconfirmedOnlineOrders =
      '/api/method/jarz_pos.api.couriers.list_unconfirmed_online_orders';
  static const confirmOnlinePayment =
      '/api/method/jarz_pos.api.couriers.confirm_online_payment';
  static const convertOnlineOrderToCod =
      '/api/method/jarz_pos.api.couriers.convert_online_order_to_cod';

  // ── Delivery Handling (service-level endpoints) ───────────────────────
  static const settleDeliveryParty =
      '/api/method/jarz_pos.jarz_pos.services.delivery_handling.settle_delivery_party';
  static const settleCourier =
      '/api/method/jarz_pos.jarz_pos.services.delivery_handling.settle_courier';
  static const salesPartnerUnpaidOutForDelivery =
      '/api/method/jarz_pos.jarz_pos.services.delivery_handling.sales_partner_unpaid_out_for_delivery';
  static const salesPartnerPaidOutForDelivery =
      '/api/method/jarz_pos.jarz_pos.services.delivery_handling.sales_partner_paid_out_for_delivery';

  // ── App releases ──────────────────────────────────────────────────────
  /// Guest-callable on purpose: the update check runs before login, so a build
  /// below the floor is stopped at the splash screen rather than after it has
  /// authenticated and started writing.
  static const getAppRequirement =
      '/api/method/jarz_pos.api.app_release.get_app_requirement';

  // ── Notifications ─────────────────────────────────────────────────────
  static const registerMobileDevice =
      '/api/method/jarz_pos.api.notifications.register_mobile_device';
  static const getVapidPublicKey =
      '/api/method/jarz_pos.api.notifications.get_vapid_public_key';
  static const registerVapidSubscription =
      '/api/method/jarz_pos.api.notifications.register_vapid_subscription';
  static const acknowledgeInvoice =
      '/api/method/jarz_pos.api.notifications.acknowledge_invoice';
  static const getPendingAlerts =
      '/api/method/jarz_pos.api.notifications.get_pending_alerts';
  static const checkForUpdates =
      '/api/method/jarz_pos.api.notifications.check_for_updates';
  static const getRecentInvoices =
      '/api/method/jarz_pos.api.notifications.get_recent_invoices';
  static const testWebsocketEmission =
      '/api/method/jarz_pos.api.notifications.test_websocket_emission';
  static const getWebsocketDebugInfo =
      '/api/method/jarz_pos.api.notifications.get_websocket_debug_info';

  // ── Purchase ──────────────────────────────────────────────────────────
  static const getSuppliers = '/api/method/jarz_pos.api.purchase.get_suppliers';
  static const getRecentSuppliers =
      '/api/method/jarz_pos.api.purchase.get_recent_suppliers';
  static const searchItems = '/api/method/jarz_pos.api.purchase.search_items';
  static const getItemDetails =
      '/api/method/jarz_pos.api.purchase.get_item_details';
  static const getItemPrice =
      '/api/method/jarz_pos.api.purchase.get_item_price';
  static const createPurchaseInvoice =
      '/api/method/jarz_pos.api.purchase.create_purchase_invoice';
  static const getPurchaseInvoices =
      '/api/method/jarz_pos.api.purchase.get_purchase_invoices';
  static const createSupplier =
      '/api/method/jarz_pos.api.purchase.create_supplier';
  static const getSupplierGroups =
      '/api/method/jarz_pos.api.purchase.get_supplier_groups';
  static const getPurchaseTaxesTemplates =
      '/api/method/jarz_pos.api.purchase.get_purchase_taxes_templates';
  static const getItemTaxTemplates =
      '/api/method/jarz_pos.api.purchase.get_item_tax_templates';
  static const payPurchaseInvoice =
      '/api/method/jarz_pos.api.purchase.pay_purchase_invoice';
  static const returnPurchaseInvoice =
      '/api/method/jarz_pos.api.purchase.return_purchase_invoice';

  // ── Purchase requests (team item requests) ────────────────────────────
  static const createItemRequest =
      '/api/method/jarz_pos.api.purchase_request.create_request';
  static const getItemRequestForEdit =
      '/api/method/jarz_pos.api.purchase_request.get_request_for_edit';
  static const updateItemRequest =
      '/api/method/jarz_pos.api.purchase_request.update_request';
  static const listItemRequests =
      '/api/method/jarz_pos.api.purchase_request.list_requests';
  static const stopItemRequest =
      '/api/method/jarz_pos.api.purchase_request.stop_request';
  static const reopenItemRequest =
      '/api/method/jarz_pos.api.purchase_request.reopen_request';
  static const getOpenRequestLines =
      '/api/method/jarz_pos.api.purchase_request.get_open_request_lines';
  static const acknowledgeItemRequest =
      '/api/method/jarz_pos.api.purchase_request.acknowledge_request';
  static const getItemRequestCounts =
      '/api/method/jarz_pos.api.purchase_request.get_request_counts';

  // ── Approvals (side-menu indicator) ───────────────────────────────────
  static const getPendingApprovals =
      '/api/method/jarz_pos.api.approvals.get_pending_approvals';

  // ── Manager ───────────────────────────────────────────────────────────
  static const getManagerDashboardSummary =
      '/api/method/jarz_pos.api.manager.get_manager_dashboard_summary';
  static const getPosShiftMonitor =
      '/api/method/jarz_pos.api.manager.get_pos_shift_monitor';
  static const getManagerTransferTargetBranches =
      '/api/method/jarz_pos.api.manager.get_transfer_target_branches';
  static const getManagerOrders =
      '/api/method/jarz_pos.api.manager.get_manager_orders';
  static const getManagerStates =
      '/api/method/jarz_pos.api.manager.get_manager_states';
  static const updateInvoiceBranch =
      '/api/method/jarz_pos.api.manager.update_invoice_branch';

  // ── Staff customers (Employee-purpose orders) ─────────────────────────
  // A staff order is only deducted from payroll when its Customer is linked
  // to an Employee, so the POS picks a person and the backend guarantees the
  // linked customer. All three are gated to the manager tier server-side.
  static const listStaffForOrders =
      '/api/method/jarz_pos.api.employee_customers.list_staff_for_orders';
  static const ensureStaffCustomer =
      '/api/method/jarz_pos.api.employee_customers.ensure_staff_customer';
  static const syncStaffCustomers =
      '/api/method/jarz_pos.api.employee_customers.sync_staff_customers';

  // ── Stock Transfer ────────────────────────────────────────────────────
  static const transferListPosProfiles =
      '/api/method/jarz_pos.api.transfer.list_pos_profiles';
  static const transferListItemGroups =
      '/api/method/jarz_pos.api.transfer.list_item_groups';
  static const searchItemsWithStock =
      '/api/method/jarz_pos.api.transfer.search_items_with_stock';
  static const submitTransfer =
      '/api/method/jarz_pos.api.transfer.submit_transfer';
  static const transferListHistory =
      '/api/method/jarz_pos.api.transfer.list_transfers';

  // ── Stock Handover ────────────────────────────────────────────────────
  // A movement that touches a branch is declared by one side and becomes a
  // Stock Entry only when the OTHER side confirms. `submitTransfer` above now
  // answers `pending: true` + a handover name for those instead of posting.
  static const stockHandoverGetContext =
      '/api/method/jarz_pos.api.stock_handover.get_context';
  static const stockHandoverListItems =
      '/api/method/jarz_pos.api.stock_handover.list_items';
  static const stockHandoverDeclare =
      '/api/method/jarz_pos.api.stock_handover.declare';
  static const stockHandoverList =
      '/api/method/jarz_pos.api.stock_handover.list_handovers';
  static const stockHandoverRespond =
      '/api/method/jarz_pos.api.stock_handover.respond';
  static const stockHandoverCancel =
      '/api/method/jarz_pos.api.stock_handover.cancel';

  // Transit matching (managers): "I sent out" posts the stock into the
  // transit warehouse; a manager approves each receipt against the sends.
  static const stockHandoverTransitBoard =
      '/api/method/jarz_pos.api.stock_handover.get_transit_board';
  static const stockHandoverApproveReceipt =
      '/api/method/jarz_pos.api.stock_handover.approve_receipt';
  static const stockHandoverRejectReceipt =
      '/api/method/jarz_pos.api.stock_handover.reject_receipt';
  static const stockHandoverWriteOffTransit =
      '/api/method/jarz_pos.api.stock_handover.write_off_transit';
  static const stockHandoverReturnToSender =
      '/api/method/jarz_pos.api.stock_handover.return_to_sender';

  // ── Branch Replenishment ─────────────────────────────────────
  /// What each branch is short of, against its own selling rate. Read only —
  /// the send half of that screen posts to [submitTransfer], because moving
  /// stock is one server method and should stay one client path.
  static const getBranchReplenishment =
      '/api/method/jarz_pos.api.replenishment.get_branch_replenishment';

  /// What the factory should MAKE this round (batches per size, the prep to do
  /// first, the materials that are short). Read only; gated server-side on
  /// the production view roles.
  static const getProductionRound =
      '/api/method/jarz_pos.api.replenishment.get_production_round';

  // ── Cash Transfer ─────────────────────────────────────────────────────
  static const cashTransferListAccounts =
      '/api/method/jarz_pos.api.cash_transfer.list_accounts';
  static const cashTransferSubmit =
      '/api/method/jarz_pos.api.cash_transfer.submit_transfer';
  static const cashTransferListHistory =
      '/api/method/jarz_pos.api.cash_transfer.list_transfers';

  // ── Cash Custody (العُهد) ─────────────────────────────────────────────
  // Company cash held by named employees. Issue/return post journal entries
  // between a till/cash/bank account and the holder's custody account; the
  // server refuses anything that would take a custody balance below zero.
  static const custodyOverview =
      '/api/method/jarz_pos.api.cash_custody.get_custody_overview';
  static const custodyListCandidates =
      '/api/method/jarz_pos.api.cash_custody.list_custody_candidates';
  static const custodyAddHolder =
      '/api/method/jarz_pos.api.cash_custody.add_custody_holder';
  static const custodySetHolderEnabled =
      '/api/method/jarz_pos.api.cash_custody.set_custody_holder_enabled';
  static const custodyIssue =
      '/api/method/jarz_pos.api.cash_custody.issue_custody';
  static const custodyReturn =
      '/api/method/jarz_pos.api.cash_custody.return_custody';
  static const custodyStatement =
      '/api/method/jarz_pos.api.cash_custody.get_custody_statement';

  // ── Manufacturing / Production ────────────────────────────────────────
  static const getProductionSuggestions =
      '/api/method/jarz_pos.api.production.get_production_suggestions';
  static const getBasketMaterialRollup =
      '/api/method/jarz_pos.api.production.get_basket_material_rollup';
  static const setItemTargetDays =
      '/api/method/jarz_pos.api.production.set_item_target_days';
  static const listDefaultBomItems =
      '/api/method/jarz_pos.api.manufacturing.list_default_bom_items';
  static const getBomDetails =
      '/api/method/jarz_pos.api.manufacturing.get_bom_details';
  static const submitWorkOrders =
      '/api/method/jarz_pos.api.manufacturing.submit_work_orders';
  // Books what actually came out, in one call per stage: Work Order, material
  // transfer and Manufacture entry together. Same line shape and same response
  // shape as `submit_work_orders`; `strict_basket` makes the basket-wide
  // material precheck refuse the whole call rather than post a partial day.
  static const produceNow =
      '/api/method/jarz_pos.api.manufacturing.produce_now';
  static const submitSingleWorkOrder =
      '/api/method/jarz_pos.api.manufacturing.submit_single_work_order';
  static const listRecentWorkOrders =
      '/api/method/jarz_pos.api.manufacturing.list_recent_work_orders';
  static const startProductionBatch =
      '/api/method/jarz_pos.api.manufacturing.start_production_batch';
  // Starts SEVERAL batches under one basket-wide material check. Calling
  // `start_production_batch` in a loop instead would skip that check, and a
  // basket can pass line by line while collectively emptying a store -- with
  // the earlier lines already committed by the time the last one finds out.
  static const startProductionBatches =
      '/api/method/jarz_pos.api.manufacturing.start_production_batches';
  static const finishProductionBatch =
      '/api/method/jarz_pos.api.manufacturing.finish_production_batch';
  static const listRunningWorkOrders =
      '/api/method/jarz_pos.api.manufacturing.list_running_work_orders';
  static const getBatchCost =
      '/api/method/jarz_pos.api.manufacturing.get_batch_cost';
  static const returnWipToStore =
      '/api/method/jarz_pos.api.manufacturing.return_wip_to_store';
  // Abort a batch that was started and must not be finished: returns whatever
  // is still in WIP and stops the Work Order. Refused by the server once
  // anything has been produced -- that batch has to be finished for what it
  // actually made.
  static const cancelProductionBatch =
      '/api/method/jarz_pos.api.manufacturing.cancel_production_batch';
  // What the server will actually accept from THIS user: the backdating window
  // it enforces and whether this account may use it. The app used to hardcode
  // its own window, which disagreed with the server's silently -- the picker
  // offered yesterday and the post was refused.
  static const getProductionPolicy =
      '/api/method/jarz_pos.api.manufacturing.get_production_policy';
  // Moves a short component into the warehouse its recipe draws from. Not a
  // general stock transfer: the server only accepts a BOM component, and only
  // into a warehouse that component is actually demanded from.
  static const transferMaterialForProduction =
      '/api/method/jarz_pos.api.manufacturing.transfer_material_for_production';

  // ── Sub-assemblies (bases) ────────────────────────────────────────────
  // Bases are never sold, so the sales-driven board computes zero for them.
  // These two answer "what bases exist" and "what would this run cost me"
  // instead. A cake is started through `start_production_batches` and finished
  // on the Running tab; a mix is booked outright through `produce_now`, because
  // a five-minute stir has nothing to come back and finish.
  //
  // `preview_base_batch` accepts EITHER `batches` or `qty`. The mixes are
  // weighed, not counted, so asking them for a batch count is the thing this
  // screen exists to stop doing.
  static const getBaseItems =
      '/api/method/jarz_pos.api.subassembly.get_base_items';
  static const previewBaseBatch =
      '/api/method/jarz_pos.api.subassembly.preview_base_batch';

  // ── Daily Production Plan ─────────────────────────────────────────────
  static const dailyPlanTemplate =
      '/api/method/jarz_pos.api.daily_plan.get_plan_template';
  static const dailyPlanPreview =
      '/api/method/jarz_pos.api.daily_plan.preview_plan';
  static const dailyPlanSave = '/api/method/jarz_pos.api.daily_plan.save_plan';
  static const dailyPlanClose =
      '/api/method/jarz_pos.api.daily_plan.close_plan';
  // Calling off a day that will not be produced. Distinct from closing it with
  // zero actuals, which reads as "we tried and made nothing".
  static const dailyPlanCancel =
      '/api/method/jarz_pos.api.daily_plan.cancel_plan';
  static const dailyPlanGet = '/api/method/jarz_pos.api.daily_plan.get_plan';
  static const dailyPlanList = '/api/method/jarz_pos.api.daily_plan.list_plans';
  static const dailyPlanBomReadiness =
      '/api/method/jarz_pos.api.daily_plan.check_bom_readiness';

  // ── Production SOPs ───────────────────────────────────────────────────
  static const getSopForItem = '/api/method/jarz_pos.api.sop.get_sop_for_item';
  static const getSopForWorkOrder =
      '/api/method/jarz_pos.api.sop.get_sop_for_work_order';
  static const recordSopStepCapture =
      '/api/method/jarz_pos.api.sop.record_sop_step_capture';
  static const listSops = '/api/method/jarz_pos.api.sop.list_sops';

  /// Item codes that have an active SOP. Absent on an older backend — callers
  /// treat any failure as "no item has one".
  static const listItemsWithSop =
      '/api/method/jarz_pos.api.sop.list_items_with_sop';

  /// Frappe core, not a jarz_pos method — SOP photo captures have to become a
  /// File on the site before `record_sop_step_capture` can reference a URL.
  static const uploadFile = '/api/method/upload_file';

  // ── Inventory Count ───────────────────────────────────────────────────
  static const listWarehouses =
      '/api/method/jarz_pos.api.inventory_count.list_warehouses';
  static const listItemsForCount =
      '/api/method/jarz_pos.api.inventory_count.list_items_for_count';
  static const submitReconciliation =
      '/api/method/jarz_pos.api.inventory_count.submit_reconciliation';
  static const listReconciliations =
      '/api/method/jarz_pos.api.inventory_count.list_reconciliations';

  // ── Expenses ──────────────────────────────────────────────────────────
  static const getExpenseBootstrap =
      '/api/method/jarz_pos.api.expenses.get_expense_bootstrap';
  static const createExpense =
      '/api/method/jarz_pos.api.expenses.create_expense';
  static const approveExpense =
      '/api/method/jarz_pos.api.expenses.approve_expense';
  // Turning a request down. `reject` refuses a pending request and leaves it a
  // draft; `cancel` reverses one that was already approved, and therefore also
  // reverses the journal entry the approval posted. Two endpoints rather than
  // one because they are two different acts.
  static const rejectExpense =
      '/api/method/jarz_pos.api.expenses.reject_expense';
  static const cancelExpense =
      '/api/method/jarz_pos.api.expenses.cancel_expense';

  // ── Monthly Expenses ──────────────────────────────────────────────────
  // The company's monthly bill: the Jarz Recurring Expense registry plus HRMS
  // payroll, for one `YYYY-MM` period, with what is due, what has been paid and
  // what REMAINS. Distinct from the ad-hoc `expenses.*` endpoints above, which
  // record one-off spending; these pay a *period* of a standing commitment.
  // Every one of them is gated server-side on the same manager set as
  // `recurring_expenses._ensure_manager`.
  static const getMonthlyExpenses =
      '/api/method/jarz_pos.api.monthly_expenses.get_monthly_expenses';
  static const payRecurringExpense =
      '/api/method/jarz_pos.api.monthly_expenses.pay_recurring_expense';
  static const paySalary =
      '/api/method/jarz_pos.api.monthly_expenses.pay_salary';
  static const saveRecurringExpense =
      '/api/method/jarz_pos.api.monthly_expenses.save_recurring_expense';
  static const setRecurringExpenseStatus =
      '/api/method/jarz_pos.api.monthly_expenses.set_recurring_expense_status';
  // Delegates to `expenses.cancel_expense`, so cancelling a monthly payment
  // reverses the very same journal entry the payment posted.
  static const cancelExpensePayment =
      '/api/method/jarz_pos.api.monthly_expenses.cancel_expense_payment';
  // A `Jarz Employee Penalty` — days, half-days or money, all three stored as
  // one amount plus its day equivalent. It posts NO journal entry: salary is
  // expensed when it is paid, so paying less already books less expense.
  static const addEmployeePenalty =
      '/api/method/jarz_pos.api.monthly_expenses.add_employee_penalty';
  static const cancelEmployeePenalty =
      '/api/method/jarz_pos.api.monthly_expenses.cancel_employee_penalty';

  // ── Employee Advances ─────────────────────────────────────────────────
  // Cash advances a line manager requests for an employee and a JARZ Manager
  // approves. Approval submits the HRMS Employee Advance AND posts the Payment
  // Entry in one call, so cash leaves the chosen branch account immediately.
  static const getEmployeeAdvanceBootstrap =
      '/api/method/jarz_pos.api.employee_advances.get_employee_advance_bootstrap';
  static const createEmployeeAdvanceRequest =
      '/api/method/jarz_pos.api.employee_advances.create_employee_advance_request';
  static const approveEmployeeAdvance =
      '/api/method/jarz_pos.api.employee_advances.approve_employee_advance';
  static const rejectEmployeeAdvance =
      '/api/method/jarz_pos.api.employee_advances.reject_employee_advance';

  // ── Payment Receipts ──────────────────────────────────────────────────
  static const listPaymentReceipts =
      '/api/method/jarz_pos.api.payment_receipts.list_payment_receipts';
  static const createPaymentReceipt =
      '/api/method/jarz_pos.api.payment_receipts.create_payment_receipt';
  static const uploadReceiptImage =
      '/api/method/jarz_pos.api.payment_receipts.upload_receipt_image';
  static const removeReceiptImage =
      '/api/method/jarz_pos.api.payment_receipts.remove_receipt_image';
  static const confirmReceipt =
      '/api/method/jarz_pos.api.payment_receipts.confirm_receipt';
  static const rejectReceipt =
      '/api/method/jarz_pos.api.payment_receipts.reject_receipt';
  static const getAccessiblePosProfiles =
      '/api/method/jarz_pos.api.payment_receipts.get_accessible_pos_profiles';

  // ── Reports ───────────────────────────────────────────────────────────
  static const getFinalProductsReport =
      '/api/method/jarz_pos.api.reports.get_final_products_report';
  static const getMaterialsReport =
      '/api/method/jarz_pos.api.reports.get_materials_report';
  static const getMasterOrders =
      '/api/method/jarz_pos.api.orders.get_master_orders';

  // ── Reports · Analytics dashboards ────────────────────────────────────
  static const getShippingAnalytics =
      '/api/method/jarz_pos.api.shipping_analytics.get_shipping_analytics';
  static const getInventoryAnalytics =
      '/api/method/jarz_pos.api.inventory_analytics.get_inventory_analytics';
  static const getProductAnalytics =
      '/api/method/jarz_pos.api.product_analytics.get_product_analytics';
  static const getCustomerAnalytics =
      '/api/method/jarz_pos.api.customer_analytics.get_customer_analytics';
  static const getExecutiveOverview =
      '/api/method/jarz_pos.api.executive_analytics.get_executive_overview';
  static const getB2bAnalytics =
      '/api/method/jarz_pos.api.b2b_analytics.get_b2b_analytics';
  static const getProfitAndLoss =
      '/api/method/jarz_pos.api.financial_report.get_profit_and_loss';

  /// Daily revenue dashboard: `date_from` / `date_to` / optional `branch`.
  /// JARZ Manager or Administrator only, like [getProfitAndLoss].
  static const getRevenueDashboard =
      '/api/method/jarz_pos.api.revenue_dashboard.get_revenue_dashboard';

  // ── Reports · Operations (reports overhaul) ───────────────────────────
  // Branch = POS Profile. Every one takes `date_from` / `date_to` and an
  // optional `branch`; daily close, cash over/short and SLA also admit the
  // line-manager tier.
  static const getReportBranches =
      '/api/method/jarz_pos.api.ops_reports.get_report_branches';
  static const getDailyClose =
      '/api/method/jarz_pos.api.ops_reports.get_daily_close';
  static const getCashOverShort =
      '/api/method/jarz_pos.api.ops_reports.get_cash_over_short';
  static const getFulfilmentSla =
      '/api/method/jarz_pos.api.ops_reports.get_fulfilment_sla';

  // ── Reports · Business (reports overhaul) ─────────────────────────────
  static const getUnitEconomics =
      '/api/method/jarz_pos.api.business_reports.get_unit_economics';
  static const getPromoPerformance =
      '/api/method/jarz_pos.api.business_reports.get_promo_performance';
  static const getStockAdjustments =
      '/api/method/jarz_pos.api.business_reports.get_stock_adjustments';
  static const getLabourCost =
      '/api/method/jarz_pos.api.business_reports.get_labour_cost';

  /// Meta Ads report: `level` (campaign | adset | ad), `date_from`, `date_to`,
  /// optional `campaign_id` / `adset_id`, `refresh=1` to bypass the 15-min
  /// server cache. JARZ Manager, Administrator, System Manager or
  /// Meta CAPI Manager.
  static const getAdsReport = '/api/method/jarz_pos.api.meta_ads.get_ads_report';

  // ── Settings ──────────────────────────────────────────────────────────
  static const getReceiptConfig =
      '/api/method/jarz_pos.api.pos.get_receipt_config';

  // ── Sub-territories ───────────────────────────────────────────────────
  static const getSubTerritories =
      '/api/method/jarz_pos.api.territories.get_sub_territories';
  static const setInvoiceSubTerritory =
      '/api/method/jarz_pos.api.territories.set_invoice_sub_territory';

  // ── Delivery Trips ────────────────────────────────────────────────────
  static const createDeliveryTrip =
      '/api/method/jarz_pos.api.trips.create_delivery_trip';
  static const getDeliveryTrips =
      '/api/method/jarz_pos.api.trips.get_delivery_trips';
  static const getTripDetails =
      '/api/method/jarz_pos.api.trips.get_trip_details';
  static const previewTripForDelivery =
      '/api/method/jarz_pos.api.trips.preview_trip_for_delivery';
  static const sendTripForDelivery =
      '/api/method/jarz_pos.api.trips.send_trip_for_delivery';
  static const markTripAsDelivered =
      '/api/method/jarz_pos.api.trips.mark_trip_as_delivered';

  // ── B2B CRM ───────────────────────────────────────────────────────────
  static const getB2bPipeline = '/api/method/jarz_pos.api.crm.get_b2b_pipeline';
  static const getB2bAccount = '/api/method/jarz_pos.api.crm.get_account';
  static const getB2bActiveAccounts =
      '/api/method/jarz_pos.api.crm.get_active_accounts';
  static const b2bAdvanceStage = '/api/method/jarz_pos.api.crm.advance_stage';
  static const b2bCreateLead = '/api/method/jarz_pos.api.crm.create_lead';
  static const b2bLogActivity = '/api/method/jarz_pos.api.crm.log_activity';
  static const getB2bFollowups =
      '/api/method/jarz_pos.api.crm.get_my_followups';
  static const getB2bReorderDue =
      '/api/method/jarz_pos.api.crm.get_reorder_due';
  static const b2bRequestSample = '/api/method/jarz_pos.api.crm.request_sample';
  static const b2bPlaceOrder = '/api/method/jarz_pos.api.crm.place_b2b_order';
  static const b2bSearchLinkableCustomers =
      '/api/method/jarz_pos.api.crm.search_linkable_customers';
  static const b2bLinkExistingCustomer =
      '/api/method/jarz_pos.api.crm.link_existing_customer';
  static const getLeadSources = '/api/method/jarz_pos.api.crm.get_lead_sources';
  static const completeFollowup =
      '/api/method/jarz_pos.api.crm.complete_followup';
  static const getB2bAccountInvoices =
      '/api/method/jarz_pos.api.crm.get_account_invoices';
  static const b2bSearchMergeTargets =
      '/api/method/jarz_pos.api.crm.search_merge_targets';
  static const b2bPreviewMergeAsBranch =
      '/api/method/jarz_pos.api.crm.preview_merge_as_branch';
  static const b2bMergeAsBranch =
      '/api/method/jarz_pos.api.crm.merge_as_branch';
  static const b2bLinkBranch = '/api/method/jarz_pos.api.crm.link_branch';
  static const b2bRenameBranch = '/api/method/jarz_pos.api.crm.rename_branch';

  // ── Pricing (Price Lists) ─────────────────────────────────────────────
  static const getPriceLists =
      '/api/method/jarz_pos.api.price_lists.get_price_lists';
  static const getPriceListDetail =
      '/api/method/jarz_pos.api.price_lists.get_price_list_detail';
  static const getCustomerPricing =
      '/api/method/jarz_pos.api.price_lists.get_customer_pricing';
  static const listPricingCategories =
      '/api/method/jarz_pos.api.price_lists.list_pricing_categories';
  static const searchB2bCustomers =
      '/api/method/jarz_pos.api.price_lists.search_b2b_customers';
  static const createPriceList =
      '/api/method/jarz_pos.api.price_lists.create_price_list';
  static const setCategoryPrice =
      '/api/method/jarz_pos.api.price_lists.set_category_price';
  static const setItemOverride =
      '/api/method/jarz_pos.api.price_lists.set_item_override';
  static const assignCustomerToPriceList =
      '/api/method/jarz_pos.api.price_lists.assign_customer_to_price_list';

  // ── Customer deals (time-limited special prices) ──────────────────────
  static const getCustomerDeals =
      '/api/method/jarz_pos.api.customer_deals.get_customer_deals';
  static const saveCustomerDeal =
      '/api/method/jarz_pos.api.customer_deals.save_customer_deal';
  static const endCustomerDeal =
      '/api/method/jarz_pos.api.customer_deals.end_customer_deal';

  // ── Leads (B2B prospect research) ─────────────────────────────────────
  static const getLeads = '/api/method/jarz_pos.api.leads.get_leads';
  static const getLead = '/api/method/jarz_pos.api.leads.get_lead';
  static const saveLead = '/api/method/jarz_pos.api.leads.save_lead';
  static const previewLeadMapsLink =
      '/api/method/jarz_pos.api.leads.preview_maps_link';
  static const saveLeadContacts =
      '/api/method/jarz_pos.api.leads.save_lead_contacts';
  static const setLeadAddress =
      '/api/method/jarz_pos.api.leads.set_lead_address';
  static const getLeadCategories =
      '/api/method/jarz_pos.api.leads.get_lead_categories';
  static const saveLeadCategory =
      '/api/method/jarz_pos.api.leads.save_lead_category';
  static const getNotSuitableReasons =
      '/api/method/jarz_pos.api.leads.get_not_suitable_reasons';
  static const setLeadSuitability =
      '/api/method/jarz_pos.api.leads.set_lead_suitability';
  static const getMergeCandidates =
      '/api/method/jarz_pos.api.leads.get_merge_candidates';
  static const mergeLeads = '/api/method/jarz_pos.api.leads.merge_leads';

  // ── Journey notes (the rep's dated field diary) ───────────────────────
  // Shared by the leads catalog and the B2B pipeline: the same note timeline
  // hangs off a Lead, an Opportunity or a Customer.
  static const getJourneyNotes =
      '/api/method/jarz_pos.api.journey.get_journey_notes';
  static const addJourneyNote =
      '/api/method/jarz_pos.api.journey.add_journey_note';
  static const updateJourneyNote =
      '/api/method/jarz_pos.api.journey.update_journey_note';
  static const deleteJourneyNote =
      '/api/method/jarz_pos.api.journey.delete_journey_note';
  static const getJourneyOptions =
      '/api/method/jarz_pos.api.journey.get_journey_options';
  // The people already recorded on the account, so the editor's "who I spoke
  // to" box is a pick, not a retype. Both read and write land on the SAME
  // roster the lead page's contacts section edits.
  static const getJourneyContacts =
      '/api/method/jarz_pos.api.journey.get_journey_contacts';
  static const addJourneyContact =
      '/api/method/jarz_pos.api.journey.add_journey_contact';
  // Closing the loop on a promise, and the calendar of everything still open.
  // A next action with no done state keeps tinting cards and keeps its
  // reminder nagging long after the rep actually made the call.
  static const setJourneyActionDone =
      '/api/method/jarz_pos.api.journey.set_journey_action_done';
  static const getJourneyActionCalendar =
      '/api/method/jarz_pos.api.journey.get_action_calendar';

  // ── Sales material sharing ────────────────────────────────────────────
  // The price list a rep sends on WhatsApp after a visit. The app never sees
  // the files: it picks a pack, the backend mints one public link, and the
  // customer opens a page built for reading a price list on a phone.
  static const getSalesMaterials =
      '/api/method/jarz_pos.api.materials.get_sales_materials';
  static const createMaterialShare =
      '/api/method/jarz_pos.api.materials.create_material_share';
  static const getMaterialShares =
      '/api/method/jarz_pos.api.materials.get_material_shares';

  // ── B2B visit planning ────────────────────────────────────────────────
  // A day's field route: which doors, in what order. The catalog answers "who
  // is worth visiting"; these answer "and when am I actually going".
  static const getVisitPlans =
      '/api/method/jarz_pos.api.visits.get_visit_plans';
  static const getVisitPlan = '/api/method/jarz_pos.api.visits.get_visit_plan';
  static const createVisitPlan =
      '/api/method/jarz_pos.api.visits.create_visit_plan';
  static const updateVisitPlan =
      '/api/method/jarz_pos.api.visits.update_visit_plan';
  static const deleteVisitPlan =
      '/api/method/jarz_pos.api.visits.delete_visit_plan';
  static const setVisitStops =
      '/api/method/jarz_pos.api.visits.set_visit_stops';
  static const addVisitStops =
      '/api/method/jarz_pos.api.visits.add_stops_to_plan';
  static const optimizeVisitPlan =
      '/api/method/jarz_pos.api.visits.optimize_visit_plan';
  static const setVisitStopStatus =
      '/api/method/jarz_pos.api.visits.set_visit_stop_status';
  static const getVisitTargets =
      '/api/method/jarz_pos.api.visits.get_visit_targets';
  static const suggestVisitPlan =
      '/api/method/jarz_pos.api.visits.suggest_visit_plan';
  // Tells the UI whether distances are real road distances or straight-line
  // estimates — and, when they are estimates, whether that is configuration or
  // a failure. Identical symptoms, different fixes.
  static const getRouteEngineStatus =
      '/api/method/jarz_pos.api.visits.get_route_engine_status';
  // Adding a door to a day from wherever the rep already is — the kanban card,
  // the leads list, the map callout, the lead page. Resolves one record to its
  // routable doors so no screen needs to know how doors are stored.
  static const getRecordVisitTargets =
      '/api/method/jarz_pos.api.visits.get_record_visit_targets';
  static const getAddableVisitPlans =
      '/api/method/jarz_pos.api.visits.get_addable_visit_plans';
  // Orders and costs a stop list without saving, so the builder can show the
  // real route while the rep is still choosing.
  static const previewVisitRoute =
      '/api/method/jarz_pos.api.visits.preview_visit_route';

  // ── Courier tracking (jarz_courier app) ───────────────────────────────
  // Supervisor-only and Redis-backed, so it is safe to poll. Couriers are
  // deliberately excluded server-side: a courier may see their own run, never
  // a colleague's live position.
  static const getLiveCourierPositions =
      '/api/method/jarz_courier.api.tracking.get_live_positions';

  // ── Customer tracking link + order timeline (courier launch) ─────────
  // Staff share the customer's public tracking link (and delivery code) from
  // the order; supervisors read the per-order timeline. The timeline lives in
  // jarz_courier and answers 404 where that app is not installed.
  static const getTrackingLink =
      '/api/method/jarz_pos.api.tracking.get_tracking_link';
  static const getOrderTimeline =
      '/api/method/jarz_courier.api.timeline.get_order_timeline';

  // ── Courier alerts + setup (jarz_courier app) ─────────────────────────
  // Alerts are for the courier-map tier; onboarding is for the same door as
  // user management. Both answer 404 when jarz_courier is not installed.
  static const courierListAlerts =
      '/api/method/jarz_courier.api.alerts.list_alerts';
  static const courierAcknowledgeAlert =
      '/api/method/jarz_courier.api.alerts.acknowledge_alert';
  static const courierAlertCounts =
      '/api/method/jarz_courier.api.alerts.get_alert_counts';
  static const courierListCandidates =
      '/api/method/jarz_courier.api.onboarding.list_courier_candidates';
  static const courierSetup =
      '/api/method/jarz_courier.api.onboarding.setup_courier';
  static const courierResetPin =
      '/api/method/jarz_courier.api.onboarding.reset_courier_pin';
  static const courierGetSetup =
      '/api/method/jarz_courier.api.onboarding.get_courier_setup';

  // ── B2B customer labels ───────────────────────────────────────────────
  // Printed-label stock per B2B customer: how many are left, how fast they are
  // going, and when a batch has to go to the print house to land before they
  // run out. Gated server-side on B2B or manager access.
  static const getLabelDashboard =
      '/api/method/jarz_pos.api.labels.get_label_dashboard';
  static const getLabelAlertCount =
      '/api/method/jarz_pos.api.labels.get_label_alert_count';
  static const getLabelDetail =
      '/api/method/jarz_pos.api.labels.get_label_detail';
  static const searchLabelCustomers =
      '/api/method/jarz_pos.api.labels.search_label_customers';
  static const getLabelFlavourOptions =
      '/api/method/jarz_pos.api.labels.get_flavour_options';
  static const getLabelStorageLocations =
      '/api/method/jarz_pos.api.labels.get_storage_locations';
  static const getLabelPrintSuppliers =
      '/api/method/jarz_pos.api.labels.get_print_suppliers';
  static const setupCustomerLabels =
      '/api/method/jarz_pos.api.labels.setup_customer_labels';
  static const createLabel = '/api/method/jarz_pos.api.labels.create_label';
  static const updateLabel = '/api/method/jarz_pos.api.labels.update_label';
  static const recordLabelMovement =
      '/api/method/jarz_pos.api.labels.record_movement';
  static const recordLabelCount =
      '/api/method/jarz_pos.api.labels.record_count';
  static const createLabelPrintOrder =
      '/api/method/jarz_pos.api.labels.create_print_order';
  static const updateLabelPrintOrder =
      '/api/method/jarz_pos.api.labels.update_print_order';
  static const billLabelPrintOrder =
      '/api/method/jarz_pos.api.labels.bill_print_order';
  // One step for a batch already bought AND delivered: print order + receipt
  // + supplier bill. Manager-only; idempotent on client_request_id.
  static const recordLabelBoughtBatch =
      '/api/method/jarz_pos.api.labels.record_bought_batch';

  // ── Custom Shipping ───────────────────────────────────────────────────
  static const requestCustomShipping =
      '/api/method/jarz_pos.api.custom_shipping.request_custom_shipping';
  static const approveCustomShipping =
      '/api/method/jarz_pos.api.custom_shipping.approve_custom_shipping';
  static const rejectCustomShipping =
      '/api/method/jarz_pos.api.custom_shipping.reject_custom_shipping';
  static const getPendingCustomShippingRequests =
      '/api/method/jarz_pos.api.custom_shipping.get_pending_custom_shipping_requests';

  // ── Shift distribution (roster) ───────────────────────────────────────
  // Writes HRMS Shift Assignments, which is the same record the geofenced
  // check-in reads — so emptying a day here stops that person clocking in.
  static const rosterBootstrap =
      '/api/method/jarz_pos.api.roster.get_bootstrap';
  static const rosterMonth = '/api/method/jarz_pos.api.roster.get_month';
  static const rosterMonthHours =
      '/api/method/jarz_pos.api.roster.get_month_hours';
  static const rosterAssignShift =
      '/api/method/jarz_pos.api.roster.assign_shift';
  static const rosterSetDayOff = '/api/method/jarz_pos.api.roster.set_day_off';
  static const rosterClearDayOff =
      '/api/method/jarz_pos.api.roster.clear_day_off';
  // Applies many single-day changes in one request. Building a month one cell
  // at a time is one round trip per cell; this is the whole month in one.
  static const rosterBulkAssign = '/api/method/jarz_pos.api.roster.bulk_assign';
  // Rota plan wizard: pre-fill for "who works what", then preview/apply the
  // whole period plus the standing (HRMS Shift Schedule) rota.
  static const rosterPlanDefaults =
      '/api/method/jarz_pos.api.roster.get_plan_defaults';
  static const rosterApplyPlan = '/api/method/jarz_pos.api.roster.apply_plan';
  // "Repeat every <weekday>": one person's single-day edit made their
  // standing week from that day on. Previews by default (dry_run=1).
  static const rosterApplyWeeklyChange =
      '/api/method/jarz_pos.api.roster.apply_weekly_change';

  // ── Branch access (POS Profile membership + one-day access) ──────────
  // Edits `POS Profile.applicable_for_users`. The server refuses any change
  // while the branch has an open shift, and logs every change it makes.
  static const branchAccessOverview =
      '/api/method/jarz_pos.api.branch_access.get_branch_access';
  static const branchAccessSet =
      '/api/method/jarz_pos.api.branch_access.set_branch_access';
  static const branchAccessGrantDay =
      '/api/method/jarz_pos.api.branch_access.grant_day_access';
  static const branchAccessCancelDay =
      '/api/method/jarz_pos.api.branch_access.cancel_day_access';
  static const branchAccessLog =
      '/api/method/jarz_pos.api.branch_access.get_access_log';
  // Permanent move: access to the new branch, old one removed, and the
  // standing schedule + future shifts moved to the new branch's location.
  static const branchAccessMoveBranch =
      '/api/method/jarz_pos.api.branch_access.move_branch';

  // ── Delivery partner settlement (the weekly bank transfer) ────────────
  // A delivery partner is a courier COMPANY. Its per-trip fees accrued at
  // dispatch; this clears the payable. Settling takes an explicit trip list
  // because the partner's own invoice does not always agree with ours, and
  // extra charges (subscription, waiting time) never accrued per order.
  static const deliveryPartnerBalances =
      '/api/method/jarz_pos.api.delivery_partners.get_delivery_partner_balances';
  static const deliveryPartnerUnsettledDetails =
      '/api/method/jarz_pos.api.delivery_partners.get_delivery_partner_unsettled_details';
  static const deliveryPartnerSettle =
      '/api/method/jarz_pos.api.delivery_partners.settle_delivery_partner';

  // ── Sales partner commission settlement ───────────────────────────────
  // Posts the batch commission + VAT recognition journal entry.
  static const salesPartnerBalances =
      '/api/method/jarz_pos.api.sales_partners.get_sales_partner_balances';
  static const salesPartnerSettle =
      '/api/method/jarz_pos.api.sales_partners.settle_sales_partner';

  // ── Address pin correction ────────────────────────────────────────────
  // preview_maps_link only helps while an address is being created. These
  // three are how a wrong pin on an EXISTING address gets fixed in the field.
  static const getAddressPin = '/api/method/jarz_pos.api.geo.get_address_pin';
  static const setAddressPin = '/api/method/jarz_pos.api.geo.set_address_pin';
  static const dryRunAddressPin =
      '/api/method/jarz_pos.api.geo.dry_run_address_pin';

  // ── Forecasting (velocity + reorder alerts) ───────────────────────────
  // A weekly job already computes velocity; these read what it produced.
  static const forecastAlertSummary =
      '/api/method/jarz_pos.api.forecasting.get_alert_summary';
  static const forecastItemVelocity =
      '/api/method/jarz_pos.api.forecasting.get_item_velocity';
  static const forecastRunVelocityNow =
      '/api/method/jarz_pos.api.forecasting.run_velocity_update_now';

  // ── Customer segmentation (RFM) ───────────────────────────────────────
  // A nightly job recalculates these; the output was Desk-only until now.
  static const segmentSummary =
      '/api/method/jarz_pos.api.segmentation.get_segment_summary';
  static const segmentExport =
      '/api/method/jarz_pos.api.segmentation.export_segment';
  static const segmentSetOverride =
      '/api/method/jarz_pos.api.segmentation.set_segment_override';
  static const segmentRunNow =
      '/api/method/jarz_pos.api.segmentation.run_segmentation_now';

  // ── Customer follow-ups (reorder plan touches) ────────────────────────
  static const followupsToday =
      '/api/method/jarz_pos.api.customer_followups.get_followups_today';
  static const followupLogTouch =
      '/api/method/jarz_pos.api.customer_followups.log_touch';
  static const followupSkipTouch =
      '/api/method/jarz_pos.api.customer_followups.skip_touch';
  static const followupDraftMessage =
      '/api/method/jarz_pos.api.customer_followups.draft_followup_message';
  static const followupCallBrief =
      '/api/method/jarz_pos.api.customer_followups.get_call_brief';
  static const followupStats =
      '/api/method/jarz_pos.api.customer_followups.get_followup_stats';
  static const followupSentReport =
      '/api/method/jarz_pos.api.customer_followups.get_sent_report';

  // ── Warehouse alignment watchlist (read-only) ─────────────────────────
  // Submitted invoices whose item warehouses disagree with their branch —
  // the drift that is upstream of the recurring negative-bin recounts.
  // The REPAIR endpoint is deliberately not exposed here.
  static const warehouseAlignmentReport =
      '/api/method/jarz_pos.api.manager.get_invoice_warehouse_alignment_report';

  // ── Unconfirmed online payment escalations ────────────────────────────
  // The hourly job flags unpaid InstaPay/wallet orders sitting Out For
  // Delivery past the configured threshold and writes a Notification Log
  // nobody reads. This reads the same set, against the same threshold.
  static const unconfirmedPaymentEscalations =
      '/api/method/jarz_pos.api.escalations.list_unconfirmed_online_payment_escalations';

  // ── WooCommerce sync operations ───────────────────────────────────────
  // These belong to the SEPARATE jarz_woocommerce_integration app. Calling
  // them over HTTP is fine — domain isolation forbids Python cross-imports
  // between the two apps, not network calls from the client.
  //
  // All of these require the `WooCommerce Sync Operator` role (or System
  // Manager). Deliberately NOT exposed here, and must never be: run_dedupe,
  // start_historical_migration, ensure_order_webhooks and test_connection —
  // they are System-Manager-only because they merge customer records,
  // rewrite live store webhooks, or make server-side calls to a caller
  // supplied URL.
  static const wooSyncDashboard =
      '/api/method/jarz_woocommerce_integration.api.sync_events.get_dashboard';
  static const wooSyncEvents =
      '/api/method/jarz_woocommerce_integration.api.sync_events.get_events';
  static const wooSyncRetryEvent =
      '/api/method/jarz_woocommerce_integration.api.sync_events.retry_event';
  static const wooSyncRetryEvents =
      '/api/method/jarz_woocommerce_integration.api.sync_events.retry_events';
  static const wooSyncProcessNow =
      '/api/method/jarz_woocommerce_integration.api.sync_events.process_event_now';
  static const wooSyncSetReviewState =
      '/api/method/jarz_woocommerce_integration.api.sync_events.set_review_state';
  static const wooSyncSetReviewStateBulk =
      '/api/method/jarz_woocommerce_integration.api.sync_events.set_review_state_bulk';
  static const wooSyncRunWorker =
      '/api/method/jarz_woocommerce_integration.api.sync_events.run_worker';
  static const wooSyncClearBreaker =
      '/api/method/jarz_woocommerce_integration.api.sync_events.clear_outbound_breaker';
  static const wooPushSalesInvoice =
      '/api/method/jarz_woocommerce_integration.api.manual_sync.push_sales_invoice';

  // Read-only: the duplicate groups the dedupe tool REFUSES to auto-merge,
  // for a human to decide on. The merge itself stays System-Manager-only and
  // is not callable from the app.
  static const wooDuplicateReview =
      '/api/method/jarz_woocommerce_integration.services.customer_dedupe.review_report';

  // ── Reversing a courier settlement ────────────────────────────────────
  // Until now every reversal was a hand-written script piped into a
  // production bench console. The reversal posts an OPPOSITE journal entry
  // and reopens the Courier Transactions — the original settlement entry is
  // never cancelled, so both it and its correction stay in the audit trail.
  //
  // Preview mints a 3-minute token that commit must present, the same
  // pattern as generate_settlement_preview / confirm_settlement.
  // How a manager FINDS the settlement to reverse. Nothing else in the app
  // surfaces a Journal Entry name: get_courier_balances only describes
  // UNSETTLED positions, and every settle call site discards the
  // `journal_entry` its own response carries. Branch-scoped server-side.
  static const recentSettlements =
      '/api/method/jarz_pos.api.couriers.list_recent_settlements';
  static const unsettlePreview =
      '/api/method/jarz_pos.api.couriers.get_unsettle_preview';
  static const unsettleCommit =
      '/api/method/jarz_pos.api.couriers.unsettle_courier_settlement';

  // ── Attendance ────────────────────────────────────────────────────────
  // Read-only. Attendance is DERIVED server-side from Employee Checkin +
  // Shift Assignment + Day Off — the Attendance DocType is not produced on
  // these sites — so there is no write endpoint to add later.
  static const attendanceBootstrap =
      '/api/method/jarz_pos.api.attendance.get_bootstrap';
  static const attendanceMonth =
      '/api/method/jarz_pos.api.attendance.get_month';
  static const attendanceDay = '/api/method/jarz_pos.api.attendance.get_day';
  static const attendanceEmployee =
      '/api/method/jarz_pos.api.attendance.get_employee';
  static const attendanceSummary =
      '/api/method/jarz_pos.api.attendance.get_summary';

  /// Trust the phone behind a "New Device" check-in (POST employee, date).
  static const attendanceApproveDevice =
      '/api/method/jarz_pos.api.attendance.approve_device';

  // ── Task Board ────────────────────────────────────────────────────────
  // The line-manager tier's task cards. Every mutation answers with the
  // whole `get_task` shape, so the detail screen never re-fetches after one.
  static const _tasks = '/api/method/jarz_pos.api.tasks';
  static const tasksBoardContext = '$_tasks.get_board_context';
  static const tasksBoard = '$_tasks.get_board';
  static const tasksGetTask = '$_tasks.get_task';
  static const tasksCreateTask = '$_tasks.create_task';
  static const tasksUpdateTask = '$_tasks.update_task';
  static const tasksSetStatus = '$_tasks.set_status';
  static const tasksAddSubtask = '$_tasks.add_subtask';
  static const tasksUpdateSubtask = '$_tasks.update_subtask';
  static const tasksDeleteSubtask = '$_tasks.delete_subtask';
  static const tasksSetSubtaskDone = '$_tasks.set_subtask_done';
  static const tasksAddEntry = '$_tasks.add_entry';
  static const tasksUploadAttachment = '$_tasks.upload_attachment';
  static const tasksRemoveAttachment = '$_tasks.remove_attachment';
  static const tasksDownloadAttachment = '$_tasks.download_attachment';
  static const tasksArchiveTask = '$_tasks.archive_task';
  static const tasksOverview = '$_tasks.get_overview';
  static const tasksCounts = '$_tasks.get_task_counts';

  // ── User management (manager tier) ────────────────────────────────────
  // ERPNext User accounts: create, edit role profiles, disable, reset a
  // password. The server gates every call on JARZ Manager / System Manager and
  // refuses to touch System Manager accounts for anyone below that.
  static const _userAdmin = '/api/method/jarz_pos.api.user_admin';
  static const userAdminContext = '$_userAdmin.get_context';
  static const userAdminListUsers = '$_userAdmin.list_users';
  static const userAdminGetUser = '$_userAdmin.get_user';
  static const userAdminListEmployees = '$_userAdmin.list_employees';
  static const userAdminCreateUser = '$_userAdmin.create_user';
  static const userAdminUpdateUser = '$_userAdmin.update_user';
  static const userAdminSetEnabled = '$_userAdmin.set_enabled';
  static const userAdminResetPassword = '$_userAdmin.reset_password';
  static const userAdminDeleteUser = '$_userAdmin.delete_user';

  // ── Chat inbox (moderator reply copilot) ──────────────────────────────
  // WhatsApp / Instagram / Messenger conversations with an AI-drafted reply
  // the moderator sends as-is, edits, rejects or regenerates. GETs take query
  // parameters; everything that writes is a POST. None of these may be
  // replayed offline (see kOfflineReplayExcludedPrefixes).
  static const _chat = '/api/method/jarz_pos.api.chat';
  static const chatGetConversations = '$_chat.get_conversations';
  static const chatGetConversation = '$_chat.get_conversation';
  static const chatSendMessage = '$_chat.send_message';
  static const chatSendDraft = '$_chat.send_draft';
  static const chatRejectDraft = '$_chat.reject_draft';
  static const chatRegenerateDraft = '$_chat.regenerate_draft';
  static const chatAssignConversation = '$_chat.assign_conversation';
  static const chatSetConversationStatus = '$_chat.set_conversation_status';
  static const chatLinkCustomer = '$_chat.link_customer';
  static const chatGetOrderPrefill = '$_chat.get_order_prefill';
  static const chatGetMetrics = '$_chat.get_chat_metrics';
  static const chatGetUnreadTotal = '$_chat.get_unread_total';
}
