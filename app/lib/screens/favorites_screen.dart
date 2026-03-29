import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/user_favorite.dart';
import '../services/user_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/game_card.dart';
import 'game_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

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

    return DefaultTabController(
      length: FavoriteStatus.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Favorites',
            style: TextStyle(fontFamily: 'Doto', fontWeight: FontWeight.w800),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabs: FavoriteStatus.values
                .map((s) => Tab(text: '${s.icon} ${s.label}'))
                .toList(),
          ),
        ),
        body: StreamBuilder<List<UserFavorite>>(
          stream: UserService.favoritesStream(),
          builder: (context, favSnap) {
            if (!favSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final favorites = favSnap.data!;

            return StreamBuilder<List<Game>>(
              stream: FirestoreService.gamesStream(),
              builder: (context, gamesSnap) {
                if (!gamesSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allGames = {for (final g in gamesSnap.data!) g.id: g};

                return TabBarView(
                  children: FavoriteStatus.values.map((status) {
                    final favs = favorites
                        .where((f) => f.status == status)
                        .toList();

                    if (favs.isEmpty) {
                      return Center(
                        child: Text('No ${status.label.toLowerCase()} games'),
                      );
                    }

                    final games = favs
                        .map((f) => allGames[f.gameId])
                        .where((g) => g != null)
                        .cast<Game>()
                        .toList();

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 900
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
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
