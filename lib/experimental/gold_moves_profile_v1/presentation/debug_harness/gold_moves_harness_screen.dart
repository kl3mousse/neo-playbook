import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_theme.dart';
import '../../gold_moves_profile.dart';
import '../gold_move_card.dart';
import '../gold_provenance_view.dart';
import '../lab/gold_move_lab_screen.dart';
import 'debug_fixtures.dart';

/// Route path for the debug-only Gold Move Lab. Kept identical to the
/// former harness route path so bookmarks and Settings entries do not
/// break. See [buildGoldHarnessRoutes].
const String kGoldHarnessRoute = '/debug/gold-moves-profile-v1';

/// Returns the [GoRoute] list for the debug lab. In release builds
/// (`!kDebugMode`) the list is empty, so the screen is unreachable.
///
/// Since v2 the route resolves to [GoldMoveLabScreen], the full
/// visual demonstration lab. The legacy [GoldMovesHarnessScreen] is
/// preserved below only for reference; it is no longer wired to any
/// route.
List<GoRoute> buildGoldHarnessRoutes() {
  if (!kDebugMode) return const [];
  return <GoRoute>[
    GoRoute(
      path: kGoldHarnessRoute,
      builder: (_, _) => const GoldMoveLabScreen(),
    ),
  ];
}

/// Screen: presents the experimental Gold Moves widgets over the three
/// bundled fixtures (both bundle examples plus a curated KOF R-2 slice).
class GoldMovesHarnessScreen extends StatefulWidget {
  const GoldMovesHarnessScreen({super.key});

  @override
  State<GoldMovesHarnessScreen> createState() => _GoldMovesHarnessScreenState();
}

class _GoldMovesHarnessScreenState extends State<GoldMovesHarnessScreen> {
  final _parser = ProfileParser();
  NotationDisplay _notation = NotationDisplay.numpad;
  GoldLocale _locale = GoldLocale.en;

  late final ProfileGold _minimal;
  late final ProfileGold _activationExample;
  late final ProfileGold _showcase;
  Object? _parseError;

  @override
  void initState() {
    super.initState();
    try {
      _minimal = _parser.parseString(minimalProfileJson);
      _activationExample = _parser.parseString(activationAutomaticProfileJson);
      _showcase = _parser.parseString(kofR2ShowcaseProfileJson);
    } catch (e) {
      _parseError = e;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(body: SizedBox.shrink());
    }
    if (_parseError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gold Moves Harness — ERROR')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('$_parseError'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gold Moves Profile v1.0.0 — Debug'),
        actions: [
          PopupMenuButton<NotationDisplay>(
            icon: const Icon(Icons.numbers),
            tooltip: 'Notation',
            onSelected: (v) => setState(() => _notation = v),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: NotationDisplay.numpad,
                child: Text('Numpad (236 A)'),
              ),
              PopupMenuItem(
                value: NotationDisplay.classic2d,
                child: Text('Classic 2D (QCF + A)'),
              ),
            ],
          ),
          PopupMenuButton<GoldLocale>(
            icon: const Icon(Icons.language),
            tooltip: 'Accessible language',
            onSelected: (v) => setState(() => _locale = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: GoldLocale.en, child: Text('English')),
              PopupMenuItem(value: GoldLocale.fr, child: Text('Français')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _sectionTitle('KOF R-2 — showcase (5 real moves)'),
          ..._buildMoveCards(_showcase),
          const SizedBox(height: 8),
          GoldProvenanceView(attribution: _showcase.attribution),
          const SizedBox(height: 16),
          _sectionTitle('Example: minimal.profile.json'),
          ..._buildMoveCards(_minimal),
          const SizedBox(height: 16),
          _sectionTitle('Example: activation-automatic.profile.json'),
          ..._buildMoveCards(_activationExample),
          const SizedBox(height: 16),
          _sectionTitle('Counts'),
          _countsPanel(_showcase),
        ],
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  List<Widget> _buildMoveCards(ProfileGold profile) {
    return [
      for (final m in profile.moves)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: GoldMoveCard(
            move: m,
            character: m.characterId == null
                ? null
                : profile.character(m.characterId!),
            buttons: profile.buttons,
            notation: _notation,
            locale: _locale,
          ),
        ),
    ];
  }

  Widget _countsPanel(ProfileGold profile) {
    final playerInput = profile.moves
        .where((m) => m.activation.kind == ActivationKind.byPlayerInput)
        .length;
    final auto = profile.moves
        .where((m) => m.activation.kind == ActivationKind.automaticAfterMove)
        .length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        'moves: ${profile.moves.length}  |  '
        'characters: ${profile.characters.length}  |  '
        'by_player_input: $playerInput  |  '
        'automatic_after_move: $auto',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
    );
  }
}
