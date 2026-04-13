import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game.dart';
import '../models/user_favorite.dart';
import '../theme/app_theme.dart';

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

// ── Diagonal line pattern painter ───────────────────────────

class _DiagonalLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 12.0;
    final diagonal = size.width + size.height;
    for (double d = 0; d < diagonal; d += spacing) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── GameCard ────────────────────────────────────────────────

class GameCard extends StatefulWidget {
  final Game game;
  final VoidCallback? onTap;
  final FavoriteStatus? status;

  const GameCard({super.key, required this.game, this.onTap, this.status});

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = genreColor(widget.game.primaryGenre);
    final darkColor = HSLColor.fromColor(baseColor)
        .withLightness(0.12)
        .toColor();

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: () {
        HapticFeedback.lightImpact();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [baseColor, darkColor],
                ),
              ),
              child: Stack(
                children: [
                  // Diagonal line pattern overlay
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DiagonalLinesPainter(),
                    ),
                  ),
                  // Status badge
                  if (widget.status != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${widget.status!.icon} ${widget.status!.label}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Year badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.game.yearLabel,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        Text(
                          widget.game.title,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontFamily: 'Doto',
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            shadows: [
                              Shadow(blurRadius: 8, color: Colors.black87),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Genre pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            widget.game.primaryGenre,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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
