import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/gold_moves_repository.dart';
import '../widgets/gold_move_list_view.dart';

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
      body: _GoldCharacterMovesBody(
        gameId: gameId,
        gameTitle: gameTitle,
        romName: romName,
        sectionTitle: sectionTitle,
      ),
    );
  }
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
  static final _goldRepository = GoldMovesRepository();
  late Future<GoldMovesPublishedProfile> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _load();
  }

  Future<GoldMovesPublishedProfile> _load() {
    return _goldRepository.loadProfile(widget.gameId);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<GoldMovesPublishedProfile>(
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
                Text(_goldCharacterLoadMessage(l, snapshot.error)),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _profile = _load();
                    });
                  },
                  child: Text(l.goldRetry),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: GoldMoveListView(
            profile: snapshot.data!.profile,
            gameId: widget.gameId,
            gameTitle: widget.gameTitle,
            onlyCharacterName: widget.sectionTitle,
          ),
        );
      },
    );
  }
}

String _goldCharacterLoadMessage(AppLocalizations l, Object? error) {
  if (error is GoldMovesRepositoryException) {
    return switch (error.kind) {
      GoldMovesFailureKind.unavailable => l.goldLoadOffline,
      GoldMovesFailureKind.unsupportedContract => l.goldLoadUnsupported,
      _ => l.goldLoadError,
    };
  }
  return l.goldLoadError;
}
