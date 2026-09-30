import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Returns the set of Unicode code points a TrueType font maps to a real
/// glyph, reading the format 4 and format 12 `cmap` subtables.
Set<int> _coveredCodePoints(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final numTables = data.getUint16(4);

  int? cmapOffset;
  for (var i = 0; i < numTables; i++) {
    final record = 12 + i * 16;
    final tag = String.fromCharCodes(bytes.sublist(record, record + 4));
    if (tag == 'cmap') {
      cmapOffset = data.getUint32(record + 8);
      break;
    }
  }
  if (cmapOffset == null) return <int>{};

  final numSubtables = data.getUint16(cmapOffset + 2);
  final covered = <int>{};

  for (var i = 0; i < numSubtables; i++) {
    final record = cmapOffset + 4 + i * 8;
    final platformId = data.getUint16(record);
    final encodingId = data.getUint16(record + 2);
    final isUnicode = platformId == 0 ||
        (platformId == 3 && (encodingId == 1 || encodingId == 10));
    if (!isUnicode) continue;

    final subtable = cmapOffset + data.getUint32(record + 4);
    final format = data.getUint16(subtable);

    if (format == 4) {
      final segCount = data.getUint16(subtable + 6) ~/ 2;
      final endCodes = subtable + 14;
      final startCodes = endCodes + segCount * 2 + 2;
      final idDeltas = startCodes + segCount * 2;
      final idRangeOffsets = idDeltas + segCount * 2;

      for (var s = 0; s < segCount; s++) {
        final end = data.getUint16(endCodes + s * 2);
        final start = data.getUint16(startCodes + s * 2);
        if (start > end || start == 0xFFFF) continue;
        final delta = data.getInt16(idDeltas + s * 2);
        final rangeOffset = data.getUint16(idRangeOffsets + s * 2);

        for (var c = start; c <= end; c++) {
          int glyph;
          if (rangeOffset == 0) {
            glyph = (c + delta) & 0xFFFF;
          } else {
            final glyphIndexAddress =
                idRangeOffsets + s * 2 + rangeOffset + (c - start) * 2;
            if (glyphIndexAddress + 1 >= bytes.length) continue;
            glyph = data.getUint16(glyphIndexAddress);
            if (glyph != 0) glyph = (glyph + delta) & 0xFFFF;
          }
          if (glyph != 0) covered.add(c);
        }
      }
    } else if (format == 12) {
      final numGroups = data.getUint32(subtable + 12);
      for (var g = 0; g < numGroups; g++) {
        final group = subtable + 16 + g * 12;
        final start = data.getUint32(group);
        final end = data.getUint32(group + 4);
        final startGlyph = data.getUint32(group + 8);
        for (var c = start; c <= end; c++) {
          final glyph = startGlyph + (c - start);
          if (glyph != 0) covered.add(c);
        }
      }
    }
  }
  return covered;
}

void main() {
  // The Turkish set, including the dotted/dotless I pair that cheap fonts
  // omit. Section 3 of the spec commits to these.
  const turkish = 'ğĞşŞİıçÇöÖüÜ';

  const fonts = <String>[
    'assets/fonts/Archivo-Regular.ttf',
    'assets/fonts/Archivo-Medium.ttf',
    'assets/fonts/Archivo-SemiBold.ttf',
    'assets/fonts/Archivo_Expanded-SemiBold.ttf',
    'assets/fonts/Archivo_Expanded-Bold.ttf',
  ];

  for (final path in fonts) {
    test('$path covers the Turkish glyph set', () {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path is missing');
      final covered = _coveredCodePoints(file.readAsBytesSync());
      expect(covered, isNotEmpty, reason: '$path has no readable cmap');

      final missing = <String>[];
      for (final rune in turkish.runes) {
        if (!covered.contains(rune)) {
          missing.add(String.fromCharCode(rune));
        }
      }
      expect(missing, isEmpty,
          reason: '$path is missing ${missing.join(", ")}');
    });
  }
}
