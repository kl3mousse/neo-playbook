import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_helpers.dart';

/// Legacy "format" describing the physical media of a copy. Kept for
/// backward compatibility with existing documents and the quick-add flow.
enum ItemFormat {
  cartridge('cartridge', 'Cartridge'),
  pcb('pcb', 'PCB'),
  cd('cd', 'CD'),
  conversion('conversion', 'Conversion');

  final String value;
  final String label;
  const ItemFormat(this.value, this.label);

  static ItemFormat fromValue(String value) {
    return ItemFormat.values.firstWhere(
      (f) => f.value == value,
      orElse: () => ItemFormat.cartridge,
    );
  }
}

/// Overall condition grade. Used both for the item and per-component.
enum ItemCondition {
  mint('mint', 'Mint'),
  veryGood('very_good', 'Very Good'),
  nearMint('near_mint', 'Near Mint'),
  good('good', 'Good'),
  fair('fair', 'Fair'),
  poor('poor', 'Poor'),
  broken('broken', 'Broken');

  final String value;
  final String label;
  const ItemCondition(this.value, this.label);

  static ItemCondition fromValue(String value) {
    return ItemCondition.values.firstWhere(
      (c) => c.value == value,
      orElse: () => ItemCondition.good,
    );
  }

  static ItemCondition? fromValueOrNull(String? value) {
    if (value == null) return null;
    for (final c in ItemCondition.values) {
      if (c.value == value) return c;
    }
    return null;
  }
}

/// Whether the user owns / wants / sold this copy.
enum OwnershipStatus {
  owned('owned', 'Owned'),
  wanted('wanted', 'Wanted'),
  sold('sold', 'Sold'),
  previouslyOwned('previously_owned', 'Previously owned');

  final String value;
  final String label;
  const OwnershipStatus(this.value, this.label);

  static OwnershipStatus fromValue(String? value) {
    return OwnershipStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => OwnershipStatus.owned,
    );
  }
}

/// Who can see this collection item.
enum ItemVisibility {
  private('private', 'Private', 'Only you can see this item'),
  friends('friends', 'Friends', 'Visible to your accepted friends'),
  community('community', 'Community', 'Visible in community & public profiles');

  final String value;
  final String label;
  final String description;
  const ItemVisibility(this.value, this.label, this.description);

  static ItemVisibility fromValue(String? value) {
    return ItemVisibility.values.firstWhere(
      (v) => v.value == value,
      orElse: () => ItemVisibility.private,
    );
  }
}

/// Nature of the copy (original PCB, conversion, bootleg, etc.).
enum CopyType {
  original('original', 'Original'),
  conversion('conversion', 'Conversion'),
  bootleg('bootleg', 'Bootleg'),
  repro('repro', 'Repro'),
  multi('multi', 'Multi'),
  netboot('netboot', 'Netboot'),
  unknown('unknown', 'Unknown');

  final String value;
  final String label;
  const CopyType(this.value, this.label);

  static CopyType fromValue(String? value) {
    return CopyType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => CopyType.unknown,
    );
  }
}

/// Tested working state.
enum WorkingStatus {
  working('working', 'Working'),
  untested('untested', 'Untested'),
  partial('partial', 'Partial'),
  faulty('faulty', 'Faulty'),
  dead('dead', 'Dead');

  final String value;
  final String label;
  const WorkingStatus(this.value, this.label);

  static WorkingStatus fromValue(String? value) {
    return WorkingStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => WorkingStatus.untested,
    );
  }
}

/// How confident we are the copy is original vs bootleg.
enum AuthenticityConfidence {
  originalConfirmed('original_confirmed', 'Original confirmed'),
  likelyOriginal('likely_original', 'Likely original'),
  uncertain('uncertain', 'Uncertain'),
  likelyBootleg('likely_bootleg', 'Likely bootleg');

  final String value;
  final String label;
  const AuthenticityConfidence(this.value, this.label);

  static AuthenticityConfidence? fromValue(String? value) {
    if (value == null) return null;
    for (final c in AuthenticityConfidence.values) {
      if (c.value == value) return c;
    }
    return null;
  }
}

/// Originality of an individual component.
enum ComponentOriginality {
  original('original', 'Original'),
  repro('repro', 'Repro'),
  conversion('conversion', 'Conversion'),
  bootleg('bootleg', 'Bootleg'),
  unknown('unknown', 'Unknown');

  final String value;
  final String label;
  const ComponentOriginality(this.value, this.label);

  static ComponentOriginality? fromValue(String? value) {
    if (value == null) return null;
    for (final c in ComponentOriginality.values) {
      if (c.value == value) return c;
    }
    return null;
  }
}

/// State of one collector component (cartridge, box, manual, key chip, ...).
class ComponentState {
  final bool present;
  final ComponentOriginality? originality;
  final ItemCondition? condition;
  final String? serialNumber;
  final String? notes;
  final List<String> photoIds;

  const ComponentState({
    this.present = false,
    this.originality,
    this.condition,
    this.serialNumber,
    this.notes,
    this.photoIds = const [],
  });

  factory ComponentState.fromMap(Map<String, dynamic> map) {
    return ComponentState(
      present: map['present'] as bool? ?? false,
      originality: ComponentOriginality.fromValue(
        map['originality'] as String?,
      ),
      condition: ItemCondition.fromValueOrNull(map['condition'] as String?),
      serialNumber: map['serial_number'] as String?,
      notes: map['notes'] as String?,
      photoIds: (map['photo_ids'] as List<dynamic>? ?? const [])
          .map((v) => v.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'present': present,
    if (originality != null) 'originality': originality!.value,
    if (condition != null) 'condition': condition!.value,
    if (serialNumber != null && serialNumber!.isNotEmpty)
      'serial_number': serialNumber,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    if (photoIds.isNotEmpty) 'photo_ids': photoIds,
  };

  ComponentState copyWith({
    bool? present,
    ComponentOriginality? originality,
    ItemCondition? condition,
    String? serialNumber,
    String? notes,
    List<String>? photoIds,
    bool clearOriginality = false,
    bool clearCondition = false,
  }) {
    return ComponentState(
      present: present ?? this.present,
      originality: clearOriginality ? null : (originality ?? this.originality),
      condition: clearCondition ? null : (condition ?? this.condition),
      serialNumber: serialNumber ?? this.serialNumber,
      notes: notes ?? this.notes,
      photoIds: photoIds ?? this.photoIds,
    );
  }
}

/// A user-owned instance (copy) of a catalog game.
class CollectionItem {
  final String id;
  final String gameId;
  final String gameTitle;
  final String platform;
  final ItemFormat format;
  final ItemCondition condition;
  final String region;

  // Acquisition / value (purchase_* kept for backward compatibility).
  final double? purchasePrice;
  final String? purchaseCurrency;
  final Timestamp? purchaseDate;
  final String? acquisitionSource;
  final double? currentEstimatedValue;

  final String? notes;
  final Timestamp? addedAt;
  final List<String> imagePaths;

  // New collector fields.
  final OwnershipStatus ownershipStatus;
  final ItemVisibility visibility;
  final CopyType copyType;
  final String? language;
  final WorkingStatus workingStatus;
  final Timestamp? lastTestedAt;
  final String? storageLocation;
  final String? serialNumber;
  final AuthenticityConfidence? authenticityConfidence;
  final Map<String, ComponentState> components;
  final Map<String, dynamic> platformFields;

  // Scan / import provenance.
  final bool isUnverified;
  final String? scanJobId;
  final String? scanCandidateId;
  final double? recognitionConfidence;
  final String? importSource;
  final Timestamp? verifiedAt;

  const CollectionItem({
    required this.id,
    required this.gameId,
    required this.gameTitle,
    required this.platform,
    required this.format,
    required this.condition,
    required this.region,
    this.purchasePrice,
    this.purchaseCurrency,
    this.purchaseDate,
    this.acquisitionSource,
    this.currentEstimatedValue,
    this.notes,
    this.addedAt,
    this.imagePaths = const [],
    this.ownershipStatus = OwnershipStatus.owned,
    this.visibility = ItemVisibility.private,
    this.copyType = CopyType.unknown,
    this.language,
    this.workingStatus = WorkingStatus.untested,
    this.lastTestedAt,
    this.storageLocation,
    this.serialNumber,
    this.authenticityConfidence,
    this.components = const {},
    this.platformFields = const {},
    this.isUnverified = false,
    this.scanJobId,
    this.scanCandidateId,
    this.recognitionConfidence,
    this.importSource,
    this.verifiedAt,
  });

  /// Convenience: acquisition price/date/currency aliases.
  double? get acquisitionPrice => purchasePrice;
  String? get acquisitionCurrency => purchaseCurrency;
  Timestamp? get acquisitionDate => purchaseDate;

  /// True when this item is not linked to a catalog game (gameId is empty).
  bool get isCustomEntry => gameId.isEmpty;

  /// Human-readable platform label for off-catalog entries, stored in
  /// [platformFields] under the key `custom_platform_label`.
  String? get customPlatformLabel =>
      platformFields['custom_platform_label'] as String?;

  static Map<String, ComponentState> _parseComponents(dynamic raw) {
    if (raw is! Map) return const {};
    final result = <String, ComponentState>{};
    raw.forEach((key, value) {
      if (value is Map) {
        result[key.toString()] = ComponentState.fromMap(
          Map<String, dynamic>.from(value),
        );
      }
    });
    return result;
  }

  factory CollectionItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return CollectionItem(
      id: doc.id,
      gameId: data['game_id'] as String? ?? '',
      gameTitle: data['game_title'] as String? ?? '',
      platform: data['platform'] as String? ?? '',
      format: ItemFormat.fromValue(data['format'] as String? ?? ''),
      condition: ItemCondition.fromValue(data['condition'] as String? ?? ''),
      region: data['region'] as String? ?? '',
      purchasePrice: (data['purchase_price'] as num?)?.toDouble(),
      purchaseCurrency: data['purchase_currency'] as String?,
      purchaseDate: parseTimestamp(data['purchase_date']),
      acquisitionSource: data['acquisition_source'] as String?,
      currentEstimatedValue: (data['current_estimated_value'] as num?)
          ?.toDouble(),
      notes: data['notes'] as String?,
      addedAt: parseTimestamp(data['added_at']),
      imagePaths: (data['image_paths'] as List<dynamic>? ?? [])
          .map((v) => v.toString())
          .toList(),
      ownershipStatus: OwnershipStatus.fromValue(
        data['ownership_status'] as String?,
      ),
      visibility: ItemVisibility.fromValue(data['visibility'] as String?),
      copyType: CopyType.fromValue(data['copy_type'] as String?),
      language: data['language'] as String?,
      workingStatus: WorkingStatus.fromValue(data['working_status'] as String?),
      lastTestedAt: parseTimestamp(data['last_tested_at']),
      storageLocation: data['storage_location'] as String?,
      serialNumber: data['serial_number'] as String?,
      authenticityConfidence: AuthenticityConfidence.fromValue(
        data['authenticity_confidence'] as String?,
      ),
      components: _parseComponents(data['components']),
      platformFields:
          (data['platform_fields'] as Map<String, dynamic>?) ?? const {},
      isUnverified: data['is_unverified'] as bool? ?? false,
      scanJobId: data['scan_job_id'] as String?,
      scanCandidateId: data['scan_candidate_id'] as String?,
      recognitionConfidence: (data['recognition_confidence'] as num?)
          ?.toDouble(),
      importSource: data['import_source'] as String?,
      verifiedAt: parseTimestamp(data['verified_at']),
    );
  }

  Map<String, dynamic> _commonFields() => {
    'game_id': gameId,
    'game_title': gameTitle,
    'platform': platform,
    'format': format.value,
    'condition': condition.value,
    'region': region,
    'ownership_status': ownershipStatus.value,
    'visibility': visibility.value,
    'copy_type': copyType.value,
    'working_status': workingStatus.value,
    'components': components.map((k, v) => MapEntry(k, v.toMap())),
    'platform_fields': platformFields,
  };

  Map<String, dynamic> toFirestoreCreate() => {
    ..._commonFields(),
    if (purchasePrice != null) 'purchase_price': purchasePrice,
    if (purchaseCurrency != null) 'purchase_currency': purchaseCurrency,
    if (purchaseDate != null) 'purchase_date': purchaseDate,
    if (acquisitionSource != null) 'acquisition_source': acquisitionSource,
    if (currentEstimatedValue != null)
      'current_estimated_value': currentEstimatedValue,
    if (language != null) 'language': language,
    if (lastTestedAt != null) 'last_tested_at': lastTestedAt,
    if (storageLocation != null) 'storage_location': storageLocation,
    if (serialNumber != null) 'serial_number': serialNumber,
    if (authenticityConfidence != null)
      'authenticity_confidence': authenticityConfidence!.value,
    if (notes != null) 'notes': notes,
    if (imagePaths.isNotEmpty) 'image_paths': imagePaths,
    'is_unverified': isUnverified,
    if (scanJobId != null) 'scan_job_id': scanJobId,
    if (scanCandidateId != null) 'scan_candidate_id': scanCandidateId,
    if (recognitionConfidence != null)
      'recognition_confidence': recognitionConfidence,
    if (importSource != null) 'import_source': importSource,
    if (verifiedAt != null) 'verified_at': verifiedAt,
    'added_at': FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toFirestoreUpdate() => {
    ..._commonFields(),
    'purchase_price': purchasePrice,
    'purchase_currency': purchaseCurrency,
    'purchase_date': purchaseDate,
    'acquisition_source': acquisitionSource,
    'current_estimated_value': currentEstimatedValue,
    'language': language,
    'last_tested_at': lastTestedAt,
    'storage_location': storageLocation,
    'serial_number': serialNumber,
    'authenticity_confidence': authenticityConfidence?.value,
    'notes': notes,
    'image_paths': imagePaths,
    'is_unverified': isUnverified,
    'scan_job_id': scanJobId,
    'scan_candidate_id': scanCandidateId,
    'recognition_confidence': recognitionConfidence,
    'import_source': importSource,
    'verified_at': verifiedAt,
  };

  CollectionItem copyWith({
    String? gameId,
    String? gameTitle,
    String? platform,
    ItemFormat? format,
    ItemCondition? condition,
    String? region,
    double? purchasePrice,
    String? purchaseCurrency,
    Timestamp? purchaseDate,
    String? acquisitionSource,
    double? currentEstimatedValue,
    String? notes,
    List<String>? imagePaths,
    OwnershipStatus? ownershipStatus,
    ItemVisibility? visibility,
    CopyType? copyType,
    String? language,
    WorkingStatus? workingStatus,
    Timestamp? lastTestedAt,
    String? storageLocation,
    String? serialNumber,
    AuthenticityConfidence? authenticityConfidence,
    Map<String, ComponentState>? components,
    Map<String, dynamic>? platformFields,
    bool? isUnverified,
    Timestamp? verifiedAt,
    bool clearAuthenticity = false,
    bool clearNotes = false,
  }) {
    return CollectionItem(
      id: id,
      gameId: gameId ?? this.gameId,
      gameTitle: gameTitle ?? this.gameTitle,
      platform: platform ?? this.platform,
      format: format ?? this.format,
      condition: condition ?? this.condition,
      region: region ?? this.region,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseCurrency: purchaseCurrency ?? this.purchaseCurrency,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      acquisitionSource: acquisitionSource ?? this.acquisitionSource,
      currentEstimatedValue:
          currentEstimatedValue ?? this.currentEstimatedValue,
      notes: clearNotes ? null : (notes ?? this.notes),
      addedAt: addedAt,
      imagePaths: imagePaths ?? this.imagePaths,
      ownershipStatus: ownershipStatus ?? this.ownershipStatus,
      visibility: visibility ?? this.visibility,
      copyType: copyType ?? this.copyType,
      language: language ?? this.language,
      workingStatus: workingStatus ?? this.workingStatus,
      lastTestedAt: lastTestedAt ?? this.lastTestedAt,
      storageLocation: storageLocation ?? this.storageLocation,
      serialNumber: serialNumber ?? this.serialNumber,
      authenticityConfidence: clearAuthenticity
          ? null
          : (authenticityConfidence ?? this.authenticityConfidence),
      components: components ?? this.components,
      platformFields: platformFields ?? this.platformFields,
      isUnverified: isUnverified ?? this.isUnverified,
      scanJobId: scanJobId,
      scanCandidateId: scanCandidateId,
      recognitionConfidence: recognitionConfidence,
      importSource: importSource,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}
