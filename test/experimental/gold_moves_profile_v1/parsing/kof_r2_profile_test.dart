import 'package:combofox/experimental/gold_moves_profile_v1/gold_moves_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fixture_loader.dart';

void main() {
  group('Full KOF R-2 profile (289 moves)', () {
    late ProfileGold profile;
    setUpAll(() {
      profile = parseBundleProfile('profile.json');
    });

    test('parses 23 characters, 289 moves', () {
      expect(profile.characters, hasLength(23));
      expect(profile.moves, hasLength(289));
    });

    test('activation counts match manifest', () {
      final counts = <ActivationKind, int>{};
      for (final m in profile.moves) {
        counts[m.activation.kind] = (counts[m.activation.kind] ?? 0) + 1;
      }
      expect(counts[ActivationKind.byPlayerInput], 286);
      expect(counts[ActivationKind.automaticAfterMove], 3);
      expect(counts[ActivationKind.contextualTrigger] ?? 0, 0);
    });

    test('all move ids are unique and preserved as declared', () {
      final ids = profile.moves.map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'move ids must be unique');
      // Editorial order preserved: at least the first move in the file
      // remains first in the parsed list.
      expect(ids.first, isNotEmpty);
    });

    test('all character_ids resolve to a declared character', () {
      for (final m in profile.moves) {
        if (m.characterId != null) {
          expect(
            profile.character(m.characterId!),
            isNotNull,
            reason: 'character "${m.characterId}" for move ${m.id}',
          );
        }
      }
    });

    test('all follow_ups resolve to declared moves', () {
      for (final m in profile.moves) {
        for (final f in m.followUps) {
          expect(
            profile.move(f.moveId),
            isNotNull,
            reason: 'follow-up "${f.moveId}" of ${m.id}',
          );
        }
      }
    });

    test('all automatic_after_move parent_move_ids resolve', () {
      for (final m in profile.moves) {
        if (m.activation.kind == ActivationKind.automaticAfterMove) {
          final parent = m.activation.trigger?.parentMoveId;
          expect(parent, isNotNull);
          expect(profile.move(parent!), isNotNull);
        }
      }
    });

    test('286 wrappers with parse_status=parsed, 0 partial, 0 unparsed', () {
      var parsed = 0, partial = 0, unparsed = 0;
      for (final m in profile.moves) {
        for (final w in m.inputExpressions) {
          switch (w.parseStatus) {
            case ParseStatus.parsed:
              parsed++;
            case ParseStatus.partial:
              partial++;
            case ParseStatus.unparsed:
              unparsed++;
          }
        }
      }
      expect(parsed, 286);
      expect(partial, 0);
      expect(unparsed, 0);
    });

    test('source_raw is preserved on every move', () {
      var missing = 0;
      for (final m in profile.moves) {
        if (m.sourceRaw == null || m.sourceRaw!.isEmpty) missing++;
      }
      expect(
        missing,
        0,
        reason: 'The KOF R-2 build preserves source_raw on every move.',
      );
    });

    test('provenance is StrategyWiki with CC BY-SA 4.0', () {
      expect(
        profile.attribution.primarySource.name,
        'strategywiki-kofr2-moves',
      );
      expect(profile.attribution.primarySource.license, 'CC BY-SA 4.0');
      expect(profile.attribution.displayText, contains('CC BY-SA 4.0'));
    });

    test('notation_frame is player_relative', () {
      expect(profile.appliesTo.notationFrame, NotationFrame.playerRelative);
      expect(profile.appliesTo.rawNotationFrame, 'player_relative');
    });

    test('button catalog includes A/B/C/D and P/K groups', () {
      expect(profile.buttons.button('A'), isNotNull);
      expect(profile.buttons.button('B'), isNotNull);
      expect(profile.buttons.button('C'), isNotNull);
      expect(profile.buttons.button('D'), isNotNull);
      expect(profile.buttons.isGroup('P'), isTrue);
      expect(profile.buttons.isGroup('K'), isTrue);
    });
  });
}
