import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Screens and services must take colour from the theme, never from the
/// Material palette constants or a raw ARGB literal. `lib/theme/` is exempt:
/// it is where colour is allowed to be literal. `lib/l10n/` is exempt too —
/// generated localisation code, not app UI.
///
/// This is deliberately deny-by-default rather than an allowlist of known
/// offenders: an allowlist only ever catches names someone has already seen
/// go wrong. `Colors.transparent` is the one name let through, since it
/// carries no hue and cannot fail a contrast check.
void main() {
  final colorsPattern = RegExp(r'Colors\.(?!transparent\b)[A-Za-z0-9_]+');
  final argbLiteralPattern = RegExp(r'Color\(0x');

  Iterable<File> dartFilesOutsideExemptions() sync* {
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalised = entity.path.replaceAll(r'\', '/');
      if (normalised.startsWith('lib/theme/')) continue;
      if (normalised.startsWith('lib/l10n/')) continue;
      yield entity;
    }
  }

  test('no Colors.<name> constants outside lib/theme', () {
    final offenders = <String>[];

    for (final entity in dartFilesOutsideExemptions()) {
      final normalised = entity.path.replaceAll(r'\', '/');
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (colorsPattern.hasMatch(lines[i])) {
          offenders.add('$normalised:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'Hardcoded palette colours found:\n${offenders.join("\n")}');
  });

  test('no Color(0x...) literals outside lib/theme', () {
    final offenders = <String>[];

    for (final entity in dartFilesOutsideExemptions()) {
      final normalised = entity.path.replaceAll(r'\', '/');
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (argbLiteralPattern.hasMatch(lines[i])) {
          offenders.add('$normalised:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'Raw Color(0x...) literals found:\n${offenders.join("\n")}');
  });
}
