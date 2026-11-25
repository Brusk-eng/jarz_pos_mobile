import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/data/models/page_like.dart';
import 'package:jarz_pos/src/studio/data/models/studio_enums.dart';
import 'package:jarz_pos/src/studio/data/optimistic_write.dart';
import 'package:jarz_pos/src/studio/data/paging.dart';
import 'package:jarz_pos/src/studio/features/decisions/data/decisions_repository.dart';
import 'package:jarz_pos/src/studio/features/ideas/data/ideas_repository.dart';
import 'package:jarz_pos/src/studio/features/review/data/review_repository.dart';

class _Page implements PageLike<int> {
  _Page(this.items, this.next);
  @override
  final List<int> items;
  @override
  final String? next;
}

/// 7 numbers, 3 per page.
class _NumbersNotifier extends PagedNotifier<int> {
  static var fetches = <String?>[];

  @override
  Future<PageLike<int>> fetchPage(String? after) async {
    fetches.add(after);
    final start = after == null ? 0 : int.parse(after);
    final end = (start + 3).clamp(0, 7);
    return _Page([
      for (var i = start; i < end; i++) i,
    ], end >= 7 ? null : '$end');
  }
}

final _numbers = AsyncNotifierProvider<_NumbersNotifier, PagedState<int>>(
  _NumbersNotifier.new,
);

ProviderContainer _container(FakeStudioApi api) {
  final c = ProviderContainer(
    overrides: [studioApiProvider.overrideWithValue(api)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  FakeStudioApi fake() => FakeStudioApi(delay: Duration.zero);

  group('paging helper', () {
    test('loads the first page, then follows the cursor to the end', () async {
      _NumbersNotifier.fetches = [];
      final c = ProviderContainer();
      addTearDown(c.dispose);
      var s = await c.read(_numbers.future);
      expect(s.items, [0, 1, 2]);
      expect(s.hasMore, isTrue);

      await c.read(_numbers.notifier).loadMore();
      s = c.read(_numbers).requireValue;
      expect(s.items, [0, 1, 2, 3, 4, 5]);

      await c.read(_numbers.notifier).loadMore();
      s = c.read(_numbers).requireValue;
      expect(s.items, [0, 1, 2, 3, 4, 5, 6]);
      expect(s.hasMore, isFalse);

      // At the end it does nothing.
      await c.read(_numbers.notifier).loadMore();
      expect(_NumbersNotifier.fetches, [null, '3', '6']);
    });

    test('refresh starts again from the first page', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(_numbers.future);
      await c.read(_numbers.notifier).loadMore();
      await c.read(_numbers.notifier).refresh();
      expect(c.read(_numbers).requireValue.items, [0, 1, 2]);
    });
  });

  group('optimistic writes', () {
    test('runOptimistic rolls back and rethrows on failure', () async {
      var value = 1;
      await expectLater(
        runOptimistic<int, void>(
          snapshot: () => value,
          apply: () => value = 2,
          rollback: (p) => value = p,
          call: () async => throw const StudioServerError('boom'),
        ),
        throwsA(isA<StudioServerError>()),
      );
      expect(value, 1);
    });

    test(
      'approve removes the card at once and puts it back on failure',
      () async {
        final api = fake();
        final c = _container(api);
        final feed = await c.read(toApproveProvider.future);
        final id = feed.items.first.version.id;

        api.failNext('versions.approve', 'SERVER_ERROR');
        final notifier = c.read(toApproveProvider.notifier);
        final done = notifier.approve(id);
        // The optimistic removal is visible before the server answers.
        expect(
          c.read(toApproveProvider).requireValue.items.map((e) => e.version.id),
          isNot(contains(id)),
        );
        await expectLater(done, throwsA(isA<StudioServerError>()));
        expect(
          c.read(toApproveProvider).requireValue.items.map((e) => e.version.id),
          contains(id),
        );
        expect(
          c.read(toApproveProvider).requireValue.items.length,
          feed.items.length,
        );

        // The retry succeeds and the card stays gone.
        await notifier.approve(id);
        expect(
          c.read(toApproveProvider).requireValue.items.map((e) => e.version.id),
          isNot(contains(id)),
        );
      },
    );

    test('ALREADY_DONE counts as success', () async {
      final api = fake();
      final c = _container(api);
      final feed = await c.read(toApproveProvider.future);
      final id = feed.items.first.version.id;
      api.failNext('versions.approve', 'ALREADY_DONE');
      await c.read(toApproveProvider.notifier).approve(id);
      expect(
        c.read(toApproveProvider).requireValue.items.map((e) => e.version.id),
        isNot(contains(id)),
      );
    });

    test('STALE swaps in the fresh object and rethrows', () async {
      final api = fake();
      final c = _container(api);
      final list = await c.read(decisionsProvider.future);
      final d = list.items.first;
      final fresh = {...(d.toJson()), 'question': 'Changed by someone else'};
      api.failNext('decisions.answer', 'STALE', current: fresh);
      await expectLater(
        c.read(decisionsProvider.notifier).answer(d.id, 0),
        throwsA(isA<StudioStale>()),
      );
      final now = c
          .read(decisionsProvider)
          .requireValue
          .items
          .firstWhere((x) => x.id == d.id);
      expect(now.question, 'Changed by someone else');
    });

    test(
      'answering a decision updates the row and keeps it on success',
      () async {
        final api = fake();
        final c = _container(api);
        final list = await c.read(decisionsProvider.future);
        final d = list.items.first;
        await c.read(decisionsProvider.notifier).answer(d.id, 1, note: 'ok');
        final now = c
            .read(decisionsProvider)
            .requireValue
            .items
            .firstWhere((x) => x.id == d.id);
        expect(now.status, DecisionStatus.answered);
        expect(now.pickedIndex, 1);
      },
    );

    test('a failed keep rolls the idea back', () async {
      final api = fake();
      final c = _container(api);
      final list = await c.read(ideasProvider.future);
      final idea = list.items.first;
      api.failNext('ideas.keep', 'NOT_PERMITTED');
      await expectLater(
        c.read(ideasProvider.notifier).keep(idea.id),
        throwsA(isA<StudioNotPermitted>()),
      );
      final back = c
          .read(ideasProvider)
          .requireValue
          .items
          .firstWhere((i) => i.id == idea.id);
      expect(back.status, idea.status);
    });

    test('a version notifier rolls back a failed fix', () async {
      final api = fake();
      final c = _container(api);
      const id = 'PC-00188-v1';
      final before = await c.read(versionProvider(id).future);
      api.failNext('versions.fix', 'VALIDATION', field: 'reason');
      await expectLater(
        c.read(versionProvider(id).notifier).fix('x'),
        throwsA(isA<StudioValidation>()),
      );
      expect(c.read(versionProvider(id)).requireValue, before);
      await c.read(versionProvider(id).notifier).fix('too dark');
      expect(
        c.read(versionProvider(id)).requireValue.reviewOutcome,
        ReviewOutcome.fix,
      );
    });
  });
}
