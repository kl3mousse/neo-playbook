import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final radius = BorderRadius.circular(20);

    // Neutral grey tones for the unselected state so bright platform colors
    // (yellow CPS-1, red Neo Geo…) don't compete for attention.
    const greyFill = Color(0x1FFFFFFF); // white @ ~12%
    const greyBorder = Color(0x40FFFFFF); // white @ ~25%
    const greyText = Color(0xFF9CA3AF); // textSecondary

    const duration = Duration(milliseconds: 200);
    const curve = Curves.easeOut;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: radius,
        splashColor: color.withValues(alpha: 0.28),
        highlightColor: color.withValues(alpha: 0.12),
        child: AnimatedContainer(
          duration: duration,
          curve: curve,
          constraints: const BoxConstraints(minHeight: 34, minWidth: 68),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? color : greyFill,
            borderRadius: radius,
            border: Border.all(
              color: isSelected ? color : greyBorder,
              width: 1.5,
            ),
            // Always keep one shadow in the list so AnimatedContainer can
            // smoothly tween its color/alpha instead of snapping on/off.
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? color.withValues(alpha: 0.55)
                    : Colors.transparent,
                blurRadius: isSelected ? 12 : 0,
                spreadRadius: isSelected ? 1 : 0,
              ),
            ],
          ),
          child: AnimatedDefaultTextStyle(
            duration: duration,
            curve: curve,
            style: TextStyle(
              color: isSelected ? Colors.white : greyText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              height: 1.0,
            ),
            child: Text(label, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
