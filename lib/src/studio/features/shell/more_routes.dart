import 'package:go_router/go_router.dart';

import '../paid/presentation/paid_overview_screen.dart';
import '../paid/presentation/paid_queue_screen.dart';
import '../paid/presentation/paid_round_screen.dart';
import '../references/presentation/competitors_screens.dart';
import '../references/presentation/reference_screen.dart';
import '../references/presentation/references_screen.dart';
import '../reports/presentation/reports_screen.dart';
import '../results/presentation/piece_results_screen.dart';
import '../results/presentation/ratings_screen.dart';
import '../results/presentation/scorecard_screen.dart';
import '../results/presentation/summary_screen.dart';
import '../settings/presentation/claims_moments_options_screens.dart';
import '../settings/presentation/flavours_screens.dart';
import '../settings/presentation/people_screens.dart';
import '../settings/presentation/rules_screens.dart';
import '../settings/presentation/settings_hub_screen.dart';

/// The routes of the More section: References, Paid, Results, Reports and
/// Settings. They are written as children of `/more` (relative paths), so an
/// integration step adds them as
///
/// ```dart
/// GoRoute(path: '/more', builder: ..., routes: moreRoutes())
/// ```
///
/// inside the More branch, so the More tab stays selected while you are in
/// one. `/more/library` and `/more/shoots` are other screens' routes; the
/// More list only links to them.
///
/// Static paths come before their `:param` siblings so `competitors` and
/// `queue` are not read as ids.
List<RouteBase> moreRoutes() => [
  // References.
  GoRoute(
    path: 'references',
    builder: (_, _) => const ReferencesScreen(),
    routes: [
      GoRoute(
        path: 'competitors',
        builder: (_, _) => const CompetitorsScreen(),
        routes: [
          GoRoute(
            path: ':key',
            builder: (_, state) =>
                CompetitorScreen(competitorKey: state.pathParameters['key']!),
          ),
        ],
      ),
      GoRoute(
        path: ':id',
        builder: (_, state) =>
            ReferenceScreen(referenceId: state.pathParameters['id']!),
      ),
    ],
  ),
  // Paid.
  GoRoute(
    path: 'paid',
    builder: (_, _) => const PaidOverviewScreen(),
    routes: [
      GoRoute(path: 'queue', builder: (_, _) => const PaidQueueScreen()),
      GoRoute(
        path: 'rounds/:code',
        builder: (_, state) =>
            PaidRoundScreen(roundCode: state.pathParameters['code']!),
      ),
    ],
  ),
  // Results.
  GoRoute(
    path: 'results',
    builder: (_, _) => const ScorecardScreen(),
    routes: [
      GoRoute(path: 'pieces', builder: (_, _) => const PieceResultsScreen()),
      GoRoute(path: 'summary', builder: (_, _) => const SummaryScreen()),
      GoRoute(path: 'ratings', builder: (_, _) => const RatingsScreen()),
    ],
  ),
  // Reports.
  GoRoute(path: 'reports', builder: (_, _) => const ReportsScreen()),
  // Settings.
  GoRoute(
    path: 'settings',
    builder: (_, _) => const SettingsHubScreen(),
    routes: [
      GoRoute(
        path: 'rules',
        builder: (_, _) => const RulesScreen(),
        routes: [
          GoRoute(
            path: ':key',
            builder: (_, state) =>
                RuleScreen(ruleKey: state.pathParameters['key']!),
          ),
        ],
      ),
      GoRoute(
        path: 'flavours',
        builder: (_, _) => const FlavoursScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                FlavourScreen(flavourId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: 'claims', builder: (_, _) => const ClaimsScreen()),
      GoRoute(path: 'moments', builder: (_, _) => const MomentsScreen()),
      GoRoute(
        path: 'people',
        builder: (_, _) => const PeopleScreen(),
        routes: [
          GoRoute(
            path: ':key',
            builder: (_, state) =>
                PersonScreen(personKey: state.pathParameters['key']!),
          ),
        ],
      ),
      GoRoute(path: 'options', builder: (_, _) => const OptionsScreen()),
    ],
  ),
];
