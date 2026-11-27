import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/shared/layout/master_detail.dart';
import 'package:jarz_pos/src/studio/shared/layout/studio_layout.dart';

import 'shot_harness.dart' show useSize;

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('StudioBreakpoint', () {
    test('classes at the boundaries', () {
      expect(StudioBreakpoint.forWidth(359), StudioBreakpoint.compact);
      expect(StudioBreakpoint.forWidth(599.9), StudioBreakpoint.compact);
      expect(StudioBreakpoint.forWidth(600), StudioBreakpoint.medium);
      expect(StudioBreakpoint.forWidth(1023), StudioBreakpoint.medium);
      expect(StudioBreakpoint.forWidth(1024), StudioBreakpoint.expanded);
      expect(StudioBreakpoint.forWidth(1439), StudioBreakpoint.expanded);
      expect(StudioBreakpoint.forWidth(1440), StudioBreakpoint.large);
      expect(StudioBreakpoint.forWidth(2560), StudioBreakpoint.large);
    });

    test('flags', () {
      expect(StudioBreakpoint.compact.isCompact, isTrue);
      expect(StudioBreakpoint.medium.isMediumUp, isTrue);
      expect(StudioBreakpoint.medium.isWide, isFalse);
      expect(StudioBreakpoint.expanded.isWide, isTrue);
      expect(StudioBreakpoint.large.isWide, isTrue);
    });

    testWidgets('context reads the window width', (tester) async {
      late StudioBreakpoint seen;
      Widget probe() => Builder(
        builder: (context) {
          seen = context.breakpoint;
          return const SizedBox();
        },
      );
      useSize(tester, 390, 844);
      await tester.pumpWidget(_host(probe()));
      expect(seen, StudioBreakpoint.compact);
      useSize(tester, 1920, 1080);
      await tester.pumpWidget(_host(probe()));
      await tester.pump();
      expect(seen, StudioBreakpoint.large);
    });
  });

  group('ResponsiveSectionGrid', () {
    test('masonry: the next section goes to the lightest column', () {
      final cols = ResponsiveSectionGrid.assign([5, 1, 1, 1, 4], 2);
      // 0 -> col0 (5), 1 -> col1 (1), 2 -> col1 (2), 3 -> col1 (3),
      // 4 -> col1 (7 after 4 more) since col1 (3) < col0 (5).
      expect(cols[0], [0]);
      expect(cols[1], [1, 2, 3, 4]);
    });

    test('order inside a column is the order of the sections', () {
      final cols = ResponsiveSectionGrid.assign(List.filled(7, 1.0), 3);
      expect(cols, [
        [0, 3, 6],
        [1, 4],
        [2, 5],
      ]);
    });

    test('columns by window width', () {
      expect(studioSectionColumns(390), 1);
      expect(studioSectionColumns(800), 1);
      expect(studioSectionColumns(1100), 2);
      expect(studioSectionColumns(1600), 3);
    });

    Future<List<double>> lefts(WidgetTester tester, double width) async {
      useSize(tester, width, 900);
      await tester.pumpWidget(
        _host(
          ResponsiveSectionGrid(
            sections: [
              for (var i = 0; i < 6; i++)
                GridSection(child: SizedBox(key: ValueKey('s$i'), height: 50)),
            ],
          ),
        ),
      );
      return [
        for (var i = 0; i < 6; i++)
          tester.getTopLeft(find.byKey(ValueKey('s$i'))).dx,
      ];
    }

    testWidgets('1 column on a phone, 2 on expanded, 3 on large', (
      tester,
    ) async {
      expect((await lefts(tester, 390)).toSet().length, 1);
      expect((await lefts(tester, 1100)).toSet().length, 2);
      expect((await lefts(tester, 1600)).toSet().length, 3);
    });

    testWidgets('short sections fill the gap under a short one', (
      tester,
    ) async {
      useSize(tester, 1100, 900);
      await tester.pumpWidget(
        _host(
          const ResponsiveSectionGrid(
            sections: [
              GridSection(weight: 6, child: SizedBox(key: ValueKey('tall'))),
              GridSection(weight: 1, child: SizedBox(key: ValueKey('a'))),
              GridSection(weight: 1, child: SizedBox(key: ValueKey('b'))),
            ],
          ),
        ),
      );
      final tall = tester.getTopLeft(find.byKey(const ValueKey('tall'))).dx;
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('a'))).dx,
        isNot(tall),
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('b'))).dx,
        isNot(tall),
      );
    });
  });

  group('ResponsiveCardGrid', () {
    test('column count', () {
      expect(ResponsiveCardGrid.columnsFor(390, 420, 4), 1);
      expect(ResponsiveCardGrid.columnsFor(900, 420, 4), 2);
      expect(ResponsiveCardGrid.columnsFor(1300, 420, 4), 3);
      expect(ResponsiveCardGrid.columnsFor(5000, 420, 4), 4);
    });

    testWidgets('lays out a last short row', (tester) async {
      useSize(tester, 1300, 900);
      await tester.pumpWidget(
        _host(
          ResponsiveCardGrid(
            children: [
              for (var i = 0; i < 4; i++)
                SizedBox(key: ValueKey('c$i'), height: 40),
            ],
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('c3'))).dx,
        tester.getTopLeft(find.byKey(const ValueKey('c0'))).dx,
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('c3'))).dy,
        greaterThan(tester.getTopLeft(find.byKey(const ValueKey('c0'))).dy),
      );
    });
  });

  group('StudioPage', () {
    testWidgets('caps and centres on a wide window, leaves a phone alone', (
      tester,
    ) async {
      Widget page() => MaterialApp(
        home: Scaffold(
          body: StudioPage(
            maxWidth: 720,
            child: Container(key: const ValueKey('p'), color: Colors.red),
          ),
        ),
      );
      useSize(tester, 1440, 900);
      await tester.pumpWidget(page());
      final box = tester.getRect(find.byKey(const ValueKey('p')));
      expect(box.width, 720);
      expect(box.center.dx, 720);
      expect(box.height, 900);
      useSize(tester, 390, 844);
      await tester.pumpWidget(page());
      await tester.pump();
      expect(tester.getSize(find.byKey(const ValueKey('p'))).width, 390);
    });
  });

  group('StudioPage margins', () {
    testWidgets('a wheel turn over the left and right margin scrolls', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      useSize(tester, 1920, 1080);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudioPage(
              maxWidth: 840,
              child: ListView(
                controller: controller,
                children: [
                  for (var i = 0; i < 80; i++)
                    SizedBox(height: 60, child: Text('row $i')),
                ],
              ),
            ),
          ),
        ),
      );
      expect(controller.offset, 0);
      for (final x in [100.0, 1800.0]) {
        final before = controller.offset;
        final pointer = TestPointer(1, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(pointer.hover(Offset(x, 500)));
        await tester.sendEventToBinding(pointer.scroll(const Offset(0, 200)));
        await tester.pump();
        expect(controller.offset, greaterThan(before), reason: 'margin x=$x');
      }
    });
  });

  group('MasterDetail', () {
    Widget app({required List<String> pushed}) => MaterialApp(
      home: Scaffold(
        body: MasterDetail(
          onPush: pushed.add,
          emptyDetail: const Text('nothing open'),
          masterBuilder: (context, selected, open) => ListView(
            children: [
              for (final id in ['a', 'b'])
                ListTile(
                  key: ValueKey('row-$id'),
                  title: Text('row $id'),
                  selected: selected == id,
                  onTap: () => open(id),
                ),
            ],
          ),
          detailBuilder: (context, id) => Text('detail $id'),
        ),
      ),
    );

    testWidgets('wide: the list and the opened item side by side', (
      tester,
    ) async {
      final pushed = <String>[];
      useSize(tester, 1440, 900);
      await tester.pumpWidget(app(pushed: pushed));
      expect(find.text('nothing open'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('row-b')));
      await tester.pump();
      expect(find.text('detail b'), findsOneWidget);
      expect(find.text('row a'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('row-a')));
      await tester.pump();
      expect(find.text('detail a'), findsOneWidget);
      expect(find.text('detail b'), findsNothing);
      expect(pushed, isEmpty);
    });

    testWidgets('narrow: only the list, opening pushes', (tester) async {
      final pushed = <String>[];
      useSize(tester, 390, 844);
      await tester.pumpWidget(app(pushed: pushed));
      expect(find.text('nothing open'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('row-b')));
      await tester.pump();
      expect(pushed, ['b']);
      expect(find.text('detail b'), findsNothing);
    });
  });
}
