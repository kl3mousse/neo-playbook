import 'package:meta/meta.dart';

import 'expression.dart';
import 'annotation.dart';
import 'parse_status.dart';

/// Editorial category of a move. Unknown wire values become
/// [MoveCategory.unknown] per CONSUMER_SPEC §8.1.
enum MoveCategory {
  normal('normal'),
  commandNormal('command_normal'),
  throwMove('throw'),
  special('special'),
  superMove('super'),
  desperation('desperation'),
  superDesperation('super_desperation'),
  climax('climax'),
  movement('movement'),
  system('system'),
  cheat('cheat'),
  info('info'),
  unknown('unknown');

  final String wire;
  const MoveCategory(this.wire);

  static MoveCategory fromWire(String? value) {
    for (final c in MoveCategory.values) {
      if (c.wire == value) return c;
    }
    return MoveCategory.unknown;
  }
}

enum ActivationKind {
  byPlayerInput('by_player_input'),
  automaticAfterMove('automatic_after_move'),
  contextualTrigger('contextual_trigger'),
  unknown('unknown');

  final String wire;
  const ActivationKind(this.wire);

  static ActivationKind fromWire(String? value) {
    for (final k in ActivationKind.values) {
      if (k.wire == value) return k;
    }
    return ActivationKind.unknown;
  }
}

enum TriggerKind {
  onHit('on_hit'),
  onMidHit('on_mid_hit'),
  onLowHit('on_low_hit'),
  onHighHit('on_high_hit'),
  onWallHit('on_wall_hit'),
  onCounterHit('on_counter_hit'),
  onBlock('on_block'),
  onLanding('on_landing'),
  onWakeup('on_wakeup'),
  onActivation('on_activation'),
  nearWall('near_wall'),
  custom('custom'),
  unknown('unknown');

  final String wire;
  const TriggerKind(this.wire);

  static TriggerKind fromWire(String? value) {
    for (final k in TriggerKind.values) {
      if (k.wire == value) return k;
    }
    return TriggerKind.unknown;
  }
}

@immutable
class ActivationTrigger {
  final TriggerKind kind;
  final String rawKind;
  final String? parentMoveId;
  final String? description;

  const ActivationTrigger({
    required this.kind,
    required this.rawKind,
    this.parentMoveId,
    this.description,
  });
}

@immutable
class Activation {
  final ActivationKind kind;
  final String rawKind;
  final ActivationTrigger? trigger;
  final String? description;

  const Activation({
    required this.kind,
    required this.rawKind,
    this.trigger,
    this.description,
  });
}

/// A parsed input expression together with its verbatim source snippet.
@immutable
class InputExpressionWrapper {
  final ParseStatus parseStatus;

  /// Present iff `parseStatus != unparsed`.
  final Expression? expression;

  /// Present iff `parseStatus != parsed` (and always non-null for
  /// unparsed per schema).
  final String? sourceRaw;

  const InputExpressionWrapper({
    required this.parseStatus,
    this.expression,
    this.sourceRaw,
  });
}

enum FollowUpRelation {
  cancel('cancel'),
  chain('chain'),
  followUp('follow_up'),
  variant('variant'),
  extension('extension'),
  unknown('unknown');

  final String wire;
  const FollowUpRelation(this.wire);

  static FollowUpRelation fromWire(String? value) {
    if (value == null) return FollowUpRelation.unknown;
    for (final r in FollowUpRelation.values) {
      if (r.wire == value) return r;
    }
    return FollowUpRelation.unknown;
  }
}

@immutable
class FollowUp {
  final String moveId;
  final FollowUpRelation relation;

  /// Original relation wire value; null when omitted in the source.
  final String? rawRelation;

  const FollowUp({
    required this.moveId,
    required this.relation,
    this.rawRelation,
  });
}

@immutable
class MoveGold {
  final String id;
  final String? characterId;
  final String name;
  final List<String> aliases;
  final MoveCategory category;
  final String rawCategory;
  final String? gauge;
  final String? sourceRaw;
  final String? sourceDialect;
  final Activation activation;
  final List<InputExpressionWrapper> inputExpressions;
  final List<Annotation> annotations;
  final List<FollowUp> followUps;

  const MoveGold({
    required this.id,
    required this.name,
    required this.category,
    required this.rawCategory,
    required this.activation,
    this.characterId,
    this.aliases = const [],
    this.gauge,
    this.sourceRaw,
    this.sourceDialect,
    this.inputExpressions = const [],
    this.annotations = const [],
    this.followUps = const [],
  });

  bool get isAutomaticFollowUp =>
      activation.kind == ActivationKind.automaticAfterMove;

  bool get isPlayerInput => activation.kind == ActivationKind.byPlayerInput;

  bool get hasStructuredInput => inputExpressions.any(
    (w) => w.parseStatus != ParseStatus.unparsed && w.expression != null,
  );
}
