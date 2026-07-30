import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/expression.dart';
import '../../domain/move.dart';

/// Localized human-readable name for a [MoveCategory].
///
/// When [category] is [MoveCategory.unknown] the caller-provided
/// [rawCategory] is preserved as a fallback so the UI never shows an
/// empty string but also never hides a wire value we don't know
/// (CONSUMER_SPEC §9).
String localizeCategory(
  AppLocalizations l,
  MoveCategory category,
  String rawCategory,
) {
  return switch (category) {
    MoveCategory.normal => l.moveCategoryNormal,
    MoveCategory.commandNormal => l.moveCategoryCommandNormal,
    MoveCategory.throwMove => l.moveCategoryThrow,
    MoveCategory.special => l.moveCategorySpecial,
    MoveCategory.superMove => l.moveCategorySuper,
    MoveCategory.desperation => l.moveCategoryDesperation,
    MoveCategory.superDesperation => l.moveCategorySuperDesperation,
    MoveCategory.climax => l.moveCategoryClimax,
    MoveCategory.movement => l.moveCategoryMovement,
    MoveCategory.system => l.moveCategorySystem,
    MoveCategory.cheat => l.moveCategoryCheat,
    MoveCategory.info => l.moveCategoryInfo,
    MoveCategory.unknown =>
      rawCategory.isEmpty ? l.moveCategoryUnknown : rawCategory,
  };
}

/// Localized short phrase describing a contextual [Requirement].
///
/// Any (kind, value) tuple not enumerated here — including
/// [RequirementKind.unknown] wire values — falls through to
/// [AppLocalizations.moveReqUnknown] carrying the raw discriminant so
/// unknown data is surfaced rather than dropped.
String localizeRequirement(AppLocalizations l, Requirement r) {
  final key = '${r.rawKind}:${r.value ?? ''}';
  return switch (key) {
    'spatial:near_opponent' => l.moveReqSpatialNearOpponent,
    'spatial:near_wall' => l.moveReqSpatialNearWall,
    'spatial:far_opponent' => l.moveReqSpatialFarOpponent,
    'state:airborne' => l.moveReqStateAirborne,
    'state:on_ground' => l.moveReqStateOnGround,
    'state:crouching' => l.moveReqStateCrouching,
    'state:standing' => l.moveReqStateStanding,
    'phase:knockdown' => l.moveReqPhaseKnockdown,
    'phase:wakeup' => l.moveReqPhaseWakeup,
    'stance:ex' => l.moveReqStanceEx,
    _ => l.moveReqUnknown(
      r.description ??
          (r.value == null ? r.rawKind : '${r.rawKind}:${r.value}'),
    ),
  };
}
