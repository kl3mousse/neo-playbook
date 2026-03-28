import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/game_card.dart';
import 'game_detail_screen.dart';

class GamesListScreen extends StatefulWidget {
  const GamesListScreen({super.key});

  @override
  State<GamesListScreen> createState() => _GamesListScreenState();
}

class _GamesListScreenState extends State<GamesListScreen> {
  String _searchQuery = '';
  String? _selectedGenre;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Otaku Playbook'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search games...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          // Games list
          Expanded(
            child: StreamBuilder<List<Game>>(
              stream: _searchQuery.isEmpty
                  ? FirestoreService.gamesStream()
                  : FirestoreService.searchGames(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var games = snapshot.data!;

                // Optional genre filter
                if (_selectedGenre != null) {
                  games = games
                      .where((g) => g.genre == _selectedGenre)
                      .toList();
                }

                if (games.isEmpty) {
                  return const Center(child: Text('No games found'));
                }

                // Genre chips
                final genres = snapshot.data!
                    .map((g) => g.genre)
                    .where((g) => g.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();

                return Column(
                  children: [
                    // Genre filter chips
                    if (genres.isNotEmpty)
                      SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: const Text('All'),
                                selected: _selectedGenre == null,
                                onSelected: (_) =>
                                    setState(() => _selectedGenre = null),
                              ),
                            ),
                            ...genres.map(
                              (genre) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(genre),
                                  selected: _selectedGenre == genre,
                                  onSelected: (_) => setState(
                                    () => _selectedGenre =
                                        _selectedGenre == genre ? null : genre,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Games grid
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount =
                              constraints.maxWidth > 900
                                  ? 4
                                  : constraints.maxWidth > 600
                                      ? 3
                                      : 2;
                          return GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: games.length,
                            itemBuilder: (context, index) {
                              final game = games[index];
                              return GameCard(
                                game: game,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        GameDetailScreen(game: game),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
