import 'package:flutter/material.dart';

class GlowingCard extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double borderRadius;
  final double blurRadius;
  final double spreadRadius;
  final bool animate;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GlowingCard({
    super.key,
    required this.child,
    required this.glowColor,
    this.borderRadius = 16.0,
    this.blurRadius = 15.0,
    this.spreadRadius = 1.0,
    this.animate = false,
    this.margin,
    this.onTap,
  });

  @override
  State<GlowingCard> createState() => _GlowingCardState();
}

class _GlowingCardState extends State<GlowingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = Tween<double>(
      begin: 0.6,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant GlowingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget card = AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final scale = widget.animate ? _animation.value : 1.0;
        return Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.25 * scale),
                blurRadius: widget.blurRadius * scale,
                spreadRadius: widget.spreadRadius,
                offset: Offset.zero,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: widget.child,
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(onTap: widget.onTap, child: card);
    }
    return card;
  }
}
