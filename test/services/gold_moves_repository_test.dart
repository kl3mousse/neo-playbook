import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:combofox/services/gold_moves_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../experimental/gold_moves_profile_v1/utils/fixture_loader.dart';

void main() {
  const gameId = 'ngpc-kofr2';
  const profileId = 'ngpc-kofr2-v2';
  const checksum =
      '5e1b2f8597929502470e4b0b19492142fa5b85d07a8875c95ef4133cdee94b24';

  Map<String, dynamic> profilePayload() =>
      jsonDecode(readBundleString('profile.json')) as Map<String, dynamic>;

  Map<String, dynamic> manifest({String? activePath}) => {
    'publication_contract': 'combofox-gold-moves-firestore',
    'publication_contract_version': '1.0.0',
    'game_id': gameId,
    'active_profile_id': profileId,
    'active_profile_path':
        activePath ?? 'move_profiles/$gameId/versions/$profileId',
    'active_payload_sha256': checksum,
    'gold_schema_version': '1.0.0',
    'profile_revision': 1,
    'published_at': '2026-08-03T00:00:00Z',
  };

  Map<String, dynamic> version({Map<String, dynamic>? payload}) => {
    'publication_contract': 'combofox-gold-moves-firestore',
    'publication_contract_version': '1.0.0',
    'game_id': gameId,
    'profile_id': profileId,
    'profile_revision': 1,
    'gold_schema_version': '1.0.0',
    'payload': payload ?? profilePayload(),
    'payload_sha256': checksum,
    'payload_bytes': 291163,
    'counts': {
      'characters': 23,
      'moves': 289,
      'by_player_input': 286,
      'automatic_after_move': 3,
    },
    'published_at': '2026-08-03T00:00:00Z',
  };

  test('reads and validates the published KOF R-2 profile', () async {
    final source = _FakeDataSource({
      'move_profiles/$gameId': GoldMovesDocument(
        data: manifest(),
        isFromCache: true,
      ),
      'move_profiles/$gameId/versions/$profileId': GoldMovesDocument(
        data: version(),
        isFromCache: true,
      ),
    });

    final result = await GoldMovesRepository(
      dataSource: source,
    ).loadProfile(gameId);

    expect(result.profile.id, profileId);
    expect(result.profile.characters, hasLength(23));
    expect(result.profile.moves, hasLength(289));
    expect(
      result.profile.moves.where((move) => move.isAutomaticFollowUp),
      hasLength(3),
    );
    expect(result.isFromCache, isTrue);
  });

  test(
    'rejects an active path that is not the manifest profile path',
    () async {
      final source = _FakeDataSource({
        'move_profiles/$gameId': GoldMovesDocument(
          data: manifest(activePath: 'move_profiles/other/versions/wrong'),
          isFromCache: false,
        ),
      });

      expect(
        () => GoldMovesRepository(dataSource: source).loadProfile(gameId),
        throwsA(
          isA<GoldMovesRepositoryException>().having(
            (error) => error.kind,
            'kind',
            GoldMovesFailureKind.invalidActivePath,
          ),
        ),
      );
    },
  );

  test(
    'rejects a payload whose counts differ from the immutable document',
    () async {
      final broken = version();
      (broken['counts'] as Map<String, dynamic>)['moves'] = 288;
      final source = _FakeDataSource({
        'move_profiles/$gameId': GoldMovesDocument(
          data: manifest(),
          isFromCache: false,
        ),
        'move_profiles/$gameId/versions/$profileId': GoldMovesDocument(
          data: broken,
          isFromCache: false,
        ),
      });

      expect(
        () => GoldMovesRepository(dataSource: source).loadProfile(gameId),
        throwsA(
          isA<GoldMovesRepositoryException>().having(
            (error) => error.kind,
            'kind',
            GoldMovesFailureKind.invalidProfile,
          ),
        ),
      );
    },
  );

  test('surfaces Firestore connectivity errors distinctly', () async {
    final source = _FakeDataSource(
      const {},
      error: FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
    );

    expect(
      () => GoldMovesRepository(dataSource: source).loadProfile(gameId),
      throwsA(
        isA<GoldMovesRepositoryException>().having(
          (error) => error.kind,
          'kind',
          GoldMovesFailureKind.unavailable,
        ),
      ),
    );
  });
}

class _FakeDataSource implements GoldMovesDataSource {
  final Map<String, GoldMovesDocument> documents;
  final Object? error;

  const _FakeDataSource(this.documents, {this.error});

  @override
  Future<GoldMovesDocument?> getDocument(String path) async {
    if (error != null) throw error!;
    return documents[path];
  }
}
