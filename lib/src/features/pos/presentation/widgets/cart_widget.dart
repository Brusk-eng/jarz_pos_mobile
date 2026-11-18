import 'package:jarz_pos/src/core/localization/user_error_message.dart';
import 'package:flutter/material.dart';
import 'package:jarz_pos/src/core/debug/app_error_reporter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/network/user_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/repositories/customer_address_repository.dart';
import '../../../../core/widgets/customer_shipping_address_flow.dart';
import '../../../../core/widgets/paste_icon_button.dart';
import '../../state/pos_notifier.dart';
import '../dialogs/payment_method_dialog.dart';
import '../dialogs/territory_profile_mismatch_dialog.dart';
import '../utils/amendment_refusal_message.dart';
import 'bundle_selection_widget.dart';
import 'delivery_pin_card.dart';
import 'delivery_slot_selection.dart';
import 'staff_member_picker.dart';
import '../../../../core/constants/business_constants.dart';
import '../../../../core/network/frappe_error_message.dart';
import '../../../credit/state/credit_providers.dart';
import '../../../../core/utils/territory_label.dart';

/// Uses the delivery branch's authoritative profile for B2B checkout. The
/// Customer-level territory may point at a different branch, so callers must
/// not replace a missing branch profile with the Customer default.
({String profileName, bool override})? b2bBranchProfileForCheckout(
  PosState state,
) {
  if (!state.isB2bOrder) return null;
  final branchProfile =
      state.selectedCustomer?['selected_shipping_address_territory_pos_profile']
          ?.toString()
          .trim() ??
      '';
  if (branchProfile.isEmpty) return null;
  return (profileName: branchProfile, override: false);
}

@visibleForTesting
void showMissingB2bBranchProfileError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.l10n.customerShippingAddressTerritoryMissing),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}

class CartWidget extends ConsumerWidget {
  final ScrollController? scrollController;
  const CartWidget({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(posNotifierProvider);
    final canManagePricing = ref
        .watch(userRolesFutureProvider)
        .maybeWhen(
          data: (roles) => roles.canAccessManagerDashboard,
          orElse: () => false,
        );
    final cartItems = state.cartItems;
    final hasAmendmentSource =
        !state.isAmendmentDraft ||
        ((state.amendmentSourceInvoiceId ?? '').trim().isNotEmpty);
    final customerTerritoryLabel = territoryLabel(
      nameAr: state.selectedCustomer?['territory_name_ar'],
      display: state.selectedCustomer?['territory_name'],
      raw: state.selectedCustomer?['territory'],
    );
    final customerTerritory = customerTerritoryLabel.isEmpty
        ? null
        : customerTerritoryLabel;
    final isPhone = ResponsiveUtils.isPhone(context);

    // Responsive padding
    final headerPadding = ResponsiveUtils.getResponsivePadding(
      context,
      small: 8,
      medium: 12,
      large: 16,
    );
    final contentPadding = ResponsiveUtils.getResponsivePadding(
      context,
      small: 5,
      medium: 8,
      large: 8,
    );

    final controller = scrollController ?? ScrollController();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: CustomScrollView(
        controller: controller,
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: headerPadding,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: isPhone
                        ? 18
                        : (ResponsiveUtils.isCompactLayout(context) ? 20 : 24),
                  ),
                  SizedBox(
                    width: ResponsiveUtils.getSpacing(
                      context,
                      small: isPhone ? 4 : 6,
                      medium: 8,
                      large: 8,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l10n.posCartHeader(cartItems.length),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: isPhone
                            ? 14
                            : (ResponsiveUtils.isCompactLayout(context)
                                  ? 14
                                  : 16),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (cartItems.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.clear_all,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: isPhone
                            ? 18
                            : (ResponsiveUtils.isCompactLayout(context)
                                  ? 20
                                  : 24),
                      ),
                      onPressed: () => _showClearCartDialog(context, ref),
                      tooltip: l10n.posCartClear,
                      padding: EdgeInsets.all(
                        isPhone
                            ? 4
                            : (ResponsiveUtils.isCompactLayout(context)
                                  ? 6
                                  : 8),
                      ),
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),

          if (canManagePricing && state.selectedProfile != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: contentPadding,
                child: _buildManagerPricingControls(context, ref, state),
              ),
            ),

          if (!canManagePricing &&
              state.isB2bOrder &&
              state.selectedProfile != null &&
              state.selectedCommercialPolicy != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: contentPadding,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildOrderPurposeControls(context, ref, state),
                  ),
                ),
              ),
            ),

          // Items or empty state
          if (cartItems.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyCart(context),
            )
          else
            SliverList.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final cartItem = cartItems[index];
                return Padding(
                  padding: contentPadding,
                  child: _buildCartItem(
                    context,
                    ref,
                    cartItem,
                    index,
                    canManagePricing: canManagePricing,
                  ),
                );
              },
            ),

          // Summary
          if (cartItems.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                padding: headerPadding,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Customer info
                    if (state.isAmendmentDraft)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isPhone ? 10 : 12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.edit_note,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.posAmendmentDraftTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    hasAmendmentSource
                                        ? l10n.posAmendmentDraftMessage
                                        : l10n.posAmendmentCheckoutBlocked,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (state.selectedCustomer != null)
                      Container(
                        padding: EdgeInsets.all(isPhone ? 10 : 12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.selectedCustomer!['customer_name'] ??
                                        l10n.posUnknownCustomer,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (state.isB2bOrder &&
                                      (state.selectedCustomer!['selected_shipping_branch_name'] ??
                                              '')
                                          .toString()
                                          .trim()
                                          .isNotEmpty)
                                    Text(
                                      state
                                          .selectedCustomer!['selected_shipping_branch_name']
                                          .toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                          ),
                                    ),
                                  if (state.isB2bOrder &&
                                      (state.selectedCustomer!['selected_shipping_address'] ??
                                              '')
                                          .toString()
                                          .trim()
                                          .isNotEmpty)
                                    Text(
                                      state
                                          .selectedCustomer!['selected_shipping_address']
                                          .toString(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            if (state.isB2bOrder)
                              IconButton(
                                onPressed: () => _changeB2bBranch(context, ref),
                                tooltip: l10n.b2bOrderChangeBranch,
                                icon: const Icon(Icons.edit_location_alt),
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                          ],
                        ),
                      ),

                    // Pickup toggle + Delivery Slot Selection
                    if (state.selectedProfile != null) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isPhone ? 10 : 12,
                          vertical: isPhone ? 6 : 8,
                        ),
                        margin: EdgeInsets.only(bottom: isPhone ? 6 : 8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Switch(
                              value: state.isPickup,
                              onChanged: (v) => ref
                                  .read(posNotifierProvider.notifier)
                                  .setPickup(v),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.posCartPickupTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    state.isPickup
                                        ? l10n.posCartPickupDescription
                                        : l10n.posCartDeliveryDescription,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (state.isPickup)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.store_mall_directory,
                                      size: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.posCartPickupChip,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    // Delivery needs a map pin on the address: ask for it here,
                    // not after the server refuses the order.
                    if (!state.isPickup &&
                        (state.selectedCustomer?['selected_shipping_address_name']
                                    ?.toString()
                                    .trim() ??
                                '')
                            .isNotEmpty)
                      DeliveryPinCard(
                        key: ValueKey(
                          'cart-pin-${state.selectedCustomer?['selected_shipping_address_name']}',
                        ),
                        addressName: state
                            .selectedCustomer!['selected_shipping_address_name']
                            .toString()
                            .trim(),
                      ),

                    if (!state.isPickup)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: DeliverySlotSelection(
                          posProfile: state.selectedProfile!['name'],
                          selectedSlot: state.selectedDeliverySlot,
                          onSlotChanged: (slot) {
                            ref
                                .read(posNotifierProvider.notifier)
                                .setDeliverySlot(slot);
                          },
                          // A counter-collected policy order has no slot to
                          // demand; see [PosState.collectsAtBranch].
                          isRequired: !state.collectsAtBranch,
                        ),
                      ),

                    // Subtotal and delivery
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.posSubtotalLabel,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontSize: isPhone ? 14 : null),
                        ),
                        Text(
                          '\$${state.cartTotal.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontSize: isPhone ? 14 : null),
                        ),
                      ],
                    ),

                    if (state.selectedSalesPartner == null &&
                        state.selectedCustomer != null &&
                        !state.isPickup) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  l10n.posDeliveryLabel,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontSize: isPhone ? 14 : null),
                                ),
                                if (state.customDeliveryIncome != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'custom',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSecondaryContainer,
                                          ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                state.customDeliveryIncome != null ||
                                        state.shippingCost > 0
                                    ? '\$${state.shippingCost.toStringAsFixed(2)}'
                                    : '—',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontSize: isPhone ? 14 : null),
                              ),
                              // Overriding the delivery income is a manager
                              // pricing action: the client sends
                              // suppress_legacy_delivery_charges alongside it,
                              // which the backend gates behind manager pricing
                              // access. Showing the control to staff only
                              // produced a "manager pricing access required"
                              // failure at checkout.
                              if (canManagePricing) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () =>
                                      _showDeliveryIncomeDialog(context, ref),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Promo codes
                    const _PromoCodeSection(),

                    if (state.promoDiscount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.l10n.posCartPromoDiscount,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontSize: isPhone ? 14 : null),
                          ),
                          Text(
                            '−\$${state.promoDiscount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: isPhone ? 14 : null,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],

                    if (state.promoFreeDelivery) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.posCartFreeDelivery,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: isPhone ? 14 : null,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],

                    if (state.promoDiscount > 0 || state.promoFreeDelivery) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.posTotalLabel,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: isPhone ? 18 : null,
                              ),
                        ),
                        Text(
                          '\$${state.displayTotalWithPromo.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: isPhone ? 18 : null,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Checkout button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.isLoading || !hasAmendmentSource
                            ? null
                            : () => _handleCheckout(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: state.isAmendmentDraft
                              ? Theme.of(context).colorScheme.secondaryContainer
                              : Theme.of(context).colorScheme.primary,
                          foregroundColor: state.isAmendmentDraft
                              ? Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer
                              : Theme.of(context).colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(
                            vertical: isPhone ? 12 : 14,
                          ),
                        ),
                        child: state.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                state.isAmendmentDraft
                                    ? l10n.posAmendmentDraftButton
                                    : l10n.posCheckoutButton,
                                style: TextStyle(
                                  fontSize: isPhone ? 14 : 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    // Shipping expense (operational info)
                    if (state.selectedSalesPartner == null &&
                        state.selectedCustomer != null &&
                        state.selectedCustomer!['delivery_expense'] != null &&
                        state.selectedCustomer!['delivery_expense'] > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.errorContainer.withValues(alpha: 0.1),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.posOperationalInfoTitle,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.posDeliveryLabel,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.8),
                                      ),
                                ),
                                Text(
                                  '\$${state.selectedCustomer!['delivery_expense'].toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              customerTerritory != null
                                  ? l10n.posDeliveryCostTo(customerTerritory)
                                  : l10n.posDeliveryCostGeneric,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _changeB2bBranch(BuildContext context, WidgetRef ref) async {
    final customer = ref.read(posNotifierProvider).selectedCustomer;
    final customerId = customer?['name']?.toString().trim() ?? '';
    if (customer == null || customerId.isEmpty) return;

    final selected = await chooseCustomerShippingAddress(
      context,
      customer: customer,
      repository: ref.read(customerAddressRepositoryProvider),
      forcePicker: true,
      requireBranchName: true,
      setAsPrimary: false,
    );
    if (selected == null || !context.mounted) return;
    final activeCustomer = ref
        .read(posNotifierProvider)
        .selectedCustomer?['name']
        ?.toString()
        .trim();
    if (activeCustomer != customerId) return;
    try {
      final applied = await ref
          .read(posNotifierProvider.notifier)
          .changeB2bBranch(selected);
      if (!applied &&
          context.mounted &&
          !ref.read(posNotifierProvider).b2bSetupComplete) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.b2bOrderPolicyUnavailable)),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.userErrorMessage(
              error,
              fallback: context.l10n.b2bOrderPolicyUnavailable,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildEmptyCart(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shopping_cart_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.posCartEmptyTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.posCartEmptyBody,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> cartItem,
    int index, {
    required bool canManagePricing,
  }) {
    final l10n = context.l10n;
    final isPhone = ResponsiveUtils.isPhone(context);
    double readAmount(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    final quantity = (cartItem['quantity'] ?? 1) as int;
    final rate = readAmount(cartItem['rate']);
    final baseRate = readAmount(
      cartItem['price_list_rate'] ?? cartItem['rate'],
    );
    final customRate = cartItem.containsKey('custom_rate_override')
        ? readAmount(cartItem['custom_rate_override'])
        : null;
    final discountAmount = cartItem.containsKey('discount_amount')
        ? readAmount(cartItem['discount_amount'])
        : null;
    final discountPercentage = cartItem.containsKey('discount_percentage')
        ? readAmount(cartItem['discount_percentage'])
        : null;
    final hasPricingOverride =
        customRate != null ||
        (discountAmount != null && discountAmount > 0) ||
        (discountPercentage != null && discountPercentage > 0);
    final total = quantity.toDouble() * rate;
    final isBundle = cartItem['type'] == 'bundle';
    final isShipping = cartItem['is_shipping'] == true;
    final itemName = cartItem['item_name']?.toString();
    final itemCode = cartItem['item_code']?.toString() ?? '';
    final stockQty = ref
        .read(posNotifierProvider.notifier)
        .getStockForItem(itemCode);
    final exceedsStock =
        !isShipping && stockQty.isFinite && quantity > stockQty;

    return Card(
      margin: EdgeInsets.only(bottom: isPhone ? 6 : 8),
      color: isShipping
          ? Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item name and action buttons
            Row(
              children: [
                if (isBundle)
                  Icon(
                    Icons.local_offer,
                    size: isPhone ? 14 : 16,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                if (isShipping)
                  Icon(
                    Icons.local_shipping,
                    size: isPhone ? 14 : 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                if (isBundle || isShipping) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    itemName ?? l10n.posUnknownItem,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isPhone ? 13 : null,
                      color: isShipping
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isBundle)
                  IconButton(
                    icon: Icon(Icons.edit, size: isPhone ? 16 : 18),
                    onPressed: () => _editBundle(context, ref, cartItem, index),
                    tooltip: l10n.posCartEditBundle,
                    visualDensity: VisualDensity.compact,
                  ),
                if (canManagePricing && !isShipping)
                  IconButton(
                    icon: Icon(Icons.price_change, size: isPhone ? 18 : 20),
                    onPressed: () =>
                        _showItemPricingDialog(context, ref, cartItem, index),
                    tooltip: l10n.posCartItemPricingDialogTitle,
                    visualDensity: VisualDensity.compact,
                  ),
                if (!isShipping) // Don't allow removing shipping items
                  IconButton(
                    icon: Icon(Icons.delete, size: isPhone ? 18 : 20),
                    onPressed: () => ref
                        .read(posNotifierProvider.notifier)
                        .removeFromCart(index),
                    color: Theme.of(context).colorScheme.error,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),

            // Show bundle items if it's a bundle
            if (isBundle && cartItem['_bundle_catalog_miss'] == true)
              _buildIncompleteBundleWarning(context)
            else if (isBundle && cartItem['bundle_details'] != null)
              _buildBundleDetails(context, cartItem['bundle_details']),

            if (hasPricingOverride) ...[
              SizedBox(height: isPhone ? 6 : 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (customRate != null)
                    _buildPricingChip(
                      context,
                      l10n.posCartItemCustomPriceApplied(
                        customRate.toStringAsFixed(2),
                      ),
                    ),
                  if (discountAmount != null && discountAmount > 0)
                    _buildPricingChip(
                      context,
                      l10n.posCartItemDiscountAmountApplied(
                        discountAmount.toStringAsFixed(2),
                      ),
                    ),
                  if (discountPercentage != null && discountPercentage > 0)
                    _buildPricingChip(
                      context,
                      l10n.posCartItemDiscountPercentApplied(
                        discountPercentage.toStringAsFixed(2),
                      ),
                    ),
                ],
              ),
            ],

            SizedBox(height: isPhone ? 6 : 8),

            // Price and quantity controls
            Row(
              children: [
                // Price per unit
                Text(
                  '\$${rate.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isShipping
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    fontSize: isPhone ? 13 : null,
                  ),
                ),
                if (baseRate > rate) ...[
                  const SizedBox(width: 8),
                  Text(
                    '\$${baseRate.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                const Spacer(),

                // Quantity controls (disabled for shipping items)
                if (!isShipping)
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, size: isPhone ? 18 : 20),
                        onPressed: quantity > 1
                            ? () => ref
                                  .read(posNotifierProvider.notifier)
                                  .updateCartItemQuantity(index, quantity - 1)
                            : null,
                        iconSize: isPhone ? 18 : 20,
                        visualDensity: VisualDensity.compact,
                      ),
                      Container(
                        constraints: BoxConstraints(
                          minWidth: isPhone ? 34 : 40,
                        ),
                        child: Text(
                          quantity.toString(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: isPhone ? 14 : null,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, size: isPhone ? 18 : 20),
                        onPressed: () => ref
                            .read(posNotifierProvider.notifier)
                            .updateCartItemQuantity(index, quantity + 1),
                        iconSize: isPhone ? 18 : 20,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  )
                else
                  // For shipping items, show quantity but make it non-editable
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${l10n.commonQtyLabel} $quantity',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            if (exceedsStock) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.itemGridStockLimitReached(stockQty.toInt()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Total for this item
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.posTotalLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: isPhone ? 13 : null,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isPhone ? 14 : null,
                    color: isShipping
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerPricingControls(
    BuildContext context,
    WidgetRef ref,
    PosState state,
  ) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final selectedPriceList = state.selectedPriceList;
    final zeroShippingDefault =
        selectedPriceList?['zero_shipping_default'] == true ||
        selectedPriceList?['zero_shipping_default'] == 1;
    final shippingSwitchLocked =
        state.isPickup || state.selectedSalesPartner != null;

    final helperText = shippingSwitchLocked
        ? (state.isPickup
              ? l10n.posCartZeroShippingManagedByPickup
              : l10n.posCartZeroShippingManagedByPartner)
        : (zeroShippingDefault
              ? l10n.posCartZeroShippingPriceListDefault
              : l10n.posCartZeroShippingDescription);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sell_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.posCartPricingTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // The purpose comes first because it decides the price list; the
            // operator never picks one, and the server refuses a contradicting
            // pair.
            if (state.availableCommercialPolicies.isNotEmpty) ...[
              _buildOrderPurposeControls(context, ref, state),
              const SizedBox(height: 12),
            ],
            _buildPriceListField(context, state),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: state.zeroShippingOverride,
              onChanged: shippingSwitchLocked || state.isLoading
                  ? null
                  : (value) {
                      ref
                          .read(posNotifierProvider.notifier)
                          .setZeroShippingOverride(value);
                    },
              title: Text(
                l10n.posCartZeroShippingTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(helperText),
            ),
          ],
        ),
      ),
    );
  }

  String _priceListLabel(Map<String, dynamic>? priceList) {
    final label = priceList?['display_label']?.toString().trim() ?? '';
    if (label.isNotEmpty) return label;
    return priceList?['name']?.toString().trim() ?? '';
  }

  /// The order's price list, always read-only: the order purpose decides it.
  ///
  ///  - Employee / Sample / B2B Supply, or the B2B launch flow → the purpose's
  ///    list with a lock and "set by the order purpose" (or "after customer");
  ///  - Standard / Free Shipping Waiver → the POS profile default, marked
  ///    "Default". The server refuses any other list on those orders.
  Widget _buildPriceListField(BuildContext context, PosState state) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final locked = state.isB2bOrder || state.isPriceListLockedByPurpose;
    final selectedName = state.selectedPriceListName;
    final awaitingCustomer =
        !state.isB2bOrder &&
        state.isB2bSupplyPurpose &&
        (state.selectedCustomer?['name']?.toString().trim().isEmpty ?? true);
    Map<String, dynamic>? option = state.selectedPriceList;
    for (final candidate in state.availablePriceLists) {
      if (candidate['name']?.toString().trim() == selectedName) {
        option = candidate;
        break;
      }
    }
    // Until B2B Supply knows its customer there is no list to show; the one
    // still loaded is only a placeholder that checkout will not send.
    final label = awaitingCustomer ? '' : _priceListLabel(option);
    final isDefault =
        option?['is_default'] == true || option?['is_default'] == 1;

    final Widget? suffix;
    if (locked) {
      suffix = const Icon(Icons.lock_outline);
    } else if (isDefault) {
      suffix = Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: Container(
          key: const ValueKey('price-list-default-chip'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            l10n.posCartPriceListDefaultChip,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    } else {
      suffix = null;
    }

    return InputDecorator(
      key: ValueKey(locked ? 'locked-price-list' : 'default-price-list'),
      isEmpty: label.isEmpty,
      decoration: InputDecoration(
        labelText: l10n.posCartPriceListLabel,
        helperText: !locked
            ? null
            : (awaitingCustomer
                  ? l10n.posCartPriceListAfterCustomer
                  : l10n.posCartPriceListSetByPurpose),
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
        enabled: false,
        suffixIcon: suffix,
        suffixIconConstraints: locked
            ? null
            : const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
      child: Text(label, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildOrderPurposeControls(
    BuildContext context,
    WidgetRef ref,
    PosState state,
  ) {
    final l10n = context.l10n;
    final policies = state.availableCommercialPolicies;
    final selected = state.selectedCommercialPolicy;
    final boundPurpose = state.boundB2bOrderPurpose?.trim().toLowerCase() ?? '';
    final selectablePolicies = state.isB2bOrder
        ? policies
              .where(
                (policy) =>
                    boundPurpose.isNotEmpty &&
                    policy.orderPurpose.trim().toLowerCase() == boundPurpose,
              )
              .toList()
        : policies;
    // Empty-string sentinel represents the "Standard" (no policy) option.
    const standardValue = '';
    final selectedValue = selected?.name ?? standardValue;
    final validSelectedValue = state.isB2bOrder
        ? (selectablePolicies.any((policy) => policy.name == selectedValue)
              ? selectedValue
              : null)
        : selectedValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('order-purpose-$selectedValue'),
          initialValue: validSelectedValue,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.posCartOrderPurposeLabel,
            helperText: l10n.posCartOrderPurposeHint,
            border: const OutlineInputBorder(),
          ),
          items: [
            if (!state.isB2bOrder)
              DropdownMenuItem<String>(
                value: standardValue,
                child: Text(
                  l10n.posCartOrderPurposeStandard,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ...selectablePolicies.map(
              (policy) => DropdownMenuItem<String>(
                value: policy.name,
                child: Text(policy.policyName, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged:
              state.isLoading ||
                  (state.isB2bOrder && selectablePolicies.length <= 1)
              ? null
              : (value) {
                  final notifier = ref.read(posNotifierProvider.notifier);
                  if (value == null || value == standardValue) {
                    notifier.setCommercialPolicy(null);
                    return;
                  }
                  final policy = selectablePolicies.firstWhere(
                    (p) => p.name == value,
                    orElse: () => selectablePolicies.first,
                  );
                  notifier.setCommercialPolicy(policy);
                },
        ),
        if (selected != null &&
            (selected.waivesShippingIncome ||
                selected.noCourier ||
                selected.deliverAtBranch)) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (selected.waivesShippingIncome)
                _buildPricingChip(
                  context,
                  l10n.posCartOrderPurposeWaivesShipping,
                ),
              if (selected.noCourier)
                _buildPricingChip(context, l10n.posCartOrderPurposeNoCourier),
              if (selected.deliverAtBranch)
                _buildPricingChip(
                  context,
                  l10n.posCartOrderPurposeDeliverAtBranch,
                ),
            ],
          ),
        ],
        // An Employee order is deducted from payroll only through the staff
        // customer, so the person is chosen here instead of a customer.
        if (state.isEmployeeOrder) ...[
          const SizedBox(height: 12),
          const StaffMemberControl(),
          const SizedBox(height: 8),
          const EmployeePaymentControl(),
        ],
        if (selected != null) ...[
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('policy-reason-${selected.name}'),
            initialValue: state.policyReason ?? '',
            minLines: 1,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.posCartOrderPurposeReasonLabel,
              helperText: l10n.posCartOrderPurposeReasonHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              ref.read(posNotifierProvider.notifier).setPolicyReason(value);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPricingChip(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  double? _parseNullableAmount(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  Future<void> _showItemPricingDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> cartItem,
    int index,
  ) async {
    final l10n = context.l10n;
    // Resolved before `showDialog`: the dialog's callbacks fire after an async
    // gap, when this widget (and therefore `ref`) may already be disposed.
    final posNotifier = ref.read(posNotifierProvider.notifier);
    double readAmount(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    final originalCatalogRate = readAmount(
      cartItem['original_catalog_rate'] ??
          cartItem['price_list_rate'] ??
          cartItem['rate'],
    );
    final hasOverrides =
        cartItem.containsKey('custom_rate_override') ||
        cartItem.containsKey('discount_amount') ||
        cartItem.containsKey('discount_percentage');
    final customRateController = TextEditingController(
      text: cartItem.containsKey('custom_rate_override')
          ? readAmount(cartItem['custom_rate_override']).toStringAsFixed(2)
          : '',
    );
    final discountAmountController = TextEditingController(
      text: cartItem.containsKey('discount_amount')
          ? readAmount(cartItem['discount_amount']).toStringAsFixed(2)
          : '',
    );
    final discountPercentController = TextEditingController(
      text: cartItem.containsKey('discount_percentage')
          ? readAmount(cartItem['discount_percentage']).toStringAsFixed(2)
          : '',
    );

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          String? validationError;
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              void savePricing() {
                final customRate = _parseNullableAmount(
                  customRateController.text,
                );
                final discountAmount = _parseNullableAmount(
                  discountAmountController.text,
                );
                final discountPercentage = _parseNullableAmount(
                  discountPercentController.text,
                );

                if ((customRateController.text.trim().isNotEmpty &&
                        customRate == null) ||
                    (discountAmountController.text.trim().isNotEmpty &&
                        discountAmount == null) ||
                    (discountPercentController.text.trim().isNotEmpty &&
                        discountPercentage == null)) {
                  setStateDialog(() {
                    validationError = l10n.posCartItemPricingInvalidNumber;
                  });
                  return;
                }
                if (customRate != null && customRate < 0) {
                  setStateDialog(() {
                    validationError = l10n.posCartItemPricingInvalidCustomRate;
                  });
                  return;
                }
                if (discountAmount != null && discountAmount < 0) {
                  setStateDialog(() {
                    validationError =
                        l10n.posCartItemPricingInvalidDiscountAmount;
                  });
                  return;
                }
                if (discountPercentage != null &&
                    (discountPercentage < 0 || discountPercentage > 100)) {
                  setStateDialog(() {
                    validationError =
                        l10n.posCartItemPricingInvalidDiscountPercent;
                  });
                  return;
                }
                if ((discountAmount ?? 0) > 0 &&
                    (discountPercentage ?? 0) > 0) {
                  setStateDialog(() {
                    validationError =
                        l10n.posCartItemPricingChooseSingleDiscount;
                  });
                  return;
                }

                final effectiveBase = customRate ?? originalCatalogRate;
                if ((discountAmount ?? 0) > effectiveBase) {
                  setStateDialog(() {
                    validationError = l10n.posCartItemPricingDiscountTooHigh;
                  });
                  return;
                }

                posNotifier.applyCartItemPricing(
                  index,
                  customRateOverride: customRate,
                  discountAmount: discountAmount,
                  discountPercentage: discountPercentage,
                );
                Navigator.of(dialogContext).pop();
              }

              return AlertDialog(
                title: Text(l10n.posCartItemPricingDialogTitle),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cartItem['item_name']?.toString() ??
                            l10n.posUnknownItem,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.posCartItemPricingBaseRate(
                          originalCatalogRate.toStringAsFixed(2),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: customRateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.posCartItemPricingCustomRateLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: discountAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.posCartItemPricingDiscountAmountLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: discountPercentController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText:
                              l10n.posCartItemPricingDiscountPercentLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.posCartItemPricingDiscountHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      if (validationError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          validationError!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  if (hasOverrides)
                    TextButton(
                      onPressed: () {
                        posNotifier.clearCartItemPricing(index);
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(l10n.posCartItemPricingReset),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.commonCancel),
                  ),
                  ElevatedButton(
                    onPressed: savePricing,
                    child: Text(l10n.posCartItemPricingSave),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      customRateController.dispose();
      discountAmountController.dispose();
      discountPercentController.dispose();
    }
  }

  void _showDeliveryIncomeDialog(BuildContext context, WidgetRef ref) {
    final state = ref.read(posNotifierProvider);
    // Resolved before `showDialog`: the dialog's actions run after an async gap.
    final posNotifier = ref.read(posNotifierProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(
      text: state.customDeliveryIncome != null
          ? state.customDeliveryIncome!.toStringAsFixed(2)
          : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.kanbanSetDeliveryIncome),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.posCartDeliveryAmountHelp,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: context.l10n.posCartDeliveryAmountField,
                prefixText: currencySymbol(context),
                hintText: '0.00',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              posNotifier.setCustomDeliveryIncome(null);
              Navigator.pop(ctx);
            },
            child: Text(context.l10n.posCartResetToDefault),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = controller.text.trim();
              if (raw.isEmpty) {
                posNotifier.setCustomDeliveryIncome(null);
              } else {
                final parsed = double.tryParse(raw);
                if (parsed == null || parsed < 0) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(context.l10n.kanbanInvalidAmount)),
                  );
                  return;
                }
                posNotifier.setCustomDeliveryIncome(parsed);
              }
              Navigator.pop(ctx);
            },
            child: Text(context.l10n.posCartSetAction),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Resolved before `showDialog`: the confirm action runs after an async gap.
    final posNotifier = ref.read(posNotifierProvider.notifier);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.posCartClearTitle),
        content: Text(l10n.posCartClearMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              posNotifier.clearCart();
              Navigator.pop(context);
            },
            child: Text(l10n.posCartClearConfirm),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    try {
      await _checkoutWithPreflight(context, ref);
    } catch (error, stackTrace) {
      AppErrorReporter.instance.capture(
        source: 'CheckoutPreflight',
        error: error,
        stackTrace: stackTrace,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userErrorMessageFor(l10n, error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _checkoutWithPreflight(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final state = ref.read(posNotifierProvider);
    final l10n = context.l10n;
    // Checkout spans several dialogs and a network round-trip. This widget can
    // be disposed at any of those async gaps, after which `ref` throws
    // ("Cannot use ref after the widget was disposed"), so capture everything
    // that depends on `ref` up front and re-check `context.mounted` before any
    // post-await `ref`/UI use. For a ConsumerWidget `context.mounted` tracks the
    // exact same element that backs `ref`.
    final posNotifier = ref.read(posNotifierProvider.notifier);

    // Refused before the payment dialogs: an Employee order with nobody to
    // deduct it from is an unattributable debt. The notifier refuses it too.
    if (state.isMissingStaffEmployee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.posStaffMemberRequired),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // A retail cart can be filled before the customer is chosen (an operator on
    // the phone with someone who has not given a name yet), so the customer is
    // enforced here instead of at the item grid. An amendment edits an order
    // that already has its customer and keeps its own handling.
    if (!state.isAmendmentDraft && state.selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.itemGridSelectCustomerWarning),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Validate delivery slot is selected. A counter-collected policy order
    // (staff purchase) is exempt like a pickup: the staff customer the backend
    // creates has no address, and nothing is delivered.
    if (!state.collectsAtBranch && state.selectedDeliverySlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.posDeliverySelectSlot),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final stockOverages = posNotifier.getCartItemsExceedingStock();
    if (stockOverages.isNotEmpty) {
      final proceed = await _confirmStockOverageCheckout(
        context,
        stockOverages,
      );
      if (proceed != true) {
        return;
      }
    }

    // Payment method selection for non-sales partner orders. An Employee order
    // sends none: see [PosState.skipsPaymentMethod].
    String? paymentMethod;
    final lockedPaymentMethod = state.amendmentLockedPaymentMethod;
    if (lockedPaymentMethod != null) {
      // Editing an already-paid order that still costs no more than was paid:
      // the carried payment settles it, so it keeps its method (see
      // [PosState.amendmentLockedPaymentMethod]). A dearer edit asks below.
      paymentMethod = lockedPaymentMethod;
    } else if (state.selectedSalesPartner == null && !state.skipsPaymentMethod) {
      if (!context.mounted) return;
      // Credit ("on account") is offered per order, and only for the customer
      // the order is actually on: the dialog resolves that customer's credit
      // profile itself. A B2B order also shows the row when the shop is NOT
      // approved, carrying the reason — a rep who expected credit has to know
      // why it is missing. B2C hides it instead of greying it on every sale.
      // An edited order is rebuilt from its invoice, which carries neither the
      // search row's `credit_allowed` nor the B2B flag, so it always asks the
      // live profile (warmed by the POS screen when the edit opened).
      final creditCustomer = (state.selectedCustomer?['name'] ?? '')
          .toString()
          .trim();
      paymentMethod = await PaymentMethodDialog.show(
        context,
        customer: creditCustomer,
        creditAllowedHint:
            state.selectedCustomer?['credit_allowed'] == true ||
            state.isAmendmentDraft,
        showCreditWhenNotAllowed: state.isB2bOrder,
        alreadyOnCredit:
            state.isAmendmentDraft &&
            state.selectedCustomer?['amendment_on_credit'] == true,
      );
      if (paymentMethod == null) {
        return; // user cancelled the dialog
      }
    }
    // Sales partner orders require choosing how the partner will pay
    String? paymentType;
    if (state.selectedSalesPartner != null) {
      if (!context.mounted) return;
      paymentType = await _promptSalesPartnerPayment(context);
      if (paymentType == null) {
        return; // user cancelled the dialog
      }
    }

    // Territory → POS profile preflight
    if (!context.mounted) return;
    final profileResolution = await _resolveProfileForCheckout(
      context,
      posNotifier,
      state,
    );
    if (profileResolution == null) return; // user cancelled

    await posNotifier.checkout(
      paymentType: paymentType,
      overridePosProfileName: profileResolution.profileName,
      paymentMethod: paymentMethod,
      posProfileOverride: profileResolution.override,
    );

    // The checkout itself is already committed; the snackbar is best-effort, so
    // bail out instead of touching a disposed `ref`/context.
    if (!context.mounted) return;
    final updatedState = ref.read(posNotifierProvider);

    if (updatedState.error == null) {
      // A credit order moves the shop's balance and its remaining headroom, so
      // the cached profile is stale the instant the invoice is submitted.
      final creditCustomerId = (state.selectedCustomer?['name'] ?? '')
          .toString()
          .trim();
      if (paymentMethod == PaymentModes.credit && creditCustomerId.isNotEmpty) {
        ref.invalidate(customerCreditProfileProvider(creditCustomerId));
      }
      // Read from the notifier captured before the await: checkout has
      // already reset the order, so the state no longer says it was cash.
      switch (posNotifier.lastEmployeeCashOutcome) {
        case EmployeeCashOutcome.savedOnCredit:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              key: const ValueKey('employee-cash-not-supported'),
              content: Text(l10n.posEmployeeCashNotSupported),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 10),
              showCloseIcon: true,
            ),
          );
        case EmployeeCashOutcome.paid:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.posCheckoutEmployeeCashPaid),
              backgroundColor: Colors.green,
            ),
          );
        case EmployeeCashOutcome.none:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.posCheckoutSuccess),
              backgroundColor: Colors.green,
            ),
          );
      }
    } else {
      // `PosNotifier.checkout` stores `e.toString()`, so a server refusal
      // arrives here as "Exception: <message>". `userErrorMessage` treats the
      // `Exception:` prefix as a technical signature and drops the whole
      // sentence, which turned a precise "credit limit exceeded" refusal into
      // a generic failure. Unwrap it first so the server's own message — the
      // only thing that names the limit and the shortfall — survives.
      final rawFailure = updatedState.error ?? l10n.commonError;
      final failure = extractFrappeErrorMessage(
        rawFailure,
        fallback: rawFailure,
      );
      // A refused order edit (`success: false`) is shown with the server's
      // reason as written; see [amendmentRefusalMessageFor].
      final rejection = posNotifier.amendmentRejection;
      // The server wants a map pin on the delivery address: say so plainly and
      // pull the cursor into the cart's pin field instead of a generic failure.
      final pinRefusal = posNotifier.addressPinRequired;
      if (pinRefusal != null) {
        ref.read(deliveryPinFocusRequestProvider.notifier).state++;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: pinRefusal != null
              ? const ValueKey('address-pin-required-snackbar')
              : null,
          content: Text(
            pinRefusal != null
                ? l10n.courierLaunchPinRequiredRefusal
                : rejection != null
                ? amendmentRefusalMessageFor(l10n, rejection.message)
                : context.userErrorMessage(failure),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<bool?> _confirmStockOverageCheckout(
    BuildContext context,
    List<Map<String, dynamic>> overages,
  ) {
    final l10n = context.l10n;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.posCheckoutStockExceedTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.posCheckoutStockExceedMessage),
              const SizedBox(height: 12),
              ...overages.map((item) {
                final itemName =
                    item['item_name']?.toString() ??
                    item['item_code']?.toString() ??
                    l10n.posUnknownItem;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    l10n.posCheckoutStockExceedLine(
                      itemName,
                      _formatQty(item['requested_qty']),
                      _formatQty(item['available_qty']),
                    ),
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.posCheckoutProceedAnyway),
          ),
        ],
      ),
    );
  }

  String _formatQty(dynamic value) {
    final qty = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    return qty == qty.roundToDouble()
        ? qty.toInt().toString()
        : qty.toStringAsFixed(2);
  }

  /// Rebuilds `selected_items` into the strongly typed shape the UI needs.
  ///
  /// The raw value is only a `Map<String, List<Map<String, dynamic>>>` when the
  /// cart was built in-memory this session. Once it round-trips through JSON
  /// (draft restore, offline cache) it comes back as `_Map<String, dynamic>`
  /// holding `List<dynamic>`, so a hard cast throws during build. Entries that
  /// don't match the expected shape are skipped rather than crashing the cart.
  Map<String, List<Map<String, dynamic>>> _normalizeBundleSelections(
    Object? rawSelections,
  ) {
    if (rawSelections is! Map) {
      return const <String, List<Map<String, dynamic>>>{};
    }

    final normalized = <String, List<Map<String, dynamic>>>{};
    rawSelections.forEach((key, value) {
      if (value is! Iterable) return;
      normalized[key.toString()] = value
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
    });
    return normalized;
  }

  /// Defensively coerces a JSON-decoded value into a `Map<String, dynamic>`.
  Map<String, dynamic>? _asStringKeyedMap(Object? value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  Widget _buildBundleDetails(BuildContext context, Object? rawBundleDetails) {
    final l10n = context.l10n;
    final bundleDetails = _asStringKeyedMap(rawBundleDetails);
    if (bundleDetails == null) return const SizedBox.shrink();

    final bundleInfo = _asStringKeyedMap(bundleDetails['bundle_info']);
    final groupLabels = _bundleGroupLabels(bundleInfo);
    final selectedItems = _normalizeBundleSelections(
      bundleDetails['selected_items'],
    );

    if (selectedItems.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.posBundleContentsTitle,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          ...selectedItems.entries.map((entry) {
            final groupName = _bundleGroupLabel(
              entry.key,
              entry.value,
              groupLabels,
            );
            final items = entry.value;
            // Group identical items by name and show count
            final counts = <String, int>{};
            for (final item in items) {
              final name = (item['name'] ?? '').toString();
              counts[name] = (counts[name] ?? 0) + 1;
            }
            final summary = counts.entries
                .map((e) {
                  return e.value > 1 ? '${e.key} x${e.value}' : e.key;
                })
                .join(', ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '$groupName: $summary',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildIncompleteBundleWarning(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: colorScheme.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              context.l10n.posCartBundleLoadFailed,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _bundleGroupLabels(Map<String, dynamic>? bundleInfo) {
    final labels = <String, String>{};
    final itemGroups = bundleInfo?['item_groups'] as List<dynamic>? ?? const [];

    for (var index = 0; index < itemGroups.length; index++) {
      final group = Map<String, dynamic>.from(itemGroups[index] as Map);
      final groupKey = _bundleGroupKey(group, index);
      final label =
          (group['group_name'] ?? group['item_group'] ?? group['title'])
              ?.toString()
              .trim();
      if (label != null && label.isNotEmpty) {
        labels[groupKey] = label;
      }
    }

    return labels;
  }

  String _bundleGroupKey(Map<String, dynamic> group, int fallbackIndex) {
    final rawKey = (group['group_key'] ?? group['group_id'] ?? group['name'])
        ?.toString()
        .trim();
    if (rawKey != null && rawKey.isNotEmpty) {
      return rawKey;
    }

    final rawIndex =
        group['group_index'] ?? group['idx'] ?? (fallbackIndex + 1);
    return '${_bundleLegacyGroupLabel((group['group_name'] ?? group['item_group'] ?? group['title'] ?? 'Group').toString())}::$rawIndex';
  }

  String _bundleGroupLabel(
    String key,
    List<Map<String, dynamic>> items,
    Map<String, String> labels,
  ) {
    final resolvedLabel = labels[key];
    if (resolvedLabel != null && resolvedLabel.isNotEmpty) {
      return resolvedLabel;
    }

    if (items.isNotEmpty) {
      final itemLabel = items.first['group_name']?.toString().trim();
      if (itemLabel != null && itemLabel.isNotEmpty) {
        return itemLabel;
      }
    }

    return _bundleLegacyGroupLabel(key);
  }

  String _bundleLegacyGroupLabel(String key) {
    final separatorIndex = key.lastIndexOf('::');
    if (separatorIndex > 0) {
      return key.substring(0, separatorIndex);
    }
    return key;
  }

  Future<String?> _promptSalesPartnerPayment(BuildContext context) async {
    String selected = PaymentModes.cashLower;
    final l10n = context.l10n;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.posSalesPartnerPaymentTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.posSalesPartnerPaymentDescription),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment<String>(
                    value: PaymentModes.cashLower,
                    label: Text(l10n.posSalesPartnerPaymentCash),
                    icon: const Icon(Icons.attach_money),
                  ),
                  ButtonSegment<String>(
                    value: PaymentModes.onlineLower,
                    label: Text(l10n.posSalesPartnerPaymentOnline),
                    icon: const Icon(Icons.online_prediction),
                  ),
                ],
                selected: <String>{selected},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) return;
                  setState(() => selected = selection.first);
                },
                showSelectedIcon: false,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(selected),
              child: Text(l10n.commonContinue),
            ),
          ],
        ),
      ),
    );
  }

  /// Determines which POS profile to use for checkout, prompting the user if
  /// the selected profile doesn't match the customer's territory profile.
  ///
  /// Returns `null` when the user cancels, or a record with the chosen profile
  /// name and whether `pos_profile_override` should be sent.
  ///
  /// Takes an already-resolved [posNotifier] rather than a [WidgetRef]: this
  /// runs after the payment dialogs, so `ref` may no longer be usable.
  Future<({String profileName, bool override})?> _resolveProfileForCheckout(
    BuildContext context,
    PosNotifier posNotifier,
    PosState state,
  ) async {
    if (state.isB2bOrder) {
      final resolution = b2bBranchProfileForCheckout(state);
      if (resolution == null && context.mounted) {
        showMissingB2bBranchProfileError(context);
      }
      return resolution;
    }

    final selectedProfileName =
        state.selectedProfile?['name']?.toString() ?? '';
    if (selectedProfileName.isEmpty) return null;

    final customer = state.selectedCustomer;
    final customerName = customer?['name']?.toString() ?? '';
    final isWalkingCustomer =
        customerName.isEmpty || customerName == 'Walking Customer';

    if (isWalkingCustomer) {
      // No territory → show dialog with only the "keep selected" option
      if (!context.mounted) return null;
      final choice = await TerritoryProfileMismatchDialog.show(
        context,
        selectedProfile: selectedProfileName,
        territoryProfile: null,
      );
      if (choice == null) return null;
      return (profileName: choice.profileName, override: choice.override);
    }

    // Fetch the POS profile mapped to the customer's territory (null = none)
    final territoryProfile = await posNotifier.getTerritoryPosProfile(
      customerName,
    );

    // A counter-collected policy order belongs to the branch it is rung up
    // at: a freshly created staff customer has no territory, so the mismatch
    // question has only one answer. Take it ("keep selected") without asking.
    if (state.selectedCommercialPolicy?.deliverAtBranch ?? false) {
      final matches =
          territoryProfile != null &&
          territoryProfile.isNotEmpty &&
          territoryProfile == selectedProfileName;
      return (profileName: selectedProfileName, override: !matches);
    }

    // Profiles match → proceed silently, no override needed
    if (territoryProfile != null &&
        territoryProfile.isNotEmpty &&
        territoryProfile == selectedProfileName) {
      return (profileName: selectedProfileName, override: false);
    }

    // Mismatch (or no territory mapping) → ask the user
    if (!context.mounted) return null;
    final choice = await TerritoryProfileMismatchDialog.show(
      context,
      selectedProfile: selectedProfileName,
      territoryProfile: territoryProfile,
    );
    if (choice == null) return null;
    return (profileName: choice.profileName, override: choice.override);
  }

  void _editBundle(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> cartItem,
    int index,
  ) {
    final bundleDetails = _asStringKeyedMap(cartItem['bundle_details']);
    if (bundleDetails == null) return;

    final bundleInfo = _asStringKeyedMap(bundleDetails['bundle_info']);
    final currentSelections = _normalizeBundleSelections(
      bundleDetails['selected_items'],
    );

    if (bundleInfo == null) return;

    // Captured before the dialog opens: these callbacks run after an async gap,
    // by which point `ref` may already be disposed.
    final posNotifier = ref.read(posNotifierProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final bundleUpdatedMessage = context.l10n.posBundleUpdated;
    final isPhone = ResponsiveUtils.isPhone(context);

    final bundleWidget = BundleSelectionWidget(
      bundle: bundleInfo,
      initialSelections: currentSelections,
      isEditing: true,
      onCancel: () => Navigator.of(context).pop(),
      onBundleSelected: (selectedItems) {
        Navigator.of(context).pop();
        posNotifier.updateBundleInCart(index, selectedItems);
        messenger.showSnackBar(
          SnackBar(
            content: Text(bundleUpdatedMessage),
            backgroundColor: Colors.green,
          ),
        );
      },
    );

    if (isPhone) {
      showDialog(
        context: context,
        barrierDismissible: true,
        useSafeArea: false,
        builder: (context) => Dialog.fullscreen(child: bundleWidget),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.getDialogWidth(
                context,
                small: 800,
                medium: 800,
                large: 800,
              ),
              maxHeight: ResponsiveUtils.getDialogHeight(
                context,
                phoneFraction: 0.9,
                tabletFraction: 0.78,
                max: 600,
              ),
            ),
            child: bundleWidget,
          ),
        ),
      );
    }
  }
}

/// Promo-code entry + applied-code chips for the cart totals block.
///
/// Owns its own [TextEditingController]. The discount itself is display-only —
/// the backend re-computes authoritatively at invoice creation.
class _PromoCodeSection extends ConsumerStatefulWidget {
  const _PromoCodeSection();

  @override
  ConsumerState<_PromoCodeSection> createState() => _PromoCodeSectionState();
}

class _PromoCodeSectionState extends ConsumerState<_PromoCodeSection> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    await ref.read(posNotifierProvider.notifier).applyPromoCode(code);
    // `_controller` is disposed with this State; clearing it after the await
    // would throw if the user left the screen while the code was applying.
    if (!mounted) return;
    _controller.clear();
  }

  /// Find the preview result entry for [code] (rejected codes carry a reason).
  Map<String, dynamic>? _resultFor(
    List<Map<String, dynamic>> results,
    String code,
  ) {
    for (final r in results) {
      if (r['code']?.toString().toUpperCase() == code.toUpperCase()) {
        return r;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posNotifierProvider);
    final theme = Theme.of(context);
    final isPhone = ResponsiveUtils.isPhone(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _apply(),
                decoration: InputDecoration(
                  labelText: context.l10n.posCartPromoCode,
                  hintText: context.l10n.posCartPromoCodeHint,
                  isDense: true,
                  border: OutlineInputBorder(),
                  suffixIcon: PasteIconButton(
                    controller: _controller,
                    replace: true,
                    transform: (s) => s.replaceAll(' ', '').toUpperCase(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: isPhone ? 44 : 48,
              child: ElevatedButton(
                onPressed: state.promoLoading ? null : _apply,
                child: state.promoLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.l10n.kanbanFilterApply),
              ),
            ),
          ],
        ),
        if (state.appliedPromoCodes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: state.appliedPromoCodes.map((code) {
              final result = _resultFor(state.promoResults, code);
              final accepted = result?['accepted'] == true;
              final reason = result?['reason']?.toString();
              return Tooltip(
                message: accepted
                    ? (reason ?? context.l10n.posCartPromoApplied)
                    : (reason ?? context.l10n.posCartPromoNotEligible),
                child: Chip(
                  label: Text(
                    code,
                    style: TextStyle(
                      color: accepted
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onErrorContainer,
                      fontSize: 12,
                    ),
                  ),
                  avatar: Icon(
                    accepted ? Icons.check_circle : Icons.error_outline,
                    size: 16,
                    color: accepted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                  backgroundColor: accepted
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.errorContainer,
                  onDeleted: () => ref
                      .read(posNotifierProvider.notifier)
                      .removePromoCode(code),
                  deleteIconColor: accepted
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onErrorContainer,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
          // Surface the reason for any rejected code as an inline subtitle.
          ...state.promoResults.where((r) => r['accepted'] != true).map((r) {
            final code = r['code']?.toString() ?? '';
            final reason =
                r['reason']?.toString() ?? context.l10n.posCartPromoNotEligible;
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$code: $reason',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
