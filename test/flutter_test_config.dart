import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _load(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(
      File(path).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
  }
  await loader.load();
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _load('Archivo', <String>[
    'assets/fonts/Archivo-Regular.ttf',
    'assets/fonts/Archivo-Medium.ttf',
    'assets/fonts/Archivo-SemiBold.ttf',
  ]);
  await _load('ArchivoExpanded', <String>[
    'assets/fonts/Archivo_Expanded-SemiBold.ttf',
    'assets/fonts/Archivo_Expanded-Bold.ttf',
  ]);

  // Load MaterialIcons from Flutter SDK if available
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final materialIconsPath = '$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf';
    final materialIconsFile = File(materialIconsPath);
    if (materialIconsFile.existsSync()) {
      await _load('MaterialIcons', <String>[materialIconsPath]);
    }
  }

  return testMain();
}
