import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/core/constants/app_routes.dart';
import 'package:jarz_pos/src/core/network/user_service.dart';
import 'package:jarz_pos/src/features/manufacturing/data/manufacturing_service.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/batch_line.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/daily_plan.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/production_policy.dart';
import 'package:jarz_pos/src/features/manufacturing/data/models/production_suggestion.dart';
import 'package:jarz_pos/src/features/manufacturing/data/repositories/production_basket_repository.dart';
import 'package:jarz_pos/src/features/manufacturing/presentation/manufacturing_screen.dart';
import 'package:jarz_pos/src/features/manufacturing/presentation/screens/base_production_tab.dart';
import 'package:jarz_pos/src/features/manufacturing/presentation/screens/production_plan_tab.dart';
import 'package:jarz_pos/src/features/manufacturing/presentation/screens/production_running_tab.dart';
import 'package:jarz_pos/src/features/manufacturing/state/daily_plan_providers.dart';
import 'package:jarz_pos/src/features/manufacturing/state/production_providers.dart';
import 'package:jarz_pos/src/features/manufacturing/state/running_batches_notifier.dart';

import '../../../helpers/mock_services.dart';

class _FakeBasketRepository implements ProductionBasketRepository {
  @override
  Future<ProductionBasket?> load() async => null;
  @override
  Future<void> save(ProductionBasket basket) async {}
  @override
  Future<void> clear() async {}
}

class _StubSuggestions extends ProductionSuggestionsNotifier {
  _StubSuggestions(this._page);
  final ProductionSuggestionsPage _page;
  @override
  Future<ProductionSuggestionsPage> build() async => _page;
}

/// Everything the three tabs would otherwise fetch, stubbed.
///
/// The Plan tab asks TWO endpoints now — the ranked board and the plan template
/// — so a host test that stubs only one still renders a spinner.
List<Override> _overrides() => [
  canAccessProductionBoardProvider.overrideWithValue(true),
  productionBasketRepositoryProvider.overrideWithValue(_FakeBasketRepository()),
  manufacturingServiceProvider.overrideWithValue(ManufacturingService(MockDio())),
  productionSuggestionsProvider.overrideWith(
    () => _StubSuggestions(
      const ProductionSuggestionsPage(velocityUpdatedOn: '2026-08-01 00:00:00'),
    ),
  ),
  dailyPlanTemplateProvider.overrideWith((ref) async => const DailyPlanTemplate()),
  bomReadinessProvider.overrideWith((ref) async => const BomReadiness(ok: true)),
  productionPolicyProvider.overrideWith(
    (ref) async => ProductionPolicy(serverDate: DateTime(2026, 8, 2)),
  ),
];

Future<void> _pump(WidgetTester tester, {int initialTab = 0}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ManufacturingScreen(initialTab: initialTab),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

/// The board inside a router that also knows the Today route.
///
/// The board and the Today screen are two destinations of one feature, so "can
/// I get from here to there" is a routing question and has to be pumped as one.
/// Today itself is stubbed: this asserts the link, not that screen's content.
Future<void> _pumpRouted(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: AppRoutes.manufacturing,
    routes: [
      GoRoute(
        path: AppRoutes.manufacturing,
        builder: (_, _) => const ManufacturingScreen(),
      ),
      GoRoute(
        path: AppRoutes.productionToday,
        builder: (_, _) => const Scaffold(body: Text('today screen')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(),
      child: MaterialApp.router(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  group('tab index constants', () {
    // Not a tautology: these are agreed on by the host, the Plan tab and the
    // Bases card, and moving a tab without moving all of them is exactly how
    // the Running tab ends up unreachable.
    test('Plan, Bases and Running keep their order inside the tab count', () {
      expect(kProductionPlanTabIndex, 0);
      expect(kProductionPlanTabIndex, lessThan(kProductionBasesTabIndex));
      expect(kProductionBasesTabIndex, lessThan(kProductionRunningTabIndex));
      expect(kProductionRunningTabIndex, lessThan(kProductionTabCount));
    });

    test('a deep link is mapped into range instead of throwing', () {
      // The board had five tabs. A link somebody saved can still name 4.
      expect(productionTabForDeepLink(4), kProductionRunningTabIndex);
      expect(productionTabForDeepLink(kProductionTabCount), kProductionTabCount - 1);
      expect(productionTabForDeepLink(-1), kProductionPlanTabIndex);
      for (var i = 0; i < kProductionTabCount; i++) {
        expect(productionTabForDeepLink(i), i);
      }
    });
  });

  testWidgets('the board reads Plan · Bases · Running', (tester) async {
    await _pump(tester);

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.tabs, hasLength(kProductionTabCount));

    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Bases'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    // The three that merged into Plan are gone from the bar.
    expect(find.text('Daily'), findsNothing);
    expect(find.text('Batch'), findsNothing);

    // Left-to-right order, which is what the index constants encode.
    final xs = <String, double>{
      for (final label in ['Plan', 'Bases', 'Running'])
        label: tester.getCenter(find.text(label)).dx,
    };
    expect(xs['Plan']!, lessThan(xs['Bases']!));
    expect(xs['Bases']!, lessThan(xs['Running']!));
  });

  testWidgets('the board opens on the merged Plan tab', (tester) async {
    await _pump(tester);
    expect(find.byType(ProductionPlanTab), findsOneWidget);
  });

  testWidgets('kProductionBasesTabIndex opens the Bases tab', (tester) async {
    await _pump(tester, initialTab: kProductionBasesTabIndex);
    expect(find.byType(BaseProductionTab), findsOneWidget);
  });

  testWidgets('kProductionRunningTabIndex still opens the Running tab', (
    tester,
  ) async {
    // The index moved 4 → 2 when Daily, Plan and Batch merged. A stale value
    // here means starting a batch drops the operator on the wrong tab.
    await _pump(tester, initialTab: kProductionRunningTabIndex);
    expect(find.byType(ProductionRunningTab), findsOneWidget);
  });

  testWidgets('a deep link past the last tab is clamped, not thrown', (
    tester,
  ) async {
    await _pump(tester, initialTab: 99);
    expect(find.byType(ProductionRunningTab), findsOneWidget);
  });

  testWidgets('the board no longer links to Today', (tester) async {
    // Today was retired on 2026-11-08 (owner: "we don't use it").
    await _pumpRouted(tester);

    expect(find.text('Today'), findsNothing);
    expect(find.byTooltip('Today'), findsNothing);
  });

  testWidgets('the app bar and all three tabs fit a 360 dp phone', (
    tester,
  ) async {
    // Title plus two icons is the tightest the bar gets, and the narrowest tablet on the floor is a phone. Five tabs
    // needed a scrolling bar below 420 dp; three do not, so every label has to
    // be laid out and legible without a swipe.
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpRouted(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Production Board'), findsOneWidget);

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.isScrollable, isFalse);
    for (final label in ['Plan', 'Bases', 'Running']) {
      final size = tester.getSize(find.text(label));
      expect(size.width, greaterThan(0), reason: '$label is not laid out');
    }
  });
}
