import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_helpers.dart';

enum FavoriteStatus {
  wantToPlay('want_to_play', 'Want to Play', '🎯'),
  playing('playing', 'Playing', '🎮'),
  played('played', 'Played', '✅'),
  mastered('mastered', 'Mastered', '🏆');

  final String value;
  final String label;
  final String icon;
  const FavoriteStatus(this.value, this.label, this.icon);

  static FavoriteStatus fromValue(String value) {
    return FavoriteStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => FavoriteStatus.wantToPlay,
    );
  }
}

class UserFavorite {
  final String gameId;
  final FavoriteStatus status;
  final Timestamp? addedAt;
  final Timestamp? updatedAt;

  const UserFavorite({
    required this.gameId,
    required this.status,
    this.addedAt,
    this.updatedAt,
  });

  factory UserFavorite.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserFavorite(
      gameId: doc.id,
      status: FavoriteStatus.fromValue(data['status'] as String? ?? ''),
      addedAt: parseTimestamp(data['added_at']),
      updatedAt: parseTimestamp(data['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'status': status.value,
        'updated_at': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toFirestoreCreate() => {
        'status': status.value,
        'added_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
}
