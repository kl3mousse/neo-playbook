import 'glyph_publisher.dart';

Future<GlyphPublishResult> publishGlyphSet(GlyphPublishInput input) async =>
    const GlyphPublishResult(
      persisted: false,
      message:
          'Chrome cannot write into the repository. Run Glyph Studio on '
          'macOS to save these parameters, then run: '
          'dart run tool/glyph_studio/generate.dart',
    );
