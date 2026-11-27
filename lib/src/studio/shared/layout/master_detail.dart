import 'package:flutter/material.dart';

import '../../core/theme/studio_tokens.dart';
import 'studio_layout.dart';

/// A list on the left and the opened item on the right, from
/// [StudioBreakpoint.expanded] up; below that only the list shows and opening
/// an item pushes its own screen (the phone behaviour, unchanged).
///
/// The caller supplies:
/// * [masterBuilder]: the list. It gets the selected id (null on a phone, or
///   when nothing is open yet) and `open(id)`. `open` selects the id on a wide
///   screen and calls [onPush] on a narrow one.
/// * [detailBuilder]: the opened item, keyed by id so switching items rebuilds
///   it.
/// * [emptyDetail]: what the right pane says before anything is open.
class MasterDetail extends StatefulWidget {
  const MasterDetail({
    super.key,
    required this.masterBuilder,
    required this.detailBuilder,
    required this.onPush,
    this.emptyDetail,
    this.masterWidth = 400,
    this.initialId,
    this.defaultId,
  });

  final Widget Function(
    BuildContext context,
    String? selectedId,
    void Function(String id) open,
  )
  masterBuilder;
  final Widget Function(BuildContext context, String id) detailBuilder;

  /// Opens [id] as its own screen (a narrow window).
  final void Function(String id) onPush;
  final Widget? emptyDetail;
  final double masterWidth;
  final String? initialId;

  /// Shown on a wide screen while nothing has been picked: the first item once
  /// an async list has loaded. Null keeps the right pane empty. A phone ignores
  /// it.
  final String? defaultId;

  @override
  State<MasterDetail> createState() => _MasterDetailState();
}

class _MasterDetailState extends State<MasterDetail> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialId;
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.isWideScreen;
    if (!wide) {
      return widget.masterBuilder(context, null, widget.onPush);
    }
    final id = _selected ?? widget.defaultId;
    return Row(
      children: [
        SizedBox(
          width: widget.masterWidth,
          child: widget.masterBuilder(
            context,
            id,
            (next) => setState(() => _selected = next),
          ),
        ),
        const VerticalDivider(width: 1, color: StudioColors.border),
        Expanded(
          child: id == null
              ? (widget.emptyDetail ?? const SizedBox.shrink())
              : KeyedSubtree(
                  key: ValueKey('master-detail-$id'),
                  child: widget.detailBuilder(context, id),
                ),
        ),
      ],
    );
  }
}

/// The quiet text a detail pane shows before an item is open.
class MasterDetailEmpty extends StatelessWidget {
  const MasterDetailEmpty({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StudioSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.touch_app_outlined,
              size: 36,
              color: StudioColors.plumMuted,
            ),
            const SizedBox(height: StudioSpacing.md),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: StudioColors.plumMuted),
            ),
          ],
        ),
      ),
    );
  }
}
