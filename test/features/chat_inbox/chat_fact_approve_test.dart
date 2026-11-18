// "Add to facts": a manager approves a statement a moderator told the AI
// (a fact-conflict line) into the approved facts, from the draft panel's
// confirm-facts alert and from the moderator-overrides screen. Covers the new
// wire fields (missing -> defaults), the action's visibility, the "Added to
// facts" tick, the dialog prefill and validation, and the request sent.
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
import 'package:jarz_pos/src/features/chat_inbox/presentation/screens/chat_fact_overrides_screen.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/screens/chat_thread_screen.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/widgets/chat_add_fact_dialog.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/widgets/chat_draft_panel.dart';
import 'package:jarz_pos/src/features/chat_inbox/state/chat_providers.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

const _lineA = 'Our jars are sugar free → Jars contain sugar';
const _lineB = 'Delivery within 1 hour → Same day, no fixed hour';
final _now = DateTime(2026, 11, 16, 12);

const _delegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Widget _plain(Widget home, {Locale locale = const Locale('en')}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: _delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

Widget _panel(
  ChatDraft draft, {
  bool canApprove = false,
  void Function(int index, String line)? onAddFact,
}) => _plain(
  Scaffold(
    body: ChatDraftPanel(
      draft: draft,
      busy: false,
      onSend: (_) {},
      onReject: () {},
      onRegenerate: () {},
      canApproveFacts: canApprove,
      onAddFact: onAddFact ?? (_, _) {},
    ),
  ),
);

ChatDraft _draft({List<int>? approved}) => ChatDraft.fromJson({
  'name': 'D-9',
  'status': 'Pending',
  'draft_text': 'Our jars are sugar free.',
  'fact_conflicts': [_lineA, _lineB],
  if (approved != null) 'approved_conflicts': approved,
});

Map<String, dynamic> _row(String draft, {List<int>? approved}) => {
  'draft': draft,
  'conversation': 'CHAT-1',
  'contact_name': 'Mona Salem',
  'channel': 'WhatsApp',
  'created_at': '2026-11-14 16:20:00',
  'requested_by_name': 'Mona',
  'moderator_hint': 'say they are sugar free',
  'conflicts': [_lineA, _lineB],
  if (approved != null) 'approved_conflicts': approved,
  'status': 'Sent Edited',
};

Widget _overridesApp(MockDio dio) => ProviderScope(
  overrides: [
    chatRepositoryProvider.overrideWithValue(ChatRepository(dio)),
    chatClockProvider.overrideWithValue(() => _now),
  ],
  child: _plain(const ChatFactOverridesScreen()),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPlatformChannels();

  group('wire fields', () {
    test('a draft without approved_conflicts has none approved', () {
      final draft = ChatDraft.fromJson({
        'name': 'D-1',
        'fact_conflicts': [_lineA],
      });
      expect(draft.approvedConflicts, isEmpty);
      expect(draft.isConflictApproved(0), isFalse);
    });

    test('approved_conflicts is read leniently', () {
      final draft = ChatDraft.fromJson({
        'name': 'D-1',
        'fact_conflicts': [_lineA, _lineB],
        'approved_conflicts': [1, '0', 2.0, null, 'x'],
      });
      expect(draft.approvedConflicts, [1, 0, 2]);
      final fromString = ChatDraft.fromJson({
        'name': 'D-1',
        'approved_conflicts': '[1]',
      });
      expect(fromString.approvedConflicts, [1]);
      // Survives the planted-error copy.
      expect(draft.withPlantedError('x').approvedConflicts, [1, 0, 2]);
      expect(
        ChatDraft.fromJson({'name': 'D-1'})
            .withApprovedConflicts([0])
            .isConflictApproved(0),
        isTrue,
      );
    });

    test('can_approve_facts: missing is false; a later summary without it '
        'keeps what the thread knew', () {
      final old = ChatConversationSummary.fromJson({'name': 'C-1'});
      expect(old.canApproveFacts, isFalse);
      expect(old.approveInfoKnown, isFalse);

      final full = ChatConversationSummary.fromJson({
        'name': 'C-1',
        'can_approve_facts': 1,
      });
      expect(full.canApproveFacts, isTrue);
      expect(full.approveInfoKnown, isTrue);

      final state = ChatThreadState(conversation: full).copyWith(
        conversation: ChatConversationSummary.fromJson({
          'name': 'C-1',
          'status': 'Closed',
        }),
      );
      expect(state.conversation.canApproveFacts, isTrue);
      expect(state.conversation.status, 'Closed');

      final refused = ChatThreadState(conversation: full).copyWith(
        conversation: ChatConversationSummary.fromJson({
          'name': 'C-1',
          'can_approve_facts': false,
        }),
      );
      expect(refused.conversation.canApproveFacts, isFalse);
      // copyWith keeps the flag.
      expect(full.copyWith(unreadCount: 0).canApproveFacts, isTrue);
    });

    test('overrides page and row read the new fields, defaults when absent',
        () {
      final old = ChatFactOverridesPage.fromJson({
        'rows': [_row('D-1')],
      });
      expect(old.canApproveFacts, isFalse);
      expect(old.rows.single.approvedConflicts, isEmpty);

      final page = ChatFactOverridesPage.fromJson({
        'rows': [
          _row('D-1', approved: [1]),
        ],
        'can_approve_facts': true,
      });
      expect(page.canApproveFacts, isTrue);
      expect(page.rows.single.isConflictApproved(1), isTrue);
      expect(page.rows.single.isConflictApproved(0), isFalse);
      expect(
        page.rows.single.withApprovedConflicts([0, 1]).approvedConflicts,
        [0, 1],
      );
    });

    test('approve_fact_conflict answer', () {
      final result = ChatFactApprovalResult.fromJson({
        'fact': 'FACT-7',
        'draft': 'D-1',
        'approved_conflicts': [0, 1],
      });
      expect(result.fact, 'FACT-7');
      expect(result.draft, 'D-1');
      expect(result.approvedConflicts, [0, 1]);
      expect(ChatFactApprovalResult.fromJson(null).approvedConflicts, isEmpty);
    });

    test('approved list after a call always includes the tapped line', () {
      const echoed = ChatFactApprovalResult(approvedConflicts: [0, 2]);
      expect(chatApprovedAfter(const [0], echoed, 2), [0, 2]);
      const silent = ChatFactApprovalResult();
      expect(chatApprovedAfter(const [3], silent, 1), [1, 3]);
    });
  });

  group('prefill helpers', () {
    test('the moderator side is the text before the arrow', () {
      expect(chatConflictModeratorSide(_lineA), 'Our jars are sugar free');
      expect(chatConflictModeratorSide('  no arrow here '), 'no arrow here');
    });

    test('the topic is cut at a word boundary to about 60 characters', () {
      expect(chatFactTopicFromLine(_lineA), 'Our jars are sugar free');
      const long =
          'Every jar ships in a cooled box and stays fresh for twelve days '
          'outside the fridge → Keep refrigerated';
      final topic = chatFactTopicFromLine(long);
      expect(topic.length, lessThanOrEqualTo(60));
      expect(topic, 'Every jar ships in a cooled box and stays fresh for twelve');
      expect(
        chatFactTopicFromLine('x' * 80),
        'x' * 60,
        reason: 'a single long word is cut hard',
      );
    });
  });

  group('draft panel alert', () {
    testWidgets('no action without can_approve_facts', (tester) async {
      await tester.pumpWidget(_panel(_draft()));
      expect(
        find.byKey(const ValueKey('chat-draft-fact-conflicts')),
        findsOneWidget,
      );
      expect(find.text('Add to facts'), findsNothing);
      expect(find.byKey(const ValueKey('chat-fact-add-0')), findsNothing);
    });

    testWidgets('a manager gets "Add to facts" on each line; tapping passes '
        'the index and the line', (tester) async {
      final taps = <(int, String)>[];
      await tester.pumpWidget(
        _panel(
          _draft(),
          canApprove: true,
          onAddFact: (index, line) => taps.add((index, line)),
        ),
      );
      expect(find.text('Add to facts'), findsNWidgets(2));
      await tester.tap(find.byKey(const ValueKey('chat-fact-add-1')));
      expect(taps, [(1, _lineB)]);
    });

    testWidgets('an approved line shows "Added to facts ✓" instead', (
      tester,
    ) async {
      await tester.pumpWidget(
        _panel(_draft(approved: [0]), canApprove: true),
      );
      expect(find.byKey(const ValueKey('chat-fact-added-0')), findsOneWidget);
      expect(find.text('Added to facts ✓'), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-fact-add-0')), findsNothing);
      expect(find.byKey(const ValueKey('chat-fact-add-1')), findsOneWidget);
    });

    testWidgets('Arabic locale uses the inline Arabic labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: _delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ChatDraftPanel(
              draft: _draft(approved: [1]),
              busy: false,
              onSend: (_) {},
              onReject: () {},
              onRegenerate: () {},
              canApproveFacts: true,
              onAddFact: (_, _) {},
            ),
          ),
        ),
      );
      expect(find.text('أضف للمعلومات'), findsOneWidget);
      expect(find.text('اتضافت للمعلومات ✓'), findsOneWidget);
    });
  });

  group('dialog', () {
    Future<void> openDialog(
      WidgetTester tester,
      Future<void> Function(ChatFactApprovalInput) onSubmit, {
      ValueChanged<bool>? onResult,
    }) async {
      await tester.pumpWidget(
        _plain(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  final added = await showChatAddFactDialog(
                    context,
                    line: _lineA,
                    onSubmit: onSubmit,
                  );
                  onResult?.call(added);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    String fieldText(WidgetTester tester, String key) => tester
        .widget<EditableText>(
          find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(EditableText),
          ),
        )
        .controller
        .text;

    testWidgets('prefills topic and English from the moderator side; Arabic '
        'empty and RTL; category Other', (tester) async {
      await openDialog(tester, (_) async {});
      expect(find.text('Add to approved facts'), findsOneWidget);
      expect(
        find.text('From now on the AI may say this without a warning.'),
        findsOneWidget,
      );
      expect(fieldText(tester, 'chat-add-fact-topic'), 'Our jars are sugar free');
      expect(fieldText(tester, 'chat-add-fact-en'), 'Our jars are sugar free');
      expect(fieldText(tester, 'chat-add-fact-ar'), '');
      final arabic = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('chat-add-fact-ar')),
          matching: find.byType(EditableText),
        ),
      );
      expect(arabic.textDirection, TextDirection.rtl);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('chat-add-fact-category')),
          matching: find.text('Other'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('validates topic and at least one fact', (tester) async {
      var calls = 0;
      await openDialog(tester, (_) async => calls++);
      await tester.enterText(
        find.byKey(const ValueKey('chat-add-fact-topic')),
        '  ',
      );
      await tester.enterText(find.byKey(const ValueKey('chat-add-fact-en')), '');
      await tester.tap(find.byKey(const ValueKey('chat-add-fact-submit')));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('Enter a topic'), findsOneWidget);
      expect(find.text('Write the fact in English or Arabic'), findsNWidgets(2));

      // Arabic alone is enough.
      await tester.enterText(
        find.byKey(const ValueKey('chat-add-fact-topic')),
        'Sugar',
      );
      await tester.enterText(
        find.byKey(const ValueKey('chat-add-fact-ar')),
        'البرطمانات من غير سكر',
      );
      await tester.tap(find.byKey(const ValueKey('chat-add-fact-submit')));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.byKey(const ValueKey('chat-add-fact-dialog')), findsNothing);
    });

    testWidgets('a failure keeps the dialog open with the message', (
      tester,
    ) async {
      bool? result;
      await openDialog(
        tester,
        (_) async => throw Exception('Only managers can approve facts'),
        onResult: (v) => result = v,
      );
      await tester.tap(find.byKey(const ValueKey('chat-add-fact-submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-add-fact-dialog')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-add-fact-error')), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('chat-add-fact-cancel')));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });

  group('thread', () {
    Map<String, dynamic> conversation({
      required bool canApprove,
      List<int>? approved,
    }) => {
      'message': {
        'conversation': {
          'name': 'CHAT-1',
          'channel': 'WhatsApp',
          'contact_name': 'Mona Salem',
          'status': 'Open',
          'last_message_at': '2026-11-16 11:00:00',
          'last_direction': 'Inbound',
          'has_pending_draft': 1,
          'can_approve_facts': canApprove,
        },
        'messages': [
          {
            'name': 'M-1',
            'direction': 'Inbound',
            'message_type': 'text',
            'body': 'Are the jars sugar free?',
            'timestamp': '2026-11-16 11:00:00',
          },
        ],
        'draft': {
          'name': 'D-9',
          'status': 'Pending',
          'draft_text': 'Yes, our jars are sugar free.',
          'fact_conflicts': [_lineA],
          if (approved != null) 'approved_conflicts': approved,
        },
        'customer': null,
      },
    };

    Widget threadApp(MockDio dio) => ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(ChatRepository(dio)),
        userRolesFutureProvider.overrideWith(
          (ref) async => UserRoles(
            user: 'boss@jarz.test',
            fullName: 'Boss',
            roles: const ['Moderator', 'POS Manager'],
            requirePosShift: false,
            canAccessB2b: false,
            isB2bSalesRep: false,
          ),
        ),
        webSocketServiceProvider.overrideWithValue(MockWebSocketService()),
        chatClockProvider.overrideWithValue(() => _now),
        chatUnreadTotalProvider.overrideWith(
          (ref) async => const ChatUnreadTotal(openCount: 0, unreadTotal: 0),
        ),
      ],
      child: _plain(const ChatThreadScreen(conversation: 'CHAT-1')),
    );

    void bigScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('a moderator without can_approve_facts sees no action', (
      tester,
    ) async {
      bigScreen(tester);
      final dio = MockDio()
        ..setResponse(
          ApiEndpoints.chatGetConversation,
          conversation(canApprove: false),
        );
      await tester.pumpWidget(threadApp(dio));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chat-draft-fact-conflicts')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('chat-fact-add-0')), findsNothing);
    });

    testWidgets('a manager adds the line from the draft alert', (tester) async {
      bigScreen(tester);
      final dio = MockDio()
        ..setResponse(
          ApiEndpoints.chatGetConversation,
          conversation(canApprove: true),
        )
        ..setResponse(ChatRepository.approveFactConflictPath, {
          'message': {
            'fact': 'FACT-1',
            'draft': 'D-9',
            'approved_conflicts': [0],
          },
        });
      await tester.pumpWidget(threadApp(dio));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('chat-fact-add-0')));
      await tester.tap(find.byKey(const ValueKey('chat-fact-add-0')));
      await tester.pumpAndSettle();
      expect(find.text('Add to approved facts'), findsOneWidget);

      // The server now serves the draft with the line approved.
      dio.setResponse(
        ApiEndpoints.chatGetConversation,
        conversation(canApprove: true, approved: [0]),
      );
      dio.clearLog();
      await tester.tap(find.byKey(const ValueKey('chat-add-fact-submit')));
      await tester.pumpAndSettle();

      final call = dio.requestLog.firstWhere(
        (r) => r['path'] == ChatRepository.approveFactConflictPath,
      );
      expect(call['data'], {
        'draft': 'D-9',
        'index': 0,
        'topic': 'Our jars are sugar free',
        'fact_en': 'Our jars are sugar free',
        'fact_ar': '',
        'category': 'Other',
      });
      // The thread re-read itself after the approval.
      expect(
        dio.requestLog.where(
          (r) => r['path'] == ApiEndpoints.chatGetConversation,
        ),
        isNotEmpty,
      );
      expect(find.byKey(const ValueKey('chat-fact-added-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-fact-add-0')), findsNothing);
      expect(find.text('Added to approved facts'), findsOneWidget);
    });
  });

  group('overrides screen', () {
    testWidgets('no action when the server does not allow approving', (
      tester,
    ) async {
      final dio = MockDio()
        ..setResponse(ApiEndpoints.chatGetFactOverrides, {
          'message': {
            'rows': [
              _row('D-1', approved: [1]),
            ],
            'has_more': false,
            'total': 1,
          },
        });
      await tester.pumpWidget(_overridesApp(dio));
      await tester.pumpAndSettle();
      expect(find.text('Add to facts'), findsNothing);
      // The tick still tells everyone the line is now an approved fact.
      expect(
        find.byKey(const ValueKey('chat-fact-added-D-1-1')),
        findsOneWidget,
      );
    });

    testWidgets('a manager adds a line: request sent, tick shown, snack', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dio = MockDio()
        ..setResponse(ApiEndpoints.chatGetFactOverrides, {
          'message': {
            'rows': [_row('D-1')],
            'has_more': false,
            'total': 1,
            'can_approve_facts': true,
          },
        })
        ..setResponse(ChatRepository.approveFactConflictPath, {
          'message': {
            'fact': 'FACT-1',
            'draft': 'D-1',
            'approved_conflicts': [0],
          },
        });
      await tester.pumpWidget(_overridesApp(dio));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('chat-fact-add-D-1-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-fact-add-D-1-1')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('chat-fact-add-D-1-0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-add-fact-dialog')), findsOneWidget);

      // Pick a category.
      await tester.tap(find.byKey(const ValueKey('chat-add-fact-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ingredients and claims').last);
      await tester.pumpAndSettle();

      dio.clearLog();
      await tester.tap(find.byKey(const ValueKey('chat-add-fact-submit')));
      await tester.pumpAndSettle();

      final call = dio.requestLog.single;
      expect(call['path'], ChatRepository.approveFactConflictPath);
      expect(call['data'], {
        'draft': 'D-1',
        'index': 0,
        'topic': 'Our jars are sugar free',
        'fact_en': 'Our jars are sugar free',
        'fact_ar': '',
        'category': 'Ingredients and claims',
      });
      expect(find.byKey(const ValueKey('chat-add-fact-dialog')), findsNothing);
      expect(
        find.byKey(const ValueKey('chat-fact-added-D-1-0')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('chat-fact-add-D-1-0')), findsNothing);
      expect(find.byKey(const ValueKey('chat-fact-add-D-1-1')), findsOneWidget);
      expect(find.text('Added to approved facts'), findsOneWidget);
    });

    testWidgets('a refusal (403) leaves the line as it was', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dio = MockDio()
        ..setResponse(ApiEndpoints.chatGetFactOverrides, {
          'message': {
            'rows': [_row('D-1')],
            'has_more': false,
            'total': 1,
            'can_approve_facts': 1,
          },
        })
        ..setError(
          ChatRepository.approveFactConflictPath,
          DioException(
            requestOptions: RequestOptions(
              path: ChatRepository.approveFactConflictPath,
            ),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(
                path: ChatRepository.approveFactConflictPath,
              ),
              statusCode: 403,
              data: {'exc_type': 'PermissionError'},
            ),
          ),
        );
      await tester.pumpWidget(_overridesApp(dio));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chat-fact-add-D-1-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chat-add-fact-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('chat-add-fact-error')), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('chat-add-fact-cancel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-fact-added-D-1-0')), findsNothing);
      expect(find.byKey(const ValueKey('chat-fact-add-D-1-0')), findsOneWidget);
    });
  });
}
