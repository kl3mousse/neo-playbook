import '../../domain/expression.dart';
import '../../domain/move.dart';
import '../render_tokens.dart';

/// Numpad notation renderer (e.g. `236 A`, `[2]~8 P (hold)`).
///
/// See CONSUMER_SPEC.md §9.1 and `rendering-samples.json`.
class NumpadRenderer {
  /// Render the first structured input expression of [move] as a
  /// numpad string. Returns `null` when the move has no structured
  /// input (e.g. `automatic_after_move`).
  String? render(MoveGold move) {
    if (move.inputExpressions.isEmpty) return null;
    final w = move.inputExpressions.first;
    final expr = w.expression;
    if (expr == null) return w.sourceRaw;
    return _renderExpression(expr);
  }

  String _renderExpression(Expression e) =>
      _stringifyTokens(buildRenderTokens(e));

  String _stringifyTokens(List<RenderToken> tokens) {
    final buf = StringBuffer();
    _TokenCategory? prev;
    for (final t in tokens) {
      final piece = _tokenPiece(t);
      if (piece == null) continue;
      final (str, cat) = piece;
      if (buf.isNotEmpty && _needsSpace(prev, cat)) {
        buf.write(' ');
      }
      buf.write(str);
      prev = cat;
    }
    return buf.toString();
  }

  bool _needsSpace(_TokenCategory? prev, _TokenCategory cur) {
    if (prev == null) return false;
    if (prev == _TokenCategory.chargeHead) return false;
    if (prev == _TokenCategory.simSep) return false;
    if (cur == _TokenCategory.simSep) return false;
    if (prev == _TokenCategory.groupOpen) return false;
    if (cur == _TokenCategory.groupClose) return false;
    return true;
  }

  (String, _TokenCategory)? _tokenPiece(RenderToken t) {
    switch (t) {
      case RtMotion(:final shape):
        return (_motionNumpad(shape), _TokenCategory.motion);
      case RtDirection(:final value):
        return (_directionNumpad(value), _TokenCategory.direction);
      case RtButton(:final symbol):
        return (symbol, _TokenCategory.button);
      case RtNeutral():
        return ('5', _TokenCategory.direction);
      case RtCharge(:final chargeDirection):
        return (
          '[${_directionNumpad(chargeDirection)}]~',
          _TokenCategory.chargeHead,
        );
      case RtHoldStart():
        return null;
      case RtHoldEnd():
        return ('(hold)', _TokenCategory.suffix);
      case RtReleaseStart():
        return null;
      case RtReleaseEnd():
        return ('(release)', _TokenCategory.suffix);
      case RtOptionalStart():
        return ('(', _TokenCategory.groupOpen);
      case RtOptionalEnd():
        return (')?', _TokenCategory.groupClose);
      case RtRepeatStart(:final count):
        return (count == null ? 'xN(' : '×$count(', _TokenCategory.groupOpen);
      case RtRepeatEnd():
        return (')', _TokenCategory.groupClose);
      case RtSimultaneousStart():
        return null;
      case RtSimultaneousEnd():
        return null;
      case RtSimultaneousSeparator():
        return ('+', _TokenCategory.simSep);
      case RtFallback(:final sourceRaw):
        return ('«$sourceRaw»', _TokenCategory.button);
      case RtUnknown():
        return ('?', _TokenCategory.button);
      case RtAlternative(:final options):
        final parts = <String>[];
        for (final o in options) {
          parts.add(_stringifyTokens(o).trim());
        }
        return (parts.join(' | '), _TokenCategory.button);
      case RtContextualHint():
        return null;
    }
  }

  String _motionNumpad(String shape) {
    return switch (shape) {
      'quarter_circle_forward' => '236',
      'quarter_circle_back' => '214',
      'half_circle_forward' => '41236',
      'half_circle_back' => '63214',
      'dragon_punch_forward' => '623',
      'dragon_punch_back' => '421',
      'reverse_dragon_punch_forward' => '632',
      'reverse_dragon_punch_back' => '412',
      'full_circle' => '360',
      'double_quarter_circle_forward' => '236236',
      'double_quarter_circle_back' => '214214',
      'pretzel_forward' => 'pretzel(f)',
      'pretzel_back' => 'pretzel(b)',
      _ => shape,
    };
  }

  String _directionNumpad(String d) {
    return switch (d) {
      'neutral' => '5',
      'forward' => '6',
      'back' => '4',
      'up' => '8',
      'down' => '2',
      'up_forward' => '9',
      'up_back' => '7',
      'down_forward' => '3',
      'down_back' => '1',
      'any' => '*',
      _ => d,
    };
  }
}

enum _TokenCategory {
  motion,
  direction,
  button,
  chargeHead,
  suffix,
  groupOpen,
  groupClose,
  simSep,
}
