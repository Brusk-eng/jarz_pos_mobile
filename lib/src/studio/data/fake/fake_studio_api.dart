import 'dart:convert';

import '../../core/network/studio_api.dart';
import 'studio_endpoint_roles.g.dart';
import 'studio_fixtures.g.dart';

/// An armed failure: the next [times] calls whose key matches throw [code].
class _Failure {
  _Failure(this.match, this.code, this.times, this.overrides);
  final String match;
  final String code;
  int times; // -1 = until cleared
  final Map<String, dynamic> overrides;
}

/// Serves the contract fixtures (`studio_fixtures.g.dart`) with no network.
///
/// * Every endpoint answers its fixture; role variants are honoured:
///   `session.me` reads `me.<role>`, any other key reads `<key>.<role>` first
///   (`today.get.creator`), then `<key>`.
/// * Writes are simulated in memory well enough for optimistic UI work:
///   approve, fix, clear review, rate, comment, tick, answer a decision, keep
///   or drop an idea return the updated object, and later reads of the same id
///   (and the to-approve feed and the inbox counts) reflect them.
/// * Every `actions` list is cut down to what the role may do. The fixtures show
///   the founder's buttons, so each action is looked up in the contract's
///   "Who may call" table (`studio_endpoint_roles.g.dart`, generated) through
///   [fakeActionEndpoints]; an action that table does not know stays.
/// * [failNext] / [failAlways] make a call fail with any contract error code.
/// * Each call waits [delay] first.
class FakeStudioApi extends StudioApi {
  FakeStudioApi({
    this.role = 'founder',
    this.delay = const Duration(milliseconds: 150),
    Map<String, String>? fixtures,
    this.textDecisions = false,
  }) : _fixtures = fixtures ?? studioFixtures;

  /// founder, lead, creator, story, or none (signed in with no Studio role).
  final String role;
  final Duration delay;
  final Map<String, String> _fixtures;

  /// Adds the two decisions answered in words (one open, one answered) to
  /// the decisions list and to the Inbox count. They are served by id either way.
  final bool textDecisions;

  final _failures = <_Failure>[];
  final _patches = <String, Map<String, dynamic>>{};
  final _gone = <String>{}; // version ids that left the to-approve feed
  final _calls = <String>[];
  var _approveDelta = 0;
  var _decisionDelta = 0;
  var _ideaDelta = 0;
  var _unreadDelta = 0;

  /// Every call made so far, as `group.fn`, oldest first (for tests).
  List<String> get calls => List.unmodifiable(_calls);

  /// Every call with the parameters it was sent (for tests: `base_modified`,
  /// explicit nulls).
  List<({String key, Map<String, dynamic> params})> get callLog =>
      List.unmodifiable(_callLog);
  final _callLog = <({String key, Map<String, dynamic> params})>[];

  /// Makes the next [times] calls to [match] fail with the contract error
  /// [code] (UNAUTHENTICATED, NOT_PERMITTED, NOT_FOUND, VALIDATION,
  /// GATE_FAILED, STALE, ALREADY_DONE, SHADOW_MODE, RATE_LIMITED,
  /// SERVER_ERROR). [match] is `group.fn` (`versions.approve`), a bare group
  /// (`versions`) or `*` for every call. The body is the contract's example for
  /// that code; [message], [field], [problems] and [current] replace parts of it.
  void failNext(
    String match,
    String code, {
    int times = 1,
    String? message,
    String? field,
    List<Map<String, String>>? problems,
    Object? current,
  }) {
    _failures.add(
      _Failure(match, code, times, {
        'message': ?message,
        'field': ?field,
        'problems': ?problems,
        'current': ?current,
      }),
    );
  }

  /// Like [failNext] but until [clearFailures].
  void failAlways(String match, String code, {String? message}) =>
      failNext(match, code, times: -1, message: message);

  void clearFailures() => _failures.clear();

  @override
  Future<dynamic> call(
    String method, {
    Map<String, dynamic>? params,
    bool get = false,
  }) async {
    final key = method.startsWith(studioMethodPrefix)
        ? method.substring(studioMethodPrefix.length)
        : method;
    await Future<void>.delayed(delay);
    _calls.add(key);
    _callLog.add((
      key: key,
      params: Map<String, dynamic>.of(params ?? const {}),
    ));
    _throwIfArmed(key);
    final p = params ?? const <String, dynamic>{};
    final written = _write(key, p);
    final result = written ?? _read(key, p);
    return _forRole(_copy(result));
  }

  // ---------------------------------------------------------- role filtering

  static const _letters = {
    'founder': 'F',
    'lead': 'L',
    'creator': 'C',
    'story': 'S',
  };

  /// Cuts every `actions` list in [v] down to what this role may do.
  dynamic _forRole(dynamic v) {
    final letter = _letters[role];
    if (letter == null) return v; // 'none': no Studio role, nothing to filter
    if (v is List) return [for (final e in v) _forRole(e)];
    if (v is! Map) return v;
    final m = <String, dynamic>{
      for (final e in v.entries) e.key as String: _forRole(e.value),
    };
    final acts = m['actions'];
    if (acts is List && acts.every((a) => a is String)) {
      final kind = fakeObjectKind(m);
      final table = kind == null ? null : fakeActionEndpoints[kind];
      if (table != null) {
        m['actions'] = [
          for (final a in acts)
            if (_allowed(table[a], letter)) a,
        ];
      }
    }
    return m;
  }

  bool _allowed(String? endpoint, String letter) {
    if (endpoint == null) return true; // not a gated action (open, rate...)
    final who = studioEndpointRoles[endpoint];
    return who == null || who.contains(letter);
  }

  // ---------------------------------------------------------------- failures

  void _throwIfArmed(String key) {
    for (final f in _failures) {
      final hit =
          f.match == '*' || f.match == key || key.startsWith('${f.match}.');
      if (!hit || f.times == 0) continue;
      if (f.times > 0) f.times--;
      throw _errorFor(f);
    }
  }

  StudioError _errorFor(_Failure f) {
    final examples = jsonDecode(_fixtures['errors']!) as Map<String, dynamic>;
    final example = examples[f.code] as Map<String, dynamic>?;
    if (example == null) {
      return StudioUnknownError('Unknown fake code ${f.code}');
    }
    final body = _copy(example['body']) as Map<String, dynamic>;
    final err = Map<String, dynamic>.from(body['error'] as Map)
      ..addAll(f.overrides);
    return StudioError.fromResponse(example['http_status'] as int, {
      'error': err,
    });
  }

  // ------------------------------------------------------------------- reads

  dynamic _fixture(String key) {
    final names = key == 'session.me'
        ? [if (role != 'none') 'me.$role', 'session.me']
        : ['$key.$role', key];
    for (final n in names) {
      final raw = _fixtures[n];
      if (raw != null) {
        final data = jsonDecode(raw);
        if (key == 'session.me' && role == 'none') return _meWithoutRole(data);
        return data;
      }
    }
    if (key == 'session.me') {
      return _meWithoutRole(jsonDecode(_fixtures['me.founder']!));
    }
    throw StudioNotFound('No fake fixture for $key', statusCode: 404);
  }

  Map<String, dynamic> _meWithoutRole(dynamic me) => {
    ...Map<String, dynamic>.from(me as Map),
    'roles': <String>[],
    'is_founder': false,
    'studio_role': null,
    'nav': <dynamic>[],
  };

  dynamic _read(String key, Map<String, dynamic> p) {
    var data = _fixture(key);
    if (key == 'inbox.to_approve' && data is Map) {
      final items = [
        for (final c in data['items'] as List)
          if (!_gone.contains((c as Map)['version']['id'])) c,
      ];
      data = {
        ...data,
        'items': [
          for (final (i, c) in items.indexed)
            {
              ...Map<String, dynamic>.from(c),
              'position': i + 1,
              'total': items.length,
            },
        ],
      };
    }
    if (key == 'today.get' && data is Map) {
      // A line the person acted on (approved, ticked) is gone on the next read,
      // like the real server: its block loses it, an empty block disappears.
      bool gone(Map line) {
        final id = line['id'];
        return _gone.contains(id) || _patches[id]?['done'] == true;
      }

      data = {
        ...data,
        'blocks': [
          for (final b in data['blocks'] as List)
            if (((b as Map)['lines'] as List).any((l) => !gone(l as Map)))
              {
                ...Map<String, dynamic>.from(b),
                'lines': [
                  for (final l in b['lines'] as List)
                    if (!gone(l as Map)) l,
                ],
                'count':
                    ((b['count'] as int) -
                            (b['lines'] as List)
                                .where((l) => gone(l as Map))
                                .length)
                        .clamp(0, 1 << 30),
              },
        ],
      };
    }
    if (key == 'decisions.get' && data is Map) {
      // The two decisions answered in words are served by id.
      final id = p['decision_id'];
      if (id == 'DEC-00012' || id == 'DEC-00011') {
        data = _fixture(
          id == 'DEC-00012'
              ? 'decisions.get.text_open'
              : 'decisions.get.text_answered',
        );
      }
    }
    if (key == 'decisions.list' && data is Map) {
      // The list holds the option decision and the two in words; `status`
      // narrows it, as on the server.
      final status = p['status'];
      final all = [
        ...(data['items'] as List),
        if (textDecisions) ...[
          _fixture('decisions.get.text_open'),
          _fixture('decisions.get.text_answered'),
        ],
      ];
      String now(Map d) => '${_patches[d['id']]?['status'] ?? d['status']}';
      data = {
        ...data,
        'items': [
          for (final d in all)
            if (status == null || now(d as Map) == status) d,
        ],
      };
    }
    if (key == 'inbox.counts' && data is Map) {
      int n(String k, int delta) =>
          ((data[k] as int) + delta).clamp(0, 1 << 30);
      final a = n('to_approve', _approveDelta);
      final d = n('decisions', _decisionDelta + (textDecisions ? 1 : 0));
      final i = n('ideas', _ideaDelta);
      data = {
        ...data,
        'to_approve': a,
        'decisions': d,
        'ideas': i,
        'unread_notifications': n('unread_notifications', _unreadDelta),
        'total': a + d + i,
      };
    }
    if (key == 'notifications.unread_count' && data is Map) {
      data = {
        'unread': ((data['unread'] as int) + _unreadDelta).clamp(0, 1 << 30),
      };
    }
    return _overlay(data);
  }

  // ------------------------------------------------------------------ writes

  /// Returns the updated object for a simulated write, or null when [key] is
  /// not one (the fixture is then served as it is).
  dynamic _write(String key, Map<String, dynamic> p) {
    switch (key) {
      case 'versions.approve':
        final id = p['version_id'] as String;
        return _versionWrite(id, key, {
          'review_outcome': 'Approved',
          'awaiting_review': false,
          'review_reason': null,
          'actions': ['clear_review', 'rate', 'comment', 'edit_meta'],
        }, leavesFeed: true);
      case 'versions.fix':
        final id = p['version_id'] as String;
        final reason = '${p['reason'] ?? ''}'.trim();
        if (reason.isEmpty) {
          throw const StudioValidation(
            'Give a reason so the creator knows what to fix.',
            field: 'reason',
            statusCode: 422,
          );
        }
        return _versionWrite(id, key, {
          'review_outcome': 'Fix',
          'awaiting_review': false,
          'review_reason': reason,
          'actions': ['clear_review', 'rate', 'comment', 'edit_meta'],
        }, leavesFeed: true);
      case 'versions.clear_review':
        final id = p['version_id'] as String;
        final wasGone = _gone.remove(id);
        if (wasGone) _approveDelta++;
        return _versionWrite(id, key, {
          'review_outcome': null,
          'awaiting_review': true,
          'review_reason': null,
          'actions': ['approve', 'fix', 'rate', 'comment', 'edit_meta'],
        });
      case 'versions.rate':
        final id = p['version_id'] as String;
        final me = _meRef();
        return _versionWrite(id, key, {
          'my_rating': {
            'score': p['score'],
            'comment': p['comment'],
            'person': me,
            'rated_at': _stamp(),
          },
        });
      case 'versions.comment':
        final r = _fixture(key) as Map<String, dynamic>;
        final c = Map<String, dynamic>.from(r['comment'] as Map)
          ..['body'] = p['body'] ?? '';
        final n = (r['comments_count'] as int) + 1;
        return {...r, 'comment': c, 'comments_count': n};
      case 'today.task_tick':
        final id = p['task_id'] as String;
        final skipped = p['skipped'] == true;
        final done = p['done'] != false && !skipped;
        final base = _fixture(key) as Map<String, dynamic>..['id'] = id;
        final patch = {
          'done': done,
          'skipped': skipped,
          'done_at': done || skipped ? _stamp() : null,
          'done_by': done || skipped ? _meRef() : null,
        };
        _patches[id] = {...?_patches[id], ...patch};
        return _overlay(base);
      case 'decisions.answer':
        final id = p['decision_id'] as String;
        final inWords = id == 'DEC-00012' || id == 'DEC-00011';
        final base =
            _fixture(inWords ? 'decisions.get.text_open' : key)
                  as Map<String, dynamic>
              ..['id'] = id;
        final wasOpen = (_patches[id]?['status'] ?? 'Open') == 'Open';
        // The same rules as the server: an option decision takes option_index
        // (and a note), a text decision takes text only, 1 to 2000 characters.
        final text = p['text'] is String ? (p['text'] as String).trim() : null;
        if (inWords) {
          if (p['option_index'] != null) {
            throw const StudioValidation(
              'This question is answered in words, not by an option.',
              field: 'option_index',
              statusCode: 422,
            );
          }
          if (p['note'] != null) {
            throw const StudioValidation(
              'A question answered in words has no note.',
              field: 'note',
              statusCode: 422,
            );
          }
          if (text == null || text.isEmpty) {
            throw const StudioValidation(
              'Write the answer first.',
              field: 'text',
              statusCode: 422,
            );
          }
          if (text.length > 2000) {
            throw const StudioValidation(
              'The answer can be 2000 characters at most.',
              field: 'text',
              statusCode: 422,
            );
          }
        } else {
          if (p['text'] != null) {
            throw const StudioValidation(
              'This decision is answered by an option, not in words.',
              field: 'text',
              statusCode: 422,
            );
          }
          if (p['option_index'] == null && id.startsWith('DEC-')) {
            throw const StudioValidation(
              'Pick an option.',
              field: 'option_index',
              statusCode: 422,
            );
          }
        }
        _patches[id] = {
          ...?_patches[id],
          'status': 'Answered',
          'picked_index': p['option_index'],
          'pick_note': p['note'],
          if (inWords) 'answer_text': text,
          'answered_by': _meRef(),
          'answered_at': _stamp(),
          'actions': <String>[],
        };
        if (wasOpen) _decisionDelta--;
        return _overlay(base);
      case 'ideas.keep':
        final id = p['idea_id'] as String;
        final base = _fixture(key) as Map<String, dynamic>;
        (base['idea'] as Map)['id'] = id;
        _patches[id] = {
          ...?_patches[id],
          'status': 'Kept',
          'decided_at': _stamp(),
          'kept_piece_id': (base['piece'] as Map)['id'],
          'actions': ['edit'],
        };
        _ideaDelta--;
        return _overlay(base);
      case 'ideas.drop':
        final id = p['idea_id'] as String;
        final base = _fixture(key) as Map<String, dynamic>..['id'] = id;
        _patches[id] = {
          ...?_patches[id],
          'status': 'Dropped',
          'drop_reason': p['reason'],
          'decided_at': _stamp(),
          'actions': ['edit'],
        };
        _ideaDelta--;
        return _overlay(base);
      case 'paid.ad_set_state':
        final id = p['ad_id'] as String;
        final raw = '${p['state'] ?? ''}';
        final base = _fixture(key) as Map<String, dynamic>..['id'] = id;
        _patches[id] = {
          ...?_patches[id],
          'state': raw.isEmpty ? null : raw,
          'state_label': raw.isEmpty ? 'Not set' : raw,
          'state_set_at': _stamp(),
          'modified': _stamp(),
        };
        return _overlay(base);
      case 'notifications.mark_read':
        final n = (p['all'] == true)
            ? 0
            : ((_fixture('notifications.unread_count') as Map)['unread']
                      as int) +
                  _unreadDelta -
                  (p['ids'] is List ? (p['ids'] as List).length : 1);
        _unreadDelta =
            n.clamp(0, 1 << 30) -
                    (_fixture('notifications.unread_count') as Map)['unread']
                as int;
        return {'unread': n.clamp(0, 1 << 30)};
    }
    return null;
  }

  dynamic _versionWrite(
    String id,
    String key,
    Map<String, dynamic> patch, {
    bool leavesFeed = false,
  }) {
    final base = _fixture(key) as Map<String, dynamic>..['id'] = id;
    if (leavesFeed && _gone.add(id)) _approveDelta--;
    _patches[id] = {...?_patches[id], ...patch, 'modified': _stamp()};
    return _overlay(base);
  }

  Map<String, dynamic> _meRef() {
    final me = _fixture('session.me') as Map;
    return Map<String, dynamic>.from(
      (me['person'] as Map?) ?? {'key': 'claude', 'full_name': 'Claude'},
    );
  }

  String _stamp() {
    final n = DateTime.now();
    String t(int v, [int w = 2]) => v.toString().padLeft(w, '0');
    return '${t(n.year, 4)}-${t(n.month)}-${t(n.day)}T${t(n.hour)}:${t(n.minute)}:${t(n.second)}+02:00';
  }

  // ----------------------------------------------------------------- helpers

  /// Applies stored patches to every object whose `id` has one.
  dynamic _overlay(dynamic v) {
    if (v is List) return [for (final e in v) _overlay(e)];
    if (v is Map) {
      final m = <String, dynamic>{
        for (final e in v.entries) e.key as String: _overlay(e.value),
      };
      final id = m['id'];
      if (id is String && _patches.containsKey(id)) m.addAll(_patches[id]!);
      return m;
    }
    return v;
  }

  dynamic _copy(dynamic v) => jsonDecode(jsonEncode(v));
}

/// Which contract shape a JSON object is, told apart by a key only that shape
/// has. Null for objects that carry no gated `actions`.
String? fakeObjectKind(Map<String, dynamic> m) {
  bool has(String k) => m.containsKey(k);
  if (has('review_outcome')) return 'version';
  if (has('kept_piece_id')) return 'idea';
  if (has('caption_problems') || (has('posting_mode') && has('slot_time'))) {
    return 'post';
  }
  if (has('due_in_min')) return 'ready_post';
  if (has('assignee_team') && has('stage')) return 'piece';
  if (has('sort_order') && has('skipped')) return 'task';
  if (has('setup') && has('shoot_id')) return 'shot';
  if (has('n_shots')) return 'shoot';
  if (has('consent') && has('media')) return 'asset';
  if (has('remake') && has('competitor')) return 'reference';
  if (has('state_label')) return 'ad';
  if (has('d4_date')) return 'round';
  if (has('queued_by')) return 'queue_item';
  if (has('week_start') && has('gates')) return 'scorecard';
  if (has('options') && has('question')) return 'decision';
  if (has('signal_date')) return 'signal';
  if (has('badge') && has('route') && has('kind')) return 'today_line';
  if (has('default_value')) return 'rule';
  if (has('item_code')) return 'flavour';
  if (has('launch_stage')) return 'moment';
  if (has('studio_role') && has('full_name')) return 'person';
  return null;
}

/// Per object kind: the endpoint each gated action calls, so the fake can read
/// who may call it from the generated contract table. Actions not listed here
/// (open, rate, comment, ...) are open to every Studio role.
const Map<String, Map<String, String>> fakeActionEndpoints = {
  'version': {
    'approve': 'versions.approve',
    'fix': 'versions.fix',
    'clear_review': 'versions.clear_review',
    'edit_meta': 'versions.set_meta',
  },
  'idea': {'keep': 'ideas.keep', 'drop': 'ideas.drop'},
  'piece': {
    'assign': 'pieces.assign',
    'park': 'pieces.park',
    'unpark': 'pieces.unpark',
  },
  'post': {
    'move': 'calendar.post_move',
    'retry': 'calendar.post_retry',
    'wont_post': 'calendar.post_wont_post',
    'mark_posted': 'calendar.post_mark_posted',
    'edit': 'calendar.post_set',
    'set_caption': 'calendar.post_set',
  },
  'ready_post': {
    'mark_posted': 'calendar.post_mark_posted',
    'wont_post': 'calendar.post_wont_post',
    'frame_set': 'calendar.frame_set',
  },
  'task': {'edit': 'today.task_update'},
  'shot': {'edit': 'shoots.shot_set'},
  'shoot': {
    'edit': 'shoots.update',
    'share': 'shoots.share_link',
    'add_shot': 'shoots.shot_set',
  },
  'reference': {'link': 'references.link', 'edit': 'references.update_status'},
  'ad': {'set_state': 'paid.ad_set_state', 'queue_remove': 'paid.queue_remove'},
  'round': {'edit': 'paid.round_set'},
  'queue_item': {'remove': 'paid.queue_remove', 'move': 'paid.queue_reorder'},
  'decision': {'answer': 'decisions.answer'},
  'rule': {'set': 'settings.rule_set'},
  'flavour': {'edit': 'settings.flavour_set'},
  'moment': {'edit': 'settings.moment_set', 'move': 'settings.moment_set'},
  'person': {'edit': 'settings.person_set'},
  'today_line': {
    'approve': 'versions.approve',
    'fix': 'versions.fix',
    'posted': 'calendar.post_mark_posted',
  },
};
