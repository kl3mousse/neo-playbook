import 'package:combofox/experimental/gold_moves_profile_v1/gold_moves_profile.dart';
import 'package:flutter_test/flutter_test.dart';

/// Notation-frame semantics per CONSUMER_SPEC.md §4/§5.
void main() {
  test('player_relative preserves forward and back semantics', () {
    // Direction(forward, relative: true) should stay `6` in numpad
    // regardless of frame — mirroring is a rendering-context concern,
    // not a domain transformation.
    const json = r'''
{
  "gold_schema_version": "1.0.0", "silver_schema_version": "0.2.0",
  "id": "x", "profile_revision": 1,
  "applies_to": {"platform":"p","notation_frame":"player_relative"},
  "attribution": {"primary_source":{"name":"s"},"display_text":"d"},
  "buttons":[{"symbol":"A","label":"A"}],
  "characters":[{"id":"c","name":"C"}],
  "moves":[{
    "id":"m","name":"M","category":"special","character_id":"c",
    "activation":{"kind":"by_player_input"},
    "input_expressions":[{"parse_status":"parsed","expression":{
      "kind":"sequence","steps":[
        {"kind":"direction","direction":"forward","relative":true},
        {"kind":"button","symbol":"A"}
      ]
    }}]
  }]
}
''';
    final profile = ProfileParser().parseString(json);
    final move = profile.moves.single;
    // Numpad output stays player-relative (`6`). Mirroring is a
    // widget-level concern (GoldRenderContext).
    expect(NumpadRenderer().render(move), '6 A');
    expect(Classic2dRenderer().render(move), 'f + A');
  });

  test('stick_absolute preserves left/right literals', () {
    const json = r'''
{
  "gold_schema_version": "1.0.0", "silver_schema_version": "0.2.0",
  "id": "x", "profile_revision": 1,
  "applies_to": {"platform":"p","notation_frame":"stick_absolute"},
  "attribution": {"primary_source":{"name":"s"},"display_text":"d"},
  "buttons":[{"symbol":"A","label":"A"}],
  "characters":[{"id":"c","name":"C"}],
  "moves":[{
    "id":"m","name":"M","category":"special","character_id":"c",
    "activation":{"kind":"by_player_input"},
    "input_expressions":[{"parse_status":"parsed","expression":{
      "kind":"sequence","steps":[
        {"kind":"direction","direction":"forward","relative":false},
        {"kind":"button","symbol":"A"}
      ]
    }}]
  }]
}
''';
    final profile = ProfileParser().parseString(json);
    expect(profile.appliesTo.notationFrame, NotationFrame.stickAbsolute);
    // Renderer output is the same tokens; mirroring never applies.
    expect(NumpadRenderer().render(profile.moves.single), '6 A');
  });

  test('mixed_explicit preserves per-node relative flag', () {
    const json = r'''
{
  "gold_schema_version": "1.0.0", "silver_schema_version": "0.2.0",
  "id": "x", "profile_revision": 1,
  "applies_to": {"platform":"p","notation_frame":"mixed_explicit"},
  "attribution": {"primary_source":{"name":"s"},"display_text":"d"},
  "buttons":[{"symbol":"A","label":"A"}],
  "characters":[{"id":"c","name":"C"}],
  "moves":[{
    "id":"m","name":"M","category":"special","character_id":"c",
    "activation":{"kind":"by_player_input"},
    "input_expressions":[{"parse_status":"parsed","expression":{
      "kind":"sequence","steps":[
        {"kind":"direction","direction":"forward","relative":true},
        {"kind":"direction","direction":"forward","relative":false},
        {"kind":"button","symbol":"A"}
      ]
    }}]
  }]
}
''';
    final profile = ProfileParser().parseString(json);
    expect(profile.appliesTo.notationFrame, NotationFrame.mixedExplicit);
    final expr =
        profile.moves.single.inputExpressions.single.expression as SequenceExpr;
    expect((expr.steps[0] as DirectionExpr).relative, isTrue);
    expect((expr.steps[1] as DirectionExpr).relative, isFalse);
  });
}
