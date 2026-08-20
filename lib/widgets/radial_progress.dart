import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class RadialProgress extends StatefulWidget {
  final double percentage; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color activeColor;
  final Color? trackColor;
  final Widget? child;

  const RadialProgress({
    super.key,
    required this.percentage,
    this.size = 80.0,
    this.strokeWidth = 8.0,
    this.activeColor = AppColors.primary,
    this.trackColor,
    this.child,
  });

  @override
  State<RadialProgress> createState() => _RadialProgressState();
}

class _RadialProgressState extends State<RadialProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: widget.percentage,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant RadialProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.percentage != oldWidget.percentage) {
      _animation =
          Tween<double>(
            begin: oldWidget.percentage,
            end: widget.percentage,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RadialPainter(
                  percentage: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  activeColor: widget.activeColor,
                  trackColor:
                      widget.trackColor ??
                      AppColors.border.withValues(alpha: 0.5),
                ),
              );
            },
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _RadialPainter extends CustomPainter {
  final double percentage;
  final double strokeWidth;
  final Color activeColor;
  final Color trackColor;

  _RadialPainter({
    required this.percentage,
    required this.strokeWidth,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - (strokeWidth / 2);

    // 1. Draw track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Draw active arc with slight outer glow shadow
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from the top
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
