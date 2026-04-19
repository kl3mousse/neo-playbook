import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_helpers.dart';

/// A bookmarked character/player move list section.
///
/// Stored at `users/{uid}/fave_moves/{docId}` where docId is a
/// sanitised composite of romName + sectionTitle for idempotent toggle.
class FaveMoveList {
  final String id;
  final String gameId;
  final String gameTitle;
  final String romName;
  final String sectionTitle;
  final String? sectionSubtitle;
  final Timestamp? addedAt;

  const FaveMoveList({
    required this.id,
    required this.gameId,
    required this.gameTitle,
    required this.romName,
    required this.sectionTitle,
    this.sectionSubtitle,
    this.addedAt,
  });

  factory FaveMoveList.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FaveMoveList(
      id: doc.id,
      gameId: data['game_id'] as String? ?? '',
      gameTitle: data['game_title'] as String? ?? '',
      romName: data['rom_name'] as String? ?? '',
      sectionTitle: data['section_title'] as String? ?? '',
      sectionSubtitle: data['section_subtitle'] as String?,
      addedAt: parseTimestamp(data['added_at']),
    );
  }

  Map<String, dynamic> toFirestoreCreate() => {
        'game_id': gameId,
        'game_title': gameTitle,
        'rom_name': romName,
        'section_title': sectionTitle,
        if (sectionSubtitle != null) 'section_subtitle': sectionSubtitle,
        'added_at': FieldValue.serverTimestamp(),
      };

  /// Build a stable document ID from romName + sectionTitle.
  static String docId(String romName, String sectionTitle) {
    final sanitised = '${romName}_$sectionTitle'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return sanitised;
  }
}
