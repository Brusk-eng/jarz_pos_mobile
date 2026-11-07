import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/meta_ads_report.dart';
import '../data/reports_repository.dart';
import 'reports_providers.dart';

/// What the Meta Ads screen is looking at besides the date range: the level,
/// the campaign / ad set filters and the sort. Value-comparable.
@immutable
class MetaAdsFilters {
  final MetaAdsLevel level;
  final String? campaignId;
  final String? adsetId;
  final MetaAdsSort sort;

  const MetaAdsFilters({
    this.level = MetaAdsLevel.ad,
    this.campaignId,
    this.adsetId,
    this.sort = MetaAdsSort.spend,
  });

  MetaAdsFilters copyWith({
    MetaAdsLevel? level,
    String? campaignId,
    String? adsetId,
    MetaAdsSort? sort,
    bool clearCampaign = false,
    bool clearAdset = false,
  }) =>
      MetaAdsFilters(
        level: level ?? this.level,
        campaignId: clearCampaign ? null : (campaignId ?? this.campaignId),
        adsetId: clearAdset ? null : (adsetId ?? this.adsetId),
        sort: sort ?? this.sort,
      );

  @override
  bool operator ==(Object other) =>
      other is MetaAdsFilters &&
      other.level == level &&
      other.campaignId == campaignId &&
      other.adsetId == adsetId &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(level, campaignId, adsetId, sort);
}

/// The filter rules, kept here (not in the widgets) so they are testable:
///  - Campaign level shows every campaign, so both filters clear.
///  - Ad set level lists ad sets, so an ad set filter would leave one row:
///    the ad set filter clears, the campaign filter stays.
///  - Ad level keeps both.
///  - Changing the campaign clears the ad set (it belonged to the old one).
///  - Picking an ad set also selects its campaign, so the two dropdowns
///    never disagree.
class MetaAdsFiltersNotifier extends StateNotifier<MetaAdsFilters> {
  MetaAdsFiltersNotifier([super.initial = const MetaAdsFilters()]);

  void setLevel(MetaAdsLevel level) {
    state = switch (level) {
      MetaAdsLevel.campaign => state.copyWith(
        level: level,
        clearCampaign: true,
        clearAdset: true,
      ),
      MetaAdsLevel.adset => state.copyWith(level: level, clearAdset: true),
      MetaAdsLevel.ad => state.copyWith(level: level),
    };
  }

  void setCampaign(String? campaignId) {
    final id = _blankToNull(campaignId);
    if (id == state.campaignId) return;
    state = state.copyWith(
      campaignId: id,
      clearCampaign: id == null,
      clearAdset: true,
    );
  }

  /// [campaignId] is the ad set's own campaign, when known.
  void setAdset(String? adsetId, {String? campaignId}) {
    final id = _blankToNull(adsetId);
    final parent = _blankToNull(campaignId);
    state = state.copyWith(
      adsetId: id,
      clearAdset: id == null,
      campaignId: id == null ? null : parent,
    );
  }

  void setSort(MetaAdsSort sort) => state = state.copyWith(sort: sort);

  /// Tapping a row opens the level below it, filtered to that row: a
  /// campaign opens its ad sets, an ad set opens its ads. Returns false for
  /// an ad (nothing below it).
  bool drillInto(MetaAdsRow row) {
    switch (state.level) {
      case MetaAdsLevel.campaign:
        state = state.copyWith(
          level: MetaAdsLevel.adset,
          campaignId: row.id,
          clearAdset: true,
        );
        return true;
      case MetaAdsLevel.adset:
        // A row without a campaign id keeps the current campaign filter.
        state = state.copyWith(
          level: MetaAdsLevel.ad,
          adsetId: row.id,
          campaignId: _blankToNull(row.campaignId),
        );
        return true;
      case MetaAdsLevel.ad:
        return false;
    }
  }

  static String? _blankToNull(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}

/// Auto-disposed: leaving the screen starts the next visit on the defaults.
final metaAdsFiltersProvider = StateNotifierProvider.autoDispose<
  MetaAdsFiltersNotifier,
  MetaAdsFilters
>((ref) => MetaAdsFiltersNotifier());

/// The family key of [metaAdsReportProvider]: what the endpoint is asked.
/// Sorting is client-side, so it is not part of the key.
@immutable
class MetaAdsQuery {
  final ReportRange range;
  final MetaAdsLevel level;
  final String? campaignId;
  final String? adsetId;

  const MetaAdsQuery({
    required this.range,
    this.level = MetaAdsLevel.ad,
    this.campaignId,
    this.adsetId,
  });

  @override
  bool operator ==(Object other) =>
      other is MetaAdsQuery &&
      other.range == range &&
      other.level == level &&
      other.campaignId == campaignId &&
      other.adsetId == adsetId;

  @override
  int get hashCode => Object.hash(range, level, campaignId, adsetId);

  @override
  String toString() =>
      'MetaAdsQuery(${range.fromIso}..${range.toIso}, ${level.apiValue}, '
      'c=${campaignId ?? '*'}, s=${adsetId ?? '*'})';
}

/// The shared report date range + this screen's filters.
final metaAdsQueryProvider = Provider.autoDispose<MetaAdsQuery>((ref) {
  final f = ref.watch(metaAdsFiltersProvider);
  return MetaAdsQuery(
    range: ref.watch(reportRangeProvider),
    level: f.level,
    campaignId: f.campaignId,
    adsetId: f.adsetId,
  );
});

/// Queries whose next fetch must bypass the server cache (`refresh=1`).
/// Pull-to-refresh marks the query and then refreshes the provider; the
/// provider consumes the mark, so only that one fetch skips the cache.
class MetaAdsRefreshRequests {
  final Set<MetaAdsQuery> _pending = {};

  void mark(MetaAdsQuery q) => _pending.add(q);

  /// Whether [q] was marked; clears the mark.
  bool take(MetaAdsQuery q) => _pending.remove(q);
}

final metaAdsRefreshRequestsProvider = Provider<MetaAdsRefreshRequests>(
  (ref) => MetaAdsRefreshRequests(),
);

final metaAdsReportProvider = FutureProvider.autoDispose
    .family<MetaAdsReport, MetaAdsQuery>((ref, q) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final refresh = ref.read(metaAdsRefreshRequestsProvider).take(q);
  return repo.fetchMetaAdsReport(q, refresh: refresh);
});
