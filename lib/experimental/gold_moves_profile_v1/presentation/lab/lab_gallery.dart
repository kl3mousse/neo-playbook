import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/annotation.dart';
import '../../domain/button.dart';
import '../../domain/character.dart';
import '../../domain/expression.dart';
import '../../domain/move.dart';
import '../../domain/parse_status.dart';
import '../../rendering/renderers/accessible_en_renderer.dart';
import '../../rendering/renderers/accessible_fr_renderer.dart';
import '../../rendering/renderers/classic_2d_renderer.dart';
import '../../rendering/renderers/numpad_renderer.dart';
import 'gold_command_view.dart';
import 'lab_controller.dart';
import 'lab_move_card.dart';

/// Synthetic profile used only inside the Lab gallery. Never surfaced
/// as "real" KOF R-2 data (each card carries a synthetic banner).
class _GalleryFixtures {
  static const CharacterSpec _char = CharacterSpec(
    id: 'demo-character',
    name: 'Demo Character',
  );

  static final ButtonCatalog buttons = ButtonCatalog(
    buttons: const [
      ButtonSpec(symbol: 'A', label: 'Weak Punch'),
      ButtonSpec(symbol: 'B', label: 'Weak Kick'),
      ButtonSpec(symbol: 'C', label: 'Strong Punch'),
      ButtonSpec(symbol: 'D', label: 'Strong Kick'),
    ],
    groups: const [
      ButtonGroupSpec(symbol: 'P', label: 'Any Punch', members: ['A', 'C']),
      ButtonGroupSpec(symbol: 'K', label: 'Any Kick', members: ['B', 'D']),
    ],
  );

  static MoveGold _mk(
    String id,
    String name,
    Expression? expr, {
    Activation? activation,
    List<Annotation> annotations = const [],
    String? sourceRaw,
    MoveCategory category = MoveCategory.special,
  }) {
    return MoveGold(
      id: id,
      name: name,
      rawCategory: category.wire,
      category: category,
      characterId: _char.id,
      activation:
          activation ??
          const Activation(
            kind: ActivationKind.byPlayerInput,
            rawKind: 'by_player_input',
          ),
      inputExpressions: expr == null
          ? const []
          : [
              InputExpressionWrapper(
                parseStatus: ParseStatus.parsed,
                expression: expr,
                sourceRaw: sourceRaw,
              ),
            ],
      annotations: annotations,
      sourceRaw: sourceRaw,
    );
  }

  static CharacterSpec get character => _char;
}

class GallerySample {
  final String caseLabelKey;
  final MoveGold move;
  const GallerySample({required this.caseLabelKey, required this.move});
}

List<GallerySample> buildGallerySamples() {
  final simple = _GalleryFixtures._mk(
    'gallery-simple',
    'Simple Poke',
    SequenceExpr(const [
      DirectionExpr(GoldDirection.forward, relative: true),
      ButtonExpr('A'),
    ]),
    sourceRaw: 'f + A',
    category: MoveCategory.commandNormal,
  );

  final qcf = _GalleryFixtures._mk(
    'gallery-qcf',
    'Fireball',
    SequenceExpr(const [
      MotionExpr(MotionShape.quarterCircleForward),
      ButtonExpr('A'),
    ]),
    sourceRaw: 'qcf + A',
  );

  final dp = _GalleryFixtures._mk(
    'gallery-dp',
    'Uppercut',
    SequenceExpr(const [
      MotionExpr(MotionShape.dragonPunchForward),
      ButtonExpr('C'),
    ]),
    sourceRaw: 'dp + C',
  );

  final charge = _GalleryFixtures._mk(
    'gallery-charge',
    'Sonic Boom',
    ChargeExpr(
      chargeDirection: ChargeDirection.back,
      then: SequenceExpr(const [
        DirectionExpr(GoldDirection.forward, relative: true),
        ButtonExpr('P'),
      ]),
    ),
    sourceRaw: 'charge b, f + P',
  );

  final long = _GalleryFixtures._mk(
    'gallery-long',
    'Long Command',
    SequenceExpr(const [
      MotionExpr(MotionShape.quarterCircleForward),
      MotionExpr(MotionShape.quarterCircleForward),
      ButtonExpr('C'),
      ButtonExpr('D'),
    ]),
    sourceRaw: 'qcf, qcf + CD',
    category: MoveCategory.superMove,
  );

  final simul = _GalleryFixtures._mk(
    'gallery-simul',
    'Roll',
    SimultaneousExpr(const [ButtonExpr('A'), ButtonExpr('B')]),
    sourceRaw: 'A + B',
    category: MoveCategory.movement,
  );

  final hold = _GalleryFixtures._mk(
    'gallery-hold',
    'Hold Button',
    const HoldExpr(input: ButtonExpr('P')),
    sourceRaw: '(hold) P',
  );

  final release = _GalleryFixtures._mk(
    'gallery-release',
    'Release Button',
    const ReleaseExpr(input: ButtonExpr('P')),
    sourceRaw: 'release P',
  );

  final alt = _GalleryFixtures._mk(
    'gallery-alt',
    'Alternative Input',
    AlternativeExpr(const [ButtonExpr('A'), ButtonExpr('B')]),
    sourceRaw: 'A or B',
  );

  final ctx = _GalleryFixtures._mk(
    'gallery-ctx',
    'Contextual Throw',
    ContextualExpr(
      requirements: const [
        Requirement(
          kind: RequirementKind.spatial,
          rawKind: 'spatial',
          value: 'near_opponent',
        ),
      ],
      input: SequenceExpr(const [
        DirectionExpr(GoldDirection.forward, relative: true),
        ButtonExpr('C'),
      ]),
    ),
    sourceRaw: '(close) f + C',
    category: MoveCategory.throwMove,
  );

  final req = _GalleryFixtures._mk(
    'gallery-req',
    'Requirement Example',
    const ContextualExpr(
      requirements: [
        Requirement(
          kind: RequirementKind.state,
          rawKind: 'state',
          value: 'on_ground',
        ),
      ],
      input: ButtonExpr('D'),
    ),
    sourceRaw: '(on ground) D',
  );

  final ann = _GalleryFixtures._mk(
    'gallery-ann',
    'Annotated Move',
    SequenceExpr(const [
      MotionExpr(MotionShape.quarterCircleBack),
      ButtonExpr('B'),
    ]),
    annotations: const [
      Annotation(
        kind: AnnotationKind.damageModifier,
        rawKind: 'damage_modifier',
        value: 120,
      ),
      Annotation(
        kind: AnnotationKind.custom,
        rawKind: 'startup_frames',
        value: 8,
      ),
    ],
    sourceRaw: 'qcb + B',
  );

  final auto = _GalleryFixtures._mk(
    'gallery-auto',
    'Auto Follow-up',
    null,
    activation: const Activation(
      kind: ActivationKind.automaticAfterMove,
      rawKind: 'automatic_after_move',
      trigger: ActivationTrigger(
        kind: TriggerKind.onMidHit,
        rawKind: 'on_mid_hit',
        parentMoveId: 'gallery-qcf',
        description: '(Mid Hit — automatic)',
      ),
      description: '(Mid Hit — automatic)',
    ),
    sourceRaw: '(Mid Hit — automatic)',
  );

  final fallback = MoveGold(
    id: 'gallery-fallback',
    name: 'Fallback Command',
    rawCategory: 'special',
    category: MoveCategory.special,
    characterId: _GalleryFixtures._char.id,
    activation: const Activation(
      kind: ActivationKind.byPlayerInput,
      rawKind: 'by_player_input',
    ),
    inputExpressions: const [
      InputExpressionWrapper(
        parseStatus: ParseStatus.unparsed,
        sourceRaw: 'BC ~ 236B (undocumented)',
      ),
    ],
    sourceRaw: 'BC ~ 236B (undocumented)',
  );

  final unknown = _GalleryFixtures._mk(
    'gallery-unknown',
    'Unknown Kind',
    const UnknownExpression(
      rawKind: 'future_kind_42',
      rawJson: {'kind': 'future_kind_42', 'foo': 'bar'},
    ),
    sourceRaw: '<future 1.1 syntax>',
  );

  return [
    GallerySample(caseLabelKey: 'labCaseSimpleCommand', move: simple),
    GallerySample(caseLabelKey: 'labCaseQuarterCircle', move: qcf),
    GallerySample(caseLabelKey: 'labCaseDragonPunch', move: dp),
    GallerySample(caseLabelKey: 'labCaseCharge', move: charge),
    GallerySample(caseLabelKey: 'labCaseSequence', move: long),
    GallerySample(caseLabelKey: 'labCaseSimultaneous', move: simul),
    GallerySample(caseLabelKey: 'labCaseHold', move: hold),
    GallerySample(caseLabelKey: 'labCaseRelease', move: release),
    GallerySample(caseLabelKey: 'labCaseAlternative', move: alt),
    GallerySample(caseLabelKey: 'labCaseContextual', move: ctx),
    GallerySample(caseLabelKey: 'labCaseRequirement', move: req),
    GallerySample(caseLabelKey: 'labCaseAnnotation', move: ann),
    GallerySample(caseLabelKey: 'labCaseLongCommand', move: long),
    GallerySample(caseLabelKey: 'labCaseAutomatic', move: auto),
    GallerySample(caseLabelKey: 'labCaseFallback', move: fallback),
    GallerySample(caseLabelKey: 'labCaseUnknown', move: unknown),
  ];
}

String labelFor(AppLocalizations l, String key) {
  return switch (key) {
    'labCaseSimpleCommand' => l.labCaseSimpleCommand,
    'labCaseQuarterCircle' => l.labCaseQuarterCircle,
    'labCaseDragonPunch' => l.labCaseDragonPunch,
    'labCaseCharge' => l.labCaseCharge,
    'labCaseSequence' => l.labCaseSequence,
    'labCaseSimultaneous' => l.labCaseSimultaneous,
    'labCaseHold' => l.labCaseHold,
    'labCaseRelease' => l.labCaseRelease,
    'labCaseAlternative' => l.labCaseAlternative,
    'labCaseContextual' => l.labCaseContextual,
    'labCaseRequirement' => l.labCaseRequirement,
    'labCaseAnnotation' => l.labCaseAnnotation,
    'labCaseLongCommand' => l.labCaseLongCommand,
    'labCaseAutomatic' => l.labCaseAutomatic,
    'labCaseFallback' => l.labCaseFallback,
    'labCaseUnknown' => l.labCaseUnknown,
    _ => key,
  };
}

class LabGalleryView extends StatelessWidget {
  final LabController controller;
  const LabGalleryView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final samples = buildGallerySamples();
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LabComparisonSection(controller: controller),
          const SizedBox(height: 16),
          _LabVisualReviewSection(controller: controller),
          const SizedBox(height: 16),
          Text(
            l.labGalleryTitle,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.labGallerySubtitle,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          for (final s in samples)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GallerySampleTile(
                sample: s,
                controller: controller,
                caseLabel: labelFor(l, s.caseLabelKey),
                syntheticBadge: l.labGallerySynthetic,
              ),
            ),
        ],
      ),
    );
  }
}

class _GallerySampleTile extends StatefulWidget {
  final GallerySample sample;
  final LabController controller;
  final String caseLabel;
  final String syntheticBadge;
  const _GallerySampleTile({
    required this.sample,
    required this.controller,
    required this.caseLabel,
    required this.syntheticBadge,
  });

  @override
  State<_GallerySampleTile> createState() => _GallerySampleTileState();
}

class _GallerySampleTileState extends State<_GallerySampleTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.caseLabel,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.accent),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.syntheticBadge.toUpperCase(),
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LabMoveCard(
          move: widget.sample.move,
          character: _GalleryFixtures.character,
          buttons: _GalleryFixtures.buttons,
          notation: widget.controller.notation,
          locale: widget.controller.accessibleLocale,
          density: widget.controller.density,
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            size: 16,
          ),
          label: Text(
            _expanded ? l.labGalleryHideTokens : l.labGalleryShowTokens,
          ),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        if (_expanded) _tokensPreview(),
      ],
    );
  }

  Widget _tokensPreview() {
    final expr = widget.sample.move.inputExpressions.isEmpty
        ? null
        : widget.sample.move.inputExpressions.first.expression;
    final exprLabel = expr == null
        ? '(no expression — automatic activation only)'
        : expr.runtimeType.toString();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      child: SelectableText(
        'expression: $exprLabel\n'
        'source_raw: ${widget.sample.move.sourceRaw ?? '—'}\n'
        'activation: ${widget.sample.move.activation.rawKind}',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Comparison section: shows the same move in all four notations
// side-by-side (or stacked on narrow screens). Lets a reviewer read
// the four modes at a glance without twiddling the settings sheet.
// ─────────────────────────────────────────────────────────────────

/// Curated cases selected to exercise every notation edge (motion,
/// simultaneous press, charge, alternative, sequence, automatic).
List<GallerySample> _comparisonCases() {
  final samples = buildGallerySamples();
  const wanted = {
    'labCaseSimpleCommand',
    'labCaseQuarterCircle',
    'labCaseCharge',
    'labCaseAlternative',
    'labCaseLongCommand',
    'labCaseAutomatic',
  };
  return [
    for (final s in samples)
      if (wanted.contains(s.caseLabelKey)) s,
  ];
}

class _LabComparisonSection extends StatelessWidget {
  final LabController controller;
  const _LabComparisonSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cases = _comparisonCases();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.labComparisonTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.labComparisonSubtitle,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        for (final c in cases) ...[
          _ComparisonRow(
            controller: controller,
            sample: c,
            caseLabel: labelFor(l, c.caseLabelKey),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final LabController controller;
  final GallerySample sample;
  final String caseLabel;
  const _ComparisonRow({
    required this.controller,
    required this.sample,
    required this.caseLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final move = sample.move;
    final accessible =
        (controller.accessibleLocale == LabAccessibleLocale.en
            ? AccessibleEnRenderer().render(move)
            : AccessibleFrRenderer().render(move)) ??
        '';
    final numpad = NumpadRenderer().render(move) ?? '—';
    final classic = Classic2dRenderer().render(move) ?? '—';

    Widget cell(String header, Widget body) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              header,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            body,
          ],
        ),
      );
    }

    final cells = <_Cell>[
      _Cell(
        header: l.labComparisonCasePictograms,
        body: GoldCommandView(
          move: move,
          buttons: _GalleryFixtures.buttons,
          locale: controller.accessibleLocale,
        ),
      ),
      _Cell(
        header: l.labComparisonCaseNumpad,
        body: _plainText(numpad, monospace: true),
      ),
      _Cell(
        header: l.labComparisonCaseClassic,
        body: _plainText(classic, monospace: true),
      ),
      _Cell(
        header: l.labComparisonCaseAccessible,
        body: _plainText(accessible.isEmpty ? '—' : accessible),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caseLabel,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            // 4 columns on ≥720 (side-by-side comparison), 2 columns
            // on medium widths, single column on narrow phones so
            // nothing overflows even at 200% text scale.
            final w = constraints.maxWidth;
            final cols = w >= 720 ? 4 : (w >= 420 ? 2 : 1);
            return _Grid(
              cellCount: cells.length,
              columns: cols,
              spacing: 8,
              children: [for (final c in cells) cell(c.header, c.body)],
            );
          },
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${l.labComparisonCaseSemantic}: ${accessible.isEmpty ? '—' : accessible}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _plainText(String text, {bool monospace = false}) => Text(
    text,
    style: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 13,
      fontFamily: monospace ? 'monospace' : null,
      fontFeatures: monospace ? const [FontFeature.tabularFigures()] : null,
      height: 1.2,
    ),
  );
}

class _Cell {
  final String header;
  final Widget body;
  const _Cell({required this.header, required this.body});
}

/// Minimal fixed-column grid: each row has [columns] cells with
/// equal-width [Expanded] children. Simpler than [GridView] because
/// we need dynamic cell content height (a numpad string is short,
/// a pictogram row can wrap).
class _Grid extends StatelessWidget {
  final int cellCount;
  final int columns;
  final double spacing;
  final List<Widget> children;
  const _Grid({
    required this.cellCount,
    required this.columns,
    required this.spacing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < cellCount; i += columns) {
      final rowChildren = <Widget>[];
      for (var j = 0; j < columns; j++) {
        final idx = i + j;
        if (j > 0) rowChildren.add(SizedBox(width: spacing));
        if (idx < cellCount) {
          rowChildren.add(Expanded(child: children[idx]));
        } else {
          rowChildren.add(const Expanded(child: SizedBox.shrink()));
        }
      }
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rowChildren,
          ),
        ),
      );
      if (i + columns < cellCount) rows.add(SizedBox(height: spacing));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Visual review section: fixed list of hard cases so a reviewer can
// eyeball the renderer under the current notation / theme / density
// / language / text-scale settings (mission §17).
// ─────────────────────────────────────────────────────────────────

class _LabVisualReviewSection extends StatelessWidget {
  final LabController controller;
  const _LabVisualReviewSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Curated subset of hard cases — longer than the comparison list,
    // and using the *live* notation so the reviewer can iterate.
    final samples = buildGallerySamples();
    const wanted = {
      'labCaseCharge',
      'labCaseSimultaneous',
      'labCaseAlternative',
      'labCaseContextual',
      'labCaseLongCommand',
      'labCaseAnnotation',
      'labCaseAutomatic',
      'labCaseFallback',
      'labCaseUnknown',
    };
    final picks = [
      for (final s in samples)
        if (wanted.contains(s.caseLabelKey)) s,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.labVisualReviewTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.labVisualReviewSubtitle,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        for (final s in picks) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labelFor(l, s.caseLabelKey),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                LabMoveCard(
                  move: s.move,
                  character: _GalleryFixtures.character,
                  buttons: _GalleryFixtures.buttons,
                  notation: controller.notation,
                  locale: controller.accessibleLocale,
                  density: controller.density,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
