import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/combofox_theme.dart';

// ═══════════════════════════════════════════════════════════════
// FoxxyAssistant — floating mascot widget
//
// Position: bottom-left overlay on game detail screen.
// Shows a speech bubble + Foxxy image placeholder.
//
// Placeholder: assets/foxxy/foxxy_idle.png
// → Replace with actual asset once artwork is ready.
// ═══════════════════════════════════════════════════════════════

class FoxxyAssistant extends StatefulWidget {
  const FoxxyAssistant({super.key});

  @override
  State<FoxxyAssistant> createState() => _FoxxyAssistantState();
}

class _FoxxyAssistantState extends State<FoxxyAssistant>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkCtrl;
  late final Animation<double> _blinkAnim;

  // ── Placeholder path ──────────────────────────────────────────
  // Drop your Foxxy artwork at this path to enable the real image.
  static const _foxxyImagePath = 'assets/foxxy/foxxy_idle.png';

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _blinkAnim = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );
    _startBlinkLoop();
  }

  Future<void> _startBlinkLoop() async {
    while (mounted) {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted) break;
      await _blinkCtrl.forward();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) break;
      await _blinkCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Speech bubble
        Container(
          constraints: const BoxConstraints(maxWidth: 170),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: neonBorder(ComboFoxColors.neonPurple).copyWith(
            color: ComboFoxColors.surface,
          ),
          child: Text(
            "Let's train\nthose combos!",
            style: GoogleFonts.pressStart2p(
              fontSize: 7,
              color: ComboFoxColors.neonPurple,
              height: 1.7,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Foxxy image — falls back to emoji placeholder when asset not found
        AnimatedBuilder(
          animation: _blinkAnim,
          builder: (context, child) => Opacity(
            opacity: _blinkAnim.value,
            child: child,
          ),
          child: SizedBox(
            width: 60,
            height: 60,
            child: Image.asset(
              _foxxyImagePath,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) => Container(
                decoration: BoxDecoration(
                  color: ComboFoxColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ComboFoxColors.neonPurple.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: const Text('🦊', style: TextStyle(fontSize: 26)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
