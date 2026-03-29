import 'package:cloud_firestore/cloud_firestore.dart';

class GameScore {
  final String id;
  final String gameId;
  final String userId;
  final String userName;
  final int score;
  final String proofUrl;
  final String proofStoragePath;
  final String platform;
  final Timestamp? verifiedAt;
  final Timestamp? createdAt;

  const GameScore({
    required this.id,
    required this.gameId,
    required this.userId,
    required this.userName,
    required this.score,
    required this.proofUrl,
    required this.proofStoragePath,
    required this.platform,
    this.verifiedAt,
    this.createdAt,
  });

  bool get isVerified => verifiedAt != null;

  factory GameScore.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return GameScore(
      id: doc.id,
      gameId: data['game_id'] as String? ?? '',
      userId: data['user_id'] as String? ?? '',
      userName: data['user_name'] as String? ?? '',
      score: data['score'] as int? ?? 0,
      proofUrl: data['proof_url'] as String? ?? '',
      proofStoragePath: data['proof_storage_path'] as String? ?? '',
      platform: data['platform'] as String? ?? '',
      verifiedAt: data['verified_at'] as Timestamp?,
      createdAt: data['created_at'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestoreCreate() => {
        'game_id': gameId,
        'user_id': userId,
        'user_name': userName,
        'score': score,
        'proof_url': proofUrl,
        'proof_storage_path': proofStoragePath,
        'platform': platform,
        'created_at': FieldValue.serverTimestamp(),
      };
}
