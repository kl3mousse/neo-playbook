import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_helpers.dart';

/// A special DIP setting (time/count value, not selectable).
class DipSpecialSetting {
  final String description;
  final String value;

  const DipSpecialSetting({required this.description, required this.value});

  factory DipSpecialSetting.fromMap(Map<String, dynamic> map) {
    return DipSpecialSetting(
      description: map['description'] as String? ?? '',
      value: map['value']?.toString() ?? '',
    );
  }
}

/// A simple DIP setting with selectable options and a default.
class DipSimpleSetting {
  final String description;
  final int defaultValue;
  final List<String> valueDescriptions;

  const DipSimpleSetting({
    required this.description,
    required this.defaultValue,
    required this.valueDescriptions,
  });

  factory DipSimpleSetting.fromMap(Map<String, dynamic> map) {
    return DipSimpleSetting(
      description: map['description'] as String? ?? '',
      defaultValue: map['default_value'] as int? ?? 0,
      valueDescriptions: (map['value_descriptions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// DIP settings for a specific region (EU, US, JP).
class RegionDipSettings {
  final String gameName;
  final List<DipSpecialSetting> specialSettings;
  final List<DipSimpleSetting> simpleSettings;

  const RegionDipSettings({
    required this.gameName,
    required this.specialSettings,
    required this.simpleSettings,
  });

  factory RegionDipSettings.fromMap(Map<String, dynamic> map) {
    return RegionDipSettings(
      gameName: map['game_name'] as String? ?? '',
      specialSettings: (map['special_settings'] as List<dynamic>?)
              ?.map((e) =>
                  DipSpecialSetting.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      simpleSettings: (map['simple_settings'] as List<dynamic>?)
              ?.map((e) =>
                  DipSimpleSetting.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  bool get isEmpty => specialSettings.isEmpty && simpleSettings.isEmpty;
}

/// A single debug DIP switch effect.
class DebugSwitch {
  final int switchNumber;
  final String effect;

  const DebugSwitch({required this.switchNumber, required this.effect});

  factory DebugSwitch.fromMap(Map<String, dynamic> map) {
    return DebugSwitch(
      switchNumber: map['switch'] as int? ?? 0,
      effect: map['effect'] as String? ?? '',
    );
  }
}

/// Full DIP settings document from Firestore.
class DipSettingsData {
  final String id;
  final String? gameId;
  final Map<String, RegionDipSettings> regions;
  final Map<String, List<DebugSwitch>> debugDips;
  final Timestamp? syncedAt;

  const DipSettingsData({
    required this.id,
    this.gameId,
    required this.regions,
    required this.debugDips,
    this.syncedAt,
  });

  factory DipSettingsData.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // Parse regions
    final regionsRaw = data['regions'] as Map<String, dynamic>? ?? {};
    final regions = regionsRaw.map((key, value) => MapEntry(
          key,
          RegionDipSettings.fromMap(Map<String, dynamic>.from(value)),
        ));

    // Parse debug DIPs (bank → array of DebugSwitch)
    final debugRaw = data['debug_dips'] as Map<String, dynamic>? ?? {};
    final debugDips = debugRaw.map((bankKey, bankValue) => MapEntry(
          bankKey,
          (bankValue as List<dynamic>)
              .map((e) => DebugSwitch.fromMap(Map<String, dynamic>.from(e)))
              .toList(),
        ));

    return DipSettingsData(
      id: doc.id,
      gameId: data['game_id'] as String?,
      regions: regions,
      debugDips: debugDips,
      syncedAt: parseTimestamp(data['synced_at']),
    );
  }

  bool get hasDebugDips => debugDips.values.any((g) => g.isNotEmpty);
}
