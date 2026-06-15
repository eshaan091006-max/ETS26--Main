import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:malhar_ets/constants/app_colors.dart';

class AmbientGlowBackground extends StatefulWidget {
  final Widget child;
  const AmbientGlowBackground({super.key, required this.child});

  @override
  State<AmbientGlowBackground> createState() => _AmbientGlowBackgroundState();
}

class _AmbientGlowBackgroundState extends State<AmbientGlowBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        // 1. Dark Background base
        Container(
          color: AppColors.background,
        ),

        // 2. Animated Glowing Orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value * 2 * pi;

            // Orb 1 (Gold/Primary) - Elliptical motion in top-right
            final orb1X = size.width * 0.5 + sin(t) * 90;
            final orb1Y = size.height * 0.15 + cos(t) * 70;

            // Orb 2 (Purple/Accent) - Elliptical motion in bottom-left
            final orb2X = size.width * 0.05 + cos(t + pi / 2) * 100;
            final orb2Y = size.height * 0.55 + sin(t + pi / 2) * 80;

            // Orb 3 (Deep Purple) - Smooth oscillation in center-right
            final orb3X = size.width * 0.4 + sin(t * 1.3) * 60;
            final orb3Y = size.height * 0.4 + cos(t * 1.3) * 60;

            return Stack(
              children: [
                // Gold Orb
                Positioned(
                  left: orb1X,
                  top: orb1Y,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.08),
                    ),
                  ),
                ),
                // Accent Purple Orb
                Positioned(
                  left: orb2X,
                  top: orb2Y,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withOpacity(0.08),
                    ),
                  ),
                ),
                // Deep Purple Orb
                Positioned(
                  left: orb3X,
                  top: orb3Y,
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.deepPurple.withOpacity(0.12),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // 3. Blur filter to merge shapes into a smooth ambient field
        Positioned.fill(
          child: IgnorePointer(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 95, sigmaY: 95),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),

        // 4. Subtle radial vignette overlay
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.45),
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 5. Foreground content
        widget.child,
      ],
    );
  }
}
