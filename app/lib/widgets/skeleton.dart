import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A lightweight shimmering placeholder used during initial data loads.
/// Intentionally dependency-free so the app stays lean.
class Skeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  const Skeleton.line({super.key, this.width, this.height = 14})
      : borderRadius = const BorderRadius.all(Radius.circular(6));

  const Skeleton.block({
    super.key,
    this.width,
    this.height,
    double radius = 16,
  }) : borderRadius = const BorderRadius.all(Radius.circular(16));

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Sweep a light band across a dark base — a subtle shimmer.
        final t = _controller.value;
        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1 + 2 * t, 0),
                end: Alignment(1 + 2 * t, 0),
                colors: [
                  AppColors.surface,
                  AppColors.surfaceLight,
                  AppColors.surface,
                ],
                stops: const [0.35, 0.5, 0.65],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A pre-built skeleton layout mimicking the GameDetailScreen while its
/// data is loading. Safe to show against the dark scaffold background.
class GameDetailSkeleton extends StatelessWidget {
  const GameDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Hero header placeholder
        Container(
          height: 160,
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton.line(width: 220, height: 28),
              SizedBox(height: 12),
              Skeleton.line(width: 140, height: 14),
              Spacer(),
              Skeleton.line(width: 180, height: 12),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              // Pills row
              Row(
                children: [
                  Skeleton(width: 72, height: 24),
                  SizedBox(width: 8),
                  Skeleton(width: 56, height: 24),
                  SizedBox(width: 8),
                  Skeleton(width: 88, height: 24),
                ],
              ),
              SizedBox(height: 20),
              // Description lines
              Skeleton.line(),
              SizedBox(height: 8),
              Skeleton.line(),
              SizedBox(height: 8),
              Skeleton.line(width: 240),
              SizedBox(height: 24),
              // Section header + rows
              Skeleton.line(width: 160, height: 18),
              SizedBox(height: 12),
              Skeleton.block(height: 48),
              SizedBox(height: 8),
              Skeleton.block(height: 48),
              SizedBox(height: 8),
              Skeleton.block(height: 48),
            ],
          ),
        ),
      ],
    );
  }
}
