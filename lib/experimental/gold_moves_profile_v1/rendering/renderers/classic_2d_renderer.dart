import '../../domain/expression.dart';
import '../../domain/move.dart';
import '../render_tokens.dart';

/// Classic 2D-notation renderer (e.g. `QCF + A`, `charge d, u + P (hold)`).
class Classic2dRenderer {
  String? render(MoveGold move) {
    if (move.inputExpressions.isEmpty) return null;
    final w = move.inputExpressions.first;
    final expr = w.expression;
    if (expr == null) return w.sourceRaw;
    return _renderExpression(expr);
  }

  String _renderExpression(Expression e) => _stringify(buildRenderTokens(e));

  String _stringify(List<RenderToken> tokens) {
    final buf = StringBuffer();
    _Cat? prev;
    for (final t in tokens) {
      final piece = _piece(t);
      if (piece == null) continue;
      final (str, cat) = piece;
      if (buf.isNotEmpty) buf.write(_sep(prev, cat));
      buf.write(str);
      prev = cat;
    }
    return buf.toString();
  }

  String _sep(_Cat? prev, _Cat cur) {
    if (prev == null) return '';
    if (cur == _Cat.suffix) return ' ';
    if (prev == _Cat.simSep || cur == _Cat.simSep) return '';
    if (cur == _Cat.groupClose) return '';
    if (prev == _Cat.groupOpen) return '';
    // action after movement -> " + "
    if (cur == _Cat.action &&
        (prev == _Cat.movement || prev == _Cat.charge || prev == _Cat.motion)) {
      return ' + ';
    }
    // movement chained after movement or charge -> ", "
    if ((cur == _Cat.movement || cur == _Cat.motion) &&
        (prev == _Cat.movement || prev == _Cat.motion || prev == _Cat.charge)) {
      return ', ';
    }
    // charge after anything else (rare in practice)
    if (cur == _Cat.charge) return ', ';
    // button after action -> " + " (multi-button)
    if (cur == _Cat.action && prev == _Cat.action) return ' + ';
    return ' ';
  }

  (String, _Cat)? _piece(RenderToken t) {
    switch (t) {
      case RtMotion(:final shape):
        return (_motionClassic(shape), _Cat.motion);
      case RtDirection(:final value):
        return (_directionClassic(value), _Cat.movement);
      case RtButton(:final symbol):
        return (symbol, _Cat.action);
      case RtNeutral():
        return ('N', _Cat.movement);
      case RtCharge(:final chargeDirection):
        return ('charge ${_directionClassic(chargeDirection)}', _Cat.charge);
      case RtHoldStart():
        return null;
      case RtHoldEnd():
        return ('(hold)', _Cat.suffix);
      case RtReleaseStart():
        return null;
      case RtReleaseEnd():
        return ('(release)', _Cat.suffix);
      case RtOptionalStart():
        return ('(', _Cat.groupOpen);
      case RtOptionalEnd():
        return (')?', _Cat.groupClose);
      case RtRepeatStart(:final count):
        return (count == null ? '(rapidly ' : '(×$count ', _Cat.groupOpen);
      case RtRepeatEnd():
        return (')', _Cat.groupClose);
      case RtSimultaneousStart():
        return null;
      case RtSimultaneousEnd():
        return null;
      case RtSimultaneousSeparator():
        return ('+', _Cat.simSep);
      case RtFallback(:final sourceRaw):
        return ('«$sourceRaw»', _Cat.action);
      case RtUnknown():
        return ('?', _Cat.action);
      case RtAlternative(:final options):
        final parts = <String>[for (final o in options) _stringify(o).trim()];
        return (parts.join(' | '), _Cat.action);
      case RtContextualHint():
        return null;
    }
  }

  String _motionClassic(String shape) {
    return switch (shape) {
      'quarter_circle_forward' => 'QCF',
      'quarter_circle_back' => 'QCB',
      'half_circle_forward' => 'HCF',
      'half_circle_back' => 'HCB',
      'dragon_punch_forward' => 'DP',
      'dragon_punch_back' => 'RDP',
      'reverse_dragon_punch_forward' => 'RDPf',
      'reverse_dragon_punch_back' => 'RDPb',
      'full_circle' => '360',
      'double_quarter_circle_forward' => 'DQCF',
      'double_quarter_circle_back' => 'DQCB',
      'pretzel_forward' => 'pretzel(f)',
      'pretzel_back' => 'pretzel(b)',
      _ => shape,
    };
  }

  String _directionClassic(String d) {
    return switch (d) {
      'neutral' => 'N',
      'forward' => 'f',
      'back' => 'b',
      'up' => 'u',
      'down' => 'd',
      'up_forward' => 'uf',
      'up_back' => 'ub',
      'down_forward' => 'df',
      'down_back' => 'db',
      'any' => '*',
      _ => d,
    };
  }
}

enum _Cat {
  motion,
  movement,
  action,
  charge,
  suffix,
  groupOpen,
  groupClose,
  simSep,
}
