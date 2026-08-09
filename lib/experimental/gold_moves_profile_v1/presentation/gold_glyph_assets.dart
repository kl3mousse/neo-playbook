import '../domain/expression.dart';

enum GoldVisualNotation { arrowIcons, motionGlyphs }

enum GoldGlyphOperator { plus, then, hold, release }

class GoldGlyphAssets {
  GoldGlyphAssets._();

  static const _root = 'assets/glyphs';

  static String? direction(
    GoldDirection direction, {
    bool mirrorForFacingLeft = false,
  }) {
    final display = mirrorForFacingLeft
        ? mirrorDirection(direction)
        : direction;
    final id = switch (display) {
      GoldDirection.up => 'dir_u',
      GoldDirection.upBack => 'dir_ub',
      GoldDirection.back => 'dir_b',
      GoldDirection.downBack => 'dir_db',
      GoldDirection.down => 'dir_d',
      GoldDirection.downForward => 'dir_df',
      GoldDirection.forward => 'dir_f',
      GoldDirection.upForward => 'dir_uf',
      GoldDirection.neutral || GoldDirection.any => null,
    };
    return id == null ? null : '$_root/directions/$id.svg';
  }

  static String motion(MotionShape shape, {bool mirrorForFacingLeft = false}) {
    final display = mirrorForFacingLeft ? mirrorMotion(shape) : shape;
    final id = switch (display) {
      MotionShape.quarterCircleForward => 'motion_qcf',
      MotionShape.quarterCircleBack => 'motion_qcb',
      MotionShape.halfCircleForward => 'motion_hcf',
      MotionShape.halfCircleBack => 'motion_hcb',
      MotionShape.dragonPunchForward => 'motion_dpf',
      MotionShape.dragonPunchBack => 'motion_dpb',
      MotionShape.reverseDragonPunchForward => 'motion_rdpf',
      MotionShape.reverseDragonPunchBack => 'motion_rdpb',
      MotionShape.fullCircle => 'motion_360',
      MotionShape.doubleQuarterCircleForward => 'motion_dqcf',
      MotionShape.doubleQuarterCircleBack => 'motion_dqcb',
      MotionShape.pretzelForward => 'motion_pretzel_f',
      MotionShape.pretzelBack => 'motion_pretzel_b',
    };
    return '$_root/motions/$id.svg';
  }

  static String? button(String symbol) {
    final normalized = symbol.toLowerCase();
    const supported = {
      'a',
      'b',
      'c',
      'd',
      'p',
      'k',
      'lp',
      'mp',
      'hp',
      'lk',
      'mk',
      'hk',
      '2p',
      '2k',
      '3p',
      '3k',
    };
    return supported.contains(normalized)
        ? '$_root/buttons/btn_$normalized.svg'
        : null;
  }

  static String operator(GoldGlyphOperator value) {
    final id = switch (value) {
      GoldGlyphOperator.plus => 'op_plus',
      GoldGlyphOperator.then => 'op_then',
      GoldGlyphOperator.hold => 'op_hold',
      GoldGlyphOperator.release => 'op_release',
    };
    return '$_root/operators/$id.svg';
  }

  static List<GoldDirection> motionDirections(
    MotionShape shape, {
    bool mirrorForFacingLeft = false,
  }) {
    final directions = switch (shape) {
      MotionShape.quarterCircleForward => const [
        GoldDirection.down,
        GoldDirection.downForward,
        GoldDirection.forward,
      ],
      MotionShape.quarterCircleBack => const [
        GoldDirection.down,
        GoldDirection.downBack,
        GoldDirection.back,
      ],
      MotionShape.halfCircleForward => const [
        GoldDirection.back,
        GoldDirection.downBack,
        GoldDirection.down,
        GoldDirection.downForward,
        GoldDirection.forward,
      ],
      MotionShape.halfCircleBack => const [
        GoldDirection.forward,
        GoldDirection.downForward,
        GoldDirection.down,
        GoldDirection.downBack,
        GoldDirection.back,
      ],
      MotionShape.dragonPunchForward => const [
        GoldDirection.forward,
        GoldDirection.down,
        GoldDirection.downForward,
      ],
      MotionShape.dragonPunchBack => const [
        GoldDirection.back,
        GoldDirection.down,
        GoldDirection.downBack,
      ],
      MotionShape.reverseDragonPunchForward => const [
        GoldDirection.forward,
        GoldDirection.downForward,
        GoldDirection.down,
      ],
      MotionShape.reverseDragonPunchBack => const [
        GoldDirection.back,
        GoldDirection.downBack,
        GoldDirection.down,
      ],
      MotionShape.fullCircle => const [
        GoldDirection.forward,
        GoldDirection.downForward,
        GoldDirection.down,
        GoldDirection.downBack,
        GoldDirection.back,
        GoldDirection.upBack,
        GoldDirection.up,
        GoldDirection.upForward,
      ],
      MotionShape.doubleQuarterCircleForward => const [
        GoldDirection.down,
        GoldDirection.downForward,
        GoldDirection.forward,
        GoldDirection.down,
        GoldDirection.downForward,
        GoldDirection.forward,
      ],
      MotionShape.doubleQuarterCircleBack => const [
        GoldDirection.down,
        GoldDirection.downBack,
        GoldDirection.back,
        GoldDirection.down,
        GoldDirection.downBack,
        GoldDirection.back,
      ],
      MotionShape.pretzelForward => const [
        GoldDirection.downBack,
        GoldDirection.forward,
        GoldDirection.downForward,
        GoldDirection.down,
        GoldDirection.downBack,
        GoldDirection.back,
        GoldDirection.downForward,
      ],
      MotionShape.pretzelBack => const [
        GoldDirection.downForward,
        GoldDirection.back,
        GoldDirection.downBack,
        GoldDirection.down,
        GoldDirection.downForward,
        GoldDirection.forward,
        GoldDirection.upBack,
      ],
    };
    return mirrorForFacingLeft
        ? directions.map(mirrorDirection).toList(growable: false)
        : directions;
  }

  static GoldDirection mirrorDirection(GoldDirection direction) =>
      switch (direction) {
        GoldDirection.forward => GoldDirection.back,
        GoldDirection.back => GoldDirection.forward,
        GoldDirection.upForward => GoldDirection.upBack,
        GoldDirection.upBack => GoldDirection.upForward,
        GoldDirection.downForward => GoldDirection.downBack,
        GoldDirection.downBack => GoldDirection.downForward,
        _ => direction,
      };

  static MotionShape mirrorMotion(MotionShape shape) => switch (shape) {
    MotionShape.quarterCircleForward => MotionShape.quarterCircleBack,
    MotionShape.quarterCircleBack => MotionShape.quarterCircleForward,
    MotionShape.halfCircleForward => MotionShape.halfCircleBack,
    MotionShape.halfCircleBack => MotionShape.halfCircleForward,
    MotionShape.dragonPunchForward => MotionShape.dragonPunchBack,
    MotionShape.dragonPunchBack => MotionShape.dragonPunchForward,
    MotionShape.reverseDragonPunchForward => MotionShape.reverseDragonPunchBack,
    MotionShape.reverseDragonPunchBack => MotionShape.reverseDragonPunchForward,
    MotionShape.doubleQuarterCircleForward =>
      MotionShape.doubleQuarterCircleBack,
    MotionShape.doubleQuarterCircleBack =>
      MotionShape.doubleQuarterCircleForward,
    MotionShape.pretzelForward => MotionShape.pretzelBack,
    MotionShape.pretzelBack => MotionShape.pretzelForward,
    MotionShape.fullCircle => MotionShape.fullCircle,
  };
}
