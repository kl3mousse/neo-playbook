import 'package:flutter_test/flutter_test.dart';

import 'package:combofox/experimental/gold_moves_profile_v1/gold_moves_profile.dart';
import 'package:combofox/experimental/gold_moves_profile_v1/presentation/lab/lab_controller.dart';

import '../utils/fixture_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProfileGold profile;

  setUpAll(() {
    profile = parseBundleProfile('profile.json');
  });

  group('LabController', () {
    test('exposes the full KOF R-2 profile', () {
      final c = LabController(profile);
      expect(c.profile.characters.length, 23);
      expect(c.profile.moves.length, 289);
    });

    test('selecting a character resets the selected move', () {
      final c = LabController(profile);
      final first = profile.characters.first.id;
      c.selectCharacter(first);
      final probe = c.movesForCharacter(first).first.id;
      c.selectMove(probe);
      c.selectCharacter(profile.characters[1].id);
      expect(c.selectedMoveId, isNull);
    });

    test('automaticOnly filter only keeps automatic activations', () {
      final c = LabController(profile);
      c.setMoveFilter(LabMoveFilter.automaticOnly);
      for (final m in c.filteredMovesAcrossProfile()) {
        expect(m.activation.kind, ActivationKind.automaticAfterMove);
      }
    });

    test('activationCounts reports 3 automatic + 286 by_player_input', () {
      final c = LabController(profile);
      final counts = c.activationCounts();
      expect(counts[ActivationKind.automaticAfterMove], 3);
      expect(counts[ActivationKind.byPlayerInput], 286);
    });

    test('LabTextScale factor and percent mapping', () {
      expect(LabTextScale.s100.factor, 1.0);
      expect(LabTextScale.s130.factor, 1.3);
      expect(LabTextScale.s160.factor, 1.6);
      expect(LabTextScale.s200.factor, 2.0);
      expect(LabTextScale.s100.percent, 100);
      expect(LabTextScale.s200.percent, 200);
    });

    test('notifies listeners on state changes', () {
      final c = LabController(profile);
      int count = 0;
      c.addListener(() => count++);
      c.selectCharacter(profile.characters.first.id);
      c.setSearch('foo');
      c.setMoveFilter(LabMoveFilter.automaticOnly);
      c.setNotation(LabNotation.numpad);
      c.setAccessibleLocale(LabAccessibleLocale.fr);
      c.setThemeMode(LabThemeMode.light);
      c.setDensity(LabDensity.compact);
      c.setTextScale(LabTextScale.s200);
      expect(count, greaterThanOrEqualTo(8));
    });

    test('setting the same value twice does not notify twice', () {
      final c = LabController(profile);
      c.setNotation(LabNotation.numpad);
      int count = 0;
      c.addListener(() => count++);
      c.setNotation(LabNotation.numpad);
      expect(count, 0);
    });
  });
}
