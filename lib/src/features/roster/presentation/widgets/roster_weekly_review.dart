import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../branch_access/presentation/server_error_text.dart';
import '../../data/roster_repository.dart';
import '../../models/roster_weekly_models.dart';
import '../roster_formats.dart';
import 'roster_plan_person_card.dart' show rosterPlanWeekdayLabel;

const Key rosterWeeklyReplaceManualKey = ValueKey<String>(
  'roster-weekly-replace-manual',
);
const Key rosterWeeklyApplyKey = ValueKey<String>('roster-weekly-apply');
const Key rosterWeeklyRetryKey = ValueKey<String>('roster-weekly-retry');

/// Amber for "worth checking", as in the plan wizard's review step.
const Color _warningColor = Color(0xFFB26A00);

/// Preview a "Repeat every {weekday}" change, then apply it.
///
/// Resolves to the applied result, or null when dismissed. The preview is a
/// dry run of the exact payload Apply sends; flipping "Replace these too"
/// re-runs it so the counts are the server's, not a guess.
Future<RosterWeeklyResult?> showRosterWeeklyReview(
  BuildContext context, {
  required RosterWeeklyChange change,
}) {
  return showModalBottomSheet<RosterWeeklyResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => RosterWeeklyReviewSheet(change: change),
  );
}

class RosterWeeklyReviewSheet extends ConsumerStatefulWidget {
  const RosterWeeklyReviewSheet({super.key, required this.change});

  final RosterWeeklyChange change;

  @override
  ConsumerState<RosterWeeklyReviewSheet> createState() =>
      _RosterWeeklyReviewSheetState();
}

class _RosterWeeklyReviewSheetState
    extends ConsumerState<RosterWeeklyReviewSheet> {
  late RosterWeeklyChange _change = widget.change;
  bool _loading = true;
  RosterWeeklyResult? _preview;

  /// Why the preview failed: the server's own text when it sent one.
  String? _previewError;

  /// Why Apply failed, shown inline: a snackbar would sit under this sheet.
  String? _applyError;
  bool _applying = false;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_runPreview);
  }

  bool get _canApply =>
      !_loading && !_applying && _preview != null && _previewError == null;

  Future<void> _runPreview() async {
    final seq = ++_seq;
    if (!mounted) return;
    setState(() {
      _loading = true;
      _previewError = null;
      _applyError = null;
    });
    try {
      final result = await ref
          .read(rosterRepositoryProvider)
          .applyWeeklyChange(_change, dryRun: true);
      if (!mounted || seq != _seq) return;
      setState(() {
        _preview = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _preview = null;
        _previewError = serverErrorText(context, error);
        _loading = false;
      });
    }
  }

  Future<void> _apply() async {
    if (!_canApply) return;
    final navigator = Navigator.of(context);
    setState(() {
      _applying = true;
      _applyError = null;
    });
    try {
      final result = await ref
          .read(rosterRepositoryProvider)
          .applyWeeklyChange(_change, dryRun: false);
      if (!mounted) return;
      if (!result.applied) {
        // The server found something the preview did not: show its verdict.
        setState(() {
          _preview = result;
          _applying = false;
          _applyError = context.l10n.rosterWeeklyNotApplied;
        });
        return;
      }
      navigator.pop(result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _applyError = serverErrorText(context, error);
      });
    }
  }

  void _setReplaceManual(bool value) {
    setState(() => _change = _change.copyWith(replaceManual: value));
    _runPreview();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.rosterWeeklyReviewTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(child: _body(context)),
              if (_applyError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _applyError!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _applying
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: rosterWeeklyApplyKey,
                      onPressed: _canApply ? _apply : null,
                      child: _applying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.rosterWeeklyApply),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final result = _preview;

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.rosterWeeklyChecking),
          ],
        ),
      );
    }
    if (_previewError != null || result == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(
              l10n.rosterWeeklyCheckFailed,
              style: theme.textTheme.titleSmall,
            ),
            if (_previewError != null) ...[
              const SizedBox(height: 4),
              Text(_previewError!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 12),
            FilledButton(
              key: rosterWeeklyRetryKey,
              onPressed: _runPreview,
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    final weekdayRaw = result.weekday ?? _change.weekday ?? '';
    final weekday = rosterPlanWeekdayLabel(l10n, weekdayRaw);
    final start = result.start ?? _change.date;
    final through = result.through;
    final rotaFrom = result.rotaFrom;
    final keptGroups = result.keptByPerson;
    final showKept =
        keptGroups.isNotEmpty || result.keptCount > 0 || _change.replaceManual;

    return ListView(
      shrinkWrap: true,
      children: [
        if (result.standing.isNotEmpty) ...[
          _SectionTitle(l10n.rosterWeeklyStandingTitle),
          for (final line in result.standing)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsetsDirectional.only(top: 2, end: 8),
                    child: Icon(Icons.event_repeat, size: 18),
                  ),
                  Expanded(
                    child: Text(
                      l10n.rosterWeeklyStandingLine(
                        line.displayName,
                        rosterPlanWeekdayLabel(l10n, line.weekday),
                        rosterWeeklyServerLabel(l10n, line.before),
                        rosterWeeklyServerLabel(l10n, line.after),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
        Text(
          result.changeCount > 0 && through != null
              ? l10n.rosterWeeklyChangeCount(
                  result.changeCount,
                  rosterNumber(context, result.changeCount),
                  weekday,
                  _date(context, start),
                  _date(context, through),
                )
              : l10n.rosterWeeklyNoDatedDays(weekday),
          style: theme.textTheme.bodyLarge,
        ),
        if (rotaFrom != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              through != null
                  ? l10n.rosterWeeklyRotaFromAfter(
                      _date(context, through),
                      _date(context, rotaFrom),
                    )
                  : l10n.rosterWeeklyRotaFrom(_date(context, rotaFrom)),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SectionTitle(l10n.rosterPlanWarningsTitle, color: _warningColor),
          for (final warning in result.warnings)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(
                Icons.warning_amber_rounded,
                color: _warningColor,
              ),
              title: Text(
                warning.message.isEmpty ? warning.code : warning.message,
              ),
            ),
        ],
        if (showKept) ...[
          const SizedBox(height: 8),
          _SectionTitle(l10n.rosterPlanManualTitle),
          Text(
            _change.replaceManual
                ? l10n.rosterWeeklyReplacedHint
                : l10n.rosterPlanManualHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SwitchListTile(
            key: rosterWeeklyReplaceManualKey,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.rosterPlanReplaceManual),
            value: _change.replaceManual,
            onChanged: _applying ? null : _setReplaceManual,
          ),
          for (final group in keptGroups) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                group.key,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final day in group.value)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8, bottom: 2),
                child: Text(
                  l10n.rosterPlanManualLine(
                    formatDateString(context, day.date, pattern: 'EEE d MMM'),
                    day.kind == 'empty' || day.current == null
                        ? l10n.rosterPlanManualEmpty
                        : rosterWeeklyServerLabel(l10n, day.current),
                  ),
                ),
              ),
          ],
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  /// `d MMM`, with the year only when it is not this year.
  String _date(BuildContext context, String iso) {
    final parsed = DateTime.tryParse(iso);
    final pattern = parsed != null && parsed.year != DateTime.now().year
        ? 'd MMM y'
        : 'd MMM';
    return formatDateString(context, iso, pattern: pattern);
  }
}

/// The server's English cell words, in the screen's language. Shift and
/// branch names are data and pass through as they are.
String rosterWeeklyServerLabel(AppLocalizations l10n, String? raw) {
  final text = (raw ?? '').trim();
  switch (text) {
    case '':
      return l10n.rosterWeeklyNothing;
    case 'Off':
      return l10n.rosterWeeklyOff;
    case 'Empty':
      return l10n.rosterPlanManualEmpty;
    default:
      return text;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
