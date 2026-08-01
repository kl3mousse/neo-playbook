import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_helpers.dart';
import 'social_link.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String bio;
  final List<SocialLink> socialLinks;
  final String preferredLanguage;
  final String defaultCurrency;
  final String goldMoveNotation;
  final String goldMoveDensity;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.bio = '',
    this.socialLinks = const <SocialLink>[],
    this.preferredLanguage = '',
    this.defaultCurrency = 'USD',
    this.goldMoveNotation = 'pictograms',
    this.goldMoveDensity = 'compact',
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawLinks = data['social_links'];
    final links = <SocialLink>[];
    if (rawLinks is List) {
      for (final entry in rawLinks) {
        if (entry is Map) {
          final link = SocialLink.fromMap(Map<String, dynamic>.from(entry));
          if (link.isValid) links.add(link);
        }
      }
    }
    return UserProfile(
      uid: doc.id,
      displayName: data['display_name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photo_url'] as String?,
      bio: data['bio'] as String? ?? '',
      socialLinks: links,
      preferredLanguage: data['preferred_language'] as String? ?? '',
      defaultCurrency: data['default_currency'] as String? ?? 'USD',
      goldMoveNotation: data['gold_move_notation'] as String? ?? 'pictograms',
      goldMoveDensity: data['gold_move_density'] as String? ?? 'compact',
      createdAt: parseTimestamp(data['created_at']),
      updatedAt: parseTimestamp(data['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'display_name': displayName,
    'email': email,
    if (photoUrl != null) 'photo_url': photoUrl,
    'bio': bio,
    'social_links': socialLinks.map((l) => l.toMap()).toList(),
    'preferred_language': preferredLanguage,
    'default_currency': defaultCurrency,
    'gold_move_notation': goldMoveNotation,
    'gold_move_density': goldMoveDensity,
    'updated_at': FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toFirestoreCreate() => {
    'display_name': displayName,
    'email': email,
    if (photoUrl != null) 'photo_url': photoUrl,
    'bio': bio,
    'social_links': socialLinks.map((l) => l.toMap()).toList(),
    'preferred_language': preferredLanguage,
    'default_currency': defaultCurrency,
    'gold_move_notation': goldMoveNotation,
    'gold_move_density': goldMoveDensity,
    'created_at': FieldValue.serverTimestamp(),
    'updated_at': FieldValue.serverTimestamp(),
  };
}
