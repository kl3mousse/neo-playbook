import 'package:flutter/services.dart';

import '../experimental/gold_moves_profile_v1/domain/profile.dart';
import '../experimental/gold_moves_profile_v1/parsing/asset_loader.dart';

/// Resolves the bundled Gold Moves Profile fixture used by the Lab and tests.
///
/// The mapping deliberately remains explicit while Gold is only used for KOF
/// R-2. Production game and favorite screens use [GoldMovesRepository]
/// instead; this resolver deliberately remains an explicit fixture helper.
class BundledGoldProfileResolver {
  static const String kofR2GameId = 'ngpc-kofr2';
  static const String kofR2ProfileId = 'ngpc-kofr2-v2';
  static const String kofR2SourceKey = kofR2ProfileId;
  static const Set<String> kofR2RomIds = {'kofr2', 'kofr2d', 'kofr2d2'};

  const BundledGoldProfileResolver({this.loadKofR2Profile});

  /// Injectable only to make bundle-validation failures deterministic in tests.
  final Future<ProfileGold> Function()? loadKofR2Profile;

  /// KOF R-2 is matched by catalog game ID first; recognized ROM IDs support
  /// legacy catalog records that predate the dedicated game ID.
  bool supports({required String gameId, Iterable<String> romIds = const []}) {
    if (gameId == kofR2GameId) return true;
    return romIds.any(kofR2RomIds.contains);
  }

  /// Returns null for unrelated games. A recognized KOF R-2 game either gets a
  /// validated local profile or throws [BundledGoldProfileException]; it never
  /// silently falls back to command.dat.
  Future<ProfileGold?> resolve({
    required String gameId,
    Iterable<String> romIds = const [],
    AssetBundle? bundle,
  }) async {
    if (!supports(gameId: gameId, romIds: romIds)) return null;

    try {
      final profile =
          await (loadKofR2Profile?.call() ??
              loadBundledKofR2Profile(bundle: bundle));
      _validateKofR2Profile(profile);
      return profile;
    } on BundledGoldProfileException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        BundledGoldProfileException(
          'Unable to load the bundled KOF R-2 profile: $error',
        ),
        stackTrace,
      );
    }
  }

  void _validateKofR2Profile(ProfileGold profile) {
    if (profile.id != kofR2ProfileId) {
      throw BundledGoldProfileException(
        'Unexpected Gold profile ID: ${profile.id}. Expected $kofR2ProfileId.',
      );
    }
    if (profile.appliesTo.gameId != kofR2GameId) {
      throw BundledGoldProfileException(
        'Bundled Gold profile applies to ${profile.appliesTo.gameId ?? 'no game'}, '
        'not $kofR2GameId.',
      );
    }
    if (!profile.appliesTo.romIds.any(kofR2RomIds.contains)) {
      throw BundledGoldProfileException(
        'Bundled Gold profile does not contain a recognized KOF R-2 ROM ID.',
      );
    }
  }
}

class BundledGoldProfileException implements Exception {
  final String message;

  const BundledGoldProfileException(this.message);

  @override
  String toString() => message;
}
