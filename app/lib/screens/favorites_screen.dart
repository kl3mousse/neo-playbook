import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/game.dart';
import '../models/user_favorite.dart';
import '../models/fave_move_list.dart';
import '../services/user_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/game_card.dart';
import 'character_moves_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final Set<FavoriteStatus> _activeFilters = Set.of(FavoriteStatus.values);

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Favorites',
            style: TextStyle(fontFamily: 'Doto', fontWeight: FontWeight.w800),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, size: 64),
              SizedBox(height: 16),
              Text('Sign in to track your favorite games'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorites',
          style: TextStyle(fontFamily: 'Doto', fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<UserFavorite>>(
        stream: UserService.favoritesStream(),
        builder: (context, favSnap) {
          if (!favSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = favSnap.data!;

          if (favorites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 64),
                  SizedBox(height: 16),
                  Text('No favorite games yet'),
                  SizedBox(height: 8),
                  Text(
                    'Add games to your favorites from\nany game detail page',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<List<Game>>(
            stream: FirestoreService.gamesStream(),
            builder: (context, gamesSnap) {
              if (!gamesSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allGames = {for (final g in gamesSnap.data!) g.id: g};
              final statusByGameId = {
                for (final f in favorites) f.gameId: f.status
              };

              final filtered = favorites
                  .where((f) => _activeFilters.contains(f.status))
                  .toList();

              final games = filtered
                  .map((f) => allGames[f.gameId])
                  .where((g) => g != null)
                  .cast<Game>()
                  .toList()
                ..sort((a, b) => a.title.compareTo(b.title));

              // Count per status for chip labels
              final counts = {
                for (final s in FavoriteStatus.values)
                  s: favorites.where((f) => f.status == s).length,
              };

              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 900
                      ? 4
                      : constraints.maxWidth > 600
                          ? 3
                          : 2;

                  return CustomScrollView(
                    slivers: [
                      // Filter chips
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: FavoriteStatus.values.map((status) {
                              final selected =
                                  _activeFilters.contains(status);
                              return FilterChip(
                                label: Text(
                                  '${status.icon} ${status.label} (${counts[status]})',
                                ),
                                selected: selected,
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
                                      _activeFilters.add(status);
                                    } else {
                                      // Don't allow deselecting all
                                      if (_activeFilters.length > 1) {
                                        _activeFilters.remove(status);
                                      }
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      // Summary count
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            '${games.length} game${games.length == 1 ? '' : 's'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
                      // Games grid (or empty filter state)
                      if (games.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('No games match the selected filters'),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => setState(() {
                                    _activeFilters
                                      ..clear()
                                      ..addAll(FavoriteStatus.values);
                                  }),
                                  child: const Text('Clear filters'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.all(12),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 1.1,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final game = games[index];
                                return GameCard(
                                  game: game,
                                  status: statusByGameId[game.id],
                                  onTap: () =>
                                      context.push('/game/${game.id}'),
                                );
                              },
                              childCount: games.length,
                            ),
                          ),
                        ),
                      // Move Lists section
                      const SliverToBoxAdapter(
                        child: _FaveMoveListsSection(),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ── Favorite Move Lists Section ──────────────────────────────────────────

class _FaveMoveListsSection extends StatelessWidget {
  const _FaveMoveListsSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FaveMoveList>>(
      stream: UserService.faveMovesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final faveMoves = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
          child: ExpansionTile(
            leading: const Text('🥊', style: TextStyle(fontSize: 20)),
            title: Text('Move Lists (${faveMoves.length})'),
            initiallyExpanded: false,
            children: faveMoves.map((fave) {
              return ListTile(
                leading: const Icon(Icons.sports_martial_arts),
                title: Text(fave.sectionTitle),
                subtitle: Text(
                  [
                    fave.gameTitle,
                    if (fave.sectionSubtitle != null &&
                        fave.sectionSubtitle!.isNotEmpty)
                      fave.sectionSubtitle!,
                  ].join(' · '),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.bookmark_remove, size: 20),
                  tooltip: 'Remove bookmark',
                  onPressed: () => UserService.removeFaveMove(fave.id),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CharacterMovesScreen(
                        romName: fave.romName,
                        sectionTitle: fave.sectionTitle,
                        gameId: fave.gameId,
                        gameTitle: fave.gameTitle,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
