// Connect a chat to a customer: the thread's link banner (suggestion / not
// linked), the redesigned link sheet (Suggested, search, New customer), the
// new-customer form (instant non-AI prefill, then the AI prefill fills only
// untouched fields; existing mobile offers "Link to them") and Unlink.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/core/constants/api_endpoints.dart';
import 'package:jarz_pos/src/core/network/user_service.dart';
import 'package:jarz_pos/src/core/websocket/websocket_service.dart';
import 'package:jarz_pos/src/features/chat_inbox/data/chat_repository.dart';
import 'package:jarz_pos/src/features/chat_inbox/data/models/chat_models.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/screens/chat_thread_screen.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/widgets/chat_link_sheet.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/widgets/chat_new_customer_form.dart';
import 'package:jarz_pos/src/features/chat_inbox/state/chat_providers.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

Widget _app(List<Override> overrides, Widget home) => ProviderScope(
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
    home: home,
  ),
);

const _territories = <Map<String, dynamic>>[
  {'name': 'Maadi', 'territory_name': 'Maadi', 'territory_name_ar': 'المعادي'},
  {'name': 'Nasr City', 'territory_name': 'Nasr City', 'territory_name_ar': ''},
];

UserRoles _moderator() => UserRoles(
  user: 'mod@jarz.test',
  fullName: 'Mod',
  roles: const ['Moderator', 'POS User', 'Sales User'],
  requirePosShift: true,
  canAccessB2b: false,
  isB2bSalesRep: false,
);

List<Override> _baseOverrides(ChatRepository repo) => [
  chatRepositoryProvider.overrideWithValue(repo),
  userRolesFutureProvider.overrideWith((ref) async => _moderator()),
  webSocketServiceProvider.overrideWithValue(MockWebSocketService()),
  chatUnreadTotalProvider.overrideWith((ref) async => const ChatUnreadTotal()),
  chatTerritoriesProvider.overrideWith((ref) async => _territories),
];

Map<String, dynamic> _candidate({
  String name = 'CUST-1',
  String customerName = 'Ahmed Ali',
  String mobile = '01011112222',
  List<String> reasons = const ['phone'],
  int orders = 4,
}) => {
  'name': name,
  'customer_name': customerName,
  'mobile_no': mobile,
  'territory': 'Maadi',
  'total_orders': orders,
  'last_order_date': '2026-11-01',
  'reasons': reasons,
  'score': 0.9,
};

Map<String, dynamic> _threadJson({
  String? customer,
  String? customerName,
  Map<String, dynamic>? suggestion,
}) => {
  'message': {
    'conversation': {
      'name': 'CHAT-1',
      'channel': 'WhatsApp',
      'contact_name': 'Mona',
      'phone': '01011112222',
      'status': 'Open',
      'customer': customer,
      'customer_name': customerName,
    },
    'messages': [
      {
        'name': 'M-1',
        'direction': 'Inbound',
        'message_type': 'text',
        'body': 'Hi',
        'timestamp': '2026-10-16 10:00:00',
      },
    ],
    'draft': null,
    'customer': customer == null
        ? null
        : {
            'name': customer,
            'customer_name': customerName,
            'mobile_no': '01011112222',
            'total_orders': 4,
          },
    'customer_suggestion': suggestion,
  },
};

/// A repository whose model calls the test controls.
class _FakeRepo extends ChatRepository {
  _FakeRepo() : super(MockDio());

  final prefill = Completer<ChatNewCustomerPrefill>();
  ChatSuggestCustomersResult suggest = const ChatSuggestCustomersResult();
  ChatCreateCustomerResult createResult = ChatCreateCustomerResult(
    conversation: ChatConversationSummary.fromJson({
      'name': 'CHAT-1',
      'customer': 'CUST-NEW',
      'customer_name': 'New Customer',
    }),
    customer: const ChatCustomerCard(
      name: 'CUST-NEW',
      customerName: 'New Customer',
    ),
    created: true,
  );
  final creates = <Map<String, dynamic>>[];
  final searches = <String>[];

  @override
  Future<ChatThread> fetchConversation(
    String name, {
    int limit = 50,
    String? before,
  }) async => ChatThread.fromJson(_threadJson()['message']);

  @override
  Future<ChatSuggestCustomersResult> suggestCustomers(
    String conversation,
  ) async => suggest;

  @override
  Future<ChatNewCustomerPrefill> fetchNewCustomerPrefill(String conversation) =>
      prefill.future;

  @override
  Future<List<ChatCustomerOption>> searchCustomers(String query) async {
    searches.add(query);
    return const <ChatCustomerOption>[];
  }

  @override
  Future<ChatCreateCustomerResult> createCustomerFromChat({
    required String conversation,
    required String customerName,
    required String mobileNo,
    required String address,
    required String territory,
    String? locationLink,
    double? latitude,
    double? longitude,
  }) async {
    creates.add({
      'customer_name': customerName,
      'mobile_no': mobileNo,
      'address': address,
      'territory': territory,
      'location_link': locationLink,
      'latitude': latitude,
      'longitude': longitude,
    });
    return createResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPlatformChannels();

  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('link banner in the thread', () {
    List<Override> overrides(MockDio dio) =>
        _baseOverrides(ChatRepository(dio));

    testWidgets('a suggestion offers one-tap Link and Not them', (
      tester,
    ) async {
      bigScreen(tester);
      final dio = MockDio()
        ..setResponse(
          ApiEndpoints.chatGetConversation,
          _threadJson(suggestion: _candidate()),
        )
        ..setResponse(ApiEndpoints.chatLinkCustomer, {
          'message': {
            'conversation': {
              'name': 'CHAT-1',
              'contact_name': 'Mona',
              'customer': 'CUST-1',
              'customer_name': 'Ahmed Ali',
            },
            'customer': {
              'name': 'CUST-1',
              'customer_name': 'Ahmed Ali',
              'total_orders': 4,
            },
          },
        });
      await tester.pumpWidget(
        _app(overrides(dio), const ChatThreadScreen(conversation: 'CHAT-1')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('chat-link-banner')), findsOneWidget);
      expect(
        find.text('Looks like Ahmed Ali · 01011112222 · 4 orders'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('chat-link-banner-link')));
      await tester.pumpAndSettle();

      final call = dio.requestLog.firstWhere(
        (r) => r['path'] == ApiEndpoints.chatLinkCustomer,
      );
      expect(call['data'], {'conversation': 'CHAT-1', 'customer': 'CUST-1'});
      // Linked now: the banner is gone and the app bar names the customer.
      expect(find.byKey(const ValueKey('chat-link-banner')), findsNothing);
      final subtitle = tester.widget<Text>(
        find.byKey(const ValueKey('chat-thread-subtitle')),
      );
      expect(subtitle.data, startsWith('Ahmed Ali'));
    });

    testWidgets('Not them hides the suggestion for the session and falls back '
        'to "Not linked"', (tester) async {
      bigScreen(tester);
      final dio = MockDio()
        ..setResponse(
          ApiEndpoints.chatGetConversation,
          _threadJson(suggestion: _candidate()),
        );
      await tester.pumpWidget(
        _app(overrides(dio), const ChatThreadScreen(conversation: 'CHAT-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chat-link-banner-dismiss')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('chat-link-banner-link')), findsNothing);
      expect(find.text('Not linked to a customer'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('chat-link-banner-find')),
        findsOneWidget,
      );
    });

    testWidgets('no suggestion: "Not linked" with Find or add', (tester) async {
      bigScreen(tester);
      final dio = MockDio()
        ..setResponse(ApiEndpoints.chatGetConversation, _threadJson());
      await tester.pumpWidget(
        _app(overrides(dio), const ChatThreadScreen(conversation: 'CHAT-1')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Not linked to a customer'), findsOneWidget);
      expect(find.text('Find or add'), findsOneWidget);
    });

    testWidgets('a linked chat shows no banner', (tester) async {
      bigScreen(tester);
      final dio = MockDio()
        ..setResponse(
          ApiEndpoints.chatGetConversation,
          _threadJson(customer: 'CUST-1', customerName: 'Ahmed Ali'),
        );
      await tester.pumpWidget(
        _app(overrides(dio), const ChatThreadScreen(conversation: 'CHAT-1')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-link-banner')), findsNothing);
    });

    testWidgets('Unlink in the customer card confirms, then clears the link', (
      tester,
    ) async {
      bigScreen(tester);
      final dio = MockDio()
        ..setResponse(
          ApiEndpoints.chatGetConversation,
          _threadJson(customer: 'CUST-1', customerName: 'Ahmed Ali'),
        )
        ..setResponse(ApiEndpoints.chatUnlinkCustomer, {
          'message': {
            'conversation': {
              'name': 'CHAT-1',
              'contact_name': 'Mona',
              'customer': null,
            },
          },
        });
      await tester.pumpWidget(
        _app(overrides(dio), const ChatThreadScreen(conversation: 'CHAT-1')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('chat-thread-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customer card'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chat-customer-unlink')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-unlink-dialog')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('chat-unlink-confirm')));
      await tester.pumpAndSettle();

      final call = dio.requestLog.firstWhere(
        (r) => r['path'] == ApiEndpoints.chatUnlinkCustomer,
      );
      expect(call['data'], {'conversation': 'CHAT-1'});
      expect(find.byKey(const ValueKey('chat-link-banner')), findsOneWidget);
      expect(find.text('Not linked to a customer'), findsOneWidget);
    });
  });

  group('link sheet', () {
    Future<void> openSheet(WidgetTester tester, _FakeRepo repo) async {
      await tester.pumpWidget(
        _app(
          _baseOverrides(repo),
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const ValueKey('open-sheet'),
                  onPressed: () => showChatLinkCustomerSheet(
                    context,
                    conversation: 'CHAT-1',
                    fallbackQuery: 'Mona',
                    fallbackName: 'Mona',
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open-sheet')));
      await tester.pumpAndSettle();
    }

    testWidgets('Suggested rows carry reason chips and one tap links', (
      tester,
    ) async {
      bigScreen(tester);
      final repo = _FakeRepo()
        ..suggest = ChatSuggestCustomersResult.fromJson({
          'candidates': [
            _candidate(reasons: ['phone', 'typed_phone']),
            _candidate(
              name: 'CUST-2',
              customerName: 'Ahmed A.',
              mobile: '01099998888',
              reasons: ['name', 'same_contact'],
              orders: 1,
            ),
          ],
          'prefill': {
            'customer_name': 'Ahmed Ali',
            'mobile_no': '01011112222',
            'phones': ['01011112222'],
          },
        });
      await openSheet(tester, repo);

      expect(find.text('Suggested'), findsOneWidget);
      expect(find.text('Same phone'), findsOneWidget);
      expect(find.text('Typed this number'), findsOneWidget);
      expect(find.text('Name match'), findsOneWidget);
      expect(find.text('Linked in another chat'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('chat-link-new-customer')),
        findsOneWidget,
      );

      // The search box is prefilled with the best phone and searched.
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('chat-link-search')))
            .controller!
            .text,
        '01011112222',
      );
      expect(repo.searches, ['01011112222']);
    });

    testWidgets('tapping a suggestion returns it as the choice', (
      tester,
    ) async {
      bigScreen(tester);
      final repo = _FakeRepo()
        ..suggest = ChatSuggestCustomersResult.fromJson({
          'candidates': [_candidate()],
          'prefill': {'customer_name': 'Ahmed Ali'},
        });
      ChatLinkChoice? picked;
      await tester.pumpWidget(
        _app(
          _baseOverrides(repo),
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                key: const ValueKey('open-sheet'),
                onPressed: () async => picked = await showChatLinkCustomerSheet(
                  context,
                  conversation: 'CHAT-1',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open-sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('chat-suggest-CUST-1')));
      await tester.pumpAndSettle();

      expect(picked?.option?.name, 'CUST-1');
      expect(picked?.option?.customerName, 'Ahmed Ali');
      expect(picked?.created, isNull);
      expect(
        find.byKey(const ValueKey('chat-link-new-customer')),
        findsNothing,
      );
    });

    testWidgets('without a phone the search is seeded with the cleaned name', (
      tester,
    ) async {
      bigScreen(tester);
      final repo = _FakeRepo()
        ..suggest = ChatSuggestCustomersResult.fromJson({
          'candidates': <Map<String, dynamic>>[],
          'prefill': {'customer_name': 'Ahmed Ali'},
        });
      await openSheet(tester, repo);
      expect(repo.searches, ['Ahmed Ali']);
    });
  });

  group('new customer form', () {
    Future<_Hosted> pumpForm(
      WidgetTester tester,
      _FakeRepo repo, {
      ChatNewCustomerPrefill initial = const ChatNewCustomerPrefill(
        customerName: 'ahmed.ali',
        mobileNo: '01011112222',
        phones: ['01011112222', '01155556666'],
      ),
      bool aiDone = true,
    }) async {
      bigScreen(tester);
      if (aiDone) repo.prefill.complete(const ChatNewCustomerPrefill());
      final hosted = _Hosted();
      await tester.pumpWidget(
        _app(
          _baseOverrides(repo),
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                key: const ValueKey('open-form'),
                onPressed: () async {
                  hosted.result = await Navigator.of(context)
                      .push<ChatLinkChoice>(
                        MaterialPageRoute(
                          builder: (_) => ChatNewCustomerScreen(
                            conversation: 'CHAT-1',
                            initial: initial,
                          ),
                        ),
                      );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open-form')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      return hosted;
    }

    String text(WidgetTester tester, String key) => tester
        .widget<TextFormField>(find.byKey(ValueKey(key)))
        .controller!
        .text;

    testWidgets('opens at once with the non-AI prefill and a loading note', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await pumpForm(tester, repo, aiDone: false);

      expect(text(tester, 'chat-newcust-name'), 'ahmed.ali');
      expect(text(tester, 'chat-newcust-mobile'), '01011112222');
      expect(
        find.byKey(const ValueKey('chat-newcust-ai-loading')),
        findsOneWidget,
      );
      expect(find.text('Filling from the chat…'), findsOneWidget);
      // One chip per phone seen in the chat.
      expect(
        find.byKey(const ValueKey('chat-newcust-phone-01011112222')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('chat-newcust-phone-01155556666')),
        findsOneWidget,
      );
    });

    testWidgets('the AI prefill fills untouched fields and never overwrites '
        'what the moderator typed', (tester) async {
      final repo = _FakeRepo();
      await pumpForm(tester, repo, aiDone: false);

      // The moderator edits the name while the AI is still reading.
      await tester.enterText(
        find.byKey(const ValueKey('chat-newcust-name')),
        'Ahmed Ali (typed)',
      );
      await tester.pump();

      repo.prefill.complete(
        const ChatNewCustomerPrefill(
          customerName: 'أحمد علي',
          mobileNo: '01011112222',
          phones: ['01011112222', '01155556666'],
          address: 'شارع 9، المعادي، عمارة 4',
          territory: 'Maadi',
          territoryName: 'Maadi',
          location: '30.0444,31.2357',
          ai: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('chat-newcust-ai-loading')),
        findsNothing,
      );
      // Touched: kept.
      expect(text(tester, 'chat-newcust-name'), 'Ahmed Ali (typed)');
      // Untouched: filled.
      expect(text(tester, 'chat-newcust-address'), 'شارع 9، المعادي، عمارة 4');
      expect(
        find.byKey(const ValueKey('chat-newcust-location')),
        findsOneWidget,
      );
      expect(find.text('المعادي'), findsWidgets);
    });

    testWidgets('a field the moderator did not touch takes the AI value', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await pumpForm(tester, repo, aiDone: false);
      repo.prefill.complete(
        const ChatNewCustomerPrefill(customerName: 'Ahmed Ali', ai: true),
      );
      await tester.pumpAndSettle();
      expect(text(tester, 'chat-newcust-name'), 'Ahmed Ali');
    });

    testWidgets('a failed AI read leaves the form usable with a note', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await pumpForm(tester, repo, aiDone: false);
      repo.prefill.completeError(Exception('timeout'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chat-newcust-ai-loading')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('chat-newcust-ai-note')),
        findsOneWidget,
      );
      expect(text(tester, 'chat-newcust-name'), 'ahmed.ali');
    });

    testWidgets('validates name, mobile, area and address like the POS', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await pumpForm(tester, repo, initial: const ChatNewCustomerPrefill());
      await tester.ensureVisible(
        find.byKey(const ValueKey('chat-newcust-create')),
      );
      await tester.tap(find.byKey(const ValueKey('chat-newcust-create')));
      await tester.pumpAndSettle();
      expect(repo.creates, isEmpty);
      final context = tester.element(
        find.byKey(const ValueKey('chat-newcust-form')),
      );
      final l10n = AppLocalizations.of(context);
      expect(find.text(l10n.customerNameRequired), findsOneWidget);
      expect(find.text(l10n.mobileNumberRequired), findsOneWidget);
      expect(find.text(l10n.territorySelectRequired), findsOneWidget);
      expect(find.text(l10n.addressRequired), findsOneWidget);
    });

    testWidgets('Create & link sends the form and returns the created choice', (
      tester,
    ) async {
      final repo = _FakeRepo();
      final hosted = await pumpForm(
        tester,
        repo,
        initial: const ChatNewCustomerPrefill(
          customerName: 'Ahmed Ali',
          mobileNo: '01011112222',
          address: '9 Road, Maadi',
          territory: 'Maadi',
          location: '30.0444,31.2357',
        ),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('chat-newcust-create')),
      );
      await tester.tap(find.byKey(const ValueKey('chat-newcust-create')));
      await tester.pumpAndSettle();

      expect(repo.creates, [
        {
          'customer_name': 'Ahmed Ali',
          'mobile_no': '01011112222',
          'address': '9 Road, Maadi',
          'territory': 'Maadi',
          'location_link': null,
          'latitude': 30.0444,
          'longitude': 31.2357,
        },
      ]);
      expect(hosted.result?.created?.customer?.name, 'CUST-NEW');
      expect(find.byKey(const ValueKey('chat-newcust-form')), findsNothing);
    });

    testWidgets(
      'an existing mobile shows who owns it and offers Link to them',
      (tester) async {
        final repo = _FakeRepo()
          ..createResult = ChatCreateCustomerResult(
            existing: ChatCustomerCandidate.fromJson(_candidate()),
          );
        final hosted = await pumpForm(
          tester,
          repo,
          initial: const ChatNewCustomerPrefill(
            customerName: 'Ahmed',
            mobileNo: '01011112222',
            address: '9 Road',
            territory: 'Maadi',
          ),
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('chat-newcust-create')),
        );
        await tester.tap(find.byKey(const ValueKey('chat-newcust-create')));
        await tester.pumpAndSettle();

        // Nothing was created; the form stays open with the explanation.
        expect(hosted.result, isNull);
        expect(find.text('This number belongs to Ahmed Ali'), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const ValueKey('chat-newcust-existing-link')),
        );
        await tester.tap(
          find.byKey(const ValueKey('chat-newcust-existing-link')),
        );
        await tester.pumpAndSettle();
        expect(hosted.result?.option?.name, 'CUST-1');
        expect(hosted.result?.created, isNull);
      },
    );
  });
}

class _Hosted {
  ChatLinkChoice? result;
}
