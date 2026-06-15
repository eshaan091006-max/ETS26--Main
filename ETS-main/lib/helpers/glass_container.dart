import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidGlassContainer extends StatefulWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color glowColor;
  final VoidCallback? onTap;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.blur = 30.0,
    this.borderRadius = 18.0,
    this.padding,
    this.margin,
    required this.glowColor,
    this.onTap,
  });

  @override
  State<LiquidGlassContainer> createState() => _LiquidGlassContainerState();
}

class _LiquidGlassContainerState extends State<LiquidGlassContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shineAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _glowAnimation = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Moves the shine gradient coordinates from top-left to bottom-right
    _shineAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter() {
    setState(() => _isHovered = true);
    _controller.forward();
  }

  void _onExit() {
    setState(() => _isHovered = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      child: GestureDetector(
        onTapDown: (_) => _onEnter(),
        onTapUp: (_) => _onExit(),
        onTapCancel: () => _onExit(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, childWidget) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: widget.margin,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: [
                    // Deep ambient drop shadow
                    BoxShadow(
                      color: Colors.black.withAlpha(140),
                      offset: const Offset(0, 12),
                      blurRadius: 28,
                      spreadRadius: -4,
                    ),
                    // Dynamic glowing shadow
                    BoxShadow(
                      color: widget.glowColor.withAlpha((_glowAnimation.value * 255).toInt()),
                      offset: const Offset(0, 4),
                      blurRadius: _isHovered ? 24 : 16,
                      spreadRadius: _isHovered ? 1 : -2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 1. Smoked Glass Backdrop Blur
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(widget.borderRadius),
                              color: Colors.black.withAlpha(190),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 2. Liquid Glass Border & Edge reflections
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(widget.borderRadius),
                            border: Border.all(
                              width: 1.2,
                              color: Colors.white.withAlpha(_isHovered ? 65 : 35),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withAlpha(15),
                                widget.glowColor.withAlpha(5),
                                widget.glowColor.withAlpha(_isHovered ? 40 : 20),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 3. Specular Glare/Shine Stripe (sweeps across on hover/tap)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(widget.borderRadius),
                            gradient: LinearGradient(
                              begin: Alignment(_shineAnimation.value - 0.5, _shineAnimation.value - 0.5),
                              end: Alignment(_shineAnimation.value + 0.5, _shineAnimation.value + 0.5),
                              colors: [
                                Colors.white.withAlpha(0),
                                Colors.white.withAlpha(10),
                                Colors.white.withAlpha(_isHovered ? 90 : 50),
                                Colors.white.withAlpha(10),
                                Colors.white.withAlpha(0),
                              ],
                              stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 4. Glowing Rim Highlight (Bottom/Right reflection)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(widget.borderRadius),
                            border: Border.all(
                              width: 1.0,
                              color: widget.glowColor.withAlpha(_isHovered ? 80 : 45),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Colors.white.withAlpha(10),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.25, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 5. Child Content
                    Padding(
                      padding: widget.padding ?? EdgeInsets.zero,
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
