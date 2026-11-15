// Moderator overrides list: rows (who, when, chat, instruction, conflicts,
// status, collapsed text), the 30-day default range, pagination by
// start/limit, and tapping a row to open its chat.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/core/constants/api_endpoints.dart';
import 'package:jarz_pos/src/core/constants/app_routes.dart';
import 'package:jarz_pos/src/features/chat_inbox/data/chat_repository.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/screens/chat_fact_overrides_screen.dart';
import 'package:jarz_pos/src/features/chat_inbox/state/chat_providers.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

final _now = DateTime(2026, 11, 16, 12);

Map<String, dynamic> _row(
  String draft, {
  String status = 'Sent Edited',
  String? hint = 'tell her delivery is 1 hour and 150',
  List<String> conflicts = const [
    '1 hour delivery → we say 2-3 hours',
    '150 → Trio is 165',
  ],
  String conversation = 'CHAT-1',
}) => {
  'draft': draft,
  'conversation': conversation,
  'contact_name': 'Mona Salem',
  'channel': 'WhatsApp',
  'created_at': '2026-11-14 16:20:00',
  'requested_by': 'mona@jarz.test',
  'requested_by_name': 'Mona',
  'moderator_hint': hint,
  'conflicts': conflicts,
  'status': status,
  'final_text': 'Delivery in 1 hour, 150 EGP.',
  'draft_text': 'Delivery in 2-3 hours.',
};

Widget _app(MockDio dio, {GoRouter? router}) {
  final overrides = [
    chatRepositoryProvider.overrideWithValue(ChatRepository(dio)),
    chatClockProvider.overrideWithValue(() => _now),
  ];
  const delegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  if (router != null) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChatFactOverridesScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPlatformChannels();

  testWidgets('lists each override with who, when, instruction, conflicts and '
      'status', (tester) async {
    final dio = MockDio()
      ..setResponse(ApiEndpoints.chatGetFactOverrides, {
        'message': {
          'rows': [
            _row('D-2'),
            _row('D-1', status: 'Rejected', hint: 'say تسليم ساعة'),
          ],
          'has_more': false,
          'total': 2,
        },
      });
    await tester.pumpWidget(_app(dio));
    await tester.pumpAndSettle();

    // Default range: the last 30 days, sent as ISO dates.
    final call = dio.requestLog.first['queryParameters'] as Map;
    expect(call['from_date'], '2026-10-17');
    expect(call['to_date'], '2026-11-16');
    expect(call['limit'], 50);
    expect(call['start'], 0);
    expect(find.text('2026-10-17 → 2026-11-16 · 2'), findsOneWidget);

    expect(find.byKey(const ValueKey('chat-override-D-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-override-D-1')), findsOneWidget);
    expect(find.text('Mona · Nov 14 · 4:20 PM'), findsNWidgets(2));
    expect(find.text('Mona Salem · WhatsApp'), findsNWidgets(2));
    expect(find.text('tell her delivery is 1 hour and 150'), findsOneWidget);
    expect(find.text('1 hour delivery → we say 2-3 hours'), findsNWidgets(2));
    expect(find.text('150 → Trio is 165'), findsNWidgets(2));
    // Status chips.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('chat-override-status-D-2')),
        matching: find.text('Sent'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('chat-override-status-D-1')),
        matching: find.text('Rejected'),
      ),
      findsOneWidget,
    );
    // An Arabic-first instruction is laid out right-to-left.
    expect(
      tester.widget<Text>(find.text('say تسليم ساعة')).textDirection,
      TextDirection.rtl,
    );
  });

  testWidgets('the sent text is collapsed until expanded', (tester) async {
    final dio = MockDio()
      ..setResponse(ApiEndpoints.chatGetFactOverrides, {
        'message': {
          'rows': [_row('D-1')],
          'has_more': false,
          'total': 1,
        },
      });
    await tester.pumpWidget(_app(dio));
    await tester.pumpAndSettle();

    expect(find.text('Sent text'), findsOneWidget);
    expect(find.text('Delivery in 1 hour, 150 EGP.'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('chat-override-text-D-1')));
    await tester.pumpAndSettle();
    expect(find.text('Delivery in 1 hour, 150 EGP.'), findsOneWidget);
  });

  testWidgets('Load more continues from the rows already shown', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dio = MockDio()
      ..setResponse(ApiEndpoints.chatGetFactOverrides, {
        'message': {
          'rows': [_row('D-2')],
          'has_more': true,
          'total': 2,
        },
      });
    await tester.pumpWidget(_app(dio));
    await tester.pumpAndSettle();

    dio.setResponse(ApiEndpoints.chatGetFactOverrides, {
      'message': {
        'rows': [_row('D-1')],
        'has_more': false,
        'total': 2,
      },
    });
    dio.clearLog();
    await tester.tap(find.byKey(const ValueKey('chat-overrides-load-more')));
    await tester.pumpAndSettle();

    expect((dio.requestLog.single['queryParameters'] as Map)['start'], 1);
    expect(find.byKey(const ValueKey('chat-override-D-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-override-D-1')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chat-overrides-load-more')),
      findsNothing,
    );
  });

  testWidgets('pull to refresh re-reads the list', (tester) async {
    final dio = MockDio()
      ..setResponse(ApiEndpoints.chatGetFactOverrides, {
        'message': {
          'rows': [_row('D-1')],
          'has_more': false,
          'total': 1,
        },
      });
    await tester.pumpWidget(_app(dio));
    await tester.pumpAndSettle();
    dio.clearLog();
    await tester.fling(
      find.byKey(const ValueKey('chat-overrides-list')),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();
    expect(dio.requestLog, hasLength(1));
  });

  testWidgets('an empty period says so', (tester) async {
    final dio = MockDio()
      ..setResponse(ApiEndpoints.chatGetFactOverrides, {
        'message': {'rows': <dynamic>[], 'has_more': false, 'total': 0},
      });
    await tester.pumpWidget(_app(dio));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-overrides-empty')), findsOneWidget);
  });

  testWidgets('tapping a row opens its chat', (tester) async {
    final dio = MockDio()
      ..setResponse(ApiEndpoints.chatGetFactOverrides, {
        'message': {
          'rows': [_row('D-1', conversation: 'CHAT-77')],
          'has_more': false,
          'total': 1,
        },
      });
    final router = GoRouter(
      initialLocation: AppRoutes.chatsFactOverrides,
      routes: [
        GoRoute(
          path: AppRoutes.chatsFactOverrides,
          builder: (_, _) => const ChatFactOverridesScreen(),
        ),
        GoRoute(
          path: '/chats/:name',
          builder: (_, state) =>
              Scaffold(body: Text('thread ${state.pathParameters['name']}')),
        ),
      ],
    );
    await tester.pumpWidget(_app(dio, router: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('chat-override-open-D-1')));
    await tester.pumpAndSettle();
    expect(find.text('thread CHAT-77'), findsOneWidget);
  });
}
