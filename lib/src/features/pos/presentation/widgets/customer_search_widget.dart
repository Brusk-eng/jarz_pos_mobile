import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/timing_config.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/utils/pasted_text.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/customer_shipping_address_dialog.dart';
import '../../../../core/widgets/paste_icon_button.dart';
import '../../../../core/widgets/paste_or_clear_button.dart';
import '../../../../core/widgets/customer_shipping_address_flow.dart';
import '../../../../core/repositories/customer_address_repository.dart';
import '../../../credit/data/models/credit_models.dart';
import '../../../credit/state/credit_providers.dart';
import '../../../geo/presentation/widgets/location_link_field.dart';
import '../../data/models/customer_duplicate_models.dart';
import '../../data/repositories/pos_repository.dart';
import '../../state/pos_notifier.dart';
import 'duplicate_customer_dialog.dart';
import '../../../../core/utils/territory_label.dart';
// providers file not present; we use repository providers directly

// Dynamic customer search provider that switches between name and phone search
final dynamicCustomerSearchProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      query,
    ) async {
      if (query.isEmpty) return [];

      final repository = ref.watch(posRepositoryProvider);

      // Check if query contains only digits (phone search) or contains letters (name search)
      // Uncomment if needed for different search types
      // final isPhoneSearch = RegExp(r'^[0-9+\-\s()]+$').hasMatch(query.trim());

      try {
        // B2C POS must only surface Individual customers; Company (B2B)
        // accounts are handled exclusively in B2B mode.
        return await repository.searchCustomers(
          query,
          customerType: 'Individual',
        );
      } catch (e) {
        return [];
      }
    });

// Territories provider (local) backed by PosRepository
final territoriesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((
      ref,
      search,
    ) async {
      final repo = ref.watch(posRepositoryProvider);
      return await repo.getTerritories(search: search);
    });

class CustomerSearchWidget extends ConsumerStatefulWidget {
  final bool lockCustomer;

  const CustomerSearchWidget({super.key, this.lockCustomer = false});

  @override
  ConsumerState<CustomerSearchWidget> createState() =>
      _CustomerSearchWidgetState();
}

/// Shared by the tablet dropdown field and the phone search page.
const List<TextInputFormatter> _searchFormatters = [
  SearchQueryInputFormatter(),
];

/// Quick Add phone fields: pasted `+20 100-123 4567` or Arabic digits become
/// plain digits instead of being saved with invisible marks.
const List<TextInputFormatter> _phoneFormatters = [PhoneInputFormatter()];

class _CustomerSearchWidgetState extends ConsumerState<CustomerSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  String _currentQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(UiDebounce.customerSearch, () {
      if (mounted) {
        setState(() {
          _currentQuery = query;
        });
      }
    });
  }

  Map<String, dynamic> _mergeCustomerAddressBook(
    Map<String, dynamic> customer,
    Map<String, dynamic> addressBook,
    List<Map<String, dynamic>> territories,
  ) {
    final addresses = (addressBook['addresses'] as List? ?? const [])
        .whereType<Map>()
        .map((address) => Map<String, dynamic>.from(address))
        .toList();
    final selectedAddress = addressBook['selected_address'] is Map
        ? Map<String, dynamic>.from(addressBook['selected_address'] as Map)
        : <String, dynamic>{};
    final selectedPhone =
        selectedAddress['phone']?.toString().trim().isNotEmpty == true
        ? selectedAddress['phone'].toString().trim()
        : (addressBook['default_phone']?.toString().trim() ??
              customer['mobile_no']?.toString().trim() ??
              '');
    final selectedTerritory = _firstNonEmptyString(selectedAddress, const [
      'city',
      'state',
      'territory',
    ]);
    final territory = _findTerritory(territories, selectedTerritory);
    final deliveryIncome =
        _asDouble(
          territory?['delivery_income'] ??
              selectedAddress['delivery_income'] ??
              customer['delivery_income'],
        ) ??
        0.0;
    final territoryDisplay = _firstNonEmptyString(territory ?? const {}, const [
      'territory_name',
      'name',
      'id',
    ]);
    // A Territory is *named* by its Woo code, so `territory_name` is a code on
    // most records. Carry the Arabic label across the merge too, or the cart's
    // delivery line reads "EGNASRCITY" back at the operator.
    final territoryNameAr = _firstNonEmptyString(territory ?? const {}, const [
      'territory_name_ar',
    ]);

    return {
      ...customer,
      'shipping_addresses': addresses,
      'selected_shipping_address_name':
          addressBook['selected_address_name']?.toString().trim() ?? '',
      'selected_shipping_address':
          selectedAddress['full_address']?.toString().trim() ?? '',
      if (selectedTerritory.isNotEmpty) ...{
        'territory': selectedTerritory,
        'selected_shipping_address_territory': selectedTerritory,
      },
      if (territoryDisplay.isNotEmpty) 'territory_name': territoryDisplay,
      if (territoryNameAr.isNotEmpty) 'territory_name_ar': territoryNameAr,
      'delivery_income': deliveryIncome,
      'selected_shipping_address_delivery_income': deliveryIncome,
      'selected_shipping_phone': selectedPhone,
      if (selectedPhone.isNotEmpty) 'mobile_no': selectedPhone,
    };
  }

  String _firstNonEmptyString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString().trim() ?? '');
  }

  Map<String, dynamic>? _findTerritory(
    List<Map<String, dynamic>> territories,
    String territoryValue,
  ) {
    final normalized = territoryValue.trim();
    if (normalized.isEmpty) {
      return null;
    }

    for (final territory in territories) {
      final candidates = [
        territory['name'],
        territory['id'],
        territory['territory_name'],
      ].map((value) => value?.toString().trim()).whereType<String>();
      if (candidates.any((candidate) => candidate == normalized)) {
        return territory;
      }
    }
    return null;
  }

  Future<void> _selectCustomerWithShippingAddress(
    Map<String, dynamic> customer, {
    bool forcePicker = false,
  }) async {
    final customerName = customer['name']?.toString().trim() ?? '';
    if (customerName.isEmpty) {
      return;
    }

    // Credit is decided per order at the payment step, but the profile behind
    // it is fetched HERE, the moment the customer is chosen, so the payment
    // dialog opens with the terms and the remaining headroom already resolved
    // instead of a spinner. Only for shops the search row already flagged —
    // a retail individual costs no request. Fire-and-forget: a failure is the
    // dialog's problem, and it renders its own "could not check" state.
    if (customer['credit_allowed'] == true) {
      unawaited(
        ref
            .read(customerCreditProfileProvider(customerName).future)
            .catchError((Object _) => const CustomerCreditProfile()),
      );
    }

    if (widget.lockCustomer) {
      final selected = await chooseCustomerShippingAddress(
        context,
        customer: customer,
        repository: ref.read(customerAddressRepositoryProvider),
        forcePicker: forcePicker,
        requireBranchName: true,
        setAsPrimary: false,
      );
      if (selected == null || !mounted) return;
      final activeCustomer = ref
          .read(posNotifierProvider)
          .selectedCustomer?['name']
          ?.toString()
          .trim();
      if (activeCustomer != customerName) return;
      ref.read(posNotifierProvider.notifier).selectCustomer(selected);
      return;
    }

    final repository = ref.read(posRepositoryProvider);
    final addressRepo = ref.read(customerAddressRepositoryProvider);
    Map<String, dynamic> addressBook;
    List<Map<String, dynamic>> territories;
    try {
      final results = await Future.wait([
        repository.getCustomerShippingAddresses(customer: customerName),
        addressRepo.getTerritories(),
      ]);
      addressBook = results[0] as Map<String, dynamic>;
      territories = (results[1] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.customerShippingAddressLoadFailed)),
      );
      return;
    }

    if (!mounted) return;

    final addresses = (addressBook['addresses'] as List? ?? const [])
        .whereType<Map>()
        .map((address) => Map<String, dynamic>.from(address))
        .toList();

    if (forcePicker || addresses.length > 1 || addresses.isEmpty) {
      final selection = await CustomerShippingAddressDialog.show(
        context,
        customerName: customer['customer_name']?.toString() ?? customerName,
        customer: customerName,
        addresses: addresses,
        territories: territories,
        initialSelectedAddressName:
            addressBook['selected_address_name']?.toString() ?? '',
        initialPhone:
            addressBook['default_phone']?.toString() ??
            customer['mobile_no']?.toString() ??
            '',
        repository: addressRepo,
      );
      if (selection == null || !mounted) {
        return;
      }

      try {
        final saveResult = await repository.saveCustomerShippingAddress(
          customer: customerName,
          phone: selection['phone']?.toString() ?? '',
          addressName: selection['address_name']?.toString(),
          address: selection['address']?.toString(),
          territory: selection['territory']?.toString(),
          locationLink: selection['location_link']?.toString(),
          latitude: double.tryParse(selection['latitude']?.toString() ?? ''),
          longitude: double.tryParse(selection['longitude']?.toString() ?? ''),
          geoSource: selection['geo_source']?.toString(),
        );
        addressBook = saveResult['address_book'] is Map
            ? Map<String, dynamic>.from(saveResult['address_book'] as Map)
            : addressBook;
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.invoiceAddressUpdateFailed)),
        );
        return;
      }
    }

    if (!mounted) return;
    ref
        .read(posNotifierProvider.notifier)
        .selectCustomer(
          _mergeCustomerAddressBook(customer, addressBook, territories),
        );
    _controller.clear();
    _focusNode.unfocus();
    setState(() {
      _currentQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedCustomer = ref.watch(
      posNotifierProvider.select((state) => state.selectedCustomer),
    );

    if (selectedCustomer != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildSelectedCustomer(selectedCustomer)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.location_on),
                  onPressed: () => _selectCustomerWithShippingAddress(
                    selectedCustomer,
                    forcePicker: true,
                  ),
                  tooltip: l10n.customerShippingAddressTitle,
                  color: Theme.of(context).colorScheme.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                if (!widget.lockCustomer) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      if (kDebugMode) {
                        debugPrint('Customer unselect button pressed');
                      }
                      ref.read(posNotifierProvider.notifier).unselectCustomer();
                    },
                    tooltip: l10n.posCustomerUnselect,
                    color: Theme.of(context).colorScheme.error,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Icon(
          Icons.person_search,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildSearchField()),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            Icons.person_add,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => _showQuickAddCustomerDialog(''),
          tooltip: l10n.posCustomerAdd,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedCustomer(Map<String, dynamic> customer) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          customer['customer_name'] ??
              customer['name'] ??
              l10n.posUnknownCustomer,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        if (customer['mobile_no'] != null)
          Text(
            customer['mobile_no'],
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        if ((customer['selected_shipping_address'] ?? '').toString().isNotEmpty)
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  customer['selected_shipping_address'].toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        if (customer['territory'] != null)
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  territoryLabel(
                    nameAr: customer['territory_name_ar'],
                    display: customer['territory_name'],
                    raw: customer['territory'],
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        if (customer['delivery_income'] != null &&
            customer['delivery_income'] > 0)
          Row(
            children: [
              Icon(Icons.attach_money, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                l10n.posCustomerDeliveryIncomeValue(
                  _formatCurrency(customer['delivery_income']),
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _formatCurrency(dynamic value) {
    if (value is num) {
      return '\$${value.toStringAsFixed(2)}';
    }
    if (value == null) {
      return '\$0.00';
    }
    return '\$${value.toString()}';
  }

  Widget _buildSearchField() {
    // The customer bar sits at the very top of the POS screen. On a phone an
    // inline overlay has nowhere to land — downward it is buried by the
    // keyboard, upward (the old behaviour) it draws over the app bar and gets
    // clipped — and the bar itself collapses with the header while scrolling,
    // dragging the anchor with it. Give phones the whole viewport instead.
    if (ResponsiveUtils.isPhone(context)) {
      return _buildFullScreenSearchLauncher();
    }
    return _buildInlineAutocomplete();
  }

  /// Phone affordance: looks like the search field, opens the full-screen
  /// search page on tap.
  Widget _buildFullScreenSearchLauncher() {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openCustomerSearchPage(),
      child: InputDecorator(
        isEmpty: true,
        decoration: InputDecoration(
          hintText: context.l10n.customerSearchHint,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        child: const SizedBox(height: 24),
      ),
    );
  }

  Future<void> _openCustomerSearchPage() async {
    final selection = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _CustomerSearchPage(),
      ),
    );
    if (selection == null || !mounted) return;

    if (selection['_isQuickAdd'] == true) {
      _showQuickAddCustomerDialog(selection['searchQuery']?.toString() ?? '');
    } else {
      await _selectCustomerWithShippingAddress(
        Map<String, dynamic>.from(selection),
      );
    }
  }

  /// Tablet/desktop affordance: an inline dropdown anchored to the field.
  /// Always opens downward — the field is the topmost element, so upward is
  /// never the right direction — and the panel is sized to the field's own
  /// width instead of a hardcoded 450px.
  Widget _buildInlineAutocomplete() {
    final isPhoneSearch = RegExp(
      r'^[0-9+\-\s()]+$',
    ).hasMatch(_currentQuery.trim());

    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth = constraints.maxWidth;
        return Autocomplete<Map<String, dynamic>>(
          optionsViewOpenDirection: OptionsViewOpenDirection.down,
          optionsBuilder: (textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Map<String, dynamic>>.empty();
            }

            try {
              final customers = await ref.read(
                dynamicCustomerSearchProvider(textEditingValue.text).future,
              );

              // A "create this customer" row is always offered, not only when
              // the search comes back empty: a near-miss match is exactly when
              // the operator still needs a new record.
              return [
                ...customers,
                {
                  '_isQuickAdd': true,
                  'customer_name':
                      'Quick Add Customer: ${textEditingValue.text}',
                  'searchQuery': textEditingValue.text,
                },
              ];
            } catch (e) {
              return const Iterable<Map<String, dynamic>>.empty();
            }
          },
          displayStringForOption: (customer) =>
              customer['customer_name'] ?? customer['name'] ?? 'Unknown',
          onSelected: (customer) {
            if (customer['_isQuickAdd'] == true) {
              _showQuickAddCustomerDialog(customer['searchQuery'] ?? '');
            } else {
              _selectCustomerWithShippingAddress(
                Map<String, dynamic>.from(customer),
              );
            }
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
                _controller.text = controller.text;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  onChanged: _onSearchChanged,
                  // A phone copied from WhatsApp arrives wrapped in bidi marks
                  // and often in Arabic digits; unnormalised it fails the phone
                  // test above and is searched as a *name*, matching nothing.
                  inputFormatters: _searchFormatters,
                  keyboardType: isPhoneSearch
                      ? TextInputType.phone
                      : TextInputType.text,
                  decoration: InputDecoration(
                    hintText: isPhoneSearch
                        ? context.l10n.customerSearchByPhone
                        : context.l10n.customerSearchByName,
                    prefixIcon: Icon(
                      isPhoneSearch ? Icons.phone : Icons.search,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: SuffixIconRow(
                      children: [
                        PasteIconButton(
                          controller: controller,
                          inputFormatters: _searchFormatters,
                          onChanged: _onSearchChanged,
                        ),
                        if (_currentQuery.isNotEmpty)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: context.l10n.commonClear,
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              controller.clear();
                              setState(() {
                                _currentQuery = '';
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            // Half the viewport, bounded — the field is pinned to the top of
            // the screen so there is always room below it.
            final maxHeight = (MediaQuery.sizeOf(context).height * 0.5).clamp(
              200.0,
              420.0,
            );
            return Align(
              alignment: AlignmentDirectional.topStart,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: maxHeight,
                    maxWidth: fieldWidth,
                  ),
                  child: SizedBox(
                    width: fieldWidth,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final customer = options.elementAt(index);
                        return buildCustomerOptionTile(
                          context,
                          customer,
                          isPhoneSearch: isPhoneSearch,
                          onTap: () => onSelected(customer),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showQuickAddCustomerDialog(String initialQuery) {
    showDialog(
      context: context,
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
          child: QuickAddCustomerWidget(
            initialQuery: initialQuery,
            onCustomerCreated: (customer) {
              Navigator.pop(context);
              _selectCustomerWithShippingAddress(customer);
            },
          ),
        ),
      ),
    );
  }
}

// Quick Add Customer Widget
class QuickAddCustomerWidget extends ConsumerStatefulWidget {
  final String initialQuery;
  final Function(Map<String, dynamic>) onCustomerCreated;

  const QuickAddCustomerWidget({
    super.key,
    required this.initialQuery,
    required this.onCustomerCreated,
  });

  @override
  ConsumerState<QuickAddCustomerWidget> createState() =>
      _QuickAddCustomerWidgetState();
}

class _QuickAddCustomerWidgetState
    extends ConsumerState<QuickAddCustomerWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _secondaryMobileController = TextEditingController();
  final _addressController = TextEditingController();

  /// Pasted Maps link plus the point the backend resolved it to.
  LocationLinkValue _location = LocationLinkValue.empty;

  String? _selectedTerritoryId;
  bool _isLoading = false;

  // Customer type / group (Phase 2 commercial policy support).
  static const _kIndividual = 'Individual';
  static const _kCompany = 'Company';
  // Company customer groups offered for B2B-style accounts.
  static const _companyCustomerGroups = <String>[
    'B2B',
    'Distributor',
    'Employee',
    'Sample',
  ];
  String _customerType = _kIndividual;
  String? _customerGroup;

  @override
  void initState() {
    super.initState();
    // Pre-populate name or mobile based on search query
    final isPhone = RegExp(
      r'^[0-9+\-\s()]+$',
    ).hasMatch(widget.initialQuery.trim());
    if (isPhone) {
      _mobileController.text = widget.initialQuery;
    } else {
      _nameController.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _secondaryMobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If a Sales Partner is selected on the POS, address becomes optional
    final selectedSalesPartner = ref.watch(
      posNotifierProvider.select((s) => s.selectedSalesPartner),
    );
    final bool hasPartner = selectedSalesPartner != null;
    return Padding(
      padding: const EdgeInsets.all(24),
      // Tapping anywhere off a field puts the keyboard away. Without it the
      // keyboard, once raised, keeps two thirds of this dialog hidden for the
      // rest of the entry.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  // Expanded, not bare: on a narrow phone the dialog is only
                  // ~310 px wide and the untruncated title overflowed the row.
                  Expanded(
                    child: Text(
                      context.l10n.quickAddCustomerTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form fields
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    children: [
                      // First row - Customer Name and Mobile Number. Stacked
                      // on a narrow dialog: side by side, each half is ~120 px
                      // and the prefix + paste icons left no room for text.
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final nameField = TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: context.l10n.customerNameLabel,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.person),
                              suffixIcon: PasteIconButton(
                                controller: _nameController,
                                enabled: !_isLoading,
                              ),
                            ),
                            // Rejects "...", "-", "123": a name nobody can
                            // search for again is how duplicates get made.
                            validator: (value) => validateCustomerNameField(
                              context,
                              value,
                              requiredMessage:
                                  context.l10n.customerNameRequired,
                            ),
                          );
                          final mobileField = TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: _phoneFormatters,
                            decoration: InputDecoration(
                              labelText: context.l10n.mobileNumberLabel,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.phone),
                              suffixIcon: PasteIconButton(
                                controller: _mobileController,
                                replace: true,
                                inputFormatters: _phoneFormatters,
                                enabled: !_isLoading,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return context.l10n.mobileNumberRequired;
                              }
                              return null;
                            },
                          );
                          if (constraints.maxWidth < 480) {
                            return Column(
                              children: [
                                nameField,
                                const SizedBox(height: 16),
                                mobileField,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: nameField),
                              const SizedBox(width: 16),
                              Expanded(child: mobileField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Second phone number (optional)
                      TextFormField(
                        controller: _secondaryMobileController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: _phoneFormatters,
                        decoration: InputDecoration(
                          labelText: context.l10n.secondaryPhoneLabel,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.phone_android),
                          hintText: context.l10n.secondaryPhoneHint,
                          suffixIcon: PasteIconButton(
                            controller: _secondaryMobileController,
                            replace: true,
                            inputFormatters: _phoneFormatters,
                            enabled: !_isLoading,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Customer type (Individual / Company) + group when Company
                      _buildCustomerTypeSelector(),
                      if (_customerType == _kCompany) ...[
                        const SizedBox(height: 16),
                        _buildCustomerGroupSelector(),
                      ],
                      const SizedBox(height: 16),

                      // Territory
                      _buildTerritorySelector(),
                      const SizedBox(height: 16),

                      // Maps link → coordinates. Full width because it grows a
                      // status line and a map preview once the link resolves.
                      LocationLinkField(
                        enabled: !_isLoading,
                        // Assigned rather than setState-ed: nothing else in this
                        // form reads it, so rebuilding the whole dialog on every
                        // keystroke would be pure churn.
                        onChanged: (value) => _location = value,
                      ),
                      const SizedBox(height: 16),

                      // Third row - Detailed Address (full width).
                      // Addresses arrive pasted from WhatsApp far more often than
                      // they are typed, so the field carries its own paste button:
                      // on a phone the native long-press toolbar is unreachable
                      // once the keyboard has squeezed this dialog.
                      TextFormField(
                        controller: _addressController,
                        maxLines: 3,
                        minLines: 2,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: hasPartner
                              ? context.l10n.detailedAddressOptional
                              : context.l10n.detailedAddressRequired,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.location_on),
                          alignLabelWithHint: true,
                          suffixIcon: PasteOrClearButton(
                            controller: _addressController,
                            enabled: !_isLoading,
                          ),
                          helperText: hasPartner
                              ? context.l10n.addressOptionalPartner
                              : null,
                        ),
                        validator: (value) {
                          if (!hasPartner) {
                            if (value == null || value.trim().isEmpty) {
                              return context.l10n.addressRequired;
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(context.l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createCustomer,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.l10n.posCreateCustomer),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerTypeSelector() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.customerTypeLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: _kIndividual,
                label: Text(context.l10n.customerTypeIndividual),
                icon: const Icon(Icons.person_outline),
              ),
              ButtonSegment<String>(
                value: _kCompany,
                label: Text(context.l10n.customerTypeCompany),
                icon: const Icon(Icons.business_outlined),
              ),
            ],
            selected: {_customerType},
            onSelectionChanged: (selection) {
              setState(() {
                _customerType = selection.first;
                if (_customerType == _kIndividual) {
                  _customerGroup = null;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerGroupSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _customerGroup,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: context.l10n.customerGroupLabel,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.groups_outlined),
      ),
      items: _companyCustomerGroups
          .map(
            (group) =>
                DropdownMenuItem<String>(value: group, child: Text(group)),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _customerGroup = value;
        });
      },
      validator: (value) {
        if (_customerType == _kCompany && (value == null || value.isEmpty)) {
          return context.l10n.customerGroupRequired;
        }
        return null;
      },
    );
  }

  Widget _buildTerritorySelector() {
    final territoriesAsync = ref.watch(territoriesProvider(null));

    return territoriesAsync.when(
      data: (territories) => DropdownButtonFormField<String>(
        initialValue: _selectedTerritoryId,
        decoration: InputDecoration(
          labelText: context.l10n.territoryLabel,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.location_on),
        ),
        isExpanded: true,
        menuMaxHeight: 320,
        alignment: AlignmentDirectional.centerStart,
        items: territories.map<DropdownMenuItem<String>>((territory) {
          final deliveryInfo =
              territory['delivery_income'] != null &&
                  territory['delivery_income'] > 0
              ? ' (Income: \$${territory['delivery_income']})'
              : '';
          final label = territoryLabelOf(territory);
          return DropdownMenuItem<String>(
            value: territory['name'],
            child: SizedBox(
              width: ResponsiveUtils.isPhone(context) ? 260 : 360,
              child: Text(
                '${label.isEmpty ? context.l10n.unknownTerritory : label}$deliveryInfo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() {
            _selectedTerritoryId = value;
            // no-op: name used directly from selection for server call
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return context.l10n.territorySelectRequired;
          }
          return null;
        },
      ),
      loading: () => TextFormField(
        decoration: InputDecoration(
          labelText: context.l10n.territoryLabel,
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.location_on),
          suffixIcon: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        enabled: false,
      ),
      error: (error, stack) => TextFormField(
        decoration: InputDecoration(
          labelText: context.l10n.territoryLabel,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.location_on),
          errorText: context.l10n.territoryLoadFailed,
        ),
        enabled: false,
      ),
    );
  }

  void _createCustomer() async {
    if (!_formKey.currentState!.validate() || _selectedTerritoryId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // If Sales Partner is selected and address is empty, auto-fill with partner name
      final selectedSalesPartner = ref.read(
        posNotifierProvider.select((s) => s.selectedSalesPartner),
      );
      final bool hasPartner = selectedSalesPartner != null;
      String addressValue = _addressController.text.trim();
      if (hasPartner && addressValue.isEmpty) {
        final Map<String, dynamic> sp = selectedSalesPartner;
        String partnerLabel = context.l10n.posSalesPartnerFallback;
        for (final key in const ['title', 'partner_name', 'name']) {
          final val = sp[key];
          if (val != null && val.toString().trim().isNotEmpty) {
            partnerLabel = val.toString();
            break;
          }
        }
        addressValue = partnerLabel;
      }

      // Pre-create duplicate warning. Fails open: an old backend, an error or
      // no network yields "no matches" and the create goes ahead.
      final secondary = _secondaryMobileController.text.trim();
      CustomerDuplicateCheck check;
      try {
        check = await ref
            .read(posRepositoryProvider)
            .checkCustomerDuplicates(
              customerName: _nameController.text.trim(),
              mobileNumber: _mobileController.text.trim(),
              secondaryMobile: secondary.isNotEmpty ? secondary : null,
              address: addressValue,
            );
      } catch (_) {
        check = CustomerDuplicateCheck.none;
      }
      if (!mounted) return;
      if (check.nameInvalid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(customerNameNoLetterMessage(context)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
      if (check.hasMatches) {
        final decision = await showDuplicateCustomerDialog(
          context,
          matches: check.matches,
        );
        if (!mounted) return;
        switch (decision.action) {
          case DuplicateCustomerAction.cancel:
            return;
          case DuplicateCustomerAction.useExisting:
            // Same path as tapping a search result: the parent's callback
            // closes this Quick Add dialog and runs the address selection.
            widget.onCustomerCreated(
              Map<String, dynamic>.from(decision.match!.raw),
            );
            return;
          case DuplicateCustomerAction.createNew:
            break;
        }
      }

      final newCustomer = await ref
          .read(posRepositoryProvider)
          .createCustomer(
            customerName: _nameController.text.trim(),
            mobileNumber: _mobileController.text.trim(),
            territoryId: _selectedTerritoryId!,
            detailedAddress: addressValue,
            locationLink: _location.link.isNotEmpty ? _location.link : null,
            latitude: _location.latitude,
            longitude: _location.longitude,
            geoSource: _location.precision,
            secondaryMobile: _secondaryMobileController.text.trim().isNotEmpty
                ? _secondaryMobileController.text.trim()
                : null,
            customerType: _customerType,
            customerGroup: _customerType == _kCompany ? _customerGroup : null,
          );

      if (mounted) {
        widget.onCustomerCreated(newCustomer);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.posCustomerCreatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final friendly = e is ApiException
            ? e.message
            : context.l10n.customerCreateFailed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendly),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// One result row, shared by the tablet dropdown and the phone search page so
/// the two surfaces cannot drift apart.
Widget buildCustomerOptionTile(
  BuildContext context,
  Map<String, dynamic> customer, {
  required bool isPhoneSearch,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);
  final isQuickAdd = customer['_isQuickAdd'] == true;

  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isQuickAdd
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isQuickAdd
                ? Icons.add_circle
                : (isPhoneSearch ? Icons.phone : Icons.person),
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isQuickAdd
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.quickAddCustomerTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        context.l10n.quickAddCustomerTap,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        customer['customer_name'] ??
                            customer['name'] ??
                            context.l10n.posUnknownCustomer,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (customer['mobile_no'] != null)
                        Text(
                          customer['mobile_no'].toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: isPhoneSearch
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      if (customer['territory'] != null)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                territoryLabel(
                                  nameAr: customer['territory_name_ar'],
                                  display: customer['territory_name'],
                                  raw: customer['territory'],
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (customer['delivery_income'] is num &&
                          (customer['delivery_income'] as num) > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            context.l10n.posCustomerDeliveryIncomeValue(
                              formatPosCurrency(customer['delivery_income']),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          if (!isQuickAdd)
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    ),
  );
}

String formatPosCurrency(dynamic value) {
  if (value is num) {
    return '\$${value.toStringAsFixed(2)}';
  }
  if (value == null) {
    return '\$0.00';
  }
  return '\$${value.toString()}';
}

/// Full-screen customer search used on phones.
///
/// A `Scaffold` route rather than an anchored overlay: `resizeToAvoidBottomInset`
/// keeps the list clear of the keyboard, the whole viewport holds results, and
/// nothing depends on where the (collapsible) POS customer bar happens to be.
/// Pops the chosen customer map, or a `_isQuickAdd` marker map.
class _CustomerSearchPage extends ConsumerStatefulWidget {
  const _CustomerSearchPage();

  @override
  ConsumerState<_CustomerSearchPage> createState() =>
      _CustomerSearchPageState();
}

class _CustomerSearchPageState extends ConsumerState<_CustomerSearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  /// Every keystroke — drives the clear button only.
  String _rawText = '';

  /// Debounced — drives the network search and the keyboard type, so neither
  /// churns while the operator is still typing.
  String _query = '';

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _rawText = value);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(UiDebounce.customerSearch, () {
      if (mounted) {
        setState(() => _query = value.trim());
      }
    });
  }

  void _clear() {
    _debounceTimer?.cancel();
    _controller.clear();
    setState(() {
      _rawText = '';
      _query = '';
    });
  }

  bool get _isPhoneSearch =>
      _query.isNotEmpty && RegExp(r'^[0-9+\-\s()]+$').hasMatch(_query);

  void _submitQuickAdd() {
    Navigator.of(context).pop(<String, dynamic>{
      '_isQuickAdd': true,
      'searchQuery': _controller.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          inputFormatters: _searchFormatters,
          textInputAction: TextInputAction.search,
          keyboardType: _isPhoneSearch
              ? TextInputType.phone
              : TextInputType.text,
          style: theme.textTheme.titleMedium,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: _isPhoneSearch
                ? l10n.customerSearchByPhone
                : l10n.customerSearchHint,
            suffixIcon: SuffixIconRow(
              children: [
                PasteIconButton(
                  controller: _controller,
                  inputFormatters: _searchFormatters,
                  onChanged: _onChanged,
                ),
                if (_rawText.isNotEmpty)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: l10n.commonClear,
                    icon: const Icon(Icons.clear),
                    onPressed: _clear,
                  ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;

    if (_query.isEmpty) {
      return _placeholder(
        icon: Icons.person_search,
        message: l10n.customerSearchStartTyping,
      );
    }

    return ref
        .watch(dynamicCustomerSearchProvider(_query))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _placeholder(
            icon: Icons.error_outline,
            message: l10n.commonError,
          ),
          data: (customers) {
            // The quick-add row always trails the results — a partial match is
            // exactly when a new customer still has to be created.
            return ListView.builder(
              padding: EdgeInsets.zero,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: customers.length + (customers.isEmpty ? 2 : 1),
              itemBuilder: (context, index) {
                if (customers.isEmpty && index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Text(
                      l10n.customerSearchNoResults,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                final offset = customers.isEmpty ? 1 : 0;
                if (index - offset >= customers.length) {
                  return buildCustomerOptionTile(
                    context,
                    const {'_isQuickAdd': true},
                    isPhoneSearch: _isPhoneSearch,
                    onTap: _submitQuickAdd,
                  );
                }
                final customer = customers[index - offset];
                return buildCustomerOptionTile(
                  context,
                  customer,
                  isPhoneSearch: _isPhoneSearch,
                  onTap: () => Navigator.of(context).pop(customer),
                );
              },
            );
          },
        );
  }

  Widget _placeholder({required IconData icon, required String message}) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
