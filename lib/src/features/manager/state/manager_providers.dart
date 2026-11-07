import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/user_service.dart';
import '../data/manager_api.dart';

final selectedBranchProvider = StateProvider<String?>((ref) => 'all');
final selectedStateProvider = StateProvider<String?>((ref) => 'all');

final dashboardSummaryProvider = FutureProvider.autoDispose((ref) async {
  final api = ref.read(managerApiProvider);
  final summary = await api.getSummary();
  // keep current selected branch if still exists, else fallback
  final selected = ref.read(selectedBranchProvider);
  if (selected != null && selected != 'all') {
    final exists = summary.branches.any((b) => b.name == selected);
    if (!exists) ref.read(selectedBranchProvider.notifier).state = 'all';
  }
  return summary;
});

/// Which sales channel the Recent orders list shows.
enum ManagerOrdersChannel {
  all,
  b2c,
  b2b;

  /// Value sent to the backend; null means no channel filter.
  String? get apiValue => this == all ? null : name;
}

final managerOrdersChannelProvider =
    StateProvider<ManagerOrdersChannel>((ref) => ManagerOrdersChannel.all);

class ManagerOrdersState {
  final List<ManagerInvoice> invoices;
  final bool hasMore;
  final bool loadingMore;
  const ManagerOrdersState({
    required this.invoices,
    required this.hasMore,
    this.loadingMore = false,
  });

  ManagerOrdersState copyWith({
    List<ManagerInvoice>? invoices,
    bool? hasMore,
    bool? loadingMore,
  }) {
    return ManagerOrdersState(
      invoices: invoices ?? this.invoices,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

/// Recent orders, 20 at a time. A change to the branch, state or channel
/// rebuilds the notifier, which restarts at the first page.
class ManagerOrdersNotifier
    extends AutoDisposeAsyncNotifier<ManagerOrdersState> {
  static const pageSize = 20;

  /// Bumped on every rebuild so a page fetched for old filters is dropped.
  int _generation = 0;

  @override
  Future<ManagerOrdersState> build() async {
    _generation++;
    final branch = ref.watch(selectedBranchProvider);
    final stateFilter = ref.watch(selectedStateProvider);
    final channel = ref.watch(managerOrdersChannelProvider);
    final page = await ref.read(managerApiProvider).getOrders(
          branch: branch,
          state: _normalizedState(stateFilter),
          channel: channel.apiValue,
          limit: pageSize,
        );
    return ManagerOrdersState(invoices: page.invoices, hasMore: page.hasMore);
  }

  String? _normalizedState(String? state) =>
      (state == null || state == 'all') ? null : state;

  /// Appends the next page; ignored while a load is running or when the
  /// server said there is nothing more.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;
    final branch = ref.read(selectedBranchProvider);
    final stateFilter = ref.read(selectedStateProvider);
    final channel = ref.read(managerOrdersChannelProvider);
    final generation = _generation;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await ref.read(managerApiProvider).getOrders(
            branch: branch,
            state: _normalizedState(stateFilter),
            channel: channel.apiValue,
            start: current.invoices.length,
            limit: pageSize,
          );
      // The filters changed (provider rebuilt) while this page was loading.
      if (generation != _generation) return;
      final latest = state.valueOrNull ?? current;
      final seen = latest.invoices.map((i) => i.name).toSet();
      state = AsyncData(latest.copyWith(
        invoices: [
          ...latest.invoices,
          ...page.invoices.where((i) => !seen.contains(i.name)),
        ],
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } catch (_) {
      if (generation != _generation) return;
      final latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncData(latest.copyWith(loadingMore: false));
      }
    }
  }
}

final managerOrdersProvider = AsyncNotifierProvider.autoDispose<
    ManagerOrdersNotifier, ManagerOrdersState>(ManagerOrdersNotifier.new);

final managerStatesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final api = ref.read(managerApiProvider);
  return api.getStates();
});

final pendingCustomShippingProvider = FutureProvider.autoDispose<List<CustomShippingRequest>>((ref) async {
  final api = ref.read(managerApiProvider);
  return api.getPendingCustomShippingRequests();
});

// Lightweight access check for Manager Dashboard visibility
final managerAccessProvider = FutureProvider<bool>((ref) async {
  final roles = await ref.watch(userRolesFutureProvider.future);
  if (!roles.canAccessManagerDashboard) {
    return false;
  }
  final api = ref.read(managerApiProvider);
  try {
    await api.getSummary();
    return true;
  } on DioException catch (e) {
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) return false;
    rethrow;
  } catch (_) {
    // On other errors (e.g., offline), don't break UI; hide manager menu by default
    return false;
  }
});
