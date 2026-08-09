import 'glyph_publisher_stub.dart'
    if (dart.library.io) 'glyph_publisher_io.dart'
    as platform;

Future<GlyphPublishResult> publishGlyphSet(GlyphPublishInput input) =>
    platform.publishGlyphSet(input);

class GlyphPublishResult {
  final bool persisted;
  final String message;

  const GlyphPublishResult({required this.persisted, required this.message});
}

class GlyphPublishInput {
  final String specJson;
  final Map<String, String> svgs;
  final bool publishAssets;
  const GlyphPublishInput({
    required this.specJson,
    required this.svgs,
    this.publishAssets = true,
  });
}
