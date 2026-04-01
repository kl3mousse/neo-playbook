import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════
// InputToken — Reusable arcade input notation component
//
// Renders directional arrows, action buttons, charge indicators,
// modifiers, and operators as styled UI tokens. Supports two
// sizes: default (move list rows) and large (Execution Mode).
// ═══════════════════════════════════════════════════════════════

enum InputTokenSize { normal, large }

// ── DirectionToken ──────────────────────────────────────────

class DirectionToken extends StatelessWidget {
  final String glyph;
  final InputTokenSize size;

  const DirectionToken(this.glyph, {super.key, this.size = InputTokenSize.normal});

  @override
  Widget build(BuildContext context) {
    final dim = size == InputTokenSize.large ? 48.0 : 26.0;
    final fontSize = size == InputTokenSize.large ? 24.0 : 14.0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        color: AppColors.tokenBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        glyph,
        style: TextStyle(
          fontSize: fontSize,
          height: 1,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── ChargeToken ─────────────────────────────────────────────

class ChargeToken extends StatelessWidget {
  final String glyph;
  final InputTokenSize size;

  const ChargeToken(this.glyph, {super.key, this.size = InputTokenSize.normal});

  @override
  Widget build(BuildContext context) {
    final dim = size == InputTokenSize.large ? 48.0 : 26.0;
    final fontSize = size == InputTokenSize.large ? 24.0 : 14.0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        color: AppColors.tokenBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.shade700, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        glyph,
        style: TextStyle(
          fontSize: fontSize,
          height: 1,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── ButtonToken ─────────────────────────────────────────────

class ButtonToken extends StatelessWidget {
  final String label;
  final Color color;
  final InputTokenSize size;

  const ButtonToken(this.label, this.color,
      {super.key, this.size = InputTokenSize.normal});

  @override
  Widget build(BuildContext context) {
    final isLarge = size == InputTokenSize.large;
    final fontSize = isLarge ? 20.0 : 12.0;
    final hPad = isLarge ? 12.0 : 5.0;
    final vPad = isLarge ? 10.0 : 4.0;
    final minH = isLarge ? 48.0 : 26.0;
    return UnconstrainedBox(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        constraints: BoxConstraints(minHeight: minH),
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            height: 1,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ── OperatorToken (+) ───────────────────────────────────────

class OperatorToken extends StatelessWidget {
  final String op;
  final InputTokenSize size;

  const OperatorToken(this.op, {super.key, this.size = InputTokenSize.normal});

  @override
  Widget build(BuildContext context) {
    final fontSize = size == InputTokenSize.large ? 22.0 : 14.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        op,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── ModifierToken (text like "air", "close") ────────────────

class ModifierToken extends StatelessWidget {
  final String text;
  final InputTokenSize size;

  const ModifierToken(this.text, {super.key, this.size = InputTokenSize.normal});

  @override
  Widget build(BuildContext context) {
    final fontSize = size == InputTokenSize.large ? 16.0 : 11.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontStyle: FontStyle.italic,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Tokeniser — MAME-faithful command.dat → widget conversion
//
// Follows button_char.lua token→glyph mapping.
// Produces InlineSpan lists for RichText or Widget lists
// for Wrap/Row layouts.
// ═══════════════════════════════════════════════════════════════

// Shorthand motion sequences
const _motionTokens = <String, List<String>>{
  '_t': ['↓', '↘', '→'],            // QCF
  '_p': ['↓', '↙', '←'],            // QCB
  '_m': ['←', '↙', '↓', '↘', '→'], // HCF
  '_k': ['→', '↘', '↓', '↙', '←'], // HCB
  '_Q': ['→', '↓', '↘'],            // DP
  '_R': ['←', '↓', '↙'],            // Reverse DP
};

// Single direction tokens (numpad)
const _dirTokens = <String, String>{
  '_7': '↖', '_8': '↑', '_9': '↗',
  '_4': '←', '_5': '●', '_6': '→',
  '_1': '↙', '_2': '↓', '_3': '↘',
};

// Button tokens → (label, color)
const _buttonTokens = <String, (String, Color)>{
  '_A': ('A', AppColors.buttonA),
  '_B': ('B', AppColors.buttonB),
  '_C': ('C', AppColors.buttonC),
  '_D': ('D', AppColors.buttonD),
  '_P': ('P', Color(0xFF9E9E9E)),
  '_K': ('K', Color(0xFF9E9E9E)),
  '_S': ('ST', Color(0xFF78909C)),
};

// Modifier button tokens (^x family, rendered as chips)
const _modButtonTokens = <String, (String, Color)>{
  '^S': ('SEL', Color(0xFF78909C)),
  '^M': ('M', Color(0xFF9575CD)),
};

// Modifier direction/glyph tokens
const _modTokens = <String, String>{
  '^*': '×',
  '^!': '→',
  '^s': '⚔',
  '^3': '↘',
  '^1': '↙',
  '^2': '↓',
  '^4': '←',
};

/// Parsed token — intermediate representation for both InlineSpan
/// and Widget rendering.
sealed class ParsedToken {}

class DirectionParsed extends ParsedToken {
  final String glyph;
  DirectionParsed(this.glyph);
}

class ChargeParsed extends ParsedToken {
  final String glyph;
  ChargeParsed(this.glyph);
}

class ButtonParsed extends ParsedToken {
  final String label;
  final Color color;
  ButtonParsed(this.label, this.color);
}

class OperatorParsed extends ParsedToken {
  final String op;
  OperatorParsed(this.op);
}

class ModifierParsed extends ParsedToken {
  final String text;
  ModifierParsed(this.text);
}

class TextParsed extends ParsedToken {
  final String text;
  TextParsed(this.text);
}

class SeparatorParsed extends ParsedToken {
  SeparatorParsed();
}

/// Parse a raw command.dat input string into a list of [ParsedToken].
List<ParsedToken> parseInputTokens(String raw) {
  if (raw.isEmpty) return [];

  final tokens = <ParsedToken>[];
  var i = 0;
  final buf = StringBuffer();

  void flushText() {
    if (buf.isNotEmpty) {
      tokens.add(TextParsed(buf.toString()));
      buf.clear();
    }
  }

  while (i < raw.length) {
    if (i + 1 < raw.length) {
      final two = raw.substring(i, i + 2);

      // Shorthand motions
      if (_motionTokens.containsKey(two)) {
        flushText();
        for (final arrow in _motionTokens[two]!) {
          tokens.add(DirectionParsed(arrow));
        }
        i += 2;
        continue;
      }

      // Direction tokens
      if (_dirTokens.containsKey(two)) {
        flushText();
        tokens.add(DirectionParsed(_dirTokens[two]!));
        i += 2;
        continue;
      }

      // Button tokens
      if (_buttonTokens.containsKey(two)) {
        flushText();
        final (label, color) = _buttonTokens[two]!;
        tokens.add(ButtonParsed(label, color));
        i += 2;
        continue;
      }

      // Operators
      if (two == '_+') {
        flushText();
        tokens.add(OperatorParsed('+'));
        i += 2;
        continue;
      }
      if (two == '_^') {
        flushText();
        tokens.add(ModifierParsed('air'));
        i += 2;
        continue;
      }
      if (two == '_?') {
        flushText();
        tokens.add(TextParsed('?'));
        i += 2;
        continue;
      }
      if (two == '_O') {
        flushText();
        tokens.add(DirectionParsed('○'));
        i += 2;
        continue;
      }
      if (two == '_X') {
        flushText();
        tokens.add(DirectionParsed('✕'));
        i += 2;
        continue;
      }
      if (two == '_L') {
        flushText();
        tokens.add(DirectionParsed('→→'));
        i += 2;
        continue;
      }
      if (two == '_M') {
        flushText();
        tokens.add(DirectionParsed('←←'));
        i += 2;
        continue;
      }
      if (two == '_x') {
        flushText();
        tokens.add(OperatorParsed('×'));
        i += 2;
        continue;
      }
      if (two == '_`') {
        i += 2;
        continue;
      }

      // Modifier button chips
      if (_modButtonTokens.containsKey(two)) {
        flushText();
        final (label, color) = _modButtonTokens[two]!;
        tokens.add(ButtonParsed(label, color));
        i += 2;
        continue;
      }

      // Modifier direction/glyph
      if (_modTokens.containsKey(two)) {
        flushText();
        final glyph = _modTokens[two]!;
        if (glyph.length == 1 && '↖↑↗←●→↙↓↘'.contains(glyph)) {
          tokens.add(ChargeParsed(glyph));
        } else {
          tokens.add(OperatorParsed(glyph));
        }
        i += 2;
        continue;
      }
    }

    if (raw[i] == '/') {
      flushText();
      tokens.add(SeparatorParsed());
      i++;
      continue;
    }

    if (raw[i] != ' ') {
      buf.write(raw[i]);
    } else {
      if (buf.isNotEmpty) flushText();
      buf.write(' ');
    }
    i++;
  }
  flushText();
  return tokens;
}

/// Convert raw input string into InlineSpan list (for RichText in move rows).
List<InlineSpan> tokeniseInput(String raw, BuildContext context) {
  final parsed = parseInputTokens(raw);
  return parsed.map((t) => _parsedToSpan(t, context)).toList();
}

InlineSpan _parsedToSpan(ParsedToken t, BuildContext context) {
  return switch (t) {
    DirectionParsed(:final glyph) => WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: DirectionToken(glyph),
      ),
    ChargeParsed(:final glyph) => WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: ChargeToken(glyph),
      ),
    ButtonParsed(:final label, :final color) => WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: ButtonToken(label, color),
      ),
    OperatorParsed(:final op) => TextSpan(
        text: op,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    ModifierParsed(:final text) => TextSpan(
        text: ' $text ',
        style: TextStyle(
          fontSize: 11,
          fontStyle: FontStyle.italic,
          color: AppColors.textSecondary,
        ),
      ),
    TextParsed(:final text) => TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    SeparatorParsed() => TextSpan(
        text: ' / ',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
  };
}

/// Convert parsed tokens into Widgets (for Wrap/Row layouts in Execution Mode).
List<Widget> tokensToWidgets(List<ParsedToken> tokens,
    {InputTokenSize size = InputTokenSize.normal}) {
  return tokens.map((t) {
    return switch (t) {
      DirectionParsed(:final glyph) => DirectionToken(glyph, size: size),
      ChargeParsed(:final glyph) => ChargeToken(glyph, size: size),
      ButtonParsed(:final label, :final color) =>
        ButtonToken(label, color, size: size),
      OperatorParsed(:final op) => OperatorToken(op, size: size),
      ModifierParsed(:final text) => ModifierToken(text, size: size),
      TextParsed(:final text) => Text(
          text,
          style: TextStyle(
            fontSize: size == InputTokenSize.large ? 18.0 : 13.0,
            color: AppColors.textPrimary,
          ),
        ),
      SeparatorParsed() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '/',
            style: TextStyle(
              fontSize: size == InputTokenSize.large ? 22.0 : 13.0,
              color: AppColors.textSecondary,
            ),
          ),
        ),
    };
  }).toList();
}

// ── InputSequence — convenience widget ──────────────────────

/// Renders a raw command.dat input string as a horizontal flow of tokens.
class InputSequence extends StatelessWidget {
  final String raw;
  final InputTokenSize size;
  final WrapAlignment alignment;

  const InputSequence({
    super.key,
    required this.raw,
    this.size = InputTokenSize.normal,
    this.alignment = WrapAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = parseInputTokens(raw);
    final widgets = tokensToWidgets(parsed, size: size);
    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 1,
      runSpacing: size == InputTokenSize.large ? 8 : 2,
      children: widgets,
    );
  }
}
