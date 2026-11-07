import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/network/user_service.dart';
import '../../../core/widgets/app_drawer.dart';
import '../state/base_production_providers.dart';
import '../state/daily_plan_providers.dart';
import '../state/production_basket_notifier.dart';
import '../state/production_providers.dart';
import '../state/running_batches_notifier.dart';
import 'screens/base_production_tab.dart';
import 'screens/production_plan_tab.dart';
import 'screens/production_running_tab.dart';
import 'widgets/recent_work_orders_sheet.dart';

/// The Production Board.
///
/// A thin three-tab host: Plan is the day — the jar list, what is running low,
/// and both of the day's actions — Bases makes the sub-assemblies the jars are
/// built from, and Running holds what is on the floor right now. It was five
/// tabs until Daily, Plan and Batch merged: they were one thought split three
/// ways, with the target on one, the ranking on the next and the queue on the
/// third. All the state lives in providers, so every tab stays independently
/// loadable and the basket survives navigation.
class ManufacturingScreen extends ConsumerStatefulWidget {
  const ManufacturingScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<ManufacturingScreen> createState() =>
      _ManufacturingScreenState();
}

class _ManufacturingScreenState extends ConsumerState<ManufacturingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: kProductionTabCount,
      vsync: this,
      // Deep-linked (`/manufacturing?tab=N`), and the board has had five tabs
      // and now has three, so an index from an older link is mapped into range
      // rather than thrown.
      initialIndex: productionTabForDeepLink(widget.initialTab),
    );
    // Hive opens asynchronously, so the basket is hydrated after first frame
    // rather than in the notifier's build().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(productionBasketProvider.notifier).restore();
      // A tab request left set while no host was listening would otherwise
      // deaden the next one: `ref.listen` does not replay the current value on
      // subscribe, and re-assigning the same int notifies nobody
      // (`identical(2, 2)`), so "View batch" would be dead for the rest of the
      // app process. Clearing on mount keeps the one-shot one-shot.
      ref.read(productionTabRequestProvider.notifier).state = null;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Role-derived and synchronous. The old screen gated on
    // `managerAccessProvider`, which fires a manager-dashboard request on every
    // open and admits roles the production API rejects — so a user could see
    // the screen and then fail every call on it.
    final allowed = ref.watch(canAccessProductionBoardProvider);
    if (!allowed) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.productionBoardTitle)),
        drawer: const AppDrawer(),
        body: Center(child: Text(l10n.productionAccessDenied)),
      );
    }

    final basket = ref.watch(productionBasketProvider);
    final isNarrow = MediaQuery.sizeOf(context).width < 420;
    final runningCount =
        ref.watch(runningBatchesProvider).valueOrNull?.length ?? 0;

    // The Plan tab and the Bases card ask to be moved to Running once a start
    // succeeds — the batch has physically left the queue at that point, so
    // leaving the user staring at the list it just emptied reads as "nothing
    // happened".
    ref.listen<int?>(productionTabRequestProvider, (_, next) {
      if (next == null) return;
      if (next >= 0 && next < _tabController.length) {
        _tabController.animateTo(next);
      }
      // Cleared immediately so the same request cannot fire twice.
      ref.read(productionTabRequestProvider.notifier).state = null;
    });

    return Scaffold(
      appBar: AppBar(
        // A phone gives the title ~190 dp beside a menu and three actions,
        // and "Production Board" at the default 20 sp needs more than that —
        // it rendered as "Production Bo…". One step down the type scale fits
        // the whole name, which is worth more here than two points of size.
        title: Text(
          l10n.productionBoardTitle,
          style: isNarrow ? Theme.of(context).textTheme.titleMedium : null,
        ),
        actions: [
          IconButton(
            tooltip: l10n.manufacturingRecentWorkOrdersTooltip,
            icon: const Icon(Icons.history),
            onPressed: () => showRecentWorkOrders(context, ref),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
            icon: const Icon(Icons.refresh),
            onPressed: _refreshVisibleTab,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          // Fixed, not scrollable. Five tabs divided a 360 dp phone into 72 dp
          // each and "Running" plus its count badge needed 79, so the two
          // badged labels were the ones that got clipped and the bar had to
          // scroll below 420 dp. Three tabs get 120 dp each on the same phone,
          // which fits every label and both badges — and a bar that does not
          // scroll is one where every tab is visible without a swipe.
          tabs: [
            Tab(
              child: _TabLabel(
                text: l10n.productionTabPlan,
                count: basket.isNotEmpty ? basket.lines.length : 0,
              ),
            ),
            Tab(text: l10n.productionTabBases),
            Tab(
              child: _TabLabel(
                text: l10n.productionTabRunning,
                count: runningCount,
              ),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ProductionPlanTab(),
          BaseProductionTab(),
          ProductionRunningTab(),
        ],
      ),
    );
  }

  /// Refreshes whichever list is on screen rather than everything.
  ///
  /// Recomputing the ranked board costs a BOM explosion per item server-side,
  /// so firing it while the user is looking at running batches is a slow answer
  /// to a question nobody asked.
  void _refreshVisibleTab() {
    // The policy is keep-alive, so a single failed probe would otherwise pin
    // this tablet to today-only for the rest of the app process — silently,
    // since every consumer falls back rather than showing the error. Refresh
    // is the one gesture a user already makes when a screen looks wrong, so a
    // failure costs one tap instead of a restart. A successful policy is left
    // alone: it does not change while a batch is being queued.
    unawaited(refreshProductionPolicy(ref));

    switch (_tabController.index) {
      case kProductionRunningTabIndex:
        ref.read(runningBatchesProvider.notifier).refresh();
      case kProductionBasesTabIndex:
        ref.read(baseItemsProvider.notifier).refresh();
      default:
        // Both halves of the Plan tab, because it now asks both questions: the
        // ranked board for the cover figures and the plan template for the
        // flavour list and the mixer.
        ref.invalidate(dailyPlanTemplateProvider);
        ref.read(productionSuggestionsProvider.notifier).refresh();
    }
  }
}

/// A tab label with an optional count badge.
///
/// The label is [Flexible] rather than a bare `Text`: three fixed tabs give a
/// 360 dp phone about 88 dp each, and "Running" plus a two-digit badge lands
/// within a few pixels of that in the widest of the two languages. An ellipsis
/// on the rare overflow is worth more than making the whole bar scroll — a
/// scrolling bar hides a tab behind a swipe on every screen, to protect against
/// a case that only arises when a badge is showing.
class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.text, required this.count});

  final String text;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(text, softWrap: false, overflow: TextOverflow.ellipsis),
        ),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Badge(label: Text('$count')),
        ],
      ],
    );
  }
}
