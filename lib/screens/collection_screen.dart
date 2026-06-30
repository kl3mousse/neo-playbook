import 'package:flutter/material.dart';
import '../models/collection_item.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../widgets/collection_scan_sheet.dart';
import '../widgets/collection_tile.dart';
import '../widgets/sign_in_prompt.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

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

          // Group items by platform
          final grouped = <String, List<CollectionItem>>{};
          for (final item in items) {
            grouped.putIfAbsent(item.platform, () => []).add(item);
          }
          final platforms = grouped.keys.toList()..sort();

          // Calculate total value
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
                    if (totalValue > 0)
                      _SummaryTile(
                        label: 'Total Value',
                        value:
                            '${totalValue.toStringAsFixed(0)} ${currency ?? ''}',
                      ),
                  ],
                ),
              ),
              // Items list grouped by platform
              Expanded(
                child: ListView.builder(
                  itemCount: platforms.length,
                  itemBuilder: (context, index) {
                    final platform = platforms[index];
                    final platformItems = grouped[platform]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            platform.toUpperCase(),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...platformItems.map(
                          (item) => CollectionTile(item: item),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
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


