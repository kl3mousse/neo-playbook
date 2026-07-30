import 'package:meta/meta.dart';

/// Cardinal / diagonal directions declared by the Gold contract.
///
/// Wire values match schema.json §expr_direction.
enum GoldDirection {
  neutral('neutral'),
  forward('forward'),
  back('back'),
  up('up'),
  down('down'),
  upForward('up_forward'),
  upBack('up_back'),
  downForward('down_forward'),
  downBack('down_back'),
  any('any');

  final String wire;
  const GoldDirection(this.wire);

  static GoldDirection? fromWire(String? value) {
    for (final d in GoldDirection.values) {
      if (d.wire == value) return d;
    }
    return null;
  }
}

/// Named stick motions (QCF, HCB, DP, …).
enum MotionShape {
  quarterCircleForward('quarter_circle_forward'),
  quarterCircleBack('quarter_circle_back'),
  halfCircleForward('half_circle_forward'),
  halfCircleBack('half_circle_back'),
  dragonPunchForward('dragon_punch_forward'),
  dragonPunchBack('dragon_punch_back'),
  reverseDragonPunchForward('reverse_dragon_punch_forward'),
  reverseDragonPunchBack('reverse_dragon_punch_back'),
  fullCircle('full_circle'),
  doubleQuarterCircleForward('double_quarter_circle_forward'),
  doubleQuarterCircleBack('double_quarter_circle_back'),
  pretzelForward('pretzel_forward'),
  pretzelBack('pretzel_back');

  final String wire;
  const MotionShape(this.wire);

  static MotionShape? fromWire(String? value) {
    for (final s in MotionShape.values) {
      if (s.wire == value) return s;
    }
    return null;
  }
}

/// Directions valid as a charge origin.
enum ChargeDirection {
  back('back'),
  down('down'),
  downBack('down_back'),
  forward('forward'),
  downForward('down_forward');

  final String wire;
  const ChargeDirection(this.wire);

  static ChargeDirection? fromWire(String? value) {
    for (final d in ChargeDirection.values) {
      if (d.wire == value) return d;
    }
    return null;
  }
}

/// Kind discriminator for a [Requirement]. Unknown wire values are
/// coerced to [RequirementKind.unknown] per CONSUMER_SPEC §9.
enum RequirementKind {
  state('state'),
  spatial('spatial'),
  phase('phase'),
  stance('stance'),
  custom('custom'),
  unknown('unknown');

  final String wire;
  const RequirementKind(this.wire);

  static RequirementKind fromWire(String? value) {
    for (final k in RequirementKind.values) {
      if (k.wire == value) return k;
    }
    return RequirementKind.unknown;
  }
}

@immutable
class Requirement {
  final RequirementKind kind;

  /// Original wire kind string. Preserved so unknown discriminants are
  /// not lost when [kind] falls back to [RequirementKind.unknown].
  final String rawKind;
  final String? value;
  final String? description;

  const Requirement({
    required this.kind,
    required this.rawKind,
    this.value,
    this.description,
  });
}

/// Discriminated union of all expression nodes defined by the Gold
/// contract. Unknown [Expression.kind] values are surfaced as
/// [UnknownExpression] rather than silently dropped.
///
/// See CONSUMER_SPEC.md §9.
sealed class Expression {
  const Expression();
}

class ButtonExpr extends Expression {
  final String symbol;
  const ButtonExpr(this.symbol);
}

class DirectionExpr extends Expression {
  final GoldDirection direction;

  /// Present when the source carried an explicit `relative` boolean.
  /// Consumers reading a `player_relative` profile MAY treat null as
  /// `true`, and a `stick_absolute` profile MAY treat null as `false`.
  final bool? relative;
  const DirectionExpr(this.direction, {this.relative});
}

class MotionExpr extends Expression {
  final MotionShape shape;
  const MotionExpr(this.shape);
}

class NeutralExpr extends Expression {
  const NeutralExpr();
}

class SequenceExpr extends Expression {
  final List<Expression> steps;
  const SequenceExpr(this.steps);
}

class AlternativeExpr extends Expression {
  final List<Expression> options;
  const AlternativeExpr(this.options);
}

class SimultaneousExpr extends Expression {
  final List<Expression> inputs;
  const SimultaneousExpr(this.inputs);
}

class ChargeExpr extends Expression {
  final ChargeDirection chargeDirection;
  final int? durationMs;
  final Expression then;
  const ChargeExpr({
    required this.chargeDirection,
    required this.then,
    this.durationMs,
  });
}

class HoldExpr extends Expression {
  final Expression input;
  final int? durationMs;
  const HoldExpr({required this.input, this.durationMs});
}

class ReleaseExpr extends Expression {
  final Expression input;
  const ReleaseExpr({required this.input});
}

class RepeatExpr extends Expression {
  final Expression input;
  final int? count;
  final bool mash;
  const RepeatExpr({required this.input, this.count, this.mash = false});
}

class ContextualExpr extends Expression {
  final List<Requirement> requirements;
  final Expression input;
  const ContextualExpr({required this.requirements, required this.input});
}

class OptionalExpr extends Expression {
  final Expression input;
  const OptionalExpr({required this.input});
}

/// Verbatim fallback preserved when a subtree could not be parsed.
class FallbackExpr extends Expression {
  final String sourceRaw;
  const FallbackExpr(this.sourceRaw);
}

/// Placeholder for an unrecognised discriminant. Renderers MUST fall
/// back to the wrapper-level `source_raw`, or display
/// "unclear notation".
class UnknownExpression extends Expression {
  /// Original `kind` value from the wire.
  final String rawKind;

  /// Raw JSON verbatim for traceability (as `jsonEncode`-safe primitives).
  final Object? rawJson;
  const UnknownExpression({required this.rawKind, this.rawJson});
}
