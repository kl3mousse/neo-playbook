import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/move_list.dart';
import '../experimental/gold_moves_profile_v1/domain/profile.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/bundled_gold_profile_resolver.dart';
import '../services/firestore_service.dart';
import '../widgets/gold_move_list_view.dart';
import '../widgets/move_list_widget.dart';

/// Dedicated screen for viewing a single character's move list.
///
/// Navigated to from the bookmarked move lists in the Favorites tab.
/// Shows common sections (controls, how-to-play) collapsed, and the
/// target character section expanded.
class CharacterMovesScreen extends StatelessWidget {
  final String romName;
  final String sectionTitle;
  final String gameId;
  final String gameTitle;

  const CharacterMovesScreen({
    super.key,
    required this.romName,
    required this.sectionTitle,
    required this.gameId,
    required this.gameTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sectionTitle,
              style: const TextStyle(
                fontFamily: 'Doto',
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              gameTitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videogame_asset_outlined),
            tooltip: 'View full game',
            onPressed: () => context.pushReplacement('/game/$gameId'),
          ),
        ],
      ),
      body: _isGoldFavorite
          ? _GoldCharacterMovesBody(
              gameId: gameId,
              gameTitle: gameTitle,
              romName: romName,
              sectionTitle: sectionTitle,
            )
          : FutureBuilder<CommandData?>(
              future: FirestoreService.getCommandData([romName]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final commandData = snapshot.data;
                if (commandData == null) {
                  return const Center(child: Text('Move list not found'));
                }

                final commonSections = commandData.sections
                    .where((s) => s.sectionType != 'other')
                    .toList();
                final targetSection = commandData.sections
                    .where(
                      (s) =>
                          s.sectionType == 'other' && s.title == sectionTitle,
                    )
                    .toList();

                if (targetSection.isEmpty) {
                  return const Center(
                    child: Text('Character not found in move list'),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Common sections (collapsed)
                      for (final s in commonSections) SectionBlock(section: s),

                      const SizedBox(height: 8),

                      // Target character section (expanded)
                      SectionBlock(
                        section: targetSection.first,
                        gameId: gameId,
                        gameTitle: gameTitle,
                        romName: commandData.id,
                        initiallyExpanded: true,
                      ),

                      const SizedBox(height: 8),
                      const MoveLegend(),
                    ],
                  ),
                );
              },
            ),
    );
  }

  bool get _isGoldFavorite => const BundledGoldProfileResolver().supports(
    gameId: gameId,
    romIds: [romName],
  );
}

class _GoldCharacterMovesBody extends StatefulWidget {
  final String gameId;
  final String gameTitle;
  final String romName;
  final String sectionTitle;

  const _GoldCharacterMovesBody({
    required this.gameId,
    required this.gameTitle,
    required this.romName,
    required this.sectionTitle,
  });

  @override
  State<_GoldCharacterMovesBody> createState() =>
      _GoldCharacterMovesBodyState();
}

class _GoldCharacterMovesBodyState extends State<_GoldCharacterMovesBody> {
  static const _resolver = BundledGoldProfileResolver();
  late Future<ProfileGold?> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _load();
  }

  Future<ProfileGold?> _load() =>
      _resolver.resolve(gameId: widget.gameId, romIds: [widget.romName]);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<ProfileGold?>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.goldLoadError),
                TextButton(
                  onPressed: () => setState(() => _profile = _load()),
                  child: Text(l.goldRetry),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: GoldMoveListView(
            profile: snapshot.data!,
            gameId: widget.gameId,
            gameTitle: widget.gameTitle,
            onlyCharacterName: widget.sectionTitle,
          ),
        );
      },
    );
  }
}
