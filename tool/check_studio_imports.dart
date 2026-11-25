// Fails when the Studio and the POS app reach into each other.
//
//   dart run tool/check_studio_imports.dart
//
// Rules:
//  1. Files under lib/src/studio/ (and lib/main_studio.dart) may import only
//     the Studio itself, packages, dart: libraries, and these POS paths:
//     lib/src/core/{network,session,env,constants,localization,monitoring,
//     offline}/ and lib/src/features/auth/data/auth_repository.dart.
//  2. No other file under lib/ may import lib/src/studio/ or main_studio.dart.
import 'dart:io';

const _allowedPosPrefixes = [
  'lib/src/core/network/',
  'lib/src/core/session/',
  'lib/src/core/env/',
  'lib/src/core/constants/',
  'lib/src/core/localization/',
  'lib/src/core/monitoring/',
  'lib/src/core/offline/',
  'lib/src/features/auth/data/auth_repository.dart',
];

final _directive = RegExp(
  r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Resolves an import to a repo-relative path with forward slashes, or null
/// for dart: and third-party packages.
String? _resolve(String fromFile, String uri) {
  if (uri.startsWith('dart:')) return null;
  if (uri.startsWith('package:')) {
    const own = 'package:jarz_pos/';
    return uri.startsWith(own) ? 'lib/${uri.substring(own.length)}' : null;
  }
  final base = fromFile.split('/')..removeLast();
  for (final part in uri.split('/')) {
    if (part == '..') {
      if (base.isNotEmpty) base.removeLast();
    } else if (part != '.' && part.isNotEmpty) {
      base.add(part);
    }
  }
  return base.join('/');
}

bool _isStudio(String path) =>
    path.startsWith('lib/src/studio/') || path == 'lib/main_studio.dart';

void main() {
  final violations = <String>[];
  var scanned = 0;

  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final file = entity.path.replaceAll('\\', '/');
    scanned++;
    final studioFile = _isStudio(file);
    final text = entity.readAsStringSync();

    for (final m in _directive.allMatches(text)) {
      final target = _resolve(file, m.group(1)!);
      if (target == null) continue;
      if (studioFile) {
        if (_isStudio(target)) continue;
        final ok = _allowedPosPrefixes.any(target.startsWith);
        if (!ok) {
          violations.add('$file imports $target (not on the allow list)');
        }
      } else if (_isStudio(target)) {
        violations.add('$file (POS) imports $target');
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('Studio import check: OK ($scanned files scanned)');
    return;
  }
  stderr.writeln('Studio import check: ${violations.length} violation(s)');
  for (final v in violations) {
    stderr.writeln('  $v');
  }
  exit(1);
}
