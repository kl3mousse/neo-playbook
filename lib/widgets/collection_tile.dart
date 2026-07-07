import 'package:flutter/material.dart';

import '../models/collection_item.dart';
import '../screens/collection_item_detail_screen.dart';

class CollectionTile extends StatelessWidget {
  final CollectionItem item;
  final bool pricesHidden;

  const CollectionTile({
    super.key,
    required this.item,
    this.pricesHidden = false,
  });

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
            if (item.notes != null && item.notes!.isNotEmpty) item.notes!,
          ].join(' · '),
        ),
        trailing: _Trailing(
          item: item,
          pricesHidden: pricesHidden,
          hasPhoto: item.imagePaths.isNotEmpty,
        ),
      ),
    );
  }
}

// ── Trailing area ────────────────────────────────────────────────────

class _Trailing extends StatelessWidget {
  final CollectionItem item;
  final bool pricesHidden;
  final bool hasPhoto;
  const _Trailing({
    required this.item,
    required this.pricesHidden,
    required this.hasPhoto,
  });

  @override
  Widget build(BuildContext context) {
    if (item.isUnverified) {
      return Chip(
        avatar: const Icon(Icons.flag_outlined, size: 16),
        label: const Text('Draft'),
        visualDensity: VisualDensity.compact,
      );
    }

    final trailingItems = <Widget>[];

    // Add "no photo" icon if missing
    if (!hasPhoto) {
      trailingItems.add(
        Tooltip(
          message: 'No photo',
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      );
    }

    if (item.purchasePrice != null) {
      final priceLabel = pricesHidden
          ? '•••'
          : '${item.purchasePrice!.toStringAsFixed(0)} ${item.purchaseCurrency ?? ''}';
      if (trailingItems.isNotEmpty) {
        trailingItems.add(const SizedBox(width: 8));
      }
      trailingItems.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.secondaryContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            priceLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: pricesHidden
                  ? Theme.of(context).colorScheme.outline
                  : Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      );
    }

    if (item.isCustomEntry) {
      if (trailingItems.isNotEmpty) {
        trailingItems.add(const SizedBox(width: 4));
      }
      trailingItems.add(const Icon(Icons.extension_outlined, size: 20));
    } else if (trailingItems.isEmpty) {
      trailingItems.add(const Icon(Icons.chevron_right));
    } else {
      trailingItems.add(const SizedBox(width: 4));
      trailingItems.add(const Icon(Icons.chevron_right));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: trailingItems,
    );
  }
}
