import 'package:flutter/material.dart';
import '../models/move_list.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

// ═══════════════════════════════════════════════════════════════
// MAME-faithful command.dat renderer
//
// Follows button_char.lua token→glyph mapping and datmenu.cpp
// document-viewer paradigm: tab strip for sections, scrollable
// rich-text body with inline directional/button chips.
// ═══════════════════════════════════════════════════════════════

// ── Token → InlineSpan conversion (button_char.lua equivalent) ──

/// Tokenise a raw command.dat input string into a list of [InlineSpan]
/// widgets. Directions become [_DirectionChip], buttons become
/// [_ButtonChip], operators render as styled text.
List<InlineSpan> _tokenise(String raw, BuildContext context) {
  if (raw.isEmpty) return [];

  final spans = <InlineSpan>[];
  var i = 0;
  final buf = StringBuffer();

  void flushText() {
    if (buf.isNotEmpty) {
      spans.add(TextSpan(
        text: buf.toString(),
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ));
      buf.clear();
    }
  }

  // Shorthand motion sequences
  const motionTokens = <String, List<String>>{
    '_t': ['↓', '↘', '→'],       // QCF
    '_p': ['↓', '↙', '←'],       // QCB
    '_m': ['←', '↙', '↓', '↘', '→'], // HCF
    '_k': ['→', '↘', '↓', '↙', '←'], // HCB
    '_Q': ['→', '↓', '↘'],       // DP
    '_R': ['←', '↓', '↙'],       // Reverse DP
  };

  // Single direction tokens (numpad)
  const dirTokens = <String, String>{
    '_7': '↖', '_8': '↑', '_9': '↗',
    '_4': '←', '_5': '●', '_6': '→',
    '_1': '↙', '_2': '↓', '_3': '↘',
  };

  // Button tokens → (label, color)
  const buttonTokens = <String, (String, Color)>{
    '_A': ('A', Color(0xFF4A90D9)),  // blue
    '_B': ('B', Color(0xFF4CAF50)),  // green
    '_C': ('C', Color(0xFFE53935)),  // red
    '_D': ('D', Color(0xFFF57C00)), // orange
    '_P': ('P', Color(0xFF9E9E9E)),  // generic punch – grey
    '_K': ('K', Color(0xFF9E9E9E)),  // generic kick – grey
    '_S': ('ST', Color(0xFF78909C)), // start
  };

  // Button-like modifier tokens (^x family, rendered as chips)
  const modButtonTokens = <String, (String, Color)>{
    '^S': ('SEL', Color(0xFF78909C)),  // select
    '^M': ('M', Color(0xFF9575CD)),    // meditation / mu no kyouchi
  };

  // Modifier prefixes (^x family, rendered as text or direction chips)
  const modTokens = <String, String>{
    '^*': '×',   // rapid tap
    '^!': '→',   // arrow glyph
    '^s': '⚔',   // slash
    '^3': '↘',   // crawl (down-forward)
    '^1': '↙',   // charge back-down
    '^2': '↓',   // charge down
    '^4': '←',   // charge back
  };

  while (i < raw.length) {
    // Try two-char tokens starting at i
    if (i + 1 < raw.length) {
      final two = raw.substring(i, i + 2);

      // Shorthand motions (_t, _p, _m, _k, _Q, _R)
      if (motionTokens.containsKey(two)) {
        flushText();
        for (final arrow in motionTokens[two]!) {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _DirectionChip(arrow),
          ));
        }
        i += 2;
        continue;
      }

      // Direction tokens (_1 .. _9)
      if (dirTokens.containsKey(two)) {
        flushText();
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _DirectionChip(dirTokens[two]!),
        ));
        i += 2;
        continue;
      }

      // Button tokens (_A, _B, _C, _D, _P, _K, _S)
      if (buttonTokens.containsKey(two)) {
        flushText();
        final (label, color) = buttonTokens[two]!;
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _ButtonChip(label, color),
        ));
        i += 2;
        continue;
      }

      // Operators
      if (two == '_+') {
        flushText();
        spans.add(TextSpan(
          text: '+',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ));
        i += 2;
        continue;
      }
      if (two == '_^') {
        flushText();
        spans.add(TextSpan(
          text: ' air ',
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ));
        i += 2;
        continue;
      }
      if (two == '_?') {
        flushText();
        spans.add(TextSpan(
          text: '?',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ));
        i += 2;
        continue;
      }
      if (two == '_O') {
        // hold / charge circle
        flushText();
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _DirectionChip('○'),
        ));
        i += 2;
        continue;
      }
      if (two == '_X') {
        flushText();
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _DirectionChip('✕'),
        ));
        i += 2;
        continue;
      }
      if (two == '_L') {
        // double-tap forward (dash)
        flushText();
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _DirectionChip('→→'),
        ));
        i += 2;
        continue;
      }
      if (two == '_M') {
        // double-tap back (backstep)
        flushText();
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _DirectionChip('←←'),
        ));
        i += 2;
        continue;
      }
      if (two == '_x') {
        // tap repeatedly
        flushText();
        spans.add(TextSpan(
          text: '×',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ));
        i += 2;
        continue;
      }
      if (two == '_`') {
        // ignored token
        i += 2;
        continue;
      }

      // Modifier button chips (^S, ^M)
      if (modButtonTokens.containsKey(two)) {
        flushText();
        final (label, color) = modButtonTokens[two]!;
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _ButtonChip(label, color),
        ));
        i += 2;
        continue;
      }

      // Modifier prefixes (^x)
      if (modTokens.containsKey(two)) {
        flushText();
        final glyph = modTokens[two]!;
        if (glyph.length == 1 && '↖↑↗←●→↙↓↘'.contains(glyph)) {
          // charge direction – render as direction chip with a border
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _ChargeChip(glyph),
          ));
        } else {
          spans.add(TextSpan(
            text: glyph,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ));
        }
        i += 2;
        continue;
      }
    }

    // Handle plain space / slashes as light separators
    if (raw[i] == '/') {
      flushText();
      spans.add(TextSpan(
        text: ' / ',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ));
      i++;
      continue;
    }

    // Regular character
    if (raw[i] != ' ') {
      buf.write(raw[i]);
    } else {
      // Collapse spaces – add a thin separator
      if (buf.isNotEmpty) flushText();
      buf.write(' ');
    }
    i++;
  }
  flushText();
  return spans;
}

// ── Inline glyph widgets ────────────────────────────────────

/// Directional input chip (arrows rendered in a dark circle).
class _DirectionChip extends StatelessWidget {
  final String glyph;
  const _DirectionChip(this.glyph);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade600, width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(
        glyph,
        style: const TextStyle(
          fontSize: 13,
          height: 1,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Charge direction chip – similar to direction but with a coloured border.
class _ChargeChip extends StatelessWidget {
  final String glyph;
  const _ChargeChip(this.glyph);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.amber.shade700, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        glyph,
        style: const TextStyle(fontSize: 13, height: 1, color: Colors.white),
      ),
    );
  }
}

/// Button chip (coloured rectangle with label). Uses vertical padding
/// instead of alignment so the Container shrink-wraps its child.
class _ButtonChip extends StatelessWidget {
  final String label;
  final Color color;
  const _ButtonChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ── Category dot (compact indicator) ────────────────────────

Color _categoryColor(String category) {
  return switch (category) {
    'throw'   => Colors.orange,
    'command' => Colors.teal,
    'special' => Colors.blue,
    'super'   => Colors.red,
    'ultra'   => Colors.purple,
    'other'   => Colors.amber,
    _         => Colors.transparent,
  };
}

// ── Move line (document-style: name row, indented input row) ─

class _MoveRichLine extends StatelessWidget {
  final MoveEntry move;
  const _MoveRichLine({required this.move});

  @override
  Widget build(BuildContext context) {
    final isInfo =
        move.note == 'info' || (move.category.isEmpty && move.input.isEmpty);

    if (isInfo) {
      // Tokenise the name so embedded tokens (_A, _P, ^S, ^M, etc.) render as glyphs
      final nameSpans = _tokenise(move.name, context);
      final hasTokens = nameSpans.any((s) => s is WidgetSpan) ||
          RegExp(r'_[A-Z]|\^[SMsm*!]').hasMatch(move.name);

      if (hasTokens) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 0,
            runSpacing: 2,
            children: nameSpans.map((span) {
              if (span is WidgetSpan) return span.child;
              final text = (span as TextSpan).text ?? '';
              return Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            }).toList(),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        child: Text(
          move.name,
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final catColor = _categoryColor(move.category);
    final inputSpans = _tokenise(move.input, context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Category dot
          if (catColor != Colors.transparent)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: catColor,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(width: 14),

          // Move name
          Expanded(
            child: Text(
              move.name,
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
          ),

          // Input notation (inline chips, right-aligned)
          if (inputSpans.isNotEmpty)
            Flexible(
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 0,
                runSpacing: 2,
                children: inputSpans.map((span) {
                  if (span is WidgetSpan) return span.child;
                  final text = (span as TextSpan).text ?? '';
                  final style = span.style;
                  return Text(text, style: style);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Section block (ExpansionTile) ───────────────────────────

class _SectionBlock extends StatelessWidget {
  final MoveListSection section;
  final bool initiallyExpanded;
  final String? gameId;
  final String? gameTitle;
  final String? romName;

  const _SectionBlock({
    required this.section,
    this.initiallyExpanded = false,
    this.gameId,
    this.gameTitle,
    this.romName,
  });

  @override
  Widget build(BuildContext context) {
    final hasSubtitle =
        section.subtitle != null && section.subtitle!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text(
          section.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: hasSubtitle
            ? Text(
                section.subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (section.sectionType == 'character' &&
                gameId != null &&
                romName != null)
              _BookmarkIcon(
                gameId: gameId!,
                gameTitle: gameTitle ?? '',
                romName: romName!,
                section: section,
              ),
            Text(
              '${section.moves.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 20),
          ],
        ),
        children: [
          if (section.moves.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No moves listed'),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: section.moves
                    .map((m) => _MoveRichLine(move: m))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Main public widget ──────────────────────────────────────

/// MAME-style move list viewer with tab strip for character
/// sections and scrollable rich-text body.
class MoveListView extends StatefulWidget {
  final CommandData commandData;
  final String? gameId;
  final String? gameTitle;
  final String? romName;

  const MoveListView({
    super.key,
    required this.commandData,
    this.gameId,
    this.gameTitle,
    this.romName,
  });

  @override
  State<MoveListView> createState() => _MoveListViewState();
}

class _MoveListViewState extends State<MoveListView>
    with SingleTickerProviderStateMixin {
  late final List<MoveListSection> _commonSections;
  late final List<MoveListSection> _charSections;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _commonSections = widget.commandData.sections
        .where((s) => s.sectionType != 'character')
        .toList();
    _charSections = widget.commandData.sections
        .where((s) => s.sectionType == 'character')
        .toList();
    if (_charSections.length > 1) {
      _tabController = TabController(
        length: _charSections.length,
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.sports_martial_arts, size: 20),
            const SizedBox(width: 6),
            Text('Move List',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          widget.commandData.title,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 8),

        // Common sections (controls, how-to-play, common commands)
        for (final s in _commonSections)
          _SectionBlock(section: s),

        // Character sections
        if (_charSections.isNotEmpty) ...[
          const SizedBox(height: 8),
          if (_charSections.length == 1)
            // Single character – just show as expansion tile
            _SectionBlock(
              section: _charSections.first,
              gameId: widget.gameId,
              gameTitle: widget.gameTitle,
              romName: widget.romName,
            )
          else ...[
            // Tab strip
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabs: _charSections
                  .map((s) => Tab(text: s.title))
                  .toList(),
            ),
            const SizedBox(height: 4),
            // Tab body – constrained height for scrollability within page
            SizedBox(
              height: 420,
              child: TabBarView(
                controller: _tabController,
                children: _charSections.map((section) {
                  return Column(
                    children: [
                      // Bookmark action row
                      if (widget.gameId != null && widget.romName != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                section.subtitle ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              const Spacer(),
                              _BookmarkIcon(
                                gameId: widget.gameId!,
                                gameTitle: widget.gameTitle ?? '',
                                romName: widget.romName!,
                                section: section,
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(vertical: 4),
                          itemCount: section.moves.length,
                          itemBuilder: (_, i) =>
                              _MoveRichLine(move: section.moves[i]),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ],

        // Legend footer
        const SizedBox(height: 8),
        _Legend(),
      ],
    );
  }
}

// ── Bookmark icon (toggle) ──────────────────────────────────

class _BookmarkIcon extends StatelessWidget {
  final String gameId;
  final String gameTitle;
  final String romName;
  final MoveListSection section;

  const _BookmarkIcon({
    required this.gameId,
    required this.gameTitle,
    required this.romName,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      return IconButton(
        icon: const Icon(Icons.bookmark_border, size: 20),
        visualDensity: VisualDensity.compact,
        tooltip: 'Bookmark move list',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign in to bookmark move lists'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      );
    }

    return StreamBuilder<bool>(
      stream: UserService.isFaveMoveStream(romName, section.title),
      builder: (context, snapshot) {
        final isBookmarked = snapshot.data ?? false;
        return IconButton(
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            size: 20,
            color: isBookmarked ? Colors.amber : null,
          ),
          visualDensity: VisualDensity.compact,
          tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark move list',
          onPressed: () {
            UserService.toggleFaveMove(
              gameId: gameId,
              gameTitle: gameTitle,
              romName: romName,
              sectionTitle: section.title,
              sectionSubtitle: section.subtitle,
            );
          },
        );
      },
    );
  }
}

// ── Legend row ───────────────────────────────────────────────

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      ('throw', Colors.orange),
      ('cmd', Colors.teal),
      ('special', Colors.blue),
      ('DM', Colors.red),
      ('SDM', Colors.purple),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (final (label, color) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        Text(
          '· source: command.dat',
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
