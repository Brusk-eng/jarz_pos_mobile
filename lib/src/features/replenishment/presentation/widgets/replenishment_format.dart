/// Unicode LTR isolate. Without it the bidi algorithm moves a leading minus to
/// the trailing edge in an Arabic paragraph, so "-18" renders as "18-" — and a
/// negative bin read as positive is exactly the mistake this screen exists to
/// stop. Written as escapes because the characters are invisible in source.
const _ltrIsolate = '\u{2066}'; // LEFT-TO-RIGHT ISOLATE
const _popIsolate = '\u{2069}'; // POP DIRECTIONAL ISOLATE

/// Formats a stock quantity for display.
///
/// Drops trailing zeros so 12 jars read as "12" and not "12.000", while
/// keeping precision for the weight-based items that share the list. Negative
/// values are direction-isolated so they still read as negative in Arabic.
///
/// Deliberately a local copy of the production board's helper rather than an
/// import: this feature owns its own presentation layer, and the board's
/// module is not a shared utility.
String trimQty(double value, {int decimals = 2}) {
  final text = _plainQty(value, decimals);
  return value < 0 ? '$_ltrIsolate$text$_popIsolate' : text;
}

String _plainQty(double value, int decimals) {
  if (value == value.roundToDouble() && value.abs() < 1e9) {
    return value.toStringAsFixed(0);
  }
  final fixed = value.toStringAsFixed(decimals);
  if (!fixed.contains('.')) return fixed;
  return fixed
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// Wraps always-Latin data (a warehouse name, an item code) in a directional
/// isolate so bidi cannot drag its trailing " - J" to the front of an Arabic
/// sentence.
String isolateLtr(String value) =>
    value.isEmpty ? value : '$_ltrIsolate$value$_popIsolate';

/// A quantity with its unit, as one already-formatted token.
///
/// Kept out of the ARB placeholders on purpose: gluing the number and the UOM
/// here means every message takes one opaque string and no translation has to
/// carry a unit it cannot inflect.
String qtyWithUom(double value, String uom, {int decimals = 2}) {
  final qty = trimQty(value, decimals: decimals);
  return uom.trim().isEmpty ? qty : '$qty ${uom.trim()}';
}
