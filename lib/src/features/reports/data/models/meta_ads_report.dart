import 'report_json.dart';

/// The Meta Ads report (`jarz_pos.api.meta_ads.get_ads_report`): spend,
/// delivery and purchases per campaign, ad set or ad for a date range, read
/// from the Meta Marketing API, next to the ERP's own count of the orders that
/// came from each ad (submitted invoices whose last-click UTM names the ad).
///
/// Meta's purchase count credits every placed web order, cancelled ones too,
/// so the `erp*` figures are the ground truth and the screen shows both.
class MetaAdsReport {
  /// False when the backend has no ads token: rows are empty and the screen
  /// shows a "not configured" state instead of an error.
  final bool configured;
  final MetaAdsLevel level;
  final String dateFrom;
  final String dateTo;
  final String currency;

  /// When the backend pulled the figures from Meta (server time, as sent).
  final String fetchedAt;
  final MetaAdsMetrics totals;
  final List<MetaAdsRow> rows;
  final List<MetaAdsFilterOption> campaigns;
  final List<MetaAdsFilterOption> adsets;

  /// Short English caveats from the backend, shown as-is.
  final List<String> notes;

  /// Every retail sale in the range against all Meta spend. Account-wide:
  /// it ignores the campaign / ad set filters and the level.
  final MetaAdsBlended blended;

  const MetaAdsReport({
    this.configured = true,
    this.level = MetaAdsLevel.ad,
    this.dateFrom = '',
    this.dateTo = '',
    this.currency = 'EGP',
    this.fetchedAt = '',
    this.totals = const MetaAdsMetrics(),
    this.rows = const [],
    this.campaigns = const [],
    this.adsets = const [],
    this.notes = const [],
    this.blended = const MetaAdsBlended(),
  });

  factory MetaAdsReport.fromJson(JsonMap json) {
    final filters = ReportJson.map(json['filters']);
    return MetaAdsReport(
      configured: ReportJson.boolean(json['configured'], true),
      level: MetaAdsLevel.parse(json['level']),
      dateFrom: ReportJson.str(json['date_from']),
      dateTo: ReportJson.str(json['date_to']),
      currency: ReportJson.str(json['currency'], 'EGP'),
      fetchedAt: ReportJson.str(json['fetched_at']),
      totals: MetaAdsMetrics.fromJson(ReportJson.map(json['totals'])),
      rows: ReportJson.listOf(json['rows'], MetaAdsRow.fromJson),
      campaigns: ReportJson.listOf(
        filters['campaigns'],
        MetaAdsFilterOption.fromJson,
      ),
      adsets: ReportJson.listOf(filters['adsets'], MetaAdsFilterOption.fromJson),
      notes: ReportJson.strings(json['notes']),
      blended: MetaAdsBlended.fromJson(ReportJson.map(json['blended'])),
    );
  }
}

/// The `blended` block: every website and shop/chat sale in the period
/// against total Meta spend. A backend that predates it (key missing or null)
/// reads as all zeros with no groups.
class MetaAdsBlended {
  final double spend;
  final int orders;
  final double revenue;
  final double roas;
  final double avgOrderValue;

  /// Groups counted in [revenue] (`website`, `pos`), in the backend's order.
  final List<MetaAdsBlendedGroup> included;

  /// Groups left out (`whatsapp_followup`, `b2b`, `staff`, `samples`,
  /// `talabat`, `partner`), in the backend's order.
  final List<MetaAdsBlendedGroup> excluded;

  const MetaAdsBlended({
    this.spend = 0,
    this.orders = 0,
    this.revenue = 0,
    this.roas = 0,
    this.avgOrderValue = 0,
    this.included = const [],
    this.excluded = const [],
  });

  factory MetaAdsBlended.fromJson(JsonMap j) => MetaAdsBlended(
    spend: ReportJson.dbl(j['spend']),
    orders: ReportJson.integer(j['orders']),
    revenue: ReportJson.dbl(j['revenue']),
    roas: ReportJson.dbl(j['roas']),
    avgOrderValue: ReportJson.dbl(j['avg_order_value']),
    included: ReportJson.listOf(j['included'], MetaAdsBlendedGroup.fromJson)
        .where((g) => g.group.isNotEmpty)
        .toList(),
    excluded: ReportJson.listOf(j['excluded'], MetaAdsBlendedGroup.fromJson)
        .where((g) => g.group.isNotEmpty)
        .toList(),
  );

  /// True when there is nothing to break down (old backend or empty range).
  bool get hasGroups => included.isNotEmpty || excluded.isNotEmpty;
}

/// One row of `blended.included` / `blended.excluded`.
class MetaAdsBlendedGroup {
  /// The backend key, lower-cased: `website`, `pos`, `whatsapp_followup`,
  /// `b2b`, `staff`, `samples`, `talabat`, `partner`.
  final String group;
  final int orders;
  final double revenue;

  const MetaAdsBlendedGroup({
    required this.group,
    this.orders = 0,
    this.revenue = 0,
  });

  factory MetaAdsBlendedGroup.fromJson(JsonMap j) => MetaAdsBlendedGroup(
    group: ReportJson.str(j['group']).trim().toLowerCase(),
    orders: ReportJson.integer(j['orders']),
    revenue: ReportJson.dbl(j['revenue']),
  );
}

/// The entity the rows describe. [apiValue] is what the endpoint's `level`
/// argument and response carry.
enum MetaAdsLevel {
  campaign('campaign'),
  adset('adset'),
  ad('ad');

  const MetaAdsLevel(this.apiValue);
  final String apiValue;

  /// The level a row at this level drills into, or null at the bottom.
  MetaAdsLevel? get child => switch (this) {
    MetaAdsLevel.campaign => MetaAdsLevel.adset,
    MetaAdsLevel.adset => MetaAdsLevel.ad,
    MetaAdsLevel.ad => null,
  };

  /// Unknown or missing → [MetaAdsLevel.ad], the endpoint's default.
  static MetaAdsLevel parse(Object? v) {
    final s = ReportJson.str(v).toLowerCase();
    for (final l in values) {
      if (l.apiValue == s) return l;
    }
    return MetaAdsLevel.ad;
  }
}

/// The metric block shared by `totals` and every row. The contract promises
/// numbers that are never null (0 when there is no data), but every reader
/// still tolerates null, strings and int-vs-double.
class MetaAdsMetrics {
  final double spend;
  final int impressions;
  final int reach;
  final double frequency;
  final int linkClicks;

  /// Link CTR in percent (Meta's `inline_link_click_ctr`), e.g. 1.23.
  final double ctr;
  final double cpc;
  final double cpm;

  /// Meta-attributed purchases. A double: Meta can report fractional
  /// conversions under some attribution settings.
  final double purchases;
  final double purchaseValue;
  final double roas;
  final double costPerPurchase;
  final int erpOrders;
  final double erpRevenue;
  final double erpRoas;

  const MetaAdsMetrics({
    this.spend = 0,
    this.impressions = 0,
    this.reach = 0,
    this.frequency = 0,
    this.linkClicks = 0,
    this.ctr = 0,
    this.cpc = 0,
    this.cpm = 0,
    this.purchases = 0,
    this.purchaseValue = 0,
    this.roas = 0,
    this.costPerPurchase = 0,
    this.erpOrders = 0,
    this.erpRevenue = 0,
    this.erpRoas = 0,
  });

  factory MetaAdsMetrics.fromJson(JsonMap j) => MetaAdsMetrics(
    spend: ReportJson.dbl(j['spend']),
    impressions: ReportJson.integer(j['impressions']),
    reach: ReportJson.integer(j['reach']),
    frequency: ReportJson.dbl(j['frequency']),
    linkClicks: ReportJson.integer(j['link_clicks']),
    ctr: ReportJson.dbl(j['ctr']),
    cpc: ReportJson.dbl(j['cpc']),
    cpm: ReportJson.dbl(j['cpm']),
    purchases: ReportJson.dbl(j['purchases']),
    purchaseValue: ReportJson.dbl(j['purchase_value']),
    roas: ReportJson.dbl(j['roas']),
    costPerPurchase: ReportJson.dbl(j['cost_per_purchase']),
    erpOrders: ReportJson.integer(j['erp_orders']),
    erpRevenue: ReportJson.dbl(j['erp_revenue']),
    erpRoas: ReportJson.dbl(j['erp_roas']),
  );
}

/// One campaign, ad set or ad with its metrics.
class MetaAdsRow {
  final String id;
  final String name;

  /// Meta's `effective_status`-style value, e.g. `ACTIVE`, `PAUSED`.
  final String status;
  final String campaignId;
  final String campaignName;

  /// Null at campaign level.
  final String? adsetId;
  final String? adsetName;

  /// Ad level only; null otherwise or when Meta has no creative preview.
  final String? thumbnailUrl;
  final MetaAdsMetrics metrics;

  const MetaAdsRow({
    this.id = '',
    this.name = '',
    this.status = '',
    this.campaignId = '',
    this.campaignName = '',
    this.adsetId,
    this.adsetName,
    this.thumbnailUrl,
    this.metrics = const MetaAdsMetrics(),
  });

  factory MetaAdsRow.fromJson(JsonMap j) {
    final id = ReportJson.str(j['id']);
    return MetaAdsRow(
      id: id,
      name: ReportJson.str(j['name'], id),
      status: ReportJson.str(j['status']).toUpperCase(),
      campaignId: ReportJson.str(j['campaign_id']),
      campaignName: ReportJson.str(j['campaign_name']),
      adsetId: ReportJson.strOrNull(j['adset_id']),
      adsetName: ReportJson.strOrNull(j['adset_name']),
      thumbnailUrl: ReportJson.strOrNull(j['thumbnail_url']),
      metrics: MetaAdsMetrics.fromJson(j),
    );
  }
}

/// An entry of `filters.campaigns` / `filters.adsets`.
class MetaAdsFilterOption {
  final String id;
  final String name;
  final String status;

  /// Set on ad sets only.
  final String? campaignId;

  const MetaAdsFilterOption({
    required this.id,
    this.name = '',
    this.status = '',
    this.campaignId,
  });

  factory MetaAdsFilterOption.fromJson(JsonMap j) {
    final id = ReportJson.str(j['id']);
    return MetaAdsFilterOption(
      id: id,
      name: ReportJson.str(j['name'], id),
      status: ReportJson.str(j['status']).toUpperCase(),
      campaignId: ReportJson.strOrNull(j['campaign_id']),
    );
  }
}

/// The metrics the row list can be sorted by.
enum MetaAdsSort {
  spend,
  purchases,
  roas,
  ctr,
  costPerPurchase,
  erpOrders;

  /// Cost per purchase is the one metric where lower is better.
  bool get ascending => this == MetaAdsSort.costPerPurchase;

  double valueOf(MetaAdsMetrics m) => switch (this) {
    MetaAdsSort.spend => m.spend,
    MetaAdsSort.purchases => m.purchases,
    MetaAdsSort.roas => m.roas,
    MetaAdsSort.ctr => m.ctr,
    MetaAdsSort.costPerPurchase => m.costPerPurchase,
    MetaAdsSort.erpOrders => m.erpOrders.toDouble(),
  };
}

/// [rows] ordered by [sort], best first. Ties fall back to spend (desc), then
/// name, so the order is stable between refreshes.
///
/// For cost per purchase, a row with no purchases reports 0 (the backend's
/// "denominator is 0" rule); that is not the cheapest row, so those go last.
List<MetaAdsRow> sortMetaAdsRows(List<MetaAdsRow> rows, MetaAdsSort sort) {
  int byTieBreak(MetaAdsRow a, MetaAdsRow b) {
    final s = b.metrics.spend.compareTo(a.metrics.spend);
    return s != 0 ? s : a.name.compareTo(b.name);
  }

  final sorted = [...rows];
  sorted.sort((a, b) {
    final va = sort.valueOf(a.metrics);
    final vb = sort.valueOf(b.metrics);
    if (sort == MetaAdsSort.costPerPurchase) {
      final aNone = va <= 0;
      final bNone = vb <= 0;
      if (aNone != bNone) return aNone ? 1 : -1;
    }
    final c = sort.ascending ? va.compareTo(vb) : vb.compareTo(va);
    return c != 0 ? c : byTieBreak(a, b);
  });
  return sorted;
}
