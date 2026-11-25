import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/studio_screen.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/studio_error.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../inbox/presentation/inbox_strings.dart';
import '../../review/data/review_repository.dart';
import '../data/decisions_repository.dart';
import 'decision_card.dart';
import 'decisions_strings.dart';

/// One decision by id (`/inbox/decisions/<id>`, from a push or a Today line).
class DecisionScreen extends ConsumerWidget {
  const DecisionScreen({super.key, required this.decisionId});

  final String decisionId;

  void _refresh(WidgetRef ref) {
    ref.invalidate(decisionProvider(decisionId));
    ref.invalidate(decisionsProvider);
    ref.invalidate(inboxCountsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = DecisionsStrings.of(context);
    final s = InboxStrings.of(context);
    final value = ref.watch(decisionProvider(decisionId));

    Future<void> answer(
      int? index,
      String? note,
      String rid, {
      String? text,
    }) async {
      try {
        await ref
            .read(decisionsRepositoryProvider)
            .answer(decisionId, index, note: note, text: text, requestId: rid);
      } on StudioAlreadyDone {
        // The first answer stands: show how it stands now, and say so.
        _refresh(ref);
        rethrow;
      }
      _refresh(ref);
    }

    return ViewEditScaffold(
      title: t.title,
      screen: StudioScreen.decisions,
      parentRoute: StudioRoutes.inboxDecisions,
      showLanguageSwitch: true,
      body: StudioAsyncView<StudioDecision>(
        value: value,
        onRetry: () => ref.invalidate(decisionProvider(decisionId)),
        empty: StudioEmptyConfig(
          purpose: t.decisionGone,
          firstStep: s.errNotFound,
        ),
        builder: (context, d) => ListView(
          padding: const EdgeInsets.all(StudioSpacing.gutter),
          children: [DecisionCard(decision: d, onAnswer: answer)],
        ),
      ),
    );
  }
}
