import 'package:flutter/material.dart';

import '../models/collection_item.dart';
import '../screens/collection_item_detail_screen.dart';
import '../services/user_service.dart';
import '../theme/combofox_theme.dart';

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
    final hasPhoto = item.imagePaths.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _LeadingThumb(
          imagePath: hasPhoto ? item.imagePaths.first : null,
        ),
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
        trailing: _Trailing(item: item, pricesHidden: pricesHidden),
      ),
    );
  }
}

// ── Leading thumbnail / placeholder ─────────────────────────────────

class _LeadingThumb extends StatelessWidget {
  final String? imagePath;
  const _LeadingThumb({this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) {
      // No photo — show a muted placeholder so the user can spot it easily.
      return Tooltip(
        message: 'No photo yet',
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 22,
            color: const Color(0xFFFBBF24).withValues(alpha: 0.65),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: _StorageThumb(path: imagePath!),
      ),
    );
  }
}

class _StorageThumb extends StatelessWidget {
  final String path;
  const _StorageThumb({required this.path});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: UserService.resolveCollectionItemPhotoUrl(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            color: ComboFoxColors.surfaceElevated,
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          );
        }
        final url = snapshot.data;
        if (url == null) {
          return Container(
            color: ComboFoxColors.surfaceElevated,
            child: const Icon(Icons.broken_image_outlined, size: 20),
          );
        }
        return Image.network(url, fit: BoxFit.cover);
      },
    );
  }
}

// ── Trailing area ────────────────────────────────────────────────────

class _Trailing extends StatelessWidget {
  final CollectionItem item;
  final bool pricesHidden;
  const _Trailing({required this.item, required this.pricesHidden});

  @override
  Widget build(BuildContext context) {
    if (item.isUnverified) {
      return Chip(
        avatar: const Icon(Icons.flag_outlined, size: 16),
        label: const Text('Draft'),
        visualDensity: VisualDensity.compact,
      );
    }
    if (item.purchasePrice != null) {
      final priceLabel = pricesHidden
          ? '•••'
          : '${item.purchasePrice!.toStringAsFixed(0)} ${item.purchaseCurrency ?? ''}';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          const SizedBox(width: 4),
          item.isCustomEntry
              ? const Icon(Icons.extension_outlined, size: 20)
              : const Icon(Icons.chevron_right),
        ],
      );
    }
    return item.isCustomEntry
        ? Chip(
            avatar: const Icon(Icons.extension_outlined, size: 16),
            label: const Text('Off-catalog'),
            visualDensity: VisualDensity.compact,
          )
        : const Icon(Icons.chevron_right);
  }
}
