/// The four Studio roles (Frappe role names) and what each one sees first.
enum StudioRole {
  founder('Studio Founder'),
  lead('Studio Marketing Lead'),
  creator('Studio Creator'),
  story('Studio Story Lead');

  const StudioRole(this.frappeName);

  final String frappeName;

  static StudioRole? fromFrappe(String name) {
    for (final r in StudioRole.values) {
      if (r.frappeName == name) return r;
    }
    return null;
  }

  /// The role whose layout wins when a user holds several.
  static StudioRole? primaryOf(Iterable<String> frappeRoles) {
    final held = frappeRoles.map(fromFrappe).whereType<StudioRole>().toSet();
    for (final r in StudioRole.values) {
      if (held.contains(r)) return r;
    }
    return null;
  }
}

/// One block on the Today screen (SYSTEM_DESIGN section 6).
enum TodayBlock {
  sentBack,
  dueToday,
  blocked,
  readyToPost,
  stories,
  readsMissing,
  didntGoOut,
  warnings,
}

/// One entry of the More list.
enum MoreItem { shoots, assets, references, paid, results, reports, settings }

/// Today's block order per role. A block a role never acts on is left out.
const Map<StudioRole, List<TodayBlock>> todayOrder = {
  StudioRole.founder: [
    TodayBlock.readyToPost,
    TodayBlock.didntGoOut,
    TodayBlock.readsMissing,
    TodayBlock.warnings,
    TodayBlock.dueToday,
    TodayBlock.sentBack,
    TodayBlock.stories,
  ],
  StudioRole.lead: [
    TodayBlock.blocked,
    TodayBlock.dueToday,
    TodayBlock.sentBack,
    TodayBlock.didntGoOut,
    TodayBlock.warnings,
    TodayBlock.readyToPost,
    TodayBlock.readsMissing,
    TodayBlock.stories,
  ],
  StudioRole.creator: [
    TodayBlock.sentBack,
    TodayBlock.dueToday,
    TodayBlock.readyToPost,
    TodayBlock.readsMissing,
  ],
  StudioRole.story: [
    TodayBlock.stories,
    TodayBlock.sentBack,
    TodayBlock.dueToday,
  ],
};

/// The More list per role. Paid is the founder's screen and Ali reads it;
/// Settings is the founder's.
const Map<StudioRole, List<MoreItem>> moreOrder = {
  StudioRole.founder: [
    MoreItem.shoots,
    MoreItem.assets,
    MoreItem.references,
    MoreItem.paid,
    MoreItem.results,
    MoreItem.reports,
    MoreItem.settings,
  ],
  StudioRole.lead: [
    MoreItem.shoots,
    MoreItem.results,
    MoreItem.reports,
    MoreItem.assets,
    MoreItem.references,
    MoreItem.paid,
  ],
  StudioRole.creator: [
    MoreItem.shoots,
    MoreItem.assets,
    MoreItem.references,
    MoreItem.results,
  ],
  StudioRole.story: [MoreItem.assets, MoreItem.shoots, MoreItem.references],
};
