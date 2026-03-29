import 'package:flutter/material.dart';
import '../models/move_list.dart';

// ── Input notation conversion ────────────────────────────────

/// Convert MAME command.dat input notation to human-readable display.
///
/// Examples:
///   _2_3_6_+_P  →  ↓↘→+P
///   _4 / _6_+_C →  ←/→+C
///   ^*_P        →  ×P (rapid press)
String formatInput(String raw) {
  if (raw.isEmpty) return '';

  var result = raw;

  // Shorthand motions (must replace before individual directions)
  const motionMap = {
    '_t': '↓↘→', // QCF
    '_p': '↓↙←', // QCB
    '_m': '←↙↓↘→', // HCF
    '_k': '→↘↓↙←', // HCB
    '_Q': '→↓↘', // DP
    '_R': '←↓↙', // Reverse DP
  };
  motionMap.forEach((token, display) {
    result = result.replaceAll(token, display);
  });

  // Directional inputs (numpad notation)
  const dirMap = {
    '_7': '↖',
    '_8': '↑',
    '_9': '↗',
    '_4': '←',
    '_5': '●',
    '_6': '→',
    '_1': '↙',
    '_2': '↓',
    '_3': '↘',
  };
  dirMap.forEach((token, arrow) {
    result = result.replaceAll(token, arrow);
  });

  // Button inputs
  const buttonMap = {
    '_A': 'A',
    '_B': 'B',
    '_C': 'C',
    '_D': 'D',
    '_P': 'P',
    '_K': 'K',
    '_S': 'ST',
    '_X': '✕',
    '_O': '○',
    '_L': '⇄',
    '_M': '⇅',
  };
  buttonMap.forEach((token, display) {
    result = result.replaceAll(token, display);
  });

  // Operator tokens
  result = result.replaceAll('_+', '+');
  result = result.replaceAll('_^', '(air) ');
  result = result.replaceAll('_?', '?');

  // Modifier prefixes
  result = result.replaceAll('^*', '×'); // rapid press
  result = result.replaceAll('^!', '→'); // arrow glyph
  result = result.replaceAll('^S', 'SEL');
  result = result.replaceAll('^s', '⚔'); // slash button
  result = result.replaceAll('^3', '↘'); // crawl

  // Clean up underscores for any remaining tokens
  result = result.replaceAll('_`', '');

  return result.trim();
}

// ── Category styling ─────────────────────────────────────────

Color categoryColor(String category) {
  switch (category) {
    case 'throw':
      return Colors.orange;
    case 'command':
      return Colors.teal;
    case 'special':
      return Colors.blue;
    case 'super':
      return Colors.red;
    case 'ultra':
      return Colors.purple;
    case 'other':
      return Colors.amber;
    default:
      return Colors.grey;
  }
}

String categoryLabel(String category) {
  switch (category) {
    case 'throw':
      return 'THR';
    case 'command':
      return 'CMD';
    case 'special':
      return 'SPE';
    case 'super':
      return 'DM';
    case 'ultra':
      return 'SDM';
    case 'other':
      return '★';
    default:
      return '';
  }
}

// ── Widgets ──────────────────────────────────────────────────

/// Full move list display for a game. Pass the resolved [CommandData].
class MoveListView extends StatelessWidget {
  final CommandData commandData;

  const MoveListView({super.key, required this.commandData});

  @override
  Widget build(BuildContext context) {
    // Group sections by type for display ordering
    final nonCharSections = commandData.sections
        .where((s) => s.sectionType != 'character')
        .toList();
    final charSections = commandData.sections
        .where((s) => s.sectionType == 'character')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Move List', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          commandData.title,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 8),

        // Common sections (controls, how to play, common commands)
        for (final section in nonCharSections)
          _SectionTile(section: section, initiallyExpanded: false),

        // Character sections
        if (charSections.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              'Characters',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          for (final section in charSections)
            _SectionTile(section: section, initiallyExpanded: false),
        ],
      ],
    );
  }
}

/// Single expandable section (character or common commands).
class _SectionTile extends StatelessWidget {
  final MoveListSection section;
  final bool initiallyExpanded;

  const _SectionTile({
    required this.section,
    required this.initiallyExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = section.subtitle != null && section.subtitle!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
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
                    .map((move) => _MoveRow(move: move))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Single move row: category badge | name | input.
class _MoveRow extends StatelessWidget {
  final MoveEntry move;

  const _MoveRow({required this.move});

  @override
  Widget build(BuildContext context) {
    final isInfoNote = move.note == 'info' || (move.category.isEmpty && move.input.isEmpty);
    
    if (isInfoNote) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

    final formattedInput = formatInput(move.input);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge
          if (move.category.isNotEmpty)
            Container(
              width: 36,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: categoryColor(move.category).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                categoryLabel(move.category),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: categoryColor(move.category),
                ),
              ),
            )
          else
            const SizedBox(width: 36),
          const SizedBox(width: 8),

          // Move name
          Expanded(
            flex: 3,
            child: Text(
              move.name,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),

          // Input notation
          if (formattedInput.isNotEmpty)
            Expanded(
              flex: 2,
              child: Text(
                formattedInput,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.end,
              ),
            ),
        ],
      ),
    );
  }
}
