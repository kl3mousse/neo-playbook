import 'dart:convert';

import 'package:combofox/experimental/gold_moves_profile_v1/gold_moves_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fixture_loader.dart';

/// Conformance smoke test against `rendering-samples.json`. The
/// reference outputs are not part of the contract per the notice at
/// the top of the file — they are a known-good target for renderers
/// so that regressions surface as failed tests.
void main() {
  late Map<String, dynamic> samples;
  late ProfileGold profile;

  setUpAll(() {
    final decoded = jsonDecode(readBundleString('rendering-samples.json'));
    samples = decoded as Map<String, dynamic>;
    profile = parseBundleProfile('profile.json');
  });

  Map<String, dynamic> sampleFor(String moveId) {
    final list = samples['moves'] as List;
    return list.firstWhere((m) => m['move_id'] == moveId)
        as Map<String, dynamic>;
  }

  test('numpad renderer matches sample outputs', () {
    final numpad = NumpadRenderer();
    final ids = (samples['moves'] as List).cast<Map<String, dynamic>>();
    for (final s in ids) {
      final id = s['move_id'] as String;
      final expressions = (s['input_expressions'] as List?) ?? const [];
      if (expressions.isEmpty) continue;
      final expected = (expressions.first as Map)['numpad'];
      if (expected == null) continue;
      final move = profile.move(id)!;
      expect(
        numpad.render(move),
        equals(expected),
        reason: 'numpad diff for $id',
      );
    }
  });

  test('classic_2d renderer matches sample outputs', () {
    final classic = Classic2dRenderer();
    for (final s in (samples['moves'] as List).cast<Map<String, dynamic>>()) {
      final id = s['move_id'] as String;
      final expressions = (s['input_expressions'] as List?) ?? const [];
      if (expressions.isEmpty) continue;
      final expected = (expressions.first as Map)['classic_2d'];
      if (expected == null) continue;
      final move = profile.move(id)!;
      expect(
        classic.render(move),
        equals(expected),
        reason: 'classic_2d diff for $id',
      );
    }
  });

  test('accessible_en renderer matches sample outputs', () {
    final en = AccessibleEnRenderer();
    for (final s in (samples['moves'] as List).cast<Map<String, dynamic>>()) {
      final id = s['move_id'] as String;
      final expressions = (s['input_expressions'] as List?) ?? const [];
      if (expressions.isEmpty) continue;
      final expected = (expressions.first as Map)['accessible_en'];
      if (expected == null) continue;
      final move = profile.move(id)!;
      expect(
        en.render(move),
        equals(expected),
        reason: 'accessible_en diff for $id',
      );
    }
  });

  test('accessible_fr renderer matches sample outputs', () {
    final fr = AccessibleFrRenderer();
    for (final s in (samples['moves'] as List).cast<Map<String, dynamic>>()) {
      final id = s['move_id'] as String;
      final expressions = (s['input_expressions'] as List?) ?? const [];
      if (expressions.isEmpty) continue;
      final expected = (expressions.first as Map)['accessible_fr'];
      if (expected == null) continue;
      final move = profile.move(id)!;
      expect(
        fr.render(move),
        equals(expected),
        reason: 'accessible_fr diff for $id',
      );
    }
  });

  test('activation_hint_en matches sample for automatic move', () {
    final s = sampleFor('ngpc-kofr2-kyo-spc-arashin');
    final expected = s['activation_hint_en'];
    final arashin = profile.move('ngpc-kofr2-kyo-spc-arashin')!;
    expect(ActivationHintRenderer().renderEn(arashin), equals(expected));
  });

  test('icon_tokens renderer matches sample structure', () {
    final iconR = IconTokensRenderer();
    for (final s in (samples['moves'] as List).cast<Map<String, dynamic>>()) {
      final id = s['move_id'] as String;
      final expressions = (s['input_expressions'] as List?) ?? const [];
      if (expressions.isEmpty) continue;
      final expected = (expressions.first as Map)['icon_tokens'];
      if (expected == null) continue;
      final move = profile.move(id)!;
      final produced = iconR.render(move);
      expect(produced, equals(expected), reason: 'icon_tokens diff for $id');
    }
  });
}
