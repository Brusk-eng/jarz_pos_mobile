import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/features/references/presentation/references_screen.dart';
import 'package:jarz_pos/src/studio/features/session/data/me_profile_x.dart';
import 'package:jarz_pos/src/studio/shared/studio_error_text.dart';
import 'package:jarz_pos/src/studio/data/studio_error.dart';

import 'more/more_test_utils.dart';

void main() {
  group('capability helper (the one place for client-side role checks)', () {
    test(
      'who may add references, edit settings, add to the paid queue',
      () async {
        Future<MeProfileCaps> caps(String role) async {
          final me = await FakeStudioApi(
            role: role,
            delay: Duration.zero,
          ).sessionMe();
          return (
            refs: me.canAddReferences,
            settings: me.canEditSettings,
            queue: me.canAddToPaidQueue,
          );
        }

        expect(await caps('founder'), (
          refs: true,
          settings: true,
          queue: true,
        ));
        expect(await caps('lead'), (refs: true, settings: false, queue: false));
        expect(await caps('creator'), (
          refs: false,
          settings: false,
          queue: false,
        ));
      },
    );
  });

  group('add a reference', () {
    testWidgets('the founder adds one with a link, source and format', (
      tester,
    ) async {
      final api = RecordingApi();
      await pumpMore(
        tester,
        const ReferencesScreen(),
        api: api,
        size: const Size(400, 1000),
      );
      await tapKey(tester, 'refs-add');
      await typeKey(tester, 'ref-add-title', 'Crumbl weekly drop');
      await typeKey(tester, 'ref-add-url', 'https://example.test/ad/1');
      await typeKey(tester, 'ref-add-brand', 'Crumbl');
      await tapKey(tester, 'ref-add-src-meta_ad');
      await tapKey(tester, 'ref-add-media-reel');
      await tapKey(tester, 'ref-add-save');
      final p = api.last('references.create')!;
      expect(p['title'], 'Crumbl weekly drop');
      expect(p['url'], 'https://example.test/ad/1');
      expect(p['brand'], 'Crumbl');
      expect(p['media_type'], 'reel');
      expect(p['request_id'], isNotEmpty);
      expect(p.containsKey('image_media_id'), isFalse, reason: 'link only');
      expect(find.text('Reference added.'), findsOneWidget);
    });

    testWidgets('a title is needed and nothing is sent without it', (
      tester,
    ) async {
      final api = RecordingApi();
      await pumpMore(
        tester,
        const ReferencesScreen(),
        api: api,
        size: const Size(400, 1000),
      );
      await tapKey(tester, 'refs-add');
      await tapKey(tester, 'ref-add-save');
      expect(find.text('Give it a title.'), findsOneWidget);
      expect(api.count('references.create'), 0);
    });

    testWidgets('a server refusal is shown in plain words and the form stays', (
      tester,
    ) async {
      final api = RecordingApi()..failNext('references.create', 'SHADOW_MODE');
      await pumpMore(
        tester,
        const ReferencesScreen(),
        api: api,
        size: const Size(400, 1000),
      );
      await tapKey(tester, 'refs-add');
      await typeKey(tester, 'ref-add-title', 'x');
      await tapKey(tester, 'ref-add-save');
      expect(find.textContaining('not switched on yet'), findsOneWidget);
      expect(find.byKey(const ValueKey('ref-add-save')), findsOneWidget);
    });

    testWidgets('a creator has no add button', (tester) async {
      await pumpMore(
        tester,
        const ReferencesScreen(),
        api: RecordingApi(role: 'creator'),
      );
      expect(find.byKey(const ValueKey('refs-add')), findsNothing);
    });
  });

  group('one error text', () {
    test('every code has one plain sentence, in both languages', () {
      const errors = <StudioError>[
        StudioShadowMode('x'),
        StudioGateFailed('x', []),
        StudioStale('x', null),
        StudioNotPermitted('x'),
        StudioNotFound('x'),
        StudioAlreadyDone('x', null),
        StudioNetworkError('x'),
        StudioRateLimited('x'),
        StudioServerError('x'),
      ];
      final seen = <String>{};
      for (final e in errors) {
        final en = studioErrorMessage(e, ar: false);
        final ar = studioErrorMessage(e, ar: true);
        expect(en, isNotEmpty);
        expect(ar, isNot(en));
        seen.add(en);
      }
      expect(seen, hasLength(errors.length), reason: 'no two the same');
      expect(
        studioErrorMessage(const StudioAlreadyDone('x', null), ar: false),
        startsWith('This was already done'),
      );
    });
  });

  test('no person name is written into the UI text', () {
    final names = RegExp(
      r'\b(Ali|Abdelrahman|Kareem|Karim|Reem|Asmaa|Reham)\b|عبدالرحمن|عبد الرحمن|(?<![؀-ۿ])(علي|كريم|ريم|رهام|أسماء)(?![؀-ۿ])',
    );
    final hits = <String>[];
    for (final f in Directory('lib/src/studio').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final path = f.path.replaceAll(r'\', '/');
      if (path.contains('/data/')) continue; // fixtures and models
      if (path.contains('.freezed.') || path.contains('.g.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final l = lines[i].trimLeft();
        if (l.startsWith('//')) continue;
        if (names.hasMatch(l)) hits.add('$path:${i + 1}: $l');
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}

typedef MeProfileCaps = ({bool refs, bool settings, bool queue});
