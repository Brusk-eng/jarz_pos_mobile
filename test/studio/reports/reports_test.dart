import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/features/reports/presentation/reports_screen.dart';

import '../more/more_test_utils.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

void main() {
  testWidgets('lists the pages, newest first, with kind and date', (
    tester,
  ) async {
    await pumpMore(tester, const ReportsScreen());
    expect(_key('reports-list'), findsOneWidget);
    expect(_key('report-REP-00041'), findsOneWidget);
    expect(_key('report-REP-00040'), findsOneWidget);
    final first = tester.getTopLeft(_key('report-REP-00041')).dy;
    final second = tester.getTopLeft(_key('report-REP-00040')).dy;
    expect(first, lessThan(second));
    expect(find.text('Ads read'), findsWidgets);
  });

  testWidgets('empty says what to do first', (tester) async {
    final api = RecordingApi(
      fixtures: patchFixtures({
        'reports.list': (j) => {'items': [], 'next': null},
      }),
    );
    await pumpMore(tester, const ReportsScreen(), api: api);
    expect(_key('empty-purpose'), findsOneWidget);
    expect(find.textContaining('first page Claude writes'), findsOneWidget);
  });

  testWidgets('error, then retry', (tester) async {
    final api = RecordingApi()..failNext('reports.list', 'SERVER_ERROR');
    await pumpMore(tester, const ReportsScreen(), api: api);
    expect(_key('error-text'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(_key('reports-list'), findsOneWidget);
  });

  testWidgets('the kind chip asks the server for that kind', (tester) async {
    final api = RecordingApi();
    await pumpMore(
      tester,
      const ReportsScreen(),
      api: api,
      size: const Size(900, 900),
    );
    await tapKey(tester, 'chip-Ads read');
    expect(api.last('reports.list')!['kind'], 'Ads read');
  });

  testWidgets('search narrows by title and topic, with a no-match line', (
    tester,
  ) async {
    await pumpMore(tester, const ReportsScreen());
    await typeKey(tester, 'search-field', 'working');
    expect(_key('report-REP-00040'), findsOneWidget);
    expect(_key('report-REP-00041'), findsNothing);
    await typeKey(tester, 'search-field', 'zzzz');
    expect(_key('reports-no-match'), findsOneWidget);
    await tapKey(tester, 'search-clear');
    expect(_key('report-REP-00041'), findsOneWidget);
  });

  testWidgets('a report opens in the browser', (tester) async {
    final opened = <Uri>[];
    await pumpMore(tester, const ReportsScreen(), opened: opened);
    await tapKey(tester, 'report-REP-00041');
    expect(opened, hasLength(1));
    expect(opened.single.scheme, 'https');
  });

  testWidgets('when the link cannot open, it says so', (tester) async {
    await pumpMore(tester, const ReportsScreen(), openResult: false);
    await tapKey(tester, 'report-REP-00041');
    expect(snackText(tester), 'Could not open the link.');
  });

  testWidgets('paging adds the next page', (tester) async {
    final api = RecordingApi();
    final base = (fixtureJson('reports.list') as Map)['items'] as List;
    api.respond['reports.list'] = (p) => p['after'] == 'n1'
        ? {
            'items': [
              {...(base.first as Map), 'id': 'REP-00001', 'title': 'Old one'},
            ],
            'next': null,
          }
        : {'items': base, 'next': 'n1'};
    await pumpMore(tester, const ReportsScreen(), api: api);
    await tapKey(tester, 'show-more');
    expect(_key('report-REP-00001'), findsOneWidget);
  });

  testWidgets('Arabic list at 360 px has no overflow', (tester) async {
    await pumpMore(tester, const ReportsScreen(), locale: 'ar');
    expect(find.text('التقارير'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
