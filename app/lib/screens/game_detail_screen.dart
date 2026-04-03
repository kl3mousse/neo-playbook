import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/move_list.dart';
import '../models/dip_settings.dart';
import '../models/community_note.dart';
import '../models/game_score.dart';
import '../models/user_favorite.dart';
import '../models/collection_item.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/notes_service.dart';
import '../services/scores_service.dart';
import '../widgets/move_list_widget.dart';
import '../widgets/dip_settings_widget.dart';
import '../widgets/add_note_sheet.dart';
import '../widgets/submit_score_sheet.dart';
import '../widgets/add_to_collection_sheet.dart';
import '../widgets/game_card.dart' show genreColor;

class GameDetailScreen extends StatelessWidget {
  final Game game;

  const GameDetailScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthService.isLoggedIn;
    final baseColor = genreColor(game.genre);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          game.title,
          style: const TextStyle(
            fontFamily: 'Doto',
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (isLoggedIn) ...[
            // Favorite button
            _FavoriteButton(gameId: game.id),
            // Add to collection
            IconButton(
              icon: const Icon(Icons.add_box_outlined),
              tooltip: 'Add to Collection',
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => AddToCollectionSheet(
                  gameId: game.id,
                  gameTitle: game.title,
                ),
              ),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Genre-colored header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    baseColor.withValues(alpha: 0.8),
                    AppColors.surface,
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontFamily: 'Doto',
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      shadows: [
                        Shadow(blurRadius: 8, color: Colors.black87),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (game.altTitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      game.altTitle!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${game.year} • ${game.publisher}',
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadata pills
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(label: game.genre, filled: true),
                      _InfoChip(label: game.type),
                      _InfoChip(label: game.nbPlayers),
                      if (game.megs != null)
                        _InfoChip(label: '${game.megs} MEGs'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Description
                  if (game.description != null && game.description!.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Text(
                        game.description!,
                        style: const TextStyle(
                          height: 1.6,
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Move List
                  if (game.roms.isNotEmpty)
                    _MoveListLoader(
                      romNames: game.roms.map((r) => r.romName).toList(),
                      gameId: game.id,
                      gameTitle: game.title,
                    ),

                  const SizedBox(height: 24),

                  // DIP Settings
                  if (game.roms.isNotEmpty)
                    _DipSettingsLoader(
                      romNames: game.roms
                          .where((r) => !r.excludeSoftdips)
                          .map((r) => r.romName)
                          .toList(),
                    ),

                  const SizedBox(height: 24),

                  // Community Notes
                  _CommunityNotesSection(gameId: game.id),

                  const SizedBox(height: 24),

                  // Leaderboard
                  _LeaderboardSection(gameId: game.id),

                  const SizedBox(height: 24),

                  // Collection status (if logged in)
                  if (isLoggedIn) _CollectionStatusSection(gameId: game.id),

                  const SizedBox(height: 24),

                  // ROMs table
                  if (game.roms.isNotEmpty)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      initiallyExpanded: false,
                      title: Row(
                        children: [
                          const Icon(Icons.memory, size: 20),
                          const SizedBox(width: 8),
                          Text('ROM Versions',
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      children: [
                        ...game.roms.map((rom) => Card(
                              child: ListTile(
                                title: Text(rom.romName),
                                subtitle: Text(
                                  [
                                    rom.description,
                                    if (rom.serial.isNotEmpty) rom.serial,
                                    if (rom.platformTag.isNotEmpty)
                                      'Platform: ${rom.platformTag}',
                                  ].join('\n'),
                                ),
                                isThreeLine: true,
                              ),
                            )),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Favorite Button ─────────────────────────────────────────────────────

class _FavoriteButton extends StatelessWidget {
  final String gameId;
  const _FavoriteButton({required this.gameId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserFavorite?>(
      stream: UserService.favoriteStatusStream(gameId),
      builder: (context, snapshot) {
        final fav = snapshot.data;
        return IconButton(
          icon: Icon(
            fav != null ? Icons.favorite : Icons.favorite_border,
            color: fav != null ? Colors.red : null,
          ),
          tooltip: fav != null ? fav.status.label : 'Add to Favorites',
          onPressed: () => _showFavoriteSheet(context, fav),
        );
      },
    );
  }

  void _showFavoriteSheet(BuildContext context, UserFavorite? current) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set Status',
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...FavoriteStatus.values.map((status) => ListTile(
                  leading: Text(status.icon, style: const TextStyle(fontSize: 24)),
                  title: Text(status.label),
                  selected: current?.status == status,
                  onTap: () {
                    UserService.setFavorite(gameId, status);
                    Navigator.pop(ctx);
                  },
                )),
            if (current != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline,
                    color: Colors.red),
                title: const Text('Remove from Favorites'),
                onTap: () {
                  UserService.removeFavorite(gameId);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Community Notes Section ─────────────────────────────────────────────

class _CommunityNotesSection extends StatelessWidget {
  final String gameId;
  const _CommunityNotesSection({required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.comment, size: 20),
            const SizedBox(width: 8),
            Text('Community Notes',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (AuthService.isLoggedIn)
              TextButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AddNoteSheet(gameId: gameId),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<CommunityNote>>(
          stream: NotesService.notesForGameStream(gameId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }
            final notes = snapshot.data!;
            if (notes.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No notes yet. Be the first to share a tip!',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              );
            }
            return Column(
              children: notes.map((note) => _NoteCard(note: note)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  final CommunityNote note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final isOwner =
        AuthService.currentUser?.uid == note.userId;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(note.category.label,
                      style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Text(note.userName,
                    style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                if (AuthService.isLoggedIn)
                  IconButton(
                    icon: const Icon(Icons.thumb_up_outlined, size: 16),
                    onPressed: () => NotesService.upvoteNote(note.id),
                    visualDensity: VisualDensity.compact,
                  ),
                Text('${note.upvotes}',
                    style: Theme.of(context).textTheme.bodySmall),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    onPressed: () => NotesService.deleteNote(note.id),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(note.text),
          ],
        ),
      ),
    );
  }
}

// ── Leaderboard Section ─────────────────────────────────────────────────

class _LeaderboardSection extends StatelessWidget {
  final String gameId;
  const _LeaderboardSection({required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events, size: 20),
            const SizedBox(width: 8),
            Text('Leaderboard',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (AuthService.isLoggedIn)
              TextButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SubmitScoreSheet(gameId: gameId),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Submit'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<GameScore>>(
          stream: ScoresService.scoresForGameStream(gameId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }
            final scores = snapshot.data!;
            if (scores.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No scores yet. Set a record!',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              );
            }
            return Column(
              children: [
                for (int i = 0; i < scores.length; i++)
                  _ScoreTile(rank: i + 1, score: scores[i]),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ScoreTile extends StatelessWidget {
  final int rank;
  final GameScore score;
  const _ScoreTile({required this.rank, required this.score});

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) { 1 => '🥇', 2 => '🥈', 3 => '🥉', _ => '#$rank' };
    return Card(
      child: ListTile(
        leading: Text(medal, style: const TextStyle(fontSize: 20)),
        title: Text('${score.score}'),
        subtitle: Text('${score.userName} · ${score.platform}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (score.isVerified)
              const Icon(Icons.verified, color: Colors.blue, size: 18),
            if (score.proofUrl.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.photo, size: 18),
                onPressed: () => _showProof(context),
                tooltip: 'View proof',
              ),
          ],
        ),
      ),
    );
  }

  void _showProof(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Score: ${score.score}'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            Image.network(
              score.proofUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Could not load proof image'),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Collection Status Section ───────────────────────────────────────────

class _CollectionStatusSection extends StatelessWidget {
  final String gameId;
  const _CollectionStatusSection({required this.gameId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CollectionItem>>(
      stream: UserService.collectionForGameStream(gameId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final items = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.collections_bookmark, size: 20),
                const SizedBox(width: 8),
                Text('In Your Collection',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Card(
                  child: ListTile(
                    title: Text(
                        '${item.platform.toUpperCase()} · ${item.format.label}'),
                    subtitle: Text([
                      item.condition.label,
                      item.region.toUpperCase(),
                      if (item.purchasePrice != null)
                        '${item.purchasePrice!.toStringAsFixed(0)} ${item.purchaseCurrency ?? ''}',
                    ].join(' · ')),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => AddToCollectionSheet(
                              gameId: item.gameId,
                              gameTitle: item.gameTitle,
                              existingItem: item,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () async {
                            await UserService.removeFromCollection(item.id);
                          },
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }
}

// ── Shared Widgets ──────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;
  final bool filled;
  const _InfoChip({required this.label, this.filled = false});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: filled
            ? AppColors.primary.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.textSecondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: filled ? FontWeight.w600 : FontWeight.normal,
          color: filled ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}



/// Async loader that fetches command data from Firestore for a game's rom names.
class _MoveListLoader extends StatelessWidget {
  final List<String> romNames;
  final String gameId;
  final String gameTitle;

  const _MoveListLoader({
    required this.romNames,
    required this.gameId,
    required this.gameTitle,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CommandData?>(
      future: FirestoreService.getCommandData(romNames),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final commandData = snapshot.data;
        if (commandData == null || commandData.sections.isEmpty) {
          return const SizedBox.shrink();
        }

        return MoveListView(
          commandData: commandData,
          gameId: gameId,
          gameTitle: gameTitle,
          romName: commandData.id,
        );
      },
    );
  }
}

/// Async loader that fetches DIP settings from Firestore for a game's rom names.
class _DipSettingsLoader extends StatelessWidget {
  final List<String> romNames;

  const _DipSettingsLoader({required this.romNames});

  @override
  Widget build(BuildContext context) {
    if (romNames.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<DipSettingsData?>(
      future: FirestoreService.getDipSettings(romNames),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final dipData = snapshot.data;
        if (dipData == null ||
            (dipData.regions.isEmpty && !dipData.hasDebugDips)) {
          return const SizedBox.shrink();
        }

        return DipSettingsView(dipData: dipData);
      },
    );
  }
}
