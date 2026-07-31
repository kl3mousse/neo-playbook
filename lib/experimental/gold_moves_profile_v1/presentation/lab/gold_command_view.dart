import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/button.dart';
import '../../domain/expression.dart';
import '../../domain/move.dart';
import '../../rendering/renderers/accessible_en_renderer.dart';
import '../../rendering/renderers/accessible_fr_renderer.dart';
import '../gold_rendering_options.dart';
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

  const GoldCommandView({
    super.key,
    required this.move,
    required this.buttons,
    required this.locale,
    this.mirrorForFacingLeft = false,
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
  /// step separated by localized "then" chips so a long combo can
  /// break across lines between steps.
  List<Widget> _walkTop(Expression expr, AppLocalizations l) {
    if (expr is SequenceExpr) {
      final out = <Widget>[];
      for (var i = 0; i < expr.steps.length; i++) {
        if (i > 0) out.add(_SeparatorChip(l.commandSepThen));
        out.add(_groupFor(expr.steps[i], l));
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
        // A nested sequence inside a group is unusual (top-level
        // sequences are unrolled) but we render inline just in case.
        final out = <Widget>[];
        for (var i = 0; i < steps.length; i++) {
          if (i > 0) out.add(_SeparatorChip(l.commandSepThen));
          out.addAll(_inline(steps[i], l));
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
          if (i > 0) out.add(const _PlusChip());
          out.addAll(_inline(inputs[i], l));
        }
        return out;
      case MotionExpr(:final shape):
        return [_MotionPill(shape)];
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
        return [
          _ChargeChip(chargeDirection),
          _SeparatorChip(l.commandSepThen),
          ..._inline(then, l),
        ];
      case HoldExpr(:final input):
        return [
          _ParenGroup.open(l.commandHoldOpen),
          ..._inline(input, l),
          _ParenGroup.close(),
        ];
      case ReleaseExpr(:final input):
        return [
          _ParenGroup.open(l.commandReleaseOpen),
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
    return Tooltip(
      message: known ? label : 'Unknown symbol: $symbol',
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: known ? color : AppColors.surfaceLight,
          shape: BoxShape.circle,
          border: isGroup ? Border.all(color: Colors.white70, width: 1) : null,
        ),
        child: Text(
          symbol,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
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
    final glyph = _arrow(mirror ? _mirrored(direction) : direction);
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
      child: Text(
        glyph,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
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

  static String _arrow(GoldDirection d) => switch (d) {
    GoldDirection.neutral => '●',
    GoldDirection.forward => '→',
    GoldDirection.back => '←',
    GoldDirection.up => '↑',
    GoldDirection.down => '↓',
    GoldDirection.upForward => '↗',
    GoldDirection.upBack => '↖',
    GoldDirection.downForward => '↘',
    GoldDirection.downBack => '↙',
    GoldDirection.any => '✕',
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
    MotionShape.reverseDragonPunchForward => '421',
    MotionShape.reverseDragonPunchBack => '623',
    MotionShape.fullCircle => '360',
    MotionShape.doubleQuarterCircleForward => '236236',
    MotionShape.doubleQuarterCircleBack => '214214',
    MotionShape.pretzelForward => '1632143',
    MotionShape.pretzelBack => '3412367',
  };
}

class _ChargeChip extends StatelessWidget {
  final ChargeDirection direction;
  const _ChargeChip(this.direction);

  @override
  Widget build(BuildContext context) {
    final arrow = switch (direction) {
      ChargeDirection.back => '←',
      ChargeDirection.down => '↓',
      ChargeDirection.downBack => '↙',
      ChargeDirection.forward => '→',
      ChargeDirection.downForward => '↘',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.tokenBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timelapse, size: 12, color: AppColors.accent),
          const SizedBox(width: 3),
          Text(
            arrow,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ],
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

class _PlusChip extends StatelessWidget {
  const _PlusChip();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 1),
    child: Text(
      '+',
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w800,
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
