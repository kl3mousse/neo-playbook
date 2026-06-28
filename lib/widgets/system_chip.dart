import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/combofox_theme.dart';
import '../theme/platform_palette.dart';

// ═══════════════════════════════════════════════════════════════
// SystemChip — platform selector pill chip
//
// Color derived from platform palette. Selected = filled + glow.
// ═══════════════════════════════════════════════════════════════

/// Display-friendly labels for known platform keys.
String platformLabel(String key) {
  const labels = {
    'neogeo': 'Neo Geo',
    'neo geo': 'Neo Geo',
    'cps1': 'CPS-1',
    'cps2': 'CPS-2',
    'cps3': 'CPS-3',
    'neogeocd': 'Neo Geo CD',
    'atomiswave': 'Atomiswave',
    'taitof3': 'Taito F3',
    'hng64': 'Hyper Neo Geo 64',
    'stv': 'ST-V',
    'zn': 'ZN',
  };
  return labels[key] ??
      key.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

class SystemChip extends StatelessWidget {
  final String platformKey;
  final bool isSelected;
  final VoidCallback onTap;

  const SystemChip({
    super.key,
    required this.platformKey,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = platformPalette(platformKey);
    final color = palette.start;
    final label = platformLabel(platformKey);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1.5),
          boxShadow: isSelected ? [neonGlow(color)] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
