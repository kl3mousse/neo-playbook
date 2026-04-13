import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game.dart';
import '../models/move_list.dart';
import '../models/dip_settings.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static const _dbName = 'otakudb';

  static FirebaseFirestore get namedDb =>
      FirebaseFirestore.instanceFor(app: _db.app, databaseId: _dbName);

  static CollectionReference<Map<String, dynamic>> get _gamesRef =>
      namedDb.collection('games');

  static CollectionReference<Map<String, dynamic>> get _commandDatRef =>
      namedDb.collection('command_dat');

  static CollectionReference<Map<String, dynamic>> get _dipSettingsRef =>
      namedDb.collection('dip_settings');

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

  /// Look up DIP settings for a list of rom names.
  /// Tries each rom name as a document ID and returns the first match.
  static Future<DipSettingsData?> getDipSettings(List<String> romNames) async {
    for (final romName in romNames) {
      final doc = await _dipSettingsRef.doc(romName).get();
      if (doc.exists) {
        return DipSettingsData.fromFirestore(doc);
      }
    }
    return null;
  }
}
