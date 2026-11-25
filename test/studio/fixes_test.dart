import 'package:jarz_pos/src/studio/core/offline/kv_store.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/config/studio_config.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_strings.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/core/router/studio_router.dart';
import 'package:jarz_pos/src/studio/core/theme/studio_theme.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';
import 'package:jarz_pos/src/studio/features/pieces/presentation/piece_edit_screen.dart';
import 'package:jarz_pos/src/studio/shared/media/studio_media_viewer.dart';
import 'package:jarz_pos/src/studio/studio_app.dart';

import 'helpers.dart';
import 'inbox/ui_test_helpers.dart';

/// A fake API whose calls to [hang] never answer: the screen is opened "before
/// its data has arrived" and stays there.
class _HangingApi extends FakeStudioApi {
  _HangingApi({required this.hang}) : super(delay: Duration.zero);

  final Set<String> hang;

  @override
  Future<dynamic> call(
    String method, {
    Map<String, dynamic>? params,
    bool get = false,
  }) {
    final key = method.startsWith(studioMethodPrefix)
        ? method.substring(studioMethodPrefix.length)
        : method;
    if (hang.contains(key)) return Completer<dynamic>().future;
    return super.call(method, params: params, get: get);
  }
}

Future<void> _mount(WidgetTester tester, FakeStudioApi api, Widget home) async {
  usePhone(tester, height: 1600);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studioFakeProvider.overrideWithValue(true),
        studioApiProvider.overrideWithValue(api),
        studioKvStoreProvider.overrideWithValue(MemoryKvStore()),
        studioFakeRoleProvider.overrideWithValue(api.role),
      ],
      child: MaterialApp(
        theme: buildStudioTheme(locale: const Locale('en')),
        locale: const Locale('en'),
        supportedLocales: StudioStrings.supportedLocales,
        localizationsDelegates: const [
          StudioStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('edit screens before their data has arrived', () {
    testWidgets('piece edit shows the loading state, not a blank page', (
      tester,
    ) async {
      await _mount(
        tester,
        _HangingApi(hang: {'pieces.get'}),
        const PieceEditScreen(pieceId: 'PC-00163'),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('skeleton')), findsOneWidget);
      expect(find.byKey(const ValueKey('edit-form')), findsNothing);
    });

    testWidgets('piece edit shows an error with a retry, then the form', (
      tester,
    ) async {
      final api = FakeStudioApi(delay: Duration.zero)
        ..failNext('pieces.get', 'SERVER_ERROR');
      await _mount(tester, api, const PieceEditScreen(pieceId: 'PC-00163'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('error-text')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('edit-form')), findsOneWidget);
    });

    testWidgets('piece edit opens once the piece is there', (tester) async {
      await _mount(
        tester,
        FakeStudioApi(delay: Duration.zero),
        const PieceEditScreen(pieceId: 'PC-00163'),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('edit-form')), findsOneWidget);
      expect(find.byKey(const ValueKey('edit-title')), findsOneWidget);
    });

    testWidgets('asset edit shows a loader while the file loads', (
      tester,
    ) async {
      usePhone(tester, height: 1600);
      final c = await pumpStudioWith(tester, _HangingApi(hang: {'assets.get'}));
      c.read(studioRouterProvider).go('/assets/AST-0000316/edit');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('asset edit says so when the file does not load', (
      tester,
    ) async {
      final api = FakeStudioApi(delay: Duration.zero)
        ..failAlways('assets.get', 'SERVER_ERROR');
      usePhone(tester, height: 1600);
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/assets/AST-0000316/edit');
      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const ValueKey('edit-title')), findsNothing);
    });
  });

  group('Today', () {
    testWidgets('a code the app does not know is never a button', (
      tester,
    ) async {
      usePhone(tester, height: 2400);
      final api = fakeApi(
        edits: {
          'today.get': (j) {
            final line = j['blocks'][0]['lines'][0] as Map;
            line['actions'] = ['approve', 'rename_the_moon', 'rate', 'open'];
          },
        },
      );
      await pumpStudioWith(tester, api);
      expect(find.text('rename_the_moon'), findsNothing);
      expect(find.text('rate'), findsNothing);
      expect(find.text('clear_review'), findsNothing);
      expect(find.text('Approve'), findsWidgets);
    });

    testWidgets('block titles come from the strings, in Arabic too', (
      tester,
    ) async {
      usePhone(tester, height: 2400);
      final api = fakeApi(role: 'lead');
      await pumpStudioWith(tester, api, locale: 'ar');
      expect(find.text('واقف'), findsOneWidget); // blocked
      expect(find.text("Didn't go out"), findsNothing);
      expect(find.text('ما نزلش'), findsWidgets);
      expect(find.textContaining('Blocked: who is waiting'), findsNothing);
    });

    testWidgets('an empty block says so in one line', (tester) async {
      usePhone(tester, height: 2400);
      final api = fakeApi(
        role: 'creator',
        edits: {
          'today.get': (j) {
            (j['blocks'] as List).removeWhere((b) => b['key'] == 'sent_back');
          },
        },
      );
      await pumpStudioWith(tester, api);
      expect(
        find.byKey(const ValueKey('today-empty-sentBack')),
        findsOneWidget,
      );
      expect(find.text('Sent back to you: nothing.'), findsOneWidget);
    });

    testWidgets('Didn\'t go out links to the clearing screen', (tester) async {
      usePhone(tester, height: 3000);
      final api = fakeApi();
      await pumpStudioWith(tester, api);
      final link = find.byKey(const ValueKey('today-drift-didntGoOut'));
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('drift-body')), findsOneWidget);
    });

    testWidgets('the story lead\'s button says what it does', (tester) async {
      usePhone(tester, height: 2000);
      final api = fakeApi(role: 'story');
      await pumpStudioWith(tester, api);
      expect(find.text('Set the frame'), findsNothing);
      expect(find.text('Post the frames'), findsOneWidget);
    });
  });

  group('Ready to post: save the files, copy the caption', () {
    testWidgets(
      'files save one tap each, all at once, and the caption copies',
      (tester) async {
        usePhone(tester, height: 3200);
        final opened = <Uri>[];
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
        final files = [
          for (final m
              in (jsonDecode(studioFixtures['inbox.to_approve']!)
                      as Map)['items'][0]['version']['files']
                  as List)
            (m as Map)['media'],
        ];
        final api = fakeApi(
          edits: {
            'calendar.post_get': (j) {
              j['actions'] = ['edit', 'mark_posted', 'wont_post'];
              j['caption'] = 'جرّبي الـ Mango Cheesecake\n#Jarz';
              j['files'] = [
                files.first,
                {...files.first as Map, 'id': 'MED-000000999', 'kind': 'image'},
              ];
            },
          },
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              studioFakeProvider.overrideWithValue(true),
              studioApiProvider.overrideWithValue(api),
              studioFakeRoleProvider.overrideWithValue('founder'),
              studioLinkOpenerProvider.overrideWithValue((uri) async {
                opened.add(uri);
                return true;
              }),
            ],
            child: const StudioApp(),
          ),
        );
        await tester.pumpAndSettle();
        final c = ProviderScope.containerOf(
          tester.element(find.byType(StudioApp)),
        );
        await goTo(tester, c, '/calendar/post/SP-2026-00221');
        expect(find.byKey(const ValueKey('hand-post')), findsOneWidget);
        final one = find.byKey(const ValueKey('save-file-0'));
        await tester.ensureVisible(one);
        await tester.tap(one);
        await tester.pumpAndSettle();
        expect(
          api.calls.where((x) => x == 'media.download_link'),
          hasLength(1),
        );
        expect(opened, hasLength(1));
        final all = find.byKey(const ValueKey('save-all'));
        await tester.ensureVisible(all);
        await tester.tap(all);
        await tester.pumpAndSettle();
        expect(
          api.calls.where((x) => x == 'media.download_link'),
          hasLength(3),
        );
        final copy = find.byKey(const ValueKey('copy-caption'));
        await tester.ensureVisible(copy);
        await tester.tap(copy);
        await tester.pumpAndSettle();
        expect(copied, ['جرّبي الـ Mango Cheesecake\n#Jarz']);
        expect(find.text('Caption copied.'), findsOneWidget);
        // Then "I posted it" asks, with the link field.
        final posted = find.byKey(const ValueKey('mark-posted'));
        await tester.ensureVisible(posted);
        await tester.tap(posted);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('ask-text')), findsOneWidget);
        expect(find.textContaining('Did you post it?'), findsOneWidget);
      },
    );

    testWidgets('a post that is not for hand-posting has no such panel', (
      tester,
    ) async {
      usePhone(tester, height: 3200);
      final api = fakeApi(
        edits: {
          'calendar.post_get': (j) => j['actions'] = ['edit', 'move'],
        },
      );
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/calendar/post/SP-2026-00221');
      expect(find.byKey(const ValueKey('hand-post')), findsNothing);
    });
  });

  group('Paid: the state dialog', () {
    Future<void> openDialog(WidgetTester tester, FakeStudioApi api) async {
      usePhone(tester, height: 3000);
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/more/paid/rounds/R2b');
      final set = find.byKey(const ValueKey('set-state-AD-00013'));
      await tester.ensureVisible(set);
      await tester.tap(set);
      await tester.pumpAndSettle();
    }

    testWidgets('every state has one plain line and the rule is shown', (
      tester,
    ) async {
      await openDialog(tester, fakeApi());
      expect(find.textContaining('Still running its test'), findsOneWidget);
      expect(find.textContaining('one more test round'), findsOneWidget);
      expect(find.textContaining('Stopped.'), findsOneWidget);
      expect(find.textContaining('more budget, step by step'), findsOneWidget);
      expect(find.textContaining('Takes the state off'), findsOneWidget);
      // The server's own rule line for this ad, with its numbers.
      expect(find.textContaining('Winner when 7 purchases'), findsWidgets);
    });

    testWidgets('Winner at 6 purchases when the rule says 7 asks twice', (
      tester,
    ) async {
      final api = fakeApi();
      await openDialog(tester, api);
      await tester.tap(find.byKey(const ValueKey('state-Winner')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('does not meet the rule for Winner: the rule asks for 7 purchases and it has 6'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('state-save')));
      await tester.pumpAndSettle();
      expect(api.calls, isNot(contains('paid.ad_set_state')));
      expect(find.text('Set it anyway'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('state-save')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('paid.ad_set_state'));
      // The card now says what the toast says.
      expect(find.text('Now: Winner'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('state-AD-00013')),
          matching: find.text('Winner'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a state that agrees with the rule saves with one tap', (
      tester,
    ) async {
      final api = fakeApi();
      await openDialog(tester, api);
      await tester.tap(find.byKey(const ValueKey('state-One more round')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('state-warning')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('state-save')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('paid.ad_set_state'));
    });
  });

  group('the clearing screen for posts that did not go out', () {
    testWidgets('a missing post shows the buttons its own actions allow', (
      tester,
    ) async {
      usePhone(tester, height: 3000);
      final api = fakeApi(
        edits: {
          'calendar.post_get': (j) => j['actions'] = ['retry', 'wont_post'],
        },
      );
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/calendar/drift');
      expect(
        find.byKey(const ValueKey('drift-retry-SP-2026-00175')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('drift-wont-SP-2026-00175')),
        findsOneWidget,
      );
      // No move: the post's own actions do not list it.
      expect(
        find.byKey(const ValueKey('drift-move-SP-2026-00175')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('drift-retry-SP-2026-00175')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('calendar.post_retry'));
    });

    testWidgets('will not post asks for a reason', (tester) async {
      usePhone(tester, height: 3000);
      final api = fakeApi(
        edits: {
          'calendar.post_get': (j) => j['actions'] = ['retry', 'wont_post'],
        },
      );
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/calendar/drift');
      await tester.tap(find.byKey(const ValueKey('drift-wont-SP-2026-00175')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ask-confirm')));
      await tester.pumpAndSettle();
      expect(api.calls, isNot(contains('calendar.post_wont_post')));
      await tester.enterText(
        find.byKey(const ValueKey('ask-text')),
        'Kitchen was closed',
      );
      await tester.tap(find.byKey(const ValueKey('ask-confirm')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('calendar.post_wont_post'));
    });

    testWidgets('a live post nobody planned can be matched or ignored', (
      tester,
    ) async {
      usePhone(tester, height: 3000);
      final api = fakeApi(role: 'lead');
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/calendar/drift');
      const id = 'instagram:18012345678901234';
      final ignore = find.byKey(const ValueKey('drift-actual-ignore-$id'));
      await tester.ensureVisible(ignore);
      expect(
        find.byKey(const ValueKey('drift-actual-match-$id')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('drift-actual-match-$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('drift-match-SP-2026-00175')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('calendar.actual_match'));
      await tester.ensureVisible(ignore);
      await tester.tap(ignore);
      await tester.pumpAndSettle();
      expect(api.calls, contains('calendar.actual_ignore'));
    });

    testWidgets('a creator only reads it', (tester) async {
      usePhone(tester, height: 3000);
      final api = fakeApi(role: 'creator');
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/calendar/drift');
      expect(find.byKey(const ValueKey('drift-body')), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('drift-actual-match-instagram:18012345678901234'),
        ),
        findsNothing,
      );
    });
  });

  group('the 72-hour read from the post', () {
    testWidgets('a due read can be filed from the post screen', (tester) async {
      usePhone(tester, height: 3200);
      final api = fakeApi(
        edits: {
          'calendar.post_get': (j) {
            j['reads'] = [
              {
                'post_id': j['id'],
                'piece_id': 'PC-00163',
                'bucket': '72h',
                'opens_on': '2026-11-24',
                'due': true,
                'filed': false,
                'missing': ['views', 'reach'],
              },
            ];
          },
        },
      );
      final c = await pumpStudioWith(tester, api);
      await goTo(tester, c, '/calendar/post/SP-2026-00221');
      final file = find.byKey(const ValueKey('file-read-SP-2026-00221'));
      await tester.ensureVisible(file);
      expect(file, findsOneWidget);
    });
  });
}
