import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/collection_item.dart';
import '../models/scan_recognition_job.dart';
import '../services/collection_scan_service.dart';
import '../services/user_service.dart';
import 'add_to_collection_sheet.dart';

enum _ScanSheetMode { chooser, ownershipCheck, bulkImport }

class CollectionScanSheet extends StatefulWidget {
  const CollectionScanSheet({super.key});

  @override
  State<CollectionScanSheet> createState() => _CollectionScanSheetState();
}

class _CollectionScanSheetState extends State<CollectionScanSheet> {
  _ScanSheetMode _mode = _ScanSheetMode.chooser;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (_mode) {
            _ScanSheetMode.chooser => _ModeChooser(
              key: const ValueKey('chooser'),
              onSelectOwnership: () =>
                  setState(() => _mode = _ScanSheetMode.ownershipCheck),
              onSelectBulk: () =>
                  setState(() => _mode = _ScanSheetMode.bulkImport),
            ),
            _ScanSheetMode.ownershipCheck => _OwnershipCheckView(
              key: const ValueKey('ownership'),
              onBack: () => setState(() => _mode = _ScanSheetMode.chooser),
            ),
            _ScanSheetMode.bulkImport => _BulkImportView(
              key: const ValueKey('bulk'),
              onBack: () => setState(() => _mode = _ScanSheetMode.chooser),
            ),
          },
        ),
      ),
    );
  }
}

class _ModeChooser extends StatelessWidget {
  final VoidCallback onSelectOwnership;
  final VoidCallback onSelectBulk;

  const _ModeChooser({
    super.key,
    required this.onSelectOwnership,
    required this.onSelectBulk,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Scan Collection', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Choose how you want to scan games with your camera.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _ModeCard(
          icon: Icons.search,
          title: 'Ownership Check',
          subtitle:
              'Take a photo to check if a detected game is already owned.',
          actionLabel: 'Start Check',
          onTap: onSelectOwnership,
        ),
        const SizedBox(height: 12),
        _ModeCard(
          icon: Icons.library_add_check,
          title: 'Bulk Import',
          subtitle: 'Capture up to 10 photos and import recognized matches.',
          actionLabel: 'Start Import',
          onTap: onSelectBulk,
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onTap, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _OwnershipCheckView extends StatefulWidget {
  final VoidCallback onBack;

  const _OwnershipCheckView({super.key, required this.onBack});

  @override
  State<_OwnershipCheckView> createState() => _OwnershipCheckViewState();
}

class _OwnershipCheckViewState extends State<_OwnershipCheckView> {
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _jobId;
  bool _capturing = false;

  Future<void> _takePhoto() async {
    setState(() => _capturing = true);
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();
      final jobId = await CollectionScanService.submitScanJob(
        mode: RecognitionMode.ownershipCheck,
        imageBytes: bytes,
        fileName: image.name,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _jobId = jobId;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: widget.key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 4),
            Text(
              'Ownership Check',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Take one photo and compare with your current collection.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _capturing ? null : _takePhoto,
          icon: const Icon(Icons.camera_alt),
          label: Text(_capturing ? 'Capturing...' : 'Take Photo'),
        ),
        if (_imageBytes != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _imageBytes!,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
        if (_jobId != null) ...[
          const SizedBox(height: 12),
          StreamBuilder<ScanRecognitionJob?>(
            stream: CollectionScanService.watchJob(_jobId!),
            builder: (context, snapshot) {
              final job = snapshot.data;
              if (job == null ||
                  job.status == ScanJobStatus.queued ||
                  job.status == ScanJobStatus.processing) {
                return const _StatusCard(
                  icon: Icons.timelapse,
                  title: 'Analyzing image...',
                  subtitle: 'Recognition in progress',
                );
              }
              if (job.isFailed) {
                return _StatusCard(
                  icon: Icons.error_outline,
                  title: 'Recognition failed',
                  subtitle: job.errorMessage ?? 'Please try again',
                );
              }
              return _OwnershipResult(job: job);
            },
          ),
        ],
      ],
    );
  }
}

class _OwnershipResult extends StatelessWidget {
  final ScanRecognitionJob job;
  const _OwnershipResult({required this.job});

  @override
  Widget build(BuildContext context) {
    final best = job.bestMatch;
    if (best == null) {
      return const _StatusCard(
        icon: Icons.help_outline,
        title: 'No confident match',
        subtitle: 'Try another photo angle or better lighting.',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              best.gameTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${best.platform.toUpperCase()} · confidence ${(best.combinedConfidence * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<CollectionItem>>(
              future: UserService.getCollectionForGame(best.gameId),
              builder: (context, snapshot) {
                final owned = (snapshot.data?.isNotEmpty ?? false);
                return Row(
                  children: [
                    Icon(
                      owned ? Icons.check_circle : Icons.info_outline,
                      color: owned
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        owned
                            ? 'Already in your collection'
                            : 'Not currently in your collection',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AddToCollectionSheet(
                    gameId: best.gameId,
                    gameTitle: best.gameTitle,
                    initialPlatform: best.platform,
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Open Add to Collection'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkImportView extends StatefulWidget {
  final VoidCallback onBack;

  const _BulkImportView({super.key, required this.onBack});

  @override
  State<_BulkImportView> createState() => _BulkImportViewState();
}

class _BulkImportViewState extends State<_BulkImportView> {
  final _picker = ImagePicker();
  final List<String> _jobIds = [];
  final Set<String> _autoDraftedJobIds = {};
  final Set<String> _manuallyImportedJobIds = {};
  final Map<String, StreamSubscription<ScanRecognitionJob?>> _subscriptions =
      {};
  bool _capturing = false;

  @override
  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _captureAndQueue() async {
    if (_jobIds.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch limit reached (10 photos)')),
      );
      return;
    }

    setState(() => _capturing = true);
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();
      final jobId = await CollectionScanService.submitScanJob(
        mode: RecognitionMode.bulkImport,
        imageBytes: bytes,
        fileName: image.name,
      );
      if (!mounted) {
        return;
      }

      setState(() => _jobIds.insert(0, jobId));
      _attachJobListener(jobId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  void _attachJobListener(String jobId) {
    if (_subscriptions.containsKey(jobId)) {
      return;
    }

    _subscriptions[jobId] = CollectionScanService.watchJob(jobId).listen((
      job,
    ) async {
      if (job == null ||
          !job.isCompleted ||
          _autoDraftedJobIds.contains(job.id)) {
        return;
      }

      final best = job.bestMatch;
      final shouldAutoDraft = best == null || best.combinedConfidence < 0.45;
      if (!shouldAutoDraft) {
        return;
      }

      _autoDraftedJobIds.add(job.id);
      if (mounted) {
        setState(() {});
      }

      if (best == null) {
        final fallbackTitle = job.detectedGames.isNotEmpty
            ? job.detectedGames.first.rawTitle
            : 'Unidentified Game';
        final fallbackPlatform = job.detectedGames.isNotEmpty
            ? (job.detectedGames.first.normalizedPlatform.isNotEmpty
                  ? job.detectedGames.first.normalizedPlatform
                  : 'mvs')
            : 'mvs';

        await UserService.importRecognizedItem(
          scanJobId: job.id,
          gameId: '',
          gameTitle: fallbackTitle.isNotEmpty
              ? fallbackTitle
              : 'Unidentified Game',
          platform: fallbackPlatform,
          confidence: job.bestModelConfidence,
          unverified: true,
          notes:
              'Auto-created from low-confidence scan. Please review details.',
        );
      } else {
        await UserService.importRecognizedItem(
          scanJobId: job.id,
          gameId: best.gameId,
          gameTitle: best.gameTitle,
          platform: best.platform,
          confidence: best.combinedConfidence,
          unverified: true,
          notes:
              'Auto-created from low-confidence scan. Please review details.',
        );
      }

      await UserService.markScanJobImported(job.id, 'draft_auto_created');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unverified draft created from scan')),
        );
      }
    });
  }

  Future<void> _importMatch(ScanRecognitionJob job) async {
    final best = job.bestMatch;
    if (best == null || _manuallyImportedJobIds.contains(job.id)) {
      return;
    }

    await UserService.importRecognizedItem(
      scanJobId: job.id,
      gameId: best.gameId,
      gameTitle: best.gameTitle,
      platform: best.platform,
      confidence: best.combinedConfidence,
      unverified: false,
      notes: 'Imported from camera scan.',
    );
    await UserService.markScanJobImported(job.id, 'imported');
    if (!mounted) {
      return;
    }

    setState(() => _manuallyImportedJobIds.add(job.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported ${best.gameTitle} to collection')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: widget.key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 4),
            Text('Bulk Import', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Capture up to 10 photos. Low-confidence results are auto-saved as unverified drafts.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _capturing ? null : _captureAndQueue,
          icon: const Icon(Icons.camera_alt),
          label: Text(
            _capturing
                ? 'Capturing...'
                : 'Capture Photo (${_jobIds.length}/10)',
          ),
        ),
        const SizedBox(height: 12),
        if (_jobIds.isEmpty)
          const Text('No scans in this batch yet.')
        else
          SizedBox(
            height: 320,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _jobIds.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final jobId = _jobIds[index];
                return StreamBuilder<ScanRecognitionJob?>(
                  stream: CollectionScanService.watchJob(jobId),
                  builder: (context, snapshot) {
                    final job = snapshot.data;
                    if (job == null) {
                      return const _StatusCard(
                        icon: Icons.hourglass_empty,
                        title: 'Queued',
                        subtitle: 'Waiting for job details...',
                      );
                    }

                    return _BulkJobCard(
                      job: job,
                      manuallyImported: _manuallyImportedJobIds.contains(
                        job.id,
                      ),
                      autoDrafted: _autoDraftedJobIds.contains(job.id),
                      onImport: () => _importMatch(job),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _BulkJobCard extends StatelessWidget {
  final ScanRecognitionJob job;
  final bool manuallyImported;
  final bool autoDrafted;
  final VoidCallback onImport;

  const _BulkJobCard({
    required this.job,
    required this.manuallyImported,
    required this.autoDrafted,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final best = job.bestMatch;
    final statusText = switch (job.status) {
      ScanJobStatus.queued => 'Queued',
      ScanJobStatus.processing => 'Processing',
      ScanJobStatus.completed => 'Completed',
      ScanJobStatus.failed => 'Failed',
    };

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scan ${job.id.substring(0, 6)} · $statusText'),
            if (job.status == ScanJobStatus.failed && job.errorMessage != null)
              Text(
                job.errorMessage!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (job.status == ScanJobStatus.completed) ...[
              const SizedBox(height: 8),
              if (best == null)
                const Text('No reliable match')
              else
                Text(
                  '${best.gameTitle} (${best.platform.toUpperCase()}) · ${(best.combinedConfidence * 100).toStringAsFixed(0)}%',
                ),
              if (autoDrafted)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Unverified draft auto-created.'),
                ),
              if (best != null &&
                  best.combinedConfidence >= 0.45 &&
                  !manuallyImported)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilledButton.tonalIcon(
                    onPressed: onImport,
                    icon: const Icon(Icons.playlist_add_check),
                    label: const Text('Import Match'),
                  ),
                ),
              if (manuallyImported)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Imported to collection.'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
