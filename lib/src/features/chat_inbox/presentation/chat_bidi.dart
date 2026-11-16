// Text direction for chat content that mixes Arabic and English.
//
// Customers write "تمام الطلب Mango Trio" or "Ok تمام الطلب كده" in one
// message. The platform's own rule (first strong character wins) lays the
// second one out left-to-right even though it is an Arabic sentence with one
// English word, so punctuation jumps to the wrong end. The rule used here is
// per paragraph: right-to-left when the first strong character is Arabic /
// Hebrew / Persian script, or when Arabic-script words are at least as many as
// Latin words; left-to-right otherwise.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'chat_linkify.dart';

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

/// Text of several paragraphs (newline), each laid out in its own direction and
/// aligned to its own start, while the whole stays shrink-wrapped (a chat
/// bubble keeps hugging its text).
///
/// Plain [Text] on purpose: a long press must reach the bubble, and a
/// surrounding `SelectionArea` (the "Select text" sheet) can still select it.
/// Links, emails and phone numbers ([findChatLinks]) are underlined spans with
/// a tap recognizer only (no long-press recognizer, so the bubble's long press
/// still opens the actions sheet). Pass `linkify: false` to turn that off.
class ChatBidiText extends StatefulWidget {
  const ChatBidiText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.linkify = true,
    this.linkColor,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool linkify;
  final Color? linkColor;

  @override
  State<ChatBidiText> createState() => _ChatBidiTextState();
}

class _ChatBidiTextState extends State<ChatBidiText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  Widget _paragraph(
    String paragraph,
    TextDirection fallback,
    Color linkColor,
  ) {
    final direction = chatTextDirection(paragraph, fallback);
    final links = widget.linkify ? findChatLinks(paragraph) : const [];
    if (links.isEmpty) {
      return Text(
        paragraph,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        textAlign: TextAlign.start,
        textDirection: direction,
      );
    }
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final link in links) {
      if (link.start > cursor) {
        spans.add(TextSpan(text: paragraph.substring(cursor, link.start)));
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => openChatLink(context, link);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: link.text,
        style: TextStyle(
          color: linkColor,
          decoration: TextDecoration.underline,
          decorationColor: linkColor,
        ),
        recognizer: recognizer,
      ));
      cursor = link.end;
    }
    if (cursor < paragraph.length) {
      spans.add(TextSpan(text: paragraph.substring(cursor)));
    }
    return Text.rich(
      TextSpan(children: spans),
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: TextAlign.start,
      textDirection: direction,
    );
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final fallback = Directionality.of(context);
    final linkColor =
        widget.linkColor ?? Theme.of(context).colorScheme.primary;
    final children = <Widget>[
      for (final paragraph in widget.text.split('\n'))
        paragraph.isEmpty
            // A blank line keeps its height without a direction.
            ? Text(' ', style: widget.style)
            : _paragraph(paragraph, fallback, linkColor),
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
