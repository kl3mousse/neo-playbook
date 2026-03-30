import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_helpers.dart';

/// Game image data with source URL and Firebase Storage path.
class GameImage {
  final String? url;
  final String? storageUrl;
  final String? storagePath;

  const GameImage({this.url, this.storageUrl, this.storagePath});

  factory GameImage.fromMap(Map<String, dynamic> map) {
    return GameImage(
      url: map['url'] as String?,
      storageUrl: map['storage_url'] as String?,
      storagePath: map['storage_path'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'url': url,
        'storage_url': storageUrl,
        'storage_path': storagePath,
      };

  /// Best available URL for display (prefer storage, fallback to source).
  String? get displayUrl => storageUrl ?? url;
}

/// ROM version details for a game.
class GameRom {
  final String romName;
  final String description;
  final String year;
  final String publisher;
  final String serial;
  final String release;
  final String platformTag;
  final String compatibility;
  final bool excludeSoftdips;

  const GameRom({
    required this.romName,
    required this.description,
    required this.year,
    required this.publisher,
    required this.serial,
    required this.release,
    required this.platformTag,
    required this.compatibility,
    required this.excludeSoftdips,
  });

  factory GameRom.fromMap(Map<String, dynamic> map) {
    return GameRom(
      romName: map['rom_name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      year: map['year']?.toString() ?? '',
      publisher: map['publisher'] as String? ?? '',
      serial: map['serial'] as String? ?? '',
      release: map['release']?.toString() ?? '',
      platformTag: map['platform_tag'] as String? ?? '',
      compatibility: map['compatibility'] as String? ?? '',
      excludeSoftdips: map['exclude_softdips'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'rom_name': romName,
        'description': description,
        'year': year,
        'publisher': publisher,
        'serial': serial,
        'release': release,
        'platform_tag': platformTag,
        'compatibility': compatibility,
        'exclude_softdips': excludeSoftdips,
      };
}

/// Neo Geo game model matching the Firestore schema.
class Game {
  final String id;
  final String pageType;
  final List<String> platforms;
  final int? hfsdbId;
  final String title;
  final String? altTitle;
  final String year;
  final String publisher;
  final String type;
  final String generation;
  final String genre;
  final String nbPlayers;
  final String? description;
  final Map<String, GameImage> images;
  final int backgroundVshift;
  final bool invertScreenshots;
  final List<GameRom> roms;
  final String? ngmId;
  final String? megs;
  final Timestamp? syncedAt;

  const Game({
    required this.id,
    required this.pageType,
    required this.platforms,
    this.hfsdbId,
    required this.title,
    this.altTitle,
    required this.year,
    required this.publisher,
    required this.type,
    required this.generation,
    required this.genre,
    required this.nbPlayers,
    this.description,
    required this.images,
    required this.backgroundVshift,
    required this.invertScreenshots,
    required this.roms,
    this.ngmId,
    this.megs,
    this.syncedAt,
  });

  factory Game.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse images map
    final imagesMap = <String, GameImage>{};
    if (data['images'] is Map) {
      (data['images'] as Map<String, dynamic>).forEach((key, value) {
        if (value is Map<String, dynamic>) {
          imagesMap[key] = GameImage.fromMap(value);
        }
      });
    }

    // Parse roms list
    final romsList = <GameRom>[];
    if (data['roms'] is List) {
      for (final rom in data['roms'] as List) {
        if (rom is Map<String, dynamic>) {
          romsList.add(GameRom.fromMap(rom));
        }
      }
    }

    // Platform-specific fields
    final ps = data['platform_specific'] as Map<String, dynamic>?;

    // Parse platforms (support both legacy 'platform' and new 'platforms')
    List<String> platforms = [];
    if (data['platforms'] is List) {
      platforms = List<String>.from(data['platforms']);
    } else if (data['platform'] is String) {
      platforms = [data['platform'] as String];
    }

    return Game(
      id: doc.id,
      pageType: data['page_type'] as String? ?? 'game',
      platforms: platforms,
      hfsdbId: data['hfsdb_id'] as int?,
      title: data['title'] as String? ?? '',
      altTitle: data['alt_title'] as String?,
      year: data['year']?.toString() ?? '',
      publisher: data['publisher'] as String? ?? '',
      type: data['type'] as String? ?? '',
      generation: data['generation'] as String? ?? '',
      genre: data['genre'] as String? ?? '',
      nbPlayers: data['nb_players'] as String? ?? '',
      description: data['description'] as String?,
      images: imagesMap,
      backgroundVshift: data['background_vshift'] as int? ?? 0,
      invertScreenshots: data['invert_screenshots'] as bool? ?? false,
      roms: romsList,
      ngmId: ps?['ngm_id']?.toString(),
      megs: ps?['megs']?.toString(),
      syncedAt: parseTimestamp(data['synced_at']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'page_type': pageType,
        'platforms': platforms,
        'id': id,
        'hfsdb_id': hfsdbId,
        'title': title,
        'alt_title': altTitle,
        'year': year,
        'publisher': publisher,
        'type': type,
        'generation': generation,
        'genre': genre,
        'nb_players': nbPlayers,
        'description': description,
        'images': images.map((k, v) => MapEntry(k, v.toMap())),
        'background_vshift': backgroundVshift,
        'invert_screenshots': invertScreenshots,
        'roms': roms.map((r) => r.toMap()).toList(),
        'platform_specific': {
          'ngm_id': ngmId,
          'megs': megs,
        },
        'synced_at': FieldValue.serverTimestamp(),
      };
}
