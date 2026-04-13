import 'package:flutter/material.dart';
import '../models/game.dart';

/// Filter state for advanced game filtering.
class GameFilters {
  final String? genre;
  final String? publisher;
  final int? playerCount;
  final RangeValues? yearRange;

  const GameFilters({
    this.genre,
    this.publisher,
    this.playerCount,
    this.yearRange,
  });

  bool get hasActiveFilters =>
      genre != null ||
      publisher != null ||
      playerCount != null ||
      yearRange != null;

  GameFilters copyWith({
    String? Function()? genre,
    String? Function()? publisher,
    int? Function()? playerCount,
    RangeValues? Function()? yearRange,
  }) {
    return GameFilters(
      genre: genre != null ? genre() : this.genre,
      publisher: publisher != null ? publisher() : this.publisher,
      playerCount: playerCount != null ? playerCount() : this.playerCount,
      yearRange: yearRange != null ? yearRange() : this.yearRange,
    );
  }

  /// Apply all filters to a list of games.
  List<Game> apply(List<Game> games) {
    var filtered = games;
    if (genre != null) {
      filtered = filtered.where((g) => g.genre.contains(genre!)).toList();
    }
    if (publisher != null) {
      filtered = filtered.where((g) => g.publisher == publisher).toList();
    }
    if (playerCount != null) {
      filtered =
          filtered.where((g) => g.nbPlayers == playerCount).toList();
    }
    if (yearRange != null) {
      filtered = filtered.where((g) {
        if (g.year == null) return false;
        return g.year! >= yearRange!.start && g.year! <= yearRange!.end;
      }).toList();
    }
    return filtered;
  }

  static GameFilters empty() => const GameFilters();
}

enum SortOption {
  title('Title'),
  year('Year'),
  publisher('Publisher');

  final String label;
  const SortOption(this.label);
}

/// Collapsible filter panel with genre, publisher, player count, type, and year range filters.
class FilterPanel extends StatelessWidget {
  final List<Game> allGames;
  final GameFilters filters;
  final ValueChanged<GameFilters> onFiltersChanged;
  final SortOption sortOption;
  final bool sortAscending;
  final ValueChanged<SortOption> onSortChanged;
  final VoidCallback onSortDirectionToggled;

  const FilterPanel({
    super.key,
    required this.allGames,
    required this.filters,
    required this.onFiltersChanged,
    required this.sortOption,
    required this.sortAscending,
    required this.onSortChanged,
    required this.onSortDirectionToggled,
  });

  @override
  Widget build(BuildContext context) {
    // Extract unique values from games
    final genres = allGames.expand((g) => g.genre).toSet().toList()..sort();
    final publishers = allGames.map((g) => g.publisher).where((p) => p != null && p.isNotEmpty).cast<String>().toSet().toList()..sort();
    final playerCounts = allGames.map((g) => g.nbPlayers).where((p) => p != null).cast<int>().toSet().toList()..sort();

    final years = allGames.map((g) => g.year).where((y) => y != null).cast<int>().toList();
    final minYear = years.isEmpty ? 1990.0 : years.reduce((a, b) => a < b ? a : b).toDouble();
    final maxYear = years.isEmpty ? 2025.0 : years.reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Text('Sort: ', style: TextStyle(fontSize: 12)),
              ...SortOption.values.map((opt) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ChoiceChip(
                      label: Text(opt.label, style: const TextStyle(fontSize: 12)),
                      selected: sortOption == opt,
                      onSelected: (_) => onSortChanged(opt),
                      visualDensity: VisualDensity.compact,
                    ),
                  )),
              IconButton(
                icon: Icon(
                  sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 18,
                ),
                onPressed: onSortDirectionToggled,
                visualDensity: VisualDensity.compact,
                tooltip: sortAscending ? 'Ascending' : 'Descending',
              ),
              const Spacer(),
              if (filters.hasActiveFilters)
                TextButton(
                  onPressed: () => onFiltersChanged(GameFilters.empty()),
                  child: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),

        // Genre chips
        if (genres.length > 1)
          _ChipRow(
            label: 'Genre',
            values: genres,
            selected: filters.genre,
            onSelected: (v) => onFiltersChanged(
                filters.copyWith(genre: () => v == filters.genre ? null : v)),
          ),

        // Publisher chips
        if (publishers.length > 1)
          _ChipRow(
            label: 'Publisher',
            values: publishers,
            selected: filters.publisher,
            onSelected: (v) => onFiltersChanged(filters.copyWith(
                publisher: () => v == filters.publisher ? null : v)),
          ),

        // Player count chips
        if (playerCounts.length > 1)
          _ChipRow(
            label: 'Players',
            values: playerCounts.map((p) => '$p').toList(),
            selected: filters.playerCount != null ? '${filters.playerCount}' : null,
            onSelected: (v) {
              final intVal = int.tryParse(v);
              onFiltersChanged(filters.copyWith(
                  playerCount: () => intVal == filters.playerCount ? null : intVal));
            },
          ),

        // Year range slider
        if (minYear < maxYear)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text('Year: ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: RangeSlider(
                    values: filters.yearRange ??
                        RangeValues(minYear, maxYear),
                    min: minYear,
                    max: maxYear,
                    divisions: (maxYear - minYear).toInt(),
                    labels: RangeLabels(
                      (filters.yearRange?.start ?? minYear).toInt().toString(),
                      (filters.yearRange?.end ?? maxYear).toInt().toString(),
                    ),
                    onChanged: (range) {
                      // If the range covers everything, clear the filter
                      if (range.start == minYear && range.end == maxYear) {
                        onFiltersChanged(
                            filters.copyWith(yearRange: () => null));
                      } else {
                        onFiltersChanged(
                            filters.copyWith(yearRange: () => range));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  final String label;
  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _ChipRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('$label:', style: const TextStyle(fontSize: 12)),
            ),
          ),
          ...values.map((v) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FilterChip(
                  label: Text(v, style: const TextStyle(fontSize: 11)),
                  selected: selected == v,
                  onSelected: (_) => onSelected(v),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )),
        ],
      ),
    );
  }
}
