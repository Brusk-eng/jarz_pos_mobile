import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/b2b/data/b2b_repository.dart';
import 'package:jarz_pos/src/features/b2b/data/models/b2b_account_labels.dart';
import 'package:jarz_pos/src/features/b2b/data/models/b2b_models.dart';
import 'package:jarz_pos/src/features/b2b/presentation/screens/b2b_account_screen.dart';
import 'package:jarz_pos/src/features/leads/data/leads_repository.dart';
import 'package:jarz_pos/src/features/leads/data/models/lead.dart';
import 'package:jarz_pos/src/features/pos/presentation/widgets/customer_search_widget.dart'
    show territoriesProvider;

const _territories = <Map<String, dynamic>>[
  {'name': 'Cairo', 'territory_name': 'Cairo'},
  {'name': 'Giza', 'territory_name': 'Giza'},
];

class _FakeB2bRepository extends B2bRepository {
  _FakeB2bRepository({this.accountDoctype = 'Lead'}) : super(Dio());

  final String accountDoctype;
  String? linkedCustomer;
  final List<String> linkCalls = [];
  final List<Map<String, String?>> orderCalls = [];

  @override
  Future<B2bAccountDetail> getAccount({
    required String doctype,
    required String name,
  }) async => B2bAccountDetail(
    account: B2bAccount(
      doctype: accountDoctype,
      name: name,
      title: 'Kavun',
      stage: 'Lead',
      contact: const B2bContact(mobileNo: '01040433168'),
      customer: accountDoctype == 'Customer' ? name : linkedCustomer,
    ),
    labels: null,
  );

  @override
  Future<List<Map<String, dynamic>>> searchLinkableCustomers(
    String query, {
    int limit = 20,
  }) async => const [
    {
      'name': 'KAVUN-CO',
      'customer_name': 'Kavun Co',
      'customer_type': 'Company',
    },
  ];

  @override
  Future<Map<String, dynamic>> linkExistingCustomer({
    required String partyDoctype,
    required String partyName,
    required String customer,
    String? expectedCustomer,
    bool allowRelink = false,
  }) async {
    linkCalls.add('$partyDoctype:$partyName:$customer');
    linkedCustomer = customer;
    return {'success': true, 'customer': customer, 'changed': true};
  }

  @override
  Future<OrderBinding> placeB2bOrder({
    required String partyDoctype,
    required String partyName,
    String? customerName,
    String? mobileNo,
    String? customerPrimaryAddress,
    String? territoryId,
    String? customerGroup,
    String? shippingAddressName,
  }) async {
    orderCalls.add({
      'customer_name': customerName,
      'mobile_no': mobileNo,
      'address': customerPrimaryAddress,
      'territory': territoryId,
    });
    linkedCustomer = 'CUST-KAVUN';
    return OrderBinding(
      customer: 'CUST-KAVUN',
      customerName: customerName,
      orderPurpose: 'B2B Supply',
    );
  }
}

class _FakeLeadsRepository extends LeadsRepository {
  _FakeLeadsRepository() : super(Dio());

  @override
  Future<Lead> getLead(String name) async => Lead(
    name: name,
    leadName: 'Kavun',
    contacts: const [
      LeadContact(contactName: 'Omar', role: 'Owner', phone: '01111111111'),
      LeadContact(
        contactName: 'Sara',
        role: 'Manager',
        phone: '01222222222',
        isPrimary: true,
      ),
      // No phone: nothing to fill the mobile with, so it is not offered.
      LeadContact(contactName: 'Mona', role: 'Barista'),
    ],
    primaryAddress: const LeadAddress(
      addressLine1: '6a Ismail Mohammed',
      city: 'Zamalek',
    ),
  );
}

Widget _wrap(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

List<Override> _overrides(_FakeB2bRepository repo) => [
  b2bRepositoryProvider.overrideWithValue(repo),
  leadsRepositoryProvider.overrideWithValue(_FakeLeadsRepository()),
  territoriesProvider(null).overrideWith((ref) async => _territories),
];

const _makeCustomer = ValueKey('b2b-make-customer');

void main() {
  testWidgets('a Customer account has no Set up customer button', (
    tester,
  ) async {
    final repo = _FakeB2bRepository(accountDoctype: 'Customer');
    await tester.pumpWidget(
      _wrap(
        const B2bAccountScreen(doctype: 'Customer', name: 'CUST-1'),
        overrides: _overrides(repo),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(_makeCustomer), findsNothing);
  });

  testWidgets(
    'Set up customer creates the customer from a picked contact without opening the POS',
    (tester) async {
      final repo = _FakeB2bRepository();
      await tester.pumpWidget(
        _wrap(
          const B2bAccountScreen(doctype: 'Lead', name: 'LEAD-KAVUN'),
          overrides: _overrides(repo),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_makeCustomer));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create new customer'));
      await tester.pumpAndSettle();

      // Paste buttons on name, mobile and address.
      expect(
        find.byKey(const ValueKey('b2b-setup-name-paste')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('b2b-setup-mobile-paste')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('b2b-setup-address-paste')),
        findsOneWidget,
      );
      // The Lead's primary address prefills the address.
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('6a Ismail Mohammed, Zamalek'),
        ),
        findsOneWidget,
      );

      // Contacts: primary first, phone-less one left out, account number last.
      await tester.tap(find.text('Contacts'));
      await tester.pumpAndSettle();
      expect(find.text('Sara · Manager · 01222222222').last, findsOneWidget);
      expect(find.text('Omar · Owner · 01111111111').last, findsOneWidget);
      expect(find.text('Kavun · 01040433168').last, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('Mona'),
        ),
        findsNothing,
      );
      await tester.tap(find.text('Omar · Owner · 01111111111').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Territory'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giza').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.orderCalls, [
        {
          'customer_name': 'Kavun',
          'mobile_no': '01111111111',
          'address': '6a Ismail Mohammed, Zamalek',
          'territory': 'Giza',
        },
      ]);
      // Stopped at the customer: no branch picker, no POS.
      expect(find.text('Customer: Kavun'), findsOneWidget);
      expect(find.byKey(_makeCustomer), findsNothing);
    },
  );

  testWidgets('Set up customer can link an existing customer instead', (
    tester,
  ) async {
    final repo = _FakeB2bRepository();
    await tester.pumpWidget(
      _wrap(
        const B2bAccountScreen(doctype: 'Lead', name: 'LEAD-KAVUN'),
        overrides: _overrides(repo),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_makeCustomer));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('b2b-setup-search-paste')),
      findsOneWidget,
    );
    await tester.tap(find.text('Kavun Co'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.linkCalls, ['Lead:LEAD-KAVUN:KAVUN-CO']);
    expect(repo.orderCalls, isEmpty);
    expect(find.text('Customer: Kavun Co'), findsOneWidget);
  });
}
