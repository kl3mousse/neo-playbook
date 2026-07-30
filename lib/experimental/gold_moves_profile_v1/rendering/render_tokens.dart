import 'package:meta/meta.dart';

import '../domain/expression.dart';
import '../domain/move.dart';

/// Semantic tokens produced by [buildRenderTokens]. They are a
/// Flutter-independent intermediate representation over which text and
/// widget renderers walk.
///
/// The shape mirrors the `icon_tokens` array in `rendering-samples.json`
/// so that widget rendering and reference smoke tests share a single
/// source of truth.
@immutable
sealed class RenderToken {
  const RenderToken();
  Map<String, Object?> toJson();
}

@immutable
class RtMotion extends RenderToken {
  final String shape;
  const RtMotion(this.shape);
  @override
  Map<String, Object?> toJson() => {'type': 'motion', 'shape': shape};
}

@immutable
class RtDirection extends RenderToken {
  final String value;

  /// `true` when the source declares the direction explicitly relative
  /// to the player. Null when unspecified.
  final bool? relative;
  const RtDirection(this.value, {this.relative});
  @override
  Map<String, Object?> toJson() => {
    'type': 'direction',
    'value': value,
    // `relative` is only surfaced in the icon-token JSON when it
    // explicitly deviates from the Gold default of `true`. This
    // matches `rendering-samples.json`.
    if (relative == false) 'relative': false,
  };
}

@immutable
class RtButton extends RenderToken {
  final String symbol;
  const RtButton(this.symbol);
  @override
  Map<String, Object?> toJson() => {'type': 'button', 'symbol': symbol};
}

@immutable
class RtNeutral extends RenderToken {
  const RtNeutral();
  @override
  Map<String, Object?> toJson() => {'type': 'neutral'};
}

@immutable
class RtCharge extends RenderToken {
  final String chargeDirection;
  final int? durationMs;
  const RtCharge(this.chargeDirection, {this.durationMs});
  @override
  Map<String, Object?> toJson() => {
    'type': 'charge',
    'charge_direction': chargeDirection,
    if (durationMs != null) 'duration_ms': durationMs,
  };
}

@immutable
class RtHoldStart extends RenderToken {
  final int? durationMs;
  const RtHoldStart({this.durationMs});
  @override
  Map<String, Object?> toJson() => {
    'type': 'hold_start',
    if (durationMs != null) 'duration_ms': durationMs,
  };
}

@immutable
class RtHoldEnd extends RenderToken {
  const RtHoldEnd();
  @override
  Map<String, Object?> toJson() => {'type': 'hold_end'};
}

@immutable
class RtReleaseStart extends RenderToken {
  const RtReleaseStart();
  @override
  Map<String, Object?> toJson() => {'type': 'release_start'};
}

@immutable
class RtReleaseEnd extends RenderToken {
  const RtReleaseEnd();
  @override
  Map<String, Object?> toJson() => {'type': 'release_end'};
}

@immutable
class RtOptionalStart extends RenderToken {
  const RtOptionalStart();
  @override
  Map<String, Object?> toJson() => {'type': 'optional_start'};
}

@immutable
class RtOptionalEnd extends RenderToken {
  const RtOptionalEnd();
  @override
  Map<String, Object?> toJson() => {'type': 'optional_end'};
}

@immutable
class RtRepeatStart extends RenderToken {
  final int? count;
  final bool mash;
  const RtRepeatStart({this.count, this.mash = false});
  @override
  Map<String, Object?> toJson() => {
    'type': 'repeat_start',
    if (count != null) 'count': count,
    if (mash) 'mash': true,
  };
}

@immutable
class RtRepeatEnd extends RenderToken {
  const RtRepeatEnd();
  @override
  Map<String, Object?> toJson() => {'type': 'repeat_end'};
}

@immutable
class RtSimultaneousStart extends RenderToken {
  const RtSimultaneousStart();
  @override
  Map<String, Object?> toJson() => {'type': 'simultaneous_start'};
}

@immutable
class RtSimultaneousEnd extends RenderToken {
  const RtSimultaneousEnd();
  @override
  Map<String, Object?> toJson() => {'type': 'simultaneous_end'};
}

/// Marker between concurrent branches inside a simultaneous block.
@immutable
class RtSimultaneousSeparator extends RenderToken {
  const RtSimultaneousSeparator();
  @override
  Map<String, Object?> toJson() => {'type': 'simultaneous_sep'};
}

@immutable
class RtFallback extends RenderToken {
  final String sourceRaw;
  const RtFallback(this.sourceRaw);
  @override
  Map<String, Object?> toJson() => {
    'type': 'fallback',
    'source_raw': sourceRaw,
  };
}

/// Placeholder emitted for [UnknownExpression] nodes.
@immutable
class RtUnknown extends RenderToken {
  final String rawKind;
  const RtUnknown(this.rawKind);
  @override
  Map<String, Object?> toJson() => {'type': 'unknown', 'raw_kind': rawKind};
}

@immutable
class RtAlternative extends RenderToken {
  final List<List<RenderToken>> options;
  const RtAlternative(this.options);
  @override
  Map<String, Object?> toJson() => {
    'type': 'alternative',
    'options': [
      for (final o in options) [for (final t in o) t.toJson()],
    ],
  };
}

@immutable
class RtRequirement {
  final String kind;
  final String? value;
  final String? description;
  const RtRequirement({required this.kind, this.value, this.description});
  Map<String, Object?> toJson() => {
    'kind': kind,
    if (value != null) 'value': value,
    if (description != null) 'description': description,
  };
}

/// Requirements attached to the parent expression, appended to the
/// end of the token stream (matches rendering-samples).
@immutable
class RtContextualHint extends RenderToken {
  final List<RtRequirement> requirements;
  const RtContextualHint(this.requirements);
  @override
  Map<String, Object?> toJson() => {
    'type': 'contextual_hint',
    'requirements': [for (final r in requirements) r.toJson()],
  };
}

/// Build the flat token stream for a single [InputExpressionWrapper] or
/// bare [Expression]. Requirements from a top-level `contextual` node
/// are lifted to the tail as a `contextual_hint` token, matching the
/// reference `rendering-samples.json` output.
List<RenderToken> buildRenderTokens(Expression expr) {
  // Lift top-level contextual requirements.
  RtContextualHint? tail;
  Expression body = expr;
  if (body is ContextualExpr) {
    tail = RtContextualHint([
      for (final r in body.requirements)
        RtRequirement(
          kind: r.rawKind,
          value: r.value,
          description: r.description,
        ),
    ]);
    body = body.input;
  }
  final out = <RenderToken>[];
  _visit(body, out);
  if (tail != null) out.add(tail);
  return out;
}

void _visit(Expression e, List<RenderToken> out) {
  switch (e) {
    case ButtonExpr(:final symbol):
      out.add(RtButton(symbol));
    case DirectionExpr(:final direction, :final relative):
      out.add(RtDirection(direction.wire, relative: relative));
    case MotionExpr(:final shape):
      out.add(RtMotion(shape.wire));
    case NeutralExpr():
      out.add(const RtNeutral());
    case SequenceExpr(:final steps):
      for (final s in steps) {
        _visit(s, out);
      }
    case AlternativeExpr(:final options):
      out.add(RtAlternative([for (final o in options) _collect(o)]));
    case SimultaneousExpr(:final inputs):
      out.add(const RtSimultaneousStart());
      for (var i = 0; i < inputs.length; i++) {
        if (i > 0) out.add(const RtSimultaneousSeparator());
        _visit(inputs[i], out);
      }
      out.add(const RtSimultaneousEnd());
    case ChargeExpr(:final chargeDirection, :final durationMs, :final then):
      out.add(RtCharge(chargeDirection.wire, durationMs: durationMs));
      _visit(then, out);
    case HoldExpr(:final input, :final durationMs):
      out.add(RtHoldStart(durationMs: durationMs));
      _visit(input, out);
      out.add(const RtHoldEnd());
    case ReleaseExpr(:final input):
      out.add(const RtReleaseStart());
      _visit(input, out);
      out.add(const RtReleaseEnd());
    case RepeatExpr(:final input, :final count, :final mash):
      out.add(RtRepeatStart(count: count, mash: mash));
      _visit(input, out);
      out.add(const RtRepeatEnd());
    case OptionalExpr(:final input):
      out.add(const RtOptionalStart());
      _visit(input, out);
      out.add(const RtOptionalEnd());
    case ContextualExpr(:final requirements, :final input):
      // Nested contextual (not lifted). Emit hint before the sub-input.
      out.add(
        RtContextualHint([
          for (final r in requirements)
            RtRequirement(
              kind: r.rawKind,
              value: r.value,
              description: r.description,
            ),
        ]),
      );
      _visit(input, out);
    case FallbackExpr(:final sourceRaw):
      out.add(RtFallback(sourceRaw));
    case UnknownExpression(:final rawKind):
      out.add(RtUnknown(rawKind));
  }
}

List<RenderToken> _collect(Expression e) {
  final buf = <RenderToken>[];
  _visit(e, buf);
  return buf;
}

/// Convenience wrapper: build render tokens for the primary input
/// expression of a move (index 0), or return an empty list when the
/// move has no structured input (e.g. `automatic_after_move`).
List<RenderToken> renderTokensForMove(MoveGold move) {
  if (move.inputExpressions.isEmpty) return const [];
  final w = move.inputExpressions.first;
  final expr = w.expression;
  if (expr == null) return const [];
  return buildRenderTokens(expr);
}
