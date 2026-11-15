// Copy / select / edit: the draft panel is editable in place with a Copy
// button, a long press on a bubble opens Copy / Select text / Use in reply,
// and "Use in reply" lands in the thread's composer.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:jarz_pos/src/features/chat_inbox/presentation/widgets/chat_draft_panel.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/widgets/chat_message_bubble.dart';
import 'package:jarz_pos/src/features/chat_inbox/state/chat_providers.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

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

/// Records `Clipboard.setData` calls.
List<String> _mockClipboard(WidgetTester tester) {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return copied;
}

ChatDraft _draft(String text, {String name = 'D-1', bool complaint = false}) =>
    ChatDraft.fromJson({
      'name': name,
      'status': 'Pending',
      'draft_text': text,
      'is_complaint': complaint ? 1 : 0,
      'fact_conflicts': ['تسليم ساعة → we say 2-3 hours'],
    });

ChatMessage _message(
  String body, {
  String name = 'M-1',
  String type = 'text',
}) => ChatMessage.fromJson({
  'name': name,
  'direction': 'Inbound',
  'message_type': type,
  'body': body,
  'timestamp': '2026-10-16 10:00:00',
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPlatformChannels();

  group('draft panel', () {
    Future<void> pumpPanel(
      WidgetTester tester,
      ChatDraft draft, {
      ValueChanged<String>? onSend,
    }) {
      return tester.pumpWidget(
        _app(
          const [],
          Scaffold(
            body: SingleChildScrollView(
              child: ChatDraftPanel(
                draft: draft,
                busy: false,
                onSend: onSend ?? (_) {},
                onReject: () {},
                onRegenerate: () {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('is editable in place: one field, no Edit / Done toggle', (
      tester,
    ) async {
      String? sent;
      await pumpPanel(
        tester,
        _draft('The jar is 150 EGP.'),
        onSend: (t) => sent = t,
      );

      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('chat-draft-field')),
      );
      expect(field.controller!.text, 'The jar is 150 EGP.');
      expect(field.minLines, 3);
      expect(field.maxLines, 10);
      expect(find.byKey(const ValueKey('chat-draft-edit')), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      // The Edited label shows once the text differs.
      expect(find.text('Edited'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('chat-draft-field')),
        'The jar is 160 EGP.',
      );
      await tester.pump();
      expect(find.text('Edited'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('chat-draft-send')));
      expect(sent, 'The jar is 160 EGP.');
    });

    testWidgets('keeps Reject, Regenerate and the fact-conflict box', (
      tester,
    ) async {
      await pumpPanel(tester, _draft('Delivered in one hour.'));
      expect(find.byKey(const ValueKey('chat-draft-reject')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('chat-draft-regenerate')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('chat-draft-fact-conflicts')),
        findsOneWidget,
      );
      // The conflict line is Arabic-first, so it is laid out right-to-left
      // rather than forced LTR.
      final line = tester.widget<Text>(
        find.text('تسليم ساعة → we say 2-3 hours'),
      );
      expect(line.textDirection, TextDirection.rtl);
    });

    testWidgets('the field follows the direction of what is typed', (
      tester,
    ) async {
      await pumpPanel(tester, _draft('Hello'));
      TextDirection? direction() => tester
          .widget<TextField>(find.byKey(const ValueKey('chat-draft-field')))
          .textDirection;
      expect(direction(), TextDirection.ltr);
      await tester.enterText(
        find.byKey(const ValueKey('chat-draft-field')),
        'تمام الطلب Mango Trio',
      );
      await tester.pump();
      expect(direction(), TextDirection.rtl);
    });

    testWidgets('Copy puts the current text on the clipboard', (tester) async {
      final copied = _mockClipboard(tester);
      await pumpPanel(tester, _draft('The jar is 150 EGP.'));

      await tester.enterText(
        find.byKey(const ValueKey('chat-draft-field')),
        '  Edited draft text ',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('chat-draft-copy')));
      await tester.pump();

      expect(copied, ['Edited draft text']);
      expect(find.text('Copied'), findsOneWidget);
    });

    testWidgets('a complaint draft stays locked until the text changes', (
      tester,
    ) async {
      await pumpPanel(tester, _draft('Sorry.', complaint: true));
      FilledButton send() => tester.widget<FilledButton>(
        find.byKey(const ValueKey('chat-draft-send')),
      );
      expect(send().onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('chat-draft-field')),
        'Sorry, a new jar is on its way.',
      );
      await tester.pump();
      expect(send().onPressed, isNotNull);
    });
  });

  group('bubble long press', () {
    Future<void> pumpBubble(
      WidgetTester tester,
      ChatMessage message, {
      ValueChanged<String>? onUseInReply,
    }) {
      return tester.pumpWidget(
        _app(
          const [],
          Scaffold(
            body: ChatMessageBubble(
              message: message,
              onUseInReply: onUseInReply,
            ),
          ),
        ),
      );
    }

    testWidgets('the bubble text is plain, not selectable', (tester) async {
      await pumpBubble(tester, _message('Mango Trio please'));
      expect(find.byType(SelectableText), findsNothing);
      expect(find.text('Mango Trio please'), findsOneWidget);
    });

    testWidgets('opens the sheet with Copy, Select text and Use in reply', (
      tester,
    ) async {
      await pumpBubble(
        tester,
        _message('Mango Trio please'),
        onUseInReply: (_) {},
      );
      await tester.longPress(find.byKey(const ValueKey('chat-message-M-1')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('chat-message-actions')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('chat-action-copy')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-action-select')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-action-reply')), findsOneWidget);
    });

    testWidgets('Copy copies the message and says Copied', (tester) async {
      final copied = _mockClipboard(tester);
      await pumpBubble(tester, _message('تمام الطلب Mango Trio'));
      await tester.longPress(find.byKey(const ValueKey('chat-message-M-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('chat-action-copy')));
      await tester.pumpAndSettle();

      expect(copied, ['تمام الطلب Mango Trio']);
      expect(find.text('Copied'), findsOneWidget);
      // No reply hook: that action is left out.
      expect(find.byKey(const ValueKey('chat-action-reply')), findsNothing);
    });

    testWidgets('Select text opens a large sheet with the whole message', (
      tester,
    ) async {
      await pumpBubble(tester, _message('line one\nسطر تاني'));
      await tester.longPress(find.byKey(const ValueKey('chat-message-M-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chat-action-select')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('chat-select-text')), findsOneWidget);
      expect(find.byType(SelectionArea), findsOneWidget);
      Finder inSheet(String text) => find.descendant(
        of: find.byKey(const ValueKey('chat-select-text')),
        matching: find.text(text),
      );
      expect(inSheet('line one'), findsOneWidget);
      final arabic = tester.widget<Text>(inSheet('سطر تاني'));
      expect(arabic.textDirection, TextDirection.rtl);
    });

    testWidgets('Use in reply hands the text to the composer hook', (
      tester,
    ) async {
      String? used;
      await pumpBubble(
        tester,
        _message('Please call me'),
        onUseInReply: (t) => used = t,
      );
      await tester.longPress(find.byKey(const ValueKey('chat-message-M-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chat-action-reply')));
      await tester.pumpAndSettle();
      expect(used, 'Please call me');
    });

    testWidgets('a voice note long press copies body and transcript', (
      tester,
    ) async {
      final copied = _mockClipboard(tester);
      final message = ChatMessage.fromJson({
        'name': 'M-2',
        'direction': 'Inbound',
        'message_type': 'audio',
        'body': 'caption here',
        'transcript': 'عايزة برطمانين',
        'timestamp': '2026-10-16 10:00:00',
      });
      expect(chatMessageCopyText(message), 'caption here\n\nعايزة برطمانين');
      await pumpBubble(tester, message);
      await tester.longPress(find.byKey(const ValueKey('chat-message-M-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chat-action-copy')));
      await tester.pumpAndSettle();
      expect(copied, ['caption here\n\nعايزة برطمانين']);
    });

    testWidgets('a message with no text has no sheet', (tester) async {
      await pumpBubble(tester, _message('', name: 'M-3', type: 'image'));
      await tester.longPress(find.byKey(const ValueKey('chat-message-M-3')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-message-actions')), findsNothing);
      expect(chatMessageCopyText(_message('', type: 'location')), isNull);
    });

    testWidgets('mixed-direction paragraphs inside a bubble lay out per line', (
      tester,
    ) async {
      await pumpBubble(tester, _message('تمام الطلب Mango Trio\nOk please'));
      expect(
        tester.widget<Text>(find.text('تمام الطلب Mango Trio')).textDirection,
        TextDirection.rtl,
      );
      expect(
        tester.widget<Text>(find.text('Ok please')).textDirection,
        TextDirection.ltr,
      );
    });
  });

  group('thread composer', () {
    Map<String, dynamic> thread({String? customer}) => {
      'message': {
        'conversation': {
          'name': 'CHAT-1',
          'channel': 'WhatsApp',
          'contact_name': 'Mona',
          'status': 'Open',
          'customer': customer,
        },
        'messages': [
          {
            'name': 'M-1',
            'direction': 'Inbound',
            'message_type': 'text',
            'body': 'Do you deliver to Maadi?',
            'timestamp': '2026-10-16 10:00:00',
          },
        ],
        'draft': null,
        'customer': null,
      },
    };

    List<Override> overrides(MockDio dio) => [
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
      chatUnreadTotalProvider.overrideWith(
        (ref) async => const ChatUnreadTotal(),
      ),
    ];

    testWidgets('Use in reply appends to the composer and focuses it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dio = MockDio()
        ..setResponse(ApiEndpoints.chatGetConversation, thread());
      await tester.pumpWidget(
        _app(overrides(dio), const ChatThreadScreen(conversation: 'CHAT-1')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('chat-composer')),
        'Hello Mona',
      );
      await tester.pump();
      await tester.longPress(find.byKey(const ValueKey('chat-message-M-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chat-action-reply')));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('chat-composer')),
      );
      expect(field.controller!.text, 'Hello Mona\nDo you deliver to Maadi?');
      expect(field.focusNode!.hasFocus, isTrue);
      expect(field.maxLines, 6);
    });

    testWidgets('the composer direction follows the typed text', (
      tester,
    ) async {
      final dio = MockDio()
        ..setResponse(ApiEndpoints.chatGetConversation, thread());
      await tester.pumpWidget(
        _app(overrides(dio), const ChatThreadScreen(conversation: 'CHAT-1')),
      );
      await tester.pumpAndSettle();
      TextDirection? direction() => tester
          .widget<TextField>(find.byKey(const ValueKey('chat-composer')))
          .textDirection;
      expect(direction(), TextDirection.ltr);
      await tester.enterText(
        find.byKey(const ValueKey('chat-composer')),
        'أهلا بيك Mona',
      );
      await tester.pump();
      expect(direction(), TextDirection.rtl);
    });
  });
}
