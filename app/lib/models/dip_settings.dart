import 'package:cloud_firestore/cloud_firestore.dart';

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

/// Full DIP settings document from Firestore.
class DipSettingsData {
  final String id;
  final String romName;
  final Map<String, RegionDipSettings> regions;
  final Map<String, Map<String, String>> debugDips;
  final Timestamp? syncedAt;

  const DipSettingsData({
    required this.id,
    required this.romName,
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

    // Parse debug DIPs
    final debugRaw = data['debug_dips'] as Map<String, dynamic>? ?? {};
    final debugDips = debugRaw.map((groupKey, groupValue) => MapEntry(
          groupKey,
          (groupValue as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v.toString())),
        ));

    return DipSettingsData(
      id: doc.id,
      romName: data['rom_name'] as String? ?? doc.id,
      regions: regions,
      debugDips: debugDips,
      syncedAt: data['synced_at'] as Timestamp?,
    );
  }

  bool get hasDebugDips => debugDips.values.any((g) => g.isNotEmpty);
}
