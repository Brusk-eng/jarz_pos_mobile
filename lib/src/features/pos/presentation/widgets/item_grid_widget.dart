import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../state/pos_notifier.dart';
import 'bundle_selection_widget.dart';

class ItemGridWidget extends ConsumerStatefulWidget {
  /// Optional animation (1.0=visible, 0.0=hidden) to collapse filter chips
  /// on phones when scrolling.
  final Animation<double>? hideAnimation;

  const ItemGridWidget({super.key, this.hideAnimation});

  @override
  ConsumerState<ItemGridWidget> createState() => _ItemGridWidgetState();
}

class _ItemGridWidgetState extends ConsumerState<ItemGridWidget> {
  String? selectedCategory;

  /// Whether the grid may add to the cart before a customer is chosen.
  ///
  /// A retail order can be built while the customer is still on the phone and
  /// has not given a name yet: prices come from the POS profile, the delivery
  /// fee is worked out at checkout from the customer's address, and checkout
  /// refuses until a customer is picked. A B2B order cannot: its catalogue and
  /// prices belong to the customer's branch, so it stays gated on the customer.
  /// Set from the watched state at the top of [build].
  bool _customerRequiredToAdd = false;

  bool _canAddToCart(Map<String, dynamic>? selectedCustomer) =>
      selectedCustomer != null || !_customerRequiredToAdd;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(posNotifierProvider.select((state) => state.items));
    final bundles = ref.watch(
      posNotifierProvider.select((state) => state.bundles),
    );
    final selectedCustomer = ref.watch(
      posNotifierProvider.select((state) => state.selectedCustomer),
    );
    _customerRequiredToAdd = ref.watch(
      posNotifierProvider.select((state) => state.isB2bOrder),
    );
    // Watching the list itself (not a derived map) keeps the rebuild scoped to
    // actual cart mutations — copyWith reuses the same list otherwise.
    final cartItems = ref.watch(
      posNotifierProvider.select((state) => state.cartItems),
    );
    final cartQuantities = _buildCartQuantityIndex(cartItems);

    // Group items by category and ensure Bundles is first
    final itemsByCategory = <String, List<Map<String, dynamic>>>{};

    // Add bundles first if they exist
    if (bundles.isNotEmpty) {
      itemsByCategory[context.l10n.itemGridBundles] = bundles;
    }

    // Then add item categories
    for (final item in items) {
      final category = item['item_group'] ?? context.l10n.itemGridUncategorized;
      itemsByCategory.putIfAbsent(category, () => []).add(item);
    }

    // Filter items based on search and category
    final filteredData = _getFilteredData(items, bundles);

    final isPhone = ResponsiveUtils.isPhone(context);
    final hideAnim = widget.hideAnimation;

    // Filter chips — collapsible on phones when scrolling
    Widget filterChips = const SizedBox.shrink();
    if (itemsByCategory.isNotEmpty) {
      final chipContent = Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            FilterChip(
              label: Text(context.l10n.itemGridAll),
              selected: selectedCategory == null,
              onSelected: (selected) {
                setState(() { selectedCategory = null; });
              },
            ),
            const SizedBox(width: 8),
            ...itemsByCategory.keys.map(
              (category) => Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: selectedCategory == category,
                  onSelected: (selected) {
                    setState(() { selectedCategory = selected ? category : null; });
                  },
                ),
              ),
            ),
          ],
        ),
      );

      filterChips = (isPhone && hideAnim != null)
          ? ClipRect(
              child: SizeTransition(
                sizeFactor: hideAnim,
                axisAlignment: -1.0,
                child: chipContent,
              ),
            )
          : chipContent;
    }

    final spacingAfterFilters = isPhone ? 8.0 : 16.0;

    return Column(
      children: [
        filterChips,

        SizedBox(height: spacingAfterFilters),

        // Customer selection warning
        // Customer selection reminder. Blocking (error colours) only where the
        // customer gates adding; otherwise a reminder that checkout needs one.
        if (selectedCustomer == null)
          Container(
            margin: EdgeInsets.symmetric(horizontal: isPhone ? 10 : 16, vertical: isPhone ? 6 : 8),
            padding: EdgeInsets.all(isPhone ? 10 : 12),
            decoration: BoxDecoration(
              color: _customerRequiredToAdd
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _customerRequiredToAdd
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.secondary,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _customerRequiredToAdd ? Icons.warning : Icons.person_search,
                  color: _customerRequiredToAdd
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.itemGridSelectCustomerWarning,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _customerRequiredToAdd
                          ? Theme.of(context).colorScheme.onErrorContainer
                          : Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Items grid
        Expanded(
          child: filteredData.isEmpty
              ? _buildEmptyState()
              : _buildItemsView(
                  filteredData,
                  itemsByCategory,
                  selectedCustomer,
                  cartQuantities,
                ),
        ),
      ],
    );
  }

  Widget _buildItemsView(
    List<Map<String, dynamic>> items,
    Map<String, List<Map<String, dynamic>>> itemsByCategory,
    Map<String, dynamic>? selectedCustomer,
    Map<String, int> cartQuantities,
  ) {
    final isPhone = ResponsiveUtils.isPhone(context);
    // If "All" is selected and no search, show categorized view
    if (selectedCategory == null && itemsByCategory.isNotEmpty) {
      return _buildCategorizedView(
        itemsByCategory,
        selectedCustomer,
        cartQuantities,
      );
    }

    // Otherwise show filtered grid
    final columns = ResponsiveUtils.getItemGridColumns(context);
    final spacing = ResponsiveUtils.getSpacing(context, small: 5, medium: 8, large: 8);
    final aspectRatio = ResponsiveUtils.getGridAspectRatio(context, compact: 1.6, normal: 1.5);
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isPhone ? 8 : 16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns, // Responsive: 2-5 columns based on screen size
          crossAxisSpacing: isPhone ? 5 : spacing,
          mainAxisSpacing: isPhone ? 5 : spacing,
          childAspectRatio: aspectRatio,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isBundle = item['type'] == 'bundle';
          return isBundle
              ? _buildBundleCard(item, selectedCustomer, cartQuantities)
              : _buildItemCard(item, selectedCustomer, cartQuantities);
        },
      ),
    );
  }

  Widget _buildCategorizedView(
    Map<String, List<Map<String, dynamic>>> itemsByCategory,
    Map<String, dynamic>? selectedCustomer,
    Map<String, int> cartQuantities,
  ) {
    final isPhone = ResponsiveUtils.isPhone(context);
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: isPhone ? 10 : 16),
      itemCount: itemsByCategory.keys.length,
      itemBuilder: (context, index) {
        final category = itemsByCategory.keys.elementAt(index);
        final categoryItems = itemsByCategory[category]!;
        final isBundleCategory = category == context.l10n.itemGridBundles;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isBundleCategory
                          ? Theme.of(context).colorScheme.tertiaryContainer
                          : Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isBundleCategory)
                          Icon(
                            Icons.local_offer,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onTertiaryContainer,
                          ),
                        if (isBundleCategory) const SizedBox(width: 4),
                        Text(
                          category,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: isBundleCategory
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onTertiaryContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${isBundleCategory ? context.l10n.itemGridBundlesCount(categoryItems.length) : context.l10n.itemGridItemsCount(categoryItems.length)})',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Category items grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveUtils.getItemGridColumns(context), // Responsive columns
                crossAxisSpacing: ResponsiveUtils.getSpacing(context, small: 6, medium: 8, large: 8),
                mainAxisSpacing: ResponsiveUtils.getSpacing(context, small: 6, medium: 8, large: 8),
                childAspectRatio: ResponsiveUtils.getGridAspectRatio(context, compact: 1.35, normal: 1.4),
              ),
              itemCount: categoryItems.length,
              itemBuilder: (context, itemIndex) {
                final item = categoryItems[itemIndex];
                return isBundleCategory
                    ? _buildBundleCard(item, selectedCustomer, cartQuantities)
                    : _buildItemCard(item, selectedCustomer, cartQuantities);
              },
            ),

            const SizedBox(height: 20), // Space between categories
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _getFilteredData(
    List<Map<String, dynamic>> items,
    List<Map<String, dynamic>> bundles,
  ) {
    List<Map<String, dynamic>> allData = [];

    // Add items with type marker
    allData.addAll(items.map((item) => {...item, 'type': 'item'}));

    // Add bundles with type marker
    allData.addAll(bundles.map((bundle) => {...bundle, 'type': 'bundle'}));

    var filtered = allData;

    // Filter by category
    if (selectedCategory != null) {
      if (selectedCategory == 'Bundles' || selectedCategory == context.l10n.itemGridBundles) {
        filtered = filtered.where((item) => item['type'] == 'bundle').toList();
      } else {
        filtered = filtered
            .where(
              (item) =>
                  item['type'] == 'item' &&
                  item['item_group'] == selectedCategory,
            )
            .toList();
      }
    }

    return filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            selectedCategory != null
                ? context.l10n.itemGridNoItemsFound
                : context.l10n.itemGridNoItemsAvailable,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            selectedCategory != null
                ? context.l10n.itemGridTryDifferentCategory
                : context.l10n.itemGridItemsWillAppear,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBundleCard(
    Map<String, dynamic> bundle,
    Map<String, dynamic>? selectedCustomer,
    Map<String, int> cartQuantities,
  ) {
    final isPhone = ResponsiveUtils.isPhone(context);
    final canAddToCart = _canAddToCart(selectedCustomer);
    final hasFreeShipping = (bundle['free_shipping'] == true);
    final cartQty = cartQuantities[bundle['id']?.toString().trim() ?? ''] ?? 0;

    return Card(
      elevation: cartQty > 0 ? 3 : 1,
      shape: _cardShape(cartQty),
      child: InkWell(
        onTap: canAddToCart
            ? () {
                _showBundleSelection(bundle);
              }
            : () {
                _showCannotAddToCartMessage(selectedCustomer, false);
              },
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_offer,
                  size: isPhone ? 16 : 20,
                  color: !canAddToCart
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(height: 2),
                Text(
                  bundle['name'] ?? context.l10n.bundleUnknownBundle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: !canAddToCart
                        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                        : null,
                    fontWeight: FontWeight.bold,
                    fontSize: isPhone ? 12 : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${(bundle['price'] ?? 0.0).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: !canAddToCart
                        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                        : Theme.of(context).colorScheme.tertiary,
                    fontSize: isPhone ? 12 : null,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (hasFreeShipping)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_shipping, size: 12, color: Theme.of(context).colorScheme.onSecondaryContainer),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.itemGridFreeDelivery,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (cartQty > 0) _buildCartQtyBadge(cartQty),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    Map<String, dynamic> item,
    Map<String, dynamic>? selectedCustomer,
    Map<String, int> cartQuantities,
  ) {
    final isPhone = ResponsiveUtils.isPhone(context);
    final cartQty = cartQuantities[item['name']?.toString().trim() ?? ''] ?? 0;
    // Extract stock information
    final stockQty = (item['actual_qty'] ?? 0).toDouble();
    final isOutOfStock = stockQty <= 0;
    // Debug: Log the stock values for comparison
    if (kDebugMode) {
      debugPrint(
        'Main item ${item['item_name']} - actual_qty: ${item['actual_qty']}, final stock: $stockQty',
      );
    }
    final canAddToCart = _canAddToCart(selectedCustomer);

    // Determine stock color based on quantity
    Color stockColor;
    if (stockQty <= 0) {
      stockColor = Colors.red;
    } else if (stockQty <= 20) {
      stockColor = Colors.orange;
    } else {
      stockColor = Colors.green;
    }

    return Card(
      elevation: cartQty > 0 ? 3 : 1,
      shape: _cardShape(cartQty),
      child: InkWell(
        onTap: canAddToCart
            ? () {
                final notifier = ref.read(posNotifierProvider.notifier);
                final added = notifier.addToCart(item);
                if (added) {
                  final itemCode = item['name']?.toString() ?? '';
                  if (notifier.cartItemExceedsAvailableStock(itemCode)) {
                    _showStockLimitMessage(stockQty.toInt());
                  } else {
                    _showAddedToCartSnackbar(item);
                  }
                } else {
                  _showCannotAddToCartMessage(selectedCustomer, false);
                }
              }
            : () {
                _showCannotAddToCartMessage(selectedCustomer, isOutOfStock);
              },
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Main card content
            Padding(
              padding: EdgeInsets.all(isPhone ? 3 : 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['item_name'] ??
                        item['name'] ??
                        context.l10n.bundleUnknownItem,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: !canAddToCart
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5)
                          : null,
                      fontWeight: FontWeight.bold,
                      fontSize: isPhone ? 11 : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${item['rate']?.toStringAsFixed(2) ?? '0.00'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: !canAddToCart
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5)
                          : Theme.of(context).colorScheme.primary,
                      fontSize: isPhone ? 11 : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Small stock indicator in top-right corner
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: stockColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      stockQty <= 0 ? Icons.warning : Icons.inventory,
                      size: 9,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${stockQty.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // How many of this item are already in the cart
            if (cartQty > 0) _buildCartQtyBadge(cartQty),
          ],
        ),
      ),
    );
  }

  /// item_code / bundle_id → total quantity currently in the cart, so each
  /// catalog card can show its own counter without re-scanning the cart.
  Map<String, int> _buildCartQuantityIndex(
    List<Map<String, dynamic>> cartItems,
  ) {
    final counts = <String, int>{};
    for (final cartItem in cartItems) {
      if (cartItem['is_shipping'] == true) continue;
      final qty =
          num.tryParse(cartItem['quantity']?.toString() ?? '')?.toInt() ?? 0;
      if (qty <= 0) continue;

      // Bundles are keyed by bundle_id in the catalog but stored under
      // item_code in the cart, so index both identities.
      final keys = <String>{};
      final itemCode = cartItem['item_code']?.toString().trim() ?? '';
      if (itemCode.isNotEmpty) keys.add(itemCode);
      final details = cartItem['bundle_details'];
      if (details is Map) {
        final bundleId = details['bundle_id']?.toString().trim() ?? '';
        if (bundleId.isNotEmpty) keys.add(bundleId);
      }

      for (final key in keys) {
        counts[key] = (counts[key] ?? 0) + qty;
      }
    }
    return counts;
  }

  /// Outlines a card whose item is already in the cart.
  ShapeBorder _cardShape(int cartQty) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: cartQty > 0
          ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
          : BorderSide.none,
    );
  }

  /// Counter badge pinned to the physical left so it never collides with the
  /// stock / free-delivery badges on the right.
  Widget _buildCartQtyBadge(int cartQty) {
    final theme = Theme.of(context);
    return Positioned(
      top: 4,
      left: 4,
      child: Tooltip(
        message: context.l10n.itemGridInCart(cartQty),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_cart,
                size: 9,
                color: theme.colorScheme.onPrimary,
              ),
              const SizedBox(width: 2),
              Text(
                '$cartQty',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddedToCartSnackbar(Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.itemGridAddedToCart),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showStockLimitMessage(int stockQty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.itemGridStockLimitReached(stockQty)),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showCannotAddToCartMessage(
    Map<String, dynamic>? selectedCustomer,
    bool isOutOfStock,
  ) {
    String message;
    if (!_canAddToCart(selectedCustomer)) {
      message = context.l10n.itemGridSelectCustomerFirst;
    } else if (isOutOfStock) {
      message = context.l10n.itemGridOutOfStock;
    } else {
      message = context.l10n.itemGridCannotAdd;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showBundleSelection(Map<String, dynamic> bundle) {
    final isPhone = ResponsiveUtils.isPhone(context);

    if (isPhone) {
      // Full-screen on phones so bundles aren't cramped
      showDialog(
        context: context,
        barrierDismissible: true,
        useSafeArea: false,
        builder: (context) => Dialog.fullscreen(
          child: BundleSelectionWidget(
            bundle: bundle,
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } else {
      // Constrained dialog on tablets
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
            child: BundleSelectionWidget(
              bundle: bundle,
              onCancel: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      );
    }
  }
}
