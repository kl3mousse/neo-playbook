import 'package:combofox/experimental/gold_moves_profile_v1/gold_moves_profile.dart';
import 'package:flutter_test/flutter_test.dart';

/// Refusal / error scenarios from CONSUMER_SPEC §13.
void main() {
  final parser = ProfileParser();

  const validBase = r'''
{
  "gold_schema_version": "1.0.0",
  "silver_schema_version": "0.2.0",
  "id": "x",
  "profile_revision": 1,
  "applies_to": { "platform": "p", "notation_frame": "player_relative" },
  "attribution": {
    "primary_source": { "name": "s" },
    "display_text": "d"
  },
  "buttons": [{ "symbol": "A", "label": "A" }],
  "characters": [{ "id": "c", "name": "C" }],
  "moves": []
}
''';

  GoldParseException expectRefusal(String Function(String) mutate) {
    try {
      parser.parseString(mutate(validBase));
      fail('expected GoldParseException');
    } on GoldParseException catch (e) {
      return e;
    }
  }

  test('refuses gold_schema_version=2.0.0', () {
    final e = expectRefusal(
      (b) => b.replaceFirst(
        '"gold_schema_version": "1.0.0"',
        '"gold_schema_version": "2.0.0"',
      ),
    );
    expect(e.path, '/gold_schema_version');
    expect(e.rawValue, '2.0.0');
    expect(e.message, contains('Incompatible'));
  });

  test('refuses missing required discriminant (activation.kind)', () {
    final json = r'''
{
  "gold_schema_version": "1.0.0", "silver_schema_version": "0.2.0",
  "id": "x", "profile_revision": 1,
  "applies_to": { "platform": "p", "notation_frame": "player_relative" },
  "attribution": {"primary_source":{"name":"s"},"display_text":"d"},
  "buttons":[{"symbol":"A","label":"A"}],
  "characters":[{"id":"c","name":"C"}],
  "moves": [{
    "id":"m","name":"M","category":"special","character_id":"c",
    "activation": {},
    "input_expressions":[{"parse_status":"parsed",
      "expression":{"kind":"button","symbol":"A"}}]
  }]
}
''';
    try {
      parser.parseString(json);
      fail('expected exception');
    } on GoldParseException catch (e) {
      expect(e.path, '/moves/0/activation/kind');
    }
  });

  test('refuses unresolved follow_up move_id', () {
    final json = validBase.replaceFirst('"moves": []', r'''
"moves": [{
  "id":"m","name":"M","category":"special","character_id":"c",
  "activation":{"kind":"by_player_input"},
  "input_expressions":[{"parse_status":"parsed","expression":{"kind":"button","symbol":"A"}}],
  "follow_ups":[{"move_id":"does-not-exist","relation":"follow_up"}]
}]
''');
    try {
      parser.parseString(json);
      fail('expected exception');
    } on GoldParseException catch (e) {
      expect(e.path, endsWith('/follow_ups/0/move_id'));
      expect(e.message, contains('does-not-exist'));
    }
  });

  test('refuses unresolved automatic_after_move parent_move_id', () {
    final json = validBase.replaceFirst('"moves": []', r'''
"moves": [{
  "id":"m","name":"M","category":"special","character_id":"c",
  "activation":{
    "kind":"automatic_after_move",
    "trigger":{"kind":"on_hit","parent_move_id":"missing"}
  }
}]
''');
    try {
      parser.parseString(json);
      fail('expected exception');
    } on GoldParseException catch (e) {
      expect(e.path, endsWith('/activation/trigger/parent_move_id'));
      expect(e.message, contains('missing'));
    }
  });

  test('refuses unresolved character_id', () {
    final json = validBase.replaceFirst('"moves": []', r'''
"moves": [{
  "id":"m","name":"M","category":"special","character_id":"ghost",
  "activation":{"kind":"by_player_input"},
  "input_expressions":[{"parse_status":"parsed","expression":{"kind":"button","symbol":"A"}}]
}]
''');
    try {
      parser.parseString(json);
      fail('expected exception');
    } on GoldParseException catch (e) {
      expect(e.path, endsWith('/character_id'));
      expect(e.message, contains('ghost'));
    }
  });

  test('refuses parse_status="unparsed" without source_raw', () {
    final json = validBase.replaceFirst('"moves": []', r'''
"moves": [{
  "id":"m","name":"M","category":"special","character_id":"c",
  "activation":{"kind":"by_player_input"},
  "input_expressions":[{"parse_status":"unparsed"}]
}]
''');
    try {
      parser.parseString(json);
      fail('expected exception');
    } on GoldParseException catch (e) {
      expect(e.path, endsWith('/source_raw'));
    }
  });

  test('unknown activation.kind is tolerated (kind=unknown)', () {
    final json = validBase.replaceFirst('"moves": []', r'''
"moves": [{
  "id":"m","name":"M","category":"special","character_id":"c",
  "activation":{"kind":"future_kind_42"},
  "input_expressions":[{"parse_status":"parsed","expression":{"kind":"button","symbol":"A"}}]
}]
''');
    final p = parser.parseString(json);
    expect(p.moves.single.activation.kind, ActivationKind.unknown);
    expect(p.moves.single.activation.rawKind, 'future_kind_42');
  });

  test(
    'unknown expression.kind becomes UnknownExpression, never silently empty',
    () {
      final json = validBase.replaceFirst('"moves": []', r'''
"moves": [{
  "id":"m","name":"M","category":"special","character_id":"c",
  "activation":{"kind":"by_player_input"},
  "input_expressions":[{
    "parse_status":"parsed",
    "expression":{"kind":"future_expr_kind","payload":42}
  }]
}]
''');
      final p = parser.parseString(json);
      final expr = p.moves.single.inputExpressions.single.expression!;
      expect(expr, isA<UnknownExpression>());
      expect((expr as UnknownExpression).rawKind, 'future_expr_kind');
    },
  );

  test('unknown notation_frame falls back to player_relative', () {
    final json = validBase.replaceFirst(
      '"notation_frame": "player_relative"',
      '"notation_frame": "some_future_frame"',
    );
    final p = parser.parseString(json);
    expect(p.appliesTo.notationFrame, NotationFrame.playerRelative);
    expect(p.appliesTo.rawNotationFrame, 'some_future_frame');
  });

  test('unknown top-level fields are preserved for forward-compat', () {
    final json = validBase.replaceFirst(
      '"moves": []',
      '"moves": [], "future_hint": {"foo": "bar"}',
    );
    final p = parser.parseString(json);
    expect(p.unknownFields.containsKey('future_hint'), isTrue);
  });

  test('by_player_input without any input_expression is rejected', () {
    final json = validBase.replaceFirst('"moves": []', r'''
"moves": [{
  "id":"m","name":"M","category":"special","character_id":"c",
  "activation":{"kind":"by_player_input"}
}]
''');
    try {
      parser.parseString(json);
      fail('expected exception');
    } on GoldParseException catch (e) {
      expect(e.path, endsWith('/input_expressions'));
    }
  });
}
