import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/core/constants/business_constants.dart';
import 'package:jarz_pos/src/core/network/user_service.dart';
import 'package:jarz_pos/src/features/pos/data/models/draft_cart.dart';
import 'package:jarz_pos/src/features/pos/data/models/pos_models.dart';
import 'package:jarz_pos/src/features/pos/data/repositories/draft_cart_repository.dart';
import 'package:jarz_pos/src/features/pos/data/repositories/pos_repository.dart';
import 'package:jarz_pos/src/features/pos/presentation/widgets/cart_widget.dart';
import 'package:jarz_pos/src/features/pos/state/pos_notifier.dart';

class _DummyPosRepository extends PosRepository {
  _DummyPosRepository() : super(Dio());

  @override
  Future<List<Map<String, dynamic>>> getPosProfiles() async => const [];

  @override
  Future<List<Map<String, dynamic>>> getItems(
    String posProfile, {
    String? priceList,
    String? customer,
    String? orderPurpose,
  }) async => const [];

  @override
  Future<List<Map<String, dynamic>>> getBundles(
    String posProfile, {
    String? priceList,
    String? customer,
    String? orderPurpose,
  }) async => const [];

  @override
  Future<List<Map<String, dynamic>>> getPosPriceLists(
    String posProfile,
  ) async => const [];
}

class _DummyDraftCartRepository extends DraftCartRepository {
  @override
  Future<List<DraftCart>> loadAll() async => const [];

  @override
  Future<void> upsert(draft) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> clearAll() async {}
}

class _PosNotifierStub extends PosNotifier {
  _PosNotifierStub(PosState initialState)
    : super(_DummyPosRepository(), _DummyDraftCartRepository()) {
    state = initialState;
  }
}

/// Stands in for a finished checkout: resets the order like the real notifier
/// and reports [outcome] for the cash Employee order that was submitted.
class _CheckoutOutcomeStub extends _PosNotifierStub {
  _CheckoutOutcomeStub(super.initialState, {required this.outcome});

  final EmployeeCashOutcome outcome;
  int checkoutCalls = 0;
  String? lastPaymentMethod;
  EmployeeCashOutcome _outcome = EmployeeCashOutcome.none;

  @override
  EmployeeCashOutcome get lastEmployeeCashOutcome => _outcome;

  @override
  Future<String?> getTerritoryPosProfile(String customerName) async => null;

  @override
  List<Map<String, dynamic>> getCartItemsExceedingStock() => const [];

  @override
  Future<void> checkout({
    String? paymentType,
    String? overridePosProfileName,
    String? paymentMethod,
    bool posProfileOverride = false,
  }) async {
    checkoutCalls += 1;
    lastPaymentMethod = paymentMethod;
    _outcome = outcome;
    state = state.copyWith(
      cartItems: const [],
      clearSelectedCustomer: true,
      clearSelectedCommercialPolicy: true,
      clearError: true,
      isLoading: false,
    );
  }
}

Future<_PosNotifierStub> _pumpCartWidget(
  WidgetTester tester,
  PosState state, {
  UserRoles? roles,
  _PosNotifierStub? stub,
  bool settle = true,
}) async {
  final notifier = stub ?? _PosNotifierStub(state);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        posNotifierProvider.overrideWith((ref) => notifier),
        if (roles != null)
          userRolesFutureProvider.overrideWith((ref) async => roles),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: CartWidget()),
      ),
    ),
  );

  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return notifier;
}

/// Builds a bundle cart item whose `bundle_details` came back through JSON, as
/// happens for a restored draft / offline-cached cart. The decoded value is a
/// `Map<String, dynamic>` holding `List<dynamic>`, NOT the
/// `Map<String, List<Map<String, dynamic>>>` the widget used to hard-cast to.
PosState _buildBundleState({required Object? selectedItems}) {
  return PosState(
    selectedProfile: const {'name': 'Main'},
    cartItems: [
      {
        'item_code': 'BUNDLE-1',
        'item_name': 'Family Box',
        'quantity': 1,
        'rate': 500,
        'type': 'bundle',
        'bundle_details': <String, dynamic>{
          'bundle_id': 'BUNDLE-1',
          'bundle_info': <String, dynamic>{
            'item_groups': <dynamic>[
              <String, dynamic>{'group_name': 'Flavours', 'group_key': 'g1'},
            ],
          },
          'selected_items': selectedItems,
        },
      },
    ],
    isPickup: true,
  );
}

PosState _buildState({
  required bool isAmendmentDraft,
  String? amendmentSourceInvoiceId,
  String? amendmentPaymentMethod,
  double? amendmentPaidAmount,
}) {
  return PosState(
    selectedProfile: const {'name': 'Main'},
    cartItems: const [
      {
        'item_code': 'ITEM-1',
        'item_name': 'Blueberry Large',
        'quantity': 1,
        'rate': 160,
        'type': 'item',
      },
    ],
    isPickup: true,
    isAmendmentDraft: isAmendmentDraft,
    amendmentSourceInvoiceId: amendmentSourceInvoiceId,
    amendmentPaymentMethod: amendmentPaymentMethod,
    amendmentPaidAmount: amendmentPaidAmount,
  );
}

void main() {
  test('B2B checkout uses the selected branch profile without override', () {
    final resolution = b2bBranchProfileForCheckout(
      PosState(
        isB2bOrder: true,
        selectedProfile: {'name': 'Heliopolis POS'},
        selectedCustomer: {
          'name': 'ilo specialty coffee',
          'territory': 'EGMASRJD',
          'selected_shipping_address_territory': 'EGMADINATY',
          'selected_shipping_address_territory_pos_profile': 'Madinaty POS',
        },
      ),
    );

    expect(resolution?.profileName, 'Madinaty POS');
    expect(resolution?.override, isFalse);
  });

  test('B2B checkout never falls back when the branch profile is absent', () {
    final resolution = b2bBranchProfileForCheckout(
      PosState(
        isB2bOrder: true,
        selectedProfile: {'name': 'Heliopolis POS'},
        selectedCustomer: {
          'name': 'ilo specialty coffee',
          'territory': 'EGMASRJD',
          'selected_shipping_address_territory': 'EGMADINATY',
        },
      ),
    );

    expect(resolution, isNull);
  });

  testWidgets('missing B2B branch profile shows actionable recovery', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showMissingB2bBranchProfileError(context),
              child: const Text('Checkout'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Checkout'));
    await tester.pump();

    expect(
      find.text(
        'Edit this branch and choose its delivery territory before ordering.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'B2B-only cart shows the bound purpose reason without manager pricing controls',
    (tester) async {
      const policy = CommercialPolicy(
        name: 'POL-SAMPLE',
        policyName: 'Sample order',
        orderPurpose: 'Sample - Courier',
        discountPercentage: 100,
        waivesShippingIncome: true,
      );
      final notifier = await _pumpCartWidget(
        tester,
        PosState(
          selectedProfile: {'name': 'Nasr city'},
          isB2bOrder: true,
          b2bSetupComplete: true,
          selectedCommercialPolicy: policy,
          availableCommercialPolicies: [policy],
          boundB2bOrderPurpose: 'Sample - Courier',
          policyReason: 'Existing sample reason',
          zeroShippingOverride: true,
        ),
        roles: const UserRoles(
          user: 'b2b-only@example.invalid',
          roles: ['B2B Sales Rep'],
          isB2bSalesRep: true,
          canAccessB2b: true,
        ),
      );

      final reasonField = find.byKey(
        const ValueKey('policy-reason-POL-SAMPLE'),
      );
      expect(reasonField, findsOneWidget);
      expect(find.text('Existing sample reason'), findsOneWidget);
      expect(find.text('Price List'), findsNothing);

      await tester.enterText(reasonField, 'Disposable sample visit');
      await tester.pump();

      expect(notifier.state.policyReason, 'Disposable sample visit');
    },
  );

  group('CartWidget manager pricing card', () {
    const managerRoles = UserRoles(
      user: 'manager@example.invalid',
      roles: [RoleNames.jarzManager],
    );
    const samplePolicy = CommercialPolicy(
      name: 'Sample (Courier)',
      policyName: 'Sample (Courier)',
      orderPurpose: 'Sample - Courier',
      priceList: 'Sample',
    );
    const b2bSupplyPolicy = CommercialPolicy(
      name: 'B2B Supply',
      policyName: 'B2B Supply',
      orderPurpose: 'B2B Supply',
    );
    const freeShippingPolicy = CommercialPolicy(
      name: 'Free Shipping Waiver',
      policyName: 'Free Shipping Waiver',
      orderPurpose: 'Free Shipping Waiver',
    );
    const policies = [samplePolicy, b2bSupplyPolicy, freeShippingPolicy];

    Map<String, dynamic> option(String name, [List<String>? reservedFor]) => {
      'name': name,
      'display_label': '$name [pl]',
      'is_default': name == 'Standard Selling',
      'zero_shipping_default': false,
      if (reservedFor != null) reservedForPurposesKey: reservedFor,
    };

    List<Map<String, dynamic>> lists({required bool withServerFlag}) => [
      option('Standard Selling', withServerFlag ? [] : null),
      option('Selling Bundle of 3', withServerFlag ? [] : null),
      option('B2B Selling', withServerFlag ? ['B2B Supply'] : null),
      option('Sample', withServerFlag ? ['Sample - Courier'] : null),
      option('Employee', withServerFlag ? ['Employee'] : null),
    ];

    PosState pricingState({
      required List<Map<String, dynamic>> priceLists,
      List<CommercialPolicy> availablePolicies = policies,
      CommercialPolicy? policy,
      String selected = 'Standard Selling',
    }) => PosState(
      selectedProfile: const {'name': 'Main'},
      availablePriceLists: priceLists,
      selectedPriceList: priceLists.firstWhere((o) => o['name'] == selected),
      availableCommercialPolicies: availablePolicies,
      selectedCommercialPolicy: policy,
      isPickup: true,
    );

    /// No purpose offers a price-list picker any more.
    void expectNoPriceListDropdown() {
      // The only dropdown left on the card is the order purpose.
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is DropdownButtonFormField<String> &&
              !((widget.key as ValueKey<String>?)?.value.startsWith(
                    'order-purpose-',
                  ) ??
                  false),
        ),
        findsNothing,
      );
    }

    testWidgets('shows a locked purpose list read-only, below the purpose', (
      tester,
    ) async {
      final notifier = await _pumpCartWidget(
        tester,
        pricingState(
          priceLists: lists(withServerFlag: true),
          policy: samplePolicy,
          selected: 'Sample',
        ),
        roles: managerRoles,
      );

      expectNoPriceListDropdown();
      final locked = find.byKey(const ValueKey('locked-price-list'));
      expect(locked, findsOneWidget);
      expect(find.text('Default'), findsNothing);
      expect(
        find.descendant(of: locked, matching: find.text('Sample [pl]')),
        findsOneWidget,
      );
      expect(find.text('Set by the order purpose.'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Order purpose')).dy,
        lessThan(tester.getTopLeft(locked).dy),
      );

      // Nothing to open: the field is not a dropdown.
      await tester.tap(locked);
      await tester.pumpAndSettle();
      expect(find.text('Standard Selling [pl]'), findsNothing);
      expect(notifier.state.selectedPriceListName, 'Sample');
    });

    testWidgets('tells B2B Supply the list follows the customer', (
      tester,
    ) async {
      await _pumpCartWidget(
        tester,
        pricingState(
          priceLists: lists(withServerFlag: true),
          policy: b2bSupplyPolicy,
        ),
        roles: managerRoles,
      );

      expectNoPriceListDropdown();
      expect(find.byKey(const ValueKey('locked-price-list')), findsOneWidget);
      expect(
        find.text(
          "Chosen from the customer's price list once you select the customer.",
        ),
        findsOneWidget,
      );
      expect(find.text('Standard Selling [pl]'), findsNothing);
    });

    for (final policy in <CommercialPolicy?>[null, freeShippingPolicy]) {
      final purpose = policy?.orderPurpose ?? 'Standard';
      testWidgets(
        'shows the POS default list read-only with the Default marker '
        'for $purpose',
        (tester) async {
          final notifier = await _pumpCartWidget(
            tester,
            pricingState(
              priceLists: lists(withServerFlag: true),
              policy: policy,
            ),
            roles: managerRoles,
          );

          expectNoPriceListDropdown();
          final field = find.byKey(const ValueKey('default-price-list'));
          expect(field, findsOneWidget);
          expect(find.byKey(const ValueKey('locked-price-list')), findsNothing);
          expect(
            find.descendant(
              of: field,
              matching: find.text('Standard Selling [pl]'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(of: field, matching: find.text('Default')),
            findsOneWidget,
          );
          expect(find.text('Set by the order purpose.'), findsNothing);
          expect(
            tester.getTopLeft(find.text('Order purpose')).dy,
            lessThan(tester.getTopLeft(field).dy),
          );
          expect(
            tester.getTopLeft(field).dy,
            lessThan(tester.getTopLeft(find.byType(SwitchListTile)).dy),
          );

          // Nothing to open: no other list is ever offered.
          await tester.tap(field);
          await tester.pumpAndSettle();
          expect(find.text('Selling Bundle of 3 [pl]'), findsNothing);
          expect(notifier.state.selectedPriceListName, 'Standard Selling');
        },
      );
    }

    testWidgets('shows the default read-only when no policies are loaded', (
      tester,
    ) async {
      await _pumpCartWidget(
        tester,
        pricingState(
          priceLists: lists(withServerFlag: false),
          availablePolicies: const [],
        ),
        roles: managerRoles,
      );

      expect(find.text('Order purpose'), findsNothing);
      expectNoPriceListDropdown();
      final field = find.byKey(const ValueKey('default-price-list'));
      expect(
        find.descendant(
          of: field,
          matching: find.text('Standard Selling [pl]'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: field, matching: find.text('Default')),
        findsOneWidget,
      );
    });

    testWidgets('omits the Default marker for a list that is not the default', (
      tester,
    ) async {
      await _pumpCartWidget(
        tester,
        pricingState(
          priceLists: lists(withServerFlag: true),
          selected: 'Selling Bundle of 3',
        ),
        roles: managerRoles,
      );

      expectNoPriceListDropdown();
      expect(find.text('Selling Bundle of 3 [pl]'), findsOneWidget);
      expect(find.text('Default'), findsNothing);
    });
  });

  group('CartWidget Employee order payment', () {
    const managerRoles = UserRoles(
      user: 'manager@example.invalid',
      roles: [RoleNames.jarzManager],
    );
    const employeePolicy = CommercialPolicy(
      name: 'POL-EMPLOYEE',
      policyName: 'Employee Order',
      orderPurpose: 'Employee',
      waivesShippingIncome: true,
      noCourier: true,
      deliverAtBranch: true,
    );

    PosState employeeState({
      String employeePayment = PosState.employeePaymentCredit,
      bool isLoading = false,
    }) => PosState(
      selectedProfile: const {'name': 'Heliopolis POS'},
      availableCommercialPolicies: const [employeePolicy],
      selectedCommercialPolicy: employeePolicy,
      selectedCustomer: const {
        'name': 'CUST-STAFF-0001',
        'customer_name': 'Mona Adel',
      },
      selectedStaffEmployee: 'HR-EMP-00007',
      selectedStaffEmployeeName: 'Mona Adel',
      employeePayment: employeePayment,
      isLoading: isLoading,
      cartItems: const [
        {
          'item_code': 'JAR-L',
          'item_name': 'Large jar',
          'quantity': 1,
          'rate': 150,
          'type': 'item',
        },
      ],
    );

    const creditHint =
        'This order is deducted from the salary of the chosen staff member.';
    const cashHint =
        'The staff member pays now; the money goes into the branch cash.';

    testWidgets('renders On credit / Cash under the staff member, credit '
        'first and selected', (tester) async {
      await _pumpCartWidget(tester, employeeState(), roles: managerRoles);

      final staff = find.byKey(const ValueKey('staff-member-control'));
      final toggle = find.byKey(const ValueKey('employee-payment-toggle'));
      expect(staff, findsOneWidget);
      expect(toggle, findsOneWidget);
      expect(
        tester.getTopLeft(staff).dy,
        lessThan(tester.getTopLeft(toggle).dy),
      );

      final credit = find.descendant(
        of: toggle,
        matching: find.text('Credit (on account)'),
      );
      final cash = find.descendant(of: toggle, matching: find.text('Cash'));
      expect(credit, findsOneWidget);
      expect(cash, findsOneWidget);
      expect(
        tester.getTopLeft(credit).dx,
        lessThan(tester.getTopLeft(cash).dx),
      );

      final button = tester.widget<SegmentedButton<String>>(toggle);
      expect(button.selected, {PosState.employeePaymentCredit});
      expect(find.text(creditHint), findsOneWidget);
      expect(find.text(cashHint), findsNothing);
    });

    testWidgets('switches to cash and swaps the salary hint', (tester) async {
      final notifier = await _pumpCartWidget(
        tester,
        employeeState(),
        roles: managerRoles,
      );

      final cash = find.descendant(
        of: find.byKey(const ValueKey('employee-payment-toggle')),
        matching: find.text('Cash'),
      );
      await tester.ensureVisible(cash);
      await tester.tap(cash);
      await tester.pumpAndSettle();

      expect(notifier.state.employeePaysCash, isTrue);
      expect(find.text(cashHint), findsOneWidget);
      expect(find.text(creditHint), findsNothing);
    });

    testWidgets('is disabled while loading', (tester) async {
      await _pumpCartWidget(
        tester,
        employeeState(isLoading: true),
        roles: managerRoles,
        settle: false,
      );

      final button = tester.widget<SegmentedButton<String>>(
        find.byKey(const ValueKey('employee-payment-toggle')),
      );
      expect(button.onSelectionChanged, isNull);
    });

    testWidgets('is absent for a Standard order', (tester) async {
      await _pumpCartWidget(
        tester,
        PosState(
          selectedProfile: const {'name': 'Heliopolis POS'},
          availableCommercialPolicies: const [employeePolicy],
          isPickup: true,
        ),
        roles: managerRoles,
      );

      expect(
        find.byKey(const ValueKey('employee-payment-toggle')),
        findsNothing,
      );
    });

    Future<void> tapCheckout(WidgetTester tester) async {
      // The cart is a lazily built scroll view; make it tall enough that the
      // checkout button is laid out at all.
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpAndSettle();
      final checkout = find.text('Checkout');
      await tester.ensureVisible(checkout);
      await tester.tap(checkout);
      await tester.pump();
      await tester.pump();
    }

    testWidgets('warns when a cash order was saved on credit', (tester) async {
      final state = employeeState(
        employeePayment: PosState.employeePaymentCash,
      );
      final stub = _CheckoutOutcomeStub(
        state,
        outcome: EmployeeCashOutcome.savedOnCredit,
      );
      await _pumpCartWidget(tester, state, roles: managerRoles, stub: stub);

      await tapCheckout(tester);

      expect(stub.checkoutCalls, 1);
      expect(
        find.byKey(const ValueKey('employee-cash-not-supported')),
        findsOneWidget,
      );
      expect(find.textContaining('Saved ON CREDIT, not cash'), findsOneWidget);
      expect(find.text('Order placed successfully!'), findsNothing);
    });

    testWidgets('confirms a cash order the server settled', (tester) async {
      final state = employeeState(
        employeePayment: PosState.employeePaymentCash,
      );
      final stub = _CheckoutOutcomeStub(
        state,
        outcome: EmployeeCashOutcome.paid,
      );
      await _pumpCartWidget(tester, state, roles: managerRoles, stub: stub);

      await tapCheckout(tester);

      expect(stub.checkoutCalls, 1);
      expect(find.text('Order placed and paid in cash.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('employee-cash-not-supported')),
        findsNothing,
      );
    });

    testWidgets('keeps the plain success for a credit order', (tester) async {
      final state = employeeState();
      final stub = _CheckoutOutcomeStub(
        state,
        outcome: EmployeeCashOutcome.none,
      );
      await _pumpCartWidget(tester, state, roles: managerRoles, stub: stub);

      await tapCheckout(tester);

      expect(stub.checkoutCalls, 1);
      expect(find.text('Order placed successfully!'), findsOneWidget);
    });
  });

  group('CartWidget checkout without a customer', () {
    // The item grid now lets a retail cart be filled before the customer is
    // known (the caller has not given a name yet); checkout is where the
    // customer becomes mandatory.
    testWidgets('refuses with the select-a-customer message and sends nothing', (
      tester,
    ) async {
      final state = _buildState(isAmendmentDraft: false);
      expect(state.selectedCustomer, isNull);
      final stub = _CheckoutOutcomeStub(
        state,
        outcome: EmployeeCashOutcome.none,
      );
      await _pumpCartWidget(tester, state, stub: stub);

      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpAndSettle();
      final checkout = find.text('Checkout');
      await tester.ensureVisible(checkout);
      await tester.tap(checkout);
      await tester.pump();
      await tester.pump();

      expect(stub.checkoutCalls, 0);
      expect(find.text('Please select a customer first'), findsWidgets);
      expect(stub.state.cartItems, hasLength(1), reason: 'cart is kept');
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });

  group('CartWidget amendment checkout', () {
    Future<void> tapSubmitAmendment(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpAndSettle();
      final submit = find.text('Submit Amendment');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      await tester.pump();
    }

    testWidgets(
      'a paid order keeps its method and never shows the payment dialog (17612)',
      (tester) async {
        final state = _buildState(
          isAmendmentDraft: true,
          amendmentSourceInvoiceId: 'ACC-SINV-2026-18471',
          amendmentPaymentMethod: 'Kashier Card',
          amendmentPaidAmount: 160,
        );
        final stub = _CheckoutOutcomeStub(
          state,
          outcome: EmployeeCashOutcome.none,
        );
        await _pumpCartWidget(tester, state, stub: stub);

        await tapSubmitAmendment(tester);

        // The first dialog is the branch-profile check that follows the payment
        // step, which proves the payment-method dialog was skipped.
        expect(find.text('Profile Mismatch'), findsOneWidget);
        await tester.tap(find.text('Proceed'));
        await tester.pumpAndSettle();

        expect(stub.checkoutCalls, 1);
        expect(stub.lastPaymentMethod, 'Kashier Card');
      },
    );

    testWidgets(
      'a paid order edited to cost more lets the cashier choose for the balance',
      (tester) async {
        // Paid 100, the edited cart is 160: 60 is still owed.
        final state = _buildState(
          isAmendmentDraft: true,
          amendmentSourceInvoiceId: 'ACC-SINV-2026-18471',
          amendmentPaymentMethod: 'Kashier Card',
          amendmentPaidAmount: 100,
        );
        final stub = _CheckoutOutcomeStub(
          state,
          outcome: EmployeeCashOutcome.none,
        );
        await _pumpCartWidget(tester, state, stub: stub);

        await tapSubmitAmendment(tester);
        await tester.pumpAndSettle();

        expect(stub.checkoutCalls, 0, reason: 'waits for the payment dialog');
        expect(find.text('Select Payment Method'), findsOneWidget);
      },
    );

    testWidgets(
      'an unpaid amendment still asks how the order will be paid',
      (tester) async {
        final state = _buildState(
          isAmendmentDraft: true,
          amendmentSourceInvoiceId: 'ACC-SINV-2026-18472',
        );
        final stub = _CheckoutOutcomeStub(
          state,
          outcome: EmployeeCashOutcome.none,
        );
        await _pumpCartWidget(tester, state, stub: stub);

        await tapSubmitAmendment(tester);
        await tester.pumpAndSettle();

        expect(stub.checkoutCalls, 0, reason: 'waits for the payment dialog');
        expect(find.text('Profile Mismatch'), findsNothing,
            reason: 'the payment dialog comes first and is still open');
        expect(find.text('Cash'), findsWidgets);
      },
    );

    testWidgets(
      'shows submit amendment action when amendment draft has source invoice',
      (tester) async {
        await _pumpCartWidget(
          tester,
          _buildState(
            isAmendmentDraft: true,
            amendmentSourceInvoiceId: 'ACC-SINV-2026-15739',
          ),
        );

        expect(find.text('Submit Amendment'), findsOneWidget);
        expect(find.text('Amendment submit unavailable'), findsNothing);
        expect(
          find.text(
            'Review the changes carefully, then submit to replace the original invoice.',
          ),
          findsOneWidget,
        );

        // The promo section also renders an ElevatedButton ("Apply"), so scope
        // the lookup to the amendment/checkout button via its label.
        final button = tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text('Submit Amendment'),
            matching: find.byType(ElevatedButton),
          ),
        );
        expect(button.onPressed, isNotNull);
      },
    );

    testWidgets(
      'disables amendment submit when draft is missing source invoice',
      (tester) async {
        await _pumpCartWidget(tester, _buildState(isAmendmentDraft: true));

        expect(find.text('Submit Amendment'), findsOneWidget);
        expect(
          find.text(
            'Amendment submission is unavailable for this draft. Return to the order and reopen the amendment.',
          ),
          findsOneWidget,
        );

        // The promo section also renders an ElevatedButton ("Apply"), so scope
        // the lookup to the amendment/checkout button via its label.
        final button = tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text('Submit Amendment'),
            matching: find.byType(ElevatedButton),
          ),
        );
        expect(button.onPressed, isNull);
      },
    );
  });

  group('CartWidget bundle details rendering', () {
    testWidgets('renders JSON-decoded bundle selections without a cast error', (
      tester,
    ) async {
      // Regression: a hard `as Map<String, List<Map<String, dynamic>>>?` cast
      // threw "_Map<String, dynamic> is not a subtype of ..." during build.
      await _pumpCartWidget(
        tester,
        _buildBundleState(
          selectedItems: <String, dynamic>{
            'g1': <dynamic>[
              <String, dynamic>{'name': 'Blueberry'},
              <String, dynamic>{'name': 'Blueberry'},
              <String, dynamic>{'name': 'Mango'},
            ],
          },
        ),
      );

      expect(tester.takeException(), isNull);
      // Identical items are collapsed into a count.
      expect(find.text('Flavours: Blueberry x2, Mango'), findsOneWidget);
    });

    testWidgets('renders the strongly typed in-memory bundle shape unchanged', (
      tester,
    ) async {
      await _pumpCartWidget(
        tester,
        _buildBundleState(
          selectedItems: <String, List<Map<String, dynamic>>>{
            'g1': <Map<String, dynamic>>[
              <String, dynamic>{'name': 'Mango'},
            ],
          },
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Flavours: Mango'), findsOneWidget);
    });

    for (final malformed in <(String, Object?)>[
      ('null selections', null),
      ('a string instead of a map', 'not-a-map'),
      ('a list instead of a map', <dynamic>[]),
      (
        'non-map entries',
        <String, dynamic>{
          'g1': <dynamic>['just a string', 42],
        },
      ),
      ('a non-list group value', <String, dynamic>{'g1': 'oops'}),
    ]) {
      testWidgets('survives malformed bundle selections: ${malformed.$1}', (
        tester,
      ) async {
        // The cart must degrade to hiding the details, never throw at build.
        await _pumpCartWidget(
          tester,
          _buildBundleState(selectedItems: malformed.$2),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Family Box'), findsOneWidget);
      });
    }
  });
}
