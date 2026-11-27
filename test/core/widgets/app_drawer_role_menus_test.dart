// Every role sees exactly the menu entries its server lets it open.
//
// The expectations below are not opinions. They are what the backend answered
// on production (2026-09-26) when each screen's gate was evaluated as a real
// member of each Jarz role profile. A tile the server refuses is a dead end
// ("Not permitted" on every tap), and a tile hidden from someone the server
// allows is a feature they cannot find. Both directions are pinned here.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/core/widgets/app_drawer.dart';

import '../../helpers/role_drawer_harness.dart';
import '../../helpers/test_helpers.dart';

const _base = {
  'Point of Sale',
  'Sales Kanban',
  'Delivery Trips',
  'Courier Balances',
  'Expenses',
  'Item Requests',
};

const _allGated = {
  // Top-level, above the groups; JARZ Manager / Administrator only.
  'Revenue Dashboard',
  'Master Orders',
  'Live courier map',
  'B2B Mode',
  'Leads',
  'Customer Labels',
  'Price Lists',
  'Monthly Expenses',
  'Cash Transfer',
  'Cash Custody',
  'Partner Settlements',
  'InstaPay Reconciliation',
  'Credit Accounts',
  'Purchase Invoice',
  'Send to Branches',
  'Stock Transfer',
  'Inventory Count',
  'Production Board',
  'Production Round',
  'Recipes',
  'Tasks',
  'Shift Distribution',
  'Attendance',
  'Shift Monitor',
  'Branch Access',
  'Manager Dashboard',
  'Reports',
  'WooCommerce Sync',
  'Users',
  'Chats',
};

Future<Set<String>> _menuFor(WidgetTester tester, List<String> roles) async {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final key = GlobalKey<ScaffoldState>();
  await tester.pumpWidget(
    ProviderScope(
      overrides: roleDrawerOverrides(roles),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          key: key,
          body: const SizedBox.expand(),
          drawer: const AppDrawer(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  key.currentState!.openDrawer();
  await tester.pumpAndSettle();
  final labels = await collectDrawerLabels(tester);
  // Only the gated entries and the base tools matter; headers, About and the
  // language switch are the same for everyone.
  return labels.intersection({..._base, ..._allGated});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPlatformChannels();

  testWidgets('staff: the POS tools and nothing else', (tester) async {
    expect(await _menuFor(tester, RoleProfiles.staff), _base);
  });

  testWidgets('moderator: staff + Master Orders + Chats', (tester) async {
    expect(
      await _menuFor(tester, RoleProfiles.moderator),
      {..._base, 'Master Orders', 'Chats'},
    );
  });

  testWidgets('line manager: every screen the server lets them open, no more',
      (tester) async {
    expect(
      await _menuFor(tester, RoleProfiles.lineManager),
      {
        ..._base,
        'Master Orders',
        'Live courier map',
        'Price Lists',
        'InstaPay Reconciliation',
        'Credit Accounts',
        'Send to Branches',
        'Stock Transfer',
        'Tasks',
        'Shift Distribution',
        'Attendance',
        'Shift Monitor',
        'Branch Access',
        'Manager Dashboard',
        'Reports',
        'Chats',
      },
    );
  });

  testWidgets('JARZ Manager: everything, including Users', (tester) async {
    expect(
      await _menuFor(tester, RoleProfiles.manager),
      {..._base, ..._allGated},
    );
  });
}
