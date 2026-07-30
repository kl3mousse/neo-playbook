import '../../domain/move.dart';

/// One-liner activation hint for moves whose `activation.kind` is not
/// `by_player_input`.
///
/// See `rendering-samples.json` `activation_hint_en`.
class ActivationHintRenderer {
  /// Returns null when the move is a normal player-input move.
  String? renderEn(MoveGold move) {
    switch (move.activation.kind) {
      case ActivationKind.byPlayerInput:
        return null;
      case ActivationKind.automaticAfterMove:
        final trigger = move.activation.trigger;
        final parent = trigger?.parentMoveId;
        final on = _triggerEn(trigger?.rawKind);
        final desc = trigger?.description ?? move.activation.description;
        final head = parent == null
            ? 'Fires automatically on $on.'
            : "Fires automatically on $on as a follow-up of '$parent'.";
        if (desc == null || desc.isEmpty) return head;
        return '$head ($desc)';
      case ActivationKind.contextualTrigger:
        final desc =
            move.activation.trigger?.description ?? move.activation.description;
        final on = _triggerEn(move.activation.trigger?.rawKind);
        if (desc == null || desc.isEmpty) {
          return 'Fires on $on.';
        }
        return 'Fires on $on. ($desc)';
      case ActivationKind.unknown:
        final desc = move.activation.description;
        return desc == null || desc.isEmpty
            ? 'Activation unknown.'
            : 'Activation unknown. ($desc)';
    }
  }

  String? renderFr(MoveGold move) {
    switch (move.activation.kind) {
      case ActivationKind.byPlayerInput:
        return null;
      case ActivationKind.automaticAfterMove:
        final trigger = move.activation.trigger;
        final parent = trigger?.parentMoveId;
        final on = _triggerFr(trigger?.rawKind);
        final desc = trigger?.description ?? move.activation.description;
        final head = parent == null
            ? "Se déclenche automatiquement sur $on."
            : "Se déclenche automatiquement sur $on à la suite de « $parent ».";
        if (desc == null || desc.isEmpty) return head;
        return '$head ($desc)';
      case ActivationKind.contextualTrigger:
        final desc =
            move.activation.trigger?.description ?? move.activation.description;
        final on = _triggerFr(move.activation.trigger?.rawKind);
        if (desc == null || desc.isEmpty) {
          return 'Se déclenche sur $on.';
        }
        return 'Se déclenche sur $on. ($desc)';
      case ActivationKind.unknown:
        final desc = move.activation.description;
        return desc == null || desc.isEmpty
            ? 'Activation inconnue.'
            : 'Activation inconnue. ($desc)';
    }
  }

  String _triggerEn(String? rawKind) {
    return switch (rawKind) {
      'on_hit' => 'a hit',
      'on_mid_hit' => 'a mid hit',
      'on_low_hit' => 'a low hit',
      'on_high_hit' => 'a high hit',
      'on_wall_hit' => 'a wall hit',
      'on_counter_hit' => 'a counter hit',
      'on_block' => 'block',
      'on_landing' => 'landing',
      'on_wakeup' => 'wakeup',
      'on_activation' => 'activation',
      'near_wall' => 'a near-wall condition',
      'custom' => 'a custom trigger',
      _ => 'an unknown trigger',
    };
  }

  String _triggerFr(String? rawKind) {
    return switch (rawKind) {
      'on_hit' => 'touche',
      'on_mid_hit' => 'touche moyenne',
      'on_low_hit' => 'touche basse',
      'on_high_hit' => 'touche haute',
      'on_wall_hit' => 'touche contre un mur',
      'on_counter_hit' => 'contre-attaque',
      'on_block' => 'garde',
      'on_landing' => 'atterrissage',
      'on_wakeup' => 'réveil',
      'on_activation' => 'activation',
      'near_wall' => 'condition « près du mur »',
      'custom' => 'un déclencheur personnalisé',
      _ => 'un déclencheur inconnu',
    };
  }
}
