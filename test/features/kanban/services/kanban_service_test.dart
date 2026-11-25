import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/features/kanban/services/kanban_service.dart';
import '../../../helpers/mock_services.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPlatformChannels();

  group('KanbanService - Invoice Scenarios', () {
    late MockDio mockDio;
    late KanbanService service;

    setUp(() {
      mockDio = MockDio();
      service = KanbanService(mockDio);
    });

    group('Sales Partner Invoices', () {
      test('salesPartnerUnpaidOutForDelivery - creates payment and DN for unpaid sales partner invoice', () async {
        final expectedResponse = {
          'success': true,
          'payment_entry': 'PE-001',
          'delivery_note': 'DN-001',
          'amount': '100.00',
          'invoice': 'INV-001',
        };

        mockDio.setResponse(
          '/api/method/jarz_pos.jarz_pos.services.delivery_handling.sales_partner_unpaid_out_for_delivery',
          createSuccessResponse(data: expectedResponse),
        );

        final result = await service.salesPartnerUnpaidOutForDelivery(
          invoiceName: 'INV-001',
          posProfile: 'Main POS',
        );

        expect(result['success'], isTrue);
        expect(result['payment_entry'], equals('PE-001'));
        expect(result['delivery_note'], equals('DN-001'));
        expect(result['amount'], equals('100.00'));
      });

      test('salesPartnerUnpaidOutForDelivery - supports custom mode of payment', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.jarz_pos.services.delivery_handling.sales_partner_unpaid_out_for_delivery',
          createSuccessResponse(data: {'success': true}),
        );

        await service.salesPartnerUnpaidOutForDelivery(
          invoiceName: 'INV-001',
          posProfile: 'Main POS',
          modeOfPayment: 'Wallet',
        );

        final requests = mockDio.requestLog;
        expect(requests.last['data']['mode_of_payment'], equals('Wallet'));
      });

      test('salesPartnerUnpaidOutForDelivery - throws on error response', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.jarz_pos.services.delivery_handling.sales_partner_unpaid_out_for_delivery',
          createSuccessResponse(data: {
            'success': false,
            'error': 'Payment creation failed',
          }),
        );

        expect(
          () => service.salesPartnerUnpaidOutForDelivery(
            invoiceName: 'INV-001',
            posProfile: 'Main POS',
          ),
          throwsException,
        );
      });

      test('salesPartnerPaidOutForDelivery - creates DN for already paid sales partner invoice', () async {
        final expectedResponse = {
          'success': true,
          'delivery_note': 'DN-002',
          'invoice': 'INV-002',
        };

        mockDio.setResponse(
          '/api/method/jarz_pos.jarz_pos.services.delivery_handling.sales_partner_paid_out_for_delivery',
          createSuccessResponse(data: expectedResponse),
        );

        final result = await service.salesPartnerPaidOutForDelivery(
          invoiceId: 'INV-002',
        );

        expect(result['success'], isTrue);
        expect(result['delivery_note'], equals('DN-002'));
      });

      test('salesPartnerPaidOutForDelivery - throws on error response', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.jarz_pos.services.delivery_handling.sales_partner_paid_out_for_delivery',
          createSuccessResponse(data: {
            'success': false,
            'error': 'Delivery note creation failed',
          }),
        );

        expect(
          () => service.salesPartnerPaidOutForDelivery(invoiceId: 'INV-002'),
          throwsException,
        );
      });
    });

    group('Pickup Invoices', () {
      test('updateInvoiceState - handles pickup invoice state changes directly', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.kanban.update_invoice_state',
          createSuccessResponse(data: {
            'success': true,
            'invoice_id': 'INV-PICKUP-001',
            'new_state': 'Ready for Pickup',
          }),
        );

        final result = await service.updateInvoiceState('INV-PICKUP-001', 'Ready for Pickup');

        expect(result, isTrue);
        final requests = mockDio.requestLog;
        expect(requests.last['data']['invoice_id'], equals('INV-PICKUP-001'));
        expect(requests.last['data']['new_state'], equals('Ready for Pickup'));
      });
    });

    group('Paid Invoices - Settle Now', () {
      test('settleCourierCollectedPayment - handles when courier collected payment from customer', () async {
        final expectedResponse = {
          'success': true,
          'journal_entry': 'JE-001',
          'net_amount': 50.00,
          'order_amount': 150.00,
          'shipping_expense': 100.00,
        };

        mockDio.setResponse(
          '/api/method/jarz_pos.api.couriers.settle_courier_collected_payment',
          createSuccessResponse(data: expectedResponse),
        );

        final result = await service.settleCourierCollectedPayment(
          invoiceName: 'INV-PAID-001',
          posProfile: 'Main POS',
          partyType: 'Employee',
          party: 'EMP-001',
        );

        expect(result['success'], isTrue);
        expect(result['journal_entry'], equals('JE-001'));
        expect(result['net_amount'], equals(50.00));
      });

      test('settleSingleInvoicePaid - handles when branch pays courier shipping expense', () async {
        final expectedResponse = {
          'success': true,
          'journal_entry': 'JE-002',
          'shipping_expense': 20.00,
        };

        mockDio.setResponse(
          '/api/method/jarz_pos.api.couriers.settle_single_invoice_paid',
          createSuccessResponse(data: expectedResponse),
        );

        final result = await service.settleSingleInvoicePaid(
          invoiceName: 'INV-PAID-002',
          posProfile: 'Main POS',
          partyType: 'Supplier',
          party: 'SUPP-001',
        );

        expect(result['success'], isTrue);
        expect(result['journal_entry'], equals('JE-002'));
      });

      test('settleCourierCollectedPayment - sends correct parameters', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.couriers.settle_courier_collected_payment',
          createSuccessResponse(data: {'success': true}),
        );

        await service.settleCourierCollectedPayment(
          invoiceName: 'INV-003',
          posProfile: 'Branch POS',
          partyType: 'Employee',
          party: 'EMP-002',
        );

        final requests = mockDio.requestLog;
        expect(requests.last['data']['invoice_name'], equals('INV-003'));
        expect(requests.last['data']['pos_profile'], equals('Branch POS'));
        expect(requests.last['data']['party_type'], equals('Employee'));
        expect(requests.last['data']['party'], equals('EMP-002'));
      });

      test('settleSingleInvoicePaid - throws on settlement failure', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.couriers.settle_single_invoice_paid',
          createSuccessResponse(data: {
            'error': 'Insufficient balance',
          }),
        );

        expect(
          () => service.settleSingleInvoicePaid(
            invoiceName: 'INV-004',
            posProfile: 'Main POS',
            partyType: 'Employee',
            party: 'EMP-003',
          ),
          throwsException,
        );
      });
    });

    group('Paid Invoices - Settle Later', () {
      test('handleOutForDeliveryTransition - supports settle later mode', () async {
        final expectedResponse = {
          'success': true,
          'courier_transaction': 'CT-001',
          'invoice': 'INV-PAID-LATER-001',
          'mode': 'later',
        };

        mockDio.setResponse(
          '/api/method/jarz_pos.api.couriers.handle_out_for_delivery_transition',
          createSuccessResponse(data: expectedResponse),
        );

        final result = await service.handleOutForDeliveryTransition(
          invoiceName: 'INV-PAID-LATER-001',
          courier: 'COURIER-001',
          mode: 'later',
          posProfile: 'Main POS',
          idempotencyToken: 'token-123',
        );

        expect(result['success'], isTrue);
        expect(result['mode'], equals('later'));
        expect(result['courier_transaction'], equals('CT-001'));
      });

      test('handleOutForDeliveryTransition - includes optional party info for settle later', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.couriers.handle_out_for_delivery_transition',
          createSuccessResponse(data: {'success': true}),
        );

        await service.handleOutForDeliveryTransition(
          invoiceName: 'INV-005',
          courier: 'COURIER-002',
          mode: 'later',
          posProfile: 'Main POS',
          idempotencyToken: 'token-456',
          partyType: 'Employee',
          party: 'EMP-004',
        );

        final requests = mockDio.requestLog;
        expect(requests.last['data']['party_type'], equals('Employee'));
        expect(requests.last['data']['party'], equals('EMP-004'));
        expect(requests.last['data']['mode'], equals('later'));
      });
    });

    group('Unpaid Invoices - Settle Now', () {
      test('handleOutForDeliveryTransition - handles unpaid with pay_now mode', () async {
        final expectedResponse = {
          'success': true,
          'payment_entry': 'PE-002',
          'courier_transaction': 'CT-002',
          'amount': 200.00,
          'shipping_amount': 25.00,
        };

        mockDio.setResponse(
          '/api/method/jarz_pos.api.couriers.handle_out_for_delivery_transition',
          createSuccessResponse(data: expectedResponse),
        );

        final result = await service.handleOutForDeliveryTransition(
          invoiceName: 'INV-UNPAID-001',
          courier: 'COURIER-003',
          mode: 'pay_now',
          posProfile: 'Main POS',
          idempotencyToken: 'token-789',
        );

        expect(result['success'], isTrue);
        expect(result['payment_entry'], equals('PE-002'));
        expect(result['courier_transaction'], equals('CT-002'));
      });

      test('markCourierOutstanding - creates payment entry for unpaid invoice', () async {
        final expectedResponse = {
          'payment_entry': 'PE-003',
          'courier_transaction': 'CT-003',
          'amount': 150.00,
        };

        mockDio.setResponse(
          '/api/method/jarz_pos.api.couriers.mark_courier_outstanding',
          createSuccessResponse(data: expectedResponse),
        );

        final result = await service.markCourierOutstanding(
          invoiceName: 'INV-UNPAID-002',
          courier: 'COURIER-004',
        );

        expect(result['success'], isTrue); // Added by normalization
        expect(result['payment_entry'], equals('PE-003'));
        expect(result['courier_transaction'], equals('CT-003'));
      });

      test('markCourierOutstanding - includes party info when provided', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.couriers.mark_courier_outstanding',
          createSuccessResponse(data: {'payment_entry': 'PE-004'}),
        );

        await service.markCourierOutstanding(
          invoiceName: 'INV-UNPAID-003',
          courier: 'COURIER-005',
          partyType: 'Supplier',
          party: 'SUPP-002',
        );

        final requests = mockDio.requestLog;
        expect(requests.last['data']['party_type'], equals('Supplier'));
        expect(requests.last['data']['party'], equals('SUPP-002'));
      });

      test('markCourierOutstanding - handles string response as success', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.couriers.mark_courier_outstanding',
          createSuccessResponse(data: 'OK'),
        );

        final result = await service.markCourierOutstanding(
          invoiceName: 'INV-UNPAID-004',
          courier: 'COURIER-006',
        );

        expect(result['success'], isTrue);
        expect(result['message'], equals('OK'));
      });
    });

    group('Unpaid Invoices - Settle Later', () {
      test('handleOutForDeliveryTransition - handles unpaid with later mode', () async {
        final expectedResponse = {
          'success': true,
          'payment_entry': 'PE-005',
          'courier_transaction': 'CT-005',
          'mode': 'later',
          'deferred': true,
        };

        mockDio.setResponse(
          '/api/method/jarz_pos.api.couriers.handle_out_for_delivery_transition',
          createSuccessResponse(data: expectedResponse),
        );

        final result = await service.handleOutForDeliveryTransition(
          invoiceName: 'INV-UNPAID-LATER-001',
          courier: 'COURIER-007',
          mode: 'later',
          posProfile: 'Main POS',
          idempotencyToken: 'token-abc',
        );

        expect(result['success'], isTrue);
        expect(result['mode'], equals('later'));
        expect(result['payment_entry'], equals('PE-005'));
      });
    });

    group('Settlement Preview', () {
      test('getInvoiceSettlementPreview - returns preview data for invoice', () async {
        final expectedPreview = {
          'invoice_name': 'INV-001',
          'outstanding': 100.00,
          'shipping_expense': 20.00,
          'net_amount': 80.00,
          'party_type': 'Employee',
          'party': 'EMP-001',
          'last_payment_seconds': 5,
          'is_unpaid_effective': false,
        };

        mockDio.setResponse(
          '/api/method/jarz_pos.api.invoices.get_invoice_settlement_preview',
          createSuccessResponse(data: expectedPreview),
        );

        final result = await service.getInvoiceSettlementPreview(
          invoiceName: 'INV-001',
        );

        expect(result['invoice_name'], equals('INV-001'));
        expect(result['outstanding'], equals(100.00));
        expect(result['net_amount'], equals(80.00));
      });

      test('getInvoiceSettlementPreview - includes party info when provided', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.invoices.get_invoice_settlement_preview',
          createSuccessResponse(data: {}),
        );

        await service.getInvoiceSettlementPreview(
          invoiceName: 'INV-002',
          partyType: 'Supplier',
          party: 'SUPP-001',
        );

        final requests = mockDio.requestLog;
        expect(requests.last['queryParameters']?['party_type'], equals('Supplier'));
        expect(requests.last['queryParameters']?['party'], equals('SUPP-001'));
      });

      test('getInvoiceSettlementPreview - throws on invalid response', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.invoices.get_invoice_settlement_preview',
          createSuccessResponse(data: null),
        );

        expect(
          () => service.getInvoiceSettlementPreview(invoiceName: 'INV-003'),
          throwsException,
        );
      });
    });

    group('Courier Management', () {
      test('fetchCouriers - returns list of active couriers', () async {
        final couriersData = [
          {
            'party_type': 'Employee',
            'party': 'EMP-001',
            'display_name': 'John Courier',
            'branch': 'Main Branch',
          },
          {
            'party_type': 'Supplier',
            'party': 'SUPP-001',
            'display_name': 'Fast Delivery Inc',
            'delivery_partner': 'Deliverk',
          },
        ];

        mockDio.setResponse(
          '/api/method/jarz_pos.api.couriers.get_active_couriers',
          createSuccessResponse(data: couriersData),
        );

        final result = await service.fetchCouriers(posProfile: 'Main Branch');

        expect(result, hasLength(2));
        expect(result[0]['party_type'], equals('Employee'));
        expect(result[0]['display_name'], equals('John Courier'));
        expect(result[0]['courier_name'], equals('John Courier')); // Legacy key
        expect(result[1]['party_type'], equals('Supplier'));
        // The partner link drives the partner-fee prompt on dispatch.
        expect(result[0].containsKey('delivery_partner'), isFalse);
        expect(result[1]['delivery_partner'], equals('Deliverk'));

        final request = mockDio.requestLog.last;
        expect(request['queryParameters']['pos_profile'], equals('Main Branch'));
      });

      test('createDeliveryParty - creates new courier party', () async {
        final expectedResponse = {
          'party_type': 'Employee',
          'party': 'EMP-NEW-001',
          'display_name': 'New Courier',
          'phone': '1234567890',
          'branch': 'Branch A',
        };

        mockDio.setResponse(
          '/api/method/jarz_pos.api.couriers.create_delivery_party',
          createSuccessResponse(data: expectedResponse),
        );

        final result = await service.createDeliveryParty(
          partyType: 'Employee',
          name: 'New Courier',
          phone: '1234567890',
          posProfile: 'Branch A POS',
        );

        expect(result['party_type'], equals('Employee'));
        expect(result['party'], equals('EMP-NEW-001'));
        expect(result['display_name'], equals('New Courier'));
      });

      test('createDeliveryParty - supports first/last name', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.couriers.create_delivery_party',
          createSuccessResponse(data: {
            'party_type': 'Employee',
            'party': 'EMP-002',
            'display_name': 'Jane Doe',
          }),
        );

        await service.createDeliveryParty(
          partyType: 'Employee',
          firstName: 'Jane',
          lastName: 'Doe',
          phone: '9876543210',
        );

        final requests = mockDio.requestLog;
        expect(requests.last['data']['first_name'], equals('Jane'));
        expect(requests.last['data']['last_name'], equals('Doe'));
      });
    });

    group('Idempotency', () {
      test('generateIdempotencyToken - creates unique tokens', () {
        final token1 = service.generateIdempotencyToken();
        final token2 = service.generateIdempotencyToken();

        expect(token1, isNotEmpty);
        expect(token2, isNotEmpty);
        expect(token1, isNot(equals(token2)));
        expect(token1, startsWith('ofd-'));
      });

      test('handleOutForDeliveryTransition - uses provided idempotency token', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.couriers.handle_out_for_delivery_transition',
          createSuccessResponse(data: {'success': true}),
        );

        const customToken = 'custom-token-12345';
        await service.handleOutForDeliveryTransition(
          invoiceName: 'INV-006',
          courier: 'COURIER-008',
          mode: 'pay_now',
          posProfile: 'Main POS',
          idempotencyToken: customToken,
        );

        final requests = mockDio.requestLog;
        expect(requests.last['data']['idempotency_token'], equals(customToken));
      });
    });

    group('Invoice Notes', () {
      test('getInvoiceNotes - returns custom note history for the invoice', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.kanban.get_invoice_notes',
          createSuccessResponse(data: {
            'success': true,
            'data': [
              {
                'name': 'JIN-001',
                'sales_invoice': 'INV-001',
                'note': 'Check customer gate code',
                'added_by': 'user@example.com',
                'added_by_full_name': 'User One',
                'added_on': '2026-06-04 12:00:00',
              },
            ],
            'note_count': 1,
          }),
        );

        final notes = await service.getInvoiceNotes('INV-001');

        expect(notes, hasLength(1));
        expect(notes.first.salesInvoice, 'INV-001');
        expect(notes.first.note, 'Check customer gate code');
        expect(notes.first.addedByFullName, 'User One');
        final requests = mockDio.requestLog;
        expect(requests.last['queryParameters']['invoice_id'], equals('INV-001'));
      });

      test('addInvoiceNote - posts note text and returns updated count', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.kanban.add_invoice_note',
          createSuccessResponse(data: {
            'success': true,
            'data': {
              'name': 'JIN-002',
              'sales_invoice': 'INV-001',
              'note': 'Leave at reception',
              'added_by': 'user@example.com',
              'added_by_full_name': 'User One',
              'added_on': '2026-06-04 12:10:00',
            },
            'note_count': 2,
          }),
        );

        final result = await service.addInvoiceNote(
          invoiceId: 'INV-001',
          note: '  Leave at reception  ',
        );

        expect(result.note.salesInvoice, 'INV-001');
        expect(result.note.note, 'Leave at reception');
        expect(result.noteCount, 2);
        final requests = mockDio.requestLog;
        expect(requests.last['data']['invoice_id'], equals('INV-001'));
        expect(requests.last['data']['note'], equals('Leave at reception'));
      });
    });

    group('Error Handling', () {
      test('throws exception on network error', () async {
        mockDio.setError(
          '/api/method/jarz_pos.api.couriers.settle_single_invoice_paid',
          createMockDioException(message: 'Network timeout'),
        );

        expect(
          () => service.settleSingleInvoicePaid(
            invoiceName: 'INV-ERR-001',
            posProfile: 'Main POS',
            partyType: 'Employee',
            party: 'EMP-001',
          ),
          throwsA(isA<DioException>()),
        );
      });

      test('handles API errors gracefully', () async {
        mockDio.setResponse(
          '/api/method/jarz_pos.api.couriers.handle_out_for_delivery_transition',
          createSuccessResponse(data: {
            'success': false,
            'error': 'Invoice already processed',
          }),
        );

        expect(
          () => service.handleOutForDeliveryTransition(
            invoiceName: 'INV-ERR-002',
            courier: 'COURIER-009',
            mode: 'pay_now',
            posProfile: 'Main POS',
            idempotencyToken: 'token-err',
          ),
          throwsException,
        );
      });
    });

    group('Customer Shipping Address', () {
      const savePath =
          '/api/method/jarz_pos.api.customer.save_customer_shipping_address';

      test('saveCustomerShippingAddress forwards the picked territory for a new address', () async {
        mockDio.setResponse(
          savePath,
          createSuccessResponse(data: {
            'success': true,
            'selected_address_name': 'ADDR-NEW',
          }),
        );

        await service.saveCustomerShippingAddress(
          customer: 'CUST-001',
          phone: '01000000000',
          invoice: 'INV-001',
          address: '12 New Street',
          territory: 'Maadi',
        );

        final data = mockDio.requestLog.last['data'] as Map;
        expect(data['territory'], equals('Maadi'));
        expect(data['address'], equals('12 New Street'));
        expect(data['invoice'], equals('INV-001'));
      });

      test('saveCustomerShippingAddress omits territory when not provided', () async {
        mockDio.setResponse(
          savePath,
          createSuccessResponse(data: {
            'success': true,
            'selected_address_name': 'ADDR-1',
          }),
        );

        await service.saveCustomerShippingAddress(
          customer: 'CUST-001',
          phone: '01000000000',
          addressName: 'ADDR-1',
        );

        final data = mockDio.requestLog.last['data'] as Map;
        expect(data.containsKey('territory'), isFalse);
        expect(data['address_name'], equals('ADDR-1'));
      });
    });

    group('Payment Receipt Images', () {
      const uploadPath =
          '/api/method/jarz_pos.api.payment_receipts.upload_receipt_image';

      // The money-path regression: a picker handed back a zero-byte file, so
      // `image_data` went up as ''. The backend answered "File does not exist",
      // the sheet still reported success, and an InstaPay payment was confirmed
      // with no proof attached. This is the chokepoint every caller — present
      // and future — passes through, so the assertion that matters is that the
      // request is never made at all.
      test('rejects an empty image_data before it reaches the server', () async {
        mockDio.setResponse(
          uploadPath,
          createSuccessResponse(data: {'success': true, 'file_url': '/x.png'}),
        );

        await expectLater(
          service.uploadReceiptImage(
            receiptName: 'PR-001',
            imageData: '',
            filename: 'receipt.png',
          ),
          throwsA(isA<Exception>()),
        );

        // Load-bearing: nothing was sent. A guard that let the POST through and
        // only checked the reply would still leave the receipt half-created.
        expect(mockDio.requestLog, isEmpty);
      });

      test('uploads normally when the image has bytes', () async {
        mockDio.setResponse(
          uploadPath,
          createSuccessResponse(data: {'success': true, 'file_url': '/x.png'}),
        );

        final result = await service.uploadReceiptImage(
          receiptName: 'PR-001',
          imageData: 'aGVsbG8=',
          filename: 'receipt.png',
        );

        expect(result['success'], isTrue);
        expect(mockDio.requestLog.last['data']['image_data'], 'aGVsbG8=');
      });
    });

    group('Order returns', () {
      const endpoint = '/api/method/jarz_pos.api.returns.submit_invoice_return';

      Future<Map<String, dynamic>> sentPayload({String? goodsCondition}) async {
        mockDio.setResponse(
          endpoint,
          createSuccessResponse(
            data: {'success': true, 'credit_note': 'ACC-SINV-CN-1'},
          ),
        );
        await service.submitInvoiceReturn(
          invoiceName: 'INV-RET-1',
          lines: const [
            {'si_detail': 'row-1', 'qty': 1},
          ],
          reason: 'Melted on the way back',
          returnType: 'Failed Delivery',
          refundMode: 'customer_credit',
          payCourierForTrip: true,
          goodsCondition: goodsCondition,
        );
        return Map<String, dynamic>.from(mockDio.requestLog.last['data'] as Map);
      }

      test('submitInvoiceReturn - sends the goods answer under the server key',
          () async {
        // The key is the contract with api.returns.submit_invoice_return; a
        // misspelling is silently dropped by the server and the jars restock.
        expect((await sentPayload(goodsCondition: 'waste'))['goods_condition'],
            'waste');
        expect((await sentPayload(goodsCondition: 'restock'))['goods_condition'],
            'restock');
      });

      test('submitInvoiceReturn - sends no goods key when the dialog did not ask',
          () async {
        final payload = await sentPayload();
        expect(payload.containsKey('goods_condition'), isFalse);
        expect(payload['return_type'], 'Failed Delivery');
      });
    });
  });
}
