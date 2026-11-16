// Chat delete / edit / correction (contract chat-message-edit-delete): model
// parsing, the long-press sheet per flag, "Send correction" into the
// composer, deleted / edited bubbles and the notifier's replace / error path.
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
import 'package:jarz_pos/src/features/chat_inbox/presentation/widgets/chat_message_actions.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/widgets/chat_message_bubble.dart';
import 'package:jarz_pos/src/features/chat_inbox/state/chat_providers.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

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

Map<String, dynamic> _json({
  String name = 'M-1',
  String direction = 'Outbound',
  String body = 'hello there',
  Map<String, dynamic> extra = const {},
}) =>
    {
      'name': name,
      'direction': direction,
      'message_type': 'text',
      'body': body,
      'timestamp': '2026-10-16 10:00:00',
      ...extra,
    };

const _paths = 'jarz_pos.api.chat';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPlatformChannels();

  group('model', () {
    test('parses the new fields, tolerant of 0/1 and strings', () {
      final m = ChatMessage.fromJson(_json(extra: {
        'deleted_at': '2026-10-16 11:00:00',
        'edited_at': '2026-10-16 10:30:00',
        'original_body': 'old',
        'can_delete': 1,
        'can_edit': true,
      }));
      expect(m.deletedAt, '2026-10-16 11:00:00');
      expect(m.editedAt, '2026-10-16 10:30:00');
      expect(m.originalBody, 'old');
      expect(m.canDelete, isTrue);
      expect(m.canEdit, isTrue);
      expect(m.isDeleted, isTrue);
      expect(m.isEdited, isTrue);
    });

    test('defaults: null strings, false flags, survives copy', () {
      final m = ChatMessage.fromJson({'name': 'M-2', 'can_edit': 0});
      expect(m.deletedAt, isNull);
      expect(m.editedAt, isNull);
      expect(m.originalBody, isNull);
      expect(m.canDelete, isFalse);
      expect(m.canEdit, isFalse);
      final full = ChatMessage.fromJson(_json(extra: {
        'edited_at': 'x',
        'original_body': 'o',
        'can_edit': true,
      }));
      final copied = full.withStaffReaction('x').withTranscript('t');
      expect(copied.editedAt, 'x');
      expect(copied.originalBody, 'o');
      expect(copied.canEdit, isTrue);
    });
  });

  group('actions sheet', () {
    Future<void> open(
      WidgetTester tester,
      ChatMessage message, {
      ValueChanged<String>? onCorrection,
      ValueChanged<String>? onEdit,
      VoidCallback? onDelete,
      TextEditingController? composer,
    }) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Column(
              children: [
                if (composer != null) TextField(controller: composer),
                ChatMessageBubble(
                  message: message,
                  onCorrection: onCorrection,
                  onEditMessage: onEdit,
                  onDeleteMessage: onDelete,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.longPress(find.text(message.body));
      await tester.pumpAndSettle();
    }

    const edit = ValueKey('chat-action-edit');
    const del = ValueKey('chat-action-delete');
    const corr = ValueKey('chat-action-correction');

    testWidgets('Edit / Delete only per flags', (tester) async {
      await open(
        tester,
        ChatMessage.fromJson(_json(extra: {'can_edit': true})),
        onEdit: (_) {},
        onDelete: () {},
        onCorrection: (_) {},
      );
      expect(find.byKey(edit), findsOneWidget);
      expect(find.byKey(del), findsNothing);
      expect(find.byKey(corr), findsNothing);
    });

    testWidgets('delete flag only shows Delete for everyone', (tester) async {
      await open(
        tester,
        ChatMessage.fromJson(_json(extra: {'can_delete': true})),
        onEdit: (_) {},
        onDelete: () {},
        onCorrection: (_) {},
      );
      expect(find.byKey(del), findsOneWidget);
      expect(find.text('Delete for everyone'), findsOneWidget);
      expect(find.byKey(edit), findsNothing);
    });

    testWidgets('inbound message offers none of them', (tester) async {
      await open(
        tester,
        ChatMessage.fromJson(_json(
          direction: 'Inbound',
          extra: {'can_edit': true, 'can_delete': true},
        )),
        onEdit: (_) {},
        onDelete: () {},
        onCorrection: (_) {},
      );
      expect(find.byKey(edit), findsNothing);
      expect(find.byKey(del), findsNothing);
      expect(find.byKey(corr), findsNothing);
    });

    testWidgets('delete asks to confirm, then calls back', (tester) async {
      var deleted = 0;
      await open(
        tester,
        ChatMessage.fromJson(_json(extra: {'can_delete': true})),
        onDelete: () => deleted++,
      );
      await tester.tap(find.byKey(del));
      await tester.pumpAndSettle();
      expect(deleted, 0);
      await tester.tap(find.byKey(const ValueKey('chat-delete-confirm')));
      await tester.pumpAndSettle();
      expect(deleted, 1);
    });

    testWidgets('edit dialog saves the new text', (tester) async {
      final edits = <String>[];
      await open(
        tester,
        ChatMessage.fromJson(_json(extra: {'can_edit': true})),
        onEdit: edits.add,
      );
      await tester.tap(find.byKey(edit));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('chat-edit-field')),
        'fixed text',
      );
      await tester.tap(find.byKey(const ValueKey('chat-edit-save')));
      await tester.pumpAndSettle();
      expect(edits, ['fixed text']);
    });

    testWidgets('Send correction (English) hands over the prefixed text',
        (tester) async {
      final got = <String>[];
      await open(
        tester,
        ChatMessage.fromJson(_json()),
        onCorrection: got.add,
      );
      expect(find.byKey(edit), findsNothing);
      expect(find.byKey(del), findsNothing);
      expect(find.byKey(corr), findsOneWidget);
      await tester.tap(find.byKey(corr));
      await tester.pumpAndSettle();
      expect(got, ['Correction: hello there']);
      expect(find.byKey(const ValueKey('chat-correction-snack')), findsOneWidget);
    });

    test('correction prefix follows the script of the old text', () {
      expect(chatCorrectionText('السعر 100'), 'تصحيح: السعر 100');
      expect(chatCorrectionText(' price 100 '), 'Correction: price 100');
    });

    testWidgets('on a DM thread the correction lands in the composer',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dio = MockDio()
        ..setResponse(ApiEndpoints.chatGetConversation, {
          'message': {
            'conversation': {'name': 'CHAT-1', 'channel': 'WhatsApp'},
            'messages': [_json(body: 'wrong price')],
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
      await tester.longPress(find.text('wrong price'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(corr));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('chat-composer')),
      );
      expect(field.controller!.text, 'Correction: wrong price');
      expect(
        field.controller!.selection,
        const TextSelection.collapsed(offset: 'Correction: wrong price'.length),
      );
    });
  });

  group('bubbles', () {
    Future<void> pump(WidgetTester tester, ChatMessage m) => tester.pumpWidget(
          _app(Scaffold(body: ChatMessageBubble(message: m))),
        );

    testWidgets('deleted outbound: notice, tap toggles original',
        (tester) async {
      await pump(
        tester,
        ChatMessage.fromJson(_json(extra: {
          'deleted_at': '2026-10-16 11:00:00',
          'original_body': 'secret old text',
          'body': '',
        })),
      );
      expect(find.text('🚫 Message deleted'), findsOneWidget);
      expect(find.text('secret old text'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('chat-deleted-body')));
      await tester.pump();
      expect(find.text('secret old text'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('chat-deleted-body')));
      await tester.pump();
      expect(find.text('secret old text'), findsNothing);
    });

    testWidgets('deleted inbound: customer deleted notice', (tester) async {
      await pump(
        tester,
        ChatMessage.fromJson(_json(
          direction: 'Inbound',
          extra: {'deleted_at': 'x', 'original_body': 'gone'},
        )),
      );
      expect(find.text('🚫 Customer deleted this message'), findsOneWidget);
    });

    testWidgets('edited: label, tap shows the original', (tester) async {
      await pump(
        tester,
        ChatMessage.fromJson(_json(
          body: 'new text',
          extra: {'edited_at': 'x', 'original_body': 'first text'},
        )),
      );
      expect(find.text('new text'), findsOneWidget);
      expect(find.text('edited'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('chat-edited-label')));
      await tester.pumpAndSettle();
      expect(find.text('first text'), findsOneWidget);
    });

    testWidgets('plain message has no edited label', (tester) async {
      await pump(tester, ChatMessage.fromJson(_json()));
      expect(find.byKey(const ValueKey('chat-edited-label')), findsNothing);
    });
  });

  group('repository + notifier', () {
    const conv = 'CHAT-1';
    late MockDio dio;

    ProviderContainer container() => ProviderContainer(
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
            webSocketServiceProvider.overrideWithValue(MockWebSocketService()),
            chatUnreadTotalProvider
                .overrideWith((ref) async => ChatUnreadTotal.zero),
          ],
        );

    setUp(() {
      dio = MockDio()
        ..setResponse(ApiEndpoints.chatGetConversation, {
          'message': {
            'conversation': {'name': conv, 'channel': 'Facebook Comment'},
            'messages': [
              _json(extra: {'can_edit': true, 'can_delete': true}),
            ],
          },
        });
    });

    test('repository posts message (+ text) to the new paths', () async {
      final repo = ChatRepository(dio);
      dio.setResponse(ChatRepository.deleteMessagePath, {
        'message': {
          'message': {'name': 'M-1', 'deleted_at': 'x'},
        },
      });
      dio.setResponse(ChatRepository.editMessagePath, {
        'message': {
          'message': {'name': 'M-1', 'edited_at': 'y', 'body': 'b'},
        },
      });
      expect(ChatRepository.deleteMessagePath, endsWith('$_paths.delete_message'));
      expect(ChatRepository.editMessagePath, endsWith('$_paths.edit_message'));
      final d = await repo.deleteMessage(message: 'M-1');
      expect(d?.isDeleted, isTrue);
      expect(dio.requestLog.last['data'], {'message': 'M-1'});
      final e = await repo.editMessage(message: 'M-1', text: 'b');
      expect(e?.isEdited, isTrue);
      expect(dio.requestLog.last['data'], {'message': 'M-1', 'text': 'b'});
    });

    test('success replaces the message in state', () async {
      dio.setResponse(ChatRepository.editMessagePath, {
        'message': {
          'message': _json(
            body: 'edited body',
            extra: {'edited_at': 'y', 'original_body': 'hello there'},
          ),
        },
      });
      dio.setResponse(ChatRepository.deleteMessagePath, {
        'message': {
          'message': _json(
            body: '',
            extra: {'deleted_at': 'z', 'original_body': 'edited body'},
          ),
        },
      });
      final c = container();
      addTearDown(c.dispose);
      final sub = c.listen(chatThreadProvider(conv), (_, _) {});
      addTearDown(sub.close);
      await c.read(chatThreadProvider(conv).future);
      final notifier = c.read(chatThreadProvider(conv).notifier);
      final first = c.read(chatThreadProvider(conv)).requireValue.messages.single;

      await notifier.editMessage(first, 'edited body');
      var msgs = c.read(chatThreadProvider(conv)).requireValue.messages;
      expect(msgs, hasLength(1));
      expect(msgs.single.body, 'edited body');
      expect(msgs.single.isEdited, isTrue);
      expect(msgs.single.canEdit, isFalse);

      await notifier.deleteMessage(msgs.single);
      msgs = c.read(chatThreadProvider(conv)).requireValue.messages;
      expect(msgs, hasLength(1));
      expect(msgs.single.isDeleted, isTrue);
      expect(msgs.single.originalBody, 'edited body');
    });

    test('a refusal rethrows and leaves the message untouched', () async {
      dio.setError(
        ChatRepository.deleteMessagePath,
        DioException(
          requestOptions: RequestOptions(path: ChatRepository.deleteMessagePath),
          type: DioExceptionType.badResponse,
          message: 'Meta refused',
        ),
      );
      final c = container();
      addTearDown(c.dispose);
      final sub = c.listen(chatThreadProvider(conv), (_, _) {});
      addTearDown(sub.close);
      await c.read(chatThreadProvider(conv).future);
      final notifier = c.read(chatThreadProvider(conv).notifier);
      final first = c.read(chatThreadProvider(conv)).requireValue.messages.single;
      await expectLater(notifier.deleteMessage(first), throwsA(isA<DioException>()));
      final after = c.read(chatThreadProvider(conv)).requireValue.messages.single;
      expect(after.isDeleted, isFalse);
      expect(after.canDelete, isTrue);
    });
  });
}
