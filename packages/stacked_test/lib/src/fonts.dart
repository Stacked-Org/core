import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';

Future<void>? _loading;

/// Loads Roboto, MaterialIcons and the app's own fonts so that text measures
/// like it does on a device. Memoized. Call inside `tester.runAsync`.
Future<void> loadStackedFonts() => _loading ??= _load();

String? _flutterRoot() {
  final fromEnv = Platform.environment['FLUTTER_ROOT'];
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
  final executable = Platform.resolvedExecutable;
  final index = executable.indexOf('/bin/cache/');
  if (index > 0) return executable.substring(0, index);
  return null;
}

Future<ByteData> _fileBytes(File file) async {
  final bytes = await file.readAsBytes();
  return ByteData.sublistView(bytes);
}

Future<void> _loadSdkFonts() async {
  final root = _flutterRoot();
  if (root == null) return;
  final fonts = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!fonts.existsSync()) return;

  final roboto = FontLoader('Roboto');
  var hasRoboto = false;
  final files = fonts.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final name = file.uri.pathSegments.last;
    if (name.startsWith('Roboto-') && name.endsWith('.ttf')) {
      roboto.addFont(_fileBytes(file));
      hasRoboto = true;
    }
  }
  if (hasRoboto) await roboto.load();

  final icons = File('${fonts.path}/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')..addFont(_fileBytes(icons));
    await loader.load();
  }
}

Future<void> _loadAppFonts() async {
  try {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json'));
    if (manifest is! List) return;
    for (final entry in manifest) {
      if (entry is! Map) continue;
      final family = entry['family'];
      final fonts = entry['fonts'];
      if (family is! String || fonts is! List) continue;
      final loader = FontLoader(family);
      for (final font in fonts) {
        if (font is Map && font['asset'] is String) {
          loader.addFont(rootBundle.load(font['asset'] as String));
        }
      }
      await loader.load();
    }
  } catch (_) {
    // No manifest or an unreadable font: the SDK fonts are still loaded.
  }
}

Future<void> _load() async {
  await _loadSdkFonts();
  await _loadAppFonts();
}
