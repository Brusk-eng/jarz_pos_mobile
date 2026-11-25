import '../../../shared/bidi_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/network/studio_api.dart';
import '../../../core/offline/reachability.dart';
import '../../../core/router/studio_screen.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../data/shoots_repository.dart';
import '../shoots_strings.dart';
import '../state/on_set_state.dart';
import '../state/shoot_list_state.dart';
import 'shoot_widgets.dart';
import '../../../shared/studio_toast.dart';

/// `/shoots/:id`: the plan, the prep checklist, the shots grouped by piece,
/// the prep page link, and the way into On set. The shoot is stored on the
/// phone when this page opens, so On set works with no connection.
class ShootScreen extends ConsumerWidget {
  const ShootScreen({super.key, required this.shootId});

  final String shootId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ShootStrings.of(context);
    final st = StudioStrings.of(context);
    final detail = ref.watch(shootDetailProvider(shootId));
    final stored = ref.watch(onSetProvider.select((s) => s.shoot(shootId)));
    final loaded = ref.watch(onSetProvider.select((s) => s.loaded));
    final shoot = stored ?? detail.valueOrNull;

    final AsyncValue<StudioShoot> value = shoot != null
        ? AsyncData(shoot)
        : (detail.isLoading || !loaded)
        ? const AsyncLoading()
        : AsyncError(detail.error ?? 'none', StackTrace.empty);
    final offlineCopy =
        !ref.watch(studioReachabilityProvider) && stored != null;

    return ViewEditScaffold(
      title: shoot?.title ?? st.screen(StudioScreen.shoot).title,
      screen: StudioScreen.shoot,
      parentRoute: '/shoots',
      onEdit: shoot != null && shoot.actions.contains('edit')
          ? () => context.push('/shoots/$shootId/edit')
          : null,
      body: detail.hasError && shoot == null && detail.error is StudioNotFound
          ? StudioEmptyState(
              config: StudioEmptyConfig(
                purpose: t.shootNotFound,
                firstStep: t.emptyUpcomingFirst,
                icon: Icons.videocam_off_outlined,
              ),
            )
          : Column(
              children: [
                const SyncBanner(),
                if (offlineCopy)
                  Padding(
                    padding: const EdgeInsets.all(StudioSpacing.sm),
                    child: Text(
                      t.showingStoredCopy,
                      key: const ValueKey('stored-copy'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                Expanded(
                  child: StudioAsyncView<StudioShoot>(
                    value: value,
                    onRetry: () => ref.invalidate(shootDetailProvider(shootId)),
                    isEmpty: (_) => false,
                    empty: StudioEmptyConfig(
                      purpose: t.shootNotFound,
                      firstStep: t.emptyUpcomingFirst,
                    ),
                    builder: (context, s) => _ShootBody(shoot: s),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ShootBody extends ConsumerWidget {
  const _ShootBody({required this.shoot});
  final StudioShoot shoot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ShootStrings.of(context);
    final theme = Theme.of(context);
    final canFilm = shoot.actions.contains('tick_shot');
    final canShare = shoot.actions.contains('share');
    final canAdd = shoot.actions.contains('add_shot');

    // Shots grouped by the first piece they serve.
    final groups = <String, List<ShootShot>>{};
    final titles = <String, String>{};
    for (final shot in [
      ...shoot.shots,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))) {
      final key = shot.pieces.isEmpty ? '' : shot.pieces.first.id;
      if (shot.pieces.isNotEmpty) titles[key] = shot.pieces.first.title;
      (groups[key] ??= []).add(shot);
    }
    final keys = [
      ...groups.keys.where((k) => k.isNotEmpty),
      if (groups.containsKey('')) '',
    ];

    return ShootPage(
      child: ListView(
        padding: const EdgeInsets.all(StudioSpacing.gutter),
        children: [
          Row(
            children: [
              ShootStatusPill(status: shoot.status),
              const SizedBox(width: StudioSpacing.md),
              Expanded(
                child: Text(
                  t.shotsOf(shoot.nDone, shoot.nShots),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: StudioSpacing.md),
          if (canFilm && shoot.shots.isNotEmpty)
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                key: const ValueKey('start-on-set'),
                onPressed: () => context.push('/shoots/${shoot.id}/on-set'),
                icon: const Icon(Icons.videocam_outlined),
                label: Text(t.startOnSet),
              ),
            ),
          const SizedBox(height: StudioSpacing.lg),
          _PlanCard(shoot: shoot),
          const SizedBox(height: StudioSpacing.lg),
          Text(t.sectionPrep, style: theme.textTheme.titleMedium),
          const SizedBox(height: StudioSpacing.xs),
          if (shoot.prep.isEmpty)
            Text(t.noPrep, style: theme.textTheme.bodySmall)
          else
            Card(
              child: Column(
                children: [
                  for (final task in [
                    ...shoot.prep,
                  ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
                    _PrepRow(shoot: shoot, task: task),
                ],
              ),
            ),
          const SizedBox(height: StudioSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(t.sectionShots, style: theme.textTheme.titleMedium),
              ),
              if (canAdd)
                TextButton.icon(
                  key: const ValueKey('add-shot'),
                  onPressed: () => showShotSheet(context, ref, shoot.id),
                  icon: const Icon(Icons.add),
                  label: Text(t.addShot),
                ),
            ],
          ),
          if (shoot.shots.isEmpty)
            Text(t.noShots, style: theme.textTheme.bodySmall),
          for (final k in keys) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: StudioSpacing.md,
                bottom: StudioSpacing.xs,
              ),
              child: Text(
                k.isEmpty ? t.notForPieceYet : titles[k]!,
                key: ValueKey('group-${k.isEmpty ? 'none' : k}'),
                style: theme.textTheme.labelLarge,
              ),
            ),
            for (final shot in groups[k]!)
              _ShotTile(shoot: shoot, shot: shot, canFilm: canFilm),
          ],
          if (canShare) ...[
            const SizedBox(height: StudioSpacing.xl),
            OutlinedButton.icon(
              key: const ValueKey('share-prep'),
              onPressed: () => showShareSheet(context, ref, shoot.id),
              icon: const Icon(Icons.share_outlined),
              label: Text(t.sharePrep),
            ),
          ],
          const SizedBox(height: StudioSpacing.xxl),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.shoot});
  final StudioShoot shoot;

  @override
  Widget build(BuildContext context) {
    final t = ShootStrings.of(context);
    final theme = Theme.of(context);
    Widget line(IconData icon, String? text, {Key? key}) =>
        text == null || text.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: StudioColors.plumMuted),
                const SizedBox(width: StudioSpacing.sm),
                Expanded(child: Text(text, key: key)),
              ],
            ),
          );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(StudioSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.sectionPlan, style: theme.textTheme.titleMedium),
            const SizedBox(height: StudioSpacing.md),
            line(
              Icons.event_outlined,
              shoot.shootDate == null
                  ? t.noDateYet
                  : t.dateLabel(shoot.shootDate, shoot.shootTime),
              key: const ValueKey('plan-when'),
            ),
            line(Icons.place_outlined, shoot.place),
            line(
              Icons.person_outline,
              shoot.assignee == null
                  ? null
                  : t.assignedTo(shoot.assignee!.fullName),
            ),
            line(Icons.groups_outlined, shoot.people),
            line(Icons.inventory_2_outlined, shoot.kit),
            line(Icons.notes_outlined, shoot.notes),
            for (final need in shoot.needs)
              Padding(
                padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: StudioColors.warning,
                    ),
                    const SizedBox(width: StudioSpacing.sm),
                    Expanded(
                      child: Text(need, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PrepRow extends ConsumerWidget {
  const _PrepRow({required this.shoot, required this.task});
  final StudioShoot shoot;
  final StudioTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ShootStrings.of(context);
    final canTick = task.actions.contains('tick');
    return CheckboxListTile(
      key: ValueKey('prep-${task.id}'),
      value: task.done,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(task.text),
      onChanged: canTick
          ? (v) async {
              try {
                await ref
                    .read(onSetProvider.notifier)
                    .tickPrep(shoot.id, task, v ?? false);
              } catch (e) {
                showStudioToast(
                  e is StudioNetworkError
                      ? t.prepNeedsConnection
                      : shootErrorText(t, e),
                );
              }
            }
          : null,
    );
  }
}

class _ShotTile extends ConsumerWidget {
  const _ShotTile({
    required this.shoot,
    required this.shot,
    required this.canFilm,
  });
  final StudioShoot shoot;
  final ShootShot shot;
  final bool canFilm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ShootStrings.of(context);
    final theme = Theme.of(context);
    final images = [
      for (final r in shot.refs)
        if (r.reference.image != null) r.reference.image!,
    ];
    return Card(
      key: ValueKey('shot-${shot.id}'),
      margin: const EdgeInsets.only(bottom: StudioSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(StudioRadii.md),
        onTap: canFilm
            ? () => context.push('/shoots/${shoot.id}/on-set?shot=${shot.id}')
            : null,
        child: Padding(
          padding: const EdgeInsets.all(StudioSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                shot.done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: shot.done
                    ? StudioColors.success
                    : StudioColors.plumMuted,
                semanticLabel: shot.done ? t.filmedMark : t.notFilmedMark,
              ),
              const SizedBox(width: StudioSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shot.what, style: theme.textTheme.bodyLarge),
                    if (shot.setup != null && shot.setup!.isNotEmpty)
                      Text(shot.setup!, style: theme.textTheme.bodySmall),
                    if (shot.pieces.length > 1)
                      Text(
                        '${t.servesPieces}: ${shot.pieces.map((p) => p.title).join(', ')}',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (images.isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: StudioSpacing.sm,
                  ),
                  child: StudioThumb(
                    media: images.first,
                    width: 44,
                    height: 56,
                  ),
                ),
              if (shot.actions.contains('edit'))
                IconButton(
                  key: ValueKey('edit-shot-${shot.id}'),
                  tooltip: t.editShot,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () =>
                      showShotSheet(context, ref, shoot.id, shot: shot),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- sheets

/// Add or edit a shot card (lead, founder).
Future<void> showShotSheet(
  BuildContext context,
  WidgetRef ref,
  String shootId, {
  ShootShot? shot,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _ShotSheet(shootId: shootId, shot: shot),
  );
}

class _ShotSheet extends ConsumerStatefulWidget {
  const _ShotSheet({required this.shootId, this.shot});
  final String shootId;
  final ShootShot? shot;

  @override
  ConsumerState<_ShotSheet> createState() => _ShotSheetState();
}

class _ShotSheetState extends ConsumerState<_ShotSheet> {
  late final what = TextEditingController(text: widget.shot?.what);
  late final setup = TextEditingController(text: widget.shot?.setup);
  late final ar = TextEditingController(text: widget.shot?.ar);
  late final en = TextEditingController(text: widget.shot?.en);
  String? error;
  var busy = false;

  @override
  void dispose() {
    for (final c in [what, setup, ar, en]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    final t = ShootStrings.of(context);
    if (what.text.trim().isEmpty) {
      setState(() => error = t.titleRequired);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(onSetProvider.notifier)
          .setShot(
            widget.shootId,
            shotId: widget.shot?.id,
            what: what.text.trim(),
            setup: setup.text.trim().isEmpty ? null : setup.text.trim(),
            ar: ar.text.trim().isEmpty ? null : ar.text.trim(),
            en: en.text.trim().isEmpty ? null : en.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = shootErrorText(t, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ShootStrings.of(context);
    Widget field(TextEditingController c, String label, {Key? key}) => Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.md),
      child: TextField(
        key: key,
        controller: c,
        decoration: InputDecoration(labelText: label),
        minLines: 1,
        maxLines: 3,
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        StudioSpacing.gutter,
        0,
        StudioSpacing.gutter,
        MediaQuery.of(context).viewInsets.bottom + StudioSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.shot == null ? t.addShot : t.editShot,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: StudioSpacing.md),
            field(what, t.shotWhat, key: const ValueKey('shot-what')),
            field(setup, t.shotSetup),
            field(ar, t.shotLineAr),
            field(en, t.shotLineEn),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
                child: Text(
                  error!,
                  key: const ValueKey('shot-error'),
                  style: const TextStyle(color: StudioColors.danger),
                ),
              ),
            FilledButton(
              key: const ValueKey('shot-save'),
              onPressed: busy ? null : save,
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
  }
}

/// The prep page link: copy it, send it on WhatsApp, or make a new one.
Future<void> showShareSheet(
  BuildContext context,
  WidgetRef ref,
  String shootId,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _ShareSheet(shootId: shootId),
  );
}

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({required this.shootId});
  final String shootId;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  ShareLink? link;
  var failed = false;
  var copied = false;

  @override
  void initState() {
    super.initState();
    load(false);
  }

  Future<void> load(bool regenerate) async {
    setState(() => failed = false);
    try {
      final l = await ref
          .read(shootsRepositoryProvider)
          .shareLink(widget.shootId, regenerate: regenerate ? true : null);
      if (mounted) setState(() => link = l);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ShootStrings.of(context);
    final theme = Theme.of(context);
    final founder = ref.watch(isFounderProvider);
    final l = link;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StudioSpacing.gutter,
        0,
        StudioSpacing.gutter,
        StudioSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.shareTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: StudioSpacing.sm),
          Text(t.shareHelp, style: theme.textTheme.bodySmall),
          const SizedBox(height: StudioSpacing.md),
          if (failed)
            Text(
              t.shareFailed,
              key: const ValueKey('share-failed'),
              style: const TextStyle(color: StudioColors.danger),
            )
          else if (l == null)
            const LinearProgressIndicator()
          else ...[
            SelectableText(l.url, key: const ValueKey('share-url')),
            const SizedBox(height: StudioSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('share-copy'),
                    icon: Icon(copied ? Icons.check : Icons.copy),
                    label: Text(copied ? t.linkCopied : t.copyLink),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: withoutBidiIsolates(l.url)),
                      );
                      if (mounted) setState(() => copied = true);
                    },
                  ),
                ),
                const SizedBox(width: StudioSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('share-whatsapp'),
                    icon: const Icon(Icons.send_outlined),
                    label: Text(t.sendWhatsApp),
                    onPressed: () async {
                      final ok = await ref.read(studioLinkOpenerProvider)(
                        Uri.parse(l.whatsappUrl),
                      );
                      if (!ok && mounted) setState(() => failed = true);
                    },
                  ),
                ),
              ],
            ),
            if (founder)
              TextButton(
                key: const ValueKey('share-regenerate'),
                onPressed: () => load(true),
                child: Text('${t.newLink}. ${t.newLinkWarning}'),
              ),
          ],
        ],
      ),
    );
  }
}
