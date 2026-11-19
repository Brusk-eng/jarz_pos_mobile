import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/leads_repository.dart';
import '../../data/models/lead.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../leads_theme.dart';

/// Picks duplicates to fold into a surviving lead.
///
/// The catalog was scraped per-location, so one brand with branches in several
/// areas can arrive as several Leads. This sheet opens on the backend's
/// suggestions (same brand name / phone / Instagram / website) and falls back
/// to a name search, because the duplicate a rep knows about is often the one
/// the heuristics miss — a spelling variant, or an Arabic name.
///
/// Every candidate shows WHY it was suggested. Merging copies branches and
/// fills blank fields on the survivor, and while the sources are kept for audit
/// rather than deleted, undoing it is a Desk job — so the reasons are on screen
/// before the rep commits, not buried behind a tap.
class MergeLeadsSheet extends ConsumerStatefulWidget {
  const MergeLeadsSheet({super.key, required this.lead});

  final Lead lead;

  /// Returns true when at least one lead was merged, so the caller can refresh.
  static Future<bool> show(BuildContext context, Lead lead) async {
    final merged = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LeadsTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MergeLeadsSheet(lead: lead),
    );
    return merged ?? false;
  }

  @override
  ConsumerState<MergeLeadsSheet> createState() => _MergeLeadsSheetState();
}

class _MergeLeadsSheetState extends ConsumerState<MergeLeadsSheet> {
  final _searchController = TextEditingController();
  final _selected = <String>{};

  List<LeadMergeCandidate> _candidates = const [];
  bool _loading = true;
  bool _merging = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String? query}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final found = await ref.read(leadsRepositoryProvider).getMergeCandidates(
            name: widget.lead.name,
            query: query,
          );
      if (!mounted) return;
      setState(() {
        _candidates = found;
        // Drop selections that fell out of the new result set, so the confirm
        // button can never merge something the rep can no longer see.
        _selected.retainWhere((n) => found.any((c) => c.name == n));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = context.userErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _merge() async {
    final chosen = _selected.toList();
    if (chosen.isEmpty) return;

    final survivor = widget.lead.leadName.isEmpty
        ? widget.lead.name
        : widget.lead.leadName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            context.l10n.leadsMergeConfirmTitle(chosen.length, survivor)),
        content: Text(
          context.l10n.leadsMergeConfirmBody(survivor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: LeadsTheme.berryPink),
            child: Text(context.l10n.leadsMergeConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _merging = true);
    try {
      await ref.read(leadsRepositoryProvider).mergeLeads(
            name: widget.lead.name,
            sources: chosen,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _merging = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(
            content: Text(context.userErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: LeadsTheme.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(context.l10n.leadsMergeTitle, style: LeadsTheme.heading),
            const SizedBox(height: 4),
            Text(
              context.l10n.leadsMergeSubtitle(widget.lead.leadName.isEmpty
                  ? widget.lead.name
                  : widget.lead.leadName),
              style: LeadsTheme.bodyMuted,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              style: LeadsTheme.body,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: context.l10n.leadsMergeSearchHint,
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                      ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (value) => _load(query: value),
            ),
            const SizedBox(height: 12),
            Flexible(child: _body()),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _merging ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LeadsTheme.deepPlum,
                      side: const BorderSide(color: LeadsTheme.line),
                    ),
                    child: Text(context.l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        (_selected.isEmpty || _merging) ? null : _merge,
                    icon: _merging
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.merge_type, size: 18),
                    label: Text(
                      _selected.isEmpty
                          ? 'Merge'
                          : context.l10n.leadsMergeAction(_selected.length),
                    ),
                    style: FilledButton.styleFrom(
                        backgroundColor: LeadsTheme.berryPink),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(context.userErrorMessage(_error!), textAlign: TextAlign.center, style: LeadsTheme.bodyMuted),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => _load(query: _searchController.text),
              style: FilledButton.styleFrom(
                  backgroundColor: LeadsTheme.berryPink),
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    }
    if (_candidates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            _searchController.text.trim().isEmpty
                ? context.l10n.leadsMergeNoDuplicates
                : context.l10n.leadsMergeNoMatch,
            textAlign: TextAlign.center,
            style: LeadsTheme.bodyMuted,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: _candidates.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: LeadsTheme.line),
      itemBuilder: (context, index) {
        final candidate = _candidates[index];
        final subtitle = [
          if (candidate.primaryArea.isNotEmpty) candidate.primaryArea,
          context.l10n.leadsBranchesCount(candidate.branchCount),
          if (candidate.phone.isNotEmpty) candidate.phone,
        ].join('  ·  ');

        return CheckboxListTile(
          value: _selected.contains(candidate.name),
          onChanged: _merging
              ? null
              : (checked) => setState(() {
                    if (checked == true) {
                      _selected.add(candidate.name);
                    } else {
                      _selected.remove(candidate.name);
                    }
                  }),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: LeadsTheme.berryPink,
          contentPadding: EdgeInsets.zero,
          title: Text(
            candidate.leadName.isEmpty ? candidate.name : candidate.leadName,
            style: LeadsTheme.body.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle, style: LeadsTheme.bodyMuted),
              if (candidate.reasons.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final reason in candidate.reasons)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: LeadsTheme.blush.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          reason,
                          style: const TextStyle(
                            fontFamily: LeadsTheme.bodyFont,
                            fontSize: 11,
                            color: LeadsTheme.deepPlum,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
