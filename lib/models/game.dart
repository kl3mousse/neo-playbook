import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_helpers.dart';

/// Game image with source URL and metadata.
class GameImage {
  final String url;
  final String source;
  final int priority;
  final bool isPrimary;

  const GameImage({
    required this.url,
    required this.source,
    required this.priority,
    required this.isPrimary,
  });

  factory GameImage.fromMap(Map<String, dynamic> map) {
    return GameImage(
      url: map['url'] as String? ?? '',
      source: map['source'] as String? ?? '',
      priority: map['priority'] as int? ?? 2,
      isPrimary: map['is_primary'] as bool? ?? false,
    );
  }

  /// URL for display.
  String? get displayUrl => url.isNotEmpty ? url : null;
}

/// ROM version details for a game.
class GameRom {
  final String romName;
  final bool isParent;
  final String? region;
  final String? title;

  const GameRom({
    required this.romName,
    required this.isParent,
    this.region,
    this.title,
  });

  factory GameRom.fromMap(Map<String, dynamic> map) {
    return GameRom(
      romName: map['rom_name'] as String? ?? '',
      isParent: map['is_parent'] as bool? ?? false,
      region: map['region'] as String?,
      title: map['title'] as String?,
    );
  }
}

/// Content availability flags.
class GameFeatures {
  final bool hasMoveLists;
  final bool hasSoftDips;
  final bool hasDebugDips;

  const GameFeatures({
    this.hasMoveLists = false,
    this.hasSoftDips = false,
    this.hasDebugDips = false,
  });

  factory GameFeatures.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const GameFeatures();
    return GameFeatures(
      hasMoveLists: map['has_move_lists'] as bool? ?? false,
      hasSoftDips: map['has_soft_dips'] as bool? ?? false,
      hasDebugDips: map['has_debug_dips'] as bool? ?? false,
    );
  }
}

/// Cross-collection navigation IDs.
class ContentLinks {
  final String? movesProfileId;
  final String? softdipProfileId;
  final String? debugdipProfileId;
  final String? mediaProfileId;

  const ContentLinks({
    this.movesProfileId,
    this.softdipProfileId,
    this.debugdipProfileId,
    this.mediaProfileId,
  });

  factory ContentLinks.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ContentLinks();
    return ContentLinks(
      movesProfileId: map['moves_profile_id'] as String?,
      softdipProfileId: map['softdip_profile_id'] as String?,
      debugdipProfileId: map['debugdip_profile_id'] as String?,
      mediaProfileId: map['media_profile_id'] as String?,
    );
  }
}

/// Arcade game model matching the Firestore v2 schema.
class Game {
  final String id;
  final String pageType;
  final String platform;
  final int? hfsdbId;
  final int? ngmId;
  final String? igdbUrl;
  final String title;
  final String? altTitle;
  final int? year;
  final String? publisher;
  final List<String> genre;
  final int? nbPlayers;
  final String? description;
  final Map<String, GameImage> images;
  final List<GameRom> roms;
  final GameFeatures features;
  final ContentLinks contentLinks;
  final Timestamp? syncedAt;

  const Game({
    required this.id,
    required this.pageType,
    required this.platform,
    this.hfsdbId,
    this.ngmId,
    this.igdbUrl,
    required this.title,
    this.altTitle,
    this.year,
    this.publisher,
    required this.genre,
    this.nbPlayers,
    this.description,
    required this.images,
    required this.roms,
    required this.features,
    required this.contentLinks,
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

    // Parse genre (array of strings)
    List<String> genre = [];
    if (data['genre'] is List) {
      genre = List<String>.from(data['genre']);
    }

    return Game(
      id: doc.id,
      pageType: data['page_type'] as String? ?? 'game',
      platform: data['platform'] as String? ?? '',
      hfsdbId: data['hfsdb_id'] as int?,
      ngmId: data['platform_specific'] is Map
          ? _parseInt((data['platform_specific'] as Map)['ngm_id'])
          : null,
      igdbUrl: data['igdb_url'] as String?,
      title: data['title'] as String? ?? '',
      altTitle: data['alt_title'] as String?,
      year: _parseInt(data['year']),
      publisher: data['publisher'] as String?,
      genre: genre,
      nbPlayers: _parseInt(data['nb_players']),
      description: data['description'] as String?,
      images: imagesMap,
      roms: romsList,
      features: GameFeatures.fromMap(
          data['features'] as Map<String, dynamic>?),
      contentLinks: ContentLinks.fromMap(
          data['content_links'] as Map<String, dynamic>?),
      syncedAt: parseTimestamp(data['synced_at']),
    );
  }

  /// Primary display genre (first in list, or empty).
  String get primaryGenre => genre.isNotEmpty ? genre.first : '';

  /// Formatted player count for display.
  String get playersLabel =>
      nbPlayers != null ? '$nbPlayers Player${nbPlayers == 1 ? '' : 's'}' : '';

  /// Year as display string.
  String get yearLabel => year?.toString() ?? '';
}

/// Safely parse an int from dynamic Firestore data.
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
