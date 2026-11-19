import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../data/models/followup_models.dart';
import '../../state/followups_providers.dart';

/// Localized label for an outcome.
String followupOutcomeLabel(BuildContext context, FollowupOutcome outcome) {
  final l10n = context.l10n;
  return switch (outcome) {
    FollowupOutcome.happy => l10n.followupsOutcomeHappy,
    FollowupOutcome.quality => l10n.followupsOutcomeQuality,
    FollowupOutcome.delivery => l10n.followupsOutcomeDelivery,
    FollowupOutcome.noReply => l10n.followupsOutcomeNoReply,
    FollowupOutcome.optedOut => l10n.followupsOutcomeOptedOut,
  };
}

/// Opens the "log result" sheet for [row]. Resolves to the server's answer
/// once the touch is logged, or null when the sender backed out.
Future<FollowupLogResult?> showLogTouchSheet(
  BuildContext context,
  FollowupRow row,
) {
  return showModalBottomSheet<FollowupLogResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => LogTouchSheet(row: row),
  );
}

class LogTouchSheet extends ConsumerStatefulWidget {
  const LogTouchSheet({super.key, required this.row});

  final FollowupRow row;

  @override
  ConsumerState<LogTouchSheet> createState() => _LogTouchSheetState();
}

class _LogTouchSheetState extends ConsumerState<LogTouchSheet> {
  final _notes = TextEditingController();
  FollowupReach? _reach;
  FollowupOutcome? _outcome;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  /// A call logged "Not Reached" may only end as "No Reply".
  bool _outcomeAllowed(FollowupOutcome o) =>
      _reach != FollowupReach.notReached || o == FollowupOutcome.noReply;

  Future<bool> _confirmLeavesCycle(FollowupOutcome outcome) async {
    final l10n = context.l10n;
    final isQuality = outcome == FollowupOutcome.quality;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isQuality
              ? l10n.followupsConfirmQualityTitle
              : l10n.followupsConfirmOptOutTitle,
        ),
        content: Text(
          isQuality
              ? l10n.followupsConfirmQualityBody
              : l10n.followupsConfirmOptOutBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final isCall = widget.row.isCall;
    if (isCall && _reach == null) {
      setState(() => _error = l10n.followupsReachedRequired);
      return;
    }
    final outcome = _outcome;
    if (outcome == null || !_outcomeAllowed(outcome)) {
      setState(() => _error = l10n.followupsOutcomeRequired);
      return;
    }
    if (outcome.leavesCycle && !await _confirmLeavesCycle(outcome)) return;
    if (!mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result =
          await ref.read(followupsTodayProvider.notifier).logTouch(
                name: widget.row.name,
                outcome: outcome,
                reached: isCall ? _reach : null,
                notes: _notes.text,
              );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = userErrorMessageFor(l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final row = widget.row;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.followupsLogTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(row.displayName, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              if (row.isCall) ...[
                Text(l10n.followupsReachedLabel,
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<FollowupReach>(
                  emptySelectionAllowed: true,
                  segments: [
                    ButtonSegment(
                      value: FollowupReach.reached,
                      icon: const Icon(Icons.call_received),
                      label: Text(l10n.followupsReached),
                    ),
                    ButtonSegment(
                      value: FollowupReach.notReached,
                      icon: const Icon(Icons.phone_missed),
                      label: Text(l10n.followupsNotReached),
                    ),
                  ],
                  selected: {if (_reach != null) _reach!},
                  onSelectionChanged: _saving
                      ? null
                      : (s) => setState(() {
                            _reach = s.isEmpty ? null : s.first;
                            _error = null;
                            // The backend accepts only "No Reply" for an
                            // unanswered call, so it is forced here.
                            if (_reach == FollowupReach.notReached) {
                              _outcome = FollowupOutcome.noReply;
                            } else if (_outcome == FollowupOutcome.noReply) {
                              _outcome = null;
                            }
                          }),
                ),
                const SizedBox(height: 16),
              ],
              Text(l10n.followupsOutcomeLabel, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in FollowupOutcome.values)
                    ChoiceChip(
                      label: Text(followupOutcomeLabel(context, o)),
                      selected: _outcome == o,
                      onSelected: _saving || !_outcomeAllowed(o)
                          ? null
                          : (sel) => setState(() {
                                _outcome = sel ? o : null;
                                _error = null;
                              }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notes,
                enabled: !_saving,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.commonNotesLabel,
                  hintText: l10n.followupsNotesHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.commonSave),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
