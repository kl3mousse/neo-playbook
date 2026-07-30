import 'package:flutter/material.dart';
import '../models/collection_item.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../widgets/collection_scan_sheet.dart';
import '../widgets/collection_tile.dart';
import '../widgets/info_fab.dart';
import '../widgets/sign_in_prompt.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  static const InfoFab _infoFab = InfoFab(
    foxxyAsset: 'assets/foxxy/sd/foxxy-sd-r2-c2.png',
    title: 'MY COLLECTION',
    paragraphs: [
      "Hmm… what games do I actually own? And which ones am I still missing?",
      "This is your personal shelf: log the cartridges, boards and discs you own, grouped by platform, with optional purchase price and condition.",
      "Add an item from any game's detail page, or tap the camera icon up top to scan a whole batch at once.",
    ],
  );

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

          final items = snapshot.data!;
          if (items.isEmpty) {
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

          // Draft (unverified) items surfaced separately for quick review.
          final drafts = items.where((i) => i.isUnverified).toList();
          final verifiedItems = items.where((i) => !i.isUnverified).toList();

          // Group verified items by platform.
          final grouped = <String, List<CollectionItem>>{};
          for (final item in verifiedItems) {
            grouped.putIfAbsent(item.platform, () => []).add(item);
          }
          final platforms = grouped.keys.toList()..sort();

          // Calculate total value across all items.
          double totalValue = 0;
          String? currency;
          for (final item in items) {
            if (item.purchasePrice != null) {
              totalValue += item.purchasePrice!;
              currency ??= item.purchaseCurrency;
            }
          }

          return Column(
            children: [
              // Summary bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryTile(
                      label: 'Items',
                      value: items.length.toString(),
                    ),
                    _SummaryTile(
                      label: 'Platforms',
                      value: platforms.length.toString(),
                    ),
                    if (drafts.isNotEmpty)
                      _SummaryTile(
                        label: 'Drafts',
                        value: drafts.length.toString(),
                      ),
                    if (totalValue > 0)
                      _SummaryTile(
                        label: 'Total Value',
                        value:
                            '${totalValue.toStringAsFixed(0)} ${currency ?? ''}',
                      ),
                  ],
                ),
              ),
              // Items list: drafts first, then grouped by platform.
              Expanded(
                child: ListView(
                  children: [
                    if (drafts.isNotEmpty) _DraftsSection(items: drafts),
                    for (final platform in platforms) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          platform.toUpperCase(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      for (final item in grouped[platform]!)
                        CollectionTile(item: item),
                    ],
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

class _DraftsSection extends StatelessWidget {
  final List<CollectionItem> items;
  const _DraftsSection({required this.items});

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
        for (final item in items) CollectionTile(item: item),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
