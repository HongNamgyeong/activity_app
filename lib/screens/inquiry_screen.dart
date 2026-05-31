import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/activity_record_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/date_range_calendar.dart';
import '../widgets/summary_section.dart';

class InquiryScreen extends ConsumerWidget {
  const InquiryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiry = ref.watch(inquiryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        const SectionTitle(
          title: '기간별 활동 조회',
          subtitle: '달력에서 시작일과 종료일을 선택한 뒤 조회하세요.',
        ),
        const SizedBox(height: 20),
        DateRangeCalendar(
          startDate: inquiry.startDate,
          endDate: inquiry.endDate,
          onRangeChanged: (start, end) {
            ref.read(inquiryProvider.notifier).selectRange(start, end);
          },
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: inquiry.isLoading
              ? null
              : () => ref.read(inquiryProvider.notifier).search(),
          icon: inquiry.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: Text(inquiry.isLoading ? '조회 중...' : '활동 조회'),
        ),
        if (inquiry.errorMessage != null) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Text(
              inquiry.errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        ],
        if (inquiry.summary != null) ...[
          const SizedBox(height: 24),
          SummarySection(summary: inquiry.summary!),
        ],
      ],
    );
  }
}
