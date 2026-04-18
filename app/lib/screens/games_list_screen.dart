import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/game.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../widgets/game_card.dart';
import '../widgets/filter_panel.dart';

/// Display-friendly labels for known platform keys.
/// Falls back to title-cased key for unknown platforms.
String _platformLabel(String key) {
  const labels = {
    'neogeo': 'Neo Geo',
    'neo geo': 'Neo Geo',
    'cps1': 'CPS-1',
    'cps2': 'CPS-2',
    'cps3': 'CPS-3',
    'neogeocd': 'Neo Geo CD',
    'atomiswave': 'Atomiswave',
    'taitof3': 'Taito F3',
    'hng64': 'Hyper Neo Geo 64',
    'stv': 'ST-V',
    'zn': 'ZN',
  };
  return labels[key] ??
      key.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

class GamesListScreen extends StatefulWidget {
  const GamesListScreen({super.key});

  @override
  State<GamesListScreen> createState() => _GamesListScreenState();
}

class _GamesListScreenState extends State<GamesListScreen> {
  String? _selectedPlatform;
  String _searchQuery = '';
  GameFilters _filters = GameFilters.empty();
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
          cmp = (a.year ?? 0).compareTo(b.year ?? 0);
        case SortOption.publisher:
          cmp = (a.publisher ?? '').compareTo(b.publisher ?? '');
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
      body: StreamBuilder<List<Game>>(
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

          final allGames = snapshot.data ?? [];

          // Derive available platforms from data
          final availablePlatforms = allGames
              .map((g) => g.platform)
              .where((p) => p.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          // Auto-select first platform if none set or selection no longer valid
          final effectivePlatform =
              (_selectedPlatform != null && availablePlatforms.contains(_selectedPlatform))
                  ? _selectedPlatform!
                  : (availablePlatforms.isNotEmpty ? availablePlatforms.first : '');

          // Filter games by selected platform
          final platformGames = allGames
              .where((game) => game.platform == effectivePlatform)
              .toList();

          // Apply advanced filters
          List<Game> filteredGames = _filters.apply(platformGames);

          // Apply sort
          filteredGames = _sortGames(filteredGames);

          return Column(
            children: [
              // Platform selector (dynamic from data)
              if (availablePlatforms.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: availablePlatforms
                          .map((p) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  label: Text(_platformLabel(p)),
                                  selected: effectivePlatform == p,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedPlatform = p;
                                      _filters = GameFilters.empty();
                                    });
                                  },
                                ),
                              ))
                          .toList(),
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

              // Filter panel + results
              Expanded(
                child: Column(
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
                                  onTap: () =>
                                      context.push('/game/${game.id}'),
                                );
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
