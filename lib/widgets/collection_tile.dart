import 'package:flutter/material.dart';

import '../models/collection_item.dart';
import '../screens/collection_item_detail_screen.dart';

class CollectionTile extends StatelessWidget {
  final CollectionItem item;
  const CollectionTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(item.gameTitle),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CollectionItemDetailScreen(
              itemId: item.id,
              initialItem: item,
            ),
          ),
        ),
        subtitle: Text(
          [
            item.format.label,
            item.condition.label,
            if (item.region.isNotEmpty) item.region.toUpperCase(),
            if (item.purchasePrice != null)
              '${item.purchasePrice!.toStringAsFixed(0)} ${item.purchaseCurrency ?? ''}',
            if (item.notes != null && item.notes!.isNotEmpty) item.notes!,
          ].join(' · '),
        ),
        trailing: item.isUnverified
            ? Chip(
                avatar: const Icon(Icons.flag_outlined, size: 16),
                label: const Text('Draft · Unverified'),
                visualDensity: VisualDensity.compact,
              )
            : item.isCustomEntry
                ? Chip(
                    avatar: const Icon(Icons.extension_outlined, size: 16),
                    label: const Text('Off-catalog'),
                    visualDensity: VisualDensity.compact,
                  )
                : const Icon(Icons.chevron_right),
      ),
    );
  }
}
