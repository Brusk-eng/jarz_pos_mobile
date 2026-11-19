import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../data/b2b_repository.dart';
import '../../data/models/b2b_models.dart';

/// Which accounts can take part in a merge-as-branch (either side).
bool canMergeAsBranch(String doctype) =>
    doctype == 'Lead' || doctype == 'Customer';

/// A completed merge plus the names the user saw, for the success message.
class B2bMergeOutcome {
  final B2bMergeResult result;
  final String sourceTitle;
  final String targetTitle;

  const B2bMergeOutcome({
    required this.result,
    required this.sourceTitle,
    required this.targetTitle,
  });
}

/// One side of a merge as the client knows it before the preview answers.
class _Side {
  final String doctype;
  final String name;
  final String title;
  const _Side(this.doctype, this.name, this.title);
}

/// "Add another account as a branch": the rep stands on the account to KEEP,
/// picks the duplicate, confirms, and the duplicate is folded in as a branch.
///
/// By default the picked candidate is the source and the current account the
/// target; the confirmation dialog can swap the two. Returns null when the
/// user backs out at any step.
Future<B2bMergeOutcome?> runMergeAsBranchFlow(
  BuildContext context, {
  required String doctype,
  required String name,
  required String title,
}) async {
  final picked = await showModalBottomSheet<B2bMergeCandidate>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _MergeSearchSheet(doctype: doctype, name: name),
  );
  if (picked == null || !context.mounted) return null;
  return showDialog<B2bMergeOutcome>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _MergeConfirmDialog(
      current: _Side(doctype, name, title),
      picked: _Side(picked.doctype, picked.name, picked.displayName),
    ),
  );
}

class _MergeSearchSheet extends ConsumerStatefulWidget {
  final String doctype;
  final String name;

  const _MergeSearchSheet({required this.doctype, required this.name});

  @override
  ConsumerState<_MergeSearchSheet> createState() => _MergeSearchSheetState();
}

class _MergeSearchSheetState extends ConsumerState<_MergeSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  int _generation = 0;
  bool _loading = false;
  Object? _error;
  List<B2bMergeCandidate> _candidates = const [];

  @override
  void initState() {
    super.initState();
    // An empty query lets the server suggest look-alikes of this account.
    unawaited(_search(''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_search(value)),
    );
  }

  Future<void> _search(String query) async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await ref
          .read(b2bRepositoryProvider)
          .searchMergeTargets(
            doctype: widget.doctype,
            name: widget.name,
            query: query,
          );
      if (!mounted || generation != _generation) return;
      setState(() {
        _candidates = rows
            .where(
              (c) =>
                  canMergeAsBranch(c.doctype) &&
                  !(c.doctype == widget.doctype && c.name == widget.name),
            )
            .toList();
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _candidates = const [];
        _error = e;
      });
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.b2bMergeSearchTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: l10n.b2bMergeSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _results(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _results(BuildContext context) {
    final l10n = context.l10n;
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          context.userErrorMessage(_error),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (!_loading && _candidates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.b2bMergeNoCandidates, textAlign: TextAlign.center),
      );
    }
    return ListView.builder(
      itemCount: _candidates.length,
      itemBuilder: (context, index) {
        final candidate = _candidates[index];
        final details = <String>[
          if (candidate.area != null) candidate.area!,
          if (candidate.mobileNo != null) candidate.mobileNo!,
          if (candidate.branchCount > 0)
            l10n.leadsBranchesCount(candidate.branchCount),
        ];
        return ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  candidate.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              _DoctypeBadge(doctype: candidate.doctype),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (details.isNotEmpty) Text(details.join(' · ')),
              if (candidate.customer != null && candidate.doctype != 'Customer')
                Text(l10n.b2bMergeLinkedCustomer(candidate.customer!)),
            ],
          ),
          onTap: () => Navigator.of(context).pop(candidate),
        );
      },
    );
  }
}

class _DoctypeBadge extends StatelessWidget {
  final String doctype;
  const _DoctypeBadge({required this.doctype});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isCustomer = doctype == 'Customer';
    final color = isCustomer
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isCustomer ? l10n.b2bMergeDoctypeCustomer : l10n.b2bMergeDoctypeLead,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MergeConfirmDialog extends ConsumerStatefulWidget {
  final _Side current;
  final _Side picked;

  const _MergeConfirmDialog({required this.current, required this.picked});

  @override
  ConsumerState<_MergeConfirmDialog> createState() =>
      _MergeConfirmDialogState();
}

class _MergeConfirmDialogState extends ConsumerState<_MergeConfirmDialog> {
  final _branchNameCtrl = TextEditingController();

  /// Default: fold the picked account into the one the rep is standing on.
  bool _pickedIsSource = true;
  B2bMergePreview? _preview;
  Object? _previewError;
  Object? _mergeError;
  bool _loadingPreview = false;
  bool _merging = false;
  int _generation = 0;

  _Side get _source => _pickedIsSource ? widget.picked : widget.current;
  _Side get _target => _pickedIsSource ? widget.current : widget.picked;

  @override
  void initState() {
    super.initState();
    _branchNameCtrl.text = _source.title;
    unawaited(_loadPreview());
  }

  @override
  void dispose() {
    _branchNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    final generation = ++_generation;
    setState(() {
      _loadingPreview = true;
      _preview = null;
      _previewError = null;
      _mergeError = null;
    });
    try {
      final preview = await ref
          .read(b2bRepositoryProvider)
          .previewMergeAsBranch(
            sourceDoctype: _source.doctype,
            sourceName: _source.name,
            targetDoctype: _target.doctype,
            targetName: _target.name,
          );
      if (!mounted || generation != _generation) return;
      setState(() => _preview = preview);
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() => _previewError = e);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loadingPreview = false);
      }
    }
  }

  void _swap() {
    setState(() {
      _pickedIsSource = !_pickedIsSource;
      _branchNameCtrl.text = _source.title;
    });
    unawaited(_loadPreview());
  }

  Future<void> _confirm() async {
    final source = _source;
    final target = _target;
    setState(() {
      _merging = true;
      _mergeError = null;
    });
    try {
      final result = await ref
          .read(b2bRepositoryProvider)
          .mergeAsBranch(
            sourceDoctype: source.doctype,
            sourceName: source.name,
            targetDoctype: target.doctype,
            targetName: target.name,
            branchName: _branchNameCtrl.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop(
        B2bMergeOutcome(
          result: result,
          sourceTitle: _preview?.source.title ?? source.title,
          targetTitle: _preview?.target.title ?? target.title,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _merging = false;
        _mergeError = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final preview = _preview;
    final sourceTitle = preview?.source.title ?? _source.title;
    final targetTitle = preview?.target.title ?? _target.title;
    final canConfirm =
        preview != null &&
        preview.canExecute &&
        preview.blockers.isEmpty &&
        !_merging &&
        !_loadingPreview;

    return AlertDialog(
      title: Text(l10n.b2bMergeConfirmTitle),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.b2bMergeBecomesBranch(sourceTitle, targetTitle),
                style: theme.textTheme.bodyLarge,
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: (_merging || _loadingPreview) ? null : _swap,
                  icon: const Icon(Icons.swap_vert, size: 18),
                  label: Text(l10n.b2bMergeSwap(sourceTitle)),
                ),
              ),
              if (_loadingPreview)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_previewError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    context.userErrorMessage(_previewError),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              if (preview != null) ..._previewDetails(context, preview),
              const SizedBox(height: 12),
              TextField(
                controller: _branchNameCtrl,
                enabled: !_merging,
                decoration: InputDecoration(
                  labelText: l10n.b2bMergeBranchNameLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_mergeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    context.userErrorMessage(_mergeError),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _merging ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: canConfirm ? _confirm : null,
          child: _merging
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.b2bMergeConfirm),
        ),
      ],
    );
  }

  List<Widget> _previewDetails(BuildContext context, B2bMergePreview preview) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final warnings = <String>[
      for (final code in preview.warnings)
        if (_warningText(context, code) case final text?) text,
    ];
    return [
      if (preview.sourceCustomer case final customer?)
        _customerSummary(
          context,
          l10n.b2bMergeSourceCustomer(
            customer.customerName ?? customer.name ?? '',
          ),
          customer,
        ),
      if (preview.targetCustomer case final customer?)
        _customerSummary(
          context,
          l10n.b2bMergeTargetCustomer(
            customer.customerName ?? customer.name ?? '',
          ),
          customer,
        ),
      if (warnings.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(l10n.b2bMergeWarningsTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        for (final text in warnings)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(text)),
              ],
            ),
          ),
      ],
      // Hard blockers (POS default customer, label clash, two Woo accounts):
      // server-written sentences, shown verbatim. No role can override them.
      if (preview.blockers.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(
          l10n.b2bMergeBlockedTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 4),
        for (final text in preview.blockers)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.block, size: 18, color: theme.colorScheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
      ],
      // Otherwise a refusal is the manager-only customer merge.
      if (!preview.canExecute && preview.blockers.isEmpty)
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 18,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.b2bMergeManagerOnly,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _customerSummary(
    BuildContext context,
    String heading,
    B2bMergeCustomerSummary customer,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: theme.textTheme.titleSmall),
          Text(
            [
              l10n.b2bBranchInvoiceCount(customer.invoiceCount),
              l10n.b2bBilledAmount(
                formatCurrency(context, customer.totalBilled),
              ),
            ].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
          if (customer.outstanding > 0.005)
            Text(
              l10n.b2bOutstandingAmount(
                formatCurrency(context, customer.outstanding),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  String? _warningText(BuildContext context, String code) {
    final l10n = context.l10n;
    return switch (code) {
      'irreversible_customer_merge' => l10n.b2bMergeWarningIrreversible,
      'credit_terms_carried_over' => l10n.b2bMergeWarningCredit,
      // An unknown (or retired, e.g. `source_woo_account_dropped`) code from a newer server is not shown as raw English.
      _ => null,
    };
  }
}
