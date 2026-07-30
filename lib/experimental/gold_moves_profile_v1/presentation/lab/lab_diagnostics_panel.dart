import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/move.dart';
import '../../domain/profile.dart';
import '../../rendering/render_tokens.dart';
import '../../rendering/renderers/icon_tokens_renderer.dart';
import 'lab_controller.dart';

const String kLabRendererVersion = 'gold_moves_profile_v1 renderer 1.0.0';

/// Read-only diagnostics panel meant only for debug mode. Never
/// displays credentials, Firebase config or secret material.
class LabDiagnosticsPanel extends StatelessWidget {
  final LabController controller;
  const LabDiagnosticsPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final p = controller.profile;
        final selectedChar = controller.selectedCharacterId == null
            ? null
            : p.character(controller.selectedCharacterId!);
        final selectedMove = controller.selectedMoveId == null
            ? null
            : p.move(controller.selectedMoveId!);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _row(l.labDiagnosticsProfileVersion, p.goldSchemaVersion),
            _row(l.labDiagnosticsRendererVersion, kLabRendererVersion),
            _row(l.labDiagnosticsCharactersCount, '${p.characters.length}'),
            _row(l.labDiagnosticsMovesCount, '${p.moves.length}'),
            _row(l.labDiagnosticsNotationFrame, p.appliesTo.rawNotationFrame),
            const SizedBox(height: 8),
            Text(
              l.labDiagnosticsByActivation.toUpperCase(),
              style: _labelStyle(),
            ),
            const SizedBox(height: 4),
            _activationBreakdown(p),
            const SizedBox(height: 12),
            if (selectedChar != null)
              _row(
                l.labDiagnosticsSelectedCharacter,
                '${selectedChar.name}  ·  ${selectedChar.id}',
              ),
            if (selectedMove != null) ...[
              _row(
                l.labDiagnosticsSelectedMove,
                '${selectedMove.name}  ·  ${selectedMove.id}',
              ),
              _row(l.labDiagnosticsSourceRaw, selectedMove.sourceRaw ?? '—'),
              _row(
                l.labDiagnosticsParseStatus,
                selectedMove.inputExpressions.isEmpty
                    ? '—'
                    : selectedMove.inputExpressions.first.parseStatus.name,
              ),
              if (selectedMove.followUps.isNotEmpty)
                _row(
                  l.labDiagnosticsRelatedMoves,
                  selectedMove.followUps.map((f) => f.moveId).join(', '),
                ),
              const SizedBox(height: 8),
              _tokensBlock(context, l, selectedMove),
            ],
          ],
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _labelStyle()),
          SelectableText(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _activationBreakdown(ProfileGold p) {
    final counts = <String, int>{};
    for (final m in p.moves) {
      counts[m.activation.rawKind] = (counts[m.activation.rawKind] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final e in entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '${e.key}: ${e.value}',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
      ],
    );
  }

  Widget _tokensBlock(BuildContext context, AppLocalizations l, MoveGold move) {
    final tokens = IconTokensRenderer().tokens(move);
    final json = tokens.map((t) => t.toJson()).toList();
    final encoded = const JsonEncoder.withIndent('  ').convert(json);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l.labDiagnosticsTokens.toUpperCase(), style: _labelStyle()),
            const Spacer(),
            IconButton(
              tooltip: l.labDiagnosticsCopy,
              iconSize: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: encoded));
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l.labDiagnosticsCopied)));
              },
              icon: const Icon(Icons.copy),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
          ),
          child: SelectableText(
            encoded,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _labelStyle() => TextStyle(
    color: AppColors.textSecondary,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
  );
}

/// Returns render tokens for a move via [buildRenderTokens]. Used by
/// unit tests that need the same IR the diagnostics panel would show.
List<RenderToken> tokensForMove(MoveGold move) {
  if (move.inputExpressions.isEmpty) return const [];
  final expr = move.inputExpressions.first.expression;
  if (expr == null) return const [];
  return buildRenderTokens(expr);
}
