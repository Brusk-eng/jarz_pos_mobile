// ignore_for_file: overridden_fields

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/core/constants/api_endpoints.dart';
import 'package:jarz_pos/src/core/constants/business_constants.dart';
import 'package:jarz_pos/src/core/network/user_service.dart';

import '../../helpers/mock_services.dart';

/// Minimal Dio stand-in for UserService tests.
class _FakeDio with DioMixin implements Dio {
  Response? nextResponse;
  DioException? nextError;

  @override
  BaseOptions options = BaseOptions();

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (nextError != null) {
      final err = nextError!;
      nextError = null;
      throw err;
    }
    final resp = nextResponse!;
    nextResponse = null;
    return resp as Response<T>;
  }
}

void main() {
  // ── UserRoles model ───────────────────────────────────────────────────

  group('UserRoles.fromJson', () {
    test('parses all fields', () {
      final roles = UserRoles.fromJson({
        'user': 'admin@test.com',
        'full_name': 'Admin User',
        'roles': [RoleNames.jarzManager, RoleNames.moderator],
        'employee': 'EMP-001',
        'employee_name': 'Admin',
        'branch': 'Main',
        'require_pos_shift': true,
      });
      expect(roles.user, 'admin@test.com');
      expect(roles.fullName, 'Admin User');
      expect(roles.roles, hasLength(2));
      expect(roles.employee, 'EMP-001');
      expect(roles.branch, 'Main');
      expect(roles.requirePosShift, isTrue);
    });

    test('defaults for missing fields', () {
      final roles = UserRoles.fromJson({});
      expect(roles.user, '');
      expect(roles.fullName, isNull);
      expect(roles.roles, isEmpty);
      expect(roles.employee, isNull);
      expect(roles.branch, isNull);
      expect(roles.requirePosShift, isFalse);
    });

    test('require_pos_shift handles int 1', () {
      final roles = UserRoles.fromJson({'require_pos_shift': 1});
      expect(roles.requirePosShift, isTrue);
    });

    test('roles handles non-list value', () {
      final roles = UserRoles.fromJson({'roles': 'not a list'});
      expect(roles.roles, isEmpty);
    });
  });

  group('UserRoles getters', () {
    test('isJarzManager when role present', () {
      final r = UserRoles(user: 'u', roles: [RoleNames.jarzManager]);
      expect(r.isJarzManager, isTrue);
      expect(r.isManager, isTrue);
    });

    test('isLineManager', () {
      final r = UserRoles(user: 'u', roles: [RoleNames.jarzLineManager]);
      expect(r.isLineManager, isTrue);
      expect(r.canAccessManagerDashboard, isTrue);
    });

    test('isModerator', () {
      final r = UserRoles(user: 'u', roles: [RoleNames.moderator]);
      expect(r.isModerator, isTrue);
      expect(r.canAccessManagerDashboard, isFalse);
    });

    test('canMuteNotifications for managers', () {
      final r = UserRoles(user: 'u', roles: [RoleNames.jarzManager]);
      expect(r.canMuteNotifications, isTrue);
    });

    test('canMuteNotifications for line managers', () {
      final r = UserRoles(user: 'u', roles: [RoleNames.jarzLineManager]);
      expect(r.canMuteNotifications, isTrue);
    });

    test('canMuteNotifications for moderators', () {
      final r = UserRoles(user: 'u', roles: [RoleNames.moderator]);
      expect(r.canMuteNotifications, isTrue);
    });

    test('canMuteNotifications for the admin tier', () {
      final r = UserRoles(user: 'u', roles: [RoleNames.systemManager]);
      expect(r.canMuteNotifications, isTrue);
    });

    test('canMuteNotifications false for regular user', () {
      final r = UserRoles(user: 'u', roles: ['POS User']);
      expect(r.canMuteNotifications, isFalse);
    });

    test('canActAsLineManager for the line manager itself', () {
      final r = UserRoles(user: 'u', roles: [RoleNames.jarzLineManager]);
      expect(r.canActAsLineManager, isTrue);
    });

    test('canActAsLineManager for a JARZ Manager without the line role', () {
      final r = UserRoles(user: 'u', roles: [RoleNames.jarzManager]);
      expect(r.isLineManager, isFalse);
      expect(r.canActAsLineManager, isTrue);
    });

    test('canActAsLineManager for the admin tier', () {
      for (final role in [
        RoleNames.administrator,
        RoleNames.systemManager,
        RoleNames.posManager,
      ]) {
        final r = UserRoles(user: 'u', roles: [role]);
        expect(r.canActAsLineManager, isTrue, reason: role);
      }
    });

    test('canActAsLineManager false for a regular POS user', () {
      final r = UserRoles(user: 'u', roles: ['POS User', RoleNames.moderator]);
      expect(r.canActAsLineManager, isFalse);
    });

    test('all false when no roles', () {
      final r = UserRoles(user: 'u', roles: []);
      expect(r.isJarzManager, isFalse);
      expect(r.isLineManager, isFalse);
      expect(r.isModerator, isFalse);
      expect(r.canMuteNotifications, isFalse);
      expect(r.canActAsLineManager, isFalse);
    });
  });

  // ── Drawer gates that mirror one backend role set each ────────────────
  //
  // The five entries below used to be gated on the manager-*dashboard* check,
  // which the line-manager tier passes — so a line manager saw every one of them
  // and got "Not permitted" from the API behind each. These assert the client
  // gate against the exact set its endpoint accepts.

  group('per-API drawer gates', () {
    UserRoles withRole(String role) => UserRoles(user: 'u', roles: [role]);

    test('the line manager reaches Stock Transfer and nothing else', () {
      for (final role in [
        RoleNames.jarzLineManager,
        RoleNames.jarzLineManagerAlt,
      ]) {
        final r = withRole(role);
        expect(r.canAccessManagerDashboard, isTrue, reason: role);
        // ROLES.STOCK_TRANSFER carries the line-manager tier: moving stock
        // between a branch and Finished Goods is floor-supervisor work.
        expect(r.canAccessStockTransfer, isTrue, reason: role);
        // The other three commit money or count stock and stay closed.
        expect(r.canAccessCashTransfer, isFalse, reason: role);
        expect(r.canAccessInventoryCount, isFalse, reason: role);
        expect(r.canAccessPurchaseInvoice, isFalse, reason: role);
      }
    });

    test('ROLES.MANAGER members reach cash and stock transfer', () {
      for (final role in [
        RoleNames.jarzManager,
        RoleNames.systemManager,
        RoleNames.administrator,
        RoleNames.accountsManager,
        RoleNames.stockManager,
        RoleNames.manufacturingManager,
        RoleNames.purchaseManager,
      ]) {
        final r = withRole(role);
        expect(r.canAccessCashTransfer, isTrue, reason: role);
        expect(r.canAccessStockTransfer, isTrue, reason: role);
        expect(r.canAccessPurchaseInvoice, isTrue, reason: role);
      }
    });

    test('Inventory Count excludes the Purchase Manager (ROLES.STOCK)', () {
      expect(withRole(RoleNames.purchaseManager).canAccessInventoryCount,
          isFalse);
      for (final role in [
        RoleNames.jarzManager,
        RoleNames.systemManager,
        RoleNames.administrator,
        RoleNames.accountsManager,
        RoleNames.stockManager,
        RoleNames.manufacturingManager,
      ]) {
        expect(withRole(role).canAccessInventoryCount, isTrue, reason: role);
      }
    });

    // The POS Manager is inside `canActAsLineManager` (via isAdminManager) but
    // OUTSIDE `ROLES.STOCK_TRANSFER`. Gating Stock Transfer on that helper would
    // hand this role a tile the server refuses — the bug this group exists for.
    test('the POS Manager reaches none of the four', () {
      final r = withRole(RoleNames.posManager);
      expect(r.canAccessManagerDashboard, isTrue);
      expect(r.canAccessCashTransfer, isFalse);
      expect(r.canAccessStockTransfer, isFalse);
      expect(r.canAccessInventoryCount, isFalse);
      expect(r.canAccessPurchaseInvoice, isFalse);
    });

    test('a plain POS user reaches none of the four', () {
      final r = withRole('POS User');
      expect(r.canAccessCashTransfer, isFalse);
      expect(r.canAccessStockTransfer, isFalse);
      expect(r.canAccessInventoryCount, isFalse);
      expect(r.canAccessPurchaseInvoice, isFalse);
    });
  });

  group('reports gates', () {
    UserRoles withRole(String role) => UserRoles(user: 'u', roles: [role]);

    test('only JARZ Manager and Administrator see the dashboards', () {
      for (final role in [RoleNames.jarzManager, RoleNames.administrator]) {
        final r = withRole(role);
        expect(r.canViewAllReports, isTrue, reason: role);
        expect(r.canAccessReportsHub, isTrue, reason: role);
      }
      for (final role in [
        RoleNames.systemManager,
        RoleNames.posManager,
        RoleNames.jarzLineManager,
        'POS User',
      ]) {
        expect(withRole(role).canViewAllReports, isFalse, reason: role);
      }
    });

    test('the line-manager tier keeps the hub for the Materials report', () {
      for (final role in [
        RoleNames.jarzLineManager,
        RoleNames.jarzLineManagerAlt,
        RoleNames.systemManager,
      ]) {
        final r = withRole(role);
        expect(r.canViewMaterialsReport, isTrue, reason: role);
        expect(r.canViewAllReports, isFalse, reason: role);
        // Hub stays visible: it still has exactly one tile for them.
        expect(r.canAccessReportsHub, isTrue, reason: role);
      }
    });

    test('the POS Manager loses the Reports entry entirely', () {
      // In neither backend set, so every tile on the hub would have 403'd.
      final r = withRole(RoleNames.posManager);
      expect(r.canViewMaterialsReport, isFalse);
      expect(r.canViewAllReports, isFalse);
      expect(r.canAccessReportsHub, isFalse);
    });

    test('a plain POS user has no reports at all', () {
      final r = withRole('POS User');
      expect(r.canAccessReportsHub, isFalse);
      expect(r.canViewMetaAds, isFalse);
    });

    test('Meta Ads: the analytics set plus System Manager and Meta CAPI Manager', () {
      for (final role in [
        RoleNames.jarzManager,
        RoleNames.administrator,
        RoleNames.systemManager,
        RoleNames.metaCapiManager,
      ]) {
        final r = withRole(role);
        expect(r.canViewMetaAds, isTrue, reason: role);
        expect(r.canAccessReportsHub, isTrue, reason: role);
      }
      for (final role in [RoleNames.posManager, RoleNames.jarzLineManager]) {
        expect(withRole(role).canViewMetaAds, isFalse, reason: role);
      }
      // The media buyer reaches the hub for this one report and nothing else.
      final buyer = withRole(RoleNames.metaCapiManager);
      expect(buyer.canViewAllReports, isFalse);
      expect(buyer.canViewMaterialsReport, isFalse);
    });
  });

  // ── UserService ───────────────────────────────────────────────────────

  group('UserService.getCurrentUserRoles', () {
    late _FakeDio dio;
    late UserService service;

    setUp(() {
      dio = _FakeDio();
      service = UserService(dio);
    });

    test('parses from message envelope', () async {
      dio.nextResponse = Response(
        requestOptions: RequestOptions(path: ApiEndpoints.getCurrentUserRoles),
        statusCode: 200,
        data: {
          'message': {
            'user': 'user@test.com',
            'roles': ['POS User'],
            'branch': 'B1',
          },
        },
      );

      final roles = await service.getCurrentUserRoles();
      expect(roles.user, 'user@test.com');
      expect(roles.roles, ['POS User']);
      expect(roles.branch, 'B1');
    });

    test('parses from flat response (no message key)', () async {
      dio.nextResponse = Response(
        requestOptions: RequestOptions(path: ApiEndpoints.getCurrentUserRoles),
        statusCode: 200,
        data: {
          'user': 'direct@test.com',
          'roles': [],
        },
      );

      final roles = await service.getCurrentUserRoles();
      expect(roles.user, 'direct@test.com');
    });

    test('throws on unexpected data type', () async {
      dio.nextResponse = Response(
        requestOptions: RequestOptions(path: ApiEndpoints.getCurrentUserRoles),
        statusCode: 200,
        data: 'plain text',
      );

      expect(
        () => service.getCurrentUserRoles(),
        throwsA(isA<Exception>()),
      );
    });

    test('propagates DioException', () async {
      dio.nextError = createMockDioException(statusCode: 401);

      expect(
        () => service.getCurrentUserRoles(),
        throwsA(isA<DioException>()),
      );
    });
  });
}
