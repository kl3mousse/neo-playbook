import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/scores_service.dart';

class SubmitScoreSheet extends StatefulWidget {
  final String gameId;
  const SubmitScoreSheet({super.key, required this.gameId});

  @override
  State<SubmitScoreSheet> createState() => _SubmitScoreSheetState();
}

class _SubmitScoreSheetState extends State<SubmitScoreSheet> {
  final _scoreController = TextEditingController();
  String _platform = 'MVS';
  Uint8List? _proofBytes;
  String? _proofName;
  bool _submitting = false;

  final _platforms = ['MVS', 'AES', 'NGCD', 'CPS1', 'CPS2', 'Emulator', 'Other'];

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _proofBytes = bytes;
        _proofName = image.name;
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _proofBytes = bytes;
        _proofName = image.name;
      });
    }
  }

  Future<void> _submit() async {
    final score = int.tryParse(_scoreController.text.trim());
    if (score == null || score <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid score')),
      );
      return;
    }
    if (_proofBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo proof is required')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ScoresService.submitScore(
        gameId: widget.gameId,
        score: score,
        proofImageBytes: _proofBytes!,
        platform: _platform,
      );
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
    _scoreController.dispose();
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
            Text('Submit Score',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            // Score input
            TextField(
              controller: _scoreController,
              decoration: const InputDecoration(
                labelText: 'Score',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            // Platform picker
            DropdownButtonFormField<String>(
              value: _platform,
              decoration: const InputDecoration(
                labelText: 'Platform',
                border: OutlineInputBorder(),
              ),
              items: _platforms
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _platform = v);
              },
            ),
            const SizedBox(height: 12),
            // Photo proof
            Text('Proof Photo *',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ],
            ),
            if (_proofBytes != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _proofBytes!,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              Text(_proofName ?? 'Photo selected',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
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
                    : const Text('Submit Score'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
