/// The directional frame of reference declared by a profile.
///
/// Consumers MUST honour this when rendering directions (see
/// CONSUMER_SPEC.md §4). Unknown values MUST be treated as
/// [NotationFrame.playerRelative].
enum NotationFrame {
  /// `forward`/`back` are player-relative; mirror when facing left.
  playerRelative('player_relative'),

  /// Directions are absolute stick positions; no mirroring.
  stickAbsolute('stick_absolute'),

  /// Per-node `relative` boolean disambiguates each direction.
  mixedExplicit('mixed_explicit');

  final String wire;
  const NotationFrame(this.wire);

  static NotationFrame fromWire(String? value) {
    for (final f in NotationFrame.values) {
      if (f.wire == value) return f;
    }
    return NotationFrame.playerRelative;
  }
}
