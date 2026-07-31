// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get settingsDevSectionTitle => 'Outils de développement';

  @override
  String get settingsGoldLabTitle => 'Laboratoire des commandes Gold';

  @override
  String get settingsGoldLabSubtitle =>
      'Aperçu expérimental du profil Gold Moves';

  @override
  String get labTitle => 'Laboratoire des commandes Gold';

  @override
  String get labTabCharacters => 'Personnages';

  @override
  String get labTabGallery => 'Galerie';

  @override
  String get labTabProvenance => 'Sources';

  @override
  String get labTabDiagnostics => 'Diagnostic';

  @override
  String get labLoading => 'Chargement du profil…';

  @override
  String get labLoadErrorTitle => 'Impossible de charger le profil Gold';

  @override
  String get labLoadErrorHint =>
      'Vérifie que la fixture livrée est bien présente et valide.';

  @override
  String get labRetry => 'Réessayer';

  @override
  String get labHeaderGame => 'Jeu';

  @override
  String get labHeaderGoldVersion => 'Contrat Gold';

  @override
  String get labHeaderCharacters => 'Personnages';

  @override
  String get labHeaderMoves => 'Moves';

  @override
  String get labHeaderAutomatic => 'Activations automatiques';

  @override
  String get labHeaderSource => 'Source principale';

  @override
  String get labSearchHint => 'Rechercher un move par nom';

  @override
  String get labSearchClear => 'Effacer';

  @override
  String labResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coups',
      one: '1 coup',
      zero: 'Aucun coup',
    );
    return '$_temp0';
  }

  @override
  String get labEmptyStateTitle => 'Aucun résultat';

  @override
  String get labEmptyStateHint => 'Efface le filtre ou essaie un autre terme.';

  @override
  String get labSelectCharacter =>
      'Sélectionne un personnage à gauche pour voir ses moves.';

  @override
  String get labFilterAllMoves => 'Tous les moves';

  @override
  String get labFilterAutomatic => 'Activations automatiques';

  @override
  String get labFilterGroupByCategory => 'Grouper par catégorie';

  @override
  String get labSettingsTitle => 'Options de rendu';

  @override
  String get labSectionNotation => 'Notation';

  @override
  String get labNotationPictograms => 'Pictogrammes ComboFox';

  @override
  String get labNotationNumpad => 'Numpad';

  @override
  String get labNotationClassic2d => '2D classique';

  @override
  String get labNotationAccessible => 'Texte accessible';

  @override
  String get labSectionAccessibleLocale => 'Langue du texte accessible';

  @override
  String get labLocaleEn => 'Anglais';

  @override
  String get labLocaleFr => 'Français';

  @override
  String get labSectionTheme => 'Thème';

  @override
  String get labThemeDark => 'Sombre';

  @override
  String get labThemeLight => 'Clair';

  @override
  String get labThemeSystem => 'Système';

  @override
  String get labSectionDensity => 'Densité';

  @override
  String get labDensityComfortable => 'Confortable';

  @override
  String get labDensityCompact => 'Compacte';

  @override
  String get labSectionTextScale => 'Taille du texte (simulée)';

  @override
  String get labTextScaleHint =>
      'N’affecte que le Laboratoire, pas tes préférences globales.';

  @override
  String labTextScalePercent(int percent) {
    return '$percent %';
  }

  @override
  String get labGalleryTitle => 'Galerie des composants';

  @override
  String get labGallerySubtitle =>
      'Types d’expressions Gold représentatifs. Les cas synthétiques sont clairement étiquetés.';

  @override
  String get labGallerySynthetic => 'Exemple de démonstration';

  @override
  String get labGalleryFromProfile => 'Extrait du profil KOF R-2';

  @override
  String get labGalleryShowTokens => 'Afficher les tokens et les données';

  @override
  String get labGalleryHideTokens => 'Masquer les tokens et les données';

  @override
  String get labCaseSimpleCommand => 'Commande simple';

  @override
  String get labCaseQuarterCircle => 'Quart de cercle';

  @override
  String get labCaseDragonPunch => 'Dragon punch';

  @override
  String get labCaseCharge => 'Charge';

  @override
  String get labCaseSequence => 'Séquence composée';

  @override
  String get labCaseSimultaneous => 'Simultanéité';

  @override
  String get labCaseHold => 'Maintenir';

  @override
  String get labCaseRelease => 'Relâcher';

  @override
  String get labCaseAlternative => 'Alternative';

  @override
  String get labCaseContextual => 'Contextuel';

  @override
  String get labCaseRequirement => 'Contrainte';

  @override
  String get labCaseAnnotation => 'Annotation';

  @override
  String get labCaseLongCommand => 'Commande longue';

  @override
  String get labCaseAutomatic => 'Activation automatique';

  @override
  String get labCaseFallback => 'Repli (brut)';

  @override
  String get labCaseUnknown => 'Input inconnu';

  @override
  String get labAutomaticBadge => 'Automatique';

  @override
  String get labAutomaticExplanation =>
      'Se déclenche automatiquement. Le joueur n’a rien à saisir.';

  @override
  String labAutomaticFollowUpOf(String name) {
    return 'Suite du move « $name »';
  }

  @override
  String get labAutomaticJumpToParent => 'Voir le move précédent';

  @override
  String get labProvenanceTitle => 'Sources et attribution';

  @override
  String get labProvenanceLicense => 'Licence';

  @override
  String get labProvenanceRole => 'Rôle';

  @override
  String get labProvenanceVersion => 'Version';

  @override
  String get labProvenanceUrl => 'URL';

  @override
  String get labProvenanceOpenUrl => 'Ouvrir l’URL de la source';

  @override
  String get labProvenanceAdditional => 'Sources additionnelles';

  @override
  String get labProvenanceAttribution => 'Texte d’attribution';

  @override
  String get labDiagnosticsTitle => 'Données techniques';

  @override
  String get labDiagnosticsProfileVersion => 'Version du profil';

  @override
  String get labDiagnosticsRendererVersion => 'Version du renderer';

  @override
  String get labDiagnosticsCharactersCount => 'Personnages chargés';

  @override
  String get labDiagnosticsMovesCount => 'Moves chargés';

  @override
  String get labDiagnosticsByActivation => 'Moves par activation';

  @override
  String get labDiagnosticsNotationFrame => 'Notation frame';

  @override
  String get labDiagnosticsSelectedCharacter => 'Personnage sélectionné';

  @override
  String get labDiagnosticsSelectedMove => 'Move sélectionné';

  @override
  String get labDiagnosticsSourceRaw => 'source_raw';

  @override
  String get labDiagnosticsTokens => 'Tokens de rendu';

  @override
  String get labDiagnosticsParseStatus => 'Statut de parsing';

  @override
  String get labDiagnosticsRelatedMoves => 'Moves associés';

  @override
  String get labDiagnosticsCopy => 'Copier';

  @override
  String get labDiagnosticsCopied => 'Copié dans le presse-papiers';

  @override
  String get labErrorMoveTitle => 'Impossible d’afficher ce move';

  @override
  String get labErrorMoveHint => 'Les autres moves restent consultables.';

  @override
  String get labErrorUnsupportedGoldVersion => 'Version Gold non supportée';

  @override
  String get labErrorInvalidReference => 'Référence de move invalide';

  @override
  String get labErrorUnknownDiscriminant => 'Discriminant inconnu';

  @override
  String get labErrorPartialExpression => 'Expression partiellement comprise';

  @override
  String get labErrorUnknownInput => 'Input inconnu';

  @override
  String get labErrorNoInputConfirmed => 'Aucune saisie nécessaire';

  @override
  String get labMoveNoInput =>
      'Ce move n’est pas déclenché par une saisie joueur.';

  @override
  String get labMoveRawSource => 'Source brute';

  @override
  String get labIrDirection => 'Direction';

  @override
  String get labIrButton => 'Bouton';

  @override
  String get labIrMotion => 'Motion';

  @override
  String get labIrCharge => 'Charge';

  @override
  String get labIrHold => 'Maintenir';

  @override
  String get labIrRelease => 'Relâcher';

  @override
  String get labIrRepeat => 'Répéter';

  @override
  String get labIrOptional => 'Optionnel';

  @override
  String get labIrSequence => 'Séquence';

  @override
  String get labIrSimultaneous => 'Simultanéité';

  @override
  String get labIrAlternative => 'Alternative';

  @override
  String get labIrContextual => 'Contextuel';

  @override
  String get labIrFallback => 'Repli';

  @override
  String get labIrUnknown => 'Inconnu';

  @override
  String get moveCategoryNormal => 'Coup normal';

  @override
  String get moveCategoryCommandNormal => 'Coup normal spécial';

  @override
  String get moveCategoryThrow => 'Projection';

  @override
  String get moveCategorySpecial => 'Coup spécial';

  @override
  String get moveCategorySuper => 'Super coup';

  @override
  String get moveCategoryDesperation => 'Coup désespéré';

  @override
  String get moveCategorySuperDesperation => 'Super coup désespéré';

  @override
  String get moveCategoryClimax => 'Climax';

  @override
  String get moveCategoryMovement => 'Déplacement';

  @override
  String get moveCategorySystem => 'Système';

  @override
  String get moveCategoryCheat => 'Triche';

  @override
  String get moveCategoryInfo => 'Info';

  @override
  String get moveCategoryUnknown => 'Catégorie inconnue';

  @override
  String get moveReqSpatialNearOpponent => 'Près de l’adversaire';

  @override
  String get moveReqSpatialNearWall => 'Près d’un mur';

  @override
  String get moveReqSpatialFarOpponent => 'Loin de l’adversaire';

  @override
  String get moveReqStateAirborne => 'En l’air';

  @override
  String get moveReqStateOnGround => 'Au sol';

  @override
  String get moveReqStateCrouching => 'Accroupi';

  @override
  String get moveReqStateStanding => 'Debout';

  @override
  String get moveReqPhaseKnockdown => 'Après un knockdown';

  @override
  String get moveReqPhaseWakeup => 'Au réveil';

  @override
  String get moveReqStanceEx => 'Posture EX';

  @override
  String moveReqUnknown(String raw) {
    return 'Condition : $raw';
  }

  @override
  String get commandSepThen => 'puis';

  @override
  String get commandSepOr => 'ou';

  @override
  String get commandSepAnd => 'et';

  @override
  String get commandHoldOpen => 'maintenir';

  @override
  String get commandReleaseOpen => 'relâcher';

  @override
  String get commandOptionalOpen => 'optionnel';

  @override
  String get commandRepeatRapidly => 'répété';

  @override
  String commandRepeatCount(int count) {
    return '×$count';
  }

  @override
  String get commandNoInputNeeded => 'Aucune saisie nécessaire';

  @override
  String get commandUnknownInput => 'Commande inconnue';

  @override
  String get commandFallbackHint => 'Source verbatim (non analysée)';

  @override
  String get labComparisonTitle => 'Comparaison des notations';

  @override
  String get labComparisonSubtitle => 'Le même move dans les quatre notations.';

  @override
  String get labComparisonCasePictograms => 'Pictogrammes';

  @override
  String get labComparisonCaseNumpad => 'Numpad';

  @override
  String get labComparisonCaseClassic => '2D classique';

  @override
  String get labComparisonCaseAccessible => 'Texte accessible';

  @override
  String get labComparisonCaseSemantic => 'Étiquette sémantique';

  @override
  String get labVisualReviewTitle => 'Revue visuelle';

  @override
  String get labVisualReviewSubtitle =>
      'Cas difficiles sélectionnés. Change notation, thème, densité, langue et taille du texte pour les inspecter.';

  @override
  String get labTechnicalDetails => 'Données techniques';

  @override
  String get labMoveCategoryLabel => 'Catégorie';

  @override
  String get labMoveRequirementLabel => 'Uniquement si';

  @override
  String get labProvenanceVerbatim => 'Texte d’attribution verbatim';

  @override
  String get labProvenanceStructured => 'Champs structurés';

  @override
  String labProvenanceComposedCredit(String source, String license) {
    return '$source — $license';
  }

  @override
  String get goldMoveListTitle => 'Liste des coups';

  @override
  String get goldProfileLabel => 'Profil Gold';

  @override
  String goldCharactersMoves(int characters, int moves) {
    return '$characters personnages · $moves moves';
  }

  @override
  String get goldSearchHint => 'Rechercher par move, alias ou personnage';

  @override
  String get goldNotation => 'Notation';

  @override
  String get goldDensity => 'Densité';

  @override
  String get goldPictograms => 'Pictogrammes ComboFox';

  @override
  String get goldNumpad => 'Numpad';

  @override
  String get goldClassic2d => '2D classique';

  @override
  String get goldAccessible => 'Texte accessible';

  @override
  String get goldCompact => 'Compacte';

  @override
  String get goldComfortable => 'Confortable';

  @override
  String get goldLoading => 'Chargement de la liste des coups…';

  @override
  String get goldLoadError => 'Impossible de charger cette liste de coups.';

  @override
  String get goldRetry => 'Réessayer';

  @override
  String get goldNoResults => 'Aucun move trouvé.';

  @override
  String goldMovesCount(int count) {
    return '$count moves';
  }

  @override
  String get goldBookmark => 'Ajouter le personnage aux favoris';

  @override
  String get goldRemoveBookmark => 'Retirer le personnage des favoris';

  @override
  String get goldSignInBookmark =>
      'Connectez-vous pour ajouter des personnages aux favoris';

  @override
  String get goldSourcesAttribution => 'Sources et attribution';

  @override
  String get goldOpenSource => 'Ouvrir la source';

  @override
  String get goldAttributionText => 'Texte d’attribution';

  @override
  String get goldCharacterMissing =>
      'Ce personnage n’est plus disponible dans la liste des coups.';
}
