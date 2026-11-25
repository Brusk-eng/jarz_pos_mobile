import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';
import '../inbox/ui_test_helpers.dart';

void clearToday(dynamic json) => json['blocks'] = [];
void noTasks(dynamic json) => json['items'] = [];

void main() {
  group('Today states', () {
    testWidgets('shows a loading skeleton first', (tester) async {
      usePhone(tester);
      final api = fakeApi(delay: const Duration(milliseconds: 300));
      await pumpStudioWith(tester, api, settle: false);
      var seen = false;
      for (var i = 0; i < 30 && !seen; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        seen = find.byKey(const ValueKey('skeleton')).evaluate().isNotEmpty;
      }
      expect(seen, isTrue);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const ValueKey('today-list')), findsOneWidget);
    });

    testWidgets('error state with a retry that works', (tester) async {
      usePhone(tester);
      final api = fakeApi()..failNext('today.get', 'SERVER_ERROR');
      await pumpStudioWith(tester, api);
      expect(find.byKey(const ValueKey('error-text')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('today-list')), findsOneWidget);
    });

    for (final (role, hint) in [
      ('founder', 'Open Ideas'),
      ('lead', 'add a task'),
      ('creator', 'bring one idea'),
      ('story', 'Open Assets'),
    ]) {
      testWidgets('first day empty state says what to do first: $role', (
        tester,
      ) async {
        usePhone(tester);
        final api = fakeApi(
          role: role,
          edits: {'today.get': clearToday, 'today.tasks': noTasks},
        );
        await pumpStudioWith(tester, api);
        expect(find.byKey(const ValueKey('empty-purpose')), findsOneWidget);
        expect(find.textContaining(hint, findRichText: true), findsOneWidget);
      });
    }
  });

  group('Today lines', () {
    testWidgets('founder sees blocks in the server order', (tester) async {
      usePhone(tester, height: 1600);
      await pumpStudioWith(tester, fakeApi());
      final first = tester.getTopLeft(
        find.byKey(const ValueKey('today-block-toApprove')),
      );
      final second = tester.getTopLeft(
        find.byKey(const ValueKey('today-block-decisions')),
      );
      expect(first.dy, lessThan(second.dy));
    });

    testWidgets('a line opens its exact route', (tester) async {
      usePhone(tester, height: 1000);
      final c = await pumpStudioWith(tester, fakeApi(role: 'creator'));
      await tester.tap(find.byKey(const ValueKey('today-line-PC-00112')));
      await tester.pumpAndSettle();
      expect(topLocation(c), '/pieces/PC-00112');
    });

    testWidgets('a decision line opens the decision route', (tester) async {
      usePhone(tester, height: 1600);
      final c = await pumpStudioWith(tester, fakeApi());
      final line = find.byKey(const ValueKey('today-line-DEC-00007'));
      await reveal(tester, line);
      await tester.tap(line);
      await tester.pumpAndSettle();
      expect(topLocation(c), '/inbox/decisions/DEC-00007');
    });

    testWidgets('buttons come only from the line actions', (tester) async {
      usePhone(tester, height: 1600);
      await pumpStudioWith(tester, fakeApi());
      expect(
        find.byKey(const ValueKey('line-PC-00163-v2-approve')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('line-PC-00163-v2-fix')),
        findsOneWidget,
      );
      // The decision line lists only "open": no inline button at all.
      expect(find.byKey(const ValueKey('line-DEC-00007-open')), findsNothing);
      expect(
        find.byKey(const ValueKey('line-DEC-00007-approve')),
        findsNothing,
      );
    });

    testWidgets('approve inline says what happens next, then the line leaves '
        'on the next refresh', (tester) async {
      usePhone(tester, height: 1600);
      final api = fakeApi();
      await pumpStudioWith(tester, api);
      await tester.tap(find.byKey(const ValueKey('line-PC-00163-v2-approve')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('versions.approve'));
      // The row stays with a sentence: what happens next and who has it.
      final done = find.byKey(const ValueKey('line-PC-00163-v2-done'));
      expect(done, findsOneWidget);
      expect(
        (tester.widget<Text>(done).data ?? ''),
        anyOf(
          contains('posts by itself'),
          contains('Ready to post'),
          contains('picks its slot'),
        ),
      );
      expect(
        find.byKey(const ValueKey('line-PC-00163-v2-approve')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('today-refresh')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('today-line-PC-00163-v2')),
        findsNothing,
      );
    });

    testWidgets('approve that fails brings the line back with a plain error', (
      tester,
    ) async {
      usePhone(tester, height: 1600);
      final api = fakeApi()
        ..failNext(
          'versions.approve',
          'GATE_FAILED',
          problems: [
            {'code': 'needs_verdict', 'message': 'It needs a final verdict.'},
          ],
        );
      await pumpStudioWith(tester, api);
      await tester.tap(find.byKey(const ValueKey('line-PC-00163-v2-approve')));
      await tester.pumpAndSettle();
      expect(find.textContaining('It needs a final verdict.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('today-line-PC-00163-v2')),
        findsOneWidget,
      );
    });

    testWidgets('SHADOW_MODE says the Studio is not switched on', (
      tester,
    ) async {
      usePhone(tester, height: 1600);
      final api = fakeApi()..failNext('versions.approve', 'SHADOW_MODE');
      await pumpStudioWith(tester, api);
      await tester.tap(find.byKey(const ValueKey('line-PC-00163-v2-approve')));
      await tester.pumpAndSettle();
      expect(find.textContaining('not switched on yet'), findsOneWidget);
    });

    testWidgets('a button that is not an inline action opens the route', (
      tester,
    ) async {
      usePhone(tester, height: 2400);
      final c = await pumpStudioWith(tester, fakeApi());
      final b = find.byKey(const ValueKey('line-SP-2026-00221-mark_posted'));
      await reveal(tester, b);
      await tester.tap(b);
      await tester.pumpAndSettle();
      expect(topLocation(c), '/calendar/post/SP-2026-00221');
    });
  });

  group('Today tasks', () {
    testWidgets('creator ticks a task from a line: it says what is next, then '
        'leaves on the next refresh', (tester) async {
      usePhone(tester, height: 1000);
      final api = fakeApi(role: 'creator');
      await pumpStudioWith(tester, api);
      await tester.tap(find.byKey(const ValueKey('line-TASK-000191-tick')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('today.task_tick'));
      expect(
        find.byKey(const ValueKey('line-TASK-000191-done')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('today-refresh')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('today-line-TASK-000191')),
        findsNothing,
      );
    });

    testWidgets('a failed tick brings the line back (NOT_PERMITTED)', (
      tester,
    ) async {
      usePhone(tester, height: 1000);
      final api = fakeApi(role: 'creator')
        ..failNext('today.task_tick', 'NOT_PERMITTED');
      await pumpStudioWith(tester, api);
      await tester.tap(find.byKey(const ValueKey('line-TASK-000191-tick')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Your role cannot do that'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('today-line-TASK-000191')),
        findsOneWidget,
      );
    });

    testWidgets('ALREADY_DONE on a tick is shown plainly', (tester) async {
      usePhone(tester, height: 1000);
      final api = fakeApi(role: 'creator')
        ..failNext('today.task_tick', 'ALREADY_DONE');
      await pumpStudioWith(tester, api);
      await tester.tap(find.byKey(const ValueKey('line-TASK-000191-tick')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Already done'), findsOneWidget);
    });

    testWidgets('tick box on a task row ticks it', (tester) async {
      usePhone(tester, height: 1600);
      final api = fakeApi(role: 'lead');
      await pumpStudioWith(tester, api);
      final box = find.byKey(const ValueKey('task-tick-TASK-000201'));
      await reveal(tester, box);
      await tester.tap(box);
      await tester.pumpAndSettle();
      expect(api.calls, contains('today.task_tick'));
      expect(find.byKey(const ValueKey('task-TASK-000201')), findsNothing);
    });

    testWidgets('a failed task tick puts the row back', (tester) async {
      usePhone(tester, height: 1600);
      final api = fakeApi(role: 'lead')
        ..failNext('today.task_tick', 'SERVER_ERROR');
      await pumpStudioWith(tester, api);
      final box = find.byKey(const ValueKey('task-tick-TASK-000201'));
      await reveal(tester, box);
      await tester.tap(box);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('task-TASK-000201')), findsOneWidget);
      expect(find.textContaining('went wrong on our side'), findsOneWidget);
    });

    testWidgets('tick and skip appear only when listed in actions', (
      tester,
    ) async {
      usePhone(tester, height: 1600);
      final api = fakeApi(
        role: 'lead',
        edits: {
          'today.tasks': (j) {
            j['items'][0]['actions'] = ['tick'];
            j['items'][1]['actions'] = [];
          },
        },
      );
      await pumpStudioWith(tester, api);
      final tasks = find.byKey(const ValueKey('today-tasks'));
      await reveal(tester, tasks);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('task-tick-TASK-000201')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('task-skip-TASK-000201')), findsNothing);
      expect(find.byKey(const ValueKey('task-edit-TASK-000201')), findsNothing);
      expect(find.byKey(const ValueKey('task-tick-TASK-000203')), findsNothing);
    });

    testWidgets('skip calls the server', (tester) async {
      usePhone(tester, height: 1600);
      final api = fakeApi(role: 'lead');
      await pumpStudioWith(tester, api);
      final b = find.byKey(const ValueKey('task-skip-TASK-000201'));
      await reveal(tester, b);
      await tester.tap(b);
      await tester.pumpAndSettle();
      expect(api.calls, contains('today.task_tick'));
    });

    testWidgets('lead adds a task with a due date', (tester) async {
      usePhone(tester, height: 1600);
      final api = fakeApi(role: 'lead');
      await pumpStudioWith(tester, api);
      final add = find.byKey(const ValueKey('task-add'));
      await reveal(tester, add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      // Empty text is refused.
      await tester.tap(find.byKey(const ValueKey('task-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Write what needs doing.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('task-text')),
        'Confirm the jar count with Karim',
      );
      await tester.tap(find.byKey(const ValueKey('task-due')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('task-submit')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('today.task_create'));
      expect(find.text('Task added.'), findsOneWidget);
      expect(find.byKey(const ValueKey('task-text')), findsNothing);
    });

    testWidgets('a task that fails to save says why and keeps the form', (
      tester,
    ) async {
      usePhone(tester, height: 1600);
      final api = fakeApi(
        role: 'lead',
      )..failNext('today.task_create', 'VALIDATION', message: 'Pick a person.');
      await pumpStudioWith(tester, api);
      final add = find.byKey(const ValueKey('task-add'));
      await reveal(tester, add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('task-text')), 'x');
      await tester.tap(find.byKey(const ValueKey('task-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Pick a person.'), findsOneWidget);
      expect(find.byKey(const ValueKey('task-text')), findsOneWidget);
    });

    testWidgets('edit a task: STALE reloads and says so', (tester) async {
      usePhone(tester, height: 1600);
      final api = fakeApi(role: 'lead')..failNext('today.task_update', 'STALE');
      await pumpStudioWith(tester, api);
      final edit = find.byKey(const ValueKey('task-edit-TASK-000201'));
      await reveal(tester, edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('task-text')),
        'Changed text',
      );
      await tester.tap(find.byKey(const ValueKey('task-submit')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('This changed since you opened it'),
        findsOneWidget,
      );
    });

    testWidgets('edit a task saves', (tester) async {
      usePhone(tester, height: 1600);
      final api = fakeApi(role: 'lead');
      await pumpStudioWith(tester, api);
      final edit = find.byKey(const ValueKey('task-edit-TASK-000201'));
      await reveal(tester, edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('task-submit')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('today.task_update'));
    });

    testWidgets('creator has no add button; lead and founder do', (
      tester,
    ) async {
      for (final (role, shown) in [
        ('creator', false),
        ('story', false),
        ('lead', true),
        ('founder', true),
      ]) {
        usePhone(tester, height: 2400);
        await pumpStudioWith(tester, fakeApi(role: role));
        await reveal(tester, find.byKey(const ValueKey('today-tasks')));
        expect(
          find.byKey(const ValueKey('task-add')),
          shown ? findsOneWidget : findsNothing,
          reason: role,
        );
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('Arabic Today runs right to left', (tester) async {
      usePhone(tester, height: 1000);
      await pumpStudioWith(tester, fakeApi(role: 'creator'), locale: 'ar');
      expect(
        Directionality.of(
          tester.element(find.byKey(const ValueKey('today-list'))),
        ),
        TextDirection.rtl,
      );
      expect(find.text('النهارده'), findsWidgets);
    });
  });
}
