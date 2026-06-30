import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/firestore_service.dart';
import '../theme/combofox_theme.dart';
import '../theme/platform_palette.dart';

/// Opens a full-screen game picker so the user can relink a collection item
/// to a different canonical game. Returns the selected [Game], or null.
Future<Game?> showGamePicker(BuildContext context, {String? initialQuery}) {
  return Navigator.of(context).push<Game>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _GamePickerScreen(initialQuery: initialQuery),
    ),
  );
}

class _GamePickerScreen extends StatefulWidget {
  final String? initialQuery;
  const _GamePickerScreen({this.initialQuery});

  @override
  State<_GamePickerScreen> createState() => _GamePickerScreenState();
}

class _GamePickerScreenState extends State<_GamePickerScreen> {
  late final TextEditingController _searchController;
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _query = widget.initialQuery?.trim() ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Change game',
          style: TextStyle(fontFamily: 'Doto', fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search the catalog…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: _query.length < 2
                ? const Center(
                    child: Text(
                      'Type at least 2 characters to search',
                      style: TextStyle(color: ComboFoxColors.textSecondary),
                    ),
                  )
                : StreamBuilder<List<Game>>(
                    stream: FirestoreService.searchGames(_query),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      final games = snapshot.data!;
                      if (games.isEmpty) {
                        return const Center(
                          child: Text(
                            'No games found',
                            style: TextStyle(
                              color: ComboFoxColors.textSecondary,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: games.length,
                        itemBuilder: (context, i) {
                          final game = games[i];
                          final palette = platformPalette(game.platform);
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: palette.gradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.videogame_asset_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(game.title),
                            subtitle: Text(
                              [
                                palette.label,
                                if (game.yearLabel.isNotEmpty) game.yearLabel,
                              ].join(' · '),
                            ),
                            onTap: () => Navigator.pop(context, game),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
