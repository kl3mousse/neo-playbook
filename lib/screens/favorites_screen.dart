import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/game.dart';
import '../models/user_favorite.dart';
import '../models/fave_move_list.dart';
import '../services/user_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/game_card.dart';
import '../widgets/info_fab.dart';
import '../widgets/sign_in_prompt.dart';
import 'character_moves_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  static const InfoFab _infoFab = InfoFab(
    foxxyAsset: 'assets/foxxy/sd/foxxy-sd-r2-c1.png',
    title: 'FAVORITES',
    paragraphs: [
      "Bookmark the games you love and I'll keep them right here for you!",
      "From any game's detail page, tap the heart to save a game — it'll land in the Games section below.",
      "You can also bookmark specific move lists from the character screens. They'll show up in their own section right below your games.",
    ],
  );

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
        floatingActionButton: _infoFab,
        body: const SignInPrompt(
          icon: Icons.favorite_border,
          message: 'Sign in to track your favorite games',
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
      floatingActionButton: _infoFab,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: const [
          _FaveGamesSection(),
          _FaveMoveListsSection(),
          SizedBox(height: 80), // room for the FAB
        ],
      ),
    );
  }
}

// ── Favorite Games Section ───────────────────────────────────────────────

class _FaveGamesSection extends StatelessWidget {
  const _FaveGamesSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserFavorite>>(
      stream: UserService.favoritesStream(),
      builder: (context, favSnap) {
        if (!favSnap.hasData) {
          return const _SectionShell(
            emoji: '❤️',
            title: 'Games',
            count: null,
            initiallyExpanded: true,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final favorites = favSnap.data!;

        if (favorites.isEmpty) {
          return const _SectionShell(
            emoji: '❤️',
            title: 'Games',
            count: 0,
            initiallyExpanded: true,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                children: [
                  Text('No favorite games yet'),
                  SizedBox(height: 6),
                  Text(
                    'Tap the heart on any game detail page to save it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return StreamBuilder<List<Game>>(
          stream: FirestoreService.gamesStream(),
          builder: (context, gamesSnap) {
            if (!gamesSnap.hasData) {
              return const _SectionShell(
                emoji: '❤️',
                title: 'Games',
                count: null,
                initiallyExpanded: true,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final allGames = {for (final g in gamesSnap.data!) g.id: g};
            final statusByGameId = {
              for (final f in favorites) f.gameId: f.status
            };

            final games = favorites
                .map((f) => allGames[f.gameId])
                .where((g) => g != null)
                .cast<Game>()
                .toList()
              ..sort((a, b) => a.title.compareTo(b.title));

            return _SectionShell(
              emoji: '❤️',
              title: 'Games',
              count: games.length,
              initiallyExpanded: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: games.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return GameCard(
                      game: game,
                      status: statusByGameId[game.id],
                      onTap: () => context.push('/game/${game.id}'),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
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
        if (!snapshot.hasData) {
          return const _SectionShell(
            emoji: '🥊',
            title: 'Move Lists',
            count: null,
            initiallyExpanded: true,
            child: SizedBox.shrink(),
          );
        }

        final faveMoves = snapshot.data!;

        if (faveMoves.isEmpty) {
          return const _SectionShell(
            emoji: '🥊',
            title: 'Move Lists',
            count: 0,
            initiallyExpanded: true,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                children: [
                  Text('No bookmarked move lists yet'),
                  SizedBox(height: 6),
                  Text(
                    'Bookmark a character or section from any move list to '
                    'find it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return _SectionShell(
          emoji: '🥊',
          title: 'Move Lists',
          count: faveMoves.length,
          initiallyExpanded: true,
          child: Column(
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

// ── Shared section shell (matching visual treatment) ─────────────────────

class _SectionShell extends StatelessWidget {
  final String emoji;
  final String title;
  final int? count;
  final bool initiallyExpanded;
  final Widget child;

  const _SectionShell({
    required this.emoji,
    required this.title,
    required this.count,
    required this.initiallyExpanded,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final countLabel = count == null ? '' : ' ($count)';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Theme(
          // Remove default ExpansionTile divider borders for a cleaner look.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            leading: Text(emoji, style: const TextStyle(fontSize: 20)),
            title: Text(
              '$title$countLabel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            childrenPadding: EdgeInsets.zero,
            children: [child],
          ),
        ),
      ),
    );
  }
}
