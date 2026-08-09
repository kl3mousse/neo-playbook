import 'dart:io';
import 'dart:convert';

import 'package:combofox/experimental/glyph_studio/glyph_studio.dart';

void main() {
  final root = Directory.current;
  final specFile = File('${root.path}/tool/glyph_studio/glyph_spec.json');
  final spec = specFile.existsSync()
      ? GlyphSpec.fromJson(_readJson(specFile))
      : GlyphSpec.defaults;
  final generated = SvgGlyphGenerator(spec).generateAll();
  final errors = GeneratedGlyphSet(generated).validate();
  if (errors.isNotEmpty) {
    stderr.writeln(errors.join('\n'));
    exitCode = 1;
    return;
  }
  for (final definition in GlyphRegistry.definitions) {
    final file = File(
      '${root.path}/assets/glyphs/${definition.category.name}/${definition.filename}',
    )..createSync(recursive: true);
    file.writeAsStringSync(generated[definition.id]!);
    stdout.writeln(file.path);
  }
}

Map<String, dynamic> _readJson(File file) => Map<String, dynamic>.from(
  const JsonDecoder().convert(file.readAsStringSync()) as Map,
);
