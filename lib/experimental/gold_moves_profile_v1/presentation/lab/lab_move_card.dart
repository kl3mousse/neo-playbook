import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/arcade_panel.dart';
import '../../domain/button.dart';
import '../../domain/character.dart';
import '../../domain/expression.dart';
import '../../domain/move.dart';
import '../../rendering/renderers/accessible_en_renderer.dart';
import '../../rendering/renderers/accessible_fr_renderer.dart';
import '../../rendering/renderers/activation_hint_renderer.dart';
import '../../rendering/renderers/classic_2d_renderer.dart';
import '../../rendering/renderers/numpad_renderer.dart';
import '../gold_rendering_options.dart';
import 'gold_command_view.dart';
import 'lab_controller.dart';
import 'lab_localization.dart';

/// A move card wired to the [LabController]. Distinct from
/// `GoldMoveCard` because it must honor four notation modes (each
/// mode is rendered *in isolation* — no redundant secondary line) and
/// expose lab-only affordances (parent-move jump, technical details,
/// automatic-badge banner).
///
/// The [density] switch changes information density, not just
/// padding: Compact drops requirements chips, annotations,
/// follow-ups, and the character-name row so a whole card fits in a
/// single visual line on a narrow phone.
class GoldProfileMoveCard extends StatelessWidget {
  final MoveGold move;
  final CharacterSpec? character;
  final ButtonCatalog buttons;
  final GoldNotation notation;
  final GoldAccessibleLocale locale;
  final GoldDensity density;
  final VoidCallback? onParentMoveTap;
  final String? automaticParentName;
  final VoidCallback? onTap;
  final bool selected;

  /// When true, appends an expandable "Technical details" block
  /// containing `source_raw`, follow-up move IDs, and internal
  /// annotations. Off by default so cards stay clean; the lab
  /// settings sheet can flip this on for auditing.
  final bool showTechnicalDetails;

  const GoldProfileMoveCard({
    super.key,
    required this.move,
    required this.buttons,
    required this.notation,
    required this.locale,
    this.density = GoldDensity.comfortable,
    this.character,
    this.onParentMoveTap,
    this.automaticParentName,
    this.onTap,
    this.selected = false,
    this.showTechnicalDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAuto = move.activation.kind == ActivationKind.automaticAfterMove;
    final accent = _categoryColor(move.category);
    final isCompact = density == GoldDensity.compact;
    final pad = isCompact ? const EdgeInsets.all(6) : const EdgeInsets.all(12);

    return ArcadePanel(
      accentColor: accent,
      isActive: selected,
      onTap: onTap,
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, accent, l, isCompact),
          SizedBox(height: isCompact ? 3 : 8),
          if (isAuto)
            _automaticBlock(context, l, isCompact)
          else
            _inputSection(context, l),
          if (!isCompact && !isAuto) _contextRequirements(l),
          if (!isCompact && move.annotations.isNotEmpty) ...[
            const SizedBox(height: 6),
            _annotations(),
          ],
          if (showTechnicalDetails) ...[
            const SizedBox(height: 6),
            _technicalDetails(context, l),
          ],
        ],
      ),
    );
  }

  Widget _header(
    BuildContext context,
    Color accent,
    AppLocalizations l,
    bool isCompact,
  ) {
    final isAuto = move.activation.kind == ActivationKind.automaticAfterMove;
    final category = localizeCategory(l, move.category, move.rawCategory);
    if (isCompact) {
      // Compact: single row — accent bar + name (+ character bullet)
      // + tiny category text + optional auto badge.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              character != null
                  ? '${move.name} · ${character!.name}'
                  : move.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            category,
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.1,
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (isAuto) ...[
            const SizedBox(width: 4),
            _AutoBadge(label: l.labAutomaticBadge, dense: true),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
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
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _CategoryChip(color: accent, label: category),
                  if (isAuto) _AutoBadge(label: l.labAutomaticBadge),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _automaticBlock(
    BuildContext context,
    AppLocalizations l,
    bool isCompact,
  ) {
    final parentId = move.activation.trigger?.parentMoveId ?? '';
    final hint = _accessibleHint(l);
    // Distinctive visual: bordered info panel with autorenew icon.
    // Deliberately NOT a filled button so it does not read as
    // "press to activate" — the badge already says AUTO.
    return Semantics(
      container: true,
      label: '${l.labAutomaticBadge}. $hint',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 10,
          vertical: isCompact ? 4 : 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.autorenew,
                  size: isCompact ? 12 : 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isCompact ? l.labAutomaticBadge : l.labAutomaticExplanation,
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: isCompact ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l.commandNoInputNeeded,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: isCompact ? 11 : 12,
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(height: 2),
              Text(
                hint,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            if (automaticParentName != null) ...[
              const SizedBox(height: 2),
              Text(
                l.labAutomaticFollowUpOf(automaticParentName!),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (parentId.isNotEmpty && onParentMoveTap != null) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: onParentMoveTap,
                icon: Icon(Icons.arrow_upward, size: isCompact ? 14 : 16),
                label: Text(l.labAutomaticJumpToParent),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _accessibleHint(AppLocalizations l) {
    final ah = ActivationHintRenderer();
    final raw = locale == GoldAccessibleLocale.en
        ? ah.renderEn(move)
        : ah.renderFr(move);
    return raw ?? l.labAutomaticExplanation;
  }

  /// Renders exactly one notation — pictograms OR numpad OR classic 2d
  /// OR accessible sentence. No secondary echo below the main line
  /// (mission §6).
  Widget _inputSection(BuildContext context, AppLocalizations l) {
    switch (notation) {
      case GoldNotation.pictograms:
        return GoldCommandView(move: move, buttons: buttons, locale: locale);
      case GoldNotation.numpad:
        final t = NumpadRenderer().render(move);
        return _textBlock(
          t == null || t.isEmpty ? '—' : t,
          _accessibleSentence(),
        );
      case GoldNotation.classic2d:
        final t = Classic2dRenderer().render(move);
        return _textBlock(
          t == null || t.isEmpty ? '—' : t,
          _accessibleSentence(),
        );
      case GoldNotation.accessible:
        final t = _accessibleSentence();
        return _textBlock(t.isEmpty ? '—' : t, t, monospace: false);
    }
  }

  String _accessibleSentence() {
    return (locale == GoldAccessibleLocale.en
            ? AccessibleEnRenderer().render(move)
            : AccessibleFrRenderer().render(move)) ??
        '';
  }

  Widget _textBlock(String text, String semantic, {bool monospace = true}) {
    return Semantics(
      container: true,
      label: semantic.isEmpty ? move.name : semantic,
      excludeSemantics: true,
      child: SelectableText(
        text,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontFamily: monospace ? 'monospace' : null,
          fontFeatures: monospace ? const [FontFeature.tabularFigures()] : null,
        ),
      ),
    );
  }

  /// Comfortable-only: shows top-level requirements if the expression
  /// is contextual, so the constraint is visible even before the user
  /// scans the pictograms.
  Widget _contextRequirements(AppLocalizations l) {
    if (move.inputExpressions.isEmpty) return const SizedBox.shrink();
    final expr = move.inputExpressions.first.expression;
    if (expr is! ContextualExpr) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${l.labMoveRequirementLabel}:',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          for (final r in expr.requirements)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.5),
                  width: 0.6,
                ),
              ),
              child: Text(
                localizeRequirement(l, r),
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
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

  Widget _technicalDetails(BuildContext context, AppLocalizations l) {
    final followUps = move.followUps.map((f) => f.moveId).join(', ');
    final source = move.sourceRaw ?? '';
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 6),
        title: Text(
          l.labTechnicalDetails,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        children: [
          _kvRow(
            l.labMoveRawSource,
            source,
            copyable: true,
            context: context,
            l: l,
          ),
          if (followUps.isNotEmpty) _kvRow('Follow-ups', followUps),
        ],
      ),
    );
  }

  Widget _kvRow(
    String key,
    String value, {
    bool copyable = false,
    BuildContext? context,
    AppLocalizations? l,
  }) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              key,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.9),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
    if (!copyable || context == null || l == null) return row;
    return GestureDetector(
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.labDiagnosticsCopied)));
      },
      child: row,
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

class _CategoryChip extends StatelessWidget {
  final Color color;
  final String label;
  const _CategoryChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.6), width: 0.6),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    ),
  );
}

/// Textual badge that does not rely on color alone (WCAG 1.4.1).
class _AutoBadge extends StatelessWidget {
  final String label;
  final bool dense;
  const _AutoBadge({required this.label, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 4 : 6,
        vertical: dense ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.secondary, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.autorenew,
            size: dense ? 9 : 10,
            color: AppColors.secondary,
          ),
          SizedBox(width: dense ? 2 : 3),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: dense ? 8 : 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compatibility name retained for the validation UI while the renderer is
/// now also used by the production move-list screen.
typedef LabMoveCard = GoldProfileMoveCard;
