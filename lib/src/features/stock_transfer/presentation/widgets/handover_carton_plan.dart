import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../data/stock_handover_models.dart';

/// Cartons the receiver has ticked off, per handover name. Session-only: a
/// tick is a counting aid, never posted anywhere.
final receivedCartonsProvider = StateProvider.family<Set<int>, String>(
  (ref, handoverName) => const <int>{},
);

/// "Cartons to receive: 3 (1 large carton + 2 B2B cartons)", then one tickable
/// row per carton with its lines, so the branch counts cartons before jars.
class HandoverCartonPlanCard extends ConsumerWidget {
  const HandoverCartonPlanCard({
    super.key,
    required this.handoverName,
    required this.plan,
  });

  final String handoverName;
  final HandoverCartonPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final provider = receivedCartonsProvider(handoverName);
    final numbers = {for (final c in plan.cartons) c.number};
    final ticked = ref.watch(provider).where(numbers.contains).toSet();
    final total = plan.cartons.length;
    final done = total > 0 && ticked.length >= total;
    final doneColor = Colors.green.shade700;
    final counts = [
      if (plan.large > 0) l10n.replenishmentCartonCountLarge(plan.large),
      if (plan.b2b > 0) l10n.replenishmentCartonCountB2b(plan.b2b),
    ].join(' + ');

    void toggle(int number) {
      final next = {...ticked};
      if (!next.remove(number)) next.add(number);
      ref.read(provider.notifier).state = next;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.stockHandoverCartonsTitle(total, counts),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.inventory_2_outlined,
              size: 18,
              color: done ? doneColor : theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                done
                    ? l10n.stockHandoverCartonsAllReceived
                    : l10n.stockHandoverCartonsReceivedProgress(
                        ticked.length,
                        total,
                      ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: done ? doneColor : null,
                ),
              ),
            ),
            if (ticked.isNotEmpty)
              TextButton(
                onPressed: () =>
                    ref.read(provider.notifier).state = const <int>{},
                child: Text(l10n.stockHandoverCartonsClear),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : ticked.length / total,
            minHeight: 6,
            color: done ? doneColor : null,
          ),
        ),
        const SizedBox(height: 4),
        for (final carton in plan.cartons)
          _ReceivedCartonRow(
            carton: carton,
            received: ticked.contains(carton.number),
            onToggle: () => toggle(carton.number),
          ),
        if (plan.unpacked.isNotEmpty)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: theme.colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.stockHandoverPackedByHand,
                    style: theme.textTheme.titleSmall,
                  ),
                  for (final line in plan.unpacked)
                    Text('${line.itemName} × ${line.qty}'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ReceivedCartonRow extends StatelessWidget {
  const _ReceivedCartonRow({
    required this.carton,
    required this.received,
    required this.onToggle,
  });

  final CartonPlanCarton carton;
  final bool received;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final type = carton.isLarge
        ? l10n.replenishmentCartonTypeLarge
        : l10n.replenishmentCartonTypeB2b;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: received ? theme.colorScheme.surfaceContainerHighest : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: received,
                onChanged: (_) => onToggle(),
                semanticLabel: l10n.stockHandoverCartonReceivedToggle,
              ),
              Expanded(
                child: Opacity(
                  opacity: received ? 0.55 : 1,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.stockHandoverCartonRow(
                            carton.number,
                            type,
                            carton.jars,
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            decoration: received
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final line in carton.lines)
                          Text('${line.itemName} × ${line.qty}'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
