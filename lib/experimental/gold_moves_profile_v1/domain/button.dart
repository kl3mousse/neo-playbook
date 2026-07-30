import 'package:meta/meta.dart';

@immutable
class ButtonSpec {
  final String symbol;
  final String label;
  const ButtonSpec({required this.symbol, required this.label});
}

@immutable
class ButtonGroupSpec {
  final String symbol;
  final String label;
  final List<String> members;
  const ButtonGroupSpec({
    required this.symbol,
    required this.label,
    required this.members,
  });
}

/// A catalog wrapping profile buttons + button_groups. Provides O(1)
/// symbol lookup for renderers.
@immutable
class ButtonCatalog {
  final List<ButtonSpec> buttons;
  final List<ButtonGroupSpec> groups;
  final Map<String, ButtonSpec> _byButtonSymbol;
  final Map<String, ButtonGroupSpec> _byGroupSymbol;

  ButtonCatalog({required this.buttons, required this.groups})
    : _byButtonSymbol = {for (final b in buttons) b.symbol: b},
      _byGroupSymbol = {for (final g in groups) g.symbol: g};

  ButtonSpec? button(String symbol) => _byButtonSymbol[symbol];
  ButtonGroupSpec? group(String symbol) => _byGroupSymbol[symbol];

  /// Human-readable label for [symbol]. Falls back to the symbol itself
  /// when unknown (forward-compat rule).
  String labelFor(String symbol) {
    return _byButtonSymbol[symbol]?.label ??
        _byGroupSymbol[symbol]?.label ??
        symbol;
  }

  bool isGroup(String symbol) => _byGroupSymbol.containsKey(symbol);
  bool isKnown(String symbol) =>
      _byButtonSymbol.containsKey(symbol) || _byGroupSymbol.containsKey(symbol);
}
