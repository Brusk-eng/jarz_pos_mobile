import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';
import '../inbox/ui_test_helpers.dart';

Finder keepBtn(String id) => find.descendant(
  of: find.byKey(ValueKey('idea-$id')),
  matching: find.byKey(const ValueKey('idea-keep')),
);
Finder dropBtn(String id) => find.descendant(
  of: find.byKey(ValueKey('idea-$id')),
  matching: find.byKey(const ValueKey('idea-drop')),
);

Future<void> openIdeas(WidgetTester tester, dynamic container) =>
    goTo(tester, container, '/inbox/ideas');

void main() {
  group('Ideas list', () {
    testWidgets('cards show hook, format, flavour, who it is for and source', (
      tester,
    ) async {
      usePhone(tester, height: 1600);
      final c = await pumpStudioWith(tester, fakeApi());
      await openIdeas(tester, c);
      expect(find.text('A jar for the late shift'), findsOneWidget);
      expect(
        find.textContaining('11 pm, the laptop is still open'),
        findsOneWidget,
      );
      expect(find.text('Reel'), findsWidgets);
      expect(find.text('Tiramisu'), findsWidgets);
      expect(find.textContaining('from Claude'), findsWidgets);
      expect(find.textContaining('For: One jar for me'), findsWidgets);
    });

    testWidgets('empty state says what to do first and offers New idea', (
      tester,
    ) async {
      usePhone(tester, height: 900);
      final c = await pumpStudioWith(
        tester,
        fakeApi(edits: {'ideas.list': (j) => j['items'] = []}),
      );
      await openIdeas(tester, c);
      expect(find.byKey(const ValueKey('empty-purpose')), findsOneWidget);
      expect(find.textContaining('bring one'), findsOneWidget);
    });

    testWidgets('error state offers retry', (tester) async {
      usePhone(tester, height: 900);
      final api = fakeApi()..failNext('ideas.list', 'SERVER_ERROR');
      final c = await pumpStudioWith(tester, api);
      await openIdeas(tester, c);
      expect(find.byKey(const ValueKey('error-text')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ideas-list')), findsOneWidget);
    });

    testWidgets('keep and drop show only when listed in actions', (
      tester,
    ) async {
      usePhone(tester, height: 1600);
      final api = fakeApi(
        role: 'founder',
        edits: {
          'ideas.list': (j) {
            j['items'][0]['actions'] = ['edit'];
            j['items'][1]['actions'] = ['keep'];
          },
        },
      );
      final c = await pumpStudioWith(tester, api);
      await openIdeas(tester, c);
      expect(keepBtn('IDEA-00012'), findsNothing);
      expect(dropBtn('IDEA-00012'), findsNothing);
      expect(find.textContaining('Waiting for the founder'), findsOneWidget);
      expect(keepBtn('IDEA-00013'), findsOneWidget);
      expect(dropBtn('IDEA-00013'), findsNothing);
    });
  });

  group('Keep and drop', () {
    testWidgets('keep becomes a piece and offers Open the piece', (
      tester,
    ) async {
      usePhone(tester, height: 1600);
      final api = fakeApi();
      final c = await pumpStudioWith(tester, api);
      await openIdeas(tester, c);
      await tester.tap(keepBtn('IDEA-00012'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('keep-confirm')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('ideas.keep'));
      expect(find.textContaining('Kept. It is a piece now.'), findsWidgets);
      await tester.tap(find.text('Open the piece').first);
      await tester.pumpAndSettle();
      expect(topLocation(c), startsWith('/pieces/'));
    });

    testWidgets('a kept idea shows what happened and links to its piece', (
      tester,
    ) async {
      usePhone(tester, height: 1600);
      final api = fakeApi(
        edits: {
          'ideas.list': (j) {
            j['items'][0]['status'] = 'Kept';
            j['items'][0]['kept_piece_id'] = 'PC-00200';
            j['items'][0]['actions'] = ['edit'];
          },
        },
      );
      final c = await pumpStudioWith(tester, api);
      await openIdeas(tester, c);
      await tester.tap(find.text('Kept').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('idea-open-piece')));
      await tester.pumpAndSettle();
      expect(topLocation(c), '/pieces/PC-00200');
    });

    testWidgets('a failed keep rolls back and says why (SHADOW_MODE)', (
      tester,
    ) async {
      usePhone(tester, height: 1600);
      final api = fakeApi()..failNext('ideas.keep', 'SHADOW_MODE');
      final c = await pumpStudioWith(tester, api);
      await openIdeas(tester, c);
      await tester.tap(keepBtn('IDEA-00012'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('keep-confirm')));
      await tester.pumpAndSettle();
      expect(find.textContaining('not switched on yet'), findsOneWidget);
      expect(keepBtn('IDEA-00012'), findsOneWidget);
    });

    testWidgets('keep ALREADY_DONE is not an error', (tester) async {
      usePhone(tester, height: 1600);
      final api = fakeApi()..failNext('ideas.keep', 'ALREADY_DONE');
      final c = await pumpStudioWith(tester, api);
      await openIdeas(tester, c);
      await tester.tap(keepBtn('IDEA-00012'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('keep-confirm')));
      await tester.pumpAndSettle();
      expect(find.textContaining('went wrong'), findsNothing);
      expect(find.textContaining('Your role cannot do that'), findsNothing);
    });

    testWidgets('keep NOT_PERMITTED is shown in plain words', (tester) async {
      usePhone(tester, height: 1600);
      final api = fakeApi()..failNext('ideas.keep', 'NOT_PERMITTED');
      final c = await pumpStudioWith(tester, api);
      await openIdeas(tester, c);
      await tester.tap(keepBtn('IDEA-00012'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('keep-confirm')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Your role cannot do that'), findsOneWidget);
    });

    testWidgets('drop needs a reason, then drops', (tester) async {
      usePhone(tester, height: 1600);
      final api = fakeApi();
      final c = await pumpStudioWith(tester, api);
      await openIdeas(tester, c);
      await tester.tap(dropBtn('IDEA-00012'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('drop-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Write a short reason.'), findsOneWidget);
      expect(api.calls, isNot(contains('ideas.drop')));
      await tester.enterText(
        find.byKey(const ValueKey('drop-reason')),
        'We shot this last month',
      );
      await tester.tap(find.byKey(const ValueKey('drop-confirm')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('ideas.drop'));
      expect(find.text('Dropped.'), findsOneWidget);
    });

    testWidgets('a failed drop brings the idea back', (tester) async {
      usePhone(tester, height: 1600);
      final api = fakeApi()..failNext('ideas.drop', 'SERVER_ERROR');
      final c = await pumpStudioWith(tester, api);
      await openIdeas(tester, c);
      await tester.tap(dropBtn('IDEA-00012'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('drop-reason')), 'No');
      await tester.tap(find.byKey(const ValueKey('drop-confirm')));
      await tester.pumpAndSettle();
      expect(find.textContaining('went wrong on our side'), findsOneWidget);
      expect(dropBtn('IDEA-00012'), findsOneWidget);
    });
  });

  group('Bring and edit an idea', () {
    testWidgets('anyone can propose; a title is required', (tester) async {
      usePhone(tester, height: 1600);
      final api = fakeApi(role: 'creator');
      final c = await pumpStudioWith(tester, api);
      await openIdeas(tester, c);
      await tester.tap(find.byKey(const ValueKey('idea-new')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('idea-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Add a title first.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('idea-title')),
        'Friday jar',
      );
      await tester.enterText(
        find.byKey(const ValueKey('idea-hook')),
        'The jar opens on the lid click',
      );
      await tester.tap(find.byKey(const ValueKey('format-reel')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('idea-submit')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('ideas.propose'));
      expect(find.text('Idea sent. The founder will see it.'), findsOneWidget);
    });

    testWidgets('a rejected proposal says why and keeps the form', (
      tester,
    ) async {
      usePhone(tester, height: 1600);
      final api = fakeApi(role: 'creator')
        ..failNext(
          'ideas.propose',
          'VALIDATION',
          message: 'The title is too long.',
        );
      final c = await pumpStudioWith(tester, api);
      await openIdeas(tester, c);
      await tester.tap(find.byKey(const ValueKey('idea-new')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('idea-title')), 'x');
      await tester.tap(find.byKey(const ValueKey('idea-submit')));
      await tester.pumpAndSettle();
      expect(find.text('The title is too long.'), findsOneWidget);
      expect(find.byKey(const ValueKey('idea-title')), findsOneWidget);
    });

    testWidgets('edit saves', (tester) async {
      usePhone(tester, height: 1600);
      final api = fakeApi();
      final c = await pumpStudioWith(tester, api);
      await openIdeas(tester, c);
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('idea-IDEA-00012')),
          matching: find.byKey(const ValueKey('idea-edit')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('idea-submit')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('ideas.update'));
      expect(find.text('Idea saved.'), findsOneWidget);
    });

    testWidgets('edit STALE reloads the list and says so', (tester) async {
      usePhone(tester, height: 1600);
      final api = fakeApi()..failNext('ideas.update', 'STALE');
      final c = await pumpStudioWith(tester, api);
      await openIdeas(tester, c);
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('idea-IDEA-00012')),
          matching: find.byKey(const ValueKey('idea-edit')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('idea-submit')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('This changed since you opened it'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('idea-title')), findsNothing);
    });

    testWidgets('Arabic ideas screen runs right to left', (tester) async {
      usePhone(tester, height: 1600);
      final c = await pumpStudioWith(tester, fakeApi(), locale: 'ar');
      await openIdeas(tester, c);
      expect(find.text('احتفظ'), findsWidgets);
      expect(find.text('فكرة جديدة'), findsWidgets);
      expect(
        Directionality.of(
          tester.element(find.byKey(const ValueKey('idea-new'))),
        ),
        TextDirection.rtl,
      );
    });
  });
}
