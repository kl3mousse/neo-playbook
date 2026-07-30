import '../../domain/move.dart';
import '../render_tokens.dart';

/// Screen-reader-friendly English renderer.
///
/// Produces phrases such as "quarter circle forward, then press A".
/// See CONSUMER_SPEC.md §9 accessibility rules.
class AccessibleEnRenderer {
  String? render(MoveGold move) {
    if (move.inputExpressions.isEmpty) return null;
    final w = move.inputExpressions.first;
    final expr = w.expression;
    if (expr == null) {
      final raw = w.sourceRaw ?? '';
      return raw.isEmpty ? null : 'unclear notation: $raw';
    }
    final tokens = buildRenderTokens(expr);
    // Lift trailing contextual hint to a prefix.
    RtContextualHint? tail;
    final body = <RenderToken>[];
    for (final t in tokens) {
      if (t is RtContextualHint) {
        tail = t;
      } else {
        body.add(t);
      }
    }
    final content = _renderList(body);
    if (tail != null) {
      return '${_prefix(tail)}: $content';
    }
    return content;
  }

  String _renderList(List<RenderToken> tokens) {
    final buf = StringBuffer();
    _Kind? prev;
    bool inHold = false;
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      if (t is RtHoldStart) {
        inHold = true;
        continue;
      }
      if (t is RtHoldEnd) {
        inHold = false;
        buf.write(' and hold');
        continue;
      }
      final piece = _piece(t, inHold: inHold);
      if (piece == null) continue;
      final (str, kind) = piece;
      if (buf.isNotEmpty) {
        buf.write(_separator(prev, kind));
      }
      buf.write(str);
      prev = kind;
    }
    return buf.toString();
  }

  String _separator(_Kind? prev, _Kind cur) {
    if (prev == null) return '';
    // Right after a charge, the follow-up direction reads "hold X then Y".
    if (prev == _Kind.charge && cur == _Kind.movement) return ' then ';
    // After a charge and next is a button, insert ", then ".
    return ', then ';
  }

  (String, _Kind)? _piece(RenderToken t, {required bool inHold}) {
    switch (t) {
      case RtMotion(:final shape):
        return (_motionEn(shape), _Kind.movement);
      case RtDirection(:final value):
        return (_directionEn(value), _Kind.movement);
      case RtButton(:final symbol):
        return ('press $symbol', _Kind.action);
      case RtNeutral():
        return ('return to neutral', _Kind.movement);
      case RtCharge(:final chargeDirection):
        return ('hold ${_directionEn(chargeDirection)}', _Kind.charge);
      case RtReleaseStart():
        return null;
      case RtReleaseEnd():
        return ('release', _Kind.action);
      case RtOptionalStart():
        return ('optionally,', _Kind.movement);
      case RtOptionalEnd():
        return null;
      case RtRepeatStart(:final count):
        return (
          count == null ? 'repeatedly:' : '$count times:',
          _Kind.movement,
        );
      case RtRepeatEnd():
        return null;
      case RtSimultaneousStart():
        return null;
      case RtSimultaneousEnd():
        return null;
      case RtSimultaneousSeparator():
        return ('and', _Kind.action);
      case RtFallback(:final sourceRaw):
        return ('unclear notation: $sourceRaw', _Kind.action);
      case RtUnknown():
        return ('unclear input', _Kind.action);
      case RtAlternative(:final options):
        final parts = <String>[for (final o in options) _renderList(o)];
        return (parts.join(' OR '), _Kind.action);
      case RtContextualHint():
        return null;
      case RtHoldStart() || RtHoldEnd():
        return null;
    }
  }

  String _prefix(RtContextualHint hint) {
    final parts = <String>[];
    for (final r in hint.requirements) {
      parts.add(_requirementEn(r.kind, r.value, r.description));
    }
    return parts.join('; ');
  }

  String _requirementEn(String kind, String? value, String? description) {
    if (kind == 'spatial') {
      return switch (value) {
        'near_opponent' => 'close to the opponent',
        'far_from_opponent' => 'far from the opponent',
        'in_corner' => 'in the corner',
        'against_wall' => 'against the wall',
        'near_wall' => 'near the wall',
        'midscreen' => 'midscreen',
        _ => description ?? value ?? kind,
      };
    }
    if (kind == 'state') {
      return switch (value) {
        'airborne' => 'while in the air',
        'grounded' => 'while on the ground',
        'on_landing' => 'on landing',
        'while_running' => 'while running',
        'while_walking' => 'while walking',
        'while_dashing' => 'while dashing',
        'while_crouching' => 'while crouching',
        _ => description ?? value ?? kind,
      };
    }
    if (kind == 'phase') {
      return switch (value) {
        'on_wakeup' => 'on wakeup',
        'on_block' => 'on block',
        'on_hit' => 'on hit',
        'when_thrown' => 'when thrown',
        _ => description ?? value ?? kind,
      };
    }
    if (kind == 'stance' && value != null) {
      return 'in $value stance';
    }
    return description ?? value ?? kind;
  }

  String _motionEn(String shape) {
    return switch (shape) {
      'quarter_circle_forward' => 'quarter circle forward',
      'quarter_circle_back' => 'quarter circle back',
      'half_circle_forward' => 'half circle forward',
      'half_circle_back' => 'half circle back',
      'dragon_punch_forward' => 'dragon punch forward',
      'dragon_punch_back' => 'dragon punch back',
      'reverse_dragon_punch_forward' => 'reverse dragon punch forward',
      'reverse_dragon_punch_back' => 'reverse dragon punch back',
      'full_circle' => 'full circle',
      'double_quarter_circle_forward' => 'double quarter circle forward',
      'double_quarter_circle_back' => 'double quarter circle back',
      'pretzel_forward' => 'pretzel motion forward',
      'pretzel_back' => 'pretzel motion back',
      _ => shape.replaceAll('_', ' '),
    };
  }

  String _directionEn(String d) {
    return switch (d) {
      'neutral' => 'neutral',
      'forward' => 'forward',
      'back' => 'back',
      'up' => 'up',
      'down' => 'down',
      'up_forward' => 'up-forward',
      'up_back' => 'up-back',
      'down_forward' => 'down-forward',
      'down_back' => 'down-back',
      'any' => 'any direction',
      _ => d,
    };
  }
}

enum _Kind { movement, action, charge }
