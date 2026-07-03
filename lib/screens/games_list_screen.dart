import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/game.dart';
import '../theme/app_theme.dart';
import '../theme/combofox_theme.dart';
import '../services/firestore_service.dart';
import '../services/prefs_service.dart';
import '../widgets/game_card.dart';
import '../widgets/filter_panel.dart';
import '../widgets/info_fab.dart';
import '../widgets/system_chip.dart' show SystemChip;

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
  // Bumped to force the StreamBuilder to re-subscribe after an error.
  int _streamAttempt = 0;
  // Latest games snapshot, used by the Shuffle action in the app bar.
  List<Game> _lastGames = const [];

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });
    _hydrateFromPrefs();
  }

  void _hydrateFromPrefs() {
    _selectedPlatform = PrefsService.getPlatform();
    final sortName = PrefsService.getSortOption();
    if (sortName != null) {
      _sortOption = SortOption.values.firstWhere(
        (o) => o.name == sortName,
        orElse: () => SortOption.title,
      );
    }
    _sortAscending = PrefsService.getSortAscending();
    final yearStart = PrefsService.getFilterYearStart();
    final yearEnd = PrefsService.getFilterYearEnd();
    _filters = GameFilters(
      genre: PrefsService.getFilterGenre(),
      publisher: PrefsService.getFilterPublisher(),
      playerCount: PrefsService.getFilterPlayers(),
      yearRange: (yearStart != null && yearEnd != null)
          ? RangeValues(yearStart.toDouble(), yearEnd.toDouble())
          : null,
    );
  }

  Future<void> _persistFilters(GameFilters f) => PrefsService.setFilters(
        genre: f.genre,
        publisher: f.publisher,
        players: f.playerCount,
        yearStart: f.yearRange?.start.round(),
        yearEnd: f.yearRange?.end.round(),
      );

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

  void _shuffle() {
    if (_lastGames.isEmpty) return;
    final game = _lastGames[Random().nextInt(_lastGames.length)];
    context.push('/game/${game.id}');
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
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Pick a random game',
            onPressed: _lastGames.isEmpty ? null : _shuffle,
          ),
        ],
      ),
      floatingActionButton: const InfoFab(
        foxxyAsset: 'assets/foxxy/sd/foxxy-sd-r1-c2.png',
        title: 'GAMES LIST',
        paragraphs: [
          "This is ComboFox's main library — the games I know about!",
          "By default it's filtered on games that ship with move lists and combos, so you can jump straight into training.",
          "Pick another system in the top strip to browse the rest — info sheets are available for many more titles too.",
          "Tap the search bar or the filter icon to narrow things down, or hit the shuffle button up top for a surprise pick.",
        ],
      ),
      body: StreamBuilder<List<Game>>(
        key: ValueKey(_streamAttempt),
        stream: _searchQuery.isEmpty
            ? FirestoreService.gamesStream()
            : FirestoreService.searchGames(_searchQuery),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorRetry(
              error: snapshot.error,
              onRetry: () => setState(() => _streamAttempt++),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allGames = snapshot.data ?? [];
          // Keep a reference so the Shuffle action in the app bar has
          // something to pick from after the first successful load.
          _lastGames = allGames;

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
                _PlatformStrip(
                  platforms: availablePlatforms,
                  selected: effectivePlatform,
                  onChanged: (p) {
                    setState(() {
                      _selectedPlatform = p;
                      _filters = GameFilters.empty();
                    });
                    PrefsService.setPlatform(p);
                    _persistFilters(GameFilters.empty());
                  },
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
                              color: ComboFoxColors.neonBlue.withValues(alpha: 0.20),
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
                            ? ComboFoxColors.neonBlue
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
                        onFiltersChanged: (f) {
                          setState(() => _filters = f);
                          _persistFilters(f);
                        },
                        sortOption: _sortOption,
                        sortAscending: _sortAscending,
                        onSortChanged: (s) {
                          setState(() => _sortOption = s);
                          PrefsService.setSortOption(s.name);
                        },
                        onSortDirectionToggled: () {
                          setState(() => _sortAscending = !_sortAscending);
                          PrefsService.setSortAscending(_sortAscending);
                        },
                      ),

                    // Result count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Text(
                            filteredGames.length == platformGames.length
                                ? '${filteredGames.length} game${filteredGames.length == 1 ? '' : 's'}'
                                : '${filteredGames.length} of ${platformGames.length} games',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (_filters.hasActiveFilters)
                            TextButton(
                              onPressed: () {
                                setState(
                                    () => _filters = GameFilters.empty());
                                _persistFilters(GameFilters.empty());
                              },
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
                        child: RepaintBoundary(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount =
                                  constraints.maxWidth > 900
                                      ? 4
                                      : constraints.maxWidth > 600
                                          ? 3
                                          : 2;
                              return RefreshIndicator(
                                onRefresh: () async {
                                  setState(() => _streamAttempt++);
                                  // Give the new stream a moment to emit
                                  // before dismissing the indicator.
                                  await Future<void>.delayed(
                                      const Duration(milliseconds: 350));
                                },
                                child: GridView.builder(
                                  padding: const EdgeInsets.all(12),
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
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
                                ),
                              );
                            },
                          ),
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

/// Horizontal strip of platform chips. Owns a local "pending" selection
/// so the tapped chip's own animation renders instantly, decoupled from
/// the expensive parent rebuild (filter pipeline + grid).
class _PlatformStrip extends StatefulWidget {
  final List<String> platforms;
  final String selected;
  final ValueChanged<String> onChanged;

  const _PlatformStrip({
    required this.platforms,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_PlatformStrip> createState() => _PlatformStripState();
}

class _PlatformStripState extends State<_PlatformStrip> {
  String? _pending;

  String get _effective => _pending ?? widget.selected;

  @override
  void didUpdateWidget(covariant _PlatformStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Parent caught up with our pending selection — drop it.
    if (_pending != null && widget.selected == _pending) {
      _pending = null;
    }
  }

  void _handleTap(String p) {
    if (p == _effective) return;
    setState(() => _pending = p);
    // Defer the heavy parent rebuild (filter + grid) until after the
    // chip's own animation has had a couple of frames to render.
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      widget.onChanged(p);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          children: widget.platforms
              .map((p) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: SystemChip(
                        platformKey: p,
                        isSelected: _effective == p,
                        onTap: () => _handleTap(p),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

/// Friendly error state with a Retry action. Hides the raw error behind
/// a disclosure so the default view stays calm.
class _ErrorRetry extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 48, color: scheme.error),
                  const SizedBox(height: 12),
                  Text(
                    "Couldn't load games",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding:
                          const EdgeInsets.only(bottom: 8, top: 4),
                      title: Text(
                        'Details',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      children: [
                        SelectableText(
                          '$error',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}