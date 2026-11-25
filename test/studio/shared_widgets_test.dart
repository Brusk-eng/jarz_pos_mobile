import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_strings.dart';
import 'package:jarz_pos/src/studio/core/router/studio_screen.dart';
import 'package:jarz_pos/src/studio/core/theme/studio_status_colors.dart';
import 'package:jarz_pos/src/studio/core/theme/studio_theme.dart';
import 'package:jarz_pos/src/studio/shared/optimistic.dart';
import 'package:jarz_pos/src/studio/shared/stage_chip.dart';
import 'package:jarz_pos/src/studio/shared/studio_async_view.dart';
import 'package:jarz_pos/src/studio/shared/verdict_badge.dart';
import 'package:jarz_pos/src/studio/shared/view_edit_scaffold.dart';
import 'package:jarz_pos/src/studio/shared/studio_toast.dart';

Widget host(Widget child, {String locale = 'en'}) => MaterialApp(
        scaffoldMessengerKey: studioMessengerKey,
  theme: buildStudioTheme(locale: Locale(locale)),
  locale: Locale(locale),
  supportedLocales: StudioStrings.supportedLocales,
  localizationsDelegates: const [
    StudioStrings.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: child,
);

void main() {
  group('ViewEditScaffold', () {
    testWidgets('has no pencil unless onEdit is given', (tester) async {
      await tester.pumpWidget(
        host(const ViewEditScaffold(title: 'Piece', body: Text('body'))),
      );
      expect(find.byKey(const ValueKey('edit')), findsNothing);
      expect(find.text('body'), findsOneWidget);
    });

    testWidgets('pencil calls onEdit; body stays read-only', (tester) async {
      var edits = 0;
      await tester.pumpWidget(
        host(
          ViewEditScaffold(
            title: 'Piece',
            body: const Text('body'),
            onEdit: () => edits++,
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.byKey(const ValueKey('edit')));
      expect(edits, 1);
    });

    testWidgets('"?" opens the how-this-works sheet with title and lines', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const ViewEditScaffold(
            title: 'Today',
            screen: StudioScreen.today,
            body: SizedBox(),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('help')));
      await tester.pumpAndSettle();
      expect(find.text('How this works'), findsOneWidget);
      final help = const StudioStringsEn().screen(StudioScreen.today).help;
      expect(help.length, inInclusiveRange(3, 5));
      for (final line in help) {
        expect(find.text(line), findsOneWidget);
      }
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('How this works'), findsNothing);
    });

    testWidgets('every screen has 3 to 5 help lines in both languages', (
      tester,
    ) async {
      for (final s in StudioScreen.values) {
        for (final t in [const StudioStringsEn(), const StudioStringsAr()]) {
          final c = t.screen(s);
          expect(c.help.length, inInclusiveRange(3, 5), reason: '$s');
          expect(c.purpose, isNotEmpty);
          expect(c.firstStep, isNotEmpty);
        }
      }
    });
  });

  group('StudioAsyncView', () {
    const empty = StudioEmptyConfig(
      purpose: 'This screen is for X.',
      firstStep: 'Do Y first.',
    );

    Widget view(AsyncValue<List<int>> v, {VoidCallback? onRetry}) => host(
      Scaffold(
        body: StudioAsyncView<List<int>>(
          value: v,
          empty: empty,
          onRetry: onRetry,
          builder: (_, data) => Text('rows: ${data.length}'),
        ),
      ),
    );

    testWidgets('loading shows the skeleton', (tester) async {
      await tester.pumpWidget(view(const AsyncLoading()));
      expect(find.byKey(const ValueKey('skeleton')), findsOneWidget);
    });

    testWidgets('empty shows what the screen is for and what to do first', (
      tester,
    ) async {
      await tester.pumpWidget(view(const AsyncData(<int>[])));
      expect(find.text('This screen is for X.'), findsOneWidget);
      expect(find.text('Do Y first.'), findsOneWidget);
    });

    testWidgets('empty with an action shows the button', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        host(
          Scaffold(
            body: StudioAsyncView<List<int>>(
              value: const AsyncData(<int>[]),
              builder: (_, _) => const SizedBox(),
              empty: StudioEmptyConfig(
                purpose: 'p',
                firstStep: 'f',
                actionLabel: 'New piece',
                onAction: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('New piece'));
      expect(tapped, isTrue);
    });

    testWidgets('error shows retry and calls onRetry', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        view(
          AsyncError<List<int>>('boom', StackTrace.empty),
          onRetry: () => retries++,
        ),
      );
      expect(find.byKey(const ValueKey('error-text')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    });

    testWidgets('data renders the builder', (tester) async {
      await tester.pumpWidget(view(const AsyncData([1, 2, 3])));
      expect(find.text('rows: 3'), findsOneWidget);
    });
  });

  group('optimistic', () {
    Future<(bool, List<String>)> run(
      WidgetTester tester, {
      required Future<void> Function() call,
    }) async {
      var state = 'before';
      final log = <String>[];
      late BuildContext ctx;
      await tester.pumpWidget(
        host(
          Scaffold(
            body: Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      final ok = await optimistic<String>(
        context: ctx,
        snapshot: () => state,
        apply: () {
          state = 'after';
          log.add('apply');
        },
        rollback: (prev) {
          state = prev;
          log.add('rollback');
        },
        call: call,
      );
      log.add(state);
      await tester.pump();
      return (ok, log);
    }

    testWidgets('keeps the change when the call succeeds', (tester) async {
      final (ok, log) = await run(tester, call: () async {});
      expect(ok, isTrue);
      expect(log, ['apply', 'after']);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('rolls back and shows a snackbar when the call fails', (
      tester,
    ) async {
      final (ok, log) = await run(tester, call: () async => throw 'nope');
      expect(ok, isFalse);
      expect(log, ['apply', 'rollback', 'before']);
      expect(
        find.text('That change was not saved. Try again.'),
        findsOneWidget,
      );
    });
  });

  group('chips', () {
    testWidgets('StageChip renders all nine stages', (tester) async {
      await tester.pumpWidget(
        host(
          Scaffold(
            body: Wrap(
              children: [
                for (final s in PieceStage.values) StageChip(stage: s),
              ],
            ),
          ),
        ),
      );
      expect(PieceStage.values.length, 9);
      expect(stageColors.length, 9);
      for (final s in PieceStage.values) {
        expect(find.text(s.apiName), findsOneWidget);
      }
    });

    testWidgets('StageChip is localised', (tester) async {
      await tester.pumpWidget(
        host(
          const Scaffold(body: StageChip(stage: PieceStage.toShoot)),
          locale: 'ar',
        ),
      );
      expect(find.text('للتصوير'), findsOneWidget);
    });

    testWidgets('VerdictBadge shows RUN, FIX and DROP', (tester) async {
      await tester.pumpWidget(
        host(
          Scaffold(
            body: Column(
              children: [
                for (final v in Verdict.values) VerdictBadge(verdict: v),
              ],
            ),
          ),
        ),
      );
      expect(find.text('RUN'), findsOneWidget);
      expect(find.text('FIX'), findsOneWidget);
      expect(find.text('DROP'), findsOneWidget);
      expect(verdictColors.length, 3);
    });
  });
}
