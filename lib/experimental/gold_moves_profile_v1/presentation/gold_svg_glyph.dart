import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GoldSvgGlyph extends StatelessWidget {
  final String assetPath;
  final String tooltip;
  final Color color;
  final double size;
  final Widget fallback;

  const GoldSvgGlyph({
    super.key,
    required this.assetPath,
    required this.tooltip,
    required this.color,
    required this.fallback,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: size,
        child: SvgPicture.asset(
          assetPath,
          key: ValueKey('glyph:$assetPath'),
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          excludeFromSemantics: true,
          placeholderBuilder: (_) => fallback,
          errorBuilder: (_, _, _) => fallback,
        ),
      ),
    );
  }
}
