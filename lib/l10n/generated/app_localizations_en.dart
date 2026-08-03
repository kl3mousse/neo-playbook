// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsDevSectionTitle => 'Developer tools';

  @override
  String get settingsGoldLabTitle => 'Gold Move Lab';

  @override
  String get settingsGoldLabSubtitle =>
      'Preview the experimental Gold Moves Profile renderer';

  @override
  String get labTitle => 'Gold Move Lab';

  @override
  String get labTabCharacters => 'Characters';

  @override
  String get labTabGallery => 'Gallery';

  @override
  String get labTabProvenance => 'Sources';

  @override
  String get labTabDiagnostics => 'Diagnostics';

  @override
  String get labLoading => 'Loading profile…';

  @override
  String get labLoadErrorTitle => 'Could not load the Gold profile';

  @override
  String get labLoadErrorHint =>
      'Check that the bundled fixture exists and is valid.';

  @override
  String get labRetry => 'Retry';

  @override
  String get labHeaderGame => 'Game';

  @override
  String get labHeaderGoldVersion => 'Gold contract';

  @override
  String get labHeaderCharacters => 'Characters';

  @override
  String get labHeaderMoves => 'Moves';

  @override
  String get labHeaderAutomatic => 'Automatic activations';

  @override
  String get labHeaderSource => 'Primary source';

  @override
  String get labSearchHint => 'Search a move by name';

  @override
  String get labSearchClear => 'Clear';

  @override
  String labResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moves',
      one: '1 move',
      zero: 'No moves',
    );
    return '$_temp0';
  }

  @override
  String get labEmptyStateTitle => 'No results';

  @override
  String get labEmptyStateHint =>
      'Try clearing the filter or searching another term.';

  @override
  String get labSelectCharacter =>
      'Select a character on the left to see its moves.';

  @override
  String get labFilterAllMoves => 'All moves';

  @override
  String get labFilterAutomatic => 'Automatic activations';

  @override
  String get labFilterGroupByCategory => 'Group by category';

  @override
  String get labSettingsTitle => 'Rendering options';

  @override
  String get labSectionNotation => 'Notation';

  @override
  String get labNotationPictograms => 'ComboFox pictograms';

  @override
  String get labNotationNumpad => 'Numpad';

  @override
  String get labNotationClassic2d => '2D classic';

  @override
  String get labNotationAccessible => 'Accessible text';

  @override
  String get labSectionAccessibleLocale => 'Accessible text language';

  @override
  String get labLocaleEn => 'English';

  @override
  String get labLocaleFr => 'French';

  @override
  String get labSectionTheme => 'Theme';

  @override
  String get labThemeDark => 'Dark';

  @override
  String get labThemeLight => 'Light';

  @override
  String get labThemeSystem => 'System';

  @override
  String get labSectionDensity => 'Density';

  @override
  String get labDensityComfortable => 'Comfortable';

  @override
  String get labDensityCompact => 'Compact';

  @override
  String get labSectionTextScale => 'Text size (simulated)';

  @override
  String get labTextScaleHint =>
      'Only affects the Lab, not your global preferences.';

  @override
  String labTextScalePercent(int percent) {
    return '$percent%';
  }

  @override
  String get labGalleryTitle => 'Component gallery';

  @override
  String get labGallerySubtitle =>
      'Representative Gold expression kinds. Synthetic cases are labelled as such.';

  @override
  String get labGallerySynthetic => 'Synthetic example';

  @override
  String get labGalleryFromProfile => 'From KOF R-2 profile';

  @override
  String get labGalleryShowTokens => 'Show tokens & data';

  @override
  String get labGalleryHideTokens => 'Hide tokens & data';

  @override
  String get labCaseSimpleCommand => 'Simple command';

  @override
  String get labCaseQuarterCircle => 'Quarter circle';

  @override
  String get labCaseDragonPunch => 'Dragon punch';

  @override
  String get labCaseCharge => 'Charge';

  @override
  String get labCaseSequence => 'Composed sequence';

  @override
  String get labCaseSimultaneous => 'Simultaneous';

  @override
  String get labCaseHold => 'Hold';

  @override
  String get labCaseRelease => 'Release';

  @override
  String get labCaseAlternative => 'Alternative';

  @override
  String get labCaseContextual => 'Contextual';

  @override
  String get labCaseRequirement => 'Requirement';

  @override
  String get labCaseAnnotation => 'Annotation';

  @override
  String get labCaseLongCommand => 'Long command';

  @override
  String get labCaseAutomatic => 'Automatic activation';

  @override
  String get labCaseFallback => 'Fallback (raw)';

  @override
  String get labCaseUnknown => 'Unknown input';

  @override
  String get labAutomaticBadge => 'Automatic';

  @override
  String get labAutomaticExplanation =>
      'Fires automatically. The player does not press anything.';

  @override
  String labAutomaticFollowUpOf(String name) {
    return 'Follow-up of “$name”';
  }

  @override
  String get labAutomaticJumpToParent => 'Go to parent move';

  @override
  String get labProvenanceTitle => 'Sources & attribution';

  @override
  String get labProvenanceLicense => 'License';

  @override
  String get labProvenanceRole => 'Role';

  @override
  String get labProvenanceVersion => 'Version';

  @override
  String get labProvenanceUrl => 'URL';

  @override
  String get labProvenanceOpenUrl => 'Open source URL';

  @override
  String get labProvenanceAdditional => 'Additional sources';

  @override
  String get labProvenanceAttribution => 'Attribution text';

  @override
  String get labDiagnosticsTitle => 'Technical data';

  @override
  String get labDiagnosticsProfileVersion => 'Profile version';

  @override
  String get labDiagnosticsRendererVersion => 'Renderer version';

  @override
  String get labDiagnosticsCharactersCount => 'Characters loaded';

  @override
  String get labDiagnosticsMovesCount => 'Moves loaded';

  @override
  String get labDiagnosticsByActivation => 'Moves by activation';

  @override
  String get labDiagnosticsNotationFrame => 'Notation frame';

  @override
  String get labDiagnosticsSelectedCharacter => 'Selected character';

  @override
  String get labDiagnosticsSelectedMove => 'Selected move';

  @override
  String get labDiagnosticsSourceRaw => 'source_raw';

  @override
  String get labDiagnosticsTokens => 'Render tokens';

  @override
  String get labDiagnosticsParseStatus => 'Parse status';

  @override
  String get labDiagnosticsRelatedMoves => 'Related moves';

  @override
  String get labDiagnosticsCopy => 'Copy';

  @override
  String get labDiagnosticsCopied => 'Copied to clipboard';

  @override
  String get labErrorMoveTitle => 'Cannot display this move';

  @override
  String get labErrorMoveHint => 'Other moves remain browsable.';

  @override
  String get labErrorUnsupportedGoldVersion => 'Unsupported Gold version';

  @override
  String get labErrorInvalidReference => 'Invalid move reference';

  @override
  String get labErrorUnknownDiscriminant => 'Unknown discriminant';

  @override
  String get labErrorPartialExpression => 'Expression partially understood';

  @override
  String get labErrorUnknownInput => 'Unknown input';

  @override
  String get labErrorNoInputConfirmed => 'No player input required';

  @override
  String get labMoveNoInput => 'This move is not triggered by a player input.';

  @override
  String get labMoveRawSource => 'Raw source';

  @override
  String get labIrDirection => 'Direction';

  @override
  String get labIrButton => 'Button';

  @override
  String get labIrMotion => 'Motion';

  @override
  String get labIrCharge => 'Charge';

  @override
  String get labIrHold => 'Hold';

  @override
  String get labIrRelease => 'Release';

  @override
  String get labIrRepeat => 'Repeat';

  @override
  String get labIrOptional => 'Optional';

  @override
  String get labIrSequence => 'Sequence';

  @override
  String get labIrSimultaneous => 'Simultaneous';

  @override
  String get labIrAlternative => 'Alternative';

  @override
  String get labIrContextual => 'Contextual';

  @override
  String get labIrFallback => 'Fallback';

  @override
  String get labIrUnknown => 'Unknown';

  @override
  String get moveCategoryNormal => 'Normal';

  @override
  String get moveCategoryCommandNormal => 'Command normal';

  @override
  String get moveCategoryThrow => 'Throw';

  @override
  String get moveCategorySpecial => 'Special';

  @override
  String get moveCategorySuper => 'Super';

  @override
  String get moveCategoryDesperation => 'Desperation move';

  @override
  String get moveCategorySuperDesperation => 'Super desperation move';

  @override
  String get moveCategoryClimax => 'Climax';

  @override
  String get moveCategoryMovement => 'Movement';

  @override
  String get moveCategorySystem => 'System';

  @override
  String get moveCategoryCheat => 'Cheat';

  @override
  String get moveCategoryInfo => 'Info';

  @override
  String get moveCategoryUnknown => 'Unknown category';

  @override
  String get moveReqSpatialNearOpponent => 'Close to the opponent';

  @override
  String get moveReqSpatialNearWall => 'Near a wall';

  @override
  String get moveReqSpatialFarOpponent => 'Far from the opponent';

  @override
  String get moveReqStateAirborne => 'In the air';

  @override
  String get moveReqStateOnGround => 'On the ground';

  @override
  String get moveReqStateCrouching => 'While crouching';

  @override
  String get moveReqStateStanding => 'While standing';

  @override
  String get moveReqPhaseKnockdown => 'After a knockdown';

  @override
  String get moveReqPhaseWakeup => 'On wake-up';

  @override
  String get moveReqStanceEx => 'EX stance';

  @override
  String moveReqUnknown(String raw) {
    return 'Requirement: $raw';
  }

  @override
  String get commandSepThen => 'then';

  @override
  String get commandSepOr => 'or';

  @override
  String get commandSepAnd => 'and';

  @override
  String get commandHoldOpen => 'hold';

  @override
  String get commandReleaseOpen => 'release';

  @override
  String get commandOptionalOpen => 'optional';

  @override
  String get commandRepeatRapidly => 'repeatedly';

  @override
  String commandRepeatCount(int count) {
    return '×$count';
  }

  @override
  String get commandNoInputNeeded => 'No player input required';

  @override
  String get commandUnknownInput => 'Unknown command';

  @override
  String get commandFallbackHint => 'Verbatim source (unparsed)';

  @override
  String get labComparisonTitle => 'Notation comparison';

  @override
  String get labComparisonSubtitle => 'Same move rendered in every notation.';

  @override
  String get labComparisonCasePictograms => 'Pictograms';

  @override
  String get labComparisonCaseNumpad => 'Numpad';

  @override
  String get labComparisonCaseClassic => '2D classic';

  @override
  String get labComparisonCaseAccessible => 'Accessible text';

  @override
  String get labComparisonCaseSemantic => 'Semantic label';

  @override
  String get labVisualReviewTitle => 'Visual review';

  @override
  String get labVisualReviewSubtitle =>
      'Curated hard cases. Change notation, theme, density, language and text size to inspect them.';

  @override
  String get labTechnicalDetails => 'Technical details';

  @override
  String get labMoveCategoryLabel => 'Category';

  @override
  String get labMoveRequirementLabel => 'Only when';

  @override
  String get labProvenanceVerbatim => 'Verbatim attribution text';

  @override
  String get labProvenanceStructured => 'Structured fields';

  @override
  String labProvenanceComposedCredit(String source, String license) {
    return '$source — $license';
  }

  @override
  String get goldMoveListTitle => 'Move List';

  @override
  String get goldProfileLabel => 'Gold profile';

  @override
  String goldCharactersMoves(int characters, int moves) {
    return '$characters characters · $moves moves';
  }

  @override
  String get goldSearchHint => 'Search by move, alias or character';

  @override
  String get goldNotation => 'Notation';

  @override
  String get goldDensity => 'Density';

  @override
  String get goldPictograms => 'ComboFox pictograms';

  @override
  String get goldNumpad => 'Numpad';

  @override
  String get goldClassic2d => '2D classic';

  @override
  String get goldAccessible => 'Accessible text';

  @override
  String get goldCompact => 'Compact';

  @override
  String get goldComfortable => 'Comfortable';

  @override
  String get goldLoading => 'Loading move list…';

  @override
  String get goldLoadError => 'Could not load this move list.';

  @override
  String get goldLoadOffline =>
      'This move list is unavailable offline. Check your connection and try again.';

  @override
  String get goldLoadUnsupported =>
      'This move list needs a newer version of the app.';

  @override
  String get goldRetry => 'Retry';

  @override
  String get goldNoResults => 'No moves found.';

  @override
  String goldMovesCount(int count) {
    return '$count moves';
  }

  @override
  String get goldBookmark => 'Bookmark character';

  @override
  String get goldRemoveBookmark => 'Remove bookmark';

  @override
  String get goldSignInBookmark => 'Sign in to bookmark characters';

  @override
  String get goldSourcesAttribution => 'Sources & attribution';

  @override
  String get goldOpenSource => 'Open source';

  @override
  String get goldAttributionText => 'Attribution text';

  @override
  String get goldCharacterMissing =>
      'This character is no longer available in the move list.';

  @override
  String get goldDisplayPreferences => 'Move-list display';

  @override
  String get goldDisplayPreferencesSubtitle => 'Notation and density';

  @override
  String get goldNotationPictogramsHelp =>
      'Visual arrows and button symbols. Best when you want to read commands at a glance.';

  @override
  String get goldNotationNumpadHelp =>
      'Uses keyboard directions: 2 = down, 3 = down-forward, 6 = forward. The example is 236 P.';

  @override
  String get goldNotationClassicHelp =>
      'Uses fighting-game shorthand: QCF means quarter-circle forward. The example is QCF + P.';

  @override
  String get goldNotationAccessibleHelp =>
      'Writes the command as a complete sentence, designed for screen readers and plain-language reading.';

  @override
  String get goldDensityHelp => 'Choose how much context appears on each move.';

  @override
  String get goldCompactHelp =>
      'A concise layout for scanning many moves quickly.';

  @override
  String get goldComfortableHelp =>
      'More spacing plus requirements and annotations when they are available.';

  @override
  String get goldAccessibleExample => 'Quarter-circle forward, then Punch';
}
