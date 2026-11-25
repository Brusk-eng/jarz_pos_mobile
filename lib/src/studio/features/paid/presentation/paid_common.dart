import 'package:flutter/material.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';

/// Colours for a note level (info, warn, stop).
({Color fg, Color bg, IconData icon}) levelStyle(NoteLevel level) =>
    switch (level) {
      NoteLevel.stop => (
        fg: StudioColors.danger,
        bg: const Color(0xFFFBE3E0),
        icon: Icons.block,
      ),
      NoteLevel.warn => (
        fg: StudioColors.warning,
        bg: const Color(0xFFF5E8CC),
        icon: Icons.warning_amber_rounded,
      ),
      _ => (
        fg: StudioColors.deepPlum,
        bg: StudioColors.blushPale,
        icon: Icons.info_outline,
      ),
    };

/// The same for a signal level (the stop signs list).
NoteLevel noteLevelOfSignal(SignalLevel l) => switch (l) {
  SignalLevel.stop || SignalLevel.red || SignalLevel.bad => NoteLevel.stop,
  SignalLevel.warn || SignalLevel.action => NoteLevel.warn,
  _ => NoteLevel.info,
};

/// A coloured pill for an ad state.
({Color fg, Color bg}) adStateColors(AdState? s) => switch (s) {
  AdState.winner => (fg: const Color(0xFF1F6B4A), bg: const Color(0xFFD7EFE2)),
  AdState.inScale => (fg: Colors.white, bg: StudioColors.success),
  AdState.testing => (fg: const Color(0xFF5A3E85), bg: const Color(0xFFE7DDF5)),
  AdState.oneMoreRound => (
    fg: const Color(0xFF7A5A12),
    bg: const Color(0xFFF5E8CC),
  ),
  AdState.off => (fg: StudioColors.plumMuted, bg: const Color(0xFFF2EFF3)),
  _ => (fg: StudioColors.deepPlum, bg: StudioColors.softBlush),
};
