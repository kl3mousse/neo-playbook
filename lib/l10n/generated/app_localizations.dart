import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Section header for debug-only tools in Settings.
  ///
  /// In en, this message translates to:
  /// **'Developer tools'**
  String get settingsDevSectionTitle;

  /// No description provided for @settingsGoldLabTitle.
  ///
  /// In en, this message translates to:
  /// **'Gold Move Lab'**
  String get settingsGoldLabTitle;

  /// No description provided for @settingsGoldLabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preview the experimental Gold Moves Profile renderer'**
  String get settingsGoldLabSubtitle;

  /// No description provided for @labTitle.
  ///
  /// In en, this message translates to:
  /// **'Gold Move Lab'**
  String get labTitle;

  /// No description provided for @labTabCharacters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get labTabCharacters;

  /// No description provided for @labTabGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get labTabGallery;

  /// No description provided for @labTabProvenance.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get labTabProvenance;

  /// No description provided for @labTabDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get labTabDiagnostics;

  /// No description provided for @labLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading profile…'**
  String get labLoading;

  /// No description provided for @labLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load the Gold profile'**
  String get labLoadErrorTitle;

  /// No description provided for @labLoadErrorHint.
  ///
  /// In en, this message translates to:
  /// **'Check that the bundled fixture exists and is valid.'**
  String get labLoadErrorHint;

  /// No description provided for @labRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get labRetry;

  /// No description provided for @labHeaderGame.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get labHeaderGame;

  /// No description provided for @labHeaderGoldVersion.
  ///
  /// In en, this message translates to:
  /// **'Gold contract'**
  String get labHeaderGoldVersion;

  /// No description provided for @labHeaderCharacters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get labHeaderCharacters;

  /// No description provided for @labHeaderMoves.
  ///
  /// In en, this message translates to:
  /// **'Moves'**
  String get labHeaderMoves;

  /// No description provided for @labHeaderAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic activations'**
  String get labHeaderAutomatic;

  /// No description provided for @labHeaderSource.
  ///
  /// In en, this message translates to:
  /// **'Primary source'**
  String get labHeaderSource;

  /// No description provided for @labSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search a move by name'**
  String get labSearchHint;

  /// No description provided for @labSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get labSearchClear;

  /// No description provided for @labResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{No moves}=1{1 move}other{{count} moves}}'**
  String labResultsCount(int count);

  /// No description provided for @labEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get labEmptyStateTitle;

  /// No description provided for @labEmptyStateHint.
  ///
  /// In en, this message translates to:
  /// **'Try clearing the filter or searching another term.'**
  String get labEmptyStateHint;

  /// No description provided for @labSelectCharacter.
  ///
  /// In en, this message translates to:
  /// **'Select a character on the left to see its moves.'**
  String get labSelectCharacter;

  /// No description provided for @labFilterAllMoves.
  ///
  /// In en, this message translates to:
  /// **'All moves'**
  String get labFilterAllMoves;

  /// No description provided for @labFilterAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic activations'**
  String get labFilterAutomatic;

  /// No description provided for @labFilterGroupByCategory.
  ///
  /// In en, this message translates to:
  /// **'Group by category'**
  String get labFilterGroupByCategory;

  /// No description provided for @labSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rendering options'**
  String get labSettingsTitle;

  /// No description provided for @labSectionNotation.
  ///
  /// In en, this message translates to:
  /// **'Notation'**
  String get labSectionNotation;

  /// No description provided for @labNotationPictograms.
  ///
  /// In en, this message translates to:
  /// **'ComboFox pictograms'**
  String get labNotationPictograms;

  /// No description provided for @labNotationNumpad.
  ///
  /// In en, this message translates to:
  /// **'Numpad'**
  String get labNotationNumpad;

  /// No description provided for @labNotationClassic2d.
  ///
  /// In en, this message translates to:
  /// **'2D classic'**
  String get labNotationClassic2d;

  /// No description provided for @labNotationAccessible.
  ///
  /// In en, this message translates to:
  /// **'Accessible text'**
  String get labNotationAccessible;

  /// No description provided for @labSectionAccessibleLocale.
  ///
  /// In en, this message translates to:
  /// **'Accessible text language'**
  String get labSectionAccessibleLocale;

  /// No description provided for @labLocaleEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get labLocaleEn;

  /// No description provided for @labLocaleFr.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get labLocaleFr;

  /// No description provided for @labSectionTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get labSectionTheme;

  /// No description provided for @labThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get labThemeDark;

  /// No description provided for @labThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get labThemeLight;

  /// No description provided for @labThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get labThemeSystem;

  /// No description provided for @labSectionDensity.
  ///
  /// In en, this message translates to:
  /// **'Density'**
  String get labSectionDensity;

  /// No description provided for @labDensityComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get labDensityComfortable;

  /// No description provided for @labDensityCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get labDensityCompact;

  /// No description provided for @labSectionTextScale.
  ///
  /// In en, this message translates to:
  /// **'Text size (simulated)'**
  String get labSectionTextScale;

  /// No description provided for @labTextScaleHint.
  ///
  /// In en, this message translates to:
  /// **'Only affects the Lab, not your global preferences.'**
  String get labTextScaleHint;

  /// No description provided for @labTextScalePercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String labTextScalePercent(int percent);

  /// No description provided for @labGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Component gallery'**
  String get labGalleryTitle;

  /// No description provided for @labGallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Representative Gold expression kinds. Synthetic cases are labelled as such.'**
  String get labGallerySubtitle;

  /// No description provided for @labGallerySynthetic.
  ///
  /// In en, this message translates to:
  /// **'Synthetic example'**
  String get labGallerySynthetic;

  /// No description provided for @labGalleryFromProfile.
  ///
  /// In en, this message translates to:
  /// **'From KOF R-2 profile'**
  String get labGalleryFromProfile;

  /// No description provided for @labGalleryShowTokens.
  ///
  /// In en, this message translates to:
  /// **'Show tokens & data'**
  String get labGalleryShowTokens;

  /// No description provided for @labGalleryHideTokens.
  ///
  /// In en, this message translates to:
  /// **'Hide tokens & data'**
  String get labGalleryHideTokens;

  /// No description provided for @labCaseSimpleCommand.
  ///
  /// In en, this message translates to:
  /// **'Simple command'**
  String get labCaseSimpleCommand;

  /// No description provided for @labCaseQuarterCircle.
  ///
  /// In en, this message translates to:
  /// **'Quarter circle'**
  String get labCaseQuarterCircle;

  /// No description provided for @labCaseDragonPunch.
  ///
  /// In en, this message translates to:
  /// **'Dragon punch'**
  String get labCaseDragonPunch;

  /// No description provided for @labCaseCharge.
  ///
  /// In en, this message translates to:
  /// **'Charge'**
  String get labCaseCharge;

  /// No description provided for @labCaseSequence.
  ///
  /// In en, this message translates to:
  /// **'Composed sequence'**
  String get labCaseSequence;

  /// No description provided for @labCaseSimultaneous.
  ///
  /// In en, this message translates to:
  /// **'Simultaneous'**
  String get labCaseSimultaneous;

  /// No description provided for @labCaseHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get labCaseHold;

  /// No description provided for @labCaseRelease.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get labCaseRelease;

  /// No description provided for @labCaseAlternative.
  ///
  /// In en, this message translates to:
  /// **'Alternative'**
  String get labCaseAlternative;

  /// No description provided for @labCaseContextual.
  ///
  /// In en, this message translates to:
  /// **'Contextual'**
  String get labCaseContextual;

  /// No description provided for @labCaseRequirement.
  ///
  /// In en, this message translates to:
  /// **'Requirement'**
  String get labCaseRequirement;

  /// No description provided for @labCaseAnnotation.
  ///
  /// In en, this message translates to:
  /// **'Annotation'**
  String get labCaseAnnotation;

  /// No description provided for @labCaseLongCommand.
  ///
  /// In en, this message translates to:
  /// **'Long command'**
  String get labCaseLongCommand;

  /// No description provided for @labCaseAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic activation'**
  String get labCaseAutomatic;

  /// No description provided for @labCaseFallback.
  ///
  /// In en, this message translates to:
  /// **'Fallback (raw)'**
  String get labCaseFallback;

  /// No description provided for @labCaseUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown input'**
  String get labCaseUnknown;

  /// No description provided for @labAutomaticBadge.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get labAutomaticBadge;

  /// No description provided for @labAutomaticExplanation.
  ///
  /// In en, this message translates to:
  /// **'Fires automatically. The player does not press anything.'**
  String get labAutomaticExplanation;

  /// No description provided for @labAutomaticFollowUpOf.
  ///
  /// In en, this message translates to:
  /// **'Follow-up of “{name}”'**
  String labAutomaticFollowUpOf(String name);

  /// No description provided for @labAutomaticJumpToParent.
  ///
  /// In en, this message translates to:
  /// **'Go to parent move'**
  String get labAutomaticJumpToParent;

  /// No description provided for @labProvenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Sources & attribution'**
  String get labProvenanceTitle;

  /// No description provided for @labProvenanceLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get labProvenanceLicense;

  /// No description provided for @labProvenanceRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get labProvenanceRole;

  /// No description provided for @labProvenanceVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get labProvenanceVersion;

  /// No description provided for @labProvenanceUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get labProvenanceUrl;

  /// No description provided for @labProvenanceOpenUrl.
  ///
  /// In en, this message translates to:
  /// **'Open source URL'**
  String get labProvenanceOpenUrl;

  /// No description provided for @labProvenanceAdditional.
  ///
  /// In en, this message translates to:
  /// **'Additional sources'**
  String get labProvenanceAdditional;

  /// No description provided for @labProvenanceAttribution.
  ///
  /// In en, this message translates to:
  /// **'Attribution text'**
  String get labProvenanceAttribution;

  /// No description provided for @labDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Technical data'**
  String get labDiagnosticsTitle;

  /// No description provided for @labDiagnosticsProfileVersion.
  ///
  /// In en, this message translates to:
  /// **'Profile version'**
  String get labDiagnosticsProfileVersion;

  /// No description provided for @labDiagnosticsRendererVersion.
  ///
  /// In en, this message translates to:
  /// **'Renderer version'**
  String get labDiagnosticsRendererVersion;

  /// No description provided for @labDiagnosticsCharactersCount.
  ///
  /// In en, this message translates to:
  /// **'Characters loaded'**
  String get labDiagnosticsCharactersCount;

  /// No description provided for @labDiagnosticsMovesCount.
  ///
  /// In en, this message translates to:
  /// **'Moves loaded'**
  String get labDiagnosticsMovesCount;

  /// No description provided for @labDiagnosticsByActivation.
  ///
  /// In en, this message translates to:
  /// **'Moves by activation'**
  String get labDiagnosticsByActivation;

  /// No description provided for @labDiagnosticsNotationFrame.
  ///
  /// In en, this message translates to:
  /// **'Notation frame'**
  String get labDiagnosticsNotationFrame;

  /// No description provided for @labDiagnosticsSelectedCharacter.
  ///
  /// In en, this message translates to:
  /// **'Selected character'**
  String get labDiagnosticsSelectedCharacter;

  /// No description provided for @labDiagnosticsSelectedMove.
  ///
  /// In en, this message translates to:
  /// **'Selected move'**
  String get labDiagnosticsSelectedMove;

  /// No description provided for @labDiagnosticsSourceRaw.
  ///
  /// In en, this message translates to:
  /// **'source_raw'**
  String get labDiagnosticsSourceRaw;

  /// No description provided for @labDiagnosticsTokens.
  ///
  /// In en, this message translates to:
  /// **'Render tokens'**
  String get labDiagnosticsTokens;

  /// No description provided for @labDiagnosticsParseStatus.
  ///
  /// In en, this message translates to:
  /// **'Parse status'**
  String get labDiagnosticsParseStatus;

  /// No description provided for @labDiagnosticsRelatedMoves.
  ///
  /// In en, this message translates to:
  /// **'Related moves'**
  String get labDiagnosticsRelatedMoves;

  /// No description provided for @labDiagnosticsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get labDiagnosticsCopy;

  /// No description provided for @labDiagnosticsCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get labDiagnosticsCopied;

  /// No description provided for @labErrorMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot display this move'**
  String get labErrorMoveTitle;

  /// No description provided for @labErrorMoveHint.
  ///
  /// In en, this message translates to:
  /// **'Other moves remain browsable.'**
  String get labErrorMoveHint;

  /// No description provided for @labErrorUnsupportedGoldVersion.
  ///
  /// In en, this message translates to:
  /// **'Unsupported Gold version'**
  String get labErrorUnsupportedGoldVersion;

  /// No description provided for @labErrorInvalidReference.
  ///
  /// In en, this message translates to:
  /// **'Invalid move reference'**
  String get labErrorInvalidReference;

  /// No description provided for @labErrorUnknownDiscriminant.
  ///
  /// In en, this message translates to:
  /// **'Unknown discriminant'**
  String get labErrorUnknownDiscriminant;

  /// No description provided for @labErrorPartialExpression.
  ///
  /// In en, this message translates to:
  /// **'Expression partially understood'**
  String get labErrorPartialExpression;

  /// No description provided for @labErrorUnknownInput.
  ///
  /// In en, this message translates to:
  /// **'Unknown input'**
  String get labErrorUnknownInput;

  /// No description provided for @labErrorNoInputConfirmed.
  ///
  /// In en, this message translates to:
  /// **'No player input required'**
  String get labErrorNoInputConfirmed;

  /// No description provided for @labMoveNoInput.
  ///
  /// In en, this message translates to:
  /// **'This move is not triggered by a player input.'**
  String get labMoveNoInput;

  /// No description provided for @labMoveRawSource.
  ///
  /// In en, this message translates to:
  /// **'Raw source'**
  String get labMoveRawSource;

  /// No description provided for @labIrDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get labIrDirection;

  /// No description provided for @labIrButton.
  ///
  /// In en, this message translates to:
  /// **'Button'**
  String get labIrButton;

  /// No description provided for @labIrMotion.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get labIrMotion;

  /// No description provided for @labIrCharge.
  ///
  /// In en, this message translates to:
  /// **'Charge'**
  String get labIrCharge;

  /// No description provided for @labIrHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get labIrHold;

  /// No description provided for @labIrRelease.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get labIrRelease;

  /// No description provided for @labIrRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get labIrRepeat;

  /// No description provided for @labIrOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get labIrOptional;

  /// No description provided for @labIrSequence.
  ///
  /// In en, this message translates to:
  /// **'Sequence'**
  String get labIrSequence;

  /// No description provided for @labIrSimultaneous.
  ///
  /// In en, this message translates to:
  /// **'Simultaneous'**
  String get labIrSimultaneous;

  /// No description provided for @labIrAlternative.
  ///
  /// In en, this message translates to:
  /// **'Alternative'**
  String get labIrAlternative;

  /// No description provided for @labIrContextual.
  ///
  /// In en, this message translates to:
  /// **'Contextual'**
  String get labIrContextual;

  /// No description provided for @labIrFallback.
  ///
  /// In en, this message translates to:
  /// **'Fallback'**
  String get labIrFallback;

  /// No description provided for @labIrUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get labIrUnknown;

  /// No description provided for @moveCategoryNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get moveCategoryNormal;

  /// No description provided for @moveCategoryCommandNormal.
  ///
  /// In en, this message translates to:
  /// **'Command normal'**
  String get moveCategoryCommandNormal;

  /// No description provided for @moveCategoryThrow.
  ///
  /// In en, this message translates to:
  /// **'Throw'**
  String get moveCategoryThrow;

  /// No description provided for @moveCategorySpecial.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get moveCategorySpecial;

  /// No description provided for @moveCategorySuper.
  ///
  /// In en, this message translates to:
  /// **'Super'**
  String get moveCategorySuper;

  /// No description provided for @moveCategoryDesperation.
  ///
  /// In en, this message translates to:
  /// **'Desperation move'**
  String get moveCategoryDesperation;

  /// No description provided for @moveCategorySuperDesperation.
  ///
  /// In en, this message translates to:
  /// **'Super desperation move'**
  String get moveCategorySuperDesperation;

  /// No description provided for @moveCategoryClimax.
  ///
  /// In en, this message translates to:
  /// **'Climax'**
  String get moveCategoryClimax;

  /// No description provided for @moveCategoryMovement.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get moveCategoryMovement;

  /// No description provided for @moveCategorySystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get moveCategorySystem;

  /// No description provided for @moveCategoryCheat.
  ///
  /// In en, this message translates to:
  /// **'Cheat'**
  String get moveCategoryCheat;

  /// No description provided for @moveCategoryInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get moveCategoryInfo;

  /// No description provided for @moveCategoryUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown category'**
  String get moveCategoryUnknown;

  /// No description provided for @moveReqSpatialNearOpponent.
  ///
  /// In en, this message translates to:
  /// **'Close to the opponent'**
  String get moveReqSpatialNearOpponent;

  /// No description provided for @moveReqSpatialNearWall.
  ///
  /// In en, this message translates to:
  /// **'Near a wall'**
  String get moveReqSpatialNearWall;

  /// No description provided for @moveReqSpatialFarOpponent.
  ///
  /// In en, this message translates to:
  /// **'Far from the opponent'**
  String get moveReqSpatialFarOpponent;

  /// No description provided for @moveReqStateAirborne.
  ///
  /// In en, this message translates to:
  /// **'In the air'**
  String get moveReqStateAirborne;

  /// No description provided for @moveReqStateOnGround.
  ///
  /// In en, this message translates to:
  /// **'On the ground'**
  String get moveReqStateOnGround;

  /// No description provided for @moveReqStateCrouching.
  ///
  /// In en, this message translates to:
  /// **'While crouching'**
  String get moveReqStateCrouching;

  /// No description provided for @moveReqStateStanding.
  ///
  /// In en, this message translates to:
  /// **'While standing'**
  String get moveReqStateStanding;

  /// No description provided for @moveReqPhaseKnockdown.
  ///
  /// In en, this message translates to:
  /// **'After a knockdown'**
  String get moveReqPhaseKnockdown;

  /// No description provided for @moveReqPhaseWakeup.
  ///
  /// In en, this message translates to:
  /// **'On wake-up'**
  String get moveReqPhaseWakeup;

  /// No description provided for @moveReqStanceEx.
  ///
  /// In en, this message translates to:
  /// **'EX stance'**
  String get moveReqStanceEx;

  /// No description provided for @moveReqUnknown.
  ///
  /// In en, this message translates to:
  /// **'Requirement: {raw}'**
  String moveReqUnknown(String raw);

  /// No description provided for @commandSepThen.
  ///
  /// In en, this message translates to:
  /// **'then'**
  String get commandSepThen;

  /// No description provided for @commandSepOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get commandSepOr;

  /// No description provided for @commandSepAnd.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get commandSepAnd;

  /// No description provided for @commandHoldOpen.
  ///
  /// In en, this message translates to:
  /// **'hold'**
  String get commandHoldOpen;

  /// No description provided for @commandReleaseOpen.
  ///
  /// In en, this message translates to:
  /// **'release'**
  String get commandReleaseOpen;

  /// No description provided for @commandOptionalOpen.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get commandOptionalOpen;

  /// No description provided for @commandRepeatRapidly.
  ///
  /// In en, this message translates to:
  /// **'repeatedly'**
  String get commandRepeatRapidly;

  /// No description provided for @commandRepeatCount.
  ///
  /// In en, this message translates to:
  /// **'×{count}'**
  String commandRepeatCount(int count);

  /// No description provided for @commandNoInputNeeded.
  ///
  /// In en, this message translates to:
  /// **'No player input required'**
  String get commandNoInputNeeded;

  /// No description provided for @commandUnknownInput.
  ///
  /// In en, this message translates to:
  /// **'Unknown command'**
  String get commandUnknownInput;

  /// No description provided for @commandFallbackHint.
  ///
  /// In en, this message translates to:
  /// **'Verbatim source (unparsed)'**
  String get commandFallbackHint;

  /// No description provided for @labComparisonTitle.
  ///
  /// In en, this message translates to:
  /// **'Notation comparison'**
  String get labComparisonTitle;

  /// No description provided for @labComparisonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Same move rendered in every notation.'**
  String get labComparisonSubtitle;

  /// No description provided for @labComparisonCasePictograms.
  ///
  /// In en, this message translates to:
  /// **'Pictograms'**
  String get labComparisonCasePictograms;

  /// No description provided for @labComparisonCaseNumpad.
  ///
  /// In en, this message translates to:
  /// **'Numpad'**
  String get labComparisonCaseNumpad;

  /// No description provided for @labComparisonCaseClassic.
  ///
  /// In en, this message translates to:
  /// **'2D classic'**
  String get labComparisonCaseClassic;

  /// No description provided for @labComparisonCaseAccessible.
  ///
  /// In en, this message translates to:
  /// **'Accessible text'**
  String get labComparisonCaseAccessible;

  /// No description provided for @labComparisonCaseSemantic.
  ///
  /// In en, this message translates to:
  /// **'Semantic label'**
  String get labComparisonCaseSemantic;

  /// No description provided for @labVisualReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Visual review'**
  String get labVisualReviewTitle;

  /// No description provided for @labVisualReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Curated hard cases. Change notation, theme, density, language and text size to inspect them.'**
  String get labVisualReviewSubtitle;

  /// No description provided for @labTechnicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get labTechnicalDetails;

  /// No description provided for @labMoveCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get labMoveCategoryLabel;

  /// No description provided for @labMoveRequirementLabel.
  ///
  /// In en, this message translates to:
  /// **'Only when'**
  String get labMoveRequirementLabel;

  /// No description provided for @labProvenanceVerbatim.
  ///
  /// In en, this message translates to:
  /// **'Verbatim attribution text'**
  String get labProvenanceVerbatim;

  /// No description provided for @labProvenanceStructured.
  ///
  /// In en, this message translates to:
  /// **'Structured fields'**
  String get labProvenanceStructured;

  /// No description provided for @labProvenanceComposedCredit.
  ///
  /// In en, this message translates to:
  /// **'{source} — {license}'**
  String labProvenanceComposedCredit(String source, String license);

  /// No description provided for @goldMoveListTitle.
  ///
  /// In en, this message translates to:
  /// **'Move List'**
  String get goldMoveListTitle;

  /// No description provided for @goldProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Gold profile'**
  String get goldProfileLabel;

  /// No description provided for @goldCharactersMoves.
  ///
  /// In en, this message translates to:
  /// **'{characters} characters · {moves} moves'**
  String goldCharactersMoves(int characters, int moves);

  /// No description provided for @goldSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by move, alias or character'**
  String get goldSearchHint;

  /// No description provided for @goldNotation.
  ///
  /// In en, this message translates to:
  /// **'Notation'**
  String get goldNotation;

  /// No description provided for @goldDensity.
  ///
  /// In en, this message translates to:
  /// **'Density'**
  String get goldDensity;

  /// No description provided for @goldPictograms.
  ///
  /// In en, this message translates to:
  /// **'ComboFox pictograms'**
  String get goldPictograms;

  /// No description provided for @goldNumpad.
  ///
  /// In en, this message translates to:
  /// **'Numpad'**
  String get goldNumpad;

  /// No description provided for @goldClassic2d.
  ///
  /// In en, this message translates to:
  /// **'2D classic'**
  String get goldClassic2d;

  /// No description provided for @goldAccessible.
  ///
  /// In en, this message translates to:
  /// **'Accessible text'**
  String get goldAccessible;

  /// No description provided for @goldCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get goldCompact;

  /// No description provided for @goldComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get goldComfortable;

  /// No description provided for @goldLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading move list…'**
  String get goldLoading;

  /// No description provided for @goldLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this move list.'**
  String get goldLoadError;

  /// No description provided for @goldLoadOffline.
  ///
  /// In en, this message translates to:
  /// **'This move list is unavailable offline. Check your connection and try again.'**
  String get goldLoadOffline;

  /// No description provided for @goldLoadUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This move list needs a newer version of the app.'**
  String get goldLoadUnsupported;

  /// No description provided for @goldRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get goldRetry;

  /// No description provided for @goldNoResults.
  ///
  /// In en, this message translates to:
  /// **'No moves found.'**
  String get goldNoResults;

  /// No description provided for @goldMovesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} moves'**
  String goldMovesCount(int count);

  /// No description provided for @goldBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark character'**
  String get goldBookmark;

  /// No description provided for @goldRemoveBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get goldRemoveBookmark;

  /// No description provided for @goldSignInBookmark.
  ///
  /// In en, this message translates to:
  /// **'Sign in to bookmark characters'**
  String get goldSignInBookmark;

  /// No description provided for @goldSourcesAttribution.
  ///
  /// In en, this message translates to:
  /// **'Sources & attribution'**
  String get goldSourcesAttribution;

  /// No description provided for @goldOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Open source'**
  String get goldOpenSource;

  /// No description provided for @goldAttributionText.
  ///
  /// In en, this message translates to:
  /// **'Attribution text'**
  String get goldAttributionText;

  /// No description provided for @goldCharacterMissing.
  ///
  /// In en, this message translates to:
  /// **'This character is no longer available in the move list.'**
  String get goldCharacterMissing;

  /// No description provided for @goldDisplayPreferences.
  ///
  /// In en, this message translates to:
  /// **'Move-list display'**
  String get goldDisplayPreferences;

  /// No description provided for @goldDisplayPreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notation and density'**
  String get goldDisplayPreferencesSubtitle;

  /// No description provided for @goldNotationPictogramsHelp.
  ///
  /// In en, this message translates to:
  /// **'Visual arrows and button symbols. Best when you want to read commands at a glance.'**
  String get goldNotationPictogramsHelp;

  /// No description provided for @goldNotationNumpadHelp.
  ///
  /// In en, this message translates to:
  /// **'Uses keyboard directions: 2 = down, 3 = down-forward, 6 = forward. The example is 236 P.'**
  String get goldNotationNumpadHelp;

  /// No description provided for @goldNotationClassicHelp.
  ///
  /// In en, this message translates to:
  /// **'Uses fighting-game shorthand: QCF means quarter-circle forward. The example is QCF + P.'**
  String get goldNotationClassicHelp;

  /// No description provided for @goldNotationAccessibleHelp.
  ///
  /// In en, this message translates to:
  /// **'Writes the command as a complete sentence, designed for screen readers and plain-language reading.'**
  String get goldNotationAccessibleHelp;

  /// No description provided for @goldDensityHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose how much context appears on each move.'**
  String get goldDensityHelp;

  /// No description provided for @goldCompactHelp.
  ///
  /// In en, this message translates to:
  /// **'A concise layout for scanning many moves quickly.'**
  String get goldCompactHelp;

  /// No description provided for @goldComfortableHelp.
  ///
  /// In en, this message translates to:
  /// **'More spacing plus requirements and annotations when they are available.'**
  String get goldComfortableHelp;

  /// No description provided for @goldAccessibleExample.
  ///
  /// In en, this message translates to:
  /// **'Quarter-circle forward, then Punch'**
  String get goldAccessibleExample;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
