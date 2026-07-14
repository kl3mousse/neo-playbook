import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart' show selectedTabIndex;
import '../models/game.dart';
import '../models/move_list.dart';
import '../models/dip_settings.dart';
import '../models/community_note.dart';
import '../models/game_score.dart';
import '../models/user_favorite.dart';
import '../models/collection_item.dart';import '../router.dart' show canonicalGameUrl;
import '../theme/app_theme.dart';
import '../theme/combofox_theme.dart';
import '../theme/platform_palette.dart';
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
import '../widgets/collection_tile.dart';
import '../widgets/game_card.dart' show genreColor;
import '../widgets/arcade_panel.dart';

class GameDetailScreen extends StatelessWidget {
  final Game game;

  const GameDetailScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthService.isLoggedIn;
    final baseColor = genreColor(game.primaryGenre);
    final palette = platformPalette(game.platform);
    // When the detail page was opened via a deep link (cold start with
    // no back stack), show a bottom nav so users can reach other parts
    // of the app.
    final showRootNav = !GoRouter.of(context).canPop();

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
          // Share game URL
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () => _shareGame(context),
          ),
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
            // Platform-accented typographic hero header.
            _HeroHeader(
              game: game,
              palette: palette,
              genreAccent: baseColor,
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
                      ...game.genre.map((g) => _InfoChip(label: g, filled: true)),
                      _InfoChip(label: game.playersLabel),
                      if (game.ngmId != null)
                        _NgmChip(ngmId: game.ngmId!),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Description
                  if (game.description != null && game.description!.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: _DescriptionWithFoxxy(
                        text: game.description!,
                        style: const TextStyle(
                          height: 1.6,
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Move List
                  if (game.features.hasMoveLists && game.roms.isNotEmpty)
                    ArcadePanel(
                      isActive: true,
                      padding: EdgeInsets.zero,
                      child: _MoveListLoader(
                        romNames: game.roms.map((r) => r.romName).toList(),
                        gameId: game.id,
                        gameTitle: game.title,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // DIP Settings
                  if ((game.features.hasSoftDips || game.features.hasDebugDips) &&
                      game.roms.isNotEmpty)
                    ArcadePanel(
                      isActive: true,
                      accentColor: ComboFoxColors.neonBlue,
                      padding: EdgeInsets.zero,
                      child: _DipSettingsLoader(
                        romNames: game.roms
                            .map((r) => r.romName)
                            .toList(),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // External Links
                  if (game.hfsdbId != null ||
                      (game.igdbUrl != null && game.igdbUrl!.isNotEmpty) ||
                      (game.mvsScansUrl != null &&
                          game.mvsScansUrl!.isNotEmpty)) ...[
                    _ExternalLinksSection(game: game),
                    const SizedBox(height: 24),
                  ],

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
                                    if (rom.title != null) rom.title!,
                                    if (rom.isParent) 'Parent ROM',
                                    if (rom.region != null) rom.region!,
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
      bottomNavigationBar: showRootNav ? const _DeepLinkBottomNav() : null,
    );
  }

  Future<void> _shareGame(BuildContext context) async {
    final url = canonicalGameUrl(game.id);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SharePlus.instance.share(
        ShareParams(text: url, subject: game.title),
      );
    } catch (_) {
      // Fallback: copy to clipboard (e.g. on web where the share API
      // may be unavailable).
      await Clipboard.setData(ClipboardData(text: url));
      messenger.showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')),
      );
    }
  }
}

// ── Deep-link bottom nav ────────────────────────────────────────────────

/// Bottom navigation shown on pages reached via a deep link (no back
/// stack). Tapping a destination updates [selectedTabIndex] and sends
/// the user to the main shell.
class _DeepLinkBottomNav extends StatelessWidget {
  const _DeepLinkBottomNav();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (i) {
        selectedTabIndex.value = i;
        context.go('/');
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.videogame_asset_outlined),
          selectedIcon: Icon(Icons.videogame_asset),
          label: 'Games',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_outline),
          selectedIcon: Icon(Icons.favorite),
          label: 'Favorites',
        ),
        NavigationDestination(
          icon: Icon(Icons.collections_bookmark_outlined),
          selectedIcon: Icon(Icons.collections_bookmark),
          label: 'Collection',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

// ── Description with Foxxy icon (text wraps around image) ───────────────

/// Renders the game description with a small Foxxy icon floated on the
/// left. Text lays out to the right of the icon and, once the vertical
/// space beside the icon is exhausted, continues at full width beneath
/// it — mimicking a CSS `float: left` behavior which Flutter does not
/// provide natively.
class _DescriptionWithFoxxy extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _DescriptionWithFoxxy({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    const desiredImageSize = 72.0;
    const gap = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final besideWidth = maxWidth - desiredImageSize - gap;

        // If there isn't enough horizontal room for meaningful text
        // beside the icon, stack vertically.
        if (besideWidth < 80) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/foxxy/sd/foxxy-sd-icon-01.png',
                width: desiredImageSize,
                height: desiredImageSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
              const SizedBox(height: gap),
              Text(text, style: style),
            ],
          );
        }

        final textScaler = MediaQuery.of(context).textScaler;
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: textScaler,
          maxLines: null,
        )..layout(maxWidth: besideWidth);

        final metrics = painter.computeLineMetrics();
        // Fallback image sized to the desired square.
        final defaultImage = Image.asset(
          'assets/foxxy/sd/foxxy-sd-icon-01.png',
          width: desiredImageSize,
          height: desiredImageSize,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        );
        if (metrics.isEmpty) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              defaultImage,
              const SizedBox(width: gap),
              Expanded(child: Text(text, style: style)),
            ],
          );
        }

        final lineHeight = metrics.first.height;
        final linesFitBesideImage =
            (desiredImageSize / lineHeight).round().clamp(1, metrics.length);
        // Snap the image height to an integer number of text lines so
        // the Row's height matches the beside-text height exactly. This
        // preserves a continuous line rhythm with the "below" text.
        final snappedImageSize = linesFitBesideImage * lineHeight;
        final image = Image.asset(
          'assets/foxxy/sd/foxxy-sd-icon-01.png',
          width: snappedImageSize,
          height: snappedImageSize,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        );

        // Case: all text fits beside the icon — no wrapping needed.
        if (metrics.length <= linesFitBesideImage) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              image,
              const SizedBox(width: gap),
              Expanded(child: Text(text, style: style)),
            ],
          );
        }

        // Find the character index at the end of the last line that
        // still sits beside the image.
        final yInLastBesideLine =
            (linesFitBesideImage - 0.5) * lineHeight;
        final splitPos = painter.getPositionForOffset(
          Offset(besideWidth, yInLastBesideLine),
        );
        var splitIndex = splitPos.offset.clamp(0, text.length);

        // Skip a soft-wrapped space or a hard newline at the split so
        // the "below" portion doesn't start with whitespace.
        while (splitIndex < text.length &&
            (text.codeUnitAt(splitIndex) == 0x20 ||
                text.codeUnitAt(splitIndex) == 0x0A)) {
          splitIndex++;
        }

        final beside = text.substring(0, splitIndex).trimRight();
        final below = text.substring(splitIndex);

        if (below.isEmpty) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              image,
              const SizedBox(width: gap),
              Expanded(child: Text(text, style: style)),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                image,
                const SizedBox(width: gap),
                Expanded(child: Text(beside, style: style)),
              ],
            ),
            Text(below, style: style),
          ],
        );
      },
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

class _CommunityNotesSection extends StatefulWidget {
  final String gameId;
  const _CommunityNotesSection({required this.gameId});

  @override
  State<_CommunityNotesSection> createState() => _CommunityNotesSectionState();
}

class _CommunityNotesSectionState extends State<_CommunityNotesSection> {
  static const _pageSize = 20;
  int _limit = _pageSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.comment, size: 20),
            const SizedBox(width: 8),
            const Expanded(child: NeonSectionHeader('Community Notes')),
            TextButton.icon(
              onPressed: () {
                if (!AuthService.isLoggedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sign in to add a note')),
                  );
                  return;
                }
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AddNoteSheet(gameId: widget.gameId),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<CommunityNote>>(
          stream: NotesService.notesForGameStream(
            widget.gameId,
            limit: _limit,
          ),
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
            final canLoadMore = notes.length >= _limit;
            return Column(
              children: [
                ...notes.map((note) => _NoteCard(note: note)),
                if (canLoadMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _limit += _pageSize),
                      icon: const Icon(Icons.expand_more, size: 18),
                      label: const Text('Load more'),
                    ),
                  ),
              ],
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

class _LeaderboardSection extends StatefulWidget {
  final String gameId;
  const _LeaderboardSection({required this.gameId});

  @override
  State<_LeaderboardSection> createState() => _LeaderboardSectionState();
}

class _LeaderboardSectionState extends State<_LeaderboardSection> {
  static const _pageSize = 20;
  int _limit = _pageSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events, size: 20),
            const SizedBox(width: 8),
            const Expanded(child: NeonSectionHeader('Leaderboard')),
            TextButton.icon(
              onPressed: () {
                if (!AuthService.isLoggedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sign in to submit a score')),
                  );
                  return;
                }
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SubmitScoreSheet(gameId: widget.gameId),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Submit'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<GameScore>>(
          stream: ScoresService.scoresForGameStream(
            widget.gameId,
            limit: _limit,
          ),
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
            final canLoadMore = scores.length >= _limit;
            return Column(
              children: [
                for (int i = 0; i < scores.length; i++)
                  _ScoreTile(rank: i + 1, score: scores[i]),
                if (canLoadMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _limit += _pageSize),
                      icon: const Icon(Icons.expand_more, size: 18),
                      label: const Text('Load more'),
                    ),
                  ),
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
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Share proof link',
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(ctx);
                    try {
                      await SharePlus.instance.share(
                        ShareParams(
                          text: score.proofUrl,
                          subject: 'Score proof',
                        ),
                      );
                    } catch (_) {
                      await Clipboard.setData(
                          ClipboardData(text: score.proofUrl));
                      messenger.showSnackBar(
                        const SnackBar(
                            content:
                                Text('Proof link copied to clipboard')),
                      );
                    }
                  },
                ),
              ],
            ),
            GestureDetector(
              onLongPress: () async {
                await Clipboard.setData(
                    ClipboardData(text: score.proofUrl));
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text('Proof link copied to clipboard')),
                );
              },
              child: InteractiveViewer(
                maxScale: 4,
                child: Image.network(
                  score.proofUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text("Couldn't load proof image"),
                  ),
                ),
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
                const Expanded(child: NeonSectionHeader('In Your Collection')),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((item) => CollectionTile(item: item)),
          ],
        );
      },
    );
  }
}

// ── External Links Section ──────────────────────────────────────────────

class _ExternalLinksSection extends StatelessWidget {
  final Game game;
  const _ExternalLinksSection({required this.game});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (game.hfsdbId != null) _HfsdbChip(hfsdbId: game.hfsdbId!),
      if (game.igdbUrl != null && game.igdbUrl!.isNotEmpty)
        _IgdbChip(igdbUrl: game.igdbUrl!),
      if (game.mvsScansUrl != null && game.mvsScansUrl!.isNotEmpty)
        _MvsScansChip(mvsScansUrl: game.mvsScansUrl!),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.link, size: 20),
            SizedBox(width: 8),
            Expanded(child: NeonSectionHeader('External Links')),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: chips,
        ),
      ],
    );
  }
}

// ── Shared Widgets ──────────────────────────────────────────────────────

class _NgmChip extends StatelessWidget {
  final int ngmId;
  const _NgmChip({required this.ngmId});

  String get _formattedId => ngmId.toString().padLeft(3, '0');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        'NGM-$_formattedId / NGH-$_formattedId',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _IgdbChip extends StatelessWidget {
  final String igdbUrl;
  const _IgdbChip({required this.igdbUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse(igdbUrl),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/logo-igdb.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'IGDB',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HfsdbChip extends StatelessWidget {
  final int hfsdbId;
  const _HfsdbChip({required this.hfsdbId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse('https://db.hfsplay.fr/games/$hfsdbId'),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo_hfs.png',
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'HFS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MvsScansChip extends StatelessWidget {
  final String mvsScansUrl;
  const _MvsScansChip({required this.mvsScansUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse(mvsScansUrl),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'MVS-scans.com',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

// ── Hero Header ─────────────────────────────────────────────────────────

/// Platform-accented typographic banner with neon arcade gradient.
/// Features a subtle "INSERT COIN" flicker text at the top.
class _HeroHeader extends StatefulWidget {
  final Game game;
  final PlatformPalette palette;
  final Color genreAccent;

  const _HeroHeader({
    required this.game,
    required this.palette,
    required this.genreAccent,
  });

  @override
  State<_HeroHeader> createState() => _HeroHeaderState();
}

class _HeroHeaderState extends State<_HeroHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flickerCtrl;
  late final Animation<double> _flickerAnim;

  @override
  void initState() {
    super.initState();
    _flickerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _flickerAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.08), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: 0.4), weight: 60),
    ]).animate(CurvedAnimation(parent: _flickerCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _flickerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ComboFoxColors.neonPurple,
            Color(0xFF7C1FA8), // mid purple
            ComboFoxColors.neonPink,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x80A855F7), // neonPurple 50%
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Platform badge + genre accent dot.
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        widget.palette.label,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: widget.genreAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.game.yearLabel,
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.game.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontFamily: 'Doto',
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -0.3,
                    shadows: [
                      Shadow(blurRadius: 10, color: Colors.black87),
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.game.altTitle != null &&
                    widget.game.altTitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.game.altTitle!,
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.72),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (widget.game.publisher != null &&
                    widget.game.publisher!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    widget.game.publisher!.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // INSERT COIN flicker text
          Positioned(
            top: 8,
            left: 16,
            child: AnimatedBuilder(
              animation: _flickerAnim,
              builder: (context, child) => Opacity(
                opacity: _flickerAnim.value,
                child: child,
              ),
              child: Text(
                '// INSERT COIN //',
                style: GoogleFonts.pressStart2p(
                  fontSize: 7,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
