import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/daily_plan.dart';
import 'package:jarz_pos/src/features/manufacturing/presentation/widgets/mixer_run_summary.dart';

/// The mixer bar under the Plan tab: one folded line until swiped up.
void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: MixerRunSummary(
              preview: DailyPlanPreview(
                totalMixQty: 28.56,
                requiredBatches: 3,
                runs: [
                  MixerRun(size: 1.5, quality: RunQuality.preferred),
                  MixerRun(size: 1.5, quality: RunQuality.preferred),
                ],
              ),
              calculating: false,
              mixUom: 'Kg',
              totalJars: 40,
              showActions: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('folded: jars and the split in short only', (tester) async {
    await pump(tester);
    expect(find.text('40 jars planned'), findsOneWidget);
    expect(find.text('1.5 + 1.5'), findsOneWidget);
    expect(find.textContaining('of mix'), findsNothing);
  });

  testWidgets('swipe up opens it, swipe down folds it', (tester) async {
    await pump(tester);

    await tester.fling(
      find.text('40 jars planned'),
      const Offset(0, -200),
      800,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('of mix'), findsOneWidget);
    expect(find.text('1.5 + 1.5'), findsNothing);

    await tester.fling(find.text('40 jars planned'), const Offset(0, 200), 800);
    await tester.pumpAndSettle();
    expect(find.textContaining('of mix'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
