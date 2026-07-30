import 'package:combofox/experimental/gold_moves_profile_v1/gold_moves_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fixture_loader.dart';

void main() {
  group('activation-automatic.profile.json', () {
    late ProfileGold profile;
    setUpAll(() {
      profile = parseBundleProfile(
        'examples/activation-automatic.profile.json',
      );
    });

    test('parses 5 moves including 3 automatic follow-ups', () {
      expect(profile.moves, hasLength(5));
      final autos = profile.moves
          .where((m) => m.activation.kind == ActivationKind.automaticAfterMove)
          .toList();
      expect(autos, hasLength(3));
    });

    test('preserves parent_move_id references and they all resolve', () {
      for (final auto in profile.moves.where(
        (m) => m.activation.kind == ActivationKind.automaticAfterMove,
      )) {
        final parent = auto.activation.trigger?.parentMoveId;
        expect(parent, isNotNull);
        expect(
          profile.move(parent!),
          isNotNull,
          reason: 'parent_move_id "$parent" must resolve',
        );
      }
    });

    test('preserves follow_ups on Nue Tumi', () {
      final nue = profile.move('ngpc-kofr2-kyo-spc-nue-tumi')!;
      expect(nue.followUps.map((f) => f.moveId).toList(), [
        'ngpc-kofr2-kyo-spc-arashin',
        'ngpc-kofr2-kyo-spc-migiri-ugachi-low',
      ]);
      for (final f in nue.followUps) {
        expect(f.relation, FollowUpRelation.followUp);
      }
    });

    test('automatic moves preserve source_raw and description', () {
      final arashin = profile.move('ngpc-kofr2-kyo-spc-arashin')!;
      expect(arashin.sourceRaw, '(Mid Hit — automatic)');
      expect(arashin.activation.trigger!.description, '(Mid Hit — automatic)');
      expect(arashin.activation.trigger!.kind, TriggerKind.onMidHit);
      expect(arashin.hasStructuredInput, isFalse);
    });

    test('distinguishes player input, no-input and unknown', () {
      final nue = profile.move('ngpc-kofr2-kyo-spc-nue-tumi')!;
      expect(nue.isPlayerInput, isTrue);
      expect(nue.inputExpressions, isNotEmpty);

      final arashin = profile.move('ngpc-kofr2-kyo-spc-arashin')!;
      expect(arashin.isPlayerInput, isFalse);
      expect(arashin.isAutomaticFollowUp, isTrue);
      expect(arashin.inputExpressions, isEmpty);
    });
  });
}
