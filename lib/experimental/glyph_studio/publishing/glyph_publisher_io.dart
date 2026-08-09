import 'dart:io';

import '../domain/glyph_registry.dart';
import 'glyph_publisher.dart';

Future<GlyphPublishResult> publishGlyphSet(GlyphPublishInput input) async {
  final root = Directory.current;
  final changed = <String>[];
  final specFile = File('${root.path}/tool/glyph_studio/glyph_spec.json')
    ..createSync(recursive: true);
  if (specFile.readAsStringSync() != input.specJson) {
    specFile.writeAsStringSync(input.specJson);
    changed.add('tool/glyph_studio/glyph_spec.json');
  }
  if (!input.publishAssets) {
    return GlyphPublishResult(
      persisted: true,
      message: changed.isEmpty
          ? 'Design spec is already saved.'
          : changed.join('\n'),
    );
  }
  for (final definition in GlyphRegistry.definitions) {
    final relative =
        'assets/glyphs/${definition.category.name}/${definition.filename}';
    final file = File('${root.path}/$relative')..createSync(recursive: true);
    final svg = input.svgs[definition.id];
    if (svg == null) {
      throw StateError('Missing generated SVG: ${definition.id}');
    }
    if (file.readAsStringSync() != svg) {
      file.writeAsStringSync(svg);
      changed.add(relative);
    }
  }
  return GlyphPublishResult(
    persisted: true,
    message: changed.isEmpty
        ? 'No changes; generated set is already published.'
        : changed.join('\n'),
  );
}
