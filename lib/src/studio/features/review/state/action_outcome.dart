import '../../../data/models/studio_models.dart';
import '../../../data/studio_error.dart';

/// Why a review action did not go through, in the words of the screen.
enum ActionFailure {
  /// GATE_FAILED: the server lists the problems.
  gateFailed,

  /// SHADOW_MODE: the Studio is not switched on yet.
  shadowMode,

  /// STALE: someone changed the version; the fresh copy was loaded.
  stale,

  /// NOT_PERMITTED: the buttons were out of date; the fresh copy was loaded.
  notPermitted,

  /// ALREADY_DONE: someone did it first; the fresh state was loaded.
  alreadyDone,

  /// VALIDATION: the server's own message says what is missing.
  validation,
  network,
  other,
}

/// The result of one action: either it worked, or it failed in one of the
/// [ActionFailure] ways. Nothing is thrown past the state layer.
class ActionOutcome {
  const ActionOutcome.ok()
    : failure = null,
      message = null,
      error = null,
      problems = const [];

  const ActionOutcome.failed(
    ActionFailure this.failure, {
    this.message,
    this.error,
    this.problems = const [],
  });

  final ActionFailure? failure;

  /// The server's plain sentence (used for VALIDATION).
  final String? message;
  final List<StudioProblem> problems;

  /// The error behind a failure, worded by `studioErrorText`.
  final Object? error;

  bool get ok => failure == null;

  /// Maps a thrown error to an outcome.
  factory ActionOutcome.fromError(Object error) {
    return switch (error) {
      StudioGateFailed e => ActionOutcome.failed(
        ActionFailure.gateFailed,
        message: e.message,
        error: error,
        problems: e.problems,
      ),
      StudioShadowMode _ => ActionOutcome.failed(
        ActionFailure.shadowMode,
        error: error,
      ),
      StudioStale _ => ActionOutcome.failed(ActionFailure.stale, error: error),
      StudioNotPermitted _ => ActionOutcome.failed(
        ActionFailure.notPermitted,
        error: error,
      ),
      StudioAlreadyDone _ => ActionOutcome.failed(
        ActionFailure.alreadyDone,
        error: error,
      ),
      StudioValidation e => ActionOutcome.failed(
        ActionFailure.validation,
        message: e.message,
        error: error,
      ),
      StudioNetworkError _ => ActionOutcome.failed(
        ActionFailure.network,
        error: error,
      ),
      _ => ActionOutcome.failed(ActionFailure.other, error: error),
    };
  }
}
