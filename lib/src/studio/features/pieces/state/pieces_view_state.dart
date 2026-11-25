import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../session/state/studio_session_notifier.dart';

/// The three ways to look at the same list of pieces.
enum PiecesView { board, week, list }

/// The chosen view, remembered per person (on this device). Starts on the
/// board, then switches to the saved choice as soon as it is read.
class PiecesViewNotifier extends StateNotifier<PiecesView> {
  PiecesViewNotifier(this._person) : super(PiecesView.board) {
    _load();
  }

  final String _person;

  String get _key => 'studio.pieces.view.$_person';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      final view = PiecesView.values.where((v) => v.name == saved);
      if (view.isNotEmpty && mounted) state = view.first;
    } catch (_) {
      // No storage (private window): keep the default.
    }
  }

  Future<void> choose(PiecesView view) async {
    state = view;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, view.name);
    } catch (_) {
      // Not remembered; still works for this visit.
    }
  }
}

final piecesViewProvider =
    StateNotifierProvider<PiecesViewNotifier, PiecesView>((ref) {
      final me = ref.watch(studioSessionProvider).valueOrNull;
      return PiecesViewNotifier(me?.user ?? 'anyone');
    });
