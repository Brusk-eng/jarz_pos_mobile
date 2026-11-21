import 'package:flutter/material.dart';

import '../../data/models/price_sheet.dart';

/// One page of a sheet: the `screen` tier fitted, swapped for the `full` tier
/// once the reader pinches in far enough for the screen image to go soft.
///
/// Shared by the price-sheet preview (pages in a horizontal pager) and the
/// client preview (pages stacked in a vertical list). In both the parent must
/// stop scrolling while a page is zoomed, which [onZoomChanged] reports.
class ZoomableSheetPage extends StatefulWidget {
  const ZoomableSheetPage({
    super.key,
    required this.page,
    required this.onZoomChanged,
    this.panWhenFitted = true,
  });

  final PriceSheetPage page;
  final ValueChanged<bool> onZoomChanged;

  /// False inside a scrolling list: a fitted page then leaves one-finger drags
  /// to the list, and only pans once pinched in.
  final bool panWhenFitted;

  @override
  State<ZoomableSheetPage> createState() => _ZoomableSheetPageState();
}

class _ZoomableSheetPageState extends State<ZoomableSheetPage> {
  static const _fullTierAt = 1.6;

  final _controller = TransformationController();
  bool _useFull = false;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTransform);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTransform);
    _controller.dispose();
    super.dispose();
  }

  void _onTransform() {
    final scale = _controller.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05;
    if (zoomed != _zoomed) {
      _zoomed = zoomed;
      widget.onZoomChanged(zoomed);
      if (!widget.panWhenFitted) setState(() {});
    }
    // Once swapped, stay on the sharp image: swapping back on zoom-out would
    // only re-download what is already cached.
    if (!_useFull && scale >= _fullTierAt && widget.page.full.isNotEmpty) {
      setState(() => _useFull = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _useFull ? widget.page.fullUrl : widget.page.screenUrl;
    return InteractiveViewer(
      transformationController: _controller,
      minScale: 1,
      maxScale: 5,
      panEnabled: widget.panWhenFitted || _zoomed,
      child: Center(
        child: AspectRatio(
          aspectRatio: widget.page.aspectRatio,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6),
              ],
            ),
            child: url.isEmpty
                ? const SizedBox.shrink()
                : Image.network(
                    url,
                    fit: BoxFit.contain,
                    // Keep the fitted image on screen while the sharp one
                    // loads, instead of flashing a spinner mid-pinch.
                    gaplessPlayback: true,
                    loadingBuilder: (context, child, progress) {
                      // Mid-swap the old (fitted) frame is still in [child]
                      // thanks to gaplessPlayback; show it, not a spinner.
                      if (progress == null || _useFull) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, _, _) => const Center(
                      child: Icon(Icons.error_outline, size: 40),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
