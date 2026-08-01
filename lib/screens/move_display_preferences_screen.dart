import 'package:flutter/material.dart';

import '../experimental/gold_moves_profile_v1/presentation/gold_rendering_options.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/prefs_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

/// Persistent display choices for production Gold move lists.
class MoveDisplayPreferencesScreen extends StatefulWidget {
  const MoveDisplayPreferencesScreen({super.key});

  @override
  State<MoveDisplayPreferencesScreen> createState() =>
      _MoveDisplayPreferencesScreenState();
}

class _MoveDisplayPreferencesScreenState
    extends State<MoveDisplayPreferencesScreen> {
  late GoldNotation _notation;
  late GoldDensity _density;

  @override
  void initState() {
    super.initState();
    _notation = PrefsService.getGoldMoveNotation();
    _density = PrefsService.getGoldMoveDensity();
  }

  Future<void> _save({GoldNotation? notation, GoldDensity? density}) async {
    setState(() {
      if (notation != null) _notation = notation;
      if (density != null) _density = density;
    });
    await UserService.updateGoldMovePreferences(
      notation: _notation,
      density: _density,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.goldDisplayPreferences)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(l.goldNotation, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          RadioGroup<GoldNotation>(
            groupValue: _notation,
            onChanged: (selected) {
              if (selected != null) _save(notation: selected);
            },
            child: Column(
              children: [
                _notationChoice(
                  GoldNotation.pictograms,
                  l.goldPictograms,
                  l.goldNotationPictogramsHelp,
                  example: '↓  ↘  →  +  P',
                ),
                _notationChoice(
                  GoldNotation.numpad,
                  l.goldNumpad,
                  l.goldNotationNumpadHelp,
                  example: '236 P',
                ),
                _notationChoice(
                  GoldNotation.classic2d,
                  l.goldClassic2d,
                  l.goldNotationClassicHelp,
                  example: 'QCF + P',
                ),
                _notationChoice(
                  GoldNotation.accessible,
                  l.goldAccessible,
                  l.goldNotationAccessibleHelp,
                  example: l.goldAccessibleExample,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(l.goldDensity, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          RadioGroup<GoldDensity>(
            groupValue: _density,
            onChanged: (selected) {
              if (selected != null) _save(density: selected);
            },
            child: Column(
              children: [
                _densityChoice(
                  GoldDensity.compact,
                  l.goldCompact,
                  l.goldCompactHelp,
                ),
                _densityChoice(
                  GoldDensity.comfortable,
                  l.goldComfortable,
                  l.goldComfortableHelp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notationChoice(
    GoldNotation value,
    String label,
    String explanation, {
    required String example,
  }) => Column(
    children: [
      RadioListTile(value: value, title: Text(label)),
      if (_notation == value)
        _OptionExplanation(example: example, text: explanation),
    ],
  );

  Widget _densityChoice(GoldDensity value, String label, String explanation) =>
      Column(
        children: [
          RadioListTile(value: value, title: Text(label)),
          if (_density == value) _OptionExplanation(text: explanation),
        ],
      );
}

class _OptionExplanation extends StatelessWidget {
  final String text;
  final String? example;

  const _OptionExplanation({required this.text, this.example});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.32)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (example != null) ...[
              const SizedBox(height: 2),
              Text(example!, style: const TextStyle(fontFamily: 'monospace')),
            ],
            const SizedBox(height: 6),
            Text(text),
          ],
        ),
      ),
    ),
  );
}
