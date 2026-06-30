import 'package:flutter/material.dart';

import '../models/collection_item.dart';
import '../screens/collection_item_detail_screen.dart';
import '../services/user_service.dart';

class CollectionTile extends StatelessWidget {
  final CollectionItem item;
  const CollectionTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CollectionTileThumbnail(item: item),
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
            item.region.toUpperCase(),
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
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class CollectionTileThumbnail extends StatelessWidget {
  final CollectionItem item;
  const CollectionTileThumbnail({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.imagePaths.isEmpty) {
      return CircleAvatar(
        backgroundColor:
            Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.videogame_asset_outlined),
      );
    }
    final path = item.imagePaths.first;
    return FutureBuilder<String>(
      future: UserService.resolveCollectionItemPhotoUrl(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CircleAvatar(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final url = snapshot.data;
        if (url == null) {
          return const CircleAvatar(
            child: Icon(Icons.broken_image_outlined),
          );
        }
        return CircleAvatar(backgroundImage: NetworkImage(url));
      },
    );
  }
}
