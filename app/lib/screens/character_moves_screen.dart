import 'package:flutter/material.dart';
import '../models/move_list.dart';
import '../services/firestore_service.dart';
import '../widgets/move_list_widget.dart';
import 'game_detail_screen.dart';

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
            onPressed: () async {
              final game = await FirestoreService.getGame(gameId);
              if (game != null && context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameDetailScreen(game: game),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<CommandData?>(
        future: FirestoreService.getCommandData([romName]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final commandData = snapshot.data;
          if (commandData == null) {
            return const Center(
              child: Text('Move list not found'),
            );
          }

          final commonSections = commandData.sections
              .where((s) => s.sectionType != 'other')
              .toList();
          final targetSection = commandData.sections
              .where((s) =>
                  s.sectionType == 'other' && s.title == sectionTitle)
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
                for (final s in commonSections)
                  SectionBlock(section: s),

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
}
