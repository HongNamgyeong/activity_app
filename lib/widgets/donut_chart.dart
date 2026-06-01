import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class DonutChartSegment {
  const DonutChartSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.segments,
    this.size = 160,
    this.strokeWidth = 28,
  });

  final List<DonutChartSegment> segments;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: Text('데이터 없음', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return CustomPaint(
      size: Size(size, size),
      painter: _DonutChartPainter(
        segments: segments,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.segments,
    required this.strokeWidth,
  });

  final List<DonutChartSegment> segments;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    var startAngle = -math.pi / 2;

    for (final segment in segments) {
      if (segment.value <= 0) continue;

      final sweepAngle = (segment.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    if (oldDelegate.strokeWidth != strokeWidth) return true;
    if (oldDelegate.segments.length != segments.length) return true;

    for (var i = 0; i < segments.length; i++) {
      final previous = oldDelegate.segments[i];
      final current = segments[i];
      if (previous.label != current.label ||
          previous.value != current.value ||
          previous.color != current.color) {
        return true;
      }
    }

    return false;
  }
}

class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.segments});

  final List<DonutChartSegment> segments;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: segments.map((segment) {
        final percent = ((segment.value / total) * 100).round();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: segment.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${segment.label} $percent%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
