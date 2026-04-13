import 'package:flutter/material.dart';
import '../models/move_list.dart';
import '../theme/app_theme.dart';
import '../screens/execution_mode_screen.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'input_token.dart';

// ═══════════════════════════════════════════════════════════════
// MAME-faithful command.dat renderer
//
// Uses InputToken system for directional/button chips.
// Tab strip for character sections, scrollable rich-text body.
// ═══════════════════════════════════════════════════════════════

void _openExecution(BuildContext context, MoveEntry move) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ExecutionModeScreen(move: move),
    ),
  );
}

// ── Category dot (compact indicator) ────────────────────────

Color categoryColor(String category) {
  return switch (category) {
    'throw'   => AppColors.catThrow,
    'command' => AppColors.catCommand,
    'special' => AppColors.catSpecial,
    'super'   => AppColors.catDM,
    'ultra'   => AppColors.catSDM,
    'other'   => Colors.amber,
    _         => Colors.transparent,
  };
}

// ── Move Row ────────────────────────────────────────────────

class MoveRow extends StatelessWidget {
  final MoveEntry move;
  final VoidCallback? onTap;

  const MoveRow({super.key, required this.move, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isInfo =
        move.note == 'info' || (move.category.isEmpty && move.input.isEmpty);

    if (isInfo) {
      final nameSpans = tokeniseInput(move.name, context);
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
                  color: AppColors.textSecondary,
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
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final catColor = categoryColor(move.category);
    final inputSpans = tokeniseInput(move.input, context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Category dot
            if (catColor != Colors.transparent)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: catColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: catColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              )
            else
              const SizedBox(width: 16),

            // Move name
            Expanded(
              child: Text(
                move.name,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(width: 8),

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
      ),
    );
  }
}

// ── Section block (ExpansionTile) ───────────────────────────

class SectionBlock extends StatelessWidget {
  final MoveListSection section;
  final String? gameId;
  final String? gameTitle;
  final String? romName;
  final bool initiallyExpanded;

  const SectionBlock({
    super.key,
    required this.section,
    this.gameId,
    this.gameTitle,
    this.romName,
    this.initiallyExpanded = false,
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
            if (section.sectionType == 'other' &&
                gameId != null &&
                romName != null)
              _BookmarkIcon(
                gameId: gameId!,
                gameTitle: gameTitle ?? '',
                romName: romName!,
                section: section,
              ),
            Text(
              '${section.entries.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 20),
          ],
        ),
        children: [
          if (section.entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No moves listed'),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  for (final m in section.entries) ...[
                    MoveRow(
                      move: m,
                      onTap: m.input.isNotEmpty
                          ? () => _openExecution(context, m)
                          : null,
                    ),
                    for (final fu in m.followUps)
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: MoveRow(
                          move: fu,
                          onTap: fu.input.isNotEmpty
                              ? () => _openExecution(context, fu)
                              : null,
                        ),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Main public widget ──────────────────────────────────────

/// MAME-style move list viewer with character cards.
class MoveListView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final commonSections = commandData.sections
        .where((s) => s.sectionType != 'other')
        .toList();
    final charSections = commandData.sections
        .where((s) => s.sectionType == 'other')
        .toList();

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
          commandData.title,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 8),

        // Common sections (controls, how-to-play, common commands)
        for (final s in commonSections)
          SectionBlock(section: s),

        // Character sections – one card per character
        if (charSections.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final s in charSections)
            SectionBlock(
              section: s,
              gameId: gameId,
              gameTitle: gameTitle,
              romName: romName,
            ),
        ],

        // Legend footer
        const SizedBox(height: 8),
        const MoveLegend(),
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

class MoveLegend extends StatelessWidget {
  const MoveLegend({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('throw', AppColors.catThrow),
      ('cmd', AppColors.catCommand),
      ('special', AppColors.catSpecial),
      ('DM', AppColors.catDM),
      ('SDM', AppColors.catSDM),
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
