import '../../domain/move.dart';
import '../render_tokens.dart';

/// Screen-reader-friendly French renderer.
///
/// Produces phrases such as « quart de cercle avant, puis appuyer sur A ».
class AccessibleFrRenderer {
  String? render(MoveGold move) {
    if (move.inputExpressions.isEmpty) return null;
    final w = move.inputExpressions.first;
    final expr = w.expression;
    if (expr == null) {
      final raw = w.sourceRaw ?? '';
      return raw.isEmpty ? null : 'notation non parsée : $raw';
    }
    final tokens = buildRenderTokens(expr);
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
      return '${_prefix(tail)} : $content';
    }
    return content;
  }

  String _renderList(List<RenderToken> tokens) {
    final buf = StringBuffer();
    _Kind? prev;
    bool inHold = false;
    for (final t in tokens) {
      if (t is RtHoldStart) {
        inHold = true;
        continue;
      }
      if (t is RtHoldEnd) {
        inHold = false;
        buf.write(' et maintenir');
        continue;
      }
      final piece = _piece(t, inHold: inHold);
      if (piece == null) continue;
      final (str, kind) = piece;
      if (buf.isNotEmpty) buf.write(_separator(prev, kind));
      buf.write(str);
      prev = kind;
    }
    return buf.toString();
  }

  String _separator(_Kind? prev, _Kind cur) {
    if (prev == null) return '';
    if (prev == _Kind.charge && cur == _Kind.movement) return ' puis ';
    return ', puis ';
  }

  (String, _Kind)? _piece(RenderToken t, {required bool inHold}) {
    switch (t) {
      case RtMotion(:final shape):
        return (_motionFr(shape), _Kind.movement);
      case RtDirection(:final value):
        return (_directionFr(value), _Kind.movement);
      case RtButton(:final symbol):
        return ('appuyer sur $symbol', _Kind.action);
      case RtNeutral():
        return ('revenir au neutre', _Kind.movement);
      case RtCharge(:final chargeDirection):
        return ('maintenir ${_directionFr(chargeDirection)}', _Kind.charge);
      case RtReleaseStart():
        return null;
      case RtReleaseEnd():
        return ('relâcher', _Kind.action);
      case RtOptionalStart():
        return ('facultativement,', _Kind.movement);
      case RtOptionalEnd():
        return null;
      case RtRepeatStart(:final count):
        return (count == null ? 'répéter :' : '$count fois :', _Kind.movement);
      case RtRepeatEnd():
        return null;
      case RtSimultaneousStart():
        return null;
      case RtSimultaneousEnd():
        return null;
      case RtSimultaneousSeparator():
        return ('et', _Kind.action);
      case RtFallback(:final sourceRaw):
        return ('notation non parsée : $sourceRaw', _Kind.action);
      case RtUnknown():
        return ('commande inconnue', _Kind.action);
      case RtAlternative(:final options):
        final parts = <String>[for (final o in options) _renderList(o)];
        return (parts.join(' OU '), _Kind.action);
      case RtContextualHint():
        return null;
      case RtHoldStart() || RtHoldEnd():
        return null;
    }
  }

  String _prefix(RtContextualHint hint) {
    final parts = <String>[
      for (final r in hint.requirements)
        _requirementFr(r.kind, r.value, r.description),
    ];
    return parts.join(' ; ');
  }

  String _requirementFr(String kind, String? value, String? description) {
    if (kind == 'spatial') {
      return switch (value) {
        'near_opponent' => "près de l'adversaire",
        'far_from_opponent' => "loin de l'adversaire",
        'in_corner' => 'dans le coin',
        'against_wall' => 'contre le mur',
        'near_wall' => 'près du mur',
        'midscreen' => "à mi-écran",
        _ => description ?? value ?? kind,
      };
    }
    if (kind == 'state') {
      return switch (value) {
        'airborne' => 'en l’air',
        'grounded' => 'au sol',
        'on_landing' => "à l'atterrissage",
        'while_running' => 'en courant',
        'while_walking' => 'en marchant',
        'while_dashing' => 'pendant un dash',
        'while_crouching' => 'accroupi',
        _ => description ?? value ?? kind,
      };
    }
    if (kind == 'phase') {
      return switch (value) {
        'on_wakeup' => 'au réveil',
        'on_block' => 'sur garde',
        'on_hit' => 'sur touche',
        'when_thrown' => 'lorsque projeté',
        _ => description ?? value ?? kind,
      };
    }
    if (kind == 'stance' && value != null) {
      return 'en posture $value';
    }
    return description ?? value ?? kind;
  }

  String _motionFr(String shape) {
    return switch (shape) {
      'quarter_circle_forward' => 'quart de cercle avant',
      'quarter_circle_back' => 'quart de cercle arrière',
      'half_circle_forward' => 'demi-cercle avant',
      'half_circle_back' => 'demi-cercle arrière',
      'dragon_punch_forward' => 'dragon punch avant',
      'dragon_punch_back' => 'dragon punch arrière',
      'reverse_dragon_punch_forward' => 'dragon punch inversé avant',
      'reverse_dragon_punch_back' => 'dragon punch inversé arrière',
      'full_circle' => 'cercle complet',
      'double_quarter_circle_forward' => 'double quart de cercle avant',
      'double_quarter_circle_back' => 'double quart de cercle arrière',
      'pretzel_forward' => 'motion pretzel avant',
      'pretzel_back' => 'motion pretzel arrière',
      _ => shape.replaceAll('_', ' '),
    };
  }

  String _directionFr(String d) {
    return switch (d) {
      'neutral' => 'neutre',
      'forward' => 'avant',
      'back' => 'arrière',
      'up' => 'haut',
      'down' => 'bas',
      'up_forward' => 'haut-avant',
      'up_back' => 'haut-arrière',
      'down_forward' => 'bas-avant',
      'down_back' => 'bas-arrière',
      'any' => 'toute direction',
      _ => d,
    };
  }
}

enum _Kind { movement, action, charge }
