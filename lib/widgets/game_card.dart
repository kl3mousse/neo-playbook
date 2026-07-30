import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game.dart';
import '../models/user_favorite.dart';
import '../theme/app_theme.dart';
import '../theme/combofox_theme.dart';

Color genreColor(String genre) {
  final g = genre.toLowerCase();
  if (g.contains('combat') || g.contains('fighting') || g.contains('versus')) {
    return Colors.red.shade700;
  }
  if (g.contains('shoot')) return Colors.blue.shade700;
  if (g.contains('beat')) return Colors.deepOrange.shade600;
  if (g.contains('action')) return Colors.orange.shade700;
  if (g.contains('puzzle')) return Colors.teal.shade600;
  if (g.contains('sport')) return Colors.green.shade700;
  if (g.contains('racing')) return Colors.amber.shade700;
  if (g.contains('platform')) return Colors.purple.shade600;
  if (g.contains('rpg') || g.contains('role')) return Colors.indigo.shade600;
  if (g.contains('quiz')) return Colors.pink.shade600;
  return Colors.blueGrey.shade600;
}

// ── GameCard ────────────────────────────────────────────────
//
// Flat, single-column card. The whole card sits on a unified dark
// surface (theme colors) and uses the genre color only as a subtle
// accent (left rail + genre chip tint).

class GameCard extends StatefulWidget {
  final Game game;
  final VoidCallback? onTap;
  final FavoriteStatus? status;

  const GameCard({super.key, required this.game, this.onTap, this.status});

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = genreColor(widget.game.primaryGenre);
    final game = widget.game;

    // Assemble metadata bits: year · publisher · players.
    final metaParts = <String>[
      if (game.yearLabel.isNotEmpty) game.yearLabel,
      if (game.publisher != null && game.publisher!.isNotEmpty) game.publisher!,
      if (game.playersLabel.isNotEmpty) game.playersLabel,
    ];

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isPressed
                  ? accent.withValues(alpha: 0.55)
                  : ComboFoxColors.neonPurple.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Genre accent rail (only visible splash of genre color)
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.withValues(alpha: 0.95),
                          accent.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  // Main content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Title
                                Text(
                                  game.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontFamily: 'Doto',
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Meta row: genre chip + year · publisher · players
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (game.primaryGenre.isNotEmpty) ...[
                                      _GenreChip(
                                        label: game.primaryGenre,
                                        accent: accent,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        metaParts.join(' · '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (widget.status != null) ...[
                            const SizedBox(width: 10),
                            _StatusBadge(status: widget.status!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small building blocks ───────────────────────────────────

class _GenreChip extends StatelessWidget {
  final String label;
  final Color accent;

  const _GenreChip({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Color.alphaBlend(
            accent.withValues(alpha: 0.35),
            AppColors.textPrimary,
          ),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final FavoriteStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ComboFoxColors.neonPurple.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status.icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
