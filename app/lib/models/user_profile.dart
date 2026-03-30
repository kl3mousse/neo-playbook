import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_helpers.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile(
      uid: doc.id,
      displayName: data['display_name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photo_url'] as String?,
      createdAt: parseTimestamp(data['created_at']),
      updatedAt: parseTimestamp(data['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'display_name': displayName,
        'email': email,
        if (photoUrl != null) 'photo_url': photoUrl,
        'updated_at': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toFirestoreCreate() => {
        'display_name': displayName,
        'email': email,
        if (photoUrl != null) 'photo_url': photoUrl,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
}
