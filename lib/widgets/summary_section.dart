import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../models/activity_summary.dart';
import 'app_card.dart';

class SummarySection extends StatelessWidget {
  const SummarySection({
    super.key,
    required this.summary,
  });

  final ActivityPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.M.d');

    if (summary.isEmpty) {
      return AppCard(
        child: Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 40,
              color: AppColors.inkMuted.withValues(alpha: 0.7),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${dateFormat.format(summary.startDate)} ~ ${dateFormat.format(summary.endDate)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '총 ${summary.totalRecords}건 · 횟수 합계 ${summary.totalCount}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...summary.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SummaryItemCard(item: item),
          ),
        ),
      ],
    );
  }
}

class _SummaryItemCard extends StatefulWidget {
  const _SummaryItemCard({required this.item});

  final ActivitySummaryItem item;

  @override
  State<_SummaryItemCard> createState() => _SummaryItemCardState();
}

class _SummaryItemCardState extends State<_SummaryItemCard> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('M월 d일');

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.goldMuted.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_stories_outlined,
                        color: AppColors.burgundy),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.activityTypeName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.item.recordCount}건 · 횟수 ${widget.item.totalCount}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.inkMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            ...widget.item.records.map(
              (record) => ListTile(
                title: Text(dateFormat.format(record.date)),
                subtitle: record.content.isEmpty
                    ? null
                    : Text(record.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Text(
                  '${record.count}회',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.burgundy,
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
