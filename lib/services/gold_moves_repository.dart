import 'package:cloud_firestore/cloud_firestore.dart';

import '../experimental/gold_moves_profile_v1/domain/move.dart';
import '../experimental/gold_moves_profile_v1/domain/profile.dart';
import '../experimental/gold_moves_profile_v1/parsing/profile_parser.dart';
import 'firestore_service.dart';

/// A minimal document abstraction makes the publication reader testable
/// without a Firebase emulator.
abstract interface class GoldMovesDataSource {
  Future<GoldMovesDocument?> getDocument(String path);
}

class GoldMovesDocument {
  final Map<String, dynamic> data;
  final bool isFromCache;

  const GoldMovesDocument({required this.data, required this.isFromCache});
}

class FirestoreGoldMovesDataSource implements GoldMovesDataSource {
  final FirebaseFirestore _db;

  FirestoreGoldMovesDataSource({FirebaseFirestore? db})
    : _db = db ?? FirestoreService.namedDb;

  @override
  Future<GoldMovesDocument?> getDocument(String path) async {
    final snapshot = await _db.doc(path).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return GoldMovesDocument(
      data: data,
      isFromCache: snapshot.metadata.isFromCache,
    );
  }
}

enum GoldMovesFailureKind {
  manifestNotFound,
  invalidManifest,
  unsupportedContract,
  noActiveProfile,
  invalidActivePath,
  profileNotFound,
  invalidProfile,
  payloadMissing,
  permissionDenied,
  unavailable,
  firestore,
}

class GoldMovesRepositoryException implements Exception {
  final GoldMovesFailureKind kind;
  final Object? cause;

  const GoldMovesRepositoryException(this.kind, {this.cause});

  @override
  String toString() => 'GoldMovesRepositoryException($kind)';
}

class GoldMovesManifest {
  final String gameId;
  final String activeProfileId;
  final String activeProfilePath;
  final String payloadSha256;
  final String goldSchemaVersion;
  final int profileRevision;

  const GoldMovesManifest({
    required this.gameId,
    required this.activeProfileId,
    required this.activeProfilePath,
    required this.payloadSha256,
    required this.goldSchemaVersion,
    required this.profileRevision,
  });
}

class GoldMovesPublishedProfile {
  final ProfileGold profile;
  final GoldMovesManifest manifest;
  final String payloadSha256;
  final bool isFromCache;

  const GoldMovesPublishedProfile({
    required this.profile,
    required this.manifest,
    required this.payloadSha256,
    required this.isFromCache,
  });
}

/// Reads the `combofox-gold-moves-firestore` v1 publication contract.
///
/// The SHA-256 belongs to the original UTF-8 JSON bytes. Firestore does not
/// preserve those bytes, so this reader checks equality between the manifest
/// and immutable version document rather than inventing a re-serialization.
class GoldMovesRepository {
  static const _contract = 'combofox-gold-moves-firestore';
  final GoldMovesDataSource _dataSource;
  final ProfileParser _parser;

  GoldMovesRepository({
    GoldMovesDataSource? dataSource,
    ProfileParser parser = const ProfileParser(),
  }) : _dataSource = dataSource ?? FirestoreGoldMovesDataSource(),
       _parser = parser;

  Future<GoldMovesPublishedProfile> loadProfile(String gameId) async {
    try {
      final manifestPath = 'move_profiles/$gameId';
      final manifestDocument = await _dataSource.getDocument(manifestPath);
      if (manifestDocument == null) {
        throw const GoldMovesRepositoryException(
          GoldMovesFailureKind.manifestNotFound,
        );
      }
      final manifest = _parseManifest(manifestDocument.data, gameId);

      final versionDocument = await _dataSource.getDocument(
        manifest.activeProfilePath,
      );
      if (versionDocument == null) {
        throw const GoldMovesRepositoryException(
          GoldMovesFailureKind.profileNotFound,
        );
      }
      final profile = _parseVersion(
        versionDocument.data,
        manifest: manifest,
        gameId: gameId,
      );
      return GoldMovesPublishedProfile(
        profile: profile,
        manifest: manifest,
        payloadSha256: manifest.payloadSha256,
        isFromCache:
            manifestDocument.isFromCache || versionDocument.isFromCache,
      );
    } on GoldMovesRepositoryException {
      rethrow;
    } on FirebaseException catch (error) {
      throw GoldMovesRepositoryException(
        _firestoreFailure(error),
        cause: error,
      );
    } catch (error) {
      throw GoldMovesRepositoryException(
        GoldMovesFailureKind.invalidProfile,
        cause: error,
      );
    }
  }

  GoldMovesManifest _parseManifest(Map<String, dynamic> data, String gameId) {
    if (data['publication_contract'] != _contract) {
      throw const GoldMovesRepositoryException(
        GoldMovesFailureKind.unsupportedContract,
      );
    }
    final version = _string(data, 'publication_contract_version');
    if (!version.startsWith('1.')) {
      throw const GoldMovesRepositoryException(
        GoldMovesFailureKind.unsupportedContract,
      );
    }
    if (_string(data, 'game_id') != gameId) {
      throw const GoldMovesRepositoryException(
        GoldMovesFailureKind.invalidManifest,
      );
    }
    final rawActiveProfileId = data['active_profile_id'];
    if (rawActiveProfileId == null || rawActiveProfileId == '') {
      throw const GoldMovesRepositoryException(
        GoldMovesFailureKind.noActiveProfile,
      );
    }
    if (rawActiveProfileId is! String) {
      throw const GoldMovesRepositoryException(
        GoldMovesFailureKind.invalidManifest,
      );
    }
    final activeProfileId = rawActiveProfileId;
    final expectedPath = 'move_profiles/$gameId/versions/$activeProfileId';
    final configuredPath = data['active_profile_path'];
    if (configuredPath != null && configuredPath != expectedPath) {
      throw const GoldMovesRepositoryException(
        GoldMovesFailureKind.invalidActivePath,
      );
    }
    final goldVersion = _string(data, 'gold_schema_version');
    if (!goldVersion.startsWith('1.')) {
      throw const GoldMovesRepositoryException(
        GoldMovesFailureKind.invalidManifest,
      );
    }
    return GoldMovesManifest(
      gameId: gameId,
      activeProfileId: activeProfileId,
      activeProfilePath: expectedPath,
      payloadSha256: _string(data, 'active_payload_sha256'),
      goldSchemaVersion: goldVersion,
      profileRevision: _int(data, 'profile_revision'),
    );
  }

  ProfileGold _parseVersion(
    Map<String, dynamic> data, {
    required GoldMovesManifest manifest,
    required String gameId,
  }) {
    if (data['publication_contract'] != _contract ||
        !_string(
          data,
          'publication_contract_version',
          failureKind: GoldMovesFailureKind.invalidProfile,
        ).startsWith('1.')) {
      throw const GoldMovesRepositoryException(
        GoldMovesFailureKind.unsupportedContract,
      );
    }
    if (_string(
              data,
              'game_id',
              failureKind: GoldMovesFailureKind.invalidProfile,
            ) !=
            gameId ||
        _string(
              data,
              'profile_id',
              failureKind: GoldMovesFailureKind.invalidProfile,
            ) !=
            manifest.activeProfileId ||
        _string(
              data,
              'payload_sha256',
              failureKind: GoldMovesFailureKind.invalidProfile,
            ) !=
            manifest.payloadSha256 ||
        _int(
              data,
              'profile_revision',
              failureKind: GoldMovesFailureKind.invalidProfile,
            ) !=
            manifest.profileRevision ||
        _string(
              data,
              'gold_schema_version',
              failureKind: GoldMovesFailureKind.invalidProfile,
            ) !=
            manifest.goldSchemaVersion) {
      throw const GoldMovesRepositoryException(
        GoldMovesFailureKind.invalidProfile,
      );
    }
    final rawPayload = data['payload'];
    if (rawPayload is! Map) {
      throw const GoldMovesRepositoryException(
        GoldMovesFailureKind.payloadMissing,
      );
    }

    final ProfileGold profile;
    try {
      profile = _parser.parseMap(_normaliseMap(rawPayload));
    } catch (error) {
      throw GoldMovesRepositoryException(
        GoldMovesFailureKind.invalidProfile,
        cause: error,
      );
    }
    if (profile.id != manifest.activeProfileId ||
        profile.appliesTo.gameId != gameId ||
        !profile.goldSchemaVersion.startsWith('1.') ||
        profile.goldSchemaVersion != manifest.goldSchemaVersion ||
        profile.profileRevision != manifest.profileRevision) {
      throw const GoldMovesRepositoryException(
        GoldMovesFailureKind.invalidProfile,
      );
    }
    _validateCounts(data['counts'], profile, gameId);
    return profile;
  }

  void _validateCounts(Object? rawCounts, ProfileGold profile, String gameId) {
    if (rawCounts is! Map) {
      throw const GoldMovesRepositoryException(
        GoldMovesFailureKind.invalidProfile,
      );
    }
    final counts = _normaliseMap(rawCounts);
    final automatic = profile.moves
        .where(
          (move) => move.activation.kind == ActivationKind.automaticAfterMove,
        )
        .length;
    final byPlayer = profile.moves
        .where((move) => move.activation.kind == ActivationKind.byPlayerInput)
        .length;
    if (_int(
              counts,
              'characters',
              failureKind: GoldMovesFailureKind.invalidProfile,
            ) !=
            profile.characters.length ||
        _int(
              counts,
              'moves',
              failureKind: GoldMovesFailureKind.invalidProfile,
            ) !=
            profile.moves.length ||
        _int(
              counts,
              'by_player_input',
              failureKind: GoldMovesFailureKind.invalidProfile,
            ) !=
            byPlayer ||
        _int(
              counts,
              'automatic_after_move',
              failureKind: GoldMovesFailureKind.invalidProfile,
            ) !=
            automatic) {
      throw const GoldMovesRepositoryException(
        GoldMovesFailureKind.invalidProfile,
      );
    }
  }

  static String _string(
    Map<String, dynamic> map,
    String key, {
    GoldMovesFailureKind failureKind = GoldMovesFailureKind.invalidManifest,
  }) {
    final value = map[key];
    if (value is! String || value.isEmpty) {
      throw GoldMovesRepositoryException(failureKind);
    }
    return value;
  }

  static int _int(
    Map<String, dynamic> map,
    String key, {
    GoldMovesFailureKind failureKind = GoldMovesFailureKind.invalidManifest,
  }) {
    final value = map[key];
    if (value is! int) {
      throw GoldMovesRepositoryException(failureKind);
    }
    return value;
  }

  static Map<String, dynamic> _normaliseMap(Map map) => {
    for (final entry in map.entries)
      if (entry.key is String)
        entry.key as String: _normaliseValue(entry.value),
  };

  static Object? _normaliseValue(Object? value) {
    if (value is Map) return _normaliseMap(value);
    if (value is List) {
      return value.map(_normaliseValue).toList(growable: false);
    }
    return value;
  }

  static GoldMovesFailureKind _firestoreFailure(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return GoldMovesFailureKind.permissionDenied;
    }
    if (error.code == 'unavailable' || error.code == 'network-request-failed') {
      return GoldMovesFailureKind.unavailable;
    }
    return GoldMovesFailureKind.firestore;
  }
}
