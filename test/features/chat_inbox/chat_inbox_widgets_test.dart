// Chat inbox state and screens: local filter matching and message merging,
// live socket merges into the inbox, the inbox rows (waiting label, draft
// dot), the complaint lock on the draft panel, and the training-check dialog
// after sending a planted draft as-is.
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
import 'package:jarz_pos/src/features/chat_inbox/presentation/widgets/chat_draft_panel.dart';
import 'package:jarz_pos/src/features/chat_inbox/state/chat_providers.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

const _me = 'mod@jarz.test';
final _now = DateTime(2026, 10, 16, 10, 30);

UserRoles _moderator() => UserRoles(
      user: _me,
      fullName: 'Mod',
      roles: const ['Moderator', 'POS User', 'Sales User'],
      requirePosShift: true,
      canAccessB2b: false,
      isB2bSalesRep: false,
    );

Map<String, dynamic> _summary(
  String name, {
  String status = 'Open',
  String channel = 'WhatsApp',
  String? assignedTo,
  String lastAt = '2026-10-16 10:00:00',
  String? waitingSince,
  bool draft = false,
  String? contact,
}) =>
    {
      'name': name,
      'channel': channel,
      'contact_name': contact ?? 'Contact $name',
      'status': status,
      'assigned_to': assignedTo,
      'last_message_at': lastAt,
      'last_message_preview': 'Hello',
      'last_direction': 'Inbound',
      'unread_count': 1,
      'waiting_since': waitingSince,
      'has_pending_draft': draft ? 1 : 0,
    };

ChatConversationSummary _s(
  String name, {
  String status = 'Open',
  String channel = 'WhatsApp',
  String? assignedTo,
}) =>
    ChatConversationSummary.fromJson(
      _summary(name, status: status, channel: channel, assignedTo: assignedTo),
    );

ChatMessage _m(String name, String? ts) =>
    ChatMessage.fromJson({'name': name, 'body': name, 'timestamp': ts});

List<Override> _overrides(MockDio dio, WebSocketService ws) => [
      chatRepositoryProvider.overrideWithValue(ChatRepository(dio)),
      userRolesFutureProvider.overrideWith((ref) async => _moderator()),
      webSocketServiceProvider.overrideWithValue(ws),
      chatClockProvider.overrideWithValue(() => _now),
      chatUnreadTotalProvider.overrideWith(
        (ref) async => const ChatUnreadTotal(openCount: 2, unreadTotal: 3),
      ),
    ];

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPlatformChannels();

  group('ChatInboxFilter', () {
    test('maps segments to the wire status; Mine adds mine=1', () {
      const f = ChatInboxFilter();
      // Open = not Closed: every status, with exclude_closed.
      expect(f.wireStatus, 'all');
      expect(f.excludeClosed, isTrue);
      expect(f.copyWith(segment: ChatInboxSegment.closed).wireStatus, 'Closed');
      expect(
        f.copyWith(segment: ChatInboxSegment.closed).excludeClosed,
        isFalse,
      );
      expect(f.copyWith(segment: ChatInboxSegment.all).excludeClosed, isFalse);
      expect(f.copyWith(segment: ChatInboxSegment.mine).excludeClosed, isFalse);
      final mine = f.copyWith(segment: ChatInboxSegment.mine);
      expect(mine.wireStatus, 'all');
      expect(mine.mine, isTrue);
      expect(f.copyWith(segment: ChatInboxSegment.all).mine, isFalse);
      expect(
        f.copyWith(channel: 'Instagram').copyWith(clearChannel: true).channel,
        isNull,
      );
    });

    test('chatSummaryMatchesFilter judges segment, channel and owner', () {
      const open = ChatInboxFilter();
      expect(chatSummaryMatchesFilter(_s('A'), open, _me), isTrue);
      // Answered stays in Open; only Closed leaves it.
      expect(
        chatSummaryMatchesFilter(_s('A', status: 'Answered'), open, _me),
        isTrue,
      );
      expect(
        chatSummaryMatchesFilter(_s('A', status: 'Closed'), open, _me),
        isFalse,
      );
      expect(
        chatSummaryMatchesFilter(
          _s('A', channel: 'Instagram'),
          open.copyWith(channel: 'WhatsApp'),
          _me,
        ),
        isFalse,
      );
      final mine = open.copyWith(segment: ChatInboxSegment.mine);
      expect(
        chatSummaryMatchesFilter(_s('A', assignedTo: _me, status: 'Answered'),
            mine, _me),
        isTrue,
      );
      expect(chatSummaryMatchesFilter(_s('A', assignedTo: 'x'), mine, _me),
          isFalse);
      expect(chatSummaryMatchesFilter(_s('A', assignedTo: _me), mine, null),
          isFalse);
      expect(
        chatSummaryMatchesFilter(_s('A', status: 'Closed'),
            open.copyWith(segment: ChatInboxSegment.all), _me),
        isTrue,
      );
    });
  });

  test('mergeChatMessages dedupes by name and sorts oldest first', () {
    final merged = mergeChatMessages(
      [_m('M1', '2026-10-16 10:00:00'), _m('M3', '2026-10-16 10:02:00')],
      [
        ChatMessage.fromJson({
          'name': 'M3',
          'body': 'updated',
          'timestamp': '2026-10-16 10:02:00',
        }),
        _m('M2', '2026-10-16 10:01:00'),
      ],
    );
    expect(merged.map((m) => m.name), ['M1', 'M2', 'M3']);
    expect(merged.last.body, 'updated');
  });

  test('chatDraftIsShowable: Pending and Failed only', () {
    ChatDraft d(String status) =>
        ChatDraft.fromJson({'name': 'D', 'status': status, 'draft_text': 'x'});
    expect(chatDraftIsShowable(d('Pending')), isTrue);
    expect(chatDraftIsShowable(d('Failed')), isTrue);
    expect(chatDraftIsShowable(d('Sent As-Is')), isFalse);
    expect(chatDraftIsShowable(null), isFalse);
  });

  test('inbox merges socket summaries: insert, update and drop', () async {
    final dio = MockDio()
      ..setResponse(ApiEndpoints.chatGetConversations, {
        'message': {
          'conversations': [
            _summary('CHAT-1', lastAt: '2026-10-16 10:00:00'),
          ],
          'has_more': 0,
          'open_count': 1,
        },
      });
    final ws = MockWebSocketService();
    final container = ProviderContainer(overrides: _overrides(dio, ws));
    addTearDown(container.dispose);
    final sub = container.listen(chatInboxProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(chatInboxProvider.future);
    await container.read(userRolesFutureProvider.future);

    void emit(Map<String, dynamic> summary) => ws.debugHandleMessage({
          'event': WsEvents.chatUpdate,
          'data': <String, dynamic>{
            'conversation': summary['name'],
            'kind': 'message',
            'summary': summary,
          },
        });

    emit(_summary('CHAT-2', lastAt: '2026-10-16 10:05:00'));
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(chatInboxProvider).value!.conversations.map((c) => c.name),
      ['CHAT-2', 'CHAT-1'],
    );

    // A reply makes it Answered: it stays in Open (not Closed) ...
    emit(_summary('CHAT-1', status: 'Answered'));
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(chatInboxProvider).value!.conversations.map((c) => c.name),
      ['CHAT-2', 'CHAT-1'],
    );
    expect(
      container.read(chatInboxProvider).value!.conversations.last.status,
      'Answered',
    );

    // ... and closing it drops it.
    emit(_summary('CHAT-1', status: 'Closed'));
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(chatInboxProvider).value!.conversations.map((c) => c.name),
      ['CHAT-2'],
    );

    // A closed chat does not enter the Open list.
    emit(_summary('CHAT-9', status: 'Closed'));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(chatInboxProvider).value!.conversations, hasLength(1));
  });

  testWidgets('inbox rows: waiting label turns red past the alert, draft dot',
      (tester) async {
    final dio = MockDio()
      ..setResponse(ApiEndpoints.chatGetConversations, {
        'message': {
          'conversations': [
            _summary('CHAT-LATE',
                waitingSince: '2026-10-16 10:15:00', draft: true,
                contact: 'Late Lina'),
            _summary('CHAT-NEW',
                waitingSince: '2026-10-16 10:27:00', contact: 'New Nour'),
          ],
          'has_more': 0,
          'open_count': 2,
        },
      });
    await tester.pumpWidget(
      _app(_overrides(dio, MockWebSocketService()), const ChatInboxScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Late Lina'), findsOneWidget);
    expect(find.text('New Nour'), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-draft-dot-CHAT-LATE')), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-draft-dot-CHAT-NEW')), findsNothing);

    final context = tester.element(find.byType(ChatInboxScreen));
    final errorColor = Theme.of(context).colorScheme.error;
    final late = tester.widget<Text>(
      find.byKey(const ValueKey('chat-waiting-CHAT-LATE')),
    );
    final fresh = tester.widget<Text>(
      find.byKey(const ValueKey('chat-waiting-CHAT-NEW')),
    );
    expect(late.data, 'Waiting 15 min');
    expect(late.style?.color, errorColor);
    expect(fresh.data, 'Waiting 3 min');
    expect(fresh.style?.color, isNot(errorColor));

    // The Open segment carries the open count from get_unread_total.
    expect(find.text('Open (2)'), findsOneWidget);
    expect(dio.requestLog.first['queryParameters'], {
      'status': 'all',
      'exclude_closed': 1,
      'limit': 30,
    });
  });

  testWidgets('complaint draft: Send stays disabled until the text is edited',
      (tester) async {
    String? sent;
    final draft = ChatDraft.fromJson({
      'name': 'D-1',
      'status': 'Pending',
      'draft_text': 'Sorry about that.',
      'is_complaint': 1,
    });
    await tester.pumpWidget(
      _app(
        const [],
        Scaffold(
          body: ChatDraftPanel(
            draft: draft,
            busy: false,
            onSend: (text) => sent = text,
            onReject: () {},
            onRegenerate: () {},
          ),
        ),
      ),
    );

    FilledButton sendButton() => tester.widget<FilledButton>(
          find.byKey(const ValueKey('chat-draft-send')),
        );

    expect(find.byKey(const ValueKey('chat-draft-complaint-lock')), findsOneWidget);
    expect(sendButton().onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('chat-draft-field')),
      'We are so sorry, a fresh jar is on its way.',
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('chat-draft-complaint-lock')), findsNothing);
    expect(sendButton().onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('chat-draft-send')));
    expect(sent, 'We are so sorry, a fresh jar is on its way.');
  });

  testWidgets(
      'complaint draft: tapping the lock note scrolls back to the draft box '
      'and focuses it', (tester) async {
    final draft = ChatDraft.fromJson({
      'name': 'D-2',
      'status': 'Pending',
      'draft_text': 'Sorry about that.',
      'is_complaint': 1,
      'warnings': [for (var i = 1; i <= 6; i++) 'Check point $i before sending.'],
    });
    await tester.pumpWidget(
      _app(
        const [],
        Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ChatDraftPanel(
              draft: draft,
              busy: false,
              maxHeight: 220,
              onSend: (_) {},
              onReject: () {},
              onRegenerate: () {},
            ),
          ),
        ),
      ),
    );

    final field = find.byKey(const ValueKey('chat-draft-field'));
    final lock = find.byKey(const ValueKey('chat-draft-complaint-lock'));
    final panel = find.byKey(const ValueKey('chat-draft-panel'));

    // Scroll the panel down to the lock note, as in the field report: the
    // draft box is then above the panel's visible top.
    await tester.dragUntilVisible(lock, panel, const Offset(0, -60));
    await tester.pumpAndSettle();
    final panelTop = tester.getTopLeft(panel).dy;
    expect(tester.getTopLeft(field).dy, lessThan(panelTop));

    await tester.tap(lock);
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(field).dy, greaterThanOrEqualTo(panelTop));
    final editable = tester.widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );
    expect(editable.focusNode.hasFocus, isTrue);
    expect(
      editable.controller.selection,
      const TextSelection.collapsed(offset: 'Sorry about that.'.length),
    );
  });

  testWidgets('fact conflicts show a confirm alert but Send stays enabled',
      (tester) async {
    String? sent;
    final draft = ChatDraft.fromJson({
      'name': 'D-2',
      'status': 'Pending',
      'draft_text': 'Delivered within one hour.',
      'fact_conflicts': ['Delivery within 1 hour → Same day, no fixed hour'],
    });
    await tester.pumpWidget(
      _app(
        const [],
        Scaffold(
          body: ChatDraftPanel(
            draft: draft,
            busy: false,
            onSend: (text) => sent = text,
            onReject: () {},
            onRegenerate: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('chat-draft-fact-conflicts')), findsOneWidget);
    expect(
      find.text('Delivery within 1 hour → Same day, no fixed hour'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('chat-draft-send')));
    expect(sent, 'Delivered within one hour.');
  });

  testWidgets('sending a planted draft as-is shows the training-check dialog',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final dio = MockDio()
      ..setResponse(ApiEndpoints.chatGetConversation, {
        'message': {
          'conversation': _summary('CHAT-1', draft: true),
          'messages': [
            {
              'name': 'M-1',
              'direction': 'Inbound',
              'message_type': 'text',
              'body': 'How much is the jar?',
              'timestamp': '2026-10-16 10:00:00',
            },
          ],
          'draft': {
            'name': 'D-1',
            'status': 'Pending',
            'draft_text': 'The jar is 150 EGP.',
          },
          'customer': null,
        },
      })
      ..setResponse(ApiEndpoints.chatSendDraft, {
        'message': {
          'message': null,
          'draft': {
            'name': 'D-1',
            'status': 'Blocked',
            'draft_text': 'The jar is 150 EGP.',
            'planted_error': 'price 120 changed to 150',
          },
          'planted': true,
          'caught': false,
        },
      });

    await tester.pumpWidget(
      _app(
        _overrides(dio, MockWebSocketService()),
        const ChatThreadScreen(conversation: 'CHAT-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('How much is the jar?'), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-draft-panel')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('chat-draft-send')));
    await tester.tap(find.byKey(const ValueKey('chat-draft-send')));
    await tester.pumpAndSettle();

    final sendCall =
        dio.requestLog.firstWhere((r) => r['path'] == ApiEndpoints.chatSendDraft);
    expect(sendCall['data'], {'draft': 'D-1', 'final_text': 'The jar is 150 EGP.'});
    expect(find.byKey(const ValueKey('chat-planted-dialog')), findsOneWidget);
    expect(
      find.text(
        'Training check — this draft had a deliberate mistake: '
        'price 120 changed to 150. It was not sent.',
      ),
      findsOneWidget,
    );
  });
}
