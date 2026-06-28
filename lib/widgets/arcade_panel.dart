import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/combofox_theme.dart';

// ═══════════════════════════════════════════════════════════════
// ArcadePanel — neon-bordered card container
//
// inactive = dim outline | active = neonPurple glow
// ═══════════════════════════════════════════════════════════════

class ArcadePanel extends StatelessWidget {
  final Widget child;
  final bool isActive;
  final Color? accentColor;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const ArcadePanel({
    super.key,
    required this.child,
    this.isActive = false,
    this.accentColor,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? ComboFoxColors.neonPurple;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: ComboFoxColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : color.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: isActive ? [neonGlow(color)] : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// NeonSectionHeader — Press Start 2P label + gradient underline
//
// Used as section titles in game detail and move list screens.
// ═══════════════════════════════════════════════════════════════

class NeonSectionHeader extends StatelessWidget {
  final String label;

  const NeonSectionHeader(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.pressStart2p(
            fontSize: 9,
            color: ComboFoxColors.textPrimary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 2,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [ComboFoxColors.neonPurple, Colors.transparent],
              stops: [0.0, 0.6],
            ),
          ),
        ),
      ],
    );
  }
}
