// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Jarz POS';

  @override
  String get drawerHeaderTitle => 'Jarz POS';

  @override
  String get drawerHeaderSubtitle => 'Mobile Point of Sale';

  @override
  String get menuB2bMode => 'B2B Mode';

  @override
  String get drawerGroupPosSales => 'Sales & Orders';

  @override
  String get drawerGroupCrm => 'B2B & Pricing';

  @override
  String get drawerGroupDelivery => 'Delivery & Couriers';

  @override
  String get drawerGroupFinance => 'Finance & Expenses';

  @override
  String get drawerGroupPurchasing => 'Stock & Purchasing';

  @override
  String get drawerGroupManagement => 'Dashboards & Reports';

  @override
  String get drawerGroupProduction => 'Production';

  @override
  String get drawerGroupTeam => 'Team & Shifts';

  @override
  String get menuPriceLists => 'Price Lists';

  @override
  String get menuPointOfSale => 'Point of Sale';

  @override
  String get menuSalesKanban => 'Sales Kanban';

  @override
  String get menuExpenses => 'Expenses';

  @override
  String get escalationSectionTitle => 'Escalated — Unconfirmed Past Threshold';

  @override
  String get escalationBadge => 'ESCALATED';

  @override
  String escalationThresholdBreached(int hours) {
    return 'Breached ${hours}h threshold';
  }

  @override
  String escalationOutForDeliveryDuration(Object duration) {
    return 'Out for delivery for $duration';
  }

  @override
  String get escalationBranchLabel => 'Branch';

  @override
  String get escalationAlreadyNotified => 'Manager already notified';

  @override
  String get escalationNotYetNotified => 'Not yet notified';

  @override
  String get escalationLoadFailed => 'Couldn\'t load escalations';

  @override
  String get warehouseAlignTitle => 'Warehouse Alignment';

  @override
  String get warehouseAlignSubtitle =>
      'Invoices whose stock left the wrong branch';

  @override
  String get warehouseAlignWatchlistBanner =>
      'Read-only watchlist — fix mismatches in Desk, no repair action here';

  @override
  String get warehouseAlignEmpty => 'No warehouse mismatches found';

  @override
  String get warehouseAlignExpectedLabel => 'Expected';

  @override
  String get warehouseAlignActualLabel => 'Actual';

  @override
  String get warehouseAlignBranchFilterLabel => 'Branch';

  @override
  String get warehouseAlignBranchFilterAll => 'All branches';

  @override
  String get menuCourierBalances => 'Courier Balances';

  @override
  String get menuManagerDashboard => 'Manager Dashboard';

  @override
  String get managerMenuTooltip => 'Menu';

  @override
  String get managerDashboardTitle => 'Manager Dashboard';

  @override
  String get managerRecentOrders => 'Recent Orders';

  @override
  String get managerOrdersChannelAll => 'All';

  @override
  String get managerOrdersChannelB2c => 'B2C';

  @override
  String get managerOrdersChannelB2b => 'B2B';

  @override
  String get managerNoRecentOrders => 'No recent orders';

  @override
  String get managerBranchBalances => 'Branch Balances';

  @override
  String get managerSwitchProfileTip =>
      'Tip: Switch POS profiles from the POS/Kanban headers.';

  @override
  String get managerSwitchProfile => 'Switch Profile';

  @override
  String get managerTotalCash => 'Total Cash';

  @override
  String get managerAll => 'All';

  @override
  String get managerFilterByState => 'Filter by state:';

  @override
  String get managerChangeBranch => 'Change Branch';

  @override
  String get managerAssignToBranch => 'Assign to Branch';

  @override
  String get managerBranchUpdated => 'Branch updated';

  @override
  String managerBranchUpdateFailed(Object error) {
    return 'Failed: $error';
  }

  @override
  String get menuPurchaseInvoice => 'Purchase Invoice';

  @override
  String get menuAbout => 'About';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutAppSection => 'App';

  @override
  String get aboutReleaseSection => 'Release';

  @override
  String get aboutShorebirdSection => 'Shorebird';

  @override
  String get aboutAppName => 'App name';

  @override
  String get aboutPackageName => 'Package name';

  @override
  String get aboutPlatform => 'Platform';

  @override
  String get aboutEnvironment => 'Environment';

  @override
  String get aboutBuildName => 'Build name';

  @override
  String get aboutBuildNumber => 'Build number';

  @override
  String get aboutReleaseId => 'Release ID';

  @override
  String get aboutReleaseDist => 'Release dist';

  @override
  String get aboutPatchNumber => 'Patch number';

  @override
  String get aboutPatchStatus => 'Patch status';

  @override
  String get aboutLastChecked => 'Last checked';

  @override
  String get aboutNotAvailable => 'Not available';

  @override
  String get aboutPatchNotInstalled => 'Base release only';

  @override
  String get aboutPatchUnavailable => 'Unavailable on this platform';

  @override
  String get aboutPatchStatusUpToDate => 'Up to date';

  @override
  String get aboutPatchStatusUpdateAvailable => 'Update available';

  @override
  String get aboutPatchStatusRestartRequired => 'Restart required';

  @override
  String get aboutPatchStatusUnavailable => 'Unavailable';

  @override
  String get aboutPatchStatusUnknown => 'Unknown';

  @override
  String get aboutPatchStatusUnknownDetail => 'Patch check error';

  @override
  String get aboutRefresh => 'Refresh';

  @override
  String get aboutCopyDiagnostics => 'Copy diagnostics';

  @override
  String get aboutCopiedDiagnostics => 'Diagnostics copied';

  @override
  String get aboutRetry => 'Retry';

  @override
  String aboutError(Object error) {
    return 'Error: $error';
  }

  @override
  String get menuManufacturing => 'Manufacturing';

  @override
  String get menuStockTransfer => 'Stock Transfer';

  @override
  String get wooSyncMenuTitle => 'WooCommerce Sync';

  @override
  String get wooSyncNotPermittedTitle => 'Not permitted';

  @override
  String get wooSyncNotPermittedBody =>
      'WooCommerce Sync Operator access is required to open this screen.';

  @override
  String get wooSyncRefresh => 'Refresh';

  @override
  String get wooSyncBreakerOpenTitle => 'Outbound sync paused';

  @override
  String get wooSyncBreakerOpenBody =>
      'The circuit breaker tripped after repeated failures pushing to WooCommerce. Every outbound push is paused until it clears.';

  @override
  String wooSyncBreakerOpenUntil(Object time) {
    return 'Paused until $time';
  }

  @override
  String wooSyncBreakerFailureCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recent failures',
      one: '1 recent failure',
    );
    return '$_temp0';
  }

  @override
  String get wooSyncBreakerClosedTitle => 'Outbound sync healthy';

  @override
  String get wooSyncBreakerClosedBody =>
      'The outbound circuit breaker is closed. Pushes to WooCommerce are flowing normally.';

  @override
  String get wooSyncBacklogTitle => 'Backlog';

  @override
  String get wooSyncBacklogPending => 'Pending';

  @override
  String get wooSyncBacklogRetryScheduled => 'Retry scheduled';

  @override
  String get wooSyncBacklogProcessing => 'Processing';

  @override
  String get wooSyncBacklogNeedsAttention => 'Needs attention';

  @override
  String get wooSyncBacklogDueNow => 'Due now';

  @override
  String wooSyncBacklogOldestDue(Object time) {
    return 'Oldest due $time';
  }

  @override
  String get wooSyncBacklogExpiredProcessing => 'Stuck processing';

  @override
  String get wooSyncSearchHint =>
      'Search event id, source id, invoice, reason...';

  @override
  String get wooSyncFilterAttentionOnly => 'Needs attention';

  @override
  String get wooSyncFilterAllEvents => 'All events';

  @override
  String get wooSyncFilterStatusLabel => 'Status';

  @override
  String get wooSyncFilterDirectionLabel => 'Direction';

  @override
  String get wooSyncFilterReviewStateLabel => 'Review state';

  @override
  String get wooSyncFilterAny => 'Any';

  @override
  String get wooSyncClearFilters => 'Clear filters';

  @override
  String get wooSyncEventsEmpty => 'No sync events match these filters.';

  @override
  String wooSyncEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events',
      one: '1 event',
    );
    return '$_temp0';
  }

  @override
  String get wooSyncEventRetry => 'Retry';

  @override
  String get wooSyncEventProcessNow => 'Process now';

  @override
  String get wooSyncEventSetReviewState => 'Review state';

  @override
  String get wooSyncEventPushInvoice => 'Push to WooCommerce';

  @override
  String wooSyncEventLocalInvoiceLabel(Object name) {
    return 'Invoice $name';
  }

  @override
  String wooSyncEventAttempt(Object count, Object max) {
    return 'Attempt $count of $max';
  }

  @override
  String wooSyncEventLastError(Object error) {
    return 'Last error: $error';
  }

  @override
  String wooSyncEventReviewReason(Object reason) {
    return 'Review: $reason';
  }

  @override
  String get wooSyncSelectAll => 'Select all';

  @override
  String get wooSyncClearSelection => 'Clear selection';

  @override
  String wooSyncSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get wooSyncBulkRetry => 'Retry selected';

  @override
  String get wooSyncBulkSetReviewState => 'Set review state';

  @override
  String wooSyncBulkLimitExceeded(int limit, int count) {
    return 'Bulk actions are limited to $limit events at a time; $count are selected. Narrow the selection and try again.';
  }

  @override
  String get wooSyncRunWorker => 'Run worker now';

  @override
  String get wooSyncRunWorkerConfirmTitle => 'Run the sync worker now?';

  @override
  String get wooSyncRunWorkerConfirmBody =>
      'This immediately processes every sync event that is due across the whole store, not only what is shown here.';

  @override
  String get wooSyncClearBreaker => 'Clear outbound breaker';

  @override
  String get wooSyncClearBreakerConfirmTitle =>
      'Clear the outbound circuit breaker?';

  @override
  String get wooSyncClearBreakerConfirmBody =>
      'This resumes every paused outbound push immediately. Only do this once the WooCommerce outage that tripped it is confirmed resolved.';

  @override
  String get wooSyncConfirm => 'Confirm';

  @override
  String get wooSyncCancel => 'Cancel';

  @override
  String wooSyncRetryQueued(Object name) {
    return 'Retry queued for $name';
  }

  @override
  String wooSyncProcessedNow(Object name) {
    return 'Processed $name';
  }

  @override
  String get wooSyncReviewStateSaved => 'Review state updated';

  @override
  String wooSyncBulkRetryDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Retried $count events',
      one: 'Retried 1 event',
    );
    return '$_temp0';
  }

  @override
  String wooSyncBulkReviewStateDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Updated $count events',
      one: 'Updated 1 event',
    );
    return '$_temp0';
  }

  @override
  String get wooSyncWorkerRunDone => 'Worker run complete';

  @override
  String wooSyncBreakerCleared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Breaker cleared, $count events released',
      one: 'Breaker cleared, 1 event released',
      zero: 'Breaker cleared',
    );
    return '$_temp0';
  }

  @override
  String wooSyncInvoicePushed(Object name) {
    return 'Pushed $name to WooCommerce';
  }

  @override
  String get wooSyncReviewStateDialogTitle => 'Set review state';

  @override
  String get wooSyncReviewStateNotesLabel => 'Notes (optional)';

  @override
  String get wooSyncStatusPending => 'Pending';

  @override
  String get wooSyncStatusProcessing => 'Processing';

  @override
  String get wooSyncStatusSucceeded => 'Succeeded';

  @override
  String get wooSyncStatusRetryScheduled => 'Retry scheduled';

  @override
  String get wooSyncStatusSkipped => 'Skipped';

  @override
  String get wooSyncStatusSuperseded => 'Superseded';

  @override
  String get wooSyncStatusFailed => 'Failed';

  @override
  String get wooSyncStatusNeedsReview => 'Needs review';

  @override
  String get wooSyncStatusDeadLetter => 'Dead letter';

  @override
  String get wooSyncDirectionInbound => 'Inbound';

  @override
  String get wooSyncDirectionOutbound => 'Outbound';

  @override
  String get wooSyncReviewStateOpen => 'Open';

  @override
  String get wooSyncReviewStateInvestigating => 'Investigating';

  @override
  String get wooSyncReviewStateResolved => 'Resolved';

  @override
  String get wooSyncReviewStateIgnored => 'Ignored';

  @override
  String get wooDuplicatesMenuTitle => 'Duplicate Customers';

  @override
  String get wooDuplicatesIntro =>
      'These phone numbers match more than one customer, but nothing here was clear enough to merge automatically.';

  @override
  String get wooDuplicatesReadOnlyBanner =>
      'Read-only triage. Merging duplicate customers is administrator-only and is done in Desk, not here.';

  @override
  String get wooDuplicatesEmpty =>
      'No duplicate customer groups need review right now.';

  @override
  String wooDuplicatesGroupSize(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count customers',
      one: '1 customer',
    );
    return '$_temp0';
  }

  @override
  String wooDuplicatesGroupReason(Object reason) {
    return 'Why not auto-merged: $reason';
  }

  @override
  String wooDuplicatesCandidateInvoices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices',
      one: '1 invoice',
    );
    return '$_temp0';
  }

  @override
  String wooDuplicatesCandidateSubmitted(int count) {
    return '$count submitted';
  }

  @override
  String wooDuplicatesCandidateRevenue(Object amount) {
    return 'Revenue $amount';
  }

  @override
  String wooDuplicatesCandidateCreated(Object date) {
    return 'Created $date';
  }

  @override
  String get wooDuplicatesCandidateDisabled => 'Disabled';

  @override
  String get wooDuplicatesCandidateActive => 'Active';

  @override
  String wooDuplicatesCandidateWooId(Object id) {
    return 'Woo ID $id';
  }

  @override
  String get wooDuplicatesCandidateNoWooId => 'No WooCommerce ID';

  @override
  String get menuCashTransfer => 'Cash Transfer';

  @override
  String get unsettleAlreadyReversedLabel => 'Already reversed';

  @override
  String unsettleReversalEntryLabel(String entry) {
    return 'Reversed by $entry';
  }

  @override
  String get unsettleEntryPointTooltip => 'Reverse a settlement';

  @override
  String get unsettleHistoryTitle => 'Reverse a Settlement';

  @override
  String get unsettleHistorySearchHint =>
      'Search by courier, party or Journal Entry';

  @override
  String get unsettleHistoryEmpty => 'No settlements found for this branch.';

  @override
  String unsettleRecordJournalEntry(Object entry) {
    return 'Journal Entry: $entry';
  }

  @override
  String unsettleRecordInvoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get unsettleModeCollect => 'Collected from courier';

  @override
  String get unsettleModePay => 'Paid to courier';

  @override
  String get unsettleModeBulk => 'Settle all';

  @override
  String get unsettleModeSettleNow => 'Settled now';

  @override
  String get unsettleModeSettleLater => 'Settled later';

  @override
  String get unsettleModeGeneric => 'Settlement';

  @override
  String get unsettleDialogTitle => 'Reverse Settlement';

  @override
  String get unsettlePreviewLoading => 'Loading reversal preview…';

  @override
  String get unsettlePreviewErrorTitle => 'Couldn\'t load the reversal preview';

  @override
  String get unsettleRefreshAndRetry => 'Refresh preview & retry';

  @override
  String unsettleOriginalEntryLabel(Object entry) {
    return 'Original settlement: $entry';
  }

  @override
  String unsettlePartyLabel(Object party) {
    return 'Party: $party';
  }

  @override
  String unsettleBranchLabel(Object branch) {
    return 'Branch: $branch';
  }

  @override
  String unsettlePostingDateLabel(Object date) {
    return 'Originally posted: $date';
  }

  @override
  String unsettleNetAmountLabel(Object amount) {
    return 'Net amount: $amount';
  }

  @override
  String get unsettleWillReopenSectionTitle => 'Transactions that will reopen';

  @override
  String get unsettleAccountLinesSectionTitle => 'Account lines that will flip';

  @override
  String unsettleTransactionLineSubtitle(Object city, Object amount) {
    return '$city • $amount';
  }

  @override
  String unsettleAccountLineSubtitle(Object debit, Object credit) {
    return 'Debit $debit / Credit $credit';
  }

  @override
  String get unsettleNoBreakdownAvailable =>
      'The server did not return a line-level breakdown for this preview. The totals above are still accurate.';

  @override
  String get unsettleAuditTrailNotice =>
      'This posts a new, opposite Journal Entry. The original settlement is never cancelled — both stay in the audit trail.';

  @override
  String get unsettleAckCheckboxLabel =>
      'I understand this reverses real money movement and cannot be undone from here.';

  @override
  String get unsettleReasonFieldLabel => 'Reason (optional)';

  @override
  String get unsettleReasonFieldHint =>
      'e.g. settled from the wrong branch till';

  @override
  String get unsettleConfirmButton => 'Reverse Settlement';

  @override
  String get unsettleCommitting => 'Posting the reversing entry…';

  @override
  String get unsettleSuccessTitle => 'Settlement reversed';

  @override
  String unsettleSuccessBody(Object entry) {
    return 'The reversing Journal Entry $entry was posted. The affected transactions are back in Unsettled.';
  }

  @override
  String get unsettleCommitErrorTitle => 'Couldn\'t reverse the settlement';

  @override
  String get unsettleAccessRestricted =>
      'Only admins and line managers can reverse a settlement.';

  @override
  String get partnerSettlementMenuTitle => 'Partner Settlements';

  @override
  String get partnerSettlementTabDelivery => 'Delivery Partners';

  @override
  String get partnerSettlementTabSales => 'Sales Partners';

  @override
  String get partnerSettlementRefreshTooltip => 'Refresh';

  @override
  String get partnerSettlementDeliveryEmptyBalances =>
      'No unbilled delivery partner fees.';

  @override
  String partnerSettlementTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '1 trip',
    );
    return '$_temp0';
  }

  @override
  String partnerSettlementOldestSince(Object date) {
    return 'Oldest: $date';
  }

  @override
  String get partnerSettlementReviewAndSettle => 'Review & settle';

  @override
  String partnerSettlementTripsTitle(Object partner) {
    return '$partner — unsettled trips';
  }

  @override
  String get partnerSettlementTripsEmpty =>
      'No unsettled trips for this partner.';

  @override
  String get partnerSettlementSelectAll => 'Select all';

  @override
  String get partnerSettlementDeselectAll => 'Deselect all';

  @override
  String partnerSettlementSelectedOfTotal(int selected, int total) {
    return '$selected of $total selected';
  }

  @override
  String get partnerSettlementUnselectedWarning =>
      'Unticked trips stay unbilled and will reappear next week.';

  @override
  String partnerSettlementTripInvoiceLabel(Object invoice) {
    return 'Invoice: $invoice';
  }

  @override
  String get partnerSettlementTripNoInvoice => 'No invoice reference';

  @override
  String get partnerSettlementExtraChargesTitle => 'Extra charges';

  @override
  String get partnerSettlementExtraChargesHint =>
      'Fixed charges that never accrued per order — subscription, waiting time, a returned-trip charge.';

  @override
  String get partnerSettlementAddCharge => 'Add charge';

  @override
  String get partnerSettlementChargeLabel => 'Description';

  @override
  String get partnerSettlementChargeAmount => 'Amount';

  @override
  String get partnerSettlementNoCharges => 'No extra charges added.';

  @override
  String get partnerSettlementRemoveCharge => 'Remove charge';

  @override
  String get partnerSettlementFeesSubtotal => 'Trip fees';

  @override
  String get partnerSettlementChargesSubtotal => 'Extra charges';

  @override
  String get partnerSettlementGrandTotal => 'Total to transfer';

  @override
  String get partnerSettlementBankAccountOptional => 'Bank account (optional)';

  @override
  String get partnerSettlementSettleButton => 'Settle';

  @override
  String get partnerSettlementConfirmTitle => 'Confirm bank transfer';

  @override
  String get partnerSettlementConfirmMessage =>
      'This posts a real bank transfer. Review the totals before you continue.';

  @override
  String partnerSettlementConfirmTripsLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips agreed',
      one: '1 trip agreed',
      zero: 'No trips selected',
    );
    return '$_temp0';
  }

  @override
  String partnerSettlementConfirmChargesLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count extra charges',
      one: '1 extra charge',
      zero: 'No extra charges',
    );
    return '$_temp0';
  }

  @override
  String get partnerSettlementNothingToSettle =>
      'Nothing selected — tick at least one trip or add a charge.';

  @override
  String partnerSettlementSettledMessage(Object journalEntry) {
    return 'Settled. Journal Entry $journalEntry.';
  }

  @override
  String get partnerSettlementSalesEmptyBalances =>
      'No unsettled sales partner commission.';

  @override
  String partnerSettlementOrderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
    );
    return '$_temp0';
  }

  @override
  String partnerSettlementOnlineCashSplit(Object online, Object cash) {
    return 'Online $online • Cash $cash';
  }

  @override
  String get partnerSettlementCommissionLabel => 'Commission';

  @override
  String get partnerSettlementVatLabel => 'VAT';

  @override
  String get partnerSettlementFeeTotalLabel => 'Total fee';

  @override
  String get partnerSettlementSettleCommissionButton => 'Settle commission';

  @override
  String get partnerSettlementSalesConfirmTitle =>
      'Confirm commission settlement';

  @override
  String get partnerSettlementSalesConfirmMessage =>
      'This posts the commission + VAT recognition journal entry. Review the totals before you continue.';

  @override
  String get partnerSettlementSalesNothingToSettle =>
      'No unsettled transactions for this partner.';

  @override
  String get cashTransferFromAccount => 'From Account';

  @override
  String get cashTransferToAccount => 'To Account';

  @override
  String get cashTransferPostingToday => 'Posting: Today';

  @override
  String cashTransferPostingDate(Object date) {
    return 'Posting: $date';
  }

  @override
  String get cashTransferRemarkOptional => 'Remark (optional)';

  @override
  String get cashTransferFrom => 'From';

  @override
  String get cashTransferTo => 'To';

  @override
  String get cashTransferAccountsMustDiffer => 'Accounts must differ';

  @override
  String get cashTransferSelectAccount => 'Select account';

  @override
  String cashTransferBefore(Object amount) {
    return 'Before: $amount';
  }

  @override
  String cashTransferAfter(Object amount) {
    return 'After: $amount';
  }

  @override
  String get cashTransferNoAccountsFound => 'No accounts found';

  @override
  String cashTransferJournalEntry(Object entry) {
    return 'Journal Entry: $entry';
  }

  @override
  String cashTransferFailed(Object error) {
    return 'Failed: $error';
  }

  @override
  String get postingDateConfirmationTitle => 'Confirm posting date';

  @override
  String get postingDateConfirmationMessage =>
      'Please confirm the posting date before submitting.';

  @override
  String postingDateConfirmationDate(Object date) {
    return 'Posting date: $date';
  }

  @override
  String get postingDateConfirmationDates => 'Posting dates:';

  @override
  String postingDateTimeConfirmationDate(Object dateTime) {
    return 'Posting date and time: $dateTime';
  }

  @override
  String get postingDateTimeConfirmationDates => 'Posting dates and times:';

  @override
  String get postingDatePickerHelp => 'Select posting date';

  @override
  String get postingTimePickerHelp => 'Select posting time';

  @override
  String get menuInventoryCount => 'Inventory Count';

  @override
  String get courierLaunchPinCardTitle => 'Delivery pin';

  @override
  String get courierLaunchPinCardMissing =>
      'This address has no map pin yet. Paste a location link or drop a pin on the map so the courier can find the door.';

  @override
  String get courierLaunchPinCardRequired =>
      'A map pin is required before this delivery order can be placed.';

  @override
  String get courierLaunchPinCardPinned => 'Address has a map pin';

  @override
  String get courierLaunchPinCardChecking => 'Checking the address pin…';

  @override
  String get courierLaunchPinAddAction => 'Add pin';

  @override
  String get courierLaunchPinSave => 'Save pin';

  @override
  String get courierLaunchPinRequiredRefusal =>
      'This delivery address needs a map pin. Add the pin below, then place the order again.';

  @override
  String get courierLaunchPinSheetTitle => 'Add map pin';

  @override
  String get courierLaunchPinSheetHint =>
      'Paste a Google Maps link, or pick the spot on the map.';

  @override
  String courierLaunchPinPicked(Object coords) {
    return 'Pin dropped at $coords';
  }

  @override
  String get courierLaunchPinSaved => 'Pin saved.';

  @override
  String get courierLaunchPinKept =>
      'The address already has a more reliable pin, so it was kept.';

  @override
  String get courierLaunchPinSaveFailed => 'Could not save the pin.';

  @override
  String get courierLaunchPinNoAddress =>
      'This order has no delivery address to pin.';

  @override
  String get courierLaunchTrackingShare => 'Share tracking link';

  @override
  String get courierLaunchTrackingSheetTitle => 'Tracking link';

  @override
  String get courierLaunchTrackingSheetHint =>
      'The customer follows the order live from this link.';

  @override
  String get courierLaunchTrackingCodeLabel => 'Delivery code';

  @override
  String get courierLaunchTrackingCodeHint =>
      'The customer gives this code to the courier at the door.';

  @override
  String get courierLaunchTrackingCopyCode => 'Copy code';

  @override
  String get courierLaunchTrackingCodeCopied => 'Code copied.';

  @override
  String get courierLaunchTrackingCopyLink => 'Copy link';

  @override
  String get courierLaunchTrackingLinkCopied => 'Link copied.';

  @override
  String get courierLaunchTrackingSendWhatsApp => 'Send on WhatsApp';

  @override
  String get courierLaunchTrackingShareOther => 'Share…';

  @override
  String get courierLaunchTrackingLinkFailed =>
      'Could not get the tracking link.';

  @override
  String get courierLaunchTimelineTitle => 'Delivery timeline';

  @override
  String courierLaunchTimelineCourier(Object name) {
    return 'Courier: $name';
  }

  @override
  String get courierLaunchTimelineStages => 'Time per stage';

  @override
  String courierLaunchTimelineTotal(Object minutes) {
    return 'Total $minutes min';
  }

  @override
  String courierLaunchTimelineMinutes(Object minutes) {
    return '$minutes min';
  }

  @override
  String courierLaunchTimelineTarget(Object minutes) {
    return 'target $minutes min';
  }

  @override
  String get courierLaunchTimelineOver => 'Over target';

  @override
  String get courierLaunchTimelineMapTitle => 'Where it happened';

  @override
  String get courierLaunchEventCreated => 'Order created';

  @override
  String get courierLaunchEventAccepted => 'Accepted';

  @override
  String get courierLaunchEventInProgress => 'Preparing';

  @override
  String get courierLaunchEventOutForDelivery => 'Out for delivery';

  @override
  String get courierLaunchEventLeftBranch => 'Left the branch';

  @override
  String get courierLaunchEventLegStarted => 'Started the trip to the customer';

  @override
  String get courierLaunchEventArrived => 'Arrived at the customer';

  @override
  String get courierLaunchEventDelivered => 'Delivered';

  @override
  String get courierLaunchEventFailed => 'Delivery failed';

  @override
  String get courierLaunchEventBackAtBranch => 'Back at the branch';

  @override
  String get courierLaunchSegmentPrep => 'Preparation';

  @override
  String get courierLaunchSegmentDispatchWait => 'Waiting for dispatch';

  @override
  String get courierLaunchSegmentTravel => 'Travel';

  @override
  String get courierLaunchSegmentAtDoor => 'At the door';

  @override
  String get courierLaunchSegmentReturn => 'Return to the branch';

  @override
  String get addressPinTitle => 'Fix delivery pin';

  @override
  String get addressPinCurrentPin => 'Current pin';

  @override
  String get addressPinNoPinYet => 'No pin set yet';

  @override
  String get addressPinProposeNew => 'Propose a new pin';

  @override
  String get addressPinPickOnMap => 'Pick on map';

  @override
  String get addressPinUseThisPoint => 'Use this point';

  @override
  String get addressPinPreviewChanges => 'Preview change';

  @override
  String get addressPinWillUpdate => 'This will update the pin.';

  @override
  String get addressPinWillKeepExisting =>
      'The existing pin is kept — it already has equal or higher confidence.';

  @override
  String addressPinMovedBy(Object meters) {
    return 'Moves the pin about $meters m from where it is now.';
  }

  @override
  String get addressPinPermissionNote =>
      'Only a line manager may commit a pin correction.';

  @override
  String get addressPinCommit => 'Save correction';

  @override
  String get addressPinNoteLabel => 'What was wrong? (optional)';

  @override
  String get addressPinSaveSuccessAccepted => 'Pin updated.';

  @override
  String get addressPinSaveSuccessRejected =>
      'Kept the existing pin — it already has equal or higher confidence.';

  @override
  String get addressPinFixTooltip => 'Fix delivery pin';

  @override
  String get addressPinDryRunFailed => 'Could not preview this change.';

  @override
  String addressPinSourceLabel(Object source) {
    return 'Source: $source';
  }

  @override
  String addressPinConfidenceLabel(int rank) {
    return 'Confidence rank: $rank';
  }

  @override
  String addressPinAccuracyLabel(Object meters) {
    return 'Accurate to about $meters m';
  }

  @override
  String get addressPinAccuracyUnknown => 'Accuracy unknown';

  @override
  String addressPinVerifiedOn(Object date) {
    return 'Verified $date';
  }

  @override
  String get addressPinStoredLinkLabel => 'Original pasted link';

  @override
  String get addressPinSourceTerritoryCentroid => 'Territory centre (fallback)';

  @override
  String get addressPinSourcePosLink => 'Pasted link at order creation';

  @override
  String get addressPinSourceCustomerPin => 'Customer-shared pin';

  @override
  String get addressPinSourceCourierWeb => 'Courier check-in (web)';

  @override
  String get addressPinSourceCourierVerified => 'Courier check-in (verified)';

  @override
  String get addressPinSourceManualOverride => 'Manual correction';

  @override
  String get addressPinSourceUnknown => 'Unknown';

  @override
  String get rosterBulkSelectHint =>
      'Tap days to select them. Tapping a day in someone else\'s row starts a new selection for that person.';

  @override
  String rosterBulkSelectionCount(int count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days selected for $name',
      one: '1 day selected for $name',
    );
    return '$_temp0';
  }

  @override
  String get rosterBulkAssignShift => 'Assign shift to all';

  @override
  String get rosterBulkMarkOff => 'Mark all off';

  @override
  String get rosterBulkClearOff => 'Clear day off (all)';

  @override
  String get rosterBulkCancelSelection => 'Cancel selection';

  @override
  String rosterBulkConfirmOffTitle(int count) {
    return 'Mark $count days off?';
  }

  @override
  String rosterBulkConfirmOffBody(Object name) {
    return '$name will not be able to clock in on these days until they are rostered again.';
  }

  @override
  String get rosterBulkApplying => 'Applying…';

  @override
  String get rosterBulkPartialFailureTitle => 'Some days could not be updated';

  @override
  String rosterBulkPartialFailureBody(int applied, int total) {
    return '$applied of $total applied.';
  }

  @override
  String get rosterBulkAllFailed =>
      'None of the selected days could be updated.';

  @override
  String rosterBulkSuccess(int count) {
    return '$count days updated.';
  }

  @override
  String get rosterBulkViewFailures => 'View details';

  @override
  String get inventoryCountOfflineUsingCache => 'Offline using cached data';

  @override
  String inventoryCountConfirmAllBeforeSubmit(int remaining) {
    return 'Please confirm all items before submitting ($remaining remaining)';
  }

  @override
  String get inventoryCountConfirmAtLeastOne =>
      'Confirm at least one item before submitting';

  @override
  String inventoryCountSubmitted(Object result) {
    return 'Submitted: $result';
  }

  @override
  String get inventoryCountNoDifferences => 'No differences';

  @override
  String get inventoryCountUncategorized => 'Uncategorized';

  @override
  String get inventoryCountManagerAccessRequired => 'Manager access required';

  @override
  String get inventoryCountSelectWarehouse => 'Select Warehouse';

  @override
  String get inventoryCountEnforceAll => 'Enforce all';

  @override
  String inventoryCountConfirmedProgress(int confirmed, int total) {
    return 'Confirmed $confirmed / $total';
  }

  @override
  String get inventoryCountClearAllEnteredData => 'Clear all entered data';

  @override
  String get inventoryCountAllEnteredDataCleared => 'All entered data cleared';

  @override
  String inventoryCountCurrentAmount(Object amount, Object uom) {
    return 'Current: $amount $uom';
  }

  @override
  String get inventoryCountDecrease => 'Decrease';

  @override
  String get inventoryCountCount => 'Count';

  @override
  String get inventoryCountIncrease => 'Increase';

  @override
  String inventoryCountValuation(Object amount, Object uom) {
    return 'Valuation: $amount / $uom';
  }

  @override
  String get inventoryCountDeltaLabel => 'Delta: ';

  @override
  String get inventoryCountSubmitCount => 'Submit Count';

  @override
  String get inventoryCountSetupStep => 'Setup';

  @override
  String get inventoryCountBlindEntryStep => 'Blind entry';

  @override
  String get inventoryCountReviewStep => 'Review discrepancies';

  @override
  String get inventoryCountSpotCount => 'Spot count';

  @override
  String get inventoryCountSpotCountDescription =>
      'Submit only the items you counted.';

  @override
  String get inventoryCountFullWarehouseCountDescription =>
      'Count every loaded item before final submit.';

  @override
  String get inventoryCountWarehouseLabel => 'Warehouse';

  @override
  String get inventoryCountPostingDateLabel => 'Posting date';

  @override
  String get inventoryCountCountModeLabel => 'Count mode';

  @override
  String get inventoryCountContinueCount => 'Continue count';

  @override
  String get inventoryCountStartCount => 'Start count';

  @override
  String get inventoryCountBackToSetup => 'Back to setup';

  @override
  String get inventoryCountReviewButton => 'Review discrepancies';

  @override
  String get inventoryCountBackToCounting => 'Back to counting';

  @override
  String inventoryCountFilteredItems(int visible, int total) {
    return '$visible of $total items';
  }

  @override
  String get inventoryCountCountedStatus => 'Counted';

  @override
  String get inventoryCountPendingStatus => 'Pending';

  @override
  String get inventoryCountClearEntry => 'Clear entry';

  @override
  String get inventoryCountSummaryCountedItems => 'Counted items';

  @override
  String get inventoryCountSummaryChangedItems => 'Changed items';

  @override
  String get inventoryCountSummaryMissingItems => 'Missing items';

  @override
  String get inventoryCountReviewDiscrepancies => 'Discrepancies';

  @override
  String get inventoryCountReviewNoCountedItems => 'No counted items yet.';

  @override
  String get inventoryCountReviewNoDiscrepancies =>
      'No discrepancies found yet.';

  @override
  String get inventoryCountReviewUnchanged => 'Unchanged counted items';

  @override
  String get inventoryCountReviewMissing => 'Missing items';

  @override
  String inventoryCountCountedAmount(Object amount, Object uom) {
    return 'Counted: $amount $uom';
  }

  @override
  String inventoryCountStockEquivalent(Object amount, Object uom) {
    return 'Stock equivalent: $amount $uom';
  }

  @override
  String get inventoryCountMissingItemNote => 'Not counted yet';

  @override
  String get inventoryCountBatchTracked => 'Batch tracked';

  @override
  String get inventoryCountSerialTracked => 'Serial tracked';

  @override
  String get menuEndShift => 'End Shift';

  @override
  String get menuHome => 'Home';

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuLogout => 'Logout';

  @override
  String get menuLanguage => 'Language';

  @override
  String get menuLanguageEnglish => 'English';

  @override
  String get menuLanguageArabic => 'Arabic';

  @override
  String menuSelectedLanguage(Object language) {
    return 'Current language: $language';
  }

  @override
  String menuConfirmLanguage(Object language) {
    return 'Switch language to $language?';
  }

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonChoose => 'Choose';

  @override
  String get commonSearchItems => 'Search items';

  @override
  String get commonSearchSuppliers => 'Search suppliers';

  @override
  String get commonNoItems => 'No items';

  @override
  String get commonNoSuppliers => 'No suppliers';

  @override
  String get commonQtyLabel => 'Qty:';

  @override
  String get commonRateLabel => 'Rate:';

  @override
  String commonAmountValue(Object amount) {
    return 'Amount: $amount';
  }

  @override
  String commonTotalValue(Object amount) {
    return 'Total: $amount';
  }

  @override
  String commonNameWithCode(Object code, Object name) {
    return '$name ($code)';
  }

  @override
  String get commonUomLabel => 'UOM:';

  @override
  String commonUomValue(Object uom) {
    return 'UOM: $uom';
  }

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonOk => 'OK';

  @override
  String get commonOnline => 'Online';

  @override
  String get commonOffline => 'Offline';

  @override
  String get commonError => 'Error';

  @override
  String commonErrorWithDetails(Object details) {
    return 'Error: $details';
  }

  @override
  String get userErrorOffline =>
      'The server could not be reached. Check your connection and the operation status before trying again.';

  @override
  String get userErrorTimeout =>
      'The request took too long. Check the operation status before trying again.';

  @override
  String get userErrorCertificate =>
      'The secure connection to the server could not be established.';

  @override
  String get userErrorCancelled => 'The request was cancelled.';

  @override
  String get userErrorUnauthorized =>
      'Your session has expired. Sign in again.';

  @override
  String get userErrorForbidden =>
      'You do not have permission to perform this action.';

  @override
  String get userErrorNotFound => 'The requested item could not be found.';

  @override
  String get userErrorConflict =>
      'This operation conflicts with existing data. Refresh and check its status before continuing.';

  @override
  String get userErrorRateLimited =>
      'Too many requests. Wait a moment and try again.';

  @override
  String get userErrorServer =>
      'The server encountered a problem. Check the operation status before submitting again.';

  @override
  String get userErrorUnexpected => 'Something went wrong unexpectedly.';

  @override
  String get userErrorValidationFallback =>
      'Check the entered information and try again.';

  @override
  String get userErrorDraftLimit =>
      'The draft limit has been reached. Delete an unused draft before creating another.';

  @override
  String get userErrorReopenOrder =>
      'The order data is incomplete or outdated. Close the order and reopen it to reload its items.';

  @override
  String get userErrorShippingAddress =>
      'The shipping address is no longer available. Select a valid address for this customer.';

  @override
  String get userErrorInsufficientStock =>
      'There is not enough stock. Check the available quantity or contact the branch.';

  @override
  String get userErrorShiftRequired =>
      'An open shift is required. Check your shift before continuing.';

  @override
  String get userErrorAlreadyProcessed =>
      'This operation was already processed. Check the order status before submitting again.';

  @override
  String get userErrorTransferReceiptRequired =>
      'InstaPay and wallet payments need a confirmed transfer receipt. Attach the customer transfer screenshot to this order and have a manager confirm it, then pay again.';

  @override
  String get userErrorRequiredFields =>
      'Complete the required fields before continuing.';

  @override
  String get userErrorScreenFailed =>
      'This page could not be displayed. Close it and open it again.';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCustomerLabel => 'Customer';

  @override
  String get commonPosProfileLabel => 'POS Profile';

  @override
  String get commonTotalLabel => 'Total';

  @override
  String get commonAmountLabel => 'Amount';

  @override
  String get commonDateLabel => 'Date';

  @override
  String get commonCourierLabel => 'Courier';

  @override
  String get commonDeliveryLabel => 'Delivery';

  @override
  String get commonItemsLabel => 'Items';

  @override
  String get commonItemLabel => 'Item';

  @override
  String get commonNotesLabel => 'Notes';

  @override
  String get commonPaymentLabel => 'Payment';

  @override
  String get commonOutstandingLabel => 'Outstanding';

  @override
  String get commonUploadedByLabel => 'Uploaded by';

  @override
  String get commonReasonLabel => 'Reason';

  @override
  String get ofdShortageDialogTitle => 'Approve stock shortage for dispatch';

  @override
  String get ofdShortageDialogMessage =>
      'These items are short at the dispatch warehouse. Add a reason to continue the Out For Delivery move.';

  @override
  String ofdShortageLine(
    String item,
    String required,
    String available,
    String warehouse,
  ) {
    return '$item: required $required, available $available, warehouse $warehouse';
  }

  @override
  String get ofdShortageReasonHint =>
      'Explain why dispatch should continue despite the shortage';

  @override
  String get ofdShortageReasonRequired =>
      'Provide a shortage reason to continue';

  @override
  String get ofdShortageApprove => 'Approve and continue';

  @override
  String get commonNotSpecified => 'Not specified';

  @override
  String get commonWalkIn => 'Walk-in';

  @override
  String get commonScheduled => 'Scheduled';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonNew => 'New';

  @override
  String get commonPreview => 'Preview';

  @override
  String commonByUser(Object user) {
    return 'by $user';
  }

  @override
  String commonQtyWithUom(Object uom) {
    return 'Qty ($uom)';
  }

  @override
  String orderAlertTitle(Object invoiceId) {
    return 'New Order: $invoiceId';
  }

  @override
  String get orderAlertNoLineItems => 'No line items';

  @override
  String orderAlertMoreItems(Object count) {
    return '+$count more item(s)';
  }

  @override
  String get orderAlertMuteAlarm => 'Mute Alarm';

  @override
  String get orderAlertUnmuteAlarm => 'Unmute Alarm';

  @override
  String get orderAlertAccepting => 'Accepting...';

  @override
  String get orderAlertAcceptOrder => 'Accept Order';

  @override
  String get posDraftDeleteTitle => 'Delete Draft';

  @override
  String posDraftDeleteBody(Object label) {
    return 'Delete \"$label\"? This cannot be undone.';
  }

  @override
  String posDraftLimitReached(Object max) {
    return 'Draft limit reached ($max max). Delete a draft to create a new one.';
  }

  @override
  String get expensesTitle => 'Expenses';

  @override
  String get expensesRefreshTooltip => 'Refresh';

  @override
  String get expensesNewExpense => 'New Expense';

  @override
  String get expensesRecorded => 'Expense recorded';

  @override
  String get expensesSubmitted => 'Expense submitted for approval';

  @override
  String get expensesMonthLabel => 'Month';

  @override
  String get expensesMonthCurrent => 'Current Month';

  @override
  String get expensesEmptyTitle => 'No expenses recorded for this month.';

  @override
  String get expensesEmptyManagerBody =>
      'Use the New Expense button to log team spending.';

  @override
  String get expensesEmptyStaffBody =>
      'Submit a request and a manager will review it shortly.';

  @override
  String get expensesFiltersClear => 'Clear filters';

  @override
  String get expensesFiltersTitle => 'Filter by payment method';

  @override
  String get expensesFiltersEmpty => 'No payment sources available';

  @override
  String get expensesSummaryTotal => 'Total';

  @override
  String get expensesSummaryApproved => 'Approved';

  @override
  String get expensesSummaryPending => 'Pending';

  @override
  String expensesSummaryReceipts(Object count) {
    return '$count receipts';
  }

  @override
  String expensesSummaryPendingAmount(Object amount, Object count) {
    return '$count | $amount';
  }

  @override
  String get expensesReasonLabel => 'Reason (Indirect expense account)';

  @override
  String get expensesPayFromLabel => 'Pay from';

  @override
  String get expensesAmountLabel => 'Amount';

  @override
  String get expensesAmountHint => 'Enter amount';

  @override
  String get expensesAmountInvalid => 'Enter a valid amount';

  @override
  String get expensesDateLabel => 'Expense date';

  @override
  String get expensesReasonRequired => 'Select a reason';

  @override
  String get expensesPaymentSourceRequired => 'Select a payment source';

  @override
  String get expensesRemarksLabel => 'Remarks (optional)';

  @override
  String get expensesSubmitManager => 'Record expense';

  @override
  String get expensesSubmitStaff => 'Submit for approval';

  @override
  String get expensesNoOptions =>
      'Expenses cannot be created until a reason and payment source are available.';

  @override
  String get expensesApprove => 'Approve';

  @override
  String get expensesPendingStatus => 'Pending Approval';

  @override
  String get expensesApprovedStatus => 'Approved';

  @override
  String get expensesDraftStatus => 'Draft';

  @override
  String get expensesJournalEntry => 'Journal Entry';

  @override
  String get expensesPosProfile => 'POS Profile';

  @override
  String get expensesPayingAccount => 'Paying account';

  @override
  String get expensesReasonAccount => 'Expense account';

  @override
  String get expensesTimelineTitle => 'Timeline';

  @override
  String get expensesTimelineEmpty => 'No timeline available';

  @override
  String get expensesPullToRefresh => 'Pull to refresh';

  @override
  String languageChanged(Object language) {
    return 'Language changed to $language.';
  }

  @override
  String get purchaseTitle => 'Purchase Invoice';

  @override
  String get purchaseSupplierSectionTitle => 'Supplier';

  @override
  String get purchaseTapToPickSupplier => 'Tap to pick supplier';

  @override
  String get purchaseItemsSectionTitle => 'Items';

  @override
  String get purchaseShippingLabel => 'Shipping (Freight & Forwarding):';

  @override
  String get purchaseSubmit => 'Create Purchase Invoice';

  @override
  String get purchaseSelectSupplier => 'Select Supplier';

  @override
  String get purchaseRecent => 'Recent';

  @override
  String get purchaseSupplierDisabledSuffix => ' (Disabled)';

  @override
  String get purchaseNoItemsInCart => 'No items in cart';

  @override
  String purchaseCreated(Object invoice) {
    return 'Purchase created: $invoice';
  }

  @override
  String purchaseSubmitFailed(Object error) {
    return 'Purchase failed: $error';
  }

  @override
  String get purchaseSelectPayment => 'Select Payment Source';

  @override
  String get purchasePaymentProfileSubtitle =>
      'Use exact-named POS Profile cash account';

  @override
  String get purchasePaymentInstapayTitle => 'InstaPay (Bank)';

  @override
  String get purchasePaymentInstapaySubtitle =>
      'Use bank account mapped to InstaPay';

  @override
  String get purchasePaymentCashTitle => 'Cash';

  @override
  String get purchasePaymentCashSubtitle => 'Use company default Cash account';

  @override
  String get posProfileSelectionTitle => 'Select POS Profile';

  @override
  String get posProfileSelectionErrorTitle => 'Error loading POS profiles';

  @override
  String get posProfileSelectionNoProfilesTitle => 'No POS Profiles Available';

  @override
  String get posProfileSelectionNoProfilesBody =>
      'Contact your administrator to assign you to a POS profile';

  @override
  String get posProfileSelectionUnknownProfile => 'Unknown Profile';

  @override
  String posProfileSelectionWarehouseLabel(Object warehouse) {
    return 'Warehouse: $warehouse';
  }

  @override
  String get posProfileSelectionPrompt => 'Choose a POS profile:';

  @override
  String get posProfileSelectionCycleHint => 'Select POS';

  @override
  String get posProfileSelectionShortFallback => 'POS';

  @override
  String get shiftStartTitle => 'Start Shift';

  @override
  String get shiftEndTitle => 'End Shift';

  @override
  String get shiftNoActive => 'No active shift found.';

  @override
  String get shiftBackToPos => 'Back to POS';

  @override
  String get shiftOpeningPrompt => 'Count opening cash and enter it:';

  @override
  String shiftPosProfile(Object profile) {
    return 'POS Profile: $profile';
  }

  @override
  String shiftAccount(Object account) {
    return 'Account: $account';
  }

  @override
  String shiftSystemBalance(Object amount) {
    return 'System Balance: $amount';
  }

  @override
  String get shiftConfirmedOpeningAmount => 'Confirmed Opening Amount';

  @override
  String get shiftCountedOpeningAmount => 'Counted Opening Cash';

  @override
  String shiftDifferenceAmount(Object amount) {
    return 'Difference: $amount';
  }

  @override
  String get shiftClosingPrompt => 'Count closing cash and enter it:';

  @override
  String get shiftClosingAmountLabel => 'Closing Amount';

  @override
  String get shiftCountedClosingAmount => 'Counted Closing Cash';

  @override
  String get shiftBlindCountHint =>
      'Count the cash in the drawer and enter the amount.';

  @override
  String get shiftNoClosingPaymentMethodsTitle => 'Cash entry is unavailable';

  @override
  String get shiftNoClosingPaymentMethodsBody =>
      'No closing payment method is available for this shift. Reopen the shift or contact support.';

  @override
  String get shiftCashCountRequired => 'Enter the counted cash amount.';

  @override
  String get shiftCashCountInvalid => 'Enter a valid cash amount.';

  @override
  String get shiftCashCountNegative => 'Cash amount cannot be negative.';

  @override
  String shiftExpectedAmount(Object amount) {
    return 'Expected: $amount';
  }

  @override
  String shiftLoadActiveFailed(Object error) {
    return 'Failed to load active shift: $error';
  }

  @override
  String get shiftSummaryLoadFailed => 'Unable to load shift summary.';

  @override
  String shiftLabel(Object shift) {
    return 'Shift: $shift';
  }

  @override
  String get shiftUnexpectedStartResponse =>
      'Unexpected server response while starting the shift.';

  @override
  String get shiftUnexpectedSummaryResponse =>
      'Unexpected server response while loading the shift summary.';

  @override
  String get shiftUnexpectedEndResponse =>
      'Unexpected server response while ending the shift.';

  @override
  String get shiftCourierBlockTitle =>
      'Settle courier balances before ending the shift';

  @override
  String shiftCourierBlockBody(
    int transactions,
    int couriers,
    int invoices,
    Object profile,
  ) {
    return 'This shift still has $transactions unsettled courier transaction(s) for $couriers courier(s) across $invoices invoice(s) on POS Profile $profile.';
  }

  @override
  String get shiftCourierBlockHint =>
      'Open courier balances, settle what is still pending, then come back to finish the shift.';

  @override
  String get shiftCourierReviewButton => 'Review & Settle Couriers';

  @override
  String shiftCourierBlockPartySummary(
    Object name,
    int transactions,
    int invoices,
  ) {
    return '$name: $transactions transaction(s) on $invoices invoice(s)';
  }

  @override
  String shiftCourierBlockNetBalance(Object amount) {
    return 'Net balance: $amount';
  }

  @override
  String shiftCourierBlockMore(int count) {
    return '+$count more courier(s)';
  }

  @override
  String shiftOutflows(Object amount) {
    return 'Outflows: $amount';
  }

  @override
  String shiftNetMovement(Object amount) {
    return 'Net Movement: $amount';
  }

  @override
  String get shiftAccountMovements => 'Account Movements';

  @override
  String get shiftOther => 'Other';

  @override
  String shiftSubtotal(Object amount) {
    return 'Subtotal: $amount';
  }

  @override
  String shiftInvoices(Object count) {
    return 'Invoices: $count';
  }

  @override
  String shiftGrandTotal(Object amount) {
    return 'Grand Total: $amount';
  }

  @override
  String get shiftStartButton => 'Start Shift';

  @override
  String get shiftEndButton => 'End Shift';

  @override
  String get shiftEndedSuccess => 'Shift ended successfully.';

  @override
  String get shiftStatusActive => 'Shift Active';

  @override
  String shiftStartedAt(Object time) {
    return 'Started at $time';
  }

  @override
  String shiftProfileMismatch(Object activeProfile, Object selectedProfile) {
    return 'Active shift is on $activeProfile. Selected profile is $selectedProfile.';
  }

  @override
  String get shiftAlreadyOpenByAnotherTitle => 'Shift Already Open';

  @override
  String shiftAlreadyOpenByAnotherBody(Object branch, Object user) {
    return 'POS Profile \"$branch\" already has an open shift started by $user. That shift must be closed before you can start a new one.';
  }

  @override
  String get shiftRefresh => 'Refresh';

  @override
  String get shiftLogout => 'Logout';

  @override
  String get shiftSwitchToActiveProfile => 'Switch to active shift profile';

  @override
  String shiftOpenOnOtherProfile(Object otherProfile, Object shiftName) {
    return 'You have an open shift ($shiftName) on profile \"$otherProfile\". Close that shift before starting a new one here.';
  }

  @override
  String get shiftGoToEnd => 'Go to End Shift';

  @override
  String get shiftAccountBalance => 'Account Balance';

  @override
  String get shiftDifference => 'Difference';

  @override
  String get shiftSalesInvoices => 'Sales Invoices';

  @override
  String get shiftNoDeliveryStatus => 'No status';

  @override
  String get shiftClosedSummaryTitle => 'Shift Summary';

  @override
  String get shiftClosingEntry => 'Closing Entry';

  @override
  String get shiftJournalCreated => 'Cash discrepancy recorded';

  @override
  String get posCartTitle => 'Shopping Cart';

  @override
  String posCartHeader(Object count) {
    return 'Cart ($count)';
  }

  @override
  String get posCartClear => 'Clear cart';

  @override
  String get posCartEmptyTitle => 'Cart is empty';

  @override
  String get posCartEmptyBody => 'Add items to get started';

  @override
  String get posCustomerUnselect => 'Remove customer';

  @override
  String get posCustomerAdd => 'Add customer';

  @override
  String posCustomerDeliveryIncomeValue(Object amount) {
    return 'Delivery income: $amount';
  }

  @override
  String get posUnknownCustomer => 'Unknown Customer';

  @override
  String get posCartPickupTitle => 'Pickup (no delivery fee)';

  @override
  String get posCartPickupDescription =>
      'Customer will collect the order from branch.';

  @override
  String get posCartDeliveryDescription =>
      'Deliver to customer at selected time.';

  @override
  String get posCartPickupChip => 'Pickup';

  @override
  String get posCartPricingTitle => 'Manager Pricing';

  @override
  String get posCartPriceListLabel => 'Price list';

  @override
  String get posCartPriceListHint =>
      'Use the profile default or switch to another list open to this order.';

  @override
  String get posCartPriceListSetByPurpose => 'Set by the order purpose.';

  @override
  String get posCartPriceListAfterCustomer =>
      'Chosen from the customer\'s price list once you select the customer.';

  @override
  String get posPurposePriceListUpdated =>
      'Prices were updated to match the order purpose. Review the cart, then check out again.';

  @override
  String get posPurposePriceListUnavailable =>
      'The price list for this order purpose could not be applied. Select the customer or change the order purpose.';

  @override
  String get posCartPriceListDefaultChip => 'Default';

  @override
  String get posCartOrderPurposeLabel => 'Order purpose';

  @override
  String get posCartOrderPurposeHint =>
      'Apply a commercial policy or keep this a standard order.';

  @override
  String get posCartOrderPurposeStandard => 'Standard';

  @override
  String get posCartOrderPurposeWaivesShipping => 'Shipping income waived';

  @override
  String get posCartOrderPurposeNoCourier => 'No courier expense';

  @override
  String get posCartOrderPurposeReasonLabel => 'Reason (optional)';

  @override
  String get posCartOrderPurposeReasonHint =>
      'Add a note explaining why this purpose applies.';

  @override
  String get posCartZeroShippingTitle => 'Zero shipping income';

  @override
  String get posCartZeroShippingDescription =>
      'Do not charge shipping income on this order.';

  @override
  String get posCartZeroShippingPriceListDefault =>
      'Enabled automatically for this price list.';

  @override
  String get posCartZeroShippingManagedByPickup =>
      'Pickup already disables delivery charges.';

  @override
  String get posCartZeroShippingManagedByPartner =>
      'Sales partner orders already suppress shipping income.';

  @override
  String get posSubtotalLabel => 'Subtotal:';

  @override
  String get posDeliveryLabel => 'Delivery:';

  @override
  String get posTotalLabel => 'Total:';

  @override
  String get posCheckoutButton => 'Checkout';

  @override
  String get posCheckoutStockExceedTitle => 'Items exceed available stock';

  @override
  String get posCheckoutStockExceedMessage =>
      'The following cart items exceed current system stock. The order can still be created, but fulfillment may need incoming stock or inventory correction.';

  @override
  String posCheckoutStockExceedLine(
    String item,
    String requested,
    String available,
  ) {
    return '$item: requested $requested, available $available';
  }

  @override
  String get posCheckoutProceedAnyway => 'Proceed with order';

  @override
  String get posTerritoryMismatchTitle => 'Profile Mismatch';

  @override
  String get posTerritoryMismatchBody =>
      'The customer\'s territory is mapped to a different POS profile.';

  @override
  String posTerritoryMismatchUseSelected(String profile) {
    return 'Keep selected: $profile';
  }

  @override
  String posTerritoryMismatchUseTerritory(String profile) {
    return 'Switch to territory profile: $profile';
  }

  @override
  String posTerritoryMismatchNoTerritory(String profile) {
    return 'No territory profile assigned - keep selected: $profile';
  }

  @override
  String get posTerritoryMismatchCancel => 'Cancel';

  @override
  String get posTerritoryMismatchConfirm => 'Proceed';

  @override
  String get posAmendmentDraftButton => 'Submit Amendment';

  @override
  String get posOperationalInfoTitle => 'Operational Info';

  @override
  String get posDeliveryExpenseLabel => 'Delivery Expense:';

  @override
  String posDeliveryCostTo(Object territory) {
    return 'Cost to $territory';
  }

  @override
  String get posDeliveryCostGeneric => 'Cost to deliver';

  @override
  String get posUnknownItem => 'Unknown Item';

  @override
  String get posCartEditBundle => 'Edit Bundle';

  @override
  String get posCartItemPricingDialogTitle => 'Edit line pricing';

  @override
  String posCartItemPricingBaseRate(String amount) {
    return 'Current catalog rate: $amount';
  }

  @override
  String get posCartItemPricingCustomRateLabel => 'Custom unit price';

  @override
  String get posCartItemPricingDiscountAmountLabel => 'Discount amount';

  @override
  String get posCartItemPricingDiscountPercentLabel => 'Discount percentage';

  @override
  String get posCartItemPricingDiscountHint =>
      'Use discount amount or discount percentage, not both.';

  @override
  String get posCartItemPricingReset => 'Reset pricing';

  @override
  String get posCartItemPricingSave => 'Apply';

  @override
  String posCartItemCustomPriceApplied(String amount) {
    return 'Custom $amount';
  }

  @override
  String posCartItemDiscountAmountApplied(String amount) {
    return 'Discount $amount';
  }

  @override
  String posCartItemDiscountPercentApplied(String amount) {
    return 'Discount $amount%';
  }

  @override
  String get posCartItemPricingInvalidNumber => 'Enter a valid number.';

  @override
  String get posCartItemPricingInvalidCustomRate =>
      'Custom price must be zero or more.';

  @override
  String get posCartItemPricingInvalidDiscountAmount =>
      'Discount amount must be zero or more.';

  @override
  String get posCartItemPricingInvalidDiscountPercent =>
      'Discount percentage must be between 0 and 100.';

  @override
  String get posCartItemPricingChooseSingleDiscount =>
      'Use discount amount or discount percentage, not both.';

  @override
  String get posCartItemPricingDiscountTooHigh =>
      'Discount amount cannot exceed the effective unit price.';

  @override
  String get posCartClearTitle => 'Clear Cart';

  @override
  String get posCartClearMessage =>
      'Are you sure you want to remove all items from the cart?';

  @override
  String get posCartClearConfirm => 'Clear';

  @override
  String get posDeliverySelectSlot => 'Please select a delivery time';

  @override
  String get posDeliveryDialogTitle => 'Select Delivery Time';

  @override
  String get posDeliveryLoadFailed => 'Failed to load delivery slots';

  @override
  String get posDeliveryEmptyTitle => 'No delivery slots available';

  @override
  String get posDeliveryEmptyBody =>
      'Please check the POS profile timetable configuration';

  @override
  String get posDeliveryDefaultChip => 'Next';

  @override
  String get posDeliveryLoading => 'Loading delivery slots...';

  @override
  String get posDeliveryFieldLabel => 'Delivery Time';

  @override
  String get posDeliveryErrorLabel => 'Error loading slots';

  @override
  String get posDeliveryNoSlotsLabel => 'No slots available';

  @override
  String get posDeliverySelectPrompt => 'Select delivery time';

  @override
  String get posSalesPartnerPaymentTitle => 'Sales Partner Payment';

  @override
  String get posSalesPartnerPaymentDescription =>
      'Choose how the sales partner is paying for this order.';

  @override
  String get posSalesPartnerPaymentCash => 'Cash (collected now)';

  @override
  String get posSalesPartnerPaymentOnline => 'Online (already paid)';

  @override
  String get posCheckoutSuccess => 'Order placed successfully!';

  @override
  String posCheckoutFailed(Object error) {
    return 'Failed to place order: $error';
  }

  @override
  String get posBundleContentsTitle => 'Bundle Contents:';

  @override
  String get posBundleUpdated => 'Bundle updated successfully!';

  @override
  String get printerStatusBle => 'Printer: BLE';

  @override
  String get printerStatusClassic => 'Printer: Classic';

  @override
  String get printerStatusConnecting => 'Printer: Connecting…';

  @override
  String get printerStatusError => 'Printer Error';

  @override
  String get printerStatusDisconnected => 'Printer: Not Connected';

  @override
  String get printerSelectTitle => 'Select Printer';

  @override
  String get printerCompatibilityTooltip => 'Printer compatibility settings';

  @override
  String get printerCompatibilityTitle => 'Compatibility';

  @override
  String get printerCompatibilitySubtitle =>
      'Safe defaults keep normal receipts as text and only use raster output where it is needed.';

  @override
  String get printerCompatibilitySaved =>
      'Printer compatibility settings saved';

  @override
  String get printerCompatibilityReset => 'Reset defaults';

  @override
  String get printerDiagnosticsTitle => 'Diagnostics';

  @override
  String printerDiagnosticsAdapter(Object state) {
    return 'Adapter: $state';
  }

  @override
  String printerDiagnosticsScan(Object status) {
    return 'Perm scan: $status';
  }

  @override
  String printerDiagnosticsConnect(Object status) {
    return 'Perm connect: $status';
  }

  @override
  String printerDiagnosticsLocation(Object status) {
    return 'Perm location: $status';
  }

  @override
  String get printerDeviceIdLabel => 'Device ID (MAC / Identifier)';

  @override
  String get printerConnectById => 'Connect by ID';

  @override
  String get printerConnectingById => 'Connecting by ID...';

  @override
  String get printerConnecting => 'Connecting...';

  @override
  String get printerConnected => 'Printer connected';

  @override
  String get printerConnectionFailed => 'Failed to connect';

  @override
  String get printerForgetSavedTooltip => 'Forget saved printer';

  @override
  String get printerForgotSaved => 'Forgot saved printer';

  @override
  String get printerRescanTooltip => 'Rescan';

  @override
  String get printerReconnecting => 'Reconnecting...';

  @override
  String get printerReconnected => 'Reconnected';

  @override
  String get printerReconnectFailed => 'Reconnect failed';

  @override
  String get printerReconnect => 'Reconnect';

  @override
  String printerConnectedTo(Object name) {
    return 'Connected: $name';
  }

  @override
  String get printerTestPrint => 'Test Print';

  @override
  String get printerTestSent => 'Test print sent';

  @override
  String printerTestFailed(Object error) {
    return 'Test failed: $error';
  }

  @override
  String get printerBleDevices => 'BLE Devices';

  @override
  String get printerRescanBleTooltip => 'Rescan BLE';

  @override
  String get printerNoBleDevices => 'No BLE devices discovered.';

  @override
  String get printerUnknownName => 'Unknown Printer';

  @override
  String get printerConnect => 'Connect';

  @override
  String get printerClassicDevices => 'Paired Classic Devices';

  @override
  String get printerPaperSizeLabel => 'Paper size';

  @override
  String get printerPaper58mm => '58 mm';

  @override
  String get printerPaper80mm => '80 mm';

  @override
  String get printerPrintLogo => 'Print logo';

  @override
  String get printerPrintLogoHint =>
      'Disable this first if the printer prints gibberish near the top of the receipt.';

  @override
  String get printerRasterizeArabic => 'Rasterize Arabic text';

  @override
  String get printerRasterizeArabicHint =>
      'Needed for printers that cannot print Arabic natively.';

  @override
  String get printerRasterizeStyledText => 'Rasterize styled ASCII text';

  @override
  String get printerRasterizeStyledTextHint =>
      'Enable this only if your printer handles bitmap text reliably.';

  @override
  String get printerRasterWidthLabel => 'Raster width (px)';

  @override
  String get printerCodeTableLabel => 'Code table';

  @override
  String get printerBleChunkSizeLabel => 'BLE chunk size';

  @override
  String get printerBleChunkDelayLabel => 'BLE chunk delay (ms)';

  @override
  String get printerClassicChunkSizeLabel => 'Classic chunk size';

  @override
  String get printerClassicChunkDelayLabel => 'Classic chunk delay (ms)';

  @override
  String get printerClassicTailDelayLabel => 'Classic tail delay (ms)';

  @override
  String get printerRefreshClassicTooltip => 'Refresh Classic List';

  @override
  String get printerNoClassicDevices =>
      'No paired classic printers found. Ensure the printer is paired in System Bluetooth settings and that Location (Android 8) is enabled.';

  @override
  String printerClassicMacConnected(Object mac) {
    return '$mac  (Classic)';
  }

  @override
  String get printerDisconnect => 'Disconnect';

  @override
  String get printerConnectingClassic => 'Connecting (Classic)...';

  @override
  String printerLastSavedNotAdvertising(Object id) {
    return 'Last saved printer: $id\nIt is not currently advertising. You can still attempt to reconnect.';
  }

  @override
  String get branchFilterTitle => 'Filter Branches';

  @override
  String get branchFilterAllBranches => 'All Branches';

  @override
  String get branchFilterApply => 'Apply';

  @override
  String get websocketCollectCashTitle => 'Collect Cash';

  @override
  String get websocketCollectCashMessage =>
      'Collect the full order amount now from the Sales Partner courier.';

  @override
  String websocketInvoiceLabel(Object invoice) {
    return 'Invoice: $invoice';
  }

  @override
  String get systemStatusChecking => 'Checking...';

  @override
  String get systemStatusRealtime => 'Real-time';

  @override
  String get systemStatusNoRealtime => 'No real-time';

  @override
  String get systemStatusSynced => 'Synced';

  @override
  String systemStatusPendingCount(Object count) {
    return '$count pending';
  }

  @override
  String get systemStatusCouriers => 'Couriers';

  @override
  String systemStatusCourierCount(Object count) {
    return '$count couriers';
  }

  @override
  String get systemStatusPartnerChip => 'Partner';

  @override
  String get systemStatusSalesPartnerFallback => 'Sales Partner';

  @override
  String get systemStatusSyncComplete => 'Sync completed & couriers refreshed';

  @override
  String get systemStatusForceSyncTooltip => 'Force sync now';

  @override
  String get courierBalancesTitle => 'Courier Balances';

  @override
  String get courierBalancesEmpty => 'No couriers found.';

  @override
  String get courierBalancesSettledLabel => 'Settled';

  @override
  String get courierBalancesPayCourierLabel => 'Pay courier';

  @override
  String get courierBalancesCourierPaysUsLabel => 'Courier pays us';

  @override
  String courierBalancesDetailsTitle(Object courier) {
    return 'Details – $courier';
  }

  @override
  String courierBalancesCityOrderLine(
    Object city,
    Object order,
    Object shipping,
  ) {
    return 'City: $city\nOrder: $order • Shipping: $shipping';
  }

  @override
  String get courierBalancesNetLabel => 'Net';

  @override
  String get courierSettlementComplete => 'Settlement complete';

  @override
  String get courierSettlementFailed => 'Settlement failed';

  @override
  String get courierSettleButton => 'Settle';

  @override
  String courierPayCourierAmount(Object amount) {
    return 'Pay Courier $amount';
  }

  @override
  String courierCollectAmount(Object amount) {
    return 'Collect $amount';
  }

  @override
  String courierSettleAllInvoicesQuestion(int count) {
    return 'Settle all $count invoices for this courier?';
  }

  @override
  String get courierSettled => 'Settled';

  @override
  String get courierSettleAllButton => 'Settle All';

  @override
  String courierSettleAllDialogTitle(Object action, Object total) {
    return '$action - Total $total';
  }

  @override
  String courierSettleAllWillSettle(int count) {
    return 'This will settle $count invoice(s).';
  }

  @override
  String get courierInvoicesLabel => 'Invoices:';

  @override
  String get courierSettleAllCollectInfo =>
      'You will collect the net amount from the courier.';

  @override
  String get courierSettleAllPayInfo =>
      'You will pay the courier the net amount now.';

  @override
  String courierSettleAllComplete(int success, int failed) {
    return 'Settle All complete: $success ok, $failed failed';
  }

  @override
  String get courierBalancesPreviewTooltip => 'Preview settlement';

  @override
  String courierBalancesPreviewFailed(Object error) {
    return 'Failed to load settlement preview: $error';
  }

  @override
  String get settlementTitleCollectFromCourier => 'Collect From Courier';

  @override
  String get settlementTitlePayCourier => 'Pay Courier';

  @override
  String get settlementTitleCourierSettlement => 'Courier Settlement';

  @override
  String get settlementStatusUnpaid => 'Unpaid';

  @override
  String get settlementStatusPaid => 'Paid';

  @override
  String get settlementPaidNoteRecent => ' (just paid, treating as Unpaid)';

  @override
  String get settlementPaidNoteAfterOfd => ' (after OFD)';

  @override
  String get settlementPaidNoteAfterOfdUnpaid =>
      ' (paid after OFD, treated as Unpaid)';

  @override
  String settlementInvoiceStatus(Object status, Object note) {
    return 'Invoice is: $status$note';
  }

  @override
  String get settlementOnlineUnconfirmedNote =>
      'Customer pays online — the courier collected nothing. Only the shipping fee is settled here.';

  @override
  String get settlementCollectFormula => 'Collect (Order - Shipping):';

  @override
  String get settlementPayFormula => 'Pay the courier (Order - Shipping):';

  @override
  String get settlementNetToCollect => 'Net to Collect';

  @override
  String get settlementPayAmount => 'Pay Amount';

  @override
  String get settlementNothingToSettle => 'Nothing to pay or collect.';

  @override
  String settlementOrderLabel(Object amount) {
    return 'Order: $amount';
  }

  @override
  String settlementShippingLabel(Object amount) {
    return 'Shipping: $amount';
  }

  @override
  String settlementTerritoryLabel(Object territory) {
    return 'Territory: $territory';
  }

  @override
  String get cancelOrderTitle => 'Cancel Order';

  @override
  String cancelOrderInvoiceLabel(Object invoice) {
    return 'Invoice: $invoice';
  }

  @override
  String cancelOrderTotalLabel(Object amount) {
    return 'Total: $amount';
  }

  @override
  String cancelOrderOutstandingLabel(Object amount) {
    return 'Outstanding: $amount';
  }

  @override
  String get cancelOrderPartialPaymentWarning =>
      'This invoice has a partial payment. Please settle or refund the payment before cancelling.';

  @override
  String get cancelOrderReasonLabel => 'Cancellation reason';

  @override
  String get cancelOrderSelectReasonValidation => 'Select a reason to continue';

  @override
  String get cancelOrderProvideReasonValidation => 'Provide a reason';

  @override
  String get cancelOrderCustomReasonLabel => 'Custom reason';

  @override
  String get cancelOrderDescribeReasonValidation =>
      'Please describe the cancellation reason';

  @override
  String get cancelOrderAdditionalNotesOptional =>
      'Additional notes (optional)';

  @override
  String get cancelOrderCreditNoteInfo =>
      'The payment on this order will be reversed. Hand the money back to the customer before confirming.';

  @override
  String get cancelOrderConfirmButton => 'Confirm cancellation';

  @override
  String get invoicePreparingReceipt => 'Preparing receipt...';

  @override
  String invoiceItemsCount(int count) {
    return 'Items ($count)';
  }

  @override
  String get invoicePrinterNotConnectedHint =>
      'Printer not connected. Open Printer Selection from menu.';

  @override
  String get invoiceShareReceipt => 'Share receipt';

  @override
  String get invoiceSendReceiptWhatsApp => 'Send via WhatsApp';

  @override
  String get invoiceSendReceiptWhatsAppCustomer =>
      'WhatsApp to the customer’s number';

  @override
  String get invoiceReceiptImageReady =>
      'Receipt image ready — tap Send to share it';

  @override
  String get invoiceReceiptSendAction => 'Send';

  @override
  String get invoiceReceiptShareFailed => 'Could not share the receipt';

  @override
  String get invoiceWhatsAppOpenFailed => 'Could not open WhatsApp';

  @override
  String get invoicePrintedSuccessfully => 'Printed successfully';

  @override
  String get invoicePrinterDisconnected => 'Printer disconnected';

  @override
  String invoicePrintFailed(Object result) {
    return 'Print failed: $result';
  }

  @override
  String get invoiceAcceptOrderTitle => 'Accept Order';

  @override
  String invoiceAcceptOrderQuestion(Object invoice, Object customer) {
    return 'Accept order $invoice for $customer?';
  }

  @override
  String get invoiceAcceptAction => 'Accept';

  @override
  String invoiceOrderAccepted(Object invoice) {
    return 'Order $invoice accepted!';
  }

  @override
  String invoiceAcceptFailed(Object error) {
    return 'Failed to accept order: $error';
  }

  @override
  String get invoiceMoreOptions => 'More Options';

  @override
  String get invoiceAddNote => 'Notes';

  @override
  String get invoiceNotesTitle => 'Invoice Notes';

  @override
  String get invoiceNotesTooltip => 'View invoice notes';

  @override
  String get invoiceNotesHint => 'Add an operational note for this invoice';

  @override
  String get invoiceNotesEmpty => 'No notes yet for this invoice.';

  @override
  String get invoiceLatestNoteLabel => 'LATEST NOTE';

  @override
  String invoiceLatestNoteLabelWithCount(Object count) {
    return 'LATEST NOTE ($count)';
  }

  @override
  String get invoiceLatestNoteTapToRead =>
      'Tap to read the notes on this order';

  @override
  String get invoiceAddingNote => 'Adding...';

  @override
  String get invoiceNoteAdded => 'Note added';

  @override
  String invoiceNotesLoadFailed(Object error) {
    return 'Failed to load invoice notes: $error';
  }

  @override
  String invoiceNoteAddFailed(Object error) {
    return 'Failed to add note: $error';
  }

  @override
  String get invoiceEditInvoice => 'Edit Invoice';

  @override
  String get invoiceEditInvoiceFailed =>
      'Could not open the invoice draft. Please try again.';

  @override
  String get invoiceAmendmentUnavailable =>
      'Invoice amendment is not available for this order.';

  @override
  String get invoiceEditCustomerAddress => 'Edit Customer Address';

  @override
  String get invoiceChangeDeliverySlot => 'Change Delivery Slot';

  @override
  String get invoiceTransferOrder => 'Transfer Order';

  @override
  String get invoiceCancelOrderSettleFirst =>
      'Cancel Order (settle payments first)';

  @override
  String get invoiceCustomerLabel => 'Customer';

  @override
  String get invoiceShippingExpenseShort => 'Shipping Exp:';

  @override
  String get manufacturingTitle => 'Manufacturing';

  @override
  String get manufacturingManagersOnly => 'Managers only';

  @override
  String get manufacturingRecentWorkOrdersTooltip => 'Recent Work Orders';

  @override
  String get manufacturingSearchDefaultBom => 'Search items with Default BOM';

  @override
  String manufacturingWorkOrdersTitle(Object count) {
    return 'Work Orders ($count)';
  }

  @override
  String get manufacturingSubmitAll => 'Submit All';

  @override
  String get manufacturingNoItemsSelected => 'No items selected';

  @override
  String get manufacturingNoItemsFound => 'No items found';

  @override
  String manufacturingBomDescription(Object bom, Object quantity, Object uom) {
    return 'BOM: $bom • Yields $quantity $uom';
  }

  @override
  String get manufacturingBomLabel => 'BOM x';

  @override
  String get manufacturingRequiredItems => 'Required Items';

  @override
  String get manufacturingNothingToSubmit => 'Nothing to submit.';

  @override
  String get manufacturingSubmittingWorkOrders => 'Submitting work orders...';

  @override
  String manufacturingSubmitFailed(Object error) {
    return 'Submit failed: $error';
  }

  @override
  String get manufacturingSubmitAllSuccess => 'Submitted successfully';

  @override
  String manufacturingSubmitAllResult(Object success, Object total) {
    return 'Processed $total line(s). Success: $success';
  }

  @override
  String get manufacturingQuantityMustBePositive =>
      'Quantity must be greater than zero';

  @override
  String get manufacturingSubmittingSingleWorkOrder =>
      'Submitting work order...';

  @override
  String get manufacturingSubmitResult => 'Submitted';

  @override
  String manufacturingSubmitStatus(Object status) {
    return 'Status: $status';
  }

  @override
  String manufacturingSubmitWorkOrder(Object workOrder) {
    return ' • WO: $workOrder';
  }

  @override
  String manufacturingLoadFailed(Object error) {
    return 'Failed to load: $error';
  }

  @override
  String get manufacturingRecentWorkOrdersTitle => 'Recent Work Orders';

  @override
  String get manufacturingNoWorkOrders => 'No Work Orders found';

  @override
  String manufacturingRecentWorkOrderTitle(Object name, Object status) {
    return '$name • $status';
  }

  @override
  String manufacturingRecentWorkOrderSubtitle(
    Object bom,
    Object item,
    Object quantity,
  ) {
    return '$item • $quantity • $bom';
  }

  @override
  String manufacturingComponentAvailable(Object quantity, Object uom) {
    return 'Available: $quantity $uom';
  }

  @override
  String get manufacturingInsufficientInventory => 'Insufficient inventory';

  @override
  String get manufacturingSubmissionBlocked =>
      'Submission blocked until shortages are resolved.';

  @override
  String manufacturingLineShortageSummary(Object components, Object item) {
    return '$item: $components';
  }

  @override
  String manufacturingComponentRequired(Object quantity, Object uom) {
    return 'Required: $quantity $uom';
  }

  @override
  String manufacturingComponentMissing(Object quantity, Object uom) {
    return 'Missing: $quantity $uom';
  }

  @override
  String get menuProductionBoard => 'Production Board';

  @override
  String get productionBoardTitle => 'Production Board';

  @override
  String get productionTabPlan => 'Plan';

  @override
  String get dailyPlanNoItems => 'No fillable items have a default BOM yet.';

  @override
  String get dailyPlanNoMix => 'No cheesecake mix';

  @override
  String dailyPlanPerBatch(int count) {
    return '$count per batch';
  }

  @override
  String dailyPlanTotalJars(int count) {
    return '$count jars planned';
  }

  @override
  String get dailyPlanEnterQuantities =>
      'Enter how many jars you plan to fill.';

  @override
  String dailyPlanMixTotal(String qty, String uom, String batches) {
    return '$qty $uom of mix = $batches batches';
  }

  @override
  String get dailyPlanNoRuns =>
      'The mixer is not configured, so the split cannot be calculated.';

  @override
  String get dailyPlanRunPreferred => 'ideal';

  @override
  String get dailyPlanRunAcceptable => 'stretching';

  @override
  String get dailyPlanRunPoor => 'mixes badly';

  @override
  String dailyPlanSpareMix(String batches) {
    return '$batches batches of spare mix from rounding to whole runs.';
  }

  @override
  String get dailyPlanCheckMaterials => 'Check stock';

  @override
  String get dailyPlanSave => 'Save plan';

  @override
  String dailyPlanSaved(String name) {
    return 'Plan $name saved.';
  }

  @override
  String dailyPlanShortages(int count) {
    return '$count materials short';
  }

  @override
  String dailyPlanShortageLine(String item, String qty, String uom) {
    return '$item: $qty $uom short';
  }

  @override
  String dailyPlanShortagesMore(int count) {
    return 'and $count more';
  }

  @override
  String get dailyPlanMaterialsUnavailable =>
      'Stock could not be checked for this plan.';

  @override
  String dailyPlanBomIssues(int count) {
    return '$count BOMs need attention before the mix total is right';
  }

  @override
  String get dailyPlanBomIssuesTitle => 'BOM issues affecting the plan';

  @override
  String get productionAccessDenied => 'Production access required';

  @override
  String get productionSearchHint => 'Search items with a BOM';

  @override
  String get productionFilterAll => 'All';

  @override
  String get productionStatusCritical => 'Critical';

  @override
  String get productionStatusLow => 'Low';

  @override
  String get productionStatusOk => 'Covered';

  @override
  String get productionStatusOverstocked => 'Overstocked';

  @override
  String get productionStatusNoVelocity => 'No sales data';

  @override
  String get productionOnHand => 'On hand';

  @override
  String productionOnHandValue(Object quantity) {
    return '$quantity on hand';
  }

  @override
  String get productionRowDetails => 'Details';

  @override
  String get productionMoreActions => 'More actions';

  @override
  String productionFilterCount(String label, int count) {
    return '$label $count';
  }

  @override
  String get productionSellsPerDay => 'Sells / day';

  @override
  String get productionCover => 'Cover';

  @override
  String productionCoverDays(Object days) {
    return '$days d';
  }

  @override
  String get productionCoverUnknown => '—';

  @override
  String get productionTrend => 'Trend';

  @override
  String productionMakeBatches(Object batches, Object units, Object uom) {
    return 'Make $batches batches · $units $uom';
  }

  @override
  String productionReachCover(Object days) {
    return 'to reach $days days cover';
  }

  @override
  String productionCappedBy(Object capped, Object limiter, Object wanted) {
    return 'capped at $capped — $limiter is short (wanted $wanted)';
  }

  @override
  String productionSeasonApplied(Object name, Object value) {
    return 'Season $name: ×$value';
  }

  @override
  String get productionFillTheDay => 'Fill the day';

  @override
  String productionFillTheDaySkipped(Object skipped) {
    return '$skipped skipped — no materials';
  }

  @override
  String get productionFillTheDayNothing => 'Nothing to add';

  @override
  String get productionPlanQty => 'Jars';

  @override
  String get productionPlanWholeJarsOnly =>
      'Whole jars only. Mixes and cakes go on the Bases tab.';

  @override
  String productionUseSuggestion(Object units) {
    return 'Use $units';
  }

  @override
  String productionPlannedToday(Object count) {
    return 'Planned $count';
  }

  @override
  String get productionStartBatches => 'Start batches';

  @override
  String get productionPlanVsStart =>
      'Save plan records the target. Start batches moves stock.';

  @override
  String get productionOtherItems => 'Other items';

  @override
  String productionFillTheDayFilled(Object items, Object jars) {
    return 'Filled $items items · $jars jars';
  }

  @override
  String get productionPlanNothingQueued =>
      'Nothing to start yet — type a quantity or use a suggestion';

  @override
  String get productionNoSuggestions => 'Nothing needs producing';

  @override
  String get productionVelocityNever =>
      'Sales velocity has never been calculated — suggestions will stay empty until it runs';

  @override
  String productionVelocityUpdated(Object when) {
    return 'Velocity updated $when';
  }

  @override
  String productionBelowCover(Object count) {
    return '$count items below cover';
  }

  @override
  String get productionPostingDate => 'Production date';

  @override
  String get productionClearBasket => 'Clear';

  @override
  String get productionBatchesLabel => 'Batches';

  @override
  String get productionPickListTitle => 'Consolidated pick list';

  @override
  String productionPickListShort(Object quantity, Object uom) {
    return 'Short by $quantity $uom';
  }

  @override
  String get productionPickListOk => 'All materials available';

  @override
  String productionSharedAcrossLines(Object count) {
    return 'shared by $count lines';
  }

  @override
  String get productionSubmitting => 'Submitting…';

  @override
  String get productionScaleToFit => 'Reduce to what materials allow';

  @override
  String productionTargetDays(Object days) {
    return 'Target $days days';
  }

  @override
  String get productionNoSourceWarehouse => 'No source warehouse configured';

  @override
  String productionStockElsewhere(Object quantity, Object warehouse) {
    return '$quantity is in $warehouse — needs a stock transfer, not a purchase';
  }

  @override
  String productionStockElsewhereMore(
    Object count,
    Object quantity,
    Object warehouse,
  ) {
    return '$quantity is in $warehouse and $count more — needs a stock transfer, not a purchase';
  }

  @override
  String get productionStockNowhere =>
      'None of it in any other store — this one has to be bought';

  @override
  String get productionMoveStock => 'Move stock';

  @override
  String productionMoveTitle(Object item) {
    return 'Move $item';
  }

  @override
  String get productionMoveFromLabel => 'From';

  @override
  String get productionMoveToLabel => 'Into';

  @override
  String get productionMoveQtyLabel => 'Quantity to move';

  @override
  String productionMoveNeededChip(Object quantity) {
    return 'Needed ($quantity)';
  }

  @override
  String productionMoveAllChip(Object quantity) {
    return 'All ($quantity)';
  }

  @override
  String productionMoveAvailable(Object quantity) {
    return '$quantity here';
  }

  @override
  String get productionMoveConfirm => 'Move';

  @override
  String productionMoved(Object quantity, Object warehouse) {
    return 'Moved $quantity into $warehouse';
  }

  @override
  String productionMoveTooMuch(Object quantity) {
    return 'Only $quantity is in that store';
  }

  @override
  String get productionMoveHint =>
      'Moves stock between your own stores. Nothing is bought and nothing is used up.';

  @override
  String get productionMoveNoDestination =>
      'No store is set for this item, so there is nowhere to move it to';

  @override
  String productionBackDateWindow(Object days) {
    return 'Up to $days days back';
  }

  @override
  String get productionBackDateTodayOnly => 'Today only';

  @override
  String get productionRecordingPastDate =>
      'Recording production for a past date';

  @override
  String get productionNegativeStock => 'Stock is negative — count this item';

  @override
  String productionMakeUnits(Object units, Object uom) {
    return 'Make $units $uom';
  }

  @override
  String productionCannotStart(Object limiter) {
    return 'Cannot start — $limiter is short';
  }

  @override
  String productionBatchTotals(Object batches, Object units) {
    return '$batches batches · $units units';
  }

  @override
  String get productionTabRunning => 'Running';

  @override
  String get productionStart => 'Start batch';

  @override
  String get productionQuickProduce => 'Quick produce';

  @override
  String get productionFinish => 'Finish';

  @override
  String get productionFinishTitle => 'Finish batch';

  @override
  String get productionActualQty => 'Actual produced';

  @override
  String get productionScrapQty => 'Scrap / waste';

  @override
  String get productionBatchNotes => 'Notes';

  @override
  String productionActualExceedsPlanned(Object planned) {
    return 'More than the $planned planned';
  }

  @override
  String get productionQtyMustBePositive => 'Enter how much actually came out';

  @override
  String get productionRunningEmpty => 'No batches running';

  @override
  String productionRunningSince(Object when, Object who) {
    return 'Started $when by $who';
  }

  @override
  String productionElapsed(Object hours, Object minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String productionElapsedMinutes(Object minutes) {
    return '$minutes min';
  }

  @override
  String productionPlannedVsProduced(Object planned, Object produced) {
    return '$planned planned · $produced produced';
  }

  @override
  String productionWipLeftover(Object quantity, Object uom) {
    return '$quantity $uom left in WIP';
  }

  @override
  String get productionReturnToStore => 'Return to store';

  @override
  String get productionReturnedToStore => 'Material returned to store';

  @override
  String get productionCostTitle => 'Batch cost';

  @override
  String get productionMaterialCost => 'Materials';

  @override
  String get productionCostPerUnit => 'Per unit';

  @override
  String get productionStandardCost => 'Standard';

  @override
  String get productionVariance => 'Variance';

  @override
  String productionVarianceOver(Object percent) {
    return '$percent% over standard';
  }

  @override
  String productionVarianceUnder(Object percent) {
    return '$percent% under standard';
  }

  @override
  String get productionCostUnavailable => 'No cost yet — nothing produced';

  @override
  String get productionPrintBatchSheet => 'Print batch sheet';

  @override
  String get productionBackDateNotAllowed =>
      'You cannot post production on a past date';

  @override
  String productionStarted(Object workOrder) {
    return 'Batch started · $workOrder';
  }

  @override
  String productionFinished(Object quantity, Object uom) {
    return 'Batch finished · $quantity $uom';
  }

  @override
  String get productionNotStartedYet => 'This batch was never started';

  @override
  String get productionTabBases => 'Bases';

  @override
  String get basesHeaderHint =>
      'Bases never sell, so the plan cannot suggest them. Pick one and set how many batches to mix.';

  @override
  String get basesEmpty => 'No bases configured';

  @override
  String get productionTodayTitle => 'Today';

  @override
  String get productionTodaySubtitle =>
      'What is coming out of the kitchen today';

  @override
  String get productionTodayAdvancedBoard => 'Full board';

  @override
  String productionTodayOpenBatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count batches still open',
      one: '1 batch still open',
    );
    return '$_temp0';
  }

  @override
  String productionReturnLeftover(String qty, String uom) {
    return 'Send the $qty $uom left over back to the store';
  }

  @override
  String get productionReturnLeftoverHint =>
      'Leave this off if more is still coming out of this batch.';

  @override
  String get productionWipReturnFailed =>
      'The batch was recorded, but the leftover material could not be returned. It is still in WIP.';

  @override
  String get productionWipWentHome =>
      'Leftover material returned to the store.';

  @override
  String productionTodayTotalJars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jars recorded',
      one: '1 jar recorded',
    );
    return '$_temp0';
  }

  @override
  String get productionTodayEnterQuantities =>
      'Enter how many came out of the oven.';

  @override
  String get productionTodayBasesSection => 'Bases';

  @override
  String get productionTodayBasesHint => 'How many batches came out';

  @override
  String get productionTodayJarsSection => 'Jars';

  @override
  String get productionTodayJarsHint => 'How many jars came out';

  @override
  String productionTodayNeededToday(String batches) {
    return 'Needed today: $batches';
  }

  @override
  String productionTodayInFreezer(String batches) {
    return 'In freezer: $batches';
  }

  @override
  String productionTodayBlockedBy(String item) {
    return 'Not enough $item for a run';
  }

  @override
  String get productionTodayBlocked => 'Materials will not cover a run';

  @override
  String get productionTodayFieldBatches => 'batches';

  @override
  String get productionTodayFieldJars => 'jars';

  @override
  String get productionTodayMake => 'Make';

  @override
  String get productionTodaySaveForLater => 'Save for later';

  @override
  String get productionTodayPlanSavedShort => 'Saved for later';

  @override
  String productionTodayProduced(int produced, int total) {
    return '$produced of $total recorded';
  }

  @override
  String get productionTodayNothingProduced => 'Nothing was recorded';

  @override
  String productionTodayPlannedTarget(String jars) {
    return 'Today\'s target: $jars';
  }

  @override
  String productionTodayBasesNotLoaded(String items) {
    return 'Nothing was recorded. The base list is not loaded, so $items could not be matched to an item. Refresh and enter it again.';
  }

  @override
  String get productionTodayJarsSkipped =>
      'Jars were not recorded — the bases have to come out first.';

  @override
  String get productionTodayPlanSaveFailed =>
      'Production is recorded. The day\'s plan did not save.';

  @override
  String get productionPlanNotSaved => 'The days plan did not save.';

  @override
  String basesSummaryShort(Object count) {
    return '$count below what the jars need';
  }

  @override
  String basesSummaryBlocked(Object count) {
    return '$count blocked — no materials';
  }

  @override
  String basesBatchYield(Object quantity, Object uom) {
    return '1 batch = $quantity $uom';
  }

  @override
  String get basesInFreezer => 'In freezer';

  @override
  String basesBatchesValue(Object batches) {
    return '$batches batches';
  }

  @override
  String basesQtyValue(Object quantity, Object uom) {
    return '$quantity $uom';
  }

  @override
  String get basesCanMakeNow => 'Can make now';

  @override
  String basesDemandHint(Object needed, Object onHand) {
    return 'The plan needs $needed batches · you have $onHand';
  }

  @override
  String basesDemandDriver(Object driver) {
    return 'from $driver';
  }

  @override
  String basesUseBatches(Object batches) {
    return 'Use $batches';
  }

  @override
  String get basesRunSizes => 'Mixer runs';

  @override
  String get basesRunSizeOff =>
      'Not one of the mixer\'s usual runs — double-check before mixing';

  @override
  String basesMakes(Object quantity, Object uom) {
    return 'Makes $quantity $uom';
  }

  @override
  String get basesConsumes => 'Consumes';

  @override
  String basesEstimatedCost(Object amount) {
    return 'Est. materials $amount';
  }

  @override
  String get basesChecking => 'Checking materials…';

  @override
  String basesPreviewFailed(Object reason) {
    return 'Could not check materials — $reason';
  }

  @override
  String basesShortage(Object component, Object quantity, Object uom) {
    return '$component is short by $quantity $uom';
  }

  @override
  String basesReduceTo(Object batches) {
    return 'Reduce to $batches';
  }

  @override
  String get basesNothingPossible =>
      'Not enough materials for even half a batch';

  @override
  String get basesUsedPerDay => 'Used / day';

  @override
  String basesQtyPerDay(Object quantity, Object uom) {
    return '$quantity $uom/day';
  }

  @override
  String basesCoverSuggestion(Object batches, Object days) {
    return 'Make $batches batches to reach $days days cover';
  }

  @override
  String get basesNoConsumption =>
      'Nothing has drawn on this base yet — cover cannot be worked out';

  @override
  String basesInStoreValue(Object quantity, Object uom) {
    return '$quantity $uom in store';
  }

  @override
  String get basesGroupMixes => 'Mixes';

  @override
  String get basesGroupMixesHint => 'Made by the kilo — enter jars or weight';

  @override
  String get basesGroupBatches => 'Cakes & biscuits';

  @override
  String get basesGroupBatchesHint => 'Made in batches — counted in eggs';

  @override
  String get basesJarsToFill => 'Jars to fill';

  @override
  String basesPerJar(Object quantity, Object uom) {
    return '$quantity $uom each';
  }

  @override
  String basesJarNeedShort(String needed, String uom, String gap) {
    return 'Those jars need $needed $uom — $gap more than the store holds';
  }

  @override
  String basesJarNeedCovered(Object needed, Object uom) {
    return 'Those jars need $needed $uom — the store already covers it';
  }

  @override
  String get basesMakeLabel => 'Make';

  @override
  String basesUseQty(Object quantity, Object uom) {
    return 'Make $quantity $uom';
  }

  @override
  String basesCountedValue(Object count, Object unit) {
    return '$count $unit';
  }

  @override
  String basesCountedPerBatch(Object count, Object unit) {
    return 'One batch = $count $unit';
  }

  @override
  String basesCountedAndBatches(String count, String unit, String batches) {
    return '$count $unit · $batches batches';
  }

  @override
  String basesReduceToQty(Object quantity, Object uom) {
    return 'Make $quantity $uom instead';
  }

  @override
  String get basesNothingToMake => 'Nothing set to make yet';

  @override
  String basesMakeMixes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Make $count mixes',
      one: 'Make 1 mix',
    );
    return '$_temp0';
  }

  @override
  String basesStartBatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Start $count batches',
      one: 'Start 1 batch',
    );
    return '$_temp0';
  }

  @override
  String basesMakeBoth(int mixes, int batches) {
    return 'Make $mixes · start $batches';
  }

  @override
  String basesSelectedShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count picks are short of materials — untick them to make the rest',
      one: '1 pick is short of materials — untick it to make the rest',
    );
    return '$_temp0';
  }

  @override
  String basesSelectedEmpty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count picks have no amount yet',
      one: '1 pick has no amount yet',
    );
    return '$_temp0';
  }

  @override
  String get basesMixedNote =>
      'Mixes are booked as made · batches go to Running to be finished';

  @override
  String get basesCatalogueStale =>
      'The base list has moved on — pull to refresh and try again';

  @override
  String basesReportMade(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mixes made',
      one: '1 mix made',
    );
    return '$_temp0';
  }

  @override
  String basesReportStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count batches started — finish them on Running',
      one: '1 batch started — finish it on Running',
    );
    return '$_temp0';
  }

  @override
  String basesReportFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count failed',
      one: '1 failed',
    );
    return '$_temp0';
  }

  @override
  String get sopTitle => 'Work instructions';

  @override
  String get sopViewSop => 'View SOP';

  @override
  String get sopNoSopForItem => 'No work instructions for this item';

  @override
  String sopStepOf(Object current, Object total) {
    return 'Step $current of $total';
  }

  @override
  String get sopNext => 'Next';

  @override
  String get sopPrevious => 'Back';

  @override
  String get sopConfirmStep => 'Done';

  @override
  String get sopCaptureNumber => 'Enter the reading';

  @override
  String get sopCaptureTemperature => 'Enter the temperature';

  @override
  String get sopCapturePhoto => 'Take a photo';

  @override
  String get sopCaptureRequired => 'Record this before continuing';

  @override
  String sopCaptureOutOfRange(Object from, Object to) {
    return 'Allowed range $from to $to';
  }

  @override
  String sopDurationMins(Object minutes) {
    return '$minutes min';
  }

  @override
  String sopTotalDuration(Object minutes) {
    return 'About $minutes min total';
  }

  @override
  String sopScaledFor(Object batches) {
    return 'Scaled for $batches batches';
  }

  @override
  String sopForJars(Object count) {
    return 'For $count jars';
  }

  @override
  String get sopEquipment => 'Equipment';

  @override
  String sopExpectedYield(Object percent) {
    return 'Expected yield $percent%';
  }

  @override
  String sopVersionLabel(Object version) {
    return 'Version $version';
  }

  @override
  String get sopFinishExecution => 'Finish instructions';

  @override
  String get sopExitConfirm =>
      'Leave the instructions? Your place is not saved.';

  @override
  String sopUnresolvedTokens(Object count) {
    return '$count instruction reference(s) could not be resolved';
  }

  @override
  String get sopPhotoCaptured => 'Photo recorded';

  @override
  String get sopCameraPermissionDenied =>
      'Camera permission is needed to record a photo';

  @override
  String get sopPhotoEmpty => 'Couldn\'t read that photo. Take it again.';

  @override
  String get sopImageUnavailable =>
      'Image unavailable — you may not have access to it';

  @override
  String get stockTransferTitle => 'Stock Transfer';

  @override
  String get stockTransferManagersOnly => 'Managers only';

  @override
  String stockTransferLinesTitle(Object count) {
    return 'Transfer Lines ($count)';
  }

  @override
  String stockTransferPostingChip(Object date) {
    return 'Posting: $date';
  }

  @override
  String get stockTransferSubmit => 'Submit';

  @override
  String get stockTransferProfilesMustDiffer => 'Source and Target must differ';

  @override
  String get stockTransferProfileLabelSource => 'Source';

  @override
  String get stockTransferProfileLabelTarget => 'Target';

  @override
  String get stockTransferProfilePlaceholder => 'Select POS Profile';

  @override
  String stockTransferProfileOption(Object profile, Object warehouse) {
    return '$profile • $warehouse';
  }

  @override
  String get stockTransferProfileWarehouseFallback => 'No warehouse';

  @override
  String get stockTransferSelectBranches => 'Select source and target branches';

  @override
  String get stockTransferSameProfile => 'Source and Target cannot be the same';

  @override
  String stockTransferAvailability(Object source, Object target) {
    return 'Src: $source • Dst: $target';
  }

  @override
  String stockTransferReservedSource(Object reservedSource) {
    return ' • Res Src: $reservedSource';
  }

  @override
  String stockTransferReservedTarget(Object reservedTarget) {
    return ' • Res Dst: $reservedTarget';
  }

  @override
  String get stockTransferPosTag => ' • POS';

  @override
  String get stockTransferPostingToday => 'Posting Date: Today';

  @override
  String stockTransferPostingDate(Object date) {
    return 'Posting Date: $date';
  }

  @override
  String get stockTransferUseToday => 'Use Today';

  @override
  String get stockTransferNoLines => 'No lines';

  @override
  String stockTransferBeforeBase(Object source, Object target) {
    return 'Before — Src: $source • Dst: $target';
  }

  @override
  String stockTransferAfterBase(Object source, Object target) {
    return 'After  — Src: $source • Dst: $target';
  }

  @override
  String stockTransferTransferCreated(Object stockEntry) {
    return 'Transfer created: $stockEntry';
  }

  @override
  String stockTransferSubmitFailed(Object error) {
    return 'Failed: $error';
  }

  @override
  String stockTransferBulkAddFailed(Object error) {
    return 'Bulk add failed: $error';
  }

  @override
  String get stockTransferQuickQuantity => 'Quick quantity';

  @override
  String get stockTransferQuantityPerItem => 'Quantity for each item';

  @override
  String get stockTransferItemGroup => 'Item Group';

  @override
  String get stockTransferAllGroups => 'All Groups';

  @override
  String get stockTransferAddAll => 'Add All';

  @override
  String get stockTransferAddGroup => 'Add Group';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonPaste => 'Paste';

  @override
  String get commonDismiss => 'Dismiss';

  @override
  String get commonSave => 'Save';

  @override
  String get paymentMethodSelectTitle => 'Select Payment Method';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodCard => 'Card';

  @override
  String get paymentMethodInstapay => 'Instapay';

  @override
  String get paymentMethodMobileWallet => 'Mobile Wallet';

  @override
  String get paymentMethodSettleLater => 'Settle Later';

  @override
  String get paymentMethodOnline => 'Online';

  @override
  String get checkoutTotal => 'Total:';

  @override
  String get checkoutPay => 'Pay';

  @override
  String get checkoutSelectProfileFirst => 'Select POS profile first';

  @override
  String get checkoutOrderSuccess => 'Order completed successfully!';

  @override
  String checkoutFailed(Object error) {
    return 'Checkout failed: $error';
  }

  @override
  String get salesPartnerTitle => 'Sales Partner';

  @override
  String get salesPartnerSearchHint => 'Search partner';

  @override
  String get salesPartnerNotFound => 'No partners found';

  @override
  String get itemGridBundles => 'Bundles';

  @override
  String get itemGridAll => 'All';

  @override
  String get itemGridUncategorized => 'Uncategorized';

  @override
  String get itemGridSelectCustomerWarning => 'Please select a customer first';

  @override
  String get itemGridNoItemsFound => 'No items found';

  @override
  String get itemGridNoItemsAvailable => 'No items available';

  @override
  String get itemGridTryDifferentCategory => 'Try a different category';

  @override
  String get itemGridItemsWillAppear => 'Items will appear here';

  @override
  String get itemGridFreeDelivery => 'Free delivery';

  @override
  String itemGridBundlesCount(Object count) {
    return '$count bundles';
  }

  @override
  String itemGridItemsCount(Object count) {
    return '$count items';
  }

  @override
  String itemGridInCart(Object count) {
    return 'In cart: $count';
  }

  @override
  String get itemGridAddedToCart => 'Added to cart';

  @override
  String get itemGridSelectCustomerFirst => 'Select customer first';

  @override
  String get itemGridOutOfStock => 'Out of stock';

  @override
  String get itemGridCannotAdd => 'Cannot add item';

  @override
  String get kanbanFilterTitle => 'Filters';

  @override
  String kanbanFilterActiveCount(Object count) {
    return '$count active';
  }

  @override
  String get kanbanFilterClearAll => 'Clear All';

  @override
  String get kanbanFilterSearch => 'Search';

  @override
  String get kanbanFilterSearchHint => 'Order #, customer, or phone';

  @override
  String kanbanFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matching orders',
      one: '1 matching order',
      zero: 'No matching orders',
    );
    return '$_temp0';
  }

  @override
  String get kanbanFilterDone => 'Done';

  @override
  String get kanbanFilterDateToday => 'Today';

  @override
  String get kanbanFilterDateLast7Days => 'Last 7 days';

  @override
  String get kanbanFilterDateLast30Days => 'Last 30 days';

  @override
  String get kanbanFilterDateThisMonth => 'This month';

  @override
  String get kanbanFilterDateCustom => 'Custom range…';

  @override
  String get kanbanFilterAllCustomers => 'All Customers';

  @override
  String get kanbanFilterAllStatuses => 'All Statuses';

  @override
  String get kanbanFilterDateRange => 'Date Range';

  @override
  String get kanbanFilterFromDate => 'From Date';

  @override
  String get kanbanFilterToDate => 'To Date';

  @override
  String get kanbanFilterAllDates => 'All Dates';

  @override
  String get kanbanFilterAmountRange => 'Amount Range';

  @override
  String get kanbanFilterMinAmount => 'Min Amount';

  @override
  String get kanbanFilterMaxAmount => 'Max Amount';

  @override
  String get kanbanFilterAllAmounts => 'All Amounts';

  @override
  String get kanbanFilterActiveLabel => 'Active Filters:';

  @override
  String get kanbanFilterByBranches => 'Filter by Branches';

  @override
  String get kanbanFilterCustomerTitle => 'Customer';

  @override
  String get kanbanFilterCustomerName => 'Customer name';

  @override
  String get kanbanFilterCustomerHint => 'Enter customer name';

  @override
  String get kanbanFilterStatusTitle => 'Status';

  @override
  String get kanbanFilterFromAmount => 'From Amount';

  @override
  String get kanbanFilterToAmount => 'To Amount';

  @override
  String get kanbanFilterApply => 'Apply';

  @override
  String get kanbanRefreshOrders => 'Refresh Orders';

  @override
  String get kanbanOrdersRefreshed => 'Orders refreshed';

  @override
  String get kanbanHideFilters => 'Hide Filters';

  @override
  String get kanbanShowFilters => 'Show Filters';

  @override
  String get kanbanMoreActions => 'More Actions';

  @override
  String get kanbanMenu => 'Menu';

  @override
  String get kanbanMenuReceipts => 'Payment Receipts';

  @override
  String get kanbanMenuPrinters => 'Printers';

  @override
  String get kanbanMenuCouriers => 'Courier Balances';

  @override
  String get kanbanMenuProfile => 'Profile';

  @override
  String get kanbanMenuPos => 'Point of Sale';

  @override
  String get kanbanPaymentReceipts => 'Payment Receipts';

  @override
  String get kanbanCourierBalances => 'Courier Balances';

  @override
  String get kanbanUserProfile => 'User Profile';

  @override
  String get kanbanOpenPos => 'Open POS';

  @override
  String get kanbanTitleShort => 'Kanban';

  @override
  String get kanbanTitleFull => 'Sales Kanban';

  @override
  String get kanbanPrinterBle => 'BLE';

  @override
  String get kanbanPrinterClassic => 'Classic';

  @override
  String get kanbanPrinterConnecting => 'Connecting...';

  @override
  String get kanbanPrinterNotConnected => 'Not Connected';

  @override
  String get kanbanErrorLoadingData => 'Error loading data';

  @override
  String get kanbanNoColumnsConfigured => 'No columns configured';

  @override
  String get kanbanEnsureStateField =>
      'Ensure the state field is configured properly.';

  @override
  String get kanbanSelectPosProfileFirst => 'Select POS profile first';

  @override
  String get kanbanSelectPosProfile => 'Select POS Profile';

  @override
  String get kanbanNoPosProfiles => 'No POS profiles available';

  @override
  String kanbanWarehouse(Object warehouse) {
    return 'Warehouse: $warehouse';
  }

  @override
  String get kanbanCourierAndMode => 'Courier & Mode';

  @override
  String get kanbanNoCouriersAvailable => 'No couriers available';

  @override
  String get kanbanCreateCourierHint => 'Create a courier to proceed.';

  @override
  String get kanbanNewCourier => 'New Courier';

  @override
  String get kanbanFirstName => 'First Name';

  @override
  String get kanbanLastName => 'Last Name';

  @override
  String get kanbanPhone => 'Phone';

  @override
  String get kanbanType => 'Type';

  @override
  String get kanbanEmployee => 'Employee';

  @override
  String get kanbanSupplier => 'Supplier';

  @override
  String get kanbanBack => 'Back';

  @override
  String kanbanCreateFailed(Object error) {
    return 'Create failed: $error';
  }

  @override
  String get kanbanMode => 'Mode';

  @override
  String get kanbanPayNowCash => 'Pay Now (Cash)';

  @override
  String get kanbanSettleLater => 'Settle Later';

  @override
  String get kanbanSettleLaterSubtitle => 'Courier settles with branch later';

  @override
  String get kanbanContinue => 'Continue';

  @override
  String get kanbanSettleLaterMissingParty =>
      'Settle Later failed: courier party missing.';

  @override
  String get kanbanSettleLaterPreviewExpired =>
      'Settle Later: preview expired. Please retry.';

  @override
  String get kanbanSettleLaterFailed => 'Settle Later failed';

  @override
  String get kanbanMarkedSettleLater => 'Marked to Settle Later';

  @override
  String kanbanSettleLaterError(Object error) {
    return 'Settle Later error: $error';
  }

  @override
  String get kanbanSettlementMissingParty =>
      'Settlement failed: courier party missing.';

  @override
  String get kanbanPreviewExpired => 'Preview expired. Please retry.';

  @override
  String get kanbanConfirmingSettlement => 'Confirming settlement...';

  @override
  String get kanbanSettlementFailed => 'Settlement failed';

  @override
  String get kanbanSettlementConfirmed => 'Settlement confirmed';

  @override
  String kanbanSettlementError(Object error) {
    return 'Settlement error: $error';
  }

  @override
  String kanbanPreviewFailed(Object error) {
    return 'Preview failed: $error';
  }

  @override
  String get kanbanPickupNoSettlement =>
      'Pickup orders don\'t require settlement';

  @override
  String get kanbanCannotMoveBackward => 'Cannot move backward';

  @override
  String get kanbanCancelViaMenuOnly =>
      'Orders can\'t be cancelled by dragging. Use the card menu and pick \"Cancel Order\".';

  @override
  String get kanbanReturnViaMenuOnly =>
      'Orders can\'t be returned by dragging. Use the card menu and pick \"Return Order\".';

  @override
  String get kanbanFullyReturnedLocked =>
      'This order was fully returned and can no longer be moved.';

  @override
  String get kanbanPinBadgePinned => 'Pinned';

  @override
  String get kanbanPinBadgePinnedTooltip => 'This address has map coordinates';

  @override
  String get kanbanPinBadgeMissing => 'No map pin';

  @override
  String get kanbanPinBadgeMissingTooltip =>
      'No map pin yet — add the location link before dispatch';

  @override
  String get kanbanMoveOneStage => 'Can only move one stage at a time';

  @override
  String get kanbanAllBranches => 'All Branches';

  @override
  String kanbanBranchCount(Object count) {
    return '$count branches';
  }

  @override
  String get kanbanLoadingBranches => 'Loading branches...';

  @override
  String get kanbanTapToRefreshBalance => 'Tap to refresh balance';

  @override
  String get kanbanPressBackAgain => 'Press back again to exit';

  @override
  String get invoiceDeliveryAddress => 'Delivery Address';

  @override
  String get invoiceItems => 'Items';

  @override
  String get invoiceNetTotal => 'Net Total';

  @override
  String get invoiceShippingIncome => 'Shipping Income';

  @override
  String get invoiceShippingExpense => 'Shipping Expense';

  @override
  String get invoiceGrandTotal => 'Grand Total';

  @override
  String invoiceAlreadyStatus(Object status) {
    return 'Invoice already $status';
  }

  @override
  String get invoiceSelectPaymentMethod => 'Select Payment Method';

  @override
  String get invoiceWallet => 'Wallet';

  @override
  String get invoiceSubmit => 'Submit';

  @override
  String get invoiceNoPosProfileCash =>
      'No POS profile selected for Cash payment';

  @override
  String invoiceProcessingPayment(Object method) {
    return 'Processing $method payment...';
  }

  @override
  String invoicePaymentSuccess(Object entry) {
    return 'Payment successful ($entry)';
  }

  @override
  String get invoiceReceiptAmountWarning =>
      'Warning: Could not get payment amount for receipt';

  @override
  String get invoiceReceiptNoPosProfile =>
      'Warning: No POS profile found - receipt not created. Please select a POS profile.';

  @override
  String invoiceReceiptCreated(Object receipt) {
    return 'Payment receipt created ($receipt) - please upload receipt image from header';
  }

  @override
  String invoiceReceiptReturnedWarning(Object message) {
    return 'Warning: Receipt creation returned: $message';
  }

  @override
  String invoiceReceiptCreationFailed(Object error) {
    return 'Warning: Receipt creation failed: $error';
  }

  @override
  String get invoicePaymentFailed => 'Payment failed';

  @override
  String get transferProofTitle => 'Transfer screenshot';

  @override
  String get transferProofIntro =>
      'InstaPay and wallet payments are recorded only after a manager confirms the customer transfer screenshot.';

  @override
  String get transferProofAmountLabel => 'Amount to be paid';

  @override
  String get transferProofMethodLabel => 'Payment method';

  @override
  String get transferProofAlreadyUploaded =>
      'A screenshot is already attached and waiting for confirmation. You can continue with it or replace it.';

  @override
  String get transferProofRejected =>
      'The previous screenshot was rejected. Attach a new one.';

  @override
  String get transferProofChecking => 'Checking the receipt…';

  @override
  String get transferProofReceiptChanged =>
      'This receipt changed since the board loaded. Close and press Pay again.';

  @override
  String transferProofRejectedReason(String reason) {
    return 'The previous screenshot was rejected: $reason. Attach a new one.';
  }

  @override
  String get transferProofAttach => 'Attach screenshot';

  @override
  String get transferProofImageSelected => 'New screenshot selected';

  @override
  String get transferProofSend => 'Send screenshot';

  @override
  String get transferProofContinue => 'Continue with this screenshot';

  @override
  String get transferProofSending => 'Sending screenshot...';

  @override
  String get transferProofConfirming => 'Confirming transfer...';

  @override
  String get transferProofConfirmTitle => 'Did the transfer arrive?';

  @override
  String transferProofConfirmBody(String amount) {
    return 'Open the company bank account and check that the transfer of $amount has arrived. Confirm only if you can see it.';
  }

  @override
  String get transferProofConfirmYes => 'Yes, it arrived. Confirm and pay';

  @override
  String get transferProofConfirmNo => 'Not yet';

  @override
  String transferProofAwaitingManager(String method) {
    return 'Screenshot sent. A manager must confirm it in Payment Receipts, then press Pay and choose $method again.';
  }

  @override
  String get transferProofAwaitingConfirmation =>
      'Screenshot saved. The receipt is waiting for confirmation, so no payment was recorded yet. Press Pay again once the transfer is confirmed.';

  @override
  String invoicePaymentError(Object error) {
    return 'Payment error: $error';
  }

  @override
  String get invoiceCollectCashTitle => 'Collect Cash';

  @override
  String invoiceCollectCashBody(Object amount, Object invoiceId) {
    return 'Please collect from the customer:\n\nTotal Amount: $amount EGP\n\nThis includes:\n• Order items\n• Shipping fee\n\nInvoice: $invoiceId';
  }

  @override
  String get invoiceSelectPosFirst => 'Select POS profile first';

  @override
  String get invoiceChangeCollectionMethod => 'Change collection method';

  @override
  String get invoiceRequestedPaymentMethod => 'Requested method';

  @override
  String get invoiceActualCollectionMethod => 'Actual collection';

  @override
  String get invoiceCollectionReferenceLabel => 'Reference number';

  @override
  String get invoiceCollectionReferenceRequired =>
      'Online collection requires a reference number.';

  @override
  String get invoiceCollectionCashAtBranchNotice =>
      'The courier for this order has already closed out, so this cash is recorded as received at the branch and will be expected in the drawer at the next count.';

  @override
  String get invoiceChangingCollectionMethod => 'Changing collection method...';

  @override
  String invoiceCollectionMethodChanged(Object method) {
    return 'Collection method changed to $method';
  }

  @override
  String invoiceCollectionMethodChangeError(Object error) {
    return 'Collection method error: $error';
  }

  @override
  String get invoiceCollectingCashPartner =>
      'Collecting cash & dispatching (Sales Partner)...';

  @override
  String get invoiceCashCollectedOfd =>
      'Cash collected & sent Out For Delivery';

  @override
  String invoiceOfdFailed(Object error) {
    return 'Failed: $error';
  }

  @override
  String invoiceOfdError(Object error) {
    return 'Error: $error';
  }

  @override
  String get invoiceSentOfd => 'Sent Out For Delivery (DN will be created)';

  @override
  String invoiceActionFailed(Object error) {
    return 'Action failed: $error';
  }

  @override
  String get invoiceSettleLaterMissingParty =>
      'Settle Later failed: courier party missing.';

  @override
  String get invoiceMarkedSettleLater => 'Marked to Settle Later';

  @override
  String get invoiceSettleLaterFailed => 'Settle Later failed';

  @override
  String invoiceSettleLaterError(Object error) {
    return 'Settle Later error: $error';
  }

  @override
  String get invoiceSettlementMissingParty =>
      'Settlement failed: courier party missing.';

  @override
  String get invoicePreviewExpired => 'Preview expired. Please retry.';

  @override
  String get invoiceConfirmingSettlement => 'Confirming settlement...';

  @override
  String get invoiceSettlementConfirmed => 'Settlement confirmed';

  @override
  String get invoiceSettlementFailed => 'Settlement failed';

  @override
  String invoiceSettlementError(Object error) {
    return 'Settlement error: $error';
  }

  @override
  String get invoiceProcessingDelivery => 'Processing Delivery...';

  @override
  String get invoiceUpdated => 'Updated';

  @override
  String get customerShippingAddressTitle => 'Choose Shipping Address';

  @override
  String get customerShippingAddressSubtitle =>
      'Select a saved shipping address or add a new one for this customer.';

  @override
  String get customerShippingAddressSavedTab => 'Saved Addresses';

  @override
  String get customerShippingAddressNewTab => 'Add New Address';

  @override
  String get customerShippingAddressEmpty => 'No saved shipping addresses yet.';

  @override
  String get customerShippingAddressSelectRequired =>
      'Choose a shipping address or add a new one.';

  @override
  String get customerShippingAddressLoadFailed =>
      'Failed to load shipping addresses.';

  @override
  String get customerShippingAddressEditTab => 'Edit Address';

  @override
  String get customerShippingAddressEditTitle => 'Edit Shipping Address';

  @override
  String get customerShippingAddressDeleteConfirm =>
      'Delete this address? This cannot be undone.';

  @override
  String get customerShippingAddressDeleteSuccess => 'Address deleted.';

  @override
  String get customerShippingAddressDeleteFailed => 'Failed to delete address.';

  @override
  String get customerShippingAddressUpdateSuccess => 'Address updated.';

  @override
  String get customerShippingAddressUpdateFailed => 'Failed to update address.';

  @override
  String get customerShippingAddressLine1Label => 'Address Line 1';

  @override
  String get customerShippingAddressLine2Label => 'Address Line 2 (optional)';

  @override
  String get customerShippingAddressTerritoryLabel => 'Territory';

  @override
  String get customerShippingAddressPincodeLabel => 'Postal Code (optional)';

  @override
  String get customerShippingAddressTerritoryRequired =>
      'Please select a territory.';

  @override
  String get customerShippingAddressLine1Required =>
      'Address line 1 is required.';

  @override
  String get customerShippingAddressBranchNameLabel => 'Delivery branch name';

  @override
  String get customerShippingAddressBranchNameRequired =>
      'Enter a delivery branch name.';

  @override
  String get customerShippingAddressTerritoryMissing =>
      'Edit this branch and choose its delivery territory before ordering.';

  @override
  String get posAmendmentDraftTitle => 'Invoice amendment draft';

  @override
  String get posAmendmentDraftMessage =>
      'Review the changes carefully, then submit to replace the original invoice.';

  @override
  String get posAmendmentCheckoutBlocked =>
      'Amendment submission is unavailable for this draft. Return to the order and reopen the amendment.';

  @override
  String get invoiceDeliveryFailed => 'Delivery action failed';

  @override
  String invoiceDeliveryError(Object error) {
    return 'Error: $error';
  }

  @override
  String get invoiceDeliveryTitle => 'Delivery';

  @override
  String get invoiceUnpaidWarning =>
      'Invoice is UNPAID. Choose Courier Collects Cash Now to record a cash payment before marking Out For Delivery.';

  @override
  String get invoiceCannotSettleParty =>
      'Cannot settle: courier party not resolved. Assign courier or retry.';

  @override
  String get invoiceNothingToSettle => 'Nothing to settle';

  @override
  String get invoiceSettlementComplete => 'Settlement complete';

  @override
  String get invoiceEditAddress => 'Edit Customer Address';

  @override
  String get invoicePhoneNumber => 'Phone Number';

  @override
  String get invoiceDeliveryAddressLabel => 'Delivery Address';

  @override
  String get invoiceAddressHelper => 'Enter the full delivery address';

  @override
  String get invoiceAddressUpdateInfo =>
      'This will update the customer\'s default address and phone number.';

  @override
  String get invoiceAddressEmpty => 'Address cannot be empty';

  @override
  String get invoiceUpdatingAddress => 'Updating customer address...';

  @override
  String get invoiceAddressUpdated => 'Customer address updated successfully';

  @override
  String invoiceAddressUpdatedWithShipping(
    Object oldExpense,
    Object newExpense,
  ) {
    return 'Address updated. Shipping: $oldExpense → $newExpense EGP';
  }

  @override
  String get invoiceAddressUpdateFailed => 'Failed to update address';

  @override
  String invoiceCopiedNumber(Object number) {
    return 'Copied: $number';
  }

  @override
  String get invoiceCopy => 'Copy';

  @override
  String get invoiceCannotCall => 'Unable to make phone call';

  @override
  String get invoiceCall => 'Call';

  @override
  String get invoiceSettleBeforeCancel =>
      'Settle or refund partial payments before cancelling this order.';

  @override
  String get invoiceCancelFailed => 'Failed to cancel order. Please try again.';

  @override
  String invoiceCancelledWithCn(Object creditNote) {
    return 'Order cancelled. Credit note $creditNote created.';
  }

  @override
  String get invoiceCancelledSuccess => 'Order cancelled successfully.';

  @override
  String get invoiceNoPosProfile => 'No POS profile selected';

  @override
  String get invoiceAssignBranch => 'Assign to Branch';

  @override
  String invoiceCustomerName(Object name) {
    return 'Customer: $name';
  }

  @override
  String invoiceInvoiceLabel(Object name) {
    return 'Invoice: $name';
  }

  @override
  String get invoiceTransferInfo =>
      'The order will be moved to the selected branch and reset to Received state.';

  @override
  String get invoiceTransferring => 'Transferring order...';

  @override
  String invoiceTransferSuccess(Object branch) {
    return 'Order transferred successfully to $branch';
  }

  @override
  String get invoiceTransferFailed => 'Transfer failed. Please try again.';

  @override
  String get invoiceCannotDetermineProfile =>
      'Unable to determine POS profile for this invoice';

  @override
  String get invoiceLoadingSlots => 'Loading delivery slots...';

  @override
  String get invoiceNoSlots => 'No delivery slots available for this branch';

  @override
  String get invoiceChangeSlot => 'Change Delivery Slot';

  @override
  String invoiceCurrentSlot(Object slot) {
    return 'Current: $slot';
  }

  @override
  String get invoiceSlotUpdateInfo =>
      'The delivery slot will be updated for this order.';

  @override
  String get invoiceNoChanges => 'No changes made';

  @override
  String get invoiceUpdatingSlot => 'Updating delivery slot...';

  @override
  String invoiceSlotUpdated(Object slot) {
    return 'Delivery slot updated to $slot';
  }

  @override
  String get invoiceSlotUpdateFailed => 'Failed to update delivery slot';

  @override
  String get tripsDeliveryTripsTitle => 'Delivery Trips';

  @override
  String get tripsActiveTab => 'Active';

  @override
  String get tripsCompletedTab => 'Completed';

  @override
  String get tripsCreateTripTitle => 'Create Delivery Trip';

  @override
  String get tripsCreateTripButton => 'Create Trip';

  @override
  String tripsCreateTripFailed(Object error) {
    return 'Failed to create trip: $error';
  }

  @override
  String get tripsOrdersLabel => 'Orders';

  @override
  String get tripsTotalAmount => 'Total Amount';

  @override
  String get tripsTotalShipping => 'Total Shipping';

  @override
  String tripsSameTerritory(Object territory) {
    return 'Same territory: $territory';
  }

  @override
  String get tripsSelectCourier => 'Select Courier';

  @override
  String get tripsNoTrips => 'No trips';

  @override
  String tripsOrdersCount(Object count) {
    return '$count orders';
  }

  @override
  String get tripsDoubleShippingLabel => 'Double Shipping';

  @override
  String get tripsNotesLabel => 'Notes';

  @override
  String get tripsMarkTripAsDeliveredTitle => 'Mark Trip as Delivered';

  @override
  String tripsMarkTripAsDeliveredContent(Object tripName, Object count) {
    return 'Mark \"$tripName\" with $count orders as delivered?';
  }

  @override
  String tripsTripMarkedAsDelivered(Object tripName) {
    return '$tripName marked as delivered';
  }

  @override
  String tripsFailed(Object error) {
    return 'Failed: $error';
  }

  @override
  String get tripsSendForDeliveryTitle => 'Send for Delivery';

  @override
  String tripsSendForDeliveryContent(Object count, Object courierName) {
    return 'Send $count orders for delivery?\n\nCourier: $courierName';
  }

  @override
  String get tripsSentForDeliverySuccess => 'Trip sent for delivery';

  @override
  String get tripsMarkAsDeliveredButton => 'Mark as Delivered';

  @override
  String tripsMarkAllAsDeliveredContent(Object count) {
    return 'Mark all $count orders as delivered?\n\nThis will complete the trip.';
  }

  @override
  String get tripsTripMarkedSuccess => 'Trip marked as delivered';

  @override
  String get tripsSending => 'Sending...';

  @override
  String get tripsMarking => 'Marking...';

  @override
  String tripsSubTerritoryRequired(Object invoices) {
    return 'Please select a sub-territory for the following orders before creating a trip: $invoices';
  }

  @override
  String tripsInvoicesCount(Object count) {
    return 'Invoices ($count)';
  }

  @override
  String get subTerritorySelectTitle => 'Select Sub-territory';

  @override
  String subTerritoryForTerritory(Object territory) {
    return 'for $territory';
  }

  @override
  String get subTerritoryNoResults => 'No sub-territories found';

  @override
  String get subTerritoryLoadFailed => 'Failed to load sub-territories';

  @override
  String get customShippingBadgePending => 'Custom shipping pending';

  @override
  String get customShippingBadgeApproved => 'Custom shipping approved';

  @override
  String customShippingBadgeAmount(Object amount) {
    return 'Custom shipping $amount';
  }

  @override
  String get customShippingBadgeRejected => 'Custom shipping rejected';

  @override
  String get returnBadgeFull => 'Returned';

  @override
  String get returnBadgePartial => 'Partially returned';

  @override
  String returnBadgeFullAmount(Object amount) {
    return 'Returned $amount';
  }

  @override
  String returnBadgePartialAmount(Object amount) {
    return 'Partially returned $amount';
  }

  @override
  String get receiptSelectImageSource => 'Select Image Source';

  @override
  String get receiptCamera => 'Camera';

  @override
  String get receiptGallery => 'Gallery';

  @override
  String get receiptUploading => 'Uploading receipt image...';

  @override
  String get receiptUploadedSuccess => 'Receipt image uploaded successfully';

  @override
  String get receiptUploadFailed => 'Failed to upload receipt image';

  @override
  String get receiptImageEmpty =>
      'Couldn\'t read that photo. Try again, or pick a different one.';

  @override
  String receiptUploadError(Object error) {
    return 'Error uploading image: $error';
  }

  @override
  String get receiptConfirming => 'Confirming receipt...';

  @override
  String get receiptConfirmedSuccess => 'Receipt confirmed successfully';

  @override
  String get receiptConfirmFailed => 'Failed to confirm receipt';

  @override
  String receiptConfirmError(Object error) {
    return 'Error confirming receipt: $error';
  }

  @override
  String get receiptAllProfiles => 'All Profiles';

  @override
  String get receiptFilterByPosProfile => 'Filter by POS Profile';

  @override
  String get receiptNoReceiptsFound => 'No payment receipts found';

  @override
  String get receiptUploadImageButton => 'Upload Receipt Image';

  @override
  String get receiptReplaceImageButton => 'Replace Image';

  @override
  String get receiptRemoveImageButton => 'Remove Image';

  @override
  String get receiptRemoveConfirmTitle => 'Remove receipt image?';

  @override
  String get receiptRemoveConfirmBody =>
      'The uploaded screenshot will be deleted. You can upload a new one afterwards.';

  @override
  String get receiptRemoving => 'Removing receipt image...';

  @override
  String get receiptRemovedSuccess => 'Receipt image removed';

  @override
  String get receiptRemoveFailed => 'Failed to remove receipt image';

  @override
  String receiptRemoveError(Object error) {
    return 'Error removing image: $error';
  }

  @override
  String get receiptPreviewTitle => 'Receipt Preview';

  @override
  String get receiptPreviewButton => 'Preview Receipt';

  @override
  String get commonPrint => 'Print';

  @override
  String get statusCreated => 'Created';

  @override
  String get statusOutForDelivery => 'Out for Delivery';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusReturn => 'Return';

  @override
  String get statusReturned => 'Returned';

  @override
  String get statusReturnedToSender => 'Returned to Sender';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusUnpaid => 'Unpaid';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusUnconfirmed => 'Unconfirmed';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusPendingApproval => 'Pending Approval';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusDraft => 'Draft';

  @override
  String get kanbanNoInvoices => 'No invoices';

  @override
  String get kanbanTripCreatedSuccess => 'Delivery trip created successfully';

  @override
  String kanbanPartOfTripWarning(Object tripName) {
    return 'This order is part of trip $tripName. Send the entire trip for delivery from the Trips screen.';
  }

  @override
  String get kanbanOfdAwaitingInstapay =>
      'Out for delivery — awaiting InstaPay';

  @override
  String kanbanOfdAwaitingInstapayWithCourier(Object courier) {
    return 'Out for delivery with $courier — awaiting InstaPay';
  }

  @override
  String get kanbanDeliveryPartnerCourier => 'Delivery Partner Courier';

  @override
  String get kanbanDeliveryPartnerCourierSubtitle =>
      'This courier belongs to a delivery partner';

  @override
  String get kanbanRequestCustomShipping => 'Request Custom Shipping';

  @override
  String get customShippingCurrentShipping => 'Current Shipping';

  @override
  String get customShippingRequestedAmount => 'Requested Amount';

  @override
  String get customShippingReasonHint => 'Why custom shipping is needed...';

  @override
  String get customShippingAmountRequired => 'Amount is required';

  @override
  String get customShippingAmountInvalid => 'Enter a valid positive amount';

  @override
  String get customShippingReasonRequired =>
      'Please provide a reason (min 10 characters)';

  @override
  String get customShippingSubmitRequest => 'Submit Request';

  @override
  String get kanbanCustomShippingSubmitted =>
      'Custom shipping request submitted';

  @override
  String kanbanCustomShippingFailed(Object error) {
    return 'Failed to submit request: $error';
  }

  @override
  String get settlementPartnerDeliveryTitle => 'Partner Delivery Settlement';

  @override
  String get settlementPartnerInfoTitle => 'Partner Settlement Info';

  @override
  String settlementPartnerLabel(Object name) {
    return 'Partner: $name';
  }

  @override
  String get settlementPartnerCollectFull =>
      'Collect full order amount from courier:';

  @override
  String get settlementPartnerOnlinePaid =>
      'Online-paid — no cash exchange with courier';

  @override
  String get settlementPartnerCollectFullChip => 'Collect (Full Amount)';

  @override
  String get settlementNoExchange => 'No Cash Exchange';

  @override
  String settlementPartnerFeeTracked(Object amount) {
    return 'Partner fee (tracked): $amount';
  }

  @override
  String get settlementPartnerCollectedFull =>
      'Collected full order amount from courier';

  @override
  String get settlementPartnerFullAmountChip => 'Full amount';

  @override
  String get settlementPartnerOnlinePaidInfo =>
      'Online paid — no cash exchange';

  @override
  String get managerPendingCustomShipping =>
      'Pending Custom Shipping Approvals';

  @override
  String get managerNoPendingRequests => 'No pending requests';

  @override
  String managerReasonLabel(Object reason) {
    return 'Reason: $reason';
  }

  @override
  String get managerCustomShippingApproved => 'Custom shipping approved';

  @override
  String managerApproveFailed(Object error) {
    return 'Approve failed: $error';
  }

  @override
  String get managerRejectCustomShippingTitle => 'Reject Custom Shipping';

  @override
  String get managerReject => 'Reject';

  @override
  String get managerCustomShippingRejected => 'Custom shipping rejected';

  @override
  String managerRejectFailed(Object error) {
    return 'Reject failed: $error';
  }

  @override
  String get managerRejectReasonHint => 'Optional rejection reason';

  @override
  String get managerPendingCustomShippingLoadFailed =>
      'Failed to load pending custom shipping requests';

  @override
  String get managerTransferBranchesLoadFailed =>
      'Failed to load transfer branches';

  @override
  String get managerApproveDefaultError => 'Unable to approve the request.';

  @override
  String get managerRejectDefaultError => 'Unable to reject the request.';

  @override
  String get purchaseNoInvoicesYet => 'No purchase invoices yet';

  @override
  String get purchaseReorderFromSupplier => 'Reorder the same purchase';

  @override
  String get purchaseHistoryTitle => 'Purchase History';

  @override
  String get posCreateCustomer => 'Create Customer';

  @override
  String get posCustomerCreatedSuccess => 'Customer created successfully!';

  @override
  String get settingsUserProfileTitle => 'User Profile';

  @override
  String get settingsRolesTitle => 'Roles';

  @override
  String get settingsNoRolesAssigned => 'No roles assigned';

  @override
  String get settingsNotificationSettings => 'Notification Settings';

  @override
  String get settingsNoAlarmSounds => 'No alarm sounds available';

  @override
  String get settingsAlarmSoundLabel => 'Alarm Sound';

  @override
  String settingsFailedToLoadAlarmSounds(Object error) {
    return 'Failed to load alarm sounds: $error';
  }

  @override
  String settingsAlarmSoundChanged(Object title) {
    return 'Alarm sound changed to $title';
  }

  @override
  String settingsAlarmSoundUnavailable(Object title) {
    return '$title can\'t be used on this device. Keeping the default alarm sound.';
  }

  @override
  String settingsCustomAlarmSoundSet(Object title) {
    return 'Custom alarm sound set: $title';
  }

  @override
  String get settingsNoFileSelected => 'No file selected';

  @override
  String get settingsBrowseCustomSoundFile => 'Browse Custom Sound File';

  @override
  String get settingsCustomSoundTitle => 'Custom Sound';

  @override
  String itemGridStockLimitReached(Object stockQty) {
    return 'Stock limit reached. Only $stockQty available.';
  }

  @override
  String get menuDeliveryTrips => 'Delivery Trips';

  @override
  String get authLoginTitle => 'Login';

  @override
  String get printingPrintersTitle => 'Printers';

  @override
  String get printingUseBitmapReceipt => 'Use new bitmap receipt';

  @override
  String get printingUseBitmapReceiptHint =>
      'Renders the full receipt as an image and helps with Arabic, missing data, and gibberish issues.';

  @override
  String kanbanOrdersSelectedCount(int count) {
    return '$count orders selected';
  }

  @override
  String get loginModeDialogTitle => 'Choose Login Mode';

  @override
  String get loginModeLineManager => 'Line Manager';

  @override
  String get loginModeLineManagerDesc =>
      'Skip shift opening — manage operations directly';

  @override
  String get loginModeEmployee => 'Employee';

  @override
  String get loginModeEmployeeDesc => 'Open a shift before starting work';

  @override
  String get customerSearchHint => 'Search by name or phone';

  @override
  String get customerSearchStartTyping =>
      'Start typing a name or phone number to find a customer';

  @override
  String get customerSearchNoResults => 'No customers found';

  @override
  String get customerSearchByPhone => 'Search by phone number...';

  @override
  String get customerSearchByName => 'Search by customer name...';

  @override
  String get quickAddCustomerTitle => 'Quick Add Customer';

  @override
  String get quickAddCustomerTap => 'Tap to create new customer';

  @override
  String get customerNameLabel => 'Customer Name *';

  @override
  String get customerNameRequired => 'Customer name is required';

  @override
  String get customerTypeLabel => 'Customer type';

  @override
  String get customerTypeIndividual => 'Individual';

  @override
  String get customerTypeCompany => 'Company';

  @override
  String get customerGroupLabel => 'Customer group';

  @override
  String get customerGroupRequired => 'Please select a customer group';

  @override
  String get mobileNumberLabel => 'Mobile Number *';

  @override
  String get mobileNumberRequired => 'Mobile number is required';

  @override
  String get secondaryPhoneLabel => 'Secondary Phone (Optional)';

  @override
  String get secondaryPhoneHint => 'Additional contact number';

  @override
  String get locationLinkLabel => 'Location Link (Optional)';

  @override
  String get locationLinkHint => 'Google Maps link, etc.';

  @override
  String get locationLinkFieldLabel => 'Location link';

  @override
  String get locationLinkPasteHint =>
      'Paste a Google Maps link or 30.0444, 31.2357';

  @override
  String get locationLinkChecking => 'Checking the location…';

  @override
  String get locationLinkConfirmed => 'Location confirmed';

  @override
  String get locationLinkUnconfirmed => 'Location not confirmed yet';

  @override
  String get locationLinkClear => 'Clear location link';

  @override
  String get locationLinkRetry => 'Check again';

  @override
  String locationLinkDistanceKm(Object value) {
    return '$value km from the branch';
  }

  @override
  String locationLinkDistanceMeters(Object value) {
    return '$value m from the branch';
  }

  @override
  String get locationLinkErrorUnrecognized =>
      'That does not look like a Maps link. Paste a Google Maps link or coordinates like 30.0444, 31.2357.';

  @override
  String get locationLinkErrorUnresolved =>
      'Could not read a location from this link. Open it in Maps, share it again, and paste the new link.';

  @override
  String get locationLinkErrorOutsideArea =>
      'This location is outside Egypt, so it cannot be a delivery address. Check the link.';

  @override
  String get locationLinkErrorPlaceLink =>
      'This link is a shop or place, not a pin. In Maps, long-press the customer’s exact spot to drop a pin, share that pin, and paste the new link.';

  @override
  String locationLinkErrorTooFar(Object distance) {
    return 'This point is $distance — too far to be a delivery address. Check the link.';
  }

  @override
  String get locationLinkErrorNetwork =>
      'Could not check the location. Try again.';

  @override
  String get detailedAddressRequired => 'Detailed Address *';

  @override
  String get detailedAddressOptional => 'Detailed Address (Optional)';

  @override
  String get addressOptionalPartner =>
      'Optional when Sales Partner is selected';

  @override
  String get addressRequired => 'Address is required';

  @override
  String get territoryLabel => 'Territory *';

  @override
  String get territorySelectRequired => 'Please select a territory';

  @override
  String get territoryLoadFailed => 'Failed to load territories';

  @override
  String get unknownTerritory => 'Unknown Territory';

  @override
  String get customerCreateFailed => 'Failed to create customer';

  @override
  String get authUsernameLabel => 'Username';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authInvalidCredentials => 'Invalid credentials';

  @override
  String get authCannotReachServer =>
      'Cannot reach server. Check Wi-Fi/VPN and backend URL, then try again.';

  @override
  String get authConnectionFailed =>
      'Connection failed. Please verify network and server availability.';

  @override
  String get authLoginFailed => 'Login failed. Please try again.';

  @override
  String get menuReports => 'Reports';

  @override
  String get velocityReportTileTitle => 'Reorder & Velocity Alerts';

  @override
  String get velocityReportTileSubtitle =>
      'Restock alerts from weekly sales-velocity tracking';

  @override
  String get velocityReportTitle => 'Reorder & Velocity Alerts';

  @override
  String get velocityReportSummaryCritical => 'Critical';

  @override
  String get velocityReportSummaryWatch => 'Watch List';

  @override
  String get velocityReportSummarySlow => 'Slow Movers';

  @override
  String get velocityReportSummaryOverstock => 'Overstocked';

  @override
  String get velocityReportDetailTitle => 'Velocity Detail';

  @override
  String get velocityReportRecalculateAction => 'Recalculate Now';

  @override
  String get velocityReportRecalculateConfirmTitle =>
      'Recalculate velocity now?';

  @override
  String get velocityReportRecalculateConfirmBody =>
      'This recalculates sales velocity for every stock item and can take a while. The weekly job already keeps this up to date automatically.';

  @override
  String velocityReportRecalculateSuccess(int count) {
    return 'Velocity updated for $count items';
  }

  @override
  String get velocityReportRecalculateError =>
      'Couldn\'t recalculate velocity. Please try again.';

  @override
  String get segmentReportTileTitle => 'Customer Segments (RFM)';

  @override
  String get segmentReportTileSubtitle =>
      'Recency, frequency & value segmentation from the nightly job';

  @override
  String get segmentReportTitle => 'Customer Segments';

  @override
  String get segmentReportColumnCount => 'Customers';

  @override
  String get segmentReportTotalCustomers => 'Total Customers';

  @override
  String get segmentReportRecalculateAction => 'Recalculate Now';

  @override
  String get segmentReportRecalculateConfirmTitle =>
      'Recalculate segments now?';

  @override
  String get segmentReportRecalculateConfirmBody =>
      'This recalculates RFM segments for every customer; pinned customers are skipped. The nightly job already keeps this up to date automatically.';

  @override
  String segmentReportRecalculateSuccess(int updated) {
    return 'Segments updated for $updated customers';
  }

  @override
  String get segmentReportRecalculateError =>
      'Couldn\'t recalculate segments. Please try again.';

  @override
  String segmentReportCustomersTitle(Object segment) {
    return '$segment customers';
  }

  @override
  String get segmentReportCopyAll => 'Copy All';

  @override
  String get segmentReportCopied => 'Copied to clipboard';

  @override
  String get segmentReportExportEmpty => 'No customers in this segment';

  @override
  String get segmentReportPin => 'Pin segment';

  @override
  String get segmentReportUnpin => 'Unpin segment';

  @override
  String segmentReportPinConfirmBody(Object customer) {
    return 'Pin $customer\'s segment so it stops changing on the next recalculation?';
  }

  @override
  String segmentReportUnpinConfirmBody(Object customer) {
    return 'Unpin $customer so their segment recalculates automatically again?';
  }

  @override
  String get segmentReportOverrideSuccess => 'Segment updated';

  @override
  String get segmentReportOverrideError =>
      'Couldn\'t update segment. Please try again.';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsFinalProducts => 'Final Products';

  @override
  String get reportsFinalProductsDesc =>
      'Stock count by warehouse for Small, Medium & Large items';

  @override
  String get reportsMaterials => 'Materials & Consumables';

  @override
  String get reportsMaterialsDesc =>
      'Raw materials, sub assemblies, and consumables stock';

  @override
  String get reportsRawMaterials => 'Raw Materials';

  @override
  String get reportsSubAssemblies => 'Sub Assemblies';

  @override
  String get reportsConsumables => 'Consumables';

  @override
  String get reportsItemName => 'Item';

  @override
  String get reportsItemGroup => 'Group';

  @override
  String get reportsTotal => 'Total';

  @override
  String get reportsNoData => 'No data available';

  @override
  String get reportsRetry => 'Retry';

  @override
  String get reportsComingSoon => 'Coming soon';

  @override
  String get reportsFrom => 'From';

  @override
  String get reportsTo => 'To';

  @override
  String get reportsRangeThisMonth => 'This Month';

  @override
  String get reportsRangeLast30Days => 'Last 30 Days';

  @override
  String get reportsRangeLast90Days => 'Last 90 Days';

  @override
  String get reportShippingTitle => 'Shipping Analytics';

  @override
  String get reportShippingSubtitle =>
      'Delivery cost, courier settlements & shipping P&L';

  @override
  String get reportInventoryTitle => 'Inventory Intelligence';

  @override
  String get reportInventorySubtitle =>
      'Stock velocity, critical items & movers';

  @override
  String get reportProductTitle => 'Product Analytics';

  @override
  String get reportProductSubtitle =>
      'Revenue, gross profit & best sellers by product';

  @override
  String get reportCustomerTitle => 'Customer Analytics';

  @override
  String get reportCustomerSubtitle =>
      'Segments, retention & at-risk customers';

  @override
  String get reportExecutiveTitle => 'Executive Overview';

  @override
  String get reportExecutiveSubtitle =>
      'Top-line KPIs across the whole business';

  @override
  String get reportB2bTitle => 'B2B Sales & Clients';

  @override
  String get reportB2bSubtitle => 'B2B revenue, pipeline & client health';

  @override
  String get reportNoData => 'No data for this period';

  @override
  String get reportError => 'Couldn\'t load report';

  @override
  String get reportAlerts => 'Alerts';

  @override
  String get reportShipKpiTotalOrders => 'Total Orders';

  @override
  String get reportShipKpiDeliveryOrders => 'Delivery Orders';

  @override
  String get reportShipKpiPickupOrders => 'Pickup Orders';

  @override
  String get reportShipKpiExpense => 'Shipping Expense';

  @override
  String get reportShipKpiIncome => 'Delivery Income';

  @override
  String get reportShipKpiNetPl => 'Net P&L';

  @override
  String get reportShipKpiAvgCost => 'Avg Cost / Order';

  @override
  String get reportShipKpiPendingOverrides => 'Pending Overrides';

  @override
  String get reportShipKpiUnsettled => 'Unsettled';

  @override
  String get reportCostByTerritory => 'Cost by Territory';

  @override
  String get reportCostBySubTerritory => 'Cost by Sub-Territory';

  @override
  String get reportCostByBranch => 'Cost by Branch';

  @override
  String get reportCostByCourier => 'Cost by Courier';

  @override
  String get reportShippingOverrides => 'Shipping Overrides';

  @override
  String get reportDoubleShipping => 'Double-Shipping Impact';

  @override
  String get reportDailyTrend => 'Daily Trend';

  @override
  String get reportPickupVsDelivery => 'Pickup vs Delivery';

  @override
  String get reportUnsettledBalances => 'Unsettled Courier Balances';

  @override
  String get reportPickupDeliveryTrend => 'Pickup / Delivery Trend';

  @override
  String get reportInvKpiStockItems => 'Stock Items';

  @override
  String get reportInvKpiCritical => 'Critical';

  @override
  String get reportInvKpiWatch => 'Watch List';

  @override
  String get reportInvKpiSlow => 'Slow Movers';

  @override
  String get reportInvKpiOverstock => 'Overstocked';

  @override
  String get reportInvKpiStockValue => 'Stock Value';

  @override
  String get reportStockVelocity => 'Stock Velocity';

  @override
  String get reportTopMovers => 'Top Movers';

  @override
  String get reportRestockAlerts => 'Restock Alerts';

  @override
  String get reportCriticalItems => 'Critical';

  @override
  String get reportWatchList => 'Watch List';

  @override
  String get reportSlowMovers => 'Slow Movers';

  @override
  String get reportOverstocked => 'Overstocked';

  @override
  String get reportTopSellers => 'Top Sellers';

  @override
  String get reportKpiTotalRevenue => 'Total Revenue';

  @override
  String get reportKpiTotalOrders => 'Total Orders';

  @override
  String get reportKpiGrossProfit => 'Gross Profit';

  @override
  String get reportKpiGrossMargin => 'Gross Margin';

  @override
  String get reportKpiAov => 'Avg Order Value';

  @override
  String get reportKpiBestSeller => 'Best Seller';

  @override
  String get reportKpiTopTerritory => 'Top Territory';

  @override
  String get reportRevenueByType => 'Revenue by Type';

  @override
  String get reportTopProducts => 'Top Products';

  @override
  String get reportByTerritory => 'By Territory';

  @override
  String get reportRevenueTrend => 'Revenue Trend';

  @override
  String get reportBundleComposition => 'Bundle Composition';

  @override
  String get reportKpiTotalCustomers => 'Total Customers';

  @override
  String get reportKpiActive => 'Active';

  @override
  String get reportKpiNew => 'New';

  @override
  String get reportKpiRepeatRate => 'Repeat Rate';

  @override
  String get reportKpiChampions => 'Champions';

  @override
  String get reportKpiAtRisk => 'At Risk';

  @override
  String get reportKpiLost => 'Lost';

  @override
  String get reportSegmentDistribution => 'Segment Distribution';

  @override
  String get reportSegmentDetail => 'Segment Detail';

  @override
  String get reportTopCustomers => 'Top Customers';

  @override
  String get reportAtRiskWinBack => 'At-Risk / Win-Back';

  @override
  String get reportNewCustomerAcquisition => 'New Customer Acquisition';

  @override
  String get reportKpiRevenue => 'Revenue';

  @override
  String get reportKpiOrders => 'Orders';

  @override
  String get reportKpiNetShippingPl => 'Net Shipping P&L';

  @override
  String get reportKpiCustomers => 'Customers';

  @override
  String get reportKpiCriticalStock => 'Critical Stock';

  @override
  String get reportProductMix => 'Product Mix';

  @override
  String get reportCustomerSegments => 'Customer Segments';

  @override
  String get reportTopTerritories => 'Top Territories';

  @override
  String get reportKpiB2bRevenue => 'B2B Revenue';

  @override
  String get reportKpiB2bOrders => 'B2B Orders';

  @override
  String get reportKpiActiveClients => 'Active Clients';

  @override
  String get reportKpiNewClients => 'New Clients';

  @override
  String get reportKpiReorderDue => 'Reorder Due';

  @override
  String get reportSalesPipeline => 'Sales Pipeline';

  @override
  String get reportTopClients => 'Top Clients';

  @override
  String get reportRevenueByPolicy => 'Revenue by Commercial Policy';

  @override
  String get reportClientsByGroup => 'Clients by Group';

  @override
  String get reportReorderDue => 'Reorder Due';

  @override
  String get reportAtRiskClients => 'At-Risk Clients';

  @override
  String get reportConversion => 'Conversion';

  @override
  String get menuMasterOrders => 'Master Orders';

  @override
  String get masterOrdersTitle => 'Master Orders';

  @override
  String get masterOrdersSearchHint => 'Search by order ID, customer...';

  @override
  String get masterOrdersNoResults => 'No orders found';

  @override
  String get masterOrdersClearFilters => 'Clear Filters';

  @override
  String masterOrdersResultCount(int count) {
    return '$count orders';
  }

  @override
  String get masterOrdersFilterStatus => 'Status';

  @override
  String get masterOrdersFilterBranch => 'Branch';

  @override
  String get masterOrdersFilterPayment => 'Payment';

  @override
  String get masterOrdersFilterDate => 'Date Range';

  @override
  String get masterOrdersFilterDateFrom => 'From';

  @override
  String get masterOrdersFilterDateTo => 'To';

  @override
  String get masterOrdersOutstanding => 'Outstanding';

  @override
  String get masterOrdersCurrency => 'EGP';

  @override
  String get menuShiftMonitor => 'Shift Monitor';

  @override
  String get shiftMonitorTitle => 'POS Shift Monitor';

  @override
  String get shiftMonitorAccessRequired => 'Manager access required';

  @override
  String get shiftMonitorAccessDeniedBody =>
      'This page is available to JARZ Manager roles and above.';

  @override
  String get shiftMonitorFiltersTitle => 'Filters';

  @override
  String get shiftMonitorToday => 'Today';

  @override
  String get shiftMonitorLast7Days => 'Last 7 Days';

  @override
  String get shiftMonitorCustomRange => 'Custom Range';

  @override
  String get shiftMonitorPickDateRange => 'Pick Date Range';

  @override
  String shiftMonitorDateRangeValue(Object from, Object to) {
    return '$from to $to';
  }

  @override
  String get shiftMonitorProfileFilter => 'POS Profile';

  @override
  String get shiftMonitorStatusFilter => 'Status';

  @override
  String get shiftMonitorStatusAll => 'All';

  @override
  String get shiftMonitorStatusOpen => 'Open';

  @override
  String get shiftMonitorStatusClosed => 'Closed';

  @override
  String get shiftMonitorNoData => 'No shifts found for the selected filters.';

  @override
  String get shiftMonitorOpenCount => 'Open Shifts';

  @override
  String get shiftMonitorClosedCount => 'Closed Shifts';

  @override
  String get shiftMonitorDiscrepancyCount => 'Discrepancies';

  @override
  String get shiftMonitorDiscrepancyTotal => 'Discrepancy Total';

  @override
  String shiftMonitorLatestStart(Object value) {
    return 'Latest start: $value';
  }

  @override
  String shiftMonitorShiftCount(Object count) {
    return '$count shifts';
  }

  @override
  String get shiftMonitorOpenedAt => 'Opened At';

  @override
  String get shiftMonitorOpenedBy => 'Opened By';

  @override
  String get shiftMonitorClosedAt => 'Closed At';

  @override
  String get shiftMonitorClosedBy => 'Closed By';

  @override
  String get shiftMonitorCashAccount => 'Cash Account';

  @override
  String get shiftMonitorOpeningCash => 'Opening Cash';

  @override
  String get shiftMonitorExpectedClosingCash => 'Expected Closing';

  @override
  String get shiftMonitorActualClosingCash => 'Actual Closing';

  @override
  String get shiftMonitorDifference => 'Difference';

  @override
  String get shiftMonitorDifferenceSurplus => 'Surplus';

  @override
  String get shiftMonitorDifferenceShortage => 'Shortage';

  @override
  String get shiftMonitorNoDiscrepancy => 'No discrepancy';

  @override
  String get shorebirdUpdateBannerMessage =>
      'A new version is ready — fully close and reopen the app to apply it.';

  @override
  String get aboutRestartInstruction =>
      'Force-close and reopen the app to apply the downloaded patch.';

  @override
  String get aboutPatchPending => 'Pending patch (after restart)';

  @override
  String get menuLeads => 'Leads';

  @override
  String get leadFieldEmail => 'Email';

  @override
  String get leadFieldSource => 'Source';

  @override
  String get leadFieldTerritory => 'Territory';

  @override
  String get leadB2bStage => 'B2B Stage';

  @override
  String get leadFitScore => 'Fit Score';

  @override
  String get b2bMoveTo => 'Move to';

  @override
  String get shiftMonitorForceCloseAction => 'Close This Shift';

  @override
  String shiftMonitorForceCloseTitle(String user) {
    return 'Close $user\'s Shift';
  }

  @override
  String shiftMonitorForceCloseIntro(String user, String branch) {
    return 'You are closing a shift opened by $user on $branch. Enter the cash actually counted in the drawer — any difference posts a Cash Over/Short entry, exactly as a normal close would.';
  }

  @override
  String get shiftMonitorForceCloseReasonLabel => 'Reason (required)';

  @override
  String get shiftMonitorForceCloseReasonHint =>
      'e.g. staff member left without closing';

  @override
  String get shiftMonitorForceCloseReasonRequired =>
      'Please give a reason for closing another user\'s shift.';

  @override
  String shiftMonitorForceCloseCountLabel(String mode) {
    return 'Counted amount — $mode';
  }

  @override
  String shiftMonitorForceCloseCountRequired(String mode) {
    return 'Enter a counted amount for $mode.';
  }

  @override
  String shiftMonitorForceCloseExpected(String amount) {
    return 'System expected: $amount';
  }

  @override
  String shiftMonitorForceCloseCourierWarning(int transactions, int invoices) {
    return 'This branch still has $transactions unsettled courier transaction(s) across $invoices order(s). They stay outstanding after closing and must still be settled.';
  }

  @override
  String get shiftMonitorForceCloseCourierAck =>
      'I understand and want to close anyway';

  @override
  String get shiftMonitorForceCloseConfirm => 'Close Shift';

  @override
  String get shiftMonitorForceCloseSuccess => 'Shift closed.';

  @override
  String get returnOrderTitle => 'Return Order';

  @override
  String get returnOrderLinesLabel => 'Items coming back';

  @override
  String returnOrderLineAvailable(String qty) {
    return 'Up to $qty can be returned';
  }

  @override
  String returnOrderLineAvailableAfterPrior(String qty, String returned) {
    return 'Up to $qty can be returned ($returned already returned)';
  }

  @override
  String get returnOrderLineFullyReturned => 'Already returned';

  @override
  String get returnOrderCreditAmountLabel => 'Customer will be credited';

  @override
  String get returnOrderFullNotice =>
      'The whole order is coming back. Stock returns to the branch and the order is credited in full.';

  @override
  String get returnOrderPartialNotice =>
      'Part of the order is coming back. Only the selected items are credited and returned to stock.';

  @override
  String get returnOrderTypeLabel => 'Return type';

  @override
  String get returnTypeCustomerReturn => 'Customer return';

  @override
  String get returnTypeFailedDelivery => 'Failed delivery';

  @override
  String get returnTypeDamaged => 'Damaged';

  @override
  String get returnTypeWrongItem => 'Wrong item';

  @override
  String get returnOrderReasonLabel => 'Reason';

  @override
  String get returnOrderReasonRequired =>
      'Please describe why the order is coming back';

  @override
  String get returnOrderNotesOptional => 'Additional notes (optional)';

  @override
  String get returnOrderPayCourierTitle => 'Pay the courier for this trip';

  @override
  String get returnOrderPayCourierYes =>
      'The courier keeps their delivery fee.';

  @override
  String get returnOrderPayCourierNo =>
      'The delivery fee will be reversed off the courier\'s balance.';

  @override
  String get returnOrderRefundLabel => 'Money already collected';

  @override
  String get returnOrderRefundCredit => 'Keep as customer credit';

  @override
  String get returnOrderRefundNow => 'Refund cash now';

  @override
  String get returnOrderRefundUnavailable => 'No collected payment to refund.';

  @override
  String get returnOrderConfirmButton => 'Confirm return';

  @override
  String get returnOrderProcessing => 'Processing return…';

  @override
  String get returnOrderPreviewFailed => 'Could not load the return details.';

  @override
  String get returnOrderNotAvailable => 'This order cannot be returned.';

  @override
  String get returnOrderFailed => 'The return could not be completed.';

  @override
  String get returnOrderSuccess => 'Return completed.';

  @override
  String returnOrderSuccessWithCn(String creditNote) {
    return 'Return completed. Credit note $creditNote created.';
  }

  @override
  String get menuItemRequests => 'Item Requests';

  @override
  String get requestsTitle => 'Item Requests';

  @override
  String get requestsFilterOpen => 'Open';

  @override
  String get requestsFilterMine => 'Mine';

  @override
  String get requestsFilterAll => 'All';

  @override
  String get requestsEmptyOpen => 'Nothing is being requested right now';

  @override
  String get requestsEmptyMine => 'You have not requested anything yet';

  @override
  String get requestsEmptyAll => 'No requests yet';

  @override
  String get requestsEmptyHint =>
      'Tap + to ask for something you are running out of.';

  @override
  String get requestsNewTitle => 'Request items';

  @override
  String get requestsAddItems => 'Add items';

  @override
  String get requestsNeededBy => 'Needed by';

  @override
  String get requestsNoteLabel => 'Note (optional)';

  @override
  String get requestsNoteHint => 'Brand, size, urgency';

  @override
  String get requestsSubmit => 'Send request';

  @override
  String requestsSubmitted(Object name) {
    return 'Request $name sent';
  }

  @override
  String requestsSubmitFailed(Object error) {
    return 'Could not send request: $error';
  }

  @override
  String get requestsNoItemsYet => 'No items added yet';

  @override
  String requestsItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String requestsRequestedBy(Object name) {
    return 'by $name';
  }

  @override
  String get requestsOverdue => 'Overdue';

  @override
  String get requestsStatusPending => 'Waiting';

  @override
  String get requestsStatusPartiallyReceived => 'Partly bought';

  @override
  String get requestsStatusReceived => 'Bought';

  @override
  String get requestsStatusStopped => 'Rejected';

  @override
  String get requestsStatusCancelled => 'Cancelled';

  @override
  String get requestsStatusOrdered => 'Ordered';

  @override
  String get requestsReject => 'Reject';

  @override
  String get requestsRejectTitle => 'Reject this request?';

  @override
  String get requestsRejectReason => 'Reason (optional)';

  @override
  String get requestsRejected => 'Request rejected';

  @override
  String get requestsEdit => 'Edit';

  @override
  String get requestsEditTitle => 'Edit request';

  @override
  String get requestsSaveChanges => 'Save changes';

  @override
  String requestsUpdated(Object name) {
    return 'Request $name updated';
  }

  @override
  String get requestsUnit => 'Unit';

  @override
  String get requestsReopen => 'Reopen';

  @override
  String get requestsReopened => 'Request reopened';

  @override
  String get requestsAccept => 'Accept';

  @override
  String get requestsAccepted => 'Request accepted — the requester can see it';

  @override
  String requestsAcceptedBy(Object name) {
    return 'Accepted by $name';
  }

  @override
  String get requestsAwaitingAcceptance => 'Not accepted yet';

  @override
  String get purchaseReorderReplaceTitle => 'Replace the current cart?';

  @override
  String purchaseReorderReplaceBody(Object invoice) {
    return 'The cart already has items. Reordering replaces them with the items from $invoice.';
  }

  @override
  String get purchaseReorderReplace => 'Replace';

  @override
  String purchaseReorderFilled(Object invoice) {
    return 'Filled from $invoice — review, then submit';
  }

  @override
  String get purchaseReorderNothing => 'This invoice has no items to reorder';

  @override
  String requestsLineProgress(Object received, Object requested, Object uom) {
    return '$received of $requested $uom';
  }

  @override
  String get requestsBranchLabel => 'Branch';

  @override
  String get purchaseFromRequests => 'From requests';

  @override
  String get purchaseFromRequestsTitle => 'Buy requested items';

  @override
  String get purchaseFromRequestsEmpty => 'No open requests to buy';

  @override
  String get purchaseFromRequestsHint =>
      'Quantities are pre-filled with what is still outstanding. Change anything before adding.';

  @override
  String purchaseRequestedQty(Object qty) {
    return 'requested $qty';
  }

  @override
  String purchaseBuyingLess(Object requested, Object buying) {
    return 'requested $requested, buying $buying';
  }

  @override
  String purchaseOnHand(Object qty) {
    return 'on hand $qty';
  }

  @override
  String purchaseLastPaid(Object rate) {
    return 'last paid $rate';
  }

  @override
  String purchaseAddSelected(Object count) {
    return 'Add $count to cart';
  }

  @override
  String purchaseNeededBy(Object date) {
    return 'needed $date';
  }

  @override
  String get purchaseRequestSources => 'Requested by';

  @override
  String get purchaseUrgent => 'Urgent';

  @override
  String get purchasePaymentCredit => 'On account (pay later)';

  @override
  String get purchasePaymentCreditSubtitle =>
      'Leaves an outstanding balance with the supplier';

  @override
  String get purchaseBillNoLabel => 'Supplier bill no.';

  @override
  String get purchaseBillNoHint => 'From the supplier\'s own invoice';

  @override
  String get purchaseBillDateLabel => 'Bill date';

  @override
  String get purchaseTaxesLabel => 'Taxes';

  @override
  String get purchaseTaxesNone => 'No tax';

  @override
  String get purchaseNoVat => 'No VAT';

  @override
  String purchaseVatValue(Object amount) {
    return 'VAT: $amount';
  }

  @override
  String purchaseNetTotalValue(Object amount) {
    return 'Net: $amount';
  }

  @override
  String get purchaseNewSupplier => 'New supplier';

  @override
  String get purchaseNewSupplierName => 'Supplier name';

  @override
  String get purchaseNewSupplierGroup => 'Supplier group';

  @override
  String get purchaseNewSupplierPhone => 'Phone (optional)';

  @override
  String purchaseSupplierCreated(Object name) {
    return 'Supplier $name created';
  }

  @override
  String get purchaseSubmitting => 'Creating purchase';

  @override
  String get purchaseOutstandingLabel => 'Outstanding';

  @override
  String get purchasePayNow => 'Pay now';

  @override
  String purchasePaid(Object entry) {
    return 'Payment recorded ($entry)';
  }

  @override
  String get purchaseReturnAction => 'Return to supplier';

  @override
  String get purchaseReturnTitle => 'Return to supplier';

  @override
  String get purchaseReturnReason => 'Reason';

  @override
  String get purchaseReturnQtyLabel => 'Return qty';

  @override
  String get purchaseReturnSubmit => 'Create return';

  @override
  String purchaseReturned(Object name) {
    return 'Return $name created';
  }

  @override
  String get purchaseHistoryFilterSupplier => 'Supplier';

  @override
  String get purchaseHistoryFilterStatus => 'Status';

  @override
  String get purchaseHistoryFilterAll => 'All';

  @override
  String get purchaseHistoryFilterClear => 'Clear filters';

  @override
  String get purchaseHistorySearchHint => 'Invoice or bill no.';

  @override
  String purchaseItemsInvoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String kanbanRunProgressLabel(int delivered, int total) {
    return '$delivered/$total delivered';
  }

  @override
  String kanbanRunProgressTooltip(String courier, int delivered, int total) {
    return '$courier: $delivered of $total stops delivered on this board';
  }

  @override
  String get kanbanRunProgressComplete => 'Run complete';

  @override
  String kanbanRunStopLabel(int sequence) {
    return 'Stop $sequence';
  }

  @override
  String kanbanRunFailedLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missed',
      one: '1 missed',
    );
    return '$_temp0';
  }

  @override
  String kanbanRunFailedTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops on this run were attempted and not delivered',
      one: '1 stop on this run was attempted and not delivered',
    );
    return '$_temp0';
  }

  @override
  String get kanbanRunAttemptFailedLabel => 'Delivery missed';

  @override
  String kanbanRunAttemptFailedTooltip(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: '$attempts times',
      one: 'once',
    );
    return 'This stop was attempted $_temp0 and has not been delivered';
  }

  @override
  String get menuLiveCourierMap => 'Live courier map';

  @override
  String get fleetTitle => 'Live courier map';

  @override
  String get fleetRefreshTooltip => 'Refresh now';

  @override
  String fleetUpdatedAgo(String ago) {
    return 'Updated $ago';
  }

  @override
  String get fleetUpdating => 'Updating…';

  @override
  String fleetCouriersOnMap(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count couriers on the map',
      one: '1 courier on the map',
    );
    return '$_temp0';
  }

  @override
  String get fleetRefreshFailed =>
      'Refresh failed — these positions are only getting older';

  @override
  String get fleetLegendTitle => 'How old is each dot';

  @override
  String fleetLegendFresh(int minutes) {
    return 'Fresh · under $minutes min';
  }

  @override
  String fleetLegendAgeing(int from, int to) {
    return 'Ageing · $from–$to min';
  }

  @override
  String fleetLegendStale(int minutes) {
    return 'Stale · over $minutes min, do not act on it';
  }

  @override
  String get fleetFreshnessFresh => 'Fresh';

  @override
  String get fleetFreshnessAgeing => 'Ageing';

  @override
  String get fleetFreshnessStale => 'Stale';

  @override
  String get fleetStaleWarning =>
      'Some couriers have not reported recently — check before dispatching';

  @override
  String get fleetAgeJustNow => 'just now';

  @override
  String fleetAgeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min ago',
      one: '1 min ago',
    );
    return '$_temp0';
  }

  @override
  String fleetAgeHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hr ago',
      one: '1 hr ago',
    );
    return '$_temp0';
  }

  @override
  String fleetAgeDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get fleetAgeUnknown => 'no timestamp';

  @override
  String get fleetAgeShortNow => 'now';

  @override
  String fleetAgeShortMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String fleetAgeShortHours(int hours) {
    return '${hours}h';
  }

  @override
  String fleetAgeShortDays(int days) {
    return '${days}d';
  }

  @override
  String get fleetBranchLabel => 'Branch';

  @override
  String get fleetBranchUnknown => 'No branch';

  @override
  String get fleetLastFixLabel => 'Last fix';

  @override
  String get fleetAccuracyLabel => 'Accuracy';

  @override
  String fleetAccuracyValue(String meters) {
    return '±$meters m';
  }

  @override
  String get fleetAccuracyUnknown => 'Not reported';

  @override
  String get fleetEmptyNoCouriersTitle => 'No couriers on shift';

  @override
  String get fleetEmptyNoCouriersBody =>
      'Nobody is signed on to the courier app right now, so there is nothing to track. Positions appear here as soon as a courier starts their shift.';

  @override
  String get fleetEmptyNoPositionsTitle => 'On shift, but no position yet';

  @override
  String get fleetEmptyNoPositionsBody =>
      'These couriers are signed on, but their phones have not sent a location. Check that the courier app has location permission and a signal.';

  @override
  String fleetEmptyNoPositionsNames(String names) {
    return 'Waiting on: $names';
  }

  @override
  String fleetUnlocatedBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count couriers on shift have sent no position',
      one: '1 courier on shift has sent no position',
    );
    return '$_temp0';
  }

  @override
  String get fleetForbiddenTitle => 'Supervisors only';

  @override
  String get fleetForbiddenBody =>
      'Live courier positions are limited to managers and supervisors. Retrying will not help — ask a manager to open this screen.';

  @override
  String get fleetErrorTitle => 'Could not load courier positions';

  @override
  String get labelsTitle => 'Customer Labels';

  @override
  String get labelsHelpTooltip => 'How this works';

  @override
  String get labelsRefreshTooltip => 'Refresh';

  @override
  String get labelsSetUpCustomer => 'Set up customer';

  @override
  String get labelsSetupNothingNew => 'Nothing new to track';

  @override
  String labelsSetupTrackingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Now tracking $count flavours',
      one: 'Now tracking 1 flavour',
    );
    return '$_temp0';
  }

  @override
  String labelsSetupSkippedSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' ($count already tracked)',
      one: ' (1 already tracked)',
    );
    return '$_temp0';
  }

  @override
  String labelsPrintOrderSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sheets sent to the printer',
      one: '1 sheet sent to the printer',
    );
    return '$_temp0';
  }

  @override
  String labelsPrintOrderDueBack(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sheets ordered — due back $date',
      one: '1 sheet ordered — due back $date',
    );
    return '$_temp0';
  }

  @override
  String get labelsHelpTitle => 'How label tracking works';

  @override
  String get labelsHelpRows =>
      'Every flavour has its own label design, and each flavour is tracked on its own row per branch where its labels are kept, so a customer served from two branches has a row at each. JARZ prints every label, and labels come off stock automatically when the customer\'s invoice is submitted.';

  @override
  String labelsHelpSheets(Object small, Object medium, Object large) {
    return 'Printing is ordered in sheets — $small Small, $medium Medium or $large Large labels per sheet.';
  }

  @override
  String labelsHelpLeadTime(
    Object min,
    Object max,
    String restDay,
    Object buffer,
  ) {
    return 'Printing takes $min–$max working days with $restDay excluded, so a label is flagged \"Print now\" once its remaining stock would not survive that wait — and \"Print soon\" $buffer days before that point.';
  }

  @override
  String get labelsHelpQuiet =>
      'Once a batch is at the printer the label goes quiet and shows its due-back date instead, so the same shortage is not raised every morning.';

  @override
  String get labelsHelpAlertsOff =>
      'Daily alerts are currently switched off in Jarz POS Settings.';

  @override
  String get labelsHelpGotIt => 'Got it';

  @override
  String labelsSummaryUrgent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count labels must go to the printer now',
      one: '1 label must go to the printer now',
    );
    return '$_temp0';
  }

  @override
  String labelsSummarySoon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count labels to print soon',
      one: '1 label to print soon',
    );
    return '$_temp0';
  }

  @override
  String get labelsSummaryNothing => 'Nothing needs printing';

  @override
  String labelsSummaryLeadTime(Object min, Object max, String restDay) {
    return 'Printing takes $min–$max working days · $restDay excluded';
  }

  @override
  String labelsSummaryReadySuffix(String date) {
    return ' · order today, ready $date';
  }

  @override
  String get labelsFilterNeedsPrinting => 'Needs printing';

  @override
  String get labelsFilterAll => 'All';

  @override
  String get labelsFilterAtPrinter => 'At printer';

  @override
  String labelsFilterWithCount(String text, int count) {
    return '$text ($count)';
  }

  @override
  String get labelsAllLocations => 'All locations';

  @override
  String get labelsSearchHint => 'Search customer or flavour';

  @override
  String get labelsEmptyNoneTitle => 'No labels tracked yet';

  @override
  String get labelsEmptyNoneBody =>
      'Set up the B2B customers whose jar labels JARZ prints — one label per flavour. Stock then comes down on its own as their orders are invoiced.';

  @override
  String get labelsEmptyEnoughCover => 'Every label has enough cover';

  @override
  String get labelsEmptyNoMatch => 'Nothing matches this filter';

  @override
  String get labelsShowAll => 'Show all labels';

  @override
  String get labelStatusOutOfStock => 'Out of stock';

  @override
  String get labelStatusOutOfStockWhy =>
      'No labels left. This customer cannot be packed.';

  @override
  String get labelStatusPrintNow => 'Print now';

  @override
  String labelStatusPrintNowWhy(int days) {
    return 'Stock runs out before a new batch could arrive ($days working days).';
  }

  @override
  String get labelStatusPrintSoon => 'Print soon';

  @override
  String get labelStatusPrintSoonWhy =>
      'Getting close to the point of no return.';

  @override
  String get labelStatusAtPrinter => 'At the printer';

  @override
  String get labelStatusAtPrinterWhy => 'A batch is already on its way.';

  @override
  String get labelStatusOk => 'OK';

  @override
  String get labelStatusOkWhy => 'Comfortable cover.';

  @override
  String get labelStatusUnknown => 'Unknown';

  @override
  String get labelStatusNotTracked => 'Not tracked';

  @override
  String get labelStatusNotTrackedWhy =>
      'This label is switched off, so nothing is counted.';

  @override
  String labelCardFlavours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count flavours',
      one: '1 flavour',
    );
    return '$_temp0';
  }

  @override
  String labelCardNeedPrintingSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' · $count need printing',
      one: ' · 1 needs printing',
    );
    return '$_temp0';
  }

  @override
  String get labelCardCustomerActions => 'Customer actions';

  @override
  String get labelCardNotTracked => 'Switched off, not counted';

  @override
  String get labelCardAddFlavour => 'Add flavour';

  @override
  String get labelCardOnHand => 'on hand';

  @override
  String get labelCardOfCover => 'of cover';

  @override
  String labelCardOrderSheets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Order $count sheets',
      one: 'Order 1 sheet',
    );
    return '$_temp0';
  }

  @override
  String get labelCardOrderBatch => 'Order a batch';

  @override
  String get labelCardCoverOver99 => '99+ d';

  @override
  String labelCardCoverDays(String days) {
    return '$days d';
  }

  @override
  String get labelCardCoverNone => '—';

  @override
  String labelCardSheetsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sheets',
      one: '1 sheet',
    );
    return '$_temp0';
  }

  @override
  String labelCardLabelsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count labels',
      one: '1 label',
    );
    return '$_temp0';
  }

  @override
  String labelCardAtPrinter(String what) {
    return '$what at the printer';
  }

  @override
  String labelCardOverdueSince(String what, String date) {
    return '$what overdue at the printer since $date';
  }

  @override
  String labelCardDueBack(String what, String date) {
    return '$what due back $date';
  }

  @override
  String labelCardRunsOutAround(String date) {
    return 'Runs out around $date';
  }

  @override
  String get labelCardNoUsage => 'No usage recorded yet';

  @override
  String labelCardOrderAhead(int days) {
    return 'Order $days working days ahead';
  }

  @override
  String get labelPrintStatusRequested => 'Requested';

  @override
  String get labelPrintStatusPrinting => 'Printing';

  @override
  String get labelPrintStatusReady => 'Ready';

  @override
  String get labelPrintStatusReceived => 'Received';

  @override
  String get labelPrintStatusCancelled => 'Cancelled';

  @override
  String get labelMovementConsumed => 'Used on jars';

  @override
  String get labelMovementPrintReceived => 'Received from the printer';

  @override
  String get labelMovementScrapped => 'Damaged or thrown away';

  @override
  String get labelMovementAdjustment => 'Correction (+/-)';

  @override
  String get labelDetailFallbackTitle => 'Label';

  @override
  String get labelDetailSettingsTooltip => 'Label settings';

  @override
  String labelDetailLoadFailed(String error) {
    return 'Could not load this label.\n$error';
  }

  @override
  String labelDetailSentToPrinter(String what) {
    return '$what sent to the printer';
  }

  @override
  String get labelDetailCountSaved => 'Count saved';

  @override
  String get labelDetailMovementRecorded => 'Movement recorded';

  @override
  String labelDetailReceivedAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count labels added to stock',
      one: '1 label added to stock',
    );
    return '$_temp0';
  }

  @override
  String labelDetailBatchMarked(String status) {
    return 'Batch marked $status';
  }

  @override
  String get labelDetailBillRecorded =>
      'Bill recorded — purchase invoice created';

  @override
  String get labelDetailSettingsSaved => 'Settings saved';

  @override
  String labelDetailStoredAt(String location) {
    return 'Stored at $location';
  }

  @override
  String get labelDetailLabelsOnHand => 'labels on hand';

  @override
  String get labelDetailDaysOfCover => 'Days of cover';

  @override
  String get labelDetailUnknownValue => 'unknown';

  @override
  String get labelDetailUsedPerDay => 'Used per day';

  @override
  String get labelDetailRunsOut => 'Runs out';

  @override
  String labelDetailUsedInDays(int days) {
    return 'Used in ${days}d';
  }

  @override
  String get labelDetailStockValue => 'Stock value';

  @override
  String get labelDetailAvgCost => 'Avg cost/label';

  @override
  String get labelDetailRetired =>
      'This label is retired. Turn it back on in label settings to resume counting.';

  @override
  String get labelDetailActionOrder => 'Order';

  @override
  String get labelDetailActionCount => 'Count';

  @override
  String get labelDetailActionRecord => 'Record';

  @override
  String get labelDetailSectionBatches => 'Print batches';

  @override
  String labelDetailOrderedOn(String date) {
    return 'ordered $date';
  }

  @override
  String labelDetailOverdueSince(String date) {
    return 'overdue since $date';
  }

  @override
  String labelDetailDueOn(String date) {
    return 'due $date';
  }

  @override
  String labelDetailReceivedOn(String date) {
    return 'received $date';
  }

  @override
  String labelDetailReceivedOnQty(String date, int qty) {
    return 'received $date ($qty)';
  }

  @override
  String get labelDetailReceiveIntoStock => 'Receive into stock';

  @override
  String get labelDetailMarkPrinting => 'Mark printing';

  @override
  String get labelDetailMarkReady => 'Mark ready';

  @override
  String get labelDetailRecordBill => 'Record the printer\'s bill';

  @override
  String get labelDetailCancelBatch => 'Cancel batch';

  @override
  String get labelDetailBilled => 'Billed';

  @override
  String labelDetailBilledWithInvoice(String invoice) {
    return 'Billed · $invoice';
  }

  @override
  String get labelDetailUnbilled => 'Unbilled';

  @override
  String labelDetailUnbilledQuoted(String amount) {
    return 'Unbilled · quoted $amount';
  }

  @override
  String get labelDetailPolicyFlavour => 'Flavour';

  @override
  String get labelDetailPolicySize => 'Size';

  @override
  String get labelDetailPolicyStoredAt => 'Stored at';

  @override
  String get labelDetailPolicyNotSet => 'Not set';

  @override
  String get labelDetailPolicyMinStock => 'Minimum stock';

  @override
  String get labelDetailPolicyUsualBatch => 'Usual print batch';

  @override
  String get labelDetailPolicyLabelsPerSheet => 'Labels per sheet';

  @override
  String get labelDetailPolicyLabelsPerJar => 'Labels per jar';

  @override
  String get labelDetailPolicyLeadTime => 'Print lead time';

  @override
  String labelDetailPolicyLeadTimeValue(
    Object min,
    Object max,
    String restDay,
  ) {
    return '$min–$max working days ($restDay excluded)';
  }

  @override
  String get labelDetailPolicyLastCounted => 'Last counted';

  @override
  String get labelDetailPolicyLastMovement => 'Last movement';

  @override
  String get labelDetailSectionSetup => 'Setup';

  @override
  String get labelDetailSectionHistory => 'History';

  @override
  String get labelDetailHistoryEmpty =>
      'Nothing recorded yet. Labels come off automatically as this customer\'s orders are invoiced.';

  @override
  String get labelDetailAutoPosted => 'Posted automatically from the invoice';

  @override
  String get labelSheetSupplierOptional => 'Print supplier (optional)';

  @override
  String get labelSheetPrintSupplier => 'Print supplier';

  @override
  String get labelSheetCountTitle => 'Count labels';

  @override
  String get labelSheetCountSubtitle =>
      'Enter what is physically on the shelf. The difference is posted to the ledger, so a label that keeps going missing shows up as a run of corrections rather than vanishing quietly.';

  @override
  String get labelSheetCountedQty => 'Counted quantity';

  @override
  String labelSheetSystemShows(int qty) {
    return 'System currently shows $qty.';
  }

  @override
  String labelSheetDeltaMore(int count) {
    return '$count more than recorded';
  }

  @override
  String labelSheetDeltaFewer(int count) {
    return '$count fewer than recorded';
  }

  @override
  String get labelSheetNoteOptional => 'Note (optional)';

  @override
  String get labelSheetNotesOptional => 'Notes (optional)';

  @override
  String get labelSheetSaveCount => 'Save count';

  @override
  String get labelSheetOrderTitle => 'Order a print batch';

  @override
  String labelSheetLeadPlain(Object min, Object max, String restDay) {
    return 'Printing takes $min–$max working days ($restDay excluded).';
  }

  @override
  String labelSheetLeadReady(
    String date,
    Object min,
    Object max,
    String restDay,
  ) {
    return 'Ordered today, ready around $date — $min–$max working days, $restDay excluded.';
  }

  @override
  String get labelSheetSheetsToPrint => 'Sheets to print';

  @override
  String labelSheetSuggestedSheets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Suggested $count sheets, based on current usage and the usual batch.',
      one: 'Suggested 1 sheet, based on current usage and the usual batch.',
    );
    return '$_temp0';
  }

  @override
  String labelSheetSheetsEquals(String sheets, String labels) {
    return '$sheets = $labels';
  }

  @override
  String get labelSheetNetCostOptional => 'Net cost (optional)';

  @override
  String get labelSheetNetCostQuoteHelper =>
      'What the printer quoted for the batch, before VAT. The bill itself is recorded when it arrives.';

  @override
  String get labelSheetSendToPrinter => 'Send to printer';

  @override
  String get labelSheetReceiveTitle => 'Receive batch';

  @override
  String labelSheetReceiveSubtitle(String name, String ordered) {
    return '$name · ordered $ordered';
  }

  @override
  String get labelSheetLabelsReceived => 'Labels received';

  @override
  String get labelSheetReceivedHelper =>
      'Adjust if the printer delivered short. Only this many are added to stock.';

  @override
  String get labelSheetAddToStock => 'Add to stock';

  @override
  String get labelSheetBillTitle => 'Record the printer\'s bill';

  @override
  String labelSheetBillSubtitle(String name, String ordered) {
    return '$name · $ordered. This books a supplier purchase invoice, so the batch lands on the books at its real cost.';
  }

  @override
  String get labelSheetNetCost => 'Net cost';

  @override
  String get labelSheetNetCostBillHelper =>
      'What the printer charged for this batch, before VAT.';

  @override
  String get labelSheetBillNoOptional => 'Supplier\'s bill no. (optional)';

  @override
  String get labelSheetRecordBill => 'Record bill';

  @override
  String get labelSheetMovementTitle => 'Record a movement';

  @override
  String get labelSheetWhatHappened => 'What happened';

  @override
  String get labelSheetQuantity => 'Quantity';

  @override
  String get labelSheetAdjustmentHelper => 'Use a minus sign to reduce stock.';

  @override
  String get labelSheetQtyHelper =>
      'Enter a plain number — the direction follows from the type.';

  @override
  String get labelSheetLabelName => 'Label name';

  @override
  String get labelSheetActive => 'Active';

  @override
  String get labelSheetActiveHelp =>
      'Turn off to retire a design that is no longer used.';

  @override
  String get labelSheetStoredAtHelper =>
      'The branch or factory where this label physically lives.';

  @override
  String get labelSheetUsualBatchSheets => 'Usual batch (sheets)';

  @override
  String get labelSheetLabelsPerSheetHelper =>
      'Leave 0 for the size default: 21 Small, 21 Medium, 18 Large.';

  @override
  String get labelSheetLabelsPerJarHelper => 'Usually 1.';

  @override
  String get labelWizardTitle => 'Set up customer labels';

  @override
  String get labelWizardStartTracking => 'Start tracking';

  @override
  String get labelWizardContinue => 'Continue';

  @override
  String get labelWizardBack => 'Back';

  @override
  String get labelWizardStepCustomer => 'Customer';

  @override
  String get labelWizardStepFlavours => 'Flavours';

  @override
  String labelWizardPickedCount(int count) {
    return '$count picked';
  }

  @override
  String get labelWizardStepLocation => 'Where the labels live';

  @override
  String get labelWizardStepConfirm => 'Confirm';

  @override
  String get labelWizardChange => 'Change';

  @override
  String labelWizardCustomerPriceList(String customer, String priceList) {
    return '$customer · price list: $priceList';
  }

  @override
  String get labelWizardSearchCustomers => 'Search customers';

  @override
  String get labelWizardSearching => 'Searching…';

  @override
  String get labelWizardNoCustomers => 'No company customers matched.';

  @override
  String labelWizardPriceList(String priceList) {
    return 'Price list: $priceList';
  }

  @override
  String labelWizardFlavoursLoadFailed(String error) {
    return 'Could not load flavours.\n$error';
  }

  @override
  String get labelWizardPickCustomerFirst => 'Pick a customer first.';

  @override
  String get labelWizardNoFlavours =>
      'No flavours found for this customer — nothing on their price list and no order history yet.';

  @override
  String get labelWizardSizeOther => 'Other';

  @override
  String get labelWizardFlavourHelp =>
      'Tick every flavour to track at the branch you pick next. A flavour already tracked at another branch can be ticked again. Enter what is already on the shelf so nothing starts life as Out of Stock.';

  @override
  String get labelWizardAlreadyTracked => 'Already tracked';

  @override
  String labelWizardTrackedAt(String locations) {
    return 'Tracked at $locations';
  }

  @override
  String labelWizardAlreadyAtLocation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count picked flavours are already tracked at this branch and will be skipped.',
      one:
          '1 picked flavour is already tracked at this branch and will be skipped.',
    );
    return '$_temp0';
  }

  @override
  String get labelWizardOnPriceList => 'On price list';

  @override
  String get labelWizardOrderedBefore => 'Ordered before';

  @override
  String get labelWizardLabelsInStock => 'Labels in stock now';

  @override
  String get labelWizardLocationsLoadFailed =>
      'Could not load locations — you can set one per label later.';

  @override
  String get labelWizardStoredAtHelper =>
      'The branch or factory where these labels physically live.';

  @override
  String get labelWizardUsualBatchSheets => 'Usual print batch (sheets)';

  @override
  String get labelWizardUsualBatchHelper =>
      'Applied to every flavour; changeable per label later.';

  @override
  String get labelWizardConfirmPriceList => 'Price list';

  @override
  String get labelWizardConfirmUsualBatch => 'Usual batch';

  @override
  String get labelWizardSafeToRerun =>
      'A flavour already tracked at the chosen branch is left untouched; picking another branch adds that branch\'s labels. Running this again is always safe.';

  @override
  String labelCardAtPrinterSuffix(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: ' · $n at printer',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String get labelCardRecordOrder => 'Record an order';

  @override
  String get labelsExpandAll => 'Expand all';

  @override
  String get labelsCollapseAll => 'Collapse all';

  @override
  String get labelQuickOrderTitle => 'Record an order';

  @override
  String get labelQuickOrderBranch => 'Goes to';

  @override
  String get labelQuickOrderBranches => 'Goes to (tap to change)';

  @override
  String get labelQuickOrderFlavours => 'Sheets ordered';

  @override
  String labelQuickOrderTimesBranches(int n) {
    return '× $n branches';
  }

  @override
  String get labelQuickOrderNotAtBranch => 'Not at the selected branch';

  @override
  String get labelQuickOrderFillSuggested => 'Fill suggested';

  @override
  String get labelQuickOrderOrderedOn => 'Ordered on';

  @override
  String get labelQuickOrderMore => 'Supplier & notes';

  @override
  String labelQuickOrderSubmit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Record order · $n sheets',
      one: 'Record order · 1 sheet',
    );
    return '$_temp0';
  }

  @override
  String labelsQuickOrderRecorded(int count, int sheets) {
    return 'Recorded $count print orders · $sheets sheets';
  }

  @override
  String labelsQuickOrderFailedSuffix(int n) {
    return ' · $n failed';
  }

  @override
  String get labelDetailActionBought => 'Bought & received';

  @override
  String labelDetailBoughtRecorded(int count, String invoice) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Recorded $count labels, bill $invoice',
      one: 'Recorded 1 label, bill $invoice',
    );
    return '$_temp0';
  }

  @override
  String get labelSheetBoughtTitle => 'Bought & received';

  @override
  String labelSheetBoughtSubtitle(String name) {
    return '$name. For a batch already bought and delivered: adds it to stock and books the printer\'s bill in one step.';
  }

  @override
  String get labelSheetSheetsBought => 'Sheets bought';

  @override
  String get labelSheetBoughtReceivedHelper =>
      'Filled in from the sheets. Change it if the printer delivered short.';

  @override
  String get labelSheetBoughtOn => 'Bought / received on';

  @override
  String get labelSheetRecordBought => 'Add to stock & record bill';

  @override
  String get labelSheetPaymentHeading => 'Payment';

  @override
  String get labelSheetPaymentOwed => 'Owed to supplier (pay later)';

  @override
  String get labelSheetPaymentOwedSubtitle =>
      'The bill stays open as a payable to the printer';

  @override
  String get labelSheetPaymentPaid => 'Paid now';

  @override
  String labelSheetPaymentPaidFrom(String source) {
    return 'Paid from $source';
  }

  @override
  String get labelSheetPaymentPickSource => 'Choose where the money came from';

  @override
  String get labelSheetPaymentChange => 'Change payment source';

  @override
  String labelDetailBoughtAlreadyRecorded(String invoice) {
    return 'This purchase was already recorded (bill $invoice)';
  }

  @override
  String get labelDetailBoughtAlreadyRecordedNoBill =>
      'This purchase was already recorded';

  @override
  String labelSheetBoughtBeforeCount(String date) {
    return 'Labels received before the last count ($date) are probably already in that count — recording them adds them again.';
  }

  @override
  String get b2bStageLead => 'Lead';

  @override
  String get b2bStageQualify => 'Qualify';

  @override
  String get b2bStageSample => 'Sample';

  @override
  String get b2bStageApproved => 'Approved';

  @override
  String get b2bStageTrial => 'Trial';

  @override
  String get b2bStageCheckup => 'Check-up';

  @override
  String get b2bStageActive => 'Active';

  @override
  String get b2bStageLostOnHold => 'Lost/On-hold';

  @override
  String get leadsTitle => 'Leads';

  @override
  String get leadsMapTitle => 'Leads map';

  @override
  String get leadsMapViewTooltip => 'Map view';

  @override
  String get leadsListViewTooltip => 'List view';

  @override
  String get leadsRefreshTooltip => 'Refresh';

  @override
  String get leadsAddLead => 'Add lead';

  @override
  String get leadsStatShowing => 'Showing';

  @override
  String get leadsStatTierA => 'Tier A';

  @override
  String get leadsStatBranches => 'Branches';

  @override
  String get leadsSearchHint => 'Search leads…';

  @override
  String get leadsAdvancedFilters => 'Advanced filters';

  @override
  String get leadsEmptyFiltered => 'No leads match these filters';

  @override
  String leadsDistanceMetres(String value) {
    return '$value m';
  }

  @override
  String leadsDistanceKm(String value) {
    return '$value km';
  }

  @override
  String get leadsLocationServicesOff =>
      'Location services are off. Turn them on in your device settings.';

  @override
  String get leadsLocationBlocked =>
      'Location permission is blocked for this app.';

  @override
  String get leadsLocationDenied => 'Location permission was declined.';

  @override
  String get leadsLocationNoFix =>
      'Could not get a location fix. Try again outdoors.';

  @override
  String get leadsLocationSettings => 'Settings';

  @override
  String leadsOnMapCount(int count) {
    return '$count on map';
  }

  @override
  String leadsOnMapWithStages(int count, String stages) {
    return '$count on map  ·  $stages';
  }

  @override
  String leadsStageSummaryCount(int count) {
    return '$count stages';
  }

  @override
  String get leadsHideLegend => 'Hide legend';

  @override
  String get leadsCategoryLegend => 'Category legend';

  @override
  String get leadsShowMyLocation => 'Show my location';

  @override
  String leadsBranchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count branches',
      one: '1 branch',
    );
    return '$_temp0';
  }

  @override
  String leadsDistanceAway(String distance) {
    return '$distance away (straight line)';
  }

  @override
  String leadsFilterActiveCount(int count) {
    return '$count active';
  }

  @override
  String get leadsFilterPipelineStage => 'Pipeline stage';

  @override
  String get leadsFilterRatingRange => 'Rating range';

  @override
  String leadsFilterMinReviews(int count) {
    return 'Minimum reviews: $count';
  }

  @override
  String get leadsFilterMinBranches => 'Minimum branch count';

  @override
  String get leadsFilterHasSahel => 'Has Sahel branches';

  @override
  String get leadsFilterSpecialtyOnly => 'Specialty only';

  @override
  String get leadsFilterTakeawayOnly => 'Takeaway confirmed';

  @override
  String get leadsFilterTalabat => 'Talabat';

  @override
  String get leadsFilterTalabatOn => 'On Talabat';

  @override
  String get leadsFilterTalabatOff => 'Not on Talabat';

  @override
  String get leadsTalabatBadge => 'Talabat';

  @override
  String get leadsTalabatRatingFromGoogle =>
      'Rating shown is from Google — no Talabat rating yet';

  @override
  String get leadsTalabatUnrated => 'Listed on Talabat, not yet rated';

  @override
  String get leadsFilterHasPhone => 'Has phone';

  @override
  String get leadsFilterHasInstagram => 'Has Instagram';

  @override
  String get leadsFilterHasWebsite => 'Has website';

  @override
  String get leadsFilterShowNotSuitable => 'Show not suitable';

  @override
  String get leadsFilterPriceBand => 'Price band';

  @override
  String get leadsFilterClearAll => 'Clear all';

  @override
  String leadsAreaClearCount(int count) {
    return 'Clear ($count)';
  }

  @override
  String get leadsAreaSearchHint => 'Search areas';

  @override
  String leadsAreaNoMatch(String query) {
    return 'No area matches \"$query\"';
  }

  @override
  String get leadsAreaAll => 'All areas';

  @override
  String leadsAreaSelectedCount(int count) {
    return '$count areas';
  }

  @override
  String leadsMergeConfirmTitle(int count, String survivor) {
    return 'Merge $count into \"$survivor\"?';
  }

  @override
  String leadsMergeConfirmBody(String survivor) {
    return 'Their branches, areas and any details \"$survivor\" is missing move onto it. The merged leads stay on file for audit but leave the catalog and the pipeline board.';
  }

  @override
  String leadsMergeFailed(String error) {
    return 'Merge failed: $error';
  }

  @override
  String get leadsMergeTitle => 'Merge duplicates';

  @override
  String leadsMergeSubtitle(String name) {
    return 'Fold other records of the same brand into \"$name\".';
  }

  @override
  String get leadsMergeSearchHint =>
      'Search by name, or leave blank for suggestions';

  @override
  String leadsMergeAction(int count) {
    return 'Merge $count';
  }

  @override
  String get leadsMergeNoDuplicates =>
      'No likely duplicates found. Search by name if you know of one.';

  @override
  String get leadsMergeNoMatch => 'No leads match that search.';

  @override
  String get leadsMergedSuccess => 'Leads merged';

  @override
  String get leadsAllStages => 'All stages';

  @override
  String get leadsFilterTitle => 'Filters';

  @override
  String get leadsFilterAreas => 'Areas';

  @override
  String get leadsFilterAny => 'Any';

  @override
  String get leadsFilterAll => 'All';

  @override
  String get leadsFilterDone => 'Done';

  @override
  String get leadDetailTitle => 'Lead';

  @override
  String get leadDetailEdit => 'Edit lead';

  @override
  String leadDetailBranchesCount(int count) {
    return 'Branches ($count)';
  }

  @override
  String get leadDetailStatusNotes => 'Status & notes';

  @override
  String get leadDetailStatusField => 'Status';

  @override
  String get leadDetailCategoryField => 'Category';

  @override
  String get leadDetailCategoryNone => 'None';

  @override
  String get leadDetailUpdated => 'Lead updated';

  @override
  String leadDetailFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get leadDetailFitScoreUpdated => 'Fit score updated';

  @override
  String leadDetailScoreOutOf(int score) {
    return '$score / 100';
  }

  @override
  String leadDetailStageUpdated(String stage) {
    return 'Stage updated to $stage';
  }

  @override
  String get leadDetailReasonTitle => 'Reason';

  @override
  String get leadDetailReasonHint => 'Why is this lost / on hold?';

  @override
  String get leadDetailNotSuitable => 'Not suitable';

  @override
  String leadDetailByWhom(String user) {
    return 'by $user';
  }

  @override
  String leadDetailOnDate(String date) {
    return 'on $date';
  }

  @override
  String get leadDetailMarkedNotSuitable => 'Marked not suitable';

  @override
  String get leadDetailRestoreTitle => 'Restore lead?';

  @override
  String get leadDetailRestoreBody =>
      'This clears the not-suitable verdict and puts the lead back in the catalog at the Lead stage.';

  @override
  String get leadDetailRestore => 'Restore';

  @override
  String get leadDetailRestored => 'Lead restored';

  @override
  String get leadDetailSuitability => 'Suitability';

  @override
  String get leadDetailSuitabilityMarked =>
      'This prospect was judged not suitable after manual inspection. It is hidden from the catalog and off the pipeline board.';

  @override
  String get leadDetailSuitabilityPrompt =>
      'Inspected this prospect and it is not worth pursuing? Mark it not suitable to take it out of the working catalog.';

  @override
  String get leadDetailRestoreLead => 'Restore lead';

  @override
  String get leadDetailMarkNotSuitable => 'Mark not suitable';

  @override
  String get leadDetailNotesOptional => 'Notes (optional)';

  @override
  String get leadDetailInspectionHint => 'What did the inspection show?';

  @override
  String get leadDetailMergedAway => 'Merged into another lead';

  @override
  String get leadDetailOpenSurvivor => 'Open the surviving lead';

  @override
  String get leadDetailDuplicates => 'Duplicates';

  @override
  String get leadDetailDuplicatesBody =>
      'The catalog was built per location, so one brand can appear as several leads. Merge them here to keep every branch on one record.';

  @override
  String get leadDetailAddresses => 'Addresses';

  @override
  String get leadDetailPrimaryAddress => 'Primary address';

  @override
  String get leadDetailShippingAddress => 'Shipping address';

  @override
  String leadDetailAddressSaved(String title) {
    return '$title saved';
  }

  @override
  String leadDetailSaveAddress(String title) {
    return 'Save $title';
  }

  @override
  String get leadFieldAddressLine1 => 'Address line 1';

  @override
  String get leadFieldAddressLine2 => 'Address line 2';

  @override
  String get leadFieldCity => 'City';

  @override
  String get leadFieldState => 'State';

  @override
  String get leadFieldCountry => 'Country';

  @override
  String get leadFieldPincode => 'Pincode';

  @override
  String get leadFieldPhone => 'Phone';

  @override
  String get leadFormEditTitle => 'Edit lead';

  @override
  String get leadFormSaved => 'Lead saved';

  @override
  String get leadFormNewCategory => 'New category';

  @override
  String get leadFormCategoryName => 'Category name';

  @override
  String get leadFormAddCategory => 'Add category';

  @override
  String get leadFormLeadName => 'Lead name *';

  @override
  String get leadFormCompanyName => 'Company name';

  @override
  String get leadFormPrimaryArea => 'Primary area';

  @override
  String leadFormDuplicateExact(String place) {
    return 'Already in your catalog: $place';
  }

  @override
  String leadFormDuplicateLikely(String place) {
    return 'This looks like a place you already have: $place';
  }

  @override
  String get leadFormDuplicateHint =>
      'Saving creates a second lead. If this is another branch, add it to the existing lead instead.';

  @override
  String get leadFormAreaEstimated =>
      'Area estimated from the map pin — check it';

  @override
  String get leadFormAreaEstimatedUnsure =>
      'Area estimated from the map pin, unsure — please check';

  @override
  String get leadFormPriceBand => 'Price band';

  @override
  String leadFormFitScoreRange(String label) {
    return '$label (0–100)';
  }

  @override
  String get leadFormSaveChanges => 'Save changes';

  @override
  String get leadFormCreate => 'Create lead';

  @override
  String get leadFormCardBrand => 'Brand';

  @override
  String get leadMapsCardTitle => 'Google Maps place';

  @override
  String get leadMapsCardDescription =>
      'Paste the place link first. Any available details will fill in below for you to review.';

  @override
  String get leadMapsFieldLabel => 'Google Maps link';

  @override
  String get leadMapsPaste => 'Paste';

  @override
  String get leadMapsGetDetails => 'Get details';

  @override
  String get leadMapsOpen => 'Open map';

  @override
  String get leadMapsChecking => 'Reading place…';

  @override
  String get leadMapsStillWorking =>
      'Details are taking longer. The link will still be saved; tap Retry to check again.';

  @override
  String get leadMapsDetailsImported =>
      'We found some details. Review and complete the form below.';

  @override
  String get leadMapsLocationImported =>
      'Location confirmed. Review and complete the form below.';

  @override
  String get leadMapsLookupFailed =>
      'Couldn’t read details. The link will still be saved; enter the details below.';

  @override
  String get leadMapsUnrecognized =>
      'This doesn’t look like a Google Maps link. You can still save it and enter the details below.';

  @override
  String get leadMapsLinkKept =>
      'The link will be saved with the lead. Enter the remaining details below.';

  @override
  String get leadMapsFoundDetails => 'Details found';

  @override
  String get leadFormCardClassification => 'Classification';

  @override
  String get leadFormCardContact => 'Contact';

  @override
  String get leadFormTier => 'Tier';

  @override
  String get leadFormSpecialty => 'Specialty';

  @override
  String get leadFieldMobile => 'Mobile';

  @override
  String get leadFieldWebsite => 'Website';

  @override
  String get leadFieldInstagram => 'Instagram';

  @override
  String get leadFieldFacebook => 'Facebook';

  @override
  String get leadFormRequired => 'Required';

  @override
  String leadFormAddressRequired(String title) {
    return '$title: address line 1, city, and country are required together.';
  }

  @override
  String get leadFormScoreRangeError => '0–100';

  @override
  String get leadFormCategoryLabel => 'Category';

  @override
  String get leadsSortTooltip => 'Sort';

  @override
  String get leadsSortScore => 'Score';

  @override
  String get leadsSortRating => 'Rating';

  @override
  String get leadsSortReviews => 'Reviews';

  @override
  String get leadsSortBranches => 'Branches';

  @override
  String get leadsSortName => 'Name';

  @override
  String get leadsSortNearest => 'Nearest';

  @override
  String get leadsMapCategories => 'Categories';

  @override
  String get leadActionCall => 'Call';

  @override
  String get leadActionInstagram => 'Instagram';

  @override
  String get leadActionWebsite => 'Website';

  @override
  String get leadActionMap => 'Map';

  @override
  String get leadsMergeConfirmAction => 'Merge';

  @override
  String get b2bAccountTitle => 'Account';

  @override
  String b2bAccountLoadFailed(String error) {
    return 'Failed to load account.\n$error';
  }

  @override
  String b2bFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get b2bLogCall => 'Log call';

  @override
  String get b2bLogCallHint => 'What was discussed?';

  @override
  String get b2bActivityLogged => 'Activity logged';

  @override
  String b2bLogActivityFailed(String error) {
    return 'Failed to log activity: $error';
  }

  @override
  String get b2bMarkLostTitle => 'Mark lost / on-hold';

  @override
  String get b2bReasonHint => 'Reason';

  @override
  String get b2bMarkedLost => 'Marked Lost/On-hold';

  @override
  String get b2bCreateCustomerTitle => 'Create customer for lead';

  @override
  String get b2bCustomerName => 'Customer name';

  @override
  String get b2bAddress => 'Address';

  @override
  String get b2bContinue => 'Continue';

  @override
  String get b2bCustomerSetupTitle => 'Set up customer';

  @override
  String get b2bLinkExistingCustomer => 'Link existing customer';

  @override
  String get b2bCreateNewCustomer => 'Create new customer';

  @override
  String get b2bSearchExistingCustomer => 'Search existing customers';

  @override
  String get b2bNoMatchingCustomers => 'No matching customers found.';

  @override
  String get b2bLinkAndContinue => 'Link and continue';

  @override
  String get b2bLoadingTerritories => 'Loading territories…';

  @override
  String get b2bTerritoriesFailed => 'Failed to load territories';

  @override
  String get b2bOpenLeadPage => 'Open lead page';

  @override
  String get b2bSectionContact => 'Contact';

  @override
  String get b2bSectionInsights => 'Insights';

  @override
  String get b2bSectionRecentInvoices => 'Recent invoices';

  @override
  String get b2bSectionOpenTodos => 'Open to-dos';

  @override
  String b2bAccountSectionWithCount(String title, int count) {
    return '$title ($count)';
  }

  @override
  String get b2bNone => 'None';

  @override
  String get b2bPredictedNextOrder => 'Predicted next order';

  @override
  String get b2bAvgOrderCycle => 'Avg order cycle';

  @override
  String b2bDaysValue(String days) {
    return '$days days';
  }

  @override
  String get b2bSendSample => 'Send sample';

  @override
  String get b2bPlaceOrder => 'Place order';

  @override
  String get b2bOpenAccount => 'Open B2B account';

  @override
  String get b2bOrderResumeTitle => 'B2B order';

  @override
  String get b2bOrderResumeMessage =>
      'Choose a B2B account or resume a saved B2B order.';

  @override
  String get b2bOrderChooseAccount => 'Choose B2B account';

  @override
  String get b2bOrderChangeBranch => 'Change delivery branch';

  @override
  String get b2bOrderPolicyUnavailable =>
      'The required B2B pricing policy is unavailable. Retry after pricing has loaded.';

  @override
  String get b2bOrderSetupFailedTitle => 'Couldn’t prepare the B2B order';

  @override
  String get b2bMarkLost => 'Mark lost';

  @override
  String get b2bViewPricing => 'View pricing';

  @override
  String get b2bLabelsSection => 'Labels';

  @override
  String b2bLabelsNeedPrinting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count need printing',
      one: '1 needs printing',
    );
    return '$_temp0';
  }

  @override
  String get b2bNoLabelsTracked => 'No labels tracked for this customer yet.';

  @override
  String get b2bSetUpLabels => 'Set up labels';

  @override
  String get b2bLoadingLeadProfile => 'Loading lead profile…';

  @override
  String get b2bLeadProfile => 'Lead profile';

  @override
  String b2bMoreBranches(int count) {
    return '+ $count more';
  }

  @override
  String get b2bPipelineTitle => 'B2B Pipeline';

  @override
  String get b2bMyFollowUps => 'My follow-ups';

  @override
  String get b2bRefresh => 'Refresh';

  @override
  String get b2bSwitchMode => 'Switch mode';

  @override
  String get b2bGoToPos => 'Go to POS (B2C)';

  @override
  String get b2bGoToKanban => 'Go to Dispatch Kanban';

  @override
  String get b2bActiveTitle => 'Active customers';

  @override
  String get b2bActivePipelineBoard => 'Pipeline board';

  @override
  String get b2bActiveSearchHint => 'Search customer or area';

  @override
  String get b2bActiveKpiAccounts => 'Active accounts';

  @override
  String b2bActiveKpiBilled(int days) {
    return 'Billed, last $days days';
  }

  @override
  String b2bActiveKpiOrders(int days) {
    return 'Orders, last $days days';
  }

  @override
  String get b2bActiveKpiOutstanding => 'Outstanding';

  @override
  String get b2bActiveKpiReorderDue => 'Reorder due';

  @override
  String get b2bActiveKpiNeedsAttention => 'Needs attention';

  @override
  String b2bActiveVsPrevious(int days) {
    return 'vs previous $days days';
  }

  @override
  String get b2bActiveReorderOverdue => 'Reorder overdue';

  @override
  String get b2bActiveReorderDueSoon => 'Due soon';

  @override
  String b2bActiveReorderOk(String date) {
    return 'Next order about $date';
  }

  @override
  String b2bActiveLastOrder(String date, String ago) {
    return 'Last order: $date ($ago)';
  }

  @override
  String b2bActiveDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: 'yesterday',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String get b2bActiveNoOrders => 'No orders yet';

  @override
  String b2bActiveFigPeriod(int days) {
    return 'Last $days days';
  }

  @override
  String b2bActiveFigOrders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
    );
    return '$_temp0';
  }

  @override
  String get b2bActiveFigLifetime => 'Lifetime';

  @override
  String get b2bActiveFigAvgOrder => 'Avg order';

  @override
  String get b2bActiveFigOutstanding => 'Outstanding';

  @override
  String b2bActiveOldestUnpaid(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'oldest unpaid $count days',
      one: 'oldest unpaid 1 day',
    );
    return '$_temp0';
  }

  @override
  String b2bActiveNextAction(String action) {
    return 'Next: $action';
  }

  @override
  String b2bActiveNextActionOn(String action, String date) {
    return 'Next: $action on $date';
  }

  @override
  String b2bActiveLastNote(String note) {
    return 'Last note: $note';
  }

  @override
  String get b2bActiveAlertOldUnpaid => 'Old unpaid invoice';

  @override
  String get b2bActiveAlertLabels => 'Labels alert';

  @override
  String get b2bActiveAlertNoCustomer => 'No customer linked';

  @override
  String get b2bActiveCall => 'Call';

  @override
  String get b2bActiveEmptyTitle => 'No active customers yet';

  @override
  String get b2bActiveEmptyBody =>
      'Accounts you move to the Active stage on the pipeline board show up here.';

  @override
  String get b2bActiveNoMatches => 'No customers match your search';

  @override
  String get b2bActiveClearFilters => 'Clear filters';

  @override
  String b2bActivePercent(String value) {
    return '$value%';
  }

  @override
  String b2bActivePlace(String area, String customer) {
    return '$area · $customer';
  }

  @override
  String get b2bNewLead => 'New lead';

  @override
  String b2bMovedToStage(String title, String stage) {
    return 'Moved \"$title\" to $stage';
  }

  @override
  String b2bAdvanceStageFailed(String error) {
    return 'Failed to advance stage: $error';
  }

  @override
  String get b2bFollowUpReminder => 'Follow-up reminder';

  @override
  String b2bFollowUpPrompt(String stage) {
    return 'When should you follow up after moving to \"$stage\"?';
  }

  @override
  String get b2bSkip => 'Skip';

  @override
  String get b2bSetReminder => 'Set reminder';

  @override
  String get b2bLostReasonHint => 'Why is this lost / on hold?';

  @override
  String b2bPipelineLoadFailed(String error) {
    return 'Could not load the pipeline.\n$error';
  }

  @override
  String get b2bTodayTitle => 'Today';

  @override
  String b2bTodayLoadFailed(String error) {
    return 'Failed to load follow-ups.\n$error';
  }

  @override
  String get b2bNoFollowUpsToday => 'No follow-ups today';

  @override
  String get b2bNoReordersDue => 'No reorders due';

  @override
  String get b2bFollowUpDone => 'Follow-up marked done';

  @override
  String b2bFollowUpFailed(String error) {
    return 'Could not complete follow-up: $error';
  }

  @override
  String get b2bDone => 'Done';

  @override
  String b2bOverdueSuffix(String date) {
    return '$date · overdue';
  }

  @override
  String b2bAvgBasket(String amount) {
    return 'Avg: $amount';
  }

  @override
  String b2bScoreLabel(int score) {
    return 'Score $score';
  }

  @override
  String get b2bNoAccounts => 'No accounts';

  @override
  String b2bLabelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count labels',
      one: '1 label',
    );
    return '$_temp0';
  }

  @override
  String b2bLastOrder(String date) {
    return 'Last: $date';
  }

  @override
  String b2bNextOrder(String date) {
    return 'Next: $date';
  }

  @override
  String get b2bCardLead => 'Lead';

  @override
  String get b2bCardOpportunity => 'Opportunity';

  @override
  String b2bLabelsNeedPrintingTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count labels need printing',
      one: '1 label needs printing',
    );
    return '$_temp0';
  }

  @override
  String get pricingTitle => 'Price Lists';

  @override
  String get pricingCustomerLookup => 'Customer pricing lookup';

  @override
  String get pricingRefresh => 'Refresh';

  @override
  String get pricingNewPriceList => 'New price list';

  @override
  String get pricingNoPriceLists => 'No price lists yet.';

  @override
  String get pricingNameField => 'Name';

  @override
  String get pricingCurrencyField => 'Currency';

  @override
  String get pricingCreate => 'Create';

  @override
  String pricingCreated(String name) {
    return 'Created \"$name\"';
  }

  @override
  String pricingCreateFailed(String error) {
    return 'Could not create price list: $error';
  }

  @override
  String get pricingDefaultBadge => 'Default';

  @override
  String pricingLoadFailed(String error) {
    return 'Could not load price lists.\n$error';
  }

  @override
  String pricingDetailLoadFailed(String name, String error) {
    return 'Could not load \"$name\".\n$error';
  }

  @override
  String pricingSetRateTitle(String category) {
    return 'Set $category rate';
  }

  @override
  String pricingRateUpdated(String category) {
    return '$category rate updated';
  }

  @override
  String pricingRateSet(String category) {
    return '$category rate set';
  }

  @override
  String get pricingAllCategoriesHaveRows =>
      'All categories already have a row.';

  @override
  String pricingItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String pricingOverrideTitle(String item) {
    return 'Override $item';
  }

  @override
  String get pricingOverrideUpdated => 'Override updated';

  @override
  String get pricingRemoveOverrideTitle => 'Remove override?';

  @override
  String pricingRemoveOverrideBody(String item) {
    return '$item will fall back to its category rate.';
  }

  @override
  String get pricingRemove => 'Remove';

  @override
  String get pricingOverrideRemoved => 'Override removed';

  @override
  String get pricingAddOverride => 'Add override';

  @override
  String get pricingItemCode => 'Item code';

  @override
  String get pricingRateField => 'Rate';

  @override
  String get pricingOverrideAdded => 'Override added';

  @override
  String get pricingUnassignTitle => 'Unassign customer?';

  @override
  String pricingUnassignBody(String customer) {
    return '$customer will revert to their customer group default.';
  }

  @override
  String get pricingUnassign => 'Unassign';

  @override
  String get pricingCustomerUnassigned => 'Customer unassigned';

  @override
  String pricingFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get pricingCategoryPrices => 'Category prices';

  @override
  String get pricingAddCategory => 'Add category';

  @override
  String get pricingNoCategoryRates => 'No category rates set.';

  @override
  String pricingEditRateTooltip(String category) {
    return 'Edit $category rate';
  }

  @override
  String get pricingPerFlavorOverrides => 'Per-flavor overrides';

  @override
  String pricingOverrideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overrides',
      one: '1 override',
    );
    return '$_temp0';
  }

  @override
  String get pricingNoOverrides => 'No per-item overrides.';

  @override
  String get pricingEditOverride => 'Edit override';

  @override
  String get pricingRemoveOverride => 'Remove override';

  @override
  String get pricingAssignedCustomers => 'Assigned customers';

  @override
  String pricingCustomerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count customers',
      one: '1 customer',
    );
    return '$_temp0';
  }

  @override
  String get pricingNoCustomers => 'No customers use this list.';

  @override
  String pricingViaGroup(String group) {
    return 'via group $group';
  }

  @override
  String get pricingDirectAssignment => 'direct assignment';

  @override
  String get customerPricingTitle => 'Customer pricing';

  @override
  String get customerPricingSearchHint => 'Search company customers…';

  @override
  String customerPricingSearchFailed(String error) {
    return 'Search failed.\n$error';
  }

  @override
  String get customerPricingNoCustomers => 'No customers found.';

  @override
  String customerPricingLoadFailed(String customer, String error) {
    return 'Could not load pricing for \"$customer\".\n$error';
  }

  @override
  String get customerPricingEffective => 'Effective prices';

  @override
  String get customerPricingNoResolved => 'No resolved prices.';

  @override
  String customerPricingSource(String group, String source) {
    return '$group · source: $source';
  }

  @override
  String get pricingNoCategoryRatesShort => 'No category rates set';

  @override
  String pricingCardSummary(String customers, String currency) {
    return '$customers · $currency';
  }

  @override
  String get pricingDisabledSuffix => ' · disabled';

  @override
  String customerPricingGroupLine(
    String group,
    String priceList,
    String assignment,
  ) {
    return 'Group: $group\nPrice list: $priceList ($assignment)';
  }

  @override
  String get pricingNoneValue => '(none)';

  @override
  String get pricingDash => '—';

  @override
  String get journeyToday => 'Today';

  @override
  String get journeyYesterday => 'Yesterday';

  @override
  String get journeyTomorrow => 'Tomorrow';

  @override
  String journeyDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String journeyWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String journeyMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String journeyOverdueByDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Overdue by $count days',
      one: 'Overdue by 1 day',
    );
    return '$_temp0';
  }

  @override
  String get journeyOverdue => 'Overdue';

  @override
  String journeyInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count days',
      one: 'In 1 day',
    );
    return '$_temp0';
  }

  @override
  String journeyInMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count months',
      one: 'In 1 month',
    );
    return '$_temp0';
  }

  @override
  String get journeyTypeVisit => 'Visit';

  @override
  String get journeyTypeCall => 'Call';

  @override
  String get journeyTypeWhatsapp => 'WhatsApp';

  @override
  String get journeyTypeSampleDrop => 'Sample Drop';

  @override
  String get journeyTypeMeeting => 'Meeting';

  @override
  String get journeyTypeEmail => 'Email';

  @override
  String get journeyTypeOther => 'Other';

  @override
  String get journeyOutcomeInterested => 'Interested';

  @override
  String get journeyOutcomeNeedsFollowUp => 'Needs Follow-up';

  @override
  String get journeyOutcomeSampleRequested => 'Sample Requested';

  @override
  String get journeyOutcomeOrderPlaced => 'Order Placed';

  @override
  String get journeyOutcomeNotNow => 'Not Now';

  @override
  String get journeyOutcomeRejected => 'Rejected';

  @override
  String get journeyEditorEditTitle => 'Edit journey note';

  @override
  String get journeyEditorNewTitle => 'Log a visit or call';

  @override
  String get journeyEditorSubtitle =>
      'What happened, who you spoke to, and what happens next.';

  @override
  String get journeyEditorDate => 'Date';

  @override
  String get journeyEditorType => 'Type';

  @override
  String get journeyEditorNote => 'Note';

  @override
  String get journeyEditorNoteHint =>
      'They liked the matcha, asked about wholesale pricing…';

  @override
  String get journeyEditorWhoSpoke => 'Who you spoke to';

  @override
  String get journeyEditorWhoHint => 'Tap who you met, or add someone new.';

  @override
  String get journeyEditorNewPerson => 'New person';

  @override
  String journeyEditorContactFailed(String error) {
    return 'Could not save the contact: $error';
  }

  @override
  String get journeyEditorPerson => 'Person';

  @override
  String get journeyEditorPersonHint => 'Mostafa';

  @override
  String get journeyEditorRole => 'Role';

  @override
  String get journeyEditorRoleHint => 'Branch manager';

  @override
  String get journeyEditorTheirPhone => 'Their phone';

  @override
  String get journeyEditorOutcome => 'Outcome';

  @override
  String get journeyEditorNextAction => 'Next action';

  @override
  String get journeyEditorNextActionHelp =>
      'A date here also sets the follow-up reminder on this account.';

  @override
  String get journeyEditorWhatToDo => 'What to do';

  @override
  String get journeyEditorWhatToDoHint =>
      'Call the manager to confirm the trial order';

  @override
  String get journeyEditorWhen => 'When';

  @override
  String get journeyEditorNoReminder => 'No reminder';

  @override
  String get journeyEditorLogIt => 'Log it';

  @override
  String get journeyEditorPickDate => 'Pick a date';

  @override
  String get journeyEditorClear => 'Clear';

  @override
  String get journeySectionTitle => 'Journey';

  @override
  String journeyOpenTasksTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open tasks',
      one: '1 open task',
    );
    return '$_temp0';
  }

  @override
  String get journeyNoOpenTasks => 'No open tasks';

  @override
  String get journeyLatestLogsTitle => 'Latest logs';

  @override
  String journeyShowAllLogs(int count) {
    return 'Show all $count logs';
  }

  @override
  String get journeyShowLatestLogs => 'Show latest only';

  @override
  String get journeyLogVisit => 'Log visit';

  @override
  String get journeyNoteAdded => 'Journey note added';

  @override
  String get journeyNoteUpdated => 'Journey note updated';

  @override
  String get journeyNoteDeleted => 'Journey note deleted';

  @override
  String get journeyDeleteTitle => 'Delete this note?';

  @override
  String get journeyDeleteBody =>
      'The visit record is removed for everyone. This cannot be undone.';

  @override
  String journeyFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get journeyEdit => 'Edit';

  @override
  String journeyLoggedBy(String user) {
    return 'Logged by $user';
  }

  @override
  String get journeyEmptyTitle => 'No visits logged yet.';

  @override
  String get journeyEmptyBody =>
      'Log what was said, who said it, and when to follow up — a dated next action also sets this account\'s reminder.';

  @override
  String get journeyLoadFailed => 'Could not load the journey.';

  @override
  String get journeyMarkDone => 'Mark done';

  @override
  String get journeyMarkNotDone => 'Mark as not done';

  @override
  String get journeyDoneLabel => 'Done';

  @override
  String journeyDoneOn(String date) {
    return 'Done $date';
  }

  @override
  String journeyDoneByOn(String date, String user) {
    return 'Done $date · $user';
  }

  @override
  String get journeyActionMarkedDone => 'Next action marked done';

  @override
  String get journeyActionReopened => 'Next action reopened';

  @override
  String get journeyCalendarTitle => 'Action calendar';

  @override
  String get journeyCalendarPreviousMonth => 'Previous month';

  @override
  String get journeyCalendarNextMonth => 'Next month';

  @override
  String get journeyCalendarScopeMine => 'Mine';

  @override
  String get journeyCalendarScopeAll => 'All';

  @override
  String get journeyCalendarShowDone => 'Show done';

  @override
  String journeyCalendarPendingCount(int count) {
    return 'Pending $count';
  }

  @override
  String journeyCalendarOverdueCount(int count) {
    return 'Overdue $count';
  }

  @override
  String journeyCalendarDoneCount(int count) {
    return 'Done $count';
  }

  @override
  String journeyCalendarDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count due',
      one: '1 due',
    );
    return '$_temp0';
  }

  @override
  String get journeyCalendarNothingOnDay => 'Nothing due on this day.';

  @override
  String get journeyCalendarEmptyMonth => 'Nothing due this month.';

  @override
  String get journeyCalendarLoadFailed => 'Could not load the calendar.';

  @override
  String get journeyCalendarSourceFollowup => 'Reminder';

  @override
  String get journeyCalendarNoAction => 'No action written';

  @override
  String get errorConsoleCopyError => 'Copy error';

  @override
  String get errorConsoleCopied => 'Error details copied';

  @override
  String get errorConsoleSummary => 'Summary';

  @override
  String get errorConsoleFatal => 'Fatal';

  @override
  String get errorConsoleYes => 'Yes';

  @override
  String get errorConsoleNo => 'No';

  @override
  String get errorConsoleOccurrences => 'Occurrences';

  @override
  String get errorConsoleDetails => 'Details';

  @override
  String get errorConsoleStackTrace => 'Stack trace';

  @override
  String get menuInstapayReconciliation => 'InstaPay Reconciliation';

  @override
  String get instapayTitle => 'InstaPay Reconciliation';

  @override
  String get instapayNoOrders => 'No orders awaiting InstaPay confirmation';

  @override
  String get instapayCourierRequired =>
      'A courier is required for cash collection';

  @override
  String get instapayConvertedToCod => 'Converted to cash on delivery';

  @override
  String get instapayCollectedCashInstead => 'Collected cash instead';

  @override
  String get instapayConfirmReceived => 'Confirm received';

  @override
  String get instapayPaymentConfirmed => 'Payment confirmed';

  @override
  String get instapayBankReference => 'Bank reference number';

  @override
  String get kanbanMoveAction => 'Move';

  @override
  String get kanbanDeliveryPartnerField => 'Delivery Partner';

  @override
  String get kanbanSetDeliveryIncome => 'Set Delivery Income';

  @override
  String get kanbanDeliveryIncomeField => 'Delivery income';

  @override
  String get kanbanInvalidAmount => 'Enter a valid non-negative amount';

  @override
  String get kanbanUpdatingDeliveryIncome => 'Updating delivery income…';

  @override
  String kanbanErrorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get posShowHeaderTooltip => 'Show header';

  @override
  String get posCartDeliveryAmountField => 'Delivery amount';

  @override
  String get posCartResetToDefault => 'Reset to Default';

  @override
  String get posCartSetAction => 'Set';

  @override
  String get posCartPromoCode => 'Promo code';

  @override
  String get posCartPromoCodeHint => 'e.g. EGY2026';

  @override
  String get reportsColumnSegment => 'Segment';

  @override
  String get reportsColumnRecencyDays => 'Recency (d)';

  @override
  String get reportsColumnFrequency => 'Frequency';

  @override
  String get reportsColumnAov => 'AOV';

  @override
  String get tripsOneBranchOnly =>
      'Select invoices from one branch only to create a trip.';

  @override
  String get webPushOnlyInWebApp =>
      'Web push notifications are only available in the web app.';

  @override
  String get webPushEnabled =>
      'Web push notifications are enabled for this device.';

  @override
  String get webPushDisabledForEnv =>
      'Web push notifications are disabled for this environment.';

  @override
  String get webPushNotConfigured =>
      'Web push notifications are not configured for this environment.';

  @override
  String get webPushUnsupportedPrompt =>
      'This browser does not support notification permission prompts.';

  @override
  String get webPushPermissionRequired =>
      'Tap Enable Notifications to allow web push on this device.';

  @override
  String get webPushPermissionDenied => 'Notification permission was denied.';

  @override
  String get webPushNoToken =>
      'No web push token is available yet. Try again after reopening the app.';

  @override
  String get webPushTokenReady => 'Web push token is ready for registration.';

  @override
  String get webPushEnableFailed =>
      'Failed to enable notifications. Reopen the Home Screen app and try again.';

  @override
  String get b2bCustomerLabelsTooltip => 'Customer labels';

  @override
  String get b2bFollowUpsHeader => 'Follow-ups';

  @override
  String get b2bReorderDueHeader => 'Reorder due';

  @override
  String get expensesEmptyManagerHint =>
      'Create a new expense to capture operational spending.';

  @override
  String get expensesEmptyStaffHint =>
      'Submit a new expense and your manager will review it.';

  @override
  String get expenseSourceCash => 'Cash';

  @override
  String get expenseSourceBank => 'Bank';

  @override
  String get expenseSourceMobileWallet => 'Mobile Wallet';

  @override
  String get expenseSourcePosProfile => 'POS Profile';

  @override
  String get expenseSourceAccount => 'Account';

  @override
  String get instapayConvertFailed => 'Failed to convert order to cash';

  @override
  String get instapayConfirmFailed => 'Failed to confirm payment';

  @override
  String get instapayConfirmSheetTitle => 'Confirm InstaPay received';

  @override
  String get instapayAwaitingBadge => 'Awaiting InstaPay';

  @override
  String get inventoryCountSubmitting => 'Submitting reconciliation';

  @override
  String get inventoryCountSubmitError => 'Submit reconciliation error';

  @override
  String get kanbanExitSelection => 'Exit Selection';

  @override
  String get kanbanSelectOrders => 'Select Orders';

  @override
  String get kanbanMoveOrderTitle => 'Move order';

  @override
  String get kanbanCreateFailedFallback => 'Create failed';

  @override
  String get kanbanDeliveryIncomeHelp =>
      'Enter a custom delivery income for this order. Leave blank to revert to the territory default. This will create an amendment of the order.';

  @override
  String get kanbanCannotAmend => 'This order cannot be amended';

  @override
  String get kanbanDeliveryIncomeReset =>
      'Delivery income reset to territory default';

  @override
  String get kanbanAmendmentFailed => 'Amendment failed';

  @override
  String get kanbanShippingNotUpdated =>
      'shipping cost was not updated. Fix the address territory.';

  @override
  String get leadsNotSuitableBadge => 'Not suitable';

  @override
  String get bundleSelectionTitle => 'Bundle Selection';

  @override
  String get bundleUpdateAction => 'Update Bundle';

  @override
  String get bundleAddToCartAction => 'Add to Cart';

  @override
  String get bundleSelectFromGroups => 'Select items from each group below:';

  @override
  String get bundleCatalogDriftWarning =>
      'Bundle options may have changed since this order was placed. Please review and confirm your selections.';

  @override
  String get bundleNoItemsInGroup => 'No items available in this group';

  @override
  String get bundleUnknownItem => 'Unknown Item';

  @override
  String get bundleUnknownBundle => 'Unknown Bundle';

  @override
  String get bundleNoItemGroups => 'No item groups found';

  @override
  String get bundleNoItemGroupsBody =>
      'This bundle has no available item groups';

  @override
  String get posCartPromoDiscount => 'Promo discount';

  @override
  String get posCartFreeDelivery => 'Free delivery';

  @override
  String get posCartDeliveryAmountHelp =>
      'Enter a custom delivery amount. Leave blank to restore the territory default.';

  @override
  String get posCartBundleLoadFailed =>
      'Bundle contents could not be loaded. Edit this bundle and reselect items before submitting.';

  @override
  String get posCartPromoApplied => 'Applied';

  @override
  String get posCartPromoNotEligible => 'Not eligible';

  @override
  String get posSalesPartnerFallback => 'Sales Partner';

  @override
  String get reportsColumnBomCost => 'BOM Cost';

  @override
  String get reportsColumnTimesInBundle => 'Times in Bundle';

  @override
  String get settingsIosWebPushTitle => 'iPhone web push notifications';

  @override
  String get settingsIosWebPushBody =>
      'Install this app to the iPhone Home Screen, then tap Enable Notifications to receive background alerts.';

  @override
  String get settingsEnablingNotifications => 'Enabling notifications...';

  @override
  String get settingsEnableNotifications => 'Enable Notifications';

  @override
  String get settingsNotificationAlerts => 'Notification Alerts';

  @override
  String get settingsAlarmsMutedAll =>
      'All order notification alarms are currently muted';

  @override
  String get settingsAlarmsActive => 'Order notification alarms are active';

  @override
  String get settingsAlarmsEnabledDevice =>
      'Notification alarms enabled on this device';

  @override
  String get settingsAlarmsMutedDevice =>
      'Notification alarms muted on this device';

  @override
  String get settingsChooseAlarmSound => 'Choose the in-app staff alarm sound:';

  @override
  String get settingsAlarmSoundNote =>
      'This sound is used for the in-app staff alarm. Closed-app order notifications use the app order tone.';

  @override
  String get settingsProfileLoadFailed => 'Failed to load user profile';

  @override
  String get shiftUnknownUser => 'Unknown user';

  @override
  String kanbanDeliveryIncomeUpdated(String amount) {
    return 'Delivery income updated to $amount';
  }

  @override
  String kanbanAddressNoTerritory(String city) {
    return 'Address saved, but \"$city\" matches no territory — shipping cost was not updated. Fix the address territory.';
  }

  @override
  String get reportsColumnComponent => 'Component';

  @override
  String get leadContactsTitle => 'Contacts';

  @override
  String leadContactsTitleCount(int count) {
    return 'Contacts ($count)';
  }

  @override
  String get leadContactsEmpty =>
      'No people recorded yet. Add the owner, the manager, or whoever you meet on a visit.';

  @override
  String get leadContactsAdd => 'Add contact';

  @override
  String get leadContactsEdit => 'Edit contact';

  @override
  String get leadContactsRemove => 'Remove';

  @override
  String get leadContactsRemoveTitle => 'Remove contact?';

  @override
  String leadContactsRemoveBody(String name) {
    return 'Remove $name from this lead?';
  }

  @override
  String get leadContactsMakePrimary => 'Make primary';

  @override
  String get leadContactsPrimary => 'Primary contact';

  @override
  String get leadContactsPrimaryHint => 'The person to ring first.';

  @override
  String get leadContactsSaved => 'Contacts updated';

  @override
  String get leadContactsName => 'Name';

  @override
  String get leadContactsRole => 'Role / title';

  @override
  String get leadContactsRoleHint => 'Owner, Manager, Barista…';

  @override
  String get leadContactsPhone => 'Phone';

  @override
  String get leadContactsEmail => 'Email';

  @override
  String get leadContactsNotes => 'Notes';

  @override
  String get leadContactsPickFromPhone => 'Pick from phone contacts';

  @override
  String get leadContactsNeedNameOrPhone => 'Add a name or a phone number.';

  @override
  String get leadContactRoleOwner => 'Owner';

  @override
  String get leadContactRoleManager => 'Manager';

  @override
  String get leadContactRoleShiftManager => 'Shift Manager';

  @override
  String get leadContactRoleBarista => 'Barista';

  @override
  String get leadContactRolePurchasing => 'Purchasing';

  @override
  String get leadContactRoleAccountant => 'Accountant';

  @override
  String get visitPlannerTitle => 'Visit planner';

  @override
  String get visitPlanDay => 'Plan a day';

  @override
  String get visitBuildDay => 'Build a day';

  @override
  String get visitRouteTitle => 'Route';

  @override
  String visitRouteFallbackTitle(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString stops',
      one: '1 stop',
      zero: 'Empty route',
    );
    return '$_temp0';
  }

  @override
  String get visitScopeMine => 'My routes';

  @override
  String get visitScopeAll => 'Everyone\'s routes';

  @override
  String get visitNoRoutesOnDay => 'No route planned for this day.';

  @override
  String get visitPlansLoadFailed =>
      'Could not load routes. Pull down to try again.';

  @override
  String visitStopsCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString stops',
      one: '1 stop',
      zero: 'No stops',
    );
    return '$_temp0';
  }

  @override
  String visitDistanceKm(String km) {
    return '$km km';
  }

  @override
  String visitDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String visitDayTotal(String duration) {
    return 'Day $duration';
  }

  @override
  String visitLeg(String km, int minutes) {
    return '$km km · $minutes min';
  }

  @override
  String get visitNextStop => 'Next stop';

  @override
  String get visitGo => 'Go';

  @override
  String get visitNavigate => 'Navigate';

  @override
  String get visitCall => 'Call';

  @override
  String get visitCheckIn => 'Check in';

  @override
  String get visitSkip => 'Skip';

  @override
  String get visitReopen => 'Reopen';

  @override
  String get visitPin => 'Pin to this position';

  @override
  String get visitUnpin => 'Unpin';

  @override
  String get visitRemoveStop => 'Remove from route';

  @override
  String get visitOptimise => 'Optimise route';

  @override
  String get visitOptimiseFromHere => 'Optimise from where I am';

  @override
  String get visitNavigateWholeRoute => 'Open whole route in Maps';

  @override
  String get visitDeleteRoute => 'Delete route';

  @override
  String get visitDeleteRouteConfirm =>
      'The route is removed. Visits already recorded stay in the diary.';

  @override
  String get visitNoStops => 'This route has no stops yet.';

  @override
  String get visitLocationUnavailable => 'Could not get your location.';

  @override
  String visitRouteTruncated(int handed, int total) {
    return 'Maps takes $handed of $total stops at once. Navigate stop by stop for the rest.';
  }

  @override
  String get visitOutcome => 'Outcome';

  @override
  String get visitLogJourneyNote => 'Log a journey note';

  @override
  String get visitLogJourneyNoteHint =>
      'Records the visit on the lead\'s diary and drives its follow-up reminder.';

  @override
  String get visitNoteWhatHappened => 'What happened';

  @override
  String get visitNextAction => 'Next action';

  @override
  String get visitNextActionDate => 'Pick a date';

  @override
  String get visitMarkVisited => 'Visited';

  @override
  String get visitSuggestDay => 'Plan my day';

  @override
  String get visitMaxStops => 'Max stops';

  @override
  String get visitDayHours => 'Day (hours)';

  @override
  String get visitStartFromMyLocation => 'Start from my location';

  @override
  String get visitStartFromMyLocationHint =>
      'Off plans around the best cluster anywhere.';

  @override
  String get visitIncludeCustomers => 'Include existing clients';

  @override
  String get visitIncludeCustomersHint =>
      'Check-ups on active accounts along the way.';

  @override
  String get visitCandidateDoors => 'Doors worth visiting';

  @override
  String get visitClearSelection => 'Clear';

  @override
  String get visitNoCandidates => 'Nothing matches those filters.';

  @override
  String get visitTargetsLoadFailed => 'Could not load candidates.';

  @override
  String visitProposedDay(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString stops proposed',
      one: '1 stop proposed',
    );
    return '$_temp0';
  }

  @override
  String visitConsidered(int count) {
    return 'Weighed $count doors';
  }

  @override
  String visitDroppedForTime(int count) {
    return '$count dropped to fit the day';
  }

  @override
  String visitSelectedCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString stops selected',
      one: '1 stop selected',
    );
    return '$_temp0';
  }

  @override
  String get visitCreateRoute => 'Create route';

  @override
  String get visitEngineRoadExplained =>
      'Distances and times come from the road network.';

  @override
  String get visitEngineEstimateExplained =>
      'Distances are straight-line estimates adjusted for city driving. The visiting order is still solved properly; the minutes are approximate.';

  @override
  String get visitEngineRecheck => 'Check again';

  @override
  String get materialsSectionTitle => 'Price list & materials';

  @override
  String get materialsSendCta => 'Send price list';

  @override
  String get materialsSendTitle => 'Send materials';

  @override
  String get materialsRecipientLabel => 'Send to';

  @override
  String get materialsNoRecipient =>
      'No contacts on this lead yet. Add one first, or send anyway and pick the chat in WhatsApp.';

  @override
  String get materialsPickLabel => 'What to send';

  @override
  String get materialsPreparing => 'still preparing';

  @override
  String get materialsMessageLabel => 'Message';

  @override
  String get materialsSending => 'Creating link…';

  @override
  String get materialsLinkReady => 'Link created and logged on the lead.';

  @override
  String get materialsCopyLink => 'Copy link';

  @override
  String get materialsLinkCopied => 'Link copied';

  @override
  String get materialsLibraryEmpty =>
      'No materials in the library yet. Ask a manager to upload the price list.';

  @override
  String get materialsRetry => 'Retry';

  @override
  String get materialsNothingSent => 'Nothing sent yet.';

  @override
  String get materialsHistoryUnavailable =>
      'Could not load what was sent before.';

  @override
  String get materialsNotOpenedYet => 'Not opened yet';

  @override
  String materialsPageCount(Object count) {
    return '$count pages';
  }

  @override
  String materialsStillPreparing(Object count) {
    return '$count of these files are still being prepared. The link works now; the first open may take a few seconds.';
  }

  @override
  String materialsOpenedCount(Object count) {
    return 'Opened $count×';
  }

  @override
  String materialsSendFailed(Object error) {
    return 'Could not create the link: $error';
  }

  @override
  String materialsLoadFailed(Object error) {
    return 'Could not load the material library: $error';
  }

  @override
  String materialsLinkPlaceholderHint(Object token) {
    return 'Leave $token where you want the link; it is replaced automatically when you send.';
  }

  @override
  String get sessionExpiredMessage =>
      'Your session ended. Please sign in again.';

  @override
  String get appUpdateRequiredTitle => 'Update Required';

  @override
  String get appUpdateRequiredBody =>
      'This version of Jarz POS is out of date and can no longer be used. Install the latest version to continue.';

  @override
  String appUpdateBuildLine(Object current, Object minimum) {
    return 'Installed build $current · Required build $minimum';
  }

  @override
  String get appUpdateDownloadButton => 'Download Update';

  @override
  String get appUpdateRecheckButton => 'I have installed it — retry';

  @override
  String get appUpdateOpenFailed =>
      'Could not open the download page. Ask your manager for the install link.';

  @override
  String get appUpdateInstallHint =>
      'Your browser will ask permission to install apps from this source. Allow it, then open the downloaded file to install.';

  @override
  String get appUpdateAvailableBanner =>
      'A new version is available — tap to download.';

  @override
  String get materialsZoomedIn => 'zoomed in';

  @override
  String get materialsDownloadedFile => 'downloaded';

  @override
  String materialsReadFor(Object time) {
    return 'Read for $time';
  }

  @override
  String materialsPagesRead(Object count) {
    return '$count pages';
  }

  @override
  String get commonDone => 'Done';

  @override
  String get visitAddToRoute => 'Add to a route';

  @override
  String get visitAddStop => 'Add';

  @override
  String get visitAddedToRoute => 'Added to the route';

  @override
  String get visitOpenRoute => 'Open';

  @override
  String visitWhichDoor(int count) {
    return 'Which branch? ($count located)';
  }

  @override
  String get visitWhichDay => 'Which day';

  @override
  String get visitNewRoute => 'New route…';

  @override
  String visitNewRouteOn(String date) {
    return 'New route on $date';
  }

  @override
  String get visitNoUpcomingRoutes => 'No upcoming routes yet.';

  @override
  String get visitNoDoorsToRoute => 'Nothing here can be routed to.';

  @override
  String get visitNoDoorsToRouteHint =>
      'This record has no branch with a location on it. Add a pin first and it becomes a stop.';

  @override
  String get visitFilters => 'Filters';

  @override
  String get visitClearFilters => 'Clear all';

  @override
  String get visitFilterTier => 'Fit tier';

  @override
  String get visitFilterCategory => 'Category';

  @override
  String get visitFilterArea => 'Area';

  @override
  String visitFilterMinFit(int score) {
    return 'Minimum fit score: $score';
  }

  @override
  String get visitFilterSpecialty => 'Specialty only';

  @override
  String get visitFilterNeverVisited => 'Never visited only';

  @override
  String get visitFilterNeverVisitedHint => 'Doors nobody has walked into yet.';

  @override
  String get visitEmptyDayHint =>
      'Pick doors below, or tap Plan my day. The route builds as you choose.';

  @override
  String get visitCostingDay => 'Working out the route…';

  @override
  String get visitManualOrderNote =>
      'Your order — tap Optimise to hand it back.';

  @override
  String visitSkippedNoPin(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString doors have no location and are not on the route',
      one: '1 door has no location and is not on the route',
    );
    return '$_temp0';
  }

  @override
  String get visitSaveDraft => 'Save draft';

  @override
  String get shiftCourierCarryTitle => 'Money still with couriers';

  @override
  String shiftCourierCarryBody(int transactions, Object amount, int couriers) {
    return '$transactions order(s) worth $amount are still out with $couriers courier(s). Confirm each one, or settle it now.';
  }

  @override
  String get shiftCourierCarryHint =>
      'Tick every order whose cash is still with the courier. Anything you leave unticked must be settled before you can close.';

  @override
  String get shiftCourierCarryConfirmAll => 'Confirm all';

  @override
  String get shiftCourierCarryClearAll => 'Clear all';

  @override
  String get shiftCourierCarrySettleNow => 'Settle a courier now';

  @override
  String shiftCourierCarryConfirmedOf(int confirmed, int total) {
    return '$confirmed of $total confirmed';
  }

  @override
  String shiftCourierCarryRowLabel(Object invoice, Object customer) {
    return '$invoice — $customer';
  }

  @override
  String get shiftCourierCarryCheckboxLabel => 'Cash still with the courier';

  @override
  String shiftCourierCarryCarriedBadge(int count, int days) {
    return 'Carried $count shift(s) · $days day(s) out';
  }

  @override
  String get shiftCourierCarryUnconfirmed =>
      'Confirm every order still out with a courier, or settle it, before closing.';

  @override
  String shiftCourierCarriedSummary(int count, Object amount) {
    return '$count order(s) worth $amount left the shift still with couriers. They stay open until settled.';
  }

  @override
  String shiftMonitorCarriedOut(int count, Object amount) {
    return 'Carried out: $count · $amount';
  }

  @override
  String shiftMonitorSettledIn(int count, Object amount) {
    return 'Collected from earlier shifts: $count · $amount';
  }

  @override
  String get shiftMonitorCourierOutstandingTitle => 'Out with couriers now';

  @override
  String shiftMonitorCourierOutstandingSummary(
    Object amount,
    int transactions,
    int days,
  ) {
    return '$amount across $transactions order(s); oldest $days day(s) out.';
  }

  @override
  String get shiftMonitorCourierOutstandingEmpty =>
      'No courier is holding cash right now.';

  @override
  String shiftMonitorCourierRow(Object name, Object branch) {
    return '$name · $branch';
  }

  @override
  String shiftMonitorCourierRowDetail(int count, Object amount, int days) {
    return '$count order(s) · $amount · oldest $days day(s)';
  }

  @override
  String get expensesAdvanceTabExpenses => 'Expenses';

  @override
  String get expensesAdvanceTabAdvances => 'Employee Advances';

  @override
  String get expensesAdvanceNewRequest => 'New Advance';

  @override
  String get expensesAdvanceFormTitle => 'Request Employee Advance';

  @override
  String get expensesAdvanceEmployeeLabel => 'Employee';

  @override
  String get expensesAdvanceEmployeeRequired => 'Select an employee';

  @override
  String get expensesAdvanceEmployeeHint => 'Tap to choose an employee';

  @override
  String get expensesAdvanceEmployeePickerTitle => 'Choose employee';

  @override
  String get expensesAdvanceEmployeeSearchHint =>
      'Search by name, branch or department';

  @override
  String get expensesAdvanceEmployeeNoMatches =>
      'No employees match that search';

  @override
  String get expensesAdvanceAmountLabel => 'Advance amount';

  @override
  String get expensesAdvanceAmountInvalid => 'Enter a valid amount';

  @override
  String get expensesAdvancePurposeLabel => 'Purpose';

  @override
  String get expensesAdvancePurposeRequired =>
      'Describe what the advance is for';

  @override
  String get expensesAdvancePayFromLabel => 'Pay from';

  @override
  String get expensesAdvancePaymentSourceRequired => 'Select a payment source';

  @override
  String get expensesAdvanceSalaryMonthLabel => 'Deduct from the salary of';

  @override
  String get expensesAdvanceSalaryMonthHelp =>
      'The cash is paid out on the advance date from the account above either way. This only decides which month’s salary it is deducted from — before pay day that is usually last month’s.';

  @override
  String get expensesAdvanceSalaryMonthRequired =>
      'Choose which month’s salary this advance is from.';

  @override
  String get expensesAdvanceSalaryMonthSuggested => 'suggested';

  @override
  String get expensesAdvanceSalaryMonthCardLabel => 'Salary month';

  @override
  String expensesAdvanceSalaryMonthChip(String month) {
    return 'Salary of $month';
  }

  @override
  String get expensesAdvanceDateLabel => 'Advance date (optional)';

  @override
  String get expensesAdvanceDateNotSet => 'Today';

  @override
  String get expensesAdvanceDateClear => 'Clear date';

  @override
  String get expensesAdvanceSubmit => 'Submit request';

  @override
  String get expensesAdvanceNoOptions =>
      'Advances cannot be requested until an employee list and a payment source are available.';

  @override
  String get expensesAdvanceSubmitted =>
      'Advance request submitted for approval';

  @override
  String get expensesAdvanceMonthLabel => 'Month';

  @override
  String get expensesAdvanceStatusFilterLabel => 'Status';

  @override
  String get expensesAdvanceStatusFilterAll => 'All statuses';

  @override
  String get expensesAdvanceEmptyTitle =>
      'No employee advances for this month.';

  @override
  String get expensesAdvanceEmptyApproverBody =>
      'Requests raised by line managers will appear here for approval.';

  @override
  String get expensesAdvanceEmptyRequesterBody =>
      'Use the New Advance button to request cash for an employee.';

  @override
  String get expensesAdvanceEmptyReadOnlyBody =>
      'You do not have permission to request or approve advances.';

  @override
  String get expensesAdvanceUnavailableTitle =>
      'Employee advances are unavailable';

  @override
  String get expensesAdvanceUnavailableBody =>
      'The HR module is not installed on this site, so advances cannot be requested here.';

  @override
  String get expensesAdvanceSummaryTotal => 'Total';

  @override
  String get expensesAdvanceSummaryPending => 'Awaiting approval';

  @override
  String get expensesAdvanceSummaryApproved => 'Approved';

  @override
  String get expensesAdvanceSummaryOutstanding => 'Outstanding';

  @override
  String expensesAdvanceSummaryCount(int count) {
    return '$count request(s)';
  }

  @override
  String expensesAdvanceSummaryPendingValue(int count, Object amount) {
    return '$count | $amount';
  }

  @override
  String get expensesAdvanceApprove => 'Approve & pay';

  @override
  String get expensesAdvanceReject => 'Reject';

  @override
  String get expensesAdvanceApproveTitle => 'Approve advance?';

  @override
  String expensesAdvanceApproveBody(
    Object amount,
    Object employee,
    Object source,
  ) {
    return 'Approving pays $amount to $employee right now, out of $source. The cash leaves that account immediately and cannot be undone from this screen.';
  }

  @override
  String get expensesAdvanceApproveConfirm => 'Approve & pay now';

  @override
  String get expensesAdvanceApproved => 'Advance approved and paid';

  @override
  String expensesAdvanceApprovedWithEntry(Object entry) {
    return 'Advance approved and paid · $entry';
  }

  @override
  String get expensesAdvanceRejectTitle => 'Reject advance request?';

  @override
  String get expensesAdvanceRejectHint =>
      'Tell the requester why this was rejected';

  @override
  String get expensesAdvanceRejectReasonRequired => 'A reason is required';

  @override
  String get expensesAdvanceRejected => 'Advance request rejected';

  @override
  String get expensesAdvanceIdLabel => 'Advance';

  @override
  String get expensesAdvancePostingDateLabel => 'Advance date';

  @override
  String get expensesAdvanceBranchLabel => 'Branch';

  @override
  String get expensesAdvancePayingAccountLabel => 'Paying account';

  @override
  String get expensesAdvancePaidLabel => 'Paid';

  @override
  String get expensesAdvanceClaimedLabel => 'Claimed';

  @override
  String get expensesAdvanceReturnedLabel => 'Returned';

  @override
  String get expensesAdvanceBalanceLabel => 'Outstanding balance';

  @override
  String get expensesAdvanceRequestedByLabel => 'Requested by';

  @override
  String get expensesAdvanceApprovedByLabel => 'Approved by';

  @override
  String get expensesAdvanceApprovedOnLabel => 'Approved on';

  @override
  String get expensesAdvancePaymentEntryLabel => 'Payment Entry';

  @override
  String get expensesAdvanceStatusDraft => 'Awaiting approval';

  @override
  String get expensesAdvanceStatusPaid => 'Paid';

  @override
  String get expensesAdvanceStatusPartiallyPaid => 'Partially Paid';

  @override
  String get expensesAdvanceStatusUnpaid => 'Unpaid';

  @override
  String get expensesAdvanceStatusClaimed => 'Claimed';

  @override
  String get expensesAdvanceStatusReturned => 'Returned';

  @override
  String get expensesAdvanceStatusPartlyClaimedAndReturned =>
      'Partly Claimed and Returned';

  @override
  String get expensesAdvanceStatusCancelled => 'Cancelled';

  @override
  String get expensesAdvanceSummarySalaryPaid =>
      'Salary paid (Monthly Expenses)';

  @override
  String get expensesAdvanceSummaryHandedOut => 'Total handed to staff';

  @override
  String get expensesAdvanceSalarySectionTitle =>
      'Salary paid from Monthly Expenses';

  @override
  String get expensesAdvanceSalarySectionHelp =>
      'Paid from the Monthly Expenses pay sheet, counted against the salary month shown.';

  @override
  String expensesAdvanceSalaryPaidByValue(String name) {
    return 'Paid by $name';
  }

  @override
  String get kanbanStateReceived => 'Received';

  @override
  String get kanbanStateInProgress => 'In Progress';

  @override
  String get kanbanStateReady => 'Ready';

  @override
  String get cancelReasonCustomerRequested => 'Customer requested cancellation';

  @override
  String get cancelReasonCreatedInError => 'Order created in error / duplicate';

  @override
  String get cancelReasonInventoryUnavailable => 'Inventory unavailable';

  @override
  String get cancelReasonPaymentIssue => 'Payment issue';

  @override
  String get cancelReasonOther => 'Other';

  @override
  String get notSuitableReasonOutOfBusiness => 'Out of Business';

  @override
  String get notSuitableReasonWrongCategory => 'Wrong Category';

  @override
  String get notSuitableReasonTooSmall => 'Too Small';

  @override
  String get notSuitableReasonNoContactInfo => 'No Contact Info';

  @override
  String get notSuitableReasonUnreachable => 'Unreachable';

  @override
  String get notSuitableReasonAlreadySupplied => 'Already Supplied';

  @override
  String get notSuitableReasonPriceMismatch => 'Price Mismatch';

  @override
  String get notSuitableReasonOutsideDeliveryArea => 'Outside Delivery Area';

  @override
  String get notSuitableReasonDuplicate => 'Duplicate';

  @override
  String get notSuitableReasonNotInterested => 'Not Interested';

  @override
  String get notSuitableReasonOther => 'Other';

  @override
  String get leadSourceWalkIn => 'Walk In';

  @override
  String get leadSourceReference => 'Reference';

  @override
  String get leadSourceCampaign => 'Campaign';

  @override
  String get leadSourceExistingCustomer => 'Existing Customer';

  @override
  String get leadSourceColdCall => 'Cold Call';

  @override
  String get leadSourceSocialMedia => 'Social Media';

  @override
  String get customerSegmentChampion => 'Champion';

  @override
  String get customerSegmentLoyal => 'Loyal';

  @override
  String get customerSegmentPotentialLoyalist => 'Potential Loyalist';

  @override
  String get customerSegmentNewCustomer => 'New Customer';

  @override
  String get customerSegmentAtRisk => 'At Risk';

  @override
  String get customerSegmentCantLoseThem => 'Can\'t Lose Them';

  @override
  String get customerSegmentLost => 'Lost';

  @override
  String get customerSegmentOneTime => 'One-Time';

  @override
  String get customerSegmentUnclassified => 'Unclassified';

  @override
  String get velocityTrendAccelerating => 'Accelerating';

  @override
  String get velocityTrendStable => 'Stable';

  @override
  String get velocityTrendDeclining => 'Declining';

  @override
  String get velocityTrendNewItem => 'New Item';

  @override
  String get velocityTrendNoSales => 'No Sales';

  @override
  String get visitStatusPlanned => 'Planned';

  @override
  String get visitStatusInProgress => 'In Progress';

  @override
  String get visitStatusVisited => 'Visited';

  @override
  String get visitStatusSkipped => 'Skipped';

  @override
  String get materialTypePriceList => 'Price List';

  @override
  String get materialTypeProductPhotos => 'Product Photos';

  @override
  String get materialTypeCatalog => 'Catalog';

  @override
  String get materialTypeCertificate => 'Certificate';

  @override
  String get materialTypeOther => 'Other';

  @override
  String get b2bStageShortLead => 'Lead';

  @override
  String get b2bStageShortQualify => 'Qual';

  @override
  String get b2bStageShortSample => 'Samp';

  @override
  String get b2bStageShortApproved => 'Appr';

  @override
  String get b2bStageShortTrial => 'Trial';

  @override
  String get b2bStageShortCheckup => 'Chk';

  @override
  String get b2bStageShortActive => 'Actv';

  @override
  String get b2bStageShortLostOnHold => 'Lost';

  @override
  String get statusChanged => 'Changed';

  @override
  String get statusSettled => 'Settled';

  @override
  String get statusUnsettled => 'Unsettled';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusActive => 'Active';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusEnded => 'Ended';

  @override
  String get statusClosed => 'Closed';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get reportsColumnItem => 'Item';

  @override
  String get reportsColumnVelocity30d => 'Vel 30d';

  @override
  String get reportsColumnVelocity60d => 'Vel 60d';

  @override
  String get reportsColumnTrend => 'Trend';

  @override
  String get reportsColumnStock => 'Stock';

  @override
  String get reportsColumnCover => 'Cover';

  @override
  String get reportsColumnSold => 'Sold';

  @override
  String get reportsColumnRevenue => 'Revenue';

  @override
  String get reportsColumnVelocity => 'Velocity';

  @override
  String get menuShiftDistribution => 'Shift Distribution';

  @override
  String get rosterTitle => 'Shift Distribution';

  @override
  String get rosterAccessDenied =>
      'Shift distribution is for managers and line managers only.';

  @override
  String get rosterHoursTitle => 'Hours & overtime';

  @override
  String get rosterHoursBasis =>
      'Rostered hours — what people were scheduled to work. Overtime is credited at each person\'s rate.';

  @override
  String get rosterPreviousMonth => 'Previous month';

  @override
  String get rosterNextMonth => 'Next month';

  @override
  String get rosterAllBranches => 'All branches';

  @override
  String get rosterEmployeeColumn => 'Employee';

  @override
  String get rosterHrmsMissing =>
      'HRMS is not installed on this site, so there is no roster to show.';

  @override
  String get rosterNobodyRostered => 'Nobody is rostered for this month yet.';

  @override
  String get rosterScopeUnconfigured =>
      'No branches are linked to your POS profiles yet, so there is nobody to show. Ask an administrator to set the HR Shift Location on your POS Profile.';

  @override
  String rosterUncoveredWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days off with nobody covering',
      one: '1 day off with nobody covering',
    );
    return '$_temp0';
  }

  @override
  String rosterStandardDay(Object hours) {
    return 'Normal day: ${hours}h';
  }

  @override
  String get rosterOffShort => 'OFF';

  @override
  String get rosterHolidayShort => 'HOL';

  @override
  String get rosterChangeShift => 'Change shift';

  @override
  String get rosterMarkDayOff => 'Mark day off';

  @override
  String get rosterClearDayOff => 'Cancel this day off';

  @override
  String get rosterNoShiftTypes => 'No shift types are configured yet.';

  @override
  String rosterShowAllShifts(int count) {
    return 'Show all shifts ($count)';
  }

  @override
  String get rosterShowMyShifts => 'Show only this person’s shifts';

  @override
  String rosterShiftWindow(Object window, Object hours) {
    return '$window · ${hours}h';
  }

  @override
  String rosterWorkingShift(Object shiftType, Object hours, Object location) {
    return 'On $shiftType · ${hours}h · $location';
  }

  @override
  String rosterOffCoveredBy(Object offType, Object name) {
    return 'Off ($offType) — covered by $name';
  }

  @override
  String rosterOffUncovered(Object offType) {
    return 'Off ($offType) — nobody is covering this day';
  }

  @override
  String get rosterHoliday => 'Holiday';

  @override
  String get rosterUnrosteredWarning =>
      'Not on the roster — this person cannot check in on this day.';

  @override
  String get rosterOffType => 'Reason';

  @override
  String get rosterCoveredBy => 'Covered by';

  @override
  String get rosterCoverHelper => 'Who absorbs this day at the branch.';

  @override
  String get rosterNobodyCovers => 'Nobody';

  @override
  String get rosterCoverShift => 'Cover shift';

  @override
  String get rosterCoverShiftHelper =>
      'The shift they move onto for this day, normally the longer full-day one.';

  @override
  String get rosterNotes => 'Notes (optional)';

  @override
  String get rosterOffTypeWeekly => 'Weekly off';

  @override
  String get rosterOffTypeVacation => 'Vacation';

  @override
  String get rosterOffTypeSick => 'Sick';

  @override
  String get rosterOffTypeUnpaid => 'Unpaid';

  @override
  String get rosterOffTypeOther => 'Other';

  @override
  String get rosterWorkedHours => 'Worked';

  @override
  String get rosterOvertimeHours => 'Overtime';

  @override
  String get rosterCreditedOvertime => 'Credited OT';

  @override
  String get rosterCreditedHours => 'Paid hours';

  @override
  String rosterCourierTag(Object multiplier) {
    return 'Courier ×$multiplier';
  }

  @override
  String rosterRowDays(Object worked, Object off, Object cover) {
    return '$worked worked · $off off · $cover cover';
  }

  @override
  String get rosterLegendWorking => 'Working';

  @override
  String get rosterLegendOff => 'Day off';

  @override
  String get rosterLegendUnrostered => 'Not rostered';

  @override
  String get rosterLegendHoliday => 'Holiday';

  @override
  String get settlementPartnerFeeInputLabel => 'Partner delivery cost';

  @override
  String get settlementPartnerFeeInputHint => 'Read it from the partner\'s app';

  @override
  String get settlementPartnerFeeRequired =>
      'Enter the partner\'s delivery cost for this order';

  @override
  String get settlementPartnerFeeInvalid => 'Enter a valid amount';

  @override
  String get settlementPartnerFeeWhy =>
      'Our area rates don\'t apply to the partner - they price this address themselves.';

  @override
  String get settlementPartnerNoDeduction =>
      'The rider hands over the full amount. Nothing is deducted for his fee - his company is billed weekly.';

  @override
  String get commonReasonRequired => 'A reason is required';

  @override
  String get expensesReject => 'Reject';

  @override
  String get expensesRejectTitle => 'Reject this expense?';

  @override
  String get expensesRejectHint => 'Tell the person who filed it why';

  @override
  String get expensesRejected => 'Expense rejected';

  @override
  String get expensesRejectedStatus => 'Rejected';

  @override
  String get expensesRejectionReason => 'Rejection reason';

  @override
  String get expensesCancelAction => 'Cancel expense';

  @override
  String get expensesCancelTitle => 'Cancel this approved expense?';

  @override
  String expensesCancelBody(Object amount, Object source) {
    return 'This reverses the journal entry for $amount and puts the money back in $source.';
  }

  @override
  String get expensesCancelHint => 'Why is this being reversed?';

  @override
  String get expensesCancelConfirm => 'Cancel & reverse';

  @override
  String get expensesCancelled =>
      'Expense cancelled and journal entry reversed';

  @override
  String get productionCancelBatch => 'Cancel batch';

  @override
  String get productionCancelBatchTitle => 'Cancel this batch?';

  @override
  String productionCancelBatchBody(Object item) {
    return 'Everything still in WIP for $item goes back to the store. Nothing has been produced yet, so no finished goods are affected.';
  }

  @override
  String get productionCancelBatchHint =>
      'Why is this batch not being finished?';

  @override
  String get productionCancelBatchConfirm => 'Cancel batch';

  @override
  String get productionBatchCancelled =>
      'Batch cancelled and material returned to store';

  @override
  String get productionPlanCancel => 'Cancel plan';

  @override
  String get productionPlanCancelTitle => 'Cancel this day\'s plan?';

  @override
  String get productionPlanCancelBody =>
      'Use this when the day will not be produced at all. Closing with zero counts instead would record a day that tried and made nothing.';

  @override
  String get productionPlanCancelHint => 'Why is the day being called off?';

  @override
  String get productionPlanCancelConfirm => 'Cancel plan';

  @override
  String get productionPlanCancelled => 'Production plan cancelled';

  @override
  String get productionPlanCancelledStatus => 'Cancelled';

  @override
  String get receiptReject => 'Reject';

  @override
  String get receiptRejectTitle => 'Reject this receipt?';

  @override
  String get receiptRejectHint => 'What is wrong with the proof of transfer?';

  @override
  String get receiptRejectConfirm => 'Reject receipt';

  @override
  String get receiptRejected => 'Receipt rejected';

  @override
  String get receiptRejectedStatus => 'Rejected';

  @override
  String get receiptRejectionReason => 'Rejection reason';

  @override
  String get historyDateRangeAll => 'All dates';

  @override
  String historyDateRangeValue(Object from, Object to) {
    return '$from - $to';
  }

  @override
  String get stockTransferHistoryTitle => 'Transfer history';

  @override
  String get stockTransferHistorySearchHint => 'Entry no. or item';

  @override
  String get stockTransferHistoryEmpty => 'No stock transfers yet.';

  @override
  String stockTransferHistoryRoute(Object source, Object target) {
    return '$source to $target';
  }

  @override
  String get stockTransferHistoryMixed => 'Multiple warehouses';

  @override
  String stockTransferHistorySummary(Object items, Object qty) {
    return '$items items, $qty units';
  }

  @override
  String get cashTransferHistoryTitle => 'Cash transfer history';

  @override
  String get cashTransferHistorySearchHint => 'Entry no. or remark';

  @override
  String get cashTransferHistoryEmpty => 'No cash transfers yet.';

  @override
  String get inventoryCountHistoryTitle => 'Count history';

  @override
  String get inventoryCountHistorySearchHint => 'Count no. or item';

  @override
  String get inventoryCountHistoryEmpty => 'No stock counts yet.';

  @override
  String inventoryCountHistoryAdjusted(Object items) {
    return '$items items adjusted';
  }

  @override
  String inventoryCountHistoryDeltas(Object up, Object down) {
    return '$up up, $down down';
  }

  @override
  String get inventoryCountHistoryValueChange => 'Value change';

  @override
  String get shiftHistoryTitle => 'Shift history';

  @override
  String get shiftHistoryEmpty => 'No shifts yet.';

  @override
  String get shiftHistoryStatusOpen => 'Open';

  @override
  String get shiftHistoryStatusClosed => 'Closed';

  @override
  String get shiftHistoryAmountsHidden => 'Amounts are shown to managers only.';

  @override
  String get shiftHistoryDifference => 'Over / short';

  @override
  String get shiftHistoryMineOnly => 'My shifts only';

  @override
  String get shiftHistoryStillOpen => 'Still open';

  @override
  String shiftHistoryDuration(Object start, Object end) {
    return '$start to $end';
  }

  @override
  String shiftHistoryOpenedBy(Object name) {
    return 'Opened by $name';
  }

  @override
  String get menuMonthlyExpenses => 'Monthly Expenses';

  @override
  String get monthlyExpensesTitle => 'Monthly Expenses';

  @override
  String get monthlyExpensesRefreshTooltip => 'Refresh';

  @override
  String get monthlyExpensesMonthLabel => 'Month';

  @override
  String get monthlyExpensesPreviousMonthTooltip => 'Previous month';

  @override
  String get monthlyExpensesNextMonthTooltip => 'Next month';

  @override
  String get monthlyExpensesLoadFailed => 'Could not load this month.';

  @override
  String get monthlyExpensesRemaining => 'Remaining';

  @override
  String get monthlyExpensesDue => 'Due';

  @override
  String get monthlyExpensesPaid => 'Paid';

  @override
  String get monthlyExpensesRunRate => 'Monthly run-rate';

  @override
  String monthlyExpensesRemainingCaption(Object paid, Object due) {
    return '$paid paid of $due due';
  }

  @override
  String monthlyExpensesOverpaidNotice(Object amount) {
    return 'Overpaid by $amount';
  }

  @override
  String monthlyExpensesItemsBreakdown(int paid, int partial, int unpaid) {
    return '$paid paid, $partial partial, $unpaid unpaid';
  }

  @override
  String monthlyExpensesItemsTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items due',
      one: '1 item due',
      zero: 'No items due',
    );
    return '$_temp0';
  }

  @override
  String get monthlyExpensesGapsTitle => 'Needs attention';

  @override
  String get monthlyExpensesRecurringTitle => 'Recurring expenses';

  @override
  String get monthlyExpensesRecurringEmpty =>
      'Nothing is in the recurring expense registry yet.';

  @override
  String get monthlyExpensesCategoryUncategorised => 'Uncategorised';

  @override
  String monthlyExpensesCategorySubtotal(Object remaining, Object due) {
    return '$remaining left of $due';
  }

  @override
  String get monthlyExpensesStatusPaid => 'Paid';

  @override
  String get monthlyExpensesStatusPartial => 'Partial';

  @override
  String get monthlyExpensesStatusUnpaid => 'Unpaid';

  @override
  String get monthlyExpensesStatusNotDue => 'Not due';

  @override
  String get monthlyExpensesStatusOverpaid => 'Overpaid';

  @override
  String get monthlyExpensesStatusAwaitingVisit => 'Awaiting visit';

  @override
  String get monthlyExpensesStatusNoVisit => 'No visit';

  @override
  String get monthlyExpensesPaidOnVisit => 'Paid on the visit';

  @override
  String monthlyExpensesAmountRaised(
    Object amount,
    Object month,
    Object previous,
  ) {
    return 'Raised to $amount from $month (was $previous)';
  }

  @override
  String monthlyExpensesAmountLowered(
    Object amount,
    Object month,
    Object previous,
  ) {
    return 'Lowered to $amount from $month (was $previous)';
  }

  @override
  String monthlyExpensesAmountUpcoming(Object amount, Object month) {
    return '$amount from $month';
  }

  @override
  String get monthlyExpensesAppliesFromLabel => 'Applies from';

  @override
  String get monthlyExpensesAppliesFromHelper =>
      'Earlier months keep the old amount.';

  @override
  String get monthlyExpensesPayOnVisitLabel =>
      'Paid when the service is done (no fixed day)';

  @override
  String get monthlyExpensesAmountHistoryTitle => 'Amount history';

  @override
  String get monthlyExpensesAmountHistoryRemoveTooltip => 'Remove this change';

  @override
  String get monthlyExpensesAmountHistoryRemoveTitle => 'Remove amount change?';

  @override
  String monthlyExpensesAmountHistoryRemoveBody(Object amount, Object month) {
    return 'Remove the $amount that starts in $month? That month and the following ones go back to the previous amount.';
  }

  @override
  String get monthlyExpensesAmountHistoryRemoved => 'Amount change removed';

  @override
  String get monthlyExpensesLifecyclePaused => 'Paused';

  @override
  String get monthlyExpensesLifecycleEnded => 'Ended';

  @override
  String get monthlyExpensesPayAction => 'Pay';

  @override
  String get monthlyExpensesInferredBadge => 'From the ledger';

  @override
  String monthlyExpensesInferredExplain(Object amount) {
    return '$amount of the paid figure was read from the ledger, not paid through this app.';
  }

  @override
  String get monthlyExpensesSharedAccountBadge => 'Shared account';

  @override
  String monthlyExpensesSharedAccountExplain(Object account) {
    return 'Other expenses post to $account this month, so ledger payments cannot be matched to this one.';
  }

  @override
  String get monthlyExpensesFrequencyLabel => 'Frequency';

  @override
  String get monthlyExpensesDueDateLabel => 'Due date';

  @override
  String get monthlyExpensesAccountLabel => 'Expense account';

  @override
  String get monthlyExpensesCostCenterLabel => 'Cost center';

  @override
  String get monthlyExpensesSupplierLabel => 'Supplier';

  @override
  String get monthlyExpensesNotesLabel => 'Notes';

  @override
  String get monthlyExpensesAmountLabel => 'Amount';

  @override
  String get monthlyExpensesMonthlyEquivalentLabel => 'Monthly equivalent';

  @override
  String get monthlyExpensesPaymentsTitle => 'Payments';

  @override
  String get monthlyExpensesPaymentsEmpty =>
      'No payments recorded for this month.';

  @override
  String get monthlyExpensesPaymentCancelAction => 'Cancel payment';

  @override
  String get monthlyExpensesPaymentCancelTitle => 'Cancel this payment?';

  @override
  String monthlyExpensesPaymentCancelBody(Object amount, Object source) {
    return 'This reverses the journal entry for $amount and puts the money back in $source.';
  }

  @override
  String get monthlyExpensesPaymentCancelHint => 'Why is this being reversed?';

  @override
  String get monthlyExpensesPaymentCancelConfirm => 'Cancel and reverse';

  @override
  String get monthlyExpensesPaymentCancelled =>
      'Payment cancelled and journal entry reversed';

  @override
  String get monthlyExpensesSalariesTitle => 'Salaries';

  @override
  String get monthlyExpensesSalariesEmpty =>
      'No employee has a salary structure for this month.';

  @override
  String get monthlyExpensesPayrollNotConfigured =>
      'Payroll is not set up, so salaries cannot be paid from this screen.';

  @override
  String get monthlyExpensesPayrollAccountLabel => 'Salary account';

  @override
  String get monthlyExpensesSalaryBaseLabel => 'Base';

  @override
  String get monthlyExpensesSalaryVariableLabel => 'Variable';

  @override
  String get monthlyExpensesSalarySlipExists =>
      'A submitted salary slip already covers this month, so paying here would post the salary twice.';

  @override
  String monthlyExpensesMissingStructureTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count employees have no salary structure',
      one: '1 employee has no salary structure',
    );
    return '$_temp0';
  }

  @override
  String get monthlyExpensesMissingStructureBody =>
      'Their pay is not in the figures above. Assign a salary structure in HR to include them.';

  @override
  String monthlyExpensesUnattributedGl(Object amount) {
    return '$amount posted to the salary account cannot be matched to any employee, so it is reported here instead of being added to a row.';
  }

  @override
  String monthlyExpensesPayTitle(Object name) {
    return 'Pay $name';
  }

  @override
  String monthlyExpensesPayPeriod(Object month) {
    return 'For $month';
  }

  @override
  String get monthlyExpensesPayAmountLabel => 'Amount to pay';

  @override
  String get monthlyExpensesPayAmountInvalid =>
      'Enter an amount greater than zero';

  @override
  String get monthlyExpensesPayFromLabel => 'Pay from';

  @override
  String get monthlyExpensesPayFromRequired => 'Choose an account to pay from';

  @override
  String get monthlyExpensesPayDateLabel => 'Payment date';

  @override
  String get monthlyExpensesPayRemarksLabel => 'Remarks (optional)';

  @override
  String get monthlyExpensesPaySubmit => 'Pay';

  @override
  String monthlyExpensesPaySourceOption(Object label, Object balance) {
    return '$label — $balance';
  }

  @override
  String get monthlyExpensesPayNoSources =>
      'No cash or bank account is available to pay from.';

  @override
  String monthlyExpensesPayRemainingHint(Object amount) {
    return 'Remaining: $amount';
  }

  @override
  String get monthlyExpensesPaymentRecorded => 'Payment recorded';

  @override
  String get monthlyExpensesOverpayTitle => 'More than what is due';

  @override
  String get monthlyExpensesOverpayConfirm => 'Pay anyway';

  @override
  String get monthlyExpensesAddAction => 'Add expense';

  @override
  String get monthlyExpensesNewTitle => 'New recurring expense';

  @override
  String get monthlyExpensesEditTitle => 'Edit recurring expense';

  @override
  String get monthlyExpensesNameLabel => 'Name';

  @override
  String get monthlyExpensesNameRequired => 'Give this expense a name';

  @override
  String get monthlyExpensesAmountRequired =>
      'Enter an amount greater than zero';

  @override
  String get monthlyExpensesCategoryLabel => 'Category';

  @override
  String get monthlyExpensesCategoryRequired => 'Choose a category';

  @override
  String get monthlyExpensesFrequencyRequired => 'Choose a frequency';

  @override
  String get monthlyExpensesAccountRequired => 'Choose an expense account';

  @override
  String get monthlyExpensesDayOfMonthLabel => 'Day of month';

  @override
  String get monthlyExpensesDayOfMonthInvalid => 'Enter a day between 1 and 28';

  @override
  String get monthlyExpensesStartDateLabel => 'Starts';

  @override
  String get monthlyExpensesEndDateLabel => 'Ends (optional)';

  @override
  String get monthlyExpensesDefaultPayingAccountLabel =>
      'Usually paid from (optional)';

  @override
  String get monthlyExpensesNoneOption => 'None';

  @override
  String get monthlyExpensesSaved => 'Recurring expense saved';

  @override
  String get monthlyExpensesManageTooltip => 'Manage';

  @override
  String get monthlyExpensesEditAction => 'Edit';

  @override
  String get monthlyExpensesPauseAction => 'Pause';

  @override
  String get monthlyExpensesResumeAction => 'Resume';

  @override
  String get monthlyExpensesEndAction => 'End';

  @override
  String monthlyExpensesEndTitle(Object name) {
    return 'End $name?';
  }

  @override
  String get monthlyExpensesEndBody =>
      'It stops being due from now on. Payments already made stay on the record.';

  @override
  String get monthlyExpensesEndConfirm => 'End it';

  @override
  String get monthlyExpensesStatusUpdated => 'Status updated';

  @override
  String get monthlyExpensesReadOnlyNotice =>
      'You can see this month but not change the registry.';

  @override
  String get monthlyExpensesFormMissingOptions =>
      'The server did not send the categories, frequencies and accounts this form needs.';

  @override
  String get monthlyExpensesSalarySlipBadge => 'Salary slip';

  @override
  String get monthlyExpensesGrossLabel => 'Gross';

  @override
  String get monthlyExpensesPenaltyLabel => 'Penalty';

  @override
  String get monthlyExpensesAdvanceLabel => 'Advance';

  @override
  String get monthlyExpensesJarsLabel => 'Jars';

  @override
  String get monthlyExpensesNetPayableLabel => 'Net to pay';

  @override
  String monthlyExpensesDeductionAmount(Object amount) {
    return '− $amount';
  }

  @override
  String monthlyExpensesDeductionsSummary(Object total, Object net) {
    return 'Deductions $total • net to hand over $net';
  }

  @override
  String monthlyExpensesOutstandingOf(Object outstanding, Object amount) {
    return '$outstanding left of $amount';
  }

  @override
  String get monthlyExpensesOffPayrollBadge => 'Off payroll';

  @override
  String get monthlyExpensesOffPayrollExplain =>
      'No salary structure for this month. This row is here because the employee still owes an advance, a staff order or a penalty.';

  @override
  String monthlyExpensesSalariesForMonth(Object month, Object payMonth) {
    return 'Salaries for $month · paid in $payMonth';
  }

  @override
  String monthlyExpensesPaySalaryPeriod(Object month) {
    return 'Salary for $month';
  }

  @override
  String monthlyExpensesLeftStaffTitle(int count) {
    return 'Left staff – still owe money ($count)';
  }

  @override
  String get monthlyExpensesLeftStaffHint =>
      'Not on this month’s payroll. Listed only because they still owe an advance or a staff order.';

  @override
  String monthlyExpensesLeftOn(Object date) {
    return 'Left on $date';
  }

  @override
  String get monthlyExpensesPenaltiesTitle => 'Penalties';

  @override
  String get monthlyExpensesAdvancesTitle => 'Advances';

  @override
  String get monthlyExpensesOrdersTitle => 'Staff orders';

  @override
  String get monthlyExpensesUnattributedTitle =>
      'Staff orders not linked to an employee';

  @override
  String monthlyExpensesUnattributedSummary(int count, String total) {
    return '$count orders · $total unpaid';
  }

  @override
  String get monthlyExpensesUnattributedHint =>
      'These unpaid staff orders belong to a customer that is not linked to any employee, so they reach no salary row. Linking staff customers to employees fixes them.';

  @override
  String monthlyExpensesPenaltyDaysAmount(Object days) {
    return '$days days';
  }

  @override
  String monthlyExpensesPenaltyEquals(Object value) {
    return '= $value';
  }

  @override
  String get monthlyExpensesPenaltyAddAction => 'Add penalty';

  @override
  String monthlyExpensesPenaltyTitle(Object name) {
    return 'Penalty for $name';
  }

  @override
  String get monthlyExpensesPenaltyUnitDays => 'Days';

  @override
  String get monthlyExpensesPenaltyUnitHalfDays => 'Half days';

  @override
  String get monthlyExpensesPenaltyUnitMoney => 'Money';

  @override
  String get monthlyExpensesPenaltyDaysLabel => 'Number of days';

  @override
  String get monthlyExpensesPenaltyHalfDaysLabel => 'Number of half days';

  @override
  String get monthlyExpensesPenaltyAmountLabel => 'Penalty amount';

  @override
  String get monthlyExpensesPenaltyQuantityInvalid =>
      'Enter a number greater than zero';

  @override
  String get monthlyExpensesPenaltyReasonLabel => 'Reason';

  @override
  String get monthlyExpensesPenaltyReasonRequired =>
      'Say why this penalty is being applied';

  @override
  String get monthlyExpensesPenaltyDateLabel => 'Date of the penalty';

  @override
  String get monthlyExpensesPenaltySubmit => 'Save penalty';

  @override
  String monthlyExpensesPenaltyDayRateHint(Object amount, Object days) {
    return 'A day is worth $amount — monthly salary ÷ $days';
  }

  @override
  String get monthlyExpensesPenaltyNoDayRate =>
      'This employee has no salary structure, so a day has no value here. Enter the penalty as money.';

  @override
  String get monthlyExpensesPenaltyRecorded => 'Penalty recorded';

  @override
  String get monthlyExpensesPenaltyCancelAction => 'Cancel penalty';

  @override
  String get monthlyExpensesPenaltyCancelTitle => 'Cancel this penalty?';

  @override
  String monthlyExpensesPenaltyCancelBody(Object amount) {
    return 'This removes the $amount penalty from the salary. It cannot be undone; enter a new penalty if it is still owed.';
  }

  @override
  String get monthlyExpensesPenaltyCancelHint => 'Why is it being cancelled?';

  @override
  String get monthlyExpensesPenaltyCancelConfirm => 'Cancel penalty';

  @override
  String get monthlyExpensesPenaltyCancelled => 'Penalty cancelled';

  @override
  String get monthlyExpensesPenaltySettledBadge => 'Settled';

  @override
  String get monthlyExpensesSettleAdvancesTitle => 'Advances to clear';

  @override
  String get monthlyExpensesSettleOrdersTitle => 'Staff orders to clear';

  @override
  String get monthlyExpensesSettleHint =>
      'Ticked balances are cleared by this payment, on top of the cash.';

  @override
  String get monthlyExpensesCashToHandOver => 'Cash to hand over';

  @override
  String get monthlyExpensesTotalDischarged => 'Total discharged';

  @override
  String get monthlyExpensesPayAmountOrSettlement =>
      'Enter an amount, or tick a balance to clear';

  @override
  String get monthlyExpensesGapsInfoTitle => 'Good to know';

  @override
  String get paymentMethodCredit => 'Credit (on account)';

  @override
  String get paymentMethodCreditSubtitle => 'Delivered now, paid later';

  @override
  String get paymentMethodCreditNotAllowed =>
      'This customer is not approved for credit';

  @override
  String get paymentMethodCreditChecking => 'Checking the credit account…';

  @override
  String get paymentMethodCreditUnavailable =>
      'Could not check the credit account right now';

  @override
  String paymentMethodCreditAvailable(Object amount) {
    return 'Available credit: $amount';
  }

  @override
  String get paymentMethodCreditNoLimit => 'No credit limit set';

  @override
  String paymentMethodCreditTerms(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Due in $_temp0';
  }

  @override
  String paymentMethodCreditOnAccount(Object amount) {
    return 'Already on account: $amount';
  }

  @override
  String get paymentMethodCreditOverLimit =>
      'This customer has used all of their credit';

  @override
  String get menuCreditAccounts => 'Credit Accounts';

  @override
  String get creditAccountsTitle => 'Credit Accounts';

  @override
  String get creditAccountsSubtitle =>
      'Shops with an open balance, largest first';

  @override
  String get creditAccountsPeriodLabel => 'Period';

  @override
  String get creditAccountsWindow30 => 'Last 30 days';

  @override
  String get creditAccountsWindow90 => 'Last 90 days';

  @override
  String get creditAccountsWindow180 => 'Last 180 days';

  @override
  String get creditAccountsWindow365 => 'Last 365 days';

  @override
  String get creditAccountsTotalOutstanding =>
      'Total on account in this period';

  @override
  String get creditAccountsTotalOutstandingAllTime =>
      'Total on account (all time)';

  @override
  String get creditAccountsAllTimeHint =>
      'Every open invoice, whatever its age. The period below only controls which invoices are listed.';

  @override
  String creditAccountsCustomerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shops owe money',
      one: '1 shop owes money',
      zero: 'No shop owes anything',
    );
    return '$_temp0';
  }

  @override
  String creditAccountsListedInvoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices listed',
      one: '1 invoice listed',
      zero: 'No invoices listed',
    );
    return '$_temp0';
  }

  @override
  String creditAccountsActivityRange(Object from, Object to) {
    return 'Listed invoices: $from to $to';
  }

  @override
  String get creditAccountsEmpty => 'No shop has an open credit balance';

  @override
  String get creditAccountsLoadFailed => 'Failed to load credit accounts';

  @override
  String get creditAccountsNoticeResultsTruncated =>
      'Only the first results are shown. Narrow the branch or the period to see the rest.';

  @override
  String creditAccountsOpenInvoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open invoices',
      one: '1 open invoice',
      zero: 'No open invoices',
    );
    return '$_temp0';
  }

  @override
  String creditAccountsOldestAge(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
      zero: 'today',
    );
    return 'Oldest $_temp0';
  }

  @override
  String get creditAccountsOldestUnknown => 'Oldest invoice not dated';

  @override
  String get creditAccountBalanceLabel => 'Balance on account';

  @override
  String get creditAccountOpenInvoicesTitle => 'Open invoices, oldest first';

  @override
  String get creditAccountInvoiceOutstandingLabel => 'Outstanding';

  @override
  String get creditAccountInvoiceTotalLabel => 'Invoice total';

  @override
  String creditAccountInvoiceAge(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days old',
      one: '1 day old',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String get creditAccountNoInvoicesInWindow =>
      'Nothing listed in this period. The balance above is older than that, so widen the period to see the invoices behind it.';

  @override
  String get creditAccountRecordPayment => 'Record payment';

  @override
  String creditAccountTerms(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Terms: $_temp0';
  }

  @override
  String creditAccountLimit(Object amount) {
    return 'Credit limit $amount';
  }

  @override
  String creditAccountAvailable(Object amount) {
    return 'Available $amount';
  }

  @override
  String get creditSendToCustomer => 'Send to customer';

  @override
  String get creditSendModeIndividual => 'Individual receipts';

  @override
  String get creditSendModeConsolidated => 'Consolidated statement';

  @override
  String get creditSendModeIndividualHint =>
      'One receipt for each order you choose.';

  @override
  String get creditSendModeConsolidatedHint =>
      'All the orders you choose in one statement, with the total due.';

  @override
  String get creditSendSelectAll => 'Select all';

  @override
  String creditSendSelectedCount(int selected, int total) {
    return '$selected of $total selected';
  }

  @override
  String creditSendTotalDue(String amount) {
    return 'Total due: $amount';
  }

  @override
  String get creditSendWhatsApp => 'WhatsApp';

  @override
  String get creditSendShare => 'Share';

  @override
  String get creditSendLoadFailed => 'Could not load the orders. Try again.';

  @override
  String get creditAccountFifoHint =>
      'A payment clears the oldest invoices first.';

  @override
  String get creditPaymentTitle => 'Record payment';

  @override
  String get creditPaymentAmountLabel => 'Amount';

  @override
  String creditPaymentFullBalanceHint(Object amount) {
    return 'Full balance is $amount';
  }

  @override
  String get creditPaymentMethodLabel => 'Paid by';

  @override
  String get creditPaymentBranchLabel => 'Branch';

  @override
  String get creditPaymentBranchMissing =>
      'Choose the branch that received the money';

  @override
  String get creditPaymentBranchLoadFailed => 'Failed to load branches';

  @override
  String get creditPaymentRemarksLabel => 'Note (optional)';

  @override
  String get creditPaymentSubmit => 'Record payment';

  @override
  String get creditPaymentAmountInvalid => 'Enter an amount greater than zero';

  @override
  String get creditPaymentAmountExceedsBalance =>
      'More than the balance. The extra will sit as an advance.';

  @override
  String get creditPaymentFailed => 'Failed to record payment';

  @override
  String get creditPaymentFifoNotice =>
      'The amount is applied to the oldest invoices first, so it may not clear the ones you expect.';

  @override
  String get creditSettingsTitle => 'Credit account';

  @override
  String get creditSettingsAllowed => 'Orders on credit allowed';

  @override
  String get creditSettingsNotAllowed => 'Credit not allowed';

  @override
  String get creditSettingsAllowSwitch => 'Allow orders on credit';

  @override
  String get creditSettingsDaysLabel => 'Credit days';

  @override
  String get creditSettingsDaysHelper => '0 uses the default of 30 days';

  @override
  String get creditSettingsLimitLabel => 'Credit limit';

  @override
  String get creditSettingsLimitHelper => 'Leave empty or 0 for no limit';

  @override
  String get creditSettingsNoLimit => 'No limit';

  @override
  String get creditSettingsEdit => 'Edit credit';

  @override
  String get creditSettingsSaved => 'Credit settings saved';

  @override
  String get creditSettingsSaveFailed => 'Failed to save credit settings';

  @override
  String get creditSettingsDaysInvalid => 'Enter days between 0 and 365';

  @override
  String get creditSettingsLimitInvalid => 'Enter a limit of 0 or more';

  @override
  String creditSettingsOffWithBalance(Object amount) {
    return 'Credit is off for new orders. $amount is still owed and can still be collected.';
  }

  @override
  String get creditAccountPayInvoice => 'Pay this order';

  @override
  String creditPaymentTargetInvoice(Object invoice) {
    return 'For order $invoice';
  }

  @override
  String creditPaymentTargetOutstandingHint(Object amount) {
    return 'Outstanding on this order $amount';
  }

  @override
  String get creditPaymentTargetNotice =>
      'The amount goes to this order first. Anything extra clears the oldest open orders.';

  @override
  String get creditPaymentResultTitle => 'Payment recorded';

  @override
  String creditPaymentResultCleared(int count, Object amount, Object invoices) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount cleared invoices $invoices',
      one: '$amount cleared invoice $invoices',
    );
    return '$_temp0';
  }

  @override
  String creditPaymentResultPartial(Object amount, Object invoice) {
    return '$amount went to invoice $invoice, which is still partly open';
  }

  @override
  String creditPaymentResultAdvance(Object amount) {
    return '$amount left as an advance';
  }

  @override
  String creditPaymentResultNoneAllocated(Object amount) {
    return 'Nothing was open, so all $amount is sitting as an advance';
  }

  @override
  String creditPaymentResultRemaining(Object amount) {
    return 'Still on account: $amount';
  }

  @override
  String creditPaymentResultEntry(Object name) {
    return 'Payment entry $name';
  }

  @override
  String creditListJoin(Object first, Object last) {
    return '$first and $last';
  }

  @override
  String get creditAccountBranchScopeNote =>
      'This balance covers the branches you can see. A payment always clears the shop\'s oldest invoices first across every branch, so it can settle invoices that are not listed here.';

  @override
  String get creditAccountNoOpenInvoices => 'No open invoices for this shop.';

  @override
  String creditPaymentResultAlreadyRecorded(Object amount) {
    return 'This payment was already recorded. The $amount went in earlier and nothing was posted a second time.';
  }

  @override
  String get creditPaymentResultAlreadyRecordedHint =>
      'Refresh the account to see the balance after it.';

  @override
  String get creditPaymentResultAlreadyRecordedTitle => 'Already recorded';

  @override
  String get menuReplenishment => 'Send to Branches';

  @override
  String get replenishmentTitle => 'Send to Branches';

  @override
  String replenishmentHeaderBasis(int coverDays, int salesDays) {
    return '$coverDays days cover · $salesDays days sales';
  }

  @override
  String replenishmentUpdatedAt(String time) {
    return 'updated $time';
  }

  @override
  String replenishmentTabLabel(String name, int count) {
    return '$name · $count';
  }

  @override
  String replenishmentMovesSummary(String qty) {
    return 'Other branches can cover $qty units';
  }

  @override
  String get replenishmentFilterNeeds => 'Needs stock';

  @override
  String get replenishmentFilterAll => 'All items';

  @override
  String replenishmentGroupToSend(int count) {
    return 'To send ($count)';
  }

  @override
  String replenishmentGroupNothing(int count) {
    return 'Nothing to send ($count)';
  }

  @override
  String replenishmentGroupSmall(int count) {
    return 'Small jars ($count)';
  }

  @override
  String get replenishmentGroupSmallHint =>
      'Not in regular use. Kept here for reference.';

  @override
  String replenishmentGroupSmallSending(String qty) {
    return '$qty set to send';
  }

  @override
  String get replenishmentItemDetails => 'Details';

  @override
  String get replenishmentQtyIncrease => 'One more';

  @override
  String get replenishmentQtyDecrease => 'One less';

  @override
  String get replenishmentSendShort => 'Send';

  @override
  String replenishmentCartonCountB2b(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count B2B cartons',
      one: '1 B2B carton',
    );
    return '$_temp0';
  }

  @override
  String replenishmentCartonCountLarge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count large cartons',
      one: '1 large carton',
    );
    return '$_temp0';
  }

  @override
  String replenishmentCartonsBar(String text) {
    return '📦 $text';
  }

  @override
  String replenishmentCartonsConfirmLine(String text) {
    return 'Cartons: $text';
  }

  @override
  String get replenishmentPackingGuide => 'Packing guide';

  @override
  String get replenishmentLargeInHand => 'Large cartons in hand';

  @override
  String get replenishmentCartonCapacityHint =>
      'B2B carton: 12 medium, 8 large or 20 small. Large carton: 20 medium, 11 large or 33 small. Sizes can share a carton.';

  @override
  String replenishmentPackingSummary(int cartons, int jars) {
    return '$cartons cartons · $jars jars';
  }

  @override
  String replenishmentCartonTitle(int number, String type, String fill) {
    return 'Carton $number · $type · $fill';
  }

  @override
  String get replenishmentCartonTypeB2b => 'B2B';

  @override
  String get replenishmentCartonTypeLarge => 'Large';

  @override
  String get replenishmentCartonFull => 'full';

  @override
  String replenishmentCartonPercent(int percent) {
    return '$percent% full';
  }

  @override
  String get replenishmentPackByHand => 'Pack by hand (jar size unknown)';

  @override
  String get replenishmentPackingEmpty => 'Nothing to pack yet';

  @override
  String get replenishmentPackingShare => 'Share';

  @override
  String replenishmentPackingShareHeader(String branch) {
    return 'Packing guide for $branch';
  }

  @override
  String get replenishmentMovesTitle =>
      'Factory can\'t cover all of it — other branches can help';

  @override
  String replenishmentMovesFrom(String branch, String items) {
    return 'From $branch: $items';
  }

  @override
  String replenishmentMovesRequest(String branch) {
    return 'Request from $branch';
  }

  @override
  String replenishmentMovesConfirmTitle(String branch) {
    return 'Request from $branch?';
  }

  @override
  String replenishmentMovesConfirmBody(
    String branch,
    String items,
    String target,
  ) {
    return 'Ask $branch to send $items to $target. The stock moves when $target confirms it received them.';
  }

  @override
  String replenishmentMovesSent(String branch) {
    return 'Request sent to $branch';
  }

  @override
  String replenishmentMovesFailed(String branch, String error) {
    return 'Request to $branch failed: $error';
  }

  @override
  String replenishmentMoveCanSpare(String branch, String qty) {
    return '$branch can spare $qty';
  }

  @override
  String replenishmentBasis(int coverDays, int salesDays) {
    return '$coverDays days of cover, from the last $salesDays days of sales';
  }

  @override
  String replenishmentSourceLine(String warehouse) {
    return 'From $warehouse';
  }

  @override
  String replenishmentGeneratedOn(String when) {
    return 'Worked out $when';
  }

  @override
  String get replenishmentBranchLabel => 'Branch';

  @override
  String replenishmentBranchOption(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count short',
      one: '1 short',
      zero: 'covered',
    );
    return '$name · $_temp0';
  }

  @override
  String replenishmentBelowCoverCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items below cover',
      one: '1 item below cover',
      zero: 'Nothing below cover',
    );
    return '$_temp0';
  }

  @override
  String replenishmentBranchCovered(String name) {
    return '$name has enough of everything for now';
  }

  @override
  String replenishmentNegativeBinsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items have negative stock',
      one: '1 item has negative stock',
    );
    return '$_temp0';
  }

  @override
  String replenishmentTotalShort(String qty) {
    return 'The factory is short $qty across all branches';
  }

  @override
  String replenishmentOnHand(String qty) {
    return 'Has $qty';
  }

  @override
  String replenishmentPerDay(String rate) {
    return 'Sells $rate/day';
  }

  @override
  String replenishmentDaysOfCover(String days) {
    return '$days days cover';
  }

  @override
  String get replenishmentNoSalesYet => 'No sales yet';

  @override
  String get replenishmentNegativeStock => 'Stock is negative, count this item';

  @override
  String replenishmentFactoryHas(String qty) {
    return 'Factory has $qty';
  }

  @override
  String replenishmentShortBy(String qty) {
    return 'Factory can\'t cover this — short by $qty';
  }

  @override
  String get replenishmentQtyLabel => 'Send';

  @override
  String replenishmentTypedTotal(int lineCount, String totalQty) {
    String _temp0 = intl.Intl.pluralLogic(
      lineCount,
      locale: localeName,
      other: '$lineCount lines',
      one: '1 line',
    );
    return '$_temp0 · $totalQty units';
  }

  @override
  String replenishmentSendAction(String name) {
    return 'Send to $name';
  }

  @override
  String replenishmentConfirmTitle(String name) {
    return 'Send to $name?';
  }

  @override
  String replenishmentConfirmBody(
    int lineCount,
    String totalQty,
    String source,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      lineCount,
      locale: localeName,
      other: '$lineCount lines',
      one: '1 line',
    );
    return '$_temp0 · $totalQty units, out of $source';
  }

  @override
  String get replenishmentConfirmAction => 'Send';

  @override
  String replenishmentSentTitle(String name) {
    return 'Sent to $name';
  }

  @override
  String replenishmentSentBody(
    int lineCount,
    String totalQty,
    String stockEntry,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      lineCount,
      locale: localeName,
      other: '$lineCount lines',
      one: '1 line',
    );
    return '$_temp0 · $totalQty units · entry $stockEntry';
  }

  @override
  String replenishmentSendFailed(String name, String reason) {
    return 'Couldn\'t send to $name: $reason';
  }

  @override
  String replenishmentFailedLine(String item) {
    return 'The line the server refused: $item';
  }

  @override
  String get replenishmentNumbersKept =>
      'Your quantities are still on screen — fix it and send again.';

  @override
  String get replenishmentNothingToSend => 'Type a quantity first.';

  @override
  String get replenishmentEmptyTitle => 'Nothing to send';

  @override
  String get replenishmentEmptyNoBranches =>
      'No selling branches yet. A branch appears here once it has a POS profile.';

  @override
  String get replenishmentLoadFailed => 'Couldn\'t load what to send';

  @override
  String get replenishmentNotAllowed => 'You do not have access to send stock.';

  @override
  String get replenishmentRefresh => 'Refresh';

  @override
  String get menuProductionRound => 'Production Round';

  @override
  String get productionRoundTitle => 'Production Round';

  @override
  String get productionRoundRefresh => 'Refresh';

  @override
  String get productionRoundTune => 'Planning settings';

  @override
  String get productionRoundOpenFromSend => 'What to make';

  @override
  String get productionRoundNotAllowed =>
      'You do not have access to production planning.';

  @override
  String get productionRoundLoadFailed => 'Couldn\'t load the production round';

  @override
  String get productionRoundRefreshFailed =>
      'Couldn\'t refresh — these are the last figures.';

  @override
  String get productionRoundSizeSmall => 'Small';

  @override
  String get productionRoundSizeMedium => 'Medium';

  @override
  String get productionRoundSizeLarge => 'Large';

  @override
  String productionRoundBatchOne(String value) {
    return '$value batch';
  }

  @override
  String productionRoundBatches(String value) {
    return '$value batches';
  }

  @override
  String productionRoundJars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jars',
      one: '1 jar',
    );
    return '$_temp0';
  }

  @override
  String productionRoundNeededNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count needed now',
      one: '1 needed now',
    );
    return '$_temp0';
  }

  @override
  String productionRoundMissingMaterials(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count materials missing',
      one: '1 material missing',
    );
    return '$_temp0';
  }

  @override
  String productionRoundBlockedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items blocked',
      one: '1 item blocked',
    );
    return '$_temp0';
  }

  @override
  String productionRoundCoverDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Covers $count days',
      one: 'Covers 1 day',
    );
    return '$_temp0';
  }

  @override
  String productionRoundBackupDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count days backup',
      one: '+ 1 day backup',
    );
    return '$_temp0';
  }

  @override
  String productionRoundSalesWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'last $count weeks of sales',
      one: 'last week of sales',
    );
    return '$_temp0';
  }

  @override
  String productionRoundUpdatedAt(String time) {
    return 'updated $time';
  }

  @override
  String productionRoundNotices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String get productionRoundNoticesTitle => 'Notes';

  @override
  String get productionRoundTabMake => 'Make';

  @override
  String get productionRoundTabMaterials => 'Materials';

  @override
  String get productionRoundTabBranches => 'Branches';

  @override
  String get productionRoundEmptyTitle => 'Nothing to make';

  @override
  String get productionRoundEmptyBody =>
      'Every branch holds enough for the full cycle and its backup.';

  @override
  String get productionRoundNoItems =>
      'There are no jars with sales or stock to plan from yet.';

  @override
  String get productionRoundNothingInSize => 'Nothing to make in this size.';

  @override
  String productionRoundCoveredGroup(int count) {
    return 'Covered ($count)';
  }

  @override
  String get productionRoundStatusNow => 'Needed now';

  @override
  String get productionRoundStatusRound => 'This round';

  @override
  String get productionRoundStatusCovered => 'Covered';

  @override
  String get productionRoundStatusNoSales => 'No sales';

  @override
  String get productionRoundBlockedTooltip => 'Waiting on a missing material';

  @override
  String get productionRoundBlockedBy => 'Blocked by:';

  @override
  String productionRoundMissingQty(String name, String qty) {
    return '$name (missing $qty)';
  }

  @override
  String productionRoundSellsPerWeek(String rate) {
    return 'Sells $rate/wk';
  }

  @override
  String productionRoundBranchesNeed(String qty) {
    return 'Branches need $qty';
  }

  @override
  String productionRoundFactoryHas(String qty) {
    return 'Factory has $qty';
  }

  @override
  String productionRoundNetNeed(String qty) {
    return 'Net need $qty';
  }

  @override
  String get productionRoundNoBranchRows => 'No branch figures for this item.';

  @override
  String get productionRoundColBranch => 'Branch';

  @override
  String get productionRoundColSells => 'Sells/wk';

  @override
  String get productionRoundColTarget => 'Target';

  @override
  String get productionRoundColHas => 'Has';

  @override
  String get productionRoundColNeeds => 'Needs';

  @override
  String productionRoundDaysLeft(String days) {
    return '$days days left';
  }

  @override
  String get productionRoundCountFirst => 'Negative — count first';

  @override
  String get productionRoundMakeFirst => 'Make first';

  @override
  String productionRoundPrepStored(String batches, String qty) {
    return '$batches ($qty)';
  }

  @override
  String productionRoundPrepFresh(String batches) {
    return 'fresh, $batches';
  }

  @override
  String productionRoundFilterMissing(int count) {
    return 'Missing ($count)';
  }

  @override
  String productionRoundFilterAll(int count) {
    return 'All ($count)';
  }

  @override
  String productionRoundNeedHave(String need, String have) {
    return 'need $need · have $have';
  }

  @override
  String productionRoundShort(String qty) {
    return 'short $qty';
  }

  @override
  String productionRoundAlternative(String qty) {
    return '+$qty in alternatives';
  }

  @override
  String get productionRoundNothingMissing => 'Every material is in stock.';

  @override
  String get productionRoundNoMaterials => 'No materials to check.';

  @override
  String get productionRoundNoBranches => 'No selling branches yet.';

  @override
  String productionRoundBranchHolds(String has, String target) {
    return 'holds $has of $target target';
  }

  @override
  String productionRoundBranchNeeds(String qty) {
    return 'needs $qty';
  }

  @override
  String productionRoundBelowBackup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items below backup',
      one: '1 item below backup',
    );
    return '$_temp0';
  }

  @override
  String get productionRoundTuneTitle => 'Planning settings';

  @override
  String get productionRoundTuneCycle => 'Days between deliveries';

  @override
  String get productionRoundTuneBackup => 'Backup days';

  @override
  String get productionRoundTuneSales => 'Sales history';

  @override
  String productionRoundDaysValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: 'None',
    );
    return '$_temp0';
  }

  @override
  String productionRoundWeeksValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String get productionRoundTuneHint =>
      'Batch sizes come from the recipes and are not changed here.';

  @override
  String get productionRoundTuneReset => 'Use defaults';

  @override
  String get settingsBackgroundDeliveryTitle => 'Background delivery';

  @override
  String get settingsBackgroundDeliveryOk =>
      'This phone will receive order alerts while the app is closed.';

  @override
  String get settingsBackgroundDeliveryWarning =>
      'Android may put this app to sleep. While it is asleep, order alerts do not arrive at all — not even silently.';

  @override
  String get settingsBackgroundDeliveryFix => 'Allow background running';

  @override
  String get settingsBackgroundDeliveryOpenSettings => 'Open app settings';

  @override
  String get settingsBackgroundDeliveryHint =>
      'On Samsung, also turn off «Put unused apps to sleep» for Jarz POS under Battery.';

  @override
  String get settingsBackgroundDeliveryNoScreen =>
      'Could not open that screen. Open Settings > Apps > Jarz POS > Battery and allow background running.';

  @override
  String get rosterLegendProblemsTitle => 'Needs fixing';

  @override
  String get rosterLegendTextTitle => 'Written in the cell';

  @override
  String get rosterLegendMarkersTitle => 'Markers';

  @override
  String get rosterLegendWorkingTime => 'Working — shift start–end time';

  @override
  String get rosterTimeAmShort => 'a';

  @override
  String get rosterTimePmShort => 'p';

  @override
  String get rosterNotSetShort => 'Not set';

  @override
  String get rosterLegendOffCovered => 'Off — covered';

  @override
  String get rosterLegendOffUncovered => 'Day off — nobody covering';

  @override
  String get rosterLegendNotRosteredFuture =>
      'No shift set yet — cannot check in';

  @override
  String get rosterLegendNotRosteredPast => 'No record (day has passed)';

  @override
  String get rosterLegendMarkerOvertime => 'Longer than the normal day';

  @override
  String get rosterLegendMarkerCover => 'Covering a colleague';

  @override
  String get rosterLegendMarkerHolidayWorked => 'Working on a public holiday';

  @override
  String get rosterLegendMarkerWeekend => 'Weekend (Fri & Sat)';

  @override
  String get rosterLegendMarkerSelected => 'Selected for a bulk change';

  @override
  String get rosterOnDutyRow => 'On duty';

  @override
  String rosterOnDutyRowBranch(String branch) {
    return 'On duty · $branch';
  }

  @override
  String get rosterBranchUnknown => 'No branch';

  @override
  String get rosterUnrosteredPast => 'No shift was assigned on this day.';

  @override
  String rosterCoveringFor(String name) {
    return 'Covering for $name';
  }

  @override
  String rosterAboveNormalDay(String hours, String standard) {
    return '${hours}h — longer than the normal ${standard}h day';
  }

  @override
  String get menuAttendance => 'Attendance';

  @override
  String get attendanceTitle => 'Attendance';

  @override
  String get attendanceTabMonth => 'Month';

  @override
  String get attendanceTabDay => 'Day';

  @override
  String get attendanceTabEmployee => 'Employee';

  @override
  String get attendanceTabSummary => 'Summary';

  @override
  String get attendanceAccessDenied => 'You do not have access to attendance';

  @override
  String get attendanceAccessDeniedHint =>
      'This screen is for branch and line managers. Ask an administrator to add the role to your account.';

  @override
  String get attendanceLoadFailedHint =>
      'Try again. If it keeps failing, tell an administrator what time you saw this.';

  @override
  String get attendanceHrmsMissing =>
      'Attendance data is not available on this site.';

  @override
  String get attendanceScopeEmpty => 'No branch is assigned to your account';

  @override
  String get attendanceScopeEmptyHint =>
      'Your account is limited to an empty branch list, so there is nothing to show. Ask an administrator to set your branches.';

  @override
  String get attendanceNobodyRostered => 'Nobody is rostered in this period';

  @override
  String get attendanceNobodyRosteredHint =>
      'Check the month, the date range and the branch filter.';

  @override
  String get attendanceNoCheckins => 'No check-ins recorded in this period';

  @override
  String get attendanceNoCheckinsHint =>
      'Days shown as absent mean no check-in was recorded, not that the shift was missed.';

  @override
  String get attendanceNoBranchResolved => 'No branch resolved';

  @override
  String get attendanceNoBranchResolvedHint =>
      'These people could not be matched to a branch on this day.';

  @override
  String get attendanceBranchNobodyRostered => 'Nobody rostered at this branch';

  @override
  String get attendanceEmployeeColumn => 'Employee';

  @override
  String get attendanceAllBranches => 'All branches';

  @override
  String get attendancePreviousPeriod => 'Previous';

  @override
  String get attendanceNextPeriod => 'Next';

  @override
  String get attendanceToday => 'Today';

  @override
  String get attendanceFromDate => 'From';

  @override
  String get attendanceToDate => 'To';

  @override
  String get attendanceThisMonth => 'This month';

  @override
  String get attendanceWholeDay => 'Whole day';

  @override
  String get attendanceLegendTitle => 'What the colours mean';

  @override
  String get attendanceScheduled => 'Scheduled';

  @override
  String get attendanceActual => 'Actual';

  @override
  String get attendanceLateBy => 'Late by';

  @override
  String get attendanceEarlyBy => 'Early by';

  @override
  String get attendanceMinutesUnit => 'min';

  @override
  String get attendanceMinutesLateShort => 'min late';

  @override
  String get attendanceHoursUnit => 'h';

  @override
  String get attendanceWorkedHours => 'Worked hours';

  @override
  String get attendanceCheckinCount => 'Check-ins';

  @override
  String get attendanceGeoLabel => 'Location';

  @override
  String get attendanceGeoInside => 'Inside the branch area';

  @override
  String get attendanceGeoOutside => 'Outside the branch area';

  @override
  String get attendanceGeoUnknown => 'No location recorded';

  @override
  String get attendanceOffshiftLabel => 'Shift window';

  @override
  String get attendanceOffshiftValue => 'Outside the shift window';

  @override
  String get attendanceShiftType => 'Shift';

  @override
  String get attendanceBranch => 'Branch';

  @override
  String get attendanceCoverDay => 'Cover';

  @override
  String get attendanceCoverDayValue => 'Covering for a colleague';

  @override
  String get attendanceOffType => 'Leave type';

  @override
  String get attendanceCoveredBy => 'Covered by';

  @override
  String get attendanceNobodyCovering => 'Nobody';

  @override
  String get attendanceNotRosteredThisMonth => 'Not rostered';

  @override
  String get attendancePickEmployee => 'Choose an employee';

  @override
  String get attendanceNoEmployeesToPick => 'No employees to show';

  @override
  String get attendanceNoEmployeesToPickHint =>
      'The list comes from the Month tab. Change the month or the branch filter there.';

  @override
  String get attendanceByBranchTitle => 'By branch';

  @override
  String get attendanceByBranchEmpty => 'No branch breakdown for this range.';

  @override
  String get attendanceTimelineTitle => 'Day by day';

  @override
  String get attendanceTimelineEmpty => 'No days in this range.';

  @override
  String get attendanceCheckinsTitle => 'Check-ins';

  @override
  String get attendanceCheckinsEmpty => 'No check-ins in this range.';

  @override
  String get attendanceGroupByBranch => 'Branch';

  @override
  String get attendanceGroupByEmployee => 'Employee';

  @override
  String get attendanceGroupByDay => 'Day';

  @override
  String get attendanceColumnGroup => 'Group';

  @override
  String get attendanceTotalsRow => 'Total';

  @override
  String get attendanceMetricRostered => 'Rostered';

  @override
  String get attendanceMetricPresent => 'Present';

  @override
  String get attendanceMetricLate => 'Late';

  @override
  String get attendanceMetricAbsent => 'Absent';

  @override
  String get attendanceMetricPending => 'Pending';

  @override
  String get attendanceMetricOff => 'Off';

  @override
  String get attendanceMetricWorkedHours => 'Hours';

  @override
  String get attendanceMetricLateMinutes => 'Late minutes';

  @override
  String get attendanceMetricAvgLate => 'Avg late';

  @override
  String get attendanceMetricAttendanceRate => 'Attendance';

  @override
  String get attendanceMetricPunctualityRate => 'Punctuality';

  @override
  String get attendanceMetricLateUnmatched => 'Outside window';

  @override
  String get attendanceRateNoRoster => 'no roster';

  @override
  String get attendanceRateNoRosterWhy =>
      'No rostered days in this period, so there is no rate to compute.';

  @override
  String get attendanceStatusPresent => 'Present';

  @override
  String get attendanceStatusPresentWhy =>
      'Checked in within the grace period after the shift start.';

  @override
  String get attendanceStatusLate => 'Late';

  @override
  String get attendanceStatusLateWhy =>
      'Checked in after the grace period had passed.';

  @override
  String get attendanceStatusLateUnmatched => 'Outside window';

  @override
  String get attendanceStatusLateUnmatchedWhy =>
      'A check-in exists but falls outside the shift window, so it could not be matched to a start time. Somebody has to look at the punch.';

  @override
  String get attendanceStatusAbsent => 'Absent';

  @override
  String get attendanceStatusAbsentWhy =>
      'Rostered on a day that has already passed, with no check-in at all.';

  @override
  String get attendanceStatusPending => 'Awaiting';

  @override
  String get attendanceStatusPendingWhy =>
      'Rostered today or later and has not checked in yet. Nothing has gone wrong.';

  @override
  String get attendanceStatusOff => 'Day off';

  @override
  String get attendanceStatusOffWhy => 'An approved day off. Not a problem.';

  @override
  String get attendanceStatusHoliday => 'Holiday';

  @override
  String get attendanceStatusHolidayWhy =>
      'A public holiday on the holiday list for this shift.';

  @override
  String get attendanceStatusNotRostered => 'Not rostered';

  @override
  String get attendanceStatusNotRosteredWhy =>
      'Nobody was scheduled to work this day. This is not absence.';

  @override
  String get attendanceStatusUnknown => 'Unknown';

  @override
  String get attendanceStatusUnknownWhy =>
      'This version of the app does not recognise the status the server sent.';

  @override
  String get attendanceTokenPresent => 'P';

  @override
  String get attendanceTokenLate => 'L';

  @override
  String get attendanceTokenLateUnmatched => 'L!';

  @override
  String get attendanceTokenAbsent => 'A';

  @override
  String get attendanceTokenPending => '…';

  @override
  String get attendanceTokenOff => 'O';

  @override
  String get attendanceTokenHoliday => 'H';

  @override
  String get attendanceTokenNotRostered => '–';

  @override
  String attendanceRangeShortened(int days) {
    return 'Range limited to $days days';
  }

  @override
  String get attendanceRangeAdjusted =>
      'The other end of the range was moved to fit.';

  @override
  String get attendanceServerRefused => 'The server refused this request';

  @override
  String get attendanceServerRefusedHint =>
      'Adjust the dates or filters and try again.';

  @override
  String get attendanceTokenUnknown => '?';

  @override
  String get posCartOrderPurposeDeliverAtBranch => 'Collected at the branch';

  @override
  String get posStaffMemberLabel => 'Staff member';

  @override
  String get posStaffMemberChoose => 'Choose staff member';

  @override
  String get posStaffMemberChange => 'Change';

  @override
  String get posStaffMemberHint =>
      'This order is deducted from the salary of the chosen staff member.';

  @override
  String get posStaffMemberRequired => 'Choose the staff member for this order';

  @override
  String get posStaffMemberPickerTitle => 'Choose staff member';

  @override
  String get posStaffMemberSearchHint => 'Search by name, branch or job title';

  @override
  String get posStaffMemberNoMatches => 'No staff member matches this search';

  @override
  String get posStaffMemberEmpty => 'No active staff members were found';

  @override
  String get posStaffMemberHrmsUnavailableTitle => 'HR is not set up';

  @override
  String get posStaffMemberHrmsUnavailableBody =>
      'Staff orders are charged to an employee record, and the HR module is not installed on this system. Ask an administrator to set it up.';

  @override
  String get posStaffMemberNewCustomerHint =>
      'A customer account will be created for them';

  @override
  String posStaffMemberCustomerCreated(String name) {
    return 'Staff customer created for $name';
  }

  @override
  String posStaffMemberAssigned(String name) {
    return 'Order assigned to $name';
  }

  @override
  String get posStaffMemberEnsureFailed =>
      'Could not prepare the customer for this staff member';

  @override
  String get posStaffMemberLoadFailed => 'Could not load staff members';

  @override
  String get posEmployeePaymentCashHint =>
      'The staff member pays now; the money goes into the branch cash.';

  @override
  String get posCheckoutEmployeeCashPaid => 'Order placed and paid in cash.';

  @override
  String get posEmployeeCashNotSupported =>
      'Saved ON CREDIT, not cash: the server does not support cash for staff orders yet. It will be deducted from the salary of the staff member.';

  @override
  String get managerStaffCustomersSyncAction =>
      'Create missing staff customers';

  @override
  String get managerStaffCustomersSyncConfirmTitle =>
      'Create missing staff customers?';

  @override
  String get managerStaffCustomersSyncConfirmBody =>
      'Every active employee without a linked customer gets one, so their staff orders can be deducted from payroll. A customer that already matches an employee is linked instead of duplicated.';

  @override
  String get managerStaffCustomersSyncConfirm => 'Create';

  @override
  String get managerStaffCustomersSyncRunning => 'Creating staff customers…';

  @override
  String get managerStaffCustomersSyncResultTitle => 'Staff customers';

  @override
  String managerStaffCustomersSyncCreated(int count) {
    return 'Created: $count';
  }

  @override
  String managerStaffCustomersSyncAdopted(int count) {
    return 'Linked to an existing customer: $count';
  }

  @override
  String managerStaffCustomersSyncExisting(int count) {
    return 'Already linked: $count';
  }

  @override
  String managerStaffCustomersSyncSkipped(int count) {
    return 'Skipped ($count)';
  }

  @override
  String managerStaffCustomersSyncConflicts(int count) {
    return 'Needs review ($count)';
  }

  @override
  String get managerStaffCustomersSyncConflictsHint =>
      'More than one customer matches these employees, so none was linked. Link the right one in Desk.';

  @override
  String managerStaffCustomersSyncMatchingCustomers(String customers) {
    return 'Matching customers: $customers';
  }

  @override
  String get managerStaffCustomersSyncNothingToDo =>
      'Nothing to create: every employee already has a linked customer.';

  @override
  String get managerStaffCustomersSyncFailed =>
      'Could not create staff customers';

  @override
  String get approvalsNeedsYourAction => 'Needs your action';

  @override
  String get approvalsQueueExpenses => 'Expense requests to approve';

  @override
  String get approvalsQueueEmployeeAdvances => 'Employee advances to approve';

  @override
  String get approvalsQueueItemRequests => 'Item requests to accept';

  @override
  String get approvalsQueuePaymentReceipts => 'Payment receipts to confirm';

  @override
  String get approvalsQueueCustomShipping => 'Custom shipping to approve';

  @override
  String approvalsMenuBadgeSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items need',
      one: '1 item needs',
    );
    return 'Menu: $_temp0 your action';
  }

  @override
  String b2bBranchesTitleCount(int count) {
    return 'Branches ($count)';
  }

  @override
  String get b2bAddBranch => 'Add branch';

  @override
  String get b2bNoBranches => 'No branches yet.';

  @override
  String b2bBranchInvoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices',
      one: '1 invoice',
      zero: 'No invoices',
    );
    return '$_temp0';
  }

  @override
  String b2bBilledAmount(String amount) {
    return 'billed $amount';
  }

  @override
  String b2bOutstandingAmount(String amount) {
    return 'outstanding $amount';
  }

  @override
  String b2bLastOrderOn(String date) {
    return 'Last order $date';
  }

  @override
  String get b2bNoOrdersYet => 'No orders yet';

  @override
  String get b2bOpenBranchMap => 'Open on map';

  @override
  String get b2bPrimaryBranch => 'Primary';

  @override
  String get b2bTerritoryMissing => 'No delivery area';

  @override
  String get b2bUnassignedInvoices => 'Unassigned invoices';

  @override
  String get b2bUnassignedInvoicesHint =>
      'Invoices that match no branch address';

  @override
  String get b2bUnassignedShort => 'Unassigned';

  @override
  String get b2bViewAllInvoices => 'All invoices';

  @override
  String get b2bInvoicesTitle => 'Invoices';

  @override
  String get b2bFilterAllBranches => 'All branches';

  @override
  String get b2bSummaryInvoices => 'Invoices';

  @override
  String get b2bSummaryBilled => 'Total billed';

  @override
  String get b2bSummaryOutstanding => 'Outstanding';

  @override
  String get b2bNoInvoicesForSelection => 'No invoices for this selection.';

  @override
  String b2bInvoicesTruncated(int count) {
    return 'Showing the first $count invoices only.';
  }

  @override
  String get b2bInvoiceReturn => 'Return';

  @override
  String get b2bMergeMenuItem => 'Add another account as a branch…';

  @override
  String get b2bMergeSearchTitle => 'Add an account as a branch';

  @override
  String get b2bMergeSearchHint => 'Search accounts by name or phone';

  @override
  String get b2bMergeNoCandidates => 'No matching accounts.';

  @override
  String get b2bMergeDoctypeLead => 'Lead';

  @override
  String get b2bMergeDoctypeCustomer => 'Customer';

  @override
  String b2bMergeLinkedCustomer(String customer) {
    return 'Linked customer: $customer';
  }

  @override
  String get b2bMergeConfirmTitle => 'Merge as a branch';

  @override
  String b2bMergeBecomesBranch(String source, String target) {
    return '$source will become a branch of $target.';
  }

  @override
  String b2bMergeSwap(String name) {
    return 'Keep $name instead';
  }

  @override
  String b2bMergeSourceCustomer(String name) {
    return 'Merged customer: $name';
  }

  @override
  String b2bMergeTargetCustomer(String name) {
    return 'Kept customer: $name';
  }

  @override
  String get b2bMergeWarningsTitle => 'Before you merge';

  @override
  String get b2bMergeWarningIrreversible =>
      'Merging two customer accounts cannot be undone. All invoices and payments move to the kept customer.';

  @override
  String get b2bMergeWarningCredit =>
      'The merged account’s credit terms are carried over.';

  @override
  String get b2bMergeBlockedTitle => 'This merge can’t be done';

  @override
  String get b2bMergeBranchNameLabel => 'Branch name';

  @override
  String get b2bMergeManagerOnly =>
      'Only a manager can merge two customer accounts.';

  @override
  String get b2bMergeConfirm => 'Merge';

  @override
  String b2bMergeSuccess(String source, String target) {
    return '$source is now a branch of $target.';
  }

  @override
  String get menuCashCustody => 'Cash Custody';

  @override
  String get custodyTitle => 'Cash Custody';

  @override
  String get custodyMyTitle => 'My Custody';

  @override
  String get custodyMine => 'My custody';

  @override
  String custodyOfHolder(String name) {
    return 'Custody - $name';
  }

  @override
  String get custodyTotalHeld => 'Total held';

  @override
  String custodyHoldersCount(String count) {
    return 'Holders: $count';
  }

  @override
  String get custodyNoHolders => 'No custody holders yet.';

  @override
  String get custodyNotAHolder => 'You do not hold a cash custody.';

  @override
  String get custodyAddHolder => 'Add holder';

  @override
  String get custodySearchEmployee => 'Search employees';

  @override
  String get custodyNoCandidates => 'No matching employees.';

  @override
  String custodyHolderAdded(String name) {
    return '$name can now hold custody.';
  }

  @override
  String get custodyDisabledBadge => 'Disabled';

  @override
  String get custodyEnableTooltip => 'Enable or disable this custody';

  @override
  String get custodyDisableHasBalance =>
      'Return the remaining balance before disabling this custody.';

  @override
  String get custodyHolderEnabledMsg => 'Custody enabled.';

  @override
  String get custodyHolderDisabledMsg => 'Custody disabled.';

  @override
  String custodyLastMovement(String date) {
    return 'Last movement: $date';
  }

  @override
  String get custodyNoMovement => 'No movements yet';

  @override
  String get custodyCurrentBalance => 'Current balance';

  @override
  String get custodyIssueAction => 'Withdraw into custody';

  @override
  String get custodyReturnAction => 'Return cash';

  @override
  String get custodyIssueTitle => 'Withdraw into custody';

  @override
  String get custodyReturnTitle => 'Return cash from custody';

  @override
  String get custodySourceAccount => 'Take from';

  @override
  String get custodyReturnAccount => 'Return to';

  @override
  String get custodySelectAccount => 'Select an account';

  @override
  String get custodyAccountRequired => 'Choose an account.';

  @override
  String get custodyAmountLabel => 'Amount';

  @override
  String get custodyAmountInvalid => 'Enter an amount greater than zero.';

  @override
  String custodyAmountExceedsBalance(String balance) {
    return 'Amount cannot exceed the custody balance ($balance).';
  }

  @override
  String get custodyDateLabel => 'Date and time';

  @override
  String get custodyDateNow => 'Now';

  @override
  String get custodyRemarkLabel => 'Remark (optional)';

  @override
  String get custodySubmitIssue => 'Withdraw';

  @override
  String get custodySubmitReturn => 'Return';

  @override
  String custodyPosted(String entry) {
    return 'Posted: $entry';
  }

  @override
  String get custodyNoAccounts => 'No accounts available.';

  @override
  String get custodyStatementTitle => 'Statement';

  @override
  String get custodyStatementEmpty => 'No movements in this period.';

  @override
  String get custodyPickDates => 'Pick dates';

  @override
  String custodyRangeLabel(String from, String to) {
    return '$from to $to';
  }

  @override
  String get custodyOpeningBalance => 'Opening balance';

  @override
  String get custodyClosingBalance => 'Closing balance';

  @override
  String get custodyKindIssue => 'Withdrawal';

  @override
  String get custodyKindReturn => 'Return';

  @override
  String get custodyKindExpense => 'Expense';

  @override
  String get custodyKindPurchase => 'Purchase';

  @override
  String get custodyKindTransferIn => 'Transfer in';

  @override
  String get custodyKindTransferOut => 'Transfer out';

  @override
  String get custodyKindOther => 'Other';

  @override
  String custodyRunningBalance(String balance) {
    return 'Balance: $balance';
  }

  @override
  String custodyCounterAccount(String account) {
    return 'Against: $account';
  }

  @override
  String custodyAvailable(String balance) {
    return 'Available: $balance';
  }

  @override
  String get custodyInsufficientBalance => 'Not enough custody balance';

  @override
  String get custodyPurchasePaymentSubtitle => 'Paid from the holder custody';

  @override
  String get userErrorCustodyInsufficient =>
      'The custody balance is not enough for this amount.';

  @override
  String get userErrorCustodyDisableWithBalance =>
      'A custody with a balance cannot be disabled. Return the cash first.';

  @override
  String get tasksMenuTitle => 'Tasks';

  @override
  String get tasksBoardTitle => 'Task Board';

  @override
  String get tasksOverviewTitle => 'Team overview';

  @override
  String get tasksNoAccess =>
      'The task board is for managers and line managers only.';

  @override
  String get tasksNewTask => 'New task';

  @override
  String get tasksEmptyColumn => 'No tasks here';

  @override
  String get tasksViewAll => 'All';

  @override
  String get tasksViewMine => 'Mine';

  @override
  String get tasksViewCreated => 'Created by me';

  @override
  String get tasksViewReview => 'To review';

  @override
  String get tasksStatusToDo => 'To Do';

  @override
  String get tasksStatusInProgress => 'In Progress';

  @override
  String get tasksStatusInReview => 'In Review';

  @override
  String get tasksStatusDone => 'Done';

  @override
  String get tasksPriorityNormal => 'Normal';

  @override
  String get tasksPriorityHigh => 'High';

  @override
  String get tasksPriorityUrgent => 'Urgent';

  @override
  String get tasksFilters => 'Filters';

  @override
  String get tasksFilterAssignee => 'Assignee';

  @override
  String get tasksFilterCreator => 'Created by';

  @override
  String get tasksFilterBranch => 'Branch';

  @override
  String get tasksFilterPriority => 'Priority';

  @override
  String get tasksFilterAny => 'Any';

  @override
  String get tasksFilterOverdueOnly => 'Overdue only';

  @override
  String get tasksFilterShowArchived => 'Show archived';

  @override
  String get tasksFilterDoneWindow => 'Done column shows';

  @override
  String tasksDoneWindowDays(int days) {
    return 'Last $days days';
  }

  @override
  String get tasksDoneWindowAll => 'All time';

  @override
  String get tasksFilterClear => 'Clear filters';

  @override
  String get tasksFilterApply => 'Apply';

  @override
  String get tasksSearchHint => 'Search tasks';

  @override
  String tasksDueOn(String date) {
    return 'Due $date';
  }

  @override
  String get tasksOverdueLabel => 'Overdue';

  @override
  String get tasksArchivedTag => 'Archived';

  @override
  String get tasksUnassigned => 'Unassigned';

  @override
  String get tasksMoveTo => 'Move to';

  @override
  String tasksMoveToStatus(String status) {
    return 'Move to $status';
  }

  @override
  String tasksStatusChanged(String status) {
    return 'Task moved to $status';
  }

  @override
  String get tasksAssignee => 'Assignee';

  @override
  String get tasksCreator => 'Created by';

  @override
  String get tasksDueDate => 'Due date';

  @override
  String get tasksNoDueDate => 'No due date';

  @override
  String get tasksBranch => 'Branch';

  @override
  String get tasksNoBranch => 'No branch';

  @override
  String get tasksDescription => 'Description';

  @override
  String get tasksNoDescription => 'No description';

  @override
  String get tasksStartedOnLabel => 'Started';

  @override
  String get tasksCompletedLabel => 'Completed';

  @override
  String tasksCompletedBy(String name, String date) {
    return '$name on $date';
  }

  @override
  String get tasksArchivedBanner => 'This task is archived and read-only.';

  @override
  String get tasksActionStart => 'Start';

  @override
  String get tasksActionSubmit => 'Submit for review';

  @override
  String get tasksActionApprove => 'Approve';

  @override
  String get tasksActionSendBack => 'Send back';

  @override
  String get tasksActionReopen => 'Reopen';

  @override
  String get tasksActionMarkDone => 'Mark done';

  @override
  String get tasksActionMoveToDo => 'Move to To Do';

  @override
  String get tasksActionEdit => 'Edit task';

  @override
  String get tasksActionArchive => 'Archive';

  @override
  String get tasksActionUnarchive => 'Unarchive';

  @override
  String get tasksArchiveConfirm =>
      'Archive this task? It becomes read-only until it is unarchived.';

  @override
  String get tasksReasonTitleSendBack => 'Why are you sending it back?';

  @override
  String get tasksReasonTitleReopen => 'Why are you reopening it?';

  @override
  String get tasksReasonHint => 'Reason';

  @override
  String get tasksEditTitle => 'Edit task';

  @override
  String get tasksFieldTitle => 'Title';

  @override
  String get tasksFieldTitleRequired => 'Enter a title';

  @override
  String get tasksFieldDescription => 'Description';

  @override
  String get tasksFieldAssignee => 'Assign to';

  @override
  String get tasksFieldAssigneeRequired => 'Choose who does it';

  @override
  String get tasksFieldDueDate => 'Due date';

  @override
  String get tasksFieldBranch => 'Branch';

  @override
  String get tasksFieldPriority => 'Priority';

  @override
  String get tasksClearDate => 'Clear date';

  @override
  String get tasksNone => 'None';

  @override
  String get tasksSaved => 'Task saved';

  @override
  String get tasksCreated => 'Task created';

  @override
  String get tasksInitialSubtasks => 'Subtasks';

  @override
  String get tasksAddSubtaskField => 'Add a subtask';

  @override
  String get tasksCreateButton => 'Create task';

  @override
  String tasksSubtasksTitle(int done, int total) {
    return 'Subtasks ($done/$total)';
  }

  @override
  String get tasksNoSubtasks => 'No subtasks yet';

  @override
  String get tasksAddSubtask => 'Add subtask';

  @override
  String get tasksEditSubtask => 'Edit subtask';

  @override
  String get tasksDeleteSubtask => 'Delete subtask';

  @override
  String tasksDeleteSubtaskConfirm(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get tasksSubtaskTitle => 'Subtask';

  @override
  String get tasksSubtaskAssignee => 'Assigned to';

  @override
  String tasksSubtaskDoneBy(String name) {
    return 'Done by $name';
  }

  @override
  String tasksAttachmentsTitle(int count) {
    return 'Attachments ($count)';
  }

  @override
  String get tasksNoAttachments => 'No attachments';

  @override
  String get tasksAddAttachment => 'Attach';

  @override
  String get tasksAttachCamera => 'Take a photo';

  @override
  String get tasksAttachGallery => 'Choose a photo';

  @override
  String get tasksAttachFile => 'Choose a file';

  @override
  String get tasksRemoveAttachment => 'Remove attachment';

  @override
  String tasksRemoveAttachmentConfirm(String file) {
    return 'Remove \"$file\"?';
  }

  @override
  String tasksFileTooLarge(String file) {
    return '\"$file\" is larger than 10 MB.';
  }

  @override
  String get tasksFileEmpty => 'The file could not be read. Pick it again.';

  @override
  String get tasksUploaded => 'Attachment added';

  @override
  String tasksFileSaved(String path) {
    return 'Saved to $path';
  }

  @override
  String get tasksDownload => 'Download';

  @override
  String get tasksAttachmentsPartial =>
      'The entry was saved, but some files did not upload.';

  @override
  String tasksUploadedBy(String name, String date) {
    return '$name · $date';
  }

  @override
  String get tasksActivityTitle => 'Activity';

  @override
  String get tasksTabLogs => 'What I did';

  @override
  String get tasksTabComments => 'Comments';

  @override
  String get tasksTabHistory => 'History';

  @override
  String get tasksNoLogs => 'No logs yet';

  @override
  String get tasksNoComments => 'No comments yet';

  @override
  String get tasksNoHistory => 'No history yet';

  @override
  String get tasksAddLog => 'Add what I did';

  @override
  String get tasksAddComment => 'Add comment';

  @override
  String get tasksLogHint => 'What did you do?';

  @override
  String get tasksCommentHint => 'Write a comment';

  @override
  String get tasksMention => 'Mention';

  @override
  String get tasksMentionPick => 'Mention someone';

  @override
  String get tasksNoMentionable => 'Nobody else can see this task.';

  @override
  String get tasksContentRequired => 'Write something first';

  @override
  String get tasksSend => 'Post';

  @override
  String tasksMentioned(String names) {
    return 'Mentioned: $names';
  }

  @override
  String tasksHistoryCreated(String actor) {
    return '$actor created the task';
  }

  @override
  String tasksHistoryReassigned(String actor) {
    return '$actor reassigned the task';
  }

  @override
  String tasksHistoryStatus(String actor) {
    return '$actor changed the status';
  }

  @override
  String tasksHistoryDueDate(String actor) {
    return '$actor changed the due date';
  }

  @override
  String tasksHistoryPriority(String actor) {
    return '$actor changed the priority';
  }

  @override
  String tasksHistoryTitle(String actor) {
    return '$actor renamed the task';
  }

  @override
  String tasksHistoryBranch(String actor) {
    return '$actor changed the branch';
  }

  @override
  String tasksHistorySubtaskAdded(String actor) {
    return '$actor added a subtask';
  }

  @override
  String tasksHistorySubtaskDone(String actor) {
    return '$actor completed a subtask';
  }

  @override
  String tasksHistorySubtaskUndone(String actor) {
    return '$actor reopened a subtask';
  }

  @override
  String tasksHistorySubtaskRemoved(String actor) {
    return '$actor removed a subtask';
  }

  @override
  String tasksHistoryAttachmentAdded(String actor) {
    return '$actor added an attachment';
  }

  @override
  String tasksHistoryAttachmentRemoved(String actor) {
    return '$actor removed an attachment';
  }

  @override
  String tasksHistoryArchived(String actor) {
    return '$actor archived the task';
  }

  @override
  String tasksHistoryUnarchived(String actor) {
    return '$actor unarchived the task';
  }

  @override
  String tasksHistoryOther(String actor) {
    return '$actor updated the task';
  }

  @override
  String tasksOverviewDays(int days) {
    return '$days days';
  }

  @override
  String get tasksOverviewOpen => 'Open';

  @override
  String get tasksOverviewInProgress => 'In progress';

  @override
  String get tasksOverviewInReview => 'In review';

  @override
  String get tasksOverviewOverdue => 'Overdue';

  @override
  String get tasksOverviewDone => 'Done';

  @override
  String get tasksOverviewOnTime => 'On time';

  @override
  String get tasksOverviewNoData => 'No tasks in this period';

  @override
  String get tasksOverviewManagerTag => 'Manager';

  @override
  String get tasksErrorOpenSubtasks =>
      'Finish or remove the open subtasks first.';

  @override
  String get tasksErrorReasonRequired => 'A reason is required.';

  @override
  String get tasksErrorArchived => 'This task is archived. Unarchive it first.';

  @override
  String get tasksErrorMentionNotVisible =>
      'Someone you mentioned cannot see this task.';

  @override
  String get tasksErrorFileTooLarge => 'The file is larger than 10 MB.';

  @override
  String get tasksQueueAssigned => 'Tasks assigned to you';

  @override
  String get tasksQueueReview => 'Tasks waiting for your review';

  @override
  String tasksFileTypeBlocked(String file) {
    return '\"$file\" cannot be attached: this file type is not allowed.';
  }

  @override
  String get menuBranchAccess => 'Branch Access';

  @override
  String get branchAccessTitle => 'Branch Access';

  @override
  String get branchAccessTabPeople => 'People';

  @override
  String get branchAccessTabHistory => 'History';

  @override
  String get branchAccessAccessDenied =>
      'Only managers and line managers can manage branch access.';

  @override
  String get branchAccessSearchHint => 'Search people';

  @override
  String get branchAccessNoUsers => 'Nobody matches.';

  @override
  String get branchAccessNoBranches => 'No branches to show.';

  @override
  String get branchAccessBranchClosed => 'Closed';

  @override
  String branchAccessOpenSince(String time, String name) {
    return 'Open since $time by $name';
  }

  @override
  String branchAccessLockedOpen(String branch, String time, String name) {
    return '$branch has been open since $time by $name. Access can change once that shift is closed.';
  }

  @override
  String get branchAccessNotYourBranch =>
      'You can only manage branches you belong to.';

  @override
  String get branchAccessCannotEditSelf => 'You cannot change your own access.';

  @override
  String get branchAccessYouTag => 'You';

  @override
  String get branchAccessDisabledTag => 'Disabled';

  @override
  String get branchAccessChipMember => 'Has access';

  @override
  String get branchAccessChipNone => 'No access';

  @override
  String branchAccessChipDay(String branch, String date) {
    return '$branch · $date';
  }

  @override
  String branchAccessAddTitle(String branch) {
    return 'Give access to $branch?';
  }

  @override
  String branchAccessAddBody(String name, String branch) {
    return '$name will be able to open the $branch POS every day until the access is removed.';
  }

  @override
  String branchAccessMakePermanentBody(String name, String branch) {
    return '$name has access to $branch for one day only. Make it permanent?';
  }

  @override
  String branchAccessRemoveTitle(String branch) {
    return 'Remove access to $branch?';
  }

  @override
  String branchAccessRemoveBody(String name, String branch) {
    return '$name will no longer be able to open the $branch POS.';
  }

  @override
  String get branchAccessNoteLabel => 'Note (optional)';

  @override
  String get branchAccessAddAction => 'Give access';

  @override
  String get branchAccessRemoveAction => 'Remove access';

  @override
  String branchAccessAdded(String name, String branch) {
    return '$name now has access to $branch.';
  }

  @override
  String branchAccessRemoved(String name, String branch) {
    return '$name no longer has access to $branch.';
  }

  @override
  String get branchAccessUnchanged =>
      'Nothing changed: the access was already like that.';

  @override
  String get branchAccessGiveDay => 'Give access for one day';

  @override
  String branchAccessDayTitle(String name) {
    return 'One-day access for $name';
  }

  @override
  String get branchAccessDayBranch => 'Branch';

  @override
  String get branchAccessDayDate => 'Day';

  @override
  String get branchAccessDayHelper =>
      'Access runs from the start of that day until 03:00 the next morning.';

  @override
  String get branchAccessDayNoBranch =>
      'No branch left to give: they already have access to every branch you manage.';

  @override
  String branchAccessDayGranted(String date) {
    return 'Access given for $date.';
  }

  @override
  String get branchAccessDaySection => 'One-day access';

  @override
  String get branchAccessDayStatusActive => 'Active';

  @override
  String get branchAccessDayStatusScheduled => 'Scheduled';

  @override
  String get branchAccessDayStatusEnded => 'Ended';

  @override
  String get branchAccessDayStatusCancelled => 'Cancelled';

  @override
  String get branchAccessCancelDay => 'Cancel access';

  @override
  String get branchAccessCancelDayTitle => 'Cancel this one-day access?';

  @override
  String branchAccessCancelDayBody(String name, String branch, String date) {
    return '$name will lose access to $branch for $date.';
  }

  @override
  String get branchAccessKeep => 'Keep';

  @override
  String get branchAccessDayCancelled => 'One-day access cancelled.';

  @override
  String branchAccessHomeBranch(String branch) {
    return 'Home branch: $branch';
  }

  @override
  String get branchAccessMoveAction => 'Move to another branch';

  @override
  String branchAccessMoveTitle(String name) {
    return 'Move $name to another branch';
  }

  @override
  String get branchAccessMoveExplain =>
      'POS access switches now. Their weekly schedule and upcoming shifts move to the new branch from today.';

  @override
  String branchAccessMoveCurrent(String branch) {
    return 'Current branch: $branch';
  }

  @override
  String get branchAccessMoveTarget => 'New branch';

  @override
  String branchAccessMoveKeepOld(String branch) {
    return 'Keep access to $branch too';
  }

  @override
  String get branchAccessMoveKeepOldUnknown =>
      'Keep access to their current branch too';

  @override
  String get branchAccessMoveConfirm => 'Move';

  @override
  String get branchAccessMoveNoTarget =>
      'There is no other branch you can move this person to.';

  @override
  String branchAccessMoved(String name, String branch) {
    return '$name moved to $branch.';
  }

  @override
  String branchAccessRosterNotMoved(String reason) {
    return 'Shift not moved: $reason. Check-in at this branch will still be refused.';
  }

  @override
  String branchAccessRosterNotRestored(String reason) {
    return 'Shift not moved back: $reason';
  }

  @override
  String get branchAccessHistoryAllBranches => 'All branches';

  @override
  String get branchAccessHistoryEmpty => 'No changes recorded yet.';

  @override
  String branchAccessHistoryBy(String name) {
    return 'by $name';
  }

  @override
  String get branchAccessActionAdded => 'Access given';

  @override
  String get branchAccessActionRemoved => 'Access removed';

  @override
  String get branchAccessActionDayScheduled => 'One-day access scheduled';

  @override
  String get branchAccessActionDayStarted => 'One-day access started';

  @override
  String get branchAccessActionDayEnded => 'One-day access ended';

  @override
  String get branchAccessActionDayCancelled => 'One-day access cancelled';

  @override
  String get branchAccessSourceScreen => 'Branch Access screen';

  @override
  String get branchAccessSourceShift => 'Shift assignment';

  @override
  String get branchAccessSourceCover => 'Day-off cover';

  @override
  String get branchAccessSourceScheduler => 'Automatic';

  @override
  String get branchAccessSourceMove => 'Branch move';

  @override
  String get rosterGrantPosAccess => 'Also give POS access for this day';

  @override
  String rosterGrantPosAccessHelper(String branch) {
    return 'Lets them open the $branch POS on this day only.';
  }

  @override
  String rosterPosAccessGranted(String branch) {
    return 'POS access to $branch given for this day.';
  }

  @override
  String rosterPosAccessScheduled(String branch) {
    return 'POS access to $branch scheduled for this day.';
  }

  @override
  String rosterPosAccessAlreadyMember(String branch) {
    return 'Already has POS access to $branch.';
  }

  @override
  String rosterPosAccessNotGranted(String reason) {
    return 'Saved, but POS access was not given: $reason';
  }

  @override
  String get rosterPosAccessNotConfirmed =>
      'Saved, but the server did not confirm the POS access.';

  @override
  String get rosterPosAccessNoReason => 'no reason given';

  @override
  String get branchAccessUserNotEditable =>
      'You are not allowed to change this person’s access.';

  @override
  String get manufacturingHistorySearchHint => 'Search item or work order';

  @override
  String get manufacturingHistoryBasisPosted => 'Stock date';

  @override
  String get manufacturingHistoryBasisCreated => 'Created date';

  @override
  String get manufacturingHistoryDateHelp =>
      'Stock date is when the batch counted in inventory. Created date is when the order was entered in the app.';

  @override
  String manufacturingHistoryPostedAt(String date) {
    return 'Stock: $date';
  }

  @override
  String manufacturingHistoryCreatedAt(String date) {
    return 'Created: $date';
  }

  @override
  String get manufacturingHistoryNotPosted => 'Not in stock yet';

  @override
  String get manufacturingHistoryBackdated => 'Backdated';

  @override
  String get manufacturingHistoryAllStatuses => 'All statuses';

  @override
  String get manufacturingHistoryAnyDate => 'Any date';

  @override
  String get manufacturingHistoryToday => 'Today';

  @override
  String get manufacturingHistoryYesterday => 'Yesterday';

  @override
  String get manufacturingHistoryLast7 => 'Last 7 days';

  @override
  String get manufacturingHistoryLast30 => 'Last 30 days';

  @override
  String get manufacturingHistoryCustomRange => 'Custom range';

  @override
  String manufacturingHistorySummary(int count, String qty) {
    return '$count work orders • $qty made';
  }

  @override
  String manufacturingHistoryQty(String qty) {
    return 'Qty $qty';
  }

  @override
  String manufacturingHistoryMade(String made, String qty) {
    return 'Made $made of $qty';
  }

  @override
  String manufacturingHistoryCapped(int count) {
    return 'Showing the latest $count only. Narrow the filters to see older ones.';
  }

  @override
  String get manufacturingWoStatusNotStarted => 'Not started';

  @override
  String get manufacturingWoStatusInProcess => 'In process';

  @override
  String get manufacturingWoStatusCompleted => 'Completed';

  @override
  String get manufacturingWoStatusStopped => 'Stopped';

  @override
  String get manufacturingWoStatusCancelled => 'Cancelled';

  @override
  String get b2bBranchMapsLinked => 'Linked to Google Maps';

  @override
  String get b2bBranchMapsAutoMatched => 'Matched automatically';

  @override
  String get b2bBranchMapsOnlySubtitle =>
      'On Google Maps — not a delivery branch yet';

  @override
  String get b2bBranchActions => 'Branch actions';

  @override
  String get b2bBranchLinkMaps => 'Link a Google Maps branch';

  @override
  String get b2bBranchUnlinkMaps => 'Unlink Google Maps branch';

  @override
  String get b2bBranchMakeDelivery => 'Make it a delivery branch';

  @override
  String get b2bBranchSameAsExisting => 'Same as an existing branch…';

  @override
  String get b2bBranchPickMapsTitle => 'Which Google Maps branch is this?';

  @override
  String get b2bBranchPickDeliveryTitle => 'Which delivery branch is this?';

  @override
  String get b2bBranchNoFreeDelivery =>
      'Every delivery branch already has a Google Maps branch.';

  @override
  String get b2bBranchLinkedDone => 'Branches combined';

  @override
  String get b2bBranchUnlinkedDone => 'Google Maps branch unlinked';

  @override
  String b2bBranchPromotedDone(String name) {
    return '$name is now a delivery branch';
  }

  @override
  String get b2bBranchOnTalabat => 'On Talabat';

  @override
  String get settlementTermsTitle => 'Payment terms';

  @override
  String get settlementTermsNotSet =>
      'No payment terms set, so no collection reminders for this shop.';

  @override
  String get settlementTermsSetAction => 'Set terms';

  @override
  String get settlementTermsEditAction => 'Edit';

  @override
  String get settlementTermsLoadFailed => 'Could not load payment terms';

  @override
  String get settlementTermsPaused => 'Reminders paused';

  @override
  String get settlementLeadHint =>
      'Will apply automatically when this lead becomes a customer.';

  @override
  String get settlementStateOverdue => 'Overdue';

  @override
  String get settlementStateDueToday => 'Due today';

  @override
  String get settlementStateDueSoon => 'Due soon';

  @override
  String get settlementStateOk => 'On track';

  @override
  String get settlementStateNone => 'Nothing owed';

  @override
  String get settlementStateUnscheduled => 'Not scheduled';

  @override
  String get settlementNextDueLabel => 'Next due';

  @override
  String get settlementNextDueAmountLabel => 'Due on that date';

  @override
  String get settlementDueNowLabel => 'Due now';

  @override
  String get settlementOverdueAmountLabel => 'Overdue';

  @override
  String get settlementOverdueSinceLabel => 'Overdue since';

  @override
  String get settlementCollectNextDeliveryLabel =>
      'Collect with the next delivery';

  @override
  String get settlementByBranchTitle => 'By branch';

  @override
  String get settlementUnassignedBranch => 'No branch on the invoice';

  @override
  String settlementBranchLine(String due, String next) {
    return 'Due now $due · next delivery $next';
  }

  @override
  String get settlementRemindsLabel => 'Reminds';

  @override
  String get settlementRemindsAllManagers => 'All managers';

  @override
  String get settlementNotesLabel => 'Agreed terms';

  @override
  String get settlementDescOnDelivery => 'Pays on delivery';

  @override
  String get settlementDescInvoiceAfterInvoice =>
      'Pays the previous invoice on each delivery';

  @override
  String settlementDescWeekly(Object days) {
    return 'Every $days';
  }

  @override
  String settlementDescWeeklyInterval(int weeks, Object days) {
    return 'Every $weeks weeks on $days';
  }

  @override
  String settlementDescMonthDays(Object days) {
    return 'Every month on $days';
  }

  @override
  String settlementDescMonthDayNumber(Object day) {
    return 'the $day';
  }

  @override
  String get settlementDescMonthDayLast => 'the last day';

  @override
  String settlementDescEveryNDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String get settlementSheetTitle => 'Payment terms';

  @override
  String get settlementSheetHint =>
      'A schedule for reminders only. Nothing here blocks an order.';

  @override
  String get settlementCycleLabel => 'How does this shop pay?';

  @override
  String get settlementCycleOnDelivery => 'On delivery';

  @override
  String get settlementCycleInvoiceAfterInvoice => 'Invoice after invoice';

  @override
  String get settlementCycleWeekly => 'Weekly';

  @override
  String get settlementCycleDaysOfMonth => 'Days of the month';

  @override
  String get settlementCycleEveryNDays => 'Every N days';

  @override
  String get settlementCycleOnDeliveryHint =>
      'Pays at the door. Any open balance shows as overdue.';

  @override
  String get settlementCycleInvoiceAfterInvoiceHint =>
      'When a new order is delivered, the shop pays the previous one.';

  @override
  String get settlementWeekdaysLabel => 'Pay day';

  @override
  String get settlementWeekIntervalLabel => 'Every how many weeks';

  @override
  String get settlementWeekIntervalHint =>
      '1 = every week, 2 = every other week';

  @override
  String get settlementMonthDaysLabel => 'Days of the month';

  @override
  String get settlementMonthDayLastChip => 'Last day';

  @override
  String get settlementMonthDaysClampHint =>
      'A day the month does not have (like the 31st) falls on its last day.';

  @override
  String get settlementIntervalDaysLabel => 'Every how many days';

  @override
  String get settlementAnchorDateLabel => 'Counting from';

  @override
  String get settlementAnchorDateDefault => 'Today (default)';

  @override
  String get settlementRemindDaysBeforeLabel => 'Remind how many days before';

  @override
  String get settlementRemindDaysBeforeHint => '0 = only on the day';

  @override
  String get settlementOverdueRepeatLabel =>
      'Repeat the overdue reminder every (days)';

  @override
  String get settlementResponsibleUserLabel => 'Who gets reminded';

  @override
  String get settlementResponsibleUserHint =>
      'User email. Leave empty for all managers.';

  @override
  String get settlementNotesFieldLabel =>
      'Agreed terms (returns, discounts, anything)';

  @override
  String get settlementEnabledLabel => 'Send reminders';

  @override
  String get settlementSaveAction => 'Save terms';

  @override
  String get settlementSaveFailed => 'Could not save payment terms';

  @override
  String get settlementSaved => 'Payment terms saved';

  @override
  String get settlementValidationPickDay => 'Pick at least one day';

  @override
  String get settlementValidationWholeNumber =>
      'Enter a whole number, 1 or more';

  @override
  String get settlementValidationZeroOrMore =>
      'Enter a whole number, 0 or more';

  @override
  String get creditAccountsViewAccounts => 'Accounts';

  @override
  String get creditAccountsViewCollections => 'Collections';

  @override
  String get collectionsSubtitle =>
      'Shops to collect from, most urgent first. Reminders only; nothing here blocks an order.';

  @override
  String collectionsEmpty(int days) {
    return 'Nothing to collect in the next $days days';
  }

  @override
  String get collectionsLoadFailed => 'Failed to load collections';

  @override
  String get collectionsNoTerms => 'No payment terms set';

  @override
  String collectionsDueNow(Object amount) {
    return 'Due now $amount';
  }

  @override
  String collectionsOverdueAmount(Object amount) {
    return 'Overdue $amount';
  }

  @override
  String collectionsNextDue(Object amount, Object date) {
    return '$amount due $date';
  }

  @override
  String get approvalsQueueCreditCollections => 'Collections due';

  @override
  String get menuUsers => 'Users';

  @override
  String get userAdminTitle => 'Users';

  @override
  String get userAdminAccessDenied => 'Only managers can manage user accounts.';

  @override
  String get userAdminSearchHint => 'Search by name, email or mobile';

  @override
  String get userAdminFilterAll => 'All';

  @override
  String get userAdminFilterActive => 'Active';

  @override
  String get userAdminFilterDisabled => 'Disabled';

  @override
  String get userAdminFilterManagers => 'Managers';

  @override
  String get userAdminFilterLineManagers => 'Line managers';

  @override
  String get userAdminFilterModerators => 'Moderators';

  @override
  String get userAdminFilterB2b => 'B2B sales';

  @override
  String get userAdminFilterProduction => 'Production';

  @override
  String get userAdminFilterStaff => 'Staff';

  @override
  String get userAdminFilterOther => 'Other';

  @override
  String get userAdminTierManager => 'Manager';

  @override
  String get userAdminTierLineManager => 'Line manager';

  @override
  String get userAdminTierModerator => 'Moderator';

  @override
  String get userAdminTierB2b => 'B2B sales';

  @override
  String get userAdminTierProduction => 'Production';

  @override
  String get userAdminTierStaff => 'Staff';

  @override
  String get userAdminTierOther => 'Other';

  @override
  String get userAdminAddUser => 'Add user';

  @override
  String get userAdminNoUsers => 'No users match.';

  @override
  String userAdminCount(int count) {
    return '$count users';
  }

  @override
  String get userAdminYouTag => 'You';

  @override
  String get userAdminDisabledTag => 'Disabled';

  @override
  String get userAdminViewOnly => 'View only';

  @override
  String get userAdminViewOnlyBanner =>
      'This is a System Manager account. It can be viewed here but not changed.';

  @override
  String get userAdminDisabledBanner =>
      'This account is disabled. The user cannot sign in.';

  @override
  String get userAdminNewTitle => 'New user';

  @override
  String get userAdminEditTitle => 'User';

  @override
  String get userAdminSectionAccount => 'Account';

  @override
  String get userAdminSectionRoles => 'Role profiles';

  @override
  String get userAdminSectionEmployee => 'Employee';

  @override
  String get userAdminSectionBranches => 'Branches';

  @override
  String get userAdminSectionActions => 'Account actions';

  @override
  String get userAdminFirstName => 'First name';

  @override
  String get userAdminLastName => 'Last name';

  @override
  String get userAdminMobile => 'Mobile';

  @override
  String get userAdminEmail => 'Email';

  @override
  String get userAdminEmailReadOnly =>
      'The email is the login and cannot be changed.';

  @override
  String get userAdminPassword => 'Password';

  @override
  String get userAdminConfirmPassword => 'Confirm password';

  @override
  String get userAdminNewPassword => 'New password';

  @override
  String get userAdminShowPassword => 'Show password';

  @override
  String get userAdminHidePassword => 'Hide password';

  @override
  String get userAdminFieldRequired => 'Required';

  @override
  String get userAdminEmailInvalid => 'Enter a valid email address';

  @override
  String userAdminPasswordTooShort(int min) {
    return 'At least $min characters';
  }

  @override
  String get userAdminPasswordMismatch => 'Passwords do not match';

  @override
  String get userAdminRoleProfilesRequired =>
      'Select at least one role profile.';

  @override
  String get userAdminRoleProfilesReplaceWarning =>
      'The user\'s roles will be replaced by the roles of the selected profiles.';

  @override
  String get userAdminRoleProfilesSelfLocked =>
      'You cannot change your own role profiles.';

  @override
  String get userAdminRoleProfileNotAssignable =>
      'Only a System Manager can assign this profile.';

  @override
  String get userAdminNoRoleProfiles => 'No role profiles are available.';

  @override
  String get userAdminPrivilegedTag => 'Privileged';

  @override
  String get userAdminRequirePosShift => 'Require POS shift';

  @override
  String get userAdminRequirePosShiftHelp =>
      'The user must open a shift before selling on the POS.';

  @override
  String get userAdminEmployeeNone => 'No employee linked';

  @override
  String get userAdminEmployeeChoose => 'Link employee';

  @override
  String get userAdminEmployeeChange => 'Change';

  @override
  String get userAdminEmployeeUnlink => 'Unlink';

  @override
  String get userAdminEmployeeUnlinkPending =>
      'The employee link will be removed when you save.';

  @override
  String get userAdminEmployeeSearchHint => 'Search employees';

  @override
  String get userAdminEmployeeNoResults => 'No active employees found.';

  @override
  String userAdminEmployeeLinkedTo(String user) {
    return 'Linked to $user';
  }

  @override
  String userAdminEmployeeLinkedWarning(String user) {
    return 'This employee is already linked to $user.';
  }

  @override
  String get userAdminBranchesNone => 'No branch access';

  @override
  String get userAdminManageBranchAccess => 'Manage branch access';

  @override
  String get userAdminLastLogin => 'Last login';

  @override
  String get userAdminCreatedOn => 'Created';

  @override
  String get userAdminNever => 'Never';

  @override
  String get userAdminCreate => 'Create user';

  @override
  String get userAdminNoChanges => 'Nothing to save.';

  @override
  String userAdminSavedMessage(String name) {
    return '$name saved.';
  }

  @override
  String userAdminCreatedMessage(String name) {
    return '$name created.';
  }

  @override
  String get userAdminChangePassword => 'Change password';

  @override
  String userAdminPasswordDialogTitle(String name) {
    return 'New password for $name';
  }

  @override
  String get userAdminSignedOutEverywhereNote =>
      'The user will be signed out of all their devices.';

  @override
  String get userAdminSignOutEverywhere => 'Sign the user out of all devices';

  @override
  String userAdminPasswordChangedMessage(String name) {
    return 'Password changed for $name.';
  }

  @override
  String get userAdminDisable => 'Disable';

  @override
  String get userAdminEnable => 'Enable';

  @override
  String userAdminDisableTitle(String name) {
    return 'Disable $name?';
  }

  @override
  String get userAdminDisableBody =>
      'They will be signed out of every device and cannot sign in until the account is enabled again.';

  @override
  String userAdminEnableTitle(String name) {
    return 'Enable $name?';
  }

  @override
  String get userAdminEnableBody =>
      'They will be able to sign in again with their current password.';

  @override
  String userAdminDisabledMessage(String name) {
    return '$name disabled.';
  }

  @override
  String userAdminEnabledMessage(String name) {
    return '$name enabled.';
  }

  @override
  String get userAdminDelete => 'Delete user';

  @override
  String userAdminDeleteTitle(String name) {
    return 'Delete $name permanently?';
  }

  @override
  String get userAdminDeleteBody =>
      'This removes the account permanently and cannot be undone. For someone who has left, disable the account instead: it keeps their history intact. An account linked to orders or other records cannot be deleted.';

  @override
  String userAdminDeletedMessage(String name) {
    return '$name deleted.';
  }

  @override
  String get userAdminUnsavedTitle => 'Discard changes?';

  @override
  String get userAdminUnsavedBody => 'Your changes have not been saved.';

  @override
  String get userAdminDiscard => 'Discard';

  @override
  String get pnlTitle => 'Profit & Loss';

  @override
  String get pnlSubtitle =>
      'Revenue from B2B vs B2C, every expense, and the net profit, checked against the books';

  @override
  String get pnlTotalRevenue => 'Total revenue';

  @override
  String get pnlB2cRevenue => 'B2C revenue';

  @override
  String get pnlB2bRevenue => 'B2B revenue';

  @override
  String get pnlGrossProfit => 'Gross profit';

  @override
  String get pnlTotalExpenses => 'Total expenses';

  @override
  String get pnlNetProfit => 'Net profit';

  @override
  String get pnlShippingNet => 'Shipping difference';

  @override
  String pnlMarginOf(String pct) {
    return '$pct% margin';
  }

  @override
  String get pnlRevenueTrend => 'Revenue by channel';

  @override
  String get pnlChannelB2c => 'B2C';

  @override
  String get pnlChannelB2b => 'B2B';

  @override
  String get pnlChannelStaff => 'Staff';

  @override
  String get pnlChannelSamples => 'Samples';

  @override
  String get pnlChannelAdjustments => 'Ledger adjustments';

  @override
  String get pnlChannelOther => 'Other';

  @override
  String get pnlShippingIncome => 'Shipping income';

  @override
  String get pnlShippingExpense => 'Shipping expense';

  @override
  String get pnlChannelSplit => 'B2B vs B2C';

  @override
  String pnlOrdersCount(int count) {
    return '$count orders';
  }

  @override
  String pnlReturnsCount(int count) {
    return '$count returns';
  }

  @override
  String get pnlStatement => 'Profit & loss statement';

  @override
  String get pnlSales => 'Sales';

  @override
  String get pnlCostOfSales => 'Cost of sales';

  @override
  String get pnlRecurringExpenses => 'Recurring expenses';

  @override
  String get pnlOtherExpenses => 'Other expenses';

  @override
  String get pnlRevenueVsExpenses => 'Revenue vs expenses';

  @override
  String get pnlExpenses => 'Expenses';

  @override
  String get pnlShippingTitle => 'Shipping: charged vs paid';

  @override
  String get pnlShippingDifference => 'Difference';

  @override
  String pnlPerDelivery(String income, String expense, int count) {
    return 'Per delivery: $income charged, $expense paid ($count deliveries)';
  }

  @override
  String pnlRecurringPosted(String posted, String due) {
    return '$posted posted of $due due for these months';
  }

  @override
  String get pnlExpenseMix => 'Where the money went';

  @override
  String get pnlLedgerMatches => 'Matches the ledger';

  @override
  String pnlLedgerMismatch(String amount) {
    return 'Differs from the ledger by $amount';
  }

  @override
  String pnlWarnCogs(String pct) {
    return 'Cost of goods is recorded for only $pct% of orders in this period, so profit here is overstated.';
  }

  @override
  String pnlWarnShipping(String pct) {
    return 'Only $pct% of the courier cost recorded on orders has reached the books, so shipping expense is understated.';
  }

  @override
  String pnlWarnRecurring(String posted, String due) {
    return 'Recurring expenses: $posted recorded of $due due for the months in this range.';
  }

  @override
  String get pnlNoteShippingInFreight =>
      'Before September 2026 shipping income was booked inside the courier expense account. It is shown separately here.';

  @override
  String get pnlRunningTotal => 'Running total for the period';

  @override
  String get expensesPeriodLabel => 'Period covered';

  @override
  String get expensesPeriodFrom => 'From';

  @override
  String get expensesPeriodTo => 'To';

  @override
  String get expensesPeriodSelect => 'Select the period';

  @override
  String get expensesPeriodHelper =>
      'The cost is split across months automatically.';

  @override
  String get expensesPeriodRequired => 'Choose the period this bill covers';

  @override
  String get expensesPeriodFromAfterTo =>
      'The period must start on or before its end';

  @override
  String get expensesPeriodAfterExpenseDate =>
      'The period cannot end after the expense date';

  @override
  String expensesPeriodValue(String from, String to) {
    return 'Period: $from – $to';
  }

  @override
  String get expensesPeriodTooLong =>
      'The period cannot be longer than 366 days';

  @override
  String get expensesPeriodJournalEntries => 'Period journal entries';

  @override
  String get reportsRangeLastMonth => 'Last Month';

  @override
  String reportShowAllCount(int count) {
    return 'Show all ($count)';
  }

  @override
  String get reportShowLess => 'Show less';

  @override
  String get reportOverridesTitle => 'Courier cost overrides';

  @override
  String get reportOverridesHint =>
      'Approved changes to what a courier was paid, compared with the area\'s standard rate';

  @override
  String get reportOverridesNetExtra => 'Net extra paid';

  @override
  String reportOverridesVsStandard(String pct) {
    return '$pct% above the standard rate on these orders';
  }

  @override
  String get reportOverridesExtraPaid => 'Paid above standard';

  @override
  String reportOverridesIncreases(int count, String avg) {
    return '$count orders, avg +$avg';
  }

  @override
  String get reportOverridesSaved => 'Paid below standard';

  @override
  String reportOverridesDecreases(int count) {
    return '$count orders';
  }

  @override
  String get reportOverridesShare => 'Orders with an override';

  @override
  String reportOverridesShareOf(int count, int total) {
    return '$count of $total deliveries';
  }

  @override
  String get reportOverridesDecisions => 'Decisions';

  @override
  String reportOverridesDecisionsValue(
    int approved,
    int rejected,
    int pending,
  ) {
    return '$approved approved · $rejected rejected · $pending pending';
  }

  @override
  String reportOverridesPendingExtra(String amount) {
    return 'Pending requests would add $amount';
  }

  @override
  String get reportOverridesByArea => 'Where the extra goes';

  @override
  String reportOverridesLargest(String pct) {
    return 'Largest single override: +$pct%';
  }

  @override
  String get dealsTitle => 'Special prices';

  @override
  String get dealsSubtitle =>
      'Deal prices for a set period, then back to normal';

  @override
  String get dealsNone => 'No active deals';

  @override
  String get dealsNew => 'New deal';

  @override
  String dealsHistory(int count) {
    return 'Past deals ($count)';
  }

  @override
  String get dealStatusActive => 'Active';

  @override
  String get dealStatusUpcoming => 'Upcoming';

  @override
  String get dealStatusExpired => 'Ended';

  @override
  String get dealStatusCancelled => 'Cancelled';

  @override
  String dealCategoryLabel(String group) {
    return 'All $group';
  }

  @override
  String dealRateVsNormal(String rate, String normal) {
    return '$rate (normally $normal)';
  }

  @override
  String get dealEditTitle => 'Edit deal';

  @override
  String get dealHelp =>
      'This customer pays these prices on orders placed during the deal dates. After the last day, the normal price applies again automatically.';

  @override
  String get dealPickDates => 'Choose the deal dates';

  @override
  String get dealStartLocked =>
      'A running deal keeps its start date and prices, because orders were already booked at them. You can change the end date, or end it and start a new deal.';

  @override
  String get dealAddCategory => 'Add category';

  @override
  String get dealAddItem => 'Add item';

  @override
  String get dealRateLabel => 'Deal price';

  @override
  String dealNormalPrice(String amount) {
    return 'Normal: $amount';
  }

  @override
  String get dealEnd => 'End deal';

  @override
  String get dealEndConfirm =>
      'End this deal? Orders placed today keep the deal price; from tomorrow this customer pays the normal price.';

  @override
  String get dealEnded => 'Deal ended';

  @override
  String get dealSaved => 'Deal saved';

  @override
  String get dealSaveFailed => 'Could not save the deal';

  @override
  String get dealNeedsDates => 'Choose the deal dates first';

  @override
  String get dealNeedsLines => 'Add at least one price';

  @override
  String get dealInvalidRate => 'Enter a valid price on every line';

  @override
  String get dealCancelled => 'Deal cancelled';

  @override
  String get dealEndsTonight =>
      'The deal ends tonight. From tomorrow this customer pays the normal price.';

  @override
  String get followupsMenuTitle => 'Follow-ups';

  @override
  String get followupsTitle => 'Follow-ups today';

  @override
  String get followupsSummaryDue => 'Due';

  @override
  String get followupsSummaryOverdue => 'Overdue';

  @override
  String get followupsSummaryCalls => 'Calls';

  @override
  String get followupsSummaryMessages => 'Messages';

  @override
  String get followupsSectionOverdue => 'Overdue';

  @override
  String get followupsSectionToday => 'Today';

  @override
  String get followupsEmpty => 'No follow-ups are due right now.';

  @override
  String get followupsLoadFailed => 'Could not load the follow-ups';

  @override
  String get followupsStep3h => 'After 3 hours';

  @override
  String followupsStepDay(String day) {
    return 'Day $day';
  }

  @override
  String get followupsChannelMessage => 'Message';

  @override
  String get followupsChannelCall => 'Call';

  @override
  String get followupsCustomerNew => 'New';

  @override
  String get followupsCustomerRepeat => 'Repeat';

  @override
  String get followupsValueHigh => 'High value (≥ 1000)';

  @override
  String get followupsValueLow => 'Under 1000';

  @override
  String get followupsRegular => 'Regular';

  @override
  String followupsWooOrder(String number) {
    return 'Order #$number';
  }

  @override
  String followupsLifetimeOrders(String count) {
    return '$count orders';
  }

  @override
  String followupsDueAt(String time) {
    return 'Due $time';
  }

  @override
  String get followupsActionWhatsapp => 'WhatsApp';

  @override
  String get followupsActionCopy => 'Copy message';

  @override
  String get followupsActionCall => 'Call';

  @override
  String get followupsActionLog => 'Log result';

  @override
  String get followupsActionSkip => 'Skip';

  @override
  String get followupsMessageCopied => 'Message copied';

  @override
  String get followupsNoWhatsapp => 'No WhatsApp number for this customer';

  @override
  String get followupsNoPhone => 'No phone number for this customer';

  @override
  String get followupsLogTitle => 'Log the follow-up result';

  @override
  String get followupsReachedLabel => 'Did the customer answer?';

  @override
  String get followupsReached => 'Reached';

  @override
  String get followupsNotReached => 'Not reached';

  @override
  String get followupsReachedRequired => 'Choose whether the customer answered';

  @override
  String get followupsOutcomeLabel => 'Outcome';

  @override
  String get followupsOutcomeRequired => 'Choose an outcome';

  @override
  String get followupsOutcomeHappy => 'Happy';

  @override
  String get followupsOutcomeQuality => 'Quality complaint';

  @override
  String get followupsOutcomeDelivery => 'Delivery complaint';

  @override
  String get followupsOutcomeNoReply => 'No reply';

  @override
  String get followupsOutcomeOptedOut => 'Wants no messages';

  @override
  String get followupsNotesHint => 'Notes (optional)';

  @override
  String get followupsConfirmQualityTitle => 'Log a quality complaint?';

  @override
  String get followupsConfirmQualityBody =>
      'This customer leaves the follow-up cycle, and the complaint goes to Karim.';

  @override
  String get followupsConfirmOptOutTitle => 'Stop messaging this customer?';

  @override
  String get followupsConfirmOptOutBody =>
      'This customer leaves the follow-up cycle and gets no more follow-up messages.';

  @override
  String get followupsLogged => 'Result saved';

  @override
  String followupsEscalated(String task) {
    return 'A task was opened: $task';
  }

  @override
  String get followupsApologyTitle => 'Apology code';

  @override
  String get followupsApologyBody => 'Send this code to the customer:';

  @override
  String get followupsApologyCopy => 'Copy code';

  @override
  String get followupsApologyCopied => 'Code copied';

  @override
  String get followupsApologySend => 'Send on WhatsApp';

  @override
  String get followupsSkipTitle => 'Skip this follow-up?';

  @override
  String get followupsSkipReasonHint => 'Reason (optional)';

  @override
  String get followupsSkipped => 'Follow-up skipped';

  @override
  String get followupsStatsCalls => 'Calls made';

  @override
  String get followupsStatsReached => 'Calls answered';

  @override
  String get followupsStatsReachRate => 'Answer rate';

  @override
  String get followupsStatsReordered => 'Ordered again';

  @override
  String get followupsStatsByStatus => 'By status';

  @override
  String get followupsStatsByOutcome => 'By outcome';

  @override
  String get followupsStatsEmpty => 'No data yet';

  @override
  String get followupsStatusPending => 'Pending';

  @override
  String get followupsStatusDone => 'Done';

  @override
  String get followupsStatusSkipped => 'Skipped';

  @override
  String get followupsStatsTotal => 'Follow-ups';

  @override
  String get followupsStatsTouchedCustomers => 'Customers followed up';

  @override
  String get followupsStatsReorderRate => 'Reorder rate';

  @override
  String get followupsSentTotal => 'Sent';

  @override
  String get followupsSentDelivered => 'Delivered';

  @override
  String get followupsSentRead => 'Read';

  @override
  String get followupsSentFailed => 'Failed';

  @override
  String get followupsSentReplied => 'Replied on WhatsApp';

  @override
  String get followupsSentReordered => 'Ordered again (30 days)';

  @override
  String get followupsSentOptedOut => 'Customers who stopped messages';

  @override
  String get followupsSentRefused => 'Refused by WhatsApp, waiting for staff';

  @override
  String get followupsSentByStep => 'By step';

  @override
  String get followupsSentByDay => 'By day';

  @override
  String get followupsSentCancelled => 'Cancelled before sending';

  @override
  String get followupsSentMessages => 'Messages';

  @override
  String followupsSentStepSummary(String sent, String read, String reordered) {
    return '$sent sent · $read read · $reordered ordered again';
  }

  @override
  String followupsSentCode(String code) {
    return 'Code $code';
  }

  @override
  String followupsSentReorderInvoice(String invoice) {
    return 'Ordered again: $invoice';
  }

  @override
  String get followupsSentReasonOrderCancelled => 'Order cancelled';

  @override
  String get followupsSentReasonOrderReturned => 'Order returned';

  @override
  String get followupsSentReasonExcluded => 'B2B / employee';

  @override
  String get followupsSentReasonNewOrder => 'Ordered again';

  @override
  String get followupsSentReasonOptedOut => 'Stopped messages';

  @override
  String get followupsSentReasonQuality => 'Quality complaint';

  @override
  String get customerSegmentRegular => 'Regulars';

  @override
  String get rosterViewWeek => 'Week';

  @override
  String get rosterViewMonth => 'Month';

  @override
  String get rosterPreviousWeek => 'Previous week';

  @override
  String get rosterNextWeek => 'Next week';

  @override
  String get rosterSelectDays => 'Select days';

  @override
  String get rosterLegendButton => 'What the cells mean';

  @override
  String get rosterMoreOptions => 'More options';

  @override
  String rosterCoverShiftSummary(String shift) {
    return 'Cover shift: $shift';
  }

  @override
  String get rosterUncoveredFix => 'Fix';

  @override
  String get rosterUncoveredListTitle => 'Days off with nobody covering';

  @override
  String get rosterPlanAction => 'Plan the rota';

  @override
  String get rosterPlanTitle => 'Plan the rota';

  @override
  String get rosterPlanStepWhen => 'When';

  @override
  String get rosterPlanStepWho => 'Who';

  @override
  String get rosterPlanStepWeek => 'Their week';

  @override
  String get rosterPlanStepCheck => 'Check & apply';

  @override
  String get rosterPlanBack => 'Back';

  @override
  String get rosterPlanNext => 'Next';

  @override
  String get rosterPlanApply => 'Apply';

  @override
  String get rosterPlanWhenQuestion => 'Which days are you planning?';

  @override
  String get rosterPlanNextMonth => 'Next month';

  @override
  String get rosterPlanRestOfMonth => 'Rest of this month';

  @override
  String get rosterPlanCustom => 'Custom';

  @override
  String get rosterPlanPickDates => 'Pick the dates';

  @override
  String rosterPlanPeriodRange(String start, String end, String days) {
    return '$start – $end ($days days)';
  }

  @override
  String rosterPlanPeriodTooLong(String max) {
    return 'That is more than $max days. Pick a shorter period.';
  }

  @override
  String get rosterPlanPeriodNone => 'Pick the dates first.';

  @override
  String get rosterPlanStandingHint =>
      'The week you set carries on after these dates too, so the next months follow it on their own. Covers are only for these dates.';

  @override
  String get rosterPlanWhoQuestion => 'Who are you planning for?';

  @override
  String get rosterPlanSelectAll => 'Select all';

  @override
  String get rosterPlanUnselectAll => 'Unselect all';

  @override
  String rosterPlanSelectedCount(String count) {
    return '$count selected';
  }

  @override
  String get rosterPlanNoBranch => 'No branch yet';

  @override
  String get rosterPlanNoPeople => 'There is nobody you can plan for.';

  @override
  String get rosterPlanSameForEveryone => 'Same for everyone';

  @override
  String rosterPlanSameForEveryoneHint(String name) {
    return 'Copies $name’s shift and days off to the others.';
  }

  @override
  String rosterPlanSameForEveryoneDone(String name) {
    return 'Copied $name’s shift and days off to everyone.';
  }

  @override
  String get rosterPlanShift => 'Shift';

  @override
  String get rosterPlanOtherShifts => 'Other shifts';

  @override
  String get rosterPlanBranch => 'Branch';

  @override
  String get rosterPlanDaysOff => 'Day off';

  @override
  String get rosterPlanWorksEveryDay => 'No day off: works every day';

  @override
  String rosterPlanFridayVariant(String shift) {
    return 'On Fridays use $shift';
  }

  @override
  String rosterPlanCoverQuestion(String day) {
    return 'Who covers $day?';
  }

  @override
  String get rosterPlanNobodyCovers => 'Nobody';

  @override
  String get rosterPlanCoverShift => 'Cover shift';

  @override
  String get rosterPlanPickShift => 'Pick a shift';

  @override
  String get rosterPlanNeedsShift => 'Pick a shift for this person.';

  @override
  String get rosterPlanNeedsCoverShift => 'Pick the cover shift.';

  @override
  String get rosterPlanIncomplete =>
      'Every person needs a shift, and every cover needs a shift.';

  @override
  String get rosterPlanNoUsualWeek => 'No usual week saved yet';

  @override
  String get rosterPlanWeekdaySaturday => 'Saturday';

  @override
  String get rosterPlanWeekdaySunday => 'Sunday';

  @override
  String get rosterPlanWeekdayMonday => 'Monday';

  @override
  String get rosterPlanWeekdayTuesday => 'Tuesday';

  @override
  String get rosterPlanWeekdayWednesday => 'Wednesday';

  @override
  String get rosterPlanWeekdayThursday => 'Thursday';

  @override
  String get rosterPlanWeekdayFriday => 'Friday';

  @override
  String get rosterPlanChecking => 'Checking the plan…';

  @override
  String get rosterPlanCheckFailed => 'Could not check the plan.';

  @override
  String get rosterPlanLoadFailed => 'Could not load the people.';

  @override
  String get rosterPlanSummaryTitle => 'What will happen';

  @override
  String get rosterPlanSummaryPeople => 'People';

  @override
  String get rosterPlanSummaryShiftDays => 'Working days';

  @override
  String get rosterPlanSummaryDayOffs => 'Days off';

  @override
  String get rosterPlanSummaryCovers => 'Covers';

  @override
  String get rosterPlanSummaryManualKept => 'Hand-edited days kept';

  @override
  String get rosterPlanSummaryManualReplaced => 'Hand-edited days replaced';

  @override
  String get rosterPlanErrorsTitle => 'Fix these first';

  @override
  String get rosterPlanWarningsTitle => 'Worth checking';

  @override
  String get rosterPlanNotesTitle => 'Good to know';

  @override
  String rosterPlanIssueWhere(String name, String date) {
    return '$name · $date';
  }

  @override
  String get rosterPlanNoIssues => 'No problems found.';

  @override
  String get rosterPlanApplyBlocked => 'Fix the problems in red to apply.';

  @override
  String get rosterPlanManualTitle => 'Days changed by hand';

  @override
  String get rosterPlanManualHint =>
      'These days were changed one by one. They stay as they are unless you replace them.';

  @override
  String get rosterPlanReplaceManual => 'Replace these too';

  @override
  String get rosterPlanManualEmpty => 'Emptied';

  @override
  String rosterPlanManualLine(String date, String current) {
    return '$date · $current';
  }

  @override
  String get rosterPlanGrantPos =>
      'Give the person covering POS access at that branch';

  @override
  String rosterPlanApplied(String count) {
    return 'Rota planned for $count people.';
  }

  @override
  String rosterRepeatWeekly(String weekday) {
    return 'Repeat every $weekday';
  }

  @override
  String rosterRepeatWeeklyHelper(String weekday) {
    return 'From this day on, this becomes their usual $weekday.';
  }

  @override
  String get rosterRepeatUsualBranch => 'Their usual branch';

  @override
  String get rosterRepeatNoPosAccess =>
      'POS access is given one day at a time, so a repeating change does not give it.';

  @override
  String get rosterWeeklyReviewTitle => 'Check the weekly change';

  @override
  String get rosterWeeklyChecking => 'Checking the change…';

  @override
  String get rosterWeeklyCheckFailed => 'Could not check the change.';

  @override
  String get rosterWeeklyStandingTitle => 'Their usual week';

  @override
  String rosterWeeklyStandingLine(
    String name,
    String weekday,
    String before,
    String after,
  ) {
    return '$name · $weekday: $before → $after';
  }

  @override
  String get rosterWeeklyNothing => 'Nothing';

  @override
  String get rosterWeeklyOff => 'Off';

  @override
  String rosterWeeklyChangeCount(
    int count,
    String countText,
    String weekday,
    String start,
    String through,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText ${weekday}s from $start to $through will change.',
      one: '1 $weekday ($start) will change.',
    );
    return '$_temp0';
  }

  @override
  String rosterWeeklyNoDatedDays(String weekday) {
    return 'No $weekday already on the calendar changes.';
  }

  @override
  String rosterWeeklyRotaFromAfter(String through, String rotaFrom) {
    return 'After $through, the weekly rota carries it on (from $rotaFrom).';
  }

  @override
  String rosterWeeklyRotaFrom(String rotaFrom) {
    return 'The weekly rota carries it on from $rotaFrom.';
  }

  @override
  String get rosterWeeklyReplacedHint => 'These days will be changed too.';

  @override
  String get rosterWeeklyApply => 'Apply every week';

  @override
  String rosterWeeklyApplied(String weekday, String start) {
    return 'Saved: every $weekday from $start.';
  }

  @override
  String get rosterWeeklyNotApplied =>
      'Nothing was changed. Check the preview and try again.';

  @override
  String get courierAlertsTitle => 'Courier alerts';

  @override
  String get courierAlertsNoAccess =>
      'Courier alerts are only available to the delivery managers.';

  @override
  String get courierAlertsFilterOpen => 'Open';

  @override
  String get courierAlertsFilterAll => 'All';

  @override
  String get courierAlertsEmptyOpen =>
      'No open alerts. All couriers look fine.';

  @override
  String get courierAlertsEmptyAll => 'No alerts yet.';

  @override
  String courierAlertsOpenCount(int count) {
    return '$count open';
  }

  @override
  String courierAlertsHighCount(int count) {
    return '$count high';
  }

  @override
  String get courierAlertsSeverityLow => 'Low';

  @override
  String get courierAlertsSeverityMedium => 'Medium';

  @override
  String get courierAlertsSeverityHigh => 'High';

  @override
  String get courierAlertsStatusOpen => 'Open';

  @override
  String get courierAlertsStatusReviewed => 'Reviewed';

  @override
  String get courierAlertsStatusDismissed => 'Dismissed';

  @override
  String get courierAlertTypeDetour => 'Detour';

  @override
  String get courierAlertTypeExcessiveIdle => 'Excessive idle';

  @override
  String get courierAlertTypeSpeeding => 'Speeding';

  @override
  String get courierAlertTypeDeliveredFarFromPin => 'Delivered far from pin';

  @override
  String get courierAlertTypePingGap => 'Ping gap';

  @override
  String get courierAlertTypeMockGps => 'Mock GPS';

  @override
  String get courierAlertTypeUnexpectedStop => 'Unexpected stop';

  @override
  String get courierAlertTypeStalePing => 'Stale ping';

  @override
  String get courierAlertTypeTrackerModeChanged => 'Tracker mode changed';

  @override
  String get courierAlertTypeTrackingLost => 'Tracking lost';

  @override
  String get courierAlertTypeActionRefused => 'Action refused';

  @override
  String get courierAlertTypeDeliveryCodeFailed => 'Delivery code failed';

  @override
  String get courierAlertsFieldCourier => 'Courier';

  @override
  String get courierAlertsFieldInvoice => 'Invoice';

  @override
  String get courierAlertsFieldBranch => 'Branch';

  @override
  String get courierAlertsFieldDetected => 'Detected';

  @override
  String get courierAlertsFieldStatus => 'Status';

  @override
  String get courierAlertsFieldDetails => 'Details';

  @override
  String get courierAlertsFieldNote => 'Review note';

  @override
  String get courierAlertsNoteLabel => 'Note (optional)';

  @override
  String get courierAlertsMarkReviewed => 'Mark reviewed';

  @override
  String get courierAlertsDismiss => 'Dismiss';

  @override
  String get courierAlertsUpdated => 'Alert updated.';

  @override
  String get courierSetupEntry => 'Couriers';

  @override
  String get courierSetupTitle => 'Couriers';

  @override
  String get courierSetupAction => 'Set up courier';

  @override
  String get courierSetupSearchHint => 'Search by name, branch or login';

  @override
  String get courierSetupEmpty => 'No employees found.';

  @override
  String get courierSetupStatusReady => 'Ready';

  @override
  String get courierSetupStatusNeedsFix => 'Needs fixing';

  @override
  String get courierSetupStatusNotCourier => 'Not a courier yet';

  @override
  String get courierSetupSetUp => 'Set up as courier';

  @override
  String get courierSetupFix => 'Repair setup (new PIN)';

  @override
  String get courierSetupResetPin => 'Reset PIN';

  @override
  String get courierSetupResetTitle => 'Reset PIN?';

  @override
  String courierSetupResetBody(String name) {
    return '$name will get a new PIN and the old one stops working. The new PIN is shown once.';
  }

  @override
  String get courierSetupFormTitle => 'Set up courier';

  @override
  String get courierSetupModeExisting => 'Existing employee';

  @override
  String get courierSetupModeNew => 'New person';

  @override
  String get courierSetupEmployee => 'Employee';

  @override
  String get courierSetupEmployeeHint => 'Type a name to search';

  @override
  String get courierSetupFullName => 'Full name';

  @override
  String get courierSetupMobile => 'Mobile number';

  @override
  String get courierSetupBranch => 'Branch';

  @override
  String get courierSetupPosProfile => 'POS profile (optional)';

  @override
  String get courierSetupPosProfileHelp =>
      'Leave empty to use the branch default.';

  @override
  String get courierSetupSubmit => 'Set up';

  @override
  String get courierSetupProblemNoIdentity => 'Login not linked to an employee';

  @override
  String get courierSetupProblemNoPosProfile => 'Not on a POS profile';

  @override
  String get courierSetupProblemNoEmployeeBranch => 'Employee has no branch';

  @override
  String get courierSetupProblemBranchNotAssigned =>
      'Branch does not match POS profile';

  @override
  String get courierSetupHintNoIdentity =>
      'Open the Employee and set User ID to this login, and make sure the Employee is Active.';

  @override
  String get courierSetupHintNoPosProfile =>
      'Add this login to the Users table of the branch POS Profile.';

  @override
  String get courierSetupHintNoEmployeeBranch =>
      'Set the Branch on the Employee record.';

  @override
  String get courierSetupHintBranchNotAssigned =>
      'The Employee branch and the POS Profile branch must be the same.';

  @override
  String get courierSetupDoneTitle => 'Courier ready';

  @override
  String get courierSetupPinResetTitle => 'New PIN';

  @override
  String get courierSetupLoginId => 'Login ID';

  @override
  String get courierSetupPinLabel => 'PIN';

  @override
  String get courierSetupPinOnce =>
      'Shown only once. Copy it or send it now; it cannot be shown again.';

  @override
  String get courierSetupNoPin =>
      'The server did not return a PIN. Use Reset PIN to issue one.';

  @override
  String get courierSetupWebLink => 'Web link';

  @override
  String get courierSetupApkLink => 'Android app';

  @override
  String get courierSetupStillMissing => 'Still missing';

  @override
  String get courierSetupShareWhatsapp => 'Share to courier on WhatsApp';

  @override
  String get courierSetupCopy => 'Copy';

  @override
  String get courierSetupCopied => 'Copied.';

  @override
  String get rptCourierBalancesPartnerFallback => 'Partner';

  @override
  String rptInstapayExpectedReference(String reference) {
    return 'Ref: $reference';
  }

  @override
  String get rptRangeToday => 'Today';

  @override
  String get rptRangeYesterday => 'Yesterday';

  @override
  String get rptRangeLast7Days => 'Last 7 days';

  @override
  String get rptRangeThisMonth => 'This month';

  @override
  String get rptRangeLastMonth => 'Last month';

  @override
  String get rptRangeLast30Days => 'Last 30 days';

  @override
  String get rptRangeLast90Days => 'Last 90 days';

  @override
  String get rptRangeThisYear => 'Year to date';

  @override
  String get rptBranchLabel => 'Branch';

  @override
  String get rptAllBranches => 'All branches';

  @override
  String get rptExport => 'Export CSV';

  @override
  String get rptExportEmpty => 'There is nothing to export yet.';

  @override
  String get rptExportFailed => 'Could not export the report.';

  @override
  String get rptExportCopied =>
      'Sharing is unavailable, so the report was copied to the clipboard.';

  @override
  String get rptHubOverview => 'Overview';

  @override
  String get rptHubDailyOps => 'Daily operations';

  @override
  String get rptHubSalesCustomers => 'Sales & customers';

  @override
  String get rptHubStock => 'Stock';

  @override
  String get rptHubPeople => 'People';

  @override
  String get rptBusinessOverviewTitle => 'Business overview';

  @override
  String get rptBusinessOverviewSubtitle =>
      'Profit & loss, key figures and the split by branch';

  @override
  String get rptUnitEconomicsTitle => 'Unit economics';

  @override
  String get rptUnitEconomicsSubtitle =>
      'Contribution per order and the break-even point';

  @override
  String get rptDailyCloseTitle => 'Daily close';

  @override
  String get rptDailyCloseSubtitle =>
      'Sales by branch, channel and payment method';

  @override
  String get rptCashOverShortTitle => 'Cash over/short';

  @override
  String get rptCashOverShortSubtitle =>
      'Drawer differences by branch, cashier and shift';

  @override
  String get rptFulfilmentSlaTitle => 'Fulfilment SLA';

  @override
  String get rptFulfilmentSlaSubtitle =>
      'Time to dispatch and deliver, late orders and cancellations';

  @override
  String get rptPromoTitle => 'Promo codes';

  @override
  String get rptPromoSubtitle => 'Orders, discount and revenue for each code';

  @override
  String get rptStockAdjustmentsTitle => 'Waste & adjustments';

  @override
  String get rptStockAdjustmentsSubtitle =>
      'The value of stock lost and gained';

  @override
  String get rptLabourCostTitle => 'Labour cost';

  @override
  String get rptLabourCostSubtitle =>
      'Labour cost against sales for each branch';

  @override
  String get rptInventoryRestockTitle => 'Inventory & restock';

  @override
  String get rptInventoryRestockSubtitle =>
      'Stock levels, sales speed and what to reorder';

  @override
  String get rptCustomersSegmentsTitle => 'Customers & segments';

  @override
  String get rptCustomersSegmentsSubtitle =>
      'Retention, top customers and customer segments';

  @override
  String get rptShippingCouriersTitle => 'Shipping & couriers';

  @override
  String get rptShippingCouriersSubtitle =>
      'Courier cost against shipping charged, and unsettled balances';

  @override
  String get rptComingSoon => 'This report is on its way.';

  @override
  String get rptAccessDenied => 'You do not have access to this report.';

  @override
  String get rptB2bReportTooltip => 'B2B sales report';

  @override
  String get rptAlertsTitle => 'Alerts';

  @override
  String get rptDailyCloseNetSales => 'Net sales';

  @override
  String get rptDailyCloseOrders => 'Orders';

  @override
  String get rptDailyCloseAvgOrder => 'Avg order value';

  @override
  String get rptDailyCloseShipping => 'Shipping income';

  @override
  String get rptDailyCloseReturns => 'Returns';

  @override
  String rptDailyCloseReturnsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count returns',
      one: '1 return',
      zero: 'No returns',
    );
    return '$_temp0';
  }

  @override
  String get rptDailyCloseCancelled => 'Cancelled';

  @override
  String get rptDailyCloseGrossSales => 'Gross sales';

  @override
  String get rptDailyCloseGrandTotal => 'Grand total';

  @override
  String get rptDailyCloseOutstanding => 'Not yet collected';

  @override
  String get rptDailyCloseOutstandingHint =>
      'Settled later by journal entry (Talabat, couriers)';

  @override
  String get rptDailyCloseChannels => 'Sales by channel';

  @override
  String get rptDailyCloseByHour => 'Sales by hour';

  @override
  String get rptDailyClosePayments => 'Payments by method';

  @override
  String get rptDailyCloseBranches => 'Branches';

  @override
  String get rptDailyCloseBranchesHint =>
      'Tap a branch for its channels and payments';

  @override
  String get rptDailyCloseChannel => 'Channel';

  @override
  String get rptDailyCloseMode => 'Payment method';

  @override
  String get rptDailyCloseAmount => 'Amount';

  @override
  String get rptDailyCloseShare => 'Share';

  @override
  String get rptDailyCloseBranch => 'Branch';

  @override
  String get rptDailyCloseHour => 'Hour';

  @override
  String get rptDailyClosePrevDay => 'Previous day';

  @override
  String get rptDailyCloseNextDay => 'Next day';

  @override
  String rptDailyCloseOrdersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
      zero: 'No orders',
    );
    return '$_temp0';
  }

  @override
  String get rptDailyCloseChannelPos => 'Walk-in (POS)';

  @override
  String get rptDailyCloseChannelWoo => 'Online store';

  @override
  String get rptDailyCloseChannelTalabat => 'Talabat';

  @override
  String get rptDailyCloseChannelB2b => 'B2B';

  @override
  String get rptDailyCloseChannelStaff => 'Staff';

  @override
  String get rptDailyCloseChannelSamples => 'Samples';

  @override
  String get rptDailyCloseChannelPartner => 'Delivery partner';

  @override
  String rptDailyCloseScopedTo(String branches) {
    return 'Limited to your branches: $branches';
  }

  @override
  String get rptCashOverShortShifts => 'Shifts';

  @override
  String get rptCashOverShortWithDiff => 'Shifts with a difference';

  @override
  String get rptCashOverShortOver => 'Over';

  @override
  String get rptCashOverShortShort => 'Short';

  @override
  String get rptCashOverShortNet => 'Net';

  @override
  String get rptCashOverShortBranches => 'By branch';

  @override
  String get rptCashOverShortCashiers => 'By cashier';

  @override
  String get rptCashOverShortCashiersHint => 'Largest shortage first';

  @override
  String get rptCashOverShortCashier => 'Cashier';

  @override
  String get rptCashOverShortBranch => 'Branch';

  @override
  String get rptCashOverShortShiftList => 'Shift closes';

  @override
  String get rptCashOverShortShiftListHint =>
      'Newest first. Tap a shift for details.';

  @override
  String get rptCashOverShortShift => 'Shift';

  @override
  String get rptCashOverShortOpened => 'Opened';

  @override
  String get rptCashOverShortClosed => 'Closed';

  @override
  String get rptCashOverShortExpected => 'Expected';

  @override
  String get rptCashOverShortCounted => 'Counted';

  @override
  String get rptCashOverShortDifference => 'Difference';

  @override
  String get rptCashOverShortOpeningEntry => 'Opening entry';

  @override
  String get rptCashOverShortOpeningDifference => 'Difference at opening';

  @override
  String get rptCashOverShortLedger => 'Cash Over/Short account';

  @override
  String get rptCashOverShortLedgerHint =>
      'What was booked to the ledger in this period';

  @override
  String get rptCashOverShortAtClose => 'Booked at shift close';

  @override
  String get rptCashOverShortAtOpen => 'Booked at shift open';

  @override
  String get rptCashOverShortUnlinked => 'Not linked to a shift';

  @override
  String get rptCashOverShortNotClosed => 'Not closed';

  @override
  String get rptCashOverShortNoShifts => 'No closed shifts in this period';

  @override
  String get rptSlaOrders => 'Orders';

  @override
  String get rptSlaDelivered => 'Delivered';

  @override
  String get rptSlaCancelled => 'Cancelled';

  @override
  String get rptSlaReturned => 'Returned';

  @override
  String get rptSlaMedianDispatch => 'Median time to dispatch';

  @override
  String get rptSlaMedianDeliver => 'Median time to deliver';

  @override
  String get rptSlaP90Deliver => '90% delivered within';

  @override
  String get rptSlaLateOrders => 'Late orders';

  @override
  String get rptSlaOpenLate => 'Late, not delivered yet';

  @override
  String rptSlaLatePct(String pct) {
    return '$pct% of delivered';
  }

  @override
  String rptSlaMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String rptSlaHoursMinutes(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String rptSlaLateRule(String minutes) {
    return 'Late = delivered after the slot end, or more than $minutes minutes after the order when it has no slot.';
  }

  @override
  String rptSlaDataSince(String date) {
    return 'Order timings are recorded from $date; earlier orders have no timings.';
  }

  @override
  String rptSlaTimedCoverage(String dispatched, String delivered) {
    return 'Timed orders: $dispatched dispatched, $delivered delivered';
  }

  @override
  String get rptSlaByDay => 'Delivery time by day';

  @override
  String get rptSlaByDayHint => 'Median minutes from order to delivery';

  @override
  String get rptSlaLateByDay => 'Late orders by day';

  @override
  String get rptSlaBranches => 'By branch';

  @override
  String get rptSlaBranch => 'Branch';

  @override
  String get rptSlaDispatchCol => 'To dispatch';

  @override
  String get rptSlaDeliverCol => 'To deliver';

  @override
  String get rptSlaLateCol => 'Late';

  @override
  String get rptSlaLateList => 'Late orders (worst first)';

  @override
  String get rptSlaLateListHint => 'Tap an order for its timings';

  @override
  String get rptSlaInvoice => 'Order';

  @override
  String get rptSlaCustomer => 'Customer';

  @override
  String get rptSlaLateBy => 'Late by';

  @override
  String get rptSlaCreated => 'Ordered at';

  @override
  String get rptSlaDeadline => 'Deadline';

  @override
  String get rptSlaDeliveredAt => 'Delivered at';

  @override
  String get rptSlaNotDelivered => 'Not delivered yet';

  @override
  String get rptSlaSlot => 'Delivery slot';

  @override
  String get rptSlaRule => 'Judged by';

  @override
  String get rptSlaRuleSlot => 'Slot end';

  @override
  String get rptSlaRuleSlotStart => 'Slot start + time limit';

  @override
  String get rptSlaRuleThreshold => 'Time limit';

  @override
  String get rptSlaState => 'Status';

  @override
  String get rptSlaTotalTime => 'Order to delivery';

  @override
  String get rptSlaCancellations => 'Cancellation reasons';

  @override
  String get rptSlaReason => 'Reason';

  @override
  String get rptSlaCount => 'Count';

  @override
  String get rptSlaNoReason => 'No reason given';

  @override
  String get rptSlaNoLate => 'No late orders in this period';

  @override
  String get rptSlaCopyInvoice => 'Copy order number';

  @override
  String get rptSlaCopied => 'Order number copied';

  @override
  String rptG1BranchGlNote(String branch) {
    return 'Branch $branch: sales, cost of goods and shipping income are for this branch. Expenses, net profit and the ledger check are company-wide.';
  }

  @override
  String get rptG1AtAGlance => 'At a glance';

  @override
  String get rptG1ByBranchTitle => 'By branch';

  @override
  String get rptG1ByBranchHint => 'Tap a branch to show only its figures';

  @override
  String get rptG1ColMargin => 'Margin';

  @override
  String get rptG1ColMetric => 'Metric';

  @override
  String get rptG1ColAmount => 'Amount';

  @override
  String get rptG1ShipCostVsCharged => 'Courier cost vs charged';

  @override
  String get rptG1ShipCostVsChargedHint =>
      'What customers paid for delivery against what couriers cost';

  @override
  String get rptG1ShipLossByArea => 'Loss by area';

  @override
  String get rptG1ShipLossByAreaHint =>
      'Shipping net per area, biggest loss first';

  @override
  String get rptG1ColArea => 'Area';

  @override
  String get rptG1ColCost => 'Cost';

  @override
  String get rptG1ColCharged => 'Charged';

  @override
  String get rptG1ColNet => 'Net';

  @override
  String get rptG1Settled => 'Settled';

  @override
  String rptG1UnsettledAsOf(String date) {
    return 'As of $date';
  }

  @override
  String get rptG1ColCourier => 'Courier';

  @override
  String get rptG1ColOwed => 'Owed';

  @override
  String get rptG1ColDaysAged => 'Days';

  @override
  String get rptG1DoubleTrips => 'Double trips';

  @override
  String get rptG1DoubleExtraCost => 'Extra courier cost';

  @override
  String rptG1OverridesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overrides',
      one: '1 override',
    );
    return '$_temp0';
  }

  @override
  String get rptG1Units => 'Units';

  @override
  String get rptG1ColType => 'Type';

  @override
  String get rptG1CostBasis => 'Cost basis';

  @override
  String get rptG1CostActual => 'Actual';

  @override
  String get rptG1CostBom => 'Estimated (BOM)';

  @override
  String get rptG1CostNone => 'No cost';

  @override
  String rptG1CostCoverage(String pct) {
    return 'Cost of goods is actual for $pct% of revenue; the rest is estimated from recipes (BOM).';
  }

  @override
  String get rptG1OrdersTrend => 'Orders over time';

  @override
  String get rptG1ProductTapHint => 'Tap a product for details';

  @override
  String get rptG1AvgPrice => 'Avg price per unit';

  @override
  String get rptG1CostPerUnit => 'Cost per unit';

  @override
  String get rptG1ColClient => 'Client';

  @override
  String get rptG1ColGroup => 'Group';

  @override
  String get rptG1ColClients => 'Clients';

  @override
  String get rptG1ColLastOrder => 'Last order';

  @override
  String get rptG1ColDaysSince => 'Days since';

  @override
  String get rptG2RestockAll => 'All';

  @override
  String get rptG2RestockStatusOther => 'Other';

  @override
  String get rptG2ColumnSuggestedQty => 'Suggested';

  @override
  String get rptG2ColumnDaysCover => 'Days cover';

  @override
  String get rptG2RestockEmpty => 'No items match this filter.';

  @override
  String get rptG2RestockHint => 'Tap an item to see its sales velocity.';

  @override
  String rptG2RecencyDaysAgo(String days) {
    return '$days days ago';
  }

  @override
  String rptG2OrdersCount(String count) {
    return '$count orders';
  }

  @override
  String get rptG2SegmentOverlay => 'Overlay';

  @override
  String get rptG2SegmentsOverlayNote =>
      'Overlay segments overlap the others and are not counted in the total.';

  @override
  String get rptG2ColumnMobile => 'Mobile';

  @override
  String get rptG2ColumnTerritory => 'Territory';

  @override
  String get rptG2ColumnUpdatedOn => 'Updated on';

  @override
  String get rptG2CustomerSummaryTitle => 'Customer summary';

  @override
  String get rptG2StockValue => 'Stock value';

  @override
  String get rptG2GrandTotal => 'Grand total';

  @override
  String get rptG2GroupTotal => 'Group total';

  @override
  String get rptG2TotalQty => 'Total qty';

  @override
  String get rptG2Company => 'Company';

  @override
  String get rptG2Refresh => 'Refresh';

  @override
  String get rptUnitEconInputsTitle => 'Owner inputs';

  @override
  String get rptUnitEconInputsSubtitle =>
      'Values you enter. They are estimates and are not booked in the ledger.';

  @override
  String get rptUnitEconEditInputs => 'Edit inputs';

  @override
  String get rptUnitEconAdSpend => 'Ad spend';

  @override
  String get rptUnitEconAdSpendHelp => 'Total for the selected period';

  @override
  String get rptUnitEconKashierPct => 'Kashier fee %';

  @override
  String get rptUnitEconKashierPctHelp =>
      'Applied to revenue paid through Kashier';

  @override
  String get rptUnitEconTalabatPct => 'Talabat commission %';

  @override
  String get rptUnitEconTalabatPctHelp => 'Applied to Talabat-channel revenue';

  @override
  String get rptUnitEconExtraFixed => 'Extra fixed costs';

  @override
  String get rptUnitEconExtraFixedHelp =>
      'Costs not in the books, such as salaries off payroll, investor return or tools';

  @override
  String rptUnitEconAppliedAmount(String amount) {
    return 'Applied in this report: $amount';
  }

  @override
  String get rptUnitEconResetDefaults => 'Reset to defaults';

  @override
  String get rptUnitEconInvalidNumber => 'Enter a number of 0 or more';

  @override
  String get rptUnitEconInvalidPct => 'Enter a percentage between 0 and 100';

  @override
  String get rptUnitEconBadgeOwnerInput => 'Owner input';

  @override
  String get rptUnitEconBadgeEstimate => 'Estimate';

  @override
  String get rptUnitEconLegend =>
      'Figures tagged Estimate or Owner input are not booked amounts.';

  @override
  String get rptUnitEconContributionMargin => 'Contribution margin';

  @override
  String get rptUnitEconNetProfit => 'Net profit';

  @override
  String get rptUnitEconWaterfallTitle => 'From revenue to net profit';

  @override
  String get rptUnitEconRevenue => 'Revenue';

  @override
  String get rptUnitEconCogs => 'Cost of goods';

  @override
  String get rptUnitEconShippingNet => 'Net delivery cost';

  @override
  String get rptUnitEconKashierFees => 'Kashier fees';

  @override
  String get rptUnitEconTalabatCommission => 'Talabat commission';

  @override
  String get rptUnitEconVariableTotal => 'Variable costs';

  @override
  String get rptUnitEconContribution => 'Contribution';

  @override
  String get rptUnitEconRecurring => 'Recurring expenses';

  @override
  String get rptUnitEconOtherExpenses => 'Other expenses';

  @override
  String get rptUnitEconFixedTotal => 'Fixed costs';

  @override
  String get rptUnitEconBreakEvenTitle => 'Break-even';

  @override
  String get rptUnitEconBreakEvenRevenue => 'Break-even revenue';

  @override
  String get rptUnitEconBreakEvenOrders => 'Break-even orders';

  @override
  String get rptUnitEconGap => 'Gap to break-even';

  @override
  String rptUnitEconPastBreakEven(String amount) {
    return 'Past break-even by $amount';
  }

  @override
  String rptUnitEconProgress(String pct) {
    return '$pct of break-even revenue reached';
  }

  @override
  String get rptUnitEconNoBreakEven =>
      'No break-even point: orders do not cover their variable costs.';

  @override
  String get rptUnitEconPerOrderTitle => 'Per order';

  @override
  String get rptUnitEconFees => 'Fees';

  @override
  String get rptUnitEconShipping => 'Delivery';

  @override
  String get rptUnitEconNotesTitle => 'Notes';

  @override
  String get rptUnitEconMetric => 'Metric';

  @override
  String get rptUnitEconValue => 'Value';

  @override
  String get rptUnitEconNoteAdSpendIsOwnerInput =>
      'Ad spend is your input, not a booked amount.';

  @override
  String get rptUnitEconNoteAdSpendNotEntered =>
      'Ad spend is not entered, so net profit leaves out advertising.';

  @override
  String get rptUnitEconNoteExtraFixedIsOwnerInput =>
      'Extra fixed costs are your input, not booked amounts.';

  @override
  String get rptUnitEconNoteKashierFeesEstimated =>
      'Kashier fees are estimated from your fee %.';

  @override
  String get rptUnitEconNoteTalabatCommissionEstimated =>
      'Talabat commission is estimated from your commission %.';

  @override
  String get rptUnitEconNoteBookedPartnerCommissionReplaced =>
      'Booked partner commission was replaced by the estimate so it is not counted twice.';

  @override
  String get rptUnitEconNoteBookedKashierFeesReplaced =>
      'Booked Kashier fees were replaced by the estimate so they are not counted twice.';

  @override
  String get rptUnitEconNoteStockAdjustmentInOther =>
      'Stock adjustments are included in other expenses.';

  @override
  String get rptUnitEconNoteCogsIncomplete =>
      'Cost of goods is incomplete: some items have no cost.';

  @override
  String get rptUnitEconNoteShippingExpenseIncomplete =>
      'Delivery expense is incomplete for this period.';

  @override
  String get rptUnitEconNoteRecurringNotFullyPosted =>
      'Some recurring expenses due in this period are not posted yet.';

  @override
  String get rptUnitEconNoteAdsAlsoBooked =>
      'Ads are also booked in the ledger; check they are not counted twice.';

  @override
  String get rptUnitEconNoteContributionNotPositive =>
      'Contribution is not positive, so there is no break-even point.';

  @override
  String get rptUnitEconBasisTitle => 'Calculation basis';

  @override
  String get rptUnitEconBasisSubtitle =>
      'Booked figures the estimates start from';

  @override
  String get rptUnitEconBasisKashierReceipts => 'Kashier receipts';

  @override
  String get rptUnitEconBasisTalabatSales => 'Talabat sales';

  @override
  String get rptUnitEconBasisTalabatOrders => 'Talabat orders';

  @override
  String get rptUnitEconBasisShippingIncome => 'Delivery income';

  @override
  String get rptUnitEconBasisShippingExpense => 'Delivery expense';

  @override
  String get rptUnitEconBasisStockAdjustment => 'Stock adjustment';

  @override
  String get rptUnitEconBasisBookedPartnerCommission =>
      'Booked partner commission';

  @override
  String get rptUnitEconBasisBookedKashierFees => 'Booked Kashier fees';

  @override
  String get rptUnitEconBasisRecurringDue => 'Recurring expenses due';

  @override
  String get rptUnitEconBasisCogsCoverage => 'Sales with a known cost';

  @override
  String get rptUnitEconBasisLedgerNetProfit => 'Net profit in the ledger';

  @override
  String get rptPromoConsumerOnly => 'Consumer orders only (B2B excluded)';

  @override
  String get rptPromoOrdersWithPromo => 'Orders with a code';

  @override
  String rptPromoShareOfOrders(String pct, String count) {
    return '$pct of $count consumer orders';
  }

  @override
  String get rptPromoDiscountTotal => 'Discount given';

  @override
  String get rptPromoRevenue => 'Revenue with codes';

  @override
  String get rptPromoAov => 'Avg order with code';

  @override
  String get rptPromoNonPromoAov => 'Avg order without code';

  @override
  String rptPromoAovDiff(String diff) {
    return '$diff vs no code';
  }

  @override
  String get rptPromoNewCustomers => 'New customers via codes';

  @override
  String get rptPromoCodesTitle => 'Codes';

  @override
  String get rptPromoCode => 'Code';

  @override
  String get rptPromoOrders => 'Orders';

  @override
  String get rptPromoDiscount => 'Discount';

  @override
  String get rptPromoRevenueShort => 'Revenue';

  @override
  String get rptPromoAovShort => 'Avg order';

  @override
  String get rptPromoNew => 'New customers';

  @override
  String get rptPromoRepeatAfter => 'Ordered again';

  @override
  String get rptPromoRepeatAfterHelp =>
      'Customers who ordered again later without a code';

  @override
  String get rptPromoDiscountRate => 'Discount as % of revenue';

  @override
  String get rptPromoChartTitle => 'Revenue and discount by code';

  @override
  String get rptPromoNoCodes => 'No codes were used in this period.';

  @override
  String get rptWasteLoss => 'Stock lost';

  @override
  String get rptWasteGain => 'Stock gained';

  @override
  String get rptWasteNet => 'Net';

  @override
  String get rptWasteEntriesCount => 'Entries';

  @override
  String get rptWasteByType => 'By type';

  @override
  String get rptWasteByBranch => 'By branch';

  @override
  String get rptWasteWorstItems => 'Biggest losses by item';

  @override
  String get rptWasteEntries => 'Latest entries';

  @override
  String get rptWasteItem => 'Item';

  @override
  String get rptWasteItemCode => 'Item code';

  @override
  String get rptWasteQty => 'Qty';

  @override
  String get rptWasteUom => 'Unit';

  @override
  String get rptWasteValue => 'Value';

  @override
  String get rptWasteDate => 'Date';

  @override
  String get rptWasteVoucher => 'Document';

  @override
  String get rptWasteWarehouse => 'Warehouse';

  @override
  String get rptWasteBranch => 'Branch';

  @override
  String get rptWasteType => 'Type';

  @override
  String get rptWasteRemarks => 'Remarks';

  @override
  String get rptWasteSignHint =>
      'Negative values are stock lost; positive values are stock found.';

  @override
  String get rptWasteTypeStockReconciliation => 'Stock count';

  @override
  String get rptWasteTypeMaterialIssue => 'Material issue (waste)';

  @override
  String get rptWasteTypeMaterialReceipt => 'Material receipt';

  @override
  String get rptWasteTypeStockEntry => 'Stock entry';

  @override
  String get rptLabourPctOfSales => 'Labour % of sales';

  @override
  String get rptLabourCost => 'Labour cost';

  @override
  String get rptLabourSales => 'Sales';

  @override
  String get rptLabourHours => 'Hours';

  @override
  String get rptLabourSalesPerHour => 'Sales per hour';

  @override
  String get rptLabourHeadcount => 'Headcount';

  @override
  String get rptLabourBasisSalarySlips => 'Based on salary slips';

  @override
  String get rptLabourBasisSalarySlipsHelp =>
      'Cost comes from salary slips, prorated to the selected period.';

  @override
  String get rptLabourBasisRecurring => 'Based on recurring salary expenses';

  @override
  String get rptLabourBasisRecurringHelp =>
      'No salary slips cover this period, so cost comes from recurring salary expenses, prorated.';

  @override
  String get rptLabourBasisEstimate => 'Estimated cost';

  @override
  String get rptLabourBasisEstimateHelp =>
      'No payroll was found for this period, so the cost is an estimate and may be off.';

  @override
  String get rptLabourByBranch => 'By branch';

  @override
  String get rptLabourBranch => 'Branch';

  @override
  String get rptLabourEmployees => 'Employees';

  @override
  String get rptLabourEmployee => 'Employee';

  @override
  String get rptLabourEmployeeId => 'Employee ID';

  @override
  String get rptLabourDays => 'Days';

  @override
  String get rptLabourCostPerHour => 'Cost per hour';

  @override
  String get rptLabourUnassigned => 'Unassigned';

  @override
  String get rptLabourChartTitle => 'Labour cost vs sales';

  @override
  String get rptG2ColumnStatus => 'Status';

  @override
  String get rptG2LastSale => 'Last sale';

  @override
  String get chatNavLabel => 'Chats';

  @override
  String get chatInboxTitle => 'Chats';

  @override
  String get chatNotAllowed =>
      'Your account does not have access to customer chats.';

  @override
  String get chatInboxLoadError => 'Couldn\'t load the chats.';

  @override
  String get chatInboxEmpty => 'No chats here yet.';

  @override
  String get chatInboxEmptySearch => 'No chats match your search.';

  @override
  String get chatSearchHint => 'Search by name or phone';

  @override
  String get chatLoadMore => 'Load more';

  @override
  String get chatLoadOlder => 'Load older messages';

  @override
  String get chatSegmentOpen => 'Open';

  @override
  String get chatSegmentMine => 'Mine';

  @override
  String get chatSegmentAll => 'All';

  @override
  String get chatSegmentClosed => 'Closed';

  @override
  String get chatChannelAll => 'All channels';

  @override
  String get chatChannelWhatsApp => 'WhatsApp';

  @override
  String get chatChannelMessenger => 'Messenger';

  @override
  String get chatChannelInstagram => 'Instagram';

  @override
  String get chatChannelFacebookComment => 'Facebook comment';

  @override
  String get chatChannelInstagramComment => 'Instagram comment';

  @override
  String get chatStatusOpen => 'Open';

  @override
  String get chatStatusAnswered => 'Answered';

  @override
  String get chatStatusClosed => 'Closed';

  @override
  String get chatIntentInquiry => 'Inquiry';

  @override
  String get chatIntentOrder => 'Order';

  @override
  String get chatIntentOther => 'Other';

  @override
  String get chatComplaintBadge => 'Complaint';

  @override
  String chatPreviewYou(String text) {
    return 'You: $text';
  }

  @override
  String chatWaitingMinutes(String minutes) {
    return 'Waiting $minutes min';
  }

  @override
  String get chatDraftReadyTooltip => 'An AI draft is ready';

  @override
  String chatAssignedTo(String name) {
    return 'Assigned to $name';
  }

  @override
  String get chatAssignedToYou => 'This chat is now assigned to you.';

  @override
  String chatSentBy(String name) {
    return 'Sent by $name';
  }

  @override
  String get chatSentBySystem => 'Sent automatically';

  @override
  String get chatSentFromPhone => 'Sent from the phone';

  @override
  String get chatMessageFailed => 'Not delivered';

  @override
  String get chatMessageImage => 'Photo';

  @override
  String get chatMessageAudio => 'Voice note';

  @override
  String get chatMessageVideo => 'Video';

  @override
  String get chatMessageDocument => 'Document';

  @override
  String get chatMessageSticker => 'Sticker';

  @override
  String get chatMessageLocation => 'Location';

  @override
  String get chatMessageReaction => 'Reaction';

  @override
  String get chatMessageTemplate => 'Template message';

  @override
  String get chatMessageUnsupported => 'Unsupported message';

  @override
  String get chatOpenInMaps => 'Open in Maps';

  @override
  String get chatOpenMedia => 'Open';

  @override
  String get chatMediaLoadFailed => 'Couldn\'t open the file.';

  @override
  String get chatMediaUnavailable => 'File not available';

  @override
  String get chatThreadLoadError => 'Couldn\'t load this chat.';

  @override
  String get chatWindowClosedBanner =>
      'The 24-hour reply window has closed. The customer may not receive a normal reply until they message again.';

  @override
  String get chatComposerHint => 'Type a reply';

  @override
  String get chatComposerSendTooltip => 'Send';

  @override
  String get chatActionAssignToMe => 'Assign to me';

  @override
  String get chatActionClose => 'Close chat';

  @override
  String get chatActionReopen => 'Reopen chat';

  @override
  String get chatActionCustomerCard => 'Customer card';

  @override
  String get chatActionLinkCustomer => 'Link to a customer';

  @override
  String get chatActionStartOrder => 'Start order';

  @override
  String get chatActionFailed => 'That didn\'t work. Please try again.';

  @override
  String get chatClosedDone => 'Chat closed.';

  @override
  String get chatReopenedDone => 'Chat reopened.';

  @override
  String get chatStartOrderNeedsCustomer =>
      'Link this chat to a customer first.';

  @override
  String get chatCustomerNotLinked =>
      'This chat is not linked to a customer yet.';

  @override
  String get chatCustomerPhone => 'Phone';

  @override
  String get chatCustomerTerritory => 'Area';

  @override
  String get chatCustomerTotalOrders => 'Total orders';

  @override
  String get chatCustomerLastOrder => 'Last order';

  @override
  String get chatCustomerLifetimeValue => 'Total spent';

  @override
  String get chatCustomerRecentItems => 'Recent items';

  @override
  String get chatLinkSearchHint => 'Search customers by name or phone';

  @override
  String get chatLinkNoResults => 'No customers found.';

  @override
  String get chatLinkSearchFailed => 'Customer search failed.';

  @override
  String chatLinkDone(String name) {
    return 'Linked to $name.';
  }

  @override
  String get chatDraftTitle => 'Suggested reply';

  @override
  String get chatDraftEditedLabel => 'Edited';

  @override
  String get chatDraftUnavailable => 'Draft unavailable — type your reply.';

  @override
  String chatDraftUpsell(String item) {
    return 'Add: $item';
  }

  @override
  String chatDraftNeedsHuman(String reason) {
    return 'Needs you: $reason';
  }

  @override
  String get chatDraftComplaintLock =>
      'This is a complaint. Edit the reply in your own words before sending.';

  @override
  String get chatDraftRegenerate => 'Regenerate';

  @override
  String get chatDraftReject => 'Reject';

  @override
  String get chatDraftEdit => 'Edit';

  @override
  String get chatDraftSend => 'Send';

  @override
  String get chatPlantedTitle => 'Training check';

  @override
  String chatPlantedNotSent(String error) {
    return 'Training check — this draft had a deliberate mistake: $error. It was not sent.';
  }

  @override
  String get chatPlantedNotSentNoDetail =>
      'Training check — this draft had a deliberate mistake. It was not sent.';

  @override
  String chatPlantedCaught(String error) {
    return 'Well spotted — this draft had a deliberate mistake: $error. You fixed it, and your reply was sent.';
  }

  @override
  String get chatPlantedCaughtNoDetail =>
      'Well spotted — this draft had a deliberate mistake. You fixed it, and your reply was sent.';

  @override
  String chatPlantedMissed(String error) {
    return 'Training check — this draft had a deliberate mistake: $error. Your edited reply was sent with it, so please send the customer a correction.';
  }

  @override
  String get chatPlantedMissedNoDetail =>
      'Training check — this draft had a deliberate mistake. Your edited reply was sent with it, so please send the customer a correction.';

  @override
  String get chatPlantedRealDraftReady => 'The real draft is ready below.';

  @override
  String get chatRejectTitle => 'Why are you rejecting this draft?';

  @override
  String get chatRejectChooseReason => 'Choose a reason.';

  @override
  String get chatRejectReasonWrongInfo => 'Wrong information';

  @override
  String get chatRejectReasonWrongPrice => 'Wrong price or number';

  @override
  String get chatRejectReasonTone => 'Wrong tone';

  @override
  String get chatRejectReasonOffTopic => 'Does not answer the customer';

  @override
  String get chatRejectReasonUpsell => 'Bad upsell suggestion';

  @override
  String get chatRejectReasonOther => 'Other';

  @override
  String get chatRejectNoteHint => 'Add a note (optional)';

  @override
  String get chatRejectNoteRequired => 'Please describe the reason.';

  @override
  String get chatRejectConfirm => 'Reject draft';

  @override
  String get chatRejectCaught =>
      'Well spotted — that draft was a training check with a deliberate mistake.';

  @override
  String get chatRegenerateTitle => 'Regenerate the draft';

  @override
  String get chatRegenerateHintLabel => 'Hint for the new draft (optional)';

  @override
  String get chatRegenerateHintExample => 'e.g. mention free delivery';

  @override
  String get chatMetricsTitle => 'Chat metrics';

  @override
  String get chatMetricsNotAllowed => 'Chat metrics are for managers only.';

  @override
  String get chatMetricsLoadError => 'Couldn\'t load the chat metrics.';

  @override
  String get chatMetricsConversations => 'Conversations';

  @override
  String get chatMetricsInbound => 'Messages received';

  @override
  String get chatMetricsOutbound => 'Messages sent';

  @override
  String get chatMetricsMedianFirstResponse => 'Median first response';

  @override
  String chatMetricsMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get chatMetricsUnansweredOpen => 'Open, unanswered';

  @override
  String get chatMetricsWaitingOverAlert => 'Waiting too long';

  @override
  String get chatMetricsDrafts => 'AI drafts';

  @override
  String get chatMetricsTotal => 'Total';

  @override
  String get chatMetricsAsIsRate => 'Sent as-is';

  @override
  String get chatMetricsSentAsIs => 'Sent unchanged';

  @override
  String get chatMetricsSentEdited => 'Sent edited';

  @override
  String get chatMetricsRejected => 'Rejected';

  @override
  String get chatMetricsSuperseded => 'Superseded';

  @override
  String get chatMetricsBlocked => 'Blocked';

  @override
  String get chatMetricsPlanted => 'Training checks caught';

  @override
  String chatMetricsPlantedValue(String caught, String total) {
    return '$caught of $total';
  }

  @override
  String get chatMetricsCost => 'AI cost';

  @override
  String get chatMetricsByModerator => 'By moderator';

  @override
  String get chatMetricsNoModerators => 'No replies in this period.';

  @override
  String get chatMetricsModerator => 'Moderator';

  @override
  String get chatMetricsModSent => 'Sent';

  @override
  String get chatMetricsModAsIs => 'As-is';

  @override
  String get chatMetricsModEdited => 'Edited';

  @override
  String get rptRevenueDashboardTitle => 'Revenue Dashboard';

  @override
  String get rptRevenueDashboardSubtitle =>
      'Today vs the same day last week, and what needs attention';

  @override
  String get rptRevAtAGlance => 'At a glance';

  @override
  String get rptRevToday => 'Today';

  @override
  String get rptRevYesterday => 'Yesterday';

  @override
  String get rptRevLast7Days => 'Last 7 days';

  @override
  String get rptRevMonthToDate => 'Month to date';

  @override
  String get rptRevCustom => 'Custom';

  @override
  String get rptRevB2c => 'B2C';

  @override
  String get rptRevB2b => 'B2B';

  @override
  String get rptRevOther => 'Other (staff, samples)';

  @override
  String get rptRevColB2c => 'B2C';

  @override
  String get rptRevColB2b => 'B2B';

  @override
  String get rptRevColNet => 'Net';

  @override
  String get rptRevNetSales => 'Net sales';

  @override
  String get rptRevAverageOrder => 'Average order';

  @override
  String rptRevVsPeriod(String period) {
    return 'vs $period';
  }

  @override
  String rptRevVsPeriodUpTo(String period, String time) {
    return 'vs $period up to $time';
  }

  @override
  String rptRevCaptionB2c(String amount) {
    return 'B2C $amount';
  }

  @override
  String rptRevCaptionB2b(String amount) {
    return 'B2B $amount';
  }

  @override
  String rptRevNewCustomersCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString new customers',
      one: '1 new customer',
    );
    return '$_temp0';
  }

  @override
  String rptRevDeliveryPickup(String delivery, String pickup) {
    return '$delivery delivery / $pickup pickup';
  }

  @override
  String rptRevDiscountsAmount(String amount) {
    return 'Discounts $amount';
  }

  @override
  String rptRevReturnsAmount(String amount) {
    return 'Returns $amount';
  }

  @override
  String rptRevCancelledShort(String count) {
    return 'Cancelled $count';
  }

  @override
  String rptRevTotalInclShipping(String amount) {
    return 'Total incl. shipping $amount';
  }

  @override
  String rptRevB2cInclShipping(String amount) {
    return 'incl. shipping $amount';
  }

  @override
  String rptRevDailyAverageAmount(String amount) {
    return 'Daily average $amount';
  }

  @override
  String rptRevBestDayOn(String day, String amount) {
    return 'Best $day $amount';
  }

  @override
  String rptRevWorstDayOn(String day, String amount) {
    return 'Worst $day $amount';
  }

  @override
  String get rptRevDeliveryFees => 'Delivery fees';

  @override
  String get rptRevDailyAverage => 'Daily average';

  @override
  String get rptRevReturns => 'Returns';

  @override
  String get rptRevCancelled => 'Cancelled';

  @override
  String get rptRevDiscounts => 'Discounts';

  @override
  String get rptRevNeedsAttention => 'Needs attention';

  @override
  String get rptRevNothingNeedsAttention => 'Nothing needs attention';

  @override
  String rptRevAttnCancelled(int count, String amount) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString cancelled orders',
      one: '1 cancelled order',
    );
    return '$_temp0 · $amount';
  }

  @override
  String rptRevAttnReturns(int count, String amount) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString returns',
      one: '1 return',
    );
    return '$_temp0 · $amount';
  }

  @override
  String rptRevAttnBranchDrop(
    String name,
    String pct,
    String amount,
    String compare,
  ) {
    return '$name B2C down $pct% ($amount vs $compare)';
  }

  @override
  String rptRevAttnSourceDrop(
    String name,
    String pct,
    String amount,
    String compare,
  ) {
    return '$name down $pct% ($amount vs $compare)';
  }

  @override
  String rptRevAttnDiscountHigh(String amount, String pct, String compare) {
    return 'Discounts $amount = $pct% of sales (vs $compare%)';
  }

  @override
  String get rptRevWhereFrom => 'Where it came from';

  @override
  String get rptRevBySourceTitle => 'By source';

  @override
  String get rptRevSourcePos => 'POS / phone';

  @override
  String get rptRevSourceWoo => 'Website';

  @override
  String get rptRevSourceTalabat => 'Talabat';

  @override
  String get rptRevSourcePartner => 'Partner';

  @override
  String get rptRevSourceStaff => 'Staff';

  @override
  String get rptRevSourceSamples => 'Samples';

  @override
  String get rptRevByPaymentTitle => 'By payment method';

  @override
  String get rptRevByBranchTitle => 'By branch';

  @override
  String get rptRevNoProfile => 'No branch';

  @override
  String get rptRevByHour => 'By hour';

  @override
  String get rptRevByHourSubtitle => 'Net sales per hour';

  @override
  String rptRevHourTooltip(String hour, String orders, String amount) {
    return '$hour:00 · $orders orders · $amount';
  }

  @override
  String get rptRevLinkProducts => 'Products';

  @override
  String get rptRevLinkB2b => 'B2B clients';

  @override
  String rptRevUpdatedAt(String time) {
    return 'Updated $time';
  }

  @override
  String get rptRevBranchCashTitle => 'Cash in branches now';

  @override
  String get rptRevBranchCashError => 'Could not load branch cash';

  @override
  String get rptRevBranchCashDrawer => 'In drawer';

  @override
  String get rptRevBranchCashCouriers => 'With couriers';

  @override
  String get managerBarOrders => 'Orders';

  @override
  String get managerBarProducts => 'Products';

  @override
  String get managerBarMore => 'More';

  @override
  String get stockHandoverTabHandovers => 'Handovers';

  @override
  String get stockHandoverTabTransfer => 'Full transfer';

  @override
  String get stockHandoverNoAccess =>
      'Open a shift on your branch to record stock handovers.';

  @override
  String stockHandoverLoadFailed(String reason) {
    return 'Could not load handovers: $reason';
  }

  @override
  String stockHandoverWaitingForYou(int count) {
    return 'Waiting for you ($count)';
  }

  @override
  String stockHandoverWaitingForThem(int count) {
    return 'Waiting for them ($count)';
  }

  @override
  String stockHandoverRecent(int count) {
    return 'Recent ($count)';
  }

  @override
  String get stockHandoverNothingWaiting => 'Nothing is waiting for you.';

  @override
  String stockHandoverRoute(String source, String target) {
    return '$source → $target';
  }

  @override
  String stockHandoverDeclaredBy(String name, String time) {
    return 'Declared by $name · $time';
  }

  @override
  String stockHandoverChangedBy(String name, String time) {
    return 'Changed by $name · $time';
  }

  @override
  String stockHandoverAwaiting(String side) {
    return 'Waiting for $side';
  }

  @override
  String get stockHandoverChangedBadge => 'Changed';

  @override
  String get stockHandoverStatusPending => 'Pending';

  @override
  String get stockHandoverStatusConfirmed => 'Confirmed';

  @override
  String get stockHandoverStatusRejected => 'Rejected';

  @override
  String get stockHandoverStatusCancelled => 'Cancelled';

  @override
  String stockHandoverReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String stockHandoverEntry(String entry) {
    return 'Entry $entry';
  }

  @override
  String get stockHandoverConfirm => 'Confirm';

  @override
  String get stockHandoverChange => 'Change';

  @override
  String get stockHandoverReject => 'Reject';

  @override
  String get stockHandoverCancel => 'Cancel handover';

  @override
  String get stockHandoverConfirmTitle => 'Confirm this handover?';

  @override
  String stockHandoverConfirmBody(String source, String target) {
    return 'The stock moves from $source to $target now.';
  }

  @override
  String get stockHandoverRejectTitle => 'Reject this handover?';

  @override
  String get stockHandoverRejectReasonHint => 'Reason (optional)';

  @override
  String get stockHandoverCancelTitle => 'Cancel this handover?';

  @override
  String get stockHandoverCancelBody =>
      'Nothing has moved yet. The other side will no longer be asked to confirm it.';

  @override
  String get stockHandoverKeep => 'Keep it';

  @override
  String stockHandoverConfirmedSnack(String entry) {
    return 'Confirmed. Stock moved ($entry).';
  }

  @override
  String get stockHandoverRejectedSnack => 'Handover rejected.';

  @override
  String get stockHandoverCancelledSnack => 'Handover cancelled.';

  @override
  String stockHandoverSentSnack(String side) {
    return 'Sent. Waiting for $side to confirm.';
  }

  @override
  String get stockHandoverActingAs => 'You are';

  @override
  String get stockHandoverIReceived => 'I received';

  @override
  String get stockHandoverFromWhom => 'Received from whom?';

  @override
  String get stockHandoverNoCounterparts =>
      'There is nobody to hand stock to or from.';

  @override
  String get stockHandoverItemsTitle => 'Add items';

  @override
  String get stockHandoverEditTitle => 'Change quantities';

  @override
  String stockHandoverReviewButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Review ($count items)',
      one: 'Review (1 item)',
      zero: 'Review',
    );
    return '$_temp0';
  }

  @override
  String get stockHandoverNoItems => 'No items to declare between these two.';

  @override
  String get stockHandoverReviewTitle => 'Review';

  @override
  String stockHandoverReviewReceived(String name) {
    return 'You received from $name:';
  }

  @override
  String stockHandoverReviewChange(String source, String target) {
    return 'Correct quantities, $source → $target:';
  }

  @override
  String stockHandoverReviewTotal(String qty) {
    return 'Total: $qty';
  }

  @override
  String get stockHandoverReviewHint =>
      'Nothing moves until the other side confirms.';

  @override
  String get stockHandoverBack => 'Back';

  @override
  String get stockHandoverSend => 'Confirm and send';

  @override
  String get stockHandoverDiscardTitle => 'Discard the quantities you entered?';

  @override
  String get stockHandoverDiscard => 'Discard';

  @override
  String get stockHandoverKeepEditing => 'Keep editing';

  @override
  String get stockHandoverISentOut => 'I sent out';

  @override
  String get stockHandoverReviewSentOut => 'You sent out:';

  @override
  String stockHandoverReviewHintSentOut(String side) {
    return 'This stock leaves $side now and goes to In Transit. A manager matches it with the branches that receive it.';
  }

  @override
  String get stockHandoverSentOutSnack =>
      'Sent out. The stock is now In Transit.';

  @override
  String get stockHandoverNoChangeHint => 'No change. Confirm it instead.';

  @override
  String stockHandoverDispatchTitle(String source) {
    return '$source sent out';
  }

  @override
  String get stockHandoverDispatchWaiting =>
      'In transit · waiting for a manager to match';

  @override
  String get stockHandoverGroupWaiting => 'Waiting for a manager to match';

  @override
  String get stockHandoverUnknownSender => 'I don\'t know who sent it';

  @override
  String get stockHandoverUnknownSenderHint =>
      'A manager matches it with what was sent';

  @override
  String get stockHandoverUnknownSenderLabel => 'Unknown sender';

  @override
  String get stockHandoverReviewReceivedUnknown =>
      'You received (sender unknown):';

  @override
  String get stockHandoverReviewHintUnknown =>
      'A manager matches it with what was sent. Nothing moves until then.';

  @override
  String get stockHandoverSentToManagerSnack =>
      'Sent. Waiting for a manager to match.';

  @override
  String get stockTransitEntryTitle => 'Transit';

  @override
  String stockTransitEntryToApprove(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count to approve',
      one: '1 to approve',
      zero: 'Nothing to approve',
    );
    return '$_temp0';
  }

  @override
  String get stockTransitEntrySubtitle =>
      'Match what was sent with what arrived';

  @override
  String get stockTransitTitle => 'Transit';

  @override
  String get stockTransitSummaryToApprove => 'To approve';

  @override
  String get stockTransitSummaryUnits => 'Units in transit';

  @override
  String get stockTransitSummaryOverdue => 'Overdue sends';

  @override
  String stockTransitSectionToApprove(int count) {
    return 'To approve ($count)';
  }

  @override
  String stockTransitSectionInTransit(int count) {
    return 'In transit ($count)';
  }

  @override
  String get stockTransitNothingToApprove => 'Nothing waiting for approval.';

  @override
  String get stockTransitNothingInTransit => 'Nothing is in transit.';

  @override
  String stockTransitReceivedBy(String target) {
    return '$target received';
  }

  @override
  String stockTransitNamedChip(String source) {
    return 'Says from $source';
  }

  @override
  String get stockTransitUnknownChip => 'Sender unknown';

  @override
  String stockTransitUnresolved(String qty) {
    return '$qty with no source';
  }

  @override
  String stockTransitLeftToAssign(String qty) {
    return 'Left to assign: $qty';
  }

  @override
  String stockTransitOverAssigned(String qty) {
    return '$qty too many assigned';
  }

  @override
  String get stockTransitAllAssigned => 'All assigned';

  @override
  String get stockTransitTapToChoose => 'Tap to choose where it came from';

  @override
  String get stockTransitEditedByYou => 'Set by you';

  @override
  String stockTransitReceivedChanged(String was, String now) {
    return 'Received $was → $now';
  }

  @override
  String stockTransitReasonExact(String source, String qty) {
    return 'Exact match — $source sent $qty';
  }

  @override
  String stockTransitReasonOnlySender(String source) {
    return 'Only $source sent this';
  }

  @override
  String get stockTransitReasonSameShipment =>
      'Same shipment as the other items';

  @override
  String get stockTransitReasonSentBefore => 'Sent before it was received';

  @override
  String get stockTransitReasonSentAfter =>
      'Sent after it was received — check';

  @override
  String stockTransitReasonUsual(String source, String percent) {
    return 'Usually from $source ($percent%)';
  }

  @override
  String stockTransitReasonNamed(String source) {
    return 'The receiver said it came from $source';
  }

  @override
  String get stockTransitReasonSplit => 'Split across several sends';

  @override
  String get stockTransitReasonNoSend =>
      'Nobody declared sending this — check the sender';

  @override
  String get stockTransitConfidenceHigh => 'Confident';

  @override
  String get stockTransitConfidenceMedium => 'Likely';

  @override
  String get stockTransitConfidenceLow => 'Check';

  @override
  String get stockTransitApprove => 'Approve';

  @override
  String get stockTransitCannotApproveOwn =>
      'You declared this receipt. Another manager must approve it.';

  @override
  String stockTransitApprovedSnack(String target, String entry) {
    return 'Approved. Stock moved to $target ($entry).';
  }

  @override
  String stockTransitRejectTitle(String target) {
    return 'Reject what $target received?';
  }

  @override
  String get stockTransitRejectBody =>
      'Nothing moves. The receiver sees it was rejected.';

  @override
  String get stockTransitReasonRequiredHint => 'Reason (required)';

  @override
  String get stockTransitRejectedSnack => 'Receipt rejected.';

  @override
  String get stockTransitDriftSnack =>
      'Something changed meanwhile. The board was reloaded — check again.';

  @override
  String get stockTransitApproveConfident => 'Approve all confident';

  @override
  String get stockTransitApproveConfidentNone =>
      'No receipt is fully confident yet.';

  @override
  String stockTransitApproveConfidentTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Approve $count confident receipts?',
      one: 'Approve 1 confident receipt?',
    );
    return '$_temp0';
  }

  @override
  String get stockTransitApproveConfidentBody =>
      'Every line below has one sure source. Each receipt is approved on its own.';

  @override
  String stockTransitApproveConfidentButton(int count) {
    return 'Approve $count';
  }

  @override
  String stockTransitApproveConfidentDone(int ok, int failed) {
    return '$ok approved, $failed not approved';
  }

  @override
  String stockTransitApproveConfidentChanged(String receipt) {
    return '$receipt changed meanwhile — left for you to check';
  }

  @override
  String stockTransitSheetTitle(String item) {
    return '$item — where did it come from?';
  }

  @override
  String get stockTransitActuallyReceived => 'Actually received';

  @override
  String stockTransitDeclaredQty(String qty) {
    return 'Declared $qty';
  }

  @override
  String get stockTransitOpenSends => 'Sends in transit';

  @override
  String stockTransitSendLeft(String qty) {
    return '$qty left';
  }

  @override
  String stockTransitReservedElsewhere(String qty) {
    return '$qty suggested for other receipts';
  }

  @override
  String get stockTransitOverRemaining => 'More than this send has left';

  @override
  String get stockTransitNoOpenSends => 'Nobody has this item in transit.';

  @override
  String get stockTransitNotDeclared => 'Sender didn\'t declare it';

  @override
  String get stockTransitAddNotDeclared =>
      'Sender didn\'t declare it — pick who sent it';

  @override
  String get stockTransitPickSender => 'Who sent it?';

  @override
  String get stockTransitNoSenders => 'There is no other side to pick.';

  @override
  String get stockTransitFillRest => 'Fill the rest';

  @override
  String get stockTransitResetSuggestion => 'Back to suggestion';

  @override
  String get stockTransitSuggested => 'Suggested';

  @override
  String get stockTransitDone => 'Done';

  @override
  String get stockTransitRemove => 'Remove';

  @override
  String stockTransitAgeHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours in transit',
      one: '1 hour in transit',
      zero: 'Just now',
    );
    return '$_temp0';
  }

  @override
  String stockTransitAgeDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days in transit',
      one: '1 day in transit',
    );
    return '$_temp0';
  }

  @override
  String get stockTransitOverdue => 'Overdue';

  @override
  String stockTransitLeftOf(String left, String total) {
    return '$left of $total left';
  }

  @override
  String get stockTransitReturn => 'Return to sender';

  @override
  String get stockTransitWriteOff => 'Write off';

  @override
  String stockTransitReturnTitle(String source) {
    return 'Return to $source';
  }

  @override
  String stockTransitReturnBody(String source) {
    return 'These units go back into $source\'s stock.';
  }

  @override
  String stockTransitWriteOffTitle(String source) {
    return 'Write off from $source\'s send';
  }

  @override
  String get stockTransitWriteOffBody =>
      'These units are recorded as lost. This can\'t be undone.';

  @override
  String stockTransitWriteOffConfirmTitle(String qty) {
    return 'Write off $qty units as lost?';
  }

  @override
  String stockTransitReturnConfirm(String qty) {
    return 'Return $qty';
  }

  @override
  String stockTransitWriteOffConfirm(String qty) {
    return 'Write off $qty';
  }

  @override
  String stockTransitReturnedSnack(String source) {
    return 'Returned to $source.';
  }

  @override
  String get stockTransitWrittenOffSnack => 'Written off.';

  @override
  String get stockTransitCannotActOwn =>
      'You sent this. Another manager must return or write it off.';

  @override
  String stockTransitSentBy(String name, String time) {
    return 'Sent by $name · $time';
  }

  @override
  String get userErrorHandoverRule => 'This handover can\'t go through yet.';

  @override
  String get stockTransferBecomesOfficialNote =>
      'Becomes official when the other side confirms; posted at that moment.';

  @override
  String get stockTransferPostDirectTitle => 'Post now (no confirmation)';

  @override
  String get stockTransferPostDirectSubtitle =>
      'Stock moves immediately; the branch does not need to confirm.';

  @override
  String stockTransferSentPending(String handover) {
    return 'Sent. Waiting for the other side to confirm ($handover).';
  }

  @override
  String replenishmentSentPendingBody(
    int lineCount,
    String totalQty,
    String name,
    String handover,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      lineCount,
      locale: localeName,
      other: '$lineCount lines',
      one: '1 line',
    );
    return '$_temp0 · $totalQty units · waiting for $name to confirm ($handover)';
  }

  @override
  String get menuWeeklyCount => 'Weekly count';

  @override
  String get menuWeeklyCountApprovals => 'Count approvals';

  @override
  String get approvalsQueueBranchCounts => 'Weekly counts to approve';

  @override
  String get weeklyCountTitle => 'Weekly count';

  @override
  String get weeklyCountApprovalsTitle => 'Count approvals';

  @override
  String get weeklyCountDetailTitle => 'Count review';

  @override
  String get weeklyCountLoadError => 'Could not load the weekly count';

  @override
  String get weeklyCountNoBranches => 'You have no branch to count';

  @override
  String get weeklyCountPickBranch => 'Choose the branch';

  @override
  String get weeklyCountOtherBranches => 'Other branches';

  @override
  String get weeklyCountChangeBranch => 'Change branch';

  @override
  String weeklyCountWeekRange(String start, String end) {
    return 'Week $start – $end';
  }

  @override
  String get weeklyCountStateDue => 'Count due';

  @override
  String get weeklyCountStatePending => 'Waiting for manager approval';

  @override
  String get weeklyCountStateDone => 'Counted this week ✓';

  @override
  String get weeklyCountStateRejected => 'Count rejected — count again';

  @override
  String weeklyCountCountedBy(String name, String time) {
    return 'Counted by $name · $time';
  }

  @override
  String weeklyCountApprovedBy(String name) {
    return 'Approved by $name';
  }

  @override
  String weeklyCountRejectionReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get weeklyCountRecount => 'Count again';

  @override
  String get weeklyCountReviewButton => 'Review the count';

  @override
  String weeklyCountProgress(int counted, int total) {
    return '$counted / $total counted';
  }

  @override
  String get weeklyCountSectionLarge => 'Large';

  @override
  String get weeklyCountSectionMedium => 'Medium';

  @override
  String get weeklyCountSectionSmall => 'Small';

  @override
  String get weeklyCountLabelsHeading => 'B2B labels';

  @override
  String get weeklyCountAllZero => 'All zero';

  @override
  String get weeklyCountAllZeroTitle => 'Set to zero?';

  @override
  String weeklyCountAllZeroBody(int count, String section) {
    return '$count items not counted yet in $section will be set to 0. Items you already counted stay as they are.';
  }

  @override
  String get weeklyCountAllZeroNothing =>
      'Every item in this section is already counted';

  @override
  String get weeklyCountUncounted => 'Not counted';

  @override
  String get weeklyCountSubmit => 'Submit count';

  @override
  String weeklyCountFinishFirst(int count) {
    return 'Count every item first — $count left';
  }

  @override
  String get weeklyCountEmptySheet =>
      'There are no items to count in this branch';

  @override
  String get weeklyCountKeypadClear => 'Clear';

  @override
  String get weeklyCountKeypadUncount => 'Not counted';

  @override
  String get weeklyCountSubmitConfirmTitle => 'Submit the count?';

  @override
  String weeklyCountSubmitConfirmSummary(String branch, int count) {
    return '$branch · $count items counted';
  }

  @override
  String get weeklyCountSubmitConfirmApprover =>
      'Stock will be updated immediately';

  @override
  String get weeklyCountSubmitConfirmStaff =>
      'It will be sent to the manager for approval';

  @override
  String get weeklyCountSubmitConfirmButton => 'Send';

  @override
  String get weeklyCountDoneTitle => 'Count sent';

  @override
  String get weeklyCountDonePosted => 'Stock updated';

  @override
  String get weeklyCountBackHome => 'Back to home';

  @override
  String weeklyCountBannerDue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
    );
    return 'Weekly count due — $_temp0';
  }

  @override
  String get weeklyCountBannerLastDay =>
      'Weekly count due — today is the last day';

  @override
  String get weeklyCountBannerRejected => 'Weekly count rejected — count again';

  @override
  String get weeklyCountErrMissingItems =>
      'Not every item was counted. The list was refreshed; count the missing items.';

  @override
  String get weeklyCountErrUnknownItems =>
      'Some items are no longer on this branch list. The list was refreshed.';

  @override
  String get weeklyCountErrInvalidQty =>
      'Invalid quantity. Use whole numbers from 0 up.';

  @override
  String get weeklyCountErrAlreadyPending =>
      'A count for this branch is already waiting for manager approval.';

  @override
  String get weeklyCountErrAlreadyDone =>
      'This branch is already counted this week.';

  @override
  String get weeklyCountErrNoAccess => 'You do not have access to this branch.';

  @override
  String get weeklyCountErrNoWarehouse =>
      'This branch has no warehouse. Contact the manager.';

  @override
  String get weeklyCountErrReasonRequired => 'Write the reason for rejecting.';

  @override
  String get weeklyCountErrNotPending =>
      'This count has already been reviewed.';

  @override
  String get weeklyCountErrNotFound => 'Count not found.';

  @override
  String get weeklyCountErrPostFailed =>
      'The count could not be posted. Try again or contact the manager.';

  @override
  String get weeklyCountErrNoItems =>
      'There are no items to count in this branch.';

  @override
  String get weeklyCountErrOwnCount =>
      'You cannot review your own count. Another manager reviews it.';

  @override
  String get weeklyCountApprovalsPending => 'Waiting for approval';

  @override
  String get weeklyCountApprovalsNonePending =>
      'No count is waiting for approval';

  @override
  String get weeklyCountApprovalsHistory => 'Recent counts';

  @override
  String get weeklyCountApprovalsNoHistory => 'No earlier counts';

  @override
  String get weeklyCountApproverOnly =>
      'Only line managers and above approve weekly counts';

  @override
  String weeklyCountDifferences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count differences',
      one: '1 difference',
      zero: 'No differences',
    );
    return '$_temp0';
  }

  @override
  String weeklyCountItemsCount(int count) {
    return '$count items';
  }

  @override
  String get weeklyCountStatusPendingApproval => 'Pending approval';

  @override
  String get weeklyCountStatusApproved => 'Approved';

  @override
  String get weeklyCountStatusRejected => 'Rejected';

  @override
  String get weeklyCountStatusCancelled => 'Cancelled';

  @override
  String get weeklyCountColCounted => 'Counted';

  @override
  String get weeklyCountColSystem => 'System';

  @override
  String get weeklyCountColDifference => 'Difference';

  @override
  String weeklyCountNoDifference(int count) {
    return 'No difference ($count)';
  }

  @override
  String get weeklyCountApprove => 'Approve';

  @override
  String get weeklyCountReject => 'Reject';

  @override
  String get weeklyCountApproveTitle => 'Approve the count?';

  @override
  String get weeklyCountApproveBody =>
      'Stock will be adjusted by the differences';

  @override
  String get weeklyCountRejectTitle => 'Reject the count';

  @override
  String get weeklyCountRejectHint => 'Reason (required)';

  @override
  String get weeklyCountRejectQuickCareful => 'Count again carefully';

  @override
  String get weeklyCountRejectQuickUnreasonable =>
      'The numbers do not make sense';

  @override
  String get weeklyCountRejectQuickSizes =>
      'Check the sizes (large / medium / small)';

  @override
  String get weeklyCountApprovedToast => 'Count approved';

  @override
  String get weeklyCountRejectedToast => 'Count rejected';

  @override
  String get rosterFilterAll => 'All';

  @override
  String get rosterFilterTooltip => 'Filter by branch or person';

  @override
  String get rosterFilterTitle => 'Show on the roster';

  @override
  String get rosterFilterHelp =>
      'Nothing selected shows everyone. A person shows if you picked them or one of their branches.';

  @override
  String get rosterFilterBranches => 'Branches';

  @override
  String get rosterFilterPeople => 'People';

  @override
  String get rosterFilterSelectAll => 'Select all';

  @override
  String get rosterFilterSearchHint => 'Search people';

  @override
  String get rosterFilterNoPeople => 'No one matches';

  @override
  String get rosterFilterApply => 'Apply';

  @override
  String rosterFilterBranchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count branches',
      one: '1 branch',
    );
    return '$_temp0';
  }

  @override
  String rosterFilterPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String rosterFilterPeopleAndBranches(String people, String branches) {
    return '$people + $branches';
  }

  @override
  String get rosterFilterNoMatch => 'No one on the roster matches this filter';

  @override
  String get attendanceCheckoutCorrected =>
      'Pressed Check Out on arrival — counted as Check In';

  @override
  String get attendanceMissedCheckout => 'No check-out';

  @override
  String attendanceLogTypeNote(String note) {
    return 'Note: $note';
  }

  @override
  String attendanceOriginalLogType(String original) {
    return 'Pressed $original, counted differently';
  }

  @override
  String get attendanceApproveDevice => 'Approve this phone';

  @override
  String get attendanceApproveDeviceConfirmTitle => 'Approve this phone?';

  @override
  String attendanceApproveDeviceConfirmBody(String name) {
    return 'This phone becomes $name’s own device and the New Device warning is cleared.';
  }

  @override
  String attendanceApproveDeviceDone(String name) {
    return 'Phone approved for $name';
  }

  @override
  String attendanceApproveDeviceFailed(String error) {
    return 'Could not approve the phone: $error';
  }

  @override
  String get followupsWrittenByClaude => 'Written by Claude';

  @override
  String get followupsActionRewrite => 'Rewrite';

  @override
  String get followupsActionBrief => 'Brief before call';

  @override
  String get followupsBriefLoading => 'Preparing the brief...';

  @override
  String get followupsBriefRefresh => 'Refresh the brief';

  @override
  String get followupsBriefFailed => 'Could not load the brief';

  @override
  String get followupsBriefEmpty => 'No brief available for this customer.';

  @override
  String get followupResultsTitle => 'Follow-up results';

  @override
  String get followupResultsRange7 => '7 days';

  @override
  String get followupResultsRange30 => '30 days';

  @override
  String get followupResultsRangeMonth => 'This month';

  @override
  String get followupResultsRangeCustom => 'Custom';

  @override
  String get followupResultsRangePickerHelp => 'Choose the period';

  @override
  String get followupResultsTabOverview => 'Overview';

  @override
  String get followupResultsTabMessages => 'Messages';

  @override
  String get followupResultsTabReplies => 'Replies';

  @override
  String get followupResultsTabOrders => 'Orders';

  @override
  String get followupResultsTabCalls => 'Calls';

  @override
  String get followupResultsCostTitle => 'Cost vs. orders';

  @override
  String get followupResultsTotalCost => 'Total cost';

  @override
  String get followupResultsMessagesCost => 'Messages';

  @override
  String followupResultsMessagesCostDetail(String count, String each) {
    return '$count × $each';
  }

  @override
  String get followupResultsDiscountsCost => 'Discounts given';

  @override
  String get followupResultsOrders => 'Orders';

  @override
  String get followupResultsRevenue => 'Revenue';

  @override
  String get followupResultsNet => 'Net';

  @override
  String get followupResultsRoi => 'Return';

  @override
  String followupResultsRoiValue(String value) {
    return '×$value';
  }

  @override
  String get followupResultsCostPerOrder => 'Cost per order';

  @override
  String followupResultsOrdersWithCode(String count, String amount) {
    return 'Orders that used a code: $count ($amount)';
  }

  @override
  String get followupResultsCostNote =>
      'Orders counted are those placed within 30 days after a message. The cost of each message comes from Follow-up Settings.';

  @override
  String followupResultsCustomers(String count) {
    return '$count customers messaged';
  }

  @override
  String get followupResultsFunnelTitle => 'From message to order';

  @override
  String get followupResultsReplied => 'Replied';

  @override
  String get followupResultsOrdered => 'Ordered';

  @override
  String get followupResultsCodesTitle => 'Codes';

  @override
  String get followupResultsCodesIssued => 'Issued';

  @override
  String get followupResultsCodesUsed => 'Used';

  @override
  String get followupResultsCodesUnused => 'Not used yet';

  @override
  String get followupResultsCodesExpired => 'Expired';

  @override
  String get followupResultsAttentionTitle => 'Worth a look';

  @override
  String get followupResultsSearchHint => 'Name, phone, code or invoice';

  @override
  String get followupResultsFilterStep => 'Step';

  @override
  String get followupResultsFilterStatus => 'Status';

  @override
  String get followupResultsFilterOutcome => 'Result';

  @override
  String get followupResultsOutcomeUsedCode => 'Used the code';

  @override
  String get followupResultsOutcomeNoResponse => 'No response';

  @override
  String get followupResultsClearFilters => 'Clear filters';

  @override
  String followupResultsCountLine(String shown, String total) {
    return '$shown of $total messages';
  }

  @override
  String followupResultsTruncated(String shown, String total) {
    return 'Showing the latest $shown of $total messages. Narrow the dates to see the rest.';
  }

  @override
  String get followupResultsMessagesEmpty => 'No messages match';

  @override
  String get followupResultsRepliesEmpty => 'No replies in this period';

  @override
  String get followupResultsOrdersEmpty =>
      'No orders followed the messages in this period';

  @override
  String get followupResultsCodeUsed => 'Used';

  @override
  String get followupResultsCodeUnused => 'Not used';

  @override
  String get followupResultsCodeExpired => 'Expired';

  @override
  String get followupResultsTierVip => 'VIP';

  @override
  String get followupResultsTierLoyal => 'Loyal';

  @override
  String get followupResultsTierRepeat => 'Repeat';

  @override
  String get followupResultsTierOneBig => 'One big order';

  @override
  String get followupResultsTierOne => 'One order';

  @override
  String get followupResultsReplyImage => '[image]';

  @override
  String get followupResultsReplyVoice => '[voice note]';

  @override
  String get followupResultsReplyVideo => '[video]';

  @override
  String get followupResultsReplyDocument => '[document]';

  @override
  String get followupResultsReplySticker => '[sticker]';

  @override
  String get followupResultsReplyLocation => '[location]';

  @override
  String get followupResultsReplyButton => '[button tap]';

  @override
  String get followupResultsReplyOther => '[attachment]';

  @override
  String get followupResultsStopReply => 'Asked to stop messages';

  @override
  String followupResultsRepliesCount(String count) {
    return '$count replies';
  }

  @override
  String get followupResultsSheetReplies => 'Replies';

  @override
  String get followupResultsSheetOrders => 'Orders after this message';

  @override
  String get followupResultsSheetNoReplies => 'No replies';

  @override
  String get followupResultsSheetNoOrders => 'No orders';

  @override
  String followupResultsSheetMoreReplies(String count) {
    return '$count more replies not shown';
  }

  @override
  String get followupResultsSheetCode => 'Code';

  @override
  String followupResultsSheetDiscount(String amount) {
    return 'Discount $amount';
  }

  @override
  String get followupResultsSheetError => 'Why it failed';

  @override
  String get followupResultsSheetAllMessages =>
      'Show all messages to this customer';

  @override
  String followupResultsOrdersSummary(String count, String amount) {
    return '$count orders · $amount';
  }

  @override
  String followupResultsOrderAfterStep(String step) {
    return 'After: $step';
  }

  @override
  String get promoLookupMenuTitle => 'Check promo code';

  @override
  String get promoLookupTitle => 'Check promo code';

  @override
  String get promoLookupCodeLabel => 'Promo code';

  @override
  String get promoLookupOrderLabel => 'Order number (optional)';

  @override
  String get promoLookupOrderHint => 'Website order number or invoice';

  @override
  String get promoLookupCheck => 'Check';

  @override
  String get promoLookupIntro =>
      'Type a promo code to see what it gives. Add an order number to see what it would do to that order.';

  @override
  String get promoLookupEnterCode => 'Type a promo code first';

  @override
  String get promoLookupLoadFailed => 'Could not check the promo code';

  @override
  String promoLookupNotFound(String code) {
    return 'No promo code $code in the system';
  }

  @override
  String get promoLookupStatusActive => 'Active';

  @override
  String get promoLookupStatusDisabled => 'Disabled';

  @override
  String get promoLookupStatusNotStarted => 'Not started yet';

  @override
  String get promoLookupStatusExpired => 'Expired';

  @override
  String get promoLookupStatusUsedUp => 'Used up';

  @override
  String promoLookupStatusUnknown(String status) {
    return 'Status: $status';
  }

  @override
  String get promoLookupTargetWholeOrder => 'the whole order';

  @override
  String get promoLookupTargetItems => 'selected items';

  @override
  String get promoLookupTargetGroups => 'selected categories';

  @override
  String promoLookupOfferPercent(String percent, String target) {
    return '$percent% off $target';
  }

  @override
  String promoLookupOfferPercentCapped(
    String percent,
    String target,
    String cap,
  ) {
    return '$percent% off $target, up to $cap';
  }

  @override
  String promoLookupOfferFixed(String amount, String target) {
    return '$amount off $target';
  }

  @override
  String get promoLookupOfferFreeDelivery => 'Free delivery';

  @override
  String get promoLookupOfferUnknown => 'Unknown discount type';

  @override
  String get promoLookupMinOrder => 'Minimum order';

  @override
  String get promoLookupMinNone => 'No minimum';

  @override
  String promoLookupMinWholeOrder(String amount) {
    return '$amount on the whole order';
  }

  @override
  String promoLookupMinEligibleOnly(String amount) {
    return '$amount on eligible items only';
  }

  @override
  String get promoLookupAppliesTo => 'Applies to';

  @override
  String get promoLookupAppliesWholeOrder => 'The whole order';

  @override
  String get promoLookupAppliesItems => 'These items';

  @override
  String get promoLookupAppliesGroups => 'These categories';

  @override
  String get promoLookupValidFrom => 'Valid from';

  @override
  String get promoLookupValidTo => 'Valid until';

  @override
  String get promoLookupNoStartDate => 'No start date';

  @override
  String get promoLookupNoEndDate => 'No end date';

  @override
  String get promoLookupUses => 'Uses';

  @override
  String promoLookupUsesOfLimit(String used, String limit) {
    return '$used of $limit used';
  }

  @override
  String promoLookupUsesUnlimited(String used) {
    return '$used used, no limit';
  }

  @override
  String get promoLookupRemaining => 'Remaining';

  @override
  String promoLookupRemainingCount(String count) {
    return '$count left';
  }

  @override
  String get promoLookupPerCustomer => 'Per customer';

  @override
  String promoLookupPerCustomerLimit(String count) {
    return 'Up to $count per customer';
  }

  @override
  String get promoLookupUnlimited => 'Unlimited';

  @override
  String get promoLookupPickup => 'Pickup orders';

  @override
  String get promoLookupAllowed => 'Allowed';

  @override
  String get promoLookupNotAllowed => 'Not allowed';

  @override
  String get promoLookupStackable => 'With other codes';

  @override
  String get promoLookupStackableYes => 'Can be combined';

  @override
  String get promoLookupStackableNo => 'Cannot be combined';

  @override
  String get promoLookupChannels => 'Channels';

  @override
  String get promoLookupAllChannels => 'All channels';

  @override
  String get promoLookupLockedCustomer => 'Only for customer';

  @override
  String get promoLookupOnWebsite => 'On the website';

  @override
  String promoLookupOnWebsiteYes(String code) {
    return 'Yes, code $code';
  }

  @override
  String get promoLookupYes => 'Yes';

  @override
  String get promoLookupNo => 'No';

  @override
  String get promoLookupRecentUses => 'Recent uses';

  @override
  String get promoLookupNoRecentUses => 'Not used yet';

  @override
  String get promoLookupUseReversed => 'Reversed';

  @override
  String get promoLookupOrderCheckTitle => 'On this order';

  @override
  String promoLookupOrderNotFound(String order) {
    return 'No order $order found';
  }

  @override
  String promoLookupOrderNotPermitted(String order) {
    return 'No access to order $order';
  }

  @override
  String get promoLookupWaivedDelivery => 'Delivery waived by the current code';

  @override
  String get promoLookupNewTotalReplacing =>
      'New total (this code instead of the current ones)';

  @override
  String get promoLookupOrder => 'Order';

  @override
  String get promoLookupCustomer => 'Customer';

  @override
  String get promoLookupOrderStatus => 'Order status';

  @override
  String get promoLookupCurrentTotal => 'Current total';

  @override
  String get promoLookupCurrentCodes => 'Codes already on it';

  @override
  String get promoLookupCurrentPromoDiscount => 'Current code discount';

  @override
  String get promoLookupNoCodes => 'None';

  @override
  String get promoLookupDelivery => 'Delivery';

  @override
  String get promoLookupAccepted => 'Accepted';

  @override
  String get promoLookupNotAccepted => 'Not accepted';

  @override
  String get promoLookupDiscount => 'Discount';

  @override
  String get promoLookupFreeDelivery => 'Free delivery';

  @override
  String get promoLookupNewTotal => 'New total';

  @override
  String get promoLookupTabCustomer => 'Customer';

  @override
  String get promoLookupTabCode => 'Code';

  @override
  String get promoCustomerSearchHint => 'Name or phone number';

  @override
  String get promoCustomerSearch => 'Search';

  @override
  String get promoCustomerIntro =>
      'Type a customer name or phone number to see their promo codes: what is active, what they used before and what expired.';

  @override
  String get promoCustomerQueryTooShort =>
      'Type at least 3 characters of a name or phone number';

  @override
  String get promoCustomerLoadFailed => 'Could not look the customer up';

  @override
  String promoCustomerNoneFound(String query) {
    return 'No customer found for $query';
  }

  @override
  String get promoCustomerTruncated =>
      'Showing first 10 matches — type more of the name';

  @override
  String promoCustomerOrderCount(String count) {
    return 'Orders: $count';
  }

  @override
  String get promoCustomerNoOrders => 'No orders yet';

  @override
  String promoCustomerLastOrder(String order, String date) {
    return 'Last order $order on $date';
  }

  @override
  String promoCustomerLastOrderDate(String date) {
    return 'Last order on $date';
  }

  @override
  String promoCustomerLastOrderId(String order) {
    return 'Last order $order';
  }

  @override
  String get promoCustomerPhoneOnly => 'Phone number only, no customer record';

  @override
  String get promoCustomerActiveCodes => 'Active personal codes';

  @override
  String get promoCustomerNoActiveCode => 'No active personal code';

  @override
  String get promoCustomerPublicCodes => 'Open codes they can use';

  @override
  String get promoCustomerNoPublicCodes => 'No open codes right now';

  @override
  String get promoCustomerUsedCodes => 'Used before';

  @override
  String get promoCustomerNeverUsed => 'Never used a promo code';

  @override
  String promoCustomerInactiveCodes(String count) {
    return 'Expired / used-up codes ($count)';
  }

  @override
  String get promoCustomerCopyCode => 'Copy code';

  @override
  String get promoCustomerCodeCopied => 'Code copied';

  @override
  String promoCustomerUsesLeft(String count) {
    return 'Uses left for this customer: $count';
  }

  @override
  String get promoCustomerUsesUnlimited => 'No use limit for this customer';

  @override
  String promoCustomerStarts(String date) {
    return 'Starts $date';
  }

  @override
  String promoCustomerValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get promoCustomerUseCancelled => 'Cancelled / reversed';

  @override
  String promoCustomerUseDiscount(String amount) {
    return '$amount off';
  }

  @override
  String promoCustomerUseDiscountOfTotal(String amount, String total) {
    return '$amount off a $total order';
  }

  @override
  String get metaAdsTitle => 'Meta Ads';

  @override
  String get metaAdsSubtitle =>
      'Which ads bring purchases: spend, CTR and ROAS by campaign, ad set and ad';

  @override
  String get metaAdsLevelCampaigns => 'Campaigns';

  @override
  String get metaAdsLevelAdsets => 'Ad sets';

  @override
  String get metaAdsLevelAds => 'Ads';

  @override
  String get metaAdsCampaign => 'Campaign';

  @override
  String get metaAdsAdset => 'Ad set';

  @override
  String get metaAdsAllCampaigns => 'All campaigns';

  @override
  String get metaAdsAllAdsets => 'All ad sets';

  @override
  String get metaAdsSortBy => 'Sort by';

  @override
  String get metaAdsSpend => 'Spend';

  @override
  String get metaAdsPurchases => 'Purchases';

  @override
  String get metaAdsRoas => 'ROAS';

  @override
  String get metaAdsCtr => 'CTR';

  @override
  String get metaAdsCostPerPurchase => 'Cost / purchase';

  @override
  String get metaAdsErpOrders => 'ERP orders';

  @override
  String get metaAdsErpRoas => 'ERP ROAS';

  @override
  String get metaAdsImpressions => 'Impressions';

  @override
  String get metaAdsLinkClicks => 'Link clicks';

  @override
  String metaAdsLinkClicksCount(String count) {
    return '$count link clicks';
  }

  @override
  String metaAdsPurchaseValueOf(String amount) {
    return 'Value $amount';
  }

  @override
  String metaAdsErpRoasOf(String value) {
    return 'ERP ROAS $value';
  }

  @override
  String metaAdsErpRevenueOf(String amount) {
    return 'Revenue $amount';
  }

  @override
  String get metaAdsNotConfigured =>
      'Meta Ads reporting is not configured. Add the ads access token in Meta CAPI Settings.';

  @override
  String get metaAdsNoRows => 'No ads delivered in this period.';

  @override
  String metaAdsFetchedAt(String time) {
    return 'Meta figures as of $time';
  }

  @override
  String get metaAdsNotes => 'Notes';

  @override
  String get metaAdsStatusActive => 'Active';

  @override
  String get metaAdsStatusPaused => 'Paused';

  @override
  String get metaAdsStatusArchived => 'Archived';

  @override
  String get metaAdsStatusDeleted => 'Deleted';

  @override
  String get metaAdsBlendedRoas => 'Blended ROAS';

  @override
  String get metaAdsBlendedSubtitle =>
      'All website and shop/chat sales against all Meta spend';

  @override
  String metaAdsBlendedRevenueOfSpend(String revenue, String spend) {
    return '$revenue sales / $spend spend';
  }

  @override
  String get metaAdsBlendedOrders => 'Orders';

  @override
  String get metaAdsBlendedAov => 'Avg order';

  @override
  String get metaAdsBlendedWholeAccount =>
      'Covers the whole ad account, not just the selected campaign or ad set.';

  @override
  String get metaAdsBlendedWhatsCounted => 'What\'s counted';

  @override
  String get metaAdsBlendedIncluded => 'Included';

  @override
  String get metaAdsBlendedExcluded => 'Left out';

  @override
  String metaAdsBlendedGroupLine(String orders, String revenue) {
    return '$orders orders · $revenue';
  }

  @override
  String get metaAdsGroupWebsite => 'Website';

  @override
  String get metaAdsGroupPos => 'Shops & chat';

  @override
  String get metaAdsGroupWhatsappFollowup => 'WhatsApp follow-ups';

  @override
  String get metaAdsGroupB2b => 'B2B';

  @override
  String get metaAdsGroupStaff => 'Staff';

  @override
  String get metaAdsGroupSamples => 'Samples';

  @override
  String get metaAdsGroupTalabat => 'Talabat';

  @override
  String get metaAdsGroupPartner => 'Other partners';

  @override
  String get metaAdsBlendedRoasShort => 'Blended ROAS';

  @override
  String get metaAdsBlendedPerRowNote =>
      'Per ad: real sales shared out by Meta\'s purchase value (estimate).';
}
