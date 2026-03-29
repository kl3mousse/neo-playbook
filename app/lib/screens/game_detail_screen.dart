import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/move_list.dart';
import '../models/dip_settings.dart';
import '../models/community_note.dart';
import '../models/game_score.dart';
import '../models/user_favorite.dart';
import '../models/collection_item.dart';
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

class GameDetailScreen extends StatelessWidget {
  final Game game;

  const GameDetailScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final wallpaper = game.images['wallpaper']?.displayUrl;
    final cover = game.images['cover3d']?.displayUrl;
    final isLoggedIn = AuthService.isLoggedIn;

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
            // Hero image
            if (wallpaper != null)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: Image.network(
                  wallpaper,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover image
                      if (cover != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              cover,
                              width: 120,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if (game.altTitle != null)
                              Text(
                                game.altTitle!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontStyle: FontStyle.italic),
                              ),
                            const SizedBox(height: 8),
                            _InfoChip(label: game.year),
                            _InfoChip(label: game.publisher),
                            _InfoChip(label: game.genre),
                            _InfoChip(label: game.type),
                            _InfoChip(label: game.nbPlayers),
                            if (game.megs != null)
                              _InfoChip(label: '${game.megs} MEGs'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  if (game.description != null && game.description!.isNotEmpty)
                    Text(game.description!),

                  const SizedBox(height: 24),

                  // Screenshots
                  _ScreenshotRow(game: game),

                  const SizedBox(height: 24),

                  // Move List
                  if (game.roms.isNotEmpty)
                    _MoveListLoader(romNames: game.roms.map((r) => r.romName).toList()),

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
                  if (game.roms.isNotEmpty) ...[
                    Text('ROM Versions',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
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
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _ScreenshotRow extends StatelessWidget {
  final Game game;
  const _ScreenshotRow({required this.game});

  @override
  Widget build(BuildContext context) {
    final keys = ['screenshot_title', 'screenshot_main', 'screenshot_alt'];
    final urls = keys
        .map((key) => game.images[key]?.displayUrl)
        .where((u) => u != null)
        .cast<String>()
        .toList();

    if (urls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Screenshots', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                urls[i],
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Async loader that fetches command data from Firestore for a game's rom names.
class _MoveListLoader extends StatelessWidget {
  final List<String> romNames;

  const _MoveListLoader({required this.romNames});

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

        return MoveListView(commandData: commandData);
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
