import '../../session/state/studio_session_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/upload/upload_engine.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../data/assets_repository.dart';

/// What the Library is filtered by (wire values; null = no filter).
class AssetFilters {
  const AssetFilters({
    this.kind,
    this.flavourId,
    this.status,
    this.consent,
    this.q = '',
  });

  final String? kind;
  final String? flavourId;
  final String? status;
  final String? consent;
  final String q;

  bool get any =>
      kind != null ||
      flavourId != null ||
      status != null ||
      consent != null ||
      q.trim().isNotEmpty;

  AssetFilters copyWith({
    Object? kind = _keep,
    Object? flavourId = _keep,
    Object? status = _keep,
    Object? consent = _keep,
    String? q,
  }) => AssetFilters(
    kind: identical(kind, _keep) ? this.kind : kind as String?,
    flavourId: identical(flavourId, _keep)
        ? this.flavourId
        : flavourId as String?,
    status: identical(status, _keep) ? this.status : status as String?,
    consent: identical(consent, _keep) ? this.consent : consent as String?,
    q: q ?? this.q,
  );
}

const Object _keep = Object();

final assetFiltersProvider = StateProvider<AssetFilters>(
  (ref) => const AssetFilters(),
);

/// The Library grid: cursor paged, reloaded from the first page whenever a
/// filter changes.
final libraryProvider =
    AsyncNotifierProvider<LibraryNotifier, PagedState<StudioAsset>>(
      LibraryNotifier.new,
    );

class LibraryNotifier extends PagedNotifier<StudioAsset> {
  @override
  Future<StudioAssetPage> fetchPage(String? after) {
    final f = ref.watch(assetFiltersProvider);
    return ref
        .read(assetsRepositoryProvider)
        .list(
          kind: f.kind,
          flavourId: f.flavourId,
          status: f.status,
          consent: f.consent,
          q: f.q.trim().isEmpty ? null : f.q.trim(),
          after: after,
        );
  }
}

/// What to do once a file picked in "Add files" is stored: create its asset.
/// Registered by the Library screens; a file that finished while they were
/// closed gets its asset the next time one opens (see [UploadEngine]).
const assetFollowUpKey = 'asset';

void registerAssetFollowUp(ProviderContainer container) {
  container.read(studioUploadEngineProvider.notifier).registerFollowUp(
    assetFollowUpKey,
    (job, media) async {
      final m = job.meta;
      await container
          .read(assetsRepositoryProvider)
          .create(
            mediaId: media.id,
            kind: m['kind'] as String,
            title: m['title'] as String?,
            flavourId: m['flavour_id'] as String?,
            category: m['category'] as String?,
            note: m['note'] as String?,
            requestId: m['create_request_id'] as String?,
          );
      container.invalidate(libraryProvider);
    },
  );
}

/// The Library's add button: every Studio role may add files.
final canAddAssetsProvider = Provider<bool>(
  (ref) => ref.watch(studioSessionProvider).valueOrNull?.canAddAssets ?? false,
);
