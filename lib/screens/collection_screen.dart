import 'package:flutter/material.dart';
import '../models/collection_item.dart';
import '../services/currency_service.dart';
import '../services/prefs_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../widgets/add_to_collection_sheet.dart';
import '../widgets/collection_scan_sheet.dart';
import '../widgets/collection_tile.dart';
import '../widgets/game_picker_sheet.dart';
import '../widgets/info_fab.dart';
import '../widgets/sign_in_prompt.dart';

// Sort options for within-platform-group ordering.
enum _SortOption { name, recent, price, condition }

extension _SortOptionLabel on _SortOption {
  String get label {
    switch (this) {
      case _SortOption.name:
        return 'Name (A→Z)';
      case _SortOption.recent:
        return 'Recently added';
      case _SortOption.price:
        return 'Purchase price';
      case _SortOption.condition:
        return 'Condition (best first)';
    }
  }

  String get key {
    switch (this) {
      case _SortOption.name:
        return 'name';
      case _SortOption.recent:
        return 'recent';
      case _SortOption.price:
        return 'price';
      case _SortOption.condition:
        return 'condition';
    }
  }

  static _SortOption fromKey(String key) {
    switch (key) {
      case 'recent':
        return _SortOption.recent;
      case 'price':
        return _SortOption.price;
      case 'condition':
        return _SortOption.condition;
      default:
        return _SortOption.name;
    }
  }
}

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  static const InfoFab _infoFab = InfoFab(
    foxxyAsset: 'assets/foxxy/sd/foxxy-sd-r2-c2.png',
    title: 'MY COLLECTION',
    paragraphs: [
      "Hmm… what games do I actually own? And which ones am I still missing?",
      "This is your personal shelf: log the cartridges, boards and discs you own, grouped by platform, with optional purchase price and condition.",
      "Add an item from any game's detail page, or tap the camera icon up top to scan a whole batch at once.",
    ],
  );

  bool _pricesHidden = false;
  bool _pricesHintShown = false;
  String _searchQuery = '';
  late _SortOption _sortOption;
  late Set<String> _collapsedPlatforms;

  @override
  void initState() {
    super.initState();
    _sortOption = _SortOptionLabel.fromKey(PrefsService.getCollectionSortOption());
    _collapsedPlatforms = Set<String>.from(PrefsService.getCollapsedPlatforms());
  }

  Future<void> _addGame(BuildContext context) async {
    final result = await showGamePicker(context);
    if (result == null || !context.mounted) return;

    if (result.game != null) {
      final game = result.game!;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddToCollectionSheet(
            gameId: game.id,
            gameTitle: game.title,
            initialPlatform: game.platform,
          ),
        ),
      );
    } else if (result.custom != null) {
      final draft = result.custom!;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddToCollectionSheet(
            gameId: '',
            gameTitle: draft.title,
            initialPlatform: draft.platformId,
            customDraft: draft,
          ),
        ),
      );
    }
  }

  void _togglePrices(BuildContext context) {
    setState(() => _pricesHidden = !_pricesHidden);
    if (_pricesHidden && !_pricesHintShown) {
      _pricesHintShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prices hidden — tap the total again to reveal.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _setSortOption(_SortOption opt) {
    setState(() => _sortOption = opt);
    PrefsService.setCollectionSortOption(opt.key);
  }

  void _toggleCollapsed(String platform) {
    setState(() {
      if (_collapsedPlatforms.contains(platform)) {
        _collapsedPlatforms.remove(platform);
      } else {
        _collapsedPlatforms.add(platform);
      }
    });
    PrefsService.setCollapsedPlatforms(_collapsedPlatforms.toList());
  }

  List<CollectionItem> _sorted(List<CollectionItem> items) {
    final copy = List<CollectionItem>.from(items);
    switch (_sortOption) {
      case _SortOption.name:
        copy.sort((a, b) =>
            a.gameTitle.toLowerCase().compareTo(b.gameTitle.toLowerCase()));
      case _SortOption.recent:
        // addedAt may be null for older items; treat null as earliest.
        copy.sort((a, b) {
          final at = a.addedAt;
          final bt = b.addedAt;
          if (at == null && bt == null) return 0;
          if (at == null) return 1;
          if (bt == null) return -1;
          return bt.compareTo(at); // newest first
        });
      case _SortOption.price:
        copy.sort((a, b) {
          final ap = a.purchasePrice;
          final bp = b.purchasePrice;
          if (ap == null && bp == null) return 0;
          if (ap == null) return 1;
          if (bp == null) return -1;
          return bp.compareTo(ap); // highest first
        });
      case _SortOption.condition:
        // Lower index in the enum = better condition.
        copy.sort((a, b) =>
            a.condition.index.compareTo(b.condition.index));
    }
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Collection',
            style: TextStyle(fontFamily: 'Doto', fontWeight: FontWeight.w800),
          ),
        ),
        floatingActionButton: _infoFab,
        body: const SignInPrompt(
          icon: Icons.collections_bookmark_outlined,
          message: 'Sign in to manage your collection',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Collection',
          style: TextStyle(fontFamily: 'Doto', fontWeight: FontWeight.w800),
        ),
        actions: [
          // Sort menu
          PopupMenuButton<_SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: _setSortOption,
            itemBuilder: (_) => _SortOption.values
                .map(
                  (opt) => PopupMenuItem(
                    value: opt,
                    child: Row(
                      children: [
                        if (opt == _sortOption)
                          const Icon(Icons.check, size: 18)
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Text(opt.label),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          IconButton(
            tooltip: 'Add game',
            icon: const Icon(Icons.add),
            onPressed: () => _addGame(context),
          ),
          IconButton(
            tooltip: 'Scan collection',
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const CollectionScanSheet(),
            ),
          ),
        ],
      ),
      floatingActionButton: _infoFab,
      body: StreamBuilder<List<CollectionItem>>(
        stream: UserService.collectionStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allItems = snapshot.data!;
          if (allItems.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64),
                  SizedBox(height: 16),
                  Text('No items in your collection'),
                  SizedBox(height: 8),
                  Text('Add games from the game detail screen'),
                ],
              ),
            );
          }

          final query = _searchQuery.toLowerCase().trim();
          final items = query.isEmpty
              ? allItems
              : allItems
                  .where(
                    (i) => i.gameTitle.toLowerCase().contains(query),
                  )
                  .toList();

          final drafts = items.where((i) => i.isUnverified).toList();
          final verifiedItems = items.where((i) => !i.isUnverified).toList();

          // Group verified items by platform.
          final grouped = <String, List<CollectionItem>>{};
          for (final item in verifiedItems) {
            grouped.putIfAbsent(item.platform, () => []).add(item);
          }
          final platforms = grouped.keys.toList()..sort();

          // Per-currency totals across ALL items (not filtered).
          final currencyTotals = <String, double>{};
          for (final item in allItems) {
            if (item.purchasePrice != null) {
              final cur = item.purchaseCurrency ?? 'USD';
              currencyTotals[cur] =
                  (currencyTotals[cur] ?? 0) + item.purchasePrice!;
            }
          }

          final defaultCurrency =
              PrefsService.getDefaultCurrency() ?? 'USD';
          final convertedTotal = currencyTotals.isEmpty
              ? null
              : CurrencyService.convertTotals(
                  currencyTotals,
                  defaultCurrency,
                );

          return Column(
            children: [
              // Summary bar
              _SummaryBar(
                itemCount: allItems.length,
                platformCount: platforms.length,
                draftCount: drafts.length,
                convertedTotal: convertedTotal,
                pricesHidden: _pricesHidden,
                onTogglePrices: () => _togglePrices(context),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search my collection…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () =>
                                setState(() => _searchQuery = ''),
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(height: 4),
              // Items list: drafts first, then grouped by platform.
              Expanded(
                child: ListView(
                  children: [
                    if (drafts.isNotEmpty)
                      _DraftsSection(
                        items: drafts,
                        pricesHidden: _pricesHidden,
                      ),
                    for (final platform in platforms)
                      if (grouped[platform]!.isNotEmpty)
                        _PlatformGroup(
                          platform: platform,
                          items: _sorted(grouped[platform]!),
                          convertedSubtotal: CurrencyService.convertTotals(
                            _platformCurrencyTotals(grouped[platform]!),
                            defaultCurrency,
                          ),
                          pricesHidden: _pricesHidden,
                          collapsed: _collapsedPlatforms.contains(platform),
                          onToggleCollapse: () =>
                              _toggleCollapsed(platform),
                        ),
                    if (items.isEmpty && query.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No results')),
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

  static Map<String, double> _platformCurrencyTotals(
    List<CollectionItem> items,
  ) {
    final totals = <String, double>{};
    for (final item in items) {
      if (item.purchasePrice != null) {
        final cur = item.purchaseCurrency ?? 'USD';
        totals[cur] = (totals[cur] ?? 0) + item.purchasePrice!;
      }
    }
    return totals;
  }
}

// ── Summary bar ─────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final int itemCount;
  final int platformCount;
  final int draftCount;
  final ConvertedTotal? convertedTotal;
  final bool pricesHidden;
  final VoidCallback onTogglePrices;

  const _SummaryBar({
    required this.itemCount,
    required this.platformCount,
    required this.draftCount,
    required this.convertedTotal,
    required this.pricesHidden,
    required this.onTogglePrices,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryTile(
            label: 'Items',
            value: itemCount.toString(),
          ),
          _SummaryTile(
            label: 'Platforms',
            value: platformCount.toString(),
          ),
          if (draftCount > 0)
            _SummaryTile(
              label: 'Drafts',
              value: draftCount.toString(),
            ),
          if (convertedTotal != null)
            _TotalValueTile(
              converted: convertedTotal!,
              pricesHidden: pricesHidden,
              onTap: onTogglePrices,
            ),
        ],
      ),
    );
  }
}

class _TotalValueTile extends StatelessWidget {
  final ConvertedTotal converted;
  final bool pricesHidden;
  final VoidCallback onTap;

  const _TotalValueTile({
    required this.converted,
    required this.pricesHidden,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final valueText = pricesHidden ? '•••' : converted.displayValue;
    final tooltipText = pricesHidden ? null : converted.tooltipText;

    Widget tile = GestureDetector(
      onTap: onTap,
      child: _SummaryTile(
        label: 'Total Value',
        value: valueText,
        hint: pricesHidden
            ? Icons.visibility_off_outlined
            : Icons.touch_app_outlined,
      ),
    );

    if (tooltipText != null) {
      tile = Tooltip(message: tooltipText, child: tile);
    }
    return tile;
  }
}

// ── Drafts section ───────────────────────────────────────────────────────

class _DraftsSection extends StatelessWidget {
  final List<CollectionItem> items;
  final bool pricesHidden;
  const _DraftsSection({required this.items, required this.pricesHidden});

  @override
  Widget build(BuildContext context) {
    const warning = Color(0xFFFBBF24);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.flag_outlined, color: warning, size: 18),
              const SizedBox(width: 6),
              Text(
                'Needs review (${items.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: warning,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            'Auto-imported drafts. Open one to verify or edit its details.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final item in items)
          CollectionTile(item: item, pricesHidden: pricesHidden),
      ],
    );
  }
}

// ── Platform group (collapsible) ─────────────────────────────────────────

class _PlatformGroup extends StatelessWidget {
  final String platform;
  final List<CollectionItem> items;
  final ConvertedTotal convertedSubtotal;
  final bool pricesHidden;
  final bool collapsed;
  final VoidCallback onToggleCollapse;

  const _PlatformGroup({
    required this.platform,
    required this.items,
    required this.convertedSubtotal,
    required this.pricesHidden,
    required this.collapsed,
    required this.onToggleCollapse,
  });

  String _subtotalLabel() {
    if (convertedSubtotal.total == 0 && convertedSubtotal.breakdown.isEmpty) {
      return '${items.length} items';
    }
    return '${items.length} items · ${convertedSubtotal.displayValue}';
  }

  @override
  Widget build(BuildContext context) {
    final subtotalText = pricesHidden
        ? '${items.length} items · •••'
        : _subtotalLabel();
    final subtotalTooltip = !pricesHidden ? convertedSubtotal.tooltipText : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggleCollapse,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        platform.toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtotalTooltip != null
                          ? Tooltip(
                              message: subtotalTooltip,
                              child: Text(
                                subtotalText,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            )
                          : Text(
                              subtotalText,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: collapsed ? -0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more),
                ),
              ],
            ),
          ),
        ),
        if (!collapsed)
          for (final item in items)
            CollectionTile(item: item, pricesHidden: pricesHidden),
      ],
    );
  }
}

// ── Summary tile ─────────────────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? hint;
  const _SummaryTile({required this.label, required this.value, this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(width: 4),
              Icon(
                hint,
                size: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ],
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

