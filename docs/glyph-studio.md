# Glyph Studio

Glyph Studio is the internal developer tool for ComboFox motion-notation glyphs. The generator is the source of truth; SVGs under `assets/glyphs/` are committed build artifacts.

## Workflow

1. Run `flutter run -d macos` and open `/debug/glyph-studio`.
2. Adjust the live parameters and inspect the gallery at 16, 20, 24, 32, 48, and 64 px on light and dark surfaces.
3. Use **Save spec** only when the design is ready to persist. Use **Publish set** to validate and write the complete inventory.
4. Run the generator and tests before committing.

Use Chrome for previews only. Its browser sandbox cannot write the spec or
SVGs into the repository, and the studio reports that limitation instead of
marking the in-memory parameters as saved.

The persisted design lives at `tool/glyph_studio/glyph_spec.json`. The reproducible publisher is:

```sh
dart run tool/glyph_studio/generate.dart
flutter test test/experimental/glyph_studio/svg_glyph_generator_test.dart
```

The command creates only `assets/glyphs/directions/`, `motions/`, `buttons/`, and `operators/`. Output is deterministic: no timestamps, IDs, metadata, fonts, raster images, or external references are emitted.

## Naming and extension

The typed registry in `lib/experimental/glyph_studio/domain/glyph_registry.dart` is the canonical id-to-category-to-filename mapping. To add a motion, add a registry definition, implement its shared geometry in `SvgGlyphGenerator`, add a focused geometry assertion, preview it, and regenerate the assets.

Geometry uses Player 1 facing right and explicit SVG screen-space directions:
up `(0, -1)`, forward `(1, 0)`, down `(0, 1)`, and back `(-1, 0)`, with
normalized diagonal combinations. Motion paths, endpoint tangents, arrowheads,
and hold positions derive from this semantic direction model. Backward motion
pairs are horizontal mirrors of their forward definitions. A shared neutral
point anchors each motion to the joystick center so quarter-circle orientation
remains readable at compact sizes.

Buttons deliberately publish a generic circular shell. Their labels are rendered by Flutter in the studio and can later be rendered as regular move-list text, avoiding SVG font dependencies while preserving ids such as `btn_a`, `btn_lp`, and `btn_3k`.

The module is debug-only and does not migrate the production move-list renderer. The next integration step is to map Gold `RtMotion` and `RtButton` tokens to this registry and use `SvgPicture.asset` for published SVGs, while retaining accessible text fallbacks.