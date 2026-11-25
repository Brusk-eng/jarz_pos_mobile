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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = DecisionsStrings.of(context);
    final s = InboxStrings.of(context);
    final value = ref.watch(decisionProvider(decisionId));

    Future<void> answer(int index, String? note, String rid) async {
      try {
        await ref
            .read(decisionsRepositoryProvider)
            .answer(decisionId, index, note: note, requestId: rid);
      } on StudioAlreadyDone {
        // Counts as done: show how it stands now.
      }
      ref.invalidate(decisionProvider(decisionId));
      ref.invalidate(decisionsProvider);
      ref.invalidate(inboxCountsProvider);
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
