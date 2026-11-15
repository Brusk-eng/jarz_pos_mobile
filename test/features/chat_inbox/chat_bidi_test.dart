// Mixed Arabic / English direction: the per-paragraph detector and the
// ChatBidiText widget that lays each paragraph out in its own direction.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jarz_pos/src/features/chat_inbox/presentation/chat_bidi.dart';

void main() {
  group('chatTextDirection', () {
    const ltr = TextDirection.ltr;
    const rtl = TextDirection.rtl;

    test('an Arabic sentence with an English product name is RTL', () {
      expect(chatTextDirection('تمام الطلب Mango Trio', ltr), rtl);
    });

    test('an English opener on an Arabic sentence is still RTL (more Arabic '
        'words than Latin)', () {
      expect(chatTextDirection('Ok تمام الطلب كده', ltr), rtl);
    });

    test('plain English is LTR', () {
      expect(chatTextDirection('Mango Cake Trio please', rtl), ltr);
    });

    test('an English sentence with one Arabic word stays LTR', () {
      expect(
        chatTextDirection('Please send it to المعادي branch today', rtl),
        ltr,
      );
    });

    test('a phone number has no strong character: the fallback decides', () {
      expect(chatTextDirection('010 1234 5678', ltr), ltr);
      expect(chatTextDirection('010 1234 5678', rtl), rtl);
    });

    test('emoji and punctuation only fall back', () {
      expect(chatTextDirection('👍🙏', rtl), rtl);
      expect(chatTextDirection('!!! ...', ltr), ltr);
      expect(chatTextDirection('', rtl), rtl);
    });

    test('Arabic-Indic digits are numbers, not strong characters', () {
      expect(chatTextDirection('٠١٠١٢٣٤', ltr), ltr);
    });

    test('Persian and Hebrew script count as right-to-left', () {
      expect(chatTextDirection('سلام دوست', ltr), rtl);
      expect(chatTextDirection('שלום חבר', ltr), rtl);
    });

    test('a number then Arabic is RTL; a number then English is LTR', () {
      expect(chatTextDirection('3 برطمانات مانجو', ltr), rtl);
      expect(chatTextDirection('3 jars of mango', rtl), ltr);
    });

    test('mixed multi-line: each paragraph is judged on its own', () {
      const text =
          'تمام الطلب Mango Trio\nMango Cake Trio please\n010 1234 5678';
      final directions = [
        for (final line in text.split('\n')) chatTextDirection(line, ltr),
      ];
      expect(directions, [rtl, ltr, ltr]);
    });
  });

  group('ChatBidiText', () {
    Widget host(Widget child, {TextDirection ui = TextDirection.ltr}) {
      return MaterialApp(
        home: Directionality(
          textDirection: ui,
          child: Scaffold(
            body: Align(alignment: Alignment.topLeft, child: child),
          ),
        ),
      );
    }

    testWidgets('every paragraph gets its own direction and start alignment', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const ChatBidiText(
            'تمام الطلب Mango Trio\nMango Cake Trio please\n010 1234 5678',
          ),
        ),
      );
      Text paragraph(String text) => tester.widget<Text>(find.text(text));

      expect(
        paragraph('تمام الطلب Mango Trio').textDirection,
        TextDirection.rtl,
      );
      expect(
        paragraph('Mango Cake Trio please').textDirection,
        TextDirection.ltr,
      );
      // No strong character: the UI direction (LTR here).
      expect(paragraph('010 1234 5678').textDirection, TextDirection.ltr);
      for (final text in [
        'تمام الطلب Mango Trio',
        'Mango Cake Trio please',
        '010 1234 5678',
      ]) {
        expect(paragraph(text).textAlign, TextAlign.start);
      }
    });

    testWidgets('a number-only paragraph follows the UI direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const ChatBidiText('010 1234 5678'), ui: TextDirection.rtl),
      );
      expect(
        tester.widget<Text>(find.text('010 1234 5678')).textDirection,
        TextDirection.rtl,
      );
    });

    testWidgets('an RTL paragraph hugs the right edge of the shrink-wrapped '
        'column and an LTR one the left', (tester) async {
      await tester.pumpWidget(
        host(
          const ChatBidiText(
            'Mango Cake Trio please, thank you very much\nتمام',
          ),
        ),
      );
      final box = tester.getRect(find.byType(ChatBidiText));
      final english = tester.getRect(
        find.text('Mango Cake Trio please, thank you very much'),
      );
      // The column hugs the wider (English) line and both lines span it.
      expect(box.width, closeTo(english.width, 0.5));
      expect(tester.getRect(find.text('تمام')).width, closeTo(box.width, 0.5));

      // Where the glyphs sit inside their line.
      double glyphEdge(String text, {required bool right}) {
        final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: text.length),
        );
        return right
            ? boxes.map((b) => b.right).reduce((a, b) => a > b ? a : b)
            : boxes.map((b) => b.left).reduce((a, b) => a < b ? a : b);
      }

      expect(glyphEdge('تمام', right: true), closeTo(box.width, 0.5));
      expect(glyphEdge('تمام', right: false), greaterThan(0));
      expect(
        glyphEdge('Mango Cake Trio please, thank you very much', right: false),
        closeTo(0, 0.5),
      );
    });

    testWidgets('a long Arabic paragraph wraps inside the width it is given', (
      tester,
    ) async {
      final text = List.filled(30, 'عايزة برطمانين مانجو').join(' ');
      await tester.pumpWidget(
        host(SizedBox(width: 200, child: ChatBidiText(text))),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(ChatBidiText)).width,
        lessThanOrEqualTo(200),
      );
    });
  });
}
