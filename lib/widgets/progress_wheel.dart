import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';

class ProgressWheel extends StatefulWidget {
  final double percentage;
  final String label;
  final double size;

  const ProgressWheel({
    super.key,
    required this.percentage,
    required this.label,
    this.size = 100,
  });

  @override
  State<ProgressWheel> createState() => _ProgressWheelState();
}

class _ProgressWheelState extends State<ProgressWheel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0.0, end: widget.percentage).animate(
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ProgressWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _animation = Tween<double>(begin: _animation.value, end: widget.percentage).animate(
        CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
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
    final double strokeWidth = widget.size * 0.06;
    final double safeDiameter = (widget.size - strokeWidth * 2) * 0.70;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: LuxuryTheme.surfaceBrown,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(100),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: widget.size - strokeWidth,
                height: widget.size - strokeWidth,
                child: CustomPaint(
                  painter: _ProgressWheelPainter(
                    percentage: _animation.value,
                    strokeWidth: strokeWidth,
                  ),
                ),
              ),
              Container(
                width: safeDiameter,
                height: safeDiameter,
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_animation.value.toInt()}%',
                          style: TextStyle(
                            color: LuxuryTheme.primaryGold,
                            fontSize: widget.size * 0.16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: widget.size * 0.02),
                        Container(
                          constraints: BoxConstraints(maxWidth: safeDiameter * 0.90),
                          child: Text(
                            widget.label.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: LuxuryTheme.textMuted,
                              fontSize: widget.size * 0.08,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressWheelPainter extends CustomPainter {
  final double percentage;
  final double strokeWidth;

  const _ProgressWheelPainter({
    required this.percentage,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - strokeWidth / 2;

    final bgPaint = Paint()
      ..color = LuxuryTheme.backgroundBlack
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          LuxuryTheme.deepGold,
          LuxuryTheme.primaryGold,
          LuxuryTheme.deepGold,
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = 2 * pi * (percentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressWheelPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.strokeWidth != strokeWidth;
  }
}
