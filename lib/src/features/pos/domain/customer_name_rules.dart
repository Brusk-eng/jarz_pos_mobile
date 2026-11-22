/// Rules for the name typed when a customer is created by hand.
///
/// A duplicate customer was once saved under the name "..." — a placeholder
/// nobody can search for again. A real name has at least one letter.
library;

/// Arabic letters (base block without tatweel / Arabic-Indic digits, the
/// supplement block, presentation forms) and Latin letters (ASCII plus the
/// accented Latin-1 / Extended-A/B ranges).
final RegExp _letter = RegExp(
  '[A-Za-zÀ-ÖØ-öø-ɏ'
  'ؠ-ؿف-يٮ-ٯٱ-ۓە'
  'ۮ-ۯۺ-ۼۿݐ-ݿ'
  'ﭐ-ﴽﵐ-ﷻﹰ-ﻼ]',
);

/// True when [name] holds at least one Arabic or Latin letter.
/// "...", "-", "123", "٣٤٥" and "" are all false.
bool customerNameHasLetter(String? name) =>
    name != null && _letter.hasMatch(name);

/// What is wrong with a typed customer name, if anything.
enum CustomerNameProblem { empty, noLetter }

/// Null when [name] is acceptable.
CustomerNameProblem? customerNameProblem(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return CustomerNameProblem.empty;
  if (!customerNameHasLetter(trimmed)) return CustomerNameProblem.noLetter;
  return null;
}
