import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../domain/button.dart';
import '../rendering/render_tokens.dart';

/// Configuration knobs used by widget renderers.
class GoldRenderContext {
  /// Mirror `player_relative` directions when true. Kept off by default
  /// so the rendering is semantically correct without knowing the side
  /// of the screen (CONSUMER_SPEC §5).
  final bool mirrorForFacingLeft;

  const GoldRenderContext({this.mirrorForFacingLeft = false});
}

/// Reusable pictogram row that renders a Gold input expression as a
/// horizontal, wrap-friendly widget list.
///
/// Each token maps to a colored chip consistent with existing
/// [InputToken] visuals (arrows, buttons, charge markers). Every
/// visible chip receives a semantic label so the whole row can be
/// summarised by an accessible sentence supplied by the caller.
class GoldInputRow extends StatelessWidget {
  final List<RenderToken> tokens;
  final ButtonCatalog buttons;
  final String semanticSentence;
  final GoldRenderContext context;

  const GoldInputRow({
    super.key,
    required this.tokens,
    required this.buttons,
    required this.semanticSentence,
    this.context = const GoldRenderContext(),
  });

  @override
  Widget build(BuildContext buildContext) {
    return Semantics(
      container: true,
      label: semanticSentence,
      // A single accessible sentence is more intelligible than each
      // pictogram announced separately (CONSUMER_SPEC §9 / a11y).
      excludeSemantics: true,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: _buildChildren(),
      ),
    );
  }

  List<Widget> _buildChildren() {
    final out = <Widget>[];
    for (final t in tokens) {
      _emit(t, out);
    }
    return out;
  }

  void _emit(RenderToken t, List<Widget> out) {
    switch (t) {
      case RtMotion(:final shape):
        out.add(
          _TextChip(
            _motionGlyph(shape),
            background: AppColors.tokenBackground,
            foreground: AppColors.textPrimary,
          ),
        );
      case RtDirection(:final value):
        out.add(
          _TextChip(
            _directionArrow(value),
            background: AppColors.tokenBackground,
            foreground: AppColors.textPrimary,
          ),
        );
      case RtButton(:final symbol):
        out.add(
          _ButtonChip(
            symbol,
            buttons.labelFor(symbol),
            isGroup: buttons.isGroup(symbol),
            known: buttons.isKnown(symbol),
          ),
        );
      case RtNeutral():
        out.add(
          const _TextChip(
            '●',
            background: AppColors.tokenBackground,
            foreground: AppColors.textSecondary,
          ),
        );
      case RtCharge(:final chargeDirection):
        out.add(
          _TextChip(
            '⏱ ${_directionArrow(chargeDirection)}',
            background: AppColors.tokenBackground,
            foreground: AppColors.textPrimary,
          ),
        );
      case RtHoldStart():
        out.add(const _MarkerChip('hold ('));
      case RtHoldEnd():
        out.add(const _MarkerChip(')'));
      case RtReleaseStart():
        out.add(const _MarkerChip('release ('));
      case RtReleaseEnd():
        out.add(const _MarkerChip(')'));
      case RtOptionalStart():
        out.add(const _MarkerChip('optional ('));
      case RtOptionalEnd():
        out.add(const _MarkerChip(')?'));
      case RtRepeatStart(:final count):
        out.add(_MarkerChip(count == null ? 'rapidly (' : '×$count ('));
      case RtRepeatEnd():
        out.add(const _MarkerChip(')'));
      case RtSimultaneousStart():
        // Rendered implicitly via `+` separators between inputs.
        break;
      case RtSimultaneousEnd():
        break;
      case RtSimultaneousSeparator():
        out.add(const _MarkerChip('+'));
      case RtFallback(:final sourceRaw):
        out.add(_FallbackChip(sourceRaw));
      case RtUnknown(:final rawKind):
        out.add(_MarkerChip('? ($rawKind)'));
      case RtAlternative(:final options):
        for (var i = 0; i < options.length; i++) {
          if (i > 0) out.add(const _MarkerChip('|'));
          for (final tt in options[i]) {
            _emit(tt, out);
          }
        }
      case RtContextualHint(:final requirements):
        out.add(_RequirementChip(requirements));
    }
  }

  String _motionGlyph(String shape) {
    return switch (shape) {
      'quarter_circle_forward' => 'QCF',
      'quarter_circle_back' => 'QCB',
      'half_circle_forward' => 'HCF',
      'half_circle_back' => 'HCB',
      'dragon_punch_forward' => 'DP',
      'dragon_punch_back' => 'RDP',
      'reverse_dragon_punch_forward' => 'RDPf',
      'reverse_dragon_punch_back' => 'RDPb',
      'full_circle' => '360',
      'double_quarter_circle_forward' => '2×QCF',
      'double_quarter_circle_back' => '2×QCB',
      _ => shape,
    };
  }

  String _directionArrow(String d) {
    // Mirror only forward/back and their diagonals when requested. Up
    // and down are never mirrored.
    final source = context.mirrorForFacingLeft ? _mirror(d) : d;
    return switch (source) {
      'neutral' => '●',
      'forward' => '→',
      'back' => '←',
      'up' => '↑',
      'down' => '↓',
      'up_forward' => '↗',
      'up_back' => '↖',
      'down_forward' => '↘',
      'down_back' => '↙',
      'any' => '✕',
      _ => source,
    };
  }

  String _mirror(String d) {
    return switch (d) {
      'forward' => 'back',
      'back' => 'forward',
      'up_forward' => 'up_back',
      'up_back' => 'up_forward',
      'down_forward' => 'down_back',
      'down_back' => 'down_forward',
      _ => d,
    };
  }
}

// ── Chips ───────────────────────────────────────────────────────

class _TextChip extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  const _TextChip(
    this.text, {
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ButtonChip extends StatelessWidget {
  final String symbol;
  final String label;
  final bool isGroup;
  final bool known;
  const _ButtonChip(
    this.symbol,
    this.label, {
    required this.isGroup,
    required this.known,
  });

  @override
  Widget build(BuildContext context) {
    // Colour convention aligned with existing InputToken palette.
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
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: known ? color : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: isGroup
              ? Border.all(
                  color: Colors.white70,
                  width: 1,
                  style: BorderStyle.solid,
                )
              : null,
        ),
        child: Text(
          symbol,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _MarkerChip extends StatelessWidget {
  final String text;
  const _MarkerChip(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _FallbackChip extends StatelessWidget {
  final String sourceRaw;
  const _FallbackChip(this.sourceRaw);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.orange, width: 0.8),
    ),
    child: Text(
      sourceRaw,
      style: const TextStyle(
        color: Colors.orange,
        fontFamily: 'monospace',
        fontSize: 12,
      ),
    ),
  );
}

class _RequirementChip extends StatelessWidget {
  final List<RtRequirement> requirements;
  const _RequirementChip(this.requirements);
  @override
  Widget build(BuildContext context) {
    final text = requirements
        .map((r) => r.value ?? r.description ?? r.kind)
        .join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.secondary,
          fontSize: 11,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
