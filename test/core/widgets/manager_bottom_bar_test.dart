// The manager home: a per-user switch (User.custom_manager_home) that lands
// the user on the revenue dashboard and adds a bottom bar (Today, Orders,
// Reports, Final Products, More), plus the branch-cash card on the dashboard.
//
// The guarantees pinned here: with the switch off (everyone else) nothing
// changes - same home route, no bar, no cash card; with it on the bar shows
// only where nothing else owns the bottom of the screen; and the switch can
// never route someone to a screen their reports guard would bounce them from.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/core/constants/app_routes.dart';
import 'package:jarz_pos/src/core/constants/business_constants.dart';
import 'package:jarz_pos/src/core/network/user_service.dart';
import 'package:jarz_pos/src/core/router.dart';
import 'package:jarz_pos/src/core/widgets/manager_bottom_bar.dart';
import 'package:jarz_pos/src/features/manager/data/manager_api.dart';
import 'package:jarz_pos/src/features/manager/state/manager_providers.dart';
import 'package:jarz_pos/src/features/reports/presentation/screens/revenue_dashboard_screen.dart';

import '../../helpers/role_drawer_harness.dart';
import '../../helpers/test_helpers.dart';

UserRoles _roles(List<String> roles, {bool managerHome = false}) =>
    UserRoles(user: 'u@x.com', roles: roles, managerHome: managerHome);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPlatformChannels();

  group('UserRoles.manager_home', () {
    test('parses true and 1, defaults off', () {
      expect(
        UserRoles.fromJson({
          'user': 'a',
          'roles': <String>[],
          'manager_home': true,
        }).managerHome,
        isTrue,
      );
      expect(
        UserRoles.fromJson({
          'user': 'a',
          'roles': <String>[],
          'manager_home': 1,
        }).managerHome,
        isTrue,
      );
      // An older backend sends no key at all.
      expect(
        UserRoles.fromJson({'user': 'a', 'roles': <String>[]}).managerHome,
        isFalse,
      );
      expect(
        UserRoles.fromJson({
          'user': 'a',
          'roles': <String>[],
          'manager_home': false,
        }).managerHome,
        isFalse,
      );
    });

    test('applies only with the reports it lands on', () {
      expect(
        _roles([RoleNames.jarzManager], managerHome: true).usesManagerHome,
        isTrue,
      );
      expect(
        _roles([RoleNames.administrator], managerHome: true).usesManagerHome,
        isTrue,
      );
      // Switched on for someone who cannot open the revenue dashboard: no
      // effect, otherwise the reports guard would send them home in a loop.
      expect(
        _roles([RoleNames.jarzPosStaff], managerHome: true).usesManagerHome,
        isFalse,
      );
      expect(
        _roles([RoleNames.systemManager], managerHome: true).usesManagerHome,
        isFalse,
      );
      expect(_roles([RoleNames.jarzManager]).usesManagerHome, isFalse);
    });
  });

  group('homeRouteFor', () {
    test('manager home lands on the revenue dashboard', () {
      expect(
        homeRouteFor(_roles([RoleNames.jarzManager], managerHome: true)),
        AppRoutes.reportsRevenueDashboard,
      );
    });

    test('everyone else lands exactly where they did before', () {
      expect(homeRouteFor(_roles([RoleNames.jarzManager])), AppRoutes.pos);
      expect(homeRouteFor(_roles([RoleNames.jarzPosStaff])), AppRoutes.kanban);
      expect(
        homeRouteFor(_roles([RoleNames.jarzPosStaff], managerHome: true)),
        AppRoutes.kanban,
      );
      expect(
        homeRouteFor(_roles([RoleNames.posManager], managerHome: true)),
        AppRoutes.pos,
      );
    });
  });

  group('managerHomeProvider', () {
    test('off while roles load, on error, and when the switch is off', () async {
      final loading = ProviderContainer(
        overrides: [
          userRolesFutureProvider.overrideWith(
            (ref) => Completer<UserRoles>().future,
          ),
        ],
      );
      addTearDown(loading.dispose);
      expect(loading.read(managerHomeProvider), isFalse);

      final failed = ProviderContainer(
        overrides: [
          userRolesFutureProvider.overrideWith(
            (ref) => Future<UserRoles>.error(Exception('x')),
          ),
        ],
      );
      addTearDown(failed.dispose);
      await failed.read(userRolesFutureProvider.future).catchError(
        (_) => _roles(const []),
      );
      expect(failed.read(managerHomeProvider), isFalse);

      final on = ProviderContainer(
        overrides: [
          userRolesFutureProvider.overrideWith(
            (ref) async => _roles([RoleNames.jarzManager], managerHome: true),
          ),
        ],
      );
      addTearDown(on.dispose);
      await on.read(userRolesFutureProvider.future);
      expect(on.read(managerHomeProvider), isTrue);
    });
  });

  group('where the bar shows', () {
    bool show(
      String path, {
      bool enabled = true,
      bool covered = false,
      bool keyboardOpen = false,
      bool phoneLandscape = false,
    }) => shouldShowManagerBar(
      enabled: enabled,
      path: path,
      covered: covered,
      keyboardOpen: keyboardOpen,
      phoneLandscape: phoneLandscape,
    );

    test('never when the switch is off', () {
      for (final p in [
        AppRoutes.kanban,
        AppRoutes.reportsRevenueDashboard,
        AppRoutes.pos,
        AppRoutes.reports,
      ]) {
        expect(show(p, enabled: false), isFalse, reason: p);
      }
    });

    test('on ordinary screens', () {
      for (final p in [
        AppRoutes.reportsRevenueDashboard,
        AppRoutes.kanban,
        AppRoutes.reports,
        AppRoutes.reportsFinalProducts,
        AppRoutes.pos,
        AppRoutes.manager,
      ]) {
        expect(show(p), isTrue, reason: p);
      }
    });

    test('not on sign-in, shift gates or screens with their own bottom bar', () {
      for (final p in [
        '',
        AppRoutes.root,
        AppRoutes.login,
        AppRoutes.shiftStart,
        AppRoutes.shiftEnd,
        AppRoutes.inventoryCount,
        '${AppRoutes.inventoryCount}/x',
        AppRoutes.userNew,
        '/users/someone@x.com',
        AppRoutes.b2bVisitBuilder,
        AppRoutes.b2bVisitPlan,
        '${AppRoutes.b2bVisitPlan}/PLAN-0001',
      ]) {
        expect(show(p), isFalse, reason: p);
      }
      // The users list itself has no bottom bar of its own.
      expect(managerBarHiddenOn('/users'), isFalse);
    });

    test('steps aside for a dialog, the keyboard and a sideways phone', () {
      expect(show(AppRoutes.kanban, covered: true), isFalse);
      expect(show(AppRoutes.kanban, keyboardOpen: true), isFalse);
      expect(show(AppRoutes.kanban, phoneLandscape: true), isFalse);
    });

    test('highlights the tab the screen belongs to', () {
      expect(managerBarIndexFor(AppRoutes.reportsRevenueDashboard), 0);
      expect(managerBarIndexFor(AppRoutes.kanban), 1);
      expect(managerBarIndexFor(AppRoutes.reports), 2);
      expect(managerBarIndexFor('${AppRoutes.reports}/pnl'), 2);
      expect(managerBarIndexFor(AppRoutes.reportsFinalProducts), 3);
      expect(managerBarIndexFor(AppRoutes.pos), isNull);
      expect(managerBarIndexFor(AppRoutes.manager), isNull);
    });
  });

  group('ManagerBottomBar', () {
    Future<void> pumpBar(
      WidgetTester tester, {
      required ValueChanged<String> onSelect,
      required VoidCallback onMore,
      Locale locale = const Locale('en'),
      double width = 360,
    }) async {
      tester.view.physicalSize = Size(width * 2, 800 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            bottomNavigationBar: ManagerBottomBar(
              selectedIndex: 1,
              onSelect: onSelect,
              onMore: onMore,
            ),
          ),
        ),
      );
    }

    testWidgets('five tabs, each opens its screen', (tester) async {
      final went = <String>[];
      var more = 0;
      await pumpBar(tester, onSelect: went.add, onMore: () => more++);
      expect(tester.takeException(), isNull);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      for (final k in [
        'manager-bar-today',
        'manager-bar-orders',
        'manager-bar-reports',
        'manager-bar-final-products',
        'manager-bar-more',
      ]) {
        await tester.tap(find.byKey(ValueKey(k)));
      }
      expect(went, [
        AppRoutes.reportsRevenueDashboard,
        AppRoutes.kanban,
        AppRoutes.reports,
        AppRoutes.reportsFinalProducts,
      ]);
      expect(more, 1);
    });

    testWidgets('Arabic on a narrow 320dp phone does not overflow', (
      tester,
    ) async {
      await pumpBar(
        tester,
        onSelect: (_) {},
        onMore: () {},
        locale: const Locale('ar'),
        width: 320,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('الطلبات'), findsOneWidget);
      expect(find.text('المزيد'), findsOneWidget);
    });
  });

  group('ManagerBottomBarHost in the app shell', () {
    Future<GoRouter> pumpShell(
      WidgetTester tester, {
      required bool enabled,
      String initial = AppRoutes.kanban,
    }) async {
      Widget page(String name) => Scaffold(
        appBar: AppBar(title: Text(name)),
        body: Builder(
          builder: (context) => Column(
            children: [
              Text('page:$name'),
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(content: Text('dialog')),
                ),
                child: const Text('open dialog'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('pushed')),
                  ),
                ),
                child: const Text('push page'),
              ),
            ],
          ),
        ),
      );
      final router = GoRouter(
        navigatorKey: rootNavigatorKey,
        initialLocation: initial,
        observers: [managerBarRouteObserver],
        routes: [
          for (final r in [
            AppRoutes.kanban,
            AppRoutes.reports,
            AppRoutes.reportsRevenueDashboard,
            AppRoutes.reportsFinalProducts,
            AppRoutes.login,
            AppRoutes.inventoryCount,
          ])
            GoRoute(path: r, builder: (_, _) => page(r)),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // The drawer behind More reads roles, badges and the shift; the
            // harness keeps those off the network.
            ...roleDrawerOverrides(RoleProfiles.manager),
            routerProvider.overrideWithValue(router),
            managerHomeProvider.overrideWithValue(enabled),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) =>
                ManagerBottomBarHost(child: child ?? const SizedBox.shrink()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    final bar = find.byKey(const ValueKey('manager-bottom-bar'));

    testWidgets('switch off: no bar anywhere', (tester) async {
      final router = await pumpShell(tester, enabled: false);
      expect(bar, findsNothing);
      router.go(AppRoutes.reportsRevenueDashboard);
      await tester.pumpAndSettle();
      expect(bar, findsNothing);
      expect(find.text('page:${AppRoutes.reportsRevenueDashboard}'), findsOne);
    });

    testWidgets('switch on: tabs navigate and keep the bar', (tester) async {
      final router = await pumpShell(tester, enabled: true);
      expect(tester.takeException(), isNull);
      expect(bar, findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('manager-bar-final-products')));
      await tester.pumpAndSettle();
      expect(find.text('page:${AppRoutes.reportsFinalProducts}'), findsOne);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.reportsFinalProducts,
      );

      await tester.tap(find.byKey(const ValueKey('manager-bar-today')));
      await tester.pumpAndSettle();
      expect(find.text('page:${AppRoutes.reportsRevenueDashboard}'), findsOne);
      expect(bar, findsOneWidget);

      // Off the bar's screens it hides, back on them it returns.
      router.go(AppRoutes.inventoryCount);
      await tester.pumpAndSettle();
      expect(bar, findsNothing);
      router.go(AppRoutes.login);
      await tester.pumpAndSettle();
      expect(bar, findsNothing);
      router.go(AppRoutes.kanban);
      await tester.pumpAndSettle();
      expect(bar, findsOneWidget);
    });

    testWidgets('hides under a dialog and a pushed page, returns after', (
      tester,
    ) async {
      await pumpShell(tester, enabled: true);
      expect(bar, findsOneWidget);

      await tester.tap(find.text('open dialog'));
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsOneWidget);
      expect(bar, findsNothing);
      Navigator.of(tester.element(find.text('dialog'))).pop();
      await tester.pumpAndSettle();
      expect(bar, findsOneWidget);

      await tester.tap(find.text('push page'));
      await tester.pumpAndSettle();
      expect(find.text('pushed'), findsOneWidget);
      expect(bar, findsNothing);
      Navigator.of(tester.element(find.text('pushed'))).pop();
      await tester.pumpAndSettle();
      expect(bar, findsOneWidget);
    });

    testWidgets('More opens the side menu over the screen', (tester) async {
      await pumpShell(tester, enabled: true);
      await tester.tap(find.byKey(const ValueKey('manager-bar-more')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.byType(Drawer), findsOneWidget);
      expect(bar, findsNothing);
    });

    testWidgets('page state survives the bar appearing and hiding', (
      tester,
    ) async {
      await pumpShell(tester, enabled: true);
      final before = tester.state(find.byType(Navigator).first);
      await tester.tap(find.text('open dialog'));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('dialog'))).pop();
      await tester.pumpAndSettle();
      expect(identical(tester.state(find.byType(Navigator).first), before), isTrue);
    });
  });

  group('BranchCashCard', () {
    Future<void> pumpCard(
      WidgetTester tester,
      Future<DashboardSummary> Function() load, {
      Locale locale = const Locale('en'),
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [dashboardSummaryProvider.overrideWith((ref) => load())],
          child: MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: BranchCashCard()),
          ),
        ),
      );
      await tester.pump();
    }

    DashboardSummary summary() => DashboardSummary(
      branches: [
        BranchBalance(
          name: 'Zayed',
          title: 'Zayed',
          cashAccount: 'Cash Zayed - J',
          balance: 1200,
        ),
        BranchBalance(
          name: 'Nasr City',
          title: 'Nasr City',
          cashAccount: 'Cash Nasr - J',
          balance: 3450.5,
        ),
      ],
      totalBalance: 4650.5,
    );

    testWidgets('lists every branch and the total', (tester) async {
      await pumpCard(tester, () async => summary());
      expect(tester.takeException(), isNull);
      expect(find.text('Cash in branches now'), findsOneWidget);
      expect(find.text('Zayed'), findsOneWidget);
      expect(find.text('Nasr City'), findsOneWidget);
      expect(find.text('Total Cash'), findsOneWidget);
      final total = tester.widget<Text>(
        find.byKey(const ValueKey('branch-cash-total')),
      );
      expect(total.data, contains('4,650.50'));
      // Largest drawer first.
      expect(
        tester.getTopLeft(find.text('Nasr City')).dy,
        lessThan(tester.getTopLeft(find.text('Zayed')).dy),
      );
    });

    testWidgets('adds cash with couriers and a combined total', (tester) async {
      await pumpCard(
        tester,
        () async => DashboardSummary(
          branches: [
            BranchBalance(
              name: 'Zayed',
              title: 'Zayed',
              cashAccount: 'Cash Zayed - J',
              balance: 1200,
              courierBalance: 3000,
            ),
            BranchBalance(
              name: 'Nasr City',
              title: 'Nasr City',
              cashAccount: 'Cash Nasr - J',
              balance: 3450.5,
            ),
          ],
          totalBalance: 4650.5,
          totalCourierBalance: 3000,
        ),
      );
      expect(tester.takeException(), isNull);
      String keyed(String k) =>
          tester.widget<Text>(find.byKey(ValueKey(k))).data!;
      expect(keyed('branch-cash-total'), contains('4,650.50'));
      expect(keyed('branch-cash-courier-total'), contains('3,000.00'));
      expect(keyed('branch-cash-combined-total'), contains('7,650.50'));
      expect(find.text('With couriers'), findsOneWidget);
      // Ordered by drawer + couriers: Zayed (4,200) above Nasr City (3,450.50).
      expect(
        tester.getTopLeft(find.text('Zayed')).dy,
        lessThan(tester.getTopLeft(find.text('Nasr City')).dy),
      );
    });

    test('summary parses the courier fields and tolerates an old server', () {
      final withCouriers = DashboardSummary.fromJson({
        'branches': [
          {'name': 'Zayed', 'balance': 100, 'courier_balance': 50},
        ],
        'total_balance': 100,
        'total_courier_balance': 50,
      });
      expect(withCouriers.branches.single.combinedBalance, 150);
      expect(withCouriers.totalCombinedBalance, 150);

      final old = DashboardSummary.fromJson({
        'branches': [
          {'name': 'Zayed', 'balance': 100},
        ],
        'total_balance': 100,
      });
      expect(old.totalCourierBalance, 0);
      expect(old.totalCombinedBalance, 100);
    });

    testWidgets('a failure stays inside the card with a retry', (tester) async {
      await pumpCard(tester, () async => throw Exception('403'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Could not load branch cash'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Arabic renders', (tester) async {
      await pumpCard(tester, () async => summary(), locale: const Locale('ar'));
      expect(tester.takeException(), isNull);
      expect(find.text('النقدية في الفروع الآن'), findsOneWidget);
    });
  });
}
