import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Screens and services must take colour from the theme, never from the
/// Material palette constants. `lib/theme/` is exempt: it is where colour is
/// allowed to be literal.
void main() {
  test('no Colors.<name> constants outside lib/theme', () {
    final offenders = <String>[];
    final pattern = RegExp(
      r'Colors\.(red|green|orange|amber|deepOrange|deepPurple|grey|blue|yellow|pink|purple|teal|indigo|lime|cyan|brown)\b',
    );

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalised = entity.path.replaceAll(r'\', '/');
      if (normalised.startsWith('lib/theme/')) continue;
      if (normalised.startsWith('lib/l10n/')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) {
          offenders.add('$normalised:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'Hardcoded palette colours found:\n${offenders.join("\n")}');
  });
}
