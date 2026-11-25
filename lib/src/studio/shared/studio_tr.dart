import 'package:flutter/widgets.dart';

import '../core/l10n/plural.dart';
import '../core/l10n/studio_labels.dart';

/// `context.tr('English', 'عربي')`: one line for a short screen text in both
/// languages (the same `tr` the label table uses). New terms go in
/// `core/l10n/GLOSSARY.md` first.
extension StudioTr on BuildContext {
  String tr(String en, String ar) => StudioLabels.of(this).tr(en, ar);

  /// A counted thing in the reader's language: `1 rating` / `3 ratings` in
  /// English, the Arabic number rules (`ar`, see `plural.dart`) in Arabic.
  /// The one way a count with its noun is written.
  String count(
    int n, {
    required String one,
    required String many,
    required ArNoun ar,
  }) => isAr ? ar.of(n) : (n == 1 ? '1 $one' : '$n $many');

  /// True when the screen is in Arabic.
  bool get isAr => Localizations.localeOf(this).languageCode == 'ar';
}
