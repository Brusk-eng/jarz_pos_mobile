import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/upload/picked_file.dart';
import 'package:jarz_pos/src/studio/data/studio_error.dart';
import 'package:jarz_pos/src/studio/core/upload/upload_engine.dart';
import 'package:jarz_pos/src/studio/core/upload/upload_job.dart';

import '../upload/upload_test_utils.dart';
import 'assets_test_utils.dart';

Finder key(String k) => find.byKey(ValueKey(k));

/// Every new file is tagged on the way in: a flavor (or "No flavor") and a
/// category are required, so the tests choose them like a person does.
Future<void> tagFile(WidgetTester tester) async {
  await tester.tap(key('add-flavour'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('No flavor (general)').last);
  await tester.pumpAndSettle();
  await tester.tap(key('add-category'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Kitchen').last);
  await tester.pumpAndSettle();
}

void main() {
  late AssetsHarness h;

  setUp(() => h = AssetsHarness());

  group('library', () {
    testWidgets('grid of tiles with the consent state of customer content', (
      tester,
    ) async {
      await pumpAssets(tester, h);
      expect(key('asset-AST-0000316'), findsOneWidget);
      expect(key('asset-AST-0000318'), findsOneWidget);
      expect(find.text('Given'), findsOneWidget);
      expect(key('add-asset'), findsOneWidget);
      expect(h.api.listCalls.single['kind'], isNull);
    });

    testWidgets('filters go to the server and reload from the first page', (
      tester,
    ) async {
      await pumpAssets(tester, h);
      await tester.tap(
        find.descendant(of: key('filter-kind'), matching: find.byType(Chip)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customer content').last);
      await tester.pumpAndSettle();
      expect(h.api.listCalls.last['kind'], 'Customer content');
      expect(key('asset-AST-0000318'), findsOneWidget);
      expect(key('asset-AST-0000316'), findsNothing);

      final consentChip = find.descendant(
        of: key('filter-consent'),
        matching: find.byType(Chip),
      );
      await tester.ensureVisible(consentChip);
      await tester.tap(consentChip);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Refused').last);
      await tester.pumpAndSettle();
      expect(h.api.listCalls.last['consent'], 'Refused');
      // Nothing matches: the empty state says so and offers to clear.
      expect(find.text('Nothing matches these filters.'), findsOneWidget);
      await tester.tap(find.text('Clear filters').last);
      await tester.pumpAndSettle();
      expect(h.api.listCalls.last['kind'], isNull);
      expect(key('asset-AST-0000316'), findsOneWidget);
    });

    testWidgets('text search', (tester) async {
      await pumpAssets(tester, h);
      await tester.enterText(key('library-search'), 'Kitchen');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(h.api.listCalls.last['q'], 'Kitchen');
      expect(key('asset-AST-0000317'), findsOneWidget);
      expect(key('asset-AST-0000316'), findsNothing);
    });

    testWidgets('cursor paging: show more adds the next page', (tester) async {
      h.api.pageSize = 2;
      await pumpAssets(tester, h);
      expect(key('asset-AST-0000318'), findsNothing);
      await tester.ensureVisible(key('load-more'));
      await tester.tap(key('load-more'));
      await tester.pumpAndSettle();
      expect(h.api.listCalls.last['after'], '2');
      expect(key('asset-AST-0000318'), findsOneWidget);
      expect(key('load-more'), findsNothing);
    });

    testWidgets('empty: says what to do first, with an add button', (
      tester,
    ) async {
      h.api.items = const [];
      await pumpAssets(tester, h);
      expect(key('empty-purpose'), findsOneWidget);
      expect(find.text('Add the first file from your phone.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Add files'), findsOneWidget);
    });

    testWidgets('error with try again; loading skeleton first', (tester) async {
      h.api.failNext('assets.list', 'SERVER_ERROR');
      await pumpAssets(tester, h, settle: false);
      await tester.pump();
      expect(key('skeleton'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(key('error-text'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(key('asset-AST-0000316'), findsOneWidget);
    });

    testWidgets('Arabic', (tester) async {
      await pumpAssets(tester, h, locale: 'ar');
      expect(find.text('ضيف ملفات'), findsOneWidget);
      expect(find.text('اتاخد'), findsOneWidget);
    });
  });

  group('asset page', () {
    testWidgets('customer content: consent record and buttons from actions', (
      tester,
    ) async {
      await pumpAssets(tester, h, location: '/assets/AST-0000318');
      expect(key('consent-card'), findsOneWidget);
      expect(find.text('Can be used in paid ads'), findsOneWidget);
      expect(key('action-consent'), findsOneWidget);
      expect(key('action-used'), findsOneWidget);
      expect(key('edit'), findsOneWidget);
      expect(key('rate-4'), findsOneWidget);
      expect(key('comment-field'), findsOneWidget);
    });

    testWidgets('no actions: no buttons at all', (tester) async {
      h.api.noActions = true;
      await pumpAssets(tester, h, location: '/assets/AST-0000318');
      expect(key('action-consent'), findsNothing);
      expect(key('action-used'), findsNothing);
      expect(key('edit'), findsNothing);
      expect(key('rate-4'), findsNothing);
      expect(key('comment-field'), findsNothing);
    });

    testWidgets('rate and comment', (tester) async {
      await pumpAssets(tester, h, location: '/assets/AST-0000318');
      await tester.ensureVisible(key('rate-4'));
      await tester.tap(key('rate-4'));
      await tester.pumpAndSettle();
      expect(h.api.rateCalls, [4]);
      await tester.ensureVisible(key('comment-field'));
      await tester.enterText(key('comment-field'), 'Nice light');
      await tester.tap(key('comment-send'));
      await tester.pumpAndSettle();
      expect(h.api.commentCalls, ['Nice light']);
      expect(find.text('Nice light'), findsOneWidget);
    });

    testWidgets('mark used', (tester) async {
      await pumpAssets(tester, h, location: '/assets/AST-0000318');
      await tester.ensureVisible(key('action-used'));
      await tester.tap(key('action-used'));
      await tester.pumpAndSettle();
      await tester.tap(key('used-Retired'));
      await tester.pumpAndSettle();
      await tester.tap(key('used-save'));
      await tester.pumpAndSettle();
      expect(h.api.usedCalls.single['status'], 'Retired');
    });

    testWidgets('a file that is gone says so; an error offers try again', (
      tester,
    ) async {
      h.api.failNext('assets.get', 'NOT_FOUND');
      await pumpAssets(tester, h, location: '/assets/AST-0000318');
      expect(
        find.text('This is no longer there. Go back and refresh.'),
        findsOneWidget,
      );
    });

    testWidgets('error state', (tester) async {
      h.api.failNext('assets.get', 'SERVER_ERROR');
      await pumpAssets(tester, h, location: '/assets/AST-0000318');
      expect(key('error-text'), findsOneWidget);
    });
  });

  group('consent', () {
    Future<void> openSheet(WidgetTester tester) async {
      await tester.ensureVisible(key('action-consent'));
      await tester.tap(key('action-consent'));
      await tester.pumpAndSettle();
    }

    testWidgets('Given needs who, date, scope and a screenshot', (
      tester,
    ) async {
      await pumpAssets(tester, h, location: '/assets/AST-0000318');
      await openSheet(tester);
      await tester.tap(key('consent-Given'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(key('consent-save'));
      // Fresh fields: the record on the fixture is cleared first.
      await tester.enterText(key('consent-who'), '');
      await tester.tap(key('consent-save'));
      await tester.pumpAndSettle();
      expect(find.text('Needed'), findsWidgets);
      expect(
        h.api.consentCalls,
        isEmpty,
        reason: 'nothing sent while incomplete',
      );
    });

    testWidgets('a server validation message shows at its field', (
      tester,
    ) async {
      await pumpAssets(tester, h, location: '/assets/AST-0000318');
      await openSheet(tester);
      // Existing record is complete, so the form goes to the server.
      h.api.consentError = const StudioValidation(
        'Name the person who agreed.',
        field: 'who',
      );
      await tester.ensureVisible(key('consent-save'));
      await tester.tap(key('consent-save'));
      await tester.pumpAndSettle();
      expect(find.text('Name the person who agreed.'), findsOneWidget);
    });

    testWidgets(
      'a complete record is saved, with the screenshot uploaded first',
      (tester) async {
        h.files.next = [
          MemoryPickedFile(
            name: 'chat.png',
            mime: 'image/png',
            bytes: bytesOf(500),
            modifiedMs: 3,
          ),
        ];
        await pumpAssets(tester, h, location: '/assets/AST-0000318');
        await openSheet(tester);
        await tester.ensureVisible(key('consent-proof'));
        await tester.tap(key('consent-proof'));
        await tester.pumpAndSettle();
        expect(find.text('Screenshot attached'), findsOneWidget);
        expect(h.s3.puts.length, 1);
        await tester.ensureVisible(key('consent-save'));
        await tester.tap(key('consent-save'));
        await tester.pumpAndSettle();
        expect(h.api.consentCalls.single['status'], 'Given');
        expect(h.api.consentCalls.single['proof_media_id'], startsWith('MED-'));
        expect(h.api.consentCalls.single['request_id'], isNotNull);
      },
    );
  });

  group('add files', () {
    testWidgets('pick, tag and upload; the asset is created when stored', (
      tester,
    ) async {
      final file = MemoryPickedFile(
        name: 'kitchen.jpg',
        bytes: bytesOf(800),
        modifiedMs: 11,
      );
      h.files.next = [file];
      final c = await pumpAssets(tester, h, location: '/assets/new');
      expect(key('no-files'), findsOneWidget);
      await tester.tap(key('pick-gallery'));
      await tester.pumpAndSettle();
      expect(find.text('kitchen.jpg'), findsOneWidget);
      await tester.enterText(key('add-title'), 'Kitchen morning');
      await tagFile(tester);
      await tester.tap(key('add-upload'));
      await tester.pumpAndSettle();
      // Back on the library; the upload ran in the background.
      final engine = c.read(studioUploadEngineProvider);
      expect(engine.jobs.single.status, UploadStatus.done);
      expect(h.s3.puts.length, 1);
      expect(h.api.createCalls.single['kind'], 'Photo');
      expect(h.api.createCalls.single['title'], 'Kitchen morning');
      expect(h.api.createCalls.single['media_id'], startsWith('MED-'));
    });

    testWidgets('the same file twice is refused in plain words', (
      tester,
    ) async {
      MemoryPickedFile mk() => MemoryPickedFile(
        name: 'a.jpg',
        bytes: bytesOf(300),
        path: '/p/a.jpg',
        modifiedMs: 5,
      );
      h.files.next = [mk()];
      final c = await pumpAssets(tester, h, location: '/assets/new');
      // The file is already in the queue.
      await c
          .read(studioUploadEngineProvider.notifier)
          .enqueue(mk(), purpose: 'asset');
      await tester.pumpAndSettle();
      await tester.tap(key('pick-files'));
      await tester.pumpAndSettle();
      await tagFile(tester);
      await tester.tap(key('add-upload'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('already uploading or uploaded'),
        findsOneWidget,
      );
    });

    testWidgets('a wrong kind of file is refused before anything is sent', (
      tester,
    ) async {
      h.files.next = [
        MemoryPickedFile(
          name: 'notes.zip',
          mime: 'application/zip',
          bytes: bytesOf(10),
        ),
      ];
      await pumpAssets(tester, h, location: '/assets/new');
      await tester.tap(key('pick-files'));
      await tester.pumpAndSettle();
      await tagFile(tester);
      await tester.tap(key('add-upload'));
      await tester.pumpAndSettle();
      expect(key('add-problem'), findsOneWidget);
      expect(h.api.beginCount, 0);
    });
  });

  group('edit', () {
    testWidgets('sends only what changed', (tester) async {
      await pumpAssets(tester, h, location: '/assets/AST-0000318/edit');
      await tester.enterText(key('edit-title'), 'Customer photo: car seat');
      await tester.ensureVisible(key('edit-save'));
      await tester.tap(key('edit-save'));
      await tester.pumpAndSettle();
      expect(h.api.updateCalls.single, {'title': 'Customer photo: car seat'});
    });
  });
}
