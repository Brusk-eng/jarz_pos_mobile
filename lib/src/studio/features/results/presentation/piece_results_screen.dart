import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../../data/studio_error.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../shell/more_common.dart';
import '../../shell/more_strings.dart';
import '../results_strings.dart';
import '../state/results_state.dart';

/// Results by piece: each piece with its posts, reads and ads, and the button
/// to file a 72-hour read the platform could not give in full.
class PieceResultsScreen extends ConsumerWidget {
  const PieceResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ResultsStrings.of(context);
    final value = ref.watch(pieceResultsProvider);
    final sort = ref.watch(pieceResultsSortProvider);

    return ViewEditScaffold(
      title: t.piecesTitle,
      parentRoute: '/more/results',
      actions: [
        moreHelpAction(context, title: t.piecesHelpTitle, lines: t.piecesHelp),
      ],
      body: MoreBody(
        child: Column(
          children: [
            ChoiceChipRow<String>(
              options: const ['views', 'hold3'],
              value: sort == 'recent' ? null : sort,
              labelOf: t.sortLabel,
              allLabel: t.sortLabel('recent'),
              onChanged: (v) =>
                  ref.read(pieceResultsSortProvider.notifier).state =
                      v ?? 'recent',
            ),
            Expanded(
              child: StudioAsyncView<PagedState<PieceResult>>(
                value: value,
                onRetry: () => ref.invalidate(pieceResultsProvider),
                empty: StudioEmptyConfig(
                  purpose: t.piecesEmptyPurpose,
                  firstStep: t.piecesEmptyFirstStep,
                  icon: Icons.view_list_outlined,
                ),
                isEmpty: (s) => s.items.isEmpty,
                builder: (context, state) => ListView(
                  key: const ValueKey('piece-results'),
                  children: [
                    for (final r in state.items) _PieceCard(r: r),
                    ShowMoreFooter(
                      state: state,
                      onMore: () =>
                          ref.read(pieceResultsProvider.notifier).loadMore(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PieceCard extends StatelessWidget {
  const _PieceCard({required this.r});

  final PieceResult r;

  @override
  Widget build(BuildContext context) {
    final t = ResultsStrings.of(context);
    final m = MoreStrings.of(context);
    final theme = Theme.of(context);
    return MoreCard(
      key: ValueKey('result-${r.piece.id}'),
      padding: const EdgeInsets.all(StudioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: StudioThumb(media: r.piece.picture),
              ),
              const SizedBox(width: StudioSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.piece.title, style: theme.textTheme.titleSmall),
                    Text(
                      '${t.postsCount(r.posts.length)} · ${t.adsCount(r.ads.length)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: StudioSpacing.sm),
          Row(
            children: [
              Expanded(
                child: LabeledValue(
                  t.bestViews,
                  r.bestViews == null ? '-' : groupDigits(r.bestViews!),
                ),
              ),
              const SizedBox(width: StudioSpacing.lg),
              Expanded(
                child: LabeledValue(
                  t.bestHold,
                  r.bestHold3 == null ? '-' : m.percent(r.bestHold3!),
                ),
              ),
            ],
          ),
          if (r.reads.isNotEmpty) ...[
            const Divider(),
            Text(t.readsTitle, style: theme.textTheme.labelLarge),
            for (final read in r.reads) _ReadRow(read: read),
          ],
        ],
      ),
    );
  }
}

String _bucketLabel(bool ar, ReadBucket b) => switch (b) {
  ReadBucket.v24h => ar ? '24 ساعة' : '24 hours',
  ReadBucket.v72h => ar ? '72 ساعة' : '72 hours',
  ReadBucket.v3d => ar ? '3 أيام' : '3 days',
  ReadBucket.v7d => ar ? '7 أيام' : '7 days',
  ReadBucket.manual => ar ? 'بإيد' : 'By hand',
  ReadBucket.unknown => '',
};

class _ReadRow extends ConsumerWidget {
  const _ReadRow({required this.read});

  final PostRead read;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ResultsStrings.of(context);
    final m = MoreStrings.of(context);
    final theme = Theme.of(context);
    final canFile = read.due && !read.filed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: StudioSpacing.xs),
      child: Row(
        key: ValueKey('read-${read.postId}-${read.bucket.wire}'),
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bucketLabel(m.isArabic, read.bucket),
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  read.filed
                      ? [
                          t.readFiled,
                          if (read.views != null)
                            '${groupDigits(read.views!)} ${t.fieldLabel('views')}',
                        ].join(' · ')
                      : canFile
                      ? t.readDueNow
                      : '${t.readNotOpen} ${m.date(read.opensOn)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (canFile)
            FilledButton.tonal(
              key: ValueKey('file-read-${read.postId}'),
              onPressed: () => _file(context, ref),
              child: Text(t.fileRead),
            ),
        ],
      ),
    );
  }

  Future<void> _file(BuildContext context, WidgetRef ref) async {
    final t = ResultsStrings.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final m = MoreStrings.of(context);
    final values = await showDialog<Map<String, num>>(
      context: context,
      builder: (_) => _FileReadDialog(read: read),
    );
    if (values == null) return;
    final notifier = ref.read(pieceResultsProvider.notifier);
    try {
      await notifier.fileRead(
        read.postId,
        hold3Pct: values['hold3_pct']?.toDouble(),
        views: values['views']?.toInt(),
        reach: values['reach']?.toInt(),
        sends: values['sends']?.toInt(),
        shares: values['shares']?.toInt(),
        likes: values['likes']?.toInt(),
        commentsCount: values['comments_count']?.toInt(),
        saves: values['saves']?.toInt(),
        avgWatchS: values['avg_watch_s']?.toDouble(),
        reelLenS: values['reel_len_s']?.toDouble(),
      );
      showMoreSnack(messenger, t.readFiledOk);
    } on StudioAlreadyDone {
      notifier.markFiled(read.postId);
      showMoreSnack(messenger, t.readAlreadyFiled);
    } catch (e) {
      showMoreSnack(messenger, moreErrorText(m, e));
    }
  }
}

/// Fields the API can give a person to fill when it could not.
const _fillable = [
  'views',
  'reach',
  'sends',
  'shares',
  'likes',
  'saves',
  'comments_count',
  'hold3_pct',
  'avg_watch_s',
  'reel_len_s',
];

const _decimalFields = {'hold3_pct', 'avg_watch_s', 'reel_len_s'};

class _FileReadDialog extends StatefulWidget {
  const _FileReadDialog({required this.read});

  final PostRead read;

  @override
  State<_FileReadDialog> createState() => _FileReadDialogState();
}

class _FileReadDialogState extends State<_FileReadDialog> {
  late final List<String> _fields = [
    for (final f in widget.read.missing)
      if (_fillable.contains(f)) f,
  ];
  late final Map<String, TextEditingController> _c = {
    for (final f in _fields) f: TextEditingController(),
  };

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ResultsStrings.of(context);
    final m = MoreStrings.of(context);
    return AlertDialog(
      key: const ValueKey('file-read-dialog'),
      title: Text(t.fileReadTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _fields.isEmpty ? t.fileReadNothingMissing : t.fileReadHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (final f in _fields)
              TextField(
                key: ValueKey('read-field-$f'),
                controller: _c[f],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    _decimalFields.contains(f)
                        ? RegExp(r'[0-9.]')
                        : RegExp(r'[0-9]'),
                  ),
                ],
                decoration: InputDecoration(labelText: t.fieldLabel(f)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(m.cancel),
        ),
        FilledButton(
          key: const ValueKey('read-send'),
          onPressed: () {
            final out = <String, num>{};
            for (final f in _fields) {
              final text = _c[f]!.text.trim();
              if (text.isEmpty) continue;
              final v = num.tryParse(text);
              if (v != null) out[f] = v;
            }
            Navigator.of(context).pop(out);
          },
          child: Text(t.fileReadSend),
        ),
      ],
    );
  }
}
