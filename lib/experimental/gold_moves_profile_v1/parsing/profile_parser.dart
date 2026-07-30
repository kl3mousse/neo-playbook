import 'dart:convert';

import '../domain/annotation.dart';
import '../domain/button.dart';
import '../domain/character.dart';
import '../domain/expression.dart';
import '../domain/move.dart';
import '../domain/notation_frame.dart';
import '../domain/parse_status.dart';
import '../domain/profile.dart';
import '../domain/provenance.dart';
import 'parse_error.dart';

/// Parses a Gold Moves Profile v1.x from JSON.
///
/// The parser is strict on refusal conditions (CONSUMER_SPEC §13) and
/// forgiving on forward-compat: unknown enum values are coerced to
/// `*Kind.unknown`, unknown top-level fields are preserved in
/// [ProfileGold.unknownFields] and unknown expression `kind`s become
/// [UnknownExpression] nodes.
class ProfileParser {
  const ProfileParser({this.strictReferences = true});

  /// When true (default), refuses to load a profile whose references
  /// (`move.character_id`, `follow_ups[].move_id`,
  /// `activation.trigger.parent_move_id`) do not resolve. Refusal is
  /// mandated by §13.
  final bool strictReferences;

  /// Convenience: parse from a JSON-encoded string.
  ProfileGold parseString(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw GoldParseException('Root JSON must be an object.');
    }
    return parseMap(decoded);
  }

  /// Parse a decoded JSON map into a typed [ProfileGold].
  ProfileGold parseMap(Map<String, dynamic> root) {
    final version = _requireString(root, 'gold_schema_version', path: '');
    if (!version.startsWith('1.')) {
      throw GoldParseException(
        'Incompatible gold_schema_version "$version". Expected "1.x.y". '
        'Please update the app.',
        path: '/gold_schema_version',
        rawValue: version,
      );
    }

    final silver = _requireString(root, 'silver_schema_version', path: '');
    final id = _requireString(root, 'id', path: '');
    final rev = _requireInt(root, 'profile_revision', path: '');
    final generatedAt = _optionalDateTime(
      root['generated_at'],
      path: '/generated_at',
    );

    final appliesTo = _parseAppliesTo(_requireObject(root, 'applies_to'));
    final attribution = _parseAttribution(_requireObject(root, 'attribution'));
    final buttons = _parseButtons(root);
    final characters = _parseCharacters(root);

    final moves = <MoveGold>[];
    final movesRaw = root['moves'];
    if (movesRaw is! List) {
      throw GoldParseException('`moves` must be an array.', path: '/moves');
    }
    for (var i = 0; i < movesRaw.length; i++) {
      final entry = movesRaw[i];
      if (entry is! Map<String, dynamic>) {
        throw GoldParseException(
          'Move at index $i is not an object.',
          path: '/moves/$i',
        );
      }
      moves.add(_parseMove(entry, '/moves/$i', buttons));
    }

    // Reference resolution (§13).
    if (strictReferences) {
      _validateReferences(characters, moves);
    }

    // Preserve any unrecognised top-level fields (§10 forward compat).
    const known = {
      'gold_schema_version',
      'silver_schema_version',
      'id',
      'profile_revision',
      'generated_at',
      'applies_to',
      'attribution',
      'buttons',
      'button_groups',
      'characters',
      'moves',
    };
    final unknown = <String, Object?>{};
    for (final key in root.keys) {
      if (!known.contains(key)) {
        unknown[key] = root[key];
      }
    }

    return ProfileGold(
      goldSchemaVersion: version,
      silverSchemaVersion: silver,
      id: id,
      profileRevision: rev,
      generatedAt: generatedAt,
      appliesTo: appliesTo,
      attribution: attribution,
      buttons: buttons,
      characters: characters,
      moves: moves,
      unknownFields: unknown,
    );
  }

  // ── applies_to ────────────────────────────────────────────────

  AppliesTo _parseAppliesTo(Map<String, dynamic> node) {
    const path = '/applies_to';
    final rawFrame = node['notation_frame'];
    if (rawFrame is! String) {
      throw GoldParseException(
        'notation_frame is required and must be a string.',
        path: '$path/notation_frame',
        rawValue: rawFrame,
      );
    }
    return AppliesTo(
      gameId: node['game_id'] as String?,
      platform: _requireString(node, 'platform', path: path),
      region: node['region'] as String?,
      romIds: (node['rom_ids'] as List?)?.cast<String>() ?? const [],
      notationFrame: NotationFrame.fromWire(rawFrame),
      rawNotationFrame: rawFrame,
    );
  }

  // ── attribution ───────────────────────────────────────────────

  Attribution _parseAttribution(Map<String, dynamic> node) {
    const path = '/attribution';
    final primaryNode = _requireObject(node, 'primary_source', path: path);
    final primary = Source(
      name: _requireString(primaryNode, 'name', path: '$path/primary_source'),
      url: primaryNode['url'] as String?,
      version: primaryNode['version'] as String?,
      license: primaryNode['license'] as String?,
      notes: primaryNode['notes'] as String?,
    );

    final additional = <AdditionalSource>[];
    final additionalList = node['additional_sources'];
    if (additionalList is List) {
      for (var i = 0; i < additionalList.length; i++) {
        final e = additionalList[i];
        if (e is! Map<String, dynamic>) {
          throw GoldParseException(
            'Additional source is not an object.',
            path: '$path/additional_sources/$i',
          );
        }
        final subPath = '$path/additional_sources/$i';
        additional.add(
          AdditionalSource(
            name: _requireString(e, 'name', path: subPath),
            url: e['url'] as String?,
            role: AdditionalSourceRole.fromWire(e['role'] as String?),
            rawRole: (e['role'] as String?) ?? '',
            notes: e['notes'] as String?,
          ),
        );
      }
    }

    final display = _requireString(node, 'display_text', path: path);
    return Attribution(
      primarySource: primary,
      additionalSources: additional,
      displayText: display,
    );
  }

  // ── buttons ───────────────────────────────────────────────────

  ButtonCatalog _parseButtons(Map<String, dynamic> root) {
    final buttonsRaw = root['buttons'];
    if (buttonsRaw is! List || buttonsRaw.isEmpty) {
      throw GoldParseException(
        '`buttons` must be a non-empty array.',
        path: '/buttons',
      );
    }
    final buttons = <ButtonSpec>[];
    for (var i = 0; i < buttonsRaw.length; i++) {
      final e = buttonsRaw[i];
      if (e is! Map<String, dynamic>) {
        throw GoldParseException(
          'Button is not an object.',
          path: '/buttons/$i',
        );
      }
      buttons.add(
        ButtonSpec(
          symbol: _requireString(e, 'symbol', path: '/buttons/$i'),
          label: _requireString(e, 'label', path: '/buttons/$i'),
        ),
      );
    }

    final groups = <ButtonGroupSpec>[];
    final groupsRaw = root['button_groups'];
    if (groupsRaw is List) {
      for (var i = 0; i < groupsRaw.length; i++) {
        final e = groupsRaw[i];
        if (e is! Map<String, dynamic>) {
          throw GoldParseException(
            'Button group is not an object.',
            path: '/button_groups/$i',
          );
        }
        final members = (e['members'] as List?)?.cast<String>();
        if (members == null || members.isEmpty) {
          throw GoldParseException(
            'button_groups[$i].members must be a non-empty array.',
            path: '/button_groups/$i/members',
          );
        }
        groups.add(
          ButtonGroupSpec(
            symbol: _requireString(e, 'symbol', path: '/button_groups/$i'),
            label: _requireString(e, 'label', path: '/button_groups/$i'),
            members: members,
          ),
        );
      }
    }

    return ButtonCatalog(buttons: buttons, groups: groups);
  }

  // ── characters ────────────────────────────────────────────────

  List<CharacterSpec> _parseCharacters(Map<String, dynamic> root) {
    final list = root['characters'];
    if (list is! List || list.isEmpty) {
      throw GoldParseException(
        '`characters` must be a non-empty array.',
        path: '/characters',
      );
    }
    final out = <CharacterSpec>[];
    for (var i = 0; i < list.length; i++) {
      final e = list[i];
      if (e is! Map<String, dynamic>) {
        throw GoldParseException(
          'Character is not an object.',
          path: '/characters/$i',
        );
      }
      out.add(
        CharacterSpec(
          id: _requireString(e, 'id', path: '/characters/$i'),
          name: _requireString(e, 'name', path: '/characters/$i'),
        ),
      );
    }
    return out;
  }

  // ── moves ─────────────────────────────────────────────────────

  MoveGold _parseMove(Map<String, dynamic> node, String path, ButtonCatalog _) {
    final id = _requireString(node, 'id', path: path);
    final name = _requireString(node, 'name', path: path);
    final rawCategory = _requireString(node, 'category', path: path);
    final activation = _parseActivation(
      _requireObject(node, 'activation', path: path),
      '$path/activation',
    );

    final wrappers = <InputExpressionWrapper>[];
    final wrappersRaw = node['input_expressions'];
    if (wrappersRaw is List) {
      for (var i = 0; i < wrappersRaw.length; i++) {
        final w = wrappersRaw[i];
        if (w is! Map<String, dynamic>) {
          throw GoldParseException(
            'input_expressions[$i] is not an object.',
            path: '$path/input_expressions/$i',
          );
        }
        wrappers.add(_parseWrapper(w, '$path/input_expressions/$i'));
      }
    }

    // §8.2 invariant: by_player_input requires at least one input expr.
    if (activation.kind == ActivationKind.byPlayerInput && wrappers.isEmpty) {
      throw GoldParseException(
        'Move with activation.kind="by_player_input" must have at least one '
        'input_expressions entry.',
        path: '$path/input_expressions',
      );
    }

    final annotations = <Annotation>[];
    final annRaw = node['annotations'];
    if (annRaw is List) {
      for (var i = 0; i < annRaw.length; i++) {
        final a = annRaw[i];
        if (a is! Map<String, dynamic>) {
          throw GoldParseException(
            'annotation is not an object.',
            path: '$path/annotations/$i',
          );
        }
        final rawKind = _requireString(a, 'kind', path: '$path/annotations/$i');
        annotations.add(
          Annotation(
            kind: AnnotationKind.fromWire(rawKind),
            rawKind: rawKind,
            value: a['value'],
            description: a['description'] as String?,
          ),
        );
      }
    }

    final followUps = <FollowUp>[];
    final fuRaw = node['follow_ups'];
    if (fuRaw is List) {
      for (var i = 0; i < fuRaw.length; i++) {
        final e = fuRaw[i];
        if (e is! Map<String, dynamic>) {
          throw GoldParseException(
            'follow_up is not an object.',
            path: '$path/follow_ups/$i',
          );
        }
        followUps.add(
          FollowUp(
            moveId: _requireString(e, 'move_id', path: '$path/follow_ups/$i'),
            relation: FollowUpRelation.fromWire(e['relation'] as String?),
            rawRelation: e['relation'] as String?,
          ),
        );
      }
    }

    return MoveGold(
      id: id,
      characterId: node['character_id'] as String?,
      name: name,
      aliases: (node['aliases'] as List?)?.cast<String>() ?? const [],
      category: MoveCategory.fromWire(rawCategory),
      rawCategory: rawCategory,
      gauge: node['gauge'] as String?,
      sourceRaw: node['source_raw'] as String?,
      sourceDialect: node['source_dialect'] as String?,
      activation: activation,
      inputExpressions: wrappers,
      annotations: annotations,
      followUps: followUps,
    );
  }

  Activation _parseActivation(Map<String, dynamic> node, String path) {
    final rawKind = _requireString(node, 'kind', path: path);
    final kind = ActivationKind.fromWire(rawKind);
    ActivationTrigger? trigger;
    final trigNode = node['trigger'];
    if (trigNode is Map<String, dynamic>) {
      final rawTk = trigNode['kind'];
      trigger = ActivationTrigger(
        kind: TriggerKind.fromWire(rawTk is String ? rawTk : null),
        rawKind: rawTk is String ? rawTk : '',
        parentMoveId: trigNode['parent_move_id'] as String?,
        description: trigNode['description'] as String?,
      );
    }

    // §8.2: automatic_after_move requires trigger.parent_move_id.
    if (kind == ActivationKind.automaticAfterMove) {
      if (trigger == null || trigger.parentMoveId == null) {
        throw GoldParseException(
          'activation.kind="automatic_after_move" requires '
          'trigger.parent_move_id.',
          path: '$path/trigger/parent_move_id',
        );
      }
    }

    return Activation(
      kind: kind,
      rawKind: rawKind,
      trigger: trigger,
      description: node['description'] as String?,
    );
  }

  InputExpressionWrapper _parseWrapper(Map<String, dynamic> node, String path) {
    final ps = ParseStatus.fromWire(
      _requireString(node, 'parse_status', path: path),
    );
    final sourceRaw = node['source_raw'] as String?;

    if (ps == ParseStatus.unparsed) {
      if (sourceRaw == null) {
        throw GoldParseException(
          'parse_status="unparsed" requires source_raw.',
          path: '$path/source_raw',
        );
      }
      return InputExpressionWrapper(
        parseStatus: ps,
        sourceRaw: sourceRaw,
        expression: null,
      );
    }

    final exprRaw = node['expression'];
    if (exprRaw is! Map<String, dynamic>) {
      throw GoldParseException(
        'parse_status="${ps.wire}" requires an expression object.',
        path: '$path/expression',
      );
    }
    final expr = _parseExpression(exprRaw, '$path/expression');
    return InputExpressionWrapper(
      parseStatus: ps,
      sourceRaw: sourceRaw,
      expression: expr,
    );
  }

  // ── expressions ───────────────────────────────────────────────

  Expression _parseExpression(Map<String, dynamic> node, String path) {
    final kind = node['kind'];
    if (kind is! String) {
      throw GoldParseException(
        'expression.kind is required and must be a string.',
        path: '$path/kind',
        rawValue: kind,
      );
    }
    switch (kind) {
      case 'button':
        return ButtonExpr(_requireString(node, 'symbol', path: path));
      case 'direction':
        final rawDir = _requireString(node, 'direction', path: path);
        final dir = GoldDirection.fromWire(rawDir);
        if (dir == null) {
          // Unknown enum value inside a known discriminant: forward-compat
          // fallback keeps the node with `any`.
          return DirectionExpr(
            GoldDirection.any,
            relative: node['relative'] as bool?,
          );
        }
        return DirectionExpr(dir, relative: node['relative'] as bool?);
      case 'motion':
        final rawShape = _requireString(node, 'shape', path: path);
        final shape = MotionShape.fromWire(rawShape);
        if (shape == null) {
          // Unknown motion shape: preserve as fallback so a renderer
          // will show source_raw at wrapper level.
          return UnknownExpression(rawKind: 'motion:$rawShape', rawJson: node);
        }
        return MotionExpr(shape);
      case 'neutral':
        return const NeutralExpr();
      case 'sequence':
        final steps = _requireList(node, 'steps', path: path);
        if (steps.isEmpty) {
          throw GoldParseException(
            'sequence.steps must be non-empty.',
            path: '$path/steps',
          );
        }
        return SequenceExpr([
          for (var i = 0; i < steps.length; i++)
            _parseExpression(
              _asObject(steps[i], '$path/steps/$i'),
              '$path/steps/$i',
            ),
        ]);
      case 'alternative':
        final options = _requireList(node, 'options', path: path);
        if (options.length < 2) {
          throw GoldParseException(
            'alternative.options must have >=2 items.',
            path: '$path/options',
          );
        }
        return AlternativeExpr([
          for (var i = 0; i < options.length; i++)
            _parseExpression(
              _asObject(options[i], '$path/options/$i'),
              '$path/options/$i',
            ),
        ]);
      case 'simultaneous':
        final inputs = _requireList(node, 'inputs', path: path);
        if (inputs.length < 2) {
          throw GoldParseException(
            'simultaneous.inputs must have >=2 items.',
            path: '$path/inputs',
          );
        }
        return SimultaneousExpr([
          for (var i = 0; i < inputs.length; i++)
            _parseExpression(
              _asObject(inputs[i], '$path/inputs/$i'),
              '$path/inputs/$i',
            ),
        ]);
      case 'charge':
        final rawCd = _requireString(node, 'charge_direction', path: path);
        final cd = ChargeDirection.fromWire(rawCd);
        if (cd == null) {
          throw GoldParseException(
            'Unknown charge_direction "$rawCd".',
            path: '$path/charge_direction',
            rawValue: rawCd,
          );
        }
        final thenNode = _requireObject(node, 'then', path: path);
        return ChargeExpr(
          chargeDirection: cd,
          durationMs: _optionalInt(
            node['duration_ms'],
            path: '$path/duration_ms',
          ),
          then: _parseExpression(thenNode, '$path/then'),
        );
      case 'hold':
        final inputNode = _requireObject(node, 'input', path: path);
        return HoldExpr(
          input: _parseExpression(inputNode, '$path/input'),
          durationMs: _optionalInt(
            node['duration_ms'],
            path: '$path/duration_ms',
          ),
        );
      case 'release':
        final inputNode = _requireObject(node, 'input', path: path);
        return ReleaseExpr(input: _parseExpression(inputNode, '$path/input'));
      case 'repeat':
        final inputNode = _requireObject(node, 'input', path: path);
        return RepeatExpr(
          input: _parseExpression(inputNode, '$path/input'),
          count: _optionalInt(node['count'], path: '$path/count'),
          mash: node['mash'] as bool? ?? false,
        );
      case 'contextual':
        final reqsRaw = _requireList(node, 'requirements', path: path);
        if (reqsRaw.isEmpty) {
          throw GoldParseException(
            'contextual.requirements must be non-empty.',
            path: '$path/requirements',
          );
        }
        final reqs = <Requirement>[];
        for (var i = 0; i < reqsRaw.length; i++) {
          final r = _asObject(reqsRaw[i], '$path/requirements/$i');
          final rawRk = _requireString(
            r,
            'kind',
            path: '$path/requirements/$i',
          );
          reqs.add(
            Requirement(
              kind: RequirementKind.fromWire(rawRk),
              rawKind: rawRk,
              value: r['value'] as String?,
              description: r['description'] as String?,
            ),
          );
        }
        final inputNode = _requireObject(node, 'input', path: path);
        return ContextualExpr(
          requirements: reqs,
          input: _parseExpression(inputNode, '$path/input'),
        );
      case 'optional':
        final inputNode = _requireObject(node, 'input', path: path);
        return OptionalExpr(input: _parseExpression(inputNode, '$path/input'));
      case 'fallback':
        return FallbackExpr(_requireString(node, 'source_raw', path: path));
      default:
        // Unknown discriminant: preserve as UnknownExpression. The
        // wrapper's `source_raw` is the safe surface for renderers.
        return UnknownExpression(rawKind: kind, rawJson: node);
    }
  }

  // ── reference validation ──────────────────────────────────────

  void _validateReferences(
    List<CharacterSpec> characters,
    List<MoveGold> moves,
  ) {
    final charIds = {for (final c in characters) c.id};
    final moveIds = {for (final m in moves) m.id};

    for (var i = 0; i < moves.length; i++) {
      final m = moves[i];
      final path = '/moves/$i';
      if (m.characterId != null && !charIds.contains(m.characterId)) {
        throw GoldParseException(
          'Move "${m.id}" references unknown character_id '
          '"${m.characterId}".',
          path: '$path/character_id',
          rawValue: m.characterId,
        );
      }
      final parent = m.activation.trigger?.parentMoveId;
      if (m.activation.kind == ActivationKind.automaticAfterMove &&
          parent != null &&
          !moveIds.contains(parent)) {
        throw GoldParseException(
          'Move "${m.id}" activation.trigger.parent_move_id "$parent" '
          'does not resolve to a declared move.',
          path: '$path/activation/trigger/parent_move_id',
          rawValue: parent,
        );
      }
      for (var f = 0; f < m.followUps.length; f++) {
        final ref = m.followUps[f].moveId;
        if (!moveIds.contains(ref)) {
          throw GoldParseException(
            'Move "${m.id}" follow_ups[$f].move_id "$ref" does not '
            'resolve to a declared move.',
            path: '$path/follow_ups/$f/move_id',
            rawValue: ref,
          );
        }
      }
    }
  }

  // ── helpers ───────────────────────────────────────────────────

  String _requireString(
    Map<String, dynamic> node,
    String key, {
    required String path,
  }) {
    final v = node[key];
    if (v is! String) {
      throw GoldParseException(
        'Missing or non-string field "$key".',
        path: path.isEmpty ? '/$key' : '$path/$key',
        rawValue: v,
      );
    }
    return v;
  }

  int _requireInt(
    Map<String, dynamic> node,
    String key, {
    required String path,
  }) {
    final v = node[key];
    if (v is! int) {
      throw GoldParseException(
        'Missing or non-integer field "$key".',
        path: path.isEmpty ? '/$key' : '$path/$key',
        rawValue: v,
      );
    }
    return v;
  }

  Map<String, dynamic> _requireObject(
    Map<String, dynamic> node,
    String key, {
    String path = '',
  }) {
    final v = node[key];
    if (v is! Map<String, dynamic>) {
      throw GoldParseException(
        'Missing or non-object field "$key".',
        path: path.isEmpty ? '/$key' : '$path/$key',
        rawValue: v,
      );
    }
    return v;
  }

  List<dynamic> _requireList(
    Map<String, dynamic> node,
    String key, {
    required String path,
  }) {
    final v = node[key];
    if (v is! List) {
      throw GoldParseException(
        'Missing or non-array field "$key".',
        path: '$path/$key',
        rawValue: v,
      );
    }
    return v;
  }

  Map<String, dynamic> _asObject(Object? v, String path) {
    if (v is! Map<String, dynamic>) {
      throw GoldParseException('Expected an object.', path: path, rawValue: v);
    }
    return v;
  }

  int? _optionalInt(Object? v, {required String path}) {
    if (v == null) return null;
    if (v is int) return v;
    throw GoldParseException(
      'Expected an integer or null.',
      path: path,
      rawValue: v,
    );
  }

  DateTime? _optionalDateTime(Object? v, {required String path}) {
    if (v == null) return null;
    if (v is! String) {
      throw GoldParseException(
        'Expected an ISO 8601 string or null.',
        path: path,
        rawValue: v,
      );
    }
    try {
      return DateTime.parse(v).toUtc();
    } catch (e) {
      throw GoldParseException(
        'Invalid ISO 8601 timestamp: $e',
        path: path,
        rawValue: v,
      );
    }
  }
}
