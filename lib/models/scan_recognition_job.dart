import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_helpers.dart';

enum RecognitionMode {
  ownershipCheck('ownership_check'),
  bulkImport('bulk_import'),
  singleImport('single_import');

  final String value;
  const RecognitionMode(this.value);

  static RecognitionMode fromValue(String value) {
    return RecognitionMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => RecognitionMode.ownershipCheck,
    );
  }
}

enum ScanJobStatus { queued, processing, completed, failed }

class ScanGameMatch {
  final String gameId;
  final String gameTitle;
  final String platform;
  final double matchScore;
  final double combinedConfidence;

  const ScanGameMatch({
    required this.gameId,
    required this.gameTitle,
    required this.platform,
    required this.matchScore,
    required this.combinedConfidence,
  });

  factory ScanGameMatch.fromMap(Map<String, dynamic> data) {
    return ScanGameMatch(
      gameId: data['game_id'] as String? ?? '',
      gameTitle: data['game_title'] as String? ?? '',
      platform: data['platform'] as String? ?? '',
      matchScore: (data['match_score'] as num?)?.toDouble() ?? 0,
      combinedConfidence:
          (data['combined_confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ScanDetectedGame {
  final String candidateId;
  final String rawTitle;
  final String rawPlatform;
  final String normalizedPlatform;
  final double modelConfidence;
  final List<ScanGameMatch> matches;

  const ScanDetectedGame({
    required this.candidateId,
    required this.rawTitle,
    required this.rawPlatform,
    required this.normalizedPlatform,
    required this.modelConfidence,
    required this.matches,
  });

  factory ScanDetectedGame.fromMap(Map<String, dynamic> data) {
    final matchesRaw = data['matches'] as List<dynamic>? ?? [];
    return ScanDetectedGame(
      candidateId: data['candidate_id'] as String? ?? '',
      rawTitle: data['raw_title'] as String? ?? '',
      rawPlatform: data['raw_platform'] as String? ?? '',
      normalizedPlatform: data['normalized_platform'] as String? ?? '',
      modelConfidence: (data['model_confidence'] as num?)?.toDouble() ?? 0,
      matches: matchesRaw
          .map((entry) {
            if (entry is Map) {
              return ScanGameMatch.fromMap(Map<String, dynamic>.from(entry));
            }
            return null;
          })
          .whereType<ScanGameMatch>()
          .toList(),
    );
  }

  ScanGameMatch? get topMatch => matches.isEmpty ? null : matches.first;
}

class ScanRecognitionJob {
  final String id;
  final String uid;
  final RecognitionMode mode;
  final ScanJobStatus status;
  final String imagePath;
  final String? imageName;
  final String? mimeType;
  final List<ScanDetectedGame> detectedGames;
  final List<String> parseWarnings;
  final String? errorMessage;
  final String? importStatus;
  final Timestamp? createdAt;
  final Timestamp? completedAt;

  const ScanRecognitionJob({
    required this.id,
    required this.uid,
    required this.mode,
    required this.status,
    required this.imagePath,
    this.imageName,
    this.mimeType,
    required this.detectedGames,
    required this.parseWarnings,
    this.errorMessage,
    this.importStatus,
    this.createdAt,
    this.completedAt,
  });

  factory ScanRecognitionJob.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final detectedRaw = data['detected_games'] as List<dynamic>? ?? [];
    final parseWarningsRaw = data['parse_warnings'] as List<dynamic>? ?? [];

    return ScanRecognitionJob(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      mode: RecognitionMode.fromValue(data['mode'] as String? ?? ''),
      status: ScanJobStatus.values.firstWhere(
        (value) => value.name == (data['status'] as String? ?? 'queued'),
        orElse: () => ScanJobStatus.queued,
      ),
      imagePath: data['image_path'] as String? ?? '',
      imageName: data['image_name'] as String?,
      mimeType: data['mime_type'] as String?,
      detectedGames: detectedRaw
          .map((entry) {
            if (entry is Map) {
              return ScanDetectedGame.fromMap(Map<String, dynamic>.from(entry));
            }
            return null;
          })
          .whereType<ScanDetectedGame>()
          .toList(),
      parseWarnings: parseWarningsRaw.map((v) => v.toString()).toList(),
      errorMessage: data['error_message'] as String?,
      importStatus: data['import_status'] as String?,
      createdAt: parseTimestamp(data['created_at']),
      completedAt: parseTimestamp(data['completed_at']),
    );
  }

  bool get isCompleted => status == ScanJobStatus.completed;
  bool get isFailed => status == ScanJobStatus.failed;

  ScanGameMatch? get bestMatch {
    ScanGameMatch? best;
    for (final detected in detectedGames) {
      final match = detected.topMatch;
      if (match == null) {
        continue;
      }
      if (best == null || match.combinedConfidence > best.combinedConfidence) {
        best = match;
      }
    }
    return best;
  }

  double get bestModelConfidence {
    if (detectedGames.isEmpty) {
      return 0;
    }
    return detectedGames
        .map((item) => item.modelConfidence)
        .reduce((a, b) => a > b ? a : b);
  }
}
