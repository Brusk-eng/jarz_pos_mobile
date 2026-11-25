import 'package:flutter/material.dart';

import '../core/theme/studio_tokens.dart';
import '../data/models/studio_models.dart';
import 'person_text.dart';
import 'media/studio_media_widgets.dart';

/// The one row for "a picture and two lines": a version in a piece, a
/// candidate for the paid queue, an ad in the glance. Thumbnail 44 x 56, a
/// title, an optional second line, an optional trailing widget; the whole row
/// taps when [onTap] is set.
class StudioMediaRow extends StatelessWidget {
  const StudioMediaRow({
    super.key,
    required this.media,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final StudioMedia? media;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: StudioSpacing.sm),
    child: ListTile(
      leading: StudioThumb(
        media: media,
        width: 44,
        height: 56,
        radius: BorderRadius.circular(StudioRadii.sm),
      ),
      title: PersonText(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
      onTap: onTap,
    ),
  );
}
