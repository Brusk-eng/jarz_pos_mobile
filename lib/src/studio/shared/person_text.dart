import 'package:flutter/material.dart';

/// Text a person wrote (a title, an idea, a caption, a reason, a name) keeps
/// its own direction: an English title that starts with a number reads left to
/// right on an Arabic page and the other way round. The direction is the first
/// strong letter of the text; a text with none (only digits or marks) follows
/// the page.
///
/// [PersonText] is the one widget for it, [personTextDirection] and
/// [personTextAlign] the same decision for a `Text` built by hand.
TextDirection? personTextDirection(String text) {
  for (final r in text.runes) {
    if ((r >= 0x41 && r <= 0x5A) ||
        (r >= 0x61 && r <= 0x7A) ||
        (r >= 0xC0 && r <= 0x24F)) {
      return TextDirection.ltr;
    }
    if ((r >= 0x0590 && r <= 0x08FF) ||
        (r >= 0xFB1D && r <= 0xFDFF) ||
        (r >= 0xFE70 && r <= 0xFEFF)) {
      return TextDirection.rtl;
    }
  }
  return null;
}

/// The alignment that keeps the text on the page's start edge even when the
/// text runs the other way.
TextAlign? personTextAlign(BuildContext context, String text) {
  final own = personTextDirection(text);
  if (own == null) return null;
  return own == Directionality.of(context) ? null : TextAlign.end;
}

class PersonText extends StatelessWidget {
  const PersonText(
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
  Widget build(BuildContext context) => Text(
    text,
    style: style,
    maxLines: maxLines,
    overflow: overflow,
    textDirection: personTextDirection(text),
    textAlign: personTextAlign(context, text),
  );
}
