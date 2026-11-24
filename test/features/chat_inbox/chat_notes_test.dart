// Staff notes on a chat: the Note payload, `open_notes` on the summary, the
// `kind: note` socket update that replaces an open thread's notes live, the
// note writes, a refresh from an older server that must not wipe them, the
// "new note arrived" detection, and the strip / inbox badge widgets.
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
import 'package:jarz_pos/src/features/chat_inbox/presentation/screens/chat_thread_screen.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/widgets/chat_conversation_tile.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/widgets/chat_notes_strip.dart';
import 'package:jarz_pos/src/features/chat_inbox/state/chat_providers.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

const _conv = 'CHAT-1';

Map<String, dynamic> _noteJson({
  String name = 'NOTE-1',
  String note = 'You were rude to her, apologise.\nThen offer free delivery.',
  String author = 'boss@jarz.test',
  String authorName = 'Boss',
  Object resolved = 0,
  String? resolvedByName,
  bool canDelete = true,
}) =>
    {
      'name': name,
      'conversation': _conv,
      'note': note,
      'author': author,
      'author_name': authorName,
      'created_at': '2026-11-24 10:15:00',
      'resolved': resolved,
      'resolved_by': resolvedByName == null ? null : 'mod@jarz.test',
      'resolved_by_name': resolvedByName,
      'resolved_at': resolvedByName == null ? null : '2026-11-24 10:20:00',
      'can_delete': canDelete,
    };

Map<String, dynamic> _summaryJson({int openNotes = 0}) => {
      'name': _conv,
      'channel': 'WhatsApp',
      'status': 'Open',
      'contact_name': 'Mona',
      'last_message_at': '2026-11-24 10:00:00',
      'last_direction': 'Inbound',
      'open_notes': openNotes,
    };

Map<String, dynamic> _threadJson({List<Map<String, dynamic>>? notes}) => {
      'message': {
        'conversation': _summaryJson(
          openNotes: notes == null
              ? 0
              : notes.where((n) => n['resolved'] == 0).length,
        ),
        'messages': <Map<String, dynamic>>[],
        'draft': null,
        'customer': null,
        if (notes != null) 'notes': notes,
      },
    };

ProviderContainer _container(MockDio dio, MockWebSocketService ws) {
  return ProviderContainer(
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
      chatUnreadTotalProvider.overrideWith((ref) async => ChatUnreadTotal.zero),
    ],
  );
}

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPlatformChannels();

  group('ChatNote parsing', () {
    test('reads every field', () {
      final n = ChatNote.fromJson(
        _noteJson(resolved: true, resolvedByName: 'Mod'),
      );
      expect(n.name, 'NOTE-1');
      expect(n.conversation, _conv);
      expect(n.authorLabel, 'Boss');
      expect(n.createdTime, DateTime(2026, 11, 24, 10, 15));
      expect(n.resolved, isTrue);
      expect(n.isOpen, isFalse);
      expect(n.resolvedByLabel, 'Mod');
      expect(n.canDelete, isTrue);
      expect(n.firstLine, 'You were rude to her, apologise.');
    });

    test('lenient flags and missing names', () {
      final n = ChatNote.fromJson({
        'name': 'N',
        'note': 'x',
        'resolved': '0',
        'can_delete': 0,
        'author': 'a@jarz.test',
      });
      expect(n.resolved, isFalse);
      expect(n.canDelete, isFalse);
      expect(n.authorLabel, 'a@jarz.test');
      expect(n.resolvedByLabel, isNull);
    });

    test('chatNoteList drops rows without a name and keeps order', () {
      final list = chatNoteList([
        _noteJson(name: 'B'),
        {'note': 'no name'},
        'junk',
        _noteJson(name: 'A', resolved: 1),
      ]);
      expect(list.map((n) => n.name), ['B', 'A']);
      expect(chatOpenNoteCount(list), 1);
      expect(chatNoteList(null), isEmpty);
    });

    test('summary open_notes, thread notes and the socket payload', () {
      expect(
        ChatConversationSummary.fromJson(_summaryJson(openNotes: 2)).openNotes,
        2,
      );
      expect(ChatConversationSummary.fromJson({'name': 'X'}).openNotes, 0);
      final withNotes =
          ChatThread.fromJson(_threadJson(notes: [_noteJson()])['message']);
      expect(withNotes.notes, hasLength(1));
      final older = ChatThread.fromJson(_threadJson()['message']);
      expect(older.notes, isNull, reason: 'absent key = older server');
      final event = ChatUpdateEvent.fromJson({
        'conversation': _conv,
        'kind': 'note',
        'summary': _summaryJson(openNotes: 1),
        'notes': [_noteJson()],
      });
      expect(event.kind, 'note');
      expect(event.notes, hasLength(1));
      expect(event.summary?.openNotes, 1);
      expect(
        ChatUpdateEvent.fromJson({'conversation': _conv, 'kind': 'message'})
            .notes,
        isNull,
      );
    });

    test('copyWith and inheritMediaInfo keep open_notes', () {
      final s = ChatConversationSummary.fromJson(_summaryJson(openNotes: 3));
      expect(s.copyWith(unreadCount: 0).openNotes, 3);
      expect(s.copyWith(openNotes: 1).openNotes, 1);
      final previous = ChatConversationSummary.fromJson({
        ..._summaryJson(),
        'can_send_media': true,
      });
      expect(s.inheritMediaInfo(previous).openNotes, 3);
    });
  });

  group('chatNewOpenNotes', () {
    final old = ChatNote.fromJson(_noteJson(name: 'OLD'));
    final fresh = ChatNote.fromJson(_noteJson(name: 'NEW'));
    final mine = ChatNote.fromJson(
      _noteJson(name: 'MINE', author: 'mod@jarz.test'),
    );
    final handled = ChatNote.fromJson(_noteJson(name: 'H', resolved: 1));

    test('first load announces nothing', () {
      expect(chatNewOpenNotes(null, [old, fresh]), isEmpty);
    });

    test('only new, open notes by someone else', () {
      final arrived = chatNewOpenNotes(
        [old],
        [fresh, mine, handled, old],
        currentUser: 'mod@jarz.test',
      );
      expect(arrived.map((n) => n.name), ['NEW']);
    });
  });

  group('thread notifier', () {
    test('loads notes, applies a kind:note socket update live', () async {
      final dio = MockDio()
        ..setResponse(
          ApiEndpoints.chatGetConversation,
          _threadJson(notes: [_noteJson(name: 'N1')]),
        );
      final ws = MockWebSocketService();
      final container = _container(dio, ws);
      addTearDown(container.dispose);
      final sub = container.listen(chatThreadProvider(_conv), (_, _) {});
      addTearDown(sub.close);
      await container.read(chatThreadProvider(_conv).future);
      var state = container.read(chatThreadProvider(_conv)).requireValue;
      expect(state.notes.map((n) => n.name), ['N1']);
      expect(state.openNoteCount, 1);

      ws.debugHandleMessage({
        'event': WsEvents.chatUpdate,
        'data': <String, dynamic>{
          'conversation': _conv,
          'kind': 'note',
          'summary': _summaryJson(openNotes: 1),
          'notes': [
            _noteJson(name: 'N2', note: 'Give her free delivery'),
            _noteJson(name: 'N1', resolved: 1, resolvedByName: 'Mod'),
          ],
        },
      });
      await Future<void>.delayed(Duration.zero);

      state = container.read(chatThreadProvider(_conv)).requireValue;
      expect(state.notes.map((n) => n.name), ['N2', 'N1']);
      expect(state.notes.last.resolved, isTrue);
      expect(state.conversation.openNotes, 1);
    });

    test('a note event for another chat is ignored', () async {
      final dio = MockDio()
        ..setResponse(ApiEndpoints.chatGetConversation, _threadJson(notes: []));
      final ws = MockWebSocketService();
      final container = _container(dio, ws);
      addTearDown(container.dispose);
      final sub = container.listen(chatThreadProvider(_conv), (_, _) {});
      addTearDown(sub.close);
      await container.read(chatThreadProvider(_conv).future);

      ws.debugHandleMessage({
        'event': WsEvents.chatUpdate,
        'data': <String, dynamic>{
          'conversation': 'CHAT-2',
          'kind': 'note',
          'notes': [_noteJson()],
        },
      });
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(chatThreadProvider(_conv)).requireValue.notes,
        isEmpty,
      );
    });

    test('add / handle / delete post and take the returned list', () async {
      final dio = MockDio()
        ..setResponse(ApiEndpoints.chatGetConversation, _threadJson(notes: []))
        ..setResponse(ChatRepository.addChatNotePath, {
          'message': {
            'note': _noteJson(name: 'N1', author: 'mod@jarz.test'),
            'notes': [_noteJson(name: 'N1', author: 'mod@jarz.test')],
          },
        })
        ..setResponse(ChatRepository.setChatNoteHandledPath, {
          'message': {
            'note': _noteJson(name: 'N1', resolved: 1, resolvedByName: 'Mod'),
            'notes': [
              _noteJson(name: 'N1', resolved: 1, resolvedByName: 'Mod'),
            ],
          },
        })
        ..setResponse(ChatRepository.deleteChatNotePath, {
          'message': {'ok': true, 'notes': <Object>[]},
        });
      final ws = MockWebSocketService();
      final container = _container(dio, ws);
      addTearDown(container.dispose);
      final sub = container.listen(chatThreadProvider(_conv), (_, _) {});
      addTearDown(sub.close);
      await container.read(chatThreadProvider(_conv).future);
      final notifier = container.read(chatThreadProvider(_conv).notifier);

      await notifier.addNote('Apologise');
      var state = container.read(chatThreadProvider(_conv)).requireValue;
      expect(state.notes.single.name, 'N1');
      expect(state.conversation.openNotes, 1);
      final addCall = dio.requestLog
          .lastWhere((r) => r['path'] == ChatRepository.addChatNotePath);
      expect(addCall['method'], 'POST');
      expect(addCall['data'], {'conversation': _conv, 'note': 'Apologise'});

      await notifier.setNoteHandled(state.notes.single, true);
      state = container.read(chatThreadProvider(_conv)).requireValue;
      expect(state.notes.single.resolved, isTrue);
      expect(state.conversation.openNotes, 0);
      final handledCall = dio.requestLog.lastWhere(
        (r) => r['path'] == ChatRepository.setChatNoteHandledPath,
      );
      expect(handledCall['data'], {'note': 'N1', 'handled': 1});

      await notifier.deleteNote(state.notes.single);
      state = container.read(chatThreadProvider(_conv)).requireValue;
      expect(state.notes, isEmpty);
    });

    test('a refresh without `notes` (older server) keeps the notes', () async {
      final dio = MockDio()
        ..setResponse(
          ApiEndpoints.chatGetConversation,
          _threadJson(notes: [_noteJson()]),
        );
      final ws = MockWebSocketService();
      final container = _container(dio, ws);
      addTearDown(container.dispose);
      final sub = container.listen(chatThreadProvider(_conv), (_, _) {});
      addTearDown(sub.close);
      await container.read(chatThreadProvider(_conv).future);

      dio.setResponse(ApiEndpoints.chatGetConversation, _threadJson());
      await container.read(chatThreadProvider(_conv).notifier).refresh();
      expect(
        container.read(chatThreadProvider(_conv)).requireValue.notes,
        hasLength(1),
      );
    });
  });

  group('widgets', () {
    ChatNotesStrip strip(
      List<ChatNote> notes, {
      bool expanded = false,
      VoidCallback? onToggle,
    }) =>
        ChatNotesStrip(
          notes: notes,
          expanded: expanded,
          onToggleExpanded: onToggle ?? () {},
          onAdd: () {},
          onSetHandled: (_, _) {},
          onDelete: (_) {},
          now: DateTime(2026, 11, 24, 12),
        );

    testWidgets('hidden with no notes', (tester) async {
      await tester.pumpWidget(_app(strip(const [])));
      expect(find.byKey(const ValueKey('chat-notes-strip')), findsNothing);
    });

    testWidgets('collapsed: count and newest open first line', (tester) async {
      var toggled = false;
      await tester.pumpWidget(_app(strip(
        [ChatNote.fromJson(_noteJson())],
        onToggle: () => toggled = true,
      )));
      expect(find.text('Notes (1)'), findsOneWidget);
      expect(find.text('You were rude to her, apologise.'), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-notes-list')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('chat-notes-toggle')));
      expect(toggled, isTrue);
    });

    testWidgets('expanded: rows, handled-by, delete only when allowed',
        (tester) async {
      await tester.pumpWidget(_app(strip(
        [
          ChatNote.fromJson(_noteJson(name: 'A', canDelete: false)),
          ChatNote.fromJson(
            _noteJson(name: 'B', resolved: 1, resolvedByName: 'Mod'),
          ),
        ],
        expanded: true,
      )));
      expect(find.byKey(const ValueKey('chat-notes-list')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-note-delete-A')), findsNothing);
      expect(find.byKey(const ValueKey('chat-note-delete-B')), findsOneWidget);
      expect(find.text('Handled by Mod'), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-notes-add')), findsOneWidget);
    });

    testWidgets('all handled: muted label', (tester) async {
      await tester.pumpWidget(_app(strip([
        ChatNote.fromJson(_noteJson(resolved: 1, resolvedByName: 'Mod')),
      ])));
      expect(find.text('Notes (1) · all handled'), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-notes-preview')), findsNothing);
    });

    testWidgets('inbox tile shows the badge only with open notes',
        (tester) async {
      Widget tile(int open) => _app(ChatConversationTile(
            summary: ChatConversationSummary.fromJson(
              _summaryJson(openNotes: open),
            ),
            now: DateTime(2026, 11, 24, 12),
            onTap: () {},
          ));
      await tester.pumpWidget(tile(2));
      expect(find.byKey(const ValueKey('chat-notes-badge-$_conv')),
          findsOneWidget);
      await tester.pumpWidget(tile(0));
      expect(find.byKey(const ValueKey('chat-notes-badge-$_conv')),
          findsNothing);
    });
  });

  group('thread screen', () {
    Widget screen(MockDio dio, MockWebSocketService ws) => ProviderScope(
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
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ChatThreadScreen(conversation: _conv),
          ),
        );

    void bigView(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('menu "Add staff note" saves through add_chat_note',
        (tester) async {
      bigView(tester);
      final dio = MockDio()
        ..setResponse(ApiEndpoints.chatGetConversation, _threadJson(notes: []))
        ..setResponse(ChatRepository.addChatNotePath, {
          'message': {
            'notes': [
              _noteJson(
                name: 'N1',
                note: 'Free delivery',
                author: 'mod@jarz.test',
              ),
            ],
          },
        });
      await tester.pumpWidget(screen(dio, MockWebSocketService()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-notes-strip')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('chat-thread-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chat-menu-add-note')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('chat-add-note-field')),
        'Free delivery',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('chat-add-note-save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('chat-add-note-dialog')), findsNothing);
      expect(find.byKey(const ValueKey('chat-notes-strip')), findsOneWidget);
      // Opened after a save, so the new note is in view.
      expect(find.byKey(const ValueKey('chat-note-N1')), findsOneWidget);
      // Our own note is not announced as a "new note".
      expect(find.textContaining('New note from'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a live note from someone else opens the strip and says so',
        (tester) async {
      bigView(tester);
      final dio = MockDio()
        ..setResponse(ApiEndpoints.chatGetConversation, _threadJson(notes: []));
      final ws = MockWebSocketService();
      await tester.pumpWidget(screen(dio, ws));
      await tester.pumpAndSettle();

      ws.debugHandleMessage({
        'event': WsEvents.chatUpdate,
        'data': <String, dynamic>{
          'conversation': _conv,
          'kind': 'note',
          'summary': _summaryJson(openNotes: 1),
          'notes': [_noteJson(name: 'N9', note: 'Apologise to her')],
        },
      });
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const ValueKey('chat-notes-list')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-note-N9')), findsOneWidget);
      expect(
        find.text('New note from Boss: Apologise to her'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
