/// Presentation choices shared by the production list and the validation UI.
enum GoldNotation { pictograms, motionGlyphs, numpad, classic2d, accessible }

extension GoldNotationStorage on GoldNotation {
  String get storageValue => switch (this) {
    GoldNotation.pictograms => 'pictograms',
    GoldNotation.motionGlyphs => 'motion_glyphs',
    GoldNotation.numpad => 'numpad',
    GoldNotation.classic2d => 'classic2d',
    GoldNotation.accessible => 'accessible',
  };

  static GoldNotation parse(String? value) => switch (value) {
    'numpad' => GoldNotation.numpad,
    'motion_glyphs' => GoldNotation.motionGlyphs,
    'classic2d' => GoldNotation.classic2d,
    'accessible' => GoldNotation.accessible,
    _ => GoldNotation.pictograms,
  };
}

enum GoldAccessibleLocale { en, fr }

enum GoldDensity { comfortable, compact }

extension GoldDensityStorage on GoldDensity {
  String get storageValue => switch (this) {
    GoldDensity.comfortable => 'comfortable',
    GoldDensity.compact => 'compact',
  };

  static GoldDensity parse(String? value) => switch (value) {
    'comfortable' => GoldDensity.comfortable,
    _ => GoldDensity.compact,
  };
}
