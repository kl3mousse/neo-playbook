import 'package:cloud_firestore/cloud_firestore.dart';

enum NoteCategory {
  tip('tip', 'Tip'),
  strategy('strategy', 'Strategy'),
  combo('combo', 'Combo'),
  trivia('trivia', 'Trivia'),
  review('review', 'Review');

  final String value;
  final String label;
  const NoteCategory(this.value, this.label);

  static NoteCategory fromValue(String value) {
    return NoteCategory.values.firstWhere(
      (c) => c.value == value,
      orElse: () => NoteCategory.tip,
    );
  }
}

class CommunityNote {
  final String id;
  final String gameId;
  final String userId;
  final String userName;
  final NoteCategory category;
  final String text;
  final int upvotes;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const CommunityNote({
    required this.id,
    required this.gameId,
    required this.userId,
    required this.userName,
    required this.category,
    required this.text,
    required this.upvotes,
    this.createdAt,
    this.updatedAt,
  });

  factory CommunityNote.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CommunityNote(
      id: doc.id,
      gameId: data['game_id'] as String? ?? '',
      userId: data['user_id'] as String? ?? '',
      userName: data['user_name'] as String? ?? '',
      category: NoteCategory.fromValue(data['category'] as String? ?? ''),
      text: data['text'] as String? ?? '',
      upvotes: data['upvotes'] as int? ?? 0,
      createdAt: data['created_at'] as Timestamp?,
      updatedAt: data['updated_at'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestoreCreate() => {
        'game_id': gameId,
        'user_id': userId,
        'user_name': userName,
        'category': category.value,
        'text': text,
        'upvotes': 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
}
