// Chat media send + reactions (contract chat-media-send): model parsing and
// defaults, the size pre-check, the send_media FormData / react_to_message
// wire shapes, the reaction row of the long-press sheet and the composer's
// attach button.
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/core/constants/api_endpoints.dart';
import 'package:jarz_pos/src/core/network/user_service.dart';
import 'package:jarz_pos/src/core/websocket/websocket_service.dart';
import 'package:jarz_pos/src/features/chat_inbox/data/chat_media_limits.dart';
import 'package:jarz_pos/src/features/chat_inbox/data/chat_repository.dart';
import 'package:jarz_pos/src/features/chat_inbox/data/models/chat_models.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/screens/chat_thread_screen.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/widgets/chat_message_bubble.dart';
import 'package:jarz_pos/src/features/chat_inbox/state/chat_providers.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

const _heart = '❤️';
const _thumbs = '\u{1F44D}';
const _love = '\u{1F60D}';

Widget _app(Widget home, {List<Override> overrides = const []}) =>
    ProviderScope(
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

ChatMessage _msg({String direction = 'Inbound', String name = 'M-1'}) =>
    ChatMessage.fromJson({
      'name': name,
      'direction': direction,
      'message_type': 'text',
      'body': 'hello',
      'timestamp': '2026-10-16 10:00:00',
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPlatformChannels();

  group('models', () {
    test('message reactions parse, are tolerant and default to null', () {
      final m = ChatMessage.fromJson({
        'name': 'M-1',
        'staff_reaction': _thumbs,
        'customer_reaction': '',
      });
      expect(m.staffReaction, _thumbs);
      expect(m.customerReaction, isNull);
      expect(ChatMessage.fromJson({'name': 'M-2'}).staffReaction, isNull);
      expect(m.withStaffReaction('').staffReaction, isNull);
      expect(m.withStaffReaction(_heart).staffReaction, _heart);
      expect(m.withStaffReaction(_heart).name, 'M-1');
    });

    test('canSendMedia / reactionChoices: server values win', () {
      final c = ChatConversationSummary.fromJson({
        'name': 'C-1',
        'channel': 'Instagram',
        'can_send_media': 0,
        'reaction_choices': [_heart],
      });
      expect(c.canSendMedia, isFalse);
      expect(c.reactionChoices, [_heart]);
      expect(c.mediaInfoKnown, isTrue);
    });

    test('missing keys: direct channels can send media, comments cannot', () {
      for (final channel in ['WhatsApp', 'Messenger', 'Instagram']) {
        final c = ChatConversationSummary.fromJson(
          {'name': 'C', 'channel': channel},
        );
        expect(c.canSendMedia, isTrue, reason: channel);
        expect(c.reactionChoices, isEmpty);
        expect(c.mediaInfoKnown, isFalse);
      }
      for (final channel in ['Instagram Comment', 'Facebook Comment', '']) {
        expect(
          ChatConversationSummary.fromJson(
            {'name': 'C', 'channel': channel},
          ).canSendMedia,
          isFalse,
          reason: channel,
        );
      }
    });

    test('a thread summary without the keys keeps what it knew', () {
      final known = ChatConversationSummary.fromJson({
        'name': 'C-1',
        'channel': 'WhatsApp',
        'can_send_media': 1,
        'reaction_choices': [_thumbs, _heart],
      });
      final socket = ChatConversationSummary.fromJson(
        {'name': 'C-1', 'channel': 'WhatsApp', 'status': 'Closed'},
      );
      final merged = ChatThreadState(conversation: known)
          .copyWith(conversation: socket)
          .conversation;
      expect(merged.status, 'Closed');
      expect(merged.reactionChoices, [_thumbs, _heart]);
    });
  });

  group('size pre-check', () {
    test('caps per kind', () {
      expect(chatMediaMaxBytes(ChatMediaKind.image), 5 * 1024 * 1024);
      expect(chatMediaMaxBytes(ChatMediaKind.video), 16 * 1024 * 1024);
      expect(chatMediaMaxBytes(ChatMediaKind.audio), 16 * 1024 * 1024);
      expect(chatMediaMaxBytes(ChatMediaKind.document), 25 * 1024 * 1024);
    });

    test('kind comes from mime, then extension', () {
      expect(chatMediaKindOf('image/png', 'a.bin'), ChatMediaKind.image);
      expect(chatMediaKindOf('video/mp4', null), ChatMediaKind.video);
      expect(
        chatMediaKindOf('audio/ogg; codecs=opus', null),
        ChatMediaKind.audio,
      );
      expect(chatMediaKindOf(null, 'clip.MOV'), ChatMediaKind.video);
      expect(
        chatMediaKindOf('application/pdf', 'a.pdf'),
        ChatMediaKind.document,
      );
    });

    test('over the cap gives a bilingual error, within it gives null', () {
      const mb = 1024 * 1024;
      expect(
        chatMediaSizeError(
          kind: ChatMediaKind.image,
          bytes: 5 * mb,
          arabic: false,
        ),
        isNull,
      );
      final en = chatMediaSizeError(
        kind: ChatMediaKind.image,
        bytes: 6 * mb,
        arabic: false,
      );
      expect(en, contains('5 MB'));
      expect(en, contains('photo'));
      final ar = chatMediaSizeError(
        kind: ChatMediaKind.video,
        bytes: 20 * mb,
        arabic: true,
      );
      expect(ar, contains('16 MB'));
      expect(ar, contains('الفيديو'));
    });
  });

  group('repository', () {
    late MockDio dio;
    late ChatRepository repo;
    setUp(() {
      dio = MockDio();
      repo = ChatRepository(dio);
    });

    test('send_media posts multipart conversation / caption / file', () async {
      dio.setResponse(ApiEndpoints.chatSendMedia, {
        'message': {
          'message': {
            'name': 'M-9',
            'direction': 'Outbound',
            'message_type': 'image',
            'media_url': '/private/files/a.jpg',
          },
        },
      });
      final sent = await repo.sendMedia(
        conversation: 'CHAT-1',
        filename: 'a.jpg',
        mime: 'image/jpeg',
        bytes: Uint8List.fromList([1, 2, 3]),
        caption: '  nice  ',
      );
      expect(sent.name, 'M-9');
      expect(sent.messageType, 'image');
      final call = dio.requestLog.last;
      expect(call['method'], 'POST');
      expect(call['path'], ApiEndpoints.chatSendMedia);
      final form = call['data'] as FormData;
      expect(
        {for (final f in form.fields) f.key: f.value},
        {'conversation': 'CHAT-1', 'caption': 'nice'},
      );
      expect(form.files.single.key, 'file');
      expect(form.files.single.value.filename, 'a.jpg');
      expect(form.files.single.value.contentType?.mimeType, 'image/jpeg');
      expect(form.files.single.value.length, 3);
    });

    test('send_media omits an empty caption and needs bytes or a path',
        () async {
      dio.setResponse(ApiEndpoints.chatSendMedia, {
        'message': {'name': 'M-1', 'direction': 'Outbound'},
      });
      await repo.sendMedia(
        conversation: 'C',
        filename: 'x.pdf',
        mime: 'application/pdf',
        bytes: Uint8List(2),
      );
      final form = dio.requestLog.last['data'] as FormData;
      expect(form.fields.map((f) => f.key), ['conversation']);
      expect(
        () => repo.sendMedia(conversation: 'C', filename: 'x', mime: ''),
        throwsArgumentError,
      );
    });

    test('react_to_message posts message + emoji, empty removes', () async {
      dio.setResponse(ApiEndpoints.chatReactToMessage, {
        'message': {
          'message': {'name': 'M-1', 'staff_reaction': _thumbs},
        },
      });
      final updated = await repo.reactToMessage(message: 'M-1', emoji: _thumbs);
      expect(updated?.staffReaction, _thumbs);
      expect(dio.requestLog.last['method'], 'POST');
      expect(dio.requestLog.last['data'], {'message': 'M-1', 'emoji': _thumbs});
      await repo.reactToMessage(message: 'M-1', emoji: '');
      expect(dio.requestLog.last['data'], {'message': 'M-1', 'emoji': ''});
    });
  });

  group('actions sheet', () {
    Future<void> open(
      WidgetTester tester, {
      required ChatMessage message,
      required List<String> choices,
      List<String>? reacted,
    }) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: ChatMessageBubble(
              message: message,
              reactionChoices: choices,
              onReact: (e) => reacted?.add(e),
            ),
          ),
        ),
      );
      await tester.longPress(find.text('hello'));
      await tester.pumpAndSettle();
    }

    testWidgets('inbound + choices: emoji row, tap reports the emoji',
        (tester) async {
      final reacted = <String>[];
      await open(
        tester,
        message: _msg(),
        choices: [_thumbs, _heart],
        reacted: reacted,
      );
      expect(find.byKey(const ValueKey('chat-reaction-row')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('chat-reaction-$_thumbs')));
      await tester.pumpAndSettle();
      expect(reacted, [_thumbs]);
    });

    testWidgets('tapping the current reaction removes it', (tester) async {
      final reacted = <String>[];
      final m = _msg().withStaffReaction(_thumbs);
      await open(tester, message: m, choices: [_thumbs, _heart], reacted: reacted);
      await tester.tap(find.byKey(const ValueKey('chat-reaction-$_thumbs')));
      await tester.pumpAndSettle();
      expect(reacted, ['']);
    });

    testWidgets('outbound message: no emoji row', (tester) async {
      await open(
        tester,
        message: _msg(direction: 'Outbound'),
        choices: [_thumbs],
      );
      expect(
        find.byKey(const ValueKey('chat-message-actions')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('chat-reaction-row')), findsNothing);
    });

    testWidgets('empty choices: no emoji row', (tester) async {
      await open(tester, message: _msg(), choices: const []);
      expect(
        find.byKey(const ValueKey('chat-message-actions')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('chat-reaction-row')), findsNothing);
    });

    testWidgets('bubble shows the right reaction badge', (tester) async {
      Future<void> pump(ChatMessage m) => tester.pumpWidget(
            _app(Scaffold(body: ChatMessageBubble(message: m))),
          );
      await pump(_msg().withStaffReaction(_thumbs));
      expect(find.byKey(const ValueKey('chat-reaction-badge')), findsOneWidget);
      // A customer reaction on an inbound bubble is not shown.
      await pump(ChatMessage.fromJson({
        'name': 'M-3',
        'direction': 'Inbound',
        'body': 'hello',
        'customer_reaction': _love,
      }));
      expect(find.byKey(const ValueKey('chat-reaction-badge')), findsNothing);
      await pump(ChatMessage.fromJson({
        'name': 'M-4',
        'direction': 'Outbound',
        'body': 'hello',
        'customer_reaction': _love,
      }));
      expect(find.text(_love), findsOneWidget);
    });
  });

  group('composer attach button', () {
    Future<void> openThread(
      WidgetTester tester,
      Map<String, dynamic> conv,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dio = MockDio()
        ..setResponse(ApiEndpoints.chatGetConversation, {
          'message': {
            'conversation': conv,
            'messages': [_msgJson()],
            'draft': null,
            'customer': null,
          },
        });
      await tester.pumpWidget(
        _app(
          const ChatThreadScreen(conversation: 'CHAT-1'),
          overrides: [
            chatRepositoryProvider.overrideWithValue(ChatRepository(dio)),
            userRolesFutureProvider.overrideWith(
              (ref) async => UserRoles(
                user: 'mod@jarz.test',
                fullName: 'Mod',
                roles: const ['Moderator', 'POS User', 'Sales User'],
                requirePosShift: true,
                canAccessB2b: false,
                isB2bSalesRep: false,
              ),
            ),
            webSocketServiceProvider.overrideWithValue(MockWebSocketService()),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shown when can_send_media is true', (tester) async {
      await openThread(tester, {
        'name': 'CHAT-1',
        'channel': 'WhatsApp',
        'can_send_media': true,
      });
      expect(
        find.byKey(const ValueKey('chat-composer-attach')),
        findsOneWidget,
      );
    });

    testWidgets('hidden when can_send_media is false', (tester) async {
      await openThread(tester, {
        'name': 'CHAT-1',
        'channel': 'Instagram Comment',
        'can_send_media': false,
      });
      expect(find.byKey(const ValueKey('chat-composer')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-composer-attach')), findsNothing);
    });
  });
}

Map<String, dynamic> _msgJson() => {
      'name': 'M-1',
      'direction': 'Inbound',
      'message_type': 'text',
      'body': 'hello there',
      'timestamp': '2026-10-16 10:00:00',
    };
