import 'package:combofox/experimental/gold_moves_profile_v1/gold_moves_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fixture_loader.dart';

void main() {
  group('minimal.profile.json', () {
    late ProfileGold profile;
    setUpAll(() {
      profile = parseBundleProfile('examples/minimal.profile.json');
    });

    test('parses top-level metadata', () {
      expect(profile.goldSchemaVersion, '1.0.0');
      expect(profile.silverSchemaVersion, '0.2.0');
      expect(profile.id, 'ngpc-kofr2-v2.example-minimal');
      expect(profile.appliesTo.platform, 'neogeo_pocket_color');
      expect(profile.appliesTo.notationFrame, NotationFrame.playerRelative);
      expect(profile.appliesTo.romIds, ['kofr2', 'kofr2d', 'kofr2d2']);
    });

    test('preserves attribution verbatim', () {
      expect(
        profile.attribution.primarySource.name,
        'strategywiki-kofr2-moves',
      );
      expect(profile.attribution.primarySource.license, 'CC BY-SA 4.0');
      expect(profile.attribution.additionalSources.length, 2);
      expect(profile.attribution.displayText, contains('CC BY-SA 4.0'));
    });

    test('parses the single character and move', () {
      expect(profile.characters, hasLength(1));
      expect(profile.characters.single.id, 'ngpc-kofr2-kyo');
      expect(profile.moves, hasLength(1));
      final m = profile.moves.single;
      expect(m.id, 'ngpc-kofr2-kyo-throw-hatsugane');
      expect(m.category, MoveCategory.throwMove);
      expect(m.characterId, 'ngpc-kofr2-kyo');
      expect(m.activation.kind, ActivationKind.byPlayerInput);
      expect(m.sourceRaw, isNotEmpty);
    });

    test('parses the contextual alternative expression tree', () {
      final expr = profile.moves.single.inputExpressions.first.expression!;
      expect(expr, isA<ContextualExpr>());
      final ctx = expr as ContextualExpr;
      expect(ctx.requirements, hasLength(1));
      expect(ctx.requirements.first.kind, RequirementKind.spatial);
      expect(ctx.requirements.first.value, 'near_opponent');
      expect(ctx.input, isA<AlternativeExpr>());
      final alt = ctx.input as AlternativeExpr;
      expect(alt.options, hasLength(2));
      for (final option in alt.options) {
        expect(option, isA<SequenceExpr>());
        final seq = option as SequenceExpr;
        expect(seq.steps, hasLength(2));
        expect(seq.steps.first, isA<DirectionExpr>());
        expect(seq.steps.last, isA<ButtonExpr>());
      }
    });
  });
}
