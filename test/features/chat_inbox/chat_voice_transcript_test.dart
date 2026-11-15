// Voice-note transcripts: the optional `transcript` on a chat message (absent
// on older servers, null until the server fills it), the socket update that
// adds it to a message already in the thread, a stale page read that must
// not wipe it, and the bubble that shows it only under an audio player.
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

const _conv = 'CHAT-1';
const _voice = 'Hi, I want two jars of tiramisu delivered tomorrow.';

Map<String, dynamic> _audioJson({
  String name = 'M1',
  Object? transcript,
  bool includeTranscript = true,
  String type = 'audio',
}) =>
    {
      'name': name,
      'direction': 'Inbound',
      'message_type': type,
      'body': '',
      'media_url': '/private/files/voice-$name.ogg',
      'media_mime': 'audio/ogg',
      'timestamp': '2026-10-29 10:00:00',
      if (includeTranscript) 'transcript': transcript,
    };

Widget _bubbleApp(ChatMessage message, {String locale = 'en'}) =>
    ProviderScope(
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        // A scrolling host, like the thread's message list.
        home: Scaffold(
          body: ListView(children: [ChatMessageBubble(message: message)]),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPlatformChannels();

  group('ChatMessage.transcript parsing', () {
    test('present: read and trimmed', () {
      final m = ChatMessage.fromJson(_audioJson(transcript: '  $_voice \n'));
      expect(m.transcript, _voice);
    });

    test('absent (older server): null', () {
      final m = ChatMessage.fromJson(_audioJson(includeTranscript: false));
      expect(m.transcript, isNull);
      expect(m.messageType, 'audio');
    });

    test('null or blank: null', () {
      expect(ChatMessage.fromJson(_audioJson(transcript: null)).transcript,
          isNull);
      expect(ChatMessage.fromJson(_audioJson(transcript: '   ')).transcript,
          isNull);
    });

    test('carried by a socket update payload', () {
      final event = ChatUpdateEvent.fromJson({
        'conversation': _conv,
        'kind': 'message',
        'message': _audioJson(transcript: _voice),
      });
      expect(event.message?.transcript, _voice);
    });
  });

  group('mergeChatMessages and transcripts', () {
    test('an update with the transcript replaces the same-name message', () {
      final merged = mergeChatMessages(
        [ChatMessage.fromJson(_audioJson())],
        [ChatMessage.fromJson(_audioJson(transcript: _voice))],
      );
      expect(merged, hasLength(1));
      expect(merged.single.transcript, _voice);
    });

    test('a stale copy without a transcript does not wipe one already held',
        () {
      final merged = mergeChatMessages(
        [ChatMessage.fromJson(_audioJson(transcript: _voice))],
        [ChatMessage.fromJson(_audioJson(includeTranscript: false))],
      );
      expect(merged.single.transcript, _voice);
      expect(merged.single.mediaUrl, '/private/files/voice-M1.ogg');
    });
  });

  test('a socket message update adds the transcript to the open thread',
      () async {
    final dio = MockDio()
      ..setResponse(ApiEndpoints.chatGetConversation, {
        'message': {
          'conversation': {
            'name': _conv,
            'channel': 'WhatsApp',
            'status': 'Open',
            'last_message_at': '2026-10-29 10:00:00',
            'last_direction': 'Inbound',
          },
          'messages': [_audioJson(transcript: null)],
          'draft': null,
          'customer': null,
        },
      });
    final ws = MockWebSocketService();
    final container = ProviderContainer(
      overrides: [
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
        chatUnreadTotalProvider
            .overrideWith((ref) async => ChatUnreadTotal.zero),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(chatThreadProvider(_conv), (_, _) {});
    addTearDown(sub.close);
    await container.read(chatThreadProvider(_conv).future);
    expect(
      container.read(chatThreadProvider(_conv)).requireValue.messages.single
          .transcript,
      isNull,
    );

    ws.debugHandleMessage({
      'event': WsEvents.chatUpdate,
      'data': <String, dynamic>{
        'conversation': _conv,
        'kind': 'message',
        'message': _audioJson(transcript: _voice),
      },
    });
    await Future<void>.delayed(Duration.zero);

    final messages =
        container.read(chatThreadProvider(_conv)).requireValue.messages;
    expect(messages, hasLength(1));
    expect(messages.single.transcript, _voice);
  });

  group('bubble', () {
    testWidgets('audio with a transcript shows the label and the text',
        (tester) async {
      await tester.pumpWidget(
        _bubbleApp(ChatMessage.fromJson(_audioJson(transcript: _voice))),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('chat-voice-transcript')),
          findsOneWidget);
      expect(find.text('Transcript'), findsOneWidget);
      expect(find.text(_voice), findsOneWidget);
      // Short: no expand toggle.
      expect(find.byKey(const ValueKey('chat-voice-transcript-toggle')),
          findsNothing);
    });

    testWidgets('Arabic UI uses the Arabic label', (tester) async {
      await tester.pumpWidget(
        _bubbleApp(
          ChatMessage.fromJson(_audioJson(transcript: 'عايزة برطمانين')),
          locale: 'ar',
        ),
      );
      await tester.pump();
      expect(find.text('نص الرسالة الصوتية'), findsOneWidget);
      final text = tester.widget<Text>(find.text('عايزة برطمانين'));
      expect(text.textDirection, TextDirection.rtl);
    });

    testWidgets('audio without a transcript shows nothing extra',
        (tester) async {
      await tester.pumpWidget(
        _bubbleApp(ChatMessage.fromJson(_audioJson(transcript: null))),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('chat-voice-transcript')),
          findsNothing);
      expect(find.text('Transcript'), findsNothing);
    });

    testWidgets('non-audio messages never show a transcript', (tester) async {
      for (final type in ['text', 'document', 'video']) {
        await tester.pumpWidget(
          _bubbleApp(
            ChatMessage.fromJson(
              _audioJson(name: 'M-$type', type: type, transcript: _voice),
            ),
          ),
        );
        await tester.pump();
        expect(find.byKey(const ValueKey('chat-voice-transcript')),
            findsNothing,
            reason: type);
      }
    });

    testWidgets('a long transcript is capped and expands on tap',
        (tester) async {
      final long = List.filled(40, _voice).join(' ');
      await tester.pumpWidget(
        _bubbleApp(ChatMessage.fromJson(_audioJson(transcript: long))),
      );
      await tester.pump();
      Text text() => tester.widget<Text>(find.text(long));
      expect(text().maxLines, 6);
      expect(find.text('Show more'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('chat-voice-transcript-toggle')),
      );
      await tester.pump();
      expect(text().maxLines, isNull);
      expect(find.text('Show less'), findsOneWidget);
    });
  });

  test('chatTextDirectionOf reads the first strong character', () {
    expect(chatTextDirectionOf('مرحبا hello'), TextDirection.rtl);
    expect(chatTextDirectionOf('123 hello مرحبا'), TextDirection.ltr);
    expect(chatTextDirectionOf('123 !'), isNull);
  });
}
