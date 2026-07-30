import 'package:meta/meta.dart';

/// A single source cited by a profile.
@immutable
class Source {
  final String name;
  final String? url;
  final String? version;
  final String? license;
  final String? notes;

  const Source({
    required this.name,
    this.url,
    this.version,
    this.license,
    this.notes,
  });
}

/// Role of an additional source. Unknown wire values become
/// [AdditionalSourceRole.unknown].
enum AdditionalSourceRole {
  secondaryFacts('secondary_facts'),
  contextOnly('context_only'),
  metadata('metadata'),
  unknown('unknown');

  final String wire;
  const AdditionalSourceRole(this.wire);

  static AdditionalSourceRole fromWire(String? value) {
    for (final r in AdditionalSourceRole.values) {
      if (r.wire == value) return r;
    }
    return AdditionalSourceRole.unknown;
  }
}

@immutable
class AdditionalSource {
  final String name;
  final String? url;
  final AdditionalSourceRole role;
  final String rawRole;
  final String? notes;

  const AdditionalSource({
    required this.name,
    required this.role,
    required this.rawRole,
    this.url,
    this.notes,
  });
}

/// A profile's attribution block. `displayText` is the license credit
/// and MUST be rendered verbatim (CONSUMER_SPEC §5).
@immutable
class Attribution {
  final Source primarySource;
  final List<AdditionalSource> additionalSources;
  final String displayText;

  const Attribution({
    required this.primarySource,
    required this.additionalSources,
    required this.displayText,
  });
}
