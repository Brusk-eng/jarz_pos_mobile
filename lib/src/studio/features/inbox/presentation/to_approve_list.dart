import '../../../shared/layout/studio_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/studio_pickers.dart';
import '../../../shared/studio_toast.dart';
import '../../calendar/state/cairo_time.dart';
import '../../review/data/review_repository.dart';
import '../../review/presentation/review_helpers.dart';
import '../../review/presentation/review_sheets.dart';
import '../../review/review_strings.dart';
import '../../review/state/action_outcome.dart';
import '../state/approvals_logic.dart';
import '../state/approvals_state.dart';
import '../state/inbox_state.dart';
import 'approval_card.dart';
import 'approvals_strings.dart';
import 'inbox_hub.dart';

/// The founder's approvals screen: what waits for his yes, and what he has
/// approved that goes out in the next 7 days. One list per tab, ordered by the
/// time it goes out and grouped by day. Every card carries what he needs to
/// decide; the version screen (`/inbox/approve/<id>`) is one tap further.
class ToApproveList extends ConsumerStatefulWidget {
  const ToApproveList({super.key});

  @override
  ConsumerState<ToApproveList> createState() => _ToApproveListState();
}

class _ToApproveListState extends ConsumerState<ToApproveList> {
  /// Cards loaded before the list shows; past it "Load more" is the way on.
  static const _cap = 300;

  bool _approvedTab = false;
  final _busy = <String>{};

  /// A page that failed to load stops the automatic loading of the rest; the
  /// "Load more" button tries again.
  bool _autoFailed = false;

  ApprovalsActions get _actions => ref.read(approvalsActionsProvider);

  Future<void> _run(
    ApproveCard c,
    Future<ActionOutcome> Function() call,
    String Function(ApprovalsStrings s) okText,
  ) async {
    if (_busy.contains(c.version.id)) return;
    setState(() => _busy.add(c.version.id));
    final outcome = await call();
    if (!mounted) return;
    setState(() => _busy.remove(c.version.id));
    if (outcome.ok) {
      showStudioToast(okText(ApprovalsStrings.of(context)));
      return;
    }
    if (outcome.failure == ActionFailure.gateFailed) {
      await showGateProblems(
        context,
        ReviewStrings.of(context),
        outcome.problems,
      );
      return;
    }
    showStudioToast(failureText(context, outcome));
  }

  Future<void> _approve(ApproveCard c) =>
      _run(c, () => _actions.approve(c), (s) => _approvedToast(c, s));

  /// The card itself says what happens next; the toast only confirms.
  String _approvedToast(ApproveCard c, ApprovalsStrings s) => s.approvedToast;

  Future<void> _sendBack(ApproveCard c) async {
    final reason = await showSendBackSheet(context);
    if (reason == null || !mounted) return;
    await _run(c, () => _actions.sendBack(c, reason), (s) => s.sentBack);
  }

  Future<void> _undo(ApproveCard c) =>
      _run(c, () => _actions.undo(c), (s) => s.approvalUndone);

  Future<void> _changeTime(ApproveCard c) async {
    final post = primaryPost(c);
    if (post == null) return;
    final s = ApprovalsStrings.of(context);
    final now = ref.read(studioNowProvider)();
    final current = approvalSlot(c) ?? now;
    final today = DateTime(now.year, now.month, now.day);
    final day = await showStudioDatePicker(
      context: context,
      initialDate: current.isBefore(today) ? today : current,
      firstDate: today,
      lastDate: DateTime(now.year + 1, now.month, now.day),
      helpText: s.pickDate,
    );
    if (day == null || !mounted) return;
    final time = await showStudioTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: s.pickTime,
    );
    if (time == null || !mounted) return;
    final slot = CairoTime.wire(
      DateTime(day.year, day.month, day.day, time.hour, time.minute),
    );
    await _run(c, () => _actions.changeTime(c, post, slot), (s) => s.timeSaved);
  }

  void _open(ApproveCard c) => context.push(InboxPaths.approve(c.version.id));

  /// More pages to fetch before the list can be grouped by time.
  bool _loading(PagedState<ApproveCard> d) =>
      d.hasMore && d.items.length < _cap && !_autoFailed;

  /// One list ordered by time needs every page, so the rest load as soon as
  /// the first one is on screen.
  void _loadAll(PagedState<ApproveCard> d, Future<void> Function() more) {
    if (d.loadingMore || !_loading(d)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await more();
      } catch (_) {
        _autoFailed = true;
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _more(Future<void> Function() load) async {
    _autoFailed = false;
    try {
      await load();
    } catch (_) {
      _autoFailed = true;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = ApprovalsStrings.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StudioSpacing.gutter,
            StudioSpacing.xs,
            StudioSpacing.gutter,
            StudioSpacing.sm,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: context.isWideScreen ? 560 : double.infinity,
              child: SegmentedButton<bool>(
                key: const ValueKey('approvals-tabs'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(
                      s.tabToApprove,
                      key: const ValueKey('approvals-tab-waiting'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(
                      s.tabApproved,
                      key: const ValueKey('approvals-tab-approved'),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                selected: {_approvedTab},
                onSelectionChanged: (v) =>
                    setState(() => _approvedTab = v.first),
              ),
            ),
          ),
        ),
        Expanded(child: _approvedTab ? _approvedBody(s) : _waitingBody(s)),
      ],
    );
  }

  Widget _waitingBody(ApprovalsStrings s) {
    final value = ref.watch(toApproveProvider);
    final here = ref.watch(approvedHereProvider);
    final now = ref.watch(studioNowProvider)();
    return StudioAsyncView<PagedState<ApproveCard>>(
      value: value,
      onRetry: () => ref.invalidate(toApproveProvider),
      empty: StudioEmptyConfig(
        purpose: s.emptyToApprove,
        firstStep: s.emptyToApproveHint,
        icon: Icons.verified_outlined,
      ),
      isEmpty: (d) => d.items.isEmpty && here.isEmpty,
      builder: (context, d) {
        final notifier = ref.read(toApproveProvider.notifier);
        if (_loading(d)) {
          _loadAll(d, notifier.loadMore);
          return const StudioSkeleton();
        }
        final waiting = {for (final c in d.items) c.version.id};
        final cards = [
          ...d.items,
          for (final c in here.values)
            if (!waiting.contains(c.version.id)) c,
        ];
        return RefreshIndicator(
          onRefresh: () async {
            _autoFailed = false;
            ref.read(approvedHereProvider.notifier).clear();
            await notifier.refresh();
          },
          child: _CardList(
            listKey: const ValueKey('approve-list'),
            cards: cards,
            now: now,
            hasMore: d.hasMore,
            onMore: () => _more(notifier.loadMore),
            modeOf: (c) => here.containsKey(c.version.id)
                ? ApprovalCardMode.approved
                : ApprovalCardMode.waiting,
            busy: _busy,
            onApprove: _approve,
            onSendBack: _sendBack,
            onChangeTime: _changeTime,
            onUndo: _undo,
            onOpen: _open,
          ),
        );
      },
    );
  }

  Widget _approvedBody(ApprovalsStrings s) {
    final value = ref.watch(approvedSoonProvider);
    final now = ref.watch(studioNowProvider)();
    return StudioAsyncView<PagedState<ApproveCard>>(
      value: value,
      onRetry: () => ref.invalidate(approvedSoonProvider),
      empty: StudioEmptyConfig(
        purpose: s.emptyApproved,
        firstStep: s.emptyApprovedHint,
        icon: Icons.event_available_outlined,
      ),
      isEmpty: (d) => d.items.isEmpty,
      builder: (context, d) {
        final notifier = ref.read(approvedSoonProvider.notifier);
        if (_loading(d)) {
          _loadAll(d, notifier.loadMore);
          return const StudioSkeleton();
        }
        return RefreshIndicator(
          onRefresh: () async {
            _autoFailed = false;
            await notifier.refresh();
          },
          child: _CardList(
            listKey: const ValueKey('approved-list'),
            cards: d.items,
            now: now,
            hasMore: d.hasMore,
            onMore: () => _more(notifier.loadMore),
            modeOf: (_) => ApprovalCardMode.approved,
            busy: _busy,
            onApprove: _approve,
            onSendBack: _sendBack,
            onChangeTime: _changeTime,
            onUndo: _undo,
            onOpen: _open,
          ),
        );
      },
    );
  }
}

class _CardList extends StatelessWidget {
  const _CardList({
    required this.listKey,
    required this.cards,
    required this.now,
    required this.hasMore,
    required this.onMore,
    required this.modeOf,
    required this.busy,
    required this.onApprove,
    required this.onSendBack,
    required this.onChangeTime,
    required this.onUndo,
    required this.onOpen,
  });

  final Key listKey;
  final List<ApproveCard> cards;
  final DateTime now;
  final bool hasMore;
  final VoidCallback onMore;
  final ApprovalCardMode Function(ApproveCard) modeOf;
  final Set<String> busy;
  final void Function(ApproveCard) onApprove;
  final void Function(ApproveCard) onSendBack;
  final void Function(ApproveCard) onChangeTime;
  final void Function(ApproveCard) onUndo;
  final void Function(ApproveCard) onOpen;

  @override
  Widget build(BuildContext context) {
    final s = ApprovalsStrings.of(context);
    final theme = Theme.of(context);
    final groups = groupApprovals(cards, now);
    List<Widget> groupWidgets(ApprovalGroup g) => [
      Padding(
        padding: const EdgeInsets.only(
          top: StudioSpacing.xs,
          bottom: StudioSpacing.sm,
        ),
        child: Text(
          s.groupTitle(g, g.date == null ? '' : s.dayText(g.date!)),
          key: ValueKey(
            'group-${g.kind.name}${g.kind == ApprovalDay.later ? '-${CairoTime.date(g.date!)}' : ''}',
          ),
          style: theme.textTheme.titleMedium?.copyWith(
            color: g.kind == ApprovalDay.overdue
                ? StudioColors.danger
                : StudioColors.deepPlum,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: StudioSpacing.md),
        // One column on a phone; 2 to 4 cards a row on a wide window.
        child: ResponsiveCardGrid(
          minCellWidth: 470,
          children: [
            for (final c in g.cards)
              ApprovalCard(
                card: c,
                now: now,
                mode: modeOf(c),
                busy: busy.contains(c.version.id),
                onApprove: () => onApprove(c),
                onSendBack: () => onSendBack(c),
                onChangeTime: () => onChangeTime(c),
                onUndo: () => onUndo(c),
                onOpenDetails: () => onOpen(c),
              ),
          ],
        ),
      ),
    ];
    return ListView(
      key: listKey,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(
        context.isWideScreen ? StudioSpacing.xl : StudioSpacing.gutter,
      ),
      children: [
        if (context.isWideScreen)
          // Wide: the days flow into columns, soonest first.
          ResponsiveSectionGrid(
            columnsFor: (w) => w >= 1800 ? 3 : 2,
            gap: StudioSpacing.xl,
            sections: [
              for (final g in groups)
                GridSection(
                  weight: 1 + 4.0 * g.cards.length,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: groupWidgets(g),
                  ),
                ),
            ],
          )
        else
          for (final g in groups) ...groupWidgets(g),
        if (hasMore)
          Center(
            child: TextButton(
              key: const ValueKey('approve-more'),
              onPressed: onMore,
              child: Text(s.loadMore),
            ),
          ),
      ],
    );
  }
}
