import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/network/user_service.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/localization/localization_extensions.dart';
import 'widgets/report_states.dart';

/// The Reports hub: report tiles grouped into sections (Overview, Daily
/// operations, Sales & customers, Stock, People). Every tile is a go_router
/// route opened with `context.push`, so each report keeps a back button and
/// the router's role guard applies to deep links too.
///
/// Velocity, Segments and the Executive overview were merged into Inventory,
/// Customers and the P&L "Business overview"; the B2B report moved to the
/// B2B pipeline's app bar.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rolesAsync = ref.watch(userRolesFutureProvider);
    final roles = rolesAsync.valueOrNull;

    // Every tile is gated on the role set its own endpoint accepts (mirrored
    // by `resolveReportsRedirect` in the router). The analytics dashboards
    // call `_ensure_jarz_manager` (JARZ Manager or Administrator — NOT System
    // Manager, NOT POS Manager); Materials and the three daily-operations
    // reports take the whole line-manager tier; Warehouse alignment takes the
    // manager-dashboard tier. Gating a tile on anything wider is how it ends
    // up answering "Not permitted" on every tap.
    final all = roles?.canViewAllReports ?? false;
    final lineTier = roles?.canViewMaterialsReport ?? false;
    final managerTier = roles?.canAccessManagerDashboard ?? false;
    final metaAds = roles?.canViewMetaAds ?? false;

    void go(String route) => context.push(route);

    final sections = <_HubSection>[
      _HubSection(l10n.rptHubOverview, [
        _ReportDestination(
          icon: Icons.insights,
          color: Colors.blue.shade800,
          title: l10n.rptRevenueDashboardTitle,
          subtitle: l10n.rptRevenueDashboardSubtitle,
          onTap: () => go(AppRoutes.reportsRevenueDashboard),
          visible: all,
        ),
        _ReportDestination(
          icon: Icons.account_balance_outlined,
          color: Colors.green.shade800,
          title: l10n.rptBusinessOverviewTitle,
          subtitle: l10n.rptBusinessOverviewSubtitle,
          onTap: () => go(AppRoutes.reportsProfitLoss),
          visible: all,
        ),
        _ReportDestination(
          icon: Icons.calculate_outlined,
          color: Colors.indigo.shade700,
          title: l10n.rptUnitEconomicsTitle,
          subtitle: l10n.rptUnitEconomicsSubtitle,
          onTap: () => go(AppRoutes.reportsUnitEconomics),
          visible: all,
        ),
      ]),
      _HubSection(l10n.rptHubDailyOps, [
        _ReportDestination(
          icon: Icons.point_of_sale_outlined,
          color: Colors.blue.shade700,
          title: l10n.rptDailyCloseTitle,
          subtitle: l10n.rptDailyCloseSubtitle,
          onTap: () => go(AppRoutes.reportsDailyClose),
          visible: lineTier,
        ),
        _ReportDestination(
          icon: Icons.price_check_outlined,
          color: Colors.amber.shade800,
          title: l10n.rptCashOverShortTitle,
          subtitle: l10n.rptCashOverShortSubtitle,
          onTap: () => go(AppRoutes.reportsCashOverShort),
          visible: lineTier,
        ),
        _ReportDestination(
          icon: Icons.timer_outlined,
          color: Colors.cyan.shade800,
          title: l10n.rptFulfilmentSlaTitle,
          subtitle: l10n.rptFulfilmentSlaSubtitle,
          onTap: () => go(AppRoutes.reportsFulfilmentSla),
          visible: lineTier,
        ),
      ]),
      _HubSection(l10n.rptHubSalesCustomers, [
        _ReportDestination(
          icon: Icons.category_outlined,
          color: Colors.deepPurple,
          title: l10n.reportProductTitle,
          subtitle: l10n.reportProductSubtitle,
          onTap: () => go(AppRoutes.reportsProduct),
          visible: all,
        ),
        _ReportDestination(
          icon: Icons.groups_outlined,
          color: Colors.orange.shade800,
          title: l10n.rptCustomersSegmentsTitle,
          subtitle: l10n.rptCustomersSegmentsSubtitle,
          onTap: () => go(AppRoutes.reportsCustomer),
          visible: all,
        ),
        _ReportDestination(
          icon: Icons.local_offer_outlined,
          color: Colors.pink.shade600,
          title: l10n.rptPromoTitle,
          subtitle: l10n.rptPromoSubtitle,
          onTap: () => go(AppRoutes.reportsPromo),
          visible: all,
        ),
        // Wider than the analytics tiles on purpose: `meta_ads.get_ads_report`
        // also admits System Manager and the media buyer's Meta CAPI Manager,
        // who sees this one tile and nothing else in the hub.
        _ReportDestination(
          icon: Icons.campaign_outlined,
          color: Colors.blue.shade600,
          title: l10n.metaAdsTitle,
          subtitle: l10n.metaAdsSubtitle,
          onTap: () => go(AppRoutes.reportsMetaAds),
          visible: metaAds,
        ),
        _ReportDestination(
          icon: Icons.local_shipping_outlined,
          color: Colors.indigo,
          title: l10n.rptShippingCouriersTitle,
          subtitle: l10n.rptShippingCouriersSubtitle,
          onTap: () => go(AppRoutes.reportsShipping),
          visible: all,
        ),
      ]),
      _HubSection(l10n.rptHubStock, [
        _ReportDestination(
          icon: Icons.inventory_2_outlined,
          color: Colors.teal,
          title: l10n.rptInventoryRestockTitle,
          subtitle: l10n.rptInventoryRestockSubtitle,
          onTap: () => go(AppRoutes.reportsInventory),
          visible: all,
        ),
        _ReportDestination(
          icon: Icons.widgets_outlined,
          color: Colors.green,
          title: l10n.reportsFinalProducts,
          subtitle: l10n.reportsFinalProductsDesc,
          onTap: () => go(AppRoutes.reportsFinalProducts),
          visible: all,
        ),
        _ReportDestination(
          icon: Icons.science_outlined,
          color: Colors.blue,
          title: l10n.reportsMaterials,
          subtitle: l10n.reportsMaterialsDesc,
          onTap: () => go(AppRoutes.reportsMaterials),
          visible: lineTier,
        ),
        _ReportDestination(
          icon: Icons.delete_sweep_outlined,
          color: Colors.red.shade700,
          title: l10n.rptStockAdjustmentsTitle,
          subtitle: l10n.rptStockAdjustmentsSubtitle,
          onTap: () => go(AppRoutes.reportsStockAdjustments),
          visible: all,
        ),
        // Wider than the analytics tiles on purpose: the backend widened this
        // report to the manager-dashboard tier so branch managers can watch
        // their own drift. The repair action is deliberately not reachable.
        _ReportDestination(
          icon: Icons.warehouse_outlined,
          color: Colors.teal.shade700,
          title: l10n.warehouseAlignTitle,
          subtitle: l10n.warehouseAlignSubtitle,
          onTap: () => go(AppRoutes.reportsWarehouseAlignment),
          visible: managerTier,
        ),
      ]),
      _HubSection(l10n.rptHubPeople, [
        _ReportDestination(
          icon: Icons.badge_outlined,
          color: Colors.brown,
          title: l10n.rptLabourCostTitle,
          subtitle: l10n.rptLabourCostSubtitle,
          onTap: () => go(AppRoutes.reportsLabourCost),
          visible: all,
        ),
      ]),
    ];

    final visibleSections = [
      for (final s in sections)
        if (s.visible.isNotEmpty) s,
    ];

    Widget body;
    if (roles == null && rolesAsync.hasError) {
      body = RefreshIndicator(
        onRefresh: () => ref.refresh(userRolesFutureProvider.future),
        child: ReportErrorView(
          error: rolesAsync.error,
          onRetry: () => ref.invalidate(userRolesFutureProvider),
        ),
      );
    } else if (roles == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (visibleSections.isEmpty) {
      body = ReportEmptyView(message: l10n.rptAccessDenied, icon: Icons.lock_outline);
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) {
          final crossCount =
              ResponsiveUtils.getGridColumns(context, min: 1, max: 4);
          const spacing = 12.0;
          final cardWidth =
              (constraints.maxWidth - 16 - spacing * (crossCount - 1)) /
                  crossCount;
          return ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 16),
            children: [
              for (final s in visibleSections) ...[
                _SectionHeader(title: s.title),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final d in s.visible)
                      SizedBox(
                        width: cardWidth,
                        child: _ReportCard(destination: d),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: body,
    );
  }
}

class _HubSection {
  final String title;
  final List<_ReportDestination> destinations;

  const _HubSection(this.title, this.destinations);

  List<_ReportDestination> get visible =>
      destinations.where((d) => d.visible).toList(growable: false);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 12, 4, 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ReportDestination {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Whether the current user's roles satisfy this report's own backend gate.
  final bool visible;

  const _ReportDestination({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.visible,
  });
}

class _ReportCard extends StatelessWidget {
  final _ReportDestination destination;
  const _ReportCard({required this.destination});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: destination.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsetsDirectional.all(10),
                decoration: BoxDecoration(
                  color: destination.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(destination.icon, color: destination.color),
              ),
              const SizedBox(height: 12),
              Text(
                destination.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                destination.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
