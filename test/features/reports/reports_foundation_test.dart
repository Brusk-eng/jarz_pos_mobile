import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/core/constants/app_routes.dart';
import 'package:jarz_pos/src/core/constants/business_constants.dart';
import 'package:jarz_pos/src/core/network/user_service.dart';
import 'package:jarz_pos/src/core/router.dart';
import 'package:jarz_pos/src/features/reports/data/models/ops_reports.dart';
import 'package:jarz_pos/src/features/reports/presentation/widgets/report_export_button.dart';
import 'package:jarz_pos/src/features/reports/state/reports_providers.dart';

UserRoles _roles(List<String> roles) => UserRoles(user: 'u@x.com', roles: roles);

void main() {
  group('ReportRange presets', () {
    final now = DateTime(2026, 10, 15, 13, 30);

    test('today / yesterday / YTD / last 7', () {
      expect(ReportRangePreset.today.range(now),
          ReportRange(from: DateTime(2026, 10, 15), to: DateTime(2026, 10, 15)));
      expect(ReportRangePreset.yesterday.range(now),
          ReportRange(from: DateTime(2026, 10, 14), to: DateTime(2026, 10, 14)));
      expect(ReportRangePreset.thisYear.range(now),
          ReportRange(from: DateTime(2026, 1, 1), to: DateTime(2026, 10, 15)));
      expect(ReportRangePreset.last7Days.range(now).dayCount, 7);
    });

    test('yesterday on the 1st crosses the month', () {
      expect(ReportRange.yesterday(DateTime(2026, 3, 1)).from, DateTime(2026, 2, 28));
    });

    test('matchingPreset finds the chip to highlight', () {
      expect(ReportRange.thisMonth(now).matchingPreset(now), ReportRangePreset.thisMonth);
      expect(
        ReportRange(from: DateTime(2026, 5, 3), to: DateTime(2026, 5, 9)).matchingPreset(now),
        isNull,
      );
    });
  });

  group('ReportQuery', () {
    final r = ReportRange(from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 15));

    test('blank branch equals no branch', () {
      expect(ReportQuery(range: r, branch: '  '), ReportQuery(range: r));
      expect(ReportQuery(range: r, branch: '').branchOrNull, isNull);
      expect(ReportQuery(range: r, branch: 'Nasr City').hasBranch, isTrue);
    });
  });

  group('ReportBranch.listFromPayload', () {
    test('reads {branches: [...]} and a bare list', () {
      expect(
        ReportBranch.listFromPayload({
          'branches': [
            {'name': 'A', 'warehouse': 'W-A', 'company': 'C'},
          ],
        }).single.name,
        'A',
      );
      expect(ReportBranch.listFromPayload([{'name': 'B'}]).single.name, 'B');
      expect(ReportBranch.listFromPayload(null), isEmpty);
    });
  });

  group('resolveReportsRedirect', () {
    final manager = _roles([RoleNames.jarzManager]);
    final lineManager = _roles([RoleNames.jarzLineManager]);
    final cashier = _roles([RoleNames.posUser]);

    test('JARZ Manager opens every report', () {
      for (final loc in [
        AppRoutes.reports,
        AppRoutes.reportsUnitEconomics,
        AppRoutes.reportsFinalProducts,
        AppRoutes.reportsMaterials,
        AppRoutes.reportsDailyClose,
        AppRoutes.reportsLabourCost,
      ]) {
        expect(resolveReportsRedirect(roles: manager, location: loc), isNull, reason: loc);
      }
    });

    test('line manager: materials + daily ops, analytics bounce to the hub', () {
      expect(resolveReportsRedirect(roles: lineManager, location: AppRoutes.reports), isNull);
      expect(resolveReportsRedirect(roles: lineManager, location: AppRoutes.reportsMaterials), isNull);
      expect(resolveReportsRedirect(roles: lineManager, location: AppRoutes.reportsDailyClose), isNull);
      expect(resolveReportsRedirect(roles: lineManager, location: AppRoutes.reportsCashOverShort), isNull);
      expect(resolveReportsRedirect(roles: lineManager, location: AppRoutes.reportsFulfilmentSla), isNull);
      expect(
        resolveReportsRedirect(roles: lineManager, location: AppRoutes.reportsFinalProducts),
        AppRoutes.reports,
      );
      expect(
        resolveReportsRedirect(roles: lineManager, location: AppRoutes.reportsProfitLoss),
        AppRoutes.reports,
      );
    });

    test('a cashier is sent home, never to the hub', () {
      expect(
        resolveReportsRedirect(roles: cashier, location: AppRoutes.reports),
        homeRouteFor(cashier),
      );
      expect(
        resolveReportsRedirect(roles: cashier, location: AppRoutes.reportsMaterials),
        homeRouteFor(cashier),
      );
    });

    test('Meta Ads: the media buyer opens it, and only it', () {
      final buyer = _roles([RoleNames.metaCapiManager]);
      expect(resolveReportsRedirect(roles: buyer, location: AppRoutes.reports), isNull);
      expect(resolveReportsRedirect(roles: buyer, location: AppRoutes.reportsMetaAds), isNull);
      expect(
        resolveReportsRedirect(roles: buyer, location: AppRoutes.reportsProfitLoss),
        AppRoutes.reports,
      );
      expect(resolveReportsRedirect(roles: manager, location: AppRoutes.reportsMetaAds), isNull);
      expect(
        resolveReportsRedirect(
          roles: _roles([RoleNames.systemManager]),
          location: AppRoutes.reportsMetaAds,
        ),
        isNull,
      );
      expect(
        resolveReportsRedirect(roles: lineManager, location: AppRoutes.reportsMetaAds),
        AppRoutes.reports,
      );
      expect(
        resolveReportsRedirect(roles: cashier, location: AppRoutes.reportsMetaAds),
        homeRouteFor(cashier),
      );
    });

    test('non-report paths are ignored', () {
      expect(resolveReportsRedirect(roles: cashier, location: AppRoutes.pos), isNull);
      expect(canOpenReportsLocation(roles: cashier, location: '/reportsx'), isNull);
    });
  });

  group('CSV export', () {
    test('quotes commas, quotes and newlines; BOM + CRLF', () {
      final csv = buildReportCsv([
        ['Item', 'Note'],
        ['A, B', 'say "hi"'],
        ['C', 'two\nlines'],
      ]);
      expect(csv.startsWith('﻿'), isTrue);
      expect(
        csv.substring(1),
        'Item,Note\r\n"A, B","say ""hi"""\r\nC,"two\nlines"\r\n',
      );
    });

    test('file name is safe and date-stamped', () {
      expect(
        reportCsvFileName('Cash over/short', DateTime(2026, 10, 5)),
        'Cash_over_short_2026-10-05.csv',
      );
      expect(reportCsvFileName('  ', DateTime(2026, 1, 2)), 'report_2026-01-02.csv');
    });
  });
}
