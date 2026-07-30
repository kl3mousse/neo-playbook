import 'package:meta/meta.dart';

import 'button.dart';
import 'character.dart';
import 'move.dart';
import 'notation_frame.dart';
import 'provenance.dart';

@immutable
class AppliesTo {
  final String? gameId;
  final String platform;
  final String? region;
  final List<String> romIds;
  final NotationFrame notationFrame;

  /// Original wire value for `notation_frame`. Preserved so tests can
  /// verify that unknown values are tolerated per §4.
  final String rawNotationFrame;

  const AppliesTo({
    required this.platform,
    required this.notationFrame,
    required this.rawNotationFrame,
    this.gameId,
    this.region,
    this.romIds = const [],
  });
}

/// Top-level Gold Moves Profile, faithful to the wire model. Character
/// and move lists preserve editorial order.
@immutable
class ProfileGold {
  final String goldSchemaVersion;
  final String silverSchemaVersion;
  final String id;
  final int profileRevision;
  final DateTime? generatedAt;
  final AppliesTo appliesTo;
  final Attribution attribution;
  final ButtonCatalog buttons;
  final List<CharacterSpec> characters;
  final List<MoveGold> moves;

  /// Any unrecognised top-level fields, preserved for forward
  /// compatibility (§10).
  final Map<String, Object?> unknownFields;

  final Map<String, CharacterSpec> _charactersById;
  final Map<String, MoveGold> _movesById;

  ProfileGold({
    required this.goldSchemaVersion,
    required this.silverSchemaVersion,
    required this.id,
    required this.profileRevision,
    required this.appliesTo,
    required this.attribution,
    required this.buttons,
    required this.characters,
    required this.moves,
    this.generatedAt,
    this.unknownFields = const {},
  }) : _charactersById = {for (final c in characters) c.id: c},
       _movesById = {for (final m in moves) m.id: m};

  CharacterSpec? character(String id) => _charactersById[id];
  MoveGold? move(String id) => _movesById[id];

  Iterable<MoveGold> movesForCharacter(String characterId) =>
      moves.where((m) => m.characterId == characterId);
}
