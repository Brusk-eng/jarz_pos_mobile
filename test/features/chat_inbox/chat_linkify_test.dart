// Links, emails and phone numbers in chat text: detection, wa.me conversion,
// and that a linkified bubble still opens the long-press actions sheet.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/chat_inbox/data/models/chat_models.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/chat_linkify.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/widgets/chat_message_bubble.dart';

List<String> _texts(String s, [ChatLinkKind? kind]) => [
  for (final m in findChatLinks(s))
    if (kind == null || m.kind == kind) m.text,
];

void main() {
  group('URLs', () {
    test('http(s) and www', () {
      expect(_texts('see https://example.com/a?b=1 ok'), [
        'https://example.com/a?b=1',
      ]);
      expect(_texts('www.jarz.com/menu'), ['www.jarz.com/menu']);
    });

    test('bare well-known hosts', () {
      expect(
        _texts('wa.me/201012345678 instagram.com/jarz fb.me/x t.me/y'),
        ['wa.me/201012345678', 'instagram.com/jarz', 'fb.me/x', 't.me/y'],
      );
      expect(_texts('maps.app.goo.gl/AbC123 goo.gl/maps/xyz'), [
        'maps.app.goo.gl/AbC123',
        'goo.gl/maps/xyz',
      ]);
    });

    test('trailing punctuation is stripped, Latin and Arabic', () {
      expect(_texts('بص https://a.com/x.'), ['https://a.com/x']);
      expect(_texts('(https://a.com/x)'), ['https://a.com/x']);
      expect(_texts('هل ده https://a.com/x؟'), ['https://a.com/x']);
      expect(_texts('https://a.com/x، وكمان'), ['https://a.com/x']);
      expect(_texts('https://a.com/x!!'), ['https://a.com/x']);
      expect(_texts('https://a.com/(v)'), ['https://a.com/(v)']);
    });

    test('Arabic text around a link', () {
      expect(_texts('اللينك https://instagram.com/jarz/ تمام'), [
        'https://instagram.com/jarz/',
      ]);
    });

    test('plain words and file names are not links', () {
      expect(_texts('hello world, report.pdf and v1.2'), isEmpty);
    });

    test('chatUrlUri adds https', () {
      expect(chatUrlUri('www.a.com/x').toString(), 'https://www.a.com/x');
      expect(chatUrlUri('http://a.com').toString(), 'http://a.com');
    });
  });

  group('emails', () {
    test('detected, trailing dot stripped, not also a URL', () {
      final m = findChatLinks('mail me at sam.k+1@jarz.com.');
      expect(m, hasLength(1));
      expect(m.single.kind, ChatLinkKind.email);
      expect(m.single.text, 'sam.k+1@jarz.com');
    });
  });

  group('phones', () {
    test('Egyptian mobiles in every form', () {
      for (final raw in [
        '01012345678',
        '0101 234 5678',
        '010-1234-5678',
        '+201012345678',
        '+20 101 234 5678',
        '00201012345678',
        '01112345678',
        '01212345678',
        '01512345678',
      ]) {
        expect(_texts('call $raw now', ChatLinkKind.phone), [raw], reason: raw);
      }
    });

    test('Arabic-Indic digits are matched, shown as is', () {
      const raw = '٠١٠١٢٣٤٥٦٧٨';
      final m = findChatLinks('رقمي $raw شكرا');
      expect(m, hasLength(1));
      expect(m.single.text, raw);
      expect(chatPhoneInternationalDigits(raw), '201012345678');
    });

    test('other international numbers need + or 00', () {
      expect(_texts('+44 20 7946 0958', ChatLinkKind.phone), [
        '+44 20 7946 0958',
      ]);
      expect(_texts('+966501234567', ChatLinkKind.phone), ['+966501234567']);
      expect(_texts('12345678', ChatLinkKind.phone), isEmpty);
    });

    test('order numbers, short numbers, dates and prices are not phones', () {
      expect(findChatLinks('طلب #17529 بعد 3 ساعات'), isEmpty);
      expect(findChatLinks('order 17529'), isEmpty);
      expect(findChatLinks('on 2026-11-16 pay 1500 EGP'), isEmpty);
      expect(findChatLinks('0101234567'), isEmpty); // 10 digits
    });

    test('digits inside a URL stay part of the URL', () {
      final m = findChatLinks('https://wa.me/201012345678');
      expect(m, hasLength(1));
      expect(m.single.kind, ChatLinkKind.url);
    });
  });

  group('wa.me conversion', () {
    test('01x becomes 201x', () {
      expect(chatWhatsAppUri('01012345678').toString(), 'https://wa.me/201012345678');
      expect(chatWhatsAppUri('0101 234 5678').toString(), 'https://wa.me/201012345678');
    });

    test('+20, 0020 and other countries', () {
      expect(chatWhatsAppUri('+20 101 234 5678').toString(), 'https://wa.me/201012345678');
      expect(chatWhatsAppUri('0020 1012345678').toString(), 'https://wa.me/201012345678');
      expect(chatWhatsAppUri('+44 20 7946 0958').toString(), 'https://wa.me/442079460958');
    });

    test('Arabic-Indic digits are normalised', () {
      expect(chatWhatsAppUri('٠١٠١٢٣٤٥٦٧٨').toString(), 'https://wa.me/201012345678');
    });

    test('junk gives null', () {
      expect(chatWhatsAppUri('123'), isNull);
    });
  });

  group('widgets', () {
    ChatMessage message(String body) => ChatMessage.fromJson({
      'name': 'M-1',
      'direction': 'Inbound',
      'message_type': 'text',
      'body': body,
      'timestamp': '2026-10-16 10:00:00',
    });

    Future<void> pump(WidgetTester tester, String body) => tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(child: ChatMessageBubble(message: message(body))),
          ),
        ),
      ),
    );

    testWidgets('link spans carry only a tap recognizer', (tester) async {
      await pump(tester, 'شوف https://a.com/x تمام');
      final rich = tester
          .widgetList<RichText>(
            find.descendant(
              of: find.byKey(const ValueKey('chat-message-M-1')),
              matching: find.byType(RichText),
            ),
          )
          .first;
      final recognizers = <GestureRecognizer>[];
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.recognizer != null) {
          recognizers.add(span.recognizer!);
        }
        return true;
      });
      expect(recognizers, hasLength(1));
      expect(recognizers.single, isA<TapGestureRecognizer>());
    });

    testWidgets('long press on a linkified bubble opens the actions sheet '
        'with Open link', (tester) async {
      await pump(tester, 'see https://a.com/x please');
      await tester.longPress(find.byKey(const ValueKey('chat-message-M-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-message-actions')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-action-open-link-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-action-copy')), findsOneWidget);
    });

    testWidgets('no Open link row when the message has no URL', (tester) async {
      await pump(tester, 'just text 01012345678');
      await tester.longPress(find.byKey(const ValueKey('chat-message-M-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-action-open-link-0')), findsNothing);
    });

    testWidgets('tapping a phone opens Call / WhatsApp / Copy', (tester) async {
      await pump(tester, 'call 01012345678');
      final rich = tester
          .widgetList<RichText>(
            find.descendant(
              of: find.byKey(const ValueKey('chat-message-M-1')),
              matching: find.byType(RichText),
            ),
          )
          .first;
      TapGestureRecognizer? tap;
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.recognizer is TapGestureRecognizer) {
          tap = span.recognizer! as TapGestureRecognizer;
        }
        return true;
      });
      tap!.onTap!();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-phone-call')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-phone-whatsapp')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-phone-copy')), findsOneWidget);
    });

    test('document body split and icons', () {
      final a = chatSplitDocumentBody('menu.pdf\nthe new menu');
      expect(a.fileName, 'menu.pdf');
      expect(a.caption, 'the new menu');
      expect(chatSplitDocumentBody('menu.pdf').fileName, 'menu.pdf');
      expect(chatSplitDocumentBody('here you go').fileName, isNull);
      expect(chatSplitDocumentBody('here you go').caption, 'here you go');
      expect(chatDocumentIcon('application/pdf', null), Icons.picture_as_pdf_outlined);
      expect(chatDocumentIcon(null, 'a.xlsx'), Icons.table_chart_outlined);
      expect(chatDocumentIcon(null, 'a.zip'), Icons.folder_zip_outlined);
      expect(chatDocumentIcon(null, 'a.bin'), Icons.insert_drive_file_outlined);
    });
  });
}
