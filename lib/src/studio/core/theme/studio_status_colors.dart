import 'package:flutter/material.dart';

import '../../data/models/studio_enums.dart';
import 'studio_tokens.dart';

/// The nine stages a piece moves through (SYSTEM_DESIGN section 3).
enum PieceStage {
  idea,
  script,
  toShoot,
  toEdit,
  inReview,
  approved,
  scheduled,
  posted,
  read;

  /// The server's stage name.
  String get apiName => switch (this) {
    PieceStage.idea => 'Idea',
    PieceStage.script => 'Script',
    PieceStage.toShoot => 'To shoot',
    PieceStage.toEdit => 'To edit',
    PieceStage.inReview => 'In review',
    PieceStage.approved => 'Approved',
    PieceStage.scheduled => 'Scheduled',
    PieceStage.posted => 'Posted',
    PieceStage.read => 'Read',
  };
}

/// Ad-sell-judge verdicts.
enum Verdict { run, fix, drop }

/// Foreground / background pair for a chip.
class StatusColors {
  const StatusColors(this.foreground, this.background);

  final Color foreground;
  final Color background;
}

/// Early stages are quiet (plum on blush), the middle warms up, approved and
/// beyond turn green or plum, so a board reads left to right as progress.
const Map<PieceStage, StatusColors> stageColors = {
  PieceStage.idea: StatusColors(StudioColors.plumMuted, Color(0xFFF2EFF3)),
  PieceStage.script: StatusColors(
    StudioColors.deepPlum,
    StudioColors.softBlush,
  ),
  PieceStage.toShoot: StatusColors(Color(0xFF8A2F3B), Color(0xFFFBD9DE)),
  PieceStage.toEdit: StatusColors(Color(0xFF7A5A12), Color(0xFFF5E8CC)),
  PieceStage.inReview: StatusColors(Color(0xFF5A3E85), Color(0xFFE7DDF5)),
  PieceStage.approved: StatusColors(Color(0xFF1F6B4A), Color(0xFFD7EFE2)),
  PieceStage.scheduled: StatusColors(Color(0xFF1F5C7A), Color(0xFFD9ECF5)),
  PieceStage.posted: StatusColors(Colors.white, StudioColors.success),
  PieceStage.read: StatusColors(Colors.white, StudioColors.deepPlum),
};

const Map<Verdict, StatusColors> verdictColors = {
  Verdict.run: StatusColors(Colors.white, StudioColors.success),
  Verdict.fix: StatusColors(Colors.white, StudioColors.warning),
  Verdict.drop: StatusColors(Colors.white, StudioColors.danger),
};

/// One colour per post status, none of them a stage colour: grey while a
/// draft, teal once checked, indigo when scheduled, amber while publishing,
/// green once out, red when it failed, faded grey when cancelled. All pairs
/// read on the light theme (text contrast 4.5:1 or better).
const Map<PostStatus, StatusColors> postStatusColors = {
  PostStatus.draft: StatusColors(Color(0xFF55526A), Color(0xFFECEAF0)),
  PostStatus.checked: StatusColors(Color(0xFF14625F), Color(0xFFD3EEEB)),
  PostStatus.scheduled: StatusColors(Color(0xFF2B479A), Color(0xFFDDE6FB)),
  PostStatus.publishing: StatusColors(Color(0xFF8F4509), Color(0xFFFCE2C8)),
  PostStatus.published: StatusColors(Colors.white, Color(0xFF2B7A55)),
  PostStatus.failed: StatusColors(Colors.white, StudioColors.danger),
  PostStatus.cancelled: StatusColors(Color(0xFF6E6B7A), Color(0xFFF3F1F4)),
  PostStatus.unknown: StatusColors(Color(0xFF6E6B7A), Color(0xFFF3F1F4)),
};
