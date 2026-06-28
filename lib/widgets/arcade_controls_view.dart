import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/combofox_theme.dart';

// ═══════════════════════════════════════════════════════════════
// ArcadeControlsView — joystick + A/B/C/D button panel
//
// Used as a visual legend at the bottom of move list sections.
// ═══════════════════════════════════════════════════════════════

class ArcadeControlsView extends StatelessWidget {
  const ArcadeControlsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const _Joystick(),
        const SizedBox(width: 20),
        Row(
          children: [
            _ArcadeButton(label: 'A', color: AppColors.buttonA),
            const SizedBox(width: 8),
            _ArcadeButton(label: 'B', color: AppColors.buttonB),
            const SizedBox(width: 8),
            _ArcadeButton(label: 'C', color: AppColors.buttonC),
            const SizedBox(width: 8),
            _ArcadeButton(label: 'D', color: AppColors.buttonD),
          ],
        ),
      ],
    );
  }
}

class _Joystick extends StatelessWidget {
  const _Joystick();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ComboFoxColors.surface,
        border: Border.all(
          color: ComboFoxColors.neonPurple.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ComboFoxColors.surfaceElevated,
          border: Border.all(
            color: ComboFoxColors.neonPurple.withValues(alpha: 0.55),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ComboFoxColors.neonPurple.withValues(alpha: 0.25),
              blurRadius: 8,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ComboFoxColors.neonPurple.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

class _ArcadeButton extends StatelessWidget {
  final String label;
  final Color color;

  const _ArcadeButton({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
