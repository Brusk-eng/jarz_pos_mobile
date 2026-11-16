// Delivery ticks on outbound chat bubbles, and a realtime status update
// replacing the held message in place.
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
import 'package:jarz_pos/src/features/chat_inbox/presentation/widgets/chat_message_bubble.dart';
import 'package:jarz_pos/src/features/chat_inbox/state/chat_providers.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

Widget _app(Widget home) => ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: home),
      ),
    );

ChatMessage _m(String direction, String? status, {String name = 'M-1'}) =>
    ChatMessage.fromJson({
      'name': name,
      'direction': direction,
      'body': 'hello',
      'status': status,
      'timestamp': '2026-10-16 10:00:00',
    });

Finder _tick(String status) => find.byKey(ValueKey('chat-receipt-$status'));

Finder _anyTick() => find.byWidgetPredicate(
      (w) => w.key.toString().contains('chat-receipt-'),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPlatformChannels();

  group('delivery ticks', () {
    const cases = {
      'queued': (Icons.schedule, 'Sending'),
      'sent': (Icons.done, 'Sent'),
      'delivered': (Icons.done_all, 'Delivered'),
      'read': (Icons.done_all, 'Read'),
    };
    for (final e in cases.entries) {
      testWidgets('${e.key}: icon and label', (tester) async {
        await tester.pumpWidget(
          _app(ChatMessageBubble(message: _m('Outbound', e.key))),
        );
        final icon = tester.widget<Icon>(_tick(e.key));
        expect(icon.icon, e.value.$1);
        expect(find.byTooltip(e.value.$2), findsOneWidget);
      });
    }

    testWidgets('read is blue, delivered is not', (tester) async {
      await tester.pumpWidget(
        _app(ChatMessageBubble(message: _m('Outbound', 'read'))),
      );
      final read = tester.widget<Icon>(_tick('read')).color;
      await tester.pumpWidget(
        _app(ChatMessageBubble(message: _m('Outbound', 'delivered'))),
      );
      final delivered = tester.widget<Icon>(_tick('delivered')).color;
      expect(read, isNot(delivered));
    });

    testWidgets('failed, unknown and empty show no tick', (tester) async {
      for (final s in ['failed', 'weird', null, '']) {
        await tester.pumpWidget(
          _app(ChatMessageBubble(message: _m('Outbound', s))),
        );
        expect(_anyTick(), findsNothing, reason: 'status $s');
      }
    });

    testWidgets('inbound shows none', (tester) async {
      for (final s in ['received', 'read']) {
        await tester.pumpWidget(
          _app(ChatMessageBubble(message: _m('Inbound', s))),
        );
        expect(_anyTick(), findsNothing, reason: 'status $s');
      }
    });

    testWidgets('comment channels (showReceipts off) show none',
        (tester) async {
      await tester.pumpWidget(
        _app(ChatMessageBubble(
          message: _m('Outbound', 'delivered'),
          showReceipts: false,
        )),
      );
      expect(_anyTick(), findsNothing);
    });
  });

  test('a realtime update of a held message replaces it, no duplicate, '
      'unread unchanged', () async {
    final dio = MockDio()
      ..setResponse(ApiEndpoints.chatGetConversation, {
        'message': {
          'conversation': {
            'name': 'CHAT-1',
            'channel': 'WhatsApp',
            'status': 'Open',
            'unread_count': 2,
            'last_message_at': '2026-10-16 10:00:00',
          },
          'messages': [
            {
              'name': 'M-1',
              'body': 'hello',
              'direction': 'Outbound',
              'status': 'sent',
              'timestamp': '2026-10-16 10:00:00',
            },
          ],
        },
      });
    final ws = MockWebSocketService();
    final container = ProviderContainer(overrides: [
      chatRepositoryProvider.overrideWithValue(ChatRepository(dio)),
      userRolesFutureProvider.overrideWith(
        (ref) async => UserRoles(
          user: 'mod@jarz.test',
          fullName: 'Mod',
          roles: const ['Moderator'],
          requirePosShift: false,
          canAccessB2b: false,
          isB2bSalesRep: false,
        ),
      ),
      webSocketServiceProvider.overrideWithValue(ws),
      chatUnreadTotalProvider.overrideWith((ref) async => ChatUnreadTotal.zero),
    ]);
    addTearDown(container.dispose);
    final sub = container.listen(chatThreadProvider('CHAT-1'), (_, _) {});
    addTearDown(sub.close);
    await container.read(chatThreadProvider('CHAT-1').future);

    ws.debugHandleMessage({
      'event': WsEvents.chatUpdate,
      'data': <String, dynamic>{
        'conversation': 'CHAT-1',
        'kind': 'message',
        'message': {
          'name': 'M-1',
          'body': 'hello',
          'direction': 'Outbound',
          'status': 'read',
          'timestamp': '2026-10-16 10:00:00',
        },
      },
    });
    await Future<void>.delayed(Duration.zero);

    final state = container.read(chatThreadProvider('CHAT-1')).requireValue;
    expect(state.messages.length, 1);
    expect(state.messages.single.status, 'read');
    expect(state.conversation.unreadCount, 2);
  });
}
