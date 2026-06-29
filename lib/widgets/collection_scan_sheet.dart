import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/collection_item.dart';
import '../models/game.dart';
import '../models/scan_recognition_job.dart';
import '../services/collection_scan_service.dart';
import '../services/firestore_service.dart';
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
          subtitle:
              'Take one photo that may include many arcade games to import.',
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
  String? _jobId;
  ScanRecognitionJob? _job;
  Uint8List? _capturedBytes;
  String? _capturedFileName;
  StreamSubscription<ScanRecognitionJob?>? _jobSubscription;
  final Set<String> _autoDraftedCandidateIds = {};
  final Set<String> _manuallyImportedCandidateIds = {};
  bool _capturing = false;
  bool _creatingDrafts = false;

  @override
  void dispose() {
    _jobSubscription?.cancel();
    super.dispose();
  }

  Future<void> _captureSingleImage() async {
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

      _attachJobListener(jobId);
      setState(() {
        _jobId = jobId;
        _job = null;
        _capturedBytes = bytes;
        _capturedFileName = image.name;
        _autoDraftedCandidateIds.clear();
        _manuallyImportedCandidateIds.clear();
      });
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

  Future<String?> _uploadScanCopyForCandidate(String candidateId) async {
    final bytes = _capturedBytes;
    if (bytes == null) {
      return null;
    }
    try {
      return await UserService.uploadCollectionItemPhoto(
        itemId: 'scan_$candidateId',
        bytes: bytes,
        contentType: 'image/jpeg',
        fileName: _capturedFileName,
      );
    } catch (_) {
      return null;
    }
  }

  String _candidateId(ScanDetectedGame detected, int index) {
    if (detected.candidateId.trim().isNotEmpty) {
      return detected.candidateId.trim();
    }
    return 'candidate_$index';
  }

  void _attachJobListener(String jobId) {
    _jobSubscription?.cancel();
    _jobSubscription = CollectionScanService.watchJob(jobId).listen((
      job,
    ) async {
      if (!mounted || job == null) {
        return;
      }
      setState(() => _job = job);

      if (!job.isCompleted) {
        return;
      }

      await _autoDraftLowConfidenceCandidates(job);
    });
  }

  Future<void> _autoDraftLowConfidenceCandidates(ScanRecognitionJob job) async {
    if (_creatingDrafts) {
      return;
    }
    _creatingDrafts = true;

    try {
      int createdDrafts = 0;
      for (var index = 0; index < job.detectedGames.length; index++) {
        final detected = job.detectedGames[index];
        final candidateId = _candidateId(detected, index);

        if (_autoDraftedCandidateIds.contains(candidateId) ||
            _manuallyImportedCandidateIds.contains(candidateId)) {
          continue;
        }

        if (await UserService.getCollectionItemForScanCandidate(
              scanJobId: job.id,
              scanCandidateId: candidateId,
            ) !=
            null) {
          _autoDraftedCandidateIds.add(candidateId);
          continue;
        }

        final best = detected.topMatch;
        final shouldAutoDraft = best == null ||
            best.combinedConfidence < 0.45;

        if (!shouldAutoDraft) {
          continue;
        }

        final fallbackTitle = detected.rawTitle.trim().isNotEmpty
            ? detected.rawTitle.trim()
            : 'Unidentified Game';
        final fallbackPlatform = detected.normalizedPlatform.trim().isNotEmpty
            ? detected.normalizedPlatform.trim()
            : 'mvs';

        final photoPath = await _uploadScanCopyForCandidate(candidateId);

        await UserService.importRecognizedItem(
          scanJobId: job.id,
          scanCandidateId: candidateId,
          gameId: best?.gameId ?? '',
          gameTitle: best?.gameTitle ?? fallbackTitle,
          platform: best?.platform ?? fallbackPlatform,
          confidence: best?.combinedConfidence ?? detected.modelConfidence,
          unverified: true,
          notes:
              'Auto-created from low-confidence scan. Please review details.',
          imagePath: photoPath,
        );

        _autoDraftedCandidateIds.add(candidateId);
        createdDrafts += 1;
      }

      if (createdDrafts > 0) {
        await UserService.markScanJobImported(job.id, 'draft_auto_created');
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                createdDrafts == 1
                    ? '1 unverified draft created from scan'
                    : '$createdDrafts unverified drafts created from scan',
              ),
            ),
          );
        }
      }
    } finally {
      _creatingDrafts = false;
    }
  }

  Future<void> _importDetectedMatch(
    ScanRecognitionJob job,
    ScanDetectedGame detected,
    int index,
  ) async {
    final best = detected.topMatch;
    if (best == null) {
      return;
    }

    final candidateId = _candidateId(detected, index);
    if (_manuallyImportedCandidateIds.contains(candidateId)) {
      return;
    }

    final photoPath = await _uploadScanCopyForCandidate(candidateId);

    await UserService.importRecognizedItem(
      scanJobId: job.id,
      scanCandidateId: candidateId,
      gameId: best.gameId,
      gameTitle: best.gameTitle,
      platform: best.platform,
      confidence: best.combinedConfidence,
      unverified: false,
      notes: 'Imported from camera scan.',
      imagePath: photoPath,
    );
    await UserService.markScanJobImported(job.id, 'imported');
    if (!mounted) {
      return;
    }

    setState(() => _manuallyImportedCandidateIds.add(candidateId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported ${best.gameTitle} to collection')),
    );
  }

  Future<void> _changeImportedGame(
    ScanRecognitionJob job,
    ScanDetectedGame detected,
    int index,
  ) async {
    final candidateId = _candidateId(detected, index);
    final existing = await UserService.getCollectionItemForScanCandidate(
      scanJobId: job.id,
      scanCandidateId: candidateId,
    );

    if (!mounted) {
      return;
    }

    if (existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Import this candidate first to modify it'),
        ),
      );
      return;
    }

    final selectedGame = await showModalBottomSheet<Game>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ChangeImportedGameSheet(initialQuery: detected.rawTitle),
    );

    if (!mounted || selectedGame == null) {
      return;
    }

    final updated = CollectionItem(
      id: existing.id,
      gameId: selectedGame.id,
      gameTitle: selectedGame.title,
      platform: selectedGame.platform.isNotEmpty
          ? selectedGame.platform
          : existing.platform,
      format: existing.format,
      condition: existing.condition,
      region: existing.region,
      purchasePrice: existing.purchasePrice,
      purchaseCurrency: existing.purchaseCurrency,
      purchaseDate: existing.purchaseDate,
      notes: existing.notes,
      addedAt: existing.addedAt,
      isUnverified: false,
      scanJobId: existing.scanJobId,
      scanCandidateId: existing.scanCandidateId,
      recognitionConfidence: existing.recognitionConfidence,
      importSource: existing.importSource,
      verifiedAt: Timestamp.now(),
    );

    await UserService.updateCollectionItem(existing.id, updated);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Updated to ${selectedGame.title}')));
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
          'Use one photo only. Include as many arcade games as possible in the shot. Low-confidence detections are auto-saved as unverified drafts.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _capturing ? null : _captureSingleImage,
          icon: const Icon(Icons.camera_alt),
          label: Text(
            _capturing
                ? 'Capturing...'
                : (_jobId == null ? 'Capture Photo' : 'Retake Photo'),
          ),
        ),
        const SizedBox(height: 12),
        if (_jobId == null)
          const Text('No scan captured yet.')
        else if (_job == null ||
            _job!.status == ScanJobStatus.queued ||
            _job!.status == ScanJobStatus.processing)
          const _StatusCard(
            icon: Icons.timelapse,
            title: 'Analyzing image...',
            subtitle: 'Recognition in progress',
          )
        else if (_job!.isFailed)
          _StatusCard(
            icon: Icons.error_outline,
            title: 'Recognition failed',
            subtitle: _job!.errorMessage ?? 'Please retake the photo',
          )
        else ...[
          Text(
            '${_job!.detectedGames.length} candidate(s) detected from this image.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_job!.parseWarnings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _job!.parseWarnings.first,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: 320,
            child: ListView.separated(
              itemCount: _job!.detectedGames.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final detected = _job!.detectedGames[index];
                final candidateId = _candidateId(detected, index);
                return _DetectedCandidateCard(
                  detected: detected,
                  manuallyImported: _manuallyImportedCandidateIds.contains(
                    candidateId,
                  ),
                  autoDrafted: _autoDraftedCandidateIds.contains(candidateId),
                  onImport: () => _importDetectedMatch(_job!, detected, index),
                  onModifyImported: () =>
                      _changeImportedGame(_job!, detected, index),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _DetectedCandidateCard extends StatelessWidget {
  final ScanDetectedGame detected;
  final bool manuallyImported;
  final bool autoDrafted;
  final VoidCallback onImport;
  final VoidCallback onModifyImported;

  const _DetectedCandidateCard({
    required this.detected,
    required this.manuallyImported,
    required this.autoDrafted,
    required this.onImport,
    required this.onModifyImported,
  });

  @override
  Widget build(BuildContext context) {
    final best = detected.topMatch;
    final title =
        best?.gameTitle ??
        (detected.rawTitle.trim().isNotEmpty
            ? detected.rawTitle.trim()
            : 'Unidentified Game');
    final platform =
        best?.platform ??
        (detected.normalizedPlatform.trim().isNotEmpty
            ? detected.normalizedPlatform.trim()
            : 'unknown');
    final confidence = best?.combinedConfidence ?? detected.modelConfidence;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 4),
            Text(
              '${platform.toUpperCase()} · ${(confidence * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (best == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('No reliable catalog match for this detection.'),
              ),
            if (autoDrafted)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Unverified draft auto-created.'),
              ),
            if (best != null && confidence >= 0.45 && !manuallyImported)
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
            if (manuallyImported || autoDrafted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: onModifyImported,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Change Game'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChangeImportedGameSheet extends StatefulWidget {
  final String initialQuery;

  const _ChangeImportedGameSheet({required this.initialQuery});

  @override
  State<_ChangeImportedGameSheet> createState() =>
      _ChangeImportedGameSheetState();
}

class _ChangeImportedGameSheetState extends State<_ChangeImportedGameSheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _query.trim();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Imported Game',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search game title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            if (normalized.length < 2)
              const Text('Type at least 2 characters to search')
            else
              SizedBox(
                height: 360,
                child: StreamBuilder<List<Game>>(
                  stream: FirestoreService.searchGames(normalized),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final results = snapshot.data!.take(30).toList();
                    if (results.isEmpty) {
                      return const Center(
                        child: Text('No game found for this query'),
                      );
                    }

                    return ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final game = results[index];
                        final subtitle = [
                          game.platform.toUpperCase(),
                          if (game.year != null) game.year.toString(),
                          if (game.publisher != null &&
                              game.publisher!.trim().isNotEmpty)
                            game.publisher!.trim(),
                        ].join(' · ');

                        return ListTile(
                          title: Text(game.title),
                          subtitle: Text(subtitle),
                          onTap: () => Navigator.pop(context, game),
                        );
                      },
                    );
                  },
                ),
              ),
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
