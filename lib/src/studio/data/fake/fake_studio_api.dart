import 'dart:convert';

import '../../core/l10n/plural.dart';
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
    this.firstLogin = false,
    this.storyFrames = false,
    String? serverLang,
  }) : _lang = serverLang,
       _fixtures = fixtures ?? studioFixtures;

  /// founder, lead, creator, story, or none (signed in with no Studio role).
  final String role;
  final Duration delay;
  final Map<String, String> _fixtures;

  /// Adds the two decisions answered in words (one open, one answered) to
  /// the decisions list and to the Inbox count. They are served by id either way.
  final bool textDecisions;

  /// A person opening the app for the first time: `session.me` does not list
  /// the role's walkthrough as seen until `session.help_seen` is called with
  /// it. Off in tests (they open the app already walked through); the running
  /// fake app turns it on.
  final bool firstLogin;

  /// Serves the story slot `SP-2026-00310` as four frames (photos and a clip)
  /// that [calendar.frame_set] decides one by one, instead of the contract's
  /// sample slot. The running fake app turns it on.
  final bool storyFrames;
  final _seenHelp = <String>{};

  /// The language the server holds for this person (`NotificationPrefs.lang`);
  /// null until the app sends one. Lines the server words (Today, the
  /// notifications) come back in it.
  String? _lang;
  String? get serverLang => _lang;

  final _failures = <_Failure>[];
  final _patches = <String, Map<String, dynamic>>{
    // A post marked won't post, as the contract shows one
    // (`calendar.post_wont_post`): Cancelled, with its reason, and "Put back"
    // (`reopen`) as its one action. It is the post the sample What changed
    // line is about. The Won't post list, What changed and the
    // range filtered by status all read this one fact.
    _wontPostId: {
      'status': 'Cancelled',
      'skip_reason': 'Same footage as the reel on Sunday',
      'actions': ['reopen'],
    },
  };
  static const _wontPostId = 'SP-2026-00230';

  /// Rows added to What changed by writes made in this run (newest last).
  final _changeRows = <Map<String, dynamic>>[];

  /// Competitors removed or restored in this run, by key.
  final _competitorPatches = <String, Map<String, dynamic>>{};
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
    if (!get) announceCall(key);
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
      // The sample shots offer only `tick`; the server also offers `note` to
      // whoever may call shoots.shot_note.
      if (kind == 'shot' &&
          _allowed('shoots.shot_note', letter) &&
          !(m['actions'] as List).contains('note')) {
        m['actions'] = [...(m['actions'] as List), 'note'];
      }
      // "Creators cannot Drop" a reference (references.update_status).
      if (kind == 'reference' && role != 'founder' && role != 'lead') {
        m['actions'] = [
          for (final a in m['actions'] as List)
            if (a != 'drop') a,
        ];
      }
      // A reference already on the shortlist is not offered Add to shortlist
      // (the server offers it only to a reference that is not there yet).
      if (kind == 'reference' && m['status'] == 'Shortlisted') {
        m['actions'] = [
          for (final a in m['actions'] as List)
            if (a != 'shortlist') a,
        ];
      }
      // A creator may add a line to the scorecard and nothing else on it.
      if (kind == 'scorecard' && role == 'creator') {
        m['actions'] = [
          for (final a in m['actions'] as List)
            if (a == 'add_line') a,
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
        if (key == 'session.me') return _meSeen(data as Map<String, dynamic>);
        return data;
      }
    }
    if (key == 'session.me') {
      return _meWithoutRole(jsonDecode(_fixtures['me.founder']!));
    }
    throw StudioNotFound('No fake fixture for $key', statusCode: 404);
  }

  /// The help this person has seen: every walkthrough when the app is not
  /// on a first login, none of them (but what was marked in this run) when it
  /// is. A creator also gets Results (the contract lets the role read the
  /// scorecard and add a line).
  Map<String, dynamic> _meSeen(Map<String, dynamic> me) {
    final seen = <String>{
      for (final k in (me['seen_help'] as List? ?? const []))
        if (!'$k'.startsWith('walkthrough')) '$k',
      ..._seenHelp,
      if (!firstLogin) 'walkthrough_$role',
    };
    final nav = [...(me['nav'] as List)];
    if (role == 'creator' && !nav.any((n) => (n as Map)['key'] == 'results')) {
      final refs = nav.indexWhere((n) => (n as Map)['key'] == 'references');
      nav.insert(refs + 1, {
        'key': 'results',
        'label': 'Results',
        'route': '/results',
        'in_bar': false,
        'badge': null,
      });
    }
    return {...me, 'seen_help': seen.toList(), 'nav': nav};
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
    if (key == 'today.get' && data is Map) data = _todayFor(data, p);
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
        final p = _patches[id];
        return _gone.contains(id) ||
            p?['done'] == true ||
            p?['skipped'] == true ||
            const {
              'Answered',
              'Kept',
              'Dropped',
              'Published',
              'Skipped',
            }.contains(p?['status']);
      }

      final counts = Map<String, dynamic>.from(data['counts'] as Map);
      void adj(String k, int delta) =>
          counts[k] = ((counts[k] as int) + delta).clamp(0, 1 << 30);
      adj('to_approve', _approveDelta);
      adj('decisions', _decisionDelta);
      adj('ideas', _ideaDelta);
      counts['total'] =
          (counts['to_approve'] as int) +
          (counts['decisions'] as int) +
          (counts['ideas'] as int);
      data = {
        ...data,
        'counts': counts,
        'blocks': [
          for (final b in data['blocks'] as List)
            if (((b as Map)['lines'] as List).any((l) => !gone(l as Map)))
              {
                ...Map<String, dynamic>.from(b),
                'lines': [
                  for (final l in b['lines'] as List)
                    if (!gone(l as Map)) _storyLine(l),
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
    if (key == 'paid.round_get' && data is Map) {
      // An ad whose state was set moves between the round's counters.
      final counts = Map<String, dynamic>.from(data['state_counts'] as Map);
      for (final a in data['ads'] as List) {
        final was = '${(a as Map)['state_label']}';
        final now = '${_patches[a['id']]?['state_label'] ?? was}';
        if (was == now) continue;
        counts[was] = ((counts[was] as int? ?? 1) - 1).clamp(0, 1 << 30);
        if (counts[was] == 0) counts.remove(was);
        counts[now] = (counts[now] as int? ?? 0) + 1;
      }
      data = {...data, 'state_counts': counts};
    }
    if (key == 'versions.get' && data is Map) {
      // A version the person already approved, sent back or cleared reads back
      // as that version, with its piece's new stage and the buttons that
      // follow the outcome.
      final id = '${p['version_id']}';
      if (_patches.containsKey(id)) {
        data = {...data, 'id': id};
        final owner = _pieceOfVersion(id);
        if (owner != null && data['piece'] is Map) {
          data['piece'] = {
            ...Map<String, dynamic>.from(data['piece'] as Map),
            'id': owner,
          };
        }
      }
    }
    if (key == 'results.scorecard' && data is Map && _lang == 'ar') {
      data = _scorecardAr(data);
    }
    if (key == 'today.tasks' && data is Map) data = _tasks(data, p);
    if (key == 'today.get' && data is Map && _lang == 'ar') {
      data = _todayAr(data);
    }
    if (key == 'notifications.list' && data is Map && _lang == 'ar') {
      data = {
        ...data,
        'items': [
          for (final n in data['items'] as List)
            {
              ...Map<String, dynamic>.from(n as Map),
              'title': 'جاهز لموافقتك',
              // The piece title is wrapped, as the server wraps text that runs
              // the other way than its sentence.
              'body': '\u2068${n["body"]}\u2069',
            },
        ],
      };
    }
    if (key == 'settings.my_notifications' && data is Map) {
      data = {...data, 'lang': _lang};
    }
    if (key == 'calendar.changes' && data is Map) data = _changesNow(data);
    if (key == 'references.competitors' && data is Map) {
      data = _competitorsNow(data, p);
    }
    if (key == 'references.competitor_get' && data is Map) {
      data = _competitorNow(data, '${p['key']}');
    }
    if (key == 'calendar.range' && data is Map) {
      // The status filter, as the server applies it (after the writes made
      // here are applied).
      final status = p['status'];
      final from = '${p['from'] ?? ''}';
      final to = '${p['to'] ?? ''}';
      final now = _overlay(data) as Map<String, dynamic>;
      // Window-bounded, as the contract says: a post outside the days asked
      // for is not in the answer.
      bool inWindow(Map post) {
        final slot = '${post['slot_time'] ?? ''}';
        if (from.isEmpty || to.isEmpty || slot.length < 10) return true;
        final day = slot.substring(0, 10);
        return day.compareTo(from) >= 0 && day.compareTo(to) <= 0;
      }

      return {
        ...now,
        'posts': [
          for (final post in now['posts'] as List)
            if (inWindow(post as Map) &&
                (status == null || post['status'] == status))
              post,
        ],
      };
    }
    if (key == 'calendar.post_get' && data is Map) data = _post(data, p);
    if (key == 'calendar.ready_to_post' && data is Map) {
      data = {
        ...data,
        'items': [
          for (final i in data['items'] as List)
            if (_patches[((i as Map)['post'] as Map)['id']]?['status'] == null)
              i,
        ],
      };
    }
    if (key == 'calendar.drift' && data is Map) {
      bool handled(Map m) {
        final s = _patches[(m['post'] as Map)['id']];
        return s?['status'] != null || s?['retried'] == true;
      }

      data = {
        ...data,
        'missing': [
          for (final m in data['missing'] as List)
            if (!handled(m as Map)) m,
        ],
      };
    }
    if (key == 'shoots.get' || key == 'shoots.sync' || key == 'shoots.list') {
      data = _shootsNow(data);
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

  /// The scorecard's gate details, as the server words them for a person whose
  /// language is Arabic (the fixtures hold the English).
  Map _scorecardAr(Map data) {
    String word(String s) {
      final tagged = RegExp(r'^(\d+)% tagged$').firstMatch(s);
      if (tagged != null) return '${tagged.group(1)}% متعلّمة';
      final against = RegExp(r'^(\d+) against (\d+)$').firstMatch(s);
      if (against != null) {
        return '${against.group(1)} مقابل ${against.group(2)}';
      }
      if (s == 'Not entered yet') return 'لسه ما اتسجّلش';
      return s;
    }

    return {
      ...data,
      'gates': [
        for (final g in data['gates'] as List)
          {
            ...Map<String, dynamic>.from(g as Map),
            if (g['detail'] is String) 'detail': word(g['detail'] as String),
          },
      ],
    };
  }

  /// Today in Arabic, as the server words it for a person whose language is
  /// Arabic: the waiting time of a line, with the flavour in isolate marks.
  Map _todayAr(Map data) {
    String word(String s) {
      final parts = s.split(' \u00b7 ');
      return [
        for (final part in parts)
          if (RegExp(r'^waiting (\d+) days?$').firstMatch(part) case final m?)
            'مستني من ${arDay.of(int.parse(m.group(1)!))}'
          else if (part == parts.first)
            part
          else
            '\u2068$part\u2069',
      ].join(' \u00b7 ');
    }

    return {
      ...data,
      'blocks': [
        for (final b in data['blocks'] as List)
          {
            ...Map<String, dynamic>.from(b as Map),
            'lines': [
              for (final l in b['lines'] as List)
                {
                  ...Map<String, dynamic>.from(l as Map),
                  if (l['subtitle'] is String)
                    'subtitle': word(l['subtitle'] as String),
                },
            ],
          },
      ],
    };
  }

  // ------------------------------------------------------------------- posts

  static const _storyId = 'SP-2026-00310';
  final _frames = <int, Map<String, dynamic>>{};

  /// A post by id: the contract's sample, with the id asked for. The story slot
  /// has four frames (photos and a clip) that [calendar.frame_set] decides one
  /// by one; the post is Published once every frame is decided and one was
  /// posted. The trial reel read for 72 hours is Published and has its read to
  /// file.
  Map<String, dynamic> _post(Map data, Map<String, dynamic> p) {
    final id = '${p['post_id']}';
    if (id == _storyId && storyFrames) return _storyPost();
    final post = <String, dynamic>{
      ...Map<String, dynamic>.from(data),
      'id': id,
    };
    if (id == 'SP-2026-00190') {
      final byPiece = _fixture('results.by_piece') as Map;
      final item = (byPiece['items'] as List).first as Map;
      post
        ..['status'] = 'Published'
        ..['posted_at'] = '2026-11-21T20:02:00+02:00'
        ..['permalink'] = 'https://social.example.test/reel/EXAMPLE190/'
        ..['actions'] = <String>[]
        ..['reads'] = item['reads'];
    }
    return _overlay(post) as Map<String, dynamic>;
  }

  /// The Today card of the story slot counts the same four frames as the slot
  /// page, and moves as frames are decided (the contract sample says three).
  dynamic _storyLine(Map line) {
    if (!storyFrames || line['id'] != _storyId) return line;
    final posted = _frames.values.where((f) => f['status'] == 'posted').length;
    final decided = _frames.values.where((f) => f['status'] != null).length;
    final left = 4 - decided;
    final ar = _lang == 'ar';
    return {
      ...Map<String, dynamic>.from(line),
      'subtitle': ar
          ? '4 فريمات · $posted اتنشر · $left فاضل'
          : '4 frames · $posted posted · $left to go',
      'badge': '$decided/4',
    };
  }

  Map<String, dynamic> _storyPost() {
    final base = Map<String, dynamic>.from(
      _fixture('calendar.frame_set') as Map,
    )..['id'] = _storyId;
    Map<String, dynamic> media(int n, bool video) => {
      'id': 'MED-0000003${n}0',
      'kind': video ? 'video' : 'image',
      'thumb_url': 'https://cdn.example.test/review/MED-0000003${n}0/thumb.jpg',
      'poster_url': video
          ? 'https://cdn.example.test/review/MED-0000003${n}0/poster.jpg'
          : null,
      'feed_url':
          'https://cdn.example.test/review/MED-0000003${n}0/feed.${video ? 'mp4' : 'jpg'}',
      'url':
          'https://cdn.example.test/review/MED-0000003${n}0/main.${video ? 'mp4' : 'jpg'}',
      'width': 1080,
      'height': 1920,
      'duration_s': video ? 9.0 : null,
    };
    const titles = [
      'Hands hold a jar and lift a spoon of dark crumb cake',
      'The lid goes on, label facing the camera (clip)',
      'Kitchen counter, jars lined up before delivery',
      'The courier closes the bag',
    ];
    final frames = [
      for (var i = 0; i < 4; i++)
        {
          'position': i + 1,
          'asset': {
            'id': 'AST-00003${i + 1}3',
            'title': titles[i],
            'kind': i == 1 ? 'Story clip' : 'Story photo',
            'media': media(i + 1, i == 1),
          },
          'status': _frames[i + 1]?['status'],
          'reason': _frames[i + 1]?['reason'],
          'set_by': _frames[i + 1]?['set_by'],
          'set_at': _frames[i + 1]?['set_at'],
          'comments_count': 0,
        },
    ];
    final decided = frames.every((f) => f['status'] != null);
    final anyPosted = frames.any((f) => f['status'] == 'posted');
    final published = decided && anyPosted;
    return {
      ...base,
      'frames': frames,
      'status': published ? 'Published' : base['status'],
      'posted_at': published ? _stamp() : null,
      'posted_by': published ? _meRef()['key'] : null,
      'posted_how': published ? 'hand' : null,
      'actions': published ? <String>[] : ['wont_post', 'frame_set'],
    };
  }

  // ------------------------------------------------------------------ shoots

  /// A shot as the contract's samples show it (`shoots.sync` holds all three
  /// shots of the shoot being filmed), by id.
  Map<String, dynamic>? _shotBase(String id) {
    for (final k in ['shoots.sync', 'shoots.get']) {
      final d = _fixture(k);
      final shoots = d is Map && d['items'] is List ? d['items'] as List : [d];
      for (final s in shoots) {
        for (final shot in ((s as Map)['shots'] as List? ?? const [])) {
          if ((shot as Map)['id'] == id) {
            return Map<String, dynamic>.from(shot);
          }
        }
      }
    }
    return null;
  }

  /// Shoots as the server counts them now: `n_done` follows the ticked shots
  /// and the shoot is Shot once every shot is filmed.
  dynamic _shootsNow(dynamic v) {
    if (v is List) return [for (final e in v) _shootsNow(e)];
    if (v is! Map) return v;
    final m = <String, dynamic>{
      for (final e in v.entries) e.key as String: _shootsNow(e.value),
    };
    if (m.containsKey('n_shots') && m.containsKey('n_done')) {
      final shots = m['shots'];
      var done = m['n_done'] as int;
      if (shots is List) {
        done = shots.where((s) => (s as Map)['done'] == true).length;
      } else {
        for (final e in _patches.entries) {
          final base = _shotBase(e.key);
          if (base == null || base['shoot_id'] != m['id']) continue;
          final was = base['done'] == true;
          final now = e.value['done'] == true;
          done += (now ? 1 : 0) - (was ? 1 : 0);
        }
      }
      m['n_done'] = done.clamp(0, m['n_shots'] as int);
      if (done >= (m['n_shots'] as int) && m['status'] == 'Prep') {
        m['status'] = 'Shot';
      }
    }
    return m;
  }

  // ---------------------------------------------------- calendar and rivals

  Map<String, dynamic>? _rangePost(String id) {
    final range = _fixture('calendar.range') as Map;
    for (final x in range['posts'] as List) {
      if ((x as Map)['id'] == id) return Map<String, dynamic>.from(x);
    }
    return null;
  }

  void _addChange(String kind, String postId, {String? reason, String? text}) {
    final post = _rangePost(postId);
    if (post == null) return;
    final at = _stamp();
    _changeRows.add({
      'id': '$postId:$kind:$at',
      'kind': kind,
      'post': post,
      'old_slot': null,
      'new_slot': null,
      'reason': reason,
      'by': _meRef(),
      'at': at,
      'text': text ?? '',
    });
  }

  /// What changed: the contract's sample, with its won't-post line about the
  /// post the sample marks Cancelled (so the list and this agree), then the
  /// changes made in this run, newest first.
  Map _changesNow(Map data) {
    final cancelled = _rangePost(_wontPostId);
    return {
      ...data,
      'items': [
        for (final row in _changeRows.reversed) row,
        for (final r in data['items'] as List)
          if ((r as Map)['kind'] == 'wont_post' && cancelled != null)
            {
              ...Map<String, dynamic>.from(r),
              'id': '$_wontPostId:wont_post:2026-11-24 18:02:00',
              'post': cancelled,
            }
          else
            r,
      ],
    };
  }

  Map<String, dynamic>? _competitorBase(String key) {
    final all = _fixture('references.competitors') as Map;
    for (final c in [
      ...(all['items'] as List),
      _fixture('references.competitor_get'),
    ]) {
      if ((c as Map)['key'] == key) return Map<String, dynamic>.from(c);
    }
    return null;
  }

  Map<String, dynamic> _withCompetitorPatch(Map c) => {
    ...Map<String, dynamic>.from(c),
    ...?_competitorPatches[c['key']],
  };

  /// The competitors list for `status` (Active by default, Removed, all).
  Map _competitorsNow(Map data, Map<String, dynamic> p) {
    final want = '${p['status'] ?? 'Active'}';
    final seen = <String>{};
    final items = data['items'] as List;
    final all = [
      for (final c in [
        ...items,
        // A competitor removed here that the page did not hold stays findable.
        for (final k in _competitorPatches.keys)
          if (!items.any((c) => (c as Map)['key'] == k)) _competitorBase(k),
      ])
        if (c != null && seen.add('${(c as Map)['key']}'))
          _withCompetitorPatch(c),
    ];
    return {
      ...data,
      'items': [
        for (final c in all)
          if (want == 'all' || c['status'] == want) c,
      ],
    };
  }

  Map _competitorNow(Map data, String key) {
    final c = key.isEmpty || data['key'] == key ? data : _competitorBase(key);
    return c == null ? data : _withCompetitorPatch(c);
  }

  // ------------------------------------------------------------------- tasks

  final _createdTasks = <Map<String, dynamic>>[];

  /// The task list as the server serves it to this role: my own tasks by
  /// default, everyone's with `assignee: all` (founder and lead only), the
  /// open ones unless `status` says otherwise. Done and skipped follow the
  /// ticks; a task made in the app is in the list.
  Map<String, dynamic> _tasks(Map data, Map<String, dynamic> p) {
    final me = _meRef()['key'];
    final all = p['assignee'] == 'all' && (role == 'founder' || role == 'lead');
    final status = '${p['status'] ?? 'open'}';
    final fixtureTasks = [
      for (final t in data['items'] as List)
        Map<String, dynamic>.from(t as Map),
      // A creator has no task in the contract's sample: one of their own.
      if (role == 'creator' && (data['items'] as List).isNotEmpty)
        {
          ...Map<String, dynamic>.from((data['items'] as List).first as Map),
          'id': 'TASK-000191',
          'text': 'Charge the camera and clear the card before the shoot',
          'assignee': {'key': me, 'full_name': 'Kareem'},
          'sort_order': 191.0,
        },
    ];
    final items = <Map<String, dynamic>>[];
    for (final raw in [..._createdTasks.reversed, ...fixtureTasks]) {
      final t = _overlay(raw) as Map<String, dynamic>;
      final mine = (t['assignee'] as Map?)?['key'] == me;
      if (!all && !mine) continue;
      final closed = t['done'] == true || t['skipped'] == true;
      if (status == 'open' && closed) continue;
      if (status == 'done' && !closed) continue;
      items.add({
        ...t,
        // Only the person's own task can be ticked or skipped; editing is
        // for the roles that may call today.task_update (cut by _forRole).
        'actions': [
          for (final a in (t['actions'] as List))
            if ((a != 'tick' && a != 'skip') || mine) a,
        ],
      });
    }
    return {...data, 'items': items};
  }

  Map<String, dynamic> _newTask(Map<String, dynamic> p) {
    final base = Map<String, dynamic>.from(
      (_fixture('today.tasks') as Map)['items'].first as Map,
    );
    final key = '${p['assignee'] ?? _meRef()['key']}';
    final n = (_createdTasks.length + 1).toString().padLeft(5, '0');
    return {
      ...base,
      'id': 'TASK-9$n',
      'kind': p['kind'] ?? 'todo',
      'text': '${p['text'] ?? ''}'.trim(),
      'assignee': {
        'key': key,
        'full_name': '${key[0].toUpperCase()}${key.substring(1)}',
      },
      'assignee_team': p['assignee_team'],
      'due': p['due'] ?? _stamp().substring(0, 10),
      'due_time': p['due_time'],
      'done': false,
      'skipped': false,
      'done_by': null,
      'done_at': null,
      'shoot_id': p['shoot_id'],
      'piece_id': p['piece_id'],
      'post_id': p['post_id'],
      'note': p['note'],
      'sort_order': 900.0 + _createdTasks.length,
      'modified': _stamp(),
    };
  }

  // ------------------------------------------------------------------ writes

  /// Today for another person (`as`, Founder and Lead only) or another day
  /// (`date`): the contract's `today.get.as` and `today.get.day` samples, with
  /// the person and the day asked for, and no action on any line.
  Map _todayFor(Map data, Map<String, dynamic> p) {
    final asKey = '${p['as'] ?? ''}';
    final date = '${p['date'] ?? ''}';
    if (asKey.isEmpty && (date.isEmpty || date == data['date'])) return data;
    if (asKey.isNotEmpty && role != 'founder' && role != 'lead') {
      throw const StudioNotPermitted('Only the founder and the lead.');
    }
    final sample =
        jsonDecode(
              _fixtures[asKey.isNotEmpty ? 'today.get.as' : 'today.get.day']!,
            )
            as Map<String, dynamic>;
    if (asKey.isNotEmpty) {
      final people = _fixture('settings.people');
      final name = [
        for (final x in people is List ? people : const [])
          if ((x as Map)['key'] == asKey) '${x['full_name']}',
      ].firstOrNull;
      if (name == null) {
        throw const StudioNotFound('No such person.', statusCode: 404);
      }
      sample['viewing_as'] = {'key': asKey, 'full_name': name};
    }
    if (date.isNotEmpty) sample['date'] = date;
    return sample;
  }

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
      case 'settings.set_my_notifications':
        if (p.containsKey('lang')) {
          final l = p['lang'];
          if (l != null && l != 'en' && l != 'ar') {
            throw const StudioValidation(
              'The language is en or ar.',
              field: 'lang',
              statusCode: 422,
            );
          }
          _lang = l as String?;
        }
        return null;
      case 'session.help_seen':
        final k = '${p['key'] ?? ''}'.trim();
        if (k.isEmpty) {
          throw const StudioValidation(
            'Say which help was seen.',
            field: 'key',
            statusCode: 422,
          );
        }
        _seenHelp.add(k);
        return {
          'seen_help': (_meSeen(
            _fixture('session.me') as Map<String, dynamic>,
          )['seen_help']),
        };
      case 'calendar.frame_set':
        final pos = (p['position'] as num?)?.toInt() ?? 0;
        final status = '${p['status'] ?? ''}';
        final reason = '${p['reason'] ?? ''}'.trim();
        if (!storyFrames || p['post_id'] != _storyId) return null;
        if (pos < 1 || pos > 4) {
          throw const StudioNotFound('No such frame.', statusCode: 404);
        }
        if (status != 'posted' && status != 'skipped') {
          throw const StudioValidation(
            'A frame is posted or skipped.',
            field: 'status',
            statusCode: 422,
          );
        }
        if (status == 'skipped' && reason.isEmpty) {
          throw const StudioValidation(
            'Say why the frame is skipped.',
            field: 'reason',
            statusCode: 422,
          );
        }
        _frames[pos] = {
          'status': status,
          'reason': status == 'skipped' ? reason : null,
          'set_by': _meRef(),
          'set_at': _stamp(),
        };
        final story = _storyPost();
        if (story['status'] == 'Published') {
          _patches[_storyId] = {'status': 'Published'};
        }
        return story;
      case 'calendar.post_mark_posted':
        final id = '${p['post_id']}';
        final base = _post(_fixture(key) as Map, {'post_id': id});
        _patches[id] = {
          ...?_patches[id],
          'status': 'Published',
          'posted_at': _stamp(),
          'posted_by': _meRef()['key'],
          'posted_how': 'hand',
          'permalink': p['link'],
          'actions': <String>[],
        };
        return _overlay(base);
      case 'calendar.post_wont_post':
        final id = '${p['post_id']}';
        final base = _post(_fixture(key) as Map, {'post_id': id});
        _patches[id] = {
          ...?_patches[id],
          'status': 'Cancelled',
          'skip_reason': p['reason'],
          'actions': ['reopen'],
          'modified': _stamp(),
        };
        _addChange(
          'wont_post',
          id,
          reason: '${p['reason'] ?? ''}',
          text: "Marked won't post: ${p['reason'] ?? ''}",
        );
        return _overlay(base);
      case 'calendar.post_set':
        // "Put back" sets the slot of a Cancelled post again, which reopens it.
        final id = '${p['post_id']}';
        if (_patches[id]?['status'] != 'Cancelled') return null;
        _patches[id] = {
          ...?_patches[id],
          'status': 'Scheduled',
          'skip_reason': null,
          'actions': ['edit', 'move', 'wont_post', 'mark_posted'],
          'modified': _stamp(),
        };
        _addChange('put_back', id, text: 'Put back on the calendar');
        return {
          ...Map<String, dynamic>.from(_fixture(key) as Map),
          'post': _overlay(
            _post(_fixture('calendar.post_get') as Map, {'post_id': id}),
          ),
        };
      case 'references.competitor_remove':
      case 'references.competitor_restore':
        final ck = '${p['key']}';
        final removing = key.endsWith('remove');
        final cur = _competitorBase(ck);
        if (cur == null) return null; // the contract's sample answer
        _competitorPatches[ck] = {
          'status': removing ? 'Removed' : 'Active',
          'removed_why': removing ? p['reason'] : null,
          'actions': [removing ? 'restore' : 'remove'],
          'modified': _stamp(),
        };
        return {...cur, ..._competitorPatches[ck]!};
      case 'calendar.post_retry':
        final id = '${p['post_id']}';
        final base = _post(_fixture(key) as Map, {'post_id': id});
        _patches[id] = {...?_patches[id], 'retried': true, 'waits_on': null};
        return _overlay(base);
      case 'shoots.shot_tick':
        final results = <Map<String, dynamic>>[];
        final shots = <Map<String, dynamic>>[];
        final ticks = p['ticks'];
        for (final t in ticks is List ? ticks : [if (ticks is Map) ticks]) {
          final tick = Map<String, dynamic>.from(t as Map);
          final id = '${tick['shot_id']}';
          final base = _shotBase(id);
          if (base == null) return null; // the contract's sample answer
          final done = tick['done'] != false;
          _patches[id] = {
            ...?_patches[id],
            'done': done,
            'done_by': done ? _meRef() : null,
            'done_at': done ? (tick['at'] ?? _stamp()) : null,
          };
          results.add({'shot_id': id, 'ok': true, 'error': null});
          shots.add(_overlay(base) as Map<String, dynamic>);
        }
        return {
          'results': results,
          'shots': shots,
          'pieces_moved': <dynamic>[],
        };
      case 'shoots.shot_note':
        final id = '${p['shot_id']}';
        final base = _shotBase(id);
        if (base == null) return null; // the contract's sample answer
        _patches[id] = {
          ...?_patches[id],
          'note': p['note'],
          'modified': _stamp(),
        };
        return _overlay(base);
      case 'today.task_create':
        final text = '${p['text'] ?? ''}'.trim();
        if (text.isEmpty) {
          throw const StudioValidation(
            'Write what needs doing.',
            field: 'text',
            statusCode: 422,
          );
        }
        final t = _newTask(p);
        _createdTasks.add(t);
        return _overlay(t);
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
    // The result names the piece of the version asked for, so its stage (moved
    // below) shows on the page the person is looking at.
    final owner = _pieceOfVersion(id);
    if (owner != null && base['piece'] is Map) {
      (base['piece'] as Map)['id'] = owner;
    }
    // The piece moves with its version, as the server moves it: an approved
    // version schedules its post (Scheduled), a fix sends the piece back (To
    // edit), a cleared review waits in review again.
    final stage = switch (key) {
      'versions.approve' => 'Scheduled',
      'versions.fix' => 'To edit',
      'versions.clear_review' => 'In review',
      _ => null,
    };
    if (stage != null) {
      final pieceId =
          _pieceOfVersion(id) ?? '${(base['piece'] as Map?)?['id']}';
      _patches[pieceId] = {...?_patches[pieceId], 'stage': stage};
    }
    return _overlay(base);
  }

  /// The piece a version belongs to (the to-approve sample names it).
  String? _pieceOfVersion(String versionId) {
    final feed = _fixture('inbox.to_approve');
    for (final c in (feed is Map ? feed['items'] as List? : null) ?? const []) {
      final v = (c as Map)['version'] as Map?;
      if (v?['id'] == versionId) return (c['piece'] as Map?)?['id'] as String?;
    }
    final i = versionId.lastIndexOf('-v');
    return i > 0 ? versionId.substring(0, i) : null;
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
  if (has('competitor_group') && has('references_count')) return 'competitor';
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
  'competitor': {
    'remove': 'references.competitor_remove',
    'restore': 'references.competitor_restore',
  },
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
    'reopen': 'calendar.post_set',
  },
  'ready_post': {
    'mark_posted': 'calendar.post_mark_posted',
    'wont_post': 'calendar.post_wont_post',
    'frame_set': 'calendar.frame_set',
  },
  'task': {'edit': 'today.task_update'},
  'shot': {'edit': 'shoots.shot_set', 'note': 'shoots.shot_note'},
  'shoot': {
    'edit': 'shoots.update',
    'share': 'shoots.share_link',
    'add_shot': 'shoots.shot_set',
  },
  'reference': {
    // Creators may move a reference along (shortlist, for a shoot) and add a
    // note, but "Creators cannot Drop" (references.update_status); the
    // `drop` rule is in `_forRole`.
    'shortlist': 'references.update_status',
    'send_to_shoot': 'references.update_status',
    'note': 'references.note',
    'link': 'references.link',
    'edit': 'references.update_status',
    'set_feasibility': 'references.set_feasibility',
  },
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
