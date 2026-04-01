import 'package:flutter/material.dart';
import '../models/game.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../widgets/game_card.dart';
import '../widgets/filter_panel.dart';
import 'game_detail_screen.dart';

const _platformLabels = {
  'neogeo': 'Neo Geo',
  'cps1': 'CPS-1',
  'cps2': 'CPS-2',
};

class GamesListScreen extends StatefulWidget {
  const GamesListScreen({super.key});

  @override
  State<GamesListScreen> createState() => _GamesListScreenState();
}

class _GamesListScreenState extends State<GamesListScreen> {
  String _selectedPlatform = 'neogeo';
  String _searchQuery = '';
  GameFilters _filters = const GameFilters(type: 'Licenced');
  SortOption _sortOption = SortOption.title;
  bool _sortAscending = true;
  bool _showFilters = false;
  final _searchFocus = FocusNode();
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  List<Game> _sortGames(List<Game> games) {
    final sorted = List<Game>.from(games);
    sorted.sort((a, b) {
      int cmp;
      switch (_sortOption) {
        case SortOption.title:
          cmp = a.title.compareTo(b.title);
        case SortOption.year:
          cmp = a.year.compareTo(b.year);
        case SortOption.publisher:
          cmp = a.publisher.compareTo(b.publisher);
      }
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Games',
          style: TextStyle(
            fontFamily: 'Doto',
            fontWeight: FontWeight.w800,
          ),
        ),

      ),
      body: Column(
        children: [
          // Platform selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SegmentedButton<String>(
              segments: _platformLabels.entries
                  .map((e) => ButtonSegment(
                        value: e.key,
                        label: Text(e.value),
                      ))
                  .toList(),
              selected: {_selectedPlatform},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedPlatform = selection.first;
                  _filters = selection.first == 'neogeo'
                      ? const GameFilters(type: 'Licenced')
                      : GameFilters.empty();
                });
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: _searchFocused
                    ? [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                focusNode: _searchFocus,
                decoration: InputDecoration(
                  hintText: 'Search games...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: _searchFocused
                        ? AppColors.secondary
                        : AppColors.textSecondary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showFilters
                          ? Icons.filter_list_off
                          : Icons.filter_list,
                    ),
                    onPressed: () =>
                        setState(() => _showFilters = !_showFilters),
                    tooltip: 'Filters',
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
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
                // Filter games by selected platform
                List<Game> platformGames = (snapshot.data ?? [])
                    .where((game) => game.platforms.contains(_selectedPlatform))
                    .toList();

                // Apply advanced filters
                List<Game> filteredGames = _filters.apply(platformGames);

                // Apply sort
                filteredGames = _sortGames(filteredGames);

                return Column(
                  children: [
                    // Advanced filter panel
                    if (_showFilters)
                      FilterPanel(
                        allGames: platformGames,
                        filters: _filters,
                        onFiltersChanged: (f) =>
                            setState(() => _filters = f),
                        sortOption: _sortOption,
                        sortAscending: _sortAscending,
                        onSortChanged: (s) =>
                            setState(() => _sortOption = s),
                        onSortDirectionToggled: () =>
                            setState(() => _sortAscending = !_sortAscending),
                      ),

                    // Result count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Text(
                            '${filteredGames.length} game${filteredGames.length == 1 ? '' : 's'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (_filters.hasActiveFilters)
                            TextButton(
                              onPressed: () => setState(
                                  () => _filters = GameFilters.empty()),
                              child: const Text('Clear filters',
                                  style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                    ),

                    if (filteredGames.isEmpty)
                      const Expanded(
                        child: Center(
                            child: Text('No games match your filters.')),
                      )
                    else
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
                                childAspectRatio: 1.1,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: filteredGames.length,
                              itemBuilder: (context, index) {
                                final game = filteredGames[index];
                                return GameCard(
                                  game: game,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GameDetailScreen(game: game),
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
