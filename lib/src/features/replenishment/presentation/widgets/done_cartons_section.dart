import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';

/// Ticked-off cartons, moved out of the way: a "✓ Done (3)" bar at the bottom
/// of the list that opens to show them. Closed by default, so the list in
/// front of the packer is only what is still left to do; tapping a carton in
/// here unticks it and it goes back to its place in the list.
class DoneCartonsSection extends StatefulWidget {
  const DoneCartonsSection({super.key, required this.children});

  final List<Widget> children;

  @override
  State<DoneCartonsSection> createState() => _DoneCartonsSectionState();
}

class _DoneCartonsSectionState extends State<DoneCartonsSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final doneColor = Colors.green.shade700;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: doneColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: doneColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${context.l10n.commonDone} (${widget.children.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: doneColor,
                        ),
                      ),
                    ),
                    Icon(
                      _open ? Icons.expand_less : Icons.expand_more,
                      color: doneColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.topCenter,
            child: _open
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.children,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
