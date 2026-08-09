import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:combofox/experimental/gold_moves_profile_v1/domain/expression.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/presentation/gold_glyph_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('nested glyph directories are included in the Flutter asset bundle', () async {
    for (final path in const [
      'assets/glyphs/directions/dir_f.svg',
      'assets/glyphs/motions/motion_qcf.svg',
      'assets/glyphs/buttons/btn_a.svg',
      'assets/glyphs/operators/op_plus.svg',
    ]) {
      final asset = await rootBundle.load(path);
      expect(asset.lengthInBytes, greaterThan(0), reason: path);
    }
  });

  test('every domain motion maps to a published SVG asset', () {
    for (final shape in MotionShape.values) {
      final path = GoldGlyphAssets.motion(shape);
      expect(File(path).existsSync(), isTrue, reason: '${shape.wire}: $path');
    }
  });

  test('directions map except neutral and any', () {
    for (final direction in GoldDirection.values) {
      final path = GoldGlyphAssets.direction(direction);
      if (direction == GoldDirection.neutral ||
          direction == GoldDirection.any) {
        expect(path, isNull);
      } else {
        expect(File(path!).existsSync(), isTrue);
      }
    }
  });

  test('known buttons and operators map to published assets', () {
    for (final symbol in const [
      'A',
      'B',
      'C',
      'D',
      'P',
      'K',
      'LP',
      'MP',
      'HP',
      'LK',
      'MK',
      'HK',
      '2P',
      '2K',
      '3P',
      '3K',
    ]) {
      expect(File(GoldGlyphAssets.button(symbol)!).existsSync(), isTrue);
    }
    expect(GoldGlyphAssets.button('Z'), isNull);
    for (final operator in GoldGlyphOperator.values) {
      expect(File(GoldGlyphAssets.operator(operator)).existsSync(), isTrue);
    }
  });

  test('facing-left swaps relative directions and motion pairs', () {
    expect(
      GoldGlyphAssets.direction(
        GoldDirection.forward,
        mirrorForFacingLeft: true,
      ),
      endsWith('/dir_b.svg'),
    );
    expect(
      GoldGlyphAssets.motion(
        MotionShape.pretzelForward,
        mirrorForFacingLeft: true,
      ),
      endsWith('/motion_pretzel_b.svg'),
    );
    expect(
      GoldGlyphAssets.motion(MotionShape.fullCircle, mirrorForFacingLeft: true),
      endsWith('/motion_360.svg'),
    );
  });

  test('arrow expansion covers every motion and mirrors each direction', () {
    for (final shape in MotionShape.values) {
      final normal = GoldGlyphAssets.motionDirections(shape);
      final mirrored = GoldGlyphAssets.motionDirections(
        shape,
        mirrorForFacingLeft: true,
      );
      expect(normal, isNotEmpty);
      expect(mirrored, normal.map(GoldGlyphAssets.mirrorDirection).toList());
    }
  });
}
