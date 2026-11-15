// Text direction for chat content that mixes Arabic and English.
//
// Customers write "تمام الطلب Mango Trio" or "Ok تمام الطلب كده" in one
// message. The platform's own rule (first strong character wins) lays the
// second one out left-to-right even though it is an Arabic sentence with one
// English word, so punctuation jumps to the wrong end. The rule used here is
// per paragraph: right-to-left when the first strong character is Arabic /
// Hebrew / Persian script, or when Arabic-script words are at least as many as
// Latin words; left-to-right otherwise.

import 'package:flutter/material.dart';

bool _isRtlScript(int rune) =>
    // Arabic-Indic digits are numbers, not letters: not strong.
    !(rune >= 0x0660 && rune <= 0x0669) &&
    !(rune >= 0x06F0 && rune <= 0x06F9) &&
    ((rune >= 0x0590 && rune <= 0x08FF) ||
        (rune >= 0xFB1D && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF));

bool _isLatinLetter(int rune) =>
    (rune >= 0x41 && rune <= 0x5A) ||
    (rune >= 0x61 && rune <= 0x7A) ||
    (rune >= 0x00C0 && rune <= 0x024F && rune != 0xD7 && rune != 0xF7);

bool _isSeparator(int rune) =>
    rune <= 0x20 ||
    rune == 0xA0 ||
    (rune >= 0x2000 && rune <= 0x206F) ||
    // Arabic comma, semicolon and question mark separate words too.
    rune == 0x060C ||
    rune == 0x061B ||
    rune == 0x061F ||
    (rune >= 0x21 && rune <= 0x2F && rune != 0x27) ||
    (rune >= 0x3A && rune <= 0x40) ||
    (rune >= 0x5B && rune <= 0x60) ||
    (rune >= 0x7B && rune <= 0x7E);

/// The direction one paragraph of [text] should be laid out in. [fallback] is
/// returned when the text has no letters at all (digits, punctuation, emoji).
TextDirection chatTextDirection(String text, TextDirection fallback) {
  var arabicWords = 0;
  var latinWords = 0;
  TextDirection? first;
  var wordHasArabic = false;
  var wordHasLatin = false;

  void endWord() {
    if (wordHasArabic) {
      arabicWords++;
    } else if (wordHasLatin) {
      latinWords++;
    }
    wordHasArabic = false;
    wordHasLatin = false;
  }

  for (final rune in text.runes) {
    if (_isRtlScript(rune)) {
      first ??= TextDirection.rtl;
      wordHasArabic = true;
    } else if (_isLatinLetter(rune)) {
      first ??= TextDirection.ltr;
      wordHasLatin = true;
    } else if (_isSeparator(rune)) {
      endWord();
    }
  }
  endWord();

  if (first == null) return fallback;
  if (first == TextDirection.rtl) return TextDirection.rtl;
  if (arabicWords > 0 && arabicWords >= latinWords) return TextDirection.rtl;
  return TextDirection.ltr;
}

/// Text of several paragraphs ('\n'), each laid out in its own direction and
/// aligned to its own start, while the whole stays shrink-wrapped (a chat
/// bubble keeps hugging its text).
///
/// Plain [Text] on purpose: a long press must reach the bubble, and a
/// surrounding `SelectionArea` (the "Select text" sheet) can still select it.
class ChatBidiText extends StatelessWidget {
  const ChatBidiText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final fallback = Directionality.of(context);
    final paragraphs = text.split('\n');
    final children = <Widget>[
      for (final paragraph in paragraphs)
        paragraph.isEmpty
            // A blank line keeps its height without a direction.
            ? Text(' ', style: style)
            : Text(
                paragraph,
                style: style,
                maxLines: maxLines,
                overflow: overflow,
                textAlign: TextAlign.start,
                textDirection: chatTextDirection(paragraph, fallback),
              ),
    ];
    if (children.length == 1) return children.single;
    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
