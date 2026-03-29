import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game.dart';
import '../models/move_list.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static const _dbName = 'otakudb';

  static FirebaseFirestore get _namedDb =>
      FirebaseFirestore.instanceFor(app: _db.app, databaseId: _dbName);

  static CollectionReference<Map<String, dynamic>> get _gamesRef =>
      _namedDb.collection('games');

  static CollectionReference<Map<String, dynamic>> get _commandDatRef =>
      _namedDb.collection('command_dat');

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

  /// Look up command.dat data for a list of rom names.
  /// Tries each rom name and returns the first match.
  static Future<CommandData?> getCommandData(List<String> romNames) async {
    for (final romName in romNames) {
      final query = await _commandDatRef
          .where('rom_names', arrayContains: romName)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return CommandData.fromFirestore(query.docs.first);
      }
    }
    return null;
  }
}
