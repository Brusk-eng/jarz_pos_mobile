import 'models/studio_models.dart';

/// A failed Studio call, one case per contract error code (section 1.6) plus
/// [StudioNetworkError] and [StudioUnknownError] for failures with no contract
/// body. Parsed by [StudioError.fromResponse].
sealed class StudioError implements Exception {
  const StudioError(this.message, {this.statusCode});

  /// Plain-English sentence safe to show to the person.
  final String message;
  final int? statusCode;

  /// The contract code, or null for network/unknown.
  String? get code;

  /// True when the session is gone and the app must go to sign-in.
  bool get deadSession => false;

  /// Builds the right case from an HTTP status and a response body.
  ///
  /// A body with an `error` map is read by its `code`; when the code is one
  /// this app does not know, the HTTP status decides. A body without `error`
  /// (Frappe's own failures) is read by status alone. A null [status] means
  /// the request never got an answer.
  factory StudioError.fromResponse(int? status, Object? body) {
    if (status == null) {
      return StudioNetworkError(_bodyText(body) ?? 'No connection.');
    }
    final env = body is Map ? body['error'] : null;
    if (env is Map) {
      final message = '${env['message'] ?? ''}';
      final code = '${env['code'] ?? ''}';
      final current = env['current'];
      final field = env['field'] as String?;
      switch (code) {
        case 'UNAUTHENTICATED':
          return StudioUnauthenticated(message, statusCode: status);
        case 'NOT_PERMITTED':
          return StudioNotPermitted(message, statusCode: status);
        case 'NOT_FOUND':
          return StudioNotFound(message, statusCode: status);
        case 'VALIDATION':
          return StudioValidation(message, field: field, statusCode: status);
        case 'GATE_FAILED':
          return StudioGateFailed(
            message,
            _problems(env['problems']),
            statusCode: status,
          );
        case 'STALE':
          return StudioStale(message, current, statusCode: status);
        case 'ALREADY_DONE':
          return StudioAlreadyDone(message, current, statusCode: status);
        case 'SHADOW_MODE':
          return StudioShadowMode(message, statusCode: status);
        case 'RATE_LIMITED':
          return StudioRateLimited(message, statusCode: status);
        case 'SERVER_ERROR':
          return StudioServerError(message, statusCode: status);
      }
      return _byStatus(status, message);
    }
    if (isDeadSessionResponse(status, body)) {
      return StudioUnauthenticated(
        'Your session ended. Sign in again.',
        statusCode: status,
      );
    }
    return _byStatus(status, _bodyText(body) ?? 'Request failed.');
  }

  static StudioError _byStatus(int status, String message) {
    final m = message.isEmpty ? 'Request failed.' : message;
    return switch (status) {
      401 => StudioUnauthenticated(m, statusCode: status),
      403 => StudioNotPermitted(m, statusCode: status),
      404 => StudioNotFound(m, statusCode: status),
      423 => StudioShadowMode(m, statusCode: status),
      429 => StudioRateLimited(m, statusCode: status),
      >= 500 => StudioServerError(m, statusCode: status),
      _ => StudioUnknownError(m, statusCode: status),
    };
  }

  static List<StudioProblem> _problems(Object? raw) => raw is List
      ? [
          for (final p in raw)
            if (p is Map) StudioProblem.fromJson(Map<String, dynamic>.from(p)),
        ]
      : const [];

  static String? _bodyText(Object? body) {
    if (body == null) return null;
    if (body is Map) {
      final m = body['exception'] ?? body['message'] ?? body['exc_type'];
      return m == null ? null : '$m';
    }
    final s = '$body';
    return s.isEmpty ? null : s;
  }

  @override
  String toString() => 'StudioError($code, $statusCode): $message';
}

/// UNAUTHENTICATED (401): go to sign-in.
final class StudioUnauthenticated extends StudioError {
  const StudioUnauthenticated(super.message, {super.statusCode});
  @override
  String get code => 'UNAUTHENTICATED';
  @override
  bool get deadSession => true;
}

/// NOT_PERMITTED (403): show the message and refresh (the `actions` were stale).
final class StudioNotPermitted extends StudioError {
  const StudioNotPermitted(super.message, {super.statusCode});
  @override
  String get code => 'NOT_PERMITTED';
}

/// NOT_FOUND (404): "no longer there", go back, refresh the list.
final class StudioNotFound extends StudioError {
  const StudioNotFound(super.message, {super.statusCode});
  @override
  String get code => 'NOT_FOUND';
}

/// VALIDATION (422): show [message] at [field].
final class StudioValidation extends StudioError {
  const StudioValidation(super.message, {this.field, super.statusCode});
  final String? field;
  @override
  String get code => 'VALIDATION';
}

/// GATE_FAILED (422): show [problems] as a list; nothing changed.
final class StudioGateFailed extends StudioError {
  const StudioGateFailed(super.message, this.problems, {super.statusCode});
  final List<StudioProblem> problems;
  @override
  String get code => 'GATE_FAILED';
}

/// STALE (409): swap in [current], tell the person, let them retry.
final class StudioStale extends StudioError {
  const StudioStale(super.message, this.current, {super.statusCode});

  /// The fresh object as JSON; parse it with the model of the call.
  final Object? current;
  @override
  String get code => 'STALE';
}

/// ALREADY_DONE (409): success; take [current] and show a quiet "already done".
final class StudioAlreadyDone extends StudioError {
  const StudioAlreadyDone(super.message, this.current, {super.statusCode});
  final Object? current;
  @override
  String get code => 'ALREADY_DONE';
}

/// SHADOW_MODE (423): hide write buttons, show the message.
final class StudioShadowMode extends StudioError {
  const StudioShadowMode(super.message, {super.statusCode});
  @override
  String get code => 'SHADOW_MODE';
}

/// RATE_LIMITED (429): wait and retry once with the same request_id.
final class StudioRateLimited extends StudioError {
  const StudioRateLimited(super.message, {super.statusCode});
  @override
  String get code => 'RATE_LIMITED';
}

/// SERVER_ERROR (500): keep queued actions, retry later with the same request_id.
final class StudioServerError extends StudioError {
  const StudioServerError(super.message, {super.statusCode});
  @override
  String get code => 'SERVER_ERROR';
}

/// No answer from the server (offline, timeout, DNS).
final class StudioNetworkError extends StudioError {
  const StudioNetworkError(super.message);
  @override
  String? get code => null;
}

/// Anything else (an unexpected status, an unreadable body).
final class StudioUnknownError extends StudioError {
  const StudioUnknownError(super.message, {super.statusCode});
  @override
  String? get code => null;
}

/// True when the response means "your session is gone": 401, or a 403 carrying
/// Frappe's Guest wording or an auth exc_type. A plain 403 (signed in, not
/// allowed) is NOT a dead session. Frappe's own failures carry no contract body.
bool isDeadSessionResponse(int? status, Object? body) {
  if (status == 401) return true;
  if (status != 403) return false;
  final text = (body ?? '').toString().toLowerCase();
  if (text.contains('login to access')) return true;
  if (text.contains('not whitelisted') &&
      text.contains('not permitted to access this resource')) {
    return true;
  }
  final excType = body is Map ? '${body['exc_type'] ?? ''}'.toLowerCase() : '';
  return excType == 'sessionexpired' ||
      excType == 'sessionstopped' ||
      excType == 'authenticationerror';
}
