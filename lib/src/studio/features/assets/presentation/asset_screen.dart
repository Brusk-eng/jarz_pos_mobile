import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/studio_error.dart';
import '../../../shared/how_this_works_sheet.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../assets_strings.dart';
import '../data/assets_repository.dart';
import 'asset_sheets.dart';
import 'asset_widgets.dart';

/// `/assets/:id`: one file with its picture, where it was used, the consent
/// record for customer content, its rating and comments. Buttons come only
/// from the asset's `actions`.
class AssetScreen extends ConsumerWidget {
  const AssetScreen({super.key, required this.assetId});
  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AssetStrings.of(context);
    final value = ref.watch(assetProvider(assetId));
    final asset = value.valueOrNull;
    final notFound = value.error is StudioNotFound;

    return ViewEditScaffold(
      title: asset?.title ?? t.assetTitle,
      parentRoute: '/assets',
      onEdit: asset != null && asset.actions.contains('edit')
          ? () => context.push('/assets/$assetId/edit')
          : null,
      actions: [
        IconButton(
          key: const ValueKey('help'),
          tooltip: StudioStrings.of(context).howThisWorks,
          icon: const Icon(Icons.help_outline),
          onPressed: () => HowThisWorksSheet.show(
            context,
            title: t.assetHelpTitle,
            lines: t.assetHelp,
          ),
        ),
      ],
      body: notFound
          ? StudioEmptyState(
              config: StudioEmptyConfig(
                purpose: t.errNotFound,
                firstStep: t.emptyFirstStep,
                icon: Icons.image_not_supported_outlined,
              ),
            )
          : StudioAsyncView<StudioAsset>(
              value: value,
              onRetry: () => ref.invalidate(assetProvider(assetId)),
              isEmpty: (_) => false,
              empty: StudioEmptyConfig(
                purpose: t.errNotFound,
                firstStep: t.emptyFirstStep,
              ),
              builder: (context, a) => _AssetBody(asset: a),
            ),
    );
  }
}

class _AssetBody extends ConsumerStatefulWidget {
  const _AssetBody({required this.asset});
  final StudioAsset asset;

  @override
  ConsumerState<_AssetBody> createState() => _AssetBodyState();
}

class _AssetBodyState extends ConsumerState<_AssetBody> {
  final _comment = TextEditingController();
  final _sent = <String>[];
  var _sending = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  AssetNotifier get _notifier =>
      ref.read(assetProvider(widget.asset.id).notifier);

  void _say(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _guard(Future<void> Function() body) async {
    final t = AssetStrings.of(context);
    try {
      await body();
    } catch (e) {
      if (mounted) _say(assetErrorText(t, e));
    }
  }

  Future<void> _sendComment() async {
    final t = AssetStrings.of(context);
    final text = _comment.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(assetsRepositoryProvider).comment(widget.asset.id, text);
      await _notifier.refresh();
      if (!mounted) return;
      setState(() {
        _sent.add(text);
        _comment.clear();
      });
      _say(t.commentSent);
    } catch (e) {
      if (mounted) setState(() => _error = assetErrorText(t, e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AssetStrings.of(context);
    final theme = Theme.of(context);
    // Always the freshest copy of the asset.
    final a =
        ref.watch(assetProvider(widget.asset.id)).valueOrNull ?? widget.asset;
    final canRate = a.actions.contains('rate');
    final canComment = a.actions.contains('comment');
    final canConsent = a.actions.contains('set_consent');
    final canUsed = a.actions.contains('mark_used');
    final c = a.consent;

    Widget row(String label, String? value, {Key? key}) =>
        value == null || value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(label, style: theme.textTheme.bodySmall),
                ),
                Expanded(child: Text(value, key: key)),
              ],
            ),
          );

    return AssetPage(
      child: ListView(
        padding: const EdgeInsets.all(StudioSpacing.gutter),
        children: [
          GestureDetector(
            key: const ValueKey('asset-media'),
            onTap: a.media == null
                ? null
                : () => openStudioMediaViewer(context, items: [a.media!]),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: AspectRatio(
                aspectRatio: _ratio(a.media),
                child: a.media == null
                    ? Container(
                        color: StudioColors.blushPale,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(StudioSpacing.lg),
                        child: Text(t.noMedia, textAlign: TextAlign.center),
                      )
                    : StudioThumb(
                        media: a.media,
                        fit: BoxFit.contain,
                        radius: BorderRadius.circular(StudioRadii.md),
                      ),
              ),
            ),
          ),
          if (a.hidden)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.sm),
              child: Text(
                t.hiddenNotice,
                key: const ValueKey('asset-hidden'),
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: StudioSpacing.lg),
          Text(a.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: StudioSpacing.sm),
          Wrap(
            spacing: StudioSpacing.sm,
            runSpacing: StudioSpacing.xs,
            children: [
              Chip(label: Text(t.kind(a.kind))),
              Chip(label: Text(t.status(a.status))),
              if (c != null) ConsentPill(consent: c),
            ],
          ),
          const SizedBox(height: StudioSpacing.md),
          row(t.fieldFlavour, a.flavour?.name),
          row(
            t.fieldCategory,
            a.category == null ? null : t.category(a.category!),
          ),
          row(t.fieldTags, a.tags.isEmpty ? null : a.tags.join(', ')),
          row(t.fieldNote, a.note),
          row(
            '',
            a.uploadedBy == null ? null : t.uploadedBy(a.uploadedBy!.fullName),
          ),
          row(
            '',
            a.usedCount == 0 ? t.notUsedYet : t.usedTimes(a.usedCount),
            key: const ValueKey('asset-used'),
          ),
          if (canConsent || canUsed) ...[
            const SizedBox(height: StudioSpacing.sm),
            Wrap(
              spacing: StudioSpacing.sm,
              runSpacing: StudioSpacing.sm,
              children: [
                if (canConsent)
                  FilledButton.tonalIcon(
                    key: const ValueKey('action-consent'),
                    icon: const Icon(Icons.verified_user_outlined),
                    label: Text(t.actionConsent),
                    onPressed: () => showConsentSheet(
                      context,
                      asset: a,
                      save:
                          ({
                            required status,
                            who,
                            date,
                            scope,
                            proofMediaId,
                            required requestId,
                          }) => _notifier.setConsent(
                            status,
                            who: who,
                            date: date,
                            scope: scope,
                            proofMediaId: proofMediaId,
                            requestId: requestId,
                          ),
                    ),
                  ),
                if (canUsed)
                  FilledButton.tonalIcon(
                    key: const ValueKey('action-used'),
                    icon: const Icon(Icons.done_all),
                    label: Text(t.actionMarkUsed),
                    onPressed: () => showMarkUsedSheet(
                      context,
                      save: ({required status, note, required requestId}) =>
                          _notifier.markUsed(
                            status: status,
                            note: note,
                            requestId: requestId,
                          ),
                    ),
                  ),
              ],
            ),
          ],
          if (c != null) ...[
            const SizedBox(height: StudioSpacing.lg),
            Card(
              key: const ValueKey('consent-card'),
              child: Padding(
                padding: const EdgeInsets.all(StudioSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.consentTitle, style: theme.textTheme.titleMedium),
                    const SizedBox(height: StudioSpacing.sm),
                    row(t.consentWho, c.who),
                    row(t.consentDate, c.date == null ? null : t.date(c.date)),
                    row(
                      t.consentScope,
                      c.scope == null ? null : t.scope(c.scope!),
                    ),
                    row(t.consentLoggedBy, c.loggedBy?.fullName),
                    if (c.status == ConsentStatus.given)
                      Text(
                        c.paidOk ? t.paidOk : t.paidNotOk,
                        key: const ValueKey('consent-paid'),
                        style: TextStyle(
                          color: c.paidOk
                              ? StudioColors.success
                              : StudioColors.warning,
                        ),
                      ),
                    if (c.proof != null) ...[
                      const SizedBox(height: StudioSpacing.sm),
                      Text(t.consentProof, style: theme.textTheme.bodySmall),
                      const SizedBox(height: StudioSpacing.xs),
                      GestureDetector(
                        onTap: () =>
                            openStudioMediaViewer(context, items: [c.proof!]),
                        child: StudioThumb(
                          media: c.proof,
                          width: 90,
                          height: 120,
                          radius: BorderRadius.circular(StudioRadii.sm),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: StudioSpacing.lg),
          Text(t.ratingTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: StudioSpacing.xs),
          Text(
            a.rating.n == 0
                ? t.noRatingsYet
                : t.ratingSummary(a.rating.avg.toStringAsFixed(1), a.rating.n),
            key: const ValueKey('asset-rating'),
          ),
          if (a.myRating != null)
            Text(
              t.yourRating(a.myRating!.score),
              key: const ValueKey('asset-my-rating'),
              style: theme.textTheme.bodySmall,
            ),
          if (canRate) ...[
            const SizedBox(height: StudioSpacing.sm),
            Wrap(
              spacing: StudioSpacing.sm,
              children: [
                for (var s = 1; s <= 5; s++)
                  ChoiceChip(
                    key: ValueKey('rate-$s'),
                    label: Text('$s  ${t.scoreLabel(s)}'),
                    selected: a.myRating?.score == s,
                    onSelected: (_) => _guard(() => _notifier.rate(s)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: StudioSpacing.lg),
          Text(t.commentsTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: StudioSpacing.xs),
          Text(
            t.commentsCount(a.commentsCount),
            key: const ValueKey('asset-comments'),
          ),
          for (final s in _sent)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.xs),
              child: Text(s, style: theme.textTheme.bodyMedium),
            ),
          if (canComment) ...[
            const SizedBox(height: StudioSpacing.sm),
            TextField(
              key: const ValueKey('comment-field'),
              controller: _comment,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: t.commentHint,
                errorText: _error,
                suffixIcon: IconButton(
                  key: const ValueKey('comment-send'),
                  icon: const Icon(Icons.send),
                  tooltip: t.commentSend,
                  onPressed: _sending ? null : _sendComment,
                ),
              ),
            ),
          ],
          const SizedBox(height: StudioSpacing.xxl),
        ],
      ),
    );
  }

  double _ratio(StudioMedia? m) {
    final w = m?.width, h = m?.height;
    if (w == null || h == null || w == 0 || h == 0) return 0.75;
    return (w / h).clamp(0.5, 1.8).toDouble();
  }
}
