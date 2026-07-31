import 'package:flutter_test/flutter_test.dart';

import 'package:combofox/experimental/gold_moves_profile_v1/domain/profile.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/parsing/asset_loader.dart';
import 'package:combofox/services/bundled_gold_profile_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BundledGoldProfileResolver', () {
    const resolver = BundledGoldProfileResolver();

    test('recognizes KOF R-2 by catalog game ID', () {
      expect(resolver.supports(gameId: 'ngpc-kofr2'), isTrue);
    });

    test('recognizes KOF R-2 by an expected ROM ID fallback', () {
      for (final romId in BundledGoldProfileResolver.kofR2RomIds) {
        expect(
          resolver.supports(gameId: 'legacy-record', romIds: [romId]),
          isTrue,
        );
      }
    });

    test('rejects unrelated games', () async {
      expect(
        resolver.supports(gameId: 'ngpc-samsho2', romIds: const ['samsho2']),
        isFalse,
      );
      expect(
        await resolver.resolve(
          gameId: 'ngpc-samsho2',
          romIds: const ['samsho2'],
        ),
        isNull,
      );
    });

    test('loads and validates the complete KOF R-2 profile', () async {
      final profile = await resolver.resolve(
        gameId: 'ngpc-kofr2',
        romIds: const ['kofr2'],
      );

      expect(profile, isNotNull);
      expect(profile!.id, 'ngpc-kofr2-v2');
      expect(profile.appliesTo.gameId, 'ngpc-kofr2');
      expect(profile.characters, hasLength(23));
      expect(profile.moves, hasLength(289));
      expect(
        profile.moves.where((move) => move.isAutomaticFollowUp),
        hasLength(3),
      );
    });

    test('reports a visible error for a mismatched bundled profile', () async {
      final valid = await loadBundledKofR2Profile();
      final mismatched = ProfileGold(
        goldSchemaVersion: valid.goldSchemaVersion,
        silverSchemaVersion: valid.silverSchemaVersion,
        id: 'wrong-profile',
        profileRevision: valid.profileRevision,
        appliesTo: valid.appliesTo,
        attribution: valid.attribution,
        buttons: valid.buttons,
        characters: valid.characters,
        moves: valid.moves,
      );
      final resolver = BundledGoldProfileResolver(
        loadKofR2Profile: () async => mismatched,
      );

      expect(
        () => resolver.resolve(gameId: 'ngpc-kofr2'),
        throwsA(isA<BundledGoldProfileException>()),
      );
    });
  });
}
