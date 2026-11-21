import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/repositories/customer_address_repository.dart';
import '../../../../core/widgets/customer_shipping_address_flow.dart';
import '../../../../core/utils/pasted_text.dart' show PhoneInputFormatter;
import '../../../../core/widgets/paste_icon_button.dart';
import '../../../../core/widgets/paste_or_clear_button.dart';
import '../../../geo/presentation/widgets/location_link_field.dart'
    show LocationLinkValue;
import '../../../credit/data/models/settlement_models.dart';
import '../../../credit/presentation/widgets/credit_settings_section.dart';
import '../../../pricing/presentation/widgets/customer_deals_section.dart';
import '../../../materials/presentation/widgets/send_materials_section.dart';
import '../../../materials/presentation/widgets/send_materials_sheet.dart'
    show MaterialRecipient;
import '../../../credit/presentation/widgets/settlement_terms_section.dart';
import '../../../journey/presentation/widgets/journey_notes_section.dart';
import '../../../journey/state/journey_notes_notifier.dart'
    show JourneyRef, journeyNotesProvider;
import '../../../labels/models/label_models.dart'
    show LabelStatus, labelLocationName;
import '../../../labels/presentation/widgets/label_status_chip.dart';
import '../../../leads/data/leads_repository.dart';
import '../../../leads/data/models/lead.dart';
import '../../../leads/presentation/leads_theme.dart';
import '../../../leads/presentation/widgets/category_chip.dart';
import '../../../leads/presentation/widgets/lead_actions.dart';
import '../../../leads/presentation/widgets/sahel_badge.dart';
import '../../../leads/presentation/widgets/score_bar.dart';
import '../../../leads/presentation/widgets/tier_pill.dart';
import '../../../pos/presentation/widgets/customer_search_widget.dart'
    show territoriesProvider;
import '../../../pricing/presentation/screens/customer_pricing_screen.dart';
import '../../data/b2b_repository.dart';
import '../../data/models/b2b_account_labels.dart';
import '../../data/models/b2b_models.dart';
import '../../state/b2b_pipeline_notifier.dart';
import '../../state/b2b_today_notifier.dart';
import '../b2b_order_launch.dart';
import '../widgets/b2b_merge_branch_flow.dart';
import '../widgets/b2b_stage_chip.dart';
import 'b2b_branch_invoices_screen.dart';
import '../../../../core/utils/territory_label.dart';

/// Whose payment terms the account screen shows: the linked Customer when
/// there is one (a Customer account, or a converted Lead), otherwise the Lead
/// itself — terms agreed during the deal, before the first order, which the
/// server moves to the Customer on conversion. An Opportunity with no Customer
/// falls back to its linked Lead; with neither there is nothing to attach
/// terms to and the section is omitted.
/// Who the price sheet can go to from the account screen: the account's own
/// mobile and landline, under the account's name. Same shape as the lead
/// page's `_recipientsFor` (one entry per distinct phone, never a duplicate),
/// minus the named contacts that only a Lead carries.
@visibleForTesting
List<MaterialRecipient> b2bMaterialRecipients(B2bAccount account) {
  final recipients = <MaterialRecipient>[];
  final name = account.title.trim().isNotEmpty
      ? account.title.trim()
      : account.name.trim();
  for (final phone in [account.contact.mobileNo, account.contact.phone]) {
    final value = phone?.trim() ?? '';
    if (value.isEmpty || recipients.any((r) => r.phone == value)) continue;
    recipients.add(MaterialRecipient(name: name, phone: value));
  }
  return recipients;
}

SettlementParty? settlementPartyForAccount(B2bAccount account) {
  final customer = account.customer?.trim() ?? '';
  if (customer.isNotEmpty) return SettlementParty.customer(customer);
  if (account.doctype == 'Customer') {
    final name = account.name.trim();
    return name.isEmpty ? null : SettlementParty.customer(name);
  }
  if (account.doctype == 'Lead') {
    final name = account.name.trim();
    return name.isEmpty ? null : SettlementParty.lead(name);
  }
  final lead = account.branchLead?.trim() ?? '';
  return lead.isEmpty ? null : SettlementParty.lead(lead);
}

/// B2B account detail: contact, stage, lead score, predicted next order, recent
/// invoices and open todos, plus quick actions (send sample, place order, log
/// call, mark lost).
class B2bAccountScreen extends ConsumerStatefulWidget {
  final String doctype;
  final String name;

  const B2bAccountScreen({
    super.key,
    required this.doctype,
    required this.name,
  });

  @override
  ConsumerState<B2bAccountScreen> createState() => _B2bAccountScreenState();
}

class _B2bAccountScreenState extends ConsumerState<B2bAccountScreen> {
  late Future<B2bAccountDetail> _future;
  bool _busy = false;

  /// The loaded account with in-place edits applied (a branch link / unlink
  /// returns the new branch list, so there is no need to refetch everything).
  /// Cleared on every reload.
  B2bAccountDetail? _current;

  /// Expand / collapse state of the collapsible sections. Held here, not in
  /// [_AccountBody], because a reload swaps the body for a spinner and would
  /// otherwise reset the choice. `null` = the rep has not chosen yet, so the
  /// default applies (Journey: collapsed for an Active account, expanded for
  /// every other stage; Open to-dos: always collapsed).
  bool? _journeyExpanded;
  bool _todosExpanded = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<B2bAccountDetail> _load() {
    return ref
        .read(b2bRepositoryProvider)
        .getAccount(doctype: widget.doctype, name: widget.name);
  }

  void _reload() {
    setState(() {
      _current = null;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.b2bAccountTitle),
        actions: [
          if (canMergeAsBranch(widget.doctype))
            PopupMenuButton<String>(
              enabled: !_busy,
              onSelected: (value) {
                if (value == 'merge') unawaited(_mergeAnotherAccount());
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'merge',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.call_merge),
                    title: Text(context.l10n.b2bMergeMenuItem),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: FutureBuilder<B2bAccountDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.userErrorMessage(snapshot.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: Text(context.l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            );
          }
          final detail = _current ?? snapshot.requireData;
          final account = detail.account;
          final customer = account.customer;
          final isCustomerAccount = widget.doctype == 'Customer';
          return _AccountBody(
            account: account,
            labels: detail.labels,
            busy: _busy,
            journeyExpanded: _journeyExpanded ?? account.stage != 'Active',
            onToggleJourney: () => setState(
              () => _journeyExpanded =
                  !(_journeyExpanded ?? account.stage != 'Active'),
            ),
            todosExpanded: _todosExpanded,
            onToggleTodos: () =>
                setState(() => _todosExpanded = !_todosExpanded),
            onSendSample: () => _bindAndOrder(account, isSample: true),
            onPlaceOrder: () => _bindAndOrder(account, isSample: false),
            onMakeCustomer:
                (customer == null || customer.isEmpty) && !isCustomerAccount
                ? () => _makeCustomer(account)
                : null,
            onLogCall: isCustomerAccount ? null : () => _logCall(account),
            onMarkLost: isCustomerAccount ? null : () => _markLost(account),
            onJourneyChanged: isCustomerAccount ? null : _reload,
            // Only a Lead has a catalog page to open; an Opportunity does not.
            onOpenLead: _isLead ? _openLeadPage : null,
            onOpenLabel: _openLabelDetail,
            // Setting up labels needs a real Customer behind the account.
            onSetupLabels: (customer != null && customer.isNotEmpty)
                ? () => _openLabelSetup(customer, account.title)
                : null,
            onViewPricing: (customer != null && customer.isNotEmpty)
                ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CustomerPricingScreen(customer: customer),
                    ),
                  )
                : null,
            onAddBranch: (customer != null && customer.isNotEmpty)
                ? () => _addBranch(account, customer)
                : null,
            onOpenInvoices: (customer != null && customer.isNotEmpty)
                ? (branch) => _openInvoices(account, branch)
                : null,
            onLinkMapsBranch: (maps, delivery) =>
                _linkMapsBranch(detail, maps: maps, delivery: delivery),
            onUnlinkMapsBranch: (delivery) =>
                _unlinkMapsBranch(detail, delivery),
            onRenameBranch: (customer != null && customer.isNotEmpty)
                ? (delivery) => _renameBranch(customer, delivery)
                : null,
            // A delivery branch is a shipping Address on the Customer.
            onPromoteMapsBranch: (customer != null && customer.isNotEmpty)
                ? (maps) => _promoteMapsBranch(detail, customer, maps)
                : null,
          );
        },
      ),
    );
  }

  /// Opens one flavour's label detail, then revalidates: a batch ordered or
  /// received there changes the status chips shown here.
  Future<void> _openLabelDetail(String label) async {
    await context.push(AppRoutes.labelDetail, extra: label);
    if (mounted) _reload();
  }

  /// Launches the label setup wizard with this account's customer preselected.
  Future<void> _openLabelSetup(String customer, String customerName) async {
    await context.push(
      AppRoutes.labelSetup,
      extra: <String, dynamic>{
        'customer': customer,
        'customer_name': customerName,
      },
    );
    if (mounted) _reload();
  }

  bool get _isLead => widget.doctype == 'Lead';

  /// Adds a named branch (a shipping Address) to the account's Customer via
  /// the same picker the order flow uses, then reloads the branch list. The
  /// reload runs even on cancel: the dialog saves a new branch before the
  /// picker closes.
  Future<void> _addBranch(B2bAccount account, String customer) async {
    await chooseCustomerShippingAddress(
      context,
      customer: <String, dynamic>{
        'name': customer,
        'customer_name': account.title,
        if (account.contact.mobileNo case final mobile?) 'mobile_no': mobile,
      },
      repository: ref.read(customerAddressRepositoryProvider),
      forcePicker: true,
      requireBranchName: true,
      setAsPrimary: false,
    );
    if (mounted) _reload();
  }

  /// Pairs the Google Maps branch [maps] with the delivery branch [delivery]:
  /// one door, shown once.
  Future<void> _linkMapsBranch(
    B2bAccountDetail detail, {
    required B2bBranch maps,
    required B2bBranch delivery,
  }) async {
    final row = maps.mapsRow;
    final address = delivery.addressName;
    if (row == null || address == null) return;
    await _sendBranchLink(
      detail,
      mapsRow: row,
      addressName: address,
      successMessage: context.l10n.b2bBranchLinkedDone,
    );
  }

  /// Splits a delivery branch from its Google Maps branch. The server also
  /// stops auto-matching that Maps row, so it stays split.
  Future<void> _unlinkMapsBranch(
    B2bAccountDetail detail,
    B2bBranch delivery,
  ) async {
    final row = delivery.mapsRow;
    if (row == null) return;
    await _sendBranchLink(
      detail,
      mapsRow: row,
      addressName: null,
      successMessage: context.l10n.b2bBranchUnlinkedDone,
    );
  }

  /// Renames a delivery branch (its Address title, on every folded Address
  /// row). Invoices point at the Address itself, so a branch keeps its whole
  /// history and balance under the new name.
  Future<void> _renameBranch(String customer, B2bBranch delivery) async {
    final address = delivery.addressName;
    if (address == null || address.isEmpty) return;
    final l10n = context.l10n;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameBranchDialog(initial: delivery.displayName),
    );
    // Same normalisation as the server: trimmed, inner runs of spaces collapsed.
    final trimmed = (name ?? '').trim().split(RegExp(r'\s+')).join(' ');
    if (!mounted || name == null) return;
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.customerShippingAddressBranchNameRequired)),
      );
      return;
    }
    if (trimmed == delivery.displayName) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(b2bRepositoryProvider)
          .renameBranch(
            customer: customer,
            addressName: address,
            branchName: trimmed,
          );
      if (!mounted) return;
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.userErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendBranchLink(
    B2bAccountDetail detail, {
    required String mapsRow,
    required String? addressName,
    required String successMessage,
  }) async {
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(b2bRepositoryProvider)
          .linkBranch(
            doctype: widget.doctype,
            name: widget.name,
            mapsRow: mapsRow,
            addressName: addressName,
          );
      if (!mounted) return;
      _applyBranches(detail, result);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.userErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Swaps in the branch list the link endpoint returned. An empty list from
  /// an account that had branches means the reply was not the expected shape:
  /// refetch rather than blank the section.
  void _applyBranches(B2bAccountDetail detail, B2bBranchLinkResult result) {
    if (result.branches.isEmpty && detail.account.branches.isNotEmpty) {
      _reload();
      return;
    }
    setState(() {
      _current = B2bAccountDetail(
        account: detail.account.copyWith(
          branches: result.branches,
          unassignedInvoices: result.unassigned,
        ),
        labels: detail.labels,
      );
    });
  }

  /// Turns a Google Maps branch into a delivery branch: the same add-branch
  /// dialog [_addBranch] opens, prefilled from the listing, then an explicit
  /// link between the new Address and the Maps row. When the new Address
  /// cannot be identified the account is reloaded and the server's name / pin
  /// auto-match pairs them instead.
  Future<void> _promoteMapsBranch(
    B2bAccountDetail detail,
    String customer,
    B2bBranch entry,
  ) async {
    final maps = entry.maps;
    final account = detail.account;
    final mapsUrl = maps?.mapsUrl?.trim() ?? '';
    final link = LeadActions.isSafeMapsUrl(mapsUrl) ? mapsUrl : '';
    LocationLinkValue? pin;
    if (maps != null && maps.hasLocation) {
      pin = LocationLinkValue(
        link: link,
        latitude: maps.latitude,
        longitude: maps.longitude,
      );
    } else if (link.isNotEmpty) {
      pin = LocationLinkValue(link: link);
    }
    final selected = await chooseCustomerShippingAddress(
      context,
      customer: <String, dynamic>{
        'name': customer,
        'customer_name': account.title,
        if (account.contact.mobileNo case final mobile?) 'mobile_no': mobile,
      },
      repository: ref.read(customerAddressRepositoryProvider),
      forcePicker: true,
      requireBranchName: true,
      setAsPrimary: false,
      initialBranchName: maps?.branchName ?? entry.displayName,
      initialNewAddress: maps?.address ?? maps?.area,
      initialNewLocation: pin,
    );
    if (!mounted) return;
    final addressName =
        selected?['selected_shipping_address_name']?.toString().trim() ?? '';
    final row = entry.mapsRow;
    if (selected == null || addressName.isEmpty || row == null) {
      // Cancelled, or saved without an identifiable Address: the dialog may
      // still have saved something, so show the server's view.
      _reload();
      return;
    }
    await _sendBranchLink(
      detail,
      mapsRow: row,
      addressName: addressName,
      successMessage: context.l10n.b2bBranchPromotedDone(entry.displayName),
    );
  }

  /// Opens the invoice list filtered to [branch] (null = every invoice).
  Future<void> _openInvoices(B2bAccount account, String? branch) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => B2bBranchInvoicesScreen(
          doctype: widget.doctype,
          name: widget.name,
          accountTitle: account.title,
          branches: account.deliveryBranches,
          hasUnassigned: account.unassignedInvoices != null,
          initialBranch: branch,
        ),
      ),
    );
  }

  /// Folds another account into this one as a branch (or, swapped in the
  /// confirmation, this one into the other). Lands on the surviving account.
  Future<void> _mergeAnotherAccount() async {
    String title = widget.name;
    try {
      title = (await _future).account.title;
    } catch (_) {
      // Fall back to the record name when the account failed to load.
    }
    if (!mounted) return;
    final outcome = await runMergeAsBranchFlow(
      context,
      doctype: widget.doctype,
      name: widget.name,
      title: title,
    );
    if (outcome == null || !mounted) return;
    ref.invalidate(b2bPipelineProvider);
    ref.invalidate(b2bTodayProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.b2bMergeSuccess(
            outcome.sourceTitle,
            outcome.targetTitle,
          ),
        ),
      ),
    );
    final result = outcome.result;
    if (result.targetDoctype == widget.doctype &&
        result.targetName == widget.name) {
      _reload();
      return;
    }
    // This account no longer exists on its own: replace it with the survivor.
    context.pushReplacement(
      AppRoutes.b2bAccount,
      extra: <String, dynamic>{
        'doctype': result.targetDoctype,
        'name': result.targetName,
      },
    );
  }

  /// Opens the full lead catalog page for this card — the rich profile, the
  /// branches, the addresses and the merge tools the account view only
  /// summarises. Revalidates on the way back so an edit made there (stage,
  /// suitability, a journey note) is reflected here immediately.
  Future<void> _openLeadPage() async {
    await context.push('/leads/${Uri.encodeComponent(widget.name)}');
    if (mounted) _reload();
  }

  Future<void> _bindAndOrder(
    B2bAccount account, {
    required bool isSample,
  }) async {
    _LeadCustomerSetup? setup;
    if (account.customer == null || account.customer!.isEmpty) {
      setup = await _promptLeadCustomerSetup(account);
      if (setup == null) return;
    }

    setState(() => _busy = true);
    final repo = ref.read(b2bRepositoryProvider);
    try {
      if (setup?.existingCustomer case final existing?) {
        await repo.linkExistingCustomer(
          partyDoctype: widget.doctype,
          partyName: widget.name,
          customer: existing['name']?.toString() ?? '',
        );
      }
      final leadFields = setup?.createFields;
      final binding = isSample
          ? await repo.requestSample(
              partyDoctype: widget.doctype,
              partyName: widget.name,
              customerName: leadFields?.customerName,
              mobileNo: leadFields?.mobileNo,
              customerPrimaryAddress: leadFields?.address,
              territoryId: leadFields?.territoryId,
            )
          : await repo.placeB2bOrder(
              partyDoctype: widget.doctype,
              partyName: widget.name,
              customerName: leadFields?.customerName,
              mobileNo: leadFields?.mobileNo,
              customerPrimaryAddress: leadFields?.address,
              territoryId: leadFields?.territoryId,
            );
      if (!mounted) return;
      final existing = setup?.existingCustomer;
      final customer = <String, dynamic>{
        ...?existing,
        'name': binding.customer,
        'customer_name':
            binding.customerName ??
            existing?['customer_name']?.toString() ??
            leadFields?.customerName ??
            account.title,
        if ((existing?['mobile_no']?.toString() ??
                leadFields?.mobileNo ??
                account.contact.mobileNo)
            case final mobile?)
          'mobile_no': mobile,
      };
      final selectedCustomer = await chooseCustomerShippingAddress(
        context,
        customer: customer,
        repository: ref.read(customerAddressRepositoryProvider),
        initialAddressBook: binding.addressBook.isEmpty
            ? null
            : binding.addressBook,
        forcePicker: binding.requiresShippingAddressSelection,
        requireBranchName: true,
        setAsPrimary: false,
      );
      if (selectedCustomer == null || !mounted) {
        // Linking or customer creation may already have succeeded before the
        // address dialog was cancelled. Reload so the account immediately
        // reflects that durable, idempotent setup on the next attempt.
        if (mounted && setup != null) _reload();
        return;
      }
      await launchB2bOrderInPos(
        context,
        binding: binding,
        selectedCustomer: selectedCustomer,
        customerName: customer['customer_name']?.toString(),
        mobileNo: customer['mobile_no']?.toString(),
      );
      if (mounted) _reload();
    } catch (e) {
      if (!mounted) return;
      if (setup != null) _reload();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.userErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logCall(B2bAccount account) async {
    final l10n = context.l10n;
    final note = await _promptText(
      title: l10n.b2bLogCall,
      hint: l10n.b2bLogCallHint,
    );
    if (note == null || note.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(b2bRepositoryProvider)
          .logActivity(doctype: widget.doctype, name: widget.name, note: note);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.b2bActivityLogged)));
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.userErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markLost(B2bAccount account) async {
    final l10n = context.l10n;
    final reason = await _promptText(
      title: l10n.b2bMarkLostTitle,
      hint: l10n.b2bReasonHint,
    );
    if (reason == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(b2bRepositoryProvider)
          .advanceStage(
            doctype: widget.doctype,
            name: widget.name,
            stage: 'Lost/On-hold',
            reason: reason,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.b2bMarkedLost)));
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.userErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _promptText({required String title, required String hint}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Future<_LeadCustomerSetup?> _promptLeadCustomerSetup(
    B2bAccount account, {
    bool setupOnly = false,
  }) {
    final leadName = account.doctype == 'Lead'
        ? account.name
        : account.branchLead;
    return showDialog<_LeadCustomerSetup>(
      context: context,
      builder: (ctx) => _LeadCustomerDialog(
        account: account,
        leadName: leadName,
        setupOnly: setupOnly,
      ),
    );
  }

  /// Links or creates the Customer for this Lead and stops there: no POS, no
  /// order, no sample. The order-binding endpoint creates the Customer without
  /// writing any invoice, so it doubles as the "just make it a customer" call.
  Future<void> _makeCustomer(B2bAccount account) async {
    final setup = await _promptLeadCustomerSetup(account, setupOnly: true);
    if (setup == null || !mounted) return;
    setState(() => _busy = true);
    final repo = ref.read(b2bRepositoryProvider);
    try {
      String? customerName;
      if (setup.existingCustomer case final existing?) {
        await repo.linkExistingCustomer(
          partyDoctype: widget.doctype,
          partyName: widget.name,
          customer: existing['name']?.toString() ?? '',
        );
        customerName =
            existing['customer_name']?.toString() ??
            existing['name']?.toString();
      } else if (setup.createFields case final fields?) {
        final binding = await repo.placeB2bOrder(
          partyDoctype: widget.doctype,
          partyName: widget.name,
          customerName: fields.customerName,
          mobileNo: fields.mobileNo,
          customerPrimaryAddress: fields.address,
          territoryId: fields.territoryId,
        );
        customerName = binding.customerName ?? fields.customerName;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.l10n.commonCustomerLabel}: ${customerName ?? account.title}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.userErrorMessage(e))));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _reload();
      }
    }
  }
}

/// Create-customer dialog for a Lead with no linked Customer. Territory is a
/// dropdown sourced from [territoriesProvider]; all fields are required.
class _LeadCustomerDialog extends ConsumerStatefulWidget {
  final B2bAccount account;

  /// The Lead whose saved contacts and primary address prefill the form
  /// (the account itself for a Lead, its source Lead for an Opportunity).
  final String? leadName;

  /// True when the dialog only sets up the Customer (no order follows), so
  /// the confirm button reads Save instead of Continue.
  final bool setupOnly;

  const _LeadCustomerDialog({
    required this.account,
    this.leadName,
    this.setupOnly = false,
  });

  @override
  ConsumerState<_LeadCustomerDialog> createState() =>
      _LeadCustomerDialogState();
}

class _LeadCustomerDialogState extends ConsumerState<_LeadCustomerDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _searchCtrl;
  final _addressCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Timer? _searchDebounce;
  int _searchGeneration = 0;
  bool _createNew = false;
  bool _searching = false;
  String? _territory;
  Map<String, dynamic>? _selectedCustomer;
  List<Map<String, dynamic>> _matches = const [];

  /// People on this account with a phone: the Lead's saved contacts plus the
  /// account's own numbers, one entry per distinct phone.
  List<LeadContact> _contacts = const [];
  int? _contactIndex;

  static const List<TextInputFormatter> _phoneFormatters = [
    PhoneInputFormatter(),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.account.title);
    _mobileCtrl = TextEditingController(
      text: widget.account.contact.mobileNo ?? '',
    );
    _searchCtrl = TextEditingController(text: widget.account.title);
    _contacts = _accountContacts(const []);
    unawaited(_search(widget.account.title));
    unawaited(_loadLead());
  }

  List<LeadContact> _accountContacts(List<LeadContact> leadContacts) {
    final out = <LeadContact>[];
    final seen = <String>{};
    void add(LeadContact c) {
      final phone = c.phone.trim();
      if (phone.isEmpty || !seen.add(phone)) return;
      out.add(c);
    }

    // Primary contact first, then the rest as saved, then the account's own.
    for (final c in leadContacts.where((c) => c.isPrimary)) {
      add(c);
    }
    for (final c in leadContacts) {
      add(c);
    }
    for (final phone in [
      widget.account.contact.mobileNo,
      widget.account.contact.phone,
    ]) {
      add(LeadContact(contactName: widget.account.title, phone: phone ?? ''));
    }
    return out;
  }

  /// Best effort: a missing or unreadable Lead just leaves the form as it was.
  Future<void> _loadLead() async {
    final leadName = widget.leadName?.trim() ?? '';
    if (leadName.isEmpty) return;
    try {
      final lead = await ref.read(leadsRepositoryProvider).getLead(leadName);
      if (!mounted) return;
      setState(() {
        _contacts = _accountContacts(lead.contacts);
        _contactIndex = null;
        if (_addressCtrl.text.trim().isEmpty) {
          final address = _formatLeadAddress(lead.primaryAddress);
          if (address != null) _addressCtrl.text = address;
        }
      });
    } catch (_) {
      // Contacts are a convenience; typing the number still works.
    }
  }

  static String? _formatLeadAddress(LeadAddress? address) {
    if (address == null) return null;
    final parts = [
      address.addressLine1,
      address.addressLine2,
      address.city,
      address.state,
      address.country,
    ].where((s) => s.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  void _useContact(int? index) {
    setState(() => _contactIndex = index);
    if (index == null || index >= _contacts.length) return;
    final phone = _contacts[index].phone.trim();
    _mobileCtrl.value = TextEditingValue(
      text: phone,
      selection: TextSelection.collapsed(offset: phone.length),
    );
  }

  String _contactLabel(LeadContact c) {
    final parts = [
      c.displayName,
      if (c.role.trim().isNotEmpty) c.role.trim(),
      if (c.phone.trim() != c.displayName) c.phone.trim(),
    ];
    return parts.join(' · ');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _searchCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_search(value)),
    );
  }

  Future<void> _search(String query) async {
    final normalized = query.trim();
    final generation = ++_searchGeneration;
    if (normalized.isEmpty) {
      if (mounted) setState(() => _matches = const []);
      return;
    }
    if (mounted) setState(() => _searching = true);
    try {
      final matches = await ref
          .read(b2bRepositoryProvider)
          .searchLinkableCustomers(normalized);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _matches = matches;
        if (_selectedCustomer != null &&
            !matches.any(
              (row) =>
                  row['name']?.toString() ==
                  _selectedCustomer?['name']?.toString(),
            )) {
          _selectedCustomer = null;
        }
      });
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() => _matches = const []);
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() => _searching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.b2bCustomerSetupTitle),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.link),
                      label: Text(l10n.b2bLinkExistingCustomer),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.person_add_outlined),
                      label: Text(l10n.b2bCreateNewCustomer),
                    ),
                  ],
                  selected: {_createNew},
                  onSelectionChanged: (selection) =>
                      setState(() => _createNew = selection.single),
                ),
                const SizedBox(height: 16),
                if (_createNew)
                  ..._buildCreateFields()
                else ...[
                  TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      labelText: l10n.b2bSearchExistingCustomer,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : PasteIconButton(
                              key: const ValueKey('b2b-setup-search-paste'),
                              controller: _searchCtrl,
                              replace: true,
                              onChanged: _onSearchChanged,
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_searching && _matches.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(l10n.b2bNoMatchingCustomers),
                    ),
                  ..._matches.map(_buildCustomerMatch),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _createNew
              ? _continueWithNewCustomer
              : (_selectedCustomer == null
                    ? null
                    : () => Navigator.pop(
                        context,
                        _LeadCustomerSetup(existingCustomer: _selectedCustomer),
                      )),
          child: Text(
            widget.setupOnly
                ? l10n.commonSave
                : (_createNew ? l10n.b2bContinue : l10n.b2bLinkAndContinue),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCreateFields() => [
    TextFormField(
      controller: _nameCtrl,
      decoration: InputDecoration(
        labelText: context.l10n.b2bCustomerName,
        suffixIcon: PasteIconButton(
          key: const ValueKey('b2b-setup-name-paste'),
          controller: _nameCtrl,
          replace: true,
        ),
      ),
      validator: _required,
    ),
    if (_contacts.isNotEmpty)
      DropdownButtonFormField<int>(
        key: ValueKey('b2b-setup-contact-${_contacts.length}'),
        initialValue: _contactIndex,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: context.l10n.leadContactsTitle,
          prefixIcon: const Icon(Icons.contacts_outlined),
        ),
        items: [
          for (var i = 0; i < _contacts.length; i++)
            DropdownMenuItem<int>(
              value: i,
              child: Text(
                _contactLabel(_contacts[i]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: _useContact,
      ),
    TextFormField(
      controller: _mobileCtrl,
      keyboardType: TextInputType.phone,
      inputFormatters: _phoneFormatters,
      decoration: InputDecoration(
        labelText: context.l10n.leadFieldMobile,
        suffixIcon: PasteIconButton(
          key: const ValueKey('b2b-setup-mobile-paste'),
          controller: _mobileCtrl,
          replace: true,
          inputFormatters: _phoneFormatters,
        ),
      ),
      validator: _required,
    ),
    TextFormField(
      controller: _addressCtrl,
      minLines: 1,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: context.l10n.b2bAddress,
        suffixIcon: PasteOrClearButton(
          key: const ValueKey('b2b-setup-address-paste'),
          controller: _addressCtrl,
        ),
      ),
      validator: _required,
    ),
    _buildTerritoryField(),
  ];

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? context.l10n.leadFormRequired
      : null;

  Widget _buildCustomerMatch(Map<String, dynamic> customer) {
    final selected =
        customer['name']?.toString() == _selectedCustomer?['name']?.toString();
    final details = <String>[
      if ((customer['customer_type'] ?? '').toString().trim().isNotEmpty)
        customer['customer_type'].toString(),
      if ((customer['customer_group'] ?? '').toString().trim().isNotEmpty)
        customer['customer_group'].toString(),
      if ((customer['mobile_no'] ?? '').toString().trim().isNotEmpty)
        customer['mobile_no'].toString(),
      if ((customer['primary_address'] ?? '').toString().trim().isNotEmpty)
        customer['primary_address'].toString(),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: RadioListTile<bool>(
        value: true,
        groupValue: selected,
        onChanged: (_) => setState(() => _selectedCustomer = customer),
        title: Text(
          customer['customer_name']?.toString() ??
              customer['name']?.toString() ??
              '',
        ),
        subtitle: details.isEmpty ? null : Text(details.join(' • ')),
      ),
    );
  }

  void _continueWithNewCustomer() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _LeadCustomerSetup(
        createFields: _LeadCustomerFields(
          customerName: _nameCtrl.text.trim(),
          mobileNo: _mobileCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          territoryId: _territory!.trim(),
        ),
      ),
    );
  }

  Widget _buildTerritoryField() {
    final l10n = context.l10n;
    final territoriesAsync = ref.watch(territoriesProvider(null));
    return territoriesAsync.when(
      data: (territories) => DropdownButtonFormField<String>(
        initialValue: _territory,
        isExpanded: true,
        menuMaxHeight: 320,
        decoration: InputDecoration(labelText: l10n.leadFieldTerritory),
        items: territories.map<DropdownMenuItem<String>>((territory) {
          final name = territory['name']?.toString() ?? '';
          final label = territoryLabelOf(territory);
          return DropdownMenuItem<String>(
            value: name,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (value) => setState(() => _territory = value),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? l10n.leadFormRequired : null,
      ),
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(l10n.b2bLoadingTerritories),
          ],
        ),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          l10n.b2bTerritoriesFailed,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}

class _LeadCustomerFields {
  final String customerName;
  final String mobileNo;
  final String address;
  final String territoryId;
  const _LeadCustomerFields({
    required this.customerName,
    required this.mobileNo,
    required this.address,
    required this.territoryId,
  });
}

class _LeadCustomerSetup {
  final Map<String, dynamic>? existingCustomer;
  final _LeadCustomerFields? createFields;

  const _LeadCustomerSetup({this.existingCustomer, this.createFields})
    : assert(existingCustomer != null || createFields != null);
}

class _AccountBody extends StatelessWidget {
  final B2bAccount account;
  final B2bAccountLabels? labels;
  final bool busy;
  final bool journeyExpanded;
  final VoidCallback onToggleJourney;
  final bool todosExpanded;
  final VoidCallback onToggleTodos;
  final VoidCallback onSendSample;
  final VoidCallback onPlaceOrder;

  /// Turns a Lead/Opportunity into a Customer without opening the POS. Null
  /// once a Customer is linked (and on a Customer account).
  final VoidCallback? onMakeCustomer;
  final VoidCallback? onLogCall;
  final VoidCallback? onMarkLost;
  final VoidCallback? onJourneyChanged;
  final VoidCallback? onOpenLead;
  final void Function(String label)? onOpenLabel;
  final VoidCallback? onSetupLabels;
  final VoidCallback? onViewPricing;
  final VoidCallback? onAddBranch;

  /// Opens the invoice list for a branch key, the unassigned bucket, or all
  /// invoices (null). Null itself when no Customer is linked.
  final void Function(String? branch)? onOpenInvoices;

  /// Combines a Google Maps branch with a delivery branch.
  final void Function(B2bBranch maps, B2bBranch delivery)? onLinkMapsBranch;

  /// Splits a delivery branch from its Google Maps branch.
  final void Function(B2bBranch delivery)? onUnlinkMapsBranch;

  /// Turns a Google Maps branch into a delivery branch. Null with no Customer.
  final void Function(B2bBranch maps)? onPromoteMapsBranch;

  /// Renames a delivery branch. Null with no Customer.
  final void Function(B2bBranch delivery)? onRenameBranch;

  const _AccountBody({
    required this.account,
    required this.labels,
    required this.busy,
    required this.journeyExpanded,
    required this.onToggleJourney,
    required this.todosExpanded,
    required this.onToggleTodos,
    required this.onSendSample,
    required this.onPlaceOrder,
    this.onMakeCustomer,
    this.onLogCall,
    this.onMarkLost,
    this.onJourneyChanged,
    this.onOpenLead,
    this.onOpenLabel,
    this.onSetupLabels,
    this.onViewPricing,
    this.onAddBranch,
    this.onOpenInvoices,
    this.onLinkMapsBranch,
    this.onUnlinkMapsBranch,
    this.onPromoteMapsBranch,
    this.onRenameBranch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Reserve room for the pinned action bar plus the bottom system inset so
    // the last list content is never hidden behind the bar.
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final trailingSpacer = 80.0 + bottomInset;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    account.title,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                B2bStageChip(stage: account.stage),
              ],
            ),
            if (onOpenLead != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onOpenLead,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(context.l10n.b2bOpenLeadPage),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _section(context, context.l10n.b2bSectionContact, [
              if (account.contact.mobileNo != null)
                _kv(
                  context,
                  context.l10n.leadFieldMobile,
                  account.contact.mobileNo!,
                ),
              if (account.contact.phone != null)
                _kv(
                  context,
                  context.l10n.leadFieldPhone,
                  account.contact.phone!,
                ),
              if (account.contact.emailId != null)
                _kv(
                  context,
                  context.l10n.leadFieldEmail,
                  account.contact.emailId!,
                ),
              if (account.customer != null)
                _kv(
                  context,
                  context.l10n.commonCustomerLabel,
                  account.customer!,
                ),
            ]),
            if (account.doctype == 'Lead')
              _LeadProfileSection(leadName: account.name),
            // Shown with a Customer (delivery branches + invoices) and also
            // for a Lead that only has Google Maps branches so far.
            if (onOpenInvoices != null || account.branches.isNotEmpty)
              _BranchesSection(
                branches: account.branches,
                unassigned: account.unassignedInvoices,
                showAddBranch: onAddBranch != null,
                onAddBranch: busy ? null : onAddBranch,
                onOpenInvoices: onOpenInvoices,
                onLinkMaps: busy ? null : onLinkMapsBranch,
                onUnlinkMaps: busy ? null : onUnlinkMapsBranch,
                onPromoteMaps: busy ? null : onPromoteMapsBranch,
                onRename: busy ? null : onRenameBranch,
              ),
            // Agreed payment terms, settable before the first order. Hidden
            // outright for a user who may not see them or on an older server.
            if (settlementPartyForAccount(account) case final party?) ...[
              const SizedBox(height: 16),
              SettlementTermsSection(
                key: const ValueKey('b2b-settlement-terms'),
                party: party,
                partyName: account.title,
                hideWhenUnavailable: true,
              ),
            ],
            // Credit needs a real Customer; a Lead gets it once converted.
            if (settlementPartyForAccount(account) case final party?
                when !party.isLead) ...[
              const SizedBox(height: 12),
              CreditSettingsSection(
                key: const ValueKey('b2b-credit-settings'),
                customer: party.name,
                customerName: account.title,
              ),
              // Time-limited special prices. Needs a Customer: orders, and so
              // deals, only exist once the Lead is converted.
              const SizedBox(height: 12),
              CustomerDealsSection(
                key: const ValueKey('b2b-customer-deals'),
                customer: party.name,
                customerName: account.title,
              ),
              // The price sheet, sent on WhatsApp with this customer's own
              // prices (and any deal above) filled in by the server.
              const SizedBox(height: 12),
              SendMaterialsSection(
                key: const ValueKey('b2b-send-materials'),
                referenceDoctype: 'Customer',
                referenceName: party.name,
                recipients: b2bMaterialRecipients(account),
              ),
            ],
            const SizedBox(height: 16),
            // The same diary the lead page shows — one journey per account, not
            // one per screen. `onJourneyChanged` reloads the account because a
            // dated next action restamps its follow-up server-side.
            if (onJourneyChanged != null)
              _CollapsibleJourney(
                key: const ValueKey('b2b-journey-section'),
                referenceDoctype: account.doctype,
                referenceName: account.name,
                expanded: journeyExpanded,
                onToggle: onToggleJourney,
                section: JourneyNotesSection(
                  referenceDoctype: account.doctype,
                  referenceName: account.name,
                  defaultContactPhone:
                      account.contact.mobileNo ?? account.contact.phone,
                  onChanged: onJourneyChanged!,
                ),
              ),
            _section(context, context.l10n.b2bSectionInsights, [
              if (account.predictedNextOrder != null)
                _kv(
                  context,
                  context.l10n.b2bPredictedNextOrder,
                  account.predictedNextOrder!,
                ),
              if (account.avgOrderCycleDays != null)
                _kv(
                  context,
                  context.l10n.b2bAvgOrderCycle,
                  context.l10n.b2bDaysValue(
                    account.avgOrderCycleDays!.toStringAsFixed(1),
                  ),
                ),
            ]),
            _LabelsSection(
              labels: labels,
              onOpenLabel: busy ? null : onOpenLabel,
              onSetupLabels: busy ? null : onSetupLabels,
            ),
            _section(context, context.l10n.b2bSectionRecentInvoices, [
              if (account.recentInvoices.isEmpty)
                Text(context.l10n.b2bNone)
              else
                ...account.recentInvoices.map(
                  (inv) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(inv.displayId),
                    subtitle: Text(
                      [
                        inv.postingDate ?? '',
                        inv.orderPurpose ?? '',
                        inv.status ?? '',
                        if (inv.branchName ?? inv.branchAddress
                            case final branch?)
                          branch,
                      ].join(' · '),
                    ),
                    trailing: Text(inv.grandTotal?.toStringAsFixed(2) ?? ''),
                  ),
                ),
              if (onOpenInvoices != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => onOpenInvoices!(null),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: Text(context.l10n.b2bViewAllInvoices),
                  ),
                ),
            ]),
            // Collapsed by default for every account: reps do not log to it,
            // so it only takes space unless they ask for it.
            const SizedBox(height: 16),
            _CollapsibleHeader(
              key: const ValueKey('b2b-open-todos-header'),
              title: context.l10n.b2bAccountSectionWithCount(
                context.l10n.b2bSectionOpenTodos,
                account.openTodos.length,
              ),
              expanded: todosExpanded,
              onToggle: onToggleTodos,
            ),
            if (todosExpanded)
              if (account.openTodos.isEmpty)
                Text(context.l10n.b2bNone)
              else
                ...account.openTodos.map(
                  (todo) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.check_box_outline_blank),
                    title: Text(todo.description ?? todo.name),
                    subtitle: todo.date != null ? Text(todo.date!) : null,
                  ),
                ),
            SizedBox(height: trailingSpacer),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Material(
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: busy ? null : onSendSample,
                      icon: const Icon(Icons.science_outlined),
                      label: Text(context.l10n.b2bSendSample),
                    ),
                    FilledButton.icon(
                      onPressed: busy ? null : onPlaceOrder,
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: Text(context.l10n.b2bPlaceOrder),
                    ),
                    if (onMakeCustomer != null)
                      OutlinedButton.icon(
                        key: const ValueKey('b2b-make-customer'),
                        onPressed: busy ? null : onMakeCustomer,
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: Text(context.l10n.b2bCustomerSetupTitle),
                      ),
                    if (onLogCall != null)
                      OutlinedButton.icon(
                        onPressed: busy ? null : onLogCall,
                        icon: const Icon(Icons.call),
                        label: Text(context.l10n.b2bLogCall),
                      ),
                    if (onMarkLost != null)
                      OutlinedButton.icon(
                        onPressed: busy ? null : onMarkLost,
                        icon: const Icon(Icons.block),
                        label: Text(context.l10n.b2bMarkLost),
                      ),
                    if (onViewPricing != null)
                      OutlinedButton.icon(
                        onPressed: busy ? null : onViewPricing,
                        icon: const Icon(Icons.sell_outlined),
                        label: Text(context.l10n.b2bViewPricing),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: theme.textTheme.titleMedium),
        const Divider(),
        ...children,
      ],
    );
  }

  Widget _kv(BuildContext context, String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              key,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Disclosure toggle used by the collapsible sections: a leading chevron plus
/// the title. The caller owns the expanded flag (kept in the screen state so it
/// survives a reload).
class _CollapsibleToggle extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final bool expanded;
  final VoidCallback onToggle;

  const _CollapsibleToggle({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggle,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final materialL10n = MaterialLocalizations.of(context);
    return Semantics(
      button: true,
      expanded: expanded,
      child: Tooltip(
        message: expanded
            ? materialL10n.expandedIconTapHint
            : materialL10n.collapsedIconTapHint,
        child: InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(expanded ? Icons.expand_more : Icons.chevron_right),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: style ?? Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A [_CollapsibleToggle] followed by a divider, matching the plain `_section`
/// header look.
class _CollapsibleHeader extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onToggle;

  const _CollapsibleHeader({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CollapsibleToggle(
          title: title,
          expanded: expanded,
          onToggle: onToggle,
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// The journey diary behind a disclosure. Collapsed it shows only
/// "Journey (N)"; expanded it shows the shared [JourneyNotesSection] (with its
/// own "Log visit" button) beside a collapse chevron. The count comes from the
/// same provider the section reads, so it costs no extra request and the notes
/// are already loaded when the rep expands.
class _CollapsibleJourney extends ConsumerWidget {
  final String referenceDoctype;
  final String referenceName;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget section;

  const _CollapsibleJourney({
    super.key,
    required this.referenceDoctype,
    required this.referenceName,
    required this.expanded,
    required this.onToggle,
    required this.section,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expanded) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            key: const ValueKey('b2b-journey-collapse'),
            tooltip: MaterialLocalizations.of(context).expandedIconTapHint,
            visualDensity: VisualDensity.compact,
            onPressed: onToggle,
            icon: const Icon(Icons.expand_more),
          ),
          Expanded(child: section),
        ],
      );
    }
    final count = ref
        .watch(
          journeyNotesProvider(
            JourneyRef(doctype: referenceDoctype, name: referenceName),
          ),
        )
        .maybeWhen(data: (notes) => notes.length, orElse: () => null);
    final title = context.l10n.journeySectionTitle;
    return _CollapsibleToggle(
      key: const ValueKey('b2b-journey-expand'),
      title: count == null
          ? title
          : context.l10n.b2bAccountSectionWithCount(title, count),
      style: LeadsTheme.heading,
      expanded: false,
      onToggle: onToggle,
    );
  }
}

/// Every door of the shop, once each. Delivery branches (the Customer's named
/// shipping Addresses) carry their invoice totals plus, when one is known, the
/// matching Google Maps listing; Google Maps branches that are not delivery
/// branches yet follow, outlined, with the actions that fold them in.
class _BranchesSection extends ConsumerWidget {
  final List<B2bBranch> branches;
  final B2bBranchStats? unassigned;

  /// Whether the account can take a new delivery branch at all (has a
  /// Customer). [onAddBranch] is additionally null while busy.
  final bool showAddBranch;
  final VoidCallback? onAddBranch;

  /// Null with no Customer: there are no invoices to open.
  final void Function(String? branch)? onOpenInvoices;
  final void Function(B2bBranch maps, B2bBranch delivery)? onLinkMaps;
  final void Function(B2bBranch delivery)? onUnlinkMaps;
  final void Function(B2bBranch maps)? onPromoteMaps;
  final void Function(B2bBranch delivery)? onRename;

  const _BranchesSection({
    required this.branches,
    required this.unassigned,
    required this.showAddBranch,
    required this.onAddBranch,
    required this.onOpenInvoices,
    this.onLinkMaps,
    this.onUnlinkMaps,
    this.onPromoteMaps,
    this.onRename,
  });

  /// Google Maps branches still free to be combined with a delivery branch.
  List<B2bBranch> get _freeMaps =>
      branches.where((b) => b.isMapsOnly && b.mapsRow != null).toList();

  /// Delivery branches with no Google Maps branch yet.
  List<B2bBranch> get _freeDelivery => branches
      .where((b) => b.isDeliveryBranch && !b.hasMaps && b.key.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Territory ids are Woo codes; the cached territory list carries the
    // readable (Arabic) name. Falls back to the id while it loads.
    final territories =
        ref.watch(territoriesProvider(null)).valueOrNull ??
        const <Map<String, dynamic>>[];
    String territoryName(String id) {
      for (final row in territories) {
        if (row['name']?.toString() == id) return territoryLabelOf(row);
      }
      return territoryLabel(raw: id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.b2bBranchesTitleCount(branches.length),
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (showAddBranch)
              TextButton.icon(
                onPressed: onAddBranch,
                icon: const Icon(Icons.add_business_outlined, size: 18),
                label: Text(l10n.b2bAddBranch),
              ),
          ],
        ),
        const Divider(),
        if (branches.isEmpty) Text(l10n.b2bNoBranches),
        for (final branch in branches)
          if (branch.isMapsOnly)
            _mapsOnlyTile(context, branch)
          else
            _branchTile(context, branch, territoryName),
        if (unassigned case final stats? when onOpenInvoices != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.help_outline,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(l10n.b2bUnassignedInvoices),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.b2bUnassignedInvoicesHint),
                _statsLine(context, stats),
              ],
            ),
            onTap: () => onOpenInvoices!(B2bRepository.unassignedBranch),
          ),
      ],
    );
  }

  Widget _branchTile(
    BuildContext context,
    B2bBranch branch,
    String Function(String id) territoryName,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final location = [
      if (branch.territory case final id?) territoryName(id),
      if (branch.addressText.isNotEmpty) branch.addressText,
    ].where((s) => s.isNotEmpty).join(' · ');

    final actions = <PopupMenuEntry<_BranchAction>>[
      if (onRename != null && (branch.addressName?.isNotEmpty ?? false))
        _menuItem(_BranchAction.rename, Icons.edit_outlined, l10n.requestsEdit),
      if (branch.hasMaps && branch.mapsRow != null && onUnlinkMaps != null)
        _menuItem(
          _BranchAction.unlinkMaps,
          Icons.link_off,
          l10n.b2bBranchUnlinkMaps,
        ),
      if (!branch.hasMaps && _freeMaps.isNotEmpty && onLinkMaps != null)
        _menuItem(
          _BranchAction.linkMaps,
          Icons.add_link,
          l10n.b2bBranchLinkMaps,
        ),
    ];

    final open = onOpenInvoices;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.storefront_outlined),
      title: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(branch.displayName),
          if (branch.isPrimaryAddress)
            _chip(context, l10n.b2bPrimaryBranch, theme.colorScheme.primary),
          if (branch.territoryMissing)
            _chip(
              context,
              l10n.b2bTerritoryMissing,
              theme.colorScheme.error,
              icon: Icons.warning_amber_rounded,
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (location.isNotEmpty) Text(location),
          if (branch.maps case final maps?)
            _mapsLine(context, maps, autoMatched: branch.isMapsAutoMatched),
          _statsLine(context, branch.stats),
        ],
      ),
      trailing: _trailing(
        context,
        mapButton: _mapButton(context, branch),
        actions: actions,
        onAction: (action) => _onAction(context, action, branch),
      ),
      onTap: (branch.key.isEmpty || open == null)
          ? null
          : () => open(branch.key),
    );
  }

  /// A Google Maps branch that is not a delivery branch: outlined, pinned,
  /// with the actions that make it one or fold it into one.
  Widget _mapsOnlyTile(BuildContext context, B2bBranch branch) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final maps = branch.maps;
    final canLink = branch.mapsRow != null;
    final actions = <PopupMenuEntry<_BranchAction>>[
      if (canLink && onPromoteMaps != null)
        _menuItem(
          _BranchAction.makeDelivery,
          Icons.add_business_outlined,
          l10n.b2bBranchMakeDelivery,
        ),
      if (canLink && onLinkMaps != null && _freeDelivery.isNotEmpty)
        _menuItem(
          _BranchAction.sameAsExisting,
          Icons.merge_type,
          l10n.b2bBranchSameAsExisting,
        ),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsetsDirectional.only(start: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          Icons.location_on_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        title: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(branch.displayName),
            if (maps?.onTalabat ?? false)
              _chip(
                context,
                l10n.b2bBranchOnTalabat,
                theme.colorScheme.tertiary,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.b2bBranchMapsOnlySubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            if (maps != null) _mapsLine(context, maps),
            if ((maps?.address ?? '').isNotEmpty)
              Text(maps!.address!, style: theme.textTheme.bodySmall),
          ],
        ),
        trailing: _trailing(
          context,
          mapButton: _mapButton(context, branch),
          actions: actions,
          onAction: (action) => _onAction(context, action, branch),
        ),
      ),
    );
  }

  /// ★ rating (reviews) · area, led by a linked / auto-matched marker when it
  /// sits under a delivery branch.
  Widget _mapsLine(
    BuildContext context,
    B2bMapsInfo maps, {
    bool? autoMatched,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall;
    final area = maps.areaText;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (autoMatched != null)
            Tooltip(
              message: autoMatched
                  ? l10n.b2bBranchMapsAutoMatched
                  : l10n.b2bBranchMapsLinked,
              child: _chip(
                context,
                autoMatched
                    ? l10n.b2bBranchMapsAutoMatched
                    : l10n.b2bBranchMapsLinked,
                autoMatched
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary,
                icon: autoMatched ? Icons.auto_awesome : Icons.link,
              ),
            ),
          if (maps.rating case final rating?)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: LeadsTheme.gold,
                ),
                const SizedBox(width: 2),
                Text(
                  maps.reviews != null
                      ? '${rating.toStringAsFixed(1)} (${maps.reviews})'
                      : rating.toStringAsFixed(1),
                  style: style,
                ),
              ],
            ),
          if (area.isNotEmpty) Text(area, style: style),
        ],
      ),
    );
  }

  /// Opens the best pin for the door: the delivery address's own pin, else
  /// the Google Maps listing (its link, else its coordinates).
  Widget? _mapButton(BuildContext context, B2bBranch branch) {
    VoidCallback? open;
    final maps = branch.maps;
    final mapsUrl = maps?.mapsUrl?.trim() ?? '';
    if (branch.hasLocation) {
      open = () => LeadActions.mapsAt(branch.latitude!, branch.longitude!);
    } else if (LeadActions.isSafeMapsUrl(mapsUrl)) {
      open = () => LeadActions.maps(mapsUrl);
    } else if (maps != null && maps.hasLocation) {
      open = () => LeadActions.mapsAt(maps.latitude!, maps.longitude!);
    }
    if (open == null) return null;
    return IconButton(
      tooltip: context.l10n.b2bOpenBranchMap,
      icon: const Icon(Icons.map_outlined),
      onPressed: open,
    );
  }

  Widget? _trailing(
    BuildContext context, {
    required Widget? mapButton,
    required List<PopupMenuEntry<_BranchAction>> actions,
    required void Function(_BranchAction action) onAction,
  }) {
    if (actions.isEmpty) return mapButton;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mapButton != null) mapButton,
        PopupMenuButton<_BranchAction>(
          tooltip: context.l10n.b2bBranchActions,
          icon: const Icon(Icons.more_vert),
          onSelected: onAction,
          itemBuilder: (_) => actions,
        ),
      ],
    );
  }

  PopupMenuItem<_BranchAction> _menuItem(
    _BranchAction value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem<_BranchAction>(
      value: value,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(label),
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    _BranchAction action,
    B2bBranch branch,
  ) async {
    final l10n = context.l10n;
    switch (action) {
      case _BranchAction.rename:
        onRename?.call(branch);
      case _BranchAction.unlinkMaps:
        onUnlinkMaps?.call(branch);
      case _BranchAction.makeDelivery:
        onPromoteMaps?.call(branch);
      case _BranchAction.linkMaps:
        final picked = await _pickBranch(
          context,
          title: l10n.b2bBranchPickMapsTitle,
          options: _freeMaps,
        );
        if (picked != null) onLinkMaps?.call(picked, branch);
      case _BranchAction.sameAsExisting:
        final options = _freeDelivery;
        if (options.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.b2bBranchNoFreeDelivery)));
          return;
        }
        final picked = await _pickBranch(
          context,
          title: l10n.b2bBranchPickDeliveryTitle,
          options: options,
        );
        if (picked != null) onLinkMaps?.call(branch, picked);
    }
  }

  Future<B2bBranch?> _pickBranch(
    BuildContext context, {
    required String title,
    required List<B2bBranch> options,
  }) {
    return showDialog<B2bBranch>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(title),
        children: [
          for (final option in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, option),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  option.isMapsOnly
                      ? Icons.location_on_outlined
                      : Icons.storefront_outlined,
                ),
                title: Text(option.displayName),
                subtitle: _pickerSubtitle(option),
              ),
            ),
        ],
      ),
    );
  }

  Widget? _pickerSubtitle(B2bBranch option) {
    final text = option.isMapsOnly
        ? [
            if (option.maps?.areaText case final area? when area.isNotEmpty)
              area,
            if (option.maps?.rating case final rating?)
              '★ ${rating.toStringAsFixed(1)}',
          ].join(' · ')
        : option.addressText;
    return text.isEmpty ? null : Text(text);
  }

  Widget _statsLine(BuildContext context, B2bBranchStats stats) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final base = theme.textTheme.bodySmall;
    final billed = l10n.b2bBilledAmount(
      formatCurrency(context, stats.totalBilled),
    );
    final owed = l10n.b2bOutstandingAmount(
      formatCurrency(context, stats.outstanding),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: base,
            children: [
              TextSpan(text: l10n.b2bBranchInvoiceCount(stats.invoiceCount)),
              TextSpan(text: ' · $billed'),
              if (stats.outstanding > 0.005)
                TextSpan(
                  text: ' · $owed',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        Text(
          stats.lastOrderDate != null
              ? l10n.b2bLastOrderOn(stats.lastOrderDate!)
              : l10n.b2bNoOrdersYet,
          style: base,
        ),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    String text,
    Color color, {
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks for a branch's new name. Owns its controller, so the field stays
/// valid through the dialog's closing animation.
class _RenameBranchDialog extends StatefulWidget {
  final String initial;

  const _RenameBranchDialog({required this.initial});

  @override
  State<_RenameBranchDialog> createState() => _RenameBranchDialogState();
}

class _RenameBranchDialogState extends State<_RenameBranchDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.customerShippingAddressBranchNameLabel),
      content: TextField(
        key: const ValueKey('b2b-rename-branch-field'),
        controller: _controller,
        autofocus: true,
        maxLength: 140,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: l10n.customerShippingAddressBranchNameLabel,
        ),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

enum _BranchAction {
  rename,
  linkMaps,
  unlinkMaps,
  makeDelivery,
  sameAsExisting,
}

/// Printed-label stock for this account, one row per flavour, straight off the
/// account payload. Tapping a row opens the label's own detail screen; an
/// account with nothing tracked gets a "Set up labels" shortcut into the
/// wizard (shown only when a real Customer is linked — labels hang off the
/// Customer, not the Lead).
class _LabelsSection extends StatelessWidget {
  final B2bAccountLabels? labels;
  final void Function(String label)? onOpenLabel;
  final VoidCallback? onSetupLabels;

  const _LabelsSection({
    required this.labels,
    this.onOpenLabel,
    this.onSetupLabels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = labels;
    final empty = data == null || data.isEmpty;

    // No labels and no way to create any: stay out of the way entirely.
    if (empty && onSetupLabels == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              context.l10n.b2bLabelsSection,
              style: theme.textTheme.titleMedium,
            ),
            if (!empty && data.needsAttention > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFB3261E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  context.l10n.b2bLabelsNeedPrinting(data.needsAttention),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFB3261E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const Divider(),
        if (empty) ...[
          Text(
            context.l10n.b2bNoLabelsTracked,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: onSetupLabels,
              icon: const Icon(Icons.label_outline, size: 18),
              label: Text(context.l10n.b2bSetUpLabels),
            ),
          ),
        ] else
          ...data.flavours.map(
            (flavour) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.label_outline, size: 20),
              title: Text(flavour.title),
              subtitle: Text(
                [
                  if (flavour.size.isNotEmpty) flavour.size,
                  if (flavour.storageLocation.isNotEmpty)
                    labelLocationName(flavour.storageLocation),
                  '${flavour.onHandQty} on hand',
                ].join(' · '),
              ),
              trailing: LabelStatusChip(
                status: LabelStatus.parse(flavour.status),
                dense: true,
              ),
              onTap: (onOpenLabel == null || flavour.label.isEmpty)
                  ? null
                  : () => onOpenLabel!(flavour.label),
            ),
          ),
      ],
    );
  }
}

/// Read-only "Lead profile" enrichment for a Lead-backed B2B account. Fetches
/// the rich lead (`leads.get_lead`) independently of the main account load and
/// silently omits itself if the fetch fails or returns an empty record.
class _LeadProfileSection extends ConsumerStatefulWidget {
  const _LeadProfileSection({required this.leadName});

  final String leadName;

  @override
  ConsumerState<_LeadProfileSection> createState() =>
      _LeadProfileSectionState();
}

class _LeadProfileSectionState extends ConsumerState<_LeadProfileSection> {
  late final Future<Lead?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Lead?> _load() async {
    try {
      final lead = await ref
          .read(leadsRepositoryProvider)
          .getLead(widget.leadName);
      // Treat an empty record (no name / no display name) as "nothing to show".
      if (lead.name.trim().isEmpty && lead.leadName.trim().isEmpty) return null;
      return lead;
    } catch (_) {
      // Resilient by design: never break the account view if the lead is
      // unavailable.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Lead?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(context.l10n.b2bLoadingLeadProfile),
              ],
            ),
          );
        }
        final lead = snapshot.data;
        if (lead == null) return const SizedBox.shrink();
        return _LeadProfileCard(lead: lead);
      },
    );
  }
}

/// The compact, read-only lead card: score + tier/category/sahel chips, a
/// metrics row, contact quick-actions and addresses. The Google Maps branches
/// are not listed here: they sit in the account's unified branch section,
/// once each, alongside the delivery branches they match.
class _LeadProfileCard extends StatelessWidget {
  const _LeadProfileCard({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = <Widget>[
      if (lead.avgRating != null)
        _metric(
          Icons.star_rounded,
          '${lead.avgRating!.toStringAsFixed(1)} (${lead.totalReviews})',
          iconColor: LeadsTheme.gold,
        ),
      if (lead.primaryArea.trim().isNotEmpty)
        _metric(Icons.place_outlined, lead.primaryArea),
      if (lead.priceBand.trim().isNotEmpty)
        _metric(Icons.sell_outlined, lead.priceBand),
    ];

    final primaryAddress = _formatAddress(lead.primaryAddress);
    final shippingAddress = _formatAddress(lead.shippingAddress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(context.l10n.b2bLeadProfile, style: theme.textTheme.titleMedium),
        const Divider(),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LeadsTheme.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScoreBar(lead.score, width: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TierPill(lead.tier),
                        if (lead.category != null &&
                            lead.category!.trim().isNotEmpty)
                          CategoryChip(
                            category: LeadCategory(
                              name: lead.category!,
                              categoryName: lead.category!,
                            ),
                            selected: false,
                            onTap: () {},
                          ),
                        if (lead.sahelBranches > 0)
                          SahelBadge(lead.sahelBranches),
                      ],
                    ),
                  ),
                ],
              ),
              if (metrics.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: metrics),
              ],
              const SizedBox(height: 12),
              _contactActions(context),
              // The people at the venue, each one tap from a call. Read-only
              // here: the lead screen owns editing them.
              if (lead.contacts.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  context.l10n.leadContactsTitleCount(lead.contacts.length),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                for (final contact in lead.contacts)
                  _contactRow(context, contact),
              ],
              if (primaryAddress != null || shippingAddress != null) ...[
                const SizedBox(height: 12),
                if (primaryAddress != null)
                  _addressRow(
                    context,
                    context.l10n.leadDetailPrimaryAddress,
                    primaryAddress,
                  ),
                if (shippingAddress != null)
                  _addressRow(
                    context,
                    context.l10n.leadDetailShippingAddress,
                    shippingAddress,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// One person at the venue: name, title, and a call button.
  Widget _contactRow(BuildContext context, LeadContact contact) {
    final theme = Theme.of(context);
    final subtitle = [
      if (contact.role.trim().isNotEmpty) contact.role.trim(),
      if (contact.phone.trim().isNotEmpty) contact.phone.trim(),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          if (contact.isPrimary)
            const Padding(
              padding: EdgeInsetsDirectional.only(end: 4),
              child: Icon(Icons.star_rounded, size: 14, color: LeadsTheme.gold),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.displayName, style: theme.textTheme.bodyMedium),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          LeadActionButton(
            icon: Icons.call,
            tooltip: context.l10n.leadActionCall,
            enabled: contact.canCall,
            onTap: () => LeadActions.call(contact.phone),
          ),
        ],
      ),
    );
  }

  Widget _contactActions(BuildContext context) {
    // Falls back to the primary contact so a lead whose only number belongs to
    // a person is still one tap from a call.
    final callable = lead.callablePhone;
    final hasPhone = callable.isNotEmpty;
    final hasWebsite = lead.website.trim().isNotEmpty;
    final hasInstagram = lead.instagram.trim().isNotEmpty;
    final hasMaps =
        lead.mapsUrl.trim().isNotEmpty ||
        (lead.latitude != null && lead.longitude != null);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        LeadActionButton(
          icon: Icons.call,
          tooltip: context.l10n.leadActionCall,
          enabled: hasPhone,
          onTap: () => LeadActions.call(callable),
        ),
        LeadActionButton(
          icon: Icons.language,
          tooltip: context.l10n.leadActionWebsite,
          enabled: hasWebsite,
          onTap: () => LeadActions.website(lead.website),
        ),
        LeadActionButton(
          icon: Icons.camera_alt_outlined,
          tooltip: context.l10n.leadActionInstagram,
          color: LeadsTheme.berryPink,
          enabled: hasInstagram,
          onTap: () => LeadActions.instagram(lead.instagram),
        ),
        LeadActionButton(
          icon: Icons.map_outlined,
          tooltip: context.l10n.leadActionMap,
          enabled: hasMaps,
          onTap: () {
            if (lead.mapsUrl.trim().isNotEmpty) {
              LeadActions.maps(lead.mapsUrl);
            } else if (lead.latitude != null && lead.longitude != null) {
              LeadActions.mapsAt(lead.latitude!, lead.longitude!);
            }
          },
        ),
      ],
    );
  }

  Widget _metric(
    IconData icon,
    String text, {
    Color iconColor = LeadsTheme.muted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LeadsTheme.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: LeadsTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: LeadsTheme.deepPlum),
          ),
        ],
      ),
    );
  }

  Widget _addressRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  String? _formatAddress(LeadAddress? address) {
    if (address == null) return null;
    final parts = [
      address.addressLine1,
      address.addressLine2,
      address.city,
      address.state,
      address.country,
      address.pincode,
    ].where((s) => s.trim().isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }
}
