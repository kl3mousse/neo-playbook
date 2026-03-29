import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_note.dart';
import 'auth_service.dart';

class NotesService {
  static final _db = FirebaseFirestore.instance;
  static const _dbName = 'otakudb';

  static FirebaseFirestore get _namedDb =>
      FirebaseFirestore.instanceFor(app: _db.app, databaseId: _dbName);

  static CollectionReference<Map<String, dynamic>> get _notesRef =>
      _namedDb.collection('community_notes');

  /// Stream notes for a game, ordered by upvotes descending.
  static Stream<List<CommunityNote>> notesForGameStream(String gameId) {
    return _notesRef
        .where('game_id', isEqualTo: gameId)
        .orderBy('upvotes', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CommunityNote.fromFirestore(d)).toList());
  }

  /// Add a new community note.
  static Future<void> addNote({
    required String gameId,
    required NoteCategory category,
    required String text,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final note = CommunityNote(
      id: '',
      gameId: gameId,
      userId: user.uid,
      userName: user.displayName ?? 'Anonymous',
      category: category,
      text: text,
      upvotes: 0,
    );
    await _notesRef.add(note.toFirestoreCreate());
  }

  /// Delete a note (only owner can delete).
  static Future<void> deleteNote(String noteId) async {
    final user = AuthService.currentUser;
    if (user == null) return;
    // Security rules enforce ownership
    await _notesRef.doc(noteId).delete();
  }

  /// Upvote a note (increment by 1).
  static Future<void> upvoteNote(String noteId) async {
    final user = AuthService.currentUser;
    if (user == null) return;
    await _notesRef.doc(noteId).update({
      'upvotes': FieldValue.increment(1),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
