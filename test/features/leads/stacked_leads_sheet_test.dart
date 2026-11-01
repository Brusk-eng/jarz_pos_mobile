// The picker behind a map pin that zooming cannot split: every member must be
// listed, and tapping one must hand that lead back to the map.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/leads/data/models/lead.dart';
import 'package:jarz_pos/src/features/leads/presentation/widgets/stacked_leads_sheet.dart';

Lead _lead(String name, String label) => Lead(
      name: name,
      leadName: label,
      tier: 'B',
      primaryArea: 'New Cairo',
      latitude: 30.0801,
      longitude: 31.3301,
    );

void main() {
  testWidgets('lists every stacked lead and returns the one tapped',
      (tester) async {
    Lead? picked;
    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                picked = await StackedLeadsSheet.show(
                  context,
                  leads: [
                    _lead('LEAD-1', 'Espressolab'),
                    _lead('LEAD-2', 'كافيه النصر'),
                  ],
                );
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Espressolab'), findsOneWidget);
    expect(find.text('كافيه النصر'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('كافيه النصر'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(picked?.name, 'LEAD-2');
  });
}
