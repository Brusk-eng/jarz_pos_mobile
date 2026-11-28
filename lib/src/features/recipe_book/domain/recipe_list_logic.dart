/// Pure list logic for the Recipe Book: which recipes the chips and the search
/// show, how jar sizes collapse into one family row, and how the rows group
/// into category sections. No Flutter imports, so every rule is unit-tested.
library;

import '../data/recipe_book_models.dart';

/// The chip row: All, then one chip per category, then Trials.
enum RecipeFilter { all, bases, fillings, jars, trials }

/// The category a category chip stands for; null for All and Trials.
String? categoryOfFilter(RecipeFilter filter) => switch (filter) {
  RecipeFilter.bases => RecipeCategory.bases,
  RecipeFilter.fillings => RecipeCategory.fillings,
  RecipeFilter.jars => RecipeCategory.jars,
  _ => null,
};

/// One row of the list: a single recipe, or a whole jar family.
sealed class RecipeListEntry {
  const RecipeListEntry();

  String get title;
  String get category;

  /// A trial exists (the recipe is one, or runs one alongside).
  bool get isTrialish;
}

/// A normal row. Also a jar with no size ("Cookie jar second bake").
class RecipeRowEntry extends RecipeListEntry {
  const RecipeRowEntry(this.recipe);

  final RecipeSummary recipe;

  @override
  String get title => recipe.title;

  @override
  String get category => recipe.effectiveCategory;

  @override
  bool get isTrialish => recipe.isTrialish;
}

/// A jar flavour: one row for every size of it.
class RecipeFamilyEntry extends RecipeListEntry {
  const RecipeFamilyEntry({
    required this.family,
    required this.sizes,
    required this.members,
    this.track,
  });

  final String family;
  final String? track;

  /// Sizes present, Small → Large.
  final List<String> sizes;
  final List<RecipeSummary> members;

  @override
  String get title => family;

  @override
  String get category => RecipeCategory.jars;

  @override
  bool get isTrialish => members.any((m) => m.isTrialish);
}

/// One section header and its rows.
typedef RecipeSection = ({String category, List<RecipeListEntry> entries});

int _sizeRank(String size) {
  final i = kJarSizes.indexOf(size);
  return i < 0 ? kJarSizes.length : i;
}

/// Jar recipes that have a family fold into one [RecipeFamilyEntry] each
/// (placed where the family first appears); everything else stays a row.
List<RecipeListEntry> collapseJarFamilies(List<RecipeSummary> recipes) {
  final entries = <RecipeListEntry?>[];
  final familyAt = <String, int>{};
  final members = <String, List<RecipeSummary>>{};
  final names = <String, String>{};
  for (final r in recipes) {
    final family = r.family?.trim();
    final isJarWithFamily =
        r.effectiveCategory == RecipeCategory.jars &&
        family != null &&
        family.isNotEmpty;
    if (!isJarWithFamily) {
      entries.add(RecipeRowEntry(r));
      continue;
    }
    final key = family.toLowerCase();
    if (!familyAt.containsKey(key)) {
      familyAt[key] = entries.length;
      entries.add(null); // filled below, once every member is known
      names[key] = family;
    }
    members.putIfAbsent(key, () => <RecipeSummary>[]).add(r);
  }
  for (final e in familyAt.entries) {
    final list = members[e.key]!;
    final sizes = <String>{
      for (final m in list)
        if (m.size != null && m.size!.isNotEmpty) m.size!,
    }.toList()..sort((a, b) => _sizeRank(a).compareTo(_sizeRank(b)));
    String? track;
    for (final m in list) {
      if (m.track != null) {
        track = m.track;
        break;
      }
    }
    entries[e.value] = RecipeFamilyEntry(
      family: names[e.key]!,
      track: track,
      sizes: sizes,
      members: list,
    );
  }
  return [
    for (final e in entries)
      if (e != null) e,
  ];
}

List<String> _words(String query) => query
    .toLowerCase()
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .toList();

String _haystack(RecipeListEntry entry) {
  switch (entry) {
    case RecipeRowEntry(:final recipe):
      return [
        recipe.title,
        recipe.family ?? '',
        recipe.size ?? '',
        recipe.itemCode ?? '',
      ].join(' ').toLowerCase();
    case RecipeFamilyEntry():
      return [
        entry.family,
        ...entry.sizes,
        for (final m in entry.members) m.title,
      ].join(' ').toLowerCase();
  }
}

bool _matchesFilter(RecipeListEntry entry, RecipeFilter filter) {
  final category = categoryOfFilter(filter);
  if (category != null) return entry.category == category;
  if (filter == RecipeFilter.trials) return entry.isTrialish;
  return true;
}

/// The rows to show for [filter] and [query], grouped into category sections
/// in bases → fillings → jars order (empty sections dropped).
///
/// Search: every word must appear in the title, the family name or the size.
/// Jars fold into one row per family before filtering, so a family is shown
/// when any of its sizes matches. Inside Jars, rows sort by name; elsewhere
/// the server's order (track, then title) is kept.
List<RecipeSection> buildRecipeSections(
  List<RecipeSummary> recipes, {
  String query = '',
  RecipeFilter filter = RecipeFilter.all,
}) {
  final words = _words(query);
  final visible = [
    for (final e in collapseJarFamilies(recipes))
      if (_matchesFilter(e, filter) && words.every(_haystack(e).contains)) e,
  ];
  final sections = <RecipeSection>[];
  for (final category in RecipeCategory.order) {
    final entries = [
      for (final e in visible)
        if (e.category == category) e,
    ];
    if (entries.isEmpty) continue;
    if (category == RecipeCategory.jars) {
      entries.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }
    sections.add((category: category, entries: entries));
  }
  return sections;
}

/// How many rows [sections] hold.
int sectionEntryCount(List<RecipeSection> sections) =>
    sections.fold(0, (sum, s) => sum + s.entries.length);
