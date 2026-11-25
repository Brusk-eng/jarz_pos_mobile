import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'data/generated/fixture_codecs.g.dart';

/// Parses what the staging server really answered with the generated model of
/// that endpoint's result.
///
/// The folder `C:\ERPNext\.scratch\studio\real_payloads\` (outside the repo,
/// PRIVATE: its files are never copied here and never printed) holds one
/// `.json` file per answer, named `<group>.<fn>[-n].json` (`today.get.json`,
/// `pieces.get-2.json`). The file may hold the answer itself or Frappe's
/// `{"message": ...}` wrapper. Without the folder the test is skipped.
///
/// A failure names the file and the path of the field that does not fit
/// (`items[2].version.files[0].media.duration_s`) and the kind of error, and
/// never shows a value.
const _folder = r'C:\ERPNext\.scratch\studio\real_payloads';

String _endpointOf(String file) {
  final base = file.split(RegExp(r'[\\/]')).last;
  final name = base.endsWith('.json')
      ? base.substring(0, base.length - 5)
      : base;
  return name.replaceFirst(RegExp(r'-\d+$'), '');
}

/// Every path of [v] that can be taken out (a map key or a list item).
Iterable<List<Object>> _paths(Object? v, [List<Object> at = const []]) sync* {
  if (v is Map) {
    for (final k in v.keys) {
      yield [...at, k as String];
      yield* _paths(v[k], [...at, k]);
    }
  } else if (v is List) {
    for (var i = 0; i < v.length; i++) {
      yield [...at, i];
      yield* _paths(v[i], [...at, i]);
    }
  }
}

Object? _without(Object? v, List<Object> path) {
  if (path.isEmpty) return v;
  final head = path.first;
  if (v is Map) {
    return {
      for (final e in v.entries)
        if (e.key != head || path.length > 1)
          e.key: e.key == head ? _without(e.value, path.sublist(1)) : e.value,
    };
  }
  if (v is List) {
    return [
      for (var i = 0; i < v.length; i++)
        if (i != head || path.length > 1)
          i == head ? _without(v[i], path.sublist(1)) : v[i],
    ];
  }
  return v;
}

String _show(List<Object> path) {
  final b = StringBuffer();
  for (final p in path) {
    if (p is int) {
      b.write('[$p]');
    } else {
      b.write(b.isEmpty ? p : '.$p');
    }
  }
  return b.toString();
}

/// The field that makes [parse] fail: of the paths whose removal lets the rest
/// parse, the deepest one. Values are never read out.
String _culprit(Object? Function(Object?) parse, Object? json) {
  var tried = 0;
  List<Object>? best;
  for (final p in _paths(json)) {
    if (++tried > 6000) break;
    try {
      parse(_without(json, p));
      if (best == null || p.length > best.length) best = p;
    } catch (_) {}
  }
  return best == null ? '(not found: the shape as a whole)' : _show(best);
}

void main() {
  // STUDIO_REAL_PAYLOADS points the test at another folder (for trying it).
  final folder = Platform.environment['STUDIO_REAL_PAYLOADS'] ?? _folder;
  final dir = Directory(folder);
  final present =
      dir.existsSync() &&
      dir.listSync().whereType<File>().any((f) => f.path.endsWith('.json'));

  test(
    'every real staging answer parses with the generated model',
    () {
      final failures = <String>[];
      final files =
          dir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.json'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      for (final f in files) {
        final name = f.path.split(RegExp(r'[\\/]')).last;
        final key = _endpointOf(f.path);
        // `compat.*` are answers of the old (pre-contract) endpoints the app
        // does not read.
        if (key.startsWith('compat.')) continue;
        final codec = fixtureCodecs[key];
        if (codec == null) {
          failures.add('$name: no model for the endpoint "$key"');
          continue;
        }
        Object? json;
        try {
          json = jsonDecode(f.readAsStringSync());
        } catch (_) {
          failures.add('$name: not valid JSON');
          continue;
        }
        if (json is Map && json.length == 1 && json.containsKey('message')) {
          json = json['message'];
        }
        try {
          codec.parse(json);
        } catch (e) {
          final where = _culprit(codec.parse, json);
          // A TypeError's text names types, not values; anything else is
          // reduced to its type.
          final what = e is TypeError
              ? '$e'.split('\n').first
              : '${e.runtimeType}';
          failures.add('$name: field $where: $what');
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    },
    skip: present
        ? false
        : 'no real payloads yet ($folder is missing or has no .json files)',
  );
}
