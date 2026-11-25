import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/features/inbox/state/inbox_state.dart';
import 'package:jarz_pos/src/studio/features/notifications/data/notifications_repository.dart';

import '../helpers.dart';
import '../inbox/ui_test_helpers.dart';

void main() {
  group('Notifications list', () {
    testWidgets('shows every row, unread ones marked', (tester) async {
      usePhone(tester, height: 1200);
      await pumpMini(tester, fakeApi(), location: '/inbox/notifications');
      expect(find.text('Ready for your approval'), findsOneWidget);
      expect(find.text('A decision is waiting'), findsOneWidget);
      expect(find.text('A post did not go out'), findsOneWidget);
      expect(find.byKey(const ValueKey('unread-dot')), findsNWidgets(2));
    });

    testWidgets('a row marks itself read and opens its route', (tester) async {
      usePhone(tester, height: 1200);
      final api = fakeApi();
      final visited = <String>[];
      await pumpMini(
        tester,
        api,
        location: '/inbox/notifications',
        visited: visited,
      );
      await tester.tap(find.byKey(const ValueKey('notification-nl0000001')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('notifications.mark_read'));
      expect(visited, contains('/inbox/approve/PC-00188-v1'));
    });

    testWidgets('a read row opens its route without another mark-read call', (
      tester,
    ) async {
      usePhone(tester, height: 1200);
      final api = fakeApi();
      final visited = <String>[];
      await pumpMini(
        tester,
        api,
        location: '/inbox/notifications',
        visited: visited,
      );
      await tester.tap(find.byKey(const ValueKey('notification-nl0000003')));
      await tester.pumpAndSettle();
      expect(api.calls, isNot(contains('notifications.mark_read')));
      expect(visited, contains('/calendar/post/SP-2026-00175'));
    });

    testWidgets('mark all read clears every dot', (tester) async {
      usePhone(tester, height: 1200);
      final api = fakeApi();
      await pumpMini(tester, api, location: '/inbox/notifications');
      await tester.tap(find.byKey(const ValueKey('mark-all-read')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('notifications.mark_read'));
      expect(find.byKey(const ValueKey('unread-dot')), findsNothing);
      expect(find.byKey(const ValueKey('mark-all-read')), findsNothing);
    });

    testWidgets('a failed mark all read keeps the dots and says why', (
      tester,
    ) async {
      usePhone(tester, height: 1200);
      final api = fakeApi()..failNext('notifications.mark_read', 'SHADOW_MODE');
      await pumpMini(tester, api, location: '/inbox/notifications');
      await tester.tap(find.byKey(const ValueKey('mark-all-read')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('unread-dot')), findsNWidgets(2));
      expect(find.textContaining('not switched on yet'), findsOneWidget);
    });

    testWidgets('empty state says when notifications arrive', (tester) async {
      usePhone(tester, height: 900);
      await pumpMini(
        tester,
        fakeApi(edits: {'notifications.list': (j) => j['items'] = []}),
        location: '/inbox/notifications',
      );
      expect(find.byKey(const ValueKey('empty-purpose')), findsOneWidget);
      expect(find.textContaining('sent back'), findsOneWidget);
    });

    testWidgets('error state offers retry', (tester) async {
      usePhone(tester, height: 900);
      final api = fakeApi()..failNext('notifications.list', 'SERVER_ERROR');
      await pumpMini(tester, api, location: '/inbox/notifications');
      expect(find.byKey(const ValueKey('error-text')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('notifications-list')), findsOneWidget);
    });

    testWidgets('the unread badge provider reads unread_count', (tester) async {
      usePhone(tester, height: 900);
      final c = await pumpStudioWith(tester, fakeApi());
      final sub = c.listen(unreadCountProvider, (_, _) {});
      addTearDown(sub.close);
      await tester.pumpAndSettle();
      expect(c.read(unreadBadgeProvider), greaterThan(0));
    });

    testWidgets('Arabic list runs right to left', (tester) async {
      usePhone(tester, height: 1200);
      await pumpMini(
        tester,
        fakeApi(),
        location: '/inbox/notifications',
        locale: 'ar',
      );
      expect(find.text('الإشعارات'), findsWidgets);
      expect(
        Directionality.of(
          tester.element(find.byKey(const ValueKey('notifications-list'))),
        ),
        TextDirection.rtl,
      );
    });
  });

  group('My notifications', () {
    testWidgets('shows quiet hours, digest and what you are told about', (
      tester,
    ) async {
      usePhone(tester, height: 1200);
      await pumpMini(
        tester,
        fakeApi(),
        location: '/inbox/notifications/settings',
      );
      expect(find.text('23:00'), findsOneWidget);
      expect(find.text('07:30'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('event-version_waiting')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('event-shoot_tomorrow')),
        findsOneWidget,
      );
    });

    testWidgets('the digest switch saves', (tester) async {
      usePhone(tester, height: 1200);
      final api = fakeApi();
      await pumpMini(tester, api, location: '/inbox/notifications/settings');
      await tester.tap(find.byKey(const ValueKey('digest-switch')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('settings.set_my_notifications'));
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('a quiet hour is picked with the time picker and saved', (
      tester,
    ) async {
      usePhone(tester, height: 1200);
      final api = fakeApi();
      await pumpMini(tester, api, location: '/inbox/notifications/settings');
      await tester.tap(find.byKey(const ValueKey('quiet-from')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(api.calls, contains('settings.set_my_notifications'));
    });

    testWidgets('a failed save rolls back and says why', (tester) async {
      usePhone(tester, height: 1200);
      final api = fakeApi()
        ..failNext(
          'settings.set_my_notifications',
          'VALIDATION',
          message: 'Pick a valid time.',
        );
      await pumpMini(tester, api, location: '/inbox/notifications/settings');
      await tester.tap(find.byKey(const ValueKey('digest-switch')));
      await tester.pumpAndSettle();
      expect(find.text('Pick a valid time.'), findsOneWidget);
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const ValueKey('digest-switch')))
            .value,
        isTrue,
      );
    });

    testWidgets('error state offers retry', (tester) async {
      usePhone(tester, height: 900);
      final api = fakeApi()
        ..failNext('settings.my_notifications', 'SERVER_ERROR');
      await pumpMini(tester, api, location: '/inbox/notifications/settings');
      expect(find.byKey(const ValueKey('error-text')), findsOneWidget);
    });
  });
}
