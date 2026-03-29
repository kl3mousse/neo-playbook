import 'package:flutter/material.dart';
import '../models/collection_item.dart';
import '../services/user_service.dart';

class AddToCollectionSheet extends StatefulWidget {
  final String gameId;
  final String gameTitle;
  final CollectionItem? existingItem;
  const AddToCollectionSheet({
    super.key,
    required this.gameId,
    required this.gameTitle,
    this.existingItem,
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

  @override
  void initState() {
    super.initState();
    final e = widget.existingItem;
    _platform = e?.platform ?? 'mvs';
    _format = e?.format ?? ItemFormat.cartridge;
    _condition = e?.condition ?? ItemCondition.good;
    _region = e?.region ?? 'jp';
    _priceController = TextEditingController(
      text: e?.purchasePrice?.toStringAsFixed(2) ?? '',
    );
    _currency = e?.purchaseCurrency ?? 'USD';
    _notesController = TextEditingController(text: e?.notes ?? '');
  }

  final _platformOptions = ['mvs', 'aes', 'ngcd', 'cps1', 'cps2'];
  final _regionOptions = ['jp', 'us', 'eu', 'kr'];
  final _currencyOptions = ['USD', 'EUR', 'JPY', 'GBP'];

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final price = double.tryParse(_priceController.text.trim());
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
      );
      if (widget.isEditing) {
        await UserService.updateCollectionItem(
            widget.existingItem!.id, item);
      } else {
        await UserService.addToCollection(item);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
            Text(widget.isEditing ? 'Edit Item' : 'Add to Collection',
                style: Theme.of(context).textTheme.titleMedium),
            Text(widget.gameTitle,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            // Platform
            DropdownButtonFormField<String>(
              value: _platform,
              decoration: const InputDecoration(
                labelText: 'Platform',
                border: OutlineInputBorder(),
              ),
              items: _platformOptions
                  .map((p) => DropdownMenuItem(
                      value: p, child: Text(p.toUpperCase())))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _platform = v);
              },
            ),
            const SizedBox(height: 12),
            // Format
            DropdownButtonFormField<ItemFormat>(
              value: _format,
              decoration: const InputDecoration(
                labelText: 'Format',
                border: OutlineInputBorder(),
              ),
              items: ItemFormat.values
                  .map((f) =>
                      DropdownMenuItem(value: f, child: Text(f.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _format = v);
              },
            ),
            const SizedBox(height: 12),
            // Condition
            DropdownButtonFormField<ItemCondition>(
              value: _condition,
              decoration: const InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(),
              ),
              items: ItemCondition.values
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _condition = v);
              },
            ),
            const SizedBox(height: 12),
            // Region
            DropdownButtonFormField<String>(
              value: _region,
              decoration: const InputDecoration(
                labelText: 'Region',
                border: OutlineInputBorder(),
              ),
              items: _regionOptions
                  .map((r) => DropdownMenuItem(
                      value: r, child: Text(r.toUpperCase())))
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
                    value: _currency,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _currencyOptions
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
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
                    : Text(widget.isEditing ? 'Save Changes' : 'Add to Collection'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
