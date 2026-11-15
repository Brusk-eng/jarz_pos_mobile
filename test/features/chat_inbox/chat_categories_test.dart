// AI contact categories (Supplier, Content Creator): the tile chip, the inbox
// filter chips + `category` parameter, the thread's "Contact type" action and
// subtitle, realtime summaries carrying the fields, and the new models parsed
// defensively (every new key optional, so an older server still works).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/core/constants/api_endpoints.dart';
import 'package:jarz_pos/src/core/constants/ws_events.dart';
import 'package:jarz_pos/src/core/network/user_service.dart';
import 'package:jarz_pos/src/core/websocket/websocket_service.dart';
import 'package:jarz_pos/src/features/chat_inbox/data/chat_repository.dart';
import 'package:jarz_pos/src/features/chat_inbox/data/models/chat_models.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/screens/chat_inbox_screen.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/screens/chat_thread_screen.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/widgets/chat_conversation_tile.dart';
import 'package:jarz_pos/src/features/chat_inbox/state/chat_providers.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

final _now = DateTime(2026, 10, 16, 10, 30);

UserRoles _moderator() => UserRoles(
  user: 'mod@jarz.test',
  fullName: 'Mod',
  roles: const ['Moderator', 'POS User', 'Sales User'],
  requirePosShift: true,
  canAccessB2b: false,
  isB2bSalesRep: false,
);

List<Override> _overrides(MockDio dio, WebSocketService ws) => [
  chatRepositoryProvider.overrideWithValue(ChatRepository(dio)),
  userRolesFutureProvider.overrideWith((ref) async => _moderator()),
  webSocketServiceProvider.overrideWithValue(ws),
  chatClockProvider.overrideWithValue(() => _now),
  chatUnreadTotalProvider.overrideWith(
    (ref) async => const ChatUnreadTotal(openCount: 3, unreadTotal: 3),
  ),
];

Widget _app(List<Override> overrides, Widget home, {String locale = 'en'}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: Locale(locale),
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

Map<String, dynamic> _summary(
  String name, {
  String? category,
  String? source,
  String? reason,
  String contact = 'Contact',
  String lastAt = '2026-10-16 10:00:00',
}) => {
  'name': name,
  'channel': 'WhatsApp',
  'contact_name': contact,
  'status': 'Open',
  'last_message_at': lastAt,
  'last_message_preview': 'Hello',
  'last_direction': 'Inbound',
  'unread_count': 0,
  'contact_category': category,
  'contact_category_source': source,
  'contact_category_reason': reason,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPlatformChannels();

  group('models: every new key is optional', () {
    test('ConversationSummary without category keys (older server)', () {
      final s = ChatConversationSummary.fromJson({'name': 'CHAT-1'});
      expect(s.contactCategory, isNull);
      expect(s.contactCategorySource, isNull);
      expect(s.contactCategoryReason, isNull);
      expect(s.categoryIsAi, isFalse);
    });

    test('ConversationSummary reads the category fields and keeps them across '
        'copyWith', () {
      final s = ChatConversationSummary.fromJson(
        _summary(
          'CHAT-1',
          category: 'Supplier',
          source: 'AI',
          reason: 'Offers packaging boxes',
        ),
      );
      expect(s.contactCategory, 'Supplier');
      expect(s.categoryIsAi, isTrue);
      expect(s.contactCategoryReason, 'Offers packaging boxes');
      final copy = s.copyWith(unreadCount: 0, status: 'Answered');
      expect(copy.contactCategory, 'Supplier');
      expect(copy.contactCategorySource, 'AI');
      expect(copy.contactCategoryReason, 'Offers packaging boxes');
    });

    test('ConversationPage reads category_counts, tolerating strings and '
        'absence', () {
      expect(
        ChatConversationPage.fromJson({
          'conversations': <dynamic>[],
          'category_counts': {'Supplier': 3, 'Content Creator': '2'},
        }).categoryCounts,
        {'Supplier': 3, 'Content Creator': 2},
      );
      expect(ChatConversationPage.fromJson({}).categoryCounts, isEmpty);
      expect(
        ChatConversationPage.fromJson({'category_counts': 'x'}).categoryCounts,
        isEmpty,
      );
    });

    test('Thread customer_suggestion: parsed, null, or empty', () {
      final json = {
        'conversation': {'name': 'CHAT-1'},
        'messages': <dynamic>[],
        'customer_suggestion': {
          'name': 'CUST-1',
          'customer_name': 'Ahmed Ali',
          'mobile_no': '010',
          'total_orders': '4',
          'reasons': ['phone'],
          'score': 0.9,
        },
      };
      final thread = ChatThread.fromJson(json);
      expect(thread.customerSuggestion?.name, 'CUST-1');
      expect(thread.customerSuggestion?.totalOrders, 4);
      expect(thread.customerSuggestion?.reasons, ['phone']);
      expect(
        ChatThread.fromJson({
          ...json,
          'customer_suggestion': null,
        }).customerSuggestion,
        isNull,
      );
      expect(
        ChatThread.fromJson({
          'conversation': {'name': 'C'},
        }).customerSuggestion,
        isNull,
      );
      expect(
        ChatThread.fromJson({
          ...json,
          'customer_suggestion': <String, dynamic>{},
        }).customerSuggestion,
        isNull,
      );
    });

    test('suggest_customers: candidates and prefill with missing keys', () {
      final result = ChatSuggestCustomersResult.fromJson({
        'candidates': [
          {'name': 'CUST-1'},
          {'customer_name': 'no id'},
        ],
        'prefill': {
          'customer_name': 'Ahmed',
          'mobile_no': '010',
          'phones': ['011'],
        },
      });
      expect(result.candidates.map((c) => c.name), ['CUST-1']);
      expect(result.candidates.single.customerName, 'CUST-1');
      expect(result.candidates.single.reasons, isEmpty);
      expect(result.prefill.phones, ['010', '011']);
      expect(result.bestPhone, '010');
      expect(result.prefill.ai, isFalse);
      expect(result.prefill.territory, isNull);
      // Nothing at all.
      final empty = ChatSuggestCustomersResult.fromJson(null);
      expect(empty.candidates, isEmpty);
      expect(empty.bestPhone, isNull);
      expect(empty.prefill.customerName, '');
    });

    test('prefill location: coordinates or a link', () {
      expect(
        ChatNewCustomerPrefill.fromJson({'location': '30.1, 31.2'}).coordinates,
        (lat: 30.1, lng: 31.2),
      );
      final link = ChatNewCustomerPrefill.fromJson({
        'location': 'https://maps.app.goo.gl/x',
      });
      expect(link.coordinates, isNull);
      expect(link.locationLink, 'https://maps.app.goo.gl/x');
      expect(ChatNewCustomerPrefill.fromJson({}).locationLink, isNull);
    });

    test('create_customer_from_chat: created, and existing', () {
      final created = ChatCreateCustomerResult.fromJson({
        'conversation': {'name': 'CHAT-1', 'customer': 'CUST-9'},
        'customer': {'name': 'CUST-9', 'customer_name': 'New'},
        'created': true,
      });
      expect(created.created, isTrue);
      expect(created.existing, isNull);
      expect(created.customer?.customerName, 'New');
      final existing = ChatCreateCustomerResult.fromJson({
        'existing': {'name': 'CUST-1', 'customer_name': 'Ahmed'},
        'conversation': {'name': 'CHAT-1'},
      });
      expect(existing.existing?.name, 'CUST-1');
      expect(existing.created, isFalse);
      expect(ChatCreateCustomerResult.fromJson(null).existing, isNull);
    });

    test('fact override rows tolerate missing keys', () {
      final page = ChatFactOverridesPage.fromJson({
        'rows': [
          {'draft': 'D-1', 'conversation': 'CHAT-1', 'status': 'Sent Edited'},
          {'draft': ''},
        ],
      });
      expect(page.rows, hasLength(1));
      expect(page.total, 1);
      expect(page.hasMore, isFalse);
      final row = page.rows.single;
      expect(row.wasSent, isTrue);
      expect(row.conflicts, isEmpty);
      expect(row.moderatorHint, isNull);
      expect(row.requester, '');
      expect(ChatFactOverridesPage.fromJson(null).rows, isEmpty);
    });
  });

  group('inbox filter', () {
    ChatConversationSummary s(String name, String? category) =>
        ChatConversationSummary.fromJson(_summary(name, category: category));

    test('category copyWith / equality / clear', () {
      const f = ChatInboxFilter();
      expect(f.category, isNull);
      final supplier = f.copyWith(category: 'Supplier');
      expect(supplier.category, 'Supplier');
      expect(supplier == f, isFalse);
      expect(supplier.copyWith(clearCategory: true), f);
      // Other fields survive.
      expect(supplier.copyWith(channel: 'Instagram').category, 'Supplier');
    });

    test('chatSummaryMatchesFilter: Customer includes unclassified chats', () {
      const base = ChatInboxFilter();
      expect(chatSummaryMatchesFilter(s('A', null), base, null), isTrue);
      final customers = base.copyWith(category: 'Customer');
      expect(chatSummaryMatchesFilter(s('A', null), customers, null), isTrue);
      expect(
        chatSummaryMatchesFilter(s('A', 'Customer'), customers, null),
        isTrue,
      );
      expect(
        chatSummaryMatchesFilter(s('A', 'Supplier'), customers, null),
        isFalse,
      );
      final suppliers = base.copyWith(category: 'Supplier');
      expect(
        chatSummaryMatchesFilter(s('A', 'Supplier'), suppliers, null),
        isTrue,
      );
      expect(chatSummaryMatchesFilter(s('A', null), suppliers, null), isFalse);
      expect(
        chatSummaryMatchesFilter(s('A', 'Other'), suppliers, null),
        isFalse,
      );
    });
  });

  group('tile chip', () {
    Future<void> pumpTile(WidgetTester tester, String? category) {
      return tester.pumpWidget(
        _app(
          const [],
          Scaffold(
            body: ChatConversationTile(
              summary: ChatConversationSummary.fromJson(
                _summary('CHAT-1', category: category),
              ),
              now: _now,
              onTap: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('Supplier, Content Creator and Other get a chip', (
      tester,
    ) async {
      const chip = ValueKey('chat-category-chip-CHAT-1');
      await pumpTile(tester, 'Supplier');
      expect(find.byKey(chip), findsOneWidget);
      expect(find.text('Supplier'), findsOneWidget);

      await pumpTile(tester, 'Content Creator');
      expect(find.text('Content creator'), findsOneWidget);

      await pumpTile(tester, 'Other');
      expect(find.byKey(chip), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('Customer and unclassified show no chip', (tester) async {
      await pumpTile(tester, 'Customer');
      expect(
        find.byKey(const ValueKey('chat-category-chip-CHAT-1')),
        findsNothing,
      );
      await pumpTile(tester, null);
      expect(
        find.byKey(const ValueKey('chat-category-chip-CHAT-1')),
        findsNothing,
      );
    });

    testWidgets('the Arabic UI uses the Arabic labels', (tester) async {
      await tester.pumpWidget(
        _app(
          const [],
          Scaffold(
            body: ChatConversationTile(
              summary: ChatConversationSummary.fromJson(
                _summary('CHAT-1', category: 'Supplier'),
              ),
              now: _now,
              onTap: () {},
            ),
          ),
          locale: 'ar',
        ),
      );
      expect(find.text('مورّد'), findsOneWidget);
    });

    testWidgets('the preview follows its own direction', (tester) async {
      await tester.pumpWidget(
        _app(
          const [],
          Scaffold(
            body: ChatConversationTile(
              summary: ChatConversationSummary.fromJson({
                ..._summary('CHAT-1'),
                'last_message_preview': 'تمام الطلب Mango Trio',
              }),
              now: _now,
              onTap: () {},
            ),
          ),
        ),
      );
      final preview = tester.widget<Text>(
        find.byKey(const ValueKey('chat-preview-CHAT-1')),
      );
      expect(preview.textDirection, TextDirection.rtl);
    });
  });

  group('inbox screen', () {
    MockDio inboxDio() => MockDio()
      ..setResponse(ApiEndpoints.chatGetConversations, {
        'message': {
          'conversations': [
            _summary('CHAT-1', category: 'Supplier', contact: 'Box Co'),
            _summary('CHAT-2', contact: 'Mona', lastAt: '2026-10-16 09:00:00'),
          ],
          'has_more': 0,
          'open_count': 2,
          'category_counts': {'Supplier': 3, 'Content Creator': 1},
        },
      });

    testWidgets('filter chips show counts and drive the category param', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dio = inboxDio();
      await tester.pumpWidget(
        _app(_overrides(dio, MockWebSocketService()), const ChatInboxScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('All'), findsWidgets);
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Suppliers (3)'), findsOneWidget);
      expect(find.text('Content creators (1)'), findsOneWidget);
      // The first load has no category.
      expect(
        dio.requestLog.first['queryParameters'],
        isNot(contains('category')),
      );

      dio.clearLog();
      await tester.tap(
        find.byKey(const ValueKey('chat-filter-category-Supplier')),
      );
      await tester.pumpAndSettle();
      expect(
        dio.requestLog.first['queryParameters'],
        containsPair('category', 'Supplier'),
      );

      dio.clearLog();
      await tester.tap(find.byKey(const ValueKey('chat-filter-category-all')));
      await tester.pumpAndSettle();
      expect(
        dio.requestLog.first['queryParameters'],
        isNot(contains('category')),
      );
    });

    testWidgets('the app bar opens the moderator-overrides list', (
      tester,
    ) async {
      final dio = inboxDio();
      await tester.pumpWidget(
        _app(_overrides(dio, MockWebSocketService()), const ChatInboxScreen()),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chat-fact-overrides-action')),
        findsOneWidget,
      );
    });

    testWidgets('a realtime summary brings the category to the row', (
      tester,
    ) async {
      final dio = inboxDio();
      final ws = MockWebSocketService();
      await tester.pumpWidget(
        _app(_overrides(dio, ws), const ChatInboxScreen()),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chat-category-chip-CHAT-2')),
        findsNothing,
      );

      ws.debugHandleMessage({
        'event': WsEvents.chatUpdate,
        'data': <String, dynamic>{
          'conversation': 'CHAT-2',
          'kind': 'status',
          'summary': _summary(
            'CHAT-2',
            category: 'Content Creator',
            source: 'AI',
            contact: 'Mona',
            lastAt: '2026-10-16 09:00:00',
          ),
        },
      });
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chat-category-chip-CHAT-2')),
        findsOneWidget,
      );
      expect(find.text('Content creator'), findsOneWidget);
    });
  });

  group('thread: Contact type', () {
    Map<String, dynamic> thread({
      String? category,
      String? source,
      String? reason,
    }) => {
      'message': {
        'conversation': _summary(
          'CHAT-1',
          category: category,
          source: source,
          reason: reason,
          contact: 'Box Co',
        ),
        'messages': [
          {
            'name': 'M-1',
            'direction': 'Inbound',
            'message_type': 'text',
            'body': 'We sell boxes',
            'timestamp': '2026-10-16 10:00:00',
          },
        ],
        'draft': null,
        'customer': null,
      },
    };

    testWidgets('the subtitle shows the category with an AI marker', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dio = MockDio()
        ..setResponse(
          ApiEndpoints.chatGetConversation,
          thread(
            category: 'Supplier',
            source: 'AI',
            reason: 'Offers packaging boxes',
          ),
        );
      await tester.pumpWidget(
        _app(
          _overrides(dio, MockWebSocketService()),
          const ChatThreadScreen(conversation: 'CHAT-1'),
        ),
      );
      await tester.pumpAndSettle();
      final subtitle = tester.widget<Text>(
        find.byKey(const ValueKey('chat-thread-subtitle')),
      );
      expect(subtitle.data, contains('Supplier (AI)'));
      // The AI's reason rides on a tooltip.
      expect(find.byTooltip('Offers packaging boxes'), findsOneWidget);
    });

    testWidgets('picking a type posts set_contact_category; Let AI decide '
        'sends an empty category', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dio = MockDio()
        ..setResponse(ApiEndpoints.chatGetConversation, thread())
        ..setResponse(ApiEndpoints.chatSetContactCategory, {
          'message': {
            'conversation': _summary(
              'CHAT-1',
              category: 'Content Creator',
              source: 'Manual',
              contact: 'Box Co',
            ),
          },
        });
      await tester.pumpWidget(
        _app(
          _overrides(dio, MockWebSocketService()),
          const ChatThreadScreen(conversation: 'CHAT-1'),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> openPicker() async {
        await tester.tap(find.byKey(const ValueKey('chat-thread-menu')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('chat-menu-contact-type')));
        await tester.pumpAndSettle();
      }

      await openPicker();
      for (final label in [
        'Customer',
        'Supplier',
        'Content creator',
        'Other',
        'Let AI decide',
      ]) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      await tester.tap(
        find.byKey(const ValueKey('chat-category-option-Content Creator')),
      );
      await tester.pumpAndSettle();

      var call = dio.requestLog.firstWhere(
        (r) => r['path'] == ApiEndpoints.chatSetContactCategory,
      );
      expect(call['data'], {
        'conversation': 'CHAT-1',
        'category': 'Content Creator',
      });
      // Manual: no AI marker in the subtitle.
      final subtitle = tester.widget<Text>(
        find.byKey(const ValueKey('chat-thread-subtitle')),
      );
      expect(subtitle.data, contains('Content creator'));
      expect(subtitle.data, isNot(contains('(AI)')));

      dio.clearLog();
      await openPicker();
      await tester.tap(
        find.byKey(const ValueKey('chat-category-option-__ai__')),
      );
      await tester.pumpAndSettle();
      call = dio.requestLog.firstWhere(
        (r) => r['path'] == ApiEndpoints.chatSetContactCategory,
      );
      expect(call['data'], {'conversation': 'CHAT-1', 'category': ''});
    });
  });
}
