import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/arcade_panel.dart';
import '../domain/button.dart';
import '../domain/character.dart';
import '../domain/move.dart';
import '../rendering/render_tokens.dart';
import '../rendering/renderers/accessible_en_renderer.dart';
import '../rendering/renderers/accessible_fr_renderer.dart';
import '../rendering/renderers/activation_hint_renderer.dart';
import '../rendering/renderers/classic_2d_renderer.dart';
import '../rendering/renderers/numpad_renderer.dart';
import 'gold_input_row.dart';

/// Preferred textual notation displayed under the pictogram row.
enum NotationDisplay { numpad, classic2d }

/// Preferred accessible language for the semantic sentence.
enum GoldLocale { en, fr }

/// Experimental card showing a single Gold move with its command as
/// pictograms, the notation strings, requirements, annotations,
/// activation semantics, provenance dialect hint and follow-up refs.
class GoldMoveCard extends StatelessWidget {
  final MoveGold move;
  final CharacterSpec? character;
  final ButtonCatalog buttons;
  final NotationDisplay notation;
  final GoldLocale locale;

  const GoldMoveCard({
    super.key,
    required this.move,
    required this.buttons,
    this.character,
    this.notation = NotationDisplay.numpad,
    this.locale = GoldLocale.en,
  });

  @override
  Widget build(BuildContext context) {
    final isAuto = move.activation.kind == ActivationKind.automaticAfterMove;
    final accent = _categoryColor(move.category);

    return ArcadePanel(
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(accent),
          const SizedBox(height: 8),
          if (isAuto) _automaticBanner(),
          if (!isAuto) _inputSection(),
          if (move.annotations.isNotEmpty) ...[
            const SizedBox(height: 6),
            _annotations(),
          ],
          if (move.followUps.isNotEmpty) ...[
            const SizedBox(height: 6),
            _followUps(),
          ],
          if (move.sourceRaw != null && move.sourceRaw!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _sourceRawLine(),
          ],
        ],
      ),
    );
  }

  Widget _header(Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 32,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (character != null)
                Text(
                  character!.name,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              Text(
                move.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                move.rawCategory,
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _automaticBanner() {
    final hint = locale == GoldLocale.en
        ? ActivationHintRenderer().renderEn(move)
        : ActivationHintRenderer().renderFr(move);
    return Semantics(
      container: true,
      label: hint ?? '',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.autorenew, size: 16, color: AppColors.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint ?? '',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputSection() {
    if (move.inputExpressions.isEmpty) return const SizedBox.shrink();
    final w = move.inputExpressions.first;
    final expr = w.expression;
    List<RenderToken> tokens;
    if (expr == null) {
      tokens = w.sourceRaw == null ? const [] : [RtFallback(w.sourceRaw!)];
    } else {
      tokens = buildRenderTokens(expr);
    }

    final accessible =
        (locale == GoldLocale.en
            ? AccessibleEnRenderer().render(move)
            : AccessibleFrRenderer().render(move)) ??
        '';

    final notationString =
        (notation == NotationDisplay.numpad
            ? NumpadRenderer().render(move)
            : Classic2dRenderer().render(move)) ??
        (w.sourceRaw ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GoldInputRow(
          tokens: tokens,
          buttons: buttons,
          semanticSentence: accessible,
        ),
        const SizedBox(height: 6),
        Text(
          notationString,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _annotations() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final a in move.annotations)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${a.rawKind}: ${a.value ?? a.description ?? '—'}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _followUps() {
    return Text(
      'Follow-ups: ${move.followUps.map((f) => f.moveId).join(', ')}',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _sourceRawLine() {
    return Text(
      'source: ${move.sourceRaw}',
      style: TextStyle(
        color: AppColors.textSecondary.withValues(alpha: 0.7),
        fontSize: 10,
        fontFamily: 'monospace',
      ),
    );
  }

  Color _categoryColor(MoveCategory c) {
    return switch (c) {
      MoveCategory.normal || MoveCategory.commandNormal => AppColors.catCommand,
      MoveCategory.throwMove => AppColors.catThrow,
      MoveCategory.special => AppColors.catSpecial,
      MoveCategory.superMove => AppColors.catDM,
      MoveCategory.desperation ||
      MoveCategory.superDesperation => AppColors.catDM,
      MoveCategory.climax => AppColors.catSDM,
      MoveCategory.movement || MoveCategory.system => AppColors.catCommand,
      MoveCategory.cheat || MoveCategory.info => AppColors.textSecondary,
      MoveCategory.unknown => AppColors.textSecondary,
    };
  }
}
