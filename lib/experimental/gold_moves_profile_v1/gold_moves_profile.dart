/// Public façade of the Gold Moves Profile v1.0.0 experimental spike.
///
/// See `README.md` in this folder for context. This library is NOT
/// intended to be imported from production screens.
library;

export 'domain/annotation.dart';
export 'domain/button.dart';
export 'domain/character.dart';
export 'domain/expression.dart';
export 'domain/move.dart';
export 'domain/notation_frame.dart';
export 'domain/parse_status.dart';
export 'domain/profile.dart';
export 'domain/provenance.dart';

export 'parsing/integrity.dart';
export 'parsing/parse_error.dart';
export 'parsing/profile_parser.dart';
export 'parsing/asset_loader.dart';

export 'rendering/render_tokens.dart';
export 'rendering/renderers/accessible_en_renderer.dart';
export 'rendering/renderers/accessible_fr_renderer.dart';
export 'rendering/renderers/activation_hint_renderer.dart';
export 'rendering/renderers/classic_2d_renderer.dart';
export 'rendering/renderers/icon_tokens_renderer.dart';
export 'rendering/renderers/numpad_renderer.dart';
