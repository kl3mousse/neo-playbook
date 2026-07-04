import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/collection_item.dart';
import '../models/platform_template.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../theme/combofox_theme.dart';
import '../theme/platform_palette.dart';
import '../widgets/arcade_panel.dart';
import '../widgets/game_picker_sheet.dart';
import '../widgets/photo_viewer.dart';
import '../widgets/picture_source_sheet.dart';

/// Full-page editor for a user-owned collection item (a game copy).
class CollectionItemEditScreen extends StatefulWidget {
  final CollectionItem item;
  const CollectionItemEditScreen({super.key, required this.item});

  @override
  State<CollectionItemEditScreen> createState() =>
      _CollectionItemEditScreenState();
}

class _PendingPhoto {
  final Uint8List bytes;
  final String fileName;
  _PendingPhoto({required this.bytes, required this.fileName});
}

class _CollectionItemEditScreenState extends State<CollectionItemEditScreen> {
  final _imagePicker = ImagePicker();

  // Linked game.
  late String _gameId;
  late String _gameTitle;
  late String _platform;

  // Core fields.
  late OwnershipStatus _ownership;
  late ItemVisibility _visibility;
  late CopyType _copyType;
  late ItemCondition _condition;
  late WorkingStatus _working;
  late String _region;
  AuthenticityConfidence? _authenticity;
  Timestamp? _lastTestedAt;
  Timestamp? _acquisitionDate;
  String _currency = 'USD';

  // Controllers.
  late final TextEditingController _languageController;
  late final TextEditingController _priceController;
  late final TextEditingController _estValueController;
  late final TextEditingController _sourceController;
  late final TextEditingController _storageController;
  late final TextEditingController _serialController;
  late final TextEditingController _notesController;

  // Photos.
  late List<String> _existingPhotos;
  final List<String> _removedPhotos = [];
  final List<_PendingPhoto> _newPhotos = [];

  // Components & platform fields working state.
  late Map<String, ComponentState> _components;
  late Map<String, dynamic> _platformFields;

  // Draft / verification state.
  late bool _wasUnverified;
  late bool _markVerifiedOnSave;

  bool _saving = false;

  final _regionOptions = const ['jp', 'us', 'eu', 'kr', 'asia', 'world'];
  final _currencyOptions = const ['USD', 'EUR', 'JPY', 'GBP'];

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _gameId = i.gameId;
    _gameTitle = i.gameTitle;
    _platform = i.platform.isEmpty ? 'mvs' : i.platform;
    _ownership = i.ownershipStatus;
    _visibility = i.visibility;
    _copyType = i.copyType;
    _condition = i.condition;
    _working = i.workingStatus;
    _region = i.region.isEmpty ? 'jp' : i.region;
    _authenticity = i.authenticityConfidence;
    _lastTestedAt = i.lastTestedAt;
    _acquisitionDate = i.purchaseDate;
    _currency = i.purchaseCurrency ?? 'USD';
    _languageController = TextEditingController(text: i.language ?? '');
    _priceController = TextEditingController(
      text: i.purchasePrice?.toStringAsFixed(2) ?? '',
    );
    _estValueController = TextEditingController(
      text: i.currentEstimatedValue?.toStringAsFixed(2) ?? '',
    );
    _sourceController = TextEditingController(text: i.acquisitionSource ?? '');
    _storageController = TextEditingController(text: i.storageLocation ?? '');
    _serialController = TextEditingController(text: i.serialNumber ?? '');
    _notesController = TextEditingController(text: i.notes ?? '');
    _existingPhotos = List<String>.from(i.imagePaths);
    _components = Map<String, ComponentState>.from(i.components);
    _platformFields = Map<String, dynamic>.from(i.platformFields);
    _wasUnverified = i.isUnverified;
    // For drafts, default to promoting to "verified" once the user saves
    // their reviewed changes. Users can opt out by toggling the switch.
    _markVerifiedOnSave = i.isUnverified;
  }

  @override
  void dispose() {
    _languageController.dispose();
    _priceController.dispose();
    _estValueController.dispose();
    _sourceController.dispose();
    _storageController.dispose();
    _serialController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  PlatformTemplate get _template => platformTemplate(_platform);

  // ── Photo handling ──────────────────────────────────────────────────

  Future<void> _addPhoto() async {
    final source = await showPictureSourceSheet(context);
    if (source == null) return;
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _newPhotos.add(_PendingPhoto(bytes: bytes, fileName: image.name));
      });
    } catch (e) {
      _showError('Photo failed: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Change game ─────────────────────────────────────────────────────

  Future<void> _changeGame() async {
    final result = await showGamePicker(context, initialQuery: _gameTitle);
    if (result == null || !mounted) return;

    if (result.game != null) {
      final game = result.game!;
      final platformChanged =
          game.platform.toLowerCase() != _platform.toLowerCase();
      setState(() {
        _gameId = game.id;
        _gameTitle = game.title;
        if (game.platform.isNotEmpty) _platform = game.platform;
        if (platformChanged) {
          _platformFields = {};
          _components = {};
        }
        // Catalog games are never "off-catalog" — clear any custom labels.
        _platformFields.remove('custom_platform_label');
      });
      if (platformChanged) {
        _showError('Platform changed — platform-specific fields were reset.');
      }
    } else if (result.custom != null) {
      final draft = result.custom!;
      final platformChanged =
          draft.platformId.toLowerCase() != _platform.toLowerCase();
      setState(() {
        _gameId = '';
        _gameTitle = draft.title;
        _platform = draft.platformId;
        if (platformChanged) {
          _platformFields = {};
          _components = {};
        }
        if (draft.customPlatformLabel != null) {
          _platformFields['custom_platform_label'] =
              draft.customPlatformLabel;
        } else {
          _platformFields.remove('custom_platform_label');
        }
      });
      if (platformChanged) {
        _showError('Platform changed — platform-specific fields were reset.');
      }
    }
  }

  // ── Save ────────────────────────────────────────────────────────────

  double? _parseDouble(String text) => double.tryParse(text.trim());

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final itemId = widget.item.id;

      // Upload new item photos.
      final uploaded = <String>[];
      for (final p in _newPhotos) {
        final path = await UserService.uploadCollectionItemPhoto(
          itemId: itemId,
          bytes: p.bytes,
          contentType: 'image/jpeg',
          fileName: p.fileName,
        );
        uploaded.add(path);
      }
      final photos = [..._existingPhotos, ...uploaded];

      // Clean component map: drop entries that are absent and empty.
      final cleanedComponents = <String, ComponentState>{};
      _components.forEach((key, state) {
        final isEmpty = !state.present &&
            state.originality == null &&
            state.condition == null &&
            (state.serialNumber == null || state.serialNumber!.isEmpty) &&
            (state.notes == null || state.notes!.isEmpty) &&
            state.photoIds.isEmpty;
        if (!isEmpty) cleanedComponents[key] = state;
      });

      // Clean platform fields: drop empty values.
      final cleanedFields = <String, dynamic>{};
      _platformFields.forEach((key, value) {
        if (value == null) return;
        if (value is String && value.trim().isEmpty) return;
        if (value is bool && value == false) return;
        cleanedFields[key] = value;
      });

      final price = _parseDouble(_priceController.text);
      final estValue = _parseDouble(_estValueController.text);

      final notesText = _textOrNull(_notesController);

      final updated = widget.item.copyWith(
        gameId: _gameId,
        gameTitle: _gameTitle,
        platform: _platform,
        condition: _condition,
        region: _region,
        purchasePrice: price,
        purchaseCurrency: price != null ? _currency : null,
        purchaseDate: _acquisitionDate,
        acquisitionSource: _textOrNull(_sourceController),
        currentEstimatedValue: estValue,
        notes: notesText,
        clearNotes: notesText == null,
        imagePaths: photos,
        ownershipStatus: _ownership,
        visibility: _visibility,
        copyType: _copyType,
        language: _textOrNull(_languageController),
        workingStatus: _working,
        lastTestedAt: _lastTestedAt,
        storageLocation: _textOrNull(_storageController),
        serialNumber: _textOrNull(_serialController),
        authenticityConfidence: _authenticity,
        clearAuthenticity: _authenticity == null,
        components: cleanedComponents,
        platformFields: cleanedFields,
        isUnverified: _wasUnverified ? !_markVerifiedOnSave : false,
        verifiedAt: _wasUnverified && _markVerifiedOnSave
            ? Timestamp.now()
            : widget.item.verifiedAt,
      );

      await UserService.updateCollectionItem(itemId, updated);

      // Remove deleted photos from storage.
      for (final path in _removedPhotos) {
        await UserService.removePhotoFromCollectionItem(
          itemId: itemId,
          storagePath: path,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _textOrNull(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  // ── Delete ──────────────────────────────────────────────────────────

  Future<void> _delete() async {
    final scheme = Theme.of(context).colorScheme;
    final navigator = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove $_gameTitle from your collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await UserService.removeFromCollection(widget.item.id);
      navigator.pop(true);
    } catch (e) {
      _showError('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = platformPalette(_platform);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Item',
          style: TextStyle(fontFamily: 'Doto', fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (_wasUnverified) ...[
            _draftBanner(),
            const SizedBox(height: 16),
          ],
          _linkedGameSection(palette),
          const SizedBox(height: 16),
          _visibilitySection(),
          const SizedBox(height: 16),
          _myCopySection(),
          const SizedBox(height: 16),
          _photosSection(),
          const SizedBox(height: 16),
          if (_template.fields.isNotEmpty) ...[
            _platformFieldsSection(),
            const SizedBox(height: 16),
          ],
          _componentsSection(),
          const SizedBox(height: 16),
          _acquisitionSection(),
          const SizedBox(height: 16),
          _notesSection(),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _saving ? null : _delete,
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(
                color: Theme.of(context).colorScheme.error.withValues(
                  alpha: 0.6,
                ),
              ),
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete from collection'),
          ),
        ],
      ),
    );
  }

  // ── Sections ────────────────────────────────────────────────────────

  Widget _draftBanner() {
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
            'Check the game, platform and details, then save to confirm.',
            style: TextStyle(
              color: ComboFoxColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: _markVerifiedOnSave,
            onChanged: (v) => setState(() => _markVerifiedOnSave = v),
            title: const Text(
              'Mark as verified when I save',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            subtitle: Text(
              _markVerifiedOnSave
                  ? "The draft flag will be cleared once you tap Save."
                  : 'The item will stay marked as a draft after saving.',
              style: const TextStyle(
                color: ComboFoxColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionPanel(String title, Color accent, List<Widget> children) {
    return ArcadePanel(
      accentColor: accent,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeonSectionHeader(title),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _linkedGameSection(PlatformPalette palette) {
    final isCustom = _gameId.isEmpty;
    return _sectionPanel('Linked Game', ComboFoxColors.neonPurple, [
      Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: palette.gradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.videogame_asset, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _gameTitle.isEmpty ? 'Unknown game' : _gameTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  isCustom ? 'Off-catalog' : palette.label,
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
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _changeGame,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Change game'),
            ),
          ),
          // Off-catalog items allow editing the title in-place.
          if (isCustom) ...[
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _editCustomTitle,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit title'),
              ),
            ),
          ],
        ],
      ),
    ]);
  }

  Future<void> _editCustomTitle() async {
    final controller = TextEditingController(text: _gameTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit title'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Game title',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newTitle != null && newTitle.isNotEmpty && mounted) {
      setState(() => _gameTitle = newTitle);
    }
  }

  Widget _visibilitySection() {
    return _sectionPanel('Visibility', ComboFoxColors.neonBlue, [
      SegmentedButton<ItemVisibility>(
        segments: ItemVisibility.values
            .map(
              (v) => ButtonSegment(
                value: v,
                label: Text(v.label),
                icon: Icon(_visibilityIcon(v)),
              ),
            )
            .toList(),
        selected: {_visibility},
        showSelectedIcon: false,
        onSelectionChanged: (s) => setState(() => _visibility = s.first),
      ),
      const SizedBox(height: 8),
      Text(
        _visibility.description,
        style: const TextStyle(
          color: ComboFoxColors.textSecondary,
          fontSize: 12,
        ),
      ),
    ]);
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

  Widget _myCopySection() {
    return _sectionPanel('My Copy', ComboFoxColors.neonPink, [
      _dropdown<OwnershipStatus>(
        label: 'Ownership status',
        value: _ownership,
        items: OwnershipStatus.values,
        labelOf: (v) => v.label,
        onChanged: (v) => setState(() => _ownership = v),
      ),
      const SizedBox(height: 12),
      _dropdown<CopyType>(
        label: 'Copy type',
        value: _copyType,
        items: CopyType.values,
        labelOf: (v) => v.label,
        onChanged: (v) => setState(() => _copyType = v),
      ),
      const SizedBox(height: 12),
      _dropdown<ItemCondition>(
        label: 'Condition',
        value: _condition,
        items: ItemCondition.values,
        labelOf: (v) => v.label,
        onChanged: (v) => setState(() => _condition = v),
      ),
      const SizedBox(height: 12),
      _dropdown<WorkingStatus>(
        label: 'Working status',
        value: _working,
        items: WorkingStatus.values,
        labelOf: (v) => v.label,
        onChanged: (v) => setState(() => _working = v),
      ),
      const SizedBox(height: 12),
      _dateField(
        label: 'Last tested',
        value: _lastTestedAt,
        onChanged: (ts) => setState(() => _lastTestedAt = ts),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _dropdown<String>(
              label: 'Region',
              value: _region,
              items: _regionOptions,
              labelOf: (v) => v.toUpperCase(),
              onChanged: (v) => setState(() => _region = v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _languageController,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _dropdown<AuthenticityConfidence?>(
        label: 'Authenticity',
        value: _authenticity,
        items: const [null, ...AuthenticityConfidence.values],
        labelOf: (v) => v?.label ?? 'Not set',
        onChanged: (v) => setState(() => _authenticity = v),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _serialController,
        decoration: const InputDecoration(
          labelText: 'Serial number',
          border: OutlineInputBorder(),
        ),
      ),
    ]);
  }

  Widget _photosSection() {
    return _sectionPanel('Photos', ComboFoxColors.neonBlue, [
      if (_existingPhotos.isNotEmpty || _newPhotos.isNotEmpty)
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (int idx = 0; idx < _existingPhotos.length; idx++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _photoThumb(
                    child: _ExistingPhoto(path: _existingPhotos[idx]),
                    onTap: () => openPhotoViewer(
                      context,
                      photos: _existingPhotos
                          .map((p) => PhotoSource.storage(p))
                          .toList(),
                      initialIndex: idx,
                    ),
                    onRemove: () => setState(() {
                      _removedPhotos.add(_existingPhotos[idx]);
                      _existingPhotos.removeAt(idx);
                    }),
                  ),
                ),
              for (final pending in _newPhotos)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _photoThumb(
                    child: Image.memory(
                      pending.bytes,
                      fit: BoxFit.cover,
                      width: 96,
                      height: 96,
                    ),
                    onTap: () => openPhotoViewer(
                      context,
                      photos: [PhotoSource.bytes(pending.bytes)],
                    ),
                    onRemove: () => setState(() => _newPhotos.remove(pending)),
                  ),
                ),
            ],
          ),
        ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _addPhoto,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Picture'),
      ),
    ]);
  }

  Widget _platformFieldsSection() {
    final fields = _template.fields;
    return _sectionPanel(
      'Platform Details',
      platformPalette(_platform).accent,
      [
        for (int i = 0; i < fields.length; i++) ...[
          _platformFieldWidget(fields[i]),
          if (i != fields.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _platformFieldWidget(PlatformFieldSpec spec) {
    final value = _platformFields[spec.key];
    switch (spec.type) {
      case PlatformFieldType.toggle:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(spec.label),
          subtitle: spec.helpText == null ? null : Text(spec.helpText!),
          value: value == true,
          onChanged: (v) => setState(() => _platformFields[spec.key] = v),
        );
      case PlatformFieldType.dropdown:
        final current = value is String && spec.options.contains(value)
            ? value
            : null;
        return DropdownButtonFormField<String?>(
          initialValue: current,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: spec.label,
            helperText: spec.helpText,
            border: const OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('—')),
            ...spec.options.map(
              (o) => DropdownMenuItem<String?>(value: o, child: Text(o)),
            ),
          ],
          onChanged: (v) => setState(() {
            if (v == null) {
              _platformFields.remove(spec.key);
            } else {
              _platformFields[spec.key] = v;
            }
          }),
        );
      case PlatformFieldType.date:
        final ts = _stringToDate(value);
        return _dateField(
          label: spec.label,
          value: ts,
          helperText: spec.helpText,
          onChanged: (newTs) => setState(() {
            if (newTs == null) {
              _platformFields.remove(spec.key);
            } else {
              _platformFields[spec.key] = _dateToString(newTs);
            }
          }),
        );
      case PlatformFieldType.number:
        return TextFormField(
          initialValue: value?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: spec.label,
            helperText: spec.helpText,
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() {
            final n = num.tryParse(v.trim());
            if (n == null) {
              _platformFields.remove(spec.key);
            } else {
              _platformFields[spec.key] = n;
            }
          }),
        );
      case PlatformFieldType.text:
        return TextFormField(
          initialValue: value?.toString() ?? '',
          decoration: InputDecoration(
            labelText: spec.label,
            helperText: spec.helpText,
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() {
            final t = v.trim();
            if (t.isEmpty) {
              _platformFields.remove(spec.key);
            } else {
              _platformFields[spec.key] = t;
            }
          }),
        );
    }
  }

  Widget _componentsSection() {
    final specs = _template.components;
    return _sectionPanel('Collector Components', ComboFoxColors.neonPurple, [
      for (final spec in specs) _componentTile(spec),
    ]);
  }

  Widget _componentTile(ComponentSpec spec) {
    final state = _components[spec.key] ?? const ComponentState();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        title: Row(
          children: [
            Expanded(
              child: Text(
                spec.label,
                style: TextStyle(
                  fontWeight: spec.important ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: state.present,
              onChanged: (v) => setState(() {
                _components[spec.key] = state.copyWith(present: v);
              }),
            ),
          ],
        ),
        children: [
          _dropdown<ComponentOriginality?>(
            label: 'Originality',
            value: state.originality,
            items: const [null, ...ComponentOriginality.values],
            labelOf: (v) => v?.label ?? 'Not set',
            onChanged: (v) => setState(() {
              _components[spec.key] = state.copyWith(
                originality: v,
                clearOriginality: v == null,
              );
            }),
          ),
          const SizedBox(height: 12),
          _dropdown<ItemCondition?>(
            label: 'Condition',
            value: state.condition,
            items: const [null, ...ItemCondition.values],
            labelOf: (v) => v?.label ?? 'Not set',
            onChanged: (v) => setState(() {
              _components[spec.key] = state.copyWith(
                condition: v,
                clearCondition: v == null,
              );
            }),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: state.serialNumber ?? '',
            decoration: const InputDecoration(
              labelText: 'Serial number',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              _components[spec.key] = (_components[spec.key] ??
                      const ComponentState())
                  .copyWith(serialNumber: v.trim());
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: state.notes ?? '',
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (v) {
              _components[spec.key] = (_components[spec.key] ??
                      const ComponentState())
                  .copyWith(notes: v.trim());
            },
          ),
        ],
      ),
    );
  }

  Widget _acquisitionSection() {
    return _sectionPanel('Acquisition', ComboFoxColors.neonBlue, [
      Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _dropdown<String>(
              label: 'Currency',
              value: _currency,
              items: _currencyOptions,
              labelOf: (v) => v,
              onChanged: (v) => setState(() => _currency = v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _dateField(
        label: 'Acquisition date',
        value: _acquisitionDate,
        onChanged: (ts) => setState(() => _acquisitionDate = ts),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _sourceController,
        decoration: const InputDecoration(
          labelText: 'Acquisition source',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _estValueController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Current estimated value',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _storageController,
        decoration: const InputDecoration(
          labelText: 'Storage location',
          border: OutlineInputBorder(),
        ),
      ),
    ]);
  }

  Widget _notesSection() {
    return _sectionPanel('Notes', ComboFoxColors.neonPink, [
      TextField(
        controller: _notesController,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Notes',
          border: OutlineInputBorder(),
        ),
      ),
    ]);
  }

  // ── Small reusable controls ─────────────────────────────────────────

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map((v) => DropdownMenuItem<T>(value: v, child: Text(labelOf(v))))
          .toList(),
      onChanged: (v) {
        if (v != null || null is T) onChanged(v as T);
      },
    );
  }

  Widget _dateField({
    required String label,
    required Timestamp? value,
    required ValueChanged<Timestamp?> onChanged,
    String? helperText,
  }) {
    final dt = value?.toDate();
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: dt ?? DateTime.now(),
          firstDate: DateTime(1970),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (picked != null) onChanged(Timestamp.fromDate(picked));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
          suffixIcon: dt == null
              ? const Icon(Icons.calendar_today_outlined, size: 18)
              : IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(
          dt == null
              ? 'Not set'
              : '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: dt == null
                ? ComboFoxColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _photoThumb({
    required Widget child,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: ComboFoxColors.surfaceElevated,
                  child: child,
                ),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Timestamp? _stringToDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      final dt = DateTime.tryParse(value);
      if (dt != null) return Timestamp.fromDate(dt);
    }
    return null;
  }

  static String _dateToString(Timestamp ts) {
    final d = ts.toDate();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

/// Resolves and renders an existing collection photo thumbnail.
class _ExistingPhoto extends StatelessWidget {
  final String path;
  const _ExistingPhoto({required this.path});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: UserService.resolveCollectionItemPhotoUrl(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final url = snapshot.data;
        if (url == null) {
          return const Icon(Icons.broken_image_outlined);
        }
        return Image.network(url, fit: BoxFit.cover, width: 96, height: 96);
      },
    );
  }
}

