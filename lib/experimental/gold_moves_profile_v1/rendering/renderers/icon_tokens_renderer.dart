import '../../domain/move.dart';
import '../render_tokens.dart';

/// Structured icon-token renderer.
///
/// Produces JSON-shaped `List<Map>` matching the reference `icon_tokens`
/// array of `rendering-samples.json`. Used both as the smoke-test
/// target and as the input for Flutter widget rendering.
class IconTokensRenderer {
  List<Map<String, Object?>>? render(MoveGold move) {
    if (move.inputExpressions.isEmpty) return null;
    final w = move.inputExpressions.first;
    final expr = w.expression;
    if (expr == null) return const [];
    return buildRenderTokens(expr).map((t) => t.toJson()).toList();
  }

  /// Direct access to the semantic token list (Flutter renderer path).
  List<RenderToken> tokens(MoveGold move) => renderTokensForMove(move);
}
