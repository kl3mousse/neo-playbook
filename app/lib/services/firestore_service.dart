import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static const _dbName = 'otakudb';

  static CollectionReference<Map<String, dynamic>> get _gamesRef =>
      FirebaseFirestore.instanceFor(app: _db.app, databaseId: _dbName)
          .collection('games');

  /// Stream all games ordered by title.
  static Stream<List<Game>> gamesStream() {
    return _gamesRef.orderBy('title').snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => Game.fromFirestore(doc)).toList(),
        );
  }

  /// Get a single game by ID.
  static Future<Game?> getGame(String id) async {
    final doc = await _gamesRef.doc(id).get();
    if (!doc.exists) return null;
    return Game.fromFirestore(doc);
  }

  /// Update a game document (merge).
  static Future<void> updateGame(Game game) {
    return _gamesRef.doc(game.id).set(game.toFirestore(), SetOptions(merge: true));
  }

  /// Search games by title (client-side filter on stream).
  static Stream<List<Game>> searchGames(String query) {
    final lower = query.toLowerCase();
    return gamesStream().map(
      (games) => games
          .where((g) =>
              g.title.toLowerCase().contains(lower) ||
              (g.altTitle?.toLowerCase().contains(lower) ?? false))
          .toList(),
    );
  }
}
