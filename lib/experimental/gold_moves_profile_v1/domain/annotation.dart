import 'package:meta/meta.dart';

/// Discriminator for [Annotation]. Unknown wire values become
/// [AnnotationKind.unknown] per CONSUMER_SPEC §8.4.
enum AnnotationKind {
  hitProperty('hit_property'),
  damageModifier('damage_modifier'),
  stockCost('stock_cost'),
  guardProperty('guard_property'),
  positioning('positioning'),
  custom('custom'),
  unknown('unknown');

  final String wire;
  const AnnotationKind(this.wire);

  static AnnotationKind fromWire(String? value) {
    for (final k in AnnotationKind.values) {
      if (k.wire == value) return k;
    }
    return AnnotationKind.unknown;
  }
}

@immutable
class Annotation {
  final AnnotationKind kind;

  /// Original wire kind string; preserved for round-tripping unknowns.
  final String rawKind;

  /// Free-form value (any JSON scalar/array/object).
  final Object? value;
  final String? description;

  const Annotation({
    required this.kind,
    required this.rawKind,
    this.value,
    this.description,
  });
}
