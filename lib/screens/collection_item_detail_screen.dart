import 'package:flutter/material.dart';
import '../models/collection_item.dart';
import '../models/platform_template.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../theme/combofox_theme.dart';
import '../theme/platform_palette.dart';
import '../widgets/arcade_panel.dart';
import '../widgets/photo_viewer.dart';
import 'collection_item_edit_screen.dart';

/// Polished, arcade-styled detail page for a user-owned collection item.
class CollectionItemDetailScreen extends StatelessWidget {
  final String itemId;
  final CollectionItem initialItem;

  const CollectionItemDetailScreen({
    super.key,
    required this.itemId,
    required this.initialItem,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<CollectionItem?>(
        stream: UserService.collectionItemStream(itemId),
        initialData: initialItem,
        builder: (context, snapshot) {
          final item = snapshot.data;
          if (item == null) {
            // Item was deleted — leave the screen.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(context)) Navigator.pop(context);
            });
            return const Center(child: CircularProgressIndicator());
          }
          return _DetailBody(item: item);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final CollectionItem item;
  const _DetailBody({required this.item});

  PlatformTemplate get _template => platformTemplate(item.platform);

  Future<void> _edit(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CollectionItemEditScreen(item: item)),
    );
  }

  Future<void> _markVerified(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await UserService.markCollectionItemVerified(item.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Item marked as verified')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = platformPalette(item.platform);
    final badges = computeBadges(item, _template);
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 220,
          backgroundColor: palette.start,
          actions: [
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(context),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _Header(item: item, palette: palette),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.isUnverified) ...[
                  _draftBanner(context),
                  const SizedBox(height: 16),
                ],
                if (badges.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: badges.map((b) => _Badge(badge: b)).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                _myCopySection(context),
                const SizedBox(height: 16),
                if (item.imagePaths.isNotEmpty) ...[
                  _photosSection(context),
                  const SizedBox(height: 16),
                ],
                if (_ownedComponents.isNotEmpty) ...[
                  _componentsSection(context),
                  const SizedBox(height: 16),
                ],
                if (_template.fields.isNotEmpty) ...[
                  _platformDetailsSection(context),
                  const SizedBox(height: 16),
                ],
                if (_hasAcquisitionInfo) ...[
                  _acquisitionSection(context),
                  const SizedBox(height: 16),
                ],
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  _notesSection(context),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Sections ────────────────────────────────────────────────────────

  Widget _draftBanner(BuildContext context) {
    const warning = Color(0xFFFBBF24);
    return ArcadePanel(
      accentColor: warning,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined, color: warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Draft — needs your review',
                  style: TextStyle(
                    color: warning,
                    fontFamily: 'Doto',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'This item was auto-created from a low-confidence scan. '
            'Review the details and confirm — or open the editor to fix them.',
            style: TextStyle(
              color: ComboFoxColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _markVerified(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Mark verified'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Review & edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panel(String title, Color accent, List<Widget> children) {
    return ArcadePanel(
      accentColor: accent,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeonSectionHeader(title),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _myCopySection(BuildContext context) {
    final rows = <Widget>[
      _kv('Ownership', item.ownershipStatus.label),
      _kv('Copy type', item.copyType.label),
      _kv('Condition', item.condition.label),
      _kv('Working', item.workingStatus.label),
      if (item.region.isNotEmpty) _kv('Region', item.region.toUpperCase()),
      if (item.language != null && item.language!.isNotEmpty)
        _kv('Language', item.language!),
      if (item.authenticityConfidence != null)
        _kv('Authenticity', item.authenticityConfidence!.label),
      if (item.serialNumber != null && item.serialNumber!.isNotEmpty)
        _kv('Serial', item.serialNumber!),
      if (item.lastTestedAt != null)
        _kv('Last tested', _fmtDate(item.lastTestedAt!.toDate())),
      if (item.storageLocation != null && item.storageLocation!.isNotEmpty)
        _kv('Storage', item.storageLocation!),
    ];
    return _panel('My Copy', ComboFoxColors.neonPink, rows);
  }

  bool get _hasAcquisitionInfo =>
      item.purchasePrice != null ||
      item.acquisitionDate != null ||
      (item.acquisitionSource != null && item.acquisitionSource!.isNotEmpty) ||
      item.currentEstimatedValue != null;

  Widget _acquisitionSection(BuildContext context) {
    final currency = item.purchaseCurrency ?? '';
    final rows = <Widget>[
      if (item.purchasePrice != null)
        _kv(
          'Acquired for',
          '${item.purchasePrice!.toStringAsFixed(0)} $currency'.trim(),
        ),
      if (item.acquisitionDate != null)
        _kv('Acquired on', _fmtDate(item.acquisitionDate!.toDate())),
      if (item.acquisitionSource != null && item.acquisitionSource!.isNotEmpty)
        _kv('Source', item.acquisitionSource!),
      if (item.currentEstimatedValue != null)
        _kv(
          'Est. value',
          '${item.currentEstimatedValue!.toStringAsFixed(0)} $currency'.trim(),
        ),
    ];
    return _panel('Acquisition', ComboFoxColors.neonBlue, rows);
  }

  Widget _photosSection(BuildContext context) {
    return _panel('Photos', ComboFoxColors.neonBlue, [
      SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: item.imagePaths.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            return GestureDetector(
              onTap: () => openPhotoViewer(
                context,
                photos: item.imagePaths
                    .map((p) => PhotoSource.storage(p))
                    .toList(),
                initialIndex: i,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 110,
                  height: 110,
                  child: _PhotoThumb(path: item.imagePaths[i]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  List<ComponentSpec> get _ownedComponents => [
    for (final spec in _template.components)
      if (item.components[spec.key]?.present ?? false) spec,
  ];

  Widget _componentsSection(BuildContext context) {
    return _panel('Collector Components', ComboFoxColors.neonPurple, [
      for (final spec in _ownedComponents) _componentRow(context, spec),
    ]);
  }

  Widget _componentRow(BuildContext context, ComponentSpec spec) {
    final state = item.components[spec.key];
    final present = state?.present ?? false;
    final detail = <String>[
      if (state?.originality != null) state!.originality!.label,
      if (state?.condition != null) state!.condition!.label,
      if (state?.serialNumber != null && state!.serialNumber!.isNotEmpty)
        'SN ${state.serialNumber}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            present ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: present
                ? const Color(0xFF4ADE80)
                : ComboFoxColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.label,
                  style: TextStyle(
                    color: present
                        ? AppColors.textPrimary
                        : ComboFoxColors.textSecondary,
                    fontWeight: spec.important
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                if (present && detail.isNotEmpty)
                  Text(
                    detail,
                    style: const TextStyle(
                      color: ComboFoxColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _platformDetailsSection(BuildContext context) {
    final rows = <Widget>[];
    for (final spec in _template.fields) {
      final value = item.platformFields[spec.key];
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      if (value is bool && value == false) continue;
      final display = value is bool ? 'Yes' : value.toString();
      rows.add(_kv(spec.label, display));
    }
    if (rows.isEmpty) {
      rows.add(
        const Text(
          'No platform details recorded yet.',
          style: TextStyle(color: ComboFoxColors.textSecondary, fontSize: 13),
        ),
      );
    }
    return _panel(
      'Platform Details',
      platformPalette(item.platform).accent,
      rows,
    );
  }

  Widget _notesSection(BuildContext context) {
    return _panel('Notes', ComboFoxColors.neonBlue, [
      Text(
        item.notes!,
        style: const TextStyle(height: 1.5, color: AppColors.textPrimary),
      ),
    ]);
  }

  // ── Small helpers ───────────────────────────────────────────────────

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              key,
              style: const TextStyle(
                color: ComboFoxColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ── Header ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final CollectionItem item;
  final PlatformPalette palette;
  const _Header({required this.item, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Photo background if available, else gradient.
        if (item.imagePaths.isNotEmpty)
          _PhotoThumb(path: item.imagePaths.first, fit: BoxFit.cover)
        else
          DecoratedBox(decoration: BoxDecoration(gradient: palette.gradient)),
        // Darkening scrim for text legibility.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.25),
                Colors.black.withValues(alpha: 0.78),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  [
                    palette.label,
                    if (item.region.isNotEmpty) item.region.toUpperCase(),
                  ].join(' · '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.gameTitle.isEmpty ? 'Unknown game' : item.gameTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontFamily: 'Doto',
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black87)],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _HeaderChip(
                    icon: _visibilityIcon(item.visibility),
                    label: item.visibility.label,
                  ),
                  const SizedBox(width: 8),
                  _HeaderChip(
                    icon: Icons.inventory_2_outlined,
                    label: item.ownershipStatus.label,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _visibilityIcon(ItemVisibility v) {
    switch (v) {
      case ItemVisibility.private:
        return Icons.lock_outline;
      case ItemVisibility.friends:
        return Icons.group_outlined;
      case ItemVisibility.community:
        return Icons.public;
    }
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final CollectionBadge badge;
  const _Badge({required this.badge});

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(badge.tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        badge.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static Color _toneColor(BadgeTone tone) {
    switch (tone) {
      case BadgeTone.positive:
        return const Color(0xFF4ADE80);
      case BadgeTone.info:
        return ComboFoxColors.neonBlue;
      case BadgeTone.neutral:
        return ComboFoxColors.textSecondary;
      case BadgeTone.warning:
        return const Color(0xFFFBBF24);
      case BadgeTone.danger:
        return const Color(0xFFF87171);
    }
  }
}

/// Resolves and renders a collection photo by storage path.
class _PhotoThumb extends StatelessWidget {
  final String path;
  final BoxFit fit;
  const _PhotoThumb({required this.path, this.fit = BoxFit.cover});

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
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final url = snapshot.data;
        if (url == null) {
          return Container(
            color: ComboFoxColors.surfaceElevated,
            child: const Icon(Icons.broken_image_outlined),
          );
        }
        return Image.network(url, fit: fit);
      },
    );
  }
}
