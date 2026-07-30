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

enum _ScanSheetMode { chooser, ownershipCheck, bulkImport, singleImport }

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
              onSelectSingleImport: () =>
                  setState(() => _mode = _ScanSheetMode.singleImport),
            ),
            _ScanSheetMode.ownershipCheck => _OwnershipCheckView(
              key: const ValueKey('ownership'),
              onBack: () => setState(() => _mode = _ScanSheetMode.chooser),
            ),
            _ScanSheetMode.bulkImport => _BulkImportView(
              key: const ValueKey('bulk'),
              onBack: () => setState(() => _mode = _ScanSheetMode.chooser),
            ),
            _ScanSheetMode.singleImport => _SingleImportView(
              key: const ValueKey('single'),
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
  final VoidCallback onSelectSingleImport;

  const _ModeChooser({
    super.key,
    required this.onSelectOwnership,
    required this.onSelectBulk,
    required this.onSelectSingleImport,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drag handle.
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Text(
          'Scan Collection',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Pick a mode to scan games with your camera.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        _ModeCard(
          icon: Icons.add_a_photo_outlined,
          title: 'Single Game Import',
          subtitle: 'One photo · one game · added to your collection.',
          accent: scheme.primary,
          onTap: onSelectSingleImport,
        ),
        const SizedBox(height: 10),
        _ModeCard(
          icon: Icons.grid_view_rounded,
          title: 'Bulk Import',
          subtitle: 'One photo of a shelf or batch · many games imported.',
          accent: scheme.primary,
          onTap: onSelectBulk,
        ),
        const SizedBox(height: 10),
        _ModeCard(
          icon: Icons.fact_check_outlined,
          title: 'Ownership Check',
          subtitle:
              'One photo · check if a game is already in your collection.',
          accent: scheme.tertiary,
          onTap: onSelectOwnership,
        ),
      ],
    );
  }
}

/// Returns a stable candidate identifier from a [ScanDetectedGame], falling
/// back to a positional key when [candidateId] is empty.
String _scanCandidateId(ScanDetectedGame detected, int index) {
  if (detected.candidateId.trim().isNotEmpty) {
    return detected.candidateId.trim();
  }
  return 'candidate_$index';
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
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
  // candidateId -> collection item id for imported candidates.
  final Map<String, String> _importedItemIds = {};
  // Candidates the user explicitly discarded for this scan.
  final Set<String> _discardedCandidateIds = {};
  bool _capturing = false;
  bool _bulkImporting = false;
  bool _preloaded = false;

  @override
  void dispose() {
    _jobSubscription?.cancel();
    super.dispose();
  }

  // ── capture ────────────────────────────────────────────────────────────────

  Future<void> _captureSingleImage() async {
    setState(() => _capturing = true);
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final jobId = await CollectionScanService.submitScanJob(
        mode: RecognitionMode.bulkImport,
        imageBytes: bytes,
        fileName: image.name,
      );
      if (!mounted) return;

      _attachJobListener(jobId);
      setState(() {
        _jobId = jobId;
        _job = null;
        _capturedBytes = bytes;
        _capturedFileName = image.name;
        _importedItemIds.clear();
        _discardedCandidateIds.clear();
        _preloaded = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  // ── job listener ───────────────────────────────────────────────────────────

  void _attachJobListener(String jobId) {
    _jobSubscription?.cancel();
    _jobSubscription = CollectionScanService.watchJob(jobId).listen((
      job,
    ) async {
      if (!mounted || job == null) return;
      setState(() => _job = job);
      if (job.isCompleted && !_preloaded) {
        await _preloadExistingImports(job);
      }
    });
  }

  /// Pre-populate _importedItemIds in case the user hot-restarts mid-review.
  Future<void> _preloadExistingImports(ScanRecognitionJob job) async {
    _preloaded = true;
    for (var i = 0; i < job.detectedGames.length; i++) {
      final detected = job.detectedGames[i];
      final cid = _scanCandidateId(detected, i);
      if (_importedItemIds.containsKey(cid)) continue;
      final existing = await UserService.getCollectionItemForScanCandidate(
        scanJobId: job.id,
        scanCandidateId: cid,
      );
      if (existing != null && mounted) {
        setState(() => _importedItemIds[cid] = existing.id);
      }
    }
  }

  // ── photo upload ───────────────────────────────────────────────────────────

  Future<String?> _uploadScanCopyForCandidate(String candidateId) async {
    final bytes = _capturedBytes;
    if (bytes == null) return null;
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

  // ── per-candidate actions ──────────────────────────────────────────────────

  Future<void> _importCandidate(
    ScanRecognitionJob job,
    ScanDetectedGame detected,
    int index,
  ) async {
    final cid = _scanCandidateId(detected, index);
    if (_importedItemIds.containsKey(cid)) return;

    final best = detected.topMatch;
    final isLow = best == null || best.combinedConfidence < 0.45;
    final fallbackTitle = detected.rawTitle.trim().isNotEmpty
        ? detected.rawTitle.trim()
        : 'Unidentified Game';
    final fallbackPlatform = detected.normalizedPlatform.trim().isNotEmpty
        ? detected.normalizedPlatform.trim()
        : 'mvs';

    final photoPath = await _uploadScanCopyForCandidate(cid);

    await UserService.importRecognizedItem(
      scanJobId: job.id,
      scanCandidateId: cid,
      gameId: best?.gameId ?? '',
      gameTitle: best?.gameTitle ?? fallbackTitle,
      platform: best?.platform ?? fallbackPlatform,
      confidence: best?.combinedConfidence ?? detected.modelConfidence,
      unverified: isLow,
      notes: isLow
          ? 'Imported from bulk scan — low confidence. Please review.'
          : 'Imported from bulk scan.',
      imagePath: photoPath,
    );
    await UserService.markScanJobImported(job.id, isLow ? 'draft' : 'imported');

    final created = await UserService.getCollectionItemForScanCandidate(
      scanJobId: job.id,
      scanCandidateId: cid,
    );
    if (!mounted) return;
    setState(() {
      if (created != null) _importedItemIds[cid] = created.id;
      _discardedCandidateIds.remove(cid);
    });
  }

  Future<void> _removeImported(String candidateId) async {
    final itemId = _importedItemIds[candidateId];
    if (itemId == null) return;
    await UserService.removeFromCollection(itemId);
    if (!mounted) return;
    setState(() => _importedItemIds.remove(candidateId));
  }

  void _discardCandidate(String candidateId) =>
      setState(() => _discardedCandidateIds.add(candidateId));

  void _undoDiscard(String candidateId) =>
      setState(() => _discardedCandidateIds.remove(candidateId));

  // ── bulk actions ───────────────────────────────────────────────────────────

  Future<void> _importAllPending() async {
    final job = _job;
    if (job == null || _bulkImporting) return;
    setState(() => _bulkImporting = true);
    try {
      for (var i = 0; i < job.detectedGames.length; i++) {
        final detected = job.detectedGames[i];
        final cid = _scanCandidateId(detected, i);
        if (_importedItemIds.containsKey(cid)) continue;
        if (_discardedCandidateIds.contains(cid)) continue;
        await _importCandidate(job, detected, i);
      }
    } finally {
      if (mounted) setState(() => _bulkImporting = false);
    }
  }

  void _discardAllPending() {
    final job = _job;
    if (job == null) return;
    setState(() {
      for (var i = 0; i < job.detectedGames.length; i++) {
        final cid = _scanCandidateId(job.detectedGames[i], i);
        if (!_importedItemIds.containsKey(cid)) {
          _discardedCandidateIds.add(cid);
        }
      }
    });
  }

  Future<void> _changeImportedGame(
    ScanRecognitionJob job,
    ScanDetectedGame detected,
    int index,
  ) async {
    final cid = _scanCandidateId(detected, index);
    final existing = await UserService.getCollectionItemForScanCandidate(
      scanJobId: job.id,
      scanCandidateId: cid,
    );
    if (!mounted || existing == null) return;

    final selectedGame = await showModalBottomSheet<Game>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ChangeImportedGameSheet(initialQuery: detected.rawTitle),
    );
    if (!mounted || selectedGame == null) return;

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
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Updated to ${selectedGame.title}')));
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final job = _job;
    final isReady = job != null && job.isCompleted;
    final scheme = Theme.of(context).colorScheme;

    // Summary counts.
    int keptCount = 0;
    int discardedCount = 0;
    int pendingCount = 0;
    if (isReady) {
      for (var i = 0; i < job.detectedGames.length; i++) {
        final cid = _scanCandidateId(job.detectedGames[i], i);
        if (_importedItemIds.containsKey(cid)) {
          keptCount++;
        } else if (_discardedCandidateIds.contains(cid)) {
          discardedCount++;
        } else {
          pendingCount++;
        }
      }
    }

    return Column(
      key: widget.key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── header ────────────────────────────────────────────────────────────
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
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Review detections, then import the ones you want.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 12),

        // ── capture button (shown only before results arrive) ─────────────────
        if (!isReady)
          FilledButton.icon(
            onPressed: _capturing ? null : _captureSingleImage,
            icon: const Icon(Icons.camera_alt),
            label: Text(
              _capturing
                  ? 'Capturing…'
                  : (_jobId == null ? 'Capture Photo' : 'Retake Photo'),
            ),
          ),

        // ── pre-capture empty state ───────────────────────────────────────────
        if (_jobId == null) ...[
          const SizedBox(height: 12),
          const Text('No scan captured yet.'),
        ],

        // ── processing / error ────────────────────────────────────────────────
        if (_jobId != null && !isReady) ...[
          const SizedBox(height: 12),
          _buildStatusOrError(),
        ],

        // ── results ───────────────────────────────────────────────────────────
        if (isReady) ...[
          const SizedBox(height: 4),
          _buildResults(job, pendingCount, keptCount, discardedCount),
        ],
      ],
    );
  }

  Widget _buildStatusOrError() {
    final job = _job;
    if (job == null ||
        job.status == ScanJobStatus.queued ||
        job.status == ScanJobStatus.processing) {
      return const _StatusCard(
        icon: Icons.timelapse,
        title: 'Analyzing image…',
        subtitle: 'Recognition in progress',
      );
    }
    return _StatusCard(
      icon: Icons.error_outline,
      title: 'Recognition failed',
      subtitle: job.errorMessage ?? 'Please retake the photo',
    );
  }

  Widget _buildResults(
    ScanRecognitionJob job,
    int pendingCount,
    int keptCount,
    int discardedCount,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary chips.
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _SummaryChip(
              label: '${job.detectedGames.length} detected',
              color: scheme.onSurfaceVariant,
              bg: scheme.surfaceContainerHighest,
            ),
            if (pendingCount > 0)
              _SummaryChip(
                label: '$pendingCount pending',
                color: scheme.onPrimaryContainer,
                bg: scheme.primaryContainer,
              ),
            if (keptCount > 0)
              _SummaryChip(
                label: '$keptCount kept',
                color: scheme.onTertiaryContainer,
                bg: scheme.tertiaryContainer,
              ),
            if (discardedCount > 0)
              _SummaryChip(
                label: '$discardedCount discarded',
                color: scheme.onSurfaceVariant,
                bg: scheme.surfaceContainerHighest,
              ),
          ],
        ),
        if (job.parseWarnings.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              job.parseWarnings.first,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        if (job.detectedGames.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'No games detected. Try another angle or better lighting.',
            ),
          )
        else ...[
          const SizedBox(height: 10),
          _buildList(job),
        ],
        // Sticky bottom actions.
        const SizedBox(height: 12),
        _buildBottomBar(pendingCount),
      ],
    );
  }

  Widget _buildList(ScanRecognitionJob job) {
    return SizedBox(
      height: 280,
      child: ListView.separated(
        itemCount: job.detectedGames.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final detected = job.detectedGames[index];
          final cid = _scanCandidateId(detected, index);
          final isImported = _importedItemIds.containsKey(cid);
          final isDiscarded = _discardedCandidateIds.contains(cid);
          return _DetectedCandidateCard(
            detected: detected,
            isImported: isImported,
            isDiscarded: isDiscarded,
            onImport: () => _importCandidate(job, detected, index),
            onDiscard: () => _discardCandidate(cid),
            onUndoDiscard: () => _undoDiscard(cid),
            onChangeGame: () => _changeImportedGame(job, detected, index),
            onRemove: () => _removeImported(cid),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(int pendingCount) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.outlineVariant, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          // Retake (left side).
          TextButton.icon(
            onPressed: _bulkImporting ? null : _captureSingleImage,
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text('Retake'),
            style: TextButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          // Discard all pending.
          if (pendingCount > 0)
            TextButton(
              onPressed: _bulkImporting ? null : _discardAllPending,
              style: TextButton.styleFrom(
                foregroundColor: scheme.onSurfaceVariant,
              ),
              child: const Text('Discard all'),
            ),
          const SizedBox(width: 8),
          // Import all pending.
          FilledButton.icon(
            onPressed: (pendingCount == 0 || _bulkImporting)
                ? null
                : _importAllPending,
            icon: _bulkImporting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.playlist_add_check, size: 20),
            label: Text(
              pendingCount > 0 ? 'Import all ($pendingCount)' : 'Import all',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single Game Import view
// ─────────────────────────────────────────────────────────────────────────────

class _SingleImportView extends StatefulWidget {
  final VoidCallback onBack;
  const _SingleImportView({super.key, required this.onBack});

  @override
  State<_SingleImportView> createState() => _SingleImportViewState();
}

class _SingleImportViewState extends State<_SingleImportView> {
  final _picker = ImagePicker();
  String? _jobId;
  ScanRecognitionJob? _job;
  Uint8List? _capturedBytes;
  String? _capturedFileName;
  StreamSubscription<ScanRecognitionJob?>? _jobSubscription;
  bool _capturing = false;
  bool _importing = false;
  bool _imported = false;
  CollectionItem? _importedItem;

  @override
  void dispose() {
    _jobSubscription?.cancel();
    super.dispose();
  }

  Future<void> _captureAndSubmit() async {
    setState(() => _capturing = true);
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final jobId = await CollectionScanService.submitScanJob(
        mode: RecognitionMode.singleImport,
        imageBytes: bytes,
        fileName: image.name,
      );
      if (!mounted) return;

      _attachJobListener(jobId);
      setState(() {
        _jobId = jobId;
        _job = null;
        _capturedBytes = bytes;
        _capturedFileName = image.name;
        _imported = false;
        _importing = false;
        _importedItem = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _attachJobListener(String jobId) {
    _jobSubscription?.cancel();
    _jobSubscription = CollectionScanService.watchJob(jobId).listen((
      job,
    ) async {
      if (!mounted || job == null) return;
      setState(() => _job = job);
      if (job.isCompleted && !_imported && !_importing) {
        await _autoImport(job);
      }
    });
  }

  Future<String?> _uploadPhoto(String candidateId) async {
    final bytes = _capturedBytes;
    if (bytes == null) return null;
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

  Future<void> _autoImport(ScanRecognitionJob job) async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final jobId = job.id;

      // Pick the first (and expected only) candidate.
      if (job.detectedGames.isEmpty) {
        // Nothing detected — create an unverified draft with placeholder.
        final candidateId = 'single_no_match';
        final existing = await UserService.getCollectionItemForScanCandidate(
          scanJobId: jobId,
          scanCandidateId: candidateId,
        );
        if (existing != null) {
          setState(() {
            _imported = true;
            _importedItem = existing;
          });
          return;
        }
        final photoPath = await _uploadPhoto(candidateId);
        await UserService.importRecognizedItem(
          scanJobId: jobId,
          scanCandidateId: candidateId,
          gameId: '',
          gameTitle: 'Unidentified Game',
          platform: 'mvs',
          confidence: 0,
          unverified: true,
          notes:
              'Auto-created from single-game scan — no item detected. Please review.',
          imagePath: photoPath,
        );
        await UserService.markScanJobImported(jobId, 'draft_auto_created');
        if (!mounted) return;
        final created = await UserService.getCollectionItemForScanCandidate(
          scanJobId: jobId,
          scanCandidateId: candidateId,
        );
        setState(() {
          _imported = true;
          _importedItem = created;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unverified draft created — no game detected'),
          ),
        );
        return;
      }

      final detected = job.detectedGames.first;
      final candidateId = _scanCandidateId(detected, 0);

      final existing = await UserService.getCollectionItemForScanCandidate(
        scanJobId: jobId,
        scanCandidateId: candidateId,
      );
      if (existing != null) {
        if (!mounted) return;
        setState(() {
          _imported = true;
          _importedItem = existing;
        });
        return;
      }

      final best = detected.topMatch;
      final isLowConfidence = best == null || best.combinedConfidence < 0.45;
      final fallbackTitle = detected.rawTitle.trim().isNotEmpty
          ? detected.rawTitle.trim()
          : 'Unidentified Game';
      final fallbackPlatform = detected.normalizedPlatform.trim().isNotEmpty
          ? detected.normalizedPlatform.trim()
          : 'mvs';

      final photoPath = await _uploadPhoto(candidateId);

      await UserService.importRecognizedItem(
        scanJobId: jobId,
        scanCandidateId: candidateId,
        gameId: best?.gameId ?? '',
        gameTitle: best?.gameTitle ?? fallbackTitle,
        platform: best?.platform ?? fallbackPlatform,
        confidence: best?.combinedConfidence ?? detected.modelConfidence,
        unverified: isLowConfidence,
        notes: isLowConfidence
            ? 'Auto-created from low-confidence single-game scan. Please review details.'
            : 'Imported from single-game scan.',
        imagePath: photoPath,
      );
      await UserService.markScanJobImported(
        jobId,
        isLowConfidence ? 'draft_auto_created' : 'imported',
      );

      if (!mounted) return;

      final created = await UserService.getCollectionItemForScanCandidate(
        scanJobId: jobId,
        scanCandidateId: candidateId,
      );
      setState(() {
        _imported = true;
        _importedItem = created;
      });

      final label = best?.gameTitle ?? fallbackTitle;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLowConfidence
                ? 'Unverified draft created for "$label"'
                : 'Imported "$label" to collection',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _changeGame() async {
    final item = _importedItem;
    if (item == null) return;

    final detected = _job?.detectedGames.firstOrNull;
    final selectedGame = await showModalBottomSheet<Game>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ChangeImportedGameSheet(
        initialQuery: detected?.rawTitle ?? item.gameTitle,
      ),
    );
    if (!mounted || selectedGame == null) return;

    final updated = CollectionItem(
      id: item.id,
      gameId: selectedGame.id,
      gameTitle: selectedGame.title,
      platform: selectedGame.platform.isNotEmpty
          ? selectedGame.platform
          : item.platform,
      format: item.format,
      condition: item.condition,
      region: item.region,
      purchasePrice: item.purchasePrice,
      purchaseCurrency: item.purchaseCurrency,
      purchaseDate: item.purchaseDate,
      notes: item.notes,
      addedAt: item.addedAt,
      isUnverified: false,
      scanJobId: item.scanJobId,
      scanCandidateId: item.scanCandidateId,
      recognitionConfidence: item.recognitionConfidence,
      importSource: item.importSource,
      verifiedAt: Timestamp.now(),
    );
    await UserService.updateCollectionItem(item.id, updated);
    if (!mounted) return;
    setState(() => _importedItem = updated);
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
            Text(
              'Single Game Import',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Take one photo of a single game. It will be imported directly into your collection.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _capturing ? null : _captureAndSubmit,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(
            _capturing
                ? 'Capturing...'
                : (_jobId == null ? 'Take Photo' : 'Retake Photo'),
          ),
        ),
        if (_capturedBytes != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _capturedBytes!,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (_jobId == null)
          const Text('No scan captured yet.')
        else if (_job == null ||
            _job!.status == ScanJobStatus.queued ||
            _job!.status == ScanJobStatus.processing ||
            (_job!.isCompleted && _importing))
          const _StatusCard(
            icon: Icons.timelapse,
            title: 'Analyzing & importing…',
            subtitle: 'Recognition in progress',
          )
        else if (_job!.isFailed)
          _StatusCard(
            icon: Icons.error_outline,
            title: 'Recognition failed',
            subtitle: _job!.errorMessage ?? 'Please retake the photo',
          )
        else if (_imported)
          _SingleImportResultCard(
            item: _importedItem,
            onChangeGame: _changeGame,
          ),
      ],
    );
  }
}

class _SingleImportResultCard extends StatelessWidget {
  final CollectionItem? item;
  final VoidCallback onChangeGame;

  const _SingleImportResultCard({
    required this.item,
    required this.onChangeGame,
  });

  @override
  Widget build(BuildContext context) {
    final i = item;
    if (i == null) {
      return const _StatusCard(
        icon: Icons.help_outline,
        title: 'Import complete',
        subtitle: 'Item was saved to your collection.',
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    i.gameTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(i.isUnverified ? 'Unverified draft' : 'Verified'),
                  backgroundColor: i.isUnverified
                      ? Theme.of(context).colorScheme.errorContainer
                      : Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: i.isUnverified
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              i.platform.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (i.recognitionConfidence != null && i.recognitionConfidence! > 0)
              Text(
                'Confidence ${(i.recognitionConfidence! * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onChangeGame,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Change Game'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary chip ──────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _SummaryChip({
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Candidate card (three-state) ─────────────────────────────────────────

class _DetectedCandidateCard extends StatelessWidget {
  final ScanDetectedGame detected;
  final bool isImported;
  final bool isDiscarded;
  final VoidCallback onImport;
  final VoidCallback onDiscard;
  final VoidCallback onUndoDiscard;
  final VoidCallback onChangeGame;
  final VoidCallback onRemove;

  const _DetectedCandidateCard({
    required this.detected,
    required this.isImported,
    required this.isDiscarded,
    required this.onImport,
    required this.onDiscard,
    required this.onUndoDiscard,
    required this.onChangeGame,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
    final isHighConf = confidence >= 0.75;
    final isMidConf = confidence >= 0.45 && confidence < 0.75;
    final isLow = !isHighConf && !isMidConf;

    return Opacity(
      opacity: isDiscarded ? 0.5 : 1.0,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── title row ─────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: isDiscarded
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // State badge.
                  if (isImported)
                    _StateBadge(
                      label: 'Kept',
                      icon: Icons.check_circle_outline,
                      color: scheme.onTertiaryContainer,
                      bg: scheme.tertiaryContainer,
                    )
                  else if (isDiscarded)
                    _StateBadge(
                      label: 'Discarded',
                      icon: Icons.remove_circle_outline,
                      color: scheme.onSurfaceVariant,
                      bg: scheme.surfaceContainerHighest,
                    )
                  else
                    _ConfidenceChip(
                      isHigh: isHighConf,
                      isMid: isMidConf,
                      confidence: confidence,
                      scheme: scheme,
                    ),
                ],
              ),
              const SizedBox(height: 3),
              // Platform.
              Text(
                platform.toUpperCase(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              // Low-conf warning.
              if (isLow && !isImported && !isDiscarded)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    best == null
                        ? 'No reliable catalog match — will be saved as a draft.'
                        : 'Low confidence — will be saved as an unverified draft.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: scheme.error),
                  ),
                ),
              const SizedBox(height: 8),
              // ── actions ───────────────────────────────────────────────────
              if (isImported)
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onChangeGame,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Change'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.error,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                )
              else if (isDiscarded)
                TextButton.icon(
                  onPressed: onUndoDiscard,
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text('Undo'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                )
              else
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: onImport,
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('Import'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: isLow
                            ? scheme.surfaceContainerHighest
                            : scheme.primary,
                        foregroundColor: isLow
                            ? scheme.onSurface
                            : scheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onDiscard,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Discard'),
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.onSurfaceVariant,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidenceChip extends StatelessWidget {
  final bool isHigh;
  final bool isMid;
  final double confidence;
  final ColorScheme scheme;
  const _ConfidenceChip({
    required this.isHigh,
    required this.isMid,
    required this.confidence,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = isHigh
        ? ('High match', scheme.onTertiaryContainer, scheme.tertiaryContainer)
        : isMid
        ? (
            'Possible match',
            scheme.onSecondaryContainer,
            scheme.secondaryContainer,
          )
        : ('Low confidence', scheme.onErrorContainer, scheme.errorContainer);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label · ${(confidence * 100).toStringAsFixed(0)}%',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  const _StateBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
