import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';

class ReportsRepository {
  ReportsRepository(this._api);
  final StudioApi _api;

  Future<StudioReportPage> list({
    String? kind,
    String? from,
    String? to,
    String? after,
  }) => _api.reportsList(kind: kind, from: from, to: to, after: after);

  Future<StudioReport> get(String id) => _api.reportsGet(reportId: id);
}

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.watch(studioApiProvider)),
);

/// Report kind filter (wire value, e.g. `Ads read`), null = all.
final reportsKindFilterProvider = StateProvider<String?>((ref) => null);

final reportsProvider =
    AsyncNotifierProvider<ReportsNotifier, PagedState<StudioReport>>(
      ReportsNotifier.new,
    );

class ReportsNotifier extends PagedNotifier<StudioReport> {
  @override
  Future<StudioReportPage> fetchPage(String? after) => ref
      .read(reportsRepositoryProvider)
      .list(kind: ref.watch(reportsKindFilterProvider), after: after);
}

final reportProvider = FutureProvider.autoDispose.family<StudioReport, String>(
  (ref, id) => ref.watch(reportsRepositoryProvider).get(id),
);
