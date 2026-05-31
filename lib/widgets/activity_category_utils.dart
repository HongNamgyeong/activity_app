import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/activity_summary.dart';
import 'donut_chart.dart';

String inferActivityCategory(String name) {
  if (name.contains('기도') || name.contains('묵주')) return '기도';
  if (name.contains('봉사')) return '봉사';
  if (name.contains('방문') || name.contains('환자')) return '방문';
  if (name.contains('회합')) return '회합';
  return '기타';
}

Color categoryColor(String category) {
  return switch (category) {
    '기도' => AppColors.chartPrayer,
    '봉사' => AppColors.chartService,
    '방문' => AppColors.chartVisit,
    '회합' => AppColors.chartMeeting,
    _ => AppColors.chartOther,
  };
}

IconData activityIconForCategory(String category) {
  return switch (category) {
    '기도' => Icons.auto_awesome,
    '봉사' => Icons.volunteer_activism_outlined,
    '방문' => Icons.favorite_outline,
    '회합' => Icons.groups_outlined,
    _ => Icons.circle_outlined,
  };
}

List<DonutChartSegment> buildCategorySegments(List<ActivitySummaryItem> items) {
  final totals = <String, double>{};

  for (final item in items) {
    final category = inferActivityCategory(item.activityTypeName);
    totals[category] = (totals[category] ?? 0) + item.totalCount;
  }

  const order = ['기도', '봉사', '방문', '회합', '기타'];

  return order
      .where((category) => (totals[category] ?? 0) > 0)
      .map(
        (category) => DonutChartSegment(
          label: category,
          value: totals[category]!,
          color: categoryColor(category),
        ),
      )
      .toList();
}
