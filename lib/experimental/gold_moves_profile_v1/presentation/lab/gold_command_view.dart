import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/button.dart';
import '../../domain/expression.dart';
import '../../domain/move.dart';
import '../../rendering/renderers/accessible_en_renderer.dart';
import '../../rendering/renderers/accessible_fr_renderer.dart';
import '../gold_glyph_assets.dart';
import '../gold_rendering_options.dart';
import '../gold_svg_glyph.dart';
import 'lab_localization.dart';

/// Compact, group-preserving pictogram renderer for a [MoveGold]
/// command.
///
/// Unlike the flat token-based [GoldInputRow], this widget walks the
/// [Expression] tree recursively and emits one indivisible *group*
/// widget per semantic subtree. Groups are laid out in a [Wrap], so
/// the row may break between groups but a group itself (e.g. `236A`,
/// `A+B`, `[Down]`) never splits across lines.
///
/// The whole widget carries a single accessible label so screen
/// readers speak one sentence instead of enumerating every glyph
/// (CONSUMER_SPEC §9 / a11y).
class GoldCommandView extends StatelessWidget {
  final MoveGold move;
  final ButtonCatalog buttons;
  final GoldAccessibleLocale locale;
  final bool mirrorForFacingLeft;
  final GoldVisualNotation visualNotation;

  const GoldCommandView({
    super.key,
    required this.move,
    required this.buttons,
    required this.locale,
    this.mirrorForFacingLeft = false,
    this.visualNotation = GoldVisualNotation.arrowIcons,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final accessible = _accessibleSentence();

    final groups = <Widget>[];
    if (move.inputExpressions.isEmpty ||
        (move.inputExpressions.first.expression == null &&
            (move.inputExpressions.first.sourceRaw == null ||
                move.inputExpressions.first.sourceRaw!.isEmpty))) {
      groups.add(_NoInputGroup(label: l.commandNoInputNeeded));
    } else {
      final w = move.inputExpressions.first;
      final expr = w.expression;
      if (expr == null) {
        groups.add(
          _FallbackGroup(
            sourceRaw: w.sourceRaw ?? '',
            hint: l.commandFallbackHint,
          ),
        );
      } else {
        groups.addAll(_walkTop(expr, l));
      }
    }

    return Semantics(
      container: true,
      label: accessible.isEmpty ? move.name : accessible,
      excludeSemantics: true,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.start,
        children: groups,
      ),
    );
  }

  String _accessibleSentence() {
    return (locale == GoldAccessibleLocale.en
            ? AccessibleEnRenderer().render(move)
            : AccessibleFrRenderer().render(move)) ??
        '';
  }

  /// Top-level walker: unrolls a top [SequenceExpr] into one group per
  /// step so a long combo can break across lines between inputs.
  List<Widget> _walkTop(Expression expr, AppLocalizations l) {
    if (expr is SequenceExpr) {
      final out = <Widget>[];
      final steps = _collapseDirectionalSteps(expr.steps);
      for (var index = 0; index < steps.length; index++) {
        out.add(_groupFor(steps[index], l));
      }
      return out;
    }
    return [_groupFor(expr, l)];
  }

  /// Wraps [expr] into a single indivisible group widget. The group's
  /// visual is produced by [_inline] which renders the tokens inline
  /// so the whole subtree fits on a single line and wraps as one unit.
  Widget _groupFor(Expression expr, AppLocalizations l) {
    if (expr is ContextualExpr) {
      // Contextual: requirement chip + a nested group so the "only
      // when …" reads as one visual unit but wraps as two if needed.
      return _ContextualGroup(
        requirements: expr.requirements,
        child: _groupFor(expr.input, l),
      );
    }
    return _TokenGroup(
      child: Wrap(
        spacing: 3,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: _inline(expr, l),
      ),
    );
  }

  /// Inline walker: produces horizontally-laid-out chips for a single
  /// group. Groups may be nested (e.g. a repeat around a simultaneous
  /// press) — recursion keeps them visually joined.
  List<Widget> _inline(Expression expr, AppLocalizations l) {
    switch (expr) {
      case SequenceExpr(:final steps):
        // A nested sequence inside a group is unusual (top-level sequences
        // are unrolled), but it follows the same compact presentation.
        final out = <Widget>[];
        final displaySteps = _collapseDirectionalSteps(steps);
        for (var index = 0; index < displaySteps.length; index++) {
          out.addAll(_inline(displaySteps[index], l));
        }
        return out;
      case AlternativeExpr(:final options):
        final out = <Widget>[];
        for (var i = 0; i < options.length; i++) {
          if (i > 0) out.add(_SeparatorChip(l.commandSepOr));
          out.addAll(_inline(options[i], l));
        }
        return out;
      case SimultaneousExpr(:final inputs):
        final out = <Widget>[];
        for (var i = 0; i < inputs.length; i++) {
          if (i > 0) {
            out.add(const _OperatorGlyphToken(GoldGlyphOperator.plus));
          }
          out.addAll(_inline(inputs[i], l));
        }
        return out;
      case MotionExpr(:final shape):
        return visualNotation == GoldVisualNotation.motionGlyphs
            ? [
                _MotionGlyphToken(
                  shape,
                  mirrorForFacingLeft: mirrorForFacingLeft,
                ),
              ]
            : _directionSequence(
                GoldGlyphAssets.motionDirections(
                  shape,
                  mirrorForFacingLeft: mirrorForFacingLeft,
                ),
              );
      case DirectionExpr(:final direction):
        return [_DirectionToken(direction, mirror: mirrorForFacingLeft)];
      case ButtonExpr(:final symbol):
        return [
          _ButtonToken(
            symbol: symbol,
            label: buttons.labelFor(symbol),
            known: buttons.isKnown(symbol),
            isGroup: buttons.isGroup(symbol),
          ),
        ];
      case NeutralExpr():
        return [const _NeutralToken()];
      case ChargeExpr(:final chargeDirection, :final then):
        return _charge(chargeDirection, then, l);
      case HoldExpr(:final input):
        return [
          const _OperatorGlyphToken(GoldGlyphOperator.hold),
          const _OpeningParen(),
          ..._inline(input, l),
          _ParenGroup.close(),
        ];
      case ReleaseExpr(:final input):
        return [
          const _OperatorGlyphToken(GoldGlyphOperator.release),
          const _OpeningParen(),
          ..._inline(input, l),
          _ParenGroup.close(),
        ];
      case OptionalExpr(:final input):
        return [
          _ParenGroup.open(l.commandOptionalOpen),
          ..._inline(input, l),
          _ParenGroup.closeOptional(),
        ];
      case RepeatExpr(:final input, :final count):
        final label = count == null
            ? l.commandRepeatRapidly
            : l.commandRepeatCount(count);
        return [
          _ParenGroup.open(label),
          ..._inline(input, l),
          _ParenGroup.close(),
        ];
      case ContextualExpr(:final requirements, :final input):
        return [_RequirementInlineChip(requirements), ..._inline(input, l)];
      case FallbackExpr(:final sourceRaw):
        return [
          _FallbackGroup(sourceRaw: sourceRaw, hint: l.commandFallbackHint),
        ];
      case UnknownExpression(:final rawKind):
        return [_UnknownChip('${l.commandUnknownInput} ($rawKind)')];
    }
  }

  /// Folds common direction-by-direction inputs into a single motion glyph.
  /// Profiles may represent a quarter circle either as a [MotionExpr] or as
  /// three [DirectionExpr] values, so both forms need the same presentation.
  List<Expression> _collapseDirectionalSteps(List<Expression> steps) {
    if (visualNotation != GoldVisualNotation.motionGlyphs) return steps;

    final result = <Expression>[];
    var index = 0;
    while (index < steps.length) {
      final match = _motionAt(steps, index);
      if (match == null) {
        result.add(steps[index]);
        index++;
      } else {
        result.add(MotionExpr(match.shape));
        index += match.directions.length;
      }
    }
    return result;
  }

  List<Widget> _directionSequence(List<GoldDirection> directions) {
    final widgets = <Widget>[];
    for (final direction in directions) {
      widgets.add(_DirectionToken(direction, mirror: false));
    }
    return widgets;
  }

  List<Widget> _charge(
    ChargeDirection chargeDirection,
    Expression then,
    AppLocalizations l,
  ) {
    final origin = _chargeOrigin(chargeDirection);
    final steps = then is SequenceExpr ? then.steps : <Expression>[then];
    final expectedRelease = switch (chargeDirection) {
      ChargeDirection.back => GoldDirection.forward,
      ChargeDirection.down => GoldDirection.up,
      _ => null,
    };
    final firstStep = steps.isEmpty ? null : steps.first;
    final isCompleteMotion =
        visualNotation == GoldVisualNotation.motionGlyphs &&
        expectedRelease != null &&
        firstStep is DirectionExpr &&
        firstStep.direction == expectedRelease;

    if (isCompleteMotion) {
      final asset = chargeDirection == ChargeDirection.back
          ? 'assets/glyphs/motions/motion_charge_bf.svg'
          : 'assets/glyphs/motions/motion_charge_du.svg';
      final widgets = <Widget>[
        _MotionAssetToken(
          assetPath: asset,
          tooltip: chargeDirection == ChargeDirection.back
              ? 'Charge back to forward'
              : 'Charge down to up',
          flipHorizontally:
              mirrorForFacingLeft && chargeDirection == ChargeDirection.back,
        ),
      ];
      for (final tail in steps.skip(1)) {
        widgets.addAll(_inline(tail, l));
      }
      return widgets;
    }

    return [
      const _OperatorGlyphToken(GoldGlyphOperator.hold),
      _DirectionToken(origin, mirror: mirrorForFacingLeft),
      ..._inline(then, l),
    ];
  }

  GoldDirection _chargeOrigin(ChargeDirection direction) => switch (direction) {
    ChargeDirection.back => GoldDirection.back,
    ChargeDirection.down => GoldDirection.down,
    ChargeDirection.downBack => GoldDirection.downBack,
    ChargeDirection.forward => GoldDirection.forward,
    ChargeDirection.downForward => GoldDirection.downForward,
  };

  _MotionPattern? _motionAt(List<Expression> steps, int start) {
    for (final pattern in _motionPatterns) {
      if (start + pattern.directions.length > steps.length) continue;
      var matches = true;
      for (var offset = 0; offset < pattern.directions.length; offset++) {
        final step = steps[start + offset];
        if (step is! DirectionExpr ||
            step.direction != pattern.directions[offset]) {
          matches = false;
          break;
        }
      }
      if (matches) return pattern;
    }
    return null;
  }

  static const _motionPatterns = <_MotionPattern>[
    _MotionPattern(MotionShape.doubleQuarterCircleForward, [
      GoldDirection.down,
      GoldDirection.downForward,
      GoldDirection.forward,
      GoldDirection.down,
      GoldDirection.downForward,
      GoldDirection.forward,
    ]),
    _MotionPattern(MotionShape.doubleQuarterCircleBack, [
      GoldDirection.down,
      GoldDirection.downBack,
      GoldDirection.back,
      GoldDirection.down,
      GoldDirection.downBack,
      GoldDirection.back,
    ]),
    _MotionPattern(MotionShape.halfCircleForward, [
      GoldDirection.back,
      GoldDirection.downBack,
      GoldDirection.down,
      GoldDirection.downForward,
      GoldDirection.forward,
    ]),
    _MotionPattern(MotionShape.halfCircleBack, [
      GoldDirection.forward,
      GoldDirection.downForward,
      GoldDirection.down,
      GoldDirection.downBack,
      GoldDirection.back,
    ]),
    _MotionPattern(MotionShape.pretzelForward, [
      GoldDirection.downBack,
      GoldDirection.forward,
      GoldDirection.downForward,
      GoldDirection.down,
      GoldDirection.downBack,
      GoldDirection.back,
      GoldDirection.downForward,
    ]),
    _MotionPattern(MotionShape.pretzelBack, [
      GoldDirection.downForward,
      GoldDirection.back,
      GoldDirection.downBack,
      GoldDirection.down,
      GoldDirection.downForward,
      GoldDirection.forward,
      GoldDirection.upBack,
    ]),
    _MotionPattern(MotionShape.fullCircle, [
      GoldDirection.forward,
      GoldDirection.downForward,
      GoldDirection.down,
      GoldDirection.downBack,
      GoldDirection.back,
      GoldDirection.upBack,
      GoldDirection.up,
      GoldDirection.upForward,
    ]),
    _MotionPattern(MotionShape.dragonPunchForward, [
      GoldDirection.forward,
      GoldDirection.down,
      GoldDirection.downForward,
    ]),
    _MotionPattern(MotionShape.dragonPunchBack, [
      GoldDirection.back,
      GoldDirection.down,
      GoldDirection.downBack,
    ]),
    _MotionPattern(MotionShape.reverseDragonPunchForward, [
      GoldDirection.forward,
      GoldDirection.downForward,
      GoldDirection.down,
    ]),
    _MotionPattern(MotionShape.reverseDragonPunchBack, [
      GoldDirection.back,
      GoldDirection.downBack,
      GoldDirection.down,
    ]),
    _MotionPattern(MotionShape.quarterCircleForward, [
      GoldDirection.down,
      GoldDirection.downForward,
      GoldDirection.forward,
    ]),
    _MotionPattern(MotionShape.quarterCircleBack, [
      GoldDirection.down,
      GoldDirection.downBack,
      GoldDirection.back,
    ]),
  ];
}

class _MotionPattern {
  final MotionShape shape;
  final List<GoldDirection> directions;

  const _MotionPattern(this.shape, this.directions);
}

// ─────────────────────────────────────────────────────────────────
// Group wrappers
// ─────────────────────────────────────────────────────────────────

class _TokenGroup extends StatelessWidget {
  final Widget child;
  const _TokenGroup({required this.child});

  @override
  Widget build(BuildContext context) {
    // A group has *intrinsic* width and never gets a full-line
    // background: the visual weight comes from the tokens inside.
    // Padding is minimal so several groups fit on a phone-sized row.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: child,
    );
  }
}

class _ContextualGroup extends StatelessWidget {
  final List<Requirement> requirements;
  final Widget child;
  const _ContextualGroup({required this.requirements, required this.child});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [_RequirementInlineChip(requirements), child],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Tokens
// ─────────────────────────────────────────────────────────────────

class _ButtonToken extends StatelessWidget {
  final String symbol;
  final String label;
  final bool known;
  final bool isGroup;
  const _ButtonToken({
    required this.symbol,
    required this.label,
    required this.known,
    required this.isGroup,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (symbol) {
      'A' => AppColors.buttonA,
      'B' => AppColors.buttonB,
      'C' => AppColors.buttonC,
      'D' => AppColors.buttonD,
      _ => AppColors.primary,
    };
    final assetPath = known ? GoldGlyphAssets.button(symbol) : null;
    final shellFallback = Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: known ? color : AppColors.surfaceLight,
        shape: BoxShape.circle,
        border: isGroup ? Border.all(color: Colors.white70, width: 1) : null,
      ),
    );
    return Tooltip(
      message: known ? label : 'Unknown symbol: $symbol',
      child: SizedBox(
        width: 24,
        height: 24,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (assetPath != null)
              GoldSvgGlyph(
                assetPath: assetPath,
                tooltip: label,
                color: color,
                fallback: shellFallback,
              )
            else
              shellFallback,
            Text(
              symbol,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionToken extends StatelessWidget {
  final GoldDirection direction;
  final bool mirror;
  const _DirectionToken(this.direction, {required this.mirror});

  @override
  Widget build(BuildContext context) {
    final displayDirection = mirror ? _mirrored(direction) : direction;
    final assetPath = GoldGlyphAssets.direction(displayDirection);
    final fallback = Icon(
      _icon(displayDirection),
      color: AppColors.textPrimary,
      size: 15,
    );
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.tokenBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: assetPath == null
          ? fallback
          : GoldSvgGlyph(
              assetPath: assetPath,
              tooltip: displayDirection.wire.replaceAll('_', ' '),
              color: AppColors.textPrimary,
              size: 16,
              fallback: fallback,
            ),
    );
  }

  static GoldDirection _mirrored(GoldDirection d) => switch (d) {
    GoldDirection.forward => GoldDirection.back,
    GoldDirection.back => GoldDirection.forward,
    GoldDirection.upForward => GoldDirection.upBack,
    GoldDirection.upBack => GoldDirection.upForward,
    GoldDirection.downForward => GoldDirection.downBack,
    GoldDirection.downBack => GoldDirection.downForward,
    _ => d,
  };

  static IconData _icon(GoldDirection d) => switch (d) {
    GoldDirection.neutral => Icons.circle,
    GoldDirection.forward => Icons.arrow_forward,
    GoldDirection.back => Icons.arrow_back,
    GoldDirection.up => Icons.arrow_upward,
    GoldDirection.down => Icons.arrow_downward,
    GoldDirection.upForward => Icons.north_east,
    GoldDirection.upBack => Icons.north_west,
    GoldDirection.downForward => Icons.south_east,
    GoldDirection.downBack => Icons.south_west,
    GoldDirection.any => Icons.all_inclusive,
  };
}

class _MotionPill extends StatelessWidget {
  final MotionShape shape;
  const _MotionPill(this.shape);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.tokenBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Text(
        _numpadFor(shape),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.0,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  static String _numpadFor(MotionShape s) => switch (s) {
    MotionShape.quarterCircleForward => '236',
    MotionShape.quarterCircleBack => '214',
    MotionShape.halfCircleForward => '41236',
    MotionShape.halfCircleBack => '63214',
    MotionShape.dragonPunchForward => '623',
    MotionShape.dragonPunchBack => '421',
    MotionShape.reverseDragonPunchForward => '632',
    MotionShape.reverseDragonPunchBack => '412',
    MotionShape.fullCircle => '360',
    MotionShape.doubleQuarterCircleForward => '236236',
    MotionShape.doubleQuarterCircleBack => '214214',
    MotionShape.pretzelForward => '1632143',
    MotionShape.pretzelBack => '3412367',
  };
}

class _MotionGlyphToken extends StatelessWidget {
  final MotionShape shape;
  final bool mirrorForFacingLeft;
  const _MotionGlyphToken(this.shape, {required this.mirrorForFacingLeft});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: _MotionPill._numpadFor(shape),
    child: Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.tokenBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: GoldSvgGlyph(
        assetPath: GoldGlyphAssets.motion(
          shape,
          mirrorForFacingLeft: mirrorForFacingLeft,
        ),
        tooltip: shape.wire.replaceAll('_', ' '),
        color: AppColors.textPrimary,
        fallback: Center(child: Text(_MotionPill._numpadFor(shape))),
      ),
    ),
  );
}

class _MotionAssetToken extends StatelessWidget {
  final String assetPath;
  final String tooltip;
  final bool flipHorizontally;

  const _MotionAssetToken({
    required this.assetPath,
    required this.tooltip,
    this.flipHorizontally = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.tokenBackground,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: AppColors.primary.withValues(alpha: 0.6),
        width: 0.8,
      ),
    ),
    child: Transform.flip(
      flipX: flipHorizontally,
      child: GoldSvgGlyph(
        assetPath: assetPath,
        tooltip: tooltip,
        color: AppColors.textPrimary,
        fallback: const Icon(Icons.sync_alt, size: 18),
      ),
    ),
  );
}

class _OperatorGlyphToken extends StatelessWidget {
  final GoldGlyphOperator operator;
  const _OperatorGlyphToken(this.operator);

  @override
  Widget build(BuildContext context) {
    final tooltip = switch (operator) {
      GoldGlyphOperator.plus => 'Simultaneous',
      GoldGlyphOperator.then => 'Then',
      GoldGlyphOperator.hold => 'Hold',
      GoldGlyphOperator.release => 'Release',
    };
    final fallback = Text(switch (operator) {
      GoldGlyphOperator.plus => '+',
      GoldGlyphOperator.then => '→',
      GoldGlyphOperator.hold => 'hold',
      GoldGlyphOperator.release => 'release',
    }, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11));
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.tokenBackground,
        borderRadius: BorderRadius.circular(3),
      ),
      child: GoldSvgGlyph(
        assetPath: GoldGlyphAssets.operator(operator),
        tooltip: tooltip,
        color: AppColors.textPrimary,
        size: 14,
        fallback: fallback,
      ),
    );
  }
}

class _NeutralToken extends StatelessWidget {
  const _NeutralToken();

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.tokenBackground,
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Text(
      '●',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        height: 1.0,
      ),
    ),
  );
}

class _SeparatorChip extends StatelessWidget {
  final String label;
  const _SeparatorChip(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Text(
      label,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontStyle: FontStyle.italic,
        height: 1.0,
      ),
    ),
  );
}

class _ParenGroup extends StatelessWidget {
  final String text;
  final bool close;
  final bool isOptional;
  const _ParenGroup.open(this.text) : close = false, isOptional = false;
  const _ParenGroup.close() : text = ')', close = true, isOptional = false;
  const _ParenGroup.closeOptional()
    : text = ')?',
      close = true,
      isOptional = true;

  @override
  Widget build(BuildContext context) {
    if (close) {
      return Text(
        text,
        style: TextStyle(
          color: isOptional ? AppColors.accent : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
              height: 1.0,
            ),
          ),
          const Text(
            ' (',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpeningParen extends StatelessWidget {
  const _OpeningParen();

  @override
  Widget build(BuildContext context) => const Text(
    '(',
    style: TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.0,
    ),
  );
}

class _RequirementInlineChip extends StatelessWidget {
  final List<Requirement> requirements;
  const _RequirementInlineChip(this.requirements);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final txt = requirements.map((r) => localizeRequirement(l, r)).join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Text(
        txt,
        style: TextStyle(
          color: AppColors.secondary,
          fontSize: 10,
          fontStyle: FontStyle.italic,
          height: 1.1,
        ),
      ),
    );
  }
}

class _FallbackGroup extends StatelessWidget {
  final String sourceRaw;
  final String hint;
  const _FallbackGroup({required this.sourceRaw, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: hint,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange, width: 0.8),
        ),
        child: Text(
          sourceRaw.isEmpty ? '—' : sourceRaw,
          style: const TextStyle(
            color: Colors.orange,
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _UnknownChip extends StatelessWidget {
  final String text;
  const _UnknownChip(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.orange, width: 0.8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.orange,
        fontSize: 11,
        fontStyle: FontStyle.italic,
        height: 1.0,
      ),
    ),
  );
}

class _NoInputGroup extends StatelessWidget {
  final String label;
  const _NoInputGroup({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: AppColors.textSecondary.withValues(alpha: 0.4),
        width: 0.8,
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontStyle: FontStyle.italic,
        height: 1.0,
      ),
    ),
  );
}
