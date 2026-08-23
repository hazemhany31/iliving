import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/luxury_theme.dart';
import '../../models/executive_dashboard_metrics.dart';

class RevenueTrendChart extends StatelessWidget {
  final List<SalesTrendDataPoint> dataPoints;
  final double height;

  const RevenueTrendChart({
    super.key,
    required this.dataPoints,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (dataPoints.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        child: Text(
          'Waiting for real-time sales transaction data...',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
            fontSize: 12,
            letterSpacing: 0.8,
          ),
        ),
      );
    }

    final maxRev = dataPoints.map((e) => e.revenue).reduce(max);

    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _RevenueTrendPainter(
          dataPoints: dataPoints,
          maxRevenue: maxRev > 0 ? maxRev : 100000.0,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _RevenueTrendPainter extends CustomPainter {
  final List<SalesTrendDataPoint> dataPoints;
  final double maxRevenue;
  final bool isDark;

  _RevenueTrendPainter({
    required this.dataPoints,
    required this.maxRevenue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    const topPadding = 20.0;
    const bottomPadding = 32.0;
    const sidePadding = 24.0;
    final chartWidth = size.width - (sidePadding * 2);
    final chartHeight = size.height - topPadding - bottomPadding;

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = (isDark ? AppColors.darkBorder : AppColors.lightBorder)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (chartHeight * i / 3);
      canvas.drawLine(Offset(sidePadding, y), Offset(size.width - sidePadding, y), gridPaint);
    }

    // Points calculation
    final stepX = dataPoints.length > 1 ? chartWidth / (dataPoints.length - 1) : chartWidth / 2;
    final List<Offset> points = [];

    final effectiveMax = maxRevenue > 0 ? maxRevenue * 1.15 : 100000.0;

    for (int i = 0; i < dataPoints.length; i++) {
      final x = sidePadding + (i * stepX);
      final normalizedY = (dataPoints[i].revenue / effectiveMax).clamp(0.08, 0.92);
      final y = topPadding + chartHeight - (normalizedY * chartHeight);
      points.add(Offset(x, y));
    }

    // Gradient fill under curve
    if (points.isNotEmpty) {
      final path = Path();
      final fillPath = Path();

      path.moveTo(points.first.dx, points.first.dy);
      fillPath.moveTo(points.first.dx, topPadding + chartHeight);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlP1 = Offset(p1.dx + (stepX / 2), p1.dy);
        final controlP2 = Offset(p2.dx - (stepX / 2), p2.dy);

        path.cubicTo(controlP1.dx, controlP1.dy, controlP2.dx, controlP2.dy, p2.dx, p2.dy);
        fillPath.cubicTo(controlP1.dx, controlP1.dy, controlP2.dx, controlP2.dy, p2.dx, p2.dy);
      }

      fillPath.lineTo(points.last.dx, topPadding + chartHeight);
      fillPath.close();

      final fillGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accent.withAlpha(50),
          AppColors.accent.withAlpha(0),
        ],
      );

      final fillPaint = Paint()
        ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);

      // Draw stroke
      final strokePaint = Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, strokePaint);

      // Draw glowing dots & X-axis month labels
      final dotOuterPaint = Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.fill;

      final dotInnerPaint = Paint()
        ..color = isDark ? AppColors.darkSurface : AppColors.lightSurface
        ..style = PaintingStyle.fill;

      final textStyle = TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      );

      for (int i = 0; i < points.length; i++) {
        final pt = points[i];
        canvas.drawCircle(pt, 5, dotOuterPaint);
        canvas.drawCircle(pt, 2.5, dotInnerPaint);

        // Draw X-axis label under each dot
        final label = dataPoints[i].label;
        if (label.isNotEmpty) {
          final textSpan = TextSpan(text: label, style: textStyle);
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(pt.dx - (textPainter.width / 2), topPadding + chartHeight + 10),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueTrendPainter oldDelegate) => true;
}

class UnitInventoryDonutChart extends StatelessWidget {
  final int available;
  final int reserved;
  final int sold;
  final double size;

  const UnitInventoryDonutChart({
    super.key,
    required this.available,
    required this.reserved,
    required this.sold,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final total = available + reserved + sold;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutChartPainter(
              available: available,
              reserved: reserved,
              sold: sold,
              isDark: isDark,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.accent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'TOTAL UNITS',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final int available;
  final int reserved;
  final int sold;
  final bool isDark;

  _DonutChartPainter({
    required this.available,
    required this.reserved,
    required this.sold,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = (available + reserved + sold).toDouble();
    if (total == 0) {
      final emptyPaint = Paint()
        ..color = (isDark ? AppColors.darkBorder : AppColors.lightBorder)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), (size.width - 20) / 2, emptyPaint);
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 16.0;

    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;

    void drawSegment(double count, Color color) {
      if (count <= 0) return;
      final sweepAngle = (count / total) * 2 * pi;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle - 0.05, false, paint);
      startAngle += sweepAngle;
    }

    drawSegment(sold.toDouble(), AppColors.accent);
    drawSegment(reserved.toDouble(), AppColors.warning);
    drawSegment(available.toDouble(), AppColors.success);
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}

class MaintenanceStatusBarChart extends StatelessWidget {
  final MaintenanceStats stats;
  final double height;

  const MaintenanceStatusBarChart({
    super.key,
    required this.stats,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final maxVal = max(1, max(stats.pendingRequests, max(stats.inProgressRequests, stats.completedRequests)));

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBar('Pending', stats.pendingRequests, maxVal, AppColors.warning, isDark),
            _buildBar('In Progress', stats.inProgressRequests, maxVal, AppColors.info, isDark),
            _buildBar('Completed', stats.completedRequests, maxVal, AppColors.success, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String label, int value, int maxValue, Color color, bool isDark) {
    final pct = (value / maxValue).clamp(0.15, 1.0);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: pct,
                widthFactor: 0.42,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
