import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/collection_item.dart';
import '../services/user_service.dart';

class AddToCollectionSheet extends StatefulWidget {
  final String gameId;
  final String gameTitle;
  final CollectionItem? existingItem;
  final String? initialPlatform;
  const AddToCollectionSheet({
    super.key,
    required this.gameId,
    required this.gameTitle,
    this.existingItem,
    this.initialPlatform,
  });

  bool get isEditing => existingItem != null;

  @override
  State<AddToCollectionSheet> createState() => _AddToCollectionSheetState();
}

class _AddToCollectionSheetState extends State<AddToCollectionSheet> {
  late String _platform;
  late ItemFormat _format;
  late ItemCondition _condition;
  late String _region;
  late final TextEditingController _priceController;
  late String _currency;
  late final TextEditingController _notesController;
  bool _submitting = false;

  final _imagePicker = ImagePicker();
  late List<String> _existingPhotoPaths;
  final List<String> _removedPhotoPaths = [];
  final List<_PendingPhoto> _newPhotos = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existingItem;
    _platform = e?.platform ?? widget.initialPlatform ?? 'mvs';
    _format = e?.format ?? ItemFormat.cartridge;
    _condition = e?.condition ?? ItemCondition.good;
    _region = e?.region ?? 'jp';
    _priceController = TextEditingController(
      text: e?.purchasePrice?.toStringAsFixed(2) ?? '',
    );
    _currency = e?.purchaseCurrency ?? 'USD';
    _notesController = TextEditingController(text: e?.notes ?? '');
    _existingPhotoPaths = List<String>.from(e?.imagePaths ?? const []);
  }

  final _platformOptions = ['mvs', 'aes', 'ngcd', 'cps1', 'cps2'];
  final _regionOptions = ['jp', 'us', 'eu', 'kr'];
  final _currencyOptions = ['USD', 'EUR', 'JPY', 'GBP'];

  Future<void> _pickPhoto(ImageSource source) async {
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Photo failed: $e')));
      }
    }
  }

  void _removeExistingPhoto(String path) {
    setState(() {
      _existingPhotoPaths.remove(path);
      if (!_removedPhotoPaths.contains(path)) {
        _removedPhotoPaths.add(path);
      }
    });
  }

  void _removePendingPhoto(_PendingPhoto pending) {
    setState(() {
      _newPhotos.remove(pending);
    });
  }

  Future<List<String>> _uploadPendingPhotos(String itemId) async {
    final paths = <String>[];
    for (final pending in _newPhotos) {
      final path = await UserService.uploadCollectionItemPhoto(
        itemId: itemId,
        bytes: pending.bytes,
        contentType: 'image/jpeg',
        fileName: pending.fileName,
      );
      paths.add(path);
    }
    return paths;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final price = double.tryParse(_priceController.text.trim());
      final retainedPaths = List<String>.from(_existingPhotoPaths);

      final item = CollectionItem(
        id: '',
        gameId: widget.gameId,
        gameTitle: widget.gameTitle,
        platform: _platform,
        format: _format,
        condition: _condition,
        region: _region,
        purchasePrice: price,
        purchaseCurrency: price != null ? _currency : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        imagePaths: retainedPaths,
        isUnverified: widget.isEditing
            ? false
            : (widget.existingItem?.isUnverified ?? false),
        scanJobId: widget.existingItem?.scanJobId,
        scanCandidateId: widget.existingItem?.scanCandidateId,
        recognitionConfidence: widget.existingItem?.recognitionConfidence,
        importSource: widget.existingItem?.importSource,
        verifiedAt:
            widget.isEditing && (widget.existingItem?.isUnverified ?? false)
            ? Timestamp.now()
            : widget.existingItem?.verifiedAt,
      );

      String? targetItemId;
      if (widget.isEditing) {
        targetItemId = widget.existingItem!.id;
        await UserService.updateCollectionItem(targetItemId, item);
      } else {
        targetItemId = await UserService.addToCollection(item);
      }

      if (targetItemId != null && _newPhotos.isNotEmpty) {
        final uploadedPaths = await _uploadPendingPhotos(targetItemId);
        for (final path in uploadedPaths) {
          await UserService.attachPhotoToCollectionItem(
            itemId: targetItemId,
            storagePath: path,
          );
        }
      }

      if (widget.isEditing && _removedPhotoPaths.isNotEmpty) {
        for (final path in _removedPhotoPaths) {
          await UserService.removePhotoFromCollectionItem(
            itemId: widget.existingItem!.id,
            storagePath: path,
          );
        }
      }
 else {
        await UserService.addToCollection(item);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEditing ? 'Edit Item' : 'Add to Collection',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              widget.gameTitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _PhotoGallerySection(
              existingPaths: _existingPhotoPaths,
              pendingPhotos: _newPhotos,
              onRemoveExisting: _removeExistingPhoto,
              onRemovePending: _removePendingPhoto,
              onPickCamera: () => _pickPhoto(ImageSource.camera),
              onPickGallery: () => _pickPhoto(ImageSource.gallery),
            ),
            const SizedBox(height: 16),
            // Platform
            DropdownButtonFormField<String>(
              initialValue: _platform,
              decoration: const InputDecoration(
                labelText: 'Platform',
                border: OutlineInputBorder(),
              ),
              items: _platformOptions
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _platform = v);
              },
            ),
            const SizedBox(height: 12),
            // Format
            DropdownButtonFormField<ItemFormat>(
              initialValue: _format,
              decoration: const InputDecoration(
                labelText: 'Format',
                border: OutlineInputBorder(),
              ),
              items: ItemFormat.values
                  .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _format = v);
              },
            ),
            const SizedBox(height: 12),
            // Condition
            DropdownButtonFormField<ItemCondition>(
              initialValue: _condition,
              decoration: const InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(),
              ),
              items: ItemCondition.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _condition = v);
              },
            ),
            const SizedBox(height: 12),
            // Region
            DropdownButtonFormField<String>(
              initialValue: _region,
              decoration: const InputDecoration(
                labelText: 'Region',
                border: OutlineInputBorder(),
              ),
              items: _regionOptions
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _region = v);
              },
            ),
            const SizedBox(height: 12),
            // Price + Currency
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price (optional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _currencyOptions
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _currency = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.isEditing ? 'Save Changes' : 'Add to Collection',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingPhoto {
  final Uint8List bytes;
  final String fileName;

  _PendingPhoto({required this.bytes, required this.fileName});
}

class _PhotoGallerySection extends StatelessWidget {
  final List<String> existingPaths;
  final List<_PendingPhoto> pendingPhotos;
  final ValueChanged<String> onRemoveExisting;
  final ValueChanged<_PendingPhoto> onRemovePending;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;

  const _PhotoGallerySection({
    required this.existingPaths,
    required this.pendingPhotos,
    required this.onRemoveExisting,
    required this.onRemovePending,
    required this.onPickCamera,
    required this.onPickGallery,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhotos = existingPaths.isNotEmpty || pendingPhotos.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (hasPhotos)
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final path in existingPaths)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ExistingPhotoThumb(
                      storagePath: path,
                      onRemove: () => onRemoveExisting(path),
                    ),
                  ),
                for (final pending in pendingPhotos)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _PendingPhotoThumb(
                      bytes: pending.bytes,
                      onRemove: () => onRemovePending(pending),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExistingPhotoThumb extends StatelessWidget {
  final String storagePath;
  final VoidCallback onRemove;

  const _ExistingPhotoThumb({
    required this.storagePath,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _PhotoThumbFrame(
      onRemove: onRemove,
      child: FutureBuilder<String>(
        future: UserService.resolveCollectionItemPhotoUrl(storagePath),
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
      ),
    );
  }
}

class _PendingPhotoThumb extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onRemove;

  const _PendingPhotoThumb({required this.bytes, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return _PhotoThumbFrame(
      onRemove: onRemove,
      child: Image.memory(bytes, fit: BoxFit.cover, width: 96, height: 96),
    );
  }
}

class _PhotoThumbFrame extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;

  const _PhotoThumbFrame({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: child,
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
}
