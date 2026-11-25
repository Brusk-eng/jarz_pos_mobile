import '../../../data/api/studio_api_base.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';

class SettingsRepository {
  SettingsRepository(this._api);
  final StudioApi _api;

  Future<StudioOptions> options() => _api.settingsOptions();

  Future<List<StudioRule>> rules({String? q}) => _api.settingsRules(q: q);

  Future<StudioRule> ruleSet(
    String key,
    double value,
    String validFrom, {
    String? note,
    String? requestId,
  }) => _api.settingsRuleSet(
    ruleKey: key,
    value: value,
    validFrom: validFrom,
    note: note,
    requestId: requestId,
  );

  Future<List<StudioFlavour>> flavours() => _api.settingsFlavours();

  Future<FlavourSetResult> flavourSet(
    String id, {
    String? status,
    String? availableFrom,
    String? availableTo,
    String? note,
    String? baseModified,
    String? requestId,
  }) => _api.settingsFlavourSet(
    flavourId: id,
    status: status,
    availableFrom: availableFrom,
    availableTo: availableTo,
    note: note,
    baseModified: baseModified,
    requestId: requestId,
  );

  Future<StudioClaimPage> claims({String? status, String? after}) =>
      _api.settingsClaims(status: status, after: after);

  Future<List<StudioMoment>> moments({
    String? from,
    String? to,
    String? kind,
  }) => _api.settingsMoments(from: from, to: to, kind: kind);

  Future<MomentSetResult> momentSet({
    String? momentId,
    String? kind,
    String? title,
    String? date,
    String? endDate,
    String? note,
    String? baseModified,
    String? requestId,
  }) => _api.settingsMomentSet(
    momentId: momentId,
    kind: kind,
    title: title,
    date: date,
    endDate: endDate,
    note: note,
    baseModified: baseModified,
    requestId: requestId,
  );

  Future<List<StudioPerson>> people() => _api.settingsPeople();

  Future<StudioPerson> personSet(
    String key,
    Map<String, dynamic> fields, {
    String? requestId,
  }) => _api.settingsPersonSet(
    personKey: key,
    fields: fields,
    requestId: requestId,
  );

  Future<NotificationPrefs> myNotifications() => _api.settingsMyNotifications();

  Future<NotificationPrefs> setMyNotifications({
    String? quietFrom,
    String? quietTo,
    bool? digestEnabled,
    String? digestTime,
    String? lang,
  }) => _api.settingsSetMyNotifications(
    quietFrom: quietFrom,
    quietTo: quietTo,
    digestEnabled: digestEnabled,
    digestTime: digestTime,
    lang: lang,
  );

  Future<HelpSeen> helpSeen(String key) => _api.sessionHelpSeen(key: key);
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(studioApiProvider)),
);

/// Dropdown values for every form (flavours, personas, stages...).
final studioOptionsProvider = FutureProvider<StudioOptions>(
  (ref) => ref.watch(settingsRepositoryProvider).options(),
);

final rulesProvider = FutureProvider.autoDispose<List<StudioRule>>(
  (ref) => ref.watch(settingsRepositoryProvider).rules(),
);

final flavoursProvider = FutureProvider.autoDispose<List<StudioFlavour>>(
  (ref) => ref.watch(settingsRepositoryProvider).flavours(),
);

final momentsProvider = FutureProvider.autoDispose<List<StudioMoment>>(
  (ref) => ref.watch(settingsRepositoryProvider).moments(),
);

final peopleProvider = FutureProvider.autoDispose<List<StudioPerson>>(
  (ref) => ref.watch(settingsRepositoryProvider).people(),
);

final claimsProvider =
    AsyncNotifierProvider<ClaimsNotifier, PagedState<StudioClaim>>(
      ClaimsNotifier.new,
    );

class ClaimsNotifier extends PagedNotifier<StudioClaim> {
  @override
  Future<StudioClaimPage> fetchPage(String? after) =>
      ref.read(settingsRepositoryProvider).claims(after: after);
}

/// This person's quiet hours and daily digest.
final myNotificationPrefsProvider =
    AsyncNotifierProvider<MyNotificationPrefsNotifier, NotificationPrefs>(
      MyNotificationPrefsNotifier.new,
    );

class MyNotificationPrefsNotifier extends AsyncNotifier<NotificationPrefs> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  Future<NotificationPrefs> build() => _repo.myNotifications();

  /// Omitted keeps the stored value; [studioClear] clears it.
  static String? _next(String? sent, String? stored) =>
      sent == null ? stored : (sent == studioClear ? null : sent);

  Future<void> save({
    String? quietFrom,
    String? quietTo,
    bool? digestEnabled,
    String? digestTime,
  }) async {
    final before = state;
    final cur = state.valueOrNull;
    if (cur != null) {
      state = AsyncData(
        cur.copyWith(
          quietFrom: _next(quietFrom, cur.quietFrom),
          quietTo: _next(quietTo, cur.quietTo),
          digestEnabled: digestEnabled ?? cur.digestEnabled,
          digestTime: digestTime ?? cur.digestTime,
        ),
      );
    }
    try {
      state = AsyncData(
        await _repo.setMyNotifications(
          quietFrom: quietFrom,
          quietTo: quietTo,
          digestEnabled: digestEnabled,
          digestTime: digestTime,
        ),
      );
    } catch (_) {
      state = before;
      rethrow;
    }
  }
}
