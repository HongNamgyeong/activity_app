import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/activity_summary.dart';
import 'activity_category_utils.dart';
import 'app_card.dart';
import 'donut_chart.dart';

typedef SummaryItemTap = void Function(ActivitySummaryItem item);

class SummarySection extends StatelessWidget {
  const SummarySection({
    super.key,
    required this.summary,
    this.onItemTap,
  });

  final ActivityPeriodSummary summary;
  final SummaryItemTap? onItemTap;

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty) {
      return AppCard(
        child: Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 40,
              color: AppColors.textMuted.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              '선택한 기간에 기록된 활동이 없습니다.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final chartSegments = buildCategorySegments(summary.items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: '활동 요약',
          trailing: Text(
            '총 ${summary.totalRecords}건',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              DonutChart(segments: chartSegments),
              const SizedBox(height: 20),
              ChartLegend(segments: chartSegments),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('항목별 상세', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...summary.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DetailItemCard(item: item, onTap: onItemTap),
          ),
        ),
      ],
    );
  }
}

class _DetailItemCard extends StatelessWidget {
  const _DetailItemCard({required this.item, this.onTap});

  final ActivitySummaryItem item;
  final SummaryItemTap? onTap;

  @override
  Widget build(BuildContext context) {
    final category = inferActivityCategory(item.activityTypeName);
    final icon = activityIconForCategory(category);
    final iconColor = categoryColor(category);

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap == null ? null : () => onTap!(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.activityTypeName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.totalCount} 회/시간',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
