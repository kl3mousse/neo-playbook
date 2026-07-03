import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/combofox_theme.dart';

// ═══════════════════════════════════════════════════════════════
// InfoFab — floating "Foxxy has a tip" button.
//
// The button itself is a circular Foxxy portrait wrapped in a
// pulsing neon ring, with a small "?" chat badge in the corner —
// so it's obvious *she* is the one waving for attention.
// Tapping it opens a themed speech-bubble dialog.
// ═══════════════════════════════════════════════════════════════

class InfoFab extends StatefulWidget {
  /// Path to the Foxxy SD asset (e.g. `assets/foxxy/sd/foxxy-sd-r1-c2.png`).
  final String foxxyAsset;

  /// Short title shown at the top of the dialog (pixel-font).
  final String title;

  /// Body paragraphs to display below the title.
  final List<String> paragraphs;

  /// Accent color for the border/glow. Defaults to neon purple.
  final Color accent;

  const InfoFab({
    super.key,
    required this.foxxyAsset,
    required this.title,
    required this.paragraphs,
    this.accent = ComboFoxColors.neonPurple,
  });

  @override
  State<InfoFab> createState() => _InfoFabState();
}

class _InfoFabState extends State<InfoFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(
      parent: _pulseCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _show(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => _FoxxyInfoDialog(
        foxxyAsset: widget.foxxyAsset,
        title: widget.title,
        paragraphs: widget.paragraphs,
        accent: widget.accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double size = 60;
    return Semantics(
      button: true,
      label: 'About this page',
      child: Tooltip(
        message: 'About this page',
        child: Material(
          color: Colors.transparent,
          child: InkResponse(
            onTap: () => _show(context),
            radius: size * 0.7,
            containedInkWell: false,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size + 10,
              height: size + 10,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Pulsing neon halo
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, _) {
                      final t = _pulseAnim.value;
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ComboFoxColors.surface,
                          border: Border.all(
                            color: widget.accent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.accent
                                  .withValues(alpha: 0.35 + 0.35 * t),
                              blurRadius: 14 + 10 * t,
                              spreadRadius: 1 + 2 * t,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Foxxy portrait
                  ClipOval(
                    child: SizedBox(
                      width: size - 6,
                      height: size - 6,
                      child: Image.asset(
                        widget.foxxyAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: ComboFoxColors.surfaceElevated,
                          alignment: Alignment.center,
                          child: const Text(
                            '🦊',
                            style: TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // "?" chat badge
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: ComboFoxColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.accent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accent.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '?',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 10,
                          color: widget.accent,
                          height: 1.0,
                        ),
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

class _FoxxyInfoDialog extends StatelessWidget {
  final String foxxyAsset;
  final String title;
  final List<String> paragraphs;
  final Color accent;

  const _FoxxyInfoDialog({
    required this.foxxyAsset,
    required this.title,
    required this.paragraphs,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          decoration: neonBorder(accent).copyWith(
            color: ComboFoxColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Foxxy portrait — large, centered, borderless
              Center(
                child: _FoxxyPortrait(asset: foxxyAsset, accent: accent),
              ),
              const SizedBox(height: 16),
              // Title (pixel font, accent color)
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.pressStart2p(
                  fontSize: 11,
                  color: accent,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              // Body paragraphs
              for (int i = 0; i < paragraphs.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                Text(
                  paragraphs[i],
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: ComboFoxColors.textPrimary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    textStyle: GoogleFonts.pressStart2p(fontSize: 8),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('GOT IT!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoxxyPortrait extends StatelessWidget {
  final String asset;
  final Color accent;
  const _FoxxyPortrait({required this.asset, required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 210,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.45),
              blurRadius: 32,
              spreadRadius: 3,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => Container(
              color: ComboFoxColors.surfaceElevated,
              alignment: Alignment.center,
              child: const Text('🦊', style: TextStyle(fontSize: 84)),
            ),
          ),
        ),
      ),
    );
  }
}
