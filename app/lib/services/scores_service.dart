import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/game_score.dart';
import 'auth_service.dart';

class ScoresService {
  static final _db = FirebaseFirestore.instance;
  static const _dbName = 'otakudb';
  static final _storage = FirebaseStorage.instance;

  static FirebaseFirestore get _namedDb =>
      FirebaseFirestore.instanceFor(app: _db.app, databaseId: _dbName);

  static CollectionReference<Map<String, dynamic>> get _scoresRef =>
      _namedDb.collection('scores');

  /// Stream scores for a game, ordered by score descending, limit 50.
  static Stream<List<GameScore>> scoresForGameStream(String gameId) {
    return _scoresRef
        .where('game_id', isEqualTo: gameId)
        .orderBy('score', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GameScore.fromFirestore(d)).toList());
  }

  /// Submit a score with proof photo.
  static Future<void> submitScore({
    required String gameId,
    required int score,
    required Uint8List proofImageBytes,
    required String platform,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    // Upload proof photo
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'scores/${user.uid}/$gameId/$timestamp.jpg';
    final ref = _storage.ref(storagePath);
    await ref.putData(proofImageBytes, SettableMetadata(contentType: 'image/jpeg'));
    final proofUrl = await ref.getDownloadURL();

    // Create score document
    final gameScore = GameScore(
      id: '',
      gameId: gameId,
      userId: user.uid,
      userName: user.displayName ?? 'Anonymous',
      score: score,
      proofUrl: proofUrl,
      proofStoragePath: storagePath,
      platform: platform,
    );
    await _scoresRef.add(gameScore.toFirestoreCreate());
  }

  /// Delete a score and its proof photo.
  static Future<void> deleteScore(GameScore score) async {
    final user = AuthService.currentUser;
    if (user == null) return;
    // Security rules enforce ownership
    await _scoresRef.doc(score.id).delete();
    if (score.proofStoragePath.isNotEmpty) {
      try {
        await _storage.ref(score.proofStoragePath).delete();
      } catch (_) {
        // Ignore storage deletion errors
      }
    }
  }

  /// Stream scores for the current user.
  static Stream<List<GameScore>> userScoresStream() {
    final user = AuthService.currentUser;
    if (user == null) return Stream.value([]);
    return _scoresRef
        .where('user_id', isEqualTo: user.uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GameScore.fromFirestore(d)).toList());
  }
}
