import 'package:jarz_pos/src/core/localization/user_error_message.dart';
import 'package:flutter/material.dart';

import '../production_timestamp.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/ui/loading_overlay.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/posting_date_confirmation_dialog.dart';
import '../../data/models/production_policy.dart';
import '../../data/models/running_batch.dart';
import '../../state/production_providers.dart';
import '../../state/running_batches_notifier.dart';
import 'batch_cost_panel.dart';
import 'batch_date_bar.dart';
import 'batch_line_card.dart' show DecimalTextInputFormatter;
import 'production_format.dart';

/// Asks how much actually came out, then files the Manufacture entry.
///
/// Returns the server's result, or null when the operator backed out or the
/// call failed. Failure keeps the sheet open on purpose: the numbers are still
/// in the fields and the entry has not posted, so a retry costs one tap.
Future<FinishBatchResult?> showFinishBatchSheet(
  BuildContext context, {
  required RunningBatch batch,
}) {
  return showModalBottomSheet<FinishBatchResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: FinishBatchSheet(batch: batch),
    ),
  );
}

class FinishBatchSheet extends ConsumerStatefulWidget {
  const FinishBatchSheet({super.key, required this.batch});

  final RunningBatch batch;

  @override
  ConsumerState<FinishBatchSheet> createState() => _FinishBatchSheetState();
}

class _FinishBatchSheetState extends ConsumerState<FinishBatchSheet> {
  late final TextEditingController _actualCtrl;
  late final TextEditingController _scrapCtrl;
  late final TextEditingController _notesCtrl;
  String? _submitError;

  /// When the batch actually came out.
  ///
  /// This sheet used to post the Manufacture entry at "now", full stop, which
  /// is the whole reason a run made yesterday could not be entered: the Batch
  /// tab could backdate the material transfer and this could not backdate the
  /// output, so the two halves of one batch landed on different days.
  DateTime? _postingDate;

  /// The ceiling the sheet enforces.
  ///
  /// The outstanding quantity, not the ordered one: a batch part-finished
  /// earlier may only be finished for what is still owed. Falls back to the
  /// full planned quantity when nothing is outstanding, so a Work Order that
  /// somehow reached the running list with nothing left still has a way out
  /// instead of a sheet that refuses every number.
  double get _plannedCap => widget.batch.outstandingQty > 0
      ? widget.batch.outstandingQty
      : widget.batch.qty;

  double get _actual => _parse(_actualCtrl.text);
  double get _scrap => _parse(_scrapCtrl.text);

  /// Ticked by default: a finish is usually the end of the batch, and the
  /// stranded-WIP problem this closes came from nobody ever being asked. The
  /// operator unticks it for the case only they can see -- more still to come
  /// out of the same transfer.
  bool _returnLeftover = true;

  /// What this finish will leave in WIP, in the finished item's own units.
  double get _leftoverAfterThisFinish {
    final left = widget.batch.wipLeftoverQty - _actual;
    return left > 0 ? left : 0;
  }

  @override
  void initState() {
    super.initState();
    _actualCtrl = TextEditingController(text: trimQty(_plannedCap, decimals: 3));
    _scrapCtrl = TextEditingController(text: '0');
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _actualCtrl.dispose();
    _scrapCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  static double _parse(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0;

  /// The date the Manufacture entry will carry.
  ///
  /// Defaults to the day the batch was STARTED, not today. A batch started
  /// yesterday and finished this morning otherwise books its material out on
  /// one day and its output on the next, leaving a day of phantom WIP that
  /// nobody can explain later; and somebody entering last week's run has
  /// already said when it happened once, on the Batch tab.
  ///
  /// Falls back to today when the start is unknown, in the future, or outside
  /// what [policy] permits — never to a date the server would refuse.
  DateTime _resolvedDate(ProductionPolicy policy) {
    final chosen = _postingDate;
    if (chosen != null) return chosen;

    final today = policy.today();
    final started = _startedOn;
    if (started == null || !started.isBefore(today)) return today;
    if (!policy.canBackDate) return today;
    if (!policy.unlimitedBackDate &&
        today.difference(started).inDays > policy.maxBackDateDays) {
      return today;
    }
    return started;
  }

  /// The moment the batch was started (`jarz_started_at`, server wall clock),
  /// or null when unparseable.
  DateTime? get _startedMoment {
    final raw = widget.batch.startedAt;
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim().replaceFirst(' ', 'T'));
  }

  /// The calendar day the batch was started, or null when unparseable.
  DateTime? get _startedOn {
    final parsed = _startedMoment;
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// Why the batch cannot be finished as typed, or null when it can.
  String? _validationError(BuildContext context) {
    final l10n = context.l10n;
    if (_actual <= 0) return l10n.productionQtyMustBePositive;
    // Blocked rather than warned: over-production against a Work Order is a
    // real stock movement the plan never authorised, and "are you sure" on a
    // shop floor is answered yes by reflex.
    if (_actual > _plannedCap + 1e-9) {
      return l10n.productionActualExceedsPlanned(
        trimQty(_plannedCap, decimals: 3),
      );
    }
    if (_scrap < 0) return l10n.productionQtyMustBePositive;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final batch = widget.batch;
    final policy = ref.watch(productionPolicyOrFallbackProvider);
    final error = _validationError(context);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.getDialogWidth(
              context,
              small: 520,
              medium: 560,
              large: 620,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.productionFinishTitle,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                batch.itemName.isEmpty ? batch.itemCode : batch.itemName,
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                l10n.productionPlannedVsProduced(
                  '${trimQty(batch.qty)} ${batch.stockUom}'.trim(),
                  trimQty(batch.producedQty),
                ),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              // Same bar as the Batch tab, same server-supplied window: the two
              // halves of a batch are dated by one rule, not two.
              BatchDateBar(
                date: _resolvedDate(policy),
                policy: policy,
                timeChosen: hasExplicitPostingTime(_postingDate),
                // A batch cannot be finished before its material went in. The
                // server refuses that outright; clamping here means the date is
                // never offered rather than refused after three taps.
                earliest: _startedOn,
                onChanged: (value) => setState(() => _postingDate = value),
              ),
              const SizedBox(height: 8),
              _QtyField(
                key: const Key('finishActualQty'),
                label: l10n.productionActualQty,
                controller: _actualCtrl,
                suffix: batch.stockUom,
                onChanged: () => setState(() => _submitError = null),
              ),
              const SizedBox(height: 12),
              _QtyField(
                key: const Key('finishScrapQty'),
                label: l10n.productionScrapQty,
                controller: _scrapCtrl,
                suffix: batch.stockUom,
                onChanged: () => setState(() => _submitError = null),
              ),
              // Only when this finish will actually leave something behind.
              // The server cannot tell a short yield from a batch still in the
              // mixer -- both are a finish under the planned quantity -- so
              // the one person who can is asked, and only when it matters.
              if (_leftoverAfterThisFinish > 0) ...[
                const SizedBox(height: 4),
                CheckboxListTile(
                  key: const Key('finishReturnLeftover'),
                  value: _returnLeftover,
                  onChanged: (value) =>
                      setState(() => _returnLeftover = value ?? false),
                  title: Text(
                    l10n.productionReturnLeftover(
                      trimQty(_leftoverAfterThisFinish),
                      batch.stockUom,
                    ),
                  ),
                  subtitle: Text(l10n.productionReturnLeftoverHint),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                key: const Key('finishNotes'),
                controller: _notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.productionBatchNotes,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              if (error != null || _submitError != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 16, color: theme.colorScheme.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        error ?? _submitError!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              BatchCostPanel(workOrder: batch.workOrder),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.commonCancel),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const Key('finishSubmit'),
                    onPressed: error == null ? _submit : null,
                    child: Text(l10n.productionFinish),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final notes = _notesCtrl.text.trim();
    final policy = ref.read(productionPolicyOrFallbackProvider);
    final postingDate = _resolvedDate(policy);

    // The default here is the batch's START day, so this sheet can post a
    // backdated Manufacture entry — with its COGS and its finished-goods
    // availability — without the operator having chosen a date at all. Both
    // Batch-tab paths confirm before posting; this one has more reason to,
    // not less.
    if (policy.isBackDated(postingDate)) {
      final confirmed = await confirmPostingDatesBeforeSubmit(
        context,
        dates: [postingDate],
        includeTime: hasExplicitPostingTime(_postingDate),
      );
      if (!confirmed || !mounted) return;
    }

    ref.loading.show(l10n.productionSubmitting);
    FinishBatchResult result;
    try {
      result = await ref.read(runningBatchesProvider.notifier).finish(
            workOrder: widget.batch.workOrder,
            actualQty: _actual,
            scrapQty: _scrap,
            scheduledAt: finishScheduledAt(
              postingDate,
              policy.today(),
              // Read from the value, not from "a date was picked": this sheet
              // seeds the time picker from a bare day, so tapping straight
              // through it yields 00:00 — a default, not a choice, and posting
              // the output at the start of the day is what puts a Manufacture
              // entry before the transfer that fed it.
              explicitTime: hasExplicitPostingTime(_postingDate),
              startedAt: _startedMoment,
            ),
            notes: notes.isEmpty ? null : notes,
            returnLeftover: _returnLeftover && _leftoverAfterThisFinish > 0,
          );
    } catch (error) {
      ref.loading.hide();
      if (!mounted) return;
      setState(() {
        _submitError =
            context.userErrorMessage(error, fallback: l10n.commonError);
      });
      return;
    }
    ref.loading.hide();

    if (!mounted) return;
    navigator.pop(result);
  }
}

class _QtyField extends StatelessWidget {
  const _QtyField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      // Shares the Batch tab's formatter: it allows a partially typed decimal
      // ("1.") and rejects a leading minus outright, so negative scrap cannot
      // even be entered.
      inputFormatters: const [DecimalTextInputFormatter()],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (_) => onChanged(),
    );
  }
}
