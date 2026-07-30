/// The rolled-up parse status of an [InputExpressionWrapper].
///
/// See CONSUMER_SPEC.md §8.3.
enum ParseStatus {
  parsed('parsed'),
  partial('partial'),
  unparsed('unparsed');

  final String wire;
  const ParseStatus(this.wire);

  static ParseStatus fromWire(String? value) {
    for (final s in ParseStatus.values) {
      if (s.wire == value) return s;
    }
    throw ArgumentError('Unknown parse_status: $value');
  }
}
