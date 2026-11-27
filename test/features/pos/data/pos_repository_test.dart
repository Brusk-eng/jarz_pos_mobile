import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/features/pos/data/repositories/pos_repository.dart';
import '../../../helpers/mock_services.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPlatformChannels();

  group('PosRepository', () {
    late MockDio mockDio;
    late PosRepository repository;

    setUp(() {
      mockDio = MockDio();
      repository = PosRepository(mockDio);
    });

    group('getPosProfiles', () {
      test('returns list of POS profiles', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.pos.get_pos_profiles',
          createSuccessResponse(data: ['Main POS', 'Branch POS']),
        );

        final result = await repository.getPosProfiles();

        expect(result, hasLength(2));
        expect(result[0]['name'], equals('Main POS'));
        expect(result[0]['title'], equals('Main POS'));
        expect(result[1]['name'], equals('Branch POS'));
      });

      test('carries allow/default delivery partner from object profiles', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.pos.get_pos_profiles',
          createSuccessResponse(data: [
            {
              'name': '6th of October',
              'allow_delivery_partner': true,
              'default_delivery_partner': 'Deliverk',
            },
            {
              'name': 'Main POS',
              'allow_delivery_partner': false,
              'default_delivery_partner': null,
            },
          ]),
        );

        final result = await repository.getPosProfiles();

        expect(result[0]['allow_delivery_partner'], isTrue);
        expect(result[0]['default_delivery_partner'], equals('Deliverk'));
        expect(result[1]['allow_delivery_partner'], isFalse);
        expect(result[1]['default_delivery_partner'], isNull);
      });

      test('returns empty list when no profiles exist', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.pos.get_pos_profiles',
          createSuccessResponse(data: []),
        );

        final result = await repository.getPosProfiles();

        expect(result, isEmpty);
      });

      test('throws exception on API error', () async {
        mockDio.setError(
          '/api/method/jarz_pos.api.pos.get_pos_profiles',
          createMockDioException(message: 'API Error'),
        );

        expect(() => repository.getPosProfiles(), throwsException);
      });

      test('handles null message gracefully', () async {
        mockDio.setResponse('/api/method/jarz_pos.api.pos.get_pos_profiles', {
          'message': null,
        });

        final result = await repository.getPosProfiles();

        expect(result, isEmpty);
      });
    });

    group('getBundles', () {
      test('returns list of bundles for profile', () async {
        final bundles = [
          {
            'id': 'BUNDLE-001',
            'name': 'Bundle 1',
            'price': 100.0,
            'free_shipping': 1,
            'item_groups': [
              {
                'group_name': 'Main',
                'items': [
                  {'id': 'ITEM-001', 'name': 'Product A'},
                ],
              },
            ],
          },
          {
            'id': 'BUNDLE-002',
            'name': 'Bundle 2',
            'price': 200.0,
            'free_shipping': 0,
            'item_groups': [
              {
                'group_name': 'Main',
                'items': [
                  {'id': 'ITEM-002', 'name': 'Product B'},
                ],
              },
            ],
          },
        ];

        mockDio.setResponse(
          '/api/method/jarz_pos.api.pos.get_profile_bundles',
          createSuccessResponse(data: bundles),
        );

        final result = await repository.getBundles('Main POS');

        expect(result, hasLength(2));
        expect(result[0]['name'], equals('Bundle 1'));
        expect(result[0]['free_shipping'], isTrue); // Normalized to bool
        expect(result[1]['free_shipping'], isFalse);
      });

      test(
        'filters disabled bundles after normalizing disabled values',
        () async {
          final bundles = [
            {
              'id': 'BUNDLE-001',
              'name': 'Enabled bool',
              'disabled': false,
              'item_groups': [
                {
                  'group_name': 'Main',
                  'items': [
                    {'id': 'ITEM-001', 'name': 'Product A'},
                  ],
                },
              ],
            },
            {
              'id': 'BUNDLE-002',
              'name': 'Disabled bool',
              'disabled': true,
              'item_groups': [
                {
                  'group_name': 'Main',
                  'items': [
                    {'id': 'ITEM-002', 'name': 'Product B'},
                  ],
                },
              ],
            },
            {
              'id': 'BUNDLE-003',
              'name': 'Enabled int',
              'disabled': 0,
              'item_groups': [
                {
                  'group_name': 'Main',
                  'items': [
                    {'id': 'ITEM-003', 'name': 'Product C'},
                  ],
                },
              ],
            },
            {
              'id': 'BUNDLE-004',
              'name': 'Disabled int',
              'disabled': 1,
              'item_groups': [
                {
                  'group_name': 'Main',
                  'items': [
                    {'id': 'ITEM-004', 'name': 'Product D'},
                  ],
                },
              ],
            },
            {
              'id': 'BUNDLE-005',
              'name': 'Enabled missing',
              'item_groups': [
                {
                  'group_name': 'Main',
                  'items': [
                    {'id': 'ITEM-005', 'name': 'Product E'},
                  ],
                },
              ],
            },
            {
              'id': 'BUNDLE-006',
              'name': 'Disabled string',
              'disabled': 'true',
              'item_groups': [
                {
                  'group_name': 'Main',
                  'items': [
                    {'id': 'ITEM-006', 'name': 'Product F'},
                  ],
                },
              ],
            },
          ];

          mockDio.setResponse(
            '/api/method/jarz_pos.api.pos.get_profile_bundles',
            createSuccessResponse(data: bundles),
          );

          final result = await repository.getBundles('Main POS');

          expect(
            result.map((bundle) => bundle['name']),
            equals(['Enabled bool', 'Enabled int', 'Enabled missing']),
          );
        },
      );

      test('normalizes free_shipping from various formats', () async {
        final bundles = [
          {
            'id': 'B1',
            'name': 'B1',
            'free_shipping': true,
            'item_groups': [
              {
                'group_name': 'Main',
                'items': [
                  {'id': 'ITEM-001', 'name': 'Product A'},
                ],
              },
            ],
          },
          {
            'id': 'B2',
            'name': 'B2',
            'free_shipping': false,
            'item_groups': [
              {
                'group_name': 'Main',
                'items': [
                  {'id': 'ITEM-002', 'name': 'Product B'},
                ],
              },
            ],
          },
          {
            'id': 'B3',
            'name': 'B3',
            'free_shipping': 1,
            'item_groups': [
              {
                'group_name': 'Main',
                'items': [
                  {'id': 'ITEM-003', 'name': 'Product C'},
                ],
              },
            ],
          },
          {
            'id': 'B4',
            'name': 'B4',
            'free_shipping': 0,
            'item_groups': [
              {
                'group_name': 'Main',
                'items': [
                  {'id': 'ITEM-004', 'name': 'Product D'},
                ],
              },
            ],
          },
          {
            'id': 'B5',
            'name': 'B5',
            'free_shipping': '1',
            'item_groups': [
              {
                'group_name': 'Main',
                'items': [
                  {'id': 'ITEM-005', 'name': 'Product E'},
                ],
              },
            ],
          },
          {
            'id': 'B6',
            'name': 'B6',
            'free_shipping': 'true',
            'item_groups': [
              {
                'group_name': 'Main',
                'items': [
                  {'id': 'ITEM-006', 'name': 'Product F'},
                ],
              },
            ],
          },
        ];

        mockDio.setResponse(
          '/api/method/jarz_pos.api.pos.get_profile_bundles',
          createSuccessResponse(data: bundles),
        );

        final result = await repository.getBundles('Main POS');

        expect(result[0]['free_shipping'], isTrue);
        expect(result[1]['free_shipping'], isFalse);
        expect(result[2]['free_shipping'], isTrue);
        expect(result[3]['free_shipping'], isFalse);
        expect(result[4]['free_shipping'], isTrue);
        expect(result[5]['free_shipping'], isTrue);
      });

      test('filters bundles that are disabled or unusable', () async {
        final bundles = [
          {
            'id': 'BUNDLE-VALID',
            'name': 'Valid Bundle',
            'item_groups': [
              {
                'group_name': 'Main',
                'items': [
                  {'id': 'ITEM-001', 'name': 'Product A'},
                  {'id': 'ITEM-002', 'name': 'Product B', 'disabled': 1},
                ],
              },
              {
                'group_name': 'Sides',
                'items': [
                  {'id': '', 'name': 'Missing Id'},
                  {'id': 'ITEM-003', 'name': 'Product C'},
                ],
              },
            ],
          },
          {
            'id': 'BUNDLE-DISABLED',
            'name': 'Disabled Bundle',
            'disabled': 1,
            'item_groups': [
              {
                'group_name': 'Main',
                'items': [
                  {'id': 'ITEM-004', 'name': 'Product D'},
                ],
              },
            ],
          },
          {
            'id': '',
            'name': 'Missing Id',
            'item_groups': [
              {
                'group_name': 'Main',
                'items': [
                  {'id': 'ITEM-005', 'name': 'Product E'},
                ],
              },
            ],
          },
          {'id': 'BUNDLE-NO-GROUPS', 'name': 'No Groups', 'item_groups': []},
          {
            'id': 'BUNDLE-INVALID-GROUPS',
            'name': 'Invalid Groups',
            'item_groups': [
              {
                'group_name': 'Main',
                'items': [
                  {'id': '', 'name': 'Missing Id'},
                  {'id': 'ITEM-006', 'name': '', 'disabled': 0},
                ],
              },
            ],
          },
        ];

        mockDio.setResponse(
          '/api/method/jarz_pos.api.pos.get_profile_bundles',
          createSuccessResponse(data: bundles),
        );

        final result = await repository.getBundles('Main POS');

        expect(result, hasLength(1));
        expect(result.single['id'], equals('BUNDLE-VALID'));
        expect(result.single['item_groups'], hasLength(2));
        expect(result.single['item_groups'][0]['items'], hasLength(1));
        expect(result.single['item_groups'][1]['items'], hasLength(1));
      });

      test(
        'normalizes alternate bundle item field names for picker UI',
        () async {
          final bundles = [
            {
              'id': 'BUNDLE-ALT',
              'name': 'Jarz Signature Trio',
              'item_groups': [
                {
                  'group_name': 'Signature Drinks',
                  'quantity': 3,
                  'items': [
                    {
                      'item_code': 'ITEM-001',
                      'item_name': 'Spanish Latte',
                      'rate': 55.0,
                      'actual_qty': 7,
                    },
                    {
                      'item_code': 'ITEM-002',
                      'item_name': 'Pistachio Latte',
                      'rate': 60.0,
                      'qty': 5,
                    },
                  ],
                },
              ],
            },
          ];

          mockDio.setResponse(
            '/api/method/jarz_pos.api.pos.get_profile_bundles',
            createSuccessResponse(data: bundles),
          );

          final result = await repository.getBundles('Main POS');
          final items =
              result.single['item_groups'].single['items'] as List<dynamic>;

          expect(items, hasLength(2));
          expect(items.first['id'], equals('ITEM-001'));
          expect(items.first['name'], equals('Spanish Latte'));
          expect(items.first['price'], equals(55.0));
          expect(items.first['actual_qty'], equals(7.0));
          expect(items[1]['id'], equals('ITEM-002'));
          expect(items[1]['name'], equals('Pistachio Latte'));
          expect(items[1]['price'], equals(60.0));
          expect(items[1]['qty'], equals(5.0));
        },
      );

      test(
        'assigns stable unique keys to duplicate same-name bundle groups',
        () async {
          final bundles = [
            {
              'id': 'BUNDLE-DUP-GROUPS',
              'name': 'Jarz Large Bundle',
              'item_groups': [
                {
                  'group_name': 'Large',
                  'quantity': 4,
                  'items': [
                    {
                      'id': 'ITEM-001',
                      'name': 'Blueberry Large',
                      'price': 160.0,
                    },
                  ],
                },
                {
                  'group_name': 'Large',
                  'quantity': 2,
                  'items': [
                    {
                      'id': 'ITEM-002',
                      'name': 'Pistachio Large',
                      'price': 170.0,
                    },
                  ],
                },
              ],
            },
          ];

          mockDio.setResponse(
            '/api/method/jarz_pos.api.pos.get_profile_bundles',
            createSuccessResponse(data: bundles),
          );

          final result = await repository.getBundles('Main POS');
          final groups = result.single['item_groups'] as List<dynamic>;

          expect(groups, hasLength(2));
          expect(groups[0]['group_name'], equals('Large'));
          expect(groups[1]['group_name'], equals('Large'));
          expect(groups[0]['group_key'], isNotEmpty);
          expect(groups[1]['group_key'], isNotEmpty);
          expect(groups[0]['group_key'], isNot(equals(groups[1]['group_key'])));
        },
      );

      test('sends profile parameter correctly', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.pos.get_profile_bundles',
          createSuccessResponse(data: []),
        );

        await repository.getBundles('Test Profile');

        final requests = mockDio.requestLog;
        expect(requests.first['data']['profile'], equals('Test Profile'));
      });

      test('throws exception on API error', () async {
        mockDio.setError(
          '/api/method/jarz_pos.api.pos.get_profile_bundles',
          createMockDioException(message: 'Network error'),
        );

        expect(() => repository.getBundles('Main POS'), throwsException);
      });
    });

    group('getTerritories', () {
      test('returns list of territories without search', () async {
        final territories = [
          {'name': 'North', 'territory_name': 'North Region'},
          {'name': 'South', 'territory_name': 'South Region'},
        ];

        mockDio.setResponse(
          '/api/method/jarz_pos.api.customer.get_territories',
          createSuccessResponse(data: territories),
        );

        final result = await repository.getTerritories();

        expect(result, hasLength(2));
        expect(result[0]['name'], equals('North'));
      });

      test('sends search parameter when provided', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.customer.get_territories',
          createSuccessResponse(data: []),
        );

        await repository.getTerritories(search: 'north');

        final requests = mockDio.requestLog;
        expect(requests.first['data']['search'], equals('north'));
      });

      test('sends empty data when search is null', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.customer.get_territories',
          createSuccessResponse(data: []),
        );

        await repository.getTerritories();

        final requests = mockDio.requestLog;
        expect(requests.first['data'], isEmpty);
      });

      test('throws exception on API error', () async {
        mockDio.setError(
          '/api/method/jarz_pos.api.customer.get_territories',
          createMockDioException(message: 'Server error'),
        );

        expect(() => repository.getTerritories(), throwsException);
      });
    });

    group('saveCustomerShippingAddress', () {
      test('should send territory when saving a new address', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.customer.save_customer_shipping_address',
          createSuccessResponse(
            data: {'success': true, 'selected_address_name': 'ADDR-NSR'},
          ),
        );

        await repository.saveCustomerShippingAddress(
          customer: 'CUST-001',
          phone: '01000000000',
          address: 'Street 1',
          territory: 'EGNASRCITY',
        );

        final data = mockDio.requestLog.last['data'] as Map<String, dynamic>;
        expect(data['territory'], 'EGNASRCITY');
      });
    });

    group('getItems', () {
      test('transforms item data to expected format', () async {
        final apiItems = [
          {
            'id': 'ITEM-001',
            'name': 'Product A',
            'item_group': 'Electronics',
            'price': 100.0,
            'qty': 10.0,
            'allow_negative_stock': 1,
          },
        ];

        mockDio.setResponse(
          '/api/method/jarz_pos.api.pos.get_profile_products',
          createSuccessResponse(data: apiItems),
        );

        final result = await repository.getItems('Main POS');

        expect(result, hasLength(1));
        expect(result[0]['name'], equals('ITEM-001'));
        expect(result[0]['item_name'], equals('Product A'));
        expect(result[0]['item_group'], equals('Electronics'));
        expect(result[0]['rate'], equals(100.0));
        expect(result[0]['actual_qty'], equals(10.0));
        expect(result[0]['allow_negative_stock'], isTrue);
        expect(result[0]['stock_uom'], equals('Unit'));
      });

      test('handles missing price and qty with defaults', () async {
        final apiItems = [
          {'id': 'ITEM-001', 'name': 'Product A', 'item_group': 'Electronics'},
        ];

        mockDio.setResponse(
          '/api/method/jarz_pos.api.pos.get_profile_products',
          createSuccessResponse(data: apiItems),
        );

        final result = await repository.getItems('Main POS');

        expect(result[0]['rate'], equals(0.0));
        expect(result[0]['actual_qty'], equals(0.0));
        expect(result[0]['allow_negative_stock'], isFalse);
      });

      test(
        'filters items that are disabled or missing usable identity',
        () async {
          final apiItems = [
            {
              'id': 'ITEM-001',
              'name': 'Product A',
              'item_group': 'Electronics',
            },
            {'id': 'ITEM-002', 'name': 'Disabled Product', 'disabled': 1},
            {'id': '', 'name': 'Missing Id'},
            {'id': 'ITEM-003', 'name': ''},
          ];

          mockDio.setResponse(
            '/api/method/jarz_pos.api.pos.get_profile_products',
            createSuccessResponse(data: apiItems),
          );

          final result = await repository.getItems('Main POS');

          expect(result, hasLength(1));
          expect(result.single['name'], equals('ITEM-001'));
          expect(result.single['item_name'], equals('Product A'));
        },
      );

      test('sends profile parameter correctly', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.pos.get_profile_products',
          createSuccessResponse(data: []),
        );

        await repository.getItems('Branch POS');

        final requests = mockDio.requestLog;
        expect(requests.first['data']['profile'], equals('Branch POS'));
      });

      test('throws exception on API error', () async {
        mockDio.setError(
          '/api/method/jarz_pos.api.pos.get_profile_products',
          createMockDioException(message: 'Failed to load items'),
        );

        expect(() => repository.getItems('Main POS'), throwsException);
      });
    });

    group('B2B pricing context', () {
      test(
        'parses the server-owned policy and sole price-list option',
        () async {
          mockDio.setResponse(
            '/api/method/jarz_pos.api.pos.get_b2b_pricing_context',
            createSuccessResponse(
              data: {
                'profile': 'Nasr city',
                'customer': 'CUST-B2B',
                'order_purpose': 'B2B Supply',
                'commercial_policy': {
                  'name': 'POL-B2B',
                  'policy_name': 'B2B Supply',
                  'order_purpose': 'B2B Supply',
                  'price_list': null,
                  'discount_percentage': 0.0,
                  'waives_shipping_income': false,
                  'no_courier': false,
                },
                'price_list': {
                  'name': 'B2B Price',
                  'display_label': 'B2B Price',
                  'currency': 'EGP',
                  'is_default': 1,
                  'zero_shipping_default': 0,
                },
              },
            ),
          );

          final context = await repository.getB2bPricingContext(
            profile: ' Nasr city ',
            customer: ' CUST-B2B ',
            orderPurpose: ' B2B Supply ',
          );

          expect(context.profile, 'Nasr city');
          expect(context.customer, 'CUST-B2B');
          expect(context.commercialPolicy.name, 'POL-B2B');
          expect(context.commercialPolicy.priceList, isNull);
          expect(context.priceList, {
            'name': 'B2B Price',
            'display_label': 'B2B Price',
            'currency': 'EGP',
            'is_default': true,
            'zero_shipping_default': false,
          });
          expect(mockDio.requestLog.single['data'], {
            'profile': 'Nasr city',
            'customer': 'CUST-B2B',
            'order_purpose': 'B2B Supply',
          });
        },
      );

      test(
        'catalog context is all-or-nothing and forwards every key',
        () async {
          mockDio.setResponse(
            '/api/method/jarz_pos.api.pos.get_profile_products',
            createSuccessResponse(data: []),
          );
          mockDio.setResponse(
            '/api/method/jarz_pos.api.pos.get_profile_bundles',
            createSuccessResponse(data: []),
          );

          await repository.getItems(
            'Nasr city',
            priceList: 'B2B Price',
            customer: 'CUST-B2B',
            orderPurpose: 'B2B Supply',
          );
          await repository.getBundles(
            'Nasr city',
            priceList: 'B2B Price',
            customer: 'CUST-B2B',
            orderPurpose: 'B2B Supply',
          );

          for (final request in mockDio.requestLog) {
            expect(request['data'], {
              'profile': 'Nasr city',
              'price_list': 'B2B Price',
              'customer': 'CUST-B2B',
              'order_purpose': 'B2B Supply',
            });
          }
          expect(
            () => repository.getItems(
              'Nasr city',
              customer: '',
              orderPurpose: '',
            ),
            throwsArgumentError,
          );
          expect(
            () => repository.getBundles('Nasr city', customer: 'CUST-B2B'),
            throwsArgumentError,
          );
        },
      );

      test('rejects a context echoed for another branch', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.pos.get_b2b_pricing_context',
          createSuccessResponse(
            data: {
              'profile': 'Dokki',
              'customer': 'CUST-B2B',
              'order_purpose': 'B2B Supply',
              'commercial_policy': {
                'name': 'POL-B2B',
                'policy_name': 'B2B Supply',
                'order_purpose': 'B2B Supply',
                'price_list': null,
              },
              'price_list': {'name': 'B2B Price'},
            },
          ),
        );

        expect(
          () => repository.getB2bPricingContext(
            profile: 'Nasr city',
            customer: 'CUST-B2B',
            orderPurpose: 'B2B Supply',
          ),
          throwsException,
        );
      });
    });
  });
}
