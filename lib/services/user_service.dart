import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_profile.dart';
import '../models/user_favorite.dart';
import '../models/fave_move_list.dart';
import '../experimental/gold_moves_profile_v1/presentation/gold_rendering_options.dart';
import '../models/collection_item.dart';
import '../models/social_link.dart';
import 'auth_service.dart';
import 'prefs_service.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;
  static const _dbName = 'otakudb';

  static FirebaseFirestore get _namedDb =>
      FirebaseFirestore.instanceFor(app: _db.app, databaseId: _dbName);

  static CollectionReference<Map<String, dynamic>> get _usersRef =>
      _namedDb.collection('users');

  static CollectionReference<Map<String, dynamic>> get _feedbackRef =>
      _namedDb.collection('feedback');

  static CollectionReference<Map<String, dynamic>> get _deletionRequestsRef =>
      _namedDb.collection('account_deletion_requests');

  static CollectionReference<Map<String, dynamic>> _favoritesRef(String uid) =>
      _usersRef.doc(uid).collection('favorites');

  static CollectionReference<Map<String, dynamic>> _collectionRef(String uid) =>
      _usersRef.doc(uid).collection('collection');

  static CollectionReference<Map<String, dynamic>> _scanJobsRef(String uid) =>
      _usersRef.doc(uid).collection('scan_jobs');

  static CollectionReference<Map<String, dynamic>> _faveMovesRef(String uid) =>
      _usersRef.doc(uid).collection('fave_moves');

  static Future<void> _deleteAllDocs(Query<Map<String, dynamic>> query) async {
    while (true) {
      final snap = await query.limit(300).get();
      if (snap.docs.isEmpty) break;

      final batch = _namedDb.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  // ── User Profile ──────────────────────────────────────────────────────

  /// Get or create user profile after sign-in/sign-up.
  static Future<UserProfile> getOrCreateProfile() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final doc = await _usersRef.doc(user.uid).get();
    if (doc.exists) {
      final profile = UserProfile.fromFirestore(doc);
      await PrefsService.setPreferredLanguage(profile.preferredLanguage);
      await PrefsService.setDefaultCurrency(profile.defaultCurrency);
      await PrefsService.setGoldMoveNotation(
        GoldNotationStorage.parse(profile.goldMoveNotation),
      );
      await PrefsService.setGoldMoveDensity(
        GoldDensityStorage.parse(profile.goldMoveDensity),
      );
      return profile;
    }

    final profile = UserProfile(
      uid: user.uid,
      displayName: user.displayName ?? '',
      email: user.email ?? '',
      preferredLanguage: PrefsService.getPreferredLanguage() ?? '',
      defaultCurrency: PrefsService.getDefaultCurrency() ?? 'USD',
      goldMoveNotation: PrefsService.getGoldMoveNotation().storageValue,
      goldMoveDensity: PrefsService.getGoldMoveDensity().storageValue,
    );
    await _usersRef.doc(user.uid).set(profile.toFirestoreCreate());
    final created = await _usersRef.doc(user.uid).get();
    return UserProfile.fromFirestore(created);
  }

  /// Update user profile.
  static Future<void> updateProfile({
    required String displayName,
    String? photoUrl,
    String? bio,
    List<SocialLink>? socialLinks,
    String? preferredLanguage,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final data = <String, dynamic>{
      'display_name': displayName,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (photoUrl != null) {
      data['photo_url'] = photoUrl;
    }
    if (bio != null) {
      data['bio'] = bio.trim();
    }
    if (socialLinks != null) {
      data['social_links'] = socialLinks
          .where((l) => l.isValid)
          .map((l) => l.toMap())
          .toList();
    }
    if (preferredLanguage != null) {
      data['preferred_language'] = preferredLanguage;
      await PrefsService.setPreferredLanguage(preferredLanguage);
    }
    await _usersRef.doc(user.uid).update(data);
  }

  /// Persist the user's default currency both in Firestore (on the profile
  /// document) and locally via [PrefsService] so it stays consistent across
  /// sessions and offline restarts.
  static Future<void> updateDefaultCurrency(String currency) async {
    await PrefsService.setDefaultCurrency(currency);
    final user = AuthService.currentUser;
    if (user == null) return;
    await _usersRef.doc(user.uid).update({
      'default_currency': currency,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Persists Gold move-list presentation choices locally first, then mirrors
  /// them to the signed-in user's existing profile document.
  static Future<void> updateGoldMovePreferences({
    required GoldNotation notation,
    required GoldDensity density,
  }) async {
    await PrefsService.setGoldMoveNotation(notation);
    await PrefsService.setGoldMoveDensity(density);
    final user = AuthService.currentUser;
    if (user == null) return;
    await _usersRef.doc(user.uid).set({
      'gold_move_notation': notation.storageValue,
      'gold_move_density': density.storageValue,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Support and Feedback ─────────────────────────────────────────────

  static Future<void> submitFeedback({
    required String message,
    String? contactEmail,
  }) async {
    final user = AuthService.currentUser;
    await _feedbackRef.add({
      'message': message.trim(),
      'contact_email': (contactEmail ?? user?.email ?? '').trim(),
      'uid': user?.uid,
      'submitted_at': FieldValue.serverTimestamp(),
      'status': 'new',
      'source': 'app',
    });
  }

  // ── Account Deletion ────────────────────────────────────────────────

  static Future<void> requestAccountDeletion({String? reason}) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _deletionRequestsRef.doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'reason': (reason ?? 'User requested deletion in app').trim(),
      'status': 'requested',
      'requested_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteCurrentAccount({String? reason}) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await requestAccountDeletion(reason: reason);

    await _deleteAllDocs(_favoritesRef(user.uid));
    await _deleteAllDocs(_collectionRef(user.uid));
    await _deleteAllDocs(_faveMovesRef(user.uid));
    await _deleteAllDocs(
      _namedDb
          .collection('community_notes')
          .where('user_id', isEqualTo: user.uid),
    );
    await _deleteAllDocs(
      _namedDb.collection('scores').where('user_id', isEqualTo: user.uid),
    );

    await _usersRef.doc(user.uid).delete();

    final profilePicRef = FirebaseStorage.instance.ref().child(
      'profile_pics/${user.uid}.jpg',
    );
    try {
      await profilePicRef.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        rethrow;
      }
    }

    try {
      await AuthService.deleteCurrentUser();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw StateError(
          'Recent sign-in required. Please sign in again, then retry account deletion.',
        );
      }
      rethrow;
    }

    await AuthService.signOut();
  }

  // ── Favorites ─────────────────────────────────────────────────────────

  /// Set or update a game's favorite status.
  static Future<void> setFavorite(String gameId, FavoriteStatus status) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final ref = _favoritesRef(user.uid).doc(gameId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.update(
        UserFavorite(gameId: gameId, status: status).toFirestore(),
      );
    } else {
      await ref.set(
        UserFavorite(gameId: gameId, status: status).toFirestoreCreate(),
      );
    }
  }

  /// Remove a game from favorites.
  static Future<void> removeFavorite(String gameId) async {
    final user = AuthService.currentUser;
    if (user == null) return;
    await _favoritesRef(user.uid).doc(gameId).delete();
  }

  /// Stream all user favorites.
  static Stream<List<UserFavorite>> favoritesStream() {
    final user = AuthService.currentUser;
    if (user == null) return Stream.value([]);
    return _favoritesRef(user.uid).snapshots().map(
      (snap) => snap.docs.map((d) => UserFavorite.fromFirestore(d)).toList(),
    );
  }

  /// Get favorite status for a single game.
  static Future<UserFavorite?> getFavoriteStatus(String gameId) async {
    final user = AuthService.currentUser;
    if (user == null) return null;
    final doc = await _favoritesRef(user.uid).doc(gameId).get();
    if (!doc.exists) return null;
    return UserFavorite.fromFirestore(doc);
  }

  /// Stream favorite status for a single game.
  static Stream<UserFavorite?> favoriteStatusStream(String gameId) {
    final user = AuthService.currentUser;
    if (user == null) return Stream.value(null);
    return _favoritesRef(user.uid)
        .doc(gameId)
        .snapshots()
        .map((doc) => doc.exists ? UserFavorite.fromFirestore(doc) : null);
  }

  // ── Collection ────────────────────────────────────────────────────────

  /// Add an item to the user's collection.
  /// Returns the new document id, or null if not authenticated.
  static Future<String?> addToCollection(CollectionItem item) async {
    final user = AuthService.currentUser;
    if (user == null) return null;
    final ref = await _collectionRef(user.uid).add(item.toFirestoreCreate());
    return ref.id;
  }

  /// Remove an item from the collection.
  static Future<void> removeFromCollection(String itemId) async {
    final user = AuthService.currentUser;
    if (user == null) return;
    await _collectionRef(user.uid).doc(itemId).delete();
  }

  /// Update a collection item.
  static Future<void> updateCollectionItem(
    String itemId,
    CollectionItem item,
  ) async {
    final user = AuthService.currentUser;
    if (user == null) return;
    await _collectionRef(user.uid).doc(itemId).update(item.toFirestoreUpdate());
  }

  /// Mark an unverified (draft) collection item as verified.
  static Future<void> markCollectionItemVerified(String itemId) async {
    final user = AuthService.currentUser;
    if (user == null) return;
    await _collectionRef(user.uid).doc(itemId).update({
      'is_unverified': false,
      'verified_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<bool> _collectionEntryExistsForScanCandidate(
    String uid,
    String scanJobId,
    String scanCandidateId,
  ) async {
    final existing = await _collectionRef(uid)
        .where('scan_job_id', isEqualTo: scanJobId)
        .where('scan_candidate_id', isEqualTo: scanCandidateId)
        .limit(1)
        .get();
    return existing.docs.isNotEmpty;
  }

  static Future<void> importRecognizedItem({
    required String scanJobId,
    required String scanCandidateId,
    required String gameId,
    required String gameTitle,
    required String platform,
    required double confidence,
    required bool unverified,
    String? notes,
    String? imagePath,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    if (await _collectionEntryExistsForScanCandidate(
      user.uid,
      scanJobId,
      scanCandidateId,
    )) {
      return;
    }

    final item = CollectionItem(
      id: '',
      gameId: gameId,
      gameTitle: gameTitle,
      platform: platform.isNotEmpty ? platform.toLowerCase() : 'mvs',
      format: ItemFormat.cartridge,
      condition: ItemCondition.good,
      region: 'jp',
      notes: notes,
      imagePaths: imagePath != null ? [imagePath] : const [],
      isUnverified: unverified,
      scanJobId: scanJobId,
      scanCandidateId: scanCandidateId,
      recognitionConfidence: confidence,
      importSource: 'scan',
      verifiedAt: unverified ? null : Timestamp.now(),
    );

    await _collectionRef(user.uid).add(item.toFirestoreCreate());
  }

  static Future<void> markScanJobImported(
    String scanJobId,
    String importStatus,
  ) async {
    final user = AuthService.currentUser;
    if (user == null) return;
    await _scanJobsRef(user.uid).doc(scanJobId).set({
      'import_status': importStatus,
      'imported_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<CollectionItem?> getCollectionItemForScanCandidate({
    required String scanJobId,
    required String scanCandidateId,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return null;

    final snap = await _collectionRef(user.uid)
        .where('scan_job_id', isEqualTo: scanJobId)
        .where('scan_candidate_id', isEqualTo: scanCandidateId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      return null;
    }
    return CollectionItem.fromFirestore(snap.docs.first);
  }

  // ── Collection Item Photos ──────────────────────────────────────────

  static Future<String> uploadCollectionItemPhoto({
    required String itemId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String? fileName,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    final extension = contentType.contains('png')
        ? 'png'
        : contentType.contains('webp')
        ? 'webp'
        : 'jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = (fileName ?? 'photo').replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );
    final storagePath =
        'collection_items/${user.uid}/$itemId/${timestamp}_$safeName.$extension';
    await FirebaseStorage.instance
        .ref()
        .child(storagePath)
        .putData(bytes, SettableMetadata(contentType: contentType));
    return storagePath;
  }

  static Future<void> attachPhotoToCollectionItem({
    required String itemId,
    required String storagePath,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return;
    await _collectionRef(user.uid).doc(itemId).update({
      'image_paths': FieldValue.arrayUnion([storagePath]),
    });
  }

  static Future<void> removePhotoFromCollectionItem({
    required String itemId,
    required String storagePath,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    await _collectionRef(user.uid).doc(itemId).update({
      'image_paths': FieldValue.arrayRemove([storagePath]),
    });

    try {
      await FirebaseStorage.instance.ref().child(storagePath).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        rethrow;
      }
    }
  }

  static Future<String> resolveCollectionItemPhotoUrl(
    String storagePath,
  ) async {
    return FirebaseStorage.instance.ref().child(storagePath).getDownloadURL();
  }

  /// Stream a single collection item by id (live updates after edits).
  static Stream<CollectionItem?> collectionItemStream(String itemId) {
    final user = AuthService.currentUser;
    if (user == null) return Stream.value(null);
    return _collectionRef(user.uid)
        .doc(itemId)
        .snapshots()
        .map((doc) => doc.exists ? CollectionItem.fromFirestore(doc) : null);
  }

  /// Stream all collection items.
  static Stream<List<CollectionItem>> collectionStream() {
    final user = AuthService.currentUser;
    if (user == null) return Stream.value([]);
    return _collectionRef(user.uid)
        .orderBy('added_at', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => CollectionItem.fromFirestore(d)).toList(),
        );
  }

  /// Get collection items for a specific game.
  static Future<List<CollectionItem>> getCollectionForGame(
    String gameId,
  ) async {
    final user = AuthService.currentUser;
    if (user == null) return [];
    final snap = await _collectionRef(
      user.uid,
    ).where('game_id', isEqualTo: gameId).get();
    return snap.docs.map((d) => CollectionItem.fromFirestore(d)).toList();
  }

  // ── Favorite Move Lists ────────────────────────────────────────────

  /// Toggle a character move list section as bookmarked.
  static Future<void> toggleFaveMove({
    required String gameId,
    required String gameTitle,
    required String romName,
    required String sectionTitle,
    String? sectionSubtitle,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final docId = FaveMoveList.docId(romName, sectionTitle);
    final ref = _faveMovesRef(user.uid).doc(docId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set(
        FaveMoveList(
          id: docId,
          gameId: gameId,
          gameTitle: gameTitle,
          romName: romName,
          sectionTitle: sectionTitle,
          sectionSubtitle: sectionSubtitle,
        ).toFirestoreCreate(),
      );
    }
  }

  /// Stream all bookmarked move list sections (most recent first).
  static Stream<List<FaveMoveList>> faveMovesStream() {
    final user = AuthService.currentUser;
    if (user == null) return Stream.value([]);
    return _faveMovesRef(user.uid)
        .orderBy('added_at', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => FaveMoveList.fromFirestore(d)).toList(),
        );
  }

  /// Stream whether a specific section is bookmarked.
  static Stream<bool> isFaveMoveStream(String romName, String sectionTitle) {
    final user = AuthService.currentUser;
    if (user == null) return Stream.value(false);
    final docId = FaveMoveList.docId(romName, sectionTitle);
    return _faveMovesRef(
      user.uid,
    ).doc(docId).snapshots().map((doc) => doc.exists);
  }

  /// Remove a bookmarked move list by doc ID.
  static Future<void> removeFaveMove(String docId) async {
    final user = AuthService.currentUser;
    if (user == null) return;
    await _faveMovesRef(user.uid).doc(docId).delete();
  }

  /// Stream collection items for a specific game.
  static Stream<List<CollectionItem>> collectionForGameStream(String gameId) {
    final user = AuthService.currentUser;
    if (user == null) return Stream.value([]);
    return _collectionRef(user.uid)
        .where('game_id', isEqualTo: gameId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => CollectionItem.fromFirestore(d)).toList(),
        );
  }
}
