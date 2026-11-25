import 'package:flutter/widgets.dart';

import '../core/l10n/studio_labels.dart';

/// `context.tr('English', 'عربي')`: one line for a short screen text in both
/// languages (the same `tr` the label table uses). New terms go in
/// `core/l10n/GLOSSARY.md` first.
extension StudioTr on BuildContext {
  String tr(String en, String ar) => StudioLabels.of(this).tr(en, ar);
}
