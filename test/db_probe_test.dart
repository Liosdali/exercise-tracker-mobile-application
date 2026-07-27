import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exercise_app/data/database_helper.dart';

void main() {
  test('db opens and queries quickly', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final sw = Stopwatch()..start();
    final entries = await DatabaseHelper.instance.allEntries();
    print('allEntries took ${sw.elapsedMilliseconds}ms, count=${entries.length}');
  });
}
