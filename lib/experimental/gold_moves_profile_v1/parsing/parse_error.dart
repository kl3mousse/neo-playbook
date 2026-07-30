/// Structured error raised while parsing a Gold profile.
///
/// `path` is a JSON Pointer (RFC 6901) style string, e.g.
/// `/moves/12/activation/trigger/parent_move_id`.
class GoldParseException implements Exception {
  final String message;
  final String path;
  final Object? rawValue;

  GoldParseException(this.message, {this.path = '', this.rawValue});

  @override
  String toString() {
    final loc = path.isEmpty ? '(root)' : path;
    return 'GoldParseException at $loc: $message';
  }
}
