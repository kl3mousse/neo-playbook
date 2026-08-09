import 'package:combofox/experimental/gold_moves_profile_v1/presentation/gold_rendering_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Gold display options have stable storage values and safe defaults', () {
    expect(GoldNotation.pictograms.storageValue, 'pictograms');
    expect(GoldNotation.motionGlyphs.storageValue, 'motion_glyphs');
    expect(GoldNotation.classic2d.storageValue, 'classic2d');
    expect(GoldNotationStorage.parse('numpad'), GoldNotation.numpad);
    expect(
      GoldNotationStorage.parse('motion_glyphs'),
      GoldNotation.motionGlyphs,
    );
    expect(GoldNotationStorage.parse('unsupported'), GoldNotation.pictograms);

    expect(GoldDensity.compact.storageValue, 'compact');
    expect(GoldDensityStorage.parse('comfortable'), GoldDensity.comfortable);
    expect(GoldDensityStorage.parse(null), GoldDensity.compact);
  });
}
