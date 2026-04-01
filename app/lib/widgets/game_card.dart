import 'package:flutter/material.dart';
import '../models/game.dart';

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

IconData _genreIcon(String genre) {
  final g = genre.toLowerCase();
  if (g.contains('combat') || g.contains('fighting') || g.contains('versus')) {
    return Icons.sports_mma;
  }
  if (g.contains('shoot')) return Icons.rocket_launch;
  if (g.contains('beat')) return Icons.front_hand;
  if (g.contains('action')) return Icons.bolt;
  if (g.contains('puzzle')) return Icons.extension;
  if (g.contains('sport')) return Icons.sports;
  if (g.contains('racing')) return Icons.speed;
  if (g.contains('platform')) return Icons.terrain;
  if (g.contains('rpg') || g.contains('role')) return Icons.shield;
  if (g.contains('quiz')) return Icons.quiz;
  return Icons.videogame_asset;
}

class GameCard extends StatelessWidget {
  final Game game;
  final VoidCallback? onTap;

  const GameCard({super.key, required this.game, this.onTap});

  @override
  Widget build(BuildContext context) {
    final baseColor = genreColor(game.genre);
    final darkColor = HSLColor.fromColor(baseColor)
        .withLightness(0.15)
        .toColor();

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [baseColor, darkColor],
            ),
          ),
          child: Stack(
            children: [
              // Background genre icon
              Positioned(
                right: -20,
                bottom: -10,
                child: Icon(
                  _genreIcon(game.genre),
                  size: 100,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              // Year badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    game.year,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      game.title,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Doto',
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        shadows: [
                          Shadow(blurRadius: 6, color: Colors.black87),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Genre pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        game.genre,
                        style: const TextStyle(
                          color: Colors.white70,
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
    );
  }
}
